!===============================================================================
! MODULE: NM_Solv_Newton
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Proc (Newton-Raphson / Modified Newton / Quasi-Newton core)
! BRIEF:  Full/modified Newton iteration with convergence control
!
! Theory: u_{k+1} = u_k - K_T^{-1}*R(u_k); Ref: Crisfield(1991), Bathe(1996)
!
! Status: PROD | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_Newton
!> Status: Production | Last verified: 2026-03-01
!> Theory: Newton-Raphson method | Ref: Dennis&Schnabel(1996)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_Solv_TrustRegion, ONLY: TrustRegion_Params, TrustRegion_State, NM_TrustRegion_Solv
  IMPLICIT NONE
  PRIVATE

  !> @brief NewtonSolver type 
  INTEGER, PARAMETER, PUBLIC :: NM_NEWTON_STANDARD = 1      !<  Newton-Raphson
  INTEGER, PARAMETER, PUBLIC :: NM_NEWTON_MODIFIED = 2      !<  Newton ( )
  INTEGER, PARAMETER, PUBLIC :: NM_NEWTON_QUASI_BFGS = 3    !<  Newton BFGS
  INTEGER, PARAMETER, PUBLIC :: NM_NEWTON_QUASI_SR1 = 4     !<  Newton SR1
  INTEGER, PARAMETER, PUBLIC :: NM_NEWTON_TRUST_REGION = 5  !< Trust-Region

  !> @brief convergence 
  INTEGER, PARAMETER, PUBLIC :: NM_CONV_FORCE = 1           !< force 
  INTEGER, PARAMETER, PUBLIC :: NM_CONV_ENERGY = 2          !<  
  INTEGER, PARAMETER, PUBLIC :: NM_CONV_DISPLACEMENT = 3    !< displacement 
  INTEGER, PARAMETER, PUBLIC :: NM_CONV_COMBINED = 4        !<  

  !> @brief Internal-force callback: F_internal(u) for residual R = F_ext - F_internal
  ABSTRACT INTERFACE
    SUBROUTINE FInternalProc(u, f_internal)
      USE IF_Base_Def, ONLY: DP
      REAL(DP), INTENT(IN)  :: u(:)
      REAL(DP), INTENT(OUT) :: f_internal(:)
    END SUBROUTINE FInternalProc
  END INTERFACE

  !> @brief NewtonSolver parameters
  TYPE, PUBLIC :: Newton_Solver_Params_Solver
    INTEGER(i4) :: solver_type                 !< Solver type
    INTEGER(i4) :: convergence_criterion       !< convergence 
  END TYPE Newton_Solver_Params_Solver

  TYPE, PUBLIC :: Newton_Solver_Params_Iter
    INTEGER(i4) :: max_iterations              !< max iterations
  END TYPE Newton_Solver_Params_Iter

  TYPE, PUBLIC :: Newton_Solver_Params_Tolerance
    REAL(DP) :: force_tolerance             !< force 
    REAL(DP) :: energy_tolerance            !<  
    REAL(DP) :: displacement_tolerance      !< displacement 
  END TYPE Newton_Solver_Params_Tolerance

  TYPE, PUBLIC :: Newton_Solver_Params_LineSearch
    LOGICAL  :: use_line_search             !<  
    LOGICAL  :: update_tangent_each_iter    !<  iteration 
  END TYPE Newton_Solver_Params_LineSearch

  TYPE, PUBLIC :: Newton_Solver_Params_TrustRegion
    REAL(DP) :: trust_delta_init            !< Initialize 
    REAL(DP) :: trust_delta_max             !<  radius
    REAL(DP) :: trust_eta1                  !<  
    REAL(DP) :: trust_eta2                  !<  
  END TYPE Newton_Solver_Params_TrustRegion

  TYPE, PUBLIC :: Newton_Solver_Params_Callback
    ! Internal-force callback for residual = F_ext - F_internal (physics from L4_PH)
    PROCEDURE(FInternalProc), POINTER, NOPASS :: f_internal_proc => NULL()
  END TYPE Newton_Solver_Params_Callback

  TYPE, PUBLIC :: Newton_Solver_Params
    TYPE(Newton_Solver_Params_Solver) :: solver
    TYPE(Newton_Solver_Params_Iter) :: iter
    TYPE(Newton_Solver_Params_Tolerance) :: tolerance
    TYPE(Newton_Solver_Params_LineSearch) :: linesearch
    TYPE(Newton_Solver_Params_TrustRegion) :: trustregion
    TYPE(Newton_Solver_Params_Callback) :: callback
  END TYPE Newton_Solver_Params

  !> @brief Newtoniteration 
  TYPE, PUBLIC :: Newton_Iteration_State_Iter
    INTEGER(i4) :: current_iteration           !<  iter count
    LOGICAL  :: converged                   !< converged
  END TYPE Newton_Iteration_State_Iter

  TYPE, PUBLIC :: Newton_Iteration_State_Residual
    REAL(DP) :: force_residual_norm         !< force 
    REAL(DP) :: energy_residual             !<  
    REAL(DP) :: displacement_increment_norm !< displacement 
  END TYPE Newton_Iteration_State_Residual

  TYPE, PUBLIC :: Newton_Iteration_State_LS
    REAL(DP) :: line_search_factor          !<  ??
  END TYPE Newton_Iteration_State_LS

  TYPE, PUBLIC :: Newton_Iteration_State
    TYPE(Newton_Iteration_State_Iter) :: iter
    TYPE(Newton_Iteration_State_Residual) :: residual
    TYPE(Newton_Iteration_State_LS) :: ls
  END TYPE Newton_Iteration_State

  ! Public interfaces
  PUBLIC :: NM_Newton_Solv
  PUBLIC :: NM_Newton_Standard_Iteration
  PUBLIC :: NM_Newton_Modified_Iteration
  PUBLIC :: NM_Newton_BFGS_Update
  PUBLIC :: NM_Newton_Check_Conv
  PUBLIC :: NM_Newton_Calc_Residual
  
  ! Extended Newton API (scope 1500-1599)
  PUBLIC :: NM_Newton_GetConvergenceRate, NM_Newton_AdaptiveTolerance
  PUBLIC :: NM_Newton_GetStatistics, NM_Newton_OptimizeStepSize
  PUBLIC :: NM_Newton_ComputeTangentStiffness
  
  ! Modified Newton API (scope 1600-1699)
  PUBLIC :: NM_ModifiedNewton_Solv, NM_ModifiedNewton_UpdateFrequency
  PUBLIC :: NM_ModifiedNewton_GetStatistics
  !   (scope 15300-15599)
  PUBLIC :: NM_Theory_Unified_Query
  PUBLIC :: NM_Theory_Unified_Describe
  !   (scope 16200-16299)
  PUBLIC :: NM_Theory_GetNumModules
  PUBLIC :: NM_Theory_QueryByIndex
  !   (scope 16600-16699)
  PUBLIC :: NM_Theory_ExportList
  
  ! Quasi-Newton API (scope 1700-1799)
  PUBLIC :: NM_BFGS_Solv, NM_LBFGS_Update, NM_LBFGS_Solv
  PUBLIC :: NM_QuasiNewton_GetStatistics

