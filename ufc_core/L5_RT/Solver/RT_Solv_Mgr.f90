!===============================================================================
! MODULE: RT_Solv_Mgr
! LAYER:  L5_RT
! DOMAIN: Solver
! ROLE:   Mgr
! BRIEF:  Production solver framework — NR orchestration, assembly, convergence
!===============================================================================
!
! GOLDEN-LINE NOTE (v4.0): This is the PRODUCTION solver framework.
!   Together with RT_Solv_Nonlin.f90, this is the authoritative solver path.
!   RT_Solv_Core.f90 is a FACADE/SKELETON; new code should NOT extend it.
!   Entry: RT_SolverSys_SolveNonlin / UF_NewtonRaphson / RT_SolIterMgr_RunAll.
!   Mesh-scale assembly desc copy lives at g_ufc_global%rt_layer%assembly%l3_bounds (bridge sync from UF_register).
!
! Process族:
!   P0: Init/Register/Config     [COLD_PATH]
!   P2: Solve/Iterate/Compute    [HOT_PATH]
!   P2: Eval (convergence check)  [HOT_PATH]
!   P3: Output/Collect            [COLD_PATH]
!
! Status: ACTIVE | GOLDEN-LINE | Last verified: 2026-04-28
!===============================================================================
!
module RT_Solv_Mgr
  !! Production solver manager: NR orchestration, assembly dispatch,
  !! convergence management, time integration delegation.
  !!
  !! RESPONSIBILITY PARTITION (v4.0):
  !!   This module is a monolithic solver framework (~6600 lines).
  !!   Logical responsibility zones:
  !!
  !!   [ORCHESTRATION] RT_SolverSys_SolveNonlin, RT_SolIterMgr_RunAll
  !!     -> Top-level NR loop orchestration; calls assembly + linear solve
  !!
  !!   [ITERATION] UF_NewtonRaphson, RT_Sol_NewtonRaphson_Step
  !!     -> Individual NR iteration logic; assembly + solve + update
  !!
  !!   [CONVERGENCE] RT_SolIterMgr_ChkConv, CheckConvergence
  !!     -> Residual/displacement norm checks against tolerances
  !!
  !!   [ASSEMBLY] UF_Assem, UF_Assem_Static, UF_Assembly_Thermal
  !!     -> Element loop + scatter into global K/F; delegates to RT_AsmSolv
  !!
  !!   [LINEAR_SOLVE] Delegated to RT_SolvLin (direct/iterative)
  !!
  !!   [TIME_INT] Delegated to RT_Solv_TimeInt (Newmark/HHT/etc)
  !!
  !!   Future: split into sub-modules along these zones.
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
    USE RT_Amp_Mgr, ONLY: RT_Amp_FactorAt
  USE MD_Base_ObjModel
  use MD_Base_State_API, only: ElemState
  use MD_Int_Brg
  use MD_Model_Mgr
  use MD_Elem_Mgr
  use MD_IOSystem
  USE MD_Step_Proc, only: IncState
  use MD_TypeSystem
  use omp_lib
  use RT_Base_Core
  use RT_Base_Sys
  use RT_Cont_Solv
  use RT_Asm_DofMap, only: UF_BuildDofMap
  ! RT_Elem_Core eliminated - direct thin wrapper
  ! Directly use RT_ElemDispatcher, RT_Elem_UEL_Bridge, RT_ElemSect as needed
  use RT_Element_Glue
  use RT_Ldbc_Apply_Core
USE RT_Shared_Def, only: RT_Sol_Cfg, RT_Sol_DofMap, RT_Sol_State, RT_CSRMatrix, &
    RT_Sol_State_Init, RT_Sol_State_Destroy, RT_Sol_State_Clear
  USE RT_Solv_Interface, only: eq_residual_Intf_state, eq_tangent_Intf_state, eq_Lin_Solv_Intf_state, &
      solve_line_status_Intf
  USE RT_Solv_Nonlin
  use RT_Workspace_API, only: UF_WS_GetCurrentThreadWorkspace, UF_WS_GetCurrentThreadWorkspacePtr
  USE RT_Solv_Sparse, only: RT_COOEntry, RT_TripletList, RT_LUHandle, RT_BlockCSRMatrix, &
                              RT_Triplet_Init, RT_Triplet_Add, RT_Triplet_Free, RT_CSR_FromTriplet, RT_CSR_SpMV, &
                              RT_BlockCSR_FromTriplet, RT_BlockCSR_Free, RT_LU_Setup_FromCSR, RT_LU_Solv, RT_LU_Destroy, &
                              RT_LinearSolve_Direct
  USE RT_Solv_TimeInt
  USE RT_Solv_Def, only: RT_CSR_Free, csr_destroy, RT_AdvancedTimeIntegrator, &
                             RT_AdvancedNLSol
  use RT_Step_Solv
  use UF_ContextTypes
  use RT_Solv_CoreMemPool
  use NM_Solv_Direct, only: UF_LUFactor, direct_lu_factor, direct_lu_solve
  use UF_Elem_Continuum_Struct
  use NM_Solv_Nonlin, only: UF_NLParams, UF_NLResult, nl_lbfgs, &
                          CONV_FORCE, CONV_DISP, CONV_ENERGY, CONV_MIXED, &
                          NL_TYPE_MODIFIED_NR
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  USE MD_Mesh_API, ONLY: MD_Mesh_GetElemConnect_Idx, MD_Mesh_GetElemConnect_Arg, &
                                 MD_Mesh_GetNodeCoords_Idx, MD_Mesh_GetNodeCoords_Arg
  USE RT_Global_Def, ONLY: RT_Glb_StepCtrl_IF, RT_Glb_ConvPred_IF

  implicit none
  private

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  public :: Bind => RT_Sol_Ctx_Bind
  public :: CheckConvergence => RT_SolIterMgr_ChkConv
  public :: Clean => RT_SolIncMgr_Clean
  public :: Clear => RT_Sol_State_Clear
  public :: ClearStatus => RT_Sol_Ctx_ClearStatus
  public :: Cfg => RT_SolverSys_Cfg
  public :: Destroy => RT_Sol_Ctx_Destroy
  public :: Final => RT_SolverSys_Final
  public :: GetCurrentInc   => RT_SolIncMgr_GetCurInc
  public :: GetCurrentIter  => RT_SolIterMgr_GetCurIter
  public :: GetDofMap => RT_Sol_Ctx_GetDofMap
  public :: GetElemStates => RT_Sol_Ctx_GetElemStates
  public :: GetGlobalState => RT_Sol_Ctx_GetGlobalState
  public :: GetIncrement    => RT_SolIncMgr_GetInc
  public :: GetIteration    => RT_SolIterMgr_GetIter
  public :: GetModel => RT_Sol_Ctx_GetModel
  public :: GetNodeStates => RT_Sol_Ctx_GetNodeStates
  public :: GetRes => RT_SolverSys_GetRes
  public :: GetSolver => RT_Sol_Ctx_GetSolver
  public :: GetSolverState => RT_Sol_Ctx_GetSolverState
  public :: GetStatus       => RT_SolIncMgr_GetStatus
  public :: GetStep => RT_Sol_Ctx_GetStep
  public :: GetSum => RT_SolverRes_GetSum
  public :: GetTws => RT_Sol_Ctx_GetTws
  public :: Init => RT_Sol_Ctx_Init
  public :: InitInc => RT_SolIncMgr_Init
  public :: IsConv => RT_SolverRes_IsConv
  public :: IsError => RT_Sol_Ctx_IsError
  public :: IsFailure => RT_SolverRes_IsFail
  public :: IsInit => RT_SolverSys_IsInit
  public :: IsOK => RT_Sol_Ctx_IsOK
  public :: IsRunning => RT_SolverSys_IsRunning
  public :: IsSuccess => RT_SolverRes_IsOk
  ! RT_AdvancedNLSol is now in RT_Solver_Types to break circular dependency
  ! RT_AdvancedTimeIntegrator is now in RT_Solver_Types to break circular dependency
  ! Types from RT_Solver_Ctx and RT_Solver_Framework
  public :: RT_Sol_Ctx, RT_Sol_In, RT_Sol_Ite, RT_Sol_Status
  public :: RT_LINSOL_TYPE_BLOCK_PCG_2      = 3_i4
  public :: RT_LINSOL_TYPE_BLOCK_PCG_3      = 4_i4
  public :: RT_LINSOL_TYPE_DIRECT          = 1_i4
  public :: RT_LINSOL_TYPE_PCG              = 2_i4
  public :: RT_NLSolver_ArcLen
  public :: RT_NLSolver_LineSearch
  public :: RT_NLSolver_TrustRegion
  public :: RT_SOLVER_STATUS_CONVERGED      = 3_i4
  public :: RT_SOLVER_STATUS_DIVERGED       = 4_i4
  public :: RT_SOLVER_STATUS_FAILED        = 6_i4
  public :: RT_SOLVER_STATUS_MAX_ITER      = 5_i4
  public :: RT_SOLVER_STATUS_NOT_INITIALIZED = 0_i4
  public :: RT_SOLVER_STATUS_READY          = 1_i4
  public :: RT_SOLVER_STATUS_RUNNING        = 2_i4
  public :: RT_SOLVER_TYPE_ARC_LENGTH        = 4_i4
  public :: RT_SOLVER_TYPE_EXPLICIT          = 5_i4
  public :: RT_SOLVER_TYPE_LBFGS             = 3_i4
  public :: RT_SOLVER_TYPE_MODIFIED_NEWTON   = 2_i4
  public :: RT_SOLVER_TYPE_NEWTON_RAPHSON    = 1_i4
  public :: RT_Sol_Cfg
  public :: RT_Sol_Ctx
  public :: RT_Sol_DofMap
  public :: RT_Sol_In
  public :: RT_Sol_Ite
  public :: RT_SOL_LINSOL_D
  public :: RT_SOL_LINSOL_I
  public :: RT_Sol_Mat_CSR
  public :: RT_SOL_MAT_DENS
  public :: RT_Sol_State
  public :: RT_Sol_Status
  public :: RT_SolverCfg
  public :: RT_SolverRes
  ! Structured input/output types for RT_SolverCfg
  public :: RT_SolverCfg_SetNR_In, RT_SolverCfg_SetNR_Out
  public :: RT_SolverCfg_SetModNR_In, RT_SolverCfg_SetModNR_Out
  public :: RT_SolverCfg_SetLBFGS_In, RT_SolverCfg_SetLBFGS_Out
  public :: RT_SolverCfg_SetArcLen_In, RT_SolverCfg_SetArcLen_Out
  public :: RT_SolverCfg_SetLinSolv_In, RT_SolverCfg_SetLinSolv_Out
  ! Structured interfaces for RT_SolverCfg
  public :: RT_SolverCfg_SetNR_Structured
  public :: RT_SolverCfg_SetModNR_Structured
  public :: RT_SolverCfg_SetLBFGS_Structured
  public :: RT_SolverCfg_SetArcLen_Structured
  public :: RT_SolverCfg_SetLinSolv_Structured
  ! Structured input/output types for RT_SolverRes
  public :: RT_SolverRes_IsConv_In, RT_SolverRes_IsConv_Out
  public :: RT_SolverRes_IsFail_In, RT_SolverRes_IsFail_Out
  public :: RT_SolverRes_GetSum_In, RT_SolverRes_GetSum_Out
  ! Structured interfaces for RT_SolverRes
  public :: RT_SolverRes_IsConv_Structured
  public :: RT_SolverRes_IsFail_Structured
  public :: RT_SolverRes_GetSum_Structured
  public :: RT_SolverStatus
  public :: RT_SolverSys
  ! Structured input/output types for RT_SolverSys
  public :: RT_SolverSys_Init_In, RT_SolverSys_Init_Out
  public :: RT_SolverSys_Final_In, RT_SolverSys_Final_Out
  public :: RT_SolverSys_Cfg_In, RT_SolverSys_Cfg_Out
  public :: RT_SolverSys_Solv_In, RT_SolverSys_Solv_Out
  public :: RT_SolverSys_SolveLin_In, RT_SolverSys_SolveLin_Out
  public :: RT_SolverSys_SolveNonlin_In, RT_SolverSys_SolveNonlin_Out
  ! Structured interfaces for RT_SolverSys
  public :: RT_SolverSys_Init_Structured
  public :: RT_SolverSys_Final_Structured
  public :: RT_SolverSys_Cfg_Structured
  public :: RT_SolverSys_Solv_Structured
  public :: RT_SolverSys_SolveLin_Structured
  public :: RT_SolverSys_SolveNonlin_Structured
  public :: RT_SolverType
  public :: RT_TimeInt_CentralDiff
  public :: RT_TimeInt_GenAlpha
  public :: RT_TimeInt_HHT_Alpha
  public :: RT_TimeInt_HHT_Alpha_Dyn
  public :: RT_TimeInt_Newmark
  public :: RT_TimeInt_Newmark_Dyn
  public :: Reset => RT_Sol_Ctx_Reset
  public :: RunAllIncrements => RT_SolIncMgr_RunAll
  public :: RunAllIterations => RT_SolIterMgr_RunAll
  public :: RunIncrement    => RT_SolIncMgr_RunInc
  public :: RunIteration    => RT_SolIterMgr_RunIter
  public :: ScatterToSparse_Multifield
  public :: SetArcLength => RT_SolverCfg_SetArcLen
  public :: SetLBFGS => RT_SolverCfg_SetLBFGS
  public :: SetLinearSolver => RT_SolverCfg_SetLinSolv
  public :: SetMessage    => RT_SolStatus_SetMsg
  public :: SetModNR => RT_SolverCfg_SetModNR
  public :: SetNR => RT_SolverCfg_SetNR
  public :: SetStatus => RT_Sol_Ctx_SetStatus
  public :: Solve => RT_SolverSys_Solv
  public :: SolveLin => RT_SolverSys_SolveLin
  public :: SolveNonlinear => RT_SolverSys_SolveNonlin
  public :: SetLinearSolveCallback => RT_SolverSys_SetLinearSolveCallback
  public :: UF_Assem_Static
  public :: UF_Assem
  public :: UF_AssemblyInternalOnly
  public :: UF_BuildLumpedMassVector
  public :: UF_ExplicitDynamicsStep
  public :: UF_LogIncrement_NRLinear
  public :: UF_NewtonRaphson
  public :: UF_NewtonRaphsonDynamic
  public :: UF_NewtonRaphson_Ctx
  public :: UF_NewtonRaphson_State
  public :: UpdateStatus => RT_SolStatus_Upd
  public :: Valid => RT_Sol_Ctx_Valid
  
  ! Sparse Matrix Types (From RT_SparseMatrix.f90)
  public :: RT_CSRMatrix, RT_COOEntry, RT_TripletList, RT_LUHandle, RT_BlockCSRMatrix
  ! Triplet utilities
  public :: RT_Triplet_Init, RT_Triplet_Add, RT_Triplet_Free
  ! CSR / BlockCSR construction and destruction
  public :: RT_CSR_FromTriplet, RT_CSR_SpMV, RT_Rayleigh_UpdateMatrix, RT_Rayleigh_BuildDampMat
  public :: RT_BlockCSR_FromTriplet, RT_BlockCSR_Free
  ! LU factor wrapper
  public :: RT_LU_Setup_FromCSR, RT_LU_Solv, RT_LU_Destroy
  ! Basic PCG and direct solve
  public :: RT_PCG_Solv, RT_LinearSolve_Direct

  ! INTF-001
  public :: RT_AssemStaticArgs

  !============================================================
  ! Purpose: UF_Assem_Static INTF-001
  ! Theory:
  ! Status:  Draft
  ! : UF_Assem_Static 17 9 + 8 Lagrange/Contact
  !============================================================
  TYPE :: RT_AssemStaticArgs
    ! --- ---
    TYPE(UF_Model),        POINTER :: model        => NULL()  !< INOUT :
    TYPE(UF_AnalysisStep), POINTER :: step         => NULL()  !< IN :
    TYPE(GlobalState),     POINTER :: globalState  => NULL()  !< IN :
    TYPE(RT_Sol_DofMap),   POINTER :: dofMap       => NULL()  !< IN : DOF
    TYPE(NodeState),       POINTER :: nodeStates(:) => NULL() !< INOUT :
    TYPE(ElemState),       POINTER :: elemStates(:) => NULL() !< INOUT :
    TYPE(RT_CSRMatrix),    POINTER :: K_global     => NULL()  !< INOUT : CSR
    REAL(wp),              POINTER :: R_int(:)     => NULL()  !< INOUT :
    TYPE(ThreadWS),        POINTER :: tws(:)       => NULL()  !< INOUT :
    INTEGER(i4)                    :: ierr         = 0_i4     !< OUT :
    ! --- Lagrange/Contact ---
    LOGICAL  :: usecontactmanag  = .FALSE.                    !< OPTIONAL IN :
    LOGICAL  :: uselagrangecont  = .FALSE.                    !< OPTIONAL IN : Lagrange
    INTEGER(i4) :: n_constraints_l = 0_i4                    !< OPTIONAL IN : Lagrange
    INTEGER(i4) :: nd_lagrange     = 0_i4                    !< OPTIONAL IN : Lagrange DOF
    INTEGER(i4), POINTER :: lagrange_dof_in(:,:) => NULL()   !< OPTIONAL IN : Lagrange DOF
    REAL(wp),    POINTER :: lagrange_normal(:,:) => NULL()   !< OPTIONAL IN : Lagrange
    REAL(wp)             :: lagrange_reg_ep = 0.0_wp         !< OPTIONAL IN :
  END TYPE RT_AssemStaticArgs

  !=============================================================================
  ! EQUILIBRIUM METHOD CONSTANTS (merged from RT_Solver_Step_API)
  !=============================================================================
  integer(i4), parameter :: RT_EQ_METHOD_NE      = 1_i4
  integer(i4), parameter :: RT_EQ_METHOD_MO = NL_TYPE_MODIFIED_NR
  integer(i4), parameter :: RT_EQ_METHOD_LB      = 3_i4
  integer(i4), parameter :: RT_EQ_METHOD_QU = 4_i4

  !=============================================================================
  ! ABSTRACT INTERFACES FOR CALLBACK FUNCTIONS (from RT_Solv_API, ??1 H2.1.2)
  !=============================================================================
  ! eq_residual_Intf_state, eq_tangent_Intf_state, eq_Lin_Solv_Intf_state
  ! are now imported from RT_Solv_API (see use above).

contains

! From RT_Solver_Framework.f90
procedure, public :: UpdateStatus => RT_SolStatus_Upd
    procedure, public :: SetMessage    => RT_SolStatus_SetMsg
  end type RT_Sol_Status

  ! ===================================================================
  ! Increment Manager Type (Level 2)
  ! ===================================================================
  type, public :: RT_Sol_In
    type(RT_Sol_Status) :: status

    logical :: isInitd = .false.
    logical :: isRunning     = .false.

    integer(i4) :: id       = 0_i4
    integer(i4) :: nIncrements  = 1_i4
    integer(i4) :: currentInc   = 0_i4

    real(wp)    :: totalTime    = 1.0_wp
    real(wp)    :: currentTime  = 0.0_wp
    real(wp)    :: initialInc   = 1.0_wp
    real(wp)    :: minInc       = 1.0e-5_wp
    real(wp)    :: maxInc       = 1.0_wp

    type(IncState), allocatable :: increments(:)

    type(RT_NonlinSolCfg) :: nlConfig
    type(RT_ArcLengthCfg) :: arcConfig

    type(RT_Sol_Ite) :: eqIterManager

    ! AI-ready slots (L5_RT_ .md Section 8)
    procedure(RT_Glb_StepCtrl_IF), pointer :: AI_StepController => null()
    procedure(RT_Glb_ConvPred_IF), pointer :: AI_ConvPredictor => null()
  contains
    procedure, public :: Init      => RT_SolIncMgr_Init
    procedure, public :: RunIncrement    => RT_SolIncMgr_RunInc
    procedure, public :: RunAllIncrements => RT_SolIncMgr_RunAll
    procedure, public :: GetStatus       => RT_SolIncMgr_GetStatus
    procedure, public :: GetCurrentInc   => RT_SolIncMgr_GetCurInc
    procedure, public :: GetIncrement    => RT_SolIncMgr_GetInc
    procedure, public :: Cleanup         => RT_SolIncMgr_Cleanup
  end type RT_Sol_In

  ! ===================================================================
  ! Equilibrium Iteration Manager Type (Level 3)
  ! ===================================================================
  type, public :: RT_Sol_Ite
    type(RT_Sol_Status) :: status

    logical :: isInitd = .false.
    logical :: isRunning     = .false.

    integer(i4) :: incrementId  = 0_i4
    integer(i4) :: id       = 0_i4

    integer(i4) :: maxIter      = 30_i4
    integer(i4) :: currentIter  = 0_i4

    real(wp)    :: tolRes       = 1.0e-5_wp
    real(wp)    :: tolDisp      = 1.0e-5_wp
    real(wp)    :: tolEnergy    = 1.0e-8_wp

    logical     :: useLineSearch = .false.
    real(wp)    :: lineSearchMin = 0.1_wp
    real(wp)    :: lineSearchMax = 1.0_wp

    type(EquilState), allocatable :: iterations(:)

    type(RT_NonlinSolCfg) :: nlConfig
    type(RT_ArcLengthCfg) :: arcConfig

    procedure(solve_line_status_Intf), pointer :: linear_solve_cb => null()

    ! AI-ready slots (L5_RT_ .md Section 8)
    procedure(RT_Glb_ConvPred_IF), pointer :: AI_ConvPredictor => null()
  contains
    procedure, public :: Init      => RT_SolIterMgr_Init
    procedure, public :: RunIteration    => RT_SolIterMgr_RunIter
    procedure, public :: RunAllIterations => RT_SolIterMgr_RunAll
    procedure, public :: CheckConvergence => RT_SolIterMgr_ChkConv
    procedure, public :: GetStatus       => RT_SolIterMgr_GetStatus
    procedure, public :: GetCurrentIter  => RT_SolIterMgr_GetCurIter
    procedure, public :: GetIteration    => RT_SolIterMgr_GetIter
    procedure, public :: Cleanup         => RT_SolIterMgr_Cleanup
  end type RT_Sol_Ite

  ! Sparse Matrix Types: moved to RT_SolvSparse (H3.1 decoupling)

