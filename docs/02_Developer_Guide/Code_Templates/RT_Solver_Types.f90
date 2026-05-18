!===============================================================================
! Module: RT_Solver_Types                                        [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: Solver — Newton-Raphson convergence and linear solver control types
!
! Purpose:
!   Defines runtime solver control types for the nonlinear iteration loop.
!   These types are populated by the analysis framework at the start of each
!   increment and updated after each Newton iteration.
!
! Type catalogue (4 TYPEs):
!   RT_NR_Algo           – Newton-Raphson algorithm parameters (pre-step config)
!   RT_NR_State          – Newton-Raphson convergence state (per-iteration)
!   RT_LinSolv_Ctx       – Linear solver driving context (per-iteration)
!   RT_ConvergeCrit_Ctx  – Convergence criteria container (tolerances + norms)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_Solver_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_NR_Algo
  PUBLIC :: RT_NR_State
  PUBLIC :: RT_LinSolv_Ctx
  PUBLIC :: RT_ConvergeCrit_Ctx

  !-- Tangent update strategy constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_NR_TANGENT_NR_TANGENT_FULL      = 1_i4  ! Full Newton (update every iter)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_NR_TANGENT_NR_TANGENT_MODIFIED  = 2_i4  ! Modified Newton (update every n iter)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_NR_TANGENT_NR_TANGENT_INITIAL   = 3_i4  ! Initial stiffness (never update)  ! migrated

  !-- Linear solver method constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_DIRECT_FULL   = 1_i4  ! Full direct (LU)  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_DIRECT_SPARSE = 2_i4  ! Sparse direct  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_ITERATIVE_CG  = 3_i4  ! Conjugate Gradient  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_LINSOL_LINSOL_ITERATIVE_GMRES = 4_i4 ! GMRES  ! migrated

  !-- Convergence norm type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONV_CONV_NORM_L2   = 1_i4  ! L2 (Euclidean) norm  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONV_CONV_NORM_LINF = 2_i4  ! L-infinity (max) norm  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONV_CONV_NORM_L1   = 3_i4  ! L1 (sum of abs) norm  ! migrated

  !-----------------------------------------------------------------------------
  ! RT_NR_Algo — Newton-Raphson algorithm configuration
  !   Pre-analysis (or pre-step) configuration for the nonlinear solver.
  !   These parameters are set from input/defaults before the analysis runs.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_NR_Algo
    !-- Iteration limits
    INTEGER(i4) :: max_iter_eq   = 16_i4   ! Max equilibrium iterations (I_0)
    INTEGER(i4) :: max_iter_severe = 50_i4  ! Severe discontinuity iter limit
    INTEGER(i4) :: max_cutbacks  = 5_i4    ! Max cut-backs per increment

    !-- Tangent update strategy
    INTEGER(i4) :: tangent_strategy = NR_TANGENT_FULL
    INTEGER(i4) :: tangent_interval = 1_i4  ! Reuse stiffness every N iterations

    !-- Line search control
    LOGICAL  :: use_line_search   = .FALSE.
    INTEGER(i4) :: ls_max_iter    = 5_i4     ! Max line-search iterations
    REAL(wp) :: ls_tol            = 0.5_wp   ! Line-search force criterion

    !-- Time-step cutback factors
    REAL(wp) :: cutback_factor    = 0.25_wp  ! dt multiplier on cutback
    REAL(wp) :: expand_factor     = 1.5_wp   ! dt multiplier when converging fast

    !-- Solver method
    INTEGER(i4) :: linsol_method  = LINSOL_DIRECT_SPARSE

    !-- Unsymmetric system flag
    LOGICAL :: unsymm_system = .FALSE.
  END TYPE RT_NR_Algo

  !-----------------------------------------------------------------------------
  ! RT_NR_State — Newton-Raphson convergence state (per-increment runtime)
  !   Updated after each iteration; read by the step controller to decide
  !   whether to accept the increment or trigger a cut-back.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_NR_State
    !-- Iteration counters
    INTEGER(i4) :: iter         = 0_i4   ! Current iteration index (1-based)
    INTEGER(i4) :: n_cutbacks   = 0_i4   ! Number of cut-backs this increment
    INTEGER(i4) :: n_iter_total = 0_i4   ! Total iterations including cut-backs

    !-- Convergence norms (updated each iteration)
    REAL(wp) :: res_norm_abs  = 0.0_wp   ! Absolute residual norm
    REAL(wp) :: res_norm_rel  = 1.0_wp   ! Relative residual norm (||R_k|| / ||R_0||)
    REAL(wp) :: disp_norm_abs = 0.0_wp   ! Absolute displacement correction norm
    REAL(wp) :: disp_norm_rel = 1.0_wp   ! Relative displacement correction

    !-- Reference norms (set at first iteration)
    REAL(wp) :: res_ref    = 1.0_wp   ! ||R_0|| reference residual
    REAL(wp) :: disp_ref   = 1.0_wp   ! ||Δu_0|| reference displacement

    !-- pnewdt signal aggregated from all domains (min of all physics pnewdts)
    REAL(wp) :: pnewdt_min = 1.0_wp   ! Minimum pnewdt seen this iteration

    !-- Status flags
    LOGICAL :: converged    = .FALSE.   ! Increment equilibrium converged
    LOGICAL :: cutback_req  = .FALSE.   ! Cut-back requested (pnewdt < 1)
    LOGICAL :: severe_disc  = .FALSE.   ! Severe discontinuity iteration
    TYPE(ErrorStatusType) :: status
  END TYPE RT_NR_State

  !-----------------------------------------------------------------------------
  ! RT_LinSolv_Ctx — Linear solver driving context
  !   Carries the assembled system for the linear solve K * Δu = R.
  !   Actual matrix storage type depends on solver backend (not defined here).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_LinSolv_Ctx
    !-- System size
    INTEGER(i4) :: ndof         = 0_i4    ! Total active DOF count
    INTEGER(i4) :: nnz          = 0_i4    ! Number of non-zeros (sparse storage)

    !-- Solver method selection
    INTEGER(i4) :: method       = LINSOL_DIRECT_SPARSE
    LOGICAL     :: unsymm       = .FALSE.  ! Unsymmetric system

    !-- Iterative solver parameters (CG/GMRES)
    INTEGER(i4) :: krylov_max_iter = 300_i4
    REAL(wp)    :: krylov_tol      = 1.0e-10_wp

    !-- Factorization reuse flag (Modified Newton)
    LOGICAL :: reuse_factorization = .FALSE.

    !-- RHS vector (ALLOCATABLE; allocated by assembly)
    REAL(wp), POINTER :: rhs(:)     ! [ndof] residual / RHS

    !-- Solution vector (Δu)
    REAL(wp), POINTER :: du(:)      ! [ndof] displacement correction

    !-- Solver status
    INTEGER(i4) :: n_iter_solver = 0_i4  ! Iterations used (iterative solver)
    REAL(wp)    :: achieved_tol  = 0.0_wp ! Achieved tolerance (iterative)
    LOGICAL     :: solved        = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE RT_LinSolv_Ctx

  !-----------------------------------------------------------------------------
  ! RT_ConvergeCrit_Ctx — Convergence criteria container
  !   Stores tolerances and norm types for equilibrium checking.
  !   Populated from input data or defaults before the analysis runs.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_ConvergeCrit_Ctx
    !-- Residual force convergence
    REAL(wp)    :: res_tol_rel   = 5.0e-3_wp  ! Relative residual tolerance
    REAL(wp)    :: res_tol_abs   = 0.0_wp      ! Absolute residual tolerance (0=inactive)
    INTEGER(i4) :: res_norm_type = CONV_NORM_L2

    !-- Displacement correction convergence
    REAL(wp)    :: disp_tol_rel  = 1.0e-2_wp
    REAL(wp)    :: disp_tol_abs  = 0.0_wp
    INTEGER(i4) :: disp_norm_type = CONV_NORM_L2

    !-- Energy-based convergence (optional)
    LOGICAL  :: check_energy  = .FALSE.
    REAL(wp) :: energy_tol    = 1.0e-5_wp

    !-- Severe discontinuity iteration tolerance (looser)
    REAL(wp) :: severe_disc_tol = 1.0e-2_wp

    !-- Zero-force tolerance (avoid divide-by-zero)
    REAL(wp) :: zero_force_tol  = 1.0e-10_wp
  END TYPE RT_ConvergeCrit_Ctx

END MODULE RT_Solver_Types
