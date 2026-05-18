!===============================================================================
! MODULE: AP_UI_JobMgr
! LAYER:  L6_AP
! DOMAIN: UI
! ROLE:   Mgr — job manager for UI layer
! BRIEF:  Job creation, submission and monitoring through UI interface.
!===============================================================================

MODULE AP_UI_JobMgr
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Log_Logger, only: g_if_logger, IF_LogConfig, LOG_OUTPUT_BOTH
  USE IF_Err_Def, only: LOG_LEVEL_INFO, LOG_LEVEL_DEBUG
  USE IF_Prec_Core, only: i4, wp
  USE MD_Model_Tree, only: ModelTree
  USE AP_UI_INP_Core, only: INPGenerator
  USE AP_UI_TreeMgr, only: TreeMgr

  implicit none
  private
  
  public :: RT_JobMgr
  public :: UIJob
  public :: RT_JobMgr_Create
  public :: RT_JobMgr_Submit
  public :: RT_JobMgr_GetStat
  public :: RT_JobMgr_Cancel
  public :: RT_JobMgr_GetLog
  
  ! Job status constants
  integer(i4), parameter, public :: JOB_STATUS_PENDING = 1_i4      ! Pending status
  integer(i4), parameter, public :: JOB_STATUS_RUNNING = 2_i4       ! Running status
  integer(i4), parameter, public :: JOB_STATUS_COMPLETELETE = 3_i4  ! Completed status
  integer(i4), parameter, public :: JOB_STATUS_FAILEDED = 4_i4      ! Failed status
  integer(i4), parameter, public :: JOB_STATUS_CANCELLEDELLED = 5_i4 ! Cancelled status
  
  !=============================================================================
  !> @brief UI job type
  !! @details Represents a job with status, progress, and file references
  !!   Theory: Job with ID, name, files, status, progress tracking (steps, increments, time)
  !=============================================================================
  type, public :: UIJob
    integer(i4) :: job_id = 0_i4                    ! Job ID ??
    character(len=64) :: job_name = ''              ! Job name
    character(len=256) :: inp_file = ''            ! INP file path
    character(len=256) :: model_file = ''           ! Model file path
    character(len=256) :: log_file = ''             ! Log file path
    character(len=256) :: result_file = ''         ! Result file path
    integer(i4) :: status = JOB_STATUS_PENDING      ! Job status ??
    real(wp) :: progress = 0.0_wp                   ! Progress p ?[0,1] ??
    integer(i4) :: current_step = 0_i4               ! Current step ??
    integer(i4) :: total_steps = 0_i4               ! Total steps n_steps ??
    integer(i4) :: current_increment = 0_i4          ! Current increment ??
    integer(i4) :: total_increments = 0_i4           ! Total increments n_inc ??
    real(wp) :: start_time = 0.0_wp                 ! Start time t_start ??
    real(wp) :: end_time = 0.0_wp                    ! End time t_end ??
    type(ModelTree), pointer :: model => null()     ! Model tree pointer
    logical :: auto_generate_i = .true.             ! Auto-generate INP flag
  end type UIJob
  
  !=============================================================================
  !> @brief Job manager type
  !! @details Manages job creation, submission, and monitoring
  !!   Theory: Manager with tree reference, INP generator, job array, job tracking
  !=============================================================================
  type, public :: RT_JobMgr
    type(TreeMgr), pointer :: tree_mgr => null()    ! Tree manager reference
    type(INPGenerator) :: inp_generator              ! INP generator instance
    type(UIJob), allocatable :: jobs(:)             ! Job array
    integer(i4) :: num_jobs = 0_i4                  ! Number of jobs n_jobs ??
    integer(i4) :: next_job_id = 1_i4               ! Next job ID ??
    LOGICAL :: init = .false.                       ! Initialization flag
  contains
    procedure, public :: Init => RT_JobMgr_Init
    procedure, public :: CreateJob => RT_JobMgr_Create
    procedure, public :: SubmitJob => RT_JobMgr_Submit
    procedure, public :: GetJobStatus => RT_JobMgr_GetStat
    procedure, public :: CancelJob => RT_JobMgr_Cancel
    procedure, public :: GetJobLog => RT_JobMgr_GetLog
    procedure, public :: MonitorJob => RT_JobMgr_Mon
    procedure, public :: GetJob => RT_JobMgr_Get
    procedure, public :: GetJobByName => RT_JobMgr_GetByName
    procedure, public :: UpdateJobProgress => RT_JobMgr_UpdateProg
  end type RT_JobMgr
  
