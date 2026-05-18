# `AP_Job_Mgr.f90`

- **Source**: `L6_AP/Job/AP_Job_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Job_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Job_Mgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Job`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Job`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Job/AP_Job_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Job_Opts` (lines 33–39)

```fortran
  type, public :: AP_Job_Opts
    !! Options for controlling Job execution from user/upper layer
    logical     :: restartEnabled  = .false.
    logical     :: checkOnly       = .false.
    logical     :: postOnly        = .false.
    integer(i4) :: maxSteps        = -1_i4   !! <=0: unlimited steps
  end type AP_Job_Opts
```

### `JobOpts` (lines 41–46)

```fortran
  type, public :: JobOpts
    logical     :: isrestartenable = .false.
    logical     :: isCheckOnly     = .false.
    logical     :: isPostOnly      = .false.
    integer(i4) :: maxSteps        = -1_i4
  end type JobOpts
```

### `AP_Job_Summary` (lines 52–60)

```fortran
  type, public :: AP_Job_Summary
    !! High-level summary of Job execution (simplified from UF_JobStatus)
    integer(i4) :: nStepsTotal     = 0_i4
    integer(i4) :: nStepsCompleted = 0_i4
    logical     :: completed       = .false.
    logical     :: aborted         = .false.
    integer(i4) :: lastErrCode     = 0_i4
    real(wp)    :: progress        = 0.0_wp  !! 0-1, overall progress by step count
  end type AP_Job_Summary
```

### `JobSummary` (lines 62–69)

```fortran
  type, public :: JobSummary
    integer(i4) :: nStepsTotal      = 0_i4
    integer(i4) :: nStepsCompleted  = 0_i4
    logical     :: isCompleted      = .false.
    logical     :: isAborted        = .false.
    integer(i4) :: lastErrorCode    = 0_i4
    real(wp)    :: progress         = 0.0_wp
  end type JobSummary
```

### `AP_Job_Ctx` (lines 93–107)

```fortran
  type, public :: AP_Job_Ctx
    !! Job context: binds description, global state, run options, and step callback
    type(JobDesc),      pointer :: desc       => null()
    type(State_Model),  pointer :: stateModel => null()

    type(AP_Job_Opts)   :: opts
    type(AP_Job_Summary):: summary

    integer(i4)   :: currentStepIdx = 0_i4
    integer(i4)   :: nStepsPlanned  = 0_i4
    logical       :: completed      = .false.
    logical       :: aborted        = .false.

    procedure(AP_Job_StepRunner_Ifc), pointer :: StepRunner => null()
  end type AP_Job_Ctx
```

### `JobCtx` (lines 109–119)

```fortran
  type, public :: JobCtx
    type(JobDesc),      pointer :: desc       => null()
    type(State_Model),  pointer :: stateModel => null()
    type(JobOpts)       :: opts
    type(JobSummary)    :: summary
    integer(i4)         :: current_step_index = 0_i4
    integer(i4)         :: nStepsPlanned      = 0_i4
    logical             :: isCompleted        = .false.
    logical             :: isAborted          = .false.
    procedure(UF_Job_StepRunner_Ifc), pointer :: StepRunner => null()
  end type JobCtx
```

### `AP_Job_InitDesc_In` (lines 125–127)

```fortran
  type, public :: AP_Job_InitDesc_In
    ! No input parameters (uses inout descJob)
  end type AP_Job_InitDesc_In
```

### `AP_Job_InitDesc_Out` (lines 128–130)

```fortran
  type, public :: AP_Job_InitDesc_Out
    type(ErrorStatusType) :: status
  end type AP_Job_InitDesc_Out
```

### `AP_Job_AttachMod_In` (lines 133–135)

```fortran
  type, public :: AP_Job_AttachMod_In
    type(ModelDesc) :: descModel  ! Model description
  end type AP_Job_AttachMod_In
```

