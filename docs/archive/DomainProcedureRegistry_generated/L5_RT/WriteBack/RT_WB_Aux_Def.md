# `RT_WB_Aux_Def.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_WB_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Aux_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_WB_Stp_Ctl_Algo` (lines 27–47)

```fortran
  TYPE, PUBLIC :: RT_WB_Stp_Ctl_Algo
    ! --- Write trigger configuration ---
    INTEGER(i4) :: write_trigger      = RT_WB_WRITE_EVERY_INC
    LOGICAL     :: trigger_at_step_end = .TRUE.     ! Always write back at step end
    LOGICAL     :: trigger_at_analysis_end = .TRUE.  ! Always write back at analysis end

    ! --- Checkpoint strategy ---
    LOGICAL     :: save_checkpoint_on_write = .FALSE.  ! Auto-checkpoint on write-back
    INTEGER(i4) :: checkpoint_interval = 10_i4        ! Save checkpoint every N writes

    ! --- Validation control ---
    LOGICAL     :: validate_before_write = .TRUE.   ! Validate data before writing
    LOGICAL     :: checksum_enabled      = .FALSE.  ! Compute checksum for audit

    ! --- Override / last-chance ---
    LOGICAL     :: force_write_back   = .FALSE.     ! Override trigger check
    LOGICAL     :: suppress_all_wb    = .FALSE.     ! Suppress all write-back

    ! --- NaN handling policy ---
    INTEGER(i4) :: nan_policy = 0_i4  ! 0=truncate+warn, 1=skip, 2=abort
  END TYPE RT_WB_Stp_Ctl_Algo
```

### `RT_WB_Itr_Algo` (lines 57–80)

```fortran
  TYPE, PUBLIC :: RT_WB_Itr_Algo
    ! --- Buffer control ---
    LOGICAL     :: use_node_buffering  = .TRUE.     ! Enable node buffering
    LOGICAL     :: use_elem_buffering  = .TRUE.     ! Enable element buffering
    INTEGER(i4) :: node_buffer_capacity = 10000_i4  ! Max items in node buffer
    INTEGER(i4) :: elem_buffer_capacity = 5000_i4   ! Max items in element buffer

    ! --- Compression ---
    LOGICAL     :: compress_output     = .FALSE.    ! Compress write-back data
    INTEGER(i4) :: compression_level   = 6_i4       ! 1-9 (9=maximum)

    ! --- Parallel write-back ---
    LOGICAL     :: use_parallel_write   = .FALSE.   ! Enable parallel writes
    INTEGER(i4) :: n_write_threads     = 1_i4       ! Number of write threads

    ! --- Batching optimization ---
    LOGICAL     :: batch_small_writes  = .TRUE.     ! Batch small write operations
    INTEGER(i4) :: batch_threshold     = 100_i4     ! Batch writes smaller than this

    ! --- Audit configuration ---
    LOGICAL     :: audit_enabled       = .TRUE.     ! Enable write-back audit trail
    LOGICAL     :: detailed_audit      = .FALSE.    ! Include data values in audit
    INTEGER(i4) :: max_audit_records   = 10000_i4   ! Max audit records to keep
  END TYPE RT_WB_Itr_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
