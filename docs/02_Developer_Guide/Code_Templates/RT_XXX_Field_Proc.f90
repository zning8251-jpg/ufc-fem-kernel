!===============================================================================
! Template: RT_XXX_Field_Proc.f90                               [Template v1.0]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Field / [Family] (e.g., USDFLD / SDVINI / SIGINI / UFIELD)
!
! HOW TO USE:
!   1. Copy to L5_RT/Field/[Family]/
!   2. Rename: RT_Field_[Family]_[Type]_Proc.f90
!              (e.g., RT_Field_USDFLD_Damage_Proc.f90)
!   3. Replace XXX_XXX -> [Family]_[Type]  (e.g., USDFLD_Dmg)
!   4. Replace XXX     -> [Type abbrev]    (e.g., Dmg)
!   5. Wire up USE statements to the matching MD_Field_XXX, PH_XXX_Field modules
!   6. Implement RT_XXX_Field_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Field_Apply   (THIS FILE)
!             → PH_XXX_Field_API     (L4_PH: field physics, PH_XXX_Field_Args inside)
!             → PH_XXX_Field_Impl    (L4_PH: hot path, Principle #14 SIO)
!
! Principle #14 SIO compliance:
!   RT_XXX_Field_Apply uses the six-parameter form:
!     (Field_Ctx, Field_State, Field_Algo, Field_Bridge, RT_Com_Ctx, args)
!   pnewdt is passed as a bare REAL(wp) INOUT per PH_XXX_Field_API ABI exception.
!   (USDFLD CAN return pnewdt to suggest step cutback.)
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified RT_XXX_Field_Args bundle
!   SIO-02 ✓  _Proc uses RT_XXX_Field_Args with [IN]/[OUT] comments
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields have no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  [IN] fields have no ALLOCATABLE members
!===============================================================================
MODULE RT_XXX_Field_Proc
  USE IF_Prec_Core,       ONLY: wp, i4
  USE IF_Err_Brg,    ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Field descriptor & base types
  USE MD_Field_XXX_XXX, ONLY: MD_XXX_Field_Desc, &
                              MD_XXX_Field_InitFromProps
  USE MD_Field_Types,   ONLY: MD_Field_Base_Desc, &
                              MD_Field_Base_State, &
                              MD_Field_Base_Algo
  !-- [PH] Field physics entry point
  USE PH_Field_XXX_XXX, ONLY: PH_XXX_Field_State, &
                              PH_XXX_Field_API
  USE PH_Field_Def,     ONLY: PH_Field_Ctx, &
                              PH_Field_Algo
  !-- [RT] Runtime types
  USE RT_Com_Types,    ONLY: RT_Com_Base_Ctx, &
                             RT_PNEWDT_NO_CHANGE
  USE RT_Bridge_Types, ONLY: RT_Field_Bridge_Ctx
  USE RT_Domain_Types, ONLY: RT_Field_Domain_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Field_Args   ! Unified IO bundle ([IN]/[OUT] in comments)
  PUBLIC :: RT_XXX_Field_Apply  ! Main entry: per-IP field update → PH_XXX_Field_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant unified bundle
  !
  !   [IN]  Call-time routing scalars (no nested four-type members; no ALLOCATABLE).
  !   [OUT] status, pnewdt_min, IP failure count.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Field_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: field_id     = 0_i4    ! [IN] Field set ID (registry key)
    INTEGER(i4) :: elem_id      = 0_i4    ! [IN] Element number (NOEL)
    INTEGER(i4) :: ip_index     = 0_i4    ! [IN] Integration point index (NPT)
    INTEGER(i4) :: layer        = 1_i4    ! [IN] Shell layer (LAYER)
    INTEGER(i4) :: kspt         = 1_i4    ! [IN] Section point (KSPT)
    LOGICAL     :: is_first_inc = .FALSE. ! [IN] .TRUE. on first increment
    LOGICAL     :: need_getvrm  = .FALSE. ! [IN] .TRUE. if GETVRM retrieval needed
    !-- TODO: add RT-level call-time routing fields here
    !   e.g., predef_field(:) values pre-interpolated from PREDEF array

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status                   ! [OUT] Structured status; check %status_code
    LOGICAL               :: success       = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: pnewdt_min    = 1.0_wp   ! [OUT] Min pnewdt over all IPs
    INTEGER(i4)           :: n_ip_failed   = 0_i4    ! [OUT] Number of IPs that failed
    !-- TODO: add RT-level output diagnostics if needed
  END TYPE RT_XXX_Field_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Field_Apply
  !>
  !> ROLE: L5_RT driver-level field variable update at one material point.
  !>   Called once per integration point per increment by the step driver
  !>   (within the USDFLD/VUSDFLD loop).
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   field variable computation to PH_XXX_Field_API.
  !>
  !> Calling pattern (step driver side):
  !>   TYPE(RT_Field_Domain_Ctx)  :: Field_Ctx
  !>   TYPE(MD_Field_Base_State)  :: Field_State
  !>   TYPE(MD_Field_Base_Algo)   :: Field_Algo
  !>   TYPE(RT_Field_Bridge_Ctx)  :: Field_Bridge
  !>   TYPE(RT_XXX_Field_Args)    :: rt_args
  !>   rt_args%field_id            = active_field_id
  !>   rt_args%elem_id             = elem_label
  !>   rt_args%ip_index            = gauss_pt
  !>   rt_args%need_getvrm         = require_stress_retrieval
  !>   CALL RT_XXX_Field_Apply(Field_Ctx, Field_State, Field_Algo,
  !>                            Field_Bridge, RT_Com_Ctx, rt_args)
  !>   IF (rt_args%status%status_code /= IF_STATUS_OK) ... error handling ...
  !>   IF (rt_args%pnewdt_min < 1.0_wp) ... cutback ...
  !>
  !> SIO note:
  !>   First 4 args: RT_Field_Domain_Ctx / MD_Field_Base_State / Algo / Bridge
  !>   5th arg:      RT_Com_Base_Ctx  (shared increment bookkeeping)
  !>   6th:          RT_XXX_Field_Args  (SIO unified bundle, INOUT)
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Field_Apply(Field_Ctx, Field_State, Field_Algo, &
                                 Field_Bridge, RT_Com_Ctx, args)
    TYPE(RT_Field_Domain_Ctx),  INTENT(INOUT) :: Field_Ctx     ! RT domain ctx
    TYPE(MD_Field_Base_State),  INTENT(INOUT) :: Field_State   ! MD-level state
    TYPE(MD_Field_Base_Algo),   INTENT(IN)    :: Field_Algo    ! MD update config
    TYPE(RT_Field_Bridge_Ctx),  INTENT(INOUT) :: Field_Bridge  ! Bridge hot-path ctx
    TYPE(RT_Com_Base_Ctx),      INTENT(IN)    :: RT_Com_Ctx     ! Increment bookkeeping
    TYPE(RT_XXX_Field_Args),    INTENT(INOUT) :: args           ! Unified IO bundle

    !-- Local typed arguments for PH call (assembled here, NOT in PH layer)
    TYPE(MD_XXX_Field_Desc)   :: MD_Field_Desc   ! Concrete Desc for this field set
    TYPE(MD_Field_Base_Algo)  :: MD_Field_Algo   ! MD-owned update config
    TYPE(PH_Field_Base_Ctx)   :: PH_Field_Ctx    ! PH-owned per-increment context
    TYPE(PH_Field_Base_Algo)  :: PH_Field_Algo   ! PH-owned GETVRM flags
    TYPE(PH_XXX_Field_State)  :: PH_Field_State  ! PH-owned field state (concrete)

    !-- Locals
    TYPE(ErrorStatusType) :: props_st
    REAL(wp)              :: pnewdt_ip    ! Per-IP pnewdt feedback

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success     = .FALSE.
    args%pnewdt_min  = RT_PNEWDT_NO_CHANGE
    args%n_ip_failed = 0_i4

    !=========================================================================
    ! Step 1: Validate field set ID and active flag
    !=========================================================================
    IF (args%field_id < 1) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Field_Apply]: field_id must be >= 1')
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_XXX_Field_Desc from field property data
    !   In UFC-native mode:  Desc already built in registry — retrieve by ID.
    !
    !   TODO: replace stub below with actual Desc retrieval:
    !     Option A: MD_Field_Desc = field_registry%get(args%field_id)
    !     Option B: CALL MD_XXX_Field_InitFromProps(MD_Field_Desc, nprops, props, props_st)
    !=========================================================================
    MD_Field_Desc%field_id     = args%field_id
    MD_Field_Desc%is_initialized = .TRUE.
    !-- TODO: populate field-family-specific Desc fields
    !   MD_Field_Desc%nfield      = Field_Bridge%nfield
    !   MD_Field_Desc%nstatv      = Field_Bridge%nstatv

    !=========================================================================
    ! Step 3: Build PH_Field_Base_Ctx — per-increment driving inputs
    !   Fill from RT_Com_Ctx and inp (elem, IP, coords, temp, field_prev).
    !
    !   TODO: populate pointer fields from field/mesh state store:
    !     PH_Field_Ctx%field_prev => Field_State%field_prev_ip(:, args%ip_index)
    !     PH_Field_Ctx%statev     => Field_State%statev_ip(:, args%ip_index)
    !=========================================================================
    PH_Field_Ctx%elem_id     = args%elem_id
    PH_Field_Ctx%integ_pt_id = args%ip_index
    PH_Field_Ctx%layer_id    = args%layer
    PH_Field_Ctx%kspt        = args%kspt
    PH_Field_Ctx%kstep       = RT_Com_Ctx%kstep
    PH_Field_Ctx%kinc        = RT_Com_Ctx%kinc
    PH_Field_Ctx%time_current = RT_Com_Ctx%time_step
    PH_Field_Ctx%time_total   = RT_Com_Ctx%time_total
    PH_Field_Ctx%nfield       = Field_Bridge%nfield
    PH_Field_Ctx%nstatv       = Field_Bridge%nstatv
    NULLIFY(PH_Field_Ctx%field_prev, PH_Field_Ctx%statev)
    !-- TODO: ASSOCIATE pointer fields with per-IP arrays here

    !=========================================================================
    ! Step 4: Build MD_Field_Base_Algo and PH_Field_Base_Algo
    !=========================================================================
    MD_Field_Algo = Field_Algo

    PH_Field_Algo%get_stress  = args%need_getvrm
    PH_Field_Algo%get_strain  = args%need_getvrm
    PH_Field_Algo%get_peeq    = args%need_getvrm
    PH_Field_Algo%get_triax   = .FALSE.
    PH_Field_Algo%max_iter    = 10_i4
    PH_Field_Algo%tolerance   = 1.0e-6_wp
    PH_Field_Algo%pnewdt_min  = 0.1_wp
    PH_Field_Algo%pnewdt_max  = 2.0_wp

    !=========================================================================
    ! Step 5: Retrieve PH_XXX_Field_State from IP state store
    !   In production: retrieve from field_state_registry keyed by (field_id, elem, ip).
    !   TODO: PH_Field_State = field_state_registry%get(args%field_id, args%elem_id, args%ip_index)
    !=========================================================================
    !-- STUB: use default-initialized state

    !=========================================================================
    ! Step 6: Initialize pnewdt and delegate to PH_XXX_Field_API (L4_PH)
    !=========================================================================
    pnewdt_ip = RT_PNEWDT_NO_CHANGE

    CALL PH_XXX_Field_API(MD_Field_Desc, PH_Field_Ctx, PH_Field_State, &
                           MD_Field_Algo, PH_Field_Algo, RT_Com_Ctx, &
                           pnewdt_ip)

    !-- Accumulate pnewdt_min
    IF (pnewdt_ip < args%pnewdt_min) args%pnewdt_min = pnewdt_ip

    !-- Check for IP-level failure
    IF (.NOT. PH_Field_State%converged) THEN
      args%n_ip_failed = args%n_ip_failed + 1_i4
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Field_Apply]: field update failed at IP')
      RETURN
    END IF

    !=========================================================================
    ! Step 7: Write back PH_XXX_Field_State to field state store
    !   TODO: field_state_registry%put(args%field_id, args%elem_id, args%ip_index,
    !                                   PH_Field_State)
    !=========================================================================

    !=========================================================================
    ! Step 8: Scatter updated field values to global field array
    !   Typical pattern:
    !     Field_State%field_ip(:, args%ip_index) = PH_Field_State%field_val(:)
    !     Field_State%statev_ip(:, args%ip_index) = PH_Field_State%statev(:)
    !=========================================================================
    !-- STUB: write updated FIELD back to bridge (replace once arrays defined)
    !   Field_Bridge%field_val(:, args%ip_index) = PH_Field_State%field_val

    !-- Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_XXX_Field_Apply

