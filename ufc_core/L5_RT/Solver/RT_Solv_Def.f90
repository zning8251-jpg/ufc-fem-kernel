!===============================================================================
! MODULE: RT_Solv_Def
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Def
! BRIEF:  Solver domain four-type system (Desc/Ctx/State/Algo) + legacy re-exports
!===============================================================================
!
! Four-TYPE System:
!   RT_Solv_Desc           �?immutable solver configuration (solver type, DOF count)
!   RT_Solv_Ctx            �?per-call transient context (step/incr/iter IDs, time)
!   RT_Solv_State          �?mutable runtime state (NR convergence, linear solve)
!   RT_Solv                -- algorithm params (%itr = RT_Solv_Itr_Algo)
!   RT_Solv_ConvergenceCtx �?convergence criteria evaluation context
!
! Legacy Re-exports (from RT_Shared_Def):
!   RT_Sol_Cfg, RT_Sol_DofMap, RT_Sol_State, RT_CSRMatrix
!
! Constants: RT_SOLV_{category}_{name} (all uppercase)
!
! Partial Pillar: H4b Solver (L3 + L5)
!   L3: MD_Solv_Def (AUTHORITY for solver definition Desc/Algo)
!   L5: RT_Solv_Def (THIS MODULE �?AUTHORITY for L5 solver shared types)
!   L5 Golden Line: RT_Solv_Mgr.f90 + RT_Solv_Nonlin.f90 (production solver)
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================

