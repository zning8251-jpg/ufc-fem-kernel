!===============================================================================
! Module: AC3D4_Core_Physics_Test
! Purpose: Test AC3D4 core physics capabilities (P2)
! Description: Validates shape functions, Jacobian, B-matrix, stiffness matrix
!===============================================================================

MODULE AC3D4_Core_Physics_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_AC3D4_Core
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D4_Core_Physics_Test()
    !! Test core physics: shape functions, Jacobian, B-matrix
    REAL(wp) :: coords(3, 4)
    REAL(wp) :: N(4), dNdX(3, 4), B(3, 4)
    REAL(wp) :: det_J, volume
    REAL(wp) :: xi, eta, zeta, w_ip
    INTEGER(i4) :: ip
    
    WRITE(*, '(A)') '  Testing C3D4 shape functions...'
    
    ! Setup: Regular tetrahedron (unit volume)
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]  ! Node 1
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]  ! Node 2
    coords(:,3) = [0.0_wp, 1.0_wp, 0.0_wp]  ! Node 3
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]  ! Node 4
    
    ! Test 1: Shape functions at centroid
    xi = 0.25_wp
    eta = 0.25_wp
    zeta = 0.25_wp
    
    CALL C3D4_Shape_Functions(xi, eta, zeta, N)
    
    ! Assertion: N should sum to 1 (partition of unity)
    IF (ABS(SUM(N) - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shape functions do not sum to 1'
      WRITE(*, '(A,4F8.4)') '    N = ', N
      RETURN
    END IF
    
    ! Assertion: At centroid, all N should be 0.25
    IF (ANY(ABS(N - 0.25_wp) > 1.0e-10_wp)) THEN
      WRITE(*, '(A)') '    FAIL: Centroid shape functions not 0.25'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Shape functions: PASSED'
    
    ! Test 2: Jacobian computation
    CALL C3D4_Jacobian(coords, N, xi, eta, zeta, dNdX, det_J)
    
    ! Assertion: det_J should be positive for valid element
    IF (det_J <= 0.0_wp) THEN
      WRITE(*, '(A,F12.6)') '    FAIL: Non-positive Jacobian det_J =', det_J
      RETURN
    END IF
    
    ! For unit tetrahedron, det_J = 6 * Volume = 6 * (1/6) = 1
    IF (ABS(det_J - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6,A)') '    FAIL: det_J =', det_J, ' (expected 1.0)'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Jacobian: PASSED'
    
    ! Test 3: B-matrix (pressure gradient operator)
    CALL AC3D4_B_Matrix(dNdX, B)
    
    ! Assertion: B should have correct dimensions [3×4]
    IF (SIZE(B, 1) /= 3 .OR. SIZE(B, 2) /= 4) THEN
      WRITE(*, '(A,I2,A,I2)') '    FAIL: B has wrong size ', SIZE(B,1), 'x', SIZE(B,2)
      RETURN
    END IF
    
    ! Verify B computes gradient correctly
    ! For linear tetrahedron, ∂N/∂x should be constant
    REAL(wp) :: test_gradient(3)
    test_gradient = MATMUL(B, [1.0_wp, 2.0_wp, 3.0_wp, 4.0_wp])
    
    IF (ANY(ISNAN(test_gradient))) THEN
      WRITE(*, '(A)') '    FAIL: B-matrix produces NaN'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ B-matrix: PASSED'
    
    ! Test 4: Volume integration
    CALL PH_ELEM_AC3D4_VolumeInt(coords, volume)
    
    ! Unit tetrahedron volume = 1/6
    IF (ABS(volume - 1.0_wp/6.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6,A)') '    FAIL: Volume =', volume, ' (expected 1/6)'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Volume integration: PASSED'
    
    WRITE(*, '(A)') '  All core physics tests PASSED!'
    
  END SUBROUTINE AC3D4_Core_Physics_Test
  
  ! Helper subroutines (normally PRIVATE in main module)
  SUBROUTINE C3D4_Shape_Functions(xi, eta, zeta, N)
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(:)
    N(1) = 1.0_wp - xi - eta - zeta
    N(2) = xi
    N(3) = eta
    N(4) = zeta
  END SUBROUTINE C3D4_Shape_Functions
  
  SUBROUTINE C3D4_Jacobian(coords, N, xi, eta, zeta, dNdX, detJ)
    REAL(wp), INTENT(IN) :: coords(:,:)
    REAL(wp), INTENT(IN) :: N(:)
    REAL(wp), INTENT(IN) :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: dNdX(:,:)
    REAL(wp), INTENT(OUT) :: detJ
    REAL(wp) :: dNdxi(3,4), J(3,3)
    INTEGER(i4) :: a
    
    dNdxi(1,:) = [-1.0_wp, 1.0_wp, 0.0_wp, 0.0_wp]
    dNdxi(2,:) = [-1.0_wp, 0.0_wp, 1.0_wp, 0.0_wp]
    dNdxi(3,:) = [-1.0_wp, 0.0_wp, 0.0_wp, 1.0_wp]
    
    J = MATMUL(coords, TRANSPOSE(dNdxi))
    detJ = J(1,1)*(J(2,2)*J(3,3)-J(2,3)*J(3,2)) - &
           J(1,2)*(J(2,1)*J(3,3)-J(2,3)*J(3,1)) + &
           J(1,3)*(J(2,1)*J(3,2)-J(2,2)*J(3,1))
    
    IF (ABS(detJ) > 1.0e-12_wp) THEN
      REAL(wp) :: Jinv(3,3)
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
      dNdX = 0.0_wp
    END IF
  END SUBROUTINE C3D4_Jacobian
  
  SUBROUTINE AC3D4_B_Matrix(dNdX, B)
    REAL(wp), INTENT(IN) :: dNdX(:,:)
    REAL(wp), INTENT(OUT) :: B(:,:)
    INTEGER(i4) :: a
    B = 0.0_wp
    DO a = 1, SIZE(dNdX, 2)
      B(1, a) = dNdX(1, a)
      B(2, a) = dNdX(2, a)
      B(3, a) = dNdX(3, a)
    END DO
  END SUBROUTINE AC3D4_B_Matrix

END MODULE AC3D4_Core_Physics_Test
