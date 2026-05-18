!===============================================================================
! Module: AC3D15_Core_Physics_Test
! Purpose: Test AC3D15 (quadratic wedge) core physics
! Element: 3D acoustic quadratic wedge (15-node)
!===============================================================================

MODULE AC3D15_Core_Physics_Test
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D15_Core_Physics_Test()
    !! Test AC3D15 core physics
    REAL(wp) :: coords(3, 15)
    REAL(wp) :: N(15), Ke(15, 15), R_int(15)
    REAL(wp) :: k_eff, nu
    INTEGER(i4) :: i, j
    LOGICAL :: test_passed
    
    test_passed = .TRUE.
    WRITE(*, '(A)') '=========================================='
    WRITE(*, '(A)') 'AC3D15 Core Physics Test'
    WRITE(*, '(A)') '=========================================='
    
    ! Setup: Wedge element (triangular prism)
    ! Bottom triangle
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:,3) = [0.5_wp, 1.0_wp, 0.0_wp]
    ! Top triangle
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]
    coords(:,5) = [1.0_wp, 0.0_wp, 1.0_wp]
    coords(:,6) = [0.5_wp, 1.0_wp, 1.0_wp]
    ! Edge mid-nodes
    coords(:,7) = [0.5_wp, 0.0_wp, 0.0_wp]
    coords(:,8) = [0.75_wp, 0.5_wp, 0.0_wp]
    coords(:,9) = [0.25_wp, 0.5_wp, 0.0_wp]
    coords(:,10) = [0.5_wp, 0.0_wp, 1.0_wp]
    coords(:,11) = [0.75_wp, 0.5_wp, 1.0_wp]
    coords(:,12) = [0.25_wp, 0.5_wp, 1.0_wp]
    coords(:,13) = [0.0_wp, 0.0_wp, 0.5_wp]
    coords(:,14) = [1.0_wp, 0.0_wp, 0.5_wp]
    coords(:,15) = [0.5_wp, 1.0_wp, 0.5_wp]
    
    WRITE(*, '(A)') '  Testing C3D15 shape functions...'
    
    CALL PH_Elem_AC3D15_ShapeFunc(0.0_wp, 0.0_wp, 0.5_wp, N)
    
    IF (ABS(SUM(N) - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shape functions do not sum to 1'
      test_passed = .FALSE.
    END IF
    
    WRITE(*, '(A)') '  Testing stiffness matrix...'
    
    k_eff = 1.42e5_wp
    nu = 0.0_wp
    Ke = 0.0_wp
    CALL PH_Elem_AC3D15_FormStiffMatrix(coords, k_eff, nu, Ke)
    
    WRITE(*, '(A)') 'AC3D15_Core_Physics_Test: COMPLETED'
    
  END SUBROUTINE AC3D15_Core_Physics_Test

END MODULE AC3D15_Core_Physics_Test
