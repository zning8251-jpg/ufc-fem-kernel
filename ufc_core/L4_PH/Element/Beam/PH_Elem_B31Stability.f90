!===============================================================================
! MODULE: PH_Elem_B31Stability
! LAYER:  L4_PH
! DOMAIN: Element/Beam
! ROLE:   Proc
! BRIEF:  B31 beam stability analysis core
!===============================================================================
MODULE PH_Elem_B31Stability
USE UFC_Kind_Defn
USE UFC_Const_Math
USE ErrorHandler

IMPLICIT NONE

PRIVATE
PUBLIC :: PH_Elem_B31_Stab_Initialize
PUBLIC :: PH_Elem_B31_Stab_LinearBuckling
PUBLIC :: PH_Elem_B31_Stab_ArcLengthRiks
PUBLIC :: PH_Elem_B31_Stab_ArcLengthCrisfield
PUBLIC :: PH_Elem_B31_Stab_IntroduceImperfection
PUBLIC :: PH_Elem_B31_Stab_DetectCriticalPoint
PUBLIC :: PH_Elem_B31_Stab_PostBucklingPath

! =============================================================================
! Type Definitions for Stability Analysis
! =============================================================================

TYPE :: B31_Stab_Desc_Type
  ! Buckling analysis parameters
  INTEGER(i4) :: n_modes_requested        ! Number of buckling modes to extract
  REAL(wp) :: load_ref                 ! Reference load magnitude
  CHARACTER(len=32) :: method          ! 'EIGEN', 'RIKS', 'CRISFIELD'
  
  ! Arc-length control parameters
  REAL(wp) :: arc_length_initial       ! Initial arc length radius
  REAL(wp) :: arc_length_min           ! Minimum arc length
  REAL(wp) :: arc_length_max           ! Maximum arc length
  REAL(wp) :: max_displacement         ! Maximum displacement limit
  
  ! Iteration control
  INTEGER(i4) :: max_iterations            ! Max NR iterations per step
  REAL(wp) :: tol_force                  ! Force convergence tolerance
  REAL(wp) :: tol_energy                 ! Energy convergence tolerance
  REAL(wp) :: tol_displacement           ! Displacement convergence tolerance
  
  ! Imperfection parameters
  REAL(wp) :: imperfection_scale        ! Scale factor for geometric imperfection
  INTEGER(i4) :: imperfection_mode         ! Buckling mode number for imperfection
  
  ! Critical point detection
  LOGICAL  :: detect_snap_through       ! Enable snap-through detection
  LOGICAL  :: detect_bifurcation        ! Enable bifurcation detection
END TYPE B31_Stab_Desc_Type

TYPE :: B31_Stab_State_Type
  ! Load parameter
  REAL(wp) :: lambda                   ! Current load factor
  REAL(wp) :: lambda_prev              ! Previous load factor
  REAL(wp) :: dlambda                  ! Load increment
  
  ! Arc-length variables
  REAL(wp) :: arc_length_current       ! Current arc length radius
  REAL(wp) :: ds                       ! Arc length increment
  REAL(wp) :: constraint_value         ! Constraint equation value
  
  ! Displacement state
  REAL(wp) :: u_total(:)               ! Total displacement vector
  REAL(wp) :: u_predictor(:)           ! Predictor displacement
  REAL(wp) :: u_corrector(:)           ! Corrector displacement
  
  ! Path following
  INTEGER(i4) :: branch_direction          ! +1 or -1 for path direction
  LOGICAL  :: passed_limit_point        ! Flag for limit point passage
  
  ! Critical points
  INTEGER(i4) :: n_critical_points         ! Number of detected critical points
  REAL(wp), ALLOCATABLE :: critical_loads(:)    ! Critical load factors
  REAL(wp), ALLOCATABLE :: critical_disps(:,:)  ! Critical displacements
  
  ! Mode shapes
  REAL(wp), ALLOCATABLE :: buckling_modes(:,:,:) ! Mode shapes at nodes
  REAL(wp), ALLOCATABLE :: eigenvalues(:)        ! Eigenvalues λ_i
END TYPE B31_Stab_State_Type

