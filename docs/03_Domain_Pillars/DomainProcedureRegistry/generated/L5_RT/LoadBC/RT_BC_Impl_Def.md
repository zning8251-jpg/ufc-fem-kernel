# `RT_BC_Impl_Def.f90`

- **Source**: `L5_RT/LoadBC/RT_BC_Impl_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_BC_Impl_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_BC_Impl_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_BC_Impl`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_BC_Impl_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_BC_Impl_Desc` (lines 14–23)

```fortran
  TYPE, PUBLIC :: RT_BC_Impl_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    INTEGER(i4) :: n_bcs = 0_i4
    INTEGER(i4) :: amp_id = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE, PASS :: Init => BddI
    PROCEDURE, PASS :: Clean => BddC
  END TYPE
```

### `RT_BC_Impl_State` (lines 25–37)

```fortran
  TYPE, PUBLIC :: RT_BC_Impl_State
    INTEGER(i4) :: num_ips = 0_i4
    INTEGER(i4) :: total_cutbacks = 0_i4
    INTEGER(i4) :: total_iterations = 0_i4
    LOGICAL :: state_committed = .FALSE.
    LOGICAL :: bc_applied = .FALSE.
    LOGICAL :: cutback_active = .FALSE.
    REAL(wp) :: current_amp = 1.0_wp
    REAL(wp) :: accumulated_work = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdsI
    PROCEDURE, PASS :: Clean => BdsC
  END TYPE
```

### `RT_BC_Impl_Algo` (lines 39–47)

```fortran
  TYPE, PUBLIC :: RT_BC_Impl_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
    INTEGER(i4) :: max_cutbacks = 10_i4
    LOGICAL :: auto_cutback_enabled = .TRUE.
    REAL(wp) :: cutback_factor = 0.5_wp
    REAL(wp) :: load_convergence_tol = 1.0e-6_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdaI
  END TYPE
```

### `RT_BC_Impl_Ctx` (lines 49–61)

```fortran
  TYPE, PUBLIC :: RT_BC_Impl_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
    INTEGER(i4) :: analysis_type = 1_i4
    LOGICAL :: nlgeom = .FALSE.
    REAL(wp) :: time_increment = 0.0_wp
    REAL(wp) :: step_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
  CONTAINS
    PROCEDURE, PASS :: Init => BdcI
    PROCEDURE, PASS :: Clean => BdcC
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BddI` | 65 | `SUBROUTINE BddI(this, mat_id, l4_slot)` |
| SUBROUTINE | `BddC` | 75 | `SUBROUTINE BddC(this)` |
| SUBROUTINE | `BdsI` | 82 | `SUBROUTINE BdsI(this, num_ips)` |
| SUBROUTINE | `BdsC` | 95 | `SUBROUTINE BdsC(this)` |
| SUBROUTINE | `BdaI` | 107 | `SUBROUTINE BdaI(this)` |
| SUBROUTINE | `BdcI` | 116 | `SUBROUTINE BdcI(this)` |
| SUBROUTINE | `BdcC` | 128 | `SUBROUTINE BdcC(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
