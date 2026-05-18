!===============================================================================
! MODULE: PH_Mat_Acou_Def
! LAYER:  L4_PH
! DOMAIN: Material / Acoustic
! ROLE:   Def
! BRIEF:  TYPE definitions for acoustic material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + auxiliary
!         types with TBP short names and SIO-compliant Eval_Arg.
!===============================================================================
MODULE PH_Mat_Acou_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Acoustic sub-type constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ACOU_SUB_LINEAR    = 1001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_ACOU_SUB_ABSORB    = 1002_i4

  !=============================================================================
  ! Auxiliary types for binary structure
  !=============================================================================

  TYPE, PUBLIC :: PH_Mat_Acou_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Acou_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Acou_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Acou_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Acou_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Acou_Inc_Evo_Ctx

  !=============================================================================
  ! Desc TYPE: Material descriptor with nested cfg/vld
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Acou_Desc
    TYPE(PH_Mat_Acou_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Acou_Pop_Vld_Desc)  :: vld
    REAL(wp) :: bulk_modulus = 0.0_wp
    REAL(wp) :: density = 0.0_wp
    REAL(wp) :: speed_of_sound = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Acou_Desc_Init
    PROCEDURE, PASS :: Valid => Acou_Desc_Valid
    PROCEDURE, PASS :: Clean => Acou_Desc_Clean
  END TYPE PH_Mat_Acou_Desc

  !=============================================================================
  ! State TYPE: Integration point state
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Acou_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: strain(6) = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Acou_State_Init
    PROCEDURE, PASS :: Update => Acou_State_Update
    PROCEDURE, PASS :: Clean  => Acou_State_Clean
  END TYPE PH_Mat_Acou_State

  !=============================================================================
  ! Algo TYPE: Algorithm control
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Acou_Algo
    INTEGER(i4) :: method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Acou_Algo_Init
  END TYPE PH_Mat_Acou_Algo

  !=============================================================================
  ! Ctx TYPE: Per-iteration workspace with nested inc
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Acou_Ctx
    TYPE(PH_Mat_Acou_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_acou(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Acou_Ctx_Init
    PROCEDURE, PASS :: Clean => Acou_Ctx_Clean
  END TYPE PH_Mat_Acou_Ctx

  !=============================================================================
  ! Eval_Arg TYPE: Unified argument bundle for SIO compliance
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Acou_Eval_Arg
    REAL(wp) :: strain(6)                ! [IN] Input strain
    REAL(wp) :: stress(6)                ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)              ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code           ! [OUT] Status code
    CHARACTER(LEN=256) :: message        ! [OUT] Status message
  END TYPE PH_Mat_Acou_Eval_Arg

  !=============================================================================
  ! Type-bound procedure implementations
  !=============================================================================
CONTAINS

  !---- Desc TBP ----!

  SUBROUTINE Acou_Desc_Init(this, cfg)
    CLASS(PH_Mat_Acou_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Acou_Cfg_Init_Desc), INTENT(IN) :: cfg
    this%cfg = cfg
    this%bulk_modulus = 0.0_wp
    this%density = 0.0_wp
    this%speed_of_sound = 0.0_wp
  END SUBROUTINE Acou_Desc_Init

  SUBROUTINE Acou_Desc_Valid(this, vld)
    CLASS(PH_Mat_Acou_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Acou_Pop_Vld_Desc), INTENT(IN) :: vld
    this%vld = vld
  END SUBROUTINE Acou_Desc_Valid

  SUBROUTINE Acou_Desc_Clean(this)
    CLASS(PH_Mat_Acou_Desc), INTENT(INOUT) :: this
    this%cfg%sub_type = 0
    this%cfg%num_constants = 0
    this%vld%is_valid = .FALSE.
    this%bulk_modulus = 0.0_wp
    this%density = 0.0_wp
    this%speed_of_sound = 0.0_wp
  END SUBROUTINE Acou_Desc_Clean

  !---- State TBP ----!

  SUBROUTINE Acou_State_Init(this)
    CLASS(PH_Mat_Acou_State), INTENT(INOUT) :: this
    this%stress = 0.0_wp
    this%pressure = 0.0_wp
    this%strain = 0.0_wp
    this%initialized = .TRUE.
    this%num_evaluations = 0
  END SUBROUTINE Acou_State_Init

  SUBROUTINE Acou_State_Update(this, stress, strain)
    CLASS(PH_Mat_Acou_State), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: stress(:)
    REAL(wp), INTENT(IN) :: strain(:)
    this%stress(1:MIN(6, SIZE(stress))) = stress(1:MIN(6, SIZE(stress)))
    this%strain(1:MIN(6, SIZE(strain))) = strain(1:MIN(6, SIZE(strain)))
    this%num_evaluations = this%num_evaluations + 1
  END SUBROUTINE Acou_State_Update

  SUBROUTINE Acou_State_Clean(this)
    CLASS(PH_Mat_Acou_State), INTENT(INOUT) :: this
    this%stress = 0.0_wp
    this%pressure = 0.0_wp
    this%strain = 0.0_wp
    this%initialized = .FALSE.
    this%num_evaluations = 0
  END SUBROUTINE Acou_State_Clean

  !---- Algo TBP ----!

  SUBROUTINE Acou_Algo_Init(this)
    CLASS(PH_Mat_Acou_Algo), INTENT(INOUT) :: this
    this%method = 1
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Acou_Algo_Init

  !---- Ctx TBP ----!

  SUBROUTINE Acou_Ctx_Init(this)
    CLASS(PH_Mat_Acou_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_acou = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE Acou_Ctx_Init

  SUBROUTINE Acou_Ctx_Clean(this)
    CLASS(PH_Mat_Acou_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_acou = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE Acou_Ctx_Clean

END MODULE PH_Mat_Acou_Def
