# `MD_KeyWordParser_Def.f90`

- **Source**: `L3_MD/KeyWord/MD_KeyWordParser_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KeyWordParser_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KeyWordParser_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KeyWordParser`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KeyWordParser_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `KeyWord_Node_Type` (lines 33–60)

```fortran
  TYPE :: KeyWord_Node_Type
    ! Identifiers
    CHARACTER(LEN=32) :: keyword_name  = ""                     ! [in]  Keyword name
    INTEGER(i4)       :: node_id       = 0_i4                   ! [out] Unique node ID
    INTEGER(i4)       :: parent_id     = -1_i4                  ! [in]  Parent node ID
    INTEGER(i4)       :: nesting_level = 0_i4                   ! [in]  Nesting depth

    ! Parameter block
    CHARACTER(LEN=32), POINTER  :: params(:)        => NULL()   ! [out] Param names
    INTEGER(i4)                 :: n_params         = 0_i4      ! [out] Param count
    REAL(wp), POINTER           :: param_values(:)  => NULL()   ! [out] Numeric values
    CHARACTER(LEN=256), POINTER :: param_strings(:) => NULL()   ! [out] String values

    ! Data block
    REAL(wp), POINTER  :: data_block(:,:) => NULL()             ! [out] Data matrix
    INTEGER(i4)        :: n_rows = 0_i4                         ! [out] Row count
    INTEGER(i4)        :: n_cols = 0_i4                         ! [out] Column count
    CHARACTER(LEN=256) :: data_block_description = ""           ! [in]  Data description

    ! Nested keyword tree
    TYPE(KeyWord_Node_Type), POINTER :: child_keywords(:) => NULL()  ! [out] Children
    INTEGER(i4)                      :: n_children = 0_i4            ! [out] Child count

    ! Metadata
    INTEGER(i4) :: line_number  = 0_i4                          ! [out] Source line number
    LOGICAL     :: is_complete  = .FALSE.                       ! [out] Parse complete?
    LOGICAL     :: is_validated = .FALSE.                       ! [out] Validation done?
  END TYPE KeyWord_Node_Type
```

### `KeyWord_ParsingRule_Type` (lines 69–90)

```fortran
  TYPE :: KeyWord_ParsingRule_Type
    CHARACTER(LEN=32)  :: keyword_name   = ""                   ! [in] Keyword name
    CHARACTER(LEN=32)  :: parent_keyword = ""                   ! [in] Parent keyword
    CHARACTER(LEN=256) :: description    = ""                   ! [in] Description

    ! Parameter specifications
    TYPE(KeyWord_ParamSpec_Type), POINTER :: param_specs(:) => NULL()  ! [in]
    INTEGER(i4)                          :: n_param_specs = 0_i4      ! [in]

    ! Data block specification
    LOGICAL            :: has_data_block    = .FALSE.            ! [in] Has data block?
    CHARACTER(LEN=256) :: data_block_format = ""                 ! [in] Format string
    INTEGER(i4)        :: expected_fields   = -1_i4              ! [in] Expected fields

    ! Nesting constraints
    CHARACTER(LEN=32), POINTER :: allowed_children(:) => NULL() ! [in] Valid children
    INTEGER(i4)                :: n_allowed_children = 0_i4     ! [in] Child count

    ! Priority and classification
    INTEGER(i4)        :: priority = 1_i4                       ! [in] P0/P1/P2
    CHARACTER(LEN=32)  :: category = "GENERAL"                  ! [in] Category string
  END TYPE KeyWord_ParsingRule_Type
```

### `KeyWord_ParamSpec_Type` (lines 98–104)

```fortran
  TYPE :: KeyWord_ParamSpec_Type
    CHARACTER(LEN=32)  :: param_name             = ""           ! [in] Parameter name
    CHARACTER(LEN=16)  :: param_type             = "STRING"     ! [in] Type (INT/REAL/STRING/LOGICAL)
    LOGICAL            :: is_required            = .FALSE.      ! [in] Required?
    CHARACTER(LEN=256) :: default_value          = ""           ! [in] Default value
    CHARACTER(LEN=256) :: constraint_description = ""           ! [in] Constraint description
  END TYPE KeyWord_ParamSpec_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_KW_NodeFactory` | 113 | `SUBROUTINE MD_KW_NodeFactory(keyword_name, parent_id, nesting_level, &` |
| SUBROUTINE | `MD_KW_RuleFactory` | 142 | `SUBROUTINE MD_KW_RuleFactory(keyword_name, parent_keyword, &` |
| SUBROUTINE | `MD_KW_TreeInit` | 168 | `SUBROUTINE MD_KW_TreeInit(root_node, status)` |
| SUBROUTINE | `MD_KW_TreePrint` | 181 | `RECURSIVE SUBROUTINE MD_KW_TreePrint(node, indent_level, unit)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
