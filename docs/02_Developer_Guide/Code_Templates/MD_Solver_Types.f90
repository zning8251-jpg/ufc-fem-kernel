!=======================================================================
! Module: MD_Solver_Types                                 [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Solver / equation-system configuration
!
! Purpose:
!   Describes the linear solver and nonlinear iteration settings as
!   read from the INP (*STEP / *STATIC / *CONTROLS etc.).  These
!   are immutable during an analysis step.
!=======================================================================
MODULE MD_Solver_Types
  USE IF_Prec_Core
  IMPLICIT NONE
  PRIVATE

  ! Linear solver method flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_DIRECT_SPARSE  = 1_i4  ! sparse direct (default)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_ITERATIVE_PCG  = 2_i4  ! preconditioned CG  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_ITERATIVE_GMRES= 3_i4  ! GMRES  ! migrated

  ! Preconditioner type flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PRECOND_PRECOND_NONE   = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PRECOND_PRECOND_DIAG   = 1_i4  ! diagonal / Jacobi  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PRECOND_PRECOND_ILU    = 2_i4  ! ILU(0)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_PRECOND_PRECOND_AMG    = 3_i4  ! algebraic multigrid  ! migrated

  ! Eigensolver type flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_EIG_EIGSOL_LANCZOS  = 1_i4  ! Lanczos (Abaqus *FREQUENCY)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_EIG_EIGSOL_SUBSPACE = 2_i4  ! subspace iteration  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_EIG_EIGSOL_AMS      = 3_i4  ! AMS (Abaqus)  ! migrated

  !=====================================================================
  ! MD_LinearSolver_Desc — linear solver configuration (Desc = INP-driven)
  !   *SOLVER, SOLVER=DIRECT  or  *CONTROLS, PARAMETERS=FIELD
  !=====================================================================
  TYPE, PUBLIC :: MD_LinearSolver_Desc
    INTEGER(i4) :: method        = LINSOL_DIRECT_SPARSE  ! solver method
    INTEGER(i4) :: n_threads     = 1_i4      ! number of solver threads
    REAL(wp)    :: tol_rel       = 1.0e-8_wp ! relative residual tolerance
    REAL(wp)    :: tol_abs       = 0.0_wp    ! absolute residual tolerance
    INTEGER(i4) :: max_iter      = 500_i4   ! max iterations (iterative only)
    LOGICAL     :: pivoting      = .TRUE.    ! partial pivoting (direct)
    LOGICAL     :: symmetric     = .TRUE.    ! symmetric storage
    LOGICAL     :: is_active     = .FALSE.
  END TYPE MD_LinearSolver_Desc

  !=====================================================================
  ! MD_Precond_Desc — preconditioner configuration
  !=====================================================================
  TYPE, PUBLIC :: MD_Precond_Desc
    INTEGER(i4) :: precond_type  = PRECOND_ILU   ! preconditioner type
    INTEGER(i4) :: fill_level    = 0_i4           ! ILU fill level
    REAL(wp)    :: drop_tol      = 1.0e-4_wp      ! drop tolerance
    INTEGER(i4) :: amg_levels    = 5_i4           ! AMG levels
    LOGICAL     :: rebuild_every_step = .FALSE.   ! rebuild preconditioner
    LOGICAL     :: is_active     = .FALSE.
  END TYPE MD_Precond_Desc

  !=====================================================================
  ! MD_EigenSolver_Desc — eigenvalue solver configuration
  !   *FREQUENCY, EIGENSOLVER=LANCZOS  etc.
  !=====================================================================
  TYPE, PUBLIC :: MD_EigenSolver_Desc
    INTEGER(i4) :: method        = EIGSOL_LANCZOS
    INTEGER(i4) :: n_modes       = 10_i4       ! number of eigenvalues
    REAL(wp)    :: freq_min      = 0.0_wp       ! minimum frequency (Hz)
    REAL(wp)    :: freq_max      = 1.0e8_wp     ! maximum frequency
    INTEGER(i4) :: max_block_size= 7_i4         ! Lanczos block size
    REAL(wp)    :: tol           = 1.0e-5_wp    ! convergence tolerance
    LOGICAL     :: mass_norm     = .TRUE.        ! mass normalise eigenvectors
    LOGICAL     :: is_active     = .FALSE.
  END TYPE MD_EigenSolver_Desc

  !=====================================================================
  ! MD_NR_Algo — Newton-Raphson algorithm parameters (L3 view: global NR)
  !   *CONTROLS, PARAMETERS=TIME INCREMENTATION
  !   Note: Per-subroutine NR control lives in PH_Mat_Base_Algo.
  !=====================================================================
  TYPE, PUBLIC :: MD_NR_Algo
    INTEGER(i4) :: max_iter      = 16_i4       ! maximum NR iterations
    INTEGER(i4) :: max_cutbacks  = 5_i4        ! maximum cutbacks per increment
    REAL(wp)    :: tol_force     = 5.0e-3_wp   ! force residual tolerance
    REAL(wp)    :: tol_disp      = 1.0e-2_wp   ! displacement correction tolerance
    REAL(wp)    :: tol_energy    = 1.0e-5_wp   ! energy tolerance
    LOGICAL     :: line_search   = .FALSE.      ! line search
    REAL(wp)    :: ls_tol        = 0.25_wp      ! line search tolerance
    INTEGER(i4) :: ls_max_iter   = 5_i4
    LOGICAL     :: quasi_newton  = .FALSE.      ! quasi-Newton (BFGS)
  END TYPE MD_NR_Algo

END MODULE MD_Solver_Types


!===============================================================================
! MODULE MD_Solver_Domain_Types                                  [Template v1.0]
! Layer:  L3_MD — Model Description Layer
! Domain: Solver — Flat-storage independent domain container
!
! PURPOSE: Standard four-type domain container for Solver domain.
!   MD_Solv_Desc   — solver configuration (per-step; write-once)
!   MD_Solv_State  — runtime solve state (residuals, iteration counts)
!   MD_Solv_Algo   — NR tolerances and cutback policy (read-only during solve)
!   MD_Solv_Ctx    — hot-path context (no ALLOCATABLE)
!===============================================================================
MODULE MD_Solver_Domain_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Solv_Desc
  PUBLIC :: MD_Solv_State
  PUBLIC :: MD_Solv_Algo
  PUBLIC :: MD_Solv_Ctx
  PUBLIC :: MD_Solver_Domain
  PUBLIC :: MD_Solver_Domain_Init
  PUBLIC :: MD_Solver_Domain_Finalize
  PUBLIC :: MD_Solver_WriteBack

  !-- Solver method constants --
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SOLV_METHOD_DIRECT_SPARSE  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SOLV_METHOD_ITERATIVE_PCG  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_SOLV_METHOD_ITERATIVE_GMRES= 3_i4

  !=============================================================================
  ! Desc — Solver configuration per step (write-once after parse)
  !=============================================================================
  TYPE, PUBLIC :: MD_Solv_Desc
    CHARACTER(LEN=80) :: name           = ''                        ! Solver name
    INTEGER(i4)       :: solver_id      = 0_i4                      ! 1-based index
    INTEGER(i4)       :: step_ref       = 0_i4                      ! Step this solver is bound to
    INTEGER(i4)       :: method         = MD_SOLV_METHOD_DIRECT_SPARSE ! Linear solver method
    INTEGER(i4)       :: n_threads      = 1_i4                      ! Solver thread count
    REAL(wp)          :: tol_rel        = 1.0e-8_wp                 ! Relative residual tol
    LOGICAL           :: symmetric      = .TRUE.                    ! Symmetric storage
    LOGICAL           :: pivoting       = .TRUE.                    ! Partial pivoting
    INTEGER(i4)       :: max_nr_iter    = 16_i4                     ! Max NR iterations
    INTEGER(i4)       :: max_cutbacks   = 5_i4                      ! Max cutbacks
    REAL(wp)          :: tol_force      = 5.0e-3_wp                 ! Force residual tol
    REAL(wp)          :: tol_disp       = 1.0e-2_wp                 ! Disp correction tol
  END TYPE MD_Solv_Desc

  !=============================================================================
  ! State — Runtime solver state (WriteBack whitelist gated)
  !=============================================================================
  TYPE, PUBLIC :: MD_Solv_State
    INTEGER(i4) :: n_iterations    = 0_i4    ! NR iterations this increment
    INTEGER(i4) :: n_cutbacks      = 0_i4    ! Cut-backs this increment
    REAL(wp)    :: residual_norm   = 0.0_wp  ! Current force residual
    REAL(wp)    :: disp_norm       = 0.0_wp  ! Current displacement correction
    LOGICAL     :: converged       = .FALSE. ! Converged this increment
    LOGICAL     :: is_active       = .FALSE. ! Active in current step
  END TYPE MD_Solv_State

  !=============================================================================
  ! Algo — Algorithm parameters (read-only during solve)
  !=============================================================================
  TYPE, PUBLIC :: MD_Solv_Algo
    REAL(wp)    :: cutback_factor  = 0.25_wp  ! Increment reduction on cutback
    LOGICAL     :: line_search     = .FALSE.  ! Enable line search
    REAL(wp)    :: ls_tol          = 0.25_wp  ! Line search tolerance
    INTEGER(i4) :: ls_max_iter     = 5_i4     ! Line search max iterations
  END TYPE MD_Solv_Algo

  !=============================================================================
  ! Ctx — Hot-path context (NO ALLOCATABLE)
  !=============================================================================
  TYPE, PUBLIC :: MD_Solv_Ctx
    INTEGER(i4) :: solver_idx      = 0_i4    ! Active solver index in domain array
    INTEGER(i4) :: step_idx        = 0_i4    ! Step index from L5_RT
    INTEGER(i4) :: incr_idx        = 0_i4    ! Increment index from L5_RT
    LOGICAL     :: is_first_iter   = .TRUE.  ! First NR iteration flag
  END TYPE MD_Solv_Ctx

  !=============================================================================
  ! MD_Solver_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_Solver_Domain
    TYPE(MD_Solv_Desc),  ALLOCATABLE :: desc(:)
    TYPE(MD_Solv_State), ALLOCATABLE :: state(:)
    TYPE(MD_Solv_Algo),  ALLOCATABLE :: algo(:)
    INTEGER(i4) :: n_solvers   = 0_i4
    INTEGER(i4) :: max_solvers = 0_i4
    LOGICAL     :: initialized = .FALSE.
    LOGICAL     :: frozen      = .FALSE.
  CONTAINS
    PROCEDURE :: Init      => MD_Solver_Domain_Init
    PROCEDURE :: Finalize  => MD_Solver_Domain_Finalize
    PROCEDURE :: WriteBack => MD_Solver_WriteBack
  END TYPE MD_Solver_Domain

CONTAINS

  SUBROUTINE MD_Solver_Domain_Init(this, cap_solvers, status)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: cap_solvers
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL MD_Solver_Domain_Finalize(this)
    ALLOCATE(this%desc(cap_solvers))
    ALLOCATE(this%state(cap_solvers))
    ALLOCATE(this%algo(cap_solvers))
    this%n_solvers   = 0_i4
    this%max_solvers = cap_solvers
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Solver_Domain_Init

  SUBROUTINE MD_Solver_Domain_Finalize(this)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%desc))  DEALLOCATE(this%desc)
    IF (ALLOCATED(this%state)) DEALLOCATE(this%state)
    IF (ALLOCATED(this%algo))  DEALLOCATE(this%algo)
    this%n_solvers   = 0_i4
    this%max_solvers = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_Solver_Domain_Finalize

  SUBROUTINE MD_Solver_WriteBack(this, solver_id, new_state, status)
    CLASS(MD_Solver_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: solver_id
    TYPE(MD_Solv_State),     INTENT(IN)    :: new_state
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. solver_id < 1_i4 .OR. solver_id > this%n_solvers) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Solver_WriteBack: invalid solver_id=', solver_id
      RETURN
    END IF
    this%state(solver_id) = new_state
    status%status_code    = IF_STATUS_OK
  END SUBROUTINE MD_Solver_WriteBack

END MODULE MD_Solver_Domain_Types
