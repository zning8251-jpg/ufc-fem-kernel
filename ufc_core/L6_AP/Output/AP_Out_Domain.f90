!======================================================================
! Module: AP_OutDomain
! Layer:  L6_AP - Application Layer
! Domain: Output / Domain
! Purpose: Application-level output management and results export.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: SIO-REFACTORED
! Last verified: 2026-04-18
!======================================================================
MODULE AP_Out_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE AP_Out_Def, ONLY: OutputRequestEntry, FrameEntry, &
                              AP_OUTPUT_REQUEST_ID_INVALID, AP_OUTPUT_FRAME_ID_INVALID
  USE MD_Out_API, ONLY: MD_OutputRequest_Desc, MD_Output_Domain, &
       OUT_FIELD, OUT_HISTORY, FMT_ODB
  USE MD_Out_Mgr, ONLY: MD_Out_Mgr_RegisterRequest
  USE UFC_GlobalContainer_Core, ONLY: g_ufc_global
  IMPLICIT NONE
  PRIVATE

  ! --- Output format enums ---
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTFMT_ODB  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTFMT_VTK  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTFMT_CSV  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTFMT_HDF5 = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: AP_OUTFMT_BINARY = 5_i4

    TYPE, PUBLIC :: AP_Output_State_Files
    INTEGER(i4) :: odbFileUnit = 0_i4
    INTEGER(i4) :: msgFileUnit = 0_i4
    INTEGER(i4) :: datFileUnit = 0_i4
    INTEGER(i4) :: staFileUnit = 0_i4
  END TYPE AP_Output_State_Files

  TYPE, PUBLIC :: AP_Output_State_Stats
    INTEGER(i4) :: totalFrames     = 0_i4
    REAL(wp)    :: totalWriteBytes = 0.0_wp  ! approximate bytes written
    REAL(wp)    :: totalWriteTime  = 0.0_wp
  END TYPE AP_Output_State_Stats

  TYPE, PUBLIC :: AP_Output_State_Flags
    LOGICAL :: odbOpen = .FALSE.
  END TYPE AP_Output_State_Flags

  TYPE, PUBLIC :: AP_Output_State
    TYPE(AP_Output_State_Files) :: files
    TYPE(AP_Output_State_Stats) :: stats
    TYPE(AP_Output_State_Flags) :: flags
  END TYPE AP_Output_State

    TYPE, PUBLIC :: AP_Output_Ctrl_Paths
    CHARACTER(LEN=512) :: outputDir = '.'
    CHARACTER(LEN=256) :: jobName   = ' '
  END TYPE AP_Output_Ctrl_Paths

  TYPE, PUBLIC :: AP_Output_Ctrl_Format
    INTEGER(i4) :: primaryFormat = AP_OUTFMT_ODB
  END TYPE AP_Output_Ctrl_Format

  TYPE, PUBLIC :: AP_Output_Ctrl_Flags
    LOGICAL :: writeODB    = .TRUE.
    LOGICAL :: writeMSG    = .TRUE.
    LOGICAL :: writeDAT    = .TRUE.
    LOGICAL :: writeSTA    = .TRUE.
    LOGICAL :: compressODB = .FALSE.
  END TYPE AP_Output_Ctrl_Flags

  TYPE, PUBLIC :: AP_Output_Ctrl
    TYPE(AP_Output_Ctrl_Paths)  :: paths
    TYPE(AP_Output_Ctrl_Format) :: format
    TYPE(AP_Output_Ctrl_Flags)  :: flags
  END TYPE AP_Output_Ctrl

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: AP_Output_OpenODB_Arg
    CHARACTER(LEN=512)    :: odbPath = ""  ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Output_OpenODB_Arg

    TYPE, PUBLIC :: AP_Output_WriteFrame_Arg_IDs
    INTEGER(i4) :: frameId    = 0_i4    ! (IN)
    INTEGER(i4) :: step_id    = 0_i4    ! (IN) step_idx, optional
    INTEGER(i4) :: inc_id     = 0_i4    ! (IN) incr_idx, optional
    INTEGER(i4) :: request_id = 0_i4    ! (IN) optional
  END TYPE AP_Output_WriteFrame_Arg_IDs

  TYPE, PUBLIC :: AP_Output_WriteFrame_Arg_Meta
    REAL(wp)  :: time        = 0.0_wp  ! (IN) optional
    LOGICAL   :: hasMetadata = .FALSE. ! (IN) use optional fields
  END TYPE AP_Output_WriteFrame_Arg_Meta

  TYPE, PUBLIC :: AP_Output_WriteFrame_Arg
    TYPE(AP_Output_WriteFrame_Arg_IDs)  :: ids
    TYPE(AP_Output_WriteFrame_Arg_Meta) :: meta
    TYPE(ErrorStatusType)               :: status
  END TYPE AP_Output_WriteFrame_Arg

  TYPE, PUBLIC :: AP_Output_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""         ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE AP_Output_GetSummary_Arg

  TYPE, PUBLIC :: AP_Output_Domain
    TYPE(AP_Output_State) :: state
    TYPE(AP_Output_Ctrl)  :: ctrl
    ! Flat domain storage (index tree + flat)
    TYPE(OutputRequestEntry), ALLOCATABLE :: output_requests(:)
    TYPE(FrameEntry),          ALLOCATABLE :: frames(:)
    INTEGER(i4) :: n_requests = 0_i4
    INTEGER(i4) :: n_frames   = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: OpenODB
    PROCEDURE :: WriteFrame
    PROCEDURE :: GetSummary
    PROCEDURE :: AddOutputRequest
    PROCEDURE :: AddFrame
    PROCEDURE :: GetRequestById
    PROCEDURE :: GetFrameById
    PROCEDURE :: GetRequestCount
    PROCEDURE :: GetFrameCount
  END TYPE AP_Output_Domain

