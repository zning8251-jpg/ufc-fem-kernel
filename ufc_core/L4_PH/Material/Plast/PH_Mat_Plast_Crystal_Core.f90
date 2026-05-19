!===============================================================================
! MODULE: PH_Mat_Plast_Crystal_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Crystal plasticity UMAT (mat_id 266) — **W1b 1-slip Schmid** (active).
!         W1a iso-surrogate **deprecated** (removed); see CONTRACT / plan crystal-impl.
! Purpose: PLM UMAT via UF_CrystalPlasticity_UMAT_Arg.
! Theory: Rate-independent single slip; tau = P:sigma, P = sym(s x m); Voigt 6.
! Status: Production (W1b) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_Crystal_Core
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF, SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, &
       IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Eval_Types, ONLY: MD_MATCTX_MAX_STATEV
  USE MD_Mat_Plast_Reg, ONLY: MD_MAT_PLAST_MAX_PROPS
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_PLASTICITY_MAT_ID = 266_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_NPROPS_MIN = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_NPROPS_SCHMID = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_NSTATV_MIN = 7_i4

  TYPE, PUBLIC :: CrystalPlast_MatDesc
    REAL(wp) :: props(50) = 0.0_wp
    INTEGER(i4) :: nprops = 0_i4
  END TYPE CrystalPlast_MatDesc

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CrystalPlast_MatDesc, PH_MAT_CRYSTAL_PLASTICITY_MAT_ID
  PUBLIC :: PH_MAT_CRYSTAL_NPROPS_MIN, PH_MAT_CRYSTAL_NPROPS_SCHMID, PH_MAT_CRYSTAL_NSTATV_MIN
  PUBLIC :: UF_CrystalPlasticity_UMAT, UF_CrystalPlasticity_UMAT_Arg

  TYPE, PUBLIC :: UF_CrystalPlasticity_UMAT_Arg
    REAL(wp) :: stress(6) = 0.0_wp                       ! [INOUT]
    INTEGER(i4) :: nstatev = 0_i4                        ! [IN]
    REAL(wp) :: statev(MD_MATCTX_MAX_STATEV) = 0.0_wp    ! [INOUT]
    REAL(wp) :: ddsdde(6, 6) = 0.0_wp                    ! [OUT]
    REAL(wp) :: sse = 0.0_wp                             ! [OUT]
    REAL(wp) :: spd = 0.0_wp                             ! [OUT]
    REAL(wp) :: scd = 0.0_wp                             ! [OUT]
    REAL(wp) :: rpl = 0.0_wp                             ! [OUT]
    REAL(wp) :: ddsddt(6) = 0.0_wp                       ! [OUT]
    REAL(wp) :: drplde(6) = 0.0_wp                       ! [OUT]
    REAL(wp) :: drpldt = 0.0_wp                          ! [OUT]
    REAL(wp) :: stran(6) = 0.0_wp                        ! [IN]
    REAL(wp) :: dstran(6) = 0.0_wp                       ! [IN]
    REAL(wp) :: time(2) = 0.0_wp                         ! [IN]
    REAL(wp) :: dtime = 0.0_wp                           ! [IN]
    REAL(wp) :: temp = 0.0_wp                            ! [IN]
    REAL(wp) :: dtemp = 0.0_wp                           ! [IN]
    INTEGER(i4) :: ndir = 0_i4                           ! [IN]
    INTEGER(i4) :: nshr = 0_i4                           ! [IN]
    INTEGER(i4) :: nprops = 0_i4                         ! [IN]
    REAL(wp) :: props(MD_MAT_PLAST_MAX_PROPS) = 0.0_wp   ! [IN]
    INTEGER(i4) :: ndim = 0_i4                           ! [IN]
    INTEGER(i4) :: kstep = 0_i4                          ! [IN]
    INTEGER(i4) :: kinc = 0_i4                           ! [IN]
    TYPE(ErrorStatusType) :: status                      ! [OUT]
  END TYPE UF_CrystalPlasticity_UMAT_Arg

