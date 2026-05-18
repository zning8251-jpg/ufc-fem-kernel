# L1_IF/Parallel - ThreadWS 线程工作空间域

## 域职责

**ThreadWS（Thread Workspace）** 提供线程级并行工作空间管理，支持 OpenMP 并行计算中的线程私有数据存储和安全聚合。

### 核心功能

1. **线程工作空间管理**
   - 全局池 → 线程切片 → 局部数组（三级层次结构）
   - 预分配策略避免运行时动态内存开销
   - 线程 ID 自动管理和检测

2. **并行原语封装**
   - 原子操作（Atomic Add、Atomic Compare-and-Swap）
   - 临界区保护（Critical Section）
   - 归约操作（Sum、Max、Min）

3. **OpenMP 集成**
   - `!$OMP PARALLEL DO` 自动线程同步
   - `!$OMP ATOMIC` 原子操作封装
   - `!$OMP CRITICAL` 临界区管理

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 架构位置

```
L1_IF (基础设施层)
├── Base/        - 基础工具
├── Error/       - 错误处理
├── Memory/      - 内存池管理 ✅ 依赖
├── Parallel/    - 并行计算 ← 当前域
│   ├── IF_ThreadWS_Types.f90   - 类型定义
│   ├── IF_ThreadWS_Core.f90    - 核心功能
│   └── IF_ThreadWS_API.f90     - 薄适配器 API
├── Precision/   - 精度定义
└── ...
```

### 依赖关系

```fortran
USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_AllocInt1D  ! 内存池多类型分配
USE IF_Err_API, ONLY: ErrorStatusType, init_error_status
USE IF_Prec_Core, ONLY: wp, i4
```

**铁律**：L1_IF 不依赖任何上层（L2-L6），确保基础设施的独立性和可复用性。

---

## 公共 API

### 1. 初始化和销毁

#### IF_ThreadWS_Init / ThreadWS_Init
```fortran
SUBROUTINE IF_ThreadWS_Init(thread_ws, n_threads, n_real_1d, n_real_2d, &
                            n_int_1d, n_int_2d, n_logical_1d, &
                            max_size_1d, max_size_2d, status)
  !! 初始化线程工作空间管理器
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
  INTEGER(i4), INTENT(IN) :: n_threads          ! 线程数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: n_real_1d    ! 预分配实型 1D 数组数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: n_real_2d    ! 预分配实型 2D 数组数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: n_int_1d     ! 预分配整型 1D 数组数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: n_int_2d     ! 预分配整型 2D 数组数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: n_logical_1d ! 预分配逻辑 1D 数组数量
  INTEGER(i4), INTENT(IN), OPTIONAL :: max_size_1d  ! 1D 数组最大尺寸
  INTEGER(i4), INTENT(IN), OPTIONAL :: max_size_2d  ! 2D 数组最大尺寸
  INTEGER(i4), INTENT(OUT) :: status
```

**使用示例**：
```fortran
TYPE(ThreadWS) :: ws
INTEGER(i4) :: status

CALL ThreadWS_Init(ws, n_threads=4, &
                   n_real_1d=3, max_size_1d=10000, &
                   n_int_1d=2, max_size_1d=5000, status=status)
IF (status /= 0) STOP "Init failed"
```

#### IF_ThreadWS_Destroy / ThreadWS_Destroy
```fortran
SUBROUTINE IF_ThreadWS_Destroy(thread_ws)
  !! 销毁所有线程工作空间并释放内存
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
```

---

### 2. 工作空间访问

#### IF_ThreadWS_GetLocalArray / ThreadWS_GetLocalArray
```fortran
FUNCTION IF_ThreadWS_GetLocalArray(thread_ws, thread_id, array_name, status) RESULT(ptr)
  !! 获取线程私有实型数组指针
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
  INTEGER(i4), INTENT(IN) :: thread_id
  CHARACTER(LEN=*), INTENT(IN) :: array_name
  INTEGER(i4), INTENT(OUT) :: status
  REAL(wp), POINTER :: ptr(:)
```

