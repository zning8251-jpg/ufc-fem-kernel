# L1_IF 基础设施精准融合设计文档

> **版本**: v3.0 | **日期**: 2026-04-26 | **状态**: 设计定稿

---

## 一、设计哲学：精准而非全面

### 1.1 核心原则：按"动态性"决定是否接入 DP

```
                    静态(编译期已知)        动态(运行时确定)
                   ──────────────────  ──────────────────
  COLD (Desc)     | 不用 DP            | 用 DP + SymTbl   |
                  | (D_el, npe, wp)    | (MAT:Steel)      |
                   ──────────────────  ──────────────────
  WARM (State)    | 不用 DP            | 池管理即可          |
                  | (stress_n)         | (SDV 动态数量)     |
                   ──────────────────  ──────────────────
  HOT  (Ctx)      | 绝对不用 DP        | 绝对不用 DP        |
                  | (Ke, B, r, p)      |                   |
                   ──────────────────  ──────────────────
```

**动态数据** = 用户通过 INP 文件定义名称和数量的数据（材料、集合、步、部件）。

**静态数据** = 编译期结构已知、运行时只填值的数据（弹性矩阵、形函数、精度参数）。

### 1.2 不推荐大量使用 DP 的理由

| 因素 | 说明 |
|------|------|
| **性能开销** | DP 查询有 ~50-100ns 开销，HOT_PATH 不可接受 |
| **冗余代价** | 简单域（Part: 3 字段）注册代码比域本身还多 |
| **耦合风险** | 全域 `USE IF_Base_DP` 使 DP 成为"上帝模块" |
| **零开销替代** | Fortran TYPE 直接成员访问（`desc%E`）是零开销 |

### 1.3 推荐精准使用的域（仅 ~6 个动态域）

| 域 | DP 注册 | SymTbl 查找 | 理由 |
|-----|---------|------------|------|
| Material | 已有 | **需接入** | 用户命名材料, O(n)→O(1) 收益最大 |
| Mesh/Sets | 已有 | **需接入** | NSET/ELSET/SURFACE 用户命名集合 |
| Step | 已有 | **需接入** | 步名称查找 |
| Part/Assembly | 简单 | **需接入** | 部件/实例命名 |
| Amplitude | 已有 | 可选 | 幅值名称查找（低频） |
| Output | 已有 | 不需要 | 输出配置, 不按名查找 |

其余域（Section, Constraint, Field, KeyWord, Solver, WriteBack 等）保持现有 TYPE 直接访问，不强制 DP 注册。

---

## 二、容器化与生命周期规范

### 2.1 三级容器架构

```
UFC_GlobalContainer (L0_Global/UFC_GlobalContainer_Core.f90)
 ├── if_layer  : IF_L1_LayerContainer  (7 域: error, log, monitor, memory, io, persist, base)
 ├── nm_layer  : NM_L2_LayerContainer  (6 域: base, linAlg, solver, eigen, timeInt, bridge)
 ├── md_layer  : MD_L3_LayerContainer  (14 域: model..writeback)
 ├── ph_layer  : PH_L4_LayerContainer  (6 域: material, element, loadbc, constraint, contact, bridge)
 ├── rt_layer  : RT_L5_LayerContainer  (bridge + metadata)
 └── ap_layer  : AP_L6_LayerContainer  (3 域: base, input, registry)
```

### 2.2 Init/Finalize 时序与 StorageMgr 挂载

