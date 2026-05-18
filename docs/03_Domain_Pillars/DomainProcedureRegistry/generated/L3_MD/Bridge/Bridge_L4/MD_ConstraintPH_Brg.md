# `MD_ConstraintPH_Brg.f90`

- **Source**: `L3_MD/Bridge/Bridge_L4/MD_ConstraintPH_Brg.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_ConstraintPH_Brg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_ConstraintPH_Brg`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_ConstraintPH`
- **第四段角色（四段式）**: `_Brg`
- **源码子路径（层下目录，不含文件名）**: `Bridge/Bridge_L4`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Bridge/Bridge_L4/MD_ConstraintPH_Brg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Constraint_Cfg_Basic` (lines 44–49)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Cfg_Basic
    INTEGER(i4) :: constraint_id = 0_i4
    CHARACTER(LEN=64) :: constraint_name = ""
    INTEGER(i4) :: constraint_type = 0_i4  ! MPC, TIE, COUPLING
    LOGICAL :: is_active = .TRUE.
  END TYPE PH_Constraint_Cfg_Basic
```

### `PH_Constraint_Cfg_MPC` (lines 51–56)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Cfg_MPC
    INTEGER(i4), ALLOCATABLE :: dof_list(:)      ! Global DOF indices
    REAL(wp), ALLOCATABLE :: coef_list(:)       ! Coefficients c1, c2, ...
    REAL(wp) :: constant_term = 0.0_wp           ! C0 in sum(ci*ui) = C0
    INTEGER(i4) :: mpc_type = 0_i4               ! BEAM, LINK, PIN, GENERAL
  END TYPE PH_Constraint_Cfg_MPC
```

### `PH_Constraint_Cfg_Tie` (lines 58–65)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Cfg_Tie
    INTEGER(i4) :: master_surface_id = 0_i4
    INTEGER(i4) :: slave_surface_id = 0_i4
    CHARACTER(LEN=64) :: master_surface = ""
    CHARACTER(LEN=64) :: slave_surface = ""
    REAL(wp) :: position_tolerance = 0.05_wp
    LOGICAL :: adjust_slave = .TRUE.
  END TYPE PH_Constraint_Cfg_Tie
```

### `PH_Constraint_Cfg_Coupling` (lines 67–73)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Cfg_Coupling
    INTEGER(i4) :: ref_node_id = 0_i4
    CHARACTER(LEN=64) :: coupled_surface = ""
    INTEGER(i4) :: coupling_type = 0_i4        ! KINEMATIC, DISTRIBUTING
    INTEGER(i4) :: dof_mask = DOF_ALL          ! DOF mask bits
    REAL(wp), ALLOCATABLE :: coef_list(:)      ! Weights for distributing
  END TYPE PH_Constraint_Cfg_Coupling
```

### `PH_Constraint_Cfg_Enforcement` (lines 75–78)

```fortran
  TYPE, PUBLIC :: PH_Constraint_Cfg_Enforcement
    INTEGER(i4) :: enforcement_method = PH_CONSTRAINT_PENALTY
    REAL(wp) :: penalty_parameter = 1.0e10_wp   ! Default penalty
  END TYPE PH_Constraint_Cfg_Enforcement
```

### `MD_Constraint_PH_Params` (lines 80–86)

```fortran
  TYPE, PUBLIC :: MD_Constraint_PH_Params
    TYPE(PH_Constraint_Cfg_Basic) :: basic
    TYPE(PH_Constraint_Cfg_MPC) :: mpc
    TYPE(PH_Constraint_Cfg_Tie) :: tie
    TYPE(PH_Constraint_Cfg_Coupling) :: coupling
    TYPE(PH_Constraint_Cfg_Enforcement) :: enforcement
  END TYPE MD_Constraint_PH_Params
```

### `MD_Constraint_PH_Params_Array` (lines 93–96)

```fortran
  TYPE, PUBLIC :: MD_Constraint_PH_Params_Array
    TYPE(MD_Constraint_PH_Params), ALLOCATABLE :: params(:)
    INTEGER(i4) :: n_constraints = 0_i4
  END TYPE MD_Constraint_PH_Params_Array
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Constraint_PH_Fill_MPC` | 111 | `SUBROUTINE MD_Constraint_PH_Fill_MPC(mpc_desc, params, status, global_dof_map)` |
| SUBROUTINE | `MD_Constraint_PH_Fill_Tie` | 162 | `SUBROUTINE MD_Constraint_PH_Fill_Tie(tie_desc, params, status)` |
| SUBROUTINE | `MD_Constraint_PH_Fill_Coupling` | 196 | `SUBROUTINE MD_Constraint_PH_Fill_Coupling(cpl_desc, params, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 98–102 | `INTERFACE MD_Constraint_PH_FillParams_FromMD` |
