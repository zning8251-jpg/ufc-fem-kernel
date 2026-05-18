# `RT_WB_Def.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_WB_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_WB_Desc` (lines 69–103)

```fortran
  TYPE, PUBLIC :: RT_WB_Desc
    INTEGER(i4) :: runtime_id = 0_i4           ! Runtime instance ID
    CHARACTER(LEN=64) :: wb_label = ''         ! Write-back configuration label
    
    ! Write frequency
    INTEGER(i4) :: write_frequency = 1_i4      ! Write every N increments
    INTEGER(i4) :: write_trigger = RT_WB_WRITE_EVERY_INC
    
    ! Output content flags
    LOGICAL :: write_displacement = .TRUE.
    LOGICAL :: write_velocity = .FALSE.        ! Dynamic analysis only
    LOGICAL :: write_acceleration = .FALSE.    ! Dynamic analysis only
    LOGICAL :: write_stress = .TRUE.
    LOGICAL :: write_strain = .TRUE.
    LOGICAL :: write_reaction = .TRUE.
    LOGICAL :: write_contact_force = .FALSE.
    
    ! Output scope
    INTEGER(i4) :: output_scope = RT_WB_SCOPE_ALL
    INTEGER(i4), POINTER :: output_node_ids(:) => NULL()
    INTEGER(i4), POINTER :: output_element_ids(:) => NULL()
    
    ! Coordinate transformation
    LOGICAL :: use_local_coords = .FALSE.
    INTEGER(i4) :: local_coord_sys_id = 0_i4
    
    ! Status flags
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_active = .TRUE.
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetOutputFields
    PROCEDURE :: SetScope
  END TYPE RT_WB_Desc
```

### `RT_WB_ProgressState` (lines 110–138)

```fortran
  TYPE, PUBLIC :: RT_WB_ProgressState
    ! Write progress counters
    INTEGER(i4) :: last_write_step = 0_i4
    INTEGER(i4) :: last_write_increment = 0_i4
    INTEGER(i4) :: total_writes = 0_i4
    INTEGER(i4) :: current_write_count = 0_i4
    
    ! Data statistics
    INTEGER(i4) :: n_nodes_written = 0_i4
    INTEGER(i4) :: n_elements_written = 0_i4
    INTEGER(i4) :: n_gp_written = 0_i4
    INTEGER(i4) :: n_total_dofs = 0_i4
    
    ! Timing information
    REAL(wp) :: last_write_time = 0.0_wp
    REAL(wp) :: write_elapsed = 0.0_wp
    REAL(wp) :: avg_write_time = 0.0_wp
    
    ! Success/failure tracking
    LOGICAL :: last_write_successful = .TRUE.
    INTEGER(i4) :: n_write_failures = 0_i4
    TYPE(ErrorStatusType) :: last_error_status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: UpdateProgress
    PROCEDURE :: RecordWriteTime
  END TYPE RT_WB_ProgressState
```

### `RT_WB_BufferState` (lines 144–172)

```fortran
  TYPE, PUBLIC :: RT_WB_BufferState
    ! Buffer sizes
    INTEGER(i4) :: node_buffer_size = 0_i4
    INTEGER(i4) :: elem_buffer_size = 0_i4
    INTEGER(i4) :: gp_buffer_size = 0_i4
    
    ! Buffer usage tracking
    INTEGER(i4) :: nodes_in_buffer = 0_i4
    INTEGER(i4) :: elements_in_buffer = 0_i4
    INTEGER(i4) :: gps_in_buffer = 0_i4
    
    ! Flush control
    LOGICAL :: buffer_needs_flush = .FALSE.
    INTEGER(i4) :: flush_threshold = 1000_i4   ! Flush when buffer reaches this count
    
    ! Memory management
    INTEGER(i4) :: total_allocations = 0_i4
    INTEGER(i4) :: total_deallocations = 0_i4
    INTEGER(i4) :: active_buffers = 0_i4
    
    ! Status
    LOGICAL :: buffers_allocated = .FALSE.
    TYPE(ErrorStatusType) :: status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
    PROCEDURE :: CheckFlush
  END TYPE RT_WB_BufferState
```

### `RT_WB_Algo` (lines 181–205)

