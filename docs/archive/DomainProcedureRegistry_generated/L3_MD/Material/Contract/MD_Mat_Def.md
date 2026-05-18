# `MD_Mat_Def.f90`

- **Source**: `L3_MD/Material/Contract/MD_Mat_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Contract/MD_Mat_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Mat_Cfg_Init_Desc` (lines 77–85)

```fortran
  TYPE, PUBLIC :: MD_Mat_Cfg_Init_Desc
    INTEGER(i4)       :: id = 0_i4
    INTEGER(i4)       :: matId = 0_i4
    INTEGER(i4)       :: matModel = 0_i4
    CHARACTER(len=32) :: materialType = ""
    INTEGER(i4)       :: class_id = 0_i4
    CHARACTER(len=32) :: behavior = ""
    CHARACTER(len=64) :: description = ""
  END TYPE MD_Mat_Cfg_Init_Desc
```

### `MD_Mat_Pop_Vld_Desc` (lines 87–91)

```fortran
  TYPE, PUBLIC :: MD_Mat_Pop_Vld_Desc
    INTEGER(i4) :: nProps = 0_i4
    INTEGER(i4) :: nStateV = 0_i4
    INTEGER(i4) :: mat_model_id = 0_i4
  END TYPE MD_Mat_Pop_Vld_Desc
```

### `MD_MatModel` (lines 122–131)

```fortran
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
```

### `Desc_MaterialModel` (lines 133–140)

```fortran
  TYPE, PUBLIC :: Desc_MaterialModel
    INTEGER(i4) :: material_id = 0_i4
    INTEGER(i4) :: nprops = 0_i4
    INTEGER(i4) :: nstatev = 0_i4
    CHARACTER(len=64) :: name = ""
    REAL(wp), ALLOCATABLE :: props(:)
    REAL(wp), ALLOCATABLE :: statev(:)
  END TYPE Desc_MaterialModel
```

### `State_IntPoint` (lines 142–150)

```fortran
  TYPE, PUBLIC :: State_IntPoint
    REAL(wp), ALLOCATABLE :: stress(:)
    TYPE(MD_Mat_Pop_Vld_Desc) :: pop
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp) :: sse = 0.0_wp
    REAL(wp) :: spd = 0.0_wp
    REAL(wp) :: scd = 0.0_wp
    REAL(wp) :: rpl = 0.0_wp
  END TYPE State_IntPoint
```

### `MatCtxLegacy` (lines 152–175)

```fortran
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
```

### `MatRes` (lines 177–193)

```fortran
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
```

### `MatFlags` (lines 195–200)

```fortran
  TYPE, PUBLIC :: MatFlags
    LOGICAL :: failed = .FALSE.
    LOGICAL :: suggest_cutback = .FALSE.
    LOGICAL :: is_plastic = .FALSE.
    REAL(wp) :: pnewdt_factor = 1.0_wp
  END TYPE MatFlags
```

### `MatProps` (lines 202–211)

```fortran
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
```

### `MD_MAT_UMAT_Intf` (lines 213–224)

```fortran
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
```

### `MD_MAT_UMAT_Input` (lines 226–257)

```fortran
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
```

### `MD_MAT_UMAT_Output` (lines 259–275)

```fortran
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
```

### `MD_MatMeta` (lines 277–295)

```fortran
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
```

### `MatReg` (lines 297–311)

```fortran
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
```

### `MatInst` (lines 313–329)

```fortran
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
```

### `MatPoolMgr` (lines 331–346)

```fortran
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
```

### `MatOri` (lines 348–355)

```fortran
  TYPE, PUBLIC :: MatOri
    REAL(wp) :: angles(3) = 0.0_wp
    REAL(wp) :: rotationMatrix(3, 3) = 0.0_wp
    LOGICAL :: isSet = .FALSE.
  CONTAINS
    PROCEDURE, PUBLIC :: Init => MatOri_InitAngles
    PROCEDURE, PUBLIC :: GetRotMat => MatOri_GetRotMat
  END TYPE MatOri
```

### `MatPropValid` (lines 357–371)

```fortran
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
```

### `MD_Mat_Base_Desc` (lines 374–376)

```fortran
  TYPE, PUBLIC, ABSTRACT :: MD_Mat_Base_Desc
    INTEGER(i4) :: mat_kind = 0_i4
  END TYPE MD_Mat_Base_Desc
```

### `MD_Mat_Base_Algo` (lines 379–381)

```fortran
  TYPE, PUBLIC :: MD_Mat_Base_Algo
    INTEGER(i4) :: algo_id = 0_i4
  END TYPE MD_Mat_Base_Algo
```