contains
  
  !=============================================================================
  !> @brief Initialize job manager (legacy interface)
  !! @details Sets up job manager with tree manager reference
  !! @param[inout] this Job manager instance
  !! @param[in] tree_mgr Tree manager reference
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !=============================================================================
  subroutine RT_JobMgr_Init(this, tree_mgr, status)
    class(RT_JobMgr), intent(inout) :: this
    type(TreeMgr), intent(in), target :: tree_mgr
    type(ErrorStatusType), intent(out), optional :: status
    
    if (present(status)) call init_error_status(status)
    
    this%tree_mgr => tree_mgr
    allocate(this%jobs(100))
    this%num_jobs = 0_i4
    this%next_job_id = 1_i4
    this%init = .true.
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_JobMgr_Init
  
  !=============================================================================
  !> @brief Create job (legacy interface)
  !! @details Creates a new job from model tree
  !! @param[inout] this Job manager instance
  !! @param[in] job_name Job name
  !! @param[in] model_tree Model tree reference
  !! @param[in] inp_file INP file path (optional)
  !! @param[out] job_id Created job ID ??
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !!   Theory: Create job with name, model tree, optional INP file path
  !=============================================================================
  subroutine RT_JobMgr_Create(this, job_name, model_tree, inp_file, &
                                     job_id, status)
    class(RT_JobMgr), intent(inout) :: this
    character(len=*), intent(in) :: job_name
    type(ModelTree), intent(in), target :: model_tree
    character(len=*), intent(in), optional :: inp_file
    integer(i4), intent(out) :: job_id
    type(ErrorStatusType), intent(out), optional :: status
    
    type(UIJob), pointer :: job => null()
    type(ErrorStatusType) :: local_status
    character(len=256) :: generated_inp_f
    integer(i4) :: n
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    if (.not. this%init) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'JobMgr not initialized'
      end if
      return
    end if
    
    ! Find available slot
    n = this%num_jobs + 1_i4
    if (n > size(this%jobs)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Maximum number of jobs reached'
      end if
      return
    end if
    
    job => this%jobs(n)
    job%job_id = this%next_job_id
    this%next_job_id = this%next_job_id + 1_i4
    job%job_name = job_name
    job%model => model_tree
    job%status = JOB_STATUS_PENDING
    job%progress = 0.0_wp
    
    ! Generate INP file if needed
    if (present(inp_file)) then
      job%inp_file = inp_file
      job%auto_generate_i = .false.
    else
      write(generated_inp_f, '(A,A,A)') trim(job_name), '_', 'model.inp'
      job%inp_file = generated_inp_f
      job%auto_generate_i = .true.
      
      ! Generate INP file
      call this%inp_generator%Generate(model_tree, job%inp_file, local_status)
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if
    end if
    
    ! Set log file
    write(job%log_file, '(A,A,A)') trim(job_name), '_', 'job.log'
    write(job%result_file, '(A,A,A)') trim(job_name), '_', 'results.odb'
    
    this%num_jobs = n
    job_id = job%job_id
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_JobMgr_Create
  
  ! ===================================================================
  ! Submit Job
  ! ===================================================================
  
  !=============================================================================
  !> @brief Submit job (legacy interface)
  !! @details Submits a job to runtime layer for execution
  !! @param[inout] this Job manager instance
  !! @param[in] job_id Job ID ??
  !! @param[out] status Error status (optional)
  !! @note Legacy interface - parameters should be encapsulated in structured types
  !!   Theory: Submit job to runtime layer, change status to RUNNING
  !=============================================================================
  subroutine RT_JobMgr_Submit(this, job_id, status)
    class(RT_JobMgr), intent(inout) :: this
    integer(i4), intent(in) :: job_id
    type(ErrorStatusType), intent(out), optional :: status
    
    type(UIJob), pointer :: job => null()
    type(ErrorStatusType) :: local_status
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    ! Get job
    job => this%GetJob(job_id)
    if (.not. associated(job)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,I0)') 'Job not found: ', job_id
      end if
      return
    end if
    
    ! Check job status
    if (job%status /= JOB_STATUS_PENDING) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Job is not in pending status'
      end if
      return
    end if
    
    ! Generate INP if needed
    if (job%auto_generate_i) then
      call this%inp_generator%Generate(job%model, job%inp_file, local_status)
      if (local_status%status_code /= IF_STATUS_OK) then
        if (present(status)) status = local_status
        return
      end if
    end if
    
    ! Submit to Runtime layer
    ! Note: In a production system, this would be asynchronous
    ! For now, we mark the job as running and record start time
    ! Actual job execution would be handled by a separate thread/process
    
    ! Get current time using CPU_TIME (wall-clock time)
    call CPU_TIME(job%start_time)
    
    ! Set job status to running
    job%status = JOB_STATUS_RUNNING
    
    ! Note: Actual job submission to Runtime layer would be:
    !   type(UF_Job) :: rt_job
    !   type(UF_RT_JobStatus) :: rt_status
    !   rt_job%name = job%job_name
    !   rt_job%model => job%model
    !   call RT_RunJob(rt_job, rt_status)
    !   ! Store rt_job handle for later cancellation/monitoring
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_JobMgr_Submit
  
  ! ===================================================================
  ! Get Job Status
  ! ===================================================================
  
  function RT_JobMgr_GetStat(this, job_id) result(status_code)
    class(RT_JobMgr), intent(in) :: this
    integer(i4), intent(in) :: job_id
    integer(i4) :: status_code
    
    type(UIJob), pointer :: job => null()
    
    status_code = JOB_STATUS_PENDING
    
    job => this%GetJob(job_id)
    if (associated(job)) then
      status_code = job%status
    end if
  end function RT_JobMgr_GetStat
  
  ! ===================================================================
  ! Cancel Job
  ! ===================================================================
  
  subroutine RT_JobMgr_Cancel(this, job_id, status)
    class(RT_JobMgr), intent(inout) :: this
    integer(i4), intent(in) :: job_id
    type(ErrorStatusType), intent(out), optional :: status
    
    type(UIJob), pointer :: job => null()
    
    if (present(status)) call init_error_status(status)
    
    ! Get job
    job => this%GetJob(job_id)
    if (.not. associated(job)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,I0)') 'Job not found: ', job_id
      end if
      return
    end if
    
    ! Cancel job
    if (job%status == JOB_STATUS_RUNNING) then
      ! Note: In a production system, this would signal the Runtime layer
      ! to stop the job gracefully. For now, we mark it as cancelled.
      ! Actual cancellation would require:
      !   - A job handle/reference to the running job
      !   - A cancellation mechanism in RT_Driver_Core
      !   - Signal handling or thread interruption
      
      job%status = JOB_STATUS_CANCELLED
      
      ! Get current time for end time
      call CPU_TIME(job%end_time)
    else
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        status%message = 'Job is not running'
      end if
      return
    end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_JobMgr_Cancel
  
  ! ===================================================================
  ! Get Job Log
  ! ===================================================================
  
  function RT_JobMgr_GetLog(this, job_id) result(log_content)
    class(RT_JobMgr), intent(in) :: this
    integer(i4), intent(in) :: job_id
    character(len=:), allocatable :: log_content
    
    type(UIJob), pointer :: job => null()
    integer(i4) :: unit_num, ios
    character(len=1024) :: line
    
    log_content = ''
    
    ! Get job
    job => this%GetJob(job_id)
    if (.not. associated(job)) return
    if (len_trim(job%log_file) == 0_i4) return
    
    ! Read log file
    open(newunit=unit_num, file=trim(job%log_file), status='old', &
         action='read', form='formatted', iostat=ios)
    if (ios /= 0_i4) return
    
    ! Read all lines
    do
      read(unit_num, '(A)', iostat=ios) line
      if (ios /= 0_i4) exit
      log_content = log_content // trim(line) // new_line('A')
    end do
    
    close(unit_num)
  end function RT_JobMgr_GetLog

  ! ===================================================================
  ! Monitor Job
  ! ===================================================================
  
  subroutine RT_JobMgr_Mon(this, job_id, status)
    class(RT_JobMgr), intent(inout) :: this
    integer(i4), intent(in) :: job_id
    type(ErrorStatusType), intent(out), optional :: status
    
    type(UIJob), pointer :: job => null()
    type(ErrorStatusType) :: local_status
    logical :: log_ok
    character(len=256) :: msg
    integer(i4) :: rt_status_code
    
    if (present(status)) call init_error_status(status)
    call init_error_status(local_status)
    
    ! Get job
    job => this%GetJob(job_id)
    if (.not. associated(job)) then
      if (present(status)) then
        status%status_code = IF_STATUS_INVALID
        write(status%message, '(A,I0)') 'Job not found: ', job_id
      end if
      return
    end if
    
    ! Only monitor running jobs
    if (job%status /= JOB_STATUS_RUNNING) then
      if (present(status)) status%status_code = IF_STATUS_OK
      return
    end if
    
    ! Init logging if needed
    if (.not. g_if_logger%is_init .and. len_trim(job%log_file) > 0) then
      type(IF_LogConfig) :: log_config
      log_config%min_level = LOG_LEVEL_INFO
      log_config%output_target = LOG_OUTPUT_BOTH
      log_config%log_file = trim(job%log_file)
      log_config%append_mode = .false.
      log_config%include_timestamp = .true.
      log_config%include_module = .true.
      log_config%buffer_size = 1000
      log_config%auto_flush = .true.
      call g_if_logger%Init(log_config, local_status)
      log_ok = (local_status%status_code == IF_STATUS_OK)
    end if
    
    ! Query Runtime layer for actual job status
    ! In a production system, this would query RT_Driver_Core or a job manager
    ! For now, we check log file and simulate progress updates
    
    ! Update progress based on log file (if available)
    if (len_trim(job%log_file) > 0) then
      ! Try to read progress from log file
      ! Parse log file for step/increment information
      call ParseLogFileProgress(job%log_file, job%current_step, &
                                job%total_steps, job%current_increment, &
                                job%total_increments, job%progress, &
                                job%status)
    end if
    
    ! Log monitoring activity
    if (g_if_logger%is_init) then
      write(msg, '(A,I0,A,F5.2)') 'Monitoring job ', job_id, ', progress: ', job%progress * 100.0_wp
      call g_if_logger%Debug(trim(msg), 'JobMgr', status=local_status)
    end if
    
    ! Update job status based on Runtime layer response
    ! Note: In a real implementation, we would query RT_Driver_Core for job status
    ! For now, we simulate status updates based on progress
    
    ! Integrate with Runtime layer to get actual job status
    ! In production, this would query RT_Driver_Core for job status
    ! For now, we check log file and update status accordingly
    
    ! Check if job has completed
    if (job%progress >= 1.0_wp) then
      ! Job completed
      job%status = JOB_STATUS_COMPLETE
      call CPU_TIME(job%end_time)
    else if (job%progress > 0.0_wp) then
      ! Job is still running
      job%status = JOB_STATUS_RUNNING
    end if
    
    ! Note: In production, we would query Runtime layer:
    !   type(UF_RT_JobStatus) :: rt_status
    !   call GetJobStatus(job_handle, rt_status)
    !   job%progress = rt_status%nStepsCompleted / real(rt_status%nStepsTotal, wp)
    !   job%current_step = rt_status%nStepsCompleted
    !   job%current_increme = rt_status%nIncsConverged
    !   if (rt_status%code == UF_JobStatus_Success) then
    !     job%status = JOB_STATUS_COMPLETE
    !   else if (rt_status%code == UF_JobStatus_NonConvergence) then
    !     job%status = JOB_STATUS_FAILED
    !   end if
    
    if (present(status)) status%status_code = IF_STATUS_OK
  end subroutine RT_JobMgr_Mon

  ! ===================================================================
  ! Get Job
  ! ===================================================================
  
  function RT_JobMgr_Get(this, job_id) result(job_ptr)
    class(RT_JobMgr), intent(in) :: this
    integer(i4), intent(in) :: job_id
    type(UIJob), pointer :: job_ptr
    
    integer(i4) :: i
    
    nullify(job_ptr)
    
    do i = 1, this%num_jobs
      if (this%jobs(i)%job_id == job_id) then
        job_ptr => this%jobs(i)
        return
      end if
    end do
  end function RT_JobMgr_Get
  
  ! ===================================================================
  ! Get Job by Name
  ! ===================================================================
  
  function RT_JobMgr_GetByName(this, job_name) result(job_ptr)
    class(RT_JobMgr), intent(in) :: this
    character(len=*), intent(in) :: job_name
    type(UIJob), pointer :: job_ptr
    
    integer(i4) :: i
    
    nullify(job_ptr)
    
    do i = 1, this%num_jobs
      if (trim(this%jobs(i)%job_name) == trim(job_name)) then
        job_ptr => this%jobs(i)
        return
      end if
    end do
  end function RT_JobMgr_GetByName
  
  ! ===================================================================
  ! Update Job Progress
  ! ===================================================================
  
  subroutine RT_JobMgr_UpdateProg(this, job_id, progress, &
                                             current_step, current_increment)
    class(RT_JobMgr), intent(inout) :: this
    integer(i4), intent(in) :: job_id
    real(wp), intent(in), optional :: progress
    integer(i4), intent(in), optional :: current_step, current_increment
    
    type(UIJob), pointer :: job => null()
    
    job => this%GetJob(job_id)
    if (.not. associated(job)) return
    
    if (present(progress)) job%progress = progress
    if (present(current_step)) job%current_step = current_step
    if (present(current_increment)) job%current_increment = current_increment
  end subroutine RT_JobMgr_UpdateProg
  
  ! ===================================================================
  ! Parse Log File for Progress Information
  ! ===================================================================
  
  subroutine ParseLogFileProgress(log_file, current_step, total_steps, &
                                  current_increment, total_increments, progress, status)
    character(len=*), intent(in) :: log_file
    integer(i4), intent(inout) :: current_step, total_steps
    integer(i4), intent(inout) :: current_increment, total_increments
    real(wp), intent(inout) :: progress
    integer(i4), intent(inout) :: status
    
    integer(i4) :: unit_num, ios
    character(len=1024) :: line
    integer(i4) :: step_num, inc_num
    logical :: found_step, found_inc
    
    current_step = 0_i4
    total_steps = 0_i4
    current_increment = 0_i4
    total_increments = 0_i4
    progress = 0.0_wp
    
    ! Try to open log file
    open(newunit=unit_num, file=trim(log_file), status='old', &
         action='read', form='formatted', iostat=ios)
    if (ios /= 0_i4) return
    
    found_step = .false.
    found_inc = .false.
    
    ! Parse log file for step/increment information
    ! Look for patterns like "Step 1", "Increment 1", "Completed step 1 of 3", etc.
    do
      read(unit_num, '(A)', iostat=ios) line
      if (ios /= 0_i4) exit
      
      ! Look for step information
      if (index(line, 'Step') > 0 .or. index(line, 'STEP') > 0) then
        ! Try to extract step number
        ! Pattern: "Step 1", "STEP 1", "Completed step 1 of 3"
        if (index(line, 'of') > 0) then
          ! Extract total steps from "step X of Y"
          read(line(index(line, 'of')+2:), *, iostat=ios) total_steps
          if (ios == 0_i4 .and. total_steps > 0_i4) found_step = .true.
        end if
        ! Extract current step
        if (index(line, 'Step') > 0) then
          read(line(index(line, 'Step')+4:), *, iostat=ios) step_num
          if (ios == 0_i4 .and. step_num > 0_i4) then
            current_step = step_num
            found_step = .true.
          end if
        end if
      end if
      
      ! Look for increment information
      if (index(line, 'Increment') > 0 .or. index(line, 'INCREMENT') > 0) then
        ! Extract increment number
        if (index(line, 'Increment') > 0) then
          read(line(index(line, 'Increment')+9:), *, iostat=ios) inc_num
          if (ios == 0_i4 .and. inc_num > 0_i4) then
            current_increment = inc_num
            found_inc = .true.
          end if
        end if
      end if
      
      ! Look for completion messages
      if (index(line, 'COMPLETED') > 0 .or. index(line, 'Completed') > 0) then
        if (found_step .and. total_steps > 0_i4) then
          progress = real(current_step, wp) / real(total_steps, wp)
        end if
      end if
      
      ! Check for completion indicators
      if (index(line, 'JOB COMPLETED') > 0 .or. &
          index(line, 'ANALYSIS COMPLETE') > 0 .or. &
          index(line, 'SUCCESSFULLY COMPLETED') > 0) then
        status = JOB_STATUS_COMPLETE
        progress = 1.0_wp
      end if
      
      ! Check for error indicators
      if (index(line, 'ERROR') > 0 .or. &
          index(line, 'FAILED') > 0 .or. &
          index(line, 'ABORTED') > 0) then
        status = JOB_STATUS_FAILED
      end if
    end do
    
    close(unit_num)
    
    ! Calculate progress if we have step information
    if (found_step .and. total_steps > 0_i4) then
      progress = min(real(current_step, wp) / real(total_steps, wp), 1.0_wp)
    else if (found_inc .and. total_increments > 0_i4) then
      progress = min(real(current_increment, wp) / real(total_increments, wp), 1.0_wp)
    end if
  end subroutine ParseLogFileProgress
  
end MODULE AP_UI_JobMgr