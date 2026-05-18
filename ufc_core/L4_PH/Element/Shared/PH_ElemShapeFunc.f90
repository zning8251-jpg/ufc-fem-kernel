!===============================================================================
! MODULE: PH_ElemShapeFunc
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Shape functions N(ξ) for element families (Shared Tool)
!===============================================================================
MODULE PH_ElemShapeFunc
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, HALF, QUARTER
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_SF_Truss_Lin
    PUBLIC :: PH_Elem_SF_Beam_Hermite
    PUBLIC :: PH_Elem_SF_Triangle_Linear
    PUBLIC :: PH_Elem_SF_Triangle_Quadratic
    PUBLIC :: PH_Elem_SF_Quad_Linear
    PUBLIC :: PH_Elem_SF_Quad_Quadratic
    PUBLIC :: PH_Elem_SF_Tetra_Linear
    PUBLIC :: PH_Elem_SF_Tetra_Quadratic
    PUBLIC :: PH_Elem_SF_Hex_Linear
    PUBLIC :: PH_Elem_SF_Hex_Quadratic
    PUBLIC :: PH_Elem_SF_Shell_Linear
    PUBLIC :: PH_Elem_SF_Shell_Quadratic
    ! Extended API (task8000-8099)
    PUBLIC :: PH_Elem_SF_Hex_20Node
    PUBLIC :: PH_Elem_SF_Wedge_Lin
    PUBLIC :: PH_Elem_SF_Pyramid_Lin
    PUBLIC :: PH_Elem_SF_Shell_8Node

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

    SUBROUTINE ET_SF_Beam_Hermite(xi, L, N, dN_dxi)
        REAL(wp), INTENT(IN) :: xi, L
        REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4)
        CALL PH_Elem_SF_Beam_Hermite(xi, L, N, dN_dxi)
    END SUBROUTINE ET_SF_Beam_Hermite

    SUBROUTINE ET_SF_Hex_Lin(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(8), dN_dxi(8), dN_deta(8), dN_dzeta(8)

        REAL(wp) :: xi_p(8), eta_p(8), zeta_p(8)
        INTEGER(i4) :: i

        ! Node coordinates in natural space
        xi_p = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
        eta_p = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
        zeta_p = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]

        DO i = 1, 8
            N(i) = QUARTER * (ONE + xi_p(i) * xi) * &
                          (ONE + eta_p(i) * eta) * &
                          (ONE + zeta_p(i) * zeta)

            dN_dxi(i) = QUARTER * xi_p(i) * (ONE + eta_p(i) * eta) * &
                               (ONE + zeta_p(i) * zeta)
            dN_deta(i) = QUARTER * (ONE + xi_p(i) * xi) * eta_p(i) * &
                                (ONE + zeta_p(i) * zeta)
            dN_dzeta(i) = QUARTER * (ONE + xi_p(i) * xi) * &
                                 (ONE + eta_p(i) * eta) * zeta_p(i)
        END DO
    END SUBROUTINE ET_SF_Hex_Lin

    SUBROUTINE ET_SF_Hex_Quadratic(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(20), dN_dxi(20), dN_deta(20), dN_dzeta(20)
        CALL PH_Elem_SF_Hex_20Node(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
    END SUBROUTINE ET_SF_Hex_Quadratic

    SUBROUTINE ET_SF_Quad_Lin(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4), dN_deta(4)

        REAL(wp) :: xi_p(4), eta_p(4)

        ! Node coordinates in natural space
        xi_p = [-ONE, ONE, ONE, -ONE]
        eta_p = [-ONE, -ONE, ONE, ONE]

        ! Shape functions
        N(1) = QUARTER * (ONE - xi) * (ONE - eta)
        N(2) = QUARTER * (ONE + xi) * (ONE - eta)
        N(3) = QUARTER * (ONE + xi) * (ONE + eta)
        N(4) = QUARTER * (ONE - xi) * (ONE + eta)

        ! Derivatives w.r.t. xi
        dN_dxi(1) = -QUARTER * (ONE - eta)
        dN_dxi(2) = QUARTER * (ONE - eta)
        dN_dxi(3) = QUARTER * (ONE + eta)
        dN_dxi(4) = -QUARTER * (ONE + eta)

        ! Derivatives w.r.t. eta
        dN_deta(1) = -QUARTER * (ONE - xi)
        dN_deta(2) = -QUARTER * (ONE + xi)
        dN_deta(3) = QUARTER * (ONE + xi)
        dN_deta(4) = QUARTER * (ONE - xi)
    END SUBROUTINE ET_SF_Quad_Lin

    SUBROUTINE ET_SF_Quad_Quadratic(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(8), dN_dxi(8), dN_deta(8)

        REAL(wp) :: xi_p(8), eta_p(8)
        REAL(wp) :: xi2, eta2, xi_eta

        ! Node coordinates in natural space
        xi_p = [-ONE, ONE, ONE, -ONE, ZERO, ONE, ZERO, -ONE]
        eta_p = [-ONE, -ONE, ONE, ONE, -ONE, ZERO, ONE, ZERO]

        xi2 = xi * xi
        eta2 = eta * eta
        xi_eta = xi * eta

        ! Corner nodes
        N(1) = QUARTER * (ONE - xi) * (ONE - eta) * (-ONE - xi - eta)
        N(2) = QUARTER * (ONE + xi) * (ONE - eta) * (-ONE + xi - eta)
        N(3) = QUARTER * (ONE + xi) * (ONE + eta) * (-ONE + xi + eta)
        N(4) = QUARTER * (ONE - xi) * (ONE + eta) * (-ONE - xi + eta)

        ! Mid-side nodes
        N(5) = HALF * (ONE - xi2) * (ONE - eta)
        N(6) = HALF * (ONE + xi) * (ONE - eta2)
        N(7) = HALF * (ONE - xi2) * (ONE + eta)
        N(8) = HALF * (ONE - xi) * (ONE - eta2)

        ! Derivatives w.r.t. xi (simplified)
        dN_dxi(1) = QUARTER * (ONE - eta) * (2.0_wp * xi + eta)
        dN_dxi(2) = QUARTER * (ONE - eta) * (2.0_wp * xi - eta)
        dN_dxi(3) = QUARTER * (ONE + eta) * (2.0_wp * xi + eta)
        dN_dxi(4) = QUARTER * (ONE + eta) * (2.0_wp * xi - eta)
        dN_dxi(5) = -xi * (ONE - eta)
        dN_dxi(6) = HALF * (ONE - eta2)
        dN_dxi(7) = -xi * (ONE + eta)
        dN_dxi(8) = -HALF * (ONE - eta2)

        ! Derivatives w.r.t. eta (simplified)
        dN_deta(1) = QUARTER * (ONE - xi) * (xi + 2.0_wp * eta)
        dN_deta(2) = QUARTER * (ONE + xi) * (-xi + 2.0_wp * eta)
        dN_deta(3) = QUARTER * (ONE + xi) * (xi + 2.0_wp * eta)
        dN_deta(4) = QUARTER * (ONE - xi) * (-xi + 2.0_wp * eta)
        dN_deta(5) = -HALF * (ONE - xi2)
        dN_deta(6) = -eta * (ONE + xi)
        dN_deta(7) = HALF * (ONE - xi2)
        dN_deta(8) = -eta * (ONE - xi)
    END SUBROUTINE ET_SF_Quad_Quadratic

    SUBROUTINE ET_SF_Shell_Lin(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4), dN_deta(4)

        ! Same as quadrilateral
        CALL ET_SF_Quad_Lin(xi, eta, N, dN_dxi, dN_deta)
    END SUBROUTINE ET_SF_Shell_Lin

    SUBROUTINE ET_SF_Shell_Quadratic(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(8), dN_dxi(8), dN_deta(8)
        CALL PH_Elem_SF_Shell_8Node(xi, eta, N, dN_dxi, dN_deta)
    END SUBROUTINE ET_SF_Shell_Quadratic

    SUBROUTINE ET_SF_Tetra_Lin(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4), dN_deta(4), dN_dzeta(4)

        REAL(wp) :: L4

        L4 = ONE - xi - eta - zeta

        N(1) = xi
        N(2) = eta
        N(3) = zeta
        N(4) = L4

        dN_dxi(1) = ONE
        dN_dxi(2) = ZERO
        dN_dxi(3) = ZERO
        dN_dxi(4) = -ONE

        dN_deta(1) = ZERO
        dN_deta(2) = ONE
        dN_deta(3) = ZERO
        dN_deta(4) = -ONE

        dN_dzeta(1) = ZERO
        dN_dzeta(2) = ZERO
        dN_dzeta(3) = ONE
        dN_dzeta(4) = -ONE
    END SUBROUTINE ET_SF_Tetra_Lin

    SUBROUTINE ET_SF_Tetra_Quadratic(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(10), dN_dxi(10), dN_deta(10), dN_dzeta(10)

        REAL(wp) :: L4

        L4 = ONE - xi - eta - zeta

        ! Corner nodes
        N(1) = xi * (2.0_wp * xi - ONE)
        N(2) = eta * (2.0_wp * eta - ONE)
        N(3) = zeta * (2.0_wp * zeta - ONE)
        N(4) = L4 * (2.0_wp * L4 - ONE)

        ! Mid-edge nodes
        N(5) = 4.0_wp * xi * eta
        N(6) = 4.0_wp * eta * zeta
        N(7) = 4.0_wp * zeta * xi
        N(8) = 4.0_wp * xi * L4
        N(9) = 4.0_wp * eta * L4
        N(10) = 4.0_wp * zeta * L4

        ! Corner derivatives: d/dxi (L*(2*L-1)) = (4*L-1)*dL/d(Î¾,Î·,Î¶)
        dN_dxi(1) = 4.0_wp * xi - ONE
        dN_deta(1) = ZERO
        dN_dzeta(1) = ZERO
        dN_dxi(2) = ZERO
        dN_deta(2) = 4.0_wp * eta - ONE
        dN_dzeta(2) = ZERO
        dN_dxi(3) = ZERO
        dN_deta(3) = ZERO
        dN_dzeta(3) = 4.0_wp * zeta - ONE
        dN_dxi(4) = -(4.0_wp * L4 - ONE)
        dN_deta(4) = -(4.0_wp * L4 - ONE)
        dN_dzeta(4) = -(4.0_wp * L4 - ONE)
        ! Mid-edge: N5=4*xi*eta, N6=4*eta*zeta, N7=4*zeta*xi, N8=4*xi*L4, N9=4*eta*L4, N10=4*zeta*L4
        dN_dxi(5) = 4.0_wp * eta
        dN_deta(5) = 4.0_wp * xi
        dN_dzeta(5) = ZERO
        dN_dxi(6) = ZERO
        dN_deta(6) = 4.0_wp * zeta
        dN_dzeta(6) = 4.0_wp * eta
        dN_dxi(7) = 4.0_wp * zeta
        dN_deta(7) = ZERO
        dN_dzeta(7) = 4.0_wp * xi
        dN_dxi(8) = 4.0_wp * (L4 - xi)
        dN_deta(8) = -4.0_wp * xi
        dN_dzeta(8) = -4.0_wp * xi
        dN_dxi(9) = -4.0_wp * eta
        dN_deta(9) = 4.0_wp * (L4 - eta)
        dN_dzeta(9) = -4.0_wp * eta
        dN_dxi(10) = -4.0_wp * zeta
        dN_deta(10) = -4.0_wp * zeta
        dN_dzeta(10) = 4.0_wp * (L4 - zeta)
    END SUBROUTINE ET_SF_Tetra_Quadratic

    SUBROUTINE ET_SF_Triangle_Lin(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(3), dN_dxi(3), dN_deta(3)

        N(1) = ONE - xi - eta
        N(2) = xi
        N(3) = eta

        dN_dxi(1) = -ONE
        dN_dxi(2) = ONE
        dN_dxi(3) = ZERO

        dN_deta(1) = -ONE
        dN_deta(2) = ZERO
        dN_deta(3) = ONE
    END SUBROUTINE ET_SF_Triangle_Lin

    SUBROUTINE ET_SF_Triangle_Quadratic(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(6), dN_dxi(6), dN_deta(6)

        REAL(wp) :: zeta

        zeta = ONE - xi - eta

        ! Corner nodes
        N(1) = zeta * (2.0_wp * zeta - ONE)
        N(2) = xi * (2.0_wp * xi - ONE)
        N(3) = eta * (2.0_wp * eta - ONE)

        ! Mid-side nodes
        N(4) = 4.0_wp * zeta * xi
        N(5) = 4.0_wp * xi * eta
        N(6) = 4.0_wp * eta * zeta

        ! Derivatives w.r.t. xi
        dN_dxi(1) = -4.0_wp * zeta + ONE
        dN_dxi(2) = 4.0_wp * xi - ONE
        dN_dxi(3) = ZERO
        dN_dxi(4) = 4.0_wp * (zeta - xi)
        dN_dxi(5) = 4.0_wp * eta
        dN_dxi(6) = -4.0_wp * eta

        ! Derivatives w.r.t. eta
        dN_deta(1) = -4.0_wp * zeta + ONE
        dN_deta(2) = ZERO
        dN_deta(3) = 4.0_wp * eta - ONE
        dN_deta(4) = -4.0_wp * xi
        dN_deta(5) = 4.0_wp * xi
        dN_deta(6) = 4.0_wp * (zeta - eta)
    END SUBROUTINE ET_SF_Triangle_Quadratic

    SUBROUTINE ET_SF_Truss_Lin(xi, N, dN_dxi)
        REAL(wp), INTENT(IN) :: xi
        REAL(wp), INTENT(OUT) :: N(2), dN_dxi(2)
        CALL PH_Elem_SF_Truss_Lin(xi, N, dN_dxi)
    END SUBROUTINE ET_SF_Truss_Lin

    SUBROUTINE PH_Elem_SF_Beam_Hermite(xi, L, N, dN_dxi)
        REAL(wp), INTENT(IN) :: xi, L
        REAL(wp), INTENT(OUT) :: N(4), dN_dxi(4)

        REAL(wp) :: xi2, xi3

        xi2 = xi * xi
        xi3 = xi2 * xi

        ! Displacement shape functions
        N(1) = HALF * (ONE - xi)
        N(2) = HALF * (ONE + xi)

        ! Rotation shape functions
        N(3) = L * (ONE - xi2) * (ONE - xi) / 8.0_wp
        N(4) = L * (ONE - xi2) * (ONE + xi) / 8.0_wp

        ! Derivatives
        dN_dxi(1) = -HALF
        dN_dxi(2) = HALF
        dN_dxi(3) = L * (-3.0_wp * xi2 + 2.0_wp * xi + ONE) / 8.0_wp
        dN_dxi(4) = L * (3.0_wp * xi2 + 2.0_wp * xi - ONE) / 8.0_wp
    END SUBROUTINE PH_Elem_SF_Beam_Hermite

    SUBROUTINE PH_Elem_SF_Hex_20Node(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(20), dN_dxi(20), dN_deta(20), dN_dzeta(20)

        REAL(wp) :: xi_p(8), eta_p(8), zeta_p(8)
        REAL(wp) :: xi2, eta2, zeta2
        REAL(wp) :: L1, L2, L3, L4, L5, L6, L7, L8
        INTEGER(i4) :: i

        ! Corner node coordinates
        xi_p = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
        eta_p = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
        zeta_p = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]

        xi2 = xi * xi
        eta2 = eta * eta
        zeta2 = zeta * zeta

        ! Corner nodes (1-8): N_i = (1/8)(1+xi_i*xi)(1+eta_i*eta)(1+zeta_i*zeta)(xi_i*xi+eta_i*eta+zeta_i*zeta-2)
        DO i = 1, 8
            L1 = HALF * (ONE + xi_p(i) * xi)
            L2 = HALF * (ONE + eta_p(i) * eta)
            L3 = HALF * (ONE + zeta_p(i) * zeta)
            N(i) = L1 * L2 * L3 * (xi_p(i) * xi + eta_p(i) * eta + zeta_p(i) * zeta - TWO)
            dN_dxi(i) = QUARTER * xi_p(i) * L2 * L3 * (2.0_wp * xi_p(i) * xi + eta_p(i) * eta + zeta_p(i) * zeta - ONE)
            dN_deta(i) = QUARTER * L1 * eta_p(i) * L3 * (xi_p(i) * xi + 2.0_wp * eta_p(i) * eta + zeta_p(i) * zeta - ONE)
            dN_dzeta(i) = QUARTER * L1 * L2 * zeta_p(i) * (xi_p(i) * xi + eta_p(i) * eta + 2.0_wp * zeta_p(i) * zeta - ONE)
        END DO

        ! Mid-edge nodes (9-20)
        ! Edge 1-2 (xi = -1, eta = -1)
        N(9) = HALF * (ONE - xi2) * HALF * (ONE - eta) * HALF * (ONE - zeta)
        ! Edge 2-3 (xi = 1, eta = -1)
        N(10) = HALF * (ONE + xi) * HALF * (ONE - eta2) * HALF * (ONE - zeta)
        ! Edge 3-4 (xi = 1, eta = 1)
        N(11) = HALF * (ONE - xi2) * HALF * (ONE + eta) * HALF * (ONE - zeta)
        ! Edge 4-1 (xi = -1, eta = 1)
        N(12) = HALF * (ONE - xi) * HALF * (ONE - eta2) * HALF * (ONE - zeta)
        ! Edge 5-6 (xi = -1, eta = -1)
        N(13) = HALF * (ONE - xi2) * HALF * (ONE - eta) * HALF * (ONE + zeta)
        ! Edge 6-7 (xi = 1, eta = -1)
        N(14) = HALF * (ONE + xi) * HALF * (ONE - eta2) * HALF * (ONE + zeta)
        ! Edge 7-8 (xi = 1, eta = 1)
        N(15) = HALF * (ONE - xi2) * HALF * (ONE + eta) * HALF * (ONE + zeta)
        ! Edge 8-5 (xi = -1, eta = 1)
        N(16) = HALF * (ONE - xi) * HALF * (ONE - eta2) * HALF * (ONE + zeta)
        ! Edge 1-5 (xi = -1, zeta = -1)
        N(17) = HALF * (ONE - xi) * HALF * (ONE - eta) * HALF * (ONE - zeta2)
        ! Edge 2-6 (xi = 1, zeta = -1)
        N(18) = HALF * (ONE + xi) * HALF * (ONE - eta) * HALF * (ONE - zeta2)
        ! Edge 3-7 (xi = 1, zeta = 1)
        N(19) = HALF * (ONE + xi) * HALF * (ONE + eta) * HALF * (ONE - zeta2)
        ! Edge 4-8 (xi = -1, zeta = 1)
        N(20) = HALF * (ONE - xi) * HALF * (ONE + eta) * HALF * (ONE - zeta2)

        ! Mid-edge derivatives (d/dxi, d/deta, d/dzeta of N(9:20))
        dN_dxi(9) = -HALF * xi * HALF * (ONE - eta) * HALF * (ONE - zeta)
        dN_deta(9) = HALF * (ONE - xi2) * (-HALF) * HALF * (ONE - zeta)
        dN_dzeta(9) = HALF * (ONE - xi2) * HALF * (ONE - eta) * (-HALF)
        dN_dxi(10) = HALF * HALF * (ONE - eta2) * HALF * (ONE - zeta)
        dN_deta(10) = HALF * (ONE + xi) * (-HALF * 2.0_wp * eta) * HALF * (ONE - zeta)
        dN_dzeta(10) = HALF * (ONE + xi) * HALF * (ONE - eta2) * (-HALF)
        dN_dxi(11) = -HALF * xi * HALF * (ONE + eta) * HALF * (ONE - zeta)
        dN_deta(11) = HALF * (ONE - xi2) * HALF * HALF * (ONE - zeta)
        dN_dzeta(11) = HALF * (ONE - xi2) * HALF * (ONE + eta) * (-HALF)
        dN_dxi(12) = (-HALF) * HALF * (ONE - eta2) * HALF * (ONE - zeta)
        dN_deta(12) = HALF * (ONE - xi) * (-HALF * 2.0_wp * eta) * HALF * (ONE - zeta)
        dN_dzeta(12) = HALF * (ONE - xi) * HALF * (ONE - eta2) * (-HALF)
        dN_dxi(13) = -HALF * xi * HALF * (ONE - eta) * HALF * (ONE + zeta)
        dN_deta(13) = HALF * (ONE - xi2) * (-HALF) * HALF * (ONE + zeta)
        dN_dzeta(13) = HALF * (ONE - xi2) * HALF * (ONE - eta) * HALF
        dN_dxi(14) = HALF * HALF * (ONE - eta2) * HALF * (ONE + zeta)
        dN_deta(14) = HALF * (ONE + xi) * (-HALF * 2.0_wp * eta) * HALF * (ONE + zeta)
        dN_dzeta(14) = HALF * (ONE + xi) * HALF * (ONE - eta2) * HALF
        dN_dxi(15) = -HALF * xi * HALF * (ONE + eta) * HALF * (ONE + zeta)
        dN_deta(15) = HALF * (ONE - xi2) * HALF * HALF * (ONE + zeta)
        dN_dzeta(15) = HALF * (ONE - xi2) * HALF * (ONE + eta) * HALF
        dN_dxi(16) = (-HALF) * HALF * (ONE - eta2) * HALF * (ONE + zeta)
        dN_deta(16) = HALF * (ONE - xi) * (-HALF * 2.0_wp * eta) * HALF * (ONE + zeta)
        dN_dzeta(16) = HALF * (ONE - xi) * HALF * (ONE - eta2) * HALF
        dN_dxi(17) = (-HALF) * HALF * (ONE - eta) * HALF * (ONE - zeta2)
        dN_deta(17) = HALF * (ONE - xi) * (-HALF) * HALF * (ONE - zeta2)
        dN_dzeta(17) = HALF * (ONE - xi) * HALF * (ONE - eta) * (-HALF * 2.0_wp * zeta)
        dN_dxi(18) = HALF * HALF * (ONE - eta) * HALF * (ONE - zeta2)
        dN_deta(18) = HALF * (ONE + xi) * (-HALF) * HALF * (ONE - zeta2)
        dN_dzeta(18) = HALF * (ONE + xi) * HALF * (ONE - eta) * (-HALF * 2.0_wp * zeta)
        dN_dxi(19) = HALF * HALF * (ONE + eta) * HALF * (ONE - zeta2)
        dN_deta(19) = HALF * (ONE + xi) * HALF * HALF * (ONE - zeta2)
        dN_dzeta(19) = HALF * (ONE + xi) * HALF * (ONE + eta) * (-HALF * 2.0_wp * zeta)
        dN_dxi(20) = (-HALF) * HALF * (ONE + eta) * HALF * (ONE - zeta2)
        dN_deta(20) = HALF * (ONE - xi) * HALF * HALF * (ONE - zeta2)
        dN_dzeta(20) = HALF * (ONE - xi) * HALF * (ONE + eta) * (-HALF * 2.0_wp * zeta)
    END SUBROUTINE PH_Elem_SF_Hex_20Node

    SUBROUTINE PH_Elem_SF_Pyramid_Lin(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(5), dN_dxi(5), dN_deta(5), dN_dzeta(5)

        REAL(wp) :: r, s, t

        r = xi
        s = eta
        t = zeta

        ! Base nodes (1-4)
        N(1) = QUARTER * (ONE - r) * (ONE - s) * (ONE - t)
        N(2) = QUARTER * (ONE + r) * (ONE - s) * (ONE - t)
        N(3) = QUARTER * (ONE + r) * (ONE + s) * (ONE - t)
        N(4) = QUARTER * (ONE - r) * (ONE + s) * (ONE - t)

        ! Apex node (5)
        N(5) = t

        ! Derivatives w.r.t. xi
        dN_dxi(1) = -QUARTER * (ONE - s) * (ONE - t)
        dN_dxi(2) = QUARTER * (ONE - s) * (ONE - t)
        dN_dxi(3) = QUARTER * (ONE + s) * (ONE - t)
        dN_dxi(4) = -QUARTER * (ONE + s) * (ONE - t)
        dN_dxi(5) = ZERO

        ! Derivatives w.r.t. eta
        dN_deta(1) = -QUARTER * (ONE - r) * (ONE - t)
        dN_deta(2) = -QUARTER * (ONE + r) * (ONE - t)
        dN_deta(3) = QUARTER * (ONE + r) * (ONE - t)
        dN_deta(4) = QUARTER * (ONE - r) * (ONE - t)
        dN_deta(5) = ZERO

        ! Derivatives w.r.t. zeta
        dN_dzeta(1) = -QUARTER * (ONE - r) * (ONE - s)
        dN_dzeta(2) = -QUARTER * (ONE + r) * (ONE - s)
        dN_dzeta(3) = -QUARTER * (ONE + r) * (ONE + s)
        dN_dzeta(4) = -QUARTER * (ONE - r) * (ONE + s)
        dN_dzeta(5) = ONE

    END SUBROUTINE PH_Elem_SF_Pyramid_Lin

    SUBROUTINE PH_Elem_SF_Shell_8Node(xi, eta, N, dN_dxi, dN_deta)
        REAL(wp), INTENT(IN) :: xi, eta
        REAL(wp), INTENT(OUT) :: N(8), dN_dxi(8), dN_deta(8)

        ! Same as quadratic quadrilateral
        CALL ET_SF_Quad_Quadratic(xi, eta, N, dN_dxi, dN_deta)
    END SUBROUTINE PH_Elem_SF_Shell_8Node

    SUBROUTINE PH_Elem_SF_Truss_Lin(xi, N, dN_dxi)
        REAL(wp), INTENT(IN) :: xi
        REAL(wp), INTENT(OUT) :: N(2), dN_dxi(2)

        N(1) = HALF * (ONE - xi)
        N(2) = HALF * (ONE + xi)

        dN_dxi(1) = -HALF
        dN_dxi(2) = HALF
    END SUBROUTINE PH_Elem_SF_Truss_Lin

    SUBROUTINE PH_Elem_SF_Wedge_Lin(xi, eta, zeta, N, dN_dxi, dN_deta, dN_dzeta)
        REAL(wp), INTENT(IN) :: xi, eta, zeta
        REAL(wp), INTENT(OUT) :: N(6), dN_dxi(6), dN_deta(6), dN_dzeta(6)

        REAL(wp) :: L1, L2, L3

        ! Triangular area coordinates
        L1 = ONE - xi - eta
        L2 = xi
        L3 = eta

        ! Bottom face (zeta = -1)
        N(1) = HALF * L1 * (ONE - zeta)
        N(2) = HALF * L2 * (ONE - zeta)
        N(3) = HALF * L3 * (ONE - zeta)

        ! Top face (zeta = 1)
        N(4) = HALF * L1 * (ONE + zeta)
        N(5) = HALF * L2 * (ONE + zeta)
        N(6) = HALF * L3 * (ONE + zeta)

        ! Derivatives w.r.t. xi
        dN_dxi(1) = -HALF * (ONE - zeta)
        dN_dxi(2) = HALF * (ONE - zeta)
        dN_dxi(3) = ZERO
        dN_dxi(4) = -HALF * (ONE + zeta)
        dN_dxi(5) = HALF * (ONE + zeta)
        dN_dxi(6) = ZERO

        ! Derivatives w.r.t. eta
        dN_deta(1) = -HALF * (ONE - zeta)
        dN_deta(2) = ZERO
        dN_deta(3) = HALF * (ONE - zeta)
        dN_deta(4) = -HALF * (ONE + zeta)
        dN_deta(5) = ZERO
        dN_deta(6) = HALF * (ONE + zeta)

        ! Derivatives w.r.t. zeta
        dN_dzeta(1) = -HALF * L1
        dN_dzeta(2) = -HALF * L2
        dN_dzeta(3) = -HALF * L3
        dN_dzeta(4) = HALF * L1
        dN_dzeta(5) = HALF * L2
        dN_dzeta(6) = HALF * L3

    END SUBROUTINE PH_Elem_SF_Wedge_Lin
END MODULE PH_ElemShapeFunc