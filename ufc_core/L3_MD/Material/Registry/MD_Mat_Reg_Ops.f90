!===============================================================================
! MODULE: MD_MatReg_Ops
! LAYER:  L3_MD
! DOMAIN: Material
! ROLE:   Reg
! BRIEF:  Material registry operations -- unified access to all MatLib material
!         models and UMAT dispatcher.  Maps mat_id to UMAT subroutines.
! **W1**：**统一注册/查询** — **mat_id→UMAT·Legacy 分发**；与 **`MD_Mat_Desc`** / **Populate** / **L4 槽 `desc%props`** 分工（热路径见 **MD_MAT_USER_CORE** / **Mat_Lib**）。
!===============================================================================
!   - Use GetMaterialInfo to query Mat properties
! Status:  Phase B | Last verified: 2026-03-11
!===============================================================================

!>>> UFC_L3_QUENCH | Domain:Mat | Role:Other | FuncSet:Query | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
MODULE MD_Mat_Reg_Ops
!>>> UFC_L3_CONTRACT | Material/CONTRACT.md

  USE IF_Err_Brg, only: ErrorStatusType, init_error_status, &
                                  MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR

  ! Elastic: Phase4: Base (registry) + Dispatch (UMAT, cycle break)
  USE IF_Prec_Core, only: wp, i4, i8
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                              IF_DATA_TYPE_INT, IF_DATA_TYPE_DP, IF_DATA_TYPE_CHAR
  USE MD_Base_DataModMgr, ONLY: g_type_reg, FieldMeta, TypeReg_RegisterType, MD_MAT_TYPE_DESC, MD_MAT_TYPE_STATE, g_data_mgr, obj_new, obj_del
  USE MD_Base_ObjModel, only: BaseRegistry
  USE MD_Mat_Def, ONLY: MD_MatMeta, MatReg, MatInst, MatPoolMgr, MD_MAT_CATEGORY_GENERAL, MatOri, MatPropValid, &
       MATERIAL_DESC_I, MATERIAL_ST_ID, MD_MAT_G_MATERIAL_ID, MD_Mat_Desc
  USE MD_Mat_Plast_Reg, ONLY: MD_MAT_SOFTROCK_MAT_ID, MD_MAT_CAMCLAY_MAT_ID
  USE MD_Mat_Plast_JohnsonCook, ONLY: MD_MAT_JOHNSONCOOK_MAT
  ! Hyperfoam/LowDensityFoam/MR/Ogden: from Hyperelastic (if available)
  use MD_MatLibPH_Brg, only: UF_Plastic_UMAT_Wrapper, &
                               UF_Plastic_GetLegacyID, &
                               MD_MAT_UMAT_Plastic_Dispatch => PH_MAT_UMAT_Plastic_Dispatch, &
                               UF_Plastic_Legacy_VonMises, UF_Plastic_Legacy_Hill, &
                               UF_Plastic_Legacy_CamClay, UF_Plastic_Leg_MohrCoulomb, &
                               UF_Plastic_Leg_ConcreteDmg, UF_Plastic_Leg_DruckerPrager, &
                               UF_Plastic_Legacy_SoftRock, UF_Plastic_Legacy_Cap, &
                               UF_Plastic_Leg_CrushableFoam, UF_Plastic_Legacy_CastIron, &
                               UF_Plastic_Leg_JohnsonCook, UF_Plastic_Legacy_Gurson, &
                               UF_Plastic_Legacy_Chaboche, UF_Plastic_Leg_CompProgressive, &
                               UF_Plastic_Legacy_Foam3Stage, UF_Plastic_Leg_Biomaterial, &
                               UF_Plastic_Legacy_Ceramic, UF_Plastic_Leg_ViscoplasticDmgEM, &
                               UF_Plastic_Leg_Nanomaterial, UF_Plastic_Legacy_FGM, &
                               UF_Plastic_Leg_SmartMat, UF_Plastic_Leg_ViscoelasticDmg, &
                               UF_Plastic_Leg_ThermoViscoplastic, UF_Plastic_Leg_MultiscaleDmg, &
                               UF_Plastic_Leg_ThermoElectroMagneto, UF_Plastic_Leg_PuckComp, &
                               UF_Plastic_Leg_Geotechnical, UF_Plastic_Leg_HashinComp
  USE MD_Mat_Lib, only: DmgState, FatigueState, CreepState, PhaseTransformationState, &
                                MD_MAT_UMAT_Damage_CDM, MD_MAT_UMAT_Damage_Lemaitre, MD_MAT_UMAT_Damage_GTN, &
                                MD_MAT_UMAT_Fatigue_Miner, MD_MAT_UMAT_Fatigue_CoffinManson, MD_MAT_UMAT_Fatigue_ParisLaw, &
                                MD_MAT_UMAT_Creep_Norton, MD_MAT_UMAT_Creep_Garofalo, MD_MAT_UMAT_Creep_KachanovRabotnov, &
                                MD_MAT_UMAT_PhaseTransformation_Martensite, MD_MAT_UMAT_PhaseTransformation_Austenite, &
                                MD_MAT_UMAT_Multiscale_Homogenization, MD_MAT_UMAT_Multiscale_RVE, &
                                MD_MAT_UMAT_602, MD_MAT_UMAT_603, UF_Legacy_Special_602

  implicit none

  !=============================================================================
  ! Wrapper Functions for Category Dispatchers
  !=============================================================================
  private :: MD_MAT_UMAT_Damage_Wrapper, MD_MAT_UMAT_Visco_Wrapper

  private

  !=============================================================================
  ! Mat Model Procedure Pointer Type
  !=============================================================================
  abstract interface
    subroutine MD_MAT_UMAT_Procedure(stress, statev, ddsdde, sse, spd, scd, &
                            rpl, ddsddt, drplde, drpldt, &
                            stran, dstran, time, dtime, temp, dtemp, &
                            predef, dpred, ndir, nshr, nstatev, nprops, &
                            props, ndim, kstep, kinc)
      USE IF_Prec_Core, only: wp
      real(wp), intent(inout) :: stress(6)
      real(wp), intent(inout) :: statev(*)
      real(wp), intent(out) :: ddsdde(6,6)
      real(wp), intent(out) :: sse, spd, scd, rpl
      real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt
      real(wp), intent(in) :: stran(6), dstran(6)
      real(wp), intent(in) :: time(2), dtime
      real(wp), intent(in) :: temp, dtemp
      real(wp), intent(in) :: predef(*), dpred(*)
      integer, intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
      real(wp), intent(in) :: props(*)
    end subroutine MD_MAT_UMAT_Procedure
  end interface

  !=============================================================================
  ! Mat Model Registry Entry
  !=============================================================================
  type, public :: MatLibModelEntry
    integer(i4) :: material_id              = 0_i4
    character(len=80) :: name          = ""
    character(len=80) :: category      = ""
    procedure(MD_MAT_UMAT_Procedure), nopass, pointer :: umat_proc => null()
    integer(i4) :: nprops_min          = 0_i4
    integer(i4) :: nprops_max          = 0_i4
    integer(i4) :: nstatev_min         = 0_i4
    integer(i4) :: nstatev_max         = 0_i4
    logical :: available               = .false.
  end type MatLibModelEntry

  !=============================================================================
  ! MatLib Integration Registry (extends BaseRegistry)
  !=============================================================================
  type, public, extends(BaseRegistry) :: MatLibIntegration
    type(MatLibModelEntry), allocatable :: models(:)
  contains
    ! BaseRegistry interface implementation
    procedure :: Init => MatLib_Init
    procedure :: Cleanup => MatLib_Cleanup
    procedure :: Reg => MatLib_Reg
    procedure :: Unregister => MatLib_Unregister
    procedure :: Lookup => MatLib_Lookup
    procedure :: Exists => MatLib_Exists
    procedure :: GetRegisteredCount => MatLib_GetRegisteredCount
    procedure :: ListRegistered => MatLib_ListRegistered
    ! Legacy interface (for backward compatibility)
    procedure :: Destroy => MatLib_Destroy
    procedure :: RegisterModel => MatLib_RegisterModel
    procedure :: GetModel => MatLib_GetModel
    procedure :: MD_MAT_UMAT_Dispatch => MatLib_UMAT_Dispatch
    procedure :: ListModels => MatLib_ListModels
    procedure :: GetModelInfo => MatLib_GetModelInfo
  end type MatLibIntegration

  public :: MatLibIntegration
  public :: MatLibModelEntry
  public :: g_matlib
  public :: SetCurrentMaterialID
  public :: GetCurrentMaterialID
  public :: GetMaterialCategory
  public :: GetMaterialCategoryName
  public :: MD_MatLib_Legacy_Dispatch
  public :: GetMaterialName
  public :: GetMaterialProps
  public :: Reg_Mat_Library
  public :: init_mate, reg_mate_types, prop_mate, st_mate, del_mate
  public :: MatInit_Def
  public :: MatReg, MatInst, MatPoolMgr, MD_MatMeta, MatOri, MatPropValid
  public :: MATERIAL_DESC_I, MATERIAL_ST_ID, MD_MAT_G_MATERIAL_ID
  public :: Set_Domain_Ptr
  public :: MD_MAT_UMAT_101
  public :: MD_MAT_UMAT_102
  public :: MD_MAT_UMAT_103
  public :: MD_MAT_UMAT_601
  public :: MD_MAT_UMAT_602
  public :: MD_MAT_UMAT_603
  ! Re-export dispatchers and constants from MatLib Core modules for convenience
  public :: MD_MAT_UMAT_Elastic_Dispatch, MD_MAT_UMAT_Plastic_Dispatch, MD_MAT_UMAT_Hyperelastic_Dispatch
  public :: MD_MAT_UMAT_Damage_Dispatch, MD_MAT_UMAT_Viscoelastic_Dispatch
  public :: MD_MAT_ELAS_I, MD_MAT_ELAS_O, &
            MD_MAT_ELAS_TRANSV_ISO, MD_MAT_ELAS_A, &
            MD_MAT_ELAS_P
  ! [REMOVED] public :: MD_MAT_PLASTI, MD_MAT_PLAST_CC, MD_MAT_PLAST_DP, MD_MAT_PLAST_MC (aliases removed)
  public :: MD_MAT_HYPER_MR, MD_MAT_HYPER_OGDEN, &
            MD_MAT_HYPER_AB, MD_MAT_HYPER_YEOH, MD_MAT_HYPER_FOAM
  public :: MD_MAT_DMG_DUCT, MD_MAT_DMG_BRIT, &
            MD_MAT_DMG_PROG, MD_MAT_DMG_FATIGUE, MD_MAT_DMG_CREEP, MD_MAT_DMG_THERMAL
  public :: MD_MAT_VISCO, MD_MAT_VISCO_GEN, MD_MAT_VISCO_HY, &
            MD_MAT_VISCO_PA, MD_MAT_VISCO_FR
  ! Advanced models (merged from MD_MatLib_Adv_Core)
  public :: MD_MAT_UMAT_Damage_CDM, MD_MAT_UMAT_Damage_Lemaitre, MD_MAT_UMAT_Damage_GTN, &
            MD_MAT_UMAT_Fatigue_Miner, MD_MAT_UMAT_Fatigue_CoffinManson, MD_MAT_UMAT_Fatigue_ParisLaw, &
            MD_MAT_UMAT_Creep_Norton, MD_MAT_UMAT_Creep_Garofalo, MD_MAT_UMAT_Creep_KachanovRabotnov, &
            MD_MAT_UMAT_PhaseTransformation_Martensite, MD_MAT_UMAT_PhaseTransformation_Austenite, &
            MD_MAT_UMAT_Multiscale_Homogenization, MD_MAT_UMAT_Multiscale_RVE, &
            DmgState, FatigueState, CreepState, PhaseTransformationState
  ! ---- NEW DOMAINS: 74-model extension (2026-03-04) ----
  ! Concrete/Brittle (MD_MAT_UMAT_700~703)
  public :: MD_MAT_UMAT_700, MD_MAT_UMAT_701, MD_MAT_UMAT_702, MD_MAT_UMAT_703
  public :: CDP_Desc, CDP_State, SmearedCrack_Desc
  public :: MD_MAT_UMAT_CDP, MD_MAT_UMAT_DiffuseCrack, MD_MAT_UMAT_BrittleCrack, MD_MAT_UMAT_MohrCoulomb_Conc
  public :: UF_Concrete_RegAllMats
  ! GeoMat (MD_MAT_UMAT_800~806)
  public :: MD_MAT_UMAT_800, MD_MAT_UMAT_801, MD_MAT_UMAT_802, MD_MAT_UMAT_803, MD_MAT_UMAT_804, MD_MAT_UMAT_805, MD_MAT_UMAT_806
  public :: MCC_Desc, MCC_State, JointedRock_Desc
  public :: MD_MAT_UMAT_MC_Geo, MD_MAT_UMAT_ExtDP, MD_MAT_UMAT_CappedDP, MD_MAT_UMAT_CamClay, MD_MAT_UMAT_ModCamClay
  public :: MD_MAT_UMAT_JointedRock, MD_MAT_UMAT_GeoCreep
  public :: UF_GeoMat_RegAllMats
  ! Composite (MD_MAT_UMAT_900~909)
  public :: MD_MAT_UMAT_900, MD_MAT_UMAT_901, MD_MAT_UMAT_902, MD_MAT_UMAT_903, MD_MAT_UMAT_904
  public :: MD_MAT_UMAT_905, MD_MAT_UMAT_906, MD_MAT_UMAT_907, MD_MAT_UMAT_908, MD_MAT_UMAT_909
  public :: Lamina_Desc, CompDmg_State, CZM_Desc
  public :: MD_MAT_UMAT_Lamina, MD_MAT_UMAT_Ortho3D, MD_MAT_UMAT_Aniso21, MD_MAT_UMAT_PQFiber
  public :: MD_MAT_UMAT_Hashin, MD_MAT_UMAT_Puck, MD_MAT_UMAT_LaRC, MD_MAT_UMAT_CZM, MD_MAT_UMAT_ProgDmg, MD_MAT_UMAT_Fabric
  public :: UF_Composite_RegAllMats
  ! MultiPhys (MD_MAT_UMAT_1000~1007)
  public :: MD_MAT_UMAT_1000, MD_MAT_UMAT_1001, MD_MAT_UMAT_1002, MD_MAT_UMAT_1003
  public :: MD_MAT_UMAT_1004, MD_MAT_UMAT_1005, MD_MAT_UMAT_1006, MD_MAT_UMAT_1007
  public :: SMA_Desc, Biot_Desc, HolzapfelOgden_Desc
  public :: MD_MAT_UMAT_ThermoMech, MD_MAT_UMAT_Piezo, MD_MAT_UMAT_DielectElast, MD_MAT_UMAT_SMA, MD_MAT_UMAT_SMP
  public :: MD_MAT_UMAT_MagnetoMech, MD_MAT_UMAT_PoroFluid, MD_MAT_UMAT_BioTissue
  public :: UF_MultiPhys_RegAllMats
  ! Foam/Special (MD_MAT_UMAT_1100~1105)
  public :: MD_MAT_UMAT_1100, MD_MAT_UMAT_1101, MD_MAT_UMAT_1102, MD_MAT_UMAT_1103, MD_MAT_UMAT_1104, MD_MAT_UMAT_1105
  public :: CrushFoam_Desc, RateFoam_Desc, Multiscale_Desc
  public :: MD_MAT_UMAT_CrushFoam, MD_MAT_UMAT_RateFoam, MD_MAT_UMAT_NoTension, MD_MAT_UMAT_NoCompression
  public :: MD_MAT_UMAT_MultiscaleFoam, MD_MAT_UMAT_TempDepFoam
  public :: UF_Foam_RegAllMats
  ! HyperElastic extensions (MD_MAT_UMAT_451~453)
  public :: MD_MAT_UMAT_451, MD_MAT_UMAT_452, MD_MAT_UMAT_453
  public :: Mullins_Desc, Mullins_State, VDW_Ext_Desc, Marlow_Ext_Desc
  public :: MD_MAT_UMAT_Mullins, MD_MAT_UMAT_VDW_Ext, MD_MAT_UMAT_Marlow_Ext
  public :: UF_HyperExt_RegAllMats
  ! Viscosity extensions (MD_MAT_UMAT_506~510)
  public :: MD_MAT_UMAT_506, MD_MAT_UMAT_507, MD_MAT_UMAT_508, MD_MAT_UMAT_509, MD_MAT_UMAT_510
  public :: NLVisc_Desc, Viscoplast_Desc, PolymerCure_Desc
  public :: ViscoplDmg_Desc, RateFoam_Ext_Desc
  public :: MD_MAT_UMAT_NLVisc, MD_MAT_UMAT_Viscoplast, MD_MAT_UMAT_PolymerCure
  public :: MD_MAT_UMAT_ViscoplDmg, MD_MAT_UMAT_RateFoam_Ext
  public :: UF_ViscExt_RegAllMats
  ! User extended interfaces
  public :: MD_MAT_UMAT_ID_UMAT, MD_MAT_UMAT_ID_VUMAT, MD_MAT_UMAT_ID_UHARD, MD_MAT_UMAT_ID_USDFLD, MD_MAT_UMAT_ID_UEXPAN
  public :: UserMat_Registry, UHARD_Desc, USDFLD_Desc, UEXPAN_Desc
  public :: UF_UserMat_Register, UF_UserMat_Exists, UF_UserMat_GetInfo
  public :: UF_UserMat_RegAllInterfaces

  ! [REMOVED] Legacy Mat ID constants MD_MAT_ELAS_ISO/PLASTIC_VON/DAMAGE_ELAS/VISC_MAXWEL/HYP_NEO_HOO/PLASTIC_GUR/DAMAGE_PLAS (migrated to canonical)

  !=============================================================================
  ! Mat Category Constants (from IntegNew)
  !=============================================================================
  integer(i4), parameter, public :: MD_MAT_CATEGORY_EL        = 1_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_PL        = 2_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_DA         = 3_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_HY   = 4_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_VI  = 5_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_CR          = 6_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_CO      = 7_i4
  integer(i4), parameter, public :: MD_MAT_CATEGORY_US          = 99_i4

  !=============================================================================
  ! Global Mat Library Instance
  !=============================================================================
  type(MatLibIntegration), save, public :: g_matlib

  !=============================================================================
  ! Global Domain Container Pointer (Phase A/B transition)
  !=============================================================================
  ! Pointer to the Material domain container for synchronized registration
  TYPE(MD_Mat_Domain), POINTER, SAVE :: global_domain_ptr => NULL()

  !=============================================================================
  ! Mat ID Lookup Cache (for performance optimization)
  !=============================================================================
  integer(i4), parameter :: MD_MAT_MAX_CACHE_SIZE = 256
  type :: MD_MatIDCacheEntry
    integer(i4) :: material_id = 0_i4
    integer(i4) :: index = 0_i4
    logical :: valid = .false.
  end type MD_MatIDCacheEntry

  type(MD_MatIDCacheEntry), save :: material_cache(MD_MAT_MAX_CACHE_SIZE)
  integer(i4), save :: cache_size = 0_i4
  logical, save :: cache_initializ = .false.

  ! Thread-local / Ctx-based current material ID (SetCurrentMaterialID / GetCurrentMaterialID)
  integer(i4), save :: current_mat_id = 0_i4

  contains

  !=============================================================================
  ! Registry/Instance API (merged from MD_MatReg)
  !=============================================================================
  subroutine init_mate(status)
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call reg_mate_types(status)
  end subroutine init_mate

  subroutine reg_mate_types(status)
    type(ErrorStatusType), intent(out) :: status
    type(FieldMeta), allocatable :: fields(:)
    integer(i4) :: nFields, alloc_stat

    call init_error_status(status)

    nFields = 6_i4
    allocate(fields(nFields), stat=alloc_stat)
    if (alloc_stat /= 0) then
      status%status_code = -1
      status%message = "Failed to allocate fields for MD_Mat_Desc"
      return
    end if
    fields(1)%field_name = "name"
    fields(1)%data_type = 4_i4
    fields(1)%elem_len = 64_i4
    fields(1)%offset_bytes = 0_i8
    fields(1)%rank = 0_i4
    fields(2)%field_name = "type"
    fields(2)%data_type = 1_i4
    fields(2)%elem_len = 4_i4
    fields(2)%offset_bytes = 64_i8
    fields(2)%rank = 0_i4
    fields(3)%field_name = "young_modulus"
    fields(3)%data_type = 2_i4
    fields(3)%elem_len = 8_i4
    fields(3)%offset_bytes = 72_i8
    fields(3)%rank = 0_i4
    fields(4)%field_name = "poisson_ratio"
    fields(4)%data_type = 2_i4
    fields(4)%elem_len = 8_i4
    fields(4)%offset_bytes = 80_i8
    fields(4)%rank = 0_i4
    fields(5)%field_name = "density"
    fields(5)%data_type = 2_i4
    fields(5)%elem_len = 8_i4
    fields(5)%offset_bytes = 88_i8
    fields(5)%rank = 0_i4
    fields(6)%field_name = "user_material_id"
    fields(6)%data_type = 1_i4
    fields(6)%elem_len = 4_i4
    fields(6)%offset_bytes = 96_i8
    fields(6)%rank = 0_i4
    call TypeReg_RegisterType(g_type_reg, "MD_Mat_Desc", MD_MAT_TYPE_DESC, MD_MAT_G_MATERIAL_ID, fields, nFields, "Mat descriptor", MATERIAL_DESC_I, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    deallocate(fields)

    nFields = 4_i4
    allocate(fields(nFields), stat=alloc_stat)
    if (alloc_stat /= 0) then
      status%status_code = -2
      status%message = "Failed to allocate fields for MD_MatSta"
      return
    end if
    fields(1)%field_name = "stress_xx"
    fields(1)%data_type = 2_i4
    fields(1)%elem_len = 8_i4
    fields(1)%offset_bytes = 0_i8
    fields(1)%rank = 0_i4
    fields(2)%field_name = "strain_xx"
    fields(2)%data_type = 2_i4
    fields(2)%elem_len = 8_i4
    fields(2)%offset_bytes = 8_i8
    fields(2)%rank = 0_i4
    fields(3)%field_name = "internal_energy"
    fields(3)%data_type = 2_i4
    fields(3)%elem_len = 8_i4
    fields(3)%offset_bytes = 16_i8
    fields(3)%rank = 0_i4
    fields(4)%field_name = "state_counter"
    fields(4)%data_type = 1_i4
    fields(4)%elem_len = 4_i4
    fields(4)%offset_bytes = 24_i8
    fields(4)%rank = 0_i4
    call TypeReg_RegisterType(g_type_reg, "MD_MatSta", MD_MAT_TYPE_STATE, MD_MAT_G_MATERIAL_ID, fields, nFields, "Mat state", MATERIAL_ST_ID, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    deallocate(fields)
  end subroutine reg_mate_types

  subroutine prop_mate(name, id, status)
    character(len=*), intent(in) :: name
    integer(i4), intent(out) :: id
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call obj_new(g_data_mgr, MATERIAL_DESC_I, name, id, status)
  end subroutine prop_mate

  subroutine st_mate(name, id, status)
    character(len=*), intent(in) :: name
    integer(i4), intent(out) :: id
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call obj_new(g_data_mgr, MATERIAL_ST_ID, name, id, status)
  end subroutine st_mate

  subroutine del_mate(id, status)
    integer(i4), intent(in) :: id
    type(ErrorStatusType), intent(out) :: status
    call init_error_status(status)
    call obj_del(g_data_mgr, id, status)
  end subroutine del_mate

  subroutine MatInit_Def(registry, status)
    type(MatReg), intent(inout) :: registry
    type(ErrorStatusType), intent(out) :: status

    call init_error_status(status)

    if (.not. registry%is_initialized) then
      call registry%Init(status=status)
      if (status%status_code /= MD_MAT_STATUS_OK) return
    end if

    call registry%RegisterMaterial( &
      material_id=101_i4, &
      name="Isotropic Linear Elastic", &
      description="Abaqus UMAT 101: Isotropic linear elasticity with thermal expansion", &
      category=MD_MAT_CATEGORY_EL, &
      nprops_min=2_i4, nprops_max=4_i4, &
      nstatev_min=0_i4, nstatev_max=0_i4, &
      requires_temp=.true., &
      supports_2d=.true., supports_3d=.true., &
      prop_names="E, nu, alpha_thermal, k_thermal", &
      status=status)

    if (status%status_code /= MD_MAT_STATUS_OK) return

    call registry%RegisterMaterial( &
      material_id=102_i4, &
      name="Orthotropic Elastic", &
      description="Abaqus UMAT 102: Orthotropic linear elasticity", &
      category=MD_MAT_CATEGORY_EL, &
      nprops_min=9_i4, nprops_max=9_i4, &
      nstatev_min=0_i4, nstatev_max=0_i4, &
      requires_temp=.false., &
      supports_2d=.true., supports_3d=.true., &
      prop_names="E1, E2, E3, nu12, nu13, nu23, G12, G13, G23", &
      status=status)

    if (status%status_code /= MD_MAT_STATUS_OK) return

    call registry%RegisterMaterial( &
      material_id=201_i4, &
      name="Mises Plasticity", &
      description="Abaqus UMAT 201: von Mises plasticity with isotropic hardening", &
      category=MD_MAT_CATEGORY_PL, &
      nprops_min=4_i4, nprops_max=5_i4, &
      nstatev_min=9_i4, nstatev_max=9_i4, &
      requires_temp=.true., &
      supports_2d=.true., supports_3d=.true., &
      prop_names="E, nu, sigma_y0, H, alpha_thermal", &
      statev_names="analysis_type, eps_plastic, plastic_work, strain_plastic(1:6)", &
      status=status)

    if (status%status_code /= MD_MAT_STATUS_OK) return

    call registry%RegisterMaterial( &
      material_id=301_i4, &
      name="Ductile Damage", &
      description="Abaqus UMAT 301: Gurson-Tvergaard-Needleman ductile damage model", &
      category=MD_MAT_CATEGORY_DA, &
      nprops_min=8_i4, nprops_max=10_i4, &
      nstatev_min=12_i4, nstatev_max=15_i4, &
      requires_temp=.false., &
      supports_2d=.true., supports_3d=.true., &
      prop_names="E, nu, sigma_y0, H, q1, q2, q3, fn, eps_n, sn", &
      statev_names="void_volume_fra, eps_plastic, damage, stress_trial", &
      status=status)

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatInit_Def

  !=============================================================================
  ! BaseRegistry Interface Implementation
  !=============================================================================
  subroutine MatLib_Init(this, max_capacity, status)
    class(MatLibIntegration), intent(inout) :: this
    integer(i4), intent(in), optional :: max_capacity
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)

    if (present(max_capacity)) then
      this%max_capacity = max_capacity
    else
      this%max_capacity = 256_i4
    end if

    this%max_models = this%max_capacity
    call this%Init(max_models=this%max_models, status=local_status)

    if (present(status)) status = local_status
  end subroutine MatLib_Init

  subroutine MatLib_Cleanup(this, status)
    class(MatLibIntegration), intent(inout) :: this
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)
    call this%Destroy()

    if (present(status)) status = local_status
  end subroutine MatLib_Cleanup

  subroutine MatLib_Reg(this, name, item, status)
    class(MatLibIntegration), intent(inout) :: this
    character(len=*), intent(in) :: name
    class(*), intent(in), optional :: item  ! MatLibModelEntry or similar
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)
    ! Note: Full implementation would extract material_id and other params from item
    ! For now, this is a placeholder that delegates to RegisterModel

    if (present(status)) status = local_status
  end subroutine MatLib_Reg

  subroutine MatLib_Unregister(this, name, status)
    class(MatLibIntegration), intent(inout) :: this
    character(len=*), intent(in) :: name
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status

    call init_error_status(local_status)
    ! Note: Implementation would find and remove model by name

    if (present(status)) status = local_status
  end subroutine MatLib_Unregister

  function MatLib_Lookup(this, name) result(found)
    class(MatLibIntegration), intent(in) :: this
    character(len=*), intent(in) :: name
    logical :: found

    integer(i4) :: i

    found = .false.
    do i = 1, this%num_models
      if (this%models(i)%available .and. trim(this%models(i)%name) == trim(name)) then
        found = .true.
        return
      end if
    end do
  end function MatLib_Lookup

  function MatLib_Exists(this, name) result(exists)
    class(MatLibIntegration), intent(in) :: this
    character(len=*), intent(in) :: name
    logical :: exists

    exists = this%Lookup(name)
  end function MatLib_Exists

  function MatLib_GetRegisteredCount(this) result(count)
    class(MatLibIntegration), intent(in) :: this
    integer(i4) :: count

    count = this%num_models
    this%registered_count = count
  end function MatLib_GetRegisteredCount

  subroutine MatLib_ListRegistered(this, names, count, status)
    class(MatLibIntegration), intent(in) :: this
    character(len=*), intent(out) :: names(:)
    integer(i4), intent(out) :: count
    type(ErrorStatusType), intent(out), optional :: status

    type(ErrorStatusType) :: local_status
    integer(i4) :: i, n

    call init_error_status(local_status)

    n = min(size(names), this%num_models)
    count = 0_i4

    do i = 1, n
      if (this%models(i)%available) then
        count = count + 1_i4
        names(count) = trim(this%models(i)%name)
      end if
    end do

    if (present(status)) status = local_status
  end subroutine MatLib_ListRegistered

  !=============================================================================
  ! Legacy Interface Implementation
  !=============================================================================
  subroutine MatLib_Init(this, max_models, status)
    class(MatLibIntegration), intent(inout) :: this
    integer(i4),                 intent(in),    optional :: max_models
    type(ErrorStatusType),       intent(out)   :: status

    call init_error_status(status)

    if (this%init) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatLibIntegration already initialized"
      return
    end if

    if (present(max_models)) then
      this%max_models = max_models
    end if

    allocate(this%models(this%max_models))
    this%models(:)%available = .false.
    this%num_models = 0_i4
    this%registered_count = 0_i4
    this%init = .true.

    call RegisterDefaultModels(this, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Init lookup cache
    call InitMaterialCache(this, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatLib_Init

  !=============================================================================
  ! Init Mat ID Lookup Cache
  !=============================================================================
  subroutine InitMaterialCache(this, status)
    class(MatLibIntegration), intent(in) :: this
    type(ErrorStatusType), intent(out) :: status

    integer(i4) :: i, cache_idx

    call init_error_status(status)

    material_cache(:)%valid = .false.
    cache_size = 0_i4

    ! Build cache from registered models
    do i = 1, this%num_models
      if (this%models(i)%available .and. cache_size < MD_MAT_MAX_CACHE_SIZE) then
        cache_idx = cache_size + 1
        material_cache(cache_idx)%material_id = this%models(i)%material_id
        material_cache(cache_idx)%index = i
        material_cache(cache_idx)%valid = .true.
        cache_size = cache_idx
      end if
    end do

    cache_initializ = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine InitMaterialCache

  !=============================================================================
  ! MatLib Destruction
  !=============================================================================
  subroutine MatLib_Destroy(this)
    class(MatLibIntegration), intent(inout) :: this

    if (allocated(this%models)) then
      deallocate(this%models)
    end if

    this%num_models = 0_i4
    this%registered_count = 0_i4
    this%init = .false.
  end subroutine MatLib_Destroy

  !=============================================================================
  ! Reg Mat Model
  !=============================================================================
  subroutine MatLib_RegisterModel(this, material_id, name, category, umat_proc, &
                                nprops_min, nprops_max, nstatev_min, nstatev_max, status)
    class(MatLibIntegration), intent(inout) :: this
    integer(i4),                 intent(in)    :: material_id
    character(len=*),            intent(in)    :: name
    character(len=*),            intent(in)    :: category
    procedure(MD_MAT_UMAT_Procedure)            :: umat_proc
    integer(i4),                 intent(in)    :: nprops_min
    integer(i4),                 intent(in)    :: nprops_max
    integer(i4),                 intent(in)    :: nstatev_min
    integer(i4),                 intent(in)    :: nstatev_max
    type(ErrorStatusType),       intent(out)   :: status

    integer(i4) :: idx
    type(ErrorStatusType) :: domain_status
    type(MD_Mat_Desc) :: mat_desc

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatLibIntegration not initialized"
      return
    end if

    if (this%num_models >= this%max_models) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatLibIntegration full"
      return
    end if

    idx = this%num_models + 1

    this%models(idx)%material_id = material_id
    this%models(idx)%name = trim(name)
    this%models(idx)%category = trim(category)
    this%models(idx)%umat_proc => umat_proc
    this%models(idx)%nprops_min = nprops_min
    this%models(idx)%nprops_max = nprops_max
    this%models(idx)%nstatev_min = nstatev_min
    this%models(idx)%nstatev_max = nstatev_max
    this%models(idx)%available = .true.

    this%num_models = this%num_models + 1_i4
    this%registered_count = this%num_models

    ! Update cache
    if (cache_size < MD_MAT_MAX_CACHE_SIZE) then
      cache_size = cache_size + 1
      material_cache(cache_size)%material_id = material_id
      material_cache(cache_size)%index = idx
      material_cache(cache_size)%valid = .true.
    end if

    ! Phase A: Synchronously register to domain container (if available)
    if (associated(global_domain_ptr)) then
      if (global_domain_ptr%initialized) then
        ! Convert MatLibModelEntry to MD_Mat_Desc (inline conversion)
        call init_error_status(domain_status)
        call mat_desc%Init()
        call init_error_status(domain_status)
        domain_status%status_code = MD_MAT_STATUS_OK
        if (domain_status%status_code == MD_MAT_STATUS_OK) then
          mat_desc%cfg%id = material_id
          mat_desc%cfg%id = material_id
          mat_desc%name = trim(name)
          mat_desc%cfg%materialType = trim(category)
          mat_desc%cfg%materialType = trim(category)
          mat_desc%pop%nProps = nprops
          mat_desc%pop%nProps = nprops_min
          mat_desc%pop%nStateV = nstatev_min
          mat_desc%pop%nStateV = nstatev_min
          mat_desc%cfg%behavior = trim(category)
          mat_desc%cfg%behavior = trim(category)
          mat_desc%cfg%description = "Registered from MatLib: " // trim(name)
          mat_desc%cfg%description = "Registered from MatLib: " // trim(name)
          
          ! Register to domain container
          call global_domain_ptr%Register(mat_desc, material_id, domain_status)
          ! Note: domain_status is not propagated to caller status
          ! Container registration failure does not fail MatLib registration
        end if
      end if
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatLib_RegisterModel

  !=============================================================================
  ! Get Mat Model
  !=============================================================================
  subroutine MatLib_GetModel(this, material_id, model, status)
    class(MatLibIntegration), intent(in)    :: this
    integer(i4),                 intent(in)    :: material_id
    type(MatLibModelEntry),       intent(out)   :: model
    type(ErrorStatusType),       intent(out)   :: status

    integer(i4) :: i, cache_idx

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatLibIntegration not initialized"
      return
    end if

    ! Try cache first (optimized lookup)
    if (cache_initializ) then
      do cache_idx = 1, cache_size
        if (material_cache(cache_idx)%valid .and. &
            material_cache(cache_idx)%material_id == material_id) then
          i = material_cache(cache_idx)%index
          if (i > 0 .and. i <= this%num_models .and. &
              this%models(i)%available .and. &
              this%models(i)%material_id == material_id) then
            model = this%models(i)
            status%status_code = MD_MAT_STATUS_OK
            return
          end if
        end if
      end do
    end if

    ! Fallback to linear search
    do i = 1, this%num_models
      if (this%models(i)%material_id == material_id .and. this%models(i)%available) then
        model = this%models(i)
        ! Update cache
        if (cache_size < MD_MAT_MAX_CACHE_SIZE) then
          cache_size = cache_size + 1
          material_cache(cache_size)%material_id = material_id
          material_cache(cache_size)%index = i
          material_cache(cache_size)%valid = .true.
        end if
        status%status_code = MD_MAT_STATUS_OK
        return
      end if
    end do

    status%status_code = MD_MAT_STATUS_NOT_FOUND
    status%message = "Mat ID not found in MatLib"
  end subroutine MatLib_GetModel

  !=============================================================================
  ! UMAT Dispatcher
  !=============================================================================
  subroutine MatLib_UMAT_Dispatch(this, material_id, stress, statev, ddsdde, sse, spd, scd, &
                                  rpl, ddsddt, drplde, drpldt, &
                                  stran, dstran, time, dtime, temp, dtemp, &
                                  predef, dpred, ndir, nshr, nstatev, nprops, &
                                  props, ndim, kstep, kinc, status)
    class(MatLibIntegration), intent(in)    :: this
    integer(i4),                 intent(in)    :: material_id
    real(wp),                   intent(inout) :: stress(6)
    real(wp),                   intent(inout) :: statev(*)
    real(wp),                   intent(out)   :: ddsdde(6,6)
    real(wp),                   intent(out)   :: sse, spd, scd, rpl
    real(wp),                   intent(out)   :: ddsddt(6), drplde(6), drpldt
    real(wp),                   intent(in)    :: stran(6), dstran(6)
    real(wp),                   intent(in)    :: time(2), dtime
    real(wp),                   intent(in)    :: temp, dtemp
    real(wp),                   intent(in)    :: predef(*), dpred(*)
    integer,                    intent(in)    :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp),                   intent(in)    :: props(*)
    type(ErrorStatusType),       intent(out)   :: status

    type(MatLibModelEntry) :: model

    call init_error_status(status)

    call this%GetModel(material_id, model, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    if (.not. associated(model%umat_proc)) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "UMAT procedure not associated"
      return
    end if

    call model%umat_proc(stress, statev, ddsdde, sse, spd, scd, &
                        rpl, ddsddt, drplde, drpldt, &
                        stran, dstran, time, dtime, temp, dtemp, &
                        predef, dpred, ndir, nshr, nstatev, nprops, &
                        props, ndim, kstep, kinc)

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatLib_UMAT_Dispatch

  !=============================================================================
  ! List Mat Models
  !=============================================================================
  subroutine MatLib_ListModels(this, material_ids, material_names, categories, nFound, status)
    class(MatLibIntegration), intent(in)    :: this
    integer(i4),                 intent(out)   :: material_ids(:)
    character(len=*),            intent(out)   :: material_names(:)
    character(len=*),            intent(out)   :: categories(:)
    integer(i4),                 intent(out)   :: nFound
    type(ErrorStatusType),       intent(out)   :: status

    integer(i4) :: i, max_output

    call init_error_status(status)

    if (.not. this%init) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "MatLibIntegration not initialized"
      nFound = 0_i4
      return
    end if

    max_output = min(size(material_ids), size(material_names), size(categories))
    nFound = 0_i4

    do i = 1, this%num_models
      if (this%models(i)%available) then
        nFound = nFound + 1_i4
        if (nFound <= max_output) then
          material_ids(nFound) = this%models(i)%material_id
          material_names(nFound) = trim(this%models(i)%name)
          categories(nFound) = trim(this%models(i)%category)
        end if
      end if
    end do

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatLib_ListModels

  !=============================================================================
  ! Get Model Information
  !=============================================================================
  subroutine MatLib_GetModelInfo(this, material_id, name, category, nprops_min, &
                                 nprops_max, nstatev_min, nstatev_max, status)
    class(MatLibIntegration), intent(in)    :: this
    integer(i4),                 intent(in)    :: material_id
    character(len=*),            intent(out)   :: name
    character(len=*),            intent(out)   :: category
    integer(i4),                 intent(out)   :: nprops_min
    integer(i4),                 intent(out)   :: nprops_max
    integer(i4),                 intent(out)   :: nstatev_min
    integer(i4),                 intent(out)   :: nstatev_max
    type(ErrorStatusType),       intent(out)   :: status

    type(MatLibModelEntry) :: model

    call this%GetModel(material_id, model, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    name = trim(model%name)
    category = trim(model%category)
    nprops_min = model%nprops_min
    nprops_max = model%nprops_max
    nstatev_min = model%nstatev_min
    nstatev_max = model%nstatev_max
  end subroutine MatLib_GetModelInfo

  !=============================================================================
  ! Reg Default Models
  !=============================================================================
  subroutine RegisterDefaultModels(this, status)
    class(MatLibIntegration), intent(inout) :: this
    type(ErrorStatusType),       intent(out)   :: status

    call init_error_status(status)

    ! Elastic Models - canonical IDs only (literal-ID duplicates removed; 121/122/131 in Hyperelastic)
    call this%RegisterModel(MD_MAT_ELAS_I, "Isotropic Linear Elastic", "Elastic", &
                            UF_Elastic_Legacy_Isotropic, 2_i4, 4_i4, 0_i4, 0_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_ELAS_O, "Orthotropic Linear Elastic", "Elastic", &
                            UF_Elastic_Legacy_Orthotropic, 9_i4, 9_i4, 0_i4, 0_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_ELAS_TRANSV_ISO, "Transversely Isotropic Elastic", "Elastic", &
                            UF_Elastic_Legacy_TransverseIso, 5_i4, 7_i4, 0_i4, 0_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_ELAS_A, "Fully Anisotropic Elastic", "Elastic", &
                            UF_Elastic_Legacy_Anisotropic, 21_i4, 21_i4, 0_i4, 0_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_ELAS_P, "Porous Elastic", "Elastic", &
                            UF_Elastic_Legacy_Porous, 4_i4, 5_i4, 5_i4, 5_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    ! 121(Hyperfoam/MD_MAT_HYPER_FOAM), 122(LowDensityFoam), 131(Hypoelastic) registered in Hyperelastic section
    ! 141(MD_MAT_HYPER_MR), 142(MD_MAT_HYPER_OGDEN) registered in Hyperelastic section below

    ! Plastic Models - canonical IDs only (201_i4/203_i4/204_i4 duplicates removed)
    ! MT-0.4: Hill plasticity id is **205** (**MD_MAT_HILL_MAT_ID**); DP remains registry **202**.
    call this%RegisterModel(MD_MAT_VONMISES_MAT_ID, "von Mises Plasticity", "Plastic", &
                            UF_Plastic_Legacy_VonMises, 4_i4, 5_i4, 8_i4, 8_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(202_i4, "Drucker-Prager Plasticity", "Plastic", &
                            UF_Plastic_Leg_DruckerPrager, 5_i4, 7_i4, 8_i4, 8_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_CAMCLAY_MAT_ID, "Cam-Clay Plasticity", "Plastic", &
                            UF_Plastic_Legacy_CamClay, 6_i4, 8_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(204_i4, "Mohr-Coulomb Plasticity", "Plastic", &
                            UF_Plastic_Leg_MohrCoulomb, 5_i4, 12_i4, 13_i4, 13_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(212_i4, "Drucker-Prager Plasticity (Legacy)", "Plastic", &
                            UF_Plastic_Leg_DruckerPrager, 5_i4, 7_i4, 8_i4, 8_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_SOFTROCK_MAT_ID, "Soft Rock (Legacy)", "Plastic", &
                            UF_Plastic_Legacy_SoftRock, 6_i4, 12_i4, 12_i4, 12_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Damage Models - CDP via Registration
    call this%RegisterModel(MD_MAT_CDP, "Concrete Damage Plasticity", "Damage", &
                            UF_Plastic_Leg_ConcreteDmg, 8_i4, 9_i4, 10_i4, 10_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(205_i4, "Concrete Damage Plasticity (Legacy)", "Damage", &
                            UF_Plastic_Leg_ConcreteDmg, 6_i4, 7_i4, 12_i4, 12_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Plastic / Foam
    call this%RegisterModel(221_i4, "Cap Plasticity", "Plastic", &
                            UF_Plastic_Legacy_Cap, 8_i4, 11_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(222_i4, "Crushable Foam Plasticity", "Plastic", &
                            UF_Plastic_Leg_CrushableFoam, 6_i4, 8_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(223_i4, "Cast Iron Plasticity", "Plastic", &
                            UF_Plastic_Legacy_CastIron, 6_i4, 9_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Johnson-Cook via Registration
    call this%RegisterModel(MD_MAT_JOHNSONCOOK_MAT, "Johnson-Cook Plasticity", "Plastic", &
                            UF_Plastic_Leg_JohnsonCook, 10_i4, 10_i4, 10_i4, 10_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(231_i4, "Johnson-Cook Plasticity (Legacy)", "Plastic", &
                            UF_Plastic_Leg_JohnsonCook, 5_i4, 8_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Damage Models - Use unified dispatcher
    call this%RegisterModel(MD_MAT_DMG_DUCT, "Ductile Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 10_i4, 13_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(MD_MAT_DMG_BRIT, "Johnson-Cook Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 7_i4, 9_i4, 5_i4, 5_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(MD_MAT_DMG_PROG, "Hashin Composite Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 24_i4, 30_i4, 19_i4, 19_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(MD_MAT_DMG_FATIGUE, "Puck Composite Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 15_i4, 30_i4, 28_i4, 28_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(MD_MAT_DMG_CREEP, "Creep Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 10_i4, 13_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(MD_MAT_DMG_THERMAL, "Thermal Damage", "Damage", &
                            MD_MAT_UMAT_Damage_Wrapper, 14_i4, 14_i4, 24_i4, 24_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Legacy Damage IDs - only unique IDs kept (301/305/311/312/341/351 removed as dups of MD_MAT_DMG_*)
    call this%RegisterModel(321_i4, "Mullins Effect (Legacy)", "Damage", &
                            UF_Damage_Legacy_Mullins, 6_i4, 6_i4, 4_i4, 4_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(331_i4, "Traction-Separation Damage (Legacy)", "Damage", &
                            UF_Dmg_Leg_TractionSeparation, 5_i4, 5_i4, 3_i4, 3_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Hyperelastic Models - canonical IDs (121/141/142/401/402 literals removed as dups of MD_MAT_HYPER_*)
    call this%RegisterModel(MD_MAT_HYPER_MR, "Mooney-Rivlin Hyperelastic", "Hyperelastic", &
                            UF_Hyper_Legacy_MooneyRivlin, 2_i4, 5_i4, 6_i4, 6_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_HYPER_OGDEN, "Ogden Hyperelastic", "Hyperelastic", &
                            UF_Hyper_Legacy_Ogden, 6_i4, 9_i4, 6_i4, 6_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_HYPER_AB, "Arruda-Boyce Hyperelastic", "Hyperelastic", &
                            UF_Hyper_Legacy_ArrudaBoyce, 2_i4, 3_i4, 6_i4, 6_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_HYPER_YEOH, "Yeoh Hyperelastic", "Hyperelastic", &
                            UF_Hyper_Legacy_Yeoh, 1_i4, 4_i4, 6_i4, 6_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_HYPER_FOAM, "Hyperfoam", "Hyperelastic", &
                            UF_Hyper_Legacy_Hyperfoam, 4_i4, 10_i4, 4_i4, 4_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(122_i4, "Low Density Foam (Legacy)", "Foam", &
                            UF_Hyper_Leg_LowDensityFoam, 6_i4, 9_i4, 4_i4, 4_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(131_i4, "Hypoelastic (Legacy)", "Elastic", &
                            UF_Elastic_Leg_Hypoelastic, 4_i4, 5_i4, 7_i4, 7_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Thermal Models
    call this%RegisterModel(405_i4, "Thermoelastic", "Thermal", &
                            UF_Comp_Leg_Thermoelastic, 3_i4, 6_i4, 8_i4, 8_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(406_i4, "Thermoelastoplastic", "Thermal", &
                            MD_MAT_UMAT_406, 8_i4, 9_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Viscoelastic Models
    call this%RegisterModel(501_i4, "Prony Viscoelastic", "Viscoelastic", &
                            UF_Viscoelastic_Legacy_Prony, 2_i4, 20_i4, 6_i4, 30_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(502_i4, "Porous Medium", "Porous", &
                            MD_MAT_UMAT_502, 7_i4, 11_i4, 9_i4, 9_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(503_i4, "Gasket Mat", "Special", &
                            MD_MAT_UMAT_503, 11_i4, 12_i4, 19_i4, 19_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(504_i4, "Piezoelectric Mat", "Special", &
                            MD_MAT_UMAT_504, 11_i4, 12_i4, 4_i4, 4_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Creep Models (601: legacy wrapper for Reg's MD_MAT_UMAT_Procedure interface)
    call this%RegisterModel(601_i4, "Power Law Creep", "Creep", &
                            UF_Creep_Legacy_PowerLaw, 5_i4, 7_i4, 10_i4, 10_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(602_i4, "Nanomaterial", "Special", &
                            UF_Legacy_Special_602, 7_i4, 8_i4, 3_i4, 3_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call this%RegisterModel(603_i4, "Gradient Mat", "Special", &
                            MD_MAT_UMAT_603, 15_i4, 16_i4, 12_i4, 12_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    ! Advanced Mat Models (241-265) via Registration
    call this%RegisterModel(241_i4, "Joint Mat", "Special", &
                            UF_Plastic_Legacy_Gurson, 5_i4, 8_i4, 5_i4, 5_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(242_i4, "Porous Media", "Special", &
                            UF_Plastic_Legacy_Chaboche, 8_i4, 12_i4, 10_i4, 10_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(251_i4, "Composite Materials", "Advanced", &
                            UF_Plastic_Leg_CompProgressive, 35_i4, 42_i4, 30_i4, 30_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(MD_MAT_FOAM3_STAGE_MAT_ID, "Foam Materials", "Advanced", &
                            UF_Plastic_Legacy_Foam3Stage, 24_i4, 30_i4, 20_i4, 20_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(253_i4, "Biomaterials", "Advanced", &
                            UF_Plastic_Leg_Biomaterial, 25_i4, 32_i4, 25_i4, 25_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(254_i4, "Ceramic Materials", "Advanced", &
                            UF_Plastic_Legacy_Ceramic, 22_i4, 28_i4, 22_i4, 22_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(255_i4, "Viscoplastic Damage Electromagnetic", "Advanced", &
                            UF_Plastic_Leg_ViscoplasticDmgEM, 19_i4, 25_i4, 24_i4, 24_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(256_i4, "Nanomaterials", "Advanced", &
                            UF_Plastic_Leg_Nanomaterial, 22_i4, 28_i4, 18_i4, 18_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(257_i4, "Gradient Materials", "Advanced", &
                            UF_Plastic_Legacy_FGM, 26_i4, 32_i4, 25_i4, 25_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(258_i4, "Smart Materials", "Advanced", &
                            UF_Plastic_Leg_SmartMat, 22_i4, 28_i4, 29_i4, 29_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(259_i4, "Viscoelastic Damage", "Advanced", &
                            UF_Plastic_Leg_ViscoelasticDmg, 12_i4, 18_i4, 17_i4, 17_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(260_i4, "Thermoviscoplastic", "Advanced", &
                            UF_Plastic_Leg_ThermoViscoplastic, 9_i4, 15_i4, 15_i4, 15_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(261_i4, "Multiscale Materials", "Advanced", &
                            UF_Plastic_Leg_MultiscaleDmg, 36_i4, 42_i4, 27_i4, 27_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(262_i4, "Thermo-Electro-Magneto-Mechanical", "Advanced", &
                            UF_Plastic_Leg_ThermoElectroMagneto, 15_i4, 25_i4, 25_i4, 25_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(263_i4, "Puck Composite Damage", "Advanced", &
                            UF_Plastic_Leg_PuckComp, 15_i4, 30_i4, 28_i4, 28_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(264_i4, "Geomaterials", "Advanced", &
                            UF_Plastic_Leg_Geotechnical, 12_i4, 18_i4, 16_i4, 16_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return
    call this%RegisterModel(265_i4, "Hashin Composite Damage", "Advanced", &
                            UF_Plastic_Leg_HashinComp, 24_i4, 30_i4, 19_i4, 19_i4, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    status%status_code = MD_MAT_STATUS_OK
  end subroutine RegisterDefaultModels

  !=============================================================================
  ! Wrapper Functions
  !=============================================================================

  !=============================================================================
  ! Category Dispatcher Wrappers
  !=============================================================================

  !=============================================================================
  ! Helper: Find Mat ID from Wrapper Function Pointer
  ! Uses procedure pointer comparison to find which Mat uses this wrapper
  !=============================================================================

  subroutine SetCurrentMaterialID(material_id)
    !! Set current Mat ID (for thread-local or Ctx-based lookup)
    integer(i4), intent(in) :: material_id
    current_mat_id = material_id
  end subroutine SetCurrentMaterialID

  function GetCurrentMaterialID() result(material_id)
    !! Get current Mat ID
    integer(i4) :: material_id
    material_id = current_mat_id
  end function GetCurrentMaterialID

  function FindMaterialIDFromWrapper(wrapper_proc) result(material_id)
    !! Find Mat ID by searching for wrapper procedure pointer in registry
    !! This is called from wrapper functions to determine which Mat they represent
    procedure(MD_MAT_UMAT_Procedure), pointer, intent(in) :: wrapper_proc
    integer(i4) :: material_id

    integer(i4) :: i, cache_idx

    material_id = 0_i4

    ! First check cache (optimized lookup)
    if (cache_initializ .and. g_matlib%initialized) then
      do cache_idx = 1, cache_size
        if (material_cache(cache_idx)%valid) then
          i = material_cache(cache_idx)%index
          if (i > 0 .and. i <= g_matlib%num_models) then
            if (g_matlib%models(i)%available) then
              ! Compare procedure pointers
              if (associated(g_matlib%models(i)%umat_proc, wrapper_proc)) then
                material_id = material_cache(cache_idx)%material_id
                return
              end if
            end if
          end if
        end if
      end do
    end if

    ! Fallback: linear search through registered models
    if (g_matlib%initialized) then
      do i = 1, g_matlib%num_models
        if (g_matlib%models(i)%available) then
          ! Compare procedure pointers
          if (associated(g_matlib%models(i)%umat_proc, wrapper_proc)) then
            material_id = g_matlib%models(i)%material_id
            ! Update cache for future lookups
            if (cache_size < MD_MAT_MAX_CACHE_SIZE) then
              cache_size = cache_size + 1
              material_cache(cache_size)%material_id = material_id
              material_cache(cache_size)%index = i
              material_cache(cache_size)%valid = .true.
            end if
            return
          end if
        end if
      end do
    end if
  end function FindMaterialIDFromWrapper

  subroutine MD_MAT_UMAT_Damage_Wrapper(stress, statev, ddsdde, sse, spd, scd, &
                                 rpl, ddsddt, drplde, drpldt, &
                                 stran, dstran, time, dtime, temp, dtemp, &
                                 predef, dpred, ndir, nshr, nstatev, nprops, &
                                 props, ndim, kstep, kinc)
    !! Wrapper for MD_MAT_UMAT_Damage_Dispatch

    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(*)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt
    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)
    integer, intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(*)

    type(ErrorStatusType) :: status
    integer(i4) :: material_id
    procedure(MD_MAT_UMAT_Procedure), pointer :: wrapper_ptr

    wrapper_ptr => MD_MAT_UMAT_Damage_Wrapper
    material_id = FindMaterialIDFromWrapper(wrapper_ptr)
    if (material_id == 0_i4) material_id = MD_MAT_DMG_DUCT

    call MD_MAT_UMAT_Damage_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &
                             rpl, ddsddt, drplde, drpldt, &
                             stran, dstran, time, dtime, temp, dtemp, &
                             predef, dpred, ndir, nshr, nstatev, nprops, &
                             props, ndim, kstep, kinc, status)

  end subroutine MD_MAT_UMAT_Damage_Wrapper

  subroutine MD_MAT_UMAT_Visco_Wrapper(stress, statev, ddsdde, sse, spd, scd, &
                                rpl, ddsddt, drplde, drpldt, &
                                stran, dstran, time, dtime, temp, dtemp, &
                                predef, dpred, ndir, nshr, nstatev, nprops, &
                                props, ndim, kstep, kinc)
    !! Wrapper for MD_MAT_UMAT_Viscoelastic_Dispatch

    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(*)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt
    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)
    integer, intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(*)

    type(ErrorStatusType) :: status
    integer(i4) :: material_id
    procedure(MD_MAT_UMAT_Procedure), pointer :: wrapper_ptr

    wrapper_ptr => MD_MAT_UMAT_Visco_Wrapper
    material_id = FindMaterialIDFromWrapper(wrapper_ptr)
    if (material_id == 0_i4) material_id = MD_MAT_VISCO

    call MD_MAT_UMAT_Viscoelastic_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &
                                    rpl, ddsddt, drplde, drpldt, &
                                    stran, dstran, time, dtime, temp, dtemp, &
                                    predef, dpred, ndir, nshr, nstatev, nprops, &
                                    props, ndim, kstep, kinc, status)

  end subroutine MD_MAT_UMAT_Visco_Wrapper

  !=============================================================================
  ! Mat Category Functions (from IntegNew)
  !=============================================================================

  function GetMaterialCategory(material_id) result(category)
    !! Get Mat category from Mat ID
    integer(i4), intent(in) :: material_id
    integer(i4) :: category

    if (material_id >= 100 .and. material_id < 200) then
      category = MD_MAT_CATEGORY_EL
    else if (material_id >= 200 .and. material_id < 300) then
      category = MD_MAT_CATEGORY_PL
    else if (material_id >= 300 .and. material_id < 400) then
      category = MD_MAT_CATEGORY_DA
    else if (material_id >= 400 .and. material_id < 500) then
      category = MD_MAT_CATEGORY_HY
    else if (material_id >= 500 .and. material_id < 600) then
      category = MD_MAT_CATEGORY_VI
    else if (material_id >= 600 .and. material_id < 700) then
      category = MD_MAT_CATEGORY_CR
    else if (material_id >= 1000 .and. material_id < 10000) then
      category = MD_MAT_CATEGORY_US
    else
      category = MD_MAT_CATEGORY_EL
    end if
  end function GetMaterialCategory

  function GetMaterialCategoryName(category) result(name)
    !! Get Mat category name from category ID
    integer(i4), intent(in) :: category
    character(len=80) :: name

    select case(category)
      case(MD_MAT_CATEGORY_EL)
        name = "Elastic"
      case(MD_MAT_CATEGORY_PL)
        name = "Plastic"
      case(MD_MAT_CATEGORY_DA)
        name = "Damage"
      case(MD_MAT_CATEGORY_HY)
        name = "Hyperelastic"
      case(MD_MAT_CATEGORY_VI)
        name = "Viscoelastic"
      case(MD_MAT_CATEGORY_CR)
        name = "Creep"
      case(MD_MAT_CATEGORY_CO)
        name = "Composite"
      case(MD_MAT_CATEGORY_US)
        name = "User-Defined"
      case default
        name = "Unknown"
    end select
  end function GetMaterialCategoryName


  !=============================================================================
  ! LEGACY DISPATCHER (for backward compatibility)
  !=============================================================================
  subroutine MD_MatLib_Legacy_Dispatch(material_id, stress, statev, ddsdde, &
                                            sse, spd, scd, rpl, ddsddt, drplde, &
                                            drpldt, stran, dstran, time, dtime, &
                                            temp, dtemp, predef, dpred, ndir, &
                                            nshr, nstatev, nprops, props, ndim, &
                                            kstep, kinc, status)
    !! Unified dispatcher for all legacy Mat models (backward compatibility)
    !! This function delegates to the unified MD_MAT_UMAT_Dispatch

    integer(i4), intent(in) :: material_id
    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(*)
    real(wp), intent(out) :: ddsdde(6,6)
    real(wp), intent(out) :: sse, spd, scd, rpl
    real(wp), intent(out) :: ddsddt(6), drplde(6), drpldt
    real(wp), intent(in) :: stran(6), dstran(6)
    real(wp), intent(in) :: time(2), dtime
    real(wp), intent(in) :: temp, dtemp
    real(wp), intent(in) :: predef(*), dpred(*)
    integer, intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(*)
    type(ErrorStatusType), intent(out) :: status

    ! Delegate to unified MD_MAT_UMAT_Dispatch
    call g_matlib%MD_MAT_UMAT_Dispatch(material_id, stress, statev, ddsdde, sse, spd, scd, &
                                rpl, ddsddt, drplde, drpldt, &
                                stran, dstran, time, dtime, temp, dtemp, &
                                predef, dpred, ndir, nshr, nstatev, nprops, &
                                props, ndim, kstep, kinc, status)

  end subroutine MD_MatLib_Legacy_Dispatch

  !=============================================================================
  ! Mat INFORMATION FUNCTIONS (from Legacy)
  !=============================================================================
function GetMaterialName(matId) result(name)
    integer(i4), intent(in) :: matId
    character(len=64) :: name

    select case (matId)
    case(MD_MAT_ELAS_I)
      name = "Isotropic Linear Elastic"
    case(MD_MAT_VONMISES_MAT_ID)
      name = "Von Mises Plasticity"
    case(MD_MAT_DMG_DUCT)
      name = "Elastic Damage"
    case default
      name = "Unknown Mat"
    end select

  end function GetMaterialName
function GetMaterialProps(matId) result(nprops)
    integer(i4), intent(in) :: matId
    integer(i4) :: nprops

    select case (matId)
    case(MD_MAT_ELAS_I)
      nprops = 2  ! E, nu
    case(MD_MAT_VONMISES_MAT_ID)
      nprops = 4  ! E, nu, sigma_y, H
    case(MD_MAT_DMG_DUCT)
      nprops = 3  ! E, nu, damage_threshol
    case default
      nprops = 0
    end select

  end function GetMaterialProps

  !=============================================================================
  ! LEGACY UMAT INTERFACES (for backward compatibility)
  !=============================================================================
  subroutine MD_MAT_UMAT_101(stress, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc)
    !! Legacy UMAT interface for Isotropic Elastic (backward compatibility)

    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6), sse, spd, scd
    real(wp), intent(out) :: rpl, ddsddt(ndir+nshr), drplde(ndir+nshr), drpldt
    real(wp), intent(in) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    real(wp), intent(in) :: predef(1), dpred(1)
    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    type(ErrorStatusType) :: status

    call MD_MatLib_Legacy_Dispatch(MD_MAT_ELAS_I, stress, statev, ddsdde, &
                                        sse, spd, scd, rpl, ddsddt, drplde, &
                                        drpldt, stran, dstran, time, dtime, &
                                        temp, dtemp, predef, dpred, ndir, &
                                        nshr, nstatev, nprops, props, ndim, &
                                        kstep, kinc, status)
  end subroutine MD_MAT_UMAT_101

  subroutine MD_MAT_UMAT_102(stress, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc)
    !! Legacy UMAT interface for von Mises Plasticity (backward compatibility)

    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6), sse, spd, scd
    real(wp), intent(out) :: rpl, ddsddt(ndir+nshr), drplde(ndir+nshr), drpldt
    real(wp), intent(in) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    real(wp), intent(in) :: predef(1), dpred(1)
    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    type(ErrorStatusType) :: status

    call MD_MatLib_Legacy_Dispatch(MD_MAT_VONMISES_MAT_ID, stress, statev, ddsdde, &
                                        sse, spd, scd, rpl, ddsddt, drplde, &
                                        drpldt, stran, dstran, time, dtime, &
                                        temp, dtemp, predef, dpred, ndir, &
                                        nshr, nstatev, nprops, props, ndim, &
                                        kstep, kinc, status)
  end subroutine MD_MAT_UMAT_102

  subroutine MD_MAT_UMAT_103(stress, statev, ddsdde, sse, spd, scd, &
                      rpl, ddsddt, drplde, drpldt, &
                      stran, dstran, time, dtime, temp, dtemp, &
                      predef, dpred, ndir, nshr, nstatev, nprops, &
                      props, ndim, kstep, kinc)
    !! Legacy UMAT interface for Elastic Damage (backward compatibility)

    real(wp), intent(inout) :: stress(6)
    real(wp), intent(inout) :: statev(nstatev)
    real(wp), intent(out) :: ddsdde(6,6), sse, spd, scd
    real(wp), intent(out) :: rpl, ddsddt(ndir+nshr), drplde(ndir+nshr), drpldt
    real(wp), intent(in) :: stran(6), dstran(6), time(2), dtime, temp, dtemp
    real(wp), intent(in) :: predef(1), dpred(1)
    integer(i4), intent(in) :: ndir, nshr, nstatev, nprops, ndim, kstep, kinc
    real(wp), intent(in) :: props(nprops)
    type(ErrorStatusType) :: status

    call MD_MatLib_Legacy_Dispatch(MD_MAT_DMG_DUCT, stress, statev, ddsdde, &
                                        sse, spd, scd, rpl, ddsddt, drplde, &
                                        drpldt, stran, dstran, time, dtime, &
                                        temp, dtemp, predef, dpred, ndir, &
                                        nshr, nstatev, nprops, props, ndim, &
                                        kstep, kinc, status)
  end subroutine MD_MAT_UMAT_103

  !=============================================================================
  ! Mat REGISTRATION SYSTEM (from Legacy)
  !=============================================================================
  subroutine Reg_Mat_Library()
    !! This subroutine registers all available Mat models
    !! with the Mat system for runtime selection
    !!
    !! This function initializes g_matlib and registers all default models

    type(ErrorStatusType) :: status

    ! Init g_matlib if not already initialized
    if (.not. g_matlib%initialized) then
      call g_matlib%Init(status=status)
      if (status%status_code /= MD_MAT_STATUS_OK) then
        ! Error handling would go here
        return
      end if
    end if

    ! Reg new plastic Mat modules
    call UF_Plastic_RegAllMats(status)
    if (status%status_code /= MD_MAT_STATUS_OK) then
      ! Error handling would go here
      return
    end if

  end subroutine Reg_Mat_Library

  !=============================================================================
  ! Set Domain Pointer (Phase A/B transition)
  !=============================================================================
  subroutine Set_Domain_Ptr(domain_ptr)
    !! Set the global domain container pointer for synchronized registration
    !! This allows MatLib_RegisterModel to automatically register materials
    !! to the domain container when they are registered to g_matlib.
    TYPE(MD_Mat_Domain), POINTER, INTENT(IN) :: domain_ptr

    global_domain_ptr => domain_ptr

  end subroutine Set_Domain_Ptr

end MODULE MD_Mat_Reg_Ops
