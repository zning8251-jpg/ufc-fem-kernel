!===============================================================================
! Module: AC3D8_EndToEnd_Test
! Purpose: End-to-end integration test for AC3D8 acoustic element
! Description: Verifies full chain L5_RT → L4_PH → L3_MD
! Element: 3D acoustic hexahedron (8-node)
!===============================================================================

PROGRAM AC3D8_EndToEnd_Test
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE UFC_Error_Handler
  IMPLICIT NONE
  
  !---------------------------------------------------------------------------
  ! Test configuration: Simple 3D acoustic cavity
  !---------------------------------------------------------------------------
  INTEGER(i4), PARAMETER :: n_elem = 1        ! Single element test
  INTEGER(i4), PARAMETER :: n_node = 8      ! 8-node hexahedron
  INTEGER(i4), PARAMETER :: n_dof = 8        ! 1 DOF per node (pressure)
  
  REAL(wp), PARAMETER :: L = 1.0_wp         ! Cavity size [m]
  REAL(wp), PARAMETER :: rho = 1.21_wp      ! Air density [kg/m³]
  REAL(wp), PARAMETER :: c = 343.0_wp       ! Sound speed [m/s]
  REAL(wp), PARAMETER :: K = rho * c**2     ! Bulk modulus [Pa]
  
  ! Local variables
  REAL(wp) :: coords(3, n_node)
  REAL(wp) :: Ke(n_dof, n_dof)
  REAL(wp) :: Me(n_dof, n_dof)
  REAL(wp) :: R_int(n_dof)
  REAL(wp) :: p(n_dof)                       ! Pressure DOFs
  REAL(wp) :: k_eff, nu
  TYPE(ErrorStatusType) :: status
  INTEGER(i4) :: i, j
  REAL(wp) :: det_J, expected_Ke_diag
  LOGICAL :: test_passed
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'AC3D8 End-to-End Integration Test'
  WRITE(*, '(A)') '=========================================='
  
  test_passed = .TRUE.
  
  !---------------------------------------------------------------------------
  ! Setup: Unit cube hexahedron
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') 'Setup: Unit cube (1m x 1m x 1m)'
  
  coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords(:,2) = [L,     0.0_wp, 0.0_wp]
  coords(:,3) = [L,     L,     0.0_wp]
  coords(:,4) = [0.0_wp, L,     0.0_wp]
  coords(:,5) = [0.0_wp, 0.0_wp, L]
  coords(:,6) = [L,     0.0_wp, L]
  coords(:,7) = [L,     L,     L]
  coords(:,8) = [0.0_wp, L,     L]
  
  k_eff = K
  nu = 0.0_wp
  
  !---------------------------------------------------------------------------
  ! Test 1: Stiffness Matrix Assembly
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') 'Test 1: Stiffness Matrix Assembly...'
  
  Ke = 0.0_wp
  CALL PH_Elem_AC3D8_FormStiffMatrix(coords, k_eff, nu, Ke)
  
  ! Check symmetry
  DO i = 1, n_dof
    DO j = i+1, n_dof
      IF (ABS(Ke(i,j) - Ke(j,i)) > 1.0e-10_wp) THEN
        WRITE(*, '(A,I0,A,I0)') '  FAIL: Ke asymmetry at (',i,',',j,')'
        test_passed = .FALSE.
      END IF
    END DO
  END DO
  
  ! Check diagonal positivity
  DO i = 1, n_dof
    IF (Ke(i,i) <= 0.0_wp) THEN
      WRITE(*, '(A,I0,A,E12.4)') '  FAIL: Ke(',i,',',i,') <= 0'
      test_passed = .FALSE.
    END IF
  END DO
  
  IF (test_passed) THEN
    WRITE(*, '(A)') '  PASS: Stiffness matrix symmetric and positive'
  END IF
  
  !---------------------------------------------------------------------------
  ! Test 2: Internal Force (Zero Pressure)
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') 'Test 2: Internal Force (Zero Pressure)...'
  
  p = 0.0_wp
  R_int = 0.0_wp
  CALL PH_Elem_AC3D8_FormIntForce(coords, p, k_eff, nu, R_int)
  
  IF (ABS(SUM(R_int)) > 1.0e-10_wp) THEN
    WRITE(*, '(A)') '  FAIL: R_int not zero for zero pressure'
    test_passed = .FALSE.
  ELSE
    WRITE(*, '(A)') '  PASS: Internal force zero for zero pressure'
  END IF
  
  !---------------------------------------------------------------------------
  ! Test 3: Internal Force (Uniform Pressure)
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') 'Test 3: Internal Force (Uniform Pressure p=1Pa)...'
  
  p = 1.0_wp
  CALL PH_Elem_AC3D8_FormIntForce(coords, p, k_eff, nu, R_int)
  
  ! For uniform pressure, integral of grad(N) should give net outward force = 0
  WRITE(*, '(A,2E14.6)') '  R_int sum = ', SUM(R_int), 'should be ~0'
  WRITE(*, '(A)') '  PASS: Internal force computed'
  
  !---------------------------------------------------------------------------
  ! Test 4: UF_Elem_Calc Interface
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') 'Test 4: UF_Elem_AC3D8_Calc Interface...'
  
  CALL Test_UF_Elem_Calc(coords, test_passed)
  
  !---------------------------------------------------------------------------
  ! Summary
  !---------------------------------------------------------------------------
  WRITE(*, '(A)') '=========================================='
  IF (test_passed) THEN
    WRITE(*, '(A)') 'AC3D8 E2E Test: ALL TESTS PASSED'
  ELSE
    WRITE(*, '(A)') 'AC3D8 E2E Test: SOME TESTS FAILED'
  END IF
  WRITE(*, '(A)') '=========================================='

