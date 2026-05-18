!===============================================================================
! Template: PH_XXX_Field.f90                                    [Template v1.1]
! Layer:  L4_PH - Physics Layer
! Domain: Field / [Family] (e.g., USDFLD / SDVINI / SIGINI / UFIELD)
! Changelog:
!   note (2026-05)  Refresh IF_Err_Brg structured-status comment baseline.
!   v1.1 (2026-03)  Single PH_XXX_Field_Args (replaces _In/_Out); _Impl(args).
!
! HOW TO USE:
!   1. Copy to L4_PH/Field/[Family]/
!   2. Rename: PH_Field_[Family]_[Type].f90
!              (e.g., PH_Field_USDFLD_Damage.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]  (e.g., USDFLD_Dmg)
!   4. Replace XXX     -> [Type abbrev]    (e.g., Dmg)
!   5. Wire up USE statements to the matching MD_Field_XXX module
!   6. Implement PH_XXX_Field_Impl — field variable computation physics
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Field_Apply  (L5_RT Proc)
!             → PH_XXX_Field_API    (THIS FILE — thin wrapper)
!             → PH_XXX_Field_Impl   (THIS FILE — hot path physics)
!
! ABAQUS subroutine coverage:
!   USDFLD   : User solution-dependent field variables (Standard)
!              Returns: FIELD(NFIELD) — updated field variable values
!   VUSDFLD  : Vectorised USDFLD (Explicit); nblock-based
!   SDVINI   : User initial solution-dependent variable values
!   SIGINI   : User initial stress field
!   UFIELD   : User pre-defined field variable distribution
!
! Principle #14 SIO compliance:
!   PH_XXX_Field_API  : 6-parameter form (desc, ctx, state, md_algo, ph_algo, rt_ctx)
!   PH_XXX_Field_Impl : adds _In/_Out types as 5th/6th args (L4 hot-path)
!   pnewdt is returned as bare REAL(wp) INOUT (ABI exception, like UMAT).
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  PH_XXX_Field_API: 7 params (6 + pnewdt bare scalar, exception)
!   SIO-02 ✓  PH_XXX_Field_Impl: last param is PH_XXX_Field_Args (INOUT)
!   SIO-03 ✓  PH_XXX_Field_Args carries structured ErrorStatusType status ([OUT]);
!             check %status_code == IF_STATUS_OK
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  _In TYPE has no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  _In TYPE has no ALLOCATABLE members
!===============================================================================
MODULE PH_XXX_Field
  USE IF_Prec_Core,        ONLY: wp, i4
  USE IF_Err_Brg,     ONLY: ErrorStatusType, init_error_status, &
                            IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Field descriptor
  USE MD_Field_XXX_XXX, ONLY: MD_XXX_Field_Desc
  USE MD_Field_Types,   ONLY: MD_Field_Base_Desc, &
                              MD_Field_Base_State, &
                              MD_Field_Base_Algo
  !-- [PH] Field base types
  USE PH_Field_Def,     ONLY: PH_Field_Ctx, &
                              PH_Field_State, &
                              PH_Field_Algo
  !-- [RT] Runtime context
  USE RT_Com_Types,     ONLY: RT_Com_Base_Ctx, &
                              RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_XXX_Field_State   ! PH-owned per-IP field state (for tests / RT)
  PUBLIC :: PH_XXX_Field_Args    ! Unified call-time IO bundle (Principle #14)
  PUBLIC :: PH_XXX_Field_API     ! UFC-native Field entry (thin wrapper -> _Impl)
  ! NOTE: PH_XXX_Field_Impl is PRIVATE — physics lives there; API is pure glue.

  !-----------------------------------------------------------------------------
  ! STATE type: PH-owned field variable state.
  !   EXTENDS PH_Field_Base_State which provides:
  !     field_val(:)  — updated FIELD array [nfield] (USDFLD output)
  !     statev(:)     — updated STATEV [nstatv] (optional USDFLD output)
  !     stress(6)     — retrieved stress tensor (from GETVRM)
  !     strain(6)     — retrieved strain tensor (from GETVRM)
  !     peeq          — equivalent plastic strain (from GETVRM)
  !     triax         — stress triaxiality (from GETVRM)
  !     converged     — convergence flag
!     status        — structured ErrorStatusType status
  !
  !   Add field-family-specific state fields below.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(PH_Field_Base_State) :: PH_XXX_Field_State
    !-- TODO: add field-family-specific state fields here
    !   e.g., for damage: REAL(wp) :: D = 0.0_wp (damage variable)
    !         for phase-field: REAL(wp) :: phi = 0.0_wp (phase order parameter)
    REAL(wp) :: field_aux1 = 0.0_wp   ! Auxiliary field state variable 1
    REAL(wp) :: field_aux2 = 0.0_wp   ! Auxiliary field state variable 2
  END TYPE PH_XXX_Field_State

  !-----------------------------------------------------------------------------
  ! PH_XXX_Field_Args — unified bundle (Principle #14, L4 adaptation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: PH_XXX_Field_Args
    !-- [IN]
    INTEGER(i4) :: ip_index     = 0_i4
    INTEGER(i4) :: layer        = 1_i4
    INTEGER(i4) :: kspt         = 1_i4
    LOGICAL     :: is_first_inc = .FALSE.
    LOGICAL     :: need_getvrm  = .FALSE.
    !-- TODO: field-type [IN] fields
    !-- [OUT]
    TYPE(ErrorStatusType) :: status
    LOGICAL               :: success       = .FALSE.
    REAL(wp)              :: pnewdt        = 1.0_wp
    !-- TODO: field-type [OUT] diagnostics
  END TYPE PH_XXX_Field_Args

CONTAINS

  !============================================================================
  ! PUBLIC API — thin wrapper (Principle #14 / SIO adaptation for L4_PH)
  !============================================================================
  !> PH_XXX_Field_API
  !>
  !> ROLE: THIN WRAPPER ONLY — fills PH_XXX_Field_Args, delegates to PH_XXX_Field_Impl.
  !>   DO NOT add field physics here; implement in PH_XXX_Field_Impl.
  !>
  !> Parameters (7-parameter form, pnewdt ABI exception):
  !>   MD_Field_Desc  [MD] field parameters (read-only)
  !>   PH_Field_Ctx   [PH] per-increment driving inputs (elem, IP, field_prev, etc.)
  !>   PH_Field_State [PH] field state (field_val, statev) — INOUT
  !>   MD_Field_Algo  [MD] update scheme config
  !>   PH_Field_Algo  [PH] GETVRM flags and iteration control
  !>   RT_Com_Ctx     [RT] runtime bookkeeping (kstep, kinc, time)
  !>   pnewdt         [RT] REAL(wp) INOUT: step-ratio feedback (USDFLD can cut)
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE PH_XXX_Field_API(MD_Field_Desc, PH_Field_Ctx, PH_Field_State, &
                               MD_Field_Algo, PH_Field_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_XXX_Field_Desc),  INTENT(IN)    :: MD_Field_Desc   ! [MD] parameters
    TYPE(PH_Field_Base_Ctx),  INTENT(IN)    :: PH_Field_Ctx    ! [PH] driving inputs
    TYPE(PH_XXX_Field_State), INTENT(INOUT) :: PH_Field_State  ! [PH] state (in/out)
    TYPE(MD_Field_Base_Algo), INTENT(IN)    :: MD_Field_Algo   ! [MD] update config
    TYPE(PH_Field_Base_Algo), INTENT(IN)    :: PH_Field_Algo   ! [PH] iteration ctrl
    TYPE(RT_Com_Base_Ctx),    INTENT(IN)    :: RT_Com_Ctx      ! [RT] runtime context
    REAL(wp),                 INTENT(INOUT) :: pnewdt          ! [RT] step-ratio feedback

    TYPE(PH_XXX_Field_Args) :: field_args

    field_args%ip_index      = PH_Field_Ctx%integ_pt_id
    field_args%layer         = PH_Field_Ctx%layer_id
    field_args%kspt          = PH_Field_Ctx%kspt
    field_args%is_first_inc  = (RT_Com_Ctx%kinc == 1_i4)
    field_args%need_getvrm   = PH_Field_Algo%get_stress .OR. &
                              PH_Field_Algo%get_strain .OR. &
                              PH_Field_Algo%get_peeq   .OR. &
                              PH_Field_Algo%get_triax
    !-- TODO: fill additional field_args [IN] fields

    field_args%success = .FALSE.

    CALL PH_XXX_Field_Impl(MD_Field_Desc, PH_Field_Ctx, PH_Field_State, &
                            MD_Field_Algo, PH_Field_Algo, field_args)

    pnewdt = field_args%pnewdt
  END SUBROUTINE PH_XXX_Field_API

  !============================================================================
  ! PRIVATE IMPLEMENTATION — all field physics here
  !============================================================================
  !> PH_XXX_Field_Impl
  !>
  !>  Six-parameter inner interface (Principle #14, L4 hot-path form).
  !>  Callers: PH_XXX_Field_API (production) and unit-test harness (direct).
  !>
  !>  Contract:
  !>    args%need_getvrm   .TRUE. → retrieve stress/strain/peeq/triax via GETVRM
  !>    args%is_first_inc  .TRUE. → apply initial field values from MD_Field_Desc
  !>    args%success       .TRUE. IFF field variables computed successfully
  !>    args%pnewdt        step-ratio feedback (<1 cut, >1 grow, =1 no change)
  !>    PH_Field_State     field_val(:) and statev(:) updated in-place
  SUBROUTINE PH_XXX_Field_Impl(MD_Field_Desc, PH_Field_Ctx, PH_Field_State, &
                                MD_Field_Algo, PH_Field_Algo, args)
    TYPE(MD_XXX_Field_Desc),  INTENT(IN)    :: MD_Field_Desc
    TYPE(PH_Field_Base_Ctx),  INTENT(IN)    :: PH_Field_Ctx
    TYPE(PH_XXX_Field_State), INTENT(INOUT) :: PH_Field_State
    TYPE(MD_Field_Base_Algo), INTENT(IN)    :: MD_Field_Algo
    TYPE(PH_Field_Base_Algo), INTENT(IN)    :: PH_Field_Algo
    TYPE(PH_XXX_Field_Args),  INTENT(INOUT) :: args

    !-- Local variables (stack-allocated; no ALLOCATE in hot path — SIO-09)
    !$UFC HOT_PATH
    INTEGER(i4) :: i, nf
    REAL(wp)    :: field_new          ! Updated field variable value
    LOGICAL     :: update_ok          ! Field update convergence flag

    !-- Initialize output
    CALL init_error_status(args%status)
    args%success = .FALSE.
    args%pnewdt  = RT_PNEWDT_NO_CHANGE

    !=========================================================================
    ! Guard: validate nfield
    !=========================================================================
    nf = MD_Field_Desc%nfield
    IF (nf < 1) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[PH_XXX_Field_Impl]: nfield < 1')
      RETURN
    END IF

    !-- Ensure output arrays allocated
    IF (.NOT. ALLOCATED(PH_Field_State%field_val)) &
      ALLOCATE(PH_Field_State%field_val(nf))

    !=========================================================================
    ! Step 1: First increment — apply initial field values
    !=========================================================================
    IF (args%is_first_inc .AND. ALLOCATED(MD_Field_Desc%field_init)) THEN
      DO i = 1, MIN(nf, SIZE(MD_Field_Desc%field_init))
        PH_Field_State%field_val(i) = MD_Field_Desc%field_init(i)
      END DO
    END IF

    !=========================================================================
    ! Step 2: GETVRM calls — retrieve auxiliary result variables
    !   In production: call GETVRM('S', avar, jvar, answer, kflag, pnewdt)
    !   to populate PH_Field_State%stress, %strain, %peeq, %triax.
    !   TODO: implement GETVRM dispatch wrapper here.
    !=========================================================================
    IF (args%need_getvrm) THEN
      !-- STUB: GETVRM not yet wired
      !-- PRODUCTION: CALL UFC_GETVRM_Dispatch(PH_Field_Ctx, PH_Field_Algo,
      !                                         PH_Field_State, pnewdt)
    END IF

    !=========================================================================
    ! Step 3: Compute updated field variable values
    !   This is the core user physics: compute FIELD(NFIELD) based on
    !   current state variables, stress, strain, temperature, etc.
    !   Replace stub below with actual field variable update law.
    !
    !   Example for damage-based field variable:
    !     field_new = MIN(PH_Field_State%peeq / MD_Field_Desc%field_param1, 1.0_wp)
    !   Example for temperature-dependent field:
    !     field_new = MD_Field_Desc%field_param1 * PH_Field_Ctx%temp
    !=========================================================================
    update_ok = .TRUE.
    DO i = 1, nf
      !-- STUB: copy previous field (no-op update)
      IF (ASSOCIATED(PH_Field_Ctx%field_prev) .AND. &
          i <= SIZE(PH_Field_Ctx%field_prev)) THEN
        field_new = PH_Field_Ctx%field_prev(i)
      ELSE
        field_new = 0.0_wp
      END IF
      !-- TODO: replace stub with actual field variable physics
      PH_Field_State%field_val(i) = field_new
    END DO

    !=========================================================================
    ! Step 4: Update solution-dependent variables (STATEV) if applicable
    !   TODO: update PH_Field_State%statev(:) based on field evolution
    !=========================================================================

    !=========================================================================
    ! Step 5: Convergence check and pnewdt signal
    !   If field update drives a large change, signal step cutback.
    !=========================================================================
    PH_Field_State%converged = update_ok
    IF (.NOT. update_ok) THEN
      args%pnewdt = 0.5_wp    ! Suggest half-step cutback
    END IF

    args%success            = update_ok
    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_XXX_Field_Impl

END MODULE PH_XXX_Field