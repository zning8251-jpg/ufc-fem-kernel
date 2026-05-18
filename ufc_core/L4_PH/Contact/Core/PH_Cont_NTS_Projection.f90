!===============================================================================
! MODULE: PH_Cont_NTS_Projection
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Proc
! BRIEF:  NTS projection utilities — Newton-Raphson closest-point, normal, gap
!
! Theory: Wriggers (2006) Ch.5; Laursen (2002) Ch.3
! Hot-path: stack-only, zero ALLOCATE
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
MODULE PH_Cont_NTS_Projection
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_ERROR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Cont_NTS_Project_Point
  PUBLIC :: PH_Cont_NTS_Compute_Normal
  PUBLIC :: PH_Cont_NTS_Compute_Gap

  INTEGER(i4), PARAMETER :: MAX_SEG_NODES = 8_i4
  INTEGER(i4), PARAMETER :: MAX_NR_ITER   = 20_i4
  REAL(wp),    PARAMETER :: NR_TOL        = 1.0E-10_wp
  REAL(wp),    PARAMETER :: TINY_VAL      = 1.0E-30_wp

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_Cont_NTS_Project_Point
  !   Newton-Raphson iteration to find natural coordinates (xi,eta)
  !   of the closest point on a master segment to a given slave point.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_NTS_Project_Point(slave_point, master_coords, n_master, &
                                        xi, eta, gap, ierr)
    REAL(wp), INTENT(IN)    :: slave_point(3)
    REAL(wp), INTENT(IN)    :: master_coords(3, MAX_SEG_NODES)
    INTEGER(i4), INTENT(IN) :: n_master          ! 3,4,6 or 8
    REAL(wp), INTENT(INOUT) :: xi, eta           ! IN: initial guess, OUT: converged
    REAL(wp), INTENT(OUT)   :: gap               ! Normal gap (>0 open, <0 penetration)
    INTEGER(i4), INTENT(OUT) :: ierr             ! 0=OK, 1=no convergence, 2=degenerate

    ! --- Local (stack only) ---
    REAL(wp) :: x_m(3), r(3), dxm_dxi(3), dxm_deta(3)
    REAL(wp) :: b(2), A(2,2), det_A, dxi, deta
    REAL(wp) :: N_sh(MAX_SEG_NODES), dN_xi(MAX_SEG_NODES), dN_eta(MAX_SEG_NODES)
    REAL(wp) :: normal(3), cross(3), norm_c
    INTEGER(i4) :: iter, I

    ierr = 0

    ! --- Newton-Raphson loop ---
    DO iter = 1, MAX_NR_ITER

      ! 1. Shape functions
      CALL ShapeFunc2D(xi, eta, n_master, N_sh, dN_xi, dN_eta)

      ! 2. Interpolate master surface & tangent vectors
      x_m(:) = 0.0_wp;  dxm_dxi(:) = 0.0_wp;  dxm_deta(:) = 0.0_wp
      DO I = 1, n_master
        x_m(:)      = x_m(:)      + N_sh(I)   * master_coords(:, I)
        dxm_dxi(:)  = dxm_dxi(:)  + dN_xi(I)  * master_coords(:, I)
        dxm_deta(:) = dxm_deta(:) + dN_eta(I) * master_coords(:, I)
      END DO

      ! 3. Residual r = slave - x_m
      r(:) = slave_point(:) - x_m(:)

      ! 4. Orthogonality residual b
      b(1) = DOT_PRODUCT(r, dxm_dxi)
      b(2) = DOT_PRODUCT(r, dxm_deta)

      ! 5. 2x2 Jacobian (negative metric tensor, approx.)
      A(1,1) = -DOT_PRODUCT(dxm_dxi,  dxm_dxi)
      A(1,2) = -DOT_PRODUCT(dxm_dxi,  dxm_deta)
      A(2,1) = A(1,2)
      A(2,2) = -DOT_PRODUCT(dxm_deta, dxm_deta)

      ! 6. 2x2 solve via Cramer
      det_A = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      IF (ABS(det_A) < TINY_VAL) THEN
        ierr = 2  ! degenerate face
        gap = 0.0_wp
        RETURN
      END IF

      dxi  = -(b(1)*A(2,2) - b(2)*A(1,2)) / det_A
      deta = -(A(1,1)*b(2) - A(2,1)*b(1)) / det_A

      ! 7. Update
      xi  = xi  + dxi
      eta = eta + deta

      ! 8. Convergence check
      IF (SQRT(dxi**2 + deta**2) < NR_TOL) THEN
        ! Converged — compute gap
        CALL ShapeFunc2D(xi, eta, n_master, N_sh, dN_xi, dN_eta)
        x_m(:) = 0.0_wp;  dxm_dxi(:) = 0.0_wp;  dxm_deta(:) = 0.0_wp
        DO I = 1, n_master
          x_m(:)      = x_m(:)      + N_sh(I)   * master_coords(:, I)
          dxm_dxi(:)  = dxm_dxi(:)  + dN_xi(I)  * master_coords(:, I)
          dxm_deta(:) = dxm_deta(:) + dN_eta(I) * master_coords(:, I)
        END DO

        ! Normal via cross product
        cross(1) = dxm_dxi(2)*dxm_deta(3) - dxm_dxi(3)*dxm_deta(2)
        cross(2) = dxm_dxi(3)*dxm_deta(1) - dxm_dxi(1)*dxm_deta(3)
        cross(3) = dxm_dxi(1)*dxm_deta(2) - dxm_dxi(2)*dxm_deta(1)
        norm_c = SQRT(DOT_PRODUCT(cross, cross))
        IF (norm_c < TINY_VAL) THEN
          ierr = 2
          gap = 0.0_wp
          RETURN
        END IF
        normal(:) = cross(:) / norm_c

        r(:) = slave_point(:) - x_m(:)
        gap = DOT_PRODUCT(r, normal)
        RETURN
      END IF
    END DO

    ! Did not converge
    ierr = 1
    gap = 0.0_wp

  END SUBROUTINE PH_Cont_NTS_Project_Point

  !---------------------------------------------------------------------------
  ! PH_Cont_NTS_Compute_Normal
  !   Compute outward unit normal on master segment at (xi,eta).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_NTS_Compute_Normal(master_coords, n_master, xi, eta, &
                                         normal, ierr)
    REAL(wp), INTENT(IN)    :: master_coords(3, MAX_SEG_NODES)
    INTEGER(i4), INTENT(IN) :: n_master
    REAL(wp), INTENT(IN)    :: xi, eta
    REAL(wp), INTENT(OUT)   :: normal(3)
    INTEGER(i4), INTENT(OUT) :: ierr

    REAL(wp) :: dxm_dxi(3), dxm_deta(3), cross(3), norm_c
    REAL(wp) :: N_sh(MAX_SEG_NODES), dN_xi(MAX_SEG_NODES), dN_eta(MAX_SEG_NODES)
    INTEGER(i4) :: I

    ierr = 0

    CALL ShapeFunc2D(xi, eta, n_master, N_sh, dN_xi, dN_eta)

    dxm_dxi(:) = 0.0_wp
    dxm_deta(:) = 0.0_wp
    DO I = 1, n_master
      dxm_dxi(:)  = dxm_dxi(:)  + dN_xi(I)  * master_coords(:, I)
      dxm_deta(:) = dxm_deta(:) + dN_eta(I) * master_coords(:, I)
    END DO

    ! Cross product n = a_xi x a_eta
    cross(1) = dxm_dxi(2)*dxm_deta(3) - dxm_dxi(3)*dxm_deta(2)
    cross(2) = dxm_dxi(3)*dxm_deta(1) - dxm_dxi(1)*dxm_deta(3)
    cross(3) = dxm_dxi(1)*dxm_deta(2) - dxm_dxi(2)*dxm_deta(1)
    norm_c = SQRT(DOT_PRODUCT(cross, cross))

    IF (norm_c < TINY_VAL) THEN
      normal(:) = 0.0_wp
      ierr = 2
      RETURN
    END IF
    normal(:) = cross(:) / norm_c

  END SUBROUTINE PH_Cont_NTS_Compute_Normal

  !---------------------------------------------------------------------------
  ! PH_Cont_NTS_Compute_Gap
  !   Normal gap: g_n = (slave - projection) . normal
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_NTS_Compute_Gap(slave_point, projection, normal, gap_n, ierr)
    REAL(wp), INTENT(IN)  :: slave_point(3)
    REAL(wp), INTENT(IN)  :: projection(3)
    REAL(wp), INTENT(IN)  :: normal(3)
    REAL(wp), INTENT(OUT) :: gap_n
    INTEGER(i4), INTENT(OUT) :: ierr

    REAL(wp) :: r(3)

    ierr = 0
    r(:) = slave_point(:) - projection(:)
    gap_n = DOT_PRODUCT(r, normal)

  END SUBROUTINE PH_Cont_NTS_Compute_Gap

  !==========================================================================
  ! PRIVATE: Shape function evaluator (QUAD4/TRIA3/QUAD8/TRIA6)
  !==========================================================================
  SUBROUTINE ShapeFunc2D(xi, eta, n_nodes, N, dN_dxi, dN_deta)
    REAL(wp), INTENT(IN)    :: xi, eta
    INTEGER(i4), INTENT(IN) :: n_nodes
    REAL(wp), INTENT(OUT)   :: N(MAX_SEG_NODES)
    REAL(wp), INTENT(OUT)   :: dN_dxi(MAX_SEG_NODES)
    REAL(wp), INTENT(OUT)   :: dN_deta(MAX_SEG_NODES)

    N(:) = 0.0_wp;  dN_dxi(:) = 0.0_wp;  dN_deta(:) = 0.0_wp

    SELECT CASE (n_nodes)
    CASE (4_i4)
      ! QUAD4 bilinear
      N(1) = 0.25_wp*(1.0_wp - xi)*(1.0_wp - eta)
      N(2) = 0.25_wp*(1.0_wp + xi)*(1.0_wp - eta)
      N(3) = 0.25_wp*(1.0_wp + xi)*(1.0_wp + eta)
      N(4) = 0.25_wp*(1.0_wp - xi)*(1.0_wp + eta)
      dN_dxi(1) = -0.25_wp*(1.0_wp - eta)
      dN_dxi(2) =  0.25_wp*(1.0_wp - eta)
      dN_dxi(3) =  0.25_wp*(1.0_wp + eta)
      dN_dxi(4) = -0.25_wp*(1.0_wp + eta)
      dN_deta(1) = -0.25_wp*(1.0_wp - xi)
      dN_deta(2) = -0.25_wp*(1.0_wp + xi)
      dN_deta(3) =  0.25_wp*(1.0_wp + xi)
      dN_deta(4) =  0.25_wp*(1.0_wp - xi)

    CASE (3_i4)
      ! TRIA3
      N(1) = 1.0_wp - xi - eta;  N(2) = xi;  N(3) = eta
      dN_dxi(1) = -1.0_wp;  dN_dxi(2) = 1.0_wp;  dN_dxi(3) = 0.0_wp
      dN_deta(1) = -1.0_wp; dN_deta(2) = 0.0_wp;  dN_deta(3) = 1.0_wp

    CASE (8_i4)
      ! QUAD8 serendipity
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
      ! TRIA6 quadratic
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
      N(1:n_nodes) = 0.0_wp
    END SELECT
  END SUBROUTINE ShapeFunc2D

END MODULE PH_Cont_NTS_Projection
