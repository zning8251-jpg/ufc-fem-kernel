!===============================================================================
! MODULE: PH_MatPlastJ2Iso
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Core
! BRIEF:  J2 (von Mises) isotropic plasticity constitutive model
!   W1: aligned with **PH_MAT_ELASTO_PLASTIC** + **`PH_Mat_Desc_Effective_Model`**;
!   elastic branch uses **E, nu** from **`desc%props`** / Populate-filled Desc.
!===============================================================================
!
! COMPUTATIONAL FLOW (single core, one increment)
!   [1] Validate ntens (1..6); init status, pnewdt, convergence counters.
!   [2] Elastic stiffness D^e from Desc (PH_MAT_E, nu) �?PLM_J2_Build_D_el.
!   [3] Trial stress: sigma_trial = sigma_n + D^e : dstran (active ntens block).
!   [4] Deviatoric trial s, von Mises q; yield stress sigma_y(peeq) �?PLM_J2_Yield_*.
!   [5] Elastic branch (f <= 0): accept trial; ddsdde = D^e if requested.
!   [6] Plastic branch (f > 0): check 3G+H_iso, q; radial return; update peeq,
!       plastic strain, back-stress; ddsdde = D_ep via PLM_J2_EP_Tangent.
!   [7] Set IF_STATUS_OK.
!
! MATPOINT PATH (PH_Mat_PLM_J2_UpdateStress)
!   MD_Mat_PLM_J2_Desc from props -> fill PH state from sigma_old/statev -> [1]..[7] -> out.
!
! PRECISION
!   Working precision is IF_Prec::wp.  All internal variables and calls use wp uniformly.
!
! CONTRACT (v4.1)
!   - MD_Mat%ntens in 1..6 or IF_STATUS_ERROR.
!   - pnewdt INOUT; initialise to RT_PNEWDT_NO_CHANGE.
!   - Hardening types 1=linear, 2=Swift, 3=Voce; optional kinematic (Desc%use_kinematic).
!   - statev layout (MatPoint / UMAT, Voigt 6):
!       PH_MAT_NSTATV_PLM_J2_ISO = 7:  (1)=peeq, (2:7)=plastic strain eps_p.
!       PH_MAT_NSTATV_PLM_J2_KIN = 13: (1)=peeq, (2:7)=eps_p, (8:13)=back stress alpha.
!     If use_kinematic: caller must provide nstatv >= 13 once statev is allocated
!     (Pack copies MIN(out,ctx); host ctx%statev must be >= 13 for kinematic).
!
! Reference: Simo & Hughes (1998); PH_Mat_Integ_Shared
!===============================================================================
MODULE PH_Mat_Plast_J2_UMAT_Core
  USE IF_Base_Def, ONLY: ZERO, ONE, TWO, THREE, SMALL, HALF
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, &
                        IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_ERROR
  USE IF_Prec_Core, ONLY: wp, i4
  USE MD_Mat_Def, ONLY: MD_Mat_Desc, MD_MatState, MD_MatAlgo
  USE UF_MaterialParameterTypes, ONLY: UF_Validate_Plastic_Params
  USE PH_Mat_Aux_Def, ONLY: PH_Mat_Krnl_Ctx, PH_Mat_Krnl_Algo  ! formerly PH_Mat_Base_Ctx/Base_Algo, renamed per R-09
  USE PH_Mat_Core_Types, ONLY: MatPoint_In, MatPoint_Out, MatInit_In, MatInit_Out
  USE PH_Mat_Integ_Shared, ONLY: Construct_Elastic_D, Calc_Deviatoric_Stress, &
                                 Calc_Von_Mises
  USE PH_Mat_Core_UMAT_Adapter, ONLY: Unpack_From_UMAT_Context, Pack_To_UMAT_Context
  USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
  USE RT_Com_Def, ONLY: RT_Com_Base_Ctx, RT_PNEWDT_NO_CHANGE
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_Mat_PLM_J2_Desc
  PUBLIC :: PH_Mat_PLM_J2_State
  PUBLIC :: PH_Mat_PLM_J2_UMAT_API
  PUBLIC :: PH_Mat_PLM_J2_UpdateStress
  PUBLIC :: PH_Mat_PLM_J2_UMAT
  PUBLIC :: J2_InitStateVars
  ! PH_MAT_NSTATV_PLM_J2_* exported via PARAMETER, PUBLIC below

  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_NSTATV_PLM_J2_ISO = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: PH_MAT_NSTATV_PLM_J2_KIN = 13_i4

  !----- 8-TYPE: L3 Desc / L4 PH state ---------------------------------------

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: MD_Mat_PLM_J2_Desc
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: sigma_y0 = 0.0_wp
    REAL(wp) :: H = 0.0_wp
    REAL(wp) :: alpha_thermal = 0.0_wp
    REAL(wp) :: hardening_exponent = 1.0_wp
    INTEGER(i4) :: hardening_type = 1_i4
    REAL(wp) :: kinematic_C = 0.0_wp
    REAL(wp) :: kinematic_gamma = 0.0_wp
    LOGICAL :: use_kinematic = .FALSE.
  CONTAINS
    PROCEDURE :: ValidateProps
    PROCEDURE :: InitFromProps
  END TYPE MD_Mat_PLM_J2_Desc

  TYPE, PUBLIC, EXTENDS(MD_MatState) :: PH_Mat_PLM_J2_State
    REAL(wp) :: peeq = 0.0_wp
    REAL(wp) :: back_stress(6) = 0.0_wp
    REAL(wp) :: strain_plastic(6) = 0.0_wp
    LOGICAL :: is_plastic = .FALSE.
    REAL(wp) :: ddsdde(6, 6) = 0.0_wp
    TYPE(ErrorStatusType) :: status
    LOGICAL :: converged = .TRUE.
    INTEGER(i4) :: iterations = 0_i4
  END TYPE PH_Mat_PLM_J2_State

  TYPE, PUBLIC, EXTENDS(MD_MatAlgo) :: PH_Mat_PLM_J2_Algo
    INTEGER(i4) :: ntens = 6_i4
    LOGICAL :: compute_tangent = .TRUE.
  END TYPE PH_Mat_PLM_J2_Algo

