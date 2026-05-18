# L5_RT 层设计决策文档

> 状态: CORE | 创建: 2026-04-26 | 版本: v1.1
> 关联: UFC_DOMAIN_PILLAR_ARCHITECTURE.md (域柱架构), L3_MD_DESIGN_DECISIONS.md, L4_PH_DESIGN_DECISIONS.md

## 总论

L5_RT 是 UFC 有限元内核的**运行调度层**，对应 ABAQUS 的 Step/Increment/NR 循环控制器。
与 L3_MD（Desc 主导）和 L4_PH（Algo 主导）不同，L5 以**调度编排**为核心产出。

```
L3_MD = Desc 主导 (写一次, 运行时只读)  -->  "数据定义层"
L4_PH = Algo 主导 (热路径, 每IP每迭代)  -->  "物理计算层"
L5_RT = Driver 主导 (编排, 步推进, 收敛) -->  "运行调度层"
```

## 四型在 L5 的角色

| 四型 | L3 角色 | L4 角色 | L5 角色 |
|------|--------|--------|--------|
| Desc | 核心产出 | 冷缓存 | 配置参数 (步定义/求解器参数) |
| State | 辅助追踪 | 核心产出 (stress/SDV) | 核心产出 (步/增量/迭代状态) |
| Algo | 不常用 | 灵魂 (算法路由) | 控制策略 (NR配置/步切割/收敛准则) |
| Ctx | 不常用 | 灵魂 (IP工作区) | 灵魂 (运行时上下文/全局系统引用) |

---

## 金线归属 (Production vs Core)

### 5 对双轨模块

| 域 | 金线 (GOLDEN-LINE) | 门面 (FACADE) |
|----|-------------------|---------------|
| Solver | `RT_Solv.f90` (6616行) + `RT_SolvNonlin.f90` | `RT_Solv_Core.f90` (SKELETON) |
| Assembly | `RT_AsmSolv.f90` (3170行) | `RT_Asm_Core.f90` (thin ops) |
| StepDriver | `RT_StepExec.f90` + `RT_StepImpl.f90` | `RT_StepDriver_Core.f90` (DEMO) |
| WriteBack | `RT_WBDomain.f90` (1179行) | `RT_WriteBack_Core.f90` (SKELETON) |
| Contact | `RT_ContSolv.f90` | `RT_Contact_Core.f90` (simplified) |

**原则**: 新代码走金线路径；FACADE 保留为教学/测试/未来重构入口。

---

## L5 过程命名对照表 (Phase x Verb)

### Phase 轴 (L5 视角)

| Phase | 含义 | L5 典型场景 |
|-------|------|-----------|
| Setup | 分析初始化 | Init/Configure/Populate |
| StepBegin | 步开始 | Begin_Step/Set_StepConfig |
| IncrBegin | 增量步开始 | Begin_Increment/Predict |
| Iteration | NR 迭代内 | Assemble/Solve/Update/Check |
| IncrEnd | 增量步结束 | Accept/Commit/WriteBack |
| StepEnd | 步结束 | End_Step/Output |
| Teardown | 分析结束 | Finalize/Cleanup |

### Verb 轴 (L5 视角)

| Verb | 含义 | 命名规范 | 示例 |
|------|------|---------|------|
| Init | 初始化 | `RT_{Domain}_Init` | `RT_L5_Init` |
| Finalize | 释放 | `RT_{Domain}_Finalize` | `RT_L5_Finalize` |
| Begin | 阶段开始 | `RT_{Domain}_Begin_*` | `RT_StepDriver_Begin_Step` |
| End | 阶段结束 | `RT_{Domain}_End_*` | `RT_StepDriver_End_Increment` |
| Assemble | 全局装配 | `RT_Asm_*` | `RT_Asm_GlobalStiffness` |
| Solve | 线性求解 | `RT_Solv_*` | `RT_Solv_Core_Solve_Linear` |
| Check | 收敛判定 | `RT_{Domain}_Check_*` | `RT_Solv_Core_Check_Convergence` |
| Update | 状态更新 | `RT_{Domain}_Update_*` | `RT_Contact_Update_Status` |
| Cutback | 步切割 | `RT_{Domain}_Cutback` | `RT_StepDriver_Cutback` |
| Execute | 编排执行 | `RT_{Domain}_Execute*` | `RT_StepDriver_Execute` |
| Write | 输出写入 | `RT_Output_Write_*` | `RT_Output_Write_Frame` |
| Run | 顶层运行 | `RT_{Domain}_Run*` | `RT_StepDriver_Run` |

