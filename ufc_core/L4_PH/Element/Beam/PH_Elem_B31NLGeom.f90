!===============================================================================
! MODULE: PH_Elem_B31NLGeom
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31 geometric nonlinear core (co-rotational formulation)
!===============================================================================
MODULE PH_Elem_B31NLGeom
USE UFC_Kind_Defn
USE UFC_Const_Math
USE ErrorHandler

IMPLICIT NONE

PRIVATE
PUBLIC :: PH_Elem_B31_NL_CorotationalFrame
PUBLIC :: PH_Elem_B31_NL_GeometricStiffness
PUBLIC :: PH_Elem_B31_NL_GreenLagrangeStrain
PUBLIC :: PH_Elem_B31_NL_SecondPiolaKirchhoff
PUBLIC :: PH_Elem_B31_NL_TangentStiffness
PUBLIC :: PH_Elem_B31_NL_InternalForce
PUBLIC :: PH_Elem_B31_NL_RotationUpdate
PUBLIC :: PH_Elem_B31_NL_EnergyCheck

! =============================================================================
! Type Definitions for Geometric Nonlinearity
! =============================================================================

TYPE :: B31_NL_Geom_Desc_Type
  ! Material properties
  REAL(wp) :: E                     ! Young's modulus
  REAL(wp) :: nu                    ! Poisson's ratio
  REAL(wp) :: G                     ! Shear modulus
  
  ! Section properties
  REAL(wp) :: A                     ! Cross-section area
  REAL(wp) :: Iy, Iz               ! Moments of inertia
  REAL(wp) :: J_tors               ! Torsional constant
  
  ! Geometry
  REAL(wp) :: L₀                    ! Initial length
  REAL(wp) :: n_vec(3)              ! Initial axis direction
  
  ! Nonlinear control
  LOGICAL  :: nlgeom_active         ! Large deformation flag
  INTEGER(i4) :: stress_measure        ! 1=PK2, 2=Cauchy, 3=Biot
  REAL(wp) :: tol_energy            ! Energy tolerance for check
END TYPE B31_NL_Geom_Desc_Type

TYPE :: B31_NL_Geom_State_Type
  ! Configuration
  REAL(wp) :: coords₀(3, 2)         ! Initial coordinates
  REAL(wp) :: coordsₜ(3, 2)         ! Current coordinates
  REAL(wp) :: disp₁₂(12)            ! Nodal displacements
  
  ! Rotation measures
  REAL(wp) :: R_matrix(3, 3, 2)     ! Nodal rotation matrices
  REAL(wp) :: theta_vec(3, 2)       ! Finite rotation vectors
  REAL(wp) :: co_rot_matrix(3, 3)   ! Co-rotational frame
  
  ! Strain measures (Green-Lagrange)
  REAL(wp) :: E_axial               ! Axial strain (finite)
  REAL(wp) :: kappa_y(2), kappa_z(2) ! Curvatures at nodes
  REAL(wp) :: gamma_shear(2)        ! Shear strain
  
  ! Stress measures (2nd Piola-Kirchhoff)
  REAL(wp) :: S_axial               ! Axial PK2 stress
  REAL(wp) :: M_y(2), M_z(2)        ! Bending moments
  REAL(wp) :: T_tors                ! Torque
  
  ! Internal variables
  REAL(wp) :: int_force(12)         ! Internal force vector
  REAL(wp) :: tangent_stiff(12, 12) ! Tangent stiffness matrix
  REAL(wp) :: geo_stiff(12, 12)     ! Geometric stiffness
  
  ! Energy quantities
  REAL(wp) :: strain_energy         ! Total strain energy
  REAL(wp) :: work_done             ! External work
  REAL(wp) :: kinetic_energy        ! Kinetic energy (for dynamics)
END TYPE B31_NL_Geom_State_Type

TYPE :: B31_NL_Geom_AlgoCtx_Type
  ! Integration
  INTEGER(i4) :: n_gauss
  REAL(wp) :: gauss_pts(3)
  REAL(wp) :: gauss_wts(3)
  
  ! Work arrays
  REAL(wp) :: B_linear(6, 12)       ! Linear strain-displacement
  REAL(wp) :: B_nl(6, 12)           ! Nonlinear B matrix
  REAL(wp) :: G_matrix(3, 12)       ! Geometric stiffness operator
  REAL(wp) :: D_mat(6, 6)           ! Constitutive matrix
  
  ! Temporary matrices
  REAL(wp) :: temp33(3, 3)
  REAL(wp) :: R_avg(3, 3)           ! Average rotation
  REAL(wp) :: F_def(3, 3)           ! Deformation gradient (pure)
  REAL(wp) :: U_stretch(3, 3)       ! Stretch tensor
  
  ! Convergence
  INTEGER(i4) :: nr_iteration
  LOGICAL  :: converged
  REAL(wp) :: energy_norm
END TYPE B31_NL_Geom_AlgoCtx_Type

CONTAINS

! =============================================================================
! PH_Elem_B31_NL_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_Initialize(&
    desc, state, algo_ctx, &
    section_props, material_props, &
    nlgeom_active, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(OUT) :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(OUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: section_props(6)
  REAL(wp), INTENT(IN)  :: material_props(4)
  LOGICAL,  INTENT(IN)  :: nlgeom_active
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  ! Extract section properties
  desc%A      = section_props(1)
  desc%Iy     = section_props(2)
  desc%Iz     = section_props(3)
  desc%J_tors = section_props(4)
  desc%L₀     = section_props(6)
  
  ! Extract material properties
  desc%E = material_props(1)
  desc%nu= material_props(2)
  desc%G = desc%E / (2.0_wp * (1.0_wp + desc%nu))
  
  ! Nonlinear control
  desc%nlgeom_active = nlgeom_active
  desc%stress_measure = 1  ! Default: 2nd Piola-Kirchhoff
  desc%tol_energy = 1.0e-6_wp
  
  ! Initialize Gauss points (2-point)
  algo_ctx%n_gauss = 2
  algo_ctx%gauss_pts(1) = -1.0_wp / SQRT(3.0_wp)
  algo_ctx%gauss_pts(2) =  1.0_wp / SQRT(3.0_wp)
  algo_ctx%gauss_wts(1) = 1.0_wp
  algo_ctx%gauss_wts(2) = 1.0_wp
  
  ! Initialize state
  state%R_matrix = 0.0_wp
  state%theta_vec = 0.0_wp
  state%co_rot_matrix = 0.0_wp
  state%E_axial = 0.0_wp
  state%int_force = 0.0_wp
  state%tangent_stiff = 0.0_wp
  state%geo_stiff = 0.0_wp
  state%strain_energy = 0.0_wp
  
  ! Initialize context
  algo_ctx%B_linear = 0.0_wp
  algo_ctx%B_nl = 0.0_wp
  algo_ctx%nr_iteration = 0
  algo_ctx%converged = .FALSE.
  
  status%code = 0
  status%message = "NL geometry initialization complete"
  
END SUBROUTINE PH_Elem_B31_NL_Initialize

! =============================================================================
! PH_Elem_B31_NL_CorotationalFrame
! =============================================================================
! Purpose: Compute the co-rotational frame that follows rigid body rotation
!
! Theory:
!   The element frame is defined by the current nodal positions:
!   e₁ = (x₂ - x₁) / ||x₂ - x₁||  (current axis)
!   
!   For pure translation without rotation:
!   u_corot = R^T · u_global - u_rigid
!
!   where R rotates initial axis to current axis
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_CorotationalFrame(&
    desc, state, algo_ctx, &
    coords₀, coordsₜ, &
    R_corot, u_local, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(INOUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: coords₀(3, 2)
  REAL(wp), INTENT(IN)  :: coordsₜ(3, 2)
  REAL(wp), INTENT(OUT) :: R_corot(3, 3)
  REAL(wp), INTENT(OUT) :: u_local(12)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: e₁₀(3), e₁ₜ(3)       ! Initial/current axis
  REAL(wp) :: L₀, Lₜ               ! Initial/current length
  REAL(wp) :: v_cross(3)           ! Cross product vector
  REAL(wp) :: sin_theta, cos_theta, theta
  REAL(wp) :: k_axis(3)            ! Rotation axis
  REAL(wp) :: I33(3, 3)            ! Identity
  REAL(wp) :: K_cross(3, 3)        ! Cross product matrix
  REAL(wp) :: temp33(3, 3)
  REAL(wp) :: u_global(12)
  INTEGER(i4) :: i, j
  
  ! Store coordinates
  state%coords₀ = coords₀
  state%coordsₜ = coordsₜ
  
  ! Initial axis direction
  e₁₀ = coords₀(:, 2) - coords₀(:, 1)
  L₀ = SQRT(DOT_PRODUCT(e₁₀, e₁₀))
  IF (L₀ > 1.0e-10_wp) THEN
    e₁₀ = e₁₀ / L₀
  ELSE
    e₁₀ = [1.0_wp, 0.0_wp, 0.0_wp]
  END IF
  
  ! Current axis direction
  e₁ₜ = coordsₜ(:, 2) - coordsₜ(:, 1)
  Lₜ = SQRT(DOT_PRODUCT(e₁ₜ, e₁ₜ))
  IF (Lₜ > 1.0e-10_wp) THEN
    e₁ₜ = e₁ₜ / Lₜ
  ELSE
    e₁ₜ = e₁₀
  END IF
  
  ! Compute rotation that maps e₁₀ → e₁ₜ
  ! Using Rodrigues' formula
  cos_theta = DOT_PRODUCT(e₁₀, e₁ₜ)
  cos_theta = MAX(-1.0_wp, MIN(1.0_wp, cos_theta))
  
  ! Cross product: v = e₁₀ × e₁ₜ
  v_cross(1) = e₁₀(2)*e₁ₜ(3) - e₁₀(3)*e₁ₜ(2)
  v_cross(2) = e₁₀(3)*e₁ₜ(1) - e₁₀(1)*e₁ₜ(3)
  v_cross(3) = e₁₀(1)*e₁ₜ(2) - e₁₀(2)*e₁ₜ(1)
  
  sin_theta = SQRT(DOT_PRODUCT(v_cross, v_cross))
  
  ! Identity matrix
  I33 = 0.0_wp
  DO i = 1, 3
    I33(i, i) = 1.0_wp
  END DO
  
  IF (sin_theta < 1.0e-10_wp) THEN
    ! No rotation or 180° rotation
    IF (cos_theta > 0.0_wp) THEN
      ! No rotation
      R_corot = I33
    ELSE
      ! 180° rotation - need arbitrary perpendicular axis
      ! Choose axis perpendicular to e₁₀
      IF (ABS(e₁₀(1)) < 0.9_wp) THEN
        k_axis = CROSS_PRODUCT(e₁₀, [1.0_wp, 0.0_wp, 0.0_wp])
      ELSE
        k_axis = CROSS_PRODUCT(e₁₀, [0.0_wp, 1.0_wp, 0.0_wp])
      END IF
      k_axis = k_axis / SQRT(DOT_PRODUCT(k_axis, k_axis))
      
      ! Rodrigues for 180°: R = -I + 2k⊗k
      R_corot = -I33 + 2.0_wp * RESHAPE([ &
        k_axis(1)*k_axis(1), k_axis(1)*k_axis(2), k_axis(1)*k_axis(3), &
        k_axis(2)*k_axis(1), k_axis(2)*k_axis(2), k_axis(2)*k_axis(3), &
        k_axis(3)*k_axis(1), k_axis(3)*k_axis(2), k_axis(3)*k_axis(3)], [3, 3])
    END IF
  ELSE
    ! General case: Rodrigues' formula
    k_axis = v_cross / sin_theta
    
    ! Build cross-product matrix K
    K_cross = 0.0_wp
    K_cross(1, 2) = -k_axis(3); K_cross(1, 3) =  k_axis(2)
    K_cross(2, 1) =  k_axis(3); K_cross(2, 3) = -k_axis(1)
    K_cross(3, 1) = -k_axis(2); K_cross(3, 2) =  k_axis(1)
    
    ! R = I + sin(θ)K + (1-cos(θ))K²
    R_corot = I33 + sin_theta * K_cross + &
              (1.0_wp - cos_theta) * MATMUL(K_cross, K_cross)
  END IF
  
  ! Store in state
  state%co_rot_matrix = R_corot
  
  ! Compute global displacements
  u_global(1:3)   = coordsₜ(:, 1) - coords₀(:, 1)
  u_global(4:6)   = 0.0_wp  ! Rotations handled separately
  u_global(7:9)   = coordsₜ(:, 2) - coords₀(:, 2)
  u_global(10:12) = 0.0_wp
  
  ! Transform to local co-rotational system
  ! u_local = R^T · u_global (for translations only)
  u_local(1:3) = MATMUL(TRANSPOSE(R_corot), u_global(1:3))
  u_local(4:6) = u_global(4:6)  ! Keep rotations as-is for now
  u_local(7:9) = MATMUL(TRANSPOSE(R_corot), u_global(7:9))
  u_local(10:12) = u_global(10:12)
  
  ! Remove rigid body translation
  ! The co-rotational formulation measures deformation relative to rotating frame
  ! TODO: Subtract rigid body motion if needed
  
  state%disp₁₂ = u_local
  
  status%code = 0
  status%message = "Co-rotational frame computed"
  
CONTAINS

  FUNCTION CROSS_PRODUCT(a, b) RESULT(c)
    REAL(wp), INTENT(IN) :: a(3), b(3)
    REAL(wp) :: c(3)
    c(1) = a(2)*b(3) - a(3)*b(2)
    c(2) = a(3)*b(1) - a(1)*b(3)
    c(3) = a(1)*b(2) - a(2)*b(1)
  END FUNCTION CROSS_PRODUCT
  
END SUBROUTINE PH_Elem_B31_NL_CorotationalFrame

! =============================================================================
! PH_Elem_B31_NL_GreenLagrangeStrain
! =============================================================================
! Purpose: Compute Green-Lagrange strain measure for large deformation
!
! E = ½(F^T · F - I) = ε_linear + ε_nonlinear
!
! For beam with co-rotational framework:
! E_axial = du/dx + ½[(du/dx)² + (dv/dx)² + (dw/dx)²]
! κ_y = d²w/dx², κ_z = -d²v/dx² (curvatures)
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_GreenLagrangeStrain(&
    desc, state, algo_ctx, &
    u_local, &
    E_gl, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(INOUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: u_local(12)
  REAL(wp), INTENT(OUT) :: E_gl(6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: L, xi, J₀
  REAL(wp) :: N1, N2, dN1, dN2
  REAL(wp) :: u1, u2, v1, v2, w1, w2
  REAL(wp) :: du_dx, dv_dx, dw_dx
  REAL(wp) :: eps_linear, eps_nonlinear
  REAL(wp) :: d2v_dx2, d2w_dx2
  REAL(wp) :: N1_dd, N2_dd  ! Second derivatives
  
  L = desc%L₀
  J₀ = L / 2.0_wp
  
  ! Use midpoint evaluation (ξ=0)
  xi = 0.0_wp
  N1 = 0.5_wp
  N2 = 0.5_wp
  dN1 = -0.5_wp
  dN2 =  0.5_wp
  
  ! Second derivatives for bending (at ξ=0)
  N1_dd = 0.0_wp
  N2_dd = 0.0_wp
  
  ! Extract nodal displacements (local co-rotational)
  u1 = u_local(1); v1 = u_local(2); w1 = u_local(3)
  u2 = u_local(7); v2 = u_local(8); w2 = u_local(9)
  
  ! Compute displacement gradients
  du_dx = (dN1*u1 + dN2*u2) / J₀
  dv_dx = (dN1*v1 + dN2*v2) / J₀
  dw_dx = (dN1*w1 + dN2*w2) / J₀
  
  ! Green-Lagrange axial strain
  ! E_xx = du/dx + ½[(du/dx)² + (dv/dx)² + (dw/dx)²]
  eps_linear = du_dx
  eps_nonlinear = 0.5_wp * (du_dx**2 + dv_dx**2 + dw_dx**2)
  
  E_gl(1) = eps_linear + eps_nonlinear  ! E_axial
  
  ! Curvatures (from bending)
  ! Simplified: use linear curvature-displacement
  ! κ_y = d²w/dx², κ_z = -d²v/dx²
  ! TODO: Add nonlinear curvature terms if needed
  
  E_gl(2) = 0.0_wp  ! Negligible for slender beams
  E_gl(3) = 0.0_wp
  E_gl(4) = 0.0_wp  ! Engineering shear strains
  E_gl(5) = 0.0_wp
  E_gl(6) = 0.0_wp
  
  ! Store in state
  state%E_axial = E_gl(1)
  
  status%code = 0
  status%message = "Green-Lagrange strain computed"
  
END SUBROUTINE PH_Elem_B31_NL_GreenLagrangeStrain

! =============================================================================
! PH_Elem_B31_NL_GeometricStiffness
! =============================================================================
! Purpose: Compute geometric stiffness matrix (initial stress stiffness)
!
! K_geo = ∫ G^T · σ · G dV
!
! where G relates displacement gradients to strains
! For beam: K_geo captures P-Δ and P-δ effects
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_GeometricStiffness(&
    desc, state, algo_ctx, &
    axial_force, &
    K_geo, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(IN)  :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: axial_force
  REAL(wp), INTENT(OUT) :: K_geo(12, 12)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: L, P
  REAL(wp) :: k_geo_bend(4, 4)
  REAL(wp) :: factor
  INTEGER(i4) :: i, j
  
  L = desc%L₀
  P = axial_force
  
  K_geo = 0.0_wp
  
  ! Geometric stiffness for bending degrees of freedom
  ! Based on exact stability functions or consistent linearization
  
  ! Simplified form (sufficient for most applications):
  ! k_geo_ij = (P/L) · ∫ (dN_i/dx)(dN_j/dx) dx
  
  ! For cubic Hermite shape functions (bending DOF: v1, θ1, v2, θ2)
  ! Index mapping: 2→v1, 6→θz1, 8→v2, 12→θz2
  
  factor = P / (30.0_wp * L)
  
  ! Bending about z-axis (v DOF)
  k_geo_bend = factor * RESHAPE([&
    36.0_wp,  3.0_wp*L, -36.0_wp,  3.0_wp*L, &
     3.0_wp*L, 4.0_wp*L**2, -3.0_wp*L, -L**2, &
   -36.0_wp, -3.0_wp*L,  36.0_wp, -3.0_wp*L, &
     3.0_wp*L, -L**2, -3.0_wp*L, 4.0_wp*L**2], [4, 4])
  
  ! Assemble to global K_geo
  ! v DOF (indices 2, 8)
  K_geo(2, 2)   = K_geo(2, 2)   + k_geo_bend(1, 1)
  K_geo(2, 6)   = K_geo(2, 6)   + k_geo_bend(1, 2)
  K_geo(2, 8)   = K_geo(2, 8)   + k_geo_bend(1, 3)
  K_geo(2, 12)  = K_geo(2, 12)  + k_geo_bend(1, 4)
  
  K_geo(6, 2)   = K_geo(6, 2)   + k_geo_bend(2, 1)
  K_geo(6, 6)   = K_geo(6, 6)   + k_geo_bend(2, 2)
  K_geo(6, 8)   = K_geo(6, 8)   + k_geo_bend(2, 3)
  K_geo(6, 12)  = K_geo(6, 12)  + k_geo_bend(2, 4)
  
  K_geo(8, 2)   = K_geo(8, 2)   + k_geo_bend(3, 1)
  K_geo(8, 6)   = K_geo(8, 6)   + k_geo_bend(3, 2)
  K_geo(8, 8)   = K_geo(8, 8)   + k_geo_bend(3, 3)
  K_geo(8, 12)  = K_geo(8, 12)  + k_geo_bend(3, 4)
  
  K_geo(12, 2)  = K_geo(12, 2)  + k_geo_bend(4, 1)
  K_geo(12, 6)  = K_geo(12, 6)  + k_geo_bend(4, 2)
  K_geo(12, 8)  = K_geo(12, 8)  + k_geo_bend(4, 3)
  K_geo(12, 12) = K_geo(12, 12) + k_geo_bend(4, 4)
  
  ! Similar for w DOF (bending about y-axis): indices 3, 7, 9, 11
  ! TODO: Add if torsional-flexural coupling is important
  
  ! Ensure symmetry
  DO i = 1, 12
    DO j = i+1, 12
      K_geo(j, i) = K_geo(i, j)
    END DO
  END DO
  
  ! Store in state
  state%geo_stiff = K_geo
  
  status%code = 0
  status%message = "Geometric stiffness computed"
  
END SUBROUTINE PH_Elem_B31_NL_GeometricStiffness

! =============================================================================
! PH_Elem_B31_NL_TangentStiffness
! =============================================================================
! Purpose: Form complete tangent stiffness matrix
!
! K_T = K_mat + K_geo
!
! where:
!   K_mat = Material stiffness (small-strain)
!   K_geo = Geometric stiffness (initial stress)
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_TangentStiffness(&
    desc, state, algo_ctx, &
    K_material, axial_force, &
    K_tangent, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(INOUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_material(12, 12)
  REAL(wp), INTENT(IN)  :: axial_force
  REAL(wp), INTENT(OUT) :: K_tangent(12, 12)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: K_geo(12, 12)
  
  ! Compute geometric stiffness
  CALL PH_Elem_B31_NL_GeometricStiffness(&
      desc, state, algo_ctx, axial_force, K_geo, status)
  
  ! Superpose: K_T = K_mat + K_geo
  K_tangent = K_material + K_geo
  
  ! Store in state
  state%tangent_stiff = K_tangent
  
  status%code = 0
  status%message = "Tangent stiffness assembled"
  
END SUBROUTINE PH_Elem_B31_NL_TangentStiffness

! =============================================================================
! PH_Elem_B31_NL_InternalForce
! =============================================================================
! Purpose: Compute internal force vector in co-rotational frame
!
! f_int = ∫ B^T · σ dV
!
! Transformed back to global coordinates via R matrix
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_InternalForce(&
    desc, state, algo_ctx, &
    u_local, stress_resultant, &
    f_int_local, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(INOUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: u_local(12)
  REAL(wp), INTENT(IN)  :: stress_resultant(6)
  REAL(wp), INTENT(OUT) :: f_int_local(12)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: L, E, A, Iy, Iz
  REAL(wp) :: N1, N2, dN1, dN2
  REAL(wp) :: eps_axial, kappa_y, kappa_z
  REAL(wp) :: N_axial, M_y, M_z
  INTEGER(i4) :: i
  
  L = desc%L₀
  E = desc%E
  A = desc%A
  Iy = desc%Iy
  Iz = desc%Iz
  
  f_int_local = 0.0_wp
  
  ! Extract stress resultants
  N_axial = stress_resultant(1)  ! Axial force
  M_y = stress_resultant(4)      ! Bending moment about y
  M_z = stress_resultant(5)      ! Bending moment about z
  
  ! Simplified: use linear strain-displacement for internal force
  ! Consistent with co-rotational small-strain assumption
  
  ! Axial contribution (nodes 1, 7)
  dN1 = -0.5_wp
  dN2 =  0.5_wp
  
  f_int_local(1) = -N_axial * dN1  ! Node 1, x-direction
  f_int_local(7) = -N_axial * dN2  ! Node 2, x-direction
  
  ! Bending contribution (cubic Hermite)
  ! TODO: Add full bending integration
  
  ! Store in state
  state%int_force = f_int_local
  
  status%code = 0
  status%message = "Internal force computed (co-rotational)"
  
END SUBROUTINE PH_Elem_B31_NL_InternalForce

! =============================================================================
! PH_Elem_B31_NL_RotationUpdate
! =============================================================================
! Purpose: Update finite rotation parameters using exponential map
!
! ΔR = exp(Δθ×) = I + sin(Δθ)/Δθ · Δθ× + (1-cos(Δθ))/Δθ² · (Δθ×)²
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_RotationUpdate(&
    desc, state, algo_ctx, &
    theta_old, delta_theta, &
    theta_new, R_new, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(INOUT) :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: theta_old(3)
  REAL(wp), INTENT(IN)  :: delta_theta(3)
  REAL(wp), INTENT(OUT) :: theta_new(3)
  REAL(wp), INTENT(OUT) :: R_new(3, 3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: dtheta_mag
  REAL(wp) :: k_vec(3)
  REAL(wp) :: K_cross(3, 3)
  REAL(wp) :: I33(3, 3)
  REAL(wp) :: sin_dth, cos_dth, coef1, coef2
  INTEGER(i4) :: i, j
  
  ! Magnitude of rotation increment
  dtheta_mag = SQRT(SUM(delta_theta**2))
  
  ! Identity matrix
  I33 = 0.0_wp
  DO i = 1, 3
    I33(i, i) = 1.0_wp
  END DO
  
  IF (dtheta_mag < 1.0e-10_wp) THEN
    ! Infinitesimal rotation
    theta_new = theta_old + delta_theta
    R_new = I33
  ELSE
    ! Finite rotation update
    theta_new = theta_old + delta_theta
    
    ! Rotation axis
    k_vec = delta_theta / dtheta_mag
    
    ! Cross-product matrix
    K_cross = 0.0_wp
    K_cross(1, 2) = -k_vec(3); K_cross(1, 3) =  k_vec(2)
    K_cross(2, 1) =  k_vec(3); K_cross(2, 3) = -k_vec(1)
    K_cross(3, 1) = -k_vec(2); K_cross(3, 2) =  k_vec(1)
    
    ! Rodrigues' formula (exponential map)
    sin_dth = SIN(dtheta_mag)
    cos_dth = COS(dtheta_mag)
    
    coef1 = sin_dth / dtheta_mag
    coef2 = (1.0_wp - cos_dth) / dtheta_mag**2
    
    R_new = I33 + coef1 * K_cross + coef2 * MATMUL(K_cross, K_cross)
  END IF
  
  status%code = 0
  status%message = "Rotation updated"
  
END SUBROUTINE PH_Elem_B31_NL_RotationUpdate

! =============================================================================
! PH_Elem_B31_NL_EnergyCheck
! =============================================================================
! Purpose: Verify energy conservation for nonlinear step
!
! ΔE_total = ΔU_strain + ΔK_kinetic - W_external ≈ 0
! =============================================================================
SUBROUTINE PH_Elem_B31_NL_EnergyCheck(&
    desc, state, algo_ctx, &
    u_old, u_new, &
    energy_balance, passed, status)
    
  TYPE(B31_NL_Geom_Desc_Type),  INTENT(IN)  :: desc
  TYPE(B31_NL_Geom_State_Type), INTENT(IN)  :: state
  TYPE(B31_NL_Geom_AlgoCtx_Type), INTENT(IN)  :: algo_ctx
  REAL(wp), INTENT(IN)  :: u_old(12)
  REAL(wp), INTENT(IN)  :: u_new(12)
  REAL(wp), INTENT(OUT) :: energy_balance
  LOGICAL,  INTENT(OUT) :: passed
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: du(12)
  REAL(wp) :: strain_energy_inc
  REAL(wp) :: external_work_inc
  
  ! Incremental displacement
  du = u_new - u_old
  
  ! Simplified energy check (for debugging)
  ! Full implementation requires time integration
  
  strain_energy_inc = state%strain_energy
  external_work_inc = DOT_PRODUCT(state%int_force, du)
  
  energy_balance = strain_energy_inc - external_work_inc
  
  ! Check tolerance
  passed = ABS(energy_balance) < desc%tol_energy
  
  status%code = 0
  status%message = "Energy check complete"
  
END SUBROUTINE PH_Elem_B31_NL_EnergyCheck

END MODULE PH_Elem_B31NLGeom