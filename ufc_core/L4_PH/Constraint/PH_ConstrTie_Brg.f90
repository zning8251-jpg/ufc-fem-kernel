!===============================================================================
! MODULE: PH_ConstrTie_Brg
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Brg ??public API for Tie constraint operations
! BRIEF:  Surface projection, constraint equation generation, and enforcement
!         bridge procedures for surface-to-surface tie constraints.
! PILOT:   `PH_Constr_IntCodeToStatus` �� `PH_Constr_Core` ͳһ������ Tie/MPC Brg �ظ������ֽڡ�status ���̡�
!===============================================================================
! Theory:
!   Tie constraint: u_slave = u_master (no relative motion)
!   Penalty method: F_constraint = -???w??(u_slave - u_master_interp)
!   where u_master_interp = ?? N_i??u_i (shape function interpolation)
!   Constraint violation: r = ||u_slave - u_master_interp||
! Status: CORE | Last verified: 2026-02-28
! API contract ( ?7.4): L5 ?Bridge ?L3 ?L3 ?
!
! Contents:
!   Types:
!     - PH_Constr_Tie_Apply_Desc: Tie descriptor (surface pairs)
!     - PH_Constr_Tie_Apply_Algo: Algorithm parameters (penalty ??, tolerance)
!     - PH_Constr_Tie_Apply_Ctx: Context (displacements u_slave, u_master)
!     - PH_Constr_Tie_Apply_State: State (constraint forces F_constraint)
!     - PH_Constr_Tie_Apply_Arg: Unified SIO bundle (Desc/Algo/Ctx/State + status)
!   Subroutines:
!     - PH_Constr_Tie_Apply: Apply tie constraint using structured interface
!     - PH_Constr_Tie_BuildNodePairs: Build slave-master node pairings
!     - PH_Constr_Tie_CheckViolation: Check constraint violations
!===============================================================================
MODULE PH_ConstrTie_Brg
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Constr_Domain, ONLY: PH_CONSTR_PENALTY, PH_CONSTR_AUGLAG
  USE PH_Constr_Core, ONLY: PH_Constr_IntCodeToStatus
  USE PH_Constr_Tie
  USE PH_ConstrTie_Def
  IMPLICIT NONE
  PRIVATE
  
  !=============================================================================
  ! FOUR-CATEGORY TYPE SYSTEM: Desc/Algo/Ctx/State
  !=============================================================================
  
  !> @brief Descriptor for tie constraint application
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Desc
    TYPE(Tie_Surface_Pair) :: surface_pair  ! Surface pair definition
  END TYPE PH_Constr_Tie_Apply_Desc
  
  !> @brief Algorithm parameters for tie enforcement
  !> enforcement_method: PH_CONS_* from PH_ConstraintDomain_Algo (same as Tie_Constraint_Params)
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Algo
    INTEGER(i4) :: enforcement_method = PH_CONSTR_PENALTY
    REAL(wp) :: penalty_stiffness = 1.0e12_wp  ! Penalty stiffness ?? (N/m)
    REAL(wp) :: position_tolerance = 1.0e-6_wp  ! Position tolerance (m)
    LOGICAL :: use_adaptive_weight = .FALSE.  ! Use adaptive weighting
  END TYPE PH_Constr_Tie_Apply_Algo
  
  !> @brief Context for tie application (displacements)
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Ctx
    REAL(wp), ALLOCATABLE :: slave_displacements(:,:)  ! Slave displacements u_slave  ??^(3??n_slave)
    REAL(wp), ALLOCATABLE :: master_displacements(:,:)  ! Master displacements u_master  ??^(3??n_master)
  END TYPE PH_Constr_Tie_Apply_Ctx
  
  !> @brief State for tie application (forces and violations)
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_State
    REAL(wp), ALLOCATABLE :: constraint_forces(:,:)  ! Constraint forces F_constraint  ??^(3??n_slave)
    TYPE(Tie_Constraint_State) :: violation_state  ! Constraint violation state
  END TYPE PH_Constr_Tie_Apply_State
  
  !> @brief Unified SIO bundle for PH_Constr_Tie_Apply
  TYPE, PUBLIC :: PH_Constr_Tie_Apply_Arg
    TYPE(PH_Constr_Tie_Apply_Desc) :: desc                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_Algo) :: algo                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_Ctx) :: ctx                   ! [IN]
    TYPE(PH_Constr_Tie_Apply_State) :: state                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Constr_Tie_Apply_Arg

  
  !=============================================================================
  ! Public API
  !=============================================================================
  PUBLIC :: PH_Constr_Tie_Init
  PUBLIC :: PH_Constr_Tie_BuildNodePairs
  PUBLIC :: PH_Constr_Tie_CalcWeights
  PUBLIC :: PH_Constr_Tie_ApplyConstraint
  PUBLIC :: PH_Constr_Tie_CheckViolation
  PUBLIC :: PH_Constr_Tie_Opt
  PUBLIC :: PH_Constr_Tie_ComputeViolation
  PUBLIC :: PH_Constr_Tie_UpdateWeights
  PUBLIC :: PH_Constr_Tie_Apply
  PUBLIC :: PH_Constr_Tie_Apply_Arg
  PUBLIC :: PH_Constr_Tie_Apply_Desc, PH_Constr_Tie_Apply_Algo
  PUBLIC :: PH_Constr_Tie_Apply_Ctx, PH_Constr_Tie_Apply_State

