!===============================================================================
! Module: MD_Field_Types                                         [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Field — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for field variable
!   management at the MD_ (model-description) layer.
!
!   Abaqus subroutines covered:
!     - USDFLD / VUSDFLD : User-defined field variables (Standard/Explicit)
!     - UFIELD           : User-defined initial field conditions
!     - SDVINI           : User-defined initial solution-dependent variables
!     - SIGINI           : User-defined initial stress field
!
!   Design notes (see memory: L4 Field域存在性):
!     - L3_MD does NOT compute field evolution; it only holds metadata,
!       declaration and registration of field variables
!     - Physical field evolution (diffusion, phase change, damage) lives in L4_PH
!     - L3 manages: how many fields, what they represent, initial values
!
!   Field variable concept in Abaqus:
!     - USDFLD replaces material properties with spatially-varying values
!     - Called at every material point each increment
!     - Access via GETVRM utility to read result variables
!
! Type roles:
!   MD_Field_Base_Desc  – Field variable metadata (name, count, initial values)
!   MD_Field_Base_State – Field variable history at increment start
!   MD_Field_Base_Algo  – Field update configuration
!   MD_Field_SDVINI_Desc – SDVINI-specific: initial SDV definition
!   MD_Field_SIGINI_Desc – SIGINI-specific: initial stress field
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Field_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Field_Base_Desc
  PUBLIC :: MD_Field_Base_State
  PUBLIC :: MD_Field_Base_Algo
  PUBLIC :: MD_Field_SDVINI_Desc
  PUBLIC :: MD_Field_SIGINI_Desc
  PUBLIC :: MD_Field_USDFLD_Desc
  PUBLIC :: MD_Field_UFIELD_Desc
  PUBLIC :: MD_Field_UVARM_Desc

  !-- Field type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_TYPE_SCALAR   = 1_i4  ! Scalar field variable  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_TYPE_VECTOR   = 2_i4  ! Vector field  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_TYPE_TENSOR   = 3_i4  ! Tensor field  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_TYPE_SDV      = 4_i4  ! Solution-dep. variable  ! migrated

  !-- Subroutine type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_SUBRT_USDFLD  = 1_i4  ! USDFLD (Standard)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_SUBRT_VUSDFLD = 2_i4  ! VUSDFLD (Explicit)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_SUBRT_UFIELD  = 3_i4  ! UFIELD  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_SUBRT_SDVINI  = 4_i4  ! SDVINI  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FIELD_FIELD_SUBRT_SIGINI  = 5_i4  ! SIGINI  ! migrated

  !-----------------------------------------------------------------------------
  ! DESC — Field Variable Descriptor
  !    Metadata for all field variables used in the model.
  !    USDFLD signature: FIELD(NFIELD), STATEV(NSTATV), PNEWDT,
  !                      DIRECT(3,3), T(3,3), STRESSVEC(NTENS)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: field_id    = 0_i4   ! Field set identifier
    INTEGER(i4)       :: field_type  = MD_FIELD_FIELD_TYPE_SCALAR
    INTEGER(i4)       :: subrt_type  = MD_FIELD_FIELD_SUBRT_USDFLD
    CHARACTER(LEN=64) :: field_name  = ''     ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Field variable count
    INTEGER(i4) :: nfield      = 0_i4  ! NFIELD: number of field variables
    INTEGER(i4) :: nstatv      = 0_i4  ! NSTATV: number of solution-dep. state vars
    !-- Initial field values
    REAL(wp), ALLOCATABLE :: field_init(:)    ! Initial values for each field variable
    !-- Material name (for GETVRM dispatch)
    CHARACTER(LEN=80) :: cmname   = ''    ! Material name (CMNAME)
    !-- Coordinate system
    INTEGER(i4) :: csys_type    = 0_i4  ! 0=global, 1=cylindrical, 2=spherical
    !-- Temperature dependence
    LOGICAL :: temp_depend      = .FALSE.  ! Fields are temperature-dependent
  CONTAINS
    PROCEDURE :: Init  => Field_Desc_Init
    PROCEDURE :: Reset => Field_Desc_Reset
  END TYPE MD_Field_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — Field Variable State at Increment Start
  !    Field variable history at the start of each increment.
  !    Holds the "known" field values from the previous increment.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_Base_State
    !-- Field variable values at start of increment
    REAL(wp), ALLOCATABLE :: field_prev(:)   ! Field values at start [nfield]
    REAL(wp), ALLOCATABLE :: dfield(:)       ! Field increments this step [nfield]
    !-- Solution-dependent variables (SDVs)
    REAL(wp), ALLOCATABLE :: statev(:)       ! SDV array [nstatv]
    !-- Spatial context
    REAL(wp) :: direct(3,3)  = 0.0_wp  ! Direction cosines of material orientation
    REAL(wp) :: T_tens(3,3)  = 0.0_wp  ! Orientation tensor T
    REAL(wp) :: stress(6)    = 0.0_wp  ! Current stress tensor (Voigt) [Pa]
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Field_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Field Update Configuration
  !    Controls how field variables are updated and interpolated.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_Base_Algo
    !-- Update scheme
    INTEGER(i4) :: update_scheme  = 1_i4   ! 1=explicit, 2=implicit, 3=staggered
    !-- Interpolation
    INTEGER(i4) :: interp_order   = 1_i4   ! 1=linear, 2=quadratic
    !-- Convergence
    REAL(wp)    :: tol_field      = 1.0e-6_wp ! Field convergence tolerance
    INTEGER(i4) :: max_iter       = 20_i4   ! Max field update iterations
    !-- Coupling
    LOGICAL :: thermo_mech_couple = .FALSE. ! Thermo-mechanical coupling active
    !-- Output
    LOGICAL :: print_debug        = .FALSE.
  END TYPE MD_Field_Base_Algo

  !-----------------------------------------------------------------------------
  ! SDVINI-specific Desc: initial solution-dependent state variables
  !   SDVINI: initializes STATEV array at start of analysis
  !   Called ONCE per material point at initialization
  !   Parameters: STATEV(NSTATV), COORDS(3), NSTATV, NCRDS, JELEM, NPT, LAYER, KSPT
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_SDVINI_Desc
    INTEGER(i4) :: nstatv         = 0_i4    ! Number of SDVs to initialize
    REAL(wp), ALLOCATABLE :: sdv_init(:)    ! Initial SDV values [nstatv]
    INTEGER(i4) :: init_scheme    = 1_i4    ! 1=uniform, 2=position-based, 3=user
    CHARACTER(LEN=80) :: cmname   = ''      ! Material name for dispatch
  END TYPE MD_Field_SDVINI_Desc

  !-----------------------------------------------------------------------------
  ! SIGINI-specific Desc: initial stress field
  !   SIGINI: provides initial stress at each material point
  !   Called at start of step-1 (geostatic or pre-stress)
  !   Parameters: SIGMA(NTENS), COORDS(3), NTENS, NCRDS, LAYER, KSPT, LREBAR, NAMES
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_SIGINI_Desc
    INTEGER(i4) :: ntens          = 6_i4    ! Voigt components (3D: 6)
    REAL(wp)    :: sigma_init(6)  = 0.0_wp  ! Initial stress [Pa] (Voigt)
    INTEGER(i4) :: init_type      = 1_i4    ! 1=uniform, 2=gravity, 3=user
    REAL(wp)    :: gravity_dir(3) = [0.0_wp, -1.0_wp, 0.0_wp] ! Gravity direction
    REAL(wp)    :: gravity_mag    = 9.81_wp ! Gravity magnitude [m/s²]
    REAL(wp)    :: rho_ref        = 0.0_wp  ! Reference density for geostatic [kg/m³]
  END TYPE MD_Field_SIGINI_Desc

  !-----------------------------------------------------------------------------
  ! USDFLD-specific Desc: user-defined field variable
  !   *USER DEFINED FIELD (called at each material point)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_USDFLD_Desc
    INTEGER(i4) :: nfield    = 0_i4
    INTEGER(i4) :: nstatv    = 0_i4
    LOGICAL     :: is_active = .FALSE.
  END TYPE MD_Field_USDFLD_Desc

  !-----------------------------------------------------------------------------
  ! UFIELD-specific Desc: initial predefined field
  !   *INITIAL CONDITIONS, TYPE=FIELD
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_UFIELD_Desc
    INTEGER(i4) :: nfield    = 0_i4
    LOGICAL     :: spatial   = .TRUE.
    LOGICAL     :: is_active = .FALSE.
  END TYPE MD_Field_UFIELD_Desc

  !-----------------------------------------------------------------------------
  ! UVARM-specific Desc: user-defined output variable
  !   *USER OUTPUT VARIABLES
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Field_UVARM_Desc
    INTEGER(i4)           :: nuvarm     = 0_i4
    INTEGER(i4), ALLOCATABLE :: var_ids(:)
    CHARACTER(LEN=8), ALLOCATABLE :: var_keys(:)
    LOGICAL               :: at_nodes   = .FALSE.
    LOGICAL               :: is_active  = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Field_UVARM_Desc

CONTAINS

  SUBROUTINE Field_Desc_Init(self)
    CLASS(MD_Field_Base_Desc), INTENT(INOUT) :: self
    IF (self%nfield > 0 .AND. .NOT. ALLOCATED(self%field_init)) THEN
      ALLOCATE(self%field_init(self%nfield))
      self%field_init = 0.0_wp
    END IF
    self%is_initialized = .TRUE.
  END SUBROUTINE Field_Desc_Init

  SUBROUTINE Field_Desc_Reset(self)
    CLASS(MD_Field_Base_Desc), INTENT(INOUT) :: self
    IF (ALLOCATED(self%field_init)) DEALLOCATE(self%field_init)
    self%field_id   = 0
    self%nfield     = 0
    self%nstatv     = 0
    self%cmname     = ''
    self%is_initialized = .FALSE.
  END SUBROUTINE Field_Desc_Reset

END MODULE MD_Field_Types
