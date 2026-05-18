# `MD_LBC_Def.f90`

- **Source**: `L3_MD/LoadBC/MD_LBC_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `MD_LBC_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_LBC_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_LBC`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/LoadBC/MD_LBC_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Load_Desc` (lines 81–99)

```fortran
  TYPE, PUBLIC :: MD_Load_Desc
    INTEGER(i4)       :: load_id      = 0_i4
    INTEGER(i4)       :: load_family  = 0_i4
    CHARACTER(LEN=64) :: load_name    = ''
    LOGICAL           :: is_initialized = .FALSE.
    REAL(wp) :: magnitude      = 0.0_wp
    REAL(wp) :: scale_factor   = 1.0_wp
    INTEGER(i4) :: time_dependence = 0_i4
    INTEGER(i4) :: amplitude_id  = 0_i4
    INTEGER(i4) :: load_type     = 0_i4
    INTEGER(i4) :: element_face  = 0_i4
    INTEGER(i4) :: node_id       = 0_i4
    INTEGER(i4) :: dof_number    = 0_i4
    REAL(wp) :: ambient_temp   = 0.0_wp
    REAL(wp) :: film_coeff     = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => Load_Desc_Init
    PROCEDURE :: Reset  => Load_Desc_Reset
  END TYPE MD_Load_Desc
```

### `MD_BC_Desc` (lines 106–121)

```fortran
  TYPE, PUBLIC :: MD_BC_Desc
    INTEGER(i4)       :: bc_id      = 0_i4
    INTEGER(i4)       :: bc_family  = 0_i4
    CHARACTER(LEN=64) :: bc_name    = ''
    LOGICAL           :: is_initialized = .FALSE.
    INTEGER(i4) :: node_set_id  = 0_i4
    INTEGER(i4) :: dof_start    = 1_i4
    INTEGER(i4) :: dof_end      = 6_i4
    INTEGER(i4) :: bc_type      = 0_i4
    REAL(wp) :: magnitude   = 0.0_wp
    INTEGER(i4) :: amplitude_id = 0_i4
    INTEGER(i4) :: field_type   = 0_i4
  CONTAINS
    PROCEDURE :: Init   => BC_Desc_Init
    PROCEDURE :: Reset  => BC_Desc_Reset
  END TYPE MD_BC_Desc
```

### `MD_Load_State` (lines 127–134)

```fortran
  TYPE, PUBLIC :: MD_Load_State
    REAL(wp) :: accumulated   = 0.0_wp
    REAL(wp) :: last_magnitude = 0.0_wp
    REAL(wp) :: work_done     = 0.0_wp
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Load_State
```

### `MD_BC_State` (lines 136–142)

```fortran
  TYPE, PUBLIC :: MD_BC_State
    REAL(wp) :: accumulated   = 0.0_wp
    REAL(wp) :: last_value    = 0.0_wp
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_BC_State
```

### `MD_BC_Algo` (lines 148–154)

```fortran
  TYPE, PUBLIC :: MD_BC_Algo
    INTEGER(i4) :: apply_mode     = 1_i4   ! 1=direct, 2=penalty, 3=Lagrange
    REAL(wp)    :: penalty_factor = 1.0e12_wp
    REAL(wp)    :: ramp_fraction  = 1.0_wp
    LOGICAL     :: use_ramp       = .FALSE.
    REAL(wp)    :: lagrange_multiplier = 0.0_wp
  END TYPE MD_BC_Algo
```

### `MD_LBC_Algo` (lines 160–165)

```fortran
  TYPE, PUBLIC :: MD_LBC_Algo
    INTEGER(i4) :: default_amp_type = 0_i4
    INTEGER(i4) :: ramp_mode        = 0_i4
    LOGICAL     :: auto_scale       = .TRUE.
    REAL(wp)    :: scale_factor     = 1.0_wp
  END TYPE MD_LBC_Algo
```

### `MD_LBC_Ctx` (lines 167–172)

```fortran
  TYPE, PUBLIC :: MD_LBC_Ctx
    INTEGER(i4) :: current_load_id   = 0_i4
    INTEGER(i4) :: current_bc_id     = 0_i4
    INTEGER(i4) :: current_ic_id     = 0_i4
    INTEGER(i4) :: operation_type    = 0_i4
  END TYPE MD_LBC_Ctx
```

### `MD_LoadBC_State` (lines 179–188)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_State
    INTEGER(i4) :: total_bc_applied = 0_i4
    INTEGER(i4) :: total_load_applied = 0_i4
    INTEGER(i4) :: active_bc_count = 0_i4
    INTEGER(i4) :: active_load_count = 0_i4
    REAL(wp)    :: total_reaction_work = 0.0_wp
    REAL(wp)    :: total_external_work = 0.0_wp
    LOGICAL     :: bc_failure_detected = .FALSE.
    INTEGER(i4) :: failed_bc_ids = 0_i4
  END TYPE MD_LoadBC_State
```

### `MD_LoadBC_Domain` (lines 193–212)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Domain
    ! --- Load definitions ---
    TYPE(MD_Load_Desc),  ALLOCATABLE :: loads(:)
    INTEGER(i4)                      :: n_loads = 0_i4
    ! --- BC definitions ---
    TYPE(MD_BC_Desc),    ALLOCATABLE :: bcs(:)
    INTEGER(i4)                      :: n_bcs = 0_i4
    ! --- State / Algo / Ctx ---
    TYPE(MD_LoadBC_State) :: lbc_state
    TYPE(MD_LBC_Algo)     :: algo
    TYPE(MD_LBC_Ctx)      :: ctx
    LOGICAL               :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init     => LoadBC_Domain_Init
    PROCEDURE :: Finalize => LoadBC_Domain_Finalize
    PROCEDURE :: AddLoad  => LoadBC_Domain_AddLoad
    PROCEDURE :: AddBC    => LoadBC_Domain_AddBC
    PROCEDURE :: GetLoad  => LoadBC_Domain_GetLoad
    PROCEDURE :: GetBC    => LoadBC_Domain_GetBC
  END TYPE MD_LoadBC_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Load_Desc_Init` | 220 | `SUBROUTINE Load_Desc_Init(this)` |
| SUBROUTINE | `Load_Desc_Reset` | 238 | `SUBROUTINE Load_Desc_Reset(this)` |
| SUBROUTINE | `BC_Desc_Init` | 243 | `SUBROUTINE BC_Desc_Init(this)` |
| SUBROUTINE | `BC_Desc_Reset` | 258 | `SUBROUTINE BC_Desc_Reset(this)` |
| SUBROUTINE | `LoadBC_Domain_Init` | 267 | `SUBROUTINE LoadBC_Domain_Init(this, status)` |
| SUBROUTINE | `LoadBC_Domain_Finalize` | 277 | `SUBROUTINE LoadBC_Domain_Finalize(this, status)` |
| SUBROUTINE | `LoadBC_Domain_AddLoad` | 289 | `SUBROUTINE LoadBC_Domain_AddLoad(this, load, status)` |
| SUBROUTINE | `LoadBC_Domain_AddBC` | 309 | `SUBROUTINE LoadBC_Domain_AddBC(this, bc, status)` |
| SUBROUTINE | `LoadBC_Domain_GetLoad` | 329 | `SUBROUTINE LoadBC_Domain_GetLoad(this, idx, load, found)` |
| SUBROUTINE | `LoadBC_Domain_GetBC` | 341 | `SUBROUTINE LoadBC_Domain_GetBC(this, idx, bc, found)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
