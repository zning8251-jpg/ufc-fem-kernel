# `MD_Asm_Sync.f90`

- **Source**: `L3_MD/Assembly/MD_Asm_Sync.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Asm_Sync`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Asm_Sync`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Asm`
- **第四段角色（四段式）**: `_Sync`
- **源码子路径（层下目录，不含文件名）**: `Assembly`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Assembly/MD_Asm_Sync.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Assembly_AddInstance_Arg` (lines 41–45)

```fortran
    TYPE, PUBLIC :: MD_Assembly_AddInstance_Arg
      TYPE(UF_InstanceDef)  :: inst          ! [in]  instance to add
      INTEGER(i4)           :: inst_idx = 0_i4 ! [out] assigned 1-based index
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Assembly_AddInstance_Arg
```

### `MD_Asm_GetInstance_Arg` (lines 52–55)

```fortran
    TYPE, PUBLIC :: MD_Asm_GetInstance_Arg
      TYPE(UF_InstanceDef)  :: inst          ! [out] instance descriptor
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Asm_GetInstance_Arg
```

### `MD_Asm_GetSummary_Arg` (lines 62–65)

```fortran
    TYPE, PUBLIC :: MD_Asm_GetSummary_Arg
      CHARACTER(LEN=512)    :: summary = ""  ! [out]
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Asm_GetSummary_Arg
```

### `UF_Constraint` (lines 93–108)

```fortran
    TYPE, PUBLIC :: UF_Constraint
        CHARACTER(LEN=MAX_SET_NAME) :: name = ""
        INTEGER(i4) :: constraint_type = 0
        ! For TIE constraint
        CHARACTER(LEN=MAX_SET_NAME) :: master_surface = ""
        CHARACTER(LEN=MAX_SET_NAME) :: slave_surface = ""
        REAL(wp) :: position_tolerance = 0.0_wp
        ! For MPC constraint
        INTEGER(i4) :: num_terms = 0                    ! n_terms
        INTEGER(i4), ALLOCATABLE :: mpc_nodes(:)
        INTEGER(i4), ALLOCATABLE :: mpc_dofs(:)
        REAL(wp), ALLOCATABLE :: mpc_coeffs(:)          ! Coefficients
        ! L6_AP command payload (optional); not consumed by MD_ConstraintDef mirror
        INTEGER(i4) :: n_properties = 0_i4
        REAL(wp), ALLOCATABLE :: properties(:)
    END TYPE UF_Constraint
