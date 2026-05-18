!===============================================================================
! MODULE: PH_Elem_B31Plasticity
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31 beam plasticity core (J2 flow theory)
!===============================================================================
MODULE PH_Elem_B31Plasticity
USE UFC_Kind_Defn
USE UFC_Const_Math
USE ErrorHandler

IMPLICIT NONE

PRIVATE
PUBLIC :: PH_Elem_B31_Plas_Initialize
PUBLIC :: PH_Elem_B31_Plas_J2YieldFunction
PUBLIC :: PH_Elem_B31_Plas_ReturnMapping
PUBLIC :: PH_Elem_B31_Plas_ConsistentTangent
PUBLIC :: PH_Elem_B31_Plas_UpdateStress
PUBLIC :: PH_Elem_B31_Plas_SectionFiberModel
PUBLIC :: PH_Elem_B31_Plas_PlasticHinge

! =============================================================================
! Type Definitions for Material Plasticity
! =============================================================================

TYPE :: B31_Plas_Mat_Desc_Type
  ! Elastic properties
  REAL(wp) :: E                     ! Young's modulus
  REAL(wp) :: nu                    ! Poisson's ratio
  REAL(wp) :: G                     ! Shear modulus
  REAL(wp) :: K_bulk                ! Bulk modulus
  
  ! Plastic properties
  REAL(wp) :: sigma_y0              ! Initial yield stress
  REAL(wp) :: H_iso                 ! Isotropic hardening modulus
  REAL(wp) :: H_kin                 ! Kinematic hardening modulus (optional)
  
  ! Hardening law parameters
  INTEGER(i4) :: hardening_type        ! 1=Linear, 2=Power-law, 3=Exponential
  REAL(wp) :: hardening_param(3)    ! Additional hardening params
  
  ! Integration control
  INTEGER(i4) :: n_fibers              ! Number of fibers through section
  REAL(wp) :: fiber_coords(:,:)     ! Fiber locations (y, z, area)
END TYPE B31_Plas_Mat_Desc_Type

TYPE :: B31_Plas_Mat_State_Type
  ! Stress state
  REAL(wp) :: sigma(6)              ! Cauchy stress vector (Voigt)
  REAL(wp) :: s_dev(6)              ! Deviatoric stress
  REAL(wp) :: alpha(6)              ! Back stress (kinematic hardening)
  
  ! Internal variables
  REAL(wp) :: eps_p_cum             ! Cumulative plastic strain
  REAL(wp) :: eps_p(6)              ! Plastic strain tensor
  REAL(wp) :: kappa                 ! Isotropic hardening variable
  
  ! Yield surface
  REAL(wp) :: f_yield               ! Yield function value
  REAL(wp) :: R_iso                 ! Isotropic hardening stress
  REAL(wp) :: sigma_eq              ! von Mises equivalent stress
  
  ! Section state (fiber model)
  REAL(wp) :: fiber_stress(:)       ! Stress at each fiber
  REAL(wp) :: fiber_strain(:)       ! Strain at each fiber
  REAL(wp) :: fiber_yield(:)        ! Yield status at fibers
END TYPE B31_Plas_Mat_State_Type

TYPE :: B31_Plas_Mat_AlgoCtx_Type
  ! Integration parameters
  REAL(wp) :: theta                 ! Newmark parameter (default 0.5)
  REAL(wp) :: dt                    ! Time increment
  
  ! Return mapping work arrays
  REAL(wp) :: D_elastic(6, 6)       ! Elastic stiffness matrix
  REAL(wp) :: N_flow(6)             ! Flow direction vector
  REAL(wp) :: D_tangent(6, 6)       ! Consistent tangent matrix
  
  ! Iteration variables
  INTEGER(i4) :: nr_iter               ! Newton-Raphson iterations
  REAL(wp) :: residual              ! Residual norm
  LOGICAL  :: converged             ! Convergence flag
  
  ! Section integration
  REAL(wp) :: N_axial               ! Axial force resultant
  REAL(wp) :: M_y, M_z              ! Bending moment resultants
  REAL(wp) :: T_tors                ! Torque resultant
END TYPE B31_Plas_Mat_AlgoCtx_Type

