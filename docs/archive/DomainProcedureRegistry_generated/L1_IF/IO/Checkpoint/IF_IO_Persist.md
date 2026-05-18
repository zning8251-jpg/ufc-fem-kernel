# `IF_IO_Persist.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_IO_Persist.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_IO_Persist`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_Persist`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_Persist`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_IO_Persist.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_PersistConfig` (lines 31–38)

```fortran
  TYPE, PUBLIC :: IF_PersistConfig
    CHARACTER(LEN=256) :: workDir       = "."
    CHARACTER(LEN=256) :: backupDir     = "./backup"
    INTEGER(i4)        :: maxBackups    = 3_i4
    INTEGER(i4)        :: maxFiles      = 32_i4
    LOGICAL            :: enAutoBackup  = .FALSE.
    LOGICAL            :: enCompression = .FALSE.
  END TYPE IF_PersistConfig
```

### `IF_FileRecord` (lines 46–52)

```fortran
  TYPE, PUBLIC :: IF_FileRecord
    CHARACTER(LEN=256) :: filename = ""
    INTEGER(i4)        :: unit     = 0_i4    ! Fortran unit number
    INTEGER(i4)        :: purpose  = IF_FILE_GENERIC
    LOGICAL            :: isOpen   = .FALSE.
    LOGICAL            :: readOnly = .FALSE.
  END TYPE IF_FileRecord
```

### `IF_Persist_Domain` (lines 57–71)

```fortran
  TYPE, PUBLIC :: IF_Persist_Domain
    TYPE(IF_PersistConfig)           :: config
    TYPE(IF_FileRecord), ALLOCATABLE :: files(:)
    INTEGER(i4) :: nFilesManaged = 0_i4
    INTEGER(i4) :: file_cap      = 0_i4
    LOGICAL     :: initialized   = .FALSE.
  CONTAINS
    PROCEDURE :: Init             => IF_IO_Persist_Init
    PROCEDURE :: Finalize         => IF_IO_Persist_Finalize
    PROCEDURE :: RegisterFile     => IF_Persist_RegisterFile
    PROCEDURE :: OpenFile         => IF_Persist_OpenFile
    PROCEDURE :: CloseFile        => IF_Persist_CloseFile
    PROCEDURE :: WriteCheckpoint  => IF_Persist_WriteCheckpoint
    PROCEDURE :: ReadCheckpoint   => IF_Persist_ReadCheckpoint
  END TYPE IF_Persist_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_IO_Persist_Init` | 78 | `SUBROUTINE IF_IO_Persist_Init(this, workDir, status)` |
| SUBROUTINE | `IF_IO_Persist_Finalize` | 98 | `SUBROUTINE IF_IO_Persist_Finalize(this)` |
| SUBROUTINE | `IF_Persist_RegisterFile` | 135 | `SUBROUTINE IF_Persist_RegisterFile(this, filename, purpose, &` |
| SUBROUTINE | `IF_Persist_OpenFile` | 193 | `SUBROUTINE IF_Persist_OpenFile(this, reg_idx, status)` |
| SUBROUTINE | `IF_Persist_CloseFile` | 239 | `SUBROUTINE IF_Persist_CloseFile(this, reg_idx, status)` |
| SUBROUTINE | `IF_Persist_ReadCheckpoint` | 269 | `SUBROUTINE IF_Persist_ReadCheckpoint(this, reg_idx, step_id, inc_id, sim_time, status)` |
| SUBROUTINE | `IF_Persist_WriteCheckpoint` | 318 | `SUBROUTINE IF_Persist_WriteCheckpoint(this, reg_idx, step_id, inc_id, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
