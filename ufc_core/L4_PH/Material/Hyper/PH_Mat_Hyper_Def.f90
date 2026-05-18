!===============================================================================
! MODULE: PH_Mat_Hyper_Def
! LAYER:  L4_PH
! DOMAIN: Material / Hyper
! ROLE:   Def
! BRIEF:  TYPE definitions for hyperelastic material family at L4_PH layer.
!===============================================================================
MODULE PH_Mat_Hyper_Def
  USE IF_Prec_Core, ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_HYPER_SUB_NEO_HOOKEAN = 401_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_HYPER_SUB_MOONEY_RIVLIN = 402_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_HYPER_SUB_OGDEN = 403_i4

  !=============================================================================
  ! Auxiliary types
  !=============================================================================

  TYPE :: PH_Mat_Hyper_Cfg_Init_Desc
    INTEGER(i4) :: family_type = 0
    INTEGER(i4) :: sub_type = 0
    INTEGER(i4) :: property_flags = 0
  END TYPE PH_Mat_Hyper_Cfg_Init_Desc

  TYPE :: PH_Mat_Hyper_Pop_Vld_Desc
    LOGICAL :: is_valid = .FALSE.
  END TYPE PH_Mat_Hyper_Pop_Vld_Desc

  TYPE :: PH_Mat_Hyper_Inc_Evo_Ctx
    REAL(wp) :: temperature = 293.15_wp
    ! TYPE-003: field-variable vector aliases caller/workspace buffer (not ALLOCATABLE in *Ctx)
    REAL(wp), DIMENSION(:), POINTER :: field_var => NULL()
  END TYPE PH_Mat_Hyper_Inc_Evo_Ctx

  !=============================================================================
  ! Primary types
  !=============================================================================

  TYPE :: PH_Mat_Hyper_Desc
    TYPE(PH_Mat_Hyper_Cfg_Init_Desc) :: cfg
    TYPE(PH_Mat_Hyper_Pop_Vld_Desc) :: pop
    REAL(wp) :: C10 = 0.0_wp, C01 = 0.0_wp, D1 = 0.0_wp
    INTEGER(i4) :: num_ogden_terms = 0
    REAL(wp), ALLOCATABLE :: mu_ogden(:), alpha_ogden(:), D_ogden(:)

    ! Yeoh model (404)
    REAL(wp) :: C20 = 0.0_wp            ! Yeoh 2nd order coeff
    REAL(wp) :: C30 = 0.0_wp            ! Yeoh 3rd order coeff

    ! Arruda-Boyce model (405)
    REAL(wp) :: mu_ab = 0.0_wp          ! Arruda-Boyce shear modulus
    REAL(wp) :: lambda_L = 0.0_wp       ! Arruda-Boyce locking stretch
    INTEGER(i4) :: n_ab_terms = 5_i4    ! Arruda-Boyce series terms

    ! Hyperfoam model (406)
    REAL(wp) :: mu_i(5) = 0.0_wp        ! Hyperfoam shear moduli
    REAL(wp) :: alpha_i(5) = 0.0_wp     ! Hyperfoam exponents
    REAL(wp) :: beta_i(5) = 0.0_wp      ! Hyperfoam Poisson ratios

    ! Mullins effect (407)
    REAL(wp) :: r_mullins = 0.0_wp      ! Mullins damage parameter
    REAL(wp) :: beta_mullins = 0.0_wp   ! Mullins evolution rate
    REAL(wp) :: eta_max = 1.0_wp        ! Mullins maximum damage
  CONTAINS
    PROCEDURE, PASS :: Init  => Desc_Init
    PROCEDURE, PASS :: Valid => Desc_Valid
    PROCEDURE, PASS :: Clean => Desc_Clean
  END TYPE PH_Mat_Hyper_Desc

  TYPE :: PH_Mat_Hyper_State
    REAL(wp) :: stress(6) = 0.0_wp, strain(6) = 0.0_wp
    REAL(wp) :: F(3,3) = 0.0_wp, C(3,3) = 0.0_wp
    REAL(wp) :: I1 = 0.0_wp, I2 = 0.0_wp, I3 = 0.0_wp, J = 1.0_wp
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: num_evaluations = 0
  CONTAINS
    PROCEDURE, PASS :: Init   => State_Init
    PROCEDURE, PASS :: Update => State_Update
    PROCEDURE, PASS :: Clean  => State_Clean
  END TYPE PH_Mat_Hyper_State

  TYPE :: PH_Mat_Hyper_Algo
    INTEGER(i4) :: formulation = 1
    LOGICAL :: use_numerical_tangent = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init   => Algo_Init
    PROCEDURE, PASS :: Config => Algo_Config
  END TYPE PH_Mat_Hyper_Algo

  TYPE :: PH_Mat_Hyper_Ctx
    TYPE(PH_Mat_Hyper_Inc_Evo_Ctx) :: inc
    REAL(wp) :: F_trial(3,3) = 0.0_wp, S(3,3) = 0.0_wp
    REAL(wp) :: dW_dI1 = 0.0_wp, dW_dI2 = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init  => Ctx_Init
    PROCEDURE, PASS :: Clean => Ctx_Clean
  END TYPE PH_Mat_Hyper_Ctx

  TYPE :: PH_Mat_Hyper_Eval_Arg
    REAL(wp) :: F(3,3)              ! [IN] Deformation gradient
    REAL(wp) :: dt                  ! [IN] Time increment
    REAL(wp) :: temperature         ! [IN] Current temperature
    REAL(wp), ALLOCATABLE :: statev(:)  ! [INOUT] state variables array
    REAL(wp) :: stress(6)           ! [OUT] Cauchy stress (Voigt)
    REAL(wp) :: ddsdde(6,6)         ! [OUT] Tangent stiffness
    INTEGER(i4) :: status_code      ! [OUT] Completion status code
    CHARACTER(len=256) :: message   ! [OUT] Status message
  END TYPE PH_Mat_Hyper_Eval_Arg

  PUBLIC :: PH_Mat_Hyper_Desc, PH_Mat_Hyper_State
  PUBLIC :: PH_Mat_Hyper_Algo, PH_Mat_Hyper_Ctx
  PUBLIC :: PH_Mat_Hyper_Eval_Arg
  PUBLIC :: PH_Mat_Hyper_Cfg_Init_Desc, PH_Mat_Hyper_Pop_Vld_Desc
  PUBLIC :: PH_Mat_Hyper_Inc_Evo_Ctx

