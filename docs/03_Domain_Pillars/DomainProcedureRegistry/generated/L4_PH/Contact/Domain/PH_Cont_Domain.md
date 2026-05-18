# `PH_Cont_Domain.f90`

- **Source**: `L4_PH/Contact/Domain/PH_Cont_Domain.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Cont_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Cont_Domain`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Cont_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Contact/Domain`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Contact/Domain/PH_Cont_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Cont_Inc_Evo_Ctx` (lines 56–59)

```fortran
  TYPE, PUBLIC :: PH_Cont_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_Cont_Inc_Evo_Ctx
```

### `PH_Contact_Ctx` (lines 61–81)

```fortran
  TYPE, PUBLIC :: PH_Contact_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_Cont_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4)              :: step_idx       = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4)              :: incr_idx       = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4)              :: nContactPairs  = 0_i4
    INTEGER(i4)              :: nActiveNodes   = 0_i4
    INTEGER(i4), ALLOCATABLE :: masterSurfIds(:)   ! (nPairs)
    INTEGER(i4), ALLOCATABLE :: slaveSurfIds(:)     ! (nPairs)
    INTEGER(i4), ALLOCATABLE :: slaveNodeIds(:)     ! (nActiveNodes)
    REAL(wp),    ALLOCATABLE :: gap(:)              ! (nActiveNodes) signed gap
    REAL(wp),    ALLOCATABLE :: normal(:,:)         ! (3, nActiveNodes)
    REAL(wp),    ALLOCATABLE :: projXi(:,:)         ! (2, nActiveNodes) parametric
    INTEGER(i4), ALLOCATABLE :: projElemId(:)       ! (nActiveNodes)
    ! AP-8: Pre-allocated in Init (cold path), used by Detect (warm path)
    REAL(wp),    ALLOCATABLE :: x_slave_buf(:,:)   ! (3, maxSlaveNodes)
    REAL(wp),    ALLOCATABLE :: x_master_buf(:,:)  ! (3, maxMasterNodes)
    INTEGER(i4)              :: maxSlaveNodes  = 0_i4
    INTEGER(i4)              :: maxMasterNodes = 0_i4
  END TYPE PH_Contact_Ctx
```

### `PH_Contact_State` (lines 83–95)

```fortran
  TYPE, PUBLIC :: PH_Contact_State
    REAL(wp),    ALLOCATABLE :: pNormal(:)         ! (nActiveNodes) normal pressure
    REAL(wp),    ALLOCATABLE :: pTangent(:,:)      ! (2, nActiveNodes) tangential
    REAL(wp),    ALLOCATABLE :: slipDisp(:,:)      ! (2, nActiveNodes) accumulated slip
    REAL(wp),    ALLOCATABLE :: slipRate(:)         ! (nActiveNodes) slip rate magnitude
    REAL(wp),    ALLOCATABLE :: lambda_n(:)         ! (nActiveNodes) AL multiplier normal
    REAL(wp),    ALLOCATABLE :: lambda_t(:,:)       ! (2, nActiveNodes) AL multiplier tan
    INTEGER(i4), ALLOCATABLE :: contactStatus(:)    ! (nActiveNodes) open/stick/slip
    REAL(wp)                 :: totalContactForce = 0.0_wp
    INTEGER(i4)              :: nOpen   = 0_i4
    INTEGER(i4)              :: nStick  = 0_i4
    INTEGER(i4)              :: nSlip   = 0_i4
  END TYPE PH_Contact_State
```

### `PH_Contact_Cfg_Algorithm` (lines 98–101)

```fortran
  TYPE, PUBLIC :: PH_Contact_Cfg_Algorithm
    INTEGER(i4) :: algorithm      = PH_CONT_SURF_TO_SURF
    INTEGER(i4) :: frictionModel  = PH_FRIC_COULOMB
  END TYPE PH_Contact_Cfg_Algorithm
```

### `PH_Contact_Cfg_Physical` (lines 104–108)

