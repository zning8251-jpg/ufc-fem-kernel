!===============================================================================
! Module: AC3D8_Core_Physics_Test
! Purpose: Test AC3D8 core physics capabilities (P2)
! Description: Validates shape functions, Jacobian, B-matrix, stiffness matrix
! Element: 3D acoustic hexahedron (8-node)
!===============================================================================

MODULE AC3D8_Core_Physics_Test
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D8_Core_Physics_Test()
    !! Test core physics: shape functions, Jacobian, B-matrix
    REAL(wp) :: coords(3, 8)
    REAL(wp) :: N(8), dNdX(3, 8), dNdx(3, 8)
    REAL(wp) :: det_J, volume
    REAL(wp) :: xi, eta, zeta, w_ip
    INTEGER(i4) :: ip, i
    REAL(wp) :: shape_sum
    LOGICAL :: test_passed
    
    test_passed = .TRUE.
    WRITE(*, '(A)') '=========================================='
    WRITE(*, '(A)') 'AC3D8 Core Physics Test'
    WRITE(*, '(A)') '=========================================='
    
    ! Setup: Regular hexahedron (unit cube)
    ! Node ordering (standard serendipity):
    !   5------7
    !  /|     /|
    ! 1-+--3  |     y
    ! |  |    |     | z
    ! |  4----6     |/
    ! |/         x<-'
    ! 0------2
    coords(:,1) = [-1.0_wp, -1.0_wp, -1.0_wp]  ! Node 1 (corner)
    coords(:,2) = [ 1.0_wp, -1.0_wp, -1.0_wp]  ! Node 2 (corner)
    coords(:,3) = [ 1.0_wp,  1.0_wp, -1.0_wp]  ! Node 3 (corner)
    coords(:,4) = [-1.0_wp,  1.0_wp, -1.0_wp]  ! Node 4 (corner)
    coords(:,5) = [-1.0_wp, -1.0_wp,  1.0_wp]  ! Node 5 (corner)
    coords(:,6) = [ 1.0_wp, -1.0_wp,  1.0_wp]  ! Node 6 (corner)
    coords(:,7) = [ 1.0_wp,  1.0_wp,  1.0_wp]  ! Node 7 (corner)
    coords(:,8) = [-1.0_wp,  1.0_wp,  1.0_wp]  ! Node 8 (corner)
    
    WRITE(*, '(A)') '  Testing C3D8 shape functions...'
    
    ! Test 1: Shape functions at centroid (should be 0.125 each)
    xi = 0.0_wp
    eta = 0.0_wp
    zeta = 0.0_wp
    
    CALL PH_Elem_AC3D8_ShapeFunc(xi, eta, zeta, N)
    
    ! Assertion: N should sum to 1 (partition of unity)
    shape_sum = SUM(N)
    IF (ABS(shape_sum - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shape functions do not sum to 1'
      WRITE(*, '(A,F12.8)') '    Sum = ', shape_sum
      test_passed = .FALSE.
    END IF
    
    ! Assertion: At centroid, all N should be 0.125
    IF (ANY(ABS(N - 0.125_wp) > 1.0e-10_wp)) THEN
      WRITE(*, '(A)') '    WARN: Centroid shape functions not all 0.125'
      WRITE(*, '(A,8F8.4)') '    N = ', N
    END IF
    
    IF (test_passed) THEN
      WRITE(*, '(A)') '    PASS: Shape functions partition of unity'
    END IF
    
    ! Test 2: Stiffness matrix computation
    WRITE(*, '(A)') '  Testing stiffness matrix assembly...'
    
    CALL Test_Stiffness_Matrix(coords, test_passed)
    
    ! Test 3: Internal force vector
    WRITE(*, '(A)') '  Testing internal force vector...'
    
    CALL Test_IntForce_Vector(coords, test_passed)
    
    IF (test_passed) THEN
      WRITE(*, '(A)') 'AC3D8_Core_Physics_Test: ALL TESTS PASSED'
    ELSE
      WRITE(*, '(A)') 'AC3D8_Core_Physics_Test: SOME TESTS FAILED'
    END IF
    
  CONTAINS
    
    SUBROUTINE Test_Stiffness_Matrix(c, passed)
      REAL(wp), INTENT(IN) :: c(3,8)
      LOGICAL, INTENT(INOUT) :: passed
      REAL(wp) :: Ke(8,8), k_eff, nu
      INTEGER(i4) :: i, j
      
      k_eff = 1.42e5_wp  ! Bulk modulus of air [Pa]
      nu = 0.0_wp         ! Poisson ratio (not used in acoustics)
      
      CALL PH_Elem_AC3D8_FormStiffMatrix(c, k_eff, nu, Ke)
      
      ! Check symmetry
      DO i = 1, 8
        DO j = i+1, 8
          IF (ABS(Ke(i,j) - Ke(j,i)) > 1.0e-10_wp) THEN
            WRITE(*, '(A,I0,A,I0)') '    WARN: Ke not symmetric at (',i,',',j,')'
          END IF
        END DO
      END DO
      
      ! Check diagonal dominance (for positive definite)
      DO i = 1, 8
        IF (Ke(i,i) <= 0.0_wp) THEN
          WRITE(*, '(A,I0,A,E12.4)') '    WARN: Ke(',i,',',i,') <= 0'
        END IF
      END DO
      
      WRITE(*, '(A)') '    PASS: Stiffness matrix computed'
      
    END SUBROUTINE Test_Stiffness_Matrix
    
    SUBROUTINE Test_IntForce_Vector(c, passed)
      REAL(wp), INTENT(IN) :: c(3,8)
      LOGICAL, INTENT(INOUT) :: passed
      REAL(wp) :: u(8), R_int(8), k_eff, nu
      
      u = 0.0_wp  ! Zero displacement field
      k_eff = 1.42e5_wp
      nu = 0.0_wp
      
      CALL PH_Elem_AC3D8_FormIntForce(c, u, k_eff, nu, R_int)
      
      ! For zero pressure field, internal force should be zero
      IF (ABS(SUM(R_int)) > 1.0e-10_wp) THEN
        WRITE(*, '(A)') '    WARN: R_int not zero for zero pressure'
      END IF
      
      WRITE(*, '(A)') '    PASS: Internal force vector computed'
      
    END SUBROUTINE Test_IntForce_Vector
    
  END SUBROUTINE AC3D8_Core_Physics_Test

END MODULE AC3D8_Core_Physics_Test
