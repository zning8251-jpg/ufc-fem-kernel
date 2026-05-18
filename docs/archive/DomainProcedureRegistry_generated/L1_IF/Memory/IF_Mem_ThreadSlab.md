# `IF_Mem_ThreadSlab.f90`

- **Source**: `L1_IF/Memory/IF_Mem_ThreadSlab.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_ThreadSlab`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_ThreadSlab`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_ThreadSlab`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_ThreadSlab.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ThreadSlab` (lines 62–73)

```fortran
  TYPE :: ThreadSlab
    INTEGER(INT8), ALLOCATABLE :: memory(:)  ! Slab memory
    INTEGER(i8)             :: offset = 0  ! Current allocation offset
    INTEGER(i8)             :: size = 0    ! Total slab size
    INTEGER(i4) :: thread_id = 0
    LOGICAL                    :: active = .FALSE.
  CONTAINS
    PROCEDURE :: init
    PROCEDURE :: reset
    PROCEDURE :: alloc
    PROCEDURE :: usage
  END TYPE ThreadSlab
```

### `ThreadSlabRegistry` (lines 76–80)

```fortran
  TYPE :: ThreadSlabRegistry
    TYPE(ThreadSlab) :: slabs(IF_MAX_THREADS)
    INTEGER(i4) :: n_threads = 0
    LOGICAL          :: initialized = .FALSE.
  END TYPE ThreadSlabRegistry
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ThreadSlab_Init` | 94 | `SUBROUTINE ThreadSlab_Init(n_threads, slab_size)` |
| SUBROUTINE | `init` | 117 | `SUBROUTINE init(this, thread_id, size)` |
| SUBROUTINE | `ThreadSlab_Finalize` | 133 | `SUBROUTINE ThreadSlab_Finalize()` |
| SUBROUTINE | `reset` | 153 | `SUBROUTINE reset(this)` |
| SUBROUTINE | `ThreadSlab_Reset` | 159 | `SUBROUTINE ThreadSlab_Reset(thread_id)` |
| SUBROUTINE | `alloc` | 168 | `SUBROUTINE alloc(this, size, ptr, success)` |
| SUBROUTINE | `ThreadSlab_Alloc` | 192 | `SUBROUTINE ThreadSlab_Alloc(thread_id, size, ptr, success)` |
| SUBROUTINE | `ThreadSlab_AllocAligned` | 207 | `SUBROUTINE ThreadSlab_AllocAligned(thread_id, size, ptr, success)` |
| FUNCTION | `usage` | 243 | `FUNCTION usage(this) RESULT(usage)` |
| FUNCTION | `ThreadSlab_GetUsage` | 256 | `FUNCTION ThreadSlab_GetUsage(thread_id) RESULT(usage)` |
| SUBROUTINE | `ThreadSlab_Report` | 267 | `SUBROUTINE ThreadSlab_Report(unit)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
