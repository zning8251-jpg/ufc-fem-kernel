!===============================================================================
! Module: MD_Contact_Types                                        [Template v1.1]
! Layer:  L3_MD �?Model Description Layer
! Domain: Contact �?Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for contact
!   computation at the MD_ (model-description) layer.
!
!   v1.1 additions:
!   - Added: MD_Contact_GAPCON_Desc   (GAPCON: gap thermal conductance)
!   - Added: MD_Contact_GAPELECTR_Desc(GAPELECTR: gap electrical conductance)
!   - Enum now covers: UINTER/VUINTER/UFRIC/VUFRIC/UCOUL/VCOUL/GAPCON/GAPELECTR
!   - Baseline refresh: comments aligned to IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!
!   Supported contact types (UFC contract):
!     - UINTER / VUINTER : Full contact interaction (normal + tangential)
!     - UFRIC / VUFRIC   : Friction only
!     - UCOUL / VCOUL    : Coulomb friction critical shear stress
!     - GAPCON           : Gap thermal/electrical conductance
!     - GAPELECTR        : Gap electrical conductance
!
! Type roles:
!   MD_Contact_Base_Desc   �?Contact pair parameters & identity
!   MD_Contact_Base_State �?Contact state at increment start
!   MD_Contact_Base_Algo  �?Analysis-phase configuration
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Contact_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Contact_Base_Desc
  PUBLIC :: MD_Contact_Base_State
  PUBLIC :: MD_Contact_Base_Algo
  PUBLIC :: MD_Contact_GAPCON_Desc
  PUBLIC :: MD_Contact_GAPELECTR_Desc
  PUBLIC :: MD_Contact_UINTER_Desc
  PUBLIC :: MD_Contact_GAPUNIT_Desc

  !-----------------------------------------------------------------------------
  ! Contact family enum
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: &
    CONTACT_FAMILY_FULL    = 1,  ! UINTER/VUINTER: full interaction
    CONTACT_FAMILY_FRIC    = 2,  ! UFRIC/VUFRIC: friction only
    CONTACT_FAMILY_COUL    = 3,  ! UCOUL/VCOUL: Coulomb shear
    CONTACT_FAMILY_GAP     = 4,  ! GAPCON: gap thermal conductance
    CONTACT_FAMILY_GAPELEC = 5   ! GAPELECTR: gap electrical conductance
  !-----------------------------------------------------------------------------
  ! DESC �?Contact Descriptor
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: contact_id   = 0    ! Contact pair identifier
    INTEGER(i4)       :: contact_family = 0   ! CONTACT_FAMILY_XXX enum
    CHARACTER(LEN=64) :: contact_name = ''   ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Contact pair configuration
    INTEGER(i4) :: master_surface = 0    ! Master surface ID
    INTEGER(i4) :: slave_surface = 0     ! Slave surface ID
    !-- Normal contact behavior
    INTEGER(i4) :: normal_behavior = 0   ! 1=hard, 2=penalty, 3=exp
    REAL(wp)    :: normal_stiffness = 0.0_wp  ! Penalty stiffness
    !-- Friction behavior
    INTEGER(i4) :: fric_law = 0           ! 1=Coulomb, 2=shear, 3=user
    REAL(wp)    :: fric_coeff = 0.0_wp    ! Friction coefficient
    REAL(wp)    :: shear_limit = 0.0_wp   ! Critical shear stress
    !-- Advanced options
    REAL(wp) :: contact_threshold = 0.0_wp  ! Gap tolerance
    INTEGER(i4) :: max_iter = 50           ! Contact iterations
  CONTAINS
    PROCEDURE :: Init   => Contact_Desc_Init
    PROCEDURE :: Reset  => Contact_Desc_Reset
  END TYPE MD_Contact_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE �?Contact State at Increment Start
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_Base_State
    !-- Contact history
    REAL(wp) :: gap_history = 0.0_wp      ! Previous gap
    REAL(wp) :: slip_accumulated = 0.0_wp ! Accumulated slip
    REAL(wp) :: pressure_cumulative = 0.0_wp ! Cumulative contact pressure
    !-- Energy
    REAL(wp) :: energy_dissipated = 0.0_wp ! Friction dissipation
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Contact_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO �?Analysis-Phase Configuration
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_Base_Algo
    !-- Contact algorithm
    INTEGER(i4) :: algorithm = 1     ! 1=penalty, 2=lagrange, 3=augmented
    LOGICAL :: use_stabilization = .FALSE. ! Stabilization
    REAL(wp) :: stabilization_factor = 0.0_wp
    !-- Output control
    LOGICAL :: print_debug = .FALSE. ! Enable debug output
  END TYPE MD_Contact_Base_Algo

  !-----------------------------------------------------------------------------
  ! GAPCON-specific Desc: gap thermal conductance
  !   GAPCON: defines thermal conductance as function of gap/pressure/temp
  !   Parameters: DGAP (gap clearance), PRES, TEMP, SVARS, NSVARS
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_GAPCON_Desc
    REAL(wp)    :: k_cond_ref  = 0.0_wp  ! Reference conductance [W/(m²·K)]
    REAL(wp)    :: gap_crit    = 0.0_wp  ! Critical gap below which cond. applies [m]
    INTEGER(i4) :: nstatv      = 0_i4   ! Number of state variables
    LOGICAL     :: pres_depend = .FALSE. ! Conductance is pressure-dependent
    LOGICAL     :: temp_depend = .FALSE. ! Conductance is temperature-dependent
  END TYPE MD_Contact_GAPCON_Desc

  !-----------------------------------------------------------------------------
  ! GAPELECTR-specific Desc: gap electrical conductance
  !   GAPELECTR: defines electrical conductance as function of gap
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_GAPELECTR_Desc
    REAL(wp)    :: sigma_ref   = 0.0_wp  ! Reference electrical conductance [S/m²]
    REAL(wp)    :: gap_crit    = 0.0_wp  ! Critical gap [m]
    LOGICAL     :: temp_depend = .FALSE. ! Conductance is temperature-dependent
  END TYPE MD_Contact_GAPELECTR_Desc

  !-----------------------------------------------------------------------------
  ! UINTER-specific Desc: user contact interaction
  !   *SURFACE INTERACTION + *USER INTERFACE
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_UINTER_Desc
    CHARACTER(LEN=80) :: inter_name = ' '
    INTEGER(i4) :: nprops   = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: nstatv   = 0_i4
    LOGICAL     :: thermal  = .FALSE.
    LOGICAL     :: is_active= .FALSE.
  END TYPE MD_Contact_UINTER_Desc

  !-----------------------------------------------------------------------------
  ! GAPUNIT-specific Desc: gap radiation
  !   *SURFACE INTERACTION + *GAP RADIATION
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Contact_GAPUNIT_Desc
    CHARACTER(LEN=80) :: inter_name = ' '
    REAL(wp)    :: emissivity  = 0.0_wp
    REAL(wp)    :: boltzmann   = 5.67e-8_wp
    LOGICAL     :: is_active   = .FALSE.
  END TYPE MD_Contact_GAPUNIT_Desc

CONTAINS

  SUBROUTINE Contact_Desc_Init(self)
    CLASS(MD_Contact_Base_Desc), INTENT(INOUT) :: self
    self%is_initialized = .TRUE.
  END SUBROUTINE Contact_Desc_Init

  SUBROUTINE Contact_Desc_Reset(self)
    CLASS(MD_Contact_Base_Desc), INTENT(INOUT) :: self
    self%contact_id = 0
    self%contact_family = 0
    self%contact_name = ''
    self%master_surface = 0
    self%slave_surface = 0
    self%normal_behavior = 0
    self%normal_stiffness = 0.0_wp
    self%fric_law = 0
    self%fric_coeff = 0.0_wp
    self%shear_limit = 0.0_wp
    self%contact_threshold = 0.0_wp
    self%max_iter = 50
    self%is_initialized = .FALSE.
  END SUBROUTINE Contact_Desc_Reset

END MODULE MD_Contact_Types