---

## 12 域 四型裁剪概览

| 域 | Desc | State | Algo | Ctx | 说明 |
|----|------|-------|------|-----|------|
| StepDriver | Y | Y | Y | Y | 四型全保留，步驱动核心 |
| Solver | Y | Y | Y | Y | 四型全保留 (分散在多个模块) |
| Assembly | Y | Y | - | Y | 无独立 Algo (算法在 Solver) |
| Element | Y | Y | - | Y | RT 路径编排，计算在 L4 |
| Material | - | - | - | Y(轻量) | 纯路由域，Ctx 仅为分发 |
| Contact | Y | Y | Y | Y | 四型全保留，编排-计算分工 |
| LoadBC | Y | - | Y | Y | 编排载荷应用 |
| Output | Y | Y | - | Y | 输出编排 |
| WriteBack | Y | Y | - | - | 回写编排 |
| Logging | Y | - | - | - | 日志 (仅 Desc) |
| Bridge | Y | - | - | - | 桥接 (仅 Desc) |
| Coupling | Y | Y | Y | Y | 多物理场 (SKELETON) |

---

## 层容器设计

### RT_L5_LayerContainer 结构 (v4.0)

```
RT_L5_LayerContainer
  bridge       :: RT_Bridge_Domain
  step_desc    :: RT_Step_Desc       (步配置)
  step_state   :: RT_Step_State      (步/增量/迭代状态)
  solver_cfg   :: RT_Sol_Cfg         (求解器配置)
  asm_cfg      :: RT_Asm_Cfg         (装配配置)
  output_state :: RT_Output_State    (输出状态)
  phase        :: INTEGER(i4)        (层级阶段门)
  currentStepId   :: INTEGER(i4)
  currentIncrId   :: INTEGER(i4)
  wallClockStart  :: REAL(wp)
  initialized     :: LOGICAL
```

### 生命周期阶段门

```
RT_L5_PHASE_UNINIT     = 0   -- 未初始化
RT_L5_PHASE_INIT       = 1   -- Init 完成
RT_L5_PHASE_STEP_BEGIN = 2   -- 步开始
RT_L5_PHASE_ASSEMBLING = 3   -- 正在总装
RT_L5_PHASE_SOLVING    = 4   -- 正在求解
RT_L5_PHASE_CONVERGED  = 5   -- 本增量步收敛
RT_L5_PHASE_OUTPUT     = 6   -- 正在输出
RT_L5_PHASE_STEP_END   = 7   -- 步结束
```

---

## 三级状态机 (v4.1)

### 总览

L5_RT 运行时采用**三级嵌套状态机**驱动分析执行：