```fortran
  TYPE, PUBLIC :: RT_WB_Algo
    !-- P2 sub-Algo composition --
    TYPE(RT_WB_Stp_Ctl_Algo) :: stp_ctl    ! [Phase:Stp|Verb:Ctl] trigger/strategy/validation
    TYPE(RT_WB_Itr_Algo)     :: itr_algo   ! [Phase:Itr|Verb:Com] buffer/compression/audit

    !-- Legacy flat fields (use stp_ctl / itr_algo for new code) --
    LOGICAL :: use_node_buffering = .TRUE.        ! (legacy, use itr_algo%use_node_buffering)
    LOGICAL :: use_elem_buffering = .TRUE.        ! (legacy, use itr_algo%use_elem_buffering)
    INTEGER(i4) :: node_buffer_capacity = 10000_i4  ! (legacy, use itr_algo%node_buffer_capacity)
    INTEGER(i4) :: elem_buffer_capacity = 5000_i4   ! (legacy, use itr_algo%elem_buffer_capacity)
    LOGICAL :: compress_output = .FALSE.        ! (legacy, use itr_algo%compress_output)
    INTEGER(i4) :: compression_level = 6_i4       ! (legacy, use itr_algo%compression_level)
    LOGICAL :: use_parallel_write = .FALSE.      ! (legacy, use itr_algo%use_parallel_write)
    INTEGER(i4) :: n_write_threads = 1_i4         ! (legacy, use itr_algo%n_write_threads)
    LOGICAL :: batch_small_writes = .TRUE.       ! (legacy, use itr_algo%batch_small_writes)
    INTEGER(i4) :: batch_threshold = 100_i4       ! (legacy, use itr_algo%batch_threshold)
    LOGICAL :: save_checkpoint_on_write = .FALSE.  ! (legacy, use stp_ctl%save_checkpoint_on_write)
    INTEGER(i4) :: checkpoint_interval = 10_i4     ! (legacy, use stp_ctl%checkpoint_interval)
    LOGICAL :: validate_before_write = .TRUE.    ! (legacy, use stp_ctl%validate_before_write)
    LOGICAL :: checksum_enabled = .FALSE.        ! (legacy, use stp_ctl%checksum_enabled)

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetBufferStrategy
  END TYPE RT_WB_Algo
```

### `RT_WB_Ctx` (lines 211–250)

```fortran
  TYPE, PUBLIC :: RT_WB_Ctx
    ! Temporary buffers (POINTER to pre-allocated arrays)
    REAL(wp), POINTER :: u_buffer(:) => NULL()      ! Displacement buffer
    REAL(wp), POINTER :: v_buffer(:) => NULL()      ! Velocity buffer
    REAL(wp), POINTER :: a_buffer(:) => NULL()      ! Acceleration buffer
    REAL(wp), POINTER :: stress_buffer(:) => NULL() ! Stress buffer [n_elem*6]
    REAL(wp), POINTER :: strain_buffer(:) => NULL() ! Strain buffer [n_elem*6]
    REAL(wp), POINTER :: rf_buffer(:) => NULL()     ! Reaction force buffer
    
    ! Work arrays (pre-allocated, 禁止 ALLOCATABLE)
    REAL(wp), POINTER :: work_array(:) => NULL()
    REAL(wp), POINTER :: temp_vector(:) => NULL()
    
    ! Current element/state pointers
    REAL(wp), POINTER :: elem_stress(:) => NULL()   ! Current element stress [6]
    REAL(wp), POINTER :: elem_strain(:) => NULL()   ! Current element strain [6]
    INTEGER(i4) :: current_elem_id = 0_i4
    INTEGER(i4) :: current_gp_id = 0_i4
    
    ! Current node/state pointers
    REAL(wp), POINTER :: node_disp(:) => NULL()     ! Current node displacement [3]
    REAL(wp), POINTER :: node_react(:) => NULL()    ! Current node reaction [3]
    INTEGER(i4) :: current_node_id = 0_i4
    
    ! Buffer management
    INTEGER(i4) :: buffer_size = 0_i4
    INTEGER(i4) :: buffer_offset = 0_i4
    LOGICAL :: buffer_needs_flush = .FALSE.
    
    ! Operation metadata
    INTEGER(i4) :: operation_type = 0_i4           ! RT_WB_TARGET_XXX
    INTEGER(i4) :: field_type = 0_i4               ! RT_WB_FIELD_XXX
    INTEGER(i4) :: n_items_to_write = 0_i4
    
  CONTAINS
    PROCEDURE :: AttachBuffers
    PROCEDURE :: ClearBuffers
    PROCEDURE :: FlushBuffer
    PROCEDURE :: Detach
  END TYPE RT_WB_Ctx
```

### `RT_WB_TransformCtx` (lines 256–283)