CONTAINS

  !=============================================================================
  ! PH_Mat_Hyper_Desc TBP implementations
  !=============================================================================

  SUBROUTINE Desc_Init(self)
    CLASS(PH_Mat_Hyper_Desc), INTENT(INOUT) :: self
    self%cfg%family_type = 0
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%pop%is_valid = .FALSE.
    self%C10 = 0.0_wp
    self%C01 = 0.0_wp
    self%D1 = 0.0_wp
    self%num_ogden_terms = 0
    IF (ALLOCATED(self%mu_ogden)) DEALLOCATE(self%mu_ogden)
    IF (ALLOCATED(self%alpha_ogden)) DEALLOCATE(self%alpha_ogden)
    IF (ALLOCATED(self%D_ogden)) DEALLOCATE(self%D_ogden)
    ! Yeoh
    self%C20 = 0.0_wp
    self%C30 = 0.0_wp
    ! Arruda-Boyce
    self%mu_ab = 0.0_wp
    self%lambda_L = 0.0_wp
    self%n_ab_terms = 5_i4
    ! Hyperfoam
    self%mu_i = 0.0_wp
    self%alpha_i = 0.0_wp
    self%beta_i = 0.0_wp
    ! Mullins effect
    self%r_mullins = 0.0_wp
    self%beta_mullins = 0.0_wp
    self%eta_max = 1.0_wp
  END SUBROUTINE Desc_Init

  SUBROUTINE Desc_Valid(self)
    CLASS(PH_Mat_Hyper_Desc), INTENT(INOUT) :: self
    self%pop%is_valid = .TRUE.
  END SUBROUTINE Desc_Valid

  SUBROUTINE Desc_Clean(self)
    CLASS(PH_Mat_Hyper_Desc), INTENT(INOUT) :: self
    self%cfg%family_type = 0
    self%cfg%sub_type = 0
    self%cfg%property_flags = 0
    self%pop%is_valid = .FALSE.
    self%C10 = 0.0_wp
    self%C01 = 0.0_wp
    self%D1 = 0.0_wp
    self%num_ogden_terms = 0
    IF (ALLOCATED(self%mu_ogden)) DEALLOCATE(self%mu_ogden)
    IF (ALLOCATED(self%alpha_ogden)) DEALLOCATE(self%alpha_ogden)
    IF (ALLOCATED(self%D_ogden)) DEALLOCATE(self%D_ogden)
    ! Yeoh
    self%C20 = 0.0_wp
    self%C30 = 0.0_wp
    ! Arruda-Boyce
    self%mu_ab = 0.0_wp
    self%lambda_L = 0.0_wp
    self%n_ab_terms = 5_i4
    ! Hyperfoam
    self%mu_i = 0.0_wp
    self%alpha_i = 0.0_wp
    self%beta_i = 0.0_wp
    ! Mullins effect
    self%r_mullins = 0.0_wp
    self%beta_mullins = 0.0_wp
    self%eta_max = 1.0_wp
  END SUBROUTINE Desc_Clean

  !=============================================================================
  ! PH_Mat_Hyper_State TBP implementations
  !=============================================================================

  SUBROUTINE State_Init(self)
    CLASS(PH_Mat_Hyper_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    self%F = 0.0_wp
    self%C = 0.0_wp
    self%I1 = 0.0_wp
    self%I2 = 0.0_wp
    self%I3 = 0.0_wp
    self%J = 1.0_wp
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Init

  SUBROUTINE State_Update(self)
    CLASS(PH_Mat_Hyper_State), INTENT(INOUT) :: self
    self%num_evaluations = self%num_evaluations + 1
    self%initialized = .TRUE.
  END SUBROUTINE State_Update

  SUBROUTINE State_Clean(self)
    CLASS(PH_Mat_Hyper_State), INTENT(INOUT) :: self
    self%stress = 0.0_wp
    self%strain = 0.0_wp
    self%F = 0.0_wp
    self%C = 0.0_wp
    self%I1 = 0.0_wp
    self%I2 = 0.0_wp
    self%I3 = 0.0_wp
    self%J = 1.0_wp
    self%initialized = .FALSE.
    self%num_evaluations = 0
  END SUBROUTINE State_Clean

  !=============================================================================
  ! PH_Mat_Hyper_Algo TBP implementations
  !=============================================================================

  SUBROUTINE Algo_Init(self)
    CLASS(PH_Mat_Hyper_Algo), INTENT(INOUT) :: self
    self%formulation = 1
    self%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Init

  SUBROUTINE Algo_Config(self)
    CLASS(PH_Mat_Hyper_Algo), INTENT(INOUT) :: self
    self%formulation = 1
    self%use_numerical_tangent = .FALSE.
  END SUBROUTINE Algo_Config

  !=============================================================================
  ! PH_Mat_Hyper_Ctx TBP implementations
  !=============================================================================

  SUBROUTINE Ctx_Init(self)
    CLASS(PH_Mat_Hyper_Ctx), INTENT(INOUT) :: self
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%F_trial = 0.0_wp
    self%S = 0.0_wp
    self%dW_dI1 = 0.0_wp
    self%dW_dI2 = 0.0_wp
  END SUBROUTINE Ctx_Init

  SUBROUTINE Ctx_Clean(self)
    CLASS(PH_Mat_Hyper_Ctx), INTENT(INOUT) :: self
    self%inc%temperature = 293.15_wp
    IF (ASSOCIATED(self%inc%field_var)) NULLIFY(self%inc%field_var)
    self%F_trial = 0.0_wp
    self%S = 0.0_wp
    self%dW_dI1 = 0.0_wp
    self%dW_dI2 = 0.0_wp
  END SUBROUTINE Ctx_Clean

END MODULE PH_Mat_Hyper_Def
