# `MD_Solv_Def.f90`

- **Source**: `L3_MD/Analysis/Solver/MD_Solv_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Solv_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Solv_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Solv`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Solver/MD_Solv_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Solv_Cfg_Init_Desc` (lines 30–33)

```fortran
  TYPE, PUBLIC :: MD_Solv_Cfg_Init_Desc
    INTEGER(i4) :: config_id      = 0_i4
    INTEGER(i4) :: step_ref        = 0_i4
  END TYPE MD_Solv_Cfg_Init_Desc
```

### `MD_Solv_Itr_Com_Desc` (lines 38–48)

```fortran
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Desc
    INTEGER(i4) :: max_iterations   = 16_i4
    REAL(wp)    :: residual_tol     = 1.0e-5_wp
    REAL(wp)    :: correction_tol   = 1.0e-3_wp
    REAL(wp)    :: energy_tol       = 1.0e-4_wp
    LOGICAL     :: check_residual   = .TRUE.
    LOGICAL     :: check_correction = .TRUE.
    LOGICAL     :: check_energy     = .FALSE.
    LOGICAL     :: line_search      = .FALSE.
    REAL(wp)    :: line_search_tol  = 0.25_wp
  END TYPE MD_Solv_Itr_Com_Desc
```

### `MD_Solv_Stp_Ctl_Desc` (lines 53–57)

```fortran
  TYPE, PUBLIC :: MD_Solv_Stp_Ctl_Desc
    LOGICAL     :: stabilize                 = .FALSE.
    REAL(wp)    :: stabilize_factor          = 2.0e-4_wp
    REAL(wp)    :: stabilize_energy_fraction = 0.05_wp
  END TYPE MD_Solv_Stp_Ctl_Desc
```

### `MD_Solver_Desc` (lines 64–68)

```fortran
  TYPE, PUBLIC :: MD_Solver_Desc
    TYPE(MD_Solv_Cfg_Init_Desc) :: cfg
    TYPE(MD_Solv_Itr_Com_Desc)  :: itr
    TYPE(MD_Solv_Stp_Ctl_Desc)  :: stp
  END TYPE MD_Solver_Desc
```

### `MD_Solv_Itr_Com_Algo` (lines 73–85)

```fortran
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Algo
    INTEGER(i4) :: max_iterations   = 16_i4
    REAL(wp)    :: residual_tol     = 1.0e-5_wp
    REAL(wp)    :: correction_tol   = 1.0e-3_wp
    REAL(wp)    :: energy_tol       = 1.0e-4_wp
    LOGICAL     :: check_residual   = .TRUE.
    LOGICAL     :: check_correction = .TRUE.
    LOGICAL     :: check_energy     = .FALSE.
    LOGICAL     :: line_search      = .FALSE.
    REAL(wp)    :: line_search_tol  = 0.25_wp
    INTEGER(i4) :: max_cutbacks     = 5_i4
    REAL(wp)    :: cutback_factor   = 0.5_wp
  END TYPE MD_Solv_Itr_Com_Algo
```

### `MD_Solver_Algo` (lines 92–94)

```fortran
  TYPE, PUBLIC :: MD_Solver_Algo
    TYPE(MD_Solv_Itr_Com_Algo) :: itr
  END TYPE MD_Solver_Algo
```

### `MD_Solv_Stp_Ctl_State` (lines 99–102)

```fortran
  TYPE, PUBLIC :: MD_Solv_Stp_Ctl_State
    INTEGER(i4) :: current_config_idx      = 0_i4
    INTEGER(i4) :: failed_steps            = 0_i4
  END TYPE MD_Solv_Stp_Ctl_State
```

### `MD_Solv_Itr_Com_State` (lines 107–113)

```fortran
  TYPE, PUBLIC :: MD_Solv_Itr_Com_State
    INTEGER(i4) :: total_iterations         = 0_i4
    INTEGER(i4) :: max_iterations_reached = 0_i4
    REAL(wp)    :: last_residual_norm      = 0.0_wp
    REAL(wp)    :: last_correction_norm    = 0.0_wp
    LOGICAL     :: converged               = .FALSE.
  END TYPE MD_Solv_Itr_Com_State
```

### `MD_Solver_State` (lines 120–123)

```fortran
  TYPE, PUBLIC :: MD_Solver_State
    TYPE(MD_Solv_Stp_Ctl_State) :: stp
    TYPE(MD_Solv_Itr_Com_State) :: itr
  END TYPE MD_Solver_State
```

### `MD_Solv_Itr_Com_Ctx` (lines 128–135)

```fortran
  TYPE, PUBLIC :: MD_Solv_Itr_Com_Ctx
    REAL(wp)    :: current_residual_norm   = 0.0_wp
    REAL(wp)    :: current_correction_norm = 0.0_wp
    REAL(wp)    :: energy_ratio            = 0.0_wp
    INTEGER(i4) :: iteration_count         = 0_i4
    LOGICAL     :: needs_cutback           = .FALSE.
    REAL(wp)    :: cutback_factor          = 0.5_wp
  END TYPE MD_Solv_Itr_Com_Ctx
```

### `MD_Solver_Ctx` (lines 142–147)

```fortran
  TYPE, PUBLIC :: MD_Solver_Ctx
    TYPE(MD_Solv_Itr_Com_Ctx) :: itr
    ! [Phase:Itr|Verb:Comp] 工作数组引用 — 裸 POINTER，辅TYPE不承载单字段分组
    REAL(wp), POINTER :: work_vec(:) => NULL()
    REAL(wp), POINTER :: rhs(:) => NULL()
  END TYPE MD_Solver_Ctx
```

### `MD_LinearSolver_Desc` (lines 154–156)

```fortran
  TYPE, PUBLIC :: MD_LinearSolver_Desc
    INTEGER(i4) :: solver_id = 0_i4
  END TYPE MD_LinearSolver_Desc
```

### `MD_NR_Algo` (lines 163–165)

```fortran
  TYPE, PUBLIC :: MD_NR_Algo
    INTEGER(i4) :: max_iter = 16_i4
  END TYPE MD_NR_Algo
```

### `MD_Precond_Desc` (lines 172–174)

```fortran
  TYPE, PUBLIC :: MD_Precond_Desc
    INTEGER(i4) :: precond_type = 0_i4
  END TYPE MD_Precond_Desc
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MD_Solver_Desc_From_Algo` | 187 | `PURE SUBROUTINE MD_Solver_Desc_From_Algo(algo, desc)` |
| SUBROUTINE | `MD_Solver_Algo_From_Desc` | 208 | `PURE SUBROUTINE MD_Solver_Algo_From_Desc(desc, algo)` |
| SUBROUTINE | `MD_Solver_Desc_Init` | 225 | `SUBROUTINE MD_Solver_Desc_Init(desc, st)` |
| SUBROUTINE | `MD_Solver_Desc_SetTolerances` | 246 | `SUBROUTINE MD_Solver_Desc_SetTolerances(desc, residual_tol, correction_tol, energy_tol, st)` |
| SUBROUTINE | `MD_Solver_Desc_Finalize` | 257 | `SUBROUTINE MD_Solver_Desc_Finalize(desc, st)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