**使用示例**：
```fortran
REAL(wp), POINTER :: local_values(:)
INTEGER(i4) :: tid, status

tid = OMP_GET_THREAD_NUM() + 1
local_values => ThreadWS_GetLocalArray(ws, tid, 'values', status)

! 线程安全计算
DO i = 1, n_local
  local_values(i) = compute_something(i)
END DO
```

#### IF_ThreadWS_AggregateReal1D / ThreadWS_Aggregate
```fortran
SUBROUTINE IF_ThreadWS_AggregateReal1D(thread_ws, array_index, global_array, &
                                       operation, status)
  !! 将线程局部数组聚合到全局数组
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
  INTEGER(i4), INTENT(IN) :: array_index
  REAL(wp), INTENT(INOUT) :: global_array(:)
  CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: operation  ! 'ADD'/'MAX'/'MIN'
  INTEGER(i4), INTENT(OUT) :: status
```

**归约操作**：
- `'ADD'` / `'SUM'`: 求和归约 `global = SUM(local_thread)`
- `'MAX'` / `'MAXIMUM'`: 最大值归约 `global = MAX(local_thread)`
- `'MIN'` / `'MINIMUM'`: 最小值归约 `global = MIN(local_thread)`

---

### 3. 并行原语

#### IF_ThreadWS_AtomicAdd / AtomicAdd
```fortran
SUBROUTINE IF_ThreadWS_AtomicAdd(value, increment)
  !! 线程安全原子加法
  REAL(wp), INTENT(INOUT) :: value
  REAL(wp), INTENT(IN) :: increment
```

**底层实现**：
```fortran
!$OMP ATOMIC
value = value + increment
```

#### IF_ThreadWS_EnterCritical / EnterCritical
```fortran
SUBROUTINE IF_ThreadWS_EnterCritical(lock)
  !! 进入临界区（互斥锁）
  TYPE(ThreadWSCriticalSection), INTENT(INOUT) :: lock
```

#### IF_ThreadWS_ExitCritical / ExitCritical
```fortran
SUBROUTINE IF_ThreadWS_ExitCritical(lock)
  !! 退出临界区
  TYPE(ThreadWSCriticalSection), INTENT(INOUT) :: lock
```

**使用示例**：
```fortran
TYPE(ThreadWSCriticalSection) :: lock
REAL(wp) :: shared_counter = 0.0_wp

!$OMP PARALLEL DO
DO i = 1, n
  REAL(wp) :: local_result
  
  ! 线程私有计算
  local_result = compute(i)
  
  ! 临界区保护（慢但安全）
  CALL EnterCritical(lock)
  shared_counter = shared_counter + local_result
  CALL ExitCritical(lock)
  
  ! 或使用原子操作（快但仅支持简单操作）
  CALL AtomicAdd(shared_counter, local_result)
END DO
!$OMP END PARALLEL DO
```

---

### 4. 线程管理

#### IF_ThreadWS_SetCurrentThread / ThreadWS_SetCurrentThread
```fortran
SUBROUTINE IF_ThreadWS_SetCurrentThread(thread_ws, thread_id, status)
  !! 设置当前线程 ID（在 OpenMP 并行区自动调用）
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
  INTEGER(i4), INTENT(IN) :: thread_id
  INTEGER(i4), INTENT(OUT) :: status
```

#### IF_ThreadWS_GetCurrentThread / ThreadWS_GetCurrentThread
```fortran
FUNCTION IF_ThreadWS_GetCurrentThread(thread_ws, status) RESULT(thread_id)
  !! 获取当前线程 ID
  TYPE(ThreadWS), INTENT(IN) :: thread_ws
  INTEGER(i4), INTENT(OUT) :: status
  INTEGER(i4) :: thread_id
```

---

## 完整使用示例

### 示例 1：接触刚度并行装配

