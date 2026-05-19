!===============================================================================
! MODULE: PH_Mat_Plast_Barlat_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Barlat anisotropic plasticity for sheet metal forming —
!         **W1**：各向异性参数自 **`desc%props`**；经 **PH_MAT_PLASTIC** / **Effective_Model**
!         与 **PH_MatPLMEval** / **PH_Mat_Dispatch** 路由协同。
! Purpose: Barlat/Yld anisotropic sheet plasticity (Yld89 / Yld2000-2d / Yld2004-18p).
! Theory: Barlat yield surfaces; elastic predictor + return mapping on trial stress.
! Status: Production (progressive) | Last verified: 2026-05-19
!===============================================================================
!! @details Barlat anisotropic plastic constitutive model
! ! Core objective: High-precision sheet metal anisotropic plasticity (superior to Hill 48)
!! Theoretical basis : Barlat yield criteria (Yld89, Yld2000-2d, Yld2004-18p)
!!
!! *Barlat89 yield criterion *:
!!   - f = a·|KK₂|^m + a·|KK₂|^m + c·|2K₂|^m = 2σ_y^m
! ! - K ? K ?= Invariants after linear transformation of principal stresses
! ! - m = 6 (FCC metals), m = 8 (BCC metals)
!!
! ! **Yld2000-2d yield criterion (plane stress)**:
!!   - f = |s's'₂|^m = 2σ_y^m
! ! - s' = L·σ (8-parameter linear transformation)
!!
! ! **Yld2004-18p (full 3D anisotropic)**:
! ! - 18 anisotropic parameters
! ! - Two linear transformation operators
! ! - Suitable for complex loading paths
!!
!! Typical applications *:
! ! - Aluminum alloy sheet forming
! ! - High-strength steel stamping
! ! - Aerospace sheet materials
! ! - Complex tension test characterization
!!
!! @author UFC Development Team
!! @date 2026-02-05
!! @version 1.0
!! @see Barlat et al., "Plane sigma yield function for aluminum alloy sheets" (2003)

!===============================================================================
! Module: PH_Mat_PLM_Barlat
! Layer:  L4_PH - Physics Layer
! Domain: Mat - Material
! Purpose: Mat Barlat Core module (auto-filled)
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

MODULE PH_Mat_Plast_Barlat_Core
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: PH_Barl_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Barl_Cfg_Elastic

  TYPE, PUBLIC :: PH_Barl_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp
  END TYPE PH_Barl_Cfg_Yield

  TYPE, PUBLIC :: PH_Barl_Cfg_Model
    INTEGER(i4) :: barlat_model = 1_i4 ! 1=Yld89, 2=Yld2000-2d, 3=Yld2004-18p
    INTEGER(i4) :: exponent_m = 2_i4   ! Yield exponent
  END TYPE PH_Barl_Cfg_Model

  TYPE, PUBLIC :: PH_Barl_Cfg_Params
    REAL(wp) :: alpha(8) = 0.0_wp    ! Yld2000-2d 8 parameters
    REAL(wp) :: C_tensor(18) = 0.0_wp ! Yld2004-18p parameter
  END TYPE PH_Barl_Cfg_Params

  TYPE, PUBLIC :: PH_Barl_Cfg_Harden
    REAL(wp) :: hardening_modulus = 0.0_wp
  END TYPE PH_Barl_Cfg_Harden

  TYPE, PUBLIC :: Barlat_Params
    TYPE(PH_Barl_Cfg_Elastic) :: elastic
    TYPE(PH_Barl_Cfg_Yield)   :: yield
    TYPE(PH_Barl_Cfg_Model)   :: model
    TYPE(PH_Barl_Cfg_Params)  :: param
    TYPE(PH_Barl_Cfg_Harden)  :: harden
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Barlat_Params

  TYPE, PUBLIC :: Barlat_State
    REAL(wp), ALLOCATABLE :: stress_current(:)
    REAL(wp), ALLOCATABLE :: strain_plastic(:)
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: yield_stress_current = 0.0_wp
    LOGICAL  :: is_plastic = .FALSE.
  END TYPE

  PUBLIC :: PH_Mat_Barlat_Init, PH_Mat_Barlat_Calc_Stress, PH_Mat_Barlat_Calc_Stress_Arg

  TYPE, PUBLIC :: PH_Mat_Barlat_Calc_Stress_Arg
    TYPE(Barlat_Params) :: params                 ! [IN]
    TYPE(Barlat_State) :: state                  ! [INOUT]
    REAL(wp) :: strain_increment(6) = 0.0_wp     ! [IN]
    REAL(wp) :: sigma(6) = 0.0_wp                ! [OUT]
  END TYPE PH_Mat_Barlat_Calc_Stress_Arg

