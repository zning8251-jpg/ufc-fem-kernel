# `MD_Mat_Reg_Ops.f90`

- **Source**: `L3_MD/Material/Registry/MD_Mat_Reg_Ops.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mat_Reg_Ops`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Reg_Ops`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Reg`
- **第四段角色（四段式）**: `_Ops`
- **源码子路径（层下目录，不含文件名）**: `Material/Registry`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Registry/MD_Mat_Reg_Ops.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MatLibModelEntry` (lines 94–104)

```fortran
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
```

### `MD_MatIDCacheEntry` (lines 251–255)

```fortran
  type :: MD_MatIDCacheEntry
    integer(i4) :: material_id = 0_i4
    integer(i4) :: index = 0_i4
    logical :: valid = .false.
  end type MD_MatIDCacheEntry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_MAT_UMAT_Procedure` | 71 | `subroutine MD_MAT_UMAT_Procedure(stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `init_mate` | 269 | `subroutine init_mate(status)` |
| SUBROUTINE | `reg_mate_types` | 275 | `subroutine reg_mate_types(status)` |
| SUBROUTINE | `prop_mate` | 355 | `subroutine prop_mate(name, id, status)` |
| SUBROUTINE | `st_mate` | 363 | `subroutine st_mate(name, id, status)` |
| SUBROUTINE | `del_mate` | 371 | `subroutine del_mate(id, status)` |
| SUBROUTINE | `MatInit_Def` | 378 | `subroutine MatInit_Def(registry, status)` |
| SUBROUTINE | `MatLib_Init` | 451 | `subroutine MatLib_Init(this, max_capacity, status)` |
| SUBROUTINE | `MatLib_Cleanup` | 472 | `subroutine MatLib_Cleanup(this, status)` |
| SUBROUTINE | `MatLib_Reg` | 484 | `subroutine MatLib_Reg(this, name, item, status)` |
| SUBROUTINE | `MatLib_Unregister` | 499 | `subroutine MatLib_Unregister(this, name, status)` |
| FUNCTION | `MatLib_Lookup` | 512 | `function MatLib_Lookup(this, name) result(found)` |
| FUNCTION | `MatLib_Exists` | 528 | `function MatLib_Exists(this, name) result(exists)` |
| FUNCTION | `MatLib_GetRegisteredCount` | 536 | `function MatLib_GetRegisteredCount(this) result(count)` |
| SUBROUTINE | `MatLib_ListRegistered` | 544 | `subroutine MatLib_ListRegistered(this, names, count, status)` |
| SUBROUTINE | `MatLib_Init` | 571 | `subroutine MatLib_Init(this, max_models, status)` |
| SUBROUTINE | `InitMaterialCache` | 607 | `subroutine InitMaterialCache(this, status)` |
| SUBROUTINE | `MatLib_Destroy` | 636 | `subroutine MatLib_Destroy(this)` |
| SUBROUTINE | `MatLib_RegisterModel` | 651 | `subroutine MatLib_RegisterModel(this, material_id, name, category, umat_proc, &` |
| SUBROUTINE | `MatLib_GetModel` | 742 | `subroutine MatLib_GetModel(this, material_id, model, status)` |
| SUBROUTINE | `MatLib_UMAT_Dispatch` | 798 | `subroutine MatLib_UMAT_Dispatch(this, material_id, stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `MatLib_ListModels` | 843 | `subroutine MatLib_ListModels(this, material_ids, material_names, categories, nFound, status)` |
| SUBROUTINE | `MatLib_GetModelInfo` | 882 | `subroutine MatLib_GetModelInfo(this, material_id, name, category, nprops_min, &` |
| SUBROUTINE | `RegisterDefaultModels` | 910 | `subroutine RegisterDefaultModels(this, status)` |
| SUBROUTINE | `SetCurrentMaterialID` | 1147 | `subroutine SetCurrentMaterialID(material_id)` |
| FUNCTION | `GetCurrentMaterialID` | 1153 | `function GetCurrentMaterialID() result(material_id)` |
| FUNCTION | `FindMaterialIDFromWrapper` | 1159 | `function FindMaterialIDFromWrapper(wrapper_proc) result(material_id)` |
| SUBROUTINE | `MD_MAT_UMAT_Damage_Wrapper` | 1208 | `subroutine MD_MAT_UMAT_Damage_Wrapper(stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `MD_MAT_UMAT_Visco_Wrapper` | 1243 | `subroutine MD_MAT_UMAT_Visco_Wrapper(stress, statev, ddsdde, sse, spd, scd, &` |
| FUNCTION | `GetMaterialCategory` | 1282 | `function GetMaterialCategory(material_id) result(category)` |
| FUNCTION | `GetMaterialCategoryName` | 1306 | `function GetMaterialCategoryName(category) result(name)` |
| SUBROUTINE | `MD_MatLib_Legacy_Dispatch` | 1337 | `subroutine MD_MatLib_Legacy_Dispatch(material_id, stress, statev, ddsdde, &` |
| FUNCTION | `GetMaterialName` | 1372 | `function GetMaterialName(matId) result(name)` |
| FUNCTION | `GetMaterialProps` | 1388 | `function GetMaterialProps(matId) result(nprops)` |
| SUBROUTINE | `MD_MAT_UMAT_101` | 1408 | `subroutine MD_MAT_UMAT_101(stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `MD_MAT_UMAT_102` | 1433 | `subroutine MD_MAT_UMAT_102(stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `MD_MAT_UMAT_103` | 1458 | `subroutine MD_MAT_UMAT_103(stress, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `Reg_Mat_Library` | 1486 | `subroutine Reg_Mat_Library()` |
| SUBROUTINE | `Set_Domain_Ptr` | 1515 | `subroutine Set_Domain_Ptr(domain_ptr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
