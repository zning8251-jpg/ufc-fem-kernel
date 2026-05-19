!===============================================================================
! MODULE: PH_Mat_Elas_PointEval
! LAYER:  L4_PH
! DOMAIN: Material / Elas
! ROLE:   Eval (legacy point-model SIO from plan C2 split)
! BRIEF:  Isotropic / orthotropic Hooke point Eval; absorbed from Dispatch/PH_MatEval.
! Purpose: Family-owned Arg types + Eval for legacy MD_Mat_Lib call paths.
! Theory: σ = D·ε (iso Lame; ortho engineering constants, diagonal S⁻¹ approx).
! Status: Production (legacy point) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Elas_PointEval
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE IF_Prec_Core, ONLY: i4, wp
  USE MD_Mat_Lib, ONLY: MD_ElasticMatDesc
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
  PUBLIC :: PH_Mat_ElasticIsotropic_Eval
  PUBLIC :: PH_Mat_ElasticOrthotropic_Eval

  TYPE, PUBLIC :: PH_Mat_ElasticIsotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_ElasticIsotropic_Eval_Arg

  TYPE, PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
    TYPE(MD_ElasticMatDesc) :: mat_desc
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: D_matrix(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_ElasticOrthotropic_Eval_Arg

CONTAINS

  SUBROUTINE PH_Mat_ElasticIsotropic_Eval(arg)
    TYPE(PH_Mat_ElasticIsotropic_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: PH_MAT_E, nu
    REAL(wp) :: lambda, mu, factor
    INTEGER(i4) :: i, j

    CALL init_error_status(arg%status)
    PH_MAT_E = arg%mat_desc%PH_MAT_E
    nu = arg%mat_desc%nu
    lambda = PH_MAT_E * nu / ((ONE + nu) * (ONE - TWO * nu))
    mu = PH_MAT_E / (TWO * (ONE + nu))
    factor = PH_MAT_E / ((ONE + nu) * (ONE - TWO * nu))
    arg%D_matrix = ZERO
    arg%D_matrix(1,1) = factor * (ONE - nu)
    arg%D_matrix(1,2) = factor * nu
    arg%D_matrix(1,3) = factor * nu
    arg%D_matrix(2,1) = factor * nu
    arg%D_matrix(2,2) = factor * (ONE - nu)
    arg%D_matrix(2,3) = factor * nu
    arg%D_matrix(3,1) = factor * nu
    arg%D_matrix(3,2) = factor * nu
    arg%D_matrix(3,3) = factor * (ONE - nu)
    arg%D_matrix(4,4) = mu
    arg%D_matrix(5,5) = mu
    arg%D_matrix(6,6) = mu
    arg%sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        arg%sigma(i) = arg%sigma(i) + arg%D_matrix(i,j) * arg%strain(j)
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_ElasticIsotropic_Eval

  SUBROUTINE PH_Mat_ElasticOrthotropic_Eval(arg)
    TYPE(PH_Mat_ElasticOrthotropic_Eval_Arg), INTENT(INOUT) :: arg
    REAL(wp) :: E1, E2, E3, nu12, nu23, nu13, G12, G23, G13
    REAL(wp) :: nu21, nu31, nu32
    REAL(wp) :: S(6,6)
    INTEGER(i4) :: i, j

    CALL init_error_status(arg%status)
    E1 = arg%mat_desc%E1
    E2 = arg%mat_desc%E2
    E3 = arg%mat_desc%E3
    nu12 = arg%mat_desc%nu12
    nu23 = arg%mat_desc%nu23
    nu13 = arg%mat_desc%nu13
    G12 = arg%mat_desc%G12
    G23 = arg%mat_desc%G23
    G13 = arg%mat_desc%G13
    nu21 = nu12 * E2 / E1
    nu31 = nu13 * E3 / E1
    nu32 = nu23 * E3 / E2
    S = ZERO
    S(1,1) = ONE / E1
    S(1,2) = -nu12 / E1
    S(1,3) = -nu13 / E1
    S(2,1) = -nu21 / E2
    S(2,2) = ONE / E2
    S(2,3) = -nu23 / E2
    S(3,1) = -nu31 / E3
    S(3,2) = -nu32 / E3
    S(3,3) = ONE / E3
    S(4,4) = ONE / G12
    S(5,5) = ONE / G23
    S(6,6) = ONE / G13
    arg%D_matrix = ZERO
    IF (ABS(S(1,1)) > 1.0e-12_wp) arg%D_matrix(1,1) = ONE / S(1,1)
    IF (ABS(S(2,2)) > 1.0e-12_wp) arg%D_matrix(2,2) = ONE / S(2,2)
    IF (ABS(S(3,3)) > 1.0e-12_wp) arg%D_matrix(3,3) = ONE / S(3,3)
    IF (ABS(S(4,4)) > 1.0e-12_wp) arg%D_matrix(4,4) = ONE / S(4,4)
    IF (ABS(S(5,5)) > 1.0e-12_wp) arg%D_matrix(5,5) = ONE / S(5,5)
    IF (ABS(S(6,6)) > 1.0e-12_wp) arg%D_matrix(6,6) = ONE / S(6,6)
    arg%sigma = ZERO
    DO i = 1, 6
      DO j = 1, 6
        arg%sigma(i) = arg%sigma(i) + arg%D_matrix(i,j) * arg%strain(j)
      END DO
    END DO
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_ElasticOrthotropic_Eval

END MODULE PH_Mat_Elas_PointEval
