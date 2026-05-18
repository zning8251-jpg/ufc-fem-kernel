## Matrix 域级合同卡（L2_NM）

- **层级**：L2_NM  
- **域名**：Matrix / 矩阵代数  
- **缩写**：`NM_Matrix_*`（稠密/教学型 API）、`NM_Sparse_Matrix_Core`（`NM_CSR_Type` 热路径稀疏）、`NM_Assem_Sparse`（RT 组装三元组→CSR）、`NM_Mtx_Core`（历史合并体，仅保留调用链未迁出时使用）  
- **职责**：稠密/稀疏矩阵类型、分配与初始化；稠密 BLAS/LAPACK 封装（乘、分解、求逆、QR）；CSR SpMV / 稀疏×稠密；**不**承担线性求解器主循环（归口 `NM_Solver_*` / `NM_LinSolv_*`）。

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

### 四型（Desc / State / Algo / Ctx）

| 型 | 内容 | 本域锚点 |
|----|------|----------|
| **Desc** | `DenseMatrix`、`SparseMatrix_CSR`、`SparseMatrix_CSC`（`NM_Matrix_Types`）；全局稀疏热路径 `NM_CSR_Type`（`NM_Sparse_Matrix_Core`）；组装侧 `RT_CSRMatrix`（`NM_Assem_Sparse`） | 形状、存储格式、对称标志 |
| **State** | 稠密 `norm_fro`（可选缓存，只读查询不反向写回）；稀疏 `nnz` / `row_ptr` 完整性 | 热路径保持轻量，避免在 SpMV 内做诊断 I/O |
| **Algo** | `NM_MatMul_Dense`（DGEMM）、`NM_MatMul_Sparse_CSR`、`NM_SpMV_*`、`NM_LU_*`、`NM_Cholesky_*`、`NM_QR_Decompose`（DGEQRF+DORGQR）、`NM_Invert_*` | 纯数值变换，错误以 `info` / `ERROR STOP` 区分 |
| **Ctx** | 本域不引入独立 Ctx TYPE；LAPACK/BLAS 工作区在子程序内局部 `ALLOCATE`（查询最优 `lwork`） | 避免隐式全局矩阵池污染热路径 |

---

### 稀疏表示「单通道」说明（一体约束）

- **新建求解/预条件/桥接代码**：优先 `NM_CSR_Type` + `NM_Sparse_Matrix_Core` 或 `RT_CSRMatrix` 装配链，避免再引入第四种 CSR 变体。  
- **`UF_CSRMatrix` / `NM_Matrix`（`NM_Mtx_Core`）**：兼容与旧 Lanczos 等路径；新功能应通过显式转换或桥接子程序接入，而非在业务层直接混用多种 CSR。  
- **`SparseMatrix_CSR`（`NM_Matrix_Types`）**：与 `TimeInt`、教学级 `Solver` 示例一致；与 `NM_CSR_Type` 索引约定均为 **1-based** 时需通过桥接对齐（见 `L5_RT/Bridge/NM/NM_Matrix_RT_Brg.f90`）。

---

### 核心接口（按功能集）

| 功能集 | 模块 | 说明 |
|--------|------|------|
| 类型与生命周期 | `NM_Matrix_Types` | `NM_Matrix_Allocate` / `Deallocate` / `Init` |
| 稠密乘 | `NM_Matrix_MatMul` | `NM_MatMul_Dense`、`NM_MatMul_Add`（αAB+D → DGEMM） |
| 稀疏乘 | `NM_Matrix_MatMul` | `NM_MatMul_Sparse_CSR`、`NM_SpMV_CSR`、`NM_SpMV_Transpose_CSR` |
| 分解 / 行列式 / QR | `NM_Matrix_Factorization` | LU、Cholesky、`NM_QR_Decompose`（m≥n 经济型 QR） |
| 求逆 | `NM_Matrix_Inversion` | LU / Cholesky / Gauss-Jordan（教学） |
| LAPACK 结构化封装 | `NM_LAPACK_Wrappers` | 与 `ModuleLapack` 绑定的工程级入口 |
| 向量内核 | `NM_Vec_Core` | 供 `NM_Mtx_Core` 等复用 |

---

### 依赖

