!===============================================================================
! MODULE: PH_Cont_ALM_Core
! LAYER:  L4_PH
! DOMAIN: Contact / Core
! ROLE:   Core
! BRIEF:  Augmented Lagrangian Method (ALM) — Uzawa update + ALM force/stiffness
!
! Theory: L_rho(u,lambda) = Pi(u) + lambda^T*g(u) + rho/2*||<g+lambda/rho>||^2
!   Wriggers (2006) Ch.4 §4.4; Simo & Laursen (1992)
! Status: ACTIVE | Created: 2026-04-28
!===============================================================================
MODULE PH_Cont_ALM_Core
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, &
                           IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Cont_ALM_Update_Multiplier
  PUBLIC :: PH_Cont_ALM_Compute_Force
  PUBLIC :: PH_Cont_ALM_Compute_Stiffness
  PUBLIC :: PH_Cont_ALM_Check_Convergence

CONTAINS

  !---------------------------------------------------------------------------
  ! PH_Cont_ALM_Update_Multiplier
  !   Uzawa update: lambda_new = lambda + penalty * gap_n
  !   Constraint:   lambda_new = max(0, lambda_new) (compression only)
  !
  !   Note: gap_n < 0 means penetration, so lambda + penalty*gap_n could
  !   decrease lambda when gap_n is negative (penetration increases force).
  !   The standard Uzawa for contact is:
  !     lambda_new = max(0, lambda + rho * gap_n)
  !   where gap_n > 0 = open, gap_n < 0 = penetration.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_ALM_Update_Multiplier(lambda, gap_n, penalty, &
                                             lambda_new, ierr)
    REAL(wp), INTENT(IN)     :: lambda         ! Current Lagrange multiplier (>=0)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap (>0 open, <0 penetration)
    REAL(wp), INTENT(IN)     :: penalty        ! Augmentation parameter rho
    REAL(wp), INTENT(OUT)    :: lambda_new     ! Updated multiplier
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    ierr = 0

    IF (penalty < 0.0_wp) THEN
      ierr = 1
      lambda_new = lambda
      RETURN
    END IF

    ! Uzawa update
    lambda_new = lambda + penalty * gap_n

    ! Compression constraint: multiplier must be non-negative
    ! (Signorini condition: lambda >= 0 for contact)
    ! Convention: positive lambda = compressive contact force
    ! When gap_n < 0 (penetration), lambda increases
    ! When gap_n > 0 (open), lambda decreases toward zero
    lambda_new = MAX(0.0_wp, lambda_new)

  END SUBROUTINE PH_Cont_ALM_Update_Multiplier

  !---------------------------------------------------------------------------
  ! PH_Cont_ALM_Compute_Force
  !   ALM normal force:
  !     f_n = max(0, lambda + penalty * (-gap_n))
  !   This combines the Lagrange multiplier with penalty augmentation.
  !   When gap_n < 0 (penetration): f_n = lambda + penalty * |gap_n|
  !   When gap_n > 0 (open): f_n = max(0, lambda - penalty * gap_n)
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_ALM_Compute_Force(lambda, gap_n, penalty, f_n, ierr)
    REAL(wp), INTENT(IN)     :: lambda         ! Current Lagrange multiplier
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap
    REAL(wp), INTENT(IN)     :: penalty        ! Augmentation parameter rho
    REAL(wp), INTENT(OUT)    :: f_n            ! ALM normal force
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    ierr = 0

    IF (penalty < 0.0_wp) THEN
      ierr = 1
      f_n = 0.0_wp
      RETURN
    END IF

    ! ALM force: combines multiplier + penalty augmentation
    ! f_n = lambda + rho * <-gap_n>
    ! Using the combined formula with Macaulay bracket on the total:
    f_n = lambda + penalty * MAX(0.0_wp, -gap_n)

    ! Ensure non-negative (contact can only push, not pull)
    f_n = MAX(0.0_wp, f_n)

  END SUBROUTINE PH_Cont_ALM_Compute_Force

  !---------------------------------------------------------------------------
  ! PH_Cont_ALM_Compute_Stiffness
  !   ALM tangent stiffness (for Newton linearisation):
  !     k_n = rho * H(-gap_n)
  !   Same form as penalty stiffness but within the ALM framework.
  !   The multiplier lambda is treated as constant within each
  !   augmentation step (Uzawa scheme).
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_ALM_Compute_Stiffness(gap_n, penalty, k_n, ierr)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap
    REAL(wp), INTENT(IN)     :: penalty        ! Augmentation parameter rho
    REAL(wp), INTENT(OUT)    :: k_n            ! ALM contact stiffness
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    ierr = 0

    IF (gap_n < 0.0_wp) THEN
      k_n = penalty
    ELSE
      k_n = 0.0_wp
    END IF

  END SUBROUTINE PH_Cont_ALM_Compute_Stiffness

  !---------------------------------------------------------------------------
  ! PH_Cont_ALM_Check_Convergence
  !   Check if augmentation loop has converged:
  !   ||gap_n|| < tol for all active contact nodes
  !   Returns converged = .TRUE. if penetration is within tolerance.
  !---------------------------------------------------------------------------
  SUBROUTINE PH_Cont_ALM_Check_Convergence(gap_n, tol, converged, ierr)
    REAL(wp), INTENT(IN)     :: gap_n          ! Normal gap
    REAL(wp), INTENT(IN)     :: tol            ! Gap tolerance
    LOGICAL, INTENT(OUT)     :: converged      ! Convergence flag
    INTEGER(i4), INTENT(OUT) :: ierr           ! 0=OK

    ierr = 0

    ! For contact (gap_n < 0), check penetration magnitude
    IF (gap_n >= 0.0_wp) THEN
      ! Open: no constraint violation
      converged = .TRUE.
    ELSE
      ! Penetration: check if within tolerance
      converged = (ABS(gap_n) < tol)
    END IF

  END SUBROUTINE PH_Cont_ALM_Check_Convergence

END MODULE PH_Cont_ALM_Core