```fortran
MODULE PH_ContCSR_Parallel
  USE IF_ThreadWS_API
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
CONTAINS
  
  SUBROUTINE PH_ContCSR_AssembleStiffness_Parallel(n_contacts, node_ids, normals, &
                                                   penetrations, penalty_stiffness, &
                                                   row_ptr, col_idx, values, thread_ws, status)
    !! Assemble contact stiffness in parallel using ThreadWS
    INTEGER(i4), INTENT(IN) :: n_contacts
    INTEGER(i4), INTENT(IN) :: node_ids(:, :)
    REAL(wp), INTENT(IN) :: normals(:, :)
    REAL(wp), INTENT(IN) :: penetrations(:)
    REAL(wp), INTENT(IN) :: penalty_stiffness
    INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
    REAL(wp), INTENT(INOUT) :: values(:)
    TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
    INTEGER(i4), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, c, dof_i, dof_j, idx
    INTEGER(i4) :: thread_id, n_threads
    REAL(wp), POINTER :: local_values(:)
    REAL(wp) :: k_normal(3, 3), normal(3)
    
    status = 0
    n_threads = thread_ws%n_threads
    
    ! 获取线程私有工作空间用于部分结果
    !$OMP PARALLEL DO PRIVATE(thread_id, local_values, normal, k_normal) &
    !$OMP                 SHARED(node_ids, normals, penetrations, values)
    DO i = 1, n_contacts
      ! 获取当前线程 ID
      thread_id = OMP_GET_THREAD_NUM() + 1
      
      ! 获取线程私有数组
      local_values => ThreadWS_GetLocalArray(thread_ws, thread_id, 'values', status)
      
      ! 清零局部数组
      local_values = 0.0_wp
      
      ! 计算每个接触点的刚度
      normal = normals(:, i)
      k_normal = MATMUL(RESHAPE(normal, [3, 1]), RESHAPE(normal, [1, 3])) * penalty_stiffness
      
      ! 组装到局部数组（线程安全，无竞争）
      DO c = 1, 3
        dof_i = node_ids(i, 1) * 3 - 3 + c
        dof_j = node_ids(i, 2) * 3 - 3 + c
        
        idx = FINDLOC(col_idx, dof_j, DIM=1, MASK=(row_ptr(dof_i) <= col_idx .AND. &
                                                   col_idx < row_ptr(dof_i+1)))
        IF (idx > 0) THEN
          local_values(idx) = k_normal(c, c)
        END IF
      END DO
      
      ! 聚合到全局数组（使用临界区或原子操作）
      !$OMP CRITICAL
      DO idx = 1, SIZE(values)
        values(idx) = values(idx) + local_values(idx)
      END DO
      !$OMP END CRITICAL
    END DO
    !$OMP END PARALLEL DO
    
  END SUBROUTINE PH_ContCSR_AssembleStiffness_Parallel
  
END MODULE PH_ContCSR_Parallel
```

---

### 示例 2：残差向量并行装配

```fortran
SUBROUTINE RT_Solv_Cont_AssembleResidual_Parallel(solver_state, n_contacts, &
                                                   contact_data, frict_model, &
                                                   global_rhs, thread_ws, status)
  !! Assemble contact residual force in parallel
  TYPE(RT_Solver_State), INTENT(INOUT) :: solver_state
  INTEGER(i4), INTENT(IN) :: n_contacts
  TYPE(RT_ContactData), INTENT(INOUT) :: contact_data(:)
  TYPE(PH_Cont_FrictModel), INTENT(IN) :: frict_model
  REAL(wp), INTENT(INOUT) :: global_rhs(:)
  TYPE(ThreadWS), INTENT(INOUT) :: thread_ws
  INTEGER(i4), INTENT(OUT) :: status
  
  INTEGER(i4) :: i, dof
  INTEGER(i4) :: thread_id
  REAL(wp), POINTER :: local_rhs(:)
  REAL(wp) :: contact_force(3)
  
  status = 0
  
  ! 预分配线程私有 RHS 数组
  CALL ThreadWS_Init(thread_ws, n_threads=4, n_real_1d=1, max_size_1d=SIZE(global_rhs), &
                     status=status)
  
  ! 并行装配
  !$OMP PARALLEL DO PRIVATE(thread_id, local_rhs, contact_force) &
  !$OMP                 SHARED(contact_data, global_rhs)
  DO i = 1, n_contacts
    thread_id = OMP_GET_THREAD_NUM() + 1
    
    ! 获取线程私有 RHS 数组
    local_rhs => ThreadWS_GetLocalArray(thread_ws, thread_id, 'rhs', status)
    local_rhs = 0.0_wp
    
    ! 计算接触力（线程安全）
    IF (contact_data(i)%is_active) THEN
      contact_force = contact_data(i)%contact_normal * &
                      contact_data(i)%penetration_depth * &
                      contact_data(i)%penalty_stiffness
      
      ! 组装到局部 RHS
      dof = contact_data(i)%slave_node_id * 3
      local_rhs(dof-2:dof) = contact_force
    END IF
    
    ! 聚合到全局 RHS
    !$OMP ATOMIC
    DO dof = 1, SIZE(global_rhs)
      global_rhs(dof) = global_rhs(dof) + local_rhs(dof)
    END DO
    !$OMP END ATOMIC
  END DO
  !$OMP END PARALLEL DO
  
  ! 清理
  CALL ThreadWS_Destroy(thread_ws)
  
END SUBROUTINE
```

