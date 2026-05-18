!===============================================================================
! AC2D4 INPUT PARAMETER REFERENCE
! Complete guide to element configuration and usage
! Version: v1.0 (Post-P6 implementation)
!===============================================================================

!==============================================================================
! SECTION 1: MATERIAL PROPERTIES (L3_MD Layer)
!==============================================================================

! TYPE: MD_Mat_Acoustic_Desc
! Usage: CALL MD_Mat_Acoustic_Init(mat_desc, material_type, status)

! Supported materials:
!   'AIR'         - Dry air at 20°C, 1 atm (default)
!   'WATER'       - Pure water at 20°C
!   'STEEL'       - Steel (for FSI problems)
!   'POROUS_FOAM' - Open-cell polyurethane foam

! Key parameters (after initialization):
mat%density_ref           ! Reference density [kg/m³]
mat%bulk_modulus_ref      ! Reference bulk modulus [Pa]
mat%sound_speed_ref       ! Reference sound speed [m/s]
mat%T_ref                 ! Reference temperature [K] (default: 293.15)
mat%P_ref                 ! Reference pressure [Pa] (default: 101325)

! Optional dependencies:
mat%use_temp_dependence   ! Enable temperature dependence (.TRUE./.FALSE.)
mat%alpha_T               ! Thermal expansion coefficient [1/K]
mat%dcdT                  ! Sound speed temperature gradient [m/s/K]

mat%use_pressure_dependence ! Enable pressure dependence
mat%K_prime               ! Pressure derivative of bulk modulus
mat%beta_P                ! Compressibility [1/Pa]

! Porous media (Biot theory):
mat%is_porous_media       ! Porous material flag
mat%porosity              ! φ [0-1] void volume fraction
mat%permeability          ! κ [m²] Darcy permeability
mat%tortuosity            ! τ ≥ 1 flow path tortuosity
mat%viscous_char_length   ! Λ [m] viscous characteristic length
mat%thermal_char_length   ! Λ' [m] thermal characteristic length


!==============================================================================
! SECTION 2: ELEMENT CONFIGURATION (L4_PH Layer)
!==============================================================================

! PH_AC2D4_UEL_Args - Unified argument bundle
elem_args = PH_AC2D4_UEL_Args()

! Computation flags:
elem_args%compute_amatrx   ! Compute tangent stiffness matrix (.TRUE./.FALSE.)
elem_args%compute_rhs      ! Compute residual vector (.TRUE./.FALSE.)
elem_args%compute_mass     ! Compute mass matrix (.TRUE./.FALSE.)
elem_args%mass_method      ! Mass formulation:
                           !   0 = None
                           !   1 = Consistent
                           !   2 = Lumped (HRZ)
                           !   3 = Lumped (RowSum)
                           !   4 = Lumped (Uniform)

elem_args%compute_damping  ! Compute damping matrix (.TRUE./.FALSE.)
elem_args%alpha_M          ! Mass-proportional damping [1/s]
elem_args%beta_K           ! Stiffness-proportional damping [s]

! Step control (from RT_Com_Ctx%lflags):
elem_args%lflags_kstep     ! Current step number

! Output diagnostics:
elem_args%status           ! Error status (required by SIO-03)
elem_args%success          ! Overall success flag
elem_args%pnewdt           ! Suggested time step ratio
elem_args%strain_energy    ! Element strain energy [J]
elem_args%ip_failed        ! IP index where failure occurred
elem_args%total_mass       ! Total element mass [kg]


!==============================================================================
! SECTION 3: UEL INTERFACE SIGNATURE
!==============================================================================

SUBROUTINE PH_AC2D4_UEL_Impl( &
     u,          ! IN:  Nodal pressure DOF [n_dof]
     amatrx,     ! OUT: Tangent stiffness matrix [n_dof, n_dof]
     rhs,        ! OUT: Residual vector [n_dof]
     mass,       ! OUT: Mass matrix [n_dof, n_dof] (optional)
     coords,     ! IN:  Element coordinates [2, 4]
     props,      ! IN:  Material properties [nprops]
     nprops,     ! IN:  Number of material properties
     svars,      ! INOUT: State variables [nsvars_per_ip, n_ips]
     nsvars,     ! IN:  Number of state variables per IP
     args)       ! INOUT: Unified argument bundle

