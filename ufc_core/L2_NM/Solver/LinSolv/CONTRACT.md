# LinSolv域合同卡 (L2_NM/Solver/LinSolv)

**Layer**: L2_NM (数值算法层)  
**Domain**: Solver/LinearSolver (线性求解器子域)  
**Version**: v1.0  
**Created**: 2026-04-17  
**Status**: ✅ 新建

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、职责边界

### 核心职责
- **定位**: UFC L2_NM层线性求解器子域，统一的直接法/迭代法/预条件子/复数求解/稀疏接口中心
- **职责**: 直接求解器(LU/Cholesky/Multifrontal)、迭代求解器(CG/GMRES/BiCGSTAB)、预条件子(ILU/SSOR/AMG)、复数求解器、稀疏求解器接口
- **边界**: 仅提供线性方程组求解算法；非线性求解由NonlinSolv域处理
- **依赖**: L2_NM Solver核心子域, 依赖Matrix域(稀疏矩阵), 被Assembly/Solver域依赖

### 与Solver域的关系
| Solver域 (NM_Solver_*) | LinSolv域 (NM_LinSolv_*) | 关系 |
|------------------------|-------------------------|------|
| NM_Solver_Direct.f90 | NM_LinSolv_Direct_LU_Core.f90 | 参考实现→生产实现 |
| NM_Solver_Iterative.f90 | NM_LinSolv_Iter_GMRES_Core.f90 | 参考实现→生产实现 |
| NM_Solver_Precond.f90 | NM_LinSolv_Prec_ILU_Core.f90 | 参考实现→生产实现 |
| 教学/单测用途 | 生产/多前端/多后端 | 职责分离 |

---

## 二、文件清单 (25个文件)

### 核心容器
| 文件 | 行数 | 职责 |
|------|------|------|
| NM_Solv_Core.f90 | 255 | 求解器核心容器(Init/Finalize/SetLin/SetNonlin/GetSummary) |

### 直接求解器 (4个文件)
| 文件 | 行数 | 算法 |
|------|------|------|
| NM_LinSolv_Direct_Core.f90 | ~450 | 直接求解器统一接口 |
| NM_LinSolv_Direct_LU_Core.f90 | ~600 | LU分解(DGETRF/DGETRS) |
| NM_LinSolv_Direct_Cholesky_Core.f90 | ~500 | Cholesky分解(DPOTRF/DPOTRS) |
| NM_LinSolv_Direct_Multifrontal_Core.f90 | ~430 | 多前端法 |

### 迭代求解器 (5个文件)
| 文件 | 行数 | 算法 |
|------|------|------|
| NM_LinSolv_Iter_Core.f90 | ~400 | 迭代求解器统一接口 |
| NM_LinSolv_Iter_CG_Core.f90 | ~330 | 共轭梯度法(CG) |
| NM_LinSolv_Iter_GMRES_Core.f90 | ~540 | GMRES(m)重启算法 |
| NM_LinSolv_Iter_BiCGSTAB_Core.f90 | ~460 | 双共轭梯度稳定法 |
| NM_LinSolv_Iter_Adv_Core.f90 | ~475 | 高级迭代算法 |

### 预条件子 (6个文件)
| 文件 | 行数 | 算法 |
|------|------|------|
| NM_LinSolv_Prec_Core.f90 | ~405 | 预条件子统一接口 |
| NM_LinSolv_Prec_ILU_Core.f90 | ~495 | ILU0/ILUT不完全LU分解 |
| NM_LinSolv_Prec_SSOR_Core.f90 | ~420 | 对称逐次超松弛 |
| NM_LinSolv_Prec_AMG_Core.f90 | ~800 | 代数多重网格(AMG) |
| NM_LinSolv_Prec_AMG_Multilevel_Core.f90 | ~605 | 多层AMG |

### 配置与接口 (4个文件)
| 文件 | 行数 | 职责 |
|------|------|------|
| NM_LinSolv_Config_Core.f90 | ~580 | 求解器配置管理 |
| NM_ComplexLinearSolver.f90 | ~110 | 复数矩阵求解器 |
| NM_Sparse_Solver_Interface.f90 | ~325 | 稀疏求解器统一接口 |
| UF_MemoryPool.f90 | ~275 | 专用内存池(MemPool/MatPool) |

