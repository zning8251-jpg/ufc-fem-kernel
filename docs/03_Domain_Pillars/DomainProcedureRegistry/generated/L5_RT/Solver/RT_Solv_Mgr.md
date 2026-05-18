# `RT_Solv_Mgr.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Solv_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Mgr`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_AssemStaticArgs` (lines 264–284)

```fortran
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
```

### `RT_Sol_In` (lines 310–344)

```fortran
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
```

### `RT_Sol_Ite` (lines 349–387)

```fortran
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
```

### `RT_Sol_Ctx_Init_In` (lines 4839–4841)

```fortran
  type, public :: RT_Sol_Ctx_Init_In
    ! No input parameters
  end type RT_Sol_Ctx_Init_In
```

### `RT_Sol_Ctx_Init_Out` (lines 4842–4844)

```fortran
  type, public :: RT_Sol_Ctx_Init_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Init_Out
```

### `RT_Sol_Ctx_Destroy_In` (lines 4847–4849)

```fortran
  type, public :: RT_Sol_Ctx_Destroy_In
    ! No input parameters
  end type RT_Sol_Ctx_Destroy_In
```

### `RT_Sol_Ctx_Destroy_Out` (lines 4850–4852)

```fortran
  type, public :: RT_Sol_Ctx_Destroy_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Destroy_Out
```

### `RT_Sol_Ctx_Reset_In` (lines 4855–4857)

```fortran
  type, public :: RT_Sol_Ctx_Reset_In
    ! No input parameters
  end type RT_Sol_Ctx_Reset_In
```

### `RT_Sol_Ctx_Reset_Out` (lines 4858–4860)

```fortran
  type, public :: RT_Sol_Ctx_Reset_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Reset_Out
```

### `RT_Sol_Ctx_GetStatus_In` (lines 4863–4865)

```fortran
  type, public :: RT_Sol_Ctx_GetStatus_In
    ! No input parameters
  end type RT_Sol_Ctx_GetStatus_In
```

### `RT_Sol_Ctx_GetStatus_Out` (lines 4866–4868)

```fortran
  type, public :: RT_Sol_Ctx_GetStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetStatus_Out
```

### `RT_Sol_Ctx_SetStatus_In` (lines 4871–4873)

```fortran
  type, public :: RT_Sol_Ctx_SetStatus_In
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_SetStatus_In
```

### `RT_Sol_Ctx_SetStatus_Out` (lines 4874–4876)

```fortran
  type, public :: RT_Sol_Ctx_SetStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_SetStatus_Out
```

### `RT_Sol_Ctx_ClearStatus_In` (lines 4879–4881)

```fortran
  type, public :: RT_Sol_Ctx_ClearStatus_In
    ! No input parameters
  end type RT_Sol_Ctx_ClearStatus_In
```

### `RT_Sol_Ctx_ClearStatus_Out` (lines 4882–4884)

```fortran
  type, public :: RT_Sol_Ctx_ClearStatus_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_ClearStatus_Out
```

### `RT_Sol_Ctx_IsOK_In` (lines 4887–4889)

```fortran
  type, public :: RT_Sol_Ctx_IsOK_In
    ! No input parameters
  end type RT_Sol_Ctx_IsOK_In
```

### `RT_Sol_Ctx_IsOK_Out` (lines 4890–4893)

```fortran
  type, public :: RT_Sol_Ctx_IsOK_Out
    logical :: is_ok
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_IsOK_Out
```

### `RT_Sol_Ctx_IsError_In` (lines 4896–4898)

```fortran
  type, public :: RT_Sol_Ctx_IsError_In
    ! No input parameters
  end type RT_Sol_Ctx_IsError_In
```

### `RT_Sol_Ctx_IsError_Out` (lines 4899–4902)

```fortran
  type, public :: RT_Sol_Ctx_IsError_Out
    logical :: is_error
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_IsError_Out
```

### `RT_Sol_Ctx_Bind_In` (lines 4905–4924)

```fortran
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
```

### `RT_Sol_Ctx_Bind_Out` (lines 4925–4927)

```fortran
  type, public :: RT_Sol_Ctx_Bind_Out
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Bind_Out
```

### `RT_Sol_Ctx_Valid_In` (lines 4930–4932)

```fortran
  type, public :: RT_Sol_Ctx_Valid_In
    ! No input parameters
  end type RT_Sol_Ctx_Valid_In
```

### `RT_Sol_Ctx_Valid_Out` (lines 4933–4936)

```fortran
  type, public :: RT_Sol_Ctx_Valid_Out
    logical :: is_valid
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_Valid_Out
```

### `RT_Sol_Ctx_GetModel_In` (lines 4939–4941)

```fortran
  type, public :: RT_Sol_Ctx_GetModel_In
    ! No input parameters
  end type RT_Sol_Ctx_GetModel_In
```

### `RT_Sol_Ctx_GetModel_Out` (lines 4942–4945)

```fortran
  type, public :: RT_Sol_Ctx_GetModel_Out
    type(UF_Model), pointer :: model
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetModel_Out
```

### `RT_Sol_Ctx_GetStep_In` (lines 4948–4950)

```fortran
  type, public :: RT_Sol_Ctx_GetStep_In
    ! No input parameters
  end type RT_Sol_Ctx_GetStep_In
```

