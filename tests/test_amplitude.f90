!===============================================================================
! Program: test_amplitude
! Purpose: Regression checks for L3_MD Amplitude — UF vs MD_Amp_Domain
!          via MD_Amp_Slot_To_MD_Desc (tabular extrapolate, periodic, decay,
!          modulated, smooth, ramp).
! Build: -DBUILD_TESTING=ON with ufc_core (links ufc_core).
!===============================================================================
PROGRAM test_amplitude
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_API, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Amp_Def, ONLY: MD_Amp_Domain, MD_Amp_Desc, &
      AMP_TABULAR, AMP_SMOOTH, AMP_RAMP, AMP_PERIODIC, AMP_DECAY, AMP_MODULATED
  USE MD_Amp_UF, ONLY: MD_Amp_Slot_Desc
  USE MD_Amp_Mgr, ONLY: MD_Amp_Slot_To_MD_Desc
  IMPLICIT NONE

  CALL run_all()
CONTAINS

  SUBROUTINE assert_near(a, b, tol, msg)
    REAL(wp), INTENT(IN) :: a, b, tol
    CHARACTER(LEN=*), INTENT(IN) :: msg
    IF (ABS(a - b) > tol) THEN
      PRINT *, "FAIL: ", TRIM(msg), " got=", a, " expected=", b
      ERROR STOP 1
    END IF
  END SUBROUTINE assert_near

  SUBROUTINE uf_md_check(uf, t_query, msg)
    TYPE(MD_Amp_Slot_Desc), INTENT(INOUT) :: uf
    REAL(wp), INTENT(IN) :: t_query
    CHARACTER(LEN=*), INTENT(IN) :: msg
    TYPE(MD_Amp_Desc) :: md
    TYPE(MD_Amp_Domain) :: dom
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: v_uf, v_md

    CALL MD_Amp_Slot_To_MD_Desc(uf, md)
    CALL dom%Init(8_i4, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      PRINT *, "FAIL Init domain ", TRIM(msg)
      ERROR STOP 1
    END IF
    CALL dom%AddAmplitude(md, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      PRINT *, "FAIL AddAmplitude ", TRIM(msg)
      ERROR STOP 1
    END IF
    v_uf = uf%evaluate(t_query)
    CALL dom%EvalAtTime(1_i4, t_query, v_md, st)
    IF (st%status_code /= IF_STATUS_OK) THEN
      PRINT *, "FAIL EvalAtTime status ", TRIM(msg)
      ERROR STOP 1
    END IF
    CALL assert_near(v_md, v_uf, 1.0E-12_wp, msg)
    CALL dom%Finalize()
  END SUBROUTINE uf_md_check

  SUBROUTINE run_all()
    TYPE(MD_Amp_Slot_Desc) :: uf
    REAL(wp), PARAMETER :: tol = 1.0E-10_wp

    PRINT *, "test_amplitude: tabular"
    CALL uf%init("tbl", AMP_TABULAR)
    CALL uf%add_point(0.0_wp, 0.0_wp)
    CALL uf%add_point(1.0_wp, 1.0_wp)
    CALL uf_md_check(uf, 0.25_wp, "tabular interior")

    PRINT *, "test_amplitude: tabular extrapolate"
    uf%tabular_extrapolate = .TRUE.
    CALL assert_near(uf%evaluate(2.0_wp), 2.0_wp, tol, "uf extrapolated")
    CALL uf_md_check(uf, 2.0_wp, "md tabular extrapolate")

    PRINT *, "test_amplitude: smooth step"
    CALL uf%set_smooth_step(0.0_wp, 1.0_wp, 0.0_wp, 1.0_wp)
    CALL uf_md_check(uf, 0.5_wp, "smooth mid")

    PRINT *, "test_amplitude: ramp"
    CALL uf%set_ramp(2.0_wp)
    CALL uf_md_check(uf, 1.0_wp, "ramp half")

    PRINT *, "test_amplitude: periodic"
    CALL uf%set_periodic(1.0_wp, 0.5_wp, 0.1_wp, 0.2_wp)
    CALL uf_md_check(uf, 0.37_wp, "periodic")

    PRINT *, "test_amplitude: decay"
    uf%amp_type = AMP_DECAY
    uf%decay_a0 = 2.0_wp
    uf%decay_rate = 0.5_wp
    CALL uf_md_check(uf, 1.0_wp, "decay")

    PRINT *, "test_amplitude: modulated"
    CALL uf%set_modulated(2.0_wp, 1.0_wp, phase=0.0_wp, mod_freq=0.25_wp, mod_depth=0.3_wp)
    CALL uf_md_check(uf, 0.41_wp, "modulated")

    PRINT *, "test_amplitude: native MD_SMOOTH vs UF"
    CALL test_native_smooth()

    PRINT *, "test_amplitude: OK"
  END SUBROUTINE run_all

  SUBROUTINE test_native_smooth()
    TYPE(MD_Amp_Domain) :: dom
    TYPE(MD_Amp_Desc) :: md
    TYPE(MD_Amp_Slot_Desc) :: uf
    TYPE(ErrorStatusType) :: st
    REAL(wp) :: v

    CALL init_error_status(st)
    md%name = "s0"
    md%amp_type = AMP_SMOOTH
    md%smooth_t1 = 0.0_wp
    md%smooth_t2 = 1.0_wp
    md%smooth_a1 = 0.0_wp
    md%smooth_a2 = 1.0_wp
    CALL uf%set_smooth_step(0.0_wp, 1.0_wp, 0.0_wp, 1.0_wp)
    CALL dom%Init(4_i4, st)
    CALL dom%AddAmplitude(md, st)
    CALL dom%EvalAtTime(1_i4, 0.5_wp, v, st)
    CALL assert_near(v, uf%evaluate(0.5_wp), 1.0E-12_wp, "native smooth vs uf")
    CALL dom%Finalize()
  END SUBROUTINE test_native_smooth

END PROGRAM test_amplitude
