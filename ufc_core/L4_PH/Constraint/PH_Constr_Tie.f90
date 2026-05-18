!===============================================================================
! MODULE: PH_Constr_Tie
! LAYER:  L4_PH
! DOMAIN: Constraint
! ROLE:   Eval — core Tie constraint algorithm implementations
! BRIEF:  Surface projection, penalty/Lagrange enforcement for tie constraints.
!===============================================================================
! Theory:
!   Surface projection: Find nearest master element for each slave node
!   Weight computation: w = 1 / (1 + d/d_tol) (adaptive)
!   Constraint force: F = -k * w * (u_slave - u_master_interp)
! Status:  CORE | Last verified: 2026-03-01
!
! Contents (A-Z):
!   Types:
!     - (None)
!   Subroutines:
!     - PH_Constr_TieCore_BuildNodePair
!     - PH_Constr_TieCore_CalcElemCenterDistance
!     - PH_Constr_TieCore_CalcWeights
!     - PH_Constr_TieCore_ComputeViolation
!     - PH_Constr_TieCore_FindNearestMasterElem
!     - PH_Constr_TieCore_UpdateWeights
!   Functions:
!     - (None)
!===============================================================================

MODULE PH_Constr_Tie
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF, SMALL_VAL => SMALL
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_ConstrTie_Def
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! Public interface (only for API layer)
  ! ==========================================================================
  PUBLIC :: PH_Constr_TieCore_CalcWeights
  PUBLIC :: PH_Constr_TieCore_ComputeViolation
  PUBLIC :: PH_Constr_TieCore_UpdateWeights
  PUBLIC :: PH_Constr_TieCore_FindNearestMasterElem
  PUBLIC :: PH_Constr_TieCore_BuildNodePair

  !=============================================================================
  ! INTF-001 Tie
  ! Purpose: PH_Constr_TieCore_FindNearestMasterElem 7
  ! Theory: dist = ||x_slave - x_elem_center||�?  ! See module header.
  ! Status: Draft |
  !=============================================================================
  PUBLIC :: PH_Constr_TieCore_FindNearestArgs

  TYPE :: PH_Constr_TieCore_FindNearestArgs
    ! ---- ----
    TYPE(Tie_Constraint_Params), POINTER :: params => NULL()  ! parameter / descriptor ptr

    ! ---- ----
    REAL(wp) :: slave_pos(3) = 0.0_wp  ! slave node position
    REAL(wp), POINTER :: master_coords(:,:) => NULL()  !! (3, n_nodes)
    INTEGER(i4), POINTER :: connectivity(:,:) => NULL()  !! (nodes_per_elem, n_elem)

    ! ---- ----
    INTEGER(i4) :: nearest_elem       = 0_i4        !! ID
    REAL(wp)    :: projection_coords(3) = 0.0_wp  ! projected master coordinates
    REAL(wp)    :: distance             = 0.0_wp  ! closest-point distance
  END TYPE PH_Constr_TieCore_FindNearestArgs