### `AP_Job_AttachMod_Out` (lines 136–138)

```fortran
  type, public :: AP_Job_AttachMod_Out
    type(ErrorStatusType) :: status
  end type AP_Job_AttachMod_Out
```

### `AP_Job_AddStep_In` (lines 141–143)

```fortran
  type, public :: AP_Job_AddStep_In
    type(StepDesc) :: descStep  ! Step description
  end type AP_Job_AddStep_In
```

### `AP_Job_AddStep_Out` (lines 144–146)

```fortran
  type, public :: AP_Job_AddStep_Out
    type(ErrorStatusType) :: status
  end type AP_Job_AddStep_Out
```

### `AP_Job_BindCtx_In` (lines 149–154)

```fortran
  type, public :: AP_Job_BindCtx_In
    type(JobDesc), pointer :: descJob  ! Job description (target)
    type(State_Model), pointer :: stateModel  ! Global model state (target)
    type(JobOpts) :: opts  ! Job options
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: stepRunner  ! Step runner callback
  end type AP_Job_BindCtx_In
```

### `AP_Job_BindCtx_Out` (lines 155–157)

```fortran
  type, public :: AP_Job_BindCtx_Out
    type(ErrorStatusType) :: status
  end type AP_Job_BindCtx_Out
```

### `AP_Job_SetOpts_In` (lines 160–162)

```fortran
  type, public :: AP_Job_SetOpts_In
    type(JobOpts) :: opts  ! Job options
  end type AP_Job_SetOpts_In
```

### `AP_Job_SetOpts_Out` (lines 163–165)

```fortran
  type, public :: AP_Job_SetOpts_Out
    type(ErrorStatusType) :: status
  end type AP_Job_SetOpts_Out
```

### `AP_Job_PrepEnv_In` (lines 168–170)

```fortran
  type, public :: AP_Job_PrepEnv_In
    ! No input parameters
  end type AP_Job_PrepEnv_In
```

### `AP_Job_PrepEnv_Out` (lines 171–173)

```fortran
  type, public :: AP_Job_PrepEnv_Out
    type(ErrorStatusType) :: status
  end type AP_Job_PrepEnv_Out
```

### `AP_Job_Run_In` (lines 176–178)

```fortran
  type, public :: AP_Job_Run_In
    ! No input parameters (uses inout ctxJob)
  end type AP_Job_Run_In
```

### `AP_Job_Run_Out` (lines 179–181)

```fortran
  type, public :: AP_Job_Run_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Run_Out
```

### `AP_Job_RunNext_In` (lines 184–186)

```fortran
  type, public :: AP_Job_RunNext_In
    ! No input parameters (uses inout ctxJob)
  end type AP_Job_RunNext_In
```

### `AP_Job_RunNext_Out` (lines 187–189)

```fortran
  type, public :: AP_Job_RunNext_Out
    type(ErrorStatusType) :: status
  end type AP_Job_RunNext_Out
```

### `AP_Job_SaveChk_In` (lines 192–194)

```fortran
  type, public :: AP_Job_SaveChk_In
    ! No input parameters
  end type AP_Job_SaveChk_In
```

### `AP_Job_SaveChk_Out` (lines 195–197)

```fortran
  type, public :: AP_Job_SaveChk_Out
    type(ErrorStatusType) :: status
  end type AP_Job_SaveChk_Out
```

### `AP_Job_LoadChk_In` (lines 200–202)

```fortran
  type, public :: AP_Job_LoadChk_In
    ! No input parameters
  end type AP_Job_LoadChk_In
```

### `AP_Job_LoadChk_Out` (lines 203–205)

```fortran
  type, public :: AP_Job_LoadChk_Out
    type(ErrorStatusType) :: status
  end type AP_Job_LoadChk_Out
```

### `AP_Job_TryRestart_In` (lines 208–210)

```fortran
  type, public :: AP_Job_TryRestart_In
    ! No input parameters
  end type AP_Job_TryRestart_In
```

