!===============================================================================
! Module:  MD_Constr_Test
! Layer:   L3_MD
! Domain:  Constraint
! Purpose: Minimal test framework for the Constraint domain.
!          Verifies Init/Finalize via MD_Constr_Mgr (production API).
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE MD_Constr_Test
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg,   ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Constr_Mgr, ONLY: MD_Constraint_Domain
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Constraint_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE MD_Constraint_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[MD_Constr_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE MD_Constraint_Run_Tests

  SUBROUTINE test_init_finalize()
    TYPE(MD_Constraint_Domain) :: domain
    TYPE(ErrorStatusType)      :: status

    CALL domain%Init(status)
    IF (status%status_code /= IF_STATUS_OK) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: Init returned non-OK status"
      RETURN
    END IF

    IF (.NOT. domain%initialized) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: domain not marked initialized after Init"
      RETURN
    END IF

    CALL domain%Finalize()

    IF (domain%initialized) THEN
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: domain still marked initialized after Finalize"
      RETURN
    END IF

    n_passed = n_passed + 1
  END SUBROUTINE test_init_finalize

END MODULE MD_Constr_Test
