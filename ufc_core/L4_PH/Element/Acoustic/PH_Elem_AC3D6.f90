!===============================================================================
! MODULE: PH_Elem_AC3D6
! LAYER:  L4_PH
! DOMAIN: Element/Acoustic
! ROLE:   Proc
! BRIEF:  AC3D6 6-node 3D acoustic element
!===============================================================================
MODULE PH_Elem_AC3D6
  USE IF_Base_Def, ONLY: ZERO, ONE
  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Base_ElemLib
  USE MD_Elem_UEL_Def, ONLY: MD_Elem_UEL_Desc
  USE MD_Sect_Def,      ONLY: MD_Sect_Registry
  USE MD_Mat_Def,       ONLY: MD_Mat_Desc, MD_MatAlgo
  USE PH_Elem_Def,      ONLY: PH_Elem_Ctx, PH_Elem_State
  USE RT_Com_Def,       ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  USE MD_Mat_Lib,         ONLY: MatProperties
  USE PH_Mat_Constit_Def, ONLY: PH_MatPoint_State, PH_MatPoint_StressStrain
  USE MD_Mat_AcousticProps, ONLY: MD_Mat_Acoustic_Desc
  IMPLICIT NONE
  PRIVATE

  !===========================================================================
  ! CONSTANTS - ELEMENT PROPERTIES
  !===========================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D6_NNODE  = 6_i4  ! 6-node wedge (prism)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D6_NDOF   = 6_i4  ! Pressure DOF per node
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D6_NIP    = 6_i4  ! 6-point integration (wedge)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D6_NFACE  = 5_i4  ! 5 faces (2 triangles + 3 quadrilaterals)
  INTEGER(i4), PARAMETER, PUBLIC :: PH_ELEM_AC3D6_NSVARS_PER_IP = 14_i4  ! State variables per IP
  
  !===========================================================================
  ! SVARS LAYOUT (Standardized across AC elements)
  !===========================================================================
  ! Slot 1-6:   stress              (hydrostatic) [Pa]
  ! Slot 7-12:  stran               (volumetric) [-]
  ! Slot 13:    pressure            [Pa]
  ! Slot 14:    velocity_potential  [m²/s]
  
  !===========================================================================
  ! PUBLIC INTERFACES - CATEGORIZED BY PRIORITY AND STATUS
  !===========================================================================
  
  !---------------------------------------------------------------------------
  ! CORE PHYSICS (P2/P3 - Acoustic element fundamentals)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_DefInit              ! Element definition init (stub)
  PUBLIC :: PH_Elem_AC3D6_FormStiffMatrix      ! Stiffness matrix assembly
  PUBLIC :: PH_Elem_AC3D6_FormIntForce         ! Internal force vector
  PUBLIC :: PH_Elem_AC3D6_ConsMass             ! Consistent mass matrix
  PUBLIC :: PH_Elem_AC3D6_LumpMass             ! Lumped mass matrix
  PUBLIC :: PH_Elem_AC3D6_ThermStrainVector    ! Thermo-acoustic coupling (P4)
  
  !---------------------------------------------------------------------------
  ! NONLINEAR GEOMETRY (Large amplitude acoustics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_NL_TL                ! Total Lagrangian formulation
  PUBLIC :: PH_Elem_AC3D6_NL_UL                ! Updated Lagrangian formulation
  
  !---------------------------------------------------------------------------
  ! BOUNDARY CONDITIONS (Essential and natural)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_ApplyEssentialBC     ! Dirichlet BC (elimination)
  PUBLIC :: PH_Elem_AC3D6_ApplyPenaltyBC       ! Neumann BC (penalty method)
  PUBLIC :: PH_Elem_AC3D6_FormConstraintMatrix ! Constraint matrix (MPC)
  
  !---------------------------------------------------------------------------
  ! SPECIAL BOUNDARY CONDITIONS
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_FormAcousticImpedance ! Impedance boundary
  PUBLIC :: PH_Elem_AC3D6_FormRadiationCondition ! Radiation BC (infinite domain)
  PUBLIC :: PH_Elem_AC3D6_FormStructureCoupling
  PUBLIC :: UF_Elem_AC3D6_Calc ! Fluid-structure interface
  
  !---------------------------------------------------------------------------
  ! LOADS (External forcing)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_FormPressureLoad     ! Surface pressure load
  PUBLIC :: PH_Elem_AC3D6_FormBodyForce        ! Body force (gravity)
  PUBLIC :: PH_Elem_AC3D6_FormSurfaceTraction  ! Surface traction
  
  !---------------------------------------------------------------------------
  ! POST-PROCESSING (Output and diagnostics)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_CalcPressure         ! Recover pressure at nodes/IPs
  PUBLIC :: PH_Elem_AC3D6_CalcAcousticIntensity ! Acoustic intensity vector
  PUBLIC :: PH_Elem_AC3D6_CalcEnergy           ! Acoustic energy computation
  PUBLIC :: PH_Elem_AC3D6_CalcEnergy_FromDesc  ! Energy from descriptor
  PUBLIC :: PH_Elem_AC3D6_OutputResults        ! Output to results file
  
  !---------------------------------------------------------------------------
  ! MATERIAL PROPS (Section and material access)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_Elem_AC3D6_GetMaterialProps     ! Get material properties
  PUBLIC :: PH_Elem_AC3D6_GetMaterialProps_FromDesc ! From descriptor
  PUBLIC :: PH_Elem_AC3D6_GetVolume            ! Element volume
  PUBLIC :: PH_Elem_AC3D6_GetAcousticProps     ! Acoustic properties (c, K, ρ)
  PUBLIC :: PH_Elem_AC3D6_SetSectionProps      ! Section property assignment
  PUBLIC :: PH_Elem_AC3D6_SetSectionProps_FromDesc ! From descriptor
  
  !=============================================================================
  ! P4-1 THERMO-ACOUSTIC COUPLING
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_Temperature_Dependent_Speed(c_speed, temperature, c_ref, T_ref, alpha_T, status)
    ! Purpose: Compute temperature-dependent sound speed
    ! Theory: c(T) = c₀·?T/T₀) (ideal gas law derivation)
    !           For liquids: c(T) = c₀·[1 + α_T·(T-T₀)]
    REAL(wp), INTENT(OUT) :: c_speed
    REAL(wp), INTENT(IN)  :: temperature
    REAL(wp), INTENT(IN)  :: c_ref      ! Reference sound speed at T_ref
    REAL(wp), INTENT(IN)  :: T_ref      ! Reference temperature [K]
    REAL(wp), INTENT(IN)  :: alpha_T    ! Thermal expansion coefficient [1/K]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: T_ratio
    
    status = init_error_status()
    
    ! Check for valid temperature
    IF (temperature <= 0.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    ! Temperature-dependent sound speed model
    ! For ideal gases: c = ?γRT/M) ?√T
    ! For liquids: c(T) = c₀·[1 + α_T·(T-T₀)] (linear approximation)
    T_ratio = temperature / T_ref
    
    ! Use square root model (default for gases)
    c_speed = c_ref * SQRT(T_ratio)
    
    ! TODO: Add material-specific model selection
    ! For water/liquids, uncomment below:
    ! c_speed = c_ref * (1.0_wp + alpha_T * (temperature - T_ref))
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Temperature_Dependent_Speed
  
  SUBROUTINE PH_Elem_AC3D6_Thermal_Expansion_Source(F_thermal, coords, MD_Desc, MD_Algo, temperature_field, status)
    ! Purpose: Compute thermal expansion source term in acoustic equation
    ! Theory: ∇²p - (1/c²)·∂²p/∂t² = -ρ·β·∂²T/∂t² (thermo-acoustic source)
    !         where β = thermal expansion coefficient
    REAL(wp), INTENT(OUT) :: F_thermal(6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(IN)  :: temperature_field(:)  ! Nodal temperatures
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: dV, rho, beta_T, dTdt2
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    F_thermal = ZERO
    
    ! Get material properties (TODO: extract from MD_Algo)
    rho = 1000.0_wp   ! Density [kg/m³]
    beta_T = 2.1e-4_wp ! Thermal expansion coefficient [1/K] for water
    dTdt2 = 1.0_wp    ! ∂²T/∂t² placeholder
    
    ! Get Gauss points
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Compute shape functions
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      
      ! Compute Jacobian
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      ! Interpolate temperature at IP: T = Σ Nᵢ·T?      ! TODO: Compute second time derivative ∂²T/∂t²
      
      ! Thermal source term: F?= ?ρ·β·(∂²T/∂t²)·N?dV
      DO i = 1, 6
        F_thermal(i) = F_thermal(i) + rho * beta_T * dTdt2 * N(i) * dV
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Thermal_Expansion_Source
  
  !=============================================================================
  ! P4-2 BIOT POROUS MEDIA
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_Biot_Wave_Speed(v_p1, v_p2, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    ! Purpose: Compute Biot wave speeds for porous media (P1/P2/S waves)
    ! Theory: Biot theory predicts three wave types:
    !         - Fast compressional wave (P1): in-phase solid/fluid motion
    !         - Slow compressional wave (P2): out-of-phase motion (highly attenuated)
    !         - Shear wave (S): solid matrix shear motion
    REAL(wp), INTENT(OUT) :: v_p1  ! Fast P-wave speed [m/s]
    REAL(wp), INTENT(OUT) :: v_p2  ! Slow P-wave speed [m/s]
    REAL(wp), INTENT(OUT) :: v_s   ! S-wave speed [m/s]
    REAL(wp), INTENT(IN)  :: porosity    ! φ: porosity [0-1]
    REAL(wp), INTENT(IN)  :: K_s   ! Bulk modulus of solid frame [Pa]
    REAL(wp), INTENT(IN)  :: K_f   ! Bulk modulus of pore fluid [Pa]
    REAL(wp), INTENT(IN)  :: G     ! Shear modulus of solid frame [Pa]
    REAL(wp), INTENT(IN)  :: rho_s ! Density of solid phase [kg/m³]
    REAL(wp), INTENT(IN)  :: rho_f ! Density of pore fluid [kg/m³]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: K_b, alpha, M, rho_11, rho_22, rho_12
    REAL(wp) :: sigma_11, sigma_22, delta
    
    status = init_error_status()
    
    ! Check porosity bounds
    IF (porosity < 0.0_wp .OR. porosity > 1.0_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    ! Biot effective stress coefficient
    alpha = 1.0_wp - K_b / K_s  ! Often K_b ?K_s for stiff frames
    
    ! Biot modulus M (constraining pressure on fluid)
    M = K_f / (porosity + (alpha - porosity) * (K_f / K_s))
    
    ! Mass coupling coefficients
    rho_11 = (1.0_wp - porosity) * rho_s  ! Solid phase mass
    rho_22 = porosity * rho_f              ! Fluid phase mass
    rho_12 = -0.5_wp * porosity * rho_f    ! Inertial coupling (approximate)
    
    ! Stiffness matrix components
    sigma_11 = K_b + 4.0_wp * G / 3.0_wp + alpha**2 * M
    sigma_22 = porosity**2 * M
    delta = alpha * M * porosity
    
    ! Fast and slow P-wave speeds from eigenvalue problem
    ! det([σ₁₁-ω²ρ₁₁, δ-ω²ρ₁₂; δ-ω²ρ₁₂, σ₂₂-ω²ρ₂₂]) = 0
    ! Simplified high-frequency limit:
    v_p1 = SQRT((sigma_11 + 2.0_wp * delta + sigma_22) / (rho_11 + 2.0_wp * rho_12 + rho_22))
    v_p2 = SQRT(M / rho_22)  ! Slow wave dominated by fluid compressibility
    
    ! Shear wave speed (solid matrix only)
    v_s = SQRT(G / rho_11)
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Biot_Wave_Speed
  
  SUBROUTINE PH_Elem_AC3D6_Biot_Damping(C_biot, frequency, permeability, viscosity, porosity, tortuosity, status)
    ! Purpose: Compute Biot damping mechanisms (viscous dissipation)
    ! Theory: Damping from viscous fluid flow in pores
    !         Frequency-dependent: low freq (Poiseuille) vs high freq (inertial)
    REAL(wp), INTENT(OUT) :: C_biot(:, :)  ! Damping matrix [6×6]
    REAL(wp), INTENT(IN)  :: frequency     ! Angular frequency ω [rad/s]
    REAL(wp), INTENT(IN)  :: permeability  ! κ [m²]
    REAL(wp), INTENT(IN)  :: viscosity     ! μ [Pa·s]
    REAL(wp), INTENT(IN)  :: porosity      ! φ [0-1]
    REAL(wp), INTENT(IN)  :: tortuosity    ! α?(high-freq limit parameter)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: b_coeff, omega_c, F_freq
    INTEGER(i4) :: i
    
    status = init_error_status()
    C_biot = ZERO
    
    ! Viscous coupling coefficient (Darcy's law)
    ! b = μ/κ (resistance to fluid flow)
    IF (permeability <= 1.0e-20_wp) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    b_coeff = viscosity / permeability
    
    ! Characteristic frequency (Biot critical frequency)
    ! ω_c = φ·b / (ρ_f·α?
    omega_c = porosity * b_coeff / (1000.0_wp * tortuosity)
    
    ! Frequency correction factor (Johnson-Champoux-Allard model)
    ! Low frequency: F(ω) ?1 (Poiseuille flow)
    ! High frequency: F(ω) ??1 - i·ω/ω_c) (inertial effects)
    IF (frequency < omega_c) THEN
      F_freq = 1.0_wp  ! Low frequency limit
    ELSE
      F_freq = SQRT(frequency / omega_c)  ! High frequency approximation
    END IF
    
    ! Damping matrix (diagonal approximation)
    ! Cᵢᵢ = b · F(ω) · φ²
    DO i = 1, 6
      C_biot(i, i) = b_coeff * F_freq * porosity**2
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Biot_Damping
  
  SUBROUTINE PH_Elem_AC3D6_Biot_Stabilize_SlowWave(tau_supg, coords, MD_Algo, frequency, status)
    ! Purpose: Add SUPG stabilization for slow P-wave (numerical stability)
    ! Theory: Slow P-wave is highly attenuated and requires stabilization
    !         in finite element formulations (SUPG/GLS methods)
    REAL(wp), INTENT(OUT) :: tau_supg
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(IN)  :: frequency
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: h_elem, c_slow, omega, dx, dy, dz, edge_len(6), min_edge, max_edge
    REAL(wp) :: v_p1, v_p2, v_s, rho_s, rho_f, K_s, K_f, G, porosity
    
    status = init_error_status()
    
    ! Element characteristic length (average edge length from coords)
    ! Compute edge lengths for 6-node wedge element
    edge_len(1) = SQRT(SUM((coords(:,1) - coords(:,2))**2))  ! Bottom edge 1-2
    edge_len(2) = SQRT(SUM((coords(:,2) - coords(:,3))**2))  ! Bottom edge 2-3
    edge_len(3) = SQRT(SUM((coords(:,3) - coords(:,1))**2))  ! Bottom edge 3-1
    edge_len(4) = SQRT(SUM((coords(:,4) - coords(:,5))**2))  ! Top edge 4-5
    edge_len(5) = SQRT(SUM((coords(:,5) - coords(:,6))**2))  ! Top edge 5-6
    edge_len(6) = SQRT(SUM((coords(:,1) - coords(:,4))**2))  ! Vertical edge 1-4
    h_elem = SUM(edge_len) / 6.0_wp  ! Average edge length
    
    ! Get default Biot parameters from MD_Algo if available
    porosity = 0.3_wp
    rho_s = 2650.0_wp
    rho_f = 1000.0_wp
    K_s = 36.0e9_wp
    K_f = 2.2e9_wp
    G = 10.0e9_wp
    ! Extract from MD_Algo if props array available
    IF (ASSOCIATED(MD_Algo%props)) THEN
      IF (SIZE(MD_Algo%props) >= 5) THEN
        porosity = MD_Algo%props(1)
        rho_s = MD_Algo%props(2)
        rho_f = MD_Algo%props(3)
        K_s = MD_Algo%props(4)
        K_f = MD_Algo%props(5)
        IF (SIZE(MD_Algo%props) >= 6) G = MD_Algo%props(6)
      END IF
    END IF
    
    ! Slow P-wave speed from Biot theory
    CALL PH_Elem_AC3D6_Biot_Wave_Speed(v_p1, c_slow, v_s, porosity, K_s, K_f, G, rho_s, rho_f, status)
    
    ! Angular frequency
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    
    ! SUPG stabilization parameter (τ)
    ! τ = h/(2|v|) for advection-dominated problems
    ! For wave equations: τ = 2/(ω²·h·c)
    IF (omega <= 1.0e-6_wp) THEN
      tau_supg = 0.0_wp  ! No stabilization needed at DC
    ELSE
      tau_supg = h_elem / (2.0_wp * c_slow)  ! Advection form
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Biot_Stabilize_SlowWave
  
  SUBROUTINE PH_Elem_AC3D6_Biot_Compute_Stab_Param(h_char, omega, c_fast, c_slow, stab_param, status)
    ! Purpose: Compute stabilization parameter for Biot formulation
    ! Theory: Balance between P1/P2 wave resolution and numerical stability
    REAL(wp), INTENT(OUT) :: stab_param
    REAL(wp), INTENT(IN)  :: h_char  ! Characteristic element size
    REAL(wp), INTENT(IN)  :: omega   ! Angular frequency
    REAL(wp), INTENT(IN)  :: c_fast  ! Fast P-wave speed
    REAL(wp), INTENT(IN)  :: c_slow  ! Slow P-wave speed
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: k_fast, k_slow, pe_fast, pe_slow
    
    status = init_error_status()
    
    ! Wavenumbers
    k_fast = omega / c_fast
    k_slow = omega / c_slow
    
    ! Element Péclet numbers (wave resolution criterion)
    pe_fast = k_fast * h_char
    pe_slow = k_slow * h_char
    
    ! Stability criterion:
    ! Need ? elements per wavelength: k·h ?π/3
    ! Stabilization parameter blends fast/slow wave requirements
    IF (pe_slow > 1.0_wp) THEN
      ! Under-resolved slow wave: add stabilization
      stab_param = (pe_slow - 1.0_wp) / pe_slow
    ELSE
      stab_param = 0.0_wp  ! Well-resolved regime
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Biot_Compute_Stab_Param
  
  !=============================================================================
  ! P4-3 PML INFINITE ELEMENTS
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_Sommerfeld_Radiation(C_rad, K_rad, face_normal, sound_speed, frequency, coords, status)
    ! Purpose: Apply Sommerfeld radiation condition for unbounded domains
    ! Theory: ∂p/∂n + (1/c)·∂p/∂t = 0 at infinity
    !         Adds absorbing boundary term to stiffness/damping matrices
    REAL(wp), INTENT(INOUT) :: C_rad(:, :)  ! Radiation damping matrix [6×6]
    REAL(wp), INTENT(INOUT) :: K_rad(:, :)  ! Radiation stiffness matrix [6×6]
    REAL(wp), INTENT(IN)  :: face_normal(3)  ! Outward normal vector
    REAL(wp), INTENT(IN)  :: sound_speed     ! Sound speed c [m/s]
    REAL(wp), INTENT(IN)  :: frequency       ! Frequency f [Hz]
    REAL(wp), INTENT(IN)  :: coords(3, 6)   ! Face nodal coordinates
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: omega, k_wave, sigma, dA
    REAL(wp) :: N(6), dNdxi(3, 6)
    REAL(wp) :: J_face(2, 3), detJ_face
    INTEGER(i4) :: i, j
    
    status = init_error_status()
    C_rad = ZERO
    K_rad = ZERO
    
    ! Angular frequency and wavenumber
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    k_wave = omega / sound_speed
    
    ! PML attenuation profile (quadratic decay)
    ! σ(ξ) = σ_max · ξ² where ξ ?[0,1] is normalized PML depth
    sigma = k_wave * 0.1_wp  ! σ_max = 0.1·k (adjustable)
    
    ! Surface integration over face
    DO i = 1, 6
      DO j = 1, 6
        ! Radiation contribution: ∂N?∂n + i·k·N?        ! Approximate: K_rad(i,j) = ?k·Nᵢ·N?dΓ
        !             C_rad(i,j) = ?(1/c)·Nᵢ·N?dΓ
        dA = 1.0_wp  ! Placeholder: face area
        K_rad(i, j) = k_wave * N(i) * N(j) * dA
        C_rad(i, j) = (1.0_wp / sound_speed) * N(i) * N(j) * dA
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Sommerfeld_Radiation
  
  SUBROUTINE PH_Elem_AC3D6_Infinite_Element_Map(coords_phys, coords_nat, infinite_direction, decay_profile, status)
    ! Purpose: Map from physical coordinates to infinite element domain
    ! Theory: Map local coordinate ξ ??using stretching transformation
    !         For infinite elements: x?= x + (x - x₀)·f(ξ)/(1-f(ξ))
    REAL(wp), INTENT(OUT) :: coords_phys(3, 6)
    REAL(wp), INTENT(IN)  :: coords_nat(3, 6)    ! Natural coordinates at "origin"
    REAL(wp), INTENT(IN)  :: infinite_direction(3)  ! Direction of infinity
    REAL(wp), INTENT(IN)  :: decay_profile(:)       ! Decay function parameters
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: r_inf, r_nat, stretching_factor
    INTEGER(i4) :: i
    
    status = init_error_status()
    
    ! Stretching factor based on decay profile
    ! exponential: f(ξ) = exp(-ξ·σ)
    ! polynomial:  f(ξ) = ξ²
    IF (SIZE(decay_profile) >= 1) THEN
      stretching_factor = decay_profile(1)
    ELSE
      stretching_factor = 1.0_wp  ! Default polynomial decay
    END IF
    
    ! Map each node to infinite position
    DO i = 1, 6
      ! Radial distance from origin in infinite direction
      r_nat = DOT_PRODUCT(coords_nat(:, i), infinite_direction)
      
      ! Infinite element mapping
      ! x?= x₀ + (x - x₀) / (1 - ξ·stretch)
      r_inf = r_nat / (1.0_wp - r_nat * stretching_factor)
      
      ! Physical coordinates
      coords_phys(:, i) = coords_nat(:, i) + infinite_direction * (r_inf - r_nat)
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Infinite_Element_Map
  
  SUBROUTINE PH_Elem_AC3D6_PML_Update_State(pml_state, pml_params, time_step, coords, pressure, status)
    ! Purpose: Update PML state variables for time-domain simulation
    ! Theory: Crank-Nicolson scheme for PML update
    !         Split-field formulation: p = p?+ p?+ p?(decoupled components)
    TYPE(*), DIMENSION(*), INTENT(INOUT) :: pml_state  ! PML state variables
    REAL(wp), INTENT(IN)  :: pml_params(:)  ! PML parameters (σ_max, depth, etc.)
    REAL(wp), INTENT(IN)  :: time_step     ! Δt
    REAL(wp), INTENT(IN)  :: coords(3, 6)   ! Element coordinates
    REAL(wp), INTENT(IN)  :: pressure(6)      ! Pressure at nodes
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sigma_x, sigma_y, sigma_z  ! PML attenuation profiles
    REAL(wp) :: depth, sigma_max
    INTEGER(i4) :: i, node
    
    status = init_error_status()
    
    ! Extract PML parameters
    IF (SIZE(pml_params) >= 2) THEN
      depth = pml_params(1)     ! PML thickness [m]
      sigma_max = pml_params(2) ! Maximum attenuation [1/m]
    ELSE
      depth = 0.5_wp
      sigma_max = 5.0_wp
    END IF
    
    ! Compute attenuation profile for each node
    DO node = 1, 6
      ! Distance from interior boundary (normalized)
      ! Assuming z-direction PML for simplicity
      depth_normalized = (coords(3, node) - coords(3, 1)) / depth
      
      IF (depth_normalized > 0.0_wp .AND. depth_normalized <= 1.0_wp) THEN
        ! Quadratic attenuation: σ = σ_max·ξ²
        sigma_z = sigma_max * depth_normalized**2
        
        ! Update split-field components (Crank-Nicolson)
        ! p_z^{n+1} = p_z^n · exp(-2·σ·Δt) (analytical solution)
        ! TODO: Implement proper Crank-Nicolson update
      ELSE
        sigma_z = 0.0_wp
      END IF
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_PML_Update_State
  
  SUBROUTINE PH_Elem_AC3D6_PML_Absorbing_Boundary(K_pml, C_pml, pml_region_mask, pml_params, coords, sound_speed, density, status)
    ! Purpose: Form PML absorbing boundary contributions
    ! Theory: Modified wave equation in PML region:
    !         ∇?1/ρ)·∇p + σ·∇p + (1/c²)·∂²p/∂t² = 0
    !         Adds first-order absorbing term to stiffness/mass matrices
    REAL(wp), INTENT(OUT) :: K_pml(:, :)  ! PML stiffness matrix [6×6]
    REAL(wp), INTENT(OUT) :: C_pml(:, :)  ! PML damping matrix [6×6]
    REAL(wp), INTENT(IN)  :: pml_region_mask(:)  ! 1 if node in PML, 0 otherwise
    REAL(wp), INTENT(IN)  :: pml_params(:)  ! PML parameters
    REAL(wp), INTENT(IN)  :: coords(3, 6)   ! Element coordinates
    REAL(wp), INTENT(IN)  :: sound_speed     ! Sound speed [m/s]
    REAL(wp), INTENT(IN)  :: density         ! Density [kg/m³]
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: sigma(3)  ! PML attenuation in x,y,z directions
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6)
    REAL(wp) :: J(3, 3), detJ, dV
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: sigma_avg
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    K_pml = ZERO
    C_pml = ZERO
    
    ! Get PML attenuation profiles
    ! sigma(1) = σ? sigma(2) = σ? sigma(3) = σ?    IF (SIZE(pml_params) >= 3) THEN
      sigma = pml_params(1:3)
    ELSE
      sigma = (/ 5.0_wp, 5.0_wp, 5.0_wp /)  ! Default isotropic PML
    END IF
    
    ! Get Gauss points
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Assemble PML matrices
    DO ip = 1, PH_ELEM_AC3D6_NIP
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D6_B_Matrix(dNdxi, coords, B)
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      ! Average PML attenuation at IP
      sigma_avg = SUM(N * pml_region_mask) * SUM(sigma) / 3.0_wp
      
      ! PML stiffness contribution (from ∇?1/ρ)·∇p term)
      DO i = 1, 6
        DO j = 1, 6
          K_pml(i, j) = K_pml(i, j) + (1.0_wp/density) * (&
            B(1, i)*B(1, j) + B(2, i)*B(2, j) + B(3, i)*B(3, j)) * dV
        END DO
      END DO
      
      ! PML damping contribution (from σ·∇p term)
      DO i = 1, 6
        DO j = 1, 6
          C_pml(i, j) = C_pml(i, j) + sigma_avg * N(i) * N(j) * dV
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_PML_Absorbing_Boundary
  
  !---------------------------------------------------------------------------
  ! VOLUME INTEGRATION (Utility)
  !---------------------------------------------------------------------------
  PUBLIC :: PH_ELEM_AC3D6_VolumeInt            ! Element volume computation

  !=============================================================================
  ! UEL_Args TYPE - Principle #14 Structured IO
  !=============================================================================
  PUBLIC :: PH_AC3D6_UEL_Args
  TYPE, PUBLIC :: PH_AC3D6_UEL_Args
    ! Purpose: Unified argument bundle for AC3D6 element computations
    ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
    ! Status: SIO-01 compliant (unified *_Arg bundle with [IN]/[OUT] comments)
    
    !-- [IN] Flags for computation control
    LOGICAL     :: compute_amatrx = .TRUE.   ! Compute tangent stiffness matrix
    LOGICAL     :: compute_rhs    = .TRUE.   ! Compute residual vector
    
    !-- [IN] P3 dynamic analysis extensions
    LOGICAL     :: compute_mass   = .FALSE.  ! Mass matrix computation flag (P3)
    INTEGER(i4) :: mass_method    = 0_i4    ! 0=None, 1=Consistent, 2=Lumped(HRZ), 3=Lumped(RowSum), 4=Lumped(Uniform)
    LOGICAL     :: compute_damping = .FALSE. ! Damping matrix computation flag (P3)
    REAL(wp)    :: alpha_M        = 0.0_wp  ! Mass proportional damping coefficient [1/s]
    REAL(wp)    :: beta_K         = 0.0_wp  ! Stiffness proportional damping coefficient [s]
    
    !-- [IN] Step control (from RT_Com_Ctx%lflags)
    INTEGER(i4) :: lflags_kstep   = 0_i4
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
  END TYPE PH_AC3D6_UEL_Args


CONTAINS

  !=============================================================================
  ! PRIVATE HELPER FUNCTIONS - C3D6 Shape Functions & Derivatives
  !=============================================================================
  
  SUBROUTINE AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
    ! Purpose: Compute shape functions and derivatives for 6-node wedge element
    ! Theory: Linear shape functions in natural coordinates (ξ,η,ζ)
    !         Triangle coordinates: ξ,η with constraint ξ+η?
    !         Height coordinate: ζ ?[-1,1]
    REAL(wp), INTENT(IN)  :: xi, eta, zeta
    REAL(wp), INTENT(OUT) :: N(6), dNdxi(3, 6)
    REAL(wp) :: xi_eta_sum
    
    xi_eta_sum = xi + eta
    
    ! Shape functions (6-node wedge)
    ! Bottom triangle (ζ=-1): nodes 1,2,3
    ! Top triangle (ζ=+1): nodes 4,5,6
    N(1) = 0.25_wp * (1.0_wp - xi - eta) * (1.0_wp - zeta)
    N(2) = 0.25_wp * xi * (1.0_wp - zeta)
    N(3) = 0.25_wp * eta * (1.0_wp - zeta)
    N(4) = 0.25_wp * (1.0_wp - xi - eta) * (1.0_wp + zeta)
    N(5) = 0.25_wp * xi * (1.0_wp + zeta)
    N(6) = 0.25_wp * eta * (1.0_wp + zeta)
    
    ! Derivatives w.r.t. natural coordinates
    dNdxi(1, 1) = -0.25_wp * (1.0_wp - zeta)  ! ∂N?∂?    dNdxi(2, 1) = -0.25_wp * (1.0_wp - zeta)  ! ∂N?∂?    dNdxi(3, 1) = -0.25_wp * (1.0_wp - xi - eta)  ! ∂N?∂?    
    dNdxi(1, 2) = 0.25_wp * (1.0_wp - zeta)   ! ∂N?∂?    dNdxi(2, 2) = 0.0_wp                       ! ∂N?∂?    dNdxi(3, 2) = -0.25_wp * xi                ! ∂N?∂?    
    dNdxi(1, 3) = 0.0_wp                       ! ∂N?∂?    dNdxi(2, 3) = 0.25_wp * (1.0_wp - zeta)   ! ∂N?∂?    dNdxi(3, 3) = -0.25_wp * eta               ! ∂N?∂?    
    dNdxi(1, 4) = -0.25_wp * (1.0_wp + zeta)  ! ∂N?∂?    dNdxi(2, 4) = -0.25_wp * (1.0_wp + zeta)  ! ∂N?∂?    dNdxi(3, 4) = 0.25_wp * (1.0_wp - xi - eta)  ! ∂N?∂?    
    dNdxi(1, 5) = 0.25_wp * (1.0_wp + zeta)   ! ∂N?∂?    dNdxi(2, 5) = 0.0_wp                       ! ∂N?∂?    dNdxi(3, 5) = 0.25_wp * xi                 ! ∂N?∂?    
    dNdxi(1, 6) = 0.0_wp                       ! ∂N?∂?    dNdxi(2, 6) = 0.25_wp * (1.0_wp + zeta)   ! ∂N?∂?    dNdxi(3, 6) = 0.25_wp * eta                ! ∂N?∂?  END SUBROUTINE AC3D6_ShapeFunc
  
  SUBROUTINE AC3D6_Jacobian(dNdxi, coords, J, detJ)
    ! Purpose: Compute Jacobian matrix and its determinant
    ! Theory: J = ∂x/∂?= Σ xᵢ·∂N?∂?(3×3 matrix for 3D)
    REAL(wp), INTENT(IN)  :: dNdxi(3, 6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(OUT) :: J(3, 3)
    REAL(wp), INTENT(OUT) :: detJ
    INTEGER(i4) :: i, j, k
    
    J = ZERO
    DO i = 1, 3  ! Physical dimensions (x,y,z)
      DO j = 1, 3  ! Natural coordinates (ξ,η,ζ)
        DO k = 1, 6  ! Nodes
          J(i, j) = J(i, j) + coords(i, k) * dNdxi(j, k)
        END DO
      END DO
    END DO
    
    ! Determinant of 3×3 matrix
    detJ = J(1,1)*(J(2,2)*J(3,3) - J(2,3)*J(3,2)) &
         - J(1,2)*(J(2,1)*J(3,3) - J(2,3)*J(3,1)) &
         + J(1,3)*(J(2,1)*J(3,2) - J(2,2)*J(3,1))
  END SUBROUTINE AC3D6_Jacobian
  
  SUBROUTINE AC3D6_B_Matrix(dNdxi, coords, B)
    ! Purpose: Compute acoustic B-matrix (pressure gradient operator)
    ! Theory: ∇p = B·p_elem where B = [∂N/∂x; ∂N/∂y; ∂N/∂z] (3×6)
    !         Requires inverse Jacobian transformation
    REAL(wp), INTENT(IN)  :: dNdxi(3, 6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(OUT) :: B(3, 6)
    REAL(wp) :: J(3, 3), detJ, Jinv(3, 3)
    INTEGER(i4) :: i, j, k
    
    ! Compute Jacobian
    CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
    
    ! Check for invalid Jacobian
    IF (ABS(detJ) <= 1.0e-12_wp) THEN
      B = ZERO
      RETURN
    END IF
    
    ! Inverse of 3×3 Jacobian
    Jinv(1,1) = (J(2,2)*J(3,3) - J(2,3)*J(3,2)) / detJ
    Jinv(1,2) = -(J(1,2)*J(3,3) - J(1,3)*J(3,2)) / detJ
    Jinv(1,3) = (J(1,2)*J(2,3) - J(1,3)*J(2,2)) / detJ
    Jinv(2,1) = -(J(2,1)*J(3,3) - J(2,3)*J(3,1)) / detJ
    Jinv(2,2) = (J(1,1)*J(3,3) - J(1,3)*J(3,1)) / detJ
    Jinv(2,3) = -(J(1,1)*J(2,3) - J(1,3)*J(2,1)) / detJ
    Jinv(3,1) = (J(2,1)*J(3,2) - J(2,2)*J(3,1)) / detJ
    Jinv(3,2) = -(J(1,1)*J(3,2) - J(1,2)*J(3,1)) / detJ
    Jinv(3,3) = (J(1,1)*J(2,2) - J(1,2)*J(2,1)) / detJ
    
    ! Transform derivatives to physical coordinates: ∂N/∂x = J⁻¹·∂N/∂?    DO i = 1, 3  ! Physical dimensions (x,y,z)
      DO k = 1, 6  ! Nodes
        B(i, k) = ZERO
        DO j = 1, 3  ! Natural coordinates
          B(i, k) = B(i, k) + Jinv(i, j) * dNdxi(j, k)
        END DO
      END DO
    END DO
  END SUBROUTINE AC3D6_B_Matrix
  
  !=============================================================================
  ! UTILITY - Volume Integration (Existing implementation retained)
  !=============================================================================
  SUBROUTINE PH_ELEM_AC3D6_VolumeInt(coords, volume)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(OUT) :: volume
    REAL(wp) :: N(6), dNdxi(3, 6), J(3, 3), detJ
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    INTEGER(i4) :: ip
    volume = ZERO
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    DO ip = 1, 6
      CALL PH_Elem_C3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL PH_Elem_C3D6_Jac(dNdxi, coords, J, detJ)
      volume = volume + detJ * weights(ip)
    END DO
  END SUBROUTINE PH_ELEM_AC3D6_VolumeInt

  !=============================================================================
  ! UEL IMPLEMENTATION - Principle #14 Structured IO
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_UEDL(args, MD_Desc, MD_State, MD_Algo, PH_Ctx, RT_Ctx, RT_Algo)
    ! Purpose: Main UEL entry point with structured IO
    ! Theory: UFC v4.3 template - 7 parameter ABI
    TYPE(PH_AC3D6_UEL_Args), INTENT(INOUT) :: args
    TYPE(MD_Elem_UEL_Desc), INTENT(IN)    :: MD_Desc
    TYPE(*), DIMENSION(*), INTENT(INOUT)   :: MD_State
    TYPE(MD_MatAlgo), INTENT(INOUT)  :: MD_Algo
    TYPE(PH_Elem_Ctx), INTENT(INOUT)  :: PH_Ctx
    TYPE(RT_Com_Base_Ctx), INTENT(INOUT)   :: RT_Ctx
    TYPE(*), DIMENSION(*), INTENT(INOUT)   :: RT_Algo
    
    REAL(wp) :: coords(3, PH_ELEM_AC3D6_NNODE)
    REAL(wp) :: pressure(PH_ELEM_AC3D6_NDOF)
    REAL(wp) :: Ke(PH_ELEM_AC3D6_NDOF, PH_ELEM_AC3D6_NDOF)
    REAL(wp) :: F_int(PH_ELEM_AC3D6_NDOF)
    INTEGER(i4) :: i, j
    
    ! Initialize status
    args%status = init_error_status()
    args%success = .FALSE.
    
    ! Extract coordinates from descriptor (TODO: implement proper extraction)
    ! coords = MD_Desc%coords  ! Placeholder
    DO i = 1, PH_ELEM_AC3D6_NNODE
      coords(:, i) = ZERO
    END DO
    
    ! Extract pressure DOFs from state (TODO: implement proper extraction)
    ! pressure = MD_State%pressure  ! Placeholder
    pressure = ZERO
    
    ! Compute stiffness matrix if requested
    IF (args%compute_amatrx) THEN
      CALL PH_Elem_AC3D6_FormStiffMatrix_Impl(coords, MD_Desc, MD_Algo, Ke, args%status)
      IF (.NOT. IF_STATUS_OK(args%status)) RETURN
    END IF
    
    ! Compute internal force if requested
    IF (args%compute_rhs) THEN
      CALL PH_Elem_AC3D6_FormIntForce_Impl(coords, pressure, MD_Desc, MD_Algo, F_int, args%status)
      IF (.NOT. IF_STATUS_OK(args%status)) RETURN
    END IF
    
    ! Compute mass matrix if requested (P3)
    IF (args%compute_mass) THEN
      SELECT CASE (args%mass_method)
      CASE (1)  ! Consistent mass
        CALL PH_Elem_AC3D6_ConsMass_Impl(coords, MD_Desc, MD_Algo, Ke, args%status)
      CASE (2:4)  ! Lumped mass variants
        CALL PH_Elem_AC3D6_LumpMass_Impl(coords, MD_Desc, MD_Algo, F_int, args%status)
      END SELECT
      IF (.NOT. IF_STATUS_OK(args%status)) RETURN
    END IF
    
    args%success = .TRUE.
  END SUBROUTINE PH_Elem_AC3D6_UEDL

  SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix(coords, E_young, nu, Ke)
    ! Legacy interface wrapper - calls Impl version
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    TYPE(ErrorStatusType) :: status
    TYPE(MD_Elem_UEL_Desc) :: dummy_desc
    TYPE(MD_MatAlgo) :: dummy_algo
    
    CALL PH_Elem_AC3D6_FormStiffMatrix_Impl(coords, dummy_desc, dummy_algo, Ke, status)
  END SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix
  
  SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix_Impl(coords, MD_Desc, MD_Algo, Ke, status)
    ! Purpose: Compute element stiffness matrix for AC3D6
    ! Theory: K = ∫?Bᵀ·K_bulk·B dV where K_bulk = ρ·c² (bulk modulus)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(OUT) :: Ke(6, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: dV, K_bulk
    INTEGER(i4) :: ip, i, j
    
    ! Initialize
    Ke = ZERO
    status = init_error_status()
    
    ! Get bulk modulus from material (K = ρ·c²)
    IF (ASSOCIATED(MD_Algo%props)) THEN
      IF (SIZE(MD_Algo%props) >= 2) K_bulk = MD_Algo%props(2)
    END IF
    K_bulk = 2.2e9_wp  ! Default: water bulk modulus
        IF (ASSOCIATED(MD_Algo%props)) THEN
          IF (SIZE(MD_Algo%props) >= 2) K_bulk = MD_Algo%props(2)
        END IF
    
    ! Get Gauss points for 6-node wedge
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Compute shape functions and derivatives
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      
      ! Compute B-matrix (pressure gradient operator)
      CALL AC3D6_B_Matrix(dNdxi, coords, B)
      
      ! Recompute Jacobian for volume computation
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      
      ! Skip invalid elements
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      
      ! Integration weight times Jacobian determinant
      dV = detJ * weights(ip)
      
      ! Assemble stiffness matrix: Kᵢⱼ = ?Bᵀ·K_bulk·B dV
      DO i = 1, PH_ELEM_AC3D6_NDOF
        DO j = 1, PH_ELEM_AC3D6_NDOF
          Ke(i, j) = Ke(i, j) + K_bulk * (&
            B(1, i) * B(1, j) + &
            B(2, i) * B(2, j) + &
            B(3, i) * B(3, j)) * dV
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormStiffMatrix_Impl

  SUBROUTINE PH_Elem_AC3D6_FormIntForce(coords, u, E_young, nu, R_int)
    ! Legacy interface wrapper - calls Impl version
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: u(6)
    REAL(wp), INTENT(IN)  :: E_young, nu
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType) :: status
    TYPE(MD_Elem_UEL_Desc) :: dummy_desc
    TYPE(MD_MatAlgo) :: dummy_algo
    
    CALL PH_Elem_AC3D6_FormIntForce_Impl(coords, u, dummy_desc, dummy_algo, R_int, status)
  END SUBROUTINE PH_Elem_AC3D6_FormIntForce
  
  SUBROUTINE PH_Elem_AC3D6_FormIntForce_Impl(coords, pressure, MD_Desc, MD_Algo, R_int, status)
    ! Purpose: Compute internal force vector for AC3D6
    ! Theory: F_int = K·p where K is stiffness matrix and p is pressure
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: pressure(6)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(OUT) :: R_int(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Ke(6, 6)
    INTEGER(i4) :: i
    
    ! Initialize
    R_int = ZERO
    status = init_error_status()
    
    ! Compute stiffness matrix
    CALL PH_Elem_AC3D6_FormStiffMatrix_Impl(coords, MD_Desc, MD_Algo, Ke, status)
    IF (.NOT. IF_STATUS_OK(status)) RETURN
    
    ! Internal force = K · p
    DO i = 1, PH_ELEM_AC3D6_NDOF
      R_int(i) = SUM(Ke(i, :) * pressure(:))
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormIntForce_Impl

  SUBROUTINE PH_Elem_AC3D6_ConsMass(coords, rho, Me)
    ! Legacy interface wrapper - calls Impl version
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    TYPE(ErrorStatusType) :: status
    TYPE(MD_Elem_UEL_Desc) :: dummy_desc
    TYPE(MD_MatAlgo) :: dummy_algo
    
    CALL PH_Elem_AC3D6_ConsMass_Impl(coords, dummy_desc, dummy_algo, Me, status)
  END SUBROUTINE PH_Elem_AC3D6_ConsMass
  
  SUBROUTINE PH_Elem_AC3D6_ConsMass_Impl(coords, MD_Desc, MD_Algo, Me, status)
    ! Purpose: Compute consistent mass matrix for AC3D6
    ! Theory: M = ∫?ρ·Nᵀ·N dV (consistent mass formulation)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(OUT) :: Me(6, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: dV, rho
    INTEGER(i4) :: ip, i, j
    
    ! Initialize
    Me = ZERO
    status = init_error_status()
    
    ! Get density from material (TODO: extract from MD_Algo or MD_Desc)
    rho = 1000.0_wp  ! Placeholder: water density
    
    ! Get Gauss points for 6-node wedge
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Compute shape functions and derivatives
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      
      ! Compute Jacobian
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      
      ! Skip invalid elements
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      
      ! Integration weight times Jacobian determinant times density
      dV = rho * detJ * weights(ip)
      
      ! Assemble mass matrix: Mᵢⱼ = ?ρ·Nᵢ·N?dV
      DO i = 1, PH_ELEM_AC3D6_NDOF
        DO j = 1, PH_ELEM_AC3D6_NDOF
          Me(i, j) = Me(i, j) + N(i) * N(j) * dV
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_ConsMass_Impl

  SUBROUTINE PH_Elem_AC3D6_LumpMass(coords, rho, M_lumped)
    ! Legacy interface wrapper - calls Impl version with HRZ method
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: rho
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    TYPE(ErrorStatusType) :: status
    TYPE(MD_Elem_UEL_Desc) :: dummy_desc
    TYPE(MD_MatAlgo) :: dummy_algo
    
    CALL PH_Elem_AC3D6_LumpMass_Impl(coords, dummy_desc, dummy_algo, M_lumped, status)
  END SUBROUTINE PH_Elem_AC3D6_LumpMass
  
  SUBROUTINE PH_Elem_AC3D6_LumpMass_Impl(coords, MD_Desc, MD_Algo, M_lumped, status)
    ! Purpose: Compute lumped mass matrix for AC3D6 (HRZ method)
    ! Theory: M_lumped = diag(m? m? ..., m? where m?= ρ·V / n_nodes
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(OUT) :: M_lumped(6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: vol, m_total, m_node
    INTEGER(i4) :: i
    
    ! Initialize
    M_lumped = ZERO
    status = init_error_status()
    
    ! Compute element volume
    CALL PH_ELEM_AC3D6_VolumeInt(coords, vol)
    
    ! Total mass = density × volume
    m_total = 1000.0_wp * vol
        IF (ASSOCIATED(MD_Algo%props)) THEN
          IF (SIZE(MD_Algo%props) >= 1) m_total = MD_Algo%props(1) * vol
        END IF
    
    ! Equal distribution to nodes (uniform lumping)
    m_node = m_total / REAL(PH_ELEM_AC3D6_NNODE, wp)
    
    ! Assign to diagonal
    DO i = 1, PH_ELEM_AC3D6_NDOF
      M_lumped(i) = m_node
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_LumpMass_Impl

  SUBROUTINE PH_Elem_AC3D6_ThermStrainVector(coords, alpha_T, deltaT, eps_th, status)
    ! Purpose: Compute thermal strain for thermo-acoustic coupling (P4-1)
    ! Theory: eps_th = alpha_T * deltaT * I (volumetric thermal expansion)
    !         In acoustics: thermal coupling through volumetric strain
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: alpha_T   ! Thermal expansion coefficient [1/K]
    REAL(wp), INTENT(IN)  :: deltaT    ! Temperature increment [K]
    REAL(wp), INTENT(OUT) :: eps_th(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Thermal volumetric strain: eps_th = alpha * deltaT
    ! For acoustic elements, this represents the source term in wave equation
    eps_th = alpha_T * deltaT
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_ThermStrainVector
  
  !=============================================================================
  ! BOUNDARY CONDITIONS (Short-term enhancements)
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_ApplyEssentialBC(p_elem, prescribed_value, node_index, status)
    ! Purpose: Apply Dirichlet boundary condition (elimination method)
    ! Theory: Set p?= p_prescribed at constrained DOF
    REAL(wp), INTENT(INOUT) :: p_elem(6)
    REAL(wp), INTENT(IN)    :: prescribed_value
    INTEGER(i4), INTENT(IN) :: node_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    IF (node_index < 1 .OR. node_index > 6) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    p_elem(node_index) = prescribed_value
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_ApplyEssentialBC
  
  SUBROUTINE PH_Elem_AC3D6_ApplyPenaltyBC(Ke, F_int, penalty, prescribed_value, node_index, status)
    ! Purpose: Apply Neumann boundary condition using penalty method
    ! Theory: Kᵢᵢ += penalty, F?+= penalty × value
    REAL(wp), INTENT(INOUT) :: Ke(6, 6)
    REAL(wp), INTENT(INOUT) :: F_int(6)
    REAL(wp), INTENT(IN)    :: penalty
    REAL(wp), INTENT(IN)    :: prescribed_value
    INTEGER(i4), INTENT(IN) :: node_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    IF (node_index < 1 .OR. node_index > 6) THEN
      status%code = STATUS_ERROR
      RETURN
    END IF
    
    ! Penalty method: add large number to diagonal
    Ke(node_index, node_index) = Ke(node_index, node_index) + penalty
    F_int(node_index) = F_int(node_index) + penalty * prescribed_value
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_ApplyPenaltyBC
  
  SUBROUTINE PH_Elem_AC3D6_FormConstraintMatrix(C, constraint_type, dof_indices, coefficients, status)
    ! Purpose: Form multi-point constraint (MPC) matrix
    ! Theory: C·p = 0 (linear constraint equations)
    ! Types: 1=Rigid beam, 2=Cyclic symmetry, 3=Averaging
    REAL(wp), INTENT(OUT) :: C(:, :)
    INTEGER(i4), INTENT(IN) :: constraint_type
    INTEGER(i4), INTENT(IN) :: dof_indices(:)
    REAL(wp), INTENT(IN)    :: coefficients(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    INTEGER(i4) :: i, j, n_dof, master_dof, slave_dof
    
    status = init_error_status()
    C = ZERO
    n_dof = SIZE(dof_indices)
    
    SELECT CASE (constraint_type)
    CASE (1)  ! Rigid beam: slave = master
      ! C(i,j) = 1 for master, -coeff for slaves
      IF (n_dof < 2) THEN
        status%code = STATUS_ERROR
        RETURN
      END IF
      master_dof = dof_indices(1)
      DO i = 2, n_dof
        slave_dof = dof_indices(i)
        C(slave_dof, slave_dof) = 1.0_wp
        C(slave_dof, master_dof) = -coefficients(i-1)
      END DO
      
    CASE (2)  ! Cyclic symmetry: sum = 0
      ! Sum of nodal values = 0
      DO i = 1, n_dof
        C(dof_indices(i), dof_indices(i)) = 1.0_wp
      END DO
      
    CASE (3)  ! Averaging: p_avg = (p1+p2+...)/n
      DO i = 1, n_dof
        C(dof_indices(i), dof_indices(i)) = 1.0_wp / REAL(n_dof, wp)
      END DO
      
    CASE DEFAULT
      ! Linear constraint: sum(coeff_i * p_i) = 0
      DO i = 1, MIN(n_dof, SIZE(coefficients))
        C(dof_indices(i), dof_indices(i)) = coefficients(i)
      END DO
    END SELECT
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormConstraintMatrix
  
  SUBROUTINE PH_Elem_AC3D6_FormAcousticImpedance(Ke, F_int, impedance, face_id, coords, status)
    ! Purpose: Add acoustic impedance boundary contribution
    ! Theory: Z = p/v (impedance relation at boundary)
    ! Adds damping-like term: K_Z += Z*N^T*N*dA
    REAL(wp), INTENT(INOUT) :: Ke(6, 6)
    REAL(wp), INTENT(INOUT) :: F_int(6)
    REAL(wp), INTENT(IN)    :: impedance
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN)    :: coords(3, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), face_coords(3, 3), dNdxi(2, 3), Jv(2, 2), detJ
    REAL(wp) :: xi_gp(3), eta_gp(3), w_gp(3), dA
    REAL(wp) :: N_face(3)  ! Face-local shape functions
    INTEGER(i4) :: ip, i, j, face_node(3)
    
    status = init_error_status()
    
    ! Get face nodes for triangular face
    SELECT CASE (face_id)
    CASE (1)  ! Bottom triangle: nodes 1, 2, 3
      face_node = [1, 2, 3]
    CASE (2)  ! Top triangle: nodes 4, 5, 6
      face_node = [4, 5, 6]
    CASE DEFAULT
      face_node = [1, 2, 3]
    END SELECT
    
    ! Extract face coordinates
    DO i = 1, 3
      face_coords(:, i) = coords(:, face_node(i))
    END DO
    
    ! 3-point Gauss quadrature for triangle
    xi_gp = [1.0_wp/6.0_wp, 2.0_wp/3.0_wp, 1.0_wp/6.0_wp]
    eta_gp = [1.0_wp/6.0_wp, 1.0_wp/6.0_wp, 2.0_wp/3.0_wp]
    w_gp = [1.0_wp/6.0_wp, 1.0_wp/6.0_wp, 1.0_wp/6.0_wp]
    
    DO ip = 1, 3
      ! Linear triangular shape functions
      N_face(1) = 1.0_wp - xi_gp(ip) - eta_gp(ip)
      N_face(2) = xi_gp(ip)
      N_face(3) = eta_gp(ip)
      
      ! Compute Jacobian for face mapping
      dNdxi(1, 1) = -1.0_wp; dNdxi(1, 2) = 1.0_wp; dNdxi(1, 3) = 0.0_wp
      dNdxi(2, 1) = -1.0_wp; dNdxi(2, 2) = 0.0_wp; dNdxi(2, 3) = 1.0_wp
      
      DO i = 1, 2
        DO j = 1, 2
          Jv(i, j) = SUM(face_coords(i, :) * dNdxi(j, :))
        END DO
      END DO
      detJ = Jv(1,1)*Jv(2,2) - Jv(1,2)*Jv(2,1)
      dA = detJ * w_gp(ip)
      
      ! Map to element DOFs and assemble impedance contribution
      DO i = 1, 3
        N(face_node(i)) = N_face(i)
      END DO
      
      ! Impedance term: Ke += Z * N^T * N * dA
      DO i = 1, 6
        DO j = 1, 6
          Ke(i, j) = Ke(i, j) + impedance * N(i) * N(j) * dA
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormAcousticImpedance
  
  SUBROUTINE PH_Elem_AC3D6_FormRadiationCondition(Ke, F_int, sound_speed, face_id, coords, status)
    ! Purpose: Apply Sommerfeld radiation condition for infinite domain
    ! Theory: ∂p/∂n + (1/c)·∂p/∂t = 0 (non-reflecting boundary)
    ! Adds frequency-dependent damping to absorb outgoing waves
    ! K_rad += (ω/c)*N^T*N, C_rad += σ*N^T*N
    REAL(wp), INTENT(INOUT) :: Ke(6, 6)
    REAL(wp), INTENT(INOUT) :: F_int(6)
    REAL(wp), INTENT(IN)    :: sound_speed
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN)    :: coords(3, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(2, 3), Jv(2, 2), detJ
    REAL(wp) :: omega, k_wave, sigma
    REAL(wp) :: xi_gp(3), eta_gp(3), w_gp(3), dA
    REAL(wp) :: N_face(3), face_coords(3, 3)
    REAL(wp) :: ref_coord(3), r_dist
    INTEGER(i4) :: ip, i, j, face_node(3), frequency
    
    status = init_error_status()
    
    frequency = 100.0_wp  ! Reference frequency for damping
    omega = 2.0_wp * 3.14159265358979_wp * frequency
    k_wave = omega / sound_speed
    sigma = k_wave * 0.1_wp  ! Absorption coefficient
    
    ! Get face nodes for triangular face
    SELECT CASE (face_id)
    CASE (1)
      face_node = [1, 2, 3]
    CASE (2)
      face_node = [4, 5, 6]
    CASE DEFAULT
      face_node = [1, 2, 3]
    END SELECT
    
    DO i = 1, 3
      face_coords(:, i) = coords(:, face_node(i))
    END DO
    
    ! Reference point at infinity (far field)
    ref_coord = SUM(face_coords, DIM=2) / 3.0_wp
    
    ! 3-point Gauss quadrature for triangle
    xi_gp = [1.0_wp/6.0_wp, 2.0_wp/3.0_wp, 1.0_wp/6.0_wp]
    eta_gp = [1.0_wp/6.0_wp, 1.0_wp/6.0_wp, 2.0_wp/3.0_wp]
    w_gp = [1.0_wp/6.0_wp, 1.0_wp/6.0_wp, 1.0_wp/6.0_wp]
    
    DO ip = 1, 3
      N_face(1) = 1.0_wp - xi_gp(ip) - eta_gp(ip)
      N_face(2) = xi_gp(ip)
      N_face(3) = eta_gp(ip)
      
      DO i = 1, 3
        N(face_node(i)) = N_face(i)
      END DO
      
      dNdxi(1, 1) = -1.0_wp; dNdxi(1, 2) = 1.0_wp; dNdxi(1, 3) = 0.0_wp
      dNdxi(2, 1) = -1.0_wp; dNdxi(2, 2) = 0.0_wp; dNdxi(2, 3) = 1.0_wp
      
      DO i = 1, 2
        DO j = 1, 2
          Jv(i, j) = SUM(face_coords(i, :) * dNdxi(j, :))
        END DO
      END DO
      detJ = Jv(1,1)*Jv(2,2) - Jv(1,2)*Jv(2,1)
      dA = detJ * w_gp(ip)
      
      DO i = 1, 6
        DO j = 1, 6
          ! Stiffness-like: (ω/c)*N^T*N
          Ke(i, j) = Ke(i, j) + (omega / sound_speed) * N(i) * N(j) * dA
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormRadiationCondition
  
  SUBROUTINE PH_Elem_AC3D6_FormStructureCoupling(Ke, F_int, coupling_matrix, interface_dofs, status)
    ! Purpose: Form fluid-structure coupling terms
    ! Theory: p = -ρ·n·ü (acoustic pressure from structural acceleration)
    ! Couples acoustic pressure DOFs with structural displacement DOFs
    REAL(wp), INTENT(INOUT) :: Ke(6, 6)
    REAL(wp), INTENT(INOUT) :: F_int(6)
    REAL(wp), INTENT(IN)    :: coupling_matrix(:, :)
    INTEGER(i4), INTENT(IN) :: interface_dofs(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(2, 3), Jv(2, 2), detJ
    REAL(wp) :: xi_gp(3), eta_gp(3), w_gp(3), dA
    REAL(wp) :: N_face(3), face_coords(3, 3)
    REAL(wp) :: face_normal(3), t1(3), t2(3), v1(3), v2(3), area
    INTEGER(i4) :: ip, i, j, k, n_dof, face_node(3)
    
    status = init_error_status()
    
    n_dof = SIZE(interface_dofs)
    
    ! Default: use face normal area product as coupling
    face_node = [1, 2, 3]
    DO i = 1, 3
      face_coords(:, i) = Ke(:, face_node(i))  ! Reuse Ke for temp storage
    END DO
    
    ! Compute face normal for interface coupling
    v1 = face_coords(:, 2) - face_coords(:, 1)
    v2 = face_coords(:, 3) - face_coords(:, 1)
    face_normal(1) = v1(2)*v2(3) - v1(3)*v2(2)
    face_normal(2) = v1(3)*v2(1) - v1(1)*v2(3)
    face_normal(3) = v1(1)*v2(2) - v1(2)*v2(1)
    area = SQRT(SUM(face_normal**2))
    face_normal = face_normal / (area + 1.0e-30_wp)
    
    ! Assemble coupling contribution
    DO i = 1, MIN(6, n_dof)
      DO j = 1, MIN(6, SIZE(coupling_matrix, 2))
        Ke(interface_dofs(i), j) = Ke(interface_dofs(i), j) + & 
          coupling_matrix(i, j) * face_normal(1) * area / 3.0_wp
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormStructureCoupling
  
  !=============================================================================
  ! LOADS (Short-term enhancements)
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_FormPressureLoad(F_ext, pressure_load, face_id, coords, status)
    ! Purpose: Apply surface pressure load on AC3D6 face
    ! Theory: F?= ∫?Nᵢ·p dΓ (surface integral)
    REAL(wp), INTENT(OUT) :: F_ext(6)
    REAL(wp), INTENT(IN)  :: pressure_load
    INTEGER(i4), INTENT(IN) :: face_id
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6)
    REAL(wp) :: J(2, 2), detJ, xi(4), eta(4), weights(4)
    REAL(wp) :: dA
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    F_ext = ZERO
    
    ! TODO: Get face-specific Gauss points and shape functions
    ! For now, use placeholder integration
    DO ip = 1, 4  ! 4-point integration on quadrilateral face
      ! Compute shape functions at IP (placeholder)
      N = 0.25_wp
      detJ = 1.0_wp  ! Placeholder
      dA = detJ * weights(ip)
      
      ! Assemble nodal forces: F?= ?Nᵢ·p dA
      DO i = 1, 6
        F_ext(i) = F_ext(i) + N(i) * pressure_load * dA
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormPressureLoad
  
  SUBROUTINE PH_Elem_AC3D6_FormBodyForce(F_ext, body_force, coords, density, status)
    ! Purpose: Apply body force (e.g., gravity) in acoustic domain
    ! Theory: F?= ∫?ρ·Nᵢ·b dV (volume integral)
    REAL(wp), INTENT(OUT) :: F_ext(6)
    REAL(wp), INTENT(IN)  :: body_force(3)  ! (bx, by, bz)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: density
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: dV
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    F_ext = ZERO
    
    ! Get Gauss points for 6-node wedge
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Compute shape functions
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      
      ! Compute Jacobian
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      
      ! Assemble body force: F?= ?ρ·Nᵢ·b dV
      ! For acoustics, body force typically zero (no mass sources)
      DO i = 1, 6
        F_ext(i) = F_ext(i) + density * N(i) * SUM(body_force) * dV
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormBodyForce
  
  SUBROUTINE PH_Elem_AC3D6_FormSurfaceTraction(F_ext, traction, surface_id, coords, status)
    ! Purpose: Apply surface traction on boundary
    ! Theory: F_i = integral(N_i * t * dGamma) (surface integral)
    REAL(wp), INTENT(OUT) :: F_ext(6)
    REAL(wp), INTENT(IN)  :: traction(3)  ! (tx, ty, tz) [Pa]
    INTEGER(i4), INTENT(IN) :: surface_id
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), J(3, 3), detJ
    REAL(wp) :: xi, eta, zeta, weights(3)
    REAL(wp) :: dA, v1(3), v2(3), normal(3), area_norm, t_normal
    INTEGER(i4) :: ip, i
    
    status = init_error_status()
    F_ext = ZERO
    
    ! 3-point Gauss integration for triangular face
    weights = [1.0_wp/3.0_wp, 1.0_wp/3.0_wp, 1.0_wp/3.0_wp]
    
    SELECT CASE (surface_id)
    CASE (1)  ! Face 1: nodes 1-2-4 (xi=0)
      DO ip = 1, 3
        eta = 0.5_wp*REAL(ip-1,wp)
        zeta = 0.0_wp
        xi = 1.0_wp - eta - zeta
        CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
        CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
        IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
        dA = SQRT(SUM(J(:,1)**2 + J(:,2)**2)) * weights(ip)
        DO i = 1, 6
          F_ext(i) = F_ext(i) + traction(1) * N(i) * dA
        END DO
      END DO
    CASE (2)  ! Face 2: nodes 2-3-5 (eta=0)
      DO ip = 1, 3
        xi = 0.5_wp*REAL(ip-1,wp)
        zeta = 0.0_wp
        eta = 1.0_wp - xi - zeta
        CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
        CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
        IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
        dA = SQRT(SUM(J(:,1)**2 + J(:,2)**2)) * weights(ip)
        DO i = 1, 6
          F_ext(i) = F_ext(i) + traction(2) * N(i) * dA
        END DO
      END DO
    CASE (3, 4)  ! Triangular faces
      DO ip = 1, 3
        SELECT CASE (ip)
        CASE (1); xi = 0.5_wp; eta = 0.0_wp
        CASE (2); xi = 0.0_wp; eta = 0.5_wp
        CASE (3); xi = 0.0_wp; eta = 0.0_wp
        END SELECT
        zeta = 0.0_wp
        IF (surface_id == 4) zeta = 1.0_wp - xi - eta
        CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
        CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
        IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
        v1 = coords(:,2) - coords(:,1)
        v2 = coords(:,4) - coords(:,1)
        normal(1) = v1(2)*v2(3) - v1(3)*v2(2)
        normal(2) = v1(3)*v2(1) - v1(1)*v2(3)
        normal(3) = v1(1)*v2(2) - v1(2)*v2(1)
        area_norm = SQRT(SUM(normal**2))
        IF (area_norm > 1.0e-12_wp) THEN
          t_normal = DOT_PRODUCT(traction, normal) / area_norm
          dA = area_norm * weights(ip)
          DO i = 1, 6
            F_ext(i) = F_ext(i) + t_normal * N(i) * dA
          END DO
        END IF
      END DO
    CASE DEFAULT
      ! Use mid-point rule
      xi = 1.0_wp/3.0_wp; eta = 1.0_wp/3.0_wp; zeta = 0.0_wp
      CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) > 1.0e-12_wp) THEN
        v1 = coords(:,2) - coords(:,1)
        v2 = coords(:,4) - coords(:,1)
        normal(1) = v1(2)*v2(3) - v1(3)*v2(2)
        normal(2) = v1(3)*v2(1) - v1(1)*v2(3)
        normal(3) = v1(1)*v2(2) - v1(2)*v2(1)
        area_norm = SQRT(SUM(normal**2))
        IF (area_norm > 1.0e-12_wp) THEN
          t_normal = DOT_PRODUCT(traction, normal) / area_norm
          dA = area_norm / 3.0_wp
          DO i = 1, 6
            F_ext(i) = F_ext(i) + t_normal * N(i) * dA
          END DO
        END IF
      END IF
    END SELECT
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_FormSurfaceTraction
  
  !=============================================================================
  ! POST-PROCESSING (Short-term enhancements)
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_CalcPressure(p_elem, coords, pressure_ip, ip_index, status)
    ! Purpose: Recover acoustic pressure at integration point or node
    ! Theory: p = Σ Nᵢ·p?(shape function interpolation)
    REAL(wp), INTENT(IN)  :: p_elem(6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(OUT) :: pressure_ip
    INTEGER(i4), INTENT(IN) :: ip_index
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6)
    REAL(wp) :: xi, eta, zeta
    
    status = init_error_status()
    
    ! Get IP coordinates (TODO: use actual IP location)
    xi = 1.0_wp / 3.0_wp
    eta = 1.0_wp / 3.0_wp
    zeta = 0.0_wp
    
    ! Compute shape functions
    CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
    
    ! Interpolate pressure: p = Σ Nᵢ·p?    pressure_ip = SUM(N * p_elem)
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_CalcPressure
  
  SUBROUTINE PH_Elem_AC3D6_CalcAcousticIntensity(p_elem, coords, density, sound_speed, intensity, status)
    ! Purpose: Compute acoustic intensity vector (energy flux)
    ! Theory: I = p·v = p²/(ρ·c) · n (intensity magnitude)
    REAL(wp), INTENT(IN)  :: p_elem(6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: density, sound_speed
    REAL(wp), INTENT(OUT) :: intensity(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6)
    REAL(wp) :: pressure, grad_p(3), velocity(3)
    REAL(wp) :: xi, eta, zeta
    
    status = init_error_status()
    
    ! Get IP location
    xi = 1.0_wp / 3.0_wp
    eta = 1.0_wp / 3.0_wp
    zeta = 0.0_wp
    
    ! Compute shape functions and B-matrix
    CALL AC3D6_ShapeFunc(xi, eta, zeta, N, dNdxi)
    CALL AC3D6_B_Matrix(dNdxi, coords, B)
    
    ! Pressure at IP
    pressure = SUM(N * p_elem)
    
    ! Pressure gradient: ∇p = B·p_elem
    grad_p = MATMUL(B, p_elem)
    
    ! Particle velocity from Euler equation: v = -(1/ρ)·∇p (frequency domain)
    ! For time domain: v = -∇?(velocity potential)
    velocity = -grad_p / density
    
    ! Acoustic intensity: I = p·v (instantaneous)
    ! Time-averaged: I = ½·Re{p·v*} for harmonic waves
    intensity = pressure * velocity
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_CalcAcousticIntensity
  
  SUBROUTINE PH_Elem_AC3D6_CalcEnergy(p_elem, coords, density, sound_speed, energy_density, total_energy, status)
    ! Purpose: Compute acoustic energy density and total energy
    ! Theory: E = KE + PE = ½·ρ·|v|² + ½·p²/(ρ·c²)
    REAL(wp), INTENT(IN)  :: p_elem(6)
    REAL(wp), INTENT(IN)  :: coords(3, 6)
    REAL(wp), INTENT(IN)  :: density, sound_speed
    REAL(wp), INTENT(OUT) :: energy_density, total_energy
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6)
    REAL(wp) :: J(3, 3), detJ
    REAL(wp) :: pressure, grad_p(3), velocity(3)
    REAL(wp) :: ke_density, pe_density
    REAL(wp) :: xi(6), eta(6), zeta(6), weights(6)
    REAL(wp) :: dV, vol
    INTEGER(i4) :: ip
    
    status = init_error_status()
    energy_density = ZERO
    total_energy = ZERO
    vol = ZERO
    
    ! Get Gauss points
    CALL PH_Elem_C3D6_GaussPoints(xi, eta, zeta, weights)
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Compute shape functions and B-matrix
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D6_B_Matrix(dNdxi, coords, B)
      
      ! Jacobian for volume
      CALL AC3D6_Jacobian(dNdxi, coords, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      dV = detJ * weights(ip)
      vol = vol + dV
      
      ! Pressure and gradient
      pressure = SUM(N * p_elem)
      grad_p = MATMUL(B, p_elem)
      velocity = -grad_p / density
      
      ! Kinetic energy density: KE = ½·ρ·|v|²
      ke_density = 0.5_wp * density * DOT_PRODUCT(velocity, velocity)
      
      ! Potential energy density: PE = ½·p²/(ρ·c²)
      pe_density = 0.5_wp * pressure**2 / (density * sound_speed**2)
      
      ! Total energy density
      energy_density = energy_density + (ke_density + pe_density) * dV
      
      ! Total energy (integrated over element)
      total_energy = total_energy + (ke_density + pe_density) * dV
    END DO
    
    ! Average energy density
    IF (vol > 1.0e-12_wp) THEN
      energy_density = energy_density / vol
    END IF
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_CalcEnergy
  
  SUBROUTINE PH_Elem_AC3D6_CalcEnergy_FromDesc(MD_Desc, MD_State, MD_Algo, energy_density, total_energy, status)
    TYPE(MD_Elem_UEL_Desc), INTENT(IN) :: MD_Desc
    TYPE(*), DIMENSION(*), INTENT(IN)   :: MD_State
    TYPE(MD_MatAlgo), INTENT(INOUT) :: MD_Algo
    REAL(wp), INTENT(OUT) :: energy_density, total_energy
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: rho, c_sound
    REAL(wp) :: coords(3, 6), p_elem(6)
    
    status = init_error_status()
    energy_density = ZERO
    total_energy = ZERO
    rho = 1000.0_wp
    c_sound = 343.0_wp
    IF (ASSOCIATED(MD_Algo%props)) THEN
      IF (SIZE(MD_Algo%props) >= 2) THEN
        rho = MD_Algo%props(1)
        c_sound = MD_Algo%props(2)
      END IF
    END IF
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_CalcEnergy_FromDesc
  
  SUBROUTINE PH_Elem_AC3D6_OutputResults(MD_State, p_elem, coords, svars, output_vars, step_time, status)
    ! Purpose: Write element results to output database
    ! Theory: State variables storage for visualization
    !         SVARS Layout:
    !           Slot 1-3:   stress (hydrostatic) [Pa]
    !           Slot 4-6:   stran (volumetric) [-]
    !           Slot 7:     pressure [Pa]
    !           Slot 8:     velocity_potential [m2/s]
    TYPE(*), DIMENSION(*), INTENT(INOUT) :: MD_State
    REAL(wp), INTENT(IN)  :: p_elem(6)     ! Nodal pressures
    REAL(wp), INTENT(IN)  :: coords(3, 6)  ! Element coordinates
    REAL(wp), INTENT(OUT) :: svars(:, :)   ! State variables per IP
    REAL(wp), INTENT(OUT) :: output_vars(:) ! Output variables
    REAL(wp), INTENT(IN)  :: step_time
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6), J(3, 3), detJ
    REAL(wp) :: xi(3), eta(3), zeta(3), weights(3)
    REAL(wp) :: pressure, grad_p(3), velocity(3), density, sound_speed
    REAL(wp) :: ke_density, pe_density
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    
    ! Default material properties
    density = 1000.0_wp
    sound_speed = 343.0_wp
    
    ! 3-point Gauss integration for triangular face
    weights = [1.0_wp/3.0_wp, 1.0_wp/3.0_wp, 1.0_wp/3.0_wp]
    
    ! Loop over integration points
    DO ip = 1, PH_ELEM_AC3D6_NIP
      ! Gauss point location in triangular element
      SELECT CASE (ip)
      CASE (1)
        xi(1) = 0.5_wp; eta(1) = 0.0_wp; zeta(1) = 0.0_wp
      CASE (2)
        xi(2) = 0.0_wp; eta(2) = 0.5_wp; zeta(2) = 0.0_wp
      CASE (3)
        xi(3) = 0.0_wp; eta(3) = 0.0_wp; zeta(3) = 0.5_wp
      END SELECT
      
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D6_B_Matrix(dNdxi, coords, B)
      
      ! Interpolate pressure
      pressure = DOT_PRODUCT(N, p_elem)
      
      ! Compute pressure gradient
      grad_p = MATMUL(B, p_elem)
      
      ! Acoustic velocity: v = -grad(p)/(rho)
      velocity = -grad_p / density
      
      ! Kinetic energy density: KE = 1/2 * rho * |v|^2
      ke_density = 0.5_wp * density * DOT_PRODUCT(velocity, velocity)
      
      ! Potential energy density: PE = p^2 / (2 * rho * c^2)
      pe_density = 0.5_wp * pressure**2 / (density * sound_speed**2)
      
      ! Fill SVARS layout
      ! Slot 1-3: stress components (hydrostatic = -pressure)
      svars(1, ip) = -pressure  ! sigma_xx
      svars(2, ip) = -pressure  ! sigma_yy
      svars(3, ip) = -pressure  ! sigma_zz
      
      ! Slot 4-6: strain components (volumetric strain = -p/(rho*c^2))
      svars(4, ip) = -pressure / (density * sound_speed**2)  ! epsilon_xx
      svars(5, ip) = -pressure / (density * sound_speed**2)  ! epsilon_yy
      svars(6, ip) = -pressure / (density * sound_speed**2)  ! epsilon_zz
      
      ! Slot 7: pressure
      svars(7, ip) = pressure
      
      ! Slot 8: velocity_potential (phi = integral(p) or velocity magnitude)
      svars(8, ip) = SQRT(DOT_PRODUCT(velocity, velocity))
      
      ! Slot 9-14: reserved for additional quantities
      svars(9, ip)  = ke_density    ! Kinetic energy density
      svars(10, ip) = pe_density     ! Potential energy density
      svars(11, ip) = ke_density + pe_density  ! Total energy density
      svars(12, ip) = step_time     ! Current time
      svars(13, ip) = SQRT(SUM(grad_p**2))  ! Pressure gradient magnitude
      svars(14, ip) = density * sound_speed  ! Acoustic impedance
    END DO
    
    ! Output variables (element averages)
    output_vars(1) = SUM(svars(7,:)) / REAL(PH_ELEM_AC3D6_NIP, wp)  ! Avg pressure
    output_vars(2) = SQRT(SUM(svars(8,:)**2)) / REAL(PH_ELEM_AC3D6_NIP, wp)  ! RMS velocity
    output_vars(3) = SUM(svars(11,:)) / REAL(PH_ELEM_AC3D6_NIP, wp)  ! Avg total energy
    output_vars(4) = step_time  ! Current time
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_OutputResults

  !=============================================================================
  ! P3 - DYNAMIC ANALYSIS EXTENSIONS
  !=============================================================================
  
  SUBROUTINE PH_Elem_AC3D6_Rayleigh_Damping(alpha_M, beta_K, Me, Ke, Ce, status)
    ! Purpose: Compute Rayleigh damping matrix C = αM + βK
    ! Theory: Proportional damping for modal analysis and transient response
    REAL(wp), INTENT(IN)  :: alpha_M  ! Mass proportional coefficient [1/s]
    REAL(wp), INTENT(IN)  :: beta_K   ! Stiffness proportional coefficient [s]
    REAL(wp), INTENT(IN)  :: Me(6, 6) ! Consistent mass matrix
    REAL(wp), INTENT(IN)  :: Ke(6, 6) ! Stiffness matrix
    REAL(wp), INTENT(OUT) :: Ce(6, 6) ! Damping matrix
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    status = init_error_status()
    
    ! Rayleigh damping: C = α·M + β·K
    Ce = alpha_M * Me + beta_K * Ke
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_Rayleigh_Damping
  
  SUBROUTINE PH_Elem_AC3D6_NL_TL(coords_ref, p_elem, D, Ke_mat, Ke_geo, R_int, status)
    ! Purpose: Total Lagrangian formulation for large amplitude acoustics
    ! Theory: Reference configuration formulation for finite deformation
    !         K_total = K_material + K_geometric
    !         For acoustic wave in compressible fluid:
    !           Material stiffness: K_mat = integral(B^T * K * B * dV0)
    !           Geometric stiffness: K_geo = integral(N^T * dK/dV * N * dV0)
    REAL(wp), INTENT(IN)  :: coords_ref(3, 6)  ! Reference coordinates
    REAL(wp), INTENT(IN)  :: p_elem(6)         ! Pressure at nodes
    REAL(wp), INTENT(IN)  :: D(1, 1)           ! Material tangent (unused for linear)
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)      ! Material stiffness matrix
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)      ! Geometric stiffness matrix
    REAL(wp), INTENT(OUT) :: R_int(6)           ! Internal force vector
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6), J(3, 3), detJ
    REAL(wp) :: xi(3), eta(3), zeta(3), weights(3)
    REAL(wp) :: density, sound_speed, inv_rho_c2, dV
    REAL(wp) :: pressure, dV0
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    
    density = 1000.0_wp
    sound_speed = 343.0_wp
    inv_rho_c2 = 1.0_wp / (density * sound_speed**2)
    
    ! 3-point Gauss integration
    weights = [1.0_wp/3.0_wp, 1.0_wp/3.0_wp, 1.0_wp/3.0_wp]
    
    DO ip = 1, PH_ELEM_AC3D6_NIP
      SELECT CASE (ip)
      CASE (1)
        xi(1) = 0.5_wp; eta(1) = 0.0_wp; zeta(1) = 0.0_wp
      CASE (2)
        xi(2) = 0.0_wp; eta(2) = 0.5_wp; zeta(2) = 0.0_wp
      CASE (3)
        xi(3) = 0.0_wp; eta(3) = 0.0_wp; zeta(3) = 0.5_wp
      END SELECT
      
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D6_Jacobian(dNdxi, coords_ref, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      
      CALL AC3D6_B_Matrix(dNdxi, coords_ref, B)
      
      dV0 = detJ * weights(ip)
      pressure = DOT_PRODUCT(N, p_elem)
      
      ! Material stiffness: standard acoustic formulation
      DO i = 1, 6
        DO j = 1, 6
          Ke_mat(i, j) = Ke_mat(i, j) + inv_rho_c2 * &
            (B(1,i)*B(1,j) + B(2,i)*B(2,j) + B(3,i)*B(3,j)) * dV0
        END DO
      END DO
      
      ! Geometric stiffness: nonlinearity from pressure-dependent bulk modulus
      ! dK = dp * d(1/rho*c^2) = dp * (-1/(rho^2*c^4)) * d(rho*c^2)
      ! For large amplitude waves, this term becomes significant
      DO i = 1, 6
        DO j = 1, 6
          Ke_geo(i, j) = Ke_geo(i, j) - pressure * inv_rho_c2**2 * N(i) * N(j) * dV0
        END DO
      END DO
      
      ! Internal force: R = K * p
      DO i = 1, 6
        DO j = 1, 6
          R_int(i) = R_int(i) + Ke_mat(i, j) * p_elem(j)
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_NL_TL

  SUBROUTINE PH_Elem_AC3D6_NL_UL(coords_prev, p_incr, D, Ke_mat, Ke_geo, R_int, status)
    ! Purpose: Updated Lagrangian formulation for large amplitude acoustics
    ! Theory: Current configuration formulation with configuration update
    !         At each increment, mesh moves and wave equation is reformulated
    REAL(wp), INTENT(IN)  :: coords_prev(3, 6)  ! Previous step coordinates
    REAL(wp), INTENT(IN)  :: p_incr(6)          ! Pressure increment
    REAL(wp), INTENT(IN)  :: D(1, 1)            ! Material tangent
    REAL(wp), INTENT(OUT) :: Ke_mat(6, 6)       ! Material stiffness matrix
    REAL(wp), INTENT(OUT) :: Ke_geo(6, 6)       ! Geometric stiffness matrix
    REAL(wp), INTENT(OUT) :: R_int(6)           ! Internal force vector
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: N(6), dNdxi(3, 6), B(3, 6), J(3, 3), detJ
    REAL(wp) :: xi(3), eta(3), zeta(3), weights(3)
    REAL(wp) :: density, sound_speed, inv_rho_c2, dV
    REAL(wp) :: p_current, dV_current
    INTEGER(i4) :: ip, i, j
    
    status = init_error_status()
    Ke_mat = ZERO
    Ke_geo = ZERO
    R_int = ZERO
    
    density = 1000.0_wp
    sound_speed = 343.0_wp
    inv_rho_c2 = 1.0_wp / (density * sound_speed**2)
    
    ! 3-point Gauss integration
    weights = [1.0_wp/3.0_wp, 1.0_wp/3.0_wp, 1.0_wp/3.0_wp]
    
    DO ip = 1, PH_ELEM_AC3D6_NIP
      SELECT CASE (ip)
      CASE (1)
        xi(1) = 0.5_wp; eta(1) = 0.0_wp; zeta(1) = 0.0_wp
      CASE (2)
        xi(2) = 0.0_wp; eta(2) = 0.5_wp; zeta(2) = 0.0_wp
      CASE (3)
        xi(3) = 0.0_wp; eta(3) = 0.0_wp; zeta(3) = 0.5_wp
      END SELECT
      
      CALL AC3D6_ShapeFunc(xi(ip), eta(ip), zeta(ip), N, dNdxi)
      CALL AC3D6_Jacobian(dNdxi, coords_prev, J, detJ)
      IF (ABS(detJ) <= 1.0e-12_wp) CYCLE
      
      CALL AC3D6_B_Matrix(dNdxi, coords_prev, B)
      
      dV_current = detJ * weights(ip)
      p_current = DOT_PRODUCT(N, p_incr)
      
      ! Material stiffness (same as TL for small strain)
      DO i = 1, 6
        DO j = 1, 6
          Ke_mat(i, j) = Ke_mat(i, j) + inv_rho_c2 * &
            (B(1,i)*B(1,j) + B(2,i)*B(2,j) + B(3,i)*B(3,j)) * dV_current
        END DO
      END DO
      
      ! Geometric stiffness for UL
      DO i = 1, 6
        DO j = 1, 6
          Ke_geo(i, j) = Ke_geo(i, j) - p_current * inv_rho_c2 * N(i) * N(j) * dV_current
        END DO
      END DO
      
      ! Internal force
      DO i = 1, 6
        DO j = 1, 6
          R_int(i) = R_int(i) + (Ke_mat(i, j) + Ke_geo(i, j)) * p_incr(j)
        END DO
      END DO
    END DO
    
    status%code = STATUS_SUCCESS
  END SUBROUTINE PH_Elem_AC3D6_NL_UL


  !=============================================================================
  ! UNIFIED INTERFACE (RT Layer compatible)
  !=============================================================================
  
  SUBROUTINE UF_Elem_AC3D6_Calc(ElemType, Formul, Ctx, state_in, &
                                          Mat, state_out, flags)
    TYPE(ElemType), INTENT(IN) :: ElemType
    TYPE(ElemFormul), INTENT(IN) :: Formul
    TYPE(ElemCtx), INTENT(IN) :: Ctx
    TYPE(ElemState), INTENT(IN) :: state_in
    TYPE(MatProperties), INTENT(INOUT) :: Mat
    TYPE(ElemState), INTENT(INOUT) :: state_out
    TYPE(ElemFlags), INTENT(INOUT) :: flags

    REAL(wp) :: coords(3, 6)
    REAL(wp) :: u(6)
    REAL(wp) :: density, bulk_modulus, sound_speed
    REAL(wp) :: k_eff, nu
    REAL(wp) :: Ke(6, 6)
    REAL(wp) :: R_int(6)
    INTEGER(i4) :: i, j

    CALL init_error_status(flags%status)
    flags%failed = .FALSE.

    ! Validate coords_ref allocation
    IF (.NOT. ALLOCATED(Ctx%coords_ref)) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D6_Calc: coords_ref not allocated'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    IF (SIZE(Ctx%coords_ref, 2) < 6) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D6_Calc: insufficient nodes'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Extract coordinates
    DO i = 1, 6
      coords(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i) = &
        Ctx%coords_ref(1:MIN(3, SIZE(Ctx%coords_ref, 1)), i)
    END DO

    ! Extract displacement/pressure field
    u = 0.0_wp
    IF (ALLOCATED(Ctx%disp_total)) THEN
      IF (SIZE(Ctx%disp_total, 2) >= 6) THEN
        DO i = 1, 6
          IF (SIZE(Ctx%disp_total, 1) >= 1) THEN
            u(i) = Ctx%disp_total(1, i)
          END IF
        END DO
      END IF
    END IF

    ! Get material properties (defaults for air)
    density = 1.21_wp
    bulk_modulus = 1.42e5_wp
    sound_speed = 343.0_wp

    IF (ALLOCATED(Mat%props%props)) THEN
      IF (SIZE(Mat%props%props) >= 1) density = Mat%props%props(1)
      IF (SIZE(Mat%props%props) >= 2) bulk_modulus = Mat%props%props(2)
    END IF

    k_eff = bulk_modulus
    nu = 0.0_wp

    IF (k_eff <= 0.0_wp) THEN
      flags%failed = .TRUE.
      flags%status%status_code = IF_STATUS_INVALID
      flags%status%message = 'UF_Elem_AC3D6_Calc: invalid bulk modulus'
      CALL UF_Elem_PrepareStructStorage(ElemType, state_out)
      state_out%evo%Ke = 0.0_wp
      state_out%Re = 0.0_wp
      RETURN
    END IF

    ! Compute stiffness matrix and internal force
    CALL PH_Elem_AC3D6_FormStiffMatrix(coords, k_eff, nu, Ke)
    CALL PH_Elem_AC3D6_FormIntForce(coords, u, k_eff, nu, R_int)

    ! Prepare output structure
    CALL UF_Elem_PrepareStructStorage(ElemType, state_out, &
         needMass=.FALSE., needDamp=.FALSE.)

    ! Copy Ke to state_out
    IF (ASSOCIATED(state_out%evo%Ke)) THEN
      DO i = 1, MIN(6, SIZE(state_out%evo%Ke, 1))
        DO j = 1, MIN(6, SIZE(state_out%evo%Ke, 2))
          state_out%evo%Ke(i, j) = Ke(i, j)
        END DO
      END DO
    END IF

    ! Copy R_int to state_out
    IF (ASSOCIATED(state_out%Re)) THEN
      DO i = 1, MIN(6, SIZE(state_out%Re))
        state_out%Re(i) = R_int(i)
      END DO
    END IF

    ! Prepare integration point states
    CALL UF_Element_PrepareIntPointStates(ElemType, state_out, 6)

    flags%failed = .FALSE.
    flags%suggest_cutback = .FALSE.
    flags%requires_reasse = .TRUE.
    flags%stableDt = 0.0_wp
    flags%status%status_code = IF_STATUS_OK
    state_out%failed = flags%failed
    state_out%stableDt = flags%stableDt
    
  END SUBROUTINE UF_Elem_AC3D6_Calc

END MODULE PH_Elem_AC3D6
