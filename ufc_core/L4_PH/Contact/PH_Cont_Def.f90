!===============================================================================
! MODULE: PH_Cont_Def
! LAYER:  L4_PH
! DOMAIN: Contact
! ROLE:   Def
! BRIEF:  Unified Contact four-type system (Desc/Algo/Ctx/State) + ABAQUS interface types
!
! Four-Type Mapping:
!   PH_Cont_Desc   — immutable contact pair definition (penalty/friction/search)
!   PH_Cont_Algo   — algorithm configuration (iteration limits, tolerances)
!   PH_Cont_State  — mutable runtime state (geometry/force/stiffness/friction/convergence)
!   PH_Cont_Ctx    — simplified per-pair workspace (merged from legacy PH_Contact_Ctx)
!
! Legacy PH_Contact_Desc/State/Algo/Ctx types have been merged into canonical types.
!
! Theory:  Contact mechanics with KKT conditions and friction models
! Contract: L4_PH/Contact/CONTRACT.md
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================
!>>> UFC_PH_QUENCH | Domain:Contact | Role:Types | FuncSet?Desc+State
!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md

MODULE PH_Cont_Def
!> [CORE] Unified Contact Type System
!> Theory:
!>   1. Karush-Kuhn-Tucker (KKT) Conditions:
!> g 0, 0, ˡ g = 0
!> where g is gap function, is contact pressure
!>   2. Penalty Method:
!> F_contact = _N max(0, -g) n
!> where _N is penalty parameter, n is normal vector
!>   3. Augmented Lagrangian:
!> L_ (u, ) = (u) + ^T g(u) + /2 ||max(0,g(u)+ / )||?
!>   4. Coulomb Friction:
!> | | ̡ _n, = - ̡ _n (v_t/|v_t|) when sliding
!> 5. Gap function: g = (x_slave - x_master) n where n is unit normal
!> 6. Thermal contact: q = h (T_slave - T_master) where h is thermal conductance
!> References:
!>   - Wriggers, P. (2006). Computational Contact Mechanics, 2nd ed.
!>   - Laursen, T.A. (2002). Computational Contact and Impact Mechanics
!> Status: Production | Last verified: 2026-02-28
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  ! ========================================================================== 
  ! PUBLIC TYPES
  ! ==========================================================================
  ! --- Canonical four-type system ---
  PUBLIC :: PH_Cont_Desc
  PUBLIC :: PH_Cont_Algo
  PUBLIC :: PH_Cont_State
  PUBLIC :: PH_Cont_Ctx
  PUBLIC :: PH_Cont_Friction_Model
  PUBLIC :: PH_Cont_Thermal_Properties
  PUBLIC :: PH_Cont_Dynamic_Properties
  PUBLIC :: PH_Cont_Optimization_Params
  ! Phase 5 Enhancement: ABAQUS contact interface types (NEW)
  ! R-09 canonical names (PH_Contact_Interface* replaces PH_Contact_Base*):
  PUBLIC :: PH_Contact_InterfaceCtx
  PUBLIC :: PH_Contact_InterfaceState
  ! PH_Contact_Base_Algo: not yet defined in this module (placeholder removed)
  PUBLIC :: PH_Contact_VUINTER_Ctx
  PUBLIC :: PH_Contact_GAPCON_Ctx
  PUBLIC :: PH_Contact_UINTER_Ctx
  PUBLIC :: PH_Contact_UINTER_State
  PUBLIC :: PH_Contact_VUINTER_State
  PUBLIC :: PH_Contact_GAPCON_State
  PUBLIC :: PH_Contact_GAPUNIT_Ctx
  PUBLIC :: PH_Contact_GAPUNIT_State
  PUBLIC :: PH_Contact_UINTER_Algo
  PUBLIC :: PH_Contact_VUINTER_Algo
  PUBLIC :: PH_Contact_GAPCON_Algo
  PUBLIC :: PH_Contact_GAPUNIT_Algo
  ! Phase 3 Enhancement: Contact pair description (NEW)
  PUBLIC :: PH_Contact_Pair_Desc
  PUBLIC :: PH_Contact_Surface_Desc
  PUBLIC :: PH_Contact_BVH_Node
  ! Phase 6B Enhancement: Contact search Procedure-as-Parameter strategy
  PUBLIC :: ContactSearchStrategy_Ifc
  PUBLIC :: PH_Cont_SearchStrategy_Arg
  PUBLIC :: PH_Cont_SearchStrategy_Ifc

  ! ==========================================================================
  ! DESC TYPES (Description/Configuration - Immutable)
  ! ==========================================================================

  !> @brief Contact constraint description (configuration)
  !! Contains penalty parameters, algorithm selection, etc.
  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Config
      INTEGER(i4) :: method = 1
      LOGICAL :: adaptive_penalty = .TRUE.
  END TYPE PH_Cont_Constr_Desc_Config

  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Penalty
      REAL(wp) :: penalty_parameter = 1.0e6_wp
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
  END TYPE PH_Cont_Constr_Desc_Penalty

  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Config
      INTEGER(i4) :: method = 1
      LOGICAL :: adaptive_penalty = .TRUE.
  END TYPE PH_Cont_Constr_Desc_Config

  TYPE, PUBLIC :: PH_Cont_Constr_Desc_Penalty
      REAL(wp) :: penalty_parameter = 1.0e6_wp
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
  END TYPE PH_Cont_Constr_Desc_Penalty

  TYPE, PUBLIC :: PH_Cont_Constr_Desc
      TYPE(PH_Cont_Constr_Desc_Config) :: config
      TYPE(PH_Cont_Constr_Desc_Penalty) :: penalty
  END TYPE PH_Cont_Constr_Desc

  !> @brief Friction model configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Fric_Cfg_Model
      INTEGER(i4) :: model_type = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent, 4=Viscoelastic
      LOGICAL :: stick_slip_transition = .TRUE.
  END TYPE PH_Fric_Cfg_Model

  !> @brief Friction coefficient configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Fric_Cfg_Coeff
      REAL(wp) :: mu_static = ZERO
      REAL(wp) :: mu_dynamic = ZERO
  END TYPE PH_Fric_Cfg_Coeff

  !> @brief Friction physical parameters (nested auxiliary)
  TYPE, PUBLIC :: PH_Fric_Cfg_Physical
      REAL(wp) :: friction_stiffness = ZERO
      REAL(wp) :: critical_slip_velocity = ZERO
      REAL(wp) :: regularization_parameter = ZERO
  END TYPE PH_Fric_Cfg_Physical

  !> @brief Friction model description (configuration)
  TYPE, PUBLIC :: PH_Cont_Friction_Desc
      TYPE(PH_Fric_Cfg_Model)    :: model
      TYPE(PH_Fric_Cfg_Coeff)    :: coeff
      TYPE(PH_Fric_Cfg_Physical) :: phys
      ! NOTE: Flat fields removed after P2 migration (zero external references verified)
  END TYPE PH_Cont_Friction_Desc

  !> @brief Contact search description (configuration)
  TYPE, PUBLIC :: PH_Cont_Search_Desc_Algo
      INTEGER(i4) :: search_algorithm = 1
  END TYPE PH_Cont_Search_Desc_Algo

  TYPE, PUBLIC :: PH_Cont_Search_Desc_Params
      REAL(wp) :: search_radius = ZERO
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: adaptive_search = .TRUE.
  END TYPE PH_Cont_Search_Desc_Params

  TYPE, PUBLIC :: PH_Cont_Search_Desc_Algo
      INTEGER(i4) :: search_algorithm = 1
  END TYPE PH_Cont_Search_Desc_Algo

  TYPE, PUBLIC :: PH_Cont_Search_Desc_Params
      REAL(wp) :: search_radius = ZERO
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: adaptive_search = .TRUE.
  END TYPE PH_Cont_Search_Desc_Params

  TYPE, PUBLIC :: PH_Cont_Search_Desc
      TYPE(PH_Cont_Search_Desc_Algo) :: algo
      TYPE(PH_Cont_Search_Desc_Params) :: params
  END TYPE PH_Cont_Search_Desc

  !> @brief Contact penalty configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Cfg_Penalty_Desc
      REAL(wp) :: penalty_normal  = 1.0E6_wp   ! normal penalty stiffness
      REAL(wp) :: penalty_tangent = 1.0E5_wp   ! tangential penalty
  END TYPE PH_Cont_Cfg_Penalty_Desc

  !> @brief Contact tolerance configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Cfg_Tol_Desc
      REAL(wp) :: gap_tolerance   = 1.0E-6_wp  ! gap tolerance for open/closed
      REAL(wp) :: mu_friction     = 0.0_wp     ! Coulomb friction coefficient
  END TYPE PH_Cont_Cfg_Tol_Desc

  !> @brief Unified contact description (bundles all Desc types)
  TYPE, PUBLIC :: PH_Cont_Desc
      TYPE(PH_Cont_Constr_Desc) :: constr
      TYPE(PH_Cont_Friction_Desc) :: friction
      TYPE(PH_Cont_Search_Desc) :: search
      TYPE(PH_Cont_Cfg_Penalty_Desc) :: cfg_penalty
      TYPE(PH_Cont_Cfg_Tol_Desc) :: cfg_tol
      INTEGER(i4) :: contact_pair_id = 0
      INTEGER(i4) :: slave_surface_id = 0
      INTEGER(i4) :: master_surface_id = 0
  END TYPE PH_Cont_Desc

  ! ==========================================================================
  ! PROCEDURE-AS-PARAMETER: Contact Search Strategy Interface (Phase 6B)
  ! Must be defined BEFORE PH_Cont_Algo which references it.
  ! ==========================================================================

  !> @brief Structured argument for contact search strategy dispatch
  TYPE, PUBLIC :: PH_Cont_SearchStrategy_Arg
    REAL(wp), POINTER :: slave_coords(:,:)  => NULL()  ! [IN]  (3, n_slave)
    REAL(wp), POINTER :: master_coords(:,:) => NULL()  ! [IN]  (3, n_master)
    REAL(wp) :: search_radius = 0.0_wp                 ! [IN]  search radius
    INTEGER(i4) :: n_candidates = 0                    ! [OUT] found candidates
    INTEGER(i4), POINTER :: candidate_slave(:)  => NULL()  ! [OUT] slave IDs
    INTEGER(i4), POINTER :: candidate_master(:) => NULL()  ! [OUT] master IDs
    REAL(wp), POINTER :: candidate_dist(:)      => NULL()  ! [OUT] distances
    TYPE(ErrorStatusType) :: status                    ! [OUT]
  END TYPE PH_Cont_SearchStrategy_Arg

  !> @brief ABSTRACT INTERFACE for pluggable contact search strategy
  !! Procedure-as-Parameter: allows NTS, Mortar, or custom search strategies
  !! Uses simplified Arg bundle to avoid circular type dependency
  ABSTRACT INTERFACE
    SUBROUTINE ContactSearchStrategy_Ifc(arg, status)
      IMPORT :: PH_Cont_SearchStrategy_Arg, ErrorStatusType
      TYPE(PH_Cont_SearchStrategy_Arg), INTENT(INOUT) :: arg
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE ContactSearchStrategy_Ifc
  END INTERFACE

  ! ==========================================================================
  ! ALGO TYPES (Algorithm Configuration)
  ! ==========================================================================

  !> @brief Contact constraint algorithm configuration
  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Iter
      INTEGER(i4) :: max_iterations = 50
  END TYPE PH_Cont_Constr_Algo_Iter

  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Tol
      REAL(wp) :: tolerance = 1.0e-6_wp
      REAL(wp) :: relative_tolerance = 1.0e-6_wp
  END TYPE PH_Cont_Constr_Algo_Tol

  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Solver
      INTEGER(i4) :: optimization_strategy = 1
      REAL(wp) :: convergence_acceleration = 1.0_wp
  END TYPE PH_Cont_Constr_Algo_Solver

  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Iter
      INTEGER(i4) :: max_iterations = 50
  END TYPE PH_Cont_Constr_Algo_Iter

  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Tol
      REAL(wp) :: tolerance = 1.0e-6_wp
      REAL(wp) :: relative_tolerance = 1.0e-6_wp
  END TYPE PH_Cont_Constr_Algo_Tol

  TYPE, PUBLIC :: PH_Cont_Constr_Algo_Solver
      INTEGER(i4) :: optimization_strategy = 1
      REAL(wp) :: convergence_acceleration = 1.0_wp
  END TYPE PH_Cont_Constr_Algo_Solver

  TYPE, PUBLIC :: PH_Cont_Constr_Algo
      TYPE(PH_Cont_Constr_Algo_Iter) :: iter
      TYPE(PH_Cont_Constr_Algo_Tol) :: tol
      TYPE(PH_Cont_Constr_Algo_Solver) :: solver
  END TYPE PH_Cont_Constr_Algo

  !> @brief Friction algorithm configuration
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Rate
      REAL(wp) :: decay_rate = ZERO
      REAL(wp) :: pressure_exponent = ZERO
      REAL(wp) :: transition_velocity = ZERO
  END TYPE PH_Cont_Friction_Algo_Rate

  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Config
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Algo_Config

  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Rate
      REAL(wp) :: decay_rate = ZERO
      REAL(wp) :: pressure_exponent = ZERO
      REAL(wp) :: transition_velocity = ZERO
  END TYPE PH_Cont_Friction_Algo_Rate

  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Config
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Algo_Config

  TYPE, PUBLIC :: PH_Cont_Friction_Algo
      TYPE(PH_Cont_Friction_Algo_Rate) :: rate
      TYPE(PH_Cont_Friction_Algo_Config) :: config
  END TYPE PH_Cont_Friction_Algo

  !> @brief Contact step method configuration (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Stp_Method_Algo
      INTEGER(i4) :: method       = 1        ! 1=penalty, 2=Lagrange, 3=augmented
      REAL(wp)    :: scale_factor = 1.0_wp   ! penalty scaling factor
  END TYPE PH_Cont_Stp_Method_Algo

  !> @brief Unified contact algorithm configuration
  TYPE, PUBLIC :: PH_Cont_Algo
      TYPE(PH_Cont_Constr_Algo) :: constr
      TYPE(PH_Cont_Friction_Algo) :: friction
      TYPE(PH_Cont_Stp_Method_Algo) :: stp_method
      ! --- Phase 6B: Procedure-as-Parameter strategy pointer ---
      PROCEDURE(ContactSearchStrategy_Ifc), POINTER, NOPASS :: search_strategy => NULL()
  END TYPE PH_Cont_Algo

  ! ==========================================================================
  ! CTX TYPES (Context - Per-pair workspace)
  ! ==========================================================================

  !> @brief Contact local position context (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Lcl_Pos_Ctx
    REAL(wp) :: x_slave(3)      = 0.0_wp   ! slave point coords
    REAL(wp) :: x_master(3)     = 0.0_wp   ! master point coords
  END TYPE PH_Cont_Lcl_Pos_Ctx

  !> @brief Contact local normal context (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Lcl_Normal_Ctx
    REAL(wp) :: normal(3)       = 0.0_wp   ! contact normal
  END TYPE PH_Cont_Lcl_Normal_Ctx

  !> @brief Contact local stiffness context (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Lcl_Stiff_Ctx
    REAL(wp) :: K_contact(24,24)= 0.0_wp   ! contact stiffness contribution
  END TYPE PH_Cont_Lcl_Stiff_Ctx

  !> @brief Simplified per-pair contact workspace (merged from legacy PH_Contact_Ctx)
  TYPE, PUBLIC :: PH_Cont_Ctx
    TYPE(PH_Cont_Lcl_Pos_Ctx)   :: lcl_pos
    TYPE(PH_Cont_Lcl_Normal_Ctx):: lcl_normal
    TYPE(PH_Cont_Lcl_Stiff_Ctx) :: lcl_stiff
  END TYPE PH_Cont_Ctx

  ! Note: PH_ContactCtx (rich context) is defined in Core/PH_Cont_Def.f90

  ! ==========================================================================
  ! ABAQUS CONTACT INTERFACE CTX TYPES (Phase 5 Enhancement)
  ! ==========================================================================
  
  !> @brief UINTER/VUINTER flat interface context (per-increment driving inputs)
  !! Maps to ABAQUS UINTER/VUINTER gap and slip parameters.
  !! This is NOT the four-kind Ctx (PH_Cont_Ctx); it is a flat ABI_Flåten workspace.
  !! Canonical name (R-09): PH_Contact_InterfaceCtx replaces PH_Contact_Base_Ctx.
  TYPE, PUBLIC :: PH_Contact_InterfaceCtx
    !-- Gap and slip
    REAL(wp) :: gap = 0.0_wp        ! GAP    current contact gap
    REAL(wp) :: slip1 = 0.0_wp      ! SLIP1  tangent slip direction 1
    REAL(wp) :: slip2 = 0.0_wp      ! SLIP2  tangent slip direction 2
    !-- Contact conditions
    REAL(wp) :: pressure = 0.0_wp   ! PRES   normal contact pressure
    REAL(wp) :: temp = 0.0_wp       ! TEMP   contact temperature
    !-- Contact point info
    REAL(wp) :: coords(3) = 0.0_wp  ! COORDS contact point coordinates
    !-- Identification
    INTEGER(i4) :: elem_id = 0      ! NOEL   contact element
    INTEGER(i4) :: integ_pt_id = 0  ! NPT    integration point
    !-- Tangent directions
    REAL(wp) :: tang1(3) = 0.0_wp   ! Tangent direction 1
    REAL(wp) :: tang2(3) = 0.0_wp   ! Tangent direction 2
  END TYPE PH_Contact_InterfaceCtx

    !-- Gap and slip
    REAL(wp) :: gap = 0.0_wp        ! GAP    current contact gap
    REAL(wp) :: slip1 = 0.0_wp      ! SLIP1  tangent slip direction 1
    REAL(wp) :: slip2 = 0.0_wp      ! SLIP2  tangent slip direction 2
    !-- Contact conditions
    REAL(wp) :: pressure = 0.0_wp   ! PRES   normal contact pressure
    REAL(wp) :: temp = 0.0_wp       ! TEMP   contact temperature
    !-- Contact point info
    REAL(wp) :: coords(3) = 0.0_wp  ! COORDS contact point coordinates
    !-- Identification
    INTEGER(i4) :: elem_id = 0      ! NOEL   contact element
    INTEGER(i4) :: integ_pt_id = 0  ! NPT    integration point
    !-- Tangent directions
    REAL(wp) :: tang1(3) = 0.0_wp   ! Tangent direction 1
    REAL(wp) :: tang2(3) = 0.0_wp   ! Tangent direction 2
  END TYPE PH_Cont_Ctx

  ! DEPRECATED: Use PH_Cont_Ctx instead (R-09). Will be removed after 2026-06.

  !> @brief VUINTER vectorized contact context (Explicit block)
  !! All arrays have first dimension = nblock
  TYPE, PUBLIC :: PH_Contact_VUINTER_Ctx
    INTEGER(i4) :: nblock = 1_i4     ! NBLOCK: block size
    INTEGER(i4) :: nfdir  = 2_i4     ! NFDIR: friction/tangential directions
    INTEGER(i4) :: nshr   = 1_i4     ! NSHR: shear components
    !-- Block arrays [nblock]
    REAL(wp), POINTER :: gap_blk(:)      ! Gap at each contact point
    REAL(wp), POINTER :: slip1_blk(:)    ! Slip dir-1
    REAL(wp), POINTER :: slip2_blk(:)    ! Slip dir-2
    REAL(wp), POINTER :: pres_blk(:)     ! Normal pressure
    REAL(wp), POINTER :: temp_blk(:)     ! Temperature at contact
    REAL(wp), POINTER :: coords_blk(:,:) ! Contact coordinates [nblock,3]
    !-- State variables block [nblock, nstatv]
    REAL(wp), POINTER :: svars_blk(:,:)
    INTEGER(i4) :: nstatv = 0_i4
  END TYPE PH_Contact_VUINTER_Ctx

  !> @brief GAPCON gap thermal conductance context
  !! Used in Standard contact thermal analyses
  TYPE, PUBLIC :: PH_Contact_GAPCON_Ctx
    REAL(wp) :: gap      = 0.0_wp    ! GAP: current gap [m]
    REAL(wp) :: pressure = 0.0_wp    ! Pressure at interface [Pa]
    REAL(wp) :: temp1    = 0.0_wp    ! Surface 1 temperature [K]
    REAL(wp) :: temp2    = 0.0_wp    ! Surface 2 temperature [K]
    REAL(wp) :: coords(3) = 0.0_wp   ! Contact point coordinates
    INTEGER(i4) :: node_id = 0_i4   ! NOEL (node pair identification)
    !-- Output
    REAL(wp) :: cond     = 0.0_wp    ! Gap conductance [W/(m²·K)]
    REAL(wp) :: dcond_dgap  = 0.0_wp ! d(cond)/d(gap) Jacobian
    REAL(wp) :: dcond_dpres = 0.0_wp ! d(cond)/d(pres) Jacobian
  END TYPE PH_Contact_GAPCON_Ctx

  !> @brief UINTER per-call driving inputs
  !! Maps to ABAQUS UINTER arguments
  TYPE, PUBLIC :: PH_Contact_UINTER_Ctx
    REAL(wp), POINTER :: coords(:,:)  ! I COORDS   [ndim, 2] master/slave nodes
    REAL(wp), POINTER :: cdisp(:)     ! I CDISP    contact displacement [ndim]
    REAL(wp), POINTER :: cdispdot(:)  ! I CDISPDOT relative velocity
    REAL(wp) :: temp(2)   = 0.0_wp   ! I TEMP(2)  temperatures at nodes
    REAL(wp) :: dtemp(2)  = 0.0_wp   ! I DTEMP(2) temperature increments
    REAL(wp) :: time(2)   = 0.0_wp   ! I TIME(2)
    REAL(wp) :: dtime     = 0.0_wp   ! I DTIME
    INTEGER(i4) :: noel   = 0_i4
    INTEGER(i4) :: npt    = 0_i4
    INTEGER(i4) :: kstep  = 0_i4
    INTEGER(i4) :: kinc   = 0_i4
    INTEGER(i4) :: ndim   = 3_i4
  END TYPE PH_Contact_UINTER_Ctx

  !> @brief GAPUNIT radiation/electrical conductance context
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Geom
    REAL(wp) :: gap      = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: coords(3)= 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Geom

  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Thermal
    REAL(wp) :: temp1    = 0.0_wp
    REAL(wp) :: temp2    = 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Thermal

  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Geom
    REAL(wp) :: gap      = 0.0_wp
    REAL(wp) :: pressure = 0.0_wp
    REAL(wp) :: coords(3)= 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Geom

  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx_Thermal
    REAL(wp) :: temp1    = 0.0_wp
    REAL(wp) :: temp2    = 0.0_wp
  END TYPE PH_Contact_GAPUNIT_Ctx_Thermal

  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Ctx
    TYPE(PH_Contact_GAPUNIT_Ctx_Geom) :: geom
    TYPE(PH_Contact_GAPUNIT_Ctx_Thermal) :: thermal
  END TYPE PH_Contact_GAPUNIT_Ctx

  ! ==========================================================================
  ! STATE TYPES (Runtime State - Mutable)
  ! ==========================================================================

  !> @brief Contact geometry state
  TYPE, PUBLIC :: PH_Cont_Geometry_State
      REAL(wp) :: gap = ZERO
      REAL(wp) :: penetration = ZERO
      REAL(wp) :: previous_gap = ZERO
      REAL(wp), ALLOCATABLE :: normal_vector(:)    ! (3) - Unit normal
      REAL(wp), ALLOCATABLE :: tangent_vector1(:)  ! (3) - First tangent
      REAL(wp), ALLOCATABLE :: tangent_vector2(:)  ! (3) - Second tangent
  END TYPE PH_Cont_Geometry_State

  !> @brief Contact force state
  TYPE, PUBLIC :: PH_Cont_Force_State
      REAL(wp), ALLOCATABLE :: normal_force(:)     ! (3) - Normal force vector
      REAL(wp), ALLOCATABLE :: friction_force(:)   ! (3) - Friction force vector
      REAL(wp) :: normal_force_magnitude = ZERO
      REAL(wp) :: friction_force_magnitude = ZERO
      REAL(wp), ALLOCATABLE :: contact_traction(:)  ! (3) - Total traction
      REAL(wp) :: contact_pressure = ZERO
      REAL(wp) :: shear_traction = ZERO
  END TYPE PH_Cont_Force_State

  !> @brief Contact stiffness state
  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Matrix
      REAL(wp), ALLOCATABLE :: K_contact(:,:)
      REAL(wp), ALLOCATABLE :: C_contact(:,:)
  END TYPE PH_Cont_Stiffness_State_Matrix

  TYPE, PUBLIC :: PH_Cont_Stiffness_State_Scalar
      REAL(wp) :: normal_stiffness = ZERO
      REAL(wp) :: tangential_stiffness = ZERO
  END TYPE PH_Cont_Stiffness_State_Scalar

  TYPE, PUBLIC :: PH_Cont_Stiffness_State
      TYPE(PH_Cont_Stiffness_State_Matrix) :: matrix
      TYPE(PH_Cont_Stiffness_State_Scalar) :: scalar
  END TYPE PH_Cont_Stiffness_State

  !> @brief Friction state
  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip

  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip

  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip

  TYPE, PUBLIC :: PH_Cont_Friction_State_Slip
      REAL(wp), ALLOCATABLE :: slip_velocity(:)
      REAL(wp) :: slip_magnitude = ZERO
      REAL(wp) :: accumulated_slip = ZERO
      REAL(wp) :: slip_rate = ZERO
  END TYPE PH_Cont_Friction_State_Slip

  TYPE, PUBLIC :: PH_Cont_Friction_State
      TYPE(PH_Cont_Friction_State_Slip) :: slip
      INTEGER(i4) :: friction_state = 0
  END TYPE PH_Cont_Friction_State

  !> @brief Convergence state
  TYPE, PUBLIC :: PH_Cont_Convergence_State
      REAL(wp) :: residual_norm = ZERO
      REAL(wp) :: residual_norm_previous = ZERO
      REAL(wp) :: convergence_rate = ZERO
      INTEGER(i4) :: iteration_count = 0
      LOGICAL :: force_converged = .FALSE.
      LOGICAL :: displacement_converged = .FALSE.
      LOGICAL :: gap_converged = .FALSE.
      LOGICAL :: friction_converged = .FALSE.
      CHARACTER(LEN=50) :: convergence_method = "Relative"
  END TYPE PH_Cont_Convergence_State

  !> @brief Contact iteration quick-access state (nested auxiliary)
  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Force
      REAL(wp)    :: f_normal       = 0.0_wp
      REAL(wp)    :: f_friction     = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Force

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State_Geom
      REAL(wp)    :: gap            = 0.0_wp
      REAL(wp)    :: slip           = 0.0_wp
  END TYPE PH_Cont_Itr_Quick_State_Geom

  TYPE, PUBLIC :: PH_Cont_Itr_Quick_State
      INTEGER(i4) :: contact_status = 0
      TYPE(PH_Cont_Itr_Quick_State_Force) :: force
      TYPE(PH_Cont_Itr_Quick_State_Geom) :: geom
  END TYPE PH_Cont_Itr_Quick_State

  !> @brief Unified contact state (bundles all State types)
  TYPE, PUBLIC :: PH_Cont_State
      INTEGER(i4) :: contact_state = 0  ! 0=separate, 1=contact, 2=sticking, 3=sliding
      TYPE(PH_Cont_Geometry_State) :: geometry
      TYPE(PH_Cont_Force_State) :: force
      TYPE(PH_Cont_Stiffness_State) :: stiffness
      TYPE(PH_Cont_Friction_State) :: friction
      TYPE(PH_Cont_Convergence_State) :: convergence
      TYPE(PH_Cont_Itr_Quick_State) :: itr_quick
  END TYPE PH_Cont_State

  ! ==========================================================================
  ! ABAQUS CONTACT INTERFACE STATE TYPES (Phase 5 Enhancement)
  ! ==========================================================================
  
  !> @brief UINTER/VUINTER flat interface output state
  !! Traction/pressure results written by UINTER/VUINTER.
  !! This is NOT the four-kind State (PH_Cont_State); it is a flat output bundle.
  !! Canonical name (R-09): PH_Contact_InterfaceState replaces PH_Contact_Base_State.
  TYPE, PUBLIC :: PH_Contact_InterfaceState
    !-- Contact traction output
    REAL(wp) :: traction_n  = 0.0_wp   ! Normal traction (pressure) [Pa]
    REAL(wp) :: traction_t1 = 0.0_wp   ! Shear traction dir-1 [Pa]
    REAL(wp) :: traction_t2 = 0.0_wp   ! Shear traction dir-2 [Pa]
    !-- Jacobian (AKI/BKI in UINTER)
    REAL(wp) :: dtn_dgap     = 0.0_wp  ! dtraction_n/dgap
    REAL(wp) :: dtt1_dslip1  = 0.0_wp  ! dtraction_t1/dslip1
    REAL(wp) :: dtt2_dslip2  = 0.0_wp  ! dtraction_t2/dslip2
    !-- State variables
    REAL(wp), ALLOCATABLE :: svars(:)  ! Solution-dependent state variables
    !-- Convergence bookkeeping
    LOGICAL     :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_InterfaceState


  !> @brief UINTER output state
  !! Carries traction, Jacobian, and status written back by UINTER
  TYPE, PUBLIC :: PH_Contact_UINTER_State_Traction
    REAL(wp) :: traction_n  = 0.0_wp
    REAL(wp) :: traction_t1 = 0.0_wp
    REAL(wp) :: traction_t2 = 0.0_wp
  END TYPE PH_Contact_UINTER_State_Traction

  TYPE, PUBLIC :: PH_Contact_UINTER_State_Jacobian
    REAL(wp) :: dtn_dgap     = 0.0_wp
    REAL(wp) :: dtt1_dslip1  = 0.0_wp
    REAL(wp) :: dtt2_dslip2  = 0.0_wp
  END TYPE PH_Contact_UINTER_State_Jacobian


  TYPE, PUBLIC :: PH_Contact_UINTER_State
    TYPE(PH_Contact_UINTER_State_Traction) :: traction
    TYPE(PH_Contact_UINTER_State_Jacobian) :: jacobian
  END TYPE PH_Contact_UINTER_State

  !> @brief VUINTER block output state (Explicit)
  !! Block arrays for all contact pairs in the block
  TYPE, PUBLIC :: PH_Contact_VUINTER_State
    REAL(wp), ALLOCATABLE :: traction_blk(:,:)   ! [nblock, 3] output tractions
    REAL(wp), ALLOCATABLE :: dtraction_blk(:,:,:)! [nblock, 3, 3] Jacobian
    REAL(wp), ALLOCATABLE :: svars_blk(:,:)      ! [nblock, nsvars]
    INTEGER(i4) :: nblock = 0
    LOGICAL :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_VUINTER_State

  !> @brief GAPCON gap conductance output state
  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct

  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct

  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct

  TYPE, PUBLIC :: PH_Contact_GAPCON_State_Conduct
    REAL(wp) :: conductance = 0.0_wp
    REAL(wp) :: heat_flux   = 0.0_wp
    REAL(wp) :: dflux_dtemp = 0.0_wp
    REAL(wp) :: dflux_dgap  = 0.0_wp
  END TYPE PH_Contact_GAPCON_State_Conduct

  TYPE, PUBLIC :: PH_Contact_GAPCON_State
    REAL(wp) :: gap = 0.0_wp
    TYPE(PH_Contact_GAPCON_State_Conduct) :: conduct
  END TYPE PH_Contact_GAPCON_State

  !> @brief GAPUNIT output state
  !! Carries unit conductance (thermal/electrical) computed by user
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_State
    REAL(wp) :: unit_cond     = 0.0_wp  ! OUT: unit conductance [W/(m²·K)] or [A/V]
    REAL(wp) :: dcond_dgap    = 0.0_wp  ! OUT: d(cond)/d(gap)
    REAL(wp) :: dcond_dtemp1  = 0.0_wp  ! OUT: d(cond)/d(T1)
    REAL(wp) :: dcond_dtemp2  = 0.0_wp  ! OUT: d(cond)/d(T2)
    LOGICAL  :: converged = .FALSE.
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Contact_GAPUNIT_State

  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES FOR INTERFACES
  ! ==========================================================================

  !> @brief Input structure for penalty force computation

  !> @brief Output structure for penalty force computation
  TYPE, PUBLIC :: PH_Cont_PenaltyForce_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penalty                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PenaltyForce_Arg


  !> @brief Input structure for penalty stiffness computation

  !> @brief Output structure for penalty stiffness computation
  TYPE, PUBLIC :: PH_Cont_PenaltyStiffness_Arg
    REAL(wp) :: penalty                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PenaltyStiffness_Arg


  !> @brief Input structure for Lagrange force computation

  !> @brief Output structure for Lagrange force computation
  TYPE, PUBLIC :: PH_Cont_LagrangeForce_Arg
    REAL(wp) :: lambda                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_LagrangeForce_Arg


  !> @brief Input structure for Augmented Lagrangian force computation

  !> @brief Output structure for Augmented Lagrangian force computation
  TYPE, PUBLIC :: PH_Cont_AugLagForce_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penalty                   ! [IN]
    REAL(wp) :: lambda                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AugLagForce_Arg


  !> @brief Input structure for Augmented Lagrangian multiplier update

  !> @brief Output structure for Augmented Lagrangian multiplier update
  TYPE, PUBLIC :: PH_Cont_AugLagUpdate_Arg
    REAL(wp) :: gap              ! Gap value (negative = penetration)                   ! [IN]
    REAL(wp) :: penalty          ! Penalty parameter (rho)                   ! [IN]
    REAL(wp) :: lambda           ! Current Lagrange multiplier                   ! [IN]
    REAL(wp) :: lambda_updated   ! Updated Lagrange multiplier                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AugLagUpdate_Arg


  !> @brief Input structure for Coulomb friction force computation

  !> @brief Output structure for Coulomb friction force computation
  TYPE, PUBLIC :: PH_Cont_CoulombFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_CoulombFriction_Arg


  !> @brief Input structure for stick-slip friction computation

  !> @brief Output structure for stick-slip friction computation
  TYPE, PUBLIC :: PH_Cont_StickSlip_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    REAL(wp) :: friction_stiffness                   ! [IN]
    LOGICAL :: is_sticking                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_StickSlip_Arg


  !> @brief Input structure for slip computation

  !> @brief Output structure for slip computation
  TYPE, PUBLIC :: PH_Cont_ComputeSlip_Arg
    REAL(wp) :: time_step                   ! [IN]
  END TYPE PH_Cont_ComputeSlip_Arg


  !> @brief Input structure for friction stiffness computation

  !> @brief Output structure for friction stiffness computation
  TYPE, PUBLIC :: PH_Cont_FrictionStiffness_Arg
    REAL(wp) :: friction_stiffness                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_FrictionStiffness_Arg


  !> @brief Input structure for exponential friction model

  !> @brief Output structure for exponential friction model
  TYPE, PUBLIC :: PH_Cont_ExponentialFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff                   ! [IN]
    REAL(wp) :: decay_rate                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ExponentialFriction_Arg


  !> @brief Input structure for pressure-dependent friction model

  !> @brief Output structure for pressure-dependent friction model
  TYPE, PUBLIC :: PH_Cont_PressureDependentFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: contact_area                   ! [IN]
    REAL(wp) :: friction_coeff_base                   ! [IN]
    REAL(wp) :: pressure_exponent                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_PressureDependentFriction_Arg


  !> @brief Input structure for velocity-dependent friction model

  !> @brief Output structure for velocity-dependent friction model
  TYPE, PUBLIC :: PH_Cont_VelocityDependentFriction_Arg
    REAL(wp) :: normal_force                   ! [IN]
    REAL(wp) :: friction_coeff_static                   ! [IN]
    REAL(wp) :: friction_coeff_kinetic                   ! [IN]
    REAL(wp) :: transition_velocity                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_VelocityDependentFriction_Arg


  ! ==========================================================================
  ! SEARCH INPUT/OUTPUT STRUCTURES
  ! ==========================================================================

  !> @brief Input structure for gap computation

  !> @brief Output structure for gap computation
  TYPE, PUBLIC :: PH_Cont_Gap_Arg
    REAL(wp) :: gap                   ! [OUT]
  END TYPE PH_Cont_Gap_Arg


  !> @brief Input structure for normal vector computation

  !> @brief Output structure for normal vector computation
  TYPE, PUBLIC :: PH_Cont_Normal_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Normal_Arg


  !> @brief Input structure for contact state check

  !> @brief Output structure for contact state check
  TYPE, PUBLIC :: PH_Cont_StateCheck_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: tolerance                   ! [IN]
    LOGICAL :: is_contact                   ! [OUT]
  END TYPE PH_Cont_StateCheck_Arg


  !> @brief Input structure for nearest point computation

  !> @brief Output structure for nearest point computation
  TYPE, PUBLIC :: PH_Cont_NearestPoint_Arg
    REAL(wp) :: parameter                   ! [OUT]
    REAL(wp) :: distance                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_NearestPoint_Arg


  !> @brief Input structure for penetration computation

  !> @brief Output structure for penetration computation
  TYPE, PUBLIC :: PH_Cont_Penetration_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: penetration                   ! [OUT]
  END TYPE PH_Cont_Penetration_Arg


  ! ==========================================================================
  ! CORE ALGORITHM INPUT/OUTPUT STRUCTURES
  ! ==========================================================================

  !> @brief Input structure for algorithm framework

  !> @brief Output structure for algorithm framework
  TYPE, PUBLIC :: PH_Cont_AlgorithmFramework_Arg
    REAL(wp) :: gap                   ! [IN]
    REAL(wp) :: dt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AlgorithmFramework_Arg


  !> @brief Input structure for convergence check

  !> @brief Output structure for convergence check
  TYPE, PUBLIC :: PH_Cont_ConvergenceCheck_Arg
    REAL(wp) :: residual                   ! [IN]
    REAL(wp) :: tolerance                   ! [IN]
    INTEGER(i4) :: max_iterations                   ! [IN]
    LOGICAL :: converged                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ConvergenceCheck_Arg


  !> @brief Input structure for search pairs

  !> @brief Output structure for search pairs
  TYPE, PUBLIC :: PH_Cont_SearchPairs_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_SearchPairs_Arg


  !> @brief Input structure for detect penetration

  !> @brief Output structure for detect penetration
  TYPE, PUBLIC :: PH_Cont_DetectPenetration_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_DetectPenetration_Arg


  !> @brief Input structure for calculate gap

  !> @brief Output structure for calculate gap
  TYPE, PUBLIC :: PH_Cont_CalculateGap_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_CalculateGap_Arg


  !> @brief Input structure for apply constraints

  !> @brief Output structure for apply constraints
  TYPE, PUBLIC :: PH_Cont_ApplyConstraints_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ApplyConstraints_Arg


  !> @brief Input structure for update friction

  !> @brief Output structure for update friction
  TYPE, PUBLIC :: PH_Cont_UpdateFriction_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_UpdateFriction_Arg


  ! ==========================================================================
  ! EXTENDED PROPERTIES TYPES (Industrial/Advanced Features)
  ! ==========================================================================
    
  ! ==========================================================================
  ! ABAQUS CONTACT INTERFACE ALGO TYPES (Phase 5 Enhancement)
  ! ==========================================================================
    
  !> @brief UINTER algorithm parameters
  TYPE, PUBLIC :: PH_Contact_UINTER_Algo
    INTEGER(i4) :: max_iter   = 20_i4
    REAL(wp)    :: tol_stress = 1.0e-8_wp
    LOGICAL     :: thermal    = .FALSE.   ! include thermal flux
    LOGICAL     :: symmetric  = .TRUE.    ! symmetric contact stiffness
  END TYPE PH_Contact_UINTER_Algo
  
  !> @brief VUINTER vectorised algorithm parameters
  TYPE, PUBLIC :: PH_Contact_VUINTER_Algo
    INTEGER(i4) :: nblock_max = 512_i4
    LOGICAL     :: thermal    = .FALSE.
    REAL(wp)    :: tol_stress = 1.0e-8_wp
  END TYPE PH_Contact_VUINTER_Algo
  
  !> @brief GAPCON thermal contact conductance algorithm
  TYPE, PUBLIC :: PH_Contact_GAPCON_Algo
    REAL(wp)    :: h_ref      = 0.0_wp   ! reference conductance
    LOGICAL     :: pressure_dep = .FALSE. ! pressure-dependent conductance
    INTEGER(i4) :: interp     = 0_i4     ! 0=step, 1=linear interpolation
  END TYPE PH_Contact_GAPCON_Algo
  
  !> @brief GAPUNIT radiation algorithm parameters
  TYPE, PUBLIC :: PH_Contact_GAPUNIT_Algo
    REAL(wp)    :: emissivity = 0.0_wp  ! emissivity coefficient
    REAL(wp)    :: boltzmann  = 5.67e-8_wp ! Stefan-Boltzmann
    LOGICAL     :: view_factor= .FALSE.  ! use view factor
  END TYPE PH_Contact_GAPUNIT_Algo
  
  !> @brief Friction model specification (extended properties)
  TYPE, PUBLIC :: PH_Cont_Friction_Model
      INTEGER(i4) :: model_type = 1  ! 1=Coulomb, 2=Tresca, 3=Rate-dependent, 4=Viscoelastic
      REAL(wp) :: mu_static = ZERO   ! Static friction coef
      REAL(wp) :: mu_dynamic = ZERO  ! Dynamic friction coef
      REAL(wp) :: mu_temperature = ZERO  ! Temperature-dependent factor
      REAL(wp) :: critical_slip_velocity = ZERO  ! Transition velocity
      REAL(wp) :: viscosity = ZERO   ! Viscous friction parameter
      REAL(wp) :: regularization_parameter = ZERO  ! Friction regularization
      LOGICAL :: stick_slip_transition = .TRUE.
      LOGICAL :: rate_dependency = .FALSE.
  END TYPE PH_Cont_Friction_Model
  
  !> @brief Thermal contact properties
  TYPE, PUBLIC :: PH_Cont_Thermal_Properties
      REAL(wp) :: thermal_conductivity = ZERO
      REAL(wp) :: thermal_conductance = ZERO
      REAL(wp) :: heat_capacity = ZERO
      REAL(wp) :: thermal_expansion = ZERO
      REAL(wp) :: interface_thermal_resistance = ZERO
      REAL(wp) :: contact_temperature = ZERO
      REAL(wp) :: heat_flux = ZERO
      LOGICAL :: thermal_contact_enabled = .FALSE.
      LOGICAL :: temperature_dependent_friction = .FALSE.
  END TYPE PH_Cont_Thermal_Properties
  
  !> @brief Dynamic contact properties
  TYPE, PUBLIC :: PH_Cont_Dynamic_Properties
      REAL(wp) :: damping_coefficient = ZERO
      REAL(wp) :: restitution_coeff = ZERO
      REAL(wp) :: impact_velocity_threshold = ZERO
      REAL(wp) :: effective_mass = ZERO
      REAL(wp) :: contact_time = ZERO
      LOGICAL :: impact_detection = .FALSE.
      LOGICAL :: energy_dissipation = .TRUE.
  END TYPE PH_Cont_Dynamic_Properties
  
  !> @brief Contact optimization parameters
  TYPE, PUBLIC :: PH_Cont_Optimization_Params
      LOGICAL :: adaptive_penalty = .TRUE.
      LOGICAL :: adaptive_friction = .TRUE.
      REAL(wp) :: penalty_growth_factor = 2.0_wp
      REAL(wp) :: penalty_reduction_factor = 0.5_wp
      REAL(wp) :: convergence_acceleration = 1.0_wp
      INTEGER(i4) :: optimization_strategy = 1  ! 1=conjugate_gradient, 2=Newton, 3=quasi-Newton
  END TYPE PH_Cont_Optimization_Params

  ! ==========================================================================
  ! STRUCTURED INTERFACE TYPES FOR LEGACY API WRAPPERS
  ! ==========================================================================
  
  !> @brief Input structure for penetration algorithm (structured interface)
  !! @details Encapsulates slave/master coordinates and node counts for penetration detection
  !!   Theory: Penetration occurs when g < 0, where g = (x_slave - x_master)·n
  
  !> @brief Output structure for penetration algorithm (structured interface)
  TYPE, PUBLIC :: PH_Cont_Penetration_Algo_Arg
    INTEGER(i4) :: num_slave_nodes  ! Number of slave nodes                   ! [IN]
    INTEGER(i4) :: num_master_nodes  ! Number of master nodes                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Penetration_Algo_Arg

  
  !> @brief Input structure for friction algorithm (structured interface)
  !! @details Encapsulates slip velocity and time step for friction force computation
  !! Theory: Coulomb friction |τ| ?μ·σ_n, τ = -μ·σ_n·(v_slip/|v_slip|) when sliding
  
  !> @brief Output structure for friction algorithm (structured interface)
  TYPE, PUBLIC :: PH_Cont_Friction_Algo_Arg
    REAL(wp) :: slip_magnitude  ! Slip magnitude ||v_slip||                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Friction_Algo_Arg

  
  !> @brief Input structure for thermal contact algorithm (structured interface)
  !! @details Encapsulates temperatures and contact pressure for thermal contact computation
  !!   Theory: Heat flux q = h·(T_slave - T_master) where h is thermal contact conductance
  
  !> @brief Output structure for thermal contact algorithm (structured interface)
  TYPE, PUBLIC :: PH_Cont_Thermal_Contact_Arg
    REAL(wp) :: temperature_slave  ! Slave temperature T_slave                   ! [IN]
    REAL(wp) :: temperature_master  ! Master temperature T_master                   ! [IN]
    REAL(wp) :: contact_pressure  ! Contact pressure σ_n                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Thermal_Contact_Arg

  
  !> @brief Input structure for dynamic contact algorithm (structured interface)
  !! @details Encapsulates relative velocity, contact area, and time step for dynamic contact
  !!   Theory: Impact force F = m·a, contact damping F_damp = c·v
  
  !> @brief Output structure for dynamic contact algorithm (structured interface)
  TYPE, PUBLIC :: PH_Cont_Dynamic_Contact_Arg
    REAL(wp) :: contact_area  ! Contact area A                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_Dynamic_Contact_Arg

  
  !> @brief Input structure for algorithm framework implementation (structured interface)
  !! @details Encapsulates gap, normal vector, relative velocity, and time step
  !! Theory: Gap function g, normal vector n ?ℝ^3, relative velocity v_rel ?ℝ^3, time step Δt
  
  !> @brief Output structure for algorithm framework implementation (structured interface)
  TYPE, PUBLIC :: PH_Cont_AlgorithmFramework_Impl_Arg
    REAL(wp) :: gap  ! Gap function g                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_AlgorithmFramework_Impl_Arg

  
  !> @brief Input structure for compute tangent vectors (structured interface)
  !! @details Encapsulates normal vector for tangent vector computation
  !! Theory: Computes orthogonal tangent vectors t ? t ? ?ℝ^3 such that n·t ?= 0, n·t ?= 0, t₁·t ?= 0
  
  !> @brief Output structure for compute tangent vectors (structured interface)
  TYPE, PUBLIC :: PH_Cont_ComputeTangentVectors_Arg
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeTangentVectors_Arg

  
  !> @brief Input structure for compute contact forces (structured interface)
  !! @details Encapsulates slip velocity, magnitude, temperature factor, and time step
  !!   Theory: Contact forces F_n = κ·max(0, -g)·n, F_t = f(v_slip, μ, σ_n)
  
  !> @brief Output structure for compute contact forces (structured interface)
  TYPE, PUBLIC :: PH_Cont_ComputeContactForces_Arg
    REAL(wp) :: slip_magnitude  ! Slip magnitude ||v_slip||                   ! [IN]
    REAL(wp) :: temperature_factor  ! Temperature effect factor                   ! [IN]
    REAL(wp) :: dt  ! Time step Δt                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeContactForces_Arg

  
  !> @brief Input structure for apply impact response (structured interface)
  !! @details Encapsulates impact energy for dynamic contact response
  !!   Theory: Impact energy E_impact = 0.5·m·v², impulse I = m·v·e where e is restitution coefficient
  
  !> @brief Output structure for apply impact response (structured interface)
  TYPE, PUBLIC :: PH_Cont_ApplyImpactResponse_Arg
    REAL(wp) :: impact_energy  ! Impact energy E_impact                   ! [IN]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ApplyImpactResponse_Arg

  
  !> @brief Input structure for compute temperature effect (structured interface)
  !! @details Encapsulates interface temperature for thermal effect computation
  
  !> @brief Output structure for compute temperature effect (structured interface)
  TYPE, PUBLIC :: PH_Cont_ComputeTemperatureEffect_Arg
    REAL(wp) :: temperature  ! Interface temperature T                   ! [IN]
    REAL(wp) :: effect_factor  ! Temperature effect factor                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Cont_ComputeTemperatureEffect_Arg


  ! ==========================================================================
  ! CONTACT PAIR DESCRIPTION TYPES (Phase 3 Enhancement)
  ! ==========================================================================
  
  !> @brief BVH tree node for contact search acceleration
  TYPE :: PH_Contact_BVH_Node
    REAL(wp) :: bbox_min(3)                    ! Bounding box minimum
    REAL(wp) :: bbox_max(3)                    ! Bounding box maximum
    INTEGER(i4) :: first_primitive = 0_i4      ! First primitive index
    INTEGER(i4) :: n_primitives = 0_i4         ! Number of primitives in node
    LOGICAL :: is_leaf = .FALSE.               ! Leaf node flag
    TYPE(PH_Contact_BVH_Node), POINTER :: left => NULL()
    TYPE(PH_Contact_BVH_Node), POINTER :: right => NULL()
  END TYPE PH_Contact_BVH_Node
  
  !> @brief Contact surface descriptor
  !! Defines master or slave surface geometry
  TYPE, PUBLIC :: PH_Contact_Surface_Desc
    INTEGER(i4) :: surface_id = 0_i4           ! Unique surface ID
    CHARACTER(len=64) :: surface_name = ''     ! Surface name (from L3)
    
    !-- Surface topology
    INTEGER(i4) :: n_nodes = 0_i4              ! Number of nodes on surface
    INTEGER(i4) :: n_segments = 0_i4           ! Number of surface segments
    INTEGER(i4), ALLOCATABLE :: node_ids(:)    ! Node IDs on surface
    INTEGER(i4), ALLOCATABLE :: segment_conn(:,:) ! Segment connectivity
    
    !-- Surface geometry (populated from L3)
    REAL(wp), ALLOCATABLE :: coords(:,:)       ! Nodal coordinates (3 x n_nodes)
    REAL(wp), ALLOCATABLE :: normals(:,:)      ! Nodal normals (3 x n_nodes)
    
    !-- Search structure (BVH/Octree pre-built)
    INTEGER(i4) :: search_structure_type = 1_i4 ! 1=None, 2=BVH, 3=Octree
    TYPE(PH_Contact_BVH_Node), POINTER :: bvh_root => NULL()
    ! NOTE: BVH build/query ops live in PH_ContBVHBuilder_Algo / PH_ContBVHQuery_Algo
  END TYPE PH_Contact_Surface_Desc
  
  !> @brief Contact pair descriptor (master-slave pair with properties)
  !! Complete description of a single contact interaction
  TYPE, PUBLIC :: PH_Contact_Pair_Desc
    INTEGER(i4) :: pair_id = 0_i4              ! Unique contact pair ID
    CHARACTER(len=64) :: pair_name = ''        ! Contact pair name
    
    !-- Master-Slave assignment
    TYPE(PH_Contact_Surface_Desc) :: master_surface  ! Master surface
    TYPE(PH_Contact_Surface_Desc) :: slave_surface   ! Slave surface
    
    !-- Contact algorithm parameters (from L3 Desc)
    TYPE(PH_Cont_Desc) :: algo_params
    
    !-- Contact enforcement method
    INTEGER(i4) :: enforcement_method = 1_i4   ! 1=Penalty, 2=Lagrange, 3=AugLag
    REAL(wp) :: penalty_normal = 1.0e6_wp      ! Normal penalty stiffness
    REAL(wp) :: penalty_tangential = 1.0e6_wp  ! Tangential penalty stiffness
    
    !-- Friction model
    INTEGER(i4) :: friction_model = 1_i4       ! 1=Coulomb, 2=Tresca, 3=User
    REAL(wp) :: friction_coeff_static = 0.0_wp ! Static friction coefficient
    REAL(wp) :: friction_coeff_dynamic = 0.0_wp ! Dynamic friction coefficient
    
    !-- Contact detection settings
    REAL(wp) :: search_tolerance = 1.0e-6_wp   ! Geometric tolerance
    LOGICAL :: finite_sliding_flag = .TRUE.    ! Finite sliding enabled
    
    !-- Thermal contact (optional)
    LOGICAL :: thermal_contact = .FALSE.       ! Thermal coupling enabled
    REAL(wp) :: thermal_conductance = 0.0_wp   ! Gap-dependent conductance
    
    !-- Damage/Failure (optional)
    LOGICAL :: enable_damage = .FALSE.         ! Contact damage evolution
    REAL(wp) :: damage_threshold = 1.0e10_wp   ! Damage initiation threshold
  END TYPE PH_Contact_Pair_Desc
  
  ! ==========================================================================
  ! EVAL ARG TYPE: PH_Cont_Eval_Arg — bundles Contact Execute IO
  ! KIND: Arg (SIO coupling bundle for PH_Cont_Execute pipeline)
  ! ==========================================================================

  !> @brief Contact evaluation argument bundle for PH_Cont_Execute pipeline.
  !! Carries per-pair I/O data through S1→S2→S3→S4 steps.
  TYPE, PUBLIC :: PH_Cont_Eval_Arg
    !-- IN: Contact pair topology
    INTEGER(i4) :: n_slave_nodes  = 0_i4        ! [IN] Number of slave nodes
    INTEGER(i4) :: n_master_faces = 0_i4        ! [IN] Number of master faces
    REAL(wp), ALLOCATABLE :: slave_coords(:,:)  ! [IN] Slave node coords (3, n_slave)
    REAL(wp), ALLOCATABLE :: master_coords(:,:,:) ! [IN] Master face coords (3, max_face_nodes, n_faces)
    !-- INOUT: Detected pairs from S1
    INTEGER(i4) :: n_active_pairs = 0_i4        ! [INOUT] Number of active contact pairs
    INTEGER(i4), ALLOCATABLE :: pair_slave(:)   ! [INOUT] Slave node IDs for active pairs
    INTEGER(i4), ALLOCATABLE :: pair_master(:)  ! [INOUT] Master face IDs for active pairs
    !-- INOUT: Gap/penetration from S2
    REAL(wp), ALLOCATABLE :: gap(:)             ! [INOUT] Gap values per active pair
    REAL(wp), ALLOCATABLE :: normal(:,:)        ! [INOUT] Normal vectors (3, n_active)
    !-- INOUT: Forces from S3
    REAL(wp), ALLOCATABLE :: f_contact(:,:)     ! [INOUT] Contact force vectors (3, n_slave)
    !-- OUT: Assembled contributions for S4
    REAL(wp), ALLOCATABLE :: K_contact(:,:)     ! [OUT] Contact stiffness (sparse CSR or dense)
    REAL(wp), ALLOCATABLE :: rhs_contact(:)     ! [OUT] Contact RHS contribution
  END TYPE PH_Cont_Eval_Arg

  ! ==========================================================================
  ! PROCEDURE STRATEGY INTERFACE: SearchStrategy
  ! PURPOSE: Abstract interface for contact search algorithm (NTS/Mortar/BVH)
  ! ==========================================================================

  ABSTRACT INTERFACE
    SUBROUTINE PH_Cont_SearchStrategy_Ifc(desc, state, arg, status)
      IMPORT :: PH_Cont_Desc, PH_Cont_State, PH_Cont_Eval_Arg, i4
      TYPE(PH_Cont_Desc),     INTENT(IN)    :: desc
      TYPE(PH_Cont_State),    INTENT(INOUT) :: state
      TYPE(PH_Cont_Eval_Arg), INTENT(INOUT) :: arg
      INTEGER(i4),            INTENT(OUT)   :: status
    END SUBROUTINE
  END INTERFACE

  ! ==========================================================================
  ! PUBLIC TYPE EXPORTS
  ! ==========================================================================
  ! PH_Cont_Friction_Model, PH_Cont_Thermal_Properties,
  ! PH_Cont_Dynamic_Properties, PH_Cont_Optimization_Params
  ! are referenced in PUBLIC at module top; dead aliases removed.

  ! ==========================================================================
  ! CONTACT STATUS AND METHOD CONSTANTS
  ! ==========================================================================

  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_OPEN   = 0
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_CLOSED = 1
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_STICK  = 2
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_SLIP   = 3

  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_METHOD_PENALTY   = 1
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_METHOD_LAGRANGE  = 2
  INTEGER(i4), PARAMETER, PUBLIC :: PH_CONT_METHOD_AUGMENTED = 3

END MODULE PH_Cont_Def
