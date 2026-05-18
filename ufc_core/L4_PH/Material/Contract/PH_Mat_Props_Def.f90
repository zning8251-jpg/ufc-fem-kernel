!===============================================================================
! MODULE: PH_Mat_Props_Def
! LAYER:  L4_PH
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Material property/statev layout constants for UMAT ABI compliance.
!   W1: index constants describe **props(**:**)** layout filled from **Populate → desc%props**;
!   keep PH ↔ L3 ordering aligned with **MD_Mat_EL*_PopulateMap** / registry where applicable.
!===============================================================================

MODULE PH_Mat_Props_Def
  USE IF_Prec_Core, ONLY: wp, i4
  IMPLICIT NONE
  PRIVATE

  !--------------------------------------------------------------------
  ! Section 1: props ( L3_MD )
  !--------------------------------------------------------------------
  ! props
  ! L3_MD/Material/MD_Mat_Elastic.f90 (MODULE MD_Mat_Elastic)

  ! Elastic (mat_id 101-112)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ELASTIC_E   = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ELASTIC_NU  = 2_i4  ! nu
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ELASTIC_ALPHA = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ELASTIC_K   = 4_i4  ! property-array index (layout constant)

  ! Orthotropic Elastic (mat_id 102)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_E11 = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_E22 = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_E33 = 3_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_NU12 = 4_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_NU13 = 5_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_NU23 = 6_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_G12 = 7_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_G13 = 8_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ORTHO_G23 = 9_i4

  ! Transversely Isotropic (mat_id 103)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_TRANS_E1 = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_TRANS_E2 = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_TRANS_NU12 = 3_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_TRANS_G12 = 4_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_TRANS_G23 = 5_i4

  ! Fully Anisotropic (mat_id 104): 21 constants C(21)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ANISO_C11 = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ANISO_C12 = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_ANISO_C13 = 3_i4
  ! ... C14-C66 (4-21)

  ! Porous Elastic (mat_id 105)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_POROUS_E0 = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_POROUS_NU0 = 2_i4  ! nu
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_POROUS_SIGMAC0 = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_POROUS_H = 4_i4  ! property-array index (layout constant)

  ! Hypoelastic (mat_id 106): PH_MAT_E,nu
  ! Thermo-Piezo (mat_id 110): 30+ parameters

  ! Plastic (mat_id 201-220)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_E     = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_NU    = 2_i4  ! nu
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_SY    = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_H     = 4_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_FRIC  = 5_i4  ! ( )
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_COH    = 6_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_PLASTIC_DIL   = 7_i4  ! ( )

  ! J2 Plasticity (mat_id 201)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_J2_E   = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_J2_NU  = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_J2_SY0 = 3_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_J2_H   = 4_i4

  ! Drucker-Prager (mat_id 202)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DP_E   = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DP_NU  = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DP_SY  = 3_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DP_H   = 4_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DP_PHI = 5_i4  ! property-array index (layout constant)

  ! Mohr-Coulomb (mat_id 211)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_MC_E   = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_MC_NU  = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_MC_C   = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_MC_PHI = 4_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_MC_PSI = 5_i4  ! property-array index (layout constant)

  ! Hill Plasticity (mat_id 220)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_E11 = 1_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_E22 = 2_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_E33 = 3_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_NU12 = 4_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_G12 = 5_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_G13 = 6_i4
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HILL_G23 = 7_i4

  ! HyperElastic (mat_id 301-310)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_C10   = 1_i4  ! Mooney-Rivlin C10
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_C01   = 2_i4  ! Mooney-Rivlin C01
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_D1    = 3_i4  ! D1
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_N     = 4_i4  ! property-array index (layout constant)

  ! Viscoelastic (mat_id 401-408)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_E    = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_NU   = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_ETA  = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_N    = 4_i4  ! Norton n
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_A    = 5_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_Q    = 6_i4  ! property-array index (layout constant)

  ! Norton Creep (mat_id 406)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NORTON_A = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NORTON_N = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NORTON_Q = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NORTON_E = 4_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NORTON_T = 5_i4  ! property-array index (layout constant)

  ! Damage (mat_id 501-509)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_E    = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_NU   = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_SF   = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_DC   = 4_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_GC   = 5_i4  ! Gc
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_L0   = 6_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_MU    = 1_i4  ! Ogden mu
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_HYPER_ALPHA = 2_i4  ! Ogden alpha

  ! Neo-Hookean (mat_id 303)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NH_C10  = 1_i4  ! C10 = mu/2
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_NH_D1   = 2_i4  ! D1 = 2/K

  ! Viscoelastic (mat_id 401-408)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_E    = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_NU   = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_ETA  = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_VISC_N    = 4_i4  ! Norton n

  ! Damage (mat_id 501-509)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_E    = 1_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_NU   = 2_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_SF   = 3_i4  ! property-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_PROP_DMG_DC   = 4_i4  ! property-array index (layout constant)

  !--------------------------------------------------------------------
  ! Section 2: statev
  !--------------------------------------------------------------------
  ! statev UMAT ABI
  ! TYPE
  ! See module header.

  ! See module header.
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_ANALYSIS_TYPE = 1_i4

  ! HyperElastic (0-9)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F11   = 1_i4  ! F(1,1)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F22   = 2_i4  ! F(2,2)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F33   = 3_i4  ! F(3,3)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F12   = 4_i4  ! F(1,2)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F23   = 5_i4  ! F(2,3)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_F13   = 6_i4  ! F(1,3)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_J     = 7_i4  ! J=det(F)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_I1    = 8_i4  ! I1
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_W     = 9_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_HYPER_MAX   = 9_i4

  ! Plastic (10-29)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EQP   = 10_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_VOLP = 11_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS1 = 12_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS2 = 13_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS3 = 14_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS4 = 15_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS5 = 16_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_EPS6 = 17_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_ALPHA = 18_i4  ! alpha
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_R    = 19_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_PLASTIC_MAX  = 29_i4

  ! Gurson/GTN ( Plastic )
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_GURSON_VOID = 10_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_GURSON_FN   = 11_i4  ! f_N

  ! Visco (30-39)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_VISC_CREEP  = 30_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_VISC_TIME  = 31_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_VISC_MAX   = 39_i4

  ! Damage (40-49)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_DMG_D      = 40_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_DMG_FVOID  = 41_i4  ! state-variable-array index (layout constant)
  INTEGER(i4), PUBLIC, PARAMETER :: PH_MAT_STATEV_DMG_MAX    = 49_i4

  !--------------------------------------------------------------------
  ! Section 3:
  !--------------------------------------------------------------------
  ! See module header.
  ! - (UMAT ): ctx%props/statev ABI
  ! - ( ): XXX_Params/XXX_State TYPE
  ! - : UMAT SUBROUTINE PH_MAT_UMAT_XXX
  !
  ! See module header.
  !   PH_Mat_Constit_Core
  ! �?PH_Mat_Reg_Core ( )
  !       �?PH_UMAT_Intf (ctx,status)
  ! �?PH_MAT_UMAT_XXX ( )
  ! �?props + statev �?XXX_Params/State
  !           �?MD_XXX_Calc_Stress
  ! �?sigma/ddsdde + statev
  !--------------------------------------------------------------------

