!===============================================================================
! MODULE: PH_Elem_B31UL
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  Updated Lagrangian (UL) Formulation for B31 Beam
!===============================================================================
MODULE PH_Elem_B31UL
USE IF_Prec_Core, ONLY: wp, i4
USE ErrorHandler

IMPLICIT NONE

! Module-wide constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: SIX   = 6.0_wp
REAL(wp), PARAMETER :: TOL_GEOM = 1.0e-12_wp
REAL(wp), PARAMETER :: TOL_STRES = 1.0e-8_wp

! Shape function parameters (2-node beam, natural coords ξ∈[-1,1])
REAL(wp), PARAMETER :: HALF = 0.5_wp

! Interface definitions
PRIVATE
PUBLIC :: PH_Elem_B31_UL_StiffnessMatrix
PUBLIC :: PH_Elem_B31_UL_InternalForce
PUBLIC :: PH_Elem_B31_UL_StressUpdate
PUBLIC :: PH_Elem_B31_UL_DeformationUpdate
PUBLIC :: PH_Elem_B31_UL_Initialize

! Type definitions for UL formulation
TYPE :: B31_UL_Desc_Type
    ! Geometric description
    REAL(wp) :: L₀                    ! Initial length (at t=0)
    REAL(wp) :: L_t                   ! Length at start of current step (t)
    REAL(wp) :: L_tdt                 ! Length at end of step (t+dt)
    REAL(wp) :: A                     ! Cross-section area
    REAL(wp) :: Iy, Iz               ! Second moments of area
    REAL(wp) :: J_tors               ! Torsional constant
    REAL(wp) :: I_warp               ! Warping constant (B31OS)
    
    ! Material properties
    REAL(wp) :: E                     ! Young's modulus
    REAL(wp) :: nu                    ! Poisson's ratio
    REAL(wp) :: G                     ! Shear modulus
    REAL(wp) :: rho                   ! Current density
    
    ! UL parameters
    INTEGER(i4) :: formulation_type     ! 2=UL (must be 2)
    LOGICAL  :: large_rotation       ! Large rotation analysis
    LOGICAL  :: large_strain        ! Large strain analysis
    LOGICAL  :: shear_deformable     ! Timoshenko beam
    LOGICAL  :: warping_active       ! B31OS warping DOF
    
    ! ADINAM compatibility
    REAL(wp) :: EPS1                 ! Previous step axial strain
    REAL(wp) :: EPS                  ! Current step axial strain
END TYPE B31_UL_Desc_Type

TYPE :: B31_UL_State_Type
    ! Configuration at t (start of step)
    REAL(wp) :: coords_t(3, 2)       ! Nodal coords at time t
    REAL(wp) :: disp_t(6, 2)         ! Displacements at time t
    REAL(wp) :: rot_t(3, 2)          ! Rotations at time t
    
    ! Configuration at t+dt (end of step)
    REAL(wp) :: coords_tdt(3, 2)    ! Nodal coords at time t+dt
    REAL(wp) :: disp_tdt(6, 2)      ! Displacements at time t+dt
    REAL(wp) :: rot_tdt(3, 2)       ! Rotations at time t+dt
    
    ! Strain measures (Almansi strain for UL)
    REAL(wp) :: eps_axial            ! Axial strain ε₁₁
    REAL(wp) :: eps_bend_y(2)        ! Bending strain at nodes
    REAL(wp) :: eps_bend_z(2)        ! Bending strain at nodes
    REAL(wp) :: gamma_xy(2)          ! Shear strain γ₁₂
    REAL(wp) :: gamma_xz(2)          ! Shear strain γ₁₃
    
    ! Stress measures (Cauchy stress for UL)
    REAL(wp) :: sigma_axial          ! Axial Cauchy stress σ₁₁
    REAL(wp) :: sigma_bend_y(2)      ! Bending Cauchy stress
    REAL(wp) :: sigma_bend_z(2)      ! Bending Cauchy stress
    REAL(wp) :: tau_xy(2)            ! Shear Cauchy stress
    
    ! Internal force vector
    REAL(wp) :: R_int(12)            ! Internal force vector (12 DOF)
    
    ! Configuration metrics
    REAL(wp) :: XLN                   ! Current length (XLN in ADINAM)
    REAL(wp) :: XLT                   ! Previous length (XLT in ADINAM)
    REAL(wp) :: theta_inc(2)          ! Incremental rotation angles
