!===============================================================================
! MODULE: RT_Solv_Proc
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Proc
! BRIEF:  Structured _In/_Out IO interfaces for solver operations (Principle #14)
!===============================================================================
!
! Process:
!   Provides TYPE bundles for six-parameter convention:
!   RT_Solv_Init_In/Out, RT_Solv_Equilibrium_In/Out,
!   RT_Solv_Linear_In/Out, RT_Solv_Convergence_In/Out,
!   RT_Solv_Cutback_In/Out + abstract interfaces.
!
! Status: SIO-REFACTORED | Last verified: 2026-04-29
!===============================================================================
MODULE RT_Solv_Proc
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK, IF_STATUS_ERROR
  USE RT_Solv_Def, ONLY: RT_Solv_Desc, RT_Solv_NRState, &
                           RT_Solv_LinearState, RT_Solv, RT_Solv_Ctx, &
                           RT_Solv_ConvergenceCtx
  IMPLICIT NONE
  PRIVATE
  
  ! _In/_Out IO types (Principle #14: six-parameter convention)
  PUBLIC :: RT_Solv_Init_In,          RT_Solv_Init_Out
  PUBLIC :: RT_Solv_Equilibrium_In,   RT_Solv_Equilibrium_Out
  PUBLIC :: RT_Solv_Linear_In,        RT_Solv_Linear_Out
  PUBLIC :: RT_Solv_Convergence_In,   RT_Solv_Convergence_Out
  PUBLIC :: RT_Solv_Cutback_In,       RT_Solv_Cutback_Out
  ! Abstract interfaces (six-parameter convention)
  PUBLIC :: RT_Solv_Init_Interface
  PUBLIC :: RT_Solv_Equilibrium_Interface
  PUBLIC :: RT_Solv_Linear_Interface
  PUBLIC :: RT_Solv_Convergence_Interface
  PUBLIC :: RT_Solv_Cutback_Interface
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Init_In -- Input Structure for Solver Initialization
  ! NOTE: Four-type references bundled as POINTERs for Impl convenience.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Init_In
    ! System size
    INTEGER(i4) :: n_dofs     = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_nodes    = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_Desc),   POINTER :: desc => NULL()
    TYPE(RT_Solv_NRState),     POINTER :: nr_state => NULL()
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    
    ! Options
    LOGICAL     :: validate_config           = .TRUE.
    LOGICAL     :: preallocate_solver_memory = .FALSE.
    
    ! Parallel context
    INTEGER(i4) :: n_threads  = 1_i4
    INTEGER(i4) :: comm_rank  = 0_i4
    INTEGER(i4) :: comm_size  = 1_i4
  END TYPE RT_Solv_Init_In
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Init_Out -- Output Structure for Solver Initialization
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Init_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Diagnostics
    LOGICAL :: initialized = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    INTEGER(i4) :: solver_memory_mb = 0_i4
    INTEGER(i4) :: max_dofs_supported = 0_i4
  END TYPE RT_Solv_Init_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Equilibrium_In -- Input Structure for Equilibrium Iteration
  ! NOTE: POINTER fields for large vectors are non-owning; caller manages
  !       lifetime. Four-type references bundled as POINTERs.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Equilibrium_In
    ! [NON_OWNING_PTR] External load vector [ndof]; caller-owned
    REAL(wp), POINTER :: external_force(:) => NULL()
    ! [NON_OWNING_PTR] Internal force vector [ndof]; caller-owned
    REAL(wp), POINTER :: internal_force(:) => NULL()
    ! [NON_OWNING_PTR] Current displacement [ndof]; caller-owned
    REAL(wp), POINTER :: displacement(:)  => NULL()
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_Desc),   POINTER :: desc => NULL()
    TYPE(RT_Solv_NRState),     POINTER :: nr_state => NULL()
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    TYPE(RT_Solv_Ctx),         POINTER :: ctx => NULL()
    
    ! Options
    LOGICAL :: compute_tangent   = .TRUE.
    LOGICAL :: use_line_search   = .FALSE.
    LOGICAL :: check_convergence = .TRUE.
  END TYPE RT_Solv_Equilibrium_In
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Equilibrium_Out -- Output Structure for Equilibrium Iteration
  ! NOTE: ALLOCATABLE is allowed on _Out TYPE fields.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Equilibrium_Out
    ! Output vectors (ALLOCATABLE allowed on _Out side)
    REAL(wp), ALLOCATABLE :: residual(:)                ! [ndof] out-of-balance force
    REAL(wp), ALLOCATABLE :: displacement_correction(:) ! [ndof] du
    
    ! Convergence
    LOGICAL     :: converged          = .FALSE.
    LOGICAL     :: cutback_requested  = .FALSE.
    REAL(wp)    :: pnewdt             = 1.0_wp
    
    ! Statistics
    INTEGER(i4) :: nr_iterations = 0_i4
    REAL(wp)    :: res_norm      = 0.0_wp
    REAL(wp)    :: disp_norm     = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Equilibrium_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Linear_In -- Input Structure for Linear System Solve
  ! NOTE: CSR matrix data as non-owning pointers for L2_NM dispatch.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Linear_In
    ! System matrix handle (opaque handle to assembled K matrix)
    INTEGER(i4) :: matrix_handle = -1_i4
    ! [NON_OWNING_PTR] RHS vector [ndof]; caller-owned
    REAL(wp), POINTER :: rhs(:) => NULL()
    
    ! CSR matrix data (non-owning pointers to assembled K)
    INTEGER(i4), POINTER :: K_row_ptr(:) => NULL()
    INTEGER(i4), POINTER :: K_col_idx(:) => NULL()
    REAL(wp),    POINTER :: K_values(:)  => NULL()
    INTEGER(i4) :: n_dof = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    TYPE(RT_Solv_Ctx),         POINTER :: ctx => NULL()
    
    ! Options
    LOGICAL :: reuse_factorization       = .FALSE.
    LOGICAL :: compute_condition_number  = .FALSE.
  END TYPE RT_Solv_Linear_In
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Linear_Out -- Output Structure for Linear System Solve
  ! NOTE: ALLOCATABLE allowed on _Out side.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Linear_Out
    ! Solution vector (ALLOCATABLE on _Out side)
    REAL(wp), ALLOCATABLE :: solution(:)          ! [ndof] du
    
    ! Solver statistics
    INTEGER(i4) :: iterations_used      = 0_i4
    REAL(wp)    :: achieved_tolerance   = 0.0_wp
    REAL(wp)    :: condition_number_est = 0.0_wp
    
    ! Status
    INTEGER(i4) :: solver_flag         = 0_i4
    LOGICAL     :: solved_successfully = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Linear_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Convergence_In -- Input Structure for Convergence Check
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Convergence_In
    ! Current norms
    REAL(wp) :: res_norm_abs  = 0.0_wp
    REAL(wp) :: disp_norm_abs = 0.0_wp
    REAL(wp) :: energy_norm   = 0.0_wp
    
    ! Reference norms
    REAL(wp) :: res_norm_ref  = 1.0_wp
    REAL(wp) :: disp_norm_ref = 1.0_wp
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_NRState),        POINTER :: nr_state => NULL()
    TYPE(RT_Solv),                POINTER :: algo => NULL()
    TYPE(RT_Solv_ConvergenceCtx), POINTER :: conv_ctx => NULL()
    
    ! Force flags
    LOGICAL :: force_check = .FALSE.
  END TYPE RT_Solv_Convergence_In
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Convergence_Out -- Output Structure for Convergence Check
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Convergence_Out
    ! Result
    LOGICAL  :: converged       = .FALSE.
    LOGICAL  :: check_performed = .FALSE.
    
    ! Criteria status
    LOGICAL  :: res_criterion_satisfied    = .FALSE.
    LOGICAL  :: disp_criterion_satisfied   = .FALSE.
    LOGICAL  :: energy_criterion_satisfied = .FALSE.
    
    ! Computed values
    REAL(wp) :: computed_res_rel  = 0.0_wp
    REAL(wp) :: computed_disp_rel = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Convergence_Out
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Cutback_In -- Input Structure for Cutback Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Cutback_In
    ! Current state
    REAL(wp)    :: current_dt           = 0.0_wp
    REAL(wp)    :: pnewdt_from_physics  = 1.0_wp
    
    ! Cutback reason: 0=None, 1=Divergence, 2=Physics
    INTEGER(i4) :: cutback_reason = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_NRState), POINTER :: nr_state => NULL()
    TYPE(RT_Solv),         POINTER :: algo => NULL()
    
    ! Options
    LOGICAL     :: allow_expansion = .TRUE.
  END TYPE RT_Solv_Cutback_In
  
  !-----------------------------------------------------------------------------
  ! RT_Solv_Cutback_Out -- Output Structure for Cutback Control
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Solv_Cutback_Out
    ! New time increment
    REAL(wp)    :: new_dt        = 0.0_wp
    REAL(wp)    :: dt_multiplier = 1.0_wp
    
    ! Status flags
    LOGICAL     :: cutback_applied      = .FALSE.
    LOGICAL     :: expansion_applied    = .FALSE.
    INTEGER(i4) :: n_cutbacks           = 0_i4
    LOGICAL     :: max_cutbacks_reached = .FALSE.
    
    ! Error status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Cutback_Out
  
  !-----------------------------------------------------------------------------
  ! Abstract Interfaces for Solver Operations (six-parameter convention)
  ! Principle #14 v2.0: (desc, state, algo, ctx, inp, out)
  !-----------------------------------------------------------------------------
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Solv_Init_Interface(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Solv_Desc, RT_Solv_NRState, RT_Solv, RT_Solv_Ctx
      IMPORT :: RT_Solv_Init_In, RT_Solv_Init_Out
      TYPE(RT_Solv_Desc), INTENT(INOUT) :: desc
      TYPE(RT_Solv_NRState),   INTENT(INOUT) :: state
      TYPE(RT_Solv),      INTENT(IN)    :: algo
      TYPE(RT_Solv_Ctx),       INTENT(INOUT) :: ctx
      TYPE(RT_Solv_Init_In),   INTENT(IN)    :: inp
      TYPE(RT_Solv_Init_Out),  INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Solv_Equilibrium_Interface(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Solv_Desc, RT_Solv_NRState, RT_Solv, RT_Solv_Ctx
      IMPORT :: RT_Solv_Equilibrium_In, RT_Solv_Equilibrium_Out
      TYPE(RT_Solv_Desc),       INTENT(INOUT) :: desc
      TYPE(RT_Solv_NRState),         INTENT(INOUT) :: state
      TYPE(RT_Solv),            INTENT(IN)    :: algo
      TYPE(RT_Solv_Ctx),             INTENT(INOUT) :: ctx
      TYPE(RT_Solv_Equilibrium_In),  INTENT(IN)    :: inp
      TYPE(RT_Solv_Equilibrium_Out), INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Solv_Linear_Interface(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Solv_Desc, RT_Solv_LinearState, RT_Solv, RT_Solv_Ctx
      IMPORT :: RT_Solv_Linear_In, RT_Solv_Linear_Out
      TYPE(RT_Solv_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_Solv_LinearState),INTENT(INOUT) :: state
      TYPE(RT_Solv),       INTENT(IN)    :: algo
      TYPE(RT_Solv_Ctx),        INTENT(INOUT) :: ctx
      TYPE(RT_Solv_Linear_In),  INTENT(IN)    :: inp
      TYPE(RT_Solv_Linear_Out), INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Solv_Convergence_Interface(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Solv_Desc, RT_Solv_NRState, RT_Solv, RT_Solv_Ctx
      IMPORT :: RT_Solv_Convergence_In, RT_Solv_Convergence_Out
      TYPE(RT_Solv_Desc),      INTENT(INOUT) :: desc
      TYPE(RT_Solv_NRState),        INTENT(INOUT) :: state
      TYPE(RT_Solv),           INTENT(IN)    :: algo
      TYPE(RT_Solv_Ctx),            INTENT(INOUT) :: ctx
      TYPE(RT_Solv_Convergence_In), INTENT(IN)    :: inp
      TYPE(RT_Solv_Convergence_Out),INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE
  
  ABSTRACT INTERFACE
    SUBROUTINE RT_Solv_Cutback_Interface(desc, state, algo, ctx, inp, out)
      IMPORT :: RT_Solv_Desc, RT_Solv_NRState, RT_Solv, RT_Solv_Ctx
      IMPORT :: RT_Solv_Cutback_In, RT_Solv_Cutback_Out
      TYPE(RT_Solv_Desc),  INTENT(INOUT) :: desc
      TYPE(RT_Solv_NRState),    INTENT(INOUT) :: state
      TYPE(RT_Solv),       INTENT(IN)    :: algo
      TYPE(RT_Solv_Ctx),        INTENT(INOUT) :: ctx
      TYPE(RT_Solv_Cutback_In), INTENT(IN)    :: inp
      TYPE(RT_Solv_Cutback_Out),INTENT(OUT)   :: out
    END SUBROUTINE
  END INTERFACE
  
END MODULE RT_Solv_Proc
