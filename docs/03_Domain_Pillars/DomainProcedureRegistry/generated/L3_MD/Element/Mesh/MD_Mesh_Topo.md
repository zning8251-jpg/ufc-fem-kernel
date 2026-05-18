# `MD_Mesh_Topo.f90`

- **Source**: `L3_MD/Element/Mesh/MD_Mesh_Topo.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Mesh_Topo`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Mesh_Topo`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Mesh_Topo`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_Mesh_Topo.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Mesh_Topo_Build_Faces` | 32 | `SUBROUTINE MD_Mesh_Topo_Build_Faces(desc, state, status)` |
| SUBROUTINE | `MD_Mesh_Topo_Find_Boundary_Faces` | 76 | `SUBROUTINE MD_Mesh_Topo_Find_Boundary_Faces(desc, state, status)` |
| SUBROUTINE | `MD_Mesh_Topo_Validate_Connectivity` | 113 | `SUBROUTINE MD_Mesh_Topo_Validate_Connectivity(desc, n_degenerate, status)` |
| SUBROUTINE | `MD_Mesh_Topo_Get_Elem_Faces` | 159 | `SUBROUTINE MD_Mesh_Topo_Get_Elem_Faces(desc, elem_id, face_ids, n_faces, status)` |
| SUBROUTINE | `append_face` | 197 | `SUBROUTINE append_face(desc, elem_id, local_id, nodes, nn)` |
| SUBROUTINE | `add_hex_faces` | 225 | `SUBROUTINE add_hex_faces(desc, ie, fid_out)` |
| SUBROUTINE | `add_tet_faces` | 258 | `SUBROUTINE add_tet_faces(desc, ie, fid_out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
