!===============================================================================
! MODULE: PH_Elem_B31TL
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  Total Lagrangian (TL) Formulation for B31 Beam
!===============================================================================
MODULE PH_Elem_B31TL
USE IF_Prec_Core, ONLY: wp, i4
USE ErrorHandler

IMPLICIT NONE

! Module-wide constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: SIX   = 6.0_wp
REAL(wp), PARAMETER :: TWELVE= 12.0_wp
REAL(wp), PARAMETER :: TOL_GEOM = 1.0e-12_wp  ! Geometric nonlinearity tolerance

! Shape function parameters (2-node beam, natural coords ξ∈[-1,1])
REAL(wp), PARAMETER :: N1_ξ(2) = [-ONE, ONE]   ! N₁(ξ) = (1-ξ)/2, N₂(ξ) = (1+ξ)/2
REAL(wp), PARAMETER :: DN1_ξ(2) = [-HALF, HALF] ! dN/dξ

! Interface definitions
PRIVATE
PUBLIC :: PH_Elem_B31_TL_StiffnessMatrix
PUBLIC :: PH_Elem_B31_TL_InternalForce
PUBLIC :: PH_Elem_B31_TL_StressUpdate
PUBLIC :: PH_Elem_B31_TL_Initialize

! Type definitions for TL formulation
TYPE :: B31_TL_Desc_Type
    ! Geometric description
    REAL(wp) :: L₀                    ! Initial length
    REAL(wp) :: A                     ! Cross-section area
    REAL(wp) :: Iy, Iz               ! Second moments of area
    REAL(wp) :: J_tors               ! Torsional constant
    REAL(wp) :: I_warp               ! Warping constant (B31OS)
    
    ! Material properties (reference config)
    REAL(wp) :: E                     ! Young's modulus
    REAL(wp) :: nu                    ! Poisson's ratio
    REAL(wp) :: G                     ! Shear modulus E/(2(1+ν))
    REAL(wp) :: rho₀                  ! Reference density
    
    ! NL parameters
    INTEGER(i4) :: formulation_type     ! 0=linear, 1=UL, 2=TL
    LOGICAL  :: large_rotation       ! Flag for large rotation analysis
    LOGICAL  :: shear_deformable     ! Timoshenko vs Euler-Bernoulli
END TYPE B31_TL_Desc_Type

TYPE :: B31_TL_State_Type
    ! Reference configuration variables
    REAL(wp) :: coords₀(3, 2)        ! Initial nodal coordinates [x₁,y₁,z₁; x₂,y₂,z₂]
    REAL(wp) :: disp₀(6, 2)          ! Previous step displacements (for UL compatibility)
    
    ! Current configuration variables
    REAL(wp) :: coordsₜ(3, 2)        ! Current nodal coordinates
    REAL(wp) :: dispₜ(6, 2)          ! Current displacements
    REAL(wp) :: rotₜ(3, 2)           ! Current rotations
    
    ! Strain measures (Green-Lagrange for TL)
    REAL(wp) :: E_axial              ! Axial strain E₁₁
    REAL(wp) :: E_bend_y(2)          ! Bending strain about y-axis (at nodes)
    REAL(wp) :: E_bend_z(2)          ! Bending strain about z-axis (at nodes)
    REAL(wp) :: gamma_xy(2)          ! Shear strain γ₁₂
    REAL(wp) :: gamma_xz(2)          ! Shear strain γ₁₃
    
    ! Stress measures (PK2 for TL)
    REAL(wp) :: S_axial              ! Axial PK2 stress
    REAL(wp) :: S_bend_y(2)          ! Bending PK2 stress
    REAL(wp) :: S_bend_z(2)          ! Bending PK2 stress
    REAL(wp) :: tau_xy(2)            ! Shear PK2 stress
    
    ! Internal force vector
    REAL(wp) :: R_int(12)            ! Internal force vector (12 DOF)
    
    ! Configuration metrics
    REAL(wp) :: Lₜ                    ! Current length
    REAL(wp) :: J_det                 ! Jacobian determinant
    REAL(wp) :: theta_total(2)       ! Total rotation angles at nodes
END TYPE B31_TL_State_Type