END MODULE RT_XXX_Field_Proc
!===============================================================================
! CALL CHAIN DIAGRAM — RT_XXX_Field_Proc
!
! Step Driver (L6 / L5_RT StepDriver) — USDFLD loop
!   │
!   ├─ FOR each active element in this step:
!   │    FOR each integration point (ip = 1 .. n_ip):
!   │      rt_args%field_id        = field_set_id
!   │      rt_args%elem_id         = elem_label
!   │      rt_args%ip_index        = ip
!   │      rt_args%is_first_inc    = (kinc == 1)
!   │      rt_args%need_getvrm     = require_stress_retrieval
!   │      CALL RT_XXX_Field_Apply(Field_Ctx, Field_State, Field_Algo,
!   │                               Field_Bridge, RT_Com_Ctx, rt_args)
!   │
!   │    RT_XXX_Field_Apply  [L5_RT — THIS FILE]
!   │      Step 1: Validate field_id
!   │      Step 2: Build MD_XXX_Field_Desc (from registry or props)
!   │      Step 3: Build PH_Field_Base_Ctx (from RT_Com_Ctx + args + bridge)
!   │      Step 4: Build MD/PH Algo structs (GETVRM flags)
!   │      Step 5: Retrieve PH_XXX_Field_State from IP state store
!   │      Step 6: pnewdt=NO_CHANGE; CALL PH_XXX_Field_API(...)  ──► L4_PH
!   │      Step 7: Write back PH_XXX_Field_State
!   │      Step 8: Scatter FIELD(:,ip) into global field array
!   │
!   │    PH_XXX_Field_API  [L4_PH thin wrapper]
!   │      Packs field_inp/field_out, CALL PH_XXX_Field_Impl
!   │      Propagates pnewdt from field_out
!   │
!   │    PH_XXX_Field_Impl  [L4_PH hot path]
!   │      Step 1: First-inc → apply MD_Field_Desc%field_init
!   │      Step 2: GETVRM dispatch (stress/strain/peeq retrieval)
!   │      Step 3: Compute FIELD(NFIELD) from physics
!   │      Step 4: Update STATEV (SDV evolution)
!   │      Step 5: Convergence check + pnewdt signal
!   │
!   └─ END FOR (IP)
!      END FOR (element)
!      IF rt_args%pnewdt_min < 1.0_wp  → signal cutback to StepDriver
!
! DATA FLOW:
!   Field_Bridge.nfield              → PH_Field_Ctx.nfield
!   Field_Bridge.nstatv              → PH_Field_Ctx.nstatv
!   Field_State.field_prev_ip[:,ip]  → PH_Field_Ctx.field_prev (TODO)
!   Field_State.statev_ip[:,ip]      → PH_Field_Ctx.statev (TODO)
!   RT_Com_Ctx.kstep/kinc             → PH_Field_Ctx.kstep/kinc
!   PH_Field_State.field_val[:]       → Field_State.field_ip[:,ip]  (Step 8)
!   pnewdt_ip                         → args%pnewdt_min (global cutback)
!===============================================================================
