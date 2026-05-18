# `PH_LoadBC_Legacy.f90`

- **Source**: `L4_PH/LoadBC/PH_LoadBC_Legacy.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_LoadBC_Legacy`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_LoadBC_Legacy`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_LoadBC_Legacy`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_LoadBC_Legacy.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_LoadBC_Inc_Evo_Ctx` (lines 77–80)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Inc_Evo_Ctx
    INTEGER(i4) :: step_idx = 0_i4    ! current step index
    INTEGER(i4) :: incr_idx = 0_i4    ! current increment index
  END TYPE PH_LoadBC_Inc_Evo_Ctx
```

### `PH_LoadBC_Ctx` (lines 82–104)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Ctx
    !--- NEW: Auxiliary TYPE nesting ---
    TYPE(PH_LoadBC_Inc_Evo_Ctx) :: inc   ! Inc+Evo fields (inc%inc%step_idx, inc%inc%incr_idx)
    INTEGER(i4)              :: nActiveLoads  = 0_i4
    INTEGER(i4)              :: nActiveBCs    = 0_i4
    INTEGER(i4)              :: nTotalDOF     = 0_i4
    !--- DEPRECATED flat fields (kept for backward compatibility) ---
    INTEGER(i4)              :: step_idx     = 0_i4   ! DEPRECATED: use %inc%step_idx
    INTEGER(i4)              :: incr_idx     = 0_i4   ! DEPRECATED: use %inc%incr_idx
    INTEGER(i4), ALLOCATABLE :: activeLoadIds(:)   ! (nActiveLoads) DOF id per load
    INTEGER(i4), ALLOCATABLE :: loadTypes(:)       ! (nActiveLoads)
    REAL(wp),    ALLOCATABLE :: loadMagnitudes(:)  ! (nActiveLoads)
    INTEGER(i4), ALLOCATABLE :: activeBCIds(:)     ! (nActiveBCs)
    INTEGER(i4), ALLOCATABLE :: bcDOFs(:)          ! prescribed DOF indices
    REAL(wp),    ALLOCATABLE :: bcValues(:)        ! prescribed values ?(t)
    INTEGER(i4), ALLOCATABLE :: ampRefLoad(:)      ! amplitude id for each load
    INTEGER(i4), ALLOCATABLE :: ampRefBC(:)        ! amplitude id for each BC
    ! Pressure surface: F_node = ?_? N^T t d?, t = ?p n (outward normal)
    INTEGER(i4)              :: nPressureSurfaces = 0_i4
    INTEGER(i4), ALLOCATABLE :: pressure_surf_elem_idx(:)   ! (nPressureSurfaces)
    INTEGER(i4), ALLOCATABLE :: pressure_surf_face_id(:)    ! (nPressureSurfaces) 1..6 for C3D8
    REAL(wp),    ALLOCATABLE :: pressure_surf_magnitude(:) ! (nPressureSurfaces)
  END TYPE PH_LoadBC_Ctx
```

### `PH_LoadBC_State` (lines 106–113)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_State
    REAL(wp), ALLOCATABLE :: F_ext(:)       ! (nTotalDOF) assembled external force
    REAL(wp), ALLOCATABLE :: F_thermal(:)   ! (nTotalDOF) thermal contribution
    REAL(wp), ALLOCATABLE :: F_body(:)      ! (nTotalDOF) body force contribution
    REAL(wp), ALLOCATABLE :: reaction(:)    ! (nTotalDOF) reaction forces at BCs
    REAL(wp)              :: totalExtWork  = 0.0_wp
    REAL(wp)              :: maxReaction   = 0.0_wp
  END TYPE PH_LoadBC_State
```

### `PH_LoadBC_Params` (lines 115–120)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Params
    INTEGER(i4) :: bcMethod        = PH_Ldbc_ELIMINATION
    REAL(wp)    :: penaltyFactor   = 1.0e+15_wp
    LOGICAL     :: followForce     = .FALSE.   ! follower load flag
    LOGICAL     :: thermalLoading  = .FALSE.
  END TYPE PH_LoadBC_Params
