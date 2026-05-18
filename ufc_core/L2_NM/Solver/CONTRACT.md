## Solver 域级合同卡（L2_NM）

- **层级**：L2_NM  
- **域名**：Solver / 线性方程组求解（教学与桥接层）  
- **缩写**：`NM_Solver_*`（本卡）、大规模稀疏主路径归口 **`NM_LinSolv_*`** / **`UF_LinearSolver`**（`LinSolv/` 子树）  

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 职责边界（一体 / 无暗道）

| 路径 | 职责 |
|------|------|
| **`NM_Solver_Direct` / `NM_Solver_Iterative` / `NM_Solver_Precond` / `NM_Solver_Types`** | 稠密/CSR 上 **可单测** 的 LU、Cholesky、GMRES(m)、CG、BiCGSTAB；Jacobi / ILU(0) / SSOR 预处理；**不**替代 `LinSolv` 中多前端、多后端与 RT 桥接。 |
| **`LinSolv/*`** | 生产型稀疏直接/迭代、配置、AMG、与 `NM_Sparse_Matrix_Core` / `NM_LinSolv_Direct_Core` 的深度集成。 |
| **`NM_Solver_SVD_Core`** | LAPACK `DGESDD` 封装与 SVD 派生量；见 `CONTRACT_SVD.md`。 |

新功能默认应挂到 **稳定桥接 + LinSolv**，本域模块仅补充 **算法参考实现** 与 **契约演示**。

---

### 四型（Desc / State / Algo / Ctx）

| 型 | 内容 | 锚点 |
|----|------|------|
| **Desc** | `LinearSolver`（`solver_type`、`precond_type`、`max_iter`、`tolerance`、`restart_freq`）；`Preconditioner`（类型 + CSR 副本 `pc_*`） | 与 `NM_Solver_Types` 一致 |
| **State** | `SolverStats`（`iterations`、`residual_norm`、`initial_residual`、`convergence_flag`、`residual_history` 可选） | 热路径不写文件 |
| **Algo** | `Solve_Direct_LU` / `Solve_Direct_Cholesky`；`GMRES_Solve` / `CG_Solve` / `BiCGSTAB_Solve`；`Construct_*_Precond`；`Check_Convergence` | 调用 `NM_Matrix_MatMul::NM_SpMV_CSR`、LAPACK `DGETRF/DGETRS`、`DPOTRF/DPOTRS` |
| **Ctx** | 无全局求解 Ctx；工作数组在子程序内 `ALLOCATE`；直接法在分解前 **拷贝** `a_orig` 用于事后残差 `‖Ax−b‖₂` | 避免分解覆盖后误用 `A%data` 验残 |

**灵敏度 / 全局平衡残差 R（与总纲 §11.4.1、集成规范 §3.2、契约卡 `L3_MD/contracts/CONTRACT_R_Theta_FourKind.md` 对齐）**：

- **全局 R 向量**（Newton 平衡残差、n_dof 维）：放在 **调用方形参** 或非线性 **回调 `R(:)`**（见 `NonlinSolv/UF_NonlinSolv.f90` 中 `residual_interface`），或 **L5_RT** 步进统一 `Arg` 的全局指针域（模板 `UFC/docs/templates/RT_XXX_StepDriver_Proc.f90` → `RT_SD_Arg%f_global` 等）；**不要**把整条 R 塞进本域 **`SolverStats`**（该型仅 **范数/迭代统计**）。
- **伴随 / 层 2**：右端项如 `rhs_lambda(:)` 等保持 **形参**（例：`GMRES_Solve_Transpose.f90`）；**θ、模式** 由 `NM_AI_Adjoint_*` 等 **专用四类** 承载，不侵占本表 **SolverStats** 语义。
- **层 3（∂R/∂θ）**：单元侧残差块仍归 **L4_PH `State%rhs`** 装配链；本域仅矩阵运算与 TransposeSolve。

---

### 预处理与 CSR 布局

- **左预处理 GMRES/CG/BiCGSTAB**：`r ← M⁻¹(b−Ax)`，`w ← M⁻¹(A v)`（与 Krylov 子空间一致）。  
- **Jacobi**：`diag` 存 **逆**；`Construct_Jacobi_Precond` 从 CSR 行内找 `(i,i)`。  
- **ILU(0)**：在 **固定 CSR 模式** 下原位因子，因子存 `pc_lu_vals`；应用为 **前向 L + 回代 U**（`NM_Precond_Apply_ILU0_Internal`）。复杂度 O(n·deg²) 量级，仅供中小规模验证。  
- **SSOR**：存 `pc_mat_vals` 与 `ssor_omega`；应用为 **一次前向 SOR 扫 + 一次后向 SOR 扫**（近似 `M⁻¹v`）。  

