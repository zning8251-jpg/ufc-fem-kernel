# NonlinSolv域合同卡 (L2_NM/Solver/NonlinSolv)

**Layer**: L2_NM (数值算法层)  
**Domain**: Solver/NonlinearSolver (非线性求解器子域)  
**Version**: v1.0  
**Created**: 2026-04-17  
**Status**: ✅ 新建

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC L2_NM层非线性求解器子域，统一的Newton/TrustRegion/ArcLength/QuasiNewton/Continuation非线性求解中心
- **职责**: Newton-Raphson求解、TrustRegion信任域求解、ArcLength弧长法、QuasiNewton拟Newton族、Continuation延拓法
- **边界**: 仅提供非线性方程组求解算法；线性求解依赖LinSolv域
- **依赖**: L2_NM Solver核心子域, 依赖LinSolv域(线性求解), 被Assembly/Solver域依赖

### 与Solver域的关系
| Solver域 (NM_Solver_*) | NonlinSolv域 (NM_Nonlinear_*) | 关系 |
|------------------------|-------------------------------|------|
| NM_Solver_Types.f90 | NM_Nonlinear_Newton_Core.f90 | 类型定义→算法实现 |
| 收敛准则定义 | 收敛检查实现 | 契约→执行 |

---

## 二、文件清单 (6个文件)

### 核心算法 (5个文件)
| 文件 | 行数 | 算法族 | 子程序数 |
|------|------|--------|----------|
| NM_Nonlinear_Newton_Core.f90 | 802 | Newton-Raphson | 23 |
| NM_Nonlinear_TrustRegion_Core.f90 | 318 | TrustRegion信任域 | 9 |
| NM_Nonlinear_ArcLength_Core.f90 | 366 | ArcLength弧长法 | 10 |
| NM_QuasiNewton_Family_Core.f90 | 711 | QuasiNewton拟Newton | 20 |
| NM_Continuation_Method_Core.f90 | ~750 | Continuation延拓法 | 20 |

### 封装层(旧版,待迁移) (1个文件)
| 文件 | 行数 | 状态 |
|------|------|------|
| UF_NonlinSolv.f90 | ~800 | ⚠️ 待迁移 |

**总计**: 6个文件, ~3747行代码

---

## 三、四类TYPE映射

| Type种类 | 文件 | TYPE名称 | 核心职责 |
|----------|------|----------|----------|
| **Desc** | NM_Base_Types.f90 | NM_NLSolv_Desc | 非线性求解器配置(method/max_iter/tolerance/line_search_enabled) |
| **State** | NM_Solver_Types.f90 | SolverStats | 求解状态(iterations/residual_norm/convergence_flag) |
| **Algo** | NM_Nonlinear_* | 各求解器子程序 | Newton/TrustRegion/ArcLength/QuasiNewton/Continuation |
| **Ctx** | 无 | - | 工作数组在子程序内ALLOCATE |

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 非线性方程组理论→Newton法→切线刚度→迭代求解 |
| **逻辑链** | NonlinSolv↔LinSolv(线性系统)↔L4_PH(残差/切线)↔L5_RT(步进)闭环 |
| **计算链** | 残差计算→切线刚度→线性求解→收敛检查→更新解 |
| **数据链** | 求解配置→迭代状态→残差历史→收敛标志→最终解 |

---

## 五、核心算法清单

### 1. Newton-Raphson求解 (23个子程序)
- ✅ 标准Newton法: 全切线,二次收敛
- ✅ Modified Newton: 修正Newton,减少切线更新
- ✅ BFGS更新: 拟Newton切线近似
- ✅ LBFGS: 限制内存BFGS,大规模问题
- ✅ 线搜索: 回溯线搜索,Armijo准则
- ✅ 收敛检查: 残差/位移/能量准则

### 2. TrustRegion信任域求解 (9个子程序)
- ✅ Dogleg方法: 最速下降+Newton步组合
- ✅ Cauchy步: 沿负梯度方向最优步长
- ✅ 自适应半径: 根据模型质量调整信任域半径
- ✅ SPD系统求解: 对称正定系统专用

### 3. ArcLength弧长法 (10个子程序)
- ✅ Crisfield弧长: 修正弧长法
- ✅ Riks弧长: 经典弧长法
- ✅ 自适应步长: 根据收敛性调整弧长半径
- ✅ 约束方程: 弧长约束求解
- ✅ 路径跟踪: 后屈曲路径追踪

### 4. QuasiNewton拟Newton族 (20个子程序)
- ✅ BFGS更新: 最常用拟Newton
- ✅ DFP更新: Davidon-Fletcher-Powell
- ✅ SR1更新: 对称秩1更新
- ✅ Broyden族: BFGS与DFP凸组合
- ✅ LBFGS两步递归: 限制内存实现
- ✅ 线搜索: Wolfe条件

### 5. Continuation延拓法 (20个子程序)
- ✅ 自然延拓: 参数连续变化
- ✅ 伪弧长延拓: 弧长参数化
- ✅ Homotopy同伦法: 同伦映射
- ✅ 切线预测器: 预测下一解点
- ✅ Newton校正器: 校正到精确解
- ✅ 自适应步长: 根据曲率调整

