# `NM_Solv_SVD.f90`

- **Source**: `L2_NM/Solver/NM_Solv_SVD.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_SVD`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_SVD`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_SVD`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_SVD.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `SVD_Compute_Full` | 38 | `SUBROUTINE SVD_Compute_Full(A, U, Sigma, VT, status, job)` |
| SUBROUTINE | `SVD_Compute_Thin` | 156 | `SUBROUTINE SVD_Compute_Thin(A, U, Sigma, VT, status)` |
| SUBROUTINE | `SVD_Compute_Partial` | 241 | `SUBROUTINE SVD_Compute_Partial(A, k, U, Sigma, VT, status)` |
| FUNCTION | `SVD_Condition_Number` | 286 | `FUNCTION SVD_Condition_Number(Sigma) RESULT(kappa)` |
| FUNCTION | `SVD_Rank` | 311 | `FUNCTION SVD_Rank(Sigma, tol) RESULT(r)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
