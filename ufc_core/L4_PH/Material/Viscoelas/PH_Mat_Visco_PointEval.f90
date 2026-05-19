!===============================================================================
! MODULE: PH_Mat_Visco_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Viscoelas
! ROLE:   Eval (legacy point-model SIO — C2 split from PH_MatEval)
! BRIEF:  Prony / Maxwell / Kelvin-Voigt point Eval.
! Purpose: Family-owned Arg types; Prony uses Elas trial helper.
! Theory: Linear viscoelastic branch models (legacy stubs).
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Visco_PointEval
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc, MD_PronyMatDesc
  USE PH_Mat_Elas_PointEval, ONLY: PH_Mat_ElasticIsotropic_Eval_Arg, PH_Mat_ElasticIsotropic_Eval
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg, PH_Mat_ViscoelasticMaxwell_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
  PUBLIC :: PH_Mat_ViscoelasticProny_Eval, PH_Mat_ViscoelasticMaxwell_Eval
  PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval

  TYPE, PUBLIC :: PH_Mat_ViscoelasticProny_Eval_Arg
    TYPE(MD_PronyMatDesc) :: mat_desc
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: strain_rate(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_ViscoelasticProny_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_ViscoelasticMaxwell_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: stress_new(6) = 0.0_wp
    REAL(wp) :: strain_rate(6) = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_ViscoelasticMaxwell_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: strain_rate(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_ViscoelasticKelvinVoigt_Eval(arg)
    TYPE(PH_Mat_ViscoelasticKelvinVoigt_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: PH_MAT_E, eta
    CALL init_error_status(arg%status)
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    eta = arg%mat_desc%viscosity
    arg%sigma = PH_MAT_E * arg%strain + eta * arg%strain_rate
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_ViscoelasticKelvinVoigt_Eval

  SUBROUTINE PH_Mat_ViscoelasticMaxwell_Eval(arg)
    TYPE(PH_Mat_ViscoelasticMaxwell_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: PH_MAT_E, eta, relaxation_time
    CALL init_error_status(arg%status)
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    eta = arg%mat_desc%viscosity
    relaxation_time = eta / PH_MAT_E
    IF (relaxation_time > 1.0e-12_wp) THEN
      arg%stress_new = arg%stress_old * EXP(-arg%dtime / relaxation_time) + &
                       PH_MAT_E * arg%strain_rate * relaxation_time * &
                       (ONE - EXP(-arg%dtime / relaxation_time))
    ELSE
      arg%stress_new = arg%stress_old + PH_MAT_E * arg%strain_rate * arg%dtime
    END IF
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_ViscoelasticMaxwell_Eval

  SUBROUTINE PH_Mat_ViscoelasticProny_Eval(arg)
    TYPE(PH_Mat_ViscoelasticProny_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: E_inf, nu
    INTEGER(i4) :: n_terms, i
    REAL(wp) :: D_elastic(6,6), stress_elastic(6), stress_viscous(6)
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    CALL init_error_status(arg%status)
    E_inf = arg%mat_desc%E_inf
    nu = arg%mat_desc%nu
    n_terms = arg%mat_desc%n_terms
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = E_inf
    md_elas_wire%nu = nu
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    IF (elastic_in%status%status_code /= IF_STATUS_OK) THEN
      arg%status = elastic_in%status
      RETURN
    END IF
    D_elastic = elastic_in%D_matrix
    stress_elastic = elastic_in%sigma
    stress_viscous = ZERO
    DO i = 1, MIN(n_terms, 10)
      IF (arg%mat_desc%tau_prony(i) > 1.0e-12_wp) THEN
        stress_viscous = stress_viscous + arg%mat_desc%g_prony(i) * arg%strain_rate(:) * &
                         (ONE - EXP(-arg%dtime / arg%mat_desc%tau_prony(i)))
      END IF
    END DO
    arg%sigma = stress_elastic + stress_viscous
    arg%D_matrix = D_elastic
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_ViscoelasticProny_Eval

END MODULE PH_Mat_Visco_PointEval