END TYPE B31_UL_State_Type

TYPE :: B31_UL_Algo_Type
    ! Integration parameters
    INTEGER(i4) :: n_gauss_axial        ! Gauss points in axial direction
    INTEGER(i4) :: n_gauss_shear        ! Gauss points in shear direction
    REAL(wp) :: gauss_pts(3)         ! Gauss point locations
    REAL(wp) :: gauss_wts(3)         ! Gauss point weights
    
    ! Gauss-Lobatto points (for ADINAM compatibility)
    REAL(wp) :: lobatto_pts(3)
    REAL(wp) :: lobatto_wts(3)
    
    ! Newton-Raphson parameters
    INTEGER(i4) :: max_iterations
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    INTEGER(i4) :: iteration_count       ! Current iteration count (ICOUNT in ADINAM)
    
    ! Solution method
    INTEGER(i4) :: solution_method       ! 1=full N-R, 2=modified N-R
    LOGICAL  :: adaptive_load
    INTEGER(i4) :: IREF                  ! Reference load flag (ADINAM)
    
    ! ADINAM compatibility
    INTEGER(i4) :: NST                    ! Storage per integration point
    INTEGER(i4) :: IB                     ! Stiffness matrix dimension
    INTEGER(i4) :: ITYPB                 ! Beam type: 0=2D, 1=3D
    INTEGER(i4) :: ISHEAR                ! Shear flag: 0=none, 1=Timoshenko
END TYPE B31_UL_Algo_Type

TYPE :: B31_UL_Ctx_Type
    ! Shape function matrices
    REAL(wp) :: B_mat(6, 16)         ! Linear strain-displacement (ADINAM B)
    REAL(wp) :: BNL1_mat(3, 16)      ! Nonlinear strain matrix (ADINAM BNL1)
    REAL(wp) :: BNL2_mat(2, 16)      ! Nonlinear strain matrix (ADINAM BNL2)
    REAL(wp) :: BNL3_mat(2, 16)      ! Nonlinear strain matrix (ADINAM BNL3)
    
    ! Constitutive matrix
    REAL(wp) :: D_mat(6, 6)          ! Material constitutive matrix
    
    ! Stiffness matrices
    REAL(wp) :: K_L(16, 16)          ! Linear stiffness
    REAL(wp) :: K_NL(16, 16)         ! Nonlinear (geometric) stiffness
    REAL(wp) :: K_total(16, 16)      ! Total stiffness
    REAL(wp) :: K_geom(16, 16)      ! Geometric stiffness from stress
    
    ! Work arrays
    REAL(wp) :: CBM(6, 16)           ! C · B product
    REAL(wp) :: SIG(3)               ! Stress vector [σ_r, τ_rs, τ_rt]
    REAL(wp) :: STRN(3)              ! Strain vector
    REAL(wp) :: EPSP(3)               ! Plastic strain (for elasto-plastic)
    
    ! Coordinate arrays
    REAL(wp) :: XOL, YOL, ZOL         ! Integration point local coords
    REAL(wp) :: XLT3, YOL2, ZOL2     ! Coordinate powers
    REAL(wp) :: YOL3, ZOL3
    
    ! Work vectors
    REAL(wp) :: du(12)                ! Displacement increment
    REAL(wp) :: dR(12)                ! Force residual
    REAL(wp) :: RE_vec(16)           ! Internal force vector
    
    ! Metrics
    LOGICAL  :: is_converged
    INTEGER(i4) :: integration_point
END TYPE B31_UL_Ctx_Type

CONTAINS

