!===============================================================================
! Template: RT_XXX_BC_Proc.f90                                [Template v1.1]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: BoundaryCondition / [Family] (e.g., DISPL / VELO / TEMP / ...)
!
! HOW TO USE:
!   1. Copy to L5_RT/BC/[Family]/
!   2. Rename: RT_BC_[BCType]_Proc.f90
!              (e.g., RT_BC_Displacement_Proc.f90)
!   3. Replace XXX_XXX -> [BCFamily]_[BCType]
!   4. Replace XXX -> [BCType abbrev]
!   5. Wire up USE statements to the matching MD_BC_XXX, PH_XXX_BC modules
!   6. Implement RT_XXX_BC_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_BC_Apply    (THIS FILE, family facade)
!             → RT_BC_Brg / RT_BC_Impl family
!             → PH_XXX_BC_API       (L4_PH: BC physics, PH_XXX_BC_Args inside)
!             → PH_XXX_BC_Impl      (L4_PH: hot path BC enforcement)
!
! Principle #14 SIO compliance:
!   RT_XXX_BC_Apply uses the six-parameter form:
!     (BC_Desc, BC_State, BC_Algo, BC_Ctx, RT_Com_Ctx, args)
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified args TYPE
!   SIO-02 ✓  _Proc signature uses unified RT_XXX_BC_Args type with [IN]/[OUT] annotations
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields are routing scalars only
!   SIO-14 ✓  [IN] fields contain no ALLOCATABLE
!===============================================================================
MODULE RT_XXX_BC_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] BC descriptor & base types
  USE MD_BC_XXX,    ONLY: MD_BC_XXX_Desc, &
                         MD_BC_XXX_InitFromProps
  USE MD_BC_Types,  ONLY: MD_BC_Base_Desc
  !-- [PH] BC physics entry point
  USE PH_XXX_BC,    ONLY: PH_XXX_BC_API
  USE PH_BC_Types,  ONLY: PH_BC_Base_Ctx, &
                         PH_BC_Base_State
  !-- [RT] Runtime types
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  USE RT_BC_Impl_Def, ONLY: RT_BC_Impl_Desc, &
                            RT_BC_Impl_State, &
                            RT_BC_Impl_Algo, &
                            RT_BC_Impl_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_BC_Args  ! SIO: unified IO bundle with [IN]/[OUT] annotations
  PUBLIC :: RT_XXX_BC_Apply  ! Main entry: per-BC call → PH_XXX_BC_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant
  ! Unified bundle with [IN]/[OUT] annotations in comments
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_BC_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: bc_id            = 0_i4    ! [IN] BC entity ID
    INTEGER(i4) :: bc_type_id       = 0_i4    ! [IN] BC type flag (DISPL/VELO/TEMP)
    INTEGER(i4) :: amplitude_id     = 0_i4    ! [IN] Amplitude definition ID
    INTEGER(i4) :: dof_number       = 0_i4    ! [IN] DOF to constrain (1=U,2=V,3=W...)
    REAL(wp)    :: bc_value         = 0.0_wp  ! [IN] Prescribed value
    REAL(wp)    :: time_value       = 0.0_wp  ! [IN] Current time for amplitude eval
    LOGICAL     :: compute_bc       = .TRUE.  ! [IN] .TRUE. if BC enforcement needed
    LOGICAL     :: first_inc        = .FALSE. ! [IN] .TRUE. on first increment

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status      ! [OUT] Structured status; check %status_code
    LOGICAL               :: success = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: bc_applied = 0.0_wp ! [OUT] Applied BC value
    REAL(wp), POINTER     :: reaction(:) => NULL() ! [OUT] Reaction force vector
    INTEGER(i4)           :: node_failed = 0_i4  ! [OUT] First node that caused error
  END TYPE RT_XXX_BC_Args

