# `NM_TimeInt_EventDet.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_EventDet.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_TimeInt_EventDet`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_EventDet`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt_EventDet`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_EventDet.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `TimeEvent_ID` (lines 47–50)

```fortran
    TYPE, PUBLIC :: TimeEvent_ID
    INTEGER(i4) :: event_type = NM_EVENT_NONE
    INTEGER(i4) :: event_id = 0_i4
  END TYPE TimeEvent_ID
```

### `TimeEvent_Data` (lines 52–55)

```fortran
  TYPE, PUBLIC :: TimeEvent_Data
    REAL(wp) :: event_time = ZERO
    REAL(wp) :: event_value = ZERO
  END TYPE TimeEvent_Data
```

### `TimeEvent_Tol` (lines 57–59)

```fortran
  TYPE, PUBLIC :: TimeEvent_Tol
    REAL(wp) :: event_tolerance = 1.0E-8_wp
  END TYPE TimeEvent_Tol
```

### `TimeEvent_Flags` (lines 61–64)

```fortran
  TYPE, PUBLIC :: TimeEvent_Flags
    LOGICAL :: is_triggered = .FALSE.
    LOGICAL :: is_processed = .FALSE.
  END TYPE TimeEvent_Flags
```

### `TimeEvent_Meta` (lines 66–68)

```fortran
  TYPE, PUBLIC :: TimeEvent_Meta
    CHARACTER(LEN=128) :: description = ""
  END TYPE TimeEvent_Meta
```

### `TimeEvent` (lines 70–76)

```fortran
  TYPE, PUBLIC :: TimeEvent
    TYPE(TimeEvent_ID)    :: id
    TYPE(TimeEvent_Data)  :: data
    TYPE(TimeEvent_Tol)   :: tol
    TYPE(TimeEvent_Flags) :: flags
    TYPE(TimeEvent_Meta)  :: meta
  END TYPE TimeEvent
```

### `EventDetector_Config_Flags` (lines 79–84)

```fortran
    TYPE, PUBLIC :: EventDetector_Config_Flags
    LOGICAL :: enable_contact_detection = .TRUE.
    LOGICAL :: enable_buckling_detection = .TRUE.
    LOGICAL :: enable_failure_detection = .TRUE.
    LOGICAL :: enable_zero_crossing = .TRUE.
  END TYPE EventDetector_Config_Flags
```

### `EventDetector_Config_Tol` (lines 86–90)

```fortran
  TYPE, PUBLIC :: EventDetector_Config_Tol
    REAL(wp) :: contact_tolerance = 1.0E-6_wp
    REAL(wp) :: buckling_tolerance = 1.0E-4_wp
    REAL(wp) :: zero_crossing_tolerance = 1.0E-10_wp
  END TYPE EventDetector_Config_Tol
```

### `EventDetector_Config_Ctrl` (lines 92–94)

```fortran
  TYPE, PUBLIC :: EventDetector_Config_Ctrl
    INTEGER(i4) :: max_events_per_step = 10_i4
  END TYPE EventDetector_Config_Ctrl
```

### `EventDetector_Config` (lines 96–100)

```fortran
  TYPE, PUBLIC :: EventDetector_Config
    TYPE(EventDetector_Config_Flags) :: flags
    TYPE(EventDetector_Config_Tol)   :: tol
    TYPE(EventDetector_Config_Ctrl)  :: ctrl
  END TYPE EventDetector_Config
```

### `EventDetector_State` (lines 103–109)

```fortran
  TYPE, PUBLIC :: EventDetector_State
    INTEGER(i4) :: n_events_detected = 0_i4
    INTEGER(i4) :: n_events_processed = 0_i4
    TYPE(TimeEvent), ALLOCATABLE :: event_history(:)
    INTEGER(i4) :: history_size = 0_i4
    INTEGER(i4) :: history_pos = 0_i4
  END TYPE EventDetector_State
```

### `Contact_Event_Data` (lines 112–118)

```fortran
  TYPE, PUBLIC :: Contact_Event_Data
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: surface_id = 0_i4
    REAL(wp) :: gap_distance = ZERO
    REAL(wp) :: contact_force = ZERO
    REAL(wp) :: penetration_depth = ZERO
  END TYPE Contact_Event_Data
```

