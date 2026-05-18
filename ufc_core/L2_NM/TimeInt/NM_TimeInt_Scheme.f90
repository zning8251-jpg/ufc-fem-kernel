!===============================================================================
! MODULE: NM_TimeInt_Scheme
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Impl — Newmark/HHT-alpha/Generalized-alpha scheme implementations
! BRIEF:  Time integration algorithm dispatch: init, step, state management
!===============================================================================
MODULE NM_TimeInt_Scheme
!> [CORE] Numerical Methods Layer Time Integration Algorithms
!> Theory: Newmark, HHT-alpha, Generalized-alpha methods
!> References:
!>   - Newmark, N.M. (1959). "A method of computation for structural dynamics"
!>   - Hilber, H.M., Hughes, T.J.R., Taylor, R.L. (1977). "Improved numerical dissipation"
!>   - Chung, J., Hulbert, G.M. (1993). "A time integration algorithm for structural dynamics"
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, HALF, QUARTER
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4

  IMPLICIT NONE
  PRIVATE

  ! ==========================================================================
  ! PUBLIC SUBROUTINES (Four-Segment Naming: Layer_Domain_Function_Action)
  ! ==========================================================================
  PUBLIC :: NM_TimeInt_Newmark_Init
  PUBLIC :: NM_TimeInt_Newmark_Step
  PUBLIC :: NM_TimeInt_HHTAlpha_Init
  PUBLIC :: NM_TimeInt_HHTAlpha_Step
  PUBLIC :: NM_TimeInt_GeneralizedAlpha_Init
  PUBLIC :: NM_TimeInt_GeneralizedAlpha_Step

  ! ==========================================================================
  ! PUBLIC FUNCTIONS
  ! ==========================================================================
  PUBLIC :: NM_TimeInt_GetAlpha
  PUBLIC :: NM_TimeInt_GetBeta
  PUBLIC :: NM_TimeInt_GetGamma
  
  !=============================================================================
  ! TIME INTEGRATION CONTROL TYPE (must precede Init_In/Out types that use it)
  !=============================================================================
  TYPE, PUBLIC :: NM_TimeInt_Ctrl_Ctx
      INTEGER(i4) :: method = 1
      REAL(wp) :: dt = 0.0_wp
      REAL(wp) :: t_current = 0.0_wp
      REAL(wp) :: t_final = 1.0_wp
      REAL(wp) :: newmark_beta = 0.25_wp
      REAL(wp) :: newmark_gamma = 0.5_wp
      REAL(wp) :: hht_alpha = 0.0_wp
      REAL(wp) :: gen_alpha_m = 0.0_wp
      REAL(wp) :: gen_alpha_f = 0.0_wp
      LOGICAL :: use_numerical_dissipation = .FALSE.
      REAL(wp) :: spectral_radius = 1.0_wp
      INTEGER(i4) :: max_iterations = 100
      REAL(wp) :: tolerance = 1.0e-6_wp
      LOGICAL :: is_initialized = .FALSE.
      LOGICAL :: use_adaptive_dt = .FALSE.
      REAL(wp) :: dt_min = 1.0e-10_wp
      REAL(wp) :: dt_max = 1.0_wp
  CONTAINS
      PROCEDURE, PUBLIC :: Init => NM_TimeInt_Ctrl_Init
      PROCEDURE, PUBLIC :: Cleanup => NM_TimeInt_Ctrl_Cleanup
      PROCEDURE, PUBLIC :: SetMethod => NM_TimeInt_Ctrl_SetMethod
      PROCEDURE, PUBLIC :: SetTimeStep => NM_TimeInt_Ctrl_SetTimeStep
  END TYPE NM_TimeInt_Ctrl_Ctx

  !=============================================================================
  ! TIME INTEGRATION STATE TYPE (must precede Init_In/Out types that use it)
  !=============================================================================
  TYPE, PUBLIC :: NM_TimeInt_State
      REAL(wp), ALLOCATABLE :: u(:)
      REAL(wp), ALLOCATABLE :: v(:)
      REAL(wp), ALLOCATABLE :: a(:)
      REAL(wp), ALLOCATABLE :: u_prev(:)
      REAL(wp), ALLOCATABLE :: v_prev(:)
      REAL(wp), ALLOCATABLE :: a_prev(:)
      REAL(wp), ALLOCATABLE :: u_intermediate(:)
      REAL(wp), ALLOCATABLE :: v_intermediate(:)
      REAL(wp), ALLOCATABLE :: a_intermediate(:)
      REAL(wp) :: t_current = 0.0_wp
      REAL(wp) :: dt = 0.0_wp
      INTEGER(i4) :: step_count = 0
      LOGICAL :: converged = .FALSE.
      INTEGER(i4) :: iteration_count = 0
      REAL(wp) :: residual_norm = 0.0_wp
      LOGICAL :: is_initialized = .FALSE.
  CONTAINS
      PROCEDURE, PUBLIC :: Init => NM_TimeInt_State_Init
      PROCEDURE, PUBLIC :: Cleanup => NM_TimeInt_State_Cleanup
      PROCEDURE, PUBLIC :: Update => NM_TimeInt_State_Update
      PROCEDURE, PUBLIC :: SavePrevious => NM_TimeInt_State_SavePrevious
  END TYPE NM_TimeInt_State
  
  ! ==========================================================================
  ! INPUT/OUTPUT STRUCTURES FOR STRUCTURED INTERFACES
  ! ==========================================================================
  
  !> @brief Input structure for Newmark initialization
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_Newmark_Init_In
  
  !> @brief Output structure for Newmark initialization
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_Newmark_Init_Out
  
  !> @brief Input structure for Newmark step
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_Newmark_Step_In
  
  !> @brief Output structure for Newmark step
  TYPE, PUBLIC :: NM_TimeInt_Newmark_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_Newmark_Step_Out
  
  !> @brief Input structure for HHT-alpha initialization
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_HHTAlpha_Init_In
  
  !> @brief Output structure for HHT-alpha initialization
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_HHTAlpha_Init_Out
  
  !> @brief Input structure for HHT-alpha step
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_HHTAlpha_Step_In
  
  !> @brief Output structure for HHT-alpha step
  TYPE, PUBLIC :: NM_TimeInt_HHTAlpha_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_HHTAlpha_Step_Out
  
  !> @brief Input structure for Generalized-alpha initialization
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Init_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: u0(:)
    REAL(wp), ALLOCATABLE :: v0(:)
    REAL(wp), ALLOCATABLE :: a0(:)
  END TYPE NM_TimeInt_GeneralizedAlpha_Init_In
  
  !> @brief Output structure for Generalized-alpha initialization
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Init_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_GeneralizedAlpha_Init_Out
  
  !> @brief Input structure for Generalized-alpha step
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Step_In
    TYPE(NM_TimeInt_Ctrl_Ctx) :: ctrl
    TYPE(NM_TimeInt_State) :: state
    REAL(wp), ALLOCATABLE :: a_new(:)
  END TYPE NM_TimeInt_GeneralizedAlpha_Step_In
  
  !> @brief Output structure for Generalized-alpha step
  TYPE, PUBLIC :: NM_TimeInt_GeneralizedAlpha_Step_Out
    TYPE(NM_TimeInt_State) :: state
    TYPE(ErrorStatusType) :: status
  END TYPE NM_TimeInt_GeneralizedAlpha_Step_Out

