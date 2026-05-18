# `MD_Amp_Def.f90`

- **Source**: `L3_MD/Analysis/Amplitude/MD_Amp_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Amp_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Amp_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Amp`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Amplitude`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Amplitude/MD_Amp_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Amp_Tabular_Desc` (lines 84–93)

```fortran
  TYPE, PUBLIC :: MD_Amp_Tabular_Desc
    CHARACTER(LEN=80)     :: amp_name       = ' '
    INTEGER(i4)           :: n_points       = 0_i4
    REAL(wp), ALLOCATABLE :: t_vals(:)
    REAL(wp), ALLOCATABLE :: a_vals(:)
    INTEGER(i4)           :: interp_method  = INTERP_LINEAR
    LOGICAL               :: smooth         = .FALSE.
    LOGICAL               :: extrapolate    = .FALSE.
    LOGICAL               :: is_active      = .FALSE.
  END TYPE MD_Amp_Tabular_Desc
```

### `MD_Amp_User_Desc` (lines 100–107)

```fortran
  TYPE, PUBLIC :: MD_Amp_User_Desc
    CHARACTER(LEN=80)     :: amp_name     = ' '
    LOGICAL               :: use_vuamp    = .FALSE.
    INTEGER(i4)           :: nprops       = 0_i4
    REAL(wp), ALLOCATABLE :: props(:)
    INTEGER(i4)           :: nsvars       = 0_i4
    LOGICAL               :: is_active    = .FALSE.
  END TYPE MD_Amp_User_Desc
```

### `MD_Amp_Periodic_Desc` (lines 114–123)

```fortran
  TYPE, PUBLIC :: MD_Amp_Periodic_Desc
    CHARACTER(LEN=80)     :: amp_name    = ' '
    INTEGER(i4)           :: n_terms     = 0_i4
    REAL(wp)              :: omega       = 0.0_wp
    REAL(wp)              :: t0          = 0.0_wp
    REAL(wp)              :: a0          = 0.0_wp
    REAL(wp), ALLOCATABLE :: a_coeff(:)
    REAL(wp), ALLOCATABLE :: b_coeff(:)
    LOGICAL               :: is_active   = .FALSE.
  END TYPE MD_Amp_Periodic_Desc
```

### `MD_Amp_Modulated_Desc` (lines 130–137)

```fortran
  TYPE, PUBLIC :: MD_Amp_Modulated_Desc
    CHARACTER(LEN=80) :: amp_name          = ' '
    CHARACTER(LEN=80) :: carrier_amp_name  = ' '
    CHARACTER(LEN=80) :: envelope_amp_name = ' '
    REAL(wp)          :: scale_carrier     = 1.0_wp
    REAL(wp)          :: scale_envelope    = 1.0_wp
    LOGICAL           :: is_active         = .FALSE.
  END TYPE MD_Amp_Modulated_Desc
```

### `MD_Amp_Algo` (lines 148–150)

```fortran
  TYPE, PUBLIC :: MD_Amp_Algo
    INTEGER(i4) :: interpolation_method = INTERP_LINEAR
  END TYPE MD_Amp_Algo
```

### `MD_Amp_Desc` (lines 161–195)

```fortran
  TYPE, PUBLIC :: MD_Amp_Desc
    CHARACTER(LEN=64) :: name       = ""
    INTEGER(i4)       :: amp_id     = 0_i4
    INTEGER(i4)       :: amp_type   = AMP_TABULAR
    INTEGER(i4)       :: definition = 0_i4
    REAL(wp), ALLOCATABLE :: time_data(:)
    REAL(wp), ALLOCATABLE :: value_data(:)
    INTEGER(i4)           :: n_points = 0_i4
    LOGICAL               :: smooth   = .FALSE.
    REAL(wp)              :: omega       = 0.0_wp
    REAL(wp)              :: periodic_t0 = 0.0_wp
    INTEGER(i4)           :: n_fourier   = 0_i4
    REAL(wp), ALLOCATABLE :: fourier_a(:)
    REAL(wp), ALLOCATABLE :: fourier_b(:)
    REAL(wp) :: decay_a0 = 0.0_wp
    REAL(wp) :: decay_a1 = 1.0_wp
    REAL(wp) :: decay_t0 = 0.0_wp
    REAL(wp) :: decay_td = 1.0_wp
    ! AMP_MODULATED (aligned with MD_Amp_Slot_Desc / MD_Amp_Desc):
    ! A(t) = mod_carr_amp*sin(2*pi*mod_carr_freq*t + mod_carr_phase) * [1 + mod_depth*sin(2*pi*mod_fm*t)]
    REAL(wp) :: mod_carr_freq  = 0.0_wp
    REAL(wp) :: mod_carr_amp   = 0.0_wp
    REAL(wp) :: mod_carr_phase = 0.0_wp
    REAL(wp) :: mod_fm        = 0.0_wp
    REAL(wp) :: mod_depth     = 0.0_wp
    ! Tabular: match MD_Amp_Slot_Desc%tabular_extrapolate when filled from Sync/API
    LOGICAL :: tabular_extrapolate = .FALSE.
    INTEGER(i4) :: interp_method = INTERP_LINEAR  ! Interpolation: LINEAR/SMOOTH/STEP
    ! Native AMP_SMOOTH / AMP_RAMP (avoid relying on tabular compression)
    REAL(wp) :: smooth_t1 = 0.0_wp
    REAL(wp) :: smooth_t2 = 1.0_wp
    REAL(wp) :: smooth_a1 = 0.0_wp
    REAL(wp) :: smooth_a2 = 1.0_wp
    REAL(wp) :: ramp_t_end = 1.0_wp
  END TYPE MD_Amp_Desc
```

