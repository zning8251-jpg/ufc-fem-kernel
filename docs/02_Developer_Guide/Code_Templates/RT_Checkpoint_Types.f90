!=======================================================================
! Module: RT_Checkpoint_Types                             [Template v1.0]
! Layer:  L5_RT — Runtime Execution Layer
! Domain: Checkpoint / Restart management
!
! Purpose:
!   Provides types for writing, reading and managing restart checkpoints
!   during a running analysis.  Supports:
!     - Periodic checkpoint (every N increments, or on convergence)
!     - Full restart from a given step/increment
!     - Snapshot for post-processing without restart
!=======================================================================
MODULE RT_Checkpoint_Types
  USE IF_Prec_Core
  USE IF_Err_Brg,  ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE

  ! Checkpoint event flags
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CKPT_CKPT_EVENT_INC_END   = 1_i4  ! end of increment  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CKPT_CKPT_EVENT_STEP_END  = 2_i4  ! end of step  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CKPT_CKPT_EVENT_ANALYSIS_END = 3_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CKPT_CKPT_EVENT_MANUAL    = 9_i4  ! user-triggered  ! migrated

  !=====================================================================
  ! RT_Checkpoint_Desc — checkpoint configuration (Desc = immutable)
  !=====================================================================
  TYPE, PUBLIC :: RT_Checkpoint_Desc
    CHARACTER(LEN=256) :: base_path     = ' '    ! directory for checkpoint files
    CHARACTER(LEN=80)  :: prefix        = 'ckpt' ! file name prefix
    INTEGER(i4) :: write_every_n_inc    = 10_i4  ! write checkpoint every N increments
    INTEGER(i4) :: write_every_n_steps  = 0_i4   ! 0 = not used
    INTEGER(i4) :: max_files            = 3_i4   ! rolling window (0=unlimited)
    LOGICAL     :: write_on_converge    = .TRUE.  ! only write on convergence
    LOGICAL     :: binary               = .TRUE.  ! binary vs text
    LOGICAL     :: is_active            = .FALSE.
  END TYPE RT_Checkpoint_Desc

  !=====================================================================
  ! RT_Checkpoint_State — checkpoint runtime state
  !=====================================================================
  TYPE, PUBLIC :: RT_Checkpoint_State
    INTEGER(i4) :: last_ckpt_inc  = 0_i4    ! increment of last successful write
    INTEGER(i4) :: last_ckpt_step = 0_i4    ! step of last successful write
    INTEGER(i4) :: n_written      = 0_i4    ! total checkpoints written
    INTEGER(i4) :: n_files_on_disk= 0_i4    ! current files in rolling window
    REAL(wp)    :: last_write_time = 0.0_wp ! wall-clock time of last write (s)
    LOGICAL     :: is_dirty       = .FALSE.  ! incremental state changed since last write
    CHARACTER(LEN=256) :: last_file = ' '   ! path of last written file
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Checkpoint_State

  !=====================================================================
  ! RT_Restore_Ctx — restart read context (call-scoped)
  !=====================================================================
  TYPE, PUBLIC :: RT_Restore_Ctx
    CHARACTER(LEN=256) :: file_path    = ' '  ! path to restart file
    INTEGER(i4) :: target_step         = 0_i4  ! resume from this step
    INTEGER(i4) :: target_inc          = 0_i4  ! resume from this increment
    LOGICAL     :: validate_hash       = .TRUE. ! check file integrity hash
    LOGICAL     :: partial             = .FALSE. ! partial restore (mat state only)
    LOGICAL     :: is_set              = .FALSE.
  END TYPE RT_Restore_Ctx

  !=====================================================================
  ! RT_Snapshot_Algo — snapshot (non-restart) write algorithm parameters
  !=====================================================================
  TYPE, PUBLIC :: RT_Snapshot_Algo
    INTEGER(i4) :: write_every_n_inc  = 1_i4   ! post-process snapshot frequency
    LOGICAL     :: include_stress     = .TRUE.
    LOGICAL     :: include_statev     = .TRUE.
    LOGICAL     :: include_energy     = .TRUE.
    LOGICAL     :: compress           = .FALSE.  ! gzip compression
  END TYPE RT_Snapshot_Algo

END MODULE RT_Checkpoint_Types
