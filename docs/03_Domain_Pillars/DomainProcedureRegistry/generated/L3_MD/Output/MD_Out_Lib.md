# `MD_Out_Lib.f90`

- **Source**: `L3_MD/Output/MD_Out_Lib.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Out_Lib`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Out_Lib`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Out`
- **第四段角色（四段式）**: `_Lib`
- **源码子路径（层下目录，不含文件名）**: `Output`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Output/MD_Out_Lib.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MD_Out_AddField_Desc` (lines 126–131)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_Desc
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! Field output name
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
      INTEGER(i4) :: region_type = 0  ! Region type: 0=all, 1=nset, 2=elset
      INTEGER(i4) :: position = POS_INTEGRATION_POINT  ! Output position
    END TYPE MD_Out_AddField_Desc
```

### `MD_Out_AddField_Algo` (lines 134–139)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_Algo
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
      REAL(wp) :: time_interval = 0.0_wp  ! Time interval ?t ???^+ (0 = disabled)
      INTEGER(i4) :: num_time_marks = 0  ! Number of time marks ????
      REAL(wp), ALLOCATABLE :: time_marks(:)  ! Time marks t_i ???^+
    END TYPE MD_Out_AddField_Algo
```

### `MD_Out_AddField_Ctx` (lines 142–144)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_Ctx
      LOGICAL :: verbose = .FALSE.  ! Verbose output flag
    END TYPE MD_Out_AddField_Ctx
```

### `MD_Out_AddField_State` (lines 147–150)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_State
      INTEGER(i4) :: num_variables = 0  ! Number of variables added ????
      INTEGER(i4), ALLOCATABLE :: variables(:)  ! Variable IDs ???^+
    END TYPE MD_Out_AddField_State
```

### `MD_Out_AddField_In` (lines 153–158)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_In
      TYPE(MD_Out_AddField_Desc) :: desc
      TYPE(MD_Out_AddField_Algo) :: algo
      TYPE(MD_Out_AddField_Ctx) :: ctx
      TYPE(MD_Out_AddField_State) :: state
    END TYPE MD_Out_AddField_In
```

### `MD_Out_AddField_Out` (lines 161–165)

```fortran
    TYPE, PUBLIC :: MD_Out_AddField_Out
      INTEGER(i4) :: field_output_id = 0  ! Assigned field output ID ???^+
      TYPE(MD_Out_AddField_State) :: state
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_AddField_Out
```

### `MD_Out_AddHistory_In` (lines 168–172)

```fortran
    TYPE, PUBLIC :: MD_Out_AddHistory_In
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! History output name
      CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
    END TYPE MD_Out_AddHistory_In
```

### `MD_Out_AddHistory_Out` (lines 175–178)

```fortran
    TYPE, PUBLIC :: MD_Out_AddHistory_Out
      INTEGER(i4) :: history_output_id = 0  ! Assigned history output ID ???^+
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_AddHistory_Out
```

### `MD_Out_ShouldOutput_In` (lines 181–188)

```fortran
    TYPE, PUBLIC :: MD_Out_ShouldOutput_In
      INTEGER(i4) :: increment = 0  ! Current increment n ???^+
      REAL(wp) :: time = 0.0_wp  ! Current time t ????
      INTEGER(i4) :: frequency = 1  ! Output frequency (every N increments)
      REAL(wp) :: time_interval = 0.0_wp  ! Time interval ?t ???^+ (0 = disabled)
      INTEGER(i4) :: num_time_marks = 0  ! Number of time marks ????
      REAL(wp), ALLOCATABLE :: time_marks(:)  ! Time marks t_i ???^+
    END TYPE MD_Out_ShouldOutput_In
```

### `MD_Out_ShouldOutput_Out` (lines 191–194)

```fortran
    TYPE, PUBLIC :: MD_Out_ShouldOutput_Out
      LOGICAL :: should_output = .FALSE.  ! Whether to output at this increment/time
      TYPE(ErrorStatusType) :: status
    END TYPE MD_Out_ShouldOutput_Out
```

