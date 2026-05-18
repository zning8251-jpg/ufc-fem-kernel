# `IF_AI_Def.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_AI_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_AI_Model_Desc_Path` (lines 19–23)

```fortran
    TYPE, PUBLIC :: IF_AI_Model_Desc_Path
    CHARACTER(LEN=256) :: model_path        ! model file path
    CHARACTER(LEN=64)  :: model_name        ! model name
    CHARACTER(LEN=64)  :: model_version     ! model version
  END TYPE IF_AI_Model_Desc_Path
```

### `IF_AI_Model_Desc_Format` (lines 25–27)

```fortran
  TYPE, PUBLIC :: IF_AI_Model_Desc_Format
    CHARACTER(LEN=64)  :: format            ! format(ONNX/PT)
  END TYPE IF_AI_Model_Desc_Format
```

### `IF_AI_Model_Desc_Dim` (lines 29–32)

```fortran
  TYPE, PUBLIC :: IF_AI_Model_Desc_Dim
    INTEGER(i4) :: input_dim                ! input dimension
    INTEGER(i4) :: output_dim               ! output dimension
  END TYPE IF_AI_Model_Desc_Dim
```

### `IF_AI_Model_Desc_Params` (lines 34–36)

```fortran
  TYPE, PUBLIC :: IF_AI_Model_Desc_Params
    INTEGER(i4) :: n_parameters             ! parameter count
  END TYPE IF_AI_Model_Desc_Params
```

### `IF_AI_Model_Desc_Flags` (lines 38–40)

```fortran
  TYPE, PUBLIC :: IF_AI_Model_Desc_Flags
    LOGICAL :: is_quantized                 ! quantized flag(INT8/FP16)
  END TYPE IF_AI_Model_Desc_Flags
```

### `IF_AI_Model_Desc` (lines 42–48)

```fortran
  TYPE, PUBLIC :: IF_AI_Model_Desc
    TYPE(IF_AI_Model_Desc_Path)   :: path
    TYPE(IF_AI_Model_Desc_Format) :: fmt
    TYPE(IF_AI_Model_Desc_Dim)    :: dim
    TYPE(IF_AI_Model_Desc_Params) :: params
    TYPE(IF_AI_Model_Desc_Flags)  :: flags
  END TYPE IF_AI_Model_Desc
```

### `IF_AI_Infer_State_Count` (lines 51–53)

```fortran
    TYPE, PUBLIC :: IF_AI_Infer_State_Count
    INTEGER(i4) :: n_inferences             ! inference count
  END TYPE IF_AI_Infer_State_Count
```

### `IF_AI_Infer_State_Timing` (lines 55–58)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_State_Timing
    REAL(wp) :: last_inference_time_ms      ! last inference time(ms)
    REAL(wp) :: avg_inference_time_ms       ! avg inference time(ms)
  END TYPE IF_AI_Infer_State_Timing
```

### `IF_AI_Infer_State_Cache` (lines 60–64)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_State_Cache
    INTEGER(i4) :: cache_hits               ! cache hits
    INTEGER(i4) :: cache_misses             ! cache misses
    REAL(wp) :: cache_hit_rate              ! cache hit rate
  END TYPE IF_AI_Infer_State_Cache
```

### `IF_AI_Infer_State_Flags` (lines 66–68)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_State_Flags
    LOGICAL :: is_ready                     ! ready flag
  END TYPE IF_AI_Infer_State_Flags
```

### `IF_AI_Infer_State_Err` (lines 70–72)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_State_Err
    INTEGER(i4) :: error_count              ! error count
  END TYPE IF_AI_Infer_State_Err
```

### `IF_AI_Infer_State` (lines 74–80)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_State
    TYPE(IF_AI_Infer_State_Count)  :: count
    TYPE(IF_AI_Infer_State_Timing) :: timing
    TYPE(IF_AI_Infer_State_Cache)  :: cache
    TYPE(IF_AI_Infer_State_Flags)  :: flags
    TYPE(IF_AI_Infer_State_Err)    :: err
  END TYPE IF_AI_Infer_State
```

### `IF_AI_Infer_Algo_Provider` (lines 83–85)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Algo_Provider
    CHARACTER(LEN=64)  :: execution_provider ! 执行提供者(CPU/CUDA/TensorRT)
  END TYPE IF_AI_Infer_Algo_Provider
```

### `IF_AI_Infer_Algo_Batch` (lines 87–89)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Algo_Batch
    INTEGER(i4) :: batch_size               ! 批量大小
  END TYPE IF_AI_Infer_Algo_Batch
```

### `IF_AI_Infer_Algo_Cache` (lines 91–94)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Algo_Cache
    LOGICAL :: use_cache                    ! 是否启用缓存
    INTEGER(i4) :: cache_capacity           ! 缓存容量
  END TYPE IF_AI_Infer_Algo_Cache
```

### `IF_AI_Infer_Algo_Config` (lines 96–100)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Algo_Config
    REAL(wp) :: confidence_threshold        ! 置信度阈值
    LOGICAL :: enable_fp16                  ! 是否启用FP16推理
    INTEGER(i4) :: n_threads                ! 线程数
  END TYPE IF_AI_Infer_Algo_Config
```

### `IF_AI_Infer_Algo` (lines 102–107)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Algo
    TYPE(IF_AI_Infer_Algo_Provider) :: provider
    TYPE(IF_AI_Infer_Algo_Batch) :: batch
    TYPE(IF_AI_Infer_Algo_Cache) :: cache
    TYPE(IF_AI_Infer_Algo_Config) :: config
  END TYPE IF_AI_Infer_Algo
```

### `IF_AI_Infer_Ctx_Session` (lines 110–112)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Session
    INTEGER(i4) :: session_idx              ! 会话索引
  END TYPE IF_AI_Infer_Ctx_Session
```

### `IF_AI_Infer_Ctx_Buffers` (lines 114–117)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Buffers
    REAL(wp), ALLOCATABLE :: input_buffer(:)  ! 输入缓冲区
    REAL(wp), ALLOCATABLE :: output_buffer(:) ! 输出缓冲区
  END TYPE IF_AI_Infer_Ctx_Buffers
```

### `IF_AI_Infer_Ctx_Timing` (lines 119–123)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Ctx_Timing
    REAL(wp) :: start_time                  ! 开始时间
    REAL(wp) :: end_time                    ! 结束时间
    LOGICAL :: use_batch_mode               ! 是否批量模式
  END TYPE IF_AI_Infer_Ctx_Timing
```

### `IF_AI_Infer_Ctx` (lines 125–129)

```fortran
  TYPE, PUBLIC :: IF_AI_Infer_Ctx
    TYPE(IF_AI_Infer_Ctx_Session) :: session
    TYPE(IF_AI_Infer_Ctx_Buffers) :: buffers
    TYPE(IF_AI_Infer_Ctx_Timing) :: timing
  END TYPE IF_AI_Infer_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Model_Desc_Init` | 165 | `SUBROUTINE IF_AI_Model_Desc_Init(desc, model_path, model_name, input_dim, output_dim)` |
| SUBROUTINE | `IF_AI_Infer_State_Init` | 195 | `SUBROUTINE IF_AI_Infer_State_Init(state)` |
| SUBROUTINE | `IF_AI_Infer_Algo_Init` | 217 | `SUBROUTINE IF_AI_Infer_Algo_Init(algo, exec_provider, batch_size)` |
| SUBROUTINE | `IF_AI_Infer_Ctx_Init` | 242 | `SUBROUTINE IF_AI_Infer_Ctx_Init(ctx, session_idx)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