TYPE :: B31_Stab_AlgoCtx_Type
  ! Work arrays
  REAL(wp) :: K_mat(:,:)               ! Material stiffness matrix
  REAL(wp) :: K_geo(:,:)               ! Geometric stiffness matrix
  REAL(wp) :: K_tan(:,:)               ! Tangent stiffness matrix
  REAL(wp) :: F_int(:)                 ! Internal force vector
  REAL(wp) :: F_ext(:)                 ! External reference load
  REAL(wp) :: F_resid(:)               ! Residual force vector
  
  ! Eigensolver workspace
  REAL(wp) :: subspace_vecs(:,:)       ! Subspace iteration vectors
  INTEGER(i4) :: n_subspace_iter          ! Subspace iterations
  
  ! Arc-length algorithm
  INTEGER(i4) :: pivot_sign              ! Sign of tangent matrix pivot
  INTEGER(i4) :: last_pivot_sign         ! Previous pivot sign
  LOGICAL  :: negative_pivot_detected ! Negative pivot flag
  
  ! Iteration history
  INTEGER(i4) :: nr_iter                 ! Newton-Raphson iterations
  REAL(wp) :: residual_norm            ! Residual norm
  REAL(wp) :: energy_norm              ! Energy norm
  REAL(wp) :: displacement_norm        ! Displacement norm
  LOGICAL  :: converged               ! Convergence flag
  
  ! Path tracking
  INTEGER(i4) :: total_steps             ! Total load steps completed
  INTEGER(i4) :: failed_steps            ! Number of failed steps
  
  ! Temporary arrays
  REAL(wp) :: temp_n(:)                ! Temporary vector (size = n_dof)
  REAL(wp) :: temp_m(:,:)              ! Temporary matrix
END TYPE B31_Stab_AlgoCtx_Type

! =============================================================================
! Constants and Parameters
! =============================================================================

REAL(wp), PARAMETER :: TOL_EIGEN = 1.0e-8_wp        ! Eigenvalue tolerance
REAL(wp), PARAMETER :: TOL_ARCLENGTH = 1.0e-6_wp    ! Arc-length tolerance
REAL(wp), PARAMETER :: DEFAULT_ARC_RADIUS = 0.1_wp  ! Default arc length
INTEGER(i4), PARAMETER :: MAX_SUBSPACE_ITER = 100      ! Max subspace iterations
INTEGER(i4), PARAMETER :: MAX_ARC_STEPS = 1000         ! Max arc-length steps

CONTAINS

