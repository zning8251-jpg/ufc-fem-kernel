!======================================================================
! MODULE:  MD_Int_Stiffness
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact stiffness computation and assembly.
!          Local stiffness, CSR assembly, penalty/ALM
!          stiffness, triplet assembly, force vectors.
! STATUS:  FOUR-TYPE-REFACTORED (B1 header)
! DATE:    2026-04-28
!======================================================================
MODULE MD_Int_Stiffness
    USE MD_Int_Types
    USE MD_Int_Manager, ONLY: contact_collect_surface_nodes, &
                              contact_Eval_face_gap, &
                              contact_decode_global_surf_id
    IMPLICIT NONE
    PRIVATE

    ! --- Direct PUBLIC procedures ---
    PUBLIC :: Cont_AsmPenaltyStiff
    PUBLIC :: md_cont_add_stif_contact_to_csr
    PUBLIC :: md_cont_assemble_stif_csr
    PUBLIC :: md_cont_csr_find_position
    PUBLIC :: alm_stif_csr, alm_stif_csr_from_nodes
    PUBLIC :: penalty_stif_csr
    PUBLIC :: contact_stif_pattern_csr
    PUBLIC :: Co_Co_st_lo_2d, Co_Co_st_lo_3d, Co_Co_st_fo_vector
    PUBLIC :: contact_add_contact_k, contact_add_force
    PUBLIC :: co_As_co_pair
    PUBLIC :: co_as_su_to_su_penalty, co_as_su_to_su_pe_cross
    PUBLIC :: contact_Assemble_triplets
    PUBLIC :: contact_add_contact_k_Arg, contact_add_force_Arg
    PUBLIC :: contact_Assemble_triplets_Arg

    ! --- PUBLIC name aliases ---
    INTERFACE Cont_Compute_stif_local_2d
        MODULE PROCEDURE Co_Co_st_lo_2d
    END INTERFACE
    PUBLIC :: Cont_Compute_stif_local_2d

    INTERFACE Cont_Compute_stif_local_3d
        MODULE PROCEDURE Co_Co_st_lo_3d
    END INTERFACE
    PUBLIC :: Cont_Compute_stif_local_3d

    INTERFACE Cont_Compute_stif_force_vector
        MODULE PROCEDURE Co_Co_st_fo_vector
    END INTERFACE
    PUBLIC :: Cont_Compute_stif_force_vector

    INTERFACE contact_Assemble_contact_pair
        MODULE PROCEDURE co_As_co_pair
    END INTERFACE
    PUBLIC :: contact_Assemble_contact_pair

    INTERFACE contact_assemble_surface_to_surface_penalty
        MODULE PROCEDURE co_as_su_to_su_penalty
    END INTERFACE
    PUBLIC :: contact_assemble_surface_to_surface_penalty

    INTERFACE contact_assemble_surface_to_surface_penalty_cross
        MODULE PROCEDURE co_as_su_to_su_pe_cross
    END INTERFACE
    PUBLIC :: contact_assemble_surface_to_surface_penalty_cross

