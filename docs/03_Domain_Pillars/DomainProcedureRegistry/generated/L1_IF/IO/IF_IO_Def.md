# `IF_IO_Def.f90`

- **Source**: `L1_IF/IO/IF_IO_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `IO`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/IF_IO_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_IO_Desc` (lines 17–21)

```fortran
  TYPE, PUBLIC :: IF_IO_Desc
    INTEGER(i4)        :: unit_min     = 10
    INTEGER(i4)        :: unit_max     = 99
    CHARACTER(LEN=256) :: default_path = ""
  END TYPE IF_IO_Desc
```

### `IF_IO_Ctx` (lines 23–27)

```fortran
  TYPE, PUBLIC :: IF_IO_Ctx
    INTEGER(i4)        :: current_unit = 0
    LOGICAL            :: unit_open    = .FALSE.
    CHARACTER(LEN=256) :: current_file = ""
  END TYPE IF_IO_Ctx
```

### `IF_IO_State` (lines 30–35)

```fortran
  TYPE, PUBLIC :: IF_IO_State
    INTEGER(i4) :: files_open   = 0_i4
    INTEGER(i4) :: total_reads  = 0_i4
    INTEGER(i4) :: total_writes = 0_i4
    LOGICAL     :: initialized  = .FALSE.
  END TYPE IF_IO_State
```

### `IF_IO_Algo` (lines 38–41)

```fortran
  TYPE, PUBLIC :: IF_IO_Algo
    INTEGER(i4) :: buffer_size    = 8192_i4   ! default 8 KB
    INTEGER(i4) :: default_format = 0_i4      ! 0=text, 1=binary
  END TYPE IF_IO_Algo
```

### `IF_IO_Cfg_Type` (lines 44–48)

```fortran
  TYPE, PUBLIC :: IF_IO_Cfg_Type
    INTEGER(i4) :: bufferSize   = 65536_i4
    LOGICAL     :: enBuffered   = .TRUE.
    LOGICAL     :: enCompressed = .FALSE.
  END TYPE IF_IO_Cfg_Type
```

### `IF_IO_OpenFile_Arg` (lines 55–59)

```fortran
  TYPE, PUBLIC :: IF_IO_OpenFile_Arg
    CHARACTER(LEN=512) :: filename = ""
    INTEGER(i4)        :: mode     = 0_i4   ! 0=default(read); IF_IO_MODE_*
    INTEGER(i4)        :: format   = 0_i4   ! 0=default(text); IF_IO_FORMAT_*
  END TYPE IF_IO_OpenFile_Arg
```

### `IF_IO_Filter_Arg` (lines 66–70)

```fortran
  TYPE, PUBLIC :: IF_IO_Filter_Arg
    INTEGER(i4) :: input_size  = 0_i4   ! IN:  number of bytes in input buffer
    INTEGER(i4) :: output_size = 0_i4   ! OUT: number of bytes written to output
    INTEGER(i4) :: io_flags    = 0_i4   ! IN:  IF_IO_FILTER_FLAG_*
  END TYPE IF_IO_Filter_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
