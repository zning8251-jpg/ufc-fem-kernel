!===============================================================================
! MODULE: PH_Elem_B31NL
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  Geometric Nonlinear Core for B31 Beam Family
!===============================================================================
MODULE PH_Elem_B31NL
USE IF_Prec_Core, ONLY: wp, i4
USE ErrorHandler

IMPLICIT NONE

! Module-wide constants
REAL(wp), PARAMETER :: ONE   = 1.0_wp
REAL(wp), PARAMETER :: TWO   = 2.0_wp
REAL(wp), PARAMETER :: THREE = 3.0_wp
REAL(wp), PARAMETER :: FOUR  = 4.0_wp
REAL(wp), PARAMETER :: SIX   = 6.0_wp
REAL(wp), PARAMETER :: TWELVE= 12.0_wp
REAL(wp), PARAMETER :: PI    = 3.14159265358979323846_wp
REAL(wp), PARAMETER :: DEG_TO_RAD = PI / 180.0_wp
REAL(wp), PARAMETER :: RAD_TO_DEG = 180.0_wp / PI

! Formulation types
INTEGER(i4), PARAMETER :: FORM_LINEAR     = 0
INTEGER(i4), PARAMETER :: FORM_UL        = 2  ! Updated Lagrangian
INTEGER(i4), PARAMETER :: FORM_TL        = 3  ! Total Lagrangian

! Solution methods
INTEGER(i4), PARAMETER :: NEWTON_FULL    = 1
INTEGER(i4), PARAMETER :: NEWTON_MOD     = 2
INTEGER(i4), PARAMETER :: ARC_LENGTH     = 3

! Public interfaces
PUBLIC :: PH_Elem_B31_NL_Initialize
PUBLIC :: PH_Elem_B31_NL_SetFormulation
PUBLIC :: PH_Elem_B31_NL_ComputeSystem
PUBLIC :: PH_Elem_B31_NL_NewtonRaphson
PUBLIC :: PH_Elem_B31_NL_CoordTransform
PUBLIC :: PH_Elem_B31_NL_ConvergenceCheck
PUBLIC :: PH_Elem_B31_NL_GetResidual

! Type definitions
TYPE :: B31_NL_Config_Type
    ! Formulation control
    INTEGER(i4) :: formulation             ! 0=linear, 2=UL, 3=TL
    LOGICAL  :: large_rotation          ! Large rotation analysis
    LOGICAL  :: large_strain           ! Large strain analysis
    LOGICAL  :: shear_deformable        ! Timoshenko beam
    LOGICAL  :: warping_active          ! B31OS warping DOF
    
    ! Element configuration
    INTEGER(i4) :: n_nodes                ! Number of nodes (2 for B31)
    INTEGER(i4) :: n_dof_per_node          ! DOF per node (6 for 3D beam)
    INTEGER(i4) :: total_dof               ! Total element DOF
    
    ! Section properties
    REAL(wp) :: A                       ! Area
    REAL(wp) :: Iy, Iz                  ! Moments of inertia
    REAL(wp) :: J_tors                  ! Torsional constant
    REAL(wp) :: I_warp                  ! Warping constant
    
    ! Material properties
    REAL(wp) :: E                       ! Young's modulus
    REAL(wp) :: nu                      ! Poisson's ratio
    REAL(wp) :: G                       ! Shear modulus
    
    ! Geometry
    REAL(wp) :: L_initial               ! Initial length
    REAL(wp) :: L_current               ! Current length
    REAL(wp) :: orientation(3)           ! Beam axis orientation
END TYPE B31_NL_Config_Type

