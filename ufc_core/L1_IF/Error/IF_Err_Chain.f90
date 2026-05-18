!===============================================================================
! MODULE: IF_Err_Chain
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Chain
! BRIEF:  Cross-layer error propagation protocol and Harness gate checks.
!===============================================================================
!
! Design:
!   - Every subroutine returns ErrorStatusType via INTENT(OUT) status.
!   - Errors propagate UPWARD: L4 -> L5 -> L6 (callee -> caller).
!   - Severity can only ESCALATE (never downgrade) during propagation.
!   - Harness gates check severity thresholds before proceeding.
!
! Error code ranges:
!   L1_IF: 1000-1999   Math: 2000-2999   L2_NM: 3000-3999
!   L3_MD: 4000-4999   L4_PH: 5000-5999  L5_RT: 6000-6999  L6_AP: 7000-7999
!
! Contents (A-Z):
!   Types:
!     ErrorChainStats          [State] Per-run chain statistics accumulator
!   Subroutines:
!     UFC_Err_Chain_Init       [P0] Reset chain statistics
!     UFC_Err_Chain_Summary    [P3] Write chain stats to output structure
!     UFC_Err_Propagate        [P1] Propagate error from callee to caller
!     UFC_Err_Wrap             [P1] Wrap low-level error with higher context
!   Functions:
!     UFC_Err_Gate_Check       [P2] Harness gate: continue / warn / halt
!     UFC_Err_Get_Layer        [P2] Determine originating layer from code
!     UFC_Err_Is_Fatal         [P2] Check if error is FATAL or CRITICAL
!     UFC_Err_Is_Recoverable   [P2] Check if error is recoverable
!
! Constants: UFC_ERR_GATE_CONTINUE, UFC_ERR_GATE_WARN, UFC_ERR_GATE_HALT
!
! Status: CORE | Last verified: 2026-04-28
!===============================================================================

MODULE IF_Err_Chain
  USE IF_Err_Def, ONLY: IF_Err_Status_State, &
                        IF_ERROR_SEVERITY_INFO, IF_ERROR_SEVERITY_WARNING, &
                        IF_ERROR_SEVERITY_ERROR, IF_ERROR_SEVERITY_CRITICAL, &
                        IF_ERROR_SEVERITY_FATAL, &
                        IF_ERROR_CATEGORY_OK, &
                        i4, i8, wp
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: UFC_Err_Propagate
  PUBLIC :: UFC_Err_Wrap
  PUBLIC :: UFC_Err_Gate_Check
  PUBLIC :: UFC_Err_Is_Fatal
  PUBLIC :: UFC_Err_Is_Recoverable
  PUBLIC :: UFC_Err_Get_Layer
  PUBLIC :: UFC_Err_Chain_Init
  PUBLIC :: UFC_Err_Chain_Summary

  PUBLIC :: UFC_ERR_GATE_CONTINUE
  PUBLIC :: UFC_ERR_GATE_WARN
  PUBLIC :: UFC_ERR_GATE_HALT

  !-----------------------------------------------------------------------------
  ! Gate action codes (returned by UFC_Err_Gate_Check)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: UFC_ERR_GATE_CONTINUE = 0_i4
  INTEGER(i4), PARAMETER :: UFC_ERR_GATE_WARN     = 1_i4
  INTEGER(i4), PARAMETER :: UFC_ERR_GATE_HALT     = 2_i4

  !-----------------------------------------------------------------------------
  ! Layer identification from error code
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: LAYER_UNKNOWN = 0_i4
  INTEGER(i4), PARAMETER :: LAYER_L1_IF   = 1_i4
  INTEGER(i4), PARAMETER :: LAYER_L2_NM   = 2_i4
  INTEGER(i4), PARAMETER :: LAYER_L3_MD   = 3_i4
  INTEGER(i4), PARAMETER :: LAYER_L4_PH   = 4_i4
  INTEGER(i4), PARAMETER :: LAYER_L5_RT   = 5_i4
  INTEGER(i4), PARAMETER :: LAYER_L6_AP   = 6_i4

  !-----------------------------------------------------------------------------
  ! TYPE: ErrorChainStats  [State]  (canonical: IF_Err_ChainStats_State)
  ! Per-run chain statistics accumulator (module-level state).
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: ErrorChainStats
    INTEGER(i4) :: total_propagated = 0_i4
    INTEGER(i4) :: total_wrapped    = 0_i4
    INTEGER(i4) :: total_halted     = 0_i4
    INTEGER(i4) :: max_severity_seen = IF_ERROR_SEVERITY_INFO
    LOGICAL     :: initialized = .FALSE.
  END TYPE ErrorChainStats

  TYPE(ErrorChainStats), SAVE :: g_chain_stats

