# `IF_ThreadWS_Def.f90`

- **Source**: `L1_IF/Base/Parallel/IF_ThreadWS_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_ThreadWS_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_ThreadWS_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_ThreadWS`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base/Parallel`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/Parallel/IF_ThreadWS_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ThreadWS_ArrayInfo` (lines 27–34)

```fortran
  TYPE :: ThreadWS_ArrayInfo
    CHARACTER(LEN=MAX_ARRAY_NAME_LEN) :: name = ''
    INTEGER(i4) :: array_type = 0       ! 1=REAL(wp), 2=INTEGER(i4), 3=LOGICAL
    INTEGER(i4) :: array_rank = 0       ! 1 or 2
    INTEGER(i4) :: size1 = 0            ! First dimension size
    INTEGER(i4) :: size2 = 0            ! Second dimension size (for rank=2)
    LOGICAL :: allocated = .FALSE.
  END TYPE ThreadWS_ArrayInfo
```

### `ThreadWorkspace` (lines 37–64)

```fortran
  TYPE :: ThreadWorkspace
    INTEGER(i4) :: thread_id = 0
    LOGICAL :: initialized = .FALSE.
    
    ! Real arrays (1D and 2D)
    REAL(wp), ALLOCATABLE :: real_arrays_1d(:,:)
    REAL(wp), ALLOCATABLE :: real_arrays_2d(:,:,:)
    
    ! Integer arrays (1D and 2D)
    INTEGER(i4), ALLOCATABLE :: int_arrays_1d(:,:)
    INTEGER(i4), ALLOCATABLE :: int_arrays_2d(:,:,:)
    
    ! Logical arrays (1D only)
    LOGICAL, ALLOCATABLE :: logical_arrays_1d(:,:)
    
    ! Array metadata registry
    TYPE(ThreadWS_ArrayInfo) :: array_info(MAX_ARRAYS_PER_THREAD)
    INTEGER(i4) :: n_arrays = 0
    
  CONTAINS
    PROCEDURE, PASS(this) :: Initialize => ThreadWS_InitializeWorkspace
    PROCEDURE, PASS(this) :: Destroy => ThreadWS_DestroyWorkspace
    PROCEDURE, PASS(this) :: GetReal1D => ThreadWS_GetReal1D
    PROCEDURE, PASS(this) :: GetReal2D => ThreadWS_GetReal2D
    PROCEDURE, PASS(this) :: GetInt1D => ThreadWS_GetInt1D
    PROCEDURE, PASS(this) :: GetInt2D => ThreadWS_GetInt2D
    PROCEDURE, PASS(this) :: HasArray => ThreadWS_HasArray
  END TYPE ThreadWorkspace
```

### `ThreadWS` (lines 67–72)

```fortran
  TYPE :: ThreadWS
    INTEGER(i4) :: n_threads = 1
    INTEGER(i4) :: current_thread_id = 0
    LOGICAL :: initialized = .FALSE.
    TYPE(ThreadWorkspace) :: threads(MAX_THREADS)
  END TYPE ThreadWS
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ThreadWS_InitializeWorkspace` | 80 | `SUBROUTINE ThreadWS_InitializeWorkspace(this, thread_id, n_real_1d, n_real_2d, &` |
| SUBROUTINE | `ThreadWS_DestroyWorkspace` | 134 | `SUBROUTINE ThreadWS_DestroyWorkspace(this)` |
| SUBROUTINE | `ThreadWS_GetReal1D` | 149 | `SUBROUTINE ThreadWS_GetReal1D(this, array_index, slice_out, status)` |
| SUBROUTINE | `ThreadWS_GetReal2D` | 181 | `SUBROUTINE ThreadWS_GetReal2D(this, array_index, slice_out, status)` |
| SUBROUTINE | `ThreadWS_GetInt1D` | 214 | `SUBROUTINE ThreadWS_GetInt1D(this, array_index, slice_out, status)` |
| SUBROUTINE | `ThreadWS_GetInt2D` | 246 | `SUBROUTINE ThreadWS_GetInt2D(this, array_index, slice_out, status)` |
| FUNCTION | `ThreadWS_HasArray` | 279 | `FUNCTION ThreadWS_HasArray(this, array_name, status) RESULT(has_array)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
