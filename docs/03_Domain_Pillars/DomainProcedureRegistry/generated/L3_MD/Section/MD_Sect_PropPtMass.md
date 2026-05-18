# `MD_Sect_PropPtMass.f90`

- **Source**: `L3_MD/Section/MD_Sect_PropPtMass.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `MD_Sect_PropPtMass`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_PropPtMass`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect_PropPtMass`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_PropPtMass.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PtMassAltManager` (lines 47–55)

```fortran
    TYPE, PUBLIC :: PtMassAltManager
        INTEGER(i4) :: numPointMasses = 0_i4
        TYPE(PtMassAltDesc), ALLOCATABLE :: pointMasses(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => PtMassAltManager_Add
        PROCEDURE, PUBLIC :: Find       => PtMassAltManager_Find
        PROCEDURE, PUBLIC :: FindByNode => PtMassAltManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => PtMassAltManager_Clear
    END TYPE PtMassAltManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sect_prop_get_param_value` | 75 | `SUBROUTINE sect_prop_get_param_value(ast_node, param_name, param_value)` |
| FUNCTION | `sect_prop_int_to_str` | 91 | `FUNCTION sect_prop_int_to_str(i) RESULT(str)` |
| SUBROUTINE | `PtMassAltDesc_RegLayout` | 102 | `SUBROUTINE PtMassAltDesc_RegLayout(this)` |
| SUBROUTINE | `PtMassAltDesc_Ensure` | 106 | `SUBROUTINE PtMassAltDesc_Ensure(this)` |
| SUBROUTINE | `PtMassAltDesc_Init_Base` | 111 | `SUBROUTINE PtMassAltDesc_Init_Base(this)` |
| SUBROUTINE | `PtMassAltDesc_Init` | 117 | `SUBROUTINE PtMassAltDesc_Init(this, pointMassId, name, nodeId, mass, status)` |
| FUNCTION | `PtMassAltDesc_Valid_Fn` | 133 | `FUNCTION PtMassAltDesc_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `PtMassAltDesc_Clear` | 142 | `SUBROUTINE PtMassAltDesc_Clear(this)` |
| SUBROUTINE | `PtMassAltManager_Add` | 159 | `SUBROUTINE PtMassAltManager_Add(this, pointMass, status)` |
| FUNCTION | `PtMassAltManager_Find` | 180 | `FUNCTION PtMassAltManager_Find(this, name) RESULT(pointMass)` |
| FUNCTION | `PtMassAltManager_FindByNode` | 195 | `FUNCTION PtMassAltManager_FindByNode(this, nodeId) RESULT(pointMass)` |
| SUBROUTINE | `PtMassAltManager_Clear` | 210 | `SUBROUTINE PtMassAltManager_Clear(this)` |
| SUBROUTINE | `MD_Prop_PointMass_Unified_Configure` | 221 | `SUBROUTINE MD_Prop_PointMass_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Prop_PointMass_Unified_Parse` | 234 | `SUBROUTINE MD_Prop_PointMass_Unified_Parse(prop_type, ast_node, pointMass, context_name, status)` |
| SUBROUTINE | `Parse_POINTMASS_DataLine` | 249 | `SUBROUTINE Parse_POINTMASS_DataLine(data_line, node_id, mass, status)` |
| SUBROUTINE | `Parse_POINTMASS_Keyword` | 272 | `SUBROUTINE Parse_POINTMASS_Keyword(ast_node, pointMass, status)` |
| SUBROUTINE | `Validate_POINTMASS_PhysicalValues` | 306 | `SUBROUTINE Validate_POINTMASS_PhysicalValues(pointMass, status)` |
| SUBROUTINE | `Valid_POINTMASS_Keyword` | 317 | `SUBROUTINE Valid_POINTMASS_Keyword(pointMass, model, status)` |
| SUBROUTINE | `Valid_POINTMASS_Node` | 334 | `SUBROUTINE Valid_POINTMASS_Node(pointMass, model, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
