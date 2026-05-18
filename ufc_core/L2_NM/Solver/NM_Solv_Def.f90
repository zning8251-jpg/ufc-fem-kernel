!===============================================================================
! MODULE: NM_Solv_Def
! LAYER:  L2_NM
! DOMAIN: Solver
! ROLE:   Def (immutable definitions, TYPE catalogue, constants)
! BRIEF:  Four-type definitions for linear solver domain - Desc/Ctx/State/Algo
!===============================================================================
MODULE NM_Solv_Def
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  !--- Four-type TYPEs ---
  PUBLIC :: NM_Solver_Desc, NM_Solver_Ctx, NM_Solver_State, NM_Solver_Algo
  PUBLIC :: NM_Precond_Desc, NM_Precond_State
  !--- Legacy type aliases (now forwarded to 4-type system) ---
  !--- Solver method constants (NM_SOLV_*) ---
  PUBLIC :: NM_SOLV_METHOD_DIRECT, NM_SOLV_METHOD_GMRES
  PUBLIC :: NM_SOLV_METHOD_CG, NM_SOLV_METHOD_BICGSTAB
  PUBLIC :: NM_SOLV_METHOD_BANDED
  !--- Preconditioner constants (NM_SOLV_PREC_*) ---
  PUBLIC :: NM_SOLV_PREC_NONE, NM_SOLV_PREC_JACOBI
  PUBLIC :: NM_SOLV_PREC_ILU0, NM_SOLV_PREC_SSOR
  !--- Phase 6B: Preconditioner Procedure-as-Parameter strategy ---
  PUBLIC :: NM_Precond_Strategy_Ifc
  PUBLIC :: NM_Precond_Apply_Arg

  !===========================================================================
  ! Constants: Solver method enumerations (NM_SOLV_*)
  !===========================================================================
  INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_DIRECT   = 1_i4  ! Direct (LU/Cholesky)
  INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_GMRES    = 2_i4  ! GMRES
  INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_CG       = 3_i4  ! CG (SPD)
  INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_BICGSTAB = 4_i4  ! BiCGSTAB
  INTEGER(i4), PARAMETER :: NM_SOLV_METHOD_BANDED   = 5_i4  ! Banded direct

  ! [REMOVED] Legacy solver constant aliases — migrated to NM_SOLV_METHOD_*

  !===========================================================================
  ! Constants: Preconditioner type enumerations (NM_SOLV_PREC_*)
  !===========================================================================
  INTEGER(i4), PARAMETER :: NM_SOLV_PREC_NONE   = 0_i4  ! No preconditioner
  INTEGER(i4), PARAMETER :: NM_SOLV_PREC_JACOBI = 1_i4  ! Jacobi diagonal
  INTEGER(i4), PARAMETER :: NM_SOLV_PREC_ILU0   = 2_i4  ! ILU(0)
  INTEGER(i4), PARAMETER :: NM_SOLV_PREC_SSOR   = 3_i4  ! SSOR

  ! [REMOVED] Legacy precond constant aliases — migrated to NM_SOLV_PREC_*

  !===========================================================================
  ! Phase 6B: Preconditioner Strategy Procedure-as-Parameter
  !===========================================================================

  !> @brief Structured argument for preconditioner strategy dispatch
  TYPE, PUBLIC :: NM_Precond_Apply_Arg
    INTEGER(i4) :: n = 0                       ! [IN]  vector dimension
    REAL(wp), POINTER :: v_in(:)  => NULL()    ! [IN]  input vector
    REAL(wp), POINTER :: v_out(:) => NULL()    ! [OUT] preconditioned output
    TYPE(ErrorStatusType) :: status             ! [OUT]
  END TYPE NM_Precond_Apply_Arg

  !> @brief ABSTRACT INTERFACE for pluggable preconditioner strategy
  !! Procedure-as-Parameter: allows Jacobi, ILU0, SSOR, or custom
  !! Must be defined BEFORE NM_Precond_State which references it.
  ABSTRACT INTERFACE
    SUBROUTINE NM_Precond_Strategy_Ifc(arg, status)
      IMPORT :: NM_Precond_Apply_Arg, ErrorStatusType
      TYPE(NM_Precond_Apply_Arg), INTENT(INOUT) :: arg
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE NM_Precond_Strategy_Ifc
  END INTERFACE

  !===========================================================================
  ! NM_Solver_Desc - immutable solver configuration [INTENT(IN)]
  !===========================================================================
  TYPE :: NM_Solver_Desc
    INTEGER(i4) :: n            = 0_i4     ! System dimension
    INTEGER(i4) :: bandwidth    = 0_i4     ! Half-bandwidth (banded only)
    LOGICAL     :: is_symmetric = .FALSE.  ! Symmetry flag
    LOGICAL     :: is_spd       = .FALSE.  ! Symmetric positive-definite
  END TYPE NM_Solver_Desc

  !===========================================================================
  ! NM_Solver_Algo - algorithm parameters [INTENT(IN)]
  !===========================================================================
  TYPE :: NM_Solver_Algo
    INTEGER(i4) :: method       = NM_SOLV_METHOD_DIRECT  ! Solver method
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_NONE      ! Preconditioner
    INTEGER(i4) :: max_iter     = 1000_i4                ! Max iterations
    REAL(wp)    :: tolerance    = 1.0E-8_wp              ! Convergence tol
    REAL(wp)    :: relaxation   = 1.0_wp                 ! Relaxation (SSOR)
    LOGICAL     :: use_restart  = .TRUE.                 ! GMRES restart
    INTEGER(i4) :: restart_freq = 50_i4                  ! GMRES restart freq
    LOGICAL     :: verbose      = .FALSE.                ! Verbose output
  CONTAINS
    PROCEDURE, PASS :: SetTolerance => NM_Solver_Algo_SetTol
    PROCEDURE, PASS :: SetMaxIter   => NM_Solver_Algo_SetMaxIter
    GENERIC :: SET_TOL      => SetTolerance
    GENERIC :: SET_MAX_ITER => SetMaxIter
  END TYPE NM_Solver_Algo

  !===========================================================================
  ! NM_Solver_State - mutable runtime state [INTENT(INOUT)]
  !===========================================================================
  TYPE :: NM_Solver_State
    INTEGER(i4) :: niter            = 0_i4         ! Current iteration count
    REAL(wp)    :: rnorm            = 0.0_wp       ! Current residual norm
    REAL(wp)    :: dunorm           = 0.0_wp       ! Displacement increment norm
    LOGICAL     :: converged        = .FALSE.      ! Convergence flag
    REAL(wp)    :: initial_residual = 0.0_wp       ! Initial residual norm
    REAL(wp)    :: solve_time       = 0.0_wp       ! Wall-clock solve time
    INTEGER(i4) :: convergence_flag = 0_i4         ! 0=OK,2=max-iter,3=singular,...
    REAL(wp), ALLOCATABLE :: residual_history(:)   ! Per-iteration residual history
    REAL(wp), POINTER :: x(:)     => NULL() ! Solution vector
    REAL(wp), POINTER :: b(:)     => NULL() ! RHS vector
    REAL(wp), POINTER :: H_inv(:,:) => NULL() ! Inverse Hessian approx
  END TYPE NM_Solver_State

  !===========================================================================
  ! NM_Solver_Ctx - hot-path work arrays [INTENT(INOUT)]
  !===========================================================================
  TYPE :: NM_Solver_Ctx
    REAL(wp)    :: alpha  = 0.0_wp          ! Line-search step
    REAL(wp), POINTER :: r(:)     => NULL() ! Residual
    REAL(wp), POINTER :: p(:)     => NULL() ! Search direction
    REAL(wp), POINTER :: Ap(:)    => NULL() ! Matrix-vector product
    REAL(wp), POINTER :: z(:)     => NULL() ! Preconditioned residual
    REAL(wp), POINTER :: du(:)    => NULL() ! Increment
    REAL(wp), POINTER :: neg_R(:) => NULL() ! Negative residual
    REAL(wp), POINTER :: diag(:)  => NULL() ! Diagonal
    REAL(wp), POINTER :: K_band(:,:) => NULL() ! Banded stiffness
  END TYPE NM_Solver_Ctx

  !===========================================================================
  ! NM_Precond_Desc - preconditioner configuration [INTENT(IN)]
  !===========================================================================
  TYPE :: NM_Precond_Desc
    INTEGER(i4) :: precond_type = NM_SOLV_PREC_NONE
    REAL(wp)    :: ssor_omega   = 1.75_wp
  END TYPE NM_Precond_Desc

  !===========================================================================
  ! NM_Precond_State - mutable preconditioner data [INTENT(INOUT)]
  !===========================================================================
  TYPE :: NM_Precond_State
    INTEGER(i4)              :: precond_type   = NM_SOLV_PREC_NONE
    REAL(wp), ALLOCATABLE    :: diag(:)
    REAL(wp), ALLOCATABLE    :: L_data(:)
    REAL(wp), ALLOCATABLE    :: U_data(:)
    INTEGER(i4), ALLOCATABLE :: L_col(:)
    INTEGER(i4), ALLOCATABLE :: U_row(:)
    INTEGER(i4)              :: n              = 0_i4
    LOGICAL                  :: is_constructed = .FALSE.
    INTEGER(i4), ALLOCATABLE :: pc_row_ptr(:)
    INTEGER(i4), ALLOCATABLE :: pc_col_idx(:)
    REAL(wp), ALLOCATABLE    :: pc_mat_vals(:)
    REAL(wp), ALLOCATABLE    :: pc_lu_vals(:)
    INTEGER(i8)              :: pc_nnz         = 0_i8
    REAL(wp)                 :: ssor_omega     = 1.75_wp
    ! --- Phase 6B: Procedure-as-Parameter preconditioner strategy pointer ---
    PROCEDURE(NM_Precond_Strategy_Ifc), POINTER, NOPASS :: precond_strategy => NULL()
  CONTAINS
    PROCEDURE, PASS :: Construct_Jacobi => NM_Precond_Construct_Jacobi
    PROCEDURE, PASS :: Apply_Left       => NM_Precond_Apply_Left
    PROCEDURE, PASS :: Apply_Right      => NM_Precond_Apply_Right
  END TYPE NM_Precond_State

  !===========================================================================
  ! NM_Solv_Iter_Arg - SIO Arg bundle for iterative solvers (GMRES/CG/BiCGSTAB)
  ! Coupling params only; Algo/State/Precond stay as independent arguments.
  ! Placement order: Desc > Ctx > State > Algo > Arg
  !===========================================================================
  TYPE :: NM_Solv_Iter_Arg
    TYPE(SparseMatrix_CSR), POINTER :: A => NULL()     ! [IN]    Sparse matrix (CSR)
    REAL(wp), POINTER               :: b(:) => NULL()  ! [IN]    Right-hand side vector
    REAL(wp), POINTER               :: x(:) => NULL()  ! [INOUT] Initial guess / solution
  END TYPE NM_Solv_Iter_Arg

  ! [REMOVED] Legacy types LinearSolver, SolverStats, Preconditioner
  ! -- fully merged into NM_Solver_Algo, NM_Solver_State, NM_Precond_State

