# `AP_Out_Domain.f90`

- **Source**: `L6_AP/Output/AP_Out_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_Out_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Out_Domain`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Out_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Output/AP_Out_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Output_State_Files` (lines 34–39)

```fortran
    TYPE, PUBLIC :: AP_Output_State_Files
    INTEGER(i4) :: odbFileUnit = 0_i4
    INTEGER(i4) :: msgFileUnit = 0_i4
    INTEGER(i4) :: datFileUnit = 0_i4
    INTEGER(i4) :: staFileUnit = 0_i4
  END TYPE AP_Output_State_Files
```

### `AP_Output_State_Stats` (lines 41–45)

```fortran
  TYPE, PUBLIC :: AP_Output_State_Stats
    INTEGER(i4) :: totalFrames     = 0_i4
    REAL(wp)    :: totalWriteBytes = 0.0_wp  ! approximate bytes written
    REAL(wp)    :: totalWriteTime  = 0.0_wp
  END TYPE AP_Output_State_Stats
```

### `AP_Output_State_Flags` (lines 47–49)

```fortran
  TYPE, PUBLIC :: AP_Output_State_Flags
    LOGICAL :: odbOpen = .FALSE.
  END TYPE AP_Output_State_Flags
```

### `AP_Output_State` (lines 51–55)

```fortran
  TYPE, PUBLIC :: AP_Output_State
    TYPE(AP_Output_State_Files) :: files
    TYPE(AP_Output_State_Stats) :: stats
    TYPE(AP_Output_State_Flags) :: flags
  END TYPE AP_Output_State
```

### `AP_Output_Ctrl_Paths` (lines 57–60)

```fortran
    TYPE, PUBLIC :: AP_Output_Ctrl_Paths
    CHARACTER(LEN=512) :: outputDir = '.'
    CHARACTER(LEN=256) :: jobName   = ' '
  END TYPE AP_Output_Ctrl_Paths
```

### `AP_Output_Ctrl_Format` (lines 62–64)

```fortran
  TYPE, PUBLIC :: AP_Output_Ctrl_Format
    INTEGER(i4) :: primaryFormat = AP_OUTFMT_ODB
  END TYPE AP_Output_Ctrl_Format
```

### `AP_Output_Ctrl_Flags` (lines 66–72)

```fortran
  TYPE, PUBLIC :: AP_Output_Ctrl_Flags
    LOGICAL :: writeODB    = .TRUE.
    LOGICAL :: writeMSG    = .TRUE.
    LOGICAL :: writeDAT    = .TRUE.
    LOGICAL :: writeSTA    = .TRUE.
    LOGICAL :: compressODB = .FALSE.
  END TYPE AP_Output_Ctrl_Flags
```

### `AP_Output_Ctrl` (lines 74–78)

```fortran
  TYPE, PUBLIC :: AP_Output_Ctrl
    TYPE(AP_Output_Ctrl_Paths)  :: paths
    TYPE(AP_Output_Ctrl_Format) :: format
    TYPE(AP_Output_Ctrl_Flags)  :: flags
  END TYPE AP_Output_Ctrl
```

### `AP_Output_OpenODB_Arg` (lines 81–84)

```fortran
  TYPE, PUBLIC :: AP_Output_OpenODB_Arg
    CHARACTER(LEN=512)    :: odbPath = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Output_OpenODB_Arg
```

### `AP_Output_WriteFrame_Arg_IDs` (lines 86–91)

```fortran
    TYPE, PUBLIC :: AP_Output_WriteFrame_Arg_IDs
    INTEGER(i4) :: frameId    = 0_i4    ! (IN)
    INTEGER(i4) :: step_id    = 0_i4    ! (IN) step_idx, optional
    INTEGER(i4) :: inc_id     = 0_i4    ! (IN) incr_idx, optional
    INTEGER(i4) :: request_id = 0_i4    ! (IN) optional
  END TYPE AP_Output_WriteFrame_Arg_IDs
