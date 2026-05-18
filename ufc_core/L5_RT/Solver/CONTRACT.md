# Solver 域级合同卡 (L5_RT)

- **层级**: L5_RT
- **域名**: Solver / 方程组求解核 (线性/非线性/时间积分)
- **缩写**: Solv (`RT_Solv_*`)
- **版本**: v3.0
- **更新**: 2026-04-28
- **状态**: ACTIVE

---

## 1. 域职责定义

- **核心职责（一句话）**: 实现三类核心求解算法 — 线性直接/迭代法、非线性 Newton-Raphson（含修正NR/L-BFGS/弧长）、时间积分 Newmark/HHT-α/Central Difference — 封装 L2_NM 数值库为物理语义接口。
- **职责边界**:
  - **做什么**: 线性方程组求解（Direct PARDISO/Iterative CG/GMRES/AGMG/SparsePak）、非线性 Newton-Raphson 迭代（全NR/修正NR/L-BFGS/弧长）、线搜索、收敛判断、时间积分（隐式 Newmark/HHT-α/Generalized-α、显式 Central Difference）、CSR 稀疏矩阵操作、Rayleigh 阻尼矩阵构建、预条件器管理、接触残差组装与收敛检查、AI 收敛预测（可选插槽）、内存池管理
  - **不做什么**: 不组装全局矩阵（L5_RT/Assembly 负责）；不定义分析步类型（L5_RT/StepDriver 负责）；不包含特征值/屈曲等非核心功能；不直接计算单元/本构（L4_PH 负责）

---

## 2. 四类 TYPE 清单

**AUTHORITY 模块**: `RT_Solv_Def.f90` (`MODULE RT_Solv_Def`)

### 2.1 Desc 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Solv_Base_Desc` | `RT_Solv_Def` | 求解器基础配置描述（冷） | 求解器类型 (Direct/Iterative/Eigen)、控制参数 (容差/最大迭代) |
| `RT_Sol_Cfg` | `RT_Shared_Def` (re-export) | 求解器运行时配置 | 线性求解类型、NR 参数、预条件 |
| `MD_LinearSolver_Desc` | L3 消费 | L3 线性求解器描述 | 经 Bridge 填充 |

### 2.2 State 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_Solv_NRState` | `RT_Solv_Def` | NR 迭代状态 | 当前迭代索引、残差范数、收敛标志 |
| `RT_Sol_State` | `RT_Shared_Def` (re-export) | 求解器全局状态 | 位移/速度/加速度向量 |
| `RT_Solver_State` | `RT_Solv_ContResidual` | 求解器运行时状态 | 接触数据绑定 |

**TBP** (NRState): `Init`, `Reset`, `UpdateNorms`

### 2.3 Algo 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_AdvancedNLSol` | `RT_Solv_Def` | 高级非线性求解器 | NR/修正NR/L-BFGS/弧长策略选择 |
| `RT_AdvancedTimeIntegrator` | `RT_Solv_Def` | 高级时间积分器 | method (Newmark/HHT-α/Gen-α/Central), dt, beta/gamma, alpha, 状态向量 u/v/a |
| `MD_NR_Algo` | L3 消费 | L3 NR 算法配置 | 经 Bridge 填充 |

### 2.4 Ctx 类型

| TYPE 名称 | 模块 | 说明 | 关键字段 |
|-----------|------|------|----------|
| `RT_NLSolver_Args` | `RT_Solv_Nonlin` | 非线性求解上下文 | DoF 映射引用、预条件句柄、内存池 |
| `RT_Solv_TimeInt_Core_Args` | `RT_Solv_TimeInt` | 时间积分上下文 | 时间积分参数、状态向量 |
| `UF_CoreMemPool_t` | `RT_Solv_CoreMemPool` | 内存池上下文 | 动态分配 slot 管理 |

**附加 Def 类型**: `RT_Solv_Cfg`, `RT_Solv_DofMap`, `SolCfg`, `SolDofMap` (legacy aliases), `RT_CSRMatrix`, `RT_TripletList`

