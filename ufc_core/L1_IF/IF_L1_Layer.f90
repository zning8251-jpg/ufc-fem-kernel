!===============================================================================
! MODULE: IF_L1_Layer
! LAYER:  L1_IF
! DOMAIN: Layer (Layer-level aggregation - 7 service domains)
! ROLE:   _Domain
! BRIEF:  L1 layer container - aggregates all 7 infrastructure domains.
!===============================================================================
!
! Theory chain:
!   L1_IF is the base layer with zero UFC layer dependencies.
!   Provides: precision, error handling, logging, IO, memory, persistence, base.
!   All upper layers (L2~L6) USE L1_IF services.
!
! Logic chain:
!   UFC_GlobalContainer -> holds this as if_layer field
!   All layers          -> USE IF_Prec / IF_Err_Brg directly (PARAMETER access)
!   L6_AP               -> configures this container at Job startup
!
! Data chain:
!   Container path: g_ufc_global%if_layer
!   Contains 7 domain fields (error, log, monitor, io, memory, persist, base)
!   Init order:     1-error 2-log 2a-monitor 3-memory 4-io 5-persist 6-base
!   Finalize order: 6-base 5-persist 4-io 3-memory 2a-monitor 2-log 1-error
!
! Contents:
!   Types:
!     IF_L1_LayerContainer  [Ctx] Aggregation of all 7 domain containers
!   Subroutines (A-Z):
!     IF_L1_Finalize        [P0] Finalize all domains in reverse order
!     IF_L1_Init            [P0] Initialize all domains in dependency order
!
! Status: Phase A
! Last verified: 2026-04-28
!===============================================================================
MODULE IF_L1_Layer
  USE IF_Prec_Core,                    ONLY: wp, i4
  USE IF_Err_Brg,                 ONLY: ErrorStatusType, init_error_status, &
                                         IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Err_Mgr,       ONLY: IF_Error_Domain
  USE IF_Log_Core,         ONLY: IF_Log_Domain
  USE IF_IO_Mgr,          ONLY: IF_IO_Domain
  USE IF_Mem_Core,      ONLY: IF_Memory_Domain
  USE IF_IO_Persist,     ONLY: IF_Persist_Domain
  USE IF_Base_Mgr,        ONLY: IF_Base_Domain
  USE IF_Mon_Core,                ONLY: IF_Monitor_Domain, IF_Monitor_GetDomain
  USE IF_Reg_Core,    ONLY: Governance_Init, Governance_Finalize
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! TYPE: IF_L1_LayerContainer  [Ctx]
  ! Aggregation of all 7 infrastructure domain containers.
  ! Note: Precision domain is PARAMETER constants (USE IF_Prec),
  !       not a domain container instance.
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: IF_L1_LayerContainer
    TYPE(IF_Error_Domain)       :: error       ! Error handling service
    TYPE(IF_Log_Domain)         :: log         ! Logging service
    TYPE(IF_Monitor_Domain), POINTER :: monitor => NULL()  ! Observability (? g_if_monitor_domain)
    TYPE(IF_IO_Domain)          :: io          ! File IO service
    TYPE(IF_Memory_Domain)    :: memory      ! Memory pool service
    TYPE(IF_Persist_Domain)   :: persist     ! Persistence/backup service
    TYPE(IF_Base_Domain)     :: base        ! Device/math/metadata service
    LOGICAL                   :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE IF_L1_LayerContainer

CONTAINS

  !====================================================================
  ! [P0] IF_L1_Finalize - Finalize all domains in REVERSE init order
  !   Order: 6-base 5-persist 4-io 3-memory 2a-monitor 2-log 1-error
  !====================================================================
  SUBROUTINE Finalize(this)
    CLASS(IF_L1_LayerContainer), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN

    ! 7?1: strict reverse order
    CALL Governance_Finalize()
    CALL this%base%Finalize()
    CALL this%persist%Finalize()
    CALL this%io%Finalize()
    CALL this%memory%Finalize()
    IF (ASSOCIATED(this%monitor)) CALL this%monitor%Finalize()
    CALL this%log%Finalize()
    CALL this%error%Finalize()

    this%initialized = .FALSE.

  END SUBROUTINE Finalize

  !====================================================================
  ! [P0] IF_L1_Init - Initialize all domains in dependency order
  !   Order: 1-error 2-log 2a-monitor 3-memory 4-io 5-persist 6-base
  !====================================================================
  SUBROUTINE Init(this, nThreads, workDir, status)
    CLASS(IF_L1_LayerContainer), INTENT(INOUT) :: this
    INTEGER(i4),                  INTENT(IN)    :: nThreads
    CHARACTER(LEN=*),             INTENT(IN)    :: workDir
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%initialized) CALL this%Finalize()

    ! 1. Error (must be first ??all others depend on error reporting)
    CALL this%error%Init(1024_i4, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 2. Log (depends on error)
    CALL this%log%Init(2_i4, .TRUE., status)  ! INFO level, console on
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 2a. Monitor (observability; points to global g_if_monitor_domain)
    this%monitor => IF_Monitor_GetDomain()
    CALL this%monitor%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN
    this%monitor%state%trace%maxSpans = 1024_i4

    ! 3. Memory (depends on error, log)
    CALL this%memory%Init(16_i4, .TRUE., status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 4. IO (depends on error, log, memory)
    CALL this%io%Init(status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 5. Persist (depends on IO)
    CALL this%persist%Init(workDir, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 6. Base (depends on error, memory)
    CALL this%base%Init(nThreads, 1024_i4, status)
    IF (status%status_code /= IF_STATUS_OK) RETURN

    ! 7. Registry (model governance; flat API)
    CALL Governance_Init()

    this%initialized = .TRUE.

  END SUBROUTINE Init

END MODULE IF_L1_Layer