### 封装层(旧版,待迁移) (6个文件)
| 文件 | 行数 | 状态 |
|------|------|------|
| UF_LinearSolver.f90 | ~1250 | ⚠️ 待迁移 |
| UF_Preconditioner.f90 | ~1400 | ⚠️ 待迁移 |
| UF_IterSolver.f90 | ~740 | ⚠️ 待迁移 |
| UF_DirectSolver.f90 | ~460 | ⚠️ 待迁移 |
| UF_AMG_Interface.f90 | ~430 | ⚠️ 待迁移 |
| UF_SparsePakWrapper.f90 | ~800 | ⚠️ 待迁移 |

---

## 三、四类TYPE映射

| Type种类 | 文件 | TYPE名称 | 核心职责 |
|----------|------|----------|----------|
| **Desc** | NM_Base_Types.f90 | NM_LinSolv_Desc | 线性求解器配置(solver_type/precond_type/max_iter/tolerance) |
| **State** | NM_Solver_Types.f90 | SolverStats | 求解器状态(iterations/residual_norm/convergence_flag) |
| **Algo** | NM_LinSolv_* | 各求解器子程序 | 直接法/迭代法/预条件子算法 |
| **Ctx** | 无 | - | 工作数组在子程序内ALLOCATE |

---

## 四、四链映射

| 链 | 映射说明 |
|---|----------|
| **理论链** | 线性代数理论→Krylov子空间方法→GMRES/CG/BiCGSTAB实现 |
| **逻辑链** | LinSolv↔Matrix(稀疏矩阵)↔Assembly(装配)↔L5_RT(求解器调度)闭环 |
| **计算链** | 直接法:LAPACK DGETRF/DGETRS; 迭代法:SpMV+预处理+收敛检查 |
| **数据链** | 求解器配置→求解状态→残差历史→收敛标志 |

---

## 五、核心算法清单

### 直接法
- ✅ LU分解: DGETRF + DGETRS (部分主元)
- ✅ Cholesky分解: DPOTRF + DPOTRS (对称正定)
- ✅ 多前端法: 大规模稀疏直接求解

### 迭代法
- ✅ CG: 对称正定系统,最优收敛
- ✅ GMRES(m): 非对称系统,m步重启
- ✅ BiCGSTAB: 非对称系统,稳定双共轭梯度

### 预条件子
- ✅ Jacobi: 对角预处理(存逆)
- ✅ ILU0: 不完全LU分解(零填充)
- ✅ ILUT: 不完全LU分解(阈值丢弃)
- ✅ SSOR: 对称逐次超松弛
- ✅ AMG: 代数多重网格
- ✅ 多层AMG: V循环/W循环

---

## 六、收敛准则

### 迭代法收敛标志
| 值 | 含义 |
|----|------|
| 0 | 成功(相对残差满足容差) |
| 2 | 迭代未在max_iter内收敛 |
| 3 | LU分解奇异(info>0) |
| 4 | Cholesky非正定(info>0) |
| 5 | 矩阵未分配 |

### 相对残差公式
```
‖r‖₂ ≤ tol · max(‖b‖₂, 1)
```

---

## 七、依赖关系

### 向上依赖(被谁使用)
- L3_MD/Assembly: 全局刚度矩阵求解
- L5_RT/Solver: 求解器调度
- L4_PH/Element: 单元-level线性系统

### 向下依赖(依赖谁)
- L2_NM/Matrix: NM_Matrix_Types, NM_Matrix_MatMul (SpMV)
- L2_NM/Base: NM_Base_Norms, NM_Base_Utils
- LAPACK/BLAS: DGETRF/DGETRS/DPOTRF/DPOTRS

---

## 八、命名规范验证

### 模块前缀
✅ `NM_LinSolv_` - 符合L2_NM层命名规范

### 过程命名
✅ `NM_LinSolv_Direct_LU_Solve` - 域+子域+算法+操作
✅ `NM_LinSolv_Prec_ILU0_Construct` - 预条件子构造