### `MD_Amp_Inc_Evo_State` (lines 206–209)

```fortran
  TYPE, PUBLIC :: MD_Amp_Inc_Evo_State
    INTEGER(i4) :: step_idx  = 0_i4
    INTEGER(i4) :: incr_idx = 0_i4
  END TYPE MD_Amp_Inc_Evo_State
```

### `MD_Amp_State` (lines 216–221)

```fortran
  TYPE, PUBLIC :: MD_Amp_State
    REAL(wp)    :: currentValue = 0.0_wp
    REAL(wp)    :: currentTime  = 0.0_wp
    INTEGER(i4) :: currentIndex = 1_i4
    TYPE(MD_Amp_Inc_Evo_State) :: inc
  END TYPE MD_Amp_State
```

### `MD_Amp_Desc_Cfg_View` (lines 227–236)

```fortran
  TYPE, PUBLIC :: MD_Amp_Desc_Cfg_View
    CHARACTER(LEN=64) :: name = ""
    INTEGER(i4)       :: amp_id = 0_i4
    INTEGER(i4)       :: amp_type = 0_i4
    INTEGER(i4)       :: definition = 0_i4
    INTEGER(i4)       :: n_points = 0_i4
    LOGICAL           :: smooth = .FALSE.
    LOGICAL           :: tabular_extrapolate = .FALSE.
    INTEGER(i4)       :: interp_method = 0_i4
  END TYPE MD_Amp_Desc_Cfg_View
```

### `MD_Amp_Desc_Itr_View` (lines 238–256)

```fortran
  TYPE, PUBLIC :: MD_Amp_Desc_Itr_View
    REAL(wp)    :: omega = 0.0_wp
    REAL(wp)    :: periodic_t0 = 0.0_wp
    INTEGER(i4) :: n_fourier = 0_i4
    REAL(wp)    :: decay_a0 = 0.0_wp
    REAL(wp)    :: decay_a1 = 0.0_wp
    REAL(wp)    :: decay_t0 = 0.0_wp
    REAL(wp)    :: decay_td = 0.0_wp
    REAL(wp)    :: mod_carr_freq = 0.0_wp
    REAL(wp)    :: mod_carr_amp = 0.0_wp
    REAL(wp)    :: mod_carr_phase = 0.0_wp
    REAL(wp)    :: mod_fm = 0.0_wp
    REAL(wp)    :: mod_depth = 0.0_wp
    REAL(wp)    :: smooth_t1 = 0.0_wp
    REAL(wp)    :: smooth_t2 = 0.0_wp
    REAL(wp)    :: smooth_a1 = 0.0_wp
    REAL(wp)    :: smooth_a2 = 0.0_wp
    REAL(wp)    :: ramp_t_end = 0.0_wp
  END TYPE MD_Amp_Desc_Itr_View
```

### `MD_Amp_Desc_Pilot_Views` (lines 258–261)

```fortran
  TYPE, PUBLIC :: MD_Amp_Desc_Pilot_Views
    TYPE(MD_Amp_Desc_Cfg_View) :: cfg
    TYPE(MD_Amp_Desc_Itr_View) :: itr
  END TYPE MD_Amp_Desc_Pilot_Views
```

### `MD_Amp_GetSummary_Arg` (lines 272–275)

```fortran
  TYPE, PUBLIC :: MD_Amp_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_GetSummary_Arg
```

### `MD_Amp_Add_Arg` (lines 282–286)

```fortran
  TYPE, PUBLIC :: MD_Amp_Add_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [IN]  amplitude descriptor
    INTEGER(i4)           :: amp_idx = 0_i4 ! [OUT] assigned 1-based index on OK
    TYPE(ErrorStatusType) :: status         ! [OUT] AddAmplitude / capacity result
  END TYPE MD_Amp_Add_Arg
```

### `MD_Amp_Get_Arg` (lines 293–296)

