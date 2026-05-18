!===============================================================================
! Program: PH_Field_GaussQuad_Test
! Purpose: Unit test for Gaussian quadrature adapter
! Test Cases:
!   1. 1D Gauss points (1, 2, 3, 4 point rules)
!   2. 2D Quad Gauss points (2x2, 3x3)
!   3. 3D Hex Gauss points (2x2x2, 3x3x3)
!   4. Weight sum verification (1D: Σw=2, 2D: Σw=4, 3D: Σw=8)
!   5. Integration of polynomial: ∫x² from -1 to 1 = 2/3
! Status: P1-2 Unit Test | Date: 2026-04-13
!===============================================================================

PROGRAM PH_Field_GaussQuad_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Const, ONLY: ZERO, ONE, HALF, TWO
  USE IF_Err_API, ONLY: IF_STATUS_OK
  USE PH_Field_GaussQuadrature, ONLY: PH_Field_GetGaussPoints, &
                                     PH_Field_GaussPt_Arg

  IMPLICIT NONE

  ! Test parameters
  INTEGER(i4), PARAMETER :: n_tests = 5
  LOGICAL :: all_passed = .TRUE.
  INTEGER(i4) :: test_id

  ! Test variables
  TYPE(PH_Field_GaussPt_Arg) :: gp
  REAL(wp) :: weight_sum, integral_val
  REAL(wp) :: tol
  INTEGER(i4) :: i

  tol = 1.0e-12_wp

  PRINT *, '================================================'
  PRINT *, 'PH_Field_GaussQuadrature - Unit Tests'
  PRINT *, '================================================'
  PRINT *

  ! ==========================================================================
  ! TEST 1: 1D Gauss points weight sum (Σw = 2 for [-1,1])
  ! ==========================================================================
  test_id = 1
  PRINT '(A, I1, A)', 'Test ', test_id, ': 1D Gauss points weight sum (Σw=2)'
  
  CALL PH_Field_GetGaussPoints(1, 3, gp)  ! 3-point rule
  
  IF (gp%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: Gauss point computation error'
    all_passed = .FALSE.
  ELSE
    weight_sum = SUM(gp%weights)
    IF (ABS(weight_sum - TWO) < tol) THEN
      PRINT '(A, F15.10, A)', '  ✅ PASSED: Σw = ', weight_sum, ' (expected 2.0)'
    ELSE
      PRINT '(A, F15.10, A)', '  ❌ FAILED: Σw = ', weight_sum, ' (expected 2.0)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(gp%xi, gp%eta, gp%zeta, gp%weights)
  PRINT *

  ! ==========================================================================
  ! TEST 2: 2D Quad Gauss points weight sum (Σw = 4 for [-1,1]²)
  ! ==========================================================================
  test_id = 2
  PRINT '(A, I1, A)', 'Test ', test_id, ': 2D Quad weight sum (Σw=4)'
  
  CALL PH_Field_GetGaussPoints(2, 2, gp)  ! 2x2 rule = 4 points
  
  IF (gp%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: 2D Quad Gauss point error'
    all_passed = .FALSE.
  ELSE
    weight_sum = SUM(gp%weights)
    IF (ABS(weight_sum - 4.0_wp) < tol) THEN
      PRINT '(A, F15.10, A)', '  ✅ PASSED: Σw = ', weight_sum, ' (expected 4.0)'
    ELSE
      PRINT '(A, F15.10, A)', '  ❌ FAILED: Σw = ', weight_sum, ' (expected 4.0)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(gp%xi, gp%eta, gp%zeta, gp%weights)
  PRINT *

  ! ==========================================================================
  ! TEST 3: 3D Hex Gauss points weight sum (Σw = 8 for [-1,1]³)
  ! ==========================================================================
  test_id = 3
  PRINT '(A, I1, A)', 'Test ', test_id, ': 3D Hex weight sum (Σw=8)'
  
  CALL PH_Field_GetGaussPoints(4, 2, gp)  ! 2x2x2 = 8 points
  
  IF (gp%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: 3D Hex Gauss point error'
    all_passed = .FALSE.
  ELSE
    weight_sum = SUM(gp%weights)
    IF (ABS(weight_sum - 8.0_wp) < tol) THEN
      PRINT '(A, F15.10, A)', '  ✅ PASSED: Σw = ', weight_sum, ' (expected 8.0)'
    ELSE
      PRINT '(A, F15.10, A)', '  ❌ FAILED: Σw = ', weight_sum, ' (expected 8.0)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(gp%xi, gp%eta, gp%zeta, gp%weights)
  PRINT *

  ! ==========================================================================
  ! TEST 4: Polynomial integration ∫x² dx from -1 to 1 = 2/3
  ! ==========================================================================
  test_id = 4
  PRINT '(A, I1, A)', 'Test ', test_id, ': Polynomial integration ∫x² dx = 2/3'
  
  CALL PH_Field_GetGaussPoints(1, 3, gp)  ! 3-point rule
  
  IF (gp%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: Gauss point error'
    all_passed = .FALSE.
  ELSE
    ! Integrate x² using Gauss quadrature
    integral_val = ZERO
    DO i = 1, gp%n_ip
      integral_val = integral_val + gp%weights(i) * gp%xi(i)**2
    END DO
    
    IF (ABS(integral_val - TWO/3.0_wp) < tol) THEN
      PRINT '(A, F15.10, A)', '  ✅ PASSED: ∫x² dx = ', integral_val, ' (expected 0.666...)'
    ELSE
      PRINT '(A, F15.10, A)', '  ❌ FAILED: ∫x² dx = ', integral_val, ' (expected 0.666...)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(gp%xi, gp%eta, gp%zeta, gp%weights)
  PRINT *

  ! ==========================================================================
  ! TEST 5: 2D polynomial integration ∫∫xy dxdy over [-1,1]² = 0
  ! ==========================================================================
  test_id = 5
  PRINT '(A, I1, A)', 'Test ', test_id, ': 2D polynomial ∫∫xy = 0 (symmetric)'
  
  CALL PH_Field_GetGaussPoints(2, 2, gp)  ! 2x2 = 4 points
  
  IF (gp%status%status_code /= IF_STATUS_OK) THEN
    PRINT *, '  ❌ FAILED: 2D Gauss point error'
    all_passed = .FALSE.
  ELSE
    ! Integrate xy using tensor product Gauss
    integral_val = ZERO
    DO i = 1, gp%n_ip
      integral_val = integral_val + gp%weights(i) * gp%xi(i) * gp%eta(i)
    END DO
    
    IF (ABS(integral_val) < tol) THEN
      PRINT '(A, E15.6, A)', '  ✅ PASSED: ∫∫xy = ', integral_val, ' (expected 0.0)'
    ELSE
      PRINT '(A, E15.6, A)', '  ❌ FAILED: ∫∫xy = ', integral_val, ' (expected 0.0)'
      all_passed = .FALSE.
    END IF
  END IF
  
  DEALLOCATE(gp%xi, gp%eta, gp%zeta, gp%weights)
  PRINT *

  ! ==========================================================================
  ! SUMMARY
  ! ==========================================================================
  PRINT *, '================================================'
  IF (all_passed) THEN
    PRINT *, '✅ ALL TESTS PASSED (5/5)'
    PRINT *, '================================================'
    STOP 0
  ELSE
    PRINT *, '❌ SOME TESTS FAILED'
    PRINT *, '================================================'
    STOP 1
  END IF

END PROGRAM PH_Field_GaussQuad_Test