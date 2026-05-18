# `MD_Field_Mgr.f90`

- **Source**: `L3_MD/Field/MD_Field_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Field_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Field_Mgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Field`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Field`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Field/MD_Field_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_NodeDisp` (lines 65–68)

```fortran
    TYPE, PUBLIC :: MD_NodeDisp
        INTEGER(i4) :: id = 0_i4
        REAL(wp)    :: u_curr(3) = 0.0_wp
    END TYPE MD_NodeDisp
```

### `MD_NodalField` (lines 73–89)

```fortran
    TYPE, PUBLIC :: MD_NodalField
        CHARACTER(LEN=MD_FLD_MAX_NAME_LEN) :: name = ""
        INTEGER(i4) :: field_type = MD_FLD_DISPLACEMENT
        INTEGER(i4) :: num_components = 3
        INTEGER(i4) :: num_nodes = 0
        REAL(wp), ALLOCATABLE :: values(:,:)        ! (ncomp, nnodes)
        REAL(wp), ALLOCATABLE :: old_values(:,:)    ! Previous increment
        REAL(wp), ALLOCATABLE :: increment(:,:)     ! Delta values
    CONTAINS
        PROCEDURE :: init => nodal_init
        PROCEDURE :: set_value => nodal_set_value
        PROCEDURE :: get_value => nodal_get_value
        PROCEDURE :: update => nodal_update
        PROCEDURE :: store_old => nodal_store_old
        PROCEDURE :: restore => nodal_restore
        PROCEDURE :: destroy => nodal_destroy
    END TYPE MD_NodalField
```

### `MD_ElemIPData` (lines 94–112)

```fortran
    TYPE, PUBLIC :: MD_ElemIPData
        INTEGER(i4) :: elem_id = 0
        INTEGER(i4) :: num_int_points = 0
        INTEGER(i4) :: num_sdv = 0
        
        ! Element-level variables (SoA)
        REAL(wp), ALLOCATABLE :: sdv(:,:)        ! (nsdv, nip)
        REAL(wp), ALLOCATABLE :: sdv_old(:,:)    ! (nsdv, nip)
        
        REAL(wp), ALLOCATABLE :: stress(:,:)     ! (ncomp, nip)
        REAL(wp), ALLOCATABLE :: strain(:,:)
        REAL(wp), ALLOCATABLE :: stress_old(:,:)
        REAL(wp), ALLOCATABLE :: strain_old(:,:)
    CONTAINS
        PROCEDURE :: init => elemstate_init
        PROCEDURE :: commit_all => elemstate_commit_all
        PROCEDURE :: revert_all => elemstate_revert_all
        PROCEDURE :: destroy => elemstate_destroy
    END TYPE MD_ElemIPData
```

### `MD_FieldMgr_Type` (lines 117–134)

```fortran
    TYPE, PUBLIC :: MD_FieldMgr_Type
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_elements = 0
        INTEGER(i4) :: num_fields = 0
        ! Nodal fields
        TYPE(MD_NodalField), ALLOCATABLE :: fields(:)
        ! Element states
        TYPE(MD_ElemIPData), ALLOCATABLE :: elem_states(:)
    CONTAINS
        PROCEDURE :: init => fsmgr_init
        PROCEDURE :: add_field => fsmgr_add_field
        PROCEDURE :: get_field => fsmgr_get_field
        PROCEDURE :: init_element_states => fsmgr_init_elem_states
        PROCEDURE :: get_elem_state => fsmgr_get_elem_state
        PROCEDURE :: commit_increment => fsmgr_commit
        PROCEDURE :: revert_increment => fsmgr_revert
        PROCEDURE :: destroy => fsmgr_destroy
    END TYPE MD_FieldMgr_Type
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Field_Domain_Init` | 141 | `SUBROUTINE MD_Field_Domain_Init(desc, state, ctx, status)` |
| SUBROUTINE | `MD_Field_Domain_Finalize` | 156 | `SUBROUTINE MD_Field_Domain_Finalize(desc, state, ctx, status)` |
| SUBROUTINE | `MD_Field_Define` | 171 | `SUBROUTINE MD_Field_Define(desc, id, name, n_comp, entity, status, &` |
| SUBROUTINE | `MD_Field_Set_Initial` | 229 | `SUBROUTINE MD_Field_Set_Initial(desc, field_id, init_val, status)` |
| SUBROUTINE | `MD_Field_Set_InitCond` | 257 | `SUBROUTINE MD_Field_Set_InitCond(desc, field_id, initial, status)` |
| SUBROUTINE | `MD_Field_Get_By_ID` | 282 | `SUBROUTINE MD_Field_Get_By_ID(desc, field_id, field, status)` |
| SUBROUTINE | `MD_Field_Get_By_Name` | 301 | `SUBROUTINE MD_Field_Get_By_Name(desc, name, field, status)` |
| FUNCTION | `MD_Field_Get_Count` | 321 | `FUNCTION MD_Field_Get_Count(desc) RESULT(n)` |
| SUBROUTINE | `nodal_init` | 330 | `SUBROUTINE nodal_init(this, name, ftype, ncomp, nnodes)` |
| SUBROUTINE | `nodal_set_value` | 346 | `SUBROUTINE nodal_set_value(this, node_id, comp, val)` |
| FUNCTION | `nodal_get_value` | 357 | `FUNCTION nodal_get_value(this, node_id, comp) RESULT(val)` |
| SUBROUTINE | `nodal_update` | 369 | `SUBROUTINE nodal_update(this, delta)` |
| SUBROUTINE | `nodal_store_old` | 376 | `SUBROUTINE nodal_store_old(this)` |
| SUBROUTINE | `nodal_restore` | 382 | `SUBROUTINE nodal_restore(this)` |
| SUBROUTINE | `nodal_destroy` | 388 | `SUBROUTINE nodal_destroy(this)` |
| SUBROUTINE | `elemstate_init` | 398 | `SUBROUTINE elemstate_init(this, elem_id, nip, nsdv, nstress)` |
| SUBROUTINE | `elemstate_commit_all` | 418 | `SUBROUTINE elemstate_commit_all(this)` |
| SUBROUTINE | `elemstate_revert_all` | 426 | `SUBROUTINE elemstate_revert_all(this)` |
| SUBROUTINE | `elemstate_destroy` | 434 | `SUBROUTINE elemstate_destroy(this)` |
| SUBROUTINE | `fsmgr_init` | 449 | `SUBROUTINE fsmgr_init(this, nnodes, nelems)` |
| SUBROUTINE | `fsmgr_add_field` | 471 | `SUBROUTINE fsmgr_add_field(this, name, ftype, ncomp)` |
| FUNCTION | `fsmgr_get_field` | 480 | `FUNCTION fsmgr_get_field(this, name) RESULT(ptr)` |
| SUBROUTINE | `fsmgr_init_elem_states` | 494 | `SUBROUTINE fsmgr_init_elem_states(this, nip_array, nsdv, nstress)` |
| FUNCTION | `fsmgr_get_elem_state` | 503 | `FUNCTION fsmgr_get_elem_state(this, elem_id) RESULT(ptr)` |
| SUBROUTINE | `fsmgr_commit` | 513 | `SUBROUTINE fsmgr_commit(this)` |
| SUBROUTINE | `fsmgr_revert` | 524 | `SUBROUTINE fsmgr_revert(this)` |
| SUBROUTINE | `fsmgr_destroy` | 535 | `SUBROUTINE fsmgr_destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
