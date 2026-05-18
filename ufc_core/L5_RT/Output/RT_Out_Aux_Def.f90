!===============================================================================
! MODULE: RT_Out_Aux_Def
! LAYER:  L5_RT
! DOMAIN: Output
! ROLE:   Aux Def — auxiliary TYPE definitions for Output step-level algorithm
!         control and iteration-level I/O algorithm, bridging the P1 gap
!         identified in Procedure_Algorithm_L3L4L5_synthesis.md §C.
! BRIEF:  RT_Out_Stp_Ctl_Algo (步级输出频率/触发控制) + RT_Out_Itr_Algo
!         (迭代级缓冲/压缩/IO控制), aligned with PH_Mat_Stp_Ctl_Algo /
!         PH_LoadBC_Stp_Ctl_Algo / MD_Cont_Stp_Ctl_Algo pattern.
!===============================================================================
MODULE RT_Out_Aux_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE RT_Out_Def,      ONLY: RT_OUT_TRIG_INCREMENT, RT_OUT_TRIG_TIME, &
                              RT_OUT_TRIG_STEP_END, RT_OUT_TRIG_ANALYSIS_END
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! RT_Out_Stp_Ctl_Algo — Step-level output frequency & trigger control
  ! [Phase:Stp|Verb:Ctl]
  !
  ! Controls when output is triggered (increment-based / time-based /
  ! step-end / analysis-end) and at what frequency.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_Out_Stp_Ctl_Algo
    ! --- Field frequency ---
    INTEGER(i4) :: field_freq_incr = 1_i4      ! Field output every N increments
    REAL(wp)    :: field_freq_time = 0.0_wp     ! Field output time interval (0=off)

    ! --- History frequency ---
    INTEGER(i4) :: hist_freq_incr  = 1_i4       ! History output every N increments
    REAL(wp)    :: hist_freq_time  = 0.0_wp     ! History output time interval

    ! --- Trigger configuration ---
    INTEGER(i4) :: trigger_type          = RT_OUT_TRIG_INCREMENT
    LOGICAL     :: trigger_at_step_end   = .TRUE.    ! Always write at step end
    LOGICAL     :: trigger_at_analysis_end = .TRUE.  ! Always write at analysis end

    ! --- Last-chance / override ---
    LOGICAL     :: force_field_write     = .FALSE.   ! Override frequency check
    LOGICAL     :: force_hist_write      = .FALSE.   ! Override frequency check
    LOGICAL     :: suppress_all_output   = .FALSE.   ! Suppress all output
  END TYPE RT_Out_Stp_Ctl_Algo

  ! ==========================================================================
  ! RT_Out_Itr_Algo — Iteration-level I/O algorithm control
  ! [Phase:Itr|Verb:Com]
  !
  ! Controls buffering strategy, compression, file management, and
  ! parallel I/O — parameters that affect the write performance but
  ! not the trigger decision.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_Out_Itr_Algo
    ! --- Buffer control ---
    LOGICAL     :: use_field_buffer   = .TRUE.     ! Enable field buffering
    LOGICAL     :: use_hist_buffer    = .TRUE.     ! Enable history buffering
    INTEGER(i4) :: field_buffer_size  = 10_i4      ! Max frames in field buffer
    INTEGER(i4) :: hist_buffer_size   = 100_i4     ! Max points in history buffer
    INTEGER(i4) :: flush_frequency    = 5_i4       ! Flush buffer every N writes

    ! --- File management ---
    LOGICAL     :: compress_output    = .FALSE.    ! Compress output files
    LOGICAL     :: split_by_step      = .FALSE.    ! Separate file per step
    INTEGER(i4) :: max_file_size_mb   = 0_i4       ! 0 = unlimited

    ! --- Parallel I/O ---
    LOGICAL     :: use_parallel_io    = .FALSE.    ! Enable parallel I/O
    INTEGER(i4) :: io_comm_rank       = 0_i4       ! MPI rank for I/O
    INTEGER(i4) :: io_comm_size       = 1_i4       ! MPI communicator size
  END TYPE RT_Out_Itr_Algo

END MODULE RT_Out_Aux_Def
