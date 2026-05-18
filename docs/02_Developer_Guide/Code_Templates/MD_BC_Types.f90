!===============================================================================
! Module: MD_BC_Types                                            [Template v1.1]
! Layer:  L3_MD — Model Description Layer
! Domain: Boundary Condition — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for boundary condition
!   computation at the MD_ (model-description) layer.
!
!   v1.1 additions:
!   - Added: BC family enum constants covering ALL Abaqus BC subroutines
!   - Added: MD_BC_UPOT_Desc    (UPOT: multi-field potential BC)
!   - Added: MD_BC_UTEMP_Desc   (UTEMP: user temperature field)
!   - Added: MD_BC_UMASFL_Desc  (UMASFL: user mass flow rate)
!   - Baseline refresh: comments aligned to IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!
!   Supported BC types (UFC contract):
!     - DISP / VDISP   : Displacement/velocity/acceleration boundary
!     - UPOT           : Multi-field potential (pore pressure, electrical)
!     - UTEMP          : Temperature boundary condition
!     - UMASFL         : Mass flow rate boundary (CFD)
!
! Type roles:
!   MD_BC_Base_Desc   – BC parameters & identity
!   MD_BC_Base_State – BC state at increment start
!   MD_BC_Base_Algo  – Analysis-phase configuration
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_BC_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE UFC_FEM_Symbols, ONLY: &
    MD_BC_FIELD_DISP, MD_BC_FIELD_VEL, MD_BC_FIELD_ACC, &
    MD_BC_FIELD_POT, MD_BC_FIELD_TEMP, MD_BC_FIELD_MASFL, &
    RT_BC_CONSTRAIN_FIXED, RT_BC_CONSTRAIN_PRESCRIBED, &
    BC_FIELD_TO_CONSTRAIN
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_BC_Base_Desc
  PUBLIC :: MD_BC_Base_State
  PUBLIC :: MD_BC_Base_Algo
  PUBLIC :: MD_BC_UPOT_Desc
  PUBLIC :: MD_BC_UTEMP_Desc
  PUBLIC :: MD_BC_UMASFL_Desc

  !-----------------------------------------------------------------------------
  ! BC family enum (DEPRECATED - use UFC_FEM_Symbols constants)
  ! Note: BC_FAMILY_DISP etc. now provided by UFC_FEM_Symbols for cross-layer compatibility
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: &
    BC_FAMILY_DISP   = 1,  ! DISP/VDISP: displacement boundary (Standard/Explicit)
    BC_FAMILY_VEL    = 2,  ! Velocity boundary
    BC_FAMILY_ACC    = 3,  ! Acceleration boundary
    BC_FAMILY_POT    = 4,  ! UPOT: multi-field potential
    BC_FAMILY_TEMP   = 5,  ! UTEMP: temperature boundary
    BC_FAMILY_MASFL  = 6   ! UMASFL: mass flow rate boundary

  !-----------------------------------------------------------------------------
  ! DESC — BC Descriptor
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: bc_id   = 0    ! BC identifier
    INTEGER(i4)       :: bc_family = MD_BC_FIELD_DISP ! BC_FAMILY_XXX enum (from UFC_FEM_Symbols)
    CHARACTER(LEN=64) :: bc_name = ''  ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- BC parameters
    INTEGER(i4) :: node_set_id = 0    ! Target node set
    INTEGER(i4) :: dof_start = DOF_UX     ! Starting DOF (1=UX, use DOF_UX from UFC_FEM_Symbols)
    INTEGER(i4) :: dof_end = DOF_RZ       ! Ending DOF (6=RZ, use DOF_RZ from UFC_FEM_Symbols)
    !-- Displacement boundary specific
    INTEGER(i4) :: bc_type = RT_BC_CONSTRAIN_FIXED ! Use UFC_FEM_Symbols constants
    REAL(wp) :: magnitude = 0.0_wp    ! Prescribed magnitude
    INTEGER(i4) :: amplitude_id = 0  ! Amplitude table ID (0=none)
    !-- Multi-field potential specific
    INTEGER(i4) :: field_type = 0     ! 1=scalar, 2=vector, 3=matrix
  CONTAINS
    PROCEDURE :: Init   => BC_Desc_Init
    PROCEDURE :: Reset  => BC_Desc_Reset
  END TYPE MD_BC_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — BC State at Increment Start
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_Base_State
    !-- BC history
    REAL(wp) :: accumulated = 0.0_wp  ! Accumulated displacement history
    REAL(wp) :: last_value = 0.0_wp    ! Value at previous increment
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_BC_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Analysis-Phase Configuration
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_Base_Algo
    !-- Application mode
    INTEGER(i4) :: apply_mode = 1    ! 1=direct, 2=time-dependent
    !-- Output control
    LOGICAL :: print_debug = .FALSE. ! Enable debug output
  END TYPE MD_BC_Base_Algo

  !-----------------------------------------------------------------------------
  ! UPOT-specific Desc: multi-field potential boundary
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UPOT_Desc
    INTEGER(i4) :: field_id    = 0_i4   ! 1=pore pressure, 2=electrical
    REAL(wp)    :: pot_ref     = 0.0_wp ! Reference potential value
    INTEGER(i4) :: dof_id      = 0_i4   ! DOF index for this potential
    LOGICAL     :: is_ramped   = .FALSE. ! Apply as ramp
  END TYPE MD_BC_UPOT_Desc

  !-----------------------------------------------------------------------------
  ! UTEMP-specific Desc: user temperature boundary
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UTEMP_Desc
    REAL(wp)    :: T_ref       = 293.15_wp ! Reference temperature [K]
    REAL(wp)    :: T_initial   = 293.15_wp ! Initial temperature [K]
    LOGICAL     :: use_predef  = .FALSE.   ! Use predefined field input
    INTEGER(i4) :: npredf      = 0_i4     ! No. of predefined fields
  END TYPE MD_BC_UTEMP_Desc

  !-----------------------------------------------------------------------------
  ! UMASFL-specific Desc: mass flow rate boundary
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UMASFL_Desc
    REAL(wp)    :: mdot_ref    = 0.0_wp  ! Reference mass flow rate [kg/s]
    INTEGER(i4) :: face_id     = 0_i4   ! Target face/surface ID
    LOGICAL     :: is_outflow  = .FALSE. ! .TRUE. = outflow boundary
  END TYPE MD_BC_UMASFL_Desc

