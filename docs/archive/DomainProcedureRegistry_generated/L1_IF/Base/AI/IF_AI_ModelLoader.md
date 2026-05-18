# `IF_AI_ModelLoader.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_ModelLoader.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_AI_ModelLoader`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_ModelLoader`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI_ModelLoader`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_ModelLoader.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_AI_ModelMetadata_Info` (lines 21–28)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelMetadata_Info
    CHARACTER(LEN=256) :: model_name        ! 模型名称
    CHARACTER(LEN=64)  :: model_version     ! 模型版本
    CHARACTER(LEN=128) :: author            ! 作者
    CHARACTER(LEN=512) :: description       ! 描述
    CHARACTER(LEN=64)  :: format            ! 格式(ONNX/PT)
    INTEGER(i4) :: opset_version           ! ONNX opset版本
  END TYPE IF_AI_ModelMetadata_Info
```

### `IF_AI_ModelMetadata_IO` (lines 30–35)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelMetadata_IO
    INTEGER(i4) :: n_inputs                ! 输入数量
    INTEGER(i4) :: n_outputs               ! 输出数量
    INTEGER(i4), ALLOCATABLE :: input_dims(:,:)   ! 输入维度[n_inputs, max_dim]
    INTEGER(i4), ALLOCATABLE :: output_dims(:,:)  ! 输出维度[n_outputs, max_dim]
  END TYPE IF_AI_ModelMetadata_IO
```

### `IF_AI_ModelMetadata_Flags` (lines 37–39)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelMetadata_Flags
    LOGICAL :: is_valid                    ! 模型有效性标志
  END TYPE IF_AI_ModelMetadata_Flags
```

### `IF_AI_ModelMetadata` (lines 41–45)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelMetadata
    TYPE(IF_AI_ModelMetadata_Info) :: info
    TYPE(IF_AI_ModelMetadata_IO) :: io
    TYPE(IF_AI_ModelMetadata_Flags) :: flags
  END TYPE IF_AI_ModelMetadata
```

### `IF_AI_ModelCacheEntry` (lines 48–53)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelCacheEntry
    CHARACTER(LEN=256) :: model_path       ! 模型路径
    TYPE(IF_AI_ModelMetadata) :: metadata  ! 模型元数据
    REAL(wp) :: load_timestamp            ! 加载时间戳
    LOGICAL :: is_loaded                  ! 加载标志
  END TYPE IF_AI_ModelCacheEntry
```

### `IF_AI_ModelCache` (lines 56–60)

```fortran
  TYPE, PUBLIC :: IF_AI_ModelCache
    TYPE(IF_AI_ModelCacheEntry), ALLOCATABLE :: entries(:) ! 缓存条目
    INTEGER(i4) :: capacity                               ! 缓存容量
    INTEGER(i4) :: n_entries                              ! 当前条目数
  END TYPE IF_AI_ModelCache
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Model_Load` | 77 | `SUBROUTINE IF_AI_Model_Load(model_path, metadata, status)` |
| SUBROUTINE | `IF_AI_Model_Validate` | 133 | `SUBROUTINE IF_AI_Model_Validate(metadata, status)` |
| SUBROUTINE | `IF_AI_Model_GetMetadata` | 167 | `SUBROUTINE IF_AI_Model_GetMetadata(model_path, metadata, status)` |
| SUBROUTINE | `IF_AI_ModelCache_Init` | 195 | `SUBROUTINE IF_AI_ModelCache_Init(cache, capacity, status)` |
| SUBROUTINE | `IF_AI_ModelCache_Find` | 222 | `SUBROUTINE IF_AI_ModelCache_Find(cache, model_path, entry_idx, found, status)` |
| SUBROUTINE | `IF_AI_ModelCache_Add` | 262 | `SUBROUTINE IF_AI_ModelCache_Add(cache, model_path, metadata, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
