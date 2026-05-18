# `RT_LoadBC_ReactionForce.f90`

- **Source**: `L5_RT/LoadBC/RT_LoadBC_ReactionForce.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_LoadBC_ReactionForce`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_LoadBC_ReactionForce`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_LoadBC_ReactionForce`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_LoadBC_ReactionForce.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_BC_Apply_In` (lines 28–46)

```fortran
  TYPE, PUBLIC :: RT_BC_Apply_In
    !-- BC identification
    INTEGER(i4) :: bc_id = 0             ! Global BC ID
    INTEGER(i4) :: bc_type = 0           ! BC type (disp/vel/acc)
    INTEGER(i4) :: dof = 0               ! DOF number (1-6)

    !-- Target nodes/elements
    INTEGER(i4), ALLOCATABLE :: node_ids(:)  ! Node list [n_nodes]
    INTEGER(i4) :: n_nodes = 0

    !-- BC values
    REAL(wp), ALLOCATABLE :: bc_values(:)    ! Prescribed values [n_nodes]
    REAL(wp) :: magnitude = 0.0_wp     ! Load curve magnitude
    REAL(wp) :: time = 0.0_wp          ! Current time

    !-- Method
    INTEGER(i4) :: apply_method = 0    ! 1=Penalty, 2=Elimination

  END TYPE RT_BC_Apply_In
```

### `RT_BC_Reaction_Out` (lines 52–66)

```fortran
  TYPE, PUBLIC :: RT_BC_Reaction_Out
    !-- Reaction forces
    REAL(wp), ALLOCATABLE :: reactions(:)    ! [n_constrained_dofs]
    INTEGER(i4) :: n_reactions = 0

    !-- Summaries
    REAL(wp) :: total_rx = 0.0_wp      ! Total X reaction
    REAL(wp) :: total_ry = 0.0_wp      ! Total Y reaction
    REAL(wp) :: total_rz = 0.0_wp      ! Total Z reaction
    REAL(wp) :: total_energy = 0.0_wp  ! Reaction work

    !-- Diagnostics
    LOGICAL :: computed = .FALSE.

  END TYPE RT_BC_Reaction_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_BC_Apply_Constraints` | 79 | `SUBROUTINE RT_BC_Apply_Constraints(desc, state, algo, ctx, inp, &` |
| SUBROUTINE | `RT_BC_Compute_Reactions` | 148 | `SUBROUTINE RT_BC_Compute_Reactions(desc, state, algo, ctx, &` |
| SUBROUTINE | `RT_BC_Process_Element_Reactions` | 179 | `SUBROUTINE RT_BC_Process_Element_Reactions(elem_desc, elem_state, elem_algo, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