```fortran
  TYPE, PUBLIC :: MD_Amp_Get_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [OUT] amplitude descriptor
    TYPE(ErrorStatusType) :: status         ! [OUT] range / init result
  END TYPE MD_Amp_Get_Arg
```

### `MD_Amp_EvalAtTime_Arg` (lines 303–309)

```fortran
  TYPE, PUBLIC :: MD_Amp_EvalAtTime_Arg
    REAL(wp)              :: time  = 0.0_wp   ! [IN]  query time t
    REAL(wp)              :: value = 0.0_wp  ! [OUT] A(t)
    INTEGER(i4)           :: step_idx = 0_i4 ! [IN]  trace only (Apply_* does not WriteBack)
    INTEGER(i4)           :: incr_idx = 0_i4 ! [IN]  trace only
    TYPE(ErrorStatusType) :: status            ! [OUT] EvalAtTime result
  END TYPE MD_Amp_EvalAtTime_Arg
```

### `MD_Amp_Domain` (lines 320–335)

```fortran
  TYPE, PUBLIC :: MD_Amp_Domain
    TYPE(MD_Amp_Desc), ALLOCATABLE  :: amplitudes(:)
    INTEGER(i4)                     :: n_amplitudes = 0_i4
    INTEGER(i4)                     :: capacity     = 0_i4
    TYPE(MD_Amp_State), ALLOCATABLE :: amp_state(:)
    TYPE(MD_Amp_Algo) :: algo
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: AddAmplitude => Add
    PROCEDURE :: GetAmplitude => Get
    PROCEDURE :: EvalAtTime
    PROCEDURE :: WriteBack
    PROCEDURE :: GetSummary
  END TYPE MD_Amp_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MD_AmpShared_TabularEval` | 344 | `PURE FUNCTION MD_AmpShared_TabularEval(np, td, vd, extrap, smooth, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_StepEval` | 405 | `PURE FUNCTION MD_AmpShared_StepEval(np, td, vd, extrap, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_SmoothStep` | 446 | `PURE FUNCTION MD_AmpShared_SmoothStep(t1, t2, a1, a2, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_RampUnit` | 464 | `PURE FUNCTION MD_AmpShared_RampUnit(t_end, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_Modulated` | 479 | `PURE FUNCTION MD_AmpShared_Modulated(carr_amp, fc, phase, fm, mdep, t, pi) RESULT(value)` |
| SUBROUTINE | `Init` | 491 | `SUBROUTINE Init(this, est_amplitudes, status)` |
| SUBROUTINE | `MD_Amp_DP_RegisterStructType` | 507 | `SUBROUTINE MD_Amp_DP_RegisterStructType(status)` |
| SUBROUTINE | `Finalize` | 617 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Add` | 626 | `SUBROUTINE Add(this, desc, status)` |
| SUBROUTINE | `Get` | 673 | `SUBROUTINE Get(this, idx, desc, status)` |
| SUBROUTINE | `EvalAtTime` | 688 | `SUBROUTINE EvalAtTime(this, idx, time, value, status)` |
| SUBROUTINE | `WriteBack` | 775 | `SUBROUTINE WriteBack(this, idx, currentValue, currentTime, currentIndex, &` |
| SUBROUTINE | `GetSummary` | 796 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Amp_Apply_Add_Arg` | 816 | `SUBROUTINE MD_Amp_Apply_Add_Arg(amp_dom, arg)` |
| SUBROUTINE | `MD_Amp_Apply_Get_Arg` | 827 | `SUBROUTINE MD_Amp_Apply_Get_Arg(amp_dom, amp_idx, arg)` |
| SUBROUTINE | `MD_Amp_Apply_EvalAtTime_Arg` | 838 | `SUBROUTINE MD_Amp_Apply_EvalAtTime_Arg(amp_dom, amp_idx, arg)` |
| SUBROUTINE | `MD_Amp_Apply_GetSummary_Arg` | 848 | `SUBROUTINE MD_Amp_Apply_GetSummary_Arg(amp_dom, arg)` |
| FUNCTION | `MD_Amp_Desc_Get_Cfg_View` | 859 | `PURE FUNCTION MD_Amp_Desc_Get_Cfg_View(d) RESULT(v)` |
| FUNCTION | `MD_Amp_Desc_Get_Itr_View` | 873 | `PURE FUNCTION MD_Amp_Desc_Get_Itr_View(d) RESULT(v)` |
| FUNCTION | `MD_Amp_Desc_Get_Pilot_Views` | 896 | `PURE FUNCTION MD_Amp_Desc_Get_Pilot_Views(d) RESULT(pv)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Cfg_View` | 904 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Cfg_View(d, v)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Itr_View` | 918 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Itr_View(d, v)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Pilot_Views` | 941 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Pilot_Views(d, pv)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
