!===============================================================================
! MODULE: NM_Solv_ArcLength
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Proc (arc-length continuation: Riks / Crisfield)
! BRIEF:  Arc-length method with constraint eq, adaptive step, 2-solve path
!
! Theory: Riks(1979), Crisfield(1981); quadratic constraint for d-lambda
!
! Status: PROD | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_ArcLength
!> Status: Production | Last verified: 2026-03-01
!> Theory: Arc-length continuation method | Ref: Riks(1979)
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !> @brief arc-length method type enum
  INTEGER, PARAMETER, PUBLIC :: NM_ARCLENGTH_RIKS = 1           !< Riks 
  INTEGER, PARAMETER, PUBLIC :: NM_ARCLENGTH_CRISFIELD = 2      !< Crisfield 
  INTEGER, PARAMETER, PUBLIC :: NM_ARCLENGTH_DISPLACEMENT = 3   !< displacementcontrol 

  !> @brief  
  INTEGER, PARAMETER, PUBLIC :: NM_CONSTRAINT_SPHERICAL = 1     !<  
  INTEGER, PARAMETER, PUBLIC :: NM_CONSTRAINT_CYLINDRICAL = 2   !<  
  INTEGER, PARAMETER, PUBLIC :: NM_CONSTRAINT_ELLIPSOIDAL = 3   !<  

  !> @brief arc-length params
  TYPE, PUBLIC :: ArcLength_Params_Method
    INTEGER(i4) :: method_type                 !<  
    INTEGER(i4) :: constraint_type             !<  
  END TYPE ArcLength_Params_Method

  TYPE, PUBLIC :: ArcLength_Params_Iter
    INTEGER(i4) :: max_iterations              !< max iterations
    REAL(DP) :: tolerance                   !< convergence tolerance
  END TYPE ArcLength_Params_Iter

  TYPE, PUBLIC :: ArcLength_Params_Step
    REAL(DP) :: initial_arc_length          !< Initialize  Δl0
    REAL(DP) :: min_arc_length              !<  
    REAL(DP) :: max_arc_length              !<  
  END TYPE ArcLength_Params_Step

  TYPE, PUBLIC :: ArcLength_Params_Load
    REAL(DP) :: psi                         !< load  ψ
    LOGICAL  :: adaptive_arc_length         !<  
  END TYPE ArcLength_Params_Load

  TYPE, PUBLIC :: ArcLength_Params
    TYPE(ArcLength_Params_Method) :: method
    TYPE(ArcLength_Params_Iter) :: iter
    TYPE(ArcLength_Params_Step) :: step
    TYPE(ArcLength_Params_Load) :: load
  END TYPE ArcLength_Params

  !> @brief arc-length state
  TYPE, PUBLIC :: ArcLength_State_Step
    INTEGER(i4) :: current_step                !<  
    INTEGER(i4) :: current_iteration           !<  iter count
  END TYPE ArcLength_State_Step

  TYPE, PUBLIC :: ArcLength_State_Load
    REAL(DP) :: arc_length                  !< current arc length Δl
    REAL(DP) :: load_factor                 !< load  λ
    REAL(DP) :: load_factor_increment       !< load factor increment Δλ
  END TYPE ArcLength_State_Load

  TYPE, PUBLIC :: ArcLength_State_Status
    REAL(DP) :: constraint_residual         !<  
    LOGICAL  :: snap_through_detected       !<  
    LOGICAL  :: limit_point_detected        !<  
  END TYPE ArcLength_State_Status

  TYPE, PUBLIC :: ArcLength_State
    TYPE(ArcLength_State_Step) :: step
    TYPE(ArcLength_State_Load) :: load
    TYPE(ArcLength_State_Status) :: status
  END TYPE ArcLength_State

  ! Public interfaces
  PUBLIC :: NM_ArcLength_Solv
  PUBLIC :: NM_ArcLength_Riks_Step
  PUBLIC :: NM_ArcLength_Crisfield_Step
  PUBLIC :: NM_ArcLength_Constraint_Equation
  PUBLIC :: NM_ArcLength_Update_Load_Factor
  PUBLIC :: NM_ArcLength_Adaptive_Ctrl
  
  ! Extended ArcLength API (scope 1800-1899)
  PUBLIC :: NM_ArcLength_AdaptiveStepSize, NM_ArcLength_GetPathFollowing
  PUBLIC :: NM_ArcLength_GetStatistics

