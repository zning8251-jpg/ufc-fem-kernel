# `MD_KW_MemPool.f90`

- **Source**: `L3_MD/KeyWord/MD_KW_MemPool.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_KW_MemPool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_KW_MemPool`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_KW_MemPool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `KeyWord`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/KeyWord/MD_KW_MemPool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RealMemoryPool` (lines 19–30)

```fortran
    TYPE, PUBLIC :: RealMemoryPool
        REAL(wp), ALLOCATABLE :: pool(:)
        INTEGER(i4) :: poolSize = DEFAULT_POOL_SIZE
        INTEGER(i4) :: currentIndex = 0
        INTEGER(i4) :: allocatedCount = 0
        LOGICAL :: initialized = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => RealMemoryPool_Init
        PROCEDURE, PUBLIC :: Allocate => RealMemoryPool_Allocate
        PROCEDURE, PUBLIC :: Reset => RealMemoryPool_Reset
        PROCEDURE, PUBLIC :: GetStats => RealMemoryPool_GetStats
    END TYPE RealMemoryPool
```

### `IntMemoryPool` (lines 33–44)

```fortran
    TYPE, PUBLIC :: IntMemoryPool
        INTEGER(i4), ALLOCATABLE :: pool(:)
        INTEGER(i4) :: poolSize = DEFAULT_POOL_SIZE
        INTEGER(i4) :: currentIndex = 0
        INTEGER(i4) :: allocatedCount = 0
        LOGICAL :: initialized = .FALSE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => IntMemoryPool_Init
        PROCEDURE, PUBLIC :: Allocate => IntMemoryPool_Allocate
        PROCEDURE, PUBLIC :: Reset => IntMemoryPool_Reset
        PROCEDURE, PUBLIC :: GetStats => IntMemoryPool_GetStats
    END TYPE IntMemoryPool
```

### `MemPoolManager` (lines 47–55)

```fortran
    TYPE, PUBLIC :: MemPoolManager
        TYPE(RealMemoryPool) :: realPool
        TYPE(IntMemoryPool) :: intPool
        LOGICAL :: enabled = .TRUE.
    CONTAINS
        PROCEDURE, PUBLIC :: Init => MemPoolManager_Init
        PROCEDURE, PUBLIC :: Reset => MemPoolManager_Reset
        PROCEDURE, PUBLIC :: GetStats => MemPoolManager_GetStats
    END TYPE MemPoolManager
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RealMemoryPool_Init` | 61 | `SUBROUTINE RealMemoryPool_Init(this, poolSize, status)` |
| FUNCTION | `RealMemoryPool_Allocate` | 85 | `FUNCTION RealMemoryPool_Allocate(this, size, status) RESULT(ptr)` |
| SUBROUTINE | `RealMemoryPool_Reset` | 136 | `SUBROUTINE RealMemoryPool_Reset(this)` |
| SUBROUTINE | `RealMemoryPool_GetStats` | 143 | `SUBROUTINE RealMemoryPool_GetStats(this, used, total, allocated)` |
| SUBROUTINE | `IntMemoryPool_Init` | 152 | `SUBROUTINE IntMemoryPool_Init(this, poolSize, status)` |
| FUNCTION | `IntMemoryPool_Allocate` | 176 | `FUNCTION IntMemoryPool_Allocate(this, size, status) RESULT(ptr)` |
| SUBROUTINE | `IntMemoryPool_Reset` | 227 | `SUBROUTINE IntMemoryPool_Reset(this)` |
| SUBROUTINE | `IntMemoryPool_GetStats` | 234 | `SUBROUTINE IntMemoryPool_GetStats(this, used, total, allocated)` |
| SUBROUTINE | `MemPoolManager_Init` | 243 | `SUBROUTINE MemPoolManager_Init(this, realPoolSize, intPoolSize, status)` |
| SUBROUTINE | `MemPoolManager_Reset` | 260 | `SUBROUTINE MemPoolManager_Reset(this)` |
| SUBROUTINE | `MemPoolManager_GetStats` | 267 | `SUBROUTINE MemPoolManager_GetStats(this, realUsed, realTotal, realAlloc, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
