# `MD_Sect_PropMass.f90`

- **Source**: `L3_MD/Section/MD_Sect_PropMass.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_PropMass`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_PropMass`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect_PropMass`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_PropMass.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PtMassManager` (lines 48–56)

```fortran
    TYPE, PUBLIC :: PtMassManager
        INTEGER(i4) :: numMasses = 0_i4
        TYPE(PtMassDesc), ALLOCATABLE :: masses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => PtMassManager_Add
        PROCEDURE, PUBLIC :: Find       => PtMassManager_Find
        PROCEDURE, PUBLIC :: FindByNode => PtMassManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => PtMassManager_Clear
    END TYPE PtMassManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sect_prop_get_param_value` | 76 | `SUBROUTINE sect_prop_get_param_value(ast_node, param_name, param_value)` |
| FUNCTION | `sect_prop_int_to_str` | 92 | `FUNCTION sect_prop_int_to_str(i) RESULT(str)` |
| SUBROUTINE | `PtMassDesc_RegLayout` | 103 | `SUBROUTINE PtMassDesc_RegLayout(this)` |
| SUBROUTINE | `PtMassDesc_Ensure` | 107 | `SUBROUTINE PtMassDesc_Ensure(this)` |
| SUBROUTINE | `PtMassDesc_Init_Base` | 112 | `SUBROUTINE PtMassDesc_Init_Base(this)` |
| SUBROUTINE | `PtMassDesc_Init` | 118 | `SUBROUTINE PtMassDesc_Init(this, massId, name, nodeId, mass, alpha, status)` |
| FUNCTION | `PtMassDesc_Valid_Fn` | 136 | `FUNCTION PtMassDesc_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `PtMassDesc_Clear` | 142 | `SUBROUTINE PtMassDesc_Clear(this)` |
| SUBROUTINE | `PtMassManager_Add` | 160 | `SUBROUTINE PtMassManager_Add(this, pointMass, status)` |
| FUNCTION | `PtMassManager_Find` | 181 | `FUNCTION PtMassManager_Find(this, name) RESULT(pointMass)` |
| FUNCTION | `PtMassManager_FindByNode` | 196 | `FUNCTION PtMassManager_FindByNode(this, nodeId) RESULT(pointMass)` |
| SUBROUTINE | `PtMassManager_Clear` | 211 | `SUBROUTINE PtMassManager_Clear(this)` |
| SUBROUTINE | `MD_Prop_Mass_Unified_Cfg` | 222 | `SUBROUTINE MD_Prop_Mass_Unified_Cfg(operation, status)` |
| SUBROUTINE | `MD_Prop_Mass_Unified_Parse` | 235 | `SUBROUTINE MD_Prop_Mass_Unified_Parse(prop_type, ast_node, pointMass, context_name, status)` |
| SUBROUTINE | `Parse_MASS_DataLine` | 250 | `SUBROUTINE Parse_MASS_DataLine(data_line, node_id, mass, status)` |
| SUBROUTINE | `Parse_MASS_Keyword` | 273 | `SUBROUTINE Parse_MASS_Keyword(ast_node, pointMass, status)` |
| SUBROUTINE | `Valid_MASS_Keyword` | 315 | `SUBROUTINE Valid_MASS_Keyword(pointMass, model, status)` |
| SUBROUTINE | `Valid_MASS_Node` | 332 | `SUBROUTINE Valid_MASS_Node(pointMass, model, status)` |
| SUBROUTINE | `Valid_MASS_PhysicalValues` | 358 | `SUBROUTINE Valid_MASS_PhysicalValues(pointMass, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
