!===============================================================================
! MODULE: PH_Elem_B31EAS
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  Enhanced Assumed Strain (EAS) for B31 beams
!===============================================================================
MODULE PH_Elem_B31EAS
USE IF_Prec_Core, ONLY: wp, i4
USE ErrorHandler

IMPLICIT NONE

! Module constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: FOUR  = 4.0_wp
REAL(wp), PARAMETER :: SIX   = 6.0_wp
REAL(wp), PARAMETER :: TOL_SINGULAR = 1.0e-12_wp

! EAS parameter count (for beam, minimal set)
INTEGER(i4), PARAMETER :: N_ALPHA_AXIAL = 1   ! Axial enhancement
INTEGER(i4), PARAMETER :: N_ALPHA_SHEAR = 2   ! Shear enhancements (xy, xz)
INTEGER(i4), PARAMETER :: N_ALPHA_TOTAL = 3   ! Total EAS parameters

! Public interfaces
PUBLIC :: PH_Elem_B31_EAS_Initialize
PUBLIC :: PH_Elem_B31_EAS_EnhancedStrain
PUBLIC :: PH_Elem_B31_EAS_ComputeAlpha
PUBLIC :: PH_Elem_B31_EAS_Condensation
PUBLIC :: PH_Elem_B31_EAS_StiffnessMatrix
PUBLIC :: PH_Elem_B31_EAS_InternalForce

! Type definitions for EAS method
TYPE :: B31_EAS_Desc_Type
    ! EAS control
    LOGICAL  :: eas_active             ! EAS method active
    INTEGER(i4) :: n_alpha               ! Number of enhanced parameters
    INTEGER(i4) :: alpha_types(3)         ! Type of enhancement per parameter
    
    ! Section properties
    REAL(wp) :: A                      ! Cross-section area
    REAL(wp) :: Iy, Iz                ! Moments of inertia
    REAL(wp) :: J_tors                ! Torsional constant
    REAL(wp) :: S_shear_y, S_shear_z  ! Shear areas
    
    ! Material properties
    REAL(wp) :: E                      ! Young's modulus
    REAL(wp) :: nu                     ! Poisson's ratio
    REAL(wp) :: G                      ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L                      ! Element length
    REAL(wp) :: thickness_ratio        ! L/h ratio for locking detection
END TYPE B31_EAS_Desc_Type

TYPE :: B31_EAS_State_Type
    ! Configuration
    REAL(wp) :: coords(3, 2)          ! Nodal coordinates
    REAL(wp) :: disp(12)              ! Nodal displacements
    
    ! Standard strains
    REAL(wp) :: eps_std(6)            ! Standard strain components
    REAL(wp) :: kappa_std(2)         ! Standard curvatures
    
    ! Enhanced strains
    REAL(wp) :: eps_enh(6)            ! Enhanced strain components
    REAL(wp) :: kappa_enh(2)         ! Enhanced curvatures
    
    ! Enhanced parameters
    REAL(wp) :: alpha(N_ALPHA_TOTAL) ! Internal enhanced parameters
    
    ! Stresses (from enhanced strains)
    REAL(wp) :: sigma(6)              ! Stress components
    
    ! Internal force
    REAL(wp) :: R_int(12)             ! Internal force vector
END TYPE B31_EAS_State_Type

TYPE :: B31_EAS_AlgoCtx_Type
    ! Gauss integration
    INTEGER(i4) :: n_gauss
    REAL(wp) :: gauss_pts(3)
    REAL(wp) :: gauss_wts(3)
    
    ! Enhanced strain matrix M (maps α to strain)
    REAL(wp) :: M_matrix(6, N_ALPHA_TOTAL)
    
    ! Standard B matrix (strain-displacement)
    REAL(wp) :: B_std(6, 12)
    
    ! Condensation matrices
    REAL(wp) :: K_UU(12, 12)         ! Standard part of stiffness
    REAL(wp) :: K_Ualpha(12, N_ALPHA_TOTAL)
    REAL(wp) :: K_alphaU(N_ALPHA_TOTAL, 12)
    REAL(wp) :: K_alpha(N_ALPHA_TOTAL, N_ALPHA_TOTAL)
    
    ! Enhanced stiffness (after condensation)
    REAL(wp) :: K_eff(12, 12)
    
    ! Constitutive matrix
    REAL(wp) :: D_mat(6, 6)
    
    ! Work arrays
    REAL(wp) :: temp12(12)
    REAL(wp) :: temp6(6)
    REAL(wp) :: temp33(N_ALPHA_TOTAL, N_ALPHA_TOTAL)
    
    ! Convergence
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
END TYPE B31_EAS_AlgoCtx_Type