CONTAINS

  !=============================================================================
  ! NM_TimeInt_Ctrl_Type METHODS
  !=============================================================================

  SUBROUTINE NM_TimeInt_Ctrl_Init(this, method, dt, t_final, status)
      CLASS(NM_TimeInt_Ctrl_Ctx), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: method
      REAL(wp), INTENT(IN) :: dt
      REAL(wp), INTENT(IN) :: t_final
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

      IF (PRESENT(status)) CALL init_error_status(status)

      ! Reset
      this%is_initialized = .FALSE.

      ! Validate inputs
      IF (dt <= ZERO) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_Ctrl_Init: dt must be positive'
          END IF
          RETURN
      END IF

      IF (t_final <= ZERO) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_Ctrl_Init: t_final must be positive'
          END IF
          RETURN
      END IF

      ! Set basic parameters
      this%method = method
      this%dt = dt
      this%t_final = t_final
      this%t_current = ZERO

      ! Set method-specific parameters
      SELECT CASE (method)
      CASE (1)  ! Newmark
          this%newmark_beta = QUARTER
          this%newmark_gamma = HALF
      CASE (2)  ! HHT-alpha
          this%hht_alpha = -0.05_wp  ! Default: small numerical dissipation
      CASE (3)  ! Generalized-alpha
          this%spectral_radius = 0.5_wp  ! Default: moderate high-frequency dissipation
          CALL NM_TimeInt_GetAlpha(this%spectral_radius, this%gen_alpha_m, &
                                   this%gen_alpha_f, this%newmark_beta, this%newmark_gamma)
      CASE DEFAULT
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_Ctrl_Init: Unknown method (1=Newmark, 2=HHT, 3=Gen-alpha)'
          END IF
          RETURN
      END SELECT

      this%is_initialized = .TRUE.

      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Ctrl_Init

  SUBROUTINE NM_TimeInt_Ctrl_Cleanup(this)
      CLASS(NM_TimeInt_Ctrl_Ctx), INTENT(INOUT) :: this

      this%is_initialized = .FALSE.
      this%t_current = ZERO
      this%step_count = 0
  END SUBROUTINE NM_TimeInt_Ctrl_Cleanup

  SUBROUTINE NM_TimeInt_Ctrl_SetMethod(this, method, status)
      CLASS(NM_TimeInt_Ctrl_Ctx), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: method
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

      IF (PRESENT(status)) CALL init_error_status(status)

      this%method = method

      SELECT CASE (method)
      CASE (1)  ! Newmark
          this%newmark_beta = QUARTER
          this%newmark_gamma = HALF
      CASE (2)  ! HHT-alpha
          this%hht_alpha = -0.05_wp
      CASE (3)  ! Generalized-alpha
          this%spectral_radius = 0.5_wp
          CALL NM_TimeInt_GetAlpha(this%spectral_radius, this%gen_alpha_m, &
                                   this%gen_alpha_f, this%newmark_beta, this%newmark_gamma)
      CASE DEFAULT
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_Ctrl_SetMethod: Unknown method'
          END IF
          RETURN
      END SELECT

      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Ctrl_SetMethod

  SUBROUTINE NM_TimeInt_Ctrl_SetTimeStep(this, dt, status)
      CLASS(NM_TimeInt_Ctrl_Ctx), INTENT(INOUT) :: this
      REAL(wp), INTENT(IN) :: dt
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

      IF (PRESENT(status)) CALL init_error_status(status)

      IF (dt <= ZERO) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_Ctrl_SetTimeStep: dt must be positive'
          END IF
          RETURN
      END IF

      ! Check adaptive dt limits
      IF (this%use_adaptive_dt) THEN
          this%dt = MAX(this%dt_min, MIN(dt, this%dt_max))
      ELSE
          this%dt = dt
      END IF

      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Ctrl_SetTimeStep

  !=============================================================================
  ! NM_TimeInt_State_Type METHODS
  !=============================================================================

  SUBROUTINE NM_TimeInt_State_Init(this, n_dof, status)
      CLASS(NM_TimeInt_State), INTENT(INOUT) :: this
      INTEGER(i4), INTENT(IN) :: n_dof
      TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

      IF (PRESENT(status)) CALL init_error_status(status)

      IF (n_dof <= 0) THEN
          IF (PRESENT(status)) THEN
              status%status_code = IF_STATUS_INVALID
              status%message = 'NM_TimeInt_State_Init: n_dof must be positive'
          END IF
          RETURN
      END IF

      ! Clean up existing allocation
      CALL this%Cleanup()

      ! Allocate arrays
      ALLOCATE(this%u(n_dof), this%v(n_dof), this%a(n_dof))
      ALLOCATE(this%u_prev(n_dof), this%v_prev(n_dof), this%a_prev(n_dof))
      ALLOCATE(this%u_intermediate(n_dof), this%v_intermediate(n_dof), this%a_intermediate(n_dof))

      ! Initialize to zero
      this%u = ZERO
      this%v = ZERO
      this%a = ZERO
      this%u_prev = ZERO
      this%v_prev = ZERO
      this%a_prev = ZERO
      this%u_intermediate = ZERO
      this%v_intermediate = ZERO
      this%a_intermediate = ZERO

      this%t_current = ZERO
      this%dt = ZERO
      this%step_count = 0
      this%converged = .FALSE.
      this%iteration_count = 0
      this%residual_norm = ZERO
      this%is_initialized = .TRUE.

      IF (PRESENT(status)) status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_State_Init

  SUBROUTINE NM_TimeInt_State_Cleanup(this)
      CLASS(NM_TimeInt_State), INTENT(INOUT) :: this

      IF (ALLOCATED(this%u)) DEALLOCATE(this%u)
      IF (ALLOCATED(this%v)) DEALLOCATE(this%v)
      IF (ALLOCATED(this%a)) DEALLOCATE(this%a)
      IF (ALLOCATED(this%u_prev)) DEALLOCATE(this%u_prev)
      IF (ALLOCATED(this%v_prev)) DEALLOCATE(this%v_prev)
      IF (ALLOCATED(this%a_prev)) DEALLOCATE(this%a_prev)
      IF (ALLOCATED(this%u_intermediate)) DEALLOCATE(this%u_intermediate)
      IF (ALLOCATED(this%v_intermediate)) DEALLOCATE(this%v_intermediate)
      IF (ALLOCATED(this%a_intermediate)) DEALLOCATE(this%a_intermediate)

      this%is_initialized = .FALSE.
  END SUBROUTINE NM_TimeInt_State_Cleanup

  SUBROUTINE NM_TimeInt_State_Update(this, u_new, v_new, a_new, dt)
      CLASS(NM_TimeInt_State), INTENT(INOUT) :: this
      REAL(wp), INTENT(IN) :: u_new(:)
      REAL(wp), INTENT(IN) :: v_new(:)
      REAL(wp), INTENT(IN) :: a_new(:)
      REAL(wp), INTENT(IN) :: dt

      ! Save previous values
      CALL this%SavePrevious()

      ! Update current values
      this%u = u_new
      this%v = v_new
      this%a = a_new
      this%t_current = this%t_current + dt
      this%step_count = this%step_count + 1
      this%dt = dt
  END SUBROUTINE NM_TimeInt_State_Update

  SUBROUTINE NM_TimeInt_State_SavePrevious(this)
      CLASS(NM_TimeInt_State), INTENT(INOUT) :: this

      this%u_prev = this%u
      this%v_prev = this%v
      this%a_prev = this%a
  END SUBROUTINE NM_TimeInt_State_SavePrevious

  !=============================================================================
  ! TIME INTEGRATION ALGORITHMS
  !=============================================================================

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_Newmark_Init
  ! Purpose: Initialize Newmark time integration method
  ! Interface: Structured (In/Out types)
  ! Theory: Set initial conditions for Newmark integration
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Newmark_Init(arg)
      !> [IN]  arg - Arg bundle with controller, state, and initial conditions
      !> [OUT] arg%out - Initialized state and status
      TYPE(NM_TimeInt_Newmark_Init_In), INTENT(INOUT) :: arg

      CALL init_error_status(arg%out%status)

      ! Copy input state to output
      arg%out%state = arg%in%state

      IF (.NOT. arg%in%ctrl%is_initialized) THEN
          arg%out%status%status_code = IF_STATUS_INVALID
          arg%out%status%message = 'NM_TimeInt_Newmark_Init: Controller not initialized'
          RETURN
      END IF

      IF (.NOT. arg%in%state%is_initialized) THEN
          arg%out%status%status_code = IF_STATUS_INVALID
          arg%out%status%message = 'NM_TimeInt_Newmark_Init: State not initialized'
          RETURN
      END IF

      IF (.NOT. ALLOCATED(arg%in%u0) .OR. .NOT. ALLOCATED(arg%in%v0) .OR. .NOT. ALLOCATED(arg%in%a0)) THEN
          arg%out%status%status_code = IF_STATUS_INVALID
          arg%out%status%message = 'NM_TimeInt_Newmark_Init: Invalid initial conditions'
          RETURN
      END IF

      ! Set initial conditions
      arg%out%state%u = arg%in%u0
      arg%out%state%v = arg%in%v0
      arg%out%state%a = arg%in%a0
      arg%out%state%u_prev = arg%in%u0
      arg%out%state%v_prev = arg%in%v0
      arg%out%state%a_prev = arg%in%a0
      arg%out%state%t_current = ZERO
      arg%out%state%dt = arg%in%ctrl%dt

      arg%out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Newmark_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_Newmark_Step
  ! Purpose: Perform one Newmark time integration step
  ! Interface: Structured (In/Out types)
  ! Theory:
  !   u_{n+1} = u_n + dt v_n + dt ((1/2-?) a_n + ? a_{n+1})
  !   v_{n+1} = v_n + dt?(1-?) a_n + ? a_{n+1})
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Newmark_Step(in, out)
      TYPE(NM_TimeInt_Newmark_Step_In), INTENT(IN) :: in
      TYPE(NM_TimeInt_Newmark_Step_Out), INTENT(OUT) :: out

      REAL(wp) :: c4, c5
      REAL(wp) :: du, dv

      CALL init_error_status(out%status)

      ! Copy input state to output
      out%state = in%state

      IF (.NOT. ALLOCATED(in%a_new)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_Newmark_Step: Invalid acceleration'
          RETURN
      END IF

      ! Newmark constants
      c4 = ONE / (TWO * in%ctrl%newmark_beta) - ONE
      c5 = in%ctrl%newmark_gamma / in%ctrl%newmark_beta - ONE

      ! Update displacement and velocity (Newmark formulas)
      ! u_{n+1} = u_n + dt v_n + dt ((1/2-?) a_n + ? a_{n+1})
      ! v_{n+1} = v_n + dt?(1-?) a_n + ? a_{n+1})

      du = in%state%dt * in%state%v_prev + in%state%dt**2 * &
           (c4 * in%state%a_prev + in%ctrl%newmark_beta * in%a_new)
      dv = in%state%dt * (c5 * in%state%a_prev + in%ctrl%newmark_gamma * in%a_new)

      out%state%u = in%state%u_prev + du
      out%state%v = in%state%v_prev + dv
      out%state%a = in%a_new
      out%state%t_current = in%state%t_current + in%state%dt
      out%state%step_count = in%state%step_count + 1

      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Newmark_Step

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_HHTAlpha_Init
  ! Purpose: Initialize HHT-alpha time integration method
  ! Interface: Structured (In/Out types)
  ! Theory: Set initial conditions for HHT-alpha integration
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_HHTAlpha_Init(in, out)
      TYPE(NM_TimeInt_HHTAlpha_Init_In), INTENT(IN) :: in
      TYPE(NM_TimeInt_HHTAlpha_Init_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      ! Copy input state to output
      out%state = in%state

      IF (.NOT. in%ctrl%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_HHTAlpha_Init: Controller not initialized'
          RETURN
      END IF

      IF (.NOT. ALLOCATED(in%u0) .OR. .NOT. ALLOCATED(in%v0) .OR. .NOT. ALLOCATED(in%a0)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_HHTAlpha_Init: Invalid initial conditions'
          RETURN
      END IF

      ! Set initial conditions
      out%state%u = in%u0
      out%state%v = in%v0
      out%state%a = in%a0
      out%state%u_prev = in%u0
      out%state%v_prev = in%v0
      out%state%a_prev = in%a0
      out%state%t_current = ZERO
      out%state%dt = in%ctrl%dt

      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_HHTAlpha_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_HHTAlpha_Step
  ! Purpose: Perform one HHT-alpha time integration step
  ! Interface: Structured (In/Out types)
  ! Theory: HHT-alpha method with numerical dissipation
  !   (1+?) M a_{n+1} - ? M a_n + (1+?) C v_{n+1} + (1+?) K u_{n+1} = F_{n+1}
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_HHTAlpha_Step(in, out)
      TYPE(NM_TimeInt_HHTAlpha_Step_In), INTENT(IN) :: in
      TYPE(NM_TimeInt_HHTAlpha_Step_Out), INTENT(OUT) :: out

      REAL(wp) :: alpha
      REAL(wp) :: c3, c4

      CALL init_error_status(out%status)

      ! Copy input state to output
      out%state = in%state

      IF (.NOT. ALLOCATED(in%a_new)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_HHTAlpha_Step: Invalid acceleration'
          RETURN
      END IF

      alpha = in%ctrl%hht_alpha

      ! HHT-alpha constants
      c3 = (ONE + alpha) / (TWO * in%ctrl%newmark_beta) - ONE
      c4 = (ONE + alpha) * in%ctrl%newmark_gamma / in%ctrl%newmark_beta - alpha

      ! Update using HHT-alpha formulas
      out%state%u = in%state%u_prev + in%state%dt * in%state%v_prev + &
                    in%state%dt**2 * (c3 * in%state%a_prev + in%ctrl%newmark_beta * in%a_new)
      out%state%v = in%state%v_prev + in%state%dt * (c4 * in%state%a_prev + in%ctrl%newmark_gamma * in%a_new)
      out%state%a = in%a_new
      out%state%t_current = in%state%t_current + in%state%dt
      out%state%step_count = in%state%step_count + 1

      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_HHTAlpha_Step

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_GeneralizedAlpha_Init
  ! Purpose: Initialize Generalized-alpha time integration method
  ! Interface: Structured (In/Out types)
  ! Theory: Set initial conditions for Generalized-alpha integration
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_GeneralizedAlpha_Init(in, out)
      TYPE(NM_TimeInt_GeneralizedAlpha_Init_In), INTENT(IN) :: in
      TYPE(NM_TimeInt_GeneralizedAlpha_Init_Out), INTENT(OUT) :: out

      CALL init_error_status(out%status)

      ! Copy input state to output
      out%state = in%state

      IF (.NOT. in%ctrl%is_initialized) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_GeneralizedAlpha_Init: Controller not initialized'
          RETURN
      END IF

      IF (.NOT. ALLOCATED(in%u0) .OR. .NOT. ALLOCATED(in%v0) .OR. .NOT. ALLOCATED(in%a0)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_GeneralizedAlpha_Init: Invalid initial conditions'
          RETURN
      END IF

      ! Set initial conditions
      out%state%u = in%u0
      out%state%v = in%v0
      out%state%a = in%a0
      out%state%u_prev = in%u0
      out%state%v_prev = in%v0
      out%state%a_prev = in%a0
      out%state%t_current = ZERO
      out%state%dt = in%ctrl%dt

      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_GeneralizedAlpha_Init

  !-----------------------------------------------------------------------------
  ! Subroutine: NM_TimeInt_GeneralizedAlpha_Step
  ! Purpose: Perform one Generalized-alpha time integration step
  ! Interface: Structured (In/Out types)
  ! Theory: Generalized-alpha method
  !   M a_{n+?_m} + C v_{n+?_f} + K u_{n+?_f} = F_{n+?_f}
  !   u_{n+?_f} = (1-?_f) u_n + ?_f u_{n+1}
  !   v_{n+?_f} = (1-?_f) v_n + ?_f v_{n+1}
  !   a_{n+?_m} = (1-?_m) a_n + ?_m a_{n+1}
  !-----------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_GeneralizedAlpha_Step(in, out)
      TYPE(NM_TimeInt_GeneralizedAlpha_Step_In), INTENT(IN) :: in
      TYPE(NM_TimeInt_GeneralizedAlpha_Step_Out), INTENT(OUT) :: out

      REAL(wp) :: alpha_m, alpha_f
      REAL(wp) :: u_alpha, v_alpha, a_alpha

      CALL init_error_status(out%status)

      ! Copy input state to output
      out%state = in%state

      IF (.NOT. ALLOCATED(in%a_new)) THEN
          out%status%status_code = IF_STATUS_INVALID
          out%status%message = 'NM_TimeInt_GeneralizedAlpha_Step: Invalid acceleration'
          RETURN
      END IF

      alpha_m = in%ctrl%gen_alpha_m
      alpha_f = in%ctrl%gen_alpha_f

      ! Generalized-alpha intermediate values
      ! u_{n+?_f} = (1-?_f) u_n + ?_f u_{n+1}
      ! v_{n+?_f} = (1-?_f) v_n + ?_f v_{n+1}
      ! a_{n+?_m} = (1-?_m) a_n + ?_m a_{n+1}

      ! First predict u and v using Newmark formulas
      out%state%u = in%state%u_prev + in%state%dt * in%state%v_prev + &
                    in%state%dt**2 * ((HALF - in%ctrl%newmark_beta) * in%state%a_prev + &
                                     in%ctrl%newmark_beta * in%a_new)
      out%state%v = in%state%v_prev + in%state%dt * ((ONE - in%ctrl%newmark_gamma) * in%state%a_prev + &
                                                     in%ctrl%newmark_gamma * in%a_new)
      out%state%a = in%a_new

      ! Compute intermediate values
      u_alpha = (ONE - alpha_f) * in%state%u_prev + alpha_f * out%state%u
      v_alpha = (ONE - alpha_f) * in%state%v_prev + alpha_f * out%state%v
      a_alpha = (ONE - alpha_m) * in%state%a_prev + alpha_m * out%state%a

      out%state%u_intermediate = u_alpha
      out%state%v_intermediate = v_alpha
      out%state%a_intermediate = a_alpha

      out%state%t_current = in%state%t_current + in%state%dt
      out%state%step_count = in%state%step_count + 1

      out%status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_GeneralizedAlpha_Step

  !=============================================================================
  ! HELPER FUNCTIONS
  !=============================================================================

  SUBROUTINE NM_TimeInt_GetAlpha(rho_inf, alpha_m, alpha_f, beta, gamma)
      REAL(wp), INTENT(IN) :: rho_inf   ! Spectral radius at high frequency
      REAL(wp), INTENT(OUT) :: alpha_m  ! Generalized-alpha alpha_m
      REAL(wp), INTENT(OUT) :: alpha_f  ! Generalized-alpha alpha_f
      REAL(wp), INTENT(OUT) :: beta     ! Newmark beta
      REAL(wp), INTENT(OUT) :: gamma    ! Newmark gamma

      ! Generalized-alpha parameters (Chung & Hulbert, 1993)
      alpha_m = (TWO * rho_inf - ONE) / (rho_inf + ONE)
      alpha_f = rho_inf / (rho_inf + ONE)
      beta = QUARTER * (ONE - alpha_m + alpha_f)**2
      gamma = HALF - alpha_m + alpha_f
  END SUBROUTINE NM_TimeInt_GetAlpha

  FUNCTION NM_TimeInt_GetBeta(method, rho_inf) RESULT(beta)
      INTEGER(i4), INTENT(IN) :: method
      REAL(wp), INTENT(IN), OPTIONAL :: rho_inf
      REAL(wp) :: beta
      REAL(wp) :: alpha_m, alpha_f, gamma

      SELECT CASE (method)
      CASE (1)  ! Newmark (average acceleration)
          beta = QUARTER
      CASE (2)  ! HHT-alpha
          beta = QUARTER
      CASE (3)  ! Generalized-alpha
          IF (PRESENT(rho_inf)) THEN
              CALL NM_TimeInt_GetAlpha(rho_inf, alpha_m, alpha_f, beta, gamma)
          ELSE
              beta = QUARTER
          END IF
      CASE DEFAULT
          beta = QUARTER
      END SELECT
  END FUNCTION NM_TimeInt_GetBeta

  FUNCTION NM_TimeInt_GetGamma(method, rho_inf) RESULT(gamma)
      INTEGER(i4), INTENT(IN) :: method
      REAL(wp), INTENT(IN), OPTIONAL :: rho_inf
      REAL(wp) :: gamma
      REAL(wp) :: alpha_m, alpha_f, beta

      SELECT CASE (method)
      CASE (1)  ! Newmark (average acceleration)
          gamma = HALF
      CASE (2)  ! HHT-alpha
          gamma = HALF
      CASE (3)  ! Generalized-alpha
          IF (PRESENT(rho_inf)) THEN
              CALL NM_TimeInt_GetAlpha(rho_inf, alpha_m, alpha_f, beta, gamma)
          ELSE
              gamma = HALF
          END IF
      CASE DEFAULT
          gamma = HALF
      END SELECT
  END FUNCTION NM_TimeInt_GetGamma

END MODULE NM_TimeInt_Scheme