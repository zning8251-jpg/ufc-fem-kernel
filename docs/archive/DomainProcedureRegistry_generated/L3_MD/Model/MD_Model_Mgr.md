# `MD_Model_Mgr.f90`

- **Source**: `L3_MD/Model/MD_Model_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Model_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Model_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Model`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Model`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Model/MD_Model_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Model_Domain` (lines 38–52)

```fortran
  TYPE, PUBLIC :: MD_Model_Domain
    TYPE(MD_Model_Desc) :: desc                          ! model descriptor
    LOGICAL             :: isBuilt        = .FALSE.      ! build completed flag
    REAL(wp)            :: build_timestamp = 0.0_wp      ! build timestamp
    LOGICAL             :: initialized    = .FALSE.      ! init state
  CONTAINS
    PROCEDURE :: Init          => MD_Model_Domain_Init
    PROCEDURE :: Finalize      => MD_Model_Domain_Finalize
    PROCEDURE :: SetDesc       => MD_Model_Domain_SetDesc
    PROCEDURE :: GetInfo       => MD_Model_Domain_GetInfo
    PROCEDURE :: WriteBack     => MD_Model_WriteBack
    PROCEDURE :: ValidateModel => MD_Model_ValidateModel
    PROCEDURE :: GetModelByName => MD_Model_Domain_GetModelByName
    PROCEDURE :: GetSummary    => MD_Model_Domain_GetSummary
  END TYPE MD_Model_Domain
```

### `MD_Model_GetSummary_Arg` (lines 60–63)

```fortran
  TYPE, PUBLIC :: MD_Model_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! [out] summary text
    TYPE(ErrorStatusType) :: status        ! [out] error status
  END TYPE MD_Model_GetSummary_Arg
```

### `AdvPropsMgr` (lines 95–110)

```fortran
  TYPE, PUBLIC :: AdvPropsMgr
    INTEGER(i4) :: numImports = 0_i4
    INTEGER(i4) :: numPrestresses = 0_i4
    INTEGER(i4) :: numSubstructures = 0_i4
    TYPE(ImportProperties), ALLOCATABLE :: imports(:)
    TYPE(PrestressProperties), ALLOCATABLE :: prestresses(:)
    TYPE(SubstructureProperties), ALLOCATABLE :: substructures(:)
  CONTAINS
    PROCEDURE, PUBLIC :: AddImport => AdvPropsMgr_AddImport
    PROCEDURE, PUBLIC :: AddPrestress => AdvPropsMgr_AddPrestress
    PROCEDURE, PUBLIC :: AddSubstructure => AdvPropsMgr_AddSubstructure
    PROCEDURE, PUBLIC :: FindImport => AdvPropsMgr_FindImport
    PROCEDURE, PUBLIC :: FindPrestress => AdvPropsMgr_FindPrestress
    PROCEDURE, PUBLIC :: FindSubstructure => AdvPropsMgr_FindSubstructure
    PROCEDURE, PUBLIC :: Clear => AdvPropsMgr_Clear
  END TYPE AdvPropsMgr
```

### `MD_Model_Domain_Init_Arg` (lines 755–758)

```fortran
  TYPE, PUBLIC :: MD_Model_Domain_Init_Arg
    TYPE(MD_Model_Desc)               :: desc        ! [INOUT] desc to init
    TYPE(ErrorStatusType)             :: status      ! [OUT] status
  END TYPE MD_Model_Domain_Init_Arg
```

### `MD_Model_Domain_SetDesc_Arg` (lines 760–763)

```fortran
  TYPE, PUBLIC :: MD_Model_Domain_SetDesc_Arg
    TYPE(MD_Model_Desc)               :: desc        ! [IN] new desc
    TYPE(ErrorStatusType)             :: status      ! [OUT] status
  END TYPE MD_Model_Domain_SetDesc_Arg
```

### `MD_Model_Domain_Validate_Arg` (lines 765–768)

