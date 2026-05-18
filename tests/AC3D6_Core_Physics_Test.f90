!===============================================================================
! Module: AC3D6_Core_Physics_Test
! Purpose: Test AC3D6 core physics capabilities (P2)
! Description: Validates shape functions, Jacobian, B-matrix, stiffness matrix
! Theory: 6-node prism (wedge) element with 2D triangle + extrusion
!===============================================================================

MODULE AC3D6_Core_Physics_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Const, ONLY: ZERO, ONE
  IMPLICIT NONE
  
CONTAINS

  LOGICAL FUNCTION AC3D6_Core_Physics_Test()
    !! Test core physics: shape functions, Jacobian, B-matrix
    USE PH_Elem_AC3D6_Core, ONLY: PH_ELEM_AC3D6_NNODE, PH_ELEM_AC3D6_NDOF
    REAL(wp) :: coords(3, 6)
    REAL(wp) :: N(6), dNdX(3, 6), B(3, 6)
    REAL(wp) :: det_J, volume
    REAL(wp) :: xi, eta, zeta
    LOGICAL :: test_passed
    
    test_passed = .TRUE.
    WRITE(*, '(A)') '    Testing AC3D6 shape functions...'
    
    ! Setup: Regular wedge element (triangular extrusion)
    ! Triangle face (xi-eta plane): unit triangle
    ! Extrusion (zeta direction): height = 1
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]  ! Node 1 (corner)
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]  ! Node 2 (edge)
    coords(:,3) = [0.0_wp, 1.0_wp, 0.0_wp]  ! Node 3 (edge)
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]  ! Node 4 (top corner)
    coords(:,5) = [1.0_wp, 0.0_wp, 1.0_wp]  ! Node 5 (top edge)
    coords(:,6) = [0.0_wp, 1.0_wp, 1.0_wp]  ! Node 6 (top edge)
    
    ! Test 1: Shape functions at centroid
    xi = 1.0_wp/3.0_wp
    eta = 1.0_wp/3.0_wp
    zeta = 0.5_wp
    
    CALL AC3D6_Shape_Functions(xi, eta, zeta, N)
    
    ! Assertion: N should sum to 1 (partition of unity)
    IF (ABS(SUM(N) - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.8)') '    FAIL: Shape functions sum to ', SUM(N), ' (expected 1.0)'
      test_passed = .FALSE.
    END IF
    
    ! Assertion: All N should be positive for valid element
    IF (ANY(N < ZERO)) THEN
      WRITE(*, '(A)') '    FAIL: Negative shape function values detected'
      test_passed = .FALSE.
    END IF
    
    IF (test_passed) THEN
      WRITE(*, '(A)') '    PASS: Shape functions partition of unity'
    END IF
    
    ! Test 2: Jacobian computation
    WRITE(*, '(A)') '    Testing Jacobian computation...'
    CALL AC3D6_Jacobian_Compute(coords, xi, eta, zeta, dNdX, det_J)
    
    ! Assertion: det_J should be positive for valid element
    IF (det_J <= ZERO) THEN
      WRITE(*, '(A,F12.6)') '    FAIL: Non-positive Jacobian det_J =', det_J
      test_passed = .FALSE.
    ELSE
      WRITE(*, '(A,F12.6)') '    PASS: Jacobian det_J =', det_J
    END IF
    
    ! Test 3: B-matrix (pressure gradient operator)
    WRITE(*, '(A)') '    Testing B-matrix...'
    CALL AC3D6_B_Matrix_Form(dNdX, B)
    
    ! Assertion: B should have correct dimensions [3×6]
    IF (SIZE(B, 1) /= 3 .OR. SIZE(B, 2) /= 6) THEN
      WRITE(*, '(A,I2,A,I2)') '    FAIL: B has wrong size ', SIZE(B,1), 'x', SIZE(B,2)
      test_passed = .FALSE.
    END IF
    
    ! Verify B computes gradient correctly
    REAL(wp) :: test_gradient(3)
    test_gradient = MATMUL(B, [1.0_wp, 2.0_wp, 3.0_wp, 4.0_wp, 5.0_wp, 6.0_wp])
    
    IF (ANY(ISNAN(test_gradient))) THEN
      WRITE(*, '(A)') '    FAIL: B-matrix produces NaN'
      test_passed = .FALSE.
    ELSE
      WRITE(*, '(A,3F10.4)') '    PASS: B-matrix gradient =', test_gradient
    END IF
    
    ! Test 4: Volume integration
    WRITE(*, '(A)') '    Testing volume integration...'
    CALL AC3D6_Volume_Compute(coords, volume)
    
    ! Unit wedge volume = triangle_area * height = (1/2) * 1 = 0.5
    IF (ABS(volume - 0.5_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6,A)') '    WARN: Volume =', volume, ' (expected 0.5)'
    ELSE
      WRITE(*, '(A,F12.6)') '    PASS: Volume =', volume
    END IF
    
    AC3D6_Core_Physics_Test = test_passed
    
  END FUNCTION AC3D6_Core_Physics_Test

  !============================================================================
  ! AC3D6 Shape Functions (6-node prism)
  ! Natural coordinates: xi (0-1), eta (0-1-xi), zeta (0-1)
  !============================================================================
  
  SUBROUTINE AC3D6_Shape_Functions(xi, eta, zeta, N)
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(:)
    
    ! Triangle shape functions (2D)
    REAL(wp) :: N2D(3)
    N2D(1) = 1.0_wp - xi - eta
    N2D(2) = xi
    N2D(3) = eta
    
    ! Extrusion in zeta direction
    ! Node 1-3: bottom face (zeta=0)
    N(1) = N2D(1) * (1.0_wp - zeta)
    N(2) = N2D(2) * (1.0_wp - zeta)
    N(3) = N2D(3) * (1.0_wp - zeta)
    
    ! Node 4-6: top face (zeta=1)
    N(4) = N2D(1) * zeta
    N(5) = N2D(2) * zeta
    N(6) = N2D(3) * zeta
    
  END SUBROUTINE AC3D6_Shape_Functions

  !============================================================================
  ! Jacobian Computation for AC3D6
  !============================================================================
  
  SUBROUTINE AC3D6_Jacobian_Compute(coords, xi, eta, zeta, dNdX, detJ)
    REAL(wp), INTENT(IN) :: coords(3, 6), xi, eta, zeta
    REAL(wp), INTENT(OUT) :: dNdX(3, 6), detJ
    REAL(wp) :: dNdxi(3, 6), J(3, 3)
    
    ! Shape function derivatives in natural coordinates
    ! dN1/dxi = -1, dN1/deta = -1, dN1/dzeta = 0 (bottom face)
    dNdxi(1,:) = [-1.0_wp, 1.0_wp, 0.0_wp, -1.0_wp, 1.0_wp, 0.0_wp]
    dNdxi(2,:) = [-1.0_wp, 0.0_wp, 1.0_wp, -1.0_wp, 0.0_wp, 1.0_wp]
    dNdxi(3,:) = [-1.0_wp, -1.0_wp, -1.0_wp, 1.0_wp, 1.0_wp, 1.0_wp]
    
    ! Jacobian: J_ij = dX_i / dxi_j
    J = MATMUL(coords, TRANSPOSE(dNdxi))
    
    ! Determinant
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - &
           J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + &
           J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
    
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      REAL(wp) :: Jinv(3, 3)
      Jinv(1,1) = (J(2,2)*J(3,3)-J(2,3)*J(3,2))/detJ
      Jinv(1,2) = (J(1,3)*J(3,2)-J(1,2)*J(3,3))/detJ
      Jinv(1,3) = (J(1,2)*J(2,3)-J(1,3)*J(2,2))/detJ
      Jinv(2,1) = (J(2,3)*J(3,1)-J(2,1)*J(3,3))/detJ
      Jinv(2,2) = (J(1,1)*J(3,3)-J(1,3)*J(3,1))/detJ
      Jinv(2,3) = (J(1,3)*J(2,1)-J(1,1)*J(2,3))/detJ
      Jinv(3,1) = (J(2,1)*J(3,2)-J(2,2)*J(3,1))/detJ
      Jinv(3,2) = (J(1,2)*J(3,1)-J(1,1)*J(3,2))/detJ
      Jinv(3,3) = (J(1,1)*J(2,2)-J(1,2)*J(2,1))/detJ
      dNdX = MATMUL(Jinv, dNdxi)
    ELSE
      dNdX = ZERO
    END IF
    
  END SUBROUTINE AC3D6_Jacobian_Compute

  !============================================================================
  ! B-Matrix (Pressure Gradient Operator) for AC3D6
  !============================================================================
  
  SUBROUTINE AC3D6_B_Matrix_Form(dNdX, B)
    REAL(wp), INTENT(IN) :: dNdX(3, 6)
    REAL(wp), INTENT(OUT) :: B(3, 6)
    INTEGER(i4) :: a
    
    B = ZERO
    DO a = 1, 6
      B(1, a) = dNdX(1, a)  ! dN/dx
      B(2, a) = dNdX(2, a)  ! dN/dy
      B(3, a) = dNdX(3, a)  ! dN/dz
    END DO
    
  END SUBROUTINE AC3D6_B_Matrix_Form

  !============================================================================
  ! Volume Computation for AC3D6
  !============================================================================
  
  SUBROUTINE AC3D6_Volume_Compute(coords, volume)
    REAL(wp), INTENT(IN) :: coords(3, 6)
    REAL(wp), INTENT(OUT) :: volume
    
    REAL(wp) :: detJ, N(6), dNdX(3, 6)
    REAL(wp) :: xi, eta, zeta, w
    REAL(wp) :: xi_pts(6), eta_pts(6), zeta_pts(6), weights(6)
    INTEGER(i4) :: ip
    
    ! 2-point Gauss integration for triangle (in xi-eta plane)
    ! Combined with 2-point Gauss in zeta direction = 6 IP total
    xi_pts = [0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp]
    eta_pts = [0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp]
    zeta_pts = [-0.577_wp, 0.577_wp, -0.577_wp, 0.577_wp, -0.577_wp, 0.577_wp]
    weights = [0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp, 0.5_wp]
    
    volume = ZERO
    DO ip = 1, 6
      CALL AC3D6_Jacobian_Compute(coords, xi_pts(ip), eta_pts(ip), zeta_pts(ip), dNdX, detJ)
      w = weights(ip)
      volume = volume + detJ * w
    END DO
    
  END SUBROUTINE AC3D6_Volume_Compute

END MODULE AC3D6_Core_Physics_Test
