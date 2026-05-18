## TimeInt 域级合同卡（L2_NM）

- **层级**：L2_NM  
- **域名**：TimeInt / 时间积分算法  
- **缩写**：`NM_TimeInt_*`  
- **职责**：提供常/变步长时间离散格式；显式/隐式局部组装与稠密小系统求解；Newmark-β、HHT-α、Runge-Kutta 等与步长控制入口。  
- **非职责（防暗道）**：不替代 L5_RT 的全局调度与工程状态机；大规模稀疏直接/迭代解算归口 **NM_Solver**；本域隐式步内仅允许 **稠密 `ndofs×ndofs` 热路径 LU**（`NM_TimeInt_Linsolv`）。

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 四型（Desc / State / Algo / Ctx）

| 四型 | 锚点 | 内容摘要 |
|------|------|----------|
| **Desc** | `NewmarkIntegrator` / `HHTIntegrator` / `RKIntegrator`（`NM_TimeInt_Types`）；`NM_TimeInt_Ctrl_Ctx`（`NM_TimeInt_Scheme_Core`） | `gamma, beta, dt`；`rho_inf, alpha_f, alpha_m`；RK Butcher 系数与自适应容差；Scheme 侧 `method, dt, t_final, tolerance…` |
| **State** | 各积分器内 `u_old,v_old,a_old,u_pred,v_pred`；`u_star,v_star`（HHT）；`NM_TimeInt_State`（Scheme） | 步内历史、预测量、迭代中间量；当前时间、步计数、收敛标志 |
| **Algo** | `NM_TimeInt_Newmark` / `NM_TimeInt_HHT` / `NM_TimeInt_RK`；`NM_TimeInt_Scheme_Core`；`NM_TimeStep_Controller_Core` | Predict–Correct、有效刚度组装、Newton 循环、RK 阶段更新、结构化 Init/Step API |
| **Ctx** | 无独立大上下文 TYPE；可选 `use_precond` 等由调用方传入 | 保持 L2 纯算法边界，上下文由上层注入 |

---

### 模块边界

| 模块 | 角色 |
|------|------|
| `NM_TimeInt_Types` | 积分器 TYPE、`Initialize`/`SetParams`/`Destroy`；HHT 的 `a0,a1,a2` 与 Newmark 系数刷新 |
| `NM_TimeInt_Linsolv` | **`NM_TimeInt_Dense_LU_Solve`**：`DGETRF`/`DGETRS`，右端 `b` 以 `bx(n,1)` 满足 LAPACK |
| `NM_TimeInt_Newmark` | `NM_TimeInt_Predict` / `Correct` / `Solve_Equilibrium` / `NM_Newmark_*` |
| `NM_TimeInt_HHT` | 预测、有效力、有效刚度、`NM_TimeInt_HHT_Integrate` 与平衡迭代 |
| `NM_TimeInt_RK` | `NM_TimeInt_RK4_Integrate` 及阶段/自适应辅助 |
| `NM_TimeInt_Scheme_Core` | **另一套** Desc/State（`NM_TimeInt_Ctrl_Ctx` / `NM_TimeInt_State`）+ 结构化 Newmark/HHT/Gen-α **Init/Step**；与 `NM_TimeInt_Newmark` 等并列，供桥接与统一入口；合并调用时避免重复维护同一物理状态 |
| `NM_TimeStep_Controller_Core` | 时间步长策略（与积分格式解耦） |

---

### 依赖

- **必须**：`IF_Prec_Core`；`NM_Matrix`（`DenseMatrix`）；`NM_TimeInt_Types`；隐式步内 **`NM_TimeInt_Linsolv`**。  
- **可选**：预条件等经 `NM_Solver` 类型传入（若启用）；不强制本域 `USE NM_Solver` 完成每一步求解。

---

### 热路径与算法要点

