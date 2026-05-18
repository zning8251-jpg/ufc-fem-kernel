# `IF_Mem_Mgr.f90`

- **Source**: `L1_IF/Memory/IF_Mem_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `MemoryPool` (lines 44–54)

```fortran
  TYPE, PUBLIC :: MemoryPool
    REAL(wp), ALLOCATABLE :: pool_data(:)
    INTEGER(i8) :: pool_size = 0_i8
    INTEGER(i8) :: used_size = 0_i8
    INTEGER(i4) :: num_blocks = 0
    INTEGER(i4) :: max_blocks = 1000
    INTEGER(i4), ALLOCATABLE :: block_sizes(:)
    INTEGER(i4), ALLOCATABLE :: block_offsets(:)
    LOGICAL, ALLOCATABLE :: block_allocated(:)
    LOGICAL :: init = .FALSE.
  END TYPE MemoryPool
```

### `MemoryStatistics_Alloc` (lines 57–60)

```fortran
    TYPE, PUBLIC :: MemoryStatistics_Alloc
    INTEGER(i8) :: total_allocated = 0_i8
    INTEGER(i8) :: total_freed = 0_i8
  END TYPE MemoryStatistics_Alloc
```

### `MemoryStatistics_Usage` (lines 62–65)

```fortran
  TYPE, PUBLIC :: MemoryStatistics_Usage
    INTEGER(i8) :: peak_usage = 0_i8
    INTEGER(i8) :: current_usage = 0_i8
  END TYPE MemoryStatistics_Usage
```

### `MemoryStatistics_Count` (lines 67–70)

```fortran
  TYPE, PUBLIC :: MemoryStatistics_Count
    INTEGER(i4) :: allocation_count = 0
    INTEGER(i4) :: deallocation_count = 0
  END TYPE MemoryStatistics_Count
```

### `MemoryStatistics_Quality` (lines 72–75)

```fortran
  TYPE, PUBLIC :: MemoryStatistics_Quality
    INTEGER(i4) :: leak_count = 0
    INTEGER(i4) :: fragmentation_ratio = 0
  END TYPE MemoryStatistics_Quality
```

### `MemoryStatistics` (lines 77–82)

```fortran
  TYPE, PUBLIC :: MemoryStatistics
    TYPE(MemoryStatistics_Alloc)    :: alloc
    TYPE(MemoryStatistics_Usage)    :: usage
    TYPE(MemoryStatistics_Count)    :: count
    TYPE(MemoryStatistics_Quality)  :: quality
  END TYPE MemoryStatistics
```

### `IF_Mem_InitPool_In` (lines 88–90)

```fortran
  TYPE, PUBLIC :: IF_Mem_InitPool_In
    INTEGER(i8) :: pool_size                                 ! M_pool ??^+ (bytes)
  END TYPE IF_Mem_InitPool_In
```

### `IF_Mem_InitPool_Out` (lines 93–95)

```fortran
  TYPE, PUBLIC :: IF_Mem_InitPool_Out
    TYPE(ErrorStatusType) :: status                          ! Error status
  END TYPE IF_Mem_InitPool_Out
```

### `IF_Mem_AllocFromPool_In` (lines 98–100)

```fortran
  TYPE, PUBLIC :: IF_Mem_AllocFromPool_In
    INTEGER(i8) :: size_bytes                                ! size ??^+ (bytes)
  END TYPE IF_Mem_AllocFromPool_In
```

### `IF_Mem_AllocFromPool_Out` (lines 103–107)

```fortran
  TYPE, PUBLIC :: IF_Mem_AllocFromPool_Out
    INTEGER(i8) :: offset                                    ! offset ??^+ (bytes)
    INTEGER(i4) :: block_id                                 ! id_block ??^+
    TYPE(ErrorStatusType) :: status                          ! Error status
  END TYPE IF_Mem_AllocFromPool_Out
```

### `IF_Mem_FreeToPool_In` (lines 110–112)

```fortran
  TYPE, PUBLIC :: IF_Mem_FreeToPool_In
    INTEGER(i4) :: block_id                                 ! id_block ??^+
  END TYPE IF_Mem_FreeToPool_In
```

### `IF_Mem_FreeToPool_Out` (lines 115–118)

```fortran
  TYPE, PUBLIC :: IF_Mem_FreeToPool_Out
    INTEGER(i8) :: freed_size                               ! M_freed ??^+ (bytes)
    TYPE(ErrorStatusType) :: status                         ! Error status
  END TYPE IF_Mem_FreeToPool_Out
```

### `IF_Mem_GetStatistics_In` (lines 121–123)

```fortran
  TYPE, PUBLIC :: IF_Mem_GetStatistics_In
    ! Empty - no input parameters
  END TYPE IF_Mem_GetStatistics_In
```

### `IF_Mem_GetStatistics_Out` (lines 126–128)

```fortran
  TYPE, PUBLIC :: IF_Mem_GetStatistics_Out
    TYPE(MemoryStatistics) :: stats                         ! Statistics (State)
  END TYPE IF_Mem_GetStatistics_Out