### `AP_Job_TryRestart_Out` (lines 211–213)

```fortran
  type, public :: AP_Job_TryRestart_Out
    type(ErrorStatusType) :: status
  end type AP_Job_TryRestart_Out
```

### `AP_Job_HandleFail_In` (lines 216–218)

```fortran
  type, public :: AP_Job_HandleFail_In
    integer(i4) :: errorCode  ! Error code
  end type AP_Job_HandleFail_In
```

### `AP_Job_HandleFail_Out` (lines 219–221)

```fortran
  type, public :: AP_Job_HandleFail_Out
    type(ErrorStatusType) :: status
  end type AP_Job_HandleFail_Out
```

### `AP_Job_Final_In` (lines 224–226)

```fortran
  type, public :: AP_Job_Final_In
    ! No input parameters
  end type AP_Job_Final_In
```

### `AP_Job_Final_Out` (lines 227–229)

```fortran
  type, public :: AP_Job_Final_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Final_Out
```

### `AP_Job_BuildSum_In` (lines 232–234)

```fortran
  type, public :: AP_Job_BuildSum_In
    ! No input parameters
  end type AP_Job_BuildSum_In
```

### `AP_Job_BuildSum_Out` (lines 235–238)

```fortran
  type, public :: AP_Job_BuildSum_Out
    type(JobSummary) :: summary  ! Job summary
    type(ErrorStatusType) :: status
  end type AP_Job_BuildSum_Out
```

### `AP_Job_QueryStat_In` (lines 241–243)

```fortran
  type, public :: AP_Job_QueryStat_In
    ! No input parameters
  end type AP_Job_QueryStat_In
```

### `AP_Job_QueryStat_Out` (lines 244–249)

```fortran
  type, public :: AP_Job_QueryStat_Out
    logical :: isCompleted  ! Whether job is completed
    logical :: isAborted  ! Whether job is aborted
    integer(i4) :: current_step_index  ! Current step index
    type(ErrorStatusType) :: status
  end type AP_Job_QueryStat_Out
```

### `AP_Job_Unified_OptionsDefault_In` (lines 252–254)

```fortran
  type, public :: AP_Job_Unified_OptionsDefault_In
    ! No input parameters
  end type AP_Job_Unified_OptionsDefault_In
```

### `AP_Job_Unified_OptionsDefault_Out` (lines 255–258)

```fortran
  type, public :: AP_Job_Unified_OptionsDefault_Out
    type(JobOpts) :: opts  ! Default job options
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_OptionsDefault_Out
```

### `AP_Job_Unified_OptionsValidate_In` (lines 261–263)

```fortran
  type, public :: AP_Job_Unified_OptionsValidate_In
    type(JobOpts) :: opts  ! Job options to validate
  end type AP_Job_Unified_OptionsValidate_In
```

### `AP_Job_Unified_OptionsValidate_Out` (lines 264–267)

```fortran
  type, public :: AP_Job_Unified_OptionsValidate_Out
    logical :: is_valid  ! Whether options are valid
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_OptionsValidate_Out
```

### `AP_Job_Unified_Cfg_In` (lines 270–275)

```fortran
  type, public :: AP_Job_Unified_Cfg_In
    type(JobDesc), pointer :: descJob  ! Job description (target)
    type(State_Model), pointer :: stateModel  ! Global model state (target)
    type(JobOpts) :: opts  ! Job options
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: step_runner  ! Step runner callback
  end type AP_Job_Unified_Cfg_In
```

### `AP_Job_Unified_Cfg_Out` (lines 276–278)

```fortran
  type, public :: AP_Job_Unified_Cfg_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Cfg_Out
```

### `AP_Job_Unified_Checkpoint_In` (lines 281–283)

```fortran
  type, public :: AP_Job_Unified_Checkpoint_In
    character(len=32) :: operation  ! Operation: 'SAVE', 'LOAD', 'TRY_RESTART'
  end type AP_Job_Unified_Checkpoint_In
```

