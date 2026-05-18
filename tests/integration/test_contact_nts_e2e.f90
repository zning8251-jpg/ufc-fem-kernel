!===============================================================================
! Module: test_contact_nts_e2e
! Layer:  L4_PH - Physics Layer (Integration Test)
! Domain: Contact
! Purpose: End-to-end integration test for PH_Cont_NTS_Eval module.
!          Validates the complete NTS contact pipeline:
!          BVH search → NTS projection → gap → penalty force → Coulomb friction
!          → contact stiffness matrix.
!
! Test Cases:
!   Case 1: Normal contact — two flat plates (pure penetration)
!   Case 2: Sliding friction — Coulomb return mapping (stick/slip)
!   Case 3: NTS projection accuracy on curved master segment
!   Case 4: BVH search correctness (no miss, no false positive)
!   Case 5: Contact tangent stiffness symmetry + finite difference check
!
! Status: Integration Test | Created: 2026-04-28
!===============================================================================
MODULE test_contact_nts_e2e
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_NTS_Eval
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: run_all_nts_e2e_tests

  ! Tolerances
  REAL(wp), PARAMETER :: TOL_FORCE  = 1.0E-8_wp
  REAL(wp), PARAMETER :: TOL_PROJ   = 1.0E-12_wp
  REAL(wp), PARAMETER :: TOL_FD     = 1.0E-4_wp

