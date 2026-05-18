# `NM_Solv_Core.f90`

- **Source**: `L2_NM/Solver/NM_Solv_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Core`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Solver_Core_Init` | 47 | `SUBROUTINE NM_Solver_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `NM_Solver_Core_Finalize` | 66 | `SUBROUTINE NM_Solver_Core_Finalize(desc, state, ctx, status)` |
| SUBROUTINE | `NM_Solver_CG` | 81 | `SUBROUTINE NM_Solver_CG(desc, state, algo, ctx, matvec, status)` |
| SUBROUTINE | `NM_Solver_Jacobi_Precond` | 131 | `SUBROUTINE NM_Solver_Jacobi_Precond(desc, ctx, status)` |
| SUBROUTINE | `NM_Solver_Direct_Dense` | 152 | `SUBROUTINE NM_Solver_Direct_Dense(n, K_in, b_in, x_out, status)` |
| SUBROUTINE | `NM_Solver_Cholesky` | 219 | `SUBROUTINE NM_Solver_Cholesky(n, K_in, b_in, x_out, status)` |
| SUBROUTINE | `NM_Solver_Direct_Banded` | 276 | `SUBROUTINE NM_Solver_Direct_Banded(desc, state, ctx, status)` |
| SUBROUTINE | `NM_Solver_Newton_Step` | 289 | `SUBROUTINE NM_Solver_Newton_Step(desc, state, ctx, solve_linear, status)` |
| SUBROUTINE | `NM_Solver_Check_Convergence` | 304 | `SUBROUTINE NM_Solver_Check_Convergence(desc, state, algo, ctx, status)` |
| SUBROUTINE | `NM_Solver_Line_Search` | 321 | `SUBROUTINE NM_Solver_Line_Search(desc, state, algo, ctx, &` |
| SUBROUTINE | `NM_Solver_BFGS_Update` | 339 | `SUBROUTINE NM_Solver_BFGS_Update(desc, state, ctx, status)` |
| SUBROUTINE | `NM_Solver_PCG` | 363 | `SUBROUTINE NM_Solver_PCG(desc, state, algo, ctx, matvec, status)` |
| SUBROUTINE | `NM_Solver_Arc_Length_Predict` | 428 | `SUBROUTINE NM_Solver_Arc_Length_Predict(n, du_bar, F_ref, ds, &` |
| SUBROUTINE | `NM_Solver_Arc_Length_Correct` | 460 | `SUBROUTINE NM_Solver_Arc_Length_Correct(n, du_total, du_t, du_bar, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
