# UFC 三级存储策略

> **文档版本**: v1.0  
> **创建日期**: 2026-04-25  
> **状态**: 权威规范（Phase 1 产出，所有域 Ctx 设计时必须对齐）  
> **裁决来源**: UFC 架构设计总纲 v5.1 §3.2（域级容器标准结构）  
> **关联文档**: `UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_端到端计算流主链.md`

---

## 0. 文档目的

本文定义 UFC **三级存储策略**，约束所有域 `*_Ctx` 的内存池引用方式和热路径分配规则。

**核心原则**：数据的存储级别由其**生命周期**决定，而非由数据量决定。

---

## 1. 三级定义

### 1.1 L3 级：外存 / 模型级（Cold Storage）


| 属性             | 描述                                                         |
| -------------- | ---------------------------------------------------------- |
| **生命周期**       | 全程：ModelBuilder 完成后冻结，进程结束时释放                              |
| **写操作**        | Write-Once（Desc/Algo 字段），State 字段仅通过 L5_RT/WriteBack 白名单写回 |
| **分配方式**       | `ALLOCATE`（普通 Fortran 堆，允许在 ModelBuilder 阶段分配）             |
| **所有者**        | `L3_MD` 各域容器                                               |
| **释放时机**       | 进程退出，或显式 `Finalize`                                        |
| **对应 TYPE 角色** | `*_Desc`（只读冻结）、`*_Algo`（算法参数冻结）、`*_State`（通过白名单写回）         |


**典型示例**：

```fortran
! L3_MD/Material/MD_Material_Desc.f90
TYPE :: MD_Material_Desc
    REAL(wp) :: young_modulus = 0.0_wp   ! Write-Once，ModelBuilder后冻结
    REAL(wp) :: poisson_ratio = 0.0_wp
    REAL(wp) :: density       = 0.0_wp
    INTEGER(i4) :: mat_id     = 0
END TYPE
```

**约束**：

- Desc/Algo 字段在 Step 执行阶段禁止修改
- State 字段修改只能通过 `L5_RT/WriteBack` 调用，不得绕过

---

### 1.2 L2 级：内存池 / Step 级（Warm Storage）


| 属性             | 描述                                                              |
| -------------- | --------------------------------------------------------------- |
| **生命周期**       | Step 级：`RT_Step_Init` 时分配，`RT_Step_End` 时归还池                    |
| **写操作**        | Step 内可读写，Step 结束后归还（不保留内容）                                     |
| **分配方式**       | 通过 `IF_StructMemPool` 或 `IF_UnstructMemPool` 分配，禁止直接 `ALLOCATE` |
| **所有者**        | `L4_PH` 各域 `*_Ctx`，通过 `pool_mgr` 引用字段持有                         |
| **释放时机**       | Step 结束，调用 `pool_mgr%release(ctx%pool_handle)`                  |
| **对应 TYPE 角色** | `*_Ctx`（L4_PH 域容器，Step 级缓存）                                     |


**典型示例**：

```fortran
! L4_PH/Element/PH_Element_Ctx.f90
TYPE :: PH_Element_Ctx
    TYPE(IF_Mem_PoolHandle) :: pool_handle  ! 内存池句柄
    ! 预分配工作数组（从内存池获取）
    REAL(wp), POINTER :: Ke_buf(:,:) => NULL()   ! 单元刚度缓冲
    REAL(wp), POINTER :: Re_buf(:)   => NULL()   ! 单元残差缓冲
    INTEGER(i4) :: n_elem_active = 0
CONTAINS
    PROCEDURE :: Init     => PH_Element_Ctx_Init
    PROCEDURE :: Finalize => PH_Element_Ctx_Finalize
END TYPE
```

**内存池标准引用写法**：

```fortran
! L4_PH 域容器初始化时从 IF_StructMemPool 请求
SUBROUTINE PH_Element_Ctx_Init(self, pool_mgr, n_elem, n_dof_per_elem)
    CLASS(PH_Element_Ctx), INTENT(INOUT) :: self
    TYPE(IF_Mem_Mgr),      INTENT(INOUT) :: pool_mgr
    INTEGER(i4),           INTENT(IN)    :: n_elem, n_dof_per_elem
    ! 从内存池请求连续内存块
    CALL pool_mgr%request(self%pool_handle, &
        n_bytes = n_elem * n_dof_per_elem * n_dof_per_elem * wp)
    ! 关联指针到内存池块
    CALL pool_mgr%map_real2d(self%pool_handle, &
        self%Ke_buf, [n_dof_per_elem, n_dof_per_elem * n_elem])
END SUBROUTINE
```