CONTAINS

  !=============================================================================
  ! [P0] UFC_Err_Chain_Init - reset chain statistics
  !=============================================================================
  SUBROUTINE UFC_Err_Chain_Init()
    g_chain_stats%total_propagated  = 0_i4
    g_chain_stats%total_wrapped     = 0_i4
    g_chain_stats%total_halted      = 0_i4
    g_chain_stats%max_severity_seen = IF_ERROR_SEVERITY_INFO
    g_chain_stats%initialized       = .TRUE.
  END SUBROUTINE UFC_Err_Chain_Init

  !=============================================================================
  ! [P1] UFC_Err_Propagate - propagate error from callee to caller
  !
  !   Pattern:
  !     CALL sub_step(args, local_status)
  !     IF (local_status%status_code /= IF_STATUS_OK) THEN
  !       CALL UFC_Err_Propagate(local_status, status, "My_Procedure")
  !       RETURN
  !     END IF
  !
  !   Rules:
  !     1. Copies all fields from source to target.
  !     2. Prepends caller source to the chain (source field).
  !     3. Severity can only escalate, never downgrade.
  !     4. Increments error_count.
  !=============================================================================
  SUBROUTINE UFC_Err_Propagate(source, target, caller_name)
    TYPE(IF_Err_Status_State), INTENT(IN)    :: source
    TYPE(IF_Err_Status_State), INTENT(INOUT) :: target
    CHARACTER(LEN=*),      INTENT(IN)    :: caller_name

    target%status_code = source%status_code
    target%category    = source%category
    target%has_error   = source%has_error
    target%error_id    = source%error_id
    target%io_stat     = source%io_stat

    ! Severity: only escalate
    IF (source%severity > target%severity) THEN
      target%severity = source%severity
    END IF

    ! Chain the source: "caller <- original_source"
    IF (LEN_TRIM(source%source) > 0) THEN
      target%source = TRIM(caller_name) // " <- " // TRIM(source%source)
    ELSE
      target%source = caller_name
    END IF

    ! Preserve original message, prepend caller context
    target%message = "[" // TRIM(caller_name) // "] " // TRIM(source%message)

    target%error_count = source%error_count + 1

    ! Update global chain stats
    IF (g_chain_stats%initialized) THEN
      g_chain_stats%total_propagated = g_chain_stats%total_propagated + 1
      IF (target%severity > g_chain_stats%max_severity_seen) THEN
        g_chain_stats%max_severity_seen = target%severity
      END IF
    END IF
  END SUBROUTINE UFC_Err_Propagate

  !=============================================================================
  ! [P1] UFC_Err_Wrap - wrap a low-level error with higher-layer context
  !
  !   Used at layer boundaries to re-code an error into the caller's
  !   error code range while preserving the original information.
  !
  !   Example: L4 constitutive failure (5010) wrapped as L5 increment
  !   failure (6010) at the L5 assembly level.
  !=============================================================================
  SUBROUTINE UFC_Err_Wrap(source, target, new_code, wrapper_name, extra_msg)
    TYPE(IF_Err_Status_State), INTENT(IN)    :: source
    TYPE(IF_Err_Status_State), INTENT(INOUT) :: target
    INTEGER(i4),           INTENT(IN)    :: new_code
    CHARACTER(LEN=*),      INTENT(IN)    :: wrapper_name
    CHARACTER(LEN=*),      INTENT(IN), OPTIONAL :: extra_msg

    CHARACTER(LEN=512) :: combined_msg

    target%status_code = new_code
    target%category    = source%category
    target%has_error   = .TRUE.
    target%error_id    = source%error_id

    ! Severity: take the higher of source or current
    IF (source%severity > target%severity) THEN
      target%severity = source%severity
    END IF

    ! Build chain source
    IF (LEN_TRIM(source%source) > 0) THEN
      target%source = TRIM(wrapper_name) // " <~ " // TRIM(source%source)
    ELSE
      target%source = wrapper_name
    END IF

    ! Build wrapped message: "[wrapper] extra_msg | original: source_msg"
    IF (PRESENT(extra_msg)) THEN
      WRITE(combined_msg, '(A,A,A,A,A,A,A)') &
        "[", TRIM(wrapper_name), "] ", TRIM(extra_msg), &
        " | original: ", TRIM(source%message), ""
    ELSE
      WRITE(combined_msg, '(A,A,A,A,A)') &
        "[", TRIM(wrapper_name), "] wrapped: ", TRIM(source%message), ""
    END IF
    target%message = combined_msg

    target%error_count = source%error_count + 1

    ! Update global chain stats
    IF (g_chain_stats%initialized) THEN
      g_chain_stats%total_wrapped = g_chain_stats%total_wrapped + 1
    END IF
  END SUBROUTINE UFC_Err_Wrap

  !=============================================================================
  ! [P2] UFC_Err_Gate_Check - Harness gate: decide continue / warn / halt
  !
  !   threshold_severity: the severity at or above which the gate halts.
  !   Typical Harness gate thresholds:
  !     - Element compute gate: ERROR (2)   — halt on element failure
  !     - Increment gate:       ERROR (2)   — halt on non-convergence
  !     - Step gate:            CRITICAL (3) — halt on critical failure
  !     - Job gate:             FATAL (4)    — halt only on fatal
  !
  !   Returns UFC_ERR_GATE_CONTINUE / UFC_ERR_GATE_WARN / UFC_ERR_GATE_HALT.
  !=============================================================================
  FUNCTION UFC_Err_Gate_Check(status, threshold_severity) RESULT(action)
    TYPE(IF_Err_Status_State), INTENT(IN) :: status
    INTEGER(i4),           INTENT(IN) :: threshold_severity
    INTEGER(i4) :: action

    IF (status%status_code == 0_i4 .AND. .NOT. status%has_error) THEN
      action = UFC_ERR_GATE_CONTINUE
      RETURN
    END IF

    IF (status%severity >= threshold_severity) THEN
      action = UFC_ERR_GATE_HALT
      IF (g_chain_stats%initialized) THEN
        g_chain_stats%total_halted = g_chain_stats%total_halted + 1
      END IF
    ELSE IF (status%severity >= IF_ERROR_SEVERITY_WARNING) THEN
      action = UFC_ERR_GATE_WARN
    ELSE
      action = UFC_ERR_GATE_CONTINUE
    END IF
  END FUNCTION UFC_Err_Gate_Check

  !=============================================================================
  ! [P2] UFC_Err_Is_Fatal - check if error is FATAL or CRITICAL
  !=============================================================================
  LOGICAL FUNCTION UFC_Err_Is_Fatal(status)
    TYPE(IF_Err_Status_State), INTENT(IN) :: status
    UFC_Err_Is_Fatal = (status%severity >= IF_ERROR_SEVERITY_CRITICAL)
  END FUNCTION UFC_Err_Is_Fatal

  !=============================================================================
  ! [P2] UFC_Err_Is_Recoverable - check if error might be recoverable
  !   WARNING or INFO severity errors are considered recoverable.
  !=============================================================================
  LOGICAL FUNCTION UFC_Err_Is_Recoverable(status)
    TYPE(IF_Err_Status_State), INTENT(IN) :: status
    UFC_Err_Is_Recoverable = (status%severity < IF_ERROR_SEVERITY_ERROR)
  END FUNCTION UFC_Err_Is_Recoverable

  !=============================================================================
  ! [P2] UFC_Err_Get_Layer - determine originating layer from error code
  !=============================================================================
  FUNCTION UFC_Err_Get_Layer(error_code) RESULT(layer_id)
    INTEGER(i4), INTENT(IN) :: error_code
    INTEGER(i4) :: layer_id

    IF (error_code <= 0) THEN
      layer_id = LAYER_UNKNOWN
    ELSE IF (error_code >= 1000 .AND. error_code <= 1999) THEN
      layer_id = LAYER_L1_IF
    ELSE IF (error_code >= 2000 .AND. error_code <= 2999) THEN
      layer_id = LAYER_L1_IF
    ELSE IF (error_code >= 3000 .AND. error_code <= 3999) THEN
      layer_id = LAYER_L2_NM
    ELSE IF (error_code >= 4000 .AND. error_code <= 4999) THEN
      layer_id = LAYER_L3_MD
    ELSE IF (error_code >= 5000 .AND. error_code <= 5999) THEN
      layer_id = LAYER_L4_PH
    ELSE IF (error_code >= 6000 .AND. error_code <= 6999) THEN
      layer_id = LAYER_L5_RT
    ELSE IF (error_code >= 7000 .AND. error_code <= 7999) THEN
      layer_id = LAYER_L6_AP
    ELSE
      layer_id = LAYER_UNKNOWN
    END IF
  END FUNCTION UFC_Err_Get_Layer

  !=============================================================================
  ! [P3] UFC_Err_Chain_Summary - write chain statistics to status structure
  !=============================================================================
  SUBROUTINE UFC_Err_Chain_Summary(stats)
    TYPE(ErrorChainStats), INTENT(OUT) :: stats
    stats = g_chain_stats
  END SUBROUTINE UFC_Err_Chain_Summary

END MODULE IF_Err_Chain
