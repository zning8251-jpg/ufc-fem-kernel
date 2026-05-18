# `RT_WB_Domain.f90`

- **Source**: `L5_RT/WriteBack/RT_WB_Domain.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_WB_Domain`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_WB_Domain`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_WB_Domain`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `WriteBack`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/WriteBack/RT_WB_Domain.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CheckpointStatus` (lines 94–105)

```fortran
  TYPE :: CheckpointStatus
    INTEGER(i4) :: id = 0
    INTEGER(i4) :: step = 0
    INTEGER(i4) :: increment = 0
    INTEGER(i4) :: iteration = 0
    REAL(wp) :: time = 0.0_wp
    REAL(wp) :: checksum = 0.0_wp
    LOGICAL  :: valid = .FALSE.
    CHARACTER(256) :: filepath = ''
    ! SaveCheckpoint u
    REAL(wp), ALLOCATABLE :: u(:)
  END TYPE CheckpointStatus
```

### `WriteBackAuditRecord` (lines 108–116)

```fortran
  TYPE :: WriteBackAuditRecord
    INTEGER(i4) :: record_id = 0
    INTEGER(i4) :: operation_type = 0     ! 1=write, 2=checkpoint, 3=rollback
    INTEGER(i4) :: target_step = 0
    REAL(wp) :: timestamp = 0.0_wp
    REAL(wp) :: data_checksum = 0.0_wp
    LOGICAL  :: success = .FALSE.
    CHARACTER(512) :: description = ''
  END TYPE WriteBackAuditRecord
```

### `WriteBackWhitelistEntry` (lines 119–124)

```fortran
  TYPE, PUBLIC :: WriteBackWhitelistEntry
    INTEGER(i4) :: target_type = 0
    CHARACTER(LEN=64) :: field_name = ""
    LOGICAL :: allow_partial = .FALSE.
    CHARACTER(LEN=128) :: description = ""
  END TYPE WriteBackWhitelistEntry
```

### `WriteBackCtx` (lines 127–136)

```fortran
  TYPE, PUBLIC :: WriteBackCtx
    INTEGER(i4) :: current_checkpoint_id = 0
    INTEGER(i4) :: max_checkpoints = 10
    INTEGER(i4) :: audit_count = 0
    LOGICAL  :: zero_trust_enabled = .TRUE.
    LOGICAL  :: audit_enabled = .TRUE.
    INTEGER(i4) :: audit_log_unit = -1
    TYPE(CheckpointStatus),      ALLOCATABLE :: checkpoints(:)
    TYPE(WriteBackAuditRecord),  ALLOCATABLE :: audit_log(:)
  END TYPE WriteBackCtx
```

### `RT_WriteBack_Domain` (lines 141–152)

```fortran
  TYPE, PUBLIC :: RT_WriteBack_Domain
    TYPE(WriteBackCtx), ALLOCATABLE :: ctx_pool(:)
    INTEGER(i4) :: pool_count = 0_i4
    LOGICAL     :: initialized = .FALSE.
    ! Whitelist (design doc Section 5)
    TYPE(WriteBackWhitelistEntry), ALLOCATABLE :: whitelist(:)
    INTEGER(i4) :: whitelist_count = 0_i4
    INTEGER(i4) :: global_version = 0_i4
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
  END TYPE RT_WriteBack_Domain
```

### `RT_WB_Init_Arg` (lines 155–160)

```fortran
  TYPE, PUBLIC :: RT_WB_Init_Arg
    INTEGER(i4) :: max_checkpoints = 10_i4
    LOGICAL :: zero_trust_enabled = .TRUE.
    INTEGER(i4) :: wb_idx = 0_i4   ! OUT: assigned index
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_Init_Arg
```

### `RT_WB_SaveCheckpoint_Arg` (lines 161–167)

```fortran
  TYPE, PUBLIC :: RT_WB_SaveCheckpoint_Arg
    INTEGER(i4) :: step = 0_i4
    INTEGER(i4) :: increment = 0_i4
    INTEGER(i4) :: iteration = 0_i4
    REAL(wp) :: time_val = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_SaveCheckpoint_Arg