- **热路径**：是 — 动力分析每步多次调用。  
- **Newmark 校正（与加速度关系一致）**  
  - \(u_{n+1} = \tilde u + \beta \Delta t^2 a_{n+1}\)，\(v_{n+1} = \tilde v + \gamma \Delta t\, a_{n+1}\)  
  - 与常用写法 \(a_{n+1} = a_0 (u_{n+1}-\tilde u) + \cdots\) 在同一 `a0` 定义下相容。  
- **HHT**：有效内力 \((1+\alpha_f)R(u)-\alpha_f R_{\text{old}}\)；有效刚度 \(a_0 M + a_1 C + (1+\alpha_f)K\)；Newton 在 **`u_star`** 上评估内力。  
- **RK4**：经典四级 Runge-Kutta；自适应步长用半步嵌入估计（实现见 `NM_TimeInt_RK_Adaptive_Step`）。

---

### 核心接口（功能集 → 符号）

| 功能集 | 主要符号 |
|--------|----------|
| Newmark | `NM_TimeInt_Predict`, `NM_TimeInt_Correct`, `NM_TimeInt_Solve_Equilibrium`, `NM_Newmark_Explicit` / `NM_Newmark_Implicit` |
| HHT | `NM_TimeInt_HHT_Integrate`, `NM_TimeInt_HHT_Predict`, `NM_TimeInt_HHT_Correct`, `NM_TimeInt_HHT_Equilibrium_Iteration` |
| RK | `NM_TimeInt_RK4_Integrate`, `NM_TimeInt_RK_Adaptive_Step` |
| Scheme（结构化） | `NM_TimeInt_Newmark_Init` / `NM_TimeInt_Newmark_Step`, `NM_TimeInt_HHTAlpha_*`, `NM_TimeInt_GeneralizedAlpha_*` |
| 线性子步 | **`NM_TimeInt_Dense_LU_Solve`**（本域唯一集中稠密 LU） |

---

### 验证

- 单元测试：`L2_NM/Tests/Test_TimeInt.f90`（Newmark 预测–校正、RK4 多步到 \(t=1\) 的阶数比等）。  
- Harness：`python UFC/ufc_harness/run_harness.py naming <path/to/TimeInt>`；全量 L2 见 `naming` 默认 `ufc_core`。

---

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_TIMEINT_xxx`（20600–20699） |
| 严重级 | WARNING（自适应步长截断）/ ERROR（LU 奇异、Newton 不收敛、dt≤0） |
| 传播规则 | 平衡迭代收敛标志通过 `convergence_flag` 返回；LU 错误通过 `info` 传播 |
| 恢复策略 | Newton 不收敛时返回标志（不 `STOP`），由 L5_RT 步进驱动决定步长回退；自适应 RK 自动减半步长 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L5_RT/StepDriver | S(被消费) | RT 层步进驱动消费时间积分格式 |
| 2 | L2_NM/Matrix | S | 消费 `DenseMatrix` 类型 |
| 3 | L2_NM/Solver | S | 隐式步可选消费预处理/迭代法（经形参传入） |
| 4 | L2_NM/ExternalLibs | U | LAPACK `DGETRF`/`DGETRS`（经 `NM_TimeInt_Linsolv`） |
| 5 | L1_IF/Precision | U | 精度定义 `wp`, `i4` |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| `USE IF_Prec_Core` 精度统一 | 硬 | 编译 | P0 |
| 隐式步内仅稠密 `ndofs×ndofs` LU（`NM_TimeInt_Linsolv`） | 硬 | Code Review | P0 |
| 不替代 L5_RT 全局调度与状态机 | 硬 | 架构 Review | P0 |
| 大规模稀疏求解归口 `NM_Solver` | 硬 | Code Review | P0 |
| Scheme 与 Newmark/HHT 并列使用时避免重复维护同一物理状态 | 软 | Code Review | P1 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` | Active |
| 2 | Definition/Schema | `NM_TimeInt_Types.f90` | 积分器 TYPE 定义 |
| 3 | Desc | `NewmarkIntegrator`, `HHTIntegrator`, `RKIntegrator`, `NM_TimeInt_Ctrl_Ctx` | 参数描述（gamma, beta, dt, rho_inf 等） |
| 4 | State | `u_old,v_old,a_old,u_pred,v_pred`；`NM_TimeInt_State` | 步内历史与中间量 |
| 5 | Algo | `NM_TimeInt_Newmark`, `NM_TimeInt_HHT`, `NM_TimeInt_RK`, `NM_TimeInt_Scheme_Core` | Predict–Correct、Newton 循环 |
| 6 | Ctx | — | 无独立大 Ctx；参数由调用方注入 |
| 7 | Kernel | `NM_TimeInt_Newmark.f90`, `NM_TimeInt_HHT.f90`, `NM_TimeInt_RK.f90` | 积分核心 |
| 8 | Bridge | — | 由 L5_RT 桥接消费 |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | — | 积分器选择由调用方配置 |
| 11 | Populate | `Initialize` / `SetParams` / `Destroy` | 积分器生命周期 |
| 12 | Diagnostics | `convergence_flag`、迭代计数 | 平衡迭代诊断 |
| 13 | Test | `L2_NM/Tests/Test_TimeInt.f90` | Active |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 时间离散格式：Newmark-β 预测–校正、HHT-α 数值阻尼、RK4 显式推进、广义-α 方法 |
| 逻辑链 | L5_RT/StepDriver → 选择积分格式 → `NM_TimeInt_*`（Predict → 平衡迭代 → Correct） → 更新状态 |
| 计算链 | 热路径（动力分析每步多次调用）；隐式步稠密 LU 归口 `NM_TimeInt_Linsolv`；RK 四级阶段更新 |
| 数据链 | Desc(冷,gamma/beta/dt) → State(u_old/v_old/a_old 步间传递) → Algo 运算中 u_pred/v_pred 为临时量 |

