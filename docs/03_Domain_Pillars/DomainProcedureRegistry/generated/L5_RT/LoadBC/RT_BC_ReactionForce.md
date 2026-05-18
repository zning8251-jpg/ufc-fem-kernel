# `RT_BC_ReactionForce.f90`

- **Source**: `L5_RT/LoadBC/RT_BC_ReactionForce.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_BC_ReactionForce`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_BC_ReactionForce`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_BC_ReactionForce`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_BC_ReactionForce.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_BC_Apply_In` (lines 15–25)

```fortran
  TYPE, PUBLIC :: RT_BC_Apply_In
    INTEGER(i4) :: bc_id = 0
    INTEGER(i4) :: bc_type = 0
    INTEGER(i4) :: dof = 0
    INTEGER(i4) :: n_nodes = 0
    INTEGER(i4), ALLOCATABLE :: node_ids(:)
    REAL(wp), ALLOCATABLE :: bc_values(:)
    REAL(wp) :: magnitude = 0.0_wp
    REAL(wp) :: time = 0.0_wp
    INTEGER(i4) :: apply_method = 0
  END TYPE
```

### `RT_BC_Reaction_Out` (lines 27–35)

```fortran
  TYPE, PUBLIC :: RT_BC_Reaction_Out
    REAL(wp), ALLOCATABLE :: reactions(:)
    INTEGER(i4) :: n_reactions = 0
    REAL(wp) :: total_rx = 0.0_wp
    REAL(wp) :: total_ry = 0.0_wp
    REAL(wp) :: total_rz = 0.0_wp
    REAL(wp) :: total_energy = 0.0_wp
    LOGICAL :: computed = .FALSE.
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_BC_Apply_Constraints` | 43 | `SUBROUTINE RT_BC_Apply_Constraints(inp, K_global, F_global, status)` |
| SUBROUTINE | `RT_BC_Compute_Reactions` | 101 | `SUBROUTINE RT_BC_Compute_Reactions(f_ext, f_reaction, status)` |
| SUBROUTINE | `RT_BC_Process_Element_Reactions` | 116 | `SUBROUTINE RT_BC_Process_Element_Reactions(asm_inp, f_reaction, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
