!===============================================================================
! MODULE: AP_Job_Mgr
! LAYER:  L6_AP
! DOMAIN: Job
! ROLE:   Mgr — job execution manager
! BRIEF:  Job execution orchestration, step scheduling, restart/failure.
!===============================================================================

module AP_Job_Mgr
!> Status: stub (not implemented yet)
!> Theory: (TODO) | Last verified: 2026-02-14
  !! UFC Job layer: orchestrates execution of analysis steps.
  !!
  !! Responsibilities (strictly within Job layer):
  !! - Holds job-level description (JobDesc) and global state (State_Model) binding;
  !! - Decides which steps to run and their order (step-level scheduling, no increment/iteration loops);
  !! - Handles restart/failure strategies at job level;
  !! - Provides simple job result summary and status query interface.
  USE IF_Prec_Core,        only: i4, wp
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID, IF_STATUS_IO_ERROR
  use MD_TypeSystem, only: StepDesc => Desc_Step, ModelDesc => Desc_Model, &
       State_Model, State_Step
  use AP_Job_Def, only: JobDesc => AP_Job_Desc
  use UF_Model_Kernel_Types, only: STEP_Static, STEP_ImplicitDynamic, STEP_ExplicitDynamic, STEP_ArcLength
  implicit none
  private

  !===================================================================
  ! Public types and callback interfaces
  !===================================================================

  type, public :: AP_Job_Opts
    !! Options for controlling Job execution from user/upper layer
    logical     :: restartEnabled  = .false.
    logical     :: checkOnly       = .false.
    logical     :: postOnly        = .false.
    integer(i4) :: maxSteps        = -1_i4   !! <=0: unlimited steps
  end type AP_Job_Opts
  ! Backward compatibility: same structure
  type, public :: JobOpts
    logical     :: isrestartenable = .false.
    logical     :: isCheckOnly     = .false.
    logical     :: isPostOnly      = .false.
    integer(i4) :: maxSteps        = -1_i4
  end type JobOpts

  ! StepRunner return codes (for L5_RT bridge)
  integer(i4), parameter, public :: AP_JOB_RT_FULL_JOB_DONE = -2_i4
  !! StepRunner returned: ran full job in one call (L5_RT bridge mode)

  type, public :: AP_Job_Summary
    !! High-level summary of Job execution (simplified from UF_JobStatus)
    integer(i4) :: nStepsTotal     = 0_i4
    integer(i4) :: nStepsCompleted = 0_i4
    logical     :: completed       = .false.
    logical     :: aborted         = .false.
    integer(i4) :: lastErrCode     = 0_i4
    real(wp)    :: progress        = 0.0_wp  !! 0-1, overall progress by step count
  end type AP_Job_Summary
  ! Backward compatibility: same structure
  type, public :: JobSummary
    integer(i4) :: nStepsTotal      = 0_i4
    integer(i4) :: nStepsCompleted  = 0_i4
    logical     :: isCompleted      = .false.
    logical     :: isAborted        = .false.
    integer(i4) :: lastErrorCode    = 0_i4
    real(wp)    :: progress         = 0.0_wp
  end type JobSummary

  !! Step-level execution callback interface: provided by Step/Runtime layer
  abstract interface
    subroutine AP_Job_StepRunner_Ifc(descJob, stateModel, stepIndex, opts, ierr)
      import :: JobDesc, State_Model, AP_Job_Opts, i4
      type(JobDesc),      intent(in)    :: descJob
      type(State_Model),  intent(inout) :: stateModel
      integer(i4),        intent(in)    :: stepIndex
      type(AP_Job_Opts), intent(in)    :: opts
      integer(i4),       intent(out)   :: ierr
    end subroutine AP_Job_StepRunner_Ifc
  end interface
  abstract interface
    subroutine UF_Job_StepRunner_Ifc(descJob, stateModel, stepIndex, opts, ierr)
      import :: JobDesc, State_Model, JobOpts, i4
      type(JobDesc),     intent(in)    :: descJob
      type(State_Model), intent(inout) :: stateModel
      integer(i4),       intent(in)    :: stepIndex
      type(JobOpts),     intent(in)    :: opts
      integer(i4),      intent(out)   :: ierr
    end subroutine UF_Job_StepRunner_Ifc
  end interface

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
  ! Backward compatibility: same structure
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

  ! ===================================================================
  ! Structured Input/Output Types
  ! ===================================================================
  ! AP_Job_InitDesc
  type, public :: AP_Job_InitDesc_In
    ! No input parameters (uses inout descJob)
  end type AP_Job_InitDesc_In
  type, public :: AP_Job_InitDesc_Out
    type(ErrorStatusType) :: status
  end type AP_Job_InitDesc_Out

  ! AP_Job_AttachMod
  type, public :: AP_Job_AttachMod_In
    type(ModelDesc) :: descModel  ! Model description
  end type AP_Job_AttachMod_In
  type, public :: AP_Job_AttachMod_Out
    type(ErrorStatusType) :: status
  end type AP_Job_AttachMod_Out

  ! AP_Job_AddStep
  type, public :: AP_Job_AddStep_In
    type(StepDesc) :: descStep  ! Step description
  end type AP_Job_AddStep_In
  type, public :: AP_Job_AddStep_Out
    type(ErrorStatusType) :: status
  end type AP_Job_AddStep_Out

  ! AP_Job_BindCtx
  type, public :: AP_Job_BindCtx_In
    type(JobDesc), pointer :: descJob  ! Job description (target)
    type(State_Model), pointer :: stateModel  ! Global model state (target)
    type(JobOpts) :: opts  ! Job options
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: stepRunner  ! Step runner callback
  end type AP_Job_BindCtx_In
  type, public :: AP_Job_BindCtx_Out
    type(ErrorStatusType) :: status
  end type AP_Job_BindCtx_Out

  ! AP_Job_SetOpts
  type, public :: AP_Job_SetOpts_In
    type(JobOpts) :: opts  ! Job options
  end type AP_Job_SetOpts_In
  type, public :: AP_Job_SetOpts_Out
    type(ErrorStatusType) :: status
  end type AP_Job_SetOpts_Out

  ! AP_Job_PrepEnv
  type, public :: AP_Job_PrepEnv_In
    ! No input parameters
  end type AP_Job_PrepEnv_In
  type, public :: AP_Job_PrepEnv_Out
    type(ErrorStatusType) :: status
  end type AP_Job_PrepEnv_Out

  ! AP_Job_Run
  type, public :: AP_Job_Run_In
    ! No input parameters (uses inout ctxJob)
  end type AP_Job_Run_In
  type, public :: AP_Job_Run_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Run_Out

  ! AP_Job_RunNext
  type, public :: AP_Job_RunNext_In
    ! No input parameters (uses inout ctxJob)
  end type AP_Job_RunNext_In
  type, public :: AP_Job_RunNext_Out
    type(ErrorStatusType) :: status
  end type AP_Job_RunNext_Out

  ! AP_Job_SaveChk
  type, public :: AP_Job_SaveChk_In
    ! No input parameters
  end type AP_Job_SaveChk_In
  type, public :: AP_Job_SaveChk_Out
    type(ErrorStatusType) :: status
  end type AP_Job_SaveChk_Out

  ! AP_Job_LoadChk
  type, public :: AP_Job_LoadChk_In
    ! No input parameters
  end type AP_Job_LoadChk_In
  type, public :: AP_Job_LoadChk_Out
    type(ErrorStatusType) :: status
  end type AP_Job_LoadChk_Out

  ! AP_Job_TryRestart
  type, public :: AP_Job_TryRestart_In
    ! No input parameters
  end type AP_Job_TryRestart_In
  type, public :: AP_Job_TryRestart_Out
    type(ErrorStatusType) :: status
  end type AP_Job_TryRestart_Out

  ! AP_Job_HandleFail
  type, public :: AP_Job_HandleFail_In
    integer(i4) :: errorCode  ! Error code
  end type AP_Job_HandleFail_In
  type, public :: AP_Job_HandleFail_Out
    type(ErrorStatusType) :: status
  end type AP_Job_HandleFail_Out

  ! AP_Job_Final
  type, public :: AP_Job_Final_In
    ! No input parameters
  end type AP_Job_Final_In
  type, public :: AP_Job_Final_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Final_Out

  ! AP_Job_BuildSum
  type, public :: AP_Job_BuildSum_In
    ! No input parameters
  end type AP_Job_BuildSum_In
  type, public :: AP_Job_BuildSum_Out
    type(JobSummary) :: summary  ! Job summary
    type(ErrorStatusType) :: status
  end type AP_Job_BuildSum_Out

  ! AP_Job_QueryStat
  type, public :: AP_Job_QueryStat_In
    ! No input parameters
  end type AP_Job_QueryStat_In
  type, public :: AP_Job_QueryStat_Out
    logical :: isCompleted  ! Whether job is completed
    logical :: isAborted  ! Whether job is aborted
    integer(i4) :: current_step_index  ! Current step index
    type(ErrorStatusType) :: status
  end type AP_Job_QueryStat_Out

  ! AP_Job_Unified_OptionsDefault
  type, public :: AP_Job_Unified_OptionsDefault_In
    ! No input parameters
  end type AP_Job_Unified_OptionsDefault_In
  type, public :: AP_Job_Unified_OptionsDefault_Out
    type(JobOpts) :: opts  ! Default job options
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_OptionsDefault_Out

  ! AP_Job_Unified_OptionsValidate
  type, public :: AP_Job_Unified_OptionsValidate_In
    type(JobOpts) :: opts  ! Job options to validate
  end type AP_Job_Unified_OptionsValidate_In
  type, public :: AP_Job_Unified_OptionsValidate_Out
    logical :: is_valid  ! Whether options are valid
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_OptionsValidate_Out

  ! AP_Job_Unified_Cfg
  type, public :: AP_Job_Unified_Cfg_In
    type(JobDesc), pointer :: descJob  ! Job description (target)
    type(State_Model), pointer :: stateModel  ! Global model state (target)
    type(JobOpts) :: opts  ! Job options
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: step_runner  ! Step runner callback
  end type AP_Job_Unified_Cfg_In
  type, public :: AP_Job_Unified_Cfg_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Cfg_Out

  ! AP_Job_Unified_Checkpoint
  type, public :: AP_Job_Unified_Checkpoint_In
    character(len=32) :: operation  ! Operation: 'SAVE', 'LOAD', 'TRY_RESTART'
  end type AP_Job_Unified_Checkpoint_In
  type, public :: AP_Job_Unified_Checkpoint_Out
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Checkpoint_Out

  ! AP_Job_Unified_Execute
  type, public :: AP_Job_Unified_Execute_In
    character(len=32) :: operation  ! Operation: 'run', 'run_next', 'final', 'query'
  end type AP_Job_Unified_Execute_In
  type, public :: AP_Job_Unified_Execute_Out
    type(JobSummary), optional :: summary  ! Job summary (for query)
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Execute_Out

  ! AP_Job_Unified_Query
  type, public :: AP_Job_Unified_Query_In
    character(len=32) :: operation  ! Operation: 'STATUS', 'SUMMARY', 'PROGRESS'
  end type AP_Job_Unified_Query_In
  type, public :: AP_Job_Unified_Query_Out
    type(JobSummary), optional :: summary  ! Job summary
    logical, optional :: isCompleted  ! Whether job is completed
    logical, optional :: isAborted  ! Whether job is aborted
    integer(i4), optional :: currentStep  ! Current step index
    real(wp), optional :: progress  ! Job progress (0-1)
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_Query_Out

  ! AP_Job_Unified_StatusReport
  type, public :: AP_Job_Unified_StatusReport_In
    ! No input parameters
  end type AP_Job_Unified_StatusReport_In
  type, public :: AP_Job_Unified_StatusReport_Out
    type(JobSummary) :: summary  ! Job summary
    type(ErrorStatusType) :: status
  end type AP_Job_Unified_StatusReport_Out

  !===================================================================
  ! Public API
  !===================================================================
  ! Structured input/output types
  public :: AP_Job_InitDesc_In, AP_Job_InitDesc_Out
  public :: AP_Job_AttachMod_In, AP_Job_AttachMod_Out
  public :: AP_Job_AddStep_In, AP_Job_AddStep_Out
  public :: AP_Job_BindCtx_In, AP_Job_BindCtx_Out
  public :: AP_Job_SetOpts_In, AP_Job_SetOpts_Out
  public :: AP_Job_PrepEnv_In, AP_Job_PrepEnv_Out
  public :: AP_Job_Run_In, AP_Job_Run_Out
  public :: AP_Job_RunNext_In, AP_Job_RunNext_Out
  public :: AP_Job_SaveChk_In, AP_Job_SaveChk_Out
  public :: AP_Job_LoadChk_In, AP_Job_LoadChk_Out
  public :: AP_Job_TryRestart_In, AP_Job_TryRestart_Out
  public :: AP_Job_HandleFail_In, AP_Job_HandleFail_Out
  public :: AP_Job_Final_In, AP_Job_Final_Out
  public :: AP_Job_BuildSum_In, AP_Job_BuildSum_Out
  public :: AP_Job_QueryStat_In, AP_Job_QueryStat_Out
  ! Structured interfaces
  public :: AP_Job_InitDesc_Structured
  public :: AP_Job_AttachMod_Structured
  public :: AP_Job_AddStep_Structured
  public :: AP_Job_BindCtx_Structured
  public :: AP_Job_SetOpts_Structured
  public :: AP_Job_PrepEnv_Structured
  public :: AP_Job_Run_Structured
  public :: AP_Job_RunNext_Structured
  public :: AP_Job_SaveChk_Structured
  public :: AP_Job_LoadChk_Structured
  public :: AP_Job_TryRestart_Structured
  public :: AP_Job_HandleFail_Structured
  public :: AP_Job_Final_Structured
  public :: AP_Job_BuildSum_Structured
  public :: AP_Job_QueryStat_Structured
  ! Legacy interfaces (deprecated)
  public :: AP_Job_InitDesc
  public :: AP_Job_AttachMod
  public :: AP_Job_AddStep
  public :: AP_Job_BindCtx
  public :: AP_Job_SetOpts
  public :: AP_Job_PrepEnv
  public :: AP_Job_Run
  public :: AP_Job_RunNext
  public :: AP_Job_SaveChk
  public :: AP_Job_LoadChk
  public :: AP_Job_TryRestart
  public :: AP_Job_HandleFail
  public :: AP_Job_Final
  public :: AP_Job_BuildSum
  public :: AP_Job_QueryStat
  ! Unified interfaces - Structured types
  public :: AP_Job_Unified_OptionsDefault_In, AP_Job_Unified_OptionsDefault_Out
  public :: AP_Job_Unified_OptionsValidate_In, AP_Job_Unified_OptionsValidate_Out
  public :: AP_Job_Unified_Cfg_In, AP_Job_Unified_Cfg_Out
  public :: AP_Job_Unified_Checkpoint_In, AP_Job_Unified_Checkpoint_Out
  public :: AP_Job_Unified_Execute_In, AP_Job_Unified_Execute_Out
  public :: AP_Job_Unified_Query_In, AP_Job_Unified_Query_Out
  public :: AP_Job_Unified_StatusReport_In, AP_Job_Unified_StatusReport_Out
  ! Unified interfaces - Structured procedures
  public :: AP_Job_Unified_OptionsDefault_Structured
  public :: AP_Job_Unified_OptionsValidate_Structured
  public :: AP_Job_Unified_Cfg_Structured
  public :: AP_Job_Unified_Checkpoint_Structured
  public :: AP_Job_Unified_Execute_Structured
  public :: AP_Job_Unified_Query_Structured
  public :: AP_Job_Unified_StatusReport_Structured
  ! Extended API (task13200-13299) - Legacy
  public :: AP_Job_UnifiedExecute
  public :: AP_Job_UnifiedCfg
  ! Jobmanagement  (task14200-14499) - Legacy
  public :: AP_Job_UnifiedStatusReport
  public :: AP_Job_UnifiedQuery
  public :: AP_Job_UnifiedChkpt
  public :: AP_Job_UnifiedOptsValid
  public :: AP_Job_UnifiedOptsDef
  ! Backward compatibility
  public :: RT_Job_InitDesc, RT_Job_AttachMod, RT_Job_AddStep
  public :: RT_Job_BindCtx, RT_Job_SetOpts, RT_Job_PrepEnv
  public :: RT_Job_Run, RT_Job_RunNext
  public :: RT_Job_SaveChk, RT_Job_LoadChk, RT_Job_TryRestart, RT_Job_HandleFail
  public :: RT_Job_Final, RT_Job_BuildSum, RT_Job_QueryStat
  public :: AP_Job_Unified_Execute, AP_Job_Unified_Cfg
  public :: AP_Job_Unified_StatusReport, AP_Job_Unified_Query
  public :: AP_Job_Unified_Checkpoint, AP_Job_Unified_OptionsValidate
  public :: AP_Job_Unified_OptionsDefault

