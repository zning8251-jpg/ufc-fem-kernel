# `NM_Solv_Dir.f90`

- **Source**: `L2_NM/Solver/NM_Solv_Dir.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Dir`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Dir`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Dir`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_Dir.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `DGETRF` | 19 | `SUBROUTINE DGETRF(M, N, A, LDA, IPIV, INFO) BIND(C, NAME='dgetrf')` |
| SUBROUTINE | `DGETRS` | 27 | `SUBROUTINE DGETRS(TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO) &` |
| SUBROUTINE | `DPOTRF` | 38 | `SUBROUTINE DPOTRF(UPLO, N, A, LDA, INFO) BIND(C, NAME='dpotrf')` |
| SUBROUTINE | `DPOTRS` | 46 | `SUBROUTINE DPOTRS(UPLO, N, NRHS, A, LDA, B, LDB, INFO) &` |
| SUBROUTINE | `Solve_Direct_LU` | 59 | `SUBROUTINE Solve_Direct_LU(A, b, x, stats)` |
| SUBROUTINE | `Solve_Direct_Cholesky` | 122 | `SUBROUTINE Solve_Direct_Cholesky(A, b, x, uplo, stats)` |
| FUNCTION | `Norm_L2` | 188 | `PURE FUNCTION Norm_L2(vec) RESULT(norm_val)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 18–55 | `INTERFACE` |