TYPE :: B31_TL_Algo_Type
    ! Integration parameters
    INTEGER(i4) :: n_gauss_axial        ! Gauss points in axial direction
    INTEGER(i4) :: n_gauss_shear        ! Gauss points in shear direction
    REAL(wp) :: gauss_pts(3)         ! Gauss point locations
    REAL(wp) :: gauss_wts(3)         ! Gauss point weights
    
    ! Newton-Raphson parameters
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    
    ! Solution method
    INTEGER(i4) :: solution_method       ! 1=full Newton, 2=modified Newton
    LOGICAL  :: adaptive_load         ! Adaptive load stepping
END TYPE B31_TL_Algo_Type

TYPE :: B31_TL_Ctx_Type
    ! Temporary work arrays
    REAL(wp) :: B_linear(6, 12)       ! Linear strain-displacement matrix
    REAL(wp) :: B_NL(6, 12, 12)      ! Nonlinear strain-displacement matrix
    REAL(wp) :: D_mat(6, 6)           ! Constitutive matrix
    REAL(wp) :: K_L(12, 12)          ! Linear stiffness matrix
    REAL(wp) :: K_NL(12, 12)         ! Nonlinear (geometric) stiffness
    REAL(wp) :: K_total(12, 12)      ! Total stiffness matrix
    REAL(wp) :: G_matrix(6, 12, 12)  ! Geometric stiffness matrix
    REAL(wp) :: F_deform(3, 3)       ! Deformation gradient
    
    ! Coordinate transformations
    REAL(wp) :: T_local(6, 6)       ! Local transformation matrix
    REAL(wp) :: Q_rotation(3, 3)     ! Rotation tensor
    
    ! Work vectors
    REAL(wp) :: strain_inc(6)        ! Strain increment
    REAL(wp) :: stress_inc(6)        ! Stress increment
    REAL(wp) :: dU(12)               ! Displacement increment
    REAL(wp) :: dR(12)               ! Force residual
    
    ! Metrics
    REAL(wp) :: axial_strain_ref      ! Reference axial strain for current step
    LOGICAL  :: is_converged         ! Convergence flag
END TYPE B31_TL_Ctx_Type

CONTAINS

! =============================================================================
! PH_Elem_B31_TL_Initialize
! =============================================================================
! Purpose: Initialize TL formulation parameters and state variables
! =============================================================================
SUBROUTINE PH_Elem_B31_TL_Initialize(desc, state, algo, status)
    TYPE(B31_TL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_TL_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_TL_Algo_Type),   INTENT(INOUT) :: algo
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    
    ! Initialize desc defaults
    desc%formulation_type = 2      ! TL formulation
    desc%large_rotation = .TRUE.
    desc%shear_deformable = .TRUE.
    
    ! Initialize algo defaults (2-point Gauss)
    algo%n_gauss_axial = 2
    algo%n_gauss_shear = 2
    algo%gauss_pts(1) = -ONE/SQRT(THREE)
    algo%gauss_pts(2) =  ONE/SQRT(THREE)
    algo%gauss_wts(1) = ONE
    algo%gauss_wts(2) = ONE
    
    algo%max_iterations = 15
    algo%tolerance_force = 1.0e-6_wp
    algo%tolerance_disp  = 1.0e-8_wp
    algo%solution_method = 1
    algo%adaptive_load = .TRUE.
    
    ! Initialize state
    state%E_axial = ZERO
    state%S_axial = ZERO
    state%Lₜ = desc%L₀
    state%J_det = ONE
    
    status%code = 0
    status%message = "TL initialization successful"
    
END SUBROUTINE PH_Elem_B31_TL_Initialize