### `MD_Mat_Base_State` (lines 384–386)

```fortran
  TYPE, PUBLIC :: MD_Mat_Base_State
    INTEGER(i4) :: state_id = 0_i4
  END TYPE MD_Mat_Base_State
```

### `MD_MaterialEntry` (lines 388–395)

```fortran
  TYPE, PUBLIC :: MD_MaterialEntry
    TYPE(MD_Mat_Cfg_Init_Desc) :: cfg
    CHARACTER(LEN=128) :: name = ""
    INTEGER(i4) :: mat_type = 0_i4
    INTEGER(i4) :: n_props = 0_i4
    REAL(wp) :: props(MD_MAT_MAX_PROPS) = 0.0_wp
    LOGICAL :: valid = .FALSE.
  END TYPE MD_MaterialEntry
```

### `MD_Material_Desc` (lines 397–400)

```fortran
  TYPE, PUBLIC :: MD_Material_Desc
    INTEGER(i4) :: n_materials = 0_i4
    TYPE(MD_MaterialEntry) :: materials(MD_MAT_MAX_MATERIALS)
  END TYPE MD_Material_Desc
```

### `MD_Material_Ctx` (lines 444–471)

```fortran
  TYPE, PUBLIC :: MD_Material_Ctx
    TYPE(MD_Mat_Desc), POINTER :: desc => NULL()
    TYPE(MD_MatSta), POINTER :: mat_sta => NULL()
    TYPE(MD_MatAlgo), POINTER :: algo => NULL()
    TYPE(MatCtxLegacy), POINTER :: ctx => NULL()
    TYPE(MatRes), POINTER :: res => NULL()
    TYPE(UF_Kinematics), POINTER :: kin => NULL()
    TYPE(Desc_MaterialModel), POINTER :: desc_legacy => NULL()
    TYPE(BaseSta) :: sta
    LOGICAL :: init = .FALSE.
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
```

### `ExpDataPt` (lines 473–479)

```fortran
  TYPE, PUBLIC :: ExpDataPt
    REAL(wp) :: strain = 0.0_wp
    REAL(wp) :: stress = 0.0_wp
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: weight = 1.0_wp
  END TYPE ExpDataPt
```

### `ExpDataSet` (lines 481–485)

```fortran
  TYPE, PUBLIC :: ExpDataSet
    INTEGER(i4) :: n_points = 0_i4
    TYPE(ExpDataPt), ALLOCATABLE :: data(:)
    CHARACTER(len=64) :: test_type = ""
  END TYPE ExpDataSet
```

### `MatParamId` (lines 487–498)

