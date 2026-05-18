!===============================================================================
! MODULE: PH_Mat_Plast_Chaboche_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Chaboche multi-backstress plasticity for cyclic loading —
!         **W1**：背应力/各向同性硬化参数自 **`desc%props`**；**PH_MAT_PLASTIC** /
!         **Effective_Model** 与 **PH_MatPLMEval** 金线协同。
!===============================================================================
! ! @details Chaboche multi-backstress plastic constitutive model
! ! Core objective: Cyclic plasticity and ratcheting effect modeling
!! Theoretical basis : Chaboche nonlinear kinematic hardening with multiple back-stresses
!!
!! *Chaboche yield criterion *:
!!   - f = 3Js - X)) - σ_y = 0
! ! - X = Σ X_i (multi-backstress superposition)
! ! - s = deviatoric stress tensor
!!
! ! **Backstress evolution (Armstrong-Frederick type)**:
!!   - dX_i = (2/3)·C_i·dε^p - γ_i·X_i·dλ
! ! - C_i = Initial hardening modulus
!! - γ_i = saturation hardening parameter
!!
! ! **Isotropic hardening**:
!!   - dR = b·(R_- R)·dλ
!! - R = isotropic hardening variable
!! - R_= saturation
!!
!! Typical applications *:
!! - low-cycle fatigue
!! - cyclic loading
!! - ratcheting effect
! ! - Multi-axial fatigue
!!
!! @author UFC Development Team
!! @date 2026-02-05
!! @version 1.0
!! @see Chaboche, "Constitutive equations for cyclic plasticity" (1989)

!===============================================================================
! Module: PH_Mat_PLM_Chaboche
! Layer:  L4_PH - Physics Layer
! Domain: Mat - Material
! Purpose: Mat Chab Core module (auto-filled)
! Theory: Internal UFC architecture spec §1 (see UFC_ .md)
! Status:  [STUB/CORE/PROD] | Last verified: 2026-02-28
!
! Contents (A-Z):
!   Types:
!     - [List types in A-Z order]
!   Subroutines:
!     - [List subroutines in A-Z order]
!   Functions:
!     - [List functions in A-Z order]
!===============================================================================