### `RT_Sol_Ctx_GetStep_Out` (lines 4951–4954)

```fortran
  type, public :: RT_Sol_Ctx_GetStep_Out
    type(UF_AnalysisStep), pointer :: step
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetStep_Out
```

### `RT_Sol_Ctx_GetSolver_In` (lines 4957–4959)

```fortran
  type, public :: RT_Sol_Ctx_GetSolver_In
    ! No input parameters
  end type RT_Sol_Ctx_GetSolver_In
```

### `RT_Sol_Ctx_GetSolver_Out` (lines 4960–4963)

```fortran
  type, public :: RT_Sol_Ctx_GetSolver_Out
    type(RT_Sol_Cfg), pointer :: solver
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetSolver_Out
```

### `RT_Sol_Ctx_GetSolverState_In` (lines 4966–4968)

```fortran
  type, public :: RT_Sol_Ctx_GetSolverState_In
    ! No input parameters
  end type RT_Sol_Ctx_GetSolverState_In
```

### `RT_Sol_Ctx_GetSolverState_Out` (lines 4969–4972)

```fortran
  type, public :: RT_Sol_Ctx_GetSolverState_Out
    type(RT_Sol_State), pointer :: solver_state
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetSolverState_Out
```

### `RT_Sol_Ctx_GetGlobalState_In` (lines 4975–4977)

```fortran
  type, public :: RT_Sol_Ctx_GetGlobalState_In
    ! No input parameters
  end type RT_Sol_Ctx_GetGlobalState_In
```

### `RT_Sol_Ctx_GetGlobalState_Out` (lines 4978–4981)

```fortran
  type, public :: RT_Sol_Ctx_GetGlobalState_Out
    type(GlobalState), pointer :: globalState
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetGlobalState_Out
```

### `RT_Sol_Ctx_GetNodeStates_In` (lines 4984–4986)

```fortran
  type, public :: RT_Sol_Ctx_GetNodeStates_In
    ! No input parameters
  end type RT_Sol_Ctx_GetNodeStates_In
```

### `RT_Sol_Ctx_GetNodeStates_Out` (lines 4987–4990)

```fortran
  type, public :: RT_Sol_Ctx_GetNodeStates_Out
    type(NodeState), pointer :: nodeStates(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetNodeStates_Out
```

### `RT_Sol_Ctx_GetElemStates_In` (lines 4993–4995)

```fortran
  type, public :: RT_Sol_Ctx_GetElemStates_In
    ! No input parameters
  end type RT_Sol_Ctx_GetElemStates_In
```

### `RT_Sol_Ctx_GetElemStates_Out` (lines 4996–4999)

```fortran
  type, public :: RT_Sol_Ctx_GetElemStates_Out
    type(ElemState), pointer :: elemStates(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetElemStates_Out
```

### `RT_Sol_Ctx_GetDofMap_In` (lines 5002–5004)

```fortran
  type, public :: RT_Sol_Ctx_GetDofMap_In
    ! No input parameters
  end type RT_Sol_Ctx_GetDofMap_In
```

### `RT_Sol_Ctx_GetDofMap_Out` (lines 5005–5008)

```fortran
  type, public :: RT_Sol_Ctx_GetDofMap_Out
    type(RT_Sol_DofMap), pointer :: dofMap
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetDofMap_Out
```

### `RT_Sol_Ctx_GetTws_In` (lines 5011–5013)

```fortran
  type, public :: RT_Sol_Ctx_GetTws_In
    ! No input parameters
  end type RT_Sol_Ctx_GetTws_In
```

### `RT_Sol_Ctx_GetTws_Out` (lines 5014–5017)

```fortran
  type, public :: RT_Sol_Ctx_GetTws_Out
    type(ThreadWS), pointer :: tws(:)
    type(ErrorStatusType) :: status
  end type RT_Sol_Ctx_GetTws_Out
```

### `RT_SolverRes` (lines 5852–5874)

```fortran
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
```

### `RT_SolverSys` (lines 5879–5905)

```fortran
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
```

### `RT_SolverSys_Init_In` (lines 5911–5913)

```fortran
  type, public :: RT_SolverSys_Init_In
    type(RT_SolverCfg), optional :: config  ! Solver configuration (optional)
  end type RT_SolverSys_Init_In
```

### `RT_SolverSys_Init_Out` (lines 5914–5916)

```fortran
  type, public :: RT_SolverSys_Init_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Init_Out
```

### `RT_SolverSys_Final_In` (lines 5919–5921)

```fortran
  type, public :: RT_SolverSys_Final_In
    ! No input parameters
  end type RT_SolverSys_Final_In
```

### `RT_SolverSys_Final_Out` (lines 5922–5924)

```fortran
  type, public :: RT_SolverSys_Final_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Final_Out
```

### `RT_SolverSys_Cfg_In` (lines 5927–5929)

```fortran
  type, public :: RT_SolverSys_Cfg_In
    type(RT_SolverCfg) :: config  ! Solver configuration
  end type RT_SolverSys_Cfg_In
```

### `RT_SolverSys_Cfg_Out` (lines 5930–5932)

```fortran
  type, public :: RT_SolverSys_Cfg_Out
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Cfg_Out
```

### `RT_SolverSys_Solv_In` (lines 5935–5937)

```fortran
  type, public :: RT_SolverSys_Solv_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_Solv_In
```

