# `MD_Cont_Mgr.f90`

- **Source**: `L3_MD/Interaction/MD_Cont_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Cont_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Cont_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Cont`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Cont_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ContAlgo` (lines 116–123)

```fortran
  TYPE, PUBLIC :: ContAlgo
    REAL(wp)    :: search_radius     = 0.0_wp   !! Contact detection radius
    REAL(wp)    :: penalty_factor    = 1.0E+5_wp !! Augmented Lagrangian penalty k_N
    REAL(wp)    :: lagrange_tol      = 1.0E-8_wp !! Lagrange multiplier convergence tol
    INTEGER(i4) :: max_search_iter   = 10_i4     !! Max contact search iterations
    LOGICAL     :: auto_penalty      = .TRUE.     !! Automatic penalty calculation
    LOGICAL     :: adjust_midplane   = .FALSE.    !! Adjust midplane for shells
  END TYPE ContAlgo
```

### `MD_Cont_Algo` (lines 130–133)

```fortran
  TYPE, PUBLIC :: MD_Cont_Algo
    TYPE(MD_Cont_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] step-level control
    TYPE(ContAlgo)             :: legacy     ! legacy fields (use stp_ctl for new code)
  END TYPE MD_Cont_Algo
```

### `MD_ContactProperty` (lines 139–148)

```fortran
  TYPE, PUBLIC :: MD_ContactProperty
    CHARACTER(LEN=64)            :: name     = ""
    TYPE(MD_Friction_Type)       :: friction
    TYPE(MD_Cohesion_Type)       :: cohesion
    TYPE(MD_ContactDamping_Type) :: damping
    TYPE(MD_ContactProperty_Type):: pressure_overclosure  !! Hard/soft/exponential
    LOGICAL                      :: has_friction  = .FALSE.
    LOGICAL                      :: has_cohesion  = .FALSE.
    LOGICAL                      :: has_damping   = .FALSE.
  END TYPE MD_ContactProperty
```

### `MD_Interaction_GetPair_Arg` (lines 154–156)

```fortran
  TYPE, PUBLIC :: MD_Interaction_GetPair_Arg
    TYPE(MD_ContactPairDef) :: pair_def
  END TYPE MD_Interaction_GetPair_Arg
```

### `MD_Interaction_GetProperty_Arg` (lines 157–159)

```fortran
  TYPE, PUBLIC :: MD_Interaction_GetProperty_Arg
    TYPE(MD_ContactProperty) :: prop
  END TYPE MD_Interaction_GetProperty_Arg
```

### `MD_ContactPairState` (lines 168–177)

```fortran
  TYPE, PUBLIC :: MD_ContactPairState
    REAL(wp)    :: gap            = 0.0_wp    !! Normal gap g_N
    REAL(wp)    :: normal_force   = 0.0_wp    !! Contact pressure p_N
    REAL(wp)    :: tangent_force  = 0.0_wp    !! Friction traction ||t_T||
    INTEGER(i4) :: contact_state  = CONT_STATE_OPEN
    LOGICAL     :: isActive       = .FALSE.
    ! [Data chain] three-step indexing L3→L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_ContactPairState
```

### `ContCtx` (lines 183–190)

```fortran
  TYPE, PUBLIC :: ContCtx
    INTEGER(i4) :: current_pair_id   = 0_i4
    INTEGER(i4) :: operation_type    = 0_i4  ! 1=Add, 2=Modify, 3=Delete
    LOGICAL     :: search_pending    = .FALSE.
    INTEGER(i4) :: last_step_idx     = 0_i4
    INTEGER(i4) :: last_incr_idx     = 0_i4   ! [ ]
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE ContCtx
```

### `MD_Interaction_Domain` (lines 199–227)

```fortran
  TYPE, PUBLIC :: MD_Interaction_Domain
    !--- Desc (Write-Once after parse) ---
    TYPE(MD_ContactPairDef),   ALLOCATABLE :: pairs(:)
    TYPE(MD_ContactProperty),  ALLOCATABLE :: props(:)
    INTEGER(i4)                            :: n_pairs = 0_i4
    INTEGER(i4)                            :: n_props = 0_i4
    !--- State (WriteBack whitelist) ---
    TYPE(MD_ContactPairState), ALLOCATABLE :: pair_state(:)
    !--- Algo (Solve-phase read-only) ---
    TYPE(ContAlgo)                         :: algo
    !--- Ctx (transient, not stored) ---
    ! ContCtx created per-operation
    !--- Internal ---
    LOGICAL                                :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init               => MD_Interaction_Domain_Init
    PROCEDURE :: Finalize           => MD_Interaction_Domain_Finalize
    PROCEDURE :: AddPair            => MD_Interaction_Domain_AddPair
    PROCEDURE :: AddProperty        => MD_Interaction_Domain_AddProperty
    PROCEDURE :: GetPairsForStep    => MD_Interaction_Domain_GetPairsForStep
    PROCEDURE :: GetPair            => MD_Interaction_Domain_GetPair
    PROCEDURE :: GetProperty        => MD_Interaction_Domain_GetProperty
    PROCEDURE :: GetPairByName      => MD_Interaction_Domain_GetPairByName
    PROCEDURE :: GetContactSummary  => MD_Interaction_Domain_GetContactSummary
    PROCEDURE :: GetSummary         => MD_Interaction_Domain_GetSummary
    PROCEDURE :: WriteBack_State    => MD_Interaction_WriteBack_State
    PROCEDURE :: WriteBack_Active   => MD_Interaction_WriteBack_Active
    PROCEDURE :: ValidateAllRefs    => MD_Interaction_Domain_ValidateAllRefs
  END TYPE MD_Interaction_Domain
