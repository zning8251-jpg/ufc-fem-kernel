!===============================================================================
! Module: AC3D4_Advanced_Physics_Test
! Purpose: Test AC3D4 P4 advanced physics (Thermo/Biot/PML)
! Description: Validates temperature dependence, Biot theory, PML boundaries
!===============================================================================

MODULE AC3D4_Advanced_Physics_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Elem_AC3D4_Core
  IMPLICIT NONE
  
CONTAINS

  SUBROUTINE AC3D4_Thermo_Test()
    !! Test P4-1: Thermo-acoustic coupling
    REAL(wp) :: c0, T0, T_current, c_T
    REAL(wp) :: density_ref, sound_speed_ref, bulk_modulus_ref
    REAL(wp) :: density_T, sound_speed_T, bulk_modulus_T
    REAL(wp) :: alpha_T, T_ref
    
    WRITE(*, '(A)') '  Testing temperature-dependent sound speed...'
    
    ! Reference: Air at 20°C (293.15K)
    c0 = 343.0_wp
    T0 = 293.15_wp
    T_current = 373.15_wp  ! 100°C
    
    CALL PH_Elem_AC3D4_Temperature_Dependent_Speed(c0, T0, T_current, c_T)
    
    ! Expected: c(T) = c₀·√(T/T₀) = 343·√(373.15/293.15) ≈ 387 m/s
    REAL(wp) :: expected_c
    expected_c = c0 * SQRT(T_current / T0)
    
    IF (ABS(c_T - expected_c) > 1.0e-6_wp) THEN
      WRITE(*, '(A,F8.2,A,F8.2)') '    FAIL: c(T) =', c_T, ' (expected', expected_c, ')'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Temperature-dependent sound speed: PASSED'
    
    ! Test full material property update
    WRITE(*, '(A)') '  Testing full material property update...'
    
    density_ref = 1.225_wp
    sound_speed_ref = 343.0_wp
    bulk_modulus_ref = density_ref * sound_speed_ref**2
    T_ref = 293.15_wp
    alpha_T = 3.4e-3_wp  ! Air thermal expansion coefficient
    
    CALL PH_Elem_AC3D4_UpdateMaterialProps_TempDep( &
         density_ref, bulk_modulus_ref, sound_speed_ref, &
         T_ref, T_current, alpha_T, &
         density_T, bulk_modulus_T, sound_speed_T)
    
    ! Verify relationships
    IF (density_T >= density_ref) THEN
      WRITE(*, '(A)') '    FAIL: Density should decrease with temperature'
      RETURN
    END IF
    
    IF (sound_speed_T <= sound_speed_ref) THEN
      WRITE(*, '(A)') '    FAIL: Sound speed should increase with temperature'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Material property update: PASSED'
    WRITE(*, '(A)') '  All thermo-acoustic tests PASSED!'
    
  END SUBROUTINE AC3D4_Thermo_Test
  
  SUBROUTINE AC3D4_Biot_Test()
    !! Test P4-2: Biot porous media theory
    REAL(wp) :: porosity, tortuosity, fluid_density, solid_density
    REAL(wp) :: fluid_bulk, solid_bulk, shear_modulus
    REAL(wp) :: fast_wave, slow_wave, shear_wave
    REAL(wp) :: permeability, fluid_viscosity, angular_freq
    REAL(wp) :: damping_coef, stabilization_param
    
    WRITE(*, '(A)') '  Testing Biot wave speeds...'
    
    ! Typical sandstone parameters
    porosity = 0.25_wp
    tortuosity = 1.5_wp
    fluid_density = 1000.0_wp   ! Water
    solid_density = 2650.0_wp   ! Quartz
    fluid_bulk = 2.2e9_wp       ! Water bulk modulus
    solid_bulk = 36.0e9_wp      ! Quartz bulk modulus
    shear_modulus = 12.0e9_wp   ! Frame shear modulus
    
    CALL PH_Elem_AC3D4_Biot_Wave_Speed( &
         porosity, tortuosity, fluid_density, solid_density, &
         fluid_bulk, solid_bulk, shear_modulus, &
         fast_wave, slow_wave, shear_wave)
    
    ! Verify physical constraints
    IF (fast_wave <= 0.0_wp) THEN
      WRITE(*, '(A)') '    FAIL: Fast wave speed must be positive'
      RETURN
    END IF
    
    IF (slow_wave < 0.0_wp) THEN
      WRITE(*, '(A)') '    FAIL: Slow wave speed cannot be negative'
      RETURN
    END IF
    
    IF (shear_wave <= 0.0_wp) THEN
      WRITE(*, '(A)') '    FAIL: Shear wave speed must be positive'
      RETURN
    END IF
    
    ! Fast wave should be fastest
    IF (fast_wave <= shear_wave) THEN
      WRITE(*, '(A)') '    FAIL: Fast wave should be faster than shear wave'
      RETURN
    END IF
    
    WRITE(*, '(A,F8.1,A)') '    V_P1 =', fast_wave, ' m/s'
    WRITE(*, '(A,F8.1,A)') '    V_S =', shear_wave, ' m/s'
    WRITE(*, '(A)') '    ✓ Biot wave speeds: PASSED'
    
    ! Test Biot damping
    WRITE(*, '(A)') '  Testing Biot viscous damping...'
    
    permeability = 1.0e-10_wp    ! 100 mDarcy
    fluid_viscosity = 1.0e-3_wp  ! Water viscosity
    angular_freq = 1000.0_wp     ! 1 kHz
    
    CALL PH_Elem_AC3D4_Biot_Damping( &
         permeability, fluid_viscosity, porosity, tortuosity, &
         angular_freq, damping_coef)
    
    IF (damping_coef <= 0.0_wp) THEN
      WRITE(*, '(A)') '    FAIL: Damping coefficient must be positive'
      RETURN
    END IF
    
    WRITE(*, '(A)') '    ✓ Biot damping: PASSED'
    WRITE(*, '(A)') '  All Biot tests PASSED!'
    
  END SUBROUTINE AC3D4_Biot_Test
  
  SUBROUTINE AC3D4_PML_Test()
    !! Test P4-3: PML absorbing boundary
    REAL(wp) :: coords(3, 4)
    INTEGER(i4) :: face_nodes(3)
    REAL(wp) :: sound_speed, density
    REAL(wp) :: radiation_stiff(4, 4), radiation_damp(4, 4)
    LOGICAL :: pml_flag
    REAL(wp) :: absorption_strength
    REAL(wp) :: pml_stiff(4, 4), pml_damp(4, 4)
    
    WRITE(*, '(A)') '  Testing Sommerfeld radiation condition...'
    
    ! Setup: Regular tetrahedron
    coords(:,1) = [0.0_wp, 0.0_wp, 0.0_wp]
    coords(:,2) = [1.0_wp, 0.0_wp, 0.0_wp]
    coords(:,3) = [0.0_wp, 1.0_wp, 0.0_wp]
    coords(:,4) = [0.0_wp, 0.0_wp, 1.0_wp]
    
    face_nodes = [1, 2, 3]  ! Face on xy-plane
    sound_speed = 343.0_wp
    density = 1.225_wp
    
    CALL PH_Elem_AC3D4_Sommerfeld_Radiation( &
         coords, face_nodes, sound_speed, density, &
         radiation_stiff, radiation_damp)
    
    ! Verify matrices are symmetric
    REAL(wp) :: asymmetry
    INTEGER(i4) :: i, j
    
    asymmetry = 0.0_wp
    DO i = 1, 4
      DO j = 1, 4
        asymmetry = asymmetry + ABS(radiation_stiff(i,j) - radiation_stiff(j,i))
        asymmetry = asymmetry + ABS(radiation_damp(i,j) - radiation_damp(j,i))
      END DO
    END DO
    
    IF (asymmetry > 1.0e-10_wp) THEN
      WRITE(*, '(A,F12.6)') '    FAIL: Radiation matrices not symmetric (asym=', asymmetry, ')'
      RETURN
    END IF
    
    ! Verify diagonal dominance (positive diagonal)
    DO i = 1, 4
      IF (radiation_damp(i,i) <= 0.0_wp .AND. i <= SIZE(face_nodes)) THEN
        WRITE(*, '(A,I2)') '    FAIL: Damping diagonal should be positive at node', i
        RETURN
      END IF
    END DO
    
    WRITE(*, '(A)') '    ✓ Sommerfeld radiation: PASSED'
    
    ! Test PML absorption
    WRITE(*, '(A)') '  Testing PML absorbing boundary...'
    
    pml_flag = .TRUE.
    absorption_strength = 100.0_wp
    
    CALL PH_Elem_AC3D4_PML_Absorbing_Boundary( &
         coords, pml_flag, absorption_strength, &
         pml_stiff, pml_damp)
    
    ! PML damping should be diagonal and positive
    DO i = 1, 4
      IF (pml_damp(i,i) <= 0.0_wp) THEN
        WRITE(*, '(A)') '    FAIL: PML damping should be positive'
        RETURN
      END IF
      
      ! Off-diagonal should be zero (local absorption)
      DO j = 1, 4
        IF (i /= j .AND. ABS(pml_damp(i,j)) > 1.0e-10_wp) THEN
          WRITE(*, '(A)') '    FAIL: PML damping should be diagonal'
          RETURN
        END IF
      END DO
    END DO
    
    WRITE(*, '(A)') '    ✓ PML absorption: PASSED'
    WRITE(*, '(A)') '  All PML tests PASSED!'
    
  END SUBROUTINE AC3D4_PML_Test

END MODULE AC3D4_Advanced_Physics_Test