CONTAINS

  !===========================================================================
  ! [Hardening] Isotropic yield and tangent at peeq (types 1/2/3)
  !===========================================================================

  PURE FUNCTION PLM_J2_Yield_Stress_iso(desc, peeq) RESULT(sigy)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: peeq
    REAL(wp) :: sigy

    SELECT CASE (desc%hardening_type)
    CASE (1)
      sigy = desc%sigma_y0 + desc%H * peeq
    CASE (2)
      sigy = desc%sigma_y0 * (ONE + peeq)**desc%hardening_exponent
    CASE (3)
      sigy = desc%sigma_y0 + desc%H * (ONE - EXP(-desc%hardening_exponent * peeq))
    CASE DEFAULT
      sigy = desc%sigma_y0 + desc%H * peeq
    END SELECT
  END FUNCTION PLM_J2_Yield_Stress_iso

  PURE FUNCTION PLM_J2_Hardening_Tangent_iso(desc, peeq) RESULT(h_iso)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: peeq
    REAL(wp) :: h_iso

    SELECT CASE (desc%hardening_type)
    CASE (1)
      h_iso = desc%H
    CASE (2)
      h_iso = desc%sigma_y0 * desc%hardening_exponent * &
          (ONE + peeq)**(desc%hardening_exponent - ONE)
    CASE (3)
      h_iso = desc%H * desc%hardening_exponent * EXP(-desc%hardening_exponent * peeq)
    CASE DEFAULT
      h_iso = desc%H
    END SELECT
  END FUNCTION PLM_J2_Hardening_Tangent_iso

  PURE SUBROUTINE PLM_J2_Back_Stress_Update(desc, delta_gamma, n_dir, alpha)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: delta_gamma, n_dir(6)
    REAL(wp), INTENT(INOUT) :: alpha(6)

    IF (.NOT. desc%use_kinematic) RETURN
    alpha = alpha + desc%kinematic_C * delta_gamma * n_dir - &
        desc%kinematic_gamma * alpha * delta_gamma
  END SUBROUTINE PLM_J2_Back_Stress_Update

  !===========================================================================
  ! [Elastic] D^e and hydrostatic + deviatoric assembly
  !===========================================================================

  SUBROUTINE PLM_J2_Build_D_el(desc, D)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(OUT) :: D(6,6)
    REAL(wp) :: Ddp(6,6)

    CALL Construct_Elastic_D(REAL(desc%PH_MAT_E, wp), REAL(desc%nu, wp), Ddp)
    D = Ddp
  END SUBROUTINE PLM_J2_Build_D_el

  PURE SUBROUTINE Assem_Stress_From_Deviatoric(stress_trial, s_dev, sigma)
    REAL(wp), INTENT(IN) :: stress_trial(6), s_dev(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    REAL(wp) :: p_mean

    p_mean = (stress_trial(1) + stress_trial(2) + stress_trial(3)) / 3.0_wp
    sigma(1) = s_dev(1) + p_mean
    sigma(2) = s_dev(2) + p_mean
    sigma(3) = s_dev(3) + p_mean
    sigma(4:6) = s_dev(4:6)
  END SUBROUTINE Assem_Stress_From_Deviatoric

  SUBROUTINE PLM_J2_Assem_Dev(stress_trial, s_dev, sigma, ntens)
    REAL(wp), INTENT(IN) :: stress_trial(6), s_dev(6)
    REAL(wp), INTENT(OUT) :: sigma(6)
    INTEGER(i4), INTENT(IN) :: ntens
    REAL(wp) :: sg(6)

    CALL Assem_Stress_From_Deviatoric(stress_trial, s_dev, sg)
    sigma(1:ntens) = sg(1:ntens)
    IF (ntens < 6_i4) sigma(ntens+1:6) = ZERO
  END SUBROUTINE PLM_J2_Assem_Dev

  !===========================================================================
  ! [Tangent] Consistent elastoplastic modulus (isotropic tangent in J2)
  !===========================================================================

  SUBROUTINE PLM_J2_EP_Tangent(desc, sigma6, ntens, plastic_step, peeq_tan, Dout)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: desc
    REAL(wp), INTENT(IN) :: sigma6(6)
    INTEGER(i4), INTENT(IN) :: ntens
    LOGICAL, INTENT(IN) :: plastic_step
    REAL(wp), INTENT(IN) :: peeq_tan
    REAL(wp), INTENT(INOUT) :: Dout(6,6)

    REAL(wp) :: D_e(6,6), G_mod, H_tan, s_cur(6), q_cur, nvec(6), fac
    REAL(wp) :: n_dyad(6,6), sg(6)
    INTEGER(i4) :: i, j

    CALL Construct_Elastic_D(REAL(desc%PH_MAT_E, wp), REAL(desc%nu, wp), D_e)
    IF (.NOT. plastic_step) THEN
      Dout(1:ntens,1:ntens) = D_e(1:ntens,1:ntens)
      RETURN
    END IF

    G_mod = desc%PH_MAT_E / (TWO * (ONE + desc%nu))
    H_tan = PLM_J2_Hardening_Tangent_iso(desc, peeq_tan)
    sg = sigma6
    CALL Calc_Deviatoric_Stress(sg, s_cur)
    q_cur = Calc_Von_Mises(s_cur)
    IF (q_cur <= SMALL) THEN
      Dout(1:ntens,1:ntens) = D_e(1:ntens,1:ntens)
      RETURN
    END IF
    nvec = s_cur / q_cur
    DO i = 1_i4, 6_i4
      DO j = 1_i4, 6_i4
        n_dyad(i,j) = nvec(i) * nvec(j)
      END DO
    END DO
    IF (THREE * G_mod + H_tan <= SMALL) THEN
      Dout(1:ntens,1:ntens) = D_e(1:ntens,1:ntens)
      RETURN
    END IF
    fac = 6.0_wp * G_mod**2 / (THREE * G_mod + H_tan)
    D_e = D_e - fac * n_dyad
    Dout(1:ntens,1:ntens) = D_e(1:ntens,1:ntens)
  END SUBROUTINE PLM_J2_EP_Tangent

  !===========================================================================
  ! [Core] PH_Mat_PLM_J2_UMAT_API �?steps [1]..[7] in header
  !===========================================================================

  SUBROUTINE PH_Mat_PLM_J2_UMAT_API(MD_Mat_Desc, PH_Mat_Ctx, PH_Mat_State, &
      MD_Mat, PH_Mat_Algo, RT_Com_Ctx, pnewdt)
    TYPE(MD_Mat_PLM_J2_Desc), INTENT(IN) :: MD_Mat_Desc
    TYPE(PH_Mat_Krnl_Ctx), INTENT(IN) :: PH_Mat_Ctx
    TYPE(PH_Mat_PLM_J2_State), INTENT(INOUT) :: PH_Mat_State
    TYPE(PH_Mat_PLM_J2_Algo), INTENT(IN) :: MD_Mat
    TYPE(PH_Mat_Krnl_Algo), INTENT(IN) :: PH_Mat_Algo
    TYPE(RT_Com_Base_Ctx), INTENT(IN) :: RT_Com_Ctx
    REAL(wp), INTENT(INOUT) :: pnewdt

    REAL(wp) :: D_el(6,6), stress_trial(6), s_trial(6), q_trial
    REAL(wp) :: f_yield, delta_gamma, G_modulus, sigma_y_current
    REAL(wp) :: H_tangent, beta, s_dev(6), n_dir(6)
    REAL(wp) :: peeq_in
    INTEGER(i4) :: ntens
    REAL(wp) :: st_dp(6), s_dp(6)
    LOGICAL :: plastic_step

    ! [1] Bookkeeping
    CALL init_error_status(PH_Mat_State%status)
    pnewdt = RT_PNEWDT_NO_CHANGE
    PH_Mat_State%converged = .TRUE.
    PH_Mat_State%iterations = 0
    plastic_step = .FALSE.
    IF (.NOT. ALLOCATED(PH_Mat_State%stress)) ALLOCATE(PH_Mat_State%stress(6))
    IF (.NOT. ALLOCATED(PH_Mat_State%strain)) ALLOCATE(PH_Mat_State%strain(6))

    ntens = MD_Mat%ntens
    IF (ntens < 1_i4 .OR. ntens > 6_i4) THEN
      CALL init_error_status(PH_Mat_State%status, IF_STATUS_ERROR, &
          message='[PLM_J2_UMAT]: MD_Mat%ntens must be in 1..6')
      PH_Mat_State%converged = .FALSE.
      RETURN
    END IF

    ! [2] D^e
    CALL PLM_J2_Build_D_el(MD_Mat_Desc, D_el)

    ! [3] Elastic predictor
    stress_trial(1:ntens) = PH_Mat_State%stress(1:ntens) &
        + MATMUL(D_el(1:ntens,1:ntens), PH_Mat_Ctx%dstran(1:ntens))
    IF (ntens < 6_i4) stress_trial(ntens+1:6) = ZERO

    ! [4] q_trial, sigma_y (Integ_Shared uses DP Voigt)
    st_dp = stress_trial
    CALL Calc_Deviatoric_Stress(st_dp, s_dp)
    s_trial = s_dp
    q_trial = Calc_Von_Mises(st_dp)

    peeq_in = PH_Mat_State%peeq
    sigma_y_current = PLM_J2_Yield_Stress_iso(MD_Mat_Desc, peeq_in)
    f_yield = q_trial - sigma_y_current

    IF (f_yield <= ZERO) THEN
      ! [5] Elastic
      PH_Mat_State%is_plastic = .FALSE.
      PH_Mat_State%stress(1:ntens) = stress_trial(1:ntens)
      IF (MD_Mat%compute_tangent) &
        PH_Mat_State%ddsdde(1:ntens,1:ntens) = D_el(1:ntens,1:ntens)
    ELSE
      ! [6] Plastic radial return
      plastic_step = .TRUE.
      PH_Mat_State%is_plastic = .TRUE.
      PH_Mat_State%iterations = 1
      G_modulus = MD_Mat_Desc%PH_MAT_E / (TWO * (ONE + MD_Mat_Desc%nu))
      H_tangent = PLM_J2_Hardening_Tangent_iso(MD_Mat_Desc, peeq_in)

      IF (THREE * G_modulus + H_tangent <= SMALL) THEN
        CALL init_error_status(PH_Mat_State%status, IF_STATUS_ERROR, &
            message='[PLM_J2_UMAT]: 3G+H_iso non-positive; check hardening parameters')
        PH_Mat_State%converged = .FALSE.
        IF (PH_Mat_Algo%auto_cut) pnewdt = PH_Mat_Algo%pnewdt_min
        RETURN
      END IF
      IF (q_trial <= SMALL) THEN
        CALL init_error_status(PH_Mat_State%status, IF_STATUS_ERROR, &
            message='[PLM_J2_UMAT]: trial von Mises q too small for plastic return')
        PH_Mat_State%converged = .FALSE.
        IF (PH_Mat_Algo%auto_cut) pnewdt = PH_Mat_Algo%pnewdt_min
        RETURN
      END IF

      n_dir = s_trial / q_trial
      delta_gamma = (q_trial - sigma_y_current) / (THREE * G_modulus + H_tangent)
      PH_Mat_State%peeq = PH_Mat_State%peeq + delta_gamma
      beta = ONE - THREE * G_modulus * delta_gamma / q_trial
      s_dev = beta * s_trial
      CALL PLM_J2_Assem_Dev(stress_trial, s_dev, PH_Mat_State%stress, ntens)
      PH_Mat_State%strain_plastic = PH_Mat_State%strain_plastic + delta_gamma * n_dir
      CALL PLM_J2_Back_Stress_Update(MD_Mat_Desc, delta_gamma, n_dir, PH_Mat_State%back_stress)

      IF (MD_Mat%compute_tangent) &
        CALL PLM_J2_EP_Tangent(MD_Mat_Desc, PH_Mat_State%stress, ntens, plastic_step, &
            PH_Mat_State%peeq, PH_Mat_State%ddsdde)
    END IF

    ! [7]
    PH_Mat_State%status%status_code = IF_STATUS_OK
  END SUBROUTINE PH_Mat_PLM_J2_UMAT_API

  !===========================================================================
  ! [L3] Type-bound Desc validate / InitFromProps
  !===========================================================================

  SUBROUTINE ValidateProps(self, nprops, props, st)
    CLASS(MD_Mat_PLM_J2_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)
    IF (nprops < 4_i4 .OR. SIZE(props) < 4_i4) THEN
      st%status_code = IF_STATUS_INVALID
      WRITE(st%message, '(A,I2,A)') "MD_Mat_PLM_J2_Desc: need at least 4 props (have ", &
          MIN(nprops, INT(SIZE(props), i4)), ")"
      RETURN
    END IF
    CALL UF_Validate_Plastic_Params(nprops, props, st)
  END SUBROUTINE ValidateProps

  !> props(1:4)=PH_MAT_E,nu,sy0,H; (5) alpha_th; (6) exp; (7) type; (8) C_kin; (9) gam_kin;
  !> (10) use_kinematic flag (>0.5 => .TRUE.).
  SUBROUTINE InitFromProps(self, nprops, props, st)
    CLASS(MD_Mat_PLM_J2_Desc), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: nprops
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: st

    CALL init_error_status(st)
    CALL self%ValidateProps(nprops, props, st)
    IF (st%status_code == IF_STATUS_INVALID) RETURN

    self%PH_MAT_E = props(1)
    self%nu = props(2)
    self%sigma_y0 = props(3)
    self%H = MERGE(props(4), 0.0_wp, SIZE(props) >= 4)
    self%alpha_thermal = 0.0_wp
    IF (SIZE(props) >= 5) self%alpha_thermal = props(5)
    self%hardening_exponent = 1.0_wp
    self%hardening_type = 1_i4
    self%kinematic_C = 0.0_wp
    self%kinematic_gamma = 0.0_wp
    self%use_kinematic = .FALSE.
    IF (SIZE(props) >= 6) self%hardening_exponent = props(6)
    IF (SIZE(props) >= 7) self%hardening_type = INT(NINT(props(7)), KIND=i4)
    IF (self%hardening_type < 1_i4 .OR. self%hardening_type > 3_i4) self%hardening_type = 1_i4
    IF (SIZE(props) >= 8) self%kinematic_C = props(8)
    IF (SIZE(props) >= 9) self%kinematic_gamma = props(9)
    IF (SIZE(props) >= 10) THEN
      self%use_kinematic = props(10) > HALF
    ELSE
      self%use_kinematic = (ABS(self%kinematic_C) > SMALL .OR. ABS(self%kinematic_gamma) > SMALL)
    END IF
    self%cfg%matId    = 201_i4
    self%class_id     = 2_i4    ! Plastic family (MD_MAT_CATEGORY_PL)
    self%cfg%behavior = "J2 Plasticity (von Mises)"
    self%is_initialized = .TRUE.
    st%status_code = IF_STATUS_OK
  END SUBROUTINE InitFromProps

  !===========================================================================
  ! [MatInit] Registry InitStateVars hook
  !===========================================================================

  SUBROUTINE J2_InitStateVars(min_in, mout_out)
    TYPE(MatInit_In), INTENT(IN) :: min_in
    TYPE(MatInit_Out), INTENT(OUT) :: mout_out

    LOGICAL :: use_kin
    INTEGER(i4) :: nreq

    CALL init_error_status(mout_out%status)
    use_kin = .FALSE.
    IF (ALLOCATED(min_in%props)) THEN
      IF (SIZE(min_in%props) >= 10) THEN
        use_kin = min_in%props(10) > HALF
      ELSE IF (SIZE(min_in%props) >= 8) THEN
        use_kin = (ABS(min_in%props(8)) > SMALL .OR. &
            (SIZE(min_in%props) >= 9 .AND. ABS(min_in%props(9)) > SMALL))
      END IF
    END IF
    nreq = PH_MAT_NSTATV_PLM_J2_ISO
    IF (use_kin) nreq = PH_MAT_NSTATV_PLM_J2_KIN
    IF (min_in%nStatev < nreq) THEN
      mout_out%status%status_code = IF_STATUS_INVALID
      WRITE(mout_out%status%message, '(A,I0,A,I0,A)') &
          "J2_InitStateVars: nStatev >= ", nreq, " required (kin=", MERGE(1_i4, 0_i4, use_kin), ")"
      RETURN
    END IF
    IF (.NOT. ALLOCATED(min_in%props) .OR. SIZE(min_in%props) < 4) THEN
      mout_out%status%status_code = IF_STATUS_INVALID
      mout_out%status%message = "J2_InitStateVars: need props(1:4)=PH_MAT_E,nu,sigma_y0,H"
      RETURN
    END IF

    ALLOCATE(mout_out%statev(nreq))
    mout_out%statev = ZERO
    mout_out%status%status_code = IF_STATUS_OK
  END SUBROUTINE J2_InitStateVars

  !===========================================================================
  ! [MatPoint] props/statev <-> core
  !===========================================================================

  SUBROUTINE PH_Mat_PLM_J2_UpdateStress(in, out)
    TYPE(MatPoint_In), INTENT(IN) :: in
    TYPE(MatPoint_Out), INTENT(OUT) :: out

    TYPE(MD_Mat_PLM_J2_Desc) :: md_desc
    TYPE(PH_Mat_PLM_J2_State) :: ph_st
    TYPE(PH_Mat_Krnl_Ctx) :: ph_ctx
    TYPE(PH_Mat_PLM_J2_Algo) :: md_algo
    TYPE(PH_Mat_Krnl_Algo) :: ph_algo
    TYPE(RT_Com_Base_Ctx) :: rt_ctx
    TYPE(ErrorStatusType) :: st_desc
    REAL(wp) :: pnewdt
    INTEGER(i4) :: nt

    CALL init_error_status(out%status)
    out%status%status_code = IF_STATUS_OK
    IF (.NOT. ALLOCATED(in%props) .OR. SIZE(in%props) < 3) THEN
      out%status%status_code = IF_STATUS_INVALID
      WRITE(out%status%message, '(A)') "J2 UpdateStress: props missing or need >= 3"
      RETURN
    END IF

    CALL UF_Validate_Plastic_Params(INT(SIZE(in%props), i4), in%props, out%status)
    IF (out%status%status_code == IF_STATUS_INVALID) RETURN

    CALL md_desc%InitFromProps(INT(SIZE(in%props), i4), in%props, st_desc)
    IF (st_desc%status_code /= IF_STATUS_OK) THEN
      out%status = st_desc
      RETURN
    END IF

    IF (md_desc%use_kinematic .AND. ALLOCATED(in%statev)) THEN
      IF (SIZE(in%statev) > 0_i4 .AND. SIZE(in%statev) < PH_MAT_NSTATV_PLM_J2_KIN) THEN
        out%status%status_code = IF_STATUS_INVALID
        WRITE(out%status%message, '(A,I0,A)') &
            "J2 UpdateStress: kinematic needs statev >= ", PH_MAT_NSTATV_PLM_J2_KIN, " (got smaller array)"
        RETURN
      END IF
    END IF

    CALL init_error_status(ph_st%status)
    IF (.NOT. ALLOCATED(ph_st%stress)) ALLOCATE(ph_st%stress(6))
    IF (.NOT. ALLOCATED(ph_st%strain)) ALLOCATE(ph_st%strain(6))
    ph_st%stress = ZERO
    ph_st%strain = ZERO
    nt = MIN(6_i4, in%ntens)
    IF (nt < 1_i4) nt = 6_i4
    ph_st%stress(1:nt) = in%sigma_old(1:nt)
    ph_st%peeq = ZERO
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 1) ph_st%peeq = in%statev(1)
    ph_st%strain_plastic = ZERO
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= 7) &
      ph_st%strain_plastic(1:6) = in%statev(2:7)
    ph_st%back_stress = ZERO
    IF (ALLOCATED(in%statev) .AND. SIZE(in%statev) >= PH_MAT_NSTATV_PLM_J2_KIN) &
      ph_st%back_stress(1:6) = in%statev(8:13)

    ph_ctx%dstran = in%strain_inc
    md_algo%ntens = in%ntens
    IF (md_algo%ntens < 1_i4 .OR. md_algo%ntens > 6_i4) md_algo%ntens = 6_i4
    md_algo%compute_tangent = .TRUE.
    pnewdt = RT_PNEWDT_NO_CHANGE

    CALL PH_Mat_PLM_J2_UMAT_API(md_desc, ph_ctx, ph_st, md_algo, ph_algo, rt_ctx, pnewdt)

    out%stress = ph_st%stress
    out%ddsdde = ph_st%ddsdde
    out%pnewdt = pnewdt
    out%status = ph_st%status

    IF (ALLOCATED(out%statev)) DEALLOCATE(out%statev)
    IF (md_desc%use_kinematic) THEN
      ALLOCATE(out%statev(PH_MAT_NSTATV_PLM_J2_KIN))
      out%statev(1) = ph_st%peeq
      out%statev(2:7) = ph_st%strain_plastic(1:6)
      out%statev(8:13) = ph_st%back_stress(1:6)
    ELSE
      ALLOCATE(out%statev(PH_MAT_NSTATV_PLM_J2_ISO))
      out%statev(1) = ph_st%peeq
      out%statev(2:7) = ph_st%strain_plastic(1:6)
    END IF
  END SUBROUTINE PH_Mat_PLM_J2_UpdateStress

  SUBROUTINE PH_Mat_PLM_J2_UMAT(ctx, status)
    TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
    TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status

    TYPE(MatPoint_In) :: pt_in
    TYPE(MatPoint_Out) :: pt_out

    IF (PRESENT(status)) CALL init_error_status(status)
    CALL Unpack_From_UMAT_Context(ctx, pt_in)
    CALL PH_Mat_PLM_J2_UpdateStress(pt_in, pt_out)
    CALL Pack_To_UMAT_Context(pt_out, ctx)
    IF (PRESENT(status)) status = pt_out%status
  END SUBROUTINE PH_Mat_PLM_J2_UMAT

END MODULE PH_Mat_Plast_J2_UMAT_Core