### `RT_SolverSys_Solv_Out` (lines 5938–5941)

```fortran
  type, public :: RT_SolverSys_Solv_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_Solv_Out
```

### `RT_SolverSys_SolveLin_In` (lines 5944–5946)

```fortran
  type, public :: RT_SolverSys_SolveLin_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_SolveLin_In
```

### `RT_SolverSys_SolveLin_Out` (lines 5947–5950)

```fortran
  type, public :: RT_SolverSys_SolveLin_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_SolveLin_Out
```

### `RT_SolverSys_SolveNonlin_In` (lines 5953–5955)

```fortran
  type, public :: RT_SolverSys_SolveNonlin_In
    ! No input parameters (uses object state)
  end type RT_SolverSys_SolveNonlin_In
```

### `RT_SolverSys_SolveNonlin_Out` (lines 5956–5959)

```fortran
  type, public :: RT_SolverSys_SolveNonlin_Out
    type(RT_SolverRes) :: result  ! Solver result
    type(ErrorStatusType) :: status
  end type RT_SolverSys_SolveNonlin_Out
```

### `RT_SolverCfg_SetNR_In` (lines 6266–6269)

```fortran
  type, public :: RT_SolverCfg_SetNR_In
    integer(i4), optional :: max_iter  ! Maximum iterations
    real(wp), optional :: tol  ! Convergence tolerance
  end type RT_SolverCfg_SetNR_In
```

### `RT_SolverCfg_SetNR_Out` (lines 6270–6272)

```fortran
  type, public :: RT_SolverCfg_SetNR_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetNR_Out
```

### `RT_SolverCfg_SetModNR_In` (lines 6275–6278)

```fortran
  type, public :: RT_SolverCfg_SetModNR_In
    integer(i4), optional :: max_iter  ! Maximum iterations
    real(wp), optional :: tol  ! Convergence tolerance
  end type RT_SolverCfg_SetModNR_In
```

### `RT_SolverCfg_SetModNR_Out` (lines 6279–6281)

```fortran
  type, public :: RT_SolverCfg_SetModNR_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetModNR_Out
```

### `RT_SolverCfg_SetLBFGS_In` (lines 6284–6287)

```fortran
  type, public :: RT_SolverCfg_SetLBFGS_In
    integer(i4), optional :: memory  ! LBFGS memory size
    real(wp), optional :: tol  ! LBFGS tolerance
  end type RT_SolverCfg_SetLBFGS_In
```

### `RT_SolverCfg_SetLBFGS_Out` (lines 6288–6290)

```fortran
  type, public :: RT_SolverCfg_SetLBFGS_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetLBFGS_Out
```

### `RT_SolverCfg_SetArcLen_In` (lines 6293–6295)

```fortran
  type, public :: RT_SolverCfg_SetArcLen_In
    real(wp) :: parameter  ! Arc-length parameter
  end type RT_SolverCfg_SetArcLen_In
```

### `RT_SolverCfg_SetArcLen_Out` (lines 6296–6298)

```fortran
  type, public :: RT_SolverCfg_SetArcLen_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetArcLen_Out
```

### `RT_SolverCfg_SetLinSolv_In` (lines 6301–6303)

```fortran
  type, public :: RT_SolverCfg_SetLinSolv_In
    integer(i4) :: solver_type  ! Linear solver type
  end type RT_SolverCfg_SetLinSolv_In
```

### `RT_SolverCfg_SetLinSolv_Out` (lines 6304–6306)

```fortran
  type, public :: RT_SolverCfg_SetLinSolv_Out
    type(ErrorStatusType) :: status
  end type RT_SolverCfg_SetLinSolv_Out
```

### `RT_SolverRes_IsConv_In` (lines 6312–6314)

```fortran
  type, public :: RT_SolverRes_IsConv_In
    ! No input parameters
  end type RT_SolverRes_IsConv_In
```

### `RT_SolverRes_IsConv_Out` (lines 6315–6318)

```fortran
  type, public :: RT_SolverRes_IsConv_Out
    logical :: converged
    type(ErrorStatusType) :: status
  end type RT_SolverRes_IsConv_Out
```

### `RT_SolverRes_IsFail_In` (lines 6321–6323)

```fortran
  type, public :: RT_SolverRes_IsFail_In
    ! No input parameters
  end type RT_SolverRes_IsFail_In
```

### `RT_SolverRes_IsFail_Out` (lines 6324–6327)

```fortran
  type, public :: RT_SolverRes_IsFail_Out
    logical :: failure
    type(ErrorStatusType) :: status
  end type RT_SolverRes_IsFail_Out
```

### `RT_SolverRes_GetSum_In` (lines 6330–6332)

```fortran
  type, public :: RT_SolverRes_GetSum_In
    ! No input parameters
  end type RT_SolverRes_GetSum_In
```

### `RT_SolverRes_GetSum_Out` (lines 6333–6336)

```fortran
  type, public :: RT_SolverRes_GetSum_Out
    character(len=512) :: summary
    type(ErrorStatusType) :: status
  end type RT_SolverRes_GetSum_Out
```

