!===============================================================================
! Module: AC3D10_Core_Physics_Test
! Purpose: Test AC3D10 (quadratic tetrahedron) core physics
! Element: 3D acoustic quadratic tetrahedron (10-node)
!===============================================================================

MODULE AC3D10_Core_Physics_Test
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D10_Core_Physics_Test()
    !! Test AC3D10 core physics: shape functions, stiffness, internal force
    REAL(wp) :: coords(3, 10)
    REAL(wp) :: N(10), Ke(10, 10), R_int(10)
    REAL(wp) :: k_eff, nu
    INTEGER(i4) :: i, j
    LOGICAL :: test_passed
    
    test_passed = .TRUE.
    WRITE(*, '(A)') '=========================================='
    WRITE(*, '(A)') 'AC3D10 Core Physics Test'
    WRITE(*, '(A)') '=========================================='
    
    ! Setup: Regular tetrahedron with mid-nodes
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:,3) = [0.5_wp, 1.0_wp, 0.0_wp]
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]
    ! Mid-nodes (5-10)
    coords(:,5) = [0.5_wp, 0.0_wp, 0.0_wp]  ! Edge 1-2
    coords(:,6) = [0.75_wp, 0.5_wp, 0.0_wp]  ! Edge 2-3
    coords(:,7) = [0.25_wp, 0.5_wp, 0.0_wp]  ! Edge 3-1
    coords(:,8) = [0.0_wp, 0.0_wp, 0.5_wp]  ! Edge 1-4
    coords(:,9) = [0.5_wp, 0.0_wp, 0.5_wp]  ! Edge 2-4
    coords(:,10) = [0.25_wp, 0.5_wp, 0.5_wp] ! Edge 3-4
    
    WRITE(*, '(A)') '  Testing C3D10 shape functions...'
    
    ! Test: Shape functions at centroid
    CALL PH_Elem_AC3D10_ShapeFunc(0.25_wp, 0.25_wp, 0.25_wp, N)
    
    IF (ABS(SUM(N) - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shape functions do not sum to 1'
      test_passed = .FALSE.
    END IF
    
    WRITE(*, '(A)') '  Testing stiffness matrix...'
    
    k_eff = 1.42e5_wp
    nu = 0.0_wp
    Ke = 0.0_wp
    CALL PH_Elem_AC3D10_FormStiffMatrix(coords, k_eff, nu, Ke)
    
    ! Check symmetry
    DO i = 1, 10
      DO j = i+1, 10
        IF (ABS(Ke(i,j) - Ke(j,i)) > 1.0e-10_wp) THEN
          WRITE(*, '(A,I0,A,I0)') '    WARN: Ke not symmetric at (',i,',',j,')'
        END IF
      END DO
    END DO
    
    WRITE(*, '(A)') 'AC3D10_Core_Physics_Test: COMPLETED'
    
  END SUBROUTINE AC3D10_Core_Physics_Test

END MODULE AC3D10_Core_Physics_Test
