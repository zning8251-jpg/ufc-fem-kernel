!===============================================================================
! MODULE: MD_Mat_Def
! LAYER:  L3_MD / Material / Contract
! BRIEF:  Canonical material TYPE definitions + legacy MatCtx / UMAT helpers.
!         Restored 2026-04-30 from DomainProcedureRegistry excerpts + Lib extract.
!         W1: nested MD_Mat_Cfg_Init_Desc / MD_Mat_Pop_Vld_Desc under MD_Mat_Desc.
!===============================================================================
MODULE MD_Mat_Def

  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, uf_set_error_status, &
                        MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR, MD_MAT_STATUS_WARN
  USE IF_Prec_Core, ONLY: wp, i4, i8
  USE IF_Base_DP, ONLY: StructFieldDesc, dp_register_struct_type, dp_create_struct_array, &
                        IF_DATA_TYPE_INT, IF_DATA_TYPE_CHAR, IF_DATA_TYPE_DP
  USE MD_Base_ObjModel, ONLY: DescBase, DescBase_Init, DescBase_Destroy, StateBase, StateBase_Init, StateBase_Destroy, &
                              CtxBase, CtxBase_Init, AlgoBase, AlgoBase_Init, &
                              CAT_DESC, CAT_STATE, CAT_CTX, CAT_ALGO, BaseSta, BaseSta_SetStatus, &
                              TreeSerializer, TreeDeserializer
  USE IF_Mem_Mgr, ONLY: UF_Mem_AllocReal1D, UF_Mem_FreeReal1D, IF_MEM_DOMAIN_MAT
  USE MD_Kinematics_Def, ONLY: UF_Kinematics
  USE, INTRINSIC :: IEEE_ARITHMETIC, ONLY: ieee_is_finite

  IMPLICIT NONE
  PRIVATE

  PUBLIC :: MD_MAT_STATUS_OK, MD_MAT_STATUS_INVALID, MD_MAT_STATUS_NOT_FOUND, MD_MAT_STATUS_ERROR, MD_MAT_STATUS_WARN

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MAX_MATERIALS = 1000_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MAX_PROPS = 256_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_DESC_PROPS_MAX = 512_i4

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_UNKNO = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_ELAS = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_PLAST = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_HYP = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_VISC = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_CREEP = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_MODEL_USER = 10_i4

  !-- Material family enum constants (P1 fill 2026-05-05)
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_ELAS   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_PLAST  = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_HYPER  = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_VISC   = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_CREEP  = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_DAMAGE = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_THERM  = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_ACOUS  = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_GEO    = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_COMP   = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_FAM_USER   = 11_i4

  !-- Integration scheme constants for constitutive integration
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_INTEG_BE = 1_i4    ! Backward Euler
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_INTEG_MP = 2_i4    ! Midpoint
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_INTEG_CRANK = 3_i4 ! Crank-Nicolson
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_INTEG_EXPL = 4_i4  ! Forward Euler

  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_GENERAL = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_EL = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_PL = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_DA = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_HY = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_VI = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_CR = 6_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_CO = 7_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_US = 8_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_FOAM = 9_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_GEOMAT = 10_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_COMPOSITE = 11_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_CATEGORY_MULTIPHYS = 12_i4

  INTEGER(i4), PUBLIC, SAVE :: MATERIAL_DESC_I = -1_i4
  INTEGER(i4), PUBLIC, SAVE :: MATERIAL_ST_ID = -1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MAT_G_MATERIAL_ID = 7_i4

  TYPE, PUBLIC :: MD_Mat_Cfg_Init_Desc
    INTEGER(i4)       :: id = 0_i4
    INTEGER(i4)       :: matId = 0_i4
    INTEGER(i4)       :: matModel = 0_i4
    CHARACTER(len=32) :: materialType = ""
    INTEGER(i4)       :: class_id = 0_i4
    CHARACTER(len=32) :: behavior = ""
    CHARACTER(len=64) :: description = ""
  END TYPE MD_Mat_Cfg_Init_Desc

  TYPE, PUBLIC :: MD_Mat_Pop_Vld_Desc
    INTEGER(i4) :: nProps = 0_i4
    INTEGER(i4) :: nStateV = 0_i4
    INTEGER(i4) :: mat_model_id = 0_i4
  END TYPE MD_Mat_Pop_Vld_Desc

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_Mat_Desc
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    TYPE(MD_Mat_Pop_Vld_Desc)  :: pop
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: id = 0_i4
    CHARACTER(len=32) :: materialType = ""
    INTEGER(i4) :: class_id = 0_i4
    INTEGER(i4) :: nProps = 0_i4
    INTEGER(i4) :: nStateV = 0_i4
    CHARACTER(len=32) :: behavior = ""
    CHARACTER(len=64) :: description = ""
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: RegLayout => MD_Mat_Desc_RegLayout
    PROCEDURE, PUBLIC :: Ensure => MD_Mat_Desc_Ensure
    PROCEDURE, PUBLIC :: Init => MD_Mat_Desc_Init_Base
    PROCEDURE, PUBLIC :: Destroy => MD_Mat_Desc_Destroy
    PROCEDURE, PUBLIC :: Valid => MD_Mat_Desc_Valid_Fn
  END TYPE MD_Mat_Desc

  TYPE, PUBLIC, EXTENDS(MD_Mat_Desc) :: DP_MatDesc
    REAL(wp) :: E_young = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
    REAL(wp) :: alpha_friction = 0.0_wp
    REAL(wp) :: k0_cohesion = 0.0_wp
    REAL(wp) :: H_hardening = 0.0_wp
    REAL(wp) :: beta_dilation = 0.0_wp
  END TYPE DP_MatDesc

  TYPE, PUBLIC :: MD_MatModel
    INTEGER(i4) :: id = 0_i4
    CHARACTER(len=64) :: name = ""
    INTEGER(i4) :: modelType = 0_i4
    INTEGER(i4) :: numProperties = 0_i4
    INTEGER(i4) :: nStatev = 0_i4
    REAL(wp), ALLOCATABLE :: properties(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    INTEGER(i4), ALLOCATABLE :: propIds(:)
  END TYPE MD_MatModel

  TYPE, PUBLIC :: Desc_MaterialModel
    INTEGER(i4) :: material_id = 0_i4
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    CHARACTER(len=64) :: name = ""
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: statev(:)
  END TYPE Desc_MaterialModel

  TYPE, PUBLIC :: State_IntPoint
    REAL(wp), ALLOCATABLE :: stress(:)
    TYPE(MD_Mat_Pop_Vld_Desc) :: pop
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
  END TYPE State_IntPoint

  TYPE, PUBLIC :: MatCtxLegacy
    TYPE(UF_Kinematics) :: kin
    TYPE(Desc_MaterialModel) :: desc
    REAL(wp), POINTER :: props(:) => NULL()
    REAL(wp), POINTER :: statev(:) => NULL()
    INTEGER(i4) :: material_id = 0_i4
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    INTEGER(i4) :: props_mem_id = 0_i4
    INTEGER(i4) :: statev_mem_id = 0_i4
    LOGICAL :: props_associate = .FALSE.
    LOGICAL :: statev_associat = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatCtxLegacy_InitLegacy
    PROCEDURE, PUBLIC :: Clean => MatCtxLegacy_Clean
    PROCEDURE, PUBLIC :: SetProps => SetProps
    PROCEDURE, PUBLIC :: SetStateV => SetStateV
    PROCEDURE, PUBLIC :: GetProps => GetProps
    PROCEDURE, PUBLIC :: GetStateV => GetStateV
    PROCEDURE, PUBLIC :: AllocateProps => AllocateProps
    PROCEDURE, PUBLIC :: AllocateStateV => AllocateStateV
    PROCEDURE, PUBLIC :: IsPropsAssociated => IsPropsAssociated
    PROCEDURE, PUBLIC :: IsStateVAssociated => IsStateVAssociated
  END TYPE MatCtxLegacy

  TYPE, PUBLIC :: MatRes
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: tangent(:, :)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    LOGICAL :: failed = .FALSE.
    LOGICAL :: is_plastic = .FALSE.
    LOGICAL :: suggest_cutback = .FALSE.
    REAL(wp) :: pnewdt_factor = 1.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatRes_InitArrays
    PROCEDURE, PUBLIC :: Clean => MatRes_Clean
    PROCEDURE, PUBLIC :: Reset => Reset
  END TYPE MatRes

  TYPE, PUBLIC :: MatFlags
    LOGICAL :: failed = .FALSE.
    LOGICAL :: suggest_cutback = .FALSE.
    LOGICAL :: is_plastic = .FALSE.
    REAL(wp) :: pnewdt_factor = 1.0_wp
  END TYPE MatFlags

  TYPE, PUBLIC :: MatProps
    INTEGER(i4) :: material_id = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4) :: nprops = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatProps_InitArrays
    PROCEDURE, PUBLIC :: Clean => MatProps_Clean
    PROCEDURE, PUBLIC :: SetProp => SetProp
    PROCEDURE, PUBLIC :: GetProp => GetProp
  END TYPE MatProps

  TYPE, PUBLIC :: MD_MAT_UMAT_Intf
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: material_name = ""
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    LOGICAL :: requires_temp = .FALSE.
    LOGICAL :: supports_2d = .TRUE.
    LOGICAL :: supports_3d = .TRUE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Intf_Init0
    PROCEDURE, PUBLIC :: Valid => MD_MAT_UMAT_Intf_Valid0
  END TYPE MD_MAT_UMAT_Intf

  TYPE, PUBLIC :: MD_MAT_UMAT_Input
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: stran(:)
    REAL(wp), ALLOCATABLE :: dstran(:)
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp) :: time(2) = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: dtemp = 0.0_wp
    REAL(wp) :: coords(3) = 0.0_wp
    REAL(wp) :: drot(3, 3) = 0.0_wp
    REAL(wp) :: dfgrd0(3, 3) = 0.0_wp
    REAL(wp) :: dfgrd1(3, 3) = 0.0_wp
    REAL(wp) :: pnewdt = 1.0_wp
    REAL(wp) :: celent = 0.0_wp
    INTEGER(i4) :: noel = 0_i4
    INTEGER(i4) :: npt = 0_i4
    INTEGER(i4) :: layer = 0_i4
    INTEGER(i4) :: kspt = 0_i4
    INTEGER(i4) :: kstep = 0_i4
    INTEGER(i4) :: kinc = 0_i4
    INTEGER(i4) :: ndir = 3_i4
    INTEGER(i4) :: nshr = 3_i4
    INTEGER(i4) :: ntens = 6_i4
    INTEGER(i4) :: nstatv = 0_i4
    INTEGER(i4) :: nprops = 0_i4
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Input_Init0
    PROCEDURE, PUBLIC :: Clean => MD_MAT_UMAT_Input_Clean0
    PROCEDURE, PUBLIC :: FromKinematics => FromKinematics
  END TYPE MD_MAT_UMAT_Input

  TYPE, PUBLIC :: MD_MAT_UMAT_Output
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: ddsdde(:, :)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
    REAL(wp), ALLOCATABLE :: ddsddt(:)
    REAL(wp), ALLOCATABLE :: drplde(:)
    REAL(wp) :: drpldt = 0.0_wp
    REAL(wp) :: pnewdt = 1.0_wp
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MAT_UMAT_Output_Init0
    PROCEDURE, PUBLIC :: Clean => MD_MAT_UMAT_Output_Clean0
    PROCEDURE, PUBLIC :: ToState => ToState
  END TYPE MD_MAT_UMAT_Output

  TYPE, PUBLIC :: MD_MatMeta
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: name = ""
    CHARACTER(len=80) :: description = ""
    INTEGER(i4) :: category = 0_i4
    CHARACTER(len=80) :: category_name = ""
    INTEGER(i4) :: nprops_min = 0_i4
    INTEGER(i4) :: nprops_max = 0_i4
    INTEGER(i4) :: nstatev_min = 0_i4
    INTEGER(i4) :: nstatev_max = 0_i4
    LOGICAL :: available = .FALSE.
    LOGICAL :: requires_temp = .FALSE.
    LOGICAL :: supports_2d = .TRUE.
    LOGICAL :: supports_3d = .TRUE.
    CHARACTER(len=200) :: prop_names = ""
    CHARACTER(len=200) :: statev_names = ""
  CONTAINS
    PROCEDURE, PUBLIC :: ValidateProps => MD_MatMeta_ValidateProps
  END TYPE MD_MatMeta

  TYPE, PUBLIC :: MatReg
    INTEGER(i4) :: nMats = 0_i4
    INTEGER(i4) :: MD_MAT_MAX_MATS = 100_i4
    TYPE(MD_MatMeta), ALLOCATABLE :: materials(:)
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatReg_Init
    PROCEDURE, PUBLIC :: Clean => MatReg_Clean
    PROCEDURE, PUBLIC :: RegisterMaterial => MatReg_RegisterMaterial
    PROCEDURE, PUBLIC :: GetMaterial => MatReg_GetMaterial
    PROCEDURE, PUBLIC :: FindMaterial => MatReg_FindMaterial
    PROCEDURE, PUBLIC :: ListMaterials => MatReg_ListMaterials
    PROCEDURE, PUBLIC :: ValidateProps => MatReg_ValidateProps
    PROCEDURE, PUBLIC :: GetCategoryName => MatReg_GetCategoryName
  END TYPE MatReg

  TYPE, PUBLIC :: MatInst
    INTEGER(i4) :: instance_id = 0_i4
    INTEGER(i4) :: material_id = 0_i4
    CHARACTER(len=80) :: name = ""
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: statev_initial(:)
    LOGICAL :: active = .FALSE.
    TYPE(MD_MatMeta) :: metadata
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatInst_Init
    PROCEDURE, PUBLIC :: Clean => MatInst_Clean
    PROCEDURE, PUBLIC :: SetProps => MatInst_SetProps
    PROCEDURE, PUBLIC :: GetProps => MatInst_GetProps
    PROCEDURE, PUBLIC :: Valid => MatInst_Valid
  END TYPE MatInst

  TYPE, PUBLIC :: MatPoolMgr
    INTEGER(i4) :: num_instances = 0_i4
    INTEGER(i4) :: max_instances = 1000_i4
    TYPE(MatInst), ALLOCATABLE :: instances(:)
    TYPE(MatReg) :: registry
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatPoolMgr_Init
    PROCEDURE, PUBLIC :: Clean => MatPoolMgr_Clean
    PROCEDURE, PUBLIC :: CreateInst => MatPoolMgr_CreateInst
    PROCEDURE, PUBLIC :: GetInst => MatPoolMgr_GetInst
    PROCEDURE, PUBLIC :: RemoveInst => MatPoolMgr_RemoveInst
    PROCEDURE, PUBLIC :: UpdateInst => MatPoolMgr_UpdateInst
    PROCEDURE, PUBLIC :: ListInsts => MatPoolMgr_ListInsts
    PROCEDURE, PUBLIC :: GetReg => MatPoolMgr_GetReg
  END TYPE MatPoolMgr

  TYPE, PUBLIC :: MatOri
    REAL(wp) :: angles(3) = 0.0_wp
    REAL(wp) :: rotationMatrix(3, 3) = 0.0_wp
    LOGICAL :: isSet = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatOri_InitAngles
    PROCEDURE, PUBLIC :: GetRotMat => MatOri_GetRotMat
  END TYPE MatOri

  TYPE, PUBLIC :: MatPropValid
    INTEGER(i4) :: id = 0_i4
    INTEGER(i4) :: numProperties = 0_i4
    REAL(wp), ALLOCATABLE :: minValues(:)
    REAL(wp), ALLOCATABLE :: maxValues(:)
    LOGICAL, ALLOCATABLE :: required(:)
    CHARACTER(len=64), ALLOCATABLE :: propertyNames(:)
    LOGICAL :: isValid = .TRUE.
    CHARACTER(len=256) :: errorMessage = ""
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatPropValid_InitArrays
    PROCEDURE, PUBLIC :: SetPropRange => MatPropValid_SetPropRange
    PROCEDURE, PUBLIC :: Valid => MatPropValid_ValidProps
    PROCEDURE, PUBLIC :: GetErrMsg => MatPropValid_GetErrMsg
  END TYPE MatPropValid

  ! DEPRECATED: Use MD_Mat_Desc (EXTENDS DescBase) instead. No new EXTENDS allowed after 2026-05.
  TYPE, PUBLIC, ABSTRACT :: MD_Mat_Base_Desc
    INTEGER(i4) :: mat_kind = 0_i4
  END TYPE MD_Mat_Base_Desc

  ! DEPRECATED: Use MD_MatAlgo (EXTENDS AlgoBase) instead. No new EXTENDS allowed after 2026-05.
  TYPE, PUBLIC :: MD_Mat_Base_Algo
    INTEGER(i4) :: algo_id = 0_i4
  END TYPE MD_Mat_Base_Algo

  ! DEPRECATED: Use MD_MatState (EXTENDS StateBase) instead. No new EXTENDS allowed after 2026-05.
  TYPE, PUBLIC :: MD_Mat_Base_State
    INTEGER(i4) :: state_id = 0_i4
  END TYPE MD_Mat_Base_State

  TYPE, PUBLIC :: MD_MaterialEntry
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    CHARACTER(LEN=128) :: name = ""
    INTEGER(i4) :: mat_type = 0_i4
    INTEGER(i4) :: n_props = 0_i4
    REAL(wp) :: props(MD_MAT_MAX_PROPS) = 0.0_wp
    LOGICAL :: valid = .FALSE.
  END TYPE MD_MaterialEntry

  TYPE, PUBLIC :: MD_Material_Desc
    INTEGER(i4) :: n_materials = 0_i4
    TYPE(MD_MaterialEntry) :: materials(MD_MAT_MAX_MATERIALS)
  END TYPE MD_Material_Desc

  ! Phase6 1.3 (rollback): increment-level cutback must restore committed MD_MatState
  ! (e.g. %stateV / stress / strain snapshots per Gauss point) before retry; L5 orchestrates,
  ! L4 PH material kernels perform copy-in/copy-out — not implemented in this PR.
  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatState
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    INTEGER(i4) :: nIntPoints = 0_i4
    REAL(wp), ALLOCATABLE :: stress(:)
    REAL(wp), ALLOCATABLE :: strain(:)
    REAL(wp), ALLOCATABLE :: stateV(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MD_MatState_Init_Base
    PROCEDURE, PUBLIC :: Destroy => MD_MatState_Destroy
  END TYPE MD_MatState

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatSta
    INTEGER(i4) :: slot = 0_i4
  END TYPE MD_MatSta

  TYPE, PUBLIC, EXTENDS(CtxBase) :: MD_MatCtx
    INTEGER(i4) :: ctx_id = 0_i4
  END TYPE MD_MatCtx

  TYPE, PUBLIC, EXTENDS(AlgoBase) :: MD_MatAlgo
    INTEGER(i4) :: method = 0_i4
  END TYPE MD_MatAlgo

  TYPE, PUBLIC, EXTENDS(StateBase) :: MD_MatPointSta
    INTEGER(i4) :: point_id = 0_i4
  END TYPE MD_MatPointSta

  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_ElasticMatDesc
  END TYPE MD_ElasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_PlasticMatDesc
  END TYPE MD_PlasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_HyperElasticMatDesc
  END TYPE MD_HyperElasticMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_DamageMatDesc
  END TYPE MD_DamageMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_PronyMatDesc
  END TYPE MD_PronyMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_CompositeMatDesc
  END TYPE MD_CompositeMatDesc
  TYPE, PUBLIC, EXTENDS(DescBase) :: MD_MatModelDesc
  END TYPE MD_MatModelDesc

  TYPE, PUBLIC :: MD_Material_Ctx
    TYPE(MD_Mat_Desc), POINTER :: desc => NULL()
    TYPE(MD_MatSta), POINTER :: mat_sta => NULL()
    TYPE(MD_MatAlgo), POINTER :: algo => NULL()
    TYPE(MatCtxLegacy), POINTER :: ctx => NULL()
    TYPE(MatRes), POINTER :: res => NULL()
    TYPE(UF_Kinematics), POINTER :: kin => NULL()
    TYPE(Desc_MaterialModel), POINTER :: desc_legacy => NULL()
    TYPE(BaseSta) :: sta
    LOGICAL :: ctx_initialized = .FALSE.
    LOGICAL :: success = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatCtx_Init
    PROCEDURE, PUBLIC :: Clean => MatCtx_Clean
    PROCEDURE, PUBLIC :: Reset => MatCtx_Reset
    PROCEDURE, PUBLIC :: GetStatus => MatCtx_GetStat
    PROCEDURE, PUBLIC :: SetStatus => MatCtx_SetStat
    PROCEDURE, PUBLIC :: ClearStatus => MatCtx_ClrStat
    PROCEDURE, PUBLIC :: IsOK => MatCtx_IsOk
    PROCEDURE, PUBLIC :: IsError => MatCtx_IsErr
    PROCEDURE, PUBLIC :: Bind => MatCtx_Bind
    PROCEDURE, PUBLIC :: Valid => MatCtx_Valid
    PROCEDURE, PUBLIC :: GetCtx => MatCtx_GetCtx
    PROCEDURE, PUBLIC :: GetRes => MatCtx_GetRes
    PROCEDURE, PUBLIC :: GetDesc => MatCtx_GetDesc
    PROCEDURE, PUBLIC :: GetSta => MatCtx_GetSta
    PROCEDURE, PUBLIC :: GetAlgo => MatCtx_GetAlgo
  END TYPE MD_Material_Ctx

  TYPE, PUBLIC :: ExpDataPt
    REAL(wp) :: strain = 0.0_wp
    REAL(wp) :: stress = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: weight = 1.0_wp
  END TYPE ExpDataPt

  TYPE, PUBLIC :: ExpDataSet
    INTEGER(i4) :: n_points = 0_i4
    TYPE(ExpDataPt), ALLOCATABLE :: data(:)
    CHARACTER(len=64) :: test_type = ""
  END TYPE ExpDataSet

  TYPE, PUBLIC :: MatParamId
    LOGICAL :: is_initialized = .FALSE.
    TYPE(ExpDataSet) :: exp_data
    REAL(wp), ALLOCATABLE :: param_lower(:)
    REAL(wp), ALLOCATABLE :: param_upper(:)
    REAL(wp), ALLOCATABLE :: param_initial(:)
    REAL(wp), ALLOCATABLE :: param_identifie(:)
    REAL(wp) :: fit_error = 0.0_wp
    INTEGER(i4) :: method = 1_i4
    INTEGER(i4) :: max_iterations = 1000_i4
    REAL(wp) :: tolerance = 1.0e-6_wp
  END TYPE MatParamId

  ! Types/constants already declared TYPE, PUBLIC / PARAMETER, PUBLIC above (gfortran 6 duplicate ACCESS).
  PUBLIC :: MD_Mat_Desc_SyncDeprecatedFlat, MatComp_RotMat
  PUBLIC :: MD_MatState_Snapshot, MD_MatState_RestoreInto

CONTAINS


  !=============================================================================
  ! MatContext Procedures
  !=============================================================================
  subroutine MatCtxLegacy_InitLegacy(this, kin, desc, material_id, nprops, nstatev, status)
    class(MatCtxLegacy),           intent(inout) :: this
    type(UF_Kinematics),     intent(in)    :: kin
    type(Desc_MaterialModel), intent(in)    :: desc
    integer(i4),             intent(in)    :: material_id
    integer(i4),             intent(in)    :: nprops
    integer(i4),             intent(in)    :: nstatev
    type(ErrorStatusType),   intent(out)   :: status

    call init_error_status(status)

    this%kin = kin
    this%desc = desc
    this%material_id = material_id
    this%nprops = nprops
    this%nstatev = nstatev

    if (nprops > 0) then
      allocate(this%props(nprops))
      this%props(:) = 0.0_wp
    end if

    if (nstatev > 0) then
      allocate(this%statev(nstatev))
      this%statev(:) = 0.0_wp
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatCtxLegacy_InitLegacy

  subroutine MatCtxLegacy_Clean(this)
    USE IF_Mem_Mgr, only: mem_disassociate_pointer, mem_free, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    type(ErrorStatusType) :: status

    ! Clean up props memory
    if (this%props_associate .and. associated(this%props)) then
      call mem_disassociate_pointer(g_mem_pool, this%props_mem_id, status)
      nullify(this%props)
      this%props_associate = .false.
      call mem_free(g_mem_pool, this%props_mem_id, status)
      this%props_mem_id = 0_i4
    else if (associated(this%props)) then
      deallocate(this%props)
      nullify(this%props)
    end if

    ! Clean up statev memory
    if (this%statev_associat .and. associated(this%statev)) then
      call mem_disassociate_pointer(g_mem_pool, this%statev_mem_id, status)
      nullify(this%statev)
      this%statev_associat = .false.
      call mem_free(g_mem_pool, this%statev_mem_id, status)
      this%statev_mem_id = 0_i4
    else if (associated(this%statev)) then
      deallocate(this%statev)
      nullify(this%statev)
    end if

    this%material_id = 0_i4
    this%nprops = 0_i4
    this%nstatev = 0_i4
  end subroutine MatCtxLegacy_Clean

  subroutine SetProps(this, props)
    class(MatCtxLegacy), intent(inout) :: this
    real(wp),      intent(in)    :: props(:)

    integer(i4) :: n

    if (.not. associated(this%props)) return

    n = min(size(props), this%nprops)
    if (n > 0) then
      this%props(1:n) = props(1:n)
    end if
  end subroutine SetProps

  subroutine SetStateV(this, statev)
    class(MatCtxLegacy), intent(inout) :: this
    real(wp),      intent(in)    :: statev(:)

    integer(i4) :: n

    if (.not. associated(this%statev)) return

    n = min(size(statev), this%nstatev)
    if (n > 0) then
      this%statev(1:n) = statev(1:n)
    end if
  end subroutine SetStateV

  subroutine GetProps(this, props)
    class(MatCtxLegacy), intent(in) :: this
    real(wp),      intent(out) :: props(:)

    integer(i4) :: n

    if (.not. associated(this%props)) then
      props(:) = 0.0_wp
      return
    end if

    n = min(size(props), this%nprops)
    if (n > 0) then
      props(1:n) = this%props(1:n)
    end if
    if (n < size(props)) then
      props(n+1:) = 0.0_wp
    end if
  end subroutine GetProps

  subroutine GetStateV(this, statev)
    class(MatCtxLegacy), intent(in) :: this
    real(wp),      intent(out) :: statev(:)

    integer(i4) :: n

    if (.not. associated(this%statev)) then
      statev(:) = 0.0_wp
      return
    end if

    n = min(size(statev), this%nstatev)
    if (n > 0) then
      statev(1:n) = this%statev(1:n)
    end if
    if (n < size(statev)) then
      statev(n+1:) = 0.0_wp
    end if
  end subroutine GetStateV

  subroutine AllocateProps(this, nprops, status)
    USE IF_Mem_Mgr, only: mem_alloc_pointer, mem_associate_pointer, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: dims(1)

    call init_error_status(status)

    if (nprops <= 0) then
      status%status_code = -1
      status%message = "Invalid number of properties"
      return
    end if

    if (this%props_associate) then
      call this%Clean()
    end if

    this%nprops = nprops
    dims(1) = nprops

    call mem_alloc_pointer(g_mem_pool, 1, 1, dims, 0, 1, &
                          "MatProps_" // trim(this%desc%name), &
                          this%props_mem_id, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call mem_associate_pointer(g_mem_pool, this%props_mem_id, &
                              ptr_real=this%props, status=status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    this%props_associate = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine AllocateProps

  subroutine AllocateStateV(this, nstatev, status)
    USE IF_Mem_Mgr, only: mem_alloc_pointer, mem_associate_pointer, g_mem_pool
    class(MatCtxLegacy), intent(inout) :: this
    integer(i4),            intent(in)    :: nstatev
    type(ErrorStatusType),  intent(out)   :: status

    integer(i4) :: dims(1)

    call init_error_status(status)

    if (nstatev <= 0) then
      status%status_code = -1
      status%message = "Invalid number of state variables"
      return
    end if

    if (this%statev_associat) then
      call MatCtxLegacy_Clean(this)
    end if

    this%nstatev = nstatev
    dims(1) = nstatev

    call mem_alloc_pointer(g_mem_pool, 1, 1, dims, 0, 1, &
                          "MatStateV_" // trim(this%desc%name), &
                          this%statev_mem_id, status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    call mem_associate_pointer(g_mem_pool, this%statev_mem_id, &
                              ptr_real=this%statev, status=status)
    if (status%status_code /= MD_MAT_STATUS_OK) return

    this%statev_associat = .true.
    status%status_code = MD_MAT_STATUS_OK
  end subroutine AllocateStateV

  function IsPropsAssociated(this) result(is_associated)
    class(MatCtxLegacy), intent(in) :: this
    logical :: is_associated
    is_associated = this%props_associate .and. associated(this%props)
  end function IsPropsAssociated

  function IsStateVAssociated(this) result(is_associated)
    class(MatCtxLegacy), intent(in) :: this
    logical :: is_associated
    is_associated = this%statev_associat .and. associated(this%statev)
  end function IsStateVAssociated

  !=============================================================================
  ! MatResult Procedures
  !=============================================================================
  subroutine MatRes_InitArrays(this, ntens, nstatev, status)
    class(MatRes),          intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatev
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    if (.not. allocated(this%stress)) then
      allocate(this%stress(ntens))
    end if

    if (.not. allocated(this%tangent)) then
      allocate(this%tangent(ntens, ntens))
    end if

    if (nstatev > 0 .and. .not. allocated(this%statev)) then
      allocate(this%statev(nstatev))
    end if

    call this%Reset()
    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatRes_InitArrays

  subroutine MatRes_Clean(this)
    class(MatRes), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%tangent)) deallocate(this%tangent)
    if (allocated(this%statev)) deallocate(this%statev)
  end subroutine MatRes_Clean

  subroutine Reset(this)
    class(MatRes), intent(inout) :: this
    if (allocated(this%stress)) this%stress(:) = 0.0_wp
    if (allocated(this%tangent)) this%tangent(:,:) = 0.0_wp
    if (allocated(this%statev)) this%statev(:) = 0.0_wp
    this%sse = 0.0_wp
    this%spd = 0.0_wp
    this%scd = 0.0_wp
    this%rpl = 0.0_wp
    this%failed = .false.
    this%is_plastic = .false.
    this%suggest_cutback = .false.
    this%pnewdt_factor = 1.0_wp
  end subroutine Reset

  !=============================================================================
  ! MatProperties Procedures
  !=============================================================================
  subroutine MatProps_InitArrays(this, material_id, nprops, status)
    class(MatProps),        intent(inout) :: this
    integer(i4),            intent(in)    :: material_id
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    this%material_id = material_id
    this%nprops = nprops

    if (nprops > 0) then
      allocate(this%props(nprops))
      this%props(:) = 0.0_wp
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MatProps_InitArrays

  subroutine MatProps_Clean(this)
    class(MatProps), intent(inout) :: this
    if (allocated(this%props)) deallocate(this%props)
    this%material_id = 0_i4
    this%nprops = 0_i4
  end subroutine MatProps_Clean

  subroutine SetProp(this, idx, value)
    class(MatProps), intent(inout) :: this
    integer(i4),     intent(in)    :: idx
    real(wp),        intent(in)    :: value
    if (idx >= 1 .and. idx <= this%nprops) then
      this%props(idx) = value
    end if
  end subroutine SetProp

  subroutine GetProp(this, idx, value)
    class(MatProps), intent(in)  :: this
    integer(i4),     intent(in)  :: idx
    real(wp),        intent(out) :: value
    value = 0.0_wp
    if (idx >= 1 .and. idx <= this%nprops) then
      value = this%props(idx)
    end if
  end subroutine GetProp

  !=============================================================================
  ! MD_MAT_UMAT_Intf Procedures
  !=============================================================================
  subroutine MD_MAT_UMAT_Intf_Init0(this, material_id, material_name, nprops, nstatev, &
                                  requires_temp, supports_2d, supports_3d, status)
    class(MD_MAT_UMAT_Intf), intent(inout) :: this
    integer(i4),            intent(in)    :: material_id
    character(len=*),       intent(in)    :: material_name
    integer(i4),            intent(in)    :: nprops
    integer(i4),            intent(in)    :: nstatev
    logical,                intent(in)    :: requires_temp
    logical,                intent(in)    :: supports_2d
    logical,                intent(in)    :: supports_3d
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    this%material_id = material_id
    this%material_name = trim(material_name)
    this%nprops = nprops
    this%nstatev = nstatev
    this%requires_temp = requires_temp
    this%supports_2d = supports_2d
    this%supports_3d = supports_3d

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Intf_Init0

  subroutine MD_MAT_UMAT_Intf_Valid0(this, status)
    class(MD_MAT_UMAT_Intf), intent(in)  :: this
    type(ErrorStatusType),  intent(out) :: status

    call init_error_status(status)

    if (this%material_id <= 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid Mat ID"
      return
    end if

    if (this%nprops < 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid number of props"
      return
    end if

    if (this%nstatev < 0) then
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = "Invalid number of state variables"
      return
    end if

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Intf_Valid0

  !=============================================================================
  ! MD_MAT_UMAT_Input Procedures
  !=============================================================================
  subroutine MD_MAT_UMAT_Input_Init0(this, ntens, nstatv, nprops, status)
    class(MD_MAT_UMAT_Input),      intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatv
    integer(i4),            intent(in)    :: nprops
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    allocate(this%stress(ntens))
    allocate(this%statev(nstatv))
    allocate(this%stran(ntens))
    allocate(this%dstran(ntens))
    allocate(this%props(nprops))

    this%stress(:) = 0.0_wp
    this%statev(:) = 0.0_wp
    this%stran(:) = 0.0_wp
    this%dstran(:) = 0.0_wp
    this%props(:) = 0.0_wp
    this%time(:) = 0.0_wp
    this%dtime = 0.0_wp
    this%temp = 0.0_wp
    this%dtemp = 0.0_wp
    this%coords(:) = 0.0_wp
    this%drot(:,:) = 0.0_wp
    this%dfgrd0(:,:) = 0.0_wp
    this%dfgrd1(:,:) = 0.0_wp
    this%pnewdt = 1.0_wp
    this%celent = 0.0_wp
    this%noel = 0_i4
    this%npt = 0_i4
    this%layer = 0_i4
    this%kspt = 0_i4
    this%kstep = 0_i4
    this%kinc = 0_i4
    this%ndir = 3_i4
    this%nshr = 3_i4
    this%ntens = ntens
    this%nstatv = nstatv
    this%nprops = nprops

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Input_Init0

  subroutine MD_MAT_UMAT_Input_Clean0(this)
    class(MD_MAT_UMAT_Input), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%statev)) deallocate(this%statev)
    if (allocated(this%stran)) deallocate(this%stran)
    if (allocated(this%dstran)) deallocate(this%dstran)
    if (allocated(this%props)) deallocate(this%props)
  end subroutine MD_MAT_UMAT_Input_Clean0

  subroutine FromKinematics(this, kin)
    class(MD_MAT_UMAT_Input), intent(inout) :: this
    type(UF_Kinematics), intent(in) :: kin

    integer(i4) :: ntens

    ntens = this%ntens
    this%stran(1:ntens) = kin%mech%strain(1:ntens)
    this%dstran(1:ntens) = kin%mech%dStrain(1:ntens)
    this%time(1) = kin%time%current
    this%time(2) = kin%time%total
    this%dtime = kin%time%inc
    this%temp = kin%temp%current
    this%dtemp = kin%temp%inc
    this%noel = kin%id
    this%npt = kin%ipID
  end subroutine FromKinematics

  !=============================================================================
  ! MD_MAT_UMAT_Output Procedures
  !=============================================================================
  subroutine MD_MAT_UMAT_Output_Init0(this, ntens, nstatv, status)
    class(MD_MAT_UMAT_Output),     intent(inout) :: this
    integer(i4),            intent(in)    :: ntens
    integer(i4),            intent(in)    :: nstatv
    type(ErrorStatusType),  intent(out)   :: status

    call init_error_status(status)

    allocate(this%stress(ntens))
    allocate(this%statev(nstatv))
    allocate(this%ddsdde(ntens, ntens))
    allocate(this%ddsddt(ntens))
    allocate(this%drplde(ntens))

    this%stress(:) = 0.0_wp
    this%statev(:) = 0.0_wp
    this%ddsdde(:,:) = 0.0_wp
    this%ddsddt(:) = 0.0_wp
    this%drplde(:) = 0.0_wp
    this%sse = 0.0_wp
    this%spd = 0.0_wp
    this%scd = 0.0_wp
    this%rpl = 0.0_wp
    this%drpldt = 0.0_wp
    this%pnewdt = 1.0_wp

    status%status_code = MD_MAT_STATUS_OK
  end subroutine MD_MAT_UMAT_Output_Init0

  subroutine MD_MAT_UMAT_Output_Clean0(this)
    class(MD_MAT_UMAT_Output), intent(inout) :: this
    if (allocated(this%stress)) deallocate(this%stress)
    if (allocated(this%statev)) deallocate(this%statev)
    if (allocated(this%ddsdde)) deallocate(this%ddsdde)
    if (allocated(this%ddsddt)) deallocate(this%ddsddt)
    if (allocated(this%drplde)) deallocate(this%drplde)
  end subroutine MD_MAT_UMAT_Output_Clean0

  subroutine ToState(this, state)
    class(MD_MAT_UMAT_Output), intent(in) :: this
    type(State_IntPoint), intent(inout) :: state

    integer(i4) :: ntens, nstatev

    ntens = size(this%stress)
    nstatev = size(this%statev)

    state%stress(1:ntens) = this%stress(1:ntens)
    state%pop%nStateV = nstatev
    state%statev(1:nstatev) = this%statev(1:nstatev)
    state%sse = this%sse
    state%spd = this%spd
    state%scd = this%scd
    state%rpl = this%rpl
  end subroutine ToState

  !=============================================================================
  ! PROCEDURES FROM MD_Material_Ctx
  !=============================================================================

  subroutine MatCtx_Init(this)
    class(MD_Material_Ctx), intent(inout) :: this
    type(ErrorStatusType) :: status
    call init_error_status(status)
    call this%sta%SetStatus(status)
    this%ctx_initialized = .true.
  end subroutine MatCtx_Init

  subroutine MatCtx_Clean(this)
    class(MD_Material_Ctx), intent(inout) :: this
    nullify(this%desc)
    ! sta is value TYPE(BaseSta); do not nullify
    nullify(this%algo)
    nullify(this%ctx)
    nullify(this%res)
    nullify(this%kin)
    nullify(this%desc_legacy)
    this%success = .false.
    this%ctx_initialized = .false.
  end subroutine MatCtx_Clean

  subroutine MatCtx_Reset(this)
    class(MD_Material_Ctx), intent(inout) :: this
    this%success = .false.
    call this%sta%ClearStatus()
  end subroutine MatCtx_Reset

  function MatCtx_GetStat(this) result(status)
    class(MD_Material_Ctx), intent(in) :: this
    type(ErrorStatusType) :: status
    if (.not. this%ctx_initialized) then
      call init_error_status(status)
      status%status_code = MD_MAT_STATUS_INVALID
      status%message = 'MD_Material_Ctx not initialized'
    else
      status = this%sta%GetStatus()
    end if
  end function MatCtx_GetStat

  subroutine MatCtx_SetStat(this, status)
    class(MD_Material_Ctx), intent(inout) :: this
    type(ErrorStatusType), intent(in) :: status
    call this%sta%SetStatus(status)
  end subroutine MatCtx_SetStat

  subroutine MatCtx_ClrStat(this)
    class(MD_Material_Ctx), intent(inout) :: this
    call this%sta%ClearStatus()
  end subroutine MatCtx_ClrStat

  function MatCtx_IsOk(this) result(is_ok)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_ok
    is_ok = this%sta%IsOK()
  end function MatCtx_IsOk

  function MatCtx_IsErr(this) result(is_error)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_error
    is_error = this%sta%IsError()
  end function MatCtx_IsErr

  subroutine MatCtx_Bind(this, desc, sta, algo, ctx, res, kin, desc_legacy)
    class(MD_Material_Ctx), intent(inout) :: this
    type(MD_Mat_Desc), target, intent(in), optional :: desc
    type(MD_MatSta), target, intent(in), optional :: sta
    type(MD_MatAlgo), target, intent(in), optional :: algo
    type(MatCtxLegacy), target, intent(in), optional :: ctx
    type(MatRes), target, intent(in), optional :: res
    type(UF_Kinematics), target, intent(in), optional :: kin
    type(Desc_MaterialModel), target, intent(in), optional :: desc_legacy

    if (present(desc)) this%desc => desc
    if (present(sta)) this%mat_sta => sta
    if (present(algo)) this%algo => algo
    if (present(ctx)) this%ctx => ctx
    if (present(res)) this%res => res
    if (present(kin)) this%kin => kin
    if (present(desc_legacy)) this%desc_legacy => desc_legacy

    call this%Init()
  end subroutine MatCtx_Bind

  function MatCtx_Valid(this) result(is_valid)
    class(MD_Material_Ctx), intent(in) :: this
    logical :: is_valid

    is_valid = .true.

    if (.not. this%ctx_initialized) then
      is_valid = .false.
      return
    end if

    if (.not. associated(this%ctx) .and. .not. associated(this%desc)) then
      is_valid = .false.
      return
    end if
  end function MatCtx_Valid

  function MatCtx_GetCtx(this) result(ctx)
    class(MD_Material_Ctx), intent(in) :: this
    type(MatCtxLegacy), pointer :: ctx
    ctx => this%ctx
  end function MatCtx_GetCtx

  function MatCtx_GetRes(this) result(res)
    class(MD_Material_Ctx), intent(in) :: this
    type(MatRes), pointer :: res
    res => this%res
  end function MatCtx_GetRes

  function MatCtx_GetDesc(this) result(desc)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_Mat_Desc), pointer :: desc
    desc => this%desc
  end function MatCtx_GetDesc

  function MatCtx_GetSta(this) result(sta)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_MatSta), pointer :: sta
    sta => this%mat_sta
  end function MatCtx_GetSta

  function MatCtx_GetAlgo(this) result(algo)
    class(MD_Material_Ctx), intent(in) :: this
    type(MD_MatAlgo), pointer :: algo
    algo => this%algo
  end function MatCtx_GetAlgo


  SUBROUTINE MD_Mat_Desc_SyncDeprecatedFlat(this)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
    ! Flat mirrors for legacy readers: nested cfg/pop are canonical (W1).
    IF (this%cfg%matId /= 0_i4) THEN
      this%id = this%cfg%matId
    ELSE
      this%id = this%cfg%id
    END IF
    this%materialType = this%cfg%materialType
    this%class_id = this%cfg%class_id
    IF (this%cfg%matModel /= 0_i4 .AND. this%pop%mat_model_id == 0_i4) THEN
      this%pop%mat_model_id = this%cfg%matModel
    END IF
    this%nProps = this%pop%nProps
    this%nStateV = this%pop%nStateV
    this%behavior = this%cfg%behavior
    this%description = this%cfg%description
  END SUBROUTINE MD_Mat_Desc_SyncDeprecatedFlat

  SUBROUTINE MD_Mat_Desc_Init_Base(this)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
    CALL DescBase_Init(this)
    this%algo_type_name = "DESC::Mat"
  END SUBROUTINE MD_Mat_Desc_Init_Base

  SUBROUTINE MD_Mat_Desc_Init(this, id, name, materialType, class_id, nProps, nStateV, behavior, description)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: id, class_id, nProps, nStateV
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: name, materialType, behavior, description
    CALL MD_Mat_Desc_Init_Base(this)
    IF (PRESENT(id)) THEN
      this%cfg%id = id
      IF (this%cfg%matId == 0_i4) this%cfg%matId = id
    END IF
    IF (PRESENT(name)) this%name = name
    IF (PRESENT(materialType)) this%cfg%materialType = materialType
    IF (PRESENT(class_id)) this%cfg%class_id = class_id
    IF (PRESENT(nProps)) THEN
      this%pop%nProps = nProps
      IF (nProps > 0_i4 .AND. .NOT. ALLOCATED(this%props)) THEN
        ALLOCATE(this%props(nProps))
        this%props = 0.0_wp
      END IF
    END IF
    IF (PRESENT(nStateV)) this%pop%nStateV = nStateV
    IF (PRESENT(behavior)) this%cfg%behavior = behavior
    IF (PRESENT(description)) this%cfg%description = description
    CALL MD_Mat_Desc_SyncDeprecatedFlat(this)
    this%is_initialized = .TRUE.
  END SUBROUTINE MD_Mat_Desc_Init

  SUBROUTINE MD_Mat_Desc_Destroy(this)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    CALL DescBase_Destroy(this)
  END SUBROUTINE MD_Mat_Desc_Destroy

  SUBROUTINE MD_Mat_Desc_RegLayout(this)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
  END SUBROUTINE MD_Mat_Desc_RegLayout

  SUBROUTINE MD_Mat_Desc_Ensure(this)
    CLASS(MD_Mat_Desc), INTENT(INOUT) :: this
  END SUBROUTINE MD_Mat_Desc_Ensure

  FUNCTION MD_Mat_Desc_Valid_Fn(this) RESULT(ok)
    CLASS(MD_Mat_Desc), INTENT(IN) :: this
    LOGICAL :: ok
    ok = (this%cfg%id >= 0_i4)
  END FUNCTION MD_Mat_Desc_Valid_Fn

  SUBROUTINE MD_MatState_Init_Base(this, n)
    CLASS(MD_MatState), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN), OPTIONAL :: n
    CALL StateBase_Init(this, n)
    this%algo_type_name = "STATE::Mat"
  END SUBROUTINE MD_MatState_Init_Base

  SUBROUTINE MD_MatState_Destroy(this)
    CLASS(MD_MatState), INTENT(INOUT) :: this
    IF (ALLOCATED(this%stress)) DEALLOCATE(this%stress)
    IF (ALLOCATED(this%strain)) DEALLOCATE(this%strain)
    IF (ALLOCATED(this%stateV)) DEALLOCATE(this%stateV)
    CALL StateBase_Destroy(this)
  END SUBROUTINE MD_MatState_Destroy

  !> Snapshot stress/strain/stateV for Phase6 cut-back rollback (L5 calls before risky increment).
  SUBROUTINE MD_MatState_Snapshot(from_obj, snap, status)
    CLASS(MD_MatState), INTENT(IN) :: from_obj
    TYPE(MD_MatState), INTENT(INOUT) :: snap
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (ALLOCATED(snap%stress)) DEALLOCATE(snap%stress)
    IF (ALLOCATED(snap%strain)) DEALLOCATE(snap%strain)
    IF (ALLOCATED(snap%stateV)) DEALLOCATE(snap%stateV)

    snap%nIntPoints = from_obj%nIntPoints
    snap%cfg = from_obj%cfg

    IF (ALLOCATED(from_obj%stress)) THEN
      ALLOCATE(snap%stress(SIZE(from_obj%stress)))
      snap%stress(:) = from_obj%stress(:)
    END IF
    IF (ALLOCATED(from_obj%strain)) THEN
      ALLOCATE(snap%strain(SIZE(from_obj%strain)))
      snap%strain(:) = from_obj%strain(:)
    END IF
    IF (ALLOCATED(from_obj%stateV)) THEN
      ALLOCATE(snap%stateV(SIZE(from_obj%stateV)))
      snap%stateV(:) = from_obj%stateV(:)
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatState_Snapshot

  !> Restore snapshot produced by MD_MatState_Snapshot.
  SUBROUTINE MD_MatState_RestoreInto(to_obj, snap, status)
    CLASS(MD_MatState), INTENT(INOUT) :: to_obj
    TYPE(MD_MatState), INTENT(IN) :: snap
    TYPE(ErrorStatusType), INTENT(OUT) :: status

    CALL init_error_status(status)
    IF (ALLOCATED(to_obj%stress)) DEALLOCATE(to_obj%stress)
    IF (ALLOCATED(to_obj%strain)) DEALLOCATE(to_obj%strain)
    IF (ALLOCATED(to_obj%stateV)) DEALLOCATE(to_obj%stateV)

    to_obj%nIntPoints = snap%nIntPoints
    to_obj%cfg = snap%cfg

    IF (ALLOCATED(snap%stress)) THEN
      ALLOCATE(to_obj%stress(SIZE(snap%stress)))
      to_obj%stress(:) = snap%stress(:)
    END IF
    IF (ALLOCATED(snap%strain)) THEN
      ALLOCATE(to_obj%strain(SIZE(snap%strain)))
      to_obj%strain(:) = snap%strain(:)
    END IF
    IF (ALLOCATED(snap%stateV)) THEN
      ALLOCATE(to_obj%stateV(SIZE(snap%stateV)))
      to_obj%stateV(:) = snap%stateV(:)
    END IF
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatState_RestoreInto

  SUBROUTINE MD_MatMeta_ValidateProps(this, nprops, nstatev, status)
    CLASS(MD_MatMeta), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: nprops, nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MD_MatMeta_ValidateProps

  SUBROUTINE MatReg_Init(this, MD_MAT_MAX_MATS, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: MD_MAT_MAX_MATS
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%MD_MAT_MAX_MATS = MD_MAT_MAX_MATS
    IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
    ALLOCATE(this%materials(MD_MAT_MAX_MATS))
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_Init

  SUBROUTINE MatReg_Clean(this)
    CLASS(MatReg), INTENT(INOUT) :: this
    IF (ALLOCATED(this%materials)) DEALLOCATE(this%materials)
    this%nMats = 0_i4
    this%is_initialized = .FALSE.
  END SUBROUTINE MatReg_Clean

  SUBROUTINE MatReg_RegisterMaterial(this, material_id, name, description, category, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id, category
    CHARACTER(len=*), INTENT(IN) :: name, description
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_RegisterMaterial

  SUBROUTINE MatReg_GetMaterial(this, material_id, metadata, status)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: material_id
    TYPE(MD_MatMeta), INTENT(OUT) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatReg_GetMaterial

  SUBROUTINE MatReg_FindMaterial(this, name, material_id, status)
    CLASS(MatReg), INTENT(IN) :: this
    CHARACTER(len=*), INTENT(IN) :: name
    INTEGER(i4), INTENT(OUT) :: material_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    material_id = 0_i4
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatReg_FindMaterial

  SUBROUTINE MatReg_ListMaterials(this, material_ids, material_names, nFound, status)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(OUT) :: material_ids(:)
    CHARACTER(len=*), INTENT(OUT) :: material_names(:)
    INTEGER(i4), INTENT(OUT) :: nFound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    nFound = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_ListMaterials

  SUBROUTINE MatReg_ValidateProps(this, material_id, nprops, nstatev, status)
    CLASS(MatReg), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id, nprops, nstatev
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatReg_ValidateProps

  FUNCTION MatReg_GetCategoryName(this, category) RESULT(name)
    CLASS(MatReg), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: category
    CHARACTER(len=80) :: name
    WRITE (name, '("CAT",I0)') category
  END FUNCTION MatReg_GetCategoryName

  SUBROUTINE MatInst_Init(this, instance_id, material_id, name, metadata, nprops, nstatev, status)
    CLASS(MatInst), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id, material_id, nprops, nstatev
    CHARACTER(len=*), INTENT(IN) :: name
    TYPE(MD_MatMeta), INTENT(IN) :: metadata
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%instance_id = instance_id
    this%material_id = material_id
    this%name = name
    this%metadata = metadata
    this%nprops = nprops
    this%nstatev = nstatev
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_Init

  SUBROUTINE MatInst_Clean(this)
    CLASS(MatInst), INTENT(INOUT) :: this
    IF (ALLOCATED(this%props)) DEALLOCATE(this%props)
    IF (ALLOCATED(this%statev_initial)) DEALLOCATE(this%statev_initial)
  END SUBROUTINE MatInst_Clean

  SUBROUTINE MatInst_SetProps(this, props, status)
    CLASS(MatInst), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_SetProps

  SUBROUTINE MatInst_GetProps(this, props, status)
    CLASS(MatInst), INTENT(IN) :: this
    REAL(wp), INTENT(OUT) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    props = 0.0_wp
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_GetProps

  SUBROUTINE MatInst_Valid(this, status)
    CLASS(MatInst), INTENT(IN) :: this
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatInst_Valid

  SUBROUTINE MatPoolMgr_Init(this, max_instances, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: max_instances
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%max_instances = max_instances
    IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
    ALLOCATE(this%instances(max_instances))
    this%is_initialized = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_Init

  SUBROUTINE MatPoolMgr_Clean(this)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    IF (ALLOCATED(this%instances)) DEALLOCATE(this%instances)
    this%is_initialized = .FALSE.
  END SUBROUTINE MatPoolMgr_Clean

  SUBROUTINE MatPoolMgr_CreateInst(this, material_id, name, props, instance_id, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: material_id
    CHARACTER(len=*), INTENT(IN) :: name
    REAL(wp), INTENT(IN) :: props(:)
    INTEGER(i4), INTENT(OUT) :: instance_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    instance_id = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_CreateInst

  SUBROUTINE MatPoolMgr_GetInst(this, instance_id, instance, status)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    TYPE(MatInst), INTENT(OUT) :: instance
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_NOT_FOUND
  END SUBROUTINE MatPoolMgr_GetInst

  SUBROUTINE MatPoolMgr_RemoveInst(this, instance_id, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_RemoveInst

  SUBROUTINE MatPoolMgr_UpdateInst(this, instance_id, props, status)
    CLASS(MatPoolMgr), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: instance_id
    REAL(wp), INTENT(IN) :: props(:)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_UpdateInst

  SUBROUTINE MatPoolMgr_ListInsts(this, instance_ids, material_ids, names, nFound, status)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    INTEGER(i4), INTENT(OUT) :: instance_ids(:), material_ids(:)
    CHARACTER(len=*), INTENT(OUT) :: names(:)
    INTEGER(i4), INTENT(OUT) :: nFound
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    nFound = 0_i4
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPoolMgr_ListInsts

  FUNCTION MatPoolMgr_GetReg(this) RESULT(registry)
    CLASS(MatPoolMgr), INTENT(IN) :: this
    TYPE(MatReg) :: registry
    registry = this%registry
  END FUNCTION MatPoolMgr_GetReg

  SUBROUTINE MatComp_RotMat(angles, rotationMatrix)
    REAL(wp), INTENT(IN) :: angles(3)
    REAL(wp), INTENT(OUT) :: rotationMatrix(3, 3)
    REAL(wp) :: c1, s1, c2, s2, c3, s3
    REAL(wp) :: R1(3, 3), R2(3, 3), R3(3, 3)
    c1 = COS(angles(1))
    s1 = SIN(angles(1))
    c2 = COS(angles(2))
    s2 = SIN(angles(2))
    c3 = COS(angles(3))
    s3 = SIN(angles(3))
    R1 = RESHAPE([1.0_wp, 0.0_wp, 0.0_wp, 0.0_wp, c1, s1, 0.0_wp, -s1, c1], [3, 3])
    R2 = RESHAPE([c2, 0.0_wp, -s2, 0.0_wp, 1.0_wp, 0.0_wp, s2, 0.0_wp, c2], [3, 3])
    R3 = RESHAPE([c3, s3, 0.0_wp, -s3, c3, 0.0_wp, 0.0_wp, 0.0_wp, 1.0_wp], [3, 3])
    rotationMatrix = MATMUL(MATMUL(R3, R2), R1)
  END SUBROUTINE MatComp_RotMat

  SUBROUTINE MatOri_InitAngles(this, angles, status)
    CLASS(MatOri), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: angles(3)
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%angles = angles
    CALL MatComp_RotMat(angles, this%rotationMatrix)
    this%isSet = .TRUE.
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatOri_InitAngles

  FUNCTION MatOri_GetRotMat(this) RESULT(rm)
    CLASS(MatOri), INTENT(IN) :: this
    REAL(wp) :: rm(3, 3)
    rm = this%rotationMatrix
  END FUNCTION MatOri_GetRotMat

  SUBROUTINE MatPropValid_InitArrays(this, id, numProperties, status)
    CLASS(MatPropValid), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: id, numProperties
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    CALL init_error_status(status)
    this%id = id
    this%numProperties = numProperties
    ALLOCATE(this%minValues(numProperties))
    ALLOCATE(this%maxValues(numProperties))
    ALLOCATE(this%required(numProperties))
    ALLOCATE(this%propertyNames(numProperties))
    this%minValues = -HUGE(1.0_wp)
    this%maxValues = HUGE(1.0_wp)
    this%required = .FALSE.
    this%propertyNames = ""
    this%isValid = .TRUE.
    this%errorMessage = ""
    status%status_code = MD_MAT_STATUS_OK
  END SUBROUTINE MatPropValid_InitArrays

  SUBROUTINE MatPropValid_SetPropRange(this, propId, minValue, maxValue, required, propName)
    CLASS(MatPropValid), INTENT(INOUT) :: this
    INTEGER(i4), INTENT(IN) :: propId
    REAL(wp), INTENT(IN) :: minValue, maxValue
    LOGICAL, INTENT(IN), OPTIONAL :: required
    CHARACTER(len=*), INTENT(IN), OPTIONAL :: propName
    IF (propId < 1 .OR. propId > this%numProperties) RETURN
    this%minValues(propId) = minValue
    this%maxValues(propId) = maxValue
    IF (PRESENT(required)) this%required(propId) = required
    IF (PRESENT(propName)) this%propertyNames(propId) = TRIM(propName)
  END SUBROUTINE MatPropValid_SetPropRange

  FUNCTION MatPropValid_ValidProps(this, properties) RESULT(isValid)
    CLASS(MatPropValid), INTENT(INOUT) :: this
    REAL(wp), INTENT(IN) :: properties(:)
    LOGICAL :: isValid
    INTEGER(i4) :: i
    isValid = .TRUE.
    this%isValid = .TRUE.
    this%errorMessage = ""
    DO i = 1, MIN(SIZE(properties), this%numProperties)
      IF (this%required(i) .AND. properties(i) == 0.0_wp) THEN
        isValid = .FALSE.
        this%isValid = .FALSE.
        this%errorMessage = "Required property " // TRIM(this%propertyNames(i)) // " is zero"
        RETURN
      END IF
      IF (properties(i) < this%minValues(i) .OR. properties(i) > this%maxValues(i)) THEN
        isValid = .FALSE.
        this%isValid = .FALSE.
        this%errorMessage = "Property " // TRIM(this%propertyNames(i)) // " out of range"
        RETURN
      END IF
    END DO
  END FUNCTION MatPropValid_ValidProps

  FUNCTION MatPropValid_GetErrMsg(this) RESULT(errorMessage)
    CLASS(MatPropValid), INTENT(IN) :: this
    CHARACTER(len=256) :: errorMessage
    errorMessage = TRIM(this%errorMessage)
  END FUNCTION MatPropValid_GetErrMsg

END MODULE MD_Mat_Def
