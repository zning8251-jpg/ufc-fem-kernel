!===============================================================================
! MODULE: PH_ConstrTie_Def
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Def â€?Tie constraint type definitions
! BRIEF:  Tie_Surface_Pair, Tie_Node_Pair, Tie_Constraint_Params/State types.
!===============================================================================
!
! Contents (A-Z):
!   Types:
!     - Tie_Constraint_Params - Tie constraint configuration parameters
!     - Tie_Constraint_State  - Tie constraint violation monitoring
!     - Tie_Node_Pair         - Single slave-master node pairing
!     - Tie_Surface_Pair      - Surface-to-surface tie definition
!   Subroutines:
!     - (None)
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_ConstrTie_Def
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Constr_Domain, ONLY: PH_CONSTR_PENALTY
  IMPLICIT NONE
  PRIVATE
  
  ! ==========================================================================
  ! Public types
  ! ==========================================================================
  PUBLIC :: Tie_Constraint_Params
  PUBLIC :: Tie_Constraint_State
  PUBLIC :: Tie_Node_Pair
  PUBLIC :: Tie_Surface_Pair
  
  ! ==========================================================================
  ! Tie Constraint Parameters - enforcement configuration
  ! ==========================================================================
  TYPE :: Tie_Constraint_Params
    ! Constraint type
    INTEGER(i4) :: constraint_type = 1_i4       ! 1=node-to-surface, 2=surface-to-surface
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY  ! PH_CONS_* (PH_ConstraintDomain_Algo)
    
    ! Pairing tolerance
    REAL(wp) :: position_tolerance = 1.0e-6_wp  ! Position tolerance (m)
    LOGICAL :: adjust_initially = .FALSE.       ! Adjust positions initially
    
    ! Adaptive weighting
    LOGICAL :: use_adaptive_weight = .FALSE.    ! Enable adaptive weighting
    REAL(wp) :: weight_distance_scale = 1.0_wp  ! Distance scaling factor
    
    ! Penalty stiffness
    REAL(wp) :: penalty_stiffness = 1.0e12_wp   ! Penalty stiffness (N/m)
    
    ! Rotation tying
    LOGICAL :: tie_rotations = .FALSE.          ! Tie rotational DOFs (shell elements)
    
    ! Search parameters
    REAL(wp) :: search_radius = 1.0_wp          ! Search radius (m)
    INTEGER(i4) :: max_search_iterations = 10_i4 ! Max search iterations
  END TYPE Tie_Constraint_Params
  
  ! ==========================================================================
  ! Tie Constraint State - violation monitoring
  ! ==========================================================================
  TYPE :: Tie_Constraint_State
    INTEGER(i4) :: num_tied_nodes = 0_i4        ! Number of tied nodes
    REAL(wp) :: max_violation = ZERO            ! Maximum violation (m)
    REAL(wp) :: avg_violation = ZERO            ! Average violation (m)
    REAL(wp) :: constraint_force = ZERO         ! Constraint force (N)
    LOGICAL :: is_satisfied = .TRUE.            ! Whether constraints satisfied
    INTEGER(i4) :: num_violations = 0_i4        ! Number of violated nodes
  END TYPE Tie_Constraint_State
  
  ! ==========================================================================
  ! Tie Node Pair - single slave-master pairing
  ! ==========================================================================
  TYPE :: Tie_Node_Pair
    INTEGER(i4) :: slave_node_id = 0_i4                   ! Slave node ID
    INTEGER(i4) :: master_element_id = 0_i4               ! Master element ID
    INTEGER(i4) :: num_master_nodes = 0_i4                ! Number of master nodes
    INTEGER(i4), ALLOCATABLE :: master_node_ids(:)        ! Master node IDs
    REAL(wp) :: local_coords(3) = ZERO                    ! Local coordinates (xi, eta, zeta)
    REAL(wp), ALLOCATABLE :: shape_functions(:)           ! Shape function values
    REAL(wp) :: weight_factor = ONE                       ! Weighting factor
    REAL(wp) :: initial_distance = ZERO                   ! Initial distance (m)
    LOGICAL :: is_active = .FALSE.                        ! Whether pair is active
  END TYPE Tie_Node_Pair
  
  ! ==========================================================================
  ! Tie Surface Pair - surface-to-surface tie
  ! ==========================================================================
  TYPE :: Tie_Surface_Pair
    CHARACTER(LEN=64) :: master_surface_name = ""
    CHARACTER(LEN=64) :: slave_surface_name = ""
    INTEGER(i4) :: num_pairs = 0_i4                       ! Number of node pairs
    TYPE(Tie_Node_Pair), ALLOCATABLE :: node_pairs(:)     ! Node pairings
  END TYPE Tie_Surface_Pair

END MODULE PH_ConstrTie_Def