---

## 九、测试策略

### 单元级测试
- 直接法: 已知解线性系统,验证求解精度
- 迭代法: 收敛性测试,残差下降曲线
- 预条件子: 条件数改善验证

### 集成级测试
- 与Matrix域集成: 稀疏矩阵求解
- 与Assembly域集成: 全局系统求解
- 性能基准: 大规模问题求解时间

---

## 十、迁移计划

### 旧版封装层迁移 (UF_* → NM_LinSolv_*)
| 旧文件 | 新位置 | 优先级 |
|--------|--------|--------|
| UF_LinearSolver.f90 | NM_LinSolv_Direct_Core.f90 | P1 |
| UF_Preconditioner.f90 | NM_LinSolv_Prec_Core.f90 | P1 |
| UF_IterSolver.f90 | NM_LinSolv_Iter_Core.f90 | P1 |
| UF_DirectSolver.f90 | NM_LinSolv_Direct_LU_Core.f90 | P2 |
| UF_AMG_Interface.f90 | NM_LinSolv_Prec_AMG_Core.f90 | P2 |
| UF_SparsePakWrapper.f90 | NM_Sparse_Solver_Interface.f90 | P2 |

---

## 十一、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 2026-04-17 | 初始版本,创建LinSolv域合同卡 |


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_AMGInterface.f90` | `NM_AMGInterface` | `UF_AMG_Control`, `UF_AMG_Info`, `UF_AMG_Precond` | `destroy` (TBP,PRV,—); `amg_set_defaults` (SUB,PUB,Mutate); `amg_setup` (SUB,PUB,Init); `amg_apply` (SUB,PUB,—); `amg_solve` (SUB,PUB,Compute); `amg_destroy` (SUB,PUB,Finalize); `amg_precond_destroy` (SUB,PRV,Finalize) |
| `NM_ComplexLinearSolver.f90` | `NM_ComplexLinearSolver` | `NM_ComplexLinSolv_Cfg`, `NM_ComplexLinSolv_Ctx` | `NM_ComplexLinearSolver_Init` (SUB,PUB,Init); `NM_ComplexLinearSolver_Factorize` (SUB,PUB,—); `NM_ComplexLinearSolver_Solve` (SUB,PUB,Compute); `NM_ComplexLinearSolver_Finalize` (SUB,PUB,Finalize) |
| `NM_DirectSolver.f90` | `NM_DirectSolver` | `UF_LUFactor` | `destroy` (TBP,PRV,—); `direct_solve_dense` (SUB,PUB,Compute); `direct_lu_factor` (SUB,PUB,—); `direct_lu_solve` (SUB,PUB,Compute); `lu_destroy` (SUB,PRV,Finalize); `skyline_init` (SUB,PRV,Init); `skyline_factor` (SUB,PUB,—); `skyline_solve` (SUB,PUB,Compute); `skyline_destroy` (SUB,PRV,Finalize); `band_lu_factor` (SUB,PUB,—); `band_lu_solve` (SUB,PUB,Compute) |
| `NM_IterSolver.f90` | `NM_IterSolver` | `UF_IterParams` | `givens_rotation` (SUB,PRV,—); `iter_bicgstab` (SUB,PUB,—); `iter_cg` (SUB,PUB,—); `iter_gmres` (SUB,PUB,—); `iter_iccg` (SUB,PUB,—); `iter_pcg` (SUB,PUB,—) |
| `NM_LinSolvCfg.f90` | `NM_LinSolvCfg` | `NM_LinSolv_Config_Params`, `NM_LinSolv_Config_Result`, `UF_LinSolParams`, `UF_LinSolResult`, `NM_LinSolv_Config` | `destroy` (TBP,PRV,—); `NM_LinSolv_Config_Destroy` (SUB,PRV,Finalize); `NM_LinSolv_Config_AutoConfigure` (SUB,PUB,—); `NM_LinSolv_Config_Estimate_Memory` (SUB,PUB,—); `NM_LinSolv_Config_Recommend_Precond` (FN,PUB,—); `NM_LinSolv_Config_Check_SPD` (FN,PUB,Validate); `NM_LinSolv_Config_Solve_Optimized` (SUB,PUB,Compute); `NM_LinSolv_Config_Solver_Name` (FN,PRV,Compute); `NM_LinSolv_Config_Precond_Name` (FN,PRV,—); `NM_LinSolv_Config_For_Physics` (SUB,PUB,—); `NM_LinSolv_Config_Print_Summary` (SUB,PUB,IO) |
| `NM_LinSolvDir.f90` | `NM_LinSolvDir` | `CSR_Matrix`, `Direct_Solver_Params`, `LU_Factorization` | `NM_LinSolv_Direct_CSR_Init` (SUB,PUB,Init); `NM_LinSolv_Direct_LU_Factorize` (SUB,PUB,—); `NM_LinSolv_Direct_Cholesky_Factorize` (SUB,PUB,—); `NM_LinSolv_Direct_Forward_Substitution_CSR` (SUB,PRV,—); `NM_LinSolv_Direct_Forward_Substitution_NM` (SUB,PRV,—); `NM_LinSolv_Direct_Backward_Substitution_CSR` (SUB,PRV,—); `NM_LinSolv_Direct_Backward_Substitution_LT` (SUB,PRV,—); `NM_LinSolv_Direct_Backward_Substitution_NM` (SUB,PRV,—); `NM_LinSolv_Direct_Solv_System` (SUB,PUB,—); `Dense_To_CSR` (SUB,PRV,—) |
| `NM_LinSolvDirCholesky.f90` | `NM_LinSolvDirCholesky` | — | `i4_to_str` (FN,PRV,—); `NM_Cholesky_Decompose_InPlace` (SUB,PUB,—); `NM_Cholesky_Banded` (SUB,PUB,—); `NM_Cholesky_Block` (SUB,PUB,—); `NM_Cholesky_Check_SPD` (SUB,PUB,Validate); `NM_Cholesky_Decompose` (SUB,PUB,—); `NM_Cholesky_Downdate` (SUB,PUB,—); `NM_Cholesky_GetStatistics` (SUB,PUB,Query); `NM_Cholesky_Invert` (SUB,PUB,—); `NM_Cholesky_LogDet` (SUB,PUB,IO); `NM_Cholesky_Modified` (SUB,PUB,—); `NM_Cholesky_Rank1Update` (SUB,PUB,—); `NM_Cholesky_Solv` (SUB,PUB,—); `Solv_Lower_Block` (SUB,PRV,—) |
| `NM_LinSolvDirLU.f90` | `NM_LinSolvDirLU` | `NM_LU_Params` | `i4_to_str` (FN,PRV,—); `NM_LU_Block_Decompose` (SUB,PUB,—); `NM_LU_ConditionNumber` (SUB,PUB,—); `NM_LU_Decompose` (SUB,PUB,—); `NM_LU_Decompose_InPlace` (SUB,PUB,—); `NM_LU_Decompose_Pivoting` (SUB,PUB,—); `NM_LU_Determinant` (SUB,PUB,—); `NM_LU_EstimateFillIn` (SUB,PUB,—); `NM_LU_GetStatistics` (SUB,PUB,Query); `NM_LU_Invert` (SUB,PUB,—); `NM_LU_Refine_Solution` (SUB,PUB,—); `NM_LU_Reorder` (SUB,PUB,—); `NM_LU_Residual` (SUB,PUB,—); `NM_LU_Solv` (SUB,PUB,—); `NM_LU_Solv_Multiple` (SUB,PUB,—); `Permutation_Sign` (FN,PRV,—); `Swap_Int` (SUB,PRV,—); `Swap_Rows` (SUB,PRV,—) |
| `NM_LinSolvDirMultifrontal.f90` | `NM_LinSolvDirMultifrontal` | `Elimination_Tree_Node`, `Elimination_Tree`, `Supernode`, `Multifrontal_Factorization`, `Multifrontal_Params` | `NM_Multifrontal_Init_Params` (SUB,PUB,Init); `NM_AMD_Ordering` (SUB,PUB,—); `NM_Nested_Dissection_Ordering` (SUB,PUB,—); `Recursive_Nested_Dissection` (SUB,PRV,—); `NM_ElimTree_Build` (SUB,PUB,Populate); `NM_ElimTree_Destroy` (SUB,PUB,Finalize); `NM_Multifrontal_Symbolic_Factorize` (SUB,PUB,—); `NM_Multifrontal_Numeric_Factorize` (SUB,PUB,—); `NM_Multifrontal_Solv` (SUB,PUB,—); `NM_Multifrontal_Factorize_Destroy` (SUB,PUB,Finalize) |
| `NM_LinSolvIter.f90` | `NM_LinSolvIter` | `Iterative_Solver_Params`, `Iterative_Solver_State` | `NM_LinSolv_Iter_Arnoldi_Process` (SUB,PUB,—); `NM_LinSolv_Iter_BiCGStab_Solv` (SUB,PUB,—); `NM_LinSolv_Iter_BuildKrylovSubspace` (SUB,PUB,Populate); `NM_LinSolv_Iter_CG_Solv` (SUB,PUB,—); `NM_LinSolv_Iter_Check_Conv` (FN,PUB,Validate); `NM_LinSolv_Iter_GMRES_Solv` (SUB,PUB,—); `NM_LinSolv_Iter_Lanczos_Process` (SUB,PUB,—); `NM_LinSolv_Iter_SpMV` (SUB,PUB,—) |
| `NM_LinSolvIterAdv.f90` | `NM_LinSolvIterAdv` | `NM_LinSolv_Iter_Params`, `NM_LinSolv_Iter_State` | `NM_CGS_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—); `NM_MinRes_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—); `NM_QMR_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—); `NM_Richardson_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—); `NM_SymmLQ_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—); `NM_TFQMR_Solv` (SUB,PUB,—); `MatVec_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—) |
| `NM_LinSolvIterBiCGSTAB.f90` | `NM_LinSolvIterBiCGSTAB` | `NM_BiCGSTAB_Params`, `NM_BiCGSTAB_State` | `MatVec_Product` (SUB,PRV,—); `SpMV_proc` (SUB,PRV,—); `NM_Bi_GetResidualHistory` (SUB,PRV,Query); `NM_Bi_RecoverFromBreakdown` (SUB,PRV,—); `NM_BiCGSTAB_GetStatistics` (SUB,PUB,Query); `NM_BiCGSTAB_Solv` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `NM_BiCGSTAB_Solv_Precond` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `Prec_proc` (SUB,PRV,—); `Precond_Solv` (SUB,PRV,—); `Prec_proc` (SUB,PRV,—) |
| `NM_LinSolvIterCG.f90` | `NM_LinSolvIterCG` | `NM_CG_Params`, `NM_CG_State` | `MatVec_Product` (SUB,PRV,—); `SpMV_proc` (SUB,PRV,—); `NM_CG_GetResidualHistory` (SUB,PUB,Query); `NM_CG_GetStatistics` (SUB,PUB,Query); `NM_CG_Solv` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `NM_CG_Solv_CSR` (SUB,PUB,—); `NM_CG_Solv_Precond` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `Precond_proc` (SUB,PRV,—) |
| `NM_LinSolvIterGMRES.f90` | `NM_LinSolvIterGMRES` | `NM_GMRES_Params`, `NM_GMRES_State` | `Apply_Givens` (SUB,PRV,—); `Calc_Givens` (SUB,PRV,—); `i4_to_str` (FN,PRV,—); `MatVec_Product` (SUB,PRV,—); `SpMV_proc` (SUB,PRV,—); `NM_FGMRES_Solv` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `Prec_proc` (SUB,PRV,—); `NM_GMRES_GetKrylovBasis` (SUB,PUB,Query); `NM_GMRES_GetStatistics` (SUB,PUB,Query); `NM_GMRES_Solv` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `NM_GMRES_Solv_Precond` (SUB,PUB,—); `SpMV_proc` (SUB,PRV,—); `Prec_proc` (SUB,PRV,—); `Precond_Solv` (SUB,PRV,—); `Prec_proc` (SUB,PRV,—); `Solv_Upper_Triangular` (SUB,PRV,—) |
| `NM_LinSolvPrec.f90` | `NM_LinSolvPrec` | `Jacobi_Preconditioner`, `SSOR_Preconditioner`, `NM_ILU_Preconditioner`, `Preconditioner_Params` | `NM_LinSolv_Prec_ComparePreconditioners` (SUB,PUB,—); `NM_LinSolv_Prec_GetEffectiveness` (SUB,PUB,Query); `NM_LinSolv_Prec_GetStatistics` (SUB,PUB,Query); `NM_LinSolv_Prec_ILU0_Build` (SUB,PUB,Populate); `NM_LinSolv_Prec_ILU_Apply` (SUB,PUB,—); `NM_LinSolv_Prec_Jacobi_Apply` (SUB,PUB,—); `NM_LinSolv_Prec_Jacobi_Build` (SUB,PUB,Populate); `NM_LinSolv_Prec_SelectOptimal` (SUB,PUB,—); `NM_LinSolv_Prec_SSOR_Apply` (SUB,PUB,—); `NM_LinSolv_Prec_SSOR_Build` (SUB,PUB,Populate) |
| `NM_LinSolvPrecAMG.f90` | `NM_LinSolvPrecAMG` | `NM_AMG_CSR_Type`, `NM_AMG_Level`, `NM_AMG_Hierarchy`, `NM_AMG_Params` | `NM_AMG_Setup` (SUB,PUB,Init); `NM_AMG_Coarsen_RS` (SUB,PUB,—); `NM_AMG_Interpolation` (SUB,PUB,—); `NM_AMG_Galerkin` (SUB,PUB,—); `NM_AMG_V_Cycle` (SUB,PUB,—); `V_Cycle_Recursive` (SUB,PRV,—); `NM_AMG_Smooth` (SUB,PUB,—); `NM_AMG_Solv` (SUB,PUB,—); `NM_AMG_W_Cycle` (SUB,PUB,—); `CSR_Transpose` (SUB,PRV,—); `CSR_MatMat` (SUB,PRV,—); `CSR_SpMV` (SUB,PRV,—); `i4_to_str` (FN,PRV,—); `NM_AMG_GetOperatorComplexity` (FN,PUB,Query); `NM_AMG_GetGridComplexity` (FN,PUB,Query); `NM_AMG_AdaptiveCoarsening` (FN,PUB,Bridge); `NM_AMG_GetStatistics` (SUB,PUB,Query) |
| `NM_LinSolvPrecAMGMultilevel.f90` | `NM_LinSolvPrecAMGMultilevel` | `NM_AMG_Level`, `NM_AMG_Hierarchy`, `NM_AMG_Params`, `NM_AMG_Preconditioner` | `NM_AMG_Init_Params` (SUB,PUB,Init); `NM_AMG_Classical_Coarsening` (SUB,PUB,—); `NM_AMG_Direct_Interpolation` (SUB,PUB,—); `NM_AMG_Aggregation` (SUB,PUB,—); `NM_AMG_Smoothed_Prolongation` (SUB,PUB,—); `NM_AMG_Smoother_Jacobi` (SUB,PUB,—); `NM_AMG_Smoother_GaussSeidel` (SUB,PUB,—); `NM_AMG_Setup` (SUB,PUB,Init); `Transpose_CSR` (SUB,PRV,—); `Galerkin_Projection` (SUB,PRV,—); `NM_AMG_Apply` (SUB,PUB,—); `NM_AMG_Destroy` (SUB,PUB,Finalize) |
| `NM_LinSolvPrecILU.f90` | `NM_LinSolvPrecILU` | `NM_ILU_CSR_Type`, `NM_ILU_Params` | `Allocate_CSR` (SUB,PRV,—); `i4_to_str` (FN,PRV,—); `NM_ILU0_Factorize` (SUB,PUB,—); `NM_ILU0_Solv` (SUB,PUB,—); `NM_ILU_Apply` (SUB,PUB,—); `NM_ILU_Estimate_Fill` (SUB,PUB,Populate); `NM_ILU_GetStatistics` (SUB,PUB,Query); `NM_ILU_Reorder` (SUB,PUB,—); `NM_ILUK_Factorize` (SUB,PUB,—); `NM_ILUT_Factorize` (SUB,PUB,—); `NM_MILU_Factorize` (SUB,PUB,—) |
| `NM_LinSolvPrecSSOR.f90` | `NM_LinSolvPrecSSOR` | `NM_SSOR_Params` | `i4_to_str` (FN,PRV,—); `NM_Block_Jacobi` (SUB,PUB,—); `NM_GaussSeidel_Apply` (SUB,PUB,—); `NM_Jacobi_Apply` (SUB,PUB,—); `NM_SOR_Backward` (SUB,PUB,—); `NM_SOR_Forward` (SUB,PUB,—); `NM_SSOR_Apply` (SUB,PUB,—); `NM_SSOR_GetStatistics` (SUB,PUB,Query); `NM_SSOR_Optimal_Omega` (SUB,PUB,—); `NM_SSOR_Solv` (SUB,PUB,—); `Solv_Dense_System` (SUB,PRV,—) |
| `NM_LinearSolver.f90` | `NM_LinearSolver` | `UF_LinSolParams`, `UF_LinSolResult`, `UF_LinSolContext`, `UF_LinearSolverWorkspace`, `AGMG_Level` | `UF_LS_ResetIterStats` (SUB,PUB,Mutate); `UF_LS_GetIterStats` (SUB,PUB,Query); `UF_LS_InitWorkspace` (SUB,PUB,Init); `UF_LS_FinalizeWorkspace` (SUB,PUB,Finalize); `UF_LS_ConfigureWorkspace` (SUB,PRV,—); `lin_solve` (SUB,PUB,Compute); `select_solver` (FN,PRV,Compute); `lin_solve_direct` (SUB,PUB,Compute); `lin_solve_pcg` (SUB,PRV,Compute); `lin_solve_bicgstab` (SUB,PRV,Compute); `lin_solve_gmres` (SUB,PRV,Compute); `lin_solve_init` (SUB,PUB,Init); `lin_solve_destroy` (SUB,PUB,Finalize); `lin_solve_iterative` (SUB,PUB,Compute); `lin_solve_cg` (SUB,PUB,Compute); `lin_solve_iccg` (SUB,PUB,Compute); `lin_solve_agmg` (SUB,PUB,Compute); `agmg_setup` (SUB,PRV,Init); `agmg_build_coarse_matrix` (SUB,PRV,Populate); `agmg_vcycle` (SUB,PRV,—); `agmg_smooth` (SUB,PRV,—); `agmg_restrict` (SUB,PRV,—); `agmg_prolongate` (SUB,PRV,—); `agmg_matvec` (FN,PRV,—); `agmg_cleanup` (SUB,PRV,Finalize); `lin_solve_sparsepak` (SUB,PRV,Compute); `lin_solve_sparsepak_reuse` (SUB,PRV,Compute) |
| `NM_MemoryPool.f90` | `NM_MemoryPool` | `UF_MemoryPool_t` | `Init` (TBP,PRV,—); `Alloc` (TBP,PRV,—); `AllocDP1D` (TBP,PRV,—); `Free` (TBP,PRV,—); `Reset` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `MemPool_Init` (SUB,PUB,Init); `MemPool_Alloc` (SUB,PUB,—); `MemPool_Free` (SUB,PUB,Finalize); `MemPool_Reset` (SUB,PUB,Mutate); `MemPool_Finalize` (SUB,PUB,Finalize); `MemPool_t_Init` (SUB,PRV,Init); `MemPool_t_Alloc` (SUB,PRV,—); `MemPool_t_AllocDP1D` (SUB,PRV,—); `MemPool_t_Free` (SUB,PRV,Finalize); `MemPool_t_Reset` (SUB,PRV,Mutate); `MemPool_t_Finalize` (SUB,PRV,Finalize); `MatPool_t_Init` (SUB,PRV,Init); `MatPool_t_Alloc` (SUB,PRV,—); `MatPool_t_Free` (SUB,PRV,Finalize); `MatPool_t_Reset` (SUB,PRV,Mutate); `MatPool_t_Finalize` (SUB,PRV,Finalize) |
| `NM_Preconditioner.f90` | `NM_Preconditioner` | `UF_Precond` | `setup` (TBP,PRV,—); `apply` (TBP,PRV,—); `destroy` (TBP,PRV,—); `precond_create` (SUB,PUB,Init); `precond_destroy` (SUB,PUB,Finalize); `precond_destroy_method` (SUB,PRV,Finalize); `precond_setup` (SUB,PUB,Init); `precond_setup_method` (SUB,PRV,Init); `precond_apply` (SUB,PUB,—); `precond_apply_method` (SUB,PRV,—); `setup_jacobi` (SUB,PRV,—); `apply_jacobi` (SUB,PRV,—); `setup_ilu0` (SUB,PRV,—); `setup_ilut` (SUB,PRV,—); `apply_ilu` (SUB,PRV,—); `setup_block_jacobi` (SUB,PRV,—); `block_lu_invert` (SUB,PRV,—); `apply_block_jacobi` (SUB,PRV,—); `setup_block_ilu0` (SUB,PRV,—); `apply_block_ilu` (SUB,PRV,—); `precond_set_block_size` (SUB,PUB,Mutate); `setup_ssor_full` (SUB,PRV,—); `apply_ssor_full` (SUB,PRV,—); `setup_ic0` (SUB,PRV,—); `setup_ick` (SUB,PRV,—); `apply_ic` (SUB,PRV,—); `setup_iluk_wrap` (SUB,PRV,—); `setup_amg` (SUB,PRV,—); `apply_amg` (SUB,PRV,—); `setup_ssor_eisenstat` (SUB,PRV,—); `apply_ssor_eisenstat` (SUB,PRV,—) |
| `NM_Solv.f90` | `NM_Solv` | `NM_LinSolvCtrl`, `NM_NLSolvCtrl`, `NM_Solver_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SetLinearSolver` (TBP,PRV,—); `SetNonlinearSolver` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `NM_Solv_Finalize` (SUB,PRV,Finalize); `NM_Solv_Init` (SUB,PRV,Init); `NM_Solv_SetLin` (SUB,PRV,Mutate); `NM_Solv_SetNonlin` (SUB,PRV,Mutate); `NM_Solv_GetSummary` (SUB,PRV,Query) |
| `NM_SparsePakWrapper.f90` | `NM_SparsePakWrapper` | `UF_SparsePakHandle` | `cleanup` (TBP,PRV,—); `spk_solve_csr` (SUB,PRV,Compute); `spk_symbolic_csr` (SUB,PRV,—); `spk_numeric_csr` (SUB,PRV,—); `spk_solve_factored` (SUB,PRV,Compute); `spk_cleanup` (SUB,PRV,Finalize); `handle_cleanup` (SUB,PRV,Finalize); `spk_reorder_csr` (SUB,PRV,—); `spk_get_reorder_name` (FN,PRV,Query); `build_adjacency` (SUB,PRV,—); `apply_rcm` (SUB,PRV,—); `apply_qmd` (SUB,PRV,—); `apply_nd` (SUB,PRV,—); `compute_envelope` (SUB,PRV,—); `add_to_envelope` (SUB,PRV,—); `envelope_cholesky` (SUB,PRV,—); `envelope_forward_solve_partial` (SUB,PRV,Compute); `envelope_forward_solve` (SUB,PRV,Compute); `envelope_backward_solve` (SUB,PRV,Compute) |
| `NM_SparseSolvInterface.f90` | `NM_SparseSolvInterface` | `UF_LinSolParams`, `UF_LinSolResult`, `SparseSolver_Config`, `SparseSolver_Context` | `NM_SparseSolver_Init` (SUB,PUB,Init); `NM_SparseSolver_Factorize` (SUB,PUB,—); `NM_SparseSolver_Solve` (SUB,PUB,Compute); `NM_SparseSolver_Solve_UF` (SUB,PUB,Compute); `NM_Solve_CG` (SUB,PRV,Compute); `CSR_MatVec` (SUB,PRV,—); `NM_SparseSolver_Finalize` (SUB,PUB,Finalize) |