```
Init 顺序 (正向依赖):
  1. L1_IF.error       <- 最先 (错误处理)
  2. L1_IF.log
  3. L1_IF.monitor
  4. L1_IF.memory      <- StorageMgr.Init (创建 10 池)
  5. L1_IF.io          <- SpillFile.Open
  6. L1_IF.persist
  7. L1_IF.base        <- SymTbl.Init, DP.Init
  8. L2_NM.*           <- Solver 向量注册到 P5/P6
  9. L3_MD.*           <- Desc 数据分配到 P1/P2, State 到 P3/P7
 10. L4_PH.*           <- Desc 走 P1, Ctx 走 P5/P6
 11. L5_RT.*           <- 编排，使用全部池
 12. L6_AP.*           <- 用户配置

Finalize 顺序 (严格逆序):
 12. L6_AP.*
 11. L5_RT.*
 10. L4_PH.*
  9. L3_MD.*
  8. L2_NM.*
  7. L1_IF.base        <- DP.Shutdown, SymTbl.Destroy
  6. L1_IF.persist
  5. L1_IF.io          <- SpillFile.Compact + Cleanup
  4. L1_IF.memory      <- StorageMgr.Finalize (释放全部池 + 报告)
  3. L1_IF.monitor
  2. L1_IF.log
  1. L1_IF.error       <- 最后
```

**规则**: 被依赖者先 Init、后 Finalize。StorageMgr 在 memory 域 Init 时创建，在 memory 域 Finalize 时销毁。DP 在 base 域 Init 时启动（此时池已就绪）。

### 2.3 全局容器实现 (Phase 0 已完成)

`UFC/ufc_core/L0_Global/UFC_GlobalContainer_Core.f90`:
- TYPE `UFC_GlobalContainer`: 6 个 LayerContainer 成员 + `initialized` 标志
- `g_ufc_global`: MODULE-level SAVE TARGET 单例
- `Init(nThreads, workDir, status)`: L1→L2→L5→L6 立即初始化；L3/L4 延迟（需 model_name/stepId）
- `Finalize()`: L6→L5→L4→L3→L2→L1 严格逆序
- `IsReady()`: 返回 `initialized` 状态

---

## 三、结构体嵌套深度规范

### 3.1 止步于 3 级: Global → Layer → Domain

最大访问路径深度 = 3 级容器 + 1 级字段：

```fortran
g_ufc_global % md_layer % material % desc % E
|  级别 1    |  级别 2  |  级别 3  | 字段 |
```

**禁止 4 级以上容器嵌套**：

```fortran
! 禁止: Domain 内再嵌套 SubDomain 容器
g_ufc_global % md_layer % material % elas % desc % E   ! 4级 <- 禁止
```

### 3.2 子域处理: 扁平数组 + type_id 分派

Material 域有天然的子族（Elas/Plast/Hyper/...）。用扁平数组 + 类型标签分派：

```fortran
TYPE :: MD_Material_Domain
  INTEGER(i4)           :: n_materials
  TYPE(MD_Mat_Entry)    :: entries(MAX_MATERIALS)  ! 扁平数组
  INTEGER(i4)           :: type_ids(MAX_MATERIALS) ! 类型标签
END TYPE

SELECT CASE (domain%type_ids(i))
  CASE (MAT_ELASTIC)
    CALL PH_Mat_Elas_Compute(domain%entries(i), ...)
  CASE (MAT_PLASTIC)
    CALL PH_Mat_Plast_Compute(domain%entries(i), ...)
END SELECT
```

### 3.3 嵌套深度规则总表

| 级别 | 内容 | 索引方式 | 示例 |
|------|------|---------|------|
| 1 | GlobalContainer | 唯一实例 `g_ufc_global` | `g_ufc_global` |
| 2 | LayerContainer | 按层固定 6 个 | `%md_layer` |
| 3 | Domain | 按域固定 ~14 个 | `%material` |
| 3+ | **扁平数组** | 整数索引或 SymTbl 查找 | `%entries(i)%E` |

**跨域引用**: 继续使用整数外键（`material_id`, `section_id`），这是 Fortran 中最高效的方式。动态域可额外注册 SymTbl 实现 O(1) 命名查找。

---

## 四、扁平域存储与三级存储对齐

### 4.1 扁平存储定义

"扁平域存储" = 同一域的同温度数据存放在连续数组中，不按子类型分散。

```
扁平:   material_props(1:n_mat)       <- 所有材料在一个连续数组
        所有 Elas + Plast + Hyper 混在一起，靠 type_id 区分
        -> 分配到 P1 (COLD_STRUCT) 单一块

嵌套:   elas_props(1:n_elas)          <- 弹性单独
        plast_props(1:n_plast)        <- 塑性单独
        hyper_props(1:n_hyper)        <- 超弹单独
        -> 3 个碎片块，跨缓存行
```

