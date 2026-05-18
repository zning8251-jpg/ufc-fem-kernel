!===============================================================================
! Module: PH_Friction_Types                                      [Template v1.0]
! Layer:  L4_PH — Physical Computation Layer
! Domain: Friction — Ctx / State / Algo types for per-increment friction
!
! Purpose:
!   Defines the full Ctx / State / Algo three-type system for friction
!   computation at the PH_ layer.  Covers:
!   - FRIC       : Standard friction at contact interfaces (Implicit)
!   - VFRIC      : Explicit vectorised friction (block form)
!   - FRIC_COEF  : User-defined friction coefficient (Standard)
!   - VFRIC_COEF : User-defined friction coefficient (Explicit)
!
! Design principle:
!   Each Abaqus friction routine → one dedicated Ctx type.
!   State captures slip history and traction outputs.
!   Algo controls regularisation and iteration parameters.
!
! Abaqus parameter map:
!   SLIP1/SLIP2    → slip1 / slip2       tangential slip magnitudes
!   DSLIP1/DSLIP2  → dslip1 / dslip2    slip increments
!   TAUMAX         → tau_max             limiting shear stress
!   PNEWDT         → (bare REAL INOUT)   time step suggestion
!   NOEL           → elem_id             contact element
!   NPT            → integ_pt_id         integration point
!
! Layer dependency:
!   USE IF_Prec      (wp, i4)
!   USE IF_Err_Brg   (structured ErrorStatusType status; baseline vocabulary:
!                     init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE PH_Friction_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Fric_Base_Ctx
  PUBLIC :: PH_Fric_Base_State
  PUBLIC :: PH_Fric_Base_Algo
  PUBLIC :: PH_Fric_VFRIC_Ctx
  PUBLIC :: PH_Fric_Coef_Ctx

  !-----------------------------------------------------------------------------
  ! CTX — Friction Computation Context (per-increment driving inputs)
  !   FRIC subroutine: called once per contact integration point
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_Base_Ctx
    !-- Slip kinematic inputs
    REAL(wp) :: slip1  = 0.0_wp    ! SLIP1:  slip in tangent dir 1 [m]
    REAL(wp) :: slip2  = 0.0_wp    ! SLIP2:  slip in tangent dir 2 [m]
    REAL(wp) :: dslip1 = 0.0_wp    ! DSLIP1: slip increment dir 1 [m]
    REAL(wp) :: dslip2 = 0.0_wp    ! DSLIP2: slip increment dir 2 [m]
    !-- Contact conditions
    REAL(wp) :: pressure = 0.0_wp  ! Normal contact pressure [Pa]
    REAL(wp) :: temp     = 0.0_wp  ! Contact temperature [K]
    REAL(wp) :: dtemp    = 0.0_wp  ! Temperature increment [K]
    !-- Limiting shear stress (from material/surface definition)
    REAL(wp) :: tau_max  = 0.0_wp  ! TAUMAX: max shear stress [Pa] (0=no limit)
    !-- Contact point geometry
    REAL(wp) :: coords(3) = 0.0_wp ! Contact point coordinates
    !-- Identification
    INTEGER(i4) :: elem_id      = 0_i4  ! NOEL: contact element
    INTEGER(i4) :: integ_pt_id  = 0_i4  ! NPT: integration point
    INTEGER(i4) :: kstep        = 0_i4  ! KSTEP: step number
    INTEGER(i4) :: kinc         = 0_i4  ! KINC: increment number
    !-- State variables (solution-dependent, from previous increment)
    REAL(wp), POINTER :: svars(:)   ! STATEV [nstatv]
    INTEGER(i4) :: nstatv = 0_i4
  END TYPE PH_Fric_Base_Ctx

  !-----------------------------------------------------------------------------
  ! STATE — Friction Computation Output
  !   FRIC returns traction and Jacobian contributions
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_Base_State
    !-- Tangential traction output
    REAL(wp) :: tau1 = 0.0_wp      ! Shear traction in dir 1 [Pa]
    REAL(wp) :: tau2 = 0.0_wp      ! Shear traction in dir 2 [Pa]
    !-- Jacobian d(tau)/d(slip)
    REAL(wp) :: dtau1_dslip1 = 0.0_wp  ! Frictional stiffness dir-1
    REAL(wp) :: dtau2_dslip2 = 0.0_wp  ! Frictional stiffness dir-2
    REAL(wp) :: dtau1_dslip2 = 0.0_wp  ! Off-diagonal coupling
    REAL(wp) :: dtau2_dslip1 = 0.0_wp  ! Off-diagonal coupling
    !-- d(tau)/d(pressure)
    REAL(wp) :: dtau1_dpres  = 0.0_wp
    REAL(wp) :: dtau2_dpres  = 0.0_wp
    !-- Updated state variables
    REAL(wp), ALLOCATABLE :: svars(:)   ! Updated STATEV [nstatv]
    !-- Slip status
    LOGICAL  :: is_sliding = .FALSE.    ! .TRUE. if currently sliding
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Per-Increment Algorithm Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_Base_Algo
    !-- Regularisation
    REAL(wp)    :: elastic_slip_tol = 1.0e-4_wp  ! Elastic slip regularisation [m]
    REAL(wp)    :: tau_tol          = 1.0e-3_wp  ! Traction convergence tol [Pa]
    !-- Iteration control
    INTEGER(i4) :: max_iter  = 30       ! Maximum friction iterations
    REAL(wp)    :: tolerance = 1.0e-6_wp
    !-- Time-step suggestion
    REAL(wp) :: pnewdt_min = 0.1_wp
    REAL(wp) :: pnewdt_max = 2.0_wp
    !-- Return mapping
    LOGICAL  :: use_return_mapping = .TRUE.  ! Radial return for Coulomb cone
  END TYPE PH_Fric_Base_Algo

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRIC_Ctx — VFRIC/VFRIC_COEF (Explicit block) driving inputs
  !   All arrays have first dimension = nblock
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRIC_Ctx
    INTEGER(i4) :: nblock = 1_i4     ! NBLOCK: block size
    INTEGER(i4) :: nstatv = 0_i4     ! NSTATV: state variable count
    !-- Block kinematic arrays [nblock]
    REAL(wp), POINTER :: slip1_blk(:)    ! Slip dir-1
    REAL(wp), POINTER :: slip2_blk(:)    ! Slip dir-2
    REAL(wp), POINTER :: dslip1_blk(:)   ! Slip increment dir-1
    REAL(wp), POINTER :: dslip2_blk(:)   ! Slip increment dir-2
    REAL(wp), POINTER :: pres_blk(:)     ! Normal pressure [nblock]
    REAL(wp), POINTER :: temp_blk(:)     ! Temperature [nblock]
    REAL(wp), POINTER :: tau_max_blk(:)  ! Max shear stress [nblock]
    !-- State variables block [nblock, nstatv]
    REAL(wp), POINTER :: svars_blk(:,:)
  END TYPE PH_Fric_VFRIC_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Fric_Coef_Ctx — FRIC_COEF / VFRIC_COEF: user friction coefficient
  !   Simpler than FRIC: only computes mu (scalar), not full traction.
  !   FRIC_COEF is called before Abaqus applies standard Coulomb law.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_Coef_Ctx
    !-- Standard inputs
    REAL(wp) :: slip1    = 0.0_wp    ! Accumulated slip dir-1 [m]
    REAL(wp) :: slip2    = 0.0_wp    ! Accumulated slip dir-2 [m]
    REAL(wp) :: slip_rate = 0.0_wp   ! Slip rate magnitude [m/s]
    REAL(wp) :: pressure  = 0.0_wp   ! Normal pressure [Pa]
    REAL(wp) :: temp      = 0.0_wp   ! Contact temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! Contact point coordinates
    INTEGER(i4) :: elem_id = 0_i4
    INTEGER(i4) :: integ_pt_id = 0_i4
    !-- Block support (for VFRIC_COEF)
    INTEGER(i4) :: nblock = 1_i4
    REAL(wp), POINTER :: slip_rate_blk(:)  ! [nblock]
    REAL(wp), POINTER :: pres_blk(:)       ! [nblock]
    REAL(wp), POINTER :: temp_blk(:)       ! [nblock]
    !-- Output: computed friction coefficient
    REAL(wp) :: mu       = 0.0_wp    ! Friction coefficient μ (output)
    REAL(wp), POINTER :: mu_blk(:) ! [nblock] for VFRIC_COEF
    REAL(wp) :: dmu_dp   = 0.0_wp    ! dμ/d(pressure)
    REAL(wp) :: dmu_dT   = 0.0_wp    ! dμ/d(temperature)
  END TYPE PH_Fric_Coef_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Fric_FRIC_State — FRIC (Standard) friction output state
  !   FRIC: shear traction + Jacobian written back for Implicit contact
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_FRIC_State
    REAL(wp) :: tau1      = 0.0_wp      ! OUT: shear traction dir-1 [Pa]
    REAL(wp) :: tau2      = 0.0_wp      ! OUT: shear traction dir-2 [Pa]
    REAL(wp) :: dtau1_dslip1 = 0.0_wp  ! OUT: frictional stiffness K11
    REAL(wp) :: dtau2_dslip2 = 0.0_wp  ! OUT: frictional stiffness K22
    REAL(wp) :: dtau1_dslip2 = 0.0_wp  ! OUT: coupling K12
    REAL(wp) :: dtau2_dslip1 = 0.0_wp  ! OUT: coupling K21
    REAL(wp), ALLOCATABLE :: svars(:)  ! IO:  state variables [nsvars]
    LOGICAL :: is_sliding  = .FALSE.    ! Sliding vs stick status
    LOGICAL :: converged   = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_FRIC_State

  !-----------------------------------------------------------------------------
  ! PH_Fric_FRIC_Ctx — FRIC Standard friction per-call driving Ctx
  !   Carries slip rates, pressure, temperature at the contact point
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_FRIC_Ctx
    REAL(wp) :: slip1     = 0.0_wp   ! I SLIP1: slip increment in dir-1 [m]
    REAL(wp) :: slip2     = 0.0_wp   ! I SLIP2: slip increment in dir-2
    REAL(wp) :: sliprate1 = 0.0_wp   ! I slip rate in dir-1 [m/s]
    REAL(wp) :: sliprate2 = 0.0_wp   ! I slip rate in dir-2
    REAL(wp) :: pressure  = 0.0_wp   ! I contact normal pressure [Pa]
    REAL(wp) :: temp      = 0.0_wp   ! I contact temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! I contact point coords
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
    REAL(wp) :: time_step  = 0.0_wp
    REAL(wp) :: time_total = 0.0_wp
  END TYPE PH_Fric_FRIC_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRIC_State — VFRIC (Explicit block) friction output state
  !   Block form of shear tractions for nblock contact pairs
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRIC_State
    REAL(wp), ALLOCATABLE :: tau1_blk(:)          ! [nblock] traction dir-1
    REAL(wp), ALLOCATABLE :: tau2_blk(:)          ! [nblock] traction dir-2
    REAL(wp), ALLOCATABLE :: dtau1_dslip1_blk(:)  ! [nblock] K11
    REAL(wp), ALLOCATABLE :: dtau2_dslip2_blk(:)  ! [nblock] K22
    REAL(wp), ALLOCATABLE :: svars_blk(:,:)       ! [nblock, nsvars]
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_VFRIC_State

  !-----------------------------------------------------------------------------
  ! PH_Fric_FRIC_COEF_State — FRIC_COEF scalar friction coefficient output
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_FRIC_COEF_State
    REAL(wp) :: mu        = 0.0_wp  ! OUT: friction coefficient μ
    REAL(wp) :: dmu_dp    = 0.0_wp  ! OUT: dμ/d(pressure)
    REAL(wp) :: dmu_dT    = 0.0_wp  ! OUT: dμ/d(temperature)
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_FRIC_COEF_State

  !-----------------------------------------------------------------------------
  ! PH_Fric_FRIC_Algo — FRIC Coulomb/user friction algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_FRIC_Algo
    INTEGER(i4) :: max_iter   = 10_i4
    REAL(wp)    :: tol_slip   = 1.0e-8_wp  ! slip increment tolerance
    LOGICAL     :: regularise = .FALSE.    ! regularised friction
    REAL(wp)    :: reg_slope  = 1.0e3_wp   ! regularisation slope
  END TYPE PH_Fric_FRIC_Algo

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRIC_Algo — VFRIC vectorised friction algorithm parameters
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRIC_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: regularise = .FALSE.
    REAL(wp)    :: reg_slope  = 1.0e3_wp
  END TYPE PH_Fric_VFRIC_Algo

  !-----------------------------------------------------------------------------
  ! PH_Fric_FRIC_COEF_Algo — FRIC_COEF friction coefficient algorithm
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_FRIC_COEF_Algo
    LOGICAL     :: pressure_dep = .FALSE.  ! pressure-dependent μ
    LOGICAL     :: temp_dep     = .FALSE.  ! temperature-dependent μ
    REAL(wp)    :: mu_min       = 0.0_wp   ! minimum coefficient
    REAL(wp)    :: mu_max       = 1.0_wp   ! maximum coefficient
  END TYPE PH_Fric_FRIC_COEF_Algo

  !=============================================================================
  ! VFRICTION — New-style vectorised friction subroutine (Abaqus 6.14+, Explicit)
  !   VFRICTION supersedes VFRIC in newer Abaqus versions.  It passes the
  !   full contact state as a block (nblock material points) and supports
  !   anisotropic friction and conduction at contact.
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRICTION_Ctx
  !   Vectorised driving input for the new-style VFRICTION interface.
  !   All arrays are dimensioned [nblock, ...] for block processing.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRICTION_Ctx
    INTEGER(i4)           :: nblock     = 0_i4   ! contact points in this block
    INTEGER(i4)           :: nfdir      = 2_i4   ! friction directions (1 or 2)
    REAL(wp)              :: dtime      = 0.0_wp  ! time increment
    !-- Contact kinematics
    REAL(wp), POINTER :: slip(:,:)            ! [nblock, nfdir] cumulative slip
    REAL(wp), POINTER :: dslip(:,:)           ! [nblock, nfdir] slip increment
    REAL(wp), POINTER :: pressure(:)          ! [nblock] contact normal pressure
    !-- Thermal
    REAL(wp), POINTER :: temp(:)              ! [nblock] surface temperature
    REAL(wp), POINTER :: dtemp(:)             ! [nblock] temperature increment
    !-- SDVs
    INTEGER(i4)           :: nstatv     = 0_i4
    REAL(wp), POINTER :: statev_prev(:,:)      ! [nblock, nstatv] SDVs at start
    !-- Properties
    INTEGER(i4)           :: nprops     = 0_i4
    REAL(wp), POINTER :: props(:)             ! [nprops] friction constants
    CHARACTER(LEN=8)      :: cmname     = ' '     ! interaction property name
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_VFRICTION_Ctx

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRICTION_State
  !   Outputs from VFRICTION: friction traction, tangent, updated SDVs.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRICTION_State
    REAL(wp), ALLOCATABLE :: traction(:,:)    ! [nblock, nfdir] O tangential traction
    REAL(wp), ALLOCATABLE :: dtraction_dp(:,:)! [nblock, nfdir] O dtraction/dpressure
    REAL(wp), ALLOCATABLE :: dtraction_dslip(:,:,:) ! [nblock, nfdir, nfdir] O tangent
    REAL(wp), ALLOCATABLE :: statev_curr(:,:)  ! [nblock, nstatv] O updated SDVs
    REAL(wp), ALLOCATABLE :: pnewdt(:)        ! [nblock] O time-step suggestion
    LOGICAL               :: is_updated = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_VFRICTION_State

  !-----------------------------------------------------------------------------
  ! PH_Fric_VFRICTION_Algo
  !   Algorithmic parameters for the VFRICTION block-processing loop.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_Fric_VFRICTION_Algo
    LOGICAL     :: anisotropic         = .FALSE.  ! anisotropic friction directions
    LOGICAL     :: pressure_dep        = .FALSE.  ! μ depends on contact pressure
    LOGICAL     :: temperature_dep     = .FALSE.  ! μ depends on temperature
    LOGICAL     :: provide_full_tangent = .FALSE.  ! fill dtraction_dslip matrix
    REAL(wp)    :: stick_tol           = 1.0e-10_wp! stick/slip switch tolerance
    REAL(wp)    :: tau_limit           = 1.0e30_wp ! maximum shear traction
    INTEGER(i4) :: regularisation_type = 0_i4     ! 0=penalty, 1=Lagrange
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Fric_VFRICTION_Algo

END MODULE PH_Friction_Types
