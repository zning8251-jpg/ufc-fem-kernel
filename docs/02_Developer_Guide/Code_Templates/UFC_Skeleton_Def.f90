!===============================================================================
! File: {Layer}_{Domain}/{Feature}/{Layer}_{Domain}_Def.f90
! Module: {Layer}_{Domain}_Def
! Layer:  {Layer} - {LayerFullName}
! Domain: {Domain} - {DomainDescription}
! Purpose: Type definitions for the {Domain}/{Feature} subdomain.
!          Contains the four-type paradigm TYPEs (Desc/State/Algo/Ctx),
!          domain-specific constants, and status codes.
!          Pure data definitions — NO procedures except type-bound
!          Init/Validate when needed.
!
! SIO Compliance (Principle #14):
!   *_Arg bundles are defined here only when >=2 fields co-evolve in a
!   single operation consumed by Harness/cross-layer callers.
!   Status-only wrappers are avoided (see AGENTS.md §5).
!
! Theory: {Brief theory reference, e.g. "Elastic constitutive tensor C_ijkl"}
!
! Status: Phase {A|B|C} | Last verified: {YYYY-MM-DD}
!===============================================================================
!
!>>> UFC_{Layer}_QUENCH | Domain:{Domain} | Role:Def | FuncSet:N/A | HotPath:No
!>>> UFC_{Layer}_CONTRACT | {Domain}/CONTRACT.md
!
MODULE {Layer}_{Domain}_Def
  !-----------------------------------------------------------------------------
  ! USE — precision first, then error, then same-layer Def modules (if needed)
  !-----------------------------------------------------------------------------
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID

  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! PUBLIC: types, constants, and (optional) Arg bundles
  !-----------------------------------------------------------------------------
  PUBLIC :: {Layer}_{Domain}_Desc
  PUBLIC :: {Layer}_{Domain}_State
  PUBLIC :: {Layer}_{Domain}_Algo
  PUBLIC :: {Layer}_{Domain}_Ctx
  ! PUBLIC :: {Layer}_{Domain}_{Verb}_Arg   ! uncomment when SIO Arg is needed

  !-----------------------------------------------------------------------------
  ! Domain status codes
  !   Convention: 0 = OK, negative = domain-specific errors
  !   Layer error code ranges (IF_Err_Reg):
  !     L1: 1000-1999, L2: 3000-3999, L3: 4000-4999,
  !     L4: 5000-5999, L5: 6000-6999, L6: 7000-7999
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: {DOMAIN}_STATUS_OK      = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: {DOMAIN}_STATUS_INVALID = -1_i4

  !-----------------------------------------------------------------------------
  ! Domain constants (UPPER_SNAKE_CASE)
  !-----------------------------------------------------------------------------
  ! INTEGER(i4), PARAMETER, PUBLIC :: {DOMAIN}_MAX_ITEMS = 1024_i4

  !=============================================================================
  ! TYPE 1 — Desc (Cold): read-only model configuration, set at parse time
  !   Memory: ALLOCATABLE, model-level lifetime
  !=============================================================================
  TYPE, PUBLIC :: {Layer}_{Domain}_Desc
    INTEGER(i4) :: id         = 0_i4
    INTEGER(i4) :: type_id    = 0_i4
    CHARACTER(LEN=64) :: name = ''
    LOGICAL     :: is_active  = .FALSE.
    ! ... domain-specific descriptors ...
  END TYPE {Layer}_{Domain}_Desc

  !=============================================================================
  ! TYPE 2 — State (Warm): evolving data, changes per step/increment
  !   Memory: ALLOCATABLE, step-level lifetime
  !=============================================================================
  TYPE, PUBLIC :: {Layer}_{Domain}_State
    LOGICAL :: is_initialized = .FALSE.
    ! ... domain-specific mutable state ...
  END TYPE {Layer}_{Domain}_State

  !=============================================================================
  ! TYPE 3 — Algo (Cold): algorithm control parameters, read-only in step
  !   Memory: ALLOCATABLE, model-level lifetime
  !   Omit this TYPE if no algorithm selection/control is needed.
  !=============================================================================
  TYPE, PUBLIC :: {Layer}_{Domain}_Algo
    INTEGER(i4) :: method = 1_i4
    ! ... algorithm parameters ...
  END TYPE {Layer}_{Domain}_Algo

  !=============================================================================
  ! TYPE 4 — Ctx (Hot): per-call scratch / aggregate, stack-allocated
  !   Memory: stack or short-lived, zero ALLOCATE on hot path
  !   Ctx aggregates POINTER references to Desc/State/Algo; does NOT own them.
  !=============================================================================
  TYPE, PUBLIC :: {Layer}_{Domain}_Ctx
    TYPE({Layer}_{Domain}_Desc),  POINTER :: desc  => NULL()
    TYPE({Layer}_{Domain}_State), POINTER :: state => NULL()
    TYPE({Layer}_{Domain}_Algo),  POINTER :: algo  => NULL()
    INTEGER(i4) :: bridge_state = 0_i4
  END TYPE {Layer}_{Domain}_Ctx

  !=============================================================================
  ! OPTIONAL — SIO Arg bundle (only when >=2 fields co-evolve)
  !   Follow Principle #14: unified *_Arg with [IN]/[OUT] comments.
  !   Do NOT create Arg bundles that wrap only a status field.
  !=============================================================================
  ! TYPE, PUBLIC :: {Layer}_{Domain}_{Verb}_Arg
  !   ! [IN]
  !   INTEGER(i4) :: input_id = 0_i4
  !   ! [OUT]
  !   INTEGER(i4) :: result_code = 0_i4
  !   REAL(wp)    :: result_value = 0.0_wp
  ! END TYPE {Layer}_{Domain}_{Verb}_Arg

  ! ---------------------------------------------------------------------------
  ! OPTIONAL — type-bound procedures (Init/Validate only in _Def)
  ! ---------------------------------------------------------------------------
  ! If the Desc TYPE needs Init/Validate, add CONTAINS in the TYPE definition:
  !   CONTAINS
  !     PROCEDURE :: Init     => {Domain}_Desc_Init
  !     PROCEDURE :: Validate => {Domain}_Desc_Validate

CONTAINS

  ! ===========================================================================
  ! Type-bound procedure implementations (keep minimal in _Def)
  ! ===========================================================================

  ! SUBROUTINE {Domain}_Desc_Init(self, name, status)
  !   CLASS({Layer}_{Domain}_Desc), INTENT(INOUT) :: self
  !   CHARACTER(LEN=*), INTENT(IN) :: name
  !   TYPE(ErrorStatusType), INTENT(OUT) :: status
  !
  !   CALL init_error_status(status)
  !   self%name = name
  !   self%is_active = .TRUE.
  !   status%status_code = IF_STATUS_OK
  ! END SUBROUTINE {Domain}_Desc_Init

  ! SUBROUTINE {Domain}_Desc_Validate(self, status)
  !   CLASS({Layer}_{Domain}_Desc), INTENT(INOUT) :: self
  !   TYPE(ErrorStatusType), INTENT(OUT) :: status
  !
  !   CALL init_error_status(status)
  !   IF (TRIM(self%name) == '') THEN
  !     status%status_code = IF_STATUS_INVALID
  !     status%message = "[{Domain}_Desc_Validate]: name is required"
  !     RETURN
  !   END IF
  !   status%status_code = IF_STATUS_OK
  ! END SUBROUTINE {Domain}_Desc_Validate

END MODULE {Layer}_{Domain}_Def
