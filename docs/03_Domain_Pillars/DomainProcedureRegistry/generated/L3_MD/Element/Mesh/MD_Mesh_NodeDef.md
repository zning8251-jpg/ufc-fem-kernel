# `MD_Mesh_NodeDef.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_NodeDef.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mesh_NodeDef`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_NodeDef`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_NodeDef`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_NodeDef.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Node_Init` | 161 | `SUBROUTINE Node_Init(this, id, coords, name, status)` |
| SUBROUTINE | `Node_Clean` | 202 | `SUBROUTINE Node_Clean(this)` |
| SUBROUTINE | `Node_GetCoords` | 216 | `SUBROUTINE Node_GetCoords(this, coords, status)` |
| SUBROUTINE | `Node_SetCoords` | 229 | `SUBROUTINE Node_SetCoords(this, coords, status)` |
| SUBROUTINE | `Node_GetDOF` | 246 | `SUBROUTINE Node_GetDOF(this, nDof, dof_map, dof_offset, status)` |
| SUBROUTINE | `Node_SetDOF` | 263 | `SUBROUTINE Node_SetDOF(this, nDof, dof_map, dof_offset, status)` |
| SUBROUTINE | `Node_Transform` | 292 | `SUBROUTINE Node_Transform(this, translation, rotation_matrix, scale, status)` |
| SUBROUTINE | `Node_AddElement` | 335 | `SUBROUTINE Node_AddElement(this, element_id, status)` |
| SUBROUTINE | `Node_RemoveElement` | 372 | `SUBROUTINE Node_RemoveElement(this, element_id, status)` |
| SUBROUTINE | `Node_AddTag` | 417 | `SUBROUTINE Node_AddTag(this, tag, status)` |
| FUNCTION | `Node_Valid_Fn` | 477 | `FUNCTION Node_Valid_Fn(this) RESULT(ok)` |
| SUBROUTINE | `Node_GetStatistics` | 486 | `SUBROUTINE Node_GetStatistics(this, stats, status)` |
| SUBROUTINE | `MD_Node_Create` | 508 | `SUBROUTINE MD_Node_Create(node, id, coords, name, status)` |
| SUBROUTINE | `MD_Node_Destroy` | 519 | `SUBROUTINE MD_Node_Destroy(node, status)` |
| SUBROUTINE | `MD_Node_SetCoords` | 531 | `SUBROUTINE MD_Node_SetCoords(node, coords, status)` |
| SUBROUTINE | `MD_Node_GetCoords` | 540 | `SUBROUTINE MD_Node_GetCoords(node, coords, status)` |
| SUBROUTINE | `MD_Node_SetDOF` | 549 | `SUBROUTINE MD_Node_SetDOF(node, nDof, dof_map, dof_offset, status)` |
| SUBROUTINE | `MD_Node_GetDOF` | 560 | `SUBROUTINE MD_Node_GetDOF(node, nDof, dof_map, dof_offset, status)` |
| SUBROUTINE | `MD_Node_Transform` | 571 | `SUBROUTINE MD_Node_Transform(node, translation, rotation_matrix, scale, status)` |
| SUBROUTINE | `MD_Node_GetStatistics` | 590 | `SUBROUTINE MD_Node_GetStatistics(node, stats, status)` |
| SUBROUTINE | `MD_Node_Valid` | 599 | `SUBROUTINE MD_Node_Valid(node, status)` |
| SUBROUTINE | `NodeState_Init` | 615 | `SUBROUTINE NodeState_Init(this, node_id, status)` |
| SUBROUTINE | `NodeState_Clean` | 643 | `SUBROUTINE NodeState_Clean(this)` |
| SUBROUTINE | `NodeState_Update` | 652 | `SUBROUTINE NodeState_Update(this, dt, status)` |
| SUBROUTINE | `NodeState_GetDisplacement` | 678 | `SUBROUTINE NodeState_GetDisplacement(this, displacement, status)` |
| SUBROUTINE | `NodeState_SetDisplacement` | 691 | `SUBROUTINE NodeState_SetDisplacement(this, displacement, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
