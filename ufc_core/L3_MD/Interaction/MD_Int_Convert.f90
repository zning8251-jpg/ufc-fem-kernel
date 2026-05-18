!======================================================================
! MODULE:  MD_Int_Convert
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact geometry and coordinate mapping.
!          Gap computation, projection, shape functions,
!          tangent/normal calculation.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Convert
    USE MD_Int_Types
    IMPLICIT NONE
    PRIVATE

    ! --- Direct PUBLIC procedures ---
    PUBLIC :: Cont_UpdateGeometry, Cont_UpdateGeometry_Simple
    PUBLIC :: Cont_ComputeRelativeVelocity, Cont_ProjectToSurface, Cont_ComputeTangents
    PUBLIC :: Co_Ge_Co_gap_2d, Co_Ge_Co_gap_3d
    PUBLIC :: Cont_Geometry_Compute_jacobian_2d, Cont_Geometry_Compute_jacobian_3d
    PUBLIC :: Co_Ge_Co_no_2d, Co_Ge_Co_no_3d
    PUBLIC :: Co_Ge_Co_ta_2d, Co_Ge_Co_ta_3d
    PUBLIC :: Co_Ge_ne_pr_3d
    PUBLIC :: Co_Ge_pr_po_2d, Co_Ge_pr_po_3d
    PUBLIC :: Co_Ge_sh_fu_2d, Co_Ge_sh_fu_3d
    PUBLIC :: Co_Ge_up_co_point
    PUBLIC :: project_point_to_quad_3d, project_point_to_segment_2d

    ! --- PUBLIC name aliases ---
    INTERFACE Cont_Geometry_project_point_2d
        MODULE PROCEDURE Co_Ge_pr_po_2d
    END INTERFACE
    PUBLIC :: Cont_Geometry_project_point_2d

    INTERFACE Cont_Geometry_project_point_3d
        MODULE PROCEDURE Co_Ge_pr_po_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_project_point_3d

    INTERFACE Cont_Geometry_Compute_gap_2d
        MODULE PROCEDURE Co_Ge_Co_gap_2d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_gap_2d

    INTERFACE Cont_Geometry_Compute_gap_3d
        MODULE PROCEDURE Co_Ge_Co_gap_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_gap_3d

    INTERFACE Cont_Geometry_Compute_normal_2d
        MODULE PROCEDURE Co_Ge_Co_no_2d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_normal_2d

    INTERFACE Cont_Geometry_Compute_normal_3d
        MODULE PROCEDURE Co_Ge_Co_no_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_normal_3d

    INTERFACE Cont_Geometry_Compute_tangent_2d
        MODULE PROCEDURE Co_Ge_Co_ta_2d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_tangent_2d

    INTERFACE Cont_Geometry_Compute_tangent_3d
        MODULE PROCEDURE Co_Ge_Co_ta_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_Compute_tangent_3d

    INTERFACE Cont_Geometry_shape_functions_2d
        MODULE PROCEDURE Co_Ge_sh_fu_2d
    END INTERFACE
    PUBLIC :: Cont_Geometry_shape_functions_2d

    INTERFACE Cont_Geometry_shape_functions_3d
        MODULE PROCEDURE Co_Ge_sh_fu_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_shape_functions_3d

    INTERFACE Cont_Geometry_newton_projection_3d
        MODULE PROCEDURE Co_Ge_ne_pr_3d
    END INTERFACE
    PUBLIC :: Cont_Geometry_newton_projection_3d

    INTERFACE Cont_Geometry_update_contact_point
        MODULE PROCEDURE Co_Ge_up_co_point
    END INTERFACE
    PUBLIC :: Cont_Geometry_update_contact_point

