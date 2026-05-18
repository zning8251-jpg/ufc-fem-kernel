# `NM_Mtx_Factorization.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_Factorization.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Mtx_Factorization`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_Factorization`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx_Factorization`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_Factorization.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DGETRF` | 23 | `SUBROUTINE DGETRF(M, N, A, LDA, IPIV, INFO) BIND(C, NAME='dgetrf')` |
| SUBROUTINE | `DGETRS` | 32 | `SUBROUTINE DGETRS(TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO) &` |
| SUBROUTINE | `DPOTRF` | 44 | `SUBROUTINE DPOTRF(UPLO, N, A, LDA, INFO) BIND(C, NAME='dpotrf')` |
| SUBROUTINE | `DPOTRS` | 53 | `SUBROUTINE DPOTRS(UPLO, N, NRHS, A, LDA, B, LDB, INFO) &` |
| SUBROUTINE | `DGEQRF` | 63 | `SUBROUTINE DGEQRF(M, N, A, LDA, TAU, WORK, LWORK, INFO) BIND(C, NAME='dgeqrf')` |
| SUBROUTINE | `DORGQR` | 72 | `SUBROUTINE DORGQR(M, N, K, A, LDA, TAU, WORK, LWORK, INFO) BIND(C, NAME='dorgqr')` |
| SUBROUTINE | `NM_LU_Decompose` | 88 | `SUBROUTINE NM_LU_Decompose(A, ipiv, info)` |
| SUBROUTINE | `NM_LU_Solve` | 120 | `SUBROUTINE NM_LU_Solve(A, ipiv, B, X, trans)` |
| SUBROUTINE | `NM_Cholesky_Decompose` | 156 | `SUBROUTINE NM_Cholesky_Decompose(A, uplo, info)` |
| SUBROUTINE | `NM_Cholesky_Solve` | 192 | `SUBROUTINE NM_Cholesky_Solve(A, uplo, B, X)` |
| FUNCTION | `NM_Determinant_LU` | 227 | `FUNCTION NM_Determinant_LU(A, ipiv) RESULT(det)` |
| FUNCTION | `NM_Determinant_Cholesky` | 254 | `FUNCTION NM_Determinant_Cholesky(A, uplo) RESULT(det)` |
| SUBROUTINE | `NM_QR_Decompose` | 284 | `SUBROUTINE NM_QR_Decompose(A, Q, R, info)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 21–80 | `INTERFACE` |