CONTAINS

  SUBROUTINE AP_Output_Domain_Finalize(this)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%state = AP_Output_State()
    IF (ALLOCATED(this%output_requests)) DEALLOCATE(this%output_requests)
    IF (ALLOCATED(this%frames)) DEALLOCATE(this%frames)
    this%n_requests = 0_i4
    this%n_frames   = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE AP_Output_Domain_Finalize

  SUBROUTINE AP_Output_Domain_Init(this, status)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctrl = AP_Output_Ctrl()
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE AP_Output_Domain_Init

  !====================================================================
  ! AP_Output_Domain_OpenODB  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Output_Domain_OpenODB(this, arg)
    CLASS(AP_Output_Domain),     INTENT(INOUT) :: this
    TYPE(AP_Output_OpenODB_Arg), INTENT(INOUT) :: arg
    CALL AP_Output_OpenODB_Impl(this, arg%odbPath, arg%status)
  END SUBROUTINE AP_Output_Domain_OpenODB

  SUBROUTINE AP_Output_OpenODB_Impl(this, odbPath, status)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),        INTENT(IN)    :: odbPath
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    IF (LEN_TRIM(odbPath) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "ODB path is empty"
      RETURN
    END IF

    this%state%files%odbFileUnit = 10_i4
    this%state%flags%odbOpen = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Output_OpenODB_Impl

  !====================================================================
  ! AP_Output_Domain_WriteFrame  [Arg wrapper]
  ! hasMetadata=.TRUE. ?Arg step_id/inc_id/time/request_id
  !====================================================================
  SUBROUTINE AP_Output_Domain_WriteFrame(this, arg)
    CLASS(AP_Output_Domain),       INTENT(INOUT) :: this
    TYPE(AP_Output_WriteFrame_Arg),INTENT(INOUT) :: arg
    IF (arg%meta%hasMetadata) THEN
      CALL AP_Output_WriteFrame_Impl(this, arg%ids%frameId, arg%status, &
                                     arg%ids%step_id, arg%ids%inc_id, arg%meta%time, arg%ids%request_id)
    ELSE
      CALL AP_Output_WriteFrame_Impl(this, arg%ids%frameId, arg%status)
    END IF
  END SUBROUTINE AP_Output_Domain_WriteFrame

  SUBROUTINE AP_Output_WriteFrame_Impl(this, frameId, status, step_id, inc_id, time, request_id)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: frameId
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: step_id, inc_id, request_id
    REAL(wp),                INTENT(IN), OPTIONAL :: time

    INTEGER(i4) :: sid, iid, rid, fid

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    IF (.NOT. this%state%flags%odbOpen) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "ODB file not open"
      RETURN
    END IF

    this%state%stats%totalFrames = this%state%stats%totalFrames + 1_i4

    IF (PRESENT(step_id) .AND. PRESENT(inc_id) .AND. PRESENT(time) .AND. PRESENT(request_id)) THEN
      sid = step_id
      iid = inc_id
      rid = request_id
      CALL this%AddFrame(sid, iid, time, rid, fid, status)
    END IF

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Output_WriteFrame_Impl

  !====================================================================
  ! AP_Output_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE AP_Output_Domain_GetSummary(this, arg)
    CLASS(AP_Output_Domain),        INTENT(IN)    :: this
    TYPE(AP_Output_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL AP_Output_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE AP_Output_Domain_GetSummary

  SUBROUTINE AP_Output_GetSummary_Impl(this, summary, status)
    CLASS(AP_Output_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0,A,I0,A,ES10.3,A,ES10.3,A,L1)') &
      "Output Summary: ODB_Unit=", this%state%files%odbFileUnit, &
      ", MSG_Unit=", this%state%files%msgFileUnit, &
      ", DAT_Unit=", this%state%files%datFileUnit, &
      ", STA_Unit=", this%state%files%staFileUnit, &
      ", TotalFrames=", this%state%stats%totalFrames, &
      ", WriteBytes=", this%state%stats%totalWriteBytes, &
      ", WriteTime=", this%state%stats%totalWriteTime, &
      ", ODB_Open=", this%state%flags%odbOpen

    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Output_GetSummary_Impl

  !====================================================================
  ! AP_Output_Domain_AddOutputRequest
  ! Delegate to md_layer%output (single source); fallback to local when MD not ready.
  !====================================================================
  SUBROUTINE AP_Output_Domain_AddOutputRequest(this, entry, request_id, status)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    TYPE(OutputRequestEntry), INTENT(IN)  :: entry
    INTEGER(i4),             INTENT(OUT)  :: request_id
    TYPE(ErrorStatusType),   INTENT(OUT)  :: status

    TYPE(OutputRequestEntry), ALLOCATABLE :: tmp(:)
    TYPE(MD_OutputRequest_Desc) :: desc
    INTEGER(i4) :: n, cap, i, start, len_str
    CHARACTER(LEN=16) :: tok

    CALL init_error_status(status)
    request_id = AP_OUTPUT_REQUEST_ID_INVALID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    ! Delegate to md_layer%output when ready (index tree + flat domain, single source)
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized) THEN
      desc%name = entry%name
      desc%request_type = MERGE(OUT_FIELD, OUT_HISTORY, entry%req_type == 1_i4)
      desc%target_set = entry%region
      desc%frequency = entry%frequency
      desc%step_ref = MAX(0_i4, entry%step_id)
      desc%format = FMT_ODB
      desc%n_variables = 0_i4
      desc%variables = ""
      len_str = LEN_TRIM(entry%variable_str)
      IF (len_str > 0) THEN
        start = 1
        DO i = 1, len_str + 1
          IF (i > len_str .OR. entry%variable_str(i:i) == ',' .OR. entry%variable_str(i:i) == ' ') THEN
            IF (i > start) THEN
              tok = entry%variable_str(start:i-1)
              IF (desc%n_variables < 32) THEN
                desc%n_variables = desc%n_variables + 1_i4
                desc%variables(desc%n_variables) = tok
              END IF
            END IF
            start = i + 1
          END IF
        END DO
      END IF
      IF (desc%n_variables == 0) THEN
        desc%n_variables = 1_i4
        desc%variables(1) = "PRESELECT"
      END IF
      CALL MD_Out_Mgr_RegisterRequest(g_ufc_global%md_layer%output, &
           g_ufc_global%md_layer%step, desc, status)
      IF (status%status_code == IF_STATUS_OK) request_id = g_ufc_global%md_layer%output%n_requests
      RETURN
    END IF

    ! Fallback: local storage when md_layer not ready
    n = this%n_requests + 1_i4
    IF (.NOT. ALLOCATED(this%output_requests)) THEN
      cap = MAX(64_i4, n)
      ALLOCATE(this%output_requests(cap))
    ELSE IF (n > SIZE(this%output_requests)) THEN
      cap = SIZE(this%output_requests) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_requests) = this%output_requests(1:this%n_requests)
      CALL MOVE_ALLOC(tmp, this%output_requests)
    END IF

    this%output_requests(n) = entry
    this%output_requests(n)%request_id = n
    this%n_requests = n
    request_id = n
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Output_Domain_AddOutputRequest

  !====================================================================
  ! AP_Output_Domain_AddFrame
  ! Add frame entry to flat domain
  !====================================================================
  SUBROUTINE AP_Output_Domain_AddFrame(this, step_id, inc_id, time, request_id, frame_id, status)
    CLASS(AP_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),            INTENT(IN)    :: step_id
    INTEGER(i4),            INTENT(IN)    :: inc_id
    REAL(wp),               INTENT(IN)    :: time
    INTEGER(i4),            INTENT(IN)    :: request_id
    INTEGER(i4),            INTENT(OUT)   :: frame_id
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    TYPE(FrameEntry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: n, cap

    CALL init_error_status(status)
    frame_id = AP_OUTPUT_FRAME_ID_INVALID
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    n = this%n_frames + 1_i4
    IF (.NOT. ALLOCATED(this%frames)) THEN
      cap = MAX(64_i4, n)
      ALLOCATE(this%frames(cap))
    ELSE IF (n > SIZE(this%frames)) THEN
      cap = SIZE(this%frames) * 2_i4
      ALLOCATE(tmp(cap))
      tmp(1:this%n_frames) = this%frames(1:this%n_frames)
      CALL MOVE_ALLOC(tmp, this%frames)
    END IF

    this%frames(n)%frame_id   = n
    this%frames(n)%step_id    = step_id
    this%frames(n)%inc_id     = inc_id
    this%frames(n)%time       = time
    this%frames(n)%request_id = request_id
    this%n_frames = n
    frame_id = n
    status%status_code = IF_STATUS_OK

  END SUBROUTINE AP_Output_Domain_AddFrame

  !====================================================================
  ! AP_Output_Domain_GetRequestById
  ! Prefer md_layer%output (single source); fallback to local storage.
  !====================================================================
  SUBROUTINE AP_Output_Domain_GetRequestById(this, idx, entry, found)
    CLASS(AP_Output_Domain), INTENT(IN)  :: this
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(OutputRequestEntry), INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found

    TYPE(MD_OutputRequest_Desc) :: desc
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: j
    CHARACTER(LEN=256) :: var_str

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN

    ! Prefer md_layer%output (single source)
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized .AND. &
        idx <= g_ufc_global%md_layer%output%n_requests) THEN
      CALL g_ufc_global%md_layer%output%GetRequest(idx, desc, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
      entry%request_id = idx
      entry%req_type = MERGE(1_i4, 2_i4, desc%request_type == OUT_FIELD)
      entry%name = desc%name
      entry%region = desc%target_set
      entry%position = 0_i4
      entry%frequency = desc%frequency
      entry%step_id = desc%step_ref
      var_str = ""
      IF (desc%n_variables > 0) THEN
        var_str = TRIM(desc%variables(1))
        DO j = 2, MIN(desc%n_variables, 32)
          var_str = TRIM(var_str) // "," // TRIM(desc%variables(j))
        END DO
      END IF
      IF (LEN_TRIM(var_str) == 0) var_str = "PRESELECT"
      entry%variable_str = var_str
      entry%n_vars = desc%n_variables
      found = .TRUE.
      RETURN
    END IF

    ! Fallback: local storage
    IF (.NOT. ALLOCATED(this%output_requests)) RETURN
    IF (idx > this%n_requests) RETURN
    entry = this%output_requests(idx)
    found = .TRUE.

  END SUBROUTINE AP_Output_Domain_GetRequestById

  !====================================================================
  ! AP_Output_Domain_GetFrameById
  !====================================================================
  SUBROUTINE AP_Output_Domain_GetFrameById(this, idx, entry, found)
    CLASS(AP_Output_Domain), INTENT(IN)  :: this
    INTEGER(i4),            INTENT(IN)  :: idx
    TYPE(FrameEntry),       INTENT(OUT) :: entry
    LOGICAL,                INTENT(OUT) :: found

    found = .FALSE.
    IF (.NOT. this%initialized) RETURN
    IF (idx < 1) RETURN
    IF (.NOT. ALLOCATED(this%frames)) RETURN
    IF (idx > this%n_frames) RETURN
    entry = this%frames(idx)
    found = .TRUE.

  END SUBROUTINE AP_Output_Domain_GetFrameById

  !====================================================================
  ! AP_Output_Domain_GetRequestCount
  ! Effective count: prefer md_layer%output (single source).
  !====================================================================
  FUNCTION AP_Output_Domain_GetRequestCount(this) RESULT(n)
    CLASS(AP_Output_Domain), INTENT(IN) :: this
    INTEGER(i4) :: n
    IF (g_ufc_global%IsReady() .AND. g_ufc_global%md_layer%output%initialized) THEN
      n = g_ufc_global%md_layer%output%n_requests
    ELSE
      n = this%n_requests
    END IF
  END FUNCTION AP_Output_Domain_GetRequestCount

  !====================================================================
  ! AP_Output_Domain_GetFrameCount
  !====================================================================
  FUNCTION AP_Output_Domain_GetFrameCount(this) RESULT(n)
    CLASS(AP_Output_Domain), INTENT(IN) :: this
    INTEGER(i4) :: n
    n = this%n_frames
  END FUNCTION AP_Output_Domain_GetFrameCount

END MODULE AP_Out_Domain