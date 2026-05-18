!===============================================================================
! MODULE: AP_InpScript_Proc
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command procedure management
! BRIEF:  Command procedure management - define, load, save, execute.
!
! Process phases:
!   P0: Cmd_ProcInit
!   P1: Cmd_ProcDefine / Cmd_ProcLoad / Cmd_ProcSave
!   P2: Cmd_ProcExec / Cmd_ProcCall
!===============================================================================
MODULE AP_InpScript_Proc
  USE IF_Prec_Core,    ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
       IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID, IF_STATUS_IO_ERROR
  USE AP_Inp_Def, ONLY: Cmd, CmdCtx, CmdList, Proc
  USE AP_Inp_Script, ONLY: Cmd_ParseLine, g_cmd_domain, Cmd_Exec, Cmd_Subst, &
       CmdList_GetCmd
  USE, INTRINSIC :: IEEE_ARITHMETIC, ONLY: IEEE_IS_NAN, IEEE_IS_FINITE
  IMPLICIT NONE
  PRIVATE

  ! Abstract interface for resolving cmd by index (avoids circular dependency for Proc_Define)
  ABSTRACT INTERFACE
    SUBROUTINE GetCmdByIndex_Proc(cmd_list, idx, cmd, found)
      IMPORT :: CmdList, Cmd, i4
      TYPE(CmdList), INTENT(IN) :: cmd_list
      INTEGER(i4), INTENT(IN) :: idx
      TYPE(Cmd), INTENT(OUT) :: cmd
      LOGICAL, INTENT(OUT) :: found
    END SUBROUTINE GetCmdByIndex_Proc
  END INTERFACE

  TYPE, PUBLIC :: CmdProcMgr
    TYPE(Proc), ALLOCATABLE :: procs(:)
    INTEGER(i4) :: num_procs = 0
    INTEGER(i4) :: max_procs = 100
    CHARACTER(LEN=256) :: proc_dir = './procedures'
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Define
    PROCEDURE :: Load
    PROCEDURE :: Save
    PROCEDURE :: Exec
    PROCEDURE :: Find
  END TYPE CmdProcMgr

  TYPE(CmdProcMgr), SAVE, PUBLIC :: g_proc_mgr

  ! Structured I/O types
  TYPE, PUBLIC :: Cmd_ProcDefine_In
    CHARACTER(LEN=32) :: name
    TYPE(CmdList) :: cmd_list
  END TYPE Cmd_ProcDefine_In

  TYPE, PUBLIC :: Cmd_ProcDefine_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcDefine_Out

  TYPE, PUBLIC :: Cmd_ProcLoad_In
    CHARACTER(LEN=256) :: filename
  END TYPE Cmd_ProcLoad_In

  TYPE, PUBLIC :: Cmd_ProcLoad_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcLoad_Out

  TYPE, PUBLIC :: Cmd_ProcSave_In
    CHARACTER(LEN=32) :: name
    CHARACTER(LEN=256) :: filename
  END TYPE Cmd_ProcSave_In

  TYPE, PUBLIC :: Cmd_ProcSave_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcSave_Out

  TYPE, PUBLIC :: Cmd_ProcExec_In
    CHARACTER(LEN=32) :: name
    REAL(wp), ALLOCATABLE :: param_values(:)
    TYPE(CmdCtx) :: ctx
  END TYPE Cmd_ProcExec_In

  TYPE, PUBLIC :: Cmd_ProcExec_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_ProcExec_Out

  PUBLIC :: Cmd_ProcDefine_Structured
  PUBLIC :: Cmd_ProcLoad_Structured
  PUBLIC :: Cmd_ProcSave_Structured
  PUBLIC :: Cmd_ProcExec_Structured
  PUBLIC :: Cmd_ProcDefine
  PUBLIC :: Cmd_ProcLoad
  PUBLIC :: Cmd_ProcSave
  PUBLIC :: Cmd_ProcExec

