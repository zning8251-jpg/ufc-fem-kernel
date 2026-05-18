!===============================================================================
! MODULE: NM_TimeInt_Mgr
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Mgr — Time integration domain container and lifecycle manager
! BRIEF:  Domain container for Newmark/HHT/adaptive time stepping
!===============================================================================
MODULE NM_TimeInt_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                         IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Time integration scheme enumerations
  !--------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TimeIntNewmark    = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TimeIntHHT       = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TIMEINT_EXPLICIT   = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: NM_TIMEINT_STATIC     = 0_i4

  !--------------------------------------------------------------------
  ! NM_TimeIntCtrl ?Time integration control parameters
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_TimeIntCtrl
    INTEGER(i4) :: scheme       = NM_TimeIntNewmark
    REAL(wp)    :: beta         = 0.25_wp        ! Newmark ?
    REAL(wp)    :: gamma        = 0.50_wp        ! Newmark ?
    REAL(wp)    :: alpha_hht    = 0.0_wp         ! HHT-? (0 = no dissipation)
    REAL(wp)    :: dtMin        = 1.0e-10_wp
    REAL(wp)    :: dtMax        = 1.0_wp
    REAL(wp)    :: dtInit       = 0.01_wp
    INTEGER(i4) :: cutbackLimit = 5_i4
    LOGICAL     :: enAdaptive   = .TRUE.
  END TYPE NM_TimeIntCtrl

  !--------------------------------------------------------------------
  ! NM_TimeInt_Domain ?Domain container
  !--------------------------------------------------------------------
  TYPE, PUBLIC :: NM_TimeInt_Domain
    TYPE(NM_TimeIntCtrl) :: ctrl
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init        => NM_TimeInt_Init
    PROCEDURE :: Finalize    => NM_TimeInt_Finalize
    PROCEDURE :: SetScheme   => NM_TimeInt_SetScheme
    PROCEDURE :: Advance     => NM_TimeInt_Advance
    PROCEDURE :: GetSummary  => NM_TimeInt_GetSummary
  END TYPE NM_TimeInt_Domain

CONTAINS

  SUBROUTINE NM_TimeInt_Finalize(this)
    !> [INOUT] this - Domain instance to finalize
    CLASS(NM_TimeInt_Domain), INTENT(INOUT) :: this
    IF (.NOT. this%initialized) RETURN
    this%ctrl = NM_TimeIntCtrl()
    this%initialized = .FALSE.
  END SUBROUTINE NM_TimeInt_Finalize

  SUBROUTINE NM_TimeInt_Init(this, status)
    !> [INOUT] this   - Domain instance to initialize
    !> [OUT]   status - Error status
    CLASS(NM_TimeInt_Domain), INTENT(INOUT) :: this
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status
    CALL init_error_status(status)
    IF (this%initialized) CALL this%Finalize()
    this%initialized  = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Init

  !====================================================================
  ! NM_TimeInt_SetScheme
  ! Set time integration scheme and parameters
  !====================================================================
  SUBROUTINE NM_TimeInt_SetScheme(this, scheme, beta, gamma, alpha, status)
    CLASS(NM_TimeInt_Domain), INTENT(INOUT) :: this
    INTEGER(i4),              INTENT(IN)    :: scheme
    REAL(wp),                 INTENT(IN)    :: beta, gamma, alpha
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    CALL init_error_status(status)

    ! Validate scheme
    IF (scheme < NM_TIMEINT_STATIC .OR. scheme > NM_TIMEINT_EXPLICIT) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid time integration scheme"
      RETURN
    END IF

    this%ctrl%scheme = scheme
    this%ctrl%beta = beta
    this%ctrl%gamma = gamma
    this%ctrl%alpha_hht = alpha

    ! Set default parameters based on scheme
    SELECT CASE(scheme)
    CASE(NM_TimeIntNewmark)
      IF (beta <= 0.0_wp .OR. gamma <= 0.0_wp) THEN
        this%ctrl%beta = 0.25_wp
        this%ctrl%gamma = 0.50_wp
      END IF
    CASE(NM_TimeIntHHT)
      IF (alpha < -0.333_wp .OR. alpha > 0.0_wp) THEN
        this%ctrl%alpha_hht = 0.0_wp
      END IF
    END SELECT

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_TimeInt_SetScheme

  !====================================================================
  ! NM_TimeInt_Advance
  ! Advance time integration by one step
  !====================================================================
  SUBROUTINE NM_TimeInt_Advance(this, u, v, a, dt, status)
    CLASS(NM_TimeInt_Domain), INTENT(INOUT) :: this
    REAL(wp),                 INTENT(INOUT) :: u(:), v(:), a(:)
    REAL(wp),                 INTENT(IN)    :: dt
    TYPE(ErrorStatusType),    INTENT(OUT)   :: status

    REAL(wp) :: beta, gamma, c4, c5

    CALL init_error_status(status)

    ! Validate time step
    IF (dt <= 0.0_wp .OR. dt > this%ctrl%dtMax) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "Invalid time step"
      RETURN
    END IF

    ! Get Newmark parameters
    beta = this%ctrl%beta
    gamma = this%ctrl%gamma

    ! Newmark time integration
    ! u_{n+1} = u_n + dt v_n + dt [(1/2-?) a_n + ? a_{n+1}]
    ! v_{n+1} = v_n + dt [(1-?) a_n + ? a_{n+1}]

    ! Newmark: u_{n+1} = u_n + dt*v_n + dt^2*[(1/2-beta)*a_n + beta*a_{n+1}]
    !          v_{n+1} = v_n + dt*[(1-gamma)*a_n + gamma*a_{n+1}]
    ! Use explicit predictor: a_{n+1} = a_n
    c4 = 1.0_wp / (2.0_wp * beta) - 1.0_wp
    c5 = gamma / beta - 1.0_wp
    u = u + dt * v + dt**2 * (c4 * a + beta * a)
    v = v + dt * (c5 * a + gamma * a)

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_TimeInt_Advance

  !====================================================================
  ! NM_TimeInt_GetSummary
  ! Get summary string of time integration domain
  !====================================================================
  SUBROUTINE NM_TimeInt_GetSummary(this, summary, status)
    CLASS(NM_TimeInt_Domain), INTENT(IN)  :: this
    CHARACTER(LEN=512),       INTENT(OUT) :: summary
    TYPE(ErrorStatusType),    INTENT(OUT) :: status

    CHARACTER(LEN=16) :: schemeName

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "TimeIntegration domain not initialized"
      RETURN
    END IF

    ! Get scheme name
    SELECT CASE(this%ctrl%scheme)
    CASE(NM_TIMEINT_STATIC)
      schemeName = "Static"
    CASE(NM_TimeIntNewmark)
      schemeName = "Newmark"
    CASE(NM_TimeIntHHT)
      schemeName = "HHT-alpha"
    CASE(NM_TIMEINT_EXPLICIT)
      schemeName = "Explicit"
    CASE DEFAULT
      schemeName = "Unknown"
    END SELECT

    WRITE(summary, '(A,A,A,ES10.3,A,ES10.3,A,ES10.3,A,ES10.3,A,ES10.3,A,L1)') &
      "TimeInt Summary: Scheme=", TRIM(schemeName), &
      ", beta=", this%ctrl%beta, &
      ", gamma=", this%ctrl%gamma, &
      ", alpha=", this%ctrl%alpha_hht, &
      ", dt=", this%ctrl%dtInit, &
      ", Adaptive=", this%ctrl%enAdaptive

    status%status_code = IF_STATUS_OK

  END SUBROUTINE NM_TimeInt_GetSummary

END MODULE NM_TimeInt_Mgr