```

### `UF_AssemblyDef` (lines 115–160)

```fortran
    TYPE :: UF_AssemblyDef
        CHARACTER(LEN=MAX_ASSEMBLY_NAME) :: name = ""
        
        ! Instances
        INTEGER(i4) :: num_instances = 0                ! n_instances
        TYPE(UF_InstanceDef), ALLOCATABLE :: instances(:)
        
        ! Assembly-level sets (reference instance.set_name)
        INTEGER(i4) :: num_node_sets = 0               ! n_node_sets
        INTEGER(i4) :: num_elem_sets = 0               ! n_elem_sets
        INTEGER(i4) :: num_surfaces = 0                ! n_surfaces
        TYPE(UF_NodeSet), ALLOCATABLE :: node_sets(:)
        TYPE(UF_ElemSet), ALLOCATABLE :: elem_sets(:)
        TYPE(UF_Surface), ALLOCATABLE :: surfaces(:)
        
        ! Constraints (TIE, MPC, etc.)
        INTEGER(i4) :: num_constraints = 0              ! n_constraints
        TYPE(UF_Constraint), ALLOCATABLE :: constraints(:)
        
        ! Global counts (after assembly)
        INTEGER(i4) :: total_nodes = 0                  ! n_nodes
        INTEGER(i4) :: total_elements = 0               ! n_elems
        INTEGER(i4) :: total_dofs = 0                   ! n_dofs
        
        ! Global coordinate arrays (flattened from instances)
        REAL(wp), ALLOCATABLE :: global_coords(:,:)    ! X in R^(3 x n_nodes)
        INTEGER(i4), ALLOCATABLE :: global_conn(:,:)   ! conn in Z^(max_npe x n_elems)
        INTEGER(i4), ALLOCATABLE :: global_elem_type(:)! Element types
        
    CONTAINS
        PROCEDURE :: init => assembly_init
        PROCEDURE :: add_instance => assembly_add_instance
        PROCEDURE :: add_node_set => assembly_add_node_set
        PROCEDURE :: add_elem_set => assembly_add_elem_set
        PROCEDURE :: add_surface => assembly_add_surface
        PROCEDURE :: add_constraint => assembly_add_constraint
        PROCEDURE :: find_instance => assembly_find_instance
        PROCEDURE :: get_instance  => assembly_get_instance
        PROCEDURE :: find_node_set => assembly_find_node_set
        PROCEDURE :: assemble => assembly_assemble
        PROCEDURE :: append_instance_sets => assembly_append_instance_sets
        PROCEDURE :: get_node_coords => assembly_get_node_coords
        PROCEDURE :: release_global_arrays => assembly_release_global_arrays
        PROCEDURE :: clear => assembly_clear
        PROCEDURE :: get_summary => assembly_get_summary
    END TYPE UF_AssemblyDef
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `assembly_init` | 169 | `SUBROUTINE assembly_init(this, name, ierr)` |
| SUBROUTINE | `assembly_add_instance` | 227 | `SUBROUTINE assembly_add_instance(this, inst)` |
| SUBROUTINE | `assembly_add_node_set` | 245 | `SUBROUTINE assembly_add_node_set(this, nset)` |
| SUBROUTINE | `assembly_add_elem_set` | 262 | `SUBROUTINE assembly_add_elem_set(this, eset)` |
| SUBROUTINE | `assembly_add_surface` | 279 | `SUBROUTINE assembly_add_surface(this, surf)` |
| SUBROUTINE | `assembly_add_constraint` | 296 | `SUBROUTINE assembly_add_constraint(this, constr)` |
| FUNCTION | `assembly_find_instance` | 313 | `FUNCTION assembly_find_instance(this, name) RESULT(idx)` |
| FUNCTION | `assembly_get_instance` | 335 | `FUNCTION assembly_get_instance(this, name) RESULT(inst_ptr)` |
| FUNCTION | `assembly_find_node_set` | 353 | `FUNCTION assembly_find_node_set(this, name) RESULT(idx)` |
| SUBROUTINE | `assembly_assemble` | 374 | `SUBROUTINE assembly_assemble(this, parts, num_parts, dof_per_node)` |
| SUBROUTINE | `assembly_append_instance_sets` | 499 | `SUBROUTINE assembly_append_instance_sets(this, inst, part_ptr)` |
| FUNCTION | `assembly_get_node_coords` | 583 | `FUNCTION assembly_get_node_coords(this, global_node_id) RESULT(coords)` |
| SUBROUTINE | `assembly_release_global_arrays` | 601 | `SUBROUTINE assembly_release_global_arrays(this)` |
| SUBROUTINE | `assembly_clear` | 613 | `SUBROUTINE assembly_clear(this)` |
| SUBROUTINE | `assembly_get_summary` | 636 | `SUBROUTINE assembly_get_summary(this, arg)` |
| SUBROUTINE | `MD_Assembly_MirrorUFConstraintToDomain` | 653 | `SUBROUTINE MD_Assembly_MirrorUFConstraintToDomain(md_layer, uf_cst, status)` |
| SUBROUTINE | `MD_Assembly_SyncFromLegacy` | 684 | `SUBROUTINE MD_Assembly_SyncFromLegacy(asm_def, md_layer, status)` |
| SUBROUTINE | `md_asm_setdef_alloc_copy_ids` | 782 | `SUBROUTINE md_asm_setdef_alloc_copy_ids(def, n, src_ids, err_label, status)` |
| SUBROUTINE | `UF_Instance_To_MD_Instance` | 812 | `SUBROUTINE UF_Instance_To_MD_Instance(uf_inst, desc)` |
| SUBROUTINE | `UF_NodeSet_To_MD_SetDef` | 828 | `SUBROUTINE UF_NodeSet_To_MD_SetDef(uf_nset, set_idx, def, status)` |
| SUBROUTINE | `UF_ElemSet_To_MD_SetDef` | 850 | `SUBROUTINE UF_ElemSet_To_MD_SetDef(uf_eset, set_idx, def, status)` |
| SUBROUTINE | `UF_Surface_To_MD_SurfaceDef` | 873 | `SUBROUTINE UF_Surface_To_MD_SurfaceDef(uf_surf, surf_idx, def, status)` |
| SUBROUTINE | `UF_Constraint_To_MD_ConstraintDef` | 915 | `SUBROUTINE UF_Constraint_To_MD_ConstraintDef(uf_cst, cst_idx, def)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
