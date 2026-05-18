# `MD_Sect_PropRotInertia.f90`

- **Source**: `L3_MD/Section/MD_Sect_PropRotInertia.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Sect_PropRotInertia`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Sect_PropRotInertia`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Sect_PropRotInertia`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Section`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Section/MD_Sect_PropRotInertia.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RotInertiaManager` (lines 58–66)

```fortran
    TYPE, PUBLIC :: RotInertiaManager
        INTEGER(i4) :: numInertias = 0_i4
        TYPE(RotInertiaDesc), ALLOCATABLE :: inertias(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add        => RotInertiaManager_Add
        PROCEDURE, PUBLIC :: Find       => RotInertiaManager_Find
        PROCEDURE, PUBLIC :: FindByNode => RotInertiaManager_FindByNode
        PROCEDURE, PUBLIC :: Clear      => RotInertiaManager_Clear
    END TYPE RotInertiaManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sect_prop_get_param_value` | 87 | `SUBROUTINE sect_prop_get_param_value(ast_node, param_name, param_value)` |
| SUBROUTINE | `RotInertiaDesc_RegLayout` | 108 | `SUBROUTINE RotInertiaDesc_RegLayout(this)` |
| SUBROUTINE | `RotInertiaDesc_Ensure` | 112 | `SUBROUTINE RotInertiaDesc_Ensure(this)` |
| SUBROUTINE | `RotInertiaDesc_Init_Base` | 117 | `SUBROUTINE RotInertiaDesc_Init_Base(this)` |
| SUBROUTINE | `RotInertiaDesc_Init` | 123 | `SUBROUTINE RotInertiaDesc_Init(this, inertiaId, name, nodeId, Ixx, Iyy, Izz, &` |
| FUNCTION | `RotInertiaDesc_Valid_Fn` | 144 | `FUNCTION RotInertiaDesc_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `RotInertiaDesc_Clear` | 154 | `SUBROUTINE RotInertiaDesc_Clear(this)` |
| SUBROUTINE | `RotInertiaDesc_GetInertiaMatrix` | 170 | `SUBROUTINE RotInertiaDesc_GetInertiaMatrix(this, I_matrix)` |
| FUNCTION | `RotInertiaDesc_IsPositiveDefinite` | 181 | `FUNCTION RotInertiaDesc_IsPositiveDefinite(this) RESULT(is_pd)` |
| SUBROUTINE | `RotInertiaManager_Add` | 206 | `SUBROUTINE RotInertiaManager_Add(this, rotaryInertia, status)` |
| FUNCTION | `RotInertiaManager_Find` | 227 | `FUNCTION RotInertiaManager_Find(this, name) RESULT(rotaryInertia)` |
| FUNCTION | `RotInertiaManager_FindByNode` | 242 | `FUNCTION RotInertiaManager_FindByNode(this, nodeId) RESULT(rotaryInertia)` |
| SUBROUTINE | `RotInertiaManager_Clear` | 257 | `SUBROUTINE RotInertiaManager_Clear(this)` |
| SUBROUTINE | `MD_Prop_RotaryInertia_Unified_Configure` | 268 | `SUBROUTINE MD_Prop_RotaryInertia_Unified_Configure(operation, status)` |
| SUBROUTINE | `MD_Prop_RotaryInertia_Unified_Parse` | 281 | `SUBROUTINE MD_Prop_RotaryInertia_Unified_Parse(prop_type, ast_node, rotaryInertia, context_name, status)` |
| SUBROUTINE | `Parse_ROTARYINERTIA_DataLine` | 296 | `SUBROUTINE Parse_ROTARYINERTIA_DataLine(data_line, I11, I22, I33, I12, I13, I23, status)` |
| SUBROUTINE | `Parse_ROTARYINERTIA_Keyword` | 316 | `SUBROUTINE Parse_ROTARYINERTIA_Keyword(ast_node, rotaryInertia, status)` |
| SUBROUTINE | `Validate_ROTARYINERTIA_Orientation` | 373 | `SUBROUTINE Validate_ROTARYINERTIA_Orientation(rotaryInertia, model, status)` |
| SUBROUTINE | `Validate_ROTARYINERTIA_PhysicalValues` | 381 | `SUBROUTINE Validate_ROTARYINERTIA_PhysicalValues(rotaryInertia, status)` |
| SUBROUTINE | `Valid_ROTARYINERTIA_Keyword` | 404 | `SUBROUTINE Valid_ROTARYINERTIA_Keyword(rotaryInertia, model, status)` |
| SUBROUTINE | `Valid_ROTARYINERTIA_Target` | 427 | `SUBROUTINE Valid_ROTARYINERTIA_Target(rotaryInertia, model, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
