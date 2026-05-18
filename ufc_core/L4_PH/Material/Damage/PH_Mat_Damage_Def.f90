!===============================================================================
! MODULE: PH_Mat_Damage_Def
! LAYER:  L4_PH
! DOMAIN: Material / Damage
! ROLE:   Def
! BRIEF:  TYPE definitions for damage material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + Args
!===============================================================================
MODULE PH_Mat_Damage_Def
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  ! --- Sub-type constants ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DMG_SUB_DUCTILE   = 701_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DMG_SUB_SHEAR     = 702_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DMG_SUB_BRITTLE   = 703_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DMG_SUB_GURSON    = 704_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_DMG_SUB_LEMAITRE  = 705_i4

  ! --- Auxiliary types ---
  TYPE, PUBLIC :: PH_Mat_Damage_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0_i4
    INTEGER(i4) :: damage_law_type = 0_i4
  END TYPE PH_Mat_Damage_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Damage_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Damage_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Damage_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE PH_Mat_Damage_Inc_Evo_Ctx

  ! --- Primary: Desc ---
  TYPE, PUBLIC :: PH_Mat_Damage_Desc
    TYPE(PH_Mat_Damage_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Damage_Pop_Vld_Desc) :: pop
    REAL(wp) :: eps_f = 0.0_wp, sigma_t = 0.0_wp
    REAL(wp) :: G_f = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Damage_Desc

  ! --- Primary: State ---
  TYPE, PUBLIC :: PH_Mat_Damage_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: damage = 0.0_wp
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    LOGICAL :: is_failed = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Damage_State

  ! --- Primary: Algo ---
  TYPE, PUBLIC :: PH_Mat_Damage_Algo
    REAL(wp) :: damage_threshold = 0.99_wp
    INTEGER(i4) :: softening_law = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Damage_Algo

  ! --- Primary: Ctx ---
  TYPE, PUBLIC :: PH_Mat_Damage_Ctx
    TYPE(PH_Mat_Damage_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_dmg(6,6) = 0.0_wp
    REAL(wp) :: damage_increment = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Damage_Ctx

  ! --- Args ---
  TYPE, PUBLIC :: PH_Mat_Damage_Eval_Arg
    REAL(wp) :: strain(6)            ! [IN]  Total strain
    REAL(wp) :: dstrain(6)           ! [IN]  Strain increment
    REAL(wp) :: stress(6)            ! [OUT] Updated stress
    REAL(wp) :: ddsdde(6,6)          ! [OUT] Tangent stiffness matrix
    INTEGER(i4) :: status_code       ! [OUT] Exit status code
    CHARACTER(len=256) :: message    ! [OUT] Diagnostic message
  END TYPE PH_Mat_Damage_Eval_Arg

  ! --- Public type declarations ---
  PUBLIC :: PH_Mat_Damage_Desc, PH_Mat_Damage_State
  PUBLIC :: PH_Mat_Damage_Algo, PH_Mat_Damage_Ctx
  PUBLIC :: PH_Mat_Damage_Eval_Arg
  PUBLIC :: PH_Mat_Damage_Cfg_Init_Desc, PH_Mat_Damage_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Damage_Inc_Evo_Ctx

CONTAINS

  ! ========== Desc TBP implementations ==========

  SUBROUTINE Desc_Init(desc, sub_type, damage_law_type, nprops)
    CLASS(PH_Mat_Damage_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type, damage_law_type, nprops
    desc%cfg%sub_type = sub_type
    desc%cfg%damage_law_type = damage_law_type
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    ALLOCATE(desc%props(nprops))
    desc%props = 0.0_wp
    desc%pop%is_valid = .TRUE.
  END SUBROUTINE Desc_Init

  FUNCTION Desc_Valid(desc) RESULT(valid)
    CLASS(PH_Mat_Damage_Desc), INTENT(IN) :: desc
    LOGICAL :: valid
    valid = desc%pop%is_valid
  END FUNCTION Desc_Valid

  SUBROUTINE Desc_Clean(desc)
    CLASS(PH_Mat_Damage_Desc), INTENT(INOUT) :: desc
    desc%cfg%sub_type = 0_i4
    desc%cfg%damage_law_type = 0_i4
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    desc%pop%is_valid = .FALSE.
  END SUBROUTINE Desc_Clean

  ! ========== State TBP implementations ==========

  SUBROUTINE State_Init(state)
    CLASS(PH_Mat_Damage_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%damage = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%is_failed = .FALSE.
    state%initialized = .TRUE.
    state%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(state, stress, damage)
    CLASS(PH_Mat_Damage_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(:), damage
    state%stress = stress
    state%damage = damage
    state%num_evaluations = state%num_evaluations + 1
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(state)
    CLASS(PH_Mat_Damage_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%damage = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%is_failed = .FALSE.
    state%initialized = .FALSE.
    state%num_evaluations = 0
  END SUBROUTINE State_Clean

  ! ========== Algo TBP implementations ==========

  SUBROUTINE Algo_Init(algo)
    CLASS(PH_Mat_Damage_Algo), INTENT(INOUT) :: algo
    algo%damage_threshold = 0.99_wp
    algo%softening_law = 1
    algo%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(algo, threshold, softening, use_num_tang)
    CLASS(PH_Mat_Damage_Algo), INTENT(INOUT) :: algo
    REAL(wp), INTENT(IN) :: threshold
    INTEGER(i4), INTENT(IN) :: softening
    LOGICAL, INTENT(IN) :: use_num_tang
    algo%damage_threshold = threshold
    algo%softening_law = softening
    algo%use_numerical_tangent = use_num_tang
  END SUBROUTINE Algo_Config

  ! ========== Ctx TBP implementations ==========

  SUBROUTINE Ctx_Init(ctx)
    CLASS(PH_Mat_Damage_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%D_dmg = 0.0_wp
    ctx%damage_increment = 0.0_wp
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(ctx)
    CLASS(PH_Mat_Damage_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%D_dmg = 0.0_wp
    ctx%damage_increment = 0.0_wp
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Damage_Def
