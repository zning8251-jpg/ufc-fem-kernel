!===============================================================================
! Module:  RT_Output_Test
! Layer:   L5_RT
! Domain:  Output
! Purpose: Test framework for the Output domain.
!          Validates RT_Out_Def (AUTHORITY) four-type system and
!          RT_Output_Def (LEGACY) wrapper types.
!
! Status: ACTIVE | Last verified: 2026-04-26
!
! Domain Pillar: P5 Output
!   AUTHORITY: RT_Out_Def.f90
!   LEGACY:    RT_Output_Def.f90
!===============================================================================
MODULE RT_Out_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Output_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_Output_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_authority_desc()
    CALL test_authority_field_state()
    CALL test_authority_hist_state()
    CALL test_authority_algo()
    CALL test_authority_ctx()
    CALL test_legacy_types()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_Output_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_Output_Run_Tests

  SUBROUTINE test_authority_desc()
    USE RT_Out_Def, ONLY: RT_Out_Base_Desc, RT_OUT_FMT_VTK
    TYPE(RT_Out_Base_Desc) :: desc

    desc%runtime_id = 1_i4
    desc%output_format = RT_OUT_FMT_VTK

    IF (desc%runtime_id == 1_i4 .AND. .NOT. desc%is_initialized) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_desc"
    END IF
  END SUBROUTINE test_authority_desc

  SUBROUTINE test_authority_field_state()
    USE RT_Out_Def, ONLY: RT_Out_FieldState
    TYPE(RT_Out_FieldState) :: fs

    IF (fs%n_frames_written == 0_i4 .AND. fs%inc_interval == 1_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_field_state"
    END IF
  END SUBROUTINE test_authority_field_state

  SUBROUTINE test_authority_hist_state()
    USE RT_Out_Def, ONLY: RT_Out_HistState
    TYPE(RT_Out_HistState) :: hs

    IF (hs%n_points_written == 0_i4 .AND. hs%buffer_max_points == 100_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_hist_state"
    END IF
  END SUBROUTINE test_authority_hist_state

  SUBROUTINE test_authority_algo()
    USE RT_Out_Def, ONLY: RT_Out
    TYPE(RT_Out) :: algo

    IF (algo%field_freq_incr == 1_i4 .AND. algo%use_field_buffer) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_algo"
    END IF
  END SUBROUTINE test_authority_algo

  SUBROUTINE test_authority_ctx()
    USE RT_Out_Def, ONLY: RT_Out_Ctx
    TYPE(RT_Out_Ctx) :: ctx

    IF (ctx%step_id == 0_i4 .AND. .NOT. ctx%suppress_all_output) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_authority_ctx"
    END IF
  END SUBROUTINE test_authority_ctx

  SUBROUTINE test_legacy_types()
    USE RT_Out_Def, ONLY: RT_Output_Desc, RT_Output_State, RT_Output_Ctx
    TYPE(RT_Output_Desc)  :: desc
    TYPE(RT_Output_State) :: st
    TYPE(RT_Output_Ctx)   :: ctx

    IF (desc%output_freq == 1 .AND. st%frame_count == 0 .AND. &
        ctx%buf_size == 0) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_legacy_types"
    END IF
  END SUBROUTINE test_legacy_types

END MODULE RT_Out_Test
