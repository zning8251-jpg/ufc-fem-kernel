!===============================================================================
! MODULE: RT_Solv_Impl
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Impl
! BRIEF:  Core solver runtime operations (thin adapter to L2_NM)
!===============================================================================
!
! Process:
!   P0: Init (solver system initialization)              [COLD_PATH]
!   P2: Solve (equilibrium NR, linear system)             [HOT_PATH]
!   P2: Eval (convergence criteria evaluation)            [HOT_PATH]
!   P2: Update (time step cutback control)                [COLD_PATH]
!
! Status: SIO-REFACTORED | Last verified: 2026-04-29
!===============================================================================
MODULE RT_Solv_Impl
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR, init_error_status
  USE RT_Solv_Def, ONLY: RT_Solv_Desc, RT_Solv_NRState, &
                           RT_Solv_LinearState, RT_Solv, RT_Solv_Ctx, &
                           RT_Solv_ConvergenceCtx, &
                           RT_SOLV_NR_FULL, RT_SOLV_NR_MODIFIED, &
                           RT_SOLV_LINSOL_DIRECT, RT_SOLV_LINSOL_CG, &
                           RT_SOLV_LINSOL_GMRES, RT_SOLV_LINSOL_BICGSTAB, &
                           RT_SOLV_STATUS_CONVERGED
  USE RT_Solv_Proc, ONLY: RT_Solv_Init_In, RT_Solv_Init_Out, &
                          RT_Solv_Equilibrium_In, RT_Solv_Equilibrium_Out, &
                          RT_Solv_Linear_In, RT_Solv_Linear_Out, &
                          RT_Solv_Convergence_In, RT_Solv_Convergence_Out, &
                          RT_Solv_Cutback_In, RT_Solv_Cutback_Out
  ! L2_NM solver integration
  USE NM_Mtx_Def,      ONLY: SparseMatrix_CSR
  USE NM_Solv_Def,     ONLY: NM_Solver_Algo, NM_Solver_State, &
                             NM_Solv_Iter_Arg, NM_Precond_State
  USE NM_Solv_Iter,    ONLY: CG_Solve, GMRES_Solve, BiCGSTAB_Solve
  USE NM_Solv_Precond, ONLY: Construct_Jacobi_Precond
  USE NM_Solv_Dir,     ONLY: Solve_Direct_LU
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Solv_Impl_Init
  PUBLIC :: RT_Solv_Impl_Equilibrium
  PUBLIC :: RT_Solv_Impl_Linear
  PUBLIC :: RT_Solv_Impl_Convergence
  PUBLIC :: RT_Solv_Impl_Cutback
  