---

## 六、收敛准则

### Newton法收敛标志
| 值 | 含义 |
|----|------|
| 0 | 成功(残差/位移/能量满足容差) |
| 1 | 迭代未在max_iter内收敛 |
| 2 | 切线矩阵奇异 |
| 3 | 线搜索失败 |
| 4 | 弧长法无法求解约束方程 |

### 收敛检查类型
1. **残差准则**: ‖R‖₂ ≤ tol_R · max(‖R₀‖₂, 1)
2. **位移准则**: ‖Δu‖₂ ≤ tol_u · max(‖u‖₂, 1)
3. **能量准则**: |Δu·R| ≤ tol_E · max(|u₀·R₀|, 1)

---

## 七、依赖关系

### 向上依赖(被谁使用)
- L5_RT/StepDriver: 非线性步进驱动
- L4_PH/Element: 单元非线性迭代
- L3_MD/Model: 模型级非线性求解

### 向下依赖(依赖谁)
- L2_NM/Solver/LinSolv: 线性系统求解(切线方程)
- L2_NM/Matrix: 矩阵运算
- L2_NM/Base: 范数计算/工具函数

---

## 八、命名规范验证

### 模块前缀
✅ `NM_Nonlinear_` - 符合L2_NM层命名规范

### 过程命名
✅ `NM_Nonlinear_Newton_Solve` - 域+子域+算法+操作
✅ `NM_Nonlinear_ArcLength_Init` - 弧长法初始化
✅ `NM_QuasiNewton_BFGS_Update` - BFGS更新

---

## 九、关键技术细节

### Newton-Raphson法
```fortran
! 标准Newton迭代
DO iter = 1, max_iter
  ! 1. 计算残差 R(u)
  CALL Compute_Residual(u, R)
  
  ! 2. 计算切线刚度 K_T = ∂R/∂u
  CALL Compute_Tangent(u, K_T)
  
  ! 3. 求解线性系统 K_T·Δu = -R
  CALL LinSolv_Solve(K_T, -R, delta_u)
  
  ! 4. 更新解 u = u + Δu
  u = u + delta_u
  
  ! 5. 收敛检查
  IF (Check_Convergence(R, delta_u)) EXIT
END DO
```

### ArcLength弧长法
```fortran
! 弧长约束方程
! Δuᵀ·Δu + Δλ²·Pᵀ·P = Δs²
! 其中Δs为弧长半径,Δλ为载荷因子增量
```

### TrustRegion信任域
```fortran
! 信任域子问题
! min m(p) = f + gᵀ·p + 1/2·pᵀ·B·p
! s.t. ‖p‖ ≤ Δ (信任域半径)
```

---

## 十、测试策略

### 单元级测试
- Newton法: 标量非线性方程验证
- ArcLength: 屈曲后行为追踪
- TrustRegion: Rosenbrock函数优化

### 集成级测试
- 与LinSolv集成: 切线系统求解
- 与L4_PH集成: 残差/切线计算
- 后屈曲分析: 弧长法路径跟踪

### 性能基准
- 大规模非线性问题迭代次数
- 不同算法收敛性对比
- 自适应步长策略效果

---

## 十一、迁移计划

### 旧版封装层迁移 (UF_NonlinSolv → NM_Nonlinear_*)
| 旧文件 | 新位置 | 优先级 |
|--------|--------|--------|
| UF_NonlinSolv.f90 | NM_Nonlinear_Newton_Core.f90 | P1 |

---