`NM_Solver_Types` **不再** 提供类型绑定 `Construct_ILU0`（已移除非法 `TYPE(*)` 桩），ILU/SSOR **仅** 通过 `NM_Solver_Precond` 过程构造，避免重复与环状 `USE`。

---

### 依赖

- **L1**：`IF_Prec_Core`（`wp`/`i4`/`i8`）。  
- **L2 Matrix**：`NM_Matrix_Types`、`NM_Matrix_MatMul`（`NM_SpMV_CSR`）。  
- **外部数学库**：LAPACK/BLAS（直接法与 SVD）。  

---

### 收敛与 `convergence_flag`（本域约定）

| 值 | 含义 |
|----|------|
| 0 | 成功（迭代满足相对残差，或直接法完成分解与求解） |
| 2 | 迭代未在 `max_iter` 内满足容差 |
| 3 | LU：`DGETRF` 报告奇异（`info>0`） |
| 4 | Cholesky：`DPOTRF` 报告非正定（`info>0`） |
| 5 | 直接法：矩阵未分配 |

相对残差：`‖r‖₂ ≤ tol · max(‖b‖₂, 1)`（与 `CG` / `GMRES` / `BiCGSTAB` 一致）。

---

### 实现锚点

- `NM_Solver_Types.f90` — `LinearSolver`、`SolverStats`、`Preconditioner`、`Precond_Apply_Left`（含 ILU0/SSOR 内部应用子程序）。  
- `NM_Solver_Direct.f90` — `bx(n,1)` 满足 `DGETRS`/`DPOTRS` 二维接口；`a_orig` 验残。  
- `NM_Solver_Iterative.f90` — `Compute_Givens`（稳定 `√(a²+b²)`）；GMRES 重启与 **Krylov 中断** 分支 `jmax`。  
- `NM_Solver_Precond.f90` — `CSR_ILU0_Factor`、`Construct_ILU0_Precond`、`Construct_SSOR_Precond`。  
- `NM_Solver_SVD_Core.f90` — SVD；`CONTRACT_SVD.md`。  

---

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_SOLVER_xxx`（20500–20599） |
| 严重级 | WARNING（迭代未收敛但返回当前解）/ ERROR（奇异矩阵、非正定、分配失败） |
| 传播规则 | `convergence_flag` + `SolverStats` 统一返回；LAPACK `info` 映射为 flag 值（3=奇异,4=非正定） |
| 恢复策略 | 迭代法返回 flag=2 与当前残差，不 `STOP`；直接法返回 flag=3/4/5，由调用方决定回退 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L2_NM/Matrix | S | 消费 CSR 类型与 `NM_SpMV_CSR` |
| 2 | L2_NM/ExternalLibs | U | LAPACK `DGETRF`/`DGETRS`/`DPOTRF`/`DPOTRS` |
| 3 | L2_NM/Bridge | S(被消费) | Bridge 消费 Solver 配置进行外部求解路由 |
| 4 | L5_RT/Solver | S(被消费) | RT 层求解驱动消费本域线性求解能力 |
| 5 | L1_IF/Precision | U | 精度定义 `wp`, `i4`, `i8` |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| `USE IF_Prec_Core` 精度统一 | 硬 | 编译 | P0 |
| `convergence_flag` 语义与合同表一致 | 硬 | 单测 | P0 |
| 全局 R 向量不存入 `SolverStats`（仅范数/统计） | 硬 | Code Review | P0 |
| ILU(0)/SSOR 仅通过 `NM_Solver_Precond` 构造 | 硬 | 编译（无类型绑定 `Construct_ILU0`） | P0 |
| 新功能优先挂 `LinSolv` 稳定桥接 | 软 | Code Review | P1 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` + `CONTRACT_SVD.md` + 子域合同卡 | Active |
| 2 | Definition/Schema | `NM_Solver_Types.f90` | `LinearSolver`, `SolverStats`, `Preconditioner` |
| 3 | Desc | `LinearSolver`（solver_type, precond_type, max_iter, tolerance） | 求解器配置描述 |
| 4 | State | `SolverStats`（iterations, residual_norm, convergence_flag） | 求解统计 |
| 5 | Algo | `Solve_Direct_LU/Cholesky`, `GMRES_Solve`, `CG_Solve`, `BiCGSTAB_Solve` | 求解算法 |
| 6 | Ctx | — | 工作数组在子程序内 `ALLOCATE` |
| 7 | Kernel | `NM_Solver_Direct.f90`, `NM_Solver_Iterative.f90`, `NM_Solver_Precond.f90` | 计算核心 |
| 8 | Bridge | `LinSolv/`（生产级桥接） | 与 RT 层桥接 |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | — | 无注册（路由在 LinSolv 层） |
| 11 | Populate | — | 求解器实例由调用方构造 |
| 12 | Diagnostics | `convergence_flag` + `residual_history` | 收敛诊断 |
| 13 | Test | `L2_NM/Tests/` | Deferred |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 线性方程组求解：LU/Cholesky 直接法、Krylov 子空间迭代法（GMRES/CG/BiCGSTAB）、预处理（Jacobi/ILU0/SSOR） |
| 逻辑链 | 调用方构造 `LinearSolver` → 选择直接/迭代 → 预处理构造 → 求解 → `SolverStats` 返回 |
| 计算链 | 热路径 Kδu=−R 在 NR 迭代内多次调用；SpMV 委托 `NM_Matrix`；分解委托 LAPACK |
| 数据链 | Desc(冷,solver_type/tolerance) → State(iterations/residual_norm) → Algo 运算中 `a_orig` 拷贝用于事后验残 |

