# `MD_Int_Connector.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Connector.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Connector`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Connector`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Connector`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Connector.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ConnPropsMgr` (lines 93–100)

```fortran
    TYPE, PUBLIC :: ConnPropsMgr
        INTEGER(i4) :: numConnectors = 0_i4
        TYPE(ConnectorProperties), ALLOCATABLE :: connectors(:)
    CONTAINS
        PROCEDURE, PUBLIC :: Add => ConnPropsMgr_Add
        PROCEDURE, PUBLIC :: Find => ConnPropsMgr_Find
        PROCEDURE, PUBLIC :: Clear => ConnPropsMgr_Clear
    END TYPE ConnPropsMgr
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `SpringProperties_Clear` | 122 | `SUBROUTINE SpringProperties_Clear(this)` |
| SUBROUTINE | `SpringProperties_Init` | 132 | `SUBROUTINE SpringProperties_Init(this, name, status)` |
| FUNCTION | `SpringProperties_Valid_Fn` | 149 | `FUNCTION SpringProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `Parse_SPRING_Keyword` | 157 | `SUBROUTINE Parse_SPRING_Keyword(ast_node, spring, name, status)` |
| SUBROUTINE | `MD_Connector_Spring_Unified_Parse` | 178 | `SUBROUTINE MD_Connector_Spring_Unified_Parse(conn_type, ast_node, spring, context_name, status)` |
| SUBROUTINE | `MD_Connector_Spring_Unified_Configure` | 193 | `SUBROUTINE MD_Connector_Spring_Unified_Configure(operation, status)` |
| SUBROUTINE | `JointProperties_Init` | 210 | `SUBROUTINE JointProperties_Init(this, name, status)` |
| FUNCTION | `JointProperties_Valid_Fn` | 226 | `FUNCTION JointProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `JointProperties_Clear` | 235 | `SUBROUTINE JointProperties_Clear(this)` |
| SUBROUTINE | `Parse_JOINT_Keyword` | 244 | `SUBROUTINE Parse_JOINT_Keyword(ast_node, joint, name, status)` |
| SUBROUTINE | `MD_Connector_Joint_Unified_Parse` | 263 | `SUBROUTINE MD_Connector_Joint_Unified_Parse(conn_type, ast_node, joint, context_name, status)` |
| SUBROUTINE | `MD_Connector_Joint_Unified_Configure` | 278 | `SUBROUTINE MD_Connector_Joint_Unified_Configure(operation, status)` |
| SUBROUTINE | `DashProperties_Init` | 295 | `SUBROUTINE DashProperties_Init(this, name, status)` |
| FUNCTION | `DashProperties_Valid_Fn` | 310 | `FUNCTION DashProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `DashProperties_Clear` | 317 | `SUBROUTINE DashProperties_Clear(this)` |
| SUBROUTINE | `Parse_DASHPOT_Keyword` | 325 | `SUBROUTINE Parse_DASHPOT_Keyword(ast_node, dashpot, name, status)` |
| SUBROUTINE | `MD_Connector_Dashpot_Unified_Parse` | 343 | `SUBROUTINE MD_Connector_Dashpot_Unified_Parse(conn_type, ast_node, dashpot, context_name, status)` |
| SUBROUTINE | `MD_Connector_Dashpot_Unified_Configure` | 358 | `SUBROUTINE MD_Connector_Dashpot_Unified_Configure(operation, status)` |
| SUBROUTINE | `BushingProperties_Init` | 375 | `SUBROUTINE BushingProperties_Init(this, name, status)` |
| FUNCTION | `BushingProperties_Valid_Fn` | 390 | `FUNCTION BushingProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `BushingProperties_Clear` | 401 | `SUBROUTINE BushingProperties_Clear(this)` |
| SUBROUTINE | `Parse_BUSHING_Keyword` | 409 | `SUBROUTINE Parse_BUSHING_Keyword(ast_node, bushing, name, status)` |
| SUBROUTINE | `MD_Connector_Bushing_Unified_Parse` | 434 | `SUBROUTINE MD_Connector_Bushing_Unified_Parse(conn_type, ast_node, bushing, context_name, status)` |
| SUBROUTINE | `MD_Connector_Bushing_Unified_Configure` | 449 | `SUBROUTINE MD_Connector_Bushing_Unified_Configure(operation, status)` |
| SUBROUTINE | `ConnectorProperties_Init` | 466 | `SUBROUTINE ConnectorProperties_Init(this, name, status)` |
| FUNCTION | `ConnectorProperties_Valid_Fn` | 482 | `FUNCTION ConnectorProperties_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `ConnectorProperties_Clear` | 489 | `SUBROUTINE ConnectorProperties_Clear(this)` |
| SUBROUTINE | `ConnPropsMgr_Add` | 502 | `SUBROUTINE ConnPropsMgr_Add(this, connector, status)` |
| SUBROUTINE | `ConnPropsMgr_Clear` | 535 | `SUBROUTINE ConnPropsMgr_Clear(this)` |
| FUNCTION | `ConnPropsMgr_Find` | 543 | `FUNCTION ConnPropsMgr_Find(this, name) RESULT(connector)` |
| SUBROUTINE | `Parse_CONNECTOR_Keyword` | 562 | `SUBROUTINE Parse_CONNECTOR_Keyword(ast_node, connector, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
