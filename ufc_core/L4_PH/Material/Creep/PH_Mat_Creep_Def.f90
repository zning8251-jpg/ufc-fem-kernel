!===============================================================================
! MODULE: PH_Mat_Creep_Def
! LAYER:  L4_PH
! DOMAIN: Material / Creep
! ROLE:   Def
! BRIEF:  TYPE definitions for creep material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + Args
!===============================================================================
MODULE PH_Mat_Creep_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  ! --- Sub-type constants ---
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CREEP_SUB_POWER     = 601_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CREEP_SUB_GAROFALO  = 602_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CREEP_SUB_PERZYNA   = 603_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CREEP_SUB_USER      = 604_i4

  ! --- Auxiliary types ---
  TYPE, PUBLIC :: PH_Mat_Creep_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0_i4
  END TYPE PH_Mat_Creep_Cfg_Init_Desc

  TYPE, PUBLIC :: PH_Mat_Creep_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Creep_Pop_Vld_Desc

  TYPE, PUBLIC :: PH_Mat_Creep_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    REAL(wp) :: dt = 0.0_wp
  END TYPE PH_Mat_Creep_Inc_Evo_Ctx

  ! --- Primary: Desc ---
  TYPE, PUBLIC :: PH_Mat_Creep_Desc
    TYPE(PH_Mat_Creep_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Creep_Pop_Vld_Desc) :: pop
    REAL(wp) :: A = 0.0_wp, n = 0.0_wp, m = 0.0_wp
    REAL(wp) :: Q_act = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Creep_Desc

  ! --- Primary: State ---
  TYPE, PUBLIC :: PH_Mat_Creep_State
    REAL(wp) :: stress(6) = 0.0_wp, creep_strain(6) = 0.0_wp
    REAL(wp) :: equiv_creep_strain = 0.0_wp
    REAL(wp) :: creep_strain_rate(6) = 0.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Creep_State

  ! --- Primary: Algo ---
  TYPE, PUBLIC :: PH_Mat_Creep_Algo
    INTEGER(i4) :: integration_method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Creep_Algo

  ! --- Primary: Ctx ---
  TYPE, PUBLIC :: PH_Mat_Creep_Ctx
    TYPE(PH_Mat_Creep_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Creep_Ctx

  ! --- Args ---
  TYPE, PUBLIC :: PH_Mat_Creep_Eval_Arg
    REAL(wp) :: strain(6)            ! [IN]  Total strain
    REAL(wp) :: dstrain(6)           ! [IN]  Strain increment
    REAL(wp) :: dt                   ! [IN]  Time increment
    REAL(wp) :: temperature          ! [IN]  Current temperature
    REAL(wp) :: stress(6)            ! [OUT] Updated stress
    REAL(wp) :: ddsdde(6,6)          ! [OUT] Tangent stiffness matrix
    INTEGER(i4) :: status_code       ! [OUT] Exit status code
    CHARACTER(len=256) :: message    ! [OUT] Diagnostic message
  END TYPE PH_Mat_Creep_Eval_Arg

  ! --- Public type declarations ---
  PUBLIC :: PH_Mat_Creep_Desc, PH_Mat_Creep_State
  PUBLIC :: PH_Mat_Creep_Algo, PH_Mat_Creep_Ctx
  PUBLIC :: PH_Mat_Creep_Eval_Arg
  PUBLIC :: PH_Mat_Creep_Cfg_Init_Desc, PH_Mat_Creep_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Creep_Inc_Evo_Ctx

CONTAINS

  ! ========== Desc TBP implementations ==========

  SUBROUTINE Desc_Init(desc, sub_type, nprops)
    CLASS(PH_Mat_Creep_Desc), INTENT(INOUT) :: desc
    INTEGER(i4), INTENT(IN) :: sub_type, nprops
    desc%cfg%sub_type = sub_type
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    ALLOCATE(desc%props(nprops))
    desc%props = 0.0_wp
    desc%pop%is_valid = .TRUE.
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(desc, status)
    CLASS(PH_Mat_Creep_Desc), INTENT(IN) :: desc
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%has_error = .NOT. desc%pop%is_valid
    IF (status%has_error) THEN
      status%message = 'PH_Mat_Creep_Desc: descriptor is not valid'
    END IF
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_Clean(desc)
    CLASS(PH_Mat_Creep_Desc), INTENT(INOUT) :: desc
    desc%cfg%sub_type = 0_i4
    desc%A = 0.0_wp; desc%n = 0.0_wp; desc%m = 0.0_wp
    desc%Q_act = 0.0_wp
    IF (ALLOCATED(desc%props)) DEALLOCATE(desc%props)
    desc%pop%is_valid = .FALSE.
  END SUBROUTINE Desc_Clean

  ! ========== State TBP implementations ==========

  SUBROUTINE State_Init(state)
    CLASS(PH_Mat_Creep_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%creep_strain = 0.0_wp
    state%equiv_creep_strain = 0.0_wp
    state%creep_strain_rate = 0.0_wp
    state%initialized = .TRUE.
    state%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(state, stress, creep_strain)
    CLASS(PH_Mat_Creep_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress(:), creep_strain(:)
    state%stress = stress
    state%creep_strain = creep_strain
    state%num_evaluations = state%num_evaluations + 1
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(state)
    CLASS(PH_Mat_Creep_State), INTENT(INOUT) :: state
    state%stress = 0.0_wp
    state%creep_strain = 0.0_wp
    state%equiv_creep_strain = 0.0_wp
    state%creep_strain_rate = 0.0_wp
    state%initialized = .FALSE.
    state%num_evaluations = 0
  END SUBROUTINE State_Clean

  ! ========== Algo TBP implementations ==========

  SUBROUTINE Algo_Init(algo)
    CLASS(PH_Mat_Creep_Algo), INTENT(INOUT) :: algo
    algo%integration_method = 1
    algo%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(algo, method, use_num_tang)
    CLASS(PH_Mat_Creep_Algo), INTENT(INOUT) :: algo
    INTEGER(i4), INTENT(IN) :: method
    LOGICAL, INTENT(IN) :: use_num_tang
    algo%integration_method = method
    algo%use_numerical_tangent = use_num_tang
  END SUBROUTINE Algo_Config

  ! ========== Ctx TBP implementations ==========

  SUBROUTINE Ctx_Init(ctx)
    CLASS(PH_Mat_Creep_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%inc%dt = 0.0_wp
    ctx%D_el = 0.0_wp
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(ctx)
    CLASS(PH_Mat_Creep_Ctx), INTENT(INOUT) :: ctx
    ctx%inc%temperature = 293.15_wp
    ctx%inc%dt = 0.0_wp
    ctx%D_el = 0.0_wp
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Creep_Def