```

### `MD_Interaction_AddPair_Arg` (lines 232–235)

```fortran
  TYPE, PUBLIC :: MD_Interaction_AddPair_Arg
    TYPE(MD_ContactPairDef)   :: pair_def      ! (IN)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_AddPair_Arg
```

### `MD_Interaction_AddProperty_Arg` (lines 237–240)

```fortran
  TYPE, PUBLIC :: MD_Interaction_AddProperty_Arg
    TYPE(MD_ContactProperty)  :: prop          ! (IN)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_AddProperty_Arg
```

### `MD_Interaction_GetSummary_Arg` (lines 242–245)

```fortran
  TYPE, PUBLIC :: MD_Interaction_GetSummary_Arg
    CHARACTER(LEN=512)        :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType)     :: status
  END TYPE MD_Interaction_GetSummary_Arg
```

### `MD_Interaction_GetPairByName_Arg` (lines 248–251)

```fortran
  TYPE, PUBLIC :: MD_Interaction_GetPairByName_Arg
    INTEGER(i4) :: pair_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Interaction_GetPairByName_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Interaction_Domain_AddPair` | 266 | `SUBROUTINE MD_Interaction_Domain_AddPair(this, pair_def, status)` |
| SUBROUTINE | `MD_Interaction_Domain_AddProperty` | 288 | `SUBROUTINE MD_Interaction_Domain_AddProperty(this, prop, status)` |
| SUBROUTINE | `MD_Interaction_Domain_Finalize` | 308 | `SUBROUTINE MD_Interaction_Domain_Finalize(this)` |
| SUBROUTINE | `MD_Interaction_Domain_GetPairsForStep` | 326 | `SUBROUTINE MD_Interaction_Domain_GetPairsForStep(this, step_idx, &` |
| SUBROUTINE | `MD_Interaction_Domain_GetPair` | 372 | `SUBROUTINE MD_Interaction_Domain_GetPair(this, idx, pair_def, status)` |
| SUBROUTINE | `MD_Interaction_Domain_GetProperty` | 392 | `SUBROUTINE MD_Interaction_Domain_GetProperty(this, name, prop, found, status)` |
| SUBROUTINE | `MD_Interaction_GetPair_Idx` | 417 | `SUBROUTINE MD_Interaction_GetPair_Idx(pair_idx, arg, status)` |
| SUBROUTINE | `MD_Interaction_GetProperty_Idx` | 429 | `SUBROUTINE MD_Interaction_GetProperty_Idx(prop_idx, arg, status)` |
| SUBROUTINE | `MD_Interaction_Domain_Init` | 449 | `SUBROUTINE MD_Interaction_Domain_Init(this, max_pairs, max_props, status)` |
| SUBROUTINE | `MD_Interaction_WriteBack_Active` | 475 | `SUBROUTINE MD_Interaction_WriteBack_Active(this, pair_idx, isActive, status)` |
| SUBROUTINE | `MD_Interaction_WriteBack_State` | 497 | `SUBROUTINE MD_Interaction_WriteBack_State(this, pair_idx, gap, &` |
| SUBROUTINE | `MD_Interaction_Domain_ValidateAllRefs` | 529 | `SUBROUTINE MD_Interaction_Domain_ValidateAllRefs(this, mesh_domain, valid, status)` |
| SUBROUTINE | `MD_Interaction_Domain_GetPairByName` | 600 | `SUBROUTINE MD_Interaction_Domain_GetPairByName(this, name, pair_idx, found, status)` |
| SUBROUTINE | `MD_Interaction_GetPairByName_Idx` | 641 | `SUBROUTINE MD_Interaction_GetPairByName_Idx(name, arg, status)` |
| SUBROUTINE | `MD_Interaction_Domain_GetContactSummary` | 675 | `SUBROUTINE MD_Interaction_Domain_GetContactSummary(this, summary, status)` |
| SUBROUTINE | `MD_Interaction_Domain_GetSummary` | 703 | `SUBROUTINE MD_Interaction_Domain_GetSummary(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