### 4.2 域 → 池映射规则

| 域的数据类型 | 形态 | 池 | 扁平数组示例 |
|------------|------|-----|-----------|
| Desc 结构体 | STRUCT | P1 | `parts(1:n_parts)`, `materials(1:n_mats)` |
| Desc 大数组 | VECTOR | P2 | `coords(3,n_nodes)`, `conn(npe,n_elems)` |
| State 向量 | VECTOR | P3 | `stress_n(6,n_gp)`, `u_n(n_dof)` |
| State 结构体 | STRUCT | P7 | `elem_state(1:n_elems)` |
| Ctx 向量 | VECTOR | P5 | `r(n_dof)`, `Ke(ndof_el,ndof_el)` |
| Ctx 矩阵 | MATRIX | P6 | `K_global(nnz)` |

每域只做一次分配，拿回一个连续块，内部用 offset 索引子元素。

---

## 五、DP/SymTbl 精准融合（仅动态域）

### 5.1 SymTbl 命名约定

仅对用户命名的动态数据注册 SymTbl：

```
SymTbl key = "{DOMAIN_TAG}:{USER_NAME}"

  "MAT:Steel"        -> data_id = 3    (材料)
  "NSET:Fix"         -> data_id = 7    (节点集)
  "ELSET:Plate"      -> data_id = 12   (单元集)
  "SURF:Top"         -> data_id = 5    (表面)
  "STEP:Load1"       -> data_id = 1    (分析步)
  "PART:Bracket"     -> data_id = 2    (部件)
  "INST:Bracket-1"   -> data_id = 4    (实例)
  "AMP:Ramp"         -> data_id = 8    (幅值)
```

### 5.2 SymTbl 接入规则

- **Register**: 在 `*_Core.f90` 的 `Add`/`Register` 过程中调用 `register_variable`
- **Lookup**: 在 `Get_ByName` 过程中调用 `find_variable`
- **不替换整数 FK**: `material_id`, `section_id` 等整数外键保留，SymTbl 是额外的命名索引

### 5.3 DP 使用边界（红线）

| 允许 | 禁止 |
|------|------|
| Bridge 模块调用 `dp_get_*_ptr` 跨域访问 | 域 Core 内直接 `dp_get_*_ptr` 绕过 Bridge |
| 域 Def 中 `dp_register_struct_type` | 热路径中任何 DP 调用 |
| `dp_save` / `dp_load` 用于 Checkpoint | 用 DP 替代 TYPE 直接成员访问 |

---

## 六、错误链设计

### 6.1 何时启用 IF_Err_Chain

| 场景 | 协议 | 示例 |
|------|------|------|
| **跨层调用 (Bridge 出口)** | `UFC_Err_Wrap` | `MD_Model_Brg` 调用 L5 返回错误时包装 |
| **StorageMgr 异步操作** | `UFC_Err_Propagate` | Spill/Reload 失败向上传播 |
| **DP 注册冲突** | `UFC_Err_Wrap` | 重复注册同名变量 |

### 6.2 不改热路径

L4 单元积分循环内仍用局部 `status` + 提前 RETURN，不引入链式开销。

### 6.3 链式传播模式

```fortran
CALL inner_subroutine(args, inner_status)
IF (inner_status%status_code /= IF_STATUS_OK) THEN
  CALL UFC_Err_Wrap(inner_status, LAYER_L5_RT, &
    "RT_StepDriver: step execution failed at increment")
  status = inner_status
  RETURN
END IF
```

### 6.4 错误码段分配

| 范围 | 用途 |
|------|------|
| 10580-10599 | StorageMgr（池 OOM、Spill 失败、Reload 失败） |
| 10600-10619 | DP/SymTbl 冲突（重复注册、命名冲突、查找失败） |

---

## 七、线程安全规范

### 7.1 需要保护的共享资源