```fortran
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
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MatCtxLegacy_InitLegacy` | 522 | `subroutine MatCtxLegacy_InitLegacy(this, kin, desc, material_id, nprops, nstatev, status)` |
| SUBROUTINE | `MatCtxLegacy_Clean` | 552 | `subroutine MatCtxLegacy_Clean(this)` |
| SUBROUTINE | `SetProps` | 586 | `subroutine SetProps(this, props)` |
| SUBROUTINE | `SetStateV` | 600 | `subroutine SetStateV(this, statev)` |
| SUBROUTINE | `GetProps` | 614 | `subroutine GetProps(this, props)` |
| SUBROUTINE | `GetStateV` | 634 | `subroutine GetStateV(this, statev)` |
| SUBROUTINE | `AllocateProps` | 654 | `subroutine AllocateProps(this, nprops, status)` |
| SUBROUTINE | `AllocateStateV` | 690 | `subroutine AllocateStateV(this, nstatev, status)` |
| FUNCTION | `IsPropsAssociated` | 726 | `function IsPropsAssociated(this) result(is_associated)` |
| FUNCTION | `IsStateVAssociated` | 732 | `function IsStateVAssociated(this) result(is_associated)` |
| SUBROUTINE | `MatRes_InitArrays` | 741 | `subroutine MatRes_InitArrays(this, ntens, nstatev, status)` |
| SUBROUTINE | `MatRes_Clean` | 765 | `subroutine MatRes_Clean(this)` |
| SUBROUTINE | `Reset` | 772 | `subroutine Reset(this)` |
| SUBROUTINE | `MatProps_InitArrays` | 790 | `subroutine MatProps_InitArrays(this, material_id, nprops, status)` |
| SUBROUTINE | `MatProps_Clean` | 809 | `subroutine MatProps_Clean(this)` |
| SUBROUTINE | `SetProp` | 816 | `subroutine SetProp(this, idx, value)` |
| SUBROUTINE | `GetProp` | 825 | `subroutine GetProp(this, idx, value)` |
| SUBROUTINE | `MD_MAT_UMAT_Intf_Init0` | 838 | `subroutine MD_MAT_UMAT_Intf_Init0(this, material_id, material_name, nprops, nstatev, &` |
| SUBROUTINE | `MD_MAT_UMAT_Intf_Valid0` | 863 | `subroutine MD_MAT_UMAT_Intf_Valid0(this, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Input_Init0` | 893 | `subroutine MD_MAT_UMAT_Input_Init0(this, ntens, nstatv, nprops, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Input_Clean0` | 938 | `subroutine MD_MAT_UMAT_Input_Clean0(this)` |
| SUBROUTINE | `FromKinematics` | 947 | `subroutine FromKinematics(this, kin)` |
| SUBROUTINE | `MD_MAT_UMAT_Output_Init0` | 968 | `subroutine MD_MAT_UMAT_Output_Init0(this, ntens, nstatv, status)` |
| SUBROUTINE | `MD_MAT_UMAT_Output_Clean0` | 997 | `subroutine MD_MAT_UMAT_Output_Clean0(this)` |
| SUBROUTINE | `ToState` | 1006 | `subroutine ToState(this, state)` |
| SUBROUTINE | `MatCtx_Init` | 1028 | `subroutine MatCtx_Init(this)` |
| SUBROUTINE | `MatCtx_Clean` | 1036 | `subroutine MatCtx_Clean(this)` |
| SUBROUTINE | `MatCtx_Reset` | 1049 | `subroutine MatCtx_Reset(this)` |
| FUNCTION | `MatCtx_GetStat` | 1055 | `function MatCtx_GetStat(this) result(status)` |
| SUBROUTINE | `MatCtx_SetStat` | 1067 | `subroutine MatCtx_SetStat(this, status)` |
| SUBROUTINE | `MatCtx_ClrStat` | 1073 | `subroutine MatCtx_ClrStat(this)` |
| FUNCTION | `MatCtx_IsOk` | 1078 | `function MatCtx_IsOk(this) result(is_ok)` |
| FUNCTION | `MatCtx_IsErr` | 1084 | `function MatCtx_IsErr(this) result(is_error)` |
| SUBROUTINE | `MatCtx_Bind` | 1090 | `subroutine MatCtx_Bind(this, desc, sta, algo, ctx, res, kin, desc_legacy)` |
| FUNCTION | `MatCtx_Valid` | 1111 | `function MatCtx_Valid(this) result(is_valid)` |
| FUNCTION | `MatCtx_GetCtx` | 1128 | `function MatCtx_GetCtx(this) result(ctx)` |
| FUNCTION | `MatCtx_GetRes` | 1134 | `function MatCtx_GetRes(this) result(res)` |
| FUNCTION | `MatCtx_GetDesc` | 1140 | `function MatCtx_GetDesc(this) result(desc)` |
| FUNCTION | `MatCtx_GetSta` | 1146 | `function MatCtx_GetSta(this) result(sta)` |
| FUNCTION | `MatCtx_GetAlgo` | 1152 | `function MatCtx_GetAlgo(this) result(algo)` |
| SUBROUTINE | `MD_Mat_Desc_SyncDeprecatedFlat` | 1159 | `SUBROUTINE MD_Mat_Desc_SyncDeprecatedFlat(this)` |
| SUBROUTINE | `MD_Mat_Desc_Init_Base` | 1178 | `SUBROUTINE MD_Mat_Desc_Init_Base(this)` |
| SUBROUTINE | `MD_Mat_Desc_Init` | 1184 | `SUBROUTINE MD_Mat_Desc_Init(this, id, name, materialType, class_id, nProps, nStateV, behavior, description)` |
| SUBROUTINE | `MD_Mat_Desc_Destroy` | 1210 | `SUBROUTINE MD_Mat_Desc_Destroy(this)` |
| SUBROUTINE | `MD_Mat_Desc_RegLayout` | 1216 | `SUBROUTINE MD_Mat_Desc_RegLayout(this)` |
| SUBROUTINE | `MD_Mat_Desc_Ensure` | 1220 | `SUBROUTINE MD_Mat_Desc_Ensure(this)` |
| FUNCTION | `MD_Mat_Desc_Valid_Fn` | 1224 | `FUNCTION MD_Mat_Desc_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `MD_MatState_Init_Base` | 1230 | `SUBROUTINE MD_MatState_Init_Base(this)` |
| SUBROUTINE | `MD_MatState_Destroy` | 1236 | `SUBROUTINE MD_MatState_Destroy(this)` |
| SUBROUTINE | `MD_MatMeta_ValidateProps` | 1244 | `SUBROUTINE MD_MatMeta_ValidateProps(this, nprops, nstatev, status)` |
| SUBROUTINE | `MatReg_Init` | 1252 | `SUBROUTINE MatReg_Init(this, MD_MAT_MAX_MATS, status)` |
| SUBROUTINE | `MatReg_Clean` | 1264 | `SUBROUTINE MatReg_Clean(this)` |
| SUBROUTINE | `MatReg_RegisterMaterial` | 1271 | `SUBROUTINE MatReg_RegisterMaterial(this, material_id, name, description, category, status)` |
| SUBROUTINE | `MatReg_GetMaterial` | 1280 | `SUBROUTINE MatReg_GetMaterial(this, material_id, metadata, status)` |
| SUBROUTINE | `MatReg_FindMaterial` | 1289 | `SUBROUTINE MatReg_FindMaterial(this, name, material_id, status)` |
| SUBROUTINE | `MatReg_ListMaterials` | 1299 | `SUBROUTINE MatReg_ListMaterials(this, material_ids, material_names, nFound, status)` |
| SUBROUTINE | `MatReg_ValidateProps` | 1310 | `SUBROUTINE MatReg_ValidateProps(this, material_id, nprops, nstatev, status)` |
| FUNCTION | `MatReg_GetCategoryName` | 1318 | `FUNCTION MatReg_GetCategoryName(this, category) RESULT(name)` |
| SUBROUTINE | `MatInst_Init` | 1325 | `SUBROUTINE MatInst_Init(this, instance_id, material_id, name, metadata, nprops, nstatev, status)` |
| SUBROUTINE | `MatInst_Clean` | 1341 | `SUBROUTINE MatInst_Clean(this)` |
| SUBROUTINE | `MatInst_SetProps` | 1347 | `SUBROUTINE MatInst_SetProps(this, props, status)` |
| SUBROUTINE | `MatInst_GetProps` | 1355 | `SUBROUTINE MatInst_GetProps(this, props, status)` |
| SUBROUTINE | `MatInst_Valid` | 1364 | `SUBROUTINE MatInst_Valid(this, status)` |
| SUBROUTINE | `MatPoolMgr_Init` | 1371 | `SUBROUTINE MatPoolMgr_Init(this, max_instances, status)` |
| SUBROUTINE | `MatPoolMgr_Clean` | 1383 | `SUBROUTINE MatPoolMgr_Clean(this)` |
| SUBROUTINE | `MatPoolMgr_CreateInst` | 1389 | `SUBROUTINE MatPoolMgr_CreateInst(this, material_id, name, props, instance_id, status)` |
| SUBROUTINE | `MatPoolMgr_GetInst` | 1401 | `SUBROUTINE MatPoolMgr_GetInst(this, instance_id, instance, status)` |
| SUBROUTINE | `MatPoolMgr_RemoveInst` | 1410 | `SUBROUTINE MatPoolMgr_RemoveInst(this, instance_id, status)` |
| SUBROUTINE | `MatPoolMgr_UpdateInst` | 1418 | `SUBROUTINE MatPoolMgr_UpdateInst(this, instance_id, props, status)` |
| SUBROUTINE | `MatPoolMgr_ListInsts` | 1427 | `SUBROUTINE MatPoolMgr_ListInsts(this, instance_ids, material_ids, names, nFound, status)` |
| FUNCTION | `MatPoolMgr_GetReg` | 1438 | `FUNCTION MatPoolMgr_GetReg(this) RESULT(registry)` |
| SUBROUTINE | `MatComp_RotMat` | 1444 | `SUBROUTINE MatComp_RotMat(angles, rotationMatrix)` |
| SUBROUTINE | `MatOri_InitAngles` | 1461 | `SUBROUTINE MatOri_InitAngles(this, angles, status)` |
| FUNCTION | `MatOri_GetRotMat` | 1472 | `FUNCTION MatOri_GetRotMat(this) RESULT(rm)` |
| SUBROUTINE | `MatPropValid_InitArrays` | 1478 | `SUBROUTINE MatPropValid_InitArrays(this, id, numProperties, status)` |
| SUBROUTINE | `MatPropValid_SetPropRange` | 1498 | `SUBROUTINE MatPropValid_SetPropRange(this, propId, minValue, maxValue, required, propName)` |
| FUNCTION | `MatPropValid_ValidProps` | 1511 | `FUNCTION MatPropValid_ValidProps(this, properties) RESULT(isValid)` |
| FUNCTION | `MatPropValid_GetErrMsg` | 1535 | `FUNCTION MatPropValid_GetErrMsg(this) RESULT(errorMessage)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
