# `MD_Load_Def.f90`

- **Source**: `L3_MD/Boundary/MD_Load_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Load_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Load_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Load`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Boundary`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Boundary/MD_Load_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Load_Base_Desc` (lines 54–72)

```fortran
  TYPE, PUBLIC :: MD_Load_Base_Desc
    INTEGER(i4)       :: load_id   = 0_i4
    INTEGER(i4)       :: load_family = 0_i4
    CHARACTER(LEN=64) :: load_name = ''
    LOGICAL           :: is_initialized = .FALSE.
    REAL(wp) :: magnitude = 0.0_wp
    REAL(wp) :: scale_factor = 1.0_wp
    INTEGER(i4) :: time_dependence = 0_i4
    INTEGER(i4) :: amplitude_id = 0_i4
    INTEGER(i4) :: load_type = 0_i4
    INTEGER(i4) :: element_face = 0_i4
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: dof_number = 0_i4
    REAL(wp) :: ambient_temp = 0.0_wp
    REAL(wp) :: film_coeff = 0.0_wp
  CONTAINS
    PROCEDURE :: Init   => Load_Desc_Init
    PROCEDURE :: Reset  => Load_Desc_Reset
  END TYPE MD_Load_Base_Desc
```

### `MD_Load_Base_State` (lines 79–86)

```fortran
  TYPE, PUBLIC :: MD_Load_Base_State
    REAL(wp) :: accumulated = 0.0_wp
    REAL(wp) :: last_magnitude = 0.0_wp
    REAL(wp) :: work_done = 0.0_wp
    LOGICAL     :: converged   = .FALSE.
    INTEGER(i4) :: iterations  = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Load_Base_State
```

### `MD_Load_Base_Algo` (lines 93–99)

```fortran
  TYPE, PUBLIC :: MD_Load_Base_Algo
    INTEGER(i4) :: apply_mode = 1_i4
    LOGICAL :: use_ramp = .FALSE.
    REAL(wp) :: ramp_duration = 0.0_wp
    LOGICAL :: is_follower = .FALSE.
    LOGICAL :: print_debug = .FALSE.
  END TYPE MD_Load_Base_Algo
```

### `MD_Load_DFLUX_Desc` (lines 106–112)

```fortran
  TYPE, PUBLIC :: MD_Load_DFLUX_Desc
    INTEGER(i4) :: flux_type   = 11_i4
    REAL(wp)    :: q0          = 0.0_wp
    REAL(wp)    :: q_scale     = 1.0_wp
    INTEGER(i4) :: temp_depend = 0_i4
    LOGICAL     :: is_explicit = .FALSE.
  END TYPE MD_Load_DFLUX_Desc
```

### `MD_Load_FILM_Desc` (lines 119–125)

```fortran
  TYPE, PUBLIC :: MD_Load_FILM_Desc
    REAL(wp)    :: h_ref       = 0.0_wp
    REAL(wp)    :: T_sink_ref  = 0.0_wp
    INTEGER(i4) :: face_id     = 0_i4
    LOGICAL     :: h_temp_dep  = .FALSE.
    LOGICAL     :: is_explicit = .FALSE.
  END TYPE MD_Load_FILM_Desc
```

### `MD_Load_HETVAL_Desc` (lines 132–137)

```fortran
  TYPE, PUBLIC :: MD_Load_HETVAL_Desc
    REAL(wp)    :: flux_ref    = 0.0_wp
    INTEGER(i4) :: nstatv      = 0_i4
    LOGICAL     :: rate_dep    = .FALSE.
    CHARACTER(LEN=80) :: cmname = ''
  END TYPE MD_Load_HETVAL_Desc
```

### `MD_Load_UWAVE_Desc` (lines 144–151)

```fortran
  TYPE, PUBLIC :: MD_Load_UWAVE_Desc
    REAL(wp) :: wave_height    = 0.0_wp
    REAL(wp) :: wave_period    = 0.0_wp
    REAL(wp) :: wave_direction = 0.0_wp
    REAL(wp) :: water_depth    = 1.0_wp
    REAL(wp) :: current_vel(3) = 0.0_wp
    INTEGER(i4) :: wave_theory = 1_i4
  END TYPE MD_Load_UWAVE_Desc
```

### `MD_Load_DLOAD_Desc` (lines 158–165)

