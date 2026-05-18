# `NM_Cpl_Staggered.f90`

- **Source**: `L2_NM/Solver/Coupling/NM_Cpl_Staggered.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Cpl_Staggered`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Cpl_Staggered`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Cpl_Staggered`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Coupling/NM_Cpl_Staggered.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Coupling_Stag_Init` | 26 | `SUBROUTINE NM_Coupling_Stag_Init(coupling_type, staggered_type, n_max_iter, tol, stag_ctx, status)` |
| SUBROUTINE | `NM_Coupling_Stag_Standard` | 40 | `SUBROUTINE NM_Coupling_Stag_Standard(params, t_start, t_end, dt_init, &` |
| SUBROUTINE | `NM_Coupling_Stag_Improved` | 61 | `SUBROUTINE NM_Coupling_Stag_Improved(params, t_start, t_end, dt_init, &` |
| SUBROUTINE | `NM_Coupling_Stag_PredictCorrect` | 76 | `SUBROUTINE NM_Coupling_Stag_PredictCorrect(params, t_start, t_end, dt_init, &` |
| SUBROUTINE | `NM_Coupling_Stag_Subcycling` | 94 | `SUBROUTINE NM_Coupling_Stag_Subcycling(params, t_start, t_end, dt_coarse, dt_fine, &` |
| SUBROUTINE | `NM_Coupling_Stag_DataTransfer` | 111 | `SUBROUTINE NM_Coupling_Stag_DataTransfer(state_from, state_to, interface, status)` |
| SUBROUTINE | `NM_Coupling_Stag_CheckConv` | 127 | `SUBROUTINE NM_Coupling_Stag_CheckConv(state_old, state_new, params, tol, converged, status)` |
| SUBROUTINE | `NM_Coupling_Stag_Cleanup` | 143 | `SUBROUTINE NM_Coupling_Stag_Cleanup(stag_ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
