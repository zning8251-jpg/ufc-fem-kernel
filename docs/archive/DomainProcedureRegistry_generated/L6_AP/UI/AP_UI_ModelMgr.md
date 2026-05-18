# `AP_UI_ModelMgr.f90`

- **Source**: `L6_AP/UI/AP_UI_ModelMgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `AP_UI_ModelMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_ModelMgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI_ModelMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_ModelMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ValidRes` (lines 61–67)

```fortran
  type, public :: ValidRes
    logical :: is_valid = .true.
    integer(i4) :: num_errors = 0_i4
    integer(i4) :: num_warnings = 0_i4
    character(len=256), allocatable :: errors(:)
    character(len=256), allocatable :: warnings(:)
  end type ValidRes
```

### `ValidMgr` (lines 72–86)

```fortran
  type, public :: ValidMgr
    type(TreeMgr), pointer :: tree_mgr => null()
    logical :: init = .false.
  contains
    procedure, public :: Init => ValidMgr_Init
    procedure, public :: ValidateModel => ValidMgr_ValidModel
    procedure, public :: ValidateNode => ValidMgr_ValidNode
    procedure, public :: CheckDependencies => ValidMgr_ChkDep
    procedure, public :: GetValidationReport => ValidMgr_GetRpt
    procedure, private :: ValidatePart => ValidMgr_ValidatePart
    procedure, private :: ValidateMaterial => ValidMgr_ValidateMaterial
    procedure, private :: ValidateSection => ValidMgr_ValidateSection
    procedure, private :: ValidateStep => ValidMgr_ValidateStep
    procedure, private :: ValidateLoadBC => ValidMgr_ValidateLoadBC
  end type ValidMgr
```

### `PropertyField` (lines 91–103)

```fortran
  type, public :: PropertyField
    character(len=64) :: field_name = ''
    character(len=128) :: display_name = ''
    character(len=256) :: description = ''
    integer(i4) :: field_type = FIELD_TYPE_TEXT
    logical :: is_required = .false.
    logical :: is_readonly = .false.
    character(len=256) :: default_value = ''
    character(len=256) :: current_value = ''
    character(len=256) :: validation_rule = ''
    integer(i4) :: num_choices = 0_i4
    character(len=64), allocatable :: choices(:)
  end type PropertyField
```

### `PropertyForm` (lines 108–114)

```fortran
  type, public :: PropertyForm
    integer(i4) :: node_type = 0_i4
    character(len=64) :: form_name = ''
    character(len=128) :: form_title = ''
    integer(i4) :: num_fields = 0_i4
    type(PropertyField), allocatable :: fields(:)
  end type PropertyForm
```

### `PropertyMgr` (lines 119–131)

```fortran
  type, public :: PropertyMgr
    type(TreeMgr), pointer :: tree_mgr => null()
    type(PropertyForm), allocatable :: forms(:)
    logical :: init = .false.
  contains
    procedure, public :: Init => PropertyMgr_Init
    procedure, public :: GetForm => PropertyMgr_GetForm
    procedure, public :: GetFieldValue => PropertyMgr_GetFieldValue
    procedure, public :: SetFieldValue => PropertyMgr_SetFieldValue
    procedure, public :: ValidateForm => PropertyMgr_ValidateForm
    procedure, public :: ApplyChanges => PropertyMgr_ApplyChanges
    procedure, private :: CreateFormForNodeType => PropMgr_CreateFormForNodeType
  end type PropertyMgr
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ValidMgr_Init` | 139 | `subroutine ValidMgr_Init(this, tree_mgr, status)` |
| SUBROUTINE | `ValidMgr_ValidModel` | 150 | `subroutine ValidMgr_ValidModel(this, model_tree, result, status)` |
| SUBROUTINE | `ValidMgr_ValidNode` | 195 | `subroutine ValidMgr_ValidNode(this, node_id, result, status)` |
| SUBROUTINE | `ValidMgr_ChkDep` | 251 | `subroutine ValidMgr_ChkDep(this, model_tree, result)` |
| FUNCTION | `ValidMgr_GetRpt` | 326 | `function ValidMgr_GetRpt(this, result) result(report)` |
| SUBROUTINE | `ValidMgr_ValidatePart` | 359 | `subroutine ValidMgr_ValidatePart(this, obj_ptr, result)` |
| SUBROUTINE | `ValidMgr_ValidateMaterial` | 393 | `subroutine ValidMgr_ValidateMaterial(this, obj_ptr, result)` |
| SUBROUTINE | `ValidMgr_ValidateSection` | 457 | `subroutine ValidMgr_ValidateSection(this, obj_ptr, result)` |
| SUBROUTINE | `ValidMgr_ValidateStep` | 538 | `subroutine ValidMgr_ValidateStep(this, obj_ptr, result)` |
| SUBROUTINE | `ValidMgr_ValidateLoadBC` | 612 | `subroutine ValidMgr_ValidateLoadBC(this, obj_ptr, result)` |
| SUBROUTINE | `AddError` | 690 | `subroutine AddError(result, error_msg)` |
| SUBROUTINE | `AddWarning` | 711 | `subroutine AddWarning(result, warning_msg)` |
| SUBROUTINE | `PropertyMgr_Init` | 735 | `subroutine PropertyMgr_Init(this, tree_mgr, status)` |
| FUNCTION | `PropertyMgr_GetForm` | 753 | `function PropertyMgr_GetForm(this, node_type) result(form)` |
| FUNCTION | `PropertyMgr_GetFieldValue` | 770 | `function PropertyMgr_GetFieldValue(this, node_id, field_name) result(value)` |
| SUBROUTINE | `PropertyMgr_SetFieldValue` | 845 | `subroutine PropertyMgr_SetFieldValue(this, node_id, field_name, value, status)` |
| FUNCTION | `PropertyMgr_ValidateForm` | 924 | `function PropertyMgr_ValidateForm(this, node_id, form) result(is_valid)` |
| SUBROUTINE | `PropertyMgr_ApplyChanges` | 979 | `subroutine PropertyMgr_ApplyChanges(this, node_id, form, status)` |
| SUBROUTINE | `PropMgr_CreateFormForNodeType` | 1002 | `subroutine PropMgr_CreateFormForNodeType(this, node_type, form)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