```

### `RT_WB_NodePos_Arg` (lines 171–177)

```fortran
  TYPE, PUBLIC :: RT_WB_NodePos_Arg
    INTEGER(i4)           :: node_idx      = 0_i4      ! (IN) mesh (1-based)
    REAL(wp)              :: new_coords(3) = 0.0_wp   ! (IN) ?
    INTEGER(i4)           :: wb_idx        = 0_i4      ! (IN) WriteBack 0
    REAL(wp)              :: old_coords(3) = 0.0_wp   ! (OUT) ?
    TYPE(ErrorStatusType) :: status                   ! (OUT)
  END TYPE RT_WB_NodePos_Arg
```

### `RT_WB_NodeDisp_Arg` (lines 180–186)

```fortran
  TYPE, PUBLIC :: RT_WB_NodeDisp_Arg
    INTEGER(i4)           :: node_idx      = 0_i4
    REAL(wp)              :: new_disp(3)   = 0.0_wp
    INTEGER(i4)           :: wb_idx        = 0_i4
    REAL(wp)              :: old_disp(3)   = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeDisp_Arg
```

### `RT_WB_NodeDisp_Batch_Arg` (lines 189–194)

```fortran
  TYPE, PUBLIC :: RT_WB_NodeDisp_Batch_Arg
    REAL(wp),    ALLOCATABLE :: u(:)       ! (IN) nTotalEq
    INTEGER(i4) :: wb_idx    = 0_i4       ! (IN) WriteBack ?
    INTEGER(i4) :: n_written = 0_i4      ! (OUT) ?
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeDisp_Batch_Arg
```

### `RT_WB_ElemStress_Arg` (lines 197–203)

```fortran
  TYPE, PUBLIC :: RT_WB_ElemStress_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) (1-based)
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) ?(1-based)
    REAL(wp)    :: sigma(6) = 0.0_wp    ! (IN) Voigt [s11,s22,s33,s12,s23,s13]
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemStress_Arg
```

### `RT_WB_ElemStrain_Arg` (lines 206–212)

```fortran
  TYPE, PUBLIC :: RT_WB_ElemStrain_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) element index (1-based)
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) integration point index (1-based)
    REAL(wp)    :: epsilon(6) = 0.0_wp   ! (IN) Voigt strain [e11,e22,e33,e12,e23,e13]
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemStrain_Arg
```

### `RT_WB_ElemEplas_Arg` (lines 215–221)

```fortran
  TYPE, PUBLIC :: RT_WB_ElemEplas_Arg
    INTEGER(i4) :: elem_idx  = 0_i4      ! (IN) element index
    INTEGER(i4) :: ip_idx    = 0_i4      ! (IN) integration point
    REAL(wp)    :: eplas     = 0.0_wp    ! (IN) accumulated plastic strain (PEEQ)
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_ElemEplas_Arg
```

### `RT_WB_NodeAccel_Arg` (lines 224–230)

```fortran
  TYPE, PUBLIC :: RT_WB_NodeAccel_Arg
    INTEGER(i4)           :: node_idx    = 0_i4
    REAL(wp)              :: new_accel(3) = 0.0_wp
    INTEGER(i4)           :: wb_idx      = 0_i4
    REAL(wp)              :: old_accel(3) = 0.0_wp
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_NodeAccel_Arg
```

### `RT_WB_GPStateVar_Arg` (lines 233–240)

```fortran
  TYPE, PUBLIC :: RT_WB_GPStateVar_Arg
    INTEGER(i4) :: elem_idx  = 0_i4              ! (IN) element index
    INTEGER(i4) :: ip_idx    = 0_i4              ! (IN) integration point index
    INTEGER(i4) :: var_idx   = 0_i4              ! (IN) state variable index (1..nStateVars)
    REAL(wp)    :: var_value = 0.0_wp            ! (IN) state variable value
    INTEGER(i4) :: wb_idx    = 0_i4
    TYPE(ErrorStatusType) :: status
  END TYPE RT_WB_GPStateVar_Arg
