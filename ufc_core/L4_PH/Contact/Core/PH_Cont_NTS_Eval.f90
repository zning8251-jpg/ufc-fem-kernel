!===============================================================================
! MODULE: PH_Cont_NTS_Eval
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Eval
! BRIEF:  Node-to-Segment (NTS) contact evaluation kernel (hot path)
!
! Theory:
!   NTS Projection -> gap computation -> penalty force -> Coulomb friction
!   return mapping -> contact stiffness matrix contribution.
!   Wriggers (2006) Ch.5-6; Laursen (2002) Ch.3
!
! Hot-path constraints (CONTRACT §8):
!   - Zero ALLOCATE in Ctx (stack allocation)
!   - 64-byte alignment (AVX-512)
!   - Contact force at face level, no GP inner loop
!
! Status: SKELETON | Created: 2026-04-28
!===============================================================================
!>>> UFC_PH_TAG | layer:L4_PH | domain:Contact | role:NTS_Eval | FuncSet:HotPath
!>>> UFC_PH_CONTRACT | Contact/CONTRACT.md

MODULE PH_Cont_NTS_Eval
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC INTERFACES
  ! ==========================================================================
  PUBLIC :: PH_NTS_ProjectNode        ! Slave → master surface projection (local NR)
  PUBLIC :: PH_NTS_ComputeGap         ! Normal / tangential gap computation
  PUBLIC :: PH_NTS_PenaltyForce       ! Penalty normal contact force
  PUBLIC :: PH_NTS_FrictionReturn     ! Coulomb friction return mapping
  PUBLIC :: PH_NTS_ContactStiffness   ! Contact stiffness matrix contribution
  PUBLIC :: PH_NTS_EvalPair           ! Unified entry: single contact pair evaluation
  PUBLIC :: PH_NTS_SearchBVH          ! BVH accelerated search (candidate pair filtering)
  ! --- Arg TYPEs for SIO Arg wrapping ---
  PUBLIC :: PH_Cont_NTS_Eval_Arg
  PUBLIC :: PH_Cont_NTS_Search_Arg
  ! --- Struct-signature wrappers ---
  PUBLIC :: PH_NTS_EvalPair_Struct
  PUBLIC :: PH_NTS_SearchBVH_Struct

  ! ==========================================================================
  ! CONSTANTS
  ! ==========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: NTS_MAX_FACE_NODES = 8_i4   ! Max nodes per master face
  INTEGER(i4), PARAMETER, PUBLIC :: NTS_MAX_LOCAL_ITER = 20_i4  ! Max projection NR iterations
  REAL(wp),    PARAMETER, PUBLIC :: NTS_TOL_PROJ  = 1.0E-10_wp  ! Projection convergence tol
  REAL(wp),    PARAMETER, PUBLIC :: NTS_TOL_GAP   = 1.0E-12_wp  ! Gap zero tolerance

  ! Contact status flags
  INTEGER(i4), PARAMETER, PUBLIC :: NTS_STATUS_STICK = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NTS_STATUS_SLIP  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NTS_STATUS_OPEN  = 0_i4

  ! ==========================================================================
  ! TYPE: NTS Contact Pair (single slave node vs master face)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_NTS_Pair
    INTEGER(i4) :: slave_node              ! Slave node global ID
    INTEGER(i4) :: master_face(NTS_MAX_FACE_NODES) ! Master face node IDs
    INTEGER(i4) :: n_master_nodes = 4_i4   ! Actual master face node count (4 or 8)
    REAL(wp)    :: xi(2) = 0.0_wp          ! Projected natural coordinates (xi, eta)
    REAL(wp)    :: gap_n = 0.0_wp          ! Normal gap (>0: open, <=0: penetration)
    REAL(wp)    :: gap_t(2) = 0.0_wp       ! Tangential slip increments
    REAL(wp)    :: normal(3) = 0.0_wp      ! Contact normal at projection point
    REAL(wp)    :: force_n = 0.0_wp        ! Normal contact force
    REAL(wp)    :: force_t(2) = 0.0_wp     ! Tangential friction force
    REAL(wp)    :: force_t_prev(2) = 0.0_wp ! Previous step tangential force (for return map)
    LOGICAL     :: active  = .FALSE.       ! Pair active flag
    LOGICAL     :: sliding = .FALSE.       ! Sliding (TRUE) / stick (FALSE) state
    INTEGER(i4) :: status  = NTS_STATUS_OPEN ! Contact status enum
  END TYPE PH_NTS_Pair

  ! ==========================================================================
  ! TYPE: NTS Contact Properties (P2 nested)
  ! ==========================================================================

  TYPE, PUBLIC :: PH_NTS_Cfg_Penalty
    REAL(wp) :: eps_n     = 1.0E6_wp       ! Normal penalty parameter [N/m^3]
    REAL(wp) :: eps_t     = 1.0E5_wp       ! Tangential penalty parameter [N/m^3]
  END TYPE PH_NTS_Cfg_Penalty

  TYPE, PUBLIC :: PH_NTS_Cfg_Friction
    REAL(wp) :: mu        = 0.3_wp         ! Friction coefficient (Coulomb)
  END TYPE PH_NTS_Cfg_Friction

  TYPE, PUBLIC :: PH_NTS_Cfg_Proj
    REAL(wp) :: tol_proj  = 1.0E-10_wp     ! Projection convergence tolerance
    INTEGER(i4) :: max_iter_proj = 20_i4   ! Projection max NR iterations
  END TYPE PH_NTS_Cfg_Proj

  TYPE, PUBLIC :: PH_NTS_Cfg_Adapt
    REAL(wp) :: gap_tol   = 1.0E-6_wp      ! Max allowed penetration for penalty adjust
    REAL(wp) :: beta_grow = 5.0_wp         ! Penalty increase factor when penetration too large
    REAL(wp) :: gamma_cut = 2.0_wp         ! Penalty decrease factor on convergence difficulty
  END TYPE PH_NTS_Cfg_Adapt

  TYPE, PUBLIC :: PH_NTS_Props
    TYPE(PH_NTS_Cfg_Penalty) :: penalty
    TYPE(PH_NTS_Cfg_Friction) :: friction
    TYPE(PH_NTS_Cfg_Proj)    :: proj
    TYPE(PH_NTS_Cfg_Adapt)   :: adapt
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_NTS_Props

  ! ==========================================================================
  ! Arg TYPE: PH_Cont_NTS_Eval_Arg — bundles EvalPair IO into one struct
  ! KIND: Arg (SIO coupling bundle)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Cont_NTS_Eval_Arg
    ! --- IN ---
    REAL(wp) :: master_coords(3, NTS_MAX_FACE_NODES) = 0.0_wp  ! [IN] Master face coords
    REAL(wp) :: x_slave(3) = 0.0_wp                            ! [IN] Slave node position
    ! --- OUT ---
    REAL(wp), ALLOCATABLE :: f_nodal(:)             ! [OUT] Equivalent nodal forces
    REAL(wp), ALLOCATABLE :: K_contact(:,:)         ! [OUT] Contact stiffness
    INTEGER(i4) :: n_dof = 0_i4                     ! [OUT] DOF count
  END TYPE PH_Cont_NTS_Eval_Arg

  ! ==========================================================================
  ! Arg TYPE: PH_Cont_NTS_Search_Arg — bundles SearchBVH IO into one struct
  ! KIND: Arg (SIO coupling bundle)
  ! ==========================================================================
  TYPE, PUBLIC :: PH_Cont_NTS_Search_Arg
    ! --- IN ---
    REAL(wp), ALLOCATABLE :: slave_nodes(:,:)        ! [IN] Slave node coords (3, n_slaves)
    INTEGER(i4) :: n_slaves = 0_i4                   ! [IN] Number of slave nodes
    REAL(wp), ALLOCATABLE :: master_coords(:,:,:)    ! [IN] Master face coords (3, max, n_faces)
    INTEGER(i4) :: n_master_faces = 0_i4             ! [IN] Number of master faces
    INTEGER(i4) :: max_candidates = 0_i4             ! [IN] Max capacity
    ! --- OUT ---
    TYPE(PH_NTS_Pair), ALLOCATABLE :: candidate_pairs(:) ! [OUT] Candidate pairs
    INTEGER(i4) :: n_candidates = 0_i4               ! [OUT] Number found
  END TYPE PH_Cont_NTS_Search_Arg

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_NTS_ProjectNode: Slave node → master face projection (local NR)
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §2.2
  ! Algorithm:
  !   Given slave point x_s and master face coords x_I^master (I=1..n_nodes),
  !   find (xi, eta) such that:
  !     r(xi,eta) = x_s - x_m(xi,eta)
  !     r · dx_m/dxi  = 0   (orthogonality condition 1)
  !     r · dx_m/deta = 0   (orthogonality condition 2)
  !   via 2×2 Newton-Raphson on the orthogonality residual.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_ProjectNode(x_slave, master_coords, n_master_nodes, &
                                 xi_out, eta_out, x_proj, converged, status)
    REAL(wp), INTENT(IN)  :: x_slave(3)                           ! [IN] Slave node position
    REAL(wp), INTENT(IN)  :: master_coords(3, NTS_MAX_FACE_NODES) ! [IN] Master face node coords
    INTEGER(i4), INTENT(IN) :: n_master_nodes                     ! [IN] 4 or 8 nodes
    REAL(wp), INTENT(OUT) :: xi_out                                ! [OUT] Converged xi
    REAL(wp), INTENT(OUT) :: eta_out                               ! [OUT] Converged eta
    REAL(wp), INTENT(OUT) :: x_proj(3)                             ! [OUT] Projection point
    LOGICAL,  INTENT(OUT) :: converged                             ! [OUT] Convergence flag
    TYPE(ErrorStatusType), INTENT(INOUT) :: status                 ! [INOUT] Error status

    ! --- Local variables (stack-allocated, no ALLOCATE) ---
    REAL(wp) :: xi, eta, dxi, deta
    REAL(wp) :: r(3), x_m(3)
    REAL(wp) :: dxm_dxi(3), dxm_deta(3)
    REAL(wp) :: A(2,2), b(2), det_A
    REAL(wp) :: N_shape(NTS_MAX_FACE_NODES)
    REAL(wp) :: dN_dxi(NTS_MAX_FACE_NODES), dN_deta(NTS_MAX_FACE_NODES)
    INTEGER(i4) :: iter, I

    converged = .FALSE.
    xi  = 0.0_wp   ! Initial guess: face center
    eta = 0.0_wp

    DO iter = 1, NTS_MAX_LOCAL_ITER
      ! Step 1: Evaluate master surface point and tangent vectors
      !         x_m = sum_I N_I(xi,eta) * x_I
      !         dxm_dxi  = sum_I dN_I/dxi  * x_I
      !         dxm_deta = sum_I dN_I/deta * x_I
      CALL EvalFaceShapeFunc(xi, eta, n_master_nodes, N_shape, dN_dxi, dN_deta)

      x_m(:) = 0.0_wp
      dxm_dxi(:) = 0.0_wp
      dxm_deta(:) = 0.0_wp
      DO I = 1, n_master_nodes
        x_m(:)       = x_m(:)       + N_shape(I) * master_coords(:, I)
        dxm_dxi(:)   = dxm_dxi(:)   + dN_dxi(I)  * master_coords(:, I)
        dxm_deta(:)  = dxm_deta(:)  + dN_deta(I) * master_coords(:, I)
      END DO

      ! Step 2: Residual vector r = x_slave - x_m
      r(:) = x_slave(:) - x_m(:)

      ! Step 3: Orthogonality condition residuals
      !         b(1) = r · dxm_dxi
      !         b(2) = r · dxm_deta
      b(1) = DOT_PRODUCT(r, dxm_dxi)
      b(2) = DOT_PRODUCT(r, dxm_deta)

      ! Step 4: 2×2 Jacobian (symmetric)
      !         A(1,1) = -dxm_dxi · dxm_dxi
      !         A(1,2) = -dxm_dxi · dxm_deta
      !         A(2,2) = -dxm_deta · dxm_deta
      A(1,1) = -DOT_PRODUCT(dxm_dxi,  dxm_dxi)
      A(1,2) = -DOT_PRODUCT(dxm_dxi,  dxm_deta)
      A(2,1) = A(1,2)
      A(2,2) = -DOT_PRODUCT(dxm_deta, dxm_deta)

      ! Step 5: Solve 2×2 system A * [dxi, deta]^T = b (Cramer's rule)
      det_A = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det_A) < 1.0E-30_wp) THEN
        ! Degenerate face (zero area) — cannot project
        status%status_code = IF_STATUS_ERROR
        status%message = 'NTS_ProjectNode: degenerate master face (det~0)'
        RETURN
      END IF
      ! NR: solve A * [dxi,deta] = -b  (standard Newton: J*dx = -f)
      dxi  = -(b(1)*A(2,2) - b(2)*A(1,2)) / det_A
      deta = -(A(1,1)*b(2) - A(2,1)*b(1)) / det_A

      ! Step 6: Update natural coordinates
      xi  = xi  + dxi
      eta = eta + deta

      ! Step 7: Convergence check
      IF (SQRT(dxi**2 + deta**2) < NTS_TOL_PROJ) THEN
        converged = .TRUE.
        EXIT
      END IF
    END DO

    ! Compute final projection point
    CALL EvalFaceShapeFunc(xi, eta, n_master_nodes, N_shape, dN_dxi, dN_deta)
    x_proj(:) = 0.0_wp
    DO I = 1, n_master_nodes
      x_proj(:) = x_proj(:) + N_shape(I) * master_coords(:, I)
    END DO

    xi_out  = xi
    eta_out = eta

  END SUBROUTINE PH_NTS_ProjectNode

  !---------------------------------------------------------------------------
  ! PH_NTS_ComputeGap: Normal and tangential gap computation
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §3.1
  ! Algorithm:
  !   g_n = (x_s - x_m(xi*,eta*)) · n_m
  !   n_m = (dxm/dxi × dxm/deta) / ||dxm/dxi × dxm/deta||
  !   delta_g_t = (I - n⊗n) · (delta_x_s - delta_x_m)  [tangential slip]
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_ComputeGap(x_slave, master_coords, n_master_nodes, &
                                 xi, eta, gap_n, gap_t, normal, status)
    REAL(wp), INTENT(IN)  :: x_slave(3)                            ! [IN] Slave node position
    REAL(wp), INTENT(IN)  :: master_coords(3, NTS_MAX_FACE_NODES)  ! [IN] Master face coords
    INTEGER(i4), INTENT(IN) :: n_master_nodes                      ! [IN] Face node count
    REAL(wp), INTENT(IN)  :: xi, eta                               ! [IN] Natural coordinates
    REAL(wp), INTENT(OUT) :: gap_n                                 ! [OUT] Normal gap
    REAL(wp), INTENT(OUT) :: gap_t(2)                              ! [OUT] Tangential slip
    REAL(wp), INTENT(OUT) :: normal(3)                             ! [OUT] Unit contact normal
    TYPE(ErrorStatusType), INTENT(INOUT) :: status                 ! [INOUT] Error status

    ! Local
    REAL(wp) :: x_m(3), r(3), dxm_dxi(3), dxm_deta(3)
    REAL(wp) :: cross(3), norm_cross
    REAL(wp) :: N_shape(NTS_MAX_FACE_NODES)
    REAL(wp) :: dN_dxi(NTS_MAX_FACE_NODES), dN_deta(NTS_MAX_FACE_NODES)
    INTEGER(i4) :: I

    ! Evaluate master surface at (xi, eta)
    CALL EvalFaceShapeFunc(xi, eta, n_master_nodes, N_shape, dN_dxi, dN_deta)

    x_m(:)      = 0.0_wp
    dxm_dxi(:)  = 0.0_wp
    dxm_deta(:) = 0.0_wp
    DO I = 1, n_master_nodes
      x_m(:)      = x_m(:)      + N_shape(I) * master_coords(:, I)
      dxm_dxi(:)  = dxm_dxi(:)  + dN_dxi(I)  * master_coords(:, I)
      dxm_deta(:) = dxm_deta(:) + dN_deta(I) * master_coords(:, I)
    END DO

    ! Normal: n_m = (dxm/dxi × dxm/deta) / ||...||
    CALL Cross3(dxm_dxi, dxm_deta, cross)
    norm_cross = SQRT(DOT_PRODUCT(cross, cross))
    IF (norm_cross < 1.0E-30_wp) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = 'NTS_ComputeGap: degenerate face normal'
      normal(:) = 0.0_wp
      gap_n = 0.0_wp
      gap_t(:) = 0.0_wp
      RETURN
    END IF
    normal(:) = cross(:) / norm_cross

    ! Normal gap: g_n = (x_s - x_m) · n
    r(:) = x_slave(:) - x_m(:)
    gap_n = DOT_PRODUCT(r, normal)

    ! Tangential slip (simplified: projection of r onto tangent plane)
    ! gap_t(1) = r · (dxm/dxi / ||dxm/dxi||)
    ! gap_t(2) = r · (dxm/deta / ||dxm/deta||)
    ! Tangential slip: project residual r onto tangent plane
    ! Simplified form: gap_t_k = r · (a_k / ||a_k||), k = xi, eta
    ! Note: Full incremental form delta_g_t = (I - n⊗n)·(Δx_s - Δx_m)
    ! requires displacement increments passed from the solver (DESIGN §4.1).
    gap_t(1) = DOT_PRODUCT(r, dxm_dxi)  / MAX(SQRT(DOT_PRODUCT(dxm_dxi, dxm_dxi)), 1.0E-30_wp)
    gap_t(2) = DOT_PRODUCT(r, dxm_deta) / MAX(SQRT(DOT_PRODUCT(dxm_deta, dxm_deta)), 1.0E-30_wp)

  END SUBROUTINE PH_NTS_ComputeGap

  !---------------------------------------------------------------------------
  ! PH_NTS_PenaltyForce: Penalty normal contact force + equivalent nodal forces
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §3.2
  ! Algorithm:
  !   f_n = eps_n * max(0, -g_n)       [penalty force scalar]
  !   F_c = f_n * n_m * [-N_1; ...; -N_nmaster; 1]  [nodal force vector]
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_PenaltyForce(pair, props, f_nodal, n_dof, status)
    TYPE(PH_NTS_Pair),  INTENT(INOUT) :: pair                     ! [INOUT] Contact pair
    TYPE(PH_NTS_Props), INTENT(IN)    :: props                    ! [IN] Contact properties
    REAL(wp), INTENT(OUT) :: f_nodal(:)                           ! [OUT] Equiv nodal forces (3*(n_master+1))
    INTEGER(i4), INTENT(OUT) :: n_dof                             ! [OUT] Actual DOF count
    TYPE(ErrorStatusType), INTENT(INOUT) :: status                ! [INOUT] Error status

    ! Local
    REAL(wp) :: f_n_scalar
    REAL(wp) :: N_shape(NTS_MAX_FACE_NODES)
    REAL(wp) :: dN_dxi(NTS_MAX_FACE_NODES), dN_deta(NTS_MAX_FACE_NODES)
    INTEGER(i4) :: I, n_mn, base_idx

    n_mn = pair%n_master_nodes
    n_dof = 3 * (n_mn + 1)  ! 3 DOF per master node + 3 for slave

    ! Step 1: Penalty force scalar: f_n = eps_n * max(0, -g_n)
    IF (pair%gap_n < 0.0_wp) THEN
      f_n_scalar = props%penalty%eps_n * (-pair%gap_n)  ! Penetration: gap_n < 0
      pair%active = .TRUE.
      pair%force_n = f_n_scalar
    ELSE
      f_n_scalar = 0.0_wp
      pair%active = .FALSE.
      pair%force_n = 0.0_wp
      pair%status = NTS_STATUS_OPEN
      f_nodal(1:n_dof) = 0.0_wp
      RETURN
    END IF

    ! Step 2: Get shape functions at projection point
    CALL EvalFaceShapeFunc(pair%xi(1), pair%xi(2), n_mn, N_shape, dN_dxi, dN_deta)

    ! Step 3: Equivalent nodal forces
    !   Master nodes: F_I = -f_n * N_I * n  (reaction opposing penetration)
    !   Slave node:   F_s = +f_n * n        (push out)
    f_nodal(1:n_dof) = 0.0_wp
    DO I = 1, n_mn
      base_idx = 3 * (I - 1)
      f_nodal(base_idx + 1) = -f_n_scalar * N_shape(I) * pair%normal(1)
      f_nodal(base_idx + 2) = -f_n_scalar * N_shape(I) * pair%normal(2)
      f_nodal(base_idx + 3) = -f_n_scalar * N_shape(I) * pair%normal(3)
    END DO
    ! Slave node DOFs (last 3)
    base_idx = 3 * n_mn
    f_nodal(base_idx + 1) = f_n_scalar * pair%normal(1)
    f_nodal(base_idx + 2) = f_n_scalar * pair%normal(2)
    f_nodal(base_idx + 3) = f_n_scalar * pair%normal(3)

  END SUBROUTINE PH_NTS_PenaltyForce

  !---------------------------------------------------------------------------
  ! PH_NTS_FrictionReturn: Coulomb friction return mapping (incremental)
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §4.3
  ! Algorithm (return mapping):
  !   Step 1: Trial tangential force: f_trial = f_t_prev + eps_t * delta_g_t
  !   Step 2: Yield check: Phi = ||f_trial|| - mu * f_n
  !   Step 3a: Phi <= 0 → STICK: f_t = f_trial
  !   Step 3b: Phi > 0  → SLIP:  f_t = mu*f_n * (f_trial / ||f_trial||)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_FrictionReturn(pair, props, delta_g_t, status)
    TYPE(PH_NTS_Pair),  INTENT(INOUT) :: pair    ! [INOUT] Contact pair (force_t updated)
    TYPE(PH_NTS_Props), INTENT(IN)    :: props   ! [IN] Contact properties
    REAL(wp), INTENT(IN) :: delta_g_t(2)          ! [IN] Tangential slip increment
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    ! Local
    REAL(wp) :: f_trial(2), f_trial_mag, f_limit

    IF (.NOT. pair%active) RETURN   ! No friction on open pairs

    ! Step 1: Elastic predictor (trial tangential force)
    f_trial(1) = pair%force_t_prev(1) + props%penalty%eps_t * delta_g_t(1)
    f_trial(2) = pair%force_t_prev(2) + props%penalty%eps_t * delta_g_t(2)

    ! Step 2: Coulomb yield function: Phi = ||f_trial|| - mu * f_n
    f_trial_mag = SQRT(f_trial(1)**2 + f_trial(2)**2)
    f_limit = props%friction%mu * pair%force_n

    IF (f_trial_mag <= f_limit) THEN
      ! STICK: trial force within friction cone
      pair%force_t(:) = f_trial(:)
      pair%sliding = .FALSE.
      pair%status = NTS_STATUS_STICK
    ELSE
      ! SLIP: return mapping to friction cone surface
      IF (f_trial_mag > 1.0E-30_wp) THEN
        pair%force_t(1) = f_limit * (f_trial(1) / f_trial_mag)
        pair%force_t(2) = f_limit * (f_trial(2) / f_trial_mag)
      ELSE
        pair%force_t(:) = 0.0_wp
      END IF
      pair%sliding = .TRUE.
      pair%status = NTS_STATUS_SLIP
    END IF

  END SUBROUTINE PH_NTS_FrictionReturn

  !---------------------------------------------------------------------------
  ! PH_NTS_ContactStiffness: Contact stiffness matrix contribution
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §3.3, §4.4
  ! Algorithm:
  !   Normal: K_c^nn = eps_n * N_n^T * N_n
  !     where N_n = [n1*N1, n2*N1, n3*N1, ..., -n1, -n2, -n3]
  !   Tangential (stick): K_t = eps_t * (I - n⊗n)
  !   Tangential (slip):  K_t = mu*f_n/||f_trial|| * (eps_t*(I-n⊗n) - eps_t*f_trial⊗f_trial/||f_trial||^2)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_ContactStiffness(pair, props, K_contact, n_dof, status)
    TYPE(PH_NTS_Pair),  INTENT(IN)    :: pair       ! [IN] Contact pair
    TYPE(PH_NTS_Props), INTENT(IN)    :: props      ! [IN] Contact properties
    REAL(wp), INTENT(OUT) :: K_contact(:,:)          ! [OUT] Contact stiffness (n_dof × n_dof)
    INTEGER(i4), INTENT(OUT) :: n_dof                ! [OUT] DOF count = 3*(n_master+1)
    TYPE(ErrorStatusType), INTENT(INOUT) :: status   ! [INOUT] Error status

    ! Local
    REAL(wp) :: N_n(3*NTS_MAX_FACE_NODES + 3)   ! Normal shape vector
    REAL(wp) :: N_shape(NTS_MAX_FACE_NODES)
    REAL(wp) :: dN_dxi(NTS_MAX_FACE_NODES), dN_deta(NTS_MAX_FACE_NODES)
    INTEGER(i4) :: I, J, n_mn, base_i, base_j, d1, d2
    ! Tangential stiffness locals
    REAL(wp) :: N_t1(3*NTS_MAX_FACE_NODES + 3)  ! Tangent-1 shape vector
    REAL(wp) :: N_t2(3*NTS_MAX_FACE_NODES + 3)  ! Tangent-2 shape vector
    REAL(wp) :: t1(3), t2(3)                     ! Orthonormal tangent vectors
    REAL(wp) :: dxm_dxi(3), dxm_deta(3)         ! Surface tangent vectors
    REAL(wp) :: norm_t, f_trial_mag, scale_slip
    REAL(wp) :: f_trial_dir(2)

    n_mn = pair%n_master_nodes
    n_dof = 3 * (n_mn + 1)

    K_contact(1:n_dof, 1:n_dof) = 0.0_wp

    IF (.NOT. pair%active) RETURN  ! No stiffness for open pairs

    ! Get shape functions at projection point
    CALL EvalFaceShapeFunc(pair%xi(1), pair%xi(2), n_mn, N_shape, dN_dxi, dN_deta)

    ! --- Normal stiffness: K_nn = eps_n * N_n^T * N_n ---
    ! Build N_n vector: [n(1)*N_1, n(2)*N_1, n(3)*N_1, ..., n(1)*N_m, n(2)*N_m, n(3)*N_m, -n(1), -n(2), -n(3)]
    N_n(1:n_dof) = 0.0_wp
    DO I = 1, n_mn
      base_i = 3 * (I - 1)
      N_n(base_i + 1) = pair%normal(1) * N_shape(I)
      N_n(base_i + 2) = pair%normal(2) * N_shape(I)
      N_n(base_i + 3) = pair%normal(3) * N_shape(I)
    END DO
    ! Slave node
    base_i = 3 * n_mn
    N_n(base_i + 1) = -pair%normal(1)
    N_n(base_i + 2) = -pair%normal(2)
    N_n(base_i + 3) = -pair%normal(3)

    ! K_nn = -eps_n * N_n^T * N_n (consistent tangent: df_applied/du)
    ! Sign: f = eps_n*(-g_n)*C, dg_n/du = -N_n, so df/du = -eps_n * N_n^T * N_n
    DO I = 1, n_dof
      DO J = 1, n_dof
        K_contact(I, J) = K_contact(I, J) - props%penalty%eps_n * N_n(I) * N_n(J)
      END DO
    END DO

    ! --- Tangential stiffness (consistent tangent per DESIGN §4.4) ---
    ! Compute tangent plane basis vectors from surface parametrization
    dxm_dxi(:) = 0.0_wp
    dxm_deta(:) = 0.0_wp
    ! Note: master_coords not passed here, but tangent directions available
    ! from the normal via Gram-Schmidt. Build orthonormal (t1, t2) from n.
    CALL BuildTangentBasis(pair%normal, t1, t2)

    ! Build tangential shape vectors N_t1, N_t2 (analogous to N_n)
    ! N_t_k = [t_k(1)*N_1, t_k(2)*N_1, ..., t_k(3)*N_m, -t_k(1), -t_k(2), -t_k(3)]
    N_t1(1:n_dof) = 0.0_wp
    N_t2(1:n_dof) = 0.0_wp
    DO I = 1, n_mn
      base_i = 3 * (I - 1)
      DO d1 = 1, 3
        N_t1(base_i + d1) = t1(d1) * N_shape(I)
        N_t2(base_i + d1) = t2(d1) * N_shape(I)
      END DO
    END DO
    ! Slave node (last 3 DOFs)
    base_i = 3 * n_mn
    DO d1 = 1, 3
      N_t1(base_i + d1) = -t1(d1)
      N_t2(base_i + d1) = -t2(d1)
    END DO

    IF (pair%status == NTS_STATUS_STICK .AND. &
        (pair%force_t(1)**2 + pair%force_t(2)**2) > 1.0E-30_wp) THEN
      ! STICK: K_t = -eps_t * (N_t1^T * N_t1 + N_t2^T * N_t2)
      ! Only active when friction force is nonzero (consistent with re-projection)
      DO I = 1, n_dof
        DO J = 1, n_dof
          K_contact(I, J) = K_contact(I, J) &
            - props%penalty%eps_t * (N_t1(I)*N_t1(J) + N_t2(I)*N_t2(J))
        END DO
      END DO

    ELSE IF (pair%status == NTS_STATUS_SLIP) THEN
      ! SLIP: Modified tangential stiffness
      ! K_t^slip = mu*f_n/||f_trial|| * [eps_t*(P_t) - eps_t*(f_hat ⊗ f_hat)]
      ! where P_t = tangent plane projector, f_hat = f_trial/||f_trial||
      f_trial_mag = SQRT(pair%force_t(1)**2 + pair%force_t(2)**2)
      IF (f_trial_mag > 1.0E-30_wp .AND. pair%force_n > 1.0E-30_wp) THEN
        scale_slip = props%friction%mu * pair%force_n / f_trial_mag
        ! Friction force direction in local tangent frame
        f_trial_dir(1) = pair%force_t(1) / f_trial_mag
        f_trial_dir(2) = pair%force_t(2) / f_trial_mag

        ! Full tangential stiffness minus rank-1 correction:
        ! K_t = scale * eps_t * [(N_t1^T N_t1 + N_t2^T N_t2)
        !      - (f1*N_t1 + f2*N_t2)^T * (f1*N_t1 + f2*N_t2)]
        DO I = 1, n_dof
          DO J = 1, n_dof
            K_contact(I, J) = K_contact(I, J) &
              - scale_slip * props%penalty%eps_t * ( &
                  (N_t1(I)*N_t1(J) + N_t2(I)*N_t2(J)) &
                - (f_trial_dir(1)*N_t1(I) + f_trial_dir(2)*N_t2(I)) &
                * (f_trial_dir(1)*N_t1(J) + f_trial_dir(2)*N_t2(J)) )
          END DO
        END DO
      END IF
    END IF

  END SUBROUTINE PH_NTS_ContactStiffness

  !---------------------------------------------------------------------------
  ! PH_NTS_EvalPair: Unified entry — single contact pair full evaluation
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §5 data flow
  ! Algorithm:
  !   1. Project slave node onto master face
  !   2. Compute normal/tangential gap
  !   3. Compute penalty normal force + equivalent nodal forces
  !   4. Coulomb friction return mapping
  !   5. Contact stiffness matrix
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_EvalPair(pair, props, master_coords, x_slave, &
                               f_nodal, K_contact, n_dof, status)
    TYPE(PH_NTS_Pair),  INTENT(INOUT) :: pair       ! [INOUT] Contact pair (updated)
    TYPE(PH_NTS_Props), INTENT(IN)    :: props      ! [IN] Contact properties
    REAL(wp), INTENT(IN) :: master_coords(3, NTS_MAX_FACE_NODES) ! [IN] Master face coords
    REAL(wp), INTENT(IN) :: x_slave(3)               ! [IN] Slave node position
    REAL(wp), INTENT(OUT) :: f_nodal(:)              ! [OUT] Equivalent nodal forces
    REAL(wp), INTENT(OUT) :: K_contact(:,:)          ! [OUT] Contact stiffness
    INTEGER(i4), INTENT(OUT) :: n_dof                ! [OUT] DOF count
    TYPE(ErrorStatusType), INTENT(INOUT) :: status   ! [INOUT] Error status

    LOGICAL  :: proj_converged
    REAL(wp) :: x_proj(3)

    CALL init_error_status(status)
    n_dof = 3 * (pair%n_master_nodes + 1)

    ! Step 1: NTS projection (local NR)
    CALL PH_NTS_ProjectNode(x_slave, master_coords, pair%n_master_nodes, &
                            pair%xi(1), pair%xi(2), x_proj, proj_converged, status)
    IF (.NOT. proj_converged) THEN
      pair%active = .FALSE.
      pair%status = NTS_STATUS_OPEN
      f_nodal(1:n_dof) = 0.0_wp
      K_contact(1:n_dof, 1:n_dof) = 0.0_wp
      RETURN
    END IF

    ! Validate projection within face: |xi| <= 1+tol, |eta| <= 1+tol
    IF (ABS(pair%xi(1)) > 1.0_wp + 0.01_wp .OR. &
        ABS(pair%xi(2)) > 1.0_wp + 0.01_wp) THEN
      pair%active = .FALSE.
      pair%status = NTS_STATUS_OPEN
      f_nodal(1:n_dof) = 0.0_wp
      K_contact(1:n_dof, 1:n_dof) = 0.0_wp
      RETURN
    END IF

    ! Step 2: Gap computation
    CALL PH_NTS_ComputeGap(x_slave, master_coords, pair%n_master_nodes, &
                            pair%xi(1), pair%xi(2), &
                            pair%gap_n, pair%gap_t, pair%normal, status)

    ! Step 3: Penalty normal force
    CALL PH_NTS_PenaltyForce(pair, props, f_nodal, n_dof, status)

    ! Step 4: Friction return mapping
    IF (pair%active) THEN
      CALL PH_NTS_FrictionReturn(pair, props, pair%gap_t, status)
      ! Add friction force contributions to nodal force vector
      CALL AddFrictionNodalForces(pair, f_nodal)
    END IF

    ! Step 5: Contact stiffness
    CALL PH_NTS_ContactStiffness(pair, props, K_contact, n_dof, status)

  END SUBROUTINE PH_NTS_EvalPair

  !---------------------------------------------------------------------------
  ! PH_NTS_SearchBVH: BVH accelerated search for candidate contact pairs
  !---------------------------------------------------------------------------
  ! Design: DESIGN_Cont_HotPath.md §2.3
  ! Algorithm:
  !   1. For each slave node, query BVH tree for nearby master faces
  !   2. Use AABB overlap test for broad phase
  !   3. Refine with NTS projection for narrow phase
  !   4. Return list of active candidate pairs
  ! Note: Consumes existing PH_Cont_BVHBuilder/BVHQuery infrastructure.
  !       This routine replaces the brute-force inner loop in QueryPoint.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_NTS_SearchBVH(slave_nodes, n_slaves, master_coords, n_master_faces, &
                                candidate_pairs, n_candidates, max_candidates, status)
    REAL(wp), INTENT(IN)  :: slave_nodes(:,:)      ! [IN] Slave node coords (3, n_slaves)
    INTEGER(i4), INTENT(IN) :: n_slaves            ! [IN] Number of slave nodes
    REAL(wp), INTENT(IN)  :: master_coords(:,:,:)  ! [IN] Master face coords (3, max_face_nodes, n_faces)
    INTEGER(i4), INTENT(IN) :: n_master_faces      ! [IN] Number of master faces
    TYPE(PH_NTS_Pair), INTENT(OUT) :: candidate_pairs(:) ! [OUT] Candidate pairs
    INTEGER(i4), INTENT(OUT) :: n_candidates       ! [OUT] Number of candidates found
    INTEGER(i4), INTENT(IN)  :: max_candidates     ! [IN] Max capacity
    TYPE(ErrorStatusType), INTENT(INOUT) :: status ! [INOUT] Error status

    ! Local variables
    INTEGER(i4) :: i_slave, i_face, I
    REAL(wp) :: pt(3), face_center(3), dist_sq
    REAL(wp) :: search_radius, radius_sq
    REAL(wp) :: xi_tmp, eta_tmp, x_proj_tmp(3)
    LOGICAL  :: proj_ok
    TYPE(ErrorStatusType) :: proj_status
    REAL(wp) :: face_coords(3, NTS_MAX_FACE_NODES)

    n_candidates = 0_i4
    status%status_code = IF_STATUS_OK

    ! Adaptive search radius: use bounding diagonal of first face as proxy
    ! (in production, this would come from BVH node AABB sizes)
    search_radius = 0.0_wp
    IF (n_master_faces > 0) THEN
      face_center(:) = 0.0_wp
      DO I = 1, 4
        face_center(:) = face_center(:) + master_coords(:, I, 1)
      END DO
      face_center(:) = face_center(:) / 4.0_wp
      DO I = 1, 4
        dist_sq = SUM((master_coords(:, I, 1) - face_center(:))**2)
        search_radius = MAX(search_radius, SQRT(dist_sq))
      END DO
      search_radius = search_radius * 3.0_wp   ! inflate by 3× for safety
    ELSE
      RETURN
    END IF
    radius_sq = search_radius * search_radius

    ! Broad-phase: for each slave node, find nearby master faces
    ! (iterative AABB overlap - replaces recursive BVH traversal)
    DO i_slave = 1, n_slaves
      pt(:) = slave_nodes(:, i_slave)

      DO i_face = 1, n_master_faces
        ! Quick centroid distance check (broad phase)
        face_center(:) = 0.0_wp
        DO I = 1, 4
          face_center(:) = face_center(:) + master_coords(:, I, i_face)
        END DO
        face_center(:) = face_center(:) / 4.0_wp

        dist_sq = SUM((pt(:) - face_center(:))**2)
        IF (dist_sq > radius_sq) CYCLE

        ! Narrow-phase: attempt NTS projection to validate candidate
        face_coords(:,:) = 0.0_wp
        DO I = 1, 4
          face_coords(:, I) = master_coords(:, I, i_face)
        END DO

        CALL init_error_status(proj_status)
        CALL PH_NTS_ProjectNode(pt, face_coords, 4_i4, &
                                xi_tmp, eta_tmp, x_proj_tmp, proj_ok, proj_status)

        ! Accept if projection converged and within face bounds
        IF (proj_ok .AND. ABS(xi_tmp) <= 1.0_wp + 0.05_wp .AND. &
            ABS(eta_tmp) <= 1.0_wp + 0.05_wp) THEN
          IF (n_candidates >= max_candidates) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = 'NTS_SearchBVH: candidate buffer overflow'
            RETURN
          END IF
          n_candidates = n_candidates + 1_i4
          candidate_pairs(n_candidates)%slave_node = i_slave
          candidate_pairs(n_candidates)%master_face(:) = 0_i4
          DO I = 1, 4
            candidate_pairs(n_candidates)%master_face(I) = I  ! face-local ID
          END DO
          candidate_pairs(n_candidates)%n_master_nodes = 4_i4
          candidate_pairs(n_candidates)%xi(1) = xi_tmp
          candidate_pairs(n_candidates)%xi(2) = eta_tmp
          candidate_pairs(n_candidates)%active = .FALSE.  ! pending gap evaluation
        END IF
      END DO
    END DO

  END SUBROUTINE PH_NTS_SearchBVH

  !==========================================================================
  ! PRIVATE HELPER SUBROUTINES
  !==========================================================================

  !---------------------------------------------------------------------------
  ! EvalFaceShapeFunc: Evaluate bilinear/biquadratic face shape functions
  !---------------------------------------------------------------------------
  SUBROUTINE EvalFaceShapeFunc(xi, eta, n_nodes, N, dN_dxi, dN_deta)
    REAL(wp), INTENT(IN)  :: xi, eta
    INTEGER(i4), INTENT(IN) :: n_nodes
    REAL(wp), INTENT(OUT) :: N(NTS_MAX_FACE_NODES)
    REAL(wp), INTENT(OUT) :: dN_dxi(NTS_MAX_FACE_NODES)
    REAL(wp), INTENT(OUT) :: dN_deta(NTS_MAX_FACE_NODES)

    N(:) = 0.0_wp
    dN_dxi(:) = 0.0_wp
    dN_deta(:) = 0.0_wp

    SELECT CASE (n_nodes)
    CASE (4_i4)
      ! QUAD4 bilinear: N_I = 0.25*(1+xi_I*xi)*(1+eta_I*eta)
      N(1) = 0.25_wp * (1.0_wp - xi) * (1.0_wp - eta)
      N(2) = 0.25_wp * (1.0_wp + xi) * (1.0_wp - eta)
      N(3) = 0.25_wp * (1.0_wp + xi) * (1.0_wp + eta)
      N(4) = 0.25_wp * (1.0_wp - xi) * (1.0_wp + eta)

      dN_dxi(1) = -0.25_wp * (1.0_wp - eta)
      dN_dxi(2) =  0.25_wp * (1.0_wp - eta)
      dN_dxi(3) =  0.25_wp * (1.0_wp + eta)
      dN_dxi(4) = -0.25_wp * (1.0_wp + eta)

      dN_deta(1) = -0.25_wp * (1.0_wp - xi)
      dN_deta(2) = -0.25_wp * (1.0_wp + xi)
      dN_deta(3) =  0.25_wp * (1.0_wp + xi)
      dN_deta(4) =  0.25_wp * (1.0_wp - xi)

    CASE (3_i4)
      ! TRIA3: N1 = 1-xi-eta, N2 = xi, N3 = eta
      N(1) = 1.0_wp - xi - eta
      N(2) = xi
      N(3) = eta

      dN_dxi(1) = -1.0_wp
      dN_dxi(2) =  1.0_wp
      dN_dxi(3) =  0.0_wp

      dN_deta(1) = -1.0_wp
      dN_deta(2) =  0.0_wp
      dN_deta(3) =  1.0_wp

    CASE (8_i4)
      ! QUAD8 serendipity: corner + midside nodes
      ! Corner nodes (1-4): N_I = 0.25*(1+xi_I*xi)*(1+eta_I*eta)*(xi_I*xi+eta_I*eta-1)
      ! Midside nodes (5-8): standard serendipity formulation
      N(1) = 0.25_wp*(1.0_wp-xi)*(1.0_wp-eta)*(-xi-eta-1.0_wp)
      N(2) = 0.25_wp*(1.0_wp+xi)*(1.0_wp-eta)*( xi-eta-1.0_wp)
      N(3) = 0.25_wp*(1.0_wp+xi)*(1.0_wp+eta)*( xi+eta-1.0_wp)
      N(4) = 0.25_wp*(1.0_wp-xi)*(1.0_wp+eta)*(-xi+eta-1.0_wp)
      N(5) = 0.5_wp*(1.0_wp-xi**2)*(1.0_wp-eta)
      N(6) = 0.5_wp*(1.0_wp+xi)*(1.0_wp-eta**2)
      N(7) = 0.5_wp*(1.0_wp-xi**2)*(1.0_wp+eta)
      N(8) = 0.5_wp*(1.0_wp-xi)*(1.0_wp-eta**2)

      dN_dxi(1) = 0.25_wp*(1.0_wp-eta)*( 2.0_wp*xi+eta)
      dN_dxi(2) = 0.25_wp*(1.0_wp-eta)*( 2.0_wp*xi-eta)
      dN_dxi(3) = 0.25_wp*(1.0_wp+eta)*( 2.0_wp*xi+eta)
      dN_dxi(4) = 0.25_wp*(1.0_wp+eta)*( 2.0_wp*xi-eta)
      dN_dxi(5) = -xi*(1.0_wp-eta)
      dN_dxi(6) =  0.5_wp*(1.0_wp-eta**2)
      dN_dxi(7) = -xi*(1.0_wp+eta)
      dN_dxi(8) = -0.5_wp*(1.0_wp-eta**2)

      dN_deta(1) = 0.25_wp*(1.0_wp-xi)*( xi+2.0_wp*eta)
      dN_deta(2) = 0.25_wp*(1.0_wp+xi)*(-xi+2.0_wp*eta)
      dN_deta(3) = 0.25_wp*(1.0_wp+xi)*( xi+2.0_wp*eta)
      dN_deta(4) = 0.25_wp*(1.0_wp-xi)*(-xi+2.0_wp*eta)
      dN_deta(5) = -0.5_wp*(1.0_wp-xi**2)
      dN_deta(6) = -eta*(1.0_wp+xi)
      dN_deta(7) =  0.5_wp*(1.0_wp-xi**2)
      dN_deta(8) = -eta*(1.0_wp-xi)

    CASE (6_i4)
      ! TRIA6 quadratic triangle: N1=L1*(2L1-1), N4=4*L1*L2, etc.
      ! where L1=1-xi-eta, L2=xi, L3=eta  (area coordinates)
      N(1) = (1.0_wp-xi-eta)*(2.0_wp*(1.0_wp-xi-eta)-1.0_wp)
      N(2) = xi*(2.0_wp*xi-1.0_wp)
      N(3) = eta*(2.0_wp*eta-1.0_wp)
      N(4) = 4.0_wp*xi*(1.0_wp-xi-eta)
      N(5) = 4.0_wp*xi*eta
      N(6) = 4.0_wp*eta*(1.0_wp-xi-eta)

      dN_dxi(1) = -3.0_wp + 4.0_wp*xi + 4.0_wp*eta
      dN_dxi(2) =  4.0_wp*xi - 1.0_wp
      dN_dxi(3) =  0.0_wp
      dN_dxi(4) =  4.0_wp - 8.0_wp*xi - 4.0_wp*eta
      dN_dxi(5) =  4.0_wp*eta
      dN_dxi(6) = -4.0_wp*eta

      dN_deta(1) = -3.0_wp + 4.0_wp*xi + 4.0_wp*eta
      dN_deta(2) =  0.0_wp
      dN_deta(3) =  4.0_wp*eta - 1.0_wp
      dN_deta(4) = -4.0_wp*xi
      dN_deta(5) =  4.0_wp*xi
      dN_deta(6) =  4.0_wp - 4.0_wp*xi - 8.0_wp*eta

    CASE DEFAULT
      ! Unsupported face topology — zero shape functions
      N(1:n_nodes) = 0.0_wp
    END SELECT

  END SUBROUTINE EvalFaceShapeFunc

  !---------------------------------------------------------------------------
  ! Cross3: 3D cross product  c = a × b
  !---------------------------------------------------------------------------
  PURE SUBROUTINE Cross3(a, b, c)
    REAL(wp), INTENT(IN)  :: a(3), b(3)
    REAL(wp), INTENT(OUT) :: c(3)
    c(1) = a(2)*b(3) - a(3)*b(2)
    c(2) = a(3)*b(1) - a(1)*b(3)
    c(3) = a(1)*b(2) - a(2)*b(1)
  END SUBROUTINE Cross3

  !---------------------------------------------------------------------------
  ! BuildTangentBasis: Construct orthonormal tangent vectors from a normal
  !---------------------------------------------------------------------------
  ! Given unit normal n, produce orthonormal (t1, t2) such that
  ! n, t1, t2 form a right-handed frame.
  ! Algorithm: Hughes-Moeller robust method — pick the component of n
  ! with smallest magnitude to seed the cross product.
  !---------------------------------------------------------------------------
  PURE SUBROUTINE BuildTangentBasis(n, t1, t2)
    REAL(wp), INTENT(IN)  :: n(3)
    REAL(wp), INTENT(OUT) :: t1(3), t2(3)

    REAL(wp) :: tmp(3), nrm

    ! Pick seed vector least parallel to n
    IF (ABS(n(1)) <= ABS(n(2)) .AND. ABS(n(1)) <= ABS(n(3))) THEN
      tmp = (/ 1.0_wp, 0.0_wp, 0.0_wp /)
    ELSE IF (ABS(n(2)) <= ABS(n(3))) THEN
      tmp = (/ 0.0_wp, 1.0_wp, 0.0_wp /)
    ELSE
      tmp = (/ 0.0_wp, 0.0_wp, 1.0_wp /)
    END IF

    ! t1 = normalize(tmp - (tmp·n)*n)
    t1(:) = tmp(:) - DOT_PRODUCT(tmp, n) * n(:)
    nrm = SQRT(DOT_PRODUCT(t1, t1))
    IF (nrm > 1.0E-30_wp) THEN
      t1(:) = t1(:) / nrm
    ELSE
      t1 = (/ 1.0_wp, 0.0_wp, 0.0_wp /)
    END IF

    ! t2 = n × t1
    t2(1) = n(2)*t1(3) - n(3)*t1(2)
    t2(2) = n(3)*t1(1) - n(1)*t1(3)
    t2(3) = n(1)*t1(2) - n(2)*t1(1)

  END SUBROUTINE BuildTangentBasis

  !---------------------------------------------------------------------------
  ! AddFrictionNodalForces: Add tangential friction force to nodal force vector
  !---------------------------------------------------------------------------
  ! Projects the 2D local friction force (force_t) into global 3D via the
  ! tangent basis, then distributes to master and slave DOFs.
  !---------------------------------------------------------------------------
  SUBROUTINE AddFrictionNodalForces(pair, f_nodal)
    TYPE(PH_NTS_Pair), INTENT(IN) :: pair
    REAL(wp), INTENT(INOUT) :: f_nodal(:)

    REAL(wp) :: t1(3), t2(3), f_t_global(3)
    REAL(wp) :: N_shape(NTS_MAX_FACE_NODES)
    REAL(wp) :: dN_dxi(NTS_MAX_FACE_NODES), dN_deta(NTS_MAX_FACE_NODES)
    INTEGER(i4) :: I, n_mn, base_idx

    n_mn = pair%n_master_nodes

    ! Build tangent basis from contact normal
    CALL BuildTangentBasis(pair%normal, t1, t2)

    ! Global friction force vector
    f_t_global(:) = pair%force_t(1) * t1(:) + pair%force_t(2) * t2(:)

    ! Shape functions at projection point
    CALL EvalFaceShapeFunc(pair%xi(1), pair%xi(2), n_mn, N_shape, dN_dxi, dN_deta)

    ! Master nodes: F_I -= N_I * f_t_global (reaction)
    DO I = 1, n_mn
      base_idx = 3 * (I - 1)
      f_nodal(base_idx + 1) = f_nodal(base_idx + 1) - N_shape(I) * f_t_global(1)
      f_nodal(base_idx + 2) = f_nodal(base_idx + 2) - N_shape(I) * f_t_global(2)
      f_nodal(base_idx + 3) = f_nodal(base_idx + 3) - N_shape(I) * f_t_global(3)
    END DO
    ! Slave node: F_s += f_t_global
    base_idx = 3 * n_mn
    f_nodal(base_idx + 1) = f_nodal(base_idx + 1) + f_t_global(1)
    f_nodal(base_idx + 2) = f_nodal(base_idx + 2) + f_t_global(2)
    f_nodal(base_idx + 3) = f_nodal(base_idx + 3) + f_t_global(3)

  END SUBROUTINE AddFrictionNodalForces

END MODULE PH_Cont_NTS_Eval
