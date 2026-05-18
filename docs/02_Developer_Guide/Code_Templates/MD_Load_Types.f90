!===============================================================================
! Module: MD_Load_Types                                           [Template v1.1]
! Layer:  L3_MD — Model Description Layer
! Domain: Load — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for load computation
!   at the MD_ (model-description) layer.
!
!   v1.1 additions:
!   - Added: Load family enum constants covering ALL Abaqus load subroutines
!   - Added: MD_Load_DFLUX_Desc    (DFLUX/VDFLUX: thermal flux)
!   - Added: MD_Load_FILM_Desc     (FILM/VFILM: convection film condition)
!   - Added: MD_Load_HETVAL_Desc   (HETVAL: internal heat generation)
!   - Added: MD_Load_UWAVE_Desc    (UWAVE: wave loading / Aqua)
!   - Baseline refresh: comments aligned to IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!
!   Supported load types (UFC contract):
!     - DLOAD / VDLOAD  : Distributed mechanical load
!     - DFLUX / VDFLUX  : Thermal flux (heat transfer)
!     - FILM  / VFILM   : Convection film coefficient
!     - HETVAL          : Internal heat generation rate
!     - UWAVE           : Wave kinematics (Abaqus/Aqua)
!
! Type roles:
!   MD_Load_Base_Desc   – Load parameters & identity (loaded once from INP)
!   MD_Load_Base_State  – Load state at increment start (history-dependent)
!   MD_Load_Base_Algo   – Analysis-phase configuration (load scaling, etc.)
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Load_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Load_Base_Desc
  PUBLIC :: MD_Load_Base_State
  PUBLIC :: MD_Load_Base_Algo
  PUBLIC :: MD_Load_DFLUX_Desc
  PUBLIC :: MD_Load_FILM_Desc
  PUBLIC :: MD_Load_HETVAL_Desc
  PUBLIC :: MD_Load_UWAVE_Desc

  !-----------------------------------------------------------------------------
  ! Load family enum (matches ABAQUS load type codes)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: &
    LOAD_FAMILY_DIST    = 1,  ! DLOAD/VDLOAD: distributed mechanical load
    LOAD_FAMILY_CONC    = 2,  ! CLOAD/VCLOAD: concentrated nodal force
    LOAD_FAMILY_FLUX    = 3,  ! DFLUX/VDFLUX: thermal flux
    LOAD_FAMILY_FILM    = 4,  ! FILM/VFILM:   convection film
    LOAD_FAMILY_HETVAL  = 5,  ! HETVAL:       internal heat generation
    LOAD_FAMILY_BODY    = 6,  ! Body force (BXNU/BYNU/BZNU)
    LOAD_FAMILY_SURF    = 7,  ! Surface pressure
    LOAD_FAMILY_WAVE    = 8   ! UWAVE: wave load (Aqua)

  !-----------------------------------------------------------------------------
  ! DESC — Load Descriptor
  !    Concrete type; parameters loaded from INP at model build time.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Load_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: load_id   = 0    ! Load identifier
    INTEGER(i4)       :: load_family = 0 ! LOAD_FAMILY_XXX enum
    CHARACTER(LEN=64) :: load_name = ''  ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Load parameters (common to all load types)
    REAL(wp) :: magnitude = 0.0_wp       ! Base magnitude
    REAL(wp) :: scale_factor = 1.0_wp    ! Load scaling factor
    INTEGER(i4) :: time_dependence = 0   ! 0=static, 1=time-dependent
    INTEGER(i4) :: amplitude_id = 0      ! Amplitude table ID (0=none)
    !-- Distributed load specific
    INTEGER(i4) :: load_type = 0         ! ABAQUS load type code (P1NU, BXNU, etc.)
    INTEGER(i4) :: element_face = 0      ! Element face identifier
    !-- Concentrated load specific
    INTEGER(i4) :: node_id = 0           ! Target node (for CLOAD)
    INTEGER(i4) :: dof_number = 0        ! Degree of freedom (1=UX, 2=UY, ...)
    !-- Thermal flux specific
    REAL(wp) :: ambient_t = 0.0_wp    ! Reference temperature
    REAL(wp) :: film_coeff = 0.0_wp      ! Film coefficient (convection)
  CONTAINS
    PROCEDURE :: Init   => Load_Desc_Init
    PROCEDURE :: Reset  => Load_Desc_Reset
  END TYPE MD_Load_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — Load State at Increment Start
  !    History-dependent state for load computation (e.g., accumulated load)
  !-----------------------------------------------------------------------------

END MODULE MD_Load_Types
