!===============================================================================
! Template: RT_XXX_Load_Proc.f90                               [Template v1.1]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Load / [Family] (e.g., MECH / THERM / HYDRO / ELEC / ...)
!
! HOW TO USE:
!   1. Copy to L5_RT/Load/[Family]/
!   2. Rename: RT_Load_[LoadType]_Proc.f90
!              (e.g., RT_Load_Pressure_Proc.f90)
!   3. Replace XXX_XXX -> [LoadFamily]_[LoadType]
!   4. Replace XXX -> [LoadType abbrev]
!   5. Wire up USE statements to the matching MD_Load_XXX, PH_XXX_Load modules
!   6. Implement RT_XXX_Load_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Load_Apply    (THIS FILE, family facade)
!             → RT_Load_Brg / RT_Load_Impl family
!             → PH_XXX_Load_API       (L4_PH: load physics, PH_XXX_Load_Args inside)
!             → PH_XXX_Load_Impl      (L4_PH: hot path load computation)
!
! Principle #14 SIO compliance:
!   RT_XXX_Load_Apply uses the six-parameter form:
!     (Load_Desc, Load_State, Load_Algo, Load_Ctx, RT_Com_Ctx, args)
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified RT_XXX_Load_Args bundle
!   SIO-02 ✓  _Proc signature uses unified RT_XXX_Load_Args type with [IN]/[OUT] annotations
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields are routing scalars only
!   SIO-14 ✓  [IN] fields contain no ALLOCATABLE
!===============================================================================
MODULE RT_XXX_Load_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Load descriptor & base types
  USE MD_Load_XXX,  ONLY: MD_Load_XXX_Desc, &
                         MD_Load_XXX_InitFromProps
  USE MD_Load_Types,ONLY: MD_Load_Base_Desc
  !-- [PH] Load physics entry point
  USE PH_XXX_Load,  ONLY: PH_XXX_Load_API
  USE PH_Load_Types,ONLY: PH_Load_Base_Ctx, &
                         PH_Load_Base_State
  !-- [RT] Runtime types
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx
  USE RT_Load_Impl_Def, ONLY: RT_Load_Impl_Desc, &
                              RT_Load_Impl_State, &
                              RT_Load_Impl_Algo, &
                              RT_Load_Impl_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Load_Args    ! SIO: unified IO bundle with [IN]/[OUT] annotations
  PUBLIC :: RT_XXX_Load_Apply  ! Main entry: per-load call → PH_XXX_Load_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant
  ! Unified bundle with [IN]/[OUT] annotations in comments
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Load_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: load_id         = 0_i4    ! [IN] Load entity ID
    INTEGER(i4) :: load_type_id    = 0_i4    ! [IN] Load type flag
    INTEGER(i4) :: amplitude_id    = 0_i4    ! [IN] Amplitude definition ID
    REAL(wp)    :: load_magnitude  = 0.0_wp ! [IN] Nominal load magnitude
    REAL(wp)    :: time_value      = 0.0_wp ! [IN] Current time for amplitude eval
    LOGICAL     :: compute_load    = .TRUE.  ! [IN] .TRUE. if load needed
    LOGICAL     :: first_inc       = .FALSE. ! [IN] .TRUE. on first increment

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status         ! [OUT] Structured status; check %status_code
    LOGICAL               :: success = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: load_mag = 0.0_wp  ! [OUT] Applied load magnitude
    REAL(wp), POINTER     :: f_ext(:) => NULL() ! [OUT] External force vector
    INTEGER(i4)           :: node_failed = 0_i4  ! [OUT] First node that caused error
  END TYPE RT_XXX_Load_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Load_Apply
  !>
  !> ROLE: L5_RT driver-level load compute call.
  !>   Called once per increment by the step driver for each active load.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   load vector computation to PH_XXX_Load_API.
  !>
  !> Calling pattern (step driver side):
