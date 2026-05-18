# `RT_Elem_Def.f90`

- **Source**: `L5_RT/Element/RT_Elem_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Elem_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Elem_Desc` (lines 36–42)

```fortran
  TYPE, PUBLIC :: RT_Elem_Desc
    TYPE(PH_Elem_Desc) :: base       ! L4 cold metadata (Populate source)
    INTEGER(i4) :: n_elem         = 0     ! Total elements in domain
    INTEGER(i4) :: max_nn         = 8     ! Max nodes per element type
    INTEGER(i4) :: max_ndof_elem  = 24    ! Max DOF per element
    INTEGER(i4) :: ndof_per_node  = 3     ! DOF per node (default: 3D structural)
  END TYPE RT_Elem_Desc
```

### `RT_Elem_State` (lines 48–60)

```fortran
  TYPE, PUBLIC :: RT_Elem_State
    TYPE(PH_Elem_State) :: base      ! L4 base state

    ! Assembly context
    INTEGER(i4) :: n_eq = 0               ! Number of equations
    INTEGER(i4), ALLOCATABLE :: eq_map(:) ! Equation mapping
    LOGICAL     :: is_active = .TRUE.     ! Active flag

    ! Kernel state extensions (UEL / per-element state variables)
    REAL(wp), ALLOCATABLE :: statev(:)    ! State variables [nstatev]
    REAL(wp)    :: energy(8) = 0.0_wp     ! Energy components [8]
    INTEGER(i4) :: nstatev = 0            ! Number of state variables
  END TYPE RT_Elem_State
```

### `RT_Elem_Algo` (lines 66–70)

```fortran
  TYPE, PUBLIC :: RT_Elem_Algo
    TYPE(PH_Elem_Algo) :: base       ! L4 algo (integration, hourglass)
    INTEGER(i4) :: calc_type = 0          ! 0=all, 1=Ke, 2=Fe, 3=Me, 4=output
    LOGICAL     :: nlgeom = .FALSE.       ! Geometric nonlinearity flag
  END TYPE RT_Elem_Algo
```

### `RT_Elem_Ctx` (lines 76–90)

```fortran
  TYPE, PUBLIC :: RT_Elem_Ctx
    TYPE(PH_Elem_Ctx) :: base        ! L4 IP scratch (current_ip, det_J)

    ! Assembly offsets
    INTEGER(i4) :: node_offset  = 0       ! Node equation offset
    INTEGER(i4) :: elem_offset  = 0       ! Element matrix offset
    INTEGER(i4) :: n_secondary  = 0       ! Number of secondary DOFs

    ! Per-element DOF mapping scratch
    INTEGER(i4) :: elem_id      = 0       ! Current element ID
    INTEGER(i4) :: nn           = 0       ! Current element node count
    INTEGER(i4) :: ndof_elem    = 0       ! Current element DOF count
    INTEGER(i4) :: conn(8)      = 0       ! Node connectivity [max_nn]
    INTEGER(i4) :: dof_map(24)  = 0       ! DOF mapping [max_ndof_elem]
  END TYPE RT_Elem_Ctx
```

### `RT_Elem_Router_Entry` (lines 106–109)

```fortran
  TYPE, PUBLIC :: RT_Elem_Router_Entry
    INTEGER(i4) :: family_id = 0
    PROCEDURE(RT_Elem_Compute_Proc), POINTER, NOPASS :: compute => NULL()
  END TYPE RT_Elem_Router_Entry
```

### `RT_Elem_Dispatch_Table` (lines 111–115)

```fortran
  TYPE, PUBLIC :: RT_Elem_Dispatch_Table
    INTEGER(i4) :: n_registered = 0
    INTEGER(i4) :: max_families = 0
    TYPE(RT_Elem_Router_Entry), ALLOCATABLE :: entries(:)
  END TYPE RT_Elem_Dispatch_Table
```

### `RT_Elem_Eval_Ke_Arg` (lines 125–142)

```fortran
TYPE, PUBLIC :: RT_Elem_Eval_Ke_Arg
  ! [IN] element state
  TYPE(RT_Elem_Desc) :: desc                  ! [IN]  element descriptor
  TYPE(RT_Elem_State) :: state                ! [INOUT] element state
  TYPE(RT_Elem_Ctx) :: ctx                    ! [INOUT] element context

  ! [IN] evaluation parameters
  INTEGER(i4) :: elem_id                      ! [IN]  element ID
  INTEGER(i4) :: n_dof                        ! [IN]  degrees of freedom
  REAL(wp), ALLOCATABLE :: coords(:,:)         ! [IN]  node coordinates
  REAL(wp), ALLOCATABLE :: props(:)            ! [IN]  section properties
  REAL(wp) :: time_step                       ! [IN]  time step size

  ! [OUT] stiffness matrix
  REAL(wp), ALLOCATABLE :: ke(:,:)            ! [OUT] element stiffness matrix
  INTEGER(i4) :: status_code                  ! [OUT] exit status
  CHARACTER(len=256) :: message               ! [OUT] status message
END TYPE RT_Elem_Eval_Ke_Arg
```

### `RT_Elem_Eval_Fe_Arg` (lines 144–160)

```fortran
TYPE, PUBLIC :: RT_Elem_Eval_Fe_Arg
  ! [IN] element state
  TYPE(RT_Elem_Desc) :: desc                  ! [IN]  element descriptor
  TYPE(RT_Elem_State) :: state                ! [INOUT] element state
  TYPE(RT_Elem_Ctx) :: ctx                    ! [INOUT] element context

  ! [IN] evaluation parameters
  INTEGER(i4) :: elem_id                      ! [IN]  element ID
  INTEGER(i4) :: n_dof                        ! [IN]  degrees of freedom
  REAL(wp), ALLOCATABLE :: coords(:,:)         ! [IN]  node coordinates
  REAL(wp), ALLOCATABLE :: u_elem(:)           ! [IN]  element nodal displacements

  ! [OUT] force vector
  REAL(wp), ALLOCATABLE :: fe(:)              ! [OUT] element force vector
  INTEGER(i4) :: status_code                  ! [OUT] exit status
  CHARACTER(len=256) :: message               ! [OUT] status message
END TYPE RT_Elem_Eval_Fe_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Elem_Compute_Proc` | 98 | `SUBROUTINE RT_Elem_Compute_Proc(state, ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
