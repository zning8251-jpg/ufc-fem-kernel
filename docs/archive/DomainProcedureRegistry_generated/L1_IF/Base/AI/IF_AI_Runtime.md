# `IF_AI_Runtime.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_Runtime.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_AI_Runtime`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_Runtime`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI_Runtime`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_Runtime.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_AI_SessionConfig` (lines 22–39)

```fortran
  TYPE, PUBLIC :: IF_AI_SessionConfig
    ! Model configuration
    CHARACTER(LEN=256) :: model_path = ""
    CHARACTER(LEN=64)  :: execution_provider = "CPU" ! "CPU" / "CUDA" / "TensorRT"
    
    ! GPU configuration
    INTEGER(i4)        :: gpu_device_id = 0
    LOGICAL            :: enable_gpu_fp16 = .FALSE.   ! FP16 inference (2-4× speedup)
    REAL(wp)           :: gpu_memory_fraction = 0.9_wp
    
    ! Thread configuration
    INTEGER(i4)        :: intra_op_num_threads = 1    ! Intra-op threads
    INTEGER(i4)        :: inter_op_num_threads = 1    ! Inter-op threads
    
    ! Memory optimization
    LOGICAL            :: use_mem_arena = .TRUE.
    INTEGER(i8)        :: mem_arena_bytes = 0_i8      ! 0=auto, or specify bytes
  END TYPE IF_AI_SessionConfig
```

### `IF_AI_RuntimeState` (lines 42–48)

```fortran
  TYPE, PUBLIC :: IF_AI_RuntimeState
    INTEGER(i8) :: session_handle = 0_i8  ! Opaque pointer to OrtSession
    LOGICAL     :: is_initialized = .FALSE.
    CHARACTER(LEN=256) :: model_path = ""
    INTEGER(i4) :: input_dim = 0
    INTEGER(i4) :: output_dim = 0
  END TYPE IF_AI_RuntimeState
```

### `IF_AI_SessionPool` (lines 51–55)

```fortran
  TYPE, PUBLIC :: IF_AI_SessionPool
    TYPE(IF_AI_RuntimeState), ALLOCATABLE :: sessions(:)
    INTEGER(i4) :: pool_size = 0
    LOGICAL, ALLOCATABLE :: in_use(:)  ! Usage flags
  END TYPE IF_AI_SessionPool
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_CreateSession` | 73 | `SUBROUTINE IF_AI_CreateSession(config, state, status)` |
| SUBROUTINE | `IF_AI_RunSession` | 101 | `SUBROUTINE IF_AI_RunSession(state, input_buffer, output_buffer, status)` |
| SUBROUTINE | `IF_AI_RunSession_Batch` | 136 | `SUBROUTINE IF_AI_RunSession_Batch(state, batch_size, input_batch, &` |
| SUBROUTINE | `IF_AI_DestroySession` | 221 | `SUBROUTINE IF_AI_DestroySession(state, status)` |
| SUBROUTINE | `IF_AI_SessionPool_Init` | 240 | `SUBROUTINE IF_AI_SessionPool_Init(pool, config, pool_size, status)` |
| SUBROUTINE | `IF_AI_SessionPool_Acquire` | 276 | `SUBROUTINE IF_AI_SessionPool_Acquire(pool, slot_index, timeout_ms, status)` |
| SUBROUTINE | `IF_AI_SessionPool_Release` | 320 | `SUBROUTINE IF_AI_SessionPool_Release(pool, slot_index, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
