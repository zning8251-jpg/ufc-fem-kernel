!===============================================================================
! Template: RT_XXX_Elem_Proc.f90                                [Template v1.0]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Element / [Family] (e.g., CONTI / SHELL / BEAM / TRUSS / ...)
!
! HOW TO USE:
!   1. Copy to L5_RT/Element/[Family]/
!   2. Rename: RT_Elem_[ElemType]_Proc.f90
!              (e.g., RT_Elem_C3D8_Proc.f90)
!   3. Replace XXX_XXX -> [ElemFamily]_[Model]  (e.g., CONTI_C3D8)
!   4. Replace XXX     -> [ElemType abbrev]     (e.g., C3D8)
!   5. Wire up USE statements to the matching MD_Elem_XXX, PH_XXX_UEL modules
!   6. Implement RT_XXX_Elem_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Elem_Apply    (THIS FILE)
!             → PH_XXX_UEL_API       (L4_PH: element physics, _In/_Out wrapper)
!             → PH_XXX_UEL_Impl      (L4_PH: hot path, Principle #14 SIO)
!             → PH_XXX_UMAT_API      (L4_PH: per-IP constitutive update)
!
! Principle #14 SIO compliance:
!   RT_XXX_Elem_Apply uses the six-parameter form:
!     (Elem_Desc, Elem_State, Elem_Algo, Elem_Ctx, RT_Com_Ctx, args)
!   pnewdt and uel_status remain PH_XXX_UEL_API ABI exceptions.
!   uel_status is still a structured status object: initialize with
!   init_error_status(...) and inspect %status_code at the RT/L4 boundary.
!
! Relationship to RT_Elem_Domain_Ctx (RT_Domain_Types.f90):
!   RT_Elem_Domain_Ctx is the persistent per-element call packet managed by
!   the domain bridge. This _Proc module assembles and tears-down that packet
!   per element, then delegates to PH_XXX_UEL_API.
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified RT_XXX_Elem_Args bundle
!   SIO-02 ✓  _Proc signature uses RT_XXX_Elem_Args with [IN]/[OUT] comments
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields have no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  [IN] fields have no ALLOCATABLE members
!   NOTE: pnewdt / uel_status are documented L4/L5 ABI exceptions; uel_status
!         still follows the IF_Err_Brg structured-status baseline.
!===============================================================================
MODULE RT_XXX_Elem_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Element descriptor & base types
  USE MD_Elem_XXX,     ONLY: MD_Elem_XXX_Desc, &
                              MD_Elem_XXX_InitFromProps
  USE MD_Elem_Types,   ONLY: MD_Elem_Base_Desc
  USE MD_Sect_Types,   ONLY: MD_Sect_Registry
  !-- [PH] UEL physics entry point
  USE PH_XXX_UEL,      ONLY: PH_XXX_UEL_API
  USE PH_Elem_Types,   ONLY: PH_Elem_Base_Ctx, &
                              PH_Elem_Base_State
  !-- [RT] Runtime types
  USE RT_Com_Types,    ONLY: RT_Com_Base_Ctx, &
                              RT_PNEWDT_NO_CHANGE
  USE RT_Bridge_Types, ONLY: RT_Elem_Bridge_Ctx
  USE RT_Elem_Types,   ONLY: RT_Elem_Desc, &
                              RT_Elem_State, &
                              RT_Elem_Algo, &
                              RT_Elem_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Elem_Args   ! Unified IO bundle ([IN]/[OUT] in comments)
  PUBLIC :: RT_XXX_Elem_Apply  ! Main entry: per-element call → PH_XXX_UEL_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant unified bundle
  !
  !   [IN]  Call-time routing scalars (no _Desc/_State/_Algo/_Ctx; no ALLOCATABLE).
  !   [OUT] status, pnewdt feedback, strain energy, diagnostics.
  !
  !   pnewdt_min aggregates per-IP UMAT feedback for increment cutback.
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Elem_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: elem_id         = 0_i4    ! [IN] Element number (NOEL)
    INTEGER(i4) :: elem_type_id    = 0_i4    ! [IN] Element type flag (JTYPE)
    INTEGER(i4) :: section_id      = 0_i4    ! [IN] Section ID (jprops(1))
    LOGICAL     :: compute_amatrx  = .TRUE.  ! [IN] .TRUE. if tangent stiffness needed
    LOGICAL     :: compute_rhs     = .TRUE.  ! [IN] .TRUE. if internal force needed
    LOGICAL     :: first_inc       = .FALSE. ! [IN] .TRUE. on first increment of step
    !-- TODO: add RT-level call-time routing fields here
    !   e.g., distributed_load_type (for DLOAD coupling)
    !         contact_flag (for embedded contact UEL)

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status                   ! [OUT] Structured status; check %status_code
    LOGICAL               :: success       = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: pnewdt_min    = 1.0_wp   ! [OUT] Min pnewdt across all IPs
    REAL(wp)              :: strain_energy = 0.0_wp   ! [OUT] Integrated strain energy [J]
    INTEGER(i4)           :: ip_failed     = 0_i4    ! [OUT] First IP that caused error (0=none)
    !-- TODO: add RT-level output diagnostics if needed
    !   e.g., hourglass_energy, max_stress_ip
  END TYPE RT_XXX_Elem_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Elem_Apply
  !>
  !> ROLE: L5_RT driver-level element compute call.
  !>   Called once per increment by the step driver for each active element.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   stiffness + residual computation to PH_XXX_UEL_API.
  !>
  !> Calling pattern (step driver side):
  !>   TYPE(RT_Elem_Desc)       :: Elem_Desc
  !>   TYPE(RT_Elem_State)      :: Elem_State
  !>   TYPE(RT_Elem_Algo)       :: Elem_Algo
  !>   TYPE(RT_Elem_Ctx)        :: Elem_Ctx
  !>   TYPE(RT_XXX_Elem_Args)   :: rt_args
  !>   rt_args%elem_id           = current_element
  !>   rt_args%section_id        = jprops(1)
  !>   rt_args%compute_amatrx    = need_stiffness
  !>   rt_args%compute_rhs       = need_residual
  !>   CALL RT_XXX_Elem_Apply(Elem_Desc, Elem_State, Elem_Algo, Elem_Ctx,
  !>                           RT_Com_Ctx, rt_args)
  !>   IF (rt_args%status%status_code /= IF_STATUS_OK) ... error handling ...
  !>   IF (rt_args%pnewdt_min < 1.0_wp) ... cutback ...
  !>
  !> SIO note:
  !>   First 4 args: RT_Elem_Desc / State / Algo / Ctx  (RT-owned)
  !>   5th arg:      RT_Com_Base_Ctx  (shared increment bookkeeping)
  !>   6th:          RT_XXX_Elem_Args  (SIO unified bundle, INOUT)
  !>   pnewdt:       bare REAL(wp) INOUT passed to PH_XXX_UEL_API
  !>   uel_status:   structured status OUT from PH_XXX_UEL_API; check
  !>                 uel_status%status_code after the call
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Elem_Apply(Elem_Desc, Elem_State, Elem_Algo, Elem_Ctx, &
                                RT_Com_Ctx, args)
    TYPE(RT_Elem_Desc),     INTENT(IN)    :: Elem_Desc   ! Element config (cold)
    TYPE(RT_Elem_State),    INTENT(INOUT) :: Elem_State  ! Runtime state (warm)
    TYPE(RT_Elem_Algo),     INTENT(IN)    :: Elem_Algo   ! Algorithm config
    TYPE(RT_Elem_Ctx),      INTENT(INOUT) :: Elem_Ctx    ! Hot-path temporaries
    TYPE(RT_Com_Base_Ctx),  INTENT(IN)    :: RT_Com_Ctx   ! Increment bookkeeping
    TYPE(RT_XXX_Elem_Args), INTENT(INOUT) :: args         ! Unified IO bundle

    !-- Local typed arguments for PH call (assembled here, NOT in PH layer)
    TYPE(MD_Elem_XXX_Desc)  :: MD_Elem_Desc    ! Concrete Desc for this element type
    TYPE(PH_Elem_Base_Ctx)  :: PH_Elem_Ctx     ! PH-owned per-increment context
    TYPE(PH_Elem_Base_State):: PH_Elem_State   ! PH-owned element state (rhs, amatrx, svars)

    !-- Locals
    TYPE(ErrorStatusType) :: uel_status          ! Structured status from PH_XXX_UEL_API
    TYPE(MD_Sect_Registry), TARGET :: sect_reg   ! Section registry pointer target
    REAL(wp)              :: pnewdt               ! Per-element pnewdt feedback

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success       = .FALSE.
    args%pnewdt_min    = RT_PNEWDT_NO_CHANGE
    args%strain_energy = 0.0_wp
    args%ip_failed     = 0_i4

    !=========================================================================
    ! Step 1: Validate element ID and active flag
    !   Check args%elem_id against Elem_Desc%n_elements bounds.
    !   Verify the element is registered and active.
    !=========================================================================
    IF (args%elem_id < 1 .OR. args%elem_id > Elem_Desc%n_elements) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Elem_Apply]: elem_id out of range')
      RETURN
    END IF
    IF (.NOT. Elem_Desc%elem_active(args%elem_id)) THEN
      !-- Element inactive this step: treat as no-op (not an error)
      args%success            = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_Elem_XXX_Desc from element property data
    !   In UFC-native mode:  Desc already built in registry — retrieve by ID.
    !   In ABAQUS plug-in:   Build from raw props stored in Elem_Desc.
    !
    !   TODO: replace stub below with actual Desc retrieval / construction:
    !     Option A (UFC registry): MD_Elem_Desc = elem_registry%get(args%elem_id)
    !     Option B (from props):   CALL MD_Elem_XXX_InitFromProps(MD_Elem_Desc,
    !                                nprops, props, props_st)
    !=========================================================================
    !-- STUB: minimal Desc from Elem_Desc scalar fields
    MD_Elem_Desc%elem_id       = args%elem_id
    MD_Elem_Desc%jtype         = args%elem_type_id
    MD_Elem_Desc%integ_npts    = Elem_Desc%nip_per_elem  ! e.g., 8 for C3D8
    MD_Elem_Desc%n_nodes       = Elem_Desc%n_nodes_per_elem
    MD_Elem_Desc%is_initialized = .TRUE.
    !-- TODO: populate nlgeom flag, section thickness (shells), reduced int flag, etc.

    !=========================================================================
    ! Step 3: Resolve section registry (for UEL -> UMAT bridge)
    !   sect_registry provides UMAT Desc pointers keyed by section_id.
    !   In production: retrieve from global runtime registry.
    !
    !   TODO: sect_reg = RT_Com_Ctx%sect_registry (if stored in common ctx)
    !         or retrieve from a module-level singleton / UFCHarness accessor.
    !=========================================================================
    !-- STUB: empty registry (must be replaced before production use)
    !-- PRODUCTION: sect_reg = global_sect_registry

    !=========================================================================
    ! Step 4: Build PH_Elem_Base_Ctx — per-increment element driving inputs
    !   Fill from RT_Com_Ctx (time, step, kinc, lflags) and inp.
    !   Nodal coordinates and displacement increments come from mesh state.
    !
    !   TODO: populate arrays from mesh state store:
    !     PH_Elem_Ctx%coords(:,:)   = Elem_Ctx%coords(:,:, args%elem_id)
    !     PH_Elem_Ctx%u(:)          = Elem_Ctx%u(:, args%elem_id)
    !     PH_Elem_Ctx%du(:)         = Elem_Ctx%du(:, args%elem_id)
    !     PH_Elem_Ctx%v(:)          = Elem_Ctx%v(:, args%elem_id)  (if dynamic)
    !     PH_Elem_Ctx%a(:)          = Elem_Ctx%a(:, args%elem_id)  (if dynamic)
    !=========================================================================
    PH_Elem_Ctx%elem_id     = args%elem_id
    PH_Elem_Ctx%jtype       = args%elem_type_id
    PH_Elem_Ctx%kstep       = RT_Com_Ctx%kstep
    PH_Elem_Ctx%kinc        = RT_Com_Ctx%kinc
    PH_Elem_Ctx%time_step   = RT_Com_Ctx%time_step
    PH_Elem_Ctx%time_total  = RT_Com_Ctx%time_total
    PH_Elem_Ctx%nlgeom      = RT_Com_Ctx%nlgeom
    PH_Elem_Ctx%lflags(:)   = RT_Com_Ctx%lflags(:)
    !-- TODO: fill nodal arrays (coords, u, du, v, a) from mesh/bridge context

    !=========================================================================
    ! Step 5: Retrieve PH_Elem_Base_State from element state store
    !   State contains: rhs (internal force), amatrx (stiffness), svars, energy.
    !   In production: retrieve from elem_state_registry keyed by elem_id.
    !   svars layout: ufc_core/L4_PH/contracts/CONTRACT_SVARS_IP_LAYOUT.md
    !
    !   TODO: replace stub with actual state retrieval:
    !     PH_Elem_State = elem_state_registry%get(args%elem_id)
    !=========================================================================
    !-- STUB: use default-initialized state
    !-- PRODUCTION: PH_Elem_State = elem_state_registry%get(args%elem_id)

    !=========================================================================
    ! Step 6: Initialize pnewdt and delegate to PH_XXX_UEL_API (L4_PH)
    !   pnewdt is INOUT: init to NO_CHANGE; accumulates cutback from all IPs.
    !   uel_status is OUT: carries structured error channel from L4_PH.
    !=========================================================================
    pnewdt = RT_PNEWDT_NO_CHANGE
    CALL init_error_status(uel_status)

    CALL PH_XXX_UEL_API(sect_reg, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &
                         RT_Com_Ctx, pnewdt, uel_status)

    !-- Check UEL-level error
    IF (uel_status%status_code == IF_STATUS_ERROR) THEN
      args%status    = uel_status
      args%ip_failed = PH_Elem_Ctx%first_failed_ip    ! populated by UEL_Impl
      RETURN
    END IF

    !-- Collect outputs
    IF (pnewdt < args%pnewdt_min) THEN
      args%pnewdt_min = pnewdt
    END IF
    args%strain_energy = PH_Elem_State%energy(1)     ! ENER(1) = elastic strain energy

    !=========================================================================
    ! Step 7: Write back PH_Elem_Base_State to element state store
    !   State must be persisted so the next increment starts from n+1 values.
    !   svars must be written back to enable ABAQUS output field requests.
    !   TODO: elem_state_registry%put(args%elem_id, PH_Elem_State)
    !=========================================================================

    !=========================================================================
    ! Step 8: Scatter rhs / amatrx into global assembly buffers via Elem_Ctx
    !   Typical pattern:
    !     Elem_Ctx%rhs_local(:, args%elem_id)         = PH_Elem_State%rhs(:)
    !     Elem_Ctx%amatrx_local(:,:, args%elem_id)    = PH_Elem_State%amatrx(:,:)
    !   Actual global assembly (DOF scatter) is done by the Assembly domain.
    !=========================================================================
    !-- STUB: wire-up via Elem_Ctx (replace once ctx arrays are defined)
    !   Elem_Ctx%rhs_local(:, args%elem_id)      = PH_Elem_State%rhs
    !   Elem_Ctx%amatrx_local(:,:, args%elem_id) = PH_Elem_State%amatrx
    !   Elem_Ctx%strain_energy(args%elem_id)      = args%strain_energy

    !-- Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_XXX_Elem_Apply

