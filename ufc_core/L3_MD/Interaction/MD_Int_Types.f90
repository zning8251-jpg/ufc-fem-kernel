!======================================================================
! MODULE:  MD_Int_Types
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Def
! BRIEF:   Foundation types, constants, and parameters for contact
!          mechanics. Extracted from original MD_Int_API monolith.
!          Core data types: nodes, segments, surfaces, pairs, search
!          structures, friction, and SIO argument bundles.
! STATUS:  FOUR-TYPE-REFACTORED
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Types
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Field_Mgr, ONLY: MD_NodeDisp
  USE MD_Int_ContactArgs, ONLY: MD_IC_ContactAddK_Arg,          &
      MD_IC_ContactAddForce_Arg, MD_IC_ContactAssemTriplets_Arg, &
      MD_IC_ContactInit_Arg, MD_IC_ContactUpdateGeom_Arg,        &
      MD_IC_ContactEvalFace_Arg
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Constants: Dimension enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_DIM_2D        = 16_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_DIM_3D        = 17_i4

  !--------------------------------------------------------------------
  ! Constants: Contact type enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CTYPE_NODE_TO = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CTYPE_SURFACE = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CTYPE_SELF    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CTYPE_GENERAL = 4_i4

  !--------------------------------------------------------------------
  ! Constants: Contact state enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CSTATE_SEPARATE = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CSTATE_STICKING = 20_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CSTATE_SLIDING  = 30_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CSTATE_INVALID  = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CSTATE_INITIAL  = 0_i4

  !--------------------------------------------------------------------
  ! Constants: Enforcement method enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ENFORCE_PENALTY = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ENFORCE_LAGRANG = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ENFORCE_AUG_LAG = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_ENFORCE_DIRECT  = 4_i4

  !--------------------------------------------------------------------
  ! Constants: Friction model enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_NONE     = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_COULOMB  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_STICK    = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_VELOCITY = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_PRESSURE = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_EXPONENT = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FMODEL_USER     = 99_i4

  !--------------------------------------------------------------------
  ! Constants: Sliding type enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_SLIDING_SMALL  = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_SLIDING_FINITE = 2_i4

  !--------------------------------------------------------------------
  ! Constants: Normal behavior enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_NORMAL_HARD     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_NORMAL_EXPONENT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_NORMAL_LINEAR   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_NORMAL_TABULAR  = 4_i4

  !--------------------------------------------------------------------
  ! Constants: Pressure-overclosure enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_POVRCL_HARD     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_POVRCL_EXPONENT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_POVRCL_LINEAR   = 3_i4

  !--------------------------------------------------------------------
  ! Constants: Coordinate system enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_COORD_AXISYM    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_COORD_PLANE_STR = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_COORD_PLANE_STS = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_COORD_3D        = 3_i4

  !--------------------------------------------------------------------
  ! Constants: Algorithm selection enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CALGO_PENALTY   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CALGO_LAGRANGE  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CALGO_AUG_LAG   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_CALGO_DIRECT    = 4_i4

  !--------------------------------------------------------------------
  ! Constants: Friction algorithm enums
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FALGO_COULOMB   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FALGO_STICK     = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_FALGO_REGULARIZ = 3_i4

  !--------------------------------------------------------------------
  ! Constants: Numerical tolerances
  !--------------------------------------------------------------------
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_GEOM_TOL       = 1.0E-12_wp
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_NEWTON   = 20_i4
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_NEWTON_TOL     = 1.0E-10_wp
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_SEARCH_TOL     = 1.0E-10_wp
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_CAND     = 10_i4
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_FRICTION_TOL   = 1.0E-8_wp
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_SLIP_VEL_TOL   = 1.0E-6_wp
  REAL(wp), PARAMETER, PUBLIC :: MD_INT_STIFF_TOL      = 1.0E-30_wp
  INTEGER(i4), PARAMETER, PUBLIC :: MD_INT_MAX_ALM_ITER = 20_i4


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ContNode_State
  ! KIND: State
  ! DESC: Contact node runtime state (coordinates, gap, forces)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ContNode_State
    INTEGER(i4) :: global_id       = 0_i4              ! [in]    Global node ID
    INTEGER(i4) :: local_id        = 0_i4              ! [in]    Local node ID
    INTEGER(i4) :: state           = MD_INT_CSTATE_INITIAL ! [inout] Contact state
    INTEGER(i4) :: matched_segment = 0_i4              ! [inout] Matched segment ID
    INTEGER(i4) :: dof_y           = 0_i4              ! [in]    DOF Y index
    INTEGER(i4) :: dof_z           = 0_i4              ! [in]    DOF Z index
    INTEGER(i4) :: dof_x           = 0_i4              ! [in]    DOF X index
    INTEGER(i4) :: skew_flag       = 0_i4              ! [in]    Skew system flag
    LOGICAL     :: was_sliding     = .FALSE.           ! [inout] Previous sliding flag
    LOGICAL     :: active          = .TRUE.            ! [inout] Active flag
    REAL(wp)    :: coords(3)       = 0.0_wp            ! [inout] Current coordinates
    REAL(wp)    :: coords_init(3)  = 0.0_wp            ! [in]    Initial coordinates
    REAL(wp)    :: gap              = 0.0_wp            ! [inout] Normal gap
    REAL(wp)    :: penetration      = 0.0_wp            ! [inout] Penetration depth
    REAL(wp)    :: normal(3)       = 0.0_wp            ! [inout] Normal vector
    REAL(wp)    :: tangent(3)      = 0.0_wp            ! [inout] Tangent vector
    REAL(wp)    :: xi_local(2)     = 0.0_wp            ! [inout] Local parametric coords
    REAL(wp)    :: force_n          = 0.0_wp            ! [inout] Normal force
    REAL(wp)    :: force_t(3)      = 0.0_wp            ! [inout] Tangential force
    REAL(wp)    :: slip             = 0.0_wp            ! [inout] Accumulated slip
    REAL(wp)    :: beta             = 0.0_wp            ! [inout] Augmented multiplier
    REAL(wp)    :: lambda           = 0.0_wp            ! [inout] Lagrange multiplier
  CONTAINS
    PROCEDURE, PUBLIC :: Destroy => MD_Int_ContNode_Destroy
  END TYPE MD_Int_ContNode_State


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_AlgoCtrl_Algo
  ! KIND: Algo
  ! DESC: Contact algorithm control parameters
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_AlgoCtrl_Algo
    INTEGER(i4) :: algorithm_type  = MD_INT_CALGO_PENALTY  ! [in] Algorithm type
    INTEGER(i4) :: friction_model  = MD_INT_FALGO_COULOMB  ! [in] Friction algorithm
    REAL(wp)    :: penalty_stiffne = 1.0e6_wp              ! [in] Normal penalty stiffness
    REAL(wp)    :: penalty_tangent = 1.0e5_wp              ! [in] Tangent penalty stiffness
    REAL(wp)    :: friction_coeffi = 0.3_wp                ! [in] Friction coefficient
    REAL(wp)    :: tolerance_gap   = 1.0e-6_wp             ! [in] Gap tolerance
    REAL(wp)    :: tolerance_slip  = 1.0e-8_wp             ! [in] Slip tolerance
    LOGICAL     :: use_adaptive_pe = .TRUE.                ! [in] Adaptive penalty flag
    LOGICAL     :: include_frictio = .TRUE.                ! [in] Include friction flag
  END TYPE MD_Int_AlgoCtrl_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ForceRes_State
  ! KIND: State
  ! DESC: Contact force results (normal, tangent, Lagrange multipliers)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ForceRes_State
    REAL(wp), ALLOCATABLE :: normal_forces(:)               ! [out] Normal forces
    REAL(wp), ALLOCATABLE :: tangent_forces(:,:)             ! [out] Tangential forces
    REAL(wp), ALLOCATABLE :: lagrange_multip(:)              ! [out] Lagrange multipliers
    INTEGER(i4)           :: nActiveCont    = 0_i4          ! [out] Active contact count
    REAL(wp)              :: total_normal_fo = 0.0_wp       ! [out] Total normal force
    REAL(wp)              :: total_friction  = 0.0_wp       ! [out] Total friction force
  CONTAINS
    PROCEDURE, PUBLIC :: Destroy => MD_Int_ForceRes_Destroy
    PROCEDURE, PUBLIC :: Init    => MD_Int_ForceRes_Init
  END TYPE MD_Int_ForceRes_State


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_AlgoSpec_Algo
  ! KIND: Algo
  ! DESC: Contact algorithm specification (method, search, stabilization)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_AlgoSpec_Algo
    CHARACTER(LEN=80) :: name              = ''            ! [in] Algorithm name
    INTEGER(i4)       :: method            = 0_i4          ! [in] Enforcement method
    INTEGER(i4)       :: frictionModel     = 0_i4          ! [in] Friction model
    LOGICAL           :: regularize_frict  = .FALSE.       ! [in] Regularize friction
    INTEGER(i4)       :: searchAlgo        = 0_i4          ! [in] Search algorithm
    REAL(wp)          :: searchRadius      = 0.0_wp        ! [in] Search radius
    LOGICAL           :: use_stabilization = .FALSE.       ! [in] Use stabilization
    REAL(wp)          :: stabFactor        = 0.0_wp        ! [in] Stabilization factor
    INTEGER(i4)       :: user_int(4)       = 0_i4          ! [in] User integer params
    REAL(wp)          :: user_real(4)      = 0.0_wp        ! [in] User real params
  END TYPE MD_Int_AlgoSpec_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_UF_AlgoSpec_Algo
  ! KIND: Algo
  ! DESC: User-function contact algorithm specification
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_UF_AlgoSpec_Algo
    CHARACTER(LEN=80) :: name              = ''            ! [in] Algorithm name
    INTEGER(i4)       :: method            = 0_i4          ! [in] Enforcement method
    INTEGER(i4)       :: frictionModel     = 0_i4          ! [in] Friction model
    LOGICAL           :: regularize_frict  = .FALSE.       ! [in] Regularize friction
    INTEGER(i4)       :: searchAlgo        = 0_i4          ! [in] Search algorithm
    REAL(wp)          :: searchRadius      = 0.0_wp        ! [in] Search radius
    LOGICAL           :: use_stabilization = .FALSE.       ! [in] Use stabilization
    REAL(wp)          :: stabFactor        = 0.0_wp        ! [in] Stabilization factor
    INTEGER(i4)       :: user_int(4)       = 0_i4          ! [in] User integer params
    REAL(wp)          :: user_real(4)      = 0.0_wp        ! [in] User real params
  END TYPE MD_Int_UF_AlgoSpec_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Context_Ctx
  ! KIND: Ctx
  ! DESC: Contact execution context (pair/increment/time tracking)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_Context_Ctx
    INTEGER(i4) :: pairId         = 0_i4                   ! [in] Contact pair ID
    INTEGER(i4) :: id             = 0_i4                   ! [in] Context ID
    INTEGER(i4) :: incId          = 0_i4                   ! [in] Increment ID
    REAL(wp)    :: time           = 0.0_wp                 ! [in] Current time
    REAL(wp)    :: lambda         = 0.0_wp                 ! [in] Load factor
    INTEGER(i4) :: interactionId  = 0_i4                   ! [in] Interaction ID
    INTEGER(i4) :: slaveSurfId    = 0_i4                   ! [in] Slave surface ID
    INTEGER(i4) :: masterSurfId   = 0_i4                   ! [in] Master surface ID
  END TYPE MD_Int_Context_Ctx


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Segment_Desc
  ! KIND: Desc
  ! DESC: Contact segment descriptor (geometry, state, pressure)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_Segment_Desc
    INTEGER(i4) :: id             = 0_i4                   ! [in]    Segment ID
    INTEGER(i4) :: surface_id     = 0_i4                   ! [in]    Parent surface ID
    INTEGER(i4) :: n_nodes        = 0_i4                   ! [in]    Node count
    INTEGER(i4) :: nodes(4)       = 0_i4                   ! [in]    Node IDs
    INTEGER(i4) :: state          = MD_INT_CSTATE_INITIAL  ! [inout] Contact state
    REAL(wp)    :: length          = 0.0_wp                 ! [out]   Segment length
    REAL(wp)    :: tangent(3)     = 0.0_wp                 ! [out]   Tangent vector
    REAL(wp)    :: normal(3)      = 0.0_wp                 ! [out]   Normal vector
    REAL(wp)    :: centroid(3)    = 0.0_wp                 ! [out]   Centroid coords
    REAL(wp)    :: jacobian(4)    = 0.0_wp                 ! [out]   Jacobian values
    REAL(wp)    :: avg_pressure    = 0.0_wp                 ! [out]   Average pressure
    REAL(wp)    :: avg_traction    = 0.0_wp                 ! [out]   Average traction
  END TYPE MD_Int_Segment_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Surface_Desc
  ! KIND: Desc
  ! DESC: Contact surface descriptor (nodes, segments, bounding box)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_Surface_Desc
    INTEGER(i4) :: id             = 0_i4                   ! [in]    Surface ID
    INTEGER(i4) :: n_nodes        = 0_i4                   ! [in]    Node count
    INTEGER(i4) :: n_segments     = 0_i4                   ! [in]    Segment count
    INTEGER(i4) :: coord_type     = MD_INT_COORD_3D        ! [in]    Coordinate type
    INTEGER(i4) :: print_flag     = 0_i4                   ! [in]    Print flag
    INTEGER(i4) :: port_flag      = 0_i4                   ! [in]    Port flag
    LOGICAL     :: is_closed      = .FALSE.                ! [in]    Closed surface
    LOGICAL     :: is_master      = .FALSE.                ! [in]    Master surface
    LOGICAL     :: is_rigid       = .FALSE.                ! [in]    Rigid body
    INTEGER(i4), ALLOCATABLE :: node_ids(:)                ! [in]    Node ID array
    INTEGER(i4), ALLOCATABLE :: dof_map(:,:)               ! [in]    DOF mapping
    REAL(wp), ALLOCATABLE    :: coords(:,:)                ! [in]    Reference coords
    REAL(wp), ALLOCATABLE    :: coords_current(:,:)        ! [inout] Current coords
    TYPE(MD_Int_Segment_Desc), ALLOCATABLE :: segments(:)  ! [inout] Segment array
    REAL(wp)    :: bbox_min(3)    = 0.0_wp                 ! [out]   Bounding box min
    REAL(wp)    :: bbox_max(3)    = 0.0_wp                 ! [out]   Bounding box max
    INTEGER(i4), ALLOCATABLE :: node_to_seg(:,:)           ! [in]    Node-to-segment map
    INTEGER(i4) :: max_seg_per_nod = 0_i4                  ! [in]    Max segments per node
  END TYPE MD_Int_Surface_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_FricParams_Algo
  ! KIND: Algo
  ! DESC: Friction parameters (Coulomb, velocity-dependent, tabular)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_FricParams_Algo
    INTEGER(i4) :: model          = MD_INT_FMODEL_COULOMB  ! [in] Friction model
    REAL(wp)    :: mu_static      = 0.0_wp                 ! [in] Static friction coeff
    REAL(wp)    :: mu_kinetic     = 0.0_wp                 ! [in] Kinetic friction coeff
    REAL(wp)    :: tolerance      = 0.01_wp                ! [in] Friction tolerance
    REAL(wp)    :: slip_rate_ref  = 1.0_wp                 ! [in] Reference slip rate
    REAL(wp)    :: decay_coeff    = 0.0_wp                 ! [in] Decay coefficient
    LOGICAL     :: velocity_depend = .FALSE.               ! [in] Velocity dependent
    LOGICAL     :: pressure_depend = .FALSE.               ! [in] Pressure dependent
    INTEGER(i4) :: n_table_points = 0_i4                   ! [in] Table point count
    REAL(wp), ALLOCATABLE :: table_velocity(:)              ! [in] Velocity table
    REAL(wp), ALLOCATABLE :: table_mu(:)                    ! [in] Friction coeff table
    REAL(wp)    :: pressure_alpha = 0.0_wp                 ! [in] Pressure exponent
    REAL(wp)    :: pressure_ref   = 1.0E6_wp               ! [in] Reference pressure
    REAL(wp)    :: bond_strength  = 0.0_wp                 ! [in] Bond strength
    REAL(wp)    :: bond_delta_f   = 0.0_wp                 ! [in] Bond force increment
    REAL(wp)    :: damage         = 0.0_wp                 ! [inout] Damage variable
    REAL(wp)    :: damping_ratio  = 0.0_wp                 ! [in] Damping ratio
    REAL(wp)    :: damping_n      = 0.0_wp                 ! [in] Normal damping
    REAL(wp)    :: damping_t      = 0.0_wp                 ! [in] Tangent damping
  END TYPE MD_Int_FricParams_Algo


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_PairDef_Desc
  ! KIND: Desc
  ! DESC: Contact pair definition (surfaces, enforcement, penalty)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_PairDef_Desc
    INTEGER(i4) :: id              = 0_i4                  ! [in] Pair ID
    INTEGER(i4) :: master_surface  = 0_i4                  ! [in] Master surface ID
    INTEGER(i4) :: slave_surface_i = 0_i4                  ! [in] Slave surface ID
    INTEGER(i4) :: contact_type    = MD_INT_CTYPE_NODE_TO  ! [in] Contact type
    INTEGER(i4) :: enforcement_met = MD_INT_ENFORCE_PENALTY ! [in] Enforcement method
    INTEGER(i4) :: sliding_type    = MD_INT_SLIDING_FINITE ! [in] Sliding type
    INTEGER(i4) :: normal_behavior = MD_INT_NORMAL_HARD    ! [in] Normal behavior
    LOGICAL     :: active          = .TRUE.                ! [in] Active flag
    LOGICAL     :: is_self_contact = .FALSE.               ! [in] Self-contact flag
    REAL(wp)    :: penalty_normal   = 0.0_wp                ! [in] Normal penalty
    REAL(wp)    :: penalty_tangent  = 0.0_wp                ! [in] Tangent penalty
    REAL(wp)    :: penalty_scale    = 10.0_wp               ! [in] Penalty scale factor
    REAL(wp)    :: penalty_n        = 0.0_wp                ! [in] Penalty normal value
    REAL(wp)    :: penalty_t        = 0.0_wp                ! [in] Penalty tangent value
    REAL(wp)    :: adaptive_alpha_min = 1.0_wp              ! [in] Adaptive alpha min
    REAL(wp)    :: adaptive_alpha_max = 10.0_wp             ! [in] Adaptive alpha max
    REAL(wp)    :: adaptive_e_modu  = 0.0_wp                ! [in] Adaptive E modulus
    REAL(wp)    :: adaptive_h_min   = 0.0_wp                ! [in] Adaptive h min
    REAL(wp)    :: penalty_ratio_t  = 0.1_wp                ! [in] Penalty tangent ratio
    REAL(wp)    :: penetration_tol  = 1.0E-10_wp            ! [in] Penetration tolerance
    REAL(wp)    :: max_penetration  = 0.0_wp                ! [in] Max penetration
    LOGICAL     :: use_adaptive_pe = .FALSE.               ! [in] Adaptive penalty flag
    REAL(wp)    :: aug_lagrange_to  = 1.0E-6_wp             ! [in] Aug Lagrange tol
    INTEGER(i4) :: aug_lagrange_ma = 10_i4                 ! [in] Aug Lagrange max iter
    REAL(wp)    :: search_toleranc  = 0.0_wp                ! [in] Search tolerance
    REAL(wp)    :: gap_tolerance    = 1.0E-10_wp            ! [in] Gap tolerance
    REAL(wp)    :: initial_clearan  = 0.0_wp                ! [in] Initial clearance
    TYPE(MD_Int_FricParams_Algo) :: friction                ! [in] Friction parameters
  END TYPE MD_Int_PairDef_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_Candidate_Desc
  ! KIND: Desc
  ! DESC: Contact candidate (slave node to master segment mapping)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_Candidate_Desc
    INTEGER(i4) :: slave_node      = 0_i4                  ! [in] Slave node ID
    INTEGER(i4) :: master_segment  = 0_i4                  ! [in] Master segment ID
    REAL(wp)    :: distance        = 0.0_wp                ! [out] Distance
  END TYPE MD_Int_Candidate_Desc


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_BucketGrid_Ctx
  ! KIND: Ctx
  ! DESC: Bucket grid spatial search context
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_BucketGrid_Ctx
    INTEGER(i4) :: nx = 0_i4                               ! [in] Grid X divisions
    INTEGER(i4) :: ny = 0_i4                               ! [in] Grid Y divisions
    INTEGER(i4) :: nz = 0_i4                               ! [in] Grid Z divisions
    REAL(wp)    :: origin(3)    = 0.0_wp                   ! [in] Grid origin
    REAL(wp)    :: cell_size(3) = 0.0_wp                   ! [in] Cell dimensions
    TYPE :: MD_Int_Bucket_Desc
      INTEGER(i4) :: n_items = 0_i4                        ! [inout] Item count
      INTEGER(i4), ALLOCATABLE :: item_ids(:)              ! [inout] Item ID array
    END TYPE
    TYPE(MD_Int_Bucket_Desc), ALLOCATABLE :: buckets(:,:,:) ! [inout] Bucket array
  END TYPE MD_Int_BucketGrid_Ctx


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_BVHTree_Ctx
  ! KIND: Ctx
  ! DESC: Bounding volume hierarchy tree for spatial search
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_BVHTree_Ctx
    INTEGER(i4) :: n_nodes = 0_i4                          ! [in] Tree node count
    INTEGER(i4) :: root    = 0_i4                          ! [in] Root node index
    TYPE :: MD_Int_BVHNode_Desc
      INTEGER(i4) :: id          = 0_i4                    ! [in] Node ID
      INTEGER(i4) :: left_child  = 0_i4                    ! [in] Left child index
      INTEGER(i4) :: right_child = 0_i4                    ! [in] Right child index
      INTEGER(i4) :: segment_id  = 0_i4                    ! [in] Segment ID (leaf)
      INTEGER(i4) :: first_prim  = 0_i4                    ! [in] First primitive index
      INTEGER(i4) :: n_prims     = 0_i4                    ! [in] Primitive count
      LOGICAL     :: is_leaf     = .FALSE.                 ! [in] Leaf flag
      REAL(wp)    :: bbox_min(3) = 0.0_wp                  ! [out] Bounding box min
      REAL(wp)    :: bbox_max(3) = 0.0_wp                  ! [out] Bounding box max
    END TYPE
    TYPE(MD_Int_BVHNode_Desc), ALLOCATABLE :: nodes(:)     ! [inout] Tree nodes
    INTEGER(i4), ALLOCATABLE :: prim_indices(:)            ! [in] Primitive indices
  END TYPE MD_Int_BVHTree_Ctx


  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ContPair_State
  ! KIND: State
  ! DESC: Contact pair runtime state (gaps, normals, forces)
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ContPair_State
    INTEGER(i4) :: id              = 0_i4                  ! [in]    Pair ID
    INTEGER(i4) :: master_surf_id  = 0_i4                  ! [in]    Master surface ID
    INTEGER(i4) :: slave_surf_id   = 0_i4                  ! [in]    Slave surface ID
    INTEGER(i4) :: contact_type    = 0_i4                  ! [in]    Contact type
    INTEGER(i4) :: dimension       = 3_i4                  ! [in]    Spatial dimension
    REAL(wp)    :: search_toleranc  = 0.0_wp                ! [in]    Search tolerance
    REAL(wp)    :: gap_tolerance    = 1.0E-6_wp             ! [in]    Gap tolerance
    LOGICAL     :: is_self_contact = .FALSE.               ! [in]    Self-contact flag
    LOGICAL     :: active          = .TRUE.                ! [inout] Active flag
    LOGICAL     :: use_bucket_sear = .TRUE.                ! [in]    Use bucket search
    LOGICAL     :: use_bvh_search  = .FALSE.               ! [in]    Use BVH search
    INTEGER(i4) :: n_contact_point = 0_i4                  ! [inout] Contact point count
    INTEGER(i4), ALLOCATABLE :: contact_nodes(:)           ! [inout] Contact node IDs
    INTEGER(i4), ALLOCATABLE :: master_elements(:)         ! [inout] Master element IDs
    INTEGER(i4), ALLOCATABLE :: contact_state(:)           ! [inout] Per-point states
    REAL(wp), ALLOCATABLE    :: gaps(:)                    ! [inout] Gap values
    REAL(wp), ALLOCATABLE    :: normals(:,:)               ! [inout] Normal vectors
    REAL(wp), ALLOCATABLE    :: tangents(:,:)              ! [inout] Tangent vectors
    REAL(wp), ALLOCATABLE    :: xi_local(:,:)              ! [inout] Local coords
    REAL(wp), ALLOCATABLE    :: tangential_slip(:,:)       ! [inout] Tangential slip
    REAL(wp), ALLOCATABLE    :: contact_pressur(:)         ! [inout] Contact pressure
    REAL(wp), ALLOCATABLE    :: friction_force(:,:)        ! [inout] Friction forces
    TYPE(MD_Int_BucketGrid_Ctx), POINTER :: bucket_grid => NULL() ! [inout] Bucket grid
    TYPE(MD_Int_BVHTree_Ctx),    POINTER :: bvh_tree    => NULL() ! [inout] BVH tree
    INTEGER(i4), ALLOCATABLE :: prev_contact_no(:)         ! [inout] Previous contact nodes
    INTEGER(i4), ALLOCATABLE :: prev_master_ele(:)         ! [inout] Previous master elems
    REAL(wp), ALLOCATABLE    :: prev_xi_local(:,:)         ! [inout] Previous local coords
  END TYPE MD_Int_ContPair_State


  !--------------------------------------------------------------------
  ! SIO Argument bundles
  !--------------------------------------------------------------------

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_PenaltyMethod_Arg
  ! KIND: Arg
  ! DESC: Input args for penalty method application
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_PenaltyMethod_Arg
    TYPE(MD_Int_ContNode_State), POINTER :: contact_nodes(:) => NULL() ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
    REAL(wp), POINTER :: velocities(:)    => NULL()                    ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_PenaltyMethod_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_PenaltyRes_Arg
  ! KIND: Arg
  ! DESC: Output args from penalty method application
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_PenaltyRes_Arg
    TYPE(MD_Int_ForceRes_State) :: forces                               ! [out]
    REAL(wp), POINTER :: stiffness(:,:) => NULL()                      ! [out]
    INTEGER(i4)       :: status = 0_i4                                 ! [out]
  END TYPE MD_Int_PenaltyRes_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_LagrangeMethod_Arg
  ! KIND: Arg
  ! DESC: Input args for Lagrange multiplier method
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_LagrangeMethod_Arg
    TYPE(MD_Int_ContNode_State), POINTER :: contact_nodes(:) => NULL() ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_LagrangeMethod_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_LagrangeRes_Arg
  ! KIND: Arg
  ! DESC: Output args from Lagrange multiplier method
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_LagrangeRes_Arg
    REAL(wp), POINTER :: constraint_matr(:,:) => NULL()                ! [out]
    REAL(wp), POINTER :: constraint_rhs(:)    => NULL()                ! [out]
    REAL(wp), POINTER :: lagrange_multip(:)   => NULL()                ! [out]
    INTEGER(i4)       :: status = 0_i4                                 ! [out]
  END TYPE MD_Int_LagrangeRes_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ForceResInit_Arg
  ! KIND: Arg
  ! DESC: Input args for force result initialization
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ForceResInit_Arg
    INTEGER(i4) :: n_nodes = 0_i4                                      ! [in]
  END TYPE MD_Int_ForceResInit_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ForceResInitOut_Arg
  ! KIND: Arg
  ! DESC: Output args from force result initialization
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ForceResInitOut_Arg
    INTEGER(i4) :: status = 0_i4                                       ! [out]
  END TYPE MD_Int_ForceResInitOut_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_UpdateGeom_Arg
  ! KIND: Arg
  ! DESC: Input args for geometry update
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_UpdateGeom_Arg
    TYPE(MD_Int_ContNode_State) :: contact_node                        ! [in]
    REAL(wp), POINTER :: displacements(:) => NULL()                    ! [in]
  END TYPE MD_Int_UpdateGeom_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_UpdateGeomRes_Arg
  ! KIND: Arg
  ! DESC: Output args from geometry update
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_UpdateGeomRes_Arg
    REAL(wp)    :: gap          = 0.0_wp                               ! [out]
    REAL(wp)    :: n_vector(3)  = 0.0_wp                               ! [out]
    REAL(wp)    :: t1_vector(3) = 0.0_wp                               ! [out]
    REAL(wp)    :: t2_vector(3) = 0.0_wp                               ! [out]
    INTEGER(i4) :: status       = 0_i4                                  ! [out]
  END TYPE MD_Int_UpdateGeomRes_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ApplyFric_Arg
  ! KIND: Arg
  ! DESC: Input args for friction application
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ApplyFric_Arg
    TYPE(MD_Int_ContNode_State) :: contact_node                        ! [in]
    REAL(wp) :: relative_velocity(3) = 0.0_wp                          ! [in]
    TYPE(MD_Int_AlgoCtrl_Algo)  :: control                             ! [in]
  END TYPE MD_Int_ApplyFric_Arg

  !--------------------------------------------------------------------
  ! TYPE: MD_Int_ApplyFricRes_Arg
  ! KIND: Arg
  ! DESC: Output args from friction application
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Int_ApplyFricRes_Arg
    REAL(wp)    :: tangent_force(2) = 0.0_wp                           ! [out]
    REAL(wp)    :: slip_rate(2)     = 0.0_wp                           ! [out]
    INTEGER(i4) :: status           = 0_i4                              ! [out]
  END TYPE MD_Int_ApplyFricRes_Arg


  !--------------------------------------------------------------------
  ! Module-level flags for user callbacks
  !--------------------------------------------------------------------
  LOGICAL, PUBLIC :: md_int_uinter_active = .FALSE.
  LOGICAL, PUBLIC :: md_int_fric_active   = .FALSE.

  ABSTRACT INTERFACE
    SUBROUTINE md_int_uinter_intf(sigma, ddsddr, stiff, flux, ddfddt, ddfddr, &
                                  deff, temp, dtemp, pnewdt, &
                                  props, nprops, statev, nstatev, &
                                  area, apts, slip, dslip, pener, sener, &
                                  rdisp, drdisp, pres, dpres, &
                                  ctime, dtime, kstep, kinc, jtype, cname, &
                                  predel, precd, dpred, dprecd)
      IMPORT :: wp, i4
      REAL(wp), INTENT(OUT)   :: sigma(6), ddsddr(6,6), stiff, flux, ddfddt, ddfddr, deff
      REAL(wp), INTENT(IN)    :: temp, dtemp
      REAL(wp), INTENT(INOUT) :: pnewdt
      REAL(wp), INTENT(IN)    :: props(*)
      INTEGER(i4), INTENT(IN) :: nprops
      REAL(wp), INTENT(INOUT) :: statev(*)
      INTEGER(i4), INTENT(IN) :: nstatev
      REAL(wp), INTENT(IN)    :: area, apts(2), slip(2), dslip(2)
      REAL(wp), INTENT(INOUT) :: pener, sener
      REAL(wp), INTENT(IN)    :: rdisp(3), drdisp(3), pres, dpres, ctime(2), dtime
      INTEGER(i4), INTENT(IN) :: kstep, kinc, jtype
      CHARACTER(LEN=80), INTENT(IN) :: cname
      REAL(wp), INTENT(IN)    :: predel, precd, dpred, dprecd
    END SUBROUTINE md_int_uinter_intf

    SUBROUTINE md_int_fric_intf(mu, ddmudp, ddmudv, press, slip, temp, &
                                props, nprops, statev, nstatev)
      IMPORT :: wp, i4
      REAL(wp), INTENT(OUT)   :: mu, ddmudp, ddmudv
      REAL(wp), INTENT(IN)    :: press, slip, temp
      REAL(wp), INTENT(IN)    :: props(*)
      INTEGER(i4), INTENT(IN) :: nprops
      REAL(wp), INTENT(INOUT) :: statev(*)
      INTEGER(i4), INTENT(IN) :: nstatev
    END SUBROUTINE md_int_fric_intf
  END INTERFACE

  PROCEDURE(md_int_uinter_intf), POINTER, PUBLIC :: md_int_user_uinter => NULL()
  PROCEDURE(md_int_fric_intf),   POINTER, PUBLIC :: md_int_user_fric   => NULL()

  !--------------------------------------------------------------------
  ! Re-export Arg types from MD_Int_ContactArgs
  !--------------------------------------------------------------------
  PUBLIC :: MD_IC_ContactAddK_Arg, MD_IC_ContactAddForce_Arg
  PUBLIC :: MD_IC_ContactAssemTriplets_Arg, MD_IC_ContactInit_Arg
  PUBLIC :: MD_IC_ContactUpdateGeom_Arg, MD_IC_ContactEvalFace_Arg

  !--------------------------------------------------------------------
  ! Utility function interfaces
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_CrossProduct, MD_Int_Dot3, MD_Int_HasInt
  PUBLIC :: MD_Int_PointInAABB
  PUBLIC :: MD_Int_ContNode_Destroy, MD_Int_ForceRes_Init, MD_Int_ForceRes_Destroy
  PUBLIC :: MD_NodeDisp
  PUBLIC :: ErrorStatusType, init_error_status, IF_STATUS_OK

