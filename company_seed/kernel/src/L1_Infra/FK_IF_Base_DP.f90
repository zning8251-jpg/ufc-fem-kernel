! FK_IF_Base_DP.f90
! L1_Infra — Double-precision base types (template)
!
! Architectural pattern:
!   - Central precision definitions used by all layers
!   - I4/I8 for integers, SP/DP for reals
!   - WP (working precision) as configurable alias

MODULE FK_IF_Base_DP
  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: &
    I4  => INT32,   &
    I8  => INT64,   &
    SP  => REAL32,  &
    DP  => REAL64

  IMPLICIT NONE
  PRIVATE

  !══════════════════════════════════════════════════════
  ! PUBLIC PRECISION TYPES
  !══════════════════════════════════════════════════════
  PUBLIC :: I4, I8, SP, DP, WP

  ! Working precision — change to SP for single-precision builds
  INTEGER, PARAMETER :: WP = DP

END MODULE FK_IF_Base_DP