```fortran
  TYPE, PUBLIC :: PH_Contact_Cfg_Physical
    REAL(wp)    :: frictionCoeff  = 0.0_wp         ! Coulomb mu (mapped from L3)
    REAL(wp)    :: penaltyNormal  = 1.0e+10_wp     ! k_N
    REAL(wp)    :: penaltyTangent = 1.0e+10_wp     ! k_T
  END TYPE PH_Contact_Cfg_Physical
```

### `PH_Contact_Cfg_Control` (lines 111–117)

```fortran
  TYPE, PUBLIC :: PH_Contact_Cfg_Control
    REAL(wp)    :: contactTol     = 1.0e-6_wp      ! gap tolerance
    REAL(wp)    :: searchTol      = 0.0_wp         ! search extension
    INTEGER(i4) :: maxAugIter     = 10_i4
    LOGICAL     :: adjustPenalty  = .FALSE.         ! auto penalty adjustment
    LOGICAL     :: finiteSlidng   = .TRUE.          ! finite vs small sliding
  END TYPE PH_Contact_Cfg_Control
```

### `PH_Contact_Params` (lines 119–124)

```fortran
  TYPE, PUBLIC :: PH_Contact_Params
    TYPE(PH_Contact_Cfg_Algorithm) :: algo
    TYPE(PH_Contact_Cfg_Physical)  :: phys
    TYPE(PH_Contact_Cfg_Control)   :: ctrl
    ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Contact_Params
```

### `PH_Cont_RegisterPair_Arg` (lines 129–134)

```fortran
  TYPE, PUBLIC :: PH_Cont_RegisterPair_Arg
    INTEGER(i4) :: masterSurfId = 0_i4  ! master surface id (IN)
    INTEGER(i4) :: slaveSurfId  = 0_i4  ! slave  surface id (IN)
    INTEGER(i4) :: pairId       = 0_i4  ! assigned pair id  (OUT)
    TYPE(ErrorStatusType) :: status     !                   (OUT)
  END TYPE PH_Cont_RegisterPair_Arg
```

### `PH_Cont_GetSummary_Arg` (lines 136–139)

```fortran
  TYPE, PUBLIC :: PH_Cont_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE PH_Cont_GetSummary_Arg
```

### `PH_Cont_Detect_Arg` (lines 148–161)

```fortran
  TYPE, PUBLIC :: PH_Cont_Detect_Arg
    INTEGER(i4) :: pairIdx       = 0_i4     ! IN: contact pair index
    INTEGER(i4) :: nSlaveNodes   = 0_i4     ! IN: slave nodes count
    INTEGER(i4) :: nMasterNodes   = 0_i4     ! IN: master nodes count
    INTEGER(i4), ALLOCATABLE :: slaveNodeIds(:)   ! IN: L3 node indices (fetch coords)
    INTEGER(i4), ALLOCATABLE :: masterNodeIds(:)  ! IN: L3 node indices (fetch coords)
    REAL(wp), ALLOCATABLE :: x_slave(:,:)   ! IN: slave coords (3, nSlaveNodes), or OUT from L3
    REAL(wp), ALLOCATABLE :: x_master(:,:) ! IN: master coords (3, nMasterNodes), or OUT from L3
    INTEGER(i4), ALLOCATABLE :: masterConn(:,:)   ! IN: master connectivity (elem, node)
    REAL(wp), ALLOCATABLE :: gap(:)         ! OUT: signed gap (nSlaveNodes)
    REAL(wp), ALLOCATABLE :: normal(:,:)   ! OUT: normal (3, nSlaveNodes)
    INTEGER(i4), ALLOCATABLE :: projElemId(:)     ! OUT: projected elem id
    TYPE(ErrorStatusType) :: status        ! OUT
  END TYPE PH_Cont_Detect_Arg
```

### `PH_Cont_ComputeForce_Arg` (lines 165–175)

