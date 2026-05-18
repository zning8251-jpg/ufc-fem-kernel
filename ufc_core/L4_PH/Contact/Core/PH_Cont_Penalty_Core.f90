!===============================================================================
! MODULE: PH_Cont_Penalty_Core
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Core
! BRIEF:  Penalty method core: normal force, stiffness, tangential force
!
! Theory: f_n = eps_n*<-g_n>; k_n = eps_n*H(-g_n); Wriggers (2006) Ch.4
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
MODULE PH_Cont_Penalty_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Cont_Penalty_Compute_NormalForce
  PUBLIC :: PH_Cont_Penalty_Compute_Stiffness
  PUBLIC :: PH_Cont_Penalty_Compute_TangentForce
  PUBLIC :: PH_Cont_Penalty_Compute_Full

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_Cont_Penalty_Compute_NormalForce
  !   f_n = eps_n * max(0, -gap_n)   (Macaulay bracket on penetration)
  !   gap_n > 0 → open → f_n = 0
  !   gap_n < 0 → penetration → f_n = eps_n * |gap_n|
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Penalty_Compute_NormalForce(gap_n, penalty_param, f_n, ierr)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap (>0 open, <0 penetration)
    REAL(wp), INTENT(IN)     :: penalty_param  ! Penalty stiffness eps_n [N/m^3]
    REAL(wp), INTENT(OUT)    :: f_n            ! Normal contact force (>=0)
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK, 1=invalid param

    ierr = 0

    IF (penalty_param < 0.0_wp) THEN
      ierr = 1
      f_n = 0.0_wp
      RETURN
    END IF

    ! Macaulay bracket: f_n = eps_n * <-gap_n>
    IF (gap_n < 0.0_wp) THEN
      f_n = penalty_param * (-gap_n)
    ELSE
      f_n = 0.0_wp
    END IF

  END SUBROUTINE PH_Cont_Penalty_Compute_NormalForce

  !---------------------------------------------------------------------------
  ! PH_Cont_Penalty_Compute_Stiffness
  !   k_n = eps_n * H(-gap_n)
  !   Heaviside: H(x) = 1 if x >= 0, else 0
  !   Active only when penetration exists (gap_n < 0).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Penalty_Compute_Stiffness(gap_n, penalty_param, k_n, ierr)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap
    REAL(wp), INTENT(IN)     :: penalty_param  ! Penalty stiffness eps_n
    REAL(wp), INTENT(OUT)    :: k_n            ! Normal contact stiffness
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    ierr = 0

    IF (penalty_param < 0.0_wp) THEN
      ierr = 1
      k_n = 0.0_wp
      RETURN
    END IF

    ! Heaviside activation
    IF (gap_n < 0.0_wp) THEN
      k_n = penalty_param
    ELSE
      k_n = 0.0_wp
    END IF

  END SUBROUTINE PH_Cont_Penalty_Compute_Stiffness

  !---------------------------------------------------------------------------
  ! PH_Cont_Penalty_Compute_TangentForce
  !   Elastic predictor for tangential (friction) direction:
  !   f_t = eps_t * slip
  !   This is the trial tangential force before Coulomb return mapping.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Penalty_Compute_TangentForce(slip, penalty_tangent, f_t, ierr)
    REAL(wp), INTENT(IN)     :: slip(2)          ! Tangential slip increments
    REAL(wp), INTENT(IN)     :: penalty_tangent  ! Tangential penalty eps_t
    REAL(wp), INTENT(OUT)    :: f_t(2)           ! Tangential penalty force
    INTEGER(i4), INTENT(OUT) :: ierr             ! 0=OK

    ierr = 0

    IF (penalty_tangent < 0.0_wp) THEN
      ierr = 1
      f_t(:) = 0.0_wp
      RETURN
    END IF

    f_t(1) = penalty_tangent * slip(1)
    f_t(2) = penalty_tangent * slip(2)

  END SUBROUTINE PH_Cont_Penalty_Compute_TangentForce

  !---------------------------------------------------------------------------
  ! PH_Cont_Penalty_Compute_Full
  !   Combined: normal force + stiffness + tangential trial force
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Penalty_Compute_Full(gap_n, slip, eps_n, eps_t, &
                                           f_n, k_n, f_t, ierr)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap
    REAL(wp), INTENT(IN)     :: slip(2)        ! Tangential slip
    REAL(wp), INTENT(IN)     :: eps_n          ! Normal penalty
    REAL(wp), INTENT(IN)     :: eps_t          ! Tangential penalty
    REAL(wp), INTENT(OUT)    :: f_n            ! Normal force
    REAL(wp), INTENT(OUT)    :: k_n            ! Normal stiffness
    REAL(wp), INTENT(OUT)    :: f_t(2)         ! Tangential trial force
    INTEGER(i4), INTENT(OUT) :: ierr

    ierr = 0

    ! Normal
    IF (gap_n < 0.0_wp) THEN
      f_n = eps_n * (-gap_n)
      k_n = eps_n
    ELSE
      f_n = 0.0_wp
      k_n = 0.0_wp
    END IF

    ! Tangential (elastic predictor)
    f_t(1) = eps_t * slip(1)
    f_t(2) = eps_t * slip(2)

  END SUBROUTINE PH_Cont_Penalty_Compute_Full

END MODULE PH_Cont_Penalty_Core