CONTAINS

  SUBROUTINE BC_Desc_Init(self)
    CLASS(MD_BC_Base_Desc), INTENT(INOUT) :: self
    self%is_initialized = .TRUE.
  END SUBROUTINE BC_Desc_Init

  SUBROUTINE BC_Desc_Reset(self)
    CLASS(MD_BC_Base_Desc), INTENT(INOUT) :: self
    self%bc_id = 0
    self%bc_family = 0
    self%bc_name = ''
    self%node_set_id = 0
    self%dof_start = 1
    self%dof_end = 6
    self%bc_type = 0
    self%magnitude = 0.0_wp
    self%field_type = 0
    self%is_initialized = .FALSE.
  END SUBROUTINE BC_Desc_Reset

  !-----------------------------------------------------------------------------
  ! MD_BC_DISP_Desc — DISP prescribed displacement description (*BOUNDARY)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_DISP_Desc
    CHARACTER(LEN=80) :: set_name  = ' '  ! node set name
    INTEGER(i4)       :: jdof_first = 0_i4  ! first constrained DOF
    INTEGER(i4)       :: jdof_last  = 0_i4  ! last constrained DOF
    REAL(wp)          :: magnitude  = 0.0_wp
    INTEGER(i4)       :: amp_id     = 0_i4
    LOGICAL           :: is_active  = .FALSE.
  END TYPE MD_BC_DISP_Desc

  !-----------------------------------------------------------------------------
  ! MD_BC_UPOT_Desc — UPOT prescribed potential description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UPOT_Desc
    CHARACTER(LEN=80) :: set_name  = ' '
    INTEGER(i4)       :: dof_type  = 0_i4  ! 0=electric, 1=pore pressure
    REAL(wp)          :: magnitude = 0.0_wp
    INTEGER(i4)       :: amp_id    = 0_i4
    LOGICAL           :: is_active = .FALSE.
  END TYPE MD_BC_UPOT_Desc

  !-----------------------------------------------------------------------------
  ! MD_BC_UTEMP_Desc — UTEMP prescribed temperature description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UTEMP_Desc
    CHARACTER(LEN=80) :: set_name  = ' '
    INTEGER(i4)       :: nfield    = 0_i4  ! number of predefined fields
    INTEGER(i4)       :: amp_id    = 0_i4
    LOGICAL           :: is_active = .FALSE.
  END TYPE MD_BC_UTEMP_Desc

  !-----------------------------------------------------------------------------
  ! MD_BC_UMASFL_Desc — UMASFL mass flow rate description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_BC_UMASFL_Desc
    CHARACTER(LEN=80) :: set_name  = ' '
    REAL(wp)          :: magnitude = 0.0_wp  ! reference flow rate
    INTEGER(i4)       :: amp_id    = 0_i4
    LOGICAL           :: is_active = .FALSE.
  END TYPE MD_BC_UMASFL_Desc

  !=============================================================================
  ! MD_BC_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_BC_Domain
    TYPE(MD_BC_Fixed_Desc),   ALLOCATABLE :: fixed_bcs(:)     ! [n_fixed]
    TYPE(MD_BC_Presc_Desc),   ALLOCATABLE :: presc_bcs(:)     ! [n_presc]
    TYPE(MD_BC_Symmetry_Desc), ALLOCATABLE :: symmetry_bcs(:) ! [n_sym]
    TYPE(MD_BC_Others_Desc),  ALLOCATABLE :: other_bcs(:)     ! [n_others]
    INTEGER(i4) :: n_fixed     = 0_i4
    INTEGER(i4) :: n_presc     = 0_i4
    INTEGER(i4) :: n_symmetry  = 0_i4
    INTEGER(i4) :: n_others    = 0_i4
    INTEGER(i4) :: max_bcs     = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_BC_Domain_Init
    PROCEDURE :: Finalize => MD_BC_Domain_Finalize
  END TYPE MD_BC_Domain

