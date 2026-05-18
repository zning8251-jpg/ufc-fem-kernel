!===============================================================================
! MODULE: MD_Mat_Ids
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Canonical material ID constants for 11-family constitutive models.
!         **MAT_*** rows are the numeric SSOT for family planning (see **MD_MAT_TOTAL_MODELS**).
!         **Abaqus614 Leaf41** (`docs/03_Domain_Pillars/MaterialPillar/Abaqus614_Material_Leaf41.md`) is a
!         **41-row semantic** classification: many **MAT_*** slots + legacy registry IDs still exist;
!         strict 41 acceptance uses **`Leaf41_UFC_Crosswalk.csv`** + quarantine rules in
!         **`UFC/REPORTS/MT0_Material_Leaf41_COMPAT_DRIFT.md`** (MT-0.3).
!         **MD_MAT_ID_*** block: L3 domain leaf dispatch integers used by `Material/*/MD_Mat_*.f90`;
!         reconcile with **MAT_*** in MT-0.4+ MRs when drift is closed.
!         **W1**：**mat_id** 与 **`cfg%matModel`** / **PH_Mat_Desc_Effective_Model** / **RT_Mat_Brg** 路由一致；改号须联动注册与 Dispatch。
!===============================================================================
MODULE MD_Mat_Ids
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Family 01: Linear Elastic (101~104) — MT-0.4 aligned with MatLib / MD_MAT_ELAS_* / Leaf41 rows 1–4
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ELAS_ISO        = 101_i4  ! Isotropic (*ELASTIC TYPE=ISOTROPIC)
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ELAS_ORTHO      = 102_i4  ! Orthotropic
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ELAS_TRANSV_ISO  = 103_i4  ! Transversely isotropic (*TRAVERSE)
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ELAS_ANISO      = 104_i4  ! Fully anisotropic (21 props)

  !-----------------------------------------------------------------------------
  ! Family 02: Plasticity - Rate Independent (201~212 + 219 J2-tab) -- MT-0.5:
  !   **MAT_PLAST_J2_TAB=219** decouples J2 tabular from registry **202** (Drucker–Prager).
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_J2_ISO    = 201_i4  ! J2 isotropic hardening
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_KIN_LIN   = 203_i4  ! Kinematic linear
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_KIN_COMB  = 204_i4  ! Kinematic combined
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_ANISO_HIL = 205_i4  ! Hill anisotropic
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_JOHNSON_C = 206_i4  ! Johnson-Cook
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_POROUS    = 207_i4  ! Porous metal (GTN)
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_ORNL      = 208_i4  ! ORNL constitutive
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_AF        = 209_i4  ! Armstrong-Frederick
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_CHABOCHE  = 210_i4  ! Chaboche
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_BARLAT    = 211_i4  ! Barlat
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_CRYSTAL   = 212_i4  ! Crystal plasticity
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_PLAST_J2_TAB    = 219_i4  ! J2 tabular hardening (SSOT; not 202/DP)

  !-----------------------------------------------------------------------------
  ! Family 03: Geotechnical Plasticity (301~308) -- 8 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_DP_LINEAR   = 301_i4  ! Drucker-Prager linear
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_DP_CAP      = 302_i4  ! Drucker-Prager cap
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_MC          = 303_i4  ! Mohr-Coulomb
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_CC_CRIT     = 304_i4  ! Critical-state
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_CONCRETE    = 305_i4  ! Concrete damage plast.
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_FOAM_CRUSH  = 306_i4  ! Crushable foam
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_CAM_CLAY    = 307_i4  ! Cam-Clay
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_GEO_HOEK_BROWN  = 308_i4  ! Hoek-Brown

  !-----------------------------------------------------------------------------
  ! Family 04: Hyperelastic / Finite Deformation (401~411) -- 11 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_NEOHOOKEAN   = 401_i4  ! Neo-Hookean
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_MOONEY2      = 402_i4  ! Mooney-Rivlin 2-param
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_MOONEY5      = 403_i4  ! Mooney-Rivlin 5-param
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_OGDEN2       = 404_i4  ! Ogden 2-term
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_OGDEN3       = 405_i4  ! Ogden 3-term
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_YEOH         = 406_i4  ! Yeoh
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_ARRUDA_BOYCE = 407_i4  ! Arruda-Boyce
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_GENT         = 408_i4  ! Gent
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_HYPERFOAM    = 409_i4  ! Hyperfoam
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_MARLOW       = 410_i4  ! Marlow data-driven
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HE_VAN_DW       = 411_i4  ! Van der Waals

  !-----------------------------------------------------------------------------
  ! Family 05: Viscoelastic (501~504) -- 4 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_VE_PRONY_DEV    = 501_i4  ! Prony deviatoric
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_VE_PRONY_VOL    = 502_i4  ! Prony volumetric
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_VE_KELVIN       = 503_i4  ! Kelvin-Voigt
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_VE_WLF_SHIFT    = 504_i4  ! WLF time-temp shift

  !-----------------------------------------------------------------------------
  ! Family 06: Viscoplastic / Creep (601~608) -- 8 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_POWER     = 601_i4  ! Power-law creep
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_USER      = 602_i4  ! User-defined creep
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_VP_TWO_LAYER    = 603_i4  ! Two-layer viscoplastic
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_ANNEAL    = 604_i4  ! Annealing creep
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_GAROFALO  = 605_i4  ! Garofalo
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_PERZYNA   = 606_i4  ! Perzyna
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_DUVAUT    = 607_i4  ! Duvaut-Lions
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_CREEP_BODNER    = 608_i4  ! Bodner-Partom

  !-----------------------------------------------------------------------------
  ! Family 07: Damage & Fracture (701~706) -- 6 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_DUCTILE     = 701_i4  ! Ductile damage
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_SHEAR       = 702_i4  ! Shear damage
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_BRITTLE     = 703_i4  ! Brittle fracture
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_FLD         = 704_i4  ! Forming limit diagram
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_CZM         = 705_i4  ! Cohesive zone model
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_DMG_CONCRETE    = 706_i4  ! Concrete damage (CDP)

  !-----------------------------------------------------------------------------
  ! Family 08: Composite (801~805) -- 5 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_COMP_CLT        = 801_i4  ! Classical laminate
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_COMP_HASHIN     = 802_i4  ! Hashin failure
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_COMP_FABRIC     = 803_i4  ! Woven fabric
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_COMP_JOINTED    = 804_i4  ! Jointed material
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_COMP_FOAM_VE    = 805_i4  ! Viscoelastic foam

  !-----------------------------------------------------------------------------
  ! Family 09: Thermal / Heat Transfer (901~903) -- 3 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HEAT_ISO        = 901_i4  ! Isotropic conductivity
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HEAT_ORTHO      = 902_i4  ! Orthotropic conductivity
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_HEAT_PHASE_CHG  = 903_i4  ! Phase-change

  !-----------------------------------------------------------------------------
  ! Family 10: Acoustic / Fluid-Structure (1001~1002) -- 2 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ACOUSTIC_LINEAR  = 1001_i4 ! Linear acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_ACOUSTIC_ABSORB  = 1002_i4 ! Absorptive acoustic

  !-----------------------------------------------------------------------------
  ! Family 11: User-Defined Extension (1101~1102) -- 2 models
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_USER_UMAT        = 1101_i4 ! UMAT (standard)
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_USER_VUMAT       = 1102_i4 ! VUMAT (explicit)

  !-----------------------------------------------------------------------------
  ! Family range boundaries (for dispatch / validation)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_ELAS_MIN  = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_ELAS_MAX  = 104_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_PLAST_MIN = 201_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_PLAST_MAX = 219_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_GEO_MIN   = 301_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_GEO_MAX   = 308_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_HE_MIN    = 401_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_HE_MAX    = 411_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_VE_MIN    = 501_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_VE_MAX    = 504_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_CREEP_MIN = 601_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_CREEP_MAX = 608_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_DMG_MIN   = 701_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_DMG_MAX   = 706_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_COMP_MIN  = 801_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_COMP_MAX  = 805_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_HEAT_MIN  = 901_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_HEAT_MAX  = 903_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_ACOU_MIN  = 1001_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_ACOU_MAX  = 1002_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_USER_MIN  = 1101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MAT_FAMILY_USER_MAX  = 1102_i4

  !-----------------------------------------------------------------------------
  ! Total model count
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_TOTAL_MODELS = 65_i4

  !-----------------------------------------------------------------------------
  ! L3 domain leaf dispatch IDs (numeric mat_id in domain *.f90)
  ! Leaf41 crosswalk: docs/03_Domain_Pillars/MaterialPillar/Leaf41_UFC_Crosswalk.csv
  ! NOTE: Reconcile remaining drift vs **MAT_*** in follow-on MRs (see MT0 drift report).
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_101 = 101_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_102 = 102_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_103 = 103_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_104 = 104_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_105 = 105_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_106 = 106_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_107 = 107_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_108 = 108_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_109 = 109_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_110 = 110_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_111 = 111_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_112 = 112_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_202 = 202_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_203 = 203_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_204 = 204_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_209 = 209_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_213 = 213_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_215 = 215_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_216 = 216_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_217 = 217_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_218 = 218_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_219 = 219_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_221 = 221_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_222 = 222_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_301 = 301_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_302 = 302_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_303 = 303_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_304 = 304_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_305 = 305_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_306 = 306_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_307 = 307_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_308 = 308_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_309 = 309_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_310 = 310_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_401 = 401_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_402 = 402_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_403 = 403_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_404 = 404_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_405 = 405_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_406 = 406_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_407 = 407_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_408 = 408_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_501 = 501_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_502 = 502_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_503 = 503_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_504 = 504_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_505 = 505_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_506 = 506_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_507 = 507_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_508 = 508_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_509 = 509_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_601 = 601_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_602 = 602_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_603 = 603_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_604 = 604_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_605 = 605_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_606 = 606_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_607 = 607_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_701 = 701_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_702 = 702_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_703 = 703_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_704 = 704_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_705 = 705_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_706 = 706_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_707 = 707_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ID_708 = 708_i4

  ! Abaqus614 Leaf41 row 1 (ISO linear elastic) — semantic index not equal to mat_id
  INTEGER(i4), PARAMETER, PUBLIC :: MD_LEAF41_ISO_LINEAR = 1_i4

END MODULE MD_Mat_Ids
