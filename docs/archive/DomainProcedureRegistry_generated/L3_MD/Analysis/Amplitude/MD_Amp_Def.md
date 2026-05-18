# `MD_Amp_Def.f90`

- **Source**: `L3_MD/Analysis/Amplitude/MD_Amp_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Amp_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Amp_Def`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Amp`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Amplitude`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Amplitude/MD_Amp_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Amp_Tabular_Desc` (lines 53–62)

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

### `MD_Amp_User_Desc` (lines 69–76)

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

### `MD_Amp_Periodic_Desc` (lines 83–92)

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

### `MD_Amp_Modulated_Desc` (lines 99–106)

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

### `AmpAlgo` (lines 113–115)

```fortran
  TYPE, PUBLIC :: AmpAlgo
    INTEGER(i4) :: interpolation_method = INTERP_LINEAR
  END TYPE AmpAlgo
```

### `MD_Amp_Desc` (lines 122–156)

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
    ! AMP_MODULATED (aligned with MD_Amp_Slot_Desc / MD_Amplitude):
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

### `MD_Amp_Inc_Evo_State` (lines 161–164)

```fortran
  TYPE, PUBLIC :: MD_Amp_Inc_Evo_State
    INTEGER(i4) :: step_idx  = 0_i4
    INTEGER(i4) :: incr_idx = 0_i4
  END TYPE MD_Amp_Inc_Evo_State
```

### `MD_Amp_State` (lines 171–176)

```fortran
  TYPE, PUBLIC :: MD_Amp_State
    REAL(wp)    :: currentValue = 0.0_wp
    REAL(wp)    :: currentTime  = 0.0_wp
    INTEGER(i4) :: currentIndex = 1_i4
    TYPE(MD_Amp_Inc_Evo_State) :: inc
  END TYPE MD_Amp_State
```

### `MD_Amp_Desc_Cfg_View` (lines 181–190)

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

### `MD_Amp_Desc_Itr_View` (lines 192–210)

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

### `MD_Amp_Desc_Pilot_Views` (lines 212–215)

```fortran
  TYPE, PUBLIC :: MD_Amp_Desc_Pilot_Views
    TYPE(MD_Amp_Desc_Cfg_View) :: cfg
    TYPE(MD_Amp_Desc_Itr_View) :: itr
  END TYPE MD_Amp_Desc_Pilot_Views
```

### `MD_Amp_GetSummary_Arg` (lines 222–225)

```fortran
  TYPE, PUBLIC :: MD_Amp_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""
    TYPE(ErrorStatusType) :: status
  END TYPE MD_Amp_GetSummary_Arg
```

### `MD_Amp_Add_Arg` (lines 232–236)

```fortran
  TYPE, PUBLIC :: MD_Amp_Add_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [IN]  amplitude descriptor
    INTEGER(i4)           :: amp_idx = 0_i4 ! [OUT] assigned 1-based index on OK
    TYPE(ErrorStatusType) :: status         ! [OUT] AddAmplitude / capacity result
  END TYPE MD_Amp_Add_Arg
```

### `MD_Amp_Get_Arg` (lines 243–246)

```fortran
  TYPE, PUBLIC :: MD_Amp_Get_Arg
    TYPE(MD_Amp_Desc)     :: desc           ! [OUT] amplitude descriptor
    TYPE(ErrorStatusType) :: status         ! [OUT] range / init result
  END TYPE MD_Amp_Get_Arg
```

### `MD_Amp_EvalAtTime_Arg` (lines 253–259)

```fortran
  TYPE, PUBLIC :: MD_Amp_EvalAtTime_Arg
    REAL(wp)              :: time  = 0.0_wp   ! [IN]  query time t
    REAL(wp)              :: value = 0.0_wp  ! [OUT] A(t)
    INTEGER(i4)           :: step_idx = 0_i4 ! [IN]  trace only (Apply_* does not WriteBack)
    INTEGER(i4)           :: incr_idx = 0_i4 ! [IN]  trace only
    TYPE(ErrorStatusType) :: status            ! [OUT] EvalAtTime result
  END TYPE MD_Amp_EvalAtTime_Arg
