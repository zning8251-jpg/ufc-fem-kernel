!===============================================================================
! MODULE: PH_Mat_Plast_Hill_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Hill anisotropic plasticity model for rolled metal sheets —
!         **W1**：Hill 参数自 **`desc%props`**；**PH_MAT_PLASTIC** / **Effective_Model** /
!         **PH_Mat_Dispatch** 与 **PH_MatPLMEval** 协同。
!===============================================================================
!!   Core objective: Anisotropic plasticity for rolled metal sheets
!!   Theoretical basis: Hill's anisotropic yield criterion (Hill48)
!!
!!   **Hill48 Yield Criterion**:
!!   - f = F(σ_yy-σ_zz)² + G(σ_zz-σ_xx)² + H(σ_xx-σ_yy)² + 2Lτ₂₃² + 2Mτ₃₁² + 2Nτ₁₂² - 1
!!   - F, G, H, L, M, N = Hill anisotropic parameters
!!
!!   **Anisotropic Parameter Calibration**:
!!   - R-values (Lankford coefficients): R₀, R₄₅, R₉₀
!!   - F = 1/(1+R₀), G = R₀/(1+R₀), H = R₀/(1+R₀)
!!   - N = (1 + 2R₄₅)(1 + R₀)/(2R₀(1 + R₄₅))
!!
!!   **Hill90 Criterion** (quadratic + quartic terms):
!!   - f = (a·|σσ₂|^m + b·|σσ₃|^m + c·|σσ₁|^m)^(1/m) - σ_y
!!
!!   **Typical Applications**:
!!   - Sheet metal stamping
!!   - Deep drawing forming
!!   - Rolled sheets
!!   - Anisotropic metals
!! @author UFC Development Team
!! @date 2026-02-05
!! @version 1.0
!! @see Hill, "A theory of the yielding and plastic flow of anisotropic metals" (1948)

!===============================================================================
! Module: PH_Mat_PLM_Hill
! Layer:  L4_PH - Physics Layer
! Domain: Mat - Material
! Purpose: Hill anisotropic plasticity for rolled metal sheets
! Theory:  Hill (1948), "A Theory of Yielding and Plastic Flow of Anisotropic Metals"
! Status:  CORE | Last verified: 2026-02-28
!
! Contents (A-Z):
!   Types:
!     - Hill_Params - Hill anisotropic parameters
!     - Hill_State  - State variables
!   Subroutines:
!     - Construct_Elastic_D                  - Elastic stiffness matrix
!     - PH_Mat_Hill_Calc_Stress              - Stress update algorithm
!     - PH_Mat_Hill_Compute_Anisotropic_Parameters - Compute F,G,H,L,M,N from R-values
!     - MD_Hill_Yield_Function               - Hill48 yield function
!     - PH_Hill_Plasticity_Eval              - UFC refactored interface
!   Functions:
!     - None
!===============================================================================