```
┌─ Level 1: 分析步 (Step) ──────────────────────────────────┐
│  RT_STEP_*:  IDLE → RUNNING → {CONVERGED|CUTBACK} → COMPLETED  │
│                                                               │
│  ┌─ Level 2: 增量步 (Increment) ─────────────────────────┐   │
│  │  RT_INC_*:  IDLE → PREDICTING → ITERATING             │   │
│  │               → {CONVERGED|CUTBACK|FAILED}             │   │
│  │                                                        │   │
│  │  ┌─ Level 3: 迭代步 (Iteration) ──────────────────┐   │   │
│  │  │  RT_ITER_*: NOT_STARTED → ASSEMBLING → SOLVING  │   │   │
│  │  │    → UPDATING → CHECKING                        │   │   │
│  │  │    → {CONVERGED|CONTINUING|DIVERGED}             │   │   │
│  │  └────────────────────────────────────────────────┘   │   │
│  └───────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### Level 1: 分析步枚举 (RT_STEP_*)

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | RT_STEP_IDLE | 未开始 |
| 1 | RT_STEP_RUNNING | 执行中 |
| 2 | RT_STEP_CONVERGED | 本增量步收敛 |
| 3 | RT_STEP_CUTBACK | 需要步切割 |
| 4 | RT_STEP_FAILED | 不可恢复失败 |
| 5 | RT_STEP_COMPLETED | 步完成 |

合法转移: IDLE→RUNNING, RUNNING→{CONVERGED,CUTBACK,FAILED},
CONVERGED→{RUNNING,COMPLETED}, CUTBACK→{RUNNING,FAILED}

### Level 2: 增量步枚举 (RT_INC_*)

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | RT_INC_IDLE | 未开始 |
| 1 | RT_INC_PREDICTING | 预测阶段 |
| 2 | RT_INC_ITERATING | NR 迭代中 |
| 3 | RT_INC_CONVERGED | 本增量步收敛 |
| 4 | RT_INC_CUTBACK | 需要步切割 |
| 5 | RT_INC_FAILED | 不可恢复失败 |

合法转移: IDLE→PREDICTING, PREDICTING→ITERATING,
ITERATING→{CONVERGED,CUTBACK,FAILED}, CONVERGED→IDLE, CUTBACK→IDLE

### Level 3: 迭代步枚举 (RT_ITER_*)

| 值 | 常量 | 含义 |
|----|------|------|
| 0 | RT_ITER_NOT_STARTED | 未开始 |
| 1 | RT_ITER_ASSEMBLING | 正在总装 K/F |
| 2 | RT_ITER_SOLVING | 正在线性求解 |
| 3 | RT_ITER_UPDATING | 正在更新 u += du |
| 4 | RT_ITER_CHECKING | 正在检查收敛 |
| 5 | RT_ITER_CONVERGED | 已收敛 |
| 6 | RT_ITER_CONTINUING | 未收敛，继续 |
| 7 | RT_ITER_DIVERGED | 发散 |

合法转移: NOT_STARTED→ASSEMBLING, ASSEMBLING→SOLVING,
SOLVING→UPDATING, UPDATING→CHECKING,
CHECKING→{CONVERGED,CONTINUING,DIVERGED}, CONTINUING→ASSEMBLING

### 三级联动协议

```
Step[RUNNING]
  └─ Inc[PREDICTING → ITERATING]
       └─ Iter[ASSEMBLING → SOLVING → UPDATING → CHECKING]
            ├─ Iter[CONVERGED]  → Inc[CONVERGED]  → Step[CONVERGED] → 下一增量步
            ├─ Iter[CONTINUING] → 下一迭代
            └─ Iter[DIVERGED]   → Inc[CUTBACK]    → Step[CUTBACK]   → 重试
```

Layer Phase 联动:

| 三级状态机事件 | 层相 RT_L5_PHASE_* |
|---------------|-------------------|
| RT_STEP_RUNNING 开始 | STEP_BEGIN |
| RT_ITER_ASSEMBLING 进入 | ASSEMBLING |
| RT_ITER_SOLVING 进入 | SOLVING |
| RT_INC_CONVERGED 达成 | CONVERGED |
| 输出触发 | OUTPUT |
| RT_STEP_COMPLETED 达成 | STEP_END |

### RT_Step_Ctx 迭代诊断字段

```
RT_Step_Ctx (v4.1):
  inc_status      :: INTEGER(i4)   -- RT_INC_* (Level 2 当前状态)
  iter_status     :: INTEGER(i4)   -- RT_ITER_* (Level 3 当前状态)
  inc_iters       :: INTEGER(i4)   -- 当前增量步 NR 迭代次数
  res_norm_0      :: REAL(wp)      -- ||R_0|| 参考残差
  res_norm        :: REAL(wp)      -- ||R_k|| 当前残差
  res_norm_prev   :: REAL(wp)      -- ||R_{k-1}|| 上一残差
  disp_norm       :: REAL(wp)      -- ||du_k|| 位移修正
  conv_rate       :: REAL(wp)      -- ||R_k|| / ||R_{k-1}|| 收敛速率
  pnewdt          :: REAL(wp)      -- 建议 dt 比率 (来自 UMAT 等)
```

---

## NR 核心循环 (金线调用链)

```
RT_StepExec::RT_StepDriver_Execute
  for each Step:
    RT_StepDriver_Begin_Step()
    for each Increment:
      RT_StepDriver_Begin_Increment()
      for each NR Iteration:
        RT_Asm_Complete()             -- 金线: RT_AsmSolv.f90
          RT_Asm_GlobalStiffness()    -- element loop -> L4 Compute_Ke
          RT_Asm_GlobalLoad()         -- L4 LoadBC
          RT_Asm_ApplyBC()            -- Dirichlet
          RT_Asm_ApplyL3Constraints() -- MPC/Rigid
          RT_Asm_ApplyContact()       -- L4 Contact
        RT_NLSolver_NewtonRaph()      -- 金线: RT_SolvNonlin.f90
          RT_Solv_Core_Solve_Linear() -- K du = -R
          RT_Solv_Core_Apply_Increment() -- u += du
        RT_SolIterMgr_ChkConv()       -- 金线: RT_Solv.f90
        if converged: break
      end NR
      RT_WBDomain::WriteBack()        -- 金线: RT_WBDomain.f90
      RT_Output_Write_Frame()
      RT_StepDriver_End_Increment()
    end Increment
    RT_StepDriver_End_Step()
  end Step
