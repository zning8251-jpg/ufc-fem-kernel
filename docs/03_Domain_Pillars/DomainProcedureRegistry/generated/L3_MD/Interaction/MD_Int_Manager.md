# `MD_Int_Manager.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Manager.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Manager`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Manager`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Manager`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Manager.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cont_Surface_init` | 111 | `SUBROUTINE Cont_Surface_init(surf, id, n_nodes, n_segs, is_master, coord_type)` |
| SUBROUTINE | `Cont_Surface_add_nodes` | 150 | `SUBROUTINE Cont_Surface_add_nodes(surf, global_node_ids, X, Y, Z, n_nodes)` |
| SUBROUTINE | `Co_Su_bu_se_2d` | 179 | `SUBROUTINE Co_Su_bu_se_2d(surf)` |
| SUBROUTINE | `Co_Su_bu_se_3d` | 201 | `SUBROUTINE Co_Su_bu_se_3d(surf, conn, n_segs)` |
| SUBROUTINE | `Co_Su_up_coords` | 219 | `SUBROUTINE Co_Su_up_coords(surf, disp, dof_map, ndof)` |
| SUBROUTINE | `Co_Su_Co_no_2d` | 249 | `SUBROUTINE Co_Su_Co_no_2d(surf)` |
| SUBROUTINE | `Co_Su_Co_no_3d` | 286 | `SUBROUTINE Co_Su_Co_no_3d(surf)` |
| SUBROUTINE | `Cont_Surface_Compute_bbox` | 337 | `SUBROUTINE Cont_Surface_Compute_bbox(surf, tolerance)` |
| SUBROUTINE | `Co_Su_Co_bb_internal` | 367 | `SUBROUTINE Co_Su_Co_bb_internal(surf, tolerance)` |
| SUBROUTINE | `Co_Su_bu_topology` | 393 | `SUBROUTINE Co_Su_bu_topology(surf, max_seg_per_nod)` |
| SUBROUTINE | `Cont_Surface_Valid` | 427 | `SUBROUTINE Cont_Surface_Valid(surf, ierr, error_msg)` |
| SUBROUTINE | `contact_init` | 471 | `SUBROUTINE contact_init(cpair, master_id, slave_id, contact_type, dimension, tol, search_tol)` |
| SUBROUTINE | `contact_init_Arg` | 517 | `SUBROUTINE contact_init_Arg(cpair, arg)` |
| SUBROUTINE | `contact_init_from_pair` | 534 | `SUBROUTINE contact_init_from_pair(cpair, pair_def)` |
| SUBROUTINE | `contact_update_geometry` | 552 | `SUBROUTINE contact_update_geometry(cpair, master_surf, slave_surf, disp, dof_map, ndof)` |
| SUBROUTINE | `contact_update_geometry_Arg` | 567 | `SUBROUTINE contact_update_geometry_Arg(cpair, master_surf, slave_surf, disp, dof_map, arg)` |
| SUBROUTINE | `co_de_gl_su_id` | 586 | `SUBROUTINE co_de_gl_su_id(model, globalId, partIndex, localSurfId)` |
| SUBROUTINE | `co_co_su_nodes` | 621 | `SUBROUTINE co_co_su_nodes(part, surfId, nodeIds, nUnique)` |
| SUBROUTINE | `co_co_fa_no_area` | 664 | `SUBROUTINE co_co_fa_no_area(coords, nNode, nrm, area)` |
| SUBROUTINE | `contact_Eval_face_gap` | 704 | `SUBROUTINE contact_Eval_face_gap(part, nodeStates, elemId, faceId, xSlave, bestGap, bestElemId, bestFaceId, bestNrm, bestX0)` |
| SUBROUTINE | `contact_Eval_face_gap_Arg` | 750 | `SUBROUTINE contact_Eval_face_gap_Arg(part, nodeStates, arg)` |
| SUBROUTINE | `uinter_call` | 763 | `SUBROUTINE uinter_call(node, pair, props, nprops, statev, nstatev, &` |
| SUBROUTINE | `ucontprop_call` | 840 | `SUBROUTINE ucontprop_call(cpen, cdamp, props, nprops, temp, press, &` |
| SUBROUTINE | `user_contact_init` | 872 | `SUBROUTINE user_contact_init()` |
| SUBROUTINE | `user_contact_Reg` | 882 | `SUBROUTINE user_contact_Reg(sub_type, active)` |
| SUBROUTINE | `fric_call` | 897 | `SUBROUTINE fric_call(mu, ddmudp, ddmudv, press, slip, temp, &` |
| SUBROUTINE | `vfric_call` | 926 | `SUBROUTINE vfric_call(mu, ddmudp, ddmudv, press, slip, sliprate, temp, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 51–53 | `INTERFACE Cont_Surface_build_segments_2d` |
| 56–58 | `INTERFACE Cont_Surface_build_segments_3d` |
| 61–63 | `INTERFACE Cont_Surface_update_coords` |
| 66–68 | `INTERFACE Cont_Surface_Compute_normals_2d` |
| 71–73 | `INTERFACE Cont_Surface_Compute_normals_3d` |
| 76–78 | `INTERFACE Cont_Surface_Compute_bbox_internal` |
| 81–83 | `INTERFACE Cont_Surface_build_topology` |
| 86–88 | `INTERFACE contact_decode_global_surf_id` |
| 91–93 | `INTERFACE contact_collect_surface_nodes` |
| 96–98 | `INTERFACE contact_compute_face_normal_area` |
| 101–103 | `INTERFACE contact_Evaluate_face_gap` |