### `RT_SolCoordinator` (lines 7622–7637)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_SolStatus_Upd` | 396 | `subroutine RT_SolStatus_Upd(this, statusCode, statusName)` |
| SUBROUTINE | `RT_SolStatus_SetMsg` | 422 | `subroutine RT_SolStatus_SetMsg(this, message)` |
| SUBROUTINE | `RT_SolIncMgr_Init` | 431 | `subroutine RT_SolIncMgr_Init(this, id, nIncrements, totalTime, &` |
| SUBROUTINE | `RT_SolIncMgr_RunInc` | 500 | `subroutine RT_SolIncMgr_RunInc(this, incIndex, status)` |
| SUBROUTINE | `RT_SolIncMgr_RunAll` | 563 | `subroutine RT_SolIncMgr_RunAll(this, status)` |
| FUNCTION | `RT_SolIncMgr_GetStatus` | 598 | `function RT_SolIncMgr_GetStatus(this) result(status)` |
| FUNCTION | `RT_SolIncMgr_GetCurInc` | 604 | `function RT_SolIncMgr_GetCurInc(this) result(incIndex)` |
| FUNCTION | `RT_SolIncMgr_GetInc` | 610 | `function RT_SolIncMgr_GetInc(this, incIndex) result(inc)` |
| SUBROUTINE | `RT_SolIncMgr_Cleanup` | 620 | `subroutine RT_SolIncMgr_Cleanup(this)` |
| SUBROUTINE | `RT_SolIterMgr_Init` | 636 | `subroutine RT_SolIterMgr_Init(this, incrementId, id, &` |
| SUBROUTINE | `RT_SolIterMgr_RunIter` | 698 | `subroutine RT_SolIterMgr_RunIter(this, iterIndex, residualNorm, dispNorm, status)` |
| SUBROUTINE | `RT_SolIterMgr_RunAll` | 735 | `subroutine RT_SolIterMgr_RunAll(this, status)` |
| SUBROUTINE | `RT_Sol_NewtonRaphson_Step` | 898 | `subroutine RT_Sol_NewtonRaphson_Step(this, residualNorm, dispNorm, energyNorm, &` |
| SUBROUTINE | `RT_Sol_ModifiedNewton_Step` | 932 | `subroutine RT_Sol_ModifiedNewton_Step(this, residualNorm, dispNorm, energyNorm, &` |
| SUBROUTINE | `RT_Sol_LBFGS_Step` | 980 | `subroutine RT_Sol_LBFGS_Step(this, residualNorm, dispNorm, energyNorm, &` |
| SUBROUTINE | `RT_SolArcLen_Upd` | 1097 | `subroutine RT_SolArcLen_Upd(this, lambda, arc_length, residualNorm, dispNorm, status)` |
| SUBROUTINE | `RT_Sol_LineSearch` | 1152 | `subroutine RT_Sol_LineSearch(this, residualNorm, dispNorm, energyNorm, &` |
| SUBROUTINE | `RT_SolIterMgr_ChkConv` | 1226 | `subroutine RT_SolIterMgr_ChkConv(this, iterState, status)` |
| FUNCTION | `RT_SolIterMgr_GetStatus` | 1243 | `function RT_SolIterMgr_GetStatus(this) result(status)` |
| FUNCTION | `RT_SolIterMgr_GetCurIter` | 1249 | `function RT_SolIterMgr_GetCurIter(this) result(iterIndex)` |
| FUNCTION | `RT_SolIterMgr_GetIter` | 1255 | `function RT_SolIterMgr_GetIter(this, iterIndex) result(iter)` |
| SUBROUTINE | `RT_SolIterMgr_Cleanup` | 1265 | `subroutine RT_SolIterMgr_Cleanup(this)` |
| FUNCTION | `to_string` | 1279 | `function to_string(i) result(s)` |
| SUBROUTINE | `check_nl_Conv` | 1294 | `subroutine check_nl_Conv(solver)` |
| SUBROUTINE | `form_arc_length_system` | 1366 | `subroutine form_arc_length_system(solver, dl, ds)` |
| SUBROUTINE | `so_arc_le_au_system` | 1414 | `subroutine so_arc_le_au_system(solver, dl, ds, status)` |
| SUBROUTINE | `Solv_quadratic_equation` | 1520 | `subroutine Solv_quadratic_equation(a, b, c, one_root, two_roots, root1, root2)` |
| FUNCTION | `select_optimal_root` | 1567 | `function select_optimal_root(root1, root2, solver) result(selected_root)` |
| SUBROUTINE | `update_arc_length_constraint` | 1603 | `subroutine update_arc_length_constraint(solver, ds)` |
| SUBROUTINE | `predict_newmark_Integ` | 1620 | `subroutine predict_newmark_Integ(integrator)` |
| SUBROUTINE | `fo_ef_ne_system` | 1633 | `subroutine fo_ef_ne_system(integrator)` |
| SUBROUTINE | `correct_newmark_Integ` | 1650 | `subroutine correct_newmark_Integ(integrator)` |
| SUBROUTINE | `predict_hht_alpha_Integ` | 1659 | `subroutine predict_hht_alpha_Integ(integrator, alpha_prime)` |
| SUBROUTINE | `form_effective_hht_system` | 1674 | `subroutine form_effective_hht_system(integrator, alpha_prime, beta_prime, gamma_prime)` |
| SUBROUTINE | `correct_hht_alpha_Integ` | 1687 | `subroutine correct_hht_alpha_Integ(integrator, alpha_prime, gamma_prime)` |
| SUBROUTINE | `update_time_Integ_state` | 1696 | `subroutine update_time_Integ_state(integrator)` |
| SUBROUTINE | `RT_TimeInt_Newmark_Dyn` | 1711 | `subroutine RT_TimeInt_Newmark_Dyn(integrator, status)` |
| SUBROUTINE | `RT_TimeInt_HHT_Alpha_Dyn` | 1759 | `subroutine RT_TimeInt_HHT_Alpha_Dyn(integrator, alpha, status)` |
| SUBROUTINE | `UF_LogIncrement_NRLinear` | 1833 | `subroutine UF_LogIncrement_NRLinear(stepType, globalState)` |
| SUBROUTINE | `UF_Assem_Static` | 1889 | `subroutine UF_Assem_Static(model, step, globalState, dofMap, nodeStates, elemStates, K_global, R_int, tws, ierr, usecontactmanag, &` |
| SUBROUTINE | `UF_NewtonRaphson_Ctx` | 2160 | `subroutine UF_NewtonRaphson_Ctx(ctx)` |
| SUBROUTINE | `Calc_residual_state` | 2270 | `subroutine Calc_residual_state(solver_state_in, status_in)` |
| SUBROUTINE | `Calc_tangent_state` | 2321 | `subroutine Calc_tangent_state(solver_state_in, status_in)` |
| SUBROUTINE | `solve_line_state` | 2377 | `subroutine solve_line_state(solver_state_in, status_in)` |
| SUBROUTINE | `UF_NewtonRaphson` | 2415 | `subroutine UF_NewtonRaphson(model, step, solver, solver_state, &` |
| SUBROUTINE | `Calc_residual_state` | 2534 | `subroutine Calc_residual_state(solver_state_in, status_in)` |
| SUBROUTINE | `Calc_tangent_state` | 2585 | `subroutine Calc_tangent_state(solver_state_in, status_in)` |
| SUBROUTINE | `solve_line_state` | 2641 | `subroutine solve_line_state(solver_state_in, status_in)` |
| SUBROUTINE | `ScatterToSparse_Multifield` | 2675 | `subroutine ScatterToSparse_Multifield(Element, dofMap, Ke, Re, triplets, R)` |
| SUBROUTINE | `ScatterToSparse_Multifield_FromConn` | 2740 | `subroutine ScatterToSparse_Multifield_FromConn(conn, npe, dofMap, Ke, Re, triplets, R)` |
| SUBROUTINE | `ApplyBoundaryConditions` | 2816 | `subroutine ApplyBoundaryConditions(dofMap, K, R, nodeStates)` |
| SUBROUTINE | `UF_UpdateNodeSolutionFromU` | 2908 | `subroutine UF_UpdateNodeSolutionFromU(nodeStates, dofMap, u)` |
| SUBROUTINE | `UF_NewtonRaphsonDynamic` | 2980 | `subroutine UF_NewtonRaphsonDynamic(model, step, solver, globalState, nodeStates, elemStates, tws, converged)` |
| SUBROUTINE | `UF_ExplicitDynamicsStep` | 3245 | `subroutine UF_ExplicitDynamicsStep(model, step, solver, globalState, nodeStates, elemStates, converged)` |
| SUBROUTINE | `UpdateNodalSolution` | 3330 | `subroutine UpdateNodalSolution(nodeStates, dofMap, du)` |
| SUBROUTINE | `UF_Assem` | 3372 | `subroutine UF_Assem(model, globalState, dofMap, nodeStates, elemStates, triplets, R)` |
| SUBROUTINE | `addElementContribution` | 3385 | `subroutine addElementContribution(Element, Ctx, Ke, Re)` |
| SUBROUTINE | `UF_BuildLumpedMassVector` | 3399 | `subroutine UF_BuildLumpedMassVector(model, globalState, dofMap, nodeStates, elemStates, mass)` |
| SUBROUTINE | `BuildElementContext` | 3579 | `subroutine BuildElementContext(part, Element, nodeStates, globalState, Ctx)` |
| SUBROUTINE | `BuildElementContextFromMesh` | 3869 | `subroutine BuildElementContextFromMesh(elem_id, arg_conn, elem_type_id, nodeStates, globalState, Ctx)` |
| SUBROUTINE | `GatherNodalU` | 3951 | `subroutine GatherNodalU(nodeStates, dofMap, u)` |
| SUBROUTINE | `NewmarkPredictor` | 3982 | `subroutine NewmarkPredictor(nodeStates, dofMap, dt, beta, gamma, u_pred)` |
| SUBROUTINE | `AddInertiaTerms` | 4010 | `subroutine AddInertiaTerms(triplets, R, mass, u, u_pred, a0)` |
| SUBROUTINE | `NewmarkUpdateKinematics` | 4029 | `subroutine NewmarkUpdateKinematics(nodeStates, dt, beta, gamma, u_pred)` |
| SUBROUTINE | `ExplicitPredictorVerlet` | 4053 | `subroutine ExplicitPredictorVerlet(nodeStates, dt)` |
| SUBROUTINE | `UF_AssemblyInternalOnly` | 4072 | `subroutine UF_AssemblyInternalOnly(model, globalState, dofMap, nodeStates, elemStates, R)` |
| SUBROUTINE | `ScatterInternalToR` | 4205 | `subroutine ScatterInternalToR(Element, dofMap, Re, R)` |
| SUBROUTINE | `ScatterInternalToR_FromConn` | 4235 | `subroutine ScatterInternalToR_FromConn(conn, npe, dofMap, Re, R)` |
| SUBROUTINE | `ApplyBoundaryConditionsDynam` | 4270 | `subroutine ApplyBoundaryConditionsDynam(model, step, dofMap, time, K, R, nodeStates)` |
| SUBROUTINE | `ApplySymmetryAtNode` | 4336 | `subroutine ApplySymmetryAtNode(nodeIdLocal, baseDof, valLocal)` |
| SUBROUTINE | `ApplyNodeBC` | 4356 | `subroutine ApplyNodeBC(nodeIdLocal, dofLocal, valLocal)` |
| SUBROUTINE | `ApplyBoundaryConditionsExpli` | 4401 | `subroutine ApplyBoundaryConditionsExpli(model, step, dofMap, time, nodeStates, R)` |
| SUBROUTINE | `ApplySymmetryBCExplicit` | 4497 | `subroutine ApplySymmetryBCExplicit(nodeIdLocal, baseDof, valLocal)` |
| SUBROUTINE | `ApplyNodeBCExplicit` | 4517 | `subroutine ApplyNodeBCExplicit(nodeIdLocal, dofLocal, valLocal)` |
| SUBROUTINE | `ApplyVelocityBCExplicit` | 4544 | `subroutine ApplyVelocityBCExplicit(nodeIdLocal, dofLocal, valLocal)` |
| SUBROUTINE | `ApplyAccelerationBCExplicit` | 4566 | `subroutine ApplyAccelerationBCExplicit(nodeIdLocal, dofLocal, valLocal)` |
| SUBROUTINE | `ExplicitUpdateVerlet` | 4583 | `subroutine ExplicitUpdateVerlet(nodeStates, dofMap, dt, mass, R)` |
| SUBROUTINE | `UF_ExplicitUpdateMultiField` | 4635 | `subroutine UF_ExplicitUpdateMultiField(model, step, solver, globalState, dofMap, nodeStates, R)` |
| SUBROUTINE | `UF_NewtonRaphson_State` | 4706 | `subroutine UF_NewtonRaphson_State(model, step, solver, solver_state, &` |
| SUBROUTINE | `RT_Sol_DofMap_Final` | 4737 | `subroutine RT_Sol_DofMap_Final(this)` |
| SUBROUTINE | `RT_Sol_Ctx_Init_Structured` | 5024 | `subroutine RT_Sol_Ctx_Init_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_Destroy_Structured` | 5049 | `subroutine RT_Sol_Ctx_Destroy_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_Reset_Structured` | 5097 | `subroutine RT_Sol_Ctx_Reset_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetStatus_Structured` | 5120 | `subroutine RT_Sol_Ctx_GetStatus_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_SetStatus_Structured` | 5146 | `subroutine RT_Sol_Ctx_SetStatus_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_ClearStatus_Structured` | 5168 | `subroutine RT_Sol_Ctx_ClearStatus_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_IsOK_Structured` | 5190 | `subroutine RT_Sol_Ctx_IsOK_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_IsError_Structured` | 5213 | `subroutine RT_Sol_Ctx_IsError_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_Bind_Structured` | 5236 | `subroutine RT_Sol_Ctx_Bind_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_Valid_Structured` | 5296 | `subroutine RT_Sol_Ctx_Valid_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetModel_Structured` | 5378 | `subroutine RT_Sol_Ctx_GetModel_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetStep_Structured` | 5401 | `subroutine RT_Sol_Ctx_GetStep_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetSolver_Structured` | 5424 | `subroutine RT_Sol_Ctx_GetSolver_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetSolverState_Structured` | 5447 | `subroutine RT_Sol_Ctx_GetSolverState_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetGlobalState_Structured` | 5470 | `subroutine RT_Sol_Ctx_GetGlobalState_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetNodeStates_Structured` | 5493 | `subroutine RT_Sol_Ctx_GetNodeStates_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetElemStates_Structured` | 5516 | `subroutine RT_Sol_Ctx_GetElemStates_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetDofMap_Structured` | 5539 | `subroutine RT_Sol_Ctx_GetDofMap_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_GetTws_Structured` | 5562 | `subroutine RT_Sol_Ctx_GetTws_Structured(ctx, in, out)` |
| SUBROUTINE | `RT_Sol_Ctx_Init` | 5589 | `subroutine RT_Sol_Ctx_Init(this)` |
| SUBROUTINE | `RT_Sol_Ctx_Destroy` | 5598 | `subroutine RT_Sol_Ctx_Destroy(this)` |
| SUBROUTINE | `RT_Sol_Ctx_Reset` | 5627 | `subroutine RT_Sol_Ctx_Reset(this)` |
| FUNCTION | `RT_Sol_Ctx_GetStatus` | 5634 | `function RT_Sol_Ctx_GetStatus(this) result(status)` |
| SUBROUTINE | `RT_Sol_Ctx_SetStatus` | 5647 | `subroutine RT_Sol_Ctx_SetStatus(this, status)` |
| SUBROUTINE | `RT_Sol_Ctx_ClearStatus` | 5654 | `subroutine RT_Sol_Ctx_ClearStatus(this)` |
| FUNCTION | `RT_Sol_Ctx_IsOK` | 5660 | `function RT_Sol_Ctx_IsOK(this) result(is_ok)` |
| FUNCTION | `RT_Sol_Ctx_IsError` | 5667 | `function RT_Sol_Ctx_IsError(this) result(is_error)` |
| SUBROUTINE | `RT_Sol_Ctx_Bind` | 5674 | `subroutine RT_Sol_Ctx_Bind(this, model, step, solver, solver_state, &` |
| FUNCTION | `RT_Sol_Ctx_Valid` | 5723 | `function RT_Sol_Ctx_Valid(this) result(is_valid)` |
| FUNCTION | `RT_Sol_Ctx_GetModel` | 5785 | `function RT_Sol_Ctx_GetModel(this) result(model)` |
| FUNCTION | `RT_Sol_Ctx_GetStep` | 5791 | `function RT_Sol_Ctx_GetStep(this) result(step)` |
| FUNCTION | `RT_Sol_Ctx_GetSolver` | 5797 | `function RT_Sol_Ctx_GetSolver(this) result(solver)` |
| FUNCTION | `RT_Sol_Ctx_GetSolverState` | 5803 | `function RT_Sol_Ctx_GetSolverState(this) result(solver_state)` |
| FUNCTION | `RT_Sol_Ctx_GetGlobalState` | 5809 | `function RT_Sol_Ctx_GetGlobalState(this) result(globalState)` |
| FUNCTION | `RT_Sol_Ctx_GetNodeStates` | 5815 | `function RT_Sol_Ctx_GetNodeStates(this) result(nodeStates)` |
| FUNCTION | `RT_Sol_Ctx_GetElemStates` | 5821 | `function RT_Sol_Ctx_GetElemStates(this) result(elemStates)` |
| FUNCTION | `RT_Sol_Ctx_GetDofMap` | 5827 | `function RT_Sol_Ctx_GetDofMap(this) result(dofMap)` |
| FUNCTION | `RT_Sol_Ctx_GetTws` | 5833 | `function RT_Sol_Ctx_GetTws(this) result(tws)` |
| SUBROUTINE | `RT_SolverSys_Init_Structured` | 5966 | `subroutine RT_SolverSys_Init_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverSys_Final_Structured` | 6001 | `subroutine RT_SolverSys_Final_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverSys_Cfg_Structured` | 6028 | `subroutine RT_SolverSys_Cfg_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverSys_Solv_Structured` | 6062 | `subroutine RT_SolverSys_Solv_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverSys_SolveLin_Structured` | 6129 | `subroutine RT_SolverSys_SolveLin_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverSys_SolveNonlin_Structured` | 6192 | `subroutine RT_SolverSys_SolveNonlin_Structured(solverSys, in, out)` |
| SUBROUTINE | `RT_SolverCfg_Init` | 6342 | `subroutine RT_SolverCfg_Init(this)` |
| SUBROUTINE | `RT_SolverCfg_Valid` | 6361 | `subroutine RT_SolverCfg_Valid(this, status)` |
| SUBROUTINE | `RT_SolverCfg_SetNR_Structured` | 6411 | `subroutine RT_SolverCfg_SetNR_Structured(cfg, in, out)` |
| SUBROUTINE | `RT_SolverCfg_SetModNR_Structured` | 6439 | `subroutine RT_SolverCfg_SetModNR_Structured(cfg, in, out)` |
| SUBROUTINE | `RT_SolverCfg_SetLBFGS_Structured` | 6467 | `subroutine RT_SolverCfg_SetLBFGS_Structured(cfg, in, out)` |
| SUBROUTINE | `RT_SolverCfg_SetArcLen_Structured` | 6494 | `subroutine RT_SolverCfg_SetArcLen_Structured(cfg, in, out)` |
| SUBROUTINE | `RT_SolverCfg_SetLinSolv_Structured` | 6522 | `subroutine RT_SolverCfg_SetLinSolv_Structured(cfg, in, out)` |
| SUBROUTINE | `RT_SolverCfg_SetNR` | 6549 | `subroutine RT_SolverCfg_SetNR(this, max_iter, tol)` |
| SUBROUTINE | `RT_SolverCfg_SetModNR` | 6563 | `subroutine RT_SolverCfg_SetModNR(this, max_iter, tol)` |
| SUBROUTINE | `RT_SolverCfg_SetLBFGS` | 6577 | `subroutine RT_SolverCfg_SetLBFGS(this, memory, tol)` |
| SUBROUTINE | `RT_SolverCfg_SetArcLen` | 6591 | `subroutine RT_SolverCfg_SetArcLen(this, parameter)` |
| SUBROUTINE | `RT_SolverCfg_SetLinSolv` | 6603 | `subroutine RT_SolverCfg_SetLinSolv(this, solver_type)` |
| SUBROUTINE | `RT_SolverRes_IsConv_Structured` | 6617 | `subroutine RT_SolverRes_IsConv_Structured(res, in, out)` |
| SUBROUTINE | `RT_SolverRes_IsFail_Structured` | 6640 | `subroutine RT_SolverRes_IsFail_Structured(res, in, out)` |
| SUBROUTINE | `RT_SolverRes_GetSum_Structured` | 6665 | `subroutine RT_SolverRes_GetSum_Structured(res, in, out)` |
| FUNCTION | `RT_SolverRes_IsConv` | 6702 | `function RT_SolverRes_IsConv(this) result(converged)` |
| FUNCTION | `RT_SolverRes_IsFail` | 6714 | `function RT_SolverRes_IsFail(this) result(failure)` |
| FUNCTION | `RT_SolverRes_GetSum` | 6726 | `function RT_SolverRes_GetSum(this) result(summary)` |
| FUNCTION | `RT_SolverRes_IsSuccess` | 6738 | `function RT_SolverRes_IsSuccess(this) result(success)` |
| SUBROUTINE | `RT_SolverSys_Init` | 6754 | `subroutine RT_SolverSys_Init(this, config, status)` |
| SUBROUTINE | `RT_SolverSys_Final` | 6770 | `subroutine RT_SolverSys_Final(this, status)` |
| SUBROUTINE | `RT_SolverSys_Cfg` | 6782 | `subroutine RT_SolverSys_Cfg(this, config, status)` |
| SUBROUTINE | `RT_SolverSys_Solv` | 6796 | `subroutine RT_SolverSys_Solv(this, status)` |
| SUBROUTINE | `RT_SolverSys_SolveLin` | 6808 | `subroutine RT_SolverSys_SolveLin(this, status)` |
| SUBROUTINE | `RT_SolverSys_SetLinearSolveCallback` | 6821 | `subroutine RT_SolverSys_SetLinearSolveCallback(this, proc)` |
| SUBROUTINE | `RT_SolverSys_SolveNonlin` | 6829 | `subroutine RT_SolverSys_SolveNonlin(this, status)` |
| FUNCTION | `RT_SolverSys_GetRes` | 6840 | `function RT_SolverSys_GetRes(this) result(result)` |
| FUNCTION | `RT_SolverSys_GetStatus` | 6847 | `function RT_SolverSys_GetStatus(this) result(status)` |
| FUNCTION | `RT_SolverSys_IsInit` | 6854 | `function RT_SolverSys_IsInit(this) result(is_init)` |
| SUBROUTINE | `RT_SolverSys_SetAI_StepController` | 6861 | `subroutine RT_SolverSys_SetAI_StepController(this, proc)` |
| SUBROUTINE | `RT_SolverSys_SetAI_ConvPredictor` | 6867 | `subroutine RT_SolverSys_SetAI_ConvPredictor(this, proc)` |
| FUNCTION | `RT_SolverSys_IsRunning` | 6874 | `function RT_SolverSys_IsRunning(this) result(running)` |
| SUBROUTINE | `RT_SolverSys_Reset` | 6881 | `subroutine RT_SolverSys_Reset(this, status)` |
| SUBROUTINE | `RT_Rayleigh_BuildDampMat` | 6910 | `subroutine RT_Rayleigh_BuildDampMat(K, mass, settings, C)` |
| SUBROUTINE | `RT_Rayleigh_UpdateMatrix` | 6978 | `subroutine RT_Rayleigh_UpdateMatrix(K, mass, settings)` |
| SUBROUTINE | `RT_PCG_Solv` | 7003 | `subroutine RT_PCG_Solv(A, b, x, tol, maxIter, converged, nIter)` |
| SUBROUTINE | `RT_Eq_SolveFixedLambda` | 7136 | `subroutine RT_Eq_SolveFixedLambda(method, solver_state, &` |
| SUBROUTINE | `Calc_residual_legacy_adapter` | 7597 | `subroutine Calc_residual_legacy_adapter(u_vec, lambda_loc, F_ext_in, R_out, ierr_out)` |
| SUBROUTINE | `RT_CreateSolverCoordinator` | 7647 | `subroutine RT_CreateSolverCoordinator(coordinator, coordinatorId, solverType, status)` |
| SUBROUTINE | `RT_SolverCoordinator_Init` | 7667 | `subroutine RT_SolverCoordinator_Init(this, convergencetole, maxIterations, status)` |
| SUBROUTINE | `RT_SolverCoordinator_Run` | 7688 | `subroutine RT_SolverCoordinator_Run(this, status)` |
| SUBROUTINE | `RT_SolverCoordinator_Update` | 7704 | `subroutine RT_SolverCoordinator_Update(this, residualNorm, status)` |
| SUBROUTINE | `RT_So_CheckConv` | 7723 | `subroutine RT_So_CheckConv(this, isConverged, status)` |
| SUBROUTINE | `RT_So_GetStatus` | 7739 | `subroutine RT_So_GetStatus(this, currentiteratio, isConverged, status)` |
| FUNCTION | `RT_SolverCoordinator_GetResNorm` | 7758 | `function RT_SolverCoordinator_GetResNorm(this) result(residualNorm)` |
| SUBROUTINE | `RT_InitSolver` | 7770 | `subroutine RT_InitSolver(coordinator, coordinatorId, solverType, convergencetole, maxIterations, status)` |
| SUBROUTINE | `RT_RunSolver` | 7784 | `subroutine RT_RunSolver(coordinator, status)` |
| SUBROUTINE | `RT_UpdateSolver` | 7791 | `subroutine RT_UpdateSolver(coordinator, residualNorm, status)` |
| SUBROUTINE | `RT_FinalizeSolver` | 7799 | `subroutine RT_FinalizeSolver(coordinator, isConverged, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
