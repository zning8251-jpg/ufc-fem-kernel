!===============================================================================
! MODULE: PH_Mat_User_Def
! LAYER:  L4_PH
! DOMAIN: Material / User
! ROLE:   Def
! BRIEF:  TYPE definitions for user-defined material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + auxiliary
!         types with TBP short names and SIO-compliant Eval_Arg.
!===============================================================================
MODULE PH_Mat_User_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! User sub-type constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_USER_SUB_UMAT   = 1101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_USER_SUB_VUMAT  = 1102_i4

  !=============================================================================
  ! Auxiliary types for binary structure
  !=============================================================================

  TYPE, PUBLIC :: PH_Mat_User_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_User_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_User_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_User_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_User_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_User_Inc_Evo_Ctx

  !=============================================================================
  ! Desc TYPE: Material descriptor with nested cfg/vld
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_User_Desc
    TYPE(PH_Mat_User_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_User_Pop_Vld_Desc)  :: vld
    INTEGER(i4) :: nprops = 0, nstatv = 0
    REAL(wp), ALLOCATABLE :: props(:)
    CHARACTER(LEN=80) :: umat_name = ""
  CONTAINS
    PROCEDURE, PASS :: Init  => User_Desc_Init
    PROCEDURE, PASS :: Valid => User_Desc_Valid
    PROCEDURE, PASS :: Clean => User_Desc_Clean
  END TYPE PH_Mat_User_Desc

  !=============================================================================
  ! State TYPE: Integration point state
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_User_State
    REAL(wp) :: stress(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: statev(:)
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => User_State_Init
    PROCEDURE, PASS :: Update => User_State_Update
    PROCEDURE, PASS :: Clean  => User_State_Clean
  END TYPE PH_Mat_User_State

  !=============================================================================
  ! Algo TYPE: Algorithm control
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_User_Algo
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => User_Algo_Init
  END TYPE PH_Mat_User_Algo

  !=============================================================================
  ! Ctx TYPE: Per-iteration workspace with nested inc
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_User_Ctx
    TYPE(PH_Mat_User_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => User_Ctx_Init
    PROCEDURE, PASS :: Clean => User_Ctx_Clean
  END TYPE PH_Mat_User_Ctx

  !=============================================================================
  ! Eval_Arg TYPE: Unified argument bundle for SIO compliance
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_User_Eval_Arg
    REAL(wp) :: strain(6)          ! [IN] Total strain
    REAL(wp) :: dstrain(6)         ! [IN] Strain increment
    REAL(wp) :: dt                 ! [IN] Time increment
    REAL(wp) :: temperature        ! [IN] Current temperature
    REAL(wp) :: stress(6)          ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)        ! [OUT] Tangent stiffness
    REAL(wp), ALLOCATABLE :: statev(:)  ! [INOUT] State variables
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_User_Eval_Arg

  !=============================================================================
  ! Type-bound procedure implementations
  !=============================================================================
CONTAINS

  !---- Desc TBP ----!

  SUBROUTINE User_Desc_Init(this, cfg)
    CLASS(PH_Mat_User_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_User_Cfg_Init_Desc), INTENT(IN) :: cfg
    this%cfg = cfg
    this%nprops = 0; this%nstatv = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    this%umat_name = ""
  END SUBROUTINE User_Desc_Init

  SUBROUTINE User_Desc_Valid(this, vld)
    CLASS(PH_Mat_User_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_User_Pop_Vld_Desc), INTENT(IN) :: vld
    this%vld = vld
  END SUBROUTINE User_Desc_Valid

  SUBROUTINE User_Desc_Clean(this)
    CLASS(PH_Mat_User_Desc), INTENT(INOUT) :: this
    this%cfg%sub_type = 0
    this%cfg%num_constants = 0
    this%vld%is_valid = .FALSE.
    this%nprops = 0; this%nstatv = 0
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    this%umat_name = ""
  END SUBROUTINE User_Desc_Clean

  !---- State TBP ----!

  SUBROUTINE User_State_Init(this, nstatv)
    CLASS(PH_Mat_User_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: nstatv
    this%stress = 0.0_wp
    IF (ALLOCATED(this%statev)) DEALLOCATE(this%statev)
    ALLOCATE(this%statev(nstatv), SOURCE=0.0_wp)
    this%initialized = .TRUE.
    this%num_evaluations = 0
  END SUBROUTINE User_State_Init

  SUBROUTINE User_State_Update(this, stress)
    CLASS(PH_Mat_User_State), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: stress(:)
    this%stress(1:MIN(6, SIZE(stress))) = stress(1:MIN(6, SIZE(stress)))
    this%num_evaluations = this%num_evaluations + 1
  END SUBROUTINE User_State_Update

  SUBROUTINE User_State_Clean(this)
    CLASS(PH_Mat_User_State), INTENT(INOUT) :: this
    this%stress = 0.0_wp
    IF (ALLOCATED(this%statev)) DEALLOCATE(this%statev)
    this%initialized = .FALSE.
    this%num_evaluations = 0
  END SUBROUTINE User_State_Clean

  !---- Algo TBP ----!

  SUBROUTINE User_Algo_Init(this)
    CLASS(PH_Mat_User_Algo), INTENT(INOUT) :: this
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE User_Algo_Init

  !---- Ctx TBP ----!

  SUBROUTINE User_Ctx_Init(this)
    CLASS(PH_Mat_User_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_el = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE User_Ctx_Init

  SUBROUTINE User_Ctx_Clean(this)
    CLASS(PH_Mat_User_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_el = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE User_Ctx_Clean

END MODULE PH_Mat_User_Def
