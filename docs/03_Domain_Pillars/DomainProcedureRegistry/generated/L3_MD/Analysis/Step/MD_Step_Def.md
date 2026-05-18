# `MD_Step_Def.f90`

- **Source**: `L3_MD/Analysis/Step/MD_Step_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Step_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Step_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Step`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Step`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Step/MD_Step_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Step_Inc_Evo_State` (lines 66–71)

```fortran
  TYPE, PUBLIC :: MD_Step_Inc_Evo_State
    REAL(wp)    :: current_time       = 0.0_wp
    INTEGER(i4) :: current_increment  = 0_i4
    INTEGER(i4) :: total_increments   = 0_i4
    REAL(wp)    :: accumulated_time   = 0.0_wp
  END TYPE MD_Step_Inc_Evo_State
```

### `MD_Step_Stp_Ctl_State` (lines 78–84)

```fortran
  TYPE, PUBLIC :: MD_Step_Stp_Ctl_State
    LOGICAL     :: is_active          = .TRUE.
    LOGICAL     :: is_complete        = .FALSE.
    LOGICAL     :: is_converged       = .TRUE.
    INTEGER(i4) :: newton_iterations  = 0_i4
    INTEGER(i4) :: cutback_count      = 0_i4
  END TYPE MD_Step_Stp_Ctl_State
```

### `MD_Step_State` (lines 91–94)

```fortran
  TYPE, PUBLIC :: MD_Step_State
    TYPE(MD_Step_Inc_Evo_State) :: inc
    TYPE(MD_Step_Stp_Ctl_State) :: stp
  END TYPE MD_Step_State
```

### `MD_Step_Inc_Evo_Ctx` (lines 101–110)

```fortran
  TYPE, PUBLIC :: MD_Step_Inc_Evo_Ctx
    REAL(wp)    :: step_time          = 0.0_wp
    REAL(wp)    :: total_time         = 0.0_wp
    REAL(wp)    :: time_increment     = 0.0_wp
    INTEGER(i4) :: increment_number   = 0_i4
    INTEGER(i4) :: analysis_type      = 0_i4
    LOGICAL     :: nlgeom             = .FALSE.
    LOGICAL     :: first_increment    = .FALSE.
    LOGICAL     :: last_increment     = .FALSE.
  END TYPE MD_Step_Inc_Evo_Ctx
```

### `MD_Step_Itr_Com_Ctx` (lines 117–122)

```fortran
  TYPE, PUBLIC :: MD_Step_Itr_Com_Ctx
    INTEGER(i4) :: iteration_number   = 0_i4
    REAL(wp)    :: newmark_gamma      = 0.5_wp
    REAL(wp)    :: newmark_beta       = 0.25_wp
    REAL(wp)    :: hht_alpha          = 0.0_wp
  END TYPE MD_Step_Itr_Com_Ctx
```

### `MD_Step_Ctx` (lines 129–132)

```fortran
  TYPE, PUBLIC :: MD_Step_Ctx
    TYPE(MD_Step_Inc_Evo_Ctx) :: inc
    TYPE(MD_Step_Itr_Com_Ctx) :: itr
  END TYPE MD_Step_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
