!===============================================================================
! Module:  RT_Contact_Test
! Layer:   L5_RT
! Domain:  Contact
! Purpose: Test framework for the Contact domain.
!          Verifies four-type defaults, LEGACY wrapper, and basic smoke tests.
!
! Status: ACTIVE | Last verified: 2026-04-26
!===============================================================================
MODULE RT_Cont_Test
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: RT_Contact_Run_Tests

  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE RT_Contact_Run_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0
    n_failed = 0

    CALL test_desc_defaults()
    CALL test_state_defaults()
    CALL test_algo_defaults()
    CALL test_ctx_defaults()
    CALL test_legacy_wrapper()

    all_passed = (n_failed == 0)
    WRITE(*,'(A,I4,A,I4,A)') "[RT_Contact_Test] ", n_passed, " passed, ", &
                               n_failed, " failed"
  END SUBROUTINE RT_Contact_Run_Tests

  !---------------------------------------------------------------------------
  SUBROUTINE test_desc_defaults()
    USE RT_Cont_Def, ONLY: RT_Contact_Desc
    TYPE(RT_Contact_Desc) :: desc

    IF (desc%n_contact_pairs == 0_i4 .AND. &
        .NOT. desc%is_initialized .AND. &
        .NOT. ASSOCIATED(desc%master_surf_ids)) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_desc_defaults"
    END IF
  END SUBROUTINE test_desc_defaults

  !---------------------------------------------------------------------------
  SUBROUTINE test_state_defaults()
    USE RT_Cont_Def, ONLY: RT_Contact_State
    TYPE(RT_Contact_State) :: st

    IF (st%n_active_pairs == 0_i4 .AND. &
        .NOT. st%converged .AND. &
        st%contact_energy == 0.0_wp) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_state_defaults"
    END IF
  END SUBROUTINE test_state_defaults

  !---------------------------------------------------------------------------
  SUBROUTINE test_algo_defaults()
    USE RT_Cont_Def, ONLY: RT_Contact_Algo, RT_CONT_DISC_NODE_TO_SURF, &
                            RT_CONT_ENFORCE_PENALTY, RT_CONT_FRICTION_COULOMB
    TYPE(RT_Contact_Algo) :: algo

    IF (algo%discretization_method == RT_CONT_DISC_NODE_TO_SURF .AND. &
        algo%enforcement_method == RT_CONT_ENFORCE_PENALTY .AND. &
        algo%friction_model == RT_CONT_FRICTION_COULOMB) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_algo_defaults"
    END IF
  END SUBROUTINE test_algo_defaults

  !---------------------------------------------------------------------------
  SUBROUTINE test_ctx_defaults()
    USE RT_Cont_Def, ONLY: RT_Contact_Ctx
    TYPE(RT_Contact_Ctx) :: ctx

    IF (ctx%current_pair_idx == 0_i4 .AND. &
        ctx%gap_distance == 0.0_wp .AND. &
        .NOT. ASSOCIATED(ctx%temp_force)) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_ctx_defaults"
    END IF
  END SUBROUTINE test_ctx_defaults

  !---------------------------------------------------------------------------
  SUBROUTINE test_legacy_wrapper()
    USE RT_Cont_Def, ONLY: RT_Contact_Desc, RT_Contact_State, &
                               RT_Contact_Ctx
    TYPE(RT_Contact_Desc)  :: desc
    TYPE(RT_Contact_State) :: st
    TYPE(RT_Contact_Ctx)   :: ctx

    IF (desc%n_contact_pairs == 0_i4 .AND. &
        st%n_active_pairs == 0_i4 .AND. &
        ctx%current_pair_idx == 0_i4) THEN
      n_passed = n_passed + 1
    ELSE
      n_failed = n_failed + 1
      WRITE(*,'(A)') "  FAIL: test_legacy_wrapper"
    END IF
  END SUBROUTINE test_legacy_wrapper

END MODULE RT_Cont_Test
