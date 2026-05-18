# `NM_LinAlg_Dense.f90`

- **Source**: `L2_NM/Matrix/NM_LinAlg_Dense.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_LinAlg_Dense`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_LinAlg_Dense`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_LinAlg_Dense`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_LinAlg_Dense.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cholesky_Factorize` | 56 | `SUBROUTINE Cholesky_Factorize(A, L, status)` |
| SUBROUTINE | `Eigenvalue_Decompose_Symmetric` | 66 | `SUBROUTINE Eigenvalue_Decompose_Symmetric(A, eigenvalues, eigenvectors, status)` |
| FUNCTION | `Inf_Mtx_Norm` | 77 | `FUNCTION Inf_Mtx_Norm(A) RESULT(norm_val)` |
| SUBROUTINE | `Inverse_Mtx_Lower` | 87 | `SUBROUTINE Inverse_Mtx_Lower(L, L_inv, status)` |
| SUBROUTINE | `NM_Condition_Number` | 97 | `SUBROUTINE NM_Condition_Number(A, cond, status)` |
| SUBROUTINE | `NM_GEP_Solv` | 133 | `SUBROUTINE NM_GEP_Solv(A, B, eigenvalues, eigenvectors, status)` |
| SUBROUTINE | `NM_Mtx_Exp` | 178 | `SUBROUTINE NM_Mtx_Exp(A, exp_A, status)` |
| SUBROUTINE | `NM_Mtx_Log` | 232 | `SUBROUTINE NM_Mtx_Log(A, log_A, status)` |
| SUBROUTINE | `NM_Mtx_Power` | 267 | `SUBROUTINE NM_Mtx_Power(A, alpha, A_alpha, status)` |
| SUBROUTINE | `NM_Mtx_Sqrt` | 297 | `SUBROUTINE NM_Mtx_Sqrt(A, sqrt_A, status)` |
| SUBROUTINE | `NM_QR_Givens` | 339 | `SUBROUTINE NM_QR_Givens(A, Q, R, status)` |
| SUBROUTINE | `NM_QR_Householder` | 408 | `SUBROUTINE NM_QR_Householder(A, Q, R, status)` |
| SUBROUTINE | `NM_QR_MGS` | 489 | `SUBROUTINE NM_QR_MGS(A, Q, R, status)` |
| SUBROUTINE | `NM_Rank_Estimate` | 547 | `SUBROUTINE NM_Rank_Estimate(A, rank, tol, status)` |
| SUBROUTINE | `NM_SVD_Decompose` | 578 | `SUBROUTINE NM_SVD_Decompose(A, U, Sigma, VT, status)` |
| SUBROUTINE | `NM_SVD_PseudoInverse` | 637 | `SUBROUTINE NM_SVD_PseudoInverse(A, A_pinv, tol, status)` |
| SUBROUTINE | `Pade_Approximation` | 678 | `SUBROUTINE Pade_Approximation(A, m, Pm, Qm, status)` |
| SUBROUTINE | `Solv_Mtx_Equation` | 690 | `SUBROUTINE Solv_Mtx_Equation(A, B, X, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