module RT_Solv_Def
  !! Four-type solver definition module.
  !! Re-exports legacy types from RT_Shared_Def; provides RT_CSR_Free.

  USE IF_Prec_Core, only: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE MD_Solv_Def, ONLY: MD_LinearSolver_Desc, MD_NR_Algo, MD_Precond_Desc
  USE RT_Shared_Def, only: RT_Sol_Cfg, RT_Sol_DofMap, RT_Sol_State, RT_CSRMatrix, &
                              RT_SOL_LINSOL_A, RT_SOL_LINSOL_AGMG, RT_SOL_LINSOL_D, RT_SOL_LINSOL_I, &
                              RT_SOL_LINSOL_S, RT_Sol_Mat_CSR, RT_SOL_MAT_DENS
  ! From NM_AssemSparse (L2_NM)
  USE NM_Assem_Sparse, only: RT_TripletList, RT_Triplet_Add

  implicit none

  private
  public :: RT_Sol_Cfg, RT_Sol_DofMap, RT_Sol_State, RT_CSRMatrix
  public :: RT_SOL_LINSOL_A, RT_SOL_LINSOL_AGMG, RT_SOL_LINSOL_D, RT_SOL_LINSOL_I, RT_SOL_LINSOL_S
  public :: RT_Sol_Mat_CSR, RT_SOL_MAT_DENS
  public :: RT_CSR_Free, csr_destroy
  public :: RT_AdvancedTimeIntegrator
  public :: RT_AdvancedNLSol
  ! Equilibrium method constants (for Step_Utils / decoupling RT_Step_Utils from RT_Solver_Core)
  public :: RT_EQ_METHOD_NE, RT_EQ_METHOD_MO, RT_EQ_METHOD_LB, RT_EQ_METHOD_QU
  public :: RT_TripletList, RT_Triplet_Add
  ! Types are now defined in RT_Shared_Def
  ! This module re-exports them for backward compatibility

  !=============================================================================
  ! Equilibrium method constants (Step/Utils decoupling; values match RT_Solver_Core)
  !=============================================================================
  integer(i4), parameter :: RT_EQ_METHOD_NE      = 1_i4
  integer(i4), parameter :: RT_EQ_METHOD_MO = 2_i4
  integer(i4), parameter :: RT_EQ_METHOD_LB      = 3_i4
  integer(i4), parameter :: RT_EQ_METHOD_QU = 4_i4

  ! REMOVED: SolCfg/SolDofMap legacy aliases �?use RT_Sol_Cfg/RT_Sol_DofMap

  !=============================================================================
  ! Time Integration Types
  !=============================================================================
  
  !---------------------------------------------------------------------------
  ! Time Integration State Type (Advanced)
  !---------------------------------------------------------------------------
  type, public :: RT_AdvancedTimeIntegrator
    integer(i4) :: method = 1          ! 1=Newmark, 2=HHT-?, 3=Generalized-?, 4=Central
    real(wp) :: dt = 0.0_wp
    real(wp) :: time = 0.0_wp
    integer(i4) :: step = 0

    ! Newmark parameters
    real(wp) :: beta = 0.25_wp, gamma = 0.5_wp

    ! HHT-alpha parameters
    real(wp) :: alpha = -0.1_wp

    ! Generalized-alpha parameters
    real(wp) :: alpha_m = 0.0_wp, alpha_f = 0.0_wp
    real(wp) :: gamma_ga = 0.5_wp, beta_ga = 0.25_wp

    ! State vectors
    real(wp), allocatable :: u_n(:), v_n(:), a_n(:), u_np1(:), v_np1(:), a_np1(:)
    real(wp), allocatable :: M(:,:), C(:,:), K(:,:)
    real(wp), allocatable :: F_ext_n(:), F_ext_np1(:), F_int_n(:), F_int_np1(:)
    real(wp), allocatable :: K_eff(:,:), F_eff(:)

    LOGICAL :: init = .FALSE.
  end type RT_AdvancedTimeIntegrator

  !---------------------------------------------------------------------------
  ! Nonlinear Solver State Type (Advanced)
  !---------------------------------------------------------------------------
  type, public :: RT_AdvancedNLSol
    integer(i4) :: method = 1         ! Solution method (1=NR, 2=Arc-Length, etc.)
    integer(i4) :: max_iterations = 50
    integer(i4) :: convergence_typ = 4  ! 1=disp, 2=force, 3=energy, 4=mixed
    real(wp) :: tolerance_force = 1.0e-6_wp
    real(wp) :: tolerance_disp = 1.0e-6_wp
    real(wp) :: tolerance_energ = 1.0e-8_wp

    ! Arc-length parameters
    real(wp) :: arc_length_radi = 1.0_wp
    real(wp) :: arc_length_ds = 0.1_wp
    integer(i4) :: arc_length_type = 1

    ! Line search parameters
    real(wp) :: line_search_alp = 1.0_wp
    real(wp) :: line_search_eta = 0.5_wp
    integer(i4) :: max_line_search = 10

    ! Trust region parameters
    real(wp) :: trust_region_de = 1.0_wp
    real(wp) :: trust_region_et = 0.1_wp

    ! State variables
    integer(i4) :: iteration = 0
    real(wp) :: residual_norm = 0.0_wp
    real(wp) :: displacement_no = 0.0_wp
    real(wp) :: energy_norm = 0.0_wp
    logical :: converged = .FALSE.

    ! Solution vectors
    real(wp), allocatable :: u(:), du(:), R(:), K(:,:), F_ext(:)
    real(wp), allocatable :: u_arc(:), psi(:)
    real(wp) :: lambda = 0.0_wp

    LOGICAL :: init = .FALSE.
  end type RT_AdvancedNLSol


  
  ! --- Four-type system public exports (H4b: cfg/itr/stp nested; aligns L3 MD_Solver_*) ---
  ! Desc  : RT_Solv_Desc = cfg + itr (runtime cache)
  ! State : RT_Solv_NRState, RT_Solv_LinearState; aggregate RT_Solv_State for SIO Arg
  ! Algo  : RT_Solv wraps RT_Solv_Itr_Algo in %itr (mirrors MD_Solver_Algo)
  ! Ctx   : RT_Solv_Ctx (stp+itr), RT_Solv_ConvergenceCtx (%itr conv bundle)
  PUBLIC :: RT_Solv_Cfg_Desc, RT_Solv_Itr_Desc_Cache
  PUBLIC :: RT_Solv_Stp_State, RT_Solv_Itr_NRState
  PUBLIC :: RT_Solv_Linear_Stp_State, RT_Solv_Linear_Itr_State
  PUBLIC :: RT_Solv_Itr_Algo
  PUBLIC :: RT_Solv_Stp_Ctx, RT_Solv_Itr_Ctx
  PUBLIC :: RT_Solv_Conv_Itr_Ctx
  PUBLIC :: RT_Solv_Desc
  ! (R-09: was RT_Solv_Base_Desc)
  PUBLIC :: RT_Solv_NRState
  PUBLIC :: RT_Solv_LinearState
  PUBLIC :: RT_Solv_State
  PUBLIC :: RT_Solv
  PUBLIC :: RT_Solv_Ctx
  PUBLIC :: RT_Solv_ConvergenceCtx
  PUBLIC :: RT_Solv_Solve_Arg
  
  !-- Newton-Raphson tangent update strategy
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NR_FULL = 1_i4          ! Full Newton (update every iter)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NR_MODIFIED = 2_i4      ! Modified Newton (periodic update)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NR_INITIAL = 3_i4       ! Initial stiffness (no update)
  
  !-- Linear solver methods
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_LINSOL_DIRECT = 1_i4    ! Direct sparse solver
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_LINSOL_CG = 2_i4        ! Conjugate Gradient
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_LINSOL_GMRES = 3_i4     ! GMRES
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_LINSOL_BICGSTAB = 4_i4  ! BiCGSTAB
  
  !-- Convergence norm types
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NORM_L2 = 1_i4          ! Euclidean norm
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NORM_LINF = 2_i4        ! Max norm
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_NORM_L1 = 3_i4          ! Sum norm

  !-- Auto-incrementation default constants (P1 fill 2026-05-05)
  REAL(wp), PARAMETER, PUBLIC :: RT_SOLV_AUTO_DT_GROWTH_FACTOR_DEFAULT  = 1.25_wp
  REAL(wp), PARAMETER, PUBLIC :: RT_SOLV_AUTO_DT_CUTBACK_FACTOR_DEFAULT = 0.25_wp
  REAL(wp), PARAMETER, PUBLIC :: RT_SOLV_AUTO_DT_EXPAND_FACTOR_DEFAULT  = 1.50_wp
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_AUTO_DT_TARGET_ITERS_DEFAULT  = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_AUTO_DT_GROWTH_THRESHOLD_DEFAULT = 12_i4

  !-- K·x=f pipeline stage enum (P1 fill)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KXF_STAGE_ASSEMBLE  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KXF_STAGE_FACTORIZE  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KXF_STAGE_SOLVE      = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KXF_STAGE_UPDATENORMS = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_KXF_STAGE_CHECK      = 5_i4

  !-- Step type / procedure type enums (P1 fill)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_STATIC_GENERAL     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_STATIC_RIKS        = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_DYNAMIC_IMPLICIT   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_DYNAMIC_EXPLICIT   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_THERMAL            = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_COUPLED_TEMP_DISP  = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_FREQUENCY          = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_BUCKLE             = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_ACOUSTIC           = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_STEP_TYPE_SUBSPACE           = 10_i4
  
  !-- Convergence criterion types
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_CONV_DISP  = 1_i4  ! Displacement-based
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_CONV_FORCE = 2_i4  ! Force-based
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_CONV_ENERGY = 3_i4 ! Energy-based
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_CONV_MIXED = 4_i4  ! Mixed criteria

  !-- Solver status codes
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_STATUS_NOT_STARTED = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_STATUS_CONVERGED = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_STATUS_DIVERGED = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_STATUS_MAX_ITER = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_SOLV_STATUS_BREAKDOWN = 4_i4
  
  !-----------------------------------------------------------------------------
  ! Desc � cfg (identity + L3 pointers) + itr (runtime-selected methods)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Cfg_Desc
    INTEGER(i4) :: runtime_id = 0_i4
    CHARACTER(LEN=64) :: solver_label = ''
    TYPE(MD_LinearSolver_Desc), POINTER :: md_linear => NULL()
    TYPE(MD_NR_Algo), POINTER :: md_nr => NULL()
    TYPE(MD_Precond_Desc), POINTER :: md_precond => NULL()
    INTEGER(i4) :: n_dofs_total = 0_i4
    INTEGER(i4) :: n_eqns = 0_i4
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_active = .TRUE.
  END TYPE RT_Solv_Cfg_Desc

  TYPE, PUBLIC :: RT_Solv_Itr_Desc_Cache
    INTEGER(i4) :: linear_method = RT_SOLV_LINSOL_DIRECT
    INTEGER(i4) :: nr_strategy = RT_SOLV_NR_FULL
    LOGICAL :: unsymmetric_system = .FALSE.
  END TYPE RT_Solv_Itr_Desc_Cache

  TYPE, PUBLIC :: RT_Solv_Desc
    TYPE(RT_Solv_Cfg_Desc) :: cfg
    TYPE(RT_Solv_Itr_Desc_Cache) :: itr
  END TYPE RT_Solv_Desc

  
  !-----------------------------------------------------------------------------
  ! NR state � stp (cutbacks / totals) + itr (per-NR-iter norms and flags)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Stp_State
    INTEGER(i4) :: n_cutbacks = 0_i4
    INTEGER(i4) :: total_iters = 0_i4
  END TYPE RT_Solv_Stp_State

  ! Per-NR-iteration state (flat %itr; matches RT_Solv_Impl / NRState_* accessors)
  TYPE, PUBLIC :: RT_Solv_Itr_NRState
    INTEGER(i4) :: curr_iter = 0_i4
    INTEGER(i4) :: max_iter_reached = 0_i4
    REAL(wp) :: res_norm_abs = 0.0_wp
    REAL(wp) :: res_norm_rel = 1.0_wp
    REAL(wp) :: disp_norm_abs = 0.0_wp
    REAL(wp) :: disp_norm_rel = 1.0_wp
    REAL(wp) :: energy_norm = 0.0_wp
    REAL(wp) :: res_ref = 1.0_wp
    REAL(wp) :: disp_ref = 1.0_wp
    REAL(wp) :: pnewdt_min = 1.0_wp
    LOGICAL :: converged = .FALSE.
    LOGICAL :: cutback_requested = .FALSE.
    LOGICAL :: severe_discontinuity = .FALSE.
  END TYPE RT_Solv_Itr_NRState

  TYPE, PUBLIC :: RT_Solv_NRState
    TYPE(RT_Solv_Stp_State) :: stp
    TYPE(RT_Solv_Itr_NRState) :: itr
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init => NRState_Init
    PROCEDURE :: Reset => NRState_Reset
    PROCEDURE :: UpdateNorms => NRState_UpdateNorms
  END TYPE RT_Solv_NRState
  
  !-----------------------------------------------------------------------------
  ! Linear state � stp (system / factorization / pointers) + itr (Krylov scratch)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Linear_Stp_State
    INTEGER(i4) :: ndof = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4) :: method = RT_SOLV_LINSOL_DIRECT
    LOGICAL :: unsymmetric = .FALSE.
    LOGICAL :: factorization_available = .FALSE.
    LOGICAL :: reuse_factorization = .FALSE.
    INTEGER(i4) :: factorization_age = 0_i4
    REAL(wp), POINTER :: rhs(:) => NULL()
    REAL(wp), POINTER :: du(:) => NULL()
  END TYPE RT_Solv_Linear_Stp_State

  TYPE, PUBLIC :: RT_Solv_Linear_Itr_State
    INTEGER(i4) :: krylov_iter = 0_i4
    REAL(wp) :: krylov_tol_achieved = 0.0_wp
    REAL(wp) :: residual_initial = 0.0_wp
    REAL(wp) :: residual_final = 0.0_wp
    INTEGER(i4) :: solver_flag = RT_SOLV_STATUS_NOT_STARTED
    LOGICAL :: solved = .FALSE.
  END TYPE RT_Solv_Linear_Itr_State

  TYPE, PUBLIC :: RT_Solv_LinearState
    TYPE(RT_Solv_Linear_Stp_State) :: stp
    TYPE(RT_Solv_Linear_Itr_State) :: itr
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init => LinearState_Init
    PROCEDURE :: Reset => LinearState_Reset
  END TYPE RT_Solv_LinearState

  ! Aggregated NR + linear state for unified SIO bundles (e.g. RT_Solv_Solve_Arg)
  TYPE, PUBLIC :: RT_Solv_State
    TYPE(RT_Solv_NRState) :: nr
    TYPE(RT_Solv_LinearState) :: lin
  END TYPE RT_Solv_State
  
  !-----------------------------------------------------------------------------
  ! Algo -- RT_Solv_Itr_Algo under %itr (mirrors MD_Solver_Algo)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Itr_Algo
    INTEGER(i4) :: nr_max_iter = 16_i4
    INTEGER(i4) :: nr_max_severe = 50_i4
    INTEGER(i4) :: nr_max_cutbacks = 5_i4
    INTEGER(i4) :: nr_tangent_strategy = RT_SOLV_NR_FULL
    INTEGER(i4) :: nr_tangent_interval = 1_i4
    LOGICAL :: use_line_search = .FALSE.
    INTEGER(i4) :: ls_max_iter = 5_i4
    REAL(wp) :: ls_tolerance = 0.5_wp
    REAL(wp) :: cutback_factor = 0.25_wp
    REAL(wp) :: expand_factor = 1.5_wp
    INTEGER(i4) :: linsol_method = RT_SOLV_LINSOL_DIRECT
    INTEGER(i4) :: linsol_max_iter = 300_i4
    REAL(wp) :: linsol_tolerance = 1.0e-10_wp
    LOGICAL :: linsol_unsymmetric = .FALSE.
    INTEGER(i4) :: precond_type = 0_i4
    INTEGER(i4) :: ilu_fill_level = 0_i4
    REAL(wp) :: ilu_drop_tolerance = 1.0e-4_wp
    INTEGER(i4) :: amg_max_levels = 10_i4
    LOGICAL :: rebuild_precond_every_step = .FALSE.
    REAL(wp) :: conv_res_tol_rel = 5.0e-3_wp
    REAL(wp) :: conv_res_tol_abs = 0.0_wp
    REAL(wp) :: conv_disp_tol_rel = 1.0e-2_wp
    REAL(wp) :: conv_disp_tol_abs = 0.0_wp
    INTEGER(i4) :: conv_norm_type = RT_SOLV_NORM_L2
    LOGICAL :: conv_check_energy = .FALSE.
    REAL(wp) :: conv_energy_tol = 1.0e-5_wp
    REAL(wp) :: zero_force_tol = 1.0e-10_wp
    REAL(wp) :: singular_pivot_tol = 1.0e-12_wp
  END TYPE RT_Solv_Itr_Algo

  TYPE, PUBLIC :: RT_Solv
    TYPE(RT_Solv_Itr_Algo) :: itr
  CONTAINS
    PROCEDURE :: Init => SolvAlgo_Init
    PROCEDURE :: SetNRParams => SolvAlgo_SetNR
    PROCEDURE :: SetLinearParams => SolvAlgo_SetLinear
  END TYPE RT_Solv
  
  !-----------------------------------------------------------------------------
  ! Ctx � stp (step/incr/time/mesh/parallel) + itr (NR iter flags)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Stp_Ctx
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: incr_id = 0_i4
    REAL(wp) :: step_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    REAL(wp) :: time_increment = 0.0_wp
    REAL(wp) :: prev_time_increment = 0.0_wp
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_active_dofs = 0_i4
    LOGICAL :: is_first_incr = .FALSE.
    INTEGER(i4) :: thread_id = 0_i4
    INTEGER(i4) :: n_threads = 1_i4
  END TYPE RT_Solv_Stp_Ctx

  TYPE, PUBLIC :: RT_Solv_Itr_Ctx
    INTEGER(i4) :: nr_iter_id = 0_i4
    LOGICAL :: is_first_iter = .FALSE.
    LOGICAL :: force_convergence_check = .FALSE.
  END TYPE RT_Solv_Itr_Ctx

  TYPE, PUBLIC :: RT_Solv_Ctx
    TYPE(RT_Solv_Stp_Ctx) :: stp
    TYPE(RT_Solv_Itr_Ctx) :: itr
  CONTAINS
    PROCEDURE :: Init => SolvCtx_Init
    PROCEDURE :: Update => SolvCtx_Update
  END TYPE RT_Solv_Ctx
  
  !-----------------------------------------------------------------------------
  ! Convergence ctx � tolerances and scratch under %itr
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Conv_Itr_Ctx
    REAL(wp) :: res_tol_rel = 5.0e-3_wp
    REAL(wp) :: res_tol_abs = 0.0_wp
    REAL(wp) :: disp_tol_rel = 1.0e-2_wp
    REAL(wp) :: disp_tol_abs = 0.0_wp
    REAL(wp) :: energy_tol = 1.0e-5_wp
    INTEGER(i4) :: res_norm_type = RT_SOLV_NORM_L2
    INTEGER(i4) :: disp_norm_type = RT_SOLV_NORM_L2
    LOGICAL :: check_energy = .FALSE.
    LOGICAL :: severe_discontinuity_active = .FALSE.
    REAL(wp) :: computed_res_norm = 0.0_wp
    REAL(wp) :: computed_disp_norm = 0.0_wp
    REAL(wp) :: computed_energy_norm = 0.0_wp
    LOGICAL :: converged = .FALSE.
    LOGICAL :: check_performed = .FALSE.
  END TYPE RT_Solv_Conv_Itr_Ctx

  TYPE, PUBLIC :: RT_Solv_ConvergenceCtx
    TYPE(RT_Solv_Conv_Itr_Ctx) :: itr
  CONTAINS
    PROCEDURE :: Init => ConvCtx_Init
    PROCEDURE :: Evaluate => ConvCtx_Evaluate
    PROCEDURE :: Reset => ConvCtx_Reset
  END TYPE RT_Solv_ConvergenceCtx
  