! =============================================================================
! Constants and Parameters
! =============================================================================

REAL(wp), PARAMETER :: TOL_NR = 1.0e-8_wp      ! NR tolerance
REAL(wp), PARAMETER :: MAX_ITER_NR = 50        ! Max NR iterations
REAL(wp), PARAMETER :: SMALL_VAL = 1.0e-12_wp  ! Small value for division

CONTAINS

! =============================================================================
! PH_Elem_B31_Plas_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_Initialize(&
    desc, state, algo_ctx, &
    material_props, plastic_props, &
    n_fibers, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(OUT) :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(OUT) :: state
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: material_props(4)   ! E, nu, density, alpha
  REAL(wp), INTENT(IN)  :: plastic_props(5)    ! sigma_y0, H_iso, H_kin, type, param1
  INTEGER(i4), INTENT(IN) :: n_fibers            ! Number of section fibers
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: E, nu
  
  ! Extract elastic properties
  E = material_props(1)
  nu = material_props(2)
  
  desc%E = E
  desc%nu = nu
  desc%G = E / (2.0_wp * (1.0_wp + nu))
  desc%K_bulk = E / (3.0_wp * (1.0_wp - 2.0_wp * nu))
  
  ! Extract plastic properties
  desc%sigma_y0 = plastic_props(1)
  desc%H_iso = plastic_props(2)
  desc%H_kin = plastic_props(3)
  desc%hardening_type = INT(plastic_props(4))
  desc%hardening_param(1) = plastic_props(5)
  
  ! Section discretization
  desc%n_fibers = n_fibers
  ALLOCATE(desc%fiber_coords(3, n_fibers))
  ALLOCATE(state%fiber_stress(n_fibers))
  ALLOCATE(state%fiber_strain(n_fibers))
  ALLOCATE(state%fiber_yield(n_fibers))
  
  ! Initialize fiber coordinates (simplified: uniform distribution)
  ! TODO: Support arbitrary section shapes
  INTEGER(i4) :: i
  REAL(wp) :: y_coord, z_coord, fiber_area
  
  DO i = 1, n_fibers
    ! For rectangular section: fibers along height
    y_coord = -0.5_wp + REAL(i - 1, wp) / REAL(n_fibers - 1, wp)
    z_coord = 0.0_wp
    fiber_area = 1.0_wp / REAL(n_fibers, wp)  ! Normalized area
    
    desc%fiber_coords(1, i) = y_coord
    desc%fiber_coords(2, i) = z_coord
    desc%fiber_coords(3, i) = fiber_area
  END DO
  
  ! Initialize state
  state%sigma = 0.0_wp
  state%s_dev = 0.0_wp
  state%alpha = 0.0_wp
  state%eps_p_cum = 0.0_wp
  state%eps_p = 0.0_wp
  state%kappa = 0.0_wp
  state%f_yield = -1.0_wp  ! Initially elastic
  state%R_iso = 0.0_wp
  state%sigma_eq = 0.0_wp
  state%fiber_stress = 0.0_wp
  state%fiber_strain = 0.0_wp
  state%fiber_yield = 0.0_wp
  
  ! Initialize algorithm context
  algo_ctx%theta = 0.5_wp  ! Trapezoidal rule
  algo_ctx%dt = 1.0_wp
  algo_ctx%D_elastic = 0.0_wp
  algo_ctx%N_flow = 0.0_wp
  algo_ctx%D_tangent = 0.0_wp
  algo_ctx%nr_iter = 0
  algo_ctx%residual = 0.0_wp
  algo_ctx%converged = .FALSE.
  algo_ctx%N_axial = 0.0_wp
  algo_ctx%M_y = 0.0_wp
  algo_ctx%M_z = 0.0_wp
  algo_ctx%T_tors = 0.0_wp
  
  ! Build elastic stiffness matrix
  CALL PH_Elem_B31_Plas_BuildElasticMatrix(desc, algo_ctx%D_elastic, status)
  
  status%code = 0
  status%message = "Plasticity initialization complete"
  
END SUBROUTINE PH_Elem_B31_Plas_Initialize

! =============================================================================
! PH_Elem_B31_Plas_BuildElasticMatrix
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_BuildElasticMatrix(desc, D_elastic, status)
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  REAL(wp), INTENT(OUT) :: D_elastic(6, 6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: E, nu, G, lambda
  
  E = desc%E
  nu = desc%nu
  G = desc%G
  lambda = E * nu / ((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu))
  
  ! 3D isotropic elasticity matrix (Voigt notation)
  D_elastic = 0.0_wp
  
  ! Normal components
  D_elastic(1, 1) = lambda + 2.0_wp * G
  D_elastic(2, 2) = lambda + 2.0_wp * G
  D_elastic(3, 3) = lambda + 2.0_wp * G
  
  ! Coupling terms
  D_elastic(1, 2) = lambda
  D_elastic(1, 3) = lambda
  D_elastic(2, 1) = lambda
  D_elastic(2, 3) = lambda
  D_elastic(3, 1) = lambda
  D_elastic(3, 2) = lambda
  
  ! Shear components
  D_elastic(4, 4) = G
  D_elastic(5, 5) = G
  D_elastic(6, 6) = G
  
  status%code = 0
  
END SUBROUTINE PH_Elem_B31_Plas_BuildElasticMatrix

! =============================================================================
! PH_Elem_B31_Plas_J2YieldFunction
! =============================================================================
! Purpose: Compute von Mises yield function
!
! f(σ, q) = ||s - α|| - sqrt(2/3) * (sigma_y0 + R_iso)
!
! where:
!   s = deviatoric stress
!   α = back stress (kinematic hardening)
!   R_iso = isotropic hardening stress
! =============================================================================
FUNCTION PH_Elem_B31_Plas_J2YieldFunction(&
    desc, state, &
    sigma, alpha, kappa, &
    f_yield, df_dsigma, status) RESULT(yield_flag)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(IN) :: state
  REAL(wp), INTENT(IN)  :: sigma(6)
  REAL(wp), INTENT(IN)  :: alpha(6)
  REAL(wp), INTENT(IN)  :: kappa
  REAL(wp), INTENT(OUT) :: f_yield
  REAL(wp), INTENT(OUT) :: df_dsigma(6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  LOGICAL :: yield_flag
  
  REAL(wp) :: s_dev(6)           ! Relative deviatoric stress (s - α)
  REAL(wp) :: J2                 ! Second invariant of deviatoric stress
  REAL(wp) :: sigma_vm           ! von Mises equivalent stress
  REAL(wp) :: sigma_yield        ! Current yield stress
  REAL(wp) :: sqrt_two_thirds
  INTEGER(i4) :: i
  
  ! Compute deviatoric stress
  REAL(wp) :: p_hydro
  p_hydro = (sigma(1) + sigma(2) + sigma(3)) / 3.0_wp
  
  s_dev(1) = sigma(1) - p_hydro - alpha(1)
  s_dev(2) = sigma(2) - p_hydro - alpha(2)
  s_dev(3) = sigma(3) - p_hydro - alpha(3)
  s_dev(4) = sigma(4) - alpha(4)  ! Shear components
  s_dev(5) = sigma(5) - alpha(5)
  s_dev(6) = sigma(6) - alpha(6)
  
  ! Compute J2 invariant
  ! J2 = ½(s:s)
  J2 = 0.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                 2.0_wp * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2))
  
  ! von Mises equivalent stress
  ! σ_vm = sqrt(3*J2) = sqrt(3/2 * s:s)
  sigma_vm = SQRT(3.0_wp * J2)
  
  ! Current yield stress
  ! σ_y = σ_y0 + R_iso(κ)
  SELECT CASE(desc%hardening_type)
    CASE(1)  ! Linear hardening
      sigma_yield = desc%sigma_y0 + desc%H_iso * kappa
      
    CASE(2)  ! Power-law hardening: σ_y = σ_y0 + K*(ε_p)^n
      sigma_yield = desc%sigma_y0 + &
                    desc%hardening_param(1) * (kappa**desc%hardening_param(2))
      
    CASE(3)  ! Exponential saturation: σ_y = σ_sat - (σ_sat - σ_y0)*exp(-δ*κ)
      sigma_yield = desc%hardening_param(1) - &
                    (desc%hardening_param(1) - desc%sigma_y0) * &
                    EXP(-desc%hardening_param(2) * kappa)
      
    CASE DEFAULT
      sigma_yield = desc%sigma_y0  ! Perfect plasticity
  END SELECT
  
  ! Yield function: f = σ_vm - σ_y
  f_yield = sigma_vm - sigma_yield
  
  ! Gradient of f with respect to stress (flow direction)
  ! ∂f/∂σ = (3/2) * s / σ_vm
  IF (sigma_vm > SMALL_VAL) THEN
    sqrt_two_thirds = SQRT(2.0_wp / 3.0_wp)
    df_dsigma(1:3) = (3.0_wp / (2.0_wp * sigma_vm)) * s_dev(1:3)
    df_dsigma(4:6) = (3.0_wp / (2.0_wp * sigma_vm)) * s_dev(4:6)
  ELSE
    df_dsigma = 0.0_wp  ! At origin, undefined gradient
  END IF
  
  ! Check yielding
  yield_flag = (f_yield > TOL_NR)
  
  ! Store in state
  state%sigma_eq = sigma_vm
  state%f_yield = f_yield
  state%R_iso = sigma_yield - desc%sigma_y0
  
  status%code = 0
  status%message = "Yield function computed"
  
END FUNCTION PH_Elem_B31_Plas_J2YieldFunction

! =============================================================================
! PH_Elem_B31_Plas_ReturnMapping
! =============================================================================
! Purpose: Radial return mapping algorithm for J2 plasticity
!
! Algorithm:
!   1. Elastic predictor: σ_trial = D : (ε_total - ε_p_old)
!   2. Check yield: f_trial > 0 ?
!   3. Plastic corrector: σ_new = σ_trial - Δγ * D : N
!   4. Update internal variables
!   5. Compute consistent tangent
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_ReturnMapping(&
    desc, state, algo_ctx, &
    strain_total, strain_old, &
    sigma_new, eps_p_new, kappa_new, &
    D_consistent, converged, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: strain_total(6)
  REAL(wp), INTENT(IN)  :: strain_old(6)
  REAL(wp), INTENT(OUT) :: sigma_new(6)
  REAL(wp), INTENT(OUT) :: eps_p_new(6)
  REAL(wp), INTENT(OUT) :: kappa_new
  REAL(wp), INTENT(OUT) :: D_consistent(6, 6)
  LOGICAL,  INTENT(OUT) :: converged
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: D_elastic(6, 6)
  REAL(wp) :: sigma_trial(6)
  REAL(wp) :: f_trial, df_dsigma(6)
  REAL(wp) :: delta_gamma, gamma_dot
  REAL(wp) :: N_flow(6)
  REAL(wp) :: sigma_vm_trial, sigma_yield
  REAL(wp) :: three_G, denom
  INTEGER(i4) :: iter
  LOGICAL  :: yield_flag
  
  D_elastic = algo_ctx%D_elastic
  
  ! Step 1: Elastic predictor
  ! σ_trial = D : (ε_total - ε_p_old)
  REAL(wp) :: eps_elastic(6)
  eps_elastic = strain_total - state%eps_p
  sigma_trial = MATMUL(D_elastic, eps_elastic)
  
  ! Step 2: Check yield condition
  yield_flag = PH_Elem_B31_Plas_J2YieldFunction(&
      desc, state, sigma_trial, state%alpha, state%kappa, &
      f_trial, df_dsigma, status)
  
  IF (.NOT. yield_flag) THEN
    ! Elastic step: no plastic flow
    sigma_new = sigma_trial
    eps_p_new = state%eps_p
    kappa_new = state%kappa
    D_consistent = D_elastic
    
    converged = .TRUE.
    algo_ctx%converged = .TRUE.
    algo_ctx%nr_iter = 0
    
    status%code = 0
    status%message = "Elastic step (no yielding)"
    RETURN
  END IF
  
  ! Step 3: Plastic corrector (radial return)
  ! For J2: σ_new lies on yield surface
  
  ! Compute flow direction (from trial stress)
  N_flow = df_dsigma  ! Already normalized for von Mises
  
  ! Compute plastic multiplier Δγ using Newton-Raphson
  ! Residual equation: r(Δγ) = σ_vm(Δγ) - σ_y(κ+Δγ) = 0
  
  delta_gamma = 0.0_wp  ! Initial guess
  converged = .FALSE.
  
  DO iter = 1, MAX_ITER_NR
    algo_ctx%nr_iter = iter
    
    ! Updated stress: σ = σ_trial - Δγ * D : N
    ! For J2 with associative flow: D:N = 3G*N (deviatoric)
    three_G = 3.0_wp * desc%G
    
    ! σ_vm = σ_vm_trial - 3G*Δγ
    sigma_vm_trial = state%sigma_eq
    sigma_yield = desc%sigma_y0 + desc%H_iso * (state%kappa + delta_gamma)
    
    ! Residual: r = σ_vm_trial - 3G*Δγ - σ_y
    algo_ctx%residual = sigma_vm_trial - three_G * delta_gamma - sigma_yield
    
    ! Check convergence
    IF (ABS(algo_ctx%residual) < TOL_NR) THEN
      converged = .TRUE.
      EXIT
    END IF
    
    ! Newton update: Δγ_new = Δγ_old - r / (dr/dγ)
    ! dr/dγ = -3G - H_iso
    denom = -three_G - desc%H_iso
    
    IF (ABS(denom) < SMALL_VAL) THEN
      ! Perfect plasticity or numerical issue
      delta_gamma = sigma_vm_trial / three_G
      converged = .TRUE.
      EXIT
    END IF
    
    delta_gamma = delta_gamma - algo_ctx%residual / denom
    
    ! Ensure non-negative plastic multiplier
    delta_gamma = MAX(0.0_wp, delta_gamma)
  END DO
  
  IF (.NOT. converged) THEN
    status%code = -1
    status%message = "Return mapping did not converge"
    RETURN
  END IF
  
  ! Step 4: Update stress
  ! σ_new = σ_trial - Δγ * (3G) * N
  sigma_new = sigma_trial - delta_gamma * three_G * N_flow
  
  ! Step 5: Update plastic strain
  ! ε_p_new = ε_p_old + Δγ * N
  eps_p_new = state%eps_p + delta_gamma * N_flow
  
  ! Step 6: Update cumulative plastic strain
  ! κ_new = κ_old + sqrt(2/3) * Δγ
  kappa_new = state%kappa + SQRT(2.0_wp / 3.0_wp) * delta_gamma
  
  ! Step 7: Compute consistent tangent modulus
  CALL PH_Elem_B31_Plas_ConsistentTangent(&
      desc, algo_ctx, sigma_new, N_flow, delta_gamma, &
      D_consistent, status)
  
  ! Store in state
  state%sigma = sigma_new
  state%eps_p = eps_p_new
  state%kappa = kappa_new
  state%eps_p_cum = kappa_new
  
  algo_ctx%converged = .TRUE.
  algo_ctx%N_flow = N_flow
  
  status%code = 0
  status%message = "Plastic return mapping converged in "//TRIM(ITOA(iter))//" iterations"
  
END SUBROUTINE PH_Elem_B31_Plas_ReturnMapping

! =============================================================================
! PH_Elem_B31_Plas_ConsistentTangent
! =============================================================================
! Purpose: Compute consistent tangent modulus for quadratic convergence
!
! D_consistent = D_elastic - (D_elastic : N) ⊗ (D_elastic : N) / (N : D_elastic : N + H')
!
! where H' = dσ_y/dκ (hardening modulus)
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_ConsistentTangent(&
    desc, algo_ctx, &
    sigma, N_flow, delta_gamma, &
    D_consistent, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: sigma(6)
  REAL(wp), INTENT(IN)  :: N_flow(6)
  REAL(wp), INTENT(IN)  :: delta_gamma
  REAL(wp), INTENT(OUT) :: D_consistent(6, 6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: D_elastic(6, 6)
  REAL(wp) :: DN(6)                  ! D : N
  REAL(wp) :: NTN                    ! N : D : N (scalar)
  REAL(wp) :: H_prime                ! Tangent hardening modulus
  REAL(wp) :: denom, coef
  INTEGER(i4) :: i, j
  
  D_elastic = algo_ctx%D_elastic
  
  ! Compute D : N
  DN = MATMUL(D_elastic, N_flow)
  
  ! Compute N : D : N
  NTN = DOT_PRODUCT(N_flow, DN)
  
  ! Tangent hardening modulus
  H_prime = desc%H_iso
  
  ! Denominator: N : D : N + H'
  denom = NTN + H_prime
  
  ! Consistent tangent: D_ep = D - (DN ⊗ DN) / denom
  IF (ABS(denom) > SMALL_VAL) THEN
    coef = 1.0_wp / denom
    
    D_consistent = D_elastic
    DO i = 1, 6
      DO j = 1, 6
        D_consistent(i, j) = D_consistent(i, j) - coef * DN(i) * DN(j)
      END DO
    END DO
  ELSE
    ! Near-perfect plasticity: use elastic matrix
    D_consistent = D_elastic
  END IF
  
  ! Store in context
  algo_ctx%D_tangent = D_consistent
  
  status%code = 0
  status%message = "Consistent tangent computed"
  
END SUBROUTINE PH_Elem_B31_Plas_ConsistentTangent

! =============================================================================
! PH_Elem_B31_Plas_UpdateStress
! =============================================================================
! Purpose: Main interface for stress update at material point
!
! Combines elastic predictor + plastic corrector
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_UpdateStress(&
    desc, state, algo_ctx, &
    strain_total, strain_rate, dt, &
    sigma_out, D_tangent_out, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: strain_total(6)
  REAL(wp), INTENT(IN)  :: strain_rate(6)
  REAL(wp), INTENT(IN)  :: dt
  REAL(wp), INTENT(OUT) :: sigma_out(6)
  REAL(wp), INTENT(OUT) :: D_tangent_out(6, 6)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: eps_p_new(6), kappa_new
  REAL(wp) :: D_consistent(6, 6)
  LOGICAL  :: converged
  
  ! Set time parameters
  algo_ctx%dt = dt
  
  ! Call return mapping
  CALL PH_Elem_B31_Plas_ReturnMapping(&
      desc, state, algo_ctx, &
      strain_total, state%eps_p, &  ! Use current plastic strain as old
      sigma_out, eps_p_new, kappa_new, &
      D_consistent, converged, status)
  
  IF (.NOT. converged) THEN
    status%code = -1
    status%message = "Stress update failed"
    RETURN
  END IF
  
  ! Output consistent tangent
  D_tangent_out = D_consistent
  
  status%code = 0
  status%message = "Stress update successful"
  
END SUBROUTINE PH_Elem_B31_Plas_UpdateStress

! =============================================================================
! PH_Elem_B31_Plas_SectionFiberModel
! =============================================================================
! Purpose: Compute section resultants from fiber integration
!
! N = ∫ σ dA, M_y = ∫ σ*z dA, M_z = -∫ σ*y dA
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_SectionFiberModel(&
    desc, state, algo_ctx, &
    eps_axial, kappa_y, kappa_z, &
    N_axial, M_y, M_z, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: eps_axial         ! Axial strain at centroid
  REAL(wp), INTENT(IN)  :: kappa_y           ! Curvature about y-axis
  REAL(wp), INTENT(IN)  :: kappa_z           ! Curvature about z-axis
  REAL(wp), INTENT(OUT) :: N_axial           ! Axial force
  REAL(wp), INTENT(OUT) :: M_y               ! Bending moment about y
  REAL(wp), INTENT(OUT) :: M_z               ! Bending moment about z
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: strain_fiber(6)
  REAL(wp) :: sigma_fiber(6)
  REAL(wp) :: D_dummy(6, 6)
  REAL(wp) :: y_coord, z_coord, fiber_area
  REAL(wp) :: sigma_xx
  INTEGER(i4) :: i
  
  N_axial = 0.0_wp
  M_y = 0.0_wp
  M_z = 0.0_wp
  
  ! Loop over fibers
  DO i = 1, desc%n_fibers
    ! Get fiber coordinates
    y_coord = desc%fiber_coords(1, i)
    z_coord = desc%fiber_coords(2, i)
    fiber_area = desc%fiber_coords(3, i)
    
    ! Compute strain at fiber location
    ! ε_xx = ε₀ + κ_y*z - κ_z*y (beam kinematics)
    strain_fiber = 0.0_wp
    strain_fiber(1) = eps_axial + kappa_y * z_coord - kappa_z * y_coord
    
    ! Call material model for this fiber
    CALL PH_Elem_B31_Plas_UpdateStress(&
        desc, state, algo_ctx, &
        strain_fiber, strain_fiber, 1.0_wp, &
        sigma_fiber, D_dummy, status)
    
    ! Store fiber state
    state%fiber_stress(i) = sigma_fiber(1)
    state%fiber_strain(i) = strain_fiber(1)
    state%fiber_yield(i) = MERGE(1.0_wp, 0.0_wp, state%f_yield > 0.0_wp)
    
    ! Integrate to get resultants
    sigma_xx = sigma_fiber(1)
    N_axial = N_axial + sigma_xx * fiber_area
    M_y = M_y + sigma_xx * z_coord * fiber_area
    M_z = M_z - sigma_xx * y_coord * fiber_area
  END DO
  
  ! Store in context
  algo_ctx%N_axial = N_axial
  algo_ctx%M_y = M_y
  algo_ctx%M_z = M_z
  
  status%code = 0
  status%message = "Section fiber integration complete"
  
END SUBROUTINE PH_Elem_B31_Plas_SectionFiberModel

! =============================================================================
! PH_Elem_B31_Plas_PlasticHinge
! =============================================================================
! Purpose: Simplified plastic hinge model with M-N interaction
!
! Yield surface: Φ(M, N) = (M/M_p)² + (N/N_p)² - 1 ≤ 0
! =============================================================================
SUBROUTINE PH_Elem_B31_Plas_PlasticHinge(&
    desc, state, algo_ctx, &
    N_axial, M_y, M_z, &
    phi_yield, plastic_rotation, status)
    
  TYPE(B31_Plas_Mat_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Plas_Mat_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Plas_Mat_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: N_axial
  REAL(wp), INTENT(IN)  :: M_y, M_z
  REAL(wp), INTENT(OUT) :: phi_yield
  REAL(wp), INTENT(OUT) :: plastic_rotation
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  REAL(wp) :: N_p, M_py, M_pz
  REAL(wp) :: M_resultant
  REAL(wp) :: interaction_ratio
  
  ! Compute plastic capacities
  N_p = desc%sigma_y0 * SUM(desc%fiber_coords(3, :))  ! N_p = σ_y0 * A
  M_py = desc%sigma_y0 * 1.0_wp  ! TODO: Compute plastic section modulus Z_y
  M_pz = desc%sigma_y0 * 1.0_wp  ! TODO: Compute plastic section modulus Z_z
  
  M_resultant = SQRT(M_y**2 + M_z**2)
  
  ! M-N interaction yield surface
  ! Φ = (M/M_p)² + (N/N_p)² - 1
  IF (ABS(M_pz) > SMALL_VAL .AND. ABS(N_p) > SMALL_VAL) THEN
    interaction_ratio = (M_resultant / M_pz)**2 + (N_axial / N_p)**2
    phi_yield = interaction_ratio - 1.0_wp
  ELSE
    phi_yield = -1.0_wp  ! Undefined
  END IF
  
  ! Check if plastic hinge forms
  IF (phi_yield > TOL_NR) THEN
    ! Plastic rotation develops
    ! TODO: Implement flow rule for plastic hinge
    
    plastic_rotation = phi_yield * 0.01_wp  ! Placeholder
    
    WRITE(*, '(A)') '  [WARNING] Plastic hinge formed!'
  ELSE
    plastic_rotation = 0.0_wp
  END IF
  
  status%code = 0
  status%message = "Plastic hinge check complete"
  
END SUBROUTINE PH_Elem_B31_Plas_PlasticHinge

END MODULE PH_Elem_B31Plasticity