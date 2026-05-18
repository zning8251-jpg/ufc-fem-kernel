!===============================================================================
! Module: AC2D6_Core_Physics_Test
! Purpose: Unit tests for AC2D6 element core physics
! Tests: Shape functions, Jacobian, B-matrix, stiffness assembly
!===============================================================================
MODULE AC2D6_Core_Physics_Test
  USE IF_Const, ONLY: ZERO, ONE
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_AC2D6_Core
  IMPLICIT NONE
  PRIVATE
  
  PUBLIC :: Test_AC2D6_Shape_Functions
  PUBLIC :: Test_AC2D6_Jacobian
  PUBLIC :: Test_AC2D6_B_Matrix
  PUBLIC :: Test_AC2D6_Stiffness_Assembly
  
CONTAINS
  
  !===========================================================================
  ! TEST 1: Shape Functions at Centroid
  !===========================================================================
  SUBROUTINE Test_AC2D6_Shape_Functions()
    !! Verify shape functions sum to 1 (partition of unity)
    REAL(wp) :: N(PH_ELEM_AC2D6_NNODE)
    REAL(wp) :: xi, eta, sum_N
    REAL(wp) :: tolerance
    INTEGER(i4) :: test_count
    
    tolerance = 1.0e-10_wp
    test_count = 0
    
    WRITE(*,*) ''
    WRITE(*,*) '=== TEST 1: AC2D6 Shape Functions ==='
    
    ! Test 1: Centroid (ξ=1/3, η=1/3)
    xi = 1.0_wp/3.0_wp
    eta = 1.0_wp/3.0_wp
    CALL CPS6_Shape_Functions(xi, eta, N)
    
    sum_N = SUM(N)
    WRITE(*,'(A,F8.5,A,F8.5)') '  Centroid (ξ=', xi, ', η=', eta, ')'
    WRITE(*,'(A,6F10.6)') '  N = ', N
    WRITE(*,'(A,F12.8)') '  Sum(N) = ', sum_N
    
    IF (ABS(sum_N - 1.0_wp) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Partition of unity satisfied'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Sum(N) ≠ 1.0'
    END IF
    
    ! Test 2: Corner node 1 (ξ=0, η=0)
    xi = 0.0_wp
    eta = 0.0_wp
    CALL CPS6_Shape_Functions(xi, eta, N)
    
    WRITE(*,'(A,F8.5,A,F8.5)') '  Corner Node 1 (ξ=', xi, ', η=', eta, ')'
    WRITE(*,'(A,6F10.6)') '  N = ', N
    WRITE(*,'(A,F10.6,A,F10.6)') '  N(1) = ', N(1), ' (expected: 1.0)'
    
    IF (ABS(N(1) - 1.0_wp) < tolerance .AND. ABS(N(2)) < tolerance .AND. &
        ABS(N(3)) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Kronecker delta at corner nodes'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Kronecker delta not satisfied'
    END IF
    
    ! Test 3: Midside node 4 (ξ=0.5, η=0)
    xi = 0.5_wp
    eta = 0.0_wp
    CALL CPS6_Shape_Functions(xi, eta, N)
    
    WRITE(*,'(A,F8.5,A,F8.5)') '  Midside Node 4 (ξ=', xi, ', η=', eta, ')'
    WRITE(*,'(A,6F10.6)') '  N = ', N
    WRITE(*,'(A,F10.6,A,F10.6)') '  N(4) = ', N(4), ' (expected: 1.0)'
    
    IF (ABS(N(4) - 1.0_wp) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Kronecker delta at midside nodes'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Kronecker delta not satisfied at midside'
    END IF
    
    WRITE(*,'(A,I2,A,I2)') '  Result: ', test_count, '/3 tests passed'
    WRITE(*,*) ''
    
  END SUBROUTINE Test_AC2D6_Shape_Functions
  
  !===========================================================================
  ! TEST 2: Jacobian Computation
  !===========================================================================
  SUBROUTINE Test_AC2D6_Jacobian()
    !! Verify Jacobian determinant for standard triangle
    REAL(wp) :: coords(2, PH_ELEM_AC2D6_NNODE)
    REAL(wp) :: N(PH_ELEM_AC2D6_NNODE), dNdX(2, PH_ELEM_AC2D6_NNODE)
    REAL(wp) :: xi, eta, detJ, expected_area
    REAL(wp) :: tolerance
    INTEGER(i4) :: test_count
    
    tolerance = 1.0e-8_wp
    test_count = 0
    
    WRITE(*,*) '=== TEST 2: AC2D6 Jacobian ==='
    
    ! Create equilateral triangle with side length 1.0
    ! Nodes 1,2,3: corners; Nodes 4,5,6: midsides
    coords(1, 1) = 0.0_wp; coords(2, 1) = 0.0_wp  ! Node 1
    coords(1, 2) = 1.0_wp; coords(2, 2) = 0.0_wp  ! Node 2
    coords(1, 3) = 0.5_wp; coords(2, 3) = 0.866025403784_wp  ! Node 3
    coords(1, 4) = 0.5_wp; coords(2, 4) = 0.0_wp  ! Node 4 (mid 1-2)
    coords(1, 5) = 0.75_wp; coords(2, 5) = 0.433012701892_wp  ! Node 5 (mid 2-3)
    coords(1, 6) = 0.25_wp; coords(2, 6) = 0.433012701892_wp  ! Node 6 (mid 3-1)
    
    expected_area = 0.433012701892_wp  ! Area of equilateral triangle with side 1
    
    ! Test at centroid
    xi = 1.0_wp/3.0_wp
    eta = 1.0_wp/3.0_wp
    
    CALL CPS6_Shape_Functions(xi, eta, N)
    CALL CPS6_Jacobian(coords, N, xi, eta, dNdX, detJ)
    
    WRITE(*,'(A,F12.8)') '  Jacobian det at centroid: ', detJ
    WRITE(*,'(A,F12.8)') '  Expected (2×Area): ', 2.0_wp * expected_area
    
    ! For linear triangle, detJ should be constant = 2×Area
    IF (ABS(detJ - 2.0_wp * expected_area) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Jacobian determinant correct'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Jacobian determinant incorrect'
    END IF
    
    ! Test positivity (no inverted elements)
    IF (detJ > 0.0_wp) THEN
      WRITE(*,*) '  ✅ PASS: Positive Jacobian (no inversion)'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Non-positive Jacobian detected'
    END IF
    
    WRITE(*,'(A,I2,A,I2)') '  Result: ', test_count, '/2 tests passed'
    WRITE(*,*) ''
    
  END SUBROUTINE Test_AC2D6_Jacobian
  
  !===========================================================================
  ! TEST 3: B-Matrix (Pressure Gradient Operator)
  !===========================================================================
  SUBROUTINE Test_AC2D6_B_Matrix()
    !! Verify B-matrix relates nodal pressures to gradient
    REAL(wp) :: dNdX(2, PH_ELEM_AC2D6_NNODE)
    REAL(wp) :: B(2, PH_ELEM_AC2D6_NDOF)
    REAL(wp) :: p_node(PH_ELEM_AC2D6_NDOF)
    REAL(wp) :: grad_p(2), expected_grad(2)
    REAL(wp) :: tolerance
    INTEGER(i4) :: test_count
    
    tolerance = 1.0e-8_wp
    test_count = 0
    
    WRITE(*,*) '=== TEST 3: AC2D6 B-Matrix ==='
    
    ! Simple test: linear pressure field p = x + 2y
    ! Expected gradient: ∇p = [1, 2]
    expected_grad(1) = 1.0_wp
    expected_grad(2) = 2.0_wp
    
    ! Setup dNdX (from previous Jacobian test)
    dNdX(1, :) = 0.1_wp  ! ∂N/∂x (example values)
    dNdX(2, :) = 0.2_wp  ! ∂N/∂y
    
    ! Nodal pressures: p_i = x_i + 2*y_i
    p_node = 1.0_wp  ! Simplified test
    
    CALL AC2D6_B_Matrix(dNdX, B)
    
    WRITE(*,'(A)') '  B-matrix computed:'
    WRITE(*,'(2F12.6)') B(1, :), B(2, :)
    
    ! Compute gradient: ∇p = B · p_node
    grad_p = MATMUL(B, p_node)
    
    WRITE(*,'(A,2F12.6)') '  Computed gradient: ', grad_p
    WRITE(*,'(A,2F12.6)') '  Expected gradient: ', expected_grad
    
    IF (ABS(grad_p(1) - expected_grad(1)) < tolerance .AND. &
        ABS(grad_p(2) - expected_grad(2)) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Gradient computation correct'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Gradient computation incorrect'
    END IF
    
    WRITE(*,'(A,I2,A,I2)') '  Result: ', test_count, '/1 tests passed'
    WRITE(*,*) ''
    
  END SUBROUTINE Test_AC2D6_B_Matrix
  
  !===========================================================================
  ! TEST 4: Stiffness Matrix Assembly (Patch Test)
  !===========================================================================
  SUBROUTINE Test_AC2D6_Stiffness_Assembly()
    !! Verify stiffness matrix passes patch test
    REAL(wp) :: coords(2, PH_ELEM_AC2D6_NNODE)
    REAL(wp) :: Ke(PH_ELEM_AC2D6_NDOF, PH_ELEM_AC2D6_NDOF)
    REAL(wp) :: p_test(PH_ELEM_AC2D6_NDOF)
    REAL(wp) :: f_int(PH_ELEM_AC2D6_NDOF)
    REAL(wp) :: bulk_modulus, thickness
    REAL(wp) :: tolerance
    INTEGER(i4) :: test_count
    
    tolerance = 1.0e-6_wp
    test_count = 0
    
    WRITE(*,*) '=== TEST 4: AC2D6 Stiffness Assembly ==='
    
    ! Create standard triangle element
    coords(1, 1) = 0.0_wp; coords(2, 1) = 0.0_wp
    coords(1, 2) = 1.0_wp; coords(2, 2) = 0.0_wp
    coords(1, 3) = 0.5_wp; coords(2, 3) = 0.866025403784_wp
    coords(1, 4) = 0.5_wp; coords(2, 4) = 0.0_wp
    coords(1, 5) = 0.75_wp; coords(2, 5) = 0.433012701892_wp
    coords(1, 6) = 0.25_wp; coords(2, 6) = 0.433012701892_wp
    
    bulk_modulus = 2.2e9_wp
    thickness = 1.0_wp
    
    ! Assemble stiffness matrix
    CALL PH_Elem_AC2D6_FormStiffMatrix(coords, bulk_modulus, 0.0_wp, Ke)
    
    WRITE(*,'(A)') '  Stiffness matrix assembled (diagonal):'
    WRITE(*,'(6F10.2)') (Ke(i,i), i=1,PH_ELEM_AC2D6_NDOF)
    
    ! Patch test: constant pressure mode should produce zero energy
    p_test = 1.0_wp  ! Constant pressure field
    f_int = MATMUL(Ke, p_test)
    
    WRITE(*,'(A,6F12.4)') '  Internal force (constant p): ', f_int
    
    ! For constant pressure, internal forces should be zero (rigid body mode)
    IF (MAXVAL(ABS(f_int)) < tolerance) THEN
      WRITE(*,*) '  ✅ PASS: Constant pressure mode (patch test)'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Non-zero force for constant pressure'
    END IF
    
    ! Symmetry check
    LOGICAL :: is_symmetric
    is_symmetric = .TRUE.
    
    DO i = 1, PH_ELEM_AC2D6_NDOF
      DO j = i+1, PH_ELEM_AC2D6_NDOF
        IF (ABS(Ke(i,j) - Ke(j,i)) > tolerance) THEN
          is_symmetric = .FALSE.
          EXIT
        END IF
      END DO
      IF (.NOT. is_symmetric) EXIT
    END DO
    
    IF (is_symmetric) THEN
      WRITE(*,*) '  ✅ PASS: Stiffness matrix symmetric'
      test_count = test_count + 1
    ELSE
      WRITE(*,*) '  ❌ FAIL: Stiffness matrix not symmetric'
    END IF
    
    WRITE(*,'(A,I2,A,I2)') '  Result: ', test_count, '/2 tests passed'
    WRITE(*,*) ''
    
  END SUBROUTINE Test_AC2D6_Stiffness_Assembly
  
END MODULE AC2D6_Core_Physics_Test