---

**版本**：v2.2  
**最后更新**：2026-04-17  
**状态**：与实现同步（`IF_Prec_Core`；ILU0/SSOR/BiCGSTAB；直接法二维右端项与验残）；v2.2 增补 **子域合同卡引用**

---

## 子域合同卡

| 子域 | 合同卡 | 版本 | 状态 |
|------|--------|------|------|
| **LinSolv** | `LinSolv/CONTRACT.md` | v1.0 | ✅ 已创建 |
| **NonlinSolv** | `NonlinSolv/CONTRACT.md` | v1.0 | ✅ 已创建 |
| **SVD** | `CONTRACT_SVD.md` | v1.0 | ✅ 已有 |

**说明**:
- LinSolv子域合同卡: 详细定义直接法/迭代法/预条件子/复数求解/稀疏接口
- NonlinSolv子域合同卡: 详细定义Newton/TrustRegion/ArcLength/QuasiNewton/Continuation
- 本域合同卡聚焦于Solver核心模块(NM_Solver_*)，子域合同卡聚焦于生产级实现(NM_LinSolv_*/NM_Nonlinear_*)

---

## Phase 4 核心闭环链（验收锚点）

本域在闭环 **`StepDriver → Assembly → Element → Material → Solver`** 中为 **最后一环**（数值解）。**验收**：与 [`Phase4_核心闭环链_验收追踪.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/Phase4_核心闭环链_验收追踪.md) 及 [`06_域级落地验收表_CodeReview与里程碑.md`](../../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/06_域级落地验收表_CodeReview与里程碑.md) **C 轴**对齐（编译/单测/smoke 命令写在 PR 或本子域 `LinSolv/CONTRACT.md`）。


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `AI/NM_AIAdjointAlgo.f90` | `NM_AIAdjointAlgo` | `NM_AI_Adjoint_Type` | `NM_AI_Adjoint_Init` (SUB,PUB,Init); `NM_AI_Adjoint_Finalize` (SUB,PUB,Finalize); `NM_AI_Adjoint_Solve` (SUB,PUB,Compute) |
| `AI/NM_AIPrecondAlgo.f90` | `NM_AIPrecondAlgo` | `NM_AI_Precond_Type` | `NM_AI_Precond_Init` (SUB,PUB,Init); `NM_AI_Precond_Finalize` (SUB,PUB,Finalize); `NM_AI_Precond_Apply` (SUB,PUB,—) |
| `AI/NM_AISparseSolverAlgo.f90` | `NM_AISparseSolverAlgo` | `NM_AI_SparseSolver_Type` | `NM_AI_SparseSolver_Init` (SUB,PUB,Init); `NM_AI_SparseSolver_Finalize` (SUB,PUB,Finalize); `NM_AI_SparseSolver_Optimize` (SUB,PUB,—) |
| `Conv/NM_ConvAccel.f90` | `NM_ConvAccel` | `Accel_Params`, `Seq_Storage`, `Eps_Table`, `Vec_Eps_Table`, `Accel_Result` | `NM_Accel_Seq` (SUB,PUB,—); `NM_Accel_VecSeq` (SUB,PUB,—); `NM_Aitken_D2` (SUB,PUB,—); `NM_Aitken_Iter` (SUB,PUB,—); `fixed_point_func` (FN,PRV,—); `NM_Aitken_Val` (FN,PRV,—); `NM_Build_Epsilon_Table` (SUB,PRV,Populate); `NM_Eps_Algo` (SUB,PUB,—); `NM_Eps_Extrap` (SUB,PUB,—); `NM_Err_Est` (FN,PUB,—); `NM_Rich_Extrap` (SUB,PUB,—); `NM_Select_Method` (FN,PUB,—); `NM_Shanks_Tf` (SUB,PUB,—); `NM_Shanks_Tf_Ord` (SUB,PUB,—); `NM_Store_SeqTerm` (SUB,PUB,—); `NM_Vec_Aitken` (SUB,PRV,—); `NM_Vec_Eps_Algo` (SUB,PUB,—) |
| `Conv/NM_ConvIterPrec.f90` | `NM_ConvIterPrec` | `Preconditioner_Params`, `Preconditioner_Data`, `NM_AMG_Level`, `Preconditioner_Result` | `NM_Preconditioner_Setup` (SUB,PUB,Init); `NM_ILU_Setup` (SUB,PUB,Init); `NM_IC_Setup` (SUB,PUB,Init); `NM_Jacobi_Setup` (SUB,PUB,Init); `NM_SSOR_Setup` (SUB,PUB,Init); `NM_SPAI_Setup` (SUB,PUB,Init); `NM_AMG_Setup` (SUB,PUB,Init); `NM_Preconditioner_Apply` (SUB,PUB,—); `NM_ILU_Solv` (SUB,PUB,—); `NM_IC_Solv` (SUB,PUB,—); `NM_Jacobi_Apply` (SUB,PUB,—); `NM_SSOR_Apply` (SUB,PUB,—); `NM_SPAI_Apply` (SUB,PUB,—); `NM_AMG_VCycle` (SUB,PUB,—); `NM_Preconditioner_Destroy` (SUB,PUB,Finalize); `NM_Estimate_Condition_Number` (FN,PUB,—) |
| `Conv/NM_ConvIterSolv.f90` | `NM_ConvIterSolv` | `Iter_Solv_Params`, `Iter_Solv_State`, `Iter_Solv_Result`, `GMRES_Workspace` | `Apply_Givens_Rotation` (SUB,PRV,—); `Calc_Givens_Rotation` (SUB,PRV,—); `NM_BiCGSTAB_L_Solv` (SUB,PUB,—); `NM_BiCGSTAB_Solv` (SUB,PUB,—); `NM_Conv_Check` (FN,PUB,Validate); `NM_GMRES_M_Solv` (SUB,PUB,—); `NM_GMRES_Solv` (SUB,PUB,—); `NM_IDR_Solv` (SUB,PUB,—); `NM_Iter_Solv` (SUB,PUB,—); `NM_Residual` (FN,PUB,—); `NM_TFQMR_Solv` (SUB,PUB,—) |
| `Conv/NM_ConvKrylovExt.f90` | `NM_ConvKrylovExt` | `Krylov_Extension_Params`, `Krylov_Basis`, `Augmented_Krylov_Subspace`, `Spectral_Info`, `Recursive_Krylov_Data`, `Krylov_Extension_Result` | `NM_Krylov_Extended_Solv` (SUB,PUB,—); `NM_Adaptive_Restart_GMRES` (SUB,PUB,Bridge); `NM_Augmented_GMRES` (SUB,PUB,—); `NM_Deflated_GMRES` (SUB,PUB,—); `NM_Build_Krylov_Basis` (SUB,PUB,Populate); `NM_Extend_Krylov_Basis` (SUB,PUB,—); `NM_Orthogonalize_Vector` (SUB,PUB,—); `NM_Calc_Ritz_Pairs` (SUB,PUB,—); `NM_Augment_Subspace` (SUB,PUB,—); `NM_Se_Au_Vectors` (SUB,PRV,—); `NM_Co_Sp_Preconditioner` (SUB,PRV,—); `NM_Update_Spectral_Info` (SUB,PUB,Compute); `NM_Krylov_Basis_Init` (SUB,PUB,Init); `NM_Krylov_Basis_Destroy` (SUB,PUB,Finalize) |
| `Conv/NM_ConvLS.f90` | `NM_ConvLS` | `LineSearch_Params`, `LineSearch_State`, `LineSearch_Result`, `Function_Eval`, `TrustRegion_Params`, `TrustRegion_State` | `NM_LineSearch_Default_Params` (FN,PUB,—); `NM_LineSearch` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_LineSearch_Armijo` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `NM_LineSearch_Wolfe` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_LineSearch_Strong_Wolfe` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `Gradient_proc` (FN,PRV,—); `NM_Backtracking_LineSearch` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `NM_Backtracking_Cubic` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `NM_Cubic_Interpolation_Step` (FN,PUB,—); `NM_Quadratic_Interpolation_Step` (FN,PUB,—); `NM_Golden_Section_LineSearch` (SUB,PUB,—); `Objective_proc` (FN,PRV,—); `NM_Eval_Phi` (FN,PUB,—); `Objective_proc` (FN,PRV,—); `NM_Eval_Dphi` (FN,PUB,—); `Gradient_proc` (FN,PRV,—); `NM_Check_Armijo_Condition` (FN,PUB,Validate); `NM_Check_Wolfe_Condition` (FN,PUB,Validate); `NM_LineSearch_Init` (SUB,PUB,Init); `NM_TrustRegion_Default_Params` (FN,PUB,—); `NM_Find_Boundary_Intersection` (SUB,PRV,Query); `NM_TrustRegion_Dogleg` (SUB,PUB,—); `NM_TrustRegion_Steihaug` (SUB,PUB,—); `NM_TrustRegion_Update_Radius` (SUB,PUB,Compute) |
| `Conv/NM_ConvMG.f90` | `NM_ConvMG` | `Multigrid_Params`, `Grid_Level`, `Multigrid_Solver`, `Multigrid_Result` | `NM_Multigrid_Solv` (SUB,PUB,—); `NM_Multigrid_VCycle` (SUB,PUB,—); `NM_Multigrid_WCycle` (SUB,PUB,—); `NM_Multigrid_Build_Hierarchy` (SUB,PUB,Populate); `NM_GMG_Build_Levels` (SUB,PUB,Populate); `NM_AMG_Build_Levels` (SUB,PUB,Populate); `NM_Calc_Prolongation` (SUB,PUB,—); `NM_Calc_Restriction` (SUB,PUB,—); `NM_MG_Smooth` (SUB,PRV,—); `NM_MG_Smooth_Jacobi` (SUB,PUB,—); `NM_MG_Smooth_GaussSeidel` (SUB,PUB,—); `NM_MG_Smooth_SOR` (SUB,PUB,—); `NM_MG_Coarse_Solv` (SUB,PRV,—); `NM_Multigrid_Init` (SUB,PUB,Init); `NM_Multigrid_Destroy` (SUB,PUB,Finalize) |
| `Coupling/NM_CplElectroMech.f90` | `NM_CplElectroMech` | — | `NM_Coupling_EM_Init` (SUB,PUB,Init); `NM_Coupling_EM_Solv` (SUB,PUB,—); `NM_Coupling_EM_Elec_Solv` (SUB,PUB,—); `NM_Coupling_EM_Struct_Solv` (SUB,PUB,—); `NM_Coupling_EM_PiezoStress_Calc` (SUB,PUB,—); `NM_Coupling_EM_Cleanup` (SUB,PUB,Finalize) |
| `Coupling/NM_CplFSI.f90` | `NM_CplFSI` | — | `NM_Coupling_FSI_Init` (SUB,PUB,Init); `NM_Coupling_FSI_Solv` (SUB,PUB,—); `NM_Coupling_FSI_Fluid_Solv` (SUB,PUB,—); `NM_Coupling_FSI_Struct_Solv` (SUB,PUB,—); `NM_Coupling_FSI_FluidForce_Calc` (SUB,PUB,—); `NM_Coupling_FSI_Interface_Transfer` (SUB,PUB,—); `NM_Coupling_FSI_CheckConv` (SUB,PUB,Validate); `NM_Coupling_FSI_Cleanup` (SUB,PUB,Finalize) |
| `Coupling/NM_CplMonolithic.f90` | `NM_CplMonolithic` | — | `NM_Coupling_Mono_Init` (SUB,PUB,Init); `NM_Coupling_Mono_Assemble` (SUB,PUB,—); `NM_Coupling_Mono_Direct_Solv` (SUB,PUB,—); `NM_Coupling_Mono_Iter_Solv` (SUB,PUB,—); `NM_Coupling_Mono_Schur_Solv` (SUB,PUB,—); `NM_Coupling_Mono_BlockPrec` (SUB,PUB,—); `NM_Coupling_Mono_Cleanup` (SUB,PUB,Finalize) |
| `Coupling/NM_CplPredictor.f90` | `NM_CplPredictor` | — | `NM_Coupling_Pred_Init` (SUB,PUB,Init); `NM_Coupling_Pred_ZeroOrder` (SUB,PUB,—); `NM_Coupling_Pred_Constant` (SUB,PUB,—); `NM_Coupling_Pred_Linear` (SUB,PUB,—); `NM_Coupling_Pred_Quadratic` (SUB,PUB,—); `NM_Coupling_Pred_Predict` (SUB,PUB,—); `NM_Coupling_Pred_Cleanup` (SUB,PUB,Finalize) |
| `Coupling/NM_CplStaggered.f90` | `NM_CplStaggered` | — | `NM_Coupling_Stag_Init` (SUB,PUB,Init); `NM_Coupling_Stag_Standard` (SUB,PUB,—); `NM_Coupling_Stag_Improved` (SUB,PUB,—); `NM_Coupling_Stag_PredictCorrect` (SUB,PUB,—); `NM_Coupling_Stag_Subcycling` (SUB,PUB,—); `NM_Coupling_Stag_DataTransfer` (SUB,PUB,—); `NM_Coupling_Stag_CheckConv` (SUB,PUB,Validate); `NM_Coupling_Stag_Cleanup` (SUB,PUB,Finalize) |
| `Coupling/NM_CplThermalStruct.f90` | `NM_CplThermalStruct` | — | `NM_Coupling_TS_Init` (SUB,PUB,Init); `NM_Coupling_TS_Solv` (SUB,PUB,—); `NM_Coupling_TS_Temp_Solv` (SUB,PUB,—); `NM_Coupling_TS_Struct_Solv` (SUB,PUB,—); `NM_Coupling_TS_ThermalStrain_Calc` (SUB,PUB,—); `NM_Coupling_TS_Cleanup` (SUB,PUB,Finalize) |
| `NM_GMRESSolveTranspose.f90` | `NM_GMRESSolveTranspose` | — | `NM_GMRES_Solve_Transpose` (SUB,PUB,Compute); `NM_CG_Solve_Transpose` (SUB,PUB,Compute); `NM_Adjoint_Solve` (SUB,PUB,Compute); `SparseMatrix_Vector_Multiply` (SUB,PRV,—); `Adjoint_Solve_Placeholder` (SUB,PRV,Compute) |
| `NM_Solv_Dir.f90` | — | — | — |
| `NM_Solv_Iter.f90` | `NM_SolvIter` | `GMRES_Arg`, `CG_Arg`, `BiCGSTAB_Arg` | `GMRES_Solve` (SUB,PUB,Compute); `CG_Solve` (SUB,PUB,Compute); `BiCGSTAB_Solve` (SUB,PUB,Compute); `Check_Convergence` (FN,PUB,—); `Compute_Givens` (SUB,PRV,—); `Solve_Upper_Triangular` (SUB,PRV,—); `Norm_L2` (FN,PRV,—) |
| `NM_Solv_Precond.f90` | — | — | — |
| `NM_Solv_SVD.f90` | `NM_SolvSVD` | — | `SVD_Compute_Full` (SUB,PUB,Compute); `TO_STRING` (FN,PRV,—); `SVD_Compute_Thin` (SUB,PUB,Compute); `TO_STRING` (FN,PRV,—); `SVD_Compute_Partial` (SUB,PUB,Compute); `SVD_Condition_Number` (FN,PUB,—); `SVD_Rank` (FN,PUB,—) |
| `NM_Solv_Def.f90` | — | — | — |
| `NM_SpMVCSRTranspose.f90` | `NM_SpMVCSRTranspose` | `NM_SparseMatrix_CSR` | `NM_CSR_Transpose` (SUB,PUB,—); `NM_CSR_Transpose_InPlace` (SUB,PUB,—); `NM_CSR_Symmetrize` (SUB,PUB,—) |
