# `MD_Int_Detect.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Detect.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Detect`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Detect`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Detect`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Detect.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `md_cont_aabb_overlap_test` | 59 | `FUNCTION md_cont_aabb_overlap_test(bbox1_min, bbox1_max, bbox2_min, bbox2_max) RESULT(overlap)` |
| SUBROUTINE | `brute_force_search` | 72 | `SUBROUTINE brute_force_search(master_surf, slave_surf, pair, &` |
| SUBROUTINE | `Compute_gap_to_segment_2d` | 142 | `SUBROUTINE Compute_gap_to_segment_2d(surf, seg_id, point, gap, xi_local)` |
| SUBROUTINE | `Compute_segment_bbox` | 187 | `SUBROUTINE Compute_segment_bbox(surf, seg_id, bbox_min, bbox_max, expand)` |
| SUBROUTINE | `Cont_Bucket_grid_init` | 217 | `SUBROUTINE Cont_Bucket_grid_init(grid, surf, n_divisions, search_rad)` |
| SUBROUTINE | `Cont_Bucket_grid_build` | 262 | `SUBROUTINE Cont_Bucket_grid_build(grid, surf, search_rad)` |
| SUBROUTINE | `Cont_Bucket_grid_cleanup` | 323 | `SUBROUTINE Cont_Bucket_grid_cleanup(grid)` |
| SUBROUTINE | `Cont_Bucket_grid_query` | 348 | `SUBROUTINE Cont_Bucket_grid_query(grid, point, seg_ids, n_segs, preallocated_se)` |
| SUBROUTINE | `Cont_Bucket_search` | 448 | `SUBROUTINE Cont_Bucket_search(master_surf, slave_surf, pair, &` |
| SUBROUTINE | `Cont_BVH_build_recursive` | 497 | `RECURSIVE SUBROUTINE Cont_BVH_build_recursive(tree, surf, seg_indices, centroids, &` |
| SUBROUTINE | `Cont_BVH_query_recursive` | 568 | `RECURSIVE SUBROUTINE Cont_BVH_query_recursive(tree, node_id, point, search_rad, &` |
| SUBROUTINE | `Cont_BVH_tree_build` | 603 | `SUBROUTINE Cont_BVH_tree_build(tree, surf, search_rad)` |
| SUBROUTINE | `Cont_BVH_tree_cleanup` | 640 | `SUBROUTINE Cont_BVH_tree_cleanup(tree)` |
| SUBROUTINE | `Cont_BVH_tree_query` | 651 | `SUBROUTINE Cont_BVH_tree_query(tree, point, search_rad, seg_ids, n_segs)` |
| SUBROUTINE | `md_cont_get_bucket_range` | 685 | `SUBROUTINE md_cont_get_bucket_range(grid, bbox_min, bbox_max, &` |
| SUBROUTINE | `md_cont_partition_segments` | 705 | `SUBROUTINE md_cont_partition_segments(seg_indices, centroids, start_idx, end_idx, &` |
| SUBROUTINE | `resize_candidates` | 741 | `SUBROUTINE resize_candidates(candidates, n_candidates)` |
| SUBROUTINE | `store_contact_results` | 757 | `SUBROUTINE store_contact_results(cpair, n_contact, temp_nodes, temp_master, &` |
| SUBROUTINE | `contact_detect` | 803 | `SUBROUTINE contact_detect(cpair, slave_coords, slave_nodes, n_slave, &` |
| SUBROUTINE | `contact_detect_2d` | 832 | `SUBROUTINE contact_detect_2d(cpair, slave_coords, slave_nodes, n_slave, &` |
| SUBROUTINE | `contact_detect_3d` | 912 | `SUBROUTINE contact_detect_3d(cpair, slave_coords, slave_nodes, n_slave, &` |
| SUBROUTINE | `Co_Se_fi_candidates` | 991 | `SUBROUTINE Co_Se_fi_candidates(master_surf, slave_surf, pair, &` |
| SUBROUTINE | `Cont_Search_global_init` | 1027 | `SUBROUTINE Cont_Search_global_init(master_surf, slave_surf, pair, search_tol)` |
| SUBROUTINE | `Cont_Search_local_update` | 1048 | `SUBROUTINE Cont_Search_local_update(cpair, master_surf, slave_surf, disp, dof_map, ndof)` |
| SUBROUTINE | `Co_Se_up_tracking` | 1065 | `SUBROUTINE Co_Se_up_tracking(master_surf, node, pair)` |
| SUBROUTINE | `project_point_to_segment_2d` | 1104 | `SUBROUTINE project_point_to_segment_2d(slave_pt, master_coords, master_element, &` |
| SUBROUTINE | `project_point_to_quad_3d` | 1156 | `SUBROUTINE project_point_to_quad_3d(slave_pt, master_coords, master_element, &` |
| SUBROUTINE | `compute_bbox_internal_local` | 1188 | `SUBROUTINE compute_bbox_internal_local(surf, tolerance)` |
| SUBROUTINE | `update_coords_local` | 1214 | `SUBROUTINE update_coords_local(surf, disp, dof_map, ndof)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 44–46 | `INTERFACE Cont_Search_find_candidates` |
| 49–51 | `INTERFACE Cont_Search_update_tracking` |
