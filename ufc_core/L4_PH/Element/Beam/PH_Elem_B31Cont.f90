!===============================================================================
! MODULE: PH_Elem_B31Cont
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31 beam contact nonlinear core
!===============================================================================
MODULE PH_Elem_B31Cont
USE UFC_Kind_Defn
USE UFC_Const_Math
USE ErrorHandler

IMPLICIT NONE

PRIVATE
PUBLIC :: PH_Elem_B31_Cont_Initialize
PUBLIC :: PH_Elem_B31_Cont_BeamToBeamDetection
PUBLIC :: PH_Elem_B31_Cont_ClosestPointProjection
PUBLIC :: PH_Elem_B31_Cont_PenaltyForce
PUBLIC :: PH_Elem_B31_Cont_AugmentedLagrangian
PUBLIC :: PH_Elem_B31_Cont_CoulombFriction
PUBLIC :: PH_Elem_B31_Cont_ContactStiffness

! =============================================================================
! Type Definitions for Contact Mechanics
! =============================================================================

!---------------------------------------------------------------------------
! AUXILIARY TYPES (Depth 2 cap — nested auxiliary types)
!---------------------------------------------------------------------------

TYPE :: B31_Cont_Cfg_Penalty
  REAL(wp) :: eps_n           = 0.0_wp  ! Normal penalty parameter
  REAL(wp) :: eps_t           = 0.0_wp  ! Tangential penalty parameter
  REAL(wp) :: mu_friction     = 0.0_wp  ! Friction coefficient
  REAL(wp) :: tol_gap         = 0.0_wp  ! Gap tolerance for detection
  REAL(wp) :: tol_penetration = 0.0_wp  ! Max allowed penetration
END TYPE B31_Cont_Cfg_Penalty

TYPE :: B31_Cont_Cfg_Pair
  INTEGER(i4) :: contact_type   = 1       ! 1=Beam-Beam, 2=Beam-Surface
  LOGICAL  :: friction_active = .FALSE. ! Friction flag
  INTEGER(i4) :: algorithm_type = 1       ! 1=Penalty, 2=Augmented Lagrangian
END TYPE B31_Cont_Cfg_Pair

TYPE :: B31_Cont_Cfg_Geom
  REAL(wp) :: beam1_radius         = 0.0_wp  ! Beam 1 radius
  REAL(wp) :: beam2_radius         = 0.0_wp  ! Beam 2 radius
  REAL(wp) :: master_surf_normal(3) = 0.0_wp ! Master surface normal
END TYPE B31_Cont_Cfg_Geom

TYPE :: B31_Cont_Det_Contact
  LOGICAL  :: in_contact   = .FALSE.     ! Contact active flag
  REAL(wp) :: gap_distance = 1.0e10_wp   ! Current gap distance
  REAL(wp) :: penetration  = 0.0_wp      ! Penetration depth
END TYPE B31_Cont_Det_Contact

TYPE :: B31_Cont_Det_Closest
  REAL(wp) :: x_c1(3) = 0.0_wp  ! Closest point on beam 1
  REAL(wp) :: x_c2(3) = 0.0_wp  ! Closest point on beam 2
  REAL(wp) :: xi_c1   = 0.0_wp  ! Convective coordinate on beam 1
  REAL(wp) :: xi_c2   = 0.0_wp  ! Convective coordinate on beam 2
END TYPE B31_Cont_Det_Closest

TYPE :: B31_Cont_Itr_Force
  REAL(wp) :: F_normal(3)  = 0.0_wp  ! Normal contact force
  REAL(wp) :: F_tangent(3) = 0.0_wp  ! Tangential friction force
  REAL(wp) :: F_total(3)   = 0.0_wp  ! Total contact force
END TYPE B31_Cont_Itr_Force

TYPE :: B31_Cont_Itr_Lagrange
  REAL(wp) :: lambda_n    = 0.0_wp     ! Normal Lagrange multiplier
  REAL(wp) :: lambda_t(3) = 0.0_wp     ! Tangential Lagrange multipliers
END TYPE B31_Cont_Itr_Lagrange

