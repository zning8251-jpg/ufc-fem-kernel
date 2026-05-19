!===============================================================================
! MODULE: PH_Mat_Plast_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Plast
! ROLE:   Eval (legacy point-model SIO from plan C2 split)
! BRIEF:  J2 / Hill48 point Eval; absorbed from Dispatch/PH_MatEval.
! Purpose: Family-owned plastic point Eval; elastic trial via PH_Mat_Elas_PointEval.
! Theory: J2 and Hill48 radial return with isotropic hardening.
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_PointEval
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc, MD_PlasticMatDesc
  USE PH_Mat_Elas_PointEval, ONLY: PH_Mat_ElasticIsotropic_Eval_Arg, PH_Mat_ElasticIsotropic_Eval
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
  PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
  PUBLIC :: PH_Mat_PlasticVonMises_Eval
  PUBLIC :: PH_Mat_PlasticHill_Eval

  TYPE, PUBLIC :: PH_Mat_PlasticVonMises_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc
    REAL(wp) :: strain_increment(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: stress_new(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_PlasticVonMises_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_PlasticHill_Eval_Arg
    TYPE(MD_PlasticMatDesc) :: mat_desc
    REAL(wp) :: strain_increment(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: stress_new(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: equiv_plastic_strain
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_PlasticHill_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_PlasticHill_Eval(arg)
    TYPE(PH_Mat_PlasticHill_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: PH_MAT_E, nu, sigma_y0, H
    REAL(wp) :: F, G, Hh, L, M, N
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: sigma_y, phi_trial, phi_factor
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in

    CALL init_error_status(arg%status)
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    sigma_y0 = arg%mat_desc%yieldStress
    H = arg%mat_desc%hardeningModulus
    F = arg%mat_desc%Hill_F
    G = arg%mat_desc%Hill_G
    Hh = arg%mat_desc%Hill_H
    L = arg%mat_desc%Hill_L
    M = arg%mat_desc%Hill_M
    N = arg%mat_desc%Hill_N
    sigma_y = sigma_y0 + H * arg%equiv_plastic_strain
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = PH_MAT_E
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain_increment
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_trial = elastic_in%sigma
    stress_trial = arg%stress_old + stress_trial
    phi_trial = SQRT( &
      F * (stress_trial(2) - stress_trial(3))**2 + &
      G * (stress_trial(3) - stress_trial(1))**2 + &
      Hh * (stress_trial(1) - stress_trial(2))**2 + &
      TWO * L * stress_trial(4)**2 + &
      TWO * M * stress_trial(5)**2 + &
      TWO * N * stress_trial(6)**2 )
    IF (phi_trial > sigma_y) THEN
      phi_factor = sigma_y / phi_trial
      arg%stress_new = stress_trial * phi_factor
      arg%equiv_plastic_strain = arg%equiv_plastic_strain + (phi_trial - sigma_y) / H
    ELSE
      arg%stress_new = stress_trial
    END IF
    arg%D_matrix = D_elastic
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_PlasticHill_Eval

  SUBROUTINE PH_Mat_PlasticVonMises_Eval(arg)
    TYPE(PH_Mat_PlasticVonMises_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: PH_MAT_E, nu, sigma_y0, H
    REAL(wp) :: D_elastic(6,6), stress_trial(6)
    REAL(wp) :: s_dev(6), q_trial, sigma_y
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in

    CALL init_error_status(arg%status)
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    sigma_y0 = arg%mat_desc%yieldStress
    H = arg%mat_desc%hardeningModulus
    sigma_y = sigma_y0 + H * arg%equiv_plastic_strain
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = PH_MAT_E
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain_increment
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_trial = elastic_in%sigma
    stress_trial = arg%stress_old + stress_trial
    s_dev(1) = stress_trial(1) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(2) = stress_trial(2) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(3) = stress_trial(3) - (stress_trial(1) + stress_trial(2) + stress_trial(3)) / THREE
    s_dev(4) = stress_trial(4)
    s_dev(5) = stress_trial(5)
    s_dev(6) = stress_trial(6)
    q_trial = SQRT(1.5_wp * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2 + &
                              TWO * (s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2)))
    IF (q_trial > sigma_y) THEN
      arg%stress_new = stress_trial * (sigma_y / q_trial)
      arg%equiv_plastic_strain = arg%equiv_plastic_strain + &
        (q_trial - sigma_y) / (THREE * PH_MAT_E / (TWO * (ONE + nu)) + H)
    ELSE
      arg%stress_new = stress_trial
    END IF
    arg%D_matrix = D_elastic
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_PlasticVonMises_Eval

END MODULE PH_Mat_Plast_PointEval