### `AP_Job_Unified_Checkpoint_Out` (lines 284–286)

```fortran
  type, public :: AP_Job_Unified_Checkpoint_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Checkpoint_Out
```

### `AP_Job_Unified_Execute_In` (lines 289–291)

```fortran
  type, public :: AP_Job_Unified_Execute_In
    character(len=32) :: operation  ! Operation: 'run', 'run_next', 'final', 'query'
  end type AP_Job_Unified_Execute_In
```

### `AP_Job_Unified_Execute_Out` (lines 292–295)

```fortran
  type, public :: AP_Job_Unified_Execute_Out
    type(JobSummary), optional :: summary  ! Job summary (for query)
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Execute_Out
```

### `AP_Job_Unified_Query_In` (lines 298–300)

```fortran
  type, public :: AP_Job_Unified_Query_In
    character(len=32) :: operation  ! Operation: 'STATUS', 'SUMMARY', 'PROGRESS'
  end type AP_Job_Unified_Query_In
```

### `AP_Job_Unified_Query_Out` (lines 301–308)

```fortran
  type, public :: AP_Job_Unified_Query_Out
    type(JobSummary), optional :: summary  ! Job summary
    logical, optional :: isCompleted  ! Whether job is completed
    logical, optional :: isAborted  ! Whether job is aborted
    integer(i4), optional :: currentStep  ! Current step index
    real(wp), optional :: progress  ! Job progress (0-1)
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Query_Out
```

### `AP_Job_Unified_StatusReport_In` (lines 311–313)

```fortran
  type, public :: AP_Job_Unified_StatusReport_In
    ! No input parameters
  end type AP_Job_Unified_StatusReport_In
```

### `AP_Job_Unified_StatusReport_Out` (lines 314–317)

