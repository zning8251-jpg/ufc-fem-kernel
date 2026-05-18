# `MD_Field_Def.f90`

- **Source**: `L3_MD/Field/MD_Field_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Field_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Field_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Field`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Field/MD_Field_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_FieldRegionRef` (lines 78–87)

```fortran
  TYPE :: MD_FieldRegionRef
    INTEGER(i4) :: region_kind  = MD_FIELD_REGION_ALL
    INTEGER(i4) :: entity_kind  = MD_FIELD_ENTITY_UNKNOWN
    CHARACTER(LEN=MD_FIELD_REGION_NAME_LEN) :: region_name = ""
    CHARACTER(LEN=MD_FIELD_REGION_NAME_LEN) :: set_name    = ""
    INTEGER(i4) :: entity_start = 0
    INTEGER(i4) :: entity_end   = 0
    INTEGER(i4) :: n_entity_ids = 0
    INTEGER(i4), ALLOCATABLE :: entity_ids(:)
  END TYPE MD_FieldRegionRef
```

### `MD_FieldInitCond` (lines 92–100)

```fortran
  TYPE :: MD_FieldInitCond
    INTEGER(i4) :: field_id          = 0
    INTEGER(i4) :: distribution_kind = MD_FIELD_DIST_UNIFORM
    TYPE(MD_FieldRegionRef) :: region
    INTEGER(i4) :: n_values = 0
    REAL(wp), ALLOCATABLE :: values(:)
    INTEGER(i4) :: table_id = 0
    CHARACTER(LEN=MD_FIELD_AMP_NAME_LEN) :: amplitude_name = ""
  END TYPE MD_FieldInitCond
```

### `MD_FieldEntry` (lines 105–119)

```fortran
  TYPE :: MD_FieldEntry
    INTEGER(i4)                      :: id                = 0
    CHARACTER(LEN=MD_FIELD_NAME_LEN) :: name              = ""
    INTEGER(i4)                      :: field_type        = MD_FIELD_USER
    INTEGER(i4)                      :: n_comp            = 1
    INTEGER(i4)                      :: entity_kind       = MD_FIELD_ENTITY_UNKNOWN
    INTEGER(i4)                      :: distribution_kind = MD_FIELD_DIST_UNIFORM
    TYPE(MD_FieldRegionRef)          :: region
    TYPE(MD_FieldInitCond)           :: initial_condition
    ! Compatibility aliases for legacy consumers. New code should prefer
    ! entity_kind and initial_condition.
    INTEGER(i4)                      :: entity   = MD_FIELD_ENTITY_UNKNOWN
    REAL(wp)                         :: init_val = 0.0_wp
    LOGICAL                          :: valid    = .FALSE.
  END TYPE MD_FieldEntry
```

### `MD_Field_Desc` (lines 124–127)

```fortran
  TYPE :: MD_Field_Desc
    TYPE(MD_FieldEntry) :: fields(MD_FIELD_MAX)
    INTEGER(i4)         :: n_fields = 0
  END TYPE MD_Field_Desc
```

### `MD_Field_State` (lines 132–137)

```fortran
  TYPE, PUBLIC :: MD_Field_State
    LOGICAL     :: allocated   = .FALSE.
    LOGICAL     :: initialized = .FALSE.
    INTEGER(i4) :: n_allocated = 0
    INTEGER(i4) :: total_dof   = 0
  END TYPE MD_Field_State
```

### `MD_Field_Ctx` (lines 142–146)

```fortran
  TYPE, PUBLIC :: MD_Field_Ctx
    INTEGER(i4) :: current_step = 0
    INTEGER(i4) :: current_incr = 0
    REAL(wp)    :: current_time = 0.0_wp
  END TYPE MD_Field_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
