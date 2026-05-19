!===============================================================================
! MODULE: PH_Mat_Creep_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Creep
! ROLE:   Eval (legacy point-model SIO — C2 split from PH_MatEval)
! BRIEF:  Norton creep rate point Eval.
! Purpose: Family-owned Arg types for legacy creep call paths.
! Theory: Norton power-law creep rate vs stress/temperature.
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Creep_PointEval
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_CreepNorton_Eval_Arg, PH_Mat_CreepNorton_Eval

  TYPE, PUBLIC :: PH_Mat_CreepNorton_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: creep_rate(6) = 0.0_wp
    REAL(wp) :: temperature = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_CreepNorton_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_CreepNorton_Eval(arg)
    TYPE(PH_Mat_CreepNorton_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: A, n_exp, Q_act, R_gas
    REAL(wp) :: sigma_eqv, s_dev(6), creep_rate_scalar, temp_factor
    INTEGER(i4) :: i
    CALL init_error_status(arg%status)
    A = arg%mat_desc%creep_A
    n_exp = arg%mat_desc%creep_n
    Q_act = arg%mat_desc%creep_Q
    R_gas = arg%mat_desc%R_gas
    s_dev(1) = arg%sigma(1) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(2) = arg%sigma(2) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(3) = arg%sigma(3) - (arg%sigma(1) + arg%sigma(2) + arg%sigma(3)) / THREE
    s_dev(4) = arg%sigma(4)
    s_dev(5) = arg%sigma(5)
    s_dev(6) = arg%sigma(6)
    sigma_eqv = SQRT(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                               TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    creep_rate_scalar = A * sigma_eqv**n_exp
    IF (arg%temperature > 1.0e-12_wp .AND. Q_act > ZERO) THEN
      temp_factor = EXP(-Q_act / (R_gas * arg%temperature))
      creep_rate_scalar = creep_rate_scalar * temp_factor
    END IF
    IF (sigma_eqv > 1.0e-12_wp) THEN
      DO i = 1, 6
        arg%creep_rate(i) = 1.5_wp * creep_rate_scalar * s_dev(i) / sigma_eqv
      END DO
    ELSE
      arg%creep_rate = ZERO
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_CreepNorton_Eval

END MODULE PH_Mat_Creep_PointEval
