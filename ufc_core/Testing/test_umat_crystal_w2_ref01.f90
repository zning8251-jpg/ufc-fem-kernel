!===============================================================================
! test_umat_crystal_w2_ref01: W2-REF-01 single-increment regression (mat_id 266)
! Run: BUILD_TESTING=ON, ctest -R UMAT_CrystalW2Ref01
!
! Locked values: plan/changes/p1-material-crystal-w2-multislip/design.md §6
!===============================================================================
PROGRAM test_umat_crystal_w2_ref01
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE PH_Mat_Plast_Crystal_Core, ONLY: UF_CrystalPlasticity_UMAT, UF_CrystalPlasticity_UMAT_Arg, &
       PH_MAT_CRYSTAL_NPROPS_W2, PH_MAT_CRYSTAL_NSTATV_W2
  IMPLICIT NONE

  TYPE(UF_CrystalPlasticity_UMAT_Arg) :: arg
  REAL(wp), PARAMETER :: tol = 1.0e-6_wp
  REAL(wp) :: err

  CALL init_error_status(arg%status)
  arg%nprops = PH_MAT_CRYSTAL_NPROPS_W2
  arg%nstatev = PH_MAT_CRYSTAL_NSTATV_W2
  arg%ndir = 3_i4
  arg%nshr = 3_i4
  arg%ndim = 3_i4

  arg%props(1) = 200000.0_wp
  arg%props(2) = 0.3_wp
  arg%props(3) = 50.0_wp
  arg%props(4) = 1000.0_wp
  arg%props(5:7) = [0.0_wp, 0.0_wp, 1.0_wp]
  arg%props(8:10) = [1.0_wp, 0.0_wp, 0.0_wp]
  arg%props(11:13) = [0.0_wp, 1.0_wp, 0.0_wp]
  arg%props(14:16) = [0.0_wp, 0.0_wp, 1.0_wp]
  arg%props(17:19) = [0.0_wp, 0.0_wp, 1000.0_wp]

  arg%stress = 0.0_wp
  arg%statev = 0.0_wp
  arg%dstran = 0.0_wp
  arg%dstran(5) = 0.004_wp

  CALL UF_CrystalPlasticity_UMAT(arg)
  IF (arg%status%status_code /= IF_STATUS_OK) THEN
    WRITE(*, *) 'FAIL: UMAT status ', arg%status%status_code, TRIM(arg%status%message)
    STOP 1
  END IF

  err = ABS(arg%statev(1) - 0.003307009_wp)
  IF (err > tol) THEN
    WRITE(*, *) 'FAIL: gamma(1)=', arg%statev(1), ' err=', err
    STOP 1
  END IF
  IF (ABS(arg%statev(2)) > tol) THEN
    WRITE(*, *) 'FAIL: gamma(2)=', arg%statev(2)
    STOP 1
  END IF
  err = ABS(arg%stress(5) - 53.307009_wp)
  IF (err > tol) THEN
    WRITE(*, *) 'FAIL: stress(5)=', arg%stress(5), ' err=', err
    STOP 1
  END IF

  WRITE(*, *) 'PASS: W2-REF-01 crystal UMAT'
END PROGRAM test_umat_crystal_w2_ref01