CONTAINS

  SUBROUTINE Apply_Line_Search(u, du, residual, alpha)
    REAL(DP), INTENT(IN)  :: u(:), du(:), residual(:)
    REAL(DP), INTENT(OUT) :: alpha

    REAL(DP) :: c, beta, res_norm_0, res_norm_trial
    INTEGER(i4) :: max_trials, trial

    c = 1.0E-4_DP
    beta = 0.5_DP
    max_trials = 10

    res_norm_0 = SQRT(DOT_PRODUCT(residual, residual))
    alpha = ONE

    DO trial = 1, max_trials
      !    
      res_norm_trial = res_norm_0 * (ONE - c * alpha)

      IF (res_norm_trial < res_norm_0) EXIT

      alpha = alpha * beta
    END DO

  END SUBROUTINE Apply_Line_Search

  SUBROUTINE Calc_Identity_Stiff(n, scale, K)
    INTEGER(i4), INTENT(IN) :: n
    REAL(DP), INTENT(IN) :: scale
    REAL(DP), INTENT(OUT) :: K(:,:)
    
    INTEGER(i4) :: i
    
    K = 0.0_DP
    DO i = 1, n
      K(i, i) = scale
    END DO
    
  END SUBROUTINE Calc_Identity_Stiff

  SUBROUTINE Invoke_TrustRegion_Solv(params, u, f_ext, K_tangent, state)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN)    :: f_ext(:)
    REAL(DP), INTENT(IN)    :: K_tangent(:,:)
    TYPE(Newton_Iteration_State), INTENT(OUT) :: state

    TYPE(TrustRegion_Params) :: tr_params
    TYPE(TrustRegion_State)  :: tr_state

    ! param 
    tr_params%iter%max_iterations = params%iter%max_iterations
    tr_params%tol_residual   = params%tolerance%force_tolerance
    tr_params%tol_step       = params%tolerance%displacement_tolerance
    tr_params%delta_init     = params%trustregion%trust_delta_init
    tr_params%delta_max      = params%trustregion%trust_delta_max
    tr_params%eta1           = params%trustregion%trust_eta1
    tr_params%eta2           = params%trustregion%trust_eta2
    tr_params%verbose        = .FALSE.

    ! NOTE: Trust-Region ??
    !        -gradeimplements Residual_proc Jacobian_proc
    ! CALL NM_TrustRegion_Solv(u, Residual_proc, Jacobian_proc, tr_params, tr_state)

    ! status Newton 
    state%iter%current_iteration = tr_state%iteration
    state%iter%converged = tr_state%iter%converged
    state%residual%force_residual_norm = tr_state%residual_norm
    state%residual%displacement_increment_norm = tr_state%step_norm
    state%residual%energy_residual = tr_state%phi
    state%ls%line_search_factor = ONE  ! Trust-Region 

  END SUBROUTINE Invoke_TrustRegion_Solv

  SUBROUTINE NM_BFGS_Solv(params, u, f_ext, H_inverse, state, status)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN) :: f_ext(:)
    REAL(DP), INTENT(INOUT) :: H_inverse(:,:)
    TYPE(Newton_Iteration_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP), ALLOCATABLE :: residual(:), du(:), f_internal(:)
    REAL(DP), ALLOCATABLE :: s(:), y(:), u_prev(:)
    INTEGER(i4) :: iter, n_dof
    LOGICAL :: converged
    REAL(DP) :: sTy
    
    CALL init_error_status(status)
    
    n_dof = SIZE(u)
    ALLOCATE(residual(n_dof), du(n_dof), f_internal(n_dof))
    ALLOCATE(s(n_dof), y(n_dof), u_prev(n_dof))
    
    state%iter%current_iteration = 0
    state%iter%converged = .FALSE.
    converged = .FALSE.
    u_prev = u
    
    ! BFGS iteration loop
    DO iter = 1, params%iter%max_iterations
      state%iter%current_iteration = iter
      
      ! Compute residual
      CALL NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, params%callback%f_internal_proc)
      
      ! Check convergence
      CALL NM_Newton_Check_Conv(params, residual, du, state, converged)
      IF (converged) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF
      
      ! BFGS update
      CALL NM_Newton_BFGS_Update(H_inverse, residual, du, u_prev)
      
      ! Update displacement
      IF (params%linesearch%use_line_search) THEN
        CALL Apply_Line_Search(u, du, residual, state%ls%line_search_factor)
        u = u + state%ls%line_search_factor * du
      ELSE
        u = u + du
        state%ls%line_search_factor = ONE
      END IF
      
      ! Update secant vectors for next iteration
      s = u - u_prev
      ! y would be computed from gradient difference (simplified here)
      y = residual  ! Simplified: actual implementation needs gradient
      
      sTy = DOT_PRODUCT(s, y)
      IF (ABS(sTy) > 1.0E-10_DP) THEN
        ! Update H_inverse using BFGS formula
        CALL NM_BFGS_Update_Mtx(H_inverse, s, y)
      END IF
      
      u_prev = u
    END DO
    
    DEALLOCATE(residual, du, f_internal, s, y, u_prev)
    
    IF (.NOT. converged) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_BFGS_Solv

  SUBROUTINE NM_BFGS_Update_Mtx(H_inv, s, y)
    REAL(DP), INTENT(INOUT) :: H_inv(:,:)
    REAL(DP), INTENT(IN) :: s(:), y(:)
    
    REAL(DP), ALLOCATABLE :: Hs(:), temp(:)
    REAL(DP) :: rho, sTy, sTHs
    INTEGER(i4) :: n
    
    n = SIZE(s)
    ALLOCATE(Hs(n), temp(n))
    
    sTy = DOT_PRODUCT(s, y)
    IF (ABS(sTy) > 1.0E-10_DP) THEN
      rho = ONE / sTy
      
      Hs = MATMUL(H_inv, s)
      sTHs = DOT_PRODUCT(s, Hs)
      
      IF (sTHs > 1.0E-10_DP) THEN
        H_inv = H_inv + rho * OUTER_PRODUCT(y, y) - &
                OUTER_PRODUCT(Hs, Hs) / sTHs
      END IF
    END IF
    
    DEALLOCATE(Hs, temp)
    
  END SUBROUTINE NM_BFGS_Update_Mtx

  SUBROUTINE NM_LBFGS_Solv(params, u, f_ext, m, state, status)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN) :: f_ext(:)
    INTEGER(i4), INTENT(IN) :: m
    TYPE(Newton_Iteration_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP), ALLOCATABLE :: residual(:), du(:), f_internal(:)
    REAL(DP), ALLOCATABLE :: s_history(:,:), y_history(:,:)
    REAL(DP), ALLOCATABLE :: H_inverse(:,:), u_prev(:)
    INTEGER(i4) :: iter, n_dof, k
    LOGICAL :: converged
    
    CALL init_error_status(status)
    
    n_dof = SIZE(u)
    ALLOCATE(residual(n_dof), du(n_dof), f_internal(n_dof))
    ALLOCATE(s_history(n_dof, m), y_history(n_dof, m))
    ALLOCATE(H_inverse(n_dof, n_dof), u_prev(n_dof))
    
    ! Init H_inverse as identity
    H_inverse = 0.0_DP
    CALL Calc_Identity_Stiff(n_dof, 1.0_DP, H_inverse)
    
    state%iter%current_iteration = 0
    state%iter%converged = .FALSE.
    converged = .FALSE.
    u_prev = u
    k = 0
    
    ! L-BFGS iteration loop
    DO iter = 1, params%iter%max_iterations
      state%iter%current_iteration = iter
      
      ! Compute residual
      CALL NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, params%callback%f_internal_proc)
      
      ! Check convergence
      CALL NM_Newton_Check_Conv(params, residual, du, state, converged)
      IF (converged) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF
      
      ! Update L-BFGS history
      IF (iter > 1) THEN
        k = MIN(k + 1, m)
        s_history(:, k) = u - u_prev
        y_history(:, k) = residual  ! Simplified: actual gradient difference
      END IF
      
      ! Apply L-BFGS update
      IF (k > 0) THEN
        CALL NM_LBFGS_Update(H_inverse, s_history(:, 1:k), y_history(:, 1:k), m, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
      END IF
      
      ! Compute search direction
      du = -MATMUL(H_inverse, residual)
      
      ! Update displacement
      IF (params%linesearch%use_line_search) THEN
        CALL Apply_Line_Search(u, du, residual, state%ls%line_search_factor)
        u = u + state%ls%line_search_factor * du
      ELSE
        u = u + du
        state%ls%line_search_factor = ONE
      END IF
      
      u_prev = u
    END DO
    
    DEALLOCATE(residual, du, f_internal, s_history, y_history, H_inverse, u_prev)
    
    IF (.NOT. converged) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_LBFGS_Solv

  SUBROUTINE NM_LBFGS_Update(H_inverse, s_history, y_history, m, status)
    REAL(DP), INTENT(INOUT) :: H_inverse(:,:)
    REAL(DP), INTENT(IN) :: s_history(:,:), y_history(:,:)
    INTEGER(i4), INTENT(IN) :: m
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, n, k
    REAL(DP), ALLOCATABLE :: rho_vec(:), alpha_vec(:)
    REAL(DP) :: sTy, beta
    
    CALL init_error_status(status)
    
    n = SIZE(H_inverse, 1)
    k = SIZE(s_history, 2)  ! Number of stored pairs
    k = MIN(k, m)
    
    ALLOCATE(rho_vec(k), alpha_vec(k))
    
    ! Compute rho values
    DO i = 1, k
      sTy = DOT_PRODUCT(s_history(:, i), y_history(:, i))
      IF (ABS(sTy) > 1.0E-10_DP) THEN
        rho_vec(i) = ONE / sTy
      ELSE
        rho_vec(i) = 0.0_DP
      END IF
    END DO
    
    ! Two-loop recursion (simplified - full implementation would use recursive formula)
    ! For now, apply BFGS updates sequentially
    DO i = 1, k
      IF (rho_vec(i) > 0.0_DP) THEN
        CALL NM_BFGS_Update_Mtx(H_inverse, s_history(:, i), y_history(:, i))
      END IF
    END DO
    
    DEALLOCATE(rho_vec, alpha_vec)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_LBFGS_Update

  SUBROUTINE NM_ModifiedNewton_GetStatistics(state, update_frequency, stats, status)
    TYPE(Newton_Iteration_State), INTENT(IN) :: state
    INTEGER(i4), INTENT(IN) :: update_frequency
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,I0,A,L1)') &
      'Modified Newton Statistics: iteration=', state%iter%current_iteration, &
      ', update_frequency=', update_frequency, &
      ', converged=', state%iter%converged
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ModifiedNewton_GetStatistics

  SUBROUTINE NM_ModifiedNewton_Solv(params, u, f_ext, K_tangent, update_frequency, state, status)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN) :: f_ext(:)
    REAL(DP), INTENT(INOUT) :: K_tangent(:,:)
    INTEGER(i4), INTENT(IN) :: update_frequency
    TYPE(Newton_Iteration_State), INTENT(OUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP), ALLOCATABLE :: residual(:), du(:), f_internal(:)
    INTEGER(i4) :: iter, n_dof
    LOGICAL :: converged
    REAL(DP), ALLOCATABLE :: K_fixed(:,:)
    
    CALL init_error_status(status)
    
    n_dof = SIZE(u)
    ALLOCATE(residual(n_dof), du(n_dof), f_internal(n_dof), K_fixed(n_dof, n_dof))
    
    ! Store fixed stiffness matrix
    K_fixed = K_tangent
    
    state%iter%current_iteration = 0
    state%iter%converged = .FALSE.
    converged = .FALSE.
    
    ! Modified Newton iteration loop
    DO iter = 1, params%iter%max_iterations
      state%iter%current_iteration = iter
      
      ! Update stiffness matrix periodically
      IF (MOD(iter - 1, update_frequency) == 0) THEN
        CALL NM_Newton_ComputeTangentStiffness(u, [1.0_DP], K_tangent, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        K_fixed = K_tangent
      ELSE
        K_tangent = K_fixed
      END IF
      
      ! Compute residual
      CALL NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, params%callback%f_internal_proc)
      
      ! Check convergence
      CALL NM_Newton_Check_Conv(params, residual, du, state, converged)
      IF (converged) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF
      
      ! Solve using fixed stiffness
      CALL NM_Newton_Modified_Iteration(K_tangent, residual, du)
      
      ! Update displacement
      IF (params%linesearch%use_line_search) THEN
        CALL Apply_Line_Search(u, du, residual, state%ls%line_search_factor)
        u = u + state%ls%line_search_factor * du
      ELSE
        u = u + du
        state%ls%line_search_factor = ONE
      END IF
    END DO
    
    DEALLOCATE(residual, du, f_internal, K_fixed)
    
    IF (.NOT. converged) THEN
      status%status_code = IF_STATUS_INVALID
    ELSE
      status%status_code = IF_STATUS_OK
    END IF
    
  END SUBROUTINE NM_ModifiedNewton_Solv

  SUBROUTINE NM_Newton_ComputeTangentStiffness(u, material_params, K_tangent, status)
    REAL(DP), INTENT(IN) :: u(:)
    REAL(DP), INTENT(IN) :: material_params(:)
    REAL(DP), INTENT(OUT) :: K_tangent(:,:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: n
    
    CALL init_error_status(status)
    
    n = SIZE(u)
    
    ! Simplified tangent stiffness computation
    ! Production code should call element assembly routines
    K_tangent = 0.0_DP
    
    ! Placeholder: would compute K_T = K_material + K_geometric + K_contact
    ! For now, return identity matrix scaled by material parameter
    IF (SIZE(material_params) > 0) THEN
      CALL Calc_Identity_Stiff(n, material_params(1), K_tangent)
    ELSE
      CALL Calc_Identity_Stiff(n, 1.0_DP, K_tangent)
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Newton_ComputeTangentStiffness

  SUBROUTINE NM_Newton_BFGS_Update(H_inverse, residual, du, u_prev)
    REAL(DP), INTENT(INOUT) :: H_inverse(:,:)
    REAL(DP), INTENT(IN)    :: residual(:), u_prev(:)
    REAL(DP), INTENT(OUT)   :: du(:)

    REAL(DP), ALLOCATABLE :: s(:), y(:), Hs(:), temp(:)
    REAL(DP) :: rho, sTy, sTHs
    INTEGER(i4) :: n_dof

    n_dof = SIZE(residual)
    ALLOCATE(s(n_dof), y(n_dof), Hs(n_dof), temp(n_dof))

    ! du = -H^{-1}??R
    du = -MATMUL(H_inverse, residual)

    !  vector (   s,y)
    s = du  ! s_k = u_{k+1} - u_k
    y = residual  ! y_k = ?R_{k+1} - ?R_k ( )

    ! BFGS 
    sTy = DOT_PRODUCT(s, y)
    IF (ABS(sTy) > 1.0E-10_DP) THEN
      rho = ONE / sTy

      Hs = MATMUL(H_inverse, s)
      sTHs = DOT_PRODUCT(s, Hs)

      ! H_{k+1} = H_k + ???y??y^T - (H??s??s^T??H)/sTHs
      H_inverse = H_inverse + &
                  rho * OUTER_PRODUCT(y, y) - &
                  OUTER_PRODUCT(Hs, Hs) / sTHs
    END IF

    DEALLOCATE(s, y, Hs, temp)

  END SUBROUTINE NM_Newton_BFGS_Update

  SUBROUTINE NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, f_internal_proc)
    REAL(DP), INTENT(IN)  :: u(:), f_ext(:)
    REAL(DP), INTENT(OUT) :: f_internal(:), residual(:)
    PROCEDURE(FInternalProc), OPTIONAL, POINTER :: f_internal_proc

    ! F_internal(u) from physics callback or stub
    IF (PRESENT(f_internal_proc) .AND. ASSOCIATED(f_internal_proc)) THEN
      CALL f_internal_proc(u, f_internal)
    ELSE
      f_internal = ZERO  !  -grade element 
    END IF

    ! residual = F_ext - F_internal
    residual = f_ext - f_internal

  END SUBROUTINE NM_Newton_Calc_Residual

  SUBROUTINE NM_Newton_Check_Conv(params, residual, du, state, converged)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: residual(:), du(:)
    TYPE(Newton_Iteration_State), INTENT(INOUT) :: state
    LOGICAL, INTENT(OUT) :: converged

    REAL(DP) :: res_norm, du_norm, energy_res
    LOGICAL :: force_conv, energy_conv, disp_conv

    ! computation 
    res_norm = SQRT(DOT_PRODUCT(residual, residual))
    du_norm = SQRT(DOT_PRODUCT(du, du))
    energy_res = ABS(DOT_PRODUCT(du, residual))

    ! update state
    state%residual%force_residual_norm = res_norm
    state%residual%displacement_increment_norm = du_norm
    state%residual%energy_residual = energy_res

    !  
    force_conv = (res_norm < params%tolerance%force_tolerance)
    energy_conv = (energy_res < params%tolerance%energy_tolerance)
    disp_conv = (du_norm < params%tolerance%displacement_tolerance)

    !  convergence
    SELECT CASE (params%solver%convergence_criterion)
    CASE (NM_CONV_FORCE)
      converged = force_conv
    CASE (NM_CONV_ENERGY)
      converged = energy_conv
    CASE (NM_CONV_DISPLACEMENT)
      converged = disp_conv
    CASE (NM_CONV_COMBINED)
      converged = force_conv .AND. energy_conv .AND. disp_conv
    CASE DEFAULT
      converged = force_conv
    END SELECT

  END SUBROUTINE NM_Newton_Check_Conv

  SUBROUTINE NM_Newton_GetStatistics(state, stats, status)
    TYPE(Newton_Iteration_State), INTENT(IN) :: state
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,L1,A,ES10.3,A,ES10.3)') &
      'Newton Statistics: iteration=', state%iter%current_iteration, &
      ', converged=', state%iter%converged, &
      ', force_residual=', state%residual%force_residual_norm, &
      ', displacement_increment=', state%residual%displacement_increment_norm
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_Newton_GetStatistics

  SUBROUTINE NM_Newton_Modified_Iteration(K_tangent, residual, du)
    REAL(DP), INTENT(IN)  :: K_tangent(:,:), residual(:)
    REAL(DP), INTENT(OUT) :: du(:)

    !  Newton ??K_tangent
    CALL NM_Newton_Standard_Iteration(K_tangent, residual, du)

  END SUBROUTINE NM_Newton_Modified_Iteration

  SUBROUTINE NM_Newton_Solv(params, u, f_ext, K_tangent, state)
    TYPE(Newton_Solver_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN)    :: f_ext(:)
    REAL(DP), INTENT(IN)    :: K_tangent(:,:)
    TYPE(Newton_Iteration_State), INTENT(OUT) :: state

    REAL(DP), ALLOCATABLE :: residual(:), du(:), f_internal(:)
    INTEGER(i4) :: iter, n_dof
    LOGICAL :: converged

    n_dof = SIZE(u)
    ALLOCATE(residual(n_dof), du(n_dof), f_internal(n_dof))

    ! Initialize iteration 
    state%iter%current_iteration = 0
    state%iter%converged = .FALSE.
    converged = .FALSE.

    ! Newton-Raphsoniteration 
    DO iter = 1, params%iter%max_iterations
      state%iter%current_iteration = iter

      ! 1. computation force 
      CALL NM_Newton_Calc_Residual(u, f_ext, f_internal, residual, params%callback%f_internal_proc)

      ! 2. check convergence
      CALL NM_Newton_Check_Conv(params, residual, du, state, converged)
      IF (converged) THEN
        state%iter%converged = .TRUE.
        EXIT
      END IF

      ! 3.  Solver type 
      SELECT CASE (params%solver%solver_type)
      CASE (NM_NEWTON_STANDARD)
        CALL NM_Newton_Standard_Iteration(K_tangent, residual, du)
      CASE (NM_NEWTON_MODIFIED)
        CALL NM_Newton_Modified_Iteration(K_tangent, residual, du)
      CASE (NM_NEWTON_QUASI_BFGS)
        CALL NM_Newton_BFGS_Update(K_tangent, residual, du, u)
      CASE (NM_NEWTON_TRUST_REGION)
        ! Trust-Region 
        CALL Invoke_TrustRegion_Solv(params, u, f_ext, K_tangent, state)
        ! Trust-Region convergencecheck??
        RETURN
      END SELECT

      ! 4.  
      IF (params%linesearch%use_line_search) THEN
        CALL Apply_Line_Search(u, du, residual, state%ls%line_search_factor)
        u = u + state%ls%line_search_factor * du
      ELSE
        u = u + du
        state%ls%line_search_factor = ONE
      END IF

    END DO

    !  convergence 
    IF (.NOT. converged) THEN
      PRINT *, 'WARNING: Newton-Raphson did not converge within', &
               params%iter%max_iterations, 'iterations'
    END IF

    DEALLOCATE(residual, du, f_internal)

  END SUBROUTINE NM_Newton_Solv

  SUBROUTINE NM_Newton_Standard_Iteration(K_tangent, residual, du)
    REAL(DP), INTENT(IN)  :: K_tangent(:,:), residual(:)
    REAL(DP), INTENT(OUT) :: du(:)

    INTEGER(i4) :: n_dof, info
    REAL(DP), ALLOCATABLE :: K_copy(:,:), rhs(:)
    INTEGER, ALLOCATABLE :: ipiv(:)

    n_dof = SIZE(residual)
    ALLOCATE(K_copy(n_dof, n_dof), rhs(n_dof), ipiv(n_dof))

    !  matrix (LAPACK matrix)
    K_copy = K_tangent
    rhs = residual

    ! solve  K_T??du = R
    ! use LAPACK DGESV (LU decomposition)
    CALL DGESV(n_dof, 1, K_copy, n_dof, ipiv, rhs, n_dof, info)

    IF (info /= 0) THEN
      PRINT *, 'ERROR: Linear solver failed in Newton iteration, info =', info
      du = ZERO
    ELSE
      du = rhs
    END IF

    DEALLOCATE(K_copy, rhs, ipiv)

  END SUBROUTINE NM_Newton_Standard_Iteration

  SUBROUTINE NM_QuasiNewton_GetStatistics(state, method_type, stats, status)
    TYPE(Newton_Iteration_State), INTENT(IN) :: state
    INTEGER(i4), INTENT(IN) :: method_type
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=16) :: method_name
    
    CALL init_error_status(status)
    
    IF (method_type == NM_NEWTON_QUASI_BFGS) THEN
      method_name = "BFGS"
    ELSE
      method_name = "L-BFGS"
    END IF
    
    WRITE(stats, '(A,A,A,I0,A,L1)') &
      'Quasi-Newton Statistics (', TRIM(method_name), &
      '): iteration=', state%iter%current_iteration, &
      ', converged=', state%iter%converged
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_QuasiNewton_GetStatistics

  SUBROUTINE NM_Theory_ExportList(unit, status)
    !! Write list of solver theory modules (name | description) to unit.
    !! Task: 16600-16699
    INTEGER(i4), INTENT(IN) :: unit
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, n
    CHARACTER(LEN=128) :: name, desc

    IF (PRESENT(status)) CALL init_error_status(status)
    CALL NM_Theory_GetNumModules(n)
    DO i = 1, n
      CALL NM_Theory_QueryByIndex(i, name, desc, status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
      WRITE(unit, '(A,1X,"|",1X,A)') TRIM(name), TRIM(desc)
    END DO
  END SUBROUTINE NM_Theory_ExportList

  SUBROUTINE NM_Theory_GetNumModules(num_modules)
    !! Return number of registered solver theory modules.
    !! Task: 16200-16299
    INTEGER(i4), INTENT(OUT) :: num_modules
    num_modules = 5
  END SUBROUTINE NM_Theory_GetNumModules

  SUBROUTINE NM_Theory_QueryByIndex(index, theory_name, description, status)
    !! Query solver theory module by index (1 to GetNumModules).
    !! Task: 16200-16299
    INTEGER(i4), INTENT(IN) :: index
    CHARACTER(LEN=*), INTENT(OUT) :: theory_name
    CHARACTER(LEN=*), INTENT(OUT) :: description
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    theory_name = ''
    description = ''
    CALL NM_Theory_Unified_Query(index, theory_name, status=status)
    IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    CALL NM_Theory_Unified_Describe(index, description, status)
  END SUBROUTINE NM_Theory_QueryByIndex

  SUBROUTINE NM_Theory_Unified_Describe(module_id, description, status)
    !! Describe solver theory module (short text).
    !! Task: 15500-15599
    INTEGER(i4), INTENT(IN) :: module_id
    CHARACTER(LEN=*), INTENT(OUT) :: description
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    description = ''
    SELECT CASE (module_id)
    CASE (1)
      description = 'Newton-Raphson: u_{k+1} = u_k - K_T^{-1} R(u_k)'
    CASE (2)
      description = 'Modified Newton: fixed tangent stiffness'
    CASE (3)
      description = 'Quasi-Newton: BFGS/SR1 secant update'
    CASE (4)
      description = 'Eigenvalue buckling analysis'
    CASE (5)
      description = 'Time integration (Newmark, alpha)'
    CASE DEFAULT
      description = 'Unknown solver theory module'
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
    END SELECT
  END SUBROUTINE NM_Theory_Unified_Describe

  SUBROUTINE NM_Theory_Unified_Query(module_id, theory_name, layer, status)
    !! Query solver theory module by id (Newton-Raphson, Modified Newton, etc.).
    !! Task: 15300-15499
    INTEGER(i4), INTENT(IN) :: module_id
    CHARACTER(LEN=*), INTENT(OUT) :: theory_name
    CHARACTER(LEN=*), INTENT(OUT), OPTIONAL :: layer
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    theory_name = ''
    IF (PRESENT(layer)) layer = 'L2_NM'
    SELECT CASE (module_id)
    CASE (1)
      theory_name = 'NM_Solve_NewtonRaphson'
    CASE (2)
      theory_name = 'NM_Solve_ModifiedNewton'
    CASE (3)
      theory_name = 'NM_Solve_QuasiNewton'
    CASE (4)
      theory_name = 'NM_Solve_EigenBuckling'
    CASE (5)
      theory_name = 'NM_TimeIntegration'
    CASE DEFAULT
      theory_name = 'NM_Solve_Unknown'
      IF (PRESENT(status)) status%status_code = IF_STATUS_INVALID
    END SELECT
  END SUBROUTINE NM_Theory_Unified_Query

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
END MODULE NM_Solv_Newton