# `MD_Int_Stiffness.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Stiffness.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Int_Stiffness`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Stiffness`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int_Stiffness`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Stiffness.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

*(no TYPE definition blocks detected)*

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Cont_AsmPenaltyStiff` | 69 | `SUBROUTINE Cont_AsmPenaltyStiff(contact_node, penalty_normal, penalty_tangent, &` |
| SUBROUTINE | `md_cont_add_stif_contact_to_csr` | 91 | `SUBROUTINE md_cont_add_stif_contact_to_csr(K_local, F_local, dof_ids, n_local, &` |
| SUBROUTINE | `md_cont_assemble_stif_csr` | 127 | `SUBROUTINE md_cont_assemble_stif_csr(K_local, dof_indices, row_ptr, col_idx, values)` |
| FUNCTION | `md_cont_csr_find_position` | 146 | `FUNCTION md_cont_csr_find_position(row, col, row_ptr, col_idx) RESULT(pos)` |
| SUBROUTINE | `alm_stif_csr` | 159 | `SUBROUTINE alm_stif_csr(dim, n_contact_point, contact_nodes, &` |
| SUBROUTINE | `alm_stif_csr_from_nodes` | 215 | `SUBROUTINE alm_stif_csr_from_nodes(dim, contact_nodes, n_contact_point, &` |
| SUBROUTINE | `penalty_stif_csr` | 272 | `SUBROUTINE penalty_stif_csr(dim, n_contact_point, contact_nodes, &` |
| SUBROUTINE | `contact_stif_pattern_csr` | 324 | `SUBROUTINE contact_stif_pattern_csr(slave_surf, master_surf, dim, &` |
| SUBROUTINE | `Co_Co_st_fo_vector` | 404 | `SUBROUTINE Co_Co_st_fo_vector(penalty_n, normal, penetration, force)` |
| SUBROUTINE | `Co_Co_st_lo_2d` | 414 | `SUBROUTINE Co_Co_st_lo_2d(penalty_n, penalty_t, normal, tangent, &` |
| SUBROUTINE | `Co_Co_st_lo_3d` | 429 | `SUBROUTINE Co_Co_st_lo_3d(penalty_n, penalty_t, normal, tangent1, tangent2, &` |
| SUBROUTINE | `contact_add_contact_k` | 445 | `SUBROUTINE contact_add_contact_k(eqRow, eqCol, penalty, scale, nrm, triplets)` |
| SUBROUTINE | `contact_add_force` | 462 | `SUBROUTINE contact_add_force(eq, f, R)` |
| SUBROUTINE | `contact_add_contact_k_Arg` | 474 | `SUBROUTINE contact_add_contact_k_Arg(triplets, arg)` |
| SUBROUTINE | `contact_add_force_Arg` | 481 | `SUBROUTINE contact_add_force_Arg(R, arg)` |
| SUBROUTINE | `co_As_co_pair` | 487 | `SUBROUTINE co_As_co_pair(slaveNodeId, masterNodeIds, nMaster, nrm, gap, penalty, w, dofMap, triplets, R)` |
| SUBROUTINE | `co_as_su_to_su_penalty` | 533 | `SUBROUTINE co_as_su_to_su_penalty(part, masterSurfId, slaveSurfId, &` |
| SUBROUTINE | `co_as_su_to_su_pe_cross` | 587 | `SUBROUTINE co_as_su_to_su_pe_cross(partMaster, partSlave, masterSurfId, slaveSurfId, &` |
| SUBROUTINE | `contact_Assemble_triplets` | 644 | `SUBROUTINE contact_Assemble_triplets(model, dofMap, nodeStates, triplets, R, ierr)` |
| SUBROUTINE | `contact_Assemble_triplets_Arg` | 681 | `SUBROUTINE contact_Assemble_triplets_Arg(arg, nodeStates, triplets, R, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 37–39 | `INTERFACE Cont_Compute_stif_local_2d` |
| 42–44 | `INTERFACE Cont_Compute_stif_local_3d` |
| 47–49 | `INTERFACE Cont_Compute_stif_force_vector` |
| 52–54 | `INTERFACE contact_Assemble_contact_pair` |
| 57–59 | `INTERFACE contact_assemble_surface_to_surface_penalty` |
| 62–64 | `INTERFACE contact_assemble_surface_to_surface_penalty_cross` |