! =============================================================================
! PH_Elem_B31_UL_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_Initialize(desc, state, algo, status)
    TYPE(B31_UL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_UL_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_UL_Algo_Type),   INTENT(INOUT) :: algo
    TYPE(ErrorStatusType),     INTENT(OUT)   :: status
    
    ! Initialize desc
    desc%formulation_type = 2      ! UL formulation (INDNL=2 in ADINAM)
    desc%large_rotation = .TRUE.
    desc%large_strain = .FALSE.    ! Beam typically small strain
    desc%shear_deformable = .TRUE.
    desc%warping_active = .FALSE.
    desc%EPS = ZERO
    desc%EPS1 = ZERO
    
    ! Initialize algo with 2-point Gauss
    algo%n_gauss_axial = 2
    algo%n_gauss_shear = 2
    algo%gauss_pts(1) = -ONE/SQRT(THREE)
    algo%gauss_pts(2) =  ONE/SQRT(THREE)
    algo%gauss_wts(1) = ONE
    algo%gauss_wts(2) = ONE
    
    ! Gauss-Lobatto for some cases
    algo%lobatto_pts(1) = -ONE
    algo%lobatto_pts(2) = ZERO
    algo%lobatto_pts(3) = ONE
    algo%lobatto_wts(1) = ONE/THREE
    algo%lobatto_wts(2) = FOUR/THREE
    algo%lobatto_wts(3) = ONE/THREE
    
    algo%max_iterations = 15
    algo%tolerance_force = 1.0e-6_wp
    algo%tolerance_disp  = 1.0e-8_wp
    algo%iteration_count = 0
    algo%solution_method = 1
    algo%adaptive_load = .TRUE.
    algo%IREF = 0
    
    ! ADINAM compatibility
    algo%NST = 3    ! Storage per point: [stress, strain, ...]
    algo%IB = 12    ! DOF count for standard 2-node beam
    
    ! Initialize state
    state%eps_axial = ZERO
    state%sigma_axial = ZERO
    state%XLN = desc%L₀
    state%XLT = desc%L₀
    
    status%code = 0
    status%message = "UL initialization successful"
    
END SUBROUTINE PH_Elem_B31_UL_Initialize

