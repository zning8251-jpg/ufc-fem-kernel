!===============================================================================
! MODULE: PH_Mat_Geo_Def
! LAYER:  L4_PH
! DOMAIN: Material / Geo
! ROLE:   Def
! BRIEF:  TYPE definitions for geomechanics material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + Args
!===============================================================================
MODULE PH_Mat_Geo_Def
  USE IF_Prec_Core, ONLY: i4, wp
  IMPLICIT NONE
  PRIVATE

  ! --- Sub-type constants ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_DP_LINEAR     = 701_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_DP_CAP        = 702_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_MC            = 703_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_CAM_CLAY      = 704_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_HOEK_BROWN    = 705_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_GEO_SUB_CC            = 706_i4

  ! --- Auxiliary types ---
  TYPE, PUBLIC :: PH_Mat_Geo_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0_i4
  END TYPE PH_Mat_Geo_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Geo_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Geo_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Geo_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
  END TYPE PH_Mat_Geo_Inc_Evo_Ctx

  ! --- Primary: Desc ---
  TYPE, PUBLIC :: PH_Mat_Geo_Desc
    TYPE(PH_Mat_Geo_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Geo_Pop_Vld_Desc)  :: pop
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp
    REAL(wp) :: phi_friction = 0.0_wp
    REAL(wp) :: c_cohesion = 0.0_wp
    REAL(wp) :: psi_dilation = 0.0_wp
    REAL(wp) :: K0 = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Geo_Desc

  ! --- Primary: State ---
  TYPE, PUBLIC :: PH_Mat_Geo_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: cap_vol_plastic_strain = 0.0_wp
    LOGICAL :: is_plastic = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Geo_State

  ! --- Primary: Algo ---
  TYPE, PUBLIC :: PH_Mat_Geo_Algo
    INTEGER(i4) :: integration_method = 1
    REAL(wp) :: tolerance = 1.0e-8_wp
    INTEGER(i4) :: return_mapping = 1
    INTEGER(i4) :: max_iter = 50
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Geo_Algo

  ! --- Primary: Ctx ---
  TYPE, PUBLIC :: PH_Mat_Geo_Ctx
    TYPE(PH_Mat_Geo_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: stress_trial(6) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Geo_Ctx

  ! --- Args ---
  TYPE, PUBLIC :: PH_Mat_Geo_Eval_Arg
    REAL(wp) :: strain(6)            ! [IN]  Total strain
    REAL(wp) :: dstrain(6)           ! [IN]  Strain increment
    REAL(wp) :: stress(6)            ! [OUT] Updated stress
    REAL(wp) :: ddsdde(6,6)          ! [OUT] Tangent stiffness matrix
    INTEGER(i4) :: status_code       ! [OUT] Exit status code
    CHARACTER(len=256) :: message    ! [OUT] Diagnostic message
  END TYPE PH_Mat_Geo_Eval_Arg

  ! --- Public type declarations ---
  PUBLIC :: PH_Mat_Geo_Desc, PH_Mat_Geo_State
  PUBLIC :: PH_Mat_Geo_Algo, PH_Mat_Geo_Ctx
  PUBLIC :: PH_Mat_Geo_Eval_Arg
  PUBLIC :: PH_Mat_Geo_Cfg_Init_Desc, PH_Mat_Geo_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Geo_Inc_Evo_Ctx

CONTAINS

  ! ========== Desc TBP implementations ==========

  SUBROUTINE Desc_Init(desc, sub_type, nprops)
    CLASS(PH_Mat_Geo_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type, nprops
    desc%cfg%sub_type = sub_type
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    ALLOCATE(desc%props(nprops))
    desc%props = 0.0_wp
    desc%pop%is_valid = .TRUE.
  END SUBROUTINE Desc_Init

  FUNCTION Desc_Valid(desc) RESULT(valid)
    CLASS(PH_Mat_Geo_Desc), INTENT(IN) :: desc
    LOGICAL :: valid
    valid = desc%pop%is_valid
  END FUNCTION Desc_Valid

  SUBROUTINE Desc_Clean(desc)
    CLASS(PH_Mat_Geo_Desc), INTENT(INOUT) :: desc
    desc%cfg%sub_type = 0_i4
    desc%E = 0.0_wp; desc%nu = 0.0_wp
    desc%phi_friction = 0.0_wp
    desc%c_cohesion = 0.0_wp
    desc%psi_dilation = 0.0_wp
    desc%K0 = 0.0_wp
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    desc%pop%is_valid = .FALSE.
  END SUBROUTINE Desc_Clean

  ! ========== State TBP implementations ==========

  SUBROUTINE State_Init(state)
    CLASS(PH_Mat_Geo_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%cap_vol_plastic_strain = 0.0_wp
    state%is_plastic = .FALSE.
    state%initialized = .TRUE.
    state%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(state, stress, plastic_strain)
    CLASS(PH_Mat_Geo_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(:), plastic_strain(:)
    state%stress = stress
    state%plastic_strain = plastic_strain
    state%num_evaluations = state%num_evaluations + 1
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(state)
    CLASS(PH_Mat_Geo_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%strain = 0.0_wp
    state%plastic_strain = 0.0_wp
    state%equiv_plastic_strain = 0.0_wp
    state%cap_vol_plastic_strain = 0.0_wp
    state%is_plastic = .FALSE.
    state%initialized = .FALSE.
    state%num_evaluations = 0
  END SUBROUTINE State_Clean

  ! ========== Algo TBP implementations ==========

  SUBROUTINE Algo_Init(algo)
    CLASS(PH_Mat_Geo_Algo), INTENT(INOUT) :: algo
    algo%integration_method = 1
    algo%tolerance = 1.0e-8_wp
    algo%return_mapping = 1
    algo%max_iter = 50
    algo%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(algo, mapping, max_it, use_num_tang)
    CLASS(PH_Mat_Geo_Algo), INTENT(INOUT) :: algo
    INTEGER(i4), INTENT(IN) :: mapping, max_it
    LOGICAL, INTENT(IN) :: use_num_tang
    algo%return_mapping = mapping
    algo%max_iter = max_it
    algo%use_numerical_tangent = use_num_tang
  END SUBROUTINE Algo_Config

  ! ========== Ctx TBP implementations ==========

  SUBROUTINE Ctx_Init(ctx)
    CLASS(PH_Mat_Geo_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%D_el = 0.0_wp
    ctx%stress_trial = 0.0_wp
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(ctx)
    CLASS(PH_Mat_Geo_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%D_el = 0.0_wp
    ctx%stress_trial = 0.0_wp
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Geo_Def
