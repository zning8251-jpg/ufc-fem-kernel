!===============================================================================
! Module: AC3D4_Mass_Matrix_Test
! Purpose: Test AC3D4 mass matrix computation (P3)
! Description: Validates consistent and lumped mass matrices
!===============================================================================

MODULE AC3D4_Mass_Matrix_Test
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D4_Mass_Matrix_Test()
    !! Test mass matrix computation
    REAL(wp) :: coords(3, 4)
    REAL(wp) :: density = 1.225_wp
    REAL(wp) :: mass_cons(4, 4), mass_lump_hrz(4, 4)
    REAL(wp) :: mass_lump_row(4, 4), mass_lump_uni(4, 4)
    REAL(wp) :: total_mass_cons, total_mass_lump
    REAL(wp) :: expected_mass
    INTEGER(i4) :: i
    
    WRITE(*, '(A)') '  Testing consistent mass matrix...'
    
    ! Setup: Regular tetrahedron
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:,3) = [0.0_wp, 1.0_wp, 0.0_wp]
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]
    
    ! Volume = 1/6
    expected_mass = density * (1.0_wp / 6.0_wp)
    
    CALL PH_Elem_AC3D4_ConsMass(coords, density, mass_cons)
    
    ! Verify symmetry
    REAL(wp) :: asymmetry
    asymmetry = 0.0_wp
    DO i = 1, 4
      INTEGER(j) :: j
      DO j = 1, 4
        asymmetry = asymmetry + ABS(mass_cons(i,j) - mass_cons(j,i))
      END DO
    END DO
    
    IF (asymmetry > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6)') '    FAIL: Consistent mass not symmetric'
      RETURN
    END IF
    
    ! Verify total mass
    total_mass_cons = 0.0_wp
    DO i = 1, 4
      total_mass_cons = total_mass_cons + mass_cons(i,i)
    END DO
    
    IF (ABS(total_mass_cons - expected_mass) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6,A,F12.6)') '    FAIL: Total mass =', total_mass_cons, &
           ' (expected', expected_mass, ')'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Consistent mass: PASSED'
    
    ! Test HRZ lumping
    WRITE(*, '(A)') '  Testing HRZ lumped mass...'
    
    CALL PH_Elem_AC3D4_LumpMass(coords, density, 1, mass_lump_hrz)
    
    ! Verify diagonal
    DO i = 1, 4
      INTEGER(j) :: j
      DO j = 1, 4
        IF (i /= j .AND. ABS(mass_lump_hrz(i,j)) > 1.0e-10_wp) THEN
          WRITE(*, '(A)') '    FAIL: HRZ mass not diagonal'
          RETURN
        END IF
      END DO
    END DO
    
    ! Verify total mass conservation
    total_mass_lump = SUM(mass_lump_hrz(i,i) FOR i = 1 TO 4)
    
    IF (ABS(total_mass_lump - expected_mass) > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6,A,F12.6)') '    FAIL: HRZ total mass =', total_mass_lump, &
           ' (expected', expected_mass, ')'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ HRZ lumped mass: PASSED'
    
    ! Test RowSum lumping
    WRITE(*, '(A)') '  Testing RowSum lumped mass...'
    
    CALL PH_Elem_AC3D4_LumpMass(coords, density, 2, mass_lump_row)
    
    ! Verify diagonal
    DO i = 1, 4
      INTEGER(j) :: j
      DO j = 1, 4
        IF (i /= j .AND. ABS(mass_lump_row(i,j)) > 1.0e-10_wp) THEN
          WRITE(*, '(A)') '    FAIL: RowSum mass not diagonal'
          RETURN
        END IF
      END DO
    END DO
    
    WRITE(*, '(A)') '    ✓ RowSum lumped mass: PASSED'
    
    ! Test Uniform lumping
    WRITE(*, '(A)') '  Testing Uniform lumped mass...'
    
    CALL PH_Elem_AC3D4_LumpMass(coords, density, 3, mass_lump_uni)
    
    ! Verify uniform distribution
    REAL(wp) :: expected_diag
    expected_diag = expected_mass / 4.0_wp
    
    DO i = 1, 4
      IF (ABS(mass_lump_uni(i,i) - expected_diag) > 1.0e-10_wp) THEN
        WRITE(*, '(A,I2,A,F12.6,A,F12.6)') '    FAIL: Node', i, &
             ' mass =', mass_lump_uni(i,i), ' (expected', expected_diag, ')'
        RETURN
      END IF
    END DO
    
    WRITE(*, '(A)') '    ✓ Uniform lumped mass: PASSED'
    WRITE(*, '(A)') '  All mass matrix tests PASSED!'
    
  END SUBROUTINE AC3D4_Mass_Matrix_Test

END MODULE AC3D4_Mass_Matrix_Test