```fortran
  TYPE, PUBLIC :: MD_Model_Domain_Validate_Arg
    LOGICAL                           :: is_valid    ! [OUT] validation result
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_Model_Domain_Validate_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Model_Domain_Init` | 127 | `SUBROUTINE MD_Model_Domain_Init(this, model_name, spatial_dim, status)` |
| SUBROUTINE | `MD_Model_Domain_Finalize` | 155 | `SUBROUTINE MD_Model_Domain_Finalize(this)` |
| SUBROUTINE | `MD_Model_Domain_GetInfo` | 170 | `SUBROUTINE MD_Model_Domain_GetInfo(this, desc, status)` |
| SUBROUTINE | `MD_Model_Domain_SetDesc` | 193 | `SUBROUTINE MD_Model_Domain_SetDesc(this, desc, status)` |
| SUBROUTINE | `MD_Model_WriteBack` | 216 | `SUBROUTINE MD_Model_WriteBack(this, isBuilt, build_timestamp, status)` |
| SUBROUTINE | `MD_Model_ValidateModel` | 241 | `SUBROUTINE MD_Model_ValidateModel(this, status)` |
| SUBROUTINE | `MD_Model_Domain_GetModelByName` | 278 | `SUBROUTINE MD_Model_Domain_GetModelByName(this, name, found, status)` |
| SUBROUTINE | `MD_Model_Domain_GetSummary` | 306 | `SUBROUTINE MD_Model_Domain_GetSummary(this, arg)` |
| SUBROUTINE | `MD_Model_GetSummary_Impl` | 318 | `SUBROUTINE MD_Model_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `MD_Model_Ctx_Init` | 352 | `SUBROUTINE MD_Model_Ctx_Init(this)` |
| SUBROUTINE | `MD_Model_Ctx_Destroy` | 366 | `SUBROUTINE MD_Model_Ctx_Destroy(this)` |
| SUBROUTINE | `MD_Model_Ctx_Reset` | 383 | `SUBROUTINE MD_Model_Ctx_Reset(this)` |
| FUNCTION | `MD_Model_Ctx_GetStatus` | 395 | `FUNCTION MD_Model_Ctx_GetStatus(this) RESULT(status)` |
| SUBROUTINE | `MD_Model_Ctx_SetStatus` | 413 | `SUBROUTINE MD_Model_Ctx_SetStatus(this, status)` |
| SUBROUTINE | `MD_Model_Ctx_ClearStatus` | 425 | `SUBROUTINE MD_Model_Ctx_ClearStatus(this)` |
| FUNCTION | `MD_Model_Ctx_IsOK` | 436 | `FUNCTION MD_Model_Ctx_IsOK(this) RESULT(is_ok)` |
| FUNCTION | `MD_Model_Ctx_IsError` | 448 | `FUNCTION MD_Model_Ctx_IsError(this) RESULT(is_error)` |
| SUBROUTINE | `MD_Model_Ctx_Bind` | 460 | `SUBROUTINE MD_Model_Ctx_Bind(this, desc, state, ctx, algo, tws)` |
| FUNCTION | `MD_Model_Ctx_Valid` | 482 | `FUNCTION MD_Model_Ctx_Valid(this) RESULT(is_valid)` |
| FUNCTION | `MD_Model_Ctx_GetDesc` | 495 | `FUNCTION MD_Model_Ctx_GetDesc(this) RESULT(desc)` |
| FUNCTION | `MD_Model_Ctx_GetState` | 507 | `FUNCTION MD_Model_Ctx_GetState(this) RESULT(state)` |
| FUNCTION | `MD_Model_Ctx_GetAlgo` | 519 | `FUNCTION MD_Model_Ctx_GetAlgo(this) RESULT(algo)` |
| SUBROUTINE | `MD_Model_Ctx_Get_NestedContext` | 531 | `SUBROUTINE MD_Model_Ctx_Get_NestedContext(parent, context_name, nested_context, found, status)` |
| SUBROUTINE | `MD_Model_Ctx_Set_NestedContext` | 555 | `SUBROUTINE MD_Model_Ctx_Set_NestedContext(parent, context_name, nested_context, status)` |
| SUBROUTINE | `MD_Model_Ctx_Merge_Contexts` | 586 | `SUBROUTINE MD_Model_Ctx_Merge_Contexts(ctx1, ctx2, merged, status)` |
| SUBROUTINE | `AdvPropsMgr_AddImport` | 609 | `SUBROUTINE AdvPropsMgr_AddImport(this, import_prop, status)` |
| SUBROUTINE | `AdvPropsMgr_AddPrestress` | 638 | `SUBROUTINE AdvPropsMgr_AddPrestress(this, prestress, status)` |
| SUBROUTINE | `AdvPropsMgr_AddSubstructure` | 667 | `SUBROUTINE AdvPropsMgr_AddSubstructure(this, substructure, status)` |
| SUBROUTINE | `AdvPropsMgr_Clear` | 696 | `SUBROUTINE AdvPropsMgr_Clear(this)` |
| FUNCTION | `AdvPropsMgr_FindImport` | 706 | `FUNCTION AdvPropsMgr_FindImport(this, name) RESULT(import_prop)` |
| FUNCTION | `AdvPropsMgr_FindPrestress` | 721 | `FUNCTION AdvPropsMgr_FindPrestress(this, name) RESULT(prestress)` |
| FUNCTION | `AdvPropsMgr_FindSubstructure` | 736 | `FUNCTION AdvPropsMgr_FindSubstructure(this, name) RESULT(substructure)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
