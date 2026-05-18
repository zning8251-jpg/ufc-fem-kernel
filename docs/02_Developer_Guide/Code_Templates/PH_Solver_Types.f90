!==============================================================================!
! MODULE PH_Solver_Types
! Layer  : L4_PH  (How / physics computation)
! Domain : Solver  –  L4-level linear solver and Krylov iteration types
!
! Five TYPE kinds:
!   PH_LinSolve_Ctx    – per-solve context (matrix/rhs pointers + metadata)
!   PH_PCG_State       – PCG iterative solver run-time state
!   PH_Krylov_Ctx      – Krylov subspace driver context (GMRES/BiCGSTAB)
!   PH_Precond_Ctx     – active preconditioner context (ILU/AMG workspace)
!   PH_Residual_Ctx    – linear residual tracking (r, ||r||, history)
!==============================================================================!
MODULE PH_Solver_Types
  USE IF_Prec_Core
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Solver status flags
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LSOLV_LSOLV_NOT_STARTED  = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LSOLV_LSOLV_CONVERGED    = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LSOLV_LSOLV_DIVERGED     = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LSOLV_LSOLV_MAX_ITER     = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_LSOLV_LSOLV_BREAKDOWN    = 4_i4  ! migrated

  ! Krylov method selector
  INTEGER(i4), PARAMETER, PUBLIC :: PH_KRYLOV_KRYLOV_PCG         = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_KRYLOV_KRYLOV_GMRES       = 2_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: PH_KRYLOV_KRYLOV_BICGSTAB    = 3_i4  ! migrated

  ! ------------------------------------------------------------------ !
  ! PH_LinSolve_Ctx
  !   Per-solve call context.  Carries non-owning pointers to the
  !   assembled stiffness matrix and RHS, plus dimension metadata.
  !   Created fresh each time the linear system is solved.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_LinSolve_Ctx
    INTEGER(i4)          :: neqns       = 0_i4   ! number of equations
    INTEGER(i4)          :: nnz         = 0_i4   ! non-zeros in sparse K
    ! Non-owning pointer arrays (data owned by assembler)
    REAL(wp),    POINTER :: rhs(:)    => NULL()  ! RHS vector [neqns]
    REAL(wp),    POINTER :: x(:)      => NULL()  ! solution vector [neqns]
    REAL(wp),    POINTER :: kval(:)   => NULL()  ! CSR values [nnz]
    INTEGER(i4), POINTER :: ia(:)     => NULL()  ! CSR row ptr [neqns+1]
    INTEGER(i4), POINTER :: ja(:)     => NULL()  ! CSR col idx [nnz]
    LOGICAL              :: sym_pos_def= .TRUE.   ! symmetric positive definite
    LOGICAL              :: reuse_factor= .FALSE. ! reuse previous factorisation
    INTEGER(i4)          :: solve_id  = 0_i4     ! monotonic solve counter
    TYPE(ErrorStatusType) :: status
  END TYPE PH_LinSolve_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_PCG_State
  !   Run-time state for the Preconditioned Conjugate Gradient solver.
  !   Persists across iterations; reset at each new linear solve.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_PCG_State
    INTEGER(i4)           :: n_iter     = 0_i4      ! current iteration count
    INTEGER(i4)           :: n_iter_max = 200_i4    ! maximum iterations
    REAL(wp)              :: tol        = 1.0e-8_wp  ! relative residual tolerance
    REAL(wp)              :: res_init   = 0.0_wp    ! initial ||r||
    REAL(wp)              :: res_curr   = 0.0_wp    ! current ||r||
    REAL(wp)              :: rho_prev   = 0.0_wp    ! rho from previous iteration
    REAL(wp), ALLOCATABLE :: p_vec(:)               ! search direction [neqns]
    REAL(wp), ALLOCATABLE :: z_vec(:)               ! preconditioned residual
    INTEGER(i4)           :: solver_flag = LSOLV_NOT_STARTED
    TYPE(ErrorStatusType) :: status
  END TYPE PH_PCG_State

  ! ------------------------------------------------------------------ !
  ! PH_Krylov_Ctx
  !   Krylov subspace driver context: method selection plus workspace
  !   sizes for GMRES restart and BiCGSTAB inner loops.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Krylov_Ctx
    INTEGER(i4) :: method           = KRYLOV_PCG   ! Krylov method selector
    INTEGER(i4) :: gmres_restart    = 50_i4         ! GMRES restart count m
    INTEGER(i4) :: n_iter_max       = 500_i4
    REAL(wp)    :: tol_rel          = 1.0e-8_wp
    REAL(wp)    :: tol_abs          = 0.0_wp        ! 0 = use relative only
    LOGICAL     :: flexible         = .FALSE.        ! FGMRES variant
    LOGICAL     :: left_precond     = .TRUE.         ! left vs right preconditioning
    INTEGER(i4) :: solver_flag      = LSOLV_NOT_STARTED
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Krylov_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Precond_Ctx
  !   Active preconditioner workspace context.  Holds the factorized
  !   ILU factors or AMG hierarchy (as opaque integer handle).
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Precond_Ctx
    INTEGER(i4)           :: precond_type = 0_i4    ! PRECOND_ILU/AMG/...
    INTEGER(i4)           :: ilu_level    = 0_i4    ! ILU(k) fill level
    REAL(wp)              :: ilu_drop_tol = 1.0e-4_wp
    INTEGER(i4)           :: amg_max_lev  = 10_i4  ! AMG max levels
    INTEGER(i4)           :: amg_coarsen  = 1_i4   ! coarsening strategy
    LOGICAL               :: is_built     = .FALSE.
    INTEGER(i4)           :: handle       = 0_i4   ! opaque solver library handle
    INTEGER(i4)           :: nnz_factors  = 0_i4   ! fill-in NNZ
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Precond_Ctx

  ! ------------------------------------------------------------------ !
  ! PH_Residual_Ctx
  !   Linear residual tracking context.  Records per-iteration history
  !   for convergence diagnostics.
  ! ------------------------------------------------------------------ !
  TYPE, PUBLIC :: PH_Residual_Ctx
    INTEGER(i4)           :: n_hist       = 0_i4   ! entries stored
    INTEGER(i4)           :: n_hist_max   = 512_i4 ! max history buffer
    REAL(wp)              :: res_init     = 0.0_wp
    REAL(wp)              :: res_final    = 0.0_wp
    REAL(wp)              :: res_rel      = 0.0_wp  ! res_final / res_init
    REAL(wp), POINTER :: res_hist(:)            ! [n_hist_max] residual history
    LOGICAL               :: converged    = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Residual_Ctx

END MODULE PH_Solver_Types
