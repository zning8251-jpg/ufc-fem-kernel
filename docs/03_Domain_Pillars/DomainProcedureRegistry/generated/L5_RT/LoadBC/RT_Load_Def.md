# `RT_Load_Def.f90`

- **Source**: `L5_RT/LoadBC/RT_Load_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Load_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Load_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Load`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_Load_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Load_Desc` (lines 14–21)

```fortran
  TYPE, PUBLIC :: RT_Load_Desc
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.
  CONTAINS
    PROCEDURE :: Init => LD_I
    PROCEDURE :: Clean => LD_C
  END TYPE
```

### `RT_Load_State` (lines 23–29)

```fortran
  TYPE, PUBLIC :: RT_Load_State
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.
  CONTAINS
    PROCEDURE :: Init => LS_I
    PROCEDURE :: Clean => LS_C
  END TYPE
```

### `RT_Load_Algo` (lines 31–35)

```fortran
  TYPE, PUBLIC :: RT_Load_Algo
    INTEGER(i4) :: dispatch_strategy = 0_i4
  CONTAINS
    PROCEDURE :: Init => LA_I
  END TYPE
```

### `RT_Load_Ctx` (lines 37–44)

```fortran
  TYPE, PUBLIC :: RT_Load_Ctx
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4
  CONTAINS
    PROCEDURE :: Init => LC_I
    PROCEDURE :: Clean => LC_C
  END TYPE
```

### `RT_Load_Dispatch_Arg` (lines 46–54)

```fortran
  TYPE, PUBLIC :: RT_Load_Dispatch_Arg
    INTEGER(i4) :: load_id
    INTEGER(i4) :: ip_index
    INTEGER(i4) :: elem_id
    REAL(wp) :: force_vector(6)
    REAL(wp) :: applied_load(6)
    INTEGER(i4) :: status_code
    CHARACTER(len=256) :: message
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `LD_I` | 58 | `SUBROUTINE LD_I(this, mat_id, l4_slot)` |
| SUBROUTINE | `LD_C` | 66 | `SUBROUTINE LD_C(this)` |
| SUBROUTINE | `LS_I` | 71 | `SUBROUTINE LS_I(this, num_ips)` |
| SUBROUTINE | `LS_C` | 78 | `SUBROUTINE LS_C(this)` |
| SUBROUTINE | `LA_I` | 84 | `SUBROUTINE LA_I(this)` |
| SUBROUTINE | `LC_I` | 89 | `SUBROUTINE LC_I(this)` |
| SUBROUTINE | `LC_C` | 96 | `SUBROUTINE LC_C(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