```fortran
  type, public :: AP_Job_Unified_StatusReport_Out
    type(JobSummary) :: summary  ! Job summary
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_StatusReport_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AP_Job_StepRunner_Ifc` | 73 | `subroutine AP_Job_StepRunner_Ifc(descJob, stateModel, stepIndex, opts, ierr)` |
| SUBROUTINE | `UF_Job_StepRunner_Ifc` | 83 | `subroutine UF_Job_StepRunner_Ifc(descJob, stateModel, stepIndex, opts, ierr)` |
| SUBROUTINE | `AP_Job_InitDesc_Structured` | 411 | `subroutine AP_Job_InitDesc_Structured(descJob, in, out)` |
| SUBROUTINE | `AP_Job_AttachMod_Structured` | 439 | `subroutine AP_Job_AttachMod_Structured(descJob, in, out)` |
| SUBROUTINE | `AP_Job_AddStep_Structured` | 465 | `subroutine AP_Job_AddStep_Structured(descJob, in, out)` |
| SUBROUTINE | `AP_Job_BindCtx_Structured` | 504 | `subroutine AP_Job_BindCtx_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_SetOpts_Structured` | 550 | `subroutine AP_Job_SetOpts_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_PrepEnv_Structured` | 572 | `subroutine AP_Job_PrepEnv_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Run_Structured` | 611 | `subroutine AP_Job_Run_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_RunNext_Structured` | 641 | `subroutine AP_Job_RunNext_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_SaveChk_Structured` | 723 | `subroutine AP_Job_SaveChk_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_LoadChk_Structured` | 777 | `subroutine AP_Job_LoadChk_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_TryRestart_Structured` | 856 | `subroutine AP_Job_TryRestart_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_HandleFail_Structured` | 899 | `subroutine AP_Job_HandleFail_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Final_Structured` | 924 | `subroutine AP_Job_Final_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_BuildSum_Structured` | 949 | `subroutine AP_Job_BuildSum_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_QueryStat_Structured` | 972 | `subroutine AP_Job_QueryStat_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Unified_OptionsDefault_Structured` | 999 | `subroutine AP_Job_Unified_OptionsDefault_Structured(in, out)` |
| SUBROUTINE | `AP_Job_Unified_OptionsValidate_Structured` | 1027 | `subroutine AP_Job_Unified_OptionsValidate_Structured(in, out)` |
| SUBROUTINE | `AP_Job_Unified_Cfg_Structured` | 1048 | `subroutine AP_Job_Unified_Cfg_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Unified_Checkpoint_Structured` | 1097 | `subroutine AP_Job_Unified_Checkpoint_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Unified_Execute_Structured` | 1142 | `subroutine AP_Job_Unified_Execute_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Unified_Query_Structured` | 1195 | `subroutine AP_Job_Unified_Query_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_Unified_StatusReport_Structured` | 1247 | `subroutine AP_Job_Unified_StatusReport_Structured(ctxJob, in, out)` |
| SUBROUTINE | `AP_Job_AddStep` | 1278 | `subroutine AP_Job_AddStep(descJob, descStep)` |
| SUBROUTINE | `AP_Job_AttachMod` | 1290 | `subroutine AP_Job_AttachMod(descJob, descModel)` |
| SUBROUTINE | `AP_Job_BindCtx` | 1302 | `subroutine AP_Job_BindCtx(ctxJob, descJob, stateModel, opts, stepRunner)` |
| SUBROUTINE | `AP_Job_BuildSum` | 1320 | `subroutine AP_Job_BuildSum(ctxJob, summary)` |
| SUBROUTINE | `AP_Job_Final` | 1332 | `subroutine AP_Job_Final(ctxJob)` |
| SUBROUTINE | `AP_Job_HandleFail` | 1342 | `subroutine AP_Job_HandleFail(ctxJob, errorCode)` |
| SUBROUTINE | `AP_Job_InitDesc` | 1354 | `subroutine AP_Job_InitDesc(descJob)` |
| SUBROUTINE | `AP_Job_LoadChk` | 1364 | `subroutine AP_Job_LoadChk(ctxJob)` |
| SUBROUTINE | `AP_Job_PrepEnv` | 1374 | `subroutine AP_Job_PrepEnv(ctxJob)` |
| SUBROUTINE | `AP_Job_QueryStat` | 1384 | `subroutine AP_Job_QueryStat(ctxJob, isCompleted, isAborted, current_step_index)` |
| SUBROUTINE | `AP_Job_Run` | 1400 | `subroutine AP_Job_Run(ctxJob)` |
| SUBROUTINE | `AP_Job_RunNext` | 1410 | `subroutine AP_Job_RunNext(ctxJob)` |
| SUBROUTINE | `AP_Job_SaveChk` | 1420 | `subroutine AP_Job_SaveChk(ctxJob)` |
| SUBROUTINE | `AP_Job_SetOpts` | 1430 | `subroutine AP_Job_SetOpts(ctxJob, opts)` |
| SUBROUTINE | `AP_Job_TryRestart` | 1442 | `subroutine AP_Job_TryRestart(ctxJob)` |
| SUBROUTINE | `AP_Job_Un_OptionsDefault` | 1452 | `subroutine AP_Job_Un_OptionsDefault(opts)` |
| SUBROUTINE | `AP_Job_Un_OptionsValidate` | 1463 | `subroutine AP_Job_Un_OptionsValidate(opts, is_valid, status)` |
| SUBROUTINE | `AP_Job_Unified_Cfg` | 1478 | `subroutine AP_Job_Unified_Cfg(ctxJob, descJob, stateModel, opts, step_runner, status)` |
| SUBROUTINE | `AP_Job_Unified_Checkpoint` | 1498 | `subroutine AP_Job_Unified_Checkpoint(operation, ctxJob, status)` |
| SUBROUTINE | `AP_Job_Unified_Execute` | 1512 | `subroutine AP_Job_Unified_Execute(ctxJob, operation, summary, status)` |
| SUBROUTINE | `AP_Job_Unified_Query` | 1528 | `subroutine AP_Job_Unified_Query(operation, ctxJob, summary, isCompleted, isAborted, currentStep, progress, status)` |
| SUBROUTINE | `AP_Job_Unified_StatusReport` | 1552 | `subroutine AP_Job_Unified_StatusReport(ctxJob, summary, status)` |
| SUBROUTINE | `AP_Job_UnifiedCfg` | 1565 | `subroutine AP_Job_UnifiedCfg(ctxJob, descJob, stateModel, opts, step_runner, status)` |
| SUBROUTINE | `AP_Job_UnifiedChkpt` | 1575 | `subroutine AP_Job_UnifiedChkpt(operation, ctxJob, status)` |
| SUBROUTINE | `AP_Job_UnifiedExecute` | 1582 | `subroutine AP_Job_UnifiedExecute(ctxJob, operation, summary, status)` |
| SUBROUTINE | `AP_Job_UnifiedOptsDef` | 1590 | `subroutine AP_Job_UnifiedOptsDef(opts)` |
| SUBROUTINE | `AP_Job_UnifiedOptsValid` | 1595 | `subroutine AP_Job_UnifiedOptsValid(opts, is_valid, status)` |
| SUBROUTINE | `AP_Job_UnifiedQuery` | 1602 | `subroutine AP_Job_UnifiedQuery(operation, ctxJob, summary, isCompleted, isAborted, currentStep, progress, status)` |
| SUBROUTINE | `AP_Job_UnifiedStatusReport` | 1614 | `subroutine AP_Job_UnifiedStatusReport(ctxJob, summary, status)` |
| SUBROUTINE | `RT_Job_AddStep` | 1621 | `subroutine RT_Job_AddStep(descJob, descStep)` |
| SUBROUTINE | `RT_Job_AttachMod` | 1627 | `subroutine RT_Job_AttachMod(descJob, descModel)` |
| SUBROUTINE | `RT_Job_BindCtx` | 1633 | `subroutine RT_Job_BindCtx(ctxJob, descJob, stateModel, opts, stepRunner)` |
| SUBROUTINE | `RT_Job_BuildSum` | 1642 | `subroutine RT_Job_BuildSum(ctxJob, summary)` |
| SUBROUTINE | `RT_Job_Final` | 1648 | `subroutine RT_Job_Final(ctxJob)` |
| SUBROUTINE | `RT_Job_HandleFail` | 1653 | `subroutine RT_Job_HandleFail(ctxJob, errorCode)` |
| SUBROUTINE | `RT_Job_InitDesc` | 1659 | `subroutine RT_Job_InitDesc(descJob)` |
| SUBROUTINE | `RT_Job_LoadChk` | 1664 | `subroutine RT_Job_LoadChk(ctxJob)` |
| SUBROUTINE | `RT_Job_PrepEnv` | 1669 | `subroutine RT_Job_PrepEnv(ctxJob)` |
| SUBROUTINE | `RT_Job_QueryStat` | 1674 | `subroutine RT_Job_QueryStat(ctxJob, isCompleted, isAborted, current_step_index)` |
| SUBROUTINE | `RT_Job_Run` | 1682 | `subroutine RT_Job_Run(ctxJob)` |
| SUBROUTINE | `RT_Job_RunNext` | 1687 | `subroutine RT_Job_RunNext(ctxJob)` |
| SUBROUTINE | `RT_Job_SaveChk` | 1692 | `subroutine RT_Job_SaveChk(ctxJob)` |
| SUBROUTINE | `RT_Job_SetOpts` | 1697 | `subroutine RT_Job_SetOpts(ctxJob, opts)` |
| SUBROUTINE | `RT_Job_TryRestart` | 1703 | `subroutine RT_Job_TryRestart(ctxJob)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