CONTAINS

  !===========================================================================
  ! Main driver
  !===========================================================================
  SUBROUTINE run_all_nts_e2e_tests()
    INTEGER(i4) :: n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,'(A)') '============================================================'
    WRITE(*,'(A)') ' Contact NTS End-to-End Integration Tests'
    WRITE(*,'(A)') '============================================================'

    CALL test_case1_normal_contact(n_pass, n_fail)
    CALL test_case2_sliding_friction(n_pass, n_fail)
    CALL test_case3_nts_projection_accuracy(n_pass, n_fail)
    CALL test_case4_bvh_search(n_pass, n_fail)
    CALL test_case5_stiffness_symmetry(n_pass, n_fail)

    WRITE(*,'(A)') '============================================================'
    WRITE(*,'(A,I3,A,I3)') ' SUMMARY: PASS=', n_pass, '  FAIL=', n_fail
    WRITE(*,'(A)') '============================================================'
    IF (n_fail > 0) THEN
      WRITE(*,'(A)') ' *** SOME TESTS FAILED ***'
    ELSE
      WRITE(*,'(A)') ' ALL TESTS PASSED'
    END IF

  END SUBROUTINE run_all_nts_e2e_tests

  !===========================================================================
  ! Case 1: Normal contact — two flat plates (pure penetration)
  !===========================================================================
  ! Upper panel: 4-node QUAD4, z=1.0 (slave surface)
  ! Lower panel: 4-node QUAD4, z=0.0 (master surface)
  ! Slave node displaced downward by 0.1 → penetration = 0.1
  ! Expected:
  !   gap_n = -0.1
  !   f_n = eps_n * 0.1
  !   f_t = 0 (no tangential motion → no friction)
  !===========================================================================
  SUBROUTINE test_case1_normal_contact(n_pass, n_fail)
    INTEGER(i4), INTENT(INOUT) :: n_pass, n_fail

    TYPE(PH_NTS_Pair)  :: pair
    TYPE(PH_NTS_Props) :: props
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES)
    REAL(wp) :: x_slave(3)
    REAL(wp) :: f_nodal(3*(4+1))
    REAL(wp) :: K_contact(3*(4+1), 3*(4+1))
    INTEGER(i4) :: n_dof
    REAL(wp) :: err, f_n_expected

    WRITE(*,'(A)') ''
    WRITE(*,'(A)') '--- Case 1: Normal Contact (Two Flat Plates) ---'

    CALL init_error_status(status)

    ! Master face: unit square at z=0
    ! Node 1: (-1, -1, 0), Node 2: (1, -1, 0)
    ! Node 3: (1, 1, 0),   Node 4: (-1, 1, 0)
    master_coords(:,:) = 0.0_wp
    master_coords(:,1) = (/ -1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,2) = (/  1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,3) = (/  1.0_wp,  1.0_wp, 0.0_wp /)
    master_coords(:,4) = (/ -1.0_wp,  1.0_wp, 0.0_wp /)

    ! Slave node: directly above center, displaced down to z=-0.1 (penetration)
    x_slave = (/ 0.0_wp, 0.0_wp, -0.1_wp /)

    ! Properties
    props%eps_n = 1.0E6_wp
    props%eps_t = 1.0E5_wp
    props%mu    = 0.3_wp
    props%tol_proj = 1.0E-10_wp
    props%max_iter_proj = 20_i4

    ! Initialize pair
    pair%n_master_nodes = 4_i4
    pair%force_t_prev(:) = 0.0_wp

    ! Run full evaluation
    CALL PH_NTS_EvalPair(pair, props, master_coords, x_slave, &
                          f_nodal, K_contact, n_dof, status)

    ! Check 1a: gap_n should be -0.1
    err = ABS(pair%gap_n - (-0.1_wp))
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] gap_n = -0.1, error=', err
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5,A,ES12.5)') '  [FAIL] gap_n expected -0.1, got ', &
        pair%gap_n, ' error=', err
      n_fail = n_fail + 1
    END IF

    ! Check 1b: f_n = eps_n * |gap_n| = 1e6 * 0.1 = 1e5
    f_n_expected = props%eps_n * 0.1_wp
    err = ABS(pair%force_n - f_n_expected)
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] f_n = eps_n*0.1, error=', err
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5,A,ES12.5)') '  [FAIL] f_n expected ', f_n_expected, &
        ' got ', pair%force_n
      n_fail = n_fail + 1
    END IF

    ! Check 1c: f_t = 0 (no tangential motion from center projection)
    err = SQRT(pair%force_t(1)**2 + pair%force_t(2)**2)
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] f_t = 0 (no friction), |f_t|=', err
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] f_t should be 0, got |f_t|=', err
      n_fail = n_fail + 1
    END IF

    ! Check 1d: Normal direction should be (0,0,1)
    err = ABS(pair%normal(3) - 1.0_wp) + ABS(pair%normal(1)) + ABS(pair%normal(2))
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A)') '  [PASS] normal = (0,0,1)'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,3ES12.5)') '  [FAIL] normal expected (0,0,1), got ', pair%normal
      n_fail = n_fail + 1
    END IF

  END SUBROUTINE test_case1_normal_contact

  !===========================================================================
  ! Case 2: Sliding friction — Coulomb return mapping
  !===========================================================================
  ! Same flat plate geometry, slave displaced tangentially.
  ! gap_n = -0.1, delta_t applied → check stick vs slip transition.
  !===========================================================================
  SUBROUTINE test_case2_sliding_friction(n_pass, n_fail)
    INTEGER(i4), INTENT(INOUT) :: n_pass, n_fail

    TYPE(PH_NTS_Pair)  :: pair
    TYPE(PH_NTS_Props) :: props
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES)
    REAL(wp) :: x_slave(3)
    REAL(wp) :: delta_g_t(2)
    REAL(wp) :: f_trial_mag, f_limit, err
    REAL(wp) :: xi_out, eta_out, x_proj(3)
    LOGICAL  :: converged

    WRITE(*,'(A)') ''
    WRITE(*,'(A)') '--- Case 2: Sliding Friction (Coulomb Return Mapping) ---'

    CALL init_error_status(status)

    ! Master face: flat at z=0
    master_coords(:,:) = 0.0_wp
    master_coords(:,1) = (/ -1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,2) = (/  1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,3) = (/  1.0_wp,  1.0_wp, 0.0_wp /)
    master_coords(:,4) = (/ -1.0_wp,  1.0_wp, 0.0_wp /)

    ! Slave at center with penetration 0.1
    x_slave = (/ 0.0_wp, 0.0_wp, -0.1_wp /)

    props%eps_n = 1.0E6_wp
    props%eps_t = 1.0E5_wp
    props%mu    = 0.3_wp
    props%tol_proj = 1.0E-10_wp
    props%max_iter_proj = 20_i4

    ! --- Sub-case 2a: STICK (small tangential slip) ---
    pair%n_master_nodes = 4_i4
    pair%force_t_prev(:) = 0.0_wp
    pair%active = .FALSE.

    ! Project + gap manually
    CALL PH_NTS_ProjectNode(x_slave, master_coords, 4_i4, &
                            xi_out, eta_out, x_proj, converged, status)
    pair%xi(1) = xi_out
    pair%xi(2) = eta_out
    CALL PH_NTS_ComputeGap(x_slave, master_coords, 4_i4, xi_out, eta_out, &
                            pair%gap_n, pair%gap_t, pair%normal, status)

    ! Apply penalty force to activate
    pair%force_n = props%eps_n * (-pair%gap_n)  ! = 1e5
    pair%active = .TRUE.

    ! Small tangential slip → should STICK
    ! f_trial = eps_t * delta_t = 1e5 * 0.001 = 100
    ! f_limit = mu * f_n = 0.3 * 1e5 = 30000
    ! |f_trial| = 100 < 30000 → STICK
    delta_g_t = (/ 0.001_wp, 0.0_wp /)
    CALL PH_NTS_FrictionReturn(pair, props, delta_g_t, status)

    f_trial_mag = SQRT(pair%force_t(1)**2 + pair%force_t(2)**2)
    f_limit = props%mu * pair%force_n

    IF (.NOT. pair%sliding .AND. pair%status == NTS_STATUS_STICK) THEN
      WRITE(*,'(A)') '  [PASS] Sub-case 2a: STICK detected'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A)') '  [FAIL] Sub-case 2a: Expected STICK'
      n_fail = n_fail + 1
    END IF

    ! Verify stick force = eps_t * delta_t
    err = ABS(f_trial_mag - props%eps_t * 0.001_wp)
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] |f_t| = eps_t*delta_t, error=', err
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5,A,ES12.5)') '  [FAIL] |f_t| expected ', &
        props%eps_t * 0.001_wp, ' got ', f_trial_mag
      n_fail = n_fail + 1
    END IF

    ! --- Sub-case 2b: SLIP (large tangential slip) ---
    pair%force_t_prev(:) = 0.0_wp
    ! f_trial = eps_t * 0.5 = 50000
    ! f_limit = mu * f_n = 0.3 * 1e5 = 30000
    ! |f_trial| = 50000 > 30000 → SLIP
    delta_g_t = (/ 0.5_wp, 0.0_wp /)
    CALL PH_NTS_FrictionReturn(pair, props, delta_g_t, status)

    IF (pair%sliding .AND. pair%status == NTS_STATUS_SLIP) THEN
      WRITE(*,'(A)') '  [PASS] Sub-case 2b: SLIP detected'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A)') '  [FAIL] Sub-case 2b: Expected SLIP'
      n_fail = n_fail + 1
    END IF

    ! Verify slip force magnitude = mu * f_n
    f_trial_mag = SQRT(pair%force_t(1)**2 + pair%force_t(2)**2)
    err = ABS(f_trial_mag - f_limit)
    IF (err < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] |f_t| = mu*f_n (slip), error=', err
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5,A,ES12.5)') '  [FAIL] |f_t| expected ', f_limit, &
        ' got ', f_trial_mag
      n_fail = n_fail + 1
    END IF

    ! Verify slip direction (should be along +x in local tangent frame)
    IF (pair%force_t(1) > 0.0_wp .AND. ABS(pair%force_t(2)) < TOL_FORCE) THEN
      WRITE(*,'(A)') '  [PASS] Slip direction correct (+xi)'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,2ES12.5)') '  [FAIL] Slip direction wrong, f_t=', pair%force_t
      n_fail = n_fail + 1
    END IF

  END SUBROUTINE test_case2_sliding_friction

  !===========================================================================
  ! Case 3: NTS projection accuracy on curved master segment
  !===========================================================================
  ! Curved QUAD4: mid-side nodes lifted to form a dome shape.
  ! Slave node above known (xi,eta) → verify projection converges correctly.
  !===========================================================================
  SUBROUTINE test_case3_nts_projection_accuracy(n_pass, n_fail)
    INTEGER(i4), INTENT(INOUT) :: n_pass, n_fail

    TYPE(ErrorStatusType) :: status
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES)
    REAL(wp) :: x_slave(3), x_proj(3)
    REAL(wp) :: xi_out, eta_out
    LOGICAL  :: converged
    REAL(wp) :: err_xi, err_eta
    REAL(wp) :: gap_n, gap_t(2), normal(3)
    REAL(wp) :: analytic_normal(3), norm_val, err_n

    WRITE(*,'(A)') ''
    WRITE(*,'(A)') '--- Case 3: NTS Projection Accuracy (Curved Surface) ---'

    CALL init_error_status(status)

    ! Curved QUAD4: corners flat, but z-heights vary to create curvature
    ! z = 0.1 * (1 - xi^2) * (1 - eta^2) at each node position
    ! Node 1: (-1,-1), z=0;  Node 2: (1,-1), z=0
    ! Node 3: (1,1), z=0;    Node 4: (-1,1), z=0
    ! But we warp z to create curvature: shift node coords to create non-planar face
    master_coords(:,:) = 0.0_wp
    master_coords(:,1) = (/ -1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,2) = (/  1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,3) = (/  1.0_wp,  1.0_wp, 0.0_wp /)
    master_coords(:,4) = (/ -1.0_wp,  1.0_wp, 0.2_wp /)  ! Node 4 lifted → curved

    ! Slave node above a known analytical point
    ! At (xi,eta) = (0,0), x_m = average of 4 nodes = (0, 0, 0.05)
    ! Place slave above at z=0.5 → well above surface
    x_slave = (/ 0.0_wp, 0.0_wp, 0.5_wp /)

    CALL PH_NTS_ProjectNode(x_slave, master_coords, 4_i4, &
                            xi_out, eta_out, x_proj, converged, status)

    ! Check convergence
    IF (converged) THEN
      WRITE(*,'(A)') '  [PASS] NR projection converged'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A)') '  [FAIL] NR projection did NOT converge'
      n_fail = n_fail + 1
      RETURN
    END IF

    ! For this geometry, projection of (0,0,0.5) onto the surface
    ! should land near (xi,eta) = (0,0) because slave is directly above center
    ! The exact value depends on the surface shape but should be close to 0
    err_xi = ABS(xi_out)
    err_eta = ABS(eta_out)
    IF (err_xi < 0.1_wp .AND. err_eta < 0.1_wp) THEN
      WRITE(*,'(A,2ES14.7)') '  [PASS] Projection near center: xi,eta=', xi_out, eta_out
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,2ES14.7)') '  [FAIL] Projection far from center: xi,eta=', xi_out, eta_out
      n_fail = n_fail + 1
    END IF

    ! Verify normal direction via ComputeGap
    CALL PH_NTS_ComputeGap(x_slave, master_coords, 4_i4, xi_out, eta_out, &
                            gap_n, gap_t, normal, status)

    ! Normal should point generally upward (positive z component)
    IF (normal(3) > 0.9_wp) THEN
      WRITE(*,'(A,3ES12.5)') '  [PASS] Normal points up: n=', normal
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,3ES12.5)') '  [FAIL] Normal direction wrong: n=', normal
      n_fail = n_fail + 1
    END IF

    ! Verify unit normal
    norm_val = SQRT(normal(1)**2 + normal(2)**2 + normal(3)**2)
    err_n = ABS(norm_val - 1.0_wp)
    IF (err_n < TOL_PROJ) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] Normal is unit vector, |err|=', err_n
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] Normal not unit, |n|-1=', err_n
      n_fail = n_fail + 1
    END IF

    ! Verify gap is positive (slave above surface)
    IF (gap_n > 0.0_wp) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] gap_n > 0 (open), gap_n=', gap_n
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] gap_n should be >0, got ', gap_n
      n_fail = n_fail + 1
    END IF

  END SUBROUTINE test_case3_nts_projection_accuracy

  !===========================================================================
  ! Case 4: BVH search — verify correct contact pair detection
  !===========================================================================
  ! 10 master segments arranged in a 2x5 grid.
  ! Slave nodes placed to contact specific faces.
  ! Verify: no missed detections, no false positives.
  !===========================================================================
  SUBROUTINE test_case4_bvh_search(n_pass, n_fail)
    INTEGER(i4), INTENT(INOUT) :: n_pass, n_fail

    INTEGER(i4), PARAMETER :: N_FACES = 10
    INTEGER(i4), PARAMETER :: N_SLAVES = 3
    INTEGER(i4), PARAMETER :: MAX_CAND = 50

    TYPE(PH_NTS_Pair) :: candidates(MAX_CAND)
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: slave_nodes(3, N_SLAVES)
    REAL(wp) :: master_faces(3, NTS_MAX_FACE_NODES, N_FACES)
    INTEGER(i4) :: n_candidates
    INTEGER(i4) :: ix, iy, face_id, I
    REAL(wp) :: x0, y0

    WRITE(*,'(A)') ''
    WRITE(*,'(A)') '--- Case 4: BVH Search (Correct Pair Detection) ---'

    CALL init_error_status(status)

    ! Build 2x5 grid of master faces (each 1x1 square at z=0)
    master_faces(:,:,:) = 0.0_wp
    face_id = 0
    DO iy = 1, 5
      DO ix = 1, 2
        face_id = face_id + 1
        x0 = REAL(ix - 1, wp)
        y0 = REAL(iy - 1, wp)
        master_faces(:, 1, face_id) = (/ x0,        y0,        0.0_wp /)
        master_faces(:, 2, face_id) = (/ x0+1.0_wp, y0,        0.0_wp /)
        master_faces(:, 3, face_id) = (/ x0+1.0_wp, y0+1.0_wp, 0.0_wp /)
        master_faces(:, 4, face_id) = (/ x0,        y0+1.0_wp, 0.0_wp /)
      END DO
    END DO

    ! Slave nodes: above specific faces
    ! Slave 1: above face 1 center (0.5, 0.5, 0.1)
    slave_nodes(:, 1) = (/ 0.5_wp, 0.5_wp, 0.1_wp /)
    ! Slave 2: above face 5 center (0.5, 2.5, 0.1)
    slave_nodes(:, 2) = (/ 0.5_wp, 2.5_wp, 0.1_wp /)
    ! Slave 3: far away — should NOT match any face
    slave_nodes(:, 3) = (/ 50.0_wp, 50.0_wp, 10.0_wp /)

    CALL PH_NTS_SearchBVH(slave_nodes, N_SLAVES, master_faces, N_FACES, &
                            candidates, n_candidates, MAX_CAND, status)

    ! Check: at least 2 candidates found (slave 1 and 2 should match)
    IF (n_candidates >= 2) THEN
      WRITE(*,'(A,I3)') '  [PASS] Found candidates >= 2: ', n_candidates
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,I3)') '  [FAIL] Expected >= 2 candidates, got ', n_candidates
      n_fail = n_fail + 1
    END IF

    ! Check: slave 3 (far away) should not appear
    ! Search through candidates for slave_node == 3
    DO I = 1, n_candidates
      IF (candidates(I)%slave_node == 3) THEN
        WRITE(*,'(A)') '  [FAIL] Far-away slave 3 falsely detected'
        n_fail = n_fail + 1
        RETURN
      END IF
    END DO
    WRITE(*,'(A)') '  [PASS] No false positive for far-away slave 3'
    n_pass = n_pass + 1

    ! Check: slave 1 detected
    DO I = 1, n_candidates
      IF (candidates(I)%slave_node == 1) THEN
        WRITE(*,'(A)') '  [PASS] Slave 1 correctly detected'
        n_pass = n_pass + 1
        EXIT
      END IF
      IF (I == n_candidates) THEN
        WRITE(*,'(A)') '  [FAIL] Slave 1 missed'
        n_fail = n_fail + 1
      END IF
    END DO

    ! Check: slave 2 detected
    DO I = 1, n_candidates
      IF (candidates(I)%slave_node == 2) THEN
        WRITE(*,'(A)') '  [PASS] Slave 2 correctly detected'
        n_pass = n_pass + 1
        EXIT
      END IF
      IF (I == n_candidates) THEN
        WRITE(*,'(A)') '  [FAIL] Slave 2 missed'
        n_fail = n_fail + 1
      END IF
    END DO

  END SUBROUTINE test_case4_bvh_search

  !===========================================================================
  ! Case 5: Contact tangent stiffness — symmetry + finite difference check
  !===========================================================================
  ! Assemble K_contact for a stick-state pair.
  ! Verify:
  !   (a) K is symmetric: K(i,j) = K(j,i)
  !   (b) Finite difference consistency: K*du ≈ df (central difference)
  !===========================================================================
  SUBROUTINE test_case5_stiffness_symmetry(n_pass, n_fail)
    INTEGER(i4), INTENT(INOUT) :: n_pass, n_fail

    INTEGER(i4), PARAMETER :: MAX_DOF = 3*(4+1)  ! 15 DOFs for QUAD4 + slave
    TYPE(PH_NTS_Pair)  :: pair, pair_p, pair_m
    TYPE(PH_NTS_Props) :: props
    TYPE(ErrorStatusType) :: status
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES)
    REAL(wp) :: x_slave(3), x_slave_p(3), x_slave_m(3)
    REAL(wp) :: f_nodal(MAX_DOF), f_p(MAX_DOF), f_m(MAX_DOF)
    REAL(wp) :: K_contact(MAX_DOF, MAX_DOF)
    REAL(wp) :: K_fd(MAX_DOF, MAX_DOF)
    INTEGER(i4) :: n_dof, I, J, dof
    REAL(wp) :: asym_max, err_max, rel_err
    REAL(wp) :: eps_fd
    REAL(wp) :: K_p(MAX_DOF, MAX_DOF), K_m(MAX_DOF, MAX_DOF)
    INTEGER(i4) :: n_dof_tmp

    WRITE(*,'(A)') ''
    WRITE(*,'(A)') '--- Case 5: Stiffness Symmetry + Finite Difference ---'

    CALL init_error_status(status)
    eps_fd = 1.0E-7_wp

    ! Setup: flat master, penetrating slave (stick state)
    master_coords(:,:) = 0.0_wp
    master_coords(:,1) = (/ -1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,2) = (/  1.0_wp, -1.0_wp, 0.0_wp /)
    master_coords(:,3) = (/  1.0_wp,  1.0_wp, 0.0_wp /)
    master_coords(:,4) = (/ -1.0_wp,  1.0_wp, 0.0_wp /)

    x_slave = (/ 0.0_wp, 0.0_wp, -0.1_wp /)

    props%eps_n = 1.0E6_wp
    props%eps_t = 1.0E5_wp
    props%mu    = 0.3_wp
    props%tol_proj = 1.0E-10_wp
    props%max_iter_proj = 20_i4

    ! Evaluate pair to get K_contact
    pair%n_master_nodes = 4_i4
    pair%force_t_prev(:) = 0.0_wp

    CALL PH_NTS_EvalPair(pair, props, master_coords, x_slave, &
                          f_nodal, K_contact, n_dof, status)

    ! --- Check 5a: Symmetry ---
    asym_max = 0.0_wp
    DO I = 1, n_dof
      DO J = I+1, n_dof
        asym_max = MAX(asym_max, ABS(K_contact(I,J) - K_contact(J,I)))
      END DO
    END DO

    IF (asym_max < TOL_FORCE) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] K_contact symmetric, max_asym=', asym_max
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] K_contact NOT symmetric, max_asym=', asym_max
      n_fail = n_fail + 1
    END IF

    ! --- Check 5b: Finite difference consistency on slave DOFs ---
    ! Perturb slave node in z-direction (DOF index = 3*n_master + 3 = 15)
    ! K * du ≈ f(u+du) - f(u-du) / (2*du)
    K_fd(:,:) = 0.0_wp
    dof = 3 * 4 + 3  ! slave z-DOF (15th)

    ! Perturb slave z+
    x_slave_p = x_slave
    x_slave_p(3) = x_slave(3) + eps_fd
    pair_p = pair
    pair_p%force_t_prev(:) = 0.0_wp
    pair_p%n_master_nodes = 4_i4
    CALL PH_NTS_EvalPair(pair_p, props, master_coords, x_slave_p, &
                          f_p, K_p, n_dof_tmp, status)

    ! Perturb slave z-
    x_slave_m = x_slave
    x_slave_m(3) = x_slave(3) - eps_fd
    pair_m = pair
    pair_m%force_t_prev(:) = 0.0_wp
    pair_m%n_master_nodes = 4_i4
    CALL PH_NTS_EvalPair(pair_m, props, master_coords, x_slave_m, &
                          f_m, K_m, n_dof_tmp, status)

    ! FD column for slave z-DOF
    DO I = 1, n_dof
      K_fd(I, dof) = (f_p(I) - f_m(I)) / (2.0_wp * eps_fd)
    END DO

    ! Compare K_contact(:, dof) with K_fd(:, dof)
    err_max = 0.0_wp
    DO I = 1, n_dof
      IF (ABS(K_contact(I, dof)) > 1.0E-10_wp) THEN
        rel_err = ABS(K_fd(I, dof) - K_contact(I, dof)) / ABS(K_contact(I, dof))
        err_max = MAX(err_max, rel_err)
      END IF
    END DO

    IF (err_max < TOL_FD) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] FD consistency (slave z), max_rel_err=', err_max
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] FD inconsistency (slave z), max_rel_err=', err_max
      n_fail = n_fail + 1
    END IF

    ! FD check on slave x-DOF (DOF = 3*4+1 = 13)
    dof = 3 * 4 + 1  ! slave x-DOF

    x_slave_p = x_slave
    x_slave_p(1) = x_slave(1) + eps_fd
    pair_p%force_t_prev(:) = 0.0_wp
    pair_p%n_master_nodes = 4_i4
    CALL PH_NTS_EvalPair(pair_p, props, master_coords, x_slave_p, &
                          f_p, K_p, n_dof_tmp, status)

    x_slave_m = x_slave
    x_slave_m(1) = x_slave(1) - eps_fd
    pair_m%force_t_prev(:) = 0.0_wp
    pair_m%n_master_nodes = 4_i4
    CALL PH_NTS_EvalPair(pair_m, props, master_coords, x_slave_m, &
                          f_m, K_m, n_dof_tmp, status)

    DO I = 1, n_dof
      K_fd(I, dof) = (f_p(I) - f_m(I)) / (2.0_wp * eps_fd)
    END DO

    err_max = 0.0_wp
    DO I = 1, n_dof
      IF (ABS(K_contact(I, dof)) > 1.0E-10_wp) THEN
        rel_err = ABS(K_fd(I, dof) - K_contact(I, dof)) / ABS(K_contact(I, dof))
        err_max = MAX(err_max, rel_err)
      END IF
    END DO

    IF (err_max < TOL_FD) THEN
      WRITE(*,'(A,ES12.5)') '  [PASS] FD consistency (slave x), max_rel_err=', err_max
      n_pass = n_pass + 1
    ELSE
      WRITE(*,'(A,ES12.5)') '  [FAIL] FD inconsistency (slave x), max_rel_err=', err_max
      n_fail = n_fail + 1
    END IF

  END SUBROUTINE test_case5_stiffness_symmetry

END MODULE test_contact_nts_e2e

!===============================================================================
! Program: Main driver
!===============================================================================
PROGRAM test_contact_nts_e2e_driver
  USE test_contact_nts_e2e, ONLY: run_all_nts_e2e_tests
  IMPLICIT NONE
  CALL run_all_nts_e2e_tests()
END PROGRAM test_contact_nts_e2e_driver
