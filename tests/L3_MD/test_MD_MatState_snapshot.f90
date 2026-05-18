!===============================================================================
! PROGRAM: test_MD_MatState_snapshot
! PURPOSE: Phase6 §1.3 — MD_MatState Snapshot/RestoreInto via MD_Mat_Def (linked build).
! Build: python tools/phase6_fortran_run.py --test matstate --linked
!===============================================================================
PROGRAM test_MD_MatState_snapshot
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_MatState, MD_MatState_Init_Base, MD_MatState_Snapshot, &
                        MD_MatState_RestoreInto, MD_MAT_STATUS_OK
  IMPLICIT NONE
  TYPE(MD_MatState), TARGET :: src, snap, dst
  TYPE(ErrorStatusType) :: status
  INTEGER(i4) :: i
  LOGICAL :: ok

  CALL MD_MatState_Init_Base(src)
  CALL MD_MatState_Init_Base(dst)
  ALLOCATE(src%stateV(4), src%stress(6))
  src%stateV = (/ 1.0_wp, 2.0_wp, 3.0_wp, 4.0_wp /)
  src%stress = (/ 10.0_wp, 20.0_wp, 30.0_wp, 40.0_wp, 50.0_wp, 60.0_wp /)
  src%nIntPoints = 1_i4

  CALL MD_MatState_Snapshot(src, snap, status)
  IF (status%status_code /= MD_MAT_STATUS_OK) THEN
    WRITE(*, '(A)') '[track13] Snapshot failed'
    STOP 1
  END IF

  src%stateV = 0.0_wp
  src%stress = 0.0_wp

  CALL MD_MatState_RestoreInto(src, snap, status)
  IF (status%status_code /= MD_MAT_STATUS_OK) THEN
    WRITE(*, '(A)') '[track13] RestoreInto failed'
    STOP 1
  END IF

  ok = .TRUE.
  DO i = 1, 4
    IF (ABS(src%stateV(i) - snap%stateV(i)) > 1.0E-12_wp) ok = .FALSE.
  END DO
  DO i = 1, 6
    IF (ABS(src%stress(i) - snap%stress(i)) > 1.0E-12_wp) ok = .FALSE.
  END DO

  IF (.NOT. ok) THEN
    WRITE(*, '(A)') '[track13] MD_MatState snapshot round-trip FAILED'
    STOP 1
  END IF
  WRITE(*, '(A)') '[track13] MD_MatState snapshot round-trip OK'
  STOP 0
END PROGRAM test_MD_MatState_snapshot