MODULE PH_Mat_Plast_Hill_Core
!> Status: STUB | Hill48 algorithm present, elastic tangent used for D_ep
!> Theory: Hill (1948) | Last verified: 2026-03-19
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, FOUR, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IEEE_ARITHMETIC, ONLY: IEEE_IS_FINITE
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Lib, ONLY: MD_PlasticMatDesc
  USE MD_Mat_Plast_Contract, ONLY: PlastMatBase, MD_MAT_PLASTIC_HILL
  USE MD_Mat_Plast_Hill, ONLY: MD_MAT_HILL_MAT_ID, MD_MAT_HILL_MAT_NAME, UF_Hill_ValidateProps, &
      MD_MAT_HILL_PROP_E, MD_MAT_HILL_PROP_NU, MD_MAT_HILL_PROP_H11, MD_MAT_HILL_PROP_H22, &
      MD_MAT_HILL_PROP_H33, MD_MAT_HILL_PROP_H12, MD_MAT_HILL_PROP_H23, MD_MAT_HILL_PROP_H13, &
      MD_MAT_HILL_PROP_H44, MD_MAT_HILL_PROP_SIGMA_Y0, MD_MAT_HILL_PROP_H55, MD_MAT_HILL_PROP_H66, &
      MD_MAT_HILL_PROP_H_HARDENIN, MD_MAT_HILL_PROP_N_HARDENIN
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context

  ! Legacy naming aliases (former module MD_MatPLMHill deleted)
  INTEGER(i4), PARAMETER :: HILL_MAT_ID = MD_MAT_HILL_MAT_ID
  INTEGER(i4), PARAMETER :: HILL_PROP_E = MD_MAT_HILL_PROP_E
  INTEGER(i4), PARAMETER :: HILL_PROP_NU = MD_MAT_HILL_PROP_NU
  INTEGER(i4), PARAMETER :: HILL_PROP_H11 = MD_MAT_HILL_PROP_H11
  INTEGER(i4), PARAMETER :: HILL_PROP_H22 = MD_MAT_HILL_PROP_H22
  INTEGER(i4), PARAMETER :: HILL_PROP_H33 = MD_MAT_HILL_PROP_H33
  INTEGER(i4), PARAMETER :: HILL_PROP_H12 = MD_MAT_HILL_PROP_H12
  INTEGER(i4), PARAMETER :: HILL_PROP_H23 = MD_MAT_HILL_PROP_H23
  INTEGER(i4), PARAMETER :: HILL_PROP_H13 = MD_MAT_HILL_PROP_H13
  INTEGER(i4), PARAMETER :: HILL_PROP_H44 = MD_MAT_HILL_PROP_H44
  INTEGER(i4), PARAMETER :: HILL_PROP_SIGMA_Y0 = MD_MAT_HILL_PROP_SIGMA_Y0
  INTEGER(i4), PARAMETER :: HILL_PROP_H55 = MD_MAT_HILL_PROP_H55
  INTEGER(i4), PARAMETER :: HILL_PROP_H66 = MD_MAT_HILL_PROP_H66
  INTEGER(i4), PARAMETER :: HILL_PROP_H_HARDENIN = MD_MAT_HILL_PROP_H_HARDENIN
  INTEGER(i4), PARAMETER :: HILL_PROP_N_HARDENIN = MD_MAT_HILL_PROP_N_HARDENIN
  INTEGER(i4), PARAMETER :: PLASTIC_HILL = MD_MAT_PLASTIC_HILL

  IMPLICIT NONE
  PRIVATE

  REAL(wp), PARAMETER :: HIL_REG = 1.0e-12_wp
  INTEGER(i4), PARAMETER :: PH_MAT_HIL_MAX_ITER = 20_i4
  REAL(wp), PARAMETER :: HIL_TOLER = 1.0e-6_wp

  TYPE :: HilMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    REAL(wp) :: H11 = 0.0_wp
    REAL(wp) :: H22 = 0.0_wp
    REAL(wp) :: H33 = 0.0_wp
    REAL(wp) :: H12 = 0.0_wp
    REAL(wp) :: H23 = 0.0_wp
    REAL(wp) :: H13 = 0.0_wp
    REAL(wp) :: H44 = 0.0_wp
    REAL(wp) :: H55 = 0.0_wp
    REAL(wp) :: H66 = 0.0_wp
    REAL(wp) :: sigma_y0 = 0.0_wp
    REAL(wp) :: H_hardening = 0.0_wp
    REAL(wp) :: n_hardening = 1.0_wp
    LOGICAL :: init = .FALSE.
  END TYPE HilMat

  TYPE, PUBLIC :: PH_Hill_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Hill_Cfg_Elastic

  TYPE, PUBLIC :: PH_Hill_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp  ! Reference direction yield stress
    INTEGER(i4) :: hill_model = 1_i4     ! 1=Hill48, 2=Hill90
  END TYPE PH_Hill_Cfg_Yield

  TYPE, PUBLIC :: PH_Hill_Cfg_RValue
    REAL(wp) :: R_0 = 0.0_wp
    REAL(wp) :: R_45 = 0.0_wp
    REAL(wp) :: R_90 = 0.0_wp            ! Lankford coefficient (0°, 45°, 90°)
  END TYPE PH_Hill_Cfg_RValue

  TYPE, PUBLIC :: PH_Hill_Cfg_HillParam
    REAL(wp) :: F = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: H = 0.0_wp
    REAL(wp) :: L = 0.0_wp
    REAL(wp) :: M = 0.0_wp
    REAL(wp) :: N = 0.0_wp               ! Hill48 anisotropic parameters
  END TYPE PH_Hill_Cfg_HillParam

  TYPE, PUBLIC :: PH_Hill_Cfg_Harden
    REAL(wp) :: hardening_modulus = 0.0_wp
    REAL(wp) :: hardening_exponent = 1.0_wp
  END TYPE PH_Hill_Cfg_Harden

  TYPE, PUBLIC :: Hill_Params
    TYPE(PH_Hill_Cfg_Elastic)    :: elastic
    TYPE(PH_Hill_Cfg_Yield)      :: yield
    TYPE(PH_Hill_Cfg_RValue)     :: rvalue
    TYPE(PH_Hill_Cfg_HillParam)  :: hill
    TYPE(PH_Hill_Cfg_Harden)     :: harden
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Hill_Params

  TYPE, PUBLIC :: Hill_State
    REAL(wp), ALLOCATABLE :: stress_current(:)
    REAL(wp), ALLOCATABLE :: strain_plastic(:)
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: yield_stress_current = 0.0_wp
    LOGICAL  :: is_plastic = .FALSE.
  END TYPE

  PUBLIC :: PH_Mat_Hill_Init, PH_Mat_Hill_Compute_Anisotropic_Parameters
  PUBLIC :: PH_Mat_Hill_Calc_Stress
  PUBLIC :: PH_Hill_Plasticity_Eval  ! UFC refactored interface
  PUBLIC :: PH_MAT_UMAT_HillPlasticity       ! PH_UMAT_Intf compatible wrapper (for registry)
  PUBLIC :: HillPlasticity_UpdateStress
  PUBLIC :: UF_Hill_UMAT

