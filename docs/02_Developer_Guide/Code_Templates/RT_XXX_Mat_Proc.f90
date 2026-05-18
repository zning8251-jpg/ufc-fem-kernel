!===============================================================================
! Template: RT_XXX_Mat_Proc.f90                                [Template v1.1]
! Layer:  L5_RT - Runtime Execution Layer
! Domain: Material / [Family] (e.g., ELA / PLM / HYP / DMG / CMP / ...)
!
! HOW TO USE:
!   1. Copy to L5_RT/Material/[Family]/
!   2. Rename: RT_Mat_[MatType]_Proc.f90
!              (e.g., RT_Mat_J2Plasticity_Proc.f90)
!   3. Replace XXX_XXX -> [MatFamily]_[MatType]
!   4. Replace XXX -> [MatType abbrev]
!   5. Wire up USE statements to the matching MD_Mat_XXX, PH_XXX_Mat modules
!   6. Implement RT_XXX_Mat_Apply — the single entry called by the step driver
!
! Role in UFC Call Chain:
!   StepDriver → RT_XXX_Mat_Apply    (THIS FILE, family facade)
!             → RT_Mat dispatch/support family
!             → PH_XXX_Mat_API       (L4_PH: material physics, _In/_Out wrapper)
!             → PH_XXX_Mat_Impl      (L4_PH: hot path material constitutive update)
!
! Principle #14 SIO compliance:
!   RT_XXX_Mat_Apply uses the six-parameter form:
!     (Mat_Desc, Mat_State, Mat_Algo, Mat_Ctx, RT_Com_Ctx, args)
!
! SIO COMPLIANCE (Principle #14, SIO-01~14):
!   SIO-01 ✓  Six-parameter form + unified RT_XXX_Mat_Args bundle
!   SIO-02 ✓  _Proc signature uses unified RT_XXX_Mat_Args type with [IN]/[OUT] annotations
!   SIO-03 ✓  Unified TYPE carries structured status; init with
!             init_error_status(...) and inspect %status_code
!   SIO-07 ✓  No INTENT(...) inside TYPE bodies
!   SIO-13 ✓  [IN] fields are routing scalars / props pointer (no nested four-type members)
!   SIO-14 ✓  [IN] fields contain no ALLOCATABLE (POINTER to external pool allowed)
!===============================================================================
MODULE RT_XXX_Mat_Proc
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_ERROR
  !-- [MD] Material descriptor & base types
  USE MD_Mat_XXX,   ONLY: MD_Mat_XXX_Desc, &
                          MD_Mat_XXX_InitFromProps
  USE MD_Mat_Types, ONLY: MD_Mat_Base_Desc
  !-- [PH] Material physics entry point
  USE PH_XXX_Mat,   ONLY: PH_XXX_Mat_API, PH_XXX_Mat_State
  USE PH_Mat_Types, ONLY: PH_Mat_Base_Ctx, &
                         PH_Mat_Base_Algo
  !-- [RT] Runtime types
  !   Material runtime no longer borrows LoadBC quartet types. Replace the
  !   placeholder module below with the actual material runtime dispatch types
  !   for your family (e.g. RT_Mat_Def + family-specific runtime state).
  USE RT_Com_Types, ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  USE RT_Mat_Runtime_Def, ONLY: RT_Mat_Desc, &
                                RT_Mat_State, &
                                RT_Mat_Algo, &
                                RT_Mat_Ctx
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_XXX_Mat_Args    ! SIO: unified IO bundle with [IN]/[OUT] annotations
  PUBLIC :: RT_XXX_Mat_Apply  ! Main entry: per-material call → PH_XXX_Mat_API

  !-----------------------------------------------------------------------------
  ! RT-level IO TYPE — Principle #14 / SIO-compliant
  ! Unified bundle with [IN]/[OUT] annotations in comments
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_XXX_Mat_Args
    !-- [IN] Routing scalars
    INTEGER(i4) :: mat_id          = 0_i4    ! [IN] Material ID
    INTEGER(i4) :: mat_type_id     = 0_i4    ! [IN] Material type flag
    INTEGER(i4) :: section_id      = 0_i4    ! [IN] Section ID
    INTEGER(i4) :: n_ip            = 0_i4    ! [IN] Number of integration points
    REAL(wp), POINTER :: props(:) => NULL()   ! [IN] Material property array
    LOGICAL     :: compute_tangent = .TRUE.  ! [IN] .TRUE. if tangent stiffness needed
    LOGICAL     :: compute_stress  = .TRUE.  ! [IN] .TRUE. if stress update needed
    LOGICAL     :: first_inc       = .FALSE. ! [IN] .TRUE. on first increment

    !-- [OUT] Results
    TYPE(ErrorStatusType) :: status        ! [OUT] Structured status; check %status_code
    LOGICAL               :: success = .FALSE.  ! [OUT] .TRUE. on clean return
    REAL(wp)              :: pnewdt_min = RT_PNEWDT_NO_CHANGE  ! [OUT] Min pnewdt across IPs
    REAL(wp)              :: strain_energy = 0.0_wp ! [OUT] Strain energy
    REAL(wp)              :: plastic_energy = 0.0_wp ! [OUT] Plastic dissipation
    INTEGER(i4)           :: ip_failed = 0_i4  ! [OUT] First IP that caused error
  END TYPE RT_XXX_Mat_Args

CONTAINS

  !============================================================================
  !> RT_XXX_Mat_Apply
  !>
  !> ROLE: L5_RT driver-level material update call.
  !>   Called once per increment by the step driver for each material point.
  !>   Assembles all L3_MD / L4_PH / L5_RT typed arguments, then delegates
  !>   material constitutive update to PH_XXX_Mat_API.
  !>
  !> Calling pattern (step driver side):
  !>   TYPE(RT_Mat_Desc)        :: Mat_Desc
  !>   TYPE(RT_Mat_State)       :: Mat_State
  !>   TYPE(RT_Mat_Algo)        :: Mat_Algo
  !>   TYPE(RT_Mat_Ctx)         :: Mat_Ctx
  !>   TYPE(RT_Com_Base_Ctx)    :: RT_Com_Ctx
  !>   TYPE(RT_XXX_Mat_Args)     :: args
  !>   args%mat_id              = current_mat
  !>   args%props               => prop_array
  !>   CALL RT_XXX_Mat_Apply(Mat_Desc, Mat_State, Mat_Algo, Mat_Ctx, RT_Com_Ctx, args)
  !>   IF (args%status%status_code /= IF_STATUS_OK) ... error handling ...
  !============================================================================
  ! Phase: Compute | Apply | HOT_PATH
  SUBROUTINE RT_XXX_Mat_Apply(Mat_Desc, Mat_State, Mat_Algo, Mat_Ctx, &
                               RT_Com_Ctx, args)
    TYPE(RT_Mat_Desc),      INTENT(IN)     :: Mat_Desc    ! Material config (cold)
    TYPE(RT_Mat_State),     INTENT(INOUT)  :: Mat_State   ! Runtime state (warm)
    TYPE(RT_Mat_Algo),      INTENT(IN)     :: Mat_Algo    ! Algorithm config
    TYPE(RT_Mat_Ctx),      INTENT(INOUT)  :: Mat_Ctx     ! Hot-path temporaries
    TYPE(RT_Com_Base_Ctx),  INTENT(IN)     :: RT_Com_Ctx  ! Increment bookkeeping
    TYPE(RT_XXX_Mat_Args),   INTENT(INOUT)  :: args        ! Unified IO bundle

    !-- Local typed arguments for PH call
    TYPE(MD_Mat_XXX_Desc)  :: MD_Mat_Desc     ! Concrete Desc for this material
    TYPE(PH_Mat_Base_Ctx)  :: PH_Mat_Ctx      ! PH-owned per-increment context
    TYPE(PH_Mat_Base_Algo) :: PH_Mat_Algo    ! PH-owned algorithm parameters
    TYPE(PH_XXX_Mat_State) :: PH_Mat_State   ! PH-owned material state (svars)

    !-- Locals
    TYPE(ErrorStatusType) :: mat_status      ! Structured status returned by PH_XXX_Mat_API
    REAL(wp)              :: pnewdt          ! Per-material pnewdt feedback

    !-- Initialize outputs
    CALL init_error_status(args%status)
    args%success        = .FALSE.
    args%pnewdt_min     = RT_PNEWDT_NO_CHANGE
    args%strain_energy  = 0.0_wp
    args%plastic_energy = 0.0_wp
    args%ip_failed      = 0_i4

    !=========================================================================
    ! Step 1: Validate material ID and active flag
    !=========================================================================
    IF (args%mat_id < 1 .OR. args%mat_id > Mat_Desc%n_materials) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Mat_Apply]: mat_id out of range')
      RETURN
    END IF
    IF (.NOT. Mat_Desc%mat_active(args%mat_id)) THEN
      args%success            = .TRUE.
      args%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    !=========================================================================
    ! Step 2: Build MD_Mat_XXX_Desc from material property data
    !=========================================================================
    ! Initialize from PROPS array
    IF (ASSOCIATED(args%props)) THEN
      CALL MD_Mat_XXX_InitFromProps(MD_Mat_Desc, args%props, SIZE(args%props))
    ELSE
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[RT_XXX_Mat_Apply]: props not associated')
      RETURN
    END IF

    MD_Mat_Desc%mat_id         = args%mat_id
    MD_Mat_Desc%mat_type_id    = args%mat_type_id
    MD_Mat_Desc%section_id     = args%section_id
    MD_Mat_Desc%is_initialized = .TRUE.

    !=========================================================================
    ! Step 3: Build PH_Mat_Base_Ctx — per-increment material driving inputs
    !=========================================================================
    PH_Mat_Ctx%mat_id      = args%mat_id
    PH_Mat_Ctx%kstep       = RT_Com_Ctx%kstep
    PH_Mat_Ctx%kinc        = RT_Com_Ctx%kinc
    PH_Mat_Ctx%time_step   = RT_Com_Ctx%time_step
    PH_Mat_Ctx%time_total  = RT_Com_Ctx%time_total
    PH_Mat_Ctx%nlgeom      = RT_Com_Ctx%nlgeom

    !=========================================================================
    ! Step 4: Build PH_Mat_Base_Algo — material algorithm parameters
    !=========================================================================
    PH_Mat_Algo%compute_tangent = args%compute_tangent
    PH_Mat_Algo%compute_stress  = args%compute_stress

    !=========================================================================
    ! Step 5: Initialize pnewdt and delegate to PH_XXX_Mat_API (L4_PH)
    !=========================================================================
    pnewdt = RT_PNEWDT_NO_CHANGE
    CALL init_error_status(mat_status)

    CALL PH_XXX_Mat_API(MD_Mat_Desc, PH_Mat_State, MD_Mat_Desc%md_algo, &
                         PH_Mat_Algo, PH_Mat_Ctx, RT_Com_Ctx, pnewdt, mat_status)

    !-- Check material-level error
    IF (mat_status%status_code == IF_STATUS_ERROR) THEN
      args%status   = mat_status
      args%ip_failed = PH_Mat_Ctx%first_failed_ip
      RETURN
    END IF

    !=========================================================================
    ! Step 6: Collect outputs
    !=========================================================================
    IF (pnewdt < args%pnewdt_min) THEN
      args%pnewdt_min = pnewdt
    END IF
    args%strain_energy  = PH_Mat_State%energy(1)  ! Elastic strain energy
    args%plastic_energy = PH_Mat_State%energy(2)   ! Plastic dissipation

    ! Finalise
    args%success            = .TRUE.
    args%status%status_code = IF_STATUS_OK

  END SUBROUTINE RT_XXX_Mat_Apply

END MODULE RT_XXX_Mat_Proc
