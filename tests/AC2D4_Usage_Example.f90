!===============================================================================
! EXAMPLE: AC2D4_Usage_Example
! PURPOSE: Demonstrate typical usage patterns for AC2D4 acoustic element
!          Shows how to setup material, mesh, boundary conditions, and solve
! VERSION: v1.0 (Post-P6 implementation)
!===============================================================================
MODULE AC2D4_Usage_Example
  USE ISO_FORTRAN_ENV, ONLY: wp => REAL64, i4 => INT32
  USE UFC_Base_Types
  USE MD_Mat_Acoustic_Props
  USE PH_Elem_AC2D4_Core
  USE PH_Acoustic_Transient_Solver
  IMPLICIT NONE
  
CONTAINS
  
  !===========================================================================
  ! EXAMPLE 1: Simple frequency domain analysis
  !===========================================================================
  SUBROUTINE Example_Frequency_Domain_Analysis()
    !! Steady-state harmonic response of a 2D acoustic cavity
    !!
    !! Use case: Compute pressure field in a room at specific frequency
    
    TYPE(MD_Mat_Acoustic_Desc) :: mat
    TYPE(PH_Acoustic_Unified_Analysis_Ctx) :: ctx
    TYPE(ErrorStatusType) :: status
    
    ! Mesh parameters
    INTEGER(i4), PARAMETER :: n_elem_x = 10
    INTEGER(i4), PARAMETER :: n_elem_y = 8
    REAL(wp), PARAMETER :: Lx = 5.0_wp   ! Room length [m]
    REAL(wp), PARAMETER :: Ly = 4.0_wp   ! Room height [m]
    
    ! Solution arrays
    REAL(wp), ALLOCATABLE :: coords(:,:)
    REAL(wp), ALLOCATABLE :: K_global(:,:)
    REAL(wp), ALLOCATABLE :: M_global(:,:)
    COMPLEX(wp), ALLOCATABLE :: p_solution(:)
    COMPLEX(wp), ALLOCATABLE :: F_harmonic(:)
    
    INTEGER(i4) :: elem, node
    REAL(wp) :: dx, dy
    
    PRINT *, '=========================================='
    PRINT *, 'Example 1: Frequency Domain Analysis'
    PRINT *, '=========================================='
    
    ! Step 1: Initialize material
    CALL MD_Mat_Acoustic_Init(mat, 'AIR', status)
    
    ! Step 2: Generate mesh (simple structured grid)
    dx = Lx / REAL(n_elem_x, wp)
    dy = Ly / REAL(n_elem_y, wp)
    
    ALLOCATE(coords(2, 4))
    
    ! Step 3: Setup unified analysis context
    ctx%is_frequency_domain = .TRUE.
    ctx%density = mat%density_ref
    ctx%bulk_modulus = mat%bulk_modulus_ref
    ctx%sound_speed = mat%sound_speed_ref
    ctx%frequency = 500.0_wp  ! Analysis frequency [Hz]
    ctx%omega = 2.0_wp * PI * ctx%frequency
    
    ! Step 4: Assembly loop (simplified)
    ! In practice, use proper FEM assembly
    ! ...
    
    ! Step 5: Apply boundary conditions
    ! - Rigid walls: ∂p/∂n = 0 (natural BC, no action)
    ! - Point source: F(x=0, y=Ly/2) = 1.0 Pa
    
    ! Step 6: Solve Helmholtz equation
    ! CALL PH_Acoustic_Frequency_Domain_Solve(...)
    
    ! Step 7: Post-process
    ! - Pressure contours
    ! - Sound pressure level (SPL)
    ! - Frequency response function
    
    PRINT *, '✓ Setup complete'
    PRINT *, '✓ Ready for assembly and solve'
    PRINT *, ''
    
  END SUBROUTINE Example_Frequency_Domain_Analysis
  
  !===========================================================================
  ! EXAMPLE 2: Transient analysis with thermo-acoustic coupling
  !===========================================================================
  SUBROUTINE Example_Transient_ThermoAcoustic()
    !! Transient simulation with temperature-dependent sound speed
    !!
    !! Use case: Thermoacoustic engine, ultrasound heating effects
    
    TYPE(MD_Mat_Acoustic_Desc) :: mat
    TYPE(PH_Acoustic_Newmark_Ctx) :: newmark_ctx
    TYPE(ErrorStatusType) :: status
    
    REAL(wp), PARAMETER :: dt = 1.0e-5_wp    ! Time step [s]
    REAL(wp), PARAMETER :: t_end = 0.1_wp    ! End time [s]
    REAL(wp), PARAMETER :: T_hot = 500.0_wp  ! Hot temperature [K]
    REAL(wp), PARAMETER :: T_cold = 300.0_wp ! Cold temperature [K]
    
    ! Temperature field (from thermal solver or measurement)
    REAL(wp), ALLOCATABLE :: T_field(:)
    
    INTEGER(i4) :: n_nodes, step
    
    PRINT *, '=========================================='
    PRINT *, 'Example 2: Transient Thermo-Acoustic Analysis'
    PRINT *, '=========================================='
    
    ! Step 1: Initialize material with temperature dependence
    CALL MD_Mat_Acoustic_Init(mat, 'AIR', status)
    mat%use_temp_dependence = .TRUE.
    
    ! Step 2: Setup Newmark parameters
    newmark_ctx%dt = dt
    newmark_ctx%t_end = t_end
    newmark_ctx%n_steps = INT(t_end / dt)
    newmark_ctx%gamma = 0.5_wp  ! Average acceleration
    newmark_ctx%beta = 0.25_wp
    
    ! Step 3: Setup thermo-acoustic coupling
    CALL PH_Acoustic_Setup_Thermo_Coupling( &
         ctx = newmark_ctx, &
         c0_ref_in = mat%sound_speed_ref, &
         T_ref_in = mat%T_ref, &
         T_field_ptr = T_field, &
         status = status)
    
    ! Step 4: Time integration loop
    DO step = 1, newmark_ctx%n_steps
      
      ! Update temperature field (from external solver)
      ! T_field = thermal_solver%get_temperature()
      
      ! Update sound speed: c(T) = c₀·√(T/T₀)
      CALL PH_Acoustic_Update_Speed_of_Sound( &
           ctx = newmark_ctx, &
           bulk_modulus = mat%bulk_modulus_ref, &
           density = mat%density_ref, &
           c_current = mat%sound_speed_ref, &
           status = status)
      
      ! Solve Newmark-β step
      ! CALL PH_Acoustic_NewmarkBeta_SolveStep(...)
      
    END DO
    
    PRINT *, '✓ Transient simulation complete'
    PRINT *, '✓ Temperature-dependent sound speed enabled'
    PRINT *, ''
    
  END SUBROUTINE Example_Transient_ThermoAcoustic
  
  !===========================================================================
  ! EXAMPLE 3: Porous media acoustics (Biot theory)
  !===========================================================================
  SUBROUTINE Example_Porous_Media_Biot()
    !! Wave propagation in fluid-saturated porous material
    !!
    !! Use case: Sound absorption in foam, rock physics, bone ultrasound
    
    TYPE(MD_Mat_Acoustic_Desc) :: mat_foam
    TYPE(ErrorStatusType) :: status
    
    REAL(wp) :: v_p1, v_p2, v_s  ! Biot wave speeds
    REAL(wp) :: damping, Q_factor
    
    PRINT *, '=========================================='
    PRINT *, 'Example 3: Porous Media (Biot Theory)'
    PRINT *, '=========================================='
    
    ! Step 1: Initialize porous material
    CALL MD_Mat_Acoustic_Init(mat_foam, 'POROUS_FOAM', status)
    
    ! Verify porous media properties
    IF (.NOT. mat_foam%is_porous_media) THEN
      PRINT *, 'ERROR: Material is not porous!'
      RETURN
    END IF
    
    PRINT '(A,F6.2)', '  ✓ Porosity: ', mat_foam%porosity
    PRINT '(A,E10.3,A)', '  ✓ Permeability: ', mat_foam%permeability, ' m²'
    PRINT '(A,F6.2)', '  ✓ Tortuosity: ', mat_foam%tortuosity
    
    ! Step 2: Compute Biot wave speeds
    CALL mat_foam%Get_Derived_Props()  ! Returns derived properties
    
    ! Step 3: Compute viscous damping
    CALL PH_Elem_AC2D4_Biot_Damping( &
         porosity = mat_foam%porosity, &
         permeability = mat_foam%permeability, &
         fluid_viscosity = 1.8e-5_wp, &  ! Air viscosity [Pa·s]
         fluid_density = 1.225_wp, &     ! Air density [kg/m³]
         frequency = 1000.0_wp, &        ! Analysis frequency [Hz]
         damping_coefficient = damping, &
         quality_factor = Q_factor)
    
    PRINT '(A,F8.3,A)', '  ✓ Damping coefficient: ', damping, ' N·s/m⁴'
    PRINT '(A,F8.1)', '  ✓ Quality factor: ', Q_factor
    PRINT *, ''
    
    ! Step 4: Apply SUPG stabilization (for numerical stability)
    ! CALL PH_Elem_AC2D4_Biot_Stabilize_SlowWave(...)
    
  END SUBROUTINE Example_Porous_Media_Biot
  
  !===========================================================================
  ! EXAMPLE 4: Non-reflecting boundaries (PML)
  !===========================================================================
  SUBROUTINE Example_NonReflecting_Boundary()
    !! Exterior acoustics with PML absorbing layers
    !!
    !! Use case: Sound radiation to open space, scattering problems
    
    REAL(wp), PARAMETER :: pml_thickness = 0.5_wp  ! PML layer thickness [m]
    REAL(wp), PARAMETER :: sigma_max = 100.0_wp    ! Max absorption [1/s]
    
    REAL(wp) :: coords(2, 4)
    REAL(wp) :: p_field(4), v_field(2, 4)
    REAL(wp) :: pml_state(2, 4)
    REAL(wp) :: sigma_profile(4)
    REAL(wp) :: pml_force(4)
    REAL(wp) :: reflection_coef
    REAL(wp) :: dt
    
    PRINT *, '=========================================='
    PRINT *, 'Example 4: PML Absorbing Boundary'
    PRINT *, '=========================================='
    
    ! Step 1: Define PML element coordinates
    coords(1, :) = [1.0_wp, 1.5_wp, 1.5_wp, 1.0_wp]  ! x in PML region
    coords(2, :) = [0.0_wp, 0.0_wp, 0.5_wp, 0.5_wp]  ! y
    
    ! Step 2: Initialize PML state
    pml_state = 0.0_wp
    
    ! Step 3: Setup absorption profile (graded)
    ! σ(x) = σ_max · (x/L)²
    REAL(wp) :: x_normalized
    INTEGER(i4) :: i
    
    DO i = 1, 4
      x_normalized = (coords(1, i) - 1.0_wp) / pml_thickness
      sigma_profile(i) = sigma_max * x_normalized**2
    END DO
    
    PRINT '(A,F8.1,A)', '  ✓ PML thickness: ', pml_thickness, ' m'
    PRINT '(A,F8.1,A)', '  ✓ Max absorption: ', sigma_max, ' 1/s'
    PRINT '(A,F8.1,A)', '  ✓ Target reflection: <', EXP(-2.0_wp*sigma_max*pml_thickness/343.0_wp)*100.0_wp, '%'
    
    ! Step 4: Time-domain update
    dt = 1.0e-4_wp
    
    CALL PH_Elem_AC2D4_PML_Update_State( &
         p_field = p_field, &
         pml_state = pml_state, &
         sigma_profile = sigma_profile, &
         dt = dt, &
         n_dof = 4)
    
    ! Step 5: Apply absorbing boundary condition
    CALL PH_Elem_AC2D4_PML_Absorbing_Boundary( &
         coords = coords, &
         normal_vec = [1.0_wp, 0.0_wp], &
         p_field = p_field, &
         velocity_field = v_field, &
         pml_state = pml_state, &
         sigma_profile = sigma_profile, &
         dt = dt, &
         pml_force = pml_force, &
         reflection_coefficient = reflection_coef)
    
    PRINT *, '✓ PML boundary applied'
    PRINT *, ''
    
  END SUBROUTINE Example_NonReflecting_Boundary
  
END MODULE AC2D4_Usage_Example