MODULE PH_Mat_Plast_Chaboche_Core
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! Theory: Internal UFC architecture (see UFC docs). Last verified: 2026-02-14
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, THIRD
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Plast_Contract, ONLY: PlastMatBase
  USE MD_Mat_Plast_Chaboche, ONLY: MD_MAT_CHABOCHE_MAT_ID, CHABOCHE_MAT_NA, UF_Chaboche_ValidateProps, &
      MD_MAT_CHAB_PROP_E, MD_MAT_CHAB_PROP_NU, MD_MAT_CHAB_PROP_SIGMA_Y0, MD_MAT_CHAB_PROP_H, &
      MD_MAT_CHAB_PROP_N_COMP, MD_MAT_CHAB_PROP_C1, MD_MAT_CHAB_PROP_GAMMA1, &
      MD_MAT_CHAB_PROP_C2, MD_MAT_CHAB_PROP_GAMMA2, MD_MAT_CHAB_PROP_C3, MD_MAT_CHAB_PROP_GAMMA3, &
      MD_MAT_CHAB_MIN_PROPS, MD_MAT_CHAB_MAX_PROPS, &
      MD_MAT_CHAB_STATEV_EPS_EQV, MD_MAT_CHAB_STATEV_WORK, MD_MAT_CHAB_STATEV_ALPHA1, &
      MD_MAT_CHAB_STATEV_ALPHA2, MD_MAT_CHAB_STATEV_ALPHA3, MD_MAT_CHAB_STATEV_EPS_P
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D, Calc_Deviatoric_Stress, Calc_Von_Mises

  ! Legacy naming aliases (former module MD_MatPLMChaboche deleted)
  INTEGER(i4), PARAMETER :: CHABOCHE_MAT_ID = MD_MAT_CHABOCHE_MAT_ID
  INTEGER(i4), PARAMETER :: CHAB_PROP_E = MD_MAT_CHAB_PROP_E
  INTEGER(i4), PARAMETER :: CHAB_PROP_NU = MD_MAT_CHAB_PROP_NU
  INTEGER(i4), PARAMETER :: CHAB_PROP_SIGMA_Y0 = MD_MAT_CHAB_PROP_SIGMA_Y0
  INTEGER(i4), PARAMETER :: CHAB_PROP_H = MD_MAT_CHAB_PROP_H
  INTEGER(i4), PARAMETER :: CHAB_PROP_N_COMP = MD_MAT_CHAB_PROP_N_COMP
  INTEGER(i4), PARAMETER :: CHAB_PROP_C1 = MD_MAT_CHAB_PROP_C1
  INTEGER(i4), PARAMETER :: CHAB_PROP_GAMMA1 = MD_MAT_CHAB_PROP_GAMMA1
  INTEGER(i4), PARAMETER :: CHAB_PROP_C2 = MD_MAT_CHAB_PROP_C2
  INTEGER(i4), PARAMETER :: CHAB_PROP_GAMMA2 = MD_MAT_CHAB_PROP_GAMMA2
  INTEGER(i4), PARAMETER :: CHAB_PROP_C3 = MD_MAT_CHAB_PROP_C3
  INTEGER(i4), PARAMETER :: CHAB_PROP_GAMMA3 = MD_MAT_CHAB_PROP_GAMMA3
  INTEGER(i4), PARAMETER :: CHAB_MIN_PROPS = MD_MAT_CHAB_MIN_PROPS
  INTEGER(i4), PARAMETER :: CHAB_MAX_PROPS = MD_MAT_CHAB_MAX_PROPS
  INTEGER(i4), PARAMETER :: CHAB_STATEV_EPS_EQV = MD_MAT_CHAB_STATEV_EPS_EQV
  INTEGER(i4), PARAMETER :: CHAB_STATEV_WORK = MD_MAT_CHAB_STATEV_WORK
  INTEGER(i4), PARAMETER :: CHAB_STATEV_ALPHA1 = MD_MAT_CHAB_STATEV_ALPHA1
  INTEGER(i4), PARAMETER :: CHAB_STATEV_ALPHA2 = MD_MAT_CHAB_STATEV_ALPHA2
  INTEGER(i4), PARAMETER :: CHAB_STATEV_ALPHA3 = MD_MAT_CHAB_STATEV_ALPHA3
  INTEGER(i4), PARAMETER :: CHAB_STATEV_EPS_P = MD_MAT_CHAB_STATEV_EPS_P

  IMPLICIT NONE
  PRIVATE

  REAL(wp), PARAMETER :: ph_chab_tol = 1.0e-10_wp
  REAL(wp), PARAMETER :: ph_chab_reg = 1.0e-10_wp

  TYPE, PRIVATE :: ChabMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    INTEGER(i4) :: n_components = 2_i4
    REAL(wp) :: C(3) = 0.0_wp
    REAL(wp) :: gamma(3) = 0.0_wp
    LOGICAL :: init = .FALSE.
  END TYPE ChabMat

  INTEGER(i4), PARAMETER :: PH_MAT_MAX_BACK_STRESSES = 5_i4

  TYPE, PUBLIC :: PH_Chab_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Chab_Cfg_Elastic

  TYPE, PUBLIC :: PH_Chab_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp ! Initial yield stress
  END TYPE PH_Chab_Cfg_Yield

  TYPE, PUBLIC :: PH_Chab_Cfg_BackStress
    INTEGER(i4) :: n_back_stresses = 2_i4 ! Number of backstresses (typically 2-4)
    REAL(wp) :: C_kinematic(PH_MAT_MAX_BACK_STRESSES) = 0.0_wp ! Kinematic hardening modulus
    REAL(wp) :: gamma_recall(PH_MAT_MAX_BACK_STRESSES) = 0.0_wp ! Dynamic recovery parameter
  END TYPE PH_Chab_Cfg_BackStress

  TYPE, PUBLIC :: PH_Chab_Cfg_Isotrop
    REAL(wp) :: b_isotropic = 0.0_wp ! Isotropic hardening rate
    REAL(wp) :: R_infinity = 0.0_wp  ! Saturation isotropic hardening
  END TYPE PH_Chab_Cfg_Isotrop

  TYPE, PUBLIC :: Chab_Params
    TYPE(PH_Chab_Cfg_Elastic)    :: elastic
    TYPE(PH_Chab_Cfg_Yield)      :: yield
    TYPE(PH_Chab_Cfg_BackStress) :: back
    TYPE(PH_Chab_Cfg_Isotrop)    :: isotrop
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Chab_Params

  TYPE, PUBLIC :: Chab_State
    REAL(wp), ALLOCATABLE :: stress_current(:)
    REAL(wp), ALLOCATABLE :: strain_plastic(:)
    REAL(wp), ALLOCATABLE :: back_stress(:,:)  ! n_back × 6
    REAL(wp), ALLOCATABLE :: back_stress_total(:)
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: R_isotropic = 0.0_wp ! isotropic hardening variable
    REAL(wp) :: yield_stress_current = 0.0_wp
    LOGICAL  :: is_plastic = .FALSE.
  END TYPE

  PUBLIC :: PH_Mat_Chaboche_Init, PH_Mat_Chaboche_Calc_Stress
  PUBLIC :: UF_Chaboche_UMAT

