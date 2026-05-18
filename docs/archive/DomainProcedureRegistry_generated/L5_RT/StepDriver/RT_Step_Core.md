# `RT_Step_Core.f90`

- **Source**: `L5_RT/StepDriver/RT_Step_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_Step_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Step_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Step`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_Step_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_StepDriver_Core_Init` | 66 | `SUBROUTINE RT_StepDriver_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `RT_StepDriver_Core_Finalize` | 104 | `SUBROUTINE RT_StepDriver_Core_Finalize(state, ctx, status)` |
| SUBROUTINE | `RT_StepDriver_Begin_Step` | 122 | `SUBROUTINE RT_StepDriver_Begin_Step(desc, state, ctx, status)` |
| SUBROUTINE | `RT_StepDriver_End_Step` | 150 | `SUBROUTINE RT_StepDriver_End_Step(state, status)` |
| SUBROUTINE | `RT_StepDriver_Begin_Increment` | 163 | `SUBROUTINE RT_StepDriver_Begin_Increment(desc, state, ctx, status)` |
| SUBROUTINE | `RT_StepDriver_End_Increment` | 211 | `SUBROUTINE RT_StepDriver_End_Increment(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_StepDriver_Advance_Time` | 251 | `SUBROUTINE RT_StepDriver_Advance_Time(state, ctx, status)` |
| SUBROUTINE | `RT_StepDriver_Cutback` | 264 | `SUBROUTINE RT_StepDriver_Cutback(desc, state, algo, ctx, status)` |
| FUNCTION | `RT_StepDriver_Check_Step_Complete` | 299 | `FUNCTION RT_StepDriver_Check_Step_Complete(desc, state) RESULT(done)` |
| FUNCTION | `RT_StepDriver_Get_Current_Time` | 308 | `FUNCTION RT_StepDriver_Get_Current_Time(state) RESULT(t)` |
| FUNCTION | `RT_StepDriver_Get_DT` | 314 | `FUNCTION RT_StepDriver_Get_DT(state) RESULT(dt)` |
| SUBROUTINE | `RT_StepDriver_NR_Increment` | 326 | `SUBROUTINE RT_StepDriver_NR_Increment(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_StepDriver_Run_Step` | 409 | `SUBROUTINE RT_StepDriver_Run_Step(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_StepDriver_NR_Increment_WithArg` | 474 | `SUBROUTINE RT_StepDriver_NR_Increment_WithArg(desc, state, algo, ctx, arg, &` |
| SUBROUTINE | `RT_StepDriver_Run_Step_WithArg` | 497 | `SUBROUTINE RT_StepDriver_Run_Step_WithArg(desc, state, algo, ctx, arg, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
