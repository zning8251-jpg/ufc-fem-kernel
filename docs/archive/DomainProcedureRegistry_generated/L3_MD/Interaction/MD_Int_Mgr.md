# `MD_Int_Mgr.f90`

- **Source**: `L3_MD/Interaction/MD_Int_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_Int_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Int_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Int`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Interaction`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Interaction/MD_Int_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_ContProblem` (lines 146–159)

```fortran
    TYPE, PUBLIC :: UF_ContProblem
        INTEGER(i4) :: contact_dim = 3
        INTEGER(i4) :: n_surfaces = 0
        INTEGER(i4) :: n_pairs = 0
        INTEGER(i4) :: global_enforcem = ENFORCE_PENALTY

        TYPE(ContSurface), ALLOCATABLE :: surfaces(:)
        TYPE(ContPairDef), ALLOCATABLE :: pairs(:)
        TYPE(ContPair), ALLOCATABLE :: active_pairs(:)

        REAL(wp) :: total_contact_f = 0.0_wp
        REAL(wp) :: max_penetration = 0.0_wp
        INTEGER(i4) :: n_active_contac = 0
    END TYPE UF_ContProblem
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Contact_Mgr_FindProperty` | 190 | `SUBROUTINE MD_Contact_Mgr_FindProperty(ctrl, property_name, property, found)` |
| SUBROUTINE | `MD_Contact_Mgr_Init` | 212 | `SUBROUTINE MD_Contact_Mgr_Init(ctrl)` |
| SUBROUTINE | `MD_Contact_Mgr_RegisterPair` | 220 | `SUBROUTINE MD_Contact_Mgr_RegisterPair(ctrl, pair, success, error_msg)` |
| SUBROUTINE | `MD_Contact_Mgr_RegisterProperty` | 291 | `SUBROUTINE MD_Contact_Mgr_RegisterProperty(ctrl, property, success, error_msg)` |
| SUBROUTINE | `MD_Contact_Mgr_ValidateAll` | 351 | `SUBROUTINE MD_Contact_Mgr_ValidateAll(ctrl, is_valid, nErrors)` |
| SUBROUTINE | `contact_set_damping` | 412 | `SUBROUTINE contact_set_damping(pair_id, damping_ratio, mass, ierr)` |
| SUBROUTINE | `contact_update_state` | 454 | `SUBROUTINE contact_update_state(pair_id, ierr)` |
| SUBROUTINE | `co_as_csr_w_damping` | 485 | `SUBROUTINE co_as_csr_w_damping(pair_id, row_ptr, col_idx, values, rhs, &` |
| SUBROUTINE | `contact_get_Stats` | 606 | `SUBROUTINE contact_get_Stats(pair_id, total_force, max_pen, n_active, ierr)` |
| SUBROUTINE | `contact_iteration_init` | 642 | `SUBROUTINE contact_iteration_init(disp, dof_map, ndof, ierr)` |
| SUBROUTINE | `contact_increment_init` | 662 | `SUBROUTINE contact_increment_init(disp, dof_map, ndof, E_ref, ierr)` |
| SUBROUTINE | `contact_setup_dof_mapping` | 690 | `SUBROUTINE contact_setup_dof_mapping(dof_map, ndof, ierr)` |
| SUBROUTINE | `contact_Assem_csr` | 720 | `SUBROUTINE contact_Assem_csr(pair_id, row_ptr, col_idx, values, rhs, ierr)` |
| SUBROUTINE | `contact_set_method` | 786 | `SUBROUTINE contact_set_method(method)` |
| SUBROUTINE | `contact_Mgr_cleanup` | 797 | `SUBROUTINE contact_Mgr_cleanup()` |
| SUBROUTINE | `contact_Mgr_init` | 810 | `SUBROUTINE contact_Mgr_init(dim, n_surfaces, n_pairs, ierr)` |
| SUBROUTINE | `contact_add_surface` | 853 | `SUBROUTINE contact_add_surface(surf_id, node_ids, n_nodes, X, Y, Z, &` |
| SUBROUTINE | `contact_update_geometry` | 908 | `SUBROUTINE contact_update_geometry(disp, dof_map, ndof, ierr)` |
| SUBROUTINE | `contact_global_search` | 929 | `SUBROUTINE contact_global_search(pair_id, ierr, preallocated_se, preallocated_te)` |
| SUBROUTINE | `contact_add_pair` | 964 | `SUBROUTINE contact_add_pair(pair_id, master_surf_id, slave_surf_id, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
