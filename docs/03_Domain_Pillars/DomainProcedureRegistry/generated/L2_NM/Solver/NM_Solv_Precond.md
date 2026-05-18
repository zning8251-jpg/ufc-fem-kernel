# `NM_Solv_Precond.f90`

- **Source**: `L2_NM/Solver/NM_Solv_Precond.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Precond`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Precond`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Precond`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Solv_Precond.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Precond_Free_CSR` | 26 | `SUBROUTINE Precond_Free_CSR(precond)` |
| SUBROUTINE | `CSR_ILU0_Factor` | 36 | `SUBROUTINE CSR_ILU0_Factor(n, row_ptr, col_idx, alu)` |
| FUNCTION | `CSR_Find_Pattern` | 69 | `PURE FUNCTION CSR_Find_Pattern(n, row_ptr, col_idx, i, j) RESULT(p)` |
| SUBROUTINE | `Construct_Jacobi_Precond` | 90 | `SUBROUTINE Construct_Jacobi_Precond(A_csr, precond)` |
| SUBROUTINE | `Construct_ILU0_Precond` | 131 | `SUBROUTINE Construct_ILU0_Precond(A_csr, precond)` |
| SUBROUTINE | `Construct_SSOR_Precond` | 175 | `SUBROUTINE Construct_SSOR_Precond(A_csr, precond, omega)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