---

## 性能优化建议

### 1. 预分配策略

```fortran
! ✅ 推荐：预先分配足够大的数组
CALL ThreadWS_Init(ws, n_threads=8, &
                   n_real_1d=5, max_size_1d=100000, &
                   n_int_1d=3, max_size_1d=50000, status=status)

! ❌ 避免：在循环中动态分配
DO i = 1, n
  ALLOCATE(local_array(size))  ! 慢！
END DO
```

### 2. 减少临界区开销

```fortran
! ✅ 推荐：在临界区外完成大部分计算
!$OMP PARALLEL DO
DO i = 1, n
  local_result = expensive_compute(i)  ! 线程私有
  
  !$OMP CRITICAL
  global_sum = global_sum + local_result  ! 仅聚合结果
  !$OMP END CRITICAL
END DO
!$OMP END PARALLEL DO

! ❌ 避免：在临界区内进行大量计算
!$OMP PARALLEL DO
DO i = 1, n
  !$OMP CRITICAL
  result = expensive_compute(i)  ! 慢！串行执行
  global_sum = global_sum + result
  !$OMP END CRITICAL
END DO
!$OMP END PARALLEL DO
```

### 3. 选择正确的归约方式

| 场景 | 推荐方式 | 性能 |
|------|----------|------|
| 简单累加 | `AtomicAdd` | ⭐⭐⭐⭐⭐ 最快 |
| 复杂更新 | `CRITICAL` | ⭐⭐⭐ 中等 |
| 大规模归约 | `AggregateReal1D` | ⭐⭐⭐⭐ 批量处理 |

---

## 架构合规性验证

### 依赖检查

```bash
# 检查 L1_IF/Parallel 是否只依赖 L1 内部模块
grep -E "^USE (L[2-6]|RT_|PH_|MD_|NM_)" UFC/ufc_core/L1_IF/Parallel/*.f90
# 预期：无输出（零依赖上层）
```

### OpenMP 语法检查

```bash
# 检查 OpenMP 指令格式
grep -E "!\$OMP" UFC/ufc_core/L1_IF/Parallel/*.f90
# 预期：正确的编译指导语句
```

### 类型安全验证

```fortran
! 确保指针关联前检查 ALLOCATED
IF (ALLOCATED(thread%real_arrays_1d)) THEN
  ptr => thread%real_arrays_1d(:, i)
END IF
```

---

## 测试计划

### 单元测试

1. **初始化/销毁测试**
   - 边界线程数（1, 64, 128）
   - 不同预分配组合
   - 错误状态码验证

2. **工作空间访问测试**
   - GetLocalArray 返回正确数组
   - 越界访问错误处理
   - 多线程并发访问安全性

3. **并行原语测试**
   - AtomicAdd 精度验证
   - Critical Section 互斥性
   - Aggregate 归约正确性

### 集成测试

1. **接触刚度并行装配**（PH_Cont_CSR 集成）
2. **残差向量并行装配**（RT_Solv_Cont_Residual 集成）
3. **大规模问题弱扩展性**（1K - 1M DOFs）

---

## 历史决策记录

### 为什么将 ThreadWS 从 L5_RT 下沉到 L1_IF？

**问题**：原 RT_StepDriver_WS 在 L5_RT 层，导致 L4_PH 依赖 L5（违反单向依赖铁律）。

**解决方案**：
- 创建 L1_IF/Parallel 域，实现基础设施级 ThreadWS
- PH_Cont_CSR 改用 IF_ThreadWS_API
- 保持 L5_RT 专用扩展（如 BCWorkspace）在 RT_StepDriver_WS