```

### `MD_Amplitude_Domain` (lines 266–281)

```fortran
  TYPE, PUBLIC :: MD_Amplitude_Domain
    TYPE(MD_Amp_Desc), ALLOCATABLE  :: amplitudes(:)
    INTEGER(i4)                     :: n_amplitudes = 0_i4
    INTEGER(i4)                     :: capacity     = 0_i4
    TYPE(MD_Amp_State), ALLOCATABLE :: amp_state(:)
    TYPE(AmpAlgo) :: algo
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: Add
    PROCEDURE :: Get
    PROCEDURE :: EvalAtTime
    PROCEDURE :: WriteBack
    PROCEDURE :: GetSummary
  END TYPE MD_Amplitude_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `MD_AmpShared_TabularEval` | 286 | `PURE FUNCTION MD_AmpShared_TabularEval(np, td, vd, extrap, smooth, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_StepEval` | 347 | `PURE FUNCTION MD_AmpShared_StepEval(np, td, vd, extrap, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_SmoothStep` | 388 | `PURE FUNCTION MD_AmpShared_SmoothStep(t1, t2, a1, a2, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_RampUnit` | 406 | `PURE FUNCTION MD_AmpShared_RampUnit(t_end, t) RESULT(value)` |
| FUNCTION | `MD_AmpShared_Modulated` | 421 | `PURE FUNCTION MD_AmpShared_Modulated(carr_amp, fc, phase, fm, mdep, t, pi) RESULT(value)` |
| SUBROUTINE | `Init` | 429 | `SUBROUTINE Init(this, est_amplitudes, status)` |
| SUBROUTINE | `MD_Amp_DP_RegisterStructType` | 445 | `SUBROUTINE MD_Amp_DP_RegisterStructType(status)` |
| SUBROUTINE | `Finalize` | 555 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `Add` | 564 | `SUBROUTINE Add(this, desc, status)` |
| SUBROUTINE | `Get` | 611 | `SUBROUTINE Get(this, idx, desc, status)` |
| SUBROUTINE | `EvalAtTime` | 624 | `SUBROUTINE EvalAtTime(this, idx, time, value, status)` |
| SUBROUTINE | `WriteBack` | 711 | `SUBROUTINE WriteBack(this, idx, currentValue, currentTime, currentIndex, &` |
| SUBROUTINE | `GetSummary` | 732 | `SUBROUTINE GetSummary(this, arg)` |
| SUBROUTINE | `MD_Amp_Apply_Add_Arg` | 752 | `SUBROUTINE MD_Amp_Apply_Add_Arg(amp_dom, arg)` |
| SUBROUTINE | `MD_Amp_Apply_Get_Arg` | 763 | `SUBROUTINE MD_Amp_Apply_Get_Arg(amp_dom, amp_idx, arg)` |
| SUBROUTINE | `MD_Amp_Apply_EvalAtTime_Arg` | 774 | `SUBROUTINE MD_Amp_Apply_EvalAtTime_Arg(amp_dom, amp_idx, arg)` |
| SUBROUTINE | `MD_Amp_Apply_GetSummary_Arg` | 784 | `SUBROUTINE MD_Amp_Apply_GetSummary_Arg(amp_dom, arg)` |
| FUNCTION | `MD_Amp_Desc_Get_Cfg_View` | 795 | `PURE FUNCTION MD_Amp_Desc_Get_Cfg_View(d) RESULT(v)` |
| FUNCTION | `MD_Amp_Desc_Get_Itr_View` | 809 | `PURE FUNCTION MD_Amp_Desc_Get_Itr_View(d) RESULT(v)` |
| FUNCTION | `MD_Amp_Desc_Get_Pilot_Views` | 832 | `PURE FUNCTION MD_Amp_Desc_Get_Pilot_Views(d) RESULT(pv)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Cfg_View` | 840 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Cfg_View(d, v)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Itr_View` | 854 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Itr_View(d, v)` |
| SUBROUTINE | `MD_Amp_Desc_Apply_Pilot_Views` | 877 | `PURE SUBROUTINE MD_Amp_Desc_Apply_Pilot_Views(d, pv)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