### `UF_OutputVar` (lines 202–209)

```fortran
    TYPE, PUBLIC :: UF_OutputVar
        INTEGER(i4) :: var_id = 0                    ! Variable ID ???^+
        CHARACTER(LEN=16) :: var_name = ""           ! Variable name (e.g., "U", "S", "E")
        INTEGER(i4) :: category = VAR_NODAL          ! Variable category: NODAL, ELEMENT, CONTACT, ENERGY
        INTEGER(i4) :: num_components = 1             ! Number of components ???^+
        LOGICAL :: is_tensor = .FALSE.                ! Is tensor variable (e.g., stress ?, strain ?)
        LOGICAL :: is_requested = .FALSE.             ! Is requested for output
    END TYPE UF_OutputVar
```

### `UF_FieldOutputDef` (lines 219–238)

```fortran
    TYPE, PUBLIC :: UF_FieldOutputDef
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! Field output name
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
        INTEGER(i4) :: region_type = 0          ! Region type: 0=all, 1=nset, 2=elset
        INTEGER(i4) :: position = POS_INTEGRATION_POINT  ! Output position: IP, centroid, node, element
        INTEGER(i4) :: frequency = 1            ! Output frequency: every N increments ???^+
        INTEGER(i4) :: time_interval = 0         ! Time interval flag (0=disabled, >0=enabled)
        REAL(wp) :: time_marks(100) = 0.0_wp    ! Time marks t_i ???^+ for output
        INTEGER(i4) :: num_time_marks = 0        ! Number of time marks ????
        INTEGER(i4) :: num_variables = 0         ! Number of variables ????
        INTEGER(i4) :: variables(MAX_VARIABLES) = 0  ! Variable IDs ???^+
        LOGICAL :: is_active = .TRUE.            ! Active flag
    CONTAINS
        PROCEDURE :: init => field_init
        PROCEDURE :: add_variable => field_add_variable
        PROCEDURE :: add_variables => field_add_variables
        PROCEDURE :: set_frequency => field_set_frequency
        PROCEDURE :: should_output => field_should_output
        PROCEDURE :: print_info => field_print_info
    END TYPE UF_FieldOutputDef
```

### `UF_HistoryOutputDef` (lines 249–261)

```fortran
    TYPE, PUBLIC :: UF_HistoryOutputDef
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: name = ""  ! History output name
        CHARACTER(LEN=MAX_OUTPUT_NAME) :: region_name = ""  ! Output region name
        INTEGER(i4) :: region_type = 0          ! Region type: 0=all, 1=nset, 2=elset
        INTEGER(i4) :: frequency = 1             ! Output frequency: every N increments ???^+
        INTEGER(i4) :: num_variables = 0         ! Number of variables ????
        INTEGER(i4) :: variables(MAX_VARIABLES) = 0  ! Variable IDs ???^+
        LOGICAL :: is_active = .TRUE.            ! Active flag
    CONTAINS
        PROCEDURE :: init         => history_def_init
        PROCEDURE :: add_variable => history_def_add_variable
        PROCEDURE :: print_info   => history_def_print_info
    END TYPE UF_HistoryOutputDef
```

### `UF_HistoryOutputState` (lines 269–279)

```fortran
    TYPE, PUBLIC :: UF_HistoryOutputState
        INTEGER(i4) :: max_points = 10000        ! Maximum number of time points ???^+
        INTEGER(i4) :: num_points = 0            ! Current number of points ????
        REAL(wp), ALLOCATABLE :: time_data(:)   ! Time array t_i ???^+
        REAL(wp), ALLOCATABLE :: value_data(:,:) ! Value array y_i ???^(nvars npoints)
    CONTAINS
        PROCEDURE :: init        => history_state_init
        PROCEDURE :: record_point => history_state_record_point
        PROCEDURE :: get_data    => history_state_get_data
        PROCEDURE :: destroy     => history_state_destroy
    END TYPE UF_HistoryOutputState
```

