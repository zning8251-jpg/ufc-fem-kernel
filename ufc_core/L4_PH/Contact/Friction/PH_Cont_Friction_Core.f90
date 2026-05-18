!===============================================================================
! MODULE: PH_Cont_Friction_Core
! LAYER:  L4_PH
! DOMAIN: Contact / Friction
! ROLE:   Core
! BRIEF:  Coulomb friction return mapping + consistent tangent matrix
!
! Theory: Coulomb cone Phi = |f_t_trial| - mu*|f_n| <= 0
!   Wriggers (2006) Ch.6 §6.3; Simo & Laursen (1992)
! Constants: PH_FRICTION_OPEN / PH_FRICTION_STICK / PH_FRICTION_SLIP
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
MODULE PH_Cont_Friction_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Cont_Friction_Compute_Coulomb
  PUBLIC :: PH_Cont_Friction_Compute_Tangent

  ! Slip status constants
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_OPEN  = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_STICK = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_FRICTION_SLIP  = 2_i4

  REAL(wp), PARAMETER :: TINY_VAL = 1.0E-30_wp

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_Cont_Friction_Compute_Coulomb
  !   Coulomb friction return mapping:
  !   1. Compute yield function: Phi = |f_t_trial| - mu * |f_n|
  !   2. If Phi <= 0 → STICK: f_t = f_t_trial
  !   3. If Phi > 0  → SLIP:  f_t = mu*|f_n| * f_t_trial / |f_t_trial|
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Friction_Compute_Coulomb(f_t_trial, f_n, mu, &
                                               f_t, slip_status, ierr)
    REAL(wp), INTENT(IN)     :: f_t_trial(2)   ! Trial tangential force
    REAL(wp), INTENT(IN)     :: f_n            ! Normal contact force (>= 0)
    REAL(wp), INTENT(IN)     :: mu             ! Friction coefficient
    REAL(wp), INTENT(OUT)    :: f_t(2)         ! Corrected tangential force
    INTEGER(i4), INTENT(OUT) :: slip_status    ! STICK=1, SLIP=2
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    REAL(wp) :: f_t_mag, f_limit, phi

    ierr = 0

    ! No contact → no friction
    IF (f_n <= 0.0_wp) THEN
      f_t(:) = 0.0_wp
      slip_status = PH_FRICTION_OPEN
      RETURN
    END IF

    ! Validate
    IF (mu < 0.0_wp) THEN
      ierr = 1
      f_t(:) = 0.0_wp
      slip_status = PH_FRICTION_OPEN
      RETURN
    END IF

    ! Trial force magnitude
    f_t_mag = SQRT(f_t_trial(1)**2 + f_t_trial(2)**2)

    ! Coulomb limit
    f_limit = mu * ABS(f_n)

    ! Yield function
    phi = f_t_mag - f_limit

    IF (phi <= 0.0_wp) THEN
      ! STICK: trial force is within the friction cone
      f_t(:) = f_t_trial(:)
      slip_status = PH_FRICTION_STICK
    ELSE
      ! SLIP: return mapping to friction cone surface
      IF (f_t_mag > TINY_VAL) THEN
        f_t(1) = f_limit * (f_t_trial(1) / f_t_mag)
        f_t(2) = f_limit * (f_t_trial(2) / f_t_mag)
      ELSE
        f_t(:) = 0.0_wp
      END IF
      slip_status = PH_FRICTION_SLIP
    END IF

  END SUBROUTINE PH_Cont_Friction_Compute_Coulomb

  !---------------------------------------------------------------------------
  ! PH_Cont_Friction_Compute_Tangent
  !   Consistent tangent matrix for friction (2x2 in tangent plane):
  !
  !   STICK: K_friction = eps_t * I_2
  !          (full tangential penalty stiffness)
  !
  !   SLIP:  K_friction = (mu*|f_n| / |f_t_trial|) *
  !                       (eps_t * (I_2 - n_t (x) n_t))
  !          where n_t = f_t_trial / |f_t_trial| is the slip direction
  !          This gives the consistent algorithmic tangent for the
  !          return mapping (Simo & Laursen 1992).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_Friction_Compute_Tangent(f_t_trial, f_n, mu, eps_t, &
                                               slip_status, K_friction, ierr)
    REAL(wp), INTENT(IN)     :: f_t_trial(2)   ! Trial tangential force
    REAL(wp), INTENT(IN)     :: f_n            ! Normal contact force
    REAL(wp), INTENT(IN)     :: mu             ! Friction coefficient
    REAL(wp), INTENT(IN)     :: eps_t          ! Tangential penalty
    INTEGER(i4), INTENT(IN)  :: slip_status    ! STICK=1, SLIP=2
    REAL(wp), INTENT(OUT)    :: K_friction(2,2)! Friction tangent matrix (2x2)
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    REAL(wp) :: f_t_mag, scale, n_t(2)
    INTEGER(i4) :: i, j

    ierr = 0
    K_friction(:,:) = 0.0_wp

    ! No contact → zero tangent
    IF (f_n <= 0.0_wp) RETURN

    SELECT CASE (slip_status)

    CASE (PH_FRICTION_STICK)
      ! K = eps_t * I_2  (tangential penalty stiffness)
      K_friction(1,1) = eps_t
      K_friction(2,2) = eps_t

    CASE (PH_FRICTION_SLIP)
      f_t_mag = SQRT(f_t_trial(1)**2 + f_t_trial(2)**2)

      IF (f_t_mag > TINY_VAL) THEN
        n_t(1) = f_t_trial(1) / f_t_mag
        n_t(2) = f_t_trial(2) / f_t_mag

        ! Scale factor: mu*|f_n| / |f_t_trial|
        scale = mu * ABS(f_n) / f_t_mag

        ! K = scale * eps_t * (I_2 - n_t (x) n_t)
        DO i = 1, 2
          DO j = 1, 2
            K_friction(i,j) = scale * eps_t * (-n_t(i) * n_t(j))
          END DO
          K_friction(i,i) = K_friction(i,i) + scale * eps_t
        END DO
      END IF

    CASE DEFAULT
      ! OPEN: zero tangent (already initialized)
    END SELECT

  END SUBROUTINE PH_Cont_Friction_Compute_Tangent

END MODULE PH_Cont_Friction_Core
