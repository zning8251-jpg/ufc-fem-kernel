!===============================================================================
! MODULE: PH_Mat_Comp_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Composite
! ROLE:   Eval (legacy point-model SIO — C2 split from PH_MatEval)
! BRIEF:  Laminate / fiber-reinforced composite point Eval.
! Purpose: Family-owned Arg types for legacy composite call paths.
! Theory: Laminate Q average; fiber ROM → isotropic equivalent.
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Comp_PointEval
  USE IF_Base_Def, ONLY: ONE, ZERO
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc, MD_CompositeMatDesc
  USE PH_Mat_Elas_PointEval, ONLY: PH_Mat_ElasticIsotropic_Eval_Arg, PH_Mat_ElasticIsotropic_Eval
  IMPLICIT NONE
  PRIVATE
  PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg, PH_Mat_CompositeFiberReinforced_Eval_Arg
  PUBLIC :: PH_Mat_CompositeLaminate_Eval, PH_Mat_CompositeFiberReinforced_Eval

  INTEGER(i4), PARAMETER :: PH_MAT_COMP_MAX_LAYERS = 100_i4

  TYPE, PUBLIC :: PH_Mat_CompositeLaminate_Eval_Arg
    INTEGER(i4) :: n_layers = 0_i4
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    REAL(wp) :: Q_matrix(6, 6, PH_MAT_COMP_MAX_LAYERS) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_CompositeLaminate_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_CompositeFiberReinforced_Eval_Arg
    TYPE(MD_CompositeMatDesc) :: mat_desc
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_CompositeFiberReinforced_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_CompositeFiberReinforced_Eval(arg)
    TYPE(PH_Mat_CompositeFiberReinforced_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: E_fiber, E_matrix, nu_fiber, nu_matrix, V_fiber
    REAL(wp) :: E_eff, nu_eff, V_matrix
    TYPE(MD_ElasticMatDesc) :: md_elas_wire
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg) :: elastic_in
    CALL init_error_status(arg%status)
    E_fiber = arg%mat_desc%E_fiber
    E_matrix = arg%mat_desc%E_matrix
    nu_fiber = arg%mat_desc%nu_fiber
    nu_matrix = arg%mat_desc%nu_matrix
    V_fiber = arg%mat_desc%volume_fraction
    V_matrix = ONE - V_fiber
    E_eff = E_fiber * V_fiber + E_matrix * V_matrix
    nu_eff = nu_fiber * V_fiber + nu_matrix * V_matrix
    CALL init_error_status(elastic_in%status)
    md_elas_wire%PH_MAT_E = E_eff
    md_elas_wire%nu = nu_eff
    elastic_in%mat_desc = md_elas_wire
    elastic_in%strain = arg%strain
    CALL PH_Mat_ElasticIsotropic_Eval(elastic_in)
    arg%sigma = elastic_in%sigma
    arg%D_matrix = elastic_in%D_matrix
    arg%status = elastic_in%status
  END SUBROUTINE PH_Mat_CompositeFiberReinforced_Eval

  SUBROUTINE PH_Mat_CompositeLaminate_Eval(arg)
    TYPE(PH_Mat_CompositeLaminate_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: stress_layer(6)
    INTEGER(i4) :: i, j, k, nlay
    CALL init_error_status(arg%status)
    arg%sigma = ZERO
    arg%D_matrix = ZERO
    nlay = MIN(arg%n_layers, PH_MAT_COMP_MAX_LAYERS)
    IF (nlay < 1) THEN
      arg%status%status_code = IF_STATUS_OK
      RETURN
    END IF
    DO k = 1, nlay
      stress_layer = ZERO
      DO i = 1, 6
        DO j = 1, 6
          stress_layer(i) = stress_layer(i) + arg%Q_matrix(i,j,k) * arg%strain(j)
        END DO
      END DO
      arg%sigma = arg%sigma + stress_layer / REAL(nlay, wp)
      DO i = 1, 6
        DO j = 1, 6
          arg%D_matrix(i,j) = arg%D_matrix(i,j) + arg%Q_matrix(i,j,k) / REAL(nlay, wp)
        END DO
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_CompositeLaminate_Eval

END MODULE PH_Mat_Comp_PointEval