CONTAINS

  !--------------------------------------------------------------------
  ! props
  !--------------------------------------------------------------------

  ! > @brief ctx%props
  SUBROUTINE Extract_Elastic_Props(ctx, PH_MAT_E, nu, alpha, status)
    TYPE(PH_UMAT_Context), INTENT(IN)  :: ctx
    REAL(wp), INTENT(OUT) :: PH_MAT_E, nu
    REAL(wp), INTENT(OUT), OPTIONAL :: alpha
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) status = 0
    PH_MAT_E  = MERGE(ctx%props(PH_MAT_PROP_ELASTIC_E), 0.0_wp, ctx%nprops >= 1)
    nu = MERGE(ctx%props(PH_MAT_PROP_ELASTIC_NU), 0.3_wp, ctx%nprops >= 2)
    IF (PRESENT(alpha)) alpha = MERGE(ctx%props(PH_MAT_PROP_ELASTIC_ALPHA), 0.0_wp, ctx%nprops >= 3)
  END SUBROUTINE Extract_Elastic_Props

  ! > @brief ctx%props
  SUBROUTINE Extract_Plastic_Props(ctx, PH_MAT_E, nu, sy, h, fric, coh, dil, status)
    TYPE(PH_UMAT_Context), INTENT(IN)  :: ctx
    REAL(wp), INTENT(OUT) :: PH_MAT_E, nu, sy, h
    REAL(wp), INTENT(OUT), OPTIONAL :: fric, coh, dil
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) status = 0
    PH_MAT_E  = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_E), 200.0e3_wp, ctx%nprops >= 1)
    nu = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_NU), 0.3_wp, ctx%nprops >= 2)
    sy = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_SY), 200.0_wp, ctx%nprops >= 3)
    h  = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_H), 0.0_wp, ctx%nprops >= 4)
    IF (PRESENT(fric)) fric = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_FRIC), 0.0_wp, ctx%nprops >= 5)
    IF (PRESENT(coh))  coh  = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_COH), 0.0_wp, ctx%nprops >= 6)
    IF (PRESENT(dil))  dil  = MERGE(ctx%props(PH_MAT_PROP_PLASTIC_DIL), 0.0_wp, ctx%nprops >= 7)
  END SUBROUTINE Extract_Plastic_Props

  ! > @brief ctx%props
  SUBROUTINE Extract_Hyperelastic_Props(ctx, c10, c01, d1, status)
    TYPE(PH_UMAT_Context), INTENT(IN)  :: ctx
    REAL(wp), INTENT(OUT) :: c10, c01, d1
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (PRESENT(status)) status = 0
    c10 = MERGE(ctx%props(PH_MAT_PROP_HYPER_C10), 0.0_wp, ctx%nprops >= 1)
    c01 = MERGE(ctx%props(PH_MAT_PROP_HYPER_C01), 0.0_wp, ctx%nprops >= 2)
    d1  = MERGE(ctx%props(PH_MAT_PROP_HYPER_D1), 1.0e-6_wp, ctx%nprops >= 3)
  END SUBROUTINE Extract_Hyperelastic_Props

  !--------------------------------------------------------------------
  ! statev /
  !--------------------------------------------------------------------

  ! > @brief F HyperElastic
  SUBROUTINE Extract_Deformation_Gradient(statev, F, status)
    REAL(wp), INTENT(IN)  :: statev(:)
    REAL(wp), INTENT(OUT) :: F(3,3)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    F = 0.0_wp
    F(1,1) = MERGE(statev(PH_MAT_STATEV_HYPER_F11), 1.0_wp, SIZE(statev) >= 1)
    F(2,2) = MERGE(statev(PH_MAT_STATEV_HYPER_F22), 1.0_wp, SIZE(statev) >= 2)
    F(3,3) = MERGE(statev(PH_MAT_STATEV_HYPER_F33), 1.0_wp, SIZE(statev) >= 3)
    F(1,2) = MERGE(statev(PH_MAT_STATEV_HYPER_F12), 0.0_wp, SIZE(statev) >= 4)
    F(2,3) = MERGE(statev(PH_MAT_STATEV_HYPER_F23), 0.0_wp, SIZE(statev) >= 5)
    F(1,3) = MERGE(statev(PH_MAT_STATEV_HYPER_F13), 0.0_wp, SIZE(statev) >= 6)
    F(2,1) = F(1,2)
    F(3,1) = F(1,3)
    F(3,2) = F(2,3)
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Extract_Deformation_Gradient

  ! > @brief F HyperElastic
  SUBROUTINE Pack_Deformation_Gradient(F, statev, status)
    REAL(wp), INTENT(IN)  :: F(3,3)
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (SIZE(statev) >= 1) statev(PH_MAT_STATEV_HYPER_F11) = F(1,1)
    IF (SIZE(statev) >= 2) statev(PH_MAT_STATEV_HYPER_F22) = F(2,2)
    IF (SIZE(statev) >= 3) statev(PH_MAT_STATEV_HYPER_F33) = F(3,3)
    IF (SIZE(statev) >= 4) statev(PH_MAT_STATEV_HYPER_F12) = F(1,2)
    IF (SIZE(statev) >= 5) statev(PH_MAT_STATEV_HYPER_F23) = F(2,3)
    IF (SIZE(statev) >= 6) statev(PH_MAT_STATEV_HYPER_F13) = F(1,3)
    IF (SIZE(statev) >= 7) statev(PH_MAT_STATEV_HYPER_J)   = F(1,1)*F(2,2)*F(3,3)  ! J from F11*F22*F33 (packed statev)
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Pack_Deformation_Gradient

  ! > @brief
  SUBROUTINE Extract_Plastic_State(statev, eqp, volp, eps_p, status)
    REAL(wp), INTENT(IN)  :: statev(:)
    REAL(wp), INTENT(OUT) :: eqp, volp, eps_p(6)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    eqp  = MERGE(statev(PH_MAT_STATEV_PLASTIC_EQP), 0.0_wp, SIZE(statev) >= 10)
    volp = MERGE(statev(PH_MAT_STATEV_PLASTIC_VOLP), 0.0_wp, SIZE(statev) >= 11)
    eps_p = 0.0_wp
    IF (SIZE(statev) >= 12) eps_p(1) = statev(PH_MAT_STATEV_PLASTIC_EPS1)
    IF (SIZE(statev) >= 13) eps_p(2) = statev(PH_MAT_STATEV_PLASTIC_EPS2)
    IF (SIZE(statev) >= 14) eps_p(3) = statev(PH_MAT_STATEV_PLASTIC_EPS3)
    IF (SIZE(statev) >= 15) eps_p(4) = statev(PH_MAT_STATEV_PLASTIC_EPS4)
    IF (SIZE(statev) >= 16) eps_p(5) = statev(PH_MAT_STATEV_PLASTIC_EPS5)
    IF (SIZE(statev) >= 17) eps_p(6) = statev(PH_MAT_STATEV_PLASTIC_EPS6)
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Extract_Plastic_State

  ! > @brief
  SUBROUTINE Pack_Plastic_State(eqp, volp, eps_p, statev, status)
    REAL(wp), INTENT(IN)  :: eqp, volp, eps_p(6)
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (SIZE(statev) >= 10) statev(PH_MAT_STATEV_PLASTIC_EQP) = eqp
    IF (SIZE(statev) >= 11) statev(PH_MAT_STATEV_PLASTIC_VOLP) = volp
    IF (SIZE(statev) >= 12) statev(PH_MAT_STATEV_PLASTIC_EPS1) = eps_p(1)
    IF (SIZE(statev) >= 13) statev(PH_MAT_STATEV_PLASTIC_EPS2) = eps_p(2)
    IF (SIZE(statev) >= 14) statev(PH_MAT_STATEV_PLASTIC_EPS3) = eps_p(3)
    IF (SIZE(statev) >= 15) statev(PH_MAT_STATEV_PLASTIC_EPS4) = eps_p(4)
    IF (SIZE(statev) >= 16) statev(PH_MAT_STATEV_PLASTIC_EPS5) = eps_p(5)
    IF (SIZE(statev) >= 17) statev(PH_MAT_STATEV_PLASTIC_EPS6) = eps_p(6)
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Pack_Plastic_State

  ! > @brief
  SUBROUTINE Extract_Damage_State(statev, d, f_void, status)
    REAL(wp), INTENT(IN)  :: statev(:)
    REAL(wp), INTENT(OUT) :: d, f_void
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    d      = MERGE(statev(PH_MAT_STATEV_DMG_D), 0.0_wp, SIZE(statev) >= 40)
    f_void = MERGE(statev(PH_MAT_STATEV_DMG_FVOID), 0.0_wp, SIZE(statev) >= 41)
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Extract_Damage_State

  ! > @brief
  SUBROUTINE Pack_Damage_State(d, f_void, statev, status)
    REAL(wp), INTENT(IN)  :: d, f_void
    REAL(wp), INTENT(OUT) :: statev(:)
    INTEGER(i4), INTENT(OUT), OPTIONAL :: status

    IF (SIZE(statev) >= 40) statev(PH_MAT_STATEV_DMG_D) = d
    IF (SIZE(statev) >= 41) statev(PH_MAT_STATEV_DMG_FVOID) = f_void
    IF (PRESENT(status)) status = 0
  END SUBROUTINE Pack_Damage_State

  !======================================================================
  ! Section 5: HyperElas/Therm
  !======================================================================
  !
  ! HyperElas :
  ! --------------------
  ! -> PH_ +
  ! --------------------
  ! Yeoh_Params        ->  HYPER_Yeoh_Params
  ! Yeoh_State         ->  HYPER_Yeoh_State
  ! MD_Yeoh_Init       ->  PH_Mat_Yeoh_Init
  ! MD_Yeoh_Calc_Stress->  PH_Mat_Yeoh_Calc
  ! PH_MAT_UMAT_Yeoh_Core     ->  PH_MAT_UMAT_HyperElas_304
  !
  ! Ogden_Params       ->  HYPER_Ogden_Params
  ! Ogden_State        ->  HYPER_Ogden_State
  ! MD_Ogden_Init      ->  PH_Mat_Ogden_Init
  ! MD_Ogden_Calc      ->  PH_Mat_Ogden_Calc
  ! PH_MAT_UMAT_Ogden_Core    ->  PH_MAT_UMAT_HyperElas_302
  !
  ! MR_Params (Mooney-Rivlin) -> HYPER_MR_Params
  ! MR_State          ->  HYPER_MR_State
  ! MD_MR_Init        ->  PH_Mat_MR_Init
  ! MD_MR_Calc        ->  PH_Mat_MR_Calc
  ! PH_MAT_UMAT_MR_Core      ->  PH_MAT_UMAT_HyperElas_301
  !
  ! NH_Params (Neo-Hookean) -> HYPER_NH_Params
  ! NH_State           ->  HYPER_NH_State
  ! MD_NH_Init         ->  PH_Mat_NH_Init
  ! MD_NH_Calc         ->  PH_Mat_NH_Calc
  ! PH_MAT_UMAT_NH_Core       ->  PH_MAT_UMAT_HyperElas_303
  !
  ! AB_Params (Arruda-Boyce) -> HYPER_AB_Params
  ! AB_State           ->  HYPER_AB_State
  ! MD_AB_Init         ->  PH_Mat_AB_Init
  ! MD_AB_Calc         ->  PH_Mat_AB_Calc
  ! PH_MAT_UMAT_AB_Core       ->  PH_MAT_UMAT_HyperElas_305
  !
  ! --------------------
  ! Therm :
  ! --------------------
  ! -> PH_ +
  ! --------------------
  ! Therm_Params        ->  THERM_Params
  ! Therm_State         ->  THERM_State
  ! MD_Therm_Init      ->  PH_Mat_Therm_Init
  ! MD_Therm_Calc      ->  PH_Mat_Therm_Calc
  !
  ! ThermElec_Params   ->  THERM_Elec_Params
  ! ThermElec_State    ->  THERM_Elec_State
  ! MD_ThermElec_Init ->  PH_Mat_ThermElec_Init
  ! MD_ThermElec_Calc  ->  PH_Mat_ThermElec_Calc
  !
  ! Piezo_Params       ->  PIEZO_Params
  ! Piezo_State        ->  PIEZO_State
  ! MD_Piezo_Init     ->  PH_Mat_Piezo_Init
  ! MD_Piezo_Calc     ->  PH_Mat_Piezo_Calc
  !
  ! See module header.
  ! 1. TYPE : [ ]_[ ]_Params/State ( HYPER_Yeoh_Params)
  ! 2. : PH_Mat_[ ]_[ ] ( PH_Mat_Yeoh_Init)
  ! 3. UMAT : PH_MAT_UMAT_[ ]_[mat_id]_[ ] ( PH_MAT_UMAT_HyperElas_304)
  !======================================================================

END MODULE PH_Mat_Props_Def
!======================================================================
! ( UMAT ):
!
! SUBROUTINE PH_MAT_UMAT_NeoHookean_Core(ctx, status)
!   USE PH_MatStandards_Algo, ONLY: &
!        Extract_Hyperelastic_Props, &
!        Extract_Deformation_Gradient, Pack_Deformation_Gradient
!   USE PH_Mat_UMAT_Def, ONLY: PH_UMAT_Context
!   TYPE(PH_UMAT_Context), INTENT(INOUT) :: ctx
!
! ! 1. props
!   CALL Extract_Hyperelastic_Props(ctx, C10, C01, D1)
!
! ! 2. statev
!   CALL Extract_Deformation_Gradient(ctx%statev, F)
!
! ! 3. ...
!
! ! 4. statev
!   CALL Pack_Deformation_Gradient(PH_MAT_F_, ctx%statev)
! END SUBROUTINE
!======================================================================
