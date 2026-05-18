!===============================================================================
! Module: HARNESS_Cont_Friction_Coulomb
! Layer:  L4_PH - Physics Layer (Harness)
! Domain: Contact
! Purpose: Harness acceptance test — Coulomb friction model.
!          Uses PH_Cont_Core::PH_Contact_Compute_Friction_Force to verify
!          stick/slip transitions and friction force limits.
!
! Theory:
!   Coulomb friction:
!     f_trial = penalty_tangent * |slip|
!     f_limit = mu * f_normal
!     if f_trial <= f_limit => STICK, f_friction = f_trial
!     if f_trial >  f_limit => SLIP,  f_friction = f_limit
!
! Test Cases:
!   TC-1: Stick regime (f_trial < mu*N)
!   TC-2: Slip regime (f_trial > mu*N)
!   TC-3: Zero normal force => no friction
!   TC-4: Verify friction direction follows slip sign
!
! Status: Harness | Created: 2026-04-28
!===============================================================================
MODULE HARNESS_Cont_Friction_Coulomb
  USE IF_Prec_Core, ONLY: wp, i4
  USE PH_Cont_Core, ONLY: PH_Contact_Core_Init, &
                           PH_Contact_Compute_Friction_Force
  USE PH_Cont_Def,  ONLY: PH_Cont_Desc, PH_Cont_State, &
                           PH_Cont_Algo, PH_Cont_Ctx, &
                           PH_CONT_STICK, PH_CONT_SLIP, PH_CONT_OPEN
  USE IF_Err_Brg,    ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_Harness_Cont_Friction_Coulomb

  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp

CONTAINS

  SUBROUTINE Run_Harness_Cont_Friction_Coulomb()
    TYPE(PH_Cont_Desc)  :: desc
    TYPE(PH_Cont_State) :: state
    TYPE(PH_Cont_Algo)  :: algo
    TYPE(PH_Cont_Ctx)   :: ctx
    TYPE(ErrorStatusType)  :: status
    REAL(wp) :: f_limit, f_trial_expected
    INTEGER(i4) :: n_pass, n_fail

    n_pass = 0
    n_fail = 0

    WRITE(*,*) ''
    WRITE(*,*) '===================================================================='
    WRITE(*,*) 'HARNESS_Cont_Friction_Coulomb: Coulomb Friction Model'
    WRITE(*,*) '===================================================================='
    WRITE(*,*) ''

    ! ---------------------------------------------------------------
    ! TC-1: Stick regime
    !   mu = 0.3, f_normal = 1000 N => f_limit = 300 N
    !   penalty_tangent = 1e5, slip = 0.001 => f_trial = 100 N
    !   100 < 300 => STICK, f_friction = 100 N
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%mu_friction     = 0.3_wp
    desc%penalty_tangent = 1.0e5_wp
    state%f_normal       = 1000.0_wp    ! N (already computed)
    state%slip           = 0.001_wp     ! m

    CALL PH_Contact_Compute_Friction_Force(desc, state, status)

    f_limit = desc%mu_friction * state%f_normal   ! 300 N
    f_trial_expected = desc%penalty_tangent * ABS(state%slip)  ! 100 N

    WRITE(*,*) '  TC-1: Stick regime'
    WRITE(*,*) '    mu = ', desc%mu_friction, ', f_normal = ', state%f_normal, ' N'
    WRITE(*,*) '    f_limit = mu*N = ', f_limit, ' N'
    WRITE(*,*) '    f_trial = pen*|slip| = ', f_trial_expected, ' N'
    WRITE(*,*) '    Computed f_friction = ', state%f_friction, ' N'
    WRITE(*,*) '    Contact status = ', state%contact_status

    IF (ABS(state%f_friction - f_trial_expected) < TOL .AND. &
        state%contact_status == PH_CONT_STICK) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-2: Slip regime
    !   Same mu/penalty, but slip = 0.01 => f_trial = 1000 N
    !   1000 > 300 => SLIP, f_friction = 300 N
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%mu_friction     = 0.3_wp
    desc%penalty_tangent = 1.0e5_wp
    state%f_normal       = 1000.0_wp
    state%slip           = 0.01_wp

    CALL PH_Contact_Compute_Friction_Force(desc, state, status)

    f_limit = desc%mu_friction * state%f_normal   ! 300 N
    f_trial_expected = desc%penalty_tangent * ABS(state%slip)  ! 1000 N

    WRITE(*,*) '  TC-2: Slip regime'
    WRITE(*,*) '    f_trial = ', f_trial_expected, ' N'
    WRITE(*,*) '    f_limit = ', f_limit, ' N'
    WRITE(*,*) '    Computed f_friction = ', state%f_friction, ' N'
    WRITE(*,*) '    Contact status = ', state%contact_status

    IF (ABS(state%f_friction - f_limit) < TOL .AND. &
        state%contact_status == PH_CONT_SLIP) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-3: Zero normal force => no friction (OPEN)
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%mu_friction     = 0.3_wp
    desc%penalty_tangent = 1.0e5_wp
    state%f_normal       = 0.0_wp
    state%slip           = 0.01_wp

    CALL PH_Contact_Compute_Friction_Force(desc, state, status)

    WRITE(*,*) '  TC-3: Zero normal force'
    WRITE(*,*) '    f_normal = 0'
    WRITE(*,*) '    Computed f_friction = ', state%f_friction
    WRITE(*,*) '    Contact status = ', state%contact_status

    IF (ABS(state%f_friction) < TOL .AND. &
        state%contact_status == PH_CONT_OPEN) THEN
      WRITE(*,*) '    >> PASS'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! TC-4: Negative slip => friction reverses sign
    !   slip = -0.001 => f_friction should be negative (STICK)
    ! ---------------------------------------------------------------
    CALL PH_Contact_Core_Init(desc, state, algo, ctx, status)
    desc%mu_friction     = 0.3_wp
    desc%penalty_tangent = 1.0e5_wp
    state%f_normal       = 1000.0_wp
    state%slip           = -0.001_wp

    CALL PH_Contact_Compute_Friction_Force(desc, state, status)

    WRITE(*,*) '  TC-4: Negative slip direction'
    WRITE(*,*) '    slip = ', state%slip
    WRITE(*,*) '    Computed f_friction = ', state%f_friction

    IF (state%f_friction < 0.0_wp .AND. &
        ABS(ABS(state%f_friction) - desc%penalty_tangent * ABS(state%slip)) < TOL) THEN
      WRITE(*,*) '    >> PASS (correct sign and magnitude)'
      n_pass = n_pass + 1
    ELSE
      WRITE(*,*) '    >> FAIL'
      n_fail = n_fail + 1
    END IF

    ! ---------------------------------------------------------------
    ! Summary
    ! ---------------------------------------------------------------
    WRITE(*,*) ''
    WRITE(*,*) '--------------------------------------------------------------------'
    WRITE(*,*) '  HARNESS_Cont_Friction_Coulomb: ', n_pass, ' PASSED, ', n_fail, ' FAILED'
    IF (n_fail == 0) THEN
      WRITE(*,*) '  >> ALL PASS'
    ELSE
      WRITE(*,*) '  >> SOME FAILURES'
    END IF
    WRITE(*,*) '===================================================================='

  END SUBROUTINE Run_Harness_Cont_Friction_Coulomb

END MODULE HARNESS_Cont_Friction_Coulomb

!===============================================================================
! Runner
!===============================================================================
PROGRAM HARNESS_Cont_Friction_Coulomb_Runner
  USE HARNESS_Cont_Friction_Coulomb, ONLY: Run_Harness_Cont_Friction_Coulomb
  IMPLICIT NONE
  CALL Run_Harness_Cont_Friction_Coulomb()
END PROGRAM HARNESS_Cont_Friction_Coulomb_Runner
