# `MD_WB_Core.f90`

- **Source**: `L3_MD/WriteBack/MD_WB_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_WB_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_WB_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_WB`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/WriteBack/MD_WB_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_WriteBack_Core_Init` | 38 | `SUBROUTINE MD_WriteBack_Core_Init(desc, state, ctx, status)` |
| SUBROUTINE | `MD_WriteBack_Core_Finalize` | 55 | `SUBROUTINE MD_WriteBack_Core_Finalize(desc, state, ctx, status)` |
| SUBROUTINE | `MD_WriteBack_Register_Map` | 72 | `SUBROUTINE MD_WriteBack_Register_Map(desc, source_id, target_id, &` |
| SUBROUTINE | `MD_WriteBack_Get_Map` | 99 | `SUBROUTINE MD_WriteBack_Get_Map(desc, idx, map, status)` |
| FUNCTION | `MD_WriteBack_Get_Count` | 115 | `FUNCTION MD_WriteBack_Get_Count(desc) RESULT(n)` |
| SUBROUTINE | `MD_WriteBack_Execute` | 121 | `SUBROUTINE MD_WriteBack_Execute(desc, state, ctx, step_idx, incr_idx, status)` |
| SUBROUTINE | `MD_WriteBack_Validate` | 153 | `SUBROUTINE MD_WriteBack_Validate(desc, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
