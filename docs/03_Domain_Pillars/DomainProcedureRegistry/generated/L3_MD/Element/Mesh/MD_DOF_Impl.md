# `MD_DOF_Impl.f90`

- **Source**: `L3_MD/Element/Mesh/MD_DOF_Impl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_DOF_Impl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_DOF_Impl`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_DOF_Impl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Mesh`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Element/Mesh/MD_DOF_Impl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_NodalDOF` (lines 39–53)

```fortran
    TYPE, PUBLIC :: UF_NodalDOF
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: num_dof = 0
        INTEGER(i4) :: dof_status(MD_MESH_MAX_DOF_PER_NODE) = MD_MESH_DOF_INACTIVE
        INTEGER(i4) :: eqn_number(MD_MESH_MAX_DOF_PER_NODE) = 0   ! Global equation number
        REAL(wp) :: prescribed_value(MD_MESH_MAX_DOF_PER_NODE) = 0.0_wp
        REAL(wp) :: reaction(MD_MESH_MAX_DOF_PER_NODE) = 0.0_wp
    CONTAINS
        PROCEDURE :: init => ndof_init
        PROCEDURE :: activate => ndof_activate
        PROCEDURE :: fix => ndof_fix
        PROCEDURE :: prescribe => ndof_prescribe
        PROCEDURE :: get_eqn => ndof_get_eqn
        PROCEDURE :: is_free => ndof_is_free
    END TYPE UF_NodalDOF
```

### `UF_DOFManagerType` (lines 58–84)

```fortran
    TYPE, PUBLIC :: UF_DOFManagerType
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_total_dof = 0
        INTEGER(i4) :: num_free_dof = 0
        INTEGER(i4) :: num_fixed_dof = 0
        INTEGER(i4) :: num_prescribed_dof = 0
        TYPE(UF_NodalDOF), ALLOCATABLE :: nodal_dofs(:)
        ! Mapping arrays
        INTEGER(i4), ALLOCATABLE :: dof_to_node(:)   ! eqn -> node
        INTEGER(i4), ALLOCATABLE :: dof_to_local(:)  ! eqn -> local dof
        ! Solution vectors (references)
        REAL(wp), ALLOCATABLE :: displacement(:)
        REAL(wp), ALLOCATABLE :: velocity(:)
        REAL(wp), ALLOCATABLE :: acceleration(:)
    CONTAINS
        PROCEDURE :: init => dofmgr_init
        PROCEDURE :: activate_dofs => dofmgr_activate_dofs
        PROCEDURE :: fix_dof => dofmgr_fix_dof
        PROCEDURE :: prescribe_dof => dofmgr_prescribe_dof
        PROCEDURE :: number_equations => dofmgr_number_eqns
        PROCEDURE :: get_nodal_dof => dofmgr_get_nodal
        PROCEDURE :: get_element_dofs => dofmgr_get_elem_dofs
        PROCEDURE :: assemble_vector => dofmgr_assemble_vec
        PROCEDURE :: scatter_solution => dofmgr_scatter
        PROCEDURE :: print_summary => dofmgr_print_summary
        PROCEDURE :: destroy => dofmgr_destroy
    END TYPE UF_DOFManagerType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ndof_init` | 91 | `SUBROUTINE ndof_init(this, node_id, ndof)` |
| SUBROUTINE | `ndof_activate` | 102 | `SUBROUTINE ndof_activate(this, dof)` |
| SUBROUTINE | `ndof_fix` | 113 | `SUBROUTINE ndof_fix(this, dof)` |
| SUBROUTINE | `ndof_prescribe` | 122 | `SUBROUTINE ndof_prescribe(this, dof, value)` |
| FUNCTION | `ndof_get_eqn` | 132 | `FUNCTION ndof_get_eqn(this, dof) RESULT(eqn)` |
| FUNCTION | `ndof_is_free` | 140 | `FUNCTION ndof_is_free(this, dof) RESULT(is_free)` |
| SUBROUTINE | `dofmgr_init` | 153 | `SUBROUTINE dofmgr_init(this, nnodes, dof_per_node)` |
| SUBROUTINE | `dofmgr_activate_dofs` | 164 | `SUBROUTINE dofmgr_activate_dofs(this, node_ids, dofs)` |
| SUBROUTINE | `dofmgr_fix_dof` | 178 | `SUBROUTINE dofmgr_fix_dof(this, node_id, dof)` |
| SUBROUTINE | `dofmgr_prescribe_dof` | 186 | `SUBROUTINE dofmgr_prescribe_dof(this, node_id, dof, value)` |
| SUBROUTINE | `dofmgr_number_eqns` | 195 | `SUBROUTINE dofmgr_number_eqns(this)` |
| FUNCTION | `dofmgr_get_nodal` | 258 | `FUNCTION dofmgr_get_nodal(this, node_id) RESULT(ptr)` |
| SUBROUTINE | `dofmgr_get_elem_dofs` | 268 | `SUBROUTINE dofmgr_get_elem_dofs(this, node_ids, elem_dofs, ndof)` |
| SUBROUTINE | `dofmgr_assemble_vec` | 288 | `SUBROUTINE dofmgr_assemble_vec(this, elem_dofs, elem_vec, global_vec)` |
| SUBROUTINE | `dofmgr_scatter` | 302 | `SUBROUTINE dofmgr_scatter(this, solution)` |
| SUBROUTINE | `dofmgr_print_summary` | 308 | `SUBROUTINE dofmgr_print_summary(this, unit_num)` |
| SUBROUTINE | `dofmgr_destroy` | 319 | `SUBROUTINE dofmgr_destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
