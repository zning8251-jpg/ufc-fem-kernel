!===============================================================================
! MODULE: PH_Mat_Hyper_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Hyper
! ROLE:   Eval (legacy point-model SIO — C2 split from PH_MatEval)
! BRIEF:  Neo-Hookean / Mooney-Rivlin point Eval stubs.
! Purpose: Family-owned Arg types + Eval for legacy hyperelastic call paths.
! Theory: Placeholder σ/D until finite-strain kernel wired.
! Status: Production (legacy point stub) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Hyper_PointEval
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_HyperElasticMatDesc
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg, PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
  PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval, PH_Mat_HyperelasticMooneyRivlin_Eval

  TYPE, PUBLIC :: PH_Mat_HyperelasticNeoHookean_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_HyperelasticNeoHookean_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_HyperelasticMooneyRivlin_Eval_Arg
    TYPE(MD_HyperElasticMatDesc) :: mat_desc
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_HyperelasticMooneyRivlin_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_HyperelasticMooneyRivlin_Eval(arg)
    TYPE(PH_Mat_HyperelasticMooneyRivlin_Eval_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%sigma = 0.0_wp
    arg%D_matrix = 0.0_wp
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_HyperelasticMooneyRivlin_Eval

  SUBROUTINE PH_Mat_HyperelasticNeoHookean_Eval(arg)
    TYPE(PH_Mat_HyperelasticNeoHookean_Eval_Arg), INTENT(INOUT) :: arg
    CALL init_error_status(arg%status)
    arg%sigma = 0.0_wp
    arg%D_matrix = 0.0_wp
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_HyperelasticNeoHookean_Eval

END MODULE PH_Mat_Hyper_PointEval
