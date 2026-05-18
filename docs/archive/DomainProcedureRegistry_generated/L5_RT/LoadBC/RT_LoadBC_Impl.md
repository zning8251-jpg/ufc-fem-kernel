# `RT_LoadBC_Impl.f90`

- **Source**: `L5_RT/LoadBC/RT_LoadBC_Impl.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_LoadBC_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_LoadBC_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_LoadBC_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_LoadBC_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_LoadBC_Init_Impl` | 49 | `SUBROUTINE RT_LoadBC_Init_Impl(desc, state, algo, ctx, analysis_type, nlgeom, &` |
| SUBROUTINE | `RT_LoadBC_Update_Impl` | 96 | `SUBROUTINE RT_LoadBC_Update_Impl(desc, state, algo, ctx, step_time, time_increment, &` |
| SUBROUTINE | `RT_LoadBC_ApplyLoads_Impl` | 125 | `SUBROUTINE RT_LoadBC_ApplyLoads_Impl(desc, state, algo, ctx, f_external, &` |
| SUBROUTINE | `RT_LoadBC_ApplyBCs_Impl` | 169 | `SUBROUTINE RT_LoadBC_ApplyBCs_Impl(desc, state, algo, ctx, bc_dofs, bc_values, &` |
| SUBROUTINE | `RT_LoadBC_ComputeReactions_Impl` | 208 | `SUBROUTINE RT_LoadBC_ComputeReactions_Impl(desc, state, algo, ctx, f_reaction, &` |
| SUBROUTINE | `RT_LoadBC_CheckConvergence_Impl` | 254 | `SUBROUTINE RT_LoadBC_CheckConvergence_Impl(desc, state, algo, ctx, residual_norm, &` |
| SUBROUTINE | `RT_LoadBC_ApplyCutback_Impl` | 294 | `SUBROUTINE RT_LoadBC_ApplyCutback_Impl(desc, state, algo, ctx, force_cutback, &` |
| SUBROUTINE | `RT_LoadBC_Finalize_Impl` | 332 | `SUBROUTINE RT_LoadBC_Finalize_Impl(desc, state, algo, ctx, clear_history, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
