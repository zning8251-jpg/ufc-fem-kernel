!===============================================================================
! PROGRAM: test_RT_NLSolver_ArcLen_min
! PURPOSE: Phase6 §1.2 — call RT_NLSolver_ArcLen without assembly; expect IF_STATUS_INVALID.
! Build: python tools/phase6_fortran_run.py --test arclen
!===============================================================================
PROGRAM test_RT_NLSolver_ArcLen_min
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_INVALID
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Step_Proc, ONLY: MD_NonlinSolv, MD_SolverState
  USE RT_Solv_Nonlin, ONLY: RT_NLSolver_ArcLen
  IMPLICIT NONE
  TYPE(MD_NonlinSolv) :: solver
  TYPE(MD_SolverState) :: state
  TYPE(ErrorStatusType) :: status
  LOGICAL :: result

  solver%method = 4_i4
  solver%max_iterations = 10_i4
  solver%arc_constraint_tol_scale = 1.0E-3_wp
  solver%arc_nonconverge_use_warn = .TRUE.
  ALLOCATE(state%u(2))
  state%u = 0.0_wp

  CALL init_error_status(status)
  CALL RT_NLSolver_ArcLen(solver, state, result, status)

  IF (result) THEN
    WRITE(*, '(A)') '[track12] expected result=.FALSE.'
    STOP 1
  END IF
  IF (status%status_code /= IF_STATUS_INVALID) THEN
    WRITE(*, '(A,I0)') '[track12] expected IF_STATUS_INVALID, got ', status%status_code
    STOP 1
  END IF
  IF (INDEX(status%message, 'assembly path required') == 0) THEN
    WRITE(*, '(A)') '[track12] missing assembly path required in message'
    STOP 1
  END IF

  WRITE(*, '(A)') '[track12] ArcLen entry smoke OK'
  STOP 0
END PROGRAM test_RT_NLSolver_ArcLen_min
