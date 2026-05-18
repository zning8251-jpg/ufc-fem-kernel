!===============================================================================
! MODULE: MD_Mat_Family_Def
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Def
! BRIEF:  Three-level nested TYPE system for material families.
!         Level 1: Family (11 main families, corresponds to ABAQUS keyword main name)
!         Level 2: Sub-type (65 variants, corresponds to ABAQUS TYPE= parameter)
!         Level 3: Property flags (bit flags, corresponds to DEPENDENCIES, MODULI, etc.)
!         **Nesting depth strictly limited to 3 levels**
!
!         Design principle:
!         - family_type: Main material family (ELASTIC, PLASTIC, etc.)
!         - sub_type: Material variant (ISOTROPIC, SHEAR, etc.)
!         - property_flags: Additional properties (bit flags, combinable)
!
!         Mapping to ABAQUS keywords:
!         *ELASTIC, TYPE=SHEAR, DEPENDENCIES=1
!           └─ family_type = MD_MAT_FAMILY_ELASTIC
!              └─ sub_type = MD_MAT_ELAS_SUB_SHEAR
!                 └─ property_flags = MD_MAT_PROP_TEMP_DEP
!===============================================================================
MODULE MD_Mat_Family_Def
  USE IF_Prec_Core, ONLY: i4
  IMPLICIT NONE
  PRIVATE

  !-----------------------------------------------------------------------------
  ! Level 1: Material Family (11 main families)
  ! Corresponds to ABAQUS keyword main name (*ELASTIC, *PLASTIC, etc.)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_ELASTIC      = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_PLASTIC      = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_GEOTECHNICAL = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_HYPERELASTIC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_VISCOELASTIC = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_CREEP        = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_DAMAGE       = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_COMPOSITE    = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_THERMAL      = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_ACOUSTIC     = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAMILY_USER         = 11_i4

  ! Total number of families
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_NUM_FAMILIES = 11_i4

  !-----------------------------------------------------------------------------
  ! Level 2: Sub-types (Material variants within each family)
  ! Corresponds to ABAQUS TYPE= parameter
  ! Note: Sub-type IDs align with MD_Mat_Ids.f90 for compatibility
  !-----------------------------------------------------------------------------

  ! Family 01: Elastic sub-types (101~110)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ISO        = 101_i4  ! TYPE=ISOTROPIC
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ORTHO      = 102_i4  ! TYPE=ORTHOTROPIC
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_TRANSISO   = 103_i4  ! TYPE=TRAVERSE
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ANISO      = 104_i4  ! TYPE=ANISOTROPIC
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_POROUS     = 105_i4  ! TYPE=POROUS
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_HYPO       = 106_i4  ! TYPE=HYPOELASTIC
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_SHEAR      = 107_i4  ! TYPE=SHEAR (new)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_ENGINEERING = 108_i4  ! TYPE=ENGINEERING (new)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_THERMO     = 109_i4  ! Thermo-elastic coupling
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ELAS_SUB_PIEZO      = 110_i4  ! Piezo-elastic coupling

  ! Family 02: Plastic sub-types (201~219)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_J2_ISO    = 201_i4  ! J2 isotropic hardening
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_KIN_LIN   = 203_i4  ! Kinematic linear
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_KIN_COMB  = 204_i4  ! Kinematic combined
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_HILL      = 205_i4  ! Hill anisotropic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_JOHNSON_C = 206_i4  ! Johnson-Cook
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_GTN       = 207_i4  ! Gurson-Tvergaard-Needleman
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_ORNL      = 208_i4  ! ORNL constitutive
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_AF        = 209_i4  ! Armstrong-Frederick
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_CHABOCHE  = 210_i4  ! Chaboche
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_BARLAT    = 211_i4  ! Barlat
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_CRYSTAL   = 212_i4  ! Crystal plasticity
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PLAST_SUB_J2_TAB    = 219_i4  ! J2 tabular hardening

  ! Family 03: Geotechnical sub-types (301~308)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_DP_LINEAR   = 301_i4  ! Drucker-Prager linear
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_DP_CAP      = 302_i4  ! Drucker-Prager cap
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_MC          = 303_i4  ! Mohr-Coulomb
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_CC_CRIT     = 304_i4  ! Critical-state
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_CONCRETE    = 305_i4  ! Concrete damage plasticity
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_FOAM_CRUSH  = 306_i4  ! Crushable foam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_CAM_CLAY    = 307_i4  ! Cam-Clay
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_GEO_SUB_HOEK_BROWN  = 308_i4  ! Hoek-Brown

  ! Family 04: Hyperelastic sub-types (401~411)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_NEOHOOKEAN   = 401_i4  ! Neo-Hookean
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_MOONEY2      = 402_i4  ! Mooney-Rivlin 2-param
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_MOONEY5      = 403_i4  ! Mooney-Rivlin 5-param
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_OGDEN2       = 404_i4  ! Ogden 2-term
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_OGDEN3       = 405_i4  ! Ogden 3-term
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_YEOH         = 406_i4  ! Yeoh
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_ARRUDA_BOYCE = 407_i4  ! Arruda-Boyce
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_GENT         = 408_i4  ! Gent
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_HYPERFOAM    = 409_i4  ! Hyperfoam
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_MARLOW       = 410_i4  ! Marlow data-driven
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HE_SUB_VAN_DW       = 411_i4  ! Van der Waals

  ! Family 05: Viscoelastic sub-types (501~504)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VE_SUB_PRONY_DEV    = 501_i4  ! Prony deviatoric
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VE_SUB_PRONY_VOL    = 502_i4  ! Prony volumetric
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VE_SUB_KELVIN       = 503_i4  ! Kelvin-Voigt
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_VE_SUB_WLF_SHIFT    = 504_i4  ! WLF time-temp shift

  ! Family 06: Creep sub-types (601~608)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_POWER     = 601_i4  ! Power-law creep
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_USER      = 602_i4  ! User-defined creep
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_TWO_LAYER = 603_i4  ! Two-layer viscoplastic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_ANNEAL    = 604_i4  ! Annealing creep
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_GAROFALO  = 605_i4  ! Garofalo
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_PERZYNA   = 606_i4  ! Perzyna
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_DUVAUT    = 607_i4  ! Duvaut-Lions
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CREEP_SUB_BODNER    = 608_i4  ! Bodner-Partom

  ! Family 07: Damage sub-types (701~706)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_DUCTILE     = 701_i4  ! Ductile damage
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_SHEAR       = 702_i4  ! Shear damage
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_BRITTLE     = 703_i4  ! Brittle fracture
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_FLD         = 704_i4  ! Forming limit diagram
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_CZM         = 705_i4  ! Cohesive zone model
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DMG_SUB_CONCRETE    = 706_i4  ! Concrete damage (CDP)

  ! Family 08: Composite sub-types (801~805)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_COMP_SUB_CLT        = 801_i4  ! Classical laminate
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_COMP_SUB_HASHIN     = 802_i4  ! Hashin failure
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_COMP_SUB_FABRIC     = 803_i4  ! Woven fabric
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_COMP_SUB_JOINTED    = 804_i4  ! Jointed material
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_COMP_SUB_FOAM_VE    = 805_i4  ! Viscoelastic foam

  ! Family 09: Thermal sub-types (901~903)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HEAT_SUB_ISO        = 901_i4  ! Isotropic conductivity
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HEAT_SUB_ORTHO      = 902_i4  ! Orthotropic conductivity
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_HEAT_SUB_PHASE_CHG  = 903_i4  ! Phase-change

  ! Family 10: Acoustic sub-types (1001~1002)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ACOU_SUB_LINEAR     = 1001_i4 ! Linear acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_ACOU_SUB_ABSORB     = 1002_i4 ! Absorptive acoustic

  ! Family 11: User-Defined sub-types (1101~1102)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_USER_SUB_UMAT       = 1101_i4 ! UMAT (standard)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_USER_SUB_VUMAT      = 1102_i4 ! VUMAT (explicit)

  !-----------------------------------------------------------------------------
  ! Level 3: Property Flags (Bit flags, combinable)
  ! Corresponds to ABAQUS additional parameters (DEPENDENCIES, MODULI, etc.)
  !-----------------------------------------------------------------------------
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_NONE         = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_TEMP_DEP     = 1_i4  ! DEPENDENCIES=1 (temperature)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_FIELD_DEP    = 2_i4  ! DEPENDENCIES=2 (field variable)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_MODULI       = 4_i4  ! MODULI option
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_LONG_TERM    = 8_i4  ! LONG TERM option
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_RATE_DEP     = 16_i4 ! Rate-dependent
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_PROP_PRESSURE_DEP = 32_i4 ! Pressure-dependent

  !-----------------------------------------------------------------------------
  ! Helper functions for three-level nesting
  !-----------------------------------------------------------------------------
  PUBLIC :: MD_Mat_Family_Get_Name
  PUBLIC :: MD_Mat_Family_Validate_Nesting
  PUBLIC :: MD_Mat_Family_Check_Compatibility

