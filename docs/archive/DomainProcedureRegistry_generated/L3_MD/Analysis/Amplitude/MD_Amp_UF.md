# `MD_Amp_UF.f90`

- **Source**: `L3_MD/Analysis/Amplitude/MD_Amp_UF.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `MD_Amp_UF`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Amp_UF`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Amp`
- **第四段角色（四段式）**: `_UF`
- **源码子路径（层下目录，不含文件名）**: `Analysis/Amplitude`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Analysis/Amplitude/MD_Amp_UF.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Amplitude_Eval_Desc` (lines 51–57)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_Desc
      CHARACTER(LEN=MAX_AMPLITUDE_NAME) :: name = ""  ! Amplitude name
      INTEGER(i4) :: amp_type = AMP_TABULAR  ! Amplitude type
      INTEGER(i4) :: time_type = TIME_STEP  ! Time type (STEP or TOTAL)
      REAL(wp), ALLOCATABLE :: props(:)  ! User-defined properties array
      INTEGER(i4) :: num_props = 0_i4  ! Number of properties
    END TYPE MD_Amplitude_Eval_Desc
```

### `MD_Amplitude_Eval_Algo` (lines 64–68)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_Algo
      LOGICAL :: use_smooth_interp = .FALSE.  ! Use smooth interpolation
      LOGICAL :: extrapolate = .FALSE.  ! Allow extrapolation beyond data range
      INTEGER(i4) :: interpolation_method = 1_i4  ! Interpolation method (1=linear, 2=hermite)
    END TYPE MD_Amplitude_Eval_Algo
```

### `MD_Amplitude_Eval_Ctx` (lines 75–82)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_Ctx
      CHARACTER(LEN=256) :: instance_name = ""  ! Instance name
      REAL(wp), ALLOCATABLE :: coords(:)  ! Coordinate array (spatial-dependent amplitudes)
      INTEGER(i4) :: num_coords = 0_i4  ! Number of coordinates
      INTEGER(i4) :: increment = 0_i4  ! Increment number (legacy UAMP-style)
      INTEGER(i4) :: step_idx = 0_i4    ! Step index (align md_layer%step)
      INTEGER(i4) :: incr_idx = 0_i4    ! Substep / increment index
    END TYPE MD_Amplitude_Eval_Ctx
```

### `MD_Amplitude_Eval_State` (lines 89–92)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_State
      REAL(wp) :: time = 0.0_wp  ! Current time t (input)
      REAL(wp) :: amp_value = 0.0_wp  ! Amplitude value A(t) (output)
    END TYPE MD_Amplitude_Eval_State
```

### `MD_Amplitude_Eval_In` (lines 99–104)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_In
      TYPE(MD_Amplitude_Eval_Desc) :: desc
      TYPE(MD_Amplitude_Eval_Algo) :: algo
      TYPE(MD_Amplitude_Eval_Ctx) :: ctx
      TYPE(MD_Amplitude_Eval_State) :: state
    END TYPE MD_Amplitude_Eval_In