!>   TYPE(RT_Load_Impl_Desc)   :: Load_Desc
!>   TYPE(RT_Load_Impl_State)  :: Load_State
!>   TYPE(RT_Load_Impl_Algo)   :: Load_Algo
!>   TYPE(RT_Load_Impl_Ctx)    :: Load_Ctx
  !>   TYPE(RT_Com_Base_Ctx)     :: RT_Com_Ctx
  !>   TYPE(RT_XXX_Load_Args)     :: args
  !>   args%load_id              = current_load
  !>   args%load_type_id         = load_type
  !>   args%load_magnitude       = magnitude
  !>   CALL RT_XXX_Load_Apply(Load_Desc, Load_State, Load_Algo, Load_Ctx,
  !>                         RT_Com_Ctx, args)
  !>   IF (args%status%status_code /= IF_STATUS_OK) ... error handling ...
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Load_Apply(Load_Desc, Load_State, Load_Algo, Load_Ctx, &
                               RT_Com_Ctx, args)
    TYPE(RT_Load_Impl_Desc),  INTENT(IN)    :: Load_Desc   ! Load config (cold)
    TYPE(RT_Load_Impl_State), INTENT(INOUT) :: Load_State  ! Runtime state (warm)
    TYPE(RT_Load_Impl_Algo),  INTENT(IN)    :: Load_Algo   ! Algorithm config
    TYPE(RT_Load_Impl_Ctx),   INTENT(INOUT) :: Load_Ctx    ! Hot-path temporaries
    TYPE(RT_Com_Base_Ctx),  INTENT(IN)    :: RT_Com_Ctx   ! Increment bookkeeping
    TYPE(RT_XXX_Load_Args),  INTENT(INOUT) :: args        ! Unified IO bundle

    !-- Local typed arguments for PH call
    TYPE(MD_Load_XXX_Desc)  :: MD_Load_Desc    ! Concrete Desc for this load type
    TYPE(PH_Load_Base_Ctx)  :: PH_Load_Ctx     ! PH-owned per-increment context
    TYPE(PH_Load_Base_State):: PH_Load_State  ! PH-owned load state

    !-- Locals
    TYPE(ErrorStatusType) :: load_status     ! Structured status returned by PH_XXX_Load_API

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success      = .FALSE.
    args%load_mag     = 0.0_wp
    args%node_failed  = 0_i4

    !=========================================================================
    ! Step 1: Validate load ID and active flag
    !=========================================================================
    IF (args%load_id < 1 .OR. args%load_id > Load_Desc%n_loads) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Load_Apply]: load_id out of range')
      RETURN
    END IF
    IF (.NOT. Load_Desc%is_active) THEN
      args%success            = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_Load_XXX_Desc from load property data
    !=========================================================================
    MD_Load_Desc%load_id       = args%load_id
    MD_Load_Desc%load_type_id = args%load_type_id
    MD_Load_Desc%magnitude    = args%load_magnitude
    MD_Load_Desc%amplitude_id = args%amplitude_id
    MD_Load_Desc%is_initialized = .TRUE.

    !=========================================================================
    ! Step 3: Build PH_Load_Base_Ctx — per-increment load driving inputs
    !=========================================================================
    PH_Load_Ctx%load_id     = args%load_id
    PH_Load_Ctx%kstep       = RT_Com_Ctx%kstep
    PH_Load_Ctx%kinc        = RT_Com_Ctx%kinc
    PH_Load_Ctx%time_step   = RT_Com_Ctx%time_step
    PH_Load_Ctx%time_total  = RT_Com_Ctx%time_total

    !=========================================================================
    ! Step 4: Evaluate amplitude if present
    !=========================================================================
    IF (args%amplitude_id > 0) THEN
      ! TODO: Call amplitude evaluation routine
      ! MD_Load_Desc%magnitude = MD_Load_Desc%magnitude * amp_value
    END IF

    !=========================================================================
    ! Step 5: Delegate to PH_XXX_Load_API (L4_PH)
    !=========================================================================
    CALL init_error_status(load_status)

    CALL PH_XXX_Load_API(MD_Load_Desc, PH_Load_Ctx, PH_Load_State, &
                         RT_Com_Ctx, load_status)

    !-- Check load-level error
    IF (load_status%status_code == IF_STATUS_ERROR) THEN
      args%status = load_status
      RETURN
    END IF

    !=========================================================================
    ! Step 6: Collect outputs
    !=========================================================================
    args%load_mag = MD_Load_Desc%magnitude

    ! Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_XXX_Load_Apply

END MODULE RT_XXX_Load_Proc
