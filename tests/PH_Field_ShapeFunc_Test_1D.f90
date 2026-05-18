!===============================================================================
! Program: PH_Field_ShapeFunc_Test_1D
! Purpose: Unit test for 1D shape function adapter
! Test Cases:
!   1. Shape function partition of unity: ΣN_i = 1
!   2. Shape function at nodes: N_i(ξ_j) = δ_ij
!   3. Jacobian computation for uniform mesh
!   4. Gradient transformation dN/dx verification
! Status: P1-1 Unit Test | Date: 2026-04-13
!===============================================================================

PROGRAM PH_Field_ShapeFunc_Test_1D
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Const, ONLY: ZERO, ONE
  USE IF_Err_API, ONLY: ErrorStatusType, IF_STATUS_OK
  USE PH_Field_ShapeFunc, ONLY: PH_Field_GetShapeFunctions, &
                                        PH_Field_GetShapeFunctionGradient, &
                                        PH_Field_ComputeJacobian, &
                                        PH_Field_ShapeFunc_Arg, &
                                        PH_Field_Gradient_Arg

  IMPLICIT NONE

  ! Test parameters
  INTEGER(i4), PARAMETER :: n_tests = 4
  INTEGER(i4) :: test_id
  LOGICAL :: all_passed = .TRUE.

  ! Test variables
  REAL(wp) :: xi, eta, zeta
  INTEGER(i4) :: npe
  TYPE(PH_Field_ShapeFunc_Arg) :: shape_out
  TYPE(PH_Field_Gradient_Arg) :: grad_out
  REAL(wp) :: coords(3, 8)
  REAL(wp) :: N_sum, detJ_expected, detJ_actual
  REAL(wp) :: tol
  INTEGER(i4) :: i, j

  tol = 1.0e-10_wp
  npe = 8

  PRINT *, '================================================'
  PRINT *, 'PH_Field_ShapeFunc - 1D Unit Tests'
  PRINT *, '================================================'
  PRINT *

  ! ==========================================================================
  ! TEST 1: Shape function partition of unity (ΣN_i = 1)
  ! ==========================================================================
  test_id = 1
  PRINT '(A, I1)', 'Test ', test_id, ': Partition of unity (ΣN_i = 1)'
  
  ! Test at center of element (ξ=η=ζ=0)
  xi = 0.0_wp; eta = 0.0_wp; zeta = 0.0_wp
  CALL PH_Field_GetShapeFunctions('C3D8', xi, eta, zeta, npe, shape_out)
  
  IF (shape_out%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: Shape function computation error'
    all_passed = .FALSE.
  ELSE
    N_sum = SUM(shape_out%N)
    IF (ABS(N_sum - ONE) < tol) THEN
      PRINT '(A, F15.10, A)', '  ✅ PASSED: ΣN_i = ', N_sum, ' (expected 1.0)'
    ELSE
      PRINT '(A, F15.10, A)', '  ❌ FAILED: ΣN_i = ', N_sum, ' (expected 1.0)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(shape_out%N)
  DEALLOCATE(shape_out%dN_dxi)
  PRINT *

  ! ==========================================================================
  ! TEST 2: Shape function at nodes (N_i(ξ_j) = δ_ij)
  ! ==========================================================================
  test_id = 2
  PRINT '(A, I1)', 'Test ', test_id, ': Kronecker delta property (N_i(ξ_j) = δ_ij)'
  
  ! Node natural coordinates
  REAL(wp) :: xi_nodes(8), eta_nodes(8), zeta_nodes(8)
  REAL(wp) :: max_error
  
  xi_nodes   = [-ONE, ONE, ONE, -ONE, -ONE, ONE, ONE, -ONE]
  eta_nodes  = [-ONE, -ONE, ONE, ONE, -ONE, -ONE, ONE, ONE]
  zeta_nodes = [-ONE, -ONE, -ONE, -ONE, ONE, ONE, ONE, ONE]
  
  max_error = ZERO
  
  DO i = 1, 8
    CALL PH_Field_GetShapeFunctions('C3D8', xi_nodes(i), eta_nodes(i), zeta_nodes(i), npe, shape_out)
    
    DO j = 1, 8
      IF (i == j) THEN
        ! Should be 1.0
        max_error = MAX(max_error, ABS(shape_out%N(j) - ONE))
      ELSE
        ! Should be 0.0
        max_error = MAX(max_error, ABS(shape_out%N(j)))
      END IF
    END DO
    
    DEALLOCATE(shape_out%N)
    DEALLOCATE(shape_out%dN_dxi)
  END DO
  
  IF (max_error < tol) THEN
    PRINT '(A, E15.6)', '  ✅ PASSED: Max error = ', max_error
  ELSE
    PRINT '(A, E15.6)', '  ❌ FAILED: Max error = ', max_error
    all_passed = .FALSE.
  END IF
  PRINT *

  ! ==========================================================================
  ! TEST 3: Jacobian computation for uniform cube
  ! ==========================================================================
  test_id = 3
  PRINT '(A, I1)', 'Test ', test_id, ': Jacobian for uniform cube (2×2×2)'
  
  ! Define unit cube [0,2]×[0,2]×[0,2]
  coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]  ! Node 1
  coords(:, 2) = [2.0_wp, 0.0_wp, 0.0_wp]  ! Node 2
  coords(:, 3) = [2.0_wp, 2.0_wp, 0.0_wp]  ! Node 3
  coords(:, 4) = [0.0_wp, 2.0_wp, 0.0_wp]  ! Node 4
  coords(:, 5) = [0.0_wp, 0.0_wp, 2.0_wp]  ! Node 5
  coords(:, 6) = [2.0_wp, 0.0_wp, 2.0_wp]  ! Node 6
  coords(:, 7) = [2.0_wp, 2.0_wp, 2.0_wp]  ! Node 7
  coords(:, 8) = [0.0_wp, 2.0_wp, 2.0_wp]  ! Node 8
  
  ! Get shape function derivatives at center
  xi = 0.0_wp; eta = 0.0_wp; zeta = 0.0_wp
  CALL PH_Field_GetShapeFunctions('C3D8', xi, eta, zeta, npe, shape_out)
  
  ! Compute Jacobian
  CALL PH_Field_ComputeJacobian(coords, shape_out%dN_dxi, npe, &
                                grad_out%dN_dx, detJ_actual, shape_out%status)
  ! Note: We reuse grad_out%dN_dx as temporary J matrix (will be overwritten)
  ! In production, use separate J matrix
  
  DEALLOCATE(shape_out%N)
  DEALLOCATE(shape_out%dN_dxi)
  
  ! Expected detJ for 2×2×2 cube: Volume / 8 = 8 / 8 = 1
  ! Actually: detJ = dx/dξ · dy/dη · dz/dζ = 1 · 1 · 1 = 1
  detJ_expected = 1.0_wp
  
  IF (ABS(detJ_actual - detJ_expected) < tol) THEN
    PRINT '(A, F15.10, A)', '  ✅ PASSED: detJ = ', detJ_actual, ' (expected ', detJ_expected, ')'
  ELSE
    PRINT '(A, F15.10, A)', '  ❌ FAILED: detJ = ', detJ_actual, ' (expected ', detJ_expected, ')'
    all_passed = .FALSE.
  END IF
  PRINT *

  ! ==========================================================================
  ! TEST 4: Gradient transformation dN/dx
  ! ==========================================================================
  test_id = 4
  PRINT '(A, I1)', 'Test ', test_id, ': Gradient transformation dN/dx'
  
  ! Use same unit cube
  CALL PH_Field_GetShapeFunctionGradient(coords, xi, eta, zeta, npe, grad_out)
  
  IF (grad_out%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: Gradient computation error'
    PRINT *, '  Error: ', TRIM(grad_out%status%error_message)
    all_passed = .FALSE.
  ELSE
    ! For uniform cube, dN/dx should be constant
    ! Check partition of unity for gradients: Σ∂N_i/∂x = 0
    REAL(wp) :: grad_sum_x, grad_sum_y, grad_sum_z
    
    grad_sum_x = SUM(grad_out%dN_dx(1, :))
    grad_sum_y = SUM(grad_out%dN_dx(2, :))
    grad_sum_z = SUM(grad_out%dN_dx(3, :))
    
    IF (ABS(grad_sum_x) < tol .AND. ABS(grad_sum_y) < tol .AND. ABS(grad_sum_z) < tol) THEN
      PRINT '(A, E15.6, A, E15.6, A, E15.6)', &
            '  ✅ PASSED: Σ∂N/∂x = ', grad_sum_x, &
            ', Σ∂N/∂y = ', grad_sum_y, &
            ', Σ∂N/∂z = ', grad_sum_z
    ELSE
      PRINT '(A, E15.6, A, E15.6, A, E15.6)', &
            '  ❌ FAILED: Σ∂N/∂x = ', grad_sum_x, &
            ', Σ∂N/∂y = ', grad_sum_y, &
            ', Σ∂N/∂z = ', grad_sum_z
      all_passed = .FALSE.
    END IF
    
    ! Check Jacobian determinant
    IF (ABS(grad_out%detJ - detJ_expected) < tol) THEN
      PRINT '(A, F15.10)', '  ✅ detJ = ', grad_out%detJ
    ELSE
      PRINT '(A, F15.10)', '  ❌ detJ = ', grad_out%detJ
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(grad_out%dN_dx)
  PRINT *

  ! ==========================================================================
  ! SUMMARY
  ! ==========================================================================
  PRINT *, '================================================'
  IF (all_passed) THEN
    PRINT *, '✅ ALL TESTS PASSED (4/4)'
    PRINT *, '================================================'
    STOP 0
  ELSE
    PRINT *, '❌ SOME TESTS FAILED'
    PRINT *, '================================================'
    STOP 1
  END IF

END PROGRAM PH_Field_ShapeFunc_Test_1D
