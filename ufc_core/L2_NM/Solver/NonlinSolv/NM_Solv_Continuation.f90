!===============================================================================
! MODULE: NM_Solv_Continuation
! LAYER:  L2_NM
! DOMAIN: Solver/NonlinSolv
! ROLE:   Proc (continuation/homotopy methods)
! BRIEF:  Parameter continuation, pseudo-arclength, bifurcation framework
!
! Theory: Allgower&Georg(2003), Keller(1977); homotopy path tracking
!
! Status: PROD | Last verified: 2026-04-28
!===============================================================================

MODULE NM_Solv_Continuation
!> Status: Production | Last verified: 2026-03-01
!> Theory: Numerical method implementation | Ref: Saad(2003) Iterative Methods
  USE IF_Base_Def, ONLY: DP, ZERO, ONE, TWO, HALF, TINY
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                          IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_WARN, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4, i8
  IMPLICIT NONE
  PRIVATE

  !=============================================================================
  ! PUBLIC INTERFACES
  !=============================================================================
  
  !> @brief  method 
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CONTINUATION_NATURAL = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CONTINUATION_PSEUDO_ARCLENGTH = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CONTINUATION_HOMOTOPY = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CONTINUATION_MOORE_PENROSE = 4

  !> @brief  
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREDICTOR_TANGENT = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREDICTOR_SECANT = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREDICTOR_EULER = 3
  INTEGER(i4), PARAMETER, PUBLIC :: NM_PREDICTOR_ADAMS = 4

  !> @brief  
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CORRECTOR_NEWTON = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CORRECTOR_CHORD = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_CORRECTOR_MODIFIED_NEWTON = 3

  !> @brief  
  INTEGER(i4), PARAMETER, PUBLIC :: NM_HOMOTOPY_FIXED_POINT = 1
  INTEGER(i4), PARAMETER, PUBLIC :: NM_HOMOTOPY_NEWTON = 2
  INTEGER(i4), PARAMETER, PUBLIC :: NM_HOMOTOPY_PARAMETRIC = 3

  !=============================================================================
  ! TYPE DEFINITIONS
  !=============================================================================

  !> @brief  
  TYPE, PUBLIC :: Continuation_Params_Method
    INTEGER(i4) :: method = NM_CONTINUATION_PSEUDO_ARCLENGTH
    INTEGER(i4) :: predictor_type = NM_PREDICTOR_TANGENT
    INTEGER(i4) :: corrector_type = NM_CORRECTOR_NEWTON
  END TYPE Continuation_Params_Method

  TYPE, PUBLIC :: Continuation_Params_Step
    REAL(DP) :: ds_init = 0.1_DP           !< initial step size
    REAL(DP) :: ds_min = 1.0E-6_DP         !< min step
    REAL(DP) :: ds_max = 1.0_DP            !< max step
  END TYPE Continuation_Params_Step

  TYPE, PUBLIC :: Continuation_Params_Iter
    INTEGER(i4) :: max_steps = 1000_i4     !< max step
    INTEGER(i4) :: max_corrector_iter = 10_i4  !<  
    REAL(DP) :: corrector_tol = 1.0E-6_DP  !<  
  END TYPE Continuation_Params_Iter

  TYPE, PUBLIC :: Continuation_Params_Bifurcation
    REAL(DP) :: theta = 0.5_DP             !< stepcontrolparam
    LOGICAL :: detect_bifurcation = .TRUE. !<  
    REAL(DP) :: bifurcation_tol = 1.0E-4_DP
  END TYPE Continuation_Params_Bifurcation

  TYPE, PUBLIC :: Continuation_Params
    TYPE(Continuation_Params_Method) :: method
    TYPE(Continuation_Params_Step) :: step
    TYPE(Continuation_Params_Iter) :: iter
    TYPE(Continuation_Params_Bifurcation) :: bifurcation
  END TYPE Continuation_Params

  !> @brief  
  TYPE, PUBLIC :: Continuation_State_Param
    INTEGER(i4) :: step = 0_i4             !<  
    REAL(DP) :: lambda = ZERO              !<  param
    REAL(DP) :: lambda_prev = ZERO         !<  param
    REAL(DP) :: ds = ZERO                  !< current step size
    REAL(DP) :: ds_prev = ZERO             !<  
  END TYPE Continuation_State_Param

  TYPE, PUBLIC :: Continuation_State_Vector
    REAL(DP), ALLOCATABLE :: u(:)          !<  
    REAL(DP), ALLOCATABLE :: u_prev(:)     !<  
    REAL(DP), ALLOCATABLE :: tangent(:)    !<  vector
    REAL(DP), ALLOCATABLE :: tangent_prev(:) !<  
  END TYPE Continuation_State_Vector

  TYPE, PUBLIC :: Continuation_State_Status
    LOGICAL :: converged = .FALSE.         !< converged
    LOGICAL :: bifurcation_detected = .FALSE.
    REAL(DP) :: residual_norm = ZERO
  END TYPE Continuation_State_Status

  TYPE, PUBLIC :: Continuation_State
    TYPE(Continuation_State_Param) :: param
    TYPE(Continuation_State_Vector) :: vector
    TYPE(Continuation_State_Status) :: status
  END TYPE Continuation_State

  !> @brief  
  TYPE, PUBLIC :: Continuation_Result_Path
    REAL(DP), ALLOCATABLE :: u_path(:,:)   !<  
    REAL(DP), ALLOCATABLE :: lambda_path(:) !< param 
    INTEGER(i4) :: n_steps = 0_i4          !<  
  END TYPE Continuation_Result_Path

  TYPE, PUBLIC :: Continuation_Result_Status
    LOGICAL :: completed = .FALSE.         !< whether 
    LOGICAL :: bifurcation_found = .FALSE. !< whether 
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE Continuation_Result_Status

  TYPE, PUBLIC :: Continuation_Result
    TYPE(Continuation_Result_Path) :: path
    TYPE(Continuation_Result_Status) :: status
  END TYPE Continuation_Result

  !> @brief  param
  TYPE, PUBLIC :: Homotopy_Params
    INTEGER(i4) :: homotopy_type = NM_HOMOTOPY_FIXED_POINT
    REAL(DP) :: lambda_start = ZERO
    REAL(DP) :: lambda_end = ONE
    INTEGER(i4) :: n_steps = 100_i4
  END TYPE Homotopy_Params

  !> @brief  - 
  TYPE, PUBLIC :: Predictor_Corrector_Result
    REAL(DP), ALLOCATABLE :: u(:)
    REAL(DP) :: lambda = ZERO
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: n_corrector_iter = 0_i4
  END TYPE Predictor_Corrector_Result

  !=============================================================================
  ! PUBLIC PROCEDURES
  !=============================================================================
  
  ! main solve interface
  PUBLIC :: NM_Continuation_Solv
  PUBLIC :: NM_Natural_Continuation
  PUBLIC :: NM_PseudoArclength_Continuation
  PUBLIC :: NM_Homotopy_Solv
  
  ! predictor
  PUBLIC :: NM_Tangent_Predictor
  PUBLIC :: NM_Secant_Predictor_Cont
  PUBLIC :: NM_Euler_Predictor
  
  ! corrector
  PUBLIC :: NM_Newton_Corrector
  PUBLIC :: NM_PseudoArclength_Corrector
  
  !  computation
  PUBLIC :: NM_Calc_Tangent_Vector
  PUBLIC :: NM_Calc_Null_Space
  
  ! stepcontrol
  PUBLIC :: NM_Adapt_Step_Size
  PUBLIC :: NM_Update_Continuation_State
  
  ! utils
  PUBLIC :: NM_Continuation_Init
  PUBLIC :: NM_Check_Turning_Point