CONTAINS

  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_ContNode_Destroy
  ! PHASE:      P0
  ! PURPOSE:    Reset contact node state to initial values
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_ContNode_Destroy(this)
    CLASS(MD_Int_ContNode_State), INTENT(INOUT) :: this
    this%global_id = 0_i4; this%local_id = 0_i4
    this%state = MD_INT_CSTATE_INITIAL
    this%matched_segment = 0_i4
    this%dof_x = 0_i4; this%dof_y = 0_i4; this%dof_z = 0_i4
    this%skew_flag = 0_i4; this%was_sliding = .FALSE.; this%active = .FALSE.
    this%coords = 0.0_wp; this%coords_init = 0.0_wp
    this%gap = 0.0_wp; this%penetration = 0.0_wp
    this%normal = 0.0_wp; this%tangent = 0.0_wp; this%xi_local = 0.0_wp
    this%force_n = 0.0_wp; this%force_t = 0.0_wp
    this%slip = 0.0_wp; this%beta = 0.0_wp; this%lambda = 0.0_wp
  END SUBROUTINE MD_Int_ContNode_Destroy


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_ForceRes_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize force result arrays for nNodes contact points
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_ForceRes_Init(this, nNodes, status)
    CLASS(MD_Int_ForceRes_State), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN)              :: nNodes          ! [in] Node count
    INTEGER(i4), INTENT(OUT), OPTIONAL   :: status          ! [out] Status code

    IF (PRESENT(status)) status = 0_i4
    IF (nNodes <= 0_i4) THEN
      IF (PRESENT(status)) status = -1_i4
      RETURN
    END IF

    CALL this%Destroy()

    IF (.NOT. ALLOCATED(this%normal_forces)) THEN
      ALLOCATE(this%normal_forces(nNodes))
      this%normal_forces = 0.0_wp
    END IF
    IF (.NOT. ALLOCATED(this%tangent_forces)) THEN
      ALLOCATE(this%tangent_forces(2, nNodes))
      this%tangent_forces = 0.0_wp
    END IF
    IF (.NOT. ALLOCATED(this%lagrange_multip)) THEN
      ALLOCATE(this%lagrange_multip(nNodes))
      this%lagrange_multip = 0.0_wp
    END IF

    this%nActiveCont    = 0_i4
    this%total_normal_fo = 0.0_wp
    this%total_friction  = 0.0_wp
    IF (PRESENT(status)) status = 0_i4
  END SUBROUTINE MD_Int_ForceRes_Init


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_ForceRes_Destroy
  ! PHASE:      P0
  ! PURPOSE:    Deallocate force result arrays
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_ForceRes_Destroy(this)
    CLASS(MD_Int_ForceRes_State), INTENT(INOUT) :: this
    IF (ALLOCATED(this%normal_forces))  DEALLOCATE(this%normal_forces)
    IF (ALLOCATED(this%tangent_forces)) DEALLOCATE(this%tangent_forces)
    IF (ALLOCATED(this%lagrange_multip)) DEALLOCATE(this%lagrange_multip)
    this%nActiveCont    = 0_i4
    this%total_normal_fo = 0.0_wp
    this%total_friction  = 0.0_wp
  END SUBROUTINE MD_Int_ForceRes_Destroy


  !--------------------------------------------------------------------
  ! FUNCTION: MD_Int_CrossProduct
  ! PHASE:    P0
  ! PURPOSE:  3D cross product utility
  !--------------------------------------------------------------------
  FUNCTION MD_Int_CrossProduct(a, b) RESULT(c)
    REAL(wp), INTENT(IN) :: a(3), b(3)
    REAL(wp) :: c(3)
    c(1) = a(2)*b(3) - a(3)*b(2)
    c(2) = a(3)*b(1) - a(1)*b(3)
    c(3) = a(1)*b(2) - a(2)*b(1)
  END FUNCTION MD_Int_CrossProduct


  !--------------------------------------------------------------------
  ! FUNCTION: MD_Int_Dot3
  ! PHASE:    P0
  ! PURPOSE:  3D dot product utility
  !--------------------------------------------------------------------
  FUNCTION MD_Int_Dot3(a, b) RESULT(val)
    REAL(wp), INTENT(IN) :: a(3), b(3)
    REAL(wp) :: val
    val = a(1)*b(1) + a(2)*b(2) + a(3)*b(3)
  END FUNCTION MD_Int_Dot3


  !--------------------------------------------------------------------
  ! FUNCTION: MD_Int_HasInt
  ! PHASE:    P0
  ! PURPOSE:  Check if integer array contains a value
  !--------------------------------------------------------------------
  FUNCTION MD_Int_HasInt(arr, nUsed, val) RESULT(found)
    INTEGER(i4), INTENT(IN) :: arr(:)
    INTEGER(i4), INTENT(IN) :: nUsed, val
    LOGICAL :: found
    INTEGER(i4) :: i
    found = .FALSE.
    DO i = 1, nUsed
      IF (arr(i) == val) THEN
        found = .TRUE.
        RETURN
      END IF
    END DO
  END FUNCTION MD_Int_HasInt


  !--------------------------------------------------------------------
  ! FUNCTION: MD_Int_PointInAABB
  ! PHASE:    P0
  ! PURPOSE:  Check if point is inside axis-aligned bounding box
  !--------------------------------------------------------------------
  PURE FUNCTION MD_Int_PointInAABB(point, bbox_min, bbox_max) RESULT(inside)
    REAL(wp), INTENT(IN) :: point(3), bbox_min(3), bbox_max(3)
    LOGICAL :: inside
    inside = (point(1) >= bbox_min(1) .AND. point(1) <= bbox_max(1) .AND. &
              point(2) >= bbox_min(2) .AND. point(2) <= bbox_max(2) .AND. &
              point(3) >= bbox_min(3) .AND. point(3) <= bbox_max(3))
  END FUNCTION MD_Int_PointInAABB

END MODULE MD_Int_Types