```

### `LegacyPtrBlock` (lines 141–148)

```fortran
  TYPE, PRIVATE :: LegacyPtrBlock
    INTEGER(i4) :: data_type = 0
    INTEGER(i4) :: dims(7) = 0
    REAL(wp), POINTER :: r(:) => null()
    INTEGER(i4), POINTER :: i(:) => null()
    LOGICAL, POINTER :: l(:) => null()
    LOGICAL :: ptr_associated = .FALSE.
  END TYPE LegacyPtrBlock
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `IF_Mem_InitPool_Structured` | 159 | `SUBROUTINE IF_Mem_InitPool_Structured(in, out)` |
| SUBROUTINE | `IF_Mem_AllocFromPool_Structured` | 167 | `SUBROUTINE IF_Mem_AllocFromPool_Structured(in, out)` |
| SUBROUTINE | `IF_Mem_FreeToPool_Structured` | 175 | `SUBROUTINE IF_Mem_FreeToPool_Structured(in, out)` |
| SUBROUTINE | `IF_Mem_GetStatistics_Structured` | 185 | `SUBROUTINE IF_Mem_GetStatistics_Structured(in, out)` |
| SUBROUTINE | `IF_Mem_AllocFromPool` | 198 | `SUBROUTINE IF_Mem_AllocFromPool(size_bytes, offset, block_id, status)` |
| SUBROUTINE | `IF_Mem_CheckLeaks` | 256 | `SUBROUTINE IF_Mem_CheckLeaks(leak_count, status)` |
| SUBROUTINE | `IF_Mem_FreeToPool` | 272 | `SUBROUTINE IF_Mem_FreeToPool(block_id, status)` |
| SUBROUTINE | `IF_Mem_GetFragmentation` | 305 | `SUBROUTINE IF_Mem_GetFragmentation(fragmentation_ratio, status)` |
| SUBROUTINE | `IF_Mem_GetStatistics` | 345 | `SUBROUTINE IF_Mem_GetStatistics(stats)` |
| SUBROUTINE | `IF_Mem_InitPool` | 351 | `SUBROUTINE IF_Mem_InitPool(pool_size, status)` |
| SUBROUTINE | `IF_Mem_ShutdownPool` | 379 | `SUBROUTINE IF_Mem_ShutdownPool(status)` |
| SUBROUTINE | `mem_init` | 405 | `SUBROUTINE mem_init(pool, memory_capacity, status)` |
| SUBROUTINE | `mem_alloc` | 412 | `SUBROUTINE mem_alloc(pool, size_bytes, type_id, module_id, name, block_id, status)` |
| SUBROUTINE | `mem_alloc_array` | 423 | `SUBROUTINE mem_alloc_array(pool, size_bytes, min_val, max_val, name, block_id, status)` |
| SUBROUTINE | `mem_free` | 434 | `SUBROUTINE mem_free(pool, block_id, status)` |
| SUBROUTINE | `mem_alloc_pointer` | 453 | `SUBROUTINE mem_alloc_pointer(pool, data_type, rank, dims, type_id, module_id, name, block_id, status)` |
| SUBROUTINE | `mem_associate_pointer` | 493 | `SUBROUTINE mem_associate_pointer(pool, block_id, ptr_real, ptr_int, ptr_logical, status)` |
| FUNCTION | `mem_is_pointer_associated` | 525 | `FUNCTION mem_is_pointer_associated(pool, block_id) RESULT(ok)` |
| SUBROUTINE | `mem_disassociate_pointer` | 539 | `SUBROUTINE mem_disassociate_pointer(pool, block_id, status)` |
| FUNCTION | `INT_TO_STRING` | 553 | `FUNCTION INT_TO_STRING(val) RESULT(str)` |
| SUBROUTINE | `IF_Mem_AllocReal1D` | 559 | `SUBROUTINE IF_Mem_AllocReal1D(domain, layer, n, name, ptr, pointer_id, status)` |
| SUBROUTINE | `UF_Mem_AllocReal1D` | 586 | `SUBROUTINE UF_Mem_AllocReal1D(domain, layer, n, name, ptr, pointer_id, status)` |
| SUBROUTINE | `IF_Mem_AllocReal2D` | 596 | `SUBROUTINE IF_Mem_AllocReal2D(domain, layer, n1, n2, name, ptr, pointer_id, status)` |
| SUBROUTINE | `UF_Mem_AllocReal2D` | 623 | `SUBROUTINE UF_Mem_AllocReal2D(domain, layer, n1, n2, name, ptr, pointer_id, status)` |
| SUBROUTINE | `IF_Mem_FreeReal1D` | 633 | `SUBROUTINE IF_Mem_FreeReal1D(pointer_id, status)` |
| SUBROUTINE | `UF_Mem_FreeReal1D` | 640 | `SUBROUTINE UF_Mem_FreeReal1D(pointer_id, status)` |
| SUBROUTINE | `IF_Mem_FreeReal2D` | 646 | `SUBROUTINE IF_Mem_FreeReal2D(pointer_id, status)` |
| SUBROUTINE | `UF_Mem_FreeReal2D` | 653 | `SUBROUTINE UF_Mem_FreeReal2D(pointer_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