CONTAINS

  SUBROUTINE PH_Constr_TieCore_BuildNodePair(slave_id, master_elem, connectivity, &
                                 local_coords, distance, pair)
    INTEGER(i4), INTENT(IN) :: slave_id, master_elem
    INTEGER(i4), INTENT(IN) :: connectivity(:,:)
    REAL(wp), INTENT(IN) :: local_coords(3), distance
    TYPE(Tie_Node_Pair), INTENT(OUT) :: pair

    INTEGER(i4) :: n_nodes, i

    pair%slave_node_id = slave_id
    pair%master_element_id = master_elem
    pair%local_coords = local_coords
    pair%initial_distance = distance
    pair%weight_factor = ONE
    pair%is_active = .FALSE.

    ! Allocate master nodes
    n_nodes = SIZE(connectivity, 1)
    pair%num_master_nodes = n_nodes
    ALLOCATE(pair%master_node_ids(n_nodes))
    ALLOCATE(pair%shape_functions(n_nodes))

    pair%master_node_ids = connectivity(:, master_elem)

    ! Compute shape functions (simplified: equal weights)
    DO i = 1, n_nodes
      pair%shape_functions(i) = ONE / REAL(n_nodes, wp)
    END DO

  END SUBROUTINE PH_Constr_TieCore_BuildNodePair

  SUBROUTINE PH_Constr_TieCore_CalcElemCenterDistance(point, coords, elem_nodes, &
                                          distance, projection)
    REAL(wp), INTENT(IN) :: point(3)
    REAL(wp), INTENT(IN) :: coords(:,:)
    INTEGER(i4), INTENT(IN) :: elem_nodes(:)
    REAL(wp), INTENT(OUT) :: distance, projection(3)

    INTEGER(i4) :: n_nodes, i
    REAL(wp) :: center(3), diff(3)

    n_nodes = SIZE(elem_nodes)
    center = ZERO

    ! Compute element center
    DO i = 1, n_nodes
      center = center + coords(:, elem_nodes(i))
    END DO
    center = center / REAL(n_nodes, wp)

    ! Distance to center
    diff = point - center
    distance = SQRT(DOT_PRODUCT(diff, diff))

    ! Projection: element center (simplified)
    projection = center

  END SUBROUTINE PH_Constr_TieCore_CalcElemCenterDistance

  SUBROUTINE PH_Constr_TieCore_CalcWeights(params, surface_pair)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    TYPE(Tie_Surface_Pair), INTENT(INOUT) :: surface_pair

    INTEGER(i4) :: i
    REAL(wp) :: distance, d_tol

    IF (.NOT. params%use_adaptive_weight) THEN
      ! Uniform weights
      DO i = 1, surface_pair%num_pairs
        surface_pair%node_pairs(i)%weight_factor = ONE
      END DO
      RETURN
    END IF

    d_tol = params%weight_distance_scale

    ! Adaptive weights
    DO i = 1, surface_pair%num_pairs
      distance = surface_pair%node_pairs(i)%initial_distance

      ! Weight: w = 1 / (1 + d/d_tol)
      surface_pair%node_pairs(i)%weight_factor = &
        ONE / (ONE + distance / MAX(d_tol, SMALL_VAL))

      ! Clamp to [0.01, 1.0]
      surface_pair%node_pairs(i)%weight_factor = &
        MAX(0.01_wp, MIN(ONE, surface_pair%node_pairs(i)%weight_factor))
    END DO

  END SUBROUTINE PH_Constr_TieCore_CalcWeights

  SUBROUTINE PH_Constr_TieCore_ComputeViolation(node_pair, u_slave, u_master, violation, status)
    TYPE(Tie_Node_Pair), INTENT(IN) :: node_pair
    REAL(wp), INTENT(IN) :: u_slave(:), u_master(:)
    REAL(wp), INTENT(OUT) :: violation
    INTEGER(i4), INTENT(OUT) :: status

    INTEGER(i4) :: i
    REAL(wp) :: u_master_interp(3)

    status = 0_i4

    ! Interpolate master displacement
    u_master_interp = ZERO
    DO i = 1, node_pair%num_master_nodes
      u_master_interp = u_master_interp + &
                       node_pair%shape_functions(i) * &
                       u_master(3*(node_pair%master_node_ids(i)-1)+1: &
                                3*node_pair%master_node_ids(i))
    END DO

    ! Violation = ||u_slave - u_master_interp||
    violation = SQRT(SUM((u_slave(1:3) - u_master_interp)**2))

  END SUBROUTINE PH_Constr_TieCore_ComputeViolation

  SUBROUTINE PH_Constr_TieCore_FindNearestMasterElem(params, slave_pos, master_coords, &
                                        connectivity, nearest_elem, &
                                        projection_coords, distance)
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    REAL(wp), INTENT(IN) :: slave_pos(3)
    REAL(wp), INTENT(IN) :: master_coords(:,:)
    INTEGER(i4), INTENT(IN) :: connectivity(:,:)
    INTEGER(i4), INTENT(OUT) :: nearest_elem
    REAL(wp), INTENT(OUT) :: projection_coords(3)
    REAL(wp), INTENT(OUT) :: distance

    INTEGER(i4) :: n_elem, i_elem
    REAL(wp) :: min_distance, elem_distance, proj_coords(3)

    n_elem = SIZE(connectivity, 2)
    min_distance = HUGE(ONE)
    nearest_elem = 1_i4
    projection_coords = ZERO

    ! Search: find nearest element
    DO i_elem = 1, n_elem
      CALL PH_Constr_TieCore_CalcElemCenterDistance(slave_pos, master_coords, &
                                        connectivity(:, i_elem), &
                                        elem_distance, proj_coords)

      IF (elem_distance < min_distance) THEN
        min_distance = elem_distance
        nearest_elem = i_elem
        projection_coords = proj_coords
      END IF
    END DO

    distance = min_distance

  END SUBROUTINE PH_Constr_TieCore_FindNearestMasterElem

  SUBROUTINE PH_Constr_TieCore_UpdateWeights(node_pair, params, status)
    TYPE(Tie_Node_Pair), INTENT(INOUT) :: node_pair
    TYPE(Tie_Constraint_Params), INTENT(IN) :: params
    INTEGER(i4), INTENT(OUT) :: status

    REAL(wp) :: distance_ratio

    status = 0_i4

    IF (params%position_tolerance > SMALL_VAL) THEN
      distance_ratio = node_pair%initial_distance / params%position_tolerance
      node_pair%weight_factor = ONE / (ONE + distance_ratio * params%weight_distance_scale)
    ELSE
      node_pair%weight_factor = ONE
    END IF

  END SUBROUTINE PH_Constr_TieCore_UpdateWeights
END MODULE PH_Constr_Tie