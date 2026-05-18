!===============================================================================
! MODULE: NM_Solv_TrustRegion
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Proc (trust-region nonlinear solver: dogleg, Cauchy, adaptive radius)
! BRIEF:  Trust-region globalization for F(u)=0 with quadratic model + radius ctrl
!
! Theory: Conn et al.(2000) Trust-Region Methods; dogleg step selection
!
! Status: PROD | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_TrustRegion
!> Status: Production | Last verified: 2026-03-01
!> Theory: Trust region methods | Ref: Conn et al.(2000)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, SMALL_VAL => SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !> @brief  Solver parameters 
  TYPE, PUBLIC :: TrustRegion_Params
    INTEGER(i4) :: max_iterations        !<  iter count
    REAL(DP) :: tol_residual          !<  
    REAL(DP) :: tol_step              !< step 

    REAL(DP) :: delta_init            !< Initialize Δ₀
    REAL(DP) :: delta_max             !<  radius Δ_max
    REAL(DP) :: eta1                  !<  η(  0.25)
    REAL(DP) :: eta2                  !<  η(  0.75)

    LOGICAL  :: verbose               !< whether iteration 
  END TYPE

  !> @brief  iterationstatus
  TYPE, PUBLIC :: TrustRegion_State
    INTEGER(i4) :: n_dof                 !< DOF count
    INTEGER(i4) :: iteration             !<  iter count

    REAL(DP) :: phi                   !<   Φ(u) = 1/2‖F ?
    REAL(DP) :: phi_new               !<  Φ(u+p)
    REAL(DP) :: residual_norm         !<   ‖F
    REAL(DP) :: step_norm             !< current step size  ‖p
    REAL(DP) :: delta                 !<  Δ
    REAL(DP) :: rho                   !<  / 

    LOGICAL  :: converged             !< converged
  END TYPE

  PUBLIC :: NM_TrustRegion_Solv
  
  ! Extended TrustRegion API (scope 1950-1999)
  PUBLIC :: NM_TrustRegion_AdaptiveRadius, NM_TrustRegion_GetStatistics