---

**版本**：v2.0  
**最后更新**：2026-03-23  
**状态**：与实现同步（稠密 LU 归口、`IF_Prec_Core`、Newmark 位移校正）


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_AdaptiveTimeStep.f90` | `NM_AdaptiveTimeStep` | `HHT_Params`, `GenAlpha_Params`, `Newmark_Params`, `AdaptiveStep_Params`, `Dynamic_State`, `AdaptiveStep_State`, `TimeIntegration_Result` | `Check_Events` (SUB,PRV,—); `Cleanup_Adaptive_State` (SUB,PRV,Bridge); `Handle_Event` (SUB,PRV,—); `Init_Res_Storage` (SUB,PRV,—); `NM_Adaptive_GetControlStatistics` (SUB,PUB,Query); `NM_Adaptive_GetStepStatistics` (SUB,PUB,Query); `NM_Adaptive_GenAlpha_Solv` (SUB,PUB,Bridge); `NM_Adaptive_HHT_Solv` (SUB,PUB,Bridge); `NM_Adaptive_Newmark_Solv` (SUB,PUB,Bridge); `NM_Adaptive_OptimizeStrategy` (SUB,PUB,Bridge); `NM_Adaptive_TimeStep_Solv` (SUB,PUB,Bridge); `NM_AdaptiveStep_Init_State` (SUB,PUB,Init); `NM_Calc_Adaptive_Step_Size` (SUB,PUB,Bridge); `NM_Calc_Effective_Force` (SUB,PUB,—); `NM_Calc_Effective_Stiff` (SUB,PUB,—); `NM_GenAlpha_Single_Step_Adaptive` (SUB,PUB,Bridge); `NM_GenAlpha_Init_Params` (SUB,PUB,Init); `NM_HHT_Init_Params` (SUB,PUB,Init); `NM_HHT_Single_Step_Adaptive` (SUB,PUB,Bridge); `NM_Limit_Step_Size` (SUB,PUB,—); `NM_Newmark_Single_Step_Adaptive` (SUB,PUB,Bridge); `NM_PI_Ctrl_Step_Size` (SUB,PUB,—); `NM_Predictive_Step_Size` (SUB,PRV,—); `NM_Update_Dynamic_State` (SUB,PUB,Compute); `Save_State_To_Res` (SUB,PRV,—); `Solv_Lin_System` (SUB,PRV,—); `Update_State_GenAlpha` (SUB,PRV,—); `Update_State_HHT` (SUB,PRV,—); `Update_State_Newmark` (SUB,PRV,—) |
| `NM_TSEventDet.f90` | `NM_TSEventDet` | `TimeEvent`, `EventDetector_Config`, `EventDetector_State`, `Contact_Event_Data`, `Buckling_Event_Data`, `ZeroCrossing_Function`, `EventDetection_Result` | `NM_EventDetector_Init` (SUB,PUB,Init); `NM_Detect_Events` (SUB,PUB,—); `NM_Process_Events` (SUB,PUB,—); `NM_Detect_Events` (SUB,PUB,—); `NM_Detect_Separation_Events` (SUB,PUB,—); `NM_Check_Contact_Condition` (FN,PUB,Validate); `NM_Handle_Contact_Event` (SUB,PUB,—); `NM_Detect_Buckling_Events` (SUB,PUB,—); `NM_Check_Buckling_Condition` (FN,PUB,Validate); `NM_Handle_Buckling_Event` (SUB,PUB,—); `NM_Detect_Zero_Crossing` (FN,PUB,—); `NM_Reg_Zero_Crossing` (SUB,PUB,—); `NM_Update_Zero_Crossing` (SUB,PUB,Compute); `NM_Calc_Event_Time` (FN,PUB,—); `NM_Get_Next_Event_Time` (FN,PUB,Query); `NM_Suggest_Step_For_Event` (FN,PUB,—); `NM_Add_Event_To_History` (SUB,PUB,Mutate) |
| `NM_TimeInt.f90` | `NM_TimeInt` | `NM_TimeIntCtrl`, `NM_TimeInt_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SetScheme` (TBP,PRV,—); `Advance` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `NM_TimeInt_Finalize` (SUB,PRV,Finalize); `NM_TimeInt_Init` (SUB,PRV,Init); `NM_TimeInt_SetScheme` (SUB,PRV,Mutate); `NM_TimeInt_Advance` (SUB,PRV,—); `NM_TimeInt_GetSummary` (SUB,PRV,Query) |
| `NM_TimeInt_Adapt.f90` | `NM_TimeIntAdapt` | `Alpha_Method_Parameters`, `Adaptive_Step_Parameters`, `Adaptive_Time_Step_State`, `Adaptive_Integration_State`, `Error_Estimate` | `NM_Al_Me_Pa_Default` (SUB,PRV,—); `NM_Al_Me_Pa_Optimal` (SUB,PRV,—); `NM_Ad_St_Pa_Default` (SUB,PRV,—); `NM_Adaptive_Integ_Init` (SUB,PUB,Init); `NM_Alpha_Method_Predictor` (SUB,PUB,—); `NM_Alpha_Method_Corrector` (SUB,PUB,—); `NM_HHT_Effective_Stiff` (FN,PUB,—); `NM_HHT_Effective_Force` (FN,PUB,—); `NM_Generalized_Alpha_Effective_Stiffness` (FN,PUB,—); `NM_Generalized_Alpha_Effective_Force` (FN,PUB,—); `NM_Error_Estimate_Embedded` (SUB,PUB,—); `NM_Adaptive_Step_Size_Update` (SUB,PUB,Compute); `NM_Time_Step_Accept` (SUB,PUB,—) |
| `NM_TimeInt_BEAM.f90` | `NM_TimeIntBEAM` | `TimeInt_BEAM_Desc_Type`, `TimeInt_BEAM_State_Type`, `TimeInt_BEAM_Algo_Type` | `L2_NM_TimeInt_BEAM_Init` (SUB,PUB,Init); `L2_NM_TimeInt_BEAM_UpdateConstants` (SUB,PUB,Compute); `L2_NM_TimeInt_BEAM_Predict` (SUB,PUB,—); `L2_NM_TimeInt_BEAM_Correct` (SUB,PUB,—); `L2_NM_TimeInt_BEAM_ComputeEffectiveStiffness` (SUB,PUB,Compute); `L2_NM_TimeInt_BEAM_GetAcceleration` (SUB,PUB,Query); `L2_NM_TimeInt_BEAM_GetVelocity` (FN,PUB,Query); `L2_NM_TimeInt_BEAM_ComputeDampingForce` (SUB,PUB,Compute); `L2_NM_TimeInt_BEAM_Advance` (SUB,PUB,—) |
| `NM_TimeInt_HHT.f90` | — | — | — |
| `NM_TimeInt_Linsolv.f90` | `NM_TimeIntLinsolv` | — | `DGETRF` (SUB,PRV,—); `DGETRS` (SUB,PRV,—); `NM_TimeInt_Dense_LU_Solve` (SUB,PUB,Compute) |
| `NM_TimeInt_Newmark.f90` | — | — | — |
| `NM_TimeInt_RK.f90` | — | — | — |
| `NM_TimeInt_Scheme.f90` | `NM_TimeIntScheme` | `NM_TimeInt_Ctrl_Ctx` | `Init` (TBP,PRV,—); `Cleanup` (TBP,PRV,—); `SetMethod` (TBP,PRV,—); `SetTimeStep` (TBP,PRV,—); `NM_TimeInt_Ctrl_Init` (SUB,PRV,Init); `NM_TimeInt_Ctrl_Cleanup` (SUB,PRV,Finalize); `NM_TimeInt_Ctrl_SetMethod` (SUB,PRV,Mutate); `NM_TimeInt_Ctrl_SetTimeStep` (SUB,PRV,Mutate); `NM_TimeInt_State_Init` (SUB,PRV,Init); `NM_TimeInt_State_Cleanup` (SUB,PRV,Finalize); `NM_TimeInt_State_Update` (SUB,PRV,Compute); `NM_TimeInt_State_SavePrevious` (SUB,PRV,—); `NM_TimeInt_Newmark_Init` (SUB,PUB,Init); `NM_TimeInt_Newmark_Step` (SUB,PUB,—); `NM_TimeInt_HHTAlpha_Init` (SUB,PUB,Init); `NM_TimeInt_HHTAlpha_Step` (SUB,PUB,—); `NM_TimeInt_GeneralizedAlpha_Init` (SUB,PUB,Init); `NM_TimeInt_GeneralizedAlpha_Step` (SUB,PUB,—); `NM_TimeInt_GetAlpha` (SUB,PUB,Query); `NM_TimeInt_GetBeta` (FN,PUB,Query); `NM_TimeInt_GetGamma` (FN,PUB,Query) |
| `NM_TimeInt_Def.f90` | — | — | — |
| `NM_TimeStepController.f90` | `NM_TimeStepController` | `PI_Controller_Params`, `Predictive_Controller_Params`, `AdaptiveGain_Params`, `StepController_Config`, `StepController_State`, `StepControl_Result`, `TimeStep_Event` | `NM_StepController_Init` (SUB,PUB,Init); `NM_StepController_Calc_Step` (SUB,PUB,—); `NM_StepController_Update` (SUB,PUB,Compute); `NM_PI_Ctrl_Step` (SUB,PUB,—); `NM_PID_Ctrl_Step` (SUB,PUB,—); `NM_Predictive_Ctrl_Step` (SUB,PUB,—); `NM_Predict_Error_Trend` (SUB,PUB,—); `NM_AdaptiveGain_Ctrl_Step` (SUB,PUB,Bridge); `NM_Limit_Step_Size_Advanced` (SUB,PUB,—); `NM_Smooth_Step_Change` (SUB,PUB,—); `NM_Check_Step_Events` (SUB,PUB,Validate); `NM_Handle_Step_Event` (SUB,PUB,—); `NM_Calc_Growth_Factor` (FN,PUB,—); `NM_Eval_Ctrl_Strategy` (SUB,PUB,—) |
