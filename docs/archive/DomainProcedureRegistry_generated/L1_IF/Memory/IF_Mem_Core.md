# `IF_Mem_Core.f90`

- **Source**: `L1_IF/Memory/IF_Mem_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_Core`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_MemPool_Desc` (lines 82–86)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Desc
    CHARACTER(LEN=32) :: name      = ""
    INTEGER(i8)       :: cap_elems = 0_i8   ! capacity in REAL(wp) elements
    LOGICAL           :: isActive  = .FALSE.
  END TYPE IF_MemPool_Desc
```

### `IF_MemPool_Runtime` (lines 100–107)

```fortran
  TYPE, PUBLIC :: IF_MemPool_Runtime
    REAL(wp), ALLOCATABLE :: buf(:)          ! backing REAL(wp) store
    INTEGER(i4)           :: cap_elems   = 0_i4   ! mirror of Desc (i4 for hot path)
    INTEGER(i4)           :: used_elems  = 0_i4   ! HWM cursor
    INTEGER(i4)           :: peak_elems  = 0_i4   ! max used_elems seen
    INTEGER(i4)           :: n_allocs    = 0_i4   ! cumulative AllocFromPool calls
    LOGICAL               :: isActive    = .FALSE.
  END TYPE IF_MemPool_Runtime
```

### `IF_MemStats` (lines 112–118)

```fortran
  TYPE, PUBLIC :: IF_MemStats
    INTEGER(i8) :: totalAllocBytes = 0_i8   ! sum of all backing-buffer bytes
    INTEGER(i8) :: peakMem         = 0_i8   ! peak aggregate used bytes
    INTEGER(i4) :: nAllocs         = 0_i4   ! cumulative AllocFromPool calls
    INTEGER(i4) :: nResets         = 0_i4   ! cumulative ResetPool calls
    INTEGER(i4) :: nPools          = 0_i4   ! active pool count
  END TYPE IF_MemStats
```

### `IF_Memory_Domain` (lines 123–140)

```fortran
  TYPE, PUBLIC :: IF_Memory_Domain
    TYPE(IF_MemStats)                     :: stats
    TYPE(IF_MemPool_Desc),    ALLOCATABLE :: pool_descs(:)   ! config
    TYPE(IF_MemPool_Runtime), ALLOCATABLE :: pool_rt(:)      ! runtime
    INTEGER(i4) :: maxPools    = 16_i4
    INTEGER(i4) :: nPools      = 0_i4
    LOGICAL     :: enMemPool   = .TRUE.
    LOGICAL     :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: CreatePool
    PROCEDURE :: AllocFromPool
    PROCEDURE :: AllocFromPoolById
    PROCEDURE :: ResetPool
    PROCEDURE :: GetStats
    PROCEDURE :: PrintReport
  END TYPE IF_Memory_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `IF_FindPool` | 152 | `PURE FUNCTION IF_FindPool(this, pool_name) RESULT(idx)` |
| SUBROUTINE | `Init` | 169 | `SUBROUTINE Init(this, maxPools, enMemPool, status)` |
| SUBROUTINE | `Finalize` | 191 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `CreatePool` | 238 | `SUBROUTINE CreatePool(this, pool_name, cap_elems, status)` |
| SUBROUTINE | `AllocFromPool` | 303 | `SUBROUTINE AllocFromPool(this, pool_name, n_elems, &` |
| SUBROUTINE | `AllocFromPoolById` | 348 | `SUBROUTINE AllocFromPoolById(this, pool_idx, n_elems, start_idx, status)` |
| SUBROUTINE | `ResetPool` | 397 | `SUBROUTINE ResetPool(this, pool_name, status)` |
| SUBROUTINE | `GetStats` | 423 | `SUBROUTINE GetStats(this, stats_out)` |
| SUBROUTINE | `PrintReport` | 443 | `SUBROUTINE PrintReport(this, unit)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
