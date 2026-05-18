# `IF_AI_Mgr.f90`

- **Source**: `L1_IF/Base/AI/IF_AI_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_AI_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_AI_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_AI`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Base/AI`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/AI/IF_AI_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_AI_CacheEntry` (lines 29–35)

```fortran
  TYPE, PUBLIC :: IF_AI_CacheEntry
    INTEGER(i8) :: hash_key           ! 输入特征哈希键
    REAL(wp), ALLOCATABLE :: input(:)  ! 输入特征(用于碰撞检测)
    REAL(wp), ALLOCATABLE :: output(:) ! 输出预测(缓存结果)
    REAL(wp) :: timestamp             ! 缓存时间戳
    LOGICAL :: is_valid               ! 缓存有效性标志
  END TYPE IF_AI_CacheEntry
```

### `IF_AI_CacheManager` (lines 38–45)

```fortran
  TYPE, PUBLIC :: IF_AI_CacheManager
    TYPE(IF_AI_CacheEntry), ALLOCATABLE :: entries(:) ! 缓存条目数组
    INTEGER(i4) :: capacity                           ! 缓存容量
    INTEGER(i4) :: n_entries                          ! 当前条目数
    INTEGER(i4) :: hit_count                          ! 缓存命中次数
    INTEGER(i4) :: miss_count                         ! 缓存未命中次数
    REAL(wp) :: hit_rate                              ! 命中率
  END TYPE IF_AI_CacheManager
```

### `IF_AI_PerfStats` (lines 48–57)

```fortran
  TYPE, PUBLIC :: IF_AI_PerfStats
    INTEGER(i4) :: n_inferences           ! 推理次数
    REAL(wp) :: total_time_ms             ! 总耗时(毫秒)
    REAL(wp) :: avg_time_ms               ! 平均耗时(毫秒)
    REAL(wp) :: min_time_ms               ! 最小耗时(毫秒)
    REAL(wp) :: max_time_ms               ! 最大耗时(毫秒)
    REAL(wp) :: throughput_samples_per_s  ! 吞吐量(样本/秒)
    INTEGER(i4) :: n_gpu_inferences       ! GPU推理次数
    INTEGER(i4) :: n_cpu_inferences       ! CPU推理次数
  END TYPE IF_AI_PerfStats
```

### `IF_AI_Domain` (lines 60–76)

```fortran
  TYPE, PUBLIC :: IF_AI_Domain
    ! 会话管理
    TYPE(IF_AI_SessionPool) :: session_pool      ! 会话池
    INTEGER(i4) :: n_active_sessions             ! 活跃会话数
    
    ! 缓存管理
    TYPE(IF_AI_CacheManager) :: cache_mgr        ! 缓存管理器
    LOGICAL :: cache_enabled                     ! 缓存开关
    
    ! 性能统计
    TYPE(IF_AI_PerfStats) :: perf_stats          ! 性能统计
    LOGICAL :: perf_monitoring_enabled           ! 性能监控开关
    
    ! 域状态
    LOGICAL :: initialized                       ! 初始化标志
    CHARACTER(LEN=128) :: version                ! 版本号
  END TYPE IF_AI_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Domain_Init` | 94 | `SUBROUTINE IF_AI_Domain_Init(this, max_sessions, cache_capacity, status)` |
| SUBROUTINE | `IF_AI_Domain_Finalize` | 148 | `SUBROUTINE IF_AI_Domain_Finalize(this, status)` |
| SUBROUTINE | `IF_AI_Domain_Infer` | 183 | `SUBROUTINE IF_AI_Domain_Infer(this, session_idx, input_buffer, output_buffer, status)` |
| SUBROUTINE | `IF_AI_Domain_Infer_Batch` | 273 | `SUBROUTINE IF_AI_Domain_Infer_Batch(this, session_idx, batch_size, &` |
| SUBROUTINE | `IF_AI_Domain_ClearCache` | 320 | `SUBROUTINE IF_AI_Domain_ClearCache(this, status)` |
| SUBROUTINE | `IF_AI_Domain_GetPerfStats` | 359 | `SUBROUTINE IF_AI_Domain_GetPerfStats(this, stats, status)` |
| SUBROUTINE | `IF_AI_Domain_GetSummary` | 382 | `SUBROUTINE IF_AI_Domain_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