CONTAINS

  SUBROUTINE Calc_Cauchy_Step(g, B, delta, p_C)
    REAL(DP), INTENT(IN)  :: g(:), B(:,:), delta
    REAL(DP), INTENT(OUT) :: p_C(:)

    REAL(DP), ALLOCATABLE :: Bg(:)
    REAL(DP) :: gBg, alpha_C, g_norm
    INTEGER(i4) :: n

    n = SIZE(g)
    ALLOCATE(Bg(n))

    Bg = MATMUL(B, g)
    gBg = DOT_PRODUCT(g, Bg)
    g_norm = SQRT(DOT_PRODUCT(g, g))

    IF (gBg <= SMALL_VAL) THEN
      ! Hessian    -g  
      p_C = - (delta / (g_norm + SMALL_VAL)) * g
    ELSE
      alpha_C = DOT_PRODUCT(g, g) / gBg
      p_C = - alpha_C * g
      IF (SQRT(DOT_PRODUCT(p_C, p_C)) > delta) THEN
        p_C = - (delta / (g_norm + SMALL_VAL)) * g
      END IF
    END IF

    DEALLOCATE(Bg)

  END SUBROUTINE Calc_Cauchy_Step

  SUBROUTINE Calc_Dogleg_Step(p_C, p_N, delta, p)
    REAL(DP), INTENT(IN)  :: p_C(:), p_N(:), delta
    REAL(DP), INTENT(OUT) :: p(:)

    REAL(DP) :: norm_pN, norm_pC, tau
    REAL(DP), ALLOCATABLE :: p_diff(:)
    INTEGER(i4) :: n

    n = SIZE(p_C)
    ALLOCATE(p_diff(n))

    norm_pN = SQRT(DOT_PRODUCT(p_N, p_N))
    norm_pC = SQRT(DOT_PRODUCT(p_C, p_C))

    IF (norm_pN <= delta) THEN
      p = p_N
    ELSEIF (norm_pC >= delta) THEN
      p = (delta / (norm_pC + SMALL_VAL)) * p_C
    ELSE
      ! p_C p_N   τ, ‖p_C + τ(p_N-p_C)= Δ
      p_diff = p_N - p_C
      CALL Solv_Tau_On_Dogleg(p_C, p_diff, delta, tau)
      p = p_C + tau * p_diff
    END IF

    DEALLOCATE(p_diff)

  END SUBROUTINE Calc_Dogleg_Step

  SUBROUTINE NM_Tr_AdaptiveRadius(params, state, rho, new_radius, status)
    TYPE(TrustRegion_Params), INTENT(IN) :: params
    TYPE(TrustRegion_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(IN) :: rho
    REAL(DP), INTENT(OUT) :: new_radius
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    ! Adaptive radius based on reduction ratio
    IF (rho < params%eta1) THEN
      ! Poor reduction: shrink radius
      new_radius = 0.25_DP * state%delta
    ELSE IF (rho > params%eta2 .AND. state%step_norm > 0.8_DP * state%delta) THEN
      ! Good reduction and step near boundary: expand radius
      new_radius = MIN(TWO * state%delta, params%delta_max)
    ELSE
      ! Moderate reduction: keep current radius
      new_radius = state%delta
    END IF
    
    ! Ensure minimum radius
    new_radius = MAX(new_radius, SMALL_VAL)
    state%delta = new_radius
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_TrustRegion_AdaptiveRadius

  SUBROUTINE NM_TrustRegion_GetStatistics(state, params, stats, status)
    TYPE(TrustRegion_State), INTENT(IN) :: state
    TYPE(TrustRegion_Params), INTENT(IN) :: params
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CALL init_error_status(status)
    
    WRITE(stats, '(A,I0,A,ES10.3,A,ES10.3,A,ES10.3,A,ES10.3,A,L1)') &
      'TrustRegion Statistics: iteration=', state%iteration, &
      ', phi=', state%phi, &
      ', residual_norm=', state%residual_norm, &
      ', step_norm=', state%step_norm, &
      ', delta=', state%delta, &
      ', rho=', state%rho, &
      ', converged=', state%converged
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_TrustRegion_GetStatistics

  SUBROUTINE NM_TrustRegion_Solv(u, Residual_proc, Jacobian_proc, params, state)
    REAL(DP), INTENT(INOUT) :: u(:)
    INTERFACE
      SUBROUTINE Residual_proc(u, F)
        USE IF_Base_Def, ONLY: DP
        REAL(DP), INTENT(IN)  :: u(:)
        REAL(DP), INTENT(OUT) :: F(:)
      END SUBROUTINE Residual_proc
      SUBROUTINE Jacobian_proc(u, J)
        USE IF_Base_Def, ONLY: DP
        REAL(DP), INTENT(IN)  :: u(:)
        REAL(DP), INTENT(OUT) :: J(:,:)
      END SUBROUTINE Jacobian_proc
    END INTERFACE
    TYPE(TrustRegion_Params), INTENT(IN)    :: params
    TYPE(TrustRegion_State),  INTENT(OUT)   :: state

    INTEGER(i4) :: n, k
    REAL(DP), ALLOCATABLE :: F(:), J(:,:), g(:), B(:,:), p(:), p_C(:), p_N(:)
    REAL(DP) :: g_norm, phi, phi_new, ared, pred
    REAL(DP) :: delta, delta_new
    LOGICAL  :: step_accepted

    n = SIZE(u)
    ALLOCATE(F(n), J(n,n), g(n), B(n,n), p(n), p_C(n), p_N(n))

    ! Initialize 
    CALL Residual_proc(u, F)
    phi = 0.5_DP * DOT_PRODUCT(F, F)
    state%residual_norm = SQRT(DOT_PRODUCT(F, F))

    state%pop%n_dof     = n
    state%iteration = 0
    state%delta     = params%delta_init
    state%converged = .FALSE.

    IF (params%verbose) THEN
      WRITE(*,'(A,ES12.4)') 'TR: Initial residual norm = ', state%residual_norm
    END IF

    !  iteration 
    DO k = 1, params%max_iterations
      state%iteration = k
      delta = state%delta

      ! 1. computationJacobian Gauss-Newton Hessian  B = J^T·J
      CALL Jacobian_proc(u, J)
      B = MATMUL(TRANSPOSE(J), J)

      ! gradient g = J^T·F
      g = MATMUL(TRANSPOSE(J), F)
      g_norm = SQRT(DOT_PRODUCT(g, g))

      IF (g_norm < params%tol_residual) THEN
        state%converged = .TRUE.
        EXIT
      END IF

      ! 2.  Cauchy p_C Newton p_N
      CALL Calc_Cauchy_Step(g, B, delta, p_C)
      CALL Solv_SPD_System(B, -g, p_N)  ! Gauss-Newton 

      ! 3. Dogleg  p
      CALL Calc_Dogleg_Step(p_C, p_N, delta, p)
      state%step_norm = SQRT(DOT_PRODUCT(p, p))

      ! 4. computation 
      CALL Residual_proc(u + p, F)
      phi_new = 0.5_DP * DOT_PRODUCT(F, F)

      ared = phi - phi_new
      pred = - (DOT_PRODUCT(g, p) + 0.5_DP * DOT_PRODUCT(p, MATMUL(B, p)))

      IF (pred <= SMALL_VAL) THEN
        state%rho = 0.0_DP
      ELSE
        state%rho = ared / pred
      END IF

      ! 5. step 
      step_accepted = (state%rho > params%eta1)

      IF (step_accepted) THEN
        !  step
        u   = u + p
        phi = phi_new
        state%residual_norm = SQRT(DOT_PRODUCT(F, F))

        !  
        IF (state%rho > params%eta2 .AND. state%step_norm > 0.8_DP * delta) THEN
          delta_new = MIN(TWO * delta, params%delta_max)
        ELSE
          delta_new = delta
        END IF

      ELSE
        !  step,  
        delta_new = 0.25_DP * delta
      END IF

      state%delta = MAX(delta_new, SMALL_VAL)
      state%phi   = phi

      IF (params%verbose) THEN
        WRITE(*,'(A,I4,A,ES10.3,A,ES10.3,A,ES10.3)') 'TR iter ', k, &
          ': ||F||=', state%residual_norm, ', ||p||=', state%step_norm, &
          ', rho=', state%rho
      END IF

      ! convergence 
      IF (state%residual_norm < params%tol_residual .OR. &
          state%step_norm      < params%tol_step) THEN
        state%converged = .TRUE.
        EXIT
      END IF

    END DO

    DEALLOCATE(F, J, g, B, p, p_C, p_N)

  END SUBROUTINE NM_TrustRegion_Solv

  SUBROUTINE Solv_SPD_System(B, rhs, x)
    REAL(DP), INTENT(IN)  :: B(:,:), rhs(:)
    REAL(DP), INTENT(OUT) :: x(:)

    INTEGER(i4) :: n, info
    REAL(DP), ALLOCATABLE :: A(:,:), b(:)
    INTEGER,  ALLOCATABLE :: ipiv(:)

    n = SIZE(rhs)
    ALLOCATE(A(n,n), b(n), ipiv(n))

    A = B
    b = rhs

    CALL DGESV(n, 1, A, n, ipiv, b, n, info)

    IF (info /= 0) THEN
      x = ZERO
    ELSE
      x = b
    END IF

    DEALLOCATE(A, b, ipiv)

  END SUBROUTINE Solv_SPD_System

  SUBROUTINE Solv_Tau_On_Dogleg(p_C, d, delta, tau)
    REAL(DP), INTENT(IN)  :: p_C(:), d(:), delta
    REAL(DP), INTENT(OUT) :: tau

    REAL(DP) :: a, b, c, disc

    a = DOT_PRODUCT(d, d)
    b = TWO * DOT_PRODUCT(p_C, d)
    c = DOT_PRODUCT(p_C, p_C) - delta**2

    disc = b*b - FOUR * a * c
    IF (disc <= ZERO) THEN
      tau = ONE
    ELSE
      tau = (-b + SQRT(disc)) / (TWO * a)
      !   τ (0,1]
      tau = MAX(0.0_DP, MIN(ONE, tau))
    END IF

  END SUBROUTINE Solv_Tau_On_Dogleg
END MODULE NM_Solv_TrustRegion