CONTAINS

  !-----------------------------------------------------------------------------
  ! MD_Mat_Family_Get_Name
  ! Returns the name of a material family
  !-----------------------------------------------------------------------------
  FUNCTION MD_Mat_Family_Get_Name(family_type) RESULT(name)
    INTEGER(i4), INTENT(IN) :: family_type
    CHARACTER(LEN=32) :: name

    SELECT CASE (family_type)
    CASE (MD_MAT_FAMILY_ELASTIC)
      name = "Elastic"
    CASE (MD_MAT_FAMILY_PLASTIC)
      name = "Plastic"
    CASE (MD_MAT_FAMILY_GEOTECHNICAL)
      name = "Geotechnical"
    CASE (MD_MAT_FAMILY_HYPERELASTIC)
      name = "Hyperelastic"
    CASE (MD_MAT_FAMILY_VISCOELASTIC)
      name = "Viscoelastic"
    CASE (MD_MAT_FAMILY_CREEP)
      name = "Creep"
    CASE (MD_MAT_FAMILY_DAMAGE)
      name = "Damage"
    CASE (MD_MAT_FAMILY_COMPOSITE)
      name = "Composite"
    CASE (MD_MAT_FAMILY_THERMAL)
      name = "Thermal"
    CASE (MD_MAT_FAMILY_ACOUSTIC)
      name = "Acoustic"
    CASE (MD_MAT_FAMILY_USER)
      name = "User-Defined"
    CASE DEFAULT
      name = "Unknown"
    END SELECT
  END FUNCTION MD_Mat_Family_Get_Name

  !-----------------------------------------------------------------------------
  ! MD_Mat_Family_Validate_Nesting
  ! Validates that nesting depth does not exceed 3 levels
  ! Returns .TRUE. if valid, .FALSE. otherwise
  !-----------------------------------------------------------------------------
  FUNCTION MD_Mat_Family_Validate_Nesting(family_type, sub_type, property_flags) RESULT(is_valid)
    INTEGER(i4), INTENT(IN) :: family_type
    INTEGER(i4), INTENT(IN) :: sub_type
    INTEGER(i4), INTENT(IN) :: property_flags
    LOGICAL :: is_valid

    ! Level 1: Family type must be valid (1-11)
    IF (family_type < 1 .OR. family_type > MD_MAT_NUM_FAMILIES) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    ! Level 2: Sub-type must be non-zero
    IF (sub_type <= 0) THEN
      is_valid = .FALSE.
      RETURN
    END IF

    ! Level 3: Property flags are optional (can be 0)
    ! No validation needed for property_flags

    ! All checks passed
    is_valid = .TRUE.
  END FUNCTION MD_Mat_Family_Validate_Nesting

  !-----------------------------------------------------------------------------
  ! MD_Mat_Family_Check_Compatibility
  ! Checks if a sub-type is compatible with a family
  ! Returns .TRUE. if compatible, .FALSE. otherwise
  !-----------------------------------------------------------------------------
  FUNCTION MD_Mat_Family_Check_Compatibility(family_type, sub_type) RESULT(is_compatible)
    INTEGER(i4), INTENT(IN) :: family_type
    INTEGER(i4), INTENT(IN) :: sub_type
    LOGICAL :: is_compatible

    is_compatible = .FALSE.

    SELECT CASE (family_type)
    CASE (MD_MAT_FAMILY_ELASTIC)
      IF (sub_type >= 101 .AND. sub_type <= 110) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_PLASTIC)
      IF (sub_type >= 201 .AND. sub_type <= 219) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_GEOTECHNICAL)
      IF (sub_type >= 301 .AND. sub_type <= 308) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_HYPERELASTIC)
      IF (sub_type >= 401 .AND. sub_type <= 411) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_VISCOELASTIC)
      IF (sub_type >= 501 .AND. sub_type <= 504) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_CREEP)
      IF (sub_type >= 601 .AND. sub_type <= 608) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_DAMAGE)
      IF (sub_type >= 701 .AND. sub_type <= 706) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_COMPOSITE)
      IF (sub_type >= 801 .AND. sub_type <= 805) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_THERMAL)
      IF (sub_type >= 901 .AND. sub_type <= 903) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_ACOUSTIC)
      IF (sub_type >= 1001 .AND. sub_type <= 1002) is_compatible = .TRUE.
    CASE (MD_MAT_FAMILY_USER)
      IF (sub_type >= 1101 .AND. sub_type <= 1102) is_compatible = .TRUE.
    END SELECT
  END FUNCTION MD_Mat_Family_Check_Compatibility

END MODULE MD_Mat_Family_Def