---

## 3. 功能模块清单

| 文件名 | MODULE 名 | 后缀角色 | 核心子程序 | 状态 |
|--------|-----------|----------|-----------|------|
| `RT_Solv_Def.f90` | `RT_Solv_Def` | _Def | 四型定义 + CSR_Free + 常量 re-export | **AUTHORITY** |
| `RT_Solv_Mgr.f90` | `RT_Solv_Mgr` | — | `UF_NewtonRaphson`, `UF_NewtonRaphsonDynamic`, `UF_ExplicitDynamicsStep`, `UF_Assem_Static`, `RT_TimeInt_Newmark_Dyn`, `RT_TimeInt_HHT_Alpha_Dyn`, `RT_SolverSys_*`, `RT_SolverCfg_*`, `RT_SolverCoordinator_*`, `RT_InitSolver/RunSolver/UpdateSolver/FinalizeSolver` | **GOLDEN-LINE** |
| `RT_Solv_Nonlin.f90` | `RT_Solv_Nonlin` | — | `RT_NLSolver_NewtonRaph`, `RT_NLSolver_ModifiedNewton`, `RT_NLSolver_QuasiNewton`, `RT_NLSolver_ArcLen`, `RT_NLSolver_LineSearch`, `RT_NLSolver_Solv_Unified` | **GOLDEN-LINE** |
| `RT_Solv_Lin.f90` | `RT_Solv_Lin` | — | `RT_LinearSolver_Solv_Unified`, `RT_Li_SelectStrategy` | **ACTIVE** |
| `RT_Solv_TimeInt.f90` | `RT_Solv_TimeInt` | — | `RT_TimeInt_Newmark/HHT_Alpha/CentralDiff/GenAlpha`, `RT_TimeInt_Implicit/Explicit_Integ` | **ACTIVE** |
| `RT_Solv_Sparse.f90` | `RT_Solv_Sparse` | — | `RT_Triplet_Init/Add/Free`, `RT_CSR_FromTriplet`, `RT_CSR_SpMV`, `RT_LU_Setup_FromCSR/Solv/Destroy`, `RT_LinearSolve_Direct` | **ACTIVE** |
| `RT_Solv_Brg.f90` | `RT_Solv_Brg` | _Brg | `RT_LinearSolver_Direct/Iterative/Unified/AGMG/SparsePak`, `RT_ConvertCSR_ToNumCore/FromNumCore`, `RT_Precond_Create/Destroy`, `RT_Solv_Bridge_Unified/Opt` | **ACTIVE** |
| `RT_Solv_Core.f90` | `RT_Solv_Core` | _Core | 求解器核心协调 | **ACTIVE** |
| `RT_Solv_Impl.f90` | `RT_Solv_Impl` | _Impl | `RT_Solv_Impl_Init`, `RT_Solv_Impl_Equilibrium`, `RT_Solv_Impl_Linear`, `RT_Solv_Impl_Convergence`, `RT_Solv_Impl_Cutback` | **ACTIVE** |
| `RT_Solv_Proc.f90` | `RT_Solv_Proc` | _Proc | `RT_Solv_Init/Equilibrium/Linear/Convergence/Cutback_Interface` (SIO In/Out) | **ACTIVE** |
| `RT_Solv_ContResidual.f90` | `RT_Solv_ContResidual` | — | `RT_Solv_Cont_AssembleGlobalResidual`, `RT_Solv_Cont_UpdateContactState`, `RT_Solv_Cont_CheckConvergence` | **ACTIVE** |
| `RT_Solv_CoreMemPool.f90` | `RT_Solv_CoreMemPool` | — | `UF_CoreMemPool_t` + `CoreMemPool_AllocDP1D/AllocInt1D/Dealloc` | **ACTIVE** |
| `RT_Solv_ABAQUSReg.f90` | `RT_Solv_ABAQUSReg` | — | `GetSolverById/ByKeyword`, `GetSolverCapabilities`, `ValidateSolverConfig`, `PrintSolverRegistry` | **ACTIVE** |
| `RT_AI_ConvPredictAlgo.f90` | `RT_AI_ConvPredictAlgo` | — | `AI_ConvPredict_Init/Finalize/Update/Predict` | **ACTIVE** (AI 插槽) |
| `RT_Asm_DofMapUtils.f90` | `RT_Asm_DofMapUtils` | — | `UF_GetEqId`, `UF_GetEqIdByDofType`, `RT_GetEqId` | **ACTIVE** |

