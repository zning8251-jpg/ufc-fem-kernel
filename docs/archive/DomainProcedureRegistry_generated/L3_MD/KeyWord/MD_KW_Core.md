# `MD_KW_Core.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_KW_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_KeyWord_Core_Init` | 37 | `SUBROUTINE MD_KeyWord_Core_Init(desc, state, algo, ctx, status)` |
| SUBROUTINE | `MD_KeyWord_Core_Finalize` | 61 | `SUBROUTINE MD_KeyWord_Core_Finalize(desc, state, ctx, status)` |
| SUBROUTINE | `MD_KeyWord_Register` | 82 | `SUBROUTINE MD_KeyWord_Register(desc, name, n_params, has_data_lines, status)` |
| SUBROUTINE | `MD_KeyWord_Parse_Line` | 113 | `SUBROUTINE MD_KeyWord_Parse_Line(desc, state, line, status)` |
| SUBROUTINE | `MD_KeyWord_Match` | 160 | `SUBROUTINE MD_KeyWord_Match(desc, name, found, status)` |
| SUBROUTINE | `MD_KeyWord_Get_Int_Param` | 185 | `SUBROUTINE MD_KeyWord_Get_Int_Param(line, pos, value, status)` |
| SUBROUTINE | `MD_KeyWord_Get_Real_Param` | 231 | `SUBROUTINE MD_KeyWord_Get_Real_Param(line, pos, value, status)` |
| FUNCTION | `MD_KeyWord_Is_DataLine` | 277 | `FUNCTION MD_KeyWord_Is_DataLine(state) RESULT(is_data)` |
| SUBROUTINE | `MD_KeyWord_Get_Current` | 288 | `SUBROUTINE MD_KeyWord_Get_Current(state, keyword)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