CONTAINS

  SUBROUTINE Crystal_ValidateProps(nprops, props, E, nu, tau_c0, H, status)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    REAL(wp), INTENT(OUT) :: E, nu, tau_c0, H
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (nprops < PH_MAT_CRYSTAL_NPROPS_MIN) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_CrystalPlasticity_UMAT: need nprops >= 4 (E, nu, tau_c0, H)'
      RETURN
    END IF
    E = props(1)
    nu = props(2)
    tau_c0 = props(3)
    H = props(4)
    IF (E <= SMALL .OR. nu <= -ONE + SMALL .OR. nu >= HALF - SMALL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_CrystalPlasticity_UMAT: invalid E or nu'
      RETURN
    END IF
    IF (tau_c0 <= SMALL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_CrystalPlasticity_UMAT: tau_c0 must be positive'
      RETURN
    END IF
    IF (H < ZERO) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_CrystalPlasticity_UMAT: H must be non-negative'
      RETURN
    END IF
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Crystal_ValidateProps

  SUBROUTINE Crystal_ParseSchmidVectors(nprops, props, s, m, status)
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    REAL(wp), INTENT(OUT) :: s(3), m(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    REAL(wp) :: sn, mn

    CALL init_error_status(status)
    IF (nprops >= PH_MAT_CRYSTAL_NPROPS_SCHMID) THEN
      s(1:3) = props(5:7)
      m(1:2) = props(8:9)
      m(3) = ZERO
      IF (nprops >= 10_i4 .AND. SIZE(props) >= 10) m(3) = props(10)
    ELSE
      s = [ZERO, ZERO, ONE]
      m = [ONE, ZERO, ZERO]
    END IF

    sn = SQRT(s(1)**2 + s(2)**2 + s(3)**2)
    mn = SQRT(m(1)**2 + m(2)**2 + m(3)**2)
    IF (sn <= SMALL .OR. mn <= SMALL) THEN
      status%status_code = IF_STATUS_INVALID
      status%message = 'UF_CrystalPlasticity_UMAT: slip s or plane m has zero length'
      RETURN
    END IF
    s = s / sn
    m = m / mn
    status%status_code = IF_STATUS_OK
  END SUBROUTINE Crystal_ParseSchmidVectors

  PURE SUBROUTINE Crystal_SchmidVector(s, m, p_voigt)
    REAL(wp), INTENT(IN) :: s(3), m(3)
    REAL(wp), INTENT(OUT) :: p_voigt(6)

    p_voigt(1) = s(1) * m(1)
    p_voigt(2) = s(2) * m(2)
    p_voigt(3) = s(3) * m(3)
    p_voigt(4) = s(1) * m(2) + s(2) * m(1)
    p_voigt(5) = s(1) * m(3) + s(3) * m(1)
    p_voigt(6) = s(2) * m(3) + s(3) * m(2)
  END SUBROUTINE Crystal_SchmidVector

  PURE FUNCTION Crystal_ResolvedShear(sigma6, p_voigt) RESULT(tau)
    REAL(wp), INTENT(IN) :: sigma6(6), p_voigt(6)
    REAL(wp) :: tau
    tau = DOT_PRODUCT(p_voigt, sigma6)
  END FUNCTION Crystal_ResolvedShear

  SUBROUTINE Crystal_Schmid_Tangent(D, p_voigt, H, plastic_step, Dout)
    REAL(wp), INTENT(IN) :: D(6, 6), p_voigt(6), H
    LOGICAL, INTENT(IN) :: plastic_step
    REAL(wp), INTENT(OUT) :: Dout(6, 6)

    REAL(wp) :: dp(6), kp, fac
    INTEGER(i4) :: i, j

    IF (.NOT. plastic_step) THEN
      Dout = D
      RETURN
    END IF
    dp = MATMUL(D, p_voigt)
    kp = DOT_PRODUCT(p_voigt, dp)
    IF (kp + H <= SMALL) THEN
      Dout = D
      RETURN
    END IF
    fac = ONE / (kp + H)
    Dout = D
    DO i = 1, 6
      DO j = 1, 6
        Dout(i, j) = Dout(i, j) - fac * dp(i) * dp(j)
      END DO
    END DO
  END SUBROUTINE Crystal_Schmid_Tangent

  SUBROUTINE UF_CrystalPlasticity_UMAT(arg)
    TYPE(UF_CrystalPlasticity_UMAT_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: E, nu, tau_c0, H
    REAL(wp) :: s(3), m(3), p_voigt(6)
    REAL(wp) :: D_el(6, 6), stress_trial(6), dp(6)
    REAL(wp) :: tau_trial, tau_y, dgamma, flow_sign
    REAL(wp) :: gamma, eps_p(6)
    INTEGER(i4) :: ntens, nsv
    LOGICAL :: plastic_step

    CALL init_error_status(arg%status)
    arg%ddsdde = ZERO
    arg%sse = ZERO
    arg%spd = ZERO
    arg%scd = ZERO
    arg%rpl = ZERO
    arg%ddsddt = ZERO
    arg%drplde = ZERO
    arg%drpldt = ZERO

    nsv = arg%nstatev
    IF (nsv < PH_MAT_CRYSTAL_NSTATV_MIN) THEN
      arg%status%status_code = IF_STATUS_INVALID
      arg%status%message = 'UF_CrystalPlasticity_UMAT: need nstatev >= 7 (gamma + eps_p)'
      RETURN
    END IF

    CALL Crystal_ValidateProps(arg%nprops, arg%props(1:MAX(arg%nprops, 1)), E, nu, tau_c0, H, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN

    CALL Crystal_ParseSchmidVectors(arg%nprops, arg%props(1:MAX(arg%nprops, 1)), s, m, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN

    CALL Crystal_SchmidVector(s, m, p_voigt)

    ntens = arg%ndir + arg%nshr
    IF (ntens < 1_i4 .OR. ntens > 6_i4) ntens = 6_i4

    gamma = arg%statev(1)
    eps_p(1:6) = arg%statev(2:7)

    CALL Construct_Elastic_D(E, nu, D_el)
    stress_trial(1:ntens) = arg%stress(1:ntens) + MATMUL(D_el(1:ntens, 1:ntens), arg%dstran(1:ntens))
    IF (ntens < 6_i4) stress_trial(ntens + 1:6) = ZERO

    tau_trial = Crystal_ResolvedShear(stress_trial, p_voigt)
    tau_y = tau_c0 + H * MAX(gamma, ZERO)
    plastic_step = .FALSE.

    IF (ABS(tau_trial) <= tau_y) THEN
      arg%stress(1:ntens) = stress_trial(1:ntens)
      CALL Crystal_Schmid_Tangent(D_el, p_voigt, H, plastic_step, arg%ddsdde)
    ELSE
      plastic_step = .TRUE.
      dp = MATMUL(D_el, p_voigt)
      IF (DOT_PRODUCT(p_voigt, dp) + H <= SMALL) THEN
        arg%status%status_code = IF_STATUS_ERROR
        arg%status%message = 'UF_CrystalPlasticity_UMAT: Schmid modulus P:D:P+H non-positive'
        RETURN
      END IF
      IF (ABS(tau_trial) <= SMALL) THEN
        arg%status%status_code = IF_STATUS_ERROR
        arg%status%message = 'UF_CrystalPlasticity_UMAT: |tau_trial| too small for slip return'
        RETURN
      END IF
      flow_sign = SIGN(ONE, tau_trial)
      dgamma = (ABS(tau_trial) - tau_y) / (DOT_PRODUCT(p_voigt, dp) + H)
      arg%stress(1:ntens) = stress_trial(1:ntens) - dgamma * flow_sign * dp(1:ntens)
      IF (ntens < 6_i4) arg%stress(ntens + 1:6) = ZERO
      gamma = gamma + dgamma
      eps_p(1:6) = eps_p(1:6) + dgamma * flow_sign * p_voigt(1:6)
      CALL Crystal_Schmid_Tangent(D_el, p_voigt, H, plastic_step, arg%ddsdde)
    END IF

    arg%statev(1) = gamma
    arg%statev(2:7) = eps_p(1:6)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CrystalPlasticity_UMAT

END MODULE PH_Mat_Plast_Crystal_Core