**子域**: `Coupling/` (4个文件) — 耦合求解路由，详见 `Coupling/CONTRACT.md`。

---

## 4. 对外接口（公开 API）

### 4.1 SIO 过程接口 (RT_Solv_Proc)

| 过程名 | In/Out TYPE | 功能 |
|--------|-------------|------|
| `RT_Solv_Init_Interface` | `RT_Solv_Init_In/Out` | 求解器初始化 |
| `RT_Solv_Equilibrium_Interface` | `RT_Solv_Equilibrium_In/Out` | 平衡迭代 |
| `RT_Solv_Linear_Interface` | `RT_Solv_Linear_In/Out` | 线性求解 |
| `RT_Solv_Convergence_Interface` | `RT_Solv_Convergence_In/Out` | 收敛检查 |
| `RT_Solv_Cutback_Interface` | `RT_Solv_Cutback_In/Out` | 回切控制 |

### 4.2 生产求解器框架 (RT_Solv_Mgr — GOLDEN-LINE)

| 过程名 | 功能 |
|--------|------|
| `RT_InitSolver` | 全局求解器初始化 |
| `RT_RunSolver` | 运行求解器主循环 |
| `RT_UpdateSolver` | 更新求解器状态 |
| `RT_FinalizeSolver` | 求解器清理 |
| `UF_NewtonRaphson` | Newton-Raphson 非线性求解 |
| `UF_NewtonRaphsonDynamic` | 动力学 Newton-Raphson |
| `UF_ExplicitDynamicsStep` | 显式动力学单步 |
| `UF_Assem_Static` | 静力组装+求解 |
| `RT_SolverSys_Init/Cfg/Solv/Final` | 结构化求解器系统接口 |
| `RT_CreateSolverCoordinator` | 创建求解器协调器 |

### 4.3 非线性求解 (RT_Solv_Nonlin)

| 过程名 | 功能 |
|--------|------|
| `RT_NLSolver_NewtonRaph` | 全切线 Newton-Raphson（可选 `nr_divergence_growth_limit`；L3 SSOT：`MD_NonlinSolv%nr_divergence_growth_limit`，0=关闭）。软发散时 `IF_STATUS_WARN` |
| `RT_NLSolver_ModifiedNewton` | 修正 Newton（常刚度） |
| `RT_NLSolver_QuasiNewton` | 拟 Newton (L-BFGS) |
| `RT_NLSolver_ArcLen` | 弧长法 (Riks)；能量范数辅助收敛见源码内 [T2 Enhancement]；`MD_NonlinSolv%arc_nonconverge_use_warn` 控制 max-iter 时 WARN vs ERROR；`arc_constraint_tol_scale` 放宽球面约束阈值 |
| `RT_NLSolver_LineSearch` | 线搜索加速 |
| `RT_NLSolver_Solv_Unified` | 统一非线性求解入口 |

### 4.4 时间积分 (RT_Solv_TimeInt)

| 过程名 | 功能 |
|--------|------|
| `RT_TimeInt_Newmark` | Newmark-β 隐式积分 |
| `RT_TimeInt_HHT_Alpha` | HHT-α 隐式积分 |
| `RT_TimeInt_GenAlpha` | Generalized-α 积分 |
| `RT_TimeInt_CentralDiff` | Central Difference 显式积分 |
| `RT_TimeInt_Implicit/Explicit_Integ` | 统一隐式/显式入口 |

---

## 5. 跨层数据流

### 5.1 上游（本域消费）

