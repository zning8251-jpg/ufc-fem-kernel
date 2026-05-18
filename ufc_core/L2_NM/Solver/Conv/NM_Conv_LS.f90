!===============================================================================
! MODULE: NM_Conv_LS
! LAYER:  L2_NM
! DOMAIN: Solver/Conv
! ROLE:   Proc (line search + trust region)
! BRIEF:  Line search and trust-region convergence methods
!
! Theory: Nocedal & Wright (2006); Conn et al. (2000)
!
! Status: PROD | Last verified: 2026-03-10
!===============================================================================

MODULE NM_Conv_LS
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  ! Line Search constants
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_ARMIJO = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_WOLFE = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_STRONG_WOLFE = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_GOLDSTEIN = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_EXACT = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_LINESEARCH_NON_MONOTONE = 6

  INTEGER(i4), PARAMETER, PUBLIC :: NM_INTERP_QUADRATIC = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_INTERP_CUBIC = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_INTERP_BISECTION = 3

  ! Trust-Region constants
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TR_DOGLEG = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TR_STEIHAUG = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TR_MORE_SORENSEN = 3

  ! Line Search types (vector-based, used by QuasiNewton)
  TYPE, PUBLIC :: LineSearch_Params
    INTEGER(i4) :: criterion = NM_LINESEARCH_WOLFE
    REAL(DP) :: c1 = 1.0E-4_DP
    REAL(DP) :: c2 = 0.9_DP
    REAL(DP) :: alpha_init = 1.0_DP
    REAL(DP) :: alpha_min = 1.0E-10_DP
    REAL(DP) :: alpha_max = 1.0E10_DP
    REAL(DP) :: rho = 0.5_DP
    INTEGER(i4) :: max_iter = 20_i4
    INTEGER(i4) :: interpolation = NM_INTERP_CUBIC
    LOGICAL :: verbose = .FALSE.
  END TYPE LineSearch_Params

  TYPE, PUBLIC :: LineSearch_State_Step
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: alpha_prev = ZERO
  END TYPE LineSearch_State_Step

  TYPE, PUBLIC :: LineSearch_State_Obj
    REAL(DP) :: phi = ZERO
    REAL(DP) :: phi_prev = ZERO
    REAL(DP) :: phi0 = ZERO
  END TYPE LineSearch_State_Obj

  TYPE, PUBLIC :: LineSearch_State_Grad
    REAL(DP) :: dphi = ZERO
    REAL(DP) :: dphi_prev = ZERO
    REAL(DP) :: dphi0 = ZERO
  END TYPE LineSearch_State_Grad

  TYPE, PUBLIC :: LineSearch_State_Status
    INTEGER(i4) :: iteration = 0_i4
    LOGICAL :: converged = .FALSE.
  END TYPE LineSearch_State_Status

  TYPE, PUBLIC :: LineSearch_State
    TYPE(LineSearch_State_Step)   :: step
    TYPE(LineSearch_State_Obj)    :: obj
    TYPE(LineSearch_State_Grad)   :: grad
    TYPE(LineSearch_State_Status) :: status
  END TYPE LineSearch_State

  TYPE, PUBLIC :: LineSearch_Result
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: phi_alpha = ZERO
    REAL(DP) :: dphi_alpha = ZERO
    INTEGER(i4) :: n_iterations = 0_i4
    LOGICAL :: success = .FALSE.
    CHARACTER(LEN=128) :: message = ""
  END TYPE LineSearch_Result

  TYPE, PUBLIC :: Function_Eval
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: phi = ZERO
    REAL(DP) :: dphi = ZERO
  END TYPE Function_Eval

  ! Trust-Region types (from LS_Core)
  TYPE, PUBLIC :: TrustRegion_Params_Method
    INTEGER(i4) :: method
  END TYPE TrustRegion_Params_Method

  TYPE, PUBLIC :: TrustRegion_Params_Delta
    REAL(DP) :: delta_init
    REAL(DP) :: delta_min
    REAL(DP) :: delta_max
  END TYPE TrustRegion_Params_Delta

  TYPE, PUBLIC :: TrustRegion_Params_Eta
    REAL(DP) :: eta
    REAL(DP) :: eta1
    REAL(DP) :: eta2
  END TYPE TrustRegion_Params_Eta

  TYPE, PUBLIC :: TrustRegion_Params_Gamma
    REAL(DP) :: gamma1
    REAL(DP) :: gamma2
  END TYPE TrustRegion_Params_Gamma

  TYPE, PUBLIC :: TrustRegion_Params_CG
    INTEGER(i4) :: max_cg_iter
    REAL(DP) :: cg_tol
  END TYPE TrustRegion_Params_CG

  TYPE, PUBLIC :: TrustRegion_Params
    TYPE(TrustRegion_Params_Method) :: method
    TYPE(TrustRegion_Params_Delta) :: delta
    TYPE(TrustRegion_Params_Eta) :: eta
    TYPE(TrustRegion_Params_Gamma) :: gamma
    TYPE(TrustRegion_Params_CG) :: cg
  END TYPE TrustRegion_Params

  TYPE, PUBLIC :: TrustRegion_State
    REAL(DP) :: delta
    REAL(DP) :: rho
    INTEGER(i4) :: iter_count
    LOGICAL :: converged
    LOGICAL :: hit_boundary
  END TYPE TrustRegion_State

  ! Line Search (vector-based)
  PUBLIC :: NM_LineSearch
  PUBLIC :: NM_LineSearch_Armijo
  PUBLIC :: NM_LineSearch_Wolfe
  PUBLIC :: NM_LineSearch_Strong_Wolfe
  PUBLIC :: NM_Backtracking_LineSearch
  PUBLIC :: NM_Backtracking_Cubic
  PUBLIC :: NM_Cubic_Interpolation_Step
  PUBLIC :: NM_Quadratic_Interpolation_Step
  PUBLIC :: NM_Golden_Section_LineSearch
  PUBLIC :: NM_Eval_Phi
  PUBLIC :: NM_Eval_Dphi
  PUBLIC :: NM_Check_Armijo_Condition
  PUBLIC :: NM_Check_Wolfe_Condition
  PUBLIC :: NM_LineSearch_Init
  PUBLIC :: NM_LineSearch_Default_Params

  ! Trust-Region
  PUBLIC :: NM_TrustRegion_Default_Params
  PUBLIC :: NM_TrustRegion_Dogleg
  PUBLIC :: NM_TrustRegion_Steihaug
  PUBLIC :: NM_TrustRegion_Update_Radius