CONTAINS

  !---------------------------------------------------------------------------
  ! P0: Config | NM_Solver_Algo_SetTol
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Solver_Algo_SetTol(self, tol)
    CLASS(NM_Solver_Algo), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: tol

    IF (tol <= 0.0_wp) THEN
      ERROR STOP "NM_Solver_Algo_SetTol: Tolerance must be positive"
    END IF

    self%tolerance = tol
  END SUBROUTINE NM_Solver_Algo_SetTol

  SUBROUTINE NM_Solver_Algo_SetMaxIter(self, max_iter)
    CLASS(NM_Solver_Algo), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: max_iter

    IF (max_iter < 1) THEN
      ERROR STOP "NM_Solver_Algo_SetMaxIter: Max iterations must be >= 1"
    END IF

    self%max_iter = max_iter
  END SUBROUTINE NM_Solver_Algo_SetMaxIter

  !---------------------------------------------------------------------------
  ! P2: Compute | NM_Precond_Construct_Jacobi  (M^{-1} = diag(A)^{-1})
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Precond_Construct_Jacobi(self, A_diag)
    CLASS(NM_Precond_State), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: A_diag(:)
    INTEGER(i4) :: i

    self%n = SIZE(A_diag)
    self%precond_type = NM_SOLV_PREC_JACOBI

    IF (ALLOCATED(self%pc_row_ptr)) DEALLOCATE(self%pc_row_ptr, self%pc_col_idx, &
                                              self%pc_mat_vals, self%pc_lu_vals)
    self%pc_nnz = 0_i8

    IF (ALLOCATED(self%diag)) DEALLOCATE(self%diag)
    ALLOCATE(self%diag(self%n))

    DO i = 1, self%n
      IF (ABS(A_diag(i)) < 1.0E-14_wp) THEN
        ERROR STOP "NM_Precond_Construct_Jacobi: Zero diagonal element detected"
      END IF
      self%diag(i) = 1.0_wp / A_diag(i)
    END DO

    self%is_constructed = .TRUE.
  END SUBROUTINE NM_Precond_Construct_Jacobi

  !---------------------------------------------------------------------------
  ! P2: Compute | NM_Precond_Apply_Left  (w = M^{-1}*v)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Precond_Apply_Left(self, v, w)
    CLASS(NM_Precond_State), INTENT(IN) :: self
    REAL(wp), INTENT(IN) :: v(:)
    REAL(wp), INTENT(OUT) :: w(:)
    INTEGER(i4) :: i

    SELECT CASE (self%precond_type)
    CASE (NM_SOLV_PREC_JACOBI)
      DO i = 1, self%n
        w(i) = self%diag(i) * v(i)
      END DO

    CASE (NM_SOLV_PREC_NONE)
      w = v

    CASE (NM_SOLV_PREC_ILU0, NM_SOLV_PREC_SSOR)
      IF (.NOT. self%is_constructed) THEN
        ERROR STOP "NM_Precond_Apply_Left: ILU0/SSOR preconditioner not constructed"
      END IF
      IF (SIZE(v) /= self%n .OR. SIZE(w) /= self%n) THEN
        ERROR STOP "NM_Precond_Apply_Left: Vector size mismatch"
      END IF
      IF (self%precond_type == NM_SOLV_PREC_ILU0) THEN
        CALL NM_Precond_Apply_ILU0_Internal(self%n, self%pc_row_ptr, self%pc_col_idx, &
                                            self%pc_lu_vals, v, w)
      ELSE
        CALL NM_Precond_Apply_SSOR_Internal(self%n, self%pc_row_ptr, self%pc_col_idx, &
                                              self%pc_mat_vals, self%ssor_omega, v, w)
      END IF

    CASE DEFAULT
      ERROR STOP "NM_Precond_Apply_Left: Unsupported preconditioner type"
    END SELECT
  END SUBROUTINE NM_Precond_Apply_Left

  !---------------------------------------------------------------------------
  ! P2: Compute | NM_Precond_Apply_Right  (w = M^{-T}*v)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Precond_Apply_Right(self, v, w)
    CLASS(NM_Precond_State), INTENT(IN) :: self
    REAL(wp), INTENT(IN) :: v(:)
    REAL(wp), INTENT(OUT) :: w(:)

    CALL self%Apply_Left(v, w)
  END SUBROUTINE NM_Precond_Apply_Right

  !---------------------------------------------------------------------------
  ! P2: Compute | NM_Precond_Apply_ILU0_Internal (CSR forward/backward solve)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Precond_Apply_ILU0_Internal(n, rp, ci, lu, v, w)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: rp(:)
    INTEGER(i4), INTENT(IN) :: ci(:)
    REAL(wp), INTENT(IN) :: lu(:), v(:)
    REAL(wp), INTENT(OUT) :: w(:)
    REAL(wp) :: y(n)
    INTEGER(i4) :: i, j, jj
    REAL(wp) :: s, diagv

    y = v(1:n)
    DO i = 1, n
      s = y(i)
      DO jj = rp(i), rp(i + 1) - 1
        j = ci(jj)
        IF (j < i) s = s - lu(jj) * y(j)
      END DO
      y(i) = s
    END DO

    w(1:n) = 0.0_wp
    DO i = n, 1, -1
      s = y(i)
      diagv = 0.0_wp
      DO jj = rp(i), rp(i + 1) - 1
        j = ci(jj)
        IF (j > i) s = s - lu(jj) * w(j)
        IF (j == i) diagv = lu(jj)
      END DO
      IF (ABS(diagv) < 1.0E-30_wp) THEN
        ERROR STOP "NM_Precond_Apply_ILU0_Internal: zero diagonal pivot"
      END IF
      w(i) = s / diagv
    END DO
  END SUBROUTINE NM_Precond_Apply_ILU0_Internal

  !---------------------------------------------------------------------------
  ! P2: Compute | NM_Precond_Apply_SSOR_Internal (symmetric SOR sweep)
  !---------------------------------------------------------------------------
  SUBROUTINE NM_Precond_Apply_SSOR_Internal(n, rp, ci, av, omega, v, w)
    INTEGER(i4), INTENT(IN) :: n
    INTEGER(i4), INTENT(IN) :: rp(:)
    INTEGER(i4), INTENT(IN) :: ci(:)
    REAL(wp), INTENT(IN) :: av(:), v(:), omega
    REAL(wp), INTENT(OUT) :: w(:)
    INTEGER(i4) :: i, j, jj
    REAL(wp) :: s, diagv

    w(1:n) = 0.0_wp
    DO i = 1, n
      s = v(i)
      diagv = 0.0_wp
      DO jj = rp(i), rp(i + 1) - 1
        j = ci(jj)
        IF (j /= i) s = s - av(jj) * w(j)
        IF (j == i) diagv = av(jj)
      END DO
      IF (ABS(diagv) < 1.0E-30_wp) THEN
        ERROR STOP "NM_Precond_Apply_SSOR_Internal: zero diagonal"
      END IF
      w(i) = (1.0_wp - omega) * w(i) + omega * s / diagv
    END DO

    DO i = n, 1, -1
      s = v(i)
      diagv = 0.0_wp
      DO jj = rp(i), rp(i + 1) - 1
        j = ci(jj)
        IF (j /= i) s = s - av(jj) * w(j)
        IF (j == i) diagv = av(jj)
      END DO
      IF (ABS(diagv) < 1.0E-30_wp) THEN
        ERROR STOP "NM_Precond_Apply_SSOR_Internal: zero diagonal"
      END IF
      w(i) = (1.0_wp - omega) * w(i) + omega * s / diagv
    END DO
  END SUBROUTINE NM_Precond_Apply_SSOR_Internal

END MODULE NM_Solv_Def