CONTAINS

  !=============================================================================
  !> @brief Apply tie constraint using structured interface
  !! @details Applies tie constraint u_slave = u_master using penalty method:
  !!   F_constraint = -???w??(u_slave - u_master_interp)
  !! @param[inout] arg Unified bundle (Desc/Algo/Ctx/State + status)
  !! @note Theory: u_master_interp = ?? N_i??u_i (shape function interpolation)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_Apply(arg)
    TYPE(PH_Constr_Tie_Apply_Arg), INTENT(INOUT) :: arg

    TYPE(Tie_Constraint_Params) :: params
    INTEGER(i4) :: n_slave

    CALL init_error_status(arg%status)

    params%enforcement_method = arg%algo%enforcement_method
    params%penalty_stiffness = arg%algo%penalty_stiffness
    params%position_tolerance = arg%algo%position_tolerance
    params%use_adaptive_weight = arg%algo%use_adaptive_weight

    IF (.NOT. ALLOCATED(arg%ctx%slave_displacements) .OR. &
        .NOT. ALLOCATED(arg%ctx%master_displacements)) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_Tie_Apply: slave/master displacements not allocated"
      RETURN
    END IF
    n_slave = SIZE(arg%ctx%slave_displacements, 2)
    IF (n_slave <= 0) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = "PH_Constr_Tie_Apply: Invalid n_slave"
      RETURN
    END IF

    ! Allocate constraint forces
    IF (.NOT. ALLOCATED(arg%state%constraint_forces)) THEN
      ALLOCATE(arg%state%constraint_forces(3, n_slave))
    END IF

    ! Apply constraint using legacy interface
    CALL PH_Constr_Tie_ApplyConstraint(params, arg%desc%surface_pair, &
                                       arg%ctx%slave_displacements, &
                                       arg%ctx%master_displacements, &
                                       arg%state%constraint_forces)

    ! Check violation (requires coordinates, which should be in context)
    ! Note: This is a simplified version; full implementation would include coordinates
    arg%state%violation_state%is_satisfied = .TRUE.

    arg%status%status_code = IF_STATUS_OK

  END SUBROUTINE PH_Constr_Tie_Apply
  
  !=============================================================================
  !> @brief Initialize tie constraint state
  !! @param[in] params Tie constraint parameters
  !! @param[inout] state Tie constraint state (will be initialized)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_Init(params, state)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(Tie_Constraint_State), INTENT(INOUT) :: state
    
    state%num_tied_nodes = 0_i4
    state%max_violation = ZERO
    state%avg_violation = ZERO
    state%constraint_force = ZERO
    state%is_satisfied = .TRUE.
    state%num_violations = 0_i4
    
  END SUBROUTINE PH_Constr_Tie_Init

  !=============================================================================
  !> @brief Build slave-master node pairings
  !! @details Builds node pairs for tie constraint by finding nearest master element
  !!   for each slave node within position tolerance
  !! @param[in] params Tie constraint parameters (position_tolerance)
  !! @param[in] slave_coords Slave node coordinates X_slave ??^(3??n_slave)
  !! @param[in] master_surface_coords Master surface coordinates X_master ??^(3??n_master)
  !! @param[in] master_connectivity Master element connectivity conn ???^(n_nodes_per_elem??n_elem)
  !! @param[out] surface_pair Surface pair definition (node pairs will be populated)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_BuildNodePairs(params, slave_coords, master_surface_coords, &
                                          master_connectivity, surface_pair)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: slave_coords(:,:)        ! (3, n_slave)
    REAL(wp), INTENT(IN) :: master_surface_coords(:,:) ! (3, n_master)
    INTEGER(i4), INTENT(IN) :: master_connectivity(:,:)  ! (n_nodes_per_elem, n_elem)
    TYPE(Tie_Surface_Pair), INTENT(OUT) :: surface_pair
    
    INTEGER(i4) :: n_slave, i_slave, nearest_elem
    REAL(wp) :: slave_pos(3), projection_coords(3), distance
    
    n_slave = SIZE(slave_coords, 2)
    surface_pair%num_pairs = n_slave
    
    ALLOCATE(surface_pair%node_pairs(n_slave))
    
    ! Build each slave node pairing
    DO i_slave = 1, n_slave
      slave_pos = slave_coords(:, i_slave)
      
      ! Find nearest master element
      CALL PH_Constr_TieCore_FindNearestMasterElem(params, slave_pos, master_surface_coords, &
                                       master_connectivity, nearest_elem, &
                                       projection_coords, distance)
      
      ! Build node pair
      CALL PH_Constr_TieCore_BuildNodePair(i_slave, nearest_elem, master_connectivity, &
                              projection_coords, distance, &
                              surface_pair%node_pairs(i_slave))
      
      ! Check if within tolerance
      IF (distance <= params%position_tolerance) THEN
        surface_pair%node_pairs(i_slave)%is_active = .TRUE.
      ELSE
        surface_pair%node_pairs(i_slave)%is_active = .FALSE.
      END IF
    END DO
    
  END SUBROUTINE PH_Constr_Tie_BuildNodePairs

  !-----------------------------------------------------------------------------
  ! PH_Constr_Tie_CalcWeights: Compute adaptive weight factors
  !-----------------------------------------------------------------------------
  SUBROUTINE PH_Constr_Tie_CalcWeights(params, surface_pair)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(Tie_Surface_Pair), INTENT(INOUT) :: surface_pair
    
    CALL PH_Constr_TieCore_CalcWeights(params, surface_pair)
    
  END SUBROUTINE PH_Constr_Tie_CalcWeights

  !=============================================================================
  !> @brief Apply tie constraint forces
  !! @details If params%enforcement_method is PH_CONSTR_PENALTY or PH_CONSTR_AUGLAG, applies
  !!   penalty forces F_constraint = -???w??(u_slave - u_master_interp); otherwise leaves
  !!   constraint_forces zero (symmetric with PH_Constr_MPC_ApplyConstraint).
  !! @param[in] params Tie constraint parameters (penalty_stiffness ??, enforcement_method)
  !! @param[in] surface_pair Surface pair definition (node pairs, weights w)
  !! @param[in] slave_displacements Slave displacements u_slave ??^(3??n_slave)
  !! @param[in] master_displacements Master displacements u_master ??^(3??n_master)
  !! @param[out] constraint_forces Constraint forces F_constraint ??^(3??n_slave)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_ApplyConstraint(params, surface_pair, slave_displacements, &
                                           master_displacements, constraint_forces)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(Tie_Surface_Pair), INTENT(IN) :: surface_pair
    REAL(wp), INTENT(IN) :: slave_displacements(:,:)   ! (3, n_slave)
    REAL(wp), INTENT(IN) :: master_displacements(:,:)  ! (3, n_master)
    REAL(wp), INTENT(OUT) :: constraint_forces(:,:)    ! (3, n_slave)
    
    INTEGER(i4) :: i_pair, i_master, n_master
    REAL(wp) :: u_slave(3), u_master_interp(3), violation(3)
    REAL(wp) :: weight, penalty
    TYPE(Tie_Node_Pair) :: pair
    
    constraint_forces = ZERO
    IF (params%enforcement_method /= PH_CONSTR_PENALTY .AND. &
        params%enforcement_method /= PH_CONSTR_AUGLAG) RETURN
    
    ! Apply penalty / aug-Lag penalty path for each node pair
    DO i_pair = 1, surface_pair%num_pairs
      pair = surface_pair%node_pairs(i_pair)
      
      IF (.NOT. pair%is_active) CYCLE
      
      ! Slave node displacement
      u_slave = slave_displacements(:, pair%slave_node_id)
      
      ! Interpolate master displacement: u_master_interp = ?? N_i??u_i
      u_master_interp = ZERO
      n_master = pair%num_master_nodes
      DO i_master = 1, n_master
        u_master_interp = u_master_interp + &
          pair%shape_functions(i_master) * &
          master_displacements(:, pair%master_node_ids(i_master))
      END DO
      
      ! Violation: r = u_slave - u_master_interp
      violation = u_slave - u_master_interp
      
      ! Weight and penalty
      weight = pair%weight_factor
      penalty = params%penalty_stiffness
      
      ! Constraint force (penalty method): F = -???w??(u_slave - u_master_interp)
      constraint_forces(:, pair%slave_node_id) = -penalty * weight * violation
    END DO
    
  END SUBROUTINE PH_Constr_Tie_ApplyConstraint

  !=============================================================================
  !> @brief Check tie constraint violations
  !! @details Computes violation r = ||u_slave - u_master_interp|| for each node pair
  !! @param[in] params Tie constraint parameters (position_tolerance)
  !! @param[in] surface_pair Surface pair definition
  !! @param[in] slave_coords Slave node coordinates X_slave ??^(3??n_slave)
  !! @param[in] master_coords Master node coordinates X_master ??^(3??n_master)
  !! @param[out] state Constraint violation state (max_violation, num_violations, etc.)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_CheckViolation(params, surface_pair, slave_coords, &
                                          master_coords, state)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(Tie_Surface_Pair), INTENT(IN) :: surface_pair
    REAL(wp), INTENT(IN) :: slave_coords(:,:)    ! Slave node positions
    REAL(wp), INTENT(IN) :: master_coords(:,:)   ! Master node positions
    TYPE(Tie_Constraint_State), INTENT(OUT) :: state
    
    INTEGER(i4) :: i_pair, i_master, n_master
    REAL(wp) :: pos_slave(3), pos_master_interp(3), violation(3), violation_mag
    REAL(wp) :: total_violation
    TYPE(Tie_Node_Pair) :: pair
    
    state%num_tied_nodes = 0_i4
    state%max_violation = ZERO
    total_violation = ZERO
    state%num_violations = 0_i4
    
    ! Check each node pair
    DO i_pair = 1, surface_pair%num_pairs
      pair = surface_pair%node_pairs(i_pair)
      
      IF (.NOT. pair%is_active) CYCLE
      
      state%num_tied_nodes = state%num_tied_nodes + 1
      
      ! Slave node position
      pos_slave = slave_coords(:, pair%slave_node_id)
      
      ! Interpolate master position
      pos_master_interp = ZERO
      n_master = pair%num_master_nodes
      DO i_master = 1, n_master
        pos_master_interp = pos_master_interp + &
          pair%shape_functions(i_master) * &
          master_coords(:, pair%master_node_ids(i_master))
      END DO
      
      ! Violation magnitude
      violation = pos_slave - pos_master_interp
      violation_mag = SQRT(DOT_PRODUCT(violation, violation))
      
      ! Update statistics
      state%max_violation = MAX(state%max_violation, violation_mag)
      total_violation = total_violation + violation_mag
      
      IF (violation_mag > params%position_tolerance) THEN
        state%num_violations = state%num_violations + 1
      END IF
    END DO
    
    ! Average violation
    IF (state%num_tied_nodes > 0_i4) THEN
      state%avg_violation = total_violation / REAL(state%num_tied_nodes, wp)
    END IF
    
    ! Check if satisfied
    state%is_satisfied = (state%num_violations == 0_i4)
    
  END SUBROUTINE PH_Constr_Tie_CheckViolation

  !=============================================================================
  !> @brief Optimize tie constraint implementation
  !! @details Optimizes tie constraint (e.g., update adaptive weights)
  !! @param[inout] surface_pair Surface pair (may be modified)
  !! @param[in] params Tie constraint parameters
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_Opt(surface_pair, params, status)
    TYPE(Tie_Surface_Pair), INTENT(INOUT) :: surface_pair
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    INTEGER(i4) :: i, ic
    
    CALL init_error_status(status)
    status%status_code = IF_STATUS_OK
    
    IF (params%use_adaptive_weight) THEN
      DO i = 1, surface_pair%num_pairs
        CALL PH_Constr_TieCore_UpdateWeights(surface_pair%node_pairs(i), params, ic)
        IF (ic /= 0_i4) THEN
          CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_Tie')
          RETURN
        END IF
      END DO
    END IF
    
  END SUBROUTINE PH_Constr_Tie_Opt

  !=============================================================================
  !> @brief Compute tie constraint violation
  !! @details Computes violation r = ||u_slave - u_master_interp|| for node pair
  !! @param[in] node_pair Node pair definition (shape functions, master nodes)
  !! @param[in] u_slave Slave displacement u_slave ??^3
  !! @param[in] u_master Master displacements u_master ??^(3??n_master)
  !! @param[out] violation Constraint violation r = ||u_slave - u_master_interp||
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_ComputeViolation(node_pair, u_slave, u_master, violation, status)
    TYPE(Tie_Node_Pair), INTENT(IN) :: node_pair
    REAL(wp), INTENT(IN) :: u_slave(:), u_master(:)
    REAL(wp), INTENT(OUT) :: violation
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ic
    CALL PH_Constr_TieCore_ComputeViolation(node_pair, u_slave, u_master, violation, ic)
    CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_Tie')
  END SUBROUTINE PH_Constr_Tie_ComputeViolation

  !=============================================================================
  !> @brief Update weight factors
  !! @details Updates adaptive weight factors w based on current distance
  !! @param[inout] node_pair Node pair (weight_factor will be updated)
  !! @param[in] params Tie constraint parameters
  !! @param[out] status ErrorStatusType (IF_STATUS_OK / IF_STATUS_INVALID + message)
  !=============================================================================
  SUBROUTINE PH_Constr_Tie_UpdateWeights(node_pair, params, status)
    TYPE(Tie_Node_Pair), INTENT(INOUT) :: node_pair
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: ic
    CALL PH_Constr_TieCore_UpdateWeights(node_pair, params, ic)
    CALL PH_Constr_IntCodeToStatus(ic, status, 'PH_Constr_Tie')
  END SUBROUTINE PH_Constr_Tie_UpdateWeights

END MODULE PH_ConstrTie_Brg