CONTAINS

  !============================================================================
  !> RT_XXX_BC_Apply
  !>
  !> ROLE: L5_RT driver-level BC enforce call.
  !>   Called once per increment by the step driver for each active BC.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   BC enforcement to PH_XXX_BC_API.
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_BC_Apply(BC_Desc, BC_State, BC_Algo, BC_Ctx, &
                              RT_Com_Ctx, args)
    TYPE(RT_BC_Impl_Desc),  INTENT(IN)    :: BC_Desc    ! BC config (cold)
    TYPE(RT_BC_Impl_State), INTENT(INOUT) :: BC_State   ! Runtime state (warm)
    TYPE(RT_BC_Impl_Algo),  INTENT(IN)    :: BC_Algo    ! Algorithm config
    TYPE(RT_BC_Impl_Ctx),   INTENT(INOUT) :: BC_Ctx     ! Hot-path temporaries
    TYPE(RT_Com_Base_Ctx), INTENT(IN)   :: RT_Com_Ctx  ! Increment bookkeeping
    TYPE(RT_XXX_BC_Args), INTENT(INOUT) :: args         ! Unified IO bundle

    !-- Local typed arguments for PH call
    TYPE(MD_BC_XXX_Desc)  :: MD_BC_Desc     ! Concrete Desc for this BC type
    TYPE(PH_BC_Base_Ctx)  :: PH_BC_Ctx      ! PH-owned per-increment context
    TYPE(PH_BC_Base_State):: PH_BC_State   ! PH-owned BC state

    !-- Locals
    TYPE(ErrorStatusType) :: bc_status      ! Structured status returned by PH_XXX_BC_API

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success      = .FALSE.
    args%bc_applied   = 0.0_wp
    args%node_failed  = 0_i4

    !=========================================================================
    ! Step 1: Validate BC ID and active flag
    !=========================================================================
    IF (args%bc_id < 1 .OR. args%bc_id > BC_Desc%n_bcs) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_BC_Apply]: bc_id out of range')
      RETURN
    END IF
    IF (.NOT. BC_Desc%is_active) THEN
      args%success            = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_BC_XXX_Desc from BC property data
    !=========================================================================
    MD_BC_Desc%bc_id        = args%bc_id
    MD_BC_Desc%bc_type_id   = args%bc_type_id
    MD_BC_Desc%value        = args%bc_value
    MD_BC_Desc%dof_number   = args%dof_number
    MD_BC_Desc%amplitude_id = args%amplitude_id
    MD_BC_Desc%is_initialized = .TRUE.

    !=========================================================================
    ! Step 3: Build PH_BC_Base_Ctx — per-increment BC driving inputs
    !=========================================================================
    PH_BC_Ctx%bc_id       = args%bc_id
    PH_BC_Ctx%kstep       = RT_Com_Ctx%kstep
    PH_BC_Ctx%kinc        = RT_Com_Ctx%kinc
    PH_BC_Ctx%time_step   = RT_Com_Ctx%time_step
    PH_BC_Ctx%time_total  = RT_Com_Ctx%time_total

    !=========================================================================
    ! Step 4: Evaluate amplitude if present
    !=========================================================================
    IF (args%amplitude_id > 0) THEN
      ! TODO: Call amplitude evaluation routine
      ! MD_BC_Desc%value = MD_BC_Desc%value * amp_value
    END IF

    !=========================================================================
    ! Step 5: Delegate to PH_XXX_BC_API (L4_PH)
    !=========================================================================
    CALL init_error_status(bc_status)

    CALL PH_XXX_BC_API(MD_BC_Desc, PH_BC_Ctx, PH_BC_State, &
                       RT_Com_Ctx, bc_status)

    !-- Check BC-level error
    IF (bc_status%status_code == IF_STATUS_ERROR) THEN
      args%status = bc_status
      RETURN
    END IF

    !=========================================================================
    ! Step 6: Collect outputs
    !=========================================================================
    args%bc_applied = MD_BC_Desc%value

    ! Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_XXX_BC_Apply

END MODULE RT_XXX_BC_Proc
