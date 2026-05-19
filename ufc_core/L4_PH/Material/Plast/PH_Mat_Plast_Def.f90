!===============================================================================
! MODULE: PH_Mat_Plast_Def
! LAYER:  L4_PH
! DOMAIN: Material / Plast
! ROLE:   Def
! BRIEF:  TYPE definitions for plastic material family at L4_PH layer.
!         Implements four TYPE system: Desc/State/Algo/Ctx + Args
! Purpose: Shared Plast family Desc/State/Algo/Ctx and mat_id sub-family constants.
! Theory: Four-type material contract (L4_PH Material pillar).
! Status: Production | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_J2_ISO    = 201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_KIN_LIN   = 203_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_KIN_COMB  = 204_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_HILL      = 205_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_JOHNSON_C = 206_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_GTN       = 207_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_CHABOCHE  = 208_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_BARLAT    = 209_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_PLAST_SUB_CRYSTAL   = 210_i4

  !=============================================================================
  ! Auxiliary types
  !=============================================================================

  TYPE :: PH_Mat_Plast_Cfg_Init_Desc
    INTEGER(i4) :: family_type = 0
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
    INTEGER(i4) :: hardening_type = 1
  END TYPE PH_Mat_Plast_Cfg_Init_Desc

  TYPE :: PH_Mat_Plast_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Plast_Pop_Vld_Desc

  TYPE :: PH_Mat_Plast_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    ! TYPE-003: field-variable vector aliases caller/workspace buffer (not ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: field_var => NULL()
    REAL(wp) :: dstrain(6) = 0.0_wp    ! [IN] strain increment
  END TYPE PH_Mat_Plast_Inc_Evo_Ctx

  !=============================================================================
  ! Primary types
  !=============================================================================

  TYPE :: PH_Mat_Plast_Desc
    TYPE(PH_Mat_Plast_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Plast_Pop_Vld_Desc) :: pop
    REAL(wp) :: E = 0.0_wp, nu = 0.0_wp, G = 0.0_wp, K = 0.0_wp
    REAL(wp) :: sigma_y = 0.0_wp
    REAL(wp) :: H_iso = 0.0_wp, H_kin = 0.0_wp
    REAL(wp) :: F_hill = 0.0_wp, G_hill = 0.0_wp, H_hill = 0.0_wp
    REAL(wp) :: A_jc = 0.0_wp, B_jc = 0.0_wp, n_jc = 0.0_wp
    REAL(wp), ALLOCATABLE :: props(:)
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Plast_Desc

  TYPE :: PH_Mat_Plast_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: elastic_strain(6) = 0.0_wp
    REAL(wp) :: plastic_strain(6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: backstress(6) = 0.0_wp
    REAL(wp) :: alpha_iso = 0.0_wp
    LOGICAL :: is_plastic = .FALSE., initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Plast_State

  TYPE :: PH_Mat_Plast_Algo
    INTEGER(i4) :: integration_method = 1
    INTEGER(i4) :: max_iterations = 50
    REAL(wp) :: tolerance = 1.0e-8_wp
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Plast_Algo

  TYPE :: PH_Mat_Plast_Ctx
    TYPE(PH_Mat_Plast_Inc_Evo_Ctx) :: inc
    REAL(wp) :: D_el(6,6) = 0.0_wp
    REAL(wp) :: stress_trial(6) = 0.0_wp
    REAL(wp) :: delta_lambda = 0.0_wp
    REAL(wp) :: yield_function = 0.0_wp
    INTEGER(i4) :: num_iterations = 0
    LOGICAL :: converged = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Plast_Ctx

  TYPE :: PH_Mat_Plast_Eval_Arg
    REAL(wp) :: strain(6)              ! [IN] Total strain at start of increment
    REAL(wp) :: dstrain(6)             ! [IN] Strain increment
    REAL(wp) :: dt                     ! [IN] Time increment
    REAL(wp) :: temperature            ! [IN] Current temperature
    REAL(wp) :: dtemp                  ! [IN] Temperature increment
    REAL(wp), ALLOCATABLE :: statev(:) ! [INOUT] state variables array
    REAL(wp) :: stress(6)              ! [OUT] Updated stress (Voigt)
    REAL(wp) :: ddsdde(6,6)            ! [OUT] Consistent tangent stiffness
    INTEGER(i4) :: status_code         ! [OUT] Completion status code
    CHARACTER(LEN=:), ALLOCATABLE :: message  ! [OUT] Status message
  END TYPE PH_Mat_Plast_Eval_Arg

  PUBLIC :: PH_Mat_Plast_Desc, PH_Mat_Plast_State
  PUBLIC :: PH_Mat_Plast_Algo, PH_Mat_Plast_Ctx
  PUBLIC :: PH_Mat_Plast_Eval_Arg
  PUBLIC :: PH_Mat_Plast_Cfg_Init_Desc, PH_Mat_Plast_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Plast_Inc_Evo_Ctx

CONTAINS

  !=============================================================================
  ! PH_Mat_Plast_Desc TBP implementations
  !=============================================================================

  SUBROUTINE Desc_Init(self)
    CLASS(PH_Mat_Plast_Desc), INTENT(INOUT) :: self
    self%cfg%family_type = 0
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%cfg%hardening_type = 1
    self%pop%is_valid = .FALSE.
    self%E = 0.0_wp
    self%nu = 0.0_wp
    self%G = 0.0_wp
    self%K = 0.0_wp
    self%sigma_y = 0.0_wp
    self%H_iso = 0.0_wp
    self%H_kin = 0.0_wp
    self%F_hill = 0.0_wp
    self%G_hill = 0.0_wp
    self%H_hill = 0.0_wp
    self%A_jc = 0.0_wp
    self%B_jc = 0.0_wp
    self%n_jc = 0.0_wp
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(self)
    CLASS(PH_Mat_Plast_Desc), INTENT(INOUT) :: self
    self%pop%is_valid = .TRUE.
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_Clean(self)
    CLASS(PH_Mat_Plast_Desc), INTENT(INOUT) :: self
    self%cfg%family_type = 0
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%cfg%hardening_type = 1
    self%pop%is_valid = .FALSE.
    self%E = 0.0_wp
    self%nu = 0.0_wp
    self%G = 0.0_wp
    self%K = 0.0_wp
    self%sigma_y = 0.0_wp
    self%H_iso = 0.0_wp
    self%H_kin = 0.0_wp
    self%F_hill = 0.0_wp
    self%G_hill = 0.0_wp
    self%H_hill = 0.0_wp
    self%A_jc = 0.0_wp
    self%B_jc = 0.0_wp
    self%n_jc = 0.0_wp
    IF (ALLOCATED(self%props)) DEALLOCATE(self%props)
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! PH_Mat_Plast_State TBP implementations
  !=============================================================================

  SUBROUTINE State_Init(self)
    CLASS(PH_Mat_Plast_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    self%elastic_strain = 0.0_wp
    self%plastic_strain = 0.0_wp
    self%equiv_plastic_strain = 0.0_wp
    self%backstress = 0.0_wp
    self%alpha_iso = 0.0_wp
    self%is_plastic = .FALSE.
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(self)
    CLASS(PH_Mat_Plast_State), INTENT(INOUT) :: self
    self%num_evaluations = self%num_evaluations + 1
    self%initialized = .TRUE.
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(self)
    CLASS(PH_Mat_Plast_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    self%elastic_strain = 0.0_wp
    self%plastic_strain = 0.0_wp
    self%equiv_plastic_strain = 0.0_wp
    self%backstress = 0.0_wp
    self%alpha_iso = 0.0_wp
    self%is_plastic = .FALSE.
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Clean

  !=============================================================================
  ! PH_Mat_Plast_Algo TBP implementations
  !=============================================================================

  SUBROUTINE Algo_Init(self)
    CLASS(PH_Mat_Plast_Algo), INTENT(INOUT) :: self
    self%integration_method = 1
    self%max_iterations = 50
    self%tolerance = 1.0e-8_wp
    self%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(self)
    CLASS(PH_Mat_Plast_Algo), INTENT(INOUT) :: self
    self%integration_method = 1
    self%max_iterations = 50
    self%tolerance = 1.0e-8_wp
    self%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Config

  !=============================================================================
  ! PH_Mat_Plast_Ctx TBP implementations
  !=============================================================================

  SUBROUTINE Ctx_Init(self)
    CLASS(PH_Mat_Plast_Ctx), INTENT(INOUT) :: self
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%D_el = 0.0_wp
    self%stress_trial = 0.0_wp
    self%delta_lambda = 0.0_wp
    self%yield_function = 0.0_wp
    self%num_iterations = 0
    self%converged = .FALSE.
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(self)
    CLASS(PH_Mat_Plast_Ctx), INTENT(INOUT) :: self
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%D_el = 0.0_wp
    self%stress_trial = 0.0_wp
    self%delta_lambda = 0.0_wp
    self%yield_function = 0.0_wp
    self%num_iterations = 0
    self%converged = .FALSE.
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Plast_Def
