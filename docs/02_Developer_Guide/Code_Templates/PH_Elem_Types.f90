!===============================================================================
! Module: PH_Elem_Types                                          [Template v4.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Element — Ctx / State types for per-increment element computation
!
! Purpose:
!   Defines the Ctx / State two-type system for element-level computations
!   (UEL hot-path) under the 8-TYPE minimal design.
!
! Design change (v3.1 → v4.0):
!   PH_Elem_Base_Algo TYPE is ELIMINATED.
!   Rationale:
!     Newmark/HHT-α parameters are framework-level (solver) configuration.
!     They are NOT element-private; the framework controls which integrator
!     and parameters to use.  Moved to RT_Com_Base_Ctx%newmark_params(3),
!     where the framework injects them before calling the UEL.
!
!   PH_Elem domain now carries two active types (reduced row):
!     Ctx   – element-level incremental driving inputs + embedded material Ctx
!     State – element-level outputs: RHS (residual), stiffness, energy
!
! Composition design (principle ⑤ CONTAINS ACROSS DOMAIN):
!   PH_Elem_Base_Ctx CONTAINS mat_ctx (TYPE PH_Mat_Base_Ctx)
!   This avoids duplicating material driving fields at the element level
!   while keeping clear ownership boundaries.
!
!   UEL-specific fields (coords, du, predef arrays) are held directly in
!   PH_Elem_Base_Ctx alongside the embedded mat_ctx.
!
! Layer dependency:
!   USE IF_Prec       (wp, i4)
!   USE PH_Mat_Types  (PH_Mat_Base_Ctx)   ← must be compiled first
!===============================================================================
! v4.1 changes vs v4.0:
!   - Added: PH_Elem_VUEL_State  — Explicit nblock vectorised block outputs
!            (mass matrix, internal/external force vectors, hourglass control)
!   - Added: PH_Elem_VUEL_Ctx   — VUEL driving inputs per block
!            (nblock, coords_blk, du_blk, vel_blk, accel_blk, charLength)
!   - Added: PH_Elem_UELMAT_Ctx — UEL-with-embedded-material Ctx
!            (mat_ctx pointer, element-level flags)
!   - Rationale: each Abaqus routine (UEL/VUEL/UELMAT) → one dedicated TYPE pair
!===============================================================================
MODULE PH_Elem_Types
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType
  USE PH_Mat_Types, ONLY: PH_Mat_Base_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Elem_Base_Ctx
  PUBLIC :: PH_Elem_Base_State
  PUBLIC :: PH_Elem_VUEL_Ctx
  PUBLIC :: PH_Elem_VUEL_State
  PUBLIC :: PH_Elem_UELMAT_Ctx
  PUBLIC :: PH_Elem_UELMAT_State
  ! NOTE: PH_Elem_Base_Algo has been eliminated (v4.0).
  !       Newmark/HHT-α parameters are now in RT_Com_Base_Ctx%newmark_params(3).

  !-----------------------------------------------------------------------------
  ! ① CTX — Element Computation Context (per-increment driving inputs)
  !    Embedded mat_ctx (CONTAINS composition) carries all material-level
  !    driving fields.  Element-level fields cover nodal / integration geometry.
  !
  !    UEL argument mapping (Part VI §PH_Elem_Base_Ctx):
  !      COORDS       → coords(:,:)     node coordinates       [mcrd × nnode]
  !      DU(MLVARX,*) → du(:,:)         displacement increment [mlvarx × ndofel]
  !      PREDEF       → predef(:,:,:)   predefined field       [2 × npredf × nnode]
  !      ADLMAG       → adlmag(:,:)     dist. load magnitudes  [mdload × nrhs]
  !      DDLMAG       → ddlmag(:,:)     dist. load increment   [mdload × nrhs]
  !
  !    Field count (漏洞L3 注释规范):
  !      PH_Elem_Base_Ctx = 5 direct ALLOCATABLE fields + 1 CONTAINS composition
  !      mat_ctx is NOT an ABAQUS direct parameter; filled by the UEL bridge
  !      before forwarding to the embedded UMAT call path.
  !
  !    Allocation note:
  !      All ALLOCATABLE arrays are sized by the UEL bridge at call setup.
  !      predef dim-1: 1 = value at start of increment, 2 = value at end.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Base_Ctx
    !-- Embedded material driving context (principle ⑤ CONTAINS)
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx

    !-- Nodal geometry
    REAL(wp), POINTER :: coords(:,:)     ! [mcrd, nnode]   nodal coordinates

    !-- Kinematic driving input (displacement increment)
    !   DU(MLVARX,*) in ABAQUS UEL: rows = MLVARX (RHS storage index),
    !   cols = NDOFEL.  rt_ctx%mlvarx gives the first dimension at run time.
    REAL(wp), POINTER :: du(:,:)         ! [mlvarx, ndofel]  displacement increment

    !-- Predefined field variables at nodes
    !   First index: 1 = value at start of increment, 2 = value at end
    REAL(wp), POINTER :: predef(:,:,:)   ! [2, npredf, nnode]

    !-- Distributed load magnitudes (UEL: ADLMAG, DDLMAG)
    REAL(wp), POINTER :: adlmag(:,:)     ! [mdload, nrhs]  load magnitudes at end
    REAL(wp), POINTER :: ddlmag(:,:)     ! [mdload, nrhs]  load increments this step
  END TYPE PH_Elem_Base_Ctx

  !-----------------------------------------------------------------------------
  ! ② STATE — Element-Level State (outputs written back to ABAQUS)
  !    These are the primary UEL output arrays passed back to the solver:
  !      RHS    → rhs(:,:)    residual force vector (right-hand side)
  !      AMATRX → amatrx(:,:) element stiffness (or mass/damping) matrix
  !      SVARS  → svars(:)    solution-dependent state variables storage
  !      ENERGY → energy(8)   element energy contributions (ABAQUS 8-vector)
  !
  !    Velocity / acceleration arrays (U/V/A in UEL) are carried here because
  !    they are "already-known state variables" updated by the time integrator:
  !      u(:)   current displacements  (full, not increment)
  !      v(:)   current velocities
  !      a(:)   current accelerations
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_Base_State
    !-- Primary UEL outputs
    REAL(wp), ALLOCATABLE :: rhs(:,:)      !  O  RHS     residual [ndofel, nrhs]
    REAL(wp), ALLOCATABLE :: amatrx(:,:)   !  O  AMATRX  stiffness matrix [ndofel, ndofel]
    REAL(wp), ALLOCATABLE :: svars(:)      ! IO  SVARS   state vars [nsvars]
    REAL(wp)              :: energy(8) = 0.0_wp  !  O  ENERGY  8-component energy vector

    !-- Kinematic state (UEL arguments U, V, A → read-only from ABAQUS)
    REAL(wp), ALLOCATABLE :: u(:)          ! I   U  total displacement [ndofel]
    REAL(wp), ALLOCATABLE :: v(:)          ! I   V  velocity           [ndofel]
    REAL(wp), ALLOCATABLE :: a(:)          ! I   A  acceleration       [ndofel]
  END TYPE PH_Elem_Base_State
  ! NOTE: PH_Elem_Base_Algo (Newmark params) eliminated in v4.0.
  !       Use RT_Com_Base_Ctx%newmark_params(3) instead.

  !-----------------------------------------------------------------------------
  ! PH_Elem_VUEL_Ctx — VUEL (Explicit vectorised element) driving inputs
  !   All arrays have first dimension = nblock (number of elements in block)
  !   Maps to VUEL arguments: NBLOCK, NDOFEL, NSVARS, NPROPS, NJPROPS
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_VUEL_Ctx
    INTEGER(i4) :: nblock   = 1_i4  ! NBLOCK: number of elements in block
    INTEGER(i4) :: ndofel   = 0_i4  ! NDOFEL: total DOF per element
    INTEGER(i4) :: nsvars   = 0_i4  ! NSVARS: number of state variables
    INTEGER(i4) :: nprops   = 0_i4  ! NPROPS: number of user props
    INTEGER(i4) :: njprops  = 0_i4  ! NJPROPS: integer props count
    !-- Nodal coordinates block [nblock, mcrd, nnode]
    REAL(wp), POINTER :: coords_blk(:,:,:)
    !-- Displacement increment block [nblock, ndofel]
    REAL(wp), POINTER :: du_blk(:,:)
    !-- Velocity block [nblock, ndofel]
    REAL(wp), POINTER :: vel_blk(:,:)
    !-- Acceleration block [nblock, ndofel]
    REAL(wp), POINTER :: accel_blk(:,:)
    !-- Characteristic element length [nblock] (for stable time step)
    REAL(wp), POINTER :: char_length(:)
    !-- Mass scaling factor [nblock]
    REAL(wp), POINTER :: mass_scale(:)
    !-- Predefined field variables block [nblock, 2, npredf, nnode]
    REAL(wp), POINTER :: predef_blk(:,:,:,:)
    !-- User integer properties
    INTEGER(i4), POINTER :: jprops(:)   ! [njprops]
    !-- User real properties
    REAL(wp), POINTER    :: props(:)    ! [nprops]
  END TYPE PH_Elem_VUEL_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Elem_VUEL_State — VUEL output arrays (block form)
  !   Written by the VUEL kernel; passed back to ABAQUS/Explicit
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_VUEL_State
    !-- Internal force vector block [nblock, ndofel]
    REAL(wp), ALLOCATABLE :: f_int(:,:)
    !-- External force vector block [nblock, ndofel] (surface loads etc.)
    REAL(wp), ALLOCATABLE :: f_ext(:,:)
    !-- Consistent mass matrix block [nblock, ndofel, ndofel] (lumped: diag)
    REAL(wp), ALLOCATABLE :: amass(:,:,:)
    !-- Lumped mass diagonal [nblock, ndofel]
    REAL(wp), ALLOCATABLE :: dmass(:,:)
    !-- State variables block [nblock, nsvars]
    REAL(wp), ALLOCATABLE :: svars_blk(:,:)
    !-- Element energy [nblock, 8] — same 8-slot convention as UEL ENERGY
    REAL(wp), ALLOCATABLE :: energy_blk(:,:)
    !-- Hourglass control force [nblock, ndofel] (reduced integration only)
    REAL(wp), ALLOCATABLE :: hg_force(:,:)
    !-- Stable time step suggestion [nblock]
    REAL(wp), ALLOCATABLE :: dt_stable(:)
  END TYPE PH_Elem_VUEL_State

  !-----------------------------------------------------------------------------
  ! PH_Elem_UELMAT_Ctx — UEL-with-embedded-material Ctx
  !   Used when a user element calls standard material routines internally.
  !   Carries PH_Mat_Base_Ctx alongside element-level control flags.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_UELMAT_Ctx
    !-- Embedded material driving context
    TYPE(PH_Mat_Base_Ctx) :: mat_ctx
    !-- UEL element identification
    INTEGER(i4) :: jtype    = 0_i4   ! JTYPE: element type flag
    INTEGER(i4) :: kstep    = 0_i4   ! KSTEP: current step
    INTEGER(i4) :: kinc     = 0_i4   ! KINC: current increment
    !-- Integration flags
    LOGICAL :: compute_mass     = .FALSE.  ! Compute mass matrix?
    LOGICAL :: compute_stiff    = .TRUE.   ! Compute stiffness?
    LOGICAL :: compute_residual = .TRUE.   ! Compute residual?
    INTEGER(i4) :: n_integ_pts  = 0_i4    ! Number of integration points
  END TYPE PH_Elem_UELMAT_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Elem_UELMAT_State — UELMAT element output state
  !   Output arrays produced by a UEL that internally calls CALUM (material).
  !   Separates element structural outputs from material state (owned by UMAT).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_UELMAT_State
    !-- Element structural outputs
    REAL(wp), ALLOCATABLE :: rhs(:,:)      !  O  RHS      residual [ndofel, nrhs]
    REAL(wp), ALLOCATABLE :: amatrx(:,:)   !  O  AMATRX   stiffness [ndofel, ndofel]
    REAL(wp)              :: energy(8) = 0.0_wp  !  O ENERGY 8-slot energy vector

    !-- Material state variables (same storage convention as PH_Elem_Base_State)
    REAL(wp), ALLOCATABLE :: svars(:)      ! IO  SVARS    state vars [nsvars]

    !-- Internal material stress at each integration point (diagnostic)
    !   ipstress(ntens, n_integ_pts) — filled after material calls
    REAL(wp), ALLOCATABLE :: ipstress(:,:)  !  O  [ntens, nip]

    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Elem_UELMAT_State

  !-----------------------------------------------------------------------------
  ! PH_Elem_UEL_Ctx — UEL user-element per-call driving inputs
  !   UEL(RHS, AMATRX, SVARS, ENERGY, NDOFEL, NRHS, NSVARS, PROPS, JTYPE, ...)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_UEL_Ctx
    REAL(wp), POINTER :: coords(:,:)  ! I COORDS   node coordinates [ndim, nnode]
    REAL(wp), POINTER :: u(:)         ! I U        displacements [ndofel]
    REAL(wp), POINTER :: du(:,:)      ! I DU       displacement incr [ndofel, nlgeom+1]
    REAL(wp), POINTER :: v(:)         ! I V        velocities [ndofel] (dynamic)
    REAL(wp), POINTER :: a(:)         ! I A        accelerations [ndofel] (dynamic)
    REAL(wp), POINTER :: predef(:,:)  ! I PREDEF   predefined fields [nfield, nnode]
    REAL(wp), POINTER :: dpred(:,:)   ! I DPRED    predefined field incr
    REAL(wp) :: time(2) = 0.0_wp    ! I TIME(2)  step/total time
    REAL(wp) :: dtime   = 0.0_wp    ! I DTIME    time increment
    INTEGER(i4) :: jtype  = 0_i4    ! I JTYPE    element identifier
    INTEGER(i4) :: ndofel = 0_i4    ! I NDOFEL   no. DOFs
    INTEGER(i4) :: nrhs   = 1_i4    ! I NRHS     no. RHS
    INTEGER(i4) :: nnode  = 0_i4    ! I NNODE    no. nodes
    INTEGER(i4) :: ndim   = 3_i4    ! I NDIM     spatial dimensions
    INTEGER(i4) :: kstep  = 0_i4    ! I KSTEP
    INTEGER(i4) :: kinc   = 0_i4    ! I KINC
    INTEGER(i4) :: noel   = 0_i4    ! I NOEL     element number
    INTEGER(i4) :: lflags(5) = 0_i4 ! I LFLAGS   procedure flags
    INTEGER(i4) :: isym   = 0_i4    ! I ISYM     0=unsymmetric, 1=symmetric
    INTEGER(i4) :: nfield = 0_i4
  END TYPE PH_Elem_UEL_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Elem_UEL_Algo — UEL user-element algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_UEL_Algo
    LOGICAL     :: geom_nonlin   = .FALSE.  ! large-displacement flag
    LOGICAL     :: mass_lump     = .FALSE.  ! lumped mass matrix
    INTEGER(i4) :: integ_rule    = 0_i4    ! 0=default, 1=full, 2=reduced
    INTEGER(i4) :: max_iter_local= 20_i4   ! max local Newton iterations
    REAL(wp)    :: tol_local     = 1.0e-8_wp
  END TYPE PH_Elem_UEL_Algo

  !-----------------------------------------------------------------------------
  ! PH_Elem_VUEL_Algo — VUEL vectorised-UEL algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_VUEL_Algo
    INTEGER(i4) :: nblock_max    = 512_i4  ! max block size
    LOGICAL     :: ave_stress    = .FALSE.  ! average stress output
    LOGICAL     :: geom_nonlin   = .FALSE.
    INTEGER(i4) :: integ_rule    = 0_i4
    REAL(wp)    :: dt_stable_fac = 0.9_wp  ! safety factor on stable dt
  END TYPE PH_Elem_VUEL_Algo

  !-----------------------------------------------------------------------------
  ! PH_Elem_UELMAT_Algo — UELMAT (UEL+CALUM) algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Elem_UELMAT_Algo
    INTEGER(i4) :: max_iter_mat  = 50_i4   ! max material iterations
    REAL(wp)    :: tol_mat       = 1.0e-8_wp
    LOGICAL     :: consistent_tan = .TRUE.  ! use consistent tangent
    LOGICAL     :: geom_nonlin   = .FALSE.
  END TYPE PH_Elem_UELMAT_Algo

  ! ------------------------------------------------------------------ !
  ! PH_Elem_UEL_State_Ext
  !   Extended UEL state carrying additional integration-point level
  !   history arrays beyond the base UEL_State (e.g. accumulated
  !   plastic strains, damage variables, anisotropic back-stresses).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Elem_UEL_State_Ext
    INTEGER(i4)           :: nsvars_ext    = 0_i4   ! extra SDV count
    REAL(wp), ALLOCATABLE :: svars_ext(:)           ! [nsvars_ext] extra SDVs
    REAL(wp), ALLOCATABLE :: stress_ip(:,:)         ! [ntens, nip] stress at IPs
    REAL(wp), ALLOCATABLE :: strain_ip(:,:)         ! [ntens, nip] strain at IPs
    REAL(wp), ALLOCATABLE :: eqpe_ip(:)             ! [nip] equivalent plastic strain
    LOGICAL               :: has_failure    = .FALSE.
    INTEGER(i4)           :: fail_mode      = 0_i4  ! 0=none,1=tensile,2=shear
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Elem_UEL_State_Ext

  ! ------------------------------------------------------------------ !
  ! PH_Elem_VUEL_Ctx
  !   Vectorised UEL driving context: passes a block of elements
  !   simultaneously (VUEL-style batch call).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Elem_VUEL_Ctx
    INTEGER(i4)           :: nelem         = 0_i4   ! block element count
    INTEGER(i4)           :: ndofel        = 0_i4   ! DOF per element
    INTEGER(i4)           :: nrhs          = 0_i4   ! columns in rhs
    REAL(wp), POINTER :: coords(:,:,:)           ! [ndim, nnode, nelem]
    REAL(wp), POINTER :: u(:,:)                  ! [ndofel, nelem] total disp
    REAL(wp), POINTER :: du(:,:)                 ! [ndofel, nelem] disp incr
    REAL(wp), POINTER :: v(:,:)                  ! velocity  (explicit)
    REAL(wp), POINTER :: a(:,:)                  ! acceleration (explicit)
    REAL(wp)              :: dtime    = 0.0_wp
    REAL(wp)              :: time(2)  = 0.0_wp   ! [step time, total time]
    LOGICAL               :: is_explicit = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Elem_VUEL_Ctx

END MODULE PH_Elem_Types
