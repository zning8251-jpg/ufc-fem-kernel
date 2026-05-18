!===============================================================================
! Template: MD_BC_XXX.f90                                       [Template v1.1]
! Layer:  L3_MD - Model Description Layer
! Domain: BC / [Family] (e.g., DISP / VEL / ACC / POT / TEMP / MASFL)
!
! HOW TO USE:
!   1. Copy to L3_MD/BC/[Family]/
!   2. Rename: MD_BC_[Family]_[Type].f90  (e.g., MD_BC_DISP_Linear.f90)
!   3. Replace XXX_XXX -> [Family]_[Type] throughout  (e.g., DISP_Linear)
!   4. Replace XXX     -> [Type abbrev]               (e.g., DL)
!   5. Fill in: bc_id constant, nprops_min, props layout, Desc fields
!   6. Implement: MD_XXX_BC_ValidateProps, MD_XXX_BC_InitFromProps
!   7. USE this module in PH_XXX_BC.f90 to obtain the concrete Desc type
!
! Naming Convention (layer prefix rule):
!   Module:        MD_BC_[Family]_[Type]         → MD_BC_DISP_Linear
!   Desc type:     MD_XXX_BC_Desc               → MD_BC_DISP_Linear_Desc  (MD-owned)
!   Validate:      MD_XXX_BC_ValidateProps       → MD_BC_DL_ValidateProps
!   Init:          MD_XXX_BC_InitFromProps       → MD_BC_DL_InitFromProps
!
! Props / nprops source:
!   For UFC-native models: props come from the INP parser (*BOUNDARY section).
!   For ABAQUS DISP/UPOT plug-in: props(:) passed at each DISP/UPOT call.
!   The PH_XXX_BC wrapper forwards them here via MD_XXX_BC_InitFromProps.
!
! Desc / TBP (v1.1):
!   No *_TBP forwarding stubs. Bind ValidateProps / InitFromProps directly;
!   first dummy is CLASS(MD_XXX_BC_Desc) (pass-object).
!
! Design notes (v1.0):
!   - MD_XXX_BC_Desc EXTENDS MD_BC_Base_Desc (see MD_BC_Types.f90).
!   - Base class carries: bc_id, bc_family, bc_name, is_initialized,
!                         node_set_id, dof_start/end, bc_type, magnitude.
!   - This Desc type is purely static / configuration; set ONCE at model load.
!   - All runtime per-increment data lives in PH_BC_Base_Ctx (L4_PH layer).
!   - Baseline refresh: comments now use IF_Err_Brg structured-status
!     vocabulary (%status_code, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*).
!===============================================================================
MODULE MD_BC_XXX
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID
  USE MD_BC_Ids,  ONLY: BC_ID_XXX         ! ← replace with actual BC ID constant
  USE MD_BC_Types, ONLY: MD_BC_Base_Desc  ! ← L3_MD abstract base
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Public exports: Desc type + two standard MD-layer interfaces
  ! Prefix MD_XXX_BC_ signals these subroutines belong to L3_MD layer.
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_XXX_BC_Desc            ! L3_MD descriptor type (MD-owned)
  PUBLIC :: MD_XXX_BC_ValidateProps   ! Validate flat props array
  PUBLIC :: MD_XXX_BC_InitFromProps   ! Unpack props -> MD_XXX_BC_Desc

  !-----------------------------------------------------------------------------
  ! Constants
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: NPROPS_MIN = 2_i4   ! ← set minimum required props
  !
  ! Props layout (document ALL slots for THIS BC model):
  !   props(1) = bc_type   : INTEGER cast as REAL — BC behaviour enum
  !                          1 = Fixed (homogeneous Dirichlet)
  !                          2 = Prescribed constant magnitude
  !                          3 = User-defined function
  !   props(2) = magnitude : [same unit as constrained DOF]
  !                          Used for bc_type == 2 only; ignored otherwise.
  !   props(3) = amplitude_id: (optional) amplitude table reference (0=none)
  !   ...
  ! NOTE: document every slot explicitly; no "pass-through" assumptions.

  !-----------------------------------------------------------------------------
  ! DESC type: EXTENDS MD_BC_Base_Desc, adds model-specific BC parameters.
  !
  !   Base class provides:
  !     bc_id, bc_family, bc_name, is_initialized,
  !     node_set_id, dof_start, dof_end, bc_type, magnitude, amplitude_id
  !
  !   Add HERE:  any parameters specific to this BC model that are NOT in base.
  !   Examples:
  !     DISP (tabular):    amplitude_table(100), n_amp_points
  !     UPOT:              pot_field_id, reference_potential
  !     Temperature ramp:  T_start, T_end, ramp_duration
  !-----------------------------------------------------------------------------
  !> L3 descriptor for [BC Model Name] boundary condition model.
  TYPE, PUBLIC, EXTENDS(MD_BC_Base_Desc) :: MD_XXX_BC_Desc
    !-- Model-specific BC parameters (replace with actual fields)
    !   For fixed homogeneous Dirichlet:   (no extra fields needed)
    !   For prescribed magnitude:          magnitude already in base; add below if needed
    !   For tabular amplitude:
    !     INTEGER(i4) :: n_amp_points = 0_i4
    !     REAL(wp)    :: amp_time(100) = 0.0_wp
    !     REAL(wp)    :: amp_value(100) = 0.0_wp
    !   For UPOT multi-field:
    !     INTEGER(i4) :: pot_field_id = 0_i4
    !     REAL(wp)    :: reference_potential = 0.0_wp
    REAL(wp) :: bc_param1 = 0.0_wp    ! Placeholder — rename to actual parameter
    REAL(wp) :: bc_param2 = 0.0_wp    ! Placeholder — rename to actual parameter

    !-- Derived / pre-computed constants (populated in InitFromProps for speed)
    !   e.g., ramp_rate = (target - initial) / duration
    REAL(wp) :: bc_derived1 = 0.0_wp  ! e.g., ramp rate [unit/s]

  CONTAINS
    PROCEDURE :: ValidateProps => MD_XXX_BC_ValidateProps
    PROCEDURE :: InitFromProps => MD_XXX_BC_InitFromProps
  END TYPE MD_XXX_BC_Desc

