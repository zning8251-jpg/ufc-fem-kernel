!===============================================================================
! MODULE: PH_Elem_B31Fbar
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  F-bar method for B31 beams (volumetric locking avoidance)
!===============================================================================
MODULE PH_Elem_B31Fbar
USE IF_Prec_Core, ONLY: wp, i4
USE ErrorHandler

IMPLICIT NONE

! Module constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: TOL_J = 1.0e-10_wp

! Public interfaces
PUBLIC :: PH_Elem_B31_Fbar_Initialize
PUBLIC :: PH_Elem_B31_Fbar_DeformationGradient
PUBLIC :: PH_Elem_B31_Fbar_Strain
PUBLIC :: PH_Elem_B31_Fbar_StressUpdate
PUBLIC :: PH_Elem_B31_Fbar_StiffnessMatrix

! Type definitions for F-bar method
TYPE :: B31_Fbar_Desc_Type
    ! F-bar control
    LOGICAL  :: fbar_active              ! F-bar method active
    LOGICAL  :: volumetric_coupling     ! Couple volumetric response
    REAL(wp) :: kappa                  ! Bulk modulus (for pressure computation)
    REAL(wp) :: J_limit                ! Jacobian limit for stability
    
    ! Section properties
    REAL(wp) :: A                      ! Cross-section area
    REAL(wp) :: Iy, Iz                ! Moments of inertia
    REAL(wp) :: J_tors                ! Torsional constant
    
    ! Material properties
    REAL(wp) :: E                      ! Young's modulus
    REAL(wp) :: nu                     ! Poisson's ratio
    REAL(wp) :: G                      ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L                      ! Element length
END TYPE B31_Fbar_Desc_Type

TYPE :: B31_Fbar_State_Type
    ! Configuration
    REAL(wp) :: coords_0(3, 2)          ! Initial coordinates
    REAL(wp) :: coords_t(3, 2)          ! Current coordinates
    
    ! Deformation measures
    REAL(wp) :: F_matrix(3, 3, 2)     ! Deformation gradient at nodes
    REAL(wp) :: F_dev(3, 3, 2)        ! Deviatoric part of F
    REAL(wp) :: J_det(2)               ! Jacobian det(F) at nodes
    
    ! F-bar strain measures
    REAL(wp) :: E_fbar_axial           ! F-bar axial strain
    REAL(wp) :: E_fbar_bend(2)        ! F-bar bending strain
    REAL(wp) :: gamma_fbar(2)          ! F-bar shear strain
    
    ! Stress measures
    REAL(wp) :: sigma_axial            ! Axial stress
    REAL(wp) :: sigma_bend(2)         ! Bending stress
    REAL(wp) :: tau_shear(2)           ! Shear stress
    REAL(wp) :: pressure               ! Hydrostatic pressure
    
    ! Volumetric response
    REAL(wp) :: p_vol                  ! Volumetric pressure
    REAL(wp) :: eps_vol                ! Volumetric strain
    
    ! Internal force
    REAL(wp) :: R_int(12)             ! Internal force vector
END TYPE B31_Fbar_State_Type

TYPE :: B31_Fbar_AlgoCtx_Type
    ! Gauss integration
    INTEGER(i4) :: n_gauss
    REAL(wp) :: gauss_pts(3)
    REAL(wp) :: gauss_wts(3)
    
    ! Work arrays
    REAL(wp) :: B_fbar(6, 12)         ! F-bar strain-displacement matrix
    REAL(wp) :: D_fbar(6, 6)          ! F-bar constitutive matrix
    REAL(wp) :: D_dev(6, 6)           ! Deviatoric part of D
    REAL(wp) :: D_vol(6, 6)           ! Volumetric part of D
    REAL(wp) :: K_fbar(12, 12)        ! F-bar stiffness matrix
    
    ! Temporary matrices
    REAL(wp) :: temp33(3, 3)
    REAL(wp) :: F_avg(3, 3)           ! Average deformation gradient
    REAL(wp) :: C_dev(3, 3)           ! Deviatoric right Cauchy-Green
    REAL(wp) :: E_dev(3, 3)           ! Deviatoric Green-Lagrange
    
    ! Convergence
    INTEGER(i4) :: iteration
    LOGICAL  :: converged
