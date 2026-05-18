!===============================================================================
! Template: MD_XXX_Contact.f90                                  [Template v1.1]
! Layer:  L3_MD - Model Description Layer
! Domain: Contact / [Family] (e.g., FULL / FRIC / COUL / GAP / GAPCON)
!
! HOW TO USE:
!   1. Copy to L3_MD/Contact/[Family]/
!   2. Rename: MD_Contact_[Family]_[Type].f90  (e.g., MD_Contact_COUL_Linear.f90)
!   3. Replace XXX_XXX -> [Family]_[Type] throughout  (e.g., COUL_Linear)
!   4. Replace XXX     -> [Type abbrev]               (e.g., CL)
!   5. Fill in: contact_id constant, nprops_min, props layout, Desc fields
!   6. Implement: MD_XXX_Contact_ValidateProps, MD_XXX_Contact_InitFromProps
!   7. USE this module in PH_XXX_Contact.f90 to obtain the concrete Desc type
!
! Naming Convention (layer prefix rule):
!   Module:        MD_Contact_[Family]_[Type]         → MD_Contact_COUL_Linear
!   Desc type:     MD_XXX_Contact_Desc               → MD_Contact_COUL_Linear_Desc
!   Validate:      MD_XXX_Contact_ValidateProps       → MD_Contact_CL_ValidateProps
!   Init:          MD_XXX_Contact_InitFromProps       → MD_Contact_CL_InitFromProps
!
! Props / nprops source:
!   For UFC-native: props from INP parser (*SURFACE INTERACTION section).
!   For ABAQUS UINTER/UFRIC/UCOUL/GAPCON plug-in:
!     props(:) re-passed each call; PH_XXX_Contact_API forwards here.
!
! Desc / TBP (v1.1):
!   Do not add *_TBP routines that only forward to module procedures. Bind
!   ValidateProps / InitFromProps directly; first dummy is CLASS(MD_XXX_Contact_Desc).
!
! Design notes (v1.0):
!   - MD_XXX_Contact_Desc EXTENDS MD_Contact_Base_Desc (MD_Contact_Types.f90).
!   - Base class carries: contact_id, contact_family, contact_name,
!                         is_initialized, master/slave_surface,
!                         normal_behavior, normal_stiffness,
!                         fric_law, fric_coeff, shear_limit,
!                         contact_threshold, max_iter.
!   - This Desc type is purely static; set ONCE at model load.
!   - Per-increment gap/slip/pressure lives in PH_Contact_Base_Ctx (L4_PH).
!   - Baseline refresh: comments now use IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*).
!===============================================================================
MODULE MD_Contact_XXX
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Contact_Ids,   ONLY: CONTACT_ID_XXX         ! ← replace with actual ID
  USE MD_Contact_Types, ONLY: MD_Contact_Base_Desc   ! ← L3_MD abstract base
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_Contact_Desc            ! L3_MD descriptor type
  PUBLIC :: MD_XXX_Contact_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_XXX_Contact_InitFromProps   ! Unpack props -> MD_XXX_Contact_Desc

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NPROPS_MIN = 4_i4   ! ← set minimum required props
  !
  ! Props layout (document ALL slots for THIS contact model):
  !   props(1) = contact_family  : CONTACT_FAMILY_XXX enum
  !                                1=FULL, 2=FRIC, 3=COUL, 4=GAP, 5=GAPELEC
  !                                [integer as REAL]
  !   props(2) = normal_behavior : 1=hard, 2=penalty, 3=exponential
  !                                [integer as REAL]
  !   props(3) = normal_stiffness: Penalty stiffness k_n [N/m³]  (for type=2,3)
  !   props(4) = fric_law        : 1=Coulomb, 2=shear-limit, 3=user
  !                                [integer as REAL]
  !   props(5) = fric_coeff      : Coulomb friction coefficient mu [-]
  !   props(6) = shear_limit     : Critical shear stress [Pa]  (for fric_law=2)
  !   props(7) = contact_threshold: Gap tolerance for exponential contact [m]
  !   props(8) = contact_param1  : Model-specific parameter [unit]
  !   ...
  ! NOTE: document every slot. Hard-contact (normal_behavior=1) ignores k_n.

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Contact_Base_Desc, adds model-specific parameters.
  !
  !   Base class provides:
  !     contact_id, contact_family, contact_name, is_initialized,
  !     master_surface, slave_surface,
  !     normal_behavior, normal_stiffness,
  !     fric_law, fric_coeff, shear_limit,
  !     contact_threshold, max_iter
  !
  !   Add HERE:  any parameters specific to this contact that are NOT in base.
  !   Examples:
  !     GAPCON thermal:       k_cond_ref, gap_crit, pres_depend, temp_depend
  !     Anisotropic friction: mu_1, mu_2, slip_dir_1(3)
  !     Rate-dependent fric:  mu_static, mu_kinetic, slip_rate_ref, decay_coeff
  !     Wear (Archard):       k_wear, hardness_ref
  !     Exponential contact:  p_ref, gap_ref, exponent_n
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Contact Model Name] contact model.
  TYPE, PUBLIC, EXTENDS(MD_Contact_Base_Desc) :: MD_XXX_Contact_Desc
    !-- Model-specific contact parameters (replace with actual fields)
    !   For basic Coulomb:              (no extra fields; fric_coeff in base)
    !   For rate-dependent friction:
    !     REAL(wp) :: mu_static   = 0.0_wp  ! Static friction coefficient [-]
    !     REAL(wp) :: mu_kinetic  = 0.0_wp  ! Kinetic friction coefficient [-]
    !     REAL(wp) :: slip_rate_ref = 1.0e-3_wp  ! Reference slip rate [m/s]
    !     REAL(wp) :: decay_coeff = 1.0_wp  ! Exponential decay coefficient [-]
    !   For Archard wear:
    !     REAL(wp) :: k_wear      = 0.0_wp  ! Wear coefficient [m²/N]
    !     REAL(wp) :: hardness_ref = 1.0_wp ! Reference hardness [Pa]
    REAL(wp) :: contact_param1 = 0.0_wp   ! Placeholder — rename to actual
    REAL(wp) :: contact_param2 = 0.0_wp   ! Placeholder — rename to actual

    !-- Derived / pre-computed constants (populated in InitFromProps for speed)
    !   e.g., for exponential contact:  exp_factor = normal_stiffness / gap_ref
    REAL(wp) :: contact_derived1 = 0.0_wp  ! e.g., pre-computed stiffness ratio

  CONTAINS
    PROCEDURE :: ValidateProps => MD_XXX_Contact_ValidateProps
    PROCEDURE :: InitFromProps => MD_XXX_Contact_InitFromProps
  END TYPE MD_XXX_Contact_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_Contact_ValidateProps
  !>   Validates the flat props array for [Contact Model Name].
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   self    - pass-object (unused in template checks; use for model dispatch)
  !>   nprops  - number of contact constants (from INP or plug-in)
  !>   props   - contact constant array
  !>   st      - structured status object OUT (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Contact_ValidateProps(self, nprops, props, st)
    CLASS(MD_XXX_Contact_Desc), INTENT(IN)  :: self
    INTEGER(i4),                INTENT(IN)  :: nprops
    REAL(wp),                   INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT) :: st

    CALL init_error_status(st)
    ASSOCIATE(unused => self); END ASSOCIATE  ! pass-object; extend checks to use self if needed

    ! ── Minimum count check ─────────────────────────────────────────────────
    IF (nprops < NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Contact]: need >= NPROPS_MIN props"
      RETURN
    END IF

    ! ── Per-slot physical constraints ────────────────────────────────────────
    ! contact_family (props(1)): 1..5
    IF (NINT(props(1)) < 1 .OR. NINT(props(1)) > 5) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Contact]: props(1) contact_family out of range [1,5]"
      RETURN
    END IF

    ! normal_behavior (props(2)): 1=hard, 2=penalty, 3=exponential
    IF (NINT(props(2)) < 1 .OR. NINT(props(2)) > 3) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Contact]: props(2) normal_behavior must be 1, 2, or 3"
      RETURN
    END IF

    ! normal_stiffness (props(3)): >= 0 (0 is OK for hard contact)
    IF (props(3) < 0.0_wp) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Contact]: props(3) normal_stiffness must be >= 0"
      RETURN
    END IF

    ! fric_law (props(4)): 1=Coulomb, 2=shear-limit, 3=user
    IF (NINT(props(4)) < 1 .OR. NINT(props(4)) > 3) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_Contact]: props(4) fric_law must be 1, 2, or 3"
      RETURN
    END IF

    ! fric_coeff (props(5)): >= 0 when law = Coulomb
    IF (nprops >= 5) THEN
      IF (NINT(props(4)) == 1 .AND. props(5) < 0.0_wp) THEN
        st%status_code = IF_STATUS_INVALID
        st%message = "[XXX_Contact]: props(5) fric_coeff must be >= 0 for Coulomb law"
        RETURN
      END IF
    END IF

    ! ── TODO: add constraints for model-specific slots ────────────────────────

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Contact_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_Contact_InitFromProps
  !>   Unpacks flat props array into self (in-place).
  !>   Calls MD_XXX_Contact_ValidateProps first; on success sets is_initialized.
  !>
  !>   TWO calling paths:
  !>
  !>   Path A — UFC model initialization  [PRIMARY, called ONCE at model load]
  !>     INP parser reads *SURFACE INTERACTION section; Desc built once.
  !>     UFC solvers retrieve Desc by contact_id on every contact call.
  !>
  !>   Path B — ABAQUS UINTER/UFRIC/UCOUL/GAPCON plug-in  [per increment]
  !>     ABAQUS re-passes props(:) on every call.
  !>     PH_XXX_Contact_API forwards them here to rebuild Desc each time.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_Contact_InitFromProps(self, nprops, props, st)
    CLASS(MD_XXX_Contact_Desc), INTENT(INOUT) :: self
    INTEGER(i4),                INTENT(IN)    :: nprops
    REAL(wp),                   INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType),      INTENT(OUT)   :: st

    CALL MD_XXX_Contact_ValidateProps(self, nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Mandatory slots: unpack into base fields
    self%contact_family   = NINT(props(1))  ! props(1): CONTACT_FAMILY_XXX enum
    self%normal_behavior  = NINT(props(2))  ! props(2): 1=hard/2=penalty/3=exp
    self%normal_stiffness = props(3)        ! props(3): k_n [N/m³]
    self%fric_law         = NINT(props(4))  ! props(4): 1=Coulomb/2=shear/3=user

    !-- Optional standard slots
    IF (nprops >= 5) self%fric_coeff        = props(5)  ! Coulomb mu [-]
    IF (nprops >= 6) self%shear_limit       = props(6)  ! Critical shear [Pa]
    IF (nprops >= 7) self%contact_threshold = props(7)  ! Gap tolerance [m]

    !-- Model-specific parameters
    !   Replace with actual slot unpacking, e.g.:
    !     self%contact_param1 = props(8)   ! e.g., wear coefficient k_w [m²/N]
    !     self%contact_param2 = props(9)   ! e.g., hardness [Pa]
    self%contact_param1 = 0.0_wp   ! ← replace with real props slot
    self%contact_param2 = 0.0_wp   ! ← replace with real props slot

    !-- Pre-computed derived constants (avoid hot-path cost)
    !   e.g., for exponential contact:
    !     self%contact_derived1 = self%normal_stiffness &
    !                           / MAX(self%contact_threshold, 1.0e-30_wp)
    self%contact_derived1 = 0.0_wp   ! ← replace with real derived expression

    !-- Identification (always set last)
    self%contact_id     = CONTACT_ID_XXX
    self%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Contact_InitFromProps

END MODULE MD_Contact_XXX

!===============================================================================
! STRUCT REFERENCE CARD — MD Layer Contact Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain   Role   Type name                Notes
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) ────────────────────────────────────────────────────────
!
!  MD  Contact  Desc  MD_Contact_Base_Desc   Base: contact_id, contact_family,
!                                             contact_name, is_initialized,
!                                             master/slave_surface,
!                                             normal_behavior, normal_stiffness,
!                                             fric_law, fric_coeff, shear_limit,
!                                             contact_threshold, max_iter
!
!  MD  Contact  Desc  MD_XXX_Contact_Desc    EXTENDS base; model-specific:
!                                             contact_param1, contact_param2,
!                                             contact_derived1 (cached)
!
!  MD  Contact  State MD_Contact_Base_State  gap_history, slip_accumulated,
!                                             pressure_cumulative,
!                                             energy_dissipated,
!                                             converged, iterations, status
!
!  MD  Contact  Algo  MD_Contact_Base_Algo   algorithm (1=penalty/2=Lagrange/
!                                             3=aug-Lagrange), use_stabilization,
!                                             stabilization_factor, print_debug
!
! ── PH layer (L4_PH) ────────────────────────────────────────────────────────
!
!  PH  Contact  State PH_XXX_Contact_State   EXTENDS MD_Contact_Base_State;
!                                             adds wear_accumulated, ISVs
!
!  PH  Contact  Ctx   PH_Contact_Base_Ctx    gap, slip1, slip2, pressure, temp,
!                                             coords, elem_id, integ_pt_id
!
!  PH  Contact  Algo  PH_Contact_Base_Algo   max_iter, tolerance,
!                                             pnewdt_min/max, use_stabilization
!
! ── RT layer (L5_RT) ────────────────────────────────────────────────────────
!
!  RT  Com  Ctx  RT_Com_Base_Ctx             time_step, time_total, kstep, kinc,
!                                             first_increment, nlgeom
!
! ─────────────────────────────────────────────────────────────────────────────
! Props layout (fill in for concrete model):
!   props(1) = contact_family  : CONTACT_FAMILY_XXX enum       [int as REAL]
!   props(2) = normal_behavior : 1=hard, 2=penalty, 3=exp      [int as REAL]
!   props(3) = normal_stiffness: k_n [N/m³]
!   props(4) = fric_law        : 1=Coulomb, 2=shear, 3=user    [int as REAL]
!   props(5) = fric_coeff      : Coulomb mu [-]
!   props(6) = shear_limit     : Critical shear [Pa]
!   props(7) = contact_threshold: gap tolerance [m]
!   props(8) = contact_param1  : model-specific                [unit]
!   props(9) = contact_param2  : model-specific                [unit]
!   ...
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================
