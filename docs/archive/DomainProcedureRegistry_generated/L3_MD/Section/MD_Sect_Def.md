# `MD_Sect_Def.f90`

- **Source**: `L3_MD/Section/MD_Sect_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sect_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Sect_Desc` (lines 60–83)

```fortran
  TYPE, PUBLIC :: MD_Sect_Desc
    INTEGER(i4)       :: section_id   = 0
    CHARACTER(LEN=64) :: section_name = ''
    INTEGER(i4) :: mat_id = 0
    CLASS(MD_Mat_Desc), POINTER :: mat_desc => NULL()
    REAL(wp) :: thickness   = 0.0_wp
    REAL(wp) :: orientation(3) = 0.0_wp
    REAL(wp) :: offset      = 0.0_wp
    INTEGER(i4) :: nlayer           = 1
    INTEGER(i4) :: integ_npts       = 0
    CHARACTER(LEN=16) :: integ_rule = ''
    INTEGER(i4) :: section_family = 0
    INTEGER(i4) :: section_type   = 0
    LOGICAL :: is_initialized = .FALSE.
    !--- Fields absorbed from legacy MD_Sect_Desc (G9) ---
    REAL(wp)          :: area             = 1.0_wp
    LOGICAL           :: valid            = .FALSE.
  CONTAINS
    PROCEDURE :: InitBasic      => Sect_InitBasic
    PROCEDURE :: InitComposite  => Sect_InitComposite
    PROCEDURE :: AssociateMat   => Sect_AssociateMaterial
    PROCEDURE :: Validate       => Sect_Validate
    PROCEDURE :: Nullify        => Sect_NullifyPointer
  END TYPE MD_Sect_Desc
```

### `MD_Sect_Registry` (lines 85–96)

```fortran
  TYPE, PUBLIC :: MD_Sect_Registry
    TYPE(MD_Sect_Desc), ALLOCATABLE :: sections(:)
    INTEGER(i4) :: nsections = 0
    INTEGER(i4) :: capacity  = 0
  CONTAINS
    PROCEDURE :: Init            => Registry_Init
    PROCEDURE :: AddSection      => Registry_AddSection
    PROCEDURE :: GetSectIdx      => Registry_GetSectIdx
    PROCEDURE :: FindByName      => Registry_FindByName
    PROCEDURE :: FindByMaterial  => Registry_FindByMaterial
    PROCEDURE :: Clear           => Registry_Clear
  END TYPE MD_Sect_Registry
```

### `MD_Sect_State` (lines 108–112)

```fortran
  TYPE, PUBLIC :: MD_Sect_State
    INTEGER(i4) :: active_sections    = 0_i4
    INTEGER(i4) :: total_sections     = 0_i4
    REAL(wp)    :: total_section_area = 0.0_wp
  END TYPE MD_Sect_State
```

### `MD_Sect_Ctx` (lines 119–121)

```fortran
  TYPE, PUBLIC :: MD_Sect_Ctx
    INTEGER(i4) :: current_section_idx = 0_i4
  END TYPE MD_Sect_Ctx
```

### `MD_Sect_Algo` (lines 128–130)

```fortran
  TYPE, PUBLIC :: MD_Sect_Algo
    INTEGER(i4) :: default_integration_rule = 0_i4
  END TYPE MD_Sect_Algo
```

### `MD_Sect_Catalog_Desc` (lines 139–142)

```fortran
  TYPE, PUBLIC :: MD_Sect_Catalog_Desc
    TYPE(MD_Sect_Desc) :: sections(MD_SECTION_MAX)
    INTEGER(i4)       :: n_sections = 0_i4
  END TYPE MD_Sect_Catalog_Desc
```

### `MD_Sect_Add_Arg` (lines 149–152)

```fortran
  TYPE, PUBLIC :: MD_Sect_Add_Arg
    TYPE(MD_Sect_Desc)     :: desc
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_Add_Arg
```

### `MD_Sect_Validate_Arg` (lines 159–162)

```fortran
  TYPE, PUBLIC :: MD_Sect_Validate_Arg
    INTEGER(i4)           :: idx = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_Validate_Arg
```

### `MD_Sect_GetSummary_Arg` (lines 169–172)

```fortran
  TYPE, PUBLIC :: MD_Sect_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Sect_GetSummary_Arg
```