### `Buckling_Event_Data` (lines 121–127)

```fortran
  TYPE, PUBLIC :: Buckling_Event_Data
    INTEGER(i4) :: element_id = 0_i4
    REAL(wp) :: critical_load = ZERO
    REAL(wp) :: current_load = ZERO
    REAL(wp) :: eigenvalue = ZERO
    INTEGER(i4) :: buckling_mode = 0_i4
  END TYPE Buckling_Event_Data
```

### `ZeroCrossing_Function` (lines 130–136)

```fortran
  TYPE, PUBLIC :: ZeroCrossing_Function
    INTEGER(i4) :: func_id = 0_i4
    REAL(wp) :: prev_value = ZERO
    REAL(wp) :: curr_value = ZERO
    REAL(wp) :: target_value = ZERO
    LOGICAL :: is_active = .FALSE.
  END TYPE ZeroCrossing_Function
```

### `EventDetection_Result` (lines 139–145)

```fortran
  TYPE, PUBLIC :: EventDetection_Result
    LOGICAL :: event_found = .FALSE.
    INTEGER(i4) :: n_events = 0_i4
    TYPE(TimeEvent), ALLOCATABLE :: events(:)
    REAL(wp) :: suggested_dt = ZERO
    INTEGER(i4) :: recommended_action = NM_ACTION_NONE
  END TYPE EventDetection_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_EventDetector_Init` | 190 | `SUBROUTINE NM_EventDetector_Init(state, max_history, status)` |
| SUBROUTINE | `NM_Detect_Events` | 219 | `SUBROUTINE NM_Detect_Events(config, state, dyn_state, t, dt, result, status)` |
| SUBROUTINE | `NM_Process_Events` | 274 | `SUBROUTINE NM_Process_Events(result, dt, action, status)` |
| SUBROUTINE | `NM_Detect_Events` | 322 | `SUBROUTINE NM_Detect_Events(config, dyn_state, t, dt, events, n_events, status)` |
| SUBROUTINE | `NM_Detect_Separation_Events` | 361 | `SUBROUTINE NM_Detect_Separation_Events(config, dyn_state, t, dt, events, n_events, status)` |
| FUNCTION | `NM_Check_Contact_Condition` | 402 | `FUNCTION NM_Check_Contact_Condition(pos1, pos2, radius1, radius2, tolerance) &` |
| SUBROUTINE | `NM_Handle_Contact_Event` | 419 | `SUBROUTINE NM_Handle_Contact_Event(event, dyn_state, status)` |
| SUBROUTINE | `NM_Detect_Buckling_Events` | 444 | `SUBROUTINE NM_Detect_Buckling_Events(config, dyn_state, t, dt, events, n_events, status)` |
| FUNCTION | `NM_Check_Buckling_Condition` | 484 | `FUNCTION NM_Check_Buckling_Condition(stiffness, geom_stiffness, tolerance) &` |
| SUBROUTINE | `NM_Handle_Buckling_Event` | 514 | `SUBROUTINE NM_Handle_Buckling_Event(event, dyn_state, status)` |
| FUNCTION | `NM_Detect_Zero_Crossing` | 536 | `FUNCTION NM_Detect_Zero_Crossing(func, prev_value, curr_value, tolerance) &` |
| SUBROUTINE | `NM_Reg_Zero_Crossing` | 552 | `SUBROUTINE NM_Reg_Zero_Crossing(func, func_id, target_value)` |
| SUBROUTINE | `NM_Update_Zero_Crossing` | 570 | `SUBROUTINE NM_Update_Zero_Crossing(func, new_value, crossing_detected)` |
| FUNCTION | `NM_Calc_Event_Time` | 594 | `FUNCTION NM_Calc_Event_Time(t_prev, t_curr, val_prev, val_curr, target) &` |
| FUNCTION | `NM_Get_Next_Event_Time` | 616 | `FUNCTION NM_Get_Next_Event_Time(state, current_time) RESULT(next_event_time)` |
| FUNCTION | `NM_Suggest_Step_For_Event` | 650 | `FUNCTION NM_Suggest_Step_For_Event(next_event_time, current_time, &` |
| SUBROUTINE | `NM_Add_Event_To_History` | 684 | `SUBROUTINE NM_Add_Event_To_History(state, event)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