```

### `PH_LoadBC_RegisterLoad_Arg` (lines 125–132)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_RegisterLoad_Arg
    INTEGER(i4) :: loadType  = PH_Ldbc_LOAD_CONCENTRATED  ! load type enum  (IN)
    INTEGER(i4) :: dofId     = 0_i4                  ! target DOF id   (IN)
    REAL(wp)    :: magnitude = 0.0_wp                ! load magnitude  (IN)
    INTEGER(i4) :: ampRef    = 0_i4                  ! amplitude ref   (IN)
    INTEGER(i4) :: loadId    = 0_i4                  ! assigned id     (OUT)
    TYPE(ErrorStatusType) :: status                  !                 (OUT)
  END TYPE PH_LoadBC_RegisterLoad_Arg
```

### `PH_LoadBC_RegisterBC_Arg` (lines 134–140)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_RegisterBC_Arg
    INTEGER(i4) :: dofId  = 0_i4      ! prescribed DOF id    (IN)
    REAL(wp)    :: value  = 0.0_wp   ! prescribed value ?   (IN)
    INTEGER(i4) :: ampRef = 0_i4     ! amplitude ref        (IN)
    INTEGER(i4) :: bcId   = 0_i4     ! assigned id          (OUT)
    TYPE(ErrorStatusType) :: status  !                      (OUT)
  END TYPE PH_LoadBC_RegisterBC_Arg
```

### `PH_LoadBC_GetSummary_Arg` (lines 142–145)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status        ! (OUT)
  END TYPE PH_LoadBC_GetSummary_Arg
```

### `PH_LoadBC_RegisterPressureSurface_Arg` (lines 147–152)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_RegisterPressureSurface_Arg
    INTEGER(i4) :: elem_idx  = 0_i4   ! IN: L3 element index (1-based)
    INTEGER(i4) :: face_id   = 1_i4   ! IN: C3D8 face 1..6
    REAL(wp)    :: magnitude = 0.0_wp ! IN: pressure p (positive = inward)
    TYPE(ErrorStatusType) :: status  ! OUT
  END TYPE PH_LoadBC_RegisterPressureSurface_Arg
```

### `PH_LoadBC_IncrBegin_Reset_Arg` (lines 160–163)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_IncrBegin_Reset_Arg
    INTEGER(i4) :: nTotalDOF = 0_i4   ! IN: total DOF count (must match allocated size)
    TYPE(ErrorStatusType) :: status    ! OUT
  END TYPE PH_LoadBC_IncrBegin_Reset_Arg
```

### `PH_LoadBC_Assemble_Fext_Arg` (lines 167–175)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Assemble_Fext_Arg
    REAL(wp)    :: time       = 0.0_wp    ! IN: current analysis time
    REAL(wp)    :: dt         = 0.0_wp    ! IN: time step size
    INTEGER(i4) :: nTotalDOF  = 0_i4     ! IN: total DOF count
    REAL(wp), ALLOCATABLE :: F_ext(:)    ! OUT: assembled external force (nTotalDOF)
    REAL(wp), ALLOCATABLE :: F_body(:)   ! OUT: body force contribution  (nTotalDOF)
    REAL(wp), ALLOCATABLE :: F_thermal(:)! OUT: thermal load contribution (nTotalDOF)
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_LoadBC_Assemble_Fext_Arg
```

### `PH_LoadBC_Apply_DirichletBC_Arg` (lines 180–188)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Apply_DirichletBC_Arg
    REAL(wp)    :: time       = 0.0_wp    ! IN: current analysis time
    INTEGER(i4) :: nTotalDOF  = 0_i4     ! IN: total DOF count
    REAL(wp), ALLOCATABLE :: u_prescribed(:) ! IN: prescribed DOF values (nActiveBCs)
    LOGICAL     :: penaltyMode = .FALSE.  ! IN: .TRUE. = penalty, .FALSE. = elimination
    REAL(wp), ALLOCATABLE :: K(:,:)      ! INOUT: global stiffness (nTotalDOF, nTotalDOF)
    REAL(wp), ALLOCATABLE :: f(:)        ! INOUT: global RHS (nTotalDOF)
    TYPE(ErrorStatusType) :: status       ! OUT
  END TYPE PH_LoadBC_Apply_DirichletBC_Arg
```

