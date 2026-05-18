!===============================================================================
! MODULE: PH_Mat_Comp_Cast_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Cast iron Rankine-type plasticity UMAT (legacy L3 migration) —
!         **W1**：UMAT **props** 与 Populate **`desc%props`** / **`PH_UMAT_Context`** 对齐；
!         族路由经 **PH_Mat_Dispatch** / **Effective_Model**（铸铁/复合塑性子路径）。
!===============================================================================
MODULE PH_Mat_Comp_Cast_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, log_error
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context, PH_UMAT_Intf
  USE MD_Mat_Plast_Contract, ONLY: PlastMatBase

  ! Legacy stub definitions (modules MD_MatPLMCastIron / MD_MatPLM_TDep deleted)
  INTEGER(i4), PARAMETER :: PH_MAT_CAST_IRON_MAT_I = 223_i4
  CHARACTER(LEN=*), PARAMETER :: CAST_IRON_MAT_N = "Cast Iron Plasticity"
  TYPE :: TDepPlasticProps
    LOGICAL :: enabled = .FALSE.
    REAL(wp) :: T_ref = 0.0_wp
    REAL(wp) :: dE_dT = 0.0_wp
    REAL(wp) :: dNu_dT = 0.0_wp
    REAL(wp) :: dsigmaY_dT = 0.0_wp
  END TYPE TDepPlasticProps

  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_E = 1_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_NU = 2_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_SIGMA_T0 = 3_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_SIGMA_C0 = 4_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_H_T = 5_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_H_C = 6_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_DAMAGE_T = 7_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_PROP_DAMAGE_C = 8_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_MIN_PROPS = 6_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_STATEV_EPS_P_T = 1_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_STATEV_EPS_P_C = 2_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_YIELD_TENSION = 1_i4
  INTEGER(i4), PARAMETER :: PH_MAT_CI_YIELD_COMPRESSI = 2_i4
  REAL(wp), PARAMETER :: PH_MAT_CI_ZERO = 0.0_wp
  REAL(wp), PARAMETER :: PH_MAT_CI_ONE = 1.0_wp
  REAL(wp), PARAMETER :: PH_MAT_CI_TWO = 2.0_wp
  REAL(wp), PARAMETER :: PH_MAT_CI_THREE = 3.0_wp
  REAL(wp), PARAMETER :: PH_MAT_CI_TOL = 1.0e-10_wp
  INTEGER(i4), PARAMETER :: PH_MAT_CI_MAX_ITER = 50_i4

  TYPE :: CastIronMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: sigma_t0 = 0.0_wp
    REAL(wp) :: sigma_c0 = 0.0_wp
    REAL(wp) :: H_t = 0.0_wp
    REAL(wp) :: H_c = 0.0_wp
    REAL(wp) :: damage_t_param = 0.0_wp
    REAL(wp) :: damage_c_param = 0.0_wp
    TYPE(TDepPlasticProps) :: temp_props
    LOGICAL :: temp_dependent = .FALSE.
    LOGICAL :: init = .FALSE.
  END TYPE CastIronMat

  PUBLIC :: PH_Mat_PLM_CastIronic_Update
  PUBLIC :: PH_MAT_UMAT_CastIronPlastic
  PUBLIC :: CastIronPlastic_UpdateStress
  PUBLIC :: UF_CastIron_UMAT

