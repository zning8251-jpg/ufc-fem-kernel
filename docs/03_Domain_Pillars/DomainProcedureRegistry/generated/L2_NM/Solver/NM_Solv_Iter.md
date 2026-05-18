# `NM_Solv_Iter.f90`

- **Source**: `L2_NM/Solver/NM_Solv_Iter.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Iter`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Iter`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Iter`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_Iter.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `GMRES_Solve` | 32 | `SUBROUTINE GMRES_Solve(solver, stats, arg, precond)` |
| SUBROUTINE | `CG_Solve` | 179 | `SUBROUTINE CG_Solve(solver, stats, arg, precond)` |
| SUBROUTINE | `BiCGSTAB_Solve` | 273 | `SUBROUTINE BiCGSTAB_Solve(solver, stats, arg, precond)` |
| FUNCTION | `Check_Convergence` | 377 | `FUNCTION Check_Convergence(residual, tol, norm_type) RESULT(converged)` |
| SUBROUTINE | `Compute_Givens` | 396 | `SUBROUTINE Compute_Givens(a, b, cs, sn)` |
| SUBROUTINE | `Solve_Upper_Triangular` | 411 | `SUBROUTINE Solve_Upper_Triangular(U, b, x)` |
| FUNCTION | `Norm_L2` | 431 | `PURE FUNCTION Norm_L2(vec) RESULT(norm_val)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
