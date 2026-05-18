# `MD_Mesh_Core.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Mesh_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Core`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mesh_Core_Init` | 42 | `SUBROUTINE MD_Mesh_Core_Init(desc, state, status)` |
| SUBROUTINE | `MD_Mesh_Core_Finalize` | 85 | `SUBROUTINE MD_Mesh_Core_Finalize(desc, state, status)` |
| SUBROUTINE | `MD_Mesh_Set_Nodes` | 123 | `SUBROUTINE MD_Mesh_Set_Nodes(desc, n_nodes, ndim, coords, status)` |
| SUBROUTINE | `MD_Mesh_Set_Connectivity` | 151 | `SUBROUTINE MD_Mesh_Set_Connectivity(desc, n_elements, max_nn, conn, elem_type, status)` |
| SUBROUTINE | `MD_Mesh_Get_Node_Coords` | 183 | `SUBROUTINE MD_Mesh_Get_Node_Coords(desc, node_id, coords_out, status)` |
| SUBROUTINE | `MD_Mesh_Get_Elem_Conn` | 215 | `SUBROUTINE MD_Mesh_Get_Elem_Conn(desc, elem_id, nn, conn_out, status)` |
| SUBROUTINE | `MD_Mesh_Add_NodeSet` | 246 | `SUBROUTINE MD_Mesh_Add_NodeSet(desc, set_id, node_ids, n_nodes, status)` |
| SUBROUTINE | `MD_Mesh_Add_ElemSet` | 283 | `SUBROUTINE MD_Mesh_Add_ElemSet(desc, set_id, elem_ids, n_elems, status)` |
| SUBROUTINE | `MD_Mesh_Validate` | 320 | `SUBROUTINE MD_Mesh_Validate(desc, status)` |
| SUBROUTINE | `MD_Mesh_Build_NodeToElem` | 347 | `SUBROUTINE MD_Mesh_Build_NodeToElem(desc, state, status)` |
| SUBROUTINE | `MD_Mesh_Get_Node_Elems` | 410 | `SUBROUTINE MD_Mesh_Get_Node_Elems(desc, node_id, elem_ids, n_elems, status)` |
| SUBROUTINE | `MD_Mesh_Get_Elem_Neighbors` | 447 | `SUBROUTINE MD_Mesh_Get_Elem_Neighbors(desc, elem_id, nbr_ids, n_nbrs, status)` |
| SUBROUTINE | `MD_Mesh_Count_Orphan_Nodes` | 503 | `SUBROUTINE MD_Mesh_Count_Orphan_Nodes(desc, n_orphans, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
