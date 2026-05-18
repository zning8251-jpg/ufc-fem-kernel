!===============================================================================
! MODULE: NM_Solv_QuasiNewton
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Proc (Quasi-Newton family: BFGS, DFP, SR1, L-BFGS, Broyden)
! BRIEF:  Quasi-Newton update methods for nonlinear iteration
!
! Theory: BFGS/DFP/SR1 secant updates; Ref: Nocedal&Wright(2006)
!
! Status: PROD | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_QuasiNewton
!> Status: Production | Last verified: 2026-03-01
!> Theory: Newton-Raphson method | Ref: Dennis&Schnabel(1996)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE NM_Conv_LS, ONLY: LineSearch_Params, LineSearch_Result, &
                                          NM_LineSearch, NM_Backtracking_LineSearch
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief  method 
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_BFGS = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_DFP = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_SR1 = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_BROYDEN = 4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_LBFGS = 5
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_PSR1 = 6

  !> @brief Initialize  
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_INIT_IDENTITY = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_INIT_SCALED = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_QN_INIT_FINITE_DIFF = 3

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief  
  TYPE, PUBLIC :: QuasiNewton_Params_Method
    INTEGER(i4) :: method = NM_QN_BFGS
    INTEGER(i4) :: initialization = NM_QN_INIT_SCALED
  END TYPE QuasiNewton_Params_Method

  TYPE, PUBLIC :: QuasiNewton_Params_Conv
    REAL(DP) :: tol = 1.0E-6_DP            !< convergence tolerance
    INTEGER(i4) :: max_iter = 1000_i4      !< max iterations
  END TYPE QuasiNewton_Params_Conv

  TYPE, PUBLIC :: QuasiNewton_Params_BFGS
    REAL(DP) :: skip_threshold = 1.0E-8_DP !<  
    LOGICAL :: damped = .TRUE.             !< dampingBFGS
    REAL(DP) :: damping_factor = 0.2_DP    !< damping 
  END TYPE QuasiNewton_Params_BFGS

  TYPE, PUBLIC :: QuasiNewton_Params_LBFGS
    INTEGER(i4) :: m = 10_i4               !< L-BFGS length
  END TYPE QuasiNewton_Params_LBFGS

  TYPE, PUBLIC :: QuasiNewton_Params
    TYPE(QuasiNewton_Params_Method) :: method
    TYPE(QuasiNewton_Params_Conv) :: conv
    TYPE(QuasiNewton_Params_BFGS) :: bfgs
    TYPE(QuasiNewton_Params_LBFGS) :: lbfgs
  END TYPE QuasiNewton_Params

  !> @brief  
  TYPE, PUBLIC :: QuasiNewton_State_Iter
    INTEGER(i4) :: iteration = 0_i4        !< current iteration
    LOGICAL :: converged = .FALSE.         !< converged
  END TYPE QuasiNewton_State_Iter

  TYPE, PUBLIC :: QuasiNewton_State_Vars
    REAL(DP), ALLOCATABLE :: x(:)          !<  
    REAL(DP) :: f = ZERO                   !<  
  END TYPE QuasiNewton_State_Vars

  TYPE, PUBLIC :: QuasiNewton_State_Grad
    REAL(DP), ALLOCATABLE :: g(:)          !<  
    REAL(DP) :: norm_g = ZERO              !<  
  END TYPE QuasiNewton_State_Grad

  TYPE, PUBLIC :: QuasiNewton_State_Step
    REAL(DP), ALLOCATABLE :: s(:)          !< step
    REAL(DP), ALLOCATABLE :: y(:)          !<  
    REAL(DP) :: alpha = ONE                !< step
  END TYPE QuasiNewton_State_Step

  TYPE, PUBLIC :: QuasiNewton_State
    TYPE(QuasiNewton_State_Iter) :: iter
    TYPE(QuasiNewton_State_Vars) :: vars
    TYPE(QuasiNewton_State_Grad) :: grad
    TYPE(QuasiNewton_State_Step) :: step
  END TYPE QuasiNewton_State

  !> @brief  
  TYPE, PUBLIC :: QuasiNewton_Result_Vars
    REAL(DP), ALLOCATABLE :: x(:)          !<  
    REAL(DP) :: f = ZERO                   !<  
  END TYPE QuasiNewton_Result_Vars

  TYPE, PUBLIC :: QuasiNewton_Result_Grad
    REAL(DP), ALLOCATABLE :: g(:)          !<  
  END TYPE QuasiNewton_Result_Grad

  TYPE, PUBLIC :: QuasiNewton_Result_Hessian
    REAL(DP), ALLOCATABLE :: H(:,:)        !<  Hessian
  END TYPE QuasiNewton_Result_Hessian

  TYPE, PUBLIC :: QuasiNewton_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4     !< iter count
    INTEGER(i4) :: n_func_evals = 0_i4     !<  value 
    INTEGER(i4) :: n_grad_evals = 0_i4     !<  value 
  END TYPE QuasiNewton_Result_Stats

  TYPE, PUBLIC :: QuasiNewton_Result_Status
    LOGICAL :: converged = .FALSE.         !< converged
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE QuasiNewton_Result_Status

  TYPE, PUBLIC :: QuasiNewton_Result
    TYPE(QuasiNewton_Result_Vars) :: vars
    TYPE(QuasiNewton_Result_Grad) :: grad
    TYPE(QuasiNewton_Result_Hessian) :: hessian
    TYPE(QuasiNewton_Result_Stats) :: stats
    TYPE(QuasiNewton_Result_Status) :: status
  END TYPE QuasiNewton_Result

  !> @brief L-BFGS 
  TYPE, PUBLIC :: LBFGS_Storage
    INTEGER(i4) :: m = 0_i4                !<  length
    INTEGER(i4) :: k = 0_i4                !< current iteration
    REAL(DP), ALLOCATABLE :: s_history(:,:) !< s 
    REAL(DP), ALLOCATABLE :: y_history(:,:) !< y 
    REAL(DP), ALLOCATABLE :: rho(:)         !< 1/(y^T·s)
  END TYPE LBFGS_Storage

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main solve interface
  PUBLIC :: NM_QuasiNewton_Solv
  PUBLIC :: NM_BFGS_Solv
  PUBLIC :: NM_DFP_Solv
  PUBLIC :: NM_SR1_Solv
  PUBLIC :: NM_LBFGS_Solv
  
  ! Hessian 
  PUBLIC :: NM_BFGS_Update
  PUBLIC :: NM_DFP_Update
  PUBLIC :: NM_SR1_Update
  PUBLIC :: NM_Broyden_Update
  
  ! L-BFGS 
  PUBLIC :: NM_LBFGS_Two_Loop_Recursion
  PUBLIC :: NM_LBFGS_Store
  PUBLIC :: NM_LBFGS_Init
  
  ! utils
  PUBLIC :: NM_QuasiNewton_Init
  PUBLIC :: NM_Calc_Search_Direction
  PUBLIC :: NM_Check_Curvature_Condition