```

---

## 实施文件清单

| Phase | 文件 | 变更 |
|-------|------|------|
| 0 | `Solver/RT_Solv.f90` | 标记 GOLDEN-LINE |
| 0 | `Solver/RT_SolvNonlin.f90` | 标记 GOLDEN-LINE |
| 0 | `Solver/RT_Solv_Core.f90` | 标记 FACADE |
| 0 | `Assembly/RT_AsmSolv.f90` | 标记 GOLDEN-LINE |
| 0 | `Assembly/RT_Asm_Core.f90` | 标记 FACADE |
| 0 | `WriteBack/RT_WBDomain.f90` | 标记 GOLDEN-LINE |
| 0 | `WriteBack/RT_WriteBack_Core.f90` | 标记 SKELETON/FACADE |
| 0 | `Contact/RT_ContSolv.f90` | 标记 GOLDEN-LINE |
| 0 | `Contact/RT_Contact_Core.f90` | 标记 FACADE |
| 0 | Material/CONTRACT.md, Contact/CONTRACT.md | 四型裁剪决策补全 |
| 0 | `docs/L5_RT_DESIGN_DECISIONS.md` | 本文档 |
| 1 | `RT_L5Layer.f90` | 容器补全 + RT_L5_PHASE_* + TBP |
| 2 | `StepDriver/RT_StepExec.f90` | 标记 GOLDEN-LINE |
| 2 | `StepDriver/RT_StepDriver_Core.f90` | 标记 DEMO |
| 2 | `StepDriver/RT_StepImpl.f90` | 标记 GOLDEN-LINE |
| 3 | `Assembly/RT_AsmSolv.f90` | USE MD_* 分类标注 |
| 3 | `Solver/RT_Solv.f90` | 职责分区注释 |
| 4 | `Bridge/RT_Brg_Def.f90` | Bridge 域扩充 |
| 4 | Coupling/AI 模块 | PLACEHOLDER 标记 |

---

## 审计记录

### Assembly USE MD_* 分类 (Phase 3)

| 分类 | 模块 | 说明 |
|------|------|------|
| COLD-OK | MD_ModelLib, MD_FieldState, MD_Step_Proc | 模型/步配置 |
| COLD-OK | MD_LBC, MD_LBC_Idx, MD_LBC_Domain, MD_BC_Def, MD_Load_Def | 载荷/BC 定义查询 |
| COLD-OK | MD_Assem_Domain | Set/Surface 名查询 |
| COLD-OK | MD_Cont, MD_ContPH_Brg | 接触定义/桥接 |
| COLD-OK | MD_LBCPH_Brg | 载荷桥接 |
| COLD-OK | MD_Elem | 单元类型枚举 |
| COLD-OK | MD_Model_Def, MD_Constraint_Def, MD_ConstraintSurfBridge | 约束定义 |
| HOT-ADJACENT | MD_Mesh (connectivity/coords/section) | 单元循环前数据获取 |
| HOT-ADJACENT | MD_SectDomain (section queries) | 截面查询 |

HOT-ADJACENT: 目前在单元循环前调用，未在 IP 级热循环内。
未来应迁移至 L4 Populate 缓存路径。

---

## Material 域重构 (v4.1)

### 决策：L5/Material = 纯路由域

L5/Material 从"自建四型+本地计算"重构为"纯路由域"：

| 重构前 | 重构后 |
|--------|--------|
| 自建 `RT_Mat_Desc/State/Algo/Ctx` | 仅保留 `RT_Mat_Dispatch_Ctx`（路由上下文） |
| 本地弹性/塑性计算 | 路由验证 + 委托 L4 `PH_Mat_Update_Stress` |
| `RT_MAT_ELASTIC=1,2,3` | 使用 L4 `MAT_*` 枚举 (101-1102) |
| 零跨层引用 | Bridge 链 (BuildTable/MakeCtx/WriteBackHook) |

### L5/Material 路由表

```
RT_Mat_Dispatch_Table
  entries[1..n] = { mat_type, mat_id, mat_pt_idx, is_user, active }
  ↓
RT_Mat_Brg_MakeCtx(table, mat_id) → RT_Mat_Dispatch_Ctx
  ↓