CONTAINS

  !=============================================================================
  ! CSR Matrix Operations
  !=============================================================================
  
  subroutine RT_CSR_Free(A)
    !! Free CSR matrix memory
    type(RT_CSRMatrix), intent(inout) :: A
    if (A%init) call csr_destroy(A)
  end subroutine RT_CSR_Free

  subroutine csr_destroy(A)
    !! Internal procedure to destroy CSR matrix
    type(RT_CSRMatrix), intent(inout) :: A

    if (allocated(A%rowPtr)) deallocate(A%rowPtr)
    if (allocated(A%colInd)) deallocate(A%colInd)
    if (allocated(A%values)) deallocate(A%values)
    A%nRows = 0_i4
    A%nCols = 0_i4
    A%nnz = 0_i4
    A%is_symmetric = .false.
    A%init = .false.
  end subroutine csr_destroy

  !-----------------------------------------------------------------------------
  ! RT_Solv_NRState Methods
  !-----------------------------------------------------------------------------
  
  SUBROUTINE NRState_Init(self)
    CLASS(RT_Solv_NRState), INTENT(INOUT) :: self

    self%stp%n_cutbacks = 0_i4
    self%stp%total_iters = 0_i4
    self%itr%curr_iter = 0_i4
    self%itr%max_iter_reached = 0_i4
    self%itr%res_norm_abs = 0.0_wp
    self%itr%res_norm_rel = 1.0_wp
    self%itr%disp_norm_abs = 0.0_wp
    self%itr%disp_norm_rel = 1.0_wp
    self%itr%energy_norm = 0.0_wp
    self%itr%res_ref = 1.0_wp
    self%itr%disp_ref = 1.0_wp
    self%itr%pnewdt_min = 1.0_wp
    self%itr%converged = .FALSE.
    self%itr%cutback_requested = .FALSE.
    self%itr%severe_discontinuity = .FALSE.
  END SUBROUTINE NRState_Init

  SUBROUTINE NRState_Reset(self)
    CLASS(RT_Solv_NRState), INTENT(INOUT) :: self

    self%stp%n_cutbacks = 0_i4
    self%itr%curr_iter = 0_i4
    self%itr%res_norm_abs = 0.0_wp
    self%itr%res_norm_rel = 1.0_wp
    self%itr%disp_norm_abs = 0.0_wp
    self%itr%disp_norm_rel = 1.0_wp
    self%itr%converged = .FALSE.
    self%itr%cutback_requested = .FALSE.
  END SUBROUTINE NRState_Reset

  SUBROUTINE NRState_UpdateNorms(self, res_abs, disp_abs, res_ref, disp_ref)
    CLASS(RT_Solv_NRState), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: res_abs, disp_abs
    REAL(wp), INTENT(IN), OPTIONAL :: res_ref, disp_ref

    self%itr%res_norm_abs = res_abs
    self%itr%disp_norm_abs = disp_abs

    IF (PRESENT(res_ref) .AND. res_ref > 0.0_wp) THEN
      self%itr%res_norm_rel = res_abs / res_ref
      self%itr%res_ref = res_ref
    ELSE IF (self%itr%curr_iter == 1) THEN
      self%itr%res_ref = res_abs
      self%itr%res_norm_rel = 1.0_wp
    END IF

    IF (PRESENT(disp_ref) .AND. disp_ref > 0.0_wp) THEN
      self%itr%disp_norm_rel = disp_abs / disp_ref
      self%itr%disp_ref = disp_ref
    ELSE IF (self%itr%curr_iter == 1) THEN
      self%itr%disp_ref = disp_abs
      self%itr%disp_norm_rel = 1.0_wp
    END IF

  END SUBROUTINE NRState_UpdateNorms

  !-----------------------------------------------------------------------------
  ! RT_Solv_LinearState Methods
  !-----------------------------------------------------------------------------

  SUBROUTINE LinearState_Init(self, ndof, method)
    CLASS(RT_Solv_LinearState), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: ndof
    INTEGER(i4), INTENT(IN), OPTIONAL :: method

    self%stp%ndof = 0_i4
    self%stp%nnz = 0_i4
    self%itr%krylov_iter = 0_i4
    self%itr%krylov_tol_achieved = 0.0_wp
    self%stp%factorization_available = .FALSE.
    self%stp%reuse_factorization = .FALSE.
    self%itr%solved = .FALSE.

    IF (PRESENT(ndof)) self%stp%ndof = ndof
    IF (PRESENT(method)) self%stp%method = method

  END SUBROUTINE LinearState_Init

  SUBROUTINE LinearState_Reset(self)
    CLASS(RT_Solv_LinearState), INTENT(INOUT) :: self

    self%itr%krylov_iter = 0_i4
    self%itr%krylov_tol_achieved = 0.0_wp
    self%itr%residual_initial = 0.0_wp
    self%itr%residual_final = 0.0_wp
    self%itr%solver_flag = RT_SOLV_STATUS_NOT_STARTED
    self%itr%solved = .FALSE.

  END SUBROUTINE LinearState_Reset

  !-----------------------------------------------------------------------------
  ! RT_Solv Methods
  !-----------------------------------------------------------------------------

  SUBROUTINE SolvAlgo_Init(self)
    CLASS(RT_Solv), INTENT(INOUT) :: self

    self%itr%nr_max_iter = 16_i4
    self%itr%nr_max_cutbacks = 5_i4
    self%itr%nr_tangent_strategy = RT_SOLV_NR_FULL
    self%itr%use_line_search = .FALSE.
    self%itr%cutback_factor = 0.25_wp
    self%itr%linsol_method = RT_SOLV_LINSOL_DIRECT
    self%itr%conv_res_tol_rel = 5.0e-3_wp
    self%itr%conv_disp_tol_rel = 1.0e-2_wp
    self%itr%conv_norm_type = RT_SOLV_NORM_L2

  END SUBROUTINE SolvAlgo_Init

  SUBROUTINE SolvAlgo_SetNR(self, max_iter, max_cutbacks, tangent_strategy, use_ls)
    CLASS(RT_Solv), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter, max_cutbacks, tangent_strategy
    LOGICAL, INTENT(IN), OPTIONAL :: use_ls

    IF (PRESENT(max_iter)) self%itr%nr_max_iter = max_iter
    IF (PRESENT(max_cutbacks)) self%itr%nr_max_cutbacks = max_cutbacks
    IF (PRESENT(tangent_strategy)) self%itr%nr_tangent_strategy = tangent_strategy
    IF (PRESENT(use_ls)) self%itr%use_line_search = use_ls

  END SUBROUTINE SolvAlgo_SetNR

  SUBROUTINE SolvAlgo_SetLinear(self, method, max_iter, tolerance, unsymm)
    CLASS(RT_Solv), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN), OPTIONAL :: method
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter
    REAL(wp), INTENT(IN), OPTIONAL :: tolerance
    LOGICAL, INTENT(IN), OPTIONAL :: unsymm

    IF (PRESENT(method)) self%itr%linsol_method = method
    IF (PRESENT(max_iter)) self%itr%linsol_max_iter = max_iter
    IF (PRESENT(tolerance)) self%itr%linsol_tolerance = tolerance
    IF (PRESENT(unsymm)) self%itr%linsol_unsymmetric = unsymm

  END SUBROUTINE SolvAlgo_SetLinear

  !-----------------------------------------------------------------------------
  ! RT_Solv_Ctx Methods
  !-----------------------------------------------------------------------------

  SUBROUTINE SolvCtx_Init(self)
    CLASS(RT_Solv_Ctx), INTENT(INOUT) :: self

    self%stp%step_id = 0_i4
    self%stp%incr_id = 0_i4
    self%itr%nr_iter_id = 0_i4
    self%stp%step_time = 0.0_wp
    self%stp%total_time = 0.0_wp
    self%stp%time_increment = 0.0_wp
    self%stp%is_first_incr = .FALSE.
    self%itr%is_first_iter = .FALSE.

  END SUBROUTINE SolvCtx_Init

  SUBROUTINE SolvCtx_Update(self, step, incr, time, dt, nr_iter)
    CLASS(RT_Solv_Ctx), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: step, incr, nr_iter
    REAL(wp), INTENT(IN) :: time, dt

    self%stp%step_id = step
    self%stp%incr_id = incr
    self%itr%nr_iter_id = nr_iter
    self%stp%step_time = time
    self%stp%total_time = time
    self%stp%prev_time_increment = self%stp%time_increment
    self%stp%time_increment = dt
    self%stp%is_first_incr = (incr == 1)
    self%itr%is_first_iter = (nr_iter == 1)

  END SUBROUTINE SolvCtx_Update

  !-----------------------------------------------------------------------------
  ! RT_Solv_ConvergenceCtx Methods
  !-----------------------------------------------------------------------------

  SUBROUTINE ConvCtx_Init(self)
    CLASS(RT_Solv_ConvergenceCtx), INTENT(INOUT) :: self

    self%itr%res_tol_rel = 5.0e-3_wp
    self%itr%res_tol_abs = 0.0_wp
    self%itr%disp_tol_rel = 1.0e-2_wp
    self%itr%disp_tol_abs = 0.0_wp
    self%itr%energy_tol = 1.0e-5_wp
    self%itr%res_norm_type = RT_SOLV_NORM_L2
    self%itr%disp_norm_type = RT_SOLV_NORM_L2
    self%itr%check_energy = .FALSE.
    self%itr%computed_res_norm = 0.0_wp
    self%itr%computed_disp_norm = 0.0_wp
    self%itr%converged = .FALSE.

  END SUBROUTINE ConvCtx_Init

  FUNCTION ConvCtx_Evaluate(self, res_norm, disp_norm, energy_norm) RESULT(converged)
    CLASS(RT_Solv_ConvergenceCtx), INTENT(INOUT) :: self
    REAL(wp), INTENT(IN) :: res_norm, disp_norm, energy_norm
    LOGICAL :: converged

    self%itr%computed_res_norm = res_norm
    self%itr%computed_disp_norm = disp_norm
    self%itr%computed_energy_norm = energy_norm
    self%itr%check_performed = .TRUE.

    converged = .TRUE.

    IF (self%itr%res_tol_abs > 0.0_wp) THEN
      IF (res_norm > self%itr%res_tol_abs .AND. res_norm > self%itr%res_tol_rel) THEN
        converged = .FALSE.
      END IF
    ELSE
      IF (res_norm > self%itr%res_tol_rel) converged = .FALSE.
    END IF

    IF (self%itr%disp_tol_abs > 0.0_wp) THEN
      IF (disp_norm > self%itr%disp_tol_abs .AND. disp_norm > self%itr%disp_tol_rel) THEN
        converged = .FALSE.
      END IF
    ELSE
      IF (disp_norm > self%itr%disp_tol_rel) converged = .FALSE.
    END IF

    IF (self%itr%check_energy) THEN
      IF (energy_norm > self%itr%energy_tol) converged = .FALSE.
    END IF

    self%itr%converged = converged

  END FUNCTION ConvCtx_Evaluate

  SUBROUTINE ConvCtx_Reset(self)
    CLASS(RT_Solv_ConvergenceCtx), INTENT(INOUT) :: self

    self%itr%computed_res_norm = 0.0_wp
    self%itr%computed_disp_norm = 0.0_wp
    self%itr%computed_energy_norm = 0.0_wp
    self%itr%converged = .FALSE.
    self%itr%check_performed = .FALSE.

  END SUBROUTINE ConvCtx_Reset

