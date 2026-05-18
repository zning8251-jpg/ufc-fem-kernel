!===============================================================================
! MODULE: PH_Mat_Visco_Def
! LAYER:  L4_PH
! DOMAIN: Material / Visco
! ROLE:   Def
! BRIEF:  TYPE definitions for viscoelastic material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + Args
!===============================================================================
MODULE PH_Mat_Visco_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_VISCO_SUB_PRONY    = 501_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_VISCO_SUB_KELVIN   = 502_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_VISCO_SUB_MAXWELL  = 503_i4

  !=============================================================================
  ! Auxiliary types
  !=============================================================================

  TYPE :: PH_Mat_Visco_Cfg_Init_Desc
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
  END TYPE PH_Mat_Visco_Cfg_Init_Desc

  TYPE :: PH_Mat_Visco_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Visco_Pop_Vld_Desc

  TYPE :: PH_Mat_Visco_Inc_Evo_Ctx
    REAL(wp) :: dt = 0.0_wp
    REAL(wp) :: temperature = 293.15_wp
    ! TYPE-003: field-variable vector aliases caller/workspace buffer (not ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: field_var => NULL()
  END TYPE PH_Mat_Visco_Inc_Evo_Ctx

  !=============================================================================
  ! Primary types
  !=============================================================================

  TYPE :: PH_Mat_Visco_Desc
    TYPE(PH_Mat_Visco_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Visco_Pop_Vld_Desc) :: pop
    REAL(wp), ALLOCATABLE :: tau_k(:)
    REAL(wp), ALLOCATABLE :: g_k(:)
    REAL(wp) :: g_inf = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
    ! --- Core fields ---
    INTEGER(i4) :: sub_type = 0
    LOGICAL :: is_valid = .FALSE.
    REAL(wp) :: E_inf = 0.0_wp
    REAL(wp) :: nu = 0.3_wp
    INTEGER(i4) :: n_prony_terms = 0
    REAL(wp) :: g_i(10) = 0.0_wp
    REAL(wp) :: tau_i(10) = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Visco_Desc

  TYPE :: PH_Mat_Visco_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp), ALLOCATABLE :: s_k_6(:,:)
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Visco_State

  TYPE :: PH_Mat_Visco_Algo
    INTEGER(i4) :: integration_method = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
    REAL(wp) :: time_step = 1.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Visco_Algo

  TYPE :: PH_Mat_Visco_Ctx
    TYPE(PH_Mat_Visco_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: D_inst(6,6) = 0.0_wp
    LOGICAL :: D_inst_cached = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Visco_Ctx

  TYPE :: PH_Mat_Visco_Eval_Arg
    REAL(wp) :: strain(6)              ! [IN] Total strain at start of increment
    REAL(wp) :: dstrain(6)             ! [IN] Strain increment
    REAL(wp) :: dt                     ! [IN] Time increment
    REAL(wp) :: temperature            ! [IN] Current temperature
    REAL(wp) :: stress(6)              ! [OUT] Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6)            ! [OUT] Consistent tangent stiffness
    INTEGER(i4) :: status_code         ! [OUT] Completion status code
    CHARACTER(LEN=:), ALLOCATABLE :: message  ! [OUT] Status message
  END TYPE PH_Mat_Visco_Eval_Arg

  PUBLIC :: PH_Mat_Visco_Desc, PH_Mat_Visco_State
  PUBLIC :: PH_Mat_Visco_Algo, PH_Mat_Visco_Ctx
  PUBLIC :: PH_Mat_Visco_Eval_Arg
  PUBLIC :: PH_Mat_Visco_Cfg_Init_Desc, PH_Mat_Visco_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Visco_Inc_Evo_Ctx

CONTAINS

  !=============================================================================
  ! PH_Mat_Visco_Desc TBP implementations
  !=============================================================================

  SUBROUTINE Desc_Init(self)
    CLASS(PH_Mat_Visco_Desc), INTENT(INOUT) :: self
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%pop%is_valid = .FALSE.
    self%g_inf = 0.0_wp
    self%sub_type = 0
    self%is_valid = .FALSE.
    self%E_inf = 0.0_wp
    self%nu = 0.3_wp
    self%n_prony_terms = 0
    self%g_i = 0.0_wp
    self%tau_i = 0.0_wp
    IF (ALLOCATED(self%tau_k)) DEALLOCATE(self%tau_k)
    IF (ALLOCATED(self%g_k)) DEALLOCATE(self%g_k)
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(self)
    CLASS(PH_Mat_Visco_Desc), INTENT(INOUT) :: self
    self%pop%is_valid = .TRUE.
    self%is_valid = .TRUE.
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_Clean(self)
    CLASS(PH_Mat_Visco_Desc), INTENT(INOUT) :: self
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%pop%is_valid = .FALSE.
    self%g_inf = 0.0_wp
    self%sub_type = 0
    self%is_valid = .FALSE.
    self%E_inf = 0.0_wp
    self%nu = 0.3_wp
    self%n_prony_terms = 0
    self%g_i = 0.0_wp
    self%tau_i = 0.0_wp
    IF (ALLOCATED(self%tau_k)) DEALLOCATE(self%tau_k)
    IF (ALLOCATED(self%g_k)) DEALLOCATE(self%g_k)
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! PH_Mat_Visco_State TBP implementations
  !=============================================================================

  SUBROUTINE State_Init(self)
    CLASS(PH_Mat_Visco_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    IF (ALLOCATED(self%s_k_6)) DEALLOCATE(self%s_k_6)
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(self)
    CLASS(PH_Mat_Visco_State), INTENT(INOUT) :: self
    self%num_evaluations = self%num_evaluations + 1
    self%initialized = .TRUE.
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(self)
    CLASS(PH_Mat_Visco_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    IF (ALLOCATED(self%s_k_6)) DEALLOCATE(self%s_k_6)
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Clean

  !=============================================================================
  ! PH_Mat_Visco_Algo TBP implementations
  !=============================================================================

  SUBROUTINE Algo_Init(self)
    CLASS(PH_Mat_Visco_Algo), INTENT(INOUT) :: self
    self%integration_method = 1
    self%use_numerical_tangent = .FALSE.
    self%time_step = 1.0_wp
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(self)
    CLASS(PH_Mat_Visco_Algo), INTENT(INOUT) :: self
    self%integration_method = 1
    self%use_numerical_tangent = .FALSE.
    self%time_step = 1.0_wp
  END SUBROUTINE Algo_Config

  !=============================================================================
  ! PH_Mat_Visco_Ctx TBP implementations
  !=============================================================================

  SUBROUTINE Ctx_Init(self)
    CLASS(PH_Mat_Visco_Ctx), INTENT(INOUT) :: self
    self%inc%dt = 0.0_wp
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%D_el = 0.0_wp
    self%D_inst = 0.0_wp
    self%D_inst_cached = .FALSE.
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(self)
    CLASS(PH_Mat_Visco_Ctx), INTENT(INOUT) :: self
    self%inc%dt = 0.0_wp
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%D_el = 0.0_wp
    self%D_inst = 0.0_wp
    self%D_inst_cached = .FALSE.
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Visco_Def