RT_Mat_Dispatch_Stress(ctx) → validate → delegate to L4
```

### MAT_* 族 ID 三层对齐

| 层 | 模块 | 角色 |
|----|------|------|
| L3 | `MD_Mat_BaseDef` (原 Base/MD_Mat_Def) | AUTHORITY (SSOT) |
| L4 | `PH_MatReg` | MIRROR（编译独立） |
| L5 | via `RT_Mat_Dispatch_Table` | CONSUMER（不透明整数） |

### L3 类型系统统一

| 模块 | 角色 | 类型风格 |
|------|------|---------|
| `MD_Mat_BaseDef` (原 Base/MD_Mat_Def) | 简单类型 + MAT_* 常量 | `MD_Mat_Desc`, `MD_Mat_Ctx` |
| `MD_Mat_Def` (Contract/) | 富四类系统 | `MD_Mat_Desc EXTENDS DescBase` |

已解决 MODULE 同名冲突：Base 版重命名为 `MD_Mat_BaseDef`。

### PH_MatDispatch 可见性修复

`PH_Mat_Compute_CTM` 和 `PH_Mat_Init_SDV` 已添加到 `PH_MatDispatch` 的 `PUBLIC` 列表。

### UMAT 统一路由路径

```
L5 RT_Mat_Dispatch_Ctx.is_user_sub
  → L4 PH_Mat_Reg_Get(MAT_USER_UMAT = 1101)
  → L4 PH_UserSub_UMAT (用户子程序执行)
