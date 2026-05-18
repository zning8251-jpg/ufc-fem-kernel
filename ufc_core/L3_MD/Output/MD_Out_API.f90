!======================================================================
! Module: MD_Out
! Layer:  L3_MD - Model Definition Layer
! Domain: Output / Domain
! Purpose: Output domain container - field/history/contact/energy requests.
!
! SIO Compliance (Principle #14):
!   All subroutines follow unified *_Arg bundles with [IN]/[OUT] comments.
!   Arg bundles provided for procedure-style calling.
!
! Status: ACTIVE | DOMAIN-FACADE | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   L3 AUTHORITY: MD_Output_Def.f90
!   This module:  Domain facade with Arg bundles and domain-level procedures
!======================================================================
!   Desc (Write-Once): requests(:) with type/variables/frequency/format
!   State (WriteBack):  output_state with lastWrittenInc/Time/Frames
!   Algo:               OutputAlgo (default format, compression)
!
! WriteBack whitelist:
!   - output_state%lastWrittenInc
!   - output_state%lastWrittenTime
!   - output_state%totalFrames
!
! Contents:
!   Types:
!     OutputAlgo ?Algorithm parameters
!     MD_OutputRequest_Desc ?Write-Once output request descriptor
!     MD_Output_State ?WriteBack-gated runtime state
!     MD_Output_Domain ?Domain container
!   Subroutines (A-Z):
!     MD_Output_Domain_AddRequest
!     MD_Output_Domain_Finalize
!     MD_Output_Domain_GetRequest ?Phase B: by-index access
!     MD_Output_Domain_GetRequestsForStep
!     MD_Output_Domain_Init
!     MD_Output_Domain_IsOutputDue ?Phase B: increment trigger check
!     MD_Output_WriteBack
!
! Status: Phase B (Arg-wrapped: GetSummary)
! Last verified: 2026-03-11
! Theory: N/A
!======================================================================
!>>> UFC_L3_QUENCH | Domain:Out | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Output/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Out | Role:Core | FuncSet:Init,Valid,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Out_API
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, &
                            IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_DP
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Output request type enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: OUT_FIELD    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: OUT_HISTORY  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: OUT_CONTACT  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: OUT_ENERGY   = 4_i4

  !--------------------------------------------------------------------
  ! Output format enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: FMT_ODB  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: FMT_VTK  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: FMT_HDF5 = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: FMT_CSV  = 4_i4

  !--------------------------------------------------------------------
  ! OutputAlgo ?Algorithm parameters
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: OutputAlgo
    INTEGER(i4) :: default_format     = FMT_ODB
    INTEGER(i4) :: compression_level  = 0_i4
    LOGICAL     :: parallel_io        = .FALSE.
  END TYPE OutputAlgo

  !--------------------------------------------------------------------
  ! MD_OutputRequest_Desc ?Write-Once output request descriptor
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_OutputRequest_Desc
    CHARACTER(LEN=64) :: name          = ""
    INTEGER(i4)       :: request_id    = 0_i4
    INTEGER(i4)       :: request_type  = OUT_FIELD
    CHARACTER(LEN=16) :: variables(32) = ""   ! up to 32 variable names (S/U/RF/E/PE/...)
    INTEGER(i4)       :: n_variables   = 0_i4
    CHARACTER(LEN=64) :: target_set    = ""   ! assembly set name
    INTEGER(i4)       :: frequency     = 1_i4 ! every N increments
    REAL(wp)          :: time_interval = 0.0_wp
    INTEGER(i4)       :: format        = FMT_ODB
    INTEGER(i4)       :: step_ref      = 0_i4 ! index into MD_Step_Domain
  END TYPE MD_OutputRequest_Desc

  !--------------------------------------------------------------------
  ! MD_Output_State ?WriteBack-gated runtime state
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_State
    INTEGER(i4) :: lastWrittenInc  = 0_i4
    REAL(wp)    :: lastWrittenTime = 0.0_wp
    INTEGER(i4) :: totalFrames     = 0_i4
    ! [Data chain] three-step indexing L3→L5
    INTEGER(i4) :: step_idx = 0_i4   ! Step
    INTEGER(i4) :: incr_idx = 0_i4  ! substep / increment index
  END TYPE MD_Output_State

  !--------------------------------------------------------------------
  ! MD_Output_Domain ?Domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_Domain
    !--- Desc (Write-Once) ---
    TYPE(MD_OutputRequest_Desc), ALLOCATABLE :: requests(:)
    INTEGER(i4)                              :: n_requests = 0_i4
    INTEGER(i4)                              :: capacity   = 0_i4

    !--- State (WriteBack whitelist) ---
    TYPE(MD_Output_State) :: output_state

    !--- Algo ---
    TYPE(OutputAlgo) :: algo

    !--- Internal ---
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init               => MD_Output_Domain_Init
    PROCEDURE :: Finalize           => MD_Output_Domain_Finalize
    PROCEDURE :: AddRequest         => MD_Output_Domain_AddRequest
    PROCEDURE :: GetRequest         => MD_Output_Domain_GetRequest
    PROCEDURE :: GetRequestsForStep => MD_Output_Domain_GetRequestsForStep
    PROCEDURE :: IsOutputDue        => MD_Output_Domain_IsOutputDue
    PROCEDURE :: GetRequestByName   => MD_Output_Domain_GetRequestByName
    PROCEDURE :: GetSummary         => MD_Output_Domain_GetSummary
    PROCEDURE :: WriteBack          => MD_Output_WriteBack
  END TYPE MD_Output_Domain

  !--------------------------------------------------------------------
  ! Arg types (Phase B)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Output_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Output_GetSummary_Arg

  ! Index-based GetRequest (?????? Phase 3)
  TYPE, PUBLIC :: MD_Output_GetRequest_Arg
    TYPE(MD_OutputRequest_Desc) :: desc
  END TYPE MD_Output_GetRequest_Arg

  ! Arg for GetRequestByName (Phase B: >4 params -> Arg)
  TYPE, PUBLIC :: MD_Output_GetRequestByName_Arg
    INTEGER(i4) :: req_idx = 0_i4
    LOGICAL :: found = .FALSE.
  END TYPE MD_Output_GetRequestByName_Arg

  PUBLIC :: MD_Output_GetRequest_Idx, MD_Output_GetRequestByName_Idx

CONTAINS

  !====================================================================
  ! MD_Output_Domain_AddRequest
  !====================================================================
  SUBROUTINE MD_Output_Domain_AddRequest(this, desc, status)
    CLASS(MD_Output_Domain),     INTENT(INOUT) :: this
    TYPE(MD_OutputRequest_Desc), INTENT(IN)    :: desc
    TYPE(ErrorStatusType),       INTENT(OUT)   :: status

    TYPE(MD_OutputRequest_Desc), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: new_cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    IF (this%n_requests >= this%capacity) THEN
      new_cap = MAX(16_i4, this%capacity * 2_i4)
      ALLOCATE(tmp(new_cap))
      IF (this%n_requests > 0) tmp(1:this%n_requests) = this%requests(1:this%n_requests)
      CALL MOVE_ALLOC(tmp, this%requests)
      this%capacity = new_cap
    END IF

    this%n_requests = this%n_requests + 1_i4
    this%requests(this%n_requests) = desc
    this%requests(this%n_requests)%request_id = this%n_requests
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_Domain_AddRequest

  !====================================================================
  ! MD_Output_Domain_Finalize
  !====================================================================
  SUBROUTINE MD_Output_Domain_Finalize(this)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this

    IF (ALLOCATED(this%requests)) DEALLOCATE(this%requests)
    this%n_requests = 0_i4
    this%capacity   = 0_i4
    this%output_state%lastWrittenInc  = 0_i4
    this%output_state%lastWrittenTime = 0.0_wp
    this%output_state%totalFrames     = 0_i4
    this%initialized = .FALSE.

  END SUBROUTINE MD_Output_Domain_Finalize

  !====================================================================
  ! MD_Output_Domain_GetRequestsForStep
  ! Phase A: If step_output_ids provided (from index tree), use directly.
  !          Otherwise scan requests by step_ref (fallback).
  !====================================================================
  SUBROUTINE MD_Output_Domain_GetRequestsForStep(this, step_idx, req_indices, n_found, status, step_output_ids)
    CLASS(MD_Output_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: step_idx
    INTEGER(i4),             INTENT(OUT) :: req_indices(:)
    INTEGER(i4),             INTENT(OUT) :: n_found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: step_output_ids(:)

    INTEGER(i4) :: i, n, idx

    CALL init_error_status(status)
    n_found = 0_i4
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    ! Use index tree when step_output_ids provided (OUTPUT_DOMAIN_DESIGN Phase A)
    ! Caller must pass allocated array; use PRESENT to detect optional arg.
    IF (PRESENT(step_output_ids)) THEN
      n = SIZE(step_output_ids)
      DO i = 1, MIN(n, SIZE(req_indices))
        idx = step_output_ids(i)
        IF (idx >= 1 .AND. idx <= this%n_requests) THEN
          n_found = n_found + 1_i4
          req_indices(n_found) = idx
        END IF
      END DO
      status%status_code = IF_STATUS_OK
      RETURN
    END IF

    ! Fallback: scan by step_ref
    DO i = 1, this%n_requests
      IF (this%requests(i)%step_ref == step_idx .OR. this%requests(i)%step_ref == 0) THEN
        n_found = n_found + 1_i4
        IF (n_found <= SIZE(req_indices)) req_indices(n_found) = i
      END IF
    END DO
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_Domain_GetRequestsForStep

  !====================================================================
  ! MD_Output_Domain_Init
  !   P2 DataPlatform: registers MD_OutputRequest_Desc type for persistence.
  !====================================================================
  SUBROUTINE MD_Output_Domain_Init(this, est_requests, status)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: est_requests
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()

    ! P2 DataPlatform: register MD_OutputRequest_Desc struct type
    CALL MD_Output_DP_RegisterStructType(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    this%capacity = MAX(16_i4, est_requests)
    ALLOCATE(this%requests(this%capacity))
    this%n_requests  = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_Domain_Init

  !====================================================================
  ! MD_Output_DP_RegisterStructType - DataPlatform type registration (P2)
  !   Registers MD_OutputRequest_Desc for checkpoint/persistence.
  !====================================================================
  SUBROUTINE MD_Output_DP_RegisterStructType(status)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(StructFieldDesc) :: fields(10)
    INTEGER(i4) :: offset

    CALL init_error_status(status)
    offset = 0
    fields(1)%field_name = 'name'
    fields(1)%data_type = IF_DATA_TYPE_CHAR
    fields(1)%offset_bytes = offset
    fields(1)%elem_len = 64
    offset = offset + 64
    fields(2)%field_name = 'request_id'
    fields(2)%data_type = IF_DATA_TYPE_INT
    fields(2)%offset_bytes = offset
    offset = offset + 4
    fields(3)%field_name = 'request_type'
    fields(3)%data_type = IF_DATA_TYPE_INT
    fields(3)%offset_bytes = offset
    offset = offset + 4
    fields(4)%field_name = 'n_variables'
    fields(4)%data_type = IF_DATA_TYPE_INT
    fields(4)%offset_bytes = offset
    offset = offset + 4
    fields(5)%field_name = 'target_set'
    fields(5)%data_type = IF_DATA_TYPE_CHAR
    fields(5)%offset_bytes = offset
    fields(5)%elem_len = 64
    offset = offset + 64
    fields(6)%field_name = 'frequency'
    fields(6)%data_type = IF_DATA_TYPE_INT
    fields(6)%offset_bytes = offset
    offset = offset + 4
    fields(7)%field_name = 'time_interval'
    fields(7)%data_type = IF_DATA_TYPE_DP
    fields(7)%offset_bytes = offset
    offset = offset + 8
    fields(8)%field_name = 'format'
    fields(8)%data_type = IF_DATA_TYPE_INT
    fields(8)%offset_bytes = offset
    offset = offset + 4
    fields(9)%field_name = 'step_ref'
    fields(9)%data_type = IF_DATA_TYPE_INT
    fields(9)%offset_bytes = offset
    offset = offset + 4
    CALL dp_register_struct_type('MD_OutputRequest_Desc', fields, 9, status)
  END SUBROUTINE MD_Output_DP_RegisterStructType

  !====================================================================
  ! MD_Output_WriteBack ?WriteBack whitelist fields only
  !   Whitelist: lastWrittenInc, lastWrittenTime, totalFrames
  !====================================================================
  SUBROUTINE MD_Output_WriteBack(this, lastWrittenInc, lastWrittenTime, &
                                  totalFrames, status, step_idx, incr_idx)
    CLASS(MD_Output_Domain), INTENT(INOUT) :: this
    INTEGER(i4),             INTENT(IN)    :: lastWrittenInc
    REAL(wp),                INTENT(IN)    :: lastWrittenTime
    INTEGER(i4),             INTENT(IN)    :: totalFrames
    TYPE(ErrorStatusType),   INTENT(OUT)   :: status
    INTEGER(i4),             INTENT(IN), OPTIONAL :: step_idx, incr_idx

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    this%output_state%lastWrittenInc  = lastWrittenInc
    this%output_state%lastWrittenTime = lastWrittenTime
    this%output_state%totalFrames     = totalFrames
    IF (PRESENT(step_idx)) this%output_state%inc%step_idx = step_idx
    IF (PRESENT(incr_idx)) this%output_state%inc%incr_idx = incr_idx
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_WriteBack

  !====================================================================
  ! MD_Output_Domain_GetRequest ?read-only copy of request by index
  !====================================================================
  SUBROUTINE MD_Output_Domain_GetRequest(this, idx, desc, status)
    CLASS(MD_Output_Domain),     INTENT(IN)  :: this
    INTEGER(i4),                 INTENT(IN)  :: idx
    TYPE(MD_OutputRequest_Desc), INTENT(OUT) :: desc
    TYPE(ErrorStatusType),       INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_requests) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF
    desc = this%requests(idx)
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_Domain_GetRequest

  !====================================================================
  ! MD_Output_GetRequest_Idx - Standalone index-based API (domain passed in to avoid UFC_GlobalContainer dep)
  !====================================================================
  SUBROUTINE MD_Output_GetRequest_Idx(dom, req_idx, arg, status)
    TYPE(MD_Output_Domain),          INTENT(IN)    :: dom
    INTEGER(i4),                    INTENT(IN)    :: req_idx
    TYPE(MD_Output_GetRequest_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (.NOT. dom%initialized .OR. req_idx < 1 .OR. req_idx > dom%n_requests) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    arg%desc = dom%requests(req_idx)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Output_GetRequest_Idx

  !====================================================================
  ! MD_Output_Domain_IsOutputDue ?check if output should be written
  !
  ! Computation chain:
  !   For request [idx] at current increment [inc_id] and time [sim_time]:
  !
  !   Case A: frequency-based  (time_interval == 0.0)
  !     due = MOD(inc_id - lastWrittenInc, frequency) == 0
  !     Triggers every [frequency] increments from last write.
  !
  !   Case B: time-interval-based  (time_interval > 0.0)
  !     due = sim_time >= lastWrittenTime + time_interval - EPS
  !     Triggers when sim_time has advanced by at least time_interval
  !     since the last write (EPS = small relative tolerance).
  !
  !   Returns .TRUE. if output is due; .FALSE. otherwise.
  !   step_ref == 0 means "all steps" (always considered for this check).
  !
  ! Called by L5_RT at the end of each converged increment before
  ! committing to the next increment.
  !====================================================================
  SUBROUTINE MD_Output_Domain_IsOutputDue(this, idx, inc_id, sim_time, &
                                           is_due, status)
    CLASS(MD_Output_Domain), INTENT(IN)  :: this
    INTEGER(i4),             INTENT(IN)  :: idx
    INTEGER(i4),             INTENT(IN)  :: inc_id
    REAL(wp),                INTENT(IN)  :: sim_time
    LOGICAL,                 INTENT(OUT) :: is_due
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    REAL(wp), PARAMETER :: EPS = 1.0E-10_wp   ! relative tolerance for time check
    INTEGER(i4) :: delta_inc

    CALL init_error_status(status)
    is_due = .FALSE.

    IF (.NOT. this%initialized .OR. idx < 1 .OR. idx > this%n_requests) THEN
      status%status_code = IF_STATUS_INVALID; RETURN
    END IF

    ASSOCIATE(req => this%requests(idx))

    IF (req%time_interval > 0.0_wp) THEN
      ! Case B: time-interval trigger
      is_due = (sim_time >= this%output_state%lastWrittenTime + &
                req%time_interval - EPS)
    ELSE
      ! Case A: increment-frequency trigger
      delta_inc = inc_id - this%output_state%lastWrittenInc
      is_due    = (MOD(delta_inc, MAX(1_i4, req%frequency)) == 0)
    END IF

    END ASSOCIATE
    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_Domain_IsOutputDue

  !====================================================================
  ! MD_Output_Domain_GetRequestByName
  ! Get request index by name (linear search)
  !====================================================================
  SUBROUTINE MD_Output_Domain_GetRequestByName(this, name, req_idx, found, status)
    CLASS(MD_Output_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=*),        INTENT(IN)  :: name
    INTEGER(i4),             INTENT(OUT) :: req_idx
    LOGICAL,                 INTENT(OUT) :: found
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    req_idx = 0_i4
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    DO i = 1, this%n_requests
      IF (TRIM(this%requests(i)%name) == TRIM(name)) THEN
        found = .TRUE.
        req_idx = i
        EXIT
      END IF
    END DO

    IF (found) THEN
      status%status_code = IF_STATUS_OK
    ELSE
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,A,A)') "Output request '", TRIM(name), "' not found"
    END IF

  END SUBROUTINE MD_Output_Domain_GetRequestByName

  !====================================================================
  ! MD_Output_GetRequestByName_Idx - Index-style API (domain passed in to avoid UFC_GlobalContainer dep)
  !====================================================================
  SUBROUTINE MD_Output_GetRequestByName_Idx(dom, name, arg, status)
    TYPE(MD_Output_Domain),          INTENT(IN)    :: dom
    CHARACTER(LEN=*),                INTENT(IN)    :: name
    TYPE(MD_Output_GetRequestByName_Arg), INTENT(INOUT) :: arg
    TYPE(ErrorStatusType),           INTENT(OUT)   :: status

    INTEGER(i4) :: i

    CALL init_error_status(status)
    arg%req_idx = 0_i4
    arg%found = .FALSE.
    IF (.NOT. dom%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF
    DO i = 1, dom%n_requests
      IF (TRIM(dom%requests(i)%name) == TRIM(name)) THEN
        arg%found = .TRUE.
        arg%req_idx = i
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO
    status%status_code = IF_STATUS_INVALID
    WRITE(status%message, '(A,A,A)') "Output request '", TRIM(name), "' not found"
  END SUBROUTINE MD_Output_GetRequestByName_Idx

  !====================================================================
  ! MD_Output_Domain_GetSummary  [Arg wrapper]
  !====================================================================
  SUBROUTINE MD_Output_Domain_GetSummary(this, arg)
    CLASS(MD_Output_Domain),       INTENT(IN)    :: this
    TYPE(MD_Output_GetSummary_Arg),INTENT(INOUT) :: arg
    CALL MD_Output_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE MD_Output_Domain_GetSummary

  SUBROUTINE MD_Output_GetSummary_Impl(this, summary, status)
    CLASS(MD_Output_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),      INTENT(OUT) :: summary
    TYPE(ErrorStatusType),   INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Output domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,I0,A,I0,A,I0,A,I0)') &
      "Output Summary: Requests=", this%n_requests, &
      ", LastInc=", this%output_state%lastWrittenInc, &
      ", Frames=", this%output_state%totalFrames, &
      ", Format=", this%algo%default_format

    status%status_code = IF_STATUS_OK

  END SUBROUTINE MD_Output_GetSummary_Impl

END MODULE MD_Out_API