# `MD_WB_Mgr.f90`

- **Source**: `L3_MD/WriteBack/MD_WB_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_WB_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_WB_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_WB`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/WriteBack/MD_WB_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init_WriteBack_WhiteList` | 49 | `SUBROUTINE Init_WriteBack_WhiteList(status)` |
| SUBROUTINE | `Register_WriteBack_Field` | 131 | `SUBROUTINE Register_WriteBack_Field(domain_name, field_name, is_active, &` |
| FUNCTION | `Is_WriteBack_Allowed` | 157 | `FUNCTION Is_WriteBack_Allowed(domain_name, field_name) RESULT(is_allowed)` |
| SUBROUTINE | `Finalize_WriteBack_WhiteList` | 171 | `SUBROUTINE Finalize_WriteBack_WhiteList()` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
