# `RT_WB_Brg.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_WB_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Brg`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_WriteBack_Brg_FromL5` | 28 | `SUBROUTINE RT_WriteBack_Brg_FromL5(n_nodes, n_elements, desc, progress, status)` |
| SUBROUTINE | `RT_WriteBack_Brg_ToL4` | 59 | `SUBROUTINE RT_WriteBack_Brg_ToL4(target_type, n_items, ctx, status)` |
| SUBROUTINE | `RT_WriteBack_Brg_ToL3` | 82 | `SUBROUTINE RT_WriteBack_Brg_ToL3(step_id, incr_id, progress, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
