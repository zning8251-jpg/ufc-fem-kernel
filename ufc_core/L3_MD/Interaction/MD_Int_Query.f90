!======================================================================
! MODULE:  MD_Int_Query
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact query and user function procedures.
!          Find/lookup, node coordinate queries,
!          UF_* user function API.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Query
    USE MD_Int_Types
    USE IF_Prec_Core, ONLY: wp, i4
    IMPLICIT NONE
    PRIVATE

    !==================================================================
    ! PUBLIC procedure interfaces
    !==================================================================
    PUBLIC :: contact_find_Elem_index
    PUBLIC :: contact_find_node_index_in_part
    PUBLIC :: contact_find_node_state_index
    PUBLIC :: contact_get_node_coord_curr
    PUBLIC :: contact_dot3

    ! UF procedures
    PUBLIC :: UF_Contact_ApplyConstraint
    PUBLIC :: UF_Co_ComputeNormalForce_node
    PUBLIC :: UF_Co_ComputeNormalForce_scalar
    PUBLIC :: UF_Contact_ComputeStiffness
    PUBLIC :: UF_Contact_ComputeTotalForce
    PUBLIC :: UF_Co_GetOutputStatistics
    PUBLIC :: UF_Co_Se_GetStatistics
    PUBLIC :: UF_Contact_UpdateState
    PUBLIC :: UF_ContactState_UpdateState
    PUBLIC :: UF_Co_ComputeTotalForce
    PUBLIC :: UF_Co_GetContactPressure
    PUBLIC :: UF_Co_GetSlipDistance
    PUBLIC :: UF_Co_GetStatistics
    PUBLIC :: UF_Co_ComputePenaltyStiffnes

    !==================================================================
    ! INTERFACE alias blocks  (PUBLIC name -> actual procedure name)
    !==================================================================
    INTERFACE UF_Contact_ComputeNormalForce
        MODULE PROCEDURE UF_Co_ComputeNormalForce_node
    END INTERFACE
    PUBLIC :: UF_Contact_ComputeNormalForce

    INTERFACE UF_ContactForce_ComputeNormalForce
        MODULE PROCEDURE UF_Co_ComputeNormalForce_scalar
    END INTERFACE
    PUBLIC :: UF_ContactForce_ComputeNormalForce

    INTERFACE UF_ContactForce_ComputeTotalForce
        MODULE PROCEDURE UF_Co_ComputeTotalForce
    END INTERFACE
    PUBLIC :: UF_ContactForce_ComputeTotalForce

    INTERFACE UF_Contact_GetOutputStatistics
        MODULE PROCEDURE UF_Co_GetOutputStatistics
    END INTERFACE
    PUBLIC :: UF_Contact_GetOutputStatistics

    INTERFACE UF_Contact_Search_GetStatistics
        MODULE PROCEDURE UF_Co_Se_GetStatistics
    END INTERFACE
    PUBLIC :: UF_Contact_Search_GetStatistics

    INTERFACE UF_ContactOutput_GetContactPressure
        MODULE PROCEDURE UF_Co_GetContactPressure
    END INTERFACE
    PUBLIC :: UF_ContactOutput_GetContactPressure

    INTERFACE UF_ContactOutput_GetSlipDistance
        MODULE PROCEDURE UF_Co_GetSlipDistance
    END INTERFACE
    PUBLIC :: UF_ContactOutput_GetSlipDistance

    INTERFACE UF_ContactSearch_GetStatistics
        MODULE PROCEDURE UF_Co_GetStatistics
    END INTERFACE
    PUBLIC :: UF_ContactSearch_GetStatistics

    INTERFACE UF_ContactStiffness_ComputePenaltyStiffness
        MODULE PROCEDURE UF_Co_ComputePenaltyStiffnes
    END INTERFACE
    PUBLIC :: UF_ContactStiffness_ComputePenaltyStiffness

