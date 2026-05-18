!===============================================================================
! MODULE: RT_Brg_Mgr
! LAYER:  L5_RT
! DOMAIN: Bridge
! ROLE:   Mgr — checkpoint/restart coordination
! BRIEF:  RT_Bridge_Domain lifecycle, Init/Finalize/GetSummary.
!===============================================================================
!
! Contents:
!   Types: RT_Bridge_State / RT_Bridge_Ctrl / RT_Bridge_Domain
!   Subroutines: RT_Bridge_Domain_Init / RT_Bridge_Domain_Finalize
!
! Design outline: Outline 12.2, 2.6a (L5_RT Bridge domain)
! USE contract (7.3): L1/L2/L3/L4; no L6
! WriteBack contract (7.2): no direct L3 Desc write; L5 via MD_WB_*
! Status: Phase B (Arg-wrapped)
! Last verified: 2026-03-11
! Theory: N/A
!======================================================================
MODULE RT_Brg_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE RT_Global_Ctx, ONLY: RT_Brg_State, RT_Brg_Ctrl_Desc
  USE RT_Asm_Def, ONLY: RT_Asm_Desc
  IMPLICIT NONE
  PRIVATE

  ! Bridge types imported from RT_Global_Ctx_Types (unified state management)
  ! RT_Brg_State: checkpoint state (lastCheckpointIncr, lastCheckpointTime)
  ! RT_Brg_Ctrl_Desc: checkpoint config (checkpointFreq, checkpointRestart)

  TYPE, PUBLIC :: RT_Bridge_Ctx
    INTEGER(i4) :: step_idx = 0_i4   ! [ ] Step checkpoint
    INTEGER(i4) :: incr_idx = 0_i4   ! [ ] checkpoint
  END TYPE RT_Bridge_Ctx

  ! --- Arg types (Phase B) ---
  TYPE, PUBLIC :: RT_Brg_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""    ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE RT_Brg_GetSummary_Arg

  TYPE, PUBLIC :: RT_Bridge_Domain
    TYPE(RT_Bridge_Ctx)       :: ctx
    TYPE(RT_Brg_State) :: state
    TYPE(RT_Brg_Ctrl_Desc)  :: ctrl
    ! Mesh-scale assembly descriptor bounds (filled from L3 via RT_Asm_Brg_FromL3Model on MD_Model_Brg path).
    ! Not a substitute for RT_Asm_Domain%Init / BuildPattern ordering — consumers must respect that lifecycle.
    TYPE(RT_Asm_Desc) :: assembly_desc
    LOGICAL               :: initialized = .FALSE.
    !--- WriteBack/Output bridge coordination (v4.0) ---
    LOGICAL :: wb_enabled       = .TRUE.   ! enable write-back after convergence
    LOGICAL :: output_enabled   = .TRUE.   ! enable output after convergence
    INTEGER(i4) :: wb_frequency = 1_i4     ! write-back every N increments
    INTEGER(i4) :: last_wb_incr = 0_i4     ! last write-back increment
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SyncStepIncr
    PROCEDURE :: Finalize
    PROCEDURE :: GetSummary
    PROCEDURE :: CallL4
    PROCEDURE :: CallL6
    PROCEDURE :: MapErrorCode
  END TYPE RT_Bridge_Domain

  ! Error code mapping constants (L5 <-> L4/L6)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_NONE        = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_NOT_INIT    = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_L4_CALL     = -10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_L6_CALL     = -20_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_MAPPING     = -30_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_BRG_ERR_VERSION     = -40_i4

CONTAINS

  SUBROUTINE Finalize(this)
    CLASS(RT_Bridge_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    CALL this%assembly_desc%Finalize()
    ! Note: Derived types are automatically deallocated, just reset scalar components
    this%initialized = .FALSE.
  END SUBROUTINE Finalize

  SUBROUTINE SyncStepIncr(this, step_idx, incr_idx)
    CLASS(RT_Bridge_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: step_idx
    INTEGER(i4),             INTENT(IN)    :: incr_idx
    IF (.NOT. this%initialized) RETURN
    this%ctx%inc%step_idx = step_idx
    this%ctx%inc%incr_idx = incr_idx
  END SUBROUTINE SyncStepIncr

  SUBROUTINE Init(this, status, step_idx, incr_idx)
    CLASS(RT_Bridge_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: step_idx
    INTEGER(i4),             INTENT(IN), OPTIONAL :: incr_idx
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%ctx%inc%step_idx = MERGE(step_idx, 0_i4, PRESENT(step_idx))
    this%ctx%inc%incr_idx = MERGE(incr_idx, 0_i4, PRESENT(incr_idx))
    ! Note: ctrl is a derived type, no explicit construction needed
    this%initialized   = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Init

  !====================================================================
  ! RT_Bridge_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE GetSummary(this, arg)
    CLASS(RT_Bridge_Domain),        INTENT(IN)    :: this
    TYPE(RT_Brg_GetSummary_Arg), INTENT(INOUT) :: arg
    CALL RT_Bridge_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE GetSummary

  SUBROUTINE RT_Bridge_GetSummary_Impl(this, summary, status)
    CLASS(RT_Bridge_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,ES10.3)') &
      "Bridge Summary: LastCheckpoint=", this%state%lastCheckpointIncr, &
      ", LastCheckpointTime=", this%state%lastCheckpointTime

    status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_Bridge_GetSummary_Impl

  !====================================================================
  ! CallL4 - Unified L5->L4 bridge call (stateless dispatch)
  !====================================================================
  SUBROUTINE CallL4(this, slot_id, operation, status)
    CLASS(RT_Bridge_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: slot_id
    INTEGER(i4),             INTENT(IN)    :: operation
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge not initialized for L4 call"
      RETURN
    END IF

    ! Stateless dispatch to L4_PH layer
    ! Placeholder: route based on slot_id and operation type
    ! CALL PH_Bridge_Dispatch(slot_id, operation, status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE CallL4

  !====================================================================
  ! CallL6 - Unified L5->L6 bridge call (reserved interface)
  !====================================================================
  SUBROUTINE CallL6(this, request_type, payload_size, status)
    CLASS(RT_Bridge_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: request_type
    INTEGER(i4),             INTENT(IN)    :: payload_size
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Bridge not initialized for L6 call"
      RETURN
    END IF

    ! Reserved: L6 application layer interface
    ! Placeholder: future L6_AP integration
    ! CALL AP_Bridge_Receive(request_type, payload_size, status)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE CallL6

  !====================================================================
  ! MapErrorCode - Map L4/L6 error codes to L5 ErrorStatusType
  !====================================================================
  SUBROUTINE MapErrorCode(this, source_layer, source_code, status)
    CLASS(RT_Bridge_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: source_layer  ! 4=L4, 6=L6
    INTEGER(i4),             INTENT(IN)  :: source_code
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (source_code == 0_i4) THEN
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Map foreign error code to L5 status
    SELECT CASE (source_layer)
    CASE (4_i4)  ! L4_PH errors
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'L4 error mapped: code=', source_code
    CASE (6_i4)  ! L6_AP errors
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'L6 error mapped: code=', source_code
    CASE DEFAULT
      status%status_code = IF_STATUS_INVALID
      status%message = 'Unknown source layer for error mapping'
    END SELECT
  END SUBROUTINE MapErrorCode

END MODULE RT_Brg_Mgr