### `PH_LoadBC_Apply_DirichletBC_CSR_Arg` (lines 193–203)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Apply_DirichletBC_CSR_Arg
    REAL(wp)    :: time       = 0.0_wp    ! IN: current analysis time
    INTEGER(i4) :: nTotalDOF  = 0_i4     ! IN: system size
    INTEGER(i4), ALLOCATABLE :: rowPtr(:)   ! INOUT: CSR row pointer (nTotalDOF+1)
    INTEGER(i4), ALLOCATABLE :: colInd(:)   ! INOUT: CSR column indices (nnz)
    REAL(wp),    ALLOCATABLE :: values(:)   ! INOUT: CSR values (nnz)
    REAL(wp),    ALLOCATABLE :: R(:)        ! INOUT: RHS (nTotalDOF), residual for K*du=-R
    REAL(wp),    ALLOCATABLE :: u_old(:)    ! IN: optional, previous-step u for incremental
    LOGICAL     :: penaltyMode = .FALSE.   ! IN: .TRUE.=penalty, .FALSE.=elimination
    TYPE(ErrorStatusType) :: status        ! OUT
  END TYPE PH_LoadBC_Apply_DirichletBC_CSR_Arg
```

### `PH_LoadBC_Eval_Amplitude_Arg` (lines 207–213)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Eval_Amplitude_Arg
    INTEGER(i4) :: ampRef     = 0_i4     ! IN: amplitude id (0 = unit ramp)
    REAL(wp)    :: time       = 0.0_wp   ! IN: current analysis time
    REAL(wp)    :: dt         = 0.0_wp   ! IN: time step size
    REAL(wp)    :: ampFactor  = 1.0_wp   ! OUT: amplitude scale factor A(t)
    TYPE(ErrorStatusType) :: status      ! OUT
  END TYPE PH_LoadBC_Eval_Amplitude_Arg
```

### `PH_LoadBC_Domain` (lines 215–233)

```fortran
  TYPE, PUBLIC :: PH_LoadBC_Domain
    TYPE(PH_LoadBC_Ctx)    :: ctx
    TYPE(PH_LoadBC_State)  :: state
    TYPE(PH_LoadBC_Params) :: params
    LOGICAL                :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: RegisterLoad
    PROCEDURE :: RegisterBC
    PROCEDURE :: RegisterPressureSurface
    PROCEDURE :: GetSummary
    ! --- Algorithm stubs (Phase B) ---
    PROCEDURE :: IncrBegin_Reset
    PROCEDURE :: Assemble_Fext
    PROCEDURE :: Apply_DirichletBC
    PROCEDURE :: Apply_DirichletBC_CSR
    PROCEDURE :: Eval_Amplitude
  END TYPE PH_LoadBC_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 237 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Init` | 260 | `SUBROUTINE Init(this, stepId, status, incr_idx)` |
| SUBROUTINE | `RegisterLoad` | 282 | `SUBROUTINE RegisterLoad(this, arg)` |
| SUBROUTINE | `RegisterPressureSurface` | 293 | `SUBROUTINE RegisterPressureSurface(this, arg)` |
| SUBROUTINE | `PH_LoadBC_RegisterLoad_Impl` | 338 | `SUBROUTINE PH_LoadBC_RegisterLoad_Impl(this, loadType, dofId, magnitude, &` |
| SUBROUTINE | `RegisterBC` | 403 | `SUBROUTINE RegisterBC(this, arg)` |
| SUBROUTINE | `PH_LoadBC_RegisterBC_Impl` | 411 | `SUBROUTINE PH_LoadBC_RegisterBC_Impl(this, dofId, value, ampRef, bcId, status)` |
| SUBROUTINE | `GetSummary` | 468 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `PH_LoadBC_GetSummary_Impl` | 475 | `SUBROUTINE PH_LoadBC_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `Assemble_Fext` | 505 | `SUBROUTINE Assemble_Fext(this, arg)` |
| SUBROUTINE | `PH_LoadBC_AssemblePressure_Surfaces` | 583 | `SUBROUTINE PH_LoadBC_AssemblePressure_Surfaces(this, arg)` |
| SUBROUTINE | `Apply_DirichletBC` | 634 | `SUBROUTINE Apply_DirichletBC(this, arg)` |
| SUBROUTINE | `Apply_DirichletBC_CSR` | 692 | `SUBROUTINE Apply_DirichletBC_CSR(this, arg)` |
| SUBROUTINE | `Eval_Amplitude` | 782 | `SUBROUTINE Eval_Amplitude(this, arg)` |
| SUBROUTINE | `IncrBegin_Reset` | 815 | `SUBROUTINE IncrBegin_Reset(this, arg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