! State variable layout (SVARS):
!   Slot 1-6:  stress        (acoustic stress tensor)
!   Slot 7-12: stran         (acoustic strain)
!   Slot 13:   pressure      (acoustic pressure [Pa])
!   Slot 14:   velocity_potential (velocity potential [m²/s])
!
! For linear acoustics, only slots 13-14 are actively used.


!==============================================================================
! SECTION 4: UNIFIED ANALYSIS CONTEXT (P6-2 Feature)
!==============================================================================

! TYPE: PH_Acoustic_Unified_Analysis_Ctx
! Purpose: Single interface for both frequency and time domain analysis

analysis_ctx = PH_Acoustic_Unified_Analysis_Ctx()

! Common acoustic properties:
analysis_ctx%density         ! ρ [kg/m³]
analysis_ctx%bulk_modulus    ! K [Pa]
analysis_ctx%sound_speed     ! c = √(K/ρ) [m/s]

! Analysis type selector:
analysis_ctx%is_frequency_domain  ! .TRUE.=freq domain, .FALSE.=time domain

! Frequency domain parameters:
analysis_ctx%omega           ! Angular frequency ω [rad/s]
analysis_ctx%frequency       ! Frequency f [Hz]
analysis_ctx%n_frequencies   ! Number of freq points for sweep
analysis_ctx%freq_array(:)   ! Frequency array [n_freqs]

! Time domain parameters:
analysis_ctx%dt              ! Time step [s]
analysis_ctx%t_end           ! End time [s]
analysis_ctx%gamma           ! Newmark γ (default: 0.5)
analysis_ctx%beta            ! Newmark β (default: 0.25)
analysis_ctx%use_hht         ! HHT-α flag (.TRUE./.FALSE.)
analysis_ctx%rho_inf         ! Spectral radius (default: 0.0)

! Thermo-acoustic coupling:
analysis_ctx%use_thermo_coupling  ! Enable temperature dependence
analysis_ctx%T_ref                ! Reference temperature [K]
analysis_ctx%c0_ref               ! Reference sound speed [m/s]
analysis_ctx%T_field(:)           ! Pointer to temperature field [K]

! Porous media (Biot theory):
analysis_ctx%use_porous_media     ! Enable porous model
analysis_ctx%porosity             ! φ [0-1]
analysis_ctx%permeability         ! κ [m²]
analysis_ctx%tortuosity           ! τ

! Absorbing boundaries:
analysis_ctx%use_pml              ! Perfectly Matched Layer
analysis_ctx%use_sommerfeld       ! Sommerfeld radiation condition
analysis_ctx%pml_thickness        ! PML layer thickness [m]


!==============================================================================
! SECTION 5: BOUNDARY CONDITIONS
!==============================================================================

! Essential BC (Dirichlet): p = p̄ on Γ_p
CALL PH_Elem_AC2D4_ApplyEssentialBC(node_list, pressure_value)

! Natural BC (Neumann): ∂p/∂n = q̄ on Γ_q
CALL PH_Elem_AC2D4_ApplyPenaltyBC(edge_nodes, normal_flux)

! Impedance BC: p = Z·v_n on Γ_Z
CALL PH_Elem_AC2D4_FormAcousticImpedance(edge_coords, impedance)

! Radiation BC (Sommerfeld): ∂p/∂n = -ikρcv_n
CALL PH_Elem_AC2D4_Sommerfeld_Radiation(coords, k, normal, p, v, Z_rad)

! PML absorbing boundary:
CALL PH_Elem_AC2D4_PML_Update_State(p, pml_state, sigma, dt)
CALL PH_Elem_AC2D4_PML_Absorbing_Boundary(coords, normal, p, v, pml_state, sigma, dt, F_pml, R)


!==============================================================================
! SECTION 6: LOADS AND EXCITATIONS
!==============================================================================

! Distributed pressure load:
CALL PH_Elem_AC2D4_FormPressureLoad(coords, pressure_mag, edge_id, F_edge)

! Body force (gravity, centrifugal):
CALL PH_Elem_AC2D4_FormBodyForce(coords, body_force_vec, F_body)

! Surface traction:
CALL PH_Elem_AC2D4_FormSurfaceTraction(coords, traction_vec, F_surf)

