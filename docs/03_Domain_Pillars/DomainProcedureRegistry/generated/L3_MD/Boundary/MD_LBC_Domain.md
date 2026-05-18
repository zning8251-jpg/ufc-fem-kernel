# `MD_LBC_Domain.f90`

- **Source**: `L3_MD/Boundary/MD_LBC_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_LBC_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Domain`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_LBC_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_LBC_Algo` (lines 62–67)

```fortran
  TYPE, PUBLIC :: MD_LBC_Algo
    INTEGER(i4) :: default_amp_type = 0_i4
    INTEGER(i4) :: ramp_mode        = 0_i4
    LOGICAL     :: auto_scale       = .TRUE.
    REAL(wp)    :: scale_factor     = 1.0_wp
  END TYPE MD_LBC_Algo
```

### `MD_LBC_Ctx` (lines 74–82)

```fortran
  TYPE, PUBLIC :: MD_LBC_Ctx
    INTEGER(i4) :: current_load_id   = 0_i4
    INTEGER(i4) :: current_bc_id     = 0_i4
    INTEGER(i4) :: current_ic_id     = 0_i4
    INTEGER(i4) :: operation_type    = 0_i4
    INTEGER(i4) :: last_step_idx     = 0_i4
    INTEGER(i4) :: last_incr_idx     = 0_i4   ! [ ]
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE MD_LBC_Ctx
```

### `MD_Load_Desc` (lines 89–99)

```fortran
  TYPE, PUBLIC :: MD_Load_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: load_id    = 0_i4
    INTEGER(i4)       :: load_type  = LOAD_CLOAD
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    INTEGER(i4)       :: node_id    = 0_i4
    REAL(wp)          :: magnitude  = 0.0_wp
    INTEGER(i4)       :: amp_ref    = 0_i4
    INTEGER(i4)       :: step_ref   = 0_i4
  END TYPE MD_Load_Desc
```

### `MD_Load_State` (lines 106–112)

```fortran
  TYPE, PUBLIC :: MD_Load_State
    REAL(wp)    :: currentLoadScale = 0.0_wp
    LOGICAL     :: isActive         = .TRUE.
    ! [Data chain] three-step indexing L3 -> L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_Load_State
```

### `MD_BC_Desc` (lines 119–131)

```fortran
  TYPE, PUBLIC :: MD_BC_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: bc_id      = 0_i4
    INTEGER(i4)       :: bc_type    = BC_DISPLACEMENT
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    INTEGER(i4)       :: dof_last   = 0_i4
    INTEGER(i4)       :: node_id    = 0_i4
    INTEGER(i4)       :: region_type= 0_i4
    REAL(wp)          :: value      = 0.0_wp
    INTEGER(i4)       :: amp_ref    = 0_i4
    INTEGER(i4)       :: step_ref   = 0_i4
  END TYPE MD_BC_Desc
```

### `MD_BC_State` (lines 138–144)

```fortran
  TYPE, PUBLIC :: MD_BC_State
    REAL(wp)    :: currentValue = 0.0_wp
    LOGICAL     :: isActive     = .TRUE.
    ! [Data chain] three-step indexing L3 -> L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_BC_State
```

### `MD_IC_Desc` (lines 151–160)

```fortran
  TYPE, PUBLIC :: MD_IC_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: ic_id      = 0_i4
    INTEGER(i4)       :: ic_type    = IC_TEMPERATURE
    CHARACTER(LEN=64) :: target_set = ""
    INTEGER(i4)       :: dof        = 0_i4
    REAL(wp)          :: value      = 0.0_wp
    REAL(wp)          :: values(6)  = 0.0_wp
    INTEGER(i4)       :: field_var  = 0_i4
  END TYPE MD_IC_Desc
```

### `MD_LBC_GetSummary_Arg` (lines 167–170)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_LBC_GetSummary_Arg
```

### `MD_LoadBC_Domain` (lines 177–213)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Domain
    TYPE(MD_Load_Desc), ALLOCATABLE :: loads(:)
    TYPE(MD_BC_Desc),   ALLOCATABLE :: bcs(:)
    TYPE(MD_IC_Desc),   ALLOCATABLE :: initial_conds(:)
    INTEGER(i4)                     :: n_loads = 0_i4
    INTEGER(i4)                     :: n_bcs   = 0_i4
    INTEGER(i4)                     :: n_ics   = 0_i4
    TYPE(MD_Load_State), ALLOCATABLE :: load_state(:)
    TYPE(MD_BC_State),   ALLOCATABLE :: bc_state(:)
    TYPE(MD_LBC_Algo) :: algo
    INTEGER(i4) :: cap_loads = 0_i4
    INTEGER(i4) :: cap_bcs   = 0_i4
    INTEGER(i4) :: cap_ics   = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddLoad
    PROCEDURE :: AddBC
    PROCEDURE :: AddInitialCondition
    PROCEDURE :: GetLoadsForStep
    PROCEDURE :: GetBCsForStep
    PROCEDURE :: GetLoad
    PROCEDURE :: GetBC
    PROCEDURE :: GetInitialCondition
    PROCEDURE :: GetICsByType
    PROCEDURE :: GetLoadByName
    PROCEDURE :: GetBCByName
    PROCEDURE :: GetLoadsByType
    PROCEDURE :: GetBCsByType
    PROCEDURE :: ActivateForStep
    PROCEDURE :: RegisterLoadType
    PROCEDURE :: RegisterBCType
    PROCEDURE :: WriteBack
    PROCEDURE :: GetSummary
  END TYPE MD_LoadBC_Domain
