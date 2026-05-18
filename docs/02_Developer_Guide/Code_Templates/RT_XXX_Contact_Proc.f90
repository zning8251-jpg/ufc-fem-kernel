!===============================================================================
! Template: RT_XXX_Contact_Proc.f90                             [Template v1.0]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Contact / [Family] (e.g., FULL / FRIC / COUL / GAP / GAPCON)
!
! HOW TO USE:
!   1. Copy to L5_RT/Contact/[Family]/
!   2. Rename: RT_Contact_[Family]_[Type]_Proc.f90
!              (e.g., RT_Contact_COUL_Linear_Proc.f90)
!   3. Replace XXX_XXX -> [Family]_[Type] throughout
!   4. Replace XXX     -> [Type abbrev]
!   5. Wire up USE statements to matching MD_XXX_Contact, PH_XXX_Contact modules
!   6. Implement RT_XXX_Contact_Eval — single entry called by contact search loop
!
! Role in UFC Call Chain:
!   ContactSearch → RT_XXX_Contact_Eval  (THIS FILE)
!                → PH_XXX_Contact_API    (L4_PH: physics, PH_XXX_Contact_Args inside)
!                -> PH_XXX_Contact_Impl  (L4_PH: hot path, Principle #14 SIO)
!
! Key difference from BC/Load Proc:
!   - Called from the CONTACT SEARCH loop (one call per detected contact point)
!     rather than from the element/node assembly loop.
!   - gap, slip1, slip2 come from the contact geometry search result.
!   - Results (press, tau1, tau2) are assembled into the contact force vector
!     and optionally into the contact stiffness matrix.
!   - pnewdt feedback IS meaningful for contact (slip reversal / divergence).
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified RT_XXX_Contact_Args bundle
!   SIO-02 ✓  _Proc uses RT_XXX_Contact_Args with [IN]/[OUT] comments
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields have no _Desc/_State/_Algo/_Ctx members
!   SIO-14 ✓  [IN] fields have no ALLOCATABLE members
!===============================================================================
MODULE RT_XXX_Contact_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Contact descriptor & base types
  USE MD_Contact_XXX_XXX,  ONLY: MD_XXX_Contact_Desc, &
                                  MD_XXX_Contact_InitFromProps
  USE MD_Contact_Types,    ONLY: MD_Contact_Base_Desc, &
                                  MD_Contact_Base_State, &
                                  MD_Contact_Base_Algo
  !-- [PH] Contact physics entry point
  USE PH_XXX_Contact,      ONLY: PH_XXX_Contact_State, &
                                  PH_XXX_Contact_API
  USE PH_Contact_Types,    ONLY: PH_Contact_Base_Ctx, &
                                  PH_Contact_Base_Algo
  !-- [RT] Runtime types
  USE RT_Com_Types,        ONLY: RT_Com_Base_Ctx
  USE RT_Bridge_Types,     ONLY: RT_Contact_Bridge_Ctx
  USE RT_Contact_Types,    ONLY: RT_Contact_Desc, &
                                  RT_Contact_State, &
                                  RT_Contact_Algo, &
                                  RT_Contact_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Contact_Args  ! Unified IO bundle ([IN]/[OUT] in comments)
  PUBLIC :: RT_XXX_Contact_Eval  ! Main entry: evaluate one contact point

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant unified bundle
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Contact_Args
    !-- [IN] Geometry search result + routing IDs
    INTEGER(i4) :: contact_pair_id   = 0_i4
    INTEGER(i4) :: slave_node_id     = 0_i4
    INTEGER(i4) :: master_elem_id    = 0_i4
    INTEGER(i4) :: integ_pt_id       = 0_i4
    REAL(wp)    :: gap               = 0.0_wp
    REAL(wp)    :: slip1             = 0.0_wp
    REAL(wp)    :: slip2             = 0.0_wp
    REAL(wp)    :: coords(3)         = 0.0_wp
    REAL(wp)    :: temp              = 0.0_wp
    !-- TODO: normal_vector(3), gauss_weight, jacobian_area, ...

    !-- [OUT] Forces + status + pnewdt
    TYPE(ErrorStatusType) :: status            ! Structured status; check %status_code
    LOGICAL               :: success       = .FALSE.
    LOGICAL               :: in_contact    = .FALSE.
    REAL(wp)              :: press         = 0.0_wp
    REAL(wp)              :: tau1          = 0.0_wp
    REAL(wp)              :: tau2          = 0.0_wp
    REAL(wp)              :: work_fric_incr = 0.0_wp
    REAL(wp)              :: pnewdt        = 1.0_wp
    !-- TODO: conductance, contact_force_vector(3), stiffness_contribution
  END TYPE RT_XXX_Contact_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Contact_Eval
  !>
  !> ROLE: L5_RT driver-level contact evaluation at one contact point.
  !>   Called by the contact search loop after geometric search finds a
  !>   slave node/IP within contact range of a master surface.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, delegates
  !>   to PH_XXX_Contact_API, then deposits contact force into f_contact.
  !>
  !> Calling pattern (contact search loop side):
  !>   TYPE(RT_XXX_Contact_Args)  :: rt_args
  !>   rt_args%contact_pair_id  = pair_idx
  !>   rt_args%slave_node_id    = slave_node
  !>   rt_args%gap              = computed_gap
  !>   rt_args%slip1            = computed_slip1
  !>   rt_args%slip2            = computed_slip2
  !>   CALL RT_XXX_Contact_Eval(CT_Desc, CT_State, CT_Algo, CT_Ctx,
  !>                             RT_Com_Ctx, rt_args)
  !>   IF (rt_args%in_contact) THEN
  !>     f_contact(slave_dofs) -= rt_args%press * normal_area + rt_args%tau1/2 * ...
  !>   END IF
  !>
  !> pnewdt: rt_args%pnewdt < 1.0 → cut increment; = 1.0 → no request
  !>
  !> SIO: 6th arg RT_XXX_Contact_Args (INOUT)
  !============================================================================
  ! Phase: Compute | Eval | HOT_PATH
  SUBROUTINE RT_XXX_Contact_Eval(CT_Desc, CT_State, CT_Algo, CT_Ctx, &
                                   RT_Com_Ctx, args)
    TYPE(RT_Contact_Desc),     INTENT(IN)    :: CT_Desc
    TYPE(RT_Contact_State),    INTENT(INOUT) :: CT_State
    TYPE(RT_Contact_Algo),     INTENT(IN)    :: CT_Algo
    TYPE(RT_Contact_Ctx),      INTENT(INOUT) :: CT_Ctx
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx
    TYPE(RT_XXX_Contact_Args), INTENT(INOUT) :: args

    !-- Local typed arguments for PH call
    TYPE(MD_XXX_Contact_Desc)  :: MD_Contact_Desc    ! Concrete Desc for this model
    TYPE(MD_Contact_Base_State):: MD_Contact_State   ! MD-owned contact state
    TYPE(MD_Contact_Base_Algo) :: MD_Contact_Algo    ! MD-owned algorithm config
    TYPE(PH_Contact_Base_Ctx)  :: PH_Contact_Ctx     ! PH-owned per-point context
    TYPE(PH_Contact_Base_Algo) :: PH_Contact_Algo    ! PH-owned iteration control
    TYPE(PH_XXX_Contact_State) :: PH_Contact_State   ! PH-owned contact state

    !-- Locals
    REAL(wp) :: press, tau1, tau2

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success        = .FALSE.
    args%in_contact     = .FALSE.
    args%press          = 0.0_wp
    args%tau1           = 0.0_wp
    args%tau2           = 0.0_wp
    args%work_fric_incr = 0.0_wp
    args%pnewdt         = 1.0_wp

    !=========================================================================
    ! Step 1: Validate that the requested contact pair is active
    !=========================================================================
    IF (args%contact_pair_id < 1 .OR. args%contact_pair_id > CT_Desc%n_contact_pairs) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Contact_Eval]: contact_pair_id out of range')
      RETURN
    END IF
    IF (.NOT. CT_State%pair_active(args%contact_pair_id)) THEN
      !-- Pair inactive this step: treat as no-op
      args%success = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_XXX_Contact_Desc
    !   Option A (UFC registry): retrieve Desc by contact_pair_id
    !   Option B (from props):   CALL MD_XXX_Contact_InitFromProps(...)
    !   TODO: replace stub with actual retrieval.
    !=========================================================================
    MD_Contact_Desc%contact_family   = CT_Desc%contact_types(args%contact_pair_id)
    MD_Contact_Desc%normal_behavior  = 2_i4   ! TODO: read from registry (default: penalty)
    MD_Contact_Desc%normal_stiffness = CT_Desc%penalty_stiffness(args%contact_pair_id)
    MD_Contact_Desc%fric_law         = CT_Desc%friction_models(args%contact_pair_id)
    MD_Contact_Desc%fric_coeff       = CT_Desc%friction_coeffs(args%contact_pair_id)
    MD_Contact_Desc%contact_threshold = CT_Desc%global_search_tol
    MD_Contact_Desc%is_initialized   = .TRUE.

    !=========================================================================
    ! Step 3: Build PH_Contact_Base_Ctx — per-contact-point driving inputs
    !   Fill from args (gap, slip, coords, temp) — from contact search
    !=========================================================================
    PH_Contact_Ctx%gap          = args%gap
    PH_Contact_Ctx%slip1        = args%slip1
    PH_Contact_Ctx%slip2        = args%slip2
    PH_Contact_Ctx%coords(:)    = args%coords
    PH_Contact_Ctx%temp         = args%temp
    PH_Contact_Ctx%elem_id      = args%master_elem_id
    PH_Contact_Ctx%integ_pt_id  = args%integ_pt_id

    !=========================================================================
    ! Step 4: Build MD_Contact_Base_Algo and PH_Contact_Base_Algo
    !=========================================================================
    MD_Contact_Algo%algorithm          = CT_Algo%constraint_method
    MD_Contact_Algo%use_stabilization  = CT_Algo%use_damping
    MD_Contact_Algo%stabilization_factor = CT_Algo%damping_factor
    MD_Contact_Algo%print_debug        = .FALSE.

    PH_Contact_Algo%max_iter           = MD_Contact_Desc%max_iter
    PH_Contact_Algo%tolerance          = CT_Algo%slip_tolerance
    PH_Contact_Algo%pnewdt_min         = 0.1_wp
    PH_Contact_Algo%pnewdt_max         = 1.0_wp
    PH_Contact_Algo%use_stabilization  = CT_Algo%use_damping

    !=========================================================================
    ! Step 5: Retrieve PH_Contact_State from state store
    !   Keyed by (contact_pair_id, slave_node_id, integ_pt_id)
    !   TODO: PH_Contact_State = contact_state_registry%get(...)
    !=========================================================================

    !=========================================================================
    ! Step 6: Delegate to PH_XXX_Contact_API (L4_PH physics)
    !=========================================================================
    CALL PH_XXX_Contact_API(MD_Contact_Desc, PH_Contact_Ctx, PH_Contact_State, &
                             MD_Contact_Algo, PH_Contact_Algo, RT_Com_Ctx, &
                             press, tau1, tau2)
    args%press = press
    args%tau1  = tau1
    args%tau2  = tau2

    !-- Propagate physics-level contact state to RT output
    args%in_contact     = PH_Contact_State%gap_history <= 0.0_wp
    args%work_fric_incr = PH_Contact_State%energy_dissipated  ! last increment

    !=========================================================================
    ! Step 7: Write back PH_Contact_State to state store
    !   TODO: contact_state_registry%put(...)
    !=========================================================================

    !=========================================================================
    ! Step 8: Update RT_Contact_State statistics
    !   Aggregate into CT_State for convergence monitoring and output
    !=========================================================================
    IF (args%in_contact) THEN
      CT_State%total_contact_force = CT_State%total_contact_force + args%press
      IF (ABS(args%press) > CT_State%max_contact_force) THEN
        CT_State%max_contact_force = ABS(args%press)
      END IF
      IF (args%gap < 0.0_wp) THEN
        !-- Penetration: update max penetration tracking
        IF (ABS(args%gap) > CT_State%max_penetration) &
          CT_State%max_penetration = ABS(args%gap)
        CT_State%avg_penetration = CT_State%avg_penetration + ABS(args%gap)
        CT_State%n_closed_pairs  = CT_State%n_closed_pairs  + 1
      END IF
    ELSE
      CT_State%n_open_pairs = CT_State%n_open_pairs + 1
    END IF

    !=========================================================================
    ! Step 9: pnewdt feedback
    !   If contact is oscillating (gap flip or excessive penetration),
    !   request step cut.  Otherwise leave pnewdt = 1.
    !   TODO: implement actual convergence check using CT_Algo thresholds
    !=========================================================================
    args%pnewdt = 1.0_wp   ! Default: no step-size request

    !-- Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE RT_XXX_Contact_Eval