CONTAINS

  SUBROUTINE Proc_Init(this, max_procs, status)
    CLASS(CmdProcMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_procs
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: max_p, ios

    max_p = 100
    IF (PRESENT(max_procs)) max_p = max_procs
    ALLOCATE(this%procs(max_p), STAT=ios)
    IF (ios /= 0 .AND. PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF
    this%max_procs = max_p
    this%init = .TRUE.
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Proc_Init

  SUBROUTINE Proc_Define(this, name, cmd_list, status, get_cmd)
    CLASS(CmdProcMgr), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(CmdList), INTENT(IN) :: cmd_list
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
    PROCEDURE(GetCmdByIndex_Proc), POINTER :: get_cmd

    INTEGER(i4) :: idx, ios, i
    TYPE(Cmd) :: cmd
    LOGICAL :: found

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%init) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    idx = this%Find(name)
    IF (idx > 0) THEN
      IF (ALLOCATED(this%procs(idx)%cmds)) DEALLOCATE(this%procs(idx)%cmds)
    ELSE
      IF (this%num_procs >= this%max_procs) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_INVALID
          WRITE(status%message, '(A,I0,A)') 'Maximum number of procedures (', this%max_procs, ') reached'
        END IF
        RETURN
      END IF
      this%num_procs = this%num_procs + 1
      idx = this%num_procs
    END IF

    this%procs(idx)%name = name
    this%procs(idx)%num_cmds = cmd_list%num_cmds
    IF (cmd_list%num_cmds > 0) THEN
      ALLOCATE(this%procs(idx)%cmds(cmd_list%num_cmds), STAT=ios)
      IF (ios /= 0) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_ERROR
          status%message = 'Failed to allocate procedure commands'
        END IF
        RETURN
      END IF
      DO i = 1, cmd_list%num_cmds
        CALL get_cmd(cmd_list, i, cmd, found)
        IF (.NOT. found) EXIT
        this%procs(idx)%cmds(i) = cmd
      END DO
    END IF
    this%procs(idx)%defined = .TRUE.

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK

  END SUBROUTINE Proc_Define

  SUBROUTINE Proc_Load(this, filename, status)
    CLASS(CmdProcMgr), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(CmdList) :: cmd_list
    CHARACTER(LEN=32) :: name
    CHARACTER(LEN=16) :: params(3)
    CHARACTER(LEN=512) :: line
    INTEGER(i4) :: unit, ios, n_cmds, i, cmd_id
    INTEGER(i4), ALLOCATABLE :: temp_ids(:)
    TYPE(Cmd) :: cmd

    CALL init_error_status(status)

    OPEN(NEWUNIT=unit, FILE=filename, STATUS='old', ACTION='read', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_IO_ERROR
      WRITE(status%message, '(A,A,A)') 'Failed to open procedure file: ', TRIM(filename)
      RETURN
    END IF

    READ(unit, '(A)', IOSTAT=ios) line
    IF (ios /= 0) THEN
      CLOSE(unit)
      status%status_code = IF_STATUS_IO_ERROR
      status%message = 'Failed to read procedure header'
      RETURN
    END IF

    READ(line, *, IOSTAT=ios) name, params(1), params(2), params(3)
    IF (ios /= 0) READ(line, *, IOSTAT=ios) name

    n_cmds = 0
    DO
      READ(unit, '(A)', IOSTAT=ios) line
      IF (ios /= 0) EXIT
      IF (LEN_TRIM(line) == 0) CYCLE
      IF (TRIM(line) == 'end') EXIT
      n_cmds = n_cmds + 1
    END DO
    REWIND(unit)
    READ(unit, '(A)', IOSTAT=ios) line

    IF (n_cmds > 0) THEN
      ALLOCATE(temp_ids(n_cmds), STAT=ios)
      IF (ios /= 0) THEN
        CLOSE(unit)
        status%status_code = IF_STATUS_ERROR
        status%message = 'Failed to allocate command list'
        RETURN
      END IF
      cmd_list%num_cmds = 0

      DO i = 1, n_cmds
        READ(unit, '(A)', IOSTAT=ios) line
        IF (ios /= 0 .OR. TRIM(line) == 'end') EXIT
        IF (LEN_TRIM(line) == 0) CYCLE

        CALL Cmd_ParseLine(line, cmd, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
          CLOSE(unit)
          DEALLOCATE(temp_ids)
          RETURN
        END IF

        CALL g_cmd_domain%AddCommand(cmd, cmd_id, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
          CLOSE(unit)
          DEALLOCATE(temp_ids)
          RETURN
        END IF
        cmd_list%num_cmds = cmd_list%num_cmds + 1
        temp_ids(cmd_list%num_cmds) = cmd_id
      END DO

      IF (cmd_list%num_cmds > 0) THEN
        ALLOCATE(cmd_list%cmd_ids(cmd_list%num_cmds), STAT=ios)
        IF (ios /= 0) THEN
          CLOSE(unit)
          DEALLOCATE(temp_ids)
          status%status_code = IF_STATUS_ERROR
          RETURN
        END IF
        cmd_list%cmd_ids(1:cmd_list%num_cmds) = temp_ids(1:cmd_list%num_cmds)
      END IF
      cmd_list%init = .TRUE.
      DEALLOCATE(temp_ids)
    END IF

    CLOSE(unit)

    CALL this%Define(name, cmd_list, status, CmdList_GetCmd)
    IF (ALLOCATED(cmd_list%cmd_ids)) DEALLOCATE(cmd_list%cmd_ids)

  END SUBROUTINE Proc_Load

  SUBROUTINE Proc_Save(this, name, filename, status)
    CLASS(CmdProcMgr), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx, unit, ios, i

    CALL init_error_status(status)

    idx = this%Find(name)
    IF (idx == 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') 'Procedure "', TRIM(name), '" not found'
      RETURN
    END IF

    OPEN(NEWUNIT=unit, FILE=filename, STATUS='replace', ACTION='write', IOSTAT=ios)
    IF (ios /= 0) THEN
      status%status_code = IF_STATUS_IO_ERROR
      WRITE(status%message, '(A,A,A)') 'Failed to open procedure file: ', TRIM(filename)
      RETURN
    END IF

    WRITE(unit, '(A,1X,3A)') TRIM(this%procs(idx)%name), &
      TRIM(this%procs(idx)%params(1)), &
      TRIM(this%procs(idx)%params(2)), &
      TRIM(this%procs(idx)%params(3))

    DO i = 1, this%procs(idx)%num_cmds
      WRITE(unit, '(A,1X,A,1X,3(1X,ES15.8),1X,A)') &
        TRIM(this%procs(idx)%cmds(i)%name), &
        TRIM(this%procs(idx)%cmds(i)%opt), &
        this%procs(idx)%cmds(i)%params(1), &
        this%procs(idx)%cmds(i)%params(2), &
        this%procs(idx)%cmds(i)%params(3), &
        TRIM(this%procs(idx)%cmds(i)%param_str)
    END DO

    WRITE(unit, '(A)') 'end'
    CLOSE(unit)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE Proc_Save

  SUBROUTINE Proc_Exec(this, name, param_values, ctx, status)
    CLASS(CmdProcMgr), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    REAL(wp), INTENT(IN), OPTIONAL :: param_values(3)
    TYPE(CmdCtx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: idx, i, j, parse_ios
    TYPE(Cmd) :: cmd, subst_cmd

    CALL init_error_status(status)

    idx = this%Find(name)
    IF (idx == 0) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') 'Procedure "', TRIM(name), '" not found'
      RETURN
    END IF

    IF (.NOT. this%procs(idx)%defined) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') 'Procedure "', TRIM(name), '" not defined'
      RETURN
    END IF

    DO i = 1, this%procs(idx)%num_cmds
      cmd = this%procs(idx)%cmds(i)
      subst_cmd = cmd

      IF (PRESENT(param_values)) THEN
        IF (LEN_TRIM(cmd%opt) > 0) THEN
          subst_cmd%opt = cmd%opt
          IF (INDEX(cmd%opt, '$') > 0) THEN
            CALL Cmd_Subst(cmd, ctx, subst_cmd, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
          END IF
        END IF

        IF (LEN_TRIM(cmd%param_str) > 0) THEN
          IF (INDEX(cmd%param_str, '$') > 0) THEN
            CALL Cmd_Subst(cmd, ctx, subst_cmd, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
          ELSE
            subst_cmd%param_str = cmd%param_str
          END IF

          READ(subst_cmd%param_str, *, IOSTAT=parse_ios) subst_cmd%params(1), subst_cmd%params(2), subst_cmd%params(3)
          IF (parse_ios == 0) THEN
            DO j = 1, 3
              IF (IEEE_IS_NAN(subst_cmd%params(j)) .OR. .NOT. IEEE_IS_FINITE(subst_cmd%params(j))) THEN
                subst_cmd%params(j) = 0.0_wp
              END IF
            END DO
          END IF
        END IF
      END IF

      CALL Cmd_Exec(subst_cmd, ctx, status)
      IF (status%status_code /= IF_STATUS_OK) RETURN
    END DO

    status%status_code = IF_STATUS_OK

  END SUBROUTINE Proc_Exec

  FUNCTION Proc_Find(this, name) RESULT(idx)
    CLASS(CmdProcMgr), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    INTEGER(i4) :: idx

    INTEGER(i4) :: i

    idx = 0
    DO i = 1, this%num_procs
      IF (this%procs(i)%defined .AND. TRIM(this%procs(i)%name) == TRIM(name)) THEN
        idx = i
        RETURN
      END IF
    END DO

  END FUNCTION Proc_Find

  !===============================================================================
  ! Structured Interfaces
  !===============================================================================
  SUBROUTINE Cmd_ProcDefine_Structured(in, out)
    TYPE(Cmd_ProcDefine_In), INTENT(IN) :: in
    TYPE(Cmd_ProcDefine_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_proc_mgr%Define(in%name, in%cmd_list, out%status, CmdList_GetCmd)
  END SUBROUTINE Cmd_ProcDefine_Structured

  SUBROUTINE Cmd_ProcLoad_Structured(in, out)
    TYPE(Cmd_ProcLoad_In), INTENT(IN) :: in
    TYPE(Cmd_ProcLoad_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_proc_mgr%Load(in%filename, out%status)
  END SUBROUTINE Cmd_ProcLoad_Structured

  SUBROUTINE Cmd_ProcSave_Structured(in, out)
    TYPE(Cmd_ProcSave_In), INTENT(IN) :: in
    TYPE(Cmd_ProcSave_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_proc_mgr%Save(in%name, in%filename, out%status)
  END SUBROUTINE Cmd_ProcSave_Structured

  SUBROUTINE Cmd_ProcExec_Structured(in, out)
    TYPE(Cmd_ProcExec_In), INTENT(IN) :: in
    TYPE(Cmd_ProcExec_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    IF (ALLOCATED(in%param_values)) THEN
      CALL g_proc_mgr%Exec(in%name, in%param_values, in%ctx, out%status)
    ELSE
      CALL g_proc_mgr%Exec(in%name, ctx=in%ctx, status=out%status)
    END IF
  END SUBROUTINE Cmd_ProcExec_Structured

  !===============================================================================
  ! Deprecated wrappers
  !===============================================================================
  SUBROUTINE Cmd_ProcDefine(name, cmd_list, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(CmdList), INTENT(IN) :: cmd_list
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_ProcDefine_In) :: in
    TYPE(Cmd_ProcDefine_Out) :: out

    in%name = name
    in%cmd_list = cmd_list
    CALL Cmd_ProcDefine_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_ProcDefine

  SUBROUTINE Cmd_ProcLoad(filename, status)
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_ProcLoad_In) :: in
    TYPE(Cmd_ProcLoad_Out) :: out

    in%filename = filename
    CALL Cmd_ProcLoad_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_ProcLoad

  SUBROUTINE Cmd_ProcSave(name, filename, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    CHARACTER(LEN=*), INTENT(IN) :: filename
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_ProcSave_In) :: in
    TYPE(Cmd_ProcSave_Out) :: out

    in%name = name
    in%filename = filename
    CALL Cmd_ProcSave_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_ProcSave

  SUBROUTINE Cmd_ProcExec(name, param_values, ctx, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    REAL(wp), INTENT(IN), OPTIONAL :: param_values(3)
    TYPE(CmdCtx), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Cmd_ProcExec_In) :: in
    TYPE(Cmd_ProcExec_Out) :: out

    in%name = name
    IF (PRESENT(param_values)) THEN
      IF (.NOT. ALLOCATED(in%param_values)) ALLOCATE(in%param_values(3))
      in%param_values = param_values
    END IF
    in%ctx = ctx
    CALL Cmd_ProcExec_Structured(in, out)
    ctx = in%ctx
    status = out%status
  END SUBROUTINE Cmd_ProcExec

END MODULE AP_InpScript_Proc