END MODULE RT_XXX_Elem_Proc
!===============================================================================
! CALL CHAIN DIAGRAM — RT_XXX_Elem_Proc
!
! Step Driver (L6 / L5_RT StepDriver)
!   │
!   ├─ FOR each active element in this step:
!   │    rt_args%elem_id           = elem_label       (from element loop)
!   │    rt_args%elem_type_id      = jtype            (from element table)
!   │    rt_args%section_id        = jprops(1)        (from section map)
!   │    rt_args%compute_amatrx    = need_stiffness   (from lflags logic)
!   │    rt_args%compute_rhs       = need_residual    (from lflags logic)
!   │    CALL RT_XXX_Elem_Apply(Elem_Desc, Elem_State, Elem_Algo, Elem_Ctx,
!   │                            RT_Com_Ctx, rt_args)
!   │
!   │    RT_XXX_Elem_Apply  [L5_RT — THIS FILE]
!   │      Step 1: Validate elem_id & active flag
!   │      Step 2: Build MD_Elem_XXX_Desc (from registry or props)
!   │      Step 3: Resolve sect_registry (for UMAT bridge)
!   │      Step 4: Build PH_Elem_Base_Ctx (from RT_Com_Ctx + args + mesh)
!   │      Step 5: Retrieve PH_Elem_Base_State from state store
!   │      Step 6: pnewdt=NO_CHANGE; CALL PH_XXX_UEL_API(...)  ──► L4_PH
!   │      Step 7: Write back PH_Elem_Base_State
!   │      Step 8: Scatter rhs / amatrx into Elem_Ctx assembly buffers
!   │
!   │    PH_XXX_UEL_API  [L4_PH thin wrapper]
!   │      Packs uel_inp/uel_out, CALL PH_XXX_UEL_Impl
!   │      Returns pnewdt and uel_status
!   │
!   │    PH_XXX_UEL_Impl  [L4_PH hot path — IP loop]
!   │      FOR ip = 1 .. integ_npts:
!   │        Load svars slice -> PH_Mat_State
!   │        Build B-matrix, compute dstran from PH_Elem_Ctx
!   │        CALL PH_XXX_UMAT_API(...)  ──► L4_PH constitutive
!   │        Write PH_Mat_State -> svars slice
!   │        Accumulate K_e, f_int, energy
!   │
!   └─ END FOR (element)
!      Collect global pnewdt_min, strain_energy
!      If any element fails: abort increment
!      → Assembly domain picks up Elem_Ctx buffers
!
! DATA FLOW:
!   Elem_Desc.elem_active[i]      → validate active
!   Elem_Desc.nip_per_elem        → MD_Elem_Desc.integ_npts
!   Elem_Ctx.coords[:,:, elem]    → PH_Elem_Ctx.coords   (Step 4, TODO)
!   Elem_Ctx.u[:, elem]           → PH_Elem_Ctx.u        (Step 4, TODO)
!   RT_Com_Ctx.kstep/kinc/lflags   → PH_Elem_Ctx.*
!   PH_Elem_State.rhs[:]           → Elem_Ctx.rhs_local[:, elem]   (Step 8)
!   PH_Elem_State.amatrx[:,:]      → Elem_Ctx.amatrx_local[:,:, elem] (Step 8)
!   pnewdt                         → args%pnewdt_min (global cutback signal)
!   uel_status                     → args%status
!===============================================================================
