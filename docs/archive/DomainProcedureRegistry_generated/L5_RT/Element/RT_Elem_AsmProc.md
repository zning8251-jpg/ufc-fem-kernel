# `RT_Elem_AsmProc.f90`

- **Source**: `L5_RT/Element/RT_Elem_AsmProc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_AsmProc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_AsmProc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem_AsmProc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_AsmProc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Elem_Assembly_In` (lines 26–51)

```fortran
  TYPE, PUBLIC :: RT_Elem_Assembly_In
    !-- Element identification
    INTEGER(i4) :: elem_id = 0           ! Global element ID
    INTEGER(i4) :: n_nodes = 0           ! Number of nodes
    INTEGER(i4) :: dof_per_node = 0      ! DOFs per node
    
    !-- Connectivity and mapping
    INTEGER(i4), ALLOCATABLE :: conn(:)      ! Node connectivity [n_nodes]
    INTEGER(i4), ALLOCATABLE :: lm(:)        ! LM array (destination array) [n_dof]
    
    !-- Nodal data
    REAL(wp), ALLOCATABLE :: coords(:,:)     ! Nodal coordinates [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: displ(:,:)      ! Nodal displacements [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: vel(:,:)        ! Nodal velocities [dim, n_nodes]
    REAL(wp), ALLOCATABLE :: accel(:,:)      ! Nodal accelerations [dim, n_nodes]
    
    !-- Time parameters
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: dtime = 0.0_wp
    INTEGER(i4) :: kstep = 0
    INTEGER(i4) :: kinc = 0
    
    !-- Flags
    LOGICAL :: nlgeom = .FALSE.          ! Geometric nonlinearity
    
  END TYPE RT_Elem_Assembly_In
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Element_Assemble_Ke` | 67 | `SUBROUTINE RT_Element_Assemble_Ke(state, ctx, inp, &` |
| SUBROUTINE | `RT_Element_Assemble_Fe` | 110 | `SUBROUTINE RT_Element_Assemble_Fe(state, ctx, inp, &` |
| SUBROUTINE | `RT_Element_Assemble_Me` | 148 | `SUBROUTINE RT_Element_Assemble_Me(state, ctx, inp, &` |
| SUBROUTINE | `RT_Element_Assemble_All` | 191 | `SUBROUTINE RT_Element_Assemble_All(state, ctx, inp, &` |
| SUBROUTINE | `Setup_Compute_Args` | 279 | `SUBROUTINE Setup_Compute_Args(args, inp)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