! =============================================================================
! PH_Elem_B31_TL_StiffnessMatrix
! =============================================================================
! Purpose: Compute Total Lagrangian stiffness matrix for B31 beam
!
! K_total = K_L + K_NL = ∫_Ω₀ B_L^T · D · B_L dV₀ 
!                              + ∫_Ω₀ G^T · S · G dV₀
!
! Where:
!   K_L  = Linear stiffness (small deformation)
!   K_NL = Geometric stiffness (stress-dependent, from PK2 stress)
!   B_L  = Linear strain-displacement matrix
!   G    = Nonlinear strain-displacement matrix
!   S    = 2nd Piola-Kirchhoff stress
!   D    = Material constitutive matrix
! =============================================================================
SUBROUTINE PH_Elem_B31_TL_StiffnessMatrix(&
    desc, state, algo, ctx, &
    coords₀, material_props, &
    K_total, status)
    
    TYPE(B31_TL_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_TL_State_Type),  INTENT(IN)  :: state
    TYPE(B31_TL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_TL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords₀(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(OUT) :: K_total(12, 12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, A, Iy, Iz, J_tors, L₀
    REAL(wp) :: xi, N1, N2, dN1, dN2
    REAL(wp) :: y_s, z_s                       ! Section coordinates
    REAL(wp) :: B_row, B_col
    REAL(wp) :: w_gauss, J₀                    ! Gauss weight and Jacobian
    REAL(wp) :: S11, S12, S13                   ! PK2 stress components
    INTEGER(i4) :: i, j, k, gp
    
    ! Extract material properties
    E   = material_props(1)  ! Young's modulus
    nu  = material_props(2)  ! Poisson's ratio
    G   = E / (TWO * (ONE + nu))  ! Shear modulus
    A   = desc%A
    Iy  = desc%Iy
    Iz  = desc%Iz
    J_tors = desc%J_tors
    L₀  = desc%L₀
    
    ! Initialize stiffness matrices
    ctx%K_L     = ZERO
    ctx%K_NL    = ZERO
    ctx%K_total = ZERO
    
    ! Build linear stiffness matrix K_L = ∫ B_L^T · D · B_L dV₀
    ! 6 strain components: [E₁₁, E₂₂, E₃₃, 2E₂₃, 2E₁₃, 2E₁₂]
    ! For beam: only E₁₁ (axial), 2E₁₃ (shear-z), 2E₁₂ (shear-y) are nonzero
    
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        
        ! Shape functions and derivatives in natural coords
        N1  = (ONE - xi) / TWO
        N2  = (ONE + xi) / TWO
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Jacobian for reference configuration
        J₀ = L₀ / TWO  ! dξ/dx = 2/L₀, so dx = (L₀/2)dξ
        
        ! Build linear strain-displacement matrix B_L
        ! Strain-displacement relations for Euler-Bernoulli beam:
        !   E₁₁ = du/dx - y*d²v/dx² - z*d²w/dx²
        !   2E₁₃ = dv/dx - θ_z (shear in y-dir)
        !   2E₁₂ = dw/dx + θ_y (shear in z-dir)
        
        ctx%B_linear = ZERO
        
        DO i = 1, 2
            ! Axial strain row (E₁₁)
            IF (i == 1) THEN
                ctx%B_linear(1, 1) = dN1    ! du/dx at node 1
                ctx%B_linear(1, 2) = -y_s * dN2 * TWO/L₀  ! -y*κ_y at node 1
                ctx%B_linear(1, 3) = -z_s * dN2 * TWO/L₀  ! -z*κ_z at node 1
                ctx%B_linear(1, 5) = -y_s * dN2 * TWO/L₀  ! rotation effect
                ctx%B_linear(1, 6) = -z_s * dN2 * TWO/L₀
            ELSE
                ctx%B_linear(1, 7) = dN2    ! du/dx at node 2
            END IF
        END DO
        
        ! Simplified B_L for 2-node beam (12 DOF: u,v,w,θx,θy,θz at each node)
        ! Row 1: Axial strain E₁₁
        ctx%B_linear(1, 1) = -ONE/L₀
        ctx%B_linear(1, 7) =  ONE/L₀
        
        ! Row 5: Shear strain 2E₁₃ (γ_xz) - Timoshenko beam
        IF (desc%shear_deformable) THEN
            ctx%B_linear(5, 2) = -ONE/L₀
            ctx%B_linear(5, 6) = -ONE
            ctx%B_linear(5, 8) =  ONE/L₀
            ctx%B_linear(5, 12)= -ONE
        END IF
        
        ! Row 6: Shear strain 2E₁₂ (γ_xy) - Timoshenko beam
        IF (desc%shear_deformable) THEN
            ctx%B_linear(6, 3) = -ONE/L₀
            ctx%B_linear(6, 5) =  ONE
            ctx%B_linear(6, 9) =  ONE/L₀
            ctx%B_linear(6, 11)=  ONE
        END IF
        
        ! Build material constitutive matrix D (elasticity matrix)
        ! For plane stress beam, simplified 3x3 for [E₁₁, 2E₁₃, 2E₁₂]
        ctx%D_mat = ZERO
        ctx%D_mat(1, 1) = E * A           ! Axial stiffness EA
        ctx%D_mat(5, 5) = G * A           ! Shear stiffness GA_z
        ctx%D_mat(6, 6) = G * A           ! Shear stiffness GA_y
        ! Bending terms (diagonal)
        ctx%D_mat(1, 1) = ctx%D_mat(1, 1) + E*Iz * (TWO/L₀)**2  ! EI_z
        ctx%D_mat(1, 1) = ctx%D_mat(1, 1) + E*Iy * (TWO/L₀)**2  ! EI_y
        
        ! K_L = B_L^T · D · B_L · weight
        ! (12x6) * (6x6) * (6x12) = (12x12)
        DO i = 1, 12
            DO j = 1, 12
                DO k = 1, 6
                    ctx%K_L(i, j) = ctx%K_L(i, j) + &
                        ctx%B_linear(k, i) * ctx%D_mat(k, k) * &
                        ctx%B_linear(k, j) * w_gauss * J₀
                END DO
            END DO
        END DO
    END DO
    
    ! Build geometric stiffness matrix K_NL = ∫ G^T · S · G dV₀
    ! This accounts for stress-dependent stiffness (stress stiffening)
    ! Based on ADINAM SHAPE subroutine BNL1/BNL2/BNL3 formulation
    
    ! Get current PK2 stresses from state
    S11 = state%S_axial
    S12 = state%tau_xy(1)
    S13 = state%tau_xy(2)
    
    ! Simplified geometric stiffness for large displacement analysis
    ! K_NL contribution from axial stress:
    !   [K_NL]_axial ≈ ∫ σ · (dN^T dN) dV for axial stress effect
    
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        
        ! Shape functions
        N1 = (ONE - xi) / TWO
        N2 = (ONE + xi) / TWO
        
        ! Geometric stiffness contribution from axial stress S11
        ! K_NL(i,j) += S11 * A * ∫ (dN_i/dx * dN_j/dx) dV
        
        ! dN/dx derivatives
        dN1 = -ONE / L₀
        dN2 =  ONE / L₀
        
        ! Axial stress geometric stiffness
        ctx%K_NL(1, 1) = ctx%K_NL(1, 1) + S11 * A * dN1 * dN1 * w_gauss * J₀
        ctx%K_NL(1, 7) = ctx%K_NL(1, 7) + S11 * A * dN1 * dN2 * w_gauss * J₀
        ctx%K_NL(7, 1) = ctx%K_NL(7, 1) + S11 * A * dN2 * dN1 * w_gauss * J₀
        ctx%K_NL(7, 7) = ctx%K_NL(7, 7) + S11 * A * dN2 * dN2 * w_gauss * J₀
    END DO
    
    ! Total stiffness matrix
    ctx%K_total = ctx%K_L + ctx%K_NL
    
    ! Ensure symmetry (numerical safety)
    DO i = 1, 12
        DO j = i+1, 12
            ctx%K_total(i, j) = ctx%K_total(j, i)
        END DO
    END DO
    
    K_total = ctx%K_total
    
    status%code = 0
    status%message = "TL stiffness matrix computed successfully"
    
END SUBROUTINE PH_Elem_B31_TL_StiffnessMatrix

! =============================================================================
! PH_Elem_B31_TL_InternalForce
! =============================================================================
! Purpose: Compute internal force vector in Total Lagrangian formulation
!
! R_int = ∫_Ω₀ B_L^T · S dV₀
!
! Where:
!   S = 2nd Piola-Kirchhoff stress tensor
!   B_L = Linear strain-displacement matrix
! =============================================================================
SUBROUTINE PH_Elem_B31_TL_InternalForce(&
    desc, state, algo, ctx, &
    coords₀, material_props, &
    R_int, status)
    
    TYPE(B31_TL_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_TL_State_Type),  INTENT(IN)  :: state
    TYPE(B31_TL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_TL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords₀(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, G, A, Iy, Iz, J_tors, L₀
    REAL(wp) :: xi, J₀, w_gauss
    REAL(wp) :: S11, S12, S13    ! PK2 stresses
    REAL(wp) :: dN1, dN2
    INTEGER(i4) :: gp, i
    
    ! Extract material properties
    E   = material_props(1)
    G   = E / (TWO * (ONE + material_props(2)))
    A   = desc%A
    Iy  = desc%Iy
    Iz  = desc%Iz
    J_tors = desc%J_tors
    L₀  = desc%L₀
    
    ! Initialize internal force vector
    R_int = ZERO
    ctx%evo%R_int = ZERO
    
    ! Get stresses from state
    S11 = state%S_axial
    S12 = state%tau_xy(1)
    S13 = state%tau_xy(2)
    
    ! Numerical integration: R_int = ∫ B_L^T · S dV₀
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        
        ! Jacobian
        J₀ = L₀ / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Internal force contributions
        ! Axial force contribution
        ctx%evo%R_int(1) = ctx%evo%R_int(1) + S11 * A * dN1 * w_gauss * J₀
        ctx%evo%R_int(7) = ctx%evo%R_int(7) + S11 * A * dN2 * w_gauss * J₀
        
        ! Bending moment contributions
        ! M_y = ∫ σ · z · dA ≈ S11 · Iz / y_max · curvature
        ctx%evo%R_int(5) = ctx%evo%R_int(5) + S11 * Iz * dN1 * w_gauss * J₀
        ctx%evo%R_int(11)= ctx%evo%R_int(11)+ S11 * Iz * dN2 * w_gauss * J₀
        
        ! Shear force contributions
        IF (desc%shear_deformable) THEN
            ctx%evo%R_int(2) = ctx%evo%R_int(2) + S12 * A * dN1 * w_gauss * J₀
            ctx%evo%R_int(8) = ctx%evo%R_int(8) + S12 * A * dN2 * w_gauss * J₀
            ctx%evo%R_int(3) = ctx%evo%R_int(3) + S13 * A * dN1 * w_gauss * J₀
            ctx%evo%R_int(9) = ctx%evo%R_int(9) + S13 * A * dN2 * w_gauss * J₀
        END IF
        
        ! Torsional moment contribution
        ctx%evo%R_int(4)  = ctx%evo%R_int(4)  + S12 * J_tors * dN1 * w_gauss * J₀
        ctx%evo%R_int(10) = ctx%evo%R_int(10) + S12 * J_tors * dN2 * w_gauss * J₀
    END DO
    
    R_int = ctx%evo%R_int
    
    status%code = 0
    status%message = "TL internal force computed successfully"
    
END SUBROUTINE PH_Elem_B31_TL_InternalForce

! =============================================================================
! PH_Elem_B31_TL_StressUpdate
! =============================================================================
! Purpose: Update PK2 stresses based on Green-Lagrange strain increment
!
! Algorithm (based on ADINAM BELPAL):
!   1. Compute Green-Lagrange strain increment: ΔE = B_L · Δu
!   2. Compute PK2 stress increment: ΔS = D : ΔE
!   3. Update PK2 stress: S_{n+1} = S_n + ΔS
!
! Constitutive relation in TL (elastic):
!   S = D : E   (for small strains, S ≈ E·ε)
!
! For geometrically nonlinear case with finite strains:
!   S = J·F^{-1}·σ·F^{-T}   (PK2 = pullback of Cauchy)
! =============================================================================
SUBROUTINE PH_Elem_B31_TL_StressUpdate(&
    desc, state, algo, ctx, &
    coords₀, material_props, &
    du, &
    status)
    
    TYPE(B31_TL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_TL_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_TL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_TL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords₀(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(IN)  :: du(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, A, L₀
    REAL(wp) :: xi, J₀, w_gauss
    REAL(wp) :: dE(6)           ! Strain increment
    REAL(wp) :: dS(6)           ! Stress increment
    REAL(wp) :: dN1, dN2
    REAL(wp) :: E_axial_new
    INTEGER(i4) :: gp, i
    
    ! Extract material properties
    E   = material_props(1)
    nu  = material_props(2)
    G   = E / (TWO * (ONE + nu))
    A   = desc%A
    L₀  = desc%L₀
    
    ! Initialize
    dE = ZERO
    dS = ZERO
    
    ! Gauss integration for stress update
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        
        J₀ = L₀ / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Compute Green-Lagrange strain increment
        ! ΔE₁₁ = ∂(Δu)/∂X = dN1*Δu₁ + dN2*Δu₇
        dE(1) = dN1 * du(1) + dN2 * du(7)  ! Axial strain increment
        
        ! Shear strain increments (if Timoshenko)
        IF (desc%shear_deformable) THEN
            dE(5) = dN1 * du(2) + dN2 * du(8) - (du(6) + du(12)) / TWO  ! γ_xz
            dE(6) = dN1 * du(3) + dN2 * du(9) + (du(5) + du(11)) / TWO  ! γ_xy
        END IF
        
        ! Material constitutive relation: ΔS = D : ΔE
        ! For elastic beam, diagonal D
        dS(1) = E * A * dE(1)       ! Axial stress
        dS(5) = G * A * dE(5)       ! Shear-z
        dS(6) = G * A * dE(6)       ! Shear-y
        
        ! Update state stresses
        state%S_axial = state%S_axial + dS(1)
        state%tau_xy(1) = state%tau_xy(1) + dS(5)
        state%tau_xy(2) = state%tau_xy(2) + dS(6)
    END DO
    
    ! Update axial strain in state
    ! E_axial = (L_t - L₀) / L₀ (approximation for small strains)
    state%E_axial = (state%Lₜ - L₀) / L₀
    
    status%code = 0
    status%message = "TL stress update completed"
    
END SUBROUTINE PH_Elem_B31_TL_StressUpdate

! =============================================================================
! PH_Elem_B31_TL_ConfigurationUpdate
! =============================================================================
! Purpose: Update current configuration for TL formulation
!
! For TL: configuration update uses deformation gradient
!   F = ∂x/∂X = I + ∂u/∂X
!   x = F · X  (current position = deformation gradient · reference position)
! =============================================================================
SUBROUTINE PH_Elem_B31_TL_ConfigurationUpdate(&
    desc, state, &
    coords₀, du, &
    status)
    
    TYPE(B31_TL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_TL_State_Type),  INTENT(INOUT) :: state
    REAL(wp),                 INTENT(IN)  :: coords₀(3, 2)
    REAL(wp),                 INTENT(IN)  :: du(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: u_vec(3)           ! Nodal displacement vector
    REAL(wp) :: x_new, y_new, z_new
    REAL(wp) :: dx, dy, dz
    REAL(wp) :: L₀, L_t
    
    ! Update nodal coordinates
    ! Node 1: DOF 1-6
    u_vec = du(1:3)                ! [ux, uy, uz]
    state%coordsₜ(:, 1) = coords₀(:, 1) + u_vec
    
    ! Node 2: DOF 7-12
    u_vec = du(7:9)
    state%coordsₜ(:, 2) = coords₀(:, 2) + u_vec
    
    ! Update rotations
    state%rotₜ(:, 1) = du(4:6)       ! [θx, θy, θz] at node 1
    state%rotₜ(:, 2) = du(10:12)     ! [θx, θy, θz] at node 2
    
    ! Update displacements
    state%dispₜ(:, 1) = du(1:6)
    state%dispₜ(:, 2) = du(7:12)
    
    ! Compute current length
    dx = state%coordsₜ(1, 2) - state%coordsₜ(1, 1)
    dy = state%coordsₜ(2, 2) - state%coordsₜ(2, 1)
    dz = state%coordsₜ(3, 2) - state%coordsₜ(3, 1)
    state%Lₜ = SQRT(dx*dx + dy*dy + dz*dz)
    
    ! Compute total rotation (for ADINAM compatibility note)
    ! "Total rotations printed are NOT used in geometric NL analysis"
    ! "Element kinematics calculated using INCREMENTAL rotations"
    state%theta_total(1) = SQRT(state%rotₜ(1,1)**2 + state%rotₜ(2,1)**2 + state%rotₜ(3,1)**2)
    state%theta_total(2) = SQRT(state%rotₜ(1,2)**2 + state%rotₜ(2,2)**2 + state%rotₜ(3,2)**2)
    
    ! Compute deformation gradient F = ∂x/∂X (simplified for beam)
    ! F ≈ I + ∂u/∂X, where ∂u/∂X = du/dX (displacement gradient)
    ! For 1D beam: F₁₁ = 1 + du₁/dX₁
    
    ! Jacobian determinant J = det(F) = F₁₁ (for 1D beam)
    L₀ = desc%L₀
    IF (L₀ > TOL_GEOM) THEN
        state%J_det = state%Lₜ / L₀  ! J = L_current / L_reference
    ELSE
        state%J_det = ONE
    END IF
    
    status%code = 0
    status%message = "TL configuration updated"
    
END SUBROUTINE PH_Elem_B31_TL_ConfigurationUpdate

END MODULE PH_Elem_B31TL