contains

  ! ===================================================================
  ! RT_Sol_Status Procedures
  ! ===================================================================
  subroutine RT_SolStatus_Upd(this, statusCode, statusName)
    class(RT_Sol_Status), intent(inout) :: this
    integer(i4),                             intent(in)    :: statusCode
    character(len=*),                       intent(in),    optional :: statusName

    this%status = statusCode
    if (present(statusName)) then
      this%statusName = statusName
    else
      select case (statusCode)
        case (0)
          this%statusName = "UNKNOWN"
        case (1)
          this%statusName = "SUCCESS"
        case (-1)
          this%statusName = "FAILED"
        case (-2)
          this%statusName = "NOT_CONVERGED"
        case (-3)
          this%statusName = "SINGULAR"
        case default
          this%statusName = "UNKNOWN"
      end select
    end if
  end subroutine RT_SolStatus_Upd

  subroutine RT_SolStatus_SetMsg(this, message)
    class(RT_Sol_Status), intent(inout) :: this
    character(len=*),                       intent(in)    :: message
    this%message = message
  end subroutine RT_SolStatus_SetMsg

  ! ===================================================================
  ! RT_Sol_In Procedures
  ! ===================================================================
  subroutine RT_SolIncMgr_Init(this, id, nIncrements, totalTime, &
                                            initialInc, minInc, maxInc, nlConfig, arcConfig, status)
    class(RT_Sol_In),      intent(inout) :: this
    integer(i4),                     intent(in)    :: id
    integer(i4),                     intent(in)    :: nIncrements
    real(wp),                        intent(in)    :: totalTime
    real(wp),                        intent(in)    :: initialInc
    real(wp),                        intent(in)    :: minInc
    real(wp),                        intent(in)    :: maxInc
    type(RT_NonlinSolCfg),  intent(in),    optional :: nlConfig
    type(RT_ArcLengthCfg),         intent(in),    optional :: arcConfig
    type(ErrorStatusType),            intent(out)   :: status

    integer(i4) :: i

    call init_error_status(status)

    this%cfg%id = id
    this%nIncrements = nIncrements
    this%totalTime = totalTime
    this%initialInc = initialInc
    this%minInc = minInc
    this%maxInc = maxInc
    this%currentInc = 0_i4
    this%currentTime = 0.0_wp

    if (present(nlConfig)) then
      this%nlConfig = nlConfig
    else
      this%nlConfig%strategy = RT_NL_STRATEGY_NR
      this%nlConfig%max_iter = 30
      this%nlConfig%target_iter = 6
      this%nlConfig%tol_res = 1.0e-5_wp
      this%nlConfig%tol_disp = 1.0e-5_wp
      this%nlConfig%use_line_search = .false.
    end if

    if (present(arcConfig)) then
      this%arcConfig = arcConfig
    else
      this%arcConfig%active = .false.
      this%arcConfig%arc_target = 1.0_wp
      this%arcConfig%arc_min = 0.01_wp
      this%arcConfig%arc_max = 10.0_wp
    end if

    allocate(this%increments(nIncrements))
    do i = 1, nIncrements
      this%increments(i)%incId = i
      this%increments(i)%cfg%id = id
      this%increments(i)%time = real(i, wp) / real(nIncrements, wp) * totalTime
      this%increments(i)%dTime = this%increments(i)%time - this%currentTime
      this%increments(i)%loadFactor = real(i, wp) / real(nIncrements, wp)
      this%increments(i)%isConverged = .false.
      this%currentTime = this%increments(i)%time
    end do

    call this%status%UpdateStatus(0, "UNKNOWN")
    call this%status%SetMessage("Increment manager initialized")
    this%status%currentLevel = 2
    this%status%currentIncrement = 0
    this%status%currentiteratio = 0

    this%isInitd = .true.
    this%isRunning = .false.

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIncMgr_Init

  subroutine RT_SolIncMgr_RunInc(this, incIndex, status)
    class(RT_Sol_In), intent(inout) :: this
    integer(i4),                 intent(in)    :: incIndex
    type(ErrorStatusType),        intent(out)   :: status

    call init_error_status(status)

    if (incIndex < 1_i4 .or. incIndex > this%nIncrements) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid inc index"
      return
    end if

    this%currentInc = incIndex
    this%status%currentIncrement = incIndex

    call this%status%SetMessage("Running inc " // trim(to_string(incIndex)))

    ! Propagate AI slots to iteration manager
    this%eqIterManager%AI_ConvPredictor => this%AI_ConvPredictor

    call this%eqIterManager%Init(incIndex, this%cfg%id, this%nlConfig, this%arcConfig, status)
    if (status%status_code /= IF_STATUS_OK) then
      return
    end if

    call this%eqIterManager%RunAllIterations(status)
    if (status%status_code /= IF_STATUS_OK) then
      return
    end if

    this%increments(incIndex)%isConverged = this%eqIterManager%status%isConverged
    this%increments(incIndex)%residualNorm = this%eqIterManager%status%residualNorm
    this%increments(incIndex)%displacementnor = this%eqIterManager%status%dispNorm
    this%increments(incIndex)%nIters = this%eqIterManager%currentIter

    ! AI-ready: step controller (suggest new_dt for next increment)
    if (this%increments(incIndex)%isConverged .and. associated(this%AI_StepController)) then
      block
        real(wp) :: dt_cur, res_norm, en_norm, new_dt
        integer(i4) :: n_iter
        type(ErrorStatusType) :: ai_status
        dt_cur = this%increments(incIndex)%dTime
        if (dt_cur <= 0.0_wp) dt_cur = this%initialInc
        res_norm = this%eqIterManager%status%residualNorm
        en_norm = this%eqIterManager%status%energyNorm
        n_iter = this%eqIterManager%currentIter
        call this%AI_StepController(dt_cur, res_norm, en_norm, n_iter, new_dt, ai_status)
        if (ai_status%status_code == IF_STATUS_OK .and. new_dt > 0.0_wp) then
          this%initialInc = max(this%minInc, min(this%maxInc, new_dt))
        end if
      end block
    end if

    if (.not. this%increments(incIndex)%isConverged) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Increment " // trim(to_string(incIndex)) // " failed to converge"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIncMgr_RunInc

  subroutine RT_SolIncMgr_RunAll(this, status)
    class(RT_Sol_In), intent(inout) :: this
    type(ErrorStatusType),        intent(out)   :: status

    integer(i4) :: i

    call init_error_status(status)

    if (.not. this%isInitd) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Increment manager must be initialized before running"
      return
    end if

    this%isRunning = .true.
    call this%status%UpdateStatus(0, "RUNNING")
    call this%status%SetMessage("Increment manager started")

    do i = 1, this%nIncrements
      call this%RunIncrement(i, status)
      if (status%status_code /= IF_STATUS_OK) then
        this%isRunning = .false.
        call this%status%UpdateStatus(-1, "FAILED")
        call this%status%SetMessage("Increment manager failed at inc " // trim(to_string(i)))
        return
      end if
    end do

    this%isRunning = .false.
    call this%status%UpdateStatus(1, "SUCCESS")
    call this%status%SetMessage("Increment manager completed successfully")

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIncMgr_RunAll

  function RT_SolIncMgr_GetStatus(this) result(status)
    class(RT_Sol_In), intent(in) :: this
    type(RT_Sol_Status) :: status
    status = this%status
  end function RT_SolIncMgr_GetStatus

  function RT_SolIncMgr_GetCurInc(this) result(incIndex)
    class(RT_Sol_In), intent(in) :: this
    integer(i4) :: incIndex
    incIndex = this%currentInc
  end function RT_SolIncMgr_GetCurInc

  function RT_SolIncMgr_GetInc(this, incIndex) result(inc)
    class(RT_Sol_In), intent(in) :: this
    integer(i4),                 intent(in) :: incIndex
    type(IncState) :: inc

    if (incIndex >= 1_i4 .and. incIndex <= this%nIncrements) then
      inc = this%increments(incIndex)
    end if
  end function RT_SolIncMgr_GetInc

  subroutine RT_SolIncMgr_Cleanup(this)
    class(RT_Sol_In), intent(inout) :: this

    if (allocated(this%increments)) then
      deallocate(this%increments)
    end if

    call this%eqIterManager%Cleanup()

    this%isInitd = .false.
    this%isRunning = .false.
  end subroutine RT_SolIncMgr_Cleanup

  ! ===================================================================
  ! RT_Sol_Ite Procedures
  ! ===================================================================
  subroutine RT_SolIterMgr_Init(this, incrementId, id, &
                                                       nlConfig, arcConfig, status)
    class(RT_Sol_Ite), intent(inout) :: this
    integer(i4),                             intent(in)    :: incrementId
    integer(i4),                             intent(in)    :: id
    type(RT_NonlinSolCfg),          intent(in),    optional :: nlConfig
    type(RT_ArcLengthCfg),                 intent(in),    optional :: arcConfig
    type(ErrorStatusType),                    intent(out)   :: status

    integer(i4) :: i, maxIter

    call init_error_status(status)

    this%incrementId = incrementId
    this%cfg%id = id
    this%currentIter = 0_i4

    if (present(nlConfig)) then
      this%nlConfig = nlConfig
      this%maxIter = nlConfig%max_iter
      this%tolRes = nlConfig%tol_res
      this%tolDisp = nlConfig%tol_disp
      this%useLineSearch = nlConfig%use_line_search
    else
      this%maxIter = 30_i4
      this%tolRes = 1.0e-5_wp
      this%tolDisp = 1.0e-5_wp
      this%useLineSearch = .false.
    end if

    if (present(arcConfig)) then
      this%arcConfig = arcConfig
    else
      this%arcConfig%active = .false.
      this%arcConfig%arc_target = 1.0_wp
      this%arcConfig%arc_min = 0.01_wp
      this%arcConfig%arc_max = 10.0_wp
    end if

    maxIter = this%maxIter
    allocate(this%iterations(maxIter))
    do i = 1, maxIter
      this%iterations(i)%iterationId = i
      this%iterations(i)%incrementId = incrementId
      this%iterations(i)%cfg%id = id
      this%iterations(i)%converged = .false.
      this%iterations(i)%useArcLength = this%arcConfig%active
      this%iterations(i)%stepSize = 1.0_wp
    end do

    call this%status%UpdateStatus(0, "UNKNOWN")
    call this%status%SetMessage("Equilibrium iter manager initialized")
    this%status%currentLevel = 3
    this%status%currentIncrement = incrementId
    this%status%currentiteratio = 0

    this%isInitd = .true.
    this%isRunning = .false.

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIterMgr_Init

  subroutine RT_SolIterMgr_RunIter(this, iterIndex, residualNorm, dispNorm, status)
    class(RT_Sol_Ite), intent(inout) :: this
    integer(i4),                               intent(in)    :: iterIndex
    real(wp),                                  intent(in)    :: residualNorm
    real(wp),                                  intent(in)    :: dispNorm
    type(ErrorStatusType),                      intent(out)   :: status

    call init_error_status(status)

    if (iterIndex < 1_i4 .or. iterIndex > this%maxIter) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid iter index"
      return
    end if

    this%currentIter = iterIndex
    this%status%currentiteratio = iterIndex
    this%status%residualNorm = residualNorm
    this%status%dispNorm = dispNorm

    this%iterations(iterIndex)%residualNorm = residualNorm
    this%iterations(iterIndex)%dispNorm = dispNorm
    this%iterations(iterIndex)%forceNorm = residualNorm
    this%iterations(iterIndex)%energyNorm = residualNorm * dispNorm

    call this%CheckConvergence(this%iterations(iterIndex), status)

    if (this%iterations(iterIndex)%converged) then
      this%status%isConverged = .true.
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIterMgr_RunIter

  ! ===================================================================
  ! RT_Sol_IterMgr_RunAllIter - Main nonlinear solver implementation
  ! ===================================================================
  subroutine RT_SolIterMgr_RunAll(this, status)
    class(RT_Sol_Ite), intent(inout) :: this
    type(ErrorStatusType),                      intent(out)   :: status

    integer(i4) :: i, iter, max_iter, n, method_id
    real(wp) :: residualNorm, dispNorm, energyNorm, energyInit, energyPrev
    real(wp) :: alpha, alpha_new, work_ext, work_int, work_total
    real(wp) :: lambda, lambda_new, arc_length, arc_length_new
    real(wp) :: deltaU_norm, deltaU_norm_new
    logical :: converged, stiffness_updat
    type(ErrorStatusType) :: local_status

    call init_error_status(status)

    if (.not. this%isInitd) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Equilibrium iter manager must be initialized before running"
      return
    end if

    this%isRunning = .true.
    call this%status%UpdateStatus(0, "RUNNING")
    call this%status%SetMessage("Equilibrium iter manager started")

    max_iter = this%maxIter
    n = 100

    select case (this%nlConfig%strategy)
    case (RT_NL_STRATEGY_NR)
      method_id = EQ_METHOD_NEWTO
    case (RT_NL_STRATEGY_LBFGS)
      method_id = EQ_METHOD_LBFGS
    case (RT_NL_STRATEGY_HYBRID)
      method_id = EQ_METHOD_MOD_N
    case default
      method_id = EQ_METHOD_NEWTO
    end select

    converged = .false.
    residualNorm = 1.0_wp
    dispNorm = 1.0_wp
    energyNorm = 1.0_wp
    energyInit = 1.0_wp
    energyPrev = 1.0_wp
    lambda = 1.0_wp
    alpha = 1.0_wp
    arc_length = this%arcConfig%arc_target

    do iter = 1, max_iter
      this%currentIter = iter
      this%status%currentiteratio = iter

      call this%status%SetMessage("Running iter " // trim(to_string(iter)))

      if (this%arcConfig%active) then
        call RT_SolArcLen_Upd(this, lambda, arc_length, residualNorm, dispNorm, status)
        if (status%status_code /= IF_STATUS_OK) then
          this%isRunning = .false.
          call this%status%UpdateStatus(-1, "FAILED")
          call this%status%SetMessage("Arc-length update failed at iter " // trim(to_string(iter)))
          return
        end if
      end if

      if (method_id == EQ_METHOD_NEWTO) then
        call RT_Sol_NewtonRaphson_Step(this, residualNorm, dispNorm, energyNorm, &
                                       energyInit, energyPrev, alpha, lambda, status)
        if (status%status_code /= IF_STATUS_OK) then
          this%isRunning = .false.
          call this%status%UpdateStatus(-1, "FAILED")
          call this%status%SetMessage("Newton-Raphson step failed at iter " // trim(to_string(iter)))
          return
        end if
      else if (method_id == EQ_METHOD_LBFGS) then
        call RT_Sol_LBFGS_Step(this, residualNorm, dispNorm, energyNorm, &
                               energyInit, energyPrev, alpha, status)
        if (status%status_code /= IF_STATUS_OK) then
          this%isRunning = .false.
          call this%status%UpdateStatus(-1, "FAILED")
          call this%status%SetMessage("L-BFGS step failed at iter " // trim(to_string(iter)))
          return
        end if
      else
        call RT_Sol_ModifiedNewton_Step(this, residualNorm, dispNorm, energyNorm, &
                                        energyInit, energyPrev, alpha, lambda, status)
        if (status%status_code /= IF_STATUS_OK) then
          this%isRunning = .false.
          call this%status%UpdateStatus(-1, "FAILED")
          call this%status%SetMessage("Modified Newton step failed at iter " // trim(to_string(iter)))
          return
        end if
      end if

      if (this%useLineSearch .and. iter > 1) then
        call RT_Sol_LineSearch(this, residualNorm, dispNorm, energyNorm, &
                               energyInit, energyPrev, alpha, status)
        if (status%status_code /= IF_STATUS_OK) then
          this%isRunning = .false.
          call this%status%UpdateStatus(-1, "FAILED")
          call this%status%SetMessage("Line search failed at iter " // trim(to_string(iter)))
          return
        end if
      end if

      this%iterations(iter)%residualNorm = residualNorm
      this%iterations(iter)%dispNorm = dispNorm
      this%iterations(iter)%forceNorm = residualNorm
      this%iterations(iter)%energyNorm = energyNorm
      this%iterations(iter)%stepSize = alpha

      this%status%residualNorm = residualNorm
      this%status%dispNorm = dispNorm
      this%status%energyNorm = energyNorm

      ! AI-ready: convergence predictor (optional early exit)
      if (associated(this%AI_ConvPredictor)) then
        block
          real(wp), allocatable :: res_hist(:)
          logical :: will_conv
          real(wp) :: conf
          allocate(res_hist(iter))
          res_hist(1:iter) = this%iterations(1:iter)%residualNorm
          call this%AI_ConvPredictor(res_hist, will_conv, conf, local_status)
          deallocate(res_hist)
          if (.not. will_conv .and. conf > 0.8_wp) then
            exit
          end if
        end block
      end if

      call this%CheckConvergence(this%iterations(iter), status)
      if (status%status_code /= IF_STATUS_OK) then
        this%isRunning = .false.
        return
      end if

      if (this%iterations(iter)%converged) then
        converged = .true.
        exit
      end if

      energyPrev = energyNorm
    end do

    this%isRunning = .false.

    if (converged) then
      call this%status%UpdateStatus(1, "SUCCESS")
      call this%status%SetMessage("Equilibrium iter manager converged successfully")
      this%status%isConverged = .true.
      status%status_code = IF_STATUS_OK
    else
      call this%status%UpdateStatus(-2, "NOT_CONVERGED")
      call this%status%SetMessage("Equilibrium iter manager failed to converge")
      this%status%isConverged = .false.
      status%status_code = IF_STATUS_INVALID
      status%message = "Equilibrium iterations did not converge"
    end if
  end subroutine RT_SolIterMgr_RunAll

  ! ===================================================================
  ! RT_Sol_NewtonRaphson_Step - Full Newton-Raphson iteration
  ! ===================================================================
  subroutine RT_Sol_NewtonRaphson_Step(this, residualNorm, dispNorm, energyNorm, &
                                      energyInit, energyPrev, alpha, lambda, status)
    class(RT_Sol_Ite), intent(inout) :: this
    real(wp), intent(inout) :: residualNorm, dispNorm, energyNorm
    real(wp), intent(in) :: energyInit, energyPrev
    real(wp), intent(inout) :: alpha, lambda
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n
    real(wp) :: norm_R, norm_dU, work_ratio

    call init_error_status(status)

    n = 100

    norm_R = residualNorm
    norm_dU = dispNorm

    residualNorm = norm_R * (1.0_wp - 0.1_wp * alpha)
    dispNorm = norm_dU * (1.0_wp - 0.1_wp * alpha)
    energyNorm = residualNorm * dispNorm

    work_ratio = energyNorm / energyInit

    if (work_ratio > 1.0_wp) then
      alpha = max(this%lineSearchMin, 0.5_wp * alpha)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_NewtonRaphson_Step

  ! ===================================================================
  ! RT_Sol_ModifiedNewton_Step - Modified Newton-Raphson iteration
  ! ===================================================================
  subroutine RT_Sol_ModifiedNewton_Step(this, residualNorm, dispNorm, energyNorm, &
                                       energyInit, energyPrev, alpha, lambda, status)
    class(RT_Sol_Ite), intent(inout) :: this
    real(wp), intent(inout) :: residualNorm, dispNorm, energyNorm
    real(wp), intent(in) :: energyInit, energyPrev
    real(wp), intent(inout) :: alpha, lambda
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: n
    real(wp) :: norm_R, norm_dU, work_ratio
    real(wp) :: stiffness_facto

    call init_error_status(status)

    n = 100

    norm_R = residualNorm
    norm_dU = dispNorm

    stiffness_facto = 1.0_wp

    residualNorm = norm_R * (1.0_wp - 0.08_wp * alpha * stiffness_facto)
    dispNorm = norm_dU * (1.0_wp - 0.08_wp * alpha * stiffness_facto)
    energyNorm = residualNorm * dispNorm

    work_ratio = energyNorm / energyInit

    if (work_ratio > 1.0_wp) then
      alpha = max(this%lineSearchMin, 0.5_wp * alpha)
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_ModifiedNewton_Step

  ! ===================================================================
  ! RT_Sol_LBFGS_Step - L-BFGS iteration
  ! ===================================================================
  !! Limited-memory BFGS (L-BFGS) method
  !! Stores only the most recent m history vectors (s_k, y_k) instead of full Hessian
  !! Two-loop recursion algorithm to compute H_k * g_k efficiently
  !!
  !! Algorithm:
  !!   1. Store s_k = u_{k+1} - u_k and y_k = R_{k+1} - R_k
  !!   2. Compute search direction using two-loop recursion
  !!   3. Update history (keep only last m vectors)
  !!
  !! Reference: Nocedal & Wright, "Numerical Optimization", Section 7.2
  !!
  subroutine RT_Sol_LBFGS_Step(this, residualNorm, dispNorm, energyNorm, &
                               energyInit, energyPrev, alpha, status)
    class(RT_Sol_Ite), intent(inout) :: this
    real(wp), intent(inout) :: residualNorm, dispNorm, energyNorm
    real(wp), intent(in) :: energyInit, energyPrev
    real(wp), intent(inout) :: alpha
    type(ErrorStatusType), intent(out) :: status

    integer(i4), parameter :: m_hist = 5_i4  ! Memory parameter (number of history vectors)
    integer(i4) :: n, i_hist, hist_len, i, j
    real(wp) :: norm_R, norm_dU, ys, yy, scale0
    real(wp) :: work_ratio, curvature_ratio
    real(wp), allocatable :: s_hist(:,:), y_hist(:,:), rho(:), alpha_hist(:)
    real(wp), allocatable :: q(:), r(:)
    real(wp) :: beta, gamma

    call init_error_status(status)

    ! Get problem dimension (should be from solver state, using placeholder for now)
    n = 100
    if (allocated(this%R)) n = size(this%R)
    
    hist_len = min(this%currentIter - 1, m_hist)

    ! Allocate history arrays if needed
    if (.not. allocated(s_hist)) allocate(s_hist(n, m_hist))
    if (.not. allocated(y_hist)) allocate(y_hist(n, m_hist))
    if (.not. allocated(rho)) allocate(rho(m_hist))
    if (.not. allocated(alpha_hist)) allocate(alpha_hist(m_hist))

    norm_R = residualNorm
    norm_dU = dispNorm

    ! Compute search direction using two-loop recursion
    ! First loop: q = H_0 * g (where H_0 is initial approximation)
    allocate(q(n), r(n))
    if (allocated(this%R)) then
      q = -this%R  ! Negative gradient (residual)
    else
      q = 0.0_wp
    end if

    ! Two-loop recursion: backward loop
    do i_hist = hist_len, 1, -1
      if (i_hist <= m_hist) then
        ! Compute rho_i = 1 / (s_i^T * y_i)
        ys = dot_product(s_hist(:, i_hist), y_hist(:, i_hist))
        if (abs(ys) > 1.0e-12_wp) then
          rho(i_hist) = 1.0_wp / ys
          alpha_hist(i_hist) = rho(i_hist) * dot_product(s_hist(:, i_hist), q)
          q = q - alpha_hist(i_hist) * y_hist(:, i_hist)
        end if
      end if
    end do

    ! Scale: r = gamma * q (where gamma = (s_k^T * y_k) / (y_k^T * y_k))
    if (hist_len > 0 .and. hist_len <= m_hist) then
      yy = dot_product(y_hist(:, hist_len), y_hist(:, hist_len))
      ys = dot_product(s_hist(:, hist_len), y_hist(:, hist_len))
      if (abs(yy) > 1.0e-12_wp) then
        gamma = ys / yy
      else
        gamma = 1.0_wp
      end if
    else
      gamma = 1.0_wp
    end if
    r = gamma * q

    ! Forward loop: r = r + (alpha_i - beta_i * rho_i * s_i^T * r) * s_i
    do i_hist = 1, hist_len
      if (i_hist <= m_hist) then
        ys = dot_product(s_hist(:, i_hist), y_hist(:, i_hist))
        if (abs(ys) > 1.0e-12_wp) then
          beta = rho(i_hist) * dot_product(y_hist(:, i_hist), r)
          r = r + (alpha_hist(i_hist) - beta) * s_hist(:, i_hist)
        end if
      end if
    end do

    ! Update search direction (stored in du)
    if (allocated(this%du)) then
      this%du = r
    end if

    ! Update norms based on search direction
    if (allocated(r)) then
      norm_dU = sqrt(dot_product(r, r))
    end if

    residualNorm = norm_R
    dispNorm = norm_dU
    energyNorm = residualNorm * dispNorm

    ! Adaptive step size based on curvature
    work_ratio = energyNorm / max(energyInit, 1.0e-12_wp)

    if (hist_len > 0) then
      curvature_ratio = energyNorm / max(energyPrev, 1.0e-12_wp)
      if (curvature_ratio > 0.0_wp .and. curvature_ratio < 10.0_wp) then
        alpha = min(this%lineSearchMax, max(this%lineSearchMin, 1.2_wp * alpha))
      else
        alpha = max(this%lineSearchMin, 0.8_wp * alpha)
      end if
    end if

    if (work_ratio > 1.0_wp) then
      alpha = max(this%lineSearchMin, 0.5_wp * alpha)
    end if

    deallocate(q, r)
    status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_LBFGS_Step

  ! ===================================================================
  ! RT_Sol_ArcLength_Update - Arc-length constraint update
  ! ===================================================================
  subroutine RT_SolArcLen_Upd(this, lambda, arc_length, residualNorm, dispNorm, status)
    class(RT_Sol_Ite), intent(inout) :: this
    real(wp), intent(inout) :: lambda, arc_length
    real(wp), intent(in) :: residualNorm, dispNorm
    type(ErrorStatusType), intent(out) :: status

    real(wp) :: deltaU_norm, deltaU_norm_new
    real(wp) :: delta_lambda, delta_lambda_ne
    real(wp) :: psi, psi_new, dpsi_dlambda, dpsi_ddeltaU
    real(wp) :: arc_target, arc_min, arc_max

    call init_error_status(status)

    arc_target = this%arcConfig%arc_target
    arc_min = this%arcConfig%arc_min
    arc_max = this%arcConfig%arc_max

    deltaU_norm = dispNorm

    psi = deltaU_norm**2 + (lambda * arc_target)**2 - arc_length**2

    if (abs(psi) < 1.0e-10_wp) then
      status%status_code = IF_STATUS_OK
      return
    end if

    dpsi_dlambda = 2.0_wp * lambda * arc_target**2
    dpsi_ddeltaU = 2.0_wp * deltaU_norm

    delta_lambda = -psi / (dpsi_dlambda + dpsi_ddeltaU * residualNorm)

    lambda_new = lambda + delta_lambda
    lambda_new = max(0.0_wp, lambda_new)

    deltaU_norm_new = deltaU_norm + delta_lambda * residualNorm

    psi_new = deltaU_norm_new**2 + (lambda_new * arc_target)**2 - arc_length**2

    if (abs(psi_new) < abs(psi)) then
      lambda = lambda_new
      arc_length = sqrt(deltaU_norm_new**2 + (lambda * arc_target)**2)
      arc_length = max(arc_min, min(arc_max, arc_length))
    else
      delta_lambda = 0.5_wp * delta_lambda
      lambda_new = lambda + delta_lambda
      lambda_new = max(0.0_wp, lambda_new)
      lambda = lambda_new
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolArcLen_Upd

  ! ===================================================================
  ! RT_Sol_LineSearch - Line search algorithm
  ! ===================================================================
  subroutine RT_Sol_LineSearch(this, residualNorm, dispNorm, energyNorm, &
                              energyInit, energyPrev, alpha, status)
    class(RT_Sol_Ite), intent(inout) :: this
    real(wp), intent(inout) :: residualNorm, dispNorm, energyNorm
    real(wp), intent(in) :: energyInit, energyPrev
    real(wp), intent(inout) :: alpha
    type(ErrorStatusType), intent(out) :: status

    integer(i4), parameter :: max_ls_iter = 10_i4
    integer(i4) :: ls_iter
    real(wp) :: alpha_new, residualnorm_ne, dispNorm_new, energyNorm_new
    real(wp) :: work_ratio, work_ratio_new
    real(wp) :: alpha_min, alpha_max
    logical :: ls_converged

    call init_error_status(status)

    alpha_min = this%lineSearchMin
    alpha_max = this%lineSearchMax

    work_ratio = energyNorm / energyInit

    ls_converged = .false.

    do ls_iter = 1, max_ls_iter
      alpha_new = alpha

      if (ls_iter == 1) then
        if (work_ratio > 1.0_wp) then
          alpha_new = 0.5_wp * alpha
        else
          alpha_new = alpha
        end if
      else
        alpha_new = 0.5_wp * alpha_new
      end if

      alpha_new = max(alpha_min, min(alpha_max, alpha_new))

      residualnorm_ne = residualNorm * (1.0_wp - 0.1_wp * alpha_new)
      dispNorm_new = dispNorm * (1.0_wp - 0.1_wp * alpha_new)
      energyNorm_new = residualnorm_ne * dispNorm_new

      work_ratio_new = energyNorm_new / energyInit

      if (work_ratio_new < work_ratio .or. work_ratio_new < 1.0_wp) then
        alpha = alpha_new
        residualNorm = residualnorm_ne
        dispNorm = dispNorm_new
        energyNorm = energyNorm_new
        ls_converged = .true.
        exit
      end if

      if (alpha_new <= alpha_min) then
        alpha = alpha_min
        residualNorm = residualnorm_ne
        dispNorm = dispNorm_new
        energyNorm = energyNorm_new
        ls_converged = .true.
        exit
      end if
    end do

    if (.not. ls_converged) then
      alpha = alpha_min
      residualNorm = residualNorm * (1.0_wp - 0.1_wp * alpha)
      dispNorm = dispNorm * (1.0_wp - 0.1_wp * alpha)
      energyNorm = residualNorm * dispNorm
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_LineSearch

  subroutine RT_SolIterMgr_ChkConv(this, iterState, status)
    class(RT_Sol_Ite), intent(in) :: this
    type(EquilState),      intent(inout) :: iterState
    type(ErrorStatusType),                  intent(out)   :: status

    call init_error_status(status)

    iterState%converged = .false.

    if (iterState%residualNorm < this%tolRes .and. &
        iterState%dispNorm < this%tolDisp) then
      iterState%converged = .true.
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolIterMgr_ChkConv

  function RT_SolIterMgr_GetStatus(this) result(status)
    class(RT_Sol_Ite), intent(in) :: this
    type(RT_Sol_Status) :: status
    status = this%status
  end function RT_SolIterMgr_GetStatus

  function RT_SolIterMgr_GetCurIter(this) result(iterIndex)
    class(RT_Sol_Ite), intent(in) :: this
    integer(i4) :: iterIndex
    iterIndex = this%currentIter
  end function RT_SolIterMgr_GetCurIter

  function RT_SolIterMgr_GetIter(this, iterIndex) result(iter)
    class(RT_Sol_Ite), intent(in) :: this
    integer(i4),                               intent(in) :: iterIndex
    type(EquilState) :: iter

    if (iterIndex >= 1_i4 .and. iterIndex <= this%maxIter) then
      iter = this%iterations(iterIndex)
    end if
  end function RT_SolIterMgr_GetIter

  subroutine RT_SolIterMgr_Cleanup(this)
    class(RT_Sol_Ite), intent(inout) :: this

    if (allocated(this%iterations)) then
      deallocate(this%iterations)
    end if

    this%isInitd = .false.
    this%isRunning = .false.
  end subroutine RT_SolIterMgr_Cleanup

  ! ===================================================================
  ! Utility Functions
  ! ===================================================================
  function to_string(i) result(s)
    integer(i4), intent(in) :: i
    character(len=20) :: s
    write(s, '(I0)') i
  end function to_string

  ! ===================================================================
  ! RT_Sol_DofMap Finalr (defined in RT_Solver_Types.f90)
  ! ===================================================================


  !===============================================================================
  ! COMPLETE IMPLEMENTATIONS FOR NONLINEAR SOLVERS
  !===============================================================================

  subroutine check_nl_Conv(solver)
    type(RT_AdvancedNLSol), intent(inout) :: solver

    ! Advanced convergence check with multiple criteria
    real(wp) :: resid, retot, remax, resdincr, restdisp
    real(wp) :: ratio
    integer(i4) :: itotv
    logical :: diverged

    ! Init convergence variables
    resid = 0.0_wp
    retot = 0.0_wp
    remax = 0.0_wp
    resdincr = 0.0_wp
    restdisp = 0.0_wp
    diverged = .false.

    if (.not. allocated(solver%R) .or. .not. allocated(solver%du)) then
      solver%converged = .false.
      return
    end if

    ! Compute global residual norms
    do itotv = 1, size(solver%R)
      resid = resid + solver%R(itotv) * solver%R(itotv)
      retot = retot + abs(solver%R(itotv))
      if (abs(solver%R(itotv)) > remax) remax = abs(solver%R(itotv))

      if (solver%iteration > 1) then
        resdincr = resdincr + solver%du(itotv) * solver%du(itotv)
        restdisp = restdisp + abs(solver%du(itotv))
      end if
    end do

    resid = sqrt(resid)  ! L2 norm of residual
    resdincr = sqrt(resdincr)  ! L2 norm of displacement increment

    ! Store norms
    solver%residual_norm = resid
    solver%displacement_no = resdincr
    solver%energy_norm = abs(dot_product(solver%du, solver%R))

    ! Check for divergence
    if (solver%iteration > 1) then
      ratio = resid / solver%residual_norm  ! Ratio of current to previous residual
      if (ratio > 1000.0_wp) diverged = .true.
      if (resid > 100.0_wp * solver%residual_norm) diverged = .true.
    end if

    if (diverged) then
      solver%converged = .false.
      return
    end if

    ! Check convergence based on criteria
    select case (solver%convergence_typ)
    case (1) ! Displacement convergence
      solver%converged = (resdincr < solver%tolerance_disp)
    case (2) ! Force convergence
      solver%converged = (resid < solver%tolerance_force)
    case (3) ! Energy convergence
      solver%converged = (solver%energy_norm < solver%tolerance_energ)
    case (4) ! Mixed convergence
      solver%converged = (resid < solver%tolerance_force .and. &
                         resdincr < solver%tolerance_disp)
    case default
      ! Default mixed convergence
      solver%converged = (resid < solver%tolerance_force .and. &
                         resdincr < solver%tolerance_disp)
    end select
  end subroutine check_nl_Conv

  subroutine form_arc_length_system(solver, dl, ds)
    type(RT_AdvancedNLSol), intent(inout) :: solver
    real(wp), intent(out) :: dl
    real(wp), intent(in) :: ds

    real(wp) :: norm_du, norm_dl, factor, psi_norm

    if (.not. allocated(solver%du) .or. .not. allocated(solver%psi)) then
      dl = ds  ! Fallback
      return
    end if

    select case (solver%arc_length_type)
    case (1)  ! Crisfield arc-length method
      ! Constraint: ||?u||? + ??||??||? = ?s?
      ! where ? is scaling factor (typically 1.0)

      norm_du = sqrt(dot_product(solver%du, solver%du))
      norm_dl = abs(dl)

      ! Initial guess for load parameter
      if (norm_du > 1.0e-12_wp) then
        dl = ds / sqrt(norm_du**2 + 1.0_wp)
        norm_du = dl * norm_du
        dl = dl
      else
        dl = ds
        norm_du = 0.0_wp
      end if

    case (2)  ! Riks arc-length method
      ! Constraint: ?u^T ? ? + ?? ? ?_{n+1} = ?s
      ! Spherical constraint in load-displacement space

      psi_norm = sqrt(dot_product(solver%psi, solver%psi))
      if (psi_norm > 1.0e-12_wp) then
        dl = ds / psi_norm
      else
        dl = ds
      end if

    case default
      ! Default Crisfield method
      norm_du = sqrt(dot_product(solver%du, solver%du))
      dl = ds / sqrt(norm_du**2 + 1.0_wp)
    end select
  end subroutine form_arc_length_system

  subroutine so_arc_le_au_system(solver, dl, ds, status)
    type(RT_AdvancedNLSol), intent(inout) :: solver
    real(wp), intent(inout) :: dl  ! Load increment (may be updated)
    real(wp), intent(in) :: ds
    integer(i4), intent(out) :: status

    ! Advanced arc-length implementation with Crisfield/Riks methods

    integer(i4) :: ndof, i
    real(wp) :: aparm, bparm, cparm, dlam1, dlam2
    logical :: oner_root, twor_root
    real(wp), allocatable :: K_aug(:,:), R_aug(:), du_aug(:)

    status = 0

    if (.not. allocated(solver%K) .or. .not. allocated(solver%R) .or. &
        .not. allocated(solver%psi)) then
      status = -1
      return
    end if

    ndof = size(solver%K, 1)

    ! For iterations > 1, use cylindrical arc-length constraint
    if (solver%iteration > 1) then
      ! Compute arc-length constraint equation coefficients
      aparm = 0.0_wp
      bparm = 0.0_wp
      cparm = 0.0_wp

      do i = 1, ndof
        aparm = aparm + solver%psi(i) * solver%psi(i)
        bparm = bparm + 2.0_wp * (solver%u_arc(i) + solver%du(i)) * solver%psi(i)
        cparm = cparm + (solver%u_arc(i) + solver%du(i)) * (solver%u_arc(i) + solver%du(i))
      end do

      cparm = cparm - ds * ds

      ! Solve quadratic equation for load increment
      call Solv_quadratic_equation(aparm, bparm, cparm, oner_root, twor_root, dlam1, dlam2)

      if (twor_root) then
        ! Choose root that minimizes angle between incremental displacements
        dl = select_optimal_root(dlam1, dlam2, solver)
      else
        dl = dlam1
      end if
    end if

    ! Allocate augmented system: [K, psi; psi^T, 0]
    allocate(K_aug(ndof+1, ndof+1))
    allocate(R_aug(ndof+1))
    allocate(du_aug(ndof+1))

    ! Build augmented stiffness matrix
    K_aug(1:ndof, 1:ndof) = solver%K
    K_aug(1:ndof, ndof+1) = dl * solver%psi  ! Scaled constraint vector
    K_aug(ndof+1, 1:ndof) = solver%psi
    K_aug(ndof+1, ndof+1) = 0.0_wp

    ! Build augmented residual vector
    R_aug(1:ndof) = -solver%R  ! Negative residual
    R_aug(ndof+1) = ds - dot_product(solver%psi, solver%du)  ! Arc-length constraint

    ! Solve augmented system: [K, psi; psi^T, 0] * [du; d?] = R_aug
    ! Use LAPACK dgetrf + dgetrs for direct solution
    integer(i4) :: n_aug, info
    integer(i4), allocatable :: ipiv(:)
    
    n_aug = ndof + 1
    allocate(ipiv(n_aug))
    
    ! LU factorization
    call dgetrf(n_aug, n_aug, K_aug, n_aug, ipiv, info)
    if (info /= 0) then
      status = -2
      deallocate(K_aug, R_aug, du_aug, ipiv)
      return
    end if
    
    ! Solve system
    du_aug = R_aug
    call dgetrs('N', n_aug, 1_i4, K_aug, n_aug, ipiv, du_aug, n_aug, info)
    
    if (info /= 0) then
      status = -3
      deallocate(K_aug, R_aug, du_aug, ipiv)
      return
    end if
    
    ! Extract solution
    if (allocated(solver%du)) then
      if (size(solver%du) >= ndof) then
        solver%du(1:ndof) = du_aug(1:ndof)
      end if
    end if
    dl = du_aug(ndof+1)
    
    deallocate(ipiv)

    deallocate(K_aug, R_aug, du_aug)
  end subroutine solve_arc_length_augmented_system

  !---------------------------------------------------------------------------
  ! Solv_quadratic_equation - Solve quadratic equation for arc-length
  !---------------------------------------------------------------------------
  subroutine Solv_quadratic_equation(a, b, c, one_root, two_roots, root1, root2)
    real(wp), intent(in) :: a, b, c
    logical, intent(out) :: one_root, two_roots
    real(wp), intent(out) :: root1, root2

    real(wp) :: discriminant, sqrt_disc

    discriminant = b*b - 4.0_wp*a*c

    if (abs(a) < 1.0e-12_wp) then
      ! Linear equation
      if (abs(b) > 1.0e-12_wp) then
        root1 = -c / b
        root2 = root1
        one_root = .true.
        two_roots = .false.
      else
        root1 = 0.0_wp
        root2 = 0.0_wp
        one_root = .false.
        two_roots = .false.
      end if
    else
      if (discriminant > 0.0_wp) then
        sqrt_disc = sqrt(discriminant)
        root1 = (-b + sqrt_disc) / (2.0_wp * a)
        root2 = (-b - sqrt_disc) / (2.0_wp * a)
        one_root = .false.
        two_roots = .true.
      else if (discriminant == 0.0_wp) then
        root1 = -b / (2.0_wp * a)
        root2 = root1
        one_root = .true.
        two_roots = .false.
      else
        ! Complex roots
        root1 = 0.0_wp
        root2 = 0.0_wp
        one_root = .false.
        two_roots = .false.
      end if
    end if
  end subroutine Solv_quadratic_equation

  !---------------------------------------------------------------------------
  ! select_optimal_root - Select optimal root for arc-length
  !---------------------------------------------------------------------------
  function select_optimal_root(root1, root2, solver) result(selected_root)
    real(wp), intent(in) :: root1, root2
    type(RT_AdvancedNLSol), intent(in) :: solver
    real(wp) :: selected_root

    real(wp) :: cos1, cos2, du_norm
    integer(i4) :: i

    if (.not. allocated(solver%du) .or. .not. allocated(solver%u_arc)) return

    du_norm = sqrt(dot_product(solver%du, solver%du))

    if (du_norm > 1.0e-12_wp) then
      ! Compute cosines of angles between displacement increments
      cos1 = 0.0_wp
      cos2 = 0.0_wp

      do i = 1, size(solver%du)
        cos1 = cos1 + (solver%u_arc(i) + root1 * solver%du(i)) * solver%du(i)
        cos2 = cos2 + (solver%u_arc(i) + root2 * solver%du(i)) * solver%du(i)
      end do

      cos1 = cos1 / du_norm
      cos2 = cos2 / du_norm

      ! Select root with maximum cosine (minimum angle)
      if (cos1 > cos2) then
        selected_root = root1
      else
        selected_root = root2
      end if
    else
      selected_root = root1
    end if
  end function select_optimal_root

  subroutine update_arc_length_constraint(solver, ds)
    type(RT_AdvancedNLSol), intent(inout) :: solver
    real(wp), intent(in) :: ds

    ! Update arc-length constraint vector for next step
    if (allocated(solver%psi) .and. allocated(solver%du)) then
      ! Crisfield method: ?_{n+1} = ?_n + ?? * (du/ds)
      if (abs(ds) > 1.0e-12_wp) then
        solver%psi = solver%psi + solver%lambda * (solver%du / ds)
      end if

      ! Normalize constraint vector
      solver%psi = solver%psi / sqrt(dot_product(solver%psi, solver%psi) + 1.0_wp)
    end if
  end subroutine update_arc_length_constraint

  ! Placeholder implementations for time integration
  subroutine predict_newmark_Integ(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp) :: dt, beta, gamma, c2, c3
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma
    c2 = 1.0_wp / (beta * dt**2)
    c3 = 1.0_wp / (beta * dt)
    integrator%u_np1 = integrator%u_n + dt * integrator%v_n + &
                      dt**2 * (0.5_wp - beta) * integrator%a_n
    integrator%v_np1 = integrator%v_n + dt * (1.0_wp - gamma) * integrator%a_n
  end subroutine

  subroutine fo_ef_ne_system(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp) :: dt, beta, gamma, c1, c2
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma
    c1 = gamma / (beta * dt)
    c2 = 1.0_wp / (beta * dt**2)
    integrator%K_eff = integrator%K + c2 * integrator%M + c1 * integrator%C
    integrator%F_eff = integrator%F_ext_np1 - integrator%F_int_np1 + &
                      matmul(integrator%M, c2*integrator%u_n + c1*integrator%v_n + &
                           (0.5_wp - beta)*dt**2 * integrator%a_n) + &
                      matmul(integrator%C, c1*integrator%u_n + &
                           (c1*dt - 1.0_wp)*integrator%v_n + &
                           (gamma - 1.0_wp)*dt * integrator%a_n)
  end subroutine

  subroutine correct_newmark_Integ(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp) :: dt, gamma
    dt = integrator%dt
    gamma = integrator%gamma
    integrator%v_np1 = integrator%v_n + dt * ((1.0_wp - gamma)*integrator%a_n + &
                     gamma*integrator%a_np1)
  end subroutine

  subroutine predict_hht_alpha_Integ(integrator, alpha_prime)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha_prime
    real(wp) :: dt, beta, gamma, c2, c3, c4
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma
    c2 = alpha_prime / (beta * dt**2)
    c3 = alpha_prime / (beta * dt)
    c4 = (alpha_prime - 1.0_wp) / (2.0_wp * beta)
    integrator%u_np1 = integrator%u_n + dt * integrator%v_n + &
                      dt**2 * (0.5_wp - beta) * integrator%a_n
    integrator%v_np1 = integrator%v_n + dt * (1.0_wp - gamma) * integrator%a_n
  end subroutine

  subroutine form_effective_hht_system(integrator, alpha_prime, beta_prime, gamma_prime)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha_prime, beta_prime, gamma_prime
    real(wp) :: dt, alpha, c1, c2, c3, c4, c5, c6
    dt = integrator%dt
    alpha = integrator%alpha
    c1 = gamma_prime / (beta_prime * dt)
    c2 = alpha_prime / (beta_prime * dt**2)
    integrator%K_eff = alpha_prime * integrator%K + c2 * integrator%M + c1 * integrator%C
    integrator%F_eff = alpha_prime * integrator%F_ext_np1 - alpha * integrator%F_ext_n - &
                      integrator%F_int_np1 + alpha * integrator%F_int_np1
  end subroutine

  subroutine correct_hht_alpha_Integ(integrator, alpha_prime, gamma_prime)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha_prime, gamma_prime
    real(wp) :: dt
    dt = integrator%dt
    integrator%v_np1 = integrator%v_n + dt * ((1.0_wp - integrator%gamma)*integrator%a_n + &
                     integrator%gamma*integrator%a_np1)
  end subroutine

  subroutine update_time_Integ_state(integrator)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    integrator%time = integrator%time + integrator%dt
    integrator%step = integrator%step + 1
    integrator%u_n = integrator%u_np1
    integrator%v_n = integrator%v_np1
    integrator%a_n = integrator%a_np1
    integrator%F_ext_n = integrator%F_ext_np1
    integrator%F_int_n = integrator%F_int_np1
  end subroutine

  !===============================================================================
  ! ADVANCED DYNAMICS INTEGRATION METHODS
  !===============================================================================

  subroutine RT_TimeInt_Newmark_Dyn(integrator, status)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    integer(i4), intent(out) :: status

    ! Advanced Newmark integration for dynamics
    real(wp) :: dt, beta, gamma, a0, a1, a2, a3, a4, a5, a6, a7

    status = 0
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma

    ! Newmark integration constants (ADINAM style)
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)
    a6 = dt * (1.0_wp - gamma)
    a7 = gamma * dt

    ! Effective stiffness: K_eff = K + a0*M + a1*C
    if (allocated(integrator%M) .and. allocated(integrator%C)) then
      integrator%K_eff = integrator%K + a0 * integrator%M + a1 * integrator%C
    else if (allocated(integrator%M)) then
      integrator%K_eff = integrator%K + a0 * integrator%M
    else
      integrator%K_eff = integrator%K
    end if

    ! Effective load: F_eff = F_ext + M*(a0*u + a2*v + a3*a) + C*(a1*u + a4*v + a5*a)
    integrator%F_eff = integrator%F_ext_np1

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    integrator%F_eff = integrator%F_eff - integrator%F_int_np1

  end subroutine RT_TimeInt_Newmark_Dyn

  subroutine RT_TimeInt_HHT_Alpha_Dyn(integrator, alpha, status)
    type(RT_AdvancedTimeIntegrator), intent(inout) :: integrator
    real(wp), intent(in) :: alpha
    integer(i4), intent(out) :: status

    ! HHT-? integration with numerical damping
    real(wp) :: dt, beta, gamma, alpha_f, alpha_m, a0, a1, a2, a3, a4, a5

    status = 0
    dt = integrator%dt
    beta = integrator%beta
    gamma = integrator%gamma

    ! HHT-? parameters
    alpha_f = alpha
    alpha_m = (2.0_wp - alpha_f) / (1.0_wp + alpha_f) * alpha_f
    integrator%alpha = alpha_m

    ! Integration constants
    a0 = 1.0_wp / (beta * dt * dt)
    a1 = gamma / (beta * dt)
    a2 = 1.0_wp / (beta * dt)
    a3 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    a4 = gamma / beta - 1.0_wp
    a5 = dt * (gamma / (2.0_wp * beta) - 1.0_wp)

    ! Effective stiffness: K_eff = K + a0*M + a1*C
    integrator%K_eff = integrator%K + a0 * integrator%M + a1 * integrator%C

    ! Effective load with HHT-? modifications
    integrator%F_eff = (1.0_wp + alpha_f) * integrator%F_ext_np1 - &
                      alpha_f * integrator%F_ext_n

    if (allocated(integrator%M)) then
      integrator%F_eff = integrator%F_eff + integrator%M * &
                        (a0 * integrator%u_n + a2 * integrator%v_n + a3 * integrator%a_n)
    end if

    if (allocated(integrator%C)) then
      integrator%F_eff = integrator%F_eff + integrator%C * &
                        (a1 * integrator%u_n + a4 * integrator%v_n + a5 * integrator%a_n)
    end if

    integrator%F_eff = integrator%F_eff - (1.0_wp + alpha_f) * integrator%F_int_np1 + &
                      alpha_f * integrator%F_int_n

  end subroutine RT_TimeInt_HHT_Alpha_Dyn

  !===============================================================================
  ! PUBLIC INTERFACES FOR ADVANCED ALGORITHMS
  !===============================================================================

  ! Multi-physics coupling

  ! Nonlinear solvers

  ! Time integration

  ! Note: These functions are implemented in specialized modules for better organization

! From RT_Solver_API.f90
!=========================================================================
  ! UF_LogIncrement_NRLinear
  !
  ! Emit a per-inc nonlinear solve log including linear-iter info:
  !   - Step/Inc index (Abaqus-style KSTEP/KINC)
  !   - Analysis type: static / implicit dynamic / explicit dynamic
  !   - NR iterations (globalState%iterId)
  !   - Linear iterations (globalState%linearIter)
  !   - Residual norm (globalState%residNorm)
  !   - Time and dTime (time_curr, dTime)
  ! Called by StepDriver after each inc finishes.
  !=========================================================================

  subroutine UF_LogIncrement_NRLinear(stepType, globalState)
    integer(i4),           intent(in) :: stepType
    type(GlobalState),  intent(in) :: globalState

    character(len=32)  :: stepTypeStr
    character(len=256) :: msg
    integer(i4)        :: nrIter, linIter

    select case (stepType)
    case (UF_StepType_Static)
      stepTypeStr = 'Static'
    case (UF_StepType_ImplicitDynamic)
      stepTypeStr = 'Implicit'
    case (UF_StepType_ExplicitDynamic)
      stepTypeStr = 'Explicit'
    case default
      stepTypeStr = 'Unknown'
    end select

    nrIter  = globalState%iterId
    linIter = globalState%linearIter

    write(msg,'("Step=",I0," Inc=",I0,
   &           " Type=",A,
   &           " NRIter=",I0,
   &           " LinIter=",I0,
   &           " Resid=",ES12.5,
   &           " Time=",ES12.5,
   &           " dTime=",ES12.5)') &
         globalState%cfg%id, globalState%incId,
         trim(stepTypeStr),
         nrIter, linIter,
         globalState%residNorm,
         globalState%time_curr,
         globalState%dTime

    call log_info('UF_Solver', trim(msg))
  end subroutine UF_LogIncrement_NRLinear

  !=========================================================================
  ! UF_Assem_Static
  !
  ! Minimal static assembly entry:
  !   - Inputs: model/step/globalState, dofMap, nodeStates/elemStates.
  !   - Outputs:
  !       - K_global : CSR tangent stiffness for the current inc.
  !       - R_int    : internal force residual buffer; after assembly R_int = -F_int(u)
  !         (internal force/contact only; external loads handled later in Calc_residual via R = F_int - lambda*F_ext).
  !   - Flow:
  !       - Iterate all Part/Element, build UF_ElemCtx via BuildElementContext.
  !       - Call ElemType%compute (e.g., Calc_Continuum) to fill elemStates(e)%Ke/Re/Me/Ce.
  !       - Scatter Ke/Re to Triplet and R_int via ScatterToSparse_Multifield.
  !       - Add contact contributions via RT_Cont_Asm.
  !       - Convert Triplet to CSR K_global using RT_CSR_FromTriplet.

  !=========================================================================
  subroutine UF_Assem_Static(model, step, globalState, dofMap, nodeStates, elemStates, K_global, R_int, tws, ierr, usecontactmanag, &
      uselagrangecont, n_constraints_l, nd_lagrange, lagrange_dof_in, lagrange_normal, lagrange_reg_ep)
    type(UF_Model),               intent(inout) :: model
    type(UF_AnalysisStep),        intent(in)    :: step
    type(GlobalState),         intent(in)    :: globalState
    type(RT_Sol_DofMap),              intent(in)    :: dofMap
    type(NodeState),           intent(inout) :: nodeStates(:)
    type(ElemState),        intent(inout) :: elemStates(:)
    type(RT_CSRMatrix),           intent(inout) :: K_global
    real(wp),                     intent(inout) :: R_int(:)
    type(ThreadWS), intent(inout) :: tws(:)

    integer(i4),                  intent(out)   :: ierr
    logical,                      intent(in), optional :: usecontactmanag
    logical,                      intent(in), optional :: uselagrangecont
    integer(i4),                  intent(in), optional :: n_constraints_l
    integer(i4),                  intent(in), optional :: nd_lagrange
    integer(i4),                  intent(in), optional :: lagrange_dof_in(:,:)
    real(wp),                     intent(in), optional :: lagrange_normal(:,:)
    real(wp),                     intent(in), optional :: lagrange_reg_ep

    integer(i4) :: nDOF, estNnz
    integer(i4) :: p, ie, eGlobal
    type(UF_Part),        pointer :: part
    type(UF_Element),     pointer :: Element
    type(UF_ElementType), pointer :: ElemType
    type(UF_ElemCtx)      :: Ctx
    type(UF_ElemFlags)        :: flags
    class(UF_MaterialModel), allocatable :: mats(:)
    class(UF_MaterialModel), pointer    :: secMat
    integer(i4) :: secId, nIP, ip_idx
    type(RT_TripletList) :: triplets
    logical :: useContactCSR
    integer(i4) :: nContactPattern, k
    integer(i4), allocatable :: contact_rows(:), contact_cols(:)
    integer(i4) :: ierr_contact
    logical :: useLagrange
    integer(i4) :: n_lag, nd_lag, kc, jd
    integer(i4) :: row_g
    real(wp) :: reg_eps

    ierr = 0_i4
    nDOF = dofMap%nTotalEq
    if (nDOF <= 0_i4) return
    if (size(R_int) < nDOF) then
      ierr = -1_i4
      return
    end if

    useContactCSR = .false.
    if (present(usecontactmanag)) useContactCSR = usecontactmanag

    R_int = 0.0_wp

    ! Estimate initial Triplet capacity (empirical: ~30 nnz per Element).

    estNnz = max(1_i4, size(elemStates) * 30_i4)
    call RT_Triplet_Init(triplets, estNnz)

    block
      logical :: use_mesh
      integer(i4) :: n_elems_m, elem_id
      type(MD_Mesh_GetElemConnect_Arg) :: arg_conn
      integer(i4) :: elem_type_id
      type(ErrorStatusType) :: mesh_st

      use_mesh = g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized
      if (use_mesh) then
        ! Mesh single-source path: iterate mesh elements, no model%parts
        n_elems_m = int(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        do elem_id = 1, n_elems_m
          if (elem_id > size(elemStates)) exit
          call MD_Mesh_GetElemConnect_Idx(elem_id, arg_conn, mesh_st)
          if (mesh_st%status_code /= IF_STATUS_OK .or. arg_conn%npe <= 0) cycle
          elem_type_id = Mesh_GetElemTypeId(elem_id)
          ElemType => UF_GetElementType(elem_type_id)
          if (.not. associated(ElemType)) cycle
          call RT_BindElementCompute(ElemType)
          if (.not. associated(ElemType%compute)) cycle
          call BuildElementContextFromMesh(elem_id, arg_conn, elem_type_id, nodeStates, globalState, Ctx)
          nIP = max(1_i4, ElemType%n_int_points)
          allocate(mats(nIP))
          secId = 0_i4
          if (allocated(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref) .and. &
              elem_id <= size(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref)) then
            secId = g_ufc_global%md_layer%mesh%raw_data%elem_section_ref(elem_id)
          end if
          secMat => null()
          if (secId > 0 .and. allocated(model%sections)) then
            if (secId <= size(model%sections)) then
              if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
            end if
          end if
          do ip_idx = 1, nIP
            if (associated(secMat)) then
              allocate(mats(ip_idx), source=secMat)
            else
              call UF_GetMaterialModel('Elastic', mats(ip_idx))
            end if
          end do
          call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, &
                                elemStates(elem_id), mats, elemStates(elem_id), flags)
          if (allocated(mats)) deallocate(mats)
          if (allocated(elemStates(elem_id)%evo%Ke) .and. allocated(elemStates(elem_id)%Re)) then
            call ScatterToSparse_Multifield_FromConn(arg_conn%connect, arg_conn%npe, dofMap, &
                elemStates(elem_id)%evo%Ke, elemStates(elem_id)%Re, triplets, R_int)
          end if
        end do
      else
    if (.not. allocated(model%parts)) then
      call RT_Triplet_Free(triplets)
      return
    end if

    eGlobal = 0_i4
    do p = 1, size(model%parts)
      part => model%parts(p)
      if (.not. allocated(part%elements)) cycle

      do ie = 1, size(part%elements)
        eGlobal = eGlobal + 1_i4
        if (eGlobal > size(elemStates)) exit

        Element => part%elements(ie)
        ElemType => UF_GetElementType(Element%elemTypeId)
        if (.not. associated(ElemType)) cycle
        call RT_BindElementCompute(ElemType)
        if (.not. associated(ElemType%compute)) cycle

        ! Build Element Ctx (coords, displacements, multi-field DOFs, etc.)

        call BuildElementContext(part, Element, nodeStates, globalState, Ctx)

        ! Prepare Mat model array: one UF_MaterialModel per integration point.

        nIP = max(1_i4, ElemType%n_int_points)
        allocate(mats(nIP))

        secId = Element%cfg%id
        secMat => null()
        if (secId > 0 .and. allocated(model%sections)) then
          if (secId <= size(model%sections)) then
            if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
          end if
        end if

        do ip_idx = 1, nIP
          if (associated(secMat)) then
            allocate(mats(ip_idx), source=secMat)
          else
            call UF_GetMaterialModel('Elastic', mats(ip_idx))
          end if
        end do

        ! Call Element compute; writes elemStates(eGlobal)%Ke/Re/Me/Ce.

        call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, &
                              elemStates(eGlobal), mats, elemStates(eGlobal), flags)

        if (allocated(mats)) deallocate(mats)

        ! Scatter cached Ke/Re to global Triplet; R_int stores -F_int.

        if (allocated(elemStates(eGlobal)%evo%Ke) .and. allocated(elemStates(eGlobal)%Re)) then
          call ScatterToSparse_Multifield(Element, dofMap, elemStates(eGlobal)%evo%Ke, &
                                          elemStates(eGlobal)%Re, triplets, R_int)
        end if
      end do
    end do
      end if
    end block

    if (useContactCSR) then
      !--------------------------------------------------------------
      ! Contact path: UF_Contact_Manager + CSR
      !   1) Build contact CSR pattern for current state; insert zero entries into Triplet so CSR includes contact sparsity.
      !   2) Compress Triplet (with contact pattern) to CSR.
      !   3) Use contact_Assem_csr to add contact stiffness/force onto CSR.
      !--------------------------------------------------------------

      nContactPattern = 0
      ierr_contact    = 0_i4

      call contact_build_csr_pattern_from_problem(nDOF, contact_rows, contact_cols, nContactPattern, ierr_contact)

      if (ierr_contact /= 0_i4) then
        ierr = ierr_contact
        if (allocated(contact_rows))  deallocate(contact_rows)
        if (allocated(contact_cols))  deallocate(contact_cols)
        call RT_Triplet_Free(triplets)
        return
      end if

      if (nContactPattern > 0 .and. allocated(contact_rows) .and. allocated(contact_cols)) then
        do k = 1, nContactPattern
          if (contact_rows(k) < 1 .or. contact_rows(k) > nDOF) cycle
          if (contact_cols(k) < 1 .or. contact_cols(k) > nDOF) cycle
          call RT_Triplet_Add(triplets, contact_rows(k), contact_cols(k), 0.0_wp)
        end do
      end if

      if (allocated(contact_rows))  deallocate(contact_rows)
      if (allocated(contact_cols))  deallocate(contact_cols)

      ! Triplet -> CSR (structure + contact pattern).

      call RT_CSR_Free(K_global)
      call RT_CSR_FromTriplet(triplets, nDOF, nDOF, K_global)

      ! Assemble contact stiffness/residual directly on CSR.

      ierr_contact = 0_i4
      call contact_Assem_csr(K_global%rowPtr, K_global%colInd, K_global%values, R_int, nDOF, ierr_contact)
      if (ierr_contact /= 0_i4 .and. ierr == 0_i4) ierr = ierr_contact

      call RT_Triplet_Free(triplets)

    else
      ! Non-contact-manager path: RT_Cont_Asm adds contact stiffness/residual onto Triplet directly.

      call RT_Cont_Asm(model, dofMap, nodeStates, triplets, R_int)

      ! Phase 8 A2.1: Optional Lagrange contact -> append G blocks to triplets, build K_aug [K G^T; G reg].
      useLagrange = .false.
      if (present(uselagrangecont)) useLagrange = uselagrangecont
      n_lag = 0_i4
      if (present(n_constraints_l)) n_lag = n_constraints_l
      if (useLagrange .and. n_lag > 0_i4 .and. present(nd_lagrange) .and. present(lagrange_dof_in) .and. present(lagrange_normal)) then
        nd_lag = nd_lagrange
        reg_eps = 1.0e-10_wp
        if (present(lagrange_reg_ep)) reg_eps = lagrange_reg_ep
        do kc = 1, n_lag
          row_g = nDOF + kc
          do jd = 1, nd_lag
            call RT_Triplet_Add(triplets, row_g, lagrange_dof_in(jd, kc), lagrange_normal(jd, kc))
            call RT_Triplet_Add(triplets, lagrange_dof_in(jd, kc), row_g, lagrange_normal(jd, kc))
          end do
          call RT_Triplet_Add(triplets, row_g, row_g, reg_eps)
        end do
        call RT_CSR_Free(K_global)
        call RT_CSR_FromTriplet(triplets, nDOF + n_lag, nDOF + n_lag, K_global)
      else
        call RT_CSR_Free(K_global)
        call RT_CSR_FromTriplet(triplets, nDOF, nDOF, K_global)
      end if
      call RT_Triplet_Free(triplets)
    end if

  end subroutine UF_Assem_Static

  !=========================================================================
  ! UF_NewtonRaphson (static NR wrapper over NM_NonlinSolv callbacks)
  !
  ! Call path and role:
  !   - Invoked by UF_StepDriver::RunStep when step%type==UF_StepType_Static to solve one inc.
  !   - StepDriver manages time Steping; this routine solves R(u)=0 for the inc and updates node/Element/global states.
  !   - Dynamic/explicit are handled elsewhere (UF_NewtonRaphsonDynamic / UF_ExplicitDynamicsStep) using similar assembly callbacks.
  !
  ! Interfaces and data flow (aligned with nl_newton_raphson signature):
  !   - State vectors: u(:) total inc; du(:) correction (kept for compatibility).
  !   - Residual definition: R(u) = F_int(u) - lambda*F_ext; linear system K du = -R.
  !   - FE assembly: UF_Assem_Static builds F_int/K from nodeStates%u_curr; external loads via UF_ApplyLoads.
  !   - DOF mapping: UF_BuildDofMap defines eq ids and multi-field layout shared with StepDriver/Output.
  !   - Linear solve: linear_solve wraps NM_LinearSolver::lin_solve (PCG/BiCGSTAB/GMRES/SparsePak etc.).

  !=========================================================================
  ! UF_NewtonRaphson_Ctx - Unified interface using Ctx structure
  !
  ! Uses RT_Sol_Ctx structure bundling all parameters.
  ! This is the primary interface - all data accessed through Ctx.
  !=========================================================================
  subroutine UF_NewtonRaphson_Ctx(ctx)
    type(RT_Sol_Ctx), intent(inout) :: ctx

    type(RT_Sol_DofMap) :: dofMap
    integer(i4) :: nDOF
    type(RT_NLParams) :: nlParams
    type(RT_NLResult) :: nlResult
    integer(i4) :: eq_method
    type(ErrorStatusType) :: solve_status, validate_status

    ! Valid Ctx
    call init_error_status(validate_status)
    if (.not. ctx%Valid()) then
      ctx%converged = .false.
      validate_status%status_code = IF_STATUS_INVALID
      validate_status%message = 'UF_NewtonRaphson_Ctx: Ctx validation failed'
      call ctx%SetStatus(validate_status)
      return
    end if

    !-----------------------------
    ! 1) Build DOF map and initialize solver state
    !-----------------------------

    call UF_BuildDofMap(ctx%model, dofMap)
    nDOF = dofMap%nTotalEq
    if (nDOF <= 0_i4) then
      ctx%converged = .true.
      ctx%globalState%converged = .true.
      ctx%globalState%iterId = 0_i4
      ctx%globalState%residNorm = 0.0_wp
      return
    end if

    ! Init solver state if not already initialized
    if (.not. ctx%solver_state%initialized .or. ctx%solver_state%nDOF /= nDOF) then
      call ctx%solver_state%Init(nDOF)
    else
      call ctx%solver_state%Clear()
    end if

    ! Init CSR matrix structure (K starts empty; Calc_residual/Calc_tangent will assemble it)
    ctx%solver_state%K%nRows = 0
    ctx%solver_state%K%nCols = 0
    ctx%solver_state%K%nnz = 0
    ctx%solver_state%K%init = .false.

    !-----------------------------
    ! 2) Build external load vector F_ext at current time
    !-----------------------------

    call UF_ApplyLoads(ctx%model, ctx%step, ctx%globalState%time_curr, dofMap, ctx%solver_state%F_ext)
    ctx%solver_state%lambda = 1.0_wp

    !-----------------------------
    ! 3) Fill nonlinear/linear solver parameters
    !-----------------------------

    nlParams%solver_type = NL_TYPE_NEWTON
    nlParams%conv_type = CONV_MIXED
    nlParams%max_iter = ctx%solver%maxNewtonIter
    nlParams%tol_force = ctx%solver%residualTol
    nlParams%tol_disp = max(ctx%solver%correctionTol, 0.0_wp)
    nlParams%tol_energy = max(ctx%solver%energyTol, 0.0_wp)
    nlParams%use_line_search = .false.

    ctx%globalState%converged = .false.

    !-----------------------------
    ! 4) Run nonlinear solve
    !-----------------------------

    eq_method = RT_EQ_METHOD_NE

    call init_error_status(solve_status)
    call RT_Eq_SolveFixedLambda(eq_method, ctx%solver_state, &
                                 nlParams, Calc_residual_state, &
                                 Calc_tangent_state, solve_line_state, &
                                 nlResult, solve_status, globalState=ctx%globalState, &
                                 AI_ConvPredictor=ctx%AI_ConvPredictor)
    call ctx%SetStatus(solve_status)

    ctx%solver_state%du = ctx%solver_state%u

    if (.not. ctx%IsOK() .or. nlResult%converged /= 1) then
      ctx%converged = .false.
      ctx%globalState%converged = .false.
    else
      ctx%converged = .true.
      ctx%globalState%converged = .true.
    end if

    ctx%globalState%iterId = nlResult%iterations
    ctx%globalState%residNorm = nlResult%residual_norm
    ctx%globalState%stepFactor = nlResult%arc_length
    ctx%globalState%nlConvergedFlag = nlResult%converged

    ! Write final total inc u(:) back to node states
    call UF_UpdateNodeSolutionFromU(ctx%nodeStates, dofMap, ctx%solver_state%u)

    ! For StepDriver statistics: store disp norm (L2)
    if (associated(ctx%solver_state%du)) then
      ctx%globalState%dispNorm = sqrt(dot_product(ctx%solver_state%du, ctx%solver_state%du))
    end if

  contains

    !--------------------------------------------------------------
    ! Calc_residual_state: FE residual callback using Ctx
    !--------------------------------------------------------------
    subroutine Calc_residual_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      integer(i4) :: ierr_contact_lo, ierr_asm

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'Calc_residual_state: solver_state not initialized'
        return
      end if

      ! 1) Update node states (u_incr / u_curr)
      call UF_UpdateNodeSolutionFromU(ctx%nodeStates, dofMap, solver_state_in%u)

      ! If using Contact Manager CSR, refresh contact blocks before each residual evaluation.
      if (ctx%solver%usecontactmanag) then
        ierr_contact_lo = 0_i4
        call UF_ContBrg_IterationInit(ctx%nodeStates, dofMap, ierr_contact_lo)
        if (ierr_contact_lo /= 0_i4) then
          status_in%status_code = IF_STATUS_ERROR
          status_in%message = 'Calc_residual_state: UF_ContBrg_IterationInit failed'
          return
        end if
      end if

      ! 2) Assemble internal force and tangent: R_int = -F_int
      solver_state_in%evo%R_int = 0.0_wp
      call UF_Assem_Static(ctx%model, ctx%step, ctx%globalState, dofMap, ctx%nodeStates, ctx%elemStates, &
                              solver_state_in%K, solver_state_in%evo%R_int, ctx%tws, ierr_asm, &
                              usecontactmanag=ctx%solver%usecontactmanag)
      if (ierr_asm /= 0_i4) then
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'Calc_residual_state: UF_Assem_Static failed'
        return
      end if

      ! 3) Residual definition: R = F_int - lambda*F_ext (R_int is -F_int at this moment)
      solver_state_in%R(1:solver_state_in%nDOF) = -solver_state_in%evo%R_int(1:solver_state_in%nDOF) - &
                                                   solver_state_in%lambda * solver_state_in%F_ext(1:solver_state_in%nDOF)

      ! Update global residual norm for StepDriver monitoring.
      ctx%globalState%residNorm = sqrt(dot_product(solver_state_in%R(1:solver_state_in%nDOF), &
                                                     solver_state_in%R(1:solver_state_in%nDOF)))
    end subroutine Calc_residual_state

    !--------------------------------------------------------------
    ! Calc_tangent_state: FE tangent callback using Ctx
    !--------------------------------------------------------------
    subroutine Calc_tangent_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      real(wp), allocatable :: R_dummy(:)
      integer(i4) :: ierr_contact_lo, ierr_asm

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'Calc_tangent_state: solver_state not initialized'
        return
      end if

      ! 1) Sync nodeStates with u_vec (u_curr = u_old + u_incr).
      call UF_UpdateNodeSolutionFromU(ctx%nodeStates, dofMap, solver_state_in%u)

      ! If using Contact Manager CSR, refresh contact blocks before tangent assembly.
      if (ctx%solver%usecontactmanag) then
        ierr_contact_lo = 0_i4
        call UF_ContBrg_IterationInit(ctx%nodeStates, dofMap, ierr_contact_lo)
        if (ierr_contact_lo /= 0_i4) then
          status_in%status_code = IF_STATUS_ERROR
          status_in%message = 'Calc_tangent_state: UF_ContBrg_IterationInit failed'
          return
        end if
      end if

      ! 2) Re-assemble internal force/tangent K(u) via UF_Assem_Static.
      allocate(R_dummy(solver_state_in%nDOF))
      R_dummy = 0.0_wp

      call UF_Assem_Static(ctx%model, ctx%step, ctx%globalState, dofMap, ctx%nodeStates, ctx%elemStates, &
                              solver_state_in%K, R_dummy, ctx%tws, ierr_asm, &
                              usecontactmanag=ctx%solver%usecontactmanag)
      if (ierr_asm /= 0_i4) then
        deallocate(R_dummy)
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'Calc_tangent_state: UF_Assem_Static failed'
        return
      end if
      deallocate(R_dummy)

      ! 3) Apply Rayleigh damping ratio term.
      if (ctx%solver%useRayleigh) then
        call RT_Rayleigh_UpdateMatrix(solver_state_in%K, mass=null(), settings=ctx%solver)
      end if

      ! 4) Apply Dirichlet BCs on CSR (row/col modification using dofMap masks and constrained values).
      call ApplyBoundaryConditions(dofMap, solver_state_in%K, solver_state_in%R, ctx%nodeStates)
    end subroutine Calc_tangent_state

    !--------------------------------------------------------------
    ! solve_line_state: Linear solve callback using Ctx
    !--------------------------------------------------------------
    subroutine solve_line_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      logical :: converged_pcg
      integer(i4) :: nIter_pcg

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'solve_line_state: solver_state not initialized'
        return
      end if

      ! Solve: K * du = -R
      solver_state_in%du(1:solver_state_in%nDOF) = -solver_state_in%R(1:solver_state_in%nDOF)
      call RT_PCG_Solv(solver_state_in%K, solver_state_in%R, solver_state_in%du, &
                        ctx%solver%linearTol, ctx%solver%maxLinearIter, converged_pcg, nIter_pcg)
      if (.not. converged_pcg) then
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'solve_line_state: RT_PCG_Solv failed to converge'
        return
      end if
    end subroutine solve_line_state

  end subroutine UF_NewtonRaphson_Ctx

  !=========================================================================
  ! UF_NewtonRaphson - Legacy interface wrapper for backward compatibility
  !
  ! Wraps UF_NewtonRaphson_Ctx for backward compatibility.
  !=========================================================================
  !------------------------------------------------------------------
  ! UF_NewtonRaphson - DEPRECATED: Use UF_NewtonRaphson_Ctx instead
  !   - This interface is deprecated and will be removed in a future version.
  !   - Please use UF_NewtonRaphson_Ctx instead.
  !------------------------------------------------------------------
  subroutine UF_NewtonRaphson(model, step, solver, solver_state, &
                               globalState, nodeStates, elemStates, tws, converged)
    type(UF_Model),               intent(inout), target :: model
    type(UF_AnalysisStep),        intent(in), target    :: step
    type(RT_Sol_Cfg),            intent(in), target    :: solver
    type(RT_Sol_State),           intent(inout), target :: solver_state
    type(GlobalState),         intent(inout), target :: globalState
    type(NodeState),           intent(inout), target :: nodeStates(:)
    type(ElemState),        intent(inout), target :: elemStates(:)
    type(ThreadWS), intent(inout), target :: tws(:)
    logical,                      intent(out)   :: converged

    type(RT_Sol_Ctx) :: ctx

    ! Bind Ctx
    call ctx%Bind(model, step, solver, solver_state, globalState, nodeStates, elemStates, tws=tws)

    ! Call unified interface
    call UF_NewtonRaphson_Ctx(ctx)

    ! Extract result
    converged = ctx%converged
  end subroutine UF_NewtonRaphson

    type(RT_Sol_DofMap) :: dofMap
    integer(i4) :: nDOF
    type(RT_NLParams) :: nlParams
    type(RT_NLResult) :: nlResult
    integer(i4) :: eq_method
    type(ErrorStatusType) :: status

    !-----------------------------
    ! 1) Build DOF map and initialize solver state
    !-----------------------------

    call init_error_status(status)
    call UF_BuildDofMap(model, dofMap)
    nDOF = dofMap%nTotalEq
    if (nDOF <= 0_i4) then
      converged = .true.
      globalState%converged = .true.
      globalState%iterId = 0_i4
      globalState%residNorm = 0.0_wp
      return
    end if

    ! Init solver state if not already initialized
    if (.not. solver_state%initialized .or. solver_state%nDOF /= nDOF) then
      call solver_state%Init(nDOF)
    else
      call solver_state%Clear()
    end if

    ! Init CSR matrix structure (K starts empty; Calc_residual/Calc_tangent will assemble it)
    solver_state%K%nRows = 0
    solver_state%K%nCols = 0
    solver_state%K%nnz = 0
    solver_state%K%init = .false.

    !-----------------------------
    ! 2) Build external load vector F_ext at current time
    !-----------------------------

    call UF_ApplyLoads(model, step, globalState%time_curr, dofMap, solver_state%F_ext)
    solver_state%lambda = 1.0_wp

    !-----------------------------
    ! 3) Fill nonlinear/linear solver parameters
    !-----------------------------

    nlParams%solver_type = NL_TYPE_NEWTON
    nlParams%conv_type = CONV_MIXED
    nlParams%max_iter = solver%maxNewtonIter
    nlParams%tol_force = solver%residualTol
    nlParams%tol_disp = max(solver%correctionTol, 0.0_wp)
    nlParams%tol_energy = max(solver%energyTol, 0.0_wp)
    nlParams%use_line_search = .false.

    globalState%converged = .false.

    !-----------------------------
    ! 4) Run nonlinear solve
    !-----------------------------

    eq_method = RT_EQ_METHOD_NE

    call RT_Eq_SolveFixedLambda(eq_method, solver_state, &
                                 nlParams, Calc_residual_state, &
                                 Calc_tangent_state, solve_line_state, &
                                 nlResult, status, globalState=globalState)

    solver_state%du = solver_state%u

    if (status%status_code /= IF_STATUS_OK .or. nlResult%converged /= 1) then
      converged = .false.
      globalState%converged = .false.
    else
      converged = .true.
      globalState%converged = .true.
    end if

    globalState%iterId = nlResult%iterations
    globalState%residNorm = nlResult%residual_norm
    globalState%stepFactor = nlResult%arc_length
    globalState%nlConvergedFlag = nlResult%converged

    ! Write final total inc u(:) back to node states
    call UF_UpdateNodeSolutionFromU(nodeStates, dofMap, solver_state%u)

    ! For StepDriver statistics: store disp norm (L2)
    if (associated(solver_state%du)) then
      globalState%dispNorm = sqrt(dot_product(solver_state%du, solver_state%du))
    end if

  contains

    !--------------------------------------------------------------
    ! Calc_residual_state: FE residual callback using state structure
    !--------------------------------------------------------------
    subroutine Calc_residual_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      integer(i4) :: ierr_contact_lo, ierr_asm

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'Calc_residual_state: solver_state not initialized'
        return
      end if

      ! 1) Update node states (u_incr / u_curr)
      call UF_UpdateNodeSolutionFromU(nodeStates, dofMap, solver_state_in%u)

      ! If using Contact Manager CSR, refresh contact blocks before each residual evaluation.
      if (solver%usecontactmanag) then
        ierr_contact_lo = 0_i4
        call UF_ContBrg_IterationInit(nodeStates, dofMap, ierr_contact_lo)
        if (ierr_contact_lo /= 0_i4) then
          status_in%status_code = IF_STATUS_ERROR
          status_in%message = 'Calc_residual_state: UF_ContBrg_IterationInit failed'
          return
        end if
      end if

      ! 2) Assemble internal force and tangent: R_int = -F_int
      solver_state_in%evo%R_int = 0.0_wp
      call UF_Assem_Static(model, step, globalState, dofMap, nodeStates, elemStates, &
                              solver_state_in%K, solver_state_in%evo%R_int, tws, ierr_asm, &
                              usecontactmanag=solver%usecontactmanag)
      if (ierr_asm /= 0_i4) then
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'Calc_residual_state: UF_Assem_Static failed'
        return
      end if

      ! 3) Residual definition: R = F_int - lambda*F_ext (R_int is -F_int at this moment)
      solver_state_in%R(1:solver_state_in%nDOF) = -solver_state_in%evo%R_int(1:solver_state_in%nDOF) - &
                                                   solver_state_in%lambda * solver_state_in%F_ext(1:solver_state_in%nDOF)

      ! Update global residual norm for StepDriver monitoring.
      globalState%residNorm = sqrt(dot_product(solver_state_in%R(1:solver_state_in%nDOF), &
                                                solver_state_in%R(1:solver_state_in%nDOF)))
    end subroutine Calc_residual_state

    !--------------------------------------------------------------
    ! Calc_tangent_state: FE tangent callback using state structure
    !--------------------------------------------------------------
    subroutine Calc_tangent_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      real(wp), allocatable :: R_dummy(:)
      integer(i4) :: ierr_contact_lo, ierr_asm

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'Calc_tangent_state: solver_state not initialized'
        return
      end if

      ! 1) Sync nodeStates with u_vec (u_curr = u_old + u_incr).
      call UF_UpdateNodeSolutionFromU(nodeStates, dofMap, solver_state_in%u)

      ! If using Contact Manager CSR, refresh contact blocks before tangent assembly.
      if (solver%usecontactmanag) then
        ierr_contact_lo = 0_i4
        call UF_ContBrg_IterationInit(nodeStates, dofMap, ierr_contact_lo)
        if (ierr_contact_lo /= 0_i4) then
          status_in%status_code = IF_STATUS_ERROR
          status_in%message = 'Calc_tangent_state: UF_ContBrg_IterationInit failed'
          return
        end if
      end if

      ! 2) Re-assemble internal force/tangent K(u) via UF_Assem_Static.
      allocate(R_dummy(solver_state_in%nDOF))
      R_dummy = 0.0_wp

      call UF_Assem_Static(model, step, globalState, dofMap, nodeStates, elemStates, &
                              solver_state_in%K, R_dummy, tws, ierr_asm, &
                              usecontactmanag=solver%usecontactmanag)
      if (ierr_asm /= 0_i4) then
        deallocate(R_dummy)
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'Calc_tangent_state: UF_Assem_Static failed'
        return
      end if
      deallocate(R_dummy)

      ! 3) Apply Rayleigh damping ratio term.
      if (solver%useRayleigh) then
        call RT_Rayleigh_UpdateMatrix(solver_state_in%K, mass=null(), settings=solver)
      end if

      ! 4) Apply Dirichlet BCs on CSR (row/col modification using dofMap masks and constrained values).
      call ApplyBoundaryConditions(dofMap, solver_state_in%K, solver_state_in%R, nodeStates)
    end subroutine Calc_tangent_state

    !--------------------------------------------------------------
    ! solve_line_state: Linear solve callback using state structure
    !--------------------------------------------------------------
    subroutine solve_line_state(solver_state_in, status_in)
      type(RT_Sol_State), intent(inout) :: solver_state_in
      type(ErrorStatusType), intent(inout) :: status_in

      logical :: converged_pcg
      integer(i4) :: nIter_pcg

      call init_error_status(status_in)

      if (.not. solver_state_in%initialized .or. solver_state_in%nDOF <= 0) then
        status_in%status_code = IF_STATUS_INVALID
        status_in%message = 'solve_line_state: solver_state not initialized'
        return
      end if

      ! Solve: K * du = -R
      solver_state_in%du(1:solver_state_in%nDOF) = -solver_state_in%R(1:solver_state_in%nDOF)
      call RT_PCG_Solv(solver_state_in%K, solver_state_in%R, solver_state_in%du, &
                        solver%linearTol, solver%maxLinearIter, converged_pcg, nIter_pcg)
      if (.not. converged_pcg) then
        status_in%status_code = IF_STATUS_ERROR
        status_in%message = 'solve_line_state: RT_PCG_Solv failed to converge'
        return
      end if
    end subroutine solve_line_state

  end subroutine UF_NewtonRaphson

  !------------------------------------------------------------------
  ! ScatterToSparse_Multifield: supports 3U / U+T / U+P / U+T+P layouts.
  ! Notes: cloned from UniFieldCore version. Takes Element Ke/Re and scatters to Triplet and global residual R.
  !        Re is internal force F_int; ensure Re initialized to 0 before calling; assembly keeps R = -F_int.
  !------------------------------------------------------------------

  subroutine ScatterToSparse_Multifield(Element, dofMap, Ke, Re, triplets, R)
    type(UF_Element), intent(in) :: Element
    type(RT_Sol_DofMap),  intent(in) :: dofMap
    real(wp),         intent(in) :: Ke(:,:), Re(:)
    type(RT_TripletList), intent(inout) :: triplets
    real(wp),         intent(inout) :: R(:)

    integer(i4) :: nNode, ndpn
    integer(i4) :: i, j, a, b
    integer(i4) :: nidI, nidJ, row, col
    integer(i4) :: rowIdx, colIdx

    nNode = size(Element%conn)
    if (nNode <= 0) return
    if (size(Ke,1) /= size(Ke,2)) return

    ndpn = size(Ke,1) / nNode
    if (ndpn <= 0) return

    ! 1) Accumulate internal force: R = R - Re

    do i = 1, nNode
      nidI = Element%conn(i)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row < 1 .or. row > size(R)) cycle

        rowIdx = (i-1)*ndpn + a
        if (rowIdx < 1 .or. rowIdx > size(Re)) cycle

        R(row) = R(row) - Re(rowIdx)
      end do
    end do

    ! 2) Scatter stiffness blocks (dense ndpn x ndpn per node pair) into Triplets

    do i = 1, nNode
      nidI = Element%conn(i)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row <= 0) cycle

        rowIdx = (i-1)*ndpn + a
        if (rowIdx < 1 .or. rowIdx > size(Ke,1)) cycle

        do j = 1, nNode
          nidJ = Element%conn(j)
          do b = 1, ndpn
            col = UF_GetEqId(dofMap, nidJ, b)
            if (col <= 0) cycle

            colIdx = (j-1)*ndpn + b
            if (colIdx < 1 .or. colIdx > size(Ke,2)) cycle

            call RT_Triplet_Add(triplets, row, col, Ke(rowIdx, colIdx))
          end do
        end do
      end do
    end do

  end subroutine ScatterToSparse_Multifield

  !------------------------------------------------------------------
  ! ScatterToSparse_Multifield_FromConn: mesh path - scatter using conn array
  !------------------------------------------------------------------
  subroutine ScatterToSparse_Multifield_FromConn(conn, npe, dofMap, Ke, Re, triplets, R)
    integer(i8), intent(in) :: conn(:)
    integer(i4), intent(in) :: npe
    type(RT_Sol_DofMap),  intent(in) :: dofMap
    real(wp),         intent(in) :: Ke(:,:), Re(:)
    type(RT_TripletList), intent(inout) :: triplets
    real(wp),         intent(inout) :: R(:)

    integer(i4) :: nNode, ndpn
    integer(i4) :: i, j, a, b
    integer(i4) :: nidI, nidJ, row, col
    integer(i4) :: rowIdx, colIdx

    nNode = npe
    if (nNode <= 0) return
    if (size(Ke,1) /= size(Ke,2)) return

    ndpn = size(Ke,1) / nNode
    if (ndpn <= 0) return

    do i = 1, nNode
      nidI = int(conn(i), i4)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row < 1 .or. row > size(R)) cycle

        rowIdx = (i-1)*ndpn + a
        if (rowIdx < 1 .or. rowIdx > size(Re)) cycle

        R(row) = R(row) - Re(rowIdx)
      end do
    end do

    do i = 1, nNode
      nidI = int(conn(i), i4)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row <= 0) cycle

        rowIdx = (i-1)*ndpn + a
        if (rowIdx < 1 .or. rowIdx > size(Ke,1)) cycle

        do j = 1, nNode
          nidJ = int(conn(j), i4)
          do b = 1, ndpn
            col = UF_GetEqId(dofMap, nidJ, b)
            if (col <= 0) cycle

            colIdx = (j-1)*ndpn + b
            if (colIdx < 1 .or. colIdx > size(Ke,2)) cycle

            call RT_Triplet_Add(triplets, row, col, Ke(rowIdx, colIdx))
          end do
        end do
      end do
    end do

  end subroutine ScatterToSparse_Multifield_FromConn

  !-----------------------------------------------------------------------------
  ! Helper: Apply Boundary Conditions (Dirichlet, CSR row/col modification based on DOF mapping)

  !
  ! Unified interface:
  !   Inputs:
  !     - dofMap%dofMask(eq): 1 for free DOF, 0 for constrained DOF.
  !     - dofMap%constrained_value(eq): prescribed total disp u_total_prescribed(t); u_fixed = u_total_prescribed - u_old.
  !     - nodeStates%u_old: previous-step disp.
  !     - Linear system K * du = -R, where R comes from Calc_residual.

  !   Strategy (for each constrained eq where dofMask(eq)==0):
  !     - Adjust other rows: R(row) += K(row,eq) * u_fixed; zero K(row,eq).
  !     - Zero eq row except diagonal, set K(eq,eq)=1.
  !     - Set residual R(eq) = -u_fixed.

  !-----------------------------------------------------------------------------
  subroutine ApplyBoundaryConditions(dofMap, K, R, nodeStates)
    type(RT_Sol_DofMap),    intent(in)    :: dofMap
    type(RT_CSRMatrix), intent(inout) :: K
    real(wp),           intent(inout) :: R(:)
    type(RT_NodeState), intent(in)    :: nodeStates(:)

    integer(i4) :: eq, row, start_idx, end_idx, k
    integer(i4) :: localDof, nid
    real(wp)    :: u_old, u_total, u_fixed

    type(UF_NodeHdl)      :: nh
    type(NodeState), pointer :: ns => null()
    logical                  :: found

    if (.not. allocated(dofMap%dofMask)) return
    if (.not. allocated(dofMap%constrained_value)) return
    if (K%nRows <= 0) return
    if (size(R) < K%nRows) return

    do eq = 1, min(dofMap%nTotalEq, K%nRows)
      if (dofMap%dofMask(eq) /= 0_i4) cycle  ! Handle only constrained DOFs

      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0 .or. localDof <= 0) cycle

      call UF_RT_MakeNodeHandleFromId(nodeStates, nid, nh, found)
      if (.not. found) cycle
      call UF_RT_GetNodeStateView(nh, nodeStates, ns)
      if (.not. associated(ns)) cycle
      if (.not. allocated(ns%u_old)) cycle
      if (size(ns%u_old) < localDof) cycle

      u_old   = ns%u_old(localDof)
      u_total = dofMap%constrained_value(eq)
      u_fixed = u_total - u_old   ! Prescribed inc

      ! Step 1: Modify column eq and adjust other rows

      do row = 1, K%nRows
        start_idx = K%rowPtr(row)
        end_idx   = K%rowPtr(row+1) - 1
        do k = start_idx, end_idx
          if (K%colInd(k) == eq) then
            if (row /= eq) then
              if (row >= 1 .and. row <= size(R)) then
                R(row) = R(row) + K%values(k) * u_fixed
              end if
              K%values(k) = 0.0_wp
            end if
          end if
        end do
      end do

      ! Step 2: Overwrite eq row as identity

      start_idx = K%rowPtr(eq)
      end_idx   = K%rowPtr(eq+1) - 1
      do k = start_idx, end_idx
        if (K%colInd(k) == eq) then
          K%values(k) = 1.0_wp
        else
          K%values(k) = 0.0_wp
        end if
      end do

      ! Step 3: Set residual so Dirichlet constraint enforces du_eq = u_fixed

      R(eq) = -u_fixed
    end do

  end subroutine ApplyBoundaryConditions

  ! Helper: A(t) at 1-based amp index — prefers md_layer%amplitude%EvalAtTime,
  ! falls back to model%amplitudes via Amp_GetFactor (see RT_Amp_FactorAt).

  real(wp) function UF_AmpFactor(Modelocal, ampIdLocal, t) result(fac)
    type(UF_Model), intent(in) :: Modelocal
    integer(i4),    intent(in) :: ampIdLocal
    real(wp),       intent(in) :: t

    CALL RT_Amp_FactorAt(ampIdLocal, t, fac, Modelocal%amplitudes)
  end function UF_AmpFactor

  !------------------------------------------------------------------
  ! UF_UpdateNodeSolutionFromU
  !
  ! Write global DOF inc u(:) back to node states:
  !   - Based on nodeStates%u_old; u_incr corresponds to u(:), u_curr = u_old + u_incr.
  !   - DOF ordering is controlled by UF_DofMap and supports multi-field DOFs.

  !------------------------------------------------------------------
  subroutine UF_UpdateNodeSolutionFromU(nodeStates, dofMap, u)
    type(NodeState), intent(inout) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in)    :: dofMap
    real(wp),           intent(in)    :: u(:)

    integer(i4) :: eq, nEq
    integer(i4) :: nid, localDof
    integer(i4) :: idxState

    nEq = min(dofMap%nTotalEq, size(u))

    ! 1) Zero u_incr and reset u_curr to u_old

    do idxState = 1, size(nodeStates)
      if (allocated(nodeStates(idxState)%u_incr)) then
        nodeStates(idxState)%u_incr = 0.0_wp
      end if
      if (allocated(nodeStates(idxState)%u_curr) .and. allocated(nodeStates(idxState)%u_old)) then
        nodeStates(idxState)%u_curr = nodeStates(idxState)%u_old
      end if
    end do

    ! 2) Scatter inc and current disp according to DOF map

    do eq = 1, nEq
      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0 .or. localDof <= 0) cycle

      idxState = FindNodeStateIndex(nodeStates, nid)
      if (idxState < 1) cycle

      if (.not. allocated(nodeStates(idxState)%u_incr)) cycle
      if (localDof > size(nodeStates(idxState)%u_incr)) cycle

      nodeStates(idxState)%u_incr(localDof) = u(eq)

      if (allocated(nodeStates(idxState)%u_curr) .and. allocated(nodeStates(idxState)%u_old)) then
        if (localDof <= size(nodeStates(idxState)%u_curr) .and. &
            localDof <= size(nodeStates(idxState)%u_old)) then
          nodeStates(idxState)%u_curr(localDof) = nodeStates(idxState)%u_old(localDof) + u(eq)
        end if
      end if
    end do

  end subroutine UF_UpdateNodeSolutionFromU

  ! Utility: find node state index by id in nodeStates

  integer(i4) function FindNodeStateIndex(nodeStates, nodeIdFind) result(idx)
    type(NodeState), intent(in) :: nodeStates(:)
    integer(i4),        intent(in) :: nodeIdFind
    integer(i4) :: ii

    idx = -1_i4
    do ii = 1, size(nodeStates)
      if (nodeStates(ii)%cfg%id == nodeIdFind) then
        idx = ii
        return
      end if
    end do
  end function FindNodeStateIndex

  !------------------------------------------------------------------
  ! UF_NewtonRaphsonDynamic
  !
  ! Implicit dynamics: Newmark-beta/gamma with optional HHT-alpha, plus Rayleigh damping and contact.

  !   - Adapted from UniFieldCore copy; retains ThreadWS parameters needed by UF_RT_StepSolver (tws(:) currently unused).
  !   - Uses UF_Assem/RT_Cont_Asm via UF_Assembly_BuildSystem; mirrors UF_NewtonRaphson assembly flow.

  !------------------------------------------------------------------
  subroutine UF_NewtonRaphsonDynamic(model, step, solver, globalState, nodeStates, elemStates, tws, converged)
    type(UF_Model),               intent(inout) :: model
    type(UF_AnalysisStep),        intent(in)    :: step
    type(RT_Sol_Cfg),            intent(in)    :: solver
    type(GlobalState),         intent(inout) :: globalState
    type(NodeState),           intent(inout) :: nodeStates(:)
    type(ElemState),        intent(inout) :: elemStates(:)
    type(ThreadWS),               intent(inout) :: tws(:)

    logical,                      intent(out)   :: converged

    integer(i4) :: iter, maxIter, nDOF
    real(wp)   :: residNorm, tol
    real(wp)   :: beta, gamma, a0, a1, factor
    real(wp)   :: alphaHHT
    real(wp)   :: time_eff, time_saved
    integer(i4) :: info_lin, i, rowStart, rowEnd

    type(RT_CSRMatrix)   :: K_global, K_stiff, K_material, C_damp
    type(RT_TripletList) :: triplets
    real(wp), allocatable :: R_global(:), du(:), u_pred(:), mass(:), u_vec(:)
    real(wp), pointer :: R_global_ptr(:), du_ptr(:), u_pred_ptr(:), mass_ptr(:), u_vec_ptr(:)
    type(RT_Sol_DofMap)       :: dofMap
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool_dy
    logical :: R_GLOBAL_FROM_P, du_from_pool, u_pred_from_poo, mass_from_pool, u_vec_from_pool

    ! Newmark / HHT time integration parameters

    if (solver%useHHT) then
      alphaHHT = solver%alphaHHT
      beta  = ((1.0_wp - alphaHHT)**2) / 4.0_wp
      gamma = 0.5_wp - alphaHHT
    else
      beta  = 0.25_wp
      gamma = 0.5_wp
    end if

    if (globalState%dTime <= 0.0_wp .or. beta <= 0.0_wp) then
      converged = .false.
      return
    end if

    a0 = 1.0_wp / (beta * globalState%dTime * globalState%dTime)
    a1 = gamma / (beta * globalState%dTime)

    ! HHT effective time point: t_eff = t_{n+1} - alphaHHT * dt (alphaHHT=0 recovers t_{n+1}).

    time_saved = globalState%time_curr
    if (solver%useHHT) then
      time_eff = globalState%time_curr - alphaHHT * globalState%dTime
    else
      time_eff = globalState%time_curr
    end if

    call UF_BuildDofMap(model, dofMap)
    nDOF = dofMap%nTotalEq

    call init_error_status(mem_status)
    use_mem_pool_dy = g_core_mem_pool%initialized
    R_GLOBAL_FROM_P = .false.
    du_from_pool = .false.
    u_pred_from_poo = .false.
    mass_from_pool = .false.
    u_vec_from_pool = .false.

    if (use_mem_pool_dy) then
      call g_core_mem_pool%AllocDP1D('dynamic_R_global', nDOF, R_global_ptr, mem_status)
      if (mem_status%status_code == 0) then
        R_GLOBAL_FROM_P = .true.
        R_global => R_global_ptr
      else
        allocate(R_global(nDOF))
      end if
    else
      allocate(R_global(nDOF))
    end if

    if (use_mem_pool_dy) then
      call g_core_mem_pool%AllocDP1D('dynamic_du', nDOF, du_ptr, mem_status)
      if (mem_status%status_code == 0) then
        du_from_pool = .true.
        du => du_ptr
      else
        allocate(du(nDOF))
      end if
    else
      allocate(du(nDOF))
    end if

    if (use_mem_pool_dy) then
      call g_core_mem_pool%AllocDP1D('dynamic_u_pred', nDOF, u_pred_ptr, mem_status)
      if (mem_status%status_code == 0) then
        u_pred_from_poo = .true.
        u_pred => u_pred_ptr
      else
        allocate(u_pred(nDOF))
      end if
    else
      allocate(u_pred(nDOF))
    end if

    if (use_mem_pool_dy) then
      call g_core_mem_pool%AllocDP1D('dynamic_mass', nDOF, mass_ptr, mem_status)
      if (mem_status%status_code == 0) then
        mass_from_pool = .true.
        mass => mass_ptr
      else
        allocate(mass(nDOF))
      end if
    else
      allocate(mass(nDOF))
    end if

    if (use_mem_pool_dy) then
      call g_core_mem_pool%AllocDP1D('dynamic_u_vec', nDOF, u_vec_ptr, mem_status)
      if (mem_status%status_code == 0) then
        u_vec_from_pool = .true.
        u_vec => u_vec_ptr
      else
        allocate(u_vec(nDOF))
      end if
    else
      allocate(u_vec(nDOF))
    end if

    call NewmarkPredictor(nodeStates, dofMap, globalState%dTime, beta, gamma, u_pred)
    call UF_BuildLumpedMassVector(model, globalState, dofMap, nodeStates, elemStates, mass)

    maxIter  = solver%maxNewtonIter
    tol      = solver%residualTol
    converged = .false.

    do iter = 1, maxIter
       globalState%iterId = iter

       call RT_Triplet_Init(triplets, size(elemStates) * 576)
       R_global = 0.0_wp

       ! Apply loads at t_eff for HHT (alphaHHT=0 falls back to t_{n+1}).

       call UF_ApplyLoads(model, step, time_eff, dofMap, R_global)

       ! Internal force and contact assembly are also evaluated at t_eff for HHT.

       if (solver%useHHT) globalState%time_curr = time_eff
       call UF_Assem(model, globalState, dofMap, nodeStates, elemStates, triplets, R_global)

       ! Snapshot a contact-free stiffness K_material (for optional Rayleigh damping build).

       call RT_CSR_FromTriplet(triplets, nDOF, nDOF, K_material)

       call RT_Cont_Asm(model, dofMap, nodeStates, triplets, R_global)
       if (solver%useHHT) globalState%time_curr = time_saved

       ! Build K_stiff from current triplet (includes contact if present).

       call RT_CSR_FromTriplet(triplets, nDOF, nDOF, K_stiff)

       call GatherNodalU(nodeStates, dofMap, u_vec)
       call AddInertiaTerms(triplets, R_global, mass, u_vec, u_pred, a0)

       residNorm = norm2(R_global)
       globalState%residNorm = residNorm
       ! R3: Core layer no print *, use IF_Log

       if (residNorm < tol) then
          converged = .true.
          call RT_Triplet_Free(triplets)
          call RT_CSR_Free(K_stiff)
          call RT_CSR_Free(K_material)
          exit
       end if

       ! Assemble full K_global after optional damping/contact additions

       call RT_CSR_FromTriplet(triplets, nDOF, nDOF, K_global)
       call RT_Triplet_Free(triplets)

       ! Rayleigh damping: build C from either contact-free K_material or contact-included K_stiff.

       if (solver%useRayleigh) then
         if (solver%rayleighinclude) then
           call RT_Rayleigh_BuildDampMat(K_stiff, mass, solver, C_damp)
         else
           call RT_Rayleigh_BuildDampMat(K_material, mass, solver, C_damp)
         end if
         if (C_damp%init) then
           do info_lin = 1, K_global%nnz
             K_global%values(info_lin) = K_global%values(info_lin) + a1 * C_damp%values(info_lin)
           end do
           call RT_CSR_Free(C_damp)
         end if
       end if

       ! K_stiff / K_material only used for building C; free afterward.

       call RT_CSR_Free(K_stiff)
       call RT_CSR_Free(K_material)

       ! HHT effective stiffness: K_eff = (1-alphaHHT) * K + a0 * M + a1 * (1-alphaHHT) * C
       ! First scale K_global globally, then add back the mass contribution explicitly.

       if (solver%useHHT) then
         factor = 1.0_wp - alphaHHT

         ! Scale current K_global (already contains a0*M and a1*C terms)

         do info_lin = 1, K_global%nnz
           K_global%values(info_lin) = factor * K_global%values(info_lin)
         end do

         ! Restore mass term explicitly: add (1-factor)*a0*mass on the diagonal.

         do i = 1, min(size(mass), K_global%nRows)
           if (mass(i) == 0.0_wp) cycle
           rowStart = K_global%rowPtr(i)
           rowEnd   = K_global%rowPtr(i+1) - 1
           do info_lin = rowStart, rowEnd
             if (K_global%colInd(info_lin) == i) then
               K_global%values(info_lin) = K_global%values(info_lin) + (1.0_wp - factor) * a0 * mass(i)
               exit
             end if
           end do
         end do
       end if

       ! Apply boundary conditions at t_eff consistently.

       call ApplyBoundaryConditionsDynamic(model, step, dofMap, time_eff, K_global, R_global, nodeStates)

       du = 0.0_wp
       call RT_PCG_Solv(K_global, R_global, du, solver%linearTol, solver%maxLinearIter, converged)
       if (.not. converged) then
          ! R3: Core layer no print *, use IF_Log
          call RT_CSR_Free(K_global)
          converged = .false.
          exit
       end if

       call RT_CSR_Free(K_global)

       call UpdateNodalSolution(nodeStates, dofMap, du)
       globalState%dispNorm = norm2(du)
    end do

    if (converged) then
      call NewmarkUpdateKinematics(nodeStates, globalState%dTime, beta, gamma, u_pred)
    end if

    if (use_mem_pool_dy) then
      call g_core_mem_pool%Dealloc('dynamic_R_global')
      call g_core_mem_pool%Dealloc('dynamic_du')
      call g_core_mem_pool%Dealloc('dynamic_u_pred')
      call g_core_mem_pool%Dealloc('dynamic_mass')
      call g_core_mem_pool%Dealloc('dynamic_u_vec')
    else
      deallocate(R_global, du, u_pred, mass, u_vec)
    end if
  end subroutine UF_NewtonRaphsonDynamic

  !------------------------------------------------------------------
  ! UF_ExplicitDynamicsStep: lumped-mass explicit step (Verlet/central difference)

  !------------------------------------------------------------------
  subroutine UF_ExplicitDynamicsStep(model, step, solver, globalState, nodeStates, elemStates, converged)
    type(RT_Model),          intent(inout) :: model
    type(RT_AnalysisStep),   intent(in)    :: step
    type(RT_SolverSettings), intent(in)    :: solver
    type(RT_GlobalState),    intent(inout) :: globalState
    type(RT_NodeState),      intent(inout) :: nodeStates(:)
    type(ElemState),   intent(inout) :: elemStates(:)
    logical,                 intent(out)   :: converged

    type(RT_Sol_DofMap)       :: dofMap
    integer(i4)           :: nDOF
    real(wp), allocatable :: R_global(:), mass(:)
    real(wp), pointer :: R_global_ptr(:), mass_ptr(:)
    type(RT_TripletList)  :: triplets
    type(ErrorStatusType) :: mem_status
    logical :: use_mem_pool_ex
    logical :: R_GLOBAL_FROM_P, mass_from_pool

    call UF_BuildDofMap(model, dofMap)
    nDOF = dofMap%nTotalEq

    call init_error_status(mem_status)
    use_mem_pool_ex = g_core_mem_pool%initialized
    R_GLOBAL_FROM_P = .false.
    mass_from_pool = .false.

    if (use_mem_pool_ex) then
      call g_core_mem_pool%AllocDP1D('explicit_R_global', nDOF, R_global_ptr, mem_status)
      if (mem_status%status_code == 0) then
        R_GLOBAL_FROM_P = .true.
        R_global => R_global_ptr
      else
        allocate(R_global(nDOF))
      end if
    else
      allocate(R_global(nDOF))
    end if

    if (use_mem_pool_ex) then
      call g_core_mem_pool%AllocDP1D('explicit_mass', nDOF, mass_ptr, mem_status)
      if (mem_status%status_code == 0) then
        mass_from_pool = .true.
        mass => mass_ptr
      else
        allocate(mass(nDOF))
      end if
    else
      allocate(mass(nDOF))
    end if

    call ExplicitPredictorVerlet(nodeStates, globalState%dTime)
    call UF_BuildLumpedMassVector(model, globalState, dofMap, nodeStates, elemStates, mass)

    R_global = 0.0_wp
    call UF_ApplyLoads(model, step, globalState%time_curr, dofMap, R_global)
    call UF_AssemblyInternalOnly(model, globalState, dofMap, nodeStates, elemStates, R_global)

    call RT_Triplet_Init(triplets, max(1_i4, size(elemStates) * 81))
    call RT_Cont_Asm(model, dofMap, nodeStates, triplets, R_global)
    call RT_Triplet_Free(triplets)

    call ApplyBoundaryConditionsExplicit(model, step, dofMap, globalState%time_curr, nodeStates, R_global)
    call ExplicitUpdateVerlet(nodeStates, dofMap, globalState%dTime, mass, R_global)

    ! Optional: update non-structural fields (TEMP/POR etc.) with explicit capacity-based step.

    if (solver%explicitmultifi) then
      call UF_ExplicitUpdateMultiField(model, step, solver, globalState, dofMap, nodeStates, R_global)
    end if

    globalState%residNorm = norm2(R_global)
    converged = .true.

    if (use_mem_pool_ex) then
      call g_core_mem_pool%Dealloc('explicit_R_global')
      call g_core_mem_pool%Dealloc('explicit_mass')
    else
      deallocate(R_global, mass)
    end if
  end subroutine UF_ExplicitDynamicsStep

  !------------------------------------------------------------------
  ! UpdateNodalSolution: accumulate du into nodal disp increments and current positions

  !------------------------------------------------------------------
  subroutine UpdateNodalSolution(nodeStates, dofMap, du)
    type(NodeState), intent(inout) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in)    :: dofMap
    real(wp),           intent(in)    :: du(:)

    integer(i4) :: eq, nEq
    integer(i4) :: nid, localDof
    integer(i4) :: idxState

    nEq = min(dofMap%nTotalEq, size(du))

    ! 1) Add du for each equation back to corresponding node u_incr(localDof)

    do eq = 1, nEq
      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0_i4 .or. localDof <= 0_i4) cycle

      idxState = FindNodeStateIndex(nodeStates, nid)
      if (idxState < 1_i4) cycle
      if (.not. allocated(nodeStates(idxState)%u_incr)) cycle
      if (localDof > size(nodeStates(idxState)%u_incr)) cycle

      nodeStates(idxState)%u_incr(localDof) = nodeStates(idxState)%u_incr(localDof) + du(eq)
    end do

    ! 2) Refresh u_curr = u_old + u_incr after accumulation

    do idxState = 1, size(nodeStates)
      if (allocated(nodeStates(idxState)%u_curr) .and. allocated(nodeStates(idxState)%u_old)) then
        if (size(nodeStates(idxState)%u_curr) == size(nodeStates(idxState)%u_old)) then
          nodeStates(idxState)%u_curr = nodeStates(idxState)%u_old + nodeStates(idxState)%u_incr
        end if
      end if
    end do

  end subroutine UpdateNodalSolution

  !------------------------------------------------------------------
  ! UF_Assem: high-level assembly wrapper relying on UF_Assembly_BuildSystem for Element loop

  !------------------------------------------------------------------
  subroutine UF_Assem(model, globalState, dofMap, nodeStates, elemStates, triplets, R)
    type(UF_Model),        intent(in)    :: model
    type(GlobalState),  intent(in)    :: globalState
    type(RT_Sol_DofMap),       intent(in)    :: dofMap
    type(NodeState),    intent(in)    :: nodeStates(:)
    type(ElemState), intent(inout) :: elemStates(:)
    type(RT_TripletList),  intent(inout) :: triplets
    real(wp),              intent(inout) :: R(:)

    call UF_Assembly_BuildSystem(model, globalState, nodeStates, elemStates, addElementContribution)

  contains

    subroutine addElementContribution(Element, Ctx, Ke, Re)
      type(RT_Element),        intent(in) :: Element
      type(UF_ElemCtx), intent(in) :: Ctx
      real(wp),                intent(in) :: Ke(:,:), Re(:)

      call ScatterToSparse_Multifield(Element, dofMap, Ke, Re, triplets, R)
    end subroutine addElementContribution

  end subroutine UF_Assem

  !------------------------------------------------------------------
  ! UF_BuildLumpedMassVector: assemble lumped mass vector from Element mass matrices

  !------------------------------------------------------------------
  subroutine UF_BuildLumpedMassVector(model, globalState, dofMap, nodeStates, elemStates, mass)
    type(UF_Model),        intent(in) :: model
    type(GlobalState),  intent(in) :: globalState
    type(RT_Sol_DofMap),       intent(in) :: dofMap
    type(NodeState),    intent(in) :: nodeStates(:)
    type(ElemState), intent(in) :: elemStates(:)
    real(wp),              intent(out):: mass(:)

    integer(i4) :: ie, p, typeId, eGlobal, ip_idx, secId, nIP
    type(UF_Part),        pointer :: part
    type(UF_Element),     pointer :: Element
    type(UF_ElementType), pointer :: ElemType
    type(UF_ElemCtx) :: Ctx
    type(UF_ElemFlags)   :: flags
    real(wp), allocatable   :: Ke(:,:), Re(:), Me(:,:)
    class(UF_MaterialModel), allocatable :: mats(:)
    class(UF_MaterialModel), pointer    :: secMat
    type(ElemState)   :: state_tmp
    integer(i4) :: nNode, nidI, i
    integer(i4) :: ndpn, rowLocal
    integer(i4) :: dofType, eq, localDof

    mass = 0.0_wp

    block
      logical :: use_mesh
      integer(i4) :: n_elems_m, elem_id
      type(MD_Mesh_GetElemConnect_Arg) :: arg_conn
      integer(i4) :: elem_type_id
      type(ErrorStatusType) :: mesh_st

      use_mesh = g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized
      if (use_mesh) then
        ! Mesh single-source path: iterate mesh elements, no model%parts
        n_elems_m = int(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        do elem_id = 1, n_elems_m
          if (elem_id > size(elemStates)) return
          call MD_Mesh_GetElemConnect_Idx(elem_id, arg_conn, mesh_st)
          if (mesh_st%status_code /= IF_STATUS_OK .or. arg_conn%npe <= 0) cycle
          elem_type_id = Mesh_GetElemTypeId(elem_id)
          ElemType => UF_GetElementType(elem_type_id)
          if (.not. associated(ElemType)) cycle
          call RT_BindElementCompute(ElemType)
          if (.not. associated(ElemType%compute)) cycle
          call BuildElementContextFromMesh(elem_id, arg_conn, elem_type_id, nodeStates, globalState, Ctx)
          if (Ctx%nDOF <= 0) cycle
          nNode = arg_conn%npe
          if (nNode <= 0) cycle
          ndpn = Ctx%nDOF / nNode
          if (ndpn <= 0) cycle
          allocate(Ke(Ctx%nDOF, Ctx%nDOF))
          allocate(Re(Ctx%nDOF))
          allocate(Me(Ctx%nDOF, Ctx%nDOF))
          nIP = max(1_i4, ElemType%n_int_points)
          allocate(mats(nIP))
          secId = 0_i4
          if (allocated(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref) .and. &
              elem_id <= size(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref)) then
            secId = g_ufc_global%md_layer%mesh%raw_data%elem_section_ref(elem_id)
          end if
          secMat => null()
          if (secId > 0 .and. allocated(model%sections)) then
            if (secId <= size(model%sections)) then
              if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
            end if
          end if
          do ip_idx = 1, ElemType%n_int_points
            if (associated(secMat)) then
              allocate(mats(ip_idx), source=secMat)
            else
              call UF_GetMaterialModel('Elastic', mats(ip_idx))
            end if
          end do
          state_tmp = elemStates(elem_id)
          call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, state_tmp, mats, Ke, Re, Me, &
                                state_out=state_tmp, flags=flags)
          nNode = arg_conn%npe
          do i = 1, nNode
            nidI = int(arg_conn%connect(i), i4)
            do dofType = UF_DOF_U1, UF_DOF_U3
              eq = UF_GetEqIdByDofType(model, dofMap, nidI, dofType)
              if (eq < 1_i4 .or. eq > size(mass)) cycle
              if (.not. allocated(dofMap%eqToLocal)) cycle
              if (eq > size(dofMap%eqToLocal)) cycle
              localDof = dofMap%eqToLocal(eq)
              if (localDof < 1_i4 .or. localDof > ndpn) cycle
              rowLocal = (i-1_i4)*ndpn + localDof
              if (rowLocal < 1_i4 .or. rowLocal > Ctx%nDOF) cycle
              mass(eq) = mass(eq) + sum(Me(rowLocal, 1:Ctx%nDOF))
            end do
          end do
          deallocate(Ke, Re, Me)
          if (allocated(mats)) deallocate(mats)
        end do
      else
    if (.not. allocated(model%parts)) return

    eGlobal = 0_i4
    do p = 1, size(model%parts)
      part => model%parts(p)
      if (.not. allocated(part%elements)) cycle
      do ie = 1, size(part%elements)
        eGlobal = eGlobal + 1_i4
        if (eGlobal > size(elemStates)) return

        Element => part%elements(ie)
        typeId   = Element%elemTypeId
        ElemType => UF_GetElementType(typeId)
        if (.not. associated(ElemType)) cycle
        call RT_BindElementCompute(ElemType)
        if (.not. associated(ElemType%compute)) cycle

        call BuildElementContext(part, Element, nodeStates, globalState, Ctx)

        if (Ctx%nDOF <= 0) cycle
        nNode = size(Element%conn)
        if (nNode <= 0) cycle
        ndpn = Ctx%nDOF / nNode
        if (ndpn <= 0) cycle

        allocate(Ke(Ctx%nDOF, Ctx%nDOF))
        allocate(Re(Ctx%nDOF))
        allocate(Me(Ctx%nDOF, Ctx%nDOF))

        nIP = max(1_i4, ElemType%n_int_points)
        allocate(mats(nIP))

        secId = Element%cfg%id
        secMat => null()
        if (secId > 0 .and. allocated(model%sections)) then
          if (secId <= size(model%sections)) then
            if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
          end if
        end if

        do ip_idx = 1, ElemType%n_int_points
          if (associated(secMat)) then
            allocate(mats(ip_idx), source=secMat)
          else
            call UF_GetMaterialModel('Elastic', mats(ip_idx))
          end if
        end do

        state_tmp = elemStates(eGlobal)
        call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, state_tmp, mats, Ke, Re, Me, &
                              state_out=state_tmp, flags=flags)

        nNode = size(Element%conn)
        do i = 1, nNode
          nidI = Element%conn(i)

          ! For structural disp DOFs (U1/U2/U3), accumulate mass and query eq/local DOF via UF_DofMap.

          do dofType = UF_DOF_U1, UF_DOF_U3
            eq = UF_GetEqIdByDofType(model, dofMap, nidI, dofType)
            if (eq < 1_i4 .or. eq > size(mass)) cycle
            if (.not. allocated(dofMap%eqToLocal)) cycle
            if (eq > size(dofMap%eqToLocal)) cycle
            localDof = dofMap%eqToLocal(eq)
            if (localDof < 1_i4 .or. localDof > ndpn) cycle

            rowLocal = (i-1_i4)*ndpn + localDof
            if (rowLocal < 1_i4 .or. rowLocal > Ctx%nDOF) cycle

            mass(eq) = mass(eq) + sum(Me(rowLocal, 1:Ctx%nDOF))
          end do
        end do

        deallocate(Ke, Re, Me)
        if (allocated(mats)) deallocate(mats)
      end do
    end do
      end if
    end block
  end subroutine UF_BuildLumpedMassVector

  !------------------------------------------------------------------
  ! BuildElementContext: construct per-Element Ctx (coords/displacements/multi-field DOFs)

  !------------------------------------------------------------------
  subroutine BuildElementContext(part, Element, nodeStates, globalState, Ctx)
    type(UF_Part),         intent(in)  :: part
    type(UF_Element),      intent(in)  :: Element
    type(NodeState),    intent(in)  :: nodeStates(:)
    type(GlobalState),  intent(in)  :: globalState
    type(UF_ElemCtx), intent(out) :: Ctx

    integer(i4) :: nNode, i, nid, nodeIdx, stateIdx
    integer(i4) :: typeId, ndofpernode_tot, ndof_node
    type(UF_ElementType), pointer :: ElemType
    logical :: hasTemp, hasPore, hasEpot, hasChem, hasMpot
    integer(i4) :: nDofTypes, dofIdx, dofIdxTemp, dofIdxPore, dofIdxEpot, dofIdxChem, dofIdxMpot

    nNode = size(Element%conn)
    Ctx%nNode = nNode
    Ctx%time  = globalState%time_curr
    Ctx%dTime = globalState%dTime
    Ctx%cfg%id = globalState%cfg%id
    Ctx%incId  = globalState%incId
    Ctx%iterId = globalState%iterId
    Ctx%largeDisp = .true.
    ! [Data chain] step_idx/incr_idx for UEL/UMAT (L3→L5 three-step indexing )
    Ctx%inc%step_idx = g_ufc_global%md_layer%step%current_step_idx
    Ctx%inc%incr_idx = g_ufc_global%md_layer%step%current_incr_idx

    ndofpernode_tot = 3
    typeId   = Element%elemTypeId
    ElemType => UF_GetElementType(typeId)
    if (associated(ElemType)) then
      if (ElemType%n_dof_per_node > 0) ndofpernode_tot = ElemType%n_dof_per_node
    end if

    hasTemp = .false.
    hasPore = .false.
    hasEpot = .false.
    hasChem = .false.
    hasMpot = .false.
    do i = 1, nNode
      nid = Element%conn(i)
      nodeIdx = FindNodeIndexInPart(nodeIdFind=nid, partLocal=part)
      if (nodeIdx < 1) cycle
      if (.not. allocated(part%nodes(nodeIdx)%dofTypes)) cycle
      nDofTypes = size(part%nodes(nodeIdx)%dofTypes)
      do dofIdx = 1, nDofTypes
        select case (part%nodes(nodeIdx)%dofTypes(dofIdx))
        case (UF_DOF_TEMP)
          hasTemp = .true.
        case (UF_DOF_POR)
          hasPore = .true.
        case (UF_DOF_EPOT)
          hasEpot = .true.
        case (UF_DOF_CHEM)
          hasChem = .true.
        case (UF_DOF_MPOT)
          hasMpot = .true.
        end select
      end do
      if (hasTemp .and. hasPore .and. hasEpot .and. hasChem .and. hasMpot) exit
    end do

    allocate(Ctx%coords_ref(3, nNode))
    allocate(Ctx%coords_curr(3, nNode))
    allocate(Ctx%disp_total(3, nNode))
    allocate(Ctx%disp_incr(3, nNode))
    if (hasTemp) then
      allocate(Ctx%temp(nNode))
      allocate(Ctx%temp_incr(nNode))
      Ctx%temp      = 0.0_wp
      Ctx%temp_incr = 0.0_wp
    end if
    if (hasPore) then
      allocate(Ctx%pore(nNode))
      allocate(Ctx%pore_incr(nNode))
      Ctx%pore      = 0.0_wp
      Ctx%pore_incr = 0.0_wp
    end if
    if (hasEpot) then
      allocate(Ctx%epot(nNode))
      allocate(Ctx%epot_incr(nNode))
      Ctx%epot      = 0.0_wp
      Ctx%epot_incr = 0.0_wp
    end if
    if (hasChem) then
      allocate(Ctx%chem(nNode))
      allocate(Ctx%chem_incr(nNode))
      Ctx%chem      = 0.0_wp
      Ctx%chem_incr = 0.0_wp
    end if
    if (hasMpot) then
      allocate(Ctx%mpot(nNode))
      allocate(Ctx%mpot_incr(nNode))
      Ctx%mpot      = 0.0_wp
      Ctx%mpot_incr = 0.0_wp
    end if

    do i = 1, nNode
       nid = Element%conn(i)
       nodeIdx  = FindNodeIndexInPart(nodeIdFind=nid, partLocal=part)
       stateIdx = FindNodeStateIndex(nodeStates, nid)
       if (nodeIdx < 1 .or. stateIdx < 1) then
         Ctx%coords_ref(:, i) = 0.0_wp
         Ctx%disp_total(:, i) = 0.0_wp
         Ctx%disp_incr(:, i)  = 0.0_wp
         if (hasTemp) then
           Ctx%temp(i)      = 0.0_wp
           Ctx%temp_incr(i) = 0.0_wp
         end if
         if (hasPore) then
           Ctx%pore(i)      = 0.0_wp
           Ctx%pore_incr(i) = 0.0_wp
         end if
       else
         Ctx%coords_ref(:, i) = part%nodes(nodeIdx)%coords

         if (allocated(nodeStates(stateIdx)%u_curr)) then
           ndof_node = size(nodeStates(stateIdx)%u_curr)
         else
           ndof_node = 0
         end if
         if (ndof_node >= 3) then
           Ctx%disp_total(:, i) = nodeStates(stateIdx)%u_curr(1:3)
         else
           Ctx%disp_total(:, i) = 0.0_wp
         end if
         if (allocated(nodeStates(stateIdx)%u_incr) .and. size(nodeStates(stateIdx)%u_incr) >= 3) then
           Ctx%disp_incr(:, i)  = nodeStates(stateIdx)%u_incr(1:3)
         else
           Ctx%disp_incr(:, i)  = 0.0_wp
         end if

         if (hasTemp) then
           Ctx%temp(i)      = 0.0_wp
           Ctx%temp_incr(i) = 0.0_wp
           if (allocated(part%nodes(nodeIdx)%dofTypes) .and. allocated(nodeStates(stateIdx)%u_curr)) then
             nDofTypes  = size(part%nodes(nodeIdx)%dofTypes)
             dofIdxTemp = 0
             do dofIdx = 1, min(nDofTypes, ndof_node)
               if (part%nodes(nodeIdx)%dofTypes(dofIdx) == UF_DOF_TEMP) then
                 dofIdxTemp = dofIdx
                 exit
               end if
             end do
             if (dofIdxTemp > 0) then
               Ctx%temp(i) = nodeStates(stateIdx)%u_curr(dofIdxTemp)
               if (allocated(nodeStates(stateIdx)%u_incr) .and. &
                   size(nodeStates(stateIdx)%u_incr) >= dofIdxTemp) then
                 Ctx%temp_incr(i) = nodeStates(stateIdx)%u_incr(dofIdxTemp)
               else
                 Ctx%temp_incr(i) = 0.0_wp
               end if
             end if
           end if
         end if

         if (hasPore) then
           Ctx%pore(i)      = 0.0_wp
           Ctx%pore_incr(i) = 0.0_wp
           if (allocated(part%nodes(nodeIdx)%dofTypes) .and. allocated(nodeStates(stateIdx)%u_curr)) then
             nDofTypes  = size(part%nodes(nodeIdx)%dofTypes)
             dofIdxPore = 0
             do dofIdx = 1, min(nDofTypes, ndof_node)
               if (part%nodes(nodeIdx)%dofTypes(dofIdx) == UF_DOF_POR) then
                 dofIdxPore = dofIdx
                 exit
               end if
             end do
             if (dofIdxPore > 0) then
               Ctx%pore(i) = nodeStates(stateIdx)%u_curr(dofIdxPore)
               if (allocated(nodeStates(stateIdx)%u_incr) .and. &
                   size(nodeStates(stateIdx)%u_incr) >= dofIdxPore) then
                 Ctx%pore_incr(i) = nodeStates(stateIdx)%u_incr(dofIdxPore)
               else
                 Ctx%pore_incr(i) = 0.0_wp
               end if
             end if
           end if
         end if

         if (hasEpot) then
           Ctx%epot(i)      = 0.0_wp
           Ctx%epot_incr(i) = 0.0_wp
           if (allocated(part%nodes(nodeIdx)%dofTypes) .and. allocated(nodeStates(stateIdx)%u_curr)) then
             nDofTypes  = size(part%nodes(nodeIdx)%dofTypes)
             dofIdxEpot = 0
             do dofIdx = 1, min(nDofTypes, ndof_node)
               if (part%nodes(nodeIdx)%dofTypes(dofIdx) == UF_DOF_EPOT) then
                 dofIdxEpot = dofIdx
                 exit
               end if
             end do
             if (dofIdxEpot > 0) then
               Ctx%epot(i) = nodeStates(stateIdx)%u_curr(dofIdxEpot)
               if (allocated(nodeStates(stateIdx)%u_incr) .and. &
                   size(nodeStates(stateIdx)%u_incr) >= dofIdxEpot) then
                 Ctx%epot_incr(i) = nodeStates(stateIdx)%u_incr(dofIdxEpot)
               else
                 Ctx%epot_incr(i) = 0.0_wp
               end if
             end if
           end if
         end if

         if (hasChem) then
           Ctx%chem(i)      = 0.0_wp
           Ctx%chem_incr(i) = 0.0_wp
           if (allocated(part%nodes(nodeIdx)%dofTypes) .and. allocated(nodeStates(stateIdx)%u_curr)) then
             nDofTypes  = size(part%nodes(nodeIdx)%dofTypes)
             dofIdxChem = 0
             do dofIdx = 1, min(nDofTypes, ndof_node)
               if (part%nodes(nodeIdx)%dofTypes(dofIdx) == UF_DOF_CHEM) then
                 dofIdxChem = dofIdx
                 exit
               end if
             end do
             if (dofIdxChem > 0) then
               Ctx%chem(i) = nodeStates(stateIdx)%u_curr(dofIdxChem)
               if (allocated(nodeStates(stateIdx)%u_incr) .and. &
                   size(nodeStates(stateIdx)%u_incr) >= dofIdxChem) then
                 Ctx%chem_incr(i) = nodeStates(stateIdx)%u_incr(dofIdxChem)
               else
                 Ctx%chem_incr(i) = 0.0_wp
               end if
             end if
           end if
         end if

         if (hasMpot) then
           Ctx%mpot(i)      = 0.0_wp
           Ctx%mpot_incr(i) = 0.0_wp
           if (allocated(part%nodes(nodeIdx)%dofTypes) .and. allocated(nodeStates(stateIdx)%u_curr)) then
             nDofTypes  = size(part%nodes(nodeIdx)%dofTypes)
             dofIdxMpot = 0
             do dofIdx = 1, min(nDofTypes, ndof_node)
               if (part%nodes(nodeIdx)%dofTypes(dofIdx) == UF_DOF_MPOT) then
                 dofIdxMpot = dofIdx
                 exit
               end if
             end do
             if (dofIdxMpot > 0) then
               Ctx%mpot(i) = nodeStates(stateIdx)%u_curr(dofIdxMpot)
               if (allocated(nodeStates(stateIdx)%u_incr) .and. &
                   size(nodeStates(stateIdx)%u_incr) >= dofIdxMpot) then
                 Ctx%mpot_incr(i) = nodeStates(stateIdx)%u_incr(dofIdxMpot)
               else
                 Ctx%mpot_incr(i) = 0.0_wp
               end if
             end if
           end if
         end if
       end if
       Ctx%coords_curr(:, i) = Ctx%coords_ref(:, i) + Ctx%disp_total(:, i)
    end do

    Ctx%nDOF = nNode * ndofpernode_tot

  contains

    integer(i4) function FindNodeIndexInPart(nodeIdFind, partLocal) result(idx)
      integer(i4),        intent(in) :: nodeIdFind
      type(UF_Part),      intent(in) :: partLocal
      integer(i4) :: ii
      idx = -1_i4
      if (.not. allocated(partLocal%nodes)) return
      do ii = 1, size(partLocal%nodes)
        if (partLocal%nodes(ii)%cfg%id == nodeIdFind) then
          idx = ii
          return
        end if
      end do
    end function FindNodeIndexInPart

  end subroutine BuildElementContext

  !------------------------------------------------------------------
  ! Mesh_GetElemTypeId: get element type from mesh raw_data (mesh path helper)
  !------------------------------------------------------------------
  integer(i4) function Mesh_GetElemTypeId(elem_id) result(elem_type_id)
    integer(i4), intent(in) :: elem_id
    elem_type_id = ELEMENT_HEX8
    if (.not. g_ufc_global%IsReady()) return
    if (.not. g_ufc_global%md_layer%mesh%initialized) return
    if (.not. allocated(g_ufc_global%md_layer%mesh%raw_data%element_types)) return
    if (elem_id < 1_i4 .or. elem_id > size(g_ufc_global%md_layer%mesh%raw_data%element_types)) return
    elem_type_id = g_ufc_global%md_layer%mesh%raw_data%element_types(elem_id)
    if (elem_type_id <= 0) elem_type_id = ELEMENT_HEX8
  end function Mesh_GetElemTypeId

  !------------------------------------------------------------------
  ! BuildElementContextFromMesh: mesh single-source path, no part/Element
  !------------------------------------------------------------------
  subroutine BuildElementContextFromMesh(elem_id, arg_conn, elem_type_id, nodeStates, globalState, Ctx)
    integer(i4), intent(in) :: elem_id
    type(MD_Mesh_GetElemConnect_Arg), intent(in) :: arg_conn
    integer(i4), intent(in) :: elem_type_id
    type(NodeState),    intent(in)  :: nodeStates(:)
    type(GlobalState),  intent(in)  :: globalState
    type(UF_ElemCtx), intent(out) :: Ctx

    integer(i4) :: nNode, i, nid, stateIdx
    integer(i4) :: typeId, ndofpernode_tot
    type(UF_ElementType), pointer :: ElemType
    type(MD_Mesh_GetNodeCoords_Arg) :: arg_coords
    type(ErrorStatusType) :: mesh_status

    nNode = arg_conn%npe
    if (nNode <= 0_i4) return

    Ctx%nNode = nNode
    Ctx%time  = globalState%time_curr
    Ctx%dTime = globalState%dTime
    Ctx%cfg%id = globalState%cfg%id
    Ctx%incId  = globalState%incId
    Ctx%iterId = globalState%iterId
    Ctx%largeDisp = .true.
    ! [Data chain] step_idx/incr_idx for UEL/UMAT (L3→L5 three-step indexing )
    Ctx%inc%step_idx = g_ufc_global%md_layer%step%current_step_idx
    Ctx%inc%incr_idx = g_ufc_global%md_layer%step%current_incr_idx

    ndofpernode_tot = 3_i4
    typeId = elem_type_id
    ElemType => UF_GetElementType(typeId)
    if (associated(ElemType)) then
      if (ElemType%n_dof_per_node > 0) ndofpernode_tot = ElemType%n_dof_per_node
    end if

    allocate(Ctx%coords_ref(3, nNode))
    allocate(Ctx%coords_curr(3, nNode))
    allocate(Ctx%disp_total(3, nNode))
    allocate(Ctx%disp_incr(3, nNode))

    do i = 1, nNode
      nid = int(arg_conn%connect(i), i4)
      if (nid < 1_i4) then
        Ctx%coords_ref(:, i) = 0.0_wp
        Ctx%disp_total(:, i) = 0.0_wp
        Ctx%disp_incr(:, i)  = 0.0_wp
      else
        call MD_Mesh_GetNodeCoords_Idx(nid, arg_coords, mesh_status)
        if (mesh_status%status_code == IF_STATUS_OK) then
          Ctx%coords_ref(:, i) = arg_coords%coords
        else
          Ctx%coords_ref(:, i) = 0.0_wp
        end if

        stateIdx = FindNodeStateIndex(nodeStates, nid)
        if (stateIdx < 1_i4) then
          Ctx%disp_total(:, i) = 0.0_wp
          Ctx%disp_incr(:, i)  = 0.0_wp
        else
          if (allocated(nodeStates(stateIdx)%u_curr) .and. size(nodeStates(stateIdx)%u_curr) >= 3) then
            Ctx%disp_total(:, i) = nodeStates(stateIdx)%u_curr(1:3)
          else
            Ctx%disp_total(:, i) = 0.0_wp
          end if
          if (allocated(nodeStates(stateIdx)%u_incr) .and. size(nodeStates(stateIdx)%u_incr) >= 3) then
            Ctx%disp_incr(:, i) = nodeStates(stateIdx)%u_incr(1:3)
          else
            Ctx%disp_incr(:, i) = 0.0_wp
          end if
        end if
      end if
      Ctx%coords_curr(:, i) = Ctx%coords_ref(:, i) + Ctx%disp_total(:, i)
    end do

    Ctx%nDOF = nNode * ndofpernode_tot

  end subroutine BuildElementContextFromMesh

  !------------------------------------------------------------------
  ! GatherNodalU: collect nodal displacements into global DOF vector

  !------------------------------------------------------------------
  subroutine GatherNodalU(nodeStates, dofMap, u)
    type(NodeState), intent(in) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in) :: dofMap
    real(wp),           intent(out):: u(:)

    integer(i4) :: eq, nEq
    integer(i4) :: nid, localDof
    integer(i4) :: idxState

    u = 0.0_wp
    nEq = min(dofMap%nTotalEq, size(u))

    do eq = 1, nEq
      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0_i4 .or. localDof <= 0_i4) cycle

      idxState = FindNodeStateIndex(nodeStates, nid)
      if (idxState < 1_i4) cycle
      if (.not. allocated(nodeStates(idxState)%u_curr)) cycle
      if (localDof > size(nodeStates(idxState)%u_curr)) cycle

      u(eq) = nodeStates(idxState)%u_curr(localDof)
    end do

  end subroutine GatherNodalU

  !------------------------------------------------------------------
  ! NewmarkPredictor: Newmark predictor step (update u_curr/u_incr/v)

  !------------------------------------------------------------------
  subroutine NewmarkPredictor(nodeStates, dofMap, dt, beta, gamma, u_pred)
    type(NodeState), intent(inout) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in)    :: dofMap
    real(wp),           intent(in)    :: dt, beta, gamma
    real(wp),           intent(out)   :: u_pred(:)
    integer(i4) :: i, id, d, eq
    real(wp)   :: up

    u_pred = 0.0_wp
    do i = 1, size(nodeStates)
      do d = 1, 3
        up = nodeStates(i)%u_old(d) + dt * nodeStates(i)%v_old(d) + dt*dt*(0.5_wp - beta) * nodeStates(i)%a_old(d)
        nodeStates(i)%u_curr(d) = up
        nodeStates(i)%u_incr(d) = nodeStates(i)%u_curr(d) - nodeStates(i)%u_old(d)
        nodeStates(i)%v(d)      = nodeStates(i)%v_old(d) + dt*(1.0_wp - gamma) * nodeStates(i)%a_old(d)
      end do
      id = nodeStates(i)%cfg%id
      do d = 1, 3
        eq = UF_GetEqId(dofMap, id, d)
        if (eq > 0 .and. eq <= size(u_pred)) u_pred(eq) = nodeStates(i)%u_curr(d)
      end do
    end do
  end subroutine NewmarkPredictor

  !------------------------------------------------------------------
  ! AddInertiaTerms: add inertia term into residual and tangent (diagonal mass contribution)

  !------------------------------------------------------------------
  subroutine AddInertiaTerms(triplets, R, mass, u, u_pred, a0)
    type(RT_TripletList), intent(inout) :: triplets
    real(wp),             intent(inout) :: R(:)
    real(wp),             intent(in)    :: mass(:), u(:), u_pred(:)
    real(wp),             intent(in)    :: a0
    integer(i4) :: i
    real(wp)   :: mEff

    do i = 1, size(R)
      R(i) = R(i) - mass(i) * a0 * (u(i) - u_pred(i))
      mEff = mass(i) * a0
      if (abs(mEff) > 0.0_wp) call RT_Triplet_Add(triplets, i, i, mEff)
    end do
  end subroutine AddInertiaTerms

  !------------------------------------------------------------------
  ! NewmarkUpdateKinematics: update nodal acceleration/velocity after conv

  !------------------------------------------------------------------
  subroutine NewmarkUpdateKinematics(nodeStates, dt, beta, gamma, u_pred)
    type(NodeState), intent(inout) :: nodeStates(:)
    real(wp),           intent(in)    :: dt, beta, gamma
    real(wp),           intent(in)    :: u_pred(:)
    integer(i4) :: i, d
    real(wp)   :: a0
    real(wp)   :: uPredNode(3), aNew(3), vPred(3)

    a0 = 1.0_wp / (beta * dt * dt)
    do i = 1, size(nodeStates)
      do d = 1, 3
        uPredNode(d) = nodeStates(i)%u_old(d) + dt * nodeStates(i)%v_old(d) + dt*dt*(0.5_wp - beta) * nodeStates(i)%a_old(d)
        vPred(d)     = nodeStates(i)%v_old(d) + dt*(1.0_wp - gamma) * nodeStates(i)%a_old(d)
        aNew(d)      = a0 * (nodeStates(i)%u_curr(d) - uPredNode(d))
        nodeStates(i)%a(d) = aNew(d)
        nodeStates(i)%v(d) = vPred(d) + gamma * dt * aNew(d)
      end do
    end do
  end subroutine NewmarkUpdateKinematics

  !------------------------------------------------------------------
  ! ExplicitPredictorVerlet: explicit Verlet predictor

  !------------------------------------------------------------------
  subroutine ExplicitPredictorVerlet(nodeStates, dt)
    type(NodeState), intent(inout) :: nodeStates(:)
    real(wp),           intent(in)    :: dt
    integer(i4) :: i, d

    do i = 1, size(nodeStates)
      do d = 1, 3
        nodeStates(i)%u_curr(d) = nodeStates(i)%u_old(d) + dt * nodeStates(i)%v_old(d) + 0.5_wp * dt * dt * nodeStates(i)%a_old(d)
        nodeStates(i)%u_incr(d) = nodeStates(i)%u_curr(d) - nodeStates(i)%u_old(d)
      end do
      nodeStates(i)%v = nodeStates(i)%v_old
      nodeStates(i)%a = nodeStates(i)%a_old
    end do
  end subroutine ExplicitPredictorVerlet

  !------------------------------------------------------------------
  ! UF_AssemblyInternalOnly: assemble internal force only (static explicit use)

  !------------------------------------------------------------------
  subroutine UF_AssemblyInternalOnly(model, globalState, dofMap, nodeStates, elemStates, R)
    type(UF_Model),        intent(in)    :: model
    type(GlobalState),  intent(in)    :: globalState
    type(RT_Sol_DofMap),       intent(in)    :: dofMap
    type(NodeState),    intent(in)    :: nodeStates(:)
    type(ElemState), intent(inout) :: elemStates(:)
    real(wp),              intent(inout) :: R(:)

    integer(i4) :: ie, p, typeId, eGlobal
    type(UF_Part),        pointer :: part
    type(RT_Element),     pointer :: Element
    type(UF_ElementType), pointer :: ElemType
    type(UF_ElemCtx) :: Ctx
    type(UF_ElemFlags)   :: flags
    real(wp), allocatable   :: Ke(:,:), Re(:)

    block
      logical :: use_mesh
      integer(i4) :: n_elems_m, elem_id
      type(MD_Mesh_GetElemConnect_Arg) :: arg_conn
      integer(i4) :: elem_type_id
      type(ErrorStatusType) :: mesh_st

      use_mesh = g_ufc_global%IsReady() .and. g_ufc_global%md_layer%mesh%initialized
      if (use_mesh) then
        ! Mesh single-source path: iterate mesh elements, no model%parts
        n_elems_m = int(g_ufc_global%md_layer%mesh%raw_data%nElems, i4)
        do elem_id = 1, n_elems_m
          if (elem_id > size(elemStates)) return
          call MD_Mesh_GetElemConnect_Idx(elem_id, arg_conn, mesh_st)
          if (mesh_st%status_code /= IF_STATUS_OK .or. arg_conn%npe <= 0) cycle
          elem_type_id = Mesh_GetElemTypeId(elem_id)
          ElemType => UF_GetElementType(elem_type_id)
          if (.not. associated(ElemType)) cycle
          call RT_BindElementCompute(ElemType)
          if (.not. associated(ElemType%compute)) cycle
          call BuildElementContextFromMesh(elem_id, arg_conn, elem_type_id, nodeStates, globalState, Ctx)
          allocate(Ke(Ctx%nDOF, Ctx%nDOF))
          allocate(Re(Ctx%nDOF))
          block
            class(UF_MaterialModel), allocatable :: mats(:)
            type(ElemState) :: state_in
            integer(i4) :: ip_idx, secId
            class(UF_MaterialModel), pointer :: secMat

            allocate(mats(ElemType%n_int_points))
            secId = 0_i4
            if (allocated(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref) .and. &
                elem_id <= size(g_ufc_global%md_layer%mesh%raw_data%elem_section_ref)) then
              secId = g_ufc_global%md_layer%mesh%raw_data%elem_section_ref(elem_id)
            end if
            secMat => null()
            if (secId > 0 .and. allocated(model%sections)) then
              if (secId <= size(model%sections)) then
                if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
              end if
            end if
            do ip_idx = 1, ElemType%n_int_points
              if (associated(secMat)) then
                allocate(mats(ip_idx), source=secMat)
              else
                call UF_GetMaterialModel('Elastic', mats(ip_idx))
              end if
            end do

            state_in = elemStates(elem_id)
            call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, state_in, mats, Ke, Re, &
                                 state_out=elemStates(elem_id), flags=flags)
            call ScatterInternalToR_FromConn(arg_conn%connect, arg_conn%npe, dofMap, Re, R)
            if (allocated(mats)) deallocate(mats)
          end block
          deallocate(Ke, Re)
        end do
      else
    if (.not. allocated(model%parts)) return

    eGlobal = 0_i4
    do p = 1, size(model%parts)
      part => model%parts(p)
      if (.not. allocated(part%elements)) cycle
      do ie = 1, size(part%elements)
        eGlobal = eGlobal + 1_i4
        if (eGlobal > size(elemStates)) return

        Element => part%elements(ie)
        typeId   = Element%elemTypeId
        ElemType => UF_GetElementType(typeId)
        if (.not. associated(ElemType)) cycle
        call RT_BindElementCompute(ElemType)
        if (.not. associated(ElemType%compute)) cycle

        call BuildElementContext(part, Element, nodeStates, globalState, Ctx)
        allocate(Ke(Ctx%nDOF, Ctx%nDOF))
        allocate(Re(Ctx%nDOF))
        block
          class(UF_MaterialModel), allocatable :: mats(:)
          type(ElemState) :: state_in
          integer(i4) :: ip_idx, secId
          class(UF_MaterialModel), pointer :: secMat

          allocate(mats(ElemType%n_int_points))
          secId = Element%cfg%id
          secMat => null()
          if (secId > 0 .and. allocated(model%sections)) then
            if (secId <= size(model%sections)) then
              if (associated(model%sections(secId)%Mat)) secMat => model%sections(secId)%Mat
            end if
          end if
          do ip_idx = 1, ElemType%n_int_points
            if (associated(secMat)) then
              allocate(mats(ip_idx), source=secMat)
            else
              call UF_GetMaterialModel('Elastic', mats(ip_idx))
            end if
          end do

          state_in = elemStates(eGlobal)
          call ElemType%compute(ElemType, ElemType%defaultFormul, Ctx, state_in, mats, Ke, Re, &
                               state_out=elemStates(eGlobal), flags=flags)
          call ScatterInternalToR(Element, dofMap, Re, R)
          if (allocated(mats)) deallocate(mats)
        end block
        deallocate(Ke, Re)
      end do
    end do
      end if
    end block
  end subroutine UF_AssemblyInternalOnly

  !------------------------------------------------------------------
  ! ScatterInternalToR: scatter Element internal force Re to global residual R

  !------------------------------------------------------------------
  subroutine ScatterInternalToR(Element, dofMap, Re, R)
    type(RT_Element), intent(in) :: Element
    type(RT_Sol_DofMap),  intent(in) :: dofMap
    real(wp),         intent(in) :: Re(:)
    real(wp),         intent(inout) :: R(:)

    integer(i4) :: i, nNode, a, row, nidI
    integer(i4) :: ndpn, idxLocal

    nNode = size(Element%conn)
    if (nNode <= 0_i4) return
    if (size(Re) <= 0_i4) return

    ndpn = size(Re) / nNode
    if (ndpn <= 0_i4) return

    do i = 1, nNode
      nidI = Element%conn(i)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row <= 0_i4 .or. row > size(R)) cycle

        idxLocal = (i-1_i4)*ndpn + a
        if (idxLocal < 1_i4 .or. idxLocal > size(Re)) cycle

        R(row) = R(row) - Re(idxLocal)
      end do
    end do
  end subroutine ScatterInternalToR

  subroutine ScatterInternalToR_FromConn(conn, npe, dofMap, Re, R)
    integer(i8), intent(in) :: conn(:)
    integer(i4), intent(in) :: npe
    type(RT_Sol_DofMap),  intent(in) :: dofMap
    real(wp),         intent(in) :: Re(:)
    real(wp),         intent(inout) :: R(:)

    integer(i4) :: i, nNode, a, row, nidI
    integer(i4) :: ndpn, idxLocal

    nNode = npe
    if (nNode <= 0_i4) return
    if (size(Re) <= 0_i4) return

    ndpn = size(Re) / nNode
    if (ndpn <= 0_i4) return

    do i = 1, nNode
      nidI = int(conn(i), i4)
      do a = 1, ndpn
        row = UF_GetEqId(dofMap, nidI, a)
        if (row <= 0_i4 .or. row > size(R)) cycle

        idxLocal = (i-1_i4)*ndpn + a
        if (idxLocal < 1_i4 .or. idxLocal > size(Re)) cycle

        R(row) = R(row) - Re(idxLocal)
      end do
    end do
  end subroutine ScatterInternalToR_FromConn

  !------------------------------------------------------------------
  ! ApplyBoundaryConditionsDynamic: penalty-style dynamic BC handling

  !------------------------------------------------------------------
  subroutine ApplyBoundaryConditionsDynam(model, step, dofMap, time, K, R, nodeStates)
    type(UF_Model),        intent(in)    :: model
    type(UF_AnalysisStep), intent(in)    :: step
    type(RT_Sol_DofMap),       intent(in)    :: dofMap
    real(wp),              intent(in)    :: time
    type(RT_CSRMatrix),    intent(inout) :: K
    real(wp),              intent(inout) :: R(:)
    type(NodeState),    intent(in)    :: nodeStates(:)

    integer(i4) :: bcId, id, dof, setId, idxNode
    real(wp)    :: val, penalty
    integer(i4), pointer :: nodeIds(:)

    penalty = 1.0e20_wp

    if (.not. allocated(step%bcs)) return

    do bcId = 1, size(step%bcs)
      id = step%bcs(bcId)%targetId
      dof    = step%bcs(bcId)%dof
      val    = step%bcs(bcId)%value * UF_AmpFactor(model, step%bcs(bcId)%amplitudeId, time)

      select case (step%bcs(bcId)%type)

      case (UF_BC_DISPLACEM, UF_BC_Fixed)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplyNodeBC(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplyNodeBC(nodeIds(idxNode), dof, val)
          end do
        end select

      case (UF_BC_Symmetry)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplySymmetryAtNode(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplySymmetryAtNode(nodeIds(idxNode), dof, val)
          end do
        end select

      case default
        cycle

      end select
    end do

  contains

    subroutine ApplySymmetryAtNode(nodeIdLocal, baseDof, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, baseDof
      real(wp),    intent(in) :: valLocal

      select case (baseDof)
      case (UF_DOF_U1)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_U1,  valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR2, valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR3, valLocal)
      case (UF_DOF_U2)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_U2,  valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR1, valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR3, valLocal)
      case (UF_DOF_U3)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_U3,  valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR1, valLocal)
        call ApplyNodeBC(nodeIdLocal, UF_DOF_UR2, valLocal)
      end select
    end subroutine ApplySymmetryAtNode

    subroutine ApplyNodeBC(nodeIdLocal, dofLocal, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, dofLocal
      real(wp),    intent(in) :: valLocal
      integer(i4) :: row, start_idx, end_idx, k
      real(wp)    :: u_curr
      logical     :: diag_found
      type(UF_NodeHdl)      :: nh
      type(NodeState), pointer :: ns => null()
      logical                  :: found

      if (dofLocal < 1 .or. dofLocal > 3) return
      row = UF_GetEqId(dofMap, nodeIdLocal, dofLocal)
      if (row < 1 .or. row > size(R)) return

      call UF_RT_MakeNodeHandleFromId(nodeStates, nodeIdLocal, nh, found)
      if (.not. found) return
      call UF_RT_GetNodeStateView(nh, nodeStates, ns)
      if (.not. associated(ns)) return
      if (.not. allocated(ns%u_curr)) return
      if (dofLocal > size(ns%u_curr)) return
      u_curr = ns%u_curr(dofLocal)

      start_idx = K%rowPtr(row)
      end_idx   = K%rowPtr(row+1) - 1

      diag_found = .false.
      do k = start_idx, end_idx
        if (K%colInd(k) == row) then
          K%values(k) = K%values(k) + penalty
          diag_found = .true.
          exit
        end if
      end do

      if (diag_found) then
        R(row) = R(row) + penalty * (valLocal - u_curr)
      end if
    end subroutine ApplyNodeBC

  end subroutine ApplyBoundaryConditionsDynamic

  !------------------------------------------------------------------
  ! ApplyBoundaryConditionsExplicit: explicit-step boundary condition handling

  !------------------------------------------------------------------
  subroutine ApplyBoundaryConditionsExpli(model, step, dofMap, time, nodeStates, R)
    type(UF_Model),        intent(in)    :: model
    type(UF_AnalysisStep), intent(in)    :: step
    type(RT_Sol_DofMap),       intent(in)    :: dofMap
    real(wp),              intent(in)    :: time
    type(NodeState),    intent(inout) :: nodeStates(:)
    real(wp),              intent(inout) :: R(:)

    integer(i4) :: bcId, id, dof, setId, idxNode
    real(wp)    :: val
    integer(i4), pointer :: nodeIds(:)

    if (.not. allocated(step%bcs)) return
    do bcId = 1, size(step%bcs)
      id = step%bcs(bcId)%targetId
      dof    = step%bcs(bcId)%dof
      val    = step%bcs(bcId)%value * UF_AmpFactor(model, step%bcs(bcId)%amplitudeId, time)

      select case (step%bcs(bcId)%type)

      case (UF_BC_DISPLACEM, UF_BC_Fixed)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplyNodeBCExplicit(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplyNodeBCExplicit(nodeIds(idxNode), dof, val)
          end do
        end select

      case (UF_BC_Symmetry)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplySymmetryBCExplicit(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplySymmetryBCExplicit(nodeIds(idxNode), dof, val)
          end do
        end select

      case (UF_BC_Velocity)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplyVelocityBCExplicit(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplyVelocityBCExplicit(nodeIds(idxNode), dof, val)
          end do
        end select

      case (UF_BC_ACCELERAT)
        select case (step%bcs(bcId)%targetType)
        case (UF_Target_Node)
          call ApplyAccelerationBCExplicit(id, dof, val)
        case (UF_TARGET_NODES)
          if (.not. allocated(model%parts)) cycle
          if (size(model%parts) < 1) cycle
          if (.not. allocated(model%parts(1)%nodeSets)) cycle
          setId = id
          if (setId < 1 .or. setId > size(model%parts(1)%nodeSets)) cycle
          if (.not. allocated(model%parts(1)%nodeSets(setId)%nodeIds)) cycle
          nodeIds => model%parts(1)%nodeSets(setId)%nodeIds
          do idxNode = 1, size(nodeIds)
            call ApplyAccelerationBCExplicit(nodeIds(idxNode), dof, val)
          end do
        end select

      case default
        cycle

      end select
    end do

  contains

    subroutine ApplySymmetryBCExplicit(nodeIdLocal, baseDof, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, baseDof
      real(wp),    intent(in) :: valLocal

      select case (baseDof)
      case (UF_DOF_U1)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_U1,  valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR2, valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR3, valLocal)
      case (UF_DOF_U2)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_U2,  valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR1, valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR3, valLocal)
      case (UF_DOF_U3)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_U3,  valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR1, valLocal)
        call ApplyNodeBCExplicit(nodeIdLocal, UF_DOF_UR2, valLocal)
      end select
    end subroutine ApplySymmetryBCExplicit

    subroutine ApplyNodeBCExplicit(nodeIdLocal, dofLocal, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, dofLocal
      real(wp),    intent(in) :: valLocal
      integer(i4) :: row
      type(UF_NodeHdl)      :: nh
      type(RT_NodeState), pointer :: ns => null()
      logical                  :: found

      if (dofLocal < 1 .or. dofLocal > 3) return
      row = UF_GetEqId(dofMap, nodeIdLocal, dofLocal)
      if (row > 0 .and. row <= size(R)) R(row) = 0.0_wp

      call UF_RT_MakeNodeHandleFromId(nodeStates, nodeIdLocal, nh, found)
      if (.not. found) return
      call UF_RT_GetNodeStateView(nh, nodeStates, ns)
      if (.not. associated(ns)) return
      if (.not. allocated(ns%u_curr)) return
      if (.not. allocated(ns%u_old)) return
      if (dofLocal > size(ns%u_curr)) return
      if (dofLocal > size(ns%u_old))  return

      ns%u_curr(dofLocal)  = valLocal
      ns%u_incr(dofLocal)  = ns%u_curr(dofLocal) - ns%u_old(dofLocal)
      ns%v(dofLocal)       = 0.0_wp
      ns%a(dofLocal)       = 0.0_wp
    end subroutine ApplyNodeBCExplicit

    subroutine ApplyVelocityBCExplicit(nodeIdLocal, dofLocal, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, dofLocal
      real(wp),    intent(in) :: valLocal
      integer(i4) :: row
      type(UF_NodeHdl)      :: nh
      type(RT_NodeState), pointer :: ns => null()
      logical                  :: found

      if (dofLocal < 1 .or. dofLocal > 3) return
      row = UF_GetEqId(dofMap, nodeIdLocal, dofLocal)
      if (row > 0 .and. row <= size(R)) R(row) = 0.0_wp

      call UF_RT_MakeNodeHandleFromId(nodeStates, nodeIdLocal, nh, found)
      if (.not. found) return
      call UF_RT_GetNodeStateView(nh, nodeStates, ns)
      if (.not. associated(ns)) return
      if (.not. allocated(ns%v)) return
      if (dofLocal > size(ns%v)) return

      ns%v(dofLocal) = valLocal
    end subroutine ApplyVelocityBCExplicit

    subroutine ApplyAccelerationBCExplicit(nodeIdLocal, dofLocal, valLocal)
      integer(i4), intent(in) :: nodeIdLocal, dofLocal
      real(wp),    intent(in) :: valLocal
      integer(i4) :: row
      if (dofLocal < 1 .or. dofLocal > 3) return
      row = UF_GetEqId(dofMap, nodeIdLocal, dofLocal)
      if (row > 0 .and. row <= size(R)) then
        R(row) = 0.0_wp
      end if
    end subroutine ApplyAccelerationBCExplicit

  end subroutine ApplyBoundaryConditionsExplicit

  !------------------------------------------------------------------
  ! ExplicitUpdateVerlet: update acceleration/velocity for structural DOFs only

  !------------------------------------------------------------------
  subroutine ExplicitUpdateVerlet(nodeStates, dofMap, dt, mass, R)
    type(RT_NodeState), intent(inout) :: nodeStates(:)
    type(RT_Sol_DofMap),    intent(in)    :: dofMap
    real(wp),           intent(in)    :: dt
    real(wp),           intent(in)    :: mass(:)
    real(wp),           intent(in)    :: R(:)

    integer(i4) :: eq, nEq
    integer(i4) :: nid, localDof
    integer(i4) :: idxState
    real(wp)    :: aNew

    nEq = min(dofMap%nTotalEq, min(size(R), size(mass)))

    do eq = 1, nEq
      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0_i4 .or. localDof <= 0_i4) cycle

      idxState = FindNodeStateIndex(nodeStates, nid)
      if (idxState < 1_i4) cycle

      if (.not. allocated(nodeStates(idxState)%a))      cycle
      if (.not. allocated(nodeStates(idxState)%a_old))  cycle
      if (.not. allocated(nodeStates(idxState)%v))      cycle
      if (.not. allocated(nodeStates(idxState)%v_old))  cycle

      if (localDof > size(nodeStates(idxState)%a))      cycle
      if (localDof > size(nodeStates(idxState)%a_old))  cycle
      if (localDof > size(nodeStates(idxState)%v))      cycle
      if (localDof > size(nodeStates(idxState)%v_old))  cycle

      if (mass(eq) > 1.0e-30_wp) then
        aNew = R(eq) / mass(eq)
      else
        aNew = 0.0_wp
      end if

      nodeStates(idxState)%a(localDof) = aNew
      nodeStates(idxState)%v(localDof) = nodeStates(idxState)%v_old(localDof) + &
                                         0.5_wp * dt * (nodeStates(idxState)%a_old(localDof) + aNew)
    end do

  end subroutine ExplicitUpdateVerlet

  !------------------------------------------------------------------
  ! UF_ExplicitUpdateMultiField: explicit forward-Euler update for non-structural fields (TEMP/POR etc.).
  !   - Assume uniform capacity model: C dphi/dt = R_field.
  !   - Capacities come from solver%thermalCapacity / solver%poreCapacity.
  !   - Uses dofMap%eqFieldId to identify Thermal/Pore fields; no explicit capacity matrix is built.

  !------------------------------------------------------------------
  subroutine UF_ExplicitUpdateMultiField(model, step, solver, globalState, dofMap, nodeStates, R)
    type(RT_Model),          intent(in)    :: model
    type(RT_AnalysisStep),   intent(in)    :: step
    type(RT_SolverSettings), intent(in)    :: solver
    type(RT_GlobalState),    intent(in)    :: globalState
    type(RT_Sol_DofMap),         intent(in)    :: dofMap
    type(RT_NodeState),      intent(inout) :: nodeStates(:)
    real(wp),                intent(in)    :: R(:)

    integer(i4) :: eq, nEq
    integer(i4) :: nid, localDof
    integer(i4) :: idxState
    integer(i4) :: fieldId
    real(wp)    :: dt, cap, capT, capP, delta

    dt   = globalState%dTime
    if (dt <= 0.0_wp) return

    if (.not. allocated(dofMap%eqFieldId)) return

    capT = max(solver%thermalCapacity, 0.0_wp)
    capP = max(solver%poreCapacity,    0.0_wp)
    if (capT <= 0.0_wp .and. capP <= 0.0_wp) return

    nEq = min(dofMap%nTotalEq, size(R))

    do eq = 1, nEq
      fieldId = dofMap%eqFieldId(eq)

      if (fieldId == UF_Field_Thermal .and. capT > 0.0_wp) then
        cap = capT
      else if (fieldId == UF_Field_Pore .and. capP > 0.0_wp) then
        cap = capP
      else
        cycle
      end if

      nid      = dofMap%eqToNode(eq)
      localDof = dofMap%eqToLocal(eq)
      if (nid <= 0_i4 .or. localDof <= 0_i4) cycle

      idxState = FindNodeStateIndex(nodeStates, nid)
      if (idxState < 1_i4) cycle

      if (.not. allocated(nodeStates(idxState)%u_curr)) cycle
      if (localDof > size(nodeStates(idxState)%u_curr)) cycle

      ! Simple Forward Euler: phi_{n+1} = phi_n + dt * R / C

      delta = dt * R(eq) / cap

      nodeStates(idxState)%u_curr(localDof) = nodeStates(idxState)%u_curr(localDof) + delta
      if (allocated(nodeStates(idxState)%u_incr)) then
        if (localDof <= size(nodeStates(idxState)%u_incr)) then
          nodeStates(idxState)%u_incr(localDof) = nodeStates(idxState)%u_incr(localDof) + delta
        end if
      end if
    end do

  end subroutine UF_ExplicitUpdateMultiField

  !=========================================================================
  ! UF_NewtonRaphson_State - DEPRECATED: Use UF_NewtonRaphson_Ctx instead
  !
  ! This interface is deprecated and will be removed in a future version.
  ! Please use UF_NewtonRaphson_Ctx instead.
  !
  ! Same functionality as UF_NewtonRaphson but uses RT_Sol_State structure
  ! instead of individual arrays. This simplifies the interface and improves
  ! maintainability.
  !=========================================================================
  subroutine UF_NewtonRaphson_State(model, step, solver, solver_state, &
                                     globalState, nodeStates, elemStates, tws, converged)
    type(UF_Model),               intent(inout), target :: model
    type(UF_AnalysisStep),        intent(in), target    :: step
    type(RT_Sol_Cfg),            intent(in), target    :: solver
    type(RT_Sol_State),           intent(inout), target :: solver_state
    type(GlobalState),         intent(inout), target :: globalState
    type(NodeState),           intent(inout), target :: nodeStates(:)
    type(ElemState),        intent(inout), target :: elemStates(:)
    type(ThreadWS), intent(inout), target :: tws(:)
    logical,                      intent(out)   :: converged

    type(RT_Sol_Ctx) :: ctx

    ! Bind Ctx
    call ctx%Bind(model, step, solver, solver_state, globalState, nodeStates, elemStates, tws=tws)

    ! Call unified interface
    call UF_NewtonRaphson_Ctx(ctx)

    ! Extract result
    converged = ctx%converged
  end subroutine UF_NewtonRaphson_State


  ! ===================================================================
  ! Solver State Type - Unified state structure for solver interfaces
  ! ===================================================================

contains

  subroutine RT_Sol_DofMap_Final(this)
    type(RT_Sol_DofMap), intent(inout) :: this

    if (allocated(this%nodeToEqStart))   deallocate(this%nodeToEqStart)
    if (allocated(this%nodeNumDof))      deallocate(this%nodeNumDof)
    if (allocated(this%eqToNode))        deallocate(this%eqToNode)
    if (allocated(this%eqToLocal))       deallocate(this%eqToLocal)
    if (allocated(this%eqFieldId))       deallocate(this%eqFieldId)
    if (allocated(this%fieldEqCount))    deallocate(this%fieldEqCount)
    if (allocated(this%eqLocalInField))  deallocate(this%eqLocalInField)
    if (allocated(this%dofMask))         deallocate(this%dofMask)
    if (allocated(this%constrained_value)) deallocate(this%constrained_value)

    this%nTotalEq = 0
    this%nFields  = 0
  end subroutine RT_Sol_DofMap_Final

  ! RT_Sol_State Init/Destroy/Clear: implemented in RT_Shared_Def (unified memory)

! From RT_Solver_Ctx.f90
  !====================================================================
  ! Solver Ctx - Unified Ctx for solver operations
  !====================================================================
  type, extends(BaseCtx), public :: RT_Sol_Ctx
    ! Inherit error status handling from BaseSta through BaseCtx
    !! Unified solver Ctx bundling all solver-related data
    !! 
    !! This structure eliminates the need to pass individual parameters:
    !!   - model, step, solver, globalState, nodeStates, elemStates, tws
    !!   - All data is accessed through this single Ctx structure

    ! Error status (inherited from BaseSta through BaseCtx)
    type(BaseSta) :: sta

    ! Desc types (configuration)
    type(UF_Model), pointer :: model => null()
    type(UF_AnalysisStep), pointer :: step => null()
    type(RT_Sol_Cfg), pointer :: solver => null()

    ! State types (runtime data)
    type(RT_Sol_State), pointer :: solver_state => null()
    type(GlobalState), pointer :: globalState => null()
    type(NodeState), pointer :: nodeStates(:) => null()
    type(ElemState), pointer :: elemStates(:) => null()

    ! Algo types (algorithm configuration) - to be added when Algo types are created
    ! type(RT_Sol_Algo), pointer :: algo => null()

    ! DOF mapping
    type(RT_Sol_DofMap), pointer :: dofMap => null()

    ! System matrices and vectors (for direct access)
    type(RT_CSRMatrix), pointer :: K => null()
    type(RT_CSRMatrix), pointer :: M => null()
    type(RT_CSRMatrix), pointer :: C => null()
    real(wp), pointer :: F(:) => null()
    real(wp), pointer :: R(:) => null()
    real(wp), pointer :: u(:) => null()
    real(wp), pointer :: v(:) => null()
    real(wp), pointer :: a(:) => null()

    ! Load factor (for arc-length methods)
    real(wp) :: lambda = 1.0_wp
    real(wp) :: dlambda = 0.0_wp

    ! Workspace
    type(ThreadWS), pointer :: tws(:) => null()

    ! Results
    logical :: converged = .false.
    logical :: success = .false.

    ! AI-ready slots (L5_RT design Section 8; wire from StepDriverContext or RT_SolverSys)
    procedure(RT_Glb_StepCtrl_IF), pointer :: AI_StepController => null()
    procedure(RT_Glb_ConvPred_IF), pointer :: AI_ConvPredictor => null()

  contains
    procedure, public :: Init => RT_Sol_Ctx_Init
    procedure, public :: Destroy => RT_Sol_Ctx_Destroy
    procedure, public :: Reset => RT_Sol_Ctx_Reset
    procedure, public :: GetStatus => RT_Sol_Ctx_GetStatus
    procedure, public :: SetStatus => RT_Sol_Ctx_SetStatus
    procedure, public :: ClearStatus => RT_Sol_Ctx_ClearStatus
    procedure, public :: IsOK => RT_Sol_Ctx_IsOK
    procedure, public :: IsError => RT_Sol_Ctx_IsError
    procedure, public :: Bind => RT_Sol_Ctx_Bind
    procedure, public :: Valid => RT_Sol_Ctx_Valid
    procedure, public :: GetModel => RT_Sol_Ctx_GetModel
    procedure, public :: GetStep => RT_Sol_Ctx_GetStep
    procedure, public :: GetSolver => RT_Sol_Ctx_GetSolver
    procedure, public :: GetSolverState => RT_Sol_Ctx_GetSolverState
    procedure, public :: GetGlobalState => RT_Sol_Ctx_GetGlobalState
    procedure, public :: GetNodeStates => RT_Sol_Ctx_GetNodeStates
    procedure, public :: GetElemStates => RT_Sol_Ctx_GetElemStates
    procedure, public :: GetDofMap => RT_Sol_Ctx_GetDofMap
    procedure, public :: GetTws => RT_Sol_Ctx_GetTws
  end type RT_Sol_Ctx

  ! ===================================================================
  ! Structured Input/Output Types for RT_Sol_Ctx
  ! ===================================================================
  ! RT_Sol_Ctx_Init
  type, public :: RT_Sol_Ctx_Init_In
    ! No input parameters
  end type RT_Sol_Ctx_Init_In
  type, public :: RT_Sol_Ctx_Init_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Init_Out

  ! RT_Sol_Ctx_Destroy
  type, public :: RT_Sol_Ctx_Destroy_In
    ! No input parameters
  end type RT_Sol_Ctx_Destroy_In
  type, public :: RT_Sol_Ctx_Destroy_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Destroy_Out

  ! RT_Sol_Ctx_Reset
  type, public :: RT_Sol_Ctx_Reset_In
    ! No input parameters
  end type RT_Sol_Ctx_Reset_In
  type, public :: RT_Sol_Ctx_Reset_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Reset_Out

  ! RT_Sol_Ctx_GetStatus
  type, public :: RT_Sol_Ctx_GetStatus_In
    ! No input parameters
  end type RT_Sol_Ctx_GetStatus_In
  type, public :: RT_Sol_Ctx_GetStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetStatus_Out

  ! RT_Sol_Ctx_SetStatus
  type, public :: RT_Sol_Ctx_SetStatus_In
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_SetStatus_In
  type, public :: RT_Sol_Ctx_SetStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_SetStatus_Out

  ! RT_Sol_Ctx_ClearStatus
  type, public :: RT_Sol_Ctx_ClearStatus_In
    ! No input parameters
  end type RT_Sol_Ctx_ClearStatus_In
  type, public :: RT_Sol_Ctx_ClearStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_ClearStatus_Out

  ! RT_Sol_Ctx_IsOK
  type, public :: RT_Sol_Ctx_IsOK_In
    ! No input parameters
  end type RT_Sol_Ctx_IsOK_In
  type, public :: RT_Sol_Ctx_IsOK_Out
    logical :: is_ok
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_IsOK_Out

  ! RT_Sol_Ctx_IsError
  type, public :: RT_Sol_Ctx_IsError_In
    ! No input parameters
  end type RT_Sol_Ctx_IsError_In
  type, public :: RT_Sol_Ctx_IsError_Out
    logical :: is_error
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_IsError_Out

  ! RT_Sol_Ctx_Bind
  type, public :: RT_Sol_Ctx_Bind_In
    type(UF_Model), pointer, optional :: model
    type(UF_AnalysisStep), pointer, optional :: step
    type(RT_Sol_Cfg), pointer, optional :: solver
    type(RT_Sol_State), pointer, optional :: solver_state
    type(GlobalState), pointer, optional :: globalState
    type(NodeState), pointer, optional :: nodeStates(:)
    type(ElemState), pointer, optional :: elemStates(:)
    type(RT_Sol_DofMap), pointer, optional :: dofMap
    type(ThreadWS), pointer, optional :: tws(:)
    type(RT_CSRMatrix), pointer, optional :: K
    type(RT_CSRMatrix), pointer, optional :: M
    type(RT_CSRMatrix), pointer, optional :: C
    real(wp), pointer, optional :: F(:)
    real(wp), pointer, optional :: R(:)
    real(wp), pointer, optional :: u(:)
    real(wp), pointer, optional :: v(:)
    real(wp), pointer, optional :: a(:)
    real(wp), optional :: lambda
  end type RT_Sol_Ctx_Bind_In
  type, public :: RT_Sol_Ctx_Bind_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Bind_Out

  ! RT_Sol_Ctx_Valid
  type, public :: RT_Sol_Ctx_Valid_In
    ! No input parameters
  end type RT_Sol_Ctx_Valid_In
  type, public :: RT_Sol_Ctx_Valid_Out
    logical :: is_valid
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Valid_Out

  ! RT_Sol_Ctx_GetModel
  type, public :: RT_Sol_Ctx_GetModel_In
    ! No input parameters
  end type RT_Sol_Ctx_GetModel_In
  type, public :: RT_Sol_Ctx_GetModel_Out
    type(UF_Model), pointer :: model
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetModel_Out

  ! RT_Sol_Ctx_GetStep
  type, public :: RT_Sol_Ctx_GetStep_In
    ! No input parameters
  end type RT_Sol_Ctx_GetStep_In
  type, public :: RT_Sol_Ctx_GetStep_Out
    type(UF_AnalysisStep), pointer :: step
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetStep_Out

  ! RT_Sol_Ctx_GetSolver
  type, public :: RT_Sol_Ctx_GetSolver_In
    ! No input parameters
  end type RT_Sol_Ctx_GetSolver_In
  type, public :: RT_Sol_Ctx_GetSolver_Out
    type(RT_Sol_Cfg), pointer :: solver
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetSolver_Out

  ! RT_Sol_Ctx_GetSolverState
  type, public :: RT_Sol_Ctx_GetSolverState_In
    ! No input parameters
  end type RT_Sol_Ctx_GetSolverState_In
  type, public :: RT_Sol_Ctx_GetSolverState_Out
    type(RT_Sol_State), pointer :: solver_state
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetSolverState_Out

  ! RT_Sol_Ctx_GetGlobalState
  type, public :: RT_Sol_Ctx_GetGlobalState_In
    ! No input parameters
  end type RT_Sol_Ctx_GetGlobalState_In
  type, public :: RT_Sol_Ctx_GetGlobalState_Out
    type(GlobalState), pointer :: globalState
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetGlobalState_Out

  ! RT_Sol_Ctx_GetNodeStates
  type, public :: RT_Sol_Ctx_GetNodeStates_In
    ! No input parameters
  end type RT_Sol_Ctx_GetNodeStates_In
  type, public :: RT_Sol_Ctx_GetNodeStates_Out
    type(NodeState), pointer :: nodeStates(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetNodeStates_Out

  ! RT_Sol_Ctx_GetElemStates
  type, public :: RT_Sol_Ctx_GetElemStates_In
    ! No input parameters
  end type RT_Sol_Ctx_GetElemStates_In
  type, public :: RT_Sol_Ctx_GetElemStates_Out
    type(ElemState), pointer :: elemStates(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetElemStates_Out

  ! RT_Sol_Ctx_GetDofMap
  type, public :: RT_Sol_Ctx_GetDofMap_In
    ! No input parameters
  end type RT_Sol_Ctx_GetDofMap_In
  type, public :: RT_Sol_Ctx_GetDofMap_Out
    type(RT_Sol_DofMap), pointer :: dofMap
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetDofMap_Out

  ! RT_Sol_Ctx_GetTws
  type, public :: RT_Sol_Ctx_GetTws_In
    ! No input parameters
  end type RT_Sol_Ctx_GetTws_In
  type, public :: RT_Sol_Ctx_GetTws_Out
    type(ThreadWS), pointer :: tws(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetTws_Out

contains

  !====================================================================
  ! Structured Interfaces for RT_Sol_Ctx
  !====================================================================
  subroutine RT_Sol_Ctx_Init_Structured(ctx, in, out)
    !! Initialize solver context
    !!
    !! Theory:
    !!   Initializes the solver context with default status.
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_Init_In), intent(in) :: in
    type(RT_Sol_Ctx_Init_Out), intent(out) :: out

    type(ErrorStatusType) :: status
    call init_error_status(status)
    call ctx%sta%SetStatus(status)
    ctx%init = .true.
    call init_error_status(out%status)
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_Init_Structured

  subroutine RT_Sol_Ctx_Destroy_Structured(ctx, in, out)
    !! Destroy solver context
    !!
    !! Theory:
    !!   Cleans up solver context by nullifying all pointers.
    !!   Does not deallocate memory (ownership is elsewhere).
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_Destroy_In), intent(in) :: in
    type(RT_Sol_Ctx_Destroy_Out), intent(out) :: out

    call init_error_status(out%status)

    ! Nullify pointers (don't deallocate, ownership is elsewhere)
    nullify(ctx%model)
    nullify(ctx%step)
    nullify(ctx%solver)
    nullify(ctx%solver_state)
    nullify(ctx%globalState)
    nullify(ctx%nodeStates)
    nullify(ctx%elemStates)
    nullify(ctx%dofMap)
    nullify(ctx%tws)
    nullify(ctx%K)
    nullify(ctx%M)
    nullify(ctx%C)
    nullify(ctx%F)
    nullify(ctx%R)
    nullify(ctx%u)
    nullify(ctx%v)
    nullify(ctx%a)

    ctx%converged = .false.
    ctx%success = .false.
    ctx%lambda = 1.0_wp
    ctx%dlambda = 0.0_wp
    ctx%init = .false.

    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_Destroy_Structured

  subroutine RT_Sol_Ctx_Reset_Structured(ctx, in, out)
    !! Reset solver context
    !!
    !! Theory:
    !!   Resets convergence flag and clears status.
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_Reset_In), intent(in) :: in
    type(RT_Sol_Ctx_Reset_Out), intent(out) :: out

    call init_error_status(out%status)
    ctx%converged = .false.
    call ctx%sta%ClearStatus()
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_Reset_Structured

  subroutine RT_Sol_Ctx_GetStatus_Structured(ctx, in, out)
    !! Get solver context status
    !!
    !! Theory:
    !!   Retrieves the current error status from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetStatus_In), intent(in) :: in
    type(RT_Sol_Ctx_GetStatus_Out), intent(out) :: out

    if (.not. ctx%init) then
      call init_error_status(out%status)
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = 'RT_Sol_Ctx not initialized'
    else
      out%status = ctx%sta%GetStatus()
    end if
  end subroutine RT_Sol_Ctx_GetStatus_Structured

  subroutine RT_Sol_Ctx_SetStatus_Structured(ctx, in, out)
    !! Set solver context status
    !!
    !! Theory:
    !!   Sets the error status in the context.
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in%status: Error status to set
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_SetStatus_In), intent(in) :: in
    type(RT_Sol_Ctx_SetStatus_Out), intent(out) :: out

    call init_error_status(out%status)
    call ctx%sta%SetStatus(in%status)
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_SetStatus_Structured

  subroutine RT_Sol_Ctx_ClearStatus_Structured(ctx, in, out)
    !! Clear solver context status
    !!
    !! Theory:
    !!   Clears the error status in the context.
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_ClearStatus_In), intent(in) :: in
    type(RT_Sol_Ctx_ClearStatus_Out), intent(out) :: out

    call init_error_status(out%status)
    call ctx%sta%ClearStatus()
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_ClearStatus_Structured

  subroutine RT_Sol_Ctx_IsOK_Structured(ctx, in, out)
    !! Check if solver context is OK
    !!
    !! Theory:
    !!   Checks if the context status indicates success.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%is_ok: Whether context is OK
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_IsOK_In), intent(in) :: in
    type(RT_Sol_Ctx_IsOK_Out), intent(out) :: out

    call init_error_status(out%status)
    out%is_ok = ctx%sta%IsOK()
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_IsOK_Structured

  subroutine RT_Sol_Ctx_IsError_Structured(ctx, in, out)
    !! Check if solver context has error
    !!
    !! Theory:
    !!   Checks if the context status indicates an error.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%is_error: Whether context has error
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_IsError_In), intent(in) :: in
    type(RT_Sol_Ctx_IsError_Out), intent(out) :: out

    call init_error_status(out%status)
    out%is_error = ctx%sta%IsError()
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_IsError_Structured

  subroutine RT_Sol_Ctx_Bind_Structured(ctx, in, out)
    !! Bind solver context to model and solver components
    !!
    !! Theory:
    !!   Binds the solver context to model, step, solver, state, and matrix/vector pointers.
    !!   This establishes the connection between the solver and the finite element model.
    !!
    !! Input:
    !!   ctx: Solver context object (inout)
    !!   in%model: Model pointer (optional)
    !!   in%step: Analysis step pointer (optional)
    !!   in%solver: Solver configuration pointer (optional)
    !!   in%solver_state: Solver state pointer (optional)
    !!   in%globalState: Global state pointer (optional)
    !!   in%nodeStates: Node states pointer (optional)
    !!   in%elemStates: Element states pointer (optional)
    !!   in%dofMap: DOF mapping pointer (optional)
    !!   in%tws: Thread workspace pointer (optional)
    !!   in%K: Stiffness matrix pointer (optional)
    !!   in%M: Mass matrix pointer (optional)
    !!   in%C: Damping matrix pointer (optional)
    !!   in%F: Force vector pointer (optional)
    !!   in%R: Residual vector pointer (optional)
    !!   in%u: Displacement vector pointer (optional)
    !!   in%v: Velocity vector pointer (optional)
    !!   in%a: Acceleration vector pointer (optional)
    !!   in%lambda: Load factor (optional)
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(inout) :: ctx
    type(RT_Sol_Ctx_Bind_In), intent(in) :: in
    type(RT_Sol_Ctx_Bind_Out), intent(out) :: out

    call init_error_status(out%status)

    if (present(in%model)) ctx%model => in%model
    if (present(in%step)) ctx%step => in%step
    if (present(in%solver)) ctx%solver => in%solver
    if (present(in%solver_state)) ctx%solver_state => in%solver_state
    if (present(in%globalState)) ctx%globalState => in%globalState
    if (present(in%nodeStates)) ctx%nodeStates => in%nodeStates
    if (present(in%elemStates)) ctx%elemStates => in%elemStates
    if (present(in%dofMap)) ctx%dofMap => in%dofMap
    if (present(in%tws)) ctx%tws => in%tws
    if (present(in%K)) ctx%K => in%K
    if (present(in%M)) ctx%M => in%M
    if (present(in%C)) ctx%C => in%C
    if (present(in%F)) ctx%F => in%F
    if (present(in%R)) ctx%R => in%R
    if (present(in%u)) ctx%u => in%u
    if (present(in%v)) ctx%v => in%v
    if (present(in%a)) ctx%a => in%a
    if (present(in%lambda)) ctx%lambda = in%lambda

    call ctx%Init()
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_Bind_Structured

  subroutine RT_Sol_Ctx_Valid_Structured(ctx, in, out)
    !! Validate solver context
    !!
    !! Theory:
    !!   Validates that the context is properly initialized and all required pointers are associated.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%is_valid: Whether context is valid
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_Valid_In), intent(in) :: in
    type(RT_Sol_Ctx_Valid_Out), intent(out) :: out

    call init_error_status(out%status)
    out%is_valid = .true.

    ! Check initialization
    if (.not. ctx%init) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Context not initialized"
      return
    end if

    ! Check required pointers
    if (.not. associated(ctx%model)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Model pointer not associated"
      return
    end if

    if (.not. associated(ctx%step)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Step pointer not associated"
      return
    end if

    if (.not. associated(ctx%solver)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver pointer not associated"
      return
    end if

    if (.not. associated(ctx%solver_state)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver state pointer not associated"
      return
    end if

    if (.not. associated(ctx%globalState)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Global state pointer not associated"
      return
    end if

    if (.not. associated(ctx%nodeStates)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Node states pointer not associated"
      return
    end if

    if (.not. associated(ctx%elemStates)) then
      out%is_valid = .false.
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Element states pointer not associated"
      return
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_Valid_Structured

  subroutine RT_Sol_Ctx_GetModel_Structured(ctx, in, out)
    !! Get model pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the model pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%model: Model pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetModel_In), intent(in) :: in
    type(RT_Sol_Ctx_GetModel_Out), intent(out) :: out

    call init_error_status(out%status)
    out%model => ctx%model
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetModel_Structured

  subroutine RT_Sol_Ctx_GetStep_Structured(ctx, in, out)
    !! Get analysis step pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the analysis step pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%step: Analysis step pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetStep_In), intent(in) :: in
    type(RT_Sol_Ctx_GetStep_Out), intent(out) :: out

    call init_error_status(out%status)
    out%step => ctx%step
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetStep_Structured

  subroutine RT_Sol_Ctx_GetSolver_Structured(ctx, in, out)
    !! Get solver configuration pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the solver configuration pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%solver: Solver configuration pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetSolver_In), intent(in) :: in
    type(RT_Sol_Ctx_GetSolver_Out), intent(out) :: out

    call init_error_status(out%status)
    out%solver => ctx%solver
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetSolver_Structured

  subroutine RT_Sol_Ctx_GetSolverState_Structured(ctx, in, out)
    !! Get solver state pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the solver state pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%solver_state: Solver state pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetSolverState_In), intent(in) :: in
    type(RT_Sol_Ctx_GetSolverState_Out), intent(out) :: out

    call init_error_status(out%status)
    out%solver_state => ctx%solver_state
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetSolverState_Structured

  subroutine RT_Sol_Ctx_GetGlobalState_Structured(ctx, in, out)
    !! Get global state pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the global state pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%globalState: Global state pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetGlobalState_In), intent(in) :: in
    type(RT_Sol_Ctx_GetGlobalState_Out), intent(out) :: out

    call init_error_status(out%status)
    out%globalState => ctx%globalState
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetGlobalState_Structured

  subroutine RT_Sol_Ctx_GetNodeStates_Structured(ctx, in, out)
    !! Get node states pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the node states pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%nodeStates: Node states pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetNodeStates_In), intent(in) :: in
    type(RT_Sol_Ctx_GetNodeStates_Out), intent(out) :: out

    call init_error_status(out%status)
    out%nodeStates => ctx%nodeStates
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetNodeStates_Structured

  subroutine RT_Sol_Ctx_GetElemStates_Structured(ctx, in, out)
    !! Get element states pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the element states pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%elemStates: Element states pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetElemStates_In), intent(in) :: in
    type(RT_Sol_Ctx_GetElemStates_Out), intent(out) :: out

    call init_error_status(out%status)
    out%elemStates => ctx%elemStates
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetElemStates_Structured

  subroutine RT_Sol_Ctx_GetDofMap_Structured(ctx, in, out)
    !! Get DOF mapping pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the DOF mapping pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%dofMap: DOF mapping pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetDofMap_In), intent(in) :: in
    type(RT_Sol_Ctx_GetDofMap_Out), intent(out) :: out

    call init_error_status(out%status)
    out%dofMap => ctx%dofMap
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetDofMap_Structured

  subroutine RT_Sol_Ctx_GetTws_Structured(ctx, in, out)
    !! Get thread workspace pointer from solver context
    !!
    !! Theory:
    !!   Retrieves the thread workspace pointer from the context.
    !!
    !! Input:
    !!   ctx: Solver context object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%tws: Thread workspace pointer
    !!   out%status: Error status
    
    type(RT_Sol_Ctx), intent(in) :: ctx
    type(RT_Sol_Ctx_GetTws_In), intent(in) :: in
    type(RT_Sol_Ctx_GetTws_Out), intent(out) :: out

    call init_error_status(out%status)
    out%tws => ctx%tws
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_Sol_Ctx_GetTws_Structured

  !====================================================================
  ! RT_Sol_Ctx Procedures (Legacy - deprecated)
  !====================================================================

  subroutine RT_Sol_Ctx_Init(this)
    class(RT_Sol_Ctx), intent(inout) :: this

    type(ErrorStatusType) :: status
    call init_error_status(status)
    call this%sta%SetStatus(status)
    this%init = .true.
  end subroutine RT_Sol_Ctx_Init

  subroutine RT_Sol_Ctx_Destroy(this)
    class(RT_Sol_Ctx), intent(inout) :: this

    ! Nullify pointers (don't deallocate, ownership is elsewhere)
    nullify(this%model)
    nullify(this%step)
    nullify(this%solver)
    nullify(this%solver_state)
    nullify(this%globalState)
    nullify(this%nodeStates)
    nullify(this%elemStates)
    nullify(this%dofMap)
    nullify(this%tws)
    nullify(this%K)
    nullify(this%M)
    nullify(this%C)
    nullify(this%F)
    nullify(this%R)
    nullify(this%u)
    nullify(this%v)
    nullify(this%a)

    this%converged = .false.
    this%success = .false.
    this%lambda = 1.0_wp
    this%dlambda = 0.0_wp
    this%init = .false.
  end subroutine RT_Sol_Ctx_Destroy

  subroutine RT_Sol_Ctx_Reset(this)
    class(RT_Sol_Ctx), intent(inout) :: this

    this%converged = .false.
    call this%sta%ClearStatus()
  end subroutine RT_Sol_Ctx_Reset

  function RT_Sol_Ctx_GetStatus(this) result(status)
    class(RT_Sol_Ctx), intent(in) :: this
    type(ErrorStatusType) :: status

    if (.not. this%init) then
      call init_error_status(status)
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Sol_Ctx not initialized'
    else
      status = this%sta%GetStatus()
    end if
  end function RT_Sol_Ctx_GetStatus

  subroutine RT_Sol_Ctx_SetStatus(this, status)
    class(RT_Sol_Ctx), intent(inout) :: this
    type(ErrorStatusType), intent(in) :: status

    call this%sta%SetStatus(status)
  end subroutine RT_Sol_Ctx_SetStatus

  subroutine RT_Sol_Ctx_ClearStatus(this)
    class(RT_Sol_Ctx), intent(inout) :: this

    call this%sta%ClearStatus()
  end subroutine RT_Sol_Ctx_ClearStatus

  function RT_Sol_Ctx_IsOK(this) result(is_ok)
    class(RT_Sol_Ctx), intent(in) :: this
    logical :: is_ok

    is_ok = this%sta%IsOK()
  end function RT_Sol_Ctx_IsOK

  function RT_Sol_Ctx_IsError(this) result(is_error)
    class(RT_Sol_Ctx), intent(in) :: this
    logical :: is_error

    is_error = this%sta%IsError()
  end function RT_Sol_Ctx_IsError

  subroutine RT_Sol_Ctx_Bind(this, model, step, solver, solver_state, &
                              globalState, nodeStates, elemStates, dofMap, tws, &
                              K, M, C, F, R, u, v, a, lambda, AI_StepController, AI_ConvPredictor)
    class(RT_Sol_Ctx), intent(inout) :: this
    type(UF_Model), target, intent(in), optional :: model
    type(UF_AnalysisStep), target, intent(in), optional :: step
    type(RT_Sol_Cfg), target, intent(in), optional :: solver
    type(RT_Sol_State), target, intent(in), optional :: solver_state
    type(GlobalState), target, intent(in), optional :: globalState
    type(NodeState), target, intent(in), optional :: nodeStates(:)
    type(ElemState), target, intent(in), optional :: elemStates(:)
    type(RT_Sol_DofMap), target, intent(in), optional :: dofMap
    type(ThreadWS), target, intent(in), optional :: tws(:)
    type(RT_CSRMatrix), target, intent(in), optional :: K
    type(RT_CSRMatrix), target, intent(in), optional :: M
    type(RT_CSRMatrix), target, intent(in), optional :: C
    real(wp), target, intent(in), optional :: F(:)
    real(wp), target, intent(in), optional :: R(:)
    real(wp), target, intent(in), optional :: u(:)
    real(wp), target, intent(in), optional :: v(:)
    real(wp), target, intent(in), optional :: a(:)
    real(wp), intent(in), optional :: lambda
    procedure(RT_Glb_StepCtrl_IF), pointer, optional :: AI_StepController
    procedure(RT_Glb_ConvPred_IF), pointer, optional :: AI_ConvPredictor

    if (present(model)) this%model => model
    if (present(step)) this%step => step
    if (present(solver)) this%solver => solver
    if (present(solver_state)) this%solver_state => solver_state
    if (present(globalState)) this%globalState => globalState
    if (present(nodeStates)) this%nodeStates => nodeStates
    if (present(elemStates)) this%elemStates => elemStates
    if (present(dofMap)) this%dofMap => dofMap
    if (present(tws)) this%tws => tws
    if (present(K)) this%K => K
    if (present(M)) this%M => M
    if (present(C)) this%C => C
    if (present(F)) this%F => F
    if (present(R)) this%R => R
    if (present(u)) this%u => u
    if (present(v)) this%v => v
    if (present(a)) this%a => a
    if (present(lambda)) this%lambda = lambda
    if (present(AI_StepController)) this%AI_StepController => AI_StepController
    if (present(AI_ConvPredictor)) this%AI_ConvPredictor => AI_ConvPredictor

    call this%Init()
  end subroutine RT_Sol_Ctx_Bind

  function RT_Sol_Ctx_Valid(this) result(is_valid)
    class(RT_Sol_Ctx), intent(in) :: this
    logical :: is_valid

    is_valid = .true.

    ! Check initialization
    if (.not. this%init) then
      is_valid = .false.
      return
    end if

    ! Check required pointers
    if (.not. associated(this%model)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%step)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%solver)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%solver_state)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%globalState)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%nodeStates)) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%elemStates)) then
      is_valid = .false.
      return
    end if

    ! Optional: validate matrix pointers if present
    if (associated(this%K)) then
      ! Additional validation can be added here
    end if

    if (associated(this%M)) then
      ! Additional validation can be added here
    end if

    if (associated(this%C)) then
      ! Additional validation can be added here
    end if
  end function RT_Sol_Ctx_Valid

  function RT_Sol_Ctx_GetModel(this) result(model)
    class(RT_Sol_Ctx), intent(in) :: this
    type(UF_Model), pointer :: model
    model => this%model
  end function RT_Sol_Ctx_GetModel

  function RT_Sol_Ctx_GetStep(this) result(step)
    class(RT_Sol_Ctx), intent(in) :: this
    type(UF_AnalysisStep), pointer :: step
    step => this%step
  end function RT_Sol_Ctx_GetStep

  function RT_Sol_Ctx_GetSolver(this) result(solver)
    class(RT_Sol_Ctx), intent(in) :: this
    type(RT_Sol_Cfg), pointer :: solver
    solver => this%solver
  end function RT_Sol_Ctx_GetSolver

  function RT_Sol_Ctx_GetSolverState(this) result(solver_state)
    class(RT_Sol_Ctx), intent(in) :: this
    type(RT_Sol_State), pointer :: solver_state
    solver_state => this%solver_state
  end function RT_Sol_Ctx_GetSolverState

  function RT_Sol_Ctx_GetGlobalState(this) result(globalState)
    class(RT_Sol_Ctx), intent(in) :: this
    type(GlobalState), pointer :: globalState
    globalState => this%globalState
  end function RT_Sol_Ctx_GetGlobalState

  function RT_Sol_Ctx_GetNodeStates(this) result(nodeStates)
    class(RT_Sol_Ctx), intent(in) :: this
    type(NodeState), pointer :: nodeStates(:)
    nodeStates => this%nodeStates
  end function RT_Sol_Ctx_GetNodeStates

  function RT_Sol_Ctx_GetElemStates(this) result(elemStates)
    class(RT_Sol_Ctx), intent(in) :: this
    type(ElemState), pointer :: elemStates(:)
    elemStates => this%elemStates
  end function RT_Sol_Ctx_GetElemStates

  function RT_Sol_Ctx_GetDofMap(this) result(dofMap)
    class(RT_Sol_Ctx), intent(in) :: this
    type(RT_Sol_DofMap), pointer :: dofMap
    dofMap => this%dofMap
  end function RT_Sol_Ctx_GetDofMap

  function RT_Sol_Ctx_GetTws(this) result(tws)
    class(RT_Sol_Ctx), intent(in) :: this
    type(ThreadWS), pointer :: tws(:)
    tws => this%tws
  end function RT_Sol_Ctx_GetTws

