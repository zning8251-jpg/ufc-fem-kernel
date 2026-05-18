# `MD_Int_Convert.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Convert.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Convert`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Convert`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Convert`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Convert.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cont_UpdateGeometry` | 93 | `SUBROUTINE Cont_UpdateGeometry(contact_node, displacements, gap, &` |
| SUBROUTINE | `Cont_UpdateGeometry_Simple` | 113 | `SUBROUTINE Cont_UpdateGeometry_Simple(contact_node, displacements, gap, n_vector)` |
| SUBROUTINE | `Cont_ComputeRelativeVelocity` | 126 | `SUBROUTINE Cont_ComputeRelativeVelocity(contact_node, velocities, relative_veloci)` |
| SUBROUTINE | `Cont_ProjectToSurface` | 135 | `SUBROUTINE Cont_ProjectToSurface(surface_id, point, projection, normal)` |
| SUBROUTINE | `Cont_ComputeTangents` | 143 | `SUBROUTINE Cont_ComputeTangents(normal, tangent1, tangent2)` |
| SUBROUTINE | `Co_Ge_Co_gap_2d` | 155 | `SUBROUTINE Co_Ge_Co_gap_2d(P_slave, P_A, P_B, gap, penetration, &` |
| SUBROUTINE | `Co_Ge_Co_gap_3d` | 170 | `SUBROUTINE Co_Ge_Co_gap_3d(P_slave, P_nodes, gap, penetration, &` |
| FUNCTION | `Cont_Geometry_Compute_jacobian_2d` | 185 | `FUNCTION Cont_Geometry_Compute_jacobian_2d(P_A, P_B) RESULT(jacobian)` |
| FUNCTION | `Cont_Geometry_Compute_jacobian_3d` | 192 | `FUNCTION Cont_Geometry_Compute_jacobian_3d(P_nodes, xi, eta) RESULT(jacobian)` |
| SUBROUTINE | `Co_Ge_Co_no_2d` | 209 | `SUBROUTINE Co_Ge_Co_no_2d(tangent, normal)` |
| SUBROUTINE | `Co_Ge_Co_no_3d` | 215 | `SUBROUTINE Co_Ge_Co_no_3d(P_nodes, xi, eta, normal)` |
| SUBROUTINE | `Co_Ge_Co_ta_2d` | 238 | `SUBROUTINE Co_Ge_Co_ta_2d(P_A, P_B, tangent, length)` |
| SUBROUTINE | `Co_Ge_Co_ta_3d` | 251 | `SUBROUTINE Co_Ge_Co_ta_3d(P_nodes, xi, eta, t1, t2)` |
| SUBROUTINE | `Co_Ge_ne_pr_3d` | 267 | `SUBROUTINE Co_Ge_ne_pr_3d(P_slave, P_nodes, n_nodes, xi, eta, P_proj, converged)` |
| SUBROUTINE | `Co_Ge_pr_po_2d` | 300 | `SUBROUTINE Co_Ge_pr_po_2d(P_slave, P_A, P_B, xi, P_proj, valid)` |
| SUBROUTINE | `Co_Ge_pr_po_3d` | 319 | `SUBROUTINE Co_Ge_pr_po_3d(P_slave, P_nodes, xi, eta, P_proj, valid, ierr)` |
| SUBROUTINE | `Co_Ge_sh_fu_2d` | 358 | `SUBROUTINE Co_Ge_sh_fu_2d(xi, N, dN)` |
| SUBROUTINE | `Co_Ge_sh_fu_3d` | 366 | `SUBROUTINE Co_Ge_sh_fu_3d(xi, eta, N, dNdxi, dNdeta)` |
| SUBROUTINE | `Co_Ge_up_co_point` | 384 | `SUBROUTINE Co_Ge_up_co_point(node, master_surf, seg_id, xi, eta)` |
| SUBROUTINE | `project_point_to_quad_3d` | 406 | `SUBROUTINE project_point_to_quad_3d(slave_pt, master_coords, master_element, &` |
| SUBROUTINE | `project_point_to_segment_2d` | 421 | `SUBROUTINE project_point_to_segment_2d(slave_pt, master_coords, master_element, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 31–33 | `INTERFACE Cont_Geometry_project_point_2d` |
| 36–38 | `INTERFACE Cont_Geometry_project_point_3d` |
| 41–43 | `INTERFACE Cont_Geometry_Compute_gap_2d` |
| 46–48 | `INTERFACE Cont_Geometry_Compute_gap_3d` |
| 51–53 | `INTERFACE Cont_Geometry_Compute_normal_2d` |
| 56–58 | `INTERFACE Cont_Geometry_Compute_normal_3d` |
| 61–63 | `INTERFACE Cont_Geometry_Compute_tangent_2d` |
| 66–68 | `INTERFACE Cont_Geometry_Compute_tangent_3d` |
| 71–73 | `INTERFACE Cont_Geometry_shape_functions_2d` |
| 76–78 | `INTERFACE Cont_Geometry_shape_functions_3d` |
| 81–83 | `INTERFACE Cont_Geometry_newton_projection_3d` |
| 86–88 | `INTERFACE Cont_Geometry_update_contact_point` |