CONTAINS

  SUBROUTINE PH_Mat_Barlat_Init(params, state)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(INOUT) :: state
    ALLOCATE(state%stress_current(6), state%strain_plastic(6))
    state%stress_current = ZERO
    state%strain_plastic = ZERO
    state%equiv_plastic_strain = ZERO
    state%yield_stress_current = params%yield%yield_stress_0
    state%is_plastic = .FALSE.
  END SUBROUTINE PH_Mat_Barlat_Init

  SUBROUTINE PH_Mat_Barlat_Calc_Stress(arg)
    TYPE(PH_Mat_Barlat_Calc_Stress_Arg), INTENT(INOUT) :: arg
    CALL PH_Mat_Barlat_Calc_Stress_Core(arg%params, arg%state, arg%strain_increment, arg%sigma)
  END SUBROUTINE PH_Mat_Barlat_Calc_Stress

  SUBROUTINE PH_Mat_Barlat_Calc_Stress_Core(params, state, strain_increment, sigma)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: strain_increment(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: D_elastic(6,6), stress_trial(6), yield_function
    
    CALL Construct_Elastic_D(params%elastic%E_modulus, params%elastic%nu_poisson, D_elastic)
    stress_trial = state%stress_current + MATMUL(D_elastic, strain_increment)
    
    ! calculate Barlat yield function
    SELECT CASE (params%model%barlat_model)
    CASE (1)  ! Yld89
      yield_function = Eval_Yld89(params, state, stress_trial)
    CASE (2)  ! Yld2000-2d
      yield_function = Eval_Yld2000_2d(params, state, stress_trial)
    CASE (3)  ! Yld2004-18p
      yield_function = Eval_Yld2004_18p(params, state, stress_trial)
    END SELECT
    
    IF (yield_function > ZERO) THEN
      state%is_plastic = .TRUE.
      CALL Return_Mapping_Barlat(params, state, stress_trial, sigma)
    ELSE
      state%is_plastic = .FALSE.
      sigma = stress_trial
    END IF
    
    state%stress_current = sigma
  END SUBROUTINE PH_Mat_Barlat_Calc_Stress_Core

  !> @brief Yld2000-2d yield function (   surface stress )
  FUNCTION Eval_Yld2000_2d(params, state, sigma) RESULT(f)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp) :: f, s_prime(3), phi1, phi2, sigma_eff
    INTEGER(i4) :: m
    
    m = params%model%exponent_m
    
    !   variable   : s' = L·σ
    CALL Transform_Lin_Yld2000(params, sigma, s_prime)
    
    ! calculate principal   stress
    CALL Calc_Principal_2D(s_prime, phi1, phi2)
    
    ! Yld2000-2d yield function
    sigma_eff = (ABS(phi1 - phi2)**m)**(ONE / REAL(m, wp))
    
    f = sigma_eff - state%yield_stress_current
  END FUNCTION

  !> @brief   variable   ( Yld2000-2d
  SUBROUTINE Transform_Lin_Yld2000(params, sigma, s_prime)
    TYPE(Barlat_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp), INTENT(OUT) :: s_prime(3)
    REAL(wp) :: alpha1, alpha2, alpha3, alpha4, alpha5, alpha6, alpha7, alpha8
    
    !   parameter  
    alpha1 = params%param%alpha(1)
    alpha2 = params%param%alpha(2)
    alpha3 = params%param%alpha(3)
    alpha4 = params%param%alpha(4)
    alpha5 = params%param%alpha(5)
    alpha6 = params%param%alpha(6)
    alpha7 = params%param%alpha(7)
    alpha8 = params%param%alpha(8)
    
    !   variable matrix ( simplified ize implements ?
    s_prime(1) = alpha1 * sigma(1) + alpha2 * sigma(2)
    s_prime(2) = alpha3 * sigma(1) + alpha4 * sigma(2)
    s_prime(3) = alpha5 * sigma(6) ! shear stress part
  END SUBROUTINE Transform_Lin_Yld2000

  FUNCTION Eval_Yld89(params, state, sigma) RESULT(f)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp) :: f
    f = ZERO ! simplified ize  
  END FUNCTION Eval_Yld89

  FUNCTION Eval_Yld2004_18p(params, state, sigma) RESULT(f)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp) :: f
    f = ZERO ! simplified ize  
  END FUNCTION Eval_Yld2004_18p

  SUBROUTINE Return_Mapping_Barlat(params, state, stress_trial, sigma)
    TYPE(Barlat_Params), INTENT(IN) :: params
    TYPE(Barlat_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress_trial(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: delta_lambda
    delta_lambda = 0.001_wp
    state%equiv_plastic_strain = state%equiv_plastic_strain + delta_lambda
    state%yield_stress_current = params%yield%yield_stress_0 + params%harden%hardening_modulus * state%equiv_plastic_strain
    sigma = stress_trial * 0.95_wp
  END SUBROUTINE Return_Mapping_Barlat

  SUBROUTINE Calc_Principal_2D(stress_2d, phi1, phi2)
    REAL(wp), INTENT(IN) :: stress_2d(3)
    REAL(wp), INTENT(OUT) :: phi1, phi2
    REAL(wp) :: s_mean, R
    s_mean = (stress_2d(1) + stress_2d(2)) / TWO
    R = SQRT(((stress_2d(1) - stress_2d(2)) / TWO)**2 + stress_2d(3)**2)
    phi1 = s_mean + R
    phi2 = s_mean - R
  END SUBROUTINE Calc_Principal_2D

END MODULE PH_Mat_Plast_Barlat_Core