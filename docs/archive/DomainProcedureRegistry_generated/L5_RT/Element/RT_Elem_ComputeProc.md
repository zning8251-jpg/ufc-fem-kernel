# `RT_Elem_ComputeProc.f90`

- **Source**: `L5_RT/Element/RT_Elem_ComputeProc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_Elem_ComputeProc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Elem_ComputeProc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Elem_ComputeProc`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Element/RT_Elem_ComputeProc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Elem_Compute_Args` (lines 22–42)

```fortran
  TYPE, PUBLIC :: RT_Elem_Compute_Args
    !-- Input data
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
    LOGICAL :: nlgeom = .FALSE.
    LOGICAL :: compute_ke = .FALSE.
    LOGICAL :: compute_fe = .FALSE.
    LOGICAL :: compute_me = .FALSE.
    LOGICAL :: compute_ce = .FALSE.
    
  END TYPE RT_Elem_Compute_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Element_Compute_Ke` | 58 | `SUBROUTINE RT_Element_Compute_Ke(state, ctx, args, amatrx, status)` |
| SUBROUTINE | `RT_Element_Compute_Fe` | 89 | `SUBROUTINE RT_Element_Compute_Fe(state, ctx, args, rhs, status)` |
| SUBROUTINE | `RT_Element_Compute_Me` | 120 | `SUBROUTINE RT_Element_Compute_Me(state, ctx, args, mass, status)` |
| SUBROUTINE | `RT_Element_Compute_All` | 150 | `SUBROUTINE RT_Element_Compute_All(state, ctx, args, &` |
| SUBROUTINE | `Setup_Kernel_In` | 195 | `SUBROUTINE Setup_Kernel_In(inp, ctx, args)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
