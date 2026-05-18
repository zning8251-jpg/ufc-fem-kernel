!===============================================================================
! Module:  MD_Asm_Test
! Layer:   L3_MD
! Domain:  Assembly
! Purpose: Minimal test framework for the Assembly domain.
!          Verifies Init/Finalize and basic operations on MD_Assembly_Domain.
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE MD_Asm_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Asm_Mgr, ONLY: MD_Assembly_Domain, MD_Instance_Desc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Assembly_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE MD_Assembly_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_init_finalize()
    CALL test_add_instance()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[MD_Asm_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE MD_Assembly_Run_Tests

  SUBROUTINE test_init_finalize()
    TYPE(MD_Assembly_Domain) :: domain

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

  SUBROUTINE test_add_instance()
    TYPE(MD_Assembly_Domain) :: domain
    TYPE(MD_Instance_Desc)   :: inst

    CALL domain%Init()

    inst%name    = "PART-1-1"
    inst%inst_id = 1
    inst%part_ref = 1
    CALL domain%AddInstance(inst)

    IF (domain%n_instances == 1) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_add_instance — count"
    END IF

    CALL domain%Finalize()
  END SUBROUTINE test_add_instance

END MODULE MD_Asm_Test
