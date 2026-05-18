!===============================================================================
! File: {Layer}_{Domain}/{Feature}/{Layer}_{Domain}_Core.f90
! Module: {Layer}_{Domain}_Core
! Note:  When domain has sub-features, use {Layer}_{Domain}_{Feature}_Core.f90
! Layer:  {Layer} - {LayerFullName}
! Domain: {Domain} - {DomainDescription}
! Purpose: Core implementation for the {Domain} domain.
!          Contains Init / Finalize / Query / Mutate / Compute / Valid procedures.
!          This is the primary "workhorse" module — all domain logic that does
!          NOT cross layer boundaries lives here.
!
! SIO Compliance (Principle #14):
!   Procedures at layer boundaries use *_Arg bundles.
!   Internal helpers use direct argument lists.
!
! Theory: {Brief theory chain reference}
!
! Logic chain:
!   {Upstream} -> {This module} -> {Downstream}
!
! Status: Phase {A|B|C} | Last verified: {YYYY-MM-DD}
!===============================================================================
!
!>>> UFC_{Layer}_QUENCH | Domain:{Domain} | Role:Core | FuncSet:Init,Query,Mutate,Compute | HotPath:{Yes|No}
!>>> UFC_{Layer}_CONTRACT | {Domain}/CONTRACT.md
!
MODULE {Layer}_{Domain}_Core
  !-----------------------------------------------------------------------------
  ! USE — precision + error first, then own _Def, then same-layer deps
  !   RULE: never USE modules from higher layers (DEP-001).
  !   Cross-layer data comes via Brg or Populate, not direct USE.
  !-----------------------------------------------------------------------------
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE {Layer}_{Domain}_Def, ONLY: &
      {Layer}_{Domain}_Desc, &
      {Layer}_{Domain}_State, &
      {Layer}_{Domain}_Algo, &
      {Layer}_{Domain}_Ctx, &
      {DOMAIN}_STATUS_OK, &
      {DOMAIN}_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! PUBLIC procedures
  !   Naming: {Layer}_{Domain}_{Verb}[{Object}]  (<=28 chars, 2-3 segments)
  !-----------------------------------------------------------------------------
  PUBLIC :: {Layer}_{Domain}_Init
  PUBLIC :: {Layer}_{Domain}_Finalize
  ! PUBLIC :: {Layer}_{Domain}_Query      ! read-only accessors
  ! PUBLIC :: {Layer}_{Domain}_Update     ! mutable setters
  ! PUBLIC :: {Layer}_{Domain}_Compute    ! hot-path numerics
  ! PUBLIC :: {Layer}_{Domain}_Validate   ! validation checks

  !-----------------------------------------------------------------------------
  ! PRIVATE helpers (short names, no layer prefix)
  !   Naming: domain_verb or verb_obj (<=24 chars)
  !   Exposed via INTERFACE if public name is needed (see naming rule).
  !-----------------------------------------------------------------------------
  ! PRIVATE :: domain_validate_input

CONTAINS

  !=============================================================================
  ! Init — allocate and initialize domain state
  ! Phase: Config | Verb: Init | COLD_PATH
  !=============================================================================
  SUBROUTINE {Layer}_{Domain}_Init(desc, state, algo, status)
    TYPE({Layer}_{Domain}_Desc),  INTENT(IN)    :: desc
    TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state
    TYPE({Layer}_{Domain}_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! --- guard: already initialized ---
    IF (state%is_initialized) THEN
      status%status_code = {DOMAIN}_STATUS_INVALID
      status%message = "[{Layer}_{Domain}_Init]: already initialized"
      RETURN
    END IF

    ! --- initialization logic ---
    ! (allocate arrays, set defaults from desc/algo)

    state%is_initialized = .TRUE.
    status%status_code = {DOMAIN}_STATUS_OK
  END SUBROUTINE {Layer}_{Domain}_Init

  !=============================================================================
  ! Finalize — deallocate and clean up domain state
  ! Phase: Teardown | Verb: Finalize | COLD_PATH
  !=============================================================================
  SUBROUTINE {Layer}_{Domain}_Finalize(state, status)
    TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),        INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. state%is_initialized) THEN
      status%status_code = {DOMAIN}_STATUS_OK
      RETURN
    END IF

    ! --- deallocation logic ---
    ! (DEALLOCATE arrays in State)

    state%is_initialized = .FALSE.
    status%status_code = {DOMAIN}_STATUS_OK
  END SUBROUTINE {Layer}_{Domain}_Finalize

  !=============================================================================
  ! TEMPLATE: Query — read-only accessor
  ! Phase: Query | Verb: Query | COLD_PATH
  !   Uncomment and adapt as needed.
  !=============================================================================
  ! SUBROUTINE {Layer}_{Domain}_Query(desc, state, result_value, status)
  !   TYPE({Layer}_{Domain}_Desc),  INTENT(IN)  :: desc
  !   TYPE({Layer}_{Domain}_State), INTENT(IN)  :: state
  !   REAL(wp),                     INTENT(OUT) :: result_value
  !   TYPE(ErrorStatusType),        INTENT(OUT) :: status
  !
  !   CALL init_error_status(status)
  !   IF (.NOT. state%is_initialized) THEN
  !     status%status_code = {DOMAIN}_STATUS_INVALID
  !     status%message = "[{Layer}_{Domain}_Query]: not initialized"
  !     RETURN
  !   END IF
  !   result_value = 0.0_wp  ! replace with actual query
  !   status%status_code = {DOMAIN}_STATUS_OK
  ! END SUBROUTINE {Layer}_{Domain}_Query

  !=============================================================================
  ! TEMPLATE: Compute — hot-path numerical kernel
  ! Phase: Compute | Verb: Compute | HOT_PATH
  !   Memory: zero ALLOCATE; work arrays passed via Ctx or stack.
  !   Uncomment and adapt as needed.
  !=============================================================================
  ! SUBROUTINE {Layer}_{Domain}_Compute(desc, state, algo, ctx, status)
  !   TYPE({Layer}_{Domain}_Desc),  INTENT(IN)    :: desc
  !   TYPE({Layer}_{Domain}_State), INTENT(INOUT) :: state
  !   TYPE({Layer}_{Domain}_Algo),  INTENT(IN)    :: algo
  !   TYPE({Layer}_{Domain}_Ctx),   INTENT(INOUT) :: ctx
  !   TYPE(ErrorStatusType),        INTENT(OUT)   :: status
  !
  !   CALL init_error_status(status)
  !   ! --- hot-path computation ---
  !   ! No ALLOCATE/DEALLOCATE here; use Ctx scratch arrays.
  !   status%status_code = {DOMAIN}_STATUS_OK
  ! END SUBROUTINE {Layer}_{Domain}_Compute

  !=============================================================================
  ! TEMPLATE: Validate — consistency checks
  ! Phase: Config | Verb: Validate | COLD_PATH
  !   Uncomment and adapt as needed.
  !=============================================================================
  ! SUBROUTINE {Layer}_{Domain}_Validate(desc, algo, status)
  !   TYPE({Layer}_{Domain}_Desc), INTENT(IN)  :: desc
  !   TYPE({Layer}_{Domain}_Algo), INTENT(IN)  :: algo
  !   TYPE(ErrorStatusType),       INTENT(OUT) :: status
  !
  !   CALL init_error_status(status)
  !   ! --- validation logic ---
  !   status%status_code = {DOMAIN}_STATUS_OK
  ! END SUBROUTINE {Layer}_{Domain}_Validate

  ! ===========================================================================
  ! Private helpers
  ! ===========================================================================

  ! SUBROUTINE domain_validate_input(value, valid, msg)
  !   REAL(wp), INTENT(IN) :: value
  !   LOGICAL, INTENT(OUT) :: valid
  !   CHARACTER(LEN=*), INTENT(OUT) :: msg
  !   valid = (value > 0.0_wp)
  !   IF (.NOT. valid) msg = "value must be positive"
  ! END SUBROUTINE domain_validate_input

END MODULE {Layer}_{Domain}_Core