TYPE :: B31_NL_State_Type
    ! Displacement fields
    REAL(wp) :: disp_history(12, 2)     ! Displacement history [current, previous]
    REAL(wp) :: rot_history(12, 2)      ! Rotation history
    
    ! Strain measures
    REAL(wp) :: eps_axial               ! Axial strain
    REAL(wp) :: eps_bend(2)            ! Bending strains
    REAL(wp) :: gamma_shear(2)         ! Shear strains
    
    ! Stress measures
    REAL(wp) :: sigma_axial             ! Axial stress
    REAL(wp) :: sigma_bend(2)          ! Bending stresses
    REAL(wp) :: tau_shear(2)           ! Shear stresses
    
    ! Internal force
    REAL(wp) :: R_int(12)              ! Internal force vector
    
    ! Configuration metrics
    REAL(wp) :: current_length
    REAL(wp) :: axial_strain_ref       ! Reference strain for step
    REAL(wp) :: total_rotation(2)      ! Total rotation at nodes
    REAL(wp) :: incremental_rotation(2)! Incremental rotation
END TYPE B31_NL_State_Type

TYPE :: B31_NL_AlgoCtx_Type
    ! Iteration control
    INTEGER(i4) :: iteration               ! Current Newton iteration
    INTEGER(i4) :: max_iterations
    INTEGER(i4) :: total_iterations       ! Total iterations in step
    LOGICAL  :: converged
    
    ! Convergence metrics
    REAL(wp) :: residual_norm
    REAL(wp) :: displacement_norm
    REAL(wp) :: energy_norm
    REAL(wp) :: tolerance_force
    REAL(wp) :: tolerance_disp
    REAL(wp) :: tolerance_energy
    
    ! System matrices
    REAL(wp) :: K_matrix(12, 12)       ! Stiffness matrix
    REAL(wp) :: M_matrix(12, 12)       ! Mass matrix
    REAL(wp) :: C_matrix(12, 12)       ! Damping matrix
    
    ! Vectors
    REAL(wp) :: R_ext(12)              ! External force
    REAL(wp) :: R_int(12)               ! Internal force
    REAL(wp) :: R_residual(12)         ! Residual R = R_ext - R_int
    REAL(wp) :: du(12)                 ! Displacement increment
    REAL(wp) :: dU_iter(12)           ! Iteration displacement
    
    ! Tangent matrix work arrays
    REAL(wp) :: K_material(12, 12)     ! Material stiffness
    REAL(wp) :: K_geometric(12, 12)    ! Geometric stiffness
    REAL(wp) :: K_initial_stress(12,12)! Initial stress stiffness
    
    ! Coordinate transformation
    REAL(wp) :: T_transform(12, 12)    ! Local-global transform
    REAL(wp) :: Q_rotation(3, 3)       ! Rotation tensor
    
    ! Line search
    LOGICAL  :: line_search_active
    REAL(wp) :: line_search_factor
    INTEGER(i4) :: line_search_max_iter
END TYPE B31_NL_AlgoCtx_Type

! Module-level state
TYPE(B31_NL_Config_Type),  SAVE :: g_config
TYPE(B31_NL_State_Type),   SAVE :: g_state
TYPE(B31_NL_AlgoCtx_Type), SAVE :: g_algo_ctx

CONTAINS