### `MD_Sect_Get_Arg` (lines 179–181)

```fortran
  TYPE, PUBLIC :: MD_Sect_Get_Arg
    TYPE(MD_Sect_Desc) :: desc
  END TYPE MD_Sect_Get_Arg
```

### `MD_Sect_GetByName_Arg` (lines 188–192)

```fortran
  TYPE, PUBLIC :: MD_Sect_GetByName_Arg
    INTEGER(i4)       :: section_idx = 0_i4
    LOGICAL             :: found       = .FALSE.
    TYPE(MD_Sect_Desc)   :: desc
  END TYPE MD_Sect_GetByName_Arg
```

### `MD_Sect_Domain` (lines 199–213)

```fortran
  TYPE, PUBLIC :: MD_Sect_Domain
    TYPE(MD_Sect_Desc), ALLOCATABLE :: desc_array(:)
    INTEGER(i4)                    :: n_sections = 0_i4
    INTEGER(i4)                    :: capacity   = 0_i4
    TYPE(MD_Sect_Algo)              :: algo
    LOGICAL                        :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Add
    PROCEDURE :: Get
    PROCEDURE :: GetByName
    PROCEDURE :: Validate
    PROCEDURE :: GetSummary
  END TYPE MD_Sect_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Sect_InitBasic` | 217 | `SUBROUTINE Sect_InitBasic(self, id, name, family)` |
| SUBROUTINE | `Sect_InitComposite` | 231 | `SUBROUTINE Sect_InitComposite(self, nlayer, thickness, npts, rule)` |
| SUBROUTINE | `Sect_AssociateMaterial` | 244 | `SUBROUTINE Sect_AssociateMaterial(self, mat_desc_ptr)` |
| SUBROUTINE | `Sect_Validate` | 252 | `SUBROUTINE Sect_Validate(self, st)` |
| SUBROUTINE | `Sect_NullifyPointer` | 298 | `SUBROUTINE Sect_NullifyPointer(self)` |
| SUBROUTINE | `Registry_Init` | 303 | `SUBROUTINE Registry_Init(self, est)` |
| SUBROUTINE | `Registry_AddSection` | 315 | `SUBROUTINE Registry_AddSection(self, sect)` |
| FUNCTION | `Registry_GetSectIdx` | 343 | `FUNCTION Registry_GetSectIdx(self, id) RESULT(idx)` |
| FUNCTION | `Registry_FindByName` | 358 | `FUNCTION Registry_FindByName(self, name) RESULT(idx)` |
| FUNCTION | `Registry_FindByMaterial` | 373 | `FUNCTION Registry_FindByMaterial(self, mat_id) RESULT(idx)` |
| SUBROUTINE | `Registry_Clear` | 388 | `SUBROUTINE Registry_Clear(self)` |
| SUBROUTINE | `Add` | 399 | `SUBROUTINE Add(this, arg)` |
| SUBROUTINE | `MD_Section_AddSection_Impl` | 405 | `SUBROUTINE MD_Section_AddSection_Impl(this, desc, status)` |
| SUBROUTINE | `Finalize` | 435 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Get` | 444 | `SUBROUTINE Get(this, idx, desc, status)` |
| SUBROUTINE | `GetByName` | 459 | `SUBROUTINE GetByName(this, name, desc, status)` |
| SUBROUTINE | `Init` | 485 | `SUBROUTINE Init(this, est_sections, status)` |
| SUBROUTINE | `Validate` | 500 | `SUBROUTINE Validate(this, arg)` |
| SUBROUTINE | `MD_Section_ValidateSection_Impl` | 506 | `SUBROUTINE MD_Section_ValidateSection_Impl(this, idx, status)` |
| SUBROUTINE | `GetSummary` | 557 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Section_GetSummary_Impl` | 563 | `SUBROUTINE MD_Section_GetSummary_Impl(this, summary, status)` |
| SUBROUTINE | `MD_Section_GetSection_Idx` | 584 | `SUBROUTINE MD_Section_GetSection_Idx(dom, section_idx, arg, status)` |
| SUBROUTINE | `MD_Section_GetSectionByName_Idx` | 604 | `SUBROUTINE MD_Section_GetSectionByName_Idx(dom, name, arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
