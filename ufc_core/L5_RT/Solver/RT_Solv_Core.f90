!===============================================================================
! MODULE: RT_Solv_Core
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Core
! BRIEF:  Solver dispatch facade (Init/Solve/Convergence/Cutback/Finalize)
!===============================================================================
!
! Theory:  Newton-Raphson: K(u_n) Δu = -R(u_n)
!                          u_{n+1} = u_n + Δu
!          Convergence: ||R|| < tol_r  AND  ||Δu|| < tol_u
!
! FACADE NOTE (v4.0): This is a SKELETON/FACADE for the solver domain.
!   The GOLDEN-LINE solver is RT_Solv_Mgr.f90 + RT_Solv_Nonlin.f90.
!   This module provides a thin four-type interface but most procedures
!   are TODO/stub. Do NOT extend -- route new code through RT_Solv_Mgr.
!
! Process族:
!   P0: Init / Finalize                (COLD_PATH)
!   P2: Solve_Linear / Solve_Nonlinear (HOT_PATH)
!   P2: Check_Convergence / Apply_Increment / Cutback (HOT_PATH)
!
! Status: FACADE | Last verified: 2026-04-28
!===============================================================================
MODULE RT_Solv_Core
  USE IF_Prec_Core,     ONLY: wp, i4
  USE IF_Err_Brg,  ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Solv_Def, ONLY: RT_Sol_Cfg, RT_Sol_State
  USE NM_Mtx_Def,      ONLY: SparseMatrix_CSR
  USE NM_Solv_Def,     ONLY: NM_Solver_Algo, NM_Solver_State, &
                             NM_Solv_Iter_Arg, NM_Precond_State
  USE NM_Solv_Iter,    ONLY: CG_Solve, GMRES_Solve
  USE NM_Solv_Precond, ONLY: Construct_Jacobi_Precond
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Solv_Core_Init
  PUBLIC :: RT_Solv_Core_Solve_Linear
  PUBLIC :: RT_Solv_Core_Solve_Nonlinear
  PUBLIC :: RT_Solv_Core_Check_Convergence
  PUBLIC :: RT_Solv_Core_Apply_Increment
  PUBLIC :: RT_Solv_Core_Cutback
  PUBLIC :: RT_Solv_Core_Finalize