### `UF_OutputManager` (lines 288–310)

```fortran
    TYPE, PUBLIC :: UF_OutputManager
        INTEGER(i4) :: num_field = 0            ! Number of field outputs ????
        INTEGER(i4) :: num_history = 0           ! Number of history outputs ????
        TYPE(UF_FieldOutputDef), ALLOCATABLE :: fields(:)  ! Field output definitions
        TYPE(UF_HistoryOutputDef), ALLOCATABLE :: histories(:)  ! History output definitions
        TYPE(UF_HistoryOutputState), ALLOCATABLE :: history_states(:)  ! History output states
        ! Output format settings
        LOGICAL :: write_odb = .TRUE.           ! Write ODB format
        LOGICAL :: write_vtk = .FALSE.          ! Write VTK format
        LOGICAL :: write_csv = .FALSE.          ! Write CSV format
        LOGICAL :: write_dat = .FALSE.          ! Write DAT format
        LOGICAL :: write_txt = .FALSE.          ! Write TXT format
        CHARACTER(LEN=256) :: output_dir = "."  ! Output directory path
        CHARACTER(LEN=64) :: job_name = "Job-1" ! Job name (file prefix)
    CONTAINS

        PROCEDURE :: init => outmgr_init
        PROCEDURE :: add_field_output => outmgr_add_field
        PROCEDURE :: add_history_output => outmgr_add_history
        PROCEDURE :: get_field => outmgr_get_field
        PROCEDURE :: print_summary => outmgr_print_summary
        PROCEDURE :: destroy => outmgr_destroy
    END TYPE UF_OutputManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `field_init` | 325 | `SUBROUTINE field_init(this, name, region)` |
| SUBROUTINE | `field_add_variable` | 340 | `SUBROUTINE field_add_variable(this, var_id)` |
| SUBROUTINE | `field_add_variables` | 348 | `SUBROUTINE field_add_variables(this, var_ids, n)` |
| SUBROUTINE | `field_set_frequency` | 364 | `SUBROUTINE field_set_frequency(this, freq, interval)` |
| FUNCTION | `field_should_output` | 380 | `FUNCTION field_should_output(this, increment, timeVal) RESULT(should)` |
| SUBROUTINE | `field_print_info` | 424 | `SUBROUTINE field_print_info(this, unit_num)` |
| SUBROUTINE | `history_def_init` | 443 | `SUBROUTINE history_def_init(this, name, region)` |
| SUBROUTINE | `history_def_add_variable` | 459 | `SUBROUTINE history_def_add_variable(this, var_id)` |
| SUBROUTINE | `history_def_print_info` | 467 | `SUBROUTINE history_def_print_info(this, unit_num)` |
| SUBROUTINE | `history_state_init` | 480 | `SUBROUTINE history_state_init(this, max_pts, nvars)` |
| SUBROUTINE | `history_state_record_point` | 513 | `SUBROUTINE history_state_record_point(this, time, values)` |
| SUBROUTINE | `history_state_get_data` | 534 | `SUBROUTINE history_state_get_data(this, times, values, n)` |
| SUBROUTINE | `history_state_destroy` | 545 | `SUBROUTINE history_state_destroy(this)` |
| SUBROUTINE | `outmgr_init` | 563 | `SUBROUTINE outmgr_init(this, job_name, output_dir)` |
| SUBROUTINE | `outmgr_add_field` | 581 | `SUBROUTINE outmgr_add_field(this, field)` |
| SUBROUTINE | `outmgr_add_history` | 594 | `SUBROUTINE outmgr_add_history(this, history)` |
| FUNCTION | `outmgr_get_field` | 602 | `FUNCTION outmgr_get_field(this, name) RESULT(ptr)` |
| SUBROUTINE | `outmgr_print_summary` | 616 | `SUBROUTINE outmgr_print_summary(this, unit_num)` |
| SUBROUTINE | `outmgr_destroy` | 629 | `SUBROUTINE outmgr_destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
