# `RT_Cont_Solv.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Solv.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_Solv`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Solv`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont`
- **第四段角色（四段式）**: `_Solv`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Solv.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Cont_Search_In` (lines 56–65)

```fortran
  TYPE, PUBLIC :: RT_Cont_Search_In
    ! Geometry references (NON_OWNING_PTR)
    REAL(wp), POINTER :: node_coords(:,:) => NULL()  ! [3, n_nodes]
    REAL(wp), POINTER :: node_disp(:,:) => NULL()    ! [3, n_nodes]
      
    ! Search parameters
    REAL(wp) :: search_radius = 0.0_wp
    LOGICAL  :: use_global_search = .TRUE.
    LOGICAL  :: use_local_search = .TRUE.
  END TYPE RT_Cont_Search_In
```

### `RT_Cont_Search_Out` (lines 70–78)

```fortran
  TYPE, PUBLIC :: RT_Cont_Search_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Search results
    LOGICAL :: search_completed = .FALSE.
    INTEGER(i4) :: n_pairs_found = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Search_Out
```

### `RT_Cont_Force_In` (lines 84–91)

```fortran
  TYPE, PUBLIC :: RT_Cont_Force_In
    ! Contact pair information
    REAL(wp) :: gap = 0.0_wp
    REAL(wp) :: normal(3) = [0.0_wp, 0.0_wp, 0.0_wp]
      
    ! Options
    LOGICAL :: compute_tangent = .FALSE.
  END TYPE RT_Cont_Force_In
```

### `RT_Cont_Force_Out` (lines 96–103)

```fortran
  TYPE, PUBLIC :: RT_Cont_Force_Out
    ! Contact force result
    REAL(wp) :: force_out(3) = [0.0_wp, 0.0_wp, 0.0_wp]
      
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Force_Out
```

### `RT_Cont_Assemble_In` (lines 108–120)

```fortran
  TYPE, PUBLIC :: RT_Cont_Assemble_In
    ! Contact pair ID
    INTEGER(i4) :: pair_id = 0_i4
      
    ! CSR matrix references (NON_OWNING_PTR)
    INTEGER(i4), POINTER :: row_ptr(:) => NULL()
    INTEGER(i4), POINTER :: col_idx(:) => NULL()
    REAL(wp), POINTER :: values(:) => NULL()
    REAL(wp), POINTER :: rhs(:) => NULL()
      
    ! System size
    INTEGER(i4) :: n_dofs = 0_i4
  END TYPE RT_Cont_Assemble_In
```

### `RT_Cont_Assemble_Out` (lines 125–132)

```fortran
  TYPE, PUBLIC :: RT_Cont_Assemble_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Assembly statistics
    INTEGER(i4) :: assembled_entries = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Assemble_Out
```

### `RT_Cont_Stats_In` (lines 137–141)

```fortran
  TYPE, PUBLIC :: RT_Cont_Stats_In
    ! Query options
    LOGICAL :: include_force = .TRUE.
    LOGICAL :: include_pressure = .FALSE.
  END TYPE RT_Cont_Stats_In
```

### `RT_Cont_Stats_Out` (lines 146–155)

```fortran
  TYPE, PUBLIC :: RT_Cont_Stats_Out
    ! Status
    TYPE(ErrorStatusType) :: status
      
    ! Statistics
    INTEGER(i4) :: n_active_pairs = 0_i4
    REAL(wp) :: max_penetration = 0.0_wp
    REAL(wp) :: total_force = 0.0_wp
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_Cont_Stats_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Cont_Search` | 165 | `SUBROUTINE RT_Cont_Search(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_Force` | 178 | `SUBROUTINE RT_Cont_Force(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_Assemble` | 191 | `SUBROUTINE RT_Cont_Assemble(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_Stats` | 204 | `SUBROUTINE RT_Cont_Stats(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_Search` | 219 | `SUBROUTINE RT_Cont_Search(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_ComputeForce` | 271 | `SUBROUTINE RT_Cont_ComputeForce(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_Assemble` | 324 | `SUBROUTINE RT_Cont_Assemble(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Cont_GetStats` | 453 | `SUBROUTINE RT_Cont_GetStats(desc, state, algo, ctx, inp, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