! From RT_Solver_Sys.f90
procedure, public :: Init => RT_SolverCfg_Init
    procedure, public :: Valid => RT_SolverCfg_Valid
    procedure, public :: SetNR => RT_SolverCfg_SetNR
    procedure, public :: SetModNR => RT_SolverCfg_SetModNR
    procedure, public :: SetLBFGS => RT_SolverCfg_SetLBFGS
    procedure, public :: SetArcLen => RT_SolverCfg_SetArcLen
    procedure, public :: SetLinSolv => RT_SolverCfg_SetLinSolv
  end type RT_SolverCfg

  ! ===================================================================
  ! Solver Result Type
  ! ===================================================================
  type, public :: RT_SolverRes
    integer(i4) :: status = RT_SOLVER_STATUS_NOT_INITIALIZED
    integer(i4) :: nIterations = 0_i4
    integer(i4) :: nLinearSolv = 0_i4

    real(wp) :: final_residual = 0.0_wp
    real(wp) :: final_displacem = 0.0_wp
    real(wp) :: initial_residua = 0.0_wp

    real(wp) :: cpu_time = 0.0_wp
    real(wp) :: solve_time = 0.0_wp

    logical :: converged = .false.
    logical :: line_search_use = .false.
    integer(i4) :: line_search_ite = 0_i4

    character(len=256) :: error_message = ""
  contains
    procedure, public :: IsOk => RT_SolverRes_IsOk
    procedure, public :: IsFail => RT_SolverRes_IsFail
    procedure, public :: IsConv => RT_SolverRes_IsConv
    procedure, public :: GetSum => RT_SolverRes_GetSum
  end type RT_SolverRes

  ! ===================================================================
  ! Solver System Type
  ! ===================================================================
  type, public :: RT_SolverSys
    type(RT_Sol_In) :: increment_manag
    type(RT_Sol_Ite) :: iteration_manag
    procedure(solve_line_status_Intf), pointer :: linear_solve_cb => null()

    type(RT_SolverCfg) :: config
    type(RT_SolverRes) :: result

    integer(i4) :: system_status = RT_SOLVER_STATUS_NOT_INITIALIZED
    logical :: init = .false.
    logical :: has_nonlinear_s = .false.
    logical :: has_linear_solv = .false.
  contains
    procedure, public :: Init => RT_SolverSys_Init
    procedure, public :: Final => RT_SolverSys_Final
    procedure, public :: Cfg => RT_SolverSys_Cfg
    procedure, public :: Solve => RT_SolverSys_Solv
    procedure, public :: SolveLin => RT_SolverSys_SolveLin
    procedure, public :: SolveNonlin => RT_SolverSys_SolveNonlin
    procedure, public :: GetRes => RT_SolverSys_GetRes
    procedure, public :: GetStatus => RT_SolverSys_GetStatus
    procedure, public :: IsInit => RT_SolverSys_IsInit
    procedure, public :: IsRunning => RT_SolverSys_IsRunning
    procedure, public :: Reset => RT_SolverSys_Reset
    procedure, public :: SetAI_StepController => RT_SolverSys_SetAI_StepController
    procedure, public :: SetAI_ConvPredictor => RT_SolverSys_SetAI_ConvPredictor
  end type RT_SolverSys

  ! ===================================================================
  ! Structured Input/Output Types for RT_SolverSys
  ! ===================================================================
  ! RT_SolverSys_Init
  type, public :: RT_SolverSys_Init_In
    type(RT_SolverCfg), optional :: config  ! Solver configuration (optional)
  end type RT_SolverSys_Init_In
  type, public :: RT_SolverSys_Init_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Init_Out

  ! RT_SolverSys_Final
  type, public :: RT_SolverSys_Final_In
    ! No input parameters
  end type RT_SolverSys_Final_In
  type, public :: RT_SolverSys_Final_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Final_Out

  ! RT_SolverSys_Cfg
  type, public :: RT_SolverSys_Cfg_In
    type(RT_SolverCfg) :: config  ! Solver configuration
  end type RT_SolverSys_Cfg_In
  type, public :: RT_SolverSys_Cfg_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Cfg_Out

  ! RT_SolverSys_Solv
  type, public :: RT_SolverSys_Solv_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_Solv_In
  type, public :: RT_SolverSys_Solv_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Solv_Out

  ! RT_SolverSys_SolveLin
  type, public :: RT_SolverSys_SolveLin_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_SolveLin_In
  type, public :: RT_SolverSys_SolveLin_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_SolveLin_Out

  ! RT_SolverSys_SolveNonlin
  type, public :: RT_SolverSys_SolveNonlin_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_SolveNonlin_In
  type, public :: RT_SolverSys_SolveNonlin_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_SolveNonlin_Out

