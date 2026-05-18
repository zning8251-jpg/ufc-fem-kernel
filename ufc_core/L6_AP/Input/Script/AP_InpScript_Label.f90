!===============================================================================
! MODULE: AP_InpScript_Label
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command label management
! BRIEF:  Command label management - register and resolve labels.
!
! Process phases:
!   P0: Cmd_LabelInit
!   P1: Cmd_LabelRegister / Cmd_LabelResolve
!===============================================================================
MODULE AP_InpScript_Label
  USE IF_Prec_Core,    ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: Cmd, CmdList
  IMPLICIT NONE
  PRIVATE

  ! Abstract interface for resolving cmd by index (avoids AP_Cmd_Label -> AP_Cmd_Core dependency)
  ABSTRACT INTERFACE
    SUBROUTINE GetCmdByIndex_Proc(cmd_list, idx, cmd, found)
      IMPORT :: CmdList, Cmd, i4
      TYPE(CmdList), INTENT(IN) :: cmd_list
      INTEGER(i4), INTENT(IN) :: idx
      TYPE(Cmd), INTENT(OUT) :: cmd
      LOGICAL, INTENT(OUT) :: found
    END SUBROUTINE GetCmdByIndex_Proc
  END INTERFACE

  TYPE, PUBLIC :: LabelEntry
    CHARACTER(LEN=32) :: name = ''
    INTEGER(i4) :: cmd_idx = 0
    LOGICAL :: defined = .FALSE.
  END TYPE LabelEntry

  TYPE, PUBLIC :: CmdLabelMgr
    TYPE(LabelEntry), ALLOCATABLE :: labels(:)
    INTEGER(i4) :: num_labels = 0
    INTEGER(i4) :: max_labels = 100
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reg
    PROCEDURE :: Resolve
  END TYPE CmdLabelMgr

  TYPE(CmdLabelMgr), SAVE, PUBLIC :: g_label_mgr

CONTAINS

  SUBROUTINE Label_Init(this, status)
    CLASS(CmdLabelMgr), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: ios

    ALLOCATE(this%labels(this%max_labels), STAT=ios)
    IF (ios /= 0 .AND. PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF
    this%init = .TRUE.
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Label_Init

  SUBROUTINE Label_Reg(this, cmd_list, status, get_cmd)
    CLASS(CmdLabelMgr), INTENT(INOUT) :: this
    TYPE(CmdList), INTENT(IN) :: cmd_list
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    PROCEDURE(GetCmdByIndex_Proc), POINTER :: get_cmd

    INTEGER(i4) :: i, idx, lbl_idx
    CHARACTER(LEN=32) :: label_name
    TYPE(Cmd) :: cmd
    LOGICAL :: found

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%init) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    ! Scan command list for label commands
    DO i = 1, cmd_list%num_cmds
      CALL get_cmd(cmd_list, i, cmd, found)
      IF (.NOT. found) CYCLE
      IF (cmd%name == 'label') THEN
        label_name = cmd%opt
        IF (LEN_TRIM(label_name) == 0) THEN
          label_name = cmd%param_str
        END IF
        IF (LEN_TRIM(label_name) == 0) CYCLE

        ! Check if label already exists
        lbl_idx = this%Resolve(label_name)
        IF (lbl_idx == 0) THEN
          ! Add new label
          IF (this%num_labels >= this%max_labels) THEN
            IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              WRITE(status%message, '(A,I0,A)') 'Maximum number of labels (', this%max_labels, ') reached'
            END IF
            RETURN
          END IF
          this%num_labels = this%num_labels + 1
          lbl_idx = this%num_labels
        END IF

        this%labels(lbl_idx)%name = label_name
        this%labels(lbl_idx)%cmd_idx = i
        this%labels(lbl_idx)%defined = .TRUE.
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK

  END SUBROUTINE Label_Reg

  FUNCTION Label_Resolve(this, name) RESULT(idx)
    CLASS(CmdLabelMgr), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4) :: idx

    INTEGER(i4) :: i
    CHARACTER(LEN=32) :: name_str, label_name

    idx = 0
    name_str = name

    ! Try as name first
    DO i = 1, this%num_labels
      IF (this%labels(i)%defined) THEN
        label_name = this%labels(i)%name
        IF (TRIM(label_name) == TRIM(name_str)) THEN
          idx = this%labels(i)%cmd_idx
          RETURN
        END IF
      END IF
    END DO

    ! Try as line number
    READ(name_str, *, IOSTAT=i) idx
    IF (i == 0 .AND. idx > 0) THEN
      ! Valid line number
      RETURN
    END IF

    idx = 0

  END FUNCTION Label_Resolve

END MODULE AP_InpScript_Label