| 来源层/域 | 提供数据 | 消费方式 | 说明 |
|-----------|---------|---------|------|
| L3_MD/Analysis/Solver | `MD_Solver_Desc` | 经 Bridge 填充 → `RT_Sol_Cfg` | 冷路径 |
| L3_MD/Analysis/Solver | `MD_NR_Algo`, `MD_Precond_Desc` | 经 Bridge 填充 | 冷路径 |
| L5_RT/Assembly | 全局 K(CSR)/F/M/C、DOF 映射 | 直接消费 `RT_CSRMatrix` + `RT_Sol_DofMap` | **核心热路径** |
| L5_RT/StepDriver | 步驱动调用 | Solver 被 StepDriver 编排调用 | 服务关系 |
| L5_RT/Contact | 接触残差贡献 | `RT_Solv_Cont_*` | 热路径 |

### 5.2 本层输出（下游消费）

| 输出数据 | 消费者 | 载体 |
|---------|--------|------|
| 位移增量 Δu | L5_RT/StepDriver → L3_MD WriteBack | `u(:)` 向量 |
| 荷载因子 λ | L5_RT/StepDriver (弧长法) | 标量 |
| 收敛状态 | L5_RT/StepDriver (回切决策) | `ErrorStatusType` |
| 速度/加速度 (动力学) | L5_RT/StepDriver → WriteBack | `v(:)`, `a(:)` |

### 5.3 L5 求解主流程

```
StepDriver → Solver (平衡迭代)
    ↓
[非线性循环 (Newton-Raphson)]
    ↓
Assembly 提供 K(CSR) + F → RT_Solv_Lin (线性求解: K·Δu = -R)
    ↓
Δu → 收敛检查 (‖R‖ < tol)
    ↓
收敛 → 返回 StepDriver    /    不收敛 → 更新切线 → 重新迭代
                                          ↓
                              超过最大迭代 → Cutback → StepDriver
```

**热路径零 L3**: 求解器仅消费 Assembly 后的 CSR/K/F，不直读 L3。

---

## 6. 域间契约

### 6.1 与 L5 同层其他域的协作关系

| 序号 | 关联域 | 方向 | 契约类型 | 主要接触面 | 备注 |
|------|--------|------|----------|-----------|------|
| R1 | L5_RT/Assembly | 上游 | T(类型) | K/F/u 输入 | 核心依赖 |
| R2 | L5_RT/StepDriver | 被调用 | S(服务) | 步驱动调用求解 | 编排关系 |
| R3 | L5_RT/Contact | 协作 | S | 接触残差贡献 | `RT_Solv_Cont_*` |

### 6.2 与 L2_NM 的消费关系

| 序号 | L2 域/模块 | 消费内容 | L5 接口 |
|------|-----------|---------|---------|
| C1 | L2_NM/Solver | BLAS/LAPACK/稀疏求解器 | `RT_Solv_Brg` 桥接 |
| C2 | L2_NM/AssemSparse | Triplet/CSR 操作 | `RT_Solv_Sparse` + `NM_Assem_Sparse` |
| C3 | L2_NM/Solver/AI | AI 预条件/稀疏求解 (插槽 5/6) | `RT_Solv_Brg` 编排 |

### 6.3 非线性策略与组装/求解契约

| 策略 | 迭代内工作 | 对 Assembly 期望 | 对 UMAT 切线 |
|------|-----------|-----------------|-------------|
| **Newton–Raphson（全切线）** | 每迭代更新 K、R | 每迭代完整切线 + 残差 | **一致切线** |
| **修正 NR / 常刚度** | 多轮共用同一 K，仅更新 R | 残差每迭代；切线可隔若干迭代 | 可仅在重算 K 的迭代提供 |
| **BFGS / L-BFGS** | secant 更新搜索方向 | 残差每迭代；精确切线可低频 | 可标注为非一致 |
| **弧长（Riks）** | 引入 λ；增广系统 | 外载与 λ 耦合块进入全局 R/K | 与 NR 相同或降级 |

---

## 7. 验收标准

### 7.1 硬约束

