# `RT_LoadBC_Impl_Def.f90`

- **Source**: `L5_RT/LoadBC/RT_LoadBC_Impl_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_LoadBC_Impl_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_LoadBC_Impl_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_LoadBC_Impl`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/LoadBC/RT_LoadBC_Impl_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_LoadBC_Impl_Desc` (lines 26–39)

```fortran
  TYPE, PUBLIC :: RT_LoadBC_Impl_Desc
    !-- Base fields (mirror Def for backward compat)
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: l4_slot_index = 0_i4
    LOGICAL :: is_active = .FALSE.

    !-- Extended fields (implementation layer)
    INTEGER(i4) :: n_loads = 0_i4  ! [IN]  number of concentrated/modal loads
    INTEGER(i4) :: n_bcs   = 0_i4  ! [IN]  number of prescribed BCs
    INTEGER(i4) :: amp_id  = 0_i4  ! [IN]  amplitude table ID (0 = none)
  CONTAINS
    PROCEDURE, PASS :: Init  => RT_LoadBC_Impl_Desc_Init
    PROCEDURE, PASS :: Clean => RT_LoadBC_Impl_Desc_Clean
  END TYPE RT_LoadBC_Impl_Desc
```

### `RT_LoadBC_Impl_State` (lines 44–60)

```fortran
  TYPE, PUBLIC :: RT_LoadBC_Impl_State
    !-- Base fields
    INTEGER(i4) :: num_ips = 0_i4
    LOGICAL :: state_committed = .FALSE.

    !-- Extended fields
    LOGICAL    :: load_applied      = .FALSE.  ! [OUT]  loads have been applied
    LOGICAL    :: bc_applied        = .FALSE.  ! [OUT]  BCs have been applied
    LOGICAL    :: cutback_active    = .FALSE.  ! [OUT]  cutback is in effect
    INTEGER(i4) :: total_cutbacks   = 0_i4     ! [INOUT] cumulative cutback count
    INTEGER(i4) :: total_iterations = 0_i4     ! [INOUT] cumulative iteration count
    REAL(wp)   :: current_amp       = 1.0_wp   ! [INOUT] current amplitude factor
    REAL(wp)   :: accumulated_work  = 0.0_wp   ! [INOUT] accumulated external work
  CONTAINS
    PROCEDURE, PASS :: Init  => RT_LoadBC_Impl_State_Init
    PROCEDURE, PASS :: Clean => RT_LoadBC_Impl_State_Clean
  END TYPE RT_LoadBC_Impl_State
```

### `RT_LoadBC_Impl_Algo` (lines 65–79)

```fortran
  TYPE, PUBLIC :: RT_LoadBC_Impl_Algo
    !-- Base fields
    INTEGER(i4) :: dispatch_strategy = 0_i4

    !-- Extended fields
    LOGICAL    :: auto_cutback_enabled  = .TRUE.    ! [IN]  enable automatic cutback
    INTEGER(i4) :: max_cutbacks         = 10_i4      ! [IN]  maximum number of cutbacks
    REAL(wp)   :: cutback_factor        = 0.5_wp     ! [IN]  load reduction factor per cutback
    REAL(wp)   :: min_load_increment    = 1.0e-6_wp  ! [IN]  minimum allowed load increment
    LOGICAL    :: adaptive_time_enabled = .FALSE.    ! [IN]  use adaptive time stepping
    INTEGER(i4) :: target_iterations     = 4_i4       ! [IN]  target iterations per increment
    REAL(wp)   :: load_convergence_tol   = 1.0e-6_wp  ! [IN]  tolerance for load convergence
  CONTAINS
    PROCEDURE, PASS :: Init => RT_LoadBC_Impl_Algo_Init
  END TYPE RT_LoadBC_Impl_Algo
```

### `RT_LoadBC_Impl_Ctx` (lines 84–103)

```fortran
  TYPE, PUBLIC :: RT_LoadBC_Impl_Ctx
    !-- Base fields
    INTEGER(i4) :: current_step = 0_i4
    INTEGER(i4) :: current_incr = 0_i4
    INTEGER(i4) :: current_iter = 0_i4

    !-- Extended fields
    INTEGER(i4) :: analysis_type     = RT_LOADBC_STATIC  ! [IN]  analysis type (static/dynamic/thermal)
    LOGICAL     :: nlgeom            = .FALSE.           ! [IN]  geometric nonlinearity flag
    REAL(wp)    :: time_increment    = 0.0_wp            ! [IN]  current time increment
    REAL(wp)    :: step_time         = 0.0_wp            ! [IN]  time elapsed in current step
    REAL(wp)    :: total_time        = 0.0_wp            ! [IN]  total simulation time
    LOGICAL     :: first_increment   = .TRUE.            ! [IN]  first increment in the step
    LOGICAL     :: last_increment    = .FALSE.           ! [IN]  last increment in the step
    INTEGER(i4) :: increment_number  = 0_i4              ! [IN]  increment number
    INTEGER(i4) :: iteration_number  = 0_i4              ! [IN]  iteration number
  CONTAINS
    PROCEDURE, PASS :: Init  => RT_LoadBC_Impl_Ctx_Init
    PROCEDURE, PASS :: Clean => RT_LoadBC_Impl_Ctx_Clean
  END TYPE RT_LoadBC_Impl_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_LoadBC_Impl_Desc_Init` | 111 | `SUBROUTINE RT_LoadBC_Impl_Desc_Init(this, mat_id, l4_slot)` |
| SUBROUTINE | `RT_LoadBC_Impl_Desc_Clean` | 122 | `SUBROUTINE RT_LoadBC_Impl_Desc_Clean(this)` |
| SUBROUTINE | `RT_LoadBC_Impl_State_Init` | 134 | `SUBROUTINE RT_LoadBC_Impl_State_Init(this, num_ips)` |
| SUBROUTINE | `RT_LoadBC_Impl_State_Clean` | 148 | `SUBROUTINE RT_LoadBC_Impl_State_Clean(this)` |
| SUBROUTINE | `RT_LoadBC_Impl_Algo_Init` | 165 | `SUBROUTINE RT_LoadBC_Impl_Algo_Init(this)` |
| SUBROUTINE | `RT_LoadBC_Impl_Ctx_Init` | 181 | `SUBROUTINE RT_LoadBC_Impl_Ctx_Init(this)` |
| SUBROUTINE | `RT_LoadBC_Impl_Ctx_Clean` | 197 | `SUBROUTINE RT_LoadBC_Impl_Ctx_Clean(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