| 资源 | 写入场景 | 保护方式 |
|------|---------|---------|
| StorageMgr 池元数据 | 池分配/释放 | `!$OMP CRITICAL(StorageMgr_Alloc)` |
| SymTbl 哈希表 | 变量注册 | `!$OMP CRITICAL(SymTbl_Write)`（读可并发） |
| error_count 累加器 | 验证循环 | `!$OMP ATOMIC` 或 `REDUCTION` |
| IF_Monitor 计数器 | 计数器递增 | `!$OMP ATOMIC` |

### 7.2 已知竞态修复清单

| 位置 | 问题 | 修复 |
|------|------|------|
| `MD_L3_ValidateBindings` | `error_count` / `all_errors` 在 `!$OMP PARALLEL DO` 中无保护 | 改用 `!$OMP PARALLEL DO REDUCTION(+:error_count)` + 线程局部 error buffer |

### 7.3 线程安全分级

| 级别 | 说明 | 适用 |
|------|------|------|
| **Thread-Safe** | 可被多线程并发调用 | `IF_Monitor_Counter_Inc`、SymTbl `find_variable`（只读） |
| **Serialized** | 需要 CRITICAL 保护 | `StorageMgr_Alloc`、`register_variable` |
| **Thread-Local** | 每线程独立工作区 | SP2 HOT_WORKSPACE、IF_ThreadWS |

---

## 八、监控集成规范

### 8.1 StorageMgr 必须内嵌的监控点

| 类型 | 名称 | 说明 |
|------|------|------|
| **计数器** | `pool_alloc_count(pool_id)` | 每个池的分配次数 |
| **计数器** | `spill_count` | Spill 触发总次数 |
| **计数器** | `reload_count` | Reload 触发总次数 |
| **计时器** | `alloc_time_total` | 累计分配耗时 |
| **计时器** | `spill_io_time` | 累计 Spill IO 耗时 |
| **计时器** | `reload_io_time` | 累计 Reload IO 耗时 |
| **水位** | `pool_peak_bytes(pool_id)` | 各池峰值内存 |
| **水位** | `pool_current_bytes(pool_id)` | 各池当前内存 |
| **命中率** | `symtbl_hit_count` / `symtbl_miss_count` | SymTbl 查找命中率 |

### 8.2 实现方式

通过 `IF_Monitor_Core` 的现有 API：

```fortran
CALL IF_Monitor_Timer_Start(mon_state, "StorageMgr_Spill", status)
! ... do spill ...
CALL IF_Monitor_Timer_Stop(mon_state, "StorageMgr_Spill", status)
CALL IF_Monitor_Counter_Inc(mon_state, "spill_count", 1_i4, status)
```

---

## 九、Workspace 注册补全方案

### 9.1 问题

`IF_Mem_WS.f90` 中定义了 `RT_Elem_WS_RegStruct` 等注册 API，L4 调用 `RT_Elem_WS_GetStruct` 获取工作区，但没有任何文件调用 `Reg*` 进行注册。全局过程指针永远为空。

### 9.2 方案

在 L5 初始化阶段注册默认工作区分配器，工作区从 SP2 (HOT_WORKSPACE) 池分配。

```
注册点: RT_L5Layer.f90 Init
  -> CALL RT_Elem_WS_RegStruct(default_struct_allocator)
  -> CALL RT_Elem_WS_RegMultiField(default_multifield_allocator)
```

### 9.3 与三级存储对齐

SP2 (HOT_WORKSPACE) 池专门用于单元级别的临时工作区，每次迭代开始时重置（bump allocator）。Workspace 注册的分配器应从 SP2 池取内存。

---

## 十、Checkpoint 闭环设计

### 10.1 当前碎片化现状

| 位置 | 实现状态 |
|------|---------|
| L6 `AP_Job_SaveChk/LoadChk` | 有实现（文本格式） |
| L5 `RT_WB_Impl_Checkpoint` | Stub（占位） |
| L3 `MD_RestartData` | Stub |
| L1 `IF_IO_Read_Checkpoint` | Stub |
| L1 `dp_save/dp_load` | 仅定义，无调用者 |

### 10.2 统一 Checkpoint 流

