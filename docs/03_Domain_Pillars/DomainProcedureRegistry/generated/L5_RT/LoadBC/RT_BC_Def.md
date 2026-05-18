# `RT_BC_Def.f90`

- **Source**: `L5_RT/LoadBC/RT_BC_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_BC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_BC_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_BC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_BC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_BC_Desc` (lines 14–21)

```fortran
  TYPE, PUBLIC :: RT_BC_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BD_I
    PROCEDURE :: Clean => BD_C
  END TYPE
```

### `RT_BC_State` (lines 23–29)

```fortran
  TYPE, PUBLIC :: RT_BC_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BS_I
    PROCEDURE :: Clean => BS_C
  END TYPE
```

### `RT_BC_Algo` (lines 31–35)

```fortran
  TYPE, PUBLIC :: RT_BC_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => BA_I
  END TYPE
```

### `RT_BC_Ctx` (lines 37–44)

```fortran
  TYPE, PUBLIC :: RT_BC_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => BC_I
    PROCEDURE :: Clean => BC_C
  END TYPE
```

### `RT_BC_Dispatch_Arg` (lines 46–54)

```fortran
  TYPE, PUBLIC :: RT_BC_Dispatch_Arg
    INTEGER(i4) :: bc_id = 0_i4
    INTEGER(i4) :: dof_index = 0_i4
    INTEGER(i4) :: elem_id = 0_i4
    REAL(wp) :: prescribed_val = 0.0_wp
    REAL(wp) :: reaction_force = 0.0_wp
    INTEGER(i4) :: status_code
    CHARACTER(len=256) :: message
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BD_I` | 58 | `SUBROUTINE BD_I(this, mat_id, l4_slot)` |
| SUBROUTINE | `BD_C` | 66 | `SUBROUTINE BD_C(this)` |
| SUBROUTINE | `BS_I` | 71 | `SUBROUTINE BS_I(this, num_ips)` |
| SUBROUTINE | `BS_C` | 78 | `SUBROUTINE BS_C(this)` |
| SUBROUTINE | `BA_I` | 84 | `SUBROUTINE BA_I(this)` |
| SUBROUTINE | `BC_I` | 89 | `SUBROUTINE BC_I(this)` |
| SUBROUTINE | `BC_C` | 96 | `SUBROUTINE BC_C(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
