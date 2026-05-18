!===============================================================================
! Module: TEST_RT_LoadBC_Output
! Purpose: Targeted tests for current LoadBC reaction/output support utilities.
!===============================================================================
MODULE TEST_RT_LoadBC_Output
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: IF_STATUS_OK, ErrorStatusType
  USE RT_BC_Impl_Def, ONLY: RT_BC_Impl_State
  USE RT_BC_Brg, ONLY: RT_BC_Brg_WriteBack
  USE RT_BC_ReactionForce, ONLY: RT_BC_Apply_In, RT_BC_Apply_Constraints, &
                                 RT_BC_Compute_Reactions
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: Run_RT_LoadBC_Output_Tests

  REAL(wp), PARAMETER :: TOL = 1.0e-10_wp
  INTEGER(i4) :: n_passed = 0_i4
  INTEGER(i4) :: n_failed = 0_i4

CONTAINS

  SUBROUTINE Run_RT_LoadBC_Output_Tests(all_passed)
    LOGICAL, INTENT(OUT) :: all_passed

    n_passed = 0_i4
    n_failed = 0_i4

    CALL Test_Reaction_Vector_Copy()
    CALL Test_WriteBack_Summary()
    CALL Test_Constraint_Apply()

    all_passed = (n_failed == 0_i4)
    WRITE(*,'(A,I4,A,I4,A)') '[TEST_RT_LoadBC_Output] ', n_passed, ' passed, ', &
                              n_failed, ' failed'
  END SUBROUTINE Run_RT_LoadBC_Output_Tests

  SUBROUTINE Test_Reaction_Vector_Copy()
    REAL(wp) :: f_ext(6)
    REAL(wp), ALLOCATABLE :: f_reaction(:)
    TYPE(ErrorStatusType) :: status

    f_ext = [1.0_wp, -2.0_wp, 3.0_wp, -4.0_wp, 5.0_wp, -6.0_wp]
    CALL RT_BC_Compute_Reactions(f_ext, f_reaction, status)

    CALL assert_true(status%status_code == IF_STATUS_OK, 'reaction copy status ok')
    CALL assert_true(ALLOCATED(f_reaction), 'reaction vector allocated')
    CALL assert_true(ALL(ABS(f_reaction - f_ext) < TOL), 'reaction vector copied exactly')

    IF (ALLOCATED(f_reaction)) DEALLOCATE(f_reaction)
  END SUBROUTINE Test_Reaction_Vector_Copy

  SUBROUTINE Test_WriteBack_Summary()
    TYPE(RT_BC_Impl_State) :: state
    REAL(wp) :: total_ext_work, max_reaction
    TYPE(ErrorStatusType) :: status

    state%accumulated_work = 12.5_wp
    CALL RT_BC_Brg_WriteBack(state, total_ext_work, max_reaction, status)

    CALL assert_true(status%status_code == IF_STATUS_OK, 'writeback status ok')
    CALL assert_true(ABS(total_ext_work - 12.5_wp) < TOL, 'writeback returns accumulated work')
    CALL assert_true(ABS(max_reaction) < TOL, 'writeback keeps max reaction placeholder')
  END SUBROUTINE Test_WriteBack_Summary

  SUBROUTINE Test_Constraint_Apply()
    TYPE(RT_BC_Apply_In) :: apply_in
    REAL(wp) :: k_global(3,3), f_global(3)
    TYPE(ErrorStatusType) :: status

    k_global = 0.0_wp
    k_global(1,1) = 10.0_wp
    k_global(2,2) = 20.0_wp
    k_global(3,3) = 30.0_wp
    f_global = 0.0_wp

    apply_in%n_nodes = 1_i4
    apply_in%dof = 2_i4
    apply_in%apply_method = 2_i4
    ALLOCATE(apply_in%node_ids(1), apply_in%bc_values(1))
    apply_in%node_ids = [1_i4]
    apply_in%bc_values = [1.25_wp]

    CALL RT_BC_Apply_Constraints(apply_in, k_global, f_global, status)

    CALL assert_true(status%status_code == IF_STATUS_OK, 'constraint apply status ok')
    CALL assert_true(ABS(k_global(2,2) - 1.0_wp) < TOL, 'constraint apply writes unit diagonal')
    CALL assert_true(ABS(f_global(2) - 1.25_wp) < TOL, 'constraint apply writes prescribed value')

    DEALLOCATE(apply_in%node_ids, apply_in%bc_values)
  END SUBROUTINE Test_Constraint_Apply

  SUBROUTINE assert_true(condition, message)
    LOGICAL, INTENT(IN) :: condition
    CHARACTER(len=*), INTENT(IN) :: message

    IF (condition) THEN
      n_passed = n_passed + 1_i4
    ELSE
      n_failed = n_failed + 1_i4
      WRITE(*,'(A,A)') '  FAIL: ', TRIM(message)
    END IF
  END SUBROUTINE assert_true

END MODULE TEST_RT_LoadBC_Output