END MODULE RT_XXX_Contact_Proc
!===============================================================================
! CALL CHAIN DIAGRAM — RT_XXX_Contact_Proc
!
! Contact Search (L5_RT)
!   │  (geometric search: master/slave pairing, gap computation)
!   │
!   ├─ FOR each detected contact point c:
!   │    rt_args%contact_pair_id  = pair_idx
!   │    rt_args%slave_node_id    = slave_label
!   │    rt_args%master_elem_id   = master_elem
!   │    rt_args%gap              = geometry_gap(c)       ! from search
!   │    rt_args%slip1/slip2      = geometry_slip(c)
!   │    rt_args%coords           = contact_point_coords
!   │    rt_args%temp             = interpolated_temp(c)
!   │    CALL RT_XXX_Contact_Eval(CT_Desc, CT_State, CT_Algo, CT_Ctx,
!   │                              RT_Com_Ctx, rt_args)
!   │
!   │    RT_XXX_Contact_Eval  [L5_RT — THIS FILE]
!   │      Step 1: Validate pair_id & active flag
!   │      Step 2: Build MD_XXX_Contact_Desc (registry or props)
!   │      Step 3: Build PH_Contact_Base_Ctx (gap, slip, coords, temp)
!   │      Step 4: Build MD/PH Algo structs
!   │      Step 5: Retrieve PH_Contact_State from state store
!   │      Step 6: CALL PH_XXX_Contact_API(...)  ──► L4_PH
!   │      Step 7: Write back PH_Contact_State
!   │      Step 8: Update CT_State statistics
!   │      Step 9: pnewdt feedback
!   │
!   │    PH_XXX_Contact_API  [L4_PH thin wrapper]
!   │      Packs ct_inp/ct_out, CALL PH_XXX_Contact_Impl
!   │
!   │    PH_XXX_Contact_Impl  [L4_PH hot path]
!   │      Step 1: Normal contact (gap check, press)
!   │      Step 2: Tangential friction (tau1, tau2)
!   │      Step 3: State update
!   │      Returns: press, tau1, tau2, PH_Contact_State updated
!   │
!   │    Assembly:
!   │      f_contact(slave_global_dof) -= press * normal_area * normal_vec(d)
!   │                                   + tau1  * tangent1_area * tangent1_vec(d)
!   │                                   + tau2  * tangent2_area * tangent2_vec(d)
!   │      (master surface gets equal and opposite reaction)
!   │
!   └─ END FOR contact points
!
! DATA FLOW:
!   geometry_search.gap            → args.gap       → PH_Contact_Ctx.gap
!   geometry_search.slip1/2        → args.slip1/2   → PH_Contact_Ctx.slip1/2
!   CT_Desc.penalty_stiffness[i]   → MD_Contact_Desc.normal_stiffness
!   CT_Desc.friction_coeffs[i]     → MD_Contact_Desc.fric_coeff
!   args.press / tau1 / tau2        → contact force assembly
!   args.pnewdt < 1.0               → step driver: cut increment
!===============================================================================
