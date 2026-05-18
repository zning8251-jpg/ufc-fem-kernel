# AI-ready 插槽调用契约

> **版本**: v2.0 | Phase 7  
> **依据**: 三步状态机28分析步联通实施计划 §10; 域柱架构 §2.5 (v3.0)  
> **更新**: v2.0 扩展覆盖全部 6+1 插槽 (v1.0 仅覆盖 1/2)

---

## 一、概述

UFC 提供 **6 个推理插槽 + 1 个训练侧插槽**，分布在 L2/L4/L5 三层。所有推理插槽共用 L1_IF/Base/AI (`IF_AI_Runtime`) 作为 ONNX 推理引擎。每个插槽**归属其宿主域**（非独立域），默认关闭 (`.FALSE.` / `NULL()` procedure pointer)，零运行时开销。

### 插槽总览


| 插槽  | 名称               | 宿主域           | 层     | 热路径      | 优先级     | 状态   |
| --- | ---------------- | ------------- | ----- | -------- | ------- | ---- |
| 1   | AI_StepCtr       | Step (H4a)    | L5_RT | 否 (增量步间) | AI P0-B | STUB |
| 2   | AI_ConvPredict   | Solver (H4b)  | L5_RT | 是 (迭代内)  | AI P0-B | STUB |
| 3   | AI_MatInteg      | Material (P1) | L4_PH | 是 (IP级)  | AI P1-A | STUB |
| 4   | AI_ContactLaw    | Contact (P3)  | L4_PH | 是 (接触面)  | AI P2-A | STUB |
| 5   | AI_Precond       | NM Solver     | L2_NM | 否 (求解前)  | AI P1-B | STUB |
| 6   | AI_SparseSolver  | NM Solver     | L2_NM | 是 (求解内)  | AI P2-B | STUB |
| 7   | AI_AdjointSolver | DiffPhys (H7) | L2_NM | 否 (训练侧)  | AI P3   | STUB |


### 公共约束

1. **ONNX 约束**: 使用 NN 的插槽 (3/4/5/6) 必须经 `IF_AI_Runtime` 调用 ONNX Runtime C API
2. **非 NN 免 ORT**: 启发式/统计插槽 (1/2) 不强制 ORT
3. **四型遵守**: 所有插槽遵循 UFC 四类 TYPE + 合同 + 层依赖
4. **默认关闭**: procedure pointer = `NULL()`，AI 配置 `enabled = .FALSE.`
5. **单向依赖**: AI 模块不得反向 USE L5_RT (插槽 3-7)

---

## 二、插槽定义

### 2.1 AI_StepController

**类型**: `StepController_Interface`  
**调用时机**: Increment 收敛后  
**用途**: 建议下一增量步时间步长 `new_dt`（自适应时间步）

**接口**:

```fortran
SUBROUTINE StepController_Interface(dt, residual_norm, energy_norm, n_iterations, new_dt, status)
  REAL(wp), INTENT(IN)  :: dt, residual_norm, energy_norm
  INTEGER(i4), INTENT(IN) :: n_iterations
  REAL(wp), INTENT(OUT) :: new_dt
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```


| 输入              | 说明       |
| --------------- | -------- |
| `dt`            | 当前时间步长   |
| `residual_norm` | 收敛时残差范数  |
| `energy_norm`   | 能量范数     |
| `n_iterations`  | 本增量步迭代次数 |



| 输出       | 说明                   |
| -------- | -------------------- |
| `new_dt` | 建议下一增量步时间步长（调用方可选采纳） |
| `status` | 错误状态                 |


---

### 2.2 AI_ConvPredictor

**类型**: `ConvergencePredictor_Interface`  
**调用时机**: Iteration 内（每 iter）  
**用途**: 预测是否将收敛、置信度；支持早退（early exit）

**接口**:

```fortran
SUBROUTINE ConvergencePredictor_Interface(residual_history, will_converge, confidence, status)
  REAL(wp), INTENT(IN) :: residual_history(:)
  LOGICAL, INTENT(OUT) :: will_converge
  REAL(wp), INTENT(OUT) :: confidence
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```


| 输入                 | 说明           |
| ------------------ | ------------ |
| `residual_history` | 当前迭代及之前的残差历史 |



| 输出              | 说明                                     |
| --------------- | -------------------------------------- |
| `will_converge` | 预测是否将收敛；若 TRUE 且 confidence 足够高，求解器可早退 |
| `confidence`    | 置信度 [0,1]；高置信度时早退更安全                   |
| `status`        | 错误状态                                   |


**早退语义**: 当 `will_converge == .TRUE.` 且 `confidence > threshold` 时，Newton 求解器可提前终止迭代，视为已收敛。阈值由求解器配置决定。

---

### 2.3 AI_MatInteg (插槽 3)

**类型**: `AI_MatInteg_Predict_Interface`  
**归属**: Material 域 (P1) / L4_PH  
**调用时机**: 每个积分点、每次迭代 (替代或增强 return-mapping)  
**用途**: 本构代理模型 — NN 预测应力更新 sigma_new = NN(eps_trial, state_old)  
**模块**: `L4_PH/Material/AI/PH_AI_MatInteg.f90`  
**ONNX**: 必须经 `IF_AI_Runtime`

**接口**:

```fortran
SUBROUTINE AI_MatInteg_Predict_Interface( &
    algo, ctx, eps_trial, state_old, n_sdv, &
    stress_new, state_new, ddsdde, confidence, status)
  TYPE(AI_MatInteg_Algo), INTENT(IN)    :: algo
  TYPE(AI_MatInteg_Ctx),  INTENT(INOUT) :: ctx
  REAL(wp), INTENT(IN)    :: eps_trial(:), state_old(:)
  INTEGER(i4), INTENT(IN) :: n_sdv
  REAL(wp), INTENT(OUT)   :: stress_new(:), state_new(:), ddsdde(:,:)
  REAL(wp), INTENT(OUT)   :: confidence
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```

**Fallback**: 若 `confidence < threshold` 或推理失败，自动回退到经典 return-mapping。

---

### 2.4 AI_ContactLaw (插槽 4)

**类型**: `AI_ContactLaw_Predict_Interface`  
**归属**: Contact 域 (P3) / L4_PH  
**调用时机**: 接触面法向/切向力计算  
**用途**: 数据驱动接触律 — NN 预测接触压力 p = NN(gap, slip, friction)  
**模块**: `L4_PH/Contact/AI/NM_AIContactLawAlgo.f90`  
**ONNX**: 必须经 `IF_AI_Runtime`

**接口**:

```fortran
SUBROUTINE AI_ContactLaw_Predict_Interface( &
    algo, gap, slip_rate, friction_coeff, &
    contact_pressure, tangent_modulus, confidence, status)
  TYPE(AI_ContactLaw_Type), INTENT(IN) :: algo
  REAL(wp), INTENT(IN)  :: gap, slip_rate, friction_coeff
  REAL(wp), INTENT(OUT) :: contact_pressure, tangent_modulus, confidence
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```

---

### 2.5 AI_Preconditioner (插槽 5)

**类型**: `AI_Precond_Interface`  
**归属**: NM Solver / L2_NM  
**调用时机**: 线性求解前 (预条件器构造)  
**用途**: AI 辅助预条件器 — 学习最优预条件策略  
**模块**: `L2_NM/Solver/AI/NM_AIPrecondAlgo.f90`  
**ONNX**: 可选 (也可为启发式)

**接口**:

```fortran
SUBROUTINE AI_Precond_Interface(K_csr, rhs, precond_type, precond_params, status)
  ! K_csr: 稀疏矩阵 (CSR 格式)
  ! rhs: 右端项
  ! precond_type: 建议的预条件器类型
  ! precond_params: 建议的参数
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```

---

### 2.6 AI_SparseSolver (插槽 6)

**类型**: `AI_SparseSolver_Interface`  
**归属**: NM Solver / L2_NM  
**调用时机**: 线性系统求解内部  
**用途**: AI 增强稀疏求解 — GNN 预测初始解/加速迭代  
**模块**: `L2_NM/Solver/AI/NM_AISparseSolverAlgo.f90`  
**ONNX**: 必须经 `IF_AI_Runtime`

---

### 2.7 AI_AdjointSolver (插槽 7 — 训练侧)

**类型**: `AI_Adjoint_Interface`  
**归属**: DiffPhys 半柱 (H7) / L2_NM  
**调用时机**: 训练循环 (冷路径，非标准 FEM 前向求解)  
**用途**: 离散伴随法 — Kᵀ·lambda = dJ/du → dJ/dtheta  
**模块**: `L2_NM/Solver/AI/NM_AIAdjointAlgo.f90`  
**ONNX**: 不需要 (纯矩阵操作)

**接口**:

```fortran
SUBROUTINE AI_Adjoint_Interface( &
    K_transpose, dJdu, lambda, dJdtheta, status)
  ! K_transpose: 刚度矩阵转置
  ! dJdu: 目标函数对位移的导数
  ! lambda: 伴随变量 (输出)
  ! dJdtheta: 目标函数对设计变量的导数 (输出)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
END SUBROUTINE
```

**训练闭环**: L6_AP 或外部 Python 脚本调用 → L2 伴随求解 → L4 `dR/dtheta` → 梯度回传 → 模型更新 → 导出 ONNX → L1 加载

---

## 三、注入路径

```
StepDriverContext (AI_StepController, AI_ConvPredictor)
  → RT_StepDriver_ApplyAISlots(cfg, sdc)
  → RT_StepDriver_Config%AI_StepController, AI_ConvPredictor
  → RT_StepDriver_Execute / RT_Standard_RunStep
  → RT_NLSolver_NewtonRaph(..., AI_ConvPredictor)
  → RT_SolIncMgr / RT_SolIterMgr (AI_StepController at increment end)
```

**Runner Init**: 各 Runner 在 Init 时从 `StepDriverContext` 接收 AI 插槽；`RT_StepDriver_ApplyAISlots` 在 Step 执行前将 `sdc` 的插槽复制到 `cfg`。

---

## 四、相关模块


| 模块                 | 路径                                         | 说明                                                       |
| ------------------ | ------------------------------------------ | -------------------------------------------------------- |
| RT_Global_Types    | L5_RT/RT_Global_Types.f90                  | StepController_Interface, ConvergencePredictor_Interface |
| RT_AI_AdaptiveStep | L5_RT/StepDriver/AI/RT_AI_AdaptiveStep.f90 | AI_AdaptiveStep_StepController 实现                        |
| RT_AI_Diagnostic   | L5_RT/StepDriver/AI/RT_AI_Diagnostic.f90   | 诊断钩子                                                     |
| RT_StepDriver_Core | L5_RT/StepDriver/RT_StepDriver_Core.f90    | RT_StepDriver_ApplyAISlots                               |


