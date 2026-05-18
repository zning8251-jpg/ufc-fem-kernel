# 推演卡综合：L2_NM — 数值方法层（非 Solver 域）

> 推演引擎 v1.0 | 2026-04-26 | 4 域（Solver 见独立卡）
>
> L2 特征：计算核心层，Compute 密集，服务于 L4/L5 的热路径调用。

---

## Base

**域**：L2_NM / Base | **域类型**：工具域 | **四型**：Desc(N) State(N) Algo(N) Ctx(N)

**核心意图**：3x3 张量运算（行列式/逆/偏差/外积）、Voigt 记法转换、范数、BVH

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `NM_Base_Core_Init` | Config | Init | O(1) |
| `NM_Base_Core_Finalize` | Config | Init(Fin) | O(1) |
| `NM_Base_Inv3x3` | (any) | Compute | O(1) |
| `NM_Base_Det3x3` | (any) | Compute | O(1) |
| `NM_Base_Voigt_To_Tensor` | (any) | Compute(Transform) | O(9) |
| `NM_Base_Tensor_To_Voigt` | (any) | Compute(Transform) | O(9) |
| `NM_Base_Outer_Product` | (any) | Compute | O(9) |
| `NM_Base_Dyadic` | (any) | Compute | O(9) |
| `NM_Base_Dev3x3` | (any) | Compute | O(9) |
| `NM_Base_Cross3` | (any) | Compute | O(1) |
| `NM_Base_Trace3x3` | (any) | Compute | O(1) |

**特征**：纯函数式工具，无状态，无 Phase 偏好，可在任意 Phase 调用。

---

## Matrix

**域**：L2_NM / Matrix | **域类型**：数据域 | **四型**：Desc(Y) State(N) Algo(N) Ctx(Y)

**核心意图**：CSR 稀疏矩阵生命周期、SpMV、BC 施加、对角线提取

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `NM_Matrix_Core_Init` | Config | Init | O(1) |
| `NM_Matrix_Core_Finalize` | Config | Init(Fin) | O(1) |
| `NM_Matrix_CSR_Create` | Config | Init | O(nnz) |
| `NM_Matrix_CSR_Insert` | Config | Access(Add) | O(1) |
| `NM_Matrix_CSR_SpMV` | Iteration | Compute | O(nnz) |
| `NM_Matrix_CSR_Apply_BC` | Iteration | Assemble(Apply) | O(n_bc) |
| `NM_Matrix_CSR_Get_Diag` | (any) | Access(Get) | O(n) |
| `NM_Matrix_CSR_NNZ` | (any) | Access(Get) | O(1) |

**关联模块**：`NM_Mtx_*`（稠密矩阵工具）、`NM_LinAlg_*`（线性代数）、`NM_AssemSparse`（装配三元组→CSR）、`NM_LAPACK_Brg`。

---

## TimeInt

**域**：L2_NM / TimeInt | **域类型**：计算域 | **四型**：Desc(Y) State(Y) Algo(Y) Ctx(Y)

**核心意图**：动力学时间积分——Newmark、HHT-α、中心差分、稳定 dt 估计

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `NM_TimeInt_Core_Init` | Config | Init | O(n) |
| `NM_TimeInt_Core_Finalize` | Config | Init(Fin) | O(1) |
| `NM_TimeInt_Newmark_Predict` | Increment | Compute | O(n) |
| `NM_TimeInt_Newmark_Correct` | Increment | Compute | O(n) |
| `NM_TimeInt_Central_Diff` | Increment | Compute | O(n) |
| `NM_TimeInt_HHT_Alpha` | Increment | Compute | O(n) |
| `NM_TimeInt_Compute_Stable_DT` | Config | Compute | O(n) |

**关联模块**：`NM_TimeIntScheme`（方案定义）、`NM_TimeIntAdapt`（自适应）、`NM_TSEventDet`（事件检测）。

---

## ExternalLibs

**域**：L2_NM / ExternalLibs | **域类型**：桥接域 | **四型**：Desc(N) State(N) Algo(N) Ctx(N)

**核心意图**：统一封装外部数学库（BLAS/LAPACK/SparsePak/AGMG/HSL）

| 过程名 | Phase | Verb | 复杂度 |
|--------|-------|------|--------|
| `NM_ExternalLibs_Core_Init` | Config | Init | O(1) |
| `NM_ExternalLibs_Core_Finalize` | Config | Init(Fin) | O(1) |
| `NM_Ext_DGEMV` | (any) | Compute | O(n^2) |
| `NM_Ext_DGEMM` | (any) | Compute | O(n^3) |
| `NM_Ext_DGESV` | (any) | Compute(Solve) | O(n^3) |
| `NM_Ext_DPOTRF` | (any) | Compute(Build) | O(n^3) |
| `NM_Ext_DNRM2` | (any) | Compute | O(n) |

**特征**：薄封装层，无自有状态。Phase 中立——被任何层在任何 Phase 调用。
