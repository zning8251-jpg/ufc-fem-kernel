# `AP_UI_JobMgr.f90`

- **Source**: `L6_AP/UI/AP_UI_JobMgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_UI_JobMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_UI_JobMgr`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_UI_JobMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `UI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/UI/AP_UI_JobMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UIJob` (lines 41–58)

```fortran
  type, public :: UIJob
    integer(i4) :: job_id = 0_i4                    ! Job ID ??
    character(len=64) :: job_name = ''              ! Job name
    character(len=256) :: inp_file = ''            ! INP file path
    character(len=256) :: model_file = ''           ! Model file path
    character(len=256) :: log_file = ''             ! Log file path
    character(len=256) :: result_file = ''         ! Result file path
    integer(i4) :: status = JOB_STATUS_PENDING      ! Job status ??
    real(wp) :: progress = 0.0_wp                   ! Progress p ?[0,1] ??
    integer(i4) :: current_step = 0_i4               ! Current step ??
    integer(i4) :: total_steps = 0_i4               ! Total steps n_steps ??
    integer(i4) :: current_increment = 0_i4          ! Current increment ??
    integer(i4) :: total_increments = 0_i4           ! Total increments n_inc ??
    real(wp) :: start_time = 0.0_wp                 ! Start time t_start ??
    real(wp) :: end_time = 0.0_wp                    ! End time t_end ??
    type(ModelTree), pointer :: model => null()     ! Model tree pointer
    logical :: auto_generate_i = .true.             ! Auto-generate INP flag
  end type UIJob
```

### `RT_JobMgr` (lines 65–83)

```fortran
  type, public :: RT_JobMgr
    type(TreeMgr), pointer :: tree_mgr => null()    ! Tree manager reference
    type(INPGenerator) :: inp_generator              ! INP generator instance
    type(UIJob), allocatable :: jobs(:)             ! Job array
    integer(i4) :: num_jobs = 0_i4                  ! Number of jobs n_jobs ??
    integer(i4) :: next_job_id = 1_i4               ! Next job ID ??
    LOGICAL :: init = .false.                       ! Initialization flag
  contains
    procedure, public :: Init => RT_JobMgr_Init
    procedure, public :: CreateJob => RT_JobMgr_Create
    procedure, public :: SubmitJob => RT_JobMgr_Submit
    procedure, public :: GetJobStatus => RT_JobMgr_GetStat
    procedure, public :: CancelJob => RT_JobMgr_Cancel
    procedure, public :: GetJobLog => RT_JobMgr_GetLog
    procedure, public :: MonitorJob => RT_JobMgr_Mon
    procedure, public :: GetJob => RT_JobMgr_Get
    procedure, public :: GetJobByName => RT_JobMgr_GetByName
    procedure, public :: UpdateJobProgress => RT_JobMgr_UpdateProg
  end type RT_JobMgr
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_JobMgr_Init` | 95 | `subroutine RT_JobMgr_Init(this, tree_mgr, status)` |
| SUBROUTINE | `RT_JobMgr_Create` | 123 | `subroutine RT_JobMgr_Create(this, job_name, model_tree, inp_file, &` |
| SUBROUTINE | `RT_JobMgr_Submit` | 206 | `subroutine RT_JobMgr_Submit(this, job_id, status)` |
| FUNCTION | `RT_JobMgr_GetStat` | 271 | `function RT_JobMgr_GetStat(this, job_id) result(status_code)` |
| SUBROUTINE | `RT_JobMgr_Cancel` | 290 | `subroutine RT_JobMgr_Cancel(this, job_id, status)` |
| FUNCTION | `RT_JobMgr_GetLog` | 337 | `function RT_JobMgr_GetLog(this, job_id) result(log_content)` |
| SUBROUTINE | `RT_JobMgr_Mon` | 372 | `subroutine RT_JobMgr_Mon(this, job_id, status)` |
| FUNCTION | `RT_JobMgr_Get` | 474 | `function RT_JobMgr_Get(this, job_id) result(job_ptr)` |
| FUNCTION | `RT_JobMgr_GetByName` | 495 | `function RT_JobMgr_GetByName(this, job_name) result(job_ptr)` |
| SUBROUTINE | `RT_JobMgr_UpdateProg` | 516 | `subroutine RT_JobMgr_UpdateProg(this, job_id, progress, &` |
| SUBROUTINE | `ParseLogFileProgress` | 537 | `subroutine ParseLogFileProgress(log_file, current_step, total_steps, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
