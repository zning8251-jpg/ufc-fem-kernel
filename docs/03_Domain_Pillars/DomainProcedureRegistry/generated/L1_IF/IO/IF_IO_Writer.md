# `IF_IO_Writer.f90`

- **Source**: `L1_IF/IO/IF_IO_Writer.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_Writer`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Writer`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Writer`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Writer.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_WriterHandle` (lines 31–34)

```fortran
    TYPE, PUBLIC :: IF_WriterHandle
        TYPE(IF_FileHandle) :: file_handle
        CHARACTER(LEN=32) :: format = ""
    END TYPE IF_WriterHandle
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Writer_WriteVTK` | 45 | `SUBROUTINE IF_Writer_WriteVTK(handle, coords, connectivity, &` |
| SUBROUTINE | `IF_Writer_WriteHDF5` | 118 | `SUBROUTINE IF_Writer_WriteHDF5(handle, dataset_name, data, status)` |
| SUBROUTINE | `IF_Writer_WriteCSV` | 158 | `SUBROUTINE IF_Writer_WriteCSV(handle, header, data, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
