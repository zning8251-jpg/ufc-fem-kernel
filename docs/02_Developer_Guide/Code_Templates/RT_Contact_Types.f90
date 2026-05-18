!===============================================================================
! Module: RT_Contact_Types                                       [Template v1.0]
! Layer:  L5_RT — Runtime Layer
! Domain: Contact — Contact algorithm runtime coordination types
!
! Purpose:
!   Defines types for contact pair management, contact force assembly,
!   and friction state tracking. Coordinates with L4_PH for actual
!   contact integration and search algorithms.
!
! Type catalogue (4 TYPEs):
!   RT_Contact_Desc  – Contact pair definitions (cold, read-only)
!   RT_Contact_State – Contact status and forces (warm, per-iteration)
!   RT_Contact_Algo  – Contact discretization algorithm (optional)
!   RT_Contact_Ctx   – Gap/temporary variables (hot path)
!
! Layer dependency:
!   USE IF_Prec  (wp, i4)
!   USE IF_Err_Brg (ErrorStatusType, init_error_status, IF_STATUS_*, IF_ERROR_CODE_*)
!===============================================================================
MODULE RT_Contact_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: RT_Contact_Desc
  PUBLIC :: RT_Contact_State
  PUBLIC :: RT_Contact_Algo
  PUBLIC :: RT_Contact_Ctx
  
  !-- Contact type constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_HARD     = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_SOFT     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_EXPO     = 2_i4  ! migrated
  
  !-- Friction model constants
  RT_FRICTION_NONE  ! DEPRECATED alias: FRICTION_NONE 0_i4
  RT_FRICTION_COULOMB  ! DEPRECATED alias: FRICTION_COULOMB 1_i4
  RT_FRICTION_VISCOUS  ! DEPRECATED alias: FRICTION_VISCOUS 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_FRICTION_FRICTION_ROUGH   = 3_i4  ! migrated
  
  !-- Pair status constants
  RT_PAIR_OPEN  ! DEPRECATED alias: PAIR_OPEN 0_i4
  RT_PAIR_CLOSED  ! DEPRECATED alias: PAIR_CLOSED 1_i4
  RT_PAIR_SLIDING  ! DEPRECATED alias: PAIR_SLIDING 2_i4
  RT_PAIR_STICKING  ! DEPRECATED alias: PAIR_STICKING 3_i4
  
  !-- Discretization method constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_DISC_NODE_TO_SURF = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_DISC_SURF_TO_SURF = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_DISC_MORTAR       = 2_i4  ! migrated
  
  !-- Constraint method constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_CONSTRAINT_PENALTY      = 0_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_CONSTRAINT_LAGRANGE     = 1_i4  ! migrated
  INTEGER(i4), PARAMETER, PUBLIC :: RT_CONTACT_CONTACT_CONSTRAINT_AUG_LAGRANGE = 2_i4  ! migrated
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_Desc — Contact pair configuration (cold, read-only)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Desc
    !-- Contact pair definitions
    INTEGER(i4) :: n_contact_pairs = 0
    INTEGER(i4), POINTER :: master_surf_ids(:) => NULL()
    INTEGER(i4), POINTER :: slave_surf_ids(:) => NULL()
    
    !-- Contact type per pair
    INTEGER(i4), POINTER :: contact_types(:) => NULL()    ! CONTACT_* constants
    INTEGER(i4), POINTER :: friction_models(:) => NULL()  ! FRICTION_* constants
    
    !-- Contact parameters
    REAL(wp), POINTER :: friction_coeffs(:) => NULL()
    REAL(wp), POINTER :: penalty_stiffness(:) => NULL()
    REAL(wp), POINTER :: clearance(:) => NULL()
    
    !-- Search parameters
    REAL(wp)    :: global_search_tol = 1.0e-6_wp
    REAL(wp)    :: local_search_tol = 1.0e-8_wp
    REAL(wp)    :: search_radius_factor = 1.1_wp
    
    !-- Adjustment options
    LOGICAL     :: adjust_slave_nodes = .FALSE.
    REAL(wp)    :: adjust_tolerance = 1.0e-6_wp
    
  CONTAINS
    PROCEDURE :: Init => Contact_Desc_Init
    PROCEDURE :: AddContactPair => Contact_Desc_AddPair
    PROCEDURE :: SetFriction => Contact_Desc_SetFriction
    PROCEDURE :: Finalize => Contact_Desc_Finalize
  END TYPE RT_Contact_Desc
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_State — Contact runtime state (warm, per-iteration)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_State
    !-- Pair status tracking
    LOGICAL, POINTER :: pair_active(:) => NULL()
    INTEGER(i4), POINTER :: pair_status(:) => NULL()  ! PAIR_* constants
    INTEGER(i4) :: n_active_pairs = 0
    
    !-- Contact forces
    REAL(wp), POINTER :: f_contact(:) => NULL()
    REAL(wp)    :: total_contact_force = 0.0_wp
    REAL(wp)    :: max_contact_force = 0.0_wp
    
    !-- Penetration/gap
    REAL(wp), POINTER :: penetration(:) => NULL()
    REAL(wp)    :: max_penetration = 0.0_wp
    REAL(wp)    :: avg_penetration = 0.0_wp
    REAL(wp)    :: max_gap = 0.0_wp
    
    !-- Friction state
    REAL(wp), POINTER :: friction_force(:) => NULL()
    LOGICAL, POINTER :: is_sticking(:) => NULL()
    INTEGER(i4) :: n_sticking = 0
    INTEGER(i4) :: n_sliding = 0
    
    !-- Statistics
    INTEGER(i4) :: n_open_pairs = 0
    INTEGER(i4) :: n_closed_pairs = 0
    REAL(wp)    :: contact_energy = 0.0_wp
    
  CONTAINS
    PROCEDURE :: Reset => Contact_State_Reset
    PROCEDURE :: UpdateStatus => Contact_State_UpdateStatus
    PROCEDURE :: ComputeContactForce => Contact_State_ComputeForce
    PROCEDURE :: AggregateStatistics => Contact_State_AggregateStats
  END TYPE RT_Contact_State
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_Algo — Contact algorithm (optional, cold)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Algo
    !-- Contact discretization
    INTEGER(i4) :: discretization_method = CONTACT_DISC_NODE_TO_SURF
    
    !-- Constraint enforcement
    INTEGER(i4) :: constraint_method = CONTACT_CONSTRAINT_PENALTY
    REAL(wp)    :: penalty_scale_factor = 1.0_wp
    REAL(wp)    :: lagrange_multiplier_init = 0.0_wp
    
    !-- Friction algorithm
    INTEGER(i4) :: friction_algorithm = 0_i4  ! 0=Elastic/1=Elasto-plastic/2=Rate-dep
    REAL(wp)    :: friction_decay_coeff = 0.0_wp
    REAL(wp)    :: slip_tolerance = 1.0e-8_wp
    
    !-- Search strategy
    INTEGER(i4) :: search_frequency = 10_i4  ! Re-search every N increments
    LOGICAL     :: use_global_search = .TRUE.
    LOGICAL     :: use_bucket_sort = .TRUE.
    
    !-- Stabilization
    LOGICAL     :: use_damping = .FALSE.
    REAL(wp)    :: damping_factor = 0.05_wp
    
  CONTAINS
    PROCEDURE :: Init => Contact_Algo_Init
    PROCEDURE :: SelectConstraintMethod => Contact_Algo_SelectConstraint
    PROCEDURE :: ConfigureFriction => Contact_Algo_ConfigureFriction
    PROCEDURE :: ConfigureSearch => Contact_Algo_ConfigureSearch
  END TYPE RT_Contact_Algo
  
  !-----------------------------------------------------------------------------
  ! RT_Contact_Ctx — Hot path context (temporary, no allocation)
  !-----------------------------------------------------------------------------
  TYPE, PUBLIC :: RT_Contact_Ctx
    !-- Temporary contact variables
    REAL(wp)    :: gap_distance = 0.0_wp
    REAL(wp)    :: penetration_depth = 0.0_wp
    REAL(wp)    :: contact_pressure = 0.0_wp
    
    !-- Normal/tangent vectors (stack space)
    REAL(wp)    :: normal_vector(3) = 0.0_wp
    REAL(wp)    :: tangent_vector(3,2) = 0.0_wp
    REAL(wp)    :: slip_direction(3) = 0.0_wp
    
    !-- Integration point variables
    REAL(wp)    :: gp_xi = 0.0_wp
    REAL(wp)    :: gp_eta = 0.0_wp
    REAL(wp)    :: gp_zeta = 0.0_wp
    REAL(wp)    :: shape_master(4) = 0.0_wp
    REAL(wp)    :: shape_slave(4) = 0.0_wp
    
    !-- Closest point projection
    REAL(wp)    :: closest_point_x = 0.0_wp
    REAL(wp)    :: closest_point_y = 0.0_wp
    REAL(wp)    :: closest_point_z = 0.0_wp
    
    !-- Work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: temp_force(:) => NULL()
    REAL(wp), POINTER :: temp_disp(:) => NULL()
    
    !-- Node/surface indices
    INTEGER(i4) :: master_node_id = 0
    INTEGER(i4) :: slave_node_id = 0
    INTEGER(i4) :: contact_elem_id = 0
    
  CONTAINS
    PROCEDURE :: AttachToState => Contact_Ctx_AttachToState
    PROCEDURE :: ClearTemporaries => Contact_Ctx_ClearTemporaries
    PROCEDURE :: Detach => Contact_Ctx_Detach
  END TYPE RT_Contact_Ctx
  
END MODULE RT_Contact_Types