```fortran
  TYPE, PUBLIC :: RT_WB_TransformCtx
    ! Transformation matrices
    REAL(wp) :: rot_matrix(3,3) = 0.0_wp           ! Global �?Local
    REAL(wp) :: inv_rot_matrix(3,3) = 0.0_wp       ! Local �?Global
    LOGICAL :: rotation_available = .FALSE.
    
    ! Coordinate system info
    INTEGER(i4) :: coord_sys_type = 0_i4           ! 0=Cartesian, 1=Cylindrical, 2=Spherical
    INTEGER(i4) :: coord_sys_id = 0_i4
    
    ! Node-specific transformation
    INTEGER(i4) :: n_transform_nodes = 0_i4
    INTEGER(i4), POINTER :: transform_node_ids(:) => NULL()
    
    ! Temporary storage for transformed data
    REAL(wp) :: temp_global(3) = 0.0_wp
    REAL(wp) :: temp_local(3) = 0.0_wp
    
    ! Status
    LOGICAL :: transformation_active = .FALSE.
    TYPE(ErrorStatusType) :: status
    
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SetRotation
    PROCEDURE :: TransformVector
    PROCEDURE :: Reset
  END TYPE RT_WB_TransformCtx
```

### `RT_WB_State` (lines 569–571)

```fortran
  TYPE, PUBLIC :: RT_WB_State
    TYPE(RT_WB_ProgressState) :: progress
  END TYPE RT_WB_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `WB_Desc_Init` | 291 | `SUBROUTINE WB_Desc_Init(self)` |
| SUBROUTINE | `WB_Desc_SetOutputFields` | 305 | `SUBROUTINE WB_Desc_SetOutputFields(self, u, v, a, s, e, rf)` |
| SUBROUTINE | `WB_Desc_SetScope` | 318 | `SUBROUTINE WB_Desc_SetScope(self, scope, node_ids, elem_ids)` |
| SUBROUTINE | `WBProgress_Init` | 337 | `SUBROUTINE WBProgress_Init(self)` |
| SUBROUTINE | `WBProgress_Reset` | 350 | `SUBROUTINE WBProgress_Reset(self)` |
| SUBROUTINE | `WBProgress_UpdateProgress` | 359 | `SUBROUTINE WBProgress_UpdateProgress(self, step, incr, n_nodes, n_elems)` |
| SUBROUTINE | `WBProgress_RecordWriteTime` | 374 | `SUBROUTINE WBProgress_RecordWriteTime(self, elapsed_sec, success)` |
| SUBROUTINE | `WBBuffer_Init` | 399 | `SUBROUTINE WBBuffer_Init(self, node_cap, elem_cap)` |
| SUBROUTINE | `WBBuffer_Reset` | 413 | `SUBROUTINE WBBuffer_Reset(self)` |
| FUNCTION | `WBBuffer_CheckFlush` | 422 | `FUNCTION WBBuffer_CheckFlush(self) RESULT(needs_flush)` |
| SUBROUTINE | `WBAlgo_Init` | 442 | `SUBROUTINE WBAlgo_Init(self)` |
| SUBROUTINE | `WBAlgo_SetBufferStrategy` | 456 | `SUBROUTINE WBAlgo_SetBufferStrategy(self, use_node_buf, use_elem_buf, node_cap, elem_cap)` |
| SUBROUTINE | `WBCtx_AttachBuffers` | 472 | `SUBROUTINE WBCtx_AttachBuffers(self, u_buf, v_buf, a_buf, s_buf, e_buf, rf_buf)` |
| SUBROUTINE | `WBCtx_ClearBuffers` | 486 | `SUBROUTINE WBCtx_ClearBuffers(self)` |
| SUBROUTINE | `WBCtx_FlushBuffer` | 495 | `SUBROUTINE WBCtx_FlushBuffer(self)` |
| SUBROUTINE | `WBCtx_Detach` | 503 | `SUBROUTINE WBCtx_Detach(self)` |
| SUBROUTINE | `WBTransform_Init` | 521 | `SUBROUTINE WBTransform_Init(self)` |
| SUBROUTINE | `WBTransform_SetRotation` | 532 | `SUBROUTINE WBTransform_SetRotation(self, rot_mat)` |
| SUBROUTINE | `WBTransform_TransformVector` | 543 | `SUBROUTINE WBTransform_TransformVector(self, global_vec, local_vec)` |
| SUBROUTINE | `WBTransform_Reset` | 556 | `SUBROUTINE WBTransform_Reset(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
