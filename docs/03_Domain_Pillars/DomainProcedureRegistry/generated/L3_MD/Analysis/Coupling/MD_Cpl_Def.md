# `MD_Cpl_Def.f90`

- **Source**: `L3_MD/Analysis/Coupling/MD_Cpl_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Cpl_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Cpl_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Cpl`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Coupling/MD_Cpl_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Coup_PairDef` (lines 111–121)

```fortran
  TYPE, PUBLIC :: MD_Coup_PairDef
    INTEGER(i4) :: pair_id = 0_i4
    INTEGER(i4) :: src_field_id = 0_i4       ! MD_COUP_FIELD_*
    INTEGER(i4) :: dst_field_id = 0_i4       ! MD_COUP_FIELD_*
    INTEGER(i4) :: qty_type = 0_i4           ! what is transferred (1-10)
    INTEGER(i4) :: interface_surf_id = 0_i4  ! mesh surface set reference
    REAL(wp) :: scale_factor = 1.0_wp
    LOGICAL :: is_active = .TRUE.
    CHARACTER(LEN=64) :: label = ''
    CHARACTER(LEN=128) :: keyword_source = ''  ! e.g. "*COUPLED TEMPERATURE-DISPLACEMENT"
  END TYPE MD_Coup_PairDef
```

### `MD_Cpl_Stp_Ctl_Desc` (lines 128–134)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_Desc
    INTEGER(i4) :: strategy = MD_COUP_STRAT_STAG
    INTEGER(i4) :: interp_method = 0_i4      ! 0=NN, 1=RBF, 2=MLS, 3=C0
    INTEGER(i4) :: max_coupling_iter = 10_i4
    REAL(wp) :: coupling_tol = 1.0E-4_wp
    LOGICAL :: is_configured = .FALSE.
  END TYPE MD_Cpl_Stp_Ctl_Desc
```

### `MD_Cpl_Desc` (lines 141–145)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Desc
    INTEGER(i4) :: n_pairs = 0_i4                       ! active pair count
    TYPE(MD_Coup_PairDef) :: pairs(MD_COUP_MAX_PAIRS)
    TYPE(MD_Cpl_Stp_Ctl_Desc) :: ctl
  END TYPE MD_Cpl_Desc
```

### `MD_Cpl_Inc_Evo_State` (lines 152–155)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Inc_Evo_State
    INTEGER(i4) :: current_step_id = 0_i4
    INTEGER(i4) :: n_active_pairs = 0_i4
  END TYPE MD_Cpl_Inc_Evo_State
```

### `MD_Cpl_Stp_Ctl_State` (lines 162–165)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_State
    LOGICAL :: is_active = .FALSE.
    LOGICAL :: populated_to_l5 = .FALSE.
  END TYPE MD_Cpl_Stp_Ctl_State
```

### `MD_Cpl_State` (lines 172–175)

```fortran
  TYPE, PUBLIC :: MD_Cpl_State
    TYPE(MD_Cpl_Inc_Evo_State) :: inc
    TYPE(MD_Cpl_Stp_Ctl_State) :: stp
  END TYPE MD_Cpl_State
```

### `MD_Cpl_Stp_Ctl_Algo` (lines 182–194)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Stp_Ctl_Algo
    REAL(wp) :: relaxation_factor = 1.0_wp
    LOGICAL :: use_aitken = .FALSE.
    REAL(wp) :: aitken_init = 0.01_wp           ! initial Aitken relaxation
    INTEGER(i4) :: subcycle_ratio = 1_i4      ! 1=no subcycle, 2=double, ...
    LOGICAL :: subcycle_adaptive = .FALSE.    ! auto-adjust subcycle ratio
    REAL(wp) :: subcycle_min_dt = 0.0_wp      ! minimum subcycle dt
    INTEGER(i4) :: stagger_strategy = 0_i4    ! 0=sequential, 1=parallel, 2=block
    LOGICAL :: use_predictor = .FALSE.        ! predict fields between stagger
    INTEGER(i4) :: predict_type = 0_i4        ! 0=zero, 1=linear, 2=extrapolation
    REAL(wp) :: relaxation_min = 0.01_wp      ! minimum relaxation factor
    REAL(wp) :: relaxation_max = 0.99_wp      ! maximum relaxation factor
  END TYPE MD_Cpl_Stp_Ctl_Algo
```

### `MD_Cpl_Algo` (lines 201–203)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Algo
    TYPE(MD_Cpl_Stp_Ctl_Algo) :: stp
  END TYPE MD_Cpl_Algo
```

### `MD_Cpl_Pop_Brg_Ctx` (lines 210–213)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Pop_Brg_Ctx
    LOGICAL :: populate_pending = .FALSE.
    LOGICAL :: writeback_done = .FALSE.
  END TYPE MD_Cpl_Pop_Brg_Ctx
```

### `MD_Cpl_Ctx` (lines 220–222)

```fortran
  TYPE, PUBLIC :: MD_Cpl_Ctx
    TYPE(MD_Cpl_Pop_Brg_Ctx) :: brg
  END TYPE MD_Cpl_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
