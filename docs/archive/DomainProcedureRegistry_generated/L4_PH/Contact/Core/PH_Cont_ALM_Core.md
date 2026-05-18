# `PH_Cont_ALM_Core.f90`

- **Source**: `L4_PH/Contact/Core/PH_Cont_ALM_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Cont_ALM_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_ALM_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_ALM`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Contact/Core`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Core/PH_Cont_ALM_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Cont_ALM_Update_Multiplier` | 37 | `SUBROUTINE PH_Cont_ALM_Update_Multiplier(lambda, gap_n, penalty, &` |
| SUBROUTINE | `PH_Cont_ALM_Compute_Force` | 73 | `SUBROUTINE PH_Cont_ALM_Compute_Force(lambda, gap_n, penalty, f_n, ierr)` |
| SUBROUTINE | `PH_Cont_ALM_Compute_Stiffness` | 106 | `SUBROUTINE PH_Cont_ALM_Compute_Stiffness(gap_n, penalty, k_n, ierr)` |
| SUBROUTINE | `PH_Cont_ALM_Check_Convergence` | 128 | `SUBROUTINE PH_Cont_ALM_Check_Convergence(gap_n, tol, converged, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
