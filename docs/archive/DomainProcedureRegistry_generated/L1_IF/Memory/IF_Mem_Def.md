# `IF_Mem_Def.f90`

- **Source**: `L1_IF/Memory/IF_Mem_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Memory_Desc` (lines 13–16)

```fortran
  TYPE, PUBLIC :: IF_Memory_Desc
    INTEGER(i4) :: max_pool_size = 0      ! 0=unlimited
    LOGICAL     :: track_leaks   = .TRUE.
  END TYPE IF_Memory_Desc
```

### `IF_Memory_State` (lines 18–23)

```fortran
  TYPE, PUBLIC :: IF_Memory_State
    INTEGER(i4) :: total_alloc_bytes = 0
    INTEGER(i4) :: peak_alloc_bytes  = 0
    INTEGER(i4) :: alloc_count       = 0
    INTEGER(i4) :: dealloc_count     = 0
  END TYPE IF_Memory_State
```

### `IF_Memory_Algo` (lines 26–30)

```fortran
  TYPE, PUBLIC :: IF_Memory_Algo
    INTEGER(i4) :: alignment_bytes  = 64_i4    ! AVX-512 default
    INTEGER(i4) :: growth_factor    = 2_i4     ! arena doubling
    LOGICAL     :: use_arena        = .TRUE.   ! arena vs system malloc
  END TYPE IF_Memory_Algo
```

### `IF_Memory_Ctx` (lines 33–36)

```fortran
  TYPE, PUBLIC :: IF_Memory_Ctx
    INTEGER(i4) :: caller_domain = 0_i4        ! IF_MEM_DOMAIN_*
    INTEGER(i4) :: request_bytes = 0_i4
  END TYPE IF_Memory_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