```fortran
  TYPE, PUBLIC :: MD_Load_DLOAD_Desc
    CHARACTER(LEN=80) :: load_name = ' '
    INTEGER(i4) :: jltyp     = 0_i4
    REAL(wp)    :: magnitude = 0.0_wp
    INTEGER(i4) :: amp_id    = 0_i4
    LOGICAL     :: follower  = .FALSE.
    LOGICAL     :: is_active = .FALSE.
  END TYPE MD_Load_DLOAD_Desc
```

### `MD_Load_Dist_Desc` (lines 172–181)

```fortran
  TYPE, PUBLIC :: MD_Load_Dist_Desc
    INTEGER(i4) :: id = 0_i4
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4) :: stepId = 0_i4
    CHARACTER(LEN=32) :: loadType = ""
    CHARACTER(LEN=64) :: target = ""
    REAL(wp) :: magnitude(3) = 0.0_wp
    CHARACTER(LEN=64) :: ampName = ""
    INTEGER(i4) :: dof = 0_i4
  END TYPE MD_Load_Dist_Desc
```

### `MD_IC_Def_Type` (lines 188–195)

```fortran
  TYPE, PUBLIC :: MD_IC_Def_Type
    INTEGER(i4) :: id = 0_i4
    CHARACTER(LEN=64) :: name = ""
    CHARACTER(LEN=32) :: icType = ""
    CHARACTER(LEN=64) :: nodeSet = ""
    INTEGER(i4) :: nDofs = 0_i4
    REAL(wp), ALLOCATABLE :: values(:)
  END TYPE MD_IC_Def_Type
```

### `MD_IC_State` (lines 202–207)

```fortran
  TYPE, PUBLIC :: MD_IC_State
    REAL(wp) :: currentValue = 0.0_wp
    LOGICAL  :: isActive = .TRUE.
    INTEGER(i4) :: step_idx = 0_i4
    INTEGER(i4) :: incr_idx = 0_i4
  END TYPE MD_IC_State
```

### `MD_Field_Predef_Desc` (lines 214–222)

```fortran
  TYPE, PUBLIC :: MD_Field_Predef_Desc
    INTEGER(i4) :: id = 0_i4
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4) :: stepId = 0_i4
    CHARACTER(LEN=32) :: fieldType = ""
    CHARACTER(LEN=64) :: region = ""
    REAL(wp), ALLOCATABLE :: fieldData(:,:)
    CHARACTER(LEN=64) :: ampName = ""
  END TYPE MD_Field_Predef_Desc
```

### `MD_Load_Base_Ctx` (lines 229–235)

```fortran
  TYPE, PUBLIC :: MD_Load_Base_Ctx
    INTEGER(i4) :: current_load_id = 0_i4
    INTEGER(i4) :: operation_type = 0_i4
    INTEGER(i4) :: last_step_idx = 0_i4
    INTEGER(i4) :: last_incr_idx = 0_i4
    CHARACTER(LEN=64) :: last_operation = ""
  END TYPE MD_Load_Base_Ctx
```

### `MD_LoadBC_State` (lines 242–251)

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

### `MD_LoadBC_Algo` (lines 258–265)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Algo
    REAL(wp)    :: penalty_factor = 1.0e12_wp
    REAL(wp)    :: load_convergence_tol = 1.0e-3_wp
    REAL(wp)    :: displacement_tol = 1.0e-6_wp
    LOGICAL     :: auto_stabilize = .FALSE.
    REAL(wp)    :: viscous_factor = 0.0_wp
    INTEGER(i4) :: max_bc_iterations = 100_i4
  END TYPE MD_LoadBC_Algo
```

### `MD_LoadBC_Ctx` (lines 272–279)

```fortran
  TYPE, PUBLIC :: MD_LoadBC_Ctx
    INTEGER(i4) :: nBCs = 0_i4
    INTEGER(i4) :: nLoads = 0_i4
    INTEGER(i4) :: nICs = 0_i4
    INTEGER(i4) :: nFields = 0_i4
    TYPE(MD_LoadBC_State) :: state
    TYPE(MD_LoadBC_Algo)  :: algo
  END TYPE MD_LoadBC_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Load_Desc_Init` | 288 | `SUBROUTINE Load_Desc_Init(self)` |
| SUBROUTINE | `Load_Desc_Reset` | 298 | `SUBROUTINE Load_Desc_Reset(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