!===============================================================================
! SIO unified Arg types for Solver domain
!===============================================================================
TYPE, PUBLIC :: RT_Solv_Solve_Arg
  TYPE(RT_Solv_Desc) :: desc             ! [IN]  solver descriptor
  TYPE(RT_Solv_State) :: state           ! [INOUT] NR + linear state bundle
  TYPE(RT_Solv) :: algo                  ! [IN]  algorithm params (%itr = RT_Solv_Itr_Algo)

  ! [IN] solve parameters
  REAL(wp), ALLOCATABLE :: k_matrix(:,:)   ! [IN]  global stiffness matrix
  REAL(wp), ALLOCATABLE :: f_vector(:)     ! [IN]  global force vector
  REAL(wp), ALLOCATABLE :: u_vector(:)     ! [INOUT] displacement vector

  ! [IN] solver controls
  INTEGER(i4) :: max_iter                ! [IN]  maximum iterations
  REAL(wp) :: tolerance                  ! [IN]  convergence tolerance

  ! [OUT] solve results
  LOGICAL :: converged                   ! [OUT] convergence flag
  INTEGER(i4) :: n_iterations            ! [OUT] iterations taken
  INTEGER(i4) :: status_code             ! [OUT] solve status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE RT_Solv_Solve_Arg

end module RT_Solv_Def
