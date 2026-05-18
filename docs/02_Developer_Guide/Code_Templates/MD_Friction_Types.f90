!===============================================================================
! Module: MD_Friction_Types                                      [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Friction — Universal Base Type Definitions
!
! Purpose:
!   Defines the Desc / State / Algo three-type system for friction computation
!   at the MD_ (model-description) layer.
!
!   Abaqus subroutines covered:
!     - FRIC / VFRIC        : User friction (Standard/Explicit)
!     - FRIC_COEF / VFRIC_COEF : User friction coefficient
!     - UTRS               : Thermo-rheological simplicity (TRS for viscoelastic)
!
!   Design notes:
!     - FRIC and UINTER share physical contact state;
!       FRIC is a sub-routine of the contact interaction focused on tangential only
!     - FRIC_COEF provides a scalar mu at each contact point
!     - VFRIC_COEF is the Explicit counterpart of FRIC_COEF
!
! Type roles:
!   MD_Fric_Base_Desc  – Friction law parameters (loaded once from INP)
!   MD_Fric_Base_State – Friction state at increment start (slip history)
!   MD_Fric_Base_Algo  – Analysis-phase configuration (regularization, etc.)
!   MD_Fric_Coef_Desc  – FRIC_COEF/VFRIC_COEF specific: coefficient lookup
!
! Layer dependency:
!   USE IF_Prec        (wp, i4)
!   USE IF_Err_Brg     (ErrorStatusType + standard bridge vocabulary:
!                      init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE MD_Friction_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Fric_Base_Desc
  PUBLIC :: MD_Fric_Base_State
  PUBLIC :: MD_Fric_Base_Algo
  PUBLIC :: MD_Fric_Coef_Desc

  PUBLIC :: MD_Fric_FRIC_Desc
  PUBLIC :: MD_Fric_VFRIC_Desc
  PUBLIC :: MD_Fric_FRIC_COEF_Desc

  !-- Friction law family enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_LAW_COULOMB      = 1_i4  ! Classic Coulomb  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_LAW_LAGRANGE     = 2_i4  ! Lagrange multiplier  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_LAW_PENALTY      = 3_i4  ! Penalty method  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_LAW_USER         = 4_i4  ! User-defined (FRIC)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_LAW_ANISOTROPIC  = 5_i4  ! Anisotropic friction  ! migrated

  !-- Subroutine type enum
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_SUBRT_FRIC       = 1_i4  ! FRIC  (Standard)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_SUBRT_VFRIC      = 2_i4  ! VFRIC (Explicit)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_SUBRT_FRIC_COEF  = 3_i4  ! FRIC_COEF  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: MD_FRIC_FRIC_SUBRT_VFRIC_COEF = 4_i4  ! VFRIC_COEF  ! migrated

  !-----------------------------------------------------------------------------
  ! DESC — Friction Descriptor
  !    Parameters loaded from INP at model build time.
  !    Maps ABAQUS FRIC/VFRIC PROPS array and contact surface properties.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_Base_Desc
    !-- Identity & metadata
    INTEGER(i4)       :: fric_id      = 0_i4   ! Friction definition ID
    INTEGER(i4)       :: fric_law     = MD_FRIC_FRIC_LAW_COULOMB  ! Law enum
    INTEGER(i4)       :: subrt_type   = MD_FRIC_FRIC_SUBRT_FRIC   ! Subroutine code
    CHARACTER(LEN=64) :: fric_name    = ''      ! Human-readable label
    LOGICAL           :: is_initialized = .FALSE.
    !-- Coulomb base parameters
    REAL(wp) :: mu_ref        = 0.3_wp    ! Reference friction coefficient μ
    REAL(wp) :: tau_limit     = 0.0_wp    ! Critical shear stress [Pa] (UCOUL)
    !-- Anisotropic friction (two principal directions)
    REAL(wp) :: mu1           = 0.3_wp    ! Friction coeff in direction 1
    REAL(wp) :: mu2           = 0.3_wp    ! Friction coeff in direction 2
    !-- Regularization (viscous / elastic)
    REAL(wp) :: elastic_slip  = 0.0_wp    ! Elastic slip (regularization distance) [m]
    REAL(wp) :: visc_coeff    = 0.0_wp    ! Viscous coefficient [Pa·s/m]
    !-- Temperature / field dependence
    LOGICAL     :: temp_depend = .FALSE.  ! mu is temperature-dependent
    INTEGER(i4) :: nprops      = 0_i4    ! Number of real user properties
    REAL(wp), ALLOCATABLE :: props(:)    ! FRIC PROPS array
    INTEGER(i4) :: nstatv      = 0_i4   ! Number of state variables (SVARS)

  !-----------------------------------------------------------------------------
  ! MD_Fric_FRIC_Desc — FRIC user friction law description
  !   *FRICTION + *USER FRICTION
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_FRIC_Desc
    INTEGER(i4) :: nprops   = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: nstatv   = 0_i4
    REAL(wp)    :: mu_ref   = 0.0_wp  ! reference friction coefficient
    LOGICAL     :: is_active= .FALSE.
  END TYPE MD_Fric_FRIC_Desc

  !-----------------------------------------------------------------------------
  ! MD_Fric_VFRIC_Desc — VFRIC vectorised friction description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_VFRIC_Desc
    INTEGER(i4) :: nprops   = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: nstatv   = 0_i4
    REAL(wp)    :: mu_ref   = 0.0_wp
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: is_active= .FALSE.
  END TYPE MD_Fric_VFRIC_Desc

  !-----------------------------------------------------------------------------
  ! MD_Fric_FRIC_COEF_Desc — FRIC_COEF friction coefficient description
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_FRIC_COEF_Desc
    INTEGER(i4) :: nprops   = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    LOGICAL     :: pressure_dep = .FALSE.
    LOGICAL     :: temp_dep     = .FALSE.
    LOGICAL     :: is_active    = .FALSE.
  END TYPE MD_Fric_FRIC_COEF_Desc


CONTAINS
    PROCEDURE :: Init  => Fric_Desc_Init
    PROCEDURE :: Reset => Fric_Desc_Reset
  END TYPE MD_Fric_Base_Desc

  !-----------------------------------------------------------------------------
  ! STATE — Friction State at Increment Start
  !    Slip history and dissipation bookkeeping.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_Base_State
    !-- Slip history
    REAL(wp) :: slip1_accum    = 0.0_wp  ! Accumulated slip direction 1 [m]
    REAL(wp) :: slip2_accum    = 0.0_wp  ! Accumulated slip direction 2 [m]
    REAL(wp) :: slip_total     = 0.0_wp  ! Total accumulated slip [m]
    !-- Contact traction history
    REAL(wp) :: tau1_prev      = 0.0_wp  ! Previous tangential traction t1 [Pa]
    REAL(wp) :: tau2_prev      = 0.0_wp  ! Previous tangential traction t2 [Pa]
    !-- Dissipation
    REAL(wp) :: fric_dissip    = 0.0_wp  ! Friction energy dissipation [J/m²]
    !-- Effective mu history
    REAL(wp) :: mu_eff         = 0.0_wp  ! Effective friction coeff at last inc
    !-- State variables (SVARS) — allocated to nstatv
    REAL(wp), ALLOCATABLE :: svars(:)
    !-- Convergence bookkeeping
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Fric_Base_State

  !-----------------------------------------------------------------------------
  ! ALGO — Analysis-Phase Configuration
  !    Pre-analysis configuration for friction algorithm selection.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_Base_Algo
    !-- Contact algorithm
    INTEGER(i4) :: algorithm    = 1_i4   ! 1=penalty, 2=Lagrange, 3=augmented
    !-- Regularization method
    INTEGER(i4) :: reg_method   = 1_i4   ! 1=elastic-slip, 2=viscous, 3=none
    REAL(wp)    :: reg_factor   = 0.0_wp ! Regularization magnitude
    !-- Convergence
    INTEGER(i4) :: max_iter     = 50_i4  ! Max contact iterations
    REAL(wp)    :: tol_slip     = 1.0e-6_wp ! Slip convergence tolerance [m]
    !-- Output control
    LOGICAL :: print_debug      = .FALSE.
  END TYPE MD_Fric_Base_Algo

  !-----------------------------------------------------------------------------
  ! FRIC_COEF/VFRIC_COEF-specific Desc
  !   Provides a scalar friction coefficient at each contact point.
  !   Called with: PRESSURE, SLIP, TEMP, COORDS, NOEL, NPT, KSTEP, KINC
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Fric_Coef_Desc
    REAL(wp)    :: mu0           = 0.3_wp   ! Base friction coefficient
    REAL(wp)    :: mu_slip_coeff = 0.0_wp   ! Slip-velocity dependence coefficient
    REAL(wp)    :: mu_temp_coeff = 0.0_wp   ! Temperature dependence coefficient
    LOGICAL     :: is_explicit   = .FALSE.  ! .TRUE. for VFRIC_COEF
    INTEGER(i4) :: lookup_type   = 1_i4    ! 1=direct, 2=tabular
  END TYPE MD_Fric_Coef_Desc

CONTAINS

  SUBROUTINE Fric_Desc_Init(self)
    CLASS(MD_Fric_Base_Desc), INTENT(INOUT) :: self
    IF (self%nprops > 0 .AND. .NOT. ALLOCATED(self%props)) THEN
      ALLOCATE(self%props(self%nprops))
      self%props = 0.0_wp
    END IF
    self%is_initialized = .TRUE.
  END SUBROUTINE Fric_Desc_Init

  SUBROUTINE Fric_Desc_Reset(self)
    CLASS(MD_Fric_Base_Desc), INTENT(INOUT) :: self
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
    self%fric_id    = 0
    self%fric_law   = MD_FRIC_FRIC_LAW_COULOMB
    self%mu_ref     = 0.3_wp
    self%tau_limit  = 0.0_wp
    self%nprops     = 0
    self%nstatv     = 0
    self%is_initialized = .FALSE.
  END SUBROUTINE Fric_Desc_Reset

END MODULE MD_Friction_Types