CONTAINS

  SUBROUTINE PH_Mat_Hill_Init(params, state)
    TYPE(Hill_Params), INTENT(INOUT) :: params
    TYPE(Hill_State), INTENT(INOUT) :: state
    
    CALL PH_Mat_Hill_Compute_Anisotropic_Parameters(params)
    
    ALLOCATE(state%stress_current(6), state%strain_plastic(6))
    state%stress_current = ZERO
    state%strain_plastic = ZERO
    state%equiv_plastic_strain = ZERO
    state%yield_stress_current = params%yield%yield_stress_0
    state%is_plastic = .FALSE.
  END SUBROUTINE PH_Mat_Hill_Init

  !> @brief Compute Hill48 anisotropic parameters from Lankford coefficients
  SUBROUTINE PH_Mat_Hill_Compute_Anisotropic_Parameters(params)
    TYPE(Hill_Params), INTENT(INOUT) :: params
    REAL(wp) :: R0, R45, R90, denom
    
    R0 = params%rvalue%R_0
    R45 = params%rvalue%R_45
    R90 = params%rvalue%R_90
    
    ! Hill48 parameters (assuming rolling direction as principal direction)
    params%hill%F = R0 / (R90 * (ONE + R0))
    params%hill%G = ONE / (ONE + R0)
    params%hill%H = R0 / (ONE + R0)
    
    ! Shear anisotropy parameter N
    denom = (ONE + R0) * (TWO * R45)
    IF (ABS(denom) > 1.0E-10_wp) THEN
      params%hill%N = (R0 * (ONE + R90)) / denom
    ELSE
      params%hill%N = 1.5_wp  ! Default value
    END IF
    
    params%hill%L = 1.5_wp  ! Simplified assumption (requires biaxial test calibration)
    params%hill%M = 1.5_wp
  END SUBROUTINE PH_Mat_Hill_Compute_Anisotropic_Parameters

  SUBROUTINE PH_Mat_Hill_Calc_Stress(params, state, strain_increment, sigma)
    TYPE(Hill_Params), INTENT(IN) :: params
    TYPE(Hill_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: strain_increment(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: yield_function
    
    CALL Construct_Elastic_D(params%elastic%E_modulus, params%elastic%nu_poisson, D_elastic)
    stress_trial = state%stress_current + MATMUL(D_elastic, strain_increment)
    
    ! Hill48 yield criterion
    yield_function = Eval_Hill48_Yield(params, state, stress_trial)
    
    IF (yield_function > ZERO) THEN
      state%is_plastic = .TRUE.
      CALL Return_Mapping_Hill48(params, state, stress_trial, sigma)
    ELSE
      state%is_plastic = .FALSE.
      sigma = stress_trial
    END IF
    
    state%stress_current = sigma
  END SUBROUTINE PH_Mat_Hill_Calc_Stress

  FUNCTION Eval_Hill48_Yield(params, state, sigma) RESULT(f)
    TYPE(Hill_Params), INTENT(IN) :: params
    TYPE(Hill_State), INTENT(IN) :: state
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp) :: f, term1, term2, term3, term4, term5, term6
    REAL(wp) :: sigma_y_eff
    
    ! Hill48 yield function
    term1 = params%hill%F * (sigma(2) - sigma(3))**2
    term2 = params%hill%G * (sigma(3) - sigma(1))**2
    term3 = params%hill%H * (sigma(1) - sigma(2))**2
    term4 = TWO * params%hill%L * sigma(4)**2  ! τ₂₃
    term5 = TWO * params%hill%M * sigma(5)**2  ! τ₃₁
    term6 = TWO * params%hill%N * sigma(6)**2  ! τ₁₂
    
    sigma_y_eff = term1 + term2 + term3 + term4 + term5 + term6
    
    ! Equivalent Hill stress
    sigma_y_eff = SQRT(sigma_y_eff)
    
    ! Yield function
    f = sigma_y_eff - state%yield_stress_current
  END FUNCTION

  SUBROUTINE Return_Mapping_Hill48(params, state, stress_trial, sigma)
    TYPE(Hill_Params), INTENT(IN) :: params
    TYPE(Hill_State), INTENT(INOUT) :: state
    REAL(wp), INTENT(IN) :: stress_trial(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: delta_lambda, G_modulus, K_modulus
    REAL(wp) :: df_dsigma(6), dg_dsigma(6)
    
    G_modulus = params%elastic%E_modulus / (TWO * (ONE + params%elastic%nu_poisson))
    K_modulus = params%elastic%E_modulus / (THREE * (ONE - TWO * params%elastic%nu_poisson))
    
    ! Compute yield function gradient (associated flow)
    CALL Calc_Hill48_Gradient(params, stress_trial, df_dsigma)
    dg_dsigma = df_dsigma
    
    ! Simplified: plastic multiplier computation (complete version requires Newton iteration)
    delta_lambda = 0.001_wp
    
    ! Update stress
    sigma = stress_trial - delta_lambda * MATMUL(Construct_Elastic_D_Mtx(params), dg_dsigma)
    
    ! Update internal variables
    state%equiv_plastic_strain = state%equiv_plastic_strain + delta_lambda
    state%yield_stress_current = params%yield%yield_stress_0 + params%harden%hardening_modulus * state%equiv_plastic_strain
  END SUBROUTINE

  SUBROUTINE Calc_Hill48_Gradient(params, sigma, df_dsigma)
    TYPE(Hill_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: sigma(6)
    REAL(wp), INTENT(OUT) :: df_dsigma(6)
    REAL(wp) :: sigma_y_eff
    
    sigma_y_eff = SQRT(Eval_Hill48_Yield(params, Hill_State(), sigma))
    
    ! ∂f/�??(simplified implementation)
    df_dsigma(1) = (TWO * params%hill%G * (sigma(3) - sigma(1)) + TWO * params%hill%H * (sigma(1) - sigma(2))) / sigma_y_eff
    df_dsigma(2) = (TWO * params%hill%F * (sigma(2) - sigma(3)) + TWO * params%hill%H * (sigma(1) - sigma(2))) / sigma_y_eff
    df_dsigma(3) = (TWO * params%hill%F * (sigma(2) - sigma(3)) + TWO * params%hill%G * (sigma(3) - sigma(1))) / sigma_y_eff
    df_dsigma(4) = (FOUR * params%hill%L * sigma(4)) / sigma_y_eff
    df_dsigma(5) = (FOUR * params%hill%M * sigma(5)) / sigma_y_eff
    df_dsigma(6) = (FOUR * params%hill%N * sigma(6)) / sigma_y_eff
  END SUBROUTINE

  FUNCTION Construct_Elastic_D_Mtx(params) RESULT(D)
    TYPE(Hill_Params), INTENT(IN) :: params
    REAL(wp) :: D(6,6)
    CALL Construct_Elastic_D(params%elastic%E_modulus, params%elastic%nu_poisson, D)
  END FUNCTION

  !============================================================================
  ! UFC REFACTORED INTERFACE ( ?Structured Parameter Pattern)
  !============================================================================

  !> @brief Hill anisotropic plasticity evaluation with UFC mat_desc pattern
  !! Refactored interface using MD_PlasticMatDesc instead of magic arrays
  !! Advantages: Type safety, semantic clarity, cross-layer stability
  SUBROUTINE PH_Hill_Plasticity_Eval(mat_desc, strain_increment, state, &
                                     stress_new, D_matrix, status)
    TYPE(MD_PlasticMatDesc), INTENT(IN) :: mat_desc  !  ?UFC structured parameter
    REAL(wp), INTENT(IN) :: strain_increment(6)
    TYPE(Hill_State), INTENT(INOUT) :: state  ! Explicit state variable
    REAL(wp), INTENT(OUT) :: stress_new(6)
    REAL(wp), INTENT(OUT), OPTIONAL :: D_matrix(6,6)
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    
    TYPE(Hill_Params) :: params
    REAL(wp) :: sigma(6)
    
    ! Initialize error status
    IF (PRESENT(status)) CALL init_error_status(status, IF_STATUS_OK)
    
    ! ========== Extract material properties from structure ==========
    params%elastic%E_modulus = mat_desc%PH_MAT_E
    params%elastic%nu_poisson = mat_desc%nu
    params%yield%yield_stress_0 = mat_desc%sy0
    params%harden%hardening_modulus = mat_desc%H
    params%harden%hardening_exponent = 0.0_wp  ! Not yet in mat_desc
    
    ! Hill anisotropic parameters from mat_desc
    params%hill%F = mat_desc%F
    params%hill%G = mat_desc%G_hill
    params%hill%H = mat_desc%H_hill
    params%hill%L = mat_desc%L
    params%hill%M = mat_desc%M
    params%hill%N = mat_desc%N_hill
    params%yield%hill_model = 1  ! Hill48
    
    ! Optional: Compute Hill parameters from R-values if provided
    ! params%rvalue%R_0 = ..., params%rvalue%R_45 = ..., params%rvalue%R_90 = ...
    ! CALL PH_Mat_Hill_Compute_Anisotropic_Parameters(params)
    
    ! ========== Call legacy core algorithm ==========
    CALL PH_Mat_Hill_Calc_Stress(params, state, strain_increment, sigma)
    stress_new = sigma
    
    ! ========== Compute consistent tangent if requested ==========
    IF (PRESENT(D_matrix)) THEN
      ! Elastic tangent as simplified version (full elastoplastic tangent TBD)
      CALL Construct_Elastic_D(params%elastic%E_modulus, params%elastic%nu_poisson, D_matrix)
    END IF
    
    ! ========== Validation ==========
    IF (PRESENT(status)) THEN
      IF (.NOT. ALL(IEEE_IS_FINITE(stress_new))) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = "PH_Hill_Plasticity_Eval: Non-finite stress detected"
      END IF
    END IF
  END SUBROUTINE PH_Hill_Plasticity_Eval

  !--------------------------------------------------------------------
  ! HillPlasticity_UpdateStress: Pure algorithm, MatPoint_In/Out
  !--------------------------------------------------------------------
  SUBROUTINE HillPlasticity_UpdateStress(in, out)
    TYPE(MatPoint_In), INTENT(IN) :: in
    TYPE(MatPoint_Out), INTENT(OUT) :: out
    TYPE(Hill_Params) :: p
    TYPE(Hill_State)  :: st
    REAL(wp) :: D(6,6), sig_new(6), strain_inc(6)
    INTEGER(i4) :: ntens, i, j

    CALL init_error_status(out%status)
    ntens = in%ntens
    IF (ntens <= 0) ntens = 6

    IF (.NOT. ALLOCATED(in%props) .OR. SIZE(in%props) < 3) THEN
      out%status%status_code = IF_STATUS_ERROR
      out%status%message = "HillPlasticity_UpdateStress: need at least 3 props"
      RETURN
    END IF

    p%elastic%E_modulus  = REAL(in%props(1), wp)
    p%elastic%nu_poisson = REAL(in%props(2), wp)
    p%yield%yield_stress_0   = REAL(in%props(3), wp)
    p%rvalue%R_0  = MERGE(REAL(in%props(4), wp), 1.0_wp, SIZE(in%props) >= 4)
    p%rvalue%R_45 = MERGE(REAL(in%props(5), wp), 1.0_wp, SIZE(in%props) >= 5)
    p%rvalue%R_90 = MERGE(REAL(in%props(6), wp), 1.0_wp, SIZE(in%props) >= 6)
    p%harden%hardening_modulus  = MERGE(REAL(in%props(7), wp), 0.0_wp, SIZE(in%props) >= 7)
    p%harden%hardening_exponent = 1.0_wp
    p%yield%hill_model = 1
    CALL PH_Mat_Hill_Init(p, st)

    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 7) THEN
      st%equiv_plastic_strain = REAL(in%statev(1), wp)
      st%strain_plastic(1:6)  = REAL(in%statev(2:7), wp)
    END IF
    st%stress_current(1:ntens) = REAL(in%sigma_old(1:ntens), wp)

    strain_inc(1:ntens) = REAL(in%strain_inc(1:ntens), wp)
    IF (ntens < 6) strain_inc(ntens+1:6) = ZERO

    CALL PH_Mat_Hill_Calc_Stress(p, st, strain_inc, sig_new)

    out%sigma(1:ntens) = REAL(sig_new(1:ntens), wp)
    CALL Construct_Elastic_D(p%elastic%E_modulus, p%elastic%nu_poisson, D)
    DO j = 1, ntens
      DO i = 1, ntens
        out%ddsdde(i, j) = REAL(D(i, j), wp)
      END DO
    END DO
    out%pnewdt = 1.0_wp
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 7) THEN
      IF (.NOT. ALLOCATED(out%statev)) ALLOCATE(out%statev(SIZE(in%statev)))
      out%statev(1)   = REAL(st%equiv_plastic_strain, wp)
      out%statev(2:7) = REAL(st%strain_plastic(1:6), wp)
    END IF
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE HillPlasticity_UpdateStress

  !--------------------------------------------------------------------
  ! UF_Hill_* : props-array UMAT path (migrated from legacy L3 plastic registry)
  !--------------------------------------------------------------------

  SUBROUTINE UF_Hill_Init(Mat, props, nprops, status)
    TYPE(HilMat), INTENT(OUT) :: Mat
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL UF_Hill_ValidateProps(props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    Mat%PH_MAT_E = props(HILL_PROP_E)
    Mat%nu = props(HILL_PROP_NU)
    Mat%H11 = props(HILL_PROP_H11)
    Mat%H22 = props(HILL_PROP_H22)
    Mat%H33 = props(HILL_PROP_H33)
    Mat%H12 = props(HILL_PROP_H12)
    Mat%H23 = props(HILL_PROP_H23)
    Mat%H13 = props(HILL_PROP_H13)
    Mat%H44 = props(HILL_PROP_H44)
    Mat%sigma_y0 = props(HILL_PROP_SIGMA_Y0)

    IF (nprops >= HILL_PROP_H55) THEN
      Mat%H55 = props(HILL_PROP_H55)
    ELSE
      Mat%H55 = Mat%H44
    END IF

    IF (nprops >= HILL_PROP_H66) THEN
      Mat%H66 = props(HILL_PROP_H66)
    ELSE
      Mat%H66 = Mat%H44
    END IF

    IF (nprops >= HILL_PROP_H_HARDENIN) THEN
      Mat%H_hardening = props(HILL_PROP_H_HARDENIN)
    ELSE
      Mat%H_hardening = Mat%PH_MAT_E / 100.0_wp
    END IF

    IF (nprops >= HILL_PROP_N_HARDENIN) THEN
      Mat%n_hardening = props(HILL_PROP_N_HARDENIN)
    ELSE
      Mat%n_hardening = ONE
    END IF

    Mat%G = Mat%PH_MAT_E / (TWO * (ONE + Mat%nu))
    Mat%K = Mat%PH_MAT_E / (THREE * (ONE - TWO * Mat%nu))

    Mat%base%material_id = HILL_MAT_ID
    Mat%base%name = MD_MAT_HILL_MAT_NAME
    Mat%base%yield_criterion = PLASTIC_HILL
    Mat%base%hardening%hardening_type = 1
    Mat%base%hardening%sigma_y0 = Mat%sigma_y0
    Mat%base%hardening%H = Mat%H_hardening
    Mat%base%flow_rule%flow_type = 1

    Mat%init = .TRUE.

  END SUBROUTINE UF_Hill_Init

  SUBROUTINE UF_Hill_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
      rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, &
      predef, dpred, ndir, nshr, nstatev, nprops, &
      props, ndim, kstep, kinc, status)
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(OUT) :: ddsdde(6, 6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(HilMat) :: Mat
    REAL(wp) :: stress_out(6)
    REAL(wp) :: ddsdde_out(6, 6)

    CALL init_error_status(status)

    CALL UF_Hill_Init(Mat, props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL UF_Hill_ComputeStress(Mat, stress, statev, dstran, &
        ndir, nshr, nstatev, stress_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    CALL UF_Hill_ComputeTangent(Mat, stress_out, statev, &
        ndir, nshr, nstatev, ddsdde_out, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    stress(1:ndir + nshr) = stress_out(1:ndir + nshr)
    ddsdde(1:ndir + nshr, 1:ndir + nshr) = ddsdde_out(1:ndir + nshr, 1:ndir + nshr)

    sse = 0.5_wp * DOT_PRODUCT(stress_out(1:ndir + nshr), &
        stran(1:ndir + nshr) + dstran(1:ndir + nshr))
    spd = 0.0_wp
    scd = 0.0_wp
    rpl = 0.0_wp
    ddsddt = 0.0_wp
    drplde = 0.0_wp
    drpldt = 0.0_wp

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Hill_UMAT

  SUBROUTINE UF_Hill_ComputeStress(Mat, stress_old, statev, dstran, &
      ndir, nshr, nstatev, stress_new, status)
    TYPE(HilMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: stress_old(6)
    REAL(wp), INTENT(INOUT) :: statev(:)
    REAL(wp), INTENT(IN) :: dstran(6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev
    REAL(wp), INTENT(OUT) :: stress_new(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ntens, i, iter
    REAL(wp) :: strain_plastic(6)
    REAL(wp) :: plastic_strain
    REAL(wp) :: stress_trial(6)
    REAL(wp) :: s_dev(3, 3), p_mean
    REAL(wp) :: sigma_eq_trial, sigma_eq
    REAL(wp) :: sigma_y_old, sigma_y
    REAL(wp) :: PH_MAT_F_
    REAL(wp) :: dlambda, dlambda_trial
    REAL(wp) :: hardening_modul
    REAL(wp) :: n_flow(6)
    REAL(wp) :: D_elastic(6, 6)
    REAL(wp) :: strain_elastic(6)
    REAL(wp) :: residual

    CALL init_error_status(status)

    ntens = ndir + nshr

    strain_plastic(1:ntens) = 0.0_wp
    DO i = 1, MIN(ntens, nstatev)
      strain_plastic(i) = statev(i)
    END DO

    plastic_strain = 0.0_wp
    IF (ntens + 1 <= nstatev) THEN
      plastic_strain = statev(ntens + 1)
    END IF

    sigma_y_old = Mat%sigma_y0 + &
        Mat%H_hardening * plastic_strain**Mat%n_hardening

    CALL hil_BuildElasticStiffness(Mat%PH_MAT_E, Mat%nu, D_elastic, ndir, nshr, ntens)

    DO i = 1, ntens
      strain_elastic(i) = dstran(i) - strain_plastic(i)
    END DO

    CALL hil_MatComp_Stress(D_elastic, strain_elastic, stress_trial, ndir, nshr, ntens)

    DO i = 1, ntens
      stress_trial(i) = stress_old(i) + stress_trial(i)
    END DO

    CALL hil_ComputeDeviatoricStress(stress_trial, s_dev, p_mean, ndir, nshr, ntens)

    CALL hil_ComputeHillEquivalentStress(s_dev, p_mean, &
        Mat%H11, Mat%H22, Mat%H33, &
        Mat%H12, Mat%H23, Mat%H13, &
        Mat%H44, Mat%H55, Mat%H66, &
        sigma_eq_trial, ndir, nshr, ntens)

    PH_MAT_F_ = sigma_eq_trial - sigma_y_old

    IF (PH_MAT_F_ <= ZERO) THEN
      stress_new(1:ntens) = stress_trial(1:ntens)
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    hardening_modul = Mat%H_hardening * Mat%n_hardening * &
        plastic_strain**MAX(Mat%n_hardening - ONE, ZERO)
    dlambda_trial = PH_MAT_F_ / (THREE * Mat%G + hardening_modul)
    dlambda = dlambda_trial
    plastic_strain = plastic_strain + dlambda

    DO iter = 1, PH_MAT_HIL_MAX_ITER
      sigma_y = Mat%sigma_y0 + &
          Mat%H_hardening * plastic_strain**Mat%n_hardening

      CALL hil_ComputeHillEquivalentStress(s_dev, p_mean, &
          Mat%H11, Mat%H22, Mat%H33, &
          Mat%H12, Mat%H23, Mat%H13, &
          Mat%H44, Mat%H55, Mat%H66, &
          sigma_eq, ndir, nshr, ntens)

      PH_MAT_F_ = sigma_eq - sigma_y
      residual = PH_MAT_F_

      IF (ABS(residual) < HIL_TOLER) EXIT

      hardening_modul = Mat%H_hardening * Mat%n_hardening * &
          plastic_strain**MAX(Mat%n_hardening - ONE, ZERO)

      dlambda = dlambda - residual / (THREE * Mat%G + hardening_modul)
      dlambda = MAX(dlambda, ZERO)

      plastic_strain = plastic_strain + dlambda
    END DO

    CALL hil_ComputeFlowDirection(s_dev, p_mean, &
        Mat%H11, Mat%H22, Mat%H33, &
        Mat%H12, Mat%H23, Mat%H13, &
        Mat%H44, Mat%H55, Mat%H66, &
        n_flow, ndir, nshr, ntens)

    DO i = 1, ntens
      stress_new(i) = stress_trial(i) - TWO * Mat%G * dlambda * n_flow(i)
    END DO

    DO i = 1, MIN(ntens, nstatev)
      statev(i) = strain_plastic(i) + dlambda * n_flow(i)
    END DO

    IF (ntens + 1 <= nstatev) THEN
      statev(ntens + 1) = plastic_strain
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Hill_ComputeStress

  SUBROUTINE UF_Hill_ComputeTangent(Mat, stress, statev, &
      ndir, nshr, nstatev, ddsdde, status)
    TYPE(HilMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(IN) :: statev(:)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev
    REAL(wp), INTENT(OUT) :: ddsdde(6, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: ntens
    REAL(wp) :: D_elastic(6, 6)
    REAL(wp) :: s_dev(3, 3), p_mean
    REAL(wp) :: n_flow(6)
    REAL(wp) :: plastic_strain
    REAL(wp) :: hardening_modul

    CALL init_error_status(status)

    ntens = ndir + nshr

    CALL hil_BuildElasticStiffness(Mat%PH_MAT_E, Mat%nu, D_elastic, ndir, nshr, ntens)

    plastic_strain = 0.0_wp
    IF (ntens + 1 <= nstatev) THEN
      plastic_strain = statev(ntens + 1)
    END IF

    hardening_modul = Mat%H_hardening * Mat%n_hardening * &
        plastic_strain**MAX(Mat%n_hardening - ONE, ZERO)

    CALL hil_ComputeDeviatoricStress(stress, s_dev, p_mean, ndir, nshr, ntens)

    CALL hil_ComputeFlowDirection(s_dev, p_mean, &
        Mat%H11, Mat%H22, Mat%H33, &
        Mat%H12, Mat%H23, Mat%H13, &
        Mat%H44, Mat%H55, Mat%H66, &
        n_flow, ndir, nshr, ntens)

    CALL hil_ComputeElastoplasticStiff(D_elastic, n_flow, hardening_modul, &
        0.0_wp, ddsdde, ndir, nshr, ntens)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE UF_Hill_ComputeTangent

  SUBROUTINE hil_BuildElasticStiffness(PH_MAT_E, nu, D, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: PH_MAT_E, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    REAL(wp) :: lambda, mu
    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))

    D = ZERO

    IF (ndir >= 1) THEN
      D(1, 1) = lambda + TWO * mu
      IF (ndir >= 2) THEN
        D(1, 2) = lambda
        D(2, 1) = lambda
        D(2, 2) = lambda + TWO * mu
        IF (ndir >= 3) THEN
          D(1, 3) = lambda
          D(2, 3) = lambda
          D(3, 1) = lambda
          D(3, 2) = lambda
          D(3, 3) = lambda + TWO * mu
        END IF
      END IF
    END IF

    IF (nshr >= 1) D(4, 4) = mu
    IF (nshr >= 2) D(5, 5) = mu
    IF (nshr >= 3) D(6, 6) = mu

  END SUBROUTINE hil_BuildElasticStiffness

  SUBROUTINE hil_MatComp_Stress(D, strain, stress, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: D(6, 6), strain(6)
    REAL(wp), INTENT(OUT) :: stress(6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    INTEGER(i4) :: i, j

    DO i = 1, ntens
      stress(i) = ZERO
      DO j = 1, ntens
        stress(i) = stress(i) + D(i, j) * strain(j)
      END DO
    END DO

  END SUBROUTINE hil_MatComp_Stress

  SUBROUTINE hil_ComputeDeviatoricStress(stress, s_dev, p_mean, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: stress(6)
    REAL(wp), INTENT(OUT) :: s_dev(3, 3), p_mean
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    p_mean = ZERO
    IF (ndir >= 1) p_mean = p_mean + stress(1)
    IF (ndir >= 2) p_mean = p_mean + stress(2)
    IF (ndir >= 3) p_mean = p_mean + stress(3)
    p_mean = p_mean / THREE

    s_dev = ZERO

    IF (ndir >= 1) s_dev(1, 1) = stress(1) - p_mean
    IF (ndir >= 2) s_dev(2, 2) = stress(2) - p_mean
    IF (ndir >= 3) s_dev(3, 3) = stress(3) - p_mean

    IF (nshr >= 1) THEN
      s_dev(1, 2) = stress(4)
      s_dev(2, 1) = stress(4)
    END IF
    IF (nshr >= 2) THEN
      s_dev(1, 3) = stress(5)
      s_dev(3, 1) = stress(5)
    END IF
    IF (nshr >= 3) THEN
      s_dev(2, 3) = stress(6)
      s_dev(3, 2) = stress(6)
    END IF

  END SUBROUTINE hil_ComputeDeviatoricStress

  SUBROUTINE hil_ComputeHillEquivalentStress(s_dev, p_mean, H11, H22, H33, &
      H12, H23, H13, H44, H55, H66, &
      sigma_eq, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: s_dev(3, 3), p_mean
    REAL(wp), INTENT(IN) :: H11, H22, H33, H12, H23, H13, H44, H55, H66
    REAL(wp), INTENT(OUT) :: sigma_eq
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    REAL(wp) :: s11, s22, s33, s12, s23, s13
    REAL(wp) :: term1, term2, term3

    s11 = s_dev(1, 1)
    s22 = s_dev(2, 2)
    s33 = s_dev(3, 3)
    s12 = s_dev(1, 2)
    s23 = s_dev(2, 3)
    s13 = s_dev(1, 3)

    term1 = H11 * s11**2 + H22 * s22**2 + H33 * s33**2
    term2 = TWO * (H12 * s11 * s22 + H23 * s22 * s33 + H13 * s11 * s33)
    term3 = TWO * (H44 * s12**2 + H55 * s23**2 + H66 * s13**2)

    sigma_eq = SQRT(term1 + term2 + term3)
    sigma_eq = MAX(sigma_eq, HIL_REG)

  END SUBROUTINE hil_ComputeHillEquivalentStress

  SUBROUTINE hil_ComputeFlowDirection(s_dev, p_mean, H11, H22, H33, &
      H12, H23, H13, H44, H55, H66, &
      n_flow, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: s_dev(3, 3), p_mean
    REAL(wp), INTENT(IN) :: H11, H22, H33, H12, H23, H13, H44, H55, H66
    REAL(wp), INTENT(OUT) :: n_flow(6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    REAL(wp) :: s11, s22, s33, s12, s23, s13
    REAL(wp) :: ds11, ds22, ds33, ds12, ds23, ds13
    REAL(wp) :: sigma_eq
    REAL(wp) :: norm

    s11 = s_dev(1, 1)
    s22 = s_dev(2, 2)
    s33 = s_dev(3, 3)
    s12 = s_dev(1, 2)
    s23 = s_dev(2, 3)
    s13 = s_dev(1, 3)

    ds11 = TWO * (H11 * s11 + H12 * s22 + H13 * s33)
    ds22 = TWO * (H12 * s11 + H22 * s22 + H23 * s33)
    ds33 = TWO * (H13 * s11 + H23 * s22 + H33 * s33)
    ds12 = TWO * H44 * s12
    ds23 = TWO * H55 * s23
    ds13 = TWO * H66 * s13

    CALL hil_ComputeHillEquivalentStress(s_dev, p_mean, H11, H22, H33, &
        H12, H23, H13, H44, H55, H66, &
        sigma_eq, ndir, nshr, ntens)

    norm = SQRT(ds11**2 + ds22**2 + ds33**2 + TWO * (ds12**2 + ds23**2 + ds13**2))
    norm = MAX(norm, HIL_REG)

    n_flow = ZERO
    IF (ndir >= 1) n_flow(1) = ds11 / norm
    IF (ndir >= 2) n_flow(2) = ds22 / norm
    IF (ndir >= 3) n_flow(3) = ds33 / norm
    IF (nshr >= 1) n_flow(4) = ds12 / norm
    IF (nshr >= 2) n_flow(5) = ds23 / norm
    IF (nshr >= 3) n_flow(6) = ds13 / norm

  END SUBROUTINE hil_ComputeFlowDirection

  SUBROUTINE hil_ComputeElastoplasticStiff(D_elastic, n_flow, hardening_modul, &
      dlambda, D_ep, ndir, nshr, ntens)
    REAL(wp), INTENT(IN) :: D_elastic(6, 6), n_flow(6)
    REAL(wp), INTENT(IN) :: hardening_modul, dlambda
    REAL(wp), INTENT(OUT) :: D_ep(6, 6)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, ntens

    REAL(wp) :: D_n(6), n_D(6), n_D_n
    INTEGER(i4) :: i, j

    DO i = 1, ntens
      D_n(i) = ZERO
      DO j = 1, ntens
        D_n(i) = D_n(i) + D_elastic(i, j) * n_flow(j)
      END DO
    END DO

    DO i = 1, ntens
      n_D(i) = ZERO
      DO j = 1, ntens
        n_D(i) = n_D(i) + n_flow(j) * D_elastic(j, i)
      END DO
    END DO

    n_D_n = ZERO
    DO i = 1, ntens
      n_D_n = n_D_n + n_flow(i) * D_n(i)
    END DO

    DO i = 1, ntens
      DO j = 1, ntens
        D_ep(i, j) = D_elastic(i, j) - D_n(i) * n_D(j) / (n_D_n + hardening_modul)
      END DO
    END DO

  END SUBROUTINE hil_ComputeElastoplasticStiff

  !--------------------------------------------------------------------
  ! PH_MAT_UMAT_HillPlasticity: Thin wrapper for registry
  !--------------------------------------------------------------------
  SUBROUTINE PH_MAT_UMAT_HillPlasticity(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(MatPoint_In) :: in
    TYPE(MatPoint_Out) :: out
    CALL Unpack_From_UMAT_Context(ctx, in)
    CALL HillPlasticity_UpdateStress(in, out)
    IF (out%status%status_code == IF_STATUS_OK) CALL Pack_To_UMAT_Context(out, ctx)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE PH_MAT_UMAT_HillPlasticity

END MODULE PH_Mat_Plast_Hill_Core