CONTAINS

  SUBROUTINE UF_Plastic_InitTDep(props, nprops, temp_props, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(TDepPlasticProps), INTENT(OUT) :: temp_props
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    temp_props%enabled = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_Plastic_InitTDep

  SUBROUTINE ci_solve_linear_2x2(A, b, x, status)
    REAL(wp), INTENT(IN) :: A(2, 2)
    REAL(wp), INTENT(IN) :: b(2)
    REAL(wp), INTENT(OUT) :: x(2)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: det
    REAL(wp), PARAMETER :: DET_TOL = 1.0e-14_wp

    CALL init_error_status(status)
    det = A(1, 1) * A(2, 2) - A(1, 2) * A(2, 1)
    IF (ABS(det) < DET_TOL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Singular matrix in 2x2 linear system solver"
      x = PH_MAT_CI_ZERO
      RETURN
    END IF
    x(1) = (b(1) * A(2, 2) - b(2) * A(1, 2)) / det
    x(2) = (A(1, 1) * b(2) - A(2, 1) * b(1)) / det
    status%status_code = IF_STATUS_OK
  END SUBROUTINE ci_solve_linear_2x2

  SUBROUTINE UF_CastIron_Init(Mat, props, nprops, status)
    TYPE(CastIronMat), INTENT(OUT) :: Mat
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    CALL UF_CastIron_ValidateProps(props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    Mat%PH_MAT_E = props(PH_MAT_CI_PROP_E)
    Mat%nu = props(PH_MAT_CI_PROP_NU)
    Mat%sigma_t0 = props(PH_MAT_CI_PROP_SIGMA_T0)
    Mat%sigma_c0 = props(PH_MAT_CI_PROP_SIGMA_C0)
    Mat%H_t = props(PH_MAT_CI_PROP_H_T)
    Mat%H_c = props(PH_MAT_CI_PROP_H_C)
    IF (nprops >= PH_MAT_CI_PROP_DAMAGE_T) Mat%damage_t_param = props(PH_MAT_CI_PROP_DAMAGE_T)
    IF (nprops >= PH_MAT_CI_PROP_DAMAGE_C) Mat%damage_c_param = props(PH_MAT_CI_PROP_DAMAGE_C)

    Mat%base%material_id = PH_MAT_CAST_IRON_MAT_I
    Mat%base%name = CAST_IRON_MAT_N

    CALL UF_Plastic_InitTDep(props, nprops, Mat%temp_props, status)
    IF (status%status_code == IF_STATUS_OK) Mat%temp_dependent = Mat%temp_props%enabled

    Mat%init = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_Init

  SUBROUTINE UF_CastIron_ValidateProps(props, nprops, status)
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(IN) :: nprops
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (nprops < PH_MAT_CI_MIN_PROPS) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE (status%message, '(A,I0,A,I0)') 'Insufficient properties: required at least ', &
        PH_MAT_CI_MIN_PROPS, ', provided ', nprops
      RETURN
    END IF
    IF (props(PH_MAT_CI_PROP_E) <= PH_MAT_CI_ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Young's modulus PH_MAT_E must be positive"
      RETURN
    END IF
    IF (props(PH_MAT_CI_PROP_NU) < -PH_MAT_CI_ONE .OR. props(PH_MAT_CI_PROP_NU) >= 0.5_wp) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Poisson's ratio must be in [-1, 0.5)"
      RETURN
    END IF
    IF (props(PH_MAT_CI_PROP_SIGMA_T0) <= PH_MAT_CI_ZERO .OR. props(PH_MAT_CI_PROP_SIGMA_C0) <= PH_MAT_CI_ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Tensile and compressive yield strengths must be positive"
      RETURN
    END IF
    IF (props(PH_MAT_CI_PROP_H_T) < PH_MAT_CI_ZERO .OR. props(PH_MAT_CI_PROP_H_C) < PH_MAT_CI_ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Hardening moduli must be non-negative"
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_ValidateProps

  SUBROUTINE UF_CastIron_ComputePrincStresses(stress, ndim, sigma_principal, sigma_max, sigma_min, status)
    REAL(wp), INTENT(IN) :: stress(6)
    INTEGER(i4), INTENT(IN) :: ndim
    REAL(wp), INTENT(OUT) :: sigma_principal(3), sigma_max, sigma_min
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: stress_matrix(3, 3)
    REAL(wp) :: eigenvalues(3)
    REAL(wp) :: trace, det_m, discriminant

    CALL init_error_status(status)
    stress_matrix = PH_MAT_CI_ZERO
    stress_matrix(1, 1) = stress(1)
    stress_matrix(2, 2) = stress(2)
    IF (ndim >= 3) THEN
      stress_matrix(3, 3) = stress(3)
      stress_matrix(1, 2) = stress(4)
      stress_matrix(2, 1) = stress(4)
      IF (ndim == 3) THEN
        stress_matrix(1, 3) = stress(5)
        stress_matrix(3, 1) = stress(5)
        stress_matrix(2, 3) = stress(6)
        stress_matrix(3, 2) = stress(6)
      END IF
    ELSE
      stress_matrix(1, 2) = stress(3)
      stress_matrix(2, 1) = stress(3)
    END IF

    IF (ndim == 2) THEN
      trace = stress_matrix(1, 1) + stress_matrix(2, 2)
      det_m = stress_matrix(1, 1) * stress_matrix(2, 2) - stress_matrix(1, 2)**2
      discriminant = trace**2 - 4.0_wp * det_m
      IF (discriminant >= PH_MAT_CI_ZERO) THEN
        eigenvalues(1) = (trace + SQRT(discriminant)) / PH_MAT_CI_TWO
        eigenvalues(2) = (trace - SQRT(discriminant)) / PH_MAT_CI_TWO
        eigenvalues(3) = PH_MAT_CI_ZERO
      ELSE
        eigenvalues(1) = trace / PH_MAT_CI_TWO
        eigenvalues(2) = trace / PH_MAT_CI_TWO
        eigenvalues(3) = PH_MAT_CI_ZERO
      END IF
    ELSE
      eigenvalues(1) = stress_matrix(1, 1)
      eigenvalues(2) = stress_matrix(2, 2)
      eigenvalues(3) = stress_matrix(3, 3)
    END IF

    sigma_max = MAXVAL(eigenvalues(1:ndim))
    sigma_min = MINVAL(eigenvalues(1:ndim))
    sigma_principal(1:3) = eigenvalues(1:3)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_ComputePrincStresses

  SUBROUTINE UF_CastIron_ComputeYieldFunction(Mat, sigma_max, sigma_min, eps_p_t, eps_p_c, &
      f_tension, f_compression, sigma_t, sigma_c, status)
    TYPE(CastIronMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: sigma_max, sigma_min, eps_p_t, eps_p_c
    REAL(wp), INTENT(OUT) :: f_tension, f_compression, sigma_t, sigma_c
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    sigma_t = Mat%sigma_t0 + Mat%H_t * eps_p_t
    sigma_c = Mat%sigma_c0 + Mat%H_c * eps_p_c
    f_tension = sigma_max - sigma_t
    f_compression = -sigma_min - sigma_c
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_ComputeYieldFunction

  SUBROUTINE UF_CastIron_ReturnMapping(Mat, stress_trial, sigma_max_trial, sigma_min_trial, &
      eps_p_t_old, eps_p_c_old, stress_new, sigma_max_new, sigma_min_new, &
      eps_p_t_new, eps_p_c_new, yield_type, delta_lambda, status)
    TYPE(CastIronMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: stress_trial(6), sigma_max_trial, sigma_min_trial
    REAL(wp), INTENT(IN) :: eps_p_t_old, eps_p_c_old
    REAL(wp), INTENT(OUT) :: stress_new(6), sigma_max_new, sigma_min_new
    REAL(wp), INTENT(OUT) :: eps_p_t_new, eps_p_c_new
    INTEGER(i4), INTENT(OUT) :: yield_type
    REAL(wp), INTENT(OUT) :: delta_lambda
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: f_tension, f_compression, sigma_t, sigma_c
    REAL(wp) :: residual(2), jacobian(2, 2), delta(2)
    REAL(wp) :: x_iter(2), x_old(2), norm_residual
    REAL(wp) :: sigma_yield_iter, E_eff
    INTEGER(i4) :: iter

    CALL init_error_status(status)

    CALL UF_CastIron_ComputeYieldFunction(Mat, sigma_max_trial, sigma_min_trial, &
      eps_p_t_old, eps_p_c_old, f_tension, f_compression, sigma_t, sigma_c, status)

    IF (f_tension > PH_MAT_CI_TOL .AND. sigma_max_trial > PH_MAT_CI_ZERO) THEN
      yield_type = PH_MAT_CI_YIELD_TENSION
      E_eff = Mat%PH_MAT_E
      x_iter(1) = PH_MAT_CI_ZERO
      x_iter(2) = eps_p_t_old
      DO iter = 1, PH_MAT_CI_MAX_ITER
        x_old = x_iter
        delta_lambda = x_iter(1)
        eps_p_t_new = x_iter(2)
        sigma_yield_iter = Mat%sigma_t0 + Mat%H_t * eps_p_t_new
        sigma_max_new = sigma_max_trial - E_eff * delta_lambda
        residual(1) = sigma_max_new - sigma_yield_iter
        residual(2) = eps_p_t_new - eps_p_t_old - delta_lambda
        norm_residual = SQRT(DOT_PRODUCT(residual, residual))
        IF (norm_residual < PH_MAT_CI_TOL) EXIT
        jacobian = PH_MAT_CI_ZERO
        jacobian(1, 1) = -E_eff
        jacobian(1, 2) = -Mat%H_t
        jacobian(2, 1) = -PH_MAT_CI_ONE
        jacobian(2, 2) = PH_MAT_CI_ONE
        CALL ci_solve_linear_2x2(jacobian, -residual, delta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
          delta_lambda = f_tension / (Mat%PH_MAT_E + Mat%H_t)
          eps_p_t_new = eps_p_t_old + delta_lambda
          EXIT
        END IF
        x_iter = x_old + delta
        x_iter(1) = MAX(x_iter(1), PH_MAT_CI_ZERO)
        x_iter(2) = MAX(x_iter(2), eps_p_t_old)
      END DO
      delta_lambda = x_iter(1)
      eps_p_t_new = x_iter(2)
      eps_p_c_new = eps_p_c_old
      sigma_max_new = sigma_max_trial - E_eff * delta_lambda
      sigma_min_new = sigma_min_trial
      IF (ABS(sigma_max_trial) > PH_MAT_CI_TOL) THEN
        stress_new = stress_trial * (sigma_max_new / sigma_max_trial)
      ELSE
        stress_new = stress_trial
      END IF
    ELSE IF (f_compression > PH_MAT_CI_TOL .AND. sigma_min_trial < PH_MAT_CI_ZERO) THEN
      yield_type = PH_MAT_CI_YIELD_COMPRESSI
      E_eff = Mat%PH_MAT_E
      x_iter(1) = PH_MAT_CI_ZERO
      x_iter(2) = eps_p_c_old
      DO iter = 1, PH_MAT_CI_MAX_ITER
        x_old = x_iter
        delta_lambda = x_iter(1)
        eps_p_c_new = x_iter(2)
        sigma_yield_iter = Mat%sigma_c0 + Mat%H_c * eps_p_c_new
        sigma_min_new = sigma_min_trial + E_eff * delta_lambda
        residual(1) = -sigma_min_new - sigma_yield_iter
        residual(2) = eps_p_c_new - eps_p_c_old - delta_lambda
        norm_residual = SQRT(DOT_PRODUCT(residual, residual))
        IF (norm_residual < PH_MAT_CI_TOL) EXIT
        jacobian = PH_MAT_CI_ZERO
        jacobian(1, 1) = -E_eff
        jacobian(1, 2) = -Mat%H_c
        jacobian(2, 1) = -PH_MAT_CI_ONE
        jacobian(2, 2) = PH_MAT_CI_ONE
        CALL ci_solve_linear_2x2(jacobian, -residual, delta, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
          delta_lambda = f_compression / (Mat%PH_MAT_E + Mat%H_c)
          eps_p_c_new = eps_p_c_old + delta_lambda
          EXIT
        END IF
        x_iter = x_old + delta
        x_iter(1) = MAX(x_iter(1), PH_MAT_CI_ZERO)
        x_iter(2) = MAX(x_iter(2), eps_p_c_old)
      END DO
      delta_lambda = x_iter(1)
      eps_p_c_new = x_iter(2)
      eps_p_t_new = eps_p_t_old
      sigma_max_new = sigma_max_trial
      sigma_min_new = sigma_min_trial + E_eff * delta_lambda
      IF (ABS(sigma_min_trial) > PH_MAT_CI_TOL) THEN
        stress_new = stress_trial * (sigma_min_new / sigma_min_trial)
      ELSE
        stress_new = stress_trial
      END IF
    ELSE
      stress_new = stress_trial
      sigma_max_new = sigma_max_trial
      sigma_min_new = sigma_min_trial
      eps_p_t_new = eps_p_t_old
      eps_p_c_new = eps_p_c_old
      yield_type = 0
      delta_lambda = PH_MAT_CI_ZERO
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_ReturnMapping

  SUBROUTINE UF_CastIron_ComputeTangent(Mat, stress, sigma_max, sigma_min, yield_type, delta_lambda, &
      D_elastic, lambda_lame, mu, ndim, ntens, D_tangent, status)
    TYPE(CastIronMat), INTENT(IN) :: Mat
    REAL(wp), INTENT(IN) :: stress(6), sigma_max, sigma_min
    INTEGER(i4), INTENT(IN) :: yield_type
    REAL(wp), INTENT(IN) :: delta_lambda
    REAL(wp), INTENT(IN) :: D_elastic(6, 6), lambda_lame, mu
    INTEGER(i4), INTENT(IN) :: ndim, ntens
    REAL(wp), INTENT(OUT) :: D_tangent(6, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    D_tangent = D_elastic
    IF (yield_type == 0) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF
    IF (yield_type == PH_MAT_CI_YIELD_TENSION) THEN
      D_tangent = D_elastic * (Mat%PH_MAT_E / (Mat%PH_MAT_E + Mat%H_t))
    ELSE IF (yield_type == PH_MAT_CI_YIELD_COMPRESSI) THEN
      D_tangent = D_elastic * (Mat%PH_MAT_E / (Mat%PH_MAT_E + Mat%H_c))
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CastIron_ComputeTangent

  SUBROUTINE UF_CastIron_UMAT(sigma, statev, ddsdde, sse, spd, scd, &
      rpl, ddsddt, drplde, drpldt, &
      stran, dstran, time, dtime, temp, dtemp, &
      predef, dpred, ndir, nshr, nstatev, nprops, &
      props, ndim, kstep, kinc)
    REAL(wp), INTENT(INOUT) :: stress(6)
    REAL(wp), INTENT(INOUT) :: statev(nstatev)
    REAL(wp), INTENT(OUT) :: ddsdde(6, 6)
    REAL(wp), INTENT(OUT) :: sse, spd, scd, rpl
    REAL(wp), INTENT(OUT) :: ddsddt(6), drplde(6), drpldt
    REAL(wp), INTENT(IN) :: stran(6), dstran(6)
    REAL(wp), INTENT(IN) :: time(2), dtime
    REAL(wp), INTENT(IN) :: temp, dtemp
    REAL(wp), INTENT(IN) :: predef(*), dpred(*)
    INTEGER(i4), INTENT(IN) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    REAL(wp), INTENT(IN) :: props(nprops)

    TYPE(CastIronMat) :: Mat
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: strain_total(6)
    REAL(wp) :: stress_trial(6), stress_new(6)
    REAL(wp) :: sigma_principal(3), sigma_max_trial, sigma_min_trial
    REAL(wp) :: sigma_max_new, sigma_min_new
    REAL(wp) :: eps_p_t_old, eps_p_c_old, eps_p_t_new, eps_p_c_new
    REAL(wp) :: lambda_lame, mu
    REAL(wp) :: D_elastic(6, 6), D_tangent(6, 6)
    REAL(wp) :: delta_lambda
    INTEGER(i4) :: yield_type
    INTEGER(i4) :: ntens, i, j

    sse = PH_MAT_CI_ZERO
    spd = PH_MAT_CI_ZERO
    scd = PH_MAT_CI_ZERO
    rpl = PH_MAT_CI_ZERO
    ddsddt = PH_MAT_CI_ZERO
    drplde = PH_MAT_CI_ZERO
    drpldt = PH_MAT_CI_ZERO
    ddsdde = PH_MAT_CI_ZERO
    ntens = ndir + nshr

    CALL UF_CastIron_Init(Mat, props, nprops, status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      CALL log_error('PH_Mat_PLM_CastIron::UMAT', status%message)
      RETURN
    END IF

    eps_p_t_old = PH_MAT_CI_ZERO
    eps_p_c_old = PH_MAT_CI_ZERO
    IF (nstatev >= PH_MAT_CI_STATEV_EPS_P_T) eps_p_t_old = statev(PH_MAT_CI_STATEV_EPS_P_T)
    IF (nstatev >= PH_MAT_CI_STATEV_EPS_P_C) eps_p_c_old = statev(PH_MAT_CI_STATEV_EPS_P_C)

    strain_total = stran + dstran
    lambda_lame = Mat%PH_MAT_E * Mat%nu / ((PH_MAT_CI_ONE + Mat%nu) * (PH_MAT_CI_ONE - PH_MAT_CI_TWO * Mat%nu))
    mu = Mat%PH_MAT_E / (PH_MAT_CI_TWO * (PH_MAT_CI_ONE + Mat%nu))

    D_elastic = PH_MAT_CI_ZERO
    DO i = 1, ndim
      DO j = 1, ndim
        IF (i == j) THEN
          D_elastic(i, j) = lambda_lame + PH_MAT_CI_TWO * mu
        ELSE
          D_elastic(i, j) = lambda_lame
        END IF
      END DO
    END DO
    DO i = ndim + 1, ntens
      D_elastic(i, i) = mu
    END DO

    DO i = 1, ntens
      stress_trial(i) = PH_MAT_CI_ZERO
      DO j = 1, ntens
        stress_trial(i) = stress_trial(i) + D_elastic(i, j) * dstran(j)
      END DO
      stress_trial(i) = stress(i) + stress_trial(i)
    END DO

    CALL UF_CastIron_ComputePrincStresses(stress_trial, ndim, sigma_principal, &
      sigma_max_trial, sigma_min_trial, status)
    CALL UF_CastIron_ReturnMapping(Mat, stress_trial, sigma_max_trial, sigma_min_trial, &
      eps_p_t_old, eps_p_c_old, stress_new, sigma_max_new, sigma_min_new, &
      eps_p_t_new, eps_p_c_new, yield_type, delta_lambda, status)

    IF (status%status_code /= IF_STATUS_OK) THEN
      CALL log_error('PH_Mat_PLM_CastIron::UMAT', status%message)
      RETURN
    END IF

    stress = stress_new
    CALL UF_CastIron_ComputeTangent(Mat, stress_new, sigma_max_new, sigma_min_new, yield_type, delta_lambda, &
      D_elastic, lambda_lame, mu, ndim, ntens, D_tangent, status)
    IF (status%status_code /= IF_STATUS_OK) D_tangent = D_elastic
    ddsdde = D_tangent
    sse = 0.5_wp * DOT_PRODUCT(stress(1:ntens), strain_total(1:ntens))
    IF (nstatev >= PH_MAT_CI_STATEV_EPS_P_T) statev(PH_MAT_CI_STATEV_EPS_P_T) = eps_p_t_new
    IF (nstatev >= PH_MAT_CI_STATEV_EPS_P_C) statev(PH_MAT_CI_STATEV_EPS_P_C) = eps_p_c_new
  END SUBROUTINE UF_CastIron_UMAT

  SUBROUTINE CastIronPlastic_UpdateStress(in, out)
    TYPE(MatPoint_In), INTENT(IN) :: in
    TYPE(MatPoint_Out), INTENT(OUT) :: out

    INTEGER(i4) :: ntens, ndim, i, j
    REAL(wp) :: PH_MAT_E, nu, lambda, mu
    REAL(wp) :: sigma_t0, sigma_c0, H
    REAL(wp) :: D(6, 6), stress_trial(6), strain_tot(6)
    REAL(wp) :: sigma_eqv, sigma_vm, p
    REAL(wp) :: dlambda_p, hardening_modulus
    REAL(wp) :: flow_dir(6)

    CALL init_error_status(out%status)
    ntens = in%ntens
    IF (ntens <= 0) ntens = 6
    ndim = in%ndi
    IF (ndim <= 0) ndim = 3

    IF (.NOT. ALLOCATED(in%props) .OR. SIZE(in%props) < 5) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "CastIronPlastic_UpdateStress: need 5 props"
      RETURN
    END IF

    PH_MAT_E = in%props(1)
    nu = in%props(2)
    sigma_t0 = in%props(3)
    sigma_c0 = in%props(4)
    H = in%props(5)

    IF (PH_MAT_E <= 0.0_wp .OR. sigma_t0 <= 0.0_wp .OR. sigma_c0 <= 0.0_wp) THEN
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "CastIronPlastic_UpdateStress: invalid parameters"
      RETURN
    END IF

    IF (ABS(1.0_wp - 2.0_wp * nu) < 1.0e-10_wp) THEN
      lambda = PH_MAT_E / 3.0_wp
      mu = PH_MAT_E / 3.0_wp
    ELSE
      lambda = PH_MAT_E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
      mu = PH_MAT_E / (2.0_wp * (1.0_wp + nu))
    END IF

    D = 0.0_wp
    IF (ndim >= 3) THEN
      D(1, 1) = lambda + 2.0_wp * mu
      D(1, 2) = lambda
      D(1, 3) = lambda
      D(2, 1) = lambda
      D(2, 2) = lambda + 2.0_wp * mu
      D(2, 3) = lambda
      D(3, 1) = lambda
      D(3, 2) = lambda
      D(3, 3) = lambda + 2.0_wp * mu
      D(4, 4) = mu
      D(5, 5) = mu
      D(6, 6) = mu
    ELSE IF (ndim == 2) THEN
      D(1, 1) = lambda + 2.0_wp * mu
      D(1, 2) = lambda
      D(2, 1) = lambda
      D(2, 2) = lambda + 2.0_wp * mu
      D(3, 3) = mu
    ELSE
      D(1, 1) = lambda + 2.0_wp * mu
    END IF

    strain_tot = in%strain_old + in%strain_inc
    stress_trial = 0.0_wp
    DO i = 1, ntens
      DO j = 1, ntens
        stress_trial(i) = stress_trial(i) + D(i, j) * strain_tot(j)
      END DO
    END DO

    sigma_vm = SQRT(1.5_wp * (stress_trial(1)**2 + stress_trial(2)**2 + stress_trial(3)**2 + &
      2.0_wp * (stress_trial(4)**2 + stress_trial(5)**2 + stress_trial(6)**2)))
    p = (stress_trial(1) + stress_trial(2) + stress_trial(3)) / 3.0_wp

    IF (p > 0.0_wp) THEN
      sigma_eqv = sigma_vm
    ELSE
      sigma_eqv = sigma_vm * (sigma_c0 / sigma_t0)
    END IF

    IF (sigma_eqv <= sigma_t0) THEN
      out%sigma = stress_trial
      out%ddsdde = 0.0_wp
      DO j = 1, ntens
        DO i = 1, ntens
          out%ddsdde(i, j) = D(i, j)
        END DO
      END DO
    ELSE
      dlambda_p = (sigma_eqv - sigma_t0) / (3.0_wp * mu + H)
      hardening_modulus = 3.0_wp * mu * H / (3.0_wp * mu + H)

      flow_dir = 0.0_wp
      IF (sigma_vm > 1.0e-10_wp) THEN
        flow_dir(1) = 1.5_wp * stress_trial(1) / sigma_vm
        flow_dir(2) = 1.5_wp * stress_trial(2) / sigma_vm
        flow_dir(3) = 1.5_wp * stress_trial(3) / sigma_vm
        flow_dir(4) = 3.0_wp * stress_trial(4) / sigma_vm
        flow_dir(5) = 3.0_wp * stress_trial(5) / sigma_vm
        flow_dir(6) = 3.0_wp * stress_trial(6) / sigma_vm
      END IF

      DO i = 1, ntens
        out%sigma(i) = stress_trial(i) - 2.0_wp * mu * dlambda_p * flow_dir(i)
      END DO

      out%ddsdde = 0.0_wp
      DO j = 1, ntens
        DO i = 1, ntens
          out%ddsdde(i, j) = D(i, j) - hardening_modulus * flow_dir(i) * flow_dir(j)
        END DO
      END DO
    END IF

    out%pnewdt = 1.0_wp
    IF (ALLOCATED(in%statev)) THEN
      IF (.NOT. ALLOCATED(out%statev)) ALLOCATE(out%statev(SIZE(in%statev)))
      out%statev = in%statev
    END IF
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE CastIronPlastic_UpdateStress

  SUBROUTINE PH_MAT_UMAT_CastIronPlastic(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(MatPoint_In) :: in
    TYPE(MatPoint_Out) :: out
    CALL Unpack_From_UMAT_Context(ctx, in)
    CALL CastIronPlastic_UpdateStress(in, out)
    IF (out%status%status_code == IF_STATUS_OK) CALL Pack_To_UMAT_Context(out, ctx)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE PH_MAT_UMAT_CastIronPlastic

  SUBROUTINE PH_Mat_PLM_CastIronic_Update(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    TYPE(MatPoint_In) :: in
    TYPE(MatPoint_Out) :: out
    CALL Unpack_From_UMAT_Context(ctx, in)
    CALL CastIronPlastic_UpdateStress(in, out)
    IF (out%status%status_code == IF_STATUS_OK) CALL Pack_To_UMAT_Context(out, ctx)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE PH_Mat_Comp_Castani_Update

END MODULE PH_Mat_Comp_Cast_Core