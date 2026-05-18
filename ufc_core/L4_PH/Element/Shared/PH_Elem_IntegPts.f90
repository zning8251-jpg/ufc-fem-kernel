!===============================================================================
! MODULE: PH_Elem_IntegPts
! LAYER:  L4_PH
! DOMAIN: Element/Shared
! ROLE:   Proc
! BRIEF:  Gauss / quadrature points and weights (Shared Tool)
!===============================================================================
MODULE PH_Elem_IntegPts
!> Status: PROGRESSIVE (partial implementation, see Arg TYPE compliance mode)
! > Theory: Internal UFC architecture spec §1 (see UFC_ .md) | Last verified: 2026-02-14
    USE IF_Base_Def, ONLY: ZERO, ONE, HALF
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID
    USE IF_Prec_Core, ONLY: wp, i4, i8
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! PUBLIC INTERFACES
    ! ==========================================================================
    PUBLIC :: PH_Elem_IP_Gauss1D
    PUBLIC :: PH_Elem_IP_Gauss2D_Quad
    PUBLIC :: PH_Elem_IP_Gauss2D_Tri
    PUBLIC :: PH_Elem_IP_Gauss3D_Hex
    PUBLIC :: PH_Elem_IP_Gauss3D_Tet
    PUBLIC :: PH_Elem_IP_GetNumPoints

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

    SUBROUTINE ET_IP_Gauss1D(n_points, xi, weights, status)
        INTEGER(i4), INTENT(IN) :: n_points
        REAL(wp), INTENT(OUT) :: xi(:), weights(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        SELECT CASE (n_points)
        CASE (1)
            ! 1-point Gauss
            xi(1) = ZERO
            weights(1) = 2.0_wp

        CASE (2)
            ! 2-point Gauss
            xi(1) = -ONE / SQRT(3.0_wp)
            xi(2) = ONE / SQRT(3.0_wp)
            weights(1) = ONE
            weights(2) = ONE

        CASE (3)
            ! 3-point Gauss
            xi(1) = -SQRT(3.0_wp / 5.0_wp)
            xi(2) = ZERO
            xi(3) = SQRT(3.0_wp / 5.0_wp)
            weights(1) = 5.0_wp / 9.0_wp
            weights(2) = 8.0_wp / 9.0_wp
            weights(3) = 5.0_wp / 9.0_wp

        CASE (4)
            ! 4-point Gauss
            REAL(wp), PARAMETER :: a = SQRT((3.0_wp - 2.0_wp * SQRT(6.0_wp / 5.0_wp)) / 7.0_wp)
            REAL(wp), PARAMETER :: b = SQRT((3.0_wp + 2.0_wp * SQRT(6.0_wp / 5.0_wp)) / 7.0_wp)
            REAL(wp), PARAMETER :: w1 = (18.0_wp + SQRT(30.0_wp)) / 36.0_wp
            REAL(wp), PARAMETER :: w2 = (18.0_wp - SQRT(30.0_wp)) / 36.0_wp

            xi(1) = -b
            xi(2) = -a
            xi(3) = a
            xi(4) = b
            weights(1) = w2
            weights(2) = w1
            weights(3) = w1
            weights(4) = w2

        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = 'PH_Elem_IP_Gauss1D: Unsupported number of points'
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_IP_Gauss1D

    SUBROUTINE ET_IP_Gauss2D_Quad(n_points_per_dim, xi, eta, weights, status)
        INTEGER(i4), INTENT(IN) :: n_points_per_dim
        REAL(wp), INTENT(OUT) :: xi(:), eta(:), weights(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp), ALLOCATABLE :: xi_1d(:), weights_1d(:)
        INTEGER(i4) :: i, j, idx, n_points

        CALL init_error_status(status)

        n_points = n_points_per_dim * n_points_per_dim
        IF (SIZE(xi) < n_points .OR. SIZE(eta) < n_points .OR. SIZE(weights) < n_points) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_IP_Gauss2D_Quad: Insufficient array size'
            RETURN
        END IF

        ALLOCATE(xi_1d(n_points_per_dim), weights_1d(n_points_per_dim))
        CALL ET_IP_Gauss1D(n_points_per_dim, xi_1d, weights_1d, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Tensor product
        idx = 0
        DO i = 1, n_points_per_dim
            DO j = 1, n_points_per_dim
                idx = idx + 1
                xi(idx) = xi_1d(i)
                eta(idx) = xi_1d(j)
                weights(idx) = weights_1d(i) * weights_1d(j)
            END DO
        END DO

        DEALLOCATE(xi_1d, weights_1d)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_IP_Gauss2D_Quad

    SUBROUTINE ET_IP_Gauss2D_Tri(order, xi, eta, weights, status)
        INTEGER(i4), INTENT(IN) :: order
        REAL(wp), INTENT(OUT) :: xi(:), eta(:), weights(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n_points

        CALL init_error_status(status)

        SELECT CASE (order)
        CASE (1)
            ! 1-point integration
            n_points = 1
            IF (SIZE(xi) < n_points) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'ET_IP_Gauss2D_Tri: Insufficient array size'
                RETURN
            END IF
            xi(1) = ONE / 3.0_wp
            eta(1) = ONE / 3.0_wp
            weights(1) = HALF

        CASE (2)
            ! 3-point integration
            n_points = 3
            IF (SIZE(xi) < n_points) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'ET_IP_Gauss2D_Tri: Insufficient array size'
                RETURN
            END IF
            xi(1) = HALF
            eta(1) = HALF
            weights(1) = ONE / 6.0_wp

            xi(2) = ZERO
            eta(2) = HALF
            weights(2) = ONE / 6.0_wp

            xi(3) = HALF
            eta(3) = ZERO
            weights(3) = ONE / 6.0_wp

        CASE (3)
            ! 4-point integration
            n_points = 4
            IF (SIZE(xi) < n_points) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'ET_IP_Gauss2D_Tri: Insufficient array size'
                RETURN
            END IF
            ! Simplified 4-point rule
            xi(1) = ONE / 3.0_wp
            eta(1) = ONE / 3.0_wp
            weights(1) = -27.0_wp / 96.0_wp

            xi(2) = 0.6_wp
            eta(2) = 0.2_wp
            weights(2) = 25.0_wp / 96.0_wp

            xi(3) = 0.2_wp
            eta(3) = 0.6_wp
            weights(3) = 25.0_wp / 96.0_wp

            xi(4) = 0.2_wp
            eta(4) = 0.2_wp
            weights(4) = 25.0_wp / 96.0_wp

        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_IP_Gauss2D_Tri: Unsupported order'
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_IP_Gauss2D_Tri

    SUBROUTINE ET_IP_Gauss3D_Hex(n_points_per_dim, xi, eta, zeta, weights, status)
        INTEGER(i4), INTENT(IN) :: n_points_per_dim
        REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), weights(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        REAL(wp), ALLOCATABLE :: xi_1d(:), weights_1d(:)
        INTEGER(i4) :: i, j, k, idx, n_points

        CALL init_error_status(status)

        n_points = n_points_per_dim * n_points_per_dim * n_points_per_dim
        IF (SIZE(xi) < n_points) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_IP_Gauss3D_Hex: Insufficient array size'
            RETURN
        END IF

        ALLOCATE(xi_1d(n_points_per_dim), weights_1d(n_points_per_dim))
        CALL ET_IP_Gauss1D(n_points_per_dim, xi_1d, weights_1d, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Tensor product
        idx = 0
        DO i = 1, n_points_per_dim
            DO j = 1, n_points_per_dim
                DO k = 1, n_points_per_dim
                    idx = idx + 1
                    xi(idx) = xi_1d(i)
                    eta(idx) = xi_1d(j)
                    zeta(idx) = xi_1d(k)
                    weights(idx) = weights_1d(i) * weights_1d(j) * weights_1d(k)
                END DO
            END DO
        END DO

        DEALLOCATE(xi_1d, weights_1d)
        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_IP_Gauss3D_Hex

    SUBROUTINE ET_IP_Gauss3D_Tet(order, xi, eta, zeta, weights, status)
        INTEGER(i4), INTENT(IN) :: order
        REAL(wp), INTENT(OUT) :: xi(:), eta(:), zeta(:), weights(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n_points

        CALL init_error_status(status)

        SELECT CASE (order)
        CASE (1)
            ! 1-point integration
            n_points = 1
            IF (SIZE(xi) < n_points) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'ET_IP_Gauss3D_Tet: Insufficient array size'
                RETURN
            END IF
            xi(1) = 0.25_wp
            eta(1) = 0.25_wp
            zeta(1) = 0.25_wp
            weights(1) = ONE / 6.0_wp

        CASE (2)
            ! 4-point integration
            n_points = 4
            IF (SIZE(xi) < n_points) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = 'ET_IP_Gauss3D_Tet: Insufficient array size'
                RETURN
            END IF
            REAL(wp), PARAMETER :: a = 0.5854101966249685_wp
            REAL(wp), PARAMETER :: b = 0.1381966011250105_wp
            REAL(wp), PARAMETER :: w = ONE / 24.0_wp

            xi(1) = a
            eta(1) = b
            zeta(1) = b
            weights(1) = w

            xi(2) = b
            eta(2) = a
            zeta(2) = b
            weights(2) = w

            xi(3) = b
            eta(3) = b
            zeta(3) = a
            weights(3) = w

            xi(4) = b
            eta(4) = b
            zeta(4) = b
            weights(4) = w

        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = 'ET_IP_Gauss3D_Tet: Unsupported order'
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE ET_IP_Gauss3D_Tet

    FUNCTION PH_Elem_IP_GetNumPoints(order) RESULT(n_points)
        INTEGER(i4), INTENT(IN) :: order
        INTEGER(i4) :: n_points

        ! Full integration: order points
        ! Reduced integration: order/2 points (rounded up)
        n_points = order
    END FUNCTION PH_Elem_IP_GetNumPoints
END MODULE PH_Elem_IntegPts