!===============================================================================
! Standalone test runner for P4 tests (no external dependencies)
! This file provides mock modules for testing
!===============================================================================

! Mock IF_Prec module
MODULE IF_Prec
  IMPLICIT NONE
  INTEGER, PARAMETER :: i4 = SELECTED_INT_KIND(9)
  INTEGER, PARAMETER :: wp = KIND(1.0D0)
END MODULE IF_Prec

! Mock IF_Const module
MODULE IF_Const
  USE IF_Prec_Core
  IMPLICIT NONE
  REAL(wp), PARAMETER :: ZERO = 0.0_wp
  REAL(wp), PARAMETER :: ONE = 1.0_wp
  REAL(wp), PARAMETER :: TWO = 2.0_wp
  REAL(wp), PARAMETER :: THREE = 3.0_wp
  REAL(wp), PARAMETER :: HALF = 0.5_wp
  REAL(wp), PARAMETER :: THIRD = 1.0_wp/3.0_wp
  REAL(wp), PARAMETER :: TWO_THIRD = 2.0_wp/3.0_wp
  REAL(wp), PARAMETER :: FOUR = 4.0_wp
END MODULE IF_Const
