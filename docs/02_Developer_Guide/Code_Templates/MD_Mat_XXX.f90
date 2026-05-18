!===============================================================================
! ★ L3_MD 材料模型标准范式模板                              [Template v3.2]
! Template: MD_Mat_XXX.f90
! Layer:  L3_MD - Model Description Layer
! Domain: Material / [Family] (e.g., ELA / PLG / DMG / HYP / CMP / ...)
!
! HOW TO USE:
!   1. Copy this file to L3_MD/Material/[Family]/
!   2. Rename: MD_Mat_[Family]_[Model].f90  (e.g., MD_Mat_PLG_MohrCoulomb.f90)
!   3. Replace XXX_XXX → [Family]_[Model]   (e.g., PLG_MohrCoulomb)
!   4. Replace XXX     → [Model abbrev]      (e.g., MC)
!   5. Fill in: mat_id, nprops_min, props layout, Desc fields
!   6. Implement: MD_Mat_XXX_ValidateProps, MD_Mat_XXX_InitFromProps
!
! Naming Convention (layer prefix rule):
!   Module:    MD_Mat_[Family]_[Model]        → MD_Mat_PLG_MohrCoulomb
!   Desc type: MD_Mat_XXX_Desc               → MD_Mat_PLG_MohrCoulomb_Desc  (MD-owned)
!   Validate:  MD_Mat_[Abbrev]_ValidateProps  → MD_Mat_MC_ValidateProps
!   Init:      MD_Mat_[Abbrev]_InitFromProps  → MD_Mat_MC_InitFromProps
!
! Props / nprops source:
!   nprops and props(:) originate from the ABAQUS INP file:
!     *USER MATERIAL, CONSTANTS=<N>
!     <val1>, <val2>, ..., <valN>
!   The solver stores these N constants and passes them unchanged to the
!   UMAT subroutine on every constitutive call.  The UMAT wrapper in
!   PH_Mat_XXX_XXX then forwards them here via MD_Mat_XXX_InitFromProps so
!   that the Desc structure is populated once per UMAT call.
!
! v3.2 Desc / TBP: No *_TBP stubs. Bind ValidateProps / InitFromProps directly;
!   first dummy CLASS(MD_Mat_XXX_Desc) (pass-object). Init uses INTENT(INOUT) self.
!   Comment baseline refresh: structured-status wording now uses %status_code
!   and IF_Err_Brg vocabulary (init_error_status / IF_STATUS_* / IF_ERROR_CODE_*).
!
! v3.1 Design Notes:
!   - Base class MD_Mat_Base_Desc does NOT carry E/nu/G/K/lambda.
!     These are isotropic-elastic-specific parameters.  Each concrete Desc
!     type declares whatever material parameters it needs (see fields below).
!   - Only rho (density) and identity fields live in the base class.
!   - This Desc type is purely static / configuration; it is set ONCE.
!===============================================================================
MODULE MD_Mat_XXX
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_Mat_Ids, ONLY: MAT_ID_XXX            ! ← replace with actual ID constant
  USE MD_Mat_Types, ONLY: MD_Mat_Base_Desc    ! ← v3.1 abstract base (no E/nu/G)
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  ! Prefix MD_XXX_ signals these subroutines belong to L3_MD layer.
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_XXX_Desc            ! L3_MD descriptor type (MD-owned)
  PUBLIC :: MD_Mat_XXX_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_Mat_XXX_InitFromProps   ! Unpack props -> MD_Mat_XXX_Desc

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: MD_NPROPS_NPROPS_MIN = 3_i4   ! ← set minimum required props  ! migrated
  !
  ! Props layout (document ALL slots for THIS model):
  !   props(1) = ???    : [unit]  (e.g., for ELA: E = Young's modulus [Pa])
  !   props(2) = ???    : [unit]  (e.g., for ELA: nu = Poisson's ratio [-])
  !   props(3) = ???    : model-specific [unit]
  !   props(4) = ???    : optional [unit]
  !   ...
  ! NOTE: document every slot explicitly; no "pass-through" assumptions.

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_Mat_Base_Desc, adds ALL model-specific parameters.
  !
  !   v3.1 rule: base class provides only { mat_id, mat_family, model_name,
  !              is_initialized, rho }.  ALL physics parameters (E, nu, G, K,
  !              lambda, cohesion, friction_angle, yield_stress, ...) belong HERE.
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [Model Name] constitutive model.
  TYPE, PUBLIC, EXTENDS(MD_Mat_Base_Desc) :: MD_Mat_XXX_Desc
    !-- Model-specific material parameters (replace with actual parameters)
    !   For isotropic elastic: add E, nu (and optionally G, K, lambda)
    !   For Mohr-Coulomb:      add cohesion, friction_angle, dilation_angle
    !   For von Mises:         add E, nu, sigma_y, H (hardening modulus)
    !   For hyperelastic:      add C10, C01, D1, ...
    REAL(wp) :: param1 = 0.0_wp     ! Physical meaning [unit]
    REAL(wp) :: param2 = 0.0_wp     ! Physical meaning [unit]
    ! ...

    !-- Derived / pre-computed constants (populated in InitFromProps for speed)
    !   e.g., G = E / (2*(1+nu)), lambda = E*nu/((1+nu)*(1-2nu)), sin_phi, ...
    REAL(wp) :: derived1 = 0.0_wp   ! e.g., G from E/nu, or sin(phi)

  CONTAINS
    PROCEDURE :: ValidateProps => MD_Mat_XXX_ValidateProps
    PROCEDURE :: InitFromProps => MD_Mat_XXX_InitFromProps
  END TYPE MD_Mat_XXX_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_Mat_XXX_ValidateProps
  !>   Validates the flat props array for [Model Name].
  !>   Called by L4_PH (via MD_Mat_XXX_InitFromProps) before populating Desc.
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   self    - pass-object (extend checks to use self when model-dependent)
  !>   nprops  - number of material constants (from INP *USER MATERIAL)
  !>   props   - material constant array (from INP *USER MATERIAL values)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_XXX_ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_XXX_Desc), INTENT(IN)  :: self
    INTEGER(i4),            INTENT(IN)  :: nprops   ! ABAQUS NPROPS
    REAL(wp),               INTENT(IN)  :: props(:) ! ABAQUS PROPS(NPROPS)
    TYPE(ErrorStatusType),  INTENT(OUT) :: st

    CALL init_error_status(st)
    ASSOCIATE(unused => self); END ASSOCIATE

    ! ── Minimum count check ─────────────────────────────────────────────────
    IF (nprops < MD_NPROPS_NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX]: nprops below template minimum (MD_NPROPS_NPROPS_MIN)"
      RETURN
    END IF

    ! ── Per-slot physical constraints (replace with actual model rules) ──────
    ! Example for isotropic elastic:
    !   IF (props(1) <= 0.0_wp) THEN   ! E > 0
    !     st%status_code = IF_STATUS_INVALID
    !     st%message = "[XXX]: E (props(1)) must be > 0"
    !     RETURN
    !   END IF
    !   IF (props(2) <= -1.0_wp .OR. props(2) >= 0.5_wp) THEN   ! nu ∈ (-1,0.5)
    !     st%status_code = IF_STATUS_INVALID
    !     st%message = "[XXX]: nu (props(2)) must be in (-1, 0.5)"
    !     RETURN
    !   END IF
    !
    ! Example for Mohr-Coulomb (cohesion >= 0, phi ∈ [0, 90)):
    !   IF (props(1) < 0.0_wp) THEN
    !     st%status_code = IF_STATUS_INVALID
    !     st%message = "[XXX]: cohesion (props(1)) must be >= 0"
    !     RETURN
    !   END IF

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Mat_XXX_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_Mat_XXX_InitFromProps
  !>   Unpacks flat props array into self (in-place).
  !>   Calls MD_Mat_XXX_ValidateProps first; on success sets is_initialized=.TRUE.
  !>
  !>   nprops / props originate from the ABAQUS INP file.  TWO calling paths:
  !>
  !>   Path A — UFC model initialization  [PRIMARY, called ONCE at model load]
  !>     L3_MD INP parser reads the *USER MATERIAL, CONSTANTS=<N> block and
  !>     the N constant values from the INP file.  It calls this subroutine
  !>     once during model setup to build a persistent Desc object stored in
  !>     the L3_MD material database.  UFC-native solvers then retrieve that
  !>     Desc by material index on each constitutive call — props are never
  !>     re-parsed after initialization.
  !>
  !>   Path B — ABAQUS UMAT compatibility  [SECONDARY, called per increment]
  !>     When deployed as an ABAQUS UMAT plug-in, ABAQUS re-passes props(:)
  !>     on every constitutive call (it manages the INP data internally).
  !>     PH_XXX_UMAT receives them and forwards to this subroutine each time
  !>     to rebuild Desc.  This is the ABAQUS-only flow; UFC itself uses Path A.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_Mat_XXX_InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_XXX_Desc), INTENT(INOUT) :: self
    INTEGER(i4),            INTENT(IN)    :: nprops   ! ABAQUS NPROPS
    REAL(wp),               INTENT(IN)    :: props(:) ! ABAQUS PROPS(NPROPS)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: st

    CALL MD_Mat_XXX_ValidateProps(self, nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Model-specific material parameters (mandatory slots)
    !   Replace with actual parameter unpacking for this model, e.g.:
    !     self%E      = props(1)   ! Young's modulus [Pa]           (ELA)
    !     self%nu     = props(2)   ! Poisson's ratio [-]            (ELA)
    !     self%cohesion       = props(1)   ! [Pa]                   (MC)
    !     self%friction_angle = props(2)   ! [deg] — convert to rad (MC)
    self%param1 = props(1)
    self%param2 = props(2)

    !-- Optional parameters (with default values)
    IF (nprops >= 3) self%derived1 = props(3)   ! ← replace with actual slot

    !-- Pre-computed derived constants (compute here once to avoid hot-path cost)
    !   e.g., for isotropic elastic:
    !     REAL(wp) :: E, nu
    !     E  = self%E
    !     nu = self%nu
    !     self%G      = E / (2.0_wp * (1.0_wp + nu))
    !     self%K      = E / (3.0_wp * (1.0_wp - 2.0_wp*nu))
    !     self%lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp*nu))
    !   e.g., for Mohr-Coulomb:
    !     self%sin_phi = SIN(self%friction_angle)
    !     self%cos_phi = COS(self%friction_angle)
    self%derived1 = self%param1   ! ← replace with real derived expression

    !-- Optional: density from props (if model includes rho as a prop slot)
    !   self%rho = props(last_slot)

    !-- Identification (always set last)
    self%mat_id         = MAT_ID_XXX
    self%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_Mat_XXX_InitFromProps

END MODULE MD_Mat_XXX
