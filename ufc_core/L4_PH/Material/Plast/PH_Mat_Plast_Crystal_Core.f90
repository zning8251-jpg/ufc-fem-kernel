!===============================================================================
! MODULE: PH_Mat_Plast_Crystal_Core
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  Crystal plasticity UMAT (mat_id 266) — **W1a iso-surrogate** (J2-equivalent).
!         **W1b** (future): 1-slip Schmid; see plan `p1-material-crystal-impl`.
! Purpose: PLM UMAT via UF_CrystalPlasticity_UMAT_Arg; removes STATUS_UNSUPPORTED.
! Theory: W1a maps tau_c to sigma_y = sqrt(3)*tau_c, isotropic J2 radial return (no orientation).
! Status: Production (W1a surrogate) | Last verified: 2026-05-19
!===============================================================================
MODULE PH_Mat_Plast_Crystal_Core
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF, SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID, &
       IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Eval_Types, ONLY: MD_MATCTX_MAX_STATEV
  USE MD_Mat_Plast_Reg, ONLY: MD_MAT_PLAST_MAX_PROPS
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D, Calc_Deviatoric_Stress, Calc_Von_Mises

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_PLASTICITY_MAT_ID = 266_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_NPROPS_MIN = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_CRYSTAL_NSTATV_MIN = 7_i4
  REAL(wp), PARAMETER :: PH_CRYSTAL_SQRT3 = 1.7320508075688772_wp

  TYPE, PUBLIC :: CrystalPlast_MatDesc
    REAL(wp) :: props(50) = 0.0_wp
    INTEGER(i4) :: nprops = 0_i4
  END TYPE CrystalPlast_MatDesc

  IMPLICIT NONE
  PRIVATE
  PUBLIC :: CrystalPlast_MatDesc, PH_MAT_CRYSTAL_PLASTICITY_MAT_ID
  PUBLIC :: PH_MAT_CRYSTAL_NPROPS_MIN, PH_MAT_CRYSTAL_NSTATV_MIN
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

  PURE FUNCTION Crystal_SigmaY_FromTau(tau_c0, H, peeq) RESULT(sigma_y)
    REAL(wp), INTENT(IN) :: tau_c0, H, peeq
    REAL(wp) :: sigma_y
    sigma_y = PH_CRYSTAL_SQRT3 * (tau_c0 + H * MAX(peeq, ZERO))
  END FUNCTION Crystal_SigmaY_FromTau

  SUBROUTINE Crystal_EP_Tangent(E, nu, H, sigma6, ntens, plastic_step, Dout)
    REAL(wp), INTENT(IN) :: E, nu, H, sigma6(6)
    INTEGER(i4), INTENT(IN) :: ntens
    LOGICAL, INTENT(IN) :: plastic_step
    REAL(wp), INTENT(OUT) :: Dout(6, 6)

    REAL(wp) :: D_e(6, 6), G_mod, s_cur(6), q_cur, nvec(6), fac
    REAL(wp) :: n_dyad(6, 6)
    INTEGER(i4) :: i, j

    CALL Construct_Elastic_D(E, nu, D_e)
    IF (.NOT. plastic_step) THEN
      Dout(1:ntens, 1:ntens) = D_e(1:ntens, 1:ntens)
      RETURN
    END IF

    G_mod = E / (TWO * (ONE + nu))
    CALL Calc_Deviatoric_Stress(sigma6, s_cur)
    q_cur = Calc_Von_Mises(s_cur)
    IF (q_cur <= SMALL) THEN
      Dout(1:ntens, 1:ntens) = D_e(1:ntens, 1:ntens)
      RETURN
    END IF
    nvec = s_cur / q_cur
    DO i = 1_i4, 6_i4
      DO j = 1_i4, 6_i4
        n_dyad(i, j) = nvec(i) * nvec(j)
      END DO
    END DO
    IF (THREE * G_mod + PH_CRYSTAL_SQRT3 * H <= SMALL) THEN
      Dout(1:ntens, 1:ntens) = D_e(1:ntens, 1:ntens)
      RETURN
    END IF
    fac = 6.0_wp * G_mod**2 / (THREE * G_mod + PH_CRYSTAL_SQRT3 * H)
    D_e = D_e - fac * n_dyad
    Dout(1:ntens, 1:ntens) = D_e(1:ntens, 1:ntens)
  END SUBROUTINE Crystal_EP_Tangent

  PURE SUBROUTINE Crystal_Assem_Dev(stress_trial, s_dev, sigma, ntens)
    REAL(wp), INTENT(IN) :: stress_trial(6), s_dev(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp) :: p_mean

    p_mean = (stress_trial(1) + stress_trial(2) + stress_trial(3)) / 3.0_wp
    sigma(1) = s_dev(1) + p_mean
    sigma(2) = s_dev(2) + p_mean
    sigma(3) = s_dev(3) + p_mean
    sigma(4:6) = s_dev(4:6)
    IF (ntens < 6_i4) sigma(ntens + 1:6) = ZERO
  END SUBROUTINE Crystal_Assem_Dev

  SUBROUTINE UF_CrystalPlasticity_UMAT(arg)
    TYPE(UF_CrystalPlasticity_UMAT_Arg), INTENT(INOUT) :: arg

    REAL(wp) :: E, nu, tau_c0, H
    REAL(wp) :: D_el(6, 6), stress_trial(6), s_trial(6), q_trial
    REAL(wp) :: sigma_y, f_yield, delta_gamma, G_mod, beta, s_dev(6), n_dir(6)
    REAL(wp) :: peeq, eps_p(6)
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
      arg%status%message = 'UF_CrystalPlasticity_UMAT: need nstatev >= 7 (peeq + eps_p)'
      RETURN
    END IF

    CALL Crystal_ValidateProps(arg%nprops, arg%props(1:MAX(arg%nprops, 1)), E, nu, tau_c0, H, arg%status)
    IF (arg%status%status_code /= IF_STATUS_OK) RETURN

    ntens = arg%ndir + arg%nshr
    IF (ntens < 1_i4 .OR. ntens > 6_i4) ntens = 6_i4

    peeq = arg%statev(1)
    eps_p(1:6) = arg%statev(2:7)

    CALL Construct_Elastic_D(E, nu, D_el)
    stress_trial(1:ntens) = arg%stress(1:ntens) + MATMUL(D_el(1:ntens, 1:ntens), arg%dstran(1:ntens))
    IF (ntens < 6_i4) stress_trial(ntens + 1:6) = ZERO

    CALL Calc_Deviatoric_Stress(stress_trial, s_trial)
    q_trial = Calc_Von_Mises(s_trial)
    sigma_y = Crystal_SigmaY_FromTau(tau_c0, H, peeq)
    f_yield = q_trial - sigma_y
    plastic_step = .FALSE.

    IF (f_yield <= ZERO) THEN
      arg%stress(1:ntens) = stress_trial(1:ntens)
      CALL Crystal_EP_Tangent(E, nu, H, arg%stress, ntens, plastic_step, arg%ddsdde)
    ELSE
      plastic_step = .TRUE.
      G_mod = E / (TWO * (ONE + nu))
      IF (THREE * G_mod + PH_CRYSTAL_SQRT3 * H <= SMALL) THEN
        arg%status%status_code = IF_STATUS_ERROR
        arg%status%message = 'UF_CrystalPlasticity_UMAT: 3G+sqrt(3)*H non-positive'
        RETURN
      END IF
      IF (q_trial <= SMALL) THEN
        arg%status%status_code = IF_STATUS_ERROR
        arg%status%message = 'UF_CrystalPlasticity_UMAT: trial q too small for plastic return'
        RETURN
      END IF
      n_dir = s_trial / q_trial
      delta_gamma = (q_trial - sigma_y) / (THREE * G_mod + PH_CRYSTAL_SQRT3 * H)
      peeq = peeq + delta_gamma
      beta = ONE - THREE * G_mod * delta_gamma / q_trial
      s_dev = beta * s_trial
      CALL Crystal_Assem_Dev(stress_trial, s_dev, arg%stress, ntens)
      eps_p(1:6) = eps_p(1:6) + delta_gamma * n_dir(1:6)
      CALL Crystal_EP_Tangent(E, nu, H, arg%stress, ntens, plastic_step, arg%ddsdde)
    END IF

    arg%statev(1) = peeq
    arg%statev(2:7) = eps_p(1:6)
    arg%status%status_code = IF_STATUS_OK
  END SUBROUTINE UF_CrystalPlasticity_UMAT

END MODULE PH_Mat_Plast_Crystal_Core
