!===============================================================================
! MODULE: PH_ConstrPeriod_Brg
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Brg — public API for Periodic BC operations
! BRIEF:  Periodic BC for RVE/homogenization: displacement periodicity,
!         macro strain/stress computation, and enforcement procedures.
!===============================================================================
!
! Contents:
!   Types:
!     - PH_Constr_Period_Apply_Desc: Periodic BC descriptor (node pairs)
!     - PH_Constr_Period_Apply_Algo: Algorithm parameters (macro strain ε̄)
!     - PH_Constr_Period_Apply_Ctx: Context (RVE size L, node coordinates)
!     - PH_Constr_Period_Apply_State: State (displacement jumps Δu)
!     - PH_Constr_Period_Apply_Arg: Unified SIO bundle (Desc/Algo/Ctx/State + status)
!   Subroutines:
!     - PH_Constr_Period_Apply: Apply periodic BC using structured interface
!     - PH_Constr_Period_BuildNodePairs / Init / ApplyDisplacement / ComputeMacro*: ErrorStatusType OUT
!     - PH_Constr_Period_ComputeMacroStrain: volume-averaged macro strain
!     - PH_Constr_Period_ComputeMacroStress: volume-averaged macro stress
!===============================================================================
MODULE PH_ConstrPeriod_Brg
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Constr_Period
  USE PH_ConstrPeriod_Def
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
  !=============================================================================
  
  !> @brief Descriptor for periodic BC application
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Desc
    TYPE(Node_Pair_Data), ALLOCATABLE :: node_pairs(:)  ! Periodic node pairs
    INTEGER(i4) :: num_pairs = 0_i4  ! Number of node pairs
  END TYPE PH_Constr_Period_Apply_Desc
  
  !> @brief Algorithm parameters for periodic BC
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Algo
    REAL(wp) :: macro_strain(6) = ZERO  ! Macro strain ε̄ [εxx, εyy, εzz, γxy, γyz, γxz]
    LOGICAL :: impose_macro_strain = .FALSE.  ! Whether to impose macro strain
    INTEGER(i4) :: bc_type = 1_i4  ! 1=displacement periodicity, 2=mixed, 3=stress periodicity
  END TYPE PH_Constr_Period_Apply_Algo
  
  !> @brief Context for periodic BC (RVE geometry)
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Ctx
    REAL(wp) :: rve_size(3) = ZERO  ! RVE dimensions L = [Lx, Ly, Lz]
    REAL(wp) :: rve_origin(3) = ZERO  ! RVE origin coordinates
    REAL(wp), ALLOCATABLE :: node_coords(:,:)  ! Node coordinates X  ?ℝ^(3×n_nodes)
  END TYPE PH_Constr_Period_Apply_Ctx
  
  !> @brief State for periodic BC (displacement jumps)
  TYPE, PUBLIC :: PH_Constr_Period_Apply_State
    REAL(wp), ALLOCATABLE :: displacement_jump(:,:)  ! Displacement jumps Δu  ?ℝ^(3×n_pairs)
    TYPE(Period_BC_State) :: bc_state  ! Periodic BC state (macro strain/stress)
  END TYPE PH_Constr_Period_Apply_State
  
  !> @brief Unified SIO bundle for PH_Constr_Period_Apply
  TYPE, PUBLIC :: PH_Constr_Period_Apply_Arg
    TYPE(PH_Constr_Period_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_Period_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_Period_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_Period_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Period_Apply_Arg

  
  !=============================================================================
  ! Public API
  !=============================================================================
  PUBLIC :: PH_Constr_Period_Init
  PUBLIC :: PH_Constr_Period_BuildNodePairs
  PUBLIC :: PH_Constr_Period_ApplyDisplacement
  PUBLIC :: PH_Constr_Period_ComputeMacroStrain
  PUBLIC :: PH_Constr_Period_ComputeMacroStress
  PUBLIC :: PH_Constr_Period_Apply
  PUBLIC :: PH_Constr_Period_Apply_Arg
  PUBLIC :: PH_Constr_Period_Apply_Desc, PH_Constr_Period_Apply_Algo
  PUBLIC :: PH_Constr_Period_Apply_Ctx, PH_Constr_Period_Apply_State

CONTAINS

  !=============================================================================
  !> @brief Apply periodic BC using structured interface
  !! @details Applies periodic boundary conditions: u(x+L) = u(x) + ε̄·L
  !!   Computes displacement jumps Δu = ε̄·L for each node pair
  !! @param[inout] arg Unified bundle (node pairs, macro strain ε̄, RVE size L, jumps, status)
  !! @note Theory: Δu = ε̄·L where ε̄ ?ℝ^6 (Voigt), L ?ℝ^3
  !=============================================================================
  SUBROUTINE PH_Constr_Period_Apply(arg)
    TYPE(PH_Constr_Period_Apply_Arg), INTENT(INOUT) :: arg
    
    TYPE(Period_BC_Params) :: params
    INTEGER(i4) :: num_pairs
    
    CALL init_error_status(arg%status)
    
    ! Build Period_BC_Params from algo and ctx
    params%rve_size = arg%ctx%rve_size
    params%rve_origin = arg%ctx%rve_origin
    params%macro_strain = arg%algo%macro_strain
    params%impose_macro_strain = arg%algo%impose_macro_strain
    params%bc_type = arg%algo%bc_type
    
    num_pairs = arg%desc%num_pairs
    IF (num_pairs <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_Period_Apply: Invalid num_pairs"
      RETURN
    END IF
    
    ! Allocate displacement jumps
    IF (.NOT. ALLOCATED(arg%state%displacement_jump)) THEN
      ALLOCATE(arg%state%displacement_jump(3, num_pairs))
    END IF
    
    CALL PH_Constr_Period_ApplyDisplacement(params, arg%desc%node_pairs, &
                                            num_pairs, &
                                            arg%state%displacement_jump, &
                                            arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN
    
    arg%state%bc_state%nNode_pairs = num_pairs
    arg%state%bc_state%computed_macro_strain = arg%algo%macro_strain
    
    arg%status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_Apply
  
  !=============================================================================
  !> @brief Initialize periodic BC state
  !! @param[in] params Periodic BC parameters
  !! @param[inout] state Periodic BC state (will be initialized)
  !=============================================================================
  SUBROUTINE PH_Constr_Period_Init(params, state, status)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    TYPE(Period_BC_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    state%nNode_pairs = 0_i4
    state%computed_macro_strain = ZERO
    state%computed_macro_stress = ZERO
    state%rve_volume = params%rve_size(1) * params%rve_size(2) * params%rve_size(3)
    state%is_consistent = .TRUE.
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_Init

  !=============================================================================
  !> @brief Build periodic node pairs
  !! @details Identifies periodic node pairs on opposite faces of RVE:
  !!   X-direction: pairs on x- and x+ faces with matching Y, Z coordinates
  !!   Y-direction: pairs on y- and y+ faces with matching X, Z coordinates
  !!   Z-direction: pairs on z- and z+ faces with matching X, Y coordinates
  !! @param[in] params Periodic BC parameters (RVE size, periodicity directions)
  !! @param[in] node_coords Node coordinates X ?ℝ^(3×n_nodes)
  !! @param[in] nNodes Number of nodes
  !! @param[out] node_pairs Periodic node pairs (allocated and populated)
  !=============================================================================
  SUBROUTINE PH_Constr_Period_BuildNodePairs(params, node_coords, nNodes, node_pairs, status)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: node_coords(:,:)  ! (3, n_nodes)
    INTEGER(i4), INTENT(IN) :: nNodes
    TYPE(Node_Pair_Data), ALLOCATABLE, INTENT(OUT) :: node_pairs(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4), ALLOCATABLE :: minus_nodes(:), plus_nodes(:)
    INTEGER(i4) :: n_minus, n_plus, i_minus, i_plus, pair_count
    REAL(wp) :: pos_minus(3), pos_plus(3), distance
    
    CALL init_error_status(status)
    IF (nNodes <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_BuildNodePairs: nNodes must be positive"
      ALLOCATE(node_pairs(0))
      RETURN
    END IF
    IF (SIZE(node_coords, 1) < 3 .OR. SIZE(node_coords, 2) < nNodes) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_BuildNodePairs: node_coords shape too small"
      ALLOCATE(node_pairs(0))
      RETURN
    END IF
    
    ALLOCATE(node_pairs(nNodes))
    pair_count = 0_i4
    
    ! X-direction periodicity
    IF (params%periodic_x) THEN
      CALL PH_Constr_PeriodCore_IdentifyBoundaryNodes(node_coords, nNodes, params, 1_i4, minus_nodes, plus_nodes)
      n_minus = SIZE(minus_nodes)
      n_plus = SIZE(plus_nodes)
      
      ! Pair X- and X+ nodes
      DO i_minus = 1, n_minus
        pos_minus = node_coords(:, minus_nodes(i_minus))
        
        DO i_plus = 1, n_plus
          pos_plus = node_coords(:, plus_nodes(i_plus))
          
          ! Check if Y and Z coordinates match
          distance = SQRT((pos_minus(2) - pos_plus(2))**2 + &
                         (pos_minus(3) - pos_plus(3))**2)
          
          IF (distance < params%pairing_tolerance) THEN
            pair_count = pair_count + 1
            node_pairs(pair_count)%node_minus_id = minus_nodes(i_minus)
            node_pairs(pair_count)%node_plus_id = plus_nodes(i_plus)
            node_pairs(pair_count)%boundary_face = 1_i4  ! X-direction
            node_pairs(pair_count)%coords_minus = pos_minus
            node_pairs(pair_count)%coords_plus = pos_plus
            EXIT
          END IF
        END DO
      END DO
      
      DEALLOCATE(minus_nodes, plus_nodes)
    END IF
    
    ! Y-direction periodicity (similar to X)
    IF (params%periodic_y) THEN
      CALL PH_Constr_PeriodCore_IdentifyBoundaryNodes(node_coords, nNodes, params, 2_i4, minus_nodes, plus_nodes)
      n_minus = SIZE(minus_nodes)
      n_plus = SIZE(plus_nodes)
      
      DO i_minus = 1, n_minus
        pos_minus = node_coords(:, minus_nodes(i_minus))
        
        DO i_plus = 1, n_plus
          pos_plus = node_coords(:, plus_nodes(i_plus))
          
          ! Check if X and Z coordinates match
          distance = SQRT((pos_minus(1) - pos_plus(1))**2 + &
                         (pos_minus(3) - pos_plus(3))**2)
          
          IF (distance < params%pairing_tolerance) THEN
            pair_count = pair_count + 1
            node_pairs(pair_count)%node_minus_id = minus_nodes(i_minus)
            node_pairs(pair_count)%node_plus_id = plus_nodes(i_plus)
            node_pairs(pair_count)%boundary_face = 3_i4  ! Y-direction
            node_pairs(pair_count)%coords_minus = pos_minus
            node_pairs(pair_count)%coords_plus = pos_plus
            EXIT
          END IF
        END DO
      END DO
      
      DEALLOCATE(minus_nodes, plus_nodes)
    END IF
    
    ! Z-direction periodicity (similar to X)
    IF (params%periodic_z) THEN
      CALL PH_Constr_PeriodCore_IdentifyBoundaryNodes(node_coords, nNodes, params, 3_i4, minus_nodes, plus_nodes)
      n_minus = SIZE(minus_nodes)
      n_plus = SIZE(plus_nodes)
      
      DO i_minus = 1, n_minus
        pos_minus = node_coords(:, minus_nodes(i_minus))
        
        DO i_plus = 1, n_plus
          pos_plus = node_coords(:, plus_nodes(i_plus))
          
          ! Check if X and Y coordinates match
          distance = SQRT((pos_minus(1) - pos_plus(1))**2 + &
                         (pos_minus(2) - pos_plus(2))**2)
          
          IF (distance < params%pairing_tolerance) THEN
            pair_count = pair_count + 1
            node_pairs(pair_count)%node_minus_id = minus_nodes(i_minus)
            node_pairs(pair_count)%node_plus_id = plus_nodes(i_plus)
            node_pairs(pair_count)%boundary_face = 5_i4  ! Z-direction
            node_pairs(pair_count)%coords_minus = pos_minus
            node_pairs(pair_count)%coords_plus = pos_plus
            EXIT
          END IF
        END DO
      END DO
      
      DEALLOCATE(minus_nodes, plus_nodes)
    END IF
    
    CALL PH_Constr_PeriodCore_ResizeNodePairsArray(node_pairs, pair_count)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_BuildNodePairs

  !=============================================================================
  !> @brief Apply macro strain-induced displacement jump
  !! @details Computes displacement jump Δu = ε̄·L for each node pair
  !!   where ε̄ is macro strain tensor, L is position vector from minus to plus node
  !! @param[in] params Periodic BC parameters (macro_strain ε̄)
  !! @param[in] node_pairs Periodic node pairs
  !! @param[in] num_pairs Number of node pairs
  !! @param[out] displacement_jump Displacement jumps Δu ?ℝ^(3×n_pairs)
  !! @note Theory: Δu = ε̄·L where ε̄ ?ℝ^(3×3), L ?ℝ^3
  !=============================================================================
  SUBROUTINE PH_Constr_Period_ApplyDisplacement(params, node_pairs, num_pairs, &
                                                 displacement_jump, status)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    TYPE(Node_Pair_Data), INTENT(IN) :: node_pairs(:)
    INTEGER(i4), INTENT(IN) :: num_pairs
    REAL(wp), INTENT(OUT) :: displacement_jump(:,:)  ! (3, n_pairs)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i_pair
    REAL(wp) :: macro_eps(3,3), position(3), jump(3)
    
    CALL init_error_status(status)
    IF (num_pairs < 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_ApplyDisplacement: num_pairs < 0"
      RETURN
    END IF
    IF (num_pairs > 0_i4) THEN
      IF (SIZE(node_pairs) < num_pairs) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "PH_Constr_Period_ApplyDisplacement: node_pairs too short"
        RETURN
      END IF
      IF (SIZE(displacement_jump, 1) < 3 .OR. SIZE(displacement_jump, 2) < num_pairs) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "PH_Constr_Period_ApplyDisplacement: displacement_jump too small"
        RETURN
      END IF
    END IF
    
    displacement_jump = ZERO
    
    ! Convert macro strain from Voigt to tensor notation: ε̄ ?ℝ^(3×3)
    macro_eps = ZERO
    macro_eps(1,1) = params%macro_strain(1)  ! εxx
    macro_eps(2,2) = params%macro_strain(2)  ! εyy
    macro_eps(3,3) = params%macro_strain(3)  ! εzz
    macro_eps(1,2) = params%macro_strain(4) * HALF  ! γxy/2
    macro_eps(2,1) = macro_eps(1,2)
    macro_eps(2,3) = params%macro_strain(5) * HALF  ! γyz/2
    macro_eps(3,2) = macro_eps(2,3)
    macro_eps(1,3) = params%macro_strain(6) * HALF  ! γxz/2
    macro_eps(3,1) = macro_eps(1,3)
    
    ! Compute displacement jump for each node pair: Δu = ε̄·L
    DO i_pair = 1, num_pairs
      ! Position vector L (from minus to plus node)
      position = node_pairs(i_pair)%coords_plus - node_pairs(i_pair)%coords_minus
      
      ! Displacement jump: Δu = ε̄·L (matrix-vector product)
      jump(1) = macro_eps(1,1) * position(1) + &
               macro_eps(1,2) * position(2) + &
               macro_eps(1,3) * position(3)
      jump(2) = macro_eps(2,1) * position(1) + &
               macro_eps(2,2) * position(2) + &
               macro_eps(2,3) * position(3)
      jump(3) = macro_eps(3,1) * position(1) + &
               macro_eps(3,2) * position(2) + &
               macro_eps(3,3) * position(3)
      
      displacement_jump(:, i_pair) = jump
    END DO
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_ApplyDisplacement

  !=============================================================================
  !> @brief Compute macro strain via volume averaging
  !! @details Computes macro strain: ε̄ = (1/V) ?ε dV = (1/V) Σ ε_i·V_i
  !! @param[in] params Periodic BC parameters (RVE volume V)
  !! @param[in] element_strains Element strains ε_i ?ℝ^6 (Voigt, nElems)
  !! @param[in] element_volumes Element volumes V_i ?ℝ^(nElems)
  !! @param[in] nElems Number of elements
  !! @param[inout] state Periodic BC state (computed_macro_strain will be updated)
  !=============================================================================
  SUBROUTINE PH_Constr_Period_ComputeMacroStrain(params, element_strains, element_volumes, &
                                                  nElems, state, status)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: element_strains(:,:)   ! (6, n_elem) Voigt
    REAL(wp), INTENT(IN) :: element_volumes(:)     ! (n_elem)
    INTEGER(i4), INTENT(IN) :: nElems
    TYPE(Period_BC_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    IF (nElems <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_ComputeMacroStrain: nElems must be positive"
      RETURN
    END IF
    IF (SIZE(element_strains, 1) < 6 .OR. SIZE(element_strains, 2) < nElems &
        .OR. SIZE(element_volumes) < nElems) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_ComputeMacroStrain: array sizes inconsistent"
      RETURN
    END IF
    CALL PH_Constr_PeriodCore_ComputeMacroStrain(params, element_strains, element_volumes, &
                                  nElems, state)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_ComputeMacroStrain

  !=============================================================================
  !> @brief Compute macro stress via volume averaging
  !! @details Computes macro stress: σ̄ = (1/V) ?σ dV = (1/V) Σ σ_i·V_i
  !! @param[in] params Periodic BC parameters (RVE volume V)
  !! @param[in] element_stresses Element stresses σ_i ?ℝ^6 (Voigt, nElems)
  !! @param[in] element_volumes Element volumes V_i ?ℝ^(nElems)
  !! @param[in] nElems Number of elements
  !! @param[inout] state Periodic BC state (computed_macro_stress will be updated)
  !=============================================================================
  SUBROUTINE PH_Constr_Period_ComputeMacroStress(params, element_stresses, element_volumes, &
                                                  nElems, state, status)
    TYPE(Period_BC_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: element_stresses(:,:)  ! (6, n_elem) Voigt
    REAL(wp), INTENT(IN) :: element_volumes(:)     ! (n_elem)
    INTEGER(i4), INTENT(IN) :: nElems
    TYPE(Period_BC_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    IF (nElems <= 0_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_ComputeMacroStress: nElems must be positive"
      RETURN
    END IF
    IF (SIZE(element_stresses, 1) < 6 .OR. SIZE(element_stresses, 2) < nElems &
        .OR. SIZE(element_volumes) < nElems) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "PH_Constr_Period_ComputeMacroStress: array sizes inconsistent"
      RETURN
    END IF
    CALL PH_Constr_PeriodCore_ComputeMacroStress(params, element_stresses, element_volumes, &
                                  nElems, state)
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE PH_Constr_Period_ComputeMacroStress

END MODULE PH_ConstrPeriod_Brg
