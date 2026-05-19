!===============================================================================
! MODULE: PH_Mat_Reg
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Reg — discrete MAT_* constants + minimal family kernel registry
! BRIEF:  MAT_* mirror **MD_Mat_Ids** (L3 SSOT). Kernels keyed by **PH_MAT_*** family marker.
!===============================================================================
MODULE PH_Mat_Reg
  USE IF_Prec_Core, ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK
  USE MD_Mat_Ids, ONLY: &
    MAT_ELAS_ISO, MAT_ELAS_ORTHO, MAT_ELAS_TRANSV_ISO, MAT_ELAS_ANISO, &
    MAT_PLAST_J2_ISO, MAT_PLAST_J2_TAB, MAT_PLAST_KIN_LIN, &
    MAT_PLAST_KIN_COMB, MAT_PLAST_ANISO_HIL, MAT_PLAST_JOHNSON_C, &
    MAT_PLAST_POROUS, MAT_PLAST_ORNL, MAT_PLAST_AF, &
    MAT_PLAST_CHABOCHE, MAT_PLAST_BARLAT, MAT_PLAST_CRYSTAL, &
    MAT_GEO_DP_LINEAR, MAT_GEO_DP_CAP, MAT_GEO_MC, &
    MAT_GEO_CC_CRIT, MAT_GEO_CONCRETE, MAT_GEO_FOAM_CRUSH, &
    MAT_GEO_CAM_CLAY, MAT_GEO_HOEK_BROWN, &
    MAT_HE_NEOHOOKEAN, MAT_HE_MOONEY2, MAT_HE_MOONEY5, &
    MAT_HE_OGDEN2, MAT_HE_OGDEN3, MAT_HE_YEOH, &
    MAT_HE_ARRUDA_BOYCE, MAT_HE_GENT, MAT_HE_HYPERFOAM, &
    MAT_HE_MARLOW, MAT_HE_VAN_DW, &
    MAT_VE_PRONY_DEV, MAT_VE_PRONY_VOL, MAT_VE_KELVIN, &
    MAT_VE_WLF_SHIFT, &
    MAT_CREEP_POWER, MAT_CREEP_USER, MAT_VP_TWO_LAYER, &
    MAT_CREEP_ANNEAL, MAT_CREEP_GAROFALO, MAT_CREEP_PERZYNA, &
    MAT_CREEP_DUVAUT, MAT_CREEP_BODNER, &
    MAT_DMG_DUCTILE, MAT_DMG_SHEAR, MAT_DMG_BRITTLE, &
    MAT_DMG_FLD, MAT_DMG_CZM, MAT_DMG_CONCRETE, &
    MAT_COMP_CLT, MAT_COMP_HASHIN, MAT_COMP_FABRIC, &
    MAT_COMP_JOINTED, MAT_COMP_FOAM_VE, &
    MAT_HEAT_ISO, MAT_HEAT_ORTHO, MAT_HEAT_PHASE_CHG, &
    MAT_ACOUSTIC_LINEAR, MAT_ACOUSTIC_ABSORB, &
    MAT_USER_UMAT, MAT_USER_VUMAT
  USE PH_Mat_Enum, ONLY: &
    PH_MAT_ELASTIC, PH_MAT_ELASTO_PLASTIC, PH_MAT_HYPERELASTIC, &
    PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, PH_MAT_GEOTECH, &
    PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, &
    PH_MAT_USER, PH_MAT_USER_VUMAT
  USE PH_Mat_KernelDefn, ONLY: PH_Mat_KernelBase, PH_Mat_Update_Arg
  USE PH_Mat_Plast_J2_Iso_Core, ONLY: PH_J2_Props, PH_J2_State, PH_J2_ComputeStress, &
      PH_J2_ComputeStress_Arg, PH_MAT_J2_HARD_LINEAR
  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MAT_ELAS_ISO, MAT_ELAS_ORTHO, MAT_ELAS_TRANSV_ISO, MAT_ELAS_ANISO
  PUBLIC :: MAT_PLAST_J2_ISO, MAT_PLAST_J2_TAB, MAT_PLAST_KIN_LIN
  PUBLIC :: MAT_PLAST_KIN_COMB, MAT_PLAST_ANISO_HIL, MAT_PLAST_JOHNSON_C
  PUBLIC :: MAT_PLAST_POROUS, MAT_PLAST_ORNL, MAT_PLAST_AF
  PUBLIC :: MAT_PLAST_CHABOCHE, MAT_PLAST_BARLAT, MAT_PLAST_CRYSTAL
  PUBLIC :: MAT_GEO_DP_LINEAR, MAT_GEO_DP_CAP, MAT_GEO_MC
  PUBLIC :: MAT_GEO_CC_CRIT, MAT_GEO_CONCRETE, MAT_GEO_FOAM_CRUSH
  PUBLIC :: MAT_GEO_CAM_CLAY, MAT_GEO_HOEK_BROWN
  PUBLIC :: MAT_HE_NEOHOOKEAN, MAT_HE_MOONEY2, MAT_HE_MOONEY5
  PUBLIC :: MAT_HE_OGDEN2, MAT_HE_OGDEN3, MAT_HE_YEOH
  PUBLIC :: MAT_HE_ARRUDA_BOYCE, MAT_HE_GENT, MAT_HE_HYPERFOAM
  PUBLIC :: MAT_HE_MARLOW, MAT_HE_VAN_DW
  PUBLIC :: MAT_VE_PRONY_DEV, MAT_VE_PRONY_VOL, MAT_VE_KELVIN
  PUBLIC :: MAT_VE_WLF_SHIFT
  PUBLIC :: MAT_CREEP_POWER, MAT_CREEP_USER, MAT_VP_TWO_LAYER
  PUBLIC :: MAT_CREEP_ANNEAL, MAT_CREEP_GAROFALO, MAT_CREEP_PERZYNA
  PUBLIC :: MAT_CREEP_DUVAUT, MAT_CREEP_BODNER
  PUBLIC :: MAT_DMG_DUCTILE, MAT_DMG_SHEAR, MAT_DMG_BRITTLE
  PUBLIC :: MAT_DMG_FLD, MAT_DMG_CZM, MAT_DMG_CONCRETE
  PUBLIC :: MAT_COMP_CLT, MAT_COMP_HASHIN, MAT_COMP_FABRIC
  PUBLIC :: MAT_COMP_JOINTED, MAT_COMP_FOAM_VE
  PUBLIC :: MAT_HEAT_ISO, MAT_HEAT_ORTHO, MAT_HEAT_PHASE_CHG
  PUBLIC :: MAT_ACOUSTIC_LINEAR, MAT_ACOUSTIC_ABSORB
  PUBLIC :: MAT_USER_UMAT, MAT_USER_VUMAT
  PUBLIC :: PH_Mat_Kernel_Entry
  PUBLIC :: PH_Mat_Init_AllKernels
  PUBLIC :: PH_Mat_GetKernel

  TYPE, PUBLIC :: PH_Mat_Kernel_Entry
    INTEGER(i4) :: family_marker = 0_i4
    INTEGER(i4) :: default_mat_id = 0_i4
  END TYPE PH_Mat_Kernel_Entry

  TYPE, EXTENDS(PH_Mat_KernelBase), PUBLIC :: PH_Kern_ElasticIso
  CONTAINS
    PROCEDURE :: UpdateStress => PH_Kern_ElasIso_update
    PROCEDURE :: ComputeCTM => PH_Kern_ElasIso_ctm
    PROCEDURE :: InitSDV => PH_Kern_ElasIso_init_sdv
  END TYPE PH_Kern_ElasticIso

  TYPE, EXTENDS(PH_Mat_KernelBase), PUBLIC :: PH_Kern_PlasticJ2Stub
    REAL(wp) :: last_D(6, 6) = 0.0_wp
    LOGICAL :: last_valid = .FALSE.
  CONTAINS
    PROCEDURE :: UpdateStress => PH_Kern_PlJ2_update
    PROCEDURE :: ComputeCTM => PH_Kern_PlJ2_ctm
    PROCEDURE :: InitSDV => PH_Kern_PlJ2_init_sdv
  END TYPE PH_Kern_PlasticJ2Stub

  TYPE, EXTENDS(PH_Mat_KernelBase), PUBLIC :: PH_Kern_GenericIso
  CONTAINS
    PROCEDURE :: UpdateStress => PH_Kern_GenIso_update
    PROCEDURE :: ComputeCTM => PH_Kern_GenIso_ctm
    PROCEDURE :: InitSDV => PH_Kern_GenIso_init_sdv
  END TYPE PH_Kern_GenericIso

  TYPE(PH_Kern_ElasticIso), TARGET, SAVE :: g_kern_elastic
  TYPE(PH_Kern_PlasticJ2Stub), TARGET, SAVE :: g_kern_plast
  TYPE(PH_Kern_GenericIso), TARGET, SAVE :: g_kern_generic
  LOGICAL, SAVE :: g_kernels_ready = .FALSE.