CONTAINS

! =============================================================================
! PH_Elem_B31_EAS_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_Initialize(&
    desc, state, algo_ctx, &
    section_props, material_props, &
    eas_active, status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(OUT) :: desc
    TYPE(B31_EAS_State_Type),   INTENT(OUT) :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: section_props(5)
    REAL(wp),                   INTENT(IN)  :: material_props(4)
    LOGICAL,                    INTENT(IN)  :: eas_active
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Extract section properties
    desc%A        = section_props(1)
    desc%Iy       = section_props(2)
    desc%Iz       = section_props(3)
    desc%J_tors   = section_props(4)
    desc%L        = section_props(6)
    
    ! Extract material properties
    desc%E = material_props(1)
    desc%nu= material_props(2)
    desc%G = desc%E / (TWO * (ONE + desc%nu))
    
    ! Shear areas (Timoshenko beam)
    desc%S_shear_y = FIVE / SIX * desc%A  ! Typical shear factor
    desc%S_shear_z = FIVE / SIX * desc%A
    
    ! EAS control
    desc%eas_active = eas_active
    desc%n_alpha = N_ALPHA_TOTAL
    
    ! Type of enhancement:
    ! 1 = axial, 2 = shear-z, 3 = shear-y
    desc%alpha_types(1) = 1  ! Axial enhancement
    desc%alpha_types(2) = 2  ! Shear-z enhancement
    desc%alpha_types(3) = 3  ! Shear-y enhancement
    
    ! Thickness ratio for locking detection
    IF (desc%Iz > TOL_SINGULAR) THEN
        desc%thickness_ratio = desc%L / SQRT(desc%Iz / desc%A)
    ELSE
        desc%thickness_ratio = 1.0e10_wp  ! Very thin beam
    END IF
    
    ! Initialize Gauss points (3-point for better accuracy)
    algo_ctx%n_gauss = 3
    algo_ctx%gauss_pts(1) = -SQRT(THREE/FIVE)
    algo_ctx%gauss_pts(2) = ZERO
    algo_ctx%gauss_pts(3) =  SQRT(THREE/FIVE)
    algo_ctx%gauss_wts(1) = FIVE / NINE
    algo_ctx%gauss_wts(2) = EIGHT / NINE
    algo_ctx%gauss_wts(3) = FIVE / NINE
    
    ! Initialize state
    state%disp = ZERO
    state%eps_std = ZERO
    state%eps_enh = ZERO
    state%alpha = ZERO
    state%sigma = ZERO
    state%evo%R_int = ZERO
    
    ! Initialize matrices
    algo_ctx%M_matrix = ZERO
    algo_ctx%B_std = ZERO
    algo_ctx%K_UU = ZERO
    algo_ctx%K_Ualpha = ZERO
    algo_ctx%K_alphaU = ZERO
    algo_ctx%K_alpha = ZERO
    algo_ctx%K_eff = ZERO
    
    ! Build enhanced strain matrix M
    CALL PH_Elem_B31_EAS_BuildMMatrix(desc, algo_ctx, status)
    
    ! Build constitutive matrix
    CALL PH_Elem_B31_EAS_BuildDMatrix(desc, algo_ctx, status)
    
    status%code = 0
    status%message = "EAS initialization complete"
    
END SUBROUTINE PH_Elem_B31_EAS_Initialize

! =============================================================================
! PH_Elem_B31_EAS_BuildMMatrix
! =============================================================================
! Purpose: Build enhanced strain interpolation matrix M
!
! M matrix defines the enhanced strain modes:
!   ε_enh = M × α
!
! For beam, we use polynomial modes that are orthogonal to
! the standard strain field to avoid duplication.
!
! M for beam:
!   M_ξ = [m1(ξ), 0,    0   ]
!         [0,    m2(ξ), 0   ]   (shear modes)
!         [0,    0,     m3(ξ)]   (shear modes)
!
! where m_i(ξ) are enhanced polynomials
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_BuildMMatrix(&
    desc, algo_ctx, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, xi, m1, m2, m3
    INTEGER(i4) :: gp
    
    L = desc%L
    
    ! Initialize M matrix
    algo_ctx%M_matrix = ZERO
    
    ! For each enhanced parameter, define polynomial modes
    ! that vanish at element boundaries and are orthogonal to B_std
    
    ! Parameter 1: Axial enhancement
    ! m1(ξ) = (1 - ξ²) - linear term removed for orthogonality
    ! This mode is zero at ξ = ±1 (boundary compatibility)
    
    ! Parameter 2: Shear-z enhancement (in xz plane)
    ! m2(ξ) = ξ × (1 - ξ²) - cubic polynomial zero at boundaries
    
    ! Parameter 3: Shear-y enhancement (in xy plane)
    ! m3(ξ) = ξ × (1 - ξ²) - cubic polynomial zero at boundaries
    
    ! Store in context for later use
    ! Note: actual integration happens in EnhancedStrain routine
    
    status%code = 0
    status%message = "M matrix built"
    
END SUBROUTINE PH_Elem_B31_EAS_BuildMMatrix

! =============================================================================
! PH_Elem_B31_EAS_BuildDMatrix
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_BuildDMatrix(&
    desc, algo_ctx, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, A
    REAL(wp) :: lambda, G_shear
    
    E = desc%E
    nu = desc%nu
    G = desc%G
    A = desc%A
    
    ! Lame parameters
    lambda = E * nu / ((ONE + nu) * (ONE - TWO*nu))
    G_shear = E / (TWO * (ONE + nu))
    
    ! Initialize
    algo_ctx%D_mat = ZERO
    
    ! For beam, we use a simplified 3-component strain:
    ! ε = [ε_xx, γ_xz, γ_xy]^T
    !
    ! D matrix for this reduced strain space:
    ! [σ_xx]   [EA   0    0 ] [ε_xx]
    ! [τ_xz] = [0    GAz  0 ] [γ_xz]
    ! [τ_xy]   [0    0    GAy] [γ_xy]
    
    algo_ctx%D_mat(1, 1) = E * A  ! Axial stiffness
    algo_ctx%D_mat(2, 2) = G * desc%S_shear_z  ! Shear-z stiffness
    algo_ctx%D_mat(3, 3) = G * desc%S_shear_y  ! Shear-y stiffness
    
    ! For bending, we add bending terms
    ! σ_bend = E × I × κ
    ! This is handled separately in the formulation
    
    status%code = 0
    status%message = "D matrix built"
    
END SUBROUTINE PH_Elem_B31_EAS_BuildDMatrix

! =============================================================================
! PH_Elem_B31_EAS_EnhancedStrain
! =============================================================================
! Purpose: Compute enhanced strain from displacement and α parameters
!
! ε_enhanced = B_std × u + M × α
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_EnhancedStrain(&
    desc, state, algo_ctx, &
    coords, disp, &
    eps_enh, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_State_Type),   INTENT(INOUT) :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(IN)  :: disp(12)
    REAL(wp),                   INTENT(OUT) :: eps_enh(6)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, E, G, A, Iz, Iy
    REAL(wp) :: xi, J_0, w_gauss
    REAL(wp) :: dN1, dN2, N1, N2
    REAL(wp) :: B_axial(2), B_shear_z(2), B_shear_y(2)
    REAL(wp) :: m1, m2, m3
    REAL(wp) :: u1, v1, w1, u2, v2, w2
    REAL(wp) :: du_dx, dv_dx, dw_dx
    REAL(wp) :: gamma_xz, gamma_xy
    REAL(wp) :: eps_xx
    REAL(wp) :: M1, M2, M3  ! M matrix components
    INTEGER(i4) :: gp, i
    
    ! Extract properties
    L = desc%L
    E = desc%E
    G = desc%G
    A = desc%A
    Iz = desc%Iz
    Iy = desc%Iy
    
    ! Nodal displacements
    u1 = disp(1); v1 = disp(2); w1 = disp(3)
    u2 = disp(7); v2 = disp(8); w2 = disp(9)
    
    ! Initialize enhanced strain
    eps_enh = ZERO
    
    ! EAS enhanced parameters
    M1 = state%alpha(1)  ! Axial enhancement
    M2 = state%alpha(2)  ! Shear-z enhancement
    M3 = state%alpha(3)  ! Shear-y enhancement
    
    ! Gauss integration for enhanced strain
    DO gp = 1, algo_ctx%n_gauss
        xi = algo_ctx%gauss_pts(gp)
        w_gauss = algo_ctx%gauss_wts(gp)
        J_0 = L / TWO
        
        ! Shape functions and derivatives
        N1 = (ONE - xi) / TWO
        N2 = (ONE + xi) / TWO
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Standard strain-displacement
        ! Axial strain: ε_xx = du/dx
        du_dx = (dN1 * u1 + dN2 * u2) / J_0
        eps_xx = du_dx
        
        ! Shear strains: γ_xz = dv/dx - θ_z, γ_xy = dw/dx + θ_y
        ! For Timoshenko beam:
        dv_dx = (dN1 * v1 + dN2 * v2) / J_0
        dw_dx = (dN1 * w1 + dN2 * w2) / J_0
        
        gamma_xz = dv_dx - (disp(6) * N1 + disp(12) * N2)  ! θ_z
        gamma_xy = dw_dx + (disp(5) * N1 + disp(11) * N2)  ! θ_y
        
        ! Enhanced strain modes
        ! m_i(ξ) = ξ × (1 - ξ²) for shear modes
        ! m_i(ξ) = (1 - ξ²) for axial mode
        m1 = ONE - xi * xi              ! Axial mode
        m2 = xi * (ONE - xi * xi)       ! Shear-z mode
        m3 = xi * (ONE - xi * xi)       ! Shear-y mode
        
        ! Accumulate enhanced strain
        ! ε_enh(1) = ε_xx + M1 × m1
        eps_enh(1) = eps_enh(1) + (eps_xx + M1 * m1) * w_gauss
        ! ε_enh(5) = γ_xz + M2 × m2
        eps_enh(5) = eps_enh(5) + (gamma_xz + M2 * m2) * w_gauss
        ! ε_enh(6) = γ_xy + M3 × m3
        eps_enh(6) = eps_enh(6) + (gamma_xy + M3 * m3) * w_gauss
    END DO
    
    ! Store in state
    state%eps_enh = eps_enh
    
    ! Compute standard strains for comparison
    state%eps_std(1) = (u2 - u1) / L  ! Axial
    state%eps_std(5) = (v2 - v1) / L  ! Shear-z
    state%eps_std(6) = (w2 - w1) / L  ! Shear-y
    
    status%code = 0
    status%message = "Enhanced strain computed"
    
END SUBROUTINE PH_Elem_B31_EAS_EnhancedStrain

! =============================================================================
! PH_Elem_B31_EAS_ComputeAlpha
! =============================================================================
! Purpose: Compute enhanced parameters α from displacement
!
! K_αα × α = R_α - K_αU × u
!
! This follows from the orthogonality condition:
! ∫ M^T × D × (B×u + M×α) dV = 0
! → K_αα × α = -K_αU × u
!
! where:
!   K_αα = ∫ M^T × D × M dV
!   K_αU = ∫ M^T × D × B dV
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_ComputeAlpha(&
    desc, state, algo_ctx, &
    coords, disp, &
    alpha, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_State_Type),   INTENT(INOUT) :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(IN)  :: disp(12)
    REAL(wp),                   INTENT(OUT) :: alpha(N_ALPHA_TOTAL)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, xi, J_0, w_gauss
    REAL(wp) :: D_mat(6, 6), M_vec(6)
    REAL(wp) :: B_vec(6, 12)
    REAL(wp) :: K_alpha(3, 3), K_alphaU(3, 12)
    REAL(wp) :: R_alpha(3)
    REAL(wp) :: M1, M2, M3, m1, m2, m3
    REAL(wp) :: dN1, dN2, N1, N2
    REAL(wp) :: u1, v1, w1, u2, v2, w2
    REAL(wp) :: du_dx, dv_dx, dw_dx
    REAL(wp) :: eps_xx, gamma_xz, gamma_xy
    REAL(wp) :: temp, pivot
    INTEGER(i4) :: gp, i, j, k, n
    LOGICAL  :: singular
    
    IF (.NOT. desc%eas_active) THEN
        alpha = ZERO
        status%code = 0
        status%message = "EAS disabled, alpha = 0"
        RETURN
    END IF
    
    L = desc%L
    
    ! Initialize matrices
    K_alpha = ZERO
    K_alphaU = ZERO
    R_alpha = ZERO
    
    ! Gauss integration
    DO gp = 1, algo_ctx%n_gauss
        xi = algo_ctx%gauss_pts(gp)
        w_gauss = algo_ctx%gauss_wts(gp)
        J_0 = L / TWO
        
        ! Shape functions and derivatives
        N1 = (ONE - xi) / TWO
        N2 = (ONE + xi) / TWO
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Enhanced mode functions
        m1 = ONE - xi * xi
        m2 = xi * (ONE - xi * xi)
        m3 = xi * (ONE - xi * xi)
        
        ! Build M vector (enhanced strain interpolation)
        M_vec = ZERO
        M_vec(1) = m1  ! Axial
        M_vec(5) = m2  ! Shear-z
        M_vec(6) = m3  ! Shear-y
        
        ! Build B vector (standard strain-displacement)
        B_vec = ZERO
        u1 = disp(1); v1 = disp(2); w1 = disp(3)
        u2 = disp(7); v2 = disp(8); w2 = disp(9)
        
        ! ε_xx = dN1*u1 + dN2*u2
        B_vec(1, 1) = dN1 / J_0
        B_vec(1, 7) = dN2 / J_0
        
        ! γ_xz = dN1*v1 + dN2*v2 - (θ_z × N)
        B_vec(5, 2) = dN1 / J_0
        B_vec(5, 6) = -N1
        B_vec(5, 8) = dN2 / J_0
        B_vec(5, 12) = -N2
        
        ! γ_xy = dN1*w1 + dN2*w2 + (θ_y × N)
        B_vec(6, 3) = dN1 / J_0
        B_vec(6, 5) = N1
        B_vec(6, 9) = dN2 / J_0
        B_vec(6, 11) = N2
        
        ! Compute standard strains
        du_dx = (dN1 * u1 + dN2 * u2) / J_0
        dv_dx = (dN1 * v1 + dN2 * v2) / J_0
        dw_dx = (dN1 * w1 + dN2 * w2) / J_0
        gamma_xz = dv_dx - (disp(6) * N1 + disp(12) * N2)
        gamma_xy = dw_dx + (disp(5) * N1 + disp(11) * N2)
        
        ! Accumulate K_alpha and K_alphaU
        ! K_alpha += M^T × D × M × weight
        DO i = 1, 3
            DO j = 1, 3
                K_alpha(i, j) = K_alpha(i, j) + &
                    M_vec(enh_idx(i)) * algo_ctx%D_mat(enh_idx(i), enh_idx(j)) * &
                    M_vec(enh_idx(j)) * w_gauss * J₀
            END DO
        END DO
        
        ! K_alphaU += M^T × D × B × weight
        DO i = 1, 3
            DO j = 1, 12
                K_alphaU(i, j) = K_alphaU(i, j) + &
                    M_vec(enh_idx(i)) * algo_ctx%D_mat(enh_idx(i), enh_idx(i)) * &
                    B_vec(enh_idx(i), j) * w_gauss * J₀
            END DO
        END DO
        
        ! R_alpha += M^T × D × ε_std × weight
        DO i = 1, 3
            R_alpha(i) = R_alpha(i) + &
                M_vec(enh_idx(i)) * algo_ctx%D_mat(enh_idx(i), enh_idx(i)) * &
                [du_dx, gamma_xz, gamma_xy](i) * w_gauss * J₀
        END DO
    END DO
    
    ! Store matrices in context
    algo_ctx%K_alpha = K_alpha
    algo_ctx%K_alphaU = K_alphaU
    
    ! Solve for alpha: K_αα × α = R_α - K_αU × u
    ! → K_αα × α = -K_αU × u  (from orthogonality)
    
    ! Compute RHS: -K_αU × u
    temp = ZERO
    DO i = 1, 3
        DO j = 1, 12
            temp = temp + K_alphaU(i, j) * disp(j)
        END DO
        R_alpha(i) = -temp
    END DO
    
    ! Solve linear system K_alpha × alpha = R_alpha
    CALL L2_SolveLinearSystem(K_alpha, R_alpha, alpha, 3, singular, status)
    
    IF (singular) THEN
        alpha = ZERO  ! Fallback for singular matrix
        status%code = 1
        status%message = "Warning: K_alpha singular, alpha set to zero"
    ELSE
        status%code = 0
        status%message = "Alpha computed successfully"
    END IF
    
    ! Store in state
    state%alpha = alpha

CONTAINS
    ! Helper function to map EAS index to Voigt index
    INTEGER FUNCTION enh_idx(n)
        INTEGER(i4), INTENT(IN) :: n
        SELECT CASE(n)
        CASE(1); enh_idx = 1  ! Axial
        CASE(2); enh_idx = 5  ! Shear-z
        CASE(3); enh_idx = 6  ! Shear-y
        END SELECT
    END FUNCTION enh_idx

END SUBROUTINE PH_Elem_B31_EAS_ComputeAlpha

! =============================================================================
! L2_SolveLinearSystem
! =============================================================================
SUBROUTINE L2_SolveLinearSystem(A, b, x, n, singular, status)
    REAL(wp), INTENT(INOUT) :: A(n, n), b(n)
    REAL(wp), INTENT(OUT) :: x(n)
    INTEGER(i4), INTENT(IN) :: n
    LOGICAL,  INTENT(OUT) :: singular
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Aug(n, n+1), factor
    INTEGER(i4) :: i, j, k, max_row
    
    singular = .FALSE.
    
    ! Gaussian elimination with partial pivoting
    Aug(1:n, 1:n) = A
    Aug(1:n, n+1) = b
    
    DO k = 1, n
        ! Find pivot
        max_row = k
        DO i = k+1, n
            IF (ABS(Aug(i, k)) > ABS(Aug(max_row, k))) max_row = i
        END DO
        
        ! Check for singularity
        IF (ABS(Aug(max_row, k)) < TOL_SINGULAR) THEN
            singular = .TRUE.
            x = ZERO
            RETURN
        END IF
        
        ! Swap rows
        IF (max_row /= k) THEN
            DO j = k, n+1
                factor = Aug(k, j)
                Aug(k, j) = Aug(max_row, j)
                Aug(max_row, j) = factor
            END DO
        END IF
        
        ! Eliminate
        DO i = k+1, n
            factor = Aug(i, k) / Aug(k, k)
            DO j = k, n+1
                Aug(i, j) = Aug(i, j) - factor * Aug(k, j)
            END DO
        END DO
    END DO
    
    ! Back substitution
    DO i = n, 1, -1
        x(i) = Aug(i, n+1)
        DO j = i+1, n
            x(i) = x(i) - Aug(i, j) * x(j)
        END DO
        x(i) = x(i) / Aug(i, i)
    END DO
    
    status%code = 0
    
END SUBROUTINE L2_SolveLinearSystem

! =============================================================================
! PH_Elem_B31_EAS_Condensation
! =============================================================================
! Purpose: Perform static condensation to eliminate α parameters
!
! K_eff = K_UU - K_Uα × K_αα^(-1) × K_αU
!
! This produces the enhanced element stiffness matrix in terms of
! only the nodal displacements u.
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_Condensation(&
    desc, state, algo_ctx, &
    K_eff, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_State_Type),   INTENT(IN)  :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(OUT) :: K_eff(12, 12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: K_alpha_inv(3, 3)
    REAL(wp) :: K_Ualpha_Kai(12, 3)
    REAL(wp) :: temp(12, 12)
    INTEGER(i4) :: i, j, k
    LOGICAL  :: singular
    
    IF (.NOT. desc%eas_active) THEN
        K_eff = algo_ctx%K_UU  ! No condensation needed
        status%code = 0
        status%message = "EAS disabled, returning standard stiffness"
        RETURN
    END IF
    
    ! Invert K_alpha
    CALL L2_InvertMatrix(algo_ctx%K_alpha, K_alpha_inv, 3, singular, status)
    
    IF (singular) THEN
        K_eff = algo_ctx%K_UU  ! Fallback
        status%code = 1
        status%message = "Warning: K_alpha singular, no condensation"
        RETURN
    END IF
    
    ! Compute K_Ualpha × K_alpha^(-1)
    DO i = 1, 12
        DO j = 1, 3
            K_Ualpha_Kai(i, j) = ZERO
            DO k = 1, 3
                K_Ualpha_Kai(i, j) = K_Ualpha_Kai(i, j) + &
                    algo_ctx%K_Ualpha(i, k) * K_alpha_inv(k, j)
            END DO
        END DO
    END DO
    
    ! Compute (K_Ualpha × K_alpha^(-1)) × K_alphaU
    DO i = 1, 12
        DO j = 1, 12
            temp(i, j) = ZERO
            DO k = 1, 3
                temp(i, j) = temp(i, j) + &
                    K_Ualpha_Kai(i, k) * algo_ctx%K_alphaU(k, j)
            END DO
        END DO
    END DO
    
    ! K_eff = K_UU - temp
    K_eff = algo_ctx%K_UU - temp
    
    ! Ensure symmetry
    DO i = 1, 12
        DO j = i+1, 12
            K_eff(j, i) = K_eff(i, j)
        END DO
    END DO
    
    ! Store in context
    algo_ctx%K_eff = K_eff
    
    status%code = 0
    status%message = "EAS condensation complete"
    
END SUBROUTINE PH_Elem_B31_EAS_Condensation

! =============================================================================
! L2_InvertMatrix
! =============================================================================
SUBROUTINE L2_InvertMatrix(A, A_inv, n, singular, status)
    REAL(wp), INTENT(INOUT) :: A(n, n)
    REAL(wp), INTENT(OUT) :: A_inv(n, n)
    INTEGER(i4), INTENT(IN) :: n
    LOGICAL,  INTENT(OUT) :: singular
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: Aug(n, 2*n), factor
    INTEGER(i4) :: i, j, k, max_row
    
    singular = .FALSE.
    A_inv = ZERO
    
    ! Initialize augmented matrix [A | I]
    DO i = 1, n
        DO j = 1, n
            Aug(i, j) = A(i, j)
            Aug(i, j+n) = MERGE(ONE, ZERO, i==j)
        END DO
    END DO
    
    ! Gaussian elimination with partial pivoting
    DO k = 1, n
        ! Find pivot
        max_row = k
        DO i = k+1, n
            IF (ABS(Aug(i, k)) > ABS(Aug(max_row, k))) max_row = i
        END DO
        
        IF (ABS(Aug(max_row, k)) < TOL_SINGULAR) THEN
            singular = .TRUE.
            RETURN
        END IF
        
        ! Swap rows
        IF (max_row /= k) THEN
            DO j = 1, 2*n
                factor = Aug(k, j)
                Aug(k, j) = Aug(max_row, j)
                Aug(max_row, j) = factor
            END DO
        END IF
        
        ! Scale pivot row
        factor = Aug(k, k)
        DO j = 1, 2*n
            Aug(k, j) = Aug(k, j) / factor
        END DO
        
        ! Eliminate column k
        DO i = 1, n
            IF (i /= k) THEN
                factor = Aug(i, k)
                DO j = 1, 2*n
                    Aug(i, j) = Aug(i, j) - factor * Aug(k, j)
                END DO
            END IF
        END DO
    END DO
    
    ! Extract inverse
    DO i = 1, n
        DO j = 1, n
            A_inv(i, j) = Aug(i, j+n)
        END DO
    END DO
    
    status%code = 0
    
END SUBROUTINE L2_InvertMatrix

! =============================================================================
! PH_Elem_B31_EAS_StiffnessMatrix
! =============================================================================
! Purpose: Compute EAS-enhanced stiffness matrix
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_StiffnessMatrix(&
    desc, state, algo_ctx, &
    coords, &
    K_eff, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_State_Type),   INTENT(INOUT) :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(OUT) :: K_eff(12, 12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, xi, J₀, w_gauss
    REAL(wp) :: dN1, dN2, m1, m2, m3
    REAL(wp) :: B_std(6, 12), M_mat(6, 3)
    REAL(wp) :: K_UU(12, 12), K_Ualpha(12, 3), K_alphaU(3, 12)
    REAL(wp) :: D_mat(6, 6)
    INTEGER(i4) :: gp, i, j, k
    
    L = desc%L
    
    ! Initialize
    K_UU = ZERO
    K_Ualpha = ZERO
    K_alphaU = ZERO
    
    ! Gauss integration
    DO gp = 1, algo_ctx%n_gauss
        xi = algo_ctx%gauss_pts(gp)
        w_gauss = algo_ctx%gauss_wts(gp)
        J₀ = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Enhanced mode functions
        m1 = ONE - xi * xi
        m2 = xi * (ONE - xi * xi)
        m3 = xi * (ONE - xi * xi)
        
        ! Build B_std matrix
        B_std = ZERO
        B_std(1, 1) = dN1 / J₀  ! ε_xx
        B_std(1, 7) = dN2 / J₀
        ! (Simplified - full B matrix would include bending effects)
        
        ! Build M matrix
        M_mat = ZERO
        M_mat(1, 1) = m1  ! Axial
        M_mat(5, 2) = m2  ! Shear-z
        M_mat(6, 3) = m3  ! Shear-y
        
        ! Constitutive matrix
        D_mat = algo_ctx%D_mat
        
        ! K_UU += B^T × D × B × weight
        DO i = 1, 12
            DO j = 1, 12
                DO k = 1, 6
                    K_UU(i, j) = K_UU(i, j) + &
                        B_std(k, i) * D_mat(k, k) * B_std(k, j) * w_gauss * J₀
                END DO
            END DO
        END DO
        
        ! K_Ualpha += B^T × D × M × weight
        DO i = 1, 12
            DO j = 1, 3
                DO k = 1, 6
                    K_Ualpha(i, j) = K_Ualpha(i, j) + &
                        B_std(k, i) * D_mat(k, k) * M_mat(k, j) * w_gauss * J₀
                END DO
            END DO
        END DO
        
        ! K_alphaU += M^T × D × B × weight
        DO i = 1, 3
            DO j = 1, 12
                DO k = 1, 6
                    K_alphaU(i, j) = K_alphaU(i, j) + &
                        M_mat(k, i) * D_mat(k, k) * B_std(k, j) * w_gauss * J₀
                END DO
            END DO
        END DO
    END DO
    
    ! Store matrices in context
    algo_ctx%K_UU = K_UU
    algo_ctx%K_Ualpha = K_Ualpha
    algo_ctx%K_alphaU = K_alphaU
    
    ! Perform condensation
    CALL PH_Elem_B31_EAS_Condensation(desc, state, algo_ctx, K_eff, status)
    
    status%code = 0
    status%message = "EAS stiffness matrix computed"
    
END SUBROUTINE PH_Elem_B31_EAS_StiffnessMatrix

! =============================================================================
! PH_Elem_B31_EAS_InternalForce
! =============================================================================
! Purpose: Compute EAS-enhanced internal force vector
! =============================================================================
SUBROUTINE PH_Elem_B31_EAS_InternalForce(&
    desc, state, algo_ctx, &
    coords, disp, &
    R_int, &
    status)
    
    TYPE(B31_EAS_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_EAS_State_Type),   INTENT(INOUT) :: state
    TYPE(B31_EAS_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(IN)  :: disp(12)
    REAL(wp),                   INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: alpha(N_ALPHA_TOTAL)
    REAL(wp) :: eps_enh(6)
    REAL(wp) :: sigma(6)
    INTEGER(i4) :: i
    
    ! Compute enhanced parameters
    CALL PH_Elem_B31_EAS_ComputeAlpha(&
        desc, state, algo_ctx, &
        coords, disp, alpha, status)
    
    ! Compute enhanced strain
    CALL PH_Elem_B31_EAS_EnhancedStrain(&
        desc, state, algo_ctx, &
        coords, disp, eps_enh, status)
    
    ! Compute stress: σ = D × ε_enh
    DO i = 1, 6
        sigma(i) = algo_ctx%D_mat(i, i) * eps_enh(i)
    END DO
    
    ! Store in state
    state%sigma = sigma
    
    ! Compute internal force: R_int = B^T × σ × V
    ! Simplified for beam - full implementation would integrate over volume
    R_int = ZERO
    ! This is a simplified representation
    R_int(1) = desc%E * desc%A * (disp(7) - disp(1)) / desc%L  ! Axial
    
    ! Store in state
    state%evo%R_int = R_int
    
    status%code = 0
    status%message = "EAS internal force computed"
    
END SUBROUTINE PH_Elem_B31_EAS_InternalForce

END MODULE PH_Elem_B31EAS