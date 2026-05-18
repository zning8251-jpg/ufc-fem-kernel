!===============================================================================
! Template: MD_Load_XXX.f90                                     [Template v1.0]
! Layer:  L3_MD - Model Description Layer
! Domain: Load / [Family] (e.g., DIST / CONC / FLUX / FILM / HETVAL / BODY)
!
! HOW TO USE:
!   1. Copy to L3_MD/Load/[Family]/
!   2. Rename: MD_Load_[Family]_[Type].f90  (e.g., MD_Load_DIST_Pressure.f90)
!   3. Replace XXX_XXX -> [Family]_[Type] throughout  (e.g., DIST_Pressure)
!   4. Replace XXX     -> [Type abbrev]               (e.g., DP)
!   5. Fill in: load_id constant, nprops_min, props layout, Desc fields
!   6. Implement: MD_XXX_Load_ValidateProps, MD_XXX_Load_InitFromProps
!   7. USE this module in PH_XXX_Load.f90 to obtain the concrete Desc type
!
! Naming Convention (layer prefix rule):
!   Module:        MD_Load_[Family]_[Type]       → MD_Load_DIST_Pressure
!   Desc type:     MD_XXX_Load_Desc             → MD_Load_DIST_Pressure_Desc
!   Validate:      MD_XXX_Load_ValidateProps     → MD_Load_DP_ValidateProps
!   Init:          MD_XXX_Load_InitFromProps     → MD_Load_DP_InitFromProps
!
! Props / nprops source:
!   For UFC-native: props from INP parser (*DLOAD/*DFLUX etc. sections).
!   For ABAQUS plug-in (DLOAD/VDLOAD/DFLUX): props(:) re-passed each call.
!   PH_XXX_Load_API forwards them here via MD_XXX_Load_InitFromProps.
!
! Design notes (v1.0):
!   - MD_XXX_Load_Desc EXTENDS MD_Load_Base_Desc (see MD_Load_Types.f90).
!   - Base class carries: load_id, load_family, load_name, is_initialized,
!                         magnitude, scale_factor, time_dependence,
!                         amplitude_id, load_type, element_face,
!                         node_id, dof_number, ambient_t, film_coeff.
!   - This Desc type is purely static; set ONCE at model load.
!   - Per-increment spatial/time data lives in PH_Load_Base_Ctx (L4_PH).
!   - Baseline refresh: comments now use IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*).
!===============================================================================
MODULE MD_Load_XXX
  USE IF_Prec_Core,      ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Load_Ids,  ONLY: LOAD_ID_XXX         ! ← replace with actual ID constant
  USE MD_Load_Types, ONLY: MD_Load_Base_Desc  ! ← L3_MD abstract base
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Load_Desc            ! L3_MD descriptor type
  PUBLIC :: MD_XXX_Load_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_XXX_Load_InitFromProps   ! Unpack props -> MD_XXX_Load_Desc

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NPROPS_MIN = 3_i4   ! ← set minimum required props
  !
  ! Props layout (document ALL slots for THIS load model):
  !   props(1) = load_family  : LOAD_FAMILY_XXX enum (1=DIST, 2=CONC, 3=FLUX …)
  !                             [integer as REAL]
  !   props(2) = magnitude    : Load magnitude [N, Pa, W/m², W/m³, …]
  !   props(3) = scale_factor : Load scaling factor [-] (default 1.0)
  !   props(4) = time_dependence : 0=constant, 1=user-fn, 2=tabular  [int as REAL]
  !   props(5) = amplitude_id    : Amplitude table reference (0=none)  [int as REAL]
  !   props(6) = load_param1  : Model-specific parameter [unit]
  !   ...
  ! NOTE: document every slot explicitly; follower-force flag should be
  !       a dedicated slot, not piggy-backed onto scale_factor.

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Load_Base_Desc, adds model-specific load parameters.
  !
  !   Base class provides:
  !     load_id, load_family, load_name, is_initialized,
  !     magnitude, scale_factor, time_dependence, amplitude_id,
  !     load_type, element_face, node_id, dof_number,
  !     ambient_t, film_coeff
  !
  !   Add HERE:  any parameters specific to this load that are NOT in base.
  !   Examples:
  !     DIST pressure (follower):  is_follower, follower_update_freq
  !     FLUX temperature-dep.:     T_ref, q_slope (dq/dT), n_tabpoints
  !     FILM convection:           h_ref, h_slope, T_sink_ref
  !     HETVAL heat generation:    cmname, nstatv, rate_dep
  !     BODY centrifugal:          omega, rotation_axis(3), r_ref
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Load Model Name] load model.
  TYPE, PUBLIC, EXTENDS(MD_Load_Base_Desc) :: MD_XXX_Load_Desc
    !-- Model-specific load parameters (replace with actual fields)
    !   For uniform distributed pressure:   (no extra fields; magnitude in base)
    !   For follower-force (nlgeom):
    !     LOGICAL :: is_follower = .FALSE.
    !   For temperature-dependent flux:
    !     REAL(wp) :: T_ref   = 293.15_wp   ! Reference temperature [K]
    !     REAL(wp) :: q_slope = 0.0_wp      ! dq/dT sensitivity  [W/(m²·K)]
    !   For tabular amplitude:
    !     INTEGER(i4) :: n_amp_points = 0_i4
    !     REAL(wp)    :: amp_time(100)  = 0.0_wp
    !     REAL(wp)    :: amp_value(100) = 0.0_wp
    REAL(wp) :: load_param1 = 0.0_wp   ! Placeholder — rename to actual parameter
    REAL(wp) :: load_param2 = 0.0_wp   ! Placeholder — rename to actual parameter

    !-- Derived / pre-computed constants (populated in InitFromProps for speed)
    !   e.g., effective_magnitude = magnitude * scale_factor
    REAL(wp) :: effective_magnitude = 0.0_wp   ! Cached magnitude * scale

  CONTAINS
    PROCEDURE :: ValidateProps => MD_XXX_Load_ValidateProps_TBP
    PROCEDURE :: InitFromProps => MD_XXX_Load_InitFromProps_TBP
  END TYPE MD_XXX_Load_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Load_ValidateProps
  !>   Validates the flat props array for [Load Model Name].
  !>   Called by MD_XXX_Load_InitFromProps before populating Desc.
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   nprops  - number of load constants (from INP or plug-in)
  !>   props   - load constant array
  !>   st      - structured status object OUT (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Load_ValidateProps(nprops, props, st)
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)

    ! ── Minimum count check ─────────────────────────────────────────────────
    IF (nprops < NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Load]: need >= NPROPS_MIN props"
      RETURN
    END IF

    ! ── Per-slot physical constraints ────────────────────────────────────────
    ! load_family (props(1)): must be valid LOAD_FAMILY_XXX
    IF (NINT(props(1)) < 1 .OR. NINT(props(1)) > 8) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Load]: props(1) load_family out of range [1,8]"
      RETURN
    END IF

    ! scale_factor (props(3)): positive non-zero
    IF (nprops >= 3) THEN
      IF (ABS(props(3)) < 1.0e-30_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Load]: props(3) scale_factor must be non-zero"
        RETURN
      END IF
    END IF

    ! ── TODO: add constraints for load-family-specific slots ─────────────────
    ! Example for follower pressure (props(6) = follower flag 0/1):
    ! IF (nprops >= 6 .AND. (NINT(props(6)) < 0 .OR. NINT(props(6)) > 1)) THEN
    !   st%status_code = IF_STATUS_INVALID
    !   st%message = "[XXX_Load]: props(6) follower flag must be 0 or 1"
    !   RETURN
    ! END IF

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Load_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_Load_InitFromProps
  !>   Unpacks flat props array into MD_XXX_Load_Desc.
  !>   Calls MD_XXX_Load_ValidateProps first; on success sets is_initialized=.TRUE.
  !>
  !>   TWO calling paths:
  !>
  !>   Path A — UFC model initialization  [PRIMARY, called ONCE at model load]
  !>     INP parser reads *DLOAD/*DFLUX section; this is called once.
  !>     UFC solvers retrieve Desc by load index on every compute call.
  !>
  !>   Path B — ABAQUS DLOAD/VDLOAD/DFLUX plug-in  [SECONDARY, per increment]
  !>     ABAQUS re-passes props(:) on every user-subroutine call.
  !>     PH_XXX_Load_API forwards them here to rebuild Desc each time.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Load_InitFromProps(desc, nprops, props, st)
    TYPE(MD_XXX_Load_Desc), INTENT(OUT) :: desc
    INTEGER(i4),            INTENT(IN)  :: nprops
    REAL(wp),               INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL MD_XXX_Load_ValidateProps(nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Mandatory slots: unpack into base fields
    desc%load_family     = NINT(props(1))  ! props(1): LOAD_FAMILY_XXX enum
    desc%magnitude       = props(2)        ! props(2): load magnitude [unit]
    IF (nprops >= 3) desc%scale_factor = props(3)  ! props(3): scale factor [-]

    !-- Optional slots
    IF (nprops >= 4) desc%time_dependence = NINT(props(4))  ! 0/1/2
    IF (nprops >= 5) desc%amplitude_id    = NINT(props(5))  ! 0=none

    !-- Model-specific parameters
    !   Replace with actual slot unpacking, e.g.:
    !     desc%load_param1 = props(6)   ! e.g., follower flag (0.0/1.0)
    !     desc%load_param2 = props(7)   ! e.g., reference radius [m]
    desc%load_param1 = 0.0_wp   ! ← replace with real props slot
    desc%load_param2 = 0.0_wp   ! ← replace with real props slot

    !-- Pre-computed derived constants (avoid hot-path multiplication cost)
    desc%effective_magnitude = desc%magnitude * desc%scale_factor

    !-- Identification (always set last)
    desc%load_id         = LOAD_ID_XXX
    desc%is_initialized  = .TRUE.
    st%status_code       = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Load_InitFromProps

  !-----------------------------------------------------------------------------
  ! Type-bound procedure wrappers (PRIVATE)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Load_ValidateProps_TBP(self, nprops, props, st)
    CLASS(MD_XXX_Load_Desc), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),                INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st
    ASSOCIATE(unused => self); END ASSOCIATE
    CALL MD_XXX_Load_ValidateProps(nprops, props, st)
  END SUBROUTINE MD_XXX_Load_ValidateProps_TBP

  SUBROUTINE MD_XXX_Load_InitFromProps_TBP(self, nprops, props, st)
    CLASS(MD_XXX_Load_Desc), INTENT(INOUT) :: self
    INTEGER(i4),             INTENT(IN)    :: nprops
    REAL(wp),                INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),   INTENT(OUT)   :: st
    TYPE(MD_XXX_Load_Desc) :: tmp
    CALL MD_XXX_Load_InitFromProps(tmp, nprops, props, st)
    IF (st%status_code == IF_STATUS_OK) THEN
      SELECT TYPE (self)
      TYPE IS (MD_XXX_Load_Desc)
        self = tmp
      END SELECT
    END IF
  END SUBROUTINE MD_XXX_Load_InitFromProps_TBP

END MODULE MD_Load_XXX

!===============================================================================
! STRUCT REFERENCE CARD — MD Layer Load Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name             Notes
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) ────────────────────────────────────────────────────────
!
!  MD  Load  Desc  MD_Load_Base_Desc    Base: load_id, load_family, load_name,
!                                       magnitude, scale_factor, time_dependence,
!                                       amplitude_id, load_type, element_face,
!                                       node_id, dof_number, ambient_t,
!                                       film_coeff, is_initialized
!
!  MD  Load  Desc  MD_XXX_Load_Desc    EXTENDS base; model-specific params:
!                                       load_param1, load_param2,
!                                       effective_magnitude (cached)
!
!  MD  Load  State MD_Load_Base_State  accumulated, last_magnitude, work_done,
!                                       converged, iterations, status
!
!  MD  Load  Algo  MD_Load_Base_Algo   apply_mode (1=direct, 2=scaled, 3=time),
!                                       use_ramp, ramp_duration, is_follower,
!                                       print_debug
!
! ── PH layer (L4_PH) ────────────────────────────────────────────────────────
!
!  PH  Load  State PH_Mat_XXX_Load_State  EXTENDS MD_Load_Base_State; ISVs
!
!  PH  Load  Ctx   PH_Load_Base_Ctx       coords(3), time_current, time_total,
!                                          elem_id, integ_pt_id, node_id, face_id,
!                                          jltyp
!
!  PH  Load  Algo  PH_Load_Base_Algo      max_iter, tolerance, pnewdt_min/max
!
! ── RT layer (L5_RT) ────────────────────────────────────────────────────────
!
!  RT  Com   Ctx   RT_Com_Base_Ctx        time_step, time_total, kstep, kinc,
!                                          first_increment, nlgeom, dtime
!
! ─────────────────────────────────────────────────────────────────────────────
! Props layout (fill in for concrete model):
!   props(1) = load_family  : LOAD_FAMILY_XXX enum           [int as REAL]
!   props(2) = magnitude    : load magnitude [N, Pa, W/m², …]
!   props(3) = scale_factor : multiplicative scale [-]        (default 1.0)
!   props(4) = time_dependence : 0=const, 1=user-fn, 2=table [int as REAL]
!   props(5) = amplitude_id : amplitude table ref (0=none)   [int as REAL]
!   props(6) = load_param1  : model-specific                 [unit]
!   props(7) = load_param2  : model-specific                 [unit]
!   ...
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================
