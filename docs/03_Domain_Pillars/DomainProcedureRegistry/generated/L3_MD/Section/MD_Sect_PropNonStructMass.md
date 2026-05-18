# `MD_Sect_PropNonStructMass.f90`

- **Source**: `L3_MD/Section/MD_Sect_PropNonStructMass.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_PropNonStructMass`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_PropNonStructMass`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect_PropNonStructMass`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_PropNonStructMass.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NonStructMassManager` (lines 54–61)

```fortran
    TYPE, PUBLIC :: NonStructMassManager
        INTEGER(i4) :: numNonstructMasses = 0_i4
        TYPE(NonStructMassDesc), ALLOCATABLE :: nonstructMasses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add   => NonStructMassManager_Add
        PROCEDURE, PUBLIC :: Find  => NonStructMassManager_Find
        PROCEDURE, PUBLIC :: Clear => NonStructMassManager_Clear
    END TYPE NonStructMassManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sect_prop_get_param_value` | 81 | `SUBROUTINE sect_prop_get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `NonStructMassDesc_RegLayout` | 102 | `SUBROUTINE NonStructMassDesc_RegLayout(this)` |
| SUBROUTINE | `NonStructMassDesc_Ensure` | 106 | `SUBROUTINE NonStructMassDesc_Ensure(this)` |
| SUBROUTINE | `NonStructMassDesc_Init_Base` | 111 | `SUBROUTINE NonStructMassDesc_Init_Base(this)` |
| SUBROUTINE | `NonStructMassDesc_Init` | 117 | `SUBROUTINE NonStructMassDesc_Init(this, nonstructMassId, name, elsetName, &` |
| FUNCTION | `NonStructMassDesc_Valid_Fn` | 138 | `FUNCTION NonStructMassDesc_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `NonStructMassDesc_Clear` | 148 | `SUBROUTINE NonStructMassDesc_Clear(this)` |
| SUBROUTINE | `NonStructMassManager_Add` | 168 | `SUBROUTINE NonStructMassManager_Add(this, nonstructMass, status)` |
| FUNCTION | `NonStructMassManager_Find` | 189 | `FUNCTION NonStructMassManager_Find(this, name) RESULT(nonstructMass)` |
| SUBROUTINE | `NonStructMassManager_Clear` | 204 | `SUBROUTINE NonStructMassManager_Clear(this)` |
| SUBROUTINE | `MD_Prop_NonstructuralMass_Unified_Configure` | 215 | `SUBROUTINE MD_Prop_NonstructuralMass_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Prop_NonstructuralMass_Unified_Parse` | 228 | `SUBROUTINE MD_Prop_NonstructuralMass_Unified_Parse(prop_type, ast_node, nonstructMass, context_name, status)` |
| SUBROUTINE | `Parse_NONSTRUCTURALMASS_DataLine` | 243 | `SUBROUTINE Parse_NONSTRUCTURALMASS_DataLine(data_line, mass_value, status)` |
| SUBROUTINE | `Parse_NONSTRUCTURALMASS_Keyword` | 260 | `SUBROUTINE Parse_NONSTRUCTURALMASS_Keyword(ast_node, nonstructMass, status)` |
| SUBROUTINE | `Validate_NONSTRUCTURALMASS_Elset` | 304 | `SUBROUTINE Validate_NONSTRUCTURALMASS_Elset(nonstructMass, model, status)` |
| SUBROUTINE | `Validate_NONSTRUCTURALMASS_Keyword` | 331 | `SUBROUTINE Validate_NONSTRUCTURALMASS_Keyword(nonstructMass, model, status)` |
| SUBROUTINE | `Validate_NONSTRUCTURALMASS_PhysicalValues` | 348 | `SUBROUTINE Validate_NONSTRUCTURALMASS_PhysicalValues(nonstructMass, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
