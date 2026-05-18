# `MD_Mat_Plast_RateDep.f90`

- **Source**: `L3_MD/Material/Plast/MD_Mat_Plast_RateDep.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mat_Plast_RateDep`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mat_Plast_RateDep`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mat_Plast_RateDep`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Material/Plast/MD_Mat_Plast_RateDep.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RateDependentPropertiesManager` (lines 61–68)

```fortran
  TYPE, PUBLIC :: RateDependentPropertiesManager
    INTEGER(i4) :: numProperties = 0_i4
    TYPE(RateDependentProperties), ALLOCATABLE :: properties(:)
  CONTAINS
    PROCEDURE, PUBLIC :: Add => RateDependentPropertiesManager_Add
    PROCEDURE, PUBLIC :: Find => RateDependentPropertiesManager_Find
    PROCEDURE, PUBLIC :: Clear => RateDependentPropertiesManager_Clear
  END TYPE RateDependentPropertiesManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RateDependentProperties_Init_Base` | 90 | `SUBROUTINE RateDependentProperties_Init_Base(this)` |
| SUBROUTINE | `RateDependentProperties_Init` | 96 | `SUBROUTINE RateDependentProperties_Init(this, modelType, status)` |
| FUNCTION | `RateDependentProperties_Valid_Fn` | 111 | `FUNCTION RateDependentProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `RateDependentProperties_Clear` | 126 | `SUBROUTINE RateDependentProperties_Clear(this)` |
| FUNCTION | `RateDependentProperties_ComputeRateFactor` | 145 | `FUNCTION RateDependentProperties_ComputeRateFactor(this, strainRate) RESULT(factor)` |
| FUNCTION | `RateDependentProperties_ComputeStress` | 166 | `FUNCTION RateDependentProperties_ComputeStress(this, strain, strainRate, temperature) RESULT(stress)` |
| SUBROUTINE | `RateDependentPropertiesManager_Add` | 189 | `SUBROUTINE RateDependentPropertiesManager_Add(this, prop, status)` |
| FUNCTION | `RateDependentPropertiesManager_Find` | 209 | `FUNCTION RateDependentPropertiesManager_Find(this, index) RESULT(prop)` |
| SUBROUTINE | `RateDependentPropertiesManager_Clear` | 219 | `SUBROUTINE RateDependentPropertiesManager_Clear(this)` |
| SUBROUTINE | `md_mat_rate_get_param` | 231 | `SUBROUTINE md_mat_rate_get_param(ast_node, param_name, param_value)` |
| SUBROUTINE | `MD_Mat_RateDependent_Unified_Configure` | 247 | `SUBROUTINE MD_Mat_RateDependent_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Mat_RateDependent_Unified_Parse` | 260 | `SUBROUTINE MD_Mat_RateDependent_Unified_Parse(material_type, ast_node, rateDep, material_name, status)` |
| SUBROUTINE | `Parse_RATE_DEPENDENT_Keyword` | 275 | `SUBROUTINE Parse_RATE_DEPENDENT_Keyword(ast_node, rateDep, material_name, status)` |
| SUBROUTINE | `Validate_RATE_DEPENDENT_PhysicalValues` | 353 | `SUBROUTINE Validate_RATE_DEPENDENT_PhysicalValues(rateDep, status)` |
| SUBROUTINE | `Valid_RATE_DEPENDENT_Keyword` | 382 | `SUBROUTINE Valid_RATE_DEPENDENT_Keyword(rateDep, material_name, model, status)` |
| SUBROUTINE | `Valid_RATE_DEPENDENT_Mat` | 400 | `SUBROUTINE Valid_RATE_DEPENDENT_Mat(material_name, model, status)` |
| SUBROUTINE | `UF_RateDepPlast_ValidateProps` | 410 | `SUBROUTINE UF_RateDepPlast_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `RateDepPlast_MatDesc_InitFromProps` | 449 | `SUBROUTINE RateDepPlast_MatDesc_InitFromProps(this, props, nprops, status)` |
| FUNCTION | `RateDepPlast_MatDesc_Valid` | 483 | `FUNCTION RateDepPlast_MatDesc_Valid(this) RESULT(ok)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