CONTAINS

  !=============================================================================
  ! MAIN SOLVER INTERFACE
  !=============================================================================

  !> @brief  
  !! @details  param 
  !! @param[in] params  
  !! @param[in] x0 Initialize
  !! @param[in] Objective_proc  
  !! @param[in] Gradient_proc  
  !! @param[in] linesearch_params  
  !! @param[out] result  
  !! @param[out] status error status
  SUBROUTINE NM_QuasiNewton_Solv(params, x0, Objective_proc, Gradient_proc, &
                                   linesearch_params, result, status)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(LineSearch_Params), INTENT(IN) :: linesearch_params
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (params%lbfgs%method%method)
    CASE (NM_QN_BFGS)
      CALL NM_BFGS_Solv(params, x0, Objective_proc, Gradient_proc, &
                          linesearch_params, result, status)
    CASE (NM_QN_DFP)
      CALL NM_DFP_Solv(params, x0, Objective_proc, Gradient_proc, &
                         linesearch_params, result, status)
    CASE (NM_QN_SR1)
      CALL NM_SR1_Solv(params, x0, Objective_proc, Gradient_proc, &
                         linesearch_params, result, status)
    CASE (NM_QN_LBFGS)
      CALL NM_LBFGS_Solv(params, x0, Objective_proc, Gradient_proc, &
                           linesearch_params, result, status)
    CASE DEFAULT
      CALL NM_BFGS_Solv(params, x0, Objective_proc, Gradient_proc, &
                          linesearch_params, result, status)
    END SELECT

  END SUBROUTINE NM_QuasiNewton_Solv

  !> @brief BFGS 
  !! @details BFGS :
  !!   H_{k+1} = (I - ρ_k·s_k·y_k^T)·H_k·(I - ρ_k·y_k·s_k^T) + ρ_k·s_k·s_k^T
  !!     ρ_k = 1/(y_k^T·s_k)
  SUBROUTINE NM_BFGS_Solv(params, x0, Objective_proc, Gradient_proc, &
                            linesearch_params, result, status)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(LineSearch_Params), INTENT(IN) :: linesearch_params
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(QuasiNewton_State) :: state
    REAL(DP), ALLOCATABLE :: H(:,:), x_new(:), g_new(:), p(:)
    REAL(DP) :: f, f_new, ys, gamma
    INTEGER(i4) :: n, iter
    TYPE(LineSearch_Result) :: ls_result

    CALL init_error_status(status)

    n = SIZE(x0)
    ALLOCATE(H(n,n), x_new(n), g_new(n), p(n))

    ! Initialize
    CALL NM_QuasiNewton_Init(params, x0, Objective_proc, Gradient_proc, &
                                    state, H, result)
    f = result%vars%f

    !  
    DO iter = 1, params%conv%max_iter
      state%iter%iteration = iter
      state%grad%grad%norm_g = SQRT(SUM(state%grad%g**2))

      ! check convergence
      IF (state%grad%grad%norm_g < params%conv%tol) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF

      ! computation : p = -H·g
      p = -MATMUL(H, state%grad%g)

      !  
      CALL NM_LineSearch(linesearch_params, state%vars%x, p, f, DOT_PRODUCT(state%grad%g, p), &
                          Objective_proc, Gradient_proc, ls_result, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      state%step%step%alpha = ls_result%alpha
      f = ls_result%phi_alpha
      result%stats%n_func_evals = result%stats%n_func_evals + ls_result%stats%n_iterations

      ! update
      x_new = state%vars%x + state%step%step%alpha * p
      g_new = Gradient_proc(x_new)
      result%stats%n_grad_evals = result%stats%n_grad_evals + 1_i4

      ! computations y
      state%step%s = x_new - state%vars%x
      state%step%y = g_new - state%grad%g

      !  
      state%vars%x = x_new
      state%grad%g = g_new

      ! BFGS 
      ys = DOT_PRODUCT(state%step%y, state%step%s)
      IF (ys > params%bfgs%skip_threshold) THEN
        CALL NM_BFGS_Update(H, state%step%s, state%step%y, ys, params%bfgs%damped, &
                             params%bfgs%damping_factor)
      END IF
    END DO

    ! store result
    result%status%converged = state%iter%converged
    result%stats%n_iterations = state%iter%iteration
    IF (ALLOCATED(result%vars%x)) DEALLOCATE(result%vars%x)
    IF (ALLOCATED(result%grad%g)) DEALLOCATE(result%grad%g)
    IF (ALLOCATED(result%hessian%H)) DEALLOCATE(result%hessian%H)
    ALLOCATE(result%vars%x(n), result%grad%g(n), result%hessian%H(n,n))
    result%vars%x = state%vars%x
    result%vars%f = f
    result%grad%g = state%grad%g
    result%hessian%H = H

    DEALLOCATE(H, x_new, g_new, p)

  END SUBROUTINE NM_BFGS_Solv

  !> @brief DFP 
  !! @details DFP :
  !!   H_{k+1} = H_k - (H_k·y_k·y_k^T·H_k)/(y_k^T·H_k·y_k) + (s_k·s_k^T)/(y_k^T·s_k)
  SUBROUTINE NM_DFP_Solv(params, x0, Objective_proc, Gradient_proc, &
                           linesearch_params, result, status)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(LineSearch_Params), INTENT(IN) :: linesearch_params
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(QuasiNewton_State) :: state
    REAL(DP), ALLOCATABLE :: H(:,:), x_new(:), g_new(:), p(:)
    REAL(DP) :: f, ys
    INTEGER(i4) :: n, iter
    TYPE(LineSearch_Result) :: ls_result

    CALL init_error_status(status)

    n = SIZE(x0)
    ALLOCATE(H(n,n), x_new(n), g_new(n), p(n))

    CALL NM_QuasiNewton_Init(params, x0, Objective_proc, Gradient_proc, &
                                    state, H, result)
    f = result%vars%f

    DO iter = 1, params%conv%max_iter
      state%iter%iteration = iter
      state%grad%grad%norm_g = SQRT(SUM(state%grad%g**2))

      IF (state%grad%grad%norm_g < params%conv%tol) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF

      p = -MATMUL(H, state%grad%g)

      CALL NM_LineSearch(linesearch_params, state%vars%x, p, f, DOT_PRODUCT(state%grad%g, p), &
                          Objective_proc, Gradient_proc, ls_result, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      state%step%step%alpha = ls_result%alpha
      f = ls_result%phi_alpha

      x_new = state%vars%x + state%step%step%alpha * p
      g_new = Gradient_proc(x_new)

      state%step%s = x_new - state%vars%x
      state%step%y = g_new - state%grad%g

      state%vars%x = x_new
      state%grad%g = g_new

      ys = DOT_PRODUCT(state%step%y, state%step%s)
      IF (ys > params%bfgs%skip_threshold) THEN
        CALL NM_DFP_Update(H, state%step%s, state%step%y, ys)
      END IF
    END DO

    result%status%converged = state%iter%converged
    result%stats%n_iterations = state%iter%iteration
    IF (ALLOCATED(result%vars%x)) DEALLOCATE(result%vars%x)
    IF (ALLOCATED(result%grad%g)) DEALLOCATE(result%grad%g)
    IF (ALLOCATED(result%hessian%H)) DEALLOCATE(result%hessian%H)
    ALLOCATE(result%vars%x(n), result%grad%g(n), result%hessian%H(n,n))
    result%vars%x = state%vars%x
    result%vars%f = f
    result%grad%g = state%grad%g
    result%hessian%H = H

    DEALLOCATE(H, x_new, g_new, p)

  END SUBROUTINE NM_DFP_Solv

  !> @brief SR1 
  !! @details SR1 :
  !!   H_{k+1} = H_k + ((s_k - H_k·y_k)·(s_k - H_k·y_k)^T) / ((s_k - H_k·y_k)^T·y_k)
  SUBROUTINE NM_SR1_Solv(params, x0, Objective_proc, Gradient_proc, &
                           linesearch_params, result, status)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(LineSearch_Params), INTENT(IN) :: linesearch_params
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(QuasiNewton_State) :: state
    REAL(DP), ALLOCATABLE :: H(:,:), x_new(:), g_new(:), p(:)
    REAL(DP) :: f, ys
    INTEGER(i4) :: n, iter
    TYPE(LineSearch_Result) :: ls_result

    CALL init_error_status(status)

    n = SIZE(x0)
    ALLOCATE(H(n,n), x_new(n), g_new(n), p(n))

    CALL NM_QuasiNewton_Init(params, x0, Objective_proc, Gradient_proc, &
                                    state, H, result)
    f = result%vars%f

    DO iter = 1, params%conv%max_iter
      state%iter%iteration = iter
      state%grad%grad%norm_g = SQRT(SUM(state%grad%g**2))

      IF (state%grad%grad%norm_g < params%conv%tol) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF

      p = -MATMUL(H, state%grad%g)

      CALL NM_LineSearch(linesearch_params, state%vars%x, p, f, DOT_PRODUCT(state%grad%g, p), &
                          Objective_proc, Gradient_proc, ls_result, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      state%step%step%alpha = ls_result%alpha
      f = ls_result%phi_alpha

      x_new = state%vars%x + state%step%step%alpha * p
      g_new = Gradient_proc(x_new)

      state%step%s = x_new - state%vars%x
      state%step%y = g_new - state%grad%g

      state%vars%x = x_new
      state%grad%g = g_new

      ys = DOT_PRODUCT(state%step%y, state%step%s)
      IF (ABS(ys) > params%bfgs%skip_threshold) THEN
        CALL NM_SR1_Update(H, state%step%s, state%step%y)
      END IF
    END DO

    result%status%converged = state%iter%converged
    result%stats%n_iterations = state%iter%iteration
    IF (ALLOCATED(result%vars%x)) DEALLOCATE(result%vars%x)
    IF (ALLOCATED(result%grad%g)) DEALLOCATE(result%grad%g)
    IF (ALLOCATED(result%hessian%H)) DEALLOCATE(result%hessian%H)
    ALLOCATE(result%vars%x(n), result%grad%g(n), result%hessian%H(n,n))
    result%vars%x = state%vars%x
    result%vars%f = f
    result%grad%g = state%grad%g
    result%hessian%H = H

    DEALLOCATE(H, x_new, g_new, p)

  END SUBROUTINE NM_SR1_Solv

  !> @brief L-BFGS 
  !! @details BFGS ?Hmatrix
  SUBROUTINE NM_LBFGS_Solv(params, x0, Objective_proc, Gradient_proc, &
                             linesearch_params, result, status)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(LineSearch_Params), INTENT(IN) :: linesearch_params
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(QuasiNewton_State) :: state
    TYPE(LBFGS_Storage) :: lbfgs_store
    REAL(DP), ALLOCATABLE :: x_new(:), g_new(:), p(:)
    REAL(DP) :: f, ys, gamma
    INTEGER(i4) :: n, iter
    TYPE(LineSearch_Result) :: ls_result

    CALL init_error_status(status)

    n = SIZE(x0)
    ALLOCATE(x_new(n), g_new(n), p(n))

    ! Initialize L-BFGS 
    CALL NM_LBFGS_Init(params%lbfgs%m, n, lbfgs_store)

    ! Initialize state
    state%vars%x = x0
    state%grad%g = Gradient_proc(x0)
    f = Objective_proc(x0)
    result%stats%n_grad_evals = 1_i4
    result%stats%n_func_evals = 1_i4

    gamma = ONE  ! Initialize 

    DO iter = 1, params%conv%max_iter
      state%iter%iteration = iter
      state%grad%grad%norm_g = SQRT(SUM(state%grad%g**2))

      IF (state%grad%grad%norm_g < params%conv%tol) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF

      !  computation 
      CALL NM_LBFGS_Two_Loop_Recursion(lbfgs_store, state%grad%g, gamma, p)
      p = -p  !  

      !  
      CALL NM_LineSearch(linesearch_params, state%vars%x, p, f, DOT_PRODUCT(state%grad%g, p), &
                          Objective_proc, Gradient_proc, ls_result, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      state%step%step%alpha = ls_result%alpha
      f = ls_result%phi_alpha
      result%stats%n_func_evals = result%stats%n_func_evals + ls_result%stats%n_iterations

      ! update
      x_new = state%vars%x + state%step%step%alpha * p
      g_new = Gradient_proc(x_new)
      result%stats%n_grad_evals = result%stats%n_grad_evals + 1_i4

      ! computations y
      state%step%s = x_new - state%vars%x
      state%step%y = g_new - state%grad%g

      ys = DOT_PRODUCT(state%step%y, state%step%s)
      IF (ys > params%bfgs%skip_threshold) THEN
        !  L-BFGS 
        CALL NM_LBFGS_Store(lbfgs_store, state%step%s, state%step%y, ys)
        ! update 
        gamma = ys / DOT_PRODUCT(state%step%y, state%step%y)
      END IF

      state%vars%x = x_new
      state%grad%g = g_new
    END DO

    result%status%converged = state%iter%converged
    result%stats%n_iterations = state%iter%iteration
    IF (ALLOCATED(result%vars%x)) DEALLOCATE(result%vars%x)
    IF (ALLOCATED(result%grad%g)) DEALLOCATE(result%grad%g)
    ALLOCATE(result%vars%x(n), result%grad%g(n))
    result%vars%x = state%vars%x
    result%vars%f = f
    result%grad%g = state%grad%g

    DEALLOCATE(x_new, g_new, p)

  END SUBROUTINE NM_LBFGS_Solv

  !=============================================================================
  ! HESSIAN UPDATE FORMULAS
  !=============================================================================

  !> @brief BFGS 
  !! @param[inout] H  Hessian 
  !! @param[in] s displacementvector
  !! @param[in] y  
  !! @param[in] ys y^T·s
  !! @param[in] damped whether damping
  !! @param[in] damping_factor damping 
  SUBROUTINE NM_BFGS_Update(H, s, y, ys, damped, damping_factor)
    REAL(DP), INTENT(INOUT) :: H(:,:)
    REAL(DP), INTENT(IN) :: s(:), y(:), ys
    LOGICAL, INTENT(IN) :: damped
    REAL(DP), INTENT(IN) :: damping_factor

    REAL(DP), ALLOCATABLE :: Hy(:), V(:,:)
    REAL(DP) :: yHy, theta, r, rho
    INTEGER(i4) :: n

    n = SIZE(s)
    ALLOCATE(Hy(n), V(n,n))

    IF (damped) THEN
      ! dampingBFGS
      Hy = MATMUL(H, y)
      yHy = DOT_PRODUCT(y, Hy)
      theta = ONE
      IF (ys < damping_factor * yHy) THEN
        theta = (ONE - damping_factor) * yHy / (yHy - ys)
      END IF
      r = theta * ys + (ONE - theta) * yHy
    ELSE
      r = ys
    END IF

    IF (ABS(r) < 1.0E-14_DP) THEN
      DEALLOCATE(Hy, V)
      RETURN
    END IF

    rho = ONE / r
    Hy = MATMUL(H, y)

    ! H = (I - ρ·s·y^T)·H·(I - ρ·y·s^T) + ρ·s·s^T
    V = -rho * OUTER_PRODUCT(s, y)
    DO n = 1, SIZE(V, 1)
      V(n,n) = V(n,n) + ONE
    END DO

    H = MATMUL(MATMUL(V, H), TRANSPOSE(V)) + rho * OUTER_PRODUCT(s, s)

    DEALLOCATE(Hy, V)

  END SUBROUTINE NM_BFGS_Update

  !> @brief DFP 
  SUBROUTINE NM_DFP_Update(H, s, y, ys)
    REAL(DP), INTENT(INOUT) :: H(:,:)
    REAL(DP), INTENT(IN) :: s(:), y(:), ys

    REAL(DP), ALLOCATABLE :: Hy(:)
    REAL(DP) :: yHy

    ALLOCATE(Hy(SIZE(s)))

    Hy = MATMUL(H, y)
    yHy = DOT_PRODUCT(y, Hy)

    IF (ABS(ys) > 1.0E-14_DP .AND. ABS(yHy) > 1.0E-14_DP) THEN
      H = H - OUTER_PRODUCT(Hy, Hy) / yHy + OUTER_PRODUCT(s, s) / ys
    END IF

    DEALLOCATE(Hy)

  END SUBROUTINE NM_DFP_Update

  !> @brief SR1 
  SUBROUTINE NM_SR1_Update(H, s, y)
    REAL(DP), INTENT(INOUT) :: H(:,:)
    REAL(DP), INTENT(IN) :: s(:), y(:)

    REAL(DP), ALLOCATABLE :: r(:)
    REAL(DP) :: r_y

    ALLOCATE(r(SIZE(s)))

    r = s - MATMUL(H, y)
    r_y = DOT_PRODUCT(r, y)

    IF (ABS(r_y) > 1.0E-8_DP) THEN
      H = H + OUTER_PRODUCT(r, r) / r_y
    END IF

    DEALLOCATE(r)

  END SUBROUTINE NM_SR1_Update

  !> @brief Broyden 
  SUBROUTINE NM_Broyden_Update(H, s, y, ys, phi)
    REAL(DP), INTENT(INOUT) :: H(:,:)
    REAL(DP), INTENT(IN) :: s(:), y(:), ys, phi

    REAL(DP), ALLOCATABLE :: H_temp(:,:)

    ALLOCATE(H_temp(SIZE(H,1), SIZE(H,2)))

    ! Broyden H = (1-φ)·H_BFGS + φ·H_DFP
    H_temp = H
    CALL NM_BFGS_Update(H_temp, s, y, ys, .FALSE., ZERO)
    H = H_temp

    DEALLOCATE(H_temp)

  END SUBROUTINE NM_Broyden_Update

  !=============================================================================
  ! L-BFGS OPERATIONS
  !=============================================================================

  !> @brief Initialize L-BFGS 
  SUBROUTINE NM_LBFGS_Init(m, n, storage)
    INTEGER(i4), INTENT(IN) :: m, n
    TYPE(LBFGS_Storage), INTENT(OUT) :: storage

    storage%m = m
    storage%k = 0_i4

    IF (ALLOCATED(storage%s_history)) DEALLOCATE(storage%s_history)
    IF (ALLOCATED(storage%y_history)) DEALLOCATE(storage%y_history)
    IF (ALLOCATED(storage%rho)) DEALLOCATE(storage%rho)

    ALLOCATE(storage%s_history(n, m))
    ALLOCATE(storage%y_history(n, m))
    ALLOCATE(storage%rho(m))

    storage%s_history = ZERO
    storage%y_history = ZERO
    storage%rho = ZERO

  END SUBROUTINE NM_LBFGS_Init

  !> @brief  s y L-BFGS 
  SUBROUTINE NM_LBFGS_Store(storage, s, y, ys)
    TYPE(LBFGS_Storage), INTENT(INOUT) :: storage
    REAL(DP), INTENT(IN) :: s(:), y(:), ys

    INTEGER(i4) :: idx

    storage%k = storage%k + 1_i4
    idx = MOD(storage%k - 1_i4, storage%m) + 1_i4

    storage%s_history(:, idx) = s
    storage%y_history(:, idx) = y
    storage%rho(idx) = ONE / ys

  END SUBROUTINE NM_LBFGS_Store

  !> @brief L-BFGS 
  !! @details computation q = H·g  H
  SUBROUTINE NM_LBFGS_Two_Loop_Recursion(storage, g, gamma, q)
    TYPE(LBFGS_Storage), INTENT(IN) :: storage
    REAL(DP), INTENT(IN) :: g(:), gamma
    REAL(DP), INTENT(OUT) :: q(:)

    REAL(DP), ALLOCATABLE :: alpha(:), r(:)
    INTEGER(i4) :: m_eff, i, idx
    REAL(DP) :: beta

    m_eff = MIN(storage%k, storage%m)
    ALLOCATE(alpha(m_eff), r(SIZE(g)))

    q = g

    !  See module header / UFC docs for context.
    DO i = m_eff, 1, -1
      idx = MOD(storage%k - m_eff + i - 1_i4, storage%m) + 1_i4
      alpha(i) = storage%rho(idx) * DOT_PRODUCT(storage%s_history(:, idx), q)
      q = q - alpha(i) * storage%y_history(:, idx)
    END DO

    ! InitializeHessian ?unitmatrix ?
    q = gamma * q

    !  See module header / UFC docs for context.
    DO i = 1, m_eff
      idx = MOD(storage%k - m_eff + i - 1_i4, storage%m) + 1_i4
      beta = storage%rho(idx) * DOT_PRODUCT(storage%y_history(:, idx), q)
      q = q + (alpha(i) - beta) * storage%s_history(:, idx)
    END DO

    DEALLOCATE(alpha, r)

  END SUBROUTINE NM_LBFGS_Two_Loop_Recursion

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief Initialize  
  SUBROUTINE NM_QuasiNewton_Init(params, x0, Objective_proc, Gradient_proc, &
                                        state, H, result)
    TYPE(QuasiNewton_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: x0(:)
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
    TYPE(QuasiNewton_State), INTENT(OUT) :: state
    REAL(DP), INTENT(OUT) :: H(:,:)
    TYPE(QuasiNewton_Result), INTENT(OUT) :: result

    INTEGER(i4) :: n
    REAL(DP) :: gamma

    n = SIZE(x0)

    ! Initialize state
    state%iter%iteration = 0_i4
    state%iter%converged = .FALSE.
    IF (ALLOCATED(state%vars%x)) DEALLOCATE(state%vars%x)
    IF (ALLOCATED(state%grad%g)) DEALLOCATE(state%grad%g)
    IF (ALLOCATED(state%step%s)) DEALLOCATE(state%step%s)
    IF (ALLOCATED(state%step%y)) DEALLOCATE(state%step%y)
    ALLOCATE(state%vars%x(n), state%grad%g(n), state%step%s(n), state%step%y(n))

    state%vars%x = x0
    state%grad%g = Gradient_proc(x0)
    state%vars%f = Objective_proc(x0)

    ! Initialize H
    H = ZERO

    SELECT CASE (params%lbfgs%method%method%initialization)
    CASE (NM_QN_INIT_IDENTITY)
      gamma = ONE
    CASE (NM_QN_INIT_SCALED)
      !  
      gamma = ONE / SQRT(SUM(state%grad%g**2))
      IF (gamma < 1.0E-10_DP) gamma = ONE
    CASE DEFAULT
      gamma = ONE
    END SELECT

    DO n = 1, SIZE(H, 1)
      H(n,n) = gamma
    END DO

    ! Initialize  
    result%stats%n_iterations = 0_i4
    result%stats%n_func_evals = 1_i4
    result%stats%n_grad_evals = 1_i4
    result%status%converged = .FALSE.
    result%vars%f = state%vars%f

  END SUBROUTINE NM_QuasiNewton_Init

  !> @brief computation 
  FUNCTION NM_Calc_Search_Direction(H, g) RESULT(p)
    REAL(DP), INTENT(IN) :: H(:,:), g(:)
    REAL(DP) :: p(SIZE(g))

    p = -MATMUL(H, g)

  END FUNCTION NM_Calc_Search_Direction

  !> @brief check 
  FUNCTION NM_Check_Curvature_Condition(s, y, tol) RESULT(satisfied)
    REAL(DP), INTENT(IN) :: s(:), y(:), tol
    LOGICAL :: satisfied

    satisfied = (DOT_PRODUCT(y, s) > tol)

  END FUNCTION NM_Check_Curvature_Condition

  !> @brief  
  FUNCTION OUTER_PRODUCT(a, b) RESULT(C)
    REAL(DP), INTENT(IN) :: a(:), b(:)
    REAL(DP) :: C(SIZE(a), SIZE(b))

    INTEGER(i4) :: i, j

    DO j = 1, SIZE(b)
      DO i = 1, SIZE(a)
        C(i,j) = a(i) * b(j)
      END DO
    END DO

  END FUNCTION OUTER_PRODUCT

END MODULE NM_Solv_QuasiNewton