## 十二、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本,创建NonlinSolv域合同卡 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_ContinuationMethod.f90` | `NM_ContinuationMethod` | `Continuation_Params`, `Continuation_State`, `Continuation_Result`, `Homotopy_Params`, `Predictor_Corrector_Result` | `NM_Continuation_Solv` (SUB,PUB,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `NM_Natural_Continuation` (SUB,PUB,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `NM_Ps_Continuation` (SUB,PRV,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `NM_Homotopy_Solv` (SUB,PUB,—); `Continuation_proc` (SUB,PRV,—); `NM_Tangent_Predictor` (SUB,PUB,—); `NM_Secant_Predictor_Cont` (SUB,PUB,—); `NM_Euler_Predictor` (SUB,PUB,—); `NM_Newton_Corrector` (SUB,PUB,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `NM_PseudoArclength_Corrector` (SUB,PUB,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `NM_Calc_Tangent_Vector` (SUB,PUB,—); `NM_Calc_Null_Space` (SUB,PUB,—); `NM_Adapt_Step_Size` (FN,PUB,Bridge); `NM_Update_Continuation_State` (SUB,PUB,Compute); `NM_Continuation_Init` (SUB,PUB,Init); `NM_Check_Turning_Point` (FN,PUB,Validate); `NM_Check_Bifurcation` (FN,PRV,Validate); `Solv_Lin_System` (SUB,PRV,—) |
| `NM_NonlinSolv.f90` | `NM_NonlinSolv` | `UF_NLParams`, `UF_NLResult` | `residual_interface` (SUB,PRV,—); `tangent_interface` (SUB,PRV,—); `adjust_arc_length` (SUB,PRV,—); `lbfgs_line_search` (SUB,PRV,Query); `nl_arc_length_crisfield` (SUB,PUB,—); `linear_solve` (SUB,PRV,Compute); `nl_convergence_check` (SUB,PUB,Validate); `nl_lbfgs` (SUB,PUB,—); `nl_line_search` (SUB,PUB,Query); `nl_newton_raphson` (SUB,PUB,—); `linear_solve` (SUB,PRV,Compute) |
| `NM_NonlinearArcLength.f90` | `NM_NonlinearArcLength` | `ArcLength_Params`, `ArcLength_State` | `NM_ArcLength_AdaptiveStepSize` (SUB,PUB,Bridge); `NM_ArcLength_Constraint_Equation` (SUB,PUB,—); `NM_ArcLength_GetPathFollowing` (SUB,PUB,Query); `NM_ArcLength_Update_Load_Factor` (SUB,PUB,Compute); `NM_ArcLength_Adaptive_Ctrl` (SUB,PUB,Bridge); `NM_ArcLength_Crisfield_Step` (SUB,PUB,—); `NM_ArcLength_GetStatistics` (SUB,PUB,Query); `NM_ArcLength_Riks_Step` (SUB,PUB,—); `NM_ArcLength_Solv` (SUB,PUB,—); `Solv_Lin_System` (SUB,PRV,—) |
| `NM_NonlinearNewton.f90` | `NM_NonlinearNewton` | `Newton_Solver_Params`, `Newton_Iteration_State` | `FInternalProc` (SUB,PRV,—); `f_internal_proc` (TBP,PRV,—); `Apply_Line_Search` (SUB,PRV,Query); `Calc_Identity_Stiff` (SUB,PRV,—); `Invoke_TrustRegion_Solv` (SUB,PRV,—); `NM_BFGS_Solv` (SUB,PUB,—); `NM_BFGS_Update_Mtx` (SUB,PRV,Compute); `NM_LBFGS_Solv` (SUB,PUB,—); `NM_LBFGS_Update` (SUB,PUB,Compute); `NM_ModifiedNewton_GetStatistics` (SUB,PUB,Query); `NM_ModifiedNewton_Solv` (SUB,PUB,—); `NM_Newton_ComputeTangentStiffness` (SUB,PUB,Compute); `NM_Newton_BFGS_Update` (SUB,PUB,Compute); `NM_Newton_Calc_Residual` (SUB,PUB,—); `NM_Newton_Check_Conv` (SUB,PUB,Validate); `NM_Newton_GetStatistics` (SUB,PUB,Query); `NM_Newton_Modified_Iteration` (SUB,PUB,—); `NM_Newton_Solv` (SUB,PUB,—); `NM_Newton_Standard_Iteration` (SUB,PUB,—); `NM_QuasiNewton_GetStatistics` (SUB,PUB,Query); `NM_Theory_ExportList` (SUB,PUB,—); `NM_Theory_GetNumModules` (SUB,PUB,Query); `NM_Theory_QueryByIndex` (SUB,PUB,Query); `NM_Theory_Unified_Describe` (SUB,PUB,—); `NM_Theory_Unified_Query` (SUB,PUB,Query); `OUTER_PRODUCT` (FN,PRV,—) |
| `NM_NonlinearTrustRegion.f90` | `NM_NonlinearTrustRegion` | `TrustRegion_Params`, `TrustRegion_State` | `Calc_Cauchy_Step` (SUB,PRV,—); `Calc_Dogleg_Step` (SUB,PRV,—); `NM_Tr_AdaptiveRadius` (SUB,PRV,Bridge); `NM_TrustRegion_GetStatistics` (SUB,PUB,Query); `NM_TrustRegion_Solv` (SUB,PUB,—); `Residual_proc` (SUB,PRV,—); `Jacobian_proc` (SUB,PRV,—); `Solv_SPD_System` (SUB,PRV,—); `Solv_Tau_On_Dogleg` (SUB,PRV,—) |
| `NM_QuasiNewtonFamily.f90` | `NM_QuasiNewtonFamily` | `QuasiNewton_Params`, `QuasiNewton_State`, `QuasiNewton_Result`, `LBFGS_Storage` | `NM_QuasiNewton_Solv` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_BFGS_Solv` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_DFP_Solv` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_SR1_Solv` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_LBFGS_Solv` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_BFGS_Update` (SUB,PUB,Compute); `NM_DFP_Update` (SUB,PUB,Compute); `NM_SR1_Update` (SUB,PUB,Compute); `NM_Broyden_Update` (SUB,PUB,Compute); `NM_LBFGS_Init` (SUB,PUB,Init); `NM_LBFGS_Store` (SUB,PUB,—); `NM_LBFGS_Two_Loop_Recursion` (SUB,PUB,—); `NM_QuasiNewton_Init` (SUB,PUB,Init); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_Calc_Search_Direction` (FN,PUB,Query); `NM_Check_Curvature_Condition` (FN,PUB,Validate); `OUTER_PRODUCT` (FN,PRV,—) |
