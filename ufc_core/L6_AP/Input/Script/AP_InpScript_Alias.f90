!===============================================================================
! MODULE: AP_InpScript_Alias
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command alias management
! BRIEF:  Command alias management - define and resolve command aliases.
!===============================================================================
MODULE AP_InpScript_Alias
  USE IF_Prec_Core,    ONLY: i4, wp
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_INVALID
  USE AP_Inp_Def, ONLY: Cmd
  IMPLICIT NONE
  PRIVATE

  TYPE, PUBLIC :: AliasEntry
    CHARACTER(LEN=16) :: name = ''
    TYPE(Cmd) :: cmd
    LOGICAL :: defined = .FALSE.
  END TYPE AliasEntry

  TYPE, PUBLIC :: CmdAliasMgr
    TYPE(AliasEntry), ALLOCATABLE :: aliases(:)
    INTEGER(i4) :: num_aliases = 0
    INTEGER(i4) :: max_aliases = 50
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Define
    PROCEDURE :: Resolve
  END TYPE CmdAliasMgr

  TYPE(CmdAliasMgr), SAVE, PUBLIC :: g_alias_mgr

  TYPE, PUBLIC :: Cmd_AliasDefine_In
    CHARACTER(LEN=16) :: name
    TYPE(Cmd) :: cmd
  END TYPE Cmd_AliasDefine_In

  TYPE, PUBLIC :: Cmd_AliasDefine_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_AliasDefine_Out

  TYPE, PUBLIC :: Cmd_AliasResolve_In
    CHARACTER(LEN=16) :: name
  END TYPE Cmd_AliasResolve_In

  TYPE, PUBLIC :: Cmd_AliasResolve_Out
    TYPE(Cmd) :: cmd
    LOGICAL :: found
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_AliasResolve_Out

  PUBLIC :: Cmd_AliasDefine_Structured
  PUBLIC :: Cmd_AliasResolve_Structured
  PUBLIC :: Cmd_AliasDefine
  PUBLIC :: Cmd_AliasResolve

CONTAINS

  SUBROUTINE Alias_Init(this, status)
    CLASS(CmdAliasMgr), INTENT(INOUT) :: this
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: ios

    ALLOCATE(this%aliases(this%max_aliases), STAT=ios)
    IF (ios /= 0 .AND. PRESENT(status)) THEN
      CALL init_error_status(status)
      status%status_code = IF_STATUS_ERROR
      RETURN
    END IF
    this%init = .TRUE.
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Alias_Init

  SUBROUTINE Alias_Define(this, name, cmd, status)
    CLASS(CmdAliasMgr), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(Cmd), INTENT(IN) :: cmd
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i, idx

    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%init) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    idx = 0
    DO i = 1, this%num_aliases
      IF (this%aliases(i)%defined .AND. TRIM(this%aliases(i)%name) == TRIM(name)) THEN
        idx = i
        EXIT
      END IF
    END DO

    IF (idx == 0) THEN
      IF (this%num_aliases >= this%max_aliases) THEN
        IF (PRESENT(status)) THEN
          status%status_code = IF_STATUS_INVALID
          WRITE(status%message, '(A,I0,A)') 'Maximum number of aliases (', this%max_aliases, ') reached'
        END IF
        RETURN
      END IF
      this%num_aliases = this%num_aliases + 1
      idx = this%num_aliases
    END IF

    this%aliases(idx)%name = name(1:MIN(16, LEN_TRIM(name)))
    this%aliases(idx)%cmd = cmd
    this%aliases(idx)%defined = .TRUE.

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Alias_Define

  SUBROUTINE Alias_Resolve(this, name, cmd, found, status)
    CLASS(CmdAliasMgr), INTENT(INOUT) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(Cmd), INTENT(OUT) :: cmd
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    INTEGER(i4) :: i

    found = .FALSE.
    IF (PRESENT(status)) CALL init_error_status(status)

    IF (.NOT. this%init) THEN
      CALL this%Init(status=status)
      IF (PRESENT(status) .AND. status%status_code /= IF_STATUS_OK) RETURN
    END IF

    DO i = 1, this%num_aliases
      IF (this%aliases(i)%defined .AND. TRIM(this%aliases(i)%name) == TRIM(name)) THEN
        cmd = this%aliases(i)%cmd
        found = .TRUE.
        IF (PRESENT(status)) status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Alias_Resolve

  SUBROUTINE Cmd_AliasDefine_Structured(in, out)
    TYPE(Cmd_AliasDefine_In), INTENT(IN) :: in
    TYPE(Cmd_AliasDefine_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_alias_mgr%Define(in%name, in%cmd, out%status)
  END SUBROUTINE Cmd_AliasDefine_Structured

  SUBROUTINE Cmd_AliasResolve_Structured(in, out)
    TYPE(Cmd_AliasResolve_In), INTENT(IN) :: in
    TYPE(Cmd_AliasResolve_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_alias_mgr%Resolve(in%name, out%cmd, out%found, out%status)
  END SUBROUTINE Cmd_AliasResolve_Structured

  SUBROUTINE Cmd_AliasDefine(name, cmd, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(Cmd), INTENT(IN) :: cmd
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_AliasDefine_In) :: in
    TYPE(Cmd_AliasDefine_Out) :: out

    in%name = name
    in%cmd = cmd
    CALL Cmd_AliasDefine_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_AliasDefine

  SUBROUTINE Cmd_AliasResolve(name, cmd, found, status)
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(Cmd), INTENT(OUT) :: cmd
    LOGICAL, INTENT(OUT) :: found
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_AliasResolve_In) :: in
    TYPE(Cmd_AliasResolve_Out) :: out

    in%name = name
    CALL Cmd_AliasResolve_Structured(in, out)
    cmd = out%cmd
    found = out%found
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_AliasResolve

END MODULE AP_InpScript_Alias