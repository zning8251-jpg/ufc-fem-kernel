!===============================================================================
! Template: RT_XXX_Constraint_Proc.f90                       [Template v1.1]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Constraint / [Family] (e.g., MPC / RBE / SPRING / CONTACT / ...)
!
! HOW TO USE:
!   1. Copy to L5_RT/Constraint/[Family]/
!   2. Rename: RT_Constraint_[Type]_Proc.f90
!              (e.g., RT_Constraint_MPC_Proc.f90)
!   3. Replace XXX_XXX -> [ConstraintFamily]_[Type]
!   4. Replace XXX -> [ConstraintType abbrev]
!   5. Wire up USE statements to the matching MD_Constraint_XXX, PH_XXX modules
!   6. Implement RT_XXX_Constraint_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Constraint_Apply    (THIS FILE, family facade)
!             → RT_Constraint_Brg / support bridge family
!             → PH_XXX_Constraint_API        (L4_PH: constraint physics)
!             → PH_XXX_Constraint_Impl       (L4_PH: hot path constraint enforcement)
!
! Principle #14 SIO compliance:
!   RT_XXX_Constraint_Apply uses the six-parameter form:
!     (Constraint_Desc, Constraint_State, Constraint_Algo, Constraint_Ctx, RT_Com_Ctx, args)
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified args TYPE
!   SIO-02 ✓  _Proc signature uses unified RT_XXX_Constraint_Args type with [IN]/[OUT] annotations
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields are routing scalars only
!   SIO-14 ✓  [IN] fields contain no ALLOCATABLE
!===============================================================================
MODULE RT_XXX_Constraint_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Constraint descriptor & base types
  USE MD_Constraint_XXX, ONLY: MD_Constraint_XXX_Desc, &
                               MD_Constraint_XXX_InitFromProps
  USE MD_Constraint_Types, ONLY: MD_Constraint_Base_Desc
  !-- [PH] Constraint physics entry point
  USE PH_XXX_Constraint, ONLY: PH_XXX_Constraint_API
  USE PH_Constraint_Types, ONLY: PH_Constraint_Base_Ctx, &
                                PH_Constraint_Base_State
  !-- [RT] Runtime types
  !   Do NOT borrow LoadBC quartet types here. New constraint runtime families
  !   should define dedicated RT_Constraint_* types / support bridges.
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  USE RT_Constraint_Def, ONLY: RT_Constraint_Desc, &
                               RT_Constraint_State, &
                               RT_Constraint_Algo, &
                               RT_Constraint_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Constraint_Args  ! SIO: unified IO bundle with [IN]/[OUT] annotations
  PUBLIC :: RT_XXX_Constraint_Apply ! Main entry: per-constraint call → PH_XXX_Constraint_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant
  ! Unified bundle with [IN]/[OUT] annotations in comments
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Constraint_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: constraint_id     = 0_i4    ! [IN] Constraint entity ID
    INTEGER(i4) :: constraint_type_id = 0_i4  ! [IN] Constraint type flag
    INTEGER(i4) :: master_node      = 0_i4    ! [IN] Master node ID
    INTEGER(i4), POINTER :: slave_nodes(:) => NULL() ! [IN] Slave node IDs
    REAL(wp), POINTER    :: coeffs(:) => NULL()      ! [IN] Constraint coefficients
    REAL(wp)            :: penalty       = 0.0_wp  ! [IN] Penalty factor
    LOGICAL             :: compute      = .TRUE.  ! [IN] .TRUE. if constraint needed
    LOGICAL             :: first_inc    = .FALSE. ! [IN] .TRUE. on first increment

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status        ! [OUT] Structured status; check %status_code
    LOGICAL               :: success = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: constraint_force = 0.0_wp ! [OUT] Constraint force magnitude
    REAL(wp), POINTER     :: K_constraint(:,:) => NULL() ! [OUT] Constraint stiffness matrix
    INTEGER(i4)           :: node_failed = 0_i4  ! [OUT] First node that caused error
  END TYPE RT_XXX_Constraint_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Constraint_Apply
  !>
  !> ROLE: L5_RT driver-level constraint enforce call.
  !>   Called once per increment by the step driver for each active constraint.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   constraint enforcement to PH_XXX_Constraint_API.
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Constraint_Apply(Constraint_Desc, Constraint_State, Constraint_Algo, &
                                      Constraint_Ctx, RT_Com_Ctx, args)
    TYPE(RT_Constraint_Desc),   INTENT(IN)    :: Constraint_Desc   ! Constraint config
    TYPE(RT_Constraint_State),  INTENT(INOUT) :: Constraint_State  ! Runtime state
    TYPE(RT_Constraint_Algo),   INTENT(IN)    :: Constraint_Algo  ! Algorithm config
    TYPE(RT_Constraint_Ctx),   INTENT(INOUT) :: Constraint_Ctx    ! Hot-path temporaries
    TYPE(RT_Com_Base_Ctx),     INTENT(IN)    :: RT_Com_Ctx         ! Increment bookkeeping
    TYPE(RT_XXX_Constraint_Args), INTENT(INOUT) :: args             ! Unified IO bundle

    !-- Local typed arguments for PH call
    TYPE(MD_Constraint_XXX_Desc)  :: MD_Constraint_Desc
    TYPE(PH_Constraint_Base_Ctx) :: PH_Constraint_Ctx
    TYPE(PH_Constraint_Base_State):: PH_Constraint_State

    !-- Locals
    TYPE(ErrorStatusType) :: constraint_status  ! Structured status returned by PH_XXX_Constraint_API

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success            = .FALSE.
    args%constraint_force   = 0.0_wp
    args%node_failed       = 0_i4

    !=========================================================================
    ! Step 1: Validate constraint ID and active flag
    !=========================================================================
    IF (args%constraint_id < 1 .OR. args%constraint_id > Constraint_Desc%n_constraints) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Constraint_Apply]: constraint_id out of range')
      RETURN
    END IF
    IF (.NOT. Constraint_Desc%constraint_active(args%constraint_id)) THEN
      args%success            = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_Constraint_XXX_Desc from constraint property data
    !=========================================================================
    MD_Constraint_Desc%constraint_id  = args%constraint_id
    MD_Constraint_Desc%constraint_type_id = args%constraint_type_id
    MD_Constraint_Desc%master_node   = args%master_node
    MD_Constraint_Desc%penalty        = args%penalty
    MD_Constraint_Desc%is_initialized = .TRUE.

    ! TODO: Copy slave_nodes and coeffs from inp (they are POINTERs, NOT OWNING)

    !=========================================================================
    ! Step 3: Build PH_Constraint_Base_Ctx — per-increment constraint inputs
    !=========================================================================
    PH_Constraint_Ctx%constraint_id = args%constraint_id
    PH_Constraint_Ctx%kstep         = RT_Com_Ctx%kstep
    PH_Constraint_Ctx%kinc          = RT_Com_Ctx%kinc
    PH_Constraint_Ctx%time_step     = RT_Com_Ctx%time_step
    PH_Constraint_Ctx%time_total    = RT_Com_Ctx%time_total

    !=========================================================================
    ! Step 4: Delegate to PH_XXX_Constraint_API (L4_PH)
    !=========================================================================
    CALL init_error_status(constraint_status)

    CALL PH_XXX_Constraint_API(MD_Constraint_Desc, PH_Constraint_Ctx, PH_Constraint_State, &
                               RT_Com_Ctx, constraint_status)

    !-- Check constraint-level error
    IF (constraint_status%status_code == IF_STATUS_ERROR) THEN
      args%status = constraint_status
      RETURN
    END IF

    !=========================================================================
    ! Step 5: Collect outputs
    !=========================================================================
    args%constraint_force = PH_Constraint_State%force_magnitude

    ! Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_XXX_Constraint_Apply

END MODULE RT_XXX_Constraint_Proc
