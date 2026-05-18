# `MD_BC_Def.f90`

- **Source**: `L3_MD/LoadBC/MD_BC_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_BC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_BC_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_BC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/LoadBC/MD_BC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_BC_Desc` (lines 42–57)

```fortran
  TYPE, PUBLIC :: MD_BC_Desc
    INTEGER(i4)       :: bc_id = 0_i4
    INTEGER(i4)       :: bc_family = 0_i4
    CHARACTER(LEN=64) :: bc_name = ""
    LOGICAL           :: is_initialized = .FALSE.
    INTEGER(i4) :: node_set_id = 0_i4
    INTEGER(i4) :: dof_start = 1_i4
    INTEGER(i4) :: dof_end = 6_i4
    INTEGER(i4) :: bc_type = 0_i4
    REAL(wp) :: magnitude = 0.0_wp
    INTEGER(i4) :: amplitude_id = 0_i4
    INTEGER(i4) :: field_type = 0_i4
  CONTAINS
    PROCEDURE :: Init => BC_Desc_Init
    PROCEDURE :: Reset => BC_Desc_Reset
  END TYPE MD_BC_Desc
```

### `MD_BC_State` (lines 59–65)

```fortran
  TYPE, PUBLIC :: MD_BC_State
    REAL(wp) :: accumulated = 0.0_wp
    REAL(wp) :: last_value = 0.0_wp
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: iterations = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_BC_State
```

### `MD_BC_Algo` (lines 67–73)

```fortran
  TYPE, PUBLIC :: MD_BC_Algo
    INTEGER(i4) :: apply_mode = 1_i4
    REAL(wp) :: penalty_factor = 1.0e12_wp
    REAL(wp) :: ramp_fraction = 1.0_wp
    LOGICAL :: use_ramp = .FALSE.
    REAL(wp) :: lagrange_multiplier = 0.0_wp
  END TYPE MD_BC_Algo
```

### `MD_BC_Domain` (lines 75–84)

```fortran
  TYPE, PUBLIC :: MD_BC_Domain
    TYPE(MD_BC_Desc), ALLOCATABLE :: bcs(:)
    INTEGER(i4) :: n_bcs = 0_i4
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init => BC_Domain_Init
    PROCEDURE :: Finalize => BC_Domain_Finalize
    PROCEDURE :: AddBC => BC_Domain_AddBC
    PROCEDURE :: GetBC => BC_Domain_GetBC
  END TYPE MD_BC_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BC_Desc_Init` | 88 | `SUBROUTINE BC_Desc_Init(this)` |
| SUBROUTINE | `BC_Desc_Reset` | 103 | `SUBROUTINE BC_Desc_Reset(this)` |
| SUBROUTINE | `BC_Domain_Init` | 108 | `SUBROUTINE BC_Domain_Init(this, status)` |
| SUBROUTINE | `BC_Domain_Finalize` | 117 | `SUBROUTINE BC_Domain_Finalize(this, status)` |
| SUBROUTINE | `BC_Domain_AddBC` | 127 | `SUBROUTINE BC_Domain_AddBC(this, bc, status)` |
| SUBROUTINE | `BC_Domain_GetBC` | 147 | `SUBROUTINE BC_Domain_GetBC(this, idx, bc, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
