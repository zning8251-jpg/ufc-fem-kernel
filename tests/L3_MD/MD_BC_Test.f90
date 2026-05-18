!===============================================================================
! Module:  MD_BC_Test
! Layer:   L3_MD
! Domain:  Boundary (LBC)
! Purpose: Minimal test framework for the Boundary domain.
!          Verifies Init/Finalize and basic operations on MD_LoadBC_Domain.
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE MD_BC_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_LBC_Domain, ONLY: MD_LoadBC_Domain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Boundary_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE MD_Boundary_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[MD_BC_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE MD_Boundary_Run_Tests

  SUBROUTINE test_init_finalize()
    TYPE(MD_LoadBC_Domain) :: domain

    CALL domain%Init()
    IF (domain%initialized) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize — Init"
    END IF

    CALL domain%Finalize()
    IF (.NOT. domain%initialized) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_init_finalize — Finalize"
    END IF
  END SUBROUTINE test_init_finalize

END MODULE MD_BC_Test
