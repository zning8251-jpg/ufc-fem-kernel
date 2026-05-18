# `MD_Step_Mgr.f90`

- **Source**: `L3_MD/Analysis/Step/MD_Step_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Step_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Step_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Step`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Step`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Step/MD_Step_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `StepAlgo` (lines 73–77)

```fortran
  TYPE, PUBLIC :: StepAlgo
    TYPE(UF_IncrementControl) :: inc_ctrl  !! Time increment control (Dt_0/Dt_min/Dt_max)
    TYPE(UF_SolutionControl)  :: sol_ctrl  !! Newton-Raphson control (max_iter/eps_res)
    TYPE(UF_DynamicParams)    :: dyn       !! Dynamic integration (Newmark beta/gamma/HHT)
  END TYPE StepAlgo
```

### `MD_Step_Desc` (lines 84–107)

```fortran
  TYPE, PUBLIC :: MD_Step_Desc
    !--- Desc (Write-Once) ---
    CHARACTER(LEN=64) :: name         = ""
    INTEGER(i4)       :: step_number  = 0_i4
    INTEGER(i4)       :: procedure    = PROC_STATIC   !! PROC_STATIC/DYNAMIC_IMPLICIT/etc.
    INTEGER(i4)       :: nlgeom       = NLGEOM_OFF    !! 0=off, 1=on
    REAL(wp)          :: time_period  = 1.0_wp        !! Step time period T (Real)
    REAL(wp)          :: start_time   = 0.0_wp        !! Absolute start time t_0 (Real)
    LOGICAL           :: perturbation = .FALSE.       !! Perturbation step flag
    !--- Index tree: load_ids/bc_ids/pair_ids (from Domain_Core) ---
    ! See BOUNDARY_DOMAIN_DESIGN.md / INTERACTION_DOMAIN_DESIGN.md
    INTEGER(i4), ALLOCATABLE :: load_ids(:)   !! Load IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: bc_ids(:)     !! BC IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: pair_ids(:)   !! Contact pair IDs active for this Step
    INTEGER(i4), ALLOCATABLE :: output_ids(:) !! Output request IDs active for this Step (OUTPUT_DOMAIN_DESIGN Phase A)
    INTEGER(i4)             :: solver_config_id = 0_i4 !! Solver config index in MD_Solver_Domain (SOLVER_INDEX_FLAT)
    !--- Algo (frozen at parse) ---
    TYPE(StepAlgo)    :: algo
    !--- State (WriteBack target ONLY - do NOT write directly) ---
    REAL(wp)    :: current_time      = 0.0_wp         !! Current time t (Real)
    INTEGER(i4) :: current_increment = 0_i4           !! Current increment n_inc (Integer)
    LOGICAL     :: is_active         = .TRUE.         !! Step is current
    LOGICAL     :: is_complete       = .FALSE.        !! Step has finished
  END TYPE MD_Step_Desc
```

### `MD_Step_Domain` (lines 114–137)

```fortran
  TYPE, PUBLIC :: MD_Step_Domain
    TYPE(MD_Step_Desc), ALLOCATABLE :: steps(:)           !! All step definitions
    INTEGER(i4)                     :: n_steps        = 0_i4
    INTEGER(i4)                     :: current_step_idx = 0_i4
    INTEGER(i4)                     :: current_incr_idx = 0_i4  !! [ ] L5 InitIncrement
    REAL(wp)                        :: total_time     = 0.0_wp  !! Sum of time_period
    TYPE(StepAlgo)                  :: algo            !! Global default algo params
    LOGICAL                         :: initialized    = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Add
    PROCEDURE :: Advance
    PROCEDURE :: GetCurrent
    PROCEDURE :: Get
    PROCEDURE :: GetByName
    PROCEDURE :: GetSummary
    PROCEDURE :: WriteBack
    PROCEDURE :: AddLoadId
    PROCEDURE :: AddBCId
    PROCEDURE :: AddPairId
    PROCEDURE :: AddOutputId
    PROCEDURE :: SetSolverConfigId
  END TYPE MD_Step_Domain
```

### `MD_Step_GetSummary_Arg` (lines 143–146)

```fortran
  TYPE, PUBLIC :: MD_Step_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Step_GetSummary_Arg
```

### `MD_Step_Get_Arg` (lines 152–154)

```fortran
  TYPE, PUBLIC :: MD_Step_Get_Arg
    TYPE(MD_Step_Desc) :: desc
  END TYPE MD_Step_Get_Arg
```

### `MD_Step_GetByName_Arg` (lines 160–163)

```fortran
  TYPE, PUBLIC :: MD_Step_GetByName_Arg
    INTEGER(i4) :: step_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Step_GetByName_Arg
```

### `MD_Step_WriteBack_Arg` (lines 169–173)

```fortran
  TYPE, PUBLIC :: MD_Step_WriteBack_Arg
    REAL(wp)  :: current_time      = 0.0_wp
    INTEGER(i4) :: current_increment = 0_i4
    LOGICAL   :: is_complete       = .FALSE.
  END TYPE MD_Step_WriteBack_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Add` | 187 | `SUBROUTINE Add(this, desc, status)` |
| SUBROUTINE | `Advance` | 243 | `SUBROUTINE Advance(this, status)` |
| SUBROUTINE | `Finalize` | 271 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `GetCurrent` | 288 | `SUBROUTINE GetCurrent(this, desc, status)` |
| SUBROUTINE | `Get` | 301 | `SUBROUTINE Get(this, idx, desc, status)` |
| SUBROUTINE | `MD_Step_GetStep_Idx` | 322 | `SUBROUTINE MD_Step_GetStep_Idx(step_idx, arg, status)` |
| SUBROUTINE | `WriteBack_Idx` | 347 | `SUBROUTINE WriteBack_Idx(step_idx, arg, status)` |
| SUBROUTINE | `Init` | 375 | `SUBROUTINE Init(this, max_steps, status)` |
| SUBROUTINE | `MD_Step_DP_RegisterStructType` | 407 | `SUBROUTINE MD_Step_DP_RegisterStructType(status)` |
| SUBROUTINE | `WriteBack` | 460 | `SUBROUTINE WriteBack(this, step_idx, current_time, current_increment, &` |
| SUBROUTINE | `GetByName` | 497 | `SUBROUTINE GetByName(this, name, step_idx, found, status)` |
| SUBROUTINE | `MD_Step_GetStepByName_Idx` | 558 | `SUBROUTINE MD_Step_GetStepByName_Idx(name, arg, status)` |
| SUBROUTINE | `GetSummary` | 590 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Step_GetSummary_Impl` | 596 | `SUBROUTINE MD_Step_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `AddLoadId` | 632 | `SUBROUTINE AddLoadId(this, step_idx, load_id, status)` |
| SUBROUTINE | `AddBCId` | 661 | `SUBROUTINE AddBCId(this, step_idx, bc_id, status)` |
| SUBROUTINE | `AddPairId` | 694 | `SUBROUTINE AddPairId(this, step_idx, pair_id, status)` |
| SUBROUTINE | `AddOutputId` | 728 | `SUBROUTINE AddOutputId(this, step_idx, output_id, status)` |
| SUBROUTINE | `SetSolverConfigId` | 762 | `SUBROUTINE SetSolverConfigId(this, step_idx, config_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