**收益**：
- ✅ 架构合规（L4→L1 单向依赖）
- ✅ 可复用性提升（L2/L3/L4 均可使用）
- ✅ 解耦基础设施与应用逻辑

---

## 交付清单

- [x] `IF_ThreadWS_Types.f90` (+275 行) - 类型定义
- [x] `IF_ThreadWS_Core.f90` (+355 行) - 核心功能
- [x] `IF_ThreadWS_API.f90` (+230 行) - 薄适配器 API
- [x] `CONTRACT.md` (+450 行) - 域合同文档
- [ ] `check_if_threadws.bat` - 验证脚本（待创建）
- [ ] 单元测试（待创建）

**总代码量**：~860 行（不含注释）
**预计工时**：2.5h ✅

---

## Phase 2 完成度

| 任务 | 状态 | 代码量 | 工时 |
|------|------|--------|------|
| A: CSR 接触刚度 | ✅ 完成 | +144 行 | 1.0h |
| C: 残差向量集成 | ✅ 完成 | +364 行 | 2.0h |
| B: ThreadWS 并行 | 🟡 进行中 | +860 行 | 2.5h |

**Phase 2 总计**: 2/3 完成，本任务完成后即可进入 Phase 3！


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_ThreadWS.f90` | `IF_ThreadWS` | `ThreadWSCriticalSection` | `IF_ThreadWS_Init` (SUB,PUB,Init); `IF_ThreadWS_Destroy` (SUB,PUB,Finalize); `IF_ThreadWS_GetLocalArray` (FN,PUB,Query); `IF_ThreadWS_AggregateReal1D` (SUB,PUB,—); `IF_ThreadWS_AtomicAdd` (SUB,PUB,—); `IF_ThreadWS_AtomicAddInt` (SUB,PUB,—); `IF_ThreadWS_EnterCritical` (SUB,PRV,—); `IF_ThreadWS_ExitCritical` (SUB,PRV,—); `IF_ThreadWS_SetCurrentThread` (SUB,PUB,Mutate); `IF_ThreadWS_GetCurrentThread` (FN,PUB,Query); `ITOCHAR` (FN,PRV,—) |
| `IF_ThreadWS_Brg.f90` | `IF_ThreadWS_Brg` | — | `ThreadWS_AllocLocal` (SUB,PUB,—); `ThreadWS_FreeLocal` (SUB,PUB,Finalize) |
| `IF_ThreadWS_Def.f90` | `IF_ThreadWS_Def` | `ThreadWS_ArrayInfo`, `ThreadWorkspace` | `ThreadWS_InitializeWorkspace` (SUB,PRV,Init); `ThreadWS_DestroyWorkspace` (SUB,PRV,Finalize); `ThreadWS_GetReal1D` (SUB,PRV,Query); `ThreadWS_GetReal2D` (SUB,PRV,Query); `ThreadWS_GetInt1D` (SUB,PRV,Query); `ThreadWS_GetInt2D` (SUB,PRV,Query); `ThreadWS_HasArray` (FN,PRV,Query) |


---

### SMP 并行贯通 (v4.0, 2026-04-26)

| 变更 | 说明 |
|------|------|
| IF_ThreadWS_GetLocalArray | 由 STUB 补全为实际实现: 按 array_name 查找 array_info slot, 返回 
eal_arrays_1d(:, slot) 指针 |
| IF_ThreadWS_AggregateReal1D | 由 STUB 补全为实际实现: 遍历所有线程 slot, 支持 ADD/MAX/MIN 归约 |
| IF_ThreadWS_RegisterArray (新增) | 向所有线程注册命名数组 (type/rank/size), 填充 array_info |
| IF_ThreadWS_ResetAll (新增) | 清零所有线程的全部工作区数组 (每次迭代前调用) |
| ThreadWS_GetReal1D/2D/Int1D/2D | 由 STUB (status=-99) 实现为正确的数组 slice 复制 |

**设计文档**: [UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_SMP_PARALLEL_DESIGN.md](../../../../docs/05_Project_Planning/PPLAN/06_核心架构/UFC_SMP_PARALLEL_DESIGN.md)