- **L1**：`IF_Prec_Core`（`wp`/`i4`/`i8` 唯一精度源，**禁止**引用仓库中不存在的 `IF_Precision_Params`）、`IF_Err_*`（`NM_Mtx_Core`）、`IF_Const` / `IF_Math_Util`（`NM_Matrix_Math`）。  
- **外部**：BLAS（`dgemm`）、LAPACK（`dgetrf`、`dgetrs`、`dpotrf`、`dpotrs`、`dgeqrf`、`dorgqr` 等），链接方式与工具链一致。

---

### 热路径与禁止事项

- **热路径**：SpMV、稀疏组装写回、求解器内多次调用的 CSR 乘。  
- **禁止**：在 SpMV/组装内层打开文件、打印、动态错误字符串分配；绕过 `NM_CSR_Type`/`RT_CSRMatrix` 合同直接手写裸 CSR 并跨层传递（除非经桥接登记）。

---

### 实现锚点（与代码同步）

- `NM_Matrix_Types.f90` — `DenseMatrix`、`SparseMatrix_CSR/CSC`、行范围查询带边界检查。  
- `NM_Matrix_MatMul.f90` — 显式 `DGEMM` 接口、转置下内维一致性检查。  
- `NM_Matrix_Factorization.f90` — 类型绑定调用 `A%IsSquare()`；`NM_QR_Decompose(A,Q,R,info)` 不覆盖输入 `A`。  
- `NM_Matrix_Inversion.f90` — Gauss-Jordan 行交换使用缓冲行，避免向量下标自赋值。  
- `NM_Matrix_Core.f90`（磁盘名）— 模块名 **`NM_Mtx_Core`**，历史合并稀疏+稠密工具；与 `NM_Matrix_Types` 并列存在，**非**重复定义 `DenseMatrix`。