CONTAINS

  !-----------------------------------------------------------------------------
  !> MD_XXX_BC_ValidateProps
  !>   Validates the flat props array for [BC Model Name].
  !>   Called by MD_XXX_BC_InitFromProps before populating Desc.
  !>   Returns structured status with %status_code = IF_STATUS_INVALID on any
  !>   constraint violation.
  !>
  !>   self    - pass-object (unused in template checks; use for model dispatch)
  !>   nprops  - number of BC constants (from INP or plug-in props)
  !>   props   - BC constant array
  !>   st      - structured status object OUT (%status_code == IF_STATUS_OK on success)
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_BC_ValidateProps(self, nprops, props, st)
    CLASS(MD_XXX_BC_Desc), INTENT(IN)  :: self
    INTEGER(i4),           INTENT(IN)  :: nprops
    REAL(wp),              INTENT(IN)  :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)
    ASSOCIATE(unused => self); END ASSOCIATE

    ! ── Minimum count check ─────────────────────────────────────────────────
    IF (nprops < NPROPS_MIN) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_BC]: need >= NPROPS_MIN props"
      RETURN
    END IF

    ! ── Per-slot physical constraints ────────────────────────────────────────
    ! bc_type slot (props(1)): must be 1, 2, or 3
    IF (NINT(props(1)) < 1 .OR. NINT(props(1)) > 3) THEN
      st%status_code = IF_STATUS_INVALID
      st%message = "[XXX_BC]: props(1) bc_type must be 1 (fixed), 2 (prescribed), or 3 (user)"
      RETURN
    END IF

    ! magnitude slot (props(2)): finite real (no NaN check in Fortran; verify sign if needed)
    ! Example: enforce non-negative magnitude for some BC types:
    ! IF (props(2) < 0.0_wp) THEN
    !   st%status_code = IF_STATUS_INVALID
    !   st%message = "[XXX_BC]: props(2) magnitude must be >= 0"
    !   RETURN
    ! END IF

    ! ── TODO: add further constraints for additional props slots ─────────────

    st%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_BC_ValidateProps

  !-----------------------------------------------------------------------------
  !> MD_XXX_BC_InitFromProps
  !>   Unpacks flat props array into self (in-place).
  !>   Calls MD_XXX_BC_ValidateProps first; on success sets is_initialized=.TRUE.
  !>
  !>   TWO calling paths:
  !>
  !>   Path A — UFC model initialization  [PRIMARY, called ONCE at model load]
  !>     INP parser reads BC parameters from *BOUNDARY section, calls this
  !>     once during model setup to build a persistent Desc in the MD database.
  !>     UFC solvers retrieve that Desc by BC index on each BC call.
  !>
  !>   Path B — ABAQUS DISP/UPOT plug-in  [SECONDARY, called per increment]
  !>     ABAQUS re-passes props(:) on every DISP/UPOT call.
  !>     PH_XXX_BC_API receives them and calls here to rebuild Desc each time.
  !-----------------------------------------------------------------------------
  SUBROUTINE MD_XXX_BC_InitFromProps(self, nprops, props, st)
    CLASS(MD_XXX_BC_Desc), INTENT(INOUT) :: self
    INTEGER(i4),           INTENT(IN)    :: nprops
    REAL(wp),              INTENT(IN)    :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT)   :: st

    CALL MD_XXX_BC_ValidateProps(self, nprops, props, st)
    IF (st%status_code /= IF_STATUS_OK) RETURN

    !-- Mandatory slots: unpack bc_type and magnitude into base fields
    self%bc_type   = NINT(props(1))    ! props(1): BC behaviour enum (1/2/3)
    self%magnitude = props(2)         ! props(2): prescribed magnitude [DOF unit]

    !-- Optional slots (with defaults if not provided)
    IF (nprops >= 3) self%amplitude_id = NINT(props(3))  ! props(3): amplitude table ref

    !-- Model-specific parameters
    !   Replace with actual slot unpacking, e.g.:
    !     self%bc_param1 = props(4)   ! e.g., ramp duration [s]
    !     self%bc_param2 = props(5)   ! e.g., reference value [unit]
    self%bc_param1 = 0.0_wp   ! ← replace with real props slot
    self%bc_param2 = 0.0_wp   ! ← replace with real props slot

    !-- Pre-computed derived constants (compute once; avoid hot-path cost)
    !   e.g., ramp_rate = (target - initial) / duration
    !   self%bc_derived1 = (self%magnitude - 0.0_wp) / MAX(self%bc_param1, 1.0e-30_wp)
    self%bc_derived1 = 0.0_wp   ! ← replace with real derived expression

    !-- Identification (always set last)
    self%bc_id          = BC_ID_XXX
    self%is_initialized = .TRUE.
    st%status_code      = IF_STATUS_OK
  END SUBROUTINE MD_XXX_BC_InitFromProps