contains

  ! ===================================================================
  ! Structured Interfaces
  ! ===================================================================
  subroutine AP_Job_InitDesc_Structured(descJob, in, out)
    !! Initialize job description
    !!
    !! Theory:
    !!   Initializes job description to clean default state.
    !!   Sets job ID, name, model name, analysis type, and CPU count to defaults.
    !!
    !! Input:
    !!   descJob: Job description (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobDesc), intent(inout) :: descJob
    type(AP_Job_InitDesc_In), intent(in) :: in
    type(AP_Job_InitDesc_Out), intent(out) :: out

    call init_error_status(out%status)
    call descJob%Init()
    descJob%jobId = 0_i4
    descJob%name = ""
    descJob%modelName = ""
    descJob%analysisType = ""
    descJob%ncpus = 1_i4
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_InitDesc_Structured

  subroutine AP_Job_AttachMod_Structured(descJob, in, out)
    !! Attach model description to job
    !!
    !! Theory:
    !!   Binds a model description to job by name convention, without copying model content.
    !!   If job analysis type is not set, inherits from model.
    !!
    !! Input:
    !!   descJob: Job description (inout)
    !!   in%descModel: Model description
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobDesc), intent(inout) :: descJob
    type(AP_Job_AttachMod_In), intent(in) :: in
    type(AP_Job_AttachMod_Out), intent(out) :: out

    call init_error_status(out%status)
    descJob%modelName = trim(in%descModel%name)
    if (len_trim(descJob%analysisType) == 0) then
      descJob%analysisType = trim(in%descModel%analysisType)
    end if
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_AttachMod_Structured

  subroutine AP_Job_AddStep_Structured(descJob, in, out)
    !! Add step to job
    !!
    !! Theory:
    !!   Infers analysis type from first step type at job level.
    !!   Step sequence is managed by Model/Step layer (in Desc_Model%steps(:)).
    !!
    !! Input:
    !!   descJob: Job description (inout)
    !!   in%descStep: Step description
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobDesc), intent(inout) :: descJob
    type(AP_Job_AddStep_In), intent(in) :: in
    type(AP_Job_AddStep_Out), intent(out) :: out

    call init_error_status(out%status)
    if (len_trim(descJob%analysisType) /= 0) then
      out%status%status_code = IF_STATUS_OK
      return
    end if

    select case (in%descStep%stepType)
    case (STEP_Static)
      descJob%analysisType = 'STATIC'
    case (STEP_ImplicitDynamic)
      descJob%analysisType = 'IMPLICIT_DYNAMIC'
    case (STEP_ExplicitDynamic)
      descJob%analysisType = 'EXPLICIT_DYNAMIC'
    case (STEP_ArcLength)
      descJob%analysisType = 'ARC_LENGTH'
    case default
      descJob%analysisType = 'GENERIC'
    end select
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_AddStep_Structured

  subroutine AP_Job_BindCtx_Structured(ctxJob, in, out)
    !! Bind job context
    !!
    !! Theory:
    !!   Binds job description, global state, run options, and step execution callback
    !!   to build Context_Job.
    !!
    !! Input:
    !!   in%descJob: Job description (target)
    !!   in%stateModel: Global model state (target)
    !!   in%opts: Job options
    !!   in%stepRunner: Step runner callback (optional)
    !!
    !! Output:
    !!   ctxJob: Job context (out)
    !!   out%status: Error status
    
    type(JobCtx), intent(out) :: ctxJob
    type(AP_Job_BindCtx_In), intent(in) :: in
    type(AP_Job_BindCtx_Out), intent(out) :: out

    call init_error_status(out%status)
    ctxJob%desc => in%descJob
    ctxJob%stateModel => in%stateModel
    ctxJob%opts = in%opts

    ctxJob%current_step_index = 1_i4
    ctxJob%isCompleted = .false.
    ctxJob%isAborted = .false.
    ctxJob%summary%nStepsTotal = in%stateModel%nStepsTotal
    ctxJob%summary%nStepsCompleted = 0_i4
    ctxJob%summary%isCompleted = .false.
    ctxJob%summary%isAborted = .false.
    ctxJob%summary%lastErrorCode = 0_i4
    ctxJob%summary%progress = 0.0_wp

    ctxJob%nStepsPlanned = in%stateModel%nStepsTotal

    if (present(in%stepRunner)) then
      ctxJob%StepRunner => in%stepRunner
    else
      ctxJob%StepRunner => null()
    end if
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_BindCtx_Structured

  subroutine AP_Job_SetOpts_Structured(ctxJob, in, out)
    !! Set job options
    !!
    !! Theory:
    !!   Sets job execution options.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in%opts: Job options
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_SetOpts_In), intent(in) :: in
    type(AP_Job_SetOpts_Out), intent(out) :: out

    call init_error_status(out%status)
    ctxJob%opts = in%opts
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_SetOpts_Structured

  subroutine AP_Job_PrepEnv_Structured(ctxJob, in, out)
    !! Prepare environment for job execution
    !!
    !! Theory:
    !!   Prepares environment for job execution (directories, logs, restart hooks, etc.).
    !!   Creates job output and checkpoint directories if they do not exist.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_PrepEnv_In), intent(in) :: in
    type(AP_Job_PrepEnv_Out), intent(out) :: out

    character(len=256) :: out_dir, chk_dir
    integer :: exitstat

    call init_error_status(out%status)

    ! Determine directory names (use job name if available)
    if (associated(ctxJob%desc) .and. len_trim(ctxJob%desc%name) > 0) then
      out_dir = trim(ctxJob%desc%name) // '_output'
      chk_dir = trim(ctxJob%desc%name) // '_checkpoint'
    else
      out_dir = 'job_output'
      chk_dir = 'job_checkpoint'
    end if

    ! Create output and checkpoint directories (mkdir ignores if exists on many systems)
    call execute_command_line('mkdir "'//trim(out_dir)//'"', exitstat=exitstat)
    call execute_command_line('mkdir "'//trim(chk_dir)//'"', exitstat=exitstat)

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_PrepEnv_Structured

  subroutine AP_Job_Run_Structured(ctxJob, in, out)
    !! Run entire job
    !!
    !! Theory:
    !!   High-level job entry: runs entire job based on Context_Job.
    !!   Executes all steps sequentially until completion or abortion.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_Run_In), intent(in) :: in
    type(AP_Job_Run_Out), intent(out) :: out

    call init_error_status(out%status)
    if (ctxJob%opts%isrestartenable) then
      call AP_Job_TryRestart(ctxJob)
    end if
    call AP_Job_PrepEnv(ctxJob)
    do while (.not. ctxJob%isCompleted .and. .not. ctxJob%isAborted)
      call AP_Job_RunNext(ctxJob)
    end do
    call AP_Job_Final(ctxJob)
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_Run_Structured

  subroutine AP_Job_RunNext_Structured(ctxJob, in, out)
    !! Execute next step
    !!
    !! Theory:
    !!   Executes next step (step-level scheduling, no increment/iteration details).
    !!   Updates progress: progress = nStepsCompleted / nStepsTotal
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_RunNext_In), intent(in) :: in
    type(AP_Job_RunNext_Out), intent(out) :: out

    integer(i4) :: ierr

    call init_error_status(out%status)

    if (.not. associated(ctxJob%StepRunner)) then
      call AP_Job_HandleFail(ctxJob, -1_i4)
      out%status%status_code = IF_STATUS_ERROR
      out%status%message = "AP_Job_RunNext_Structured: Step runner not associated"
      return
    end if

    ! If all steps completed, mark as done
    if (ctxJob%nStepsPlanned > 0_i4) then
      if (ctxJob%current_step_index > ctxJob%nStepsPlanned) then
        ctxJob%isCompleted = .true.
        ctxJob%summary%isCompleted = .true.
        out%status%status_code = IF_STATUS_OK
        return
      end if
    end if

    ! Call Step/Runtime provided callback to execute current step
    ierr = 0_i4
    call ctxJob%StepRunner(ctxJob%desc, ctxJob%stateModel, &
                           ctxJob%current_step_index, ctxJob%opts, ierr)

    ! AP_JOB_RT_FULL_JOB_DONE: StepRunner ran entire job (e.g. L5_RT bridge)
    if (ierr == AP_JOB_RT_FULL_JOB_DONE) then
      ctxJob%summary%nStepsCompleted = ctxJob%nStepsPlanned
      ctxJob%current_step_index = ctxJob%nStepsPlanned + 1_i4
      ctxJob%isCompleted = .true.
      ctxJob%summary%isCompleted = .true.
      ctxJob%summary%progress = 1.0_wp
      out%status%status_code = IF_STATUS_OK
      return
    end if

    if (ierr == 0_i4) then
      ctxJob%summary%nStepsCompleted = ctxJob%summary%nStepsCompleted + 1_i4
      ctxJob%current_step_index = ctxJob%current_step_index + 1_i4

      ! Update progress: progress = nStepsCompleted / nStepsTotal
      if (ctxJob%summary%nStepsTotal > 0_i4) then
        ctxJob%summary%progress = real(ctxJob%summary%nStepsCompleted, wp) / &
                                  real(ctxJob%summary%nStepsTotal, wp)
      else
        ctxJob%summary%progress = 0.0_wp
      end if

      if (ctxJob%nStepsPlanned > 0_i4 .and. &
          ctxJob%current_step_index > ctxJob%nStepsPlanned) then
        ctxJob%isCompleted = .true.
        ctxJob%summary%isCompleted = .true.
      end if
    else
      call AP_Job_HandleFail(ctxJob, ierr)
      out%status%status_code = IF_STATUS_ERROR
      out%status%message = "AP_Job_RunNext_Structured: Step execution failed"
      return
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_RunNext_Structured

  subroutine AP_Job_SaveChk_Structured(ctxJob, in, out)
    !! Save job checkpoint
    !!
    !! Theory:
    !!   Saves lightweight job-level checkpoint (e.g., step number) to file.
    !!   Checkpoint file format: currentStep isCompleted isAborted lastErrorCode
    !!
    !! Input:
    !!   ctxJob: Job context (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(in) :: ctxJob
    type(AP_Job_SaveChk_In), intent(in) :: in
    type(AP_Job_SaveChk_Out), intent(out) :: out

    integer(i4) :: unit, ios
    character(len=256) :: chk_file

    call init_error_status(out%status)

    ! Determine checkpoint file name (use job name if available)
    if (associated(ctxJob%desc) .and. len_trim(ctxJob%desc%name) > 0) then
      write(chk_file, '(A,A)') trim(ctxJob%desc%name), '.chk'
    else
      chk_file = 'job.chk'
    end if

    ! Open checkpoint file with automatic unit allocation
    open(newunit=unit, file=trim(chk_file), status='replace', action='write', &
         form='formatted', iostat=ios)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_IO_ERROR
      out%status%message = "AP_Job_SaveChk_Structured: Cannot open checkpoint file"
      return
    end if

    ! Write checkpoint data
    write(unit, '(I10,1X,L1,1X,L1,1X,I10)', iostat=ios) &
      ctxJob%current_step_index, ctxJob%isCompleted, &
      ctxJob%isAborted, ctxJob%summary%lastErrorCode
    
    close(unit)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_IO_ERROR
      out%status%message = "AP_Job_SaveChk_Structured: Cannot write checkpoint file"
      return
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_SaveChk_Structured

  subroutine AP_Job_LoadChk_Structured(ctxJob, in, out)
    !! Load job checkpoint
    !!
    !! Theory:
    !!   Restores job-level checkpoint info from job.chk (if exists).
    !!   Checkpoint file format: currentStep isCompleted isAborted lastErrorCode
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_LoadChk_In), intent(in) :: in
    type(AP_Job_LoadChk_Out), intent(out) :: out

    integer(i4) :: unit, ios
    logical :: fileExists
    logical :: isCompleted, isAborted
    integer(i4) :: currentStep, lastErr
    character(len=256) :: chk_file

    call init_error_status(out%status)

    ! Determine checkpoint file name (use job name if available)
    if (associated(ctxJob%desc) .and. len_trim(ctxJob%desc%name) > 0) then
      write(chk_file, '(A,A)') trim(ctxJob%desc%name), '.chk'
    else
      chk_file = 'job.chk'
    end if

    ! Check if checkpoint file exists
    inquire(file=trim(chk_file), exist=fileExists)
    if (.not. fileExists) then
      out%status%status_code = IF_STATUS_OK
      out%status%message = "AP_Job_LoadChk_Structured: Checkpoint file not found"
      return
    end if

    ! Open checkpoint file with automatic unit allocation
    open(newunit=unit, file=trim(chk_file), status='old', action='read', &
         form='formatted', iostat=ios)
    if (ios /= 0) then
      out%status%status_code = IF_STATUS_IO_ERROR
      out%status%message = "AP_Job_LoadChk_Structured: Cannot open checkpoint file"
      return
    end if

    ! Read checkpoint data
    read(unit, '(I10,1X,L1,1X,L1,1X,I10)', iostat=ios) &
      currentStep, isCompleted, isAborted, lastErr
    close(unit)

    if (ios /= 0) then
      out%status%status_code = IF_STATUS_IO_ERROR
      out%status%message = "AP_Job_LoadChk_Structured: Cannot read checkpoint file"
      return
    end if

    ! Restore job state from checkpoint
    ctxJob%current_step_index = currentStep
    ctxJob%isCompleted = isCompleted
    ctxJob%isAborted = isAborted
    ctxJob%summary%lastErrorCode = lastErr
    ctxJob%summary%nStepsCompleted = max(0_i4, currentStep-1_i4)

    ! Update progress: progress = nStepsCompleted / nStepsTotal
    if (ctxJob%summary%nStepsTotal > 0_i4) then
      ctxJob%summary%progress = real(ctxJob%summary%nStepsCompleted, wp) / &
                                real(ctxJob%summary%nStepsTotal, wp)
    else
      ctxJob%summary%progress = 0.0_wp
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_LoadChk_Structured

  subroutine AP_Job_TryRestart_Structured(ctxJob, in, out)
    !! Try to restart job from checkpoint
    !!
    !! Theory:
    !!   Attempts to restart job from checkpoint if restart is enabled.
    !!   If restored currentStep exceeds planned step count, considers job complete.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_TryRestart_In), intent(in) :: in
    type(AP_Job_TryRestart_Out), intent(out) :: out

    call init_error_status(out%status)

    if (.not. ctxJob%opts%isrestartenable) then
      out%status%status_code = IF_STATUS_OK
      return
    end if

    call AP_Job_LoadChk(ctxJob)

    ! If already marked as completed or aborted, do not continue
    if (ctxJob%isCompleted .or. ctxJob%isAborted) then
      out%status%status_code = IF_STATUS_OK
      return
    end if

    ! Simple strategy: if restored currentStep exceeds planned step count, consider complete
    if (ctxJob%nStepsPlanned > 0_i4 .and. &
        ctxJob%current_step_index > ctxJob%nStepsPlanned) then
      ctxJob%isCompleted = .true.
      ctxJob%summary%isCompleted = .true.
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_TryRestart_Structured

  subroutine AP_Job_HandleFail_Structured(ctxJob, in, out)
    !! Handle job failure
    !!
    !! Theory:
    !!   Handles job failure by setting error code, marking as aborted, and saving checkpoint.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in%errorCode: Error code
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_HandleFail_In), intent(in) :: in
    type(AP_Job_HandleFail_Out), intent(out) :: out

    call init_error_status(out%status)
    ctxJob%summary%lastErrorCode = in%errorCode
    ctxJob%isAborted = .true.
    ctxJob%summary%isAborted = .true.
    call AP_Job_SaveChk(ctxJob)
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_HandleFail_Structured

  subroutine AP_Job_Final_Structured(ctxJob, in, out)
    !! Finalize job
    !!
    !! Theory:
    !!   Finalizes job by marking as completed if not aborted.
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_Final_In), intent(in) :: in
    type(AP_Job_Final_Out), intent(out) :: out

    call init_error_status(out%status)
    if (.not. ctxJob%isAborted) then
      ctxJob%isCompleted = .true.
      ctxJob%summary%isCompleted = .true.
    end if
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_Final_Structured

  subroutine AP_Job_BuildSum_Structured(ctxJob, in, out)
    !! Build job summary
    !!
    !! Theory:
    !!   Builds job summary from job context.
    !!
    !! Input:
    !!   ctxJob: Job context (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%summary: Job summary
    !!   out%status: Error status
    
    type(JobCtx), intent(in) :: ctxJob
    type(AP_Job_BuildSum_In), intent(in) :: in
    type(AP_Job_BuildSum_Out), intent(out) :: out

    call init_error_status(out%status)
    out%summary = ctxJob%summary
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_BuildSum_Structured

  subroutine AP_Job_QueryStat_Structured(ctxJob, in, out)
    !! Query job status
    !!
    !! Theory:
    !!   Queries job status including completion, abortion, and current step index.
    !!
    !! Input:
    !!   ctxJob: Job context (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%isCompleted: Whether job is completed
    !!   out%isAborted: Whether job is aborted
    !!   out%current_step_index: Current step index
    !!   out%status: Error status
    
    type(JobCtx), intent(in) :: ctxJob
    type(AP_Job_QueryStat_In), intent(in) :: in
    type(AP_Job_QueryStat_Out), intent(out) :: out

    call init_error_status(out%status)
    out%isCompleted = ctxJob%isCompleted
    out%isAborted = ctxJob%isAborted
    out%current_step_index = ctxJob%current_step_index
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_QueryStat_Structured

  subroutine AP_Job_Unified_OptionsDefault_Structured(in, out)
    !! Set job options to default values
    !!
    !! Theory:
    !!   Sets job options to default values:
    !!   - restartEnabled = false
    !!   - checkOnly = false
    !!   - postOnly = false
    !!   - maxSteps = -1 (unlimited)
    !!
    !! Input:
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%opts: Default job options
    !!   out%status: Error status
    
    type(AP_Job_Unified_OptionsDefault_In), intent(in) :: in
    type(AP_Job_Unified_OptionsDefault_Out), intent(out) :: out

    call init_error_status(out%status)
    out%opts%isrestartenable = .false.
    out%opts%isCheckOnly = .false.
    out%opts%isPostOnly = .false.
    out%opts%maxSteps = -1_i4
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_Unified_OptionsDefault_Structured

  subroutine AP_Job_Unified_OptionsValidate_Structured(in, out)
    !! Validate job options
    !!
    !! Theory:
    !!   Validates job options. Options are valid if maxSteps >= -1.
    !!
    !! Input:
    !!   in%opts: Job options to validate
    !!
    !! Output:
    !!   out%is_valid: Whether options are valid
    !!   out%status: Error status
    
    type(AP_Job_Unified_OptionsValidate_In), intent(in) :: in
    type(AP_Job_Unified_OptionsValidate_Out), intent(out) :: out

    call init_error_status(out%status)
    out%is_valid = (in%opts%maxSteps >= -1_i4)
    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_Unified_OptionsValidate_Structured

  subroutine AP_Job_Unified_Cfg_Structured(ctxJob, in, out)
    !! Unified job configuration interface
    !!
    !! Theory:
    !!   Unified job configuration interface that binds job description, global state,
    !!   run options, and step execution callback, then prepares environment.
    !!
    !! Input:
    !!   in%descJob: Job description (target)
    !!   in%stateModel: Global model state (target)
    !!   in%opts: Job options
    !!   in%step_runner: Step runner callback (optional)
    !!
    !! Output:
    !!   ctxJob: Configured job context (out)
    !!   out%status: Error status
    
    type(JobCtx), intent(out) :: ctxJob
    type(AP_Job_Unified_Cfg_In), intent(in) :: in
    type(AP_Job_Unified_Cfg_Out), intent(out) :: out

    type(AP_Job_BindCtx_In) :: bind_in
    type(AP_Job_BindCtx_Out) :: bind_out
    type(AP_Job_PrepEnv_In) :: prep_in
    type(AP_Job_PrepEnv_Out) :: prep_out

    call init_error_status(out%status)

    ! Bind context
    bind_in%descJob => in%descJob
    bind_in%stateModel => in%stateModel
    bind_in%opts = in%opts
    if (present(in%step_runner)) bind_in%stepRunner => in%step_runner
    call AP_Job_BindCtx_Structured(ctxJob, bind_in, bind_out)
    if (bind_out%status%status_code /= IF_STATUS_OK) then
      out%status = bind_out%status
      return
    end if

    ! Prepare environment
    call AP_Job_PrepEnv_Structured(ctxJob, prep_in, prep_out)
    if (prep_out%status%status_code /= IF_STATUS_OK) then
      out%status = prep_out%status
      return
    end if

    out%status%status_code = IF_STATUS_OK
  end subroutine AP_Job_Unified_Cfg_Structured

  subroutine AP_Job_Unified_Checkpoint_Structured(ctxJob, in, out)
    !! Unified checkpoint interface
    !!
    !! Theory:
    !!   Unified checkpoint interface supporting operations:
    !!   - 'SAVE': Save checkpoint
    !!   - 'LOAD': Load checkpoint
    !!   - 'TRY_RESTART': Try to restart from checkpoint
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in%operation: Operation ('SAVE', 'LOAD', 'TRY_RESTART')
    !!
    !! Output:
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_Unified_Checkpoint_In), intent(in) :: in
    type(AP_Job_Unified_Checkpoint_Out), intent(out) :: out

    type(AP_Job_SaveChk_In) :: save_in
    type(AP_Job_SaveChk_Out) :: save_out
    type(AP_Job_LoadChk_In) :: load_in
    type(AP_Job_LoadChk_Out) :: load_out
    type(AP_Job_TryRestart_In) :: restart_in
    type(AP_Job_TryRestart_Out) :: restart_out

    call init_error_status(out%status)

    select case (trim(in%operation))
    case ('SAVE', 'save')
      call AP_Job_SaveChk_Structured(ctxJob, save_in, save_out)
      out%status = save_out%status
    case ('LOAD', 'load')
      call AP_Job_LoadChk_Structured(ctxJob, load_in, load_out)
      out%status = load_out%status
    case ('TRY_RESTART', 'try_restart')
      call AP_Job_TryRestart_Structured(ctxJob, restart_in, restart_out)
      out%status = restart_out%status
    case default
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "AP_Job_Unified_Checkpoint_Structured: Invalid operation"
    end select
  end subroutine AP_Job_Unified_Checkpoint_Structured

  subroutine AP_Job_Unified_Execute_Structured(ctxJob, in, out)
    !! Unified job execution interface
    !!
    !! Theory:
    !!   Unified job execution interface supporting operations:
    !!   - 'run': Run entire job
    !!   - 'run_next': Execute next step
    !!   - 'final': Finalize job
    !!   - 'query': Query job summary
    !!
    !! Input:
    !!   ctxJob: Job context (inout)
    !!   in%operation: Operation ('run', 'run_next', 'final', 'query')
    !!
    !! Output:
    !!   out%summary: Job summary (for query)
    !!   out%status: Error status
    
    type(JobCtx), intent(inout) :: ctxJob
    type(AP_Job_Unified_Execute_In), intent(in) :: in
    type(AP_Job_Unified_Execute_Out), intent(out) :: out

    type(AP_Job_Run_In) :: run_in
    type(AP_Job_Run_Out) :: run_out
    type(AP_Job_RunNext_In) :: runnext_in
    type(AP_Job_RunNext_Out) :: runnext_out
    type(AP_Job_Final_In) :: final_in
    type(AP_Job_Final_Out) :: final_out
    type(AP_Job_BuildSum_In) :: buildsum_in
    type(AP_Job_BuildSum_Out) :: buildsum_out

    call init_error_status(out%status)

    select case (trim(in%operation))
    case ('run', 'RUN', 'Run')
      call AP_Job_Run_Structured(ctxJob, run_in, run_out)
      out%status = run_out%status
    case ('run_next', 'RUN_NEXT')
      call AP_Job_RunNext_Structured(ctxJob, runnext_in, runnext_out)
      out%status = runnext_out%status
    case ('final', 'FINAL', 'Finalize')
      call AP_Job_Final_Structured(ctxJob, final_in, final_out)
      out%status = final_out%status
    case ('query', 'QUERY')
      call AP_Job_BuildSum_Structured(ctxJob, buildsum_in, buildsum_out)
      out%summary = buildsum_out%summary
      out%status = buildsum_out%status
    case default
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "AP_Job_Unified_Execute_Structured: Invalid operation"
    end select
  end subroutine AP_Job_Unified_Execute_Structured

  subroutine AP_Job_Unified_Query_Structured(ctxJob, in, out)
    !! Unified job query interface
    !!
    !! Theory:
    !!   Unified job query interface supporting operations:
    !!   - 'STATUS': Query job status (isCompleted, isAborted, currentStep)
    !!   - 'SUMMARY': Query job summary
    !!   - 'PROGRESS': Query job progress (0-1)
    !!
    !! Input:
    !!   ctxJob: Job context (in)
    !!   in%operation: Operation ('STATUS', 'SUMMARY', 'PROGRESS')
    !!
    !! Output:
    !!   out%summary: Job summary (for SUMMARY)
    !!   out%isCompleted: Whether job is completed (for STATUS)
    !!   out%isAborted: Whether job is aborted (for STATUS)
    !!   out%currentStep: Current step index (for STATUS)
    !!   out%progress: Job progress (for PROGRESS)
    !!   out%status: Error status
    
    type(JobCtx), intent(in) :: ctxJob
    type(AP_Job_Unified_Query_In), intent(in) :: in
    type(AP_Job_Unified_Query_Out), intent(out) :: out

    type(AP_Job_QueryStat_In) :: querystat_in
    type(AP_Job_QueryStat_Out) :: querystat_out
    type(AP_Job_BuildSum_In) :: buildsum_in
    type(AP_Job_BuildSum_Out) :: buildsum_out

    call init_error_status(out%status)

    select case (trim(in%operation))
    case ('STATUS', 'status')
      call AP_Job_QueryStat_Structured(ctxJob, querystat_in, querystat_out)
      out%isCompleted = querystat_out%isCompleted
      out%isAborted = querystat_out%isAborted
      out%currentStep = querystat_out%current_step_index
      out%status = querystat_out%status
    case ('SUMMARY', 'summary')
      call AP_Job_BuildSum_Structured(ctxJob, buildsum_in, buildsum_out)
      out%summary = buildsum_out%summary
      out%status = buildsum_out%status
    case ('PROGRESS', 'progress')
      out%progress = ctxJob%summary%progress
      out%status%status_code = IF_STATUS_OK
    case default
      out%status%status_code = IF_STATUS_INVALID
      out%status%message = "AP_Job_Unified_Query_Structured: Invalid operation"
    end select
  end subroutine AP_Job_Unified_Query_Structured

  subroutine AP_Job_Unified_StatusReport_Structured(ctxJob, in, out)
    !! Unified job status report interface
    !!
    !! Theory:
    !!   Unified job status report interface that fills summary from job context.
    !!
    !! Input:
    !!   ctxJob: Job context (in)
    !!   in: No input parameters
    !!
    !! Output:
    !!   out%summary: Job summary
    !!   out%status: Error status
    
    type(JobCtx), intent(in) :: ctxJob
    type(AP_Job_Unified_StatusReport_In), intent(in) :: in
    type(AP_Job_Unified_StatusReport_Out), intent(out) :: out

    type(AP_Job_BuildSum_In) :: buildsum_in
    type(AP_Job_BuildSum_Out) :: buildsum_out

    call init_error_status(out%status)
    call AP_Job_BuildSum_Structured(ctxJob, buildsum_in, buildsum_out)
    out%summary = buildsum_out%summary
    out%status = buildsum_out%status
  end subroutine AP_Job_Unified_StatusReport_Structured

  ! ===================================================================
  ! Legacy Interfaces (deprecated)
  ! ===================================================================
  !> @deprecated Use AP_Job_AddStep_Structured instead
  subroutine AP_Job_AddStep(descJob, descStep)
    type(JobDesc),  intent(inout) :: descJob
    type(StepDesc), intent(in)    :: descStep

    type(AP_Job_AddStep_In) :: in
    type(AP_Job_AddStep_Out) :: out

    in%descStep = descStep
    call AP_Job_AddStep_Structured(descJob, in, out)
  end subroutine AP_Job_AddStep

  !> @deprecated Use AP_Job_AttachMod_Structured instead
  subroutine AP_Job_AttachMod(descJob, descModel)
    type(JobDesc),   intent(inout) :: descJob
    type(ModelDesc), intent(in)    :: descModel

    type(AP_Job_AttachMod_In) :: in
    type(AP_Job_AttachMod_Out) :: out

    in%descModel = descModel
    call AP_Job_AttachMod_Structured(descJob, in, out)
  end subroutine AP_Job_AttachMod

  !> @deprecated Use AP_Job_BindCtx_Structured instead
  subroutine AP_Job_BindCtx(ctxJob, descJob, stateModel, opts, stepRunner)
    type(JobCtx),           intent(out)   :: ctxJob
    type(JobDesc),      target, intent(in)    :: descJob
    type(State_Model),   target, intent(inout) :: stateModel
    type(JobOpts),        intent(in)     :: opts
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: stepRunner

    type(AP_Job_BindCtx_In) :: in
    type(AP_Job_BindCtx_Out) :: out

    in%descJob => descJob
    in%stateModel => stateModel
    in%opts = opts
    if (present(stepRunner)) in%stepRunner => stepRunner
    call AP_Job_BindCtx_Structured(ctxJob, in, out)
  end subroutine AP_Job_BindCtx

  !> @deprecated Use AP_Job_BuildSum_Structured instead
  subroutine AP_Job_BuildSum(ctxJob, summary)
    type(JobCtx),      intent(in)  :: ctxJob
    type(JobSummary), intent(out) :: summary

    type(AP_Job_BuildSum_In) :: in
    type(AP_Job_BuildSum_Out) :: out

    call AP_Job_BuildSum_Structured(ctxJob, in, out)
    summary = out%summary
  end subroutine AP_Job_BuildSum

  !> @deprecated Use AP_Job_Final_Structured instead
  subroutine AP_Job_Final(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_Final_In) :: in
    type(AP_Job_Final_Out) :: out

    call AP_Job_Final_Structured(ctxJob, in, out)
  end subroutine AP_Job_Final

  !> @deprecated Use AP_Job_HandleFail_Structured instead
  subroutine AP_Job_HandleFail(ctxJob, errorCode)
    type(JobCtx), intent(inout) :: ctxJob
    integer(i4),  intent(in)    :: errorCode

    type(AP_Job_HandleFail_In) :: in
    type(AP_Job_HandleFail_Out) :: out

    in%errorCode = errorCode
    call AP_Job_HandleFail_Structured(ctxJob, in, out)
  end subroutine AP_Job_HandleFail

  !> @deprecated Use AP_Job_InitDesc_Structured instead
  subroutine AP_Job_InitDesc(descJob)
    type(JobDesc), intent(inout) :: descJob

    type(AP_Job_InitDesc_In) :: in
    type(AP_Job_InitDesc_Out) :: out

    call AP_Job_InitDesc_Structured(descJob, in, out)
  end subroutine AP_Job_InitDesc

  !> @deprecated Use AP_Job_LoadChk_Structured instead
  subroutine AP_Job_LoadChk(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_LoadChk_In) :: in
    type(AP_Job_LoadChk_Out) :: out

    call AP_Job_LoadChk_Structured(ctxJob, in, out)
  end subroutine AP_Job_LoadChk

  !> @deprecated Use AP_Job_PrepEnv_Structured instead
  subroutine AP_Job_PrepEnv(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_PrepEnv_In) :: in
    type(AP_Job_PrepEnv_Out) :: out

    call AP_Job_PrepEnv_Structured(ctxJob, in, out)
  end subroutine AP_Job_PrepEnv

  !> @deprecated Use AP_Job_QueryStat_Structured instead
  subroutine AP_Job_QueryStat(ctxJob, isCompleted, isAborted, current_step_index)
    type(JobCtx), intent(in)   :: ctxJob
    logical,      intent(out) :: isCompleted
    logical,      intent(out) :: isAborted
    integer(i4),  intent(out) :: current_step_index

    type(AP_Job_QueryStat_In) :: in
    type(AP_Job_QueryStat_Out) :: out

    call AP_Job_QueryStat_Structured(ctxJob, in, out)
    isCompleted = out%isCompleted
    isAborted = out%isAborted
    current_step_index = out%current_step_index
  end subroutine AP_Job_QueryStat

  !> @deprecated Use AP_Job_Run_Structured instead
  subroutine AP_Job_Run(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_Run_In) :: in
    type(AP_Job_Run_Out) :: out

    call AP_Job_Run_Structured(ctxJob, in, out)
  end subroutine AP_Job_Run

  !> @deprecated Use AP_Job_RunNext_Structured instead
  subroutine AP_Job_RunNext(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_RunNext_In) :: in
    type(AP_Job_RunNext_Out) :: out

    call AP_Job_RunNext_Structured(ctxJob, in, out)
  end subroutine AP_Job_RunNext

  !> @deprecated Use AP_Job_SaveChk_Structured instead
  subroutine AP_Job_SaveChk(ctxJob)
    type(JobCtx), intent(in) :: ctxJob

    type(AP_Job_SaveChk_In) :: in
    type(AP_Job_SaveChk_Out) :: out

    call AP_Job_SaveChk_Structured(ctxJob, in, out)
  end subroutine AP_Job_SaveChk

  !> @deprecated Use AP_Job_SetOpts_Structured instead
  subroutine AP_Job_SetOpts(ctxJob, opts)
    type(JobCtx),  intent(inout) :: ctxJob
    type(JobOpts), intent(in)    :: opts

    type(AP_Job_SetOpts_In) :: in
    type(AP_Job_SetOpts_Out) :: out

    in%opts = opts
    call AP_Job_SetOpts_Structured(ctxJob, in, out)
  end subroutine AP_Job_SetOpts

  !> @deprecated Use AP_Job_TryRestart_Structured instead
  subroutine AP_Job_TryRestart(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob

    type(AP_Job_TryRestart_In) :: in
    type(AP_Job_TryRestart_Out) :: out

    call AP_Job_TryRestart_Structured(ctxJob, in, out)
  end subroutine AP_Job_TryRestart

  !> @deprecated Use AP_Job_Unified_OptionsDefault_Structured instead
  subroutine AP_Job_Un_OptionsDefault(opts)
    type(JobOpts), intent(out) :: opts

    type(AP_Job_Unified_OptionsDefault_In) :: in
    type(AP_Job_Unified_OptionsDefault_Out) :: out

    call AP_Job_Unified_OptionsDefault_Structured(in, out)
    opts = out%opts
  end subroutine AP_Job_Unified_OptionsDefault

  !> @deprecated Use AP_Job_Unified_OptionsValidate_Structured instead
  subroutine AP_Job_Un_OptionsValidate(opts, is_valid, status)
    type(JobOpts), intent(in) :: opts
    logical, intent(out), optional :: is_valid
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_OptionsValidate_In) :: in
    type(AP_Job_Unified_OptionsValidate_Out) :: out

    in%opts = opts
    call AP_Job_Unified_OptionsValidate_Structured(in, out)
    if (present(is_valid)) is_valid = out%is_valid
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_OptionsValidate

  !> @deprecated Use AP_Job_Unified_Cfg_Structured instead
  subroutine AP_Job_Unified_Cfg(ctxJob, descJob, stateModel, opts, step_runner, status)
    type(JobCtx), intent(out) :: ctxJob
    type(JobDesc), target, intent(in) :: descJob
    type(State_Model), target, intent(inout) :: stateModel
    type(JobOpts), intent(in) :: opts
    procedure(UF_Job_StepRunner_Ifc), optional :: step_runner
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_Cfg_In) :: in
    type(AP_Job_Unified_Cfg_Out) :: out

    in%descJob => descJob
    in%stateModel => stateModel
    in%opts = opts
    if (present(step_runner)) in%step_runner => step_runner
    call AP_Job_Unified_Cfg_Structured(ctxJob, in, out)
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_Cfg

  !> @deprecated Use AP_Job_Unified_Checkpoint_Structured instead
  subroutine AP_Job_Unified_Checkpoint(operation, ctxJob, status)
    character(len=*), intent(in) :: operation
    type(JobCtx), intent(inout) :: ctxJob
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_Checkpoint_In) :: in
    type(AP_Job_Unified_Checkpoint_Out) :: out

    in%operation = trim(operation)
    call AP_Job_Unified_Checkpoint_Structured(ctxJob, in, out)
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_Checkpoint

  !> @deprecated Use AP_Job_Unified_Execute_Structured instead
  subroutine AP_Job_Unified_Execute(ctxJob, operation, summary, status)
    type(JobCtx), intent(inout) :: ctxJob
    character(len=*), intent(in) :: operation
    type(JobSummary), intent(out), optional :: summary
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_Execute_In) :: in
    type(AP_Job_Unified_Execute_Out) :: out

    in%operation = trim(operation)
    call AP_Job_Unified_Execute_Structured(ctxJob, in, out)
    if (present(summary)) summary = out%summary
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_Execute

  !> @deprecated Use AP_Job_Unified_Query_Structured instead
  subroutine AP_Job_Unified_Query(operation, ctxJob, summary, isCompleted, isAborted, currentStep, progress, status)
    character(len=*), intent(in) :: operation
    type(JobCtx), intent(in) :: ctxJob
    type(JobSummary), intent(out), optional :: summary
    logical, intent(out), optional :: isCompleted
    logical, intent(out), optional :: isAborted
    integer(i4), intent(out), optional :: currentStep
    real(wp), intent(out), optional :: progress
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_Query_In) :: in
    type(AP_Job_Unified_Query_Out) :: out

    in%operation = trim(operation)
    call AP_Job_Unified_Query_Structured(ctxJob, in, out)
    if (present(summary)) summary = out%summary
    if (present(isCompleted)) isCompleted = out%isCompleted
    if (present(isAborted)) isAborted = out%isAborted
    if (present(currentStep)) currentStep = out%currentStep
    if (present(progress)) progress = out%progress
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_Query

  !> @deprecated Use AP_Job_Unified_StatusReport_Structured instead
  subroutine AP_Job_Unified_StatusReport(ctxJob, summary, status)
    type(JobCtx), intent(in) :: ctxJob
    type(JobSummary), intent(out) :: summary
    integer(i4), intent(out), optional :: status

    type(AP_Job_Unified_StatusReport_In) :: in
    type(AP_Job_Unified_StatusReport_Out) :: out

    call AP_Job_Unified_StatusReport_Structured(ctxJob, in, out)
    summary = out%summary
    if (present(status)) status = out%status%status_code
  end subroutine AP_Job_Unified_StatusReport

  subroutine AP_Job_UnifiedCfg(ctxJob, descJob, stateModel, opts, step_runner, status)
    type(JobCtx), intent(out) :: ctxJob
    type(JobDesc), target, intent(in) :: descJob
    type(State_Model), target, intent(inout) :: stateModel
    type(JobOpts), intent(in) :: opts
    procedure(UF_Job_StepRunner_Ifc), optional :: step_runner
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_Cfg(ctxJob, descJob, stateModel, opts, step_runner, status)
  end subroutine AP_Job_UnifiedCfg

  subroutine AP_Job_UnifiedChkpt(operation, ctxJob, status)
    character(len=*), intent(in) :: operation
    type(JobCtx), intent(inout) :: ctxJob
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_Checkpoint(operation, ctxJob, status)
  end subroutine AP_Job_UnifiedChkpt

  subroutine AP_Job_UnifiedExecute(ctxJob, operation, summary, status)
    type(JobCtx), intent(inout) :: ctxJob
    character(len=*), intent(in) :: operation
    type(JobSummary), intent(out), optional :: summary
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_Execute(ctxJob, operation, summary, status)
  end subroutine AP_Job_UnifiedExecute

  subroutine AP_Job_UnifiedOptsDef(opts)
    type(JobOpts), intent(out) :: opts
    call AP_Job_Unified_OptionsDefault(opts)
  end subroutine AP_Job_UnifiedOptsDef

  subroutine AP_Job_UnifiedOptsValid(opts, is_valid, status)
    type(JobOpts), intent(in) :: opts
    logical, intent(out), optional :: is_valid
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_OptionsValidate(opts, is_valid, status)
  end subroutine AP_Job_UnifiedOptsValid

  subroutine AP_Job_UnifiedQuery(operation, ctxJob, summary, isCompleted, isAborted, currentStep, progress, status)
    character(len=*), intent(in) :: operation
    type(JobCtx), intent(in) :: ctxJob
    type(JobSummary), intent(out), optional :: summary
    logical, intent(out), optional :: isCompleted
    logical, intent(out), optional :: isAborted
    integer(i4), intent(out), optional :: currentStep
    real(wp), intent(out), optional :: progress
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_Query(operation, ctxJob, summary, isCompleted, isAborted, currentStep, progress, status)
  end subroutine AP_Job_UnifiedQuery

  subroutine AP_Job_UnifiedStatusReport(ctxJob, summary, status)
    type(JobCtx), intent(in) :: ctxJob
    type(JobSummary), intent(out) :: summary
    integer(i4), intent(out), optional :: status
    call AP_Job_Unified_StatusReport(ctxJob, summary, status)
  end subroutine AP_Job_UnifiedStatusReport

  subroutine RT_Job_AddStep(descJob, descStep)
    type(JobDesc),  intent(inout) :: descJob
    type(StepDesc), intent(in)    :: descStep
    call AP_Job_AddStep(descJob, descStep)
  end subroutine RT_Job_AddStep

  subroutine RT_Job_AttachMod(descJob, descModel)
    type(JobDesc),   intent(inout) :: descJob
    type(ModelDesc), intent(in)    :: descModel
    call AP_Job_AttachMod(descJob, descModel)
  end subroutine RT_Job_AttachMod

  subroutine RT_Job_BindCtx(ctxJob, descJob, stateModel, opts, stepRunner)
    type(JobCtx),           intent(out)   :: ctxJob
    type(JobDesc),      target, intent(in)    :: descJob
    type(State_Model),   target, intent(inout) :: stateModel
    type(JobOpts),        intent(in)     :: opts
    procedure(UF_Job_StepRunner_Ifc), pointer, optional :: stepRunner
    call AP_Job_BindCtx(ctxJob, descJob, stateModel, opts, stepRunner)
  end subroutine RT_Job_BindCtx

  subroutine RT_Job_BuildSum(ctxJob, summary)
    type(JobCtx),      intent(in)  :: ctxJob
    type(JobSummary), intent(out) :: summary
    call AP_Job_BuildSum(ctxJob, summary)
  end subroutine RT_Job_BuildSum

  subroutine RT_Job_Final(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_Final(ctxJob)
  end subroutine RT_Job_Final

  subroutine RT_Job_HandleFail(ctxJob, errorCode)
    type(JobCtx), intent(inout) :: ctxJob
    integer(i4),  intent(in)    :: errorCode
    call AP_Job_HandleFail(ctxJob, errorCode)
  end subroutine RT_Job_HandleFail

  subroutine RT_Job_InitDesc(descJob)
    type(JobDesc), intent(inout) :: descJob
    call AP_Job_InitDesc(descJob)
  end subroutine RT_Job_InitDesc

  subroutine RT_Job_LoadChk(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_LoadChk(ctxJob)
  end subroutine RT_Job_LoadChk

  subroutine RT_Job_PrepEnv(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_PrepEnv(ctxJob)
  end subroutine RT_Job_PrepEnv

  subroutine RT_Job_QueryStat(ctxJob, isCompleted, isAborted, current_step_index)
    type(JobCtx), intent(in)   :: ctxJob
    logical,      intent(out) :: isCompleted
    logical,      intent(out) :: isAborted
    integer(i4),  intent(out) :: current_step_index
    call AP_Job_QueryStat(ctxJob, isCompleted, isAborted, current_step_index)
  end subroutine RT_Job_QueryStat

  subroutine RT_Job_Run(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_Run(ctxJob)
  end subroutine RT_Job_Run

  subroutine RT_Job_RunNext(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_RunNext(ctxJob)
  end subroutine RT_Job_RunNext

  subroutine RT_Job_SaveChk(ctxJob)
    type(JobCtx), intent(in) :: ctxJob
    call AP_Job_SaveChk(ctxJob)
  end subroutine RT_Job_SaveChk

  subroutine RT_Job_SetOpts(ctxJob, opts)
    type(JobCtx),  intent(inout) :: ctxJob
    type(JobOpts), intent(in)    :: opts
    call AP_Job_SetOpts(ctxJob, opts)
  end subroutine RT_Job_SetOpts

  subroutine RT_Job_TryRestart(ctxJob)
    type(JobCtx), intent(inout) :: ctxJob
    call AP_Job_TryRestart(ctxJob)
  end subroutine RT_Job_TryRestart
end module AP_Job_Mgr