CONTAINS

    SUBROUTINE Cont_UpdateGeometry(contact_node, displacements, gap, &
                                    n_vector, t1_vector, t2_vector)
        TYPE(ContNode), INTENT(INOUT) :: contact_node
        REAL(wp), INTENT(IN) :: displacements(:)
        REAL(wp), INTENT(OUT) :: gap, n_vector(3), t1_vector(3), t2_vector(3)
        INTEGER(i4) :: node_idx
        REAL(wp) :: node_pos(3), proj_pos(3), vector_gap(3)
        node_idx = contact_node%global_id
        node_pos = contact_node%coords_init + displacements(3*node_idx-2:3*node_idx)
        CALL Cont_ProjectToSurface(contact_node%matched_segment, node_pos, proj_pos, n_vector)
        vector_gap = node_pos - proj_pos
        gap = SQRT(DOT_PRODUCT(vector_gap, vector_gap))
        IF (gap > 0.0_wp) THEN
            n_vector = vector_gap / gap
        ELSE
            n_vector = [0.0_wp, 0.0_wp, 1.0_wp]
        END IF
        CALL Cont_ComputeTangents(n_vector, t1_vector, t2_vector)
    END SUBROUTINE

    SUBROUTINE Cont_UpdateGeometry_Simple(contact_node, displacements, gap, n_vector)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: displacements(:)
        REAL(wp), INTENT(OUT) :: gap, n_vector(3)
        INTEGER(i4) :: node_idx
        REAL(wp) :: node_pos(3), proj_pos(3)
        node_idx = contact_node%global_id
        node_pos = contact_node%coords_init + displacements(3*node_idx-2:3*node_idx)
        proj_pos = node_pos - [0.0_wp, 0.0_wp, contact_node%gap]
        n_vector = [0.0_wp, 0.0_wp, 1.0_wp]
        gap = contact_node%gap
    END SUBROUTINE

    SUBROUTINE Cont_ComputeRelativeVelocity(contact_node, velocities, relative_veloci)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: velocities(:)
        REAL(wp), INTENT(OUT) :: relative_veloci(3)
        INTEGER(i4) :: node_idx
        node_idx = contact_node%global_id
        relative_veloci = velocities(3*node_idx-2:3*node_idx)
    END SUBROUTINE

    SUBROUTINE Cont_ProjectToSurface(surface_id, point, projection, normal)
        INTEGER(i4), INTENT(IN) :: surface_id
        REAL(wp), INTENT(IN) :: point(3)
        REAL(wp), INTENT(OUT) :: projection(3), normal(3)
        projection = point
        normal = [0.0_wp, 0.0_wp, 1.0_wp]
    END SUBROUTINE

    SUBROUTINE Cont_ComputeTangents(normal, tangent1, tangent2)
        REAL(wp), INTENT(IN) :: normal(3)
        REAL(wp), INTENT(OUT) :: tangent1(3), tangent2(3)
        IF (ABS(normal(1)) < ABS(normal(2))) THEN
            tangent1 = [normal(2), -normal(1), 0.0_wp]
        ELSE
            tangent1 = [0.0_wp, normal(3), -normal(2)]
        END IF
        tangent1 = tangent1 / SQRT(DOT_PRODUCT(tangent1, tangent1))
        tangent2 = md_cont_cross_product(normal, tangent1)
    END SUBROUTINE

    SUBROUTINE Co_Ge_Co_gap_2d(P_slave, P_A, P_B, gap, penetration, &
                                        xi, P_proj, normal, tangent)
        REAL(wp), INTENT(IN) :: P_slave(3), P_A(3), P_B(3)
        REAL(wp), INTENT(OUT) :: gap, penetration, xi, P_proj(3), normal(3), tangent(3)
        REAL(wp) :: dist_vec(3), seg_len
        LOGICAL :: valid
        CALL Co_Ge_pr_po_2d(P_slave, P_A, P_B, xi, P_proj, valid)
        CALL Co_Ge_Co_ta_2d(P_A, P_B, tangent, seg_len)
        CALL Co_Ge_Co_no_2d(tangent, normal)
        dist_vec = P_slave - P_proj
        gap = dist_vec(2)*normal(2) + dist_vec(3)*normal(3)
        penetration = -gap
        IF (penetration < 0.0_wp) penetration = 0.0_wp
    END SUBROUTINE

    SUBROUTINE Co_Ge_Co_gap_3d(P_slave, P_nodes, gap, penetration, &
                                        xi, eta, P_proj, normal)
        REAL(wp), INTENT(IN) :: P_slave(3), P_nodes(3,4)
        REAL(wp), INTENT(OUT) :: gap, penetration, xi, eta, P_proj(3), normal(3)
        REAL(wp) :: dist_vec(3)
        LOGICAL :: valid
        INTEGER(i4) :: ierr
        CALL Co_Ge_pr_po_3d(P_slave, P_nodes, xi, eta, P_proj, valid, ierr)
        CALL Co_Ge_Co_no_3d(P_nodes, xi, eta, normal)
        dist_vec = P_slave - P_proj
        gap = SUM(dist_vec * normal)
        penetration = -gap
        IF (penetration < 0.0_wp) penetration = 0.0_wp
    END SUBROUTINE

    FUNCTION Cont_Geometry_Compute_jacobian_2d(P_A, P_B) RESULT(jacobian)
        REAL(wp), INTENT(IN) :: P_A(3), P_B(3)
        REAL(wp) :: jacobian, dy, dz
        dy = P_B(2) - P_A(2); dz = P_B(3) - P_A(3)
        jacobian = 0.5_wp * SQRT(dy*dy + dz*dz)
    END FUNCTION

    FUNCTION Cont_Geometry_Compute_jacobian_3d(P_nodes, xi, eta) RESULT(jacobian)
        REAL(wp), INTENT(IN) :: P_nodes(3,4), xi, eta
        REAL(wp) :: jacobian, dXdxi(3), dXdeta(3), cross(3)
        REAL(wp) :: N(4), dNdxi(4), dNdeta(4)
        INTEGER(i4) :: i
        CALL Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
        dXdxi = 0.0_wp; dXdeta = 0.0_wp
        DO i = 1, 4
            dXdxi = dXdxi + dNdxi(i) * P_nodes(:,i)
            dXdeta = dXdeta + dNdeta(i) * P_nodes(:,i)
        END DO
        cross(1) = dXdxi(2)*dXdeta(3) - dXdxi(3)*dXdeta(2)
        cross(2) = dXdxi(3)*dXdeta(1) - dXdxi(1)*dXdeta(3)
        cross(3) = dXdxi(1)*dXdeta(2) - dXdxi(2)*dXdeta(1)
        jacobian = SQRT(SUM(cross**2))
    END FUNCTION

    SUBROUTINE Co_Ge_Co_no_2d(tangent, normal)
        REAL(wp), INTENT(IN) :: tangent(3)
        REAL(wp), INTENT(OUT) :: normal(3)
        normal(1) = 0.0_wp; normal(2) = -tangent(3); normal(3) = tangent(2)
    END SUBROUTINE

    SUBROUTINE Co_Ge_Co_no_3d(P_nodes, xi, eta, normal)
        REAL(wp), INTENT(IN) :: P_nodes(3,4), xi, eta
        REAL(wp), INTENT(OUT) :: normal(3)
        REAL(wp) :: dXdxi(3), dXdeta(3), cross(3), mag
        REAL(wp) :: N(4), dNdxi(4), dNdeta(4)
        INTEGER(i4) :: i
        CALL Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
        dXdxi = 0.0_wp; dXdeta = 0.0_wp
        DO i = 1, 4
            dXdxi = dXdxi + dNdxi(i) * P_nodes(:,i)
            dXdeta = dXdeta + dNdeta(i) * P_nodes(:,i)
        END DO
        cross(1) = dXdxi(2)*dXdeta(3) - dXdxi(3)*dXdeta(2)
        cross(2) = dXdxi(3)*dXdeta(1) - dXdxi(1)*dXdeta(3)
        cross(3) = dXdxi(1)*dXdeta(2) - dXdxi(2)*dXdeta(1)
        mag = SQRT(SUM(cross**2))
        IF (mag > GEOM_TOL) THEN
            normal = cross / mag
        ELSE
            normal = 0.0_wp; normal(3) = 1.0_wp
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Ge_Co_ta_2d(P_A, P_B, tangent, length)
        REAL(wp), INTENT(IN) :: P_A(3), P_B(3)
        REAL(wp), INTENT(OUT) :: tangent(3), length
        REAL(wp) :: dy, dz
        dy = P_B(2) - P_A(2); dz = P_B(3) - P_A(3)
        length = SQRT(dy*dy + dz*dz)
        IF (length > GEOM_TOL) THEN
            tangent(1) = 0.0_wp; tangent(2) = dy / length; tangent(3) = dz / length
        ELSE
            tangent = 0.0_wp
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Ge_Co_ta_3d(P_nodes, xi, eta, t1, t2)
        REAL(wp), INTENT(IN) :: P_nodes(3,4), xi, eta
        REAL(wp), INTENT(OUT) :: t1(3), t2(3)
        REAL(wp) :: N(4), dNdxi(4), dNdeta(4), mag
        INTEGER(i4) :: i
        CALL Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
        t1 = 0.0_wp; t2 = 0.0_wp
        DO i = 1, 4
            t1 = t1 + dNdxi(i) * P_nodes(:,i)
            t2 = t2 + dNdeta(i) * P_nodes(:,i)
        END DO
        mag = SQRT(SUM(t1**2)); IF (mag > GEOM_TOL) t1 = t1 / mag
        t2 = t2 - SUM(t2 * t1) * t1
        mag = SQRT(SUM(t2**2)); IF (mag > GEOM_TOL) t2 = t2 / mag
    END SUBROUTINE

    SUBROUTINE Co_Ge_ne_pr_3d(P_slave, P_nodes, n_nodes, xi, eta, P_proj, converged)
        REAL(wp), INTENT(IN) :: P_slave(3), P_nodes(3,*)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(INOUT) :: xi, eta
        REAL(wp), INTENT(OUT) :: P_proj(3)
        LOGICAL, INTENT(OUT) :: converged
        INTEGER(i4) :: iter, i
        REAL(wp) :: r(3), dXdxi(3), dXdeta(3), A(2,2), b(2), dxi(2), det
        REAL(wp) :: N(4), dNdxi(4), dNdeta(4), res_norm, alpha
        converged = .FALSE.
        DO iter = 1, MAX_NEWTON_ITER
            CALL Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
            P_proj = 0.0_wp; dXdxi = 0.0_wp; dXdeta = 0.0_wp
            DO i = 1, MIN(n_nodes, 4)
                P_proj = P_proj + N(i) * P_nodes(:,i)
                dXdxi = dXdxi + dNdxi(i) * P_nodes(:,i)
                dXdeta = dXdeta + dNdeta(i) * P_nodes(:,i)
            END DO
            r = P_slave - P_proj
            b(1) = SUM(r * dXdxi); b(2) = SUM(r * dXdeta)
            res_norm = SQRT(b(1)**2 + b(2)**2)
            IF (res_norm < NEWTON_TOL) THEN; converged = .TRUE.; EXIT; END IF
            A(1,1) = SUM(dXdxi * dXdxi); A(1,2) = SUM(dXdxi * dXdeta)
            A(2,1) = A(1,2); A(2,2) = SUM(dXdeta * dXdeta)
            det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
            IF (ABS(det) < GEOM_TOL) EXIT
            dxi(1) = (A(2,2)*b(1) - A(1,2)*b(2)) / det
            dxi(2) = (A(1,1)*b(2) - A(2,1)*b(1)) / det
            alpha = 1.0_wp; xi = xi + alpha * dxi(1); eta = eta + alpha * dxi(2)
            xi = MAX(-1.5_wp, MIN(1.5_wp, xi)); eta = MAX(-1.5_wp, MIN(1.5_wp, eta))
        END DO
    END SUBROUTINE

    SUBROUTINE Co_Ge_pr_po_2d(P_slave, P_A, P_B, xi, P_proj, valid)
        REAL(wp), INTENT(IN) :: P_slave(3), P_A(3), P_B(3)
        REAL(wp), INTENT(OUT) :: xi, P_proj(3)
        LOGICAL, INTENT(OUT) :: valid
        REAL(wp) :: seg_vec(3), pt_vec(3), seg_len, t_param
        seg_vec = P_B - P_A; seg_len = SQRT(seg_vec(2)**2 + seg_vec(3)**2)
        IF (seg_len < GEOM_TOL) THEN
            xi = 0.0_wp; P_proj = P_A; valid = .FALSE.; RETURN
        END IF
        pt_vec = P_slave - P_A
        t_param = (pt_vec(2)*seg_vec(2) + pt_vec(3)*seg_vec(3)) / (seg_len * seg_len)
        xi = 2.0_wp * t_param - 1.0_wp
        valid = (xi >= -1.0_wp - GEOM_TOL .AND. xi <= 1.0_wp + GEOM_TOL)
        t_param = MAX(0.0_wp, MIN(1.0_wp, t_param))
        P_proj(1) = 0.0_wp
        P_proj(2) = P_A(2) + t_param * seg_vec(2)
        P_proj(3) = P_A(3) + t_param * seg_vec(3)
    END SUBROUTINE

    SUBROUTINE Co_Ge_pr_po_3d(P_slave, P_nodes, xi, eta, P_proj, valid, ierr)
        REAL(wp), INTENT(IN) :: P_slave(3), P_nodes(3,4)
        REAL(wp), INTENT(OUT) :: xi, eta, P_proj(3)
        LOGICAL, INTENT(OUT) :: valid
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: iter, i
        REAL(wp) :: r(3), dXdxi(3), dXdeta(3), A(2,2), b(2), dxi(2), det
        REAL(wp) :: N(4), dNdxi(4), dNdeta(4), res_norm
        IF (PRESENT(ierr)) ierr = 0
        xi = 0.0_wp; eta = 0.0_wp
        DO iter = 1, MAX_NEWTON_ITER
            CALL Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
            P_proj = 0.0_wp; dXdxi = 0.0_wp; dXdeta = 0.0_wp
            DO i = 1, 4
                P_proj = P_proj + N(i) * P_nodes(:,i)
                dXdxi = dXdxi + dNdxi(i) * P_nodes(:,i)
                dXdeta = dXdeta + dNdeta(i) * P_nodes(:,i)
            END DO
            r = P_slave - P_proj
            b(1) = SUM(r * dXdxi); b(2) = SUM(r * dXdeta)
            res_norm = SQRT(b(1)**2 + b(2)**2)
            IF (res_norm < NEWTON_TOL) EXIT
            A(1,1) = SUM(dXdxi * dXdxi); A(1,2) = SUM(dXdxi * dXdeta)
            A(2,1) = A(1,2); A(2,2) = SUM(dXdeta * dXdeta)
            det = A(1,1)*A(2,2) - A(1,2)*A(2,1)
            IF (ABS(det) < GEOM_TOL) THEN
                IF (PRESENT(ierr)) ierr = 1; EXIT
            END IF
            dxi(1) = (A(2,2)*b(1) - A(1,2)*b(2)) / det
            dxi(2) = (A(1,1)*b(2) - A(2,1)*b(1)) / det
            xi = xi + dxi(1); eta = eta + dxi(2)
            xi = MAX(-2.0_wp, MIN(2.0_wp, xi)); eta = MAX(-2.0_wp, MIN(2.0_wp, eta))
        END DO
        valid = (ABS(xi) <= 1.0_wp + GEOM_TOL .AND. ABS(eta) <= 1.0_wp + GEOM_TOL)
        CALL Co_Ge_sh_fu_3d(xi, eta, N)
        P_proj = 0.0_wp
        DO i = 1, 4; P_proj = P_proj + N(i) * P_nodes(:,i); END DO
    END SUBROUTINE

    SUBROUTINE Co_Ge_sh_fu_2d(xi, N, dN)
        REAL(wp), INTENT(IN) :: xi
        REAL(wp), INTENT(OUT) :: N(2)
        REAL(wp), INTENT(OUT), OPTIONAL :: dN(2)
        N(1) = 0.5_wp * (1.0_wp - xi); N(2) = 0.5_wp * (1.0_wp + xi)
        IF (PRESENT(dN)) THEN; dN(1) = -0.5_wp; dN(2) = 0.5_wp; END IF
    END SUBROUTINE

    SUBROUTINE Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(4)
        REAL(wp), INTENT(OUT), OPTIONAL :: dNdxi(4), dNdeta(4)
        N(1) = 0.25_wp * (1.0_wp - xi) * (1.0_wp - eta)
        N(2) = 0.25_wp * (1.0_wp + xi) * (1.0_wp - eta)
        N(3) = 0.25_wp * (1.0_wp + xi) * (1.0_wp + eta)
        N(4) = 0.25_wp * (1.0_wp - xi) * (1.0_wp + eta)
        IF (PRESENT(dNdxi)) THEN
            dNdxi(1) = -0.25_wp * (1.0_wp - eta); dNdxi(2) = 0.25_wp * (1.0_wp - eta)
            dNdxi(3) = 0.25_wp * (1.0_wp + eta); dNdxi(4) = -0.25_wp * (1.0_wp + eta)
        END IF
        IF (PRESENT(dNdeta)) THEN
            dNdeta(1) = -0.25_wp * (1.0_wp - xi); dNdeta(2) = -0.25_wp * (1.0_wp + xi)
            dNdeta(3) = 0.25_wp * (1.0_wp + xi); dNdeta(4) = 0.25_wp * (1.0_wp - xi)
        END IF
    END SUBROUTINE

    SUBROUTINE Co_Ge_up_co_point(node, master_surf, seg_id, xi, eta)
        TYPE(ContNode), INTENT(INOUT) :: node
        TYPE(ContSurface), INTENT(IN) :: master_surf
        INTEGER(i4), INTENT(IN) :: seg_id
        REAL(wp), INTENT(IN) :: xi, eta
        INTEGER(i4) :: i, n_nodes
        REAL(wp) :: N(4), P_proj(3), normal(3), tangent1(3), tangent2(3)
        IF (seg_id <= 0 .OR. seg_id > master_surf%n_segments) RETURN
        n_nodes = master_surf%segments(seg_id)%pop%n_nodes
        CALL Co_Ge_sh_fu_3d(xi, eta, N)
        P_proj = 0.0_wp
        DO i = 1, MIN(n_nodes, 4)
            P_proj = P_proj + N(i) * master_surf%coords_current(:, master_surf%segments(seg_id)%nodes(i))
        END DO
        CALL Co_Ge_Co_no_3d(master_surf%coords_current(:, master_surf%segments(seg_id)%nodes(1:MIN(n_nodes,4))), &
                               xi, eta, normal)
        CALL Co_Ge_Co_ta_3d(master_surf%coords_current(:, master_surf%segments(seg_id)%nodes(1:MIN(n_nodes,4))), &
                                xi, eta, tangent1, tangent2)
        node%coords = P_proj; node%normal = normal; node%tangent = tangent1
        node%xi_local(1) = xi; node%xi_local(2) = eta
    END SUBROUTINE

    SUBROUTINE project_point_to_quad_3d(slave_pt, master_coords, master_element, &
                                         proj_pt, normal, tangent1, tangent2, gap, xi_param, converged, tol)
        REAL(wp), INTENT(IN) :: slave_pt(3), master_coords(:,:), tol
        INTEGER(i4), INTENT(IN) :: master_element(:)
        REAL(wp), INTENT(OUT) :: proj_pt(3), normal(3), tangent1(3), tangent2(3), gap, xi_param(2)
        LOGICAL, INTENT(OUT) :: converged
        REAL(wp) :: P_nodes(3,4)
        INTEGER(i4) :: i
        DO i = 1, 4; P_nodes(:, i) = master_coords(:, master_element(i)); END DO
        CALL Co_Ge_pr_po_3d(slave_pt, P_nodes, xi_param(1), xi_param(2), proj_pt, converged)
        CALL Co_Ge_Co_no_3d(P_nodes, xi_param(1), xi_param(2), normal)
        CALL Co_Ge_Co_ta_3d(P_nodes, xi_param(1), xi_param(2), tangent1, tangent2)
        gap = SUM((slave_pt - proj_pt) * normal)
    END SUBROUTINE

    SUBROUTINE project_point_to_segment_2d(slave_pt, master_coords, master_element, &
                                            proj_pt, normal, tangent, gap, xi_param, in_contact, tol)
        REAL(wp), INTENT(IN) :: slave_pt(2), master_coords(:,:), tol
        INTEGER(i4), INTENT(IN) :: master_element(:)
        REAL(wp), INTENT(OUT) :: proj_pt(2), normal(2), tangent(2), gap, xi_param
        LOGICAL, INTENT(OUT) :: in_contact
        REAL(wp) :: P_A(2), P_B(2), seg_vec(2), pt_vec(2), seg_len, t_param
        P_A = master_coords(:, master_element(1)); P_B = master_coords(:, master_element(2))
        seg_vec = P_B - P_A; seg_len = SQRT(seg_vec(1)**2 + seg_vec(2)**2)
        IF (seg_len < GEOM_TOL) THEN
            xi_param = 0.0_wp; proj_pt = P_A; in_contact = .FALSE.
            gap = 0.0_wp; normal = 0.0_wp; tangent = 0.0_wp; RETURN
        END IF
        pt_vec = slave_pt - P_A
        t_param = (pt_vec(1)*seg_vec(1) + pt_vec(2)*seg_vec(2)) / (seg_len * seg_len)
        xi_param = 2.0_wp * t_param - 1.0_wp
        in_contact = (xi_param >= -1.0_wp - GEOM_TOL .AND. xi_param <= 1.0_wp + GEOM_TOL)
        t_param = MAX(0.0_wp, MIN(1.0_wp, t_param))
        proj_pt = P_A + t_param * seg_vec
        tangent = seg_vec / seg_len; normal(1) = -tangent(2); normal(2) = tangent(1)
        gap = (slave_pt(1) - proj_pt(1)) * normal(1) + (slave_pt(2) - proj_pt(2)) * normal(2)
    END SUBROUTINE

END MODULE MD_Int_Convert
