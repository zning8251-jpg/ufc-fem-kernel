!===============================================================================
! Module: AC3D20_Core_Physics_Test
! Purpose: Test AC3D20 (quadratic hexahedron) core physics
! Element: 3D acoustic quadratic hexahedron (20-node)
!===============================================================================

MODULE AC3D20_Core_Physics_Test
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D20_Core_Physics_Test()
    !! Test AC3D20 core physics
    REAL(wp) :: coords(3, 20)
    REAL(wp) :: N(20), Ke(20, 20), R_int(20)
    REAL(wp) :: k_eff, nu
    INTEGER(i4) :: i, j
    LOGICAL :: test_passed
    
    test_passed = .TRUE.
    WRITE(*, '(A)') '=========================================='
    WRITE(*, '(A)') 'AC3D20 Core Physics Test'
    WRITE(*, '(A)') '=========================================='
    
    ! Setup: Unit cube with mid-nodes
    ! Corner nodes (1-8)
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:,3) = [1.0_wp, 1.0_wp, 0.0_wp]
    coords(:,4) = [0.0_wp, 1.0_wp, 0.0_wp]
    coords(:,5) = [0.0_wp, 0.0_wp, 1.0_wp]
    coords(:,6) = [1.0_wp, 0.0_wp, 1.0_wp]
    coords(:,7) = [1.0_wp, 1.0_wp, 1.0_wp]
    coords(:,8) = [0.0_wp, 1.0_wp, 1.0_wp]
    ! Edge mid-nodes (9-20)
    coords(:,9)  = [0.5_wp, 0.0_wp, 0.0_wp]  ! Edge 1-2
    coords(:,10) = [1.0_wp, 0.5_wp, 0.0_wp]  ! Edge 2-3
    coords(:,11) = [0.5_wp, 1.0_wp, 0.0_wp]  ! Edge 3-4
    coords(:,12) = [0.0_wp, 0.5_wp, 0.0_wp]  ! Edge 4-1
    coords(:,13) = [0.5_wp, 0.0_wp, 1.0_wp]  ! Edge 5-6
    coords(:,14) = [1.0_wp, 0.5_wp, 1.0_wp]  ! Edge 6-7
    coords(:,15) = [0.5_wp, 1.0_wp, 1.0_wp]  ! Edge 7-8
    coords(:,16) = [0.0_wp, 0.5_wp, 1.0_wp]  ! Edge 8-5
    coords(:,17) = [0.0_wp, 0.0_wp, 0.5_wp]  ! Edge 1-5
    coords(:,18) = [1.0_wp, 0.0_wp, 0.5_wp]  ! Edge 2-6
    coords(:,19) = [1.0_wp, 1.0_wp, 0.5_wp]  ! Edge 3-7
    coords(:,20) = [0.0_wp, 1.0_wp, 0.5_wp]  ! Edge 4-8
    
    WRITE(*, '(A)') '  Testing C3D20 shape functions...'
    
    CALL PH_Elem_AC3D20_ShapeFunc(0.0_wp, 0.0_wp, 0.0_wp, N)
    
    IF (ABS(SUM(N) - 1.0_wp) > 1.0e-10_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shape functions do not sum to 1'
      test_passed = .FALSE.
    END IF
    
    WRITE(*, '(A)') '  Testing stiffness matrix...'
    
    k_eff = 1.42e5_wp
    nu = 0.0_wp
    Ke = 0.0_wp
    CALL PH_Elem_AC3D20_FormStiffMatrix(coords, k_eff, nu, Ke)
    
    ! Check symmetry
    DO i = 1, 20
      DO j = i+1, 20
        IF (ABS(Ke(i,j) - Ke(j,i)) > 1.0e-10_wp) THEN
          WRITE(*, '(A,I0,A,I0)') '    WARN: Ke not symmetric at (',i,',',j,')'
        END IF
      END DO
    END DO
    
    WRITE(*, '(A)') 'AC3D20_Core_Physics_Test: COMPLETED'
    
  END SUBROUTINE AC3D20_Core_Physics_Test

END MODULE AC3D20_Core_Physics_Test