! =============================================================================
! PH_Elem_B31_UL_DeformationUpdate
! =============================================================================
! Purpose: Update configuration for UL formulation
!
! Based on ADINAM STIFNL:
!   EPS1 = WA(1)              ! Previous axial strain (stored)
!   EPS = (XLN - XLT) / XLT  ! Current axial strain from length change
!   XLN = current length      ! L_{t+dt}
!   XLT = previous length     ! L_t
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_DeformationUpdate(&
    desc, state, &
    coords_t, du, &
    status)
    
    TYPE(B31_UL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_UL_State_Type),  INTENT(INOUT) :: state
    REAL(wp),                 INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                 INTENT(IN)  :: du(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: dx, dy, dz
    REAL(wp) :: theta_x, theta_y, theta_z
    REAL(wp) :: theta_mag
    
    ! Store previous length
    state%XLT = desc%L_t
    
    ! Update displacements at t+dt
    state%disp_tdt(:, 1) = coords_t(:, 1) + du(1:6)
    state%disp_tdt(:, 2) = coords_t(:, 2) + du(7:12)
    
    ! Update rotations (incremental)
    state%rot_tdt(:, 1) = du(4:6)
    state%rot_tdt(:, 2) = du(10:12)
    
    ! Update nodal coordinates
    state%coords_tdt(:, 1) = coords_t(:, 1) + du(1:3)
    state%coords_tdt(:, 2) = coords_t(:, 2) + du(7:9)
    
    ! Compute current length XLN
    dx = state%coords_tdt(1, 2) - state%coords_tdt(1, 1)
    dy = state%coords_tdt(2, 2) - state%coords_tdt(2, 1)
    dz = state%coords_tdt(3, 2) - state%coords_tdt(3, 1)
    state%XLN = SQRT(dx*dx + dy*dy + dz*dz)
    
    ! Compute axial strain (ADINAM formula)
    IF (desc%L_t > TOL_GEOM) THEN
        desc%EPS = (state%XLN - desc%L_t) / desc%L_t
    ELSE
        desc%EPS = ZERO
    END IF
    
    ! Update state length
    desc%L_tdt = state%XLN
    
    ! Store previous strain
    desc%EPS1 = state%eps_axial
    
    ! Compute incremental rotations
    DO i = 1, 2
        theta_x = state%rot_tdt(1, i)
        theta_y = state%rot_tdt(2, i)
        theta_z = state%rot_tdt(3, i)
        theta_mag = SQRT(theta_x**2 + theta_y**2 + theta_z**2)
        state%theta_inc(i) = theta_mag
    END DO
    
    status%code = 0
    status%message = "UL deformation update completed"
    
CONTAINS
    INTEGER(i4) :: i
END SUBROUTINE PH_Elem_B31_UL_DeformationUpdate

! =============================================================================
! PH_Elem_B31_UL_ShapeFunctions
! =============================================================================
! Purpose: Compute shape functions and strain-displacement matrices
!
! Based on ADINAM SHAPE subroutine:
!   B(3,16)    - Linear strain-displacement matrix
!   BNL1(3,16) - Nonlinear strain matrix (linear part of nonlinear strain)
!   BNL2(2,16) - Nonlinear strain matrix (quadratic part in S-dir)
!   BNL3(2,16) - Nonlinear strain matrix (quadratic part in T-dir)
!
! For UL formulation, shape functions are evaluated at current 
! configuration, but strain measures use incremental displacements.
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_ShapeFunctions(&
    algo, desc, state, ctx, &
    xi, status)
    
    TYPE(B31_UL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_UL_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_UL_State_Type),  INTENT(IN)  :: state
    TYPE(B31_UL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: xi
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, R1, R2, R3, R4, R5
    REAL(wp) :: A_coef
    INTEGER(i4) :: i, j
    
    L = state%XLN  ! Current length for UL
    
    ! Initialize matrices
    ctx%B_mat = ZERO
    ctx%BNL1_mat = ZERO
    ctx%BNL2_mat = ZERO
    ctx%BNL3_mat = ZERO
    
    ! Pre-compute coordinate powers
    ctx%XLT3 = L * L * L
    ctx%YOL2 = ctx%YOL * ctx%YOL
    ctx%ZOL2 = ctx%ZOL * ctx%ZOL
    ctx%YOL3 = ctx%YOL2 * ctx%YOL
    ctx%ZOL3 = ctx%ZOL2 * ctx%ZOL
    
    ! =====================================================================
    ! Linear strain-displacement matrix B (ADINAM B matrix)
    ! =====================================================================
    ! Row 1: Axial strain ε₁₁ = du/dx - y*d²v/dx² - z*d²w/dx²
    ! B(1,1) = -1/L, B(1,7) = 1/L (axial)
    ctx%B_mat(1, 1) = -ONE/L
    ctx%B_mat(1, 7) =  ONE/L
    
    ! Bending effects on axial strain
    A_coef = (SIX - TWELVE*xi) / L
    ctx%B_mat(1, 2) = A_coef * ctx%YOL  ! v effect on ε₁₁
    ctx%B_mat(1, 3) = A_coef * ctx%ZOL  ! w effect on ε₁₁
    ctx%B_mat(1, 5) = (-FOUR + SIX*xi) * ctx%ZOL  ! θ_z effect
    ctx%B_mat(1, 6) = ( FOUR - SIX*xi) * ctx%YOL  ! θ_y effect
    ctx%B_mat(1, 8) = -A_coef * ctx%YOL
    ctx%B_mat(1, 9) = -A_coef * ctx%ZOL
    ctx%B_mat(1, 11)= (-TWO + SIX*xi) * ctx%ZOL
    ctx%B_mat(1, 12)= ( TWO - SIX*xi) * ctx%YOL
    
    ! Row 2: Shear strain γ_rs = dv/dr + dθ_z/dr (S-direction)
    ctx%B_mat(2, 14) = -ONE              ! Direct shear DOF
    ctx%B_mat(2, 15) = L * ctx%ZOL        ! Higher order
    ctx%B_mat(2, 16) = ctx%XLT3 * (THREE*ctx%YOL2*ctx%ZOL - ctx%ZOL3)
    ctx%B_mat(2, 4) = ctx%ZOL           ! θ_x (torsion) coupling
    ctx%B_mat(2, 10) = -ctx%ZOL
    
    ! Row 3: Shear strain γ_rt = dw/dr - dθ_y/dr (T-direction)
    ctx%B_mat(3, 13) = ONE               ! Direct shear DOF
    ctx%B_mat(3, 15) = L * ctx%YOL       ! Higher order
    ctx%B_mat(3, 16) = ctx%XLT3 * (ctx%YOL3 - THREE*ctx%YOL*ctx%ZOL2)
    ctx%B_mat(3, 4) = -ctx%YOL
    ctx%B_mat(3, 10) = ctx%YOL
    
    ! =====================================================================
    ! Nonlinear strain matrices (for large rotation effects)
    ! =====================================================================
    ! These are used in geometric stiffness calculation
    
    IF (desc%large_rotation) THEN
        ! Coefficients for nonlinear strain terms
        R1 = (SIX - TWELVE*xi) / L
        R2 = FOUR - SIX*xi
        R3 = SIX*xi*(ONE - xi) / L
        R4 = ONE - FOUR*xi + THREE*xi*xi
        R5 = xi * (TWO - THREE*xi)
        
        ! BNL1: Linear part of nonlinear strain (partial derivatives of ε_NL)
        ! BNL1(1,:) - Axial nonlinear strain derivatives
        ctx%BNL1_mat(1, 1) = -ONE/L
        ctx%BNL1_mat(1, 2) = R1 * ctx%YOL
        ctx%BNL1_mat(1, 3) = R1 * ctx%ZOL
        ctx%BNL1_mat(1, 5) = -R2 * ctx%ZOL
        ctx%BNL1_mat(1, 6) = R2 * ctx%YOL
        ctx%BNL1_mat(1, 7) = ONE/L
        ctx%BNL1_mat(1, 8) = -R1 * ctx%YOL
        ctx%BNL1_mat(1, 9) = -R1 * ctx%ZOL
        ctx%BNL1_mat(1, 11)= (SIX*xi - TWO) * ctx%ZOL
        ctx%BNL1_mat(1, 12)= (TWO - SIX*xi) * ctx%YOL
        
        ! BNL2: Quadratic part derivatives (S-direction)
        ctx%BNL2_mat(1, 2) = -R3
        ctx%BNL2_mat(1, 4) = ctx%ZOL
        ctx%BNL2_mat(1, 6) = R4
        ctx%BNL2_mat(1, 8) = R3
        ctx%BNL2_mat(1, 10)= -ctx%ZOL
        ctx%BNL2_mat(1, 12)= -R5
        ctx%BNL2_mat(1, 14)= -ONE + R3*L
        
        ! BNL3: Quadratic part derivatives (T-direction)
        ctx%BNL3_mat(1, 3) = -R3
        ctx%BNL3_mat(1, 4) = -ctx%YOL
        ctx%BNL3_mat(1, 5) = -R4
        ctx%BNL3_mat(1, 9) = R3
        ctx%BNL3_mat(1, 10)= ctx%YOL
        ctx%BNL3_mat(1, 11)= R5
        ctx%BNL3_mat(1, 13)= ONE - R3*L
    END IF
    
    status%code = 0
    status%message = "Shape functions computed"
    
END SUBROUTINE PH_Elem_B31_UL_ShapeFunctions

! =============================================================================
! PH_Elem_B31_UL_StiffnessMatrix
! =============================================================================
! Purpose: Compute Updated Lagrangian stiffness matrix
!
! K_total = K_L + K_NL = ∫ B^T · D · B dV + ∫ G^T · σ · G dV
!
! For UL formulation, integration is over current configuration (t+dt).
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_StiffnessMatrix(&
    desc, state, algo, ctx, &
    coords_t, material_props, &
    K_total, status)
    
    TYPE(B31_UL_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_UL_State_Type),  INTENT(IN)  :: state
    TYPE(B31_UL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_UL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(OUT) :: K_total(12, 12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, A, Iy, Iz, J_tors, L
    REAL(wp) :: xi, J_curr, w_gauss
    REAL(wp) :: sigma11, tau12, tau13
    REAL(wp) :: DELV, WFAC, WFACZ
    REAL(wp) :: XAREA(3)
    INTEGER(i4) :: i, j, k, i1, i2, i3
    INTEGER(i4) :: IB, INPL
    
    ! Extract material properties
    E   = material_props(1)
    nu  = material_props(2)
    G   = E / (TWO * (ONE + nu))
    A   = desc%A
    Iy  = desc%Iy
    Iz  = desc%Iz
    J_tors = desc%J_tors
    L   = state%XLN  ! Current length
    
    ! Initialize matrices
    ctx%K_L    = ZERO
    ctx%K_NL   = ZERO
    ctx%K_total = ZERO
    
    ! Determine dimensions
    IB = algo%IB
    INPL = 3  ! Strain components: ε₁₁, γ₁₂, γ₁₃
    
    ! Gauss integration loop (simplified 2-point)
    DO i1 = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(i1)
        
        ! Update shape functions at this point
        CALL PH_Elem_B31_UL_ShapeFunctions(algo, desc, state, ctx, xi, status)
        
        ! Jacobian for current configuration
        J_curr = L / TWO
        
        ! Compute integration weight
        w_gauss = algo%gauss_wts(i1)
        WFAC = w_gauss * J_curr * A
        
        ! Build material constitutive matrix D
        ctx%D_mat = ZERO
        ctx%D_mat(1, 1) = E * A              ! Axial
        ctx%D_mat(2, 2) = G * A              ! Shear-z
        ctx%D_mat(3, 3) = G * A              ! Shear-y
        
        ! Bending contributions (simplified)
        ctx%D_mat(1, 1) = ctx%D_mat(1, 1) + E*Iz * (TWO/L)**2
        ctx%D_mat(1, 1) = ctx%D_mat(1, 1) + E*Iy * (TWO/L)**2
        
        ! Linear stiffness: K_L = ∫ B^T · D · B dV
        DO i = 1, 3
            DO j = 1, IB
                DO k = 1, IB
                    ctx%K_L(j, k) = ctx%K_L(j, k) + &
                        ctx%B_mat(i, j) * ctx%D_mat(i, i) * &
                        ctx%B_mat(i, k) * WFAC
                END DO
            END DO
        END DO
    END DO
    
    ! Geometric stiffness from current stresses (stress stiffening)
    sigma11 = state%sigma_axial
    tau12 = state%tau_xy(1)
    tau13 = state%tau_xy(2)
    
    ! K_NL contribution from axial stress
    DO i1 = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(i1)
        w_gauss = algo%gauss_wts(i1)
        J_curr = L / TWO
        
        ! dN/dx derivatives
        ctx%K_NL(1, 1) = ctx%K_NL(1, 1) + sigma11 * A * (-ONE/L) * (-ONE/L) * w_gauss * J_curr
        ctx%K_NL(1, 7) = ctx%K_NL(1, 7) + sigma11 * A * (-ONE/L) * ( ONE/L) * w_gauss * J_curr
        ctx%K_NL(7, 1) = ctx%K_NL(7, 1) + sigma11 * A * ( ONE/L) * (-ONE/L) * w_gauss * J_curr
        ctx%K_NL(7, 7) = ctx%K_NL(7, 7) + sigma11 * A * ( ONE/L) * ( ONE/L) * w_gauss * J_curr
    END DO
    
    ! Total stiffness
    ctx%K_total = ctx%K_L + ctx%K_NL
    
    ! Ensure symmetry
    DO i = 1, 12
        DO j = i+1, 12
            ctx%K_total(i, j) = ctx%K_total(j, i)
        END DO
    END DO
    
    K_total(1:12, 1:12) = ctx%K_total(1:12, 1:12)
    
    status%code = 0
    status%message = "UL stiffness matrix computed"
    
END SUBROUTINE PH_Elem_B31_UL_StiffnessMatrix

! =============================================================================
! PH_Elem_B31_UL_InternalForce
! =============================================================================
! Purpose: Compute internal force vector in UL formulation
!
! R_int = ∫_Ωₜ B^T · σ dVₜ
!
! Where σ is Cauchy stress integrated over current configuration.
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_InternalForce(&
    desc, state, algo, ctx, &
    coords_t, material_props, &
    R_int, status)
    
    TYPE(B31_UL_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_UL_State_Type),  INTENT(IN)  :: state
    TYPE(B31_UL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_UL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, G, A, Iy, Iz, J_tors, L
    REAL(wp) :: xi, J_curr, w_gauss
    REAL(wp) :: sigma11, tau12, tau13
    REAL(wp) :: dN1, dN2
    INTEGER(i4) :: i, j, gp
    
    ! Extract material properties
    E   = material_props(1)
    G   = E / (TWO * (ONE + material_props(2)))
    A   = desc%A
    Iy  = desc%Iy
    Iz  = desc%Iz
    J_tors = desc%J_tors
    L   = state%XLN
    
    ! Initialize
    R_int = ZERO
    ctx%RE_vec = ZERO
    
    ! Get stresses
    sigma11 = state%sigma_axial
    tau12 = state%tau_xy(1)
    tau13 = state%tau_xy(2)
    
    ! Gauss integration
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        J_curr = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Axial force contribution
        ctx%RE_vec(1)  = ctx%RE_vec(1)  + sigma11 * A * dN1 * w_gauss * J_curr
        ctx%RE_vec(7)  = ctx%RE_vec(7)  + sigma11 * A * dN2 * w_gauss * J_curr
        
        ! Bending moment contributions
        ctx%RE_vec(5)  = ctx%RE_vec(5)  + sigma11 * Iz * dN1 * w_gauss * J_curr
        ctx%RE_vec(11) = ctx%RE_vec(11) + sigma11 * Iz * dN2 * w_gauss * J_curr
        
        ! Shear contributions
        IF (desc%shear_deformable) THEN
            ctx%RE_vec(2)  = ctx%RE_vec(2)  + tau12 * A * dN1 * w_gauss * J_curr
            ctx%RE_vec(8)  = ctx%RE_vec(8)  + tau12 * A * dN2 * w_gauss * J_curr
            ctx%RE_vec(3)  = ctx%RE_vec(3)  + tau13 * A * dN1 * w_gauss * J_curr
            ctx%RE_vec(9)  = ctx%RE_vec(9)  + tau13 * A * dN2 * w_gauss * J_curr
        END IF
        
        ! Torsional moment
        ctx%RE_vec(4)  = ctx%RE_vec(4)  + tau12 * J_tors * dN1 * w_gauss * J_curr
        ctx%RE_vec(10) = ctx%RE_vec(10) + tau12 * J_tors * dN2 * w_gauss * J_curr
    END DO
    
    R_int(1:12) = ctx%RE_vec(1:12)
    state%evo%R_int = R_int
    
    status%code = 0
    status%message = "UL internal force computed"
    
END SUBROUTINE PH_Elem_B31_UL_InternalForce

! =============================================================================
! PH_Elem_B31_UL_StressUpdate
! =============================================================================
! Purpose: Update Cauchy stress based on Almansi strain increment
!
! Algorithm (based on ADINAM BELPAL):
!   1. Compute strain increment: Δε = B · Δu
!   2. Compute stress increment: Δσ = D : Δε
!   3. Update Cauchy stress: σ_{n+1} = σ_n + Δσ
!
! For UL, constitutive relation is in current configuration:
!   σ = D : ε (for elastic)
!
! For elastoplastic:
!   σ = D_ep : ε (consistent tangent)
! =============================================================================
SUBROUTINE PH_Elem_B31_UL_StressUpdate(&
    desc, state, algo, ctx, &
    coords_t, material_props, &
    du, &
    status)
    
    TYPE(B31_UL_Desc_Type),   INTENT(INOUT) :: desc
    TYPE(B31_UL_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_UL_Algo_Type),   INTENT(IN)  :: algo
    TYPE(B31_UL_Ctx_Type),    INTENT(INOUT) :: ctx
    REAL(wp),                 INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                 INTENT(IN)  :: material_props(4)
    REAL(wp),                 INTENT(IN)  :: du(12)
    TYPE(ErrorStatusType),     INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, A, L
    REAL(wp) :: xi, J_curr, w_gauss
    REAL(wp) :: dE(3)               ! Strain increment
    REAL(wp) :: dS(3)               ! Stress increment
    REAL(wp) :: dN1, dN2
    INTEGER(i4) :: gp
    
    ! Extract material properties
    E   = material_props(1)
    nu  = material_props(2)
    G   = E / (TWO * (ONE + nu))
    A   = desc%A
    L   = state%XLN
    
    ! Initialize
    dE = ZERO
    dS = ZERO
    
    ! Gauss integration
    DO gp = 1, algo%n_gauss_axial
        xi = algo%gauss_pts(gp)
        w_gauss = algo%gauss_wts(gp)
        J_curr = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Almansi strain increment (current config)
        ! ε₁₁ = ∂u/∂x - y·∂²v/∂x² - z·∂²w/∂x²
        dE(1) = dN1 * du(1) + dN2 * du(7)
        
        ! Shear strain increments
        IF (desc%shear_deformable) THEN
            dE(2) = dN1 * du(2) + dN2 * du(8) - (du(6) + du(12)) / TWO
            dE(3) = dN1 * du(3) + dN2 * du(9) + (du(5) + du(11)) / TWO
        END IF
        
        ! Constitutive relation: Δσ = D : Δε (elastic)
        dS(1) = E * A * dE(1)
        dS(2) = G * A * dE(2)
        dS(3) = G * A * dE(3)
        
        ! Update Cauchy stresses
        state%sigma_axial = state%sigma_axial + dS(1)
        state%tau_xy(1) = state%tau_xy(1) + dS(2)
        state%tau_xy(2) = state%tau_xy(2) + dS(3)
    END DO
    
    ! Update axial strain
    state%eps_axial = (state%XLN - desc%L_t) / desc%L_t
    
    status%code = 0
    status%message = "UL stress update completed"
    
END SUBROUTINE PH_Elem_B31_UL_StressUpdate

END MODULE PH_Elem_B31UL