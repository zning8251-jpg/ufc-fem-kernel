!===============================================================================
! MODULE: IF_Err_Mgr
! LAYER:  L1_IF
! DOMAIN: Error
! ROLE:   _Mgr
! BRIEF:  Error domain container - aggregates error stack, stats, recovery.
!===============================================================================
!
! Theory chain:
!   Error propagation model: every subroutine returns ErrorStatusType
!   Severity levels: INFO(0)->WARNING(1)->ERROR(2)->CRITICAL(3)->FATAL(4)
!   Code bands: L1=1000-2999, L2=3000-3999, L3=4000-4999,
!               L4=5000-5999, L5=6000-6999, L6=7000-7999
!
! Data chain:
!   Container path: g_ufc_global%if_layer%error
!   Lifecycle: Process-level (Job-scoped, initialized once at startup)
!
! Contents:
!   Types:
!     IF_Err_Stats_State   [State] Error counting statistics
!     IF_Err_Domain_Ctx    [Ctx]   Domain container
!   Subroutines (A-Z):
!     IF_Err_Finalize      [P0]    Release error stack, reset stats
!     IF_Err_GetStats      [P3]    Read-only copy of error statistics
!     IF_Err_Init          [P0]    Initialize error domain
!
! Status: Phase A | Last verified: 2026-04-28
!===============================================================================
MODULE IF_Err_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4, i8
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Def, ONLY: IF_Err_Stack_State
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! TYPE: IF_Error_Stats  [State]  (canonical: IF_Err_Stats_State)
  ! Error counting statistics.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Error_Stats
    INTEGER(i8) :: total_errors   = 0_i8
    INTEGER(i8) :: total_warnings = 0_i8
    INTEGER(i8) :: total_fatals   = 0_i8
    INTEGER(i4) :: last_error_code = 0_i4
  END TYPE IF_Error_Stats

  !--------------------------------------------------------------------
  ! TYPE: IF_Error_Domain  [Ctx]  (canonical: IF_Err_Domain_Ctx)
  ! Error domain container aggregating stack + stats.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_Error_Domain
    TYPE(IF_Err_Stack_State) :: errStack
    TYPE(IF_Error_Stats)       :: stats
    INTEGER(i4) :: maxStackSize = 1024_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetStats
  END TYPE IF_Error_Domain

CONTAINS

  !====================================================================
  ! [P0] IF_Err_Finalize - Release error stack, reset stats
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_Error_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN

    IF (ALLOCATED(this%errStack%errors)) DEALLOCATE(this%errStack%errors)
    this%errStack%stack_size = 0_i4
    this%errStack%has_error  = .FALSE.
    this%errStack%init       = .FALSE.
    this%stats%total_errors   = 0_i8
    this%stats%total_warnings = 0_i8
    this%stats%total_fatals   = 0_i8
    this%stats%last_error_code = 0_i4
    this%initialized = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! [P3] IF_Err_GetStats - Read-only copy of error statistics
  !====================================================================
  SUBROUTINE GetStats(this, stats, status)
    CLASS(IF_Error_Domain), INTENT(IN)  :: this
    TYPE(IF_Error_Stats),   INTENT(OUT) :: stats
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "IF_Error_Domain not initialized"
      RETURN
    END IF

    stats = this%stats
    status%status_code = IF_STATUS_OK

  END SUBROUTINE GetStats

  !====================================================================
  ! [P0] IF_Err_Init - Initialize error domain
  !====================================================================
  SUBROUTINE Init(this, maxStackSize, status)
    CLASS(IF_Error_Domain), INTENT(INOUT) :: this
    INTEGER(i4),            INTENT(IN)    :: maxStackSize
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%initialized) CALL this%Finalize()

    this%maxStackSize = maxStackSize
    ALLOCATE(this%errStack%errors(maxStackSize))
    this%errStack%max_size   = maxStackSize
    this%errStack%stack_size = 0_i4
    this%errStack%has_error  = .FALSE.
    this%errStack%init       = .TRUE.
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK

  END SUBROUTINE Init

END MODULE IF_Err_Mgr