```

L5 作为统一分发入口，L4 注册表作为实现查找表。

---

## Element 域重构 (v2.0)

> 日期: 2026-04-26 | 触发: Element Domain Pillar 一体化设计

### 问题诊断

L5/Element 域存在 8 个核心问题:

1. **双头 TYPE 定义**: `RT_Elem_Def` 和 `RT_Element_Def` 两个模块定义了同名但不同结构的 `RT_Elem_State`/`RT_Elem_Ctx`
2. **7 套并行路径**: Dispatcher/Dispatch_Brg/ComputeProc/KernelProc/AsmProc/ElemProc/Element_Core 相互重叠
3. **Mesh 子域越权**: L5/Element/Mesh/ 定义了完整四型，需明确为"运行时视图"
4. **L4 重复文件**: `PH_ElemShapeFunc.f90` 同时在 `Element/` 和 `Element/Shared/`
5. **类型 ID 未对齐**: L3 `ELEM_*`/`FAMILY_*` 与 L4 `PH_ELEM_FAMILY_*` 两级体系未明确
6. **L4 无抽象基类**: 203 文件全部 SELECT CASE 分发（暂不改，标记中期目标）
7. **合同/代码漂移**: 三层 CONTRACT 文件名/模块名不匹配
8. **Bridge 链缺 WriteBack**: L5→L3 元素级 WriteBack 钩子缺失

### 实施决策

#### TYPE 统一 (Phase 0)

- `RT_Elem_Def` 扩展为完整四型: Desc/State/Algo/Ctx + Dispatch Table 类型
- `RT_Elem_Desc`: wraps `PH_Elem_Base_Desc` + 域级统计 (n_elem, max_nn, ndof_per_node)
- `RT_Elem_State`: wraps `PH_Elem_Base_State` + assembly (n_eq, eq_map) + kernel (statev, energy)
- `RT_Elem_Algo`: wraps `PH_Elem_Base_Algo` + calc_type, nlgeom
- `RT_Elem_Ctx`: wraps `PH_Elem_Base_Ctx` + assembly offsets + DOF scratch (conn, dof_map)
- `RT_Elem_Router_Entry` + `RT_Elem_Dispatch_Table` + `RT_Elem_Compute_Proc` 抽象接口
- `RT_Element_Def` 降级为 LEGACY wrapper (re-exports RT_Elem_Def)

#### 模块角色精简 (Phase 1)

| 模块 | 新状态 | 原因 |
|------|--------|------|
| `RT_ElemDispatcher` | ACTIVE | 主路由，修复类型引用 |
| `RT_Element_Core` | LEGACY | 仅测试用，生产路径不调用 |
| `RT_ElemKernelProc` | SKELETON | 有预存编译问题 |
| `RT_ElemComputeProc` | SKELETON | 参数不匹配 bug |
| `RT_ElemAsmProc` | SKELETON | 生产路径走 RT_AsmSolv |
| `RT_ElemProc` | SKELETON | 接口定义，待注册机制落地 |

#### 类型 ID 两级体系 (Phase 2)

- L3 `MD_Elem_Reg`: AUTHORITY for `FAMILY_*` (1-17) + `ELEM_*` (10-80)
- L3 `MD_Elem`: AUTHORITY for 细粒度 `PH_ELEM_*` (4000+ 常量)
- L4 `PH_ElemReg`: AUTHORITY for `PH_ELEM_FAMILY_*` (1-12); imports `PH_ELEM_*` from L3
- L5: 通过 Dispatch Table 间接消费，不持有常量

#### Bridge 链闭环 (Phase 3)

新增 `RT_ElemWB_Brg.f90` 提供:
- `RT_ElemWB_Brg_Filter`: NaN/Inf 检测
- `RT_ElemWB_Brg_AggregateEnergy`: 能量聚合

Mesh 子域明确标注为 "RUNTIME VIEW — NOT SSOT"。

#### 与 Material 域柱的差异

| 特征 | Material (P1) | Element (P2) |
|------|--------------|--------------|
| L5 角色 | 纯路由 (Thin Router) | 路由 + DOF 管理 + 循环编排 |
| L5 四型 | 仅 Ctx (其余委托) | 全四型保留 |
| ID 体系 | 单级 MAT_* (101-1102) | 两级: elem_type_id + family_id |
| L4 规模 | ~10 文件 | 203 文件 |
| L5 Dispatch | RT_Mat_Dispatch_Table | RT_Elem_Dispatch_Table |

---

## LoadBC 域重构 (v2.0)

> 日期: 2026-04-26 | 触发: LoadBC Domain Pillar 一体化设计

### 问题诊断

L5/LoadBC 域存在 9 个核心问题:

1. **双头 TYPE 定义**: `RT_LoadBC_Def` 和 `RT_LBC_Def` 定义同名但不同结构的四型
2. **生产路径断连**: `RT_AsmSolv` 直连 L3 `MD_LBC` + L4 `PH_LoadBC_Domain`，绕过 L5/LoadBC
3. **悬挂引用**: `RT_AsmGlobal.f90` 中 `USE RT_Asm_LoadBC_Apply` 引用不存在的模块
4. **L3 巨型文件**: `MD_LBC.f90` 约 6000 行（L3 范畴，仅标记）
5. **L4 三套并行枚举**: `PH_Ldbc`/`PH_LoadBC_Def`/`PH_Load_Def`
6. **空 Bridge**: `RT_LoadBC_Brg.f90` 为空壳
7. **缺失约束实现**: Tie/MPC/Coupling/RigidBody 在 L5 无实现
8. **分散 L4 Bridge**: LoadBC 桥接分散在多模块
9. **合同/代码文件名漂移**: CONTRACT 引用不存在的文件名

### 实施决策

#### TYPE 统一 (Phase 0)

- `RT_LBC_Def` 扩展为统一四型 AUTHORITY + 生命周期过程
- `RT_LoadBC_Desc` 吸收 `n_loads`, `n_bcs`, `ndof_global`
- `RT_LoadBC_Ctx` 新增 `F_global`, `u_prescribed`, `bc_flags` POINTER
- `RT_LoadBC_State` 新增 `current_amp`, `time`
- `RT_LoadBC_Def` 降级 LEGACY wrapper

#### 模块角色精简 + Bridge 扩展 (Phase 1)

| 模块 | 新状态 | 原因 |
|------|--------|------|
| `RT_LBC_Def` | ACTIVE | 统一四型 AUTHORITY |
| `RT_LoadBC_Brg` | ACTIVE | FromL3/ToL4/WriteBack |
| `RT_LBCImpl` | ACTIVE+SKELETON | load/BC active; 约束 skeleton |
| `RT_BCReactionForce` | ACTIVE | BC 处理 + reaction |
| `RT_LoadBC_Core` | LEGACY | 生产路径不调用 |

悬挂引用修复: `RT_AsmGlobal.f90` 中 `USE`/`CALL` 已注释 (DANGLING-REF)

#### L4 枚举对齐 (Phase 2)

| 模块 | 角色 | 枚举 |
|------|------|------|
| `PH_Ldbc` | AUTHORITY | `PH_LOAD_*` (1-8), `PH_BC_*` (1-3) |
| `PH_LoadBC_Def` | LEGACY MIRROR | `LOAD_*` (1-6) |
| `PH_Load_Def` | LEGACY MIRROR | `LOAD_TYPE_*` (1-6) |

#### 与 Material/Element 域柱的对比

| 特征 | Material (P1) | Element (P2) | LoadBC (P4) |
|------|--------------|--------------|-------------|
| L5 角色 | 纯路由 | 路由+DOF+编排 | 编排+收敛控制 |
| L5 四型 | 仅 Ctx | 全四型 | 全四型 |
| 生产路径 | dispatch to L4 | AsmSolv to L4 | AsmSolv 直连 L3/L4 |
| 枚举 | 单级 MAT_* | 两级 elem+family | 三套并行(标注AUTHORITY) |
| Bridge | BuildTable/MakeCtx/WB | Dispatcher/WB_Brg | FromL3/ToL4/WriteBack |

---

## Contact ع (v2.0)

### ֵ

| # |  |  | ض |
|---|------|---|--------|
| I1 | L5 ˫ͷ TYPE: RT_Cont_Def () vs RT_Contact_Def (stub) | L5 |  |
| I2 | L5 ͬ: RT_Contact_Core (FACADE) vs RT_ContactCore (ACTIVE) | L5 |  |
| I3 | : MD_Model_Brg USE ڵ RT_ContactSurface/RT_ContactTypes | L3->L5 |  |
| I4 | L4 ظ MODULE: PH_ContSearchAdvanced  MODULE RT_ContSearch ( L5 ͬ) | L4+L5 |  |
| I5 | L4 ˫: PH_Contact_Def (SKELETON) vs PH_Cont_Def () | L4 |  |
| I6 | L5 Bridge Ǽ: RT_Contact_Brg տ | L5 |  |
| I7 | L3 ְԽ: MD_Int.f90 Ӵѧ | L3 |  |
| I8 | L3 ˫ͷ Desc: MD_Interaction_Def vs MD_Int_Def ͬͬ | L3 |  |
| I9 |  CONTRACT.md ʱ | ȫ |  |

### ʵʩ

| Phase |  | ״̬ |
|-------|------|------|
| 0 | RT_Cont_Def AUTHORITY + RT_Contact_Def LEGACY wrapper |  |
| 1 | MD_Model_Brg ޸ + RT_Contact_Brg չ |  |
| 2 | PH_ContSearchAdvanced MODULE  PH_ContSearchAdv + öٱע |  |
| 3 |  CONTRACT v2.0 д |  |
| 4 | ĵ + DESIGN_DECISIONS ͬ |  |

###  Material/Element/LoadBC Ա

| ά | Material (P1) | Element (P2) | LoadBC (P4) | Contact (P3) |
|------|---------------|--------------|-------------|--------------|
| L5 AUTHORITY | RT_Mat_Dispatch_Table | RT_Elem_Def | RT_LBC_Def | RT_Cont_Def |
| L5 LEGACY | - | RT_Element_Def | RT_LoadBC_Def | RT_Contact_Def |
| L4 AUTHORITY | PH_MatReg | PH_ElemReg | PH_Ldbc | PH_Cont_Def |
| L5 Bridge | RT_Mat_Brg | RT_ElemWB_Brg | RT_LoadBC_Brg | RT_Contact_Brg |
| · | dispatch | RT_ElemDispatcher | RT_AsmSolv | RT_ContSolv |
| ö | MAT_*  | ELEM_*/FAMILY_* | PH_LOAD_*/PH_BC_* | RT_CONT_*/PH_FRIC_*/PH_FRICT_* |
|  | ˫ͷ L3 | L5 dual TYPE | Dangling USE | MODULE  +  |

---

## Output 域重构 (v2.0) — 2026-04-26

### 问题识别

| # | 问题 | 严重度 |
|---|------|--------|
| O1 | L5 双 TYPE 系统: RT_Output_Def vs RT_Out_Def | 高 |
| O2 | L5 双命名轨道: RT_Output_* vs RT_Out_* | 高 |
| O3 | L3 三重 MD_Output_Desc 定义 | 高 |
| O4 | RT_Output_Brg SKELETON 空壳 | 中 |
| O5-O7 | L4/L5/L3 CONTRACT 命名漂移 | 中 |
| O8 | MD_UniFldRT_Brg 域标签错误 (标注 Output 实为 Material) | 低 |

### 实施决策

| 决策 | 内容 |
|------|------|
| AUTHORITY | RT_Out_Def.f90 (丰富四型: 7 TYPE + TriggerCtx) |
| LEGACY | RT_Output_Def.f90 (最简三型, 不扩展) |
| Golden Path | RT_Out.f90 (生产编排) |
| LEGACY/FACADE | RT_Output_Core.f90 (文件 I/O 包装) |
| Bridge | RT_Output_Brg: SKELETON -> ACTIVE (FromL3/ToL4/CollectResults) |

### 与其他域柱对比

| 维度 | Output (P5) | WriteBack (P6) |
|------|-------------|----------------|
| L5 AUTHORITY | RT_Out_Def | RT_WB_Def |
| L5 LEGACY | RT_Output_Def | RT_WriteBack_Def |
| L4 AUTHORITY | PH_Out | PH_WB |
| L5 Bridge | RT_Output_Brg | RT_WriteBack_Brg |
| 生产路径 | RT_Out | RT_WBDomain |

---

## WriteBack 域重构 (v2.0) — 2026-04-26

### 问题识别

| # | 问题 | 严重度 |
|---|------|--------|
| W1 | L5 双 TYPE 系统: RT_WriteBack_Def vs RT_WB_Def | 高 |
| W2 | RT_WriteBack_Core SKELETON/FACADE | 高 |
| W3 | RT_WriteBack_Brg SKELETON 空壳 | 高 |
| W4 | RT_WBDomain 头部 GOLDEN-LINE / Draft 冲突 | 中 |
| W5 | 双重 Target 分类 (RT_WB_Def vs RT_WBDomain) | 中 |
| W6 | CMake 排除整个 L5 WriteBack 子树 | 中 |
| W7 | L3/L4 CONTRACT 命名漂移 | 中 |

### 实施决策

| 决策 | 内容 |
|------|------|
| AUTHORITY | RT_WB_Def.f90 (丰富四型: 6 TYPE) |
| LEGACY | RT_WriteBack_Def.f90 (最简二型, 不扩展) |
| Golden Path | RT_WBDomain.f90 (域逻辑) |
| LEGACY/FACADE | RT_WriteBack_Core.f90 (stub 门面) |
| Bridge | RT_WriteBack_Brg: SKELETON -> ACTIVE (FromL5/ToL4/ToL3) |
| 头部清理 | RT_WBDomain Draft 块已移除, 统一为 GOLDEN-LINE |

---

### 半贯通柱 AUTHORITY 标注 (v2.0, 2026-04-26)

在 L5_RT 层，以下半贯通柱模块被标注为 **AUTHORITY**:

| 半柱 | L5 AUTHORITY 模块 | L5 GOLDEN-LINE | 说明 |
|------|------------------|----------------|------|
| H3 Assembly | `RT_Asm_Def.f90` | `RT_AsmSolv.f90` | 全局 K/F 装配四型 |
| H4a Step | `RT_StepDriver_Def.f90` | `RT_StepExec.f90` | 三级状态机四型 |
| H4b Solver | `RT_Solv_Def.f90` | `RT_Solv.f90` + `RT_SolvNonlin.f90` | 运行时求解器类型 |

H1 Constraint 和 H2 Field 在 L5 无独立目录:
- H1: 约束贡献融入 `RT_AsmSolv::RT_Asm_ApplyL3Constraints`
- H2: 场变量操作分散于 Output/WriteBack/Assembly/StepDriver

H5 Bridge 重新分类为 **基础设施域** (非域柱)。

**架构文档**: `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §5b

---

### H6 Coupling AUTHORITY 标注 (v2.1, 2026-04-26)

H6 Coupling 从 Proto-Partial Pillar 升级为正式 **Partial Pillar H6**。

| 半柱 | L5 AUTHORITY 模块 | L5 GOLDEN-LINE | 说明 |
|------|------------------|----------------|------|
| H6 Coupling | `RT_MF_Def.f90` | `RT_MFCoordinator.f90` | 多场耦合运行时四型 + 策略调度 |

L5 集成点:
- `RT_MF_Brg.f90` — L3→L5 Populate Bridge (PLACEHOLDER)
- `RT_STEPDRV_SEQ_COUPLED` 枚举触发 `RT_MFCoordinator_Run`
- L3 AUTHORITY: `MD_Cpl_Def.f90` (Analysis/Coupling/)
- L4 缺席: 耦合贡献分散在各域 (PH_Field_Cpl, PH_Mat_Cpl)
- 目录位置: `L5_RT/Solver/Coupling/` (历史位置, 独立域非Solver子域)

**架构文档**: `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §5b
