!===============================================================================
! MODULE: AP_InpScript_Debug
! LAYER:  L6_AP
! DOMAIN: Input/Script
! ROLE:   Impl â€?command system debugger
! BRIEF:  Command system debugger - breakpoints, variable display.
!===============================================================================
MODULE AP_InpScript_Debug
  USE IF_Prec_Core,    ONLY: i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE AP_Inp_Def, ONLY: CmdCtx
  IMPLICIT NONE
  PRIVATE

  !===============================================================================
  ! Structured I/O Types
  !===============================================================================
  TYPE, PUBLIC :: Cmd_DebugSetBrk_In
    INTEGER(i4) :: line_num
  END TYPE Cmd_DebugSetBrk_In

  TYPE, PUBLIC :: Cmd_DebugSetBrk_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_DebugSetBrk_Out

  TYPE, PUBLIC :: Cmd_DebugShowVars_In
    TYPE(CmdCtx) :: ctx
  END TYPE Cmd_DebugShowVars_In

  TYPE, PUBLIC :: Cmd_DebugShowVars_Out
    TYPE(ErrorStatusType) :: status
  END TYPE Cmd_DebugShowVars_Out

  !===============================================================================
  ! Debugger Type
  !===============================================================================
  TYPE, PUBLIC :: CmdDebugger
    INTEGER(i4), ALLOCATABLE :: breakpoints(:)
    INTEGER(i4) :: num_breakpoints = 0
    LOGICAL :: enabled = .FALSE.
    LOGICAL :: verbose = .TRUE.
    LOGICAL :: init = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetBreakpoint
    PROCEDURE :: CheckBreakpoint
  END TYPE CmdDebugger

  !===============================================================================
  ! Global Instance
  !===============================================================================
  TYPE(CmdDebugger), SAVE, PUBLIC :: g_debugger

  !===============================================================================
  ! Public Interface
  !===============================================================================
  PUBLIC :: Cmd_DebugSetBrk_Structured
  PUBLIC :: Cmd_DebugShowVars_Structured
  PUBLIC :: Cmd_DebugSetBrk
  PUBLIC :: Cmd_DebugShowVars

CONTAINS

  !-----------------------------------------------------------------------------
  ! Type-bound procedures
  !-----------------------------------------------------------------------------
  SUBROUTINE Debug_Init(this, enabled, verbose, status)
    CLASS(CmdDebugger), INTENT(INOUT) :: this
    LOGICAL, INTENT(IN), OPTIONAL :: enabled
    LOGICAL, INTENT(IN), OPTIONAL :: verbose
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(enabled)) this%enabled = enabled
    IF (PRESENT(verbose)) this%verbose = verbose
    this%init = .TRUE.
    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Debug_Init

  SUBROUTINE Debug_SetBreakpoint(this, line_num, status)
    CLASS(CmdDebugger), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: line_num
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) CALL init_error_status(status)
    IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE Debug_SetBreakpoint

  FUNCTION Debug_CheckBreakpoint(this, line_num) RESULT(is_breakpoint)
    CLASS(CmdDebugger), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: line_num
    LOGICAL :: is_breakpoint

    is_breakpoint = .FALSE.
  END FUNCTION Debug_CheckBreakpoint

  !-----------------------------------------------------------------------------
  ! Structured interface
  !-----------------------------------------------------------------------------
  SUBROUTINE Cmd_DebugSetBrk_Structured(in, out)
    TYPE(Cmd_DebugSetBrk_In), INTENT(IN) :: in
    TYPE(Cmd_DebugSetBrk_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    CALL g_debugger%SetBreakpoint(in%line_num, out%status)
  END SUBROUTINE Cmd_DebugSetBrk_Structured

  SUBROUTINE Cmd_DebugShowVars_Structured(in, out)
    TYPE(Cmd_DebugShowVars_In), INTENT(IN) :: in
    TYPE(Cmd_DebugShowVars_Out), INTENT(OUT) :: out

    CALL init_error_status(out%status)
    ! TODO: Implement actual variable display logic
    out%status%status_code = IF_STATUS_OK
  END SUBROUTINE Cmd_DebugShowVars_Structured

  !-----------------------------------------------------------------------------
  ! Legacy scalar interface (wrappers)
  !-----------------------------------------------------------------------------
  SUBROUTINE Cmd_DebugSetBrk(line_num, status)
    INTEGER(i4), INTENT(IN) :: line_num
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_DebugSetBrk_In) :: in
    TYPE(Cmd_DebugSetBrk_Out) :: out

    in%line_num = line_num
    CALL Cmd_DebugSetBrk_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_DebugSetBrk

  SUBROUTINE Cmd_DebugShowVars(ctx, status)
    TYPE(CmdCtx), INTENT(IN) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(Cmd_DebugShowVars_In) :: in
    TYPE(Cmd_DebugShowVars_Out) :: out

    in%ctx = ctx
    CALL Cmd_DebugShowVars_Structured(in, out)
    IF (PRESENT(status)) status = out%status
  END SUBROUTINE Cmd_DebugShowVars

END MODULE AP_InpScript_Debug