---

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L2_MATRIX_xxx`（20400–20499） |
| 严重级 | WARNING（精度损失、接近奇异）/ ERROR（维度不匹配、分配失败） |
| 传播规则 | LAPACK `info` 映射为 UFC `status`；矩阵操作错误通过 `info` 返回值传递 |
| 恢复策略 | 返回错误码，不 `ERROR STOP`（仅极端内层分支保留）；调用方决定中止策略 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| 1 | L2_NM/ExternalLibs | U | BLAS `DGEMM` 等稠密运算 |
| 2 | L2_NM/Solver | S(被消费) | Solver 域消费 CSR 类型与 SpMV |
| 3 | L2_NM/TimeInt | S(被消费) | TimeInt 域消费 `DenseMatrix` |
| 4 | L5_RT/Assembly | S(被消费) | RT 层组装消费 `NM_CSR_Type` / `RT_CSRMatrix` |
| 5 | L5_RT/Bridge/NM | B | `NM_Matrix_RT_Brg.f90` 索引对齐桥接 |
| 6 | L1_IF/Precision | U | 精度定义 `wp`, `i4`, `i8` |
| 7 | L1_IF/Error | U | `IF_Err_*` 错误类型 |
| 8 | L1_IF/Const | U | `IF_Const`, `IF_Math_Util` |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| `USE IF_Prec_Core` 精度统一，禁止 `IF_Precision_Params` | 硬 | 编译 | P0 |
| SpMV/组装内层禁止文件 I/O、动态字符串 | 硬 | Code Review | P0 |
| 新代码优先 `NM_CSR_Type`，避免第四种 CSR 变体 | 硬 | Code Review | P0 |
| 绕过合同直接手写裸 CSR 跨层传递须经桥接登记 | 硬 | Code Review | P0 |
| `NM_Mtx_Core` 仅保留旧调用链未迁出时使用 | 软 | 迁移计划 | P1 |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Contract | 本文 `CONTRACT.md` | Active |
| 2 | Definition/Schema | `NM_Matrix_Types.f90`（DenseMatrix, SparseMatrix_CSR/CSC） | 类型定义 |
| 3 | Desc | `DenseMatrix`, `SparseMatrix_CSR`, `NM_CSR_Type`, `RT_CSRMatrix` | 存储格式、对称标志 |
| 4 | State | `nnz`, `row_ptr` 完整性；稠密 `norm_fro` 缓存 | 轻量状态 |
| 5 | Algo | `NM_MatMul_Dense`, `NM_SpMV_CSR`, `NM_LU_*`, `NM_Cholesky_*`, `NM_QR_Decompose` | 矩阵算子 |
| 6 | Ctx | — | 无独立 Ctx；LAPACK 工作区局部分配 |
| 7 | Kernel | `NM_Matrix_MatMul.f90`, `NM_Matrix_Factorization.f90`, `NM_Matrix_Inversion.f90` | 计算核心 |
| 8 | Bridge | `NM_Matrix_RT_Brg.f90`（L5 桥接） | 索引对齐 |
| 9 | Proc | — | 无 `_Proc` 入口 |
| 10 | Registry | — | 无注册 |
| 11 | Populate | `NM_Matrix_Allocate` / `Init` | 生命周期管理 |
| 12 | Diagnostics | `info` 返回值 | LAPACK 错误码映射 |
| 13 | Test | `L2_NM/Tests/` | Deferred |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 线性代数矩阵运算：稠密/稀疏存储格式、LU/Cholesky/QR 分解、SpMV |
| 逻辑链 | `NM_Matrix_Types`（TYPE 定义） → `NM_Matrix_MatMul` / `NM_Matrix_Factorization`（算子） → `NM_Solver` / `L5_RT` 消费 |
| 计算链 | SpMV、稀疏组装写回为热路径；DGEMM 委托 BLAS；LAPACK 查询最优 `lwork` |
| 数据链 | Desc(冷,格式/维度) → State(nnz/行指针) → Algo 运算中仅读写数值数组，不变更结构 |

---

**版本**：v2.0  
**最后更新**：2026-03-23  
**状态**：与实现同步（精度源 `IF_Prec_Core`；QR 已实现；合同区分稀疏单通道）


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `NM_Assem_Sparse.f90` | `NM_AssemSparse` | `RT_COOEntry`, `RT_TripletList`, `RT_CSRMatrix` | `matvec` (TBP,PRV,—); `RT_Triplet_Init` (SUB,PUB,Init); `RT_Triplet_Add` (SUB,PUB,Mutate); `RT_Triplet_Free` (SUB,PUB,Finalize); `csr_init_from_coo` (SUB,PRV,Init); `RT_CSR_FromTriplet` (SUB,PUB,—); `RT_CSR_Free` (SUB,PUB,Finalize); `RT_CSR_SpMV` (SUB,PUB,—); `RT_CSRMatrix_matvec` (SUB,PRV,—) |
| `NM_LAPACK_Brg.f90` | `NM_LAPACK_Brg` | `NM_LAPACK_EigenSolve_In`, `NM_LAPACK_EigenSolve_Out`, `NM_LAPACK_SVD_In`, `NM_LAPACK_SVD_Out`, `NM_LAPACK_LUFactor_In`, `NM_LAPACK_LUFactor_Out`, `NM_LAPACK_Inverse_In`, `NM_LAPACK_Inverse_Out`, `NM_LAPACK_LinearSolve_In`, `NM_LAPACK_LinearSolve_Out` | `NM_LAPACK_EigenSolve` (SUB,PUB,—); `NM_LAPACK_Inverse` (SUB,PUB,—); `NM_LAPACK_LinearSolve` (SUB,PUB,—); `NM_LAPACK_LUFactor` (SUB,PUB,—); `NM_LAPACK_SVD` (SUB,PUB,—) |
| `NM_LinAlg_Dense.f90` | `NM_LinAlg_Dense` | — | `Cholesky_Factorize` (SUB,PRV,—); `Eigenvalue_Decompose_Symmetric` (SUB,PRV,—); `Inf_Mtx_Norm` (FN,PRV,—); `Inverse_Mtx_Lower` (SUB,PRV,—); `NM_Condition_Number` (SUB,PUB,—); `NM_GEP_Solv` (SUB,PUB,—); `NM_Mtx_Exp` (SUB,PUB,—); `NM_Mtx_Log` (SUB,PUB,IO); `NM_Mtx_Power` (SUB,PUB,—); `NM_Mtx_Sqrt` (SUB,PUB,—); `NM_QR_Givens` (SUB,PUB,—); `NM_QR_Householder` (SUB,PUB,—); `NM_QR_MGS` (SUB,PUB,—); `NM_Rank_Estimate` (SUB,PUB,—); `NM_SVD_Decompose` (SUB,PUB,—); `NM_SVD_PseudoInverse` (SUB,PUB,—); `Pade_Approximation` (SUB,PRV,—); `Solv_Mtx_Equation` (SUB,PRV,—) |
| `NM_LinAlg_Domain.f90` | `NM_LinAlg_Domain` | `NM_SparseConfig`, `NM_LinAlg_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SetFormat` (TBP,PRV,—); `MatVec` (TBP,PRV,—); `GetSummary` (TBP,PRV,—); `NM_Mtx_LinAlg_Finalize` (SUB,PRV,Finalize); `NM_Mtx_LinAlg_Init` (SUB,PRV,Init); `NM_Mtx_LinAlg_SetFormat` (SUB,PRV,Mutate); `NM_LinAlg_Domain_MatVec` (SUB,PRV,—); `NM_Mtx_LinAlg_GetSummary` (SUB,PRV,Query) |
| `NM_Mtx.f90` | `NM_Mtx_Core` | `NM_Matrix_Index`, `NM_Matrix_Values`, `NM_Matrix`, `UF_COOEntry`, `UF_CSRMatrix` | `init` (TBP,PRV,—); `destroy` (TBP,PRV,—); `get` (TBP,PRV,—); `set` (TBP,PRV,—); `add` (TBP,PRV,—); `matvec` (TBP,PRV,—); `matvec_trans` (TBP,PRV,—); `get_row_nnz` (TBP,PRV,—); `print_info` (TBP,PRV,—); `NM_Matrix_Init` (SUB,PUB,Init); `NM_Matrix_AddEntry` (SUB,PUB,Mutate); `NM_Matrix_Finalize` (SUB,PUB,Finalize); `NM_Matrix_Destroy` (SUB,PUB,Finalize); `NM_Matrix_MatVec` (SUB,PUB,—); `NM_Matrix_GetValue` (SUB,PUB,Query); `NM_Matrix_SetValue` (SUB,PUB,Mutate); `NM_Matrix_IsValid` (FN,PUB,Query); `NM_Mtx_Add` (SUB,PUB,Mutate); `NM_Mtx_Subtract` (SUB,PUB,—); `NM_Mtx_Det` (FN,PUB,—); `NM_Mtx_Diag` (SUB,PUB,—); `NM_Mtx_Eye` (SUB,PUB,—); `NM_Mtx_Gemm` (SUB,PUB,—); `NM_Mtx_Gemv` (SUB,PUB,—); `NM_Mtx_Ger` (SUB,PUB,—); `NM_Mtx_Inv` (SUB,PUB,—); `NM_Mtx_Norm1` (FN,PUB,—); `NM_Mtx_NormF` (FN,PUB,—); `NM_Mtx_NormInf` (FN,PUB,—); `NM_Mtx_Symm` (SUB,PUB,—); `NM_Mtx_Symv` (SUB,PUB,—); `NM_Mtx_Trace` (FN,PUB,—); `NM_Mtx_Transpose` (SUB,PUB,—); `NM_Mtx_Trmm` (SUB,PUB,—); `NM_Mtx_Trmv` (SUB,PUB,—); `csr_create` (SUB,PUB,Init); `csr_destroy` (SUB,PUB,Finalize); `csr_destroy_method` (SUB,PRV,Finalize); `csr_init_from_coo` (SUB,PUB,Init); `csr_init` (SUB,PRV,Init); `csr_get_value` (FN,PUB,Query); `csr_get_value_method` (FN,PRV,Query); `csr_set_value` (SUB,PUB,Mutate); `csr_set_value_method` (SUB,PRV,Mutate); `csr_add_value` (SUB,PUB,Mutate); `csr_add_value_method` (SUB,PRV,Mutate); `csr_clear` (SUB,PUB,Mutate); `csr_zero_matrix` (SUB,PUB,—); `csr_deallocate` (SUB,PUB,Finalize); `csr_scale` (SUB,PUB,—); `csr_copy` (SUB,PUB,—); `csr_add_scaled` (SUB,PUB,Mutate); `csr_axpy` (SUB,PUB,—); `csr_get_diagonal` (SUB,PUB,Query); `csr_set_diagonal` (SUB,PUB,Mutate); `csr_matvec` (SUB,PRV,—); `csr_matvec_trans` (SUB,PRV,—); `csr_get_row_nnz` (FN,PRV,Query); `csr_info` (SUB,PUB,—); `csr_info_method` (SUB,PRV,—); `csr_print` (SUB,PUB,IO); `csr_matvec_direct` (SUB,PUB,—); `sparse_lsolve` (SUB,PUB,—); `sparse_lsolve_msr` (SUB,PUB,—); `sparse_matvec` (SUB,PUB,—); `sparse_matvec_trans` (SUB,PUB,—); `sparse_usolve` (SUB,PUB,—); `sparse_usolve_msr` (SUB,PUB,—); `vec_add` (SUB,PUB,Mutate); `vec_axpy` (SUB,PUB,—); `vec_copy` (SUB,PUB,—); `vec_dot` (FN,PUB,—); `vec_norm2` (FN,PUB,—); `vec_scale` (SUB,PUB,—); `vec_sub` (SUB,PUB,—); `vec_zero` (SUB,PUB,—); `assembly_map_init` (SUB,PRV,Init); `assembly_map_destroy` (SUB,PRV,Finalize); `csr_build_assembly_map` (SUB,PUB,Populate); `csr_get_position` (FN,PUB,Query); `csr_fast_assemble_element` (SUB,PUB,—); `csr_batch_assemble` (SUB,PUB,—); `csr_analyze_bandwidth` (SUB,PUB,—); `csr_reorder_rcm` (SUB,PUB,—); `add_neighbors_sorted` (SUB,PRV,—); `sort_by_key` (SUB,PRV,—) |
| `NM_Mtx_Def.f90` | — | — | — |
| `NM_Mtx_Factorization.f90` | `NM_Mtx_Factorization` | — | `DGETRF` (SUB,PRV,—); `DGETRS` (SUB,PRV,—); `DPOTRF` (SUB,PRV,—); `DPOTRS` (SUB,PRV,—); `DGEQRF` (SUB,PRV,—); `DORGQR` (SUB,PRV,—); `NM_LU_Decompose` (SUB,PUB,—); `NM_LU_Solve` (SUB,PUB,Compute); `NM_Cholesky_Decompose` (SUB,PUB,—); `NM_Cholesky_Solve` (SUB,PUB,Compute); `NM_Determinant_LU` (FN,PUB,—); `NM_Determinant_Cholesky` (FN,PUB,—); `NM_QR_Decompose` (SUB,PUB,—) |
| `NM_Mtx_Inversion.f90` | `NM_Mtx_Inversion` | — | `NM_Invert_LU` (SUB,PUB,—); `NM_Invert_Cholesky` (SUB,PUB,—); `NM_Invert_GaussJordan` (SUB,PUB,—) |
| `NM_Mtx_MatMul.f90` | `NM_Mtx_MatMul` | — | `DGEMM` (SUB,PRV,—); `NM_MatMul_Dense` (SUB,PUB,—); `NM_MatMul_Add` (SUB,PUB,Mutate); `NM_MatMul_Sparse_CSR` (SUB,PUB,—); `NM_SpMV_CSR` (SUB,PUB,—); `NM_SpMV_Transpose_CSR` (SUB,PUB,—) |
| `NM_Mtx_Math.f90` | `NM_Mtx_Math` | — | `NM_Math_Mtx_Cholesky_Decomposition` (SUB,PUB,—); `NM_Math_Mtx_LU_Decomposition` (SUB,PUB,—); `NM_Math_Mtx_QR_Decomposition` (SUB,PUB,—); `NM_Math_Mtx_Eigenvalues` (SUB,PUB,—); `NM_Math_Mtx_Eigenvalues_3x3` (SUB,PRV,—); `NM_Math_Compute_Eigenvectors_3x3` (SUB,PRV,Compute); `NM_Math_Mtx_ConditionNumber` (SUB,PUB,—) |
| `NM_SparseMtx.f90` | `NM_SparseMtx` | `NM_CSR_Type`, `NM_COO_Type` | `BFS_Levels` (SUB,PRV,—); `Mark_Distance2_Colors` (SUB,PRV,—); `NM_AMD_Ordering` (SUB,PUB,—); `NM_COO_to_CSR` (SUB,PUB,—); `NM_CSC_to_CSR` (SUB,PUB,—); `NM_CSR_GetStatistics` (SUB,PUB,Query); `NM_CSR_MatMult_Optimized` (SUB,PUB,—); `NM_CSR_MatVec_Optimized` (SUB,PUB,—); `NM_CSR_MatMult` (SUB,PRV,—); `NM_CSR_OptimizeStorage` (SUB,PUB,—); `NM_CSR_to_COO` (SUB,PUB,—); `NM_CSR_to_CSC` (SUB,PUB,—); `NM_Graph_Coloring` (SUB,PUB,—); `NM_Mtx_Bandwidth` (SUB,PUB,—); `NM_Mtx_Profile` (SUB,PUB,—); `NM_ND_Ordering` (SUB,PUB,—); `NM_Permute_Mtx` (SUB,PUB,—); `NM_RCM_Ordering` (SUB,PUB,—); `NM_Transpose_CSR` (SUB,PUB,—); `Sort_CSR_Rows` (SUB,PRV,—); `Sort_Levels_By_Degree` (SUB,PRV,—); `NM_COO_Init` (SUB,PUB,Init); `NM_COO_AddEntry` (SUB,PUB,Mutate); `NM_COO_AddElementMatrix` (SUB,PUB,Mutate); `NM_COO_Finalize` (SUB,PUB,Finalize); `NM_CSR_AssembleFromElements` (SUB,PUB,—) |
| `NM_Vec.f90` | `NM_Vec` | `Vec_Add_Arg`, `Vec_Axpy_Arg`, `Vec_Copy_Arg`, `Vec_Div_Arg`, `Vec_Fill_Arg`, `Vec_Scal_Arg`, `Vec_Sub_Arg`, `Vec_Swap_Arg`, `Vec_Normalize_Arg`, `Vec_Invert_Arg`, `Vec_Zero_Arg`, `Vec_Linspace_Arg`, `Vec_Mul_Arg` | `NM_Vec_Add_Proc` (SUB,PRV,Mutate); `NM_Vec_Axpy_Proc` (SUB,PRV,—); `NM_Vec_Copy_Proc` (SUB,PRV,—); `NM_Vec_Div_Proc` (SUB,PRV,—); `NM_Vec_Fill_Proc` (SUB,PRV,Populate); `NM_Vec_Scal_Proc` (SUB,PRV,—); `NM_Vec_Sub_Proc` (SUB,PRV,—); `NM_Vec_Swap_Proc` (SUB,PRV,—); `NM_Vec_Normalize_Proc` (SUB,PRV,—); `NM_Vec_Invert_Proc` (SUB,PRV,—); `NM_Vec_Zero_Proc` (SUB,PRV,—); `NM_Vec_Linspace_Proc` (SUB,PRV,—); `NM_Vec_Mul_Proc` (SUB,PRV,—); `NM_Vec_Add` (SUB,PRV,Mutate); `NM_Vec_Asum` (FN,PRV,—); `NM_Vec_Axpy` (SUB,PRV,—); `NM_Vec_Copy` (SUB,PRV,—); `NM_Vec_Div` (SUB,PRV,—); `NM_Vec_Dot` (FN,PRV,—); `NM_Vec_CrossProduct` (FN,PRV,—); `NM_Vec_Diff` (FN,PRV,—); `NM_Vec_Fill` (SUB,PRV,Populate); `NM_Vec_Iamax` (FN,PRV,—); `NM_Vec_Invert` (SUB,PRV,—); `NM_Vec_Linspace` (SUB,PRV,—); `NM_Vec_Max` (FN,PRV,—); `NM_Vec_Mean` (FN,PRV,—); `NM_Vec_Min` (FN,PRV,—); `NM_Vec_Mul` (SUB,PRV,—); `NM_Vec_Normalize` (SUB,PRV,—); `NM_Vec_NormInf` (FN,PRV,—); `NM_Vec_Nrm2` (FN,PRV,—); `NM_Vec_Scal` (SUB,PRV,—); `NM_Vec_Sub` (SUB,PRV,—); `NM_Vec_Sum` (FN,PRV,—); `NM_Vec_Swap` (SUB,PRV,—); `NM_Vec_Zero` (SUB,PRV,—); `NM_Vec_Variance` (FN,PRV,—) |