**约束**：

- L4_PH `*_Ctx` 中**禁止**直接 `ALLOCATE`，必须使用 `pool_mgr` 接口
- `pool_handle` 必须在 Ctx TYPE 中显式声明
- Step 结束时必须调用 `Finalize` 归还池（不得泄漏）

---

### 1.3 L1 级：缓存 / Iter 级（Hot Storage）


| 属性             | 描述                                        |
| -------------- | ----------------------------------------- |
| **生命周期**       | Iter 级：迭代内分配（或预分配后复用），收敛后丢弃               |
| **写操作**        | Iter 内自由读写，迭代间不保留                         |
| **分配方式**       | **预分配**（Step 初始化时一次性分配，Iter 内复用）或**栈上分配** |
| **所有者**        | `L5_RT/Assembly`、`L4_PH/Element` 等热路径过程   |
| **释放时机**       | Step 结束（复用方式）或函数返回（栈方式）                   |
| **对应 TYPE 角色** | `*_Ctx`（L5_RT 积分点工作数组，Iter 级）             |


**典型示例**（预分配方式，推荐）：

```fortran
! L5_RT/Assembly/RT_Asm_WS.f90
TYPE :: RT_Asm_WorkSpace
    ! 在 Step_Init 时预分配，Iter 内复用
    REAL(wp), ALLOCATABLE :: K_csr_val(:)    ! 全局刚度矩阵 CSR 值
    REAL(wp), ALLOCATABLE :: R_global(:)     ! 全局残差向量
    REAL(wp), ALLOCATABLE :: du_local(:)     ! 单元位移增量临时缓冲
    INTEGER(i4) :: n_dof_total = 0
END TYPE
```

**栈上分配示例**（小尺寸，编译器优化友好）：

```fortran
! 在 PH_Element_Compute_Ke 内部，栈上局部数组
SUBROUTINE PH_Element_Compute_Ke(elem_ctx, mat_ctx, Ke)
    ! 栈上小数组，不需要动态分配
    REAL(wp) :: B_mat(6, 24)   ! 应变矩阵（固定尺寸元素类型）
    REAL(wp) :: D_mat(6, 6)    ! 材料刚度矩阵
    REAL(wp) :: BtDB(24, 24)   ! 中间矩阵
    ! ... 积分点计算
END SUBROUTINE
```

**热路径强约束**：

- Iter 级 Ctx **严禁** `ALLOCATE` 在迭代循环内部
- 如需动态尺寸，必须在 Step_Init 时预分配（见 L2 级策略）
- 积分点工作数组优先使用栈（自动变量），大数组使用预分配复用

---

## 2. 三级对应的 TYPE 角色矩阵


| 存储级别              | TYPE 角色        | 写权限           | 分配方式                     | 典型所有者          |
| ----------------- | -------------- | ------------- | ------------------------ | -------------- |
| **L3（外存/模型级）**    | `*_Desc`       | Write-Once    | `ALLOCATE`（ModelBuilder） | L3_MD 各域       |
| **L3（外存/模型级）**    | `*_Algo`       | Write-Once    | `ALLOCATE`（ModelBuilder） | L3_MD 各域       |
| **L3（外存/模型级）**    | `*_State`      | WriteBack 白名单 | `ALLOCATE`（ModelBuilder） | L3_MD 各域       |
| **L2（内存池/Step级）** | `*_Ctx`（L4_PH） | Step 内自由      | `IF_Mem_PoolMgr`         | L4_PH 各域       |
| **L1（缓存/Iter级）**  | `*_Ctx`（L5_RT） | Iter 内自由      | 预分配复用 / 栈                | L5_RT Assembly |


---

## 3. 各域 `*_Ctx.f90` 设计约束

### 3.1 L4_PH 域 Ctx 标准结构

每个 L4_PH 域的 `*_Ctx` **必须**包含：

```fortran
TYPE :: PH_XXX_Ctx
    ! 必选字段 1：内存池句柄
    TYPE(IF_Mem_PoolHandle) :: pool_handle
    
    ! 必选字段 2：活跃数量（用于向量化循环边界）
    INTEGER(i4) :: n_active = 0
    
    ! 可选字段：指针到内存池数据
    REAL(wp), POINTER :: work_buf(:) => NULL()
    
    ! 可选字段：从 L3 Desc 缓存的只读快照（避免热路径重复查询）
    ! 注：仅缓存 Step 内不变的量，State 值不缓存
    INTEGER(i4) :: cached_mat_type = 0
CONTAINS
    PROCEDURE :: Init     => PH_XXX_Ctx_Init
    PROCEDURE :: Finalize => PH_XXX_Ctx_Finalize
    PROCEDURE :: Reset    => PH_XXX_Ctx_Reset  ! Incr开始时复位（不重分配）
END TYPE
```

