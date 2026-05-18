# `RT_BC_Impl.f90`

- **Source**: `L5_RT/LoadBC/RT_BC_Impl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_BC_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_BC_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_BC_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_BC_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_BC_Init_Impl` | 26 | `SUBROUTINE RT_BC_Init_Impl(desc, state, algo, ctx, analysis_type, &` |
| SUBROUTINE | `RT_BC_Update_Impl` | 51 | `SUBROUTINE RT_BC_Update_Impl(desc, state, algo, ctx, step_time, &` |
| SUBROUTINE | `RT_BC_ApplyBCs_Impl` | 71 | `SUBROUTINE RT_BC_ApplyBCs_Impl(desc, state, algo, ctx, bc_dofs, &` |
| SUBROUTINE | `RT_BC_ComputeReactions_Impl` | 103 | `SUBROUTINE RT_BC_ComputeReactions_Impl(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_BC_CheckConvergence_Impl` | 143 | `SUBROUTINE RT_BC_CheckConvergence_Impl(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_BC_ApplyCutback_Impl` | 161 | `SUBROUTINE RT_BC_ApplyCutback_Impl(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_BC_Finalize_Impl` | 188 | `SUBROUTINE RT_BC_Finalize_Impl(desc, state, algo, ctx, clear_history, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