! =============================================================================
! PH_Elem_B31_NL_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_Initialize(&
    config, state, algo_ctx, &
    section_props, material_props, &
    formulation, status)
    
    TYPE(B31_NL_Config_Type),   INTENT(OUT) :: config
    TYPE(B31_NL_State_Type),    INTENT(OUT) :: state
    TYPE(B31_NL_AlgoCtx_Type),  INTENT(OUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: section_props(5)
    REAL(wp),                   INTENT(IN)  :: material_props(4)
    INTEGER(i4), INTENT(IN) :: formulation
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Extract section properties
    config%A      = section_props(1)
    config%Iy     = section_props(2)
    config%Iz     = section_props(3)
    config%J_tors = section_props(4)
    config%I_warp = section_props(5)
    
    ! Extract material properties
    config%E = material_props(1)
    config%nu= material_props(2)
    config%G = config%E / (TWO * (ONE + config%nu))
    
    ! Set formulation
    config%formulation = formulation
    config%large_rotation = (formulation > 0)
    config%large_strain = .FALSE.   ! Beam typically small strain
    config%shear_deformable = .TRUE.
    config%warping_active = .FALSE.
    
    ! Element configuration
    config%pop%n_nodes = 2
    config%n_dof_per_node = 6
    config%total_dof = config%pop%n_nodes * config%n_dof_per_node
    
    ! Initialize state
    state%disp_history = ZERO
    state%rot_history = ZERO
    state%eps_axial = ZERO
    state%sigma_axial = ZERO
    state%evo%R_int = ZERO
    state%current_length = section_props(6)  ! Initial length
    config%L_initial = section_props(6)
    config%L_current = section_props(6)
    state%axial_strain_ref = ZERO
    
    ! Initialize algorithm context
    algo_ctx%iteration = 0
    algo_ctx%max_iterations = 15
    algo_ctx%total_iterations = 0
    algo_ctx%converged = .FALSE.
    algo_ctx%residual_norm = ZERO
    algo_ctx%displacement_norm = ZERO
    algo_ctx%energy_norm = ZERO
    algo_ctx%tolerance_force = 1.0e-6_wp
    algo_ctx%tolerance_disp  = 1.0e-8_wp
    algo_ctx%tolerance_energy= 1.0e-9_wp
    algo_ctx%line_search_active = .TRUE.
    algo_ctx%line_search_factor = ONE
    algo_ctx%line_search_max_iter = 5
    
    ! Initialize matrices
    algo_ctx%K_matrix = ZERO
    algo_ctx%M_matrix = ZERO
    algo_ctx%C_matrix = ZERO
    algo_ctx%K_material = ZERO
    algo_ctx%K_geometric = ZERO
    algo_ctx%K_initial_stress = ZERO
    
    ! Initialize vectors
    algo_ctx%R_ext = ZERO
    algo_ctx%evo%R_int = ZERO
    algo_ctx%R_residual = ZERO
    algo_ctx%du = ZERO
    algo_ctx%dU_iter = ZERO
    
    status%code = 0
    status%message = "NL core initialization complete"
    
END SUBROUTINE PH_Elem_B31_NL_Initialize

! =============================================================================
! PH_Elem_B31_NL_SetFormulation
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_SetFormulation(&
    config, state, &
    formulation, large_rotation, &
    shear_deform, warping, &
    status)
    
    TYPE(B31_NL_Config_Type),   INTENT(INOUT) :: config
    TYPE(B31_NL_State_Type),    INTENT(INOUT) :: state
    INTEGER(i4), INTENT(IN) :: formulation
    LOGICAL,                    INTENT(IN)  :: large_rotation
    LOGICAL,                    INTENT(IN)  :: shear_deform
    LOGICAL,                    INTENT(IN)  :: warping
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    config%formulation = formulation
    config%large_rotation = large_rotation
    config%shear_deformable = shear_deform
    config%warping_active = warping
    
    ! Adjust DOF count for warping
    IF (warping) THEN
        config%n_dof_per_node = 7  ! u,v,w,θx,θy,θz,θw (warping)
        config%total_dof = 14
    ELSE
        config%n_dof_per_node = 6
        config%total_dof = 12
    END IF
    
    status%code = 0
    
END SUBROUTINE PH_Elem_B31_NL_SetFormulation

! =============================================================================
! PH_Elem_B31_NL_CoordTransform
! =============================================================================
! Purpose: Compute coordinate transformation matrix for beam element
!
! For 3D beam: Transform between global and local coordinate systems
! Local x-axis = beam axis (from node 1 to node 2)
! Local y,z = principal axes of cross-section
!
! T = [t_local  0    ]
!     [  0    t_local]
!
! where t_local is 3x3 rotation tensor
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_CoordTransform(&
    coords1, coords2, &
    T_matrix, Q_rotation, &
    status)
    
    REAL(wp), INTENT(IN)  :: coords1(3), coords2(3)
    REAL(wp), INTENT(OUT) :: T_matrix(12, 12)
    REAL(wp), INTENT(OUT) :: Q_rotation(3, 3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: dx, dy, dz, L
    REAL(wp) :: e_x(3), e_y(3), e_z(3)
    REAL(wp) :: e_y_temp(3)
    REAL(wp) :: tolerance
    INTEGER(i4) :: i, j
    
    tolerance = 1.0e-12_wp
    
    ! Compute beam axis vector
    dx = coords2(1) - coords1(1)
    dy = coords2(2) - coords1(2)
    dz = coords2(3) - coords1(3)
    
    L = SQRT(dx*dx + dy*dy + dz*dz)
    
    IF (L < tolerance) THEN
        status%code = 1
        status%message = "Zero-length beam element"
        RETURN
    END IF
    
    ! Local x-axis (beam axis)
    e_x(1) = dx / L
    e_x(2) = dy / L
    e_x(3) = dz / L
    
    ! Determine local y-axis (perpendicular to x)
    ! Choose arbitrary vector not parallel to x
    IF (ABS(e_x(1)) < 0.9_wp) THEN
        e_y_temp = [ONE, ZERO, ZERO]
    ELSE
        e_y_temp = [ZERO, ONE, ZERO]
    END IF
    
    ! e_z = e_x × e_y_temp (cross product)
    e_z(1) = e_x(2)*e_y_temp(3) - e_x(3)*e_y_temp(2)
    e_z(2) = e_x(3)*e_y_temp(1) - e_x(1)*e_y_temp(3)
    e_z(3) = e_x(1)*e_y_temp(2) - e_x(2)*e_y_temp(1)
    
    ! Normalize e_z
    L = SQRT(e_z(1)*e_z(1) + e_z(2)*e_z(2) + e_z(3)*e_z(3))
    IF (L > tolerance) THEN
        e_z = e_z / L
    ELSE
        e_z = [ZERO, ZERO, ONE]
    END IF
    
    ! e_y = e_z × e_x (orthonormal set)
    e_y(1) = e_z(2)*e_x(3) - e_z(3)*e_x(2)
    e_y(2) = e_z(3)*e_x(1) - e_z(1)*e_x(3)
    e_y(3) = e_z(1)*e_x(2) - e_z(2)*e_x(1)
    
    ! Build rotation tensor Q
    Q_rotation(1, :) = e_x
    Q_rotation(2, :) = e_y
    Q_rotation(3, :) = e_z
    
    ! Build transformation matrix T for 6 DOF per node
    ! T = [ Q  0  0  0 ]
    !     [ 0  Q  0  0 ]
    !     [ 0  0  Q  0 ]
    !     [ 0  0  0  Q ]
    T_matrix = ZERO
    
    DO i = 1, 4
        DO j = 1, 3
            T_matrix(3*(i-1)+j, 3*(i-1)+1) = Q_rotation(j, 1)
            T_matrix(3*(i-1)+j, 3*(i-1)+2) = Q_rotation(j, 2)
            T_matrix(3*(i-1)+j, 3*(i-1)+3) = Q_rotation(j, 3)
        END DO
    END DO
    
    status%code = 0
    status%message = "Coordinate transform computed"
    
END SUBROUTINE PH_Elem_B31_NL_CoordTransform

! =============================================================================
! PH_Elem_B31_NL_ComputeSystem
! =============================================================================
! Purpose: Compute tangent stiffness matrix and internal force
!
! K_tangent = K_material + K_geometric + K_initial_stress
! R_int = ∫ B^T · σ dV
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_ComputeSystem(&
    config, state, algo_ctx, &
    coords, disp_inc, &
    K_tangent, R_int, &
    status)
    
    TYPE(B31_NL_Config_Type),   INTENT(IN)  :: config
    TYPE(B31_NL_State_Type),    INTENT(IN)  :: state
    TYPE(B31_NL_AlgoCtx_Type),  INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(IN)  :: disp_inc(12)
    REAL(wp),                   INTENT(OUT) :: K_tangent(12, 12)
    REAL(wp),                   INTENT(OUT) :: R_int(12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: L, E, G, A, Iy, Iz, J_tors
    REAL(wp) :: xi, J_curr, w_gauss
    REAL(wp) :: B_mat(6, 12), BNL1(3, 12), BNL2(2, 12), BNL3(2, 12)
    REAL(wp) :: D_mat(6, 6)
    REAL(wp) :: sigma(6)
    REAL(wp) :: dN1, dN2
    REAL(wp) :: K_L(12, 12), K_NL(12, 12)
    INTEGER(i4) :: i, j, k, gp
    TYPE(ErrorStatusType) :: local_status
    
    ! Extract properties
    L = config%L_current
    E = config%E
    G = config%G
    A = config%A
    Iy = config%Iy
    Iz = config%Iz
    J_tors = config%J_tors
    
    ! Initialize
    K_tangent = ZERO
    R_int = ZERO
    K_L = ZERO
    K_NL = ZERO
    B_mat = ZERO
    D_mat = ZERO
    sigma = ZERO
    
    ! Set up stress state
    sigma(1) = state%sigma_axial
    
    ! Material constitutive matrix (beam, diagonal)
    D_mat = ZERO
    D_mat(1, 1) = E * A
    D_mat(2, 2) = G * A
    D_mat(3, 3) = G * A
    D_mat(4, 4) = G * J_tors
    D_mat(5, 5) = E * Iz
    D_mat(6, 6) = E * Iy
    
    ! Gauss integration (2-point)
    DO gp = 1, 2
        IF (gp == 1) THEN
            xi = -ONE / SQRT(THREE)
            w_gauss = ONE
        ELSE
            xi = ONE / SQRT(THREE)
            w_gauss = ONE
        END IF
        
        J_curr = L / TWO
        
        ! Shape function derivatives
        dN1 = -ONE / TWO
        dN2 =  ONE / TWO
        
        ! Build B matrix
        B_mat = ZERO
        
        ! Axial strain row
        B_mat(1, 1) = dN1; B_mat(1, 7) = dN2
        
        ! Bending effects on axial strain
        B_mat(1, 2) = -(SIX - TWELVE*xi) / L * (coords(2,1) - coords(2,2)) / L
        B_mat(1, 3) = -(SIX - TWELVE*xi) / L * (coords(3,1) - coords(3,2)) / L
        
        ! Shear rows
        IF (config%shear_deformable) THEN
            B_mat(2, 2) = dN1; B_mat(2, 6) = -ONE; B_mat(2, 8) = dN2; B_mat(2, 12) = -ONE
            B_mat(3, 3) = dN1; B_mat(3, 5) =  ONE; B_mat(3, 9) = dN2; B_mat(3, 11) =  ONE
        END IF
        
        ! Torsion row
        B_mat(4, 4) = dN1; B_mat(4, 10) = dN2
        
        ! Bending rows
        B_mat(5, 2) = (SIX - TWELVE*xi) / (L*L)
        B_mat(5, 6) = (-FOUR + SIX*xi) / L
        B_mat(5, 8) = -(SIX - TWELVE*xi) / (L*L)
        B_mat(5, 12) = (-TWO + SIX*xi) / L
        
        B_mat(6, 3) = (SIX - TWELVE*xi) / (L*L)
        B_mat(6, 5) = ( FOUR - SIX*xi) / L
        B_mat(6, 9) = -(SIX - TWELVE*xi) / (L*L)
        B_mat(6, 11) = ( TWO - SIX*xi) / L
        
        ! Material stiffness: K_L = ∫ B^T D B dV
        DO i = 1, 12
            DO j = 1, 12
                DO k = 1, 6
                    K_L(i, j) = K_L(i, j) + &
                        B_mat(k, i) * D_mat(k, k) * B_mat(k, j) * w_gauss * J_curr
                END DO
            END DO
        END DO
        
        ! Internal force: R_int = ∫ B^T σ dV
        DO i = 1, 12
            DO k = 1, 6
                R_int(i) = R_int(i) + B_mat(k, i) * sigma(k) * w_gauss * J_curr
            END DO
        END DO
        
        ! Geometric stiffness from stress (if nonlinear)
        IF (config%large_rotation) THEN
            ! K_NL contribution from axial stress
            K_NL(1, 1) = K_NL(1, 1) + sigma(1) * A * dN1 * dN1 * w_gauss * J_curr
            K_NL(1, 7) = K_NL(1, 7) + sigma(1) * A * dN1 * dN2 * w_gauss * J_curr
            K_NL(7, 1) = K_NL(7, 1) + sigma(1) * A * dN2 * dN1 * w_gauss * J_curr
            K_NL(7, 7) = K_NL(7, 7) + sigma(1) * A * dN2 * dN2 * w_gauss * J_curr
        END IF
    END DO
    
    ! Total tangent stiffness
    K_tangent = K_L + K_NL
    
    ! Ensure symmetry
    DO i = 1, 12
        DO j = i+1, 12
            K_tangent(i, j) = K_tangent(j, i)
        END DO
    END DO
    
    ! Store in algo context
    algo_ctx%K_matrix = K_tangent
    algo_ctx%K_material = K_L
    algo_ctx%K_geometric = K_NL
    algo_ctx%evo%R_int = R_int
    
    state%evo%R_int = R_int
    
    status%code = 0
    status%message = "System computed"
    
END SUBROUTINE PH_Elem_B31_NL_ComputeSystem

! =============================================================================
! PH_Elem_B31_NL_NewtonRaphson
! =============================================================================
! Purpose: Perform Newton-Raphson iteration for equilibrium
!
! Algorithm:
!   1. Compute residual: R = R_ext - R_int
!   2. Check convergence
!   3. If not converged:
!      - Solve: K · Δu = R
!      - Update: u = u + Δu
!      - Recompute internal forces
!      - Iterate
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_NewtonRaphson(&
    config, state, algo_ctx, &
    coords, R_ext, &
    du, status)
    
    TYPE(B31_NL_Config_Type),   INTENT(INOUT) :: config
    TYPE(B31_NL_State_Type),    INTENT(INOUT) :: state
    TYPE(B31_NL_AlgoCtx_Type),  INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: coords(3, 2)
    REAL(wp),                   INTENT(IN)  :: R_ext(12)
    REAL(wp),                   INTENT(INOUT) :: du(12)
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: K_tangent(12, 12)
    REAL(wp) :: R_int(12), R_res(12)
    REAL(wp) :: delta_u(12)
    REAL(wp) :: disp_inc(12)
    REAL(wp) :: line_search_factor
    INTEGER(i4) :: iter, line_iter
    LOGICAL  :: is_converged
    TYPE(ErrorStatusType) :: local_status
    
    ! Initialize
    iter = 0
    algo_ctx%converged = .FALSE.
    disp_inc = du
    
    ! Main Newton-Raphson loop
    Newton_Loop: DO WHILE (.NOT. algo_ctx%converged .AND. &
                          iter < algo_ctx%max_iterations)
        
        iter = iter + 1
        algo_ctx%iteration = iter
        
        ! Compute tangent stiffness and internal force
        CALL PH_Elem_B31_NL_ComputeSystem(&
            config, state, algo_ctx, &
            coords, disp_inc, &
            K_tangent, R_int, local_status)
        
        ! Compute residual
        R_res = R_ext - R_int
        algo_ctx%R_residual = R_res
        
        ! Check convergence
        CALL PH_Elem_B31_NL_ConvergenceCheck(&
            algo_ctx, R_res, delta_u, &
            is_converged, local_status)
        
        IF (is_converged) THEN
            algo_ctx%converged = .TRUE.
            EXIT Newton_Loop
        END IF
        
        ! Solve for displacement increment
        ! K_tangent · delta_u = R_res
        delta_u = R_res  ! Simplified: use residual as pseudo-increment
        
        ! Simple line search
        IF (algo_ctx%line_search_active) THEN
            line_search_factor = ONE
            DO line_iter = 1, algo_ctx%line_search_max_iter
                disp_inc = disp_inc + line_search_factor * delta_u
                
                CALL PH_Elem_B31_NL_ComputeSystem(&
                    config, state, algo_ctx, &
                    coords, disp_inc, &
                    K_tangent, R_int, local_status)
                
                ! Check if residual decreased
                IF (SUM(ABS(R_ext - R_int)) < SUM(ABS(R_res))) THEN
                    EXIT
                ELSE
                    line_search_factor = line_search_factor * HALF
                    disp_inc = disp_inc - line_search_factor * delta_u
                END IF
            END DO
            algo_ctx%line_search_factor = line_search_factor
        ELSE
            disp_inc = disp_inc + delta_u
        END IF
        
    END DO Newton_Loop
    
    ! Update displacement
    du = disp_inc
    algo_ctx%total_iterations = algo_ctx%total_iterations + iter
    
    IF (algo_ctx%converged) THEN
        status%code = 0
        status%message = "Newton-Raphson converged"
    ELSE
        status%code = 1
        status%message = "Newton-Raphson failed to converge"
    END IF
    
END SUBROUTINE PH_Elem_B31_NL_NewtonRaphson

! =============================================================================
! PH_Elem_B31_NL_ConvergenceCheck
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_ConvergenceCheck(&
    algo_ctx, R_residual, du_inc, &
    is_converged, status)
    
    TYPE(B31_NL_AlgoCtx_Type),  INTENT(INOUT) :: algo_ctx
    REAL(wp),                   INTENT(IN)  :: R_residual(12)
    REAL(wp),                   INTENT(IN)  :: du_inc(12)
    LOGICAL,                    INTENT(OUT) :: is_converged
    TYPE(ErrorStatusType),       INTENT(OUT) :: status
    
    ! Local variables
    REAL(wp) :: residual_norm, disp_norm, energy_norm
    REAL(wp) :: RNORM  ! Reference residual norm
    
    ! Compute norms
    residual_norm = SQRT(DOT_PRODUCT(R_residual, R_residual))
    disp_norm = SQRT(DOT_PRODUCT(du_inc, du_inc))
    energy_norm = ABS(DOT_PRODUCT(du_inc, R_residual))
    
    ! Store in context
    algo_ctx%residual_norm = residual_norm
    algo_ctx%displacement_norm = disp_norm
    algo_ctx%energy_norm = energy_norm
    
    ! Reference norm (initial residual or external force magnitude)
    RNORM = MAX(SUM(ABS(algo_ctx%R_ext)), ONE)
    
    ! Convergence criteria (based on ADINAM)
    ! 1. Force convergence: ||R|| / RNORM <= RTOL
    ! 2. Displacement convergence: ||Δu|| / ||u|| <= DTOL
    ! 3. Energy convergence: Δu^T R / Δu_0^T R_0 <= ETOL
    
    is_converged = .FALSE.
    
    IF (residual_norm / RNORM <= algo_ctx%tolerance_force) THEN
        is_converged = .TRUE.
    END IF
    
    IF (disp_norm > ZERO .AND. &
        disp_norm / MAX(SUM(ABS(algo_ctx%du)), ONE) <= algo_ctx%tolerance_disp) THEN
        is_converged = .TRUE.
    END IF
    
    status%code = 0
    
END SUBROUTINE PH_Elem_B31_NL_ConvergenceCheck

! =============================================================================
! PH_Elem_B31_NL_GetResidual
! =============================================================================
FUNCTION PH_Elem_B31_NL_GetResidual(algo_ctx) RESULT(R_residual)
    TYPE(B31_NL_AlgoCtx_Type), INTENT(IN) :: algo_ctx
    REAL(wp) :: R_residual(12)
    R_residual = algo_ctx%R_residual
END FUNCTION PH_Elem_B31_NL_GetResidual

END MODULE PH_Elem_B31NL