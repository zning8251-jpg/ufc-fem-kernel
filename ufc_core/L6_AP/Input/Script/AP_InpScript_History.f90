!===============================================================================
! MODULE: AP_InpScript_History
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command history type and operations
! BRIEF:  Command history type and operations.
!
! Process phases:
!   P0: Cmd_HistoryInit
!   P1: Cmd_HistoryAdd / Cmd_HistoryGet
!   P0: Cmd_HistoryClear
!===============================================================================
MODULE AP_InpScript_History
  USE IF_Prec_Core,    ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: Cmd, HistoryEntry
  IMPLICIT NONE
  PRIVATE

  INTEGER(i4), PARAMETER :: MAX_HISTORY = 1000

  TYPE, PUBLIC :: CmdHistory
    TYPE(HistoryEntry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: num_entries = 0
    INTEGER(i4) :: max_entries = MAX_HISTORY
    INTEGER(i4) :: idx = 0
    LOGICAL :: enabled = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Add
    PROCEDURE :: Get
    PROCEDURE :: Clear
  END TYPE CmdHistory

  PUBLIC :: CmdHistory

CONTAINS

  SUBROUTINE Hist_Init(this, max_entries, status)
    CLASS(CmdHistory), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_entries
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: max_ent, ios

    IF (PRESENT(status)) CALL init_error_status(status)

    max_ent = MAX_HISTORY
    IF (PRESENT(max_entries)) max_ent = max_entries

    IF (ALLOCATED(this%entries)) DEALLOCATE(this%entries)
    ALLOCATE(this%entries(max_ent), STAT=ios)
    IF (ios /= 0) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_ERROR
        status%message = 'Failed to allocate history entries'
      END IF
      RETURN
    END IF

    this%max_entries = max_ent
    this%num_entries = 0
    this%idx = 0
    this%enabled = .TRUE.
    this%init = .TRUE.

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Hist_Init

  SUBROUTINE Hist_Add(this, cmd, source, status)
    CLASS(CmdHistory), INTENT(INOUT) :: this
    TYPE(Cmd), INTENT(IN) :: cmd
    CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: source
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: idx

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%enabled) THEN
      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
      RETURN
    END IF

    IF (.NOT. this%init) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    IF (this%num_entries < this%max_entries) THEN
      this%num_entries = this%num_entries + 1
      idx = this%num_entries
    ELSE
      idx = MOD(this%idx, this%max_entries) + 1
      this%idx = idx
    END IF

    this%entries(idx)%cmd = cmd
    this%entries(idx)%timestamp = this%num_entries
    IF (PRESENT(source)) THEN
      this%entries(idx)%source = source(1:MIN(256, LEN_TRIM(source)))
    ELSE
      this%entries(idx)%source = 'interactive'
    END IF

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Hist_Add

  SUBROUTINE Hist_Get(this, index, cmd, status)
    CLASS(CmdHistory), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: index
    TYPE(Cmd), INTENT(OUT) :: cmd
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (index < 1 .OR. index > this%num_entries) THEN
      IF (PRESENT(status)) THEN
        status%status_code = IF_STATUS_INVALID
        WRITE(status%message, '(A,I0,A,I0)') 'History index ', index, &
          ' out of range [1,', this%num_entries, ']'
      END IF
      RETURN
    END IF

    cmd = this%entries(index)%cmd

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Hist_Get

  SUBROUTINE Hist_Clear(this, status)
    CLASS(CmdHistory), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    this%num_entries = 0
    this%idx = 0
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Hist_Clear

END MODULE AP_InpScript_History