```

### `MD_LBC_GetLoadsForStep_Arg` (lines 220–223)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetLoadsForStep_Arg
    INTEGER(i4), ALLOCATABLE :: load_indices(:)
    INTEGER(i4) :: n_found = 0_i4
  END TYPE MD_LBC_GetLoadsForStep_Arg
```

### `MD_LBC_GetBCsForStep_Arg` (lines 229–232)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetBCsForStep_Arg
    INTEGER(i4), ALLOCATABLE :: bc_indices(:)
    INTEGER(i4) :: n_found = 0_i4
  END TYPE MD_LBC_GetBCsForStep_Arg
```

### `MD_LBC_GetBC_Arg` (lines 238–240)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetBC_Arg
    TYPE(MD_BC_Desc) :: desc
  END TYPE MD_LBC_GetBC_Arg
```

### `MD_LBC_GetLoad_Arg` (lines 246–248)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetLoad_Arg
    TYPE(MD_Load_Desc) :: desc
  END TYPE MD_LBC_GetLoad_Arg
```

### `MD_LBC_GetLoadByName_Arg` (lines 254–257)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetLoadByName_Arg
    INTEGER(i4) :: load_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_LBC_GetLoadByName_Arg
```

### `MD_LBC_GetBCByName_Arg` (lines 263–266)

```fortran
  TYPE, PUBLIC :: MD_LBC_GetBCByName_Arg
    INTEGER(i4) :: bc_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_LBC_GetBCByName_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 275 | `SUBROUTINE Init(this, est_loads, est_bcs, status)` |
| SUBROUTINE | `Finalize` | 297 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `AddBC` | 313 | `SUBROUTINE AddBC(this, desc, status)` |
| SUBROUTINE | `AddLoad` | 350 | `SUBROUTINE AddLoad(this, desc, status)` |
| SUBROUTINE | `AddInitialCondition` | 387 | `SUBROUTINE AddInitialCondition(this, desc, status)` |
| SUBROUTINE | `GetLoadsForStep` | 410 | `SUBROUTINE GetLoadsForStep(this, step_idx, load_indices, n_found, status)` |
| SUBROUTINE | `GetBCsForStep` | 431 | `SUBROUTINE GetBCsForStep(this, step_idx, bc_indices, n_found, status)` |
| SUBROUTINE | `GetLoad` | 452 | `SUBROUTINE GetLoad(this, idx, desc, status)` |
| SUBROUTINE | `GetBC` | 465 | `SUBROUTINE GetBC(this, idx, desc, status)` |
| SUBROUTINE | `GetInitialCondition` | 478 | `SUBROUTINE GetInitialCondition(this, idx, desc, status)` |
| SUBROUTINE | `GetICsByType` | 491 | `SUBROUTINE GetICsByType(this, ic_type, ic_indices, n_found, status)` |
| SUBROUTINE | `GetLoadByName` | 512 | `SUBROUTINE GetLoadByName(this, name, load_idx, found, status)` |
| SUBROUTINE | `GetBCByName` | 542 | `SUBROUTINE GetBCByName(this, name, bc_idx, found, status)` |
| SUBROUTINE | `WriteBack` | 572 | `SUBROUTINE WriteBack(this, load_idx, bc_idx, load_scale, load_active, bc_value, bc_active, &` |
| SUBROUTINE | `GetSummary` | 599 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `GetLoadsByType` | 619 | `SUBROUTINE GetLoadsByType(this, load_type, load_indices, n_found, status)` |
| SUBROUTINE | `GetBCsByType` | 644 | `SUBROUTINE GetBCsByType(this, bc_type, bc_indices, n_found, status)` |
| SUBROUTINE | `ActivateForStep` | 670 | `SUBROUTINE ActivateForStep(this, step_idx, status)` |
| SUBROUTINE | `RegisterLoadType` | 701 | `SUBROUTINE RegisterLoadType(this, desc, assigned_idx, status)` |
| SUBROUTINE | `RegisterBCType` | 719 | `SUBROUTINE RegisterBCType(this, desc, assigned_idx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
