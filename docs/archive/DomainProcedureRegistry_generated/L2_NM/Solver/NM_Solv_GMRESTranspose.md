# `NM_Solv_GMRESTranspose.f90`

- **Source**: `L2_NM/Solver/NM_Solv_GMRESTranspose.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_GMRESTranspose`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_GMRESTranspose`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_GMRESTranspose`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_GMRESTranspose.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_GMRES_Solve_Transpose` | 37 | `SUBROUTINE NM_GMRES_Solve_Transpose(K_csr, rhs_lambda, lambda, params, state, status)` |
| SUBROUTINE | `NM_CG_Solve_Transpose` | 118 | `SUBROUTINE NM_CG_Solve_Transpose(K_csr, rhs_lambda, lambda, tol, max_iter, state, status)` |
| SUBROUTINE | `NM_Adjoint_Solve` | 229 | `SUBROUTINE NM_Adjoint_Solve(K_csr, objective_gradient, adjoint_variable, &` |
| SUBROUTINE | `SparseMatrix_Vector_Multiply` | 298 | `SUBROUTINE SparseMatrix_Vector_Multiply(A_csr, x, y, status)` |
| SUBROUTINE | `Adjoint_Solve_Placeholder` | 337 | `SUBROUTINE Adjoint_Solve_Placeholder(KT_csr, rhs, lambda, params, state, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
