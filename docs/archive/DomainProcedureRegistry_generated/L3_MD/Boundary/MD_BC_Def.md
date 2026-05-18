# `MD_BC_Def.f90`

- **Source**: `L3_MD/Boundary/MD_BC_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_BC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_BC_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_BC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_BC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_BC_Base_Desc` (lines 44–59)

```fortran
  TYPE, PUBLIC :: MD_BC_Base_Desc
    INTEGER(i4)       :: bc_id   = 0_i4
    INTEGER(i4)       :: bc_family = 0_i4
    CHARACTER(LEN=64) :: bc_name = ''
    LOGICAL           :: is_initialized = .FALSE.
    INTEGER(i4) :: node_set_id = 0_i4
    INTEGER(i4) :: dof_start = 1_i4
    INTEGER(i4) :: dof_end = 6_i4
    INTEGER(i4) :: bc_type = 0_i4
    REAL(wp) :: magnitude = 0.0_wp
    INTEGER(i4) :: amplitude_id = 0_i4
    INTEGER(i4) :: field_type = 0_i4
  CONTAINS
    PROCEDURE :: Init   => BC_Desc_Init
    PROCEDURE :: Reset  => BC_Desc_Reset
  END TYPE MD_BC_Base_Desc
```

### `MD_BC_Base_State` (lines 66–72)

```fortran
  TYPE, PUBLIC :: MD_BC_Base_State
    REAL(wp) :: accumulated = 0.0_wp
    REAL(wp) :: last_value = 0.0_wp
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_BC_Base_State
```

### `MD_BC_Base_Algo` (lines 79–85)

```fortran
  TYPE, PUBLIC :: MD_BC_Base_Algo
    INTEGER(i4) :: apply_mode = 1_i4     ! 1=direct, 2=penalty, 3=Lagrange
    REAL(wp)    :: penalty_factor = 1.0e12_wp  ! penalty stiffness (mode 2)
    REAL(wp)    :: ramp_fraction  = 1.0_wp     ! fraction of step for ramp-in
    LOGICAL     :: use_ramp     = .FALSE.      ! ramp BC over increment
    LOGICAL     :: print_debug = .FALSE.
  END TYPE MD_BC_Base_Algo
```

### `MD_BC_UPOT_Desc` (lines 92–97)

```fortran
  TYPE, PUBLIC :: MD_BC_UPOT_Desc
    INTEGER(i4) :: field_id    = 0_i4
    REAL(wp)    :: pot_ref     = 0.0_wp
    INTEGER(i4) :: dof_id      = 0_i4
    LOGICAL     :: is_ramped   = .FALSE.
  END TYPE MD_BC_UPOT_Desc
```

### `MD_BC_UTEMP_Desc` (lines 104–109)

```fortran
  TYPE, PUBLIC :: MD_BC_UTEMP_Desc
    REAL(wp)    :: T_ref       = 293.15_wp
    REAL(wp)    :: T_initial   = 293.15_wp
    LOGICAL     :: use_predef  = .FALSE.
    INTEGER(i4) :: npredf      = 0_i4
  END TYPE MD_BC_UTEMP_Desc
```

### `MD_BC_UMASFL_Desc` (lines 116–120)

```fortran
  TYPE, PUBLIC :: MD_BC_UMASFL_Desc
    REAL(wp)    :: mdot_ref    = 0.0_wp
    INTEGER(i4) :: face_id     = 0_i4
    LOGICAL     :: is_outflow  = .FALSE.
  END TYPE MD_BC_UMASFL_Desc
```

### `MD_BC_DISP_Desc` (lines 127–134)

```fortran
  TYPE, PUBLIC :: MD_BC_DISP_Desc
    CHARACTER(LEN=80) :: set_name  = ' '
    INTEGER(i4)       :: jdof_first = 0_i4
    INTEGER(i4)       :: jdof_last  = 0_i4
    REAL(wp)          :: magnitude  = 0.0_wp
    INTEGER(i4)       :: amp_id     = 0_i4
    LOGICAL           :: is_active  = .FALSE.
  END TYPE MD_BC_DISP_Desc
```

### `MD_BC_Base_Ctx` (lines 141–147)

```fortran
  TYPE, PUBLIC :: MD_BC_Base_Ctx
    INTEGER(i4) :: current_bc_id = 0_i4
    INTEGER(i4) :: operation_type = 0_i4
    INTEGER(i4) :: last_step_idx = 0_i4
    INTEGER(i4) :: last_incr_idx = 0_i4
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE MD_BC_Base_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `BC_Desc_Init` | 156 | `SUBROUTINE BC_Desc_Init(self)` |
| SUBROUTINE | `BC_Desc_Reset` | 166 | `SUBROUTINE BC_Desc_Reset(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