| 编号 | 约束 | 说明 |
|------|------|------|
| H-ERR-01 | 不使用 STOP | 错误通过 `ErrorStatusType` 传播至 StepDriver |
| H-CONV-01 | 不收敛时不崩溃 | 返回 status → StepDriver 决策回切 |
| H-UMAT-01 | 切线语义与材料域对齐 | UMAT 合同一致性 |
| H-DEP-01 | 单向依赖 | 不可依赖 L6_AP |

### 7.2 软约束

| 编号 | 约束 | 说明 |
|------|------|------|
| S-TST-01 | 测试覆盖率 | 待建 |
| S-DOC-01 | 子程序级注释 | 新增模块须含 purpose/theory/status 头 |

### 7.3 功能验收

| 编号 | 验收项 | 判定标准 |
|------|--------|---------|
| V-SOL-01 | 线性直接求解 | SPD 矩阵求解误差 < 1e-12 |
| V-SOL-02 | Newton-Raphson 收敛 | 二次收敛速率（‖R_{k+1}‖ ∝ ‖R_k‖²） |
| V-SOL-03 | 弧长法 | 过极限点后仍可追踪平衡路径 |
| V-SOL-04 | Newmark 时间积分 | 能量守恒误差 < 1% (无阻尼自由振动) |
| V-SOL-05 | 显式 Central Diff | dt ≤ dt_cfl 时稳定 |

---

### 错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| 迭代不收敛 | `IF_STATUS_ERROR` | 返回 status → StepDriver 决策回切 |
| 线性求解失败（奇异矩阵） | `IF_STATUS_ERROR` | 返回 status |
| 弧长参数无效 | `IF_STATUS_INVALID` | 返回 status |

不使用 `STOP`；错误通过 `ErrorStatusType` 传播至 StepDriver。

---

### AI Enhancement (L2 插槽 5/6, H7 插槽 7 经由 L5 编排)

| 项 | 插槽 5 | 插槽 6 | 插槽 7 |
|----|--------|--------|--------|
| **名称** | AI_Precond | AI_SparseSolver | AI_AdjointSolver |
| **实体层** | L2_NM | L2_NM | L2_NM |
| **模块** | `NM_AIPrecondAlgo` | `NM_AISparseSolverAlgo` | `NM_AIAdjointAlgo` |
| **用途** | AI 辅助预条件 | GNN 加速迭代 | 离散伴随梯度 |
| **默认** | 关闭 | 关闭 | 关闭 |

### Partial Pillar v2.0 (H4b Solver)

**半柱分类**: H4b Solver 是 L3+L5 半贯通柱。

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| L3 | `MD_Solv_Def.f90` | **AUTHORITY** — 求解器配置 Desc/Algo | ACTIVE |
| L4 | (不存在) | 求解器非单元级物理计算 | — |
| L5 | `RT_Solv_Def.f90` | **AUTHORITY** — 运行时求解器类型 | ACTIVE |
| L5 | `RT_Solv_Mgr.f90` | **GOLDEN-LINE** — 生产求解器框架 | ACTIVE |
| L5 | `RT_Solv_Nonlin.f90` | **GOLDEN-LINE** — 非线性求解核 | ACTIVE |

### 四链说明

| 链 | 本域可核对说明 |
|----|---------------|
| **理论链** | Newton-Raphson: K·Δu = R → 迭代直至 ‖R‖ < tol；弧长法: ‖Δu‖² + ψ·Δλ² = Δs² |
| **逻辑链** | StepDriver → Solver → LinSolv(L2) 求解 → 收敛判据 → 返回 StepDriver |
| **计算链** | 全局 K(CSR) + F → L2 LinSolv → Δu → 残差更新 → 收敛检查 |
| **数据链** | `RT_Sol_DofMap`+`RT_CSRMatrix`(Assembly 产) → Solver 消费 → `u`,`lambda` 输出 |

---

*维护注记: 新增求解器子模块时在「§3 功能模块清单」和「§4 对外接口」补一行。*
