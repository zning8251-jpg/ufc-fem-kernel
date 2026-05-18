# `IF_IO_Mgr.f90`

- **Source**: `L1_IF/IO/IF_IO_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_IO_Domain` (lines 22–34)

```fortran
  TYPE, PUBLIC :: IF_IO_Domain
    TYPE(IF_IO_Cfg_Type) :: config
    TYPE(IF_FileHandle), ALLOCATABLE :: handles(:)
    INTEGER(i4) :: maxOpenFiles = 64_i4
    INTEGER(i4) :: nOpenFiles   = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: OpenFile
    PROCEDURE :: CloseFile
    PROCEDURE :: GetHandle
  END TYPE IF_IO_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 41 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 64 | `SUBROUTINE Init(this, status)` |
| SUBROUTINE | `OpenFile` | 81 | `SUBROUTINE OpenFile(this, filename, mode, format, handle_idx, status)` |
| SUBROUTINE | `CloseFile` | 116 | `SUBROUTINE CloseFile(this, handle_idx, status)` |
| FUNCTION | `GetHandle` | 136 | `FUNCTION GetHandle(this, handle_idx) RESULT(h)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