```
L5 StepDriver
  -> Checkpoint_Conditional (ASP S13)
    -> [1] StorageMgr snapshot WARM 池 (P3/P7) -> SpillFile
    -> [2] L3 Model 序列化动态域 (SymTbl 注册的材料/集合/步) -> dp_save
    -> [3] L5 Solver 保存 Krylov 向量 / 收敛历史 -> P9 (IO_BUFFER)
    -> [4] L1 IO 统一写出 checkpoint 文件
```

### 10.3 Restart 恢复流

```
L6 AP_Job_LoadChk
  -> [1] L1 IO 读取 checkpoint 文件
  -> [2] StorageMgr 恢复 WARM 池数据
  -> [3] L3 Model dp_load 恢复动态域
  -> [4] L5 Solver 恢复求解器状态
  -> [5] 继续计算
```

---

## 十一、配置注入路径

### 11.1 L6 → L1 配置协议

L6 `AP_Config_Core` 存储 StorageMgr 相关参数：

| 配置键 | 默认值 | 说明 |
|--------|--------|------|
| `STORAGE:POOL_SIZE_MB` | 256 | 总池大小（MB） |
| `STORAGE:SPILL_THRESHOLD` | 0.85 | Spill 触发阈值 |
| `STORAGE:LRU_WINDOW` | 64 | LRU 块窗口大小 |
| `STORAGE:CHECKPOINT_INTERVAL` | 0 | 检查点间隔（0=仅步末） |

### 11.2 注入流

```
L6 Init:
  AP_Config -> key-value 存储
  AP_Config -> Bridge -> L1_StorageMgr_Configure(pool_sizes, thresholds)

若用户未配置:
  StorageMgr 使用硬编码默认值
```

---

## 十二、AI 池对接备忘（仅设计预留）

### 12.1 SP1 (AI_RUNTIME) 与 IF_AI_SessionPool

- `IF_AI_SessionPool` 当前使用自管理的 `pool_size` 和 `slot_index`
- 预留接口：`IF_AI_SessionPool_Acquire` 内部从 SP1 分配
- 6 slot 语义不变：STEPCTR, CONVPRED, MATINT, CONTLAW, PRECOND, SPARSESLV
- 本轮不实施，仅记录设计预留

---

## 十三、动态/静态数据分类总表

| 域 | 数据性质 | 用 DP | 用 SymTbl | 用 Pool | 温度 |
|-----|---------|-------|-----------|---------|------|
| Material | **动态** | 已有 | **接入** | P1/P3 | COLD/WARM |
| Mesh (nodes/elems) | 静态 | 已有 | 不需要 | P2 | COLD |
| Mesh (Sets) | **动态** | 已有 | **接入** | P1 | COLD |
| Step | **动态** | 已有 | **接入** | P1 | COLD |
| Part | **动态** | 简单 | **接入** | P1 | COLD |
| Assembly | 静态 | 简单 | **接入** | P1 | COLD |
| Amplitude | **动态** | 已有 | 可选 | P1 | COLD |
| Section | 静态 | 不用 | 不需要 | P1 | COLD |
| Constraint | 静态 | 不用 | 不需要 | P1 | COLD |
| Interaction | 静态 | 已有 | 不需要 | P1 | COLD |
| Solver | 静态 | 不用 | 不需要 | P5/P6 | HOT |
| Output | 静态 | 已有 | 不需要 | P9 | COLD |
| WriteBack | 静态 | 不用 | 不需要 | - | - |
| KeyWord | 静态 | 不用 | 不需要 | - | COLD |
| Field | 静态 | 已有 | 不需要 | P3 | WARM |

---

## 十四、实施路线（6 Phase）

```
Phase 0 --- GlobalContainer 实体 (已完成)
   |
Phase 1 --- 设计文档 (本文档)
   |
Phase 2 --- SymTbl 命名查找 (动态域)
   |
Phase 3 --- 容器生命周期 + 错误链 + 配置注入
   |
Phase 4 --- 扁平存储 + 线程安全 + 监控 + Workspace
   |
Phase 5 --- 文档更新 + Checkpoint 闭环
```