CONTAINS

  SUBROUTINE PH_Mat_Init_AllKernels()
    IF (g_kernels_ready) RETURN
    g_kern_elastic%n_sdv = 0_i4
    g_kern_plast%n_sdv = 7_i4
    g_kern_generic%n_sdv = 0_i4
    g_kernels_ready = .TRUE.
  END SUBROUTINE PH_Mat_Init_AllKernels

  SUBROUTINE PH_Mat_GetKernel(mat_type, kernel_ptr, reg_st)
    INTEGER(i4), INTENT(IN) :: mat_type
    CLASS(PH_Mat_KernelBase), POINTER, INTENT(OUT) :: kernel_ptr
    INTEGER(i4), INTENT(OUT) :: reg_st

    NULLIFY(kernel_ptr)
    reg_st = -1_i4
    IF (.NOT. g_kernels_ready) CALL PH_Mat_Init_AllKernels()

    SELECT CASE (mat_type)
    CASE (PH_MAT_ELASTIC)
      kernel_ptr => g_kern_elastic
      reg_st = 0_i4
    CASE (PH_MAT_ELASTO_PLASTIC)
      kernel_ptr => g_kern_plast
      reg_st = 0_i4
    CASE (PH_MAT_HYPERELASTIC, PH_MAT_VISCOELASTIC, PH_MAT_CREEP, PH_MAT_DAMAGE, &
          PH_MAT_GEOTECH, PH_MAT_COMPOSITE, PH_MAT_THERMAL, PH_MAT_ACOUSTIC, &
          PH_MAT_USER, PH_MAT_USER_VUMAT)
      kernel_ptr => g_kern_generic
      reg_st = 0_i4
    CASE DEFAULT
      reg_st = -1_i4
    END SELECT
  END SUBROUTINE PH_Mat_GetKernel

  PURE SUBROUTINE PH_Kern_Build_D_iso6(E, nu, D)
    REAL(wp), INTENT(IN) :: E, nu
    REAL(wp), INTENT(OUT) :: D(6, 6)
    REAL(wp) :: lam, mu, c1, c2
    D = 0.0_wp
    IF (E <= 0.0_wp .OR. nu <= -1.0_wp .OR. nu >= 0.5_wp) RETURN
    lam = E * nu / MAX((1.0_wp + nu) * (1.0_wp - 2.0_wp * nu), 1.0E-30_wp)
    mu = E / (2.0_wp * (1.0_wp + nu))
    c1 = lam + 2.0_wp * mu
    c2 = lam
    D(1, 1) = c1; D(2, 2) = c1; D(3, 3) = c1
    D(1, 2) = c2; D(1, 3) = c2; D(2, 1) = c2
    D(2, 3) = c2; D(3, 1) = c2; D(3, 2) = c2
    D(4, 4) = mu; D(5, 5) = mu; D(6, 6) = mu
  END SUBROUTINE PH_Kern_Build_D_iso6

  SUBROUTINE PH_Kern_ElasIso_update(this, uarg, istat)
    CLASS(PH_Kern_ElasticIso), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    REAL(wp) :: D(6, 6), E, nu
    INTEGER(i4) :: nt, i, j
    istat = 0_i4
    IF (.NOT. ASSOCIATED(uarg%props) .OR. SIZE(uarg%props) < 2) THEN
      istat = -1_i4
      RETURN
    END IF
    E = uarg%props(1)
    nu = uarg%props(2)
    CALL PH_Kern_Build_D_iso6(E, nu, D)
    nt = MIN(6_i4, uarg%ntens)
    DO i = 1, nt
      DO j = 1, nt
        uarg%stress_new(i) = uarg%stress_new(i) + D(i, j) * uarg%dstrain(j)
      END DO
    END DO
  END SUBROUTINE PH_Kern_ElasIso_update

  SUBROUTINE PH_Kern_ElasIso_ctm(this, uarg, istat)
    CLASS(PH_Kern_ElasticIso), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    REAL(wp) :: D(6, 6), E, nu
    istat = 0_i4
    IF (.NOT. ASSOCIATED(uarg%props) .OR. SIZE(uarg%props) < 2) THEN
      istat = -1_i4
      RETURN
    END IF
    E = uarg%props(1)
    nu = uarg%props(2)
    CALL PH_Kern_Build_D_iso6(E, nu, D)
    uarg%D_tang(1:6, 1:6) = D(1:6, 1:6)
  END SUBROUTINE PH_Kern_ElasIso_ctm

  SUBROUTINE PH_Kern_ElasIso_init_sdv(this, sdv, nsdv, istat)
    CLASS(PH_Kern_ElasticIso), INTENT(INOUT) :: this
    REAL(wp), INTENT(INOUT) :: sdv(:)
    INTEGER(i4), INTENT(IN) :: nsdv
    INTEGER(i4), INTENT(OUT) :: istat
    istat = 0_i4
    IF (nsdv > 0 .AND. SIZE(sdv) >= nsdv) sdv(1:nsdv) = 0.0_wp
  END SUBROUTINE PH_Kern_ElasIso_init_sdv

  SUBROUTINE PH_Kern_PlJ2_update(this, uarg, istat)
    CLASS(PH_Kern_PlasticJ2Stub), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    REAL(wp) :: D(6, 6), E, nu
    INTEGER(i4) :: nt, i, j
    TYPE(PH_J2_Props) :: j2p
    TYPE(PH_J2_State) :: j2s
    TYPE(PH_J2_ComputeStress_Arg) :: j2arg

    istat = 0_i4
    this%last_valid = .FALSE.

    IF (uarg%mat_model_id == MAT_PLAST_J2_ISO .AND. ASSOCIATED(uarg%props) .AND. &
        SIZE(uarg%props) >= 4_i4) THEN
      j2p%elastic%E = uarg%props(1)
      j2p%elastic%nu = uarg%props(2)
      j2p%yield%sigma_y0 = uarg%props(3)
      j2p%harden%H = uarg%props(4)
      j2p%ctrl%hardening_type = PH_MAT_J2_HARD_LINEAR
      j2p%ctrl%use_kinematic = .FALSE.

      j2s%stress%stress(1:6) = uarg%stress_new(1:6)
      j2s%plastic%eps_p_eq = 0.0_wp
      j2s%plastic%strain_p = 0.0_wp
      IF (ASSOCIATED(uarg%sdv_n) .AND. SIZE(uarg%sdv_n) >= 7_i4) THEN
        j2s%plastic%eps_p_eq = uarg%sdv_n(1)
        j2s%plastic%strain_p(1:6) = uarg%sdv_n(2:7)
      END IF

      j2arg%props = j2p
      j2arg%strain_inc = uarg%dstrain
      j2arg%state = j2s
      j2arg%pnewdt = 1.0_wp
      CALL init_error_status(j2arg%status)
      CALL PH_J2_ComputeStress(j2arg)
      IF (j2arg%status%status_code /= IF_STATUS_OK) THEN
        istat = -1_i4
        RETURN
      END IF

      uarg%stress_new(1:6) = j2arg%state%stress%stress(1:6)
      uarg%D_tang(1:6, 1:6) = j2arg%tangent(1:6, 1:6)
      this%last_D(:, :) = tan6(:, :)
      this%last_valid = .TRUE.

      IF (ALLOCATED(uarg%sdv_tr) .AND. SIZE(uarg%sdv_tr) >= 7_i4) THEN
        uarg%sdv_tr(1) = j2s%plastic%eps_p_eq
        uarg%sdv_tr(2:7) = j2s%plastic%strain_p(1:6)
      END IF
      RETURN
    END IF

    IF (.NOT. ASSOCIATED(uarg%props) .OR. SIZE(uarg%props) < 2) THEN
      istat = -1_i4
      RETURN
    END IF
    E = uarg%props(1)
    nu = uarg%props(2)
    CALL PH_Kern_Build_D_iso6(E, nu, D)
    nt = MIN(6_i4, uarg%ntens)
    DO i = 1, nt
      DO j = 1, nt
        uarg%stress_new(i) = uarg%stress_new(i) + D(i, j) * uarg%dstrain(j)
      END DO
    END DO
    IF (ALLOCATED(uarg%sdv_tr) .AND. SIZE(uarg%sdv_tr) >= 7) THEN
      uarg%sdv_tr(1:7) = 0.0_wp
    END IF
  END SUBROUTINE PH_Kern_PlJ2_update

  SUBROUTINE PH_Kern_PlJ2_ctm(this, uarg, istat)
    CLASS(PH_Kern_PlasticJ2Stub), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    IF (this%last_valid) THEN
      uarg%D_tang(:, :) = this%last_D(:, :)
      this%last_valid = .FALSE.
      istat = 0_i4
      RETURN
    END IF
    CALL g_kern_elastic%ComputeCTM(uarg, istat)
  END SUBROUTINE PH_Kern_PlJ2_ctm

  SUBROUTINE PH_Kern_PlJ2_init_sdv(this, sdv, nsdv, istat)
    CLASS(PH_Kern_PlasticJ2Stub), INTENT(INOUT) :: this
    REAL(wp), INTENT(INOUT) :: sdv(:)
    INTEGER(i4), INTENT(IN) :: nsdv
    INTEGER(i4), INTENT(OUT) :: istat
    istat = 0_i4
    IF (nsdv > 0 .AND. SIZE(sdv) >= nsdv) sdv(1:nsdv) = 0.0_wp
  END SUBROUTINE PH_Kern_PlJ2_init_sdv

  SUBROUTINE PH_Kern_GenIso_update(this, uarg, istat)
    CLASS(PH_Kern_GenericIso), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    istat = 0_i4
    IF (.NOT. ASSOCIATED(uarg%props) .OR. SIZE(uarg%props) < 2) THEN
      istat = -1_i4
      RETURN
    END IF
    CALL g_kern_elastic%UpdateStress(uarg, istat)
  END SUBROUTINE PH_Kern_GenIso_update

  SUBROUTINE PH_Kern_GenIso_ctm(this, uarg, istat)
    CLASS(PH_Kern_GenericIso), INTENT(INOUT) :: this
    TYPE(PH_Mat_Update_Arg), INTENT(INOUT) :: uarg
    INTEGER(i4), INTENT(OUT) :: istat
    CALL g_kern_elastic%ComputeCTM(uarg, istat)
  END SUBROUTINE PH_Kern_GenIso_ctm

  SUBROUTINE PH_Kern_GenIso_init_sdv(this, sdv, nsdv, istat)
    CLASS(PH_Kern_GenericIso), INTENT(INOUT) :: this
    REAL(wp), INTENT(INOUT) :: sdv(:)
    INTEGER(i4), INTENT(IN) :: nsdv
    INTEGER(i4), INTENT(OUT) :: istat
    istat = 0_i4
    IF (nsdv > 0 .AND. SIZE(sdv) >= nsdv) sdv(1:nsdv) = 0.0_wp
  END SUBROUTINE PH_Kern_GenIso_init_sdv

END MODULE PH_Mat_Reg


