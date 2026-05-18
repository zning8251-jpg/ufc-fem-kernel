# `RT_Elem_KernelProc.f90`

- **Source**: `L5_RT/Element/RT_Elem_KernelProc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_KernelProc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_KernelProc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem_KernelProc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_KernelProc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Elem_Kernel_In` (lines 24–46)

```fortran
  TYPE, PUBLIC :: RT_Elem_Kernel_In
    !-- Element identification
    INTEGER(i4) :: elem_id = 0           ! Global element ID
    INTEGER(i4) :: elem_type_id = 0      ! Element type ID
    INTEGER(i4) :: step_id = 0           ! Analysis step ID
    
    !-- Nodal data
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! Nodal coordinates [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: displ(:,:)      ! Nodal displacements [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: vel(:,:)        ! Nodal velocities [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: accel(:,:)      ! Nodal accelerations [dim, n_nodes]
    
    !-- Time and loading
    REAL(wp) :: time = 0.0_wp            ! Current time
    REAL(wp) :: dtime = 0.0_wp           ! Time increment
    INTEGER(i4) :: kstep = 0             ! Step number
    INTEGER(i4) :: kinc = 0              ! Increment number
    
    !-- Flags
    LOGICAL :: nlgeom = .FALSE.          ! Geometric nonlinearity flag
    LOGICAL :: is_first_iter = .FALSE.   ! First iteration in step
    
  END TYPE RT_Elem_Kernel_In
```

### `RT_Elem_Kernel_Out` (lines 52–67)

```fortran
  TYPE, PUBLIC :: RT_Elem_Kernel_Out
    !-- Element matrices
    REAL(wp), ALLOCATABLE :: amatrx(:,:)     ! Stiffness matrix [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: rhs(:,:)        ! Residual force [n_dof, 1]
    REAL(wp), ALLOCATABLE :: mass(:,:)       ! Mass matrix [n_dof, n_dof]
    REAL(wp), ALLOCATABLE :: damp(:,:)       ! Damping matrix [n_dof, n_dof]
    
    !-- State variables
    REAL(wp), ALLOCATABLE :: statev(:)       ! State variables [nstatev]
    REAL(wp), ALLOCATABLE :: energy(:)       ! Energy components [8]
    
    !-- Diagnostics
    INTEGER(i4) :: status = 0            ! Completion status
    REAL(wp) :: pnewdt = 1.0_wp          ! Time increment factor
    
  END TYPE RT_Elem_Kernel_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Elem_Kernel_Compute` | 83 | `SUBROUTINE RT_Elem_Kernel_Compute(state, ctx, inp, out, status)` |
| SUBROUTINE | `RT_Elem_Kernel_Init` | 137 | `SUBROUTINE RT_Elem_Kernel_Init(state, nstatev, status)` |
| SUBROUTINE | `RT_Elem_Kernel_Update` | 165 | `SUBROUTINE RT_Elem_Kernel_Update(state, out, status)` |
| SUBROUTINE | `RT_to_PH_Map` | 190 | `SUBROUTINE RT_to_PH_Map(rt_desc, rt_state, rt_algo, rt_ctx, &` |
| SUBROUTINE | `PH_to_RT_Update` | 209 | `SUBROUTINE PH_to_RT_Update(ph_state, rt_state)` |
| SUBROUTINE | `RT_Elem_Kernel_Allocate_Out` | 227 | `SUBROUTINE RT_Elem_Kernel_Allocate_Out(out, n_dof, nstatev)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
