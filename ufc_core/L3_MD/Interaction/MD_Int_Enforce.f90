!======================================================================
! MODULE:  MD_Int_Enforce
! LAYER:   L3_MD
! DOMAIN:  Interaction
! ROLE:    Impl
! BRIEF:   Contact constraint enforcement methods.
!          Penalty, Lagrange multiplier, and augmented Lagrange.
!          Extracted from original MD_Int_API monolith.
! STATUS:  FOUR-TYPE-REFACTORED
! DATE:    2026-04-28
!======================================================================

MODULE MD_Int_Enforce
  USE MD_Int_Types
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! PUBLIC: Direct procedures
  !--------------------------------------------------------------------
  PUBLIC :: MD_Int_EnforcePenalty
  PUBLIC :: MD_Int_EnforceAugLagr
  PUBLIC :: MD_Int_EnforceLagrMult
  PUBLIC :: MD_Int_UpdateMultipliers

CONTAINS

  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_EnforceAugLagr
  ! PHASE:      P1
  ! PURPOSE:    Augmented Lagrange enforcement method
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_EnforceAugLagr(penalty_n, gap, lambda, &
                                   contact_force, contact_pressur, &
                                   converged, tol)
    REAL(wp), INTENT(IN)              :: penalty_n       ! [in]    Normal penalty
    REAL(wp), INTENT(IN)              :: gap              ! [in]    Gap distance
    REAL(wp), INTENT(INOUT)           :: lambda           ! [inout] Lagrange multiplier
    REAL(wp), INTENT(OUT)             :: contact_force    ! [out]   Contact force
    REAL(wp), INTENT(OUT)             :: contact_pressur  ! [out]   Contact pressure
    LOGICAL,  INTENT(OUT)             :: converged        ! [out]   Convergence flag
    REAL(wp), INTENT(IN), OPTIONAL    :: tol              ! [in]    Convergence tolerance

    REAL(wp) :: tolerance

    tolerance = 1.0E-6_wp
    IF (PRESENT(tol)) tolerance = tol

    IF (gap < 0.0_wp) THEN
      contact_pressur = MAX(0.0_wp, lambda + penalty_n * gap)
    ELSE
      contact_pressur = 0.0_wp
    END IF

    contact_force = contact_pressur
    converged = (ABS(gap) < tolerance)
  END SUBROUTINE MD_Int_EnforceAugLagr


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_EnforceLagrMult
  ! PHASE:      P1
  ! PURPOSE:    Lagrange multiplier enforcement method
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_EnforceLagrMult(gap, lambda, contact_force, contact_pressur)
    REAL(wp), INTENT(IN)    :: gap              ! [in]    Gap distance
    REAL(wp), INTENT(INOUT) :: lambda           ! [inout] Lagrange multiplier
    REAL(wp), INTENT(OUT)   :: contact_force    ! [out]   Contact force
    REAL(wp), INTENT(OUT)   :: contact_pressur  ! [out]   Contact pressure

    IF (gap < 0.0_wp) THEN
      contact_pressur = lambda
    ELSE
      contact_pressur = 0.0_wp
    END IF

    contact_force = contact_pressur
  END SUBROUTINE MD_Int_EnforceLagrMult


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_EnforcePenalty
  ! PHASE:      P1
  ! PURPOSE:    Penalty enforcement method
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_EnforcePenalty(penalty_n, gap, contact_force, contact_pressur)
    REAL(wp), INTENT(IN)  :: penalty_n        ! [in]  Normal penalty stiffness
    REAL(wp), INTENT(IN)  :: gap              ! [in]  Gap distance
    REAL(wp), INTENT(OUT) :: contact_force    ! [out] Contact force
    REAL(wp), INTENT(OUT) :: contact_pressur  ! [out] Contact pressure

    IF (gap < 0.0_wp) THEN
      contact_pressur = -penalty_n * gap
      contact_force   = contact_pressur
    ELSE
      contact_pressur = 0.0_wp
      contact_force   = 0.0_wp
    END IF
  END SUBROUTINE MD_Int_EnforcePenalty


  !--------------------------------------------------------------------
  ! SUBROUTINE: MD_Int_UpdateMultipliers
  ! PHASE:      P1
  ! PURPOSE:    Update Lagrange multipliers iteratively (ALM loop)
  !--------------------------------------------------------------------
  SUBROUTINE MD_Int_UpdateMultipliers(lambda, gap, penalty_n, max_iter, tol)
    REAL(wp), INTENT(INOUT)           :: lambda(:)       ! [inout] Multiplier array
    REAL(wp), INTENT(IN)              :: gap(:)           ! [in]    Gap array
    REAL(wp), INTENT(IN)              :: penalty_n        ! [in]    Penalty stiffness
    INTEGER(i4), INTENT(IN), OPTIONAL :: max_iter         ! [in]    Max ALM iterations
    REAL(wp), INTENT(IN), OPTIONAL    :: tol              ! [in]    Convergence tol

    INTEGER(i4) :: iter, max_iter_local, i
    REAL(wp)    :: tolerance, lambda_old
    LOGICAL     :: converged

    max_iter_local = MD_INT_MAX_ALM_ITER
    IF (PRESENT(max_iter)) max_iter_local = max_iter

    tolerance = 1.0E-6_wp
    IF (PRESENT(tol)) tolerance = tol

    DO iter = 1, max_iter_local
      converged = .TRUE.
      DO i = 1, SIZE(lambda)
        lambda_old = lambda(i)
        IF (gap(i) < 0.0_wp) THEN
          lambda(i) = MAX(0.0_wp, lambda(i) + penalty_n * gap(i))
        ELSE
          lambda(i) = 0.0_wp
        END IF
        IF (ABS(lambda(i) - lambda_old) > tolerance) THEN
          converged = .FALSE.
        END IF
      END DO
      IF (converged) EXIT
    END DO
  END SUBROUTINE MD_Int_UpdateMultipliers

END MODULE MD_Int_Enforce
