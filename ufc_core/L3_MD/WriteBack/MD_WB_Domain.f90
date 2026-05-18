!===============================================================================
! MODULE: MD_WB_Domain
! LAYER:  L3_MD
! DOMAIN: WriteBack
! ROLE:   Domain — Flat whitelist storage container
! BRIEF:  AddEntry/IsAllowed/GetSummary for WriteBack whitelist domain.
!===============================================================================
!
! Types:
!   MD_WriteBack_AddEntry_Arg    — Arg bundle for AddEntry
!   MD_WriteBack_GetSummary_Arg  — Arg bundle for GetSummary
!   MD_WriteBack_WhiteListDomain — Flat whitelist storage container
!
! Procedures (TBP on MD_WriteBack_WhiteListDomain):
!   [P0] Init / Finalize / AddEntry / IsAllowed / GetSummary
!
! Status: SIO-REFACTORED | ACTIVE | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:WB | Role:Domain_Core | FuncSet:Init,Query,Valid | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | WriteBack/CONTRACT.md

MODULE MD_WB_Domain
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_WB_Def, ONLY: MD_WriteBack_Entry
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_WriteBack_WhiteListDomain
  PUBLIC :: MD_WriteBack_Entry

  INTEGER(i4), PARAMETER :: MAX_WRITEBACK_ENTRIES = 200_i4

  !--------------------------------------------------------------------
  ! Arg types for Arg-wrapped interfaces (Phase B)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_AddEntry_Arg
    CHARACTER(LEN=64) :: domain_name  = ""      ! (IN)
    CHARACTER(LEN=64) :: field_name   = ""      ! (IN)
    INTEGER(i4)       :: domain_id    = 0_i4    ! (IN)
    LOGICAL           :: is_active    = .TRUE.  ! (IN)
    LOGICAL           :: requires_lock = .FALSE. ! (IN)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_WriteBack_AddEntry_Arg

  TYPE, PUBLIC :: MD_WriteBack_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! (OUT)
    TYPE(ErrorStatusType) :: status
  END TYPE MD_WriteBack_GetSummary_Arg

  !--------------------------------------------------------------------
  ! MD_WriteBack_WhiteListDomain - flat whitelist storage
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_WriteBack_WhiteListDomain
    TYPE(MD_WriteBack_Entry), ALLOCATABLE :: entries(:)
    INTEGER(i4) :: n_entries = 0_i4
    INTEGER(i4) :: capacity  = 0_i4
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => MD_WriteBack_Domain_Init
    PROCEDURE :: Finalize => MD_WriteBack_Domain_Finalize
    PROCEDURE :: AddEntry => MD_WriteBack_Domain_AddEntry
    PROCEDURE :: IsAllowed => MD_WriteBack_Domain_IsAllowed
    PROCEDURE :: GetSummary => MD_WriteBack_Domain_GetSummary
  END TYPE MD_WriteBack_WhiteListDomain

CONTAINS

  SUBROUTINE MD_WriteBack_Domain_Init(this, initial_capacity, status)
    CLASS(MD_WriteBack_WhiteListDomain), INTENT(INOUT) :: this
    INTEGER(i4),                         INTENT(IN)    :: initial_capacity
    TYPE(ErrorStatusType),               INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%capacity = MAX(MAX_WRITEBACK_ENTRIES, initial_capacity)
    ALLOCATE(this%entries(this%capacity))
    this%n_entries = 0_i4
    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Domain_Init

  SUBROUTINE MD_WriteBack_Domain_Finalize(this)
    CLASS(MD_WriteBack_WhiteListDomain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    IF (ALLOCATED(this%entries)) DEALLOCATE(this%entries)
    this%n_entries = 0_i4
    this%capacity  = 0_i4
    this%initialized = .FALSE.
  END SUBROUTINE MD_WriteBack_Domain_Finalize

  SUBROUTINE MD_WriteBack_Domain_AddEntry(this, domain_name, field_name, &
                                          domain_id, is_active, requires_lock, status)
    CLASS(MD_WriteBack_WhiteListDomain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),                    INTENT(IN)    :: domain_name, field_name
    INTEGER(i4),                        INTENT(IN)    :: domain_id
    LOGICAL,                            INTENT(IN)    :: is_active, requires_lock
    TYPE(ErrorStatusType),               INTENT(OUT)   :: status

    TYPE(MD_WriteBack_Entry), ALLOCATABLE :: tmp(:)
    INTEGER(i4) :: i, new_cap

    CALL init_error_status(status)
    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "WriteBack domain not initialized"
      RETURN
    END IF

    ! Check duplicate
    DO i = 1, this%n_entries
      IF (TRIM(this%entries(i)%field_path) == TRIM(domain_name) // "." // TRIM(field_name)) THEN
        status%status_code = IF_STATUS_OK
        RETURN
      END IF
    END DO

    IF (this%n_entries >= this%capacity) THEN
      new_cap = this%capacity * 2_i4
      ALLOCATE(tmp(new_cap))
      tmp(1:this%n_entries) = this%entries
      CALL MOVE_ALLOC(tmp, this%entries)
      this%capacity = new_cap
    END IF

    this%n_entries = this%n_entries + 1_i4
    this%entries(this%n_entries)%field_path    = TRIM(domain_name) // "." // TRIM(field_name)
    this%entries(this%n_entries)%domain_name  = domain_name
    this%entries(this%n_entries)%field_name   = field_name
    this%entries(this%n_entries)%domain_id    = domain_id
    this%entries(this%n_entries)%is_active    = is_active
    this%entries(this%n_entries)%requires_lock = requires_lock
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Domain_AddEntry

  FUNCTION MD_WriteBack_Domain_IsAllowed(this, domain_name, field_name) RESULT(is_allowed)
    CLASS(MD_WriteBack_WhiteListDomain), INTENT(IN) :: this
    CHARACTER(LEN=*),                    INTENT(IN) :: domain_name, field_name
    LOGICAL :: is_allowed

    CHARACTER(LEN=128) :: field_path
    INTEGER(i4) :: i

    is_allowed = .FALSE.
    IF (.NOT. this%initialized) RETURN
    field_path = TRIM(domain_name) // "." // TRIM(field_name)

    DO i = 1, this%n_entries
      IF (.NOT. this%entries(i)%is_active) CYCLE
      IF (TRIM(this%entries(i)%field_path) == TRIM(field_path)) THEN
        is_allowed = .TRUE.
        RETURN
      END IF
    END DO
  END FUNCTION MD_WriteBack_Domain_IsAllowed

  !====================================================================
  ! MD_WriteBack_Domain_GetSummary  [Phase B Arg wrapper]
  !====================================================================
  SUBROUTINE MD_WriteBack_Domain_GetSummary(this, arg)
    CLASS(MD_WriteBack_WhiteListDomain), INTENT(IN)    :: this
    TYPE(MD_WriteBack_GetSummary_Arg),   INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    IF (.NOT. this%initialized) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "WriteBack domain not initialized"
      RETURN
    END IF
    WRITE(arg%summary, '(A,I0,A,I0,A)') &
      "WriteBack Summary: n_entries=", this%n_entries, &
      ", capacity=", this%capacity, " (whitelist slots)"
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_WriteBack_Domain_GetSummary

END MODULE MD_WB_Domain