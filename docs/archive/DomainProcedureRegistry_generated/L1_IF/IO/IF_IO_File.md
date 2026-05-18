# `IF_IO_File.f90`

- **Source**: `L1_IF/IO/IF_IO_File.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_IO_File`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_File`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_File`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_File.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_FileHandle` (lines 70–90)

```fortran
    TYPE, PUBLIC :: IF_FileHandle
        INTEGER(i4) :: unit = -1                              ! n_unit
        CHARACTER(LEN=512) :: filename = ""                   ! path
        INTEGER(i4) :: mode = IF_IO_MODE_READ
        INTEGER(i4) :: format = IF_IO_FORMAT_TEXT
        LOGICAL :: is_open = .FALSE.
        INTEGER(i8) :: position = 0_i8                        ! pos (bytes)
        INTEGER(i8) :: file_size = 0_i8                       ! size (bytes)
    CONTAINS
        PROCEDURE :: Open
        PROCEDURE :: Close
        PROCEDURE :: ReadTextLine
        PROCEDURE :: WriteTextLine
        PROCEDURE :: ReadBinary
        PROCEDURE :: WriteBinary
        PROCEDURE :: Rewind
        PROCEDURE :: SetPosition
        PROCEDURE :: Flush
        PROCEDURE :: GetPosition
        PROCEDURE :: IsOpen
    END TYPE IF_FileHandle
```

### `IF_FileHandle_Open_In` (lines 96–100)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_Open_In
        CHARACTER(LEN=512) :: filename                        ! path
        INTEGER(i4) :: mode = IF_IO_MODE_UNSPECIFIED             ! Access mode; 0=default
        INTEGER(i4) :: format = IF_IO_FORMAT_UNSPECIFIED         ! Format type; 0=default
    END TYPE IF_FileHandle_Open_In
```

### `IF_FileHandle_Open_Out` (lines 103–106)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_Open_Out
        TYPE(IF_FileHandle) :: handle                         ! File handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_Open_Out
```

### `IF_FileHandle_Close_In` (lines 109–111)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_Close_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
    END TYPE IF_FileHandle_Close_In
```

### `IF_FileHandle_Close_Out` (lines 114–117)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_Close_Out
        TYPE(IF_FileHandle) :: handle                         ! Closed file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_Close_Out
```

### `IF_FileHandle_ReadTextLine_In` (lines 120–122)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_ReadTextLine_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
    END TYPE IF_FileHandle_ReadTextLine_In
```

### `IF_FileHandle_ReadTextLine_Out` (lines 125–129)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_ReadTextLine_Out
        CHARACTER(LEN=512) :: line                            ! Read line
        TYPE(IF_FileHandle) :: handle                         ! Updated file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_ReadTextLine_Out
```

### `IF_FileHandle_WriteTextLine_In` (lines 132–135)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_WriteTextLine_In
        TYPE(IF_FileHandle) :: handle                         ! File handle
        CHARACTER(LEN=512) :: line                            ! Line to write (fixed len for derived type)
    END TYPE IF_FileHandle_WriteTextLine_In
```

### `IF_FileHandle_WriteTextLine_Out` (lines 138–141)

```fortran
    TYPE, PUBLIC :: IF_FileHandle_WriteTextLine_Out
        TYPE(IF_FileHandle) :: handle                         ! Updated file handle
        TYPE(ErrorStatusType) :: status                       ! Error status
    END TYPE IF_FileHandle_WriteTextLine_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Open` | 164 | `SUBROUTINE Open(this, filename, mode, format, status)` |
| SUBROUTINE | `Close` | 261 | `SUBROUTINE Close(this, status)` |
| SUBROUTINE | `ReadTextLine` | 293 | `SUBROUTINE ReadTextLine(this, line, status)` |
| SUBROUTINE | `WriteTextLine` | 333 | `SUBROUTINE WriteTextLine(this, line, status)` |
| SUBROUTINE | `ReadBinary` | 370 | `SUBROUTINE ReadBinary(this, buffer, n_bytes, status)` |
| SUBROUTINE | `WriteBinary` | 412 | `SUBROUTINE WriteBinary(this, buffer, n_bytes, status)` |
| SUBROUTINE | `Rewind` | 452 | `SUBROUTINE Rewind(this, status)` |
| SUBROUTINE | `SetPosition` | 482 | `SUBROUTINE SetPosition(this, position, status)` |
| SUBROUTINE | `Flush` | 509 | `SUBROUTINE Flush(this, status)` |
| FUNCTION | `GetPosition` | 529 | `FUNCTION GetPosition(this) RESULT(position)` |
| FUNCTION | `IsOpen` | 539 | `FUNCTION IsOpen(this) RESULT(is_open)` |
| FUNCTION | `IF_FileHandle_Exists` | 553 | `FUNCTION IF_FileHandle_Exists(filename) RESULT(exists)` |
| FUNCTION | `IF_FileHandle_GetSize` | 563 | `FUNCTION IF_FileHandle_GetSize(filename) RESULT(file_size)` |
| SUBROUTINE | `IF_FileHandle_Delete` | 577 | `SUBROUTINE IF_FileHandle_Delete(filename, status)` |
| SUBROUTINE | `IF_FileHandle_Copy` | 613 | `SUBROUTINE IF_FileHandle_Copy(src_filename, dst_filename, status)` |
| SUBROUTINE | `IF_FileHandle_CreateDirectory` | 672 | `SUBROUTINE IF_FileHandle_CreateDirectory(path, status)` |
| SUBROUTINE | `IF_FileHandle_Open_Structured` | 688 | `SUBROUTINE IF_FileHandle_Open_Structured(in, out)` |
| SUBROUTINE | `IF_FileHandle_Close_Structured` | 707 | `SUBROUTINE IF_FileHandle_Close_Structured(in, out)` |
| SUBROUTINE | `IF_FileHandle_ReadTextLine_Structured` | 718 | `SUBROUTINE IF_FileHandle_ReadTextLine_Structured(in, out)` |
| SUBROUTINE | `IF_FileHandle_WriteTextLine_Structured` | 729 | `SUBROUTINE IF_FileHandle_WriteTextLine_Structured(in, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