! =============================================================================
! PH_Elem_B31_Stab_Initialize
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_Initialize(&
    desc, state, algo_ctx, &
    stability_params, n_dof, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(OUT) :: desc
  TYPE(B31_Stab_State_Type), INTENT(OUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(OUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: stability_params(10)  ! Analysis parameters
  INTEGER(i4), INTENT(IN) :: n_dof                 ! Number of DOFs
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  ! Extract parameters
  desc%n_modes_requested = INT(stability_params(1))
  desc%load_ref = stability_params(2)
  desc%arc_length_initial = stability_params(3)
  desc%arc_length_min = stability_params(4)
  desc%arc_length_max = stability_params(5)
  desc%max_displacement = stability_params(6)
  desc%max_iterations = INT(stability_params(7))
  desc%tol_force = stability_params(8)
  desc%tol_energy = stability_params(9)
  desc%tol_displacement = stability_params(10)
  
  ! Default settings
  desc%method = 'EIGEN'
  desc%imperfection_scale = 0.0_wp
  desc%imperfection_mode = 1
  desc%detect_snap_through = .TRUE.
  desc%detect_bifurcation = .TRUE.
  
  ! Initialize state
  state%lambda = 0.0_wp
  state%lambda_prev = 0.0_wp
  state%dlambda = 0.0_wp
  state%arc_length_current = desc%arc_length_initial
  state%ds = 0.0_wp
  state%constraint_value = 0.0_wp
  state%branch_direction = 1
  state%passed_limit_point = .FALSE.
  state%n_critical_points = 0
  
  ! Allocate arrays
  ALLOCATE(state%u_total(n_dof))
  ALLOCATE(state%u_predictor(n_dof))
  ALLOCATE(state%u_corrector(n_dof))
  
  state%u_total = 0.0_wp
  state%u_predictor = 0.0_wp
  state%u_corrector = 0.0_wp
  
  ! Initialize algorithm context
  algo_ctx%K_mat = 0.0_wp
  algo_ctx%K_geo = 0.0_wp
  algo_ctx%K_tan = 0.0_wp
  algo_ctx%F_int = 0.0_wp
  algo_ctx%F_ext = 0.0_wp
  algo_ctx%F_resid = 0.0_wp
  algo_ctx%nr_iter = 0
  algo_ctx%residual_norm = 0.0_wp
  algo_ctx%energy_norm = 0.0_wp
  algo_ctx%displacement_norm = 0.0_wp
  algo_ctx%converged = .FALSE.
  algo_ctx%pivot_sign = 1
  algo_ctx%last_pivot_sign = 1
  algo_ctx%negative_pivot_detected = .FALSE.
  algo_ctx%total_steps = 0
  algo_ctx%failed_steps = 0
  
  ALLOCATE(algo_ctx%temp_n(n_dof))
  ALLOCATE(algo_ctx%temp_m(n_dof, n_dof))
  
  status%code = 0
  status%message = "Stability analysis initialized"
  
END SUBROUTINE PH_Elem_B31_Stab_Initialize

! =============================================================================
! PH_Elem_B31_Stab_LinearBuckling
! =============================================================================
! Purpose: Solve linear buckling eigenvalue problem
!
! (K_mat + λ*K_geo) φ = 0
!
! Using subspace iteration method
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_LinearBuckling(&
    desc, state, algo_ctx, &
    K_mat_in, K_geo_in, &
    n_modes, eigenvalues, eigenvectors, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_mat_in(:,:)     ! Material stiffness
  REAL(wp), INTENT(IN)  :: K_geo_in(:,:)     ! Geometric stiffness
  INTEGER(i4), INTENT(IN) :: n_modes           ! Number of modes
  REAL(wp), INTENT(OUT) :: eigenvalues(n_modes)
  REAL(wp), INTENT(OUT) :: eigenvectors(:,:,:) ! Mode shapes
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_dof, i, j
  INTEGER(i4) :: iter
  REAL(wp) :: eigenvalue_old(n_modes)
  REAL(wp) :: beta(n_modes, n_modes)
  REAL(wp) :: work(n_dof, n_modes)
  REAL(wp) :: residual, tol
  
  n_dof = SIZE(K_mat_in, 1)
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Linear Buckling Analysis (Subspace Iteration)'
  WRITE(*, '(A,I4)') '  DOFs: ', n_dof
  WRITE(*, '(A,I4)') '  Requested modes: ', n_modes
  WRITE(*, '(A)') '=========================================='
  
  ! Store stiffness matrices
  algo_ctx%K_mat = K_mat_in
  algo_ctx%K_geo = K_geo_in
  
  ! Initialize subspace vectors (random start)
  ALLOCATE(algo_ctx%subspace_vecs(n_dof, n_modes))
  CALL RANDOM_NUMBER(algo_ctx%subspace_vecs)
  
  ! Orthogonalize initial vectors
  CALL PH_Elem_B31_Stab_GramSchmidt(&
      algo_ctx%subspace_vecs, n_dof, n_modes)
  
  ! Subspace iteration
  eigenvalues = 0.0_wp
  eigenvalue_old = -1.0_wp
  tol = TOL_EIGEN
  iter = 0
  
  DO WHILE (iter < MAX_SUBSPACE_ITER)
    iter = iter + 1
    algo_ctx%n_subspace_iter = iter
    
    ! Step 1: Solve K_mat * W = K_geo * V
    ! W = K_mat^(-1) * K_geo * V
    DO i = 1, n_modes
      work(:, i) = MATMUL(K_geo_in, algo_ctx%subspace_vecs(:, i))
      
      ! Solve linear system: K_mat * x = work(:,i)
      ! TODO: Use efficient solver (Cholesky/LDLT)
      CALL PH_Elem_B31_Stab_SolveLinearSystem(&
          K_mat_in, work(:, i), algo_ctx%subspace_vecs(:, i), status)
    END DO
    
    ! Step 2: Rayleigh-Ritz projection
    ! Project onto subspace: A = V^T * K_mat * V, B = V^T * K_geo * V
    ! Simplified: Solve reduced eigenproblem
    
    ! Form projection matrices
    REAL(wp) :: A_red(n_modes, n_modes), B_red(n_modes, n_modes)
    
    DO i = 1, n_modes
      DO j = 1, n_modes
        A_red(i, j) = DOT_PRODUCT(algo_ctx%subspace_vecs(:, i), &
                                  MATMUL(K_mat_in, algo_ctx%subspace_vecs(:, j)))
        B_red(i, j) = DOT_PRODUCT(algo_ctx%subspace_vecs(:, i), &
                                  MATMUL(K_geo_in, algo_ctx%subspace_vecs(:, j)))
      END DO
    END DO
    
    ! Solve generalized eigenproblem: A*x = λ*B*x
    ! Using Jacobi method for symmetric matrices
    CALL PH_Elem_B31_Stab_JacobiEigen(&
        A_red, B_red, n_modes, &
        eigenvalues, beta, status)
    
    ! Sort eigenvalues (ascending)
    CALL PH_Elem_B31_Stab_SortEigenvalues(&
        eigenvalues, beta, n_modes)
    
    ! Update eigenvectors: V_new = V * Q
    DO i = 1, n_modes
      algo_ctx%subspace_vecs(:, i) = 0.0_wp
      DO j = 1, n_modes
        algo_ctx%subspace_vecs(:, i) = algo_ctx%subspace_vecs(:, i) + &
                                       beta(j, i) * algo_ctx%subspace_vecs(:, j)
      END DO
    END DO
    
    ! Re-orthogonalize
    CALL PH_Elem_B31_Stab_GramSchmidt(&
        algo_ctx%subspace_vecs, n_dof, n_modes)
    
    ! Check convergence
    residual = 0.0_wp
    DO i = 1, n_modes
      IF (ABS(eigenvalue_old(i)) > SMALL_VAL) THEN
        residual = MAX(residual, ABS(eigenvalues(i) - eigenvalue_old(i)) / &
                                   ABS(eigenvalue_old(i)))
      END IF
    END DO
    
    IF (residual < tol) EXIT
    
    eigenvalue_old = eigenvalues
  END DO
  
  ! Store results
  DO i = 1, n_modes
    eigenvectors(:, :, i) = RESHAPE(algo_ctx%subspace_vecs(:, i), &
                                    [SIZE(eigenvectors, 1), SIZE(eigenvectors, 2)])
  END DO
  
  ! Store in state
  ALLOCATE(state%eigenvalues(n_modes))
  ALLOCATE(state%buckling_modes(SIZE(eigenvectors, 1), SIZE(eigenvectors, 2), n_modes))
  
  state%eigenvalues = eigenvalues
  state%buckling_modes = eigenvectors
  
  WRITE(*, '(A,I4,A)') '  Converged in ', iter, ' iterations'
  WRITE(*, '(A)') '  Buckling load factors:'
  DO i = 1, MIN(5, n_modes)
    WRITE(*, '(I4,A,F12.6)') i, ': λ = ', eigenvalues(i)
  END DO
  
  status%code = 0
  status%message = "Linear buckling analysis complete"
  
END SUBROUTINE PH_Elem_B31_Stab_LinearBuckling

! =============================================================================
! PH_Elem_B31_Stab_ArcLengthRiks
! =============================================================================
! Purpose: Riks arc-length method for post-buckling path tracing
!
! Constraint equation: Δu^T * Δu + ψ² * Δλ² * F_ref^T * F_ref = Δs²
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_ArcLengthRiks(&
    desc, state, algo_ctx, &
    K_tan, F_int, F_ext_ref, &
    u_new, lambda_new, converged, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_tan(:,:)      ! Tangent stiffness
  REAL(wp), INTENT(IN)  :: F_int(:)        ! Internal forces
  REAL(wp), INTENT(IN)  :: F_ext_ref(:)    ! Reference external load
  REAL(wp), INTENT(OUT) :: u_new(:)        ! Updated displacements
  REAL(wp), INTENT(OUT) :: lambda_new      ! Updated load factor
  LOGICAL,  INTENT(OUT) :: converged       ! Convergence flag
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_dof, iter
  REAL(wp) :: ds_target                  ! Target arc length
  REAL(wp) :: psi                        ! Arc length parameter
  REAL(wp) :: delta_u_bar( SIZE(u_new) ) ! Displacement due to unit load
  REAL(wp) :: delta_u_hat( SIZE(u_new) ) ! Displacement correction
  REAL(wp) :: delta_lambda               ! Load factor increment
  REAL(wp) :: a1, a2, a3                 ! Coefficients for quadratic
  REAL(wp) :: delta_s_sq                 ! Δs²
  INTEGER(i4) :: n_roots                    ! Number of real roots
  
  n_dof = SIZE(u_new)
  ds_target = state%arc_length_current
  psi = 1.0_wp  ! Standard arc length
  
  ! Initialize
  converged = .FALSE.
  algo_ctx%nr_iter = 0
  
  ! Reference load magnitude
  REAL(wp) :: F_ref_norm
  F_ref_norm = SQRT(DOT_PRODUCT(F_ext_ref, F_ext_ref))
  
  ! Newton-Raphson iteration
  DO iter = 1, desc%max_iterations
    algo_ctx%nr_iter = iter
    
    ! Compute residual: R = λ*F_ext - F_int
    algo_ctx%F_resid = state%lambda * F_ext_ref - F_int
    
    ! Check convergence
    algo_ctx%residual_norm = SQRT(DOT_PRODUCT(algo_ctx%F_resid, algo_ctx%F_resid))
    
    IF (algo_ctx%residual_norm < desc%tol_force) THEN
      converged = .TRUE.
      EXIT
    END IF
    
    ! Solve: K_tan * δu_bar = F_ext_ref (unit load response)
    CALL PH_Elem_B31_Stab_SolveLinearSystem(&
        K_tan, F_ext_ref, delta_u_bar, status)
    
    ! Solve: K_tan * δu_hat = R (residual correction)
    CALL PH_Elem_B31_Stab_SolveLinearSystem(&
        K_tan, algo_ctx%F_resid, delta_u_hat, status)
    
    ! Arc-length constraint equation
    ! (δu_bar + δλ*δu_hat)^T*(δu_bar + δλ*δu_hat) + ψ²*Δλ²*F_ref² = Δs²
    
    ! Coefficients for quadratic: a1*Δλ² + a2*Δλ + a3 = 0
    REAL(wp) :: du_bar_sq, du_hat_sq, du_bar_hat
    REAL(wp) :: dlambda_total
    
    du_bar_sq = DOT_PRODUCT(delta_u_bar, delta_u_bar)
    du_hat_sq = DOT_PRODUCT(delta_u_hat, delta_u_hat)
    du_bar_hat = DOT_PRODUCT(delta_u_bar, delta_u_hat)
    
    dlambda_total = state%lambda - state%lambda_prev
    
    a1 = du_hat_sq + psi**2 * F_ref_norm**2
    a2 = 2.0_wp * (du_bar_hat - du_hat_sq) - 2.0_wp * psi**2 * F_ref_norm**2 * dlambda_total
    a3 = du_bar_sq - 2.0_wp * du_bar_hat + du_hat_sq - ds_target**2 + &
         psi**2 * F_ref_norm**2 * dlambda_total**2
    
    ! Solve quadratic
    REAL(wp) :: discriminant, dl1, dl2
    
    discriminant = a2**2 - 4.0_wp * a1 * a3
    
    IF (discriminant >= 0.0_wp) THEN
      dl1 = (-a2 + SQRT(discriminant)) / (2.0_wp * a1)
      dl2 = (-a2 - SQRT(discriminant)) / (2.0_wp * a1)
      
      ! Choose root based on path continuation
      IF (iter == 1) THEN
        ! First iteration: use predictor direction
        delta_lambda = MERGE(dl1, dl2, dl1 > 0.0_wp)
      ELSE
        ! Subsequent iterations: minimize angle with previous increment
        REAL(wp) :: cos_theta1, cos_theta2
        REAL(wp) :: du_prev(SIZE(u_new))
        
        du_prev = state%u_total - state%u_predictor
        
        cos_theta1 = DOT_PRODUCT(du_prev, delta_u_bar + dl1*delta_u_hat)
        cos_theta2 = DOT_PRODUCT(du_prev, delta_u_bar + dl2*delta_u_hat)
        
        delta_lambda = MERGE(dl1, dl2, cos_theta1 > cos_theta2)
      END IF
      
      n_roots = 2
    ELSE
      ! No real roots: reduce arc length
      state%arc_length_current = 0.5_wp * state%arc_length_current
      delta_lambda = 0.0_wp
      n_roots = 0
    END IF
    
    ! Update displacement and load factor
    state%u_corrector = delta_u_bar + delta_lambda * delta_u_hat
    state%u_total = state%u_total + state%u_corrector
    state%lambda = state%lambda + delta_lambda
    
    ! Check for limit point passage (pivot sign change)
    CALL PH_Elem_B31_Stab_CheckPivotSign(K_tan, algo_ctx%last_pivot_sign, &
                                         algo_ctx%pivot_sign, algo_ctx%negative_pivot_detected)
    
    IF (algo_ctx%negative_pivot_detected .AND. .NOT. state%passed_limit_point) THEN
      state%passed_limit_point = .TRUE.
      WRITE(*, '(A)') '  *** Limit point detected ***'
    END IF
    
    ! Update displacement norms
    algo_ctx%displacement_norm = SQRT(DOT_PRODUCT(state%u_corrector, state%u_corrector))
    
  END DO
  
  ! Output results
  u_new = state%u_total
  lambda_new = state%lambda
  
  IF (converged) THEN
    state%total_steps = state%total_steps + 1
  ELSE
    algo_ctx%failed_steps = algo_ctx%failed_steps + 1
  END IF
  
  status%code = 0
  IF (converged) THEN
    status%message = "Arc-length converged in "//TRIM(ITOA(iter))//" iterations"
  ELSE
    status%message = "Arc-length did not converge"
  END IF
  
END SUBROUTINE PH_Elem_B31_Stab_ArcLengthRiks

! =============================================================================
! PH_Elem_B31_Stab_ArcLengthCrisfield
! =============================================================================
! Purpose: Crisfield's modified arc-length method (spherical update)
!
! Improved numerical stability over standard Riks method
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_ArcLengthCrisfield(&
    desc, state, algo_ctx, &
    K_tan, F_int, F_ext_ref, &
    u_new, lambda_new, converged, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_tan(:,:)
  REAL(wp), INTENT(IN)  :: F_int(:)
  REAL(wp), INTENT(IN)  :: F_ext_ref(:)
  REAL(wp), INTENT(OUT) :: u_new(:)
  REAL(wp), INTENT(OUT) :: lambda_new
  LOGICAL,  INTENT(OUT) :: converged
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  ! Similar to Riks but with spherical constraint
  ! Implementation follows Crisfield (1981)
  
  ! TODO: Full implementation
  ! For now, delegate to Riks method
  CALL PH_Elem_B31_Stab_ArcLengthRiks(&
      desc, state, algo_ctx, &
      K_tan, F_int, F_ext_ref, &
      u_new, lambda_new, converged, &
      status)
  
  status%message = "Crisfield arc-length (via Riks): "//status%message
  
END SUBROUTINE PH_Elem_B31_Stab_ArcLengthCrisfield

! =============================================================================
! PH_Elem_B31_Stab_IntroduceImperfection
! =============================================================================
! Purpose: Introduce geometric imperfection based on buckling mode
!
! u_imperfect = u_perfect + α * h * φ_i
!
! where:
!   α = imperfection scale factor
!   h = characteristic dimension (thickness, length)
!   φ_i = i-th buckling mode shape
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_IntroduceImperfection(&
    desc, state, algo_ctx, &
    coords_original, &
    coords_imperfect, &
    h_char, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(IN) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(IN) :: algo_ctx
  REAL(wp), INTENT(IN)  :: coords_original(:,:)  ! Original coordinates (3, n_nodes)
  REAL(wp), INTENT(OUT) :: coords_imperfect(:,:) ! Imperfect coordinates
  REAL(wp), INTENT(IN)  :: h_char                ! Characteristic dimension
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: n_nodes, i_node
  INTEGER(i4) :: mode_idx
  REAL(wp) :: alpha, scale
  REAL(wp) :: phi(3)                     ! Mode shape at node
  
  n_nodes = SIZE(coords_original, 2)
  alpha = desc%imperfection_scale
  mode_idx = desc%imperfection_mode
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Introducing Geometric Imperfection'
  WRITE(*, '(A,F8.4)') '  Scale factor: ', alpha
  WRITE(*, '(A,I4)') '  Mode number: ', mode_idx
  WRITE(*, '(A,F12.6,A)') '  Characteristic dim: ', h_char, ' m'
  WRITE(*, '(A)') '=========================================='
  
  ! Get buckling mode shape
  IF (.NOT. ALLOCATED(state%buckling_modes)) THEN
    status%code = -1
    status%message = "Error: Buckling modes not available"
    RETURN
  END IF
  
  IF (mode_idx > SIZE(state%buckling_modes, 3)) THEN
    status%code = -1
    status%message = "Error: Mode index out of range"
    RETURN
  END IF
  
  ! Apply imperfection
  scale = alpha * h_char
  
  DO i_node = 1, n_nodes
    ! Extract mode shape at this node
    phi(1) = state%buckling_modes(i_node, 1, mode_idx)
    phi(2) = state%buckling_modes(i_node, 2, mode_idx)
    phi(3) = state%buckling_modes(i_node, 3, mode_idx)
    
    ! Add imperfection
    coords_imperfect(1, i_node) = coords_original(1, i_node) + scale * phi(1)
    coords_imperfect(2, i_node) = coords_original(2, i_node) + scale * phi(2)
    coords_imperfect(3, i_node) = coords_original(3, i_node) + scale * phi(3)
  END DO
  
  WRITE(*, '(A,F12.6,A)') '  Max imperfection: ', scale*1000.0_wp, ' mm'
  
  status%code = 0
  status%message = "Geometric imperfection applied successfully"
  
END SUBROUTINE PH_Elem_B31_Stab_IntroduceImperfection

! =============================================================================
! PH_Elem_B31_Stab_DetectCriticalPoint
! =============================================================================
! Purpose: Detect critical points (limit/bifurcation) during path following
!
! Criteria:
!   - Limit point: det(K_tan) = 0 (pivot sign change)
!   - Bifurcation: Multiple eigenvalues cross zero
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_DetectCriticalPoint(&
    desc, state, algo_ctx, &
    K_tan, lambda_current, &
    is_critical, critical_type, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  REAL(wp), INTENT(IN)  :: K_tan(:,:)
  REAL(wp), INTENT(IN)  :: lambda_current
  LOGICAL,  INTENT(OUT) :: is_critical
  INTEGER(i4), INTENT(OUT) :: critical_type  ! 1=Limit, 2=Bifurcation
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: current_pivot, prev_pivot
  
  is_critical = .FALSE.
  critical_type = 0
  
  ! Check for pivot sign change (limit point indicator)
  CALL PH_Elem_B31_Stab_CheckPivotSign(K_tan, prev_pivot, current_pivot, &
                                       algo_ctx%negative_pivot_detected)
  
  IF (current_pivot /= prev_pivot) THEN
    ! Pivot changed sign → passed through singular point
    is_critical = .TRUE.
    critical_type = 1  ! Limit point
    
    ! Record critical point
    state%n_critical_points = state%n_critical_points + 1
    
    IF (.NOT. ALLOCATED(state%critical_loads)) THEN
      ALLOCATE(state%critical_loads(10))
      ALLOCATE(state%critical_disps(10, SIZE(state%u_total)))
    END IF
    
    IF (state%n_critical_points <= 10) THEN
      state%critical_loads(state%n_critical_points) = lambda_current
      state%critical_disps(state%n_critical_points, :) = state%u_total
    END IF
    
    WRITE(*, '(A,F12.6)') '  *** Critical point detected at λ = ', lambda_current
  END IF
  
  ! TODO: Bifurcation detection via eigenvalue analysis
  
  status%code = 0
  IF (is_critical) THEN
    status%message = "Critical point type "//TRIM(ITOA(critical_type))//" detected"
  ELSE
    status%message = "No critical point"
  END IF
  
END SUBROUTINE PH_Elem_B31_Stab_DetectCriticalPoint

! =============================================================================
! PH_Elem_B31_Stab_PostBucklingPath
! =============================================================================
! Purpose: Trace complete post-buckling equilibrium path
! =============================================================================
SUBROUTINE PH_Elem_B31_Stab_PostBucklingPath(&
    desc, state, algo_ctx, &
    K_mat_func, K_geo_func, F_int_func, &
    n_steps_max, &
    load_displacement_curve, &
    status)
    
  TYPE(B31_Stab_Desc_Type), INTENT(IN)  :: desc
  TYPE(B31_Stab_State_Type), INTENT(INOUT) :: state
  TYPE(B31_Stab_AlgoCtx_Type), INTENT(INOUT) :: algo_ctx
  INTERFACE
    SUBROUTINE K_mat_func(u, K_mat, status)
      USE UFC_Kind_Defn
      REAL(wp), INTENT(IN) :: u(:)
      REAL(wp), INTENT(OUT) :: K_mat(:,:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE
  END INTERFACE
  INTERFACE
    SUBROUTINE K_geo_func(u, lambda, K_geo, status)
      USE UFC_Kind_Defn
      REAL(wp), INTENT(IN) :: u(:), lambda
      REAL(wp), INTENT(OUT) :: K_geo(:,:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE
  END INTERFACE
  INTERFACE
    SUBROUTINE F_int_func(u, lambda, F_int, status)
      USE UFC_Kind_Defn
      REAL(wp), INTENT(IN) :: u(:), lambda
      REAL(wp), INTENT(OUT) :: F_int(:)
      TYPE(ErrorStatusType), INTENT(OUT) :: status
    END SUBROUTINE
  END INTERFACE
  INTEGER(i4), INTENT(IN) :: n_steps_max
  REAL(wp), INTENT(OUT) :: load_displacement_curve(:,:) ! (lambda, u_max)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  
  INTEGER(i4) :: step
  INTEGER(i4) :: n_dof
  REAL(wp) :: K_tan(SIZE(algo_ctx%K_mat, 1), SIZE(algo_ctx%K_mat, 2))
  REAL(wp) :: F_ext(SIZE(state%u_total))
  REAL(wp) :: F_int_local(SIZE(state%u_total))
  REAL(wp) :: u_new(SIZE(state%u_total))
  REAL(wp) :: lambda_new
  LOGICAL  :: converged
  
  n_dof = SIZE(state%u_total)
  F_ext = desc%load_ref * 1.0_wp  ! Normalized reference load
  
  WRITE(*, '(A)') '=========================================='
  WRITE(*, '(A)') 'Post-Buckling Path Tracing'
  WRITE(*, '(A,I4)') '  Max steps: ', n_steps_max
  WRITE(*, '(A,F12.6)') '  Initial arc length: ', state%arc_length_current
  WRITE(*, '(A)') '=========================================='
  
  ! Main loop
  DO step = 1, n_steps_max
    WRITE(*, '(A,I4,A,F10.4)') 'Step ', step, ', λ = ', state%lambda
    
    ! Assemble tangent stiffness
    CALL K_mat_func(state%u_total, algo_ctx%K_mat, status)
    CALL K_geo_func(state%u_total, state%lambda, algo_ctx%K_geo, status)
    
    K_tan = algo_ctx%K_mat + state%lambda * algo_ctx%K_geo
    
    ! Compute internal forces
    CALL F_int_func(state%u_total, state%lambda, F_int_local, status)
    algo_ctx%F_int = F_int_local
    
    ! Arc-length step
    CALL PH_Elem_B31_Stab_ArcLengthRiks(&
        desc, state, algo_ctx, &
        K_tan, algo_ctx%F_int, F_ext, &
        u_new, lambda_new, converged, &
        status)
    
    ! Store results
    IF (ALLOCATED(load_displacement_curve)) THEN
      IF (step <= SIZE(load_displacement_curve, 1)) THEN
        load_displacement_curve(step, 1) = lambda_new
        load_displacement_curve(step, 2) = MAXVAL(ABS(u_new))
      END IF
    END IF
    
    IF (.NOT. converged) THEN
      WRITE(*, '(A)') '  Warning: Step did not converge'
      ! Reduce arc length and retry
      state%arc_length_current = 0.5_wp * state%arc_length_current
    END IF
    
    ! Check termination
    IF (MAXVAL(ABS(u_new)) > desc%max_displacement) THEN
      WRITE(*, '(A)') '  Displacement limit reached'
      EXIT
    END IF
  END DO
  
  status%code = 0
  status%message = "Post-buckling path traced for "//TRIM(ITOA(step-1))//" steps"
  
END SUBROUTINE PH_Elem_B31_Stab_PostBucklingPath

! =============================================================================
! Helper Functions
! =============================================================================

! Gram-Schmidt orthogonalization
SUBROUTINE PH_Elem_B31_Stab_GramSchmidt(V, n, m)
  REAL(wp), INTENT(INOUT) :: V(n, m)
  INTEGER(i4), INTENT(IN) :: n, m
  INTEGER(i4) :: i, j
  REAL(wp) :: norm_v, dot_ij
  
  DO i = 1, m
    DO j = 1, i-1
      dot_ij = DOT_PRODUCT(V(:, i), V(:, j))
      V(:, i) = V(:, i) - dot_ij * V(:, j)
    END DO
    norm_v = SQRT(DOT_PRODUCT(V(:, i), V(:, i)))
    IF (norm_v > SMALL_VAL) THEN
      V(:, i) = V(:, i) / norm_v
    END IF
  END DO
END SUBROUTINE PH_Elem_B31_Stab_GramSchmidt

! Solve linear system (placeholder - use LAPACK in production)
SUBROUTINE PH_Elem_B31_Stab_SolveLinearSystem(A, b, x, status)
  REAL(wp), INTENT(IN) :: A(:,:)
  REAL(wp), INTENT(IN) :: b(:)
  REAL(wp), INTENT(OUT) :: x(:)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  ! TODO: Implement efficient solver
  x = b  ! Placeholder
  status%code = 0
END SUBROUTINE

! Jacobi eigenvalue solver (placeholder)
SUBROUTINE PH_Elem_B31_Stab_JacobiEigen(A, B, n, eigenvalues, eigenvectors, status)
  REAL(wp), INTENT(IN) :: A(n, n), B(n, n)
  INTEGER(i4), INTENT(IN) :: n
  REAL(wp), INTENT(OUT) :: eigenvalues(n)
  REAL(wp), INTENT(OUT) :: eigenvectors(n, n)
  TYPE(ErrorStatusType), INTENT(OUT) :: status
  ! TODO: Implement Jacobi method
  eigenvalues = [(REAL(i, wp), i=1,n)]  ! Placeholder
  eigenvectors = RESHAPE([(1.0_wp, i=1,n*n)], [n, n])
  status%code = 0
END SUBROUTINE

! Sort eigenvalues
SUBROUTINE PH_Elem_B31_Stab_SortEigenvalues(eigenvalues, eigenvectors, n)
  REAL(wp), INTENT(INOUT) :: eigenvalues(n)
  REAL(wp), INTENT(INOUT) :: eigenvectors(n, n)
  INTEGER(i4), INTENT(IN) :: n
  INTEGER(i4) :: i, j
  REAL(wp) :: temp_val, temp_vec(n)
  
  DO i = 1, n-1
    DO j = i+1, n
      IF (eigenvalues(j) < eigenvalues(i)) THEN
        temp_val = eigenvalues(i)
        eigenvalues(i) = eigenvalues(j)
        eigenvalues(j) = temp_val
        
        temp_vec = eigenvectors(:, i)
        eigenvectors(:, i) = eigenvectors(:, j)
        eigenvectors(:, j) = temp_vec
      END IF
    END DO
  END DO
END SUBROUTINE

! Check pivot sign
SUBROUTINE PH_Elem_B31_Stab_CheckPivotSign(K, prev_sign, curr_sign, neg_detected)
  REAL(wp), INTENT(IN) :: K(:,:)
  INTEGER(i4), INTENT(OUT) :: prev_sign, curr_sign
  LOGICAL, INTENT(OUT) :: neg_detected
  ! TODO: Actual pivot check during factorization
  prev_sign = curr_sign
  neg_detected = .FALSE.
END SUBROUTINE

END MODULE PH_Elem_B31Stability