! Thermo-acoustic source:
CALL PH_Elem_AC2D4_Thermal_Expansion_Source(coords, N, dNdx, T_field, beta, K, F_therm)


!==============================================================================
! SECTION 7: POST-PROCESSING
!==============================================================================

! Recover pressure field:
CALL PH_Elem_AC2D4_CalcPressure(coords, u, p_nodes)

! Compute acoustic intensity (power flux):
CALL PH_Elem_AC2D4_CalcAcousticIntensity(coords, u, omega, I_vector)

! Compute energies:
CALL PH_Elem_AC2D4_CalcEnergy(coords, u, u_dot, KE, PE, SE)

! Output results to file:
CALL PH_Elem_AC2D4_OutputResults(filename, time, u, p_nodes, I_vector)


!==============================================================================
! SECTION 8: PERFORMANCE OPTIMIZATION (P6-1 Features)
!==============================================================================

! Precompute shape functions (HOT_PATH optimization):
CALL PH_Elem_AC2D4_Precompute_Shapes(xi_values, eta_values, n_gauss, &
                                     N_pre, dNdxi_pre, weights)
! Performance gain: +30-50%

! Vectorized B-matrix computation:
CALL PH_Elem_AC2D4_Vectorized_B_Matrix(coords, dNdX, B_matrix, n_ips)
! Performance gain: +2-3×


!==============================================================================
! SECTION 9: COMPLETE WORKFLOW EXAMPLE
!==============================================================================

PROGRAM AC2D4_Complete_Workflow
  USE MD_Mat_Acoustic_Props
  USE PH_Elem_AC2D4_Core
  USE PH_Acoustic_Transient_Solver
  
  ! 1. Initialize material
  TYPE(MD_Mat_Acoustic_Desc) :: mat
  CALL MD_Mat_Acoustic_Init(mat, 'AIR', status)
  
  ! 2. Setup analysis context
  TYPE(PH_Acoustic_Unified_Analysis_Ctx) :: ctx
  ctx%is_frequency_domain = .TRUE.
  ctx%density = mat%density_ref
  ctx%bulk_modulus = mat%bulk_modulus_ref
  ctx%sound_speed = mat%sound_speed_ref
  ctx%frequency = 1000.0_wp
  ctx%omega = 2.0_wp * PI * ctx%frequency
  
  ! 3. Mesh generation (external)
  ! ... generate nodes and elements ...
  
  ! 4. Assembly loop
  DO elem = 1, n_elements
    ! Get element coordinates
    coords = get_element_coords(elem)
    
    ! Call UEL implementation
    CALL PH_AC2D4_UEL_Impl(u_elem, Ke, Fe, Me, coords, &
                          [density, bulk_modulus], 2, svars, 14, args)
    
    ! Assemble to global matrices
    CALL assemble_global(elem, Ke, Me, Fe)
  END DO
  
  ! 5. Apply boundary conditions
  CALL apply_dirichlet_bc(...)
  CALL apply_neumann_bc(...)
  
  ! 6. Solve
  IF (ctx%is_frequency_domain) THEN
    CALL PH_Acoustic_Frequency_Domain_Solve(ctx, M, C, K, F, p)
  ELSE
    CALL PH_Acoustic_NewmarkBeta_SolveStep(ctx, state, M, C, K, F)
  END IF
  
  ! 7. Post-process
  CALL output_results(p)
  
END PROGRAM


!==============================================================================
! SECTION 10: COMMON USE CASES
!==============================================================================

! Case 1: Room acoustics (frequency domain)
!   - Material: AIR
!   - BC: Rigid walls (natural), point source excitation
!   - Output: SPL distribution, frequency response

! Case 2: Thermoacoustic engine
!   - Material: AIR with use_temp_dependence=.TRUE.
!   - Coupling: T_field from thermal solver
!   - Analysis: Transient with adaptive time stepping

! Case 3: Sound absorption in porous material
!   - Material: POROUS_FOAM
!   - Physics: Biot theory (P1/P2/S waves)
!   - Stabilization: SUPG for slow wave

! Case 4: Exterior radiation/scattering
!   - BC: PML or Sommerfeld radiation condition
!   - Domain: Truncated with absorbing layers
!   - Output: Far-field pattern, RCS


!==============================================================================
! END OF INPUT PARAMETER REFERENCE
!==============================================================================