```

### `MD_Amplitude_Eval_Out` (lines 111–114)

```fortran
    TYPE, PUBLIC :: MD_Amplitude_Eval_Out
      TYPE(MD_Amplitude_Eval_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Amplitude_Eval_Out
```

### `MD_Amp_Ext_Desc` (lines 121–142)

```fortran
    TYPE, PUBLIC :: MD_Amp_Ext_Desc
      INTEGER(i4) :: amplitudeId = 0_i4
      CHARACTER(LEN=64) :: name = ""
      INTEGER(i4) :: amp_type = 1_i4
      REAL(wp), ALLOCATABLE :: time_points(:)
      REAL(wp), ALLOCATABLE :: amplitude_value(:)
      LOGICAL :: smooth = .FALSE.
      LOGICAL :: extrapolate = .FALSE.
      REAL(wp) :: smooth_t1 = 0.0_wp
      REAL(wp) :: smooth_t2 = 1.0_wp
      REAL(wp) :: smooth_a1 = 0.0_wp
      REAL(wp) :: smooth_a2 = 1.0_wp
      REAL(wp) :: ramp_t_end = 1.0_wp
      REAL(wp) :: periodic_freq = 1.0_wp
      REAL(wp) :: periodic_amp = 1.0_wp
      REAL(wp) :: periodic_phase = 0.0_wp
      REAL(wp) :: periodic_offset = 0.0_wp
      REAL(wp) :: decay_a0 = 1.0_wp
      REAL(wp) :: decay_rate = 1.0_wp
      REAL(wp) :: modulated_freq = 0.1_wp
      REAL(wp) :: modulated_depth = 0.5_wp
    END TYPE MD_Amp_Ext_Desc
```

### `MD_Amp_Slot_Desc` (lines 177–239)

```fortran
    TYPE :: MD_Amp_Slot_Desc
        CHARACTER(LEN=MAX_AMPLITUDE_NAME) :: name = ""  ! Amplitude name
        INTEGER(i4) :: id = 0_i4  ! Amplitude ID
        INTEGER(i4) :: amp_type = AMP_TABULAR  ! Amplitude type
        INTEGER(i4) :: time_type = TIME_STEP  ! Time type (STEP or TOTAL)
        
        ! Tabular data: (t_i, A_i) pairs for A(t) = linear interpolation
        INTEGER(i4) :: num_points = 0_i4  ! Number of data points
        REAL(wp), ALLOCATABLE :: time(:)  ! Time array t_i
        REAL(wp), ALLOCATABLE :: value(:)  ! Value array A_i
        
        ! Smooth step (Hermite): xi=(t-t1)/(t2-t1), s=xi^2*(3-2*xi), A=A1+s*(A2-A1)
        REAL(wp) :: smooth_t1 = 0.0_wp  ! Start time t1
        REAL(wp) :: smooth_t2 = 1.0_wp  ! End time t2
        REAL(wp) :: smooth_a1 = 0.0_wp  ! Start amplitude A1
        REAL(wp) :: smooth_a2 = 1.0_wp  ! End amplitude A2
        
        ! Periodic: A(t) = offset + amp*sin(2*pi*f*t + phase)
        REAL(wp) :: periodic_freq = 1.0_wp  ! Frequency f (Hz)
        REAL(wp) :: periodic_phase = 0.0_wp  ! Phase (radians)
        REAL(wp) :: periodic_amp = 1.0_wp  ! Sine amplitude
        REAL(wp) :: periodic_offset = 0.0_wp  ! DC offset
        
        ! Decay: A(t) = decay_a0 * exp(-decay_rate * t)
        REAL(wp) :: decay_a0 = 1.0_wp  ! Initial scale
        REAL(wp) :: decay_rate = 1.0_wp  ! Rate lambda
        ! Modulated: carrier * [1 + m*sin(2*pi*fm*t)]; align MD_Amp_Desc in MD_Amplitude_Def
        REAL(wp) :: modulated_freq = 0.1_wp   ! Modulation frequency f_m (Hz)
        REAL(wp) :: modulated_depth = 0.5_wp  ! Modulation depth m (often in [0,1])

        ! Ramp: A(t) = t/t_end in [0,t_end], then 1.0 (linear 0->1 in step)
        REAL(wp) :: ramp_t_end = 1.0_wp  ! Time at which ramp reaches 1.0
        
        ! Default value (before first time point)
        REAL(wp) :: default_value = 0.0_wp
        ! Tabular: linear extrapolation outside [t_1, t_N] when .true.; else clamp to endpoints
        LOGICAL :: tabular_extrapolate = .FALSE.
        
        ! INPUT file support (ABAQUS INPUT= parameter)
        CHARACTER(LEN=256) :: input_file = ""  ! External data file path
        LOGICAL :: from_input_file = .FALSE.  ! Data loaded from file?
        
        ! USER subroutine support (ABAQUS DEFINITION=USER)
        PROCEDURE(Amp_User_IF), POINTER, NOPASS :: user_subroutine => NULL()  ! Legacy interface
        PROCEDURE(Amp_User_IF_Structured), POINTER, NOPASS :: user_subroutine_structured => NULL()  ! Structured interface
        REAL(wp) :: user_props(20) = 0.0_wp  ! User-defined properties
        INTEGER(i4) :: num_user_props = 0_i4  ! Number of user properties
        LOGICAL :: is_user_defined = .FALSE.  ! Using USER subroutine?
        LOGICAL :: use_structured_interface = .FALSE.  ! Use structured interface?
        
    CONTAINS
        PROCEDURE :: init => amplitude_init
        PROCEDURE :: add_point => amplitude_add_point
        PROCEDURE :: set_tabular => amplitude_set_tabular
        PROCEDURE :: set_smooth_step => amplitude_set_smooth_step
        PROCEDURE :: set_periodic => amplitude_set_periodic
        PROCEDURE :: set_modulated => amplitude_set_modulated
        PROCEDURE :: set_ramp => amplitude_set_ramp
        PROCEDURE :: load_from_file => amplitude_load_from_file
        PROCEDURE :: set_user_subroutine => amplitude_set_user_sub
        PROCEDURE :: evaluate => amplitude_evaluate
        PROCEDURE :: clear => amplitude_clear
    END TYPE MD_Amp_Slot_Desc
```

### `MD_Amp_Slot_Ctx` (lines 246–256)

```fortran
    TYPE :: MD_Amp_Slot_Ctx
        INTEGER(i4) :: num_amplitudes = 0_i4  ! Number of amplitudes in database
        TYPE(MD_Amp_Slot_Desc), ALLOCATABLE :: amplitudes(:)  ! Array of amplitude definitions
    CONTAINS
        PROCEDURE :: init => ampdb_init
        PROCEDURE :: add_amplitude => ampdb_add_amplitude
        PROCEDURE :: find_by_name => ampdb_find_by_name
        PROCEDURE :: get_amplitude => ampdb_get_amplitude
        PROCEDURE :: evaluate => ampdb_evaluate
        PROCEDURE :: clear => ampdb_clear
    END TYPE MD_Amp_Slot_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Amp_User_IF_Structured` | 146 | `SUBROUTINE Amp_User_IF_Structured(in, out)` |
| SUBROUTINE | `Amp_User_IF` | 157 | `SUBROUTINE Amp_User_IF(amp_value, time, amp_name, num_props, props, &` |
| SUBROUTINE | `ampdb_add_amplitude` | 260 | `SUBROUTINE ampdb_add_amplitude(this, amp)` |
| SUBROUTINE | `ampdb_clear` | 280 | `SUBROUTINE ampdb_clear(this)` |
| FUNCTION | `ampdb_evaluate` | 287 | `FUNCTION ampdb_evaluate(this, name, t) RESULT(val)` |
| FUNCTION | `ampdb_find_by_name` | 301 | `FUNCTION ampdb_find_by_name(this, name) RESULT(idx)` |
| FUNCTION | `ampdb_get_amplitude` | 318 | `FUNCTION ampdb_get_amplitude(this, idx) RESULT(amp_ptr)` |
| SUBROUTINE | `ampdb_init` | 331 | `SUBROUTINE ampdb_init(this, capacity)` |
| SUBROUTINE | `amplitude_init` | 349 | `SUBROUTINE amplitude_init(this, name, amp_type)` |
| SUBROUTINE | `amplitude_add_point` | 369 | `SUBROUTINE amplitude_add_point(this, t, val)` |
| SUBROUTINE | `amplitude_clear` | 383 | `SUBROUTINE amplitude_clear(this)` |
| SUBROUTINE | `amplitude_load_from_file` | 392 | `SUBROUTINE amplitude_load_from_file(this, filename, success)` |
| SUBROUTINE | `amplitude_set_periodic` | 458 | `SUBROUTINE amplitude_set_periodic(this, freq, amp, phase, offset)` |
| SUBROUTINE | `amplitude_set_ramp` | 476 | `SUBROUTINE amplitude_set_ramp(this, t_end)` |
| SUBROUTINE | `amplitude_set_modulated` | 486 | `SUBROUTINE amplitude_set_modulated(this, carrier_freq, carrier_amp, phase, mod_freq, mod_depth)` |
| SUBROUTINE | `amplitude_set_smooth_step` | 507 | `SUBROUTINE amplitude_set_smooth_step(this, t1, t2, a1, a2)` |
| SUBROUTINE | `amplitude_set_tabular` | 523 | `SUBROUTINE amplitude_set_tabular(this, times, values)` |
| SUBROUTINE | `amplitude_set_user_sub` | 540 | `SUBROUTINE amplitude_set_user_sub(this, user_sub, props, num_props)` |
| FUNCTION | `amplitude_evaluate` | 574 | `FUNCTION amplitude_evaluate(this, t) RESULT(val)` |
| SUBROUTINE | `MD_Amp_FromExt` | 672 | `SUBROUTINE MD_Amp_FromExt(desc_amp, md_amplitude, status)` |
| SUBROUTINE | `MD_Amp_FromExt_Def` | 681 | `SUBROUTINE MD_Amp_FromExt_Def(desc_amp, md_ampdef, status)` |
| SUBROUTINE | `MD_Amp_FromExt_DB` | 743 | `SUBROUTINE MD_Amp_FromExt_DB(desc_amps, md_ampdb, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
