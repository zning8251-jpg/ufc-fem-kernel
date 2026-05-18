!===============================================================================
! B31PIPE Pipe Element - Usage Example and Verification Guide
! Phase 3 Deliverable: B31PIPE Pipe Beam with Pressure Loading
!===============================================================================

PROGRAM B31PIPE_Usage_Example
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_B31PIPE_Core
  
  IMPLICIT NONE
  
  !-- Test parameters
  REAL(wp) :: coords(3, 2)
  REAL(wp) :: E, nu, A, Iy, Iz, J
  REAL(wp) :: D_outer, D_inner, t_wall
  REAL(wp) :: p_internal
  REAL(wp) :: Ke14(14, 14), Rint14(14), M_lumped14(14)
  TYPE(ErrorStatusType) :: status
  
  PRINT *, '=============================================='
  PRINT *, 'B31PIPE Pipe Element - Usage Example'
  PRINT *, '=============================================='
  
  !===========================================================================
  ! Example 1: Straight pipe segment with internal pressure
  !===========================================================================
  PRINT *, ''
  PRINT *, 'Example 1: Straight Pipe Under Internal Pressure'
  PRINT *, '------------------------------------------------'
  
  ! Geometry (nominal pipe NPS 6, Schedule 40)
  D_outer = 0.1683_wp      ! 6.625 inch = 168.3 mm
  D_inner = 0.1541_wp      ! 6.065 inch = 154.1 mm
  t_wall  = (D_outer - D_inner) / 2.0_wp  ! 7.11 mm
  
  ! Material (Steel)
  E  = 210.0e9_wp          ! 210 GPa
  nu = 0.3_wp
  
  ! Section properties
  A  = PI * (D_outer**2 - D_inner**2) / 4.0_wp
  Iy = PI * (D_outer**4 - D_inner**4) / 64.0_wp
  Iz = Iy
  J  = PI * (D_outer**4 - D_inner**4) / 32.0_wp
  
  ! Coordinates (pipe length L=2.0m)
  coords(:, 1) = [0.0_wp, 0.0_wp, 0.0_wp]
  coords(:, 2) = [2.0_wp, 0.0_wp, 0.0_wp]
  
  ! Internal pressure (10 MPa = 100 bar)
  p_internal = 10.0e6_wp
  
  ! Compute stiffness matrix
  CALL PH_Elem_B31PIPE_FormStiffMatrix(coords, E, nu, A, Iy, Iz, J, &
                                       D_outer, D_inner, t_wall, Ke14, status)
  
  IF (STATUS_SUCCESS(status)) THEN
    PRINT *, '✓ Stiffness matrix formed successfully (14x14)'
  ELSE
    PRINT *, '✗ Failed to form stiffness matrix'
    STOP 1
  END IF
  
  ! Compute pressure load vector (end cap effect)
  CALL PH_Elem_B31PIPE_PressureLoad(coords, p_internal, D_inner, t_wall, &
                                    Rint14, status)
  
  IF (STATUS_SUCCESS(status)) THEN
    PRINT *, '✓ Pressure load vector computed'
    PRINT *, '  End cap force F = p × A = ', p_internal/1.0e6_wp, ' MPa × ', &
             PI*D_inner**2/4.0_wp*1.0e6_wp, ' mm² = ', ABS(Rint14(1))/1000.0_wp, ' kN'
  END IF
  
  ! Compute lumped mass
  REAL(wp) :: rho = 7800.0_wp  ! Steel density
  CALL PH_Elem_B31PIPE_LumpMassVector(coords, rho, A, M_lumped14, status)
  
  IF (STATUS_SUCCESS(status)) THEN
    PRINT *, '✓ Lumped mass vector computed'
    PRINT *, '  Total mass = ', SUM(M_lumped14(1:6) + M_lumped14(8:13)), ' kg'
  END IF
  
  !===========================================================================
  ! Stress verification
  !===========================================================================
  PRINT *, ''
  PRINT *, 'Stress Verification (Thin-Walled Theory)'
  PRINT *, '----------------------------------------'
  
  REAL(wp) :: hoop_stress, axial_stress
  hoop_stress = p_internal * D_inner / (2.0_wp * t_wall)
  axial_stress = p_internal * D_inner / (4.0_wp * t_wall)
  
  PRINT '(A,F8.2,A)', '  Hoop stress σ_θ = ', hoop_stress/1.0e6_wp, ' MPa'
  PRINT '(A,F8.2,A)', '  Axial stress σ_x = ', axial_stress/1.0e6_wp, ' MPa'
  PRINT '(A,F8.2)', '  Von Mises σ_eq = ', &
       SQRT(hoop_stress**2 + axial_stress**2 - hoop_stress*axial_stress)/1.0e6_wp, ' MPa'
  
  ! Theoretical values for comparison
  REAL(wp) :: hoop_theory, axial_theory
  hoop_theory = p_internal * D_inner / (2.0_wp * t_wall)
  axial_theory = p_internal * D_inner / (4.0_wp * t_wall)
  
  PRINT *, ''
  PRINT *, 'Verification:'
  IF (ABS(hoop_stress - hoop_theory)/hoop_theory < 1.0e-6_wp) THEN
    PRINT *, '  ✓ Hoop stress matches thin-walled theory'
  ELSE
    PRINT *, '  ✗ Hoop stress mismatch!'
  END IF
  
  IF (ABS(axial_stress - axial_theory)/axial_theory < 1.0e-6_wp) THEN
    PRINT *, '  ✓ Axial stress matches thin-walled theory'
  ELSE
    PRINT *, '  ✗ Axial stress mismatch!'
  END IF
  
  !===========================================================================
  ! Example 2: Parametric study - Effect of diameter-to-thickness ratio
  !===========================================================================
  PRINT *, ''
  PRINT *, 'Example 2: D/t Ratio Study'
  PRINT *, '---------------------------'
  
  INTEGER(i4) :: i
  REAL(wp) :: D_t_ratio
  
  DO i = 1, 5
    SELECT CASE(i)
    CASE(1)
      ! Very thick (D/t = 10)
      t_wall = D_inner / 10.0_wp
      D_outer = D_inner + 2.0_wp*t_wall
    CASE(2)
      ! Thick (D/t = 20)
      t_wall = D_inner / 20.0_wp
      D_outer = D_inner + 2.0_wp*t_wall
    CASE(3)
      ! Moderate (D/t = 40)
      t_wall = D_inner / 40.0_wp
      D_outer = D_inner + 2.0_wp*t_wall
    CASE(4)
      ! Thin (D/t = 60)
      t_wall = D_inner / 60.0_wp
      D_outer = D_inner + 2.0_wp*t_wall
    CASE(5)
      ! Very thin (D/t = 100)
      t_wall = D_inner / 100.0_wp
      D_outer = D_inner + 2.0_wp*t_wall
    END SELECT
    
    D_t_ratio = D_inner / t_wall
    
    ! Recompute section properties
    A  = PI * (D_outer**2 - D_inner**2) / 4.0_wp
    Iy = PI * (D_outer**4 - D_inner**4) / 64.0_wp
    Iz = Iy
    J  = PI * (D_outer**4 - D_inner**4) / 32.0_wp
    
    ! Compute stresses
    hoop_stress = p_internal * D_inner / (2.0_wp * t_wall)
    
    PRINT '(A,I3,A,F8.2,A)', '  D/t = ', INT(D_t_ratio), &
         ': σ_θ = ', hoop_stress/1.0e6_wp, ' MPa'
  END DO
  
  PRINT *, ''
  PRINT *, '=============================================='
  PRINT *, 'B31PIPE Example Complete'
  PRINT *, '=============================================='
  
CONTAINS

  LOGICAL FUNCTION STATUS_SUCCESS(stat)
    TYPE(ErrorStatusType), INTENT(IN) :: stat
    STATUS_SUCCESS = (stat%status_code == IF_STATUS_OK)
  END FUNCTION STATUS_SUCCESS

END PROGRAM B31PIPE_Usage_Example