```

### `AP_Output_WriteFrame_Arg_Meta` (lines 93–96)

```fortran
  TYPE, PUBLIC :: AP_Output_WriteFrame_Arg_Meta
    REAL(wp)  :: time        = 0.0_wp  ! (IN) optional
    LOGICAL   :: hasMetadata = .FALSE. ! (IN) use optional fields
  END TYPE AP_Output_WriteFrame_Arg_Meta
```

### `AP_Output_WriteFrame_Arg` (lines 98–102)

```fortran
  TYPE, PUBLIC :: AP_Output_WriteFrame_Arg
    TYPE(AP_Output_WriteFrame_Arg_IDs)  :: ids
    TYPE(AP_Output_WriteFrame_Arg_Meta) :: meta
    TYPE(ErrorStatusType)               :: status
  END TYPE AP_Output_WriteFrame_Arg
```

### `AP_Output_GetSummary_Arg` (lines 104–107)

```fortran
  TYPE, PUBLIC :: AP_Output_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""         ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Output_GetSummary_Arg
```

### `AP_Output_Domain` (lines 109–130)

```fortran
  TYPE, PUBLIC :: AP_Output_Domain
    TYPE(AP_Output_State) :: state
    TYPE(AP_Output_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(OutputRequestEntry), ALLOCATABLE :: output_requests(:)
    TYPE(FrameEntry),          ALLOCATABLE :: frames(:)
    INTEGER(i4) :: n_requests = 0_i4
    INTEGER(i4) :: n_frames   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: OpenODB
    PROCEDURE :: WriteFrame
    PROCEDURE :: GetSummary
    PROCEDURE :: AddOutputRequest
    PROCEDURE :: AddFrame
    PROCEDURE :: GetRequestById
    PROCEDURE :: GetFrameById
    PROCEDURE :: GetRequestCount
    PROCEDURE :: GetFrameCount
  END TYPE AP_Output_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Output_Domain_Finalize` | 134 | `SUBROUTINE AP_Output_Domain_Finalize(this)` |
| SUBROUTINE | `AP_Output_Domain_Init` | 145 | `SUBROUTINE AP_Output_Domain_Init(this, status)` |
| SUBROUTINE | `AP_Output_Domain_OpenODB` | 158 | `SUBROUTINE AP_Output_Domain_OpenODB(this, arg)` |
| SUBROUTINE | `AP_Output_OpenODB_Impl` | 164 | `SUBROUTINE AP_Output_OpenODB_Impl(this, odbPath, status)` |
| SUBROUTINE | `AP_Output_Domain_WriteFrame` | 193 | `SUBROUTINE AP_Output_Domain_WriteFrame(this, arg)` |
| SUBROUTINE | `AP_Output_WriteFrame_Impl` | 204 | `SUBROUTINE AP_Output_WriteFrame_Impl(this, frameId, status, step_id, inc_id, time, request_id)` |
| SUBROUTINE | `AP_Output_Domain_GetSummary` | 243 | `SUBROUTINE AP_Output_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `AP_Output_GetSummary_Impl` | 249 | `SUBROUTINE AP_Output_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `AP_Output_Domain_AddOutputRequest` | 280 | `SUBROUTINE AP_Output_Domain_AddOutputRequest(this, entry, request_id, status)` |
| SUBROUTINE | `AP_Output_Domain_AddFrame` | 359 | `SUBROUTINE AP_Output_Domain_AddFrame(this, step_id, inc_id, time, request_id, frame_id, status)` |
| SUBROUTINE | `AP_Output_Domain_GetRequestById` | 405 | `SUBROUTINE AP_Output_Domain_GetRequestById(this, idx, entry, found)` |
| SUBROUTINE | `AP_Output_Domain_GetFrameById` | 457 | `SUBROUTINE AP_Output_Domain_GetFrameById(this, idx, entry, found)` |
| FUNCTION | `AP_Output_Domain_GetRequestCount` | 477 | `FUNCTION AP_Output_Domain_GetRequestCount(this) RESULT(n)` |
| FUNCTION | `AP_Output_Domain_GetFrameCount` | 490 | `FUNCTION AP_Output_Domain_GetFrameCount(this) RESULT(n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