CONTAINS

  SUBROUTINE MD_BC_Domain_Init(this, cap_bcs, status)
    CLASS(MD_BC_Domain), INTENT(INOUT) :: this
    INTEGER(i4),         INTENT(IN)    :: cap_bcs
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL MD_BC_Domain_Finalize(this)
    IF (cap_bcs < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_BC_Domain_Init: cap_bcs must be >= 1'
      RETURN
    END IF
    ALLOCATE(this%fixed_bcs(cap_bcs/2+1))
    ALLOCATE(this%presc_bcs(cap_bcs/4+1))
    ALLOCATE(this%symmetry_bcs(cap_bcs/10+1))
    ALLOCATE(this%other_bcs(cap_bcs/10+1))
    this%n_fixed     = 0_i4
    this%n_presc     = 0_i4
    this%n_symmetry  = 0_i4
    this%n_others    = 0_i4
    this%max_bcs     = cap_bcs
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_BC_Domain_Init

  SUBROUTINE MD_BC_Domain_Finalize(this)
    CLASS(MD_BC_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%fixed_bcs))    DEALLOCATE(this%fixed_bcs)
    IF (ALLOCATED(this%presc_bcs))    DEALLOCATE(this%presc_bcs)
    IF (ALLOCATED(this%symmetry_bcs)) DEALLOCATE(this%symmetry_bcs)
    IF (ALLOCATED(this%other_bcs))    DEALLOCATE(this%other_bcs)
    this%n_fixed     = 0_i4
    this%n_presc     = 0_i4
    this%n_symmetry  = 0_i4
    this%n_others    = 0_i4
    this%max_bcs     = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_BC_Domain_Finalize

END MODULE MD_BC_Types
