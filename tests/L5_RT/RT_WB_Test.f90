!===============================================================================
! Module:  RT_WriteBack_Test
! Layer:   L5_RT
! Domain:  WriteBack
! Purpose: Test framework for the WriteBack domain.
!          Validates RT_WB_Def (AUTHORITY) four-type system and
!          RT_WriteBack_Def (LEGACY) wrapper types.
!
! Status: ACTIVE | Last verified: 2026-04-26
!
! Domain Pillar: P6 WriteBack
!   AUTHORITY: RT_WB_Def.f90
!   LEGACY:    RT_WriteBack_Def.f90
!===============================================================================
MODULE RT_WB_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_WriteBack_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_WriteBack_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_authority_desc()
    CALL test_authority_progress()
    CALL test_authority_buffer()
    CALL test_authority_algo()
    CALL test_authority_ctx()
    CALL test_legacy_types()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_WriteBack_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_WriteBack_Run_Tests

  SUBROUTINE test_authority_desc()
    USE RT_WB_Def, ONLY: RT_WB_Base_Desc, RT_WB_WRITE_EVERY_INC
    TYPE(RT_WB_Base_Desc) :: desc

    desc%runtime_id = 1_i4
    desc%write_frequency = 2_i4

    IF (desc%runtime_id == 1_i4 .AND. &
        desc%write_trigger == RT_WB_WRITE_EVERY_INC .AND. &
        .NOT. desc%is_initialized) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_desc"
    END IF
  END SUBROUTINE test_authority_desc

  SUBROUTINE test_authority_progress()
    USE RT_WB_Def, ONLY: RT_WB_ProgressState
    TYPE(RT_WB_ProgressState) :: ps

    IF (ps%total_writes == 0_i4 .AND. ps%last_write_successful) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_progress"
    END IF
  END SUBROUTINE test_authority_progress

  SUBROUTINE test_authority_buffer()
    USE RT_WB_Def, ONLY: RT_WB_BufferState
    TYPE(RT_WB_BufferState) :: bs

    IF (bs%flush_threshold == 1000_i4 .AND. &
        .NOT. bs%buffers_allocated) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_buffer"
    END IF
  END SUBROUTINE test_authority_buffer

  SUBROUTINE test_authority_algo()
    USE RT_WB_Def, ONLY: RT_WB_Algo
    TYPE(RT_WB_Algo) :: algo

    IF (algo%use_node_buffering .AND. algo%validate_before_write) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_algo"
    END IF
  END SUBROUTINE test_authority_algo

  SUBROUTINE test_authority_ctx()
    USE RT_WB_Def, ONLY: RT_WB_Ctx
    TYPE(RT_WB_Ctx) :: ctx

    IF (.NOT. ASSOCIATED(ctx%u_buffer) .AND. &
        ctx%buffer_size == 0_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_ctx"
    END IF
  END SUBROUTINE test_authority_ctx

  SUBROUTINE test_legacy_types()
    USE RT_WB_Def, ONLY: RT_WB_Desc, RT_WB_State
    TYPE(RT_WB_Desc)  :: desc
    TYPE(RT_WB_State) :: st

    IF (desc%n_maps == 0 .AND. st%wb_count == 0) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_legacy_types"
    END IF
  END SUBROUTINE test_legacy_types

END MODULE RT_WB_Test