END MODULE MD_BC_XXX

!===============================================================================
! STRUCT REFERENCE CARD — MD Layer BC Domain
!
! ─────────────────────────────────────────────────────────────────────────────
! Layer  Domain  Role   Type name           Notes
! ─────────────────────────────────────────────────────────────────────────────
!
! ── MD layer (L3_MD) ────────────────────────────────────────────────────────
!
!  MD  BC  Desc  MD_BC_Base_Desc      Base: bc_id, bc_family, bc_name,
!                                     node_set_id, dof_start/end, bc_type,
!                                     magnitude, amplitude_id, is_initialized
!
!  MD  BC  Desc  MD_XXX_BC_Desc       EXTENDS base; model-specific params:
!                                     bc_param1, bc_param2, bc_derived1
!
!  MD  BC  State MD_BC_Base_State     accumulated, last_value, converged,
!                                     iterations, status
!
!  MD  BC  Algo  MD_BC_Base_Algo      apply_mode (1=direct, 2=time-dep),
!                                     print_debug
!
! ── PH layer (L4_PH) ────────────────────────────────────────────────────────
!
!  PH  BC  State PH_XXX_BC_State      EXTENDS MD_BC_Base_State; ISVs
!
!  PH  BC  Ctx   PH_BC_Base_Ctx       node_id, dof_number, coords(3),
!                                     time_current, time_total, step_id, inc_id
!
!  PH  BC  Algo  PH_BC_Base_Algo      max_iter, tolerance, pnewdt_min/max
!
! ── RT layer (L5_RT) ────────────────────────────────────────────────────────
!
!  RT  Com  Ctx  RT_Com_Base_Ctx      time_step, time_total, kstep, kinc,
!                                     first_increment, nlgeom
!
! ─────────────────────────────────────────────────────────────────────────────
! Props layout (fill in for concrete model):
!   props(1) = bc_type   : 1=fixed, 2=prescribed, 3=user   [integer as REAL]
!   props(2) = magnitude : prescribed DOF value             [DOF unit]
!   props(3) = amplitude_id: amplitude table ref (opt)     [integer as REAL]
!   props(4) = bc_param1 : model-specific parameter        [unit]
!   props(5) = bc_param2 : model-specific parameter        [unit]
!   ...
! ─────────────────────────────────────────────────────────────────────────────
!===============================================================================
