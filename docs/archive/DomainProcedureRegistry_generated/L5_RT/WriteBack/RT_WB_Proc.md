# `RT_WB_Proc.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Proc.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_WB_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_WB_Init_Arg` (lines 36–53)

```fortran
  TYPE, PUBLIC :: RT_WB_Init_Arg
    !-- [IN]
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_total_dofs = 0_i4
    LOGICAL :: preallocate_buffers = .TRUE.
    LOGICAL :: enable_checkpointing = .FALSE.
    INTEGER(i4) :: max_checkpoints = 10_i4
    INTEGER(i4) :: n_threads = 1_i4
    INTEGER(i4) :: comm_rank = 0_i4
    INTEGER(i4) :: comm_size = 1_i4
    !-- [OUT]
    LOGICAL :: initialized = .FALSE.
    INTEGER(i4) :: buffer_memory_mb = 0_i4
    INTEGER(i4) :: checkpoint_slots_allocated = 0_i4
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Init_Arg
```

### `RT_WB_NodePos_Arg` (lines 60–72)

```fortran
  TYPE, PUBLIC :: RT_WB_NodePos_Arg
    !-- [IN]
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: node_idx = 0_i4
    REAL(wp) :: new_coords(3)
    LOGICAL :: return_old_coords = .TRUE.
    LOGICAL :: validate_before_write = .TRUE.
    !-- [OUT]
    REAL(wp) :: old_coords(3) = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_NodePos_Arg
```

### `RT_WB_NodeDisp_Arg` (lines 79–91)

```fortran
  TYPE, PUBLIC :: RT_WB_NodeDisp_Arg
    !-- [IN]
    INTEGER(i4) :: node_id = 0_i4
    INTEGER(i4) :: node_idx = 0_i4
    REAL(wp) :: new_disp(3)
    LOGICAL :: return_old_disp = .TRUE.
    LOGICAL :: use_batch_mode = .FALSE.
    !-- [OUT]
    REAL(wp) :: old_disp(3) = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_NodeDisp_Arg
```

### `RT_WB_ElemStress_Arg` (lines 98–112)

```fortran
  TYPE, PUBLIC :: RT_WB_ElemStress_Arg
    !-- [IN]
    INTEGER(i4) :: elem_id = 0_i4
    INTEGER(i4) :: elem_idx = 0_i4
    INTEGER(i4) :: gp_id = 0_i4
    REAL(wp) :: stress(6) = 0.0_wp
    LOGICAL :: compute_principal = .FALSE.
    LOGICAL :: use_buffering = .TRUE.
    !-- [OUT]
    REAL(wp) :: principal_stress(3) = 0.0_wp
    REAL(wp) :: von_mises = 0.0_wp
    LOGICAL :: write_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_ElemStress_Arg
```

### `RT_WB_Checkpoint_Arg` (lines 119–139)

```fortran
  TYPE, PUBLIC :: RT_WB_Checkpoint_Arg
    !-- [IN]
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: increment_id = 0_i4
    INTEGER(i4) :: iteration_id = 0_i4
    REAL(wp) :: time_val = 0.0_wp
    INTEGER(i4) :: operation = 0_i4    ! 0=Save, 1=Load, 2=Rollback
    CHARACTER(LEN=256) :: file_path = ''
    LOGICAL :: compute_checksum = .FALSE.
    LOGICAL :: compress_data = .FALSE.
    !-- [OUT]
    INTEGER(i4) :: checkpoint_id = 0_i4
    INTEGER(i4) :: loaded_step = 0_i4
    INTEGER(i4) :: loaded_increment = 0_i4
    REAL(wp) :: loaded_time = 0.0_wp
    REAL(wp) :: checksum = 0.0_wp
    LOGICAL :: checksum_valid = .FALSE.
    LOGICAL :: operation_successful = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Checkpoint_Arg
```

### `RT_WB_Write_Arg` (lines 146–157)

```fortran
  TYPE, PUBLIC :: RT_WB_Write_Arg
    !-- [IN]
    REAL(wp), ALLOCATABLE :: node_pos(:,:)
    REAL(wp), ALLOCATABLE :: node_disp(:,:)
    REAL(wp), ALLOCATABLE :: elem_stress(:,:)
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elems = 0_i4
    !-- [OUT]
    INTEGER(i4) :: bytes_written = 0_i4
    INTEGER(i4) :: status_code = 0_i4
    CHARACTER(LEN=256) :: message = ''
  END TYPE RT_WB_Write_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_WB_Init_Interface` | 163 | `SUBROUTINE RT_WB_Init_Interface(desc, state, algo, ctx, args)` |
| SUBROUTINE | `RT_WB_NodePos_Interface` | 174 | `SUBROUTINE RT_WB_NodePos_Interface(desc, state, algo, ctx, args)` |
| SUBROUTINE | `RT_WB_NodeDisp_Interface` | 185 | `SUBROUTINE RT_WB_NodeDisp_Interface(desc, state, algo, ctx, args)` |
| SUBROUTINE | `RT_WB_ElemStress_Interface` | 196 | `SUBROUTINE RT_WB_ElemStress_Interface(desc, state, algo, ctx, args)` |
| SUBROUTINE | `RT_WB_Checkpoint_Interface` | 207 | `SUBROUTINE RT_WB_Checkpoint_Interface(desc, state, algo, ctx, args)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