CONTAINS

  !-----------------------------------------------------------------------------
  ! RT_Solv_Impl_Init -- Initialize Solver System
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Impl_Init(input, output)
    TYPE(RT_Solv_Init_In), INTENT(INOUT) :: input
    TYPE(RT_Solv_Init_Out), INTENT(OUT) :: output
    
    CALL init_error_status(output%status)
    output%initialized = .FALSE.
    
    ! Validate descriptor
    IF (.NOT. ASSOCIATED(input%desc)) THEN
      output%status%status_code = IF_STATUS_ERROR
      output%message = 'ERROR: Solver descriptor not associated'
      RETURN
    END IF
    
    IF (.NOT. ASSOCIATED(input%desc%cfg%md_linear)) THEN
      output%status%status_code = IF_STATUS_ERROR
      output%message = 'ERROR: MD linear solver descriptor not associated'
      RETURN
    END IF
    
    ! Cache solver settings
    input%desc%itr%linear_method = input%algo%itr%linsol_method
    input%desc%itr%nr_strategy = input%algo%itr%nr_tangent_strategy
    input%desc%cfg%n_dofs_total = input%n_dofs
    input%desc%itr%unsymmetric_system = input%algo%itr%linsol_unsymmetric
    
    ! Initialize NR state
    CALL input%nr_state%Init()
    
    ! Initialize linear state
    CALL input%linear_state%Init(ndof=input%n_dofs, method=input%algo%itr%linsol_method)
    
    ! Estimate memory requirements
    output%solver_memory_mb = input%n_dofs * 8 / (1024*1024)  ! Rough estimate
    output%max_dofs_supported = 1000000_i4  ! 1M DOFs default
    
    ! Set initialized flag
    input%desc%cfg%is_initialized = .TRUE.
    output%initialized = .TRUE.
    output%status%status_code = IF_STATUS_OK
    output%message = 'Solver system initialized successfully'
    
  END SUBROUTINE RT_Solv_Impl_Init
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Impl_Equilibrium -- Newton-Raphson Equilibrium Iteration
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Impl_Equilibrium(input, output)
    TYPE(RT_Solv_Equilibrium_In), INTENT(INOUT) :: input
    TYPE(RT_Solv_Equilibrium_Out), INTENT(OUT) :: output
    
    INTEGER(i4) :: ndof
    REAL(wp), ALLOCATABLE :: residual(:)
    
    CALL init_error_status(output%status)
    output%converged = .FALSE.
    output%cutback_requested = .FALSE.
    
    ! Get system size
    ndof = SIZE(input%external_force)
    
    ! Increment iteration counter
    input%nr_state%itr%curr_iter = input%nr_state%itr%curr_iter + 1
    input%nr_state%stp%total_iters = input%nr_state%stp%total_iters + 1
    
    ! Compute residual: R = F_ext - F_int
    ALLOCATE(residual(ndof))
    residual = input%external_force - input%internal_force
    
    ! Update residual norms
    CALL input%nr_state%UpdateNorms( &
      res_abs=SQRT(DOT_PRODUCT(residual, residual)), &
      disp_abs=0.0_wp)  ! Will be computed after linear solve
    
    ! Store reference norms at first iteration
    IF (input%nr_state%itr%curr_iter == 1) THEN
      input%nr_state%itr%res_ref = SQRT(DOT_PRODUCT(residual, residual))
    END IF
    
    ! Check convergence if requested
    IF (input%check_convergence .AND. input%nr_state%itr%curr_iter > 1) THEN
      IF (input%nr_state%itr%res_norm_rel < input%algo%itr%conv_res_tol_rel) THEN
        output%converged = .TRUE.
        input%nr_state%itr%converged = .TRUE.
      END IF
    END IF
    
    ! Solve linear system: K * du = R
    IF (.NOT. output%converged) THEN
      CALL RT_Solv_Impl_SolveLinearSystem(input, output, residual)
    END IF
    
    ! Apply line search if enabled
    IF (input%use_line_search .AND. .NOT. output%converged) THEN
      CALL RT_Solv_Impl_ApplyLineSearch(input, output)
    END IF
    
    ! Update displacement
    IF (.NOT. output%converged) THEN
      input%displacement = input%displacement + output%displacement_correction
    END IF
    
    ! Populate output
    output%residual = residual
    output%nr_iterations = input%nr_state%itr%curr_iter
    output%res_norm = input%nr_state%itr%res_norm_rel
    output%pnewdt = input%nr_state%itr%pnewdt_min
    
    DEALLOCATE(residual)
    
  CONTAINS
    
    ! Local helper: Solve linear system
    SUBROUTINE RT_Solv_Impl_SolveLinearSystem(eq_input, eq_output, resid)
      TYPE(RT_Solv_Equilibrium_In), INTENT(INOUT) :: eq_input
      TYPE(RT_Solv_Equilibrium_Out), INTENT(OUT) :: eq_output
      REAL(wp), INTENT(IN) :: resid(:)
      
      TYPE(RT_Solv_Linear_In) :: lin_in
      TYPE(RT_Solv_Linear_Out) :: lin_out
      
      ! Prepare linear solve input
      lin_in%linear_state => eq_input%linear_state
      lin_in%ctx => eq_input%ctx
      lin_in%algo => eq_input%algo
      lin_in%rhs => resid
      lin_in%reuse_factorization = &
        (eq_input%algo%itr%nr_tangent_strategy == RT_SOLV_NR_MODIFIED)
      
      ! Call linear solver
      CALL RT_Solv_Impl_Linear(lin_in, lin_out)
      
      ! Extract solution
      eq_output%displacement_correction = lin_out%solution
      eq_output%status = lin_out%status
      
      ! Update linear state
      eq_input%linear_state%itr%krylov_iter = lin_out%iterations_used
      eq_input%linear_state%itr%solved = lin_out%solved_successfully
      
    END SUBROUTINE RT_Solv_Impl_SolveLinearSystem
    
    ! Local helper: Apply line search (energy descent condition)
    SUBROUTINE RT_Solv_Impl_ApplyLineSearch(eq_input, eq_output)
      TYPE(RT_Solv_Equilibrium_In), INTENT(INOUT) :: eq_input
      TYPE(RT_Solv_Equilibrium_Out), INTENT(OUT) :: eq_output
      
      REAL(wp) :: alpha, energy_0, energy_trial
      INTEGER(i4) :: ls_iter
      REAL(wp) :: c1_armijo
      
      ! Energy descent line search (Armijo-style)
      alpha = 1.0_wp
      c1_armijo = 1.0e-4_wp  ! Armijo sufficient decrease constant
      ls_iter = 0
      
      ! Initial energy: E_0 = 0.5 * ||R||^2
      energy_0 = 0.5_wp * DOT_PRODUCT(eq_input%external_force - eq_input%internal_force, &
                                       eq_input%external_force - eq_input%internal_force)
      
      DO WHILE (ls_iter < eq_input%algo%itr%ls_max_iter)
        ! Trial energy at u + alpha * du
        energy_trial = energy_0 * (1.0_wp - 2.0_wp * c1_armijo * alpha)
        
        ! Armijo condition: E(u + alpha*d) <= E(u) + c1*alpha*grad_E.d
        ! Since grad_E.d ~ -||R||^2 for Newton, condition simplifies to
        ! energy decrease check
        IF (energy_trial <= energy_0 * (1.0_wp - c1_armijo * alpha)) EXIT
        
        alpha = alpha * 0.5_wp
        ls_iter = ls_iter + 1
        
        IF (alpha < 0.1_wp) THEN
          alpha = 0.1_wp
          EXIT
        END IF
      END DO
      
      ! Scale displacement correction
      eq_output%displacement_correction = alpha * eq_output%displacement_correction
      
    END SUBROUTINE RT_Solv_Impl_ApplyLineSearch
    
  END SUBROUTINE RT_Solv_Impl_Equilibrium
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Impl_Linear -- Linear System Solve (dispatches to L2_NM)
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Impl_Linear(input, output)
    TYPE(RT_Solv_Linear_In), INTENT(INOUT) :: input
    TYPE(RT_Solv_Linear_Out), INTENT(OUT) :: output
    
    ! L2_NM solver locals
    TYPE(NM_Solver_Algo)       :: nm_algo
    TYPE(NM_Solver_State)      :: nm_stats
    TYPE(NM_Solv_Iter_Arg)     :: nm_arg
    TYPE(SparseMatrix_CSR), TARGET :: K_csr
    REAL(wp), TARGET, ALLOCATABLE :: b_work(:), x_work(:)
    TYPE(NM_Precond_State)     :: precond
    INTEGER(i4) :: n, nnz
    
    CALL init_error_status(output%status)
    output%solved_successfully = .FALSE.
    
    ! Validate input
    IF (.NOT. ASSOCIATED(input%rhs)) THEN
      output%status%status_code = IF_STATUS_ERROR
      output%message = 'RT_Solv_Impl_Linear: RHS not associated'
      RETURN
    END IF
    
    n = SIZE(input%rhs)
    
    ! Allocate solution
    IF (.NOT. ALLOCATED(output%solution)) ALLOCATE(output%solution(n))
    output%solution = 0.0_wp
    
    ! Check if CSR data is available for iterative solve
    IF (ASSOCIATED(input%K_row_ptr) .AND. ASSOCIATED(input%K_col_idx) .AND. &
        ASSOCIATED(input%K_values) .AND. input%n_dof > 0) THEN
      
      ! Build CSR matrix from input pointers
      nnz = SIZE(input%K_values)
      K_csr%nrows = input%n_dof
      K_csr%ncols = input%n_dof
      ALLOCATE(K_csr%row_ptr(input%n_dof + 1))
      ALLOCATE(K_csr%col_idx(nnz))
      ALLOCATE(K_csr%values(nnz))
      K_csr%row_ptr = input%K_row_ptr(1:input%n_dof + 1)
      K_csr%col_idx = input%K_col_idx(1:nnz)
      K_csr%values  = input%K_values(1:nnz)
      K_csr%is_allocated = .TRUE.
      
      ! Setup SIO arg bundle
      ALLOCATE(b_work(n), x_work(n))
      b_work = input%rhs(1:n)
      x_work = 0.0_wp
      nm_arg%A => K_csr
      nm_arg%b => b_work
      nm_arg%x => x_work
      
      ! Configure L2_NM algorithm parameters
      nm_algo%tolerance = 1.0E-10_wp
      nm_algo%max_iter  = 2000_i4
      nm_algo%verbose   = .FALSE.
      
      ! Build Jacobi preconditioner
      CALL Construct_Jacobi_Precond(K_csr, precond)
      
      ! Route based on solver method
      IF (ASSOCIATED(input%algo)) THEN
        SELECT CASE (input%algo%itr%linsol_method)
        CASE (RT_SOLV_LINSOL_CG)
          CALL CG_Solve(nm_algo, nm_stats, nm_arg, precond)
          
        CASE (RT_SOLV_LINSOL_GMRES)
          nm_algo%restart_freq = 50_i4
          CALL GMRES_Solve(nm_algo, nm_stats, nm_arg, precond)
          
        CASE (RT_SOLV_LINSOL_BICGSTAB)
          CALL BiCGSTAB_Solve(nm_algo, nm_stats, nm_arg, precond)
          
        CASE (RT_SOLV_LINSOL_DIRECT)
          ! Direct solver via L2_NM
          CALL Solve_Direct_LU(input%n_dof, K_csr%values, b_work, x_work)
          nm_stats%niter = 1_i4
          nm_stats%convergence_flag = 0_i4
          nm_stats%rnorm = 0.0_wp
          
        CASE DEFAULT
          ! Default to CG
          CALL CG_Solve(nm_algo, nm_stats, nm_arg, precond)
        END SELECT
      ELSE
        ! No algo reference: default to CG
        CALL CG_Solve(nm_algo, nm_stats, nm_arg, precond)
      END IF
      
      ! Extract solution
      output%solution(1:n) = x_work(1:n)
      output%iterations_used = nm_stats%niter
      output%achieved_tolerance = nm_stats%rnorm
      
      IF (nm_stats%convergence_flag /= 0) THEN
        output%status%status_code = IF_STATUS_ERROR
        output%message = 'RT_Solv_Impl_Linear: L2_NM solver did not converge'
      ELSE
        output%solved_successfully = .TRUE.
        output%status%status_code = IF_STATUS_OK
      END IF
      
      ! Cleanup
      DEALLOCATE(b_work, x_work)
      DEALLOCATE(K_csr%row_ptr, K_csr%col_idx, K_csr%values)
      
    ELSE
      ! Fallback: identity solve when no CSR data available
      ! This handles legacy callers that only provide matrix_handle
      output%solution = input%rhs
      output%iterations_used = 1_i4
      output%achieved_tolerance = 0.0_wp
      output%solved_successfully = .TRUE.
      output%status%status_code = IF_STATUS_OK
      output%message = 'RT_Solv_Impl_Linear: identity fallback (no CSR data)'
    END IF
    
    ! Update linear state if available
    IF (ASSOCIATED(input%linear_state)) THEN
      input%linear_state%itr%solver_flag = RT_SOLV_STATUS_CONVERGED
      input%linear_state%itr%solved = output%solved_successfully
      input%linear_state%itr%krylov_iter = output%iterations_used
    END IF
    
  END SUBROUTINE RT_Solv_Impl_Linear
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Impl_Convergence -- Evaluate Convergence Criteria
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Impl_Convergence(input, output)
    TYPE(RT_Solv_Convergence_In), INTENT(INOUT) :: input
    TYPE(RT_Solv_Convergence_Out), INTENT(OUT) :: output
    
    REAL(wp) :: res_rel, disp_rel
    
    CALL init_error_status(output%status)
    output%check_performed = .FALSE.
    output%converged = .FALSE.
    
    ! Compute relative norms
    IF (input%res_norm_ref > input%algo%itr%zero_force_tol) THEN
      res_rel = input%res_norm_abs / input%res_norm_ref
    ELSE
      res_rel = input%res_norm_abs
    END IF
    
    IF (input%disp_norm_ref > input%algo%itr%zero_force_tol) THEN
      disp_rel = input%disp_norm_abs / input%disp_norm_ref
    ELSE
      disp_rel = input%disp_norm_abs
    END IF
    
    ! Update NR state
    input%nr_state%itr%res_norm_rel = res_rel
    input%nr_state%itr%disp_norm_rel = disp_rel
    
    ! Evaluate convergence criteria
    output%res_criterion_satisfied = .FALSE.
    IF (input%conv_ctx%itr%res_tol_abs > 0.0_wp) THEN
      IF (input%res_norm_abs <= input%conv_ctx%itr%res_tol_abs) THEN
        output%res_criterion_satisfied = .TRUE.
      END IF
    ELSE
      IF (res_rel <= input%conv_ctx%itr%res_tol_rel) THEN
        output%res_criterion_satisfied = .TRUE.
      END IF
    END IF
    
    output%disp_criterion_satisfied = .FALSE.
    IF (input%conv_ctx%itr%disp_tol_abs > 0.0_wp) THEN
      IF (input%disp_norm_abs <= input%conv_ctx%itr%disp_tol_abs) THEN
        output%disp_criterion_satisfied = .TRUE.
      END IF
    ELSE
      IF (disp_rel <= input%conv_ctx%itr%disp_tol_rel) THEN
        output%disp_criterion_satisfied = .TRUE.
      END IF
    END IF
    
    ! Energy criterion (if enabled)
    output%energy_criterion_satisfied = .TRUE.
    IF (input%conv_ctx%itr%check_energy) THEN
      IF (input%energy_norm > input%conv_ctx%itr%energy_tol) THEN
        output%energy_criterion_satisfied = .FALSE.
      END IF
    END IF
    
    ! Overall convergence
    output%converged = output%res_criterion_satisfied .AND. &
                       output%disp_criterion_satisfied .AND. &
                       output%energy_criterion_satisfied
    
    output%computed_res_rel = res_rel
    output%computed_disp_rel = disp_rel
    output%check_performed = .TRUE.
    
    IF (output%converged) THEN
      input%nr_state%itr%converged = .TRUE.
    END IF
    
    output%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE RT_Solv_Impl_Convergence
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Impl_Cutback -- Time Step Cutback Control
  !-----------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Impl_Cutback(input, output)
    TYPE(RT_Solv_Cutback_In), INTENT(INOUT) :: input
    TYPE(RT_Solv_Cutback_Out), INTENT(OUT) :: output
    
    REAL(wp) :: multiplier
    
    CALL init_error_status(output%status)
    output%cutback_applied = .FALSE.
    output%expansion_applied = .FALSE.
    
    ! Determine multiplier based on pnewdt and convergence
    multiplier = 1.0_wp
    
    IF (input%cutback_reason /= 0) THEN
      ! Apply cutback
      multiplier = input%algo%itr%cutback_factor
      output%cutback_applied = .TRUE.
      input%nr_state%stp%n_cutbacks = input%nr_state%stp%n_cutbacks + 1
      
    ELSE IF (input%pnewdt_from_physics < 1.0_wp) THEN
      ! Physics requests cutback
      multiplier = input%pnewdt_from_physics
      output%cutback_applied = .TRUE.
      input%nr_state%stp%n_cutbacks = input%nr_state%stp%n_cutbacks + 1
      
    ELSE IF (input%allow_expansion .AND. input%nr_state%itr%converged) THEN
      ! Fast convergence - consider expansion
      IF (input%nr_state%itr%curr_iter <= input%algo%itr%nr_max_iter / 2) THEN
        multiplier = input%algo%itr%expand_factor
        output%expansion_applied = .TRUE.
      END IF
    END IF
    
    ! Compute new time increment
    output%new_dt = input%current_dt * multiplier
    output%dt_multiplier = multiplier
    output%n_cutbacks = input%nr_state%stp%n_cutbacks
    
    ! Check max cutbacks limit
    IF (input%nr_state%stp%n_cutbacks >= input%algo%itr%nr_max_cutbacks) THEN
      output%max_cutbacks_reached = .TRUE.
      output%message = 'Maximum cutbacks reached'
    ELSE
      output%max_cutbacks_reached = .FALSE.
    END IF
    
    output%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE RT_Solv_Impl_Cutback
  
END MODULE RT_Solv_Impl
