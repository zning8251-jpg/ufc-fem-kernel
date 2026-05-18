!===============================================================================
! File: {Layer}_{Domain}/Bridge/{Layer}_{Domain}_Brg.f90
! Module: {Layer}_{Domain}_Brg
! Layer:  {Layer} - {LayerFullName}
! Domain: {Domain} - {DomainDescription}
! Purpose: Bridge / API facade for the {Domain} domain.
!
!   Three roles:
!     1. RE-EXPORT: public types from _Def and _Core for upstream consumers
!     2. DELEGATE:  thin wrappers that call _Core procedures
!     3. CROSS-LAYER: Populate / WriteBack / Bridge routines that touch
!        adjacent layers (the ONLY module allowed to USE other-layer modules)
!
!   DEP-001 exemption: *_Brg.f90 and Bridge/ paths are exempt from the
!   dependency-inversion rule and MAY USE modules from adjacent layers.
!
! SIO Compliance (Principle #14):
!   Cross-layer procedures use *_Arg bundles.
!   Re-export-only facades have no procedures.
!
! Theory: N/A (routing/facade, no domain theory)
!
! Status: Phase {A|B|C} | Last verified: {YYYY-MM-DD}
!===============================================================================
!
!>>> UFC_{Layer}_QUENCH | Domain:{Domain} | Role:Brg | FuncSet:Brg,Query | HotPath:{Yes|No}
!>>> UFC_{Layer}_CONTRACT | {Domain}/CONTRACT.md
!
MODULE {Layer}_{Domain}_Brg
  !-----------------------------------------------------------------------------
  ! USE — precision + error + own domain modules
  !-----------------------------------------------------------------------------
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID

  !-- Own domain definitions (for re-export)
  USE {Layer}_{Domain}_Def, ONLY: &
      {Layer}_{Domain}_Desc,  &
      {Layer}_{Domain}_State, &
      {Layer}_{Domain}_Algo,  &
      {Layer}_{Domain}_Ctx,   &
      {DOMAIN}_STATUS_OK,     &
      {DOMAIN}_STATUS_INVALID

  !-- Own domain core (for delegation)
  USE {Layer}_{Domain}_Core, ONLY: &
      {Layer}_{Domain}_Init,     &
      {Layer}_{Domain}_Finalize

  !-- Adjacent-layer modules (cross-layer bridge — DEP-001 exempt)
  ! USE {OtherLayer}_{Domain}_Def, ONLY: {OtherLayer}_{Domain}_Desc
  ! USE {OtherLayer}_{Domain}_Core, ONLY: {OtherLayer}_{Domain}_SomeProc

  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! RE-EXPORT: Domain types (so consumers USE only _Brg, not _Def + _Core)
  !=============================================================================
  PUBLIC :: {Layer}_{Domain}_Desc
  PUBLIC :: {Layer}_{Domain}_State
  PUBLIC :: {Layer}_{Domain}_Algo
  PUBLIC :: {Layer}_{Domain}_Ctx
  PUBLIC :: {DOMAIN}_STATUS_OK
  PUBLIC :: {DOMAIN}_STATUS_INVALID

  !=============================================================================
  ! RE-EXPORT: Core procedures (delegate)
  !=============================================================================
  PUBLIC :: {Layer}_{Domain}_Init
  PUBLIC :: {Layer}_{Domain}_Finalize

  !=============================================================================
  ! BRIDGE procedures (cross-layer)
  !=============================================================================
  ! PUBLIC :: {Layer}_{Domain}_Populate      ! L3 -> L4 data push
  ! PUBLIC :: {Layer}_{Domain}_WriteBack     ! L5 -> L3 result write-back

  !=============================================================================
  ! Arg bundles for cross-layer operations (SIO Principle #14)
  !=============================================================================
  ! PUBLIC :: {Layer}_{Domain}_Populate_Arg

  ! TYPE, PUBLIC :: {Layer}_{Domain}_Populate_Arg
  !   ! [IN]
  !   INTEGER(i4) :: source_id  = 0_i4
  !   ! [OUT]
  !   INTEGER(i4) :: target_id  = 0_i4
  !   INTEGER(i4) :: pop_count  = 0_i4
  ! END TYPE {Layer}_{Domain}_Populate_Arg

CONTAINS

  !=============================================================================
  ! Populate — push data from source layer to target layer
  ! Phase: Populate | Verb: Populate | COLD_PATH
  !   Cross-layer: {SourceLayer} -> {TargetLayer}
  !   Error chain: source errors are wrapped with bridge context and propagated.
  !=============================================================================
  ! SUBROUTINE {Layer}_{Domain}_Populate(source_desc, target_ctx, arg, status)
  !   TYPE({SourceLayer}_{Domain}_Desc), INTENT(IN)    :: source_desc
  !   TYPE({TargetLayer}_{Domain}_Ctx),  INTENT(INOUT) :: target_ctx
  !   TYPE({Layer}_{Domain}_Populate_Arg), INTENT(INOUT) :: arg
  !   TYPE(ErrorStatusType),             INTENT(OUT)   :: status
  !
  !   TYPE(ErrorStatusType) :: local_status
  !
  !   CALL init_error_status(status)
  !
  !   ! --- map source data to target context ---
  !   ! target_ctx%desc => source_desc  ! non-owning pointer
  !
  !   ! --- propagate sub-step errors ---
  !   ! IF (local_status%status_code /= IF_STATUS_OK) THEN
  !   !   status = local_status
  !   !   status%source = "{Layer}_{Domain}_Populate"
  !   !   RETURN
  !   ! END IF
  !
  !   arg%pop_count = arg%pop_count + 1
  !   status%status_code = IF_STATUS_OK
  ! END SUBROUTINE {Layer}_{Domain}_Populate

  !=============================================================================
  ! WriteBack — write results back from runtime to model layer
  ! Phase: WriteBack | Verb: WriteBack | COLD_PATH
  !   Cross-layer: L5_RT -> L3_MD (typical direction)
  !   Guard: only whitelisted fields may be written back.
  !=============================================================================
  ! SUBROUTINE {Layer}_{Domain}_WriteBack(rt_state, md_state, status)
  !   TYPE(RT_{Domain}_State), INTENT(IN)    :: rt_state
  !   TYPE(MD_{Domain}_State), INTENT(INOUT) :: md_state
  !   TYPE(ErrorStatusType),   INTENT(OUT)   :: status
  !
  !   CALL init_error_status(status)
  !   ! --- writeback logic (field whitelist check) ---
  !   status%status_code = IF_STATUS_OK
  ! END SUBROUTINE {Layer}_{Domain}_WriteBack

END MODULE {Layer}_{Domain}_Brg