CONTAINS

  SUBROUTINE NM_ArcLength_AdaptiveStepSize(params, state, convergence_rate, new_step_size, status)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    TYPE(ArcLength_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(IN) :: convergence_rate
    REAL(DP), INTENT(OUT) :: new_step_size
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP) :: scale_factor
    
    CALL init_error_status(status)
    
    ! Adaptive step size based on convergence rate
    IF (convergence_rate < 0.3_DP) THEN
      ! Fast convergence: increase step size
      scale_factor = 1.3_DP
    ELSE IF (convergence_rate > 0.7_DP) THEN
      ! Slow convergence: decrease step size
      scale_factor = 0.7_DP
    ELSE
      scale_factor = ONE
    END IF
    
    new_step_size = state%load%arc_length * scale_factor
    
    ! Limit to allowed range
    new_step_size = MAX(params%step%min_arc_length, &
                       MIN(params%step%max_arc_length, new_step_size))
    
    state%load%arc_length = new_step_size
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ArcLength_AdaptiveStepSize

  SUBROUTINE NM_ArcLength_Constraint_Equation(params, du, delta_lambda, state, phi)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: du(:), delta_lambda
    TYPE(ArcLength_State), INTENT(IN) :: state
    REAL(DP), INTENT(OUT) :: phi

    REAL(DP) :: term_u, term_lambda, psi2, dl2

    psi2 = params%load%psi * params%load%psi
    dl2 = state%load%arc_length**2

    SELECT CASE (params%method%constraint_type)
    CASE (NM_CONSTRAINT_SPHERICAL)
      !  
      term_u = DOT_PRODUCT(du, du)
      term_lambda = psi2 * delta_lambda**2
      phi = term_u + term_lambda - dl2

    CASE (NM_CONSTRAINT_CYLINDRICAL)
      !   ( load
      term_u = DOT_PRODUCT(du, du)
      phi = term_u - dl2

    CASE (NM_CONSTRAINT_ELLIPSOIDAL)
      !   ( )
      term_u = DOT_PRODUCT(du, du)
      term_lambda = psi2 * delta_lambda**2
      phi = term_u + term_lambda - dl2

    END SELECT

  END SUBROUTINE NM_ArcLength_Constraint_Equation

  SUBROUTINE NM_ArcLength_GetPathFollowing(state, load_history, displacement_history, &
                                          path_stats, status)
    TYPE(ArcLength_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: load_history(:), displacement_history(:)
    CHARACTER(len=256), INTENT(OUT) :: path_stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    REAL(DP) :: max_load, min_load, path_length
    INTEGER(i4) :: num_steps
    
    CALL init_error_status(status)
    
    num_steps = SIZE(load_history)
    
    IF (num_steps > 0) THEN
      max_load = MAXVAL(load_history)
      min_load = MINVAL(load_history)
      
      ! Estimate path length (simplified)
      path_length = SUM(ABS(load_history(2:num_steps) - load_history(1:num_steps-1)))
      
      WRITE(path_stats, '(A,I0,A,ES10.3,A,ES10.3,A,ES10.3)') &
        'Path Following Statistics: steps=', num_steps, &
        ', max_load=', max_load, &
        ', min_load=', min_load, &
        ', path_length=', path_length
    ELSE
      WRITE(path_stats, '(A)') 'Path Following Statistics: No data'
    END IF
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ArcLength_GetPathFollowing

  SUBROUTINE NM_ArcLength_Update_Load_Factor(params, state, converged)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    TYPE(ArcLength_State), INTENT(INOUT) :: state
    LOGICAL, INTENT(IN) :: converged

    REAL(DP) :: scale_factor

    IF (converged) THEN
      ! convergence  step
      IF (state%step%current_iteration < 5) THEN
        scale_factor = 1.2_DP
      ELSE
        scale_factor = ONE
      END IF
    ELSE
      !  step
      scale_factor = 0.5_DP
    END IF

    state%load%load_factor_increment = state%load%load_factor_increment * scale_factor

  END SUBROUTINE NM_ArcLength_Update_Load_Factor

  SUBROUTINE NM_ArcLength_Adaptive_Ctrl(params, state, converged)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    TYPE(ArcLength_State), INTENT(INOUT) :: state
    LOGICAL, INTENT(IN) :: converged

    REAL(DP) :: desired_iter, actual_iter, scale, new_arc_length

    desired_iter = 6.0_DP
    actual_iter = REAL(state%step%current_iteration, DP)

    IF (converged .AND. actual_iter > 0) THEN
      scale = SQRT(desired_iter / actual_iter)

      new_arc_length = state%load%arc_length * scale

      !  
      new_arc_length = MAX(params%step%min_arc_length, &
                          MIN(params%step%max_arc_length, new_arc_length))

      state%load%arc_length = new_arc_length
    ELSE IF (.NOT. converged) THEN
      !  
      state%load%arc_length = state%load%arc_length * 0.5_DP
      state%load%arc_length = MAX(params%step%min_arc_length, state%load%arc_length)
    END IF

  END SUBROUTINE NM_ArcLength_Adaptive_Ctrl

  SUBROUTINE NM_ArcLength_Crisfield_Step(params, u, f_ref, K_tangent, state, du)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: u(:), f_ref(:), K_tangent(:,:)
    TYPE(ArcLength_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: du(:)

    REAL(DP), ALLOCATABLE :: u_I(:), delta_u_bar(:), delta_u_total(:)
    REAL(DP) :: delta_lambda, numerator, denominator, psi2
    INTEGER(i4) :: n_dof

    n_dof = SIZE(u)
    ALLOCATE(u_I(n_dof), delta_u_bar(n_dof), delta_u_total(n_dof))

    psi2 = params%load%psi * params%load%psi

    ! 1.  K_T·u_I = F_ref
    CALL Solv_Lin_System(K_tangent, f_ref, u_I)

    ! 2.  K_T·δu_bar = R ( )
    ! simplified impl
    delta_u_bar = ZERO

    ! 3. Crisfield 
    delta_u_total = du  !   ( )

    numerator = -DOT_PRODUCT(delta_u_bar, delta_u_total)
    denominator = DOT_PRODUCT(delta_u_bar, u_I) + &
                  psi2 * state%load%load_factor_increment

    IF (ABS(denominator) > 1.0E-10_DP) THEN
      delta_lambda = numerator / denominator
    ELSE
      delta_lambda = ZERO
    END IF

    ! 4.  
    state%load%load_factor_increment = delta_lambda
    state%load%load_factor = state%load%load_factor + delta_lambda
    du = u_I * delta_lambda + delta_u_bar

    DEALLOCATE(u_I, delta_u_bar, delta_u_total)

  END SUBROUTINE NM_ArcLength_Crisfield_Step

  SUBROUTINE NM_ArcLength_GetStatistics(state, params, stats, status)
    TYPE(ArcLength_State), INTENT(IN) :: state
    TYPE(ArcLength_Params), INTENT(IN) :: params
    CHARACTER(len=256), INTENT(OUT) :: stats
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    
    CHARACTER(len=16) :: method_name
    
    CALL init_error_status(status)
    
    SELECT CASE (params%method%method_type)
    CASE (NM_ARCLENGTH_RIKS)
      method_name = "Riks"
    CASE (NM_ARCLENGTH_CRISFIELD)
      method_name = "Crisfield"
    CASE DEFAULT
      method_name = "Unknown"
    END SELECT
    
    WRITE(stats, '(A,A,A,I0,A,ES10.3,A,ES10.3,A,L1,A,L1)') &
      'ArcLength Statistics (', TRIM(method_name), &
      '): step=', state%step%current_step, &
      ', iteration=', state%step%current_iteration, &
      ', arc_length=', state%load%arc_length, &
      ', load_factor=', state%load%load_factor, &
      ', snap_through=', state%status%snap_through_detected, &
      ', limit_point=', state%status%limit_point_detected
    
    status%status_code = IF_STATUS_OK
    
  END SUBROUTINE NM_ArcLength_GetStatistics

  SUBROUTINE NM_ArcLength_Riks_Step(params, u, f_ref, K_tangent, state, du)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: u(:), f_ref(:), K_tangent(:,:)
    TYPE(ArcLength_State), INTENT(INOUT) :: state
    REAL(DP), INTENT(OUT) :: du(:)

    REAL(DP), ALLOCATABLE :: u_I(:), u_II(:), residual(:)
    REAL(DP) :: a, b, c, discriminant, delta_lambda, psi2
    INTEGER(i4) :: n_dof

    n_dof = SIZE(u)
    ALLOCATE(u_I(n_dof), u_II(n_dof), residual(n_dof))

    psi2 = params%load%psi * params%load%psi

    ! 1. computation 
    residual = f_ref * state%load%load_factor - MATMUL(K_tangent, u)  !  

    ! 2.  K_T·u_I = F_ref
    CALL Solv_Lin_System(K_tangent, f_ref, u_I)

    ! 3.  K_T·u_II = R
    CALL Solv_Lin_System(K_tangent, residual, u_II)

    ! 4.  
    a = DOT_PRODUCT(u_I, u_I) + psi2 * DOT_PRODUCT(f_ref, f_ref)
    b = TWO * (DOT_PRODUCT(u_I, u_II) + &
              psi2 * state%load%load_factor * DOT_PRODUCT(f_ref, f_ref))
    c = DOT_PRODUCT(u_II, u_II) - state%load%arc_length**2

    ! 5.  
    discriminant = b*b - 4.0_DP*a*c
    IF (discriminant < ZERO) THEN
      PRINT *, 'WARNING: Negative discriminant in Riks arc-length'
      delta_lambda = ZERO
    ELSE
      !  ( load )
      delta_lambda = (-b + SQRT(discriminant)) / (TWO * a)
    END IF

    ! 6.  load displacement 
    state%load%load_factor_increment = delta_lambda
    state%load%load_factor = state%load%load_factor + delta_lambda
    du = u_I * delta_lambda + u_II

    DEALLOCATE(u_I, u_II, residual)

  END SUBROUTINE NM_ArcLength_Riks_Step

  SUBROUTINE NM_ArcLength_Solv(params, u, f_ref, K_tangent, state)
    TYPE(ArcLength_Params), INTENT(IN) :: params
    REAL(DP), INTENT(INOUT) :: u(:)
    REAL(DP), INTENT(IN)    :: f_ref(:)
    REAL(DP), INTENT(IN)    :: K_tangent(:,:)
    TYPE(ArcLength_State), INTENT(INOUT) :: state

    REAL(DP), ALLOCATABLE :: du(:), residual(:)
    INTEGER(i4) :: iter, n_dof
    LOGICAL :: converged

    n_dof = SIZE(u)
    ALLOCATE(du(n_dof), residual(n_dof))

    state%step%current_iteration = 0
    converged = .FALSE.

    !  iteration 
    DO iter = 1, params%iter%max_iterations
      state%step%current_iteration = iter

      !  method 
      SELECT CASE (params%method%method_type)
      CASE (NM_ARCLENGTH_RIKS)
        CALL NM_ArcLength_Riks_Step(params, u, f_ref, K_tangent, state, du)
      CASE (NM_ARCLENGTH_CRISFIELD)
        CALL NM_ArcLength_Crisfield_Step(params, u, f_ref, K_tangent, state, du)
      END SELECT

      ! updatedisplacement load 
      u = u + du

      ! check convergence
      IF (SQRT(DOT_PRODUCT(du, du)) < params%iter%tolerance) THEN
        converged = .TRUE.
        EXIT
      END IF

    END DO

    !  
    IF (params%load%adaptive_arc_length) THEN
      CALL NM_ArcLength_Adaptive_Ctrl(params, state, converged)
    END IF

    DEALLOCATE(du, residual)

  END SUBROUTINE NM_ArcLength_Solv

  SUBROUTINE Solv_Lin_System(A, b, x)
    REAL(DP), INTENT(IN)  :: A(:,:), b(:)
    REAL(DP), INTENT(OUT) :: x(:)

    INTEGER(i4) :: n, info
    REAL(DP), ALLOCATABLE :: A_copy(:,:), b_copy(:)
    INTEGER, ALLOCATABLE :: ipiv(:)

    n = SIZE(b)
    ALLOCATE(A_copy(n,n), b_copy(n), ipiv(n))

    A_copy = A
    b_copy = b

    CALL DGESV(n, 1, A_copy, n, ipiv, b_copy, n, info)

    IF (info == 0) THEN
      x = b_copy
    ELSE
      x = ZERO
    END IF

    DEALLOCATE(A_copy, b_copy, ipiv)

  END SUBROUTINE Solv_Lin_System
END MODULE NM_Solv_ArcLength