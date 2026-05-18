!===============================================================================
! MODULE: RT_WB_Aux_Def
! LAYER:  L5_RT
! DOMAIN: WriteBack
! ROLE:   Aux Def — auxiliary TYPE definitions for WriteBack step-level
!         algorithm control and iteration-level I/O/audit algorithm, bridging
!         the P2 gap identified in Procedure_Algorithm_L3L4L5_synthesis.md §C.
! BRIEF:  RT_WB_Stp_Ctl_Algo (步级写回策略/触发/验证控制) + RT_WB_Itr_Algo
!         (迭代级缓冲/压缩/审计/NaN截断控制), aligned with
!         RT_Out_Stp_Ctl_Algo / RT_Out_Itr_Algo / PH_LoadBC_Stp_Ctl_Algo /
!         MD_Cont_Stp_Ctl_Algo pattern.
!===============================================================================
MODULE RT_WB_Aux_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE RT_WB_Def,       ONLY: RT_WB_WRITE_EVERY_INC, RT_WB_WRITE_STEP_END, &
                              RT_WB_WRITE_USER_DEFINED
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! RT_WB_Stp_Ctl_Algo — Step-level write-back trigger & strategy control
  ! [Phase:Stp|Verb:Ctl]
  !
  ! Controls when write-back is triggered (increment-based / step-end /
  ! user-defined LOP) and what validation/checkpoint strategy to apply.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_WB_Stp_Ctl_Algo
    ! --- Write trigger configuration ---
    INTEGER(i4) :: write_trigger      = RT_WB_WRITE_EVERY_INC
    LOGICAL     :: trigger_at_step_end = .TRUE.     ! Always write back at step end
    LOGICAL     :: trigger_at_analysis_end = .TRUE.  ! Always write back at analysis end

    ! --- Checkpoint strategy ---
    LOGICAL     :: save_checkpoint_on_write = .FALSE.  ! Auto-checkpoint on write-back
    INTEGER(i4) :: checkpoint_interval = 10_i4        ! Save checkpoint every N writes

    ! --- Validation control ---
    LOGICAL     :: validate_before_write = .TRUE.   ! Validate data before writing
    LOGICAL     :: checksum_enabled      = .FALSE.  ! Compute checksum for audit

    ! --- Override / last-chance ---
    LOGICAL     :: force_write_back   = .FALSE.     ! Override trigger check
    LOGICAL     :: suppress_all_wb    = .FALSE.     ! Suppress all write-back

    ! --- NaN handling policy ---
    INTEGER(i4) :: nan_policy = 0_i4  ! 0=truncate+warn, 1=skip, 2=abort
  END TYPE RT_WB_Stp_Ctl_Algo

  ! ==========================================================================
  ! RT_WB_Itr_Algo — Iteration-level I/O buffer & audit algorithm control
  ! [Phase:Itr|Verb:Com]
  !
  ! Controls buffering strategy, compression, parallel write, and
  ! audit/batching — parameters that affect write performance and
  ! audit trail, not the trigger decision.
  ! ==========================================================================
  TYPE, PUBLIC :: RT_WB_Itr_Algo
    ! --- Buffer control ---
    LOGICAL     :: use_node_buffering  = .TRUE.     ! Enable node buffering
    LOGICAL     :: use_elem_buffering  = .TRUE.     ! Enable element buffering
    INTEGER(i4) :: node_buffer_capacity = 10000_i4  ! Max items in node buffer
    INTEGER(i4) :: elem_buffer_capacity = 5000_i4   ! Max items in element buffer

    ! --- Compression ---
    LOGICAL     :: compress_output     = .FALSE.    ! Compress write-back data
    INTEGER(i4) :: compression_level   = 6_i4       ! 1-9 (9=maximum)

    ! --- Parallel write-back ---
    LOGICAL     :: use_parallel_write   = .FALSE.   ! Enable parallel writes
    INTEGER(i4) :: n_write_threads     = 1_i4       ! Number of write threads

    ! --- Batching optimization ---
    LOGICAL     :: batch_small_writes  = .TRUE.     ! Batch small write operations
    INTEGER(i4) :: batch_threshold     = 100_i4     ! Batch writes smaller than this

    ! --- Audit configuration ---
    LOGICAL     :: audit_enabled       = .TRUE.     ! Enable write-back audit trail
    LOGICAL     :: detailed_audit      = .FALSE.    ! Include data values in audit
    INTEGER(i4) :: max_audit_records   = 10000_i4   ! Max audit records to keep
  END TYPE RT_WB_Itr_Algo

END MODULE RT_WB_Aux_Def