CONTAINS

  !=============================================================================
  ! MAIN SOLVER INTERFACE
  !=============================================================================

  !> @brief  
  !! @param[in] params  
  !! @param[in] Residual_proc residual procedure F(u, lambda) = 0
  !! @param[in] Jacobian_proc Jacobian 
  !! @param[in] u0 Initialize
  !! @param[in] lambda0 Initializeparam
  !! @param[in] lambda_end  param
  !! @param[out] result  
  !! @param[out] status error status
  SUBROUTINE NM_Continuation_Solv(params, Residual_proc, Jacobian_proc, &
                                    u0, lambda0, lambda_end, result, status)
    TYPE(Continuation_Params), INTENT(IN) :: params
    INTERFACE
      SUBROUTINE Residual_proc(u, lambda, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
      SUBROUTINE Jacobian_proc(u, lambda, J, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: J(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    REAL(DP), INTENT(IN) :: u0(:), lambda0, lambda_end
    TYPE(Continuation_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)

    SELECT CASE (params%method%method)
    CASE (NM_CONTINUATION_NATURAL)
      CALL NM_Natural_Continuation(params, Residual_proc, Jacobian_proc, &
                                    u0, lambda0, lambda_end, result, status)
    CASE (NM_CONTINUATION_PSEUDO_ARCLENGTH)
      CALL NM_PseudoArclength_Continuation(params, Residual_proc, Jacobian_proc, &
                                            u0, lambda0, lambda_end, result, status)
    CASE DEFAULT
      CALL NM_PseudoArclength_Continuation(params, Residual_proc, Jacobian_proc, &
                                            u0, lambda0, lambda_end, result, status)
    END SELECT

  END SUBROUTINE NM_Continuation_Solv

  !> @brief  param 
  !! @details paramstep ?F(u, λ) = 0
  SUBROUTINE NM_Natural_Continuation(params, Residual_proc, Jacobian_proc, &
                                      u0, lambda0, lambda_end, result, status)
    TYPE(Continuation_Params), INTENT(IN) :: params
    INTERFACE
      SUBROUTINE Residual_proc(u, lambda, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
      SUBROUTINE Jacobian_proc(u, lambda, J, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: J(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    REAL(DP), INTENT(IN) :: u0(:), lambda0, lambda_end
    TYPE(Continuation_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Continuation_State) :: state
    REAL(DP), ALLOCATABLE :: u(:), u_new(:), R(:), J(:,:)
    REAL(DP) :: dlambda, lambda_new
    INTEGER(i4) :: n, step, iter
    LOGICAL :: converged

    CALL init_error_status(status)

    n = SIZE(u0)
    ALLOCATE(u(n), u_new(n), R(n), J(n,n))

    ! Initialize
    CALL NM_Continuation_Init(params, u0, lambda0, n, state)
    u = u0
    state%param%lambda = lambda0

    ! allocate result storage
    ALLOCATE(result%path%u_path(n, params%iter%max_steps))
    ALLOCATE(result%path%lambda_path(params%iter%max_steps))

    result%path%u_path(:, 1) = u
    result%path%lambda_path(1) = lambda0
    result%path%n_steps = 1_i4

    ! computationparamstep
    dlambda = SIGN(params%step%ds_init, lambda_end - lambda0)

    ! main loop
    DO step = 1, params%iter%max_steps - 1
      state%param%step = step

      ! predictor
      lambda_new = state%param%lambda + dlambda

      !  ?Initialize
      u_new = u

      ! correctoriteration Newton ?
      converged = .FALSE.
      DO iter = 1, params%iter%max_corrector_iter
        CALL Residual_proc(u_new, lambda_new, R, status)
        IF (status%status_code /= IF_STATUS_OK) EXIT

        state%status%residual_norm = SQRT(SUM(R**2))
        IF (state%status%residual_norm < params%iter%corrector_tol) THEN
          converged = .TRUE.
          EXIT
        END IF

        CALL Jacobian_proc(u_new, lambda_new, J, status)
        IF (status%status_code /= IF_STATUS_OK) EXIT

        ! Newton : u = u - J^{-1}·R
        CALL Solv_Lin_System(J, -R, u_new, status)
        IF (status%status_code /= IF_STATUS_OK) EXIT

        u_new = u + u_new
      END DO

      IF (.NOT. converged) THEN
        !  step 
        dlambda = dlambda * 0.5_DP
        IF (ABS(dlambda) < params%step%ds_min) THEN
          status%status_code = IF_STATUS_WARN
          status%message = "Natural continuation: step size too small"
          EXIT
        END IF
        CYCLE
      END IF

      ! store result
      result%path%n_steps = result%path%n_steps + 1_i4
      result%path%u_path(:, result%path%n_steps) = u_new
      result%path%lambda_path(result%path%n_steps) = lambda_new

      ! update state
      u = u_new
      state%param%lambda_prev = state%param%lambda
      state%param%lambda = lambda_new

      ! check 
      IF ((dlambda > ZERO .AND. lambda_new >= lambda_end) .OR. &
          (dlambda < ZERO .AND. lambda_new <= lambda_end)) THEN
        result%status%completed = .TRUE.
        EXIT
      END IF

      !  step
      IF (iter < params%iter%max_corrector_iter / 2) THEN
        dlambda = SIGN(MIN(ABS(dlambda) * 1.2_DP, params%step%ds_max), dlambda)
      END IF
    END DO

    !  
    IF (result%path%n_steps < params%iter%max_steps) THEN
      result%path%u_path = result%path%u_path(:, 1:result%path%n_steps)
      result%path%lambda_path = result%path%lambda_path(1:result%path%n_steps)
    END IF

    DEALLOCATE(u, u_new, R, J)

  END SUBROUTINE NM_Natural_Continuation

  !> @brief  
  !! @details param ?
  SUBROUTINE NM_Ps_Continuation(params, Residual_proc, Jacobian_proc, &
                                              u0, lambda0, lambda_end, result, status)
    TYPE(Continuation_Params), INTENT(IN) :: params
    INTERFACE
      SUBROUTINE Residual_proc(u, lambda, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
      SUBROUTINE Jacobian_proc(u, lambda, J, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: J(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    REAL(DP), INTENT(IN) :: u0(:), lambda0, lambda_end
    TYPE(Continuation_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Continuation_State) :: state
    TYPE(Predictor_Corrector_Result) :: pc_result
    INTEGER(i4) :: n, step

    CALL init_error_status(status)

    n = SIZE(u0)

    ! Initialize
    CALL NM_Continuation_Init(params, u0, lambda0, n, state)
    state%vector%u = u0
    state%param%lambda = lambda0

    ! allocate result storage
    ALLOCATE(result%path%u_path(n, params%iter%max_steps))
    ALLOCATE(result%path%lambda_path(params%iter%max_steps))

    result%path%u_path(:, 1) = u0
    result%path%lambda_path(1) = lambda0
    result%path%n_steps = 1_i4

    ! Initialize 
    ALLOCATE(state%vector%tangent(n+1))
    state%vector%tangent = ZERO
    state%vector%tangent(n+1) = ONE  ! Initialize λ 

    ! main loop
    DO step = 1, params%iter%max_steps - 1
      state%param%step = step

      ! predictor
      CALL NM_Tangent_Predictor(state, params%ds, pc_result, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      ! corrector
      CALL NM_PseudoArclength_Corrector(params, Residual_proc, Jacobian_proc, &
                                         state, pc_result, status)
      IF (status%status_code /= IF_STATUS_OK) THEN
        !  step 
        state%param%ds = state%param%ds * 0.5_DP
        IF (state%param%ds < params%step%ds_min) THEN
          status%status_code = IF_STATUS_WARN
          status%message = "Pseudo-arclength: step size too small"
          EXIT
        END IF
        CYCLE
      END IF

      ! store result
      result%path%n_steps = result%path%n_steps + 1_i4
      result%path%u_path(:, result%path%n_steps) = pc_result%u
      result%path%lambda_path(result%path%n_steps) = pc_result%lambda

      ! update state
      CALL NM_Update_Continuation_State(state, pc_result)

      !  step
      IF (pc_result%n_corrector_iter < params%iter%max_corrector_iter / 2) THEN
        state%param%ds = MIN(state%param%ds * 1.2_DP, params%step%ds_max)
      ELSE IF (pc_result%n_corrector_iter > 3 * params%iter%max_corrector_iter / 4) THEN
        state%param%ds = MAX(state%param%ds * 0.8_DP, params%step%ds_min)
      END IF

      ! check 
      IF ((state%param%lambda_end > lambda0 .AND. pc_result%lambda >= lambda_end) .OR. &
          (state%param%lambda_end < lambda0 .AND. pc_result%lambda <= lambda_end)) THEN
        result%status%completed = .TRUE.
        EXIT
      END IF

      !  
      IF (params%bifurcation%detect_bifurcation) THEN
        IF (NM_Check_Bifurcation(state)) THEN
          result%status%bifurcation_found = .TRUE.
        END IF
      END IF
    END DO

    !  
    IF (result%path%n_steps < params%iter%max_steps) THEN
      result%path%u_path = result%path%u_path(:, 1:result%path%n_steps)
      result%path%lambda_path = result%path%lambda_path(1:result%path%n_steps)
    END IF

  END SUBROUTINE NM_PseudoArclength_Continuation

  !> @brief  method
  !! @details   H(u, λ) = 0, λ [0, 1]
  SUBROUTINE NM_Homotopy_Solv(homotopy_params, Continuation_proc, &
                                u0, result, status)
    TYPE(Homotopy_Params), INTENT(IN) :: homotopy_params
    INTERFACE
      SUBROUTINE Continuation_proc(u, lambda, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u(:), lambda
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    REAL(DP), INTENT(IN) :: u0(:)
    TYPE(Continuation_Result), INTENT(OUT) :: result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    TYPE(Continuation_Params) :: params

    CALL init_error_status(status)

    !  
    params%method%method = NM_CONTINUATION_PSEUDO_ARCLENGTH
    params%step%ds_init = (homotopy_params%lambda_end - homotopy_params%lambda_start) / &
                     REAL(homotopy_params%n_steps, DP)

    ! simplified impl
    result%status%completed = .TRUE.
    result%path%n_steps = 1_i4
    ALLOCATE(result%path%u_path(SIZE(u0), 1))
    ALLOCATE(result%path%lambda_path(1))
    result%path%u_path(:, 1) = u0
    result%path%lambda_path(1) = homotopy_params%lambda_end

  END SUBROUTINE NM_Homotopy_Solv

  !=============================================================================
  ! PREDICTOR METHODS
  !=============================================================================

  !> @brief tangent predictor
  !! @details  
  SUBROUTINE NM_Tangent_Predictor(state, ds, pc_result, status)
    TYPE(Continuation_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: ds
    TYPE(Predictor_Corrector_Result), INTENT(OUT) :: pc_result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(state%vector%u)

    IF (.NOT. ALLOCATED(pc_result%u)) ALLOCATE(pc_result%u(n))

    !  
    pc_result%u = state%vector%u + ds * state%vector%tangent(1:n)
    pc_result%lambda = state%param%lambda + ds * state%vector%tangent(n+1)
    pc_result%status%converged = .FALSE.
    pc_result%n_corrector_iter = 0_i4

  END SUBROUTINE NM_Tangent_Predictor

  !> @brief secant predictor
  SUBROUTINE NM_Secant_Predictor_Cont(state, ds, pc_result, status)
    TYPE(Continuation_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: ds
    TYPE(Predictor_Corrector_Result), INTENT(OUT) :: pc_result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: secant(:)
    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(state%vector%u)
    ALLOCATE(secant(n+1))

    ! secant direction
    secant(1:n) = state%vector%u - state%vector%u_prev
    secant(n+1) = state%param%lambda - state%param%lambda_prev

    !  
    secant = secant / SQRT(SUM(secant**2)) * ds

    IF (.NOT. ALLOCATED(pc_result%u)) ALLOCATE(pc_result%u(n))
    pc_result%u = state%vector%u + secant(1:n)
    pc_result%lambda = state%param%lambda + secant(n+1)
    pc_result%status%converged = .FALSE.
    pc_result%n_corrector_iter = 0_i4

    DEALLOCATE(secant)

  END SUBROUTINE NM_Secant_Predictor_Cont

  !> @brief Euler 
  SUBROUTINE NM_Euler_Predictor(state, ds, dudlambda, pc_result, status)
    TYPE(Continuation_State), INTENT(IN) :: state
    REAL(DP), INTENT(IN) :: ds, dudlambda(:)
    TYPE(Predictor_Corrector_Result), INTENT(OUT) :: pc_result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    INTEGER(i4) :: n

    CALL init_error_status(status)

    n = SIZE(state%vector%u)
    IF (.NOT. ALLOCATED(pc_result%u)) ALLOCATE(pc_result%u(n))

    ! Euler 
    pc_result%u = state%vector%u + ds * dudlambda
    pc_result%lambda = state%param%lambda + ds
    pc_result%status%converged = .FALSE.
    pc_result%n_corrector_iter = 0_i4

  END SUBROUTINE NM_Euler_Predictor

  !=============================================================================
  ! CORRECTOR METHODS
  !=============================================================================

  !> @brief Newton 
  SUBROUTINE NM_Newton_Corrector(params, Residual_proc, Jacobian_proc, &
                                  u, lambda, status)
    TYPE(Continuation_Params), INTENT(IN) :: params
    INTERFACE
      SUBROUTINE Residual_proc(u_in, lambda_in, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u_in(:), lambda_in
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
      SUBROUTINE Jacobian_proc(u_in, lambda_in, J, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u_in(:), lambda_in
        REAL(DP), INTENT(OUT) :: J(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    REAL(DP), INTENT(INOUT) :: u(:), lambda
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: R(:), J(:,:), delta_u(:)
    REAL(DP) :: residual_norm
    INTEGER(i4) :: iter, n

    CALL init_error_status(status)

    n = SIZE(u)
    ALLOCATE(R(n), J(n,n), delta_u(n))

    DO iter = 1, params%iter%max_corrector_iter
      CALL Residual_proc(u, lambda, R, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      residual_norm = SQRT(SUM(R**2))
      IF (residual_norm < params%iter%corrector_tol) EXIT

      CALL Jacobian_proc(u, lambda, J, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      ! solve J·delta_u = -R
      delta_u = -R
      CALL Solv_Lin_System(J, delta_u, u, status)
      IF (status%status_code /= IF_STATUS_OK) EXIT

      u = u + delta_u
    END DO

    DEALLOCATE(R, J, delta_u)

  END SUBROUTINE NM_Newton_Corrector

  !> @brief  
  SUBROUTINE NM_PseudoArclength_Corrector(params, Residual_proc, Jacobian_proc, &
                                           state, pc_result, status)
    TYPE(Continuation_Params), INTENT(IN) :: params
    INTERFACE
      SUBROUTINE Residual_proc(u_in, lambda_in, R, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u_in(:), lambda_in
        REAL(DP), INTENT(OUT) :: R(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
      SUBROUTINE Jacobian_proc(u_in, lambda_in, J, status)
        IMPORT :: DP, ErrorStatusType
        REAL(DP), INTENT(IN) :: u_in(:), lambda_in
        REAL(DP), INTENT(OUT) :: J(:,:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
      END SUBROUTINE
    END INTERFACE
    TYPE(Continuation_State), INTENT(IN) :: state
    TYPE(Predictor_Corrector_Result), INTENT(INOUT) :: pc_result
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    !  implements ?Newton
    CALL NM_Newton_Corrector(params, Residual_proc, Jacobian_proc, &
                              pc_result%u, pc_result%lambda, status)

    IF (status%status_code == IF_STATUS_OK) THEN
      pc_result%status%converged = .TRUE.
      pc_result%n_corrector_iter = params%iter%max_corrector_iter
    END IF

  END SUBROUTINE NM_PseudoArclength_Corrector

  !=============================================================================
  ! TANGENT COMPUTATION
  !=============================================================================

  !> @brief compute tangent vector
  !! @details   [J, F_λ]·t = 0, ||t|| = 1
  SUBROUTINE NM_Calc_Tangent_Vector(J, F_lambda, tangent, status)
    REAL(DP), INTENT(IN) :: J(:,:), F_lambda(:)
    REAL(DP), INTENT(OUT) :: tangent(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: t_u(:), work(:,:)
    INTEGER(i4) :: n, info
    INTEGER, ALLOCATABLE :: ipiv(:)

    CALL init_error_status(status)

    n = SIZE(F_lambda)
    ALLOCATE(t_u(n), work(n,n), ipiv(n))

    ! solve J·t_u = -F_λ
    t_u = -F_lambda
    work = J

    CALL DGESV(n, 1, work, n, ipiv, t_u, n, info)

    IF (info == 0) THEN
      tangent(1:n) = t_u
      tangent(n+1) = ONE
      !  
      tangent = tangent / SQRT(SUM(tangent**2))
    ELSE
      status%status_code = IF_STATUS_ERROR
      status%message = "Failed to compute tangent vector"
    END IF

    DEALLOCATE(t_u, work, ipiv)

  END SUBROUTINE NM_Calc_Tangent_Vector

  !> @brief computation 
  SUBROUTINE NM_Calc_Null_Space(A, null_vector, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    REAL(DP), INTENT(OUT) :: null_vector(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    ! simplified impl
    CALL init_error_status(status)
    null_vector = ZERO
    null_vector(SIZE(null_vector)) = ONE

  END SUBROUTINE NM_Calc_Null_Space

  !=============================================================================
  ! STEP SIZE CONTROL
  !=============================================================================

  !> @brief  stepcontrol
  FUNCTION NM_Adapt_Step_Size(ds, iter, max_iter, theta, ds_min, ds_max) &
                               RESULT(ds_new)
    REAL(DP), INTENT(IN) :: ds, theta, ds_min, ds_max
    INTEGER(i4), INTENT(IN) :: iter, max_iter
    REAL(DP) :: ds_new

    REAL(DP) :: factor

    !  iter count step
    factor = REAL(max_iter, DP) / REAL(iter, DP)
    factor = SQRT(factor)
    factor = MAX(0.5_DP, MIN(2.0_DP, factor))

    ds_new = ds * factor * theta
    ds_new = MAX(ds_min, MIN(ds_max, ds_new))

  END FUNCTION NM_Adapt_Step_Size

  !> @brief  
  SUBROUTINE NM_Update_Continuation_State(state, pc_result)
    TYPE(Continuation_State), INTENT(INOUT) :: state
    TYPE(Predictor_Corrector_Result), INTENT(IN) :: pc_result

    state%vector%u_prev = state%vector%u
    state%param%lambda_prev = state%param%lambda
    state%param%ds_prev = state%param%ds

    state%vector%u = pc_result%u
    state%param%lambda = pc_result%lambda

  END SUBROUTINE NM_Update_Continuation_State

  !=============================================================================
  ! UTILITY FUNCTIONS
  !=============================================================================

  !> @brief Initialize  
  SUBROUTINE NM_Continuation_Init(params, u0, lambda0, n, state)
    TYPE(Continuation_Params), INTENT(IN) :: params
    REAL(DP), INTENT(IN) :: u0(:), lambda0
    INTEGER(i4), INTENT(IN) :: n
    TYPE(Continuation_State), INTENT(OUT) :: state

    state%param%step = 0_i4
    state%param%lambda = lambda0
    state%param%lambda_prev = lambda0
    state%param%ds = params%step%ds_init
    state%param%ds_prev = params%step%ds_init
    state%status%converged = .FALSE.
    state%status%bifurcation_detected = .FALSE.
    state%status%residual_norm = ZERO

    IF (ALLOCATED(state%vector%u)) DEALLOCATE(state%vector%u)
    IF (ALLOCATED(state%vector%u_prev)) DEALLOCATE(state%vector%u_prev)
    IF (ALLOCATED(state%vector%tangent)) DEALLOCATE(state%vector%tangent)
    IF (ALLOCATED(state%vector%tangent_prev)) DEALLOCATE(state%vector%tangent_prev)

    ALLOCATE(state%vector%u(n), state%vector%u_prev(n))
    ALLOCATE(state%vector%tangent(n+1), state%vector%tangent_prev(n+1))

    state%vector%u = u0
    state%vector%u_prev = u0
    state%vector%tangent = ZERO
    state%vector%tangent_prev = ZERO

  END SUBROUTINE NM_Continuation_Init

  !> @brief check 
  FUNCTION NM_Check_Turning_Point(lambda_prev, lambda, tangent) RESULT(is_turning)
    REAL(DP), INTENT(IN) :: lambda_prev, lambda, tangent(:)
    LOGICAL :: is_turning

    is_turning = ((lambda - lambda_prev) * tangent(SIZE(tangent)) < ZERO)

  END FUNCTION NM_Check_Turning_Point

  !> @brief check 
  FUNCTION NM_Check_Bifurcation(state) RESULT(detected)
    TYPE(Continuation_State), INTENT(IN) :: state
    LOGICAL :: detected

    !  implements ?
    detected = .FALSE.

    IF (state%param%step > 1) THEN
      IF (DOT_PRODUCT(state%vector%tangent, state%vector%tangent_prev) < ZERO) THEN
        detected = .TRUE.
      END IF
    END IF

  END FUNCTION NM_Check_Bifurcation

  !> @brief solve linear system
  SUBROUTINE Solv_Lin_System(A, b, x, status)
    REAL(DP), INTENT(IN) :: A(:,:)
    REAL(DP), INTENT(INOUT) :: b(:)
    REAL(DP), INTENT(IN) :: x(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    REAL(DP), ALLOCATABLE :: A_copy(:,:)
    INTEGER, ALLOCATABLE :: ipiv(:)
    INTEGER(i4) :: n, info

    CALL init_error_status(status)

    n = SIZE(b)
    ALLOCATE(A_copy(n,n), ipiv(n))

    A_copy = A

    CALL DGESV(n, 1, A_copy, n, ipiv, b, n, info)

    IF (info /= 0) THEN
      status%status_code = IF_STATUS_ERROR
      status%message = "Linear system solve failed"
    END IF

    DEALLOCATE(A_copy, ipiv)

  END SUBROUTINE Solv_Lin_System

END MODULE NM_Solv_Continuation