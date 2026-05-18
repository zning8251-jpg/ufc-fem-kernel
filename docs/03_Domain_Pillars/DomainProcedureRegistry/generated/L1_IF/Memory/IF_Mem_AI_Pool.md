# `IF_Mem_AI_Pool.f90`

- **Source**: `L1_IF/Memory/IF_Mem_AI_Pool.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Mem_AI_Pool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_AI_Pool`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_AI_Pool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_AI_Pool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AI_PoolConfig` (lines 22–29)

```fortran
  TYPE, PUBLIC :: AI_PoolConfig
    INTEGER(i4) :: arena_size_bytes  = 0
    INTEGER(i4) :: alignment         = IF_AI_POOL_ALIGN
    LOGICAL     :: gpu_mappable      = .FALSE.
    INTEGER(i4) :: n_slots           = 0
    INTEGER(i4) :: slot_input_size(IF_AI_POOL_MAX_SLOTS) = 0
    INTEGER(i4) :: slot_output_size(IF_AI_POOL_MAX_SLOTS) = 0
  END TYPE AI_PoolConfig
```

### `AI_PoolState` (lines 34–40)

```fortran
  TYPE, PUBLIC :: AI_PoolState
    LOGICAL     :: initialized = .FALSE.
    INTEGER(i4) :: allocated_bytes = 0
    INTEGER(i4) :: peak_bytes      = 0
    INTEGER(i4) :: n_allocs        = 0
    INTEGER(i4) :: n_frees         = 0
  END TYPE AI_PoolState
```

### `AI_MemPool` (lines 45–48)

```fortran
  TYPE, PUBLIC :: AI_MemPool
    TYPE(AI_PoolConfig) :: config
    TYPE(AI_PoolState)  :: state
  END TYPE AI_MemPool
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_AI_Pool_Init` | 59 | `SUBROUTINE IF_AI_Pool_Init(pool, config, status)` |
| SUBROUTINE | `IF_AI_Pool_Finalize` | 79 | `SUBROUTINE IF_AI_Pool_Finalize(pool, status)` |
| SUBROUTINE | `IF_AI_Pool_GetStats` | 93 | `SUBROUTINE IF_AI_Pool_GetStats(pool, allocated, peak, n_allocs, n_frees)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