```fortran
  TYPE, PUBLIC :: PH_Cont_ComputeForce_Arg
    INTEGER(i4) :: nActiveNodes = 0_i4    ! IN
    REAL(wp)    :: penaltyNormal = 0.0_wp ! IN: ?N
    REAL(wp), ALLOCATABLE :: gap(:)       ! IN: signed gap
    REAL(wp), ALLOCATABLE :: normal(:,:)   ! IN: normal (3, n)
    REAL(wp), ALLOCATABLE :: pNormal(:)   ! OUT: normal pressure
    REAL(wp), ALLOCATABLE :: pTangent(:,:)! OUT: tangential (2, n)
    INTEGER(i4), ALLOCATABLE :: contactStatus(:) ! OUT: open/stick/slip
    REAL(wp)    :: totalForce = 0.0_wp    ! OUT
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_Cont_ComputeForce_Arg
```

### `PH_Cont_UpdateState_Arg` (lines 179–186)

```fortran
  TYPE, PUBLIC :: PH_Cont_UpdateState_Arg
    INTEGER(i4) :: nActiveNodes = 0_i4    ! IN
    REAL(wp), ALLOCATABLE :: pNormal(:)   ! IN: converged normal pressure
    REAL(wp), ALLOCATABLE :: pTangent(:,:)! IN: converged tangential
    INTEGER(i4), ALLOCATABLE :: contactStatus(:) ! IN
    REAL(wp), ALLOCATABLE :: slipDisp(:,:) ! INOUT: accumulated slip
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_Cont_UpdateState_Arg
```

### `PH_Contact_Domain` (lines 188–208)

```fortran
  TYPE, PUBLIC :: PH_Contact_Domain
    TYPE(PH_Contact_Ctx)    :: ctx
    TYPE(PH_Contact_State)  :: state
    TYPE(PH_Contact_Params) :: params
    ! Phase 3 Enhancement: Contact pair collection (NEW)
    INTEGER(i4)             :: n_pairs = 0_i4
    TYPE(PH_Contact_Pair_Desc), ALLOCATABLE :: pairs(:)
    LOGICAL                 :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterPair
    ! Phase 3 Enhancement: New interface for Pair Desc (NEW)
    PROCEDURE :: RegisterFromDesc
    PROCEDURE :: GetPair
    PROCEDURE :: GetPairCount
    PROCEDURE :: GetSummary
    PROCEDURE :: Detect
    PROCEDURE :: ComputeForce
    PROCEDURE :: UpdateState
  END TYPE PH_Contact_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 212 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 238 | `SUBROUTINE Init(this, stepId, status, maxSlaveNodes, maxMasterNodes, incr_idx)` |
| SUBROUTINE | `RegisterPair` | 271 | `SUBROUTINE RegisterPair(this, arg)` |
| SUBROUTINE | `PH_Contact_RegisterContactPair_Impl` | 279 | `SUBROUTINE PH_Contact_RegisterContactPair_Impl(this, masterSurfId, &` |
| SUBROUTINE | `GetSummary` | 326 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `PH_Contact_GetSummary_Impl` | 333 | `SUBROUTINE PH_Contact_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `Detect` | 365 | `SUBROUTINE Detect(this, arg)` |
| SUBROUTINE | `ComputeForce` | 494 | `SUBROUTINE ComputeForce(this, arg)` |
| SUBROUTINE | `UpdateState` | 535 | `SUBROUTINE UpdateState(this, arg)` |
| SUBROUTINE | `RegisterFromDesc` | 570 | `SUBROUTINE RegisterFromDesc(this, pair_desc, status)` |
| FUNCTION | `PH_Contact_Domain_GetPair` | 605 | `FUNCTION PH_Contact_Domain_GetPair(this, index, status) RESULT(pair_ptr)` |
| FUNCTION | `PH_Contact_Domain_GetPairCount` | 634 | `FUNCTION PH_Contact_Domain_GetPairCount(this) RESULT(n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
