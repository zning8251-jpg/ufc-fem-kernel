!===============================================================================
! MODULE: PH_Mat_Geo_DP_Core
! Layer:  L4_PH
! Domain: Material / Plast / Drucker-Prager (linear meridional form)
! Role:   Core — pressure-sensitive yield, nonassociated meridional flow (SIO)
!
! Theory chain (Abaqus Theory Guide §4.4.2, extracted via PyMuPDF):
!   Linear meridional yield F = t − p tan β − d = 0 with deviatoric measure t
!   tied to Mises q and intermediate-stress parameter K (here K=1 ⇒ t=q).
!   Abaqus equivalent pressure p is positive in compression; flow uses
!   dilation ψ (stored as MD_Mat_DP_Desc % alpha) in the meridional p–t plane;
!   flow remains associated on the deviatoric π-plane when both surfaces use t.
!
! Computation chain (increment, small-strain):
!   (1) D^e(isotropic) from (E,ν); (2) σ^tr = σ_n + D^e Δε;
!   (3) p = −(σ11+σ22+σ33)/3, q = √(3 J2(s)); f = q − p tan β − d;
!   (4) if f≤0 elastic; else one-step return: Δλ = f / ( (∂g/σ):D:(∂f/σ) ),
!       σ = σ^tr − Δλ D:(∂g/∂σ) with ∂f/∂σ, ∂g/∂σ built from trial deviator.
!
! Data chain: MD_Mat_DP_Desc (L3 Geo) + PH_Mat_PLM_DP_State + PH_Mat_PLM_DP_Algo
!   + PH_Mat_Base_Ctx + unified *_Arg (Principle #14).
!===============================================================================
MODULE PH_Mat_Geo_DP_Core
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, HALF, SMALL
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_MatAlgo, MD_MatState
  USE MD_Geo_DruckerPrager, ONLY: MD_Mat_DP_Desc
  USE PH_Mat_Aux_Def, ONLY: PH_Mat_Krnl_Ctx  ! formerly PH_Mat_Base_Ctx, renamed per R-09
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: PH_Mat_Geo_DP_Core_Init
  PUBLIC :: PH_Mat_Geo_DP_Core_Update
  PUBLIC :: PH_Mat_PLM_DP_State
  PUBLIC :: PH_Mat_PLM_DP_Algo
  PUBLIC :: PH_Mat_DP_Init_Arg
  PUBLIC :: PH_Mat_DP_Update_Arg

  TYPE, PUBLIC, EXTENDS(MD_MatState) :: PH_Mat_PLM_DP_State
    REAL(wp) :: ddsdde(6, 6) = 0.0_wp
    REAL(wp) :: strain_plastic(6) = 0.0_wp
    REAL(wp) :: peeq = 0.0_wp
    LOGICAL :: is_plastic = .FALSE.
    TYPE(ErrorStatusType) :: status
    LOGICAL :: converged = .TRUE.
    INTEGER(i4) :: iterations = 0_i4
  END TYPE PH_Mat_PLM_DP_State

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PH_Mat_PLM_DP_Algo
    INTEGER(i4) :: ntens = 6_i4
    LOGICAL :: compute_tangent = .TRUE.
  END TYPE PH_Mat_PLM_DP_Algo

  TYPE, PUBLIC :: PH_Mat_DP_Init_Arg
    TYPE(ErrorStatusType) :: status
  END TYPE PH_Mat_DP_Init_Arg

  TYPE, PUBLIC :: PH_Mat_DP_Update_Arg
    LOGICAL :: request_consistent_tangent = .TRUE.
    TYPE(ErrorStatusType) :: status
    INTEGER(i4) :: local_iters = 0_i4
  END TYPE PH_Mat_DP_Update_Arg

CONTAINS

  SUBROUTINE PH_Mat_Geo_DP_Core_Init(desc, state, algo, ctx, args)
    TYPE(MD_Mat_DP_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_PLM_DP_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_PLM_DP_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Krnl_Ctx), INTENT(IN) :: ctx
    TYPE(PH_Mat_DP_Init_Arg), INTENT(INOUT) :: args

    INTEGER(i4) :: k

    CALL init_error_status(args%status)
    IF (desc%E <= ZERO) THEN
      CALL init_error_status(args%status, IF_STATUS_INVALID, &
          message='[PH_Mat_Geo_DP_Core_Init]: MD_Mat_DP_Desc%E must be positive')
      RETURN
    END IF

    state%strain_plastic = ZERO
    state%peeq = ZERO
    state%is_plastic = .FALSE.
    state%converged = .TRUE.
    state%iterations = 0_i4
    CALL init_error_status(state%status)
    IF (.NOT. ALLOCATED(state%stress)) ALLOCATE(state%stress(6))
    state%stress = ZERO
    state%stress(1) = state%stress(1) + ctx%dstran(1) * ZERO
    DO k = 1_i4, 6_i4
      state%ddsdde(k, k) = ZERO
    END DO

    args%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Geo_DP_Core_Init

  SUBROUTINE PH_Mat_Geo_DP_Core_Update(desc, state, algo, ctx, args)
    TYPE(MD_Mat_DP_Desc), INTENT(IN) :: desc
    TYPE(PH_Mat_PLM_DP_State), INTENT(INOUT) :: state
    TYPE(PH_Mat_PLM_DP_Algo), INTENT(IN) :: algo
    TYPE(PH_Mat_Krnl_Ctx), INTENT(IN) :: ctx
    TYPE(PH_Mat_DP_Update_Arg), INTENT(INOUT) :: args

    INTEGER(i4) :: ntens, i, j
    REAL(wp) :: D_el(6, 6), sig_tr(6), s_dev(6), p_comp, q_vm, f_y
    REAL(wp) :: tan_psi, df_ds(6), dg_ds(6), v_df(6), v_dg(6), den, dlam

    CALL init_error_status(args%status)
    args%local_iters = 0_i4
    CALL init_error_status(state%status)
    state%converged = .TRUE.
    state%iterations = 0_i4
    state%is_plastic = .FALSE.

    ntens = algo%ntens
    IF (ntens < 1_i4 .OR. ntens > 6_i4) ntens = 6_i4

    IF (desc%E <= ZERO) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[PH_Mat_Geo_DP_Core_Update]: invalid elastic modulus E')
      state%converged = .FALSE.
      RETURN
    END IF

    CALL PLM_DP_Build_D_el(desc%E, desc%nu, D_el)

    sig_tr(1:ntens) = state%stress(1:ntens) + &
        MATMUL(D_el(1:ntens, 1:ntens), ctx%dstran(1:ntens))
    IF (ntens < 6_i4) sig_tr(ntens+1:6) = ZERO

    CALL PLM_DP_Deviator_q_p(sig_tr, ntens, s_dev, q_vm, p_comp)
    f_y = PLM_DP_Yield_value(q_vm, p_comp, desc%d, desc%tan_beta)

    IF (f_y <= SMALL) THEN
      state%stress(1:ntens) = sig_tr(1:ntens)
      IF (algo%compute_tangent .AND. args%request_consistent_tangent) THEN
        state%ddsdde(1:ntens, 1:ntens) = D_el(1:ntens, 1:ntens)
      END IF
      args%status%status_code = IF_STATUS_OK
      state%status%status_code = IF_STATUS_OK
      RETURN
    END IF

    state%is_plastic = .TRUE.
    tan_psi = TAN(desc%alpha)
    CALL PLM_DP_Potential_grad(s_dev, q_vm, desc%tan_beta, ntens, df_ds)
    CALL PLM_DP_Potential_grad(s_dev, q_vm, tan_psi, ntens, dg_ds)

    v_df(1:ntens) = MATMUL(D_el(1:ntens, 1:ntens), df_ds(1:ntens))
    den = DOT_PRODUCT(dg_ds(1:ntens), v_df(1:ntens))
    IF (den <= SMALL) THEN
      CALL init_error_status(args%status, IF_STATUS_ERROR, &
          message='[PH_Mat_Geo_DP_Core_Update]: non-positive plastic modulus denominator')
      state%converged = .FALSE.
      state%status = args%status
      RETURN
    END IF

    dlam = f_y / den
    args%local_iters = 1_i4
    state%iterations = 1_i4

    v_dg(1:ntens) = MATMUL(D_el(1:ntens, 1:ntens), dg_ds(1:ntens))
    state%stress(1:ntens) = sig_tr(1:ntens) - dlam * v_dg(1:ntens)
    state%strain_plastic(1:ntens) = state%strain_plastic(1:ntens) + dlam * dg_ds(1:ntens)
    state%peeq = state%peeq + dlam

    IF (algo%compute_tangent .AND. args%request_consistent_tangent) THEN
      DO i = 1_i4, ntens
        DO j = 1_i4, ntens
          state%ddsdde(i, j) = D_el(i, j) - (v_dg(i) * v_df(j)) / den
        END DO
      END DO
    END IF

    args%status%status_code = IF_STATUS_OK
    state%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_Geo_DP_Core_Update

  SUBROUTINE PLM_DP_Build_D_el(E, nu, D)
    REAL(wp), INTENT(IN) :: E, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)

    REAL(wp) :: lam, mu, Kb

    mu = E / (TWO * (ONE + nu))
    Kb = E / (THREE * (ONE - TWO * nu))
    lam = Kb - TWO * mu / THREE

    D = ZERO
    D(1, 1) = lam + TWO * mu
    D(2, 2) = D(1, 1)
    D(3, 3) = D(1, 1)
    D(1, 2) = lam
    D(2, 1) = lam
    D(1, 3) = lam
    D(3, 1) = lam
    D(2, 3) = lam
    D(3, 2) = lam
    D(4, 4) = mu
    D(5, 5) = mu
    D(6, 6) = mu
  END SUBROUTINE PLM_DP_Build_D_el

  PURE SUBROUTINE PLM_DP_Deviator_q_p(sig, ntens, s_dev, q_out, p_comp)
    REAL(wp), INTENT(IN) :: sig(6)
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp), INTENT(OUT) :: s_dev(6), q_out, p_comp

    REAL(wp) :: mean_st, j2, qf
    INTEGER(i4) :: n

    n = ntens
    IF (n < 1_i4) n = 6_i4
    IF (n > 6_i4) n = 6_i4

    mean_st = (sig(1) + sig(2) + sig(3)) / THREE
    s_dev(1) = sig(1) - mean_st
    s_dev(2) = sig(2) - mean_st
    s_dev(3) = sig(3) - mean_st
    s_dev(4:6) = sig(4:6)
    IF (n < 6_i4) s_dev(n+1:6) = ZERO

    p_comp = -mean_st
    j2 = HALF * (s_dev(1)**2 + s_dev(2)**2 + s_dev(3)**2) + &
        s_dev(4)**2 + s_dev(5)**2 + s_dev(6)**2
    qf = SQRT(MAX(THREE * j2, ZERO))
    q_out = qf
  END SUBROUTINE PLM_DP_Deviator_q_p

  PURE FUNCTION PLM_DP_Yield_value(q, p_comp, d_c, tan_beta) RESULT(f)
    REAL(wp), INTENT(IN) :: q, p_comp, d_c, tan_beta
    REAL(wp) :: f

    f = q - p_comp * tan_beta - d_c
  END FUNCTION PLM_DP_Yield_value

  PURE SUBROUTINE PLM_DP_Potential_grad(s_dev, q, tan_ang, ntens, grad)
    REAL(wp), INTENT(IN) :: s_dev(6), q, tan_ang
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp), INTENT(OUT) :: grad(6)

    REAL(wp) :: qf
    INTEGER(i4) :: n, k

    n = ntens
    IF (n < 1_i4) n = 6_i4
    IF (n > 6_i4) n = 6_i4

    qf = MAX(q, SMALL)
    grad = ZERO
    grad(1:3) = 1.5_wp * s_dev(1:3) / qf + tan_ang / THREE
    IF (n >= 4_i4) grad(4) = THREE * s_dev(4) / qf
    IF (n >= 5_i4) grad(5) = THREE * s_dev(5) / qf
    IF (n >= 6_i4) grad(6) = THREE * s_dev(6) / qf

    IF (q <= SMALL) THEN
      grad = ZERO
      grad(1:3) = tan_ang / THREE
      DO k = 4_i4, n
        grad(k) = ZERO
      END DO
    END IF
  END SUBROUTINE PLM_DP_Potential_grad

END MODULE PH_Mat_Geo_DP_Core

