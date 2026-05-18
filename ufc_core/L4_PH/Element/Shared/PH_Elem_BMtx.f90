!===============================================================================
! MODULE: PH_Elem_BMtx
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Strain-displacement B-matrix (Shared Tool)
!===============================================================================
MODULE PH_Elem_BMtx
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_BMatrix_2D_Plane
    PUBLIC :: PH_Elem_BMatrix_3D_Continuum
    PUBLIC :: PH_Elem_BMatrix_Axisymmetric
    PUBLIC :: PH_Elem_BMatrix_Shell
    ! Extended API (task8100-8199)
    PUBLIC :: PH_Elem_BMatrix_2D_Plane_Strain
    PUBLIC :: PH_Elem_BMatrix_2D_Plane_Stress
    PUBLIC :: PH_Elem_BMatrix_Shell_MITC
    PUBLIC :: PH_Elem_BMatrix_Derivative

  !=============================================================================
  ! INTF-001 Arg TYPE
  !=============================================================================
  PUBLIC :: PH_Elem_Shared_Args
  TYPE :: PH_Elem_Shared_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  END TYPE PH_Elem_Shared_Args


CONTAINS

    SUBROUTINE ET_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL PH_Elem_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)
    END SUBROUTINE ET_BMatrix_2D_Plane

    SUBROUTINE ET_BMatrix_3D_Continuum(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL PH_Elem_BMatrix_3D_Continuum(dN_dx, n_nodes, B, status)
    END SUBROUTINE ET_BMatrix_3D_Continuum

    SUBROUTINE ET_BMatrix_Axisymmetric(dN_dx, N, r, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:), N(:), r
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL PH_Elem_BMatrix_Axisymmetric(dN_dx, N, r, n_nodes, B, status)
    END SUBROUTINE ET_BMatrix_Axisymmetric

    SUBROUTINE ET_BMatrix_Shell(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL PH_Elem_BMatrix_Shell(dN_dx, n_nodes, B, status)
    END SUBROUTINE ET_BMatrix_Shell

    SUBROUTINE PH_El_BM_2D_Pl_Strain(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        ! Plane strain uses same B-matrix as plane sigma
        CALL PH_Elem_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)

    END SUBROUTINE PH_Elem_BMatrix_2D_Plane_Strain

    SUBROUTINE PH_El_BM_2D_Pl_Stress(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        ! Plane sigma uses same B-matrix as plane strain
        CALL PH_Elem_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)

    END SUBROUTINE PH_Elem_BMatrix_2D_Plane_Stress

    SUBROUTINE PH_Elem_BMatrix_2D_Plane(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)  ! (2, n_nodes)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)  ! (3, 2*n_nodes)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, col_idx

        CALL init_error_status(status)

        IF (SIZE(dN_dx, 1) < 2 .OR. SIZE(dN_dx, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_2D_Plane: Invalid dN_dx dimensions'
            RETURN
        END IF

        IF (SIZE(B, 1) < 3 .OR. SIZE(B, 2) < 2*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_2D_Plane: Invalid B dimensions'
            RETURN
        END IF

        B = ZERO

        ! B-matrix for plane sigma/strain: [eps_xx, eps_yy, gamma_xy]^T = B * [u1, v1, u2, v2, ...]^T
        DO i = 1, n_nodes
            col_idx = 2 * (i - 1) + 1

            ! eps_xx = dN_i/dx * u_i
            B(1, col_idx) = dN_dx(1, i)
            B(1, col_idx + 1) = ZERO

            ! eps_yy = dN_i/dy * v_i
            B(2, col_idx) = ZERO
            B(2, col_idx + 1) = dN_dx(2, i)

            ! gamma_xy = dN_i/dy * u_i + dN_i/dx * v_i
            B(3, col_idx) = dN_dx(2, i)
            B(3, col_idx + 1) = dN_dx(1, i)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_BMatrix_2D_Plane

    SUBROUTINE PH_Elem_BMatrix_3D_Continuum(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)  ! (3, n_nodes)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)  ! (6, 3*n_nodes)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, col_idx

        CALL init_error_status(status)

        IF (SIZE(dN_dx, 1) < 3 .OR. SIZE(dN_dx, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_3D_Continuum: Invalid dN_dx dimensions'
            RETURN
        END IF

        IF (SIZE(B, 1) < 6 .OR. SIZE(B, 2) < 3*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_3D_Continuum: Invalid B dimensions'
            RETURN
        END IF

        B = ZERO

        ! B-matrix for 3D: [eps_xx, eps_yy, eps_zz, gamma_xy, gamma_yz, gamma_zx]^T
        DO i = 1, n_nodes
            col_idx = 3 * (i - 1) + 1

            ! eps_xx = dN_i/dx * u_i
            B(1, col_idx) = dN_dx(1, i)
            B(1, col_idx + 1) = ZERO
            B(1, col_idx + 2) = ZERO

            ! eps_yy = dN_i/dy * v_i
            B(2, col_idx) = ZERO
            B(2, col_idx + 1) = dN_dx(2, i)
            B(2, col_idx + 2) = ZERO

            ! eps_zz = dN_i/dz * w_i
            B(3, col_idx) = ZERO
            B(3, col_idx + 1) = ZERO
            B(3, col_idx + 2) = dN_dx(3, i)

            ! gamma_xy = dN_i/dy * u_i + dN_i/dx * v_i
            B(4, col_idx) = dN_dx(2, i)
            B(4, col_idx + 1) = dN_dx(1, i)
            B(4, col_idx + 2) = ZERO

            ! gamma_yz = dN_i/dz * v_i + dN_i/dy * w_i
            B(5, col_idx) = ZERO
            B(5, col_idx + 1) = dN_dx(3, i)
            B(5, col_idx + 2) = dN_dx(2, i)

            ! gamma_zx = dN_i/dx * w_i + dN_i/dz * u_i
            B(6, col_idx) = dN_dx(3, i)
            B(6, col_idx + 1) = ZERO
            B(6, col_idx + 2) = dN_dx(1, i)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_BMatrix_3D_Continuum

    SUBROUTINE PH_Elem_BMatrix_Axisymmetric(dN_dx, N, r, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)  ! (2, n_nodes) - derivatives w.r.t. r, z
        REAL(wp), INTENT(IN) :: N(:)  ! (n_nodes)
        REAL(wp), INTENT(IN) :: r  ! Radial coordinate
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)  ! (4, 2*n_nodes)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, col_idx
        REAL(wp) :: inv_r

        CALL init_error_status(status)

        IF (SIZE(dN_dx, 1) < 2 .OR. SIZE(dN_dx, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Axisymmetric: Invalid dN_dx dimensions'
            RETURN
        END IF

        IF (SIZE(N) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Axisymmetric: Invalid N dimensions'
            RETURN
        END IF

        IF (SIZE(B, 1) < 4 .OR. SIZE(B, 2) < 2*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Axisymmetric: Invalid B dimensions'
            RETURN
        END IF

        IF (ABS(r) < 1.0e-10_wp) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Axisymmetric: r too small'
            RETURN
        END IF

        B = ZERO
        inv_r = ONE / r

        ! B-matrix for axisymmetric: [eps_rr, eps_zz, eps_theta, gamma_rz]^T
        DO i = 1, n_nodes
            col_idx = 2 * (i - 1) + 1

            ! eps_rr = dN_i/dr * u_i
            B(1, col_idx) = dN_dx(1, i)
            B(1, col_idx + 1) = ZERO

            ! eps_zz = dN_i/dz * v_i
            B(2, col_idx) = ZERO
            B(2, col_idx + 1) = dN_dx(2, i)

            ! eps_theta = N_i/r * u_i (hoop strain)
            B(3, col_idx) = N(i) * inv_r
            B(3, col_idx + 1) = ZERO

            ! gamma_rz = dN_i/dz * u_i + dN_i/dr * v_i
            B(4, col_idx) = dN_dx(2, i)
            B(4, col_idx + 1) = dN_dx(1, i)
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_BMatrix_Axisymmetric

    SUBROUTINE PH_Elem_BMatrix_Derivative(dN_dx, d2N_dx2, n_nodes, dB_dx, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:), d2N_dx2(:,:,:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: dB_dx(:,:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, col_idx, dim_idx
        INTEGER(i4) :: n_dim, n_strain

        CALL init_error_status(status)

        n_dim = SIZE(dN_dx, 1)
        n_strain = SIZE(dB_dx, 1)

        IF (n_dim == 2) THEN
            ! 2D case
            DO i = 1, n_nodes
                col_idx = 2 * (i - 1) + 1
                ! dB/dx for eps_xx
                dB_dx(1, col_idx, 1) = d2N_dx2(1, 1, i)  ! d²N/dx²
                dB_dx(1, col_idx, 2) = d2N_dx2(1, 2, i)  ! d²N/dxdy
                ! dB/dy for eps_yy
                dB_dx(2, col_idx + 1, 1) = d2N_dx2(2, 1, i)  ! d²N/dydx
                dB_dx(2, col_idx + 1, 2) = d2N_dx2(2, 2, i)  ! d²N/dy²
                ! dB for gamma_xy
                dB_dx(3, col_idx, 1) = d2N_dx2(2, 1, i)
                dB_dx(3, col_idx, 2) = d2N_dx2(2, 2, i)
                dB_dx(3, col_idx + 1, 1) = d2N_dx2(1, 1, i)
                dB_dx(3, col_idx + 1, 2) = d2N_dx2(1, 2, i)
            END DO
        ELSE IF (n_dim == 3) THEN
            ! 3D case: dB/dx for eps_xx, eps_yy, eps_zz, gamma_xy, gamma_yz, gamma_xz
            DO i = 1, n_nodes
                col_idx = 3 * (i - 1) + 1
                ! eps_xx: d(dN/dx)/d(x,y,z)
                dB_dx(1, col_idx, 1) = d2N_dx2(1, 1, i)
                dB_dx(1, col_idx, 2) = d2N_dx2(1, 2, i)
                dB_dx(1, col_idx, 3) = d2N_dx2(1, 3, i)
                ! eps_yy
                dB_dx(2, col_idx + 1, 1) = d2N_dx2(2, 1, i)
                dB_dx(2, col_idx + 1, 2) = d2N_dx2(2, 2, i)
                dB_dx(2, col_idx + 1, 3) = d2N_dx2(2, 3, i)
                ! eps_zz
                dB_dx(3, col_idx + 2, 1) = d2N_dx2(3, 1, i)
                dB_dx(3, col_idx + 2, 2) = d2N_dx2(3, 2, i)
                dB_dx(3, col_idx + 2, 3) = d2N_dx2(3, 3, i)
                ! gamma_xy = dN/dy for u and dN/dx for v
                dB_dx(4, col_idx, 1) = d2N_dx2(2, 1, i)
                dB_dx(4, col_idx, 2) = d2N_dx2(2, 2, i)
                dB_dx(4, col_idx, 3) = d2N_dx2(2, 3, i)
                dB_dx(4, col_idx + 1, 1) = d2N_dx2(1, 1, i)
                dB_dx(4, col_idx + 1, 2) = d2N_dx2(1, 2, i)
                dB_dx(4, col_idx + 1, 3) = d2N_dx2(1, 3, i)
                ! gamma_yz
                dB_dx(5, col_idx + 1, 1) = d2N_dx2(3, 1, i)
                dB_dx(5, col_idx + 1, 2) = d2N_dx2(3, 2, i)
                dB_dx(5, col_idx + 1, 3) = d2N_dx2(3, 3, i)
                dB_dx(5, col_idx + 2, 1) = d2N_dx2(2, 1, i)
                dB_dx(5, col_idx + 2, 2) = d2N_dx2(2, 2, i)
                dB_dx(5, col_idx + 2, 3) = d2N_dx2(2, 3, i)
                ! gamma_xz
                dB_dx(6, col_idx, 1) = d2N_dx2(3, 1, i)
                dB_dx(6, col_idx, 2) = d2N_dx2(3, 2, i)
                dB_dx(6, col_idx, 3) = d2N_dx2(3, 3, i)
                dB_dx(6, col_idx + 2, 1) = d2N_dx2(1, 1, i)
                dB_dx(6, col_idx + 2, 2) = d2N_dx2(1, 2, i)
                dB_dx(6, col_idx + 2, 3) = d2N_dx2(1, 3, i)
            END DO
        END IF

        status%status_code = IF_STATUS_OK

    END SUBROUTINE PH_Elem_BMatrix_Derivative

    SUBROUTINE PH_Elem_BMatrix_Shell(dN_dx, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:)  ! (2, n_nodes)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)  ! (5, 5*n_nodes) - simplified
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i, col_idx

        CALL init_error_status(status)

        IF (SIZE(dN_dx, 1) < 2 .OR. SIZE(dN_dx, 2) < n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Shell: Invalid dN_dx dimensions'
            RETURN
        END IF

        IF (SIZE(B, 1) < 5 .OR. SIZE(B, 2) < 5*n_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_BMatrix_Shell: Invalid B dimensions'
            RETURN
        END IF

        B = ZERO

        ! Simplified shell B-matrix: membrane (3) + bending (2)
        ! DOF: [u, v, w, rot_x, rot_y] per node
        DO i = 1, n_nodes
            col_idx = 5 * (i - 1) + 1

            ! Membrane strains (eps_xx, eps_yy, gamma_xy)
            B(1, col_idx) = dN_dx(1, i)      ! eps_xx
            B(2, col_idx + 1) = dN_dx(2, i)  ! eps_yy
            B(3, col_idx) = dN_dx(2, i)      ! gamma_xy
            B(3, col_idx + 1) = dN_dx(1, i)

            ! Bending curvature (kappa_xx = -d(rot_x)/dx, kappa_yy = -d(rot_y)/dy)
            B(4, col_idx + 3) = -dN_dx(1, i)  ! kappa_xx from rot_x
            B(5, col_idx + 4) = -dN_dx(2, i)  ! kappa_yy from rot_y
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE PH_Elem_BMatrix_Shell

    SUBROUTINE PH_Elem_BMatrix_Shell_MITC(dN_dx, N, n_nodes, B, status)
        REAL(wp), INTENT(IN) :: dN_dx(:,:), N(:)
        INTEGER(i4), INTENT(IN) :: n_nodes
        REAL(wp), INTENT(OUT) :: B(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        ! Simplified MITC shell B-matrix
        ! Full implementation requires interpolation of transverse shear strains
        CALL init_error_status(status)

        ! MITC: transverse shear interpolated at tying points; here use standard B.
        CALL PH_Elem_BMatrix_Shell(dN_dx, n_nodes, B, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN
        ! Full MITC would replace shear rows with interpolation at tying points per edge.
    END SUBROUTINE PH_Elem_BMatrix_Shell_MITC
END MODULE PH_Elem_BMtx