END TYPE B31_Fbar_AlgoCtx_Type

CONTAINS

! =============================================================================
! PH_Elem_B31_Fbar_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_Initialize(&
    desc, state, algo_ctx, &
    section_props, material_props, &
    fbar_active, status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(OUT) :: desc
    TYPE(B31_Fbar_State_Type),   INTENT(OUT) :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: section_props(5)
    REAL(wp),                   INTENT(IN)  :: material_props(4)
    LOGICAL,                    INTENT(IN)  :: fbar_active
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Extract section properties
    desc%A      = section_props(1)
    desc%Iy     = section_props(2)
    desc%Iz     = section_props(3)
    desc%J_tors = section_props(4)
    desc%L      = section_props(6)
    
    ! Extract material properties
    desc%E = material_props(1)
    desc%nu= material_props(2)
    desc%G = desc%E / (TWO * (ONE + desc%nu))
    
    ! Compute bulk modulus for volumetric response
    ! κ = E / (3(1-2ν)) for 3D, simplified for beam
    IF (ABS(ONE - TWO*desc%nu - THREE*desc%nu*desc%nu) > TOL_J) THEN
        desc%kappa = desc%E / (THREE * (ONE - TWO*desc%nu))
    ELSE
        ! Nearly incompressible, use large value
        desc%kappa = desc%E * 1.0e6_wp
    END IF
    
    ! F-bar control
    desc%fbar_active = fbar_active
    desc%volumetric_coupling = .TRUE.
    desc%J_limit = 0.5_wp  ! Minimum Jacobian for stability
    
    ! Initialize Gauss points (2-point)
    algo_ctx%n_gauss = 2
    algo_ctx%gauss_pts(1) = -ONE / SQRT(THREE)
    algo_ctx%gauss_pts(2) =  ONE / SQRT(THREE)
    algo_ctx%gauss_wts(1) = ONE
    algo_ctx%gauss_wts(2) = ONE
    
    ! Initialize state
    state%E_fbar_axial = ZERO
    state%sigma_axial = ZERO
    state%p_vol = ZERO
    state%eps_vol = ZERO
    state%evo%R_int = ZERO
    
    ! Initialize work arrays
    algo_ctx%B_fbar = ZERO
    algo_ctx%D_fbar = ZERO
    algo_ctx%K_fbar = ZERO
    algo_ctx%iteration = 0
    algo_ctx%converged = .FALSE.
    
    status%code = 0
    status%message = "F-bar initialization complete"
    
END SUBROUTINE PH_Elem_B31_Fbar_Initialize

! =============================================================================
! PH_Elem_B31_Fbar_DeformationGradient
! =============================================================================
! Purpose: Compute deformation gradient F from displacement
!
! F = ∂x/∂X = I + ∂u/∂X
!
! For beam: F is approximated using displacement derivatives
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_DeformationGradient(&
    desc, state, &
    coords_0, coords_t, &
    F_matrix, J_det, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(INOUT) :: state
    REAL(wp),                   INTENT(IN)  :: coords_0(3, 2)
    REAL(wp),                   INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                   INTENT(OUT) :: F_matrix(3, 3, 2)
    REAL(wp),                   INTENT(OUT) :: J_det(2)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: du1(3), du2(3)        ! Nodal displacement increments
    REAL(wp) :: dX1, dX2             ! Reference coordinates relative to node 1
    REAL(wp) :: dx1(3), dx2(3)        ! Current coordinates relative to node 1
    REAL(wp) :: F_approx(3, 3)        ! Approximate F at element center
    REAL(wp) :: L₀, Lₜ               ! Initial and current lengths
    REAL(wp) :: e_x₀(3), e_xₜ(3)    ! Initial and current axis directions
    REAL(wp) :: R_matrix(3, 3)      ! Rotation matrix
    REAL(wp) :: U_matrix(3, 3)      ! Stretch matrix
    REAL(wp) :: V_matrix(3, 3)       ! Left stretch matrix
    REAL(wp) :: temp33(3, 3)
    REAL(wp) :: trace_C
    REAL(wp) :: J_avg
    INTEGER(i4) :: i
    
    ! Store coordinates
    state%coords_0 = coords_0
    state%coords_t = coords_t
    
    ! Compute displacement increments
    du1 = coords_t(:, 1) - coords_0(:, 1)
    du2 = coords_t(:, 2) - coords_0(:, 2)
    
    ! Reference configuration axis
    dX1 = ZERO
    dX2 = coords_0(:, 2) - coords_0(:, 1)
    L₀ = SQRT(DOT_PRODUCT(dX2, dX2))
    
    ! Current configuration axis
    dx1 = ZERO
    dx2 = coords_t(:, 2) - coords_t(:, 1)
    Lₜ = SQRT(DOT_PRODUCT(dx2, dx2))
    
    ! Unit vectors
    IF (L₀ > TOL_J) THEN
        e_x₀ = dX2 / L₀
    ELSE
        e_x₀ = [ONE, ZERO, ZERO]
    END IF
    
    IF (Lₜ > TOL_J) THEN
        e_xₜ = dx2 / Lₜ
    ELSE
        e_xₜ = e_x₀
    END IF
    
    ! Simplified deformation gradient for beam
    ! F = R × U where R rotates e_x₀ to e_xₜ
    ! This captures large rotations but approximates stretch
    
    ! Build rotation matrix R (axis-angle representation)
    CALL PH_Elem_B31_Fbar_RodriguesFormula(e_x₀, e_xₜ, R_matrix, status)
    
    ! Compute stretch ratio
    IF (L₀ > TOL_J) THEN
        U_matrix = ZERO
        DO i = 1, 3
            U_matrix(i, i) = ONE
        END DO
        U_matrix(1, 1) = Lₜ / L₀  ! Axial stretch
    ELSE
        U_matrix = ZERO
        DO i = 1, 3
            U_matrix(i, i) = ONE
        END DO
    END IF
    
    ! F = R × U (polar decomposition)
    F_approx = MATMUL(R_matrix, U_matrix)
    
    ! Store F at element center
    F_matrix(:, :, 1) = F_approx
    F_matrix(:, :, 2) = F_approx
    
    ! Compute Jacobian J = det(F)
    J_det(1) = F_approx(1,1) * (F_approx(2,2)*F_approx(3,3) - F_approx(2,3)*F_approx(3,2)) &
              - F_approx(1,2) * (F_approx(2,1)*F_approx(3,3) - F_approx(2,3)*F_approx(3,1)) &
              + F_approx(1,3) * (F_approx(2,1)*F_approx(3,2) - F_approx(2,2)*F_approx(3,1))
    J_det(2) = J_det(1)
    
    ! Store in state
    state%F_matrix = F_matrix
    state%J_det = J_det
    
    ! Compute average F for F-bar method
    state%F_avg = F_approx
    
    status%code = 0
    status%message = "Deformation gradient computed"
    
CONTAINS

SUBROUTINE PH_Elem_B31_Fbar_RodriguesFormula(v1, v2, R, status)
    REAL(wp), INTENT(IN)  :: v1(3), v2(3)
    REAL(wp), INTENT(OUT) :: R(3, 3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(wp) :: axis(3), cross_prod(3)
    REAL(wp) :: cos_theta, sin_theta, theta
    REAL(wp) :: I33(3, 3), axis_cross(3, 3)
    REAL(wp) :: temp33(3, 3)
    
    ! Compute rotation angle
    cos_theta = DOT_PRODUCT(v1, v2)
    cos_theta = MAX(-ONE, MIN(ONE, cos_theta))  ! Clamp for numerical stability
    theta = ACOS(cos_theta)
    
    ! Compute rotation axis (cross product)
    cross_prod(1) = v1(2)*v2(3) - v1(3)*v2(2)
    cross_prod(2) = v1(3)*v2(1) - v1(1)*v2(3)
    cross_prod(3) = v1(1)*v2(2) - v1(2)*v2(1)
    
    IF (ABS(theta) < TOL_J) THEN
        ! Identity rotation
        R = ZERO
        DO i = 1, 3
            R(i, i) = ONE
        END DO
    ELSE
        ! Normalize axis
        sin_theta = SIN(theta)
        axis = cross_prod / sin_theta
        
        ! Identity matrix
        I33 = ZERO
        DO i = 1, 3
            I33(i, i) = ONE
        END DO
        
        ! Cross product matrix of axis
        axis_cross = ZERO
        axis_cross(1, 2) = -axis(3)
        axis_cross(1, 3) =  axis(2)
        axis_cross(2, 1) =  axis(3)
        axis_cross(2, 3) = -axis(1)
        axis_cross(3, 1) = -axis(2)
        axis_cross(3, 2) =  axis(1)
        
        ! Tensor product of axis with itself
        temp33 = ZERO
        DO i = 1, 3
            DO j = 1, 3
                temp33(i, j) = axis(i) * axis(j)
            END DO
        END DO
        
        ! Rodrigues' formula: R = I + sin(θ)*K + (1-cos(θ))*K²
        R = I33 + sin_theta * axis_cross + (ONE - cos_theta) * MATMUL(axis_cross, axis_cross)
    END IF
    
    status%code = 0
    
END SUBROUTINE PH_Elem_B31_Fbar_RodriguesFormula

END SUBROUTINE PH_Elem_B31_Fbar_DeformationGradient

! =============================================================================
! PH_Elem_B31_Fbar_ComputeFbar
! =============================================================================
! Purpose: Compute F-bar version of deformation gradient
!
! F_bar = J_avg^(1/3) × F / J^(1/3)
!
! This ensures isochoric (volume-preserving) strain while allowing
! volumetric stress response through the pressure field.
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_ComputeFbar(&
    desc, state, algo_ctx, &
    F_matrix, J_det, &
    F_fbar, J_fbar, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(IN)  :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: F_matrix(3, 3, 2)
    REAL(wp),                   INTENT(IN)  :: J_det(2)
    REAL(wp),                   INTENT(OUT) :: F_fbar(3, 3, 2)
    REAL(wp),                   INTENT(OUT) :: J_fbar(2)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: J_avg, J_avg_13, J_13
    REAL(wp) :: F_avg(3, 3)
    REAL(wp) :: temp33(3, 3)
    INTEGER(i4) :: gp, i, j
    
    IF (.NOT. desc%fbar_active) THEN
        ! No F-bar, return original F
        F_fbar = F_matrix
        J_fbar = J_det
        status%code = 0
        status%message = "F-bar disabled, returning original F"
        RETURN
    END IF
    
    ! Compute average Jacobian (for F-bar)
    J_avg = (J_det(1) + J_det(2)) / TWO
    
    ! Ensure J_avg is positive for stability
    J_avg = MAX(J_avg, desc%J_limit)
    J_avg_13 = J_avg ** (ONE/THREE)
    
    ! Compute F-bar for each Gauss point
    DO gp = 1, 2
        J_13 = J_det(gp) ** (ONE/THREE)
        
        ! F_fbar = J_avg^(1/3) × F / J^(1/3)
        ! This is equivalent to F_dev scaled by average volume change
        
        DO i = 1, 3
            DO j = 1, 3
                F_fbar(i, j, gp) = (J_avg_13 / J_13) * F_matrix(i, j, gp)
            END DO
        END DO
        
        ! J_fbar = det(F_fbar) = J_avg (isochoric)
        J_fbar(gp) = J_avg
    END DO
    
    ! Store average F for strain computation
    algo_ctx%F_avg = (F_matrix(:, :, 1) + F_matrix(:, :, 2)) / TWO
    
    status%code = 0
    status%message = "F-bar deformation gradient computed"
    
END SUBROUTINE PH_Elem_B31_Fbar_ComputeFbar

! =============================================================================
! PH_Elem_B31_Fbar_Strain
! =============================================================================
! Purpose: Compute F-bar Green-Lagrange strain
!
! E_fbar = 0.5(F_fbar^T × F_fbar - I)
!
! Using deviatoric part ensures isochoric strain response.
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_Strain(&
    desc, state, algo_ctx, &
    F_fbar, &
    E_fbar, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: F_fbar(3, 3, 2)
    REAL(wp),                   INTENT(OUT) :: E_fbar(6)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: C_fbar(3, 3)            ! Right Cauchy-Green tensor
    REAL(wp) :: F_avg(3, 3)            ! Average F
    REAL(wp) :: E_tensor(3, 3)         ! Green-Lagrange strain tensor
    REAL(wp) :: xi, N1, N2
    REAL(wp) :: L, y_s, z_s           ! Section coordinates
    INTEGER(i4) :: gp, i, j
    
    ! Compute average F for strain (use center point)
    F_avg = (F_fbar(:, :, 1) + F_fbar(:, :, 2)) / TWO
    
    ! Compute C_fbar = F_fbar^T × F_fbar
    C_fbar = MATMUL(TRANSPOSE(F_avg), F_avg)
    
    ! Compute Green-Lagrange strain: E = 0.5(C - I)
    DO i = 1, 3
        DO j = 1, 3
            E_tensor(i, j) = 0.5_wp * (C_fbar(i, j) - &
                MERGE(ONE, ZERO, i==j))
        END DO
    END DO
    
    ! For beam, extract axial and bending strains
    ! E_fbar(1) = E_xx (axial)
    ! E_fbar(5) = 2*E_xz (shear in xz plane)
    ! E_fbar(6) = 2*E_xy (shear in xy plane)
    
    E_fbar = ZERO
    E_fbar(1) = E_tensor(1, 1)  ! E_xx
    E_fbar(5) = TWO * E_tensor(1, 3)  ! 2*E_xz
    E_fbar(6) = TWO * E_tensor(1, 2)  ! 2*E_xy
    
    ! Compute bending strain at section points (for composite section)
    ! E_bend = -y * κ_y - z * κ_z where κ = d²v/dx²
    L = desc%L
    ! Approximate curvature from strain gradient
    ! This is simplified; full implementation requires section integration
    
    ! Store in state
    state%E_fbar_axial = E_tensor(1, 1)
    
    ! Compute volumetric strain for pressure calculation
    ! ε_vol = tr(E) = ln(J) ≈ J - 1 for small strains
    state%eps_vol = LOG((E_tensor(1,1) + ONE) * &
                        (E_tensor(2,2) + ONE) * &
                        (E_tensor(3,3) + ONE))
    
    status%code = 0
    status%message = "F-bar strain computed"
    
END SUBROUTINE PH_Elem_B31_Fbar_Strain

! =============================================================================
! PH_Elem_B31_Fbar_StressUpdate
! =============================================================================
! Purpose: Compute stress using F-bar strain
!
! For nearly incompressible material:
!   σ = σ_dev + p × I
!   where:
!     σ_dev = K_dev × ε_dev (deviatoric stress)
!     p = -κ × ε_vol (hydrostatic pressure)
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_StressUpdate(&
    desc, state, algo_ctx, &
    E_fbar, &
    sigma_fbar, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(INOUT) :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: E_fbar(6)
    REAL(wp),                   INTENT(OUT) :: sigma_fbar(6)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, kappa
    REAL(wp) :: lambda, G_shear
    REAL(wp) :: D_matrix(6, 6)
    REAL(wp) :: K_dev, K_bulk
    REAL(wp) :: eps_vol, p_vol
    REAL(wp) :: eps_dev(6), sigma_dev(6)
    
    ! Extract material properties
    E = desc%E
    nu = desc%nu
    G = desc%G
    kappa = desc%kappa
    
    ! Compute Lame parameters
    lambda = E * nu / ((ONE + nu) * (ONE - TWO*nu))
    G_shear = E / (TWO * (ONE + nu))
    
    ! Bulk and shear moduli for volumetric/deviatoric split
    K_bulk = E / (THREE * (ONE - TWO*nu))  ! Bulk modulus
    K_dev = E / (ONE + nu)  ! Deviatoric modulus
    
    ! Compute volumetric strain
    eps_vol = E_fbar(1) + E_fbar(2) + E_fbar(3)
    
    ! Compute hydrostatic pressure (negative for compression)
    p_vol = -kappa * eps_vol
    state%p_vol = p_vol
    state%eps_vol = eps_vol
    
    ! Compute deviatoric strain
    eps_dev = E_fbar
    eps_dev(1) = eps_dev(1) - eps_vol / THREE
    eps_dev(2) = eps_dev(2) - eps_vol / THREE
    eps_dev(3) = eps_dev(3) - eps_vol / THREE
    
    ! Compute deviatoric stress using 2G
    sigma_dev(1) = TWO * G_shear * eps_dev(1)
    sigma_dev(2) = TWO * G_shear * eps_dev(2)
    sigma_dev(3) = TWO * G_shear * eps_dev(3)
    sigma_dev(4) = TWO * G_shear * eps_dev(4)  ! τ_yz
    sigma_dev(5) = TWO * G_shear * eps_dev(5)  ! τ_xz
    sigma_dev(6) = TWO * G_shear * eps_dev(6)  ! τ_xy
    
    ! Total stress = deviatoric + pressure (tensorial)
    ! For beam, we store in Voigt format with pressure contribution
    sigma_fbar = sigma_dev
    
    ! Add pressure to diagonal components (for 3D representation)
    ! σ_xx = σ_dev_xx - p, etc.
    sigma_fbar(1) = sigma_fbar(1) + p_vol  ! σ_xx
    sigma_fbar(2) = sigma_fbar(2) + p_vol  ! σ_yy
    sigma_fbar(3) = sigma_fbar(3) + p_vol  ! σ_zz
    
    ! Store in state
    state%sigma_axial = sigma_fbar(1)
    state%pressure = p_vol
    
    ! Build F-bar constitutive matrix for stiffness
    CALL PH_Elem_B31_Fbar_ConstitutiveMatrix(desc, algo_ctx, D_matrix, status)
    
    status%code = 0
    status%message = "F-bar stress updated"
    
END SUBROUTINE PH_Elem_B31_Fbar_StressUpdate

! =============================================================================
! PH_Elem_B31_Fbar_ConstitutiveMatrix
! =============================================================================
! Purpose: Compute F-bar constitutive matrix
!
! D_fbar = D_dev + D_vol
!
! where D_dev = 2G × P (deviatoric part)
!       D_vol = κ × 1⊗1 (volumetric part)
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_ConstitutiveMatrix(&
    desc, algo_ctx, &
    D_matrix, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(OUT) :: D_matrix(6, 6)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: E, nu, G, kappa
    REAL(wp) :: lambda, G_shear
    REAL(wp) :: D_dev(6, 6), D_vol(6, 6)
    INTEGER(i4) :: i, j
    
    ! Extract material properties
    E = desc%E
    nu = desc%nu
    G = desc%G
    kappa = desc%kappa
    
    ! Lame parameters
    lambda = E * nu / ((ONE + nu) * (ONE - TWO*nu))
    G_shear = E / (TWO * (ONE + nu))
    
    ! Initialize
    D_matrix = ZERO
    
    ! Deviatoric part D_dev = 2G × (I_dev ⊗ I_dev)
    ! For plane strain beam approximation:
    ! Simplified 6x6 elasticity matrix
    ! D_ij = λ for i,j = 1,2,3 and i=j
    ! D_ij = 2G for i=j and i>3 (shear)
    ! D_ij = 0 for i≠j and i,j ≤ 3 (isochoric)
    
    ! Axial terms
    D_matrix(1, 1) = lambda + TWO * G_shear  ! E_xx → σ_xx
    D_matrix(2, 2) = lambda + TWO * G_shear
    D_matrix(3, 3) = lambda + TWO * G_shear
    
    ! Coupling terms
    D_matrix(1, 2) = lambda
    D_matrix(1, 3) = lambda
    D_matrix(2, 1) = lambda
    D_matrix(2, 3) = lambda
    D_matrix(3, 1) = lambda
    D_matrix(3, 2) = lambda
    
    ! Shear terms
    D_matrix(4, 4) = G_shear  ! τ_yz
    D_matrix(5, 5) = G_shear  ! τ_xz
    D_matrix(6, 6) = G_shear  ! τ_xy
    
    ! Volumetric coupling (for F-bar)
    ! D_vol = κ × [1,1,1,0,0,0]^T × [1,1,1,0,0,0]
    IF (desc%volumetric_coupling) THEN
        DO i = 1, 3
            DO j = 1, 3
                D_vol(i, j) = kappa - lambda
            END DO
        END DO
        D_vol(4, 4) = kappa / TWO
        D_vol(5, 5) = kappa / TWO
        D_vol(6, 6) = kappa / TWO
        
        D_matrix = D_matrix + D_vol
    END IF
    
    ! Store in context
    algo_ctx%D_fbar = D_matrix
    
    status%code = 0
    status%message = "F-bar constitutive matrix computed"
    
END SUBROUTINE PH_Elem_B31_Fbar_ConstitutiveMatrix

! =============================================================================
! PH_Elem_B31_Fbar_StiffnessMatrix
! =============================================================================
! Purpose: Compute F-bar tangent stiffness matrix
!
! K_fbar = ∫ B_fbar^T × D_fbar × B_fbar dV
!
! Where B_fbar is the strain-displacement matrix using F-bar strains.
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_StiffnessMatrix(&
    desc, state, algo_ctx, &
    coords_0, coords_t, &
    K_fbar, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(IN)  :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords_0(3, 2)
    REAL(wp),                   INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                   INTENT(OUT) :: K_fbar(12, 12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: F_matrix(3, 3, 2), J_det(2)
    REAL(wp) :: F_fbar(3, 3, 2), J_fbar(2)
    REAL(wp) :: E_fbar(6), sigma_fbar(6)
    REAL(wp) :: D_matrix(6, 6)
    REAL(wp) :: B_matrix(6, 12)
    REAL(wp) :: L, E, G, A
    REAL(wp) :: xi, J_0, w_gauss
    REAL(wp) :: dN1, dN2
    REAL(wp) :: K_axial(2, 2), K_bend(2, 2), K_shear(2, 2)
    INTEGER(i4) :: gp, i, j, k
    
    ! Initialize
    K_fbar = ZERO
    K_axial = ZERO
    K_bend = ZERO
    K_shear = ZERO
    
    ! Extract properties
    L = desc%L
    E = desc%E
    G = desc%G
    A = desc%A
    
    ! Compute deformation gradient
    CALL PH_Elem_B31_Fbar_DeformationGradient(&
        desc, state, coords_0, coords_t, &
        F_matrix, J_det, status)
    
    ! Compute F-bar deformation gradient
    CALL PH_Elem_B31_Fbar_ComputeFbar(&
        desc, state, algo_ctx, &
        F_matrix, J_det, &
        F_fbar, J_fbar, status)
    
    ! Gauss integration
    DO gp = 1, algo_ctx%n_gauss
        xi = algo_ctx%gauss_pts(gp)
        w_gauss = algo_ctx%gauss_wts(gp)
        J_0 = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Build B_fbar matrix for axial strain
        ! E_xx = dN1*u1 + dN2*u7 for 2-node beam
        B_matrix = ZERO
        B_matrix(1, 1) = dN1 / L  ! ∂E_xx/∂u1
        B_matrix(1, 7) = dN2 / L  ! ∂E_xx/∂u7
        
        ! Bending contributions
        ! κ_y = d²N/dx² for bending
        B_matrix(1, 2) = -(SIX - TWELVE*xi) / (L*L)  ! z * κ_z
        B_matrix(1, 3) = -(SIX - TWELVE*xi) / (L*L)  ! y * κ_y
        B_matrix(1, 8) = (SIX - TWELVE*xi) / (L*L)
        B_matrix(1, 9) = (SIX - TWELVE*xi) / (L*L)
        
        ! Shear contributions
        IF (desc%nu < 0.49_wp) THEN  ! Not nearly incompressible
            B_matrix(5, 2) = dN1 / L  ! γ_xz
            B_matrix(5, 6) = -ONE
            B_matrix(5, 8) = dN2 / L
            B_matrix(5, 12) = -ONE
            
            B_matrix(6, 3) = dN1 / L  ! γ_xy
            B_matrix(6, 5) = ONE
            B_matrix(6, 9) = dN2 / L
            B_matrix(6, 11) = ONE
        END IF
        
        ! Compute F-bar strain
        CALL PH_Elem_B31_Fbar_Strain(&
            desc, state, algo_ctx, &
            F_fbar, E_fbar, status)
        
        ! Compute stress
        CALL PH_Elem_B31_Fbar_StressUpdate(&
            desc, state, algo_ctx, &
            E_fbar, sigma_fbar, status)
        
        ! Get constitutive matrix
        D_matrix = algo_ctx%D_fbar
        
        ! K_fbar += B^T × D × B × weight
        DO i = 1, 12
            DO j = 1, 12
                DO k = 1, 6
                    K_fbar(i, j) = K_fbar(i, j) + &
                        B_matrix(k, i) * D_matrix(k, k) * &
                        B_matrix(k, j) * w_gauss * J_0
                END DO
            END DO
        END DO
    END DO
    
    ! Ensure symmetry
    DO i = 1, 12
        DO j = i+1, 12
            K_fbar(j, i) = K_fbar(i, j)
        END DO
    END DO
    
    ! Store in context
    algo_ctx%K_fbar = K_fbar
    
    status%code = 0
    status%message = "F-bar stiffness matrix computed"
    
END SUBROUTINE PH_Elem_B31_Fbar_StiffnessMatrix

! =============================================================================
! PH_Elem_B31_Fbar_InternalForce
! =============================================================================
! Purpose: Compute internal force vector using F-bar method
!
! R_int = ∫ B_fbar^T × σ_fbar dV
! =============================================================================
SUBROUTINE PH_Elem_B31_Fbar_InternalForce(&
    desc, state, algo_ctx, &
    coords_0, coords_t, &
    R_int, &
    status)
    
    TYPE(B31_Fbar_Desc_Type),   INTENT(IN)  :: desc
    TYPE(B31_Fbar_State_Type),  INTENT(IN)  :: state
    TYPE(B31_Fbar_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords_0(3, 2)
    REAL(wp),                   INTENT(IN)  :: coords_t(3, 2)
    REAL(wp),                   INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: F_matrix(3, 3, 2), J_det(2)
    REAL(wp) :: F_fbar(3, 3, 2), J_fbar(2)
    REAL(wp) :: E_fbar(6), sigma_fbar(6)
    REAL(wp) :: B_matrix(6, 12)
    REAL(wp) :: L, xi, J_0, w_gauss
    REAL(wp) :: dN1, dN2
    INTEGER(i4) :: gp, i, k
    
    ! Initialize
    R_int = ZERO
    
    L = desc%L
    
    ! Compute deformation gradients
    CALL PH_Elem_B31_Fbar_DeformationGradient(&
        desc, state, coords_0, coords_t, &
        F_matrix, J_det, status)
    
    CALL PH_Elem_B31_Fbar_ComputeFbar(&
        desc, state, algo_ctx, &
        F_matrix, J_det, &
        F_fbar, J_fbar, status)
    
    ! Gauss integration
    DO gp = 1, algo_ctx%n_gauss
        xi = algo_ctx%gauss_pts(gp)
        w_gauss = algo_ctx%gauss_wts(gp)
        J_0 = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Build B matrix
        B_matrix = ZERO
        B_matrix(1, 1) = dN1 / L
        B_matrix(1, 7) = dN2 / L
        
        ! Compute strain and stress
        CALL PH_Elem_B31_Fbar_Strain(&
            desc, state, algo_ctx, F_fbar, E_fbar, status)
        
        CALL PH_Elem_B31_Fbar_StressUpdate(&
            desc, state, algo_ctx, E_fbar, sigma_fbar, status)
        
        ! R_int += B^T × σ × weight
        DO i = 1, 12
            DO k = 1, 6
                R_int(i) = R_int(i) + &
                    B_matrix(k, i) * sigma_fbar(k) * w_gauss * J_0
            END DO
        END DO
    END DO
    
    ! Store in state
    state%evo%R_int = R_int
    
    status%code = 0
    status%message = "F-bar internal force computed"
    
END SUBROUTINE PH_Elem_B31_Fbar_InternalForce

END MODULE PH_Elem_B31Fbar