CONTAINS

  !---------------------------------------------------------------------------
  ! Init: set up solver from configuration
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Init(cfg, sol_state, status)
    TYPE(RT_Sol_Cfg),   INTENT(IN)    :: cfg
    TYPE(RT_Sol_State), INTENT(INOUT) :: sol_state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! S1. Read solver type from cfg
    sol_state%solverMethod = cfg%solver_type
    sol_state%nDOF = cfg%pop%n_dof

    ! S2. Set convergence tolerances
    sol_state%tol_residual   = cfg%tol_residual
    sol_state%tol_correction = cfg%tol_correction

    ! S3. Initialize iteration counters
    sol_state%n_iter       = 0
    sol_state%n_iter_total = 0
    sol_state%converged    = .FALSE.

    ! S4. Allocate solution vectors
    IF (cfg%pop%n_dof > 0) THEN
      IF (ALLOCATED(sol_state%u))  DEALLOCATE(sol_state%u)
      IF (ALLOCATED(sol_state%du)) DEALLOCATE(sol_state%du)
      IF (ALLOCATED(sol_state%R))  DEALLOCATE(sol_state%R)
      ALLOCATE(sol_state%u(cfg%pop%n_dof))
      ALLOCATE(sol_state%du(cfg%pop%n_dof))
      ALLOCATE(sol_state%R(cfg%pop%n_dof))
      sol_state%u  = 0.0_wp
      sol_state%du = 0.0_wp
      sol_state%R  = 0.0_wp
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Core_Init

  !---------------------------------------------------------------------------
  ! Solve_Linear: solve K * du = -R via L2_NM/Solver
  ! HOT_PATH | O(n_dof^alpha) where alpha depends on solver type
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Solve_Linear(cfg, sol_state, n_dof, &
                                        K_row_ptr, K_col_idx, K_values, &
                                        rhs, du, status)
    TYPE(RT_Sol_Cfg),   INTENT(IN)    :: cfg
    TYPE(RT_Sol_State), INTENT(INOUT) :: sol_state
    INTEGER(i4),        INTENT(IN)    :: n_dof
    INTEGER(i4),        INTENT(IN)    :: K_row_ptr(:)
    INTEGER(i4),        INTENT(IN)    :: K_col_idx(:)
    REAL(wp),           INTENT(IN)    :: K_values(:)
    REAL(wp),           INTENT(IN)    :: rhs(:)
    REAL(wp),           INTENT(OUT)   :: du(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! L2_NM solver types
    TYPE(NM_Solver_Algo)  :: nm_algo
    TYPE(NM_Solver_State) :: nm_stats
    TYPE(NM_Solv_Iter_Arg) :: nm_arg
    TYPE(SparseMatrix_CSR), TARGET :: K_csr
    REAL(wp), TARGET, ALLOCATABLE :: b_copy(:), x_copy(:)
    TYPE(NM_Precond_State) :: precond
    INTEGER(i4) :: nnz

    CALL init_error_status(status)
    du = 0.0_wp

    IF (n_dof < 1) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Solv_Core_Solve_Linear]: n_dof < 1"
      RETURN
    END IF

    ! S1. Build CSR matrix from input arrays
    nnz = SIZE(K_values)
    K_csr%nrows = n_dof
    K_csr%ncols = n_dof
    ALLOCATE(K_csr%row_ptr(n_dof + 1))
    ALLOCATE(K_csr%col_idx(nnz))
    ALLOCATE(K_csr%values(nnz))
    K_csr%row_ptr = K_row_ptr(1:n_dof + 1)
    K_csr%col_idx = K_col_idx(1:nnz)
    K_csr%values  = K_values(1:nnz)
    K_csr%is_allocated = .TRUE.

    ! S2. Setup SIO arg bundle
    ALLOCATE(b_copy(n_dof), x_copy(n_dof))
    b_copy = rhs(1:n_dof)
    x_copy = 0.0_wp
    nm_arg%A => K_csr
    nm_arg%b => b_copy
    nm_arg%x => x_copy

    ! S3. Configure algorithm
    nm_algo%tolerance = cfg%tol_residual
    nm_algo%max_iter  = 1000_i4
    nm_algo%verbose   = .FALSE.

    ! S4. Build Jacobi preconditioner
    CALL Construct_Jacobi_Precond(K_csr, precond)

    ! S5. Dispatch to L2_NM iterative solver (CG for SPD, GMRES otherwise)
    IF (cfg%is_spd) THEN
      CALL CG_Solve(nm_algo, nm_stats, nm_arg, precond)
    ELSE
      nm_algo%restart_freq = 50_i4
      CALL GMRES_Solve(nm_algo, nm_stats, nm_arg, precond)
    END IF

    ! S6. Extract solution
    du(1:n_dof) = x_copy(1:n_dof)

    ! S7. Update sol_state
    sol_state%n_iter       = nm_stats%niter
    sol_state%n_iter_total = sol_state%n_iter_total + nm_stats%niter
    sol_state%residual_norm = nm_stats%rnorm

    IF (nm_stats%convergence_flag /= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Solv_Core_Solve_Linear]: L2_NM solver did not converge"
    ELSE
      status%status_code = IF_STATUS_OK
    END IF

    ! Cleanup
    DEALLOCATE(b_copy, x_copy)
    DEALLOCATE(K_csr%row_ptr, K_csr%col_idx, K_csr%values)
  END SUBROUTINE RT_Solv_Core_Solve_Linear

  !---------------------------------------------------------------------------
  ! Solve_Nonlinear: Newton-Raphson iteration loop
  ! HOT_PATH | O(max_iter * solve_linear_cost)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Solve_Nonlinear(cfg, sol_state, &
                                           n_dof, u, R_norm, converged, &
                                           status)
    TYPE(RT_Sol_Cfg),   INTENT(IN)    :: cfg
    TYPE(RT_Sol_State), INTENT(INOUT) :: sol_state
    INTEGER(i4),        INTENT(IN)    :: n_dof
    REAL(wp),           INTENT(INOUT) :: u(:)
    REAL(wp),           INTENT(OUT)   :: R_norm
    LOGICAL,            INTENT(OUT)   :: converged
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    R_norm = 0.0_wp
    converged = .FALSE.

    BLOCK
      INTEGER(i4) :: iter, max_iter, i
      REAL(wp) :: R_norm_0, du_norm, alpha
      REAL(wp), ALLOCATABLE :: R_vec(:), du_vec(:)
      REAL(wp), PARAMETER :: eps_min = 1.0E-30_wp

      max_iter = 16
      ALLOCATE(R_vec(n_dof), du_vec(n_dof))
      R_vec = 0.0_wp
      du_vec = 0.0_wp
      R_norm_0 = 0.0_wp

      DO iter = 1, max_iter
        ! S2a/b. Residual from sol_state (pre-assembled by caller)
        IF (ALLOCATED(sol_state%R)) THEN
          R_vec(1:n_dof) = sol_state%R(1:n_dof)
        END IF

        ! S2b. Compute residual norm
        R_norm = 0.0_wp
        DO i = 1, n_dof
          R_norm = R_norm + R_vec(i) * R_vec(i)
        END DO
        R_norm = SQRT(R_norm)

        IF (iter == 1) R_norm_0 = MAX(R_norm, eps_min)

        ! S2c. Convergence check
        IF (iter > 1) THEN
          du_norm = 0.0_wp
          DO i = 1, n_dof
            du_norm = du_norm + du_vec(i) * du_vec(i)
          END DO
          du_norm = SQRT(du_norm)
        END IF

        IF (R_norm / R_norm_0 < sol_state%tol_residual .OR. &
            R_norm < 1.0E-12_wp) THEN
          converged = .TRUE.
          EXIT
        END IF

        ! S2d. Divergence check
        IF (iter > 3 .AND. R_norm > 1.0E4_wp * R_norm_0) THEN
          status%status_code = IF_STATUS_INVALID
          status%message = "[RT_Solv_Core_Solve_Nonlinear]: divergence"
          EXIT
        END IF

        ! S2e. Linear solve placeholder (identity preconditioner fallback)
        du_vec = R_vec

        ! S2g. Update u = u + du
        alpha = 1.0_wp
        DO i = 1, n_dof
          u(i) = u(i) + alpha * du_vec(i)
        END DO
      END DO

      IF (.NOT. converged) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[RT_Solv_Core_Solve_Nonlinear]: max iter"
      ELSE
        status%status_code = IF_STATUS_OK
      END IF

      DEALLOCATE(R_vec, du_vec)
    END BLOCK
  END SUBROUTINE RT_Solv_Core_Solve_Nonlinear

  !---------------------------------------------------------------------------
  ! Check_Convergence: evaluate convergence criteria
  ! HOT_PATH | O(n_dof)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Check_Convergence(cfg, sol_state, &
                                             R, du, R_norm, du_norm, &
                                             converged, status)
    TYPE(RT_Sol_Cfg),   INTENT(IN)  :: cfg
    TYPE(RT_Sol_State), INTENT(IN)  :: sol_state
    REAL(wp),           INTENT(IN)  :: R(:)
    REAL(wp),           INTENT(IN)  :: du(:)
    REAL(wp),           INTENT(OUT) :: R_norm
    REAL(wp),           INTENT(OUT) :: du_norm
    LOGICAL,            INTENT(OUT) :: converged
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n, i
    REAL(wp) :: energy_norm

    CALL init_error_status(status)
    n = SIZE(R)

    ! S1. Compute residual norm: ||R||_2
    R_norm = 0.0_wp
    DO i = 1, n
      R_norm = R_norm + R(i) * R(i)
    END DO
    R_norm = SQRT(R_norm)

    ! S2. Compute displacement correction norm: ||du||_2
    du_norm = 0.0_wp
    DO i = 1, n
      du_norm = du_norm + du(i) * du(i)
    END DO
    du_norm = SQRT(du_norm)

    ! S3. Dual-criterion convergence check
    converged = (R_norm < cfg%tol_residual) .AND. &
                (du_norm < cfg%tol_correction)

    ! S4. Optional energy criterion: |du^T * R| < tol_energy
    IF (.NOT. converged) THEN
      energy_norm = 0.0_wp
      DO i = 1, n
        energy_norm = energy_norm + du(i) * R(i)
      END DO
      energy_norm = ABS(energy_norm)
      IF (energy_norm < 1.0E-12_wp) converged = .TRUE.
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Core_Check_Convergence

  !---------------------------------------------------------------------------
  ! Apply_Increment: u_{n+1} = u_n + alpha * du (with optional line search)
  ! HOT_PATH | O(n_dof)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Apply_Increment(n_dof, u, du, alpha, status)
    INTEGER(i4), INTENT(IN)    :: n_dof
    REAL(wp),    INTENT(INOUT) :: u(:)
    REAL(wp),    INTENT(IN)    :: du(:)
    REAL(wp),    INTENT(IN)    :: alpha
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)

    DO i = 1, n_dof
      u(i) = u(i) + alpha * du(i)
    END DO

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Core_Apply_Increment

  !---------------------------------------------------------------------------
  ! Cutback: reduce time step when NR fails to converge
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Cutback(sol_state, cutback_factor, &
                                    new_dt, can_continue, status)
    TYPE(RT_Sol_State), INTENT(INOUT) :: sol_state
    REAL(wp),           INTENT(IN)    :: cutback_factor
    REAL(wp),           INTENT(OUT)   :: new_dt
    LOGICAL,            INTENT(OUT)   :: can_continue
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(wp), PARAMETER :: dt_min_default = 1.0E-12_wp
    INTEGER(i4), PARAMETER :: max_cutbacks_default = 10

    CALL init_error_status(status)

    ! S1. Reduce time step by cutback factor
    new_dt = sol_state%dt * cutback_factor

    ! S2. Check minimum threshold
    IF (new_dt < dt_min_default) THEN
      new_dt = dt_min_default
      can_continue = .FALSE.
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Solv_Core_Cutback]: dt below minimum"
      RETURN
    END IF

    ! S3. Update state and check cutback count
    sol_state%n_cutbacks = sol_state%n_cutbacks + 1
    IF (sol_state%n_cutbacks > max_cutbacks_default) THEN
      can_continue = .FALSE.
      status%status_code = IF_STATUS_INVALID
      status%message = "[RT_Solv_Core_Cutback]: max cutbacks exceeded"
      RETURN
    END IF

    ! S4. Apply new dt and signal continuation
    sol_state%dt = new_dt
    sol_state%converged = .FALSE.
    can_continue = .TRUE.

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Core_Cutback

  !---------------------------------------------------------------------------
  ! Finalize: release solver resources
  ! COLD_PATH | O(1)
  !---------------------------------------------------------------------------
  SUBROUTINE RT_Solv_Core_Finalize(sol_state, status)
    TYPE(RT_Sol_State), INTENT(INOUT) :: sol_state
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    ! Deallocate solution vectors
    IF (ALLOCATED(sol_state%u))  DEALLOCATE(sol_state%u)
    IF (ALLOCATED(sol_state%du)) DEALLOCATE(sol_state%du)
    IF (ALLOCATED(sol_state%R))  DEALLOCATE(sol_state%R)

    ! Reset counters
    sol_state%n_iter       = 0
    sol_state%n_iter_total = 0
    sol_state%n_cutbacks   = 0
    sol_state%converged    = .FALSE.
    sol_state%nDOF         = 0

    status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_Solv_Core_Finalize

END MODULE RT_Solv_Core
