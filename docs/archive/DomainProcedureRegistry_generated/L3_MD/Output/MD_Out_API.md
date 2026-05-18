# `MD_Out_API.f90`

- **Source**: `L3_MD/Output/MD_Out_API.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Out_API`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_API`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_API`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_API.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `OutputAlgo` (lines 80–84)

```fortran
  TYPE, PUBLIC :: OutputAlgo
    INTEGER(i4) :: default_format     = FMT_ODB
    INTEGER(i4) :: compression_level  = 0_i4
    LOGICAL     :: parallel_io        = .FALSE.
  END TYPE OutputAlgo
```

### `MD_OutputRequest_Desc` (lines 89–100)

```fortran
  TYPE, PUBLIC :: MD_OutputRequest_Desc
    CHARACTER(LEN=64) :: name          = ""
    INTEGER(i4)       :: request_id    = 0_i4
    INTEGER(i4)       :: request_type  = OUT_FIELD
    CHARACTER(LEN=16) :: variables(32) = ""   ! up to 32 variable names (S/U/RF/E/PE/...)
    INTEGER(i4)       :: n_variables   = 0_i4
    CHARACTER(LEN=64) :: target_set    = ""   ! assembly set name
    INTEGER(i4)       :: frequency     = 1_i4 ! every N increments
    REAL(wp)          :: time_interval = 0.0_wp
    INTEGER(i4)       :: format        = FMT_ODB
    INTEGER(i4)       :: step_ref      = 0_i4 ! index into MD_Step_Domain
  END TYPE MD_OutputRequest_Desc
```

### `MD_Output_State` (lines 105–112)

```fortran
  TYPE, PUBLIC :: MD_Output_State
    INTEGER(i4) :: lastWrittenInc  = 0_i4
    REAL(wp)    :: lastWrittenTime = 0.0_wp
    INTEGER(i4) :: totalFrames     = 0_i4
    ! [Data chain] three-step indexing L3→L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_Output_State
```

### `MD_Output_Domain` (lines 117–141)

```fortran
  TYPE, PUBLIC :: MD_Output_Domain
    !--- Desc (Write-Once) ---
    TYPE(MD_OutputRequest_Desc), ALLOCATABLE :: requests(:)
    INTEGER(i4)                              :: n_requests = 0_i4
    INTEGER(i4)                              :: capacity   = 0_i4

    !--- State (WriteBack whitelist) ---
    TYPE(MD_Output_State) :: output_state

    !--- Algo ---
    TYPE(OutputAlgo) :: algo

    !--- Internal ---
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init               => MD_Output_Domain_Init
    PROCEDURE :: Finalize           => MD_Output_Domain_Finalize
    PROCEDURE :: AddRequest         => MD_Output_Domain_AddRequest
    PROCEDURE :: GetRequest         => MD_Output_Domain_GetRequest
    PROCEDURE :: GetRequestsForStep => MD_Output_Domain_GetRequestsForStep
    PROCEDURE :: IsOutputDue        => MD_Output_Domain_IsOutputDue
    PROCEDURE :: GetRequestByName   => MD_Output_Domain_GetRequestByName
    PROCEDURE :: GetSummary         => MD_Output_Domain_GetSummary
    PROCEDURE :: WriteBack          => MD_Output_WriteBack
  END TYPE MD_Output_Domain
```

### `MD_Output_GetSummary_Arg` (lines 146–149)

```fortran
  TYPE, PUBLIC :: MD_Output_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Output_GetSummary_Arg
```

### `MD_Output_GetRequest_Arg` (lines 152–154)

```fortran
  TYPE, PUBLIC :: MD_Output_GetRequest_Arg
    TYPE(MD_OutputRequest_Desc) :: desc
  END TYPE MD_Output_GetRequest_Arg
```

### `MD_Output_GetRequestByName_Arg` (lines 157–160)

```fortran
  TYPE, PUBLIC :: MD_Output_GetRequestByName_Arg
    INTEGER(i4) :: req_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Output_GetRequestByName_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Output_Domain_AddRequest` | 169 | `SUBROUTINE MD_Output_Domain_AddRequest(this, desc, status)` |
| SUBROUTINE | `MD_Output_Domain_Finalize` | 200 | `SUBROUTINE MD_Output_Domain_Finalize(this)` |
| SUBROUTINE | `MD_Output_Domain_GetRequestsForStep` | 218 | `SUBROUTINE MD_Output_Domain_GetRequestsForStep(this, step_idx, req_indices, n_found, status, step_output_ids)` |
| SUBROUTINE | `MD_Output_Domain_Init` | 264 | `SUBROUTINE MD_Output_Domain_Init(this, est_requests, status)` |
| SUBROUTINE | `MD_Output_DP_RegisterStructType` | 288 | `SUBROUTINE MD_Output_DP_RegisterStructType(status)` |
| SUBROUTINE | `MD_Output_WriteBack` | 340 | `SUBROUTINE MD_Output_WriteBack(this, lastWrittenInc, lastWrittenTime, &` |
| SUBROUTINE | `MD_Output_Domain_GetRequest` | 366 | `SUBROUTINE MD_Output_Domain_GetRequest(this, idx, desc, status)` |
| SUBROUTINE | `MD_Output_GetRequest_Idx` | 384 | `SUBROUTINE MD_Output_GetRequest_Idx(dom, req_idx, arg, status)` |
| SUBROUTINE | `MD_Output_Domain_IsOutputDue` | 420 | `SUBROUTINE MD_Output_Domain_IsOutputDue(this, idx, inc_id, sim_time, &` |
| SUBROUTINE | `MD_Output_Domain_GetRequestByName` | 460 | `SUBROUTINE MD_Output_Domain_GetRequestByName(this, name, req_idx, found, status)` |
| SUBROUTINE | `MD_Output_GetRequestByName_Idx` | 499 | `SUBROUTINE MD_Output_GetRequestByName_Idx(dom, name, arg, status)` |
| SUBROUTINE | `MD_Output_Domain_GetSummary` | 530 | `SUBROUTINE MD_Output_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `MD_Output_GetSummary_Impl` | 536 | `SUBROUTINE MD_Output_GetSummary_Impl(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