CONTAINS

    !===================================================================
    ! contact_find_Elem_index
    !===================================================================
    FUNCTION contact_find_Elem_index(part, id) RESULT(idx)
        USE MD_Base_ObjModel, ONLY: UF_Part

        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: id
        INTEGER(i4) :: idx
        INTEGER(i4) :: i

        idx = -1_i4
        IF (.NOT. ALLOCATED(part%elements)) RETURN
        DO i = 1, SIZE(part%elements)
            IF (part%elements(i)%cfg%id == id) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION

    !===================================================================
    ! contact_find_node_index_in_part
    !===================================================================
    FUNCTION contact_find_node_index_in_part(part, nodeIdFind) RESULT(idx)
        USE MD_Base_ObjModel, ONLY: UF_Part

        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: nodeIdFind
        INTEGER(i4) :: idx
        INTEGER(i4) :: ii

        idx = -1_i4
        DO ii = 1, SIZE(part%nodes)
            IF (part%nodes(ii)%cfg%id == nodeIdFind) THEN
                idx = ii
                RETURN
            END IF
        END DO
    END FUNCTION

    !===================================================================
    ! contact_find_node_state_index
    !===================================================================
    FUNCTION contact_find_node_state_index(nodeStates, nodeIdFind) RESULT(idx)

        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        INTEGER(i4), INTENT(IN) :: nodeIdFind
        INTEGER(i4) :: idx
        INTEGER(i4) :: ii

        idx = -1_i4
        DO ii = 1, SIZE(nodeStates)
            IF (nodeStates(ii)%cfg%id == nodeIdFind) THEN
                idx = ii
                RETURN
            END IF
        END DO
    END FUNCTION

    !===================================================================
    ! contact_get_node_coord_curr
    !===================================================================
    FUNCTION contact_get_node_coord_curr(part, nodeStates, id) RESULT(x)
        USE MD_Base_ObjModel, ONLY: UF_Part

        TYPE(UF_Part), INTENT(IN) :: part
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        INTEGER(i4), INTENT(IN) :: id
        REAL(wp) :: x(3)
        INTEGER(i4) :: nodeIdx, stateIdx

        nodeIdx = contact_find_node_index_in_part(part, id)
        stateIdx = contact_find_node_state_index(nodeStates, id)
        IF (nodeIdx < 1) THEN
            x = 0.0_wp
            RETURN
        END IF
        x = part%nodes(nodeIdx)%coords
        IF (stateIdx > 0) x = x + nodeStates(stateIdx)%u_curr
    END FUNCTION

    !===================================================================
    ! contact_dot3
    !===================================================================
    FUNCTION contact_dot3(a, b) RESULT(val)
        REAL(wp), INTENT(IN) :: a(3), b(3)
        REAL(wp) :: val
        val = a(1)*b(1) + a(2)*b(2) + a(3)*b(3)
    END FUNCTION

    !===================================================================
    ! UF_Contact_ApplyConstraint
    !===================================================================
    SUBROUTINE UF_Contact_ApplyConstraint(contact_node, penalty_stiffness, &
                                          constraint_force, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: penalty_stiffness
        REAL(wp), INTENT(OUT) :: constraint_force(3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        IF (contact_node%penetration > 0.0_wp) THEN
            constraint_force = penalty_stiffness * contact_node%penetration * &
                              contact_node%normal
        ELSE
            constraint_force = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Co_ComputeNormalForce_node  (ContNode variant)
    ! PUBLIC alias: UF_Contact_ComputeNormalForce
    !===================================================================
    SUBROUTINE UF_Co_ComputeNormalForce_node(contact_node, penalty_stiffness, &
                                              normal_force, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: penalty_stiffness
        REAL(wp), INTENT(OUT) :: normal_force
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        IF (contact_node%penetration > 0.0_wp) THEN
            normal_force = penalty_stiffness * contact_node%penetration
        ELSE
            normal_force = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Co_ComputeNormalForce_scalar  (scalar variant)
    ! PUBLIC alias: UF_ContactForce_ComputeNormalForce
    !===================================================================
    SUBROUTINE UF_Co_ComputeNormalForce_scalar(penetration, penalty_stiffness, &
                                                   normal_force, status)
        REAL(wp), INTENT(IN) :: penetration, penalty_stiffness
        REAL(wp), INTENT(OUT) :: normal_force
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        IF (penetration > 0.0_wp) THEN
            normal_force = penalty_stiffness * penetration
        ELSE
            normal_force = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Contact_ComputeStiffness
    !===================================================================
    SUBROUTINE UF_Contact_ComputeStiffness(contact_node, penalty_stiffness, &
                                            contact_stiffness, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: penalty_stiffness
        REAL(wp), INTENT(OUT) :: contact_stiffness(3,3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i, j

        IF (PRESENT(status)) status = 0

        contact_stiffness = 0.0_wp

        IF (contact_node%penetration > 0.0_wp) THEN
            DO i = 1, 3
                DO j = 1, 3
                    contact_stiffness(i,j) = penalty_stiffness * &
                                            contact_node%normal(i) * &
                                            contact_node%normal(j)
                END DO
            END DO
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Contact_ComputeTotalForce
    !===================================================================
    SUBROUTINE UF_Contact_ComputeTotalForce(force_result, total_force, status)
        TYPE(ContForceRes), INTENT(IN) :: force_result
        REAL(wp), INTENT(OUT) :: total_force(3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i

        IF (PRESENT(status)) status = 0

        total_force = 0.0_wp

        IF (ALLOCATED(force_result%normal_forces)) THEN
            DO i = 1, SIZE(force_result%normal_forces)
                total_force(1) = total_force(1) + force_result%normal_forces(i)
            END DO
        END IF

        IF (ALLOCATED(force_result%tangent_forces)) THEN
            DO i = 1, SIZE(force_result%tangent_forces, 1)
                total_force(2) = total_force(2) + force_result%tangent_forces(i, 1)
                total_force(3) = total_force(3) + force_result%tangent_forces(i, 2)
            END DO
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Co_GetOutputStatistics
    ! PUBLIC alias: UF_Contact_GetOutputStatistics
    !===================================================================
    SUBROUTINE UF_Co_GetOutputStatistics(contact_pair, stats, status)
        TYPE(ContPair), INTENT(IN) :: contact_pair
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        WRITE(stats, '(A,I0,A,I0,A,I0)') &
            'Contact Output Statistics: n_active=', contact_pair%n_active, &
            ', n_slave=', contact_pair%n_slave, &
            ', n_master=', contact_pair%n_master
    END SUBROUTINE

    !===================================================================
    ! UF_Co_Se_GetStatistics
    ! PUBLIC alias: UF_Contact_Search_GetStatistics
    !===================================================================
    SUBROUTINE UF_Co_Se_GetStatistics(search_result, stats, status)
        TYPE(ContPair), INTENT(IN) :: search_result
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        WRITE(stats, '(A,I0,A,I0)') &
            'Contact Search Statistics: n_active=', search_result%n_active, &
            ', n_slave=', search_result%n_slave
    END SUBROUTINE

    !===================================================================
    ! UF_Contact_UpdateState
    !===================================================================
    SUBROUTINE UF_Contact_UpdateState(contact_node, new_coords, new_gap, &
                                      updated_node, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: new_coords(3), new_gap
        TYPE(ContNode), INTENT(OUT) :: updated_node
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        updated_node = contact_node
        updated_node%coords = new_coords
        updated_node%gap = new_gap

        IF (new_gap < 0.0_wp) THEN
            updated_node%penetration = -new_gap
            updated_node%state = CSTATE_STICKING
        ELSE
            updated_node%penetration = 0.0_wp
            updated_node%state = CSTATE_SEPARATE
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_ContactState_UpdateState
    !===================================================================
    SUBROUTINE UF_ContactState_UpdateState(contact_node, gap, penetration, &
                                           contact_state, status)
        TYPE(ContNode), INTENT(INOUT) :: contact_node
        REAL(wp), INTENT(IN) :: gap, penetration
        INTEGER(i4), INTENT(OUT) :: contact_state
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        IF (penetration > 0.0_wp) THEN
            contact_state = CSTATE_STICKING
        ELSE IF (gap < 1.0e-6_wp) THEN
            contact_state = CSTATE_SLIDING
        ELSE
            contact_state = CSTATE_SEPARATE
        END IF

        contact_node%state = contact_state
        contact_node%gap = gap
        contact_node%penetration = penetration
    END SUBROUTINE

    !===================================================================
    ! UF_Co_ComputeTotalForce  (scalar variant)
    ! PUBLIC alias: UF_ContactForce_ComputeTotalForce
    !===================================================================
    SUBROUTINE UF_Co_ComputeTotalForce(normal_force, friction_force, &
                                                  total_force, status)
        REAL(wp), INTENT(IN) :: normal_force
        REAL(wp), INTENT(IN) :: friction_force(3)
        REAL(wp), INTENT(OUT) :: total_force(3)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        total_force(1) = friction_force(1)
        total_force(2) = friction_force(2)
        total_force(3) = normal_force + friction_force(3)
    END SUBROUTINE

    !===================================================================
    ! UF_Co_GetContactPressure
    ! PUBLIC alias: UF_ContactOutput_GetContactPressure
    !===================================================================
    SUBROUTINE UF_Co_GetContactPressure(contact_node, contact_area, &
                                                    contact_pressure, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: contact_area
        REAL(wp), INTENT(OUT) :: contact_pressure
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        IF (contact_area > 1.0e-12_wp) THEN
            contact_pressure = contact_node%force_n / contact_area
        ELSE
            contact_pressure = 0.0_wp
        END IF
    END SUBROUTINE

    !===================================================================
    ! UF_Co_GetSlipDistance
    ! PUBLIC alias: UF_ContactOutput_GetSlipDistance
    !===================================================================
    SUBROUTINE UF_Co_GetSlipDistance(contact_node, slip_distance, status)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(OUT) :: slip_distance
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        IF (PRESENT(status)) status = 0

        slip_distance = contact_node%slip
    END SUBROUTINE

    !===================================================================
    ! UF_Co_GetStatistics
    ! PUBLIC alias: UF_ContactSearch_GetStatistics
    !===================================================================
    SUBROUTINE UF_Co_GetStatistics(search_algorithm, n_candidates, &
                                               n_contacts, stats, status)
        INTEGER(i4), INTENT(IN) :: search_algorithm
        INTEGER(i4), INTENT(IN) :: n_candidates, n_contacts
        CHARACTER(LEN=512), INTENT(OUT) :: stats
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        CHARACTER(LEN=32) :: algo_name

        IF (PRESENT(status)) status = 0

        SELECT CASE (search_algorithm)
        CASE (1)
            algo_name = "Bucket"
        CASE (2)
            algo_name = "Octree"
        CASE (3)
            algo_name = "Spatial_Hash"
        CASE DEFAULT
            algo_name = "Unknown"
        END SELECT

        WRITE(stats, '(A,A,A,I0,A,I0)') &
            'Contact Search Statistics: algorithm="', TRIM(algo_name), &
            '", n_candidates=', n_candidates, &
            ', n_contacts=', n_contacts
    END SUBROUTINE

    !===================================================================
    ! UF_Co_ComputePenaltyStiffnes
    ! PUBLIC alias: UF_ContactStiffness_ComputePenaltyStiffness
    !===================================================================
    SUBROUTINE UF_Co_ComputePenaltyStiffnes(penalty_stiffness, &
                                                            contact_stiffness, &
                                                            ndim, status)
        REAL(wp), INTENT(IN) :: penalty_stiffness
        REAL(wp), INTENT(OUT) :: contact_stiffness(6,6)
        INTEGER(i4), INTENT(IN) :: ndim
        INTEGER(i4), INTENT(OUT), OPTIONAL :: status

        INTEGER(i4) :: i

        IF (PRESENT(status)) status = 0

        contact_stiffness = 0.0_wp
        DO i = 1, MIN(ndim, 6)
            contact_stiffness(i, i) = penalty_stiffness
        END DO
    END SUBROUTINE

END MODULE MD_Int_Query