CONTAINS

    SUBROUTINE Cont_AsmPenaltyStiff(contact_node, penalty_normal, penalty_tangent, &
                                               n_vector, t1_vector, t2_vector, stiffness)
        TYPE(ContNode), INTENT(IN) :: contact_node
        REAL(wp), INTENT(IN) :: penalty_normal, penalty_tangent
        REAL(wp), INTENT(IN) :: n_vector(3), t1_vector(3), t2_vector(3)
        REAL(wp), INTENT(INOUT) :: stiffness(:,:)
        INTEGER(i4) :: node_idx, dof_start, i, j
        REAL(wp) :: K_local(3,3)
        node_idx = contact_node%global_id
        dof_start = 3 * (node_idx - 1) + 1
        K_local = 0.0_wp
        K_local(1,1) = penalty_normal
        K_local(2,2) = penalty_tangent
        K_local(3,3) = penalty_tangent
        DO i = 1, 3
        DO j = 1, 3
            stiffness(dof_start+i-1, dof_start+j-1) = &
                stiffness(dof_start+i-1, dof_start+j-1) + K_local(i,j)
        END DO
        END DO
    END SUBROUTINE

    SUBROUTINE md_cont_add_stif_contact_to_csr(K_local, F_local, dof_ids, n_local, &
                                             row_ptr, col_idx, values, F_global, &
                                             n_eq, ierr)
        REAL(wp), INTENT(IN) :: K_local(:,:), F_local(:)
        INTEGER(i4), INTENT(IN) :: dof_ids(:), n_local
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:), F_global(:)
        INTEGER(i4), INTENT(IN) :: n_eq
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: i, j, row, col, pos
        REAL(wp) :: val
        IF (PRESENT(ierr)) ierr = 0
        DO i = 1, n_local
            row = dof_ids(i)
            IF (row <= 0 .OR. row > n_eq) CYCLE
            DO j = 1, n_local
                col = dof_ids(j)
                IF (col <= 0 .OR. col > n_eq) CYCLE
                val = K_local(i, j)
                IF (ABS(val) < STIFF_TOL) CYCLE
                pos = md_cont_csr_find_position(row, col, row_ptr, col_idx)
                IF (pos > 0) THEN
                    values(pos) = values(pos) + val
                ELSE
                    IF (PRESENT(ierr)) ierr = -1
                END IF
            END DO
        END DO
        DO i = 1, n_local
            row = dof_ids(i)
            IF (row > 0 .AND. row <= n_eq) THEN
                F_global(row) = F_global(row) + F_local(i)
            END IF
        END DO
    END SUBROUTINE

    SUBROUTINE md_cont_assemble_stif_csr(K_local, dof_indices, row_ptr, col_idx, values)
        REAL(wp), INTENT(IN) :: K_local(:,:)
        INTEGER(i4), INTENT(IN) :: dof_indices(:)
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:)
        INTEGER(i4) :: i, j, row, col, pos, n_local
        n_local = SIZE(dof_indices)
        DO i = 1, n_local
            row = dof_indices(i)
            DO j = 1, n_local
                col = dof_indices(j)
                pos = md_cont_csr_find_position(row, col, row_ptr, col_idx)
                IF (pos > 0) THEN
                    values(pos) = values(pos) + K_local(i,j)
                END IF
            END DO
        END DO
    END SUBROUTINE

    FUNCTION md_cont_csr_find_position(row, col, row_ptr, col_idx) RESULT(pos)
        INTEGER(i4), INTENT(IN) :: row, col
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        INTEGER(i4) :: pos, k
        pos = 0
        DO k = row_ptr(row), row_ptr(row+1) - 1
            IF (col_idx(k) == col) THEN
                pos = k
                EXIT
            END IF
        END DO
    END FUNCTION

    SUBROUTINE alm_stif_csr(dim, n_contact_point, contact_nodes, &
                                  gaps, normals, tangents, &
                                  lambda, contact_state, contact_pressur, &
                                  eps_n, eps_t, mu, tol, &
                                  row_ptr, col_idx, values, F_global, &
                                  n_eq, converged, ierr)
        INTEGER(i4), INTENT(IN) :: dim, n_contact_point
        INTEGER(i4), INTENT(IN) :: contact_nodes(:)
        REAL(wp), INTENT(IN) :: gaps(:), normals(:,:), tangents(:,:)
        REAL(wp), INTENT(INOUT) :: lambda(:)
        INTEGER(i4), INTENT(INOUT) :: contact_state(:)
        REAL(wp), INTENT(INOUT), OPTIONAL :: contact_pressur(:)
        REAL(wp), INTENT(IN) :: eps_n, eps_t, mu, tol
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:), F_global(:)
        INTEGER(i4), INTENT(IN) :: n_eq
        LOGICAL, INTENT(OUT) :: converged
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: ic, node_s, i, j, pos, dof_s(3)
        REAL(wp) :: gap, normal(3), tangent(3), lambda_trial, pn, k_val, f_val, max_violation
        IF (PRESENT(ierr)) ierr = 0
        max_violation = 0.0_wp
        converged = .TRUE.
        DO ic = 1, n_contact_point
            node_s = contact_nodes(ic)
            gap = gaps(ic)
            normal(1:dim) = normals(1:dim, ic)
            tangent(1:dim) = tangents(1:dim, ic)
            lambda_trial = lambda(ic) + eps_n * gap
            IF (lambda_trial > 0.0_wp .OR. gap < 0.0_wp) THEN
                pn = MAX(lambda_trial, 0.0_wp)
                DO i = 1, dim
                    dof_s(i) = dim * (node_s - 1) + i
                END DO
                DO i = 1, dim
                    IF (dof_s(i) > n_eq) CYCLE
                    DO j = 1, dim
                        IF (dof_s(j) > n_eq) CYCLE
                        k_val = eps_n * normal(i) * normal(j)
                        pos = md_cont_csr_find_position(dof_s(i), dof_s(j), row_ptr, col_idx)
                        IF (pos > 0) values(pos) = values(pos) + k_val
                    END DO
                    f_val = pn * normal(i)
                    F_global(dof_s(i)) = F_global(dof_s(i)) + f_val
                END DO
                IF (gap < 0.0_wp) max_violation = MAX(max_violation, ABS(gap))
                IF (PRESENT(contact_pressur)) contact_pressur(ic) = pn
                contact_state(ic) = CSTATE_STICKING
            ELSE
                contact_state(ic) = CSTATE_SEPARATE
            END IF
            lambda(ic) = MAX(lambda_trial, 0.0_wp)
        END DO
        converged = (max_violation < tol)
    END SUBROUTINE

    SUBROUTINE alm_stif_csr_from_nodes(dim, contact_nodes, n_contact_point, &
                                            eps_n, eps_t, mu, tol, &
                                            row_ptr, col_idx, values, F_global, &
                                            n_eq, converged, ierr)
        INTEGER(i4), INTENT(IN) :: dim
        TYPE(ContNode), INTENT(INOUT) :: contact_nodes(:)
        INTEGER(i4), INTENT(IN) :: n_contact_point
        REAL(wp), INTENT(IN) :: eps_n, eps_t, mu, tol
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:), F_global(:)
        INTEGER(i4), INTENT(IN) :: n_eq
        LOGICAL, INTENT(OUT) :: converged
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: ic, i, j, pos, dof_s(3)
        TYPE(ContNode), POINTER :: node
        REAL(wp) :: gap, normal(3), lambda_trial, pn, k_val, f_val, max_violation
        IF (PRESENT(ierr)) ierr = 0
        max_violation = 0.0_wp
        converged = .TRUE.
        DO ic = 1, n_contact_point
            node => contact_nodes(ic)
            gap = node%gap
            normal(1:dim) = node%normal(1:dim)
            lambda_trial = node%lambda + eps_n * gap
            IF (lambda_trial > 0.0_wp .OR. gap < 0.0_wp) THEN
                pn = MAX(lambda_trial, 0.0_wp)
                SELECT CASE (dim)
                CASE (2)
                    dof_s(1) = node%dof_y; dof_s(2) = node%dof_z
                CASE (3)
                    dof_s(1) = node%dof_x; dof_s(2) = node%dof_y; dof_s(3) = node%dof_z
                CASE DEFAULT
                    CYCLE
                END SELECT
                DO i = 1, dim
                    IF (dof_s(i) <= 0 .OR. dof_s(i) > n_eq) CYCLE
                    DO j = 1, dim
                        IF (dof_s(j) <= 0 .OR. dof_s(j) > n_eq) CYCLE
                        k_val = eps_n * normal(i) * normal(j)
                        pos = md_cont_csr_find_position(dof_s(i), dof_s(j), row_ptr, col_idx)
                        IF (pos > 0) values(pos) = values(pos) + k_val
                    END DO
                    f_val = pn * normal(i)
                    F_global(dof_s(i)) = F_global(dof_s(i)) + f_val
                END DO
                IF (gap < 0.0_wp) max_violation = MAX(max_violation, ABS(gap))
                node%state = CSTATE_STICKING
                node%force_n = pn
            ELSE
                node%state = CSTATE_SEPARATE
                node%force_n = 0.0_wp
            END IF
            node%lambda = MAX(lambda_trial, 0.0_wp)
        END DO
        converged = (max_violation < tol)
    END SUBROUTINE

    SUBROUTINE penalty_stif_csr(dim, n_contact_point, contact_nodes, &
                                      gaps, normals, tangents, contact_state, &
                                      tangential_slip, eps_n, eps_t, mu, &
                                      row_ptr, col_idx, values, F_global, &
                                      n_eq, ierr)
        INTEGER(i4), INTENT(IN) :: dim, n_contact_point
        INTEGER(i4), INTENT(IN) :: contact_nodes(:)
        REAL(wp), INTENT(IN) :: gaps(:), normals(:,:), tangents(:,:)
        INTEGER(i4), INTENT(IN) :: contact_state(:)
        REAL(wp), INTENT(IN), OPTIONAL :: tangential_slip(:,:)
        REAL(wp), INTENT(IN) :: eps_n, eps_t, mu
        INTEGER(i4), INTENT(IN) :: row_ptr(:), col_idx(:)
        REAL(wp), INTENT(INOUT) :: values(:), F_global(:)
        INTEGER(i4), INTENT(IN) :: n_eq
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: ic, node_s, i, j, dof_s(3), pos
        REAL(wp) :: gap, normal(3), tangent(3), fn, k_val, f_val
        IF (PRESENT(ierr)) ierr = 0
        DO ic = 1, n_contact_point
            node_s = contact_nodes(ic)
            gap = gaps(ic)
            IF (gap >= 0.0_wp) CYCLE
            normal(1:dim) = normals(1:dim, ic)
            tangent(1:dim) = tangents(1:dim, ic)
            fn = -eps_n * gap
            DO i = 1, dim
                dof_s(i) = dim * (node_s - 1) + i
            END DO
            DO i = 1, dim
                IF (dof_s(i) > n_eq) CYCLE
                DO j = 1, dim
                    IF (dof_s(j) > n_eq) CYCLE
                    k_val = eps_n * normal(i) * normal(j)
                    IF (contact_state(ic) == CSTATE_STICKING .AND. mu > 0.0_wp) THEN
                        k_val = k_val + eps_t * tangent(i) * tangent(j)
                    END IF
                    pos = md_cont_csr_find_position(dof_s(i), dof_s(j), row_ptr, col_idx)
                    IF (pos > 0) values(pos) = values(pos) + k_val
                END DO
                f_val = fn * normal(i)
                IF (mu > 0.0_wp .AND. PRESENT(tangential_slip)) THEN
                    IF (contact_state(ic) == CSTATE_STICKING) THEN
                        f_val = f_val + eps_t * tangential_slip(i, ic)
                    ELSE IF (contact_state(ic) == CSTATE_SLIDING) THEN
                        f_val = f_val + mu * fn * tangent(i)
                    END IF
                END IF
                F_global(dof_s(i)) = F_global(dof_s(i)) + f_val
            END DO
        END DO
    END SUBROUTINE

    SUBROUTINE contact_stif_pattern_csr(slave_surf, master_surf, dim, &
                                              pattern_rows, pattern_cols, n_pattern)
        TYPE(ContSurface), INTENT(IN) :: slave_surf, master_surf
        INTEGER(i4), INTENT(IN) :: dim
        INTEGER(i4), ALLOCATABLE, INTENT(OUT) :: pattern_rows(:), pattern_cols(:)
        INTEGER(i4), INTENT(OUT) :: n_pattern
        INTEGER(i4) :: is, seg_id, i, j, m, im, k
        INTEGER(i4) :: slave_dofs(3), master_dofs(12)
        INTEGER(i4) :: n_slave_dof, n_master_dof, max_pattern
        INTEGER(i4), ALLOCATABLE :: temp_rows(:), temp_cols(:)
        max_pattern = slave_surf%pop%n_nodes * master_surf%n_segments * (dim * 5)**2
        ALLOCATE(temp_rows(max_pattern), temp_cols(max_pattern))
        n_pattern = 0
        n_slave_dof = dim
        n_master_dof = dim * 4
        DO is = 1, slave_surf%pop%n_nodes
            IF (ALLOCATED(slave_surf%dof_map)) THEN
                DO i = 1, dim
                    slave_dofs(i) = slave_surf%dof_map(i, is)
                END DO
            ELSE
                CYCLE
            END IF
            DO seg_id = 1, master_surf%n_segments
                k = 0
                DO m = 1, MIN(4, master_surf%segments(seg_id)%pop%n_nodes)
                    im = master_surf%segments(seg_id)%nodes(m)
                    IF (ALLOCATED(master_surf%dof_map)) THEN
                        DO i = 1, dim
                            k = k + 1
                            master_dofs(k) = master_surf%dof_map(i, im)
                        END DO
                    END IF
                END DO
                n_master_dof = k
                DO i = 1, n_slave_dof
                    DO j = 1, n_slave_dof
                        n_pattern = n_pattern + 1
                        IF (n_pattern <= max_pattern) THEN
                            temp_rows(n_pattern) = slave_dofs(i)
                            temp_cols(n_pattern) = slave_dofs(j)
                        END IF
                    END DO
                END DO
                DO i = 1, n_slave_dof
                    DO j = 1, n_master_dof
                        n_pattern = n_pattern + 1
                        IF (n_pattern <= max_pattern) THEN
                            temp_rows(n_pattern) = slave_dofs(i)
                            temp_cols(n_pattern) = master_dofs(j)
                        END IF
                    END DO
                END DO
                DO i = 1, n_master_dof
                    DO j = 1, n_slave_dof
                        n_pattern = n_pattern + 1
                        IF (n_pattern <= max_pattern) THEN
                            temp_rows(n_pattern) = master_dofs(i)
                            temp_cols(n_pattern) = slave_dofs(j)
                        END IF
                    END DO
                END DO
                DO i = 1, n_master_dof
                    DO j = 1, n_master_dof
                        n_pattern = n_pattern + 1
                        IF (n_pattern <= max_pattern) THEN
                            temp_rows(n_pattern) = master_dofs(i)
                            temp_cols(n_pattern) = master_dofs(j)
                        END IF
                    END DO
                END DO
            END DO
        END DO
        n_pattern = MIN(n_pattern, max_pattern)
        ALLOCATE(pattern_rows(n_pattern), pattern_cols(n_pattern))
        pattern_rows = temp_rows(1:n_pattern)
        pattern_cols = temp_cols(1:n_pattern)
        DEALLOCATE(temp_rows, temp_cols)
    END SUBROUTINE

    SUBROUTINE Co_Co_st_fo_vector(penalty_n, normal, penetration, force)
        REAL(wp), INTENT(IN) :: penalty_n, normal(:), penetration
        REAL(wp), INTENT(OUT) :: force(:)
        IF (penetration <= 0.0_wp) THEN
            force = 0.0_wp
            RETURN
        END IF
        force = penalty_n * penetration * normal
    END SUBROUTINE

    SUBROUTINE Co_Co_st_lo_2d(penalty_n, penalty_t, normal, tangent, &
                                           penetration, K_local, F_local)
        REAL(wp), INTENT(IN) :: penalty_n, penalty_t, normal(2), tangent(2), penetration
        REAL(wp), INTENT(OUT) :: K_local(4,4), F_local(4)
        REAL(wp) :: Bn(4), Bt(4), p_n
        IF (penetration <= 0.0_wp) THEN
            K_local = 0.0_wp; F_local = 0.0_wp; RETURN
        END IF
        p_n = penalty_n * penetration
        Bn(1) = normal(1); Bn(2) = normal(2); Bn(3) = -normal(1); Bn(4) = -normal(2)
        Bt(1) = tangent(1); Bt(2) = tangent(2); Bt(3) = -tangent(1); Bt(4) = -tangent(2)
        K_local = penalty_n * SPREAD(Bn, 1, 4) * SPREAD(Bn, 2, 4)
        F_local = p_n * Bn
    END SUBROUTINE

    SUBROUTINE Co_Co_st_lo_3d(penalty_n, penalty_t, normal, tangent1, tangent2, &
                                           penetration, K_local, F_local)
        REAL(wp), INTENT(IN) :: penalty_n, penalty_t, normal(3), tangent1(3), tangent2(3), penetration
        REAL(wp), INTENT(OUT) :: K_local(6,6), F_local(6)
        REAL(wp) :: Bn(6), Bt1(6), Bt2(6), p_n
        IF (penetration <= 0.0_wp) THEN
            K_local = 0.0_wp; F_local = 0.0_wp; RETURN
        END IF
        p_n = penalty_n * penetration
        Bn(1:3) = normal; Bn(4:6) = -normal
        Bt1(1:3) = tangent1; Bt1(4:6) = -tangent1
        Bt2(1:3) = tangent2; Bt2(4:6) = -tangent2
        K_local = penalty_n * SPREAD(Bn, 1, 6) * SPREAD(Bn, 2, 6)
        F_local = p_n * Bn
    END SUBROUTINE

    SUBROUTINE contact_add_contact_k(eqRow, eqCol, penalty, scale, nrm, triplets)
        USE MD_ContRT_Brg, ONLY: RT_TripletList, MD_RT_Cont_TripletAdd
        INTEGER(i4), INTENT(IN) :: eqRow(3), eqCol(3)
        REAL(wp), INTENT(IN) :: penalty, scale, nrm(3)
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        INTEGER(i4) :: i, j
        REAL(wp) :: val
        DO i = 1, 3
            IF (eqRow(i) < 1) CYCLE
            DO j = 1, 3
                IF (eqCol(j) < 1) CYCLE
                val = penalty * scale * nrm(i) * nrm(j)
                CALL MD_RT_Cont_TripletAdd(triplets, eqRow(i), eqCol(j), val)
            END DO
        END DO
    END SUBROUTINE

    SUBROUTINE contact_add_force(eq, f, R)
        INTEGER(i4), INTENT(IN) :: eq(3)
        REAL(wp), INTENT(IN) :: f(3)
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4) :: i
        DO i = 1, 3
            IF (eq(i) > 0 .AND. eq(i) <= SIZE(R)) THEN
                R(eq(i)) = R(eq(i)) - f(i)
            END IF
        END DO
    END SUBROUTINE

    SUBROUTINE contact_add_contact_k_Arg(triplets, arg)
        USE MD_ContRT_Brg, ONLY: RT_TripletList
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        TYPE(MD_IC_ContactAddK_Arg), INTENT(IN) :: arg
        CALL contact_add_contact_k(arg%eqRow, arg%eqCol, arg%penalty, arg%scale, arg%nrm, triplets)
    END SUBROUTINE

    SUBROUTINE contact_add_force_Arg(R, arg)
        REAL(wp), INTENT(INOUT) :: R(:)
        TYPE(MD_IC_ContactAddForce_Arg), INTENT(IN) :: arg
        CALL contact_add_force(arg%eq, arg%f, R)
    END SUBROUTINE

    SUBROUTINE co_As_co_pair(slaveNodeId, masterNodeIds, nMaster, nrm, gap, penalty, w, dofMap, triplets, R)
        USE MD_ContRT_Brg, ONLY: RT_Sol_DofMap, RT_TripletList, &
                                   MD_RT_Cont_GetEqId, MD_RT_Cont_TripletAdd
        INTEGER(i4), INTENT(IN) :: slaveNodeId, nMaster
        INTEGER(i4), INTENT(IN) :: masterNodeIds(:)
        REAL(wp), INTENT(IN) :: nrm(3), gap, penalty, w
        TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4) :: ia, ib
        INTEGER(i4) :: eqS(3), eqA(3), eqB(3)
        REAL(wp) :: fS(3), fA(3), kAB
        eqS(1) = MD_RT_Cont_GetEqId(dofMap, slaveNodeId, 1_i4)
        eqS(2) = MD_RT_Cont_GetEqId(dofMap, slaveNodeId, 2_i4)
        eqS(3) = MD_RT_Cont_GetEqId(dofMap, slaveNodeId, 3_i4)
        fS = -penalty * gap * nrm
        CALL contact_add_force(eqS, fS, R)
        DO ia = 1, nMaster
            eqA(1) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 1_i4)
            eqA(2) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 2_i4)
            eqA(3) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 3_i4)
            fA = penalty * gap * w * nrm
            CALL contact_add_force(eqA, fA, R)
        END DO
        CALL contact_add_contact_k(eqS, eqS, penalty, 1.0_wp, nrm, triplets)
        DO ia = 1, nMaster
            eqA(1) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 1_i4)
            eqA(2) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 2_i4)
            eqA(3) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 3_i4)
            CALL contact_add_contact_k(eqS, eqA, penalty, -w, nrm, triplets)
            CALL contact_add_contact_k(eqA, eqS, penalty, -w, nrm, triplets)
        END DO
        DO ia = 1, nMaster
            eqA(1) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 1_i4)
            eqA(2) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 2_i4)
            eqA(3) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ia), 3_i4)
            DO ib = 1, nMaster
                eqB(1) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ib), 1_i4)
                eqB(2) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ib), 2_i4)
                eqB(3) = MD_RT_Cont_GetEqId(dofMap, masterNodeIds(ib), 3_i4)
                kAB = w * w
                CALL contact_add_contact_k(eqA, eqB, penalty, kAB, nrm, triplets)
            END DO
        END DO
    END SUBROUTINE

    SUBROUTINE co_as_su_to_su_penalty(part, masterSurfId, slaveSurfId, &
                                                      penalty, dofMap, nodeStates, triplets, R)
        USE MD_ContRT_Brg, ONLY: RT_Sol_DofMap, RT_TripletList
        USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes
        USE MD_Base_ObjModel, ONLY: UF_Part
        TYPE(UF_Part), INTENT(IN) :: part
        INTEGER(i4), INTENT(IN) :: masterSurfId, slaveSurfId
        REAL(wp), INTENT(IN) :: penalty
        TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4), ALLOCATABLE :: slaveNodes(:)
        INTEGER(i4) :: nSlave, iS, slaveNodeId
        INTEGER(i4) :: masterFaceIdx, bestElemId, bestFaceId, nFaceNode
        REAL(wp) :: bestGap, xSlave(3), nrm(3), xMaster0(3)
        INTEGER(i4) :: localNodes(9), masterElemIdx
        TYPE(UF_ElementType), POINTER :: ElemType
        REAL(wp) :: w
        IF (.NOT. ALLOCATED(part%surfSets)) RETURN
        IF (masterSurfId > SIZE(part%surfSets)) RETURN
        IF (slaveSurfId > SIZE(part%surfSets)) RETURN
        IF (.NOT. ALLOCATED(part%surfSets(masterSurfId)%faces)) RETURN
        IF (.NOT. ALLOCATED(part%surfSets(slaveSurfId)%faces)) RETURN
        IF (.NOT. ALLOCATED(part%elements)) RETURN
        IF (.NOT. ALLOCATED(part%nodes)) RETURN
        CALL contact_collect_surface_nodes(part, slaveSurfId, slaveNodes, nSlave)
        IF (nSlave < 1) RETURN
        DO iS = 1, nSlave
            slaveNodeId = slaveNodes(iS)
            xSlave = contact_get_node_coord_curr(part, nodeStates, slaveNodeId)
            bestGap = HUGE(1.0_wp); bestElemId = -1_i4; bestFaceId = -1_i4
            DO masterFaceIdx = 1, SIZE(part%surfSets(masterSurfId)%faces, 2)
                CALL contact_Eval_face_gap(part, nodeStates, &
                    part%surfSets(masterSurfId)%faces(1, masterFaceIdx), &
                    part%surfSets(masterSurfId)%faces(2, masterFaceIdx), &
                    xSlave, bestGap, bestElemId, bestFaceId, nrm, xMaster0)
            END DO
            IF (bestElemId < 1) CYCLE
            IF (bestGap >= 0.0_wp) CYCLE
            masterElemIdx = contact_find_Elem_index(part, bestElemId)
            IF (masterElemIdx < 1) CYCLE
            ElemType => UF_GetElementType(part%elements(masterElemIdx)%elemTypeId)
            IF (.NOT. ASSOCIATED(ElemType)) CYCLE
            CALL UF_GetFaceLocalNodes(ElemType, bestFaceId, localNodes, nFaceNode)
            IF (nFaceNode < 3) CYCLE
            w = 1.0_wp / REAL(nFaceNode, wp)
            CALL co_As_co_pair(slaveNodeId, &
                part%elements(masterElemIdx)%conn(localNodes(1:nFaceNode)), &
                nFaceNode, nrm, bestGap, penalty, w, dofMap, triplets, R)
        END DO
        DEALLOCATE(slaveNodes)
    END SUBROUTINE

    SUBROUTINE co_as_su_to_su_pe_cross(partMaster, partSlave, masterSurfId, slaveSurfId, &
                                                             penalty, dofMap, nodeStates, triplets, R)
        USE MD_ContRT_Brg, ONLY: RT_Sol_DofMap, RT_TripletList
        USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes
        USE MD_Base_ObjModel, ONLY: UF_Part
        TYPE(UF_Part), INTENT(IN) :: partMaster, partSlave
        INTEGER(i4), INTENT(IN) :: masterSurfId, slaveSurfId
        REAL(wp), INTENT(IN) :: penalty
        TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4), ALLOCATABLE :: slaveNodes(:)
        INTEGER(i4) :: nSlave, iS, slaveNodeId
        INTEGER(i4) :: masterFaceIdx, bestElemId, bestFaceId, nFaceNode
        REAL(wp) :: bestGap, xSlave(3), nrm(3), xMaster0(3)
        INTEGER(i4) :: localNodes(9), masterElemIdx
        TYPE(UF_ElementType), POINTER :: ElemType
        REAL(wp) :: w
        IF (.NOT. ALLOCATED(partMaster%surfSets)) RETURN
        IF (.NOT. ALLOCATED(partSlave%surfSets)) RETURN
        IF (masterSurfId > SIZE(partMaster%surfSets)) RETURN
        IF (slaveSurfId > SIZE(partSlave%surfSets)) RETURN
        IF (.NOT. ALLOCATED(partMaster%surfSets(masterSurfId)%faces)) RETURN
        IF (.NOT. ALLOCATED(partSlave%surfSets(slaveSurfId)%faces)) RETURN
        IF (.NOT. ALLOCATED(partMaster%elements)) RETURN
        IF (.NOT. ALLOCATED(partSlave%elements)) RETURN
        IF (.NOT. ALLOCATED(partMaster%nodes)) RETURN
        IF (.NOT. ALLOCATED(partSlave%nodes)) RETURN
        CALL contact_collect_surface_nodes(partSlave, slaveSurfId, slaveNodes, nSlave)
        IF (nSlave < 1) RETURN
        DO iS = 1, nSlave
            slaveNodeId = slaveNodes(iS)
            xSlave = contact_get_node_coord_curr(partSlave, nodeStates, slaveNodeId)
            bestGap = HUGE(1.0_wp); bestElemId = -1_i4; bestFaceId = -1_i4
            DO masterFaceIdx = 1, SIZE(partMaster%surfSets(masterSurfId)%faces, 2)
                CALL contact_Eval_face_gap(partMaster, nodeStates, &
                    partMaster%surfSets(masterSurfId)%faces(1, masterFaceIdx), &
                    partMaster%surfSets(masterSurfId)%faces(2, masterFaceIdx), &
                    xSlave, bestGap, bestElemId, bestFaceId, nrm, xMaster0)
            END DO
            IF (bestElemId < 1) CYCLE
            IF (bestGap >= 0.0_wp) CYCLE
            masterElemIdx = contact_find_Elem_index(partMaster, bestElemId)
            IF (masterElemIdx < 1) CYCLE
            ElemType => UF_GetElementType(partMaster%elements(masterElemIdx)%elemTypeId)
            IF (.NOT. ASSOCIATED(ElemType)) CYCLE
            CALL UF_GetFaceLocalNodes(ElemType, bestFaceId, localNodes, nFaceNode)
            IF (nFaceNode < 3) CYCLE
            w = 1.0_wp / REAL(nFaceNode, wp)
            CALL co_As_co_pair(slaveNodeId, &
                partMaster%elements(masterElemIdx)%conn(localNodes(1:nFaceNode)), &
                nFaceNode, nrm, bestGap, penalty, w, dofMap, triplets, R)
        END DO
        DEALLOCATE(slaveNodes)
    END SUBROUTINE

    SUBROUTINE contact_Assemble_triplets(model, dofMap, nodeStates, triplets, R, ierr)
        USE MD_ContRT_Brg, ONLY: RT_Sol_DofMap, RT_TripletList
        USE MD_Mesh_Mgr, ONLY: UF_ElementType, UF_GetElementType, UF_GetFaceLocalNodes
        USE MD_Base_ObjModel, ONLY: UF_Model, UF_Part
        TYPE(UF_Model), INTENT(IN) :: model
        TYPE(RT_Sol_DofMap), INTENT(IN) :: dofMap
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        INTEGER(i4) :: iInt, masterId, slaveId, masterPart, slavePart, masterLocalId, slaveLocalId
        REAL(wp) :: penalty
        IF (PRESENT(ierr)) ierr = 0
        IF (.NOT. ALLOCATED(model%interactions)) RETURN
        IF (.NOT. ALLOCATED(model%parts)) RETURN
        IF (SIZE(model%parts) < 1) RETURN
        penalty = 1.0E12_wp
        DO iInt = 1, SIZE(model%interactions)
            IF (model%interactions(iInt)%type /= 2_i4) CYCLE
            masterId = model%interactions(iInt)%masterSurfId
            slaveId = model%interactions(iInt)%slaveSurfId
            IF (masterId < 1 .OR. slaveId < 1) CYCLE
            CALL contact_decode_global_surf_id(model, masterId, masterPart, masterLocalId)
            CALL contact_decode_global_surf_id(model, slaveId, slavePart, slaveLocalId)
            IF (masterLocalId < 1 .OR. slaveLocalId < 1) CYCLE
            IF (masterPart > 0 .AND. slavePart > 0) THEN
                IF (masterPart == slavePart) THEN
                    CALL co_as_su_to_su_penalty(model%parts(masterPart), &
                        masterLocalId, slaveLocalId, penalty, dofMap, nodeStates, triplets, R)
                ELSE
                    CALL co_as_su_to_su_pe_cross(model%parts(masterPart), model%parts(slavePart), &
                        masterLocalId, slaveLocalId, penalty, dofMap, nodeStates, triplets, R)
                END IF
            END IF
        END DO
    END SUBROUTINE

    SUBROUTINE contact_Assemble_triplets_Arg(arg, nodeStates, triplets, R, ierr)
        USE MD_ContRT_Brg, ONLY: RT_TripletList
        TYPE(MD_IC_ContactAssemTriplets_Arg), INTENT(IN) :: arg
        TYPE(MD_NodeDisp), INTENT(IN) :: nodeStates(:)
        TYPE(RT_TripletList), INTENT(INOUT) :: triplets
        REAL(wp), INTENT(INOUT) :: R(:)
        INTEGER(i4), INTENT(OUT), OPTIONAL :: ierr
        IF (.NOT. ASSOCIATED(arg%model) .OR. .NOT. ASSOCIATED(arg%dofMap)) THEN
            IF (PRESENT(ierr)) ierr = -1_i4
            RETURN
        END IF
        CALL contact_Assemble_triplets(arg%model, arg%dofMap, nodeStates, triplets, R, ierr)
    END SUBROUTINE

END MODULE MD_Int_Stiffness