CONTAINS

  SUBROUTINE PH_Mat_Chaboche_Init(params, state)
    TYPE(Chab_Params), INTENT(IN) :: params
    TYPE(Chab_State), INTENT(INOUT) :: state
    
    ALLOCATE(state%stress_current(6), state%strain_plastic(6))
    ALLOCATE(state%back_stress(params%back%n_back_stresses, 6))
    ALLOCATE(state%back_stress_total(6))
    
    state%stress_current = ZERO
    state%strain_plastic = ZERO
    state%back_stress = ZERO
    state%back_stress_total = ZERO
    state%equiv_plastic_strain = ZERO
    state%R_isotropic = ZERO
    state%yield_stress_current = params%yield%yield_stress_0
    state%is_plastic = .FALSE.
  END SUBROUTINE PH_Mat_Chaboche_Init

  SUBROUTINE PH_Mat_Chaboche_Calc_Stress(params, state, strain_increment, sigma)
    TYPE(Chab_Params), INTENT(IN) :: params
    TYPE(Chab_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: strain_increment(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: s_trial(6), xi_trial(6), q_trial, yield_function
    
    CALL Construct_Elastic_D(params%elastic%E_modulus, params%elastic%nu_poisson, D_elastic)
    stress_trial = state%stress_current + MATMUL(D_elastic, strain_increment)
    
    ! Calculate trial deviatoric stress
    CALL Calc_Deviatoric_Stress(stress_trial, s_trial)
    
    ! calculate total   stress
    state%back_stress_total = SUM(state%back_stress, DIM=1)
    
    ! calculate   asymmetric   stress : ξ = s - X
    xi_trial = s_trial - state%back_stress_total
    
    ! von von Mises equivalent stress (   asymmetric )
    q_trial = Calc_Von_Mises(xi_trial)
    
    ! update yield stress ( isotropic hardening )
    state%yield_stress_current = params%yield%yield_stress_0 + state%R_isotropic
    
    ! yield  
    yield_function = q_trial - state%yield_stress_current
    
    IF (yield_function > ZERO) THEN
      state%is_plastic = .TRUE.
      CALL Return_Mapping_Chaboche(params, state, stress_trial, sigma)
    ELSE
      state%is_plastic = .FALSE.
      sigma = stress_trial
    END IF
    
    state%stress_current = sigma
  END SUBROUTINE PH_Mat_Chaboche_Calc_Stress

  !> @brief Chaboche return mapping algorithm
  SUBROUTINE Return_Mapping_Chaboche(params, state, stress_trial, sigma)
    TYPE(Chab_Params), INTENT(IN) :: params
    TYPE(Chab_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress_trial(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: delta_lambda, s_trial(6), xi(6), n(6)
    REAL(wp) :: G_modulus
    INTEGER(i4) :: i_back
    
    G_modulus = params%elastic%E_modulus / (TWO * (ONE + params%elastic%nu_poisson))
    
    ! simplified ize implements :  delta_lambda 
    delta_lambda = 0.001_wp
    
    ! calculate flow direction
    CALL Calc_Deviatoric_Stress(stress_trial, s_trial)
    xi = s_trial - state%back_stress_total
    n = xi / Calc_Von_Mises(xi)
    
    ! update   stress ( Chaboche model type
    DO i_back = 1, params%back%n_back_stresses
      CALL Update_Back_Stress_Chaboche(params, state, i_back, delta_lambda, n)
    END DO
    
    ! update isotropic  
    CALL Update_Isotropic_Hardening(params, state, delta_lambda)
    
    ! update equivalent plastic stress
    state%equiv_plastic_strain = state%equiv_plastic_strain + delta_lambda
    
    ! update stress
    sigma = stress_trial - TWO * G_modulus * delta_lambda * n
  END SUBROUTINE Return_Mapping_Chaboche

  !> @brief update   stress ( Armstrong-Frederick type )
  SUBROUTINE Update_Back_Stress_Chaboche(params, state, i_back, delta_lambda, n)
    TYPE(Chab_Params), INTENT(IN) :: params
    TYPE(Chab_State), INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: i_back
    REAL(wp), INTENT(IN) :: delta_lambda, n(6)
    REAL(wp) :: dX(6), C_i, gamma_i
    
    C_i = params%back%C_kinematic(i_back)
    gamma_i = params%back%gamma_recall(i_back)
    
    ! Armstrong-Frederick  ize   : dX_i = (2/3)·C_i·dε^p - γ_i·X_i·dλ
    dX = (TWO * THIRD) * C_i * delta_lambda * n - &
         gamma_i * state%back_stress(i_back, :) * delta_lambda
    
    state%back_stress(i_back, :) = state%back_stress(i_back, :) + dX
  END SUBROUTINE Update_Back_Stress_Chaboche

  !> @brief update isotropic  
  SUBROUTINE Update_Isotropic_Hardening(params, state, delta_lambda)
    TYPE(Chab_Params), INTENT(IN) :: params
    TYPE(Chab_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: delta_lambda
    REAL(wp) :: dR
    
    ! Voce type isotropic hardening : dR = b·(R_- R)·dλ
    dR = params%isotrop%b_isotropic * (params%isotrop%R_infinity - state%R_isotropic) * delta_lambda
    state%R_isotropic = state%R_isotropic + dR
  END SUBROUTINE Update_Isotropic_Hardening

  !=============================================================================
  ! Init Chaboche Mat
  !=============================================================================

  SUBROUTINE UF_Chaboche_Init(Mat, props, nprops, status)
    !! Init Chaboche Mat from properties array

    TYPE(ChabMat), INTENT(OUT) :: Mat
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n_comp

    CALL init_error_status(status)

    ! Valid properties
    CALL UF_Chaboche_ValidateProps(props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! Extract Mat properties
    Mat%PH_MAT_E = props(CHAB_PROP_E)
    Mat%nu = props(CHAB_PROP_NU)
    Mat%base%hardening%sigma_y0 = props(CHAB_PROP_SIGMA_Y0)
    Mat%base%hardening%H = props(CHAB_PROP_H)

    ! Number of back-stress components
    n_comp = INT(props(CHAB_PROP_N_COMP), i4)
    Mat%n_components = MAX(1_i4, MIN(3_i4, n_comp))

    ! Extract back-stress parameters
    Mat%C(1) = props(CHAB_PROP_C1)
    Mat%gamma(1) = props(CHAB_PROP_GAMMA1)
    Mat%C(2) = props(CHAB_PROP_C2)
    Mat%gamma(2) = props(CHAB_PROP_GAMMA2)

    ! Optional third component
    IF (nprops >= CHAB_PROP_C3) THEN
      Mat%C(3) = props(CHAB_PROP_C3)
      Mat%gamma(3) = props(CHAB_PROP_GAMMA3)
    ELSE
      Mat%C(3) = ZERO
      Mat%gamma(3) = ZERO
    END IF

    ! Compute Lame parameters
    Mat%lambda = Mat%PH_MAT_E * Mat%nu / &
                      ((ONE + Mat%nu) * (ONE - TWO * Mat%nu))
    Mat%mu = Mat%PH_MAT_E / (TWO * (ONE + Mat%nu))
    Mat%K = Mat%PH_MAT_E / (THREE * (ONE - TWO * Mat%nu))

    ! Init base
    Mat%base%material_id = CHABOCHE_MAT_ID
    Mat%base%name = CHABOCHE_MAT_NA
    Mat%base%yield_criterion = 8_i4  ! Chaboche yield criterion
    Mat%base%hardening%hardening_type = 2_i4  ! Kinematic hardening

    Mat%init = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Chaboche_Init

  !=============================================================================
  ! Valid Properties
  !=============================================================================


  !=============================================================================
  ! Compute Yield Function
  !=============================================================================

  SUBROUTINE UF_Chaboche_ComputeYieldFunction(sigma_dev, alpha_total, sigma_y, &
                                               yield_function, status)
    !! Compute Chaboche yield function
    !! f = || -  || -  _y = 0

    REAL(wp), INTENT(IN) :: sigma_dev(6)    ! Deviatoric stress
    REAL(wp), INTENT(IN) :: alpha_total(6)  ! Total back-stress
    REAL(wp), INTENT(IN) :: sigma_y         ! Yield stress
    REAL(wp), INTENT(OUT) :: yield_function
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: xi(6)  ! Relative stress:  -
    REAL(wp) :: xi_norm

    CALL init_error_status(status)

    ! Compute relative stress
    xi(1:6) = sigma_dev(1:6) - alpha_total(1:6)

    ! Compute norm: ||xi|| = sqrt(3/2 * xi:xi)
    xi_norm = SQRT(1.5_wp * DOT_PRODUCT(xi(1:6), xi(1:6)))

    ! Yield function
    yield_function = xi_norm - sigma_y

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Chaboche_ComputeYieldFunction

  !=============================================================================
  ! Update Back-Stress Components
  !=============================================================================

  SUBROUTINE UF_Chaboche_UpdateBackStress(alpha_old, dlambda, d_eps_p, &
                                           eps_p_eqv_dot, Mat, &
                                           alpha_new, status)
    !! Update back-stress components
    !! d )dt = (2/3)*Cd )-  ) )d eq

    REAL(wp), INTENT(IN) :: alpha_old(6,3)  ! Old back-stress components (6 components n_components)
    REAL(wp), INTENT(IN) :: dlambda         ! Plastic multiplier
    REAL(wp), INTENT(IN) :: d_eps_p(6)       ! Plastic strain increment
    REAL(wp), INTENT(IN) :: eps_p_eqv_dot   ! Equivalent plastic strain rate
    TYPE(ChabMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(OUT) :: alpha_new(6,3) ! New back-stress components
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i, j
    REAL(wp) :: coeff1, coeff2

    CALL init_error_status(status)

    alpha_new = alpha_old

    ! Update each back-stress component
    DO i = 1, Mat%n_components
      IF (Mat%C(i) > ph_chab_reg) THEN
        ! Evolution: d )= (2/3)*Cd )-  ) )d eq
        coeff1 = TWO / THREE * Mat%C(i)
        coeff2 = Mat%gamma(i) * eps_p_eqv_dot

        DO j = 1, 6
          alpha_new(j, i) = alpha_old(j, i) + &
                            coeff1 * d_eps_p(j) - &
                            coeff2 * alpha_old(j, i)
        END DO
      END IF
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Chaboche_UpdateBackStress

  !=============================================================================
  ! Compute Total Back-Stress
  !=============================================================================

  SUBROUTINE UF_Chaboche_ComputeTotalBackStress(alpha_component, n_components, &
                                                  alpha_total)
    !! Compute total back-stress: =

    REAL(wp), INTENT(IN) :: alpha_component(6,3)
    INTEGER(i4), INTENT(IN) :: n_components
    REAL(wp), INTENT(OUT) :: alpha_total(6)

    INTEGER(i4) :: i

    alpha_total = ZERO
    DO i = 1, n_components
      alpha_total(1:6) = alpha_total(1:6) + alpha_component(1:6, i)
    END DO

  END SUBROUTINE UF_Chaboche_ComputeTotalBackStress

  !=============================================================================
  ! Standard UMAT Interface
  !=============================================================================

  SUBROUTINE UF_Chaboche_UMAT(sigma, statev, ddsdde, sse, spd, scd, rpl, &
                               ddsddt, drplde, drpldt, &
                               stran, dstran, time, dtime, temp, dtemp, &
                               predef, dpred, ndir, nshr, nstatev, nprops, &
                               props, ndim, kstep, kinc, status)
    !! Standard UMAT interface for Chaboche kinematic hardening plasticity

    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(ChabMat) :: Mat
    REAL(wp) :: stress_trial(6), stress_new(6), D_elastic(6,6)
    REAL(wp) :: sigma_dev_trial(6), p_mean
    REAL(wp) :: alpha_old(6,3), alpha_new(6,3), alpha_total_old(6), alpha_total_new(6)
    REAL(wp) :: sigma_y_old, sigma_y_new
    REAL(wp) :: eps_p_eqv_old, eps_p_eqv_new
    REAL(wp) :: yield_function
    REAL(wp) :: dlambda
    REAL(wp) :: plastic_strain(6)
    REAL(wp) :: n_flow(6)  ! Flow direction
    INTEGER(i4) :: ntens, i, j, iter
    LOGICAL :: plastic_loading, converged

    CALL init_error_status(status)

    ! Init outputs
    sse = ZERO
    spd = ZERO
    scd = ZERO
    rpl = ZERO
    ddsddt = ZERO
    drplde = ZERO
    drpldt = ZERO
    ddsdde = ZERO

    ! Init Mat
    CALL UF_Chaboche_Init(Mat, props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ntens = ndir + nshr

    ! Init state variables (first increment)
    IF (kinc == 1) THEN
      statev(CHAB_STATEV_EPS_EQV) = ZERO
      statev(CHAB_STATEV_WORK) = ZERO
      DO i = 1, Mat%n_components
        DO j = 1, 6
          statev(CHAB_STATEV_ALPHA1 + (i-1)*6 + j - 1) = ZERO
        END DO
      END DO
      DO i = CHAB_STATEV_EPS_P, MIN(CHAB_STATEV_EPS_P + 5, nstatev)
        statev(i) = ZERO
      END DO
    END IF

    ! Extract historical state variables
    eps_p_eqv_old = statev(CHAB_STATEV_EPS_EQV)
    sigma_y_old = Mat%base%hardening%sigma_y0 + &
                  Mat%base%hardening%H * eps_p_eqv_old

    ! Extract back-stress components
    DO i = 1, Mat%n_components
      DO j = 1, 6
        alpha_old(j, i) = statev(CHAB_STATEV_ALPHA1 + (i-1)*6 + j - 1)
      END DO
    END DO

    ! Compute total back-stress
    CALL UF_Chaboche_ComputeTotalBackStress(alpha_old, Mat%n_components, &
                                             alpha_total_old)

    ! Build elastic stiffness matrix
    CALL chab_build_elastic_stiffness(Mat%lambda, Mat%mu, ndim, D_elastic)

    ! Compute trial stress
    CALL chab_compute_trial_stress(stress, dstran, D_elastic, ndir, nshr, ntens, &
                                stress_trial)

    ! Compute deviatoric stress
    CALL chab_compute_deviatoric_stress(stress_trial, sigma_dev_trial, p_mean, &
                                     ndir, nshr, ntens)

    ! Check yield condition
    CALL UF_Chaboche_ComputeYieldFunction(sigma_dev_trial, alpha_total_old, &
                                           sigma_y_old, yield_function, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    plastic_loading = (yield_function > ph_chab_tol)

    ! Return mapping if yielding
    IF (plastic_loading) THEN
      ! Compute flow direction: n = ( -  / || -  ||
      n_flow(1:6) = sigma_dev_trial(1:6) - alpha_total_old(1:6)
      CALL chab_normalize_vector(n_flow, 6)

      ! Simplified return mapping
      dlambda = yield_function / (THREE * Mat%mu + Mat%base%hardening%H)
      dlambda = MAX(dlambda, ZERO)

      ! Update equivalent plastic strain
      eps_p_eqv_new = eps_p_eqv_old + dlambda
      sigma_y_new = Mat%base%hardening%sigma_y0 + &
                    Mat%base%hardening%H * eps_p_eqv_new

      ! Compute plastic strain increment
      plastic_strain(1:6) = dlambda * n_flow(1:6)

      ! Update back-stress components
      CALL UF_Chaboche_UpdateBackStress(alpha_old, dlambda, &
                                         plastic_strain, &
                                         dlambda / dtime, Mat, &
                                         alpha_new, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN

      ! Compute new total back-stress
      CALL UF_Chaboche_ComputeTotalBackStress(alpha_new, Mat%n_components, &
                                               alpha_total_new)

      ! Update stress
      stress_new(1:3) = -p_mean / THREE + &
                        sigma_dev_trial(1:3) - &
                        THREE * Mat%mu * plastic_strain(1:3)
      IF (ntens >= 4) THEN
        stress_new(4:ntens) = sigma_dev_trial(4:ntens) - &
                               TWO * Mat%mu * plastic_strain(4:ntens)
      END IF

      ! Compute tangent stiffness
      CALL UF_Chaboche_ComputeTangent(Mat, stress_new, alpha_total_new, &
                                       sigma_y_new, D_elastic, ddsdde, &
                                       ndir, nshr, ntens, status)

      spd = sigma_y_new * dlambda
    ELSE
      ! Elastic step
      stress_new(1:ntens) = stress_trial(1:ntens)
      alpha_new = alpha_old
      alpha_total_new = alpha_total_old
      eps_p_eqv_new = eps_p_eqv_old
      sigma_y_new = sigma_y_old
      plastic_strain = ZERO
      ddsdde(1:ntens,1:ntens) = D_elastic(1:ntens,1:ntens)
      spd = ZERO
    END IF

    ! Update stress
    stress(1:ntens) = stress_new(1:ntens)

    ! Update state variables
    statev(CHAB_STATEV_EPS_EQV) = eps_p_eqv_new
    statev(CHAB_STATEV_WORK) = statev(CHAB_STATEV_WORK) + spd

    ! Update back-stress components
    DO i = 1, Mat%n_components
      DO j = 1, 6
        statev(CHAB_STATEV_ALPHA1 + (i-1)*6 + j - 1) = alpha_new(j, i)
      END DO
    END DO

    ! Save plastic strain components
    IF (nstatev >= CHAB_STATEV_EPS_P + 5) THEN
      DO i = 1, MIN(6, nstatev - CHAB_STATEV_EPS_P + 1)
        statev(CHAB_STATEV_EPS_P + i - 1) = &
          statev(CHAB_STATEV_EPS_P + i - 1) + plastic_strain(i)
      END DO
    END IF

    ! Compute strain energy
    sse = 0.5_wp * DOT_PRODUCT(stress(1:ntens), stran(1:ntens) + dstran(1:ntens))

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Chaboche_UMAT

  !=============================================================================
  ! Helper: Build Elastic Stiffness Matrix
  !=============================================================================


  SUBROUTINE chab_compute_deviatoric_stress(stress, s_dev, p_mean, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(OUT) :: s_dev(6), p_mean
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens
    INTEGER(i4) :: i, ncomp
    ncomp = MIN(3_i4, ndir)
    p_mean = ZERO
    DO i = 1, ncomp
      p_mean = p_mean + stress(i)
    END DO
    p_mean = p_mean / THREE
    s_dev = stress
    DO i = 1, ncomp
      s_dev(i) = s_dev(i) - p_mean
    END DO
  END SUBROUTINE chab_compute_deviatoric_stress

  SUBROUTINE chab_build_elastic_stiffness(lambda, mu, ndim, D_elastic)
    !! Build elastic stiffness matrix

    REAL(wp), INTENT(IN) :: lambda, mu
    INTEGER(i4), INTENT(IN) :: ndim
    REAL(wp), INTENT(OUT) :: D_elastic(6,6)

    INTEGER(i4) :: i, j

    D_elastic = ZERO

    ! Diagonal terms
    DO i = 1, 3
      D_elastic(i, i) = lambda + TWO * mu
    END DO

    ! Off-diagonal terms
    DO i = 1, 3
      DO j = 1, 3
        IF (i /= j) THEN
          D_elastic(i, j) = lambda
        END IF
      END DO
    END DO

    ! Shear terms
    IF (ndim >= 3) THEN
      D_elastic(4, 4) = mu
      D_elastic(5, 5) = mu
      D_elastic(6, 6) = mu
    ELSE IF (ndim == 2) THEN
      D_elastic(4, 4) = mu
    END IF

  END SUBROUTINE chab_build_elastic_stiffness

  !=============================================================================
  ! Helper: Compute Trial Stress
  !=============================================================================

  SUBROUTINE chab_compute_trial_stress(stress_old, dstran, D_elastic, &
                                    ndir, nshr, ntens, stress_trial)
    !! Compute trial stress

    REAL(wp), INTENT(IN) :: stress_old(6)
    REAL(wp), INTENT(IN) :: dstran(6)
    REAL(wp), INTENT(IN) :: D_elastic(6,6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens
    REAL(wp), INTENT(OUT) :: stress_trial(6)

    INTEGER(i4) :: i, j

    stress_trial = stress_old
    DO i = 1, ntens
      DO j = 1, ntens
        stress_trial(i) = stress_trial(i) + D_elastic(i,j) * dstran(j)
      END DO
    END DO

  END SUBROUTINE chab_compute_trial_stress

  !=============================================================================
  ! Helper: Normalize Vector
  !=============================================================================

  SUBROUTINE chab_normalize_vector(vec, n)
    !! Normalize a vector

    REAL(wp), INTENT(INOUT) :: vec(:)
    INTEGER(i4), INTENT(IN) :: n

    REAL(wp) :: norm

    norm = SQRT(DOT_PRODUCT(vec(1:n), vec(1:n)))
    IF (norm > ph_chab_reg) THEN
      vec(1:n) = vec(1:n) / norm
    ELSE
      vec(1:n) = ZERO
    END IF

  END SUBROUTINE chab_normalize_vector

  !=============================================================================
  ! Compute Stress (High-level interface)
  !=============================================================================

  SUBROUTINE UF_Chaboche_ComputeStress(Mat, stress, statev, dstran, &
                                        dtime, ndir, nshr, nstatev, status)
    !! Compute stress using Chaboche model (high-level interface)

    TYPE(ChabMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(IN) :: dstran(6)
    REAL(wp), INTENT(IN) :: dtime
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp) :: ddsdde(6,6), sse, spd, scd, rpl
    REAL(wp) :: ddsddt(6), drplde(6), drpldt
    REAL(wp) :: stran(6) = ZERO
    REAL(wp) :: time(2) = ZERO
    REAL(wp) :: temp = 20.0_wp, dtemp = ZERO
    REAL(wp) :: props(CHAB_MAX_PROPS)
    INTEGER(i4) :: ndim = 3, kstep = 1, kinc = 1

    ! Pack properties
    props(CHAB_PROP_E) = Mat%PH_MAT_E
    props(CHAB_PROP_NU) = Mat%nu
    props(CHAB_PROP_SIGMA_Y0) = Mat%base%hardening%sigma_y0
    props(CHAB_PROP_H) = Mat%base%hardening%H
    props(CHAB_PROP_N_COMP) = REAL(Mat%n_components, wp)
    props(CHAB_PROP_C1) = Mat%C(1)
    props(CHAB_PROP_GAMMA1) = Mat%gamma(1)
    props(CHAB_PROP_C2) = Mat%C(2)
    props(CHAB_PROP_GAMMA2) = Mat%gamma(2)
    IF (Mat%n_components >= 3) THEN
      props(CHAB_PROP_C3) = Mat%C(3)
      props(CHAB_PROP_GAMMA3) = Mat%gamma(3)
    END IF

    CALL UF_Chaboche_UMAT(stress, statev, ddsdde, sse, spd, scd, rpl, &
                          ddsddt, drplde, drpldt, &
                          stran, dstran, time, dtime, temp, dtemp, &
                          [ZERO], [ZERO], ndir, nshr, nstatev, CHAB_MAX_PROPS, &
                          props, ndim, kstep, kinc, status)

  END SUBROUTINE UF_Chaboche_ComputeStress

  !=============================================================================
  ! Compute Tangent Stiffness
  !=============================================================================

  SUBROUTINE UF_Chaboche_ComputeTangent(Mat, stress, alpha_total, &
                                         sigma_y, D_elastic, ddsdde, &
                                         ndir, nshr, ntens, status)
    !! Compute consistent tangent stiffness matrix

    TYPE(ChabMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(IN) :: alpha_total(6)
    REAL(wp), INTENT(IN) :: sigma_y
    REAL(wp), INTENT(IN) :: D_elastic(6,6)
    REAL(wp), INTENT(OUT) :: ddsdde(6,6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! Simplified tangent stiffness (full implementation would compute consistent tangent)
    ddsdde(1:ntens,1:ntens) = D_elastic(1:ntens,1:ntens)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Chaboche_ComputeTangent

END MODULE PH_Mat_Plast_Chaboche_Core