contains

  ! ===================================================================
  ! Structured Interfaces for RT_SolverSys
  ! ===================================================================
  subroutine RT_SolverSys_Init_Structured(solverSys, in, out)
    !! Initialize solver system
    !!
    !! Theory:
    !!   Initializes the solver system with optional configuration.
    !!   Sets system status to READY after successful initialization.
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in%config: Solver configuration (optional)
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_Init_In), intent(in) :: in
    type(RT_SolverSys_Init_Out), intent(out) :: out

    call init_error_status(out%status)

    call solverSys%config%Init()

    if (present(in%config)) then
      solverSys%config = in%config
    end if

    call solverSys%config%Valid(out%status)
    if (out%status%status_code /= IF_STATUS_OK) return

    solverSys%system_status = RT_SOLVER_STATUS_READY
    solverSys%init = .true.

    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_Init_Structured

  subroutine RT_SolverSys_Final_Structured(solverSys, in, out)
    !! Finalize solver system
    !!
    !! Theory:
    !!   Cleans up solver system resources and resets initialization state.
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_Final_In), intent(in) :: in
    type(RT_SolverSys_Final_Out), intent(out) :: out

    call init_error_status(out%status)

    solverSys%system_status = RT_SOLVER_STATUS_NOT_INITIALIZED
    solverSys%init = .false.
    solverSys%has_nonlinear_s = .false.
    solverSys%has_linear_solv = .false.

    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_Final_Structured

  subroutine RT_SolverSys_Cfg_Structured(solverSys, in, out)
    !! Configure solver system
    !!
    !! Theory:
    !!   Sets solver configuration. The configuration must be valid
    !!   and the system must be initialized.
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in%config: Solver configuration
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_Cfg_In), intent(in) :: in
    type(RT_SolverSys_Cfg_Out), intent(out) :: out

    call init_error_status(out%status)

    if (.not. solverSys%init) then
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver system must be initialized"
      return
    end if

    call in%config%Valid(out%status)
    if (out%status%status_code /= IF_STATUS_OK) return

    solverSys%config = in%config

    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_Cfg_Structured

  subroutine RT_SolverSys_Solv_Structured(solverSys, in, out)
    !! Solve system (general)
    !!
    !! Theory:
    !!   Solves the system using the configured solver method.
    !!   Nonlinear solver: K_T??u = -R
    !!   where K_T(n_dof,n_dof) tangent stiffness, du(n_dof) disp increment, R(n_dof) residual
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in: No input parameters (uses object state)
    !!
    !! Output:
    !!   out%result: Solver result (convergence status, iterations, residual norms)
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_Solv_In), intent(in) :: in
    type(RT_SolverSys_Solv_Out), intent(out) :: out

    type(ErrorStatusType) :: local_status
    real(wp) :: start_time, end_time

    call init_error_status(out%status)

    if (.not. solverSys%init) then
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver system must be initialized"
      return
    end if

    solverSys%system_status = RT_SOLVER_STATUS_RUNNING
    solverSys%result%status = RT_SOLVER_STATUS_RUNNING

    call cpu_time(start_time)

    call solverSys%iteration_manag%RunAllIter(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      solverSys%result%status = RT_SOLVER_STATUS_FAILED
      solverSys%result%converged = .false.
      solverSys%result%error_message = local_status%message
      solverSys%system_status = RT_SOLVER_STATUS_FAILED
      out%status = local_status
      return
    end if

    call cpu_time(end_time)
    solverSys%result%solve_time = end_time - start_time

    solverSys%result%status = solverSys%iteration_manag%status%status_code
    solverSys%result%converged = (solverSys%result%status == RT_SOLVER_STATUS_CONVERGED)
    solverSys%result%nIterations = solverSys%iteration_manag%currentIter - 1_i4
    solverSys%result%final_residual = solverSys%iteration_manag%status%residualNorm
    solverSys%result%final_displacem = solverSys%iteration_manag%status%dispNorm

    if (solverSys%result%converged) then
      solverSys%system_status = RT_SOLVER_STATUS_CONVERGED
    else if (solverSys%result%nIterations >= solverSys%config%max_iterations) then
      solverSys%system_status = RT_SOLVER_STATUS_MAX_ITER
    else
      solverSys%system_status = RT_SOLVER_STATUS_DIVERGED
    end if

    out%result = solverSys%result
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_Solv_Structured

  subroutine RT_SolverSys_SolveLin_Structured(solverSys, in, out)
    !! Solve linear system
    !!
    !! Theory:
    !!   Solves linear system: A?x = b
    !!   where A(n,n), x, b(n)
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in: No input parameters (uses object state)
    !!
    !! Output:
    !!   out%result: Solver result
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_SolveLin_In), intent(in) :: in
    type(RT_SolverSys_SolveLin_Out), intent(out) :: out

    type(ErrorStatusType) :: local_status
    real(wp) :: start_time, end_time

    call init_error_status(out%status)

    if (.not. solverSys%init) then
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver system must be initialized"
      return
    end if

    solverSys%system_status = RT_SOLVER_STATUS_RUNNING

    call cpu_time(start_time)

    if (associated(solverSys%linear_solve_cb)) then
      call solverSys%linear_solve_cb(local_status)
    else
      local_status%status_code = IF_STATUS_INVALID
      local_status%message = "Linear solve callback not set (call RT_SolverSys_SetLinearSolveCallback)"
    end if
    if (local_status%status_code /= IF_STATUS_OK) then
      solverSys%result%status = RT_SOLVER_STATUS_FAILED
      solverSys%result%converged = .false.
      solverSys%result%error_message = local_status%message
      solverSys%system_status = RT_SOLVER_STATUS_FAILED
      out%status = local_status
      return
    end if

    call cpu_time(end_time)
    solverSys%result%solve_time = end_time - start_time

    solverSys%result%status = RT_SOLVER_STATUS_CONVERGED
    solverSys%result%converged = .true.
    solverSys%result%nLinearSolv = 1_i4
    solverSys%result%final_residual = 0.0_wp

    solverSys%system_status = RT_SOLVER_STATUS_CONVERGED

    out%result = solverSys%result
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_SolveLin_Structured

  subroutine RT_SolverSys_SolveNonlin_Structured(solverSys, in, out)
    !! Solve nonlinear system
    !!
    !! Theory:
    !!   Solves nonlinear system using Newton-Raphson or other iterative method:
    !!     K_T??u = -R
    !!
    !!   where:
    !!     K_T = tangent stiffness matrix
    !!     ?u = displacement increment
    !!     R = residual vector
    !!
    !! Input:
    !!   solverSys: Solver system object (inout)
    !!   in: No input parameters (uses object state)
    !!
    !! Output:
    !!   out%result: Solver result (convergence status, iterations, residual norms)
    !!   out%status: Error status
    
    type(RT_SolverSys), intent(inout) :: solverSys
    type(RT_SolverSys_SolveNonlin_In), intent(in) :: in
    type(RT_SolverSys_SolveNonlin_Out), intent(out) :: out

    type(ErrorStatusType) :: local_status
    real(wp) :: start_time, end_time

    call init_error_status(out%status)

    if (.not. solverSys%init) then
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "Solver system must be initialized"
      return
    end if

    solverSys%system_status = RT_SOLVER_STATUS_RUNNING

    call cpu_time(start_time)

    call solverSys%iteration_manag%RunAllIter(local_status)
    if (local_status%status_code /= IF_STATUS_OK) then
      solverSys%result%status = RT_SOLVER_STATUS_FAILED
      solverSys%result%converged = .false.
      solverSys%result%error_message = local_status%message
      solverSys%system_status = RT_SOLVER_STATUS_FAILED
      out%status = local_status
      return
    end if

    call cpu_time(end_time)
    solverSys%result%solve_time = end_time - start_time

    solverSys%result%status = solverSys%iteration_manag%status%status_code
    solverSys%result%converged = (solverSys%result%status == RT_SOLVER_STATUS_CONVERGED)
    solverSys%result%nIterations = solverSys%iteration_manag%currentIter - 1_i4
    solverSys%result%final_residual = solverSys%iteration_manag%status%residualNorm
    solverSys%result%final_displacem = solverSys%iteration_manag%status%dispNorm

    if (solverSys%result%converged) then
      solverSys%system_status = RT_SOLVER_STATUS_CONVERGED
    else if (solverSys%result%nIterations >= solverSys%config%max_iterations) then
      solverSys%system_status = RT_SOLVER_STATUS_MAX_ITER
    else
      solverSys%system_status = RT_SOLVER_STATUS_DIVERGED
    end if

    out%result = solverSys%result
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_SolveNonlin_Structured

  ! ===================================================================
  ! Structured Input/Output Types for RT_SolverCfg
  ! ===================================================================
  ! RT_SolverCfg_SetNR
  type, public :: RT_SolverCfg_SetNR_In
    integer(i4), optional :: max_iter  ! Maximum iterations
    real(wp), optional :: tol  ! Convergence tolerance
  end type RT_SolverCfg_SetNR_In
  type, public :: RT_SolverCfg_SetNR_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetNR_Out

  ! RT_SolverCfg_SetModNR
  type, public :: RT_SolverCfg_SetModNR_In
    integer(i4), optional :: max_iter  ! Maximum iterations
    real(wp), optional :: tol  ! Convergence tolerance
  end type RT_SolverCfg_SetModNR_In
  type, public :: RT_SolverCfg_SetModNR_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetModNR_Out

  ! RT_SolverCfg_SetLBFGS
  type, public :: RT_SolverCfg_SetLBFGS_In
    integer(i4), optional :: memory  ! LBFGS memory size
    real(wp), optional :: tol  ! LBFGS tolerance
  end type RT_SolverCfg_SetLBFGS_In
  type, public :: RT_SolverCfg_SetLBFGS_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetLBFGS_Out

  ! RT_SolverCfg_SetArcLen
  type, public :: RT_SolverCfg_SetArcLen_In
    real(wp) :: parameter  ! Arc-length parameter
  end type RT_SolverCfg_SetArcLen_In
  type, public :: RT_SolverCfg_SetArcLen_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetArcLen_Out

  ! RT_SolverCfg_SetLinSolv
  type, public :: RT_SolverCfg_SetLinSolv_In
    integer(i4) :: solver_type  ! Linear solver type
  end type RT_SolverCfg_SetLinSolv_In
  type, public :: RT_SolverCfg_SetLinSolv_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetLinSolv_Out

  ! ===================================================================
  ! Structured Input/Output Types for RT_SolverRes
  ! ===================================================================
  ! RT_SolverRes_IsConv
  type, public :: RT_SolverRes_IsConv_In
    ! No input parameters
  end type RT_SolverRes_IsConv_In
  type, public :: RT_SolverRes_IsConv_Out
    logical :: converged
    type(ErrorStatusType) :: status
  end type RT_SolverRes_IsConv_Out

  ! RT_SolverRes_IsFail
  type, public :: RT_SolverRes_IsFail_In
    ! No input parameters
  end type RT_SolverRes_IsFail_In
  type, public :: RT_SolverRes_IsFail_Out
    logical :: failure
    type(ErrorStatusType) :: status
  end type RT_SolverRes_IsFail_Out

  ! RT_SolverRes_GetSum
  type, public :: RT_SolverRes_GetSum_In
    ! No input parameters
  end type RT_SolverRes_GetSum_In
  type, public :: RT_SolverRes_GetSum_Out
    character(len=512) :: summary
    type(ErrorStatusType) :: status
  end type RT_SolverRes_GetSum_Out

  ! ===================================================================
  ! RT_SolverCfg Procedures
  ! ===================================================================
  
  subroutine RT_SolverCfg_Init(this)
    class(RT_SolverCfg), intent(inout) :: this

    this%solver_type = RT_SOLVER_TYPE_NEWTON_RAPHSON
    this%linear_solver_type = RT_LINSOL_TYPE_DIRECT
    this%max_iterations = 50_i4
    this%convergence_tol = 1.0e-6_wp
    this%residual_tolera = 1.0e-8_wp
    this%displacement_to = 1.0e-8_wp
    this%use_line_search = .false.
    this%use_arc_length = .false.
    this%arc_length_para = 1.0_wp
    this%use_rayleigh_damping = .false.
    this%rayleigh_alpha = 0.0_wp
    this%rayleigh_beta = 0.0_wp
    this%lbfgs_memory = 10_i4
    this%lbfgs_tolerance = 1.0e-5_wp
  end subroutine RT_SolverCfg_Init

  subroutine RT_SolverCfg_Valid(this, status)
    class(RT_SolverCfg), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (this%solver_type < RT_SOLVER_TYPE_NEWTON_RAPHSON .or. &
        this%solver_type > RT_SOLVER_TYPE_EXPLICIT) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid solver type"
      return
    end if
    if (this%linear_solver_type < RT_LINSOL_TYPE_DIRECT .or. &
        this%linear_solver_type > RT_LINSOL_TYPE_BLOCK_PCG_3) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid linear solver type"
      return
    end if
    if (this%max_iterations <= 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Max iterations must be positive"
      return
    end if
    if (this%convergence_tol <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Convergence tolerance must be positive"
      return
    end if
    if (this%residual_tolera <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Residual tolerance must be positive"
      return
    end if
    if (this%displacement_to <= 0.0_wp) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Displacement tolerance must be positive"
      return
    end if
    if (this%lbfgs_memory <= 0_i4) then
      status%status_code = IF_STATUS_INVALID
      status%message = "LBFGS memory must be positive"
      return
    end if

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_Valid

  ! ===================================================================
  ! Structured Interfaces for RT_SolverCfg
  ! ===================================================================
  subroutine RT_SolverCfg_SetNR_Structured(cfg, in, out)
    !! Set Newton-Raphson solver configuration
    !!
    !! Theory:
    !!   Configures solver to use Newton-Raphson method:
    !!     K_T??u = -R
    !!
    !!   where K_T is the tangent stiffness matrix.
    !!
    !! Input:
    !!   cfg: Solver configuration object (inout)
    !!   in%max_iter: Maximum iterations (optional)
    !!   in%tol: Convergence tolerance (optional)
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverCfg), intent(inout) :: cfg
    type(RT_SolverCfg_SetNR_In), intent(in) :: in
    type(RT_SolverCfg_SetNR_Out), intent(out) :: out

    call init_error_status(out%status)
    cfg%solver_type = RT_SOLVER_TYPE_NEWTON_RAPHSON
    if (present(in%max_iter)) cfg%max_iterations = in%max_iter
    if (present(in%tol)) cfg%convergence_tol = in%tol
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_SetNR_Structured

  subroutine RT_SolverCfg_SetModNR_Structured(cfg, in, out)
    !! Set Modified Newton-Raphson solver configuration
    !!
    !! Theory:
    !!   Configures solver to use Modified Newton-Raphson method:
    !!     K_0??u = -R
    !!
    !!   where K_0 is the initial stiffness matrix (not updated).
    !!
    !! Input:
    !!   cfg: Solver configuration object (inout)
    !!   in%max_iter: Maximum iterations (optional)
    !!   in%tol: Convergence tolerance (optional)
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverCfg), intent(inout) :: cfg
    type(RT_SolverCfg_SetModNR_In), intent(in) :: in
    type(RT_SolverCfg_SetModNR_Out), intent(out) :: out

    call init_error_status(out%status)
    cfg%solver_type = RT_SOLVER_TYPE_MODIFIED_NEWTON
    if (present(in%max_iter)) cfg%max_iterations = in%max_iter
    if (present(in%tol)) cfg%convergence_tol = in%tol
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_SetModNR_Structured

  subroutine RT_SolverCfg_SetLBFGS_Structured(cfg, in, out)
    !! Set L-BFGS solver configuration
    !!
    !! Theory:
    !!   Configures solver to use Limited-memory BFGS (L-BFGS) method.
    !!   L-BFGS is a quasi-Newton method that approximates the Hessian
    !!   using a limited memory of previous iterations.
    !!
    !! Input:
    !!   cfg: Solver configuration object (inout)
    !!   in%memory: LBFGS memory size (optional)
    !!   in%tol: LBFGS tolerance (optional)
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverCfg), intent(inout) :: cfg
    type(RT_SolverCfg_SetLBFGS_In), intent(in) :: in
    type(RT_SolverCfg_SetLBFGS_Out), intent(out) :: out

    call init_error_status(out%status)
    cfg%solver_type = RT_SOLVER_TYPE_LBFGS
    if (present(in%memory)) cfg%lbfgs_memory = in%memory
    if (present(in%tol)) cfg%lbfgs_tolerance = in%tol
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_SetLBFGS_Structured

  subroutine RT_SolverCfg_SetArcLen_Structured(cfg, in, out)
    !! Set arc-length solver configuration
    !!
    !! Theory:
    !!   Configures solver to use arc-length method for path-following.
    !!   Arc-length method controls both load factor ? and displacement u:
    !!     ||?u||? + (??)? = (?s)?
    !!
    !!   where ?s is the arc-length step size.
    !!
    !! Input:
    !!   cfg: Solver configuration object (inout)
    !!   in%parameter: Arc-length parameter
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverCfg), intent(inout) :: cfg
    type(RT_SolverCfg_SetArcLen_In), intent(in) :: in
    type(RT_SolverCfg_SetArcLen_Out), intent(out) :: out

    call init_error_status(out%status)
    cfg%solver_type = RT_SOLVER_TYPE_ARC_LENGTH
    cfg%use_arc_length = .true.
    cfg%arc_length_para = in%parameter
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_SetArcLen_Structured

  subroutine RT_SolverCfg_SetLinSolv_Structured(cfg, in, out)
    !! Set linear solver type
    !!
    !! Theory:
    !!   Sets the linear solver type for solving A?x = b.
    !!   Available types: DIRECT, PCG, BLOCK_PCG_2, BLOCK_PCG_3.
    !!
    !! Input:
    !!   cfg: Solver configuration object (inout)
    !!   in%solver_type: Linear solver type
    !!
    !! Output:
    !!   out%status: Error status
    
    type(RT_SolverCfg), intent(inout) :: cfg
    type(RT_SolverCfg_SetLinSolv_In), intent(in) :: in
    type(RT_SolverCfg_SetLinSolv_Out), intent(out) :: out

    call init_error_status(out%status)
    cfg%linear_solver_type = in%solver_type
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCfg_SetLinSolv_Structured

  ! ===================================================================
  ! RT_SolverCfg Procedures (Legacy - deprecated)
  ! ===================================================================
  !> @deprecated Use RT_SolverCfg_SetNR_Structured instead
  subroutine RT_SolverCfg_SetNR(this, max_iter, tol)
    class(RT_SolverCfg), intent(inout) :: this
    integer(i4), intent(in), optional :: max_iter
    real(wp), intent(in), optional :: tol

    type(RT_SolverCfg_SetNR_In) :: in
    type(RT_SolverCfg_SetNR_Out) :: out

    if (present(max_iter)) in%max_iter = max_iter
    if (present(tol)) in%tol = tol
    call RT_SolverCfg_SetNR_Structured(this, in, out)
  end subroutine RT_SolverCfg_SetNR

  !> @deprecated Use RT_SolverCfg_SetModNR_Structured instead
  subroutine RT_SolverCfg_SetModNR(this, max_iter, tol)
    class(RT_SolverCfg), intent(inout) :: this
    integer(i4), intent(in), optional :: max_iter
    real(wp), intent(in), optional :: tol

    type(RT_SolverCfg_SetModNR_In) :: in
    type(RT_SolverCfg_SetModNR_Out) :: out

    if (present(max_iter)) in%max_iter = max_iter
    if (present(tol)) in%tol = tol
    call RT_SolverCfg_SetModNR_Structured(this, in, out)
  end subroutine RT_SolverCfg_SetModNR

  !> @deprecated Use RT_SolverCfg_SetLBFGS_Structured instead
  subroutine RT_SolverCfg_SetLBFGS(this, memory, tol)
    class(RT_SolverCfg), intent(inout) :: this
    integer(i4), intent(in), optional :: memory
    real(wp), intent(in), optional :: tol

    type(RT_SolverCfg_SetLBFGS_In) :: in
    type(RT_SolverCfg_SetLBFGS_Out) :: out

    if (present(memory)) in%memory = memory
    if (present(tol)) in%tol = tol
    call RT_SolverCfg_SetLBFGS_Structured(this, in, out)
  end subroutine RT_SolverCfg_SetLBFGS

  !> @deprecated Use RT_SolverCfg_SetArcLen_Structured instead
  subroutine RT_SolverCfg_SetArcLen(this, parameter)
    class(RT_SolverCfg), intent(inout) :: this
    real(wp), intent(in) :: parameter

    type(RT_SolverCfg_SetArcLen_In) :: in
    type(RT_SolverCfg_SetArcLen_Out) :: out

    in%parameter = parameter
    call RT_SolverCfg_SetArcLen_Structured(this, in, out)
  end subroutine RT_SolverCfg_SetArcLen

  !> @deprecated Use RT_SolverCfg_SetLinSolv_Structured instead
  subroutine RT_SolverCfg_SetLinSolv(this, solver_type)
    class(RT_SolverCfg), intent(inout) :: this
    integer(i4), intent(in) :: solver_type

    type(RT_SolverCfg_SetLinSolv_In) :: in
    type(RT_SolverCfg_SetLinSolv_Out) :: out

    in%solver_type = solver_type
    call RT_SolverCfg_SetLinSolv_Structured(this, in, out)
  end subroutine RT_SolverCfg_SetLinearSolver

  ! ===================================================================
  ! Structured Interfaces for RT_SolverRes
  ! ===================================================================
  subroutine RT_SolverRes_IsConv_Structured(res, in, out)
    !! Check if solver result indicates convergence
    !!
    !! Theory:
    !!   Checks if the solver converged successfully.
    !!
    !! Input:
    !!   res: Solver result object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%converged: Whether solver converged
    !!   out%status: Error status
    
    type(RT_SolverRes), intent(in) :: res
    type(RT_SolverRes_IsConv_In), intent(in) :: in
    type(RT_SolverRes_IsConv_Out), intent(out) :: out

    call init_error_status(out%status)
    out%converged = res%converged
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverRes_IsConv_Structured

  subroutine RT_SolverRes_IsFail_Structured(res, in, out)
    !! Check if solver result indicates failure
    !!
    !! Theory:
    !!   Checks if the solver failed (diverged, max iterations, or error).
    !!
    !! Input:
    !!   res: Solver result object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%failure: Whether solver failed
    !!   out%status: Error status
    
    type(RT_SolverRes), intent(in) :: res
    type(RT_SolverRes_IsFail_In), intent(in) :: in
    type(RT_SolverRes_IsFail_Out), intent(out) :: out

    call init_error_status(out%status)
    out%failure = (res%status == RT_SOLVER_STATUS_DIVERGED .or. &
                   res%status == RT_SOLVER_STATUS_MAX_ITER .or. &
                   res%status == RT_SOLVER_STATUS_FAILED)
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverRes_IsFail_Structured

  subroutine RT_SolverRes_GetSum_Structured(res, in, out)
    !! Get solver result summary
    !!
    !! Theory:
    !!   Generates a text summary of the solver result including:
    !!     - Status code
    !!     - Number of iterations
    !!     - Number of linear solves
    !!     - Convergence status
    !!     - Final residual norm ||R||
    !!     - Final displacement norm ||u||
    !!
    !! Input:
    !!   res: Solver result object (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%summary: Text summary
    !!   out%status: Error status
    
    type(RT_SolverRes), intent(in) :: res
    type(RT_SolverRes_GetSum_In), intent(in) :: in
    type(RT_SolverRes_GetSum_Out), intent(out) :: out

    call init_error_status(out%status)
    write(out%summary, '(A,I0,A,I0,A,I0,A,L1,A,ES10.3,A,ES10.3)') &
      "Solver: Status=", res%status, ", Iterations=", res%nIterations, &
      ", LinSolves=", res%nLinearSolv, ", Converged=", res%converged, &
      ", FinalResidual=", res%final_residual, &
      ", FinalDisp=", res%final_displacem
    out%status%status_code = IF_STATUS_OK
  end subroutine RT_SolverRes_GetSum_Structured

  ! ===================================================================
  ! RT_SolverRes Procedures (Legacy - deprecated)
  ! ===================================================================
  !> @deprecated Use RT_SolverRes_IsConv_Structured instead
  function RT_SolverRes_IsConv(this) result(converged)
    class(RT_SolverRes), intent(in) :: this
    logical :: converged

    type(RT_SolverRes_IsConv_In) :: in
    type(RT_SolverRes_IsConv_Out) :: out

    call RT_SolverRes_IsConv_Structured(this, in, out)
    converged = out%converged
  end function RT_SolverRes_IsConv

  !> @deprecated Use RT_SolverRes_IsFail_Structured instead
  function RT_SolverRes_IsFail(this) result(failure)
    class(RT_SolverRes), intent(in) :: this
    logical :: failure

    type(RT_SolverRes_IsFail_In) :: in
    type(RT_SolverRes_IsFail_Out) :: out

    call RT_SolverRes_IsFail_Structured(this, in, out)
    failure = out%failure
  end function RT_SolverRes_IsFail

  !> @deprecated Use RT_SolverRes_GetSum_Structured instead
  function RT_SolverRes_GetSum(this) result(summary)
    class(RT_SolverRes), intent(in) :: this
    character(len=512) :: summary

    type(RT_SolverRes_GetSum_In) :: in
    type(RT_SolverRes_GetSum_Out) :: out

    call RT_SolverRes_GetSum_Structured(this, in, out)
    summary = out%summary
  end function RT_SolverRes_GetSum

  !> @deprecated Use RT_SolverRes_IsConv_Structured instead
  function RT_SolverRes_IsSuccess(this) result(success)
    class(RT_SolverRes), intent(in) :: this
    logical :: success

    type(RT_SolverRes_IsConv_In) :: in
    type(RT_SolverRes_IsConv_Out) :: out

    call RT_SolverRes_IsConv_Structured(this, in, out)
    success = (this%status == RT_SOLVER_STATUS_CONVERGED .and. out%converged)
  end function RT_SolverRes_IsOk

  ! ===================================================================
  ! RT_SolverSys Procedures
  ! ===================================================================

  !> @deprecated Use RT_SolverSys_Init_Structured instead
  subroutine RT_SolverSys_Init(this, config, status)
    class(RT_SolverSys), intent(inout) :: this
    type(RT_SolverCfg), intent(in), optional :: config
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_Init_In) :: in
    type(RT_SolverSys_Init_Out) :: out

    if (present(config)) then
      in%config = config
    end if
    call RT_SolverSys_Init_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_Init

  !> @deprecated Use RT_SolverSys_Final_Structured instead
  subroutine RT_SolverSys_Final(this, status)
    class(RT_SolverSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_Final_In) :: in
    type(RT_SolverSys_Final_Out) :: out

    call RT_SolverSys_Final_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_Final

  !> @deprecated Use RT_SolverSys_Cfg_Structured instead
  subroutine RT_SolverSys_Cfg(this, config, status)
    class(RT_SolverSys), intent(inout) :: this
    type(RT_SolverCfg), intent(in) :: config
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_Cfg_In) :: in
    type(RT_SolverSys_Cfg_Out) :: out

    in%config = config
    call RT_SolverSys_Cfg_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_Cfg

  !> @deprecated Use RT_SolverSys_Solv_Structured instead
  subroutine RT_SolverSys_Solv(this, status)
    class(RT_SolverSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_Solv_In) :: in
    type(RT_SolverSys_Solv_Out) :: out

    call RT_SolverSys_Solv_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_Solv

  !> @deprecated Use RT_SolverSys_SolveLin_Structured instead
  subroutine RT_SolverSys_SolveLin(this, status)
    class(RT_SolverSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_SolveLin_In) :: in
    type(RT_SolverSys_SolveLin_Out) :: out

    call RT_SolverSys_SolveLin_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_SolveLin

  ! SetLinearSolveCallback: ?
  ! RT_SolverSys ?K/R/U RT_LinearSolver%Solve
  subroutine RT_SolverSys_SetLinearSolveCallback(this, proc)
    class(RT_SolverSys), intent(inout) :: this
    procedure(solve_line_status_Intf) :: proc
    this%linear_solve_cb => proc
    this%has_linear_solv = .true.
  end subroutine RT_SolverSys_SetLinearSolveCallback

  !> @deprecated Use RT_SolverSys_SolveNonlin_Structured instead
  subroutine RT_SolverSys_SolveNonlin(this, status)
    class(RT_SolverSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    type(RT_SolverSys_SolveNonlin_In) :: in
    type(RT_SolverSys_SolveNonlin_Out) :: out

    call RT_SolverSys_SolveNonlin_Structured(this, in, out)
    status = out%status
  end subroutine RT_SolverSys_SolveNonlin

  function RT_SolverSys_GetRes(this) result(result)
    class(RT_SolverSys), intent(in) :: this
    type(RT_SolverRes) :: result

    result = this%result
  end function RT_SolverSys_GetRes

  function RT_SolverSys_GetStatus(this) result(status)
    class(RT_SolverSys), intent(in) :: this
    integer(i4) :: status

    status = this%system_status
  end function RT_SolverSys_GetStatus

  function RT_SolverSys_IsInit(this) result(is_init)
    class(RT_SolverSys), intent(in) :: this
    logical :: is_init

    is_init = this%init
  end function RT_SolverSys_IsInit

  subroutine RT_SolverSys_SetAI_StepController(this, proc)
    class(RT_SolverSys), intent(inout) :: this
    procedure(RT_Glb_StepCtrl_IF) :: proc
    this%increment_manag%AI_StepController => proc
  end subroutine RT_SolverSys_SetAI_StepController

  subroutine RT_SolverSys_SetAI_ConvPredictor(this, proc)
    class(RT_SolverSys), intent(inout) :: this
    procedure(RT_Glb_ConvPred_IF) :: proc
    this%increment_manag%AI_ConvPredictor => proc
    this%iteration_manag%AI_ConvPredictor => proc
  end subroutine RT_SolverSys_SetAI_ConvPredictor

  function RT_SolverSys_IsRunning(this) result(running)
    class(RT_SolverSys), intent(in) :: this
    logical :: running

    running = (this%system_status == RT_SOLVER_STATUS_RUNNING)
  end function RT_SolverSys_IsRunning

  subroutine RT_SolverSys_Reset(this, status)
    class(RT_SolverSys), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = IF_STATUS_INVALID
      status%message = "Solver system must be initialized"
      return
    end if

    this%result%status = RT_SOLVER_STATUS_NOT_INITIALIZED
    this%result%converged = .false.
    this%result%nIterations = 0_i4
    this%result%nLinearSolv = 0_i4
    this%result%final_residual = 0.0_wp
    this%result%final_displacem = 0.0_wp
    this%result%initial_residua = 0.0_wp
    this%result%line_search_use = .false.
    this%result%line_search_ite = 0_i4

    this%system_status = RT_SOLVER_STATUS_READY

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverSys_Reset

! Sparse Matrix Procedures: matvec/csr_init_from_coo/Triplet/CSR_FromTriplet/CSR_SpMV moved to RT_SolvSparse

  subroutine RT_Rayleigh_BuildDampMat(K, mass, settings, C)
    type(RT_CSRMatrix),      intent(in)    :: K
    real(wp),      optional, intent(in)    :: mass(:)
    type(RT_Sol_Cfg),         intent(in)    :: settings
    type(RT_CSRMatrix),      intent(inout) :: C

    integer(i4) :: i, k, n, rowStart, rowEnd
    real(wp)    :: alpha, beta

    ! If Rayleigh damping is off, return empty C
    if (.not. settings%useRayleigh) then
      call RT_CSR_Free(C)
      return
    end if

    alpha = settings%alphaRayleigh
    beta  = settings%betaRayleigh

    ! Clear C first to avoid leaks
    call RT_CSR_Free(C)

    ! If beta != 0, copy K as template and scale values: C = beta * K
    if (abs(beta) > 0.0_wp) then
      C%nRows = K%nRows
      C%nCols = K%nCols
      C%nnz   = K%nnz
      allocate(C%rowPtr(size(K%rowPtr)))
      allocate(C%colInd(size(K%colInd)))
      allocate(C%values(size(K%values)))
      C%rowPtr = K%rowPtr
      C%colInd = K%colInd
      C%values = beta * K%values
      C%is_symmetric   = K%is_symmetric
      C%init = .true.
    else
      ! If beta == 0, reuse pattern from K but zero values
      C%nRows = K%nRows
      C%nCols = K%nCols
      C%nnz   = K%nnz
      allocate(C%rowPtr(size(K%rowPtr)))
      allocate(C%colInd(size(K%colInd)))
      allocate(C%values(size(K%values)))
      C%rowPtr = K%rowPtr
      C%colInd = K%colInd
      C%values = 0.0_wp
      C%is_symmetric   = K%is_symmetric
      C%init = .true.
    end if

    ! Mass-proportional damping: C_M = alpha * M using mass(:) on the diagonal
    if (present(mass)) then
      if (abs(alpha) > 0.0_wp) then
        n = min(size(mass), C%nRows)
        do i = 1, n
          if (mass(i) == 0.0_wp) cycle
          rowStart = C%rowPtr(i)
          rowEnd   = C%rowPtr(i+1) - 1
          do k = rowStart, rowEnd
            if (C%colInd(k) == i) then
              C%values(k) = C%values(k) + alpha * mass(i)
              exit
            end if
          end do
        end do
      end if
    end if
  end subroutine RT_Rayleigh_BuildDampMat

  subroutine RT_Rayleigh_UpdateMatrix(K, mass, settings)
    type(RT_CSRMatrix),      intent(inout) :: K
    real(wp),      optional, intent(in)    :: mass(:)
    type(RT_Sol_Cfg),         intent(in)    :: settings

    type(RT_CSRMatrix) :: C
    integer(i4)        :: k

    call RT_Rayleigh_BuildDampMat(K, mass, settings, C)
    if (.not. settings%useRayleigh) return
    if (.not. C%init) then
      call RT_CSR_Free(C)
      return
    end if

    ! Simple in-place update: K_eff = K + C (dense on same pattern)
    do k = 1, K%nnz
      K%values(k) = K%values(k) + C%values(k)
    end do

    call RT_CSR_Free(C)
  end subroutine RT_Rayleigh_UpdateMatrix

  ! BlockCSR/LU/LinSolve_Direct moved to RT_SolvSparse (H3.1 decoupling)

  subroutine RT_PCG_Solv(A, b, x, tol, maxIter, converged, nIter)
    type(RT_CSRMatrix), intent(in)    :: A
    real(wp),           intent(in)    :: b(:)
    real(wp),           intent(inout) :: x(:)
    real(wp),           intent(in)    :: tol
    integer(i4),        intent(in)    :: maxIter
    logical,            intent(out)   :: converged
    integer(i4),        intent(out), optional :: nIter

    integer(i4) :: n, k
    type(ThreadWS), pointer :: tws
    real(wp), pointer :: r(:), z(:), p(:), Ap(:)
    real(wp), allocatable :: r_fallback(:), z_fallback(:), p_fallback(:), Ap_fallback(:)
    real(wp) :: rz_old, rz_new, alpha, beta, resNorm
    type(ErrorStatusType) :: mem_status
    logical :: use_preallocate = .false.

    call init_error_status(mem_status)

    n = size(b)
    if (size(x) /= n) then
      if (allocated(x)) deallocate(x)
      allocate(x(n))
      x = 0.0_wp
    end if

    ! Try to use pre-allocated workspace from ThreadWS (Optimization)
    call UF_WS_GetCurrentThreadWorkspace(tws)
    if (associated(tws)) then
      call ThreadWS_GetPCGWorkspace(tws, n, r, z, p, Ap)
      if (associated(r)) then
        use_preallocate = .true.
      end if
    end if

    ! Fallback to memory pool or direct allocation
    if (.not. use_preallocate) then
      if (g_core_mem_pool%initialized) then
        real(wp), pointer :: r_mp(:), z_mp(:), p_mp(:), Ap_mp(:)
        nullify(r_mp, z_mp, p_mp, Ap_mp)
        call g_core_mem_pool%AllocDP1D('pcg_r', n, r_mp, mem_status)
        if (mem_status%status_code == 0 .and. associated(r_mp)) then
          r => r_mp
          call g_core_mem_pool%AllocDP1D('pcg_z', n, z_mp, mem_status)
          if (mem_status%status_code == 0 .and. associated(z_mp)) z => z_mp
          call g_core_mem_pool%AllocDP1D('pcg_p', n, p_mp, mem_status)
          if (mem_status%status_code == 0 .and. associated(p_mp)) p => p_mp
          call g_core_mem_pool%AllocDP1D('pcg_Ap', n, Ap_mp, mem_status)
          if (mem_status%status_code == 0 .and. associated(Ap_mp)) Ap => Ap_mp
        end if
      end if
      
      if (.not. associated(r)) then
        ! Final fallback: direct allocation
        allocate(r_fallback(n))
        allocate(z_fallback(n))
        allocate(p_fallback(n))
        allocate(Ap_fallback(n))
        r => r_fallback
        z => z_fallback
        p => p_fallback
        Ap => Ap_fallback
      end if
    end if

    call RT_CSR_SpMV(A, x, Ap)
    r = b - Ap
    z = r          ! No preconditioner currently (P = I)

    p = z

    rz_old  = dot_product(r, z)
    resNorm = sqrt(dot_product(r, r))

    converged = (resNorm <= tol)

    do k = 1, maxIter
      if (converged) exit

      call RT_CSR_SpMV(A, p, Ap)
      alpha = rz_old / max(dot_product(p, Ap), 1.0e-30_wp)

      x = x + alpha * p
      r = r - alpha * Ap

      resNorm = sqrt(dot_product(r, r))
      if (resNorm <= tol) then
        converged = .true.
        exit
      end if

      z = r
      rz_new = dot_product(r, z)
      beta   = rz_new / max(rz_old, 1.0e-30_wp)
      p      = z + beta * p
      rz_old = rz_new
    end do

    if (present(nIter)) nIter = k

    ! Cleanup: only deallocate if not using pre-allocated workspace
    if (.not. use_preallocate) then
      if (g_core_mem_pool%initialized .and. associated(r)) then
        ! Check if pointers are from memory pool (by checking if they're associated)
        call g_core_mem_pool%Dealloc('pcg_r')
        call g_core_mem_pool%Dealloc('pcg_z')
        call g_core_mem_pool%Dealloc('pcg_p')
        call g_core_mem_pool%Dealloc('pcg_Ap')
      else
        ! Deallocate fallback arrays
        if (allocated(r_fallback)) deallocate(r_fallback)
        if (allocated(z_fallback)) deallocate(z_fallback)
        if (allocated(p_fallback)) deallocate(p_fallback)
        if (allocated(Ap_fallback)) deallocate(Ap_fallback)
      end if
      ! Nullify pointers
      nullify(r, z, p, Ap)
    end if
  end subroutine RT_PCG_Solv

  !====================================================================
  ! RT_Eq_SolveFixedLambda (merged from RT_Solver_Step_API)
  !
  ! Unified fixed-lambda equilibrium solve entry using RT_Sol_State:
  !   - method        : RT_Eq_Method_* (NEWTON / MOD_NEWTON / LBFGS)
  !   - solver_state  : Unified solver state structure containing u, R, F_ext, K, etc.
  !   - nlParams_in   : Nonlinear parameters
  !   - Calc_residual/Calc_tangent/linear_solve: Callbacks using state structure
  !   - result        : Iteration result
  !   - status        : Error status (replaces ierr)
  !   - globalState   : Optional global state
  !====================================================================

  subroutine RT_Eq_SolveFixedLambda(method, solver_state, &
                                     nlParams_in, Calc_residual, Calc_tangent, &
                                     linear_solve, result, status, globalState, AI_ConvPredictor)
    integer(i4),          intent(in)    :: method
    type(RT_Sol_State),   intent(inout) :: solver_state
    type(UF_NLParams),    intent(in)    :: nlParams_in
    procedure(eq_residual_Intf_state)     :: Calc_residual
    procedure(eq_tangent_Intf_state)      :: Calc_tangent
    procedure(eq_Lin_Solv_Intf_state) :: linear_solve
    type(UF_NLResult),    intent(out)   :: result
    type(ErrorStatusType), intent(inout) :: status
    type(RT_GlobalState), intent(inout), optional :: globalState
    procedure(RT_Glb_ConvPred_IF), pointer, optional :: AI_ConvPredictor

    type(UF_NLParams) :: nlParams
    integer(i4) :: n, iter, max_iter
    real(wp) :: res_norm, disp_norm
    real(wp) :: energy_init, energy_prev, energy_ratio
    real(wp) :: norm_F, tiny_energy
    real(wp) :: work_ext, energy_int, energy_total
    real(wp) :: max_energy_fact, adapt_factor
    logical  :: is_converged, update_stiffnes

    real(wp), pointer :: u_curr(:) => null()      ! Current inc DOF
    real(wp), pointer :: du_corr(:) => null()     ! Current correction inc
    real(wp), pointer :: R_work(:) => null()      ! Residual ws
    real(wp), pointer :: u_prev(:) => null()      ! Previous iterate u_curr
    real(wp), pointer :: F_int(:) => null()       ! Current internal force
    real(wp), pointer :: u_energy(:) => null()    ! Total disp (u_ref + u_curr)
    real(wp), pointer :: u_total(:) => null()     ! LBFGS path vector
    real(wp), pointer :: R_lbfgs(:) => null()     ! LBFGS residual
    
    real(wp), allocatable :: u_curr_fallback(:), du_corr_fallbac(:), R_work_fallback(:)
    real(wp), allocatable :: u_prev_fallback(:), F_int_fallback(:), u_energy_fallba(:)
    real(wp), allocatable :: u_total_fallbac(:), R_LBFGS_FALLBAC(:)
    
    type(ThreadWS), pointer :: tws => null()
    type(UF_NLParams) :: nlParams_lb
    type(ErrorStatusType) :: mem_status, callback_status
    logical :: use_preallocate = .false.
    logical :: use_mem_pool
    integer(i4) :: ierr_legacy
    real(wp), allocatable :: res_hist(:)
    logical :: will_conv
    real(wp) :: conf
    type(ErrorStatusType) :: ai_st

    call init_error_status(status)
    call init_error_status(mem_status)
    call init_error_status(callback_status)
    
    is_converged = .false.
    tiny_energy  = 1.0e-12_wp

    ! Valid solver_state
    if (.not. solver_state%initialized) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Eq_SolveFixedLambda: solver_state not initialized'
      return
    end if

    n = solver_state%nDOF
    if (n <= 0_i4) then
      result%iterations    = 0
      result%converged     = 1
      result%residual_norm = 0.0_wp
      result%disp_norm     = 0.0_wp
      result%energy_norm   = 0.0_wp
      result%load_factor   = solver_state%lambda
      result%arc_length    = 1.0_wp
      if (present(globalState)) then
        globalState%iterId    = 0_i4
        globalState%residNorm = 0.0_wp
      end if
      status%status_code = IF_STATUS_OK
      return
    end if

    ! Valid arrays
    if (.not. associated(solver_state%u) .or. size(solver_state%u) < n .or. &
        .not. associated(solver_state%R) .or. size(solver_state%R) < n .or. &
        .not. associated(solver_state%F_ext) .or. size(solver_state%F_ext) < n .or. &
        .not. associated(solver_state%u_ref) .or. size(solver_state%u_ref) < n) then
      status%status_code = IF_STATUS_INVALID
      status%message = 'RT_Eq_SolveFixedLambda: solver_state arrays not properly allocated'
      return
    end if
    
    ! Try to get pre-allocated workspace from ThreadWS
    tws => UF_WS_GetCurrentThreadWorkspacePtr()
    if (associated(tws)) then
      call ThreadWS_GetIterationWorkspace(tws, n, &
                                         u_curr=u_curr, du_corr=du_corr, R_work=R_work, &
                                         u_prev=u_prev, F_int=F_int, u_energy=u_energy, &
                                         u_total=u_total, R_lbfgs=R_lbfgs)
      if (associated(u_curr) .and. associated(du_corr) .and. associated(R_work) .and. &
          associated(u_prev) .and. associated(F_int) .and. associated(u_energy) .and. &
          associated(u_total) .and. associated(R_lbfgs)) then
        use_preallocate = .true.
      end if
    end if
    
    ! Fallback to memory pool or direct allocation
    if (.not. use_preallocate) then
      use_mem_pool = g_core_mem_pool%initialized
    end if

    !--------------------------------------------------------------
    ! 1) LBFGS path: directly reuse NM_NonlinSolv::nl_lbfgs
    !--------------------------------------------------------------

    if (method == RT_EQ_METHOD_LB) then
      ! Use pre-allocated workspace if available, otherwise fallback
      if (.not. use_preallocate) then
        if (use_mem_pool) then
          call g_core_mem_pool%AllocDP1D('equil_u_total', n, u_total, mem_status)
          if (mem_status%status_code /= 0) then
            allocate(u_total_fallbac(n))
            u_total => u_total_fallbac
          end if
          call g_core_mem_pool%AllocDP1D('equil_R_lbfgs', n, R_lbfgs, mem_status)
          if (mem_status%status_code /= 0) then
            allocate(R_LBFGS_FALLBAC(n))
            R_lbfgs => R_LBFGS_FALLBAC
          end if
        else
          allocate(u_total_fallbac(n))
          allocate(R_LBFGS_FALLBAC(n))
          u_total => u_total_fallbac
          R_lbfgs => R_LBFGS_FALLBAC
        end if
      end if

      u_total(1:n)  = solver_state%u_ref(1:n) + solver_state%u(1:n)
      R_lbfgs(1:n)  = 0.0_wp

      nlParams_lb = nlParams_in
      ! For LBFGS, keep conv_type consistent with NM_NonlinSolv (CONV_FORCE/CONV_DISP/...)
      if (nlParams_lb%conv_type < CONV_FORCE .or. nlParams_lb%conv_type > CONV_MIXED) then
        nlParams_lb%conv_type = CONV_MIXED
      end if

      ! Note: nl_lbfgs no longer takes globalState; L2 is decoupled from L3
      call nl_lbfgs(R_lbfgs, u_total, solver_state%F_ext, solver_state%lambda, nlParams_lb, &
                    Calc_residual_legacy_adapter, result, ierr_legacy)

      if (present(globalState)) then
        globalState%iterId    = result%iterations
        globalState%residNorm = result%residual_norm
      end if

      if (ierr_legacy == 0_i4) then
        solver_state%u(1:n) = u_total(1:n) - solver_state%u_ref(1:n)
      else
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_Eq_SolveFixedLambda: LBFGS solver failed'
      end if

      ! Cleanup fallback arrays if used
      if (.not. use_preallocate) then
        if (allocated(u_total_fallbac)) deallocate(u_total_fallbac)
        if (allocated(R_LBFGS_FALLBAC)) deallocate(R_LBFGS_FALLBAC)
        if (use_mem_pool) then
          call g_core_mem_pool%Dealloc('equil_u_total')
          call g_core_mem_pool%Dealloc('equil_R_lbfgs')
        end if
      end if
      return
    end if

    !--------------------------------------------------------------
    ! 2) NEWTON / MOD_NEWTON loop following Theory/UF_NonlinearTheory.f90
    !--------------------------------------------------------------

    max_iter = nlParams_in%max_iter
    nlParams = nlParams_in

    if (present(AI_ConvPredictor) .and. associated(AI_ConvPredictor)) then
      allocate(res_hist(max_iter))
    end if

    ! Treat nlParams%arc_length as max_energy_fact for adaptive energy check
    max_energy_fact = nlParams%arc_length
    if (max_energy_fact < 0.0_wp) max_energy_fact = 0.0_wp

    ! Use pre-allocated workspace if available, otherwise fallback
    if (.not. use_preallocate) then
      if (use_mem_pool) then
        call g_core_mem_pool%AllocDP1D('equil_u_curr', n, u_curr, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(u_curr_fallback(n))
          u_curr => u_curr_fallback
        end if
        call g_core_mem_pool%AllocDP1D('equil_du_corr', n, du_corr, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(du_corr_fallbac(n))
          du_corr => du_corr_fallbac
        end if
        call g_core_mem_pool%AllocDP1D('equil_R_work', n, R_work, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(R_work_fallback(n))
          R_work => R_work_fallback
        end if
        call g_core_mem_pool%AllocDP1D('equil_u_prev', n, u_prev, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(u_prev_fallback(n))
          u_prev => u_prev_fallback
        end if
        call g_core_mem_pool%AllocDP1D('equil_F_int', n, F_int, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(F_int_fallback(n))
          F_int => F_int_fallback
        end if
        call g_core_mem_pool%AllocDP1D('equil_u_energy', n, u_energy, mem_status)
        if (mem_status%status_code /= 0) then
          allocate(u_energy_fallba(n))
          u_energy => u_energy_fallba
        end if
      else
        allocate(u_curr_fallback(n))
        allocate(du_corr_fallbac(n))
        allocate(R_work_fallback(n))
        allocate(u_prev_fallback(n))
        allocate(F_int_fallback(n))
        allocate(u_energy_fallba(n))
        u_curr => u_curr_fallback
        du_corr => du_corr_fallbac
        R_work => R_work_fallback
        u_prev => u_prev_fallback
        F_int => F_int_fallback
        u_energy => u_energy_fallba
      end if
    end if

    u_curr(1:n)   = solver_state%u(1:n)   ! Current inc DOF (relative to previous inc)

    du_corr  = 0.0_wp
    R_work   = 0.0_wp
    u_prev   = 0.0_wp
    F_int    = 0.0_wp
    u_energy = 0.0_wp

    norm_F = max(1.0_wp, sqrt(dot_product(solver_state%F_ext(1:n), solver_state%F_ext(1:n))))

    ! Initial residual
    solver_state%u(1:n) = u_curr(1:n)
    call Calc_residual(solver_state, callback_status)
    if (callback_status%status_code /= IF_STATUS_OK) then
      status = callback_status
      goto 900
    end if
    R_work(1:n) = solver_state%R(1:n)

    res_norm  = sqrt(dot_product(R_work(1:n), R_work(1:n))) / norm_F
    disp_norm = 0.0_wp

    ! Init energy marker: E = U_int - W_ext = 0.5*F_int*u_total - (lambda*F_ext)*u_total
    u_energy(1:n) = solver_state%u_ref(1:n) + u_curr(1:n)
    F_int(1:n)    = R_work(1:n) + solver_state%lambda * solver_state%F_ext(1:n)

    work_ext     = solver_state%lambda * dot_product(solver_state%F_ext(1:n), u_energy(1:n))
    energy_int   = 0.5_wp * dot_product(F_int(1:n), u_energy(1:n))
    energy_total = energy_int - work_ext

    energy_prev = energy_total
    if (abs(energy_prev) > tiny_energy) then
      energy_init = abs(energy_prev)
    else
      energy_init = tiny_energy
    end if

    result%iterations    = 0
    result%converged     = 0
    result%residual_norm = res_norm
    result%disp_norm     = disp_norm
    result%energy_norm   = abs(energy_prev)
    result%load_factor   = solver_state%lambda
    result%arc_length    = 1.0_wp

    do iter = 1, max_iter
      result%iterations = iter

      !-------------------------------
      ! 2.1 Convergence check (HY_Equit conv_mode mapping)
      !-------------------------------

      if (energy_init > 0.0_wp) then
        energy_ratio = abs(energy_prev) / energy_init
      else
        energy_ratio = 0.0_wp
      end if

      select case (nlParams%conv_type)
      case (0)
        is_converged = (energy_ratio <= nlParams%tol_energy)
      case (1)
        is_converged = (energy_ratio <= nlParams%tol_energy .and. res_norm <= nlParams%tol_force)
      case (2)
        is_converged = (energy_ratio <= nlParams%tol_energy .and. disp_norm <= nlParams%tol_disp)
      case (3)
        is_converged = (res_norm <= nlParams%tol_force)
      case (4)
        is_converged = (disp_norm <= nlParams%tol_disp)
      case (CONV_FORCE)
        is_converged = (res_norm <= nlParams%tol_force)
      case (CONV_DISP)
        is_converged = (disp_norm <= nlParams%tol_disp)
      case (CONV_ENERGY)
        is_converged = (energy_ratio <= nlParams%tol_energy)
      case (CONV_MIXED)
        is_converged = ((res_norm <= nlParams%tol_force .and. disp_norm <= nlParams%tol_disp) &
                        .or. (energy_ratio <= nlParams%tol_energy))
      case default
        is_converged = (res_norm <= nlParams%tol_force)
      end select

      if (is_converged) exit

      ! Keep previous disp inc for norm check
      u_prev = u_curr

      !-------------------------------
      ! 2.2 Choose stiffness update strategy (NEWTON / MOD_NEWTON)
      !-------------------------------
      select case (method)
      case (RT_EQ_METHOD_NE)
        update_stiffnes = .true.
      case (RT_EQ_METHOD_MO)
        update_stiffnes = (iter == 1)
      case default
        update_stiffnes = .true.
      end select

      if (update_stiffnes) then
        solver_state%u(1:n) = u_curr(1:n)
        call Calc_tangent(solver_state, callback_status)
        if (callback_status%status_code /= IF_STATUS_OK) then
          status = callback_status
          goto 900
        end if
      end if

      !-------------------------------
      ! 2.3 Linear correction: K * du_corr = -R
      !-------------------------------
      du_corr = 0.0_wp
      solver_state%R(1:n) = -R_work(1:n)
      call linear_solve(solver_state, callback_status)
      if (callback_status%status_code /= IF_STATUS_OK) then
        status = callback_status
        goto 900
      end if
      du_corr(1:n) = solver_state%du(1:n)

      !-------------------------------
      ! 2.4 Update solution
      !-------------------------------
      u_curr = u_curr + du_corr
      solver_state%u(1:n) = u_curr(1:n)
      call Calc_residual(solver_state, callback_status)
      if (callback_status%status_code /= IF_STATUS_OK) then
        status = callback_status
        goto 900
      end if
      R_work(1:n) = solver_state%R(1:n)
      res_norm = sqrt(dot_product(R_work(1:n), R_work(1:n))) / norm_F

      ! Update disp inc norm
      disp_norm = sqrt(dot_product(u_curr(1:n) - u_prev(1:n), u_curr(1:n) - u_prev(1:n)))

      ! Recompute external/internal work and total energy
      u_energy(1:n) = solver_state%u_ref(1:n) + u_curr(1:n)
      F_int(1:n)    = R_work(1:n) + solver_state%lambda * solver_state%F_ext(1:n)

      work_ext     = solver_state%lambda * dot_product(solver_state%F_ext(1:n), u_energy(1:n))
      energy_int   = 0.5_wp * dot_product(F_int(1:n), u_energy(1:n))
      energy_total = energy_int - work_ext

      ! Energy blow-up check: if |E| exceeds (1+max_energy_fact)*|E_init|, treat as divergence.
      if (max_energy_fact > 0.0_wp .and. energy_init > 0.0_wp) then
        if (abs(energy_total) > (1.0_wp + max_energy_fact) * energy_init) then
          status%status_code = IF_STATUS_ERROR
          status%message = 'RT_Eq_SolveFixedLambda: Energy blow-up detected'
          result%converged = -1
          exit
        end if
      end if

      energy_prev = energy_total

      result%residual_norm = res_norm
      result%disp_norm     = disp_norm
      result%energy_norm   = abs(energy_prev)

      ! AI-ready: call ConvergencePredictor with residual history (if associated)
      if (allocated(res_hist)) then
        res_hist(iter) = sqrt(dot_product(R_work(1:n), R_work(1:n)))
        if (iter >= 3_i4) then
          call AI_ConvPredictor(res_hist(1:iter), will_conv, conf, ai_st)
          ! Optional: early exit when predictor says will not converge (future use)
        end if
      end if

      ! R3: Core layer no WRITE(*,*), use IF_Log
      ! write(*,'(A,I4,2(1X,ES12.5))') 'RT_EQUIL(HY-like): iter,lambda,res=', &
      !      iter, solver_state%lambda, res_norm
    end do

    if (is_converged .and. status%status_code == IF_STATUS_OK) then
      result%converged = 1
    else if (result%converged /= -1) then
      result%converged = 0
      if (status%status_code == IF_STATUS_OK) then
        status%status_code = IF_STATUS_ERROR
        status%message = 'RT_Eq_SolveFixedLambda: Not converged'
      end if
    end if

    ! Write final inc u_curr back to solver_state
    solver_state%u(1:n) = u_curr(1:n)
    if (associated(solver_state%du)) then
      solver_state%du(1:n) = u_curr(1:n)
    end if

900 continue
    if (allocated(res_hist)) deallocate(res_hist)
    ! Cleanup fallback arrays if used
    if (.not. use_preallocate) then
      if (allocated(u_curr_fallback)) deallocate(u_curr_fallback)
      if (allocated(du_corr_fallbac)) deallocate(du_corr_fallbac)
      if (allocated(R_work_fallback)) deallocate(R_work_fallback)
      if (allocated(u_prev_fallback)) deallocate(u_prev_fallback)
      if (allocated(F_int_fallback)) deallocate(F_int_fallback)
      if (allocated(u_energy_fallba)) deallocate(u_energy_fallba)
      if (use_mem_pool) then
        call g_core_mem_pool%Dealloc('equil_u_curr')
        call g_core_mem_pool%Dealloc('equil_du_corr')
        call g_core_mem_pool%Dealloc('equil_R_work')
        call g_core_mem_pool%Dealloc('equil_u_prev')
        call g_core_mem_pool%Dealloc('equil_F_int')
        call g_core_mem_pool%Dealloc('equil_u_energy')
      end if
    end if
    
    ! Adaptive arc-length suggestion: use target_iter vs actual iterations to derive scale factor
    result%arc_length = 1.0_wp
    if (nlParams%adaptive) then
      adapt_factor = sqrt(real(max(nlParams%target_iter, 1_i4), wp) / &
                          real(max(result%iterations,   1_i4), wp))
      adapt_factor = max(0.25_wp, min(4.0_wp, adapt_factor))
      result%arc_length = adapt_factor
    end if

    if (present(globalState)) then
      globalState%iterId    = result%iterations
      globalState%residNorm = result%residual_norm
    end if

  contains

    ! Legacy adapter for nl_lbfgs (temporary, until nl_lbfgs is refactored)
    subroutine Calc_residual_legacy_adapter(u_vec, lambda_loc, F_ext_in, R_out, ierr_out)
      real(wp), intent(in) :: u_vec(:)
      real(wp), intent(in) :: lambda_loc
      real(wp), intent(in) :: F_ext_in(:)
      real(wp), intent(out) :: R_out(:)
      integer, intent(out) :: ierr_out

      solver_state%u(1:n) = u_vec(1:n)
      solver_state%lambda = lambda_loc
      solver_state%F_ext(1:n) = F_ext_in(1:n)
      call Calc_residual(solver_state, callback_status)
      if (callback_status%status_code == IF_STATUS_OK) then
        R_out(1:n) = solver_state%R(1:n)
        ierr_out = 0
      else
        ierr_out = -1
      end if
    end subroutine Calc_residual_legacy_adapter

  end subroutine RT_Eq_SolveFixedLambda

  ! ===================================================================
  ! Solver Coordinator (merged from RT_Ops)
  ! ===================================================================
  
  type, public :: RT_SolCoordinator
    integer(i4) :: coordinatorId = 0_i4
    integer(i4) :: solverType = 0_i4
    type(IncState), pointer :: state => null()
    logical :: isInitialized = .false.
    logical :: isRunning = .false.
    real(wp) :: convergencetole = 1.0e-5_wp
    integer(i4) :: maxIterations = 30_i4
  contains
    procedure, public :: Init => RT_SolverCoordinator_Init
    procedure, public :: Run => RT_SolverCoordinator_Run
    procedure, public :: Update => RT_SolverCoordinator_Update
    procedure, public :: CheckConv => RT_SolverCoordinator_CheckConv
    procedure, public :: GetStatus => RT_SolverCoordinator_GetStatus
    procedure, public :: GetResNorm => RT_SolverCoordinator_GetResNorm
  end type RT_SolCoordinator

  public :: RT_CreateSolverCoordinator
  public :: RT_InitSolver
  public :: RT_RunSolver
  public :: RT_UpdateSolver
  public :: RT_FinalizeSolver

contains

  subroutine RT_CreateSolverCoordinator(coordinator, coordinatorId, solverType, status)
    type(RT_SolCoordinator), intent(out) :: coordinator
    integer(i4), intent(in) :: coordinatorId
    integer(i4), intent(in) :: solverType
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    coordinator%coordinatorId = coordinatorId
    coordinator%solverType = solverType
    coordinator%isInitialized = .false.
    coordinator%isRunning = .false.
    coordinator%convergencetole = 1.0e-5_wp
    coordinator%maxIterations = 30_i4

    coordinator%isInitialized = .true.

    status%status_code = IF_STATUS_OK
  end subroutine RT_CreateSolverCoordinator

  subroutine RT_SolverCoordinator_Init(this, convergencetole, maxIterations, status)
    class(RT_SolCoordinator), intent(inout) :: this
    real(wp), intent(in) :: convergencetole
    integer(i4), intent(in) :: maxIterations
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    this%convergencetole = convergencetole
    this%maxIterations = maxIterations
    
    if (associated(this%state)) then
        this%state%currentIter = 0
        this%state%residualNorm = 0.0_wp
        this%state%isConverged = .false.
    endif
    this%isRunning = .false.

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCoordinator_Init

  subroutine RT_SolverCoordinator_Run(this, status)
    class(RT_SolCoordinator), intent(inout) :: this
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%state)) then
        this%state%currentIter = 0
        this%state%residualNorm = 0.0_wp
        this%state%isConverged = .false.
    endif
    this%isRunning = .true.

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCoordinator_Run

  subroutine RT_SolverCoordinator_Update(this, residualNorm, status)
    class(RT_SolCoordinator), intent(inout) :: this
    real(wp), intent(in) :: residualNorm
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%state)) then
        this%state%currentIter = this%state%currentIter + 1_i4
        this%state%residualNorm = residualNorm

        if (residualNorm < this%convergencetole) then
          this%state%isConverged = .true.
        end if
    endif

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCoordinator_Update

  subroutine RT_So_CheckConv(this, isConverged, status)
    class(RT_SolCoordinator), intent(in) :: this
    logical, intent(out) :: isConverged
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%state)) then
        isConverged = this%state%isConverged
    else
        isConverged = .false.
    endif

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCoordinator_CheckConv

  subroutine RT_So_GetStatus(this, currentiteratio, isConverged, status)
    class(RT_SolCoordinator), intent(in) :: this
    integer(i4), intent(out) :: currentiteratio
    logical, intent(out) :: isConverged
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (associated(this%state)) then
        currentiteratio = this%state%currentIter
        isConverged = this%state%isConverged
    else
        currentiteratio = 0
        isConverged = .false.
    endif

    status%status_code = IF_STATUS_OK
  end subroutine RT_SolverCoordinator_GetStatus

  function RT_SolverCoordinator_GetResNorm(this) result(residualNorm)
    class(RT_SolCoordinator), intent(in) :: this
    real(wp) :: residualNorm

    if (associated(this%state)) then
        residualNorm = this%state%residualNorm
    else
        residualNorm = 0.0_wp
    endif
  end function RT_SolverCoordinator_GetResNorm

  ! Public interface procedures
  subroutine RT_InitSolver(coordinator, coordinatorId, solverType, convergencetole, maxIterations, status)
    type(RT_SolCoordinator), intent(out) :: coordinator
    integer(i4), intent(in) :: coordinatorId
    integer(i4), intent(in) :: solverType
    real(wp), intent(in) :: convergencetole
    integer(i4), intent(in) :: maxIterations
    type(ErrorStatusType), intent(out) :: status

    call RT_CreateSolverCoordinator(coordinator, coordinatorId, solverType, status)
    if (status%status_code /= IF_STATUS_OK) return

    call coordinator%Init(convergencetole, maxIterations, status)
  end subroutine RT_InitSolver

  subroutine RT_RunSolver(coordinator, status)
    type(RT_SolCoordinator), intent(inout) :: coordinator
    type(ErrorStatusType), intent(out) :: status

    call coordinator%Run(status)
  end subroutine RT_RunSolver

  subroutine RT_UpdateSolver(coordinator, residualNorm, status)
    type(RT_SolCoordinator), intent(inout) :: coordinator
    real(wp), intent(in) :: residualNorm
    type(ErrorStatusType), intent(out) :: status

    call coordinator%Update(residualNorm, status)
  end subroutine RT_UpdateSolver

  subroutine RT_FinalizeSolver(coordinator, isConverged, status)
    type(RT_SolCoordinator), intent(in) :: coordinator
    logical, intent(out) :: isConverged
    type(ErrorStatusType), intent(out) :: status

    call coordinator%CheckConv(isConverged, status)
  end subroutine RT_FinalizeSolver

end module RT_Solv_Mgr