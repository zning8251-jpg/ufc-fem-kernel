# `RT_Load_Impl.f90`

- **Source**: `L5_RT/LoadBC/RT_Load_Impl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Load_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Load_Impl`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Load_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_Load_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Load_Init_Impl` | 25 | `SUBROUTINE RT_Load_Init_Impl(desc, state, algo, ctx, analysis_type, &` |
| SUBROUTINE | `RT_Load_Update_Impl` | 52 | `SUBROUTINE RT_Load_Update_Impl(desc, state, algo, ctx, step_time, &` |
| SUBROUTINE | `RT_Load_ApplyLoads_Impl` | 72 | `SUBROUTINE RT_Load_ApplyLoads_Impl(desc, state, algo, ctx, f_external, &` |
| SUBROUTINE | `RT_Load_CheckConvergence_Impl` | 91 | `SUBROUTINE RT_Load_CheckConvergence_Impl(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_Load_ApplyCutback_Impl` | 109 | `SUBROUTINE RT_Load_ApplyCutback_Impl(desc, state, algo, ctx, force_cutback, &` |
| SUBROUTINE | `RT_Load_Finalize_Impl` | 135 | `SUBROUTINE RT_Load_Finalize_Impl(desc, state, algo, ctx, clear_history, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
