!===============================================================================
! MODULE: PH_Mat_Therm_Def
! LAYER:  L4_PH
! DOMAIN: Material / Thermal
! ROLE:   Def
! BRIEF:  TYPE definitions for thermal material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + auxiliary
!         types with TBP short names and SIO-compliant Eval_Arg.
!===============================================================================
MODULE PH_Mat_Therm_Def
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Thermal sub-type constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_THERM_SUB_ISO      = 901_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_THERM_SUB_ORTHO    = 902_i4

  !=============================================================================
  ! Auxiliary types for binary structure
  !=============================================================================

  TYPE, PUBLIC :: PH_Mat_Therm_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Therm_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Therm_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Therm_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Therm_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Therm_Inc_Evo_Ctx

  !=============================================================================
  ! Desc TYPE: Material descriptor with nested cfg/vld
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Therm_Desc
    TYPE(PH_Mat_Therm_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Therm_Pop_Vld_Desc)  :: vld
    REAL(wp) :: kappa = 0.0_wp
    REAL(wp) :: specific_heat = 0.0_wp
    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: alpha(3) = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Therm_Desc_Init
    PROCEDURE, PASS :: Valid => Therm_Desc_Valid
    PROCEDURE, PASS :: Clean => Therm_Desc_Clean
  END TYPE PH_Mat_Therm_Desc

  !=============================================================================
  ! State TYPE: Integration point state
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Therm_State
    REAL(wp) :: temperature = 293.15_wp
    REAL(wp) :: heat_flux(3) = 0.0_wp
    REAL(wp) :: internal_energy = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Therm_State_Init
    PROCEDURE, PASS :: Update => Therm_State_Update
    PROCEDURE, PASS :: Clean  => Therm_State_Clean
  END TYPE PH_Mat_Therm_State

  !=============================================================================
  ! Algo TYPE: Algorithm control
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Therm_Algo
    INTEGER(i4) :: time_integration = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Therm_Algo_Init
  END TYPE PH_Mat_Therm_Algo

  !=============================================================================
  ! Ctx TYPE: Per-iteration workspace with nested inc
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Therm_Ctx
    TYPE(PH_Mat_Therm_Inc_Evo_Ctx) :: inc
    REAL(wp) :: K_th(3,3) = 0.0_wp
    REAL(wp) :: grad_T(3) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Therm_Ctx_Init
    PROCEDURE, PASS :: Clean => Therm_Ctx_Clean
  END TYPE PH_Mat_Therm_Ctx

  !=============================================================================
  ! Eval_Arg TYPE: Unified argument bundle for SIO compliance
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Therm_Eval_Arg
    REAL(wp) :: grad_T(3)          ! [IN] Temperature gradient
    REAL(wp) :: temperature        ! [IN] Current temperature
    REAL(wp) :: heat_flux(3)       ! [OUT] Heat flux
    REAL(wp) :: dq_dT(3,3)        ! [OUT] Conductivity tangent
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_Therm_Eval_Arg

  !=============================================================================
  ! Type-bound procedure implementations
  !=============================================================================
CONTAINS

  !---- Desc TBP ----!

  SUBROUTINE Therm_Desc_Init(this, cfg)
    CLASS(PH_Mat_Therm_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Therm_Cfg_Init_Desc), INTENT(IN) :: cfg
    this%cfg = cfg
    this%kappa = 0.0_wp
    this%specific_heat = 0.0_wp
    this%density = 0.0_wp
    this%alpha = 0.0_wp
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
  END SUBROUTINE Therm_Desc_Init

  SUBROUTINE Therm_Desc_Valid(this, vld)
    CLASS(PH_Mat_Therm_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Therm_Pop_Vld_Desc), INTENT(IN) :: vld
    this%vld = vld
  END SUBROUTINE Therm_Desc_Valid

  SUBROUTINE Therm_Desc_Clean(this)
    CLASS(PH_Mat_Therm_Desc), INTENT(INOUT) :: this
    this%cfg%sub_type = 0
    this%cfg%num_constants = 0
    this%vld%is_valid = .FALSE.
    this%kappa = 0.0_wp
    this%specific_heat = 0.0_wp
    this%density = 0.0_wp
    this%alpha = 0.0_wp
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
  END SUBROUTINE Therm_Desc_Clean

  !---- State TBP ----!

  SUBROUTINE Therm_State_Init(this)
    CLASS(PH_Mat_Therm_State), INTENT(INOUT) :: this
    this%temperature = 293.15_wp
    this%heat_flux = 0.0_wp
    this%internal_energy = 0.0_wp
    this%initialized = .TRUE.
    this%num_evaluations = 0
  END SUBROUTINE Therm_State_Init

  SUBROUTINE Therm_State_Update(this, temperature, heat_flux)
    CLASS(PH_Mat_Therm_State), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: temperature
    REAL(wp), INTENT(IN) :: heat_flux(:)
    this%temperature = temperature
    this%heat_flux(1:MIN(3, SIZE(heat_flux))) = heat_flux(1:MIN(3, SIZE(heat_flux)))
    this%num_evaluations = this%num_evaluations + 1
  END SUBROUTINE Therm_State_Update

  SUBROUTINE Therm_State_Clean(this)
    CLASS(PH_Mat_Therm_State), INTENT(INOUT) :: this
    this%temperature = 293.15_wp
    this%heat_flux = 0.0_wp
    this%internal_energy = 0.0_wp
    this%initialized = .FALSE.
    this%num_evaluations = 0
  END SUBROUTINE Therm_State_Clean

  !---- Algo TBP ----!

  SUBROUTINE Therm_Algo_Init(this)
    CLASS(PH_Mat_Therm_Algo), INTENT(INOUT) :: this
    this%time_integration = 1
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Therm_Algo_Init

  !---- Ctx TBP ----!

  SUBROUTINE Therm_Ctx_Init(this)
    CLASS(PH_Mat_Therm_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%K_th = 0.0_wp
    this%grad_T = 0.0_wp
  END SUBROUTINE Therm_Ctx_Init

  SUBROUTINE Therm_Ctx_Clean(this)
    CLASS(PH_Mat_Therm_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%K_th = 0.0_wp
    this%grad_T = 0.0_wp
  END SUBROUTINE Therm_Ctx_Clean

END MODULE PH_Mat_Therm_Def