CONTAINS

  !-----------------------------------------------------------------------------
  ! Line Search Default Params
  !-----------------------------------------------------------------------------
  FUNCTION NM_LineSearch_Default_Params() RESULT(params)
    TYPE(LineSearch_Params) :: params
    params%criterion = NM_LINESEARCH_WOLFE
    params%c1 = 1.0E-4_DP
    params%c2 = 0.9_DP
    params%alpha_init = 1.0_DP
    params%alpha_min = 1.0E-10_DP
    params%alpha_max = 1.0E10_DP
    params%rho = 0.5_DP
    params%max_iter = 20_i4
    params%interpolation = NM_INTERP_CUBIC
    params%verbose = .FALSE.
  END FUNCTION NM_LineSearch_Default_Params

  !-----------------------------------------------------------------------------
  ! Main Line Search Interface (vector-based)
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_LineSearch(params, x0, d, phi0, dphi0, &
                            Objective_proc, Gradient_proc, result, status)
    TYPE(LineSearch_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
      FUNCTION Gradient_proc(x) RESULT(g)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: g(SIZE(x))
      END FUNCTION
    END INTERFACE
    TYPE(LineSearch_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    SELECT CASE (params%criterion)
    CASE (NM_LINESEARCH_ARMIJO)
      CALL NM_LineSearch_Armijo(params, x0, d, phi0, dphi0, Objective_proc, result, status)
    CASE (NM_LINESEARCH_WOLFE)
      CALL NM_LineSearch_Wolfe(params, x0, d, phi0, dphi0, &
                                Objective_proc, Gradient_proc, result, status)
    CASE (NM_LINESEARCH_STRONG_WOLFE)
      CALL NM_LineSearch_Strong_Wolfe(params, x0, d, phi0, dphi0, &
                                       Objective_proc, Gradient_proc, result, status)
    CASE DEFAULT
      CALL NM_LineSearch_Wolfe(params, x0, d, phi0, dphi0, &
                                Objective_proc, Gradient_proc, result, status)
    END SELECT
  END SUBROUTINE NM_LineSearch

  SUBROUTINE NM_LineSearch_Armijo(params, x0, d, phi0, dphi0, &
                                   Objective_proc, result, status)
    TYPE(LineSearch_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
    END INTERFACE
    TYPE(LineSearch_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha, phi_alpha
    INTEGER(i4) :: iter

    CALL init_error_status(status)
    alpha = params%alpha_init
    result%n_iterations = 0_i4
    result%success = .FALSE.

    IF (dphi0 >= ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Armijo: dphi0 >= 0, not a descent direction"
      RETURN
    END IF

    DO iter = 1, params%max_iter
      result%n_iterations = iter
      phi_alpha = NM_Eval_Phi(x0, d, alpha, Objective_proc)
      IF (NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, params%c1)) THEN
        result%success = .TRUE.
        result%alpha = alpha
        result%phi_alpha = phi_alpha
        result%message = "Armijo condition satisfied"
        EXIT
      END IF
      alpha = alpha * params%rho
      IF (alpha < params%alpha_min) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "Armijo: alpha < alpha_min"
        EXIT
      END IF
    END DO

    IF (.NOT. result%success) THEN
      result%alpha = alpha
      result%phi_alpha = phi_alpha
    END IF
  END SUBROUTINE NM_LineSearch_Armijo

  SUBROUTINE NM_LineSearch_Wolfe(params, x0, d, phi0, dphi0, &
                                  Objective_proc, Gradient_proc, result, status)
    TYPE(LineSearch_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
      FUNCTION Gradient_proc(x) RESULT(g)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: g(SIZE(x))
      END FUNCTION
    END INTERFACE
    TYPE(LineSearch_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha, alpha_prev, phi_alpha, phi_prev, dphi_alpha
    INTEGER(i4) :: iter

    CALL init_error_status(status)
    alpha = params%alpha_init
    alpha_prev = ZERO
    phi_prev = phi0
    result%n_iterations = 0_i4
    result%success = .FALSE.

    IF (dphi0 >= ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Wolfe: dphi0 >= 0"
      RETURN
    END IF

    DO iter = 1, params%max_iter
      result%n_iterations = iter
      phi_alpha = NM_Eval_Phi(x0, d, alpha, Objective_proc)
      dphi_alpha = NM_Eval_Dphi(x0, d, alpha, Gradient_proc)

      IF (.NOT. NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, params%c1)) THEN
        alpha = NM_Cubic_Interpolation_Step(alpha_prev, alpha, phi_prev, phi_alpha, &
                                             dphi0, dphi_alpha)
        alpha = MAX(alpha, params%alpha_min)
        CYCLE
      END IF

      IF (NM_Check_Wolfe_Condition(dphi_alpha, dphi0, params%c2)) THEN
        result%success = .TRUE.
        result%alpha = alpha
        result%phi_alpha = phi_alpha
        result%dphi_alpha = dphi_alpha
        result%message = "Wolfe conditions satisfied"
        EXIT
      END IF

      alpha_prev = alpha
      phi_prev = phi_alpha
      alpha = alpha * 2.0_DP
      IF (alpha > params%alpha_max) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "Wolfe: alpha > alpha_max"
        EXIT
      END IF
    END DO

    IF (.NOT. result%success) THEN
      result%alpha = alpha
      result%phi_alpha = phi_alpha
      result%dphi_alpha = dphi_alpha
    END IF
  END SUBROUTINE NM_LineSearch_Wolfe

  SUBROUTINE NM_LineSearch_Strong_Wolfe(params, x0, d, phi0, dphi0, &
                                         Objective_proc, Gradient_proc, result, status)
    TYPE(LineSearch_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
      FUNCTION Gradient_proc(x) RESULT(g)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: g(SIZE(x))
      END FUNCTION
    END INTERFACE
    TYPE(LineSearch_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha, phi_alpha, dphi_alpha
    INTEGER(i4) :: iter
    LOGICAL :: armijo_satisfied, strong_wolfe_satisfied

    CALL init_error_status(status)
    alpha = params%alpha_init
    result%n_iterations = 0_i4
    result%success = .FALSE.

    IF (dphi0 >= ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Strong Wolfe: dphi0 >= 0"
      RETURN
    END IF

    DO iter = 1, params%max_iter
      result%n_iterations = iter
      phi_alpha = NM_Eval_Phi(x0, d, alpha, Objective_proc)
      dphi_alpha = NM_Eval_Dphi(x0, d, alpha, Gradient_proc)

      armijo_satisfied = NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, params%c1)
      strong_wolfe_satisfied = (ABS(dphi_alpha) <= params%c2 * ABS(dphi0))

      IF (armijo_satisfied .AND. strong_wolfe_satisfied) THEN
        result%success = .TRUE.
        result%alpha = alpha
        result%phi_alpha = phi_alpha
        result%dphi_alpha = dphi_alpha
        result%message = "Strong Wolfe conditions satisfied"
        EXIT
      END IF

      IF (.NOT. armijo_satisfied) THEN
        alpha = alpha * params%rho
      ELSE
        alpha = alpha * 1.5_DP
      END IF

      IF (alpha < params%alpha_min .OR. alpha > params%alpha_max) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "Strong Wolfe: alpha out of bounds"
        EXIT
      END IF
    END DO

    IF (.NOT. result%success) THEN
      result%alpha = alpha
      result%phi_alpha = phi_alpha
      result%dphi_alpha = dphi_alpha
    END IF
  END SUBROUTINE NM_LineSearch_Strong_Wolfe

  SUBROUTINE NM_Backtracking_LineSearch(x0, d, phi0, dphi0, rho, c1, &
                                         Objective_proc, alpha, status)
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    REAL(DP), INTENT(IN) :: rho, c1
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
    END INTERFACE
    REAL(DP), INTENT(OUT) :: alpha
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: phi_alpha
    INTEGER(i4) :: iter

    CALL init_error_status(status)
    alpha = 1.0_DP
    DO iter = 1, 20
      phi_alpha = NM_Eval_Phi(x0, d, alpha, Objective_proc)
      IF (NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, c1)) EXIT
      alpha = alpha * rho
      IF (alpha < 1.0E-10_DP) THEN
        status%status_code = IF_STATUS_WARN
        status%message = "Backtracking: alpha too small"
        EXIT
      END IF
    END DO
  END SUBROUTINE NM_Backtracking_LineSearch

  SUBROUTINE NM_Backtracking_Cubic(x0, d, phi0, dphi0, rho, c1, &
                                    Objective_proc, alpha, status)
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    REAL(DP), INTENT(IN) :: rho, c1
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
    END INTERFACE
    REAL(DP), INTENT(OUT) :: alpha
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP) :: alpha_prev, phi_prev, phi_alpha
    INTEGER(i4) :: iter

    CALL init_error_status(status)
    alpha = 1.0_DP
    alpha_prev = ZERO
    phi_prev = phi0
    DO iter = 1, 20
      phi_alpha = NM_Eval_Phi(x0, d, alpha, Objective_proc)
      IF (NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, c1)) EXIT
      alpha = NM_Cubic_Interpolation_Step(alpha_prev, alpha, phi_prev, phi_alpha, &
                                           dphi0, (phi_alpha - phi_prev) / (alpha - alpha_prev))
      alpha = MAX(alpha, rho * alpha_prev)
      alpha_prev = alpha
      phi_prev = phi_alpha
      IF (alpha < 1.0E-10_DP) THEN
        status%status_code = IF_STATUS_WARN
        EXIT
      END IF
    END DO
  END SUBROUTINE NM_Backtracking_Cubic

  FUNCTION NM_Cubic_Interpolation_Step(a, b, phi_a, phi_b, dphi_a, dphi_b) RESULT(alpha)
    REAL(DP), INTENT(IN) :: a, b, phi_a, phi_b, dphi_a, dphi_b
    REAL(DP) :: alpha
    REAL(DP) :: d1, d2, s, z
    s = b - a
    d1 = dphi_a + dphi_b - 3.0_DP * (phi_a - phi_b) / s
    d2 = SIGN(SQRT(d1**2 - dphi_a * dphi_b), d1)
    IF (ABS(d1 + d2 - dphi_a) > ABS(d1 - d2 - dphi_a)) THEN
      z = d1 + d2 - dphi_a
    ELSE
      z = d1 - d2 - dphi_a
    END IF
    IF (ABS(z) > 1.0E-14_DP) THEN
      alpha = b - s * (dphi_b + d2 - d1) / z
    ELSE
      alpha = (a + b) / TWO
    END IF
    alpha = MAX(a + 0.1_DP * s, MIN(b - 0.1_DP * s, alpha))
  END FUNCTION NM_Cubic_Interpolation_Step

  FUNCTION NM_Quadratic_Interpolation_Step(a, b, phi_a, phi_b, dphi_a) RESULT(alpha)
    REAL(DP), INTENT(IN) :: a, b, phi_a, phi_b, dphi_a
    REAL(DP) :: alpha
    REAL(DP) :: s, d
    s = b - a
    d = phi_b - phi_a - dphi_a * s
    IF (ABS(d) > 1.0E-14_DP) THEN
      alpha = a - dphi_a * s**2 / (TWO * d)
    ELSE
      alpha = (a + b) / TWO
    END IF
  END FUNCTION NM_Quadratic_Interpolation_Step

  SUBROUTINE NM_Golden_Section_LineSearch(x0, d, phi0, dphi0, Objective_proc, alpha, status)
    REAL(DP), INTENT(IN) :: x0(:), d(:)
    REAL(DP), INTENT(IN) :: phi0, dphi0
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
    END INTERFACE
    REAL(DP), INTENT(OUT) :: alpha
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), PARAMETER :: GOLDEN_RATIO = 0.618033988749895_DP
    REAL(DP) :: a, b, c, d_gs
    REAL(DP) :: phi_a, phi_b, phi_c, phi_d
    INTEGER(i4) :: iter

    CALL init_error_status(status)
    a = ZERO
    b = 1.0_DP
    c = b - GOLDEN_RATIO * (b - a)
    d_gs = a + GOLDEN_RATIO * (b - a)
    phi_c = NM_Eval_Phi(x0, d, c, Objective_proc)
    phi_d = NM_Eval_Phi(x0, d, d_gs, Objective_proc)

    DO iter = 1, 50
      IF (phi_c < phi_d) THEN
        b = d_gs
        d_gs = c
        phi_d = phi_c
        c = b - GOLDEN_RATIO * (b - a)
        phi_c = NM_Eval_Phi(x0, d, c, Objective_proc)
      ELSE
        a = c
        c = d_gs
        phi_c = phi_d
        d_gs = a + GOLDEN_RATIO * (b - a)
        phi_d = NM_Eval_Phi(x0, d, d_gs, Objective_proc)
      END IF
      IF (ABS(b - a) < 1.0E-10_DP) EXIT
    END DO
    alpha = (a + b) / TWO
  END SUBROUTINE NM_Golden_Section_LineSearch

  FUNCTION NM_Eval_Phi(x0, d, alpha, Objective_proc) RESULT(phi)
    REAL(DP), INTENT(IN) :: x0(:), d(:), alpha
    INTERFACE
      FUNCTION Objective_proc(x) RESULT(f)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: f
      END FUNCTION
    END INTERFACE
    REAL(DP) :: phi
    REAL(DP), ALLOCATABLE :: x(:)
    ALLOCATE(x(SIZE(x0)))
    x = x0 + alpha * d
    phi = Objective_proc(x)
    DEALLOCATE(x)
  END FUNCTION NM_Eval_Phi

  FUNCTION NM_Eval_Dphi(x0, d, alpha, Gradient_proc) RESULT(dphi)
    REAL(DP), INTENT(IN) :: x0(:), d(:), alpha
    INTERFACE
      FUNCTION Gradient_proc(x) RESULT(g)
        IMPORT :: DP
        REAL(DP), INTENT(IN) :: x(:)
        REAL(DP) :: g(SIZE(x))
      END FUNCTION
    END INTERFACE
    REAL(DP) :: dphi
    REAL(DP), ALLOCATABLE :: x(:), grad(:)
    ALLOCATE(x(SIZE(x0)), grad(SIZE(x0)))
    x = x0 + alpha * d
    grad = Gradient_proc(x)
    dphi = DOT_PRODUCT(grad, d)
    DEALLOCATE(x, grad)
  END FUNCTION NM_Eval_Dphi

  FUNCTION NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, c1) RESULT(satisfied)
    REAL(DP), INTENT(IN) :: phi_alpha, phi0, dphi0, alpha, c1
    LOGICAL :: satisfied
    satisfied = (phi_alpha <= phi0 + c1 * alpha * dphi0)
  END FUNCTION NM_Check_Armijo_Condition

  FUNCTION NM_Check_Wolfe_Condition(dphi_alpha, dphi0, c2) RESULT(satisfied)
    REAL(DP), INTENT(IN) :: dphi_alpha, dphi0, c2
    LOGICAL :: satisfied
    satisfied = (dphi_alpha >= c2 * dphi0)
  END FUNCTION NM_Check_Wolfe_Condition

  SUBROUTINE NM_LineSearch_Init(state, phi0, dphi0, alpha_init)
    TYPE(LineSearch_State), INTENT(OUT) :: state
    REAL(DP), INTENT(IN) :: phi0, dphi0, alpha_init
    state%step%alpha = alpha_init
    state%step%alpha_prev = ZERO
    state%obj%phi = phi0
    state%obj%phi_prev = phi0
    state%grad%dphi = dphi0
    state%grad%dphi_prev = dphi0
    state%obj%phi0 = phi0
    state%grad%dphi0 = dphi0
    state%status%iteration = 0_i4
    state%status%converged = .FALSE.
  END SUBROUTINE NM_LineSearch_Init

  !-----------------------------------------------------------------------------
  ! Trust-Region (from LS_Core)
  !-----------------------------------------------------------------------------
  FUNCTION NM_TrustRegion_Default_Params() RESULT(params)
    TYPE(TrustRegion_Params) :: params
    params%method%method = NM_TR_DOGLEG
    params%delta%delta_init = 1.0_DP
    params%delta%delta_min = 1.0e-10_DP
    params%delta%delta_max = 1.0e10_DP
    params%eta%eta = 0.0_DP
    params%eta%eta%eta1 = 0.25_DP
    params%eta%eta%eta2 = 0.75_DP
    params%gamma%gamma1 = 0.25_DP
    params%gamma%gamma2 = 2.0_DP
    params%cg%max_cg_iter = 100
    params%cg%cg_tol = 1.0e-6_DP
  END FUNCTION NM_TrustRegion_Default_Params

  SUBROUTINE NM_Find_Boundary_Intersection(z, d, delta, p)
    REAL(DP), INTENT(IN) :: z(:), d(:)
    REAL(DP), INTENT(IN) :: delta
    REAL(DP), INTENT(OUT) :: p(:)
    REAL(DP) :: a, b, c, discriminant, tau
    a = DOT_PRODUCT(d, d)
    b = 2.0_DP * DOT_PRODUCT(z, d)
    c = DOT_PRODUCT(z, z) - delta**2
    discriminant = b**2 - 4.0_DP * a * c
    IF (discriminant >= 0.0_DP) THEN
      tau = (-b + SQRT(discriminant)) / (2.0_DP * a)
      tau = MAX(0.0_DP, tau)
    ELSE
      tau = 0.0_DP
    END IF
    p = z + tau * d
  END SUBROUTINE NM_Find_Boundary_Intersection

  SUBROUTINE NM_TrustRegion_Dogleg(g, B, delta, p, hit_boundary)
    REAL(DP), INTENT(IN) :: g(:)
    REAL(DP), INTENT(IN) :: B(:,:)
    REAL(DP), INTENT(IN) :: delta
    REAL(DP), INTENT(OUT) :: p(:)
    LOGICAL, INTENT(OUT) :: hit_boundary

    REAL(DP), ALLOCATABLE :: p_u(:), p_b(:)
    REAL(DP) :: norm_g, gBg, tau, a, coef_b, c, discriminant
    INTEGER(i4) :: n

    n = SIZE(g)
    ALLOCATE(p_u(n), p_b(n))
    hit_boundary = .FALSE.

    norm_g = SQRT(DOT_PRODUCT(g, g))
    gBg = DOT_PRODUCT(g, MATMUL(B, g))

    IF (gBg <= 0.0_DP) THEN
      tau = 1.0_DP
    ELSE
      tau = MIN(norm_g**3 / (delta * gBg), 1.0_DP)
    END IF

    p_u = -tau * delta / norm_g * g

    IF (tau < 1.0_DP) THEN
      p = p_u
      hit_boundary = .TRUE.
      RETURN
    END IF

    p_b = -MATMUL(g, B)
    IF (SQRT(DOT_PRODUCT(p_b, p_b)) <= delta) THEN
      p = p_b
      hit_boundary = .FALSE.
      RETURN
    END IF

    p_b = p_b - p_u
    a = DOT_PRODUCT(p_b, p_b)
    coef_b = 2.0_DP * DOT_PRODUCT(p_u, p_b)
    c = DOT_PRODUCT(p_u, p_u) - delta**2
    discriminant = coef_b**2 - 4.0_DP * a * c

    IF (discriminant >= 0.0_DP) THEN
      tau = (-coef_b + SQRT(discriminant)) / (2.0_DP * a)
      tau = MAX(0.0_DP, MIN(1.0_DP, tau))
    ELSE
      tau = 1.0_DP
    END IF

    p = p_u + tau * p_b
    hit_boundary = .TRUE.
    DEALLOCATE(p_u, p_b)
  END SUBROUTINE NM_TrustRegion_Dogleg

  SUBROUTINE NM_TrustRegion_Steihaug(g, B, delta, params, p, hit_boundary)
    REAL(DP), INTENT(IN) :: g(:)
    REAL(DP), INTENT(IN) :: B(:,:)
    REAL(DP), INTENT(IN) :: delta
    TYPE(TrustRegion_Params), INTENT(IN) :: params
    REAL(DP), INTENT(OUT) :: p(:)
    LOGICAL, INTENT(OUT) :: hit_boundary

    REAL(DP), ALLOCATABLE :: z(:), r(:), d(:), Bd(:)
    REAL(DP) :: norm_r, norm_r_old, alpha, beta, dBd, norm_d
    INTEGER(i4) :: n, iter

    n = SIZE(g)
    ALLOCATE(z(n), r(n), d(n), Bd(n))

    z = 0.0_DP
    r = -g
    d = r
    norm_r = SQRT(DOT_PRODUCT(r, r))
    hit_boundary = .FALSE.

    DO iter = 1, params%cg%max_cg_iter
      IF (norm_r < params%cg%cg_tol) EXIT

      Bd = MATMUL(B, d)
      dBd = DOT_PRODUCT(d, Bd)

      IF (dBd <= 0.0_DP) THEN
        CALL NM_Find_Boundary_Intersection(z, d, delta, p)
        hit_boundary = .TRUE.
        DEALLOCATE(z, r, d, Bd)
        RETURN
      END IF

      alpha = norm_r**2 / dBd
      norm_d = SQRT(DOT_PRODUCT(d, d))
      IF (SQRT(DOT_PRODUCT(z + alpha * d, z + alpha * d)) >= delta) THEN
        CALL NM_Find_Boundary_Intersection(z, d, delta, p)
        hit_boundary = .TRUE.
        DEALLOCATE(z, r, d, Bd)
        RETURN
      END IF

      z = z + alpha * d
      r = r - alpha * Bd
      norm_r_old = norm_r
      norm_r = SQRT(DOT_PRODUCT(r, r))
      beta = (norm_r / norm_r_old)**2
      d = r + beta * d
    END DO

    p = z
    DEALLOCATE(z, r, d, Bd)
  END SUBROUTINE NM_TrustRegion_Steihaug

  SUBROUTINE NM_TrustRegion_Update_Radius(rho, params, state)
    REAL(DP), INTENT(IN) :: rho
    TYPE(TrustRegion_Params), INTENT(IN) :: params
    TYPE(TrustRegion_State), INTENT(INOUT) :: state

    state%rho = rho
    IF (rho < params%eta%eta%eta1) THEN
      state%delta = params%gamma%gamma1 * state%delta
    ELSE IF (rho > params%eta%eta%eta2) THEN
      IF (state%hit_boundary) THEN
        state%delta = MIN(params%gamma%gamma2 * state%delta, params%delta%delta_max)
      END IF
    END IF
    state%delta = MAX(state%delta, params%delta%delta_min)
  END SUBROUTINE NM_TrustRegion_Update_Radius

END MODULE NM_Conv_LS