!===============================================================================
! MODULE: NM_TimeInt_Core
! LAYER:  L2_NM
! DOMAIN: TimeIntegration
! ROLE:   Core — Newmark predict/correct, central difference, HHT-alpha
! BRIEF:  Time integration scheme core routines using four-type signature
!===============================================================================
MODULE NM_TimeInt_Core
  USE IF_Prec_Core,          ONLY: wp, i4
  USE IF_Err_Brg,       ONLY: ErrorStatusType, init_error_status, &
                              IF_STATUS_OK, IF_STATUS_INVALID
  USE NM_TimeInt_Def,   ONLY: NM_TimeInt_Desc, NM_TimeInt_State, &
                              NM_TimeInt_Algo, NM_TINT_NEWMARK, &
                              NM_TINT_CENTRAL_DIFF, NM_TINT_HHT_ALPHA
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: NM_TimeInt_Core_Init
  PUBLIC :: NM_TimeInt_Core_Finalize
  PUBLIC :: NM_TimeInt_Newmark_Predict
  PUBLIC :: NM_TimeInt_Newmark_Correct
  PUBLIC :: NM_TimeInt_Central_Diff
  PUBLIC :: NM_TimeInt_HHT_Alpha
  PUBLIC :: NM_TimeInt_Compute_Stable_DT

CONTAINS

  SUBROUTINE NM_TimeInt_Core_Init(desc, state, algo, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)    :: desc
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    NULLIFY(state%u, state%v, state%a, state%u_pred, state%v_pred)
    state%time = 0.0_wp
    state%dt   = 0.0_wp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Core_Init

  SUBROUTINE NM_TimeInt_Core_Finalize(state, status)
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)
    IF (ASSOCIATED(state%u))      DEALLOCATE(state%u)
    IF (ASSOCIATED(state%v))      DEALLOCATE(state%v)
    IF (ASSOCIATED(state%a))      DEALLOCATE(state%a)
    IF (ASSOCIATED(state%u_pred)) DEALLOCATE(state%u_pred)
    IF (ASSOCIATED(state%v_pred)) DEALLOCATE(state%v_pred)
    NULLIFY(state%u, state%v, state%a, state%u_pred, state%v_pred)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Core_Finalize

  !---------------------------------------------------------------------------
  ! Newmark predict: u_pred and v_pred from current u, v, a
  !   u_pred = u + dt*v + (0.5 - beta)*dt^2*a
  !   v_pred = v + (1 - gamma)*dt*a
  !---------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Newmark_Predict(desc, state, algo, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)    :: desc
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i
    REAL(wp) :: dt, dt2

    CALL init_error_status(status)
    IF (desc%ndof <= 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_TimeInt_Newmark_Predict]: ndof <= 0"
      RETURN
    END IF

    dt  = state%dt
    dt2 = dt * dt
    DO i = 1, desc%ndof
      state%u_pred(i) = state%u(i) + dt * state%v(i) &
                       + (0.5_wp - algo%beta) * dt2 * state%a(i)
      state%v_pred(i) = state%v(i) + (1.0_wp - algo%gamma) * dt * state%a(i)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Newmark_Predict

  !---------------------------------------------------------------------------
  ! Newmark correct: update u, v, a from predicted values and new acceleration
  !   u = u_pred + beta*dt^2*a_new
  !   v = v_pred + gamma*dt*a_new
  !---------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Newmark_Correct(desc, state, algo, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)    :: desc
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i
    REAL(wp) :: dt, dt2

    CALL init_error_status(status)
    dt  = state%dt
    dt2 = dt * dt
    DO i = 1, desc%ndof
      state%u(i) = state%u_pred(i) + algo%beta * dt2 * state%a(i)
      state%v(i) = state%v_pred(i) + algo%gamma * dt * state%a(i)
    END DO
    state%time = state%time + dt
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Newmark_Correct

  !---------------------------------------------------------------------------
  ! Central difference: a_new = M_diag^{-1} * (F - K*u), then v, u update
  !---------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Central_Diff(desc, state, algo, M_diag, F, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)    :: desc
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
    REAL(wp),               INTENT(IN)    :: M_diag(:)
    REAL(wp),               INTENT(IN)    :: F(:)
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i
    REAL(wp) :: dt, half_dt

    CALL init_error_status(status)
    dt      = state%dt
    half_dt = 0.5_wp * dt

    DO i = 1, desc%ndof
      IF (ABS(M_diag(i)) < 1.0E-30_wp) THEN
        status%status_code = IF_STATUS_INVALID
        status%message = "[NM_TimeInt_Central_Diff]: zero diagonal mass"
        RETURN
      END IF
      state%a(i) = F(i) / M_diag(i)
      state%v(i) = state%v(i) + dt * state%a(i)
      state%u(i) = state%u(i) + dt * state%v(i)
    END DO
    state%time = state%time + dt
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Central_Diff

  !---------------------------------------------------------------------------
  ! HHT-alpha: modified Newmark with numerical dissipation
  !---------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_HHT_Alpha(desc, state, algo, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)    :: desc
    TYPE(NM_TimeInt_State), INTENT(INOUT) :: state
    TYPE(NM_TimeInt_Algo),  INTENT(IN)    :: algo
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    INTEGER(i4) :: i
    REAL(wp) :: dt, dt2, alpha_m
    REAL(wp) :: beta_eff, gamma_eff

    CALL init_error_status(status)
    alpha_m   = algo%alpha_hht
    beta_eff  = (1.0_wp - alpha_m)**2 * algo%beta
    gamma_eff = (1.0_wp - alpha_m) * algo%gamma + alpha_m * 0.5_wp
    dt  = state%dt
    dt2 = dt * dt

    DO i = 1, desc%ndof
      state%u_pred(i) = state%u(i) + dt * state%v(i) &
                       + (0.5_wp - beta_eff) * dt2 * state%a(i)
      state%v_pred(i) = state%v(i) + (1.0_wp - gamma_eff) * dt * state%a(i)
    END DO
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_HHT_Alpha

  !---------------------------------------------------------------------------
  ! Compute critical stable time step: dt_crit = 2 / omega_max
  !---------------------------------------------------------------------------
  SUBROUTINE NM_TimeInt_Compute_Stable_DT(desc, algo, omega_max, dt_crit, status)
    TYPE(NM_TimeInt_Desc),  INTENT(IN)  :: desc
    TYPE(NM_TimeInt_Algo),  INTENT(IN)  :: algo
    REAL(wp),               INTENT(IN)  :: omega_max
    REAL(wp),               INTENT(OUT) :: dt_crit
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (omega_max <= 0.0_wp) THEN
      dt_crit = 0.0_wp
      status%status_code = IF_STATUS_INVALID
      status%message = "[NM_TimeInt_Compute_Stable_DT]: omega_max <= 0"
      RETURN
    END IF

    dt_crit = 2.0_wp / omega_max
    status%status_code = IF_STATUS_OK
  END SUBROUTINE NM_TimeInt_Compute_Stable_DT

END MODULE NM_TimeInt_Core