TYPE :: B31_Cont_Itr_Friction
  LOGICAL  :: sticking             = .TRUE.  ! Sticking vs sliding
  REAL(wp) :: slip_displacement(3) = 0.0_wp  ! Cumulative slip displacement
END TYPE B31_Cont_Itr_Friction

TYPE :: B31_Cont_Lcl_Vectors
  REAL(wp) :: n_vec(3) = 0.0_wp  ! Contact normal vector
  REAL(wp) :: t_vec(3) = 0.0_wp  ! Tangent vector (sliding direction)
  REAL(wp) :: s_vec(3) = 0.0_wp  ! Second tangent (binormal)
END TYPE B31_Cont_Lcl_Vectors

TYPE :: B31_Cont_Lcl_Quad
  INTEGER(i4) :: n_contact_pts = 1                ! Number of contact integration points
  REAL(wp), ALLOCATABLE :: contact_weights(:)  ! Integration weights
END TYPE B31_Cont_Lcl_Quad

TYPE :: B31_Cont_Lcl_Iter
  INTEGER(i4) :: nl_iter       = 0       ! Nonlinear iterations
  REAL(wp) :: residual_norm = 0.0_wp  ! Residual norm
  LOGICAL  :: converged     = .FALSE. ! Convergence flag
END TYPE B31_Cont_Lcl_Iter

TYPE :: B31_Cont_Lcl_Algo
  REAL(wp) :: aug_lag_factor      = 10.0_wp  ! Augmentation factor for AL
  INTEGER(i4) :: max_AL_iterations   = 20       ! Max AL iterations
END TYPE B31_Cont_Lcl_Algo

TYPE :: B31_Cont_Lcl_Temp
  REAL(wp) :: temp3(3)   = 0.0_wp  ! Temporary vector
  REAL(wp) :: dN_dxi(3)  = 0.0_wp  ! Shape function derivative
END TYPE B31_Cont_Lcl_Temp

!---------------------------------------------------------------------------
! MAIN TYPES (with nested auxiliary types)
!---------------------------------------------------------------------------

TYPE :: B31_Cont_Desc_Type
  TYPE(B31_Cont_Cfg_Penalty) :: cfg_penalty
  TYPE(B31_Cont_Cfg_Pair)    :: cfg_pair
  TYPE(B31_Cont_Cfg_Geom)    :: cfg_geom
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_Desc_Type

TYPE :: B31_Cont_State_Type
  TYPE(B31_Cont_Det_Contact)   :: det_contact
  TYPE(B31_Cont_Det_Closest)   :: det_closest
  TYPE(B31_Cont_Itr_Force)     :: itr_force
  TYPE(B31_Cont_Itr_Lagrange)  :: itr_lagrange
  TYPE(B31_Cont_Itr_Friction)  :: itr_friction
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_State_Type

TYPE :: B31_Cont_AlgoCtx_Type
  TYPE(B31_Cont_Lcl_Vectors) :: lcl_vectors
  TYPE(B31_Cont_Lcl_Quad)    :: lcl_quad
  TYPE(B31_Cont_Lcl_Iter)    :: lcl_iter
  TYPE(B31_Cont_Lcl_Algo)    :: lcl_algo
  TYPE(B31_Cont_Lcl_Temp)    :: lcl_temp
  ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
END TYPE B31_Cont_AlgoCtx_Type

! =============================================================================
! Constants and Parameters
! =============================================================================

REAL(wp), PARAMETER :: TOL_GAP = 1.0e-6_wp          ! Gap detection tolerance
REAL(wp), PARAMETER :: TOL_PEN = 1.0e-8_wp          ! Penetration tolerance
REAL(wp), PARAMETER :: SMALL_VEC = 1.0e-12_wp       ! Small vector magnitude
REAL(wp), PARAMETER :: DEFAULT_PENALTY = 1.0e9_wp   ! Default penalty parameter

CONTAINS

! =============================================================================
! PH_Elem_B31_Cont_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_Initialize(&
    desc, state, algo_ctx, &
    contact_params, geometry_props, &
    status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(OUT) :: desc
  TYPE(B31_Cont_State_Type), INTENT(OUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: contact_params(5)   ! eps_n, eps_t, mu, tol_gap, alg_type
  REAL(wp), INTENT(IN)  :: geometry_props(3)   ! r1, r2, unused
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  ! Extract contact parameters
  desc%cfg_penalty%eps_n = contact_params(1)
  desc%cfg_penalty%eps_t = contact_params(2)
  desc%cfg_penalty%mu_friction = contact_params(3)
  desc%cfg_penalty%tol_gap = contact_params(4)
  desc%cfg_pair%algorithm_type = INT(contact_params(5))

  ! Check if friction is active
  IF (desc%cfg_penalty%mu_friction > 0.0_wp) THEN
    desc%cfg_pair%friction_active = .TRUE.
  ELSE
    desc%cfg_pair%friction_active = .FALSE.
  END IF

  ! Geometry
  desc%cfg_geom%beam1_radius = geometry_props(1)
  desc%cfg_geom%beam2_radius = geometry_props(2)

  ! Default contact type
  desc%cfg_pair%contact_type = 1  ! Beam-to-beam default
  
  ! Initialize state
  state%det_contact%in_contact = .FALSE.
  state%det_contact%gap_distance = 1.0e10_wp
  state%det_contact%penetration = 0.0_wp
  state%det_closest%x_c1 = 0.0_wp
  state%det_closest%x_c2 = 0.0_wp
  state%det_closest%xi_c1 = 0.0_wp
  state%det_closest%xi_c2 = 0.0_wp
  state%itr_force%F_normal = 0.0_wp
  state%itr_force%F_tangent = 0.0_wp
  state%itr_force%F_total = 0.0_wp
  state%itr_lagrange%lambda_n = 0.0_wp
  state%itr_lagrange%lambda_t = 0.0_wp
  state%itr_friction%sticking = .TRUE.
  state%itr_friction%slip_displacement = 0.0_wp

  ! Initialize algorithm context
  algo_ctx%lcl_vectors%n_vec = 0.0_wp
  algo_ctx%lcl_vectors%t_vec = 0.0_wp
  algo_ctx%lcl_vectors%s_vec = 0.0_wp
  algo_ctx%lcl_quad%n_contact_pts = 1  ! Single point contact default
  algo_ctx%lcl_iter%nl_iter = 0
  algo_ctx%lcl_iter%residual_norm = 0.0_wp
  algo_ctx%lcl_iter%converged = .FALSE.
  algo_ctx%lcl_algo%aug_lag_factor = 10.0_wp
  algo_ctx%lcl_algo%max_AL_iterations = 20

  ! Allocate work arrays
  ALLOCATE(algo_ctx%lcl_quad%contact_weights(algo_ctx%lcl_quad%n_contact_pts))
  algo_ctx%lcl_quad%contact_weights = 1.0_wp
  
  status%code = 0
  status%message = "Contact initialization complete"
  
END SUBROUTINE PH_Elem_B31_Cont_Initialize

! =============================================================================
! PH_Elem_B31_Cont_BeamToBeamDetection
! =============================================================================
! Purpose: Detect contact between two beam elements
!
! Strategy:
!   1. Global search: Check if beams are close enough
!   2. Local search: Find closest points using Newton iteration
!   3. Gap computation: g = ||x_c1 - x_c2|| - (r1 + r2)
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_BeamToBeamDetection(&
    desc, state, algo_ctx, &
    coords1, coords2, &
    in_contact, gap, status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: coords1(3, 2)   ! Beam 1 nodal coordinates
  REAL(wp), INTENT(IN)  :: coords2(3, 2)   ! Beam 2 nodal coordinates
  LOGICAL,  INTENT(OUT) :: in_contact
  REAL(wp), INTENT(OUT) :: gap
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: x1(3), x2(3)              ! Nodal positions
  REAL(wp) :: d1(3), d2(3)              ! Beam direction vectors
  REAL(wp) :: r1, r2                    ! Beam radii
  REAL(wp) :: d_vec(3)                  ! Vector between beam axes
  REAL(wp) :: dist                      ! Distance between axes
  REAL(wp) :: xi1, xi2                  ! Convective coordinates
  LOGICAL  :: found_contact
  
  ! Extract geometry
  r1 = desc%cfg_geom%beam1_radius
  r2 = desc%cfg_geom%beam2_radius
  
  ! Quick rejection test (bounding box)
  ! TODO: Implement efficient global search
  
  ! Find closest points on beam axes
  CALL PH_Elem_B31_Cont_ClosestPointProjection(&
      desc, state, algo_ctx, &
      coords1, coords2, &
      xi1, xi2, &
      state%det_closest%x_c1, state%det_closest%x_c2, &
      status)

  ! Compute gap distance
  ! g = ||x_c1 - x_c2|| - (r1 + r2)
  d_vec = state%det_closest%x_c2 - state%det_closest%x_c1
  dist = SQRT(DOT_PRODUCT(d_vec, d_vec))

  gap = dist - (r1 + r2)
  state%det_contact%gap_distance = gap

  ! Check contact
  IF (gap < desc%cfg_penalty%tol_gap) THEN
    in_contact = .TRUE.
    state%det_contact%penetration = -gap  ! Positive penetration

    ! Store convective coordinates
    state%det_closest%xi_c1 = xi1
    state%det_closest%xi_c2 = xi2

    ! Compute contact normal
    IF (dist > SMALL_VEC) THEN
      algo_ctx%lcl_vectors%n_vec = d_vec / dist
    ELSE
      ! Degenerate case: coincident axes
      algo_ctx%lcl_vectors%n_vec = [1.0_wp, 0.0_wp, 0.0_wp]
    END IF

    found_contact = .TRUE.
  ELSE
    in_contact = .FALSE.
    state%det_contact%penetration = 0.0_wp
    found_contact = .FALSE.
  END IF

  state%det_contact%in_contact = in_contact
  
  status%code = 0
  IF (found_contact) THEN
    status%message = "Contact detected, gap = "//TRIM(FTOA(gap))
  ELSE
    status%message = "No contact, gap = "//TRIM(FTOA(gap))
  END IF
  
END SUBROUTINE PH_Elem_B31_Cont_BeamToBeamDetection

! =============================================================================
! PH_Elem_B31_Cont_ClosestPointProjection
! =============================================================================
! Purpose: Find closest points on two beam axes using Newton iteration
!
! Minimize: f(ξ₁, ξ₂) = ½ ||x₁(ξ₁) - x₂(ξ₂)||²
!
! Solution via Newton-Raphson:
!   [H]{Δξ} = -{∇f}
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_ClosestPointProjection(&
    desc, state, algo_ctx, &
    coords1, coords2, &
    xi1_out, xi2_out, &
    x_c1, x_c2, &
    status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: coords1(3, 2)
  REAL(wp), INTENT(IN)  :: coords2(3, 2)
  REAL(wp), INTENT(OUT) :: xi1_out, xi2_out
  REAL(wp), INTENT(OUT) :: x_c1(3), x_c2(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: xi1, xi2
  REAL(wp) :: N1(2), N2(2)              ! Shape functions
  REAL(wp) :: dN1(2), dN2(2)            ! Shape function derivatives
  REAL(wp) :: x1(3), x2(3)              ! Points on beams
  REAL(wp) :: dx1(3), dx2(3)            ! Tangent vectors
  REAL(wp) :: d_vec(3)                  ! x2 - x1
  REAL(wp) :: grad_f(2)                 ! Gradient ∂f/∂ξ
  REAL(wp) :: Hessian(2, 2)             ! Hessian matrix
  REAL(wp) :: delta_xi(2)
  REAL(wp) :: residual, tol_nr
  INTEGER(i4) :: iter, max_iter
  
  ! Initial guess (midpoints)
  xi1 = 0.0_wp
  xi2 = 0.0_wp
  
  tol_nr = 1.0e-10_wp
  max_iter = 20
  
  ! Newton-Raphson iteration
  DO iter = 1, max_iter
    ! Shape functions at current ξ
    N1 = [(1.0_wp - xi1)/2.0_wp, (1.0_wp + xi1)/2.0_wp]
    N2 = [(1.0_wp - xi2)/2.0_wp, (1.0_wp + xi2)/2.0_wp]
    
    dN1 = [-0.5_wp, 0.5_wp]
    dN2 = [-0.5_wp, 0.5_wp]
    
    ! Current points on beam axes
    x1 = MATMUL(coords1, N1)
    x2 = MATMUL(coords2, N2)
    
    ! Tangent vectors
    dx1 = MATMUL(coords1, dN1)
    dx2 = MATMUL(coords2, dN2)
    
    ! Distance vector
    d_vec = x2 - x1
    
    ! Gradient: ∂f/∂ξ₁ = -dx₁·d, ∂f/∂ξ₂ = dx₂·d
    grad_f(1) = -DOT_PRODUCT(dx1, d_vec)
    grad_f(2) =  DOT_PRODUCT(dx2, d_vec)
    
    ! Check convergence
    residual = SQRT(grad_f(1)**2 + grad_f(2)**2)
    
    IF (residual < tol_nr) EXIT
    
    ! Hessian matrix
    ! H₁₁ = dx₁·dx₁, H₁₂ = -dx₁·dx₂, H₂₂ = dx₂·dx₂
    Hessian(1, 1) = DOT_PRODUCT(dx1, dx1)
    Hessian(1, 2) = -DOT_PRODUCT(dx1, dx2)
    Hessian(2, 1) = Hessian(1, 2)
    Hessian(2, 2) = DOT_PRODUCT(dx2, dx2)
    
    ! Solve 2×2 system
    REAL(wp) :: det_H, invH(2, 2)
    det_H = Hessian(1, 1)*Hessian(2, 2) - Hessian(1, 2)*Hessian(2, 1)
    
    IF (ABS(det_H) < SMALL_VEC) THEN
      ! Singular Hessian, use steepest descent
      delta_xi = -0.1_wp * grad_f
    ELSE
      invH(1, 1) =  Hessian(2, 2) / det_H
      invH(1, 2) = -Hessian(1, 2) / det_H
      invH(2, 1) = -Hessian(2, 1) / det_H
      invH(2, 2) =  Hessian(1, 1) / det_H
      
      delta_xi = -MATMUL(invH, grad_f)
    END IF
    
    ! Update
    xi1 = xi1 + delta_xi(1)
    xi2 = xi2 + delta_xi(2)
    
    ! Enforce bounds [-1, 1]
    xi1 = MAX(-1.0_wp, MIN(1.0_wp, xi1))
    xi2 = MAX(-1.0_wp, MIN(1.0_wp, xi2))
  END DO
  
  ! Output results
  xi1_out = xi1
  xi2_out = xi2
  
  ! Recompute final positions
  N1 = [(1.0_wp - xi1)/2.0_wp, (1.0_wp + xi1)/2.0_wp]
  N2 = [(1.0_wp - xi2)/2.0_wp, (1.0_wp + xi2)/2.0_wp]
  
  x_c1 = MATMUL(coords1, N1)
  x_c2 = MATMUL(coords2, N2)
  
  status%code = 0
  IF (iter <= max_iter) THEN
    status%message = "Closest point found in "//TRIM(ITOA(iter))//" iterations"
  ELSE
    status%message = "Closest point iteration did not converge"
  END IF
  
END SUBROUTINE PH_Elem_B31_Cont_ClosestPointProjection

! =============================================================================
! PH_Elem_B31_Cont_PenaltyForce
! =============================================================================
! Purpose: Compute contact force using penalty method
!
! F_n = eps_n * g_N * n  (if g_N < 0, i.e., penetration)
!
! where:
!   g_N = gap distance (negative for penetration)
!   n = contact normal
!   eps_n = penalty parameter
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_PenaltyForce(&
    desc, state, algo_ctx, &
    gap, &
    F_normal, status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: gap
  REAL(wp), INTENT(OUT) :: F_normal(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: g_N                      ! Normal gap
  REAL(wp) :: penalty_force
  
  g_N = gap
  
  ! Only active for penetration (g_N < 0)
  IF (g_N < 0.0_wp) THEN
    ! Penalty force: F = eps_n * |g_N| * n
    penalty_force = desc%cfg_penalty%eps_n * ABS(g_N)
    
    F_normal = penalty_force * algo_ctx%lcl_vectors%n_vec
    
    ! Store in state
    state%itr_force%F_normal = F_normal
    state%det_contact%penetration = -g_N
  ELSE
    F_normal = 0.0_wp
    state%itr_force%F_normal = 0.0_wp
  END IF
  
  status%code = 0
  IF (g_N < 0.0_wp) THEN
    status%message = "Penalty force computed: "//TRIM(FTOA(penalty_force))//" N"
  ELSE
    status%message = "No contact (gap > 0)"
  END IF
  
END SUBROUTINE PH_Elem_B31_Cont_PenaltyForce

! =============================================================================
! PH_Elem_B31_Cont_AugmentedLagrangian
! =============================================================================
! Purpose: Augmented Lagrangian method for exact constraint enforcement
!
! F_n = lambda_n + eps_n * g_N
!
! Update Lagrange multiplier:
!   lambda_n^{k+1} = lambda_n^k + eps_n * g_N
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_AugmentedLagrangian(&
    desc, state, algo_ctx, &
    gap, &
    F_normal, lambda_new, status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: gap
  REAL(wp), INTENT(OUT) :: F_normal(3)
  REAL(wp), INTENT(OUT) :: lambda_new
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: g_N
  REAL(wp) :: aug_term
  
  g_N = gap
  
  ! Augmented Lagrangian force
  ! F = lambda + eps_n * g_N (for g_N < 0)
  
  IF (g_N < 0.0_wp) THEN
    aug_term = desc%cfg_penalty%eps_n * g_N
    F_normal = (state%itr_lagrange%lambda_n + aug_term) * algo_ctx%lcl_vectors%n_vec
    
    ! Update Lagrange multiplier
    lambda_new = state%itr_lagrange%lambda_n + aug_term
    
    ! Ensure non-negative (compression only)
    lambda_new = MAX(0.0_wp, lambda_new)
  ELSE
    F_normal = 0.0_wp
    lambda_new = 0.0_wp
  END IF
  
  ! Store updated multiplier
  state%itr_lagrange%lambda_n = lambda_new
  
  status%code = 0
  status%message = "Augmented Lagrangian force computed"
  
END SUBROUTINE PH_Elem_B31_Cont_AugmentedLagrangian

! =============================================================================
! PH_Elem_B31_Cont_CoulombFriction
! =============================================================================
! Purpose: Coulomb friction model for tangential contact
!
! Stick: |F_t| ≤ μ * |F_n|
! Slide: F_t = -μ * |F_n| * t (t = sliding direction)
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_CoulombFriction(&
    desc, state, algo_ctx, &
    F_normal, v_tangent, dt, &
    F_friction, status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: F_normal(3)
  REAL(wp), INTENT(IN)  :: v_tangent(3)   ! Relative tangential velocity
  REAL(wp), INTENT(IN)  :: dt             ! Time increment
  REAL(wp), INTENT(OUT) :: F_friction(3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: F_n_mag                  ! Magnitude of normal force
  REAL(wp) :: v_t_mag                  ! Tangential velocity magnitude
  REAL(wp) :: trial_F_t(3)             ! Trial elastic friction force
  REAL(wp) :: slip_limit               ! μ * |F_n|
  REAL(wp) :: coef
  
  ! Normal force magnitude
  F_n_mag = SQRT(DOT_PRODUCT(F_normal, F_normal))
  
  ! No friction without normal force
  IF (F_n_mag < SMALL_VEC) THEN
    F_friction = 0.0_wp
    status%code = 0
    status%message = "No friction (zero normal force)"
    RETURN
  END IF
  
  ! Tangential velocity magnitude
  v_t_mag = SQRT(DOT_PRODUCT(v_tangent, v_tangent))
  
  ! Compute tangential direction
  IF (v_t_mag > SMALL_VEC) THEN
    algo_ctx%lcl_vectors%t_vec = v_tangent / v_t_mag
  ELSE
    ! No relative motion, use previous direction
    algo_ctx%lcl_vectors%t_vec = state%itr_force%F_tangent
    IF (SQRT(DOT_PRODUCT(algo_ctx%lcl_vectors%t_vec, algo_ctx%lcl_vectors%t_vec)) > SMALL_VEC) THEN
      algo_ctx%lcl_vectors%t_vec = algo_ctx%lcl_vectors%t_vec / SQRT(DOT_PRODUCT(algo_ctx%lcl_vectors%t_vec, algo_ctx%lcl_vectors%t_vec))
    ELSE
      algo_ctx%lcl_vectors%t_vec = [1.0_wp, 0.0_wp, 0.0_wp]
    END IF
    v_t_mag = 0.0_wp
  END IF
  
  ! Slip limit (Coulomb criterion)
  slip_limit = desc%cfg_penalty%mu_friction * F_n_mag
  
  ! Trial elastic friction (predictor)
  ! F_t_trial = F_t_old + eps_t * v_t * dt
  trial_F_t = state%itr_force%F_tangent + desc%cfg_penalty%eps_t * v_tangent * dt
  
  ! Check stick/slip
  REAL(wp) :: F_t_trial_mag
  F_t_trial_mag = SQRT(DOT_PRODUCT(trial_F_t, trial_F_t))
  
  IF (F_t_trial_mag <= slip_limit) THEN
    ! Sticking: elastic response
    F_friction = trial_F_t
    state%itr_friction%sticking = .TRUE.
  ELSE
    ! Sliding: return to slip surface
    IF (F_t_trial_mag > SMALL_VEC) THEN
      coef = slip_limit / F_t_trial_mag
      F_friction = coef * trial_F_t
    ELSE
      F_friction = 0.0_wp
    END IF
    state%itr_friction%sticking = .FALSE.

    ! Update slip displacement
    state%itr_friction%slip_displacement = state%itr_friction%slip_displacement + v_tangent * dt
  END IF

  ! Store in state
  state%itr_force%F_tangent = F_friction

  ! Total contact force
  state%itr_force%F_total = F_normal + F_friction

  status%code = 0
  IF (state%itr_friction%sticking) THEN
    status%message = "Friction: Sticking regime"
  ELSE
    status%message = "Friction: Sliding regime"
  END IF
  
END SUBROUTINE PH_Elem_B31_Cont_CoulombFriction

! =============================================================================
! PH_Elem_B31_Cont_ContactStiffness
! =============================================================================
! Purpose: Compute consistent contact stiffness matrix
!
! K_contact = ∂F_contact/∂u
!
! For penalty method:
!   K_n = eps_n * n ⊗ n
! =============================================================================
SUBROUTINE PH_Elem_B31_Cont_ContactStiffness(&
    desc, state, algo_ctx, &
    K_contact, status)
    
  TYPE(B31_Cont_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Cont_State_Type), INTENT(IN) :: state
  TYPE(B31_Cont_AlgoCtx_Type), INTENT(IN) :: algo_ctx
  REAL(wp), INTENT(OUT) :: K_contact(3, 3)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: n(3)
  REAL(wp) :: nn_outer(3, 3)
  
  IF (.NOT. state%det_contact%in_contact) THEN
    K_contact = 0.0_wp
    status%code = 0
    status%message = "No contact stiffness (no contact)"
    RETURN
  END IF
  
  n = algo_ctx%lcl_vectors%n_vec
  
  ! Normal contact stiffness (penalty)
  ! K_n = eps_n * n ⊗ n
  nn_outer = RESHAPE([&
    n(1)*n(1), n(1)*n(2), n(1)*n(3), &
    n(2)*n(1), n(2)*n(2), n(2)*n(3), &
    n(3)*n(1), n(3)*n(2), n(3)*n(3)], [3, 3])
  
  K_contact = desc%cfg_penalty%eps_n * nn_outer
  
  ! TODO: Add frictional contribution if needed
  ! K_friction = eps_t * t ⊗ t (for sticking)
  
  status%code = 0
  status%message = "Contact stiffness computed"
  
END SUBROUTINE PH_Elem_B31_Cont_ContactStiffness

END MODULE PH_Elem_B31Cont