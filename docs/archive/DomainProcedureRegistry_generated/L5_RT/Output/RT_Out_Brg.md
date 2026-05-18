# `RT_Out_Brg.f90`

- **Source**: `L5_RT/Output/RT_Out_Brg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Out_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Out_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Out`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Output/RT_Out_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Output_Brg_FromL3` | 36 | `SUBROUTINE RT_Output_Brg_FromL3(n_field_reqs, n_hist_reqs, desc, status)` |
| SUBROUTINE | `RT_Output_Brg_ToL4` | 61 | `SUBROUTINE RT_Output_Brg_ToL4(ctx, n_nodes, n_elements, status)` |
| SUBROUTINE | `RT_Output_Brg_CollectResults` | 84 | `SUBROUTINE RT_Output_Brg_CollectResults(step_id, incr_id, time, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