```

### `RT_WB_CurrentTime_Arg` (lines 243–249)

```fortran
  TYPE, PUBLIC :: RT_WB_CurrentTime_Arg
    INTEGER(i4)           :: step_idx     = 0_i4    ! (IN) md_layer%step
    REAL(wp)              :: current_time = 0.0_wp  ! (IN)
    INTEGER(i4)           :: current_inc  = 0_i4    ! (IN)
    LOGICAL               :: is_complete  = .FALSE. ! (IN) Step ?
    TYPE(ErrorStatusType) :: status                 ! (OUT)
  END TYPE RT_WB_CurrentTime_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Init` | 256 | `SUBROUTINE Init(this, status)` |
| SUBROUTINE | `Finalize` | 312 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `WriteBack_Init` | 340 | `SUBROUTINE WriteBack_Init(max_checkpoints, zero_trust_enabled, ierr)` |
| SUBROUTINE | `WriteBack_Finalize` | 353 | `SUBROUTINE WriteBack_Finalize(ierr)` |
| SUBROUTINE | `WriteState` | 361 | `SUBROUTINE WriteState(state_data, state_size, target_step, ierr)` |
| SUBROUTINE | `SaveCheckpoint` | 372 | `SUBROUTINE SaveCheckpoint(step, increment, iteration, time_val, ierr)` |
| SUBROUTINE | `LoadCheckpoint` | 384 | `SUBROUTINE LoadCheckpoint(checkpoint_id, ierr)` |
| SUBROUTINE | `RollbackToCheckpoint` | 393 | `SUBROUTINE RollbackToCheckpoint(checkpoint_id, ierr)` |
| FUNCTION | `ValidateWriteBack` | 402 | `FUNCTION ValidateWriteBack(state_data, state_size) RESULT(valid)` |
| SUBROUTINE | `AuditWriteBack` | 417 | `SUBROUTINE AuditWriteBack(op_type, target_step, checksum, success, desc)` |
| SUBROUTINE | `RT_WriteBack_RegisterTarget` | 428 | `SUBROUTINE RT_WriteBack_RegisterTarget(domain, target_type, field_name, &` |
| FUNCTION | `RT_WriteBack_IsAllowed` | 466 | `FUNCTION RT_WriteBack_IsAllowed(domain, target_type, field_name) RESULT(allowed)` |
| SUBROUTINE | `RT_WriteBack_WriteNodeCoord_Idx` | 488 | `SUBROUTINE RT_WriteBack_WriteNodeCoord_Idx(domain, wb_idx, node_idx, new_coords, old_coords, status)` |
| SUBROUTINE | `RT_WriteBack_LogAudit_Idx` | 523 | `SUBROUTINE RT_WriteBack_LogAudit_Idx(domain, wb_idx, operation, target_id, old_value, new_value, status)` |
| SUBROUTINE | `RT_WriteBack_Init_Idx` | 566 | `SUBROUTINE RT_WriteBack_Init_Idx(domain, max_checkpoints, zero_trust_enabled, wb_idx, status)` |
| SUBROUTINE | `RT_WriteBack_SaveCheckpoint_Idx` | 611 | `SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx(domain, wb_idx, step, increment, iteration, time_val, status)` |
| SUBROUTINE | `RT_WriteBack_SaveCheckpoint_WithSolution_Idx` | 655 | `SUBROUTINE RT_WriteBack_SaveCheckpoint_WithSolution_Idx(domain, wb_idx, step, increment, iteration, time_val, u, status)` |
| SUBROUTINE | `RT_WriteBack_LoadCheckpoint_Idx` | 704 | `SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx(domain, wb_idx, cp_id, u_out, status)` |
| SUBROUTINE | `AuditWriteBack_Idx` | 744 | `SUBROUTINE AuditWriteBack_Idx(domain, wb_idx, op_type, target_step, checksum, success, desc)` |
| SUBROUTINE | `RT_WB_Init_Arg` | 772 | `SUBROUTINE RT_WB_Init_Arg(domain, arg)` |
| SUBROUTINE | `RT_WB_SaveCheckpoint_Arg` | 782 | `SUBROUTINE RT_WB_SaveCheckpoint_Arg(domain, wb_idx, arg)` |
| SUBROUTINE | `RT_WB_Init_Arg_Standalone` | 794 | `SUBROUTINE RT_WB_Init_Arg_Standalone(arg)` |
| SUBROUTINE | `RT_WriteBack_SaveCheckpoint_Idx_Standalone` | 805 | `SUBROUTINE RT_WriteBack_SaveCheckpoint_Idx_Standalone(wb_idx, arg, status)` |
| SUBROUTINE | `RT_WriteBack_LoadCheckpoint_Idx_Standalone` | 820 | `SUBROUTINE RT_WriteBack_LoadCheckpoint_Idx_Standalone(wb_idx, cp_id, u_out, status)` |
| FUNCTION | `ComputeChecksum` | 837 | `FUNCTION ComputeChecksum(data, size) RESULT(checksum)` |
| FUNCTION | `ValidateStateData` | 851 | `FUNCTION ValidateStateData(data, size, expected_checksum) RESULT(valid)` |
| SUBROUTINE | `RT_WriteBack_WriteNodeDisp_Idx` | 868 | `SUBROUTINE RT_WriteBack_WriteNodeDisp_Idx(domain, wb_idx, node_idx, new_disp, old_disp, status)` |
| SUBROUTINE | `RT_WriteBack_NodePos` | 905 | `SUBROUTINE RT_WriteBack_NodePos(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_NodePos_Idx` | 926 | `SUBROUTINE RT_WriteBack_NodePos_Idx(node_idx, arg, status)` |
| SUBROUTINE | `RT_WriteBack_NodeDisp_Idx` | 946 | `SUBROUTINE RT_WriteBack_NodeDisp_Idx(node_idx, arg, status)` |
| SUBROUTINE | `RT_WriteBack_NodeDisp_Batch_Idx` | 965 | `SUBROUTINE RT_WriteBack_NodeDisp_Batch_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_ElemStress_Idx` | 982 | `SUBROUTINE RT_WriteBack_ElemStress_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_CurrentTime_Idx` | 999 | `SUBROUTINE RT_WriteBack_CurrentTime_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_NodeDisp` | 1018 | `SUBROUTINE RT_WriteBack_NodeDisp(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_NodeDisp_Batch` | 1037 | `SUBROUTINE RT_WriteBack_NodeDisp_Batch(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_ElemStress` | 1081 | `SUBROUTINE RT_WriteBack_ElemStress(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_CurrentTime` | 1109 | `SUBROUTINE RT_WriteBack_CurrentTime(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_ElemStrain` | 1138 | `SUBROUTINE RT_WriteBack_ElemStrain(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_ElemStrain_Idx` | 1162 | `SUBROUTINE RT_WriteBack_ElemStrain_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_ElemEplas` | 1179 | `SUBROUTINE RT_WriteBack_ElemEplas(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_ElemEplas_Idx` | 1203 | `SUBROUTINE RT_WriteBack_ElemEplas_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_NodeAccel` | 1220 | `SUBROUTINE RT_WriteBack_NodeAccel(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_NodeAccel_Idx` | 1244 | `SUBROUTINE RT_WriteBack_NodeAccel_Idx(arg, status)` |
| SUBROUTINE | `RT_WriteBack_GPStateVar` | 1262 | `SUBROUTINE RT_WriteBack_GPStateVar(domain, arg)` |
| SUBROUTINE | `RT_WriteBack_GPStateVar_Idx` | 1287 | `SUBROUTINE RT_WriteBack_GPStateVar_Idx(arg, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
