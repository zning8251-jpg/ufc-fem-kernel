!===============================================================================
! MODULE: PH_Mat_Comp_Def
! LAYER:  L4_PH
! DOMAIN: Material / Composite
! ROLE:   Def
! BRIEF:  TYPE definitions for composite material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + auxiliary
!         types with TBP short names and SIO-compliant Eval_Arg.
!===============================================================================
MODULE PH_Mat_Comp_Def
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Composite sub-type constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_COMP_SUB_CLT     = 801_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_COMP_SUB_HASHIN  = 802_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_COMP_SUB_FABRIC  = 803_i4

  !=============================================================================
  ! Auxiliary types for binary structure
  !=============================================================================

  TYPE, PUBLIC :: PH_Mat_Comp_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: num_constants = 0
  END TYPE PH_Mat_Comp_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Comp_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Comp_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Comp_Inc_Evo_Ctx
    REAL(wp) :: temperature = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
  END TYPE PH_Mat_Comp_Inc_Evo_Ctx

  !=============================================================================
  ! Desc TYPE: Material descriptor with nested cfg/vld
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Comp_Desc
    TYPE(PH_Mat_Comp_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Comp_Pop_Vld_Desc)  :: vld
    REAL(wp) :: E11 = 0.0_wp, E22 = 0.0_wp, E33 = 0.0_wp
    REAL(wp) :: nu12 = 0.0_wp, nu13 = 0.0_wp, nu23 = 0.0_wp
    REAL(wp) :: G12 = 0.0_wp, G13 = 0.0_wp, G23 = 0.0_wp
    REAL(wp) :: ply_thickness = 0.0_wp
    INTEGER(i4) :: n_plies = 0
    REAL(wp), ALLOCATABLE :: ply_angles(:)
    REAL(wp), ALLOCATABLE :: ply_fractions(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Comp_Desc_Init
    PROCEDURE, PASS :: Valid => Comp_Desc_Valid
    PROCEDURE, PASS :: Clean => Comp_Desc_Clean
  END TYPE PH_Mat_Comp_Desc

  !=============================================================================
  ! State TYPE: Integration point state
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Comp_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: failure_index(6) = 0.0_wp
    LOGICAL :: is_failed = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => Comp_State_Init
    PROCEDURE, PASS :: Update => Comp_State_Update
    PROCEDURE, PASS :: Clean  => Comp_State_Clean
  END TYPE PH_Mat_Comp_State

  !=============================================================================
  ! Algo TYPE: Algorithm control
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Comp_Algo
    INTEGER(i4) :: failure_criterion = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => Comp_Algo_Init
  END TYPE PH_Mat_Comp_Algo

  !=============================================================================
  ! Ctx TYPE: Per-iteration workspace with nested inc
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Comp_Ctx
    TYPE(PH_Mat_Comp_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_comp(6,6) = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Comp_Ctx_Init
    PROCEDURE, PASS :: Clean => Comp_Ctx_Clean
  END TYPE PH_Mat_Comp_Ctx

  !=============================================================================
  ! Eval_Arg TYPE: Unified argument bundle for SIO compliance
  !=============================================================================
  TYPE, PUBLIC :: PH_Mat_Comp_Eval_Arg
    REAL(wp) :: strain(6)          ! [IN] Input strain
    REAL(wp) :: stress(6)          ! [OUT] Output stress
    REAL(wp) :: ddsdde(6,6)        ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code     ! [OUT] Status code
    CHARACTER(LEN=256) :: message  ! [OUT] Status message
  END TYPE PH_Mat_Comp_Eval_Arg

  !=============================================================================
  ! Type-bound procedure implementations
  !=============================================================================
CONTAINS

  !---- Desc TBP ----!

  SUBROUTINE Comp_Desc_Init(this, cfg)
    CLASS(PH_Mat_Comp_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Comp_Cfg_Init_Desc), INTENT(IN) :: cfg
    this%cfg = cfg
    this%E11 = 0.0_wp; this%E22 = 0.0_wp; this%E33 = 0.0_wp
    this%nu12 = 0.0_wp; this%nu13 = 0.0_wp; this%nu23 = 0.0_wp
    this%G12 = 0.0_wp; this%G13 = 0.0_wp; this%G23 = 0.0_wp
    this%ply_thickness = 0.0_wp
    this%n_plies = 0
    IF (ALLOCATED(this%ply_angles)) DEALLOCATE(this%ply_angles)
    IF (ALLOCATED(this%ply_fractions)) DEALLOCATE(this%ply_fractions)
  END SUBROUTINE Comp_Desc_Init

  SUBROUTINE Comp_Desc_Valid(this, vld)
    CLASS(PH_Mat_Comp_Desc), INTENT(INOUT) :: this
    TYPE(PH_Mat_Comp_Pop_Vld_Desc), INTENT(IN) :: vld
    this%vld = vld
  END SUBROUTINE Comp_Desc_Valid

  SUBROUTINE Comp_Desc_Clean(this)
    CLASS(PH_Mat_Comp_Desc), INTENT(INOUT) :: this
    this%cfg%sub_type = 0
    this%cfg%num_constants = 0
    this%vld%is_valid = .FALSE.
    this%E11 = 0.0_wp; this%E22 = 0.0_wp; this%E33 = 0.0_wp
    this%nu12 = 0.0_wp; this%nu13 = 0.0_wp; this%nu23 = 0.0_wp
    this%G12 = 0.0_wp; this%G13 = 0.0_wp; this%G23 = 0.0_wp
    this%ply_thickness = 0.0_wp
    this%n_plies = 0
    IF (ALLOCATED(this%ply_angles)) DEALLOCATE(this%ply_angles)
    IF (ALLOCATED(this%ply_fractions)) DEALLOCATE(this%ply_fractions)
  END SUBROUTINE Comp_Desc_Clean

  !---- State TBP ----!

  SUBROUTINE Comp_State_Init(this)
    CLASS(PH_Mat_Comp_State), INTENT(INOUT) :: this
    this%stress = 0.0_wp; this%strain = 0.0_wp
    this%failure_index = 0.0_wp
    this%is_failed = .FALSE.
    this%initialized = .TRUE.
    this%num_evaluations = 0
  END SUBROUTINE Comp_State_Init

  SUBROUTINE Comp_State_Update(this, stress, strain)
    CLASS(PH_Mat_Comp_State), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: stress(:)
    REAL(wp), INTENT(IN) :: strain(:)
    this%stress(1:MIN(6, SIZE(stress))) = stress(1:MIN(6, SIZE(stress)))
    this%strain(1:MIN(6, SIZE(strain))) = strain(1:MIN(6, SIZE(strain)))
    this%num_evaluations = this%num_evaluations + 1
  END SUBROUTINE Comp_State_Update

  SUBROUTINE Comp_State_Clean(this)
    CLASS(PH_Mat_Comp_State), INTENT(INOUT) :: this
    this%stress = 0.0_wp; this%strain = 0.0_wp
    this%failure_index = 0.0_wp
    this%is_failed = .FALSE.
    this%initialized = .FALSE.
    this%num_evaluations = 0
  END SUBROUTINE Comp_State_Clean

  !---- Algo TBP ----!

  SUBROUTINE Comp_Algo_Init(this)
    CLASS(PH_Mat_Comp_Algo), INTENT(INOUT) :: this
    this%failure_criterion = 1
    this%use_numerical_tangent = .FALSE.
  END SUBROUTINE Comp_Algo_Init

  !---- Ctx TBP ----!

  SUBROUTINE Comp_Ctx_Init(this)
    CLASS(PH_Mat_Comp_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_comp = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE Comp_Ctx_Init

  SUBROUTINE Comp_Ctx_Clean(this)
    CLASS(PH_Mat_Comp_Ctx), INTENT(INOUT) :: this
    this%inc%temperature = 0.0_wp
    this%inc%dtemp = 0.0_wp
    this%D_comp = 0.0_wp
    this%temperature = 293.15_wp
  END SUBROUTINE Comp_Ctx_Clean

END MODULE PH_Mat_Comp_Def
