# `IF_IO_Parser.f90`

- **Source**: `L1_IF/IO/IF_IO_Parser.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_IO_Parser`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Parser`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Parser`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Parser.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_ParserHandle` (lines 33–37)

```fortran
    TYPE, PUBLIC :: IF_ParserHandle
        TYPE(IF_FileHandle) :: file_handle
        CHARACTER(LEN=32) :: format = ""
        INTEGER(i4) :: line_number = 0
    END TYPE IF_ParserHandle
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Parser_ReadKeyword` | 48 | `SUBROUTINE IF_Parser_ReadKeyword(handle, keyword, options, nOptions, eof, status)` |
| SUBROUTINE | `IF_Parser_ParseNodeLine` | 104 | `SUBROUTINE IF_Parser_ParseNodeLine(line, node_id, coords, status)` |
| SUBROUTINE | `IF_Parser_ParseElemLine` | 132 | `SUBROUTINE IF_Parser_ParseElemLine(line, elem_id, node_ids, nNodes, status)` |
| SUBROUTINE | `IF_Parser_SkipComments` | 169 | `SUBROUTINE IF_Parser_SkipComments(line, is_comment)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