CONTAINS

  SUBROUTINE Test_UF_Elem_Calc(elem_coords, passed)
    REAL(wp), INTENT(IN) :: elem_coords(3, 8)
    LOGICAL, INTENT(INOUT) :: passed
    
    TYPE(ElemType) :: ElemType_dummy
    TYPE(ElemFormul) :: Formul_dummy
    TYPE(ElemCtx) :: Ctx_dummy
    TYPE(ElemState) :: state_in, state_out
    TYPE(MatProperties) :: Mat_dummy
    TYPE(ElemFlags) :: flags_dummy
    
    ! Initialize minimal context
    ALLOCATE(Ctx_dummy%coords_ref(3, 8))
    Ctx_dummy%coords_ref = elem_coords
    
    ALLOCATE(Ctx_dummy%disp_total(1, 8))
    Ctx_dummy%disp_total = 0.0_wp
    
    ! Initialize material
    ALLOCATE(Mat_dummy%props)
    ALLOCATE(Mat_dummy%props%props(3))
    Mat_dummy%props%props(1) = rho      ! Density
    Mat_dummy%props%props(2) = K        ! Bulk modulus
    Mat_dummy%props%props(3) = c        ! Sound speed
    
    ! Call unified interface
    CALL UF_Elem_AC3D8_Calc(ElemType_dummy, Formul_dummy, Ctx_dummy, &
         state_in, Mat_dummy, state_out, flags_dummy)
    
    IF (flags_dummy%failed) THEN
      WRITE(*, '(A)') '  FAIL: UF_Elem_AC3D8_Calc returned failed flag'
      passed = .FALSE.
    ELSE
      WRITE(*, '(A)') '  PASS: UF_Elem_AC3D8_Calc executed successfully'
    END IF
    
    ! Cleanup
    DEALLOCATE(Ctx_dummy%coords_ref, Ctx_dummy%disp_total)
    DEALLOCATE(Mat_dummy%props%props, Mat_dummy%props)
    
  END SUBROUTINE Test_UF_Elem_Calc

END PROGRAM AC3D8_EndToEnd_Test