**禁止模式**：

```fortran
! ❌ 禁止：在 Ctx 内部动态分配
TYPE :: PH_Bad_Ctx
    REAL(wp), ALLOCATABLE :: bad_buf(:)  ! 禁止！必须用 pool_handle
END TYPE

! ❌ 禁止：在 Iter 循环内分配
DO iter = 1, max_iter
    ALLOCATE(tmp_arr(n))   ! 禁止！在迭代内分配
    ! ...
    DEALLOCATE(tmp_arr)
END DO
```

### 3.2 L5_RT 热路径 Ctx 标准结构

```fortran
TYPE :: RT_XXX_WS
    ! 在 Step_Init 时一次性预分配
    REAL(wp), ALLOCATABLE :: buf_A(:,:)
    REAL(wp), ALLOCATABLE :: buf_b(:)
    INTEGER(i4) :: capacity = 0
CONTAINS
    PROCEDURE :: Alloc  => RT_XXX_WS_Alloc   ! Step_Init 调用一次
    PROCEDURE :: Dealloc => RT_XXX_WS_Dealloc ! Step_End 调用
    ! 无 Iter 级分配接口
END TYPE
```

---

## 4. 内存池接口参考

```fortran
! L1_IF/Memory 提供的标准接口（参考 IF_Mem_Mgr.f90）
USE IF_Prec, ONLY: wp, i4

TYPE :: IF_Mem_PoolHandle
    INTEGER(i4) :: pool_id   = -1
    INTEGER(i4) :: chunk_idx = -1
    INTEGER(i4) :: size_bytes = 0
END TYPE

! 请求内存块
SUBROUTINE IF_Mem_Request(mgr, handle, n_bytes)

! 释放内存块（归还给池，不真正 DEALLOCATE）
SUBROUTINE IF_Mem_Release(mgr, handle)

! 将内存块映射到 1D REAL 指针
SUBROUTINE IF_Mem_Map_Real1D(mgr, handle, ptr, n)

! 将内存块映射到 2D REAL 指针
SUBROUTINE IF_Mem_Map_Real2D(mgr, handle, ptr, shape)
```

---

## 5. 热路径规则汇总（强制）


| 规则编号       | 规则                               | 违反后果       |
| ---------- | -------------------------------- | ---------- |
| **MEM-01** | Iter 级热路径**禁止** `ALLOCATE`       | 内存碎片，性能劣化  |
| **MEM-02** | L4_PH `*_Ctx` 必须持有 `pool_handle` | 无法池归还，内存泄漏 |
| **MEM-03** | L3 Desc/Algo 字段 Step 阶段禁止写       | 破坏唯一真相     |
| **MEM-04** | State 写回只走 L5_RT/WriteBack       | 越权写回，破坏白名单 |
| **MEM-05** | 预分配数组在 Step_Init 完成，Iter 内只复用    | 同 MEM-01   |
| **MEM-06** | 小尺寸（编译期确定）积分点数组优先栈分配             | 无硬性违规，性能建议 |
| **MEM-07** | L4_PH Ctx 的 L3 快照只缓存 Step 内不变量   | 缓存失效，数据不一致 |


---

## 6. 三级存储与端到端计算流的对应关系

参见 `UFC_端到端计算流主链.md` 中的节点说明：

```
ModelBuilder（L3 Desc 冻结）
    │
    ├─ L3 级存储激活：全程驻留
    │
RT_Step_Init → PH_L4_Init
    │
    ├─ L2 级存储激活：pool_mgr 分配 L4_PH Ctx
    │
RT_Inc_Begin → Newton Iter
    │
    ├─ L1 级存储激活：预分配复用，无额外 ALLOCATE
    │
RT_Conv_Check → 收敛
    │
RT_WriteBack → L3 State 白名单写回
    │
RT_Step_End
    │
    └─ L2 级存储归还：pool_mgr%release(ctx%pool_handle)
       L1 级存储复用：Step 结束不释放预分配数组，供下一 Step 复用
```

---

*本文档是所有域 `*_Ctx` 设计的强制参考，Phase 3 各层子总纲中 CONTRACT.md 的 Ctx 设计必须引用本策略。*