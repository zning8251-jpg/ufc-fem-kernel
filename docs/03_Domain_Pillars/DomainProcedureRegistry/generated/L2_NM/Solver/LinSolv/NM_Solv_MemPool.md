# `NM_Solv_MemPool.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_MemPool.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_MemPool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_MemPool`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_MemPool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_MemPool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_MemoryPool_t` (lines 37–49)

```fortran
    TYPE :: UF_MemoryPool_t
        LOGICAL                           :: initialized  = .FALSE.
        INTEGER(i4)                       :: capacity     = 0_i4    ! elements in buf
        INTEGER(i4)                       :: used         = 0_i4    ! HWM cursor
        REAL(wp), POINTER                 :: buf(:) => NULL()        ! backing buffer (POINTER for ptr=>buf(s:e))
    CONTAINS
        PROCEDURE :: Init     => MemPool_t_Init
        PROCEDURE :: Alloc    => MemPool_t_Alloc
        PROCEDURE :: AllocDP1D=> MemPool_t_AllocDP1D    ! alias for CoreMemPool compat
        PROCEDURE :: Free     => MemPool_t_Free
        PROCEDURE :: Reset    => MemPool_t_Reset
        PROCEDURE :: Finalize => MemPool_t_Finalize
    END TYPE UF_MemoryPool_t
```

### `UF_MatrixPool_t` (lines 56–67)

```fortran
    TYPE :: UF_MatrixPool_t
        LOGICAL                           :: initialized  = .FALSE.
        INTEGER(i4)                       :: capacity     = 0_i4
        INTEGER(i4)                       :: used         = 0_i4
        REAL(wp), POINTER                 :: buf(:) => NULL()        ! POINTER for ptr=>buf(s:e)
    CONTAINS
        PROCEDURE :: Init     => MatPool_t_Init
        PROCEDURE :: Alloc    => MatPool_t_Alloc
        PROCEDURE :: Free     => MatPool_t_Free
        PROCEDURE :: Reset    => MatPool_t_Reset
        PROCEDURE :: Finalize => MatPool_t_Finalize
    END TYPE UF_MatrixPool_t
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MemPool_Init` | 75 | `SUBROUTINE MemPool_Init(pool, capacity, status)` |
| SUBROUTINE | `MemPool_Alloc` | 82 | `SUBROUTINE MemPool_Alloc(pool, n, ptr, status)` |
| SUBROUTINE | `MemPool_Free` | 90 | `SUBROUTINE MemPool_Free(pool, ptr)` |
| SUBROUTINE | `MemPool_Reset` | 96 | `SUBROUTINE MemPool_Reset(pool)` |
| SUBROUTINE | `MemPool_Finalize` | 101 | `SUBROUTINE MemPool_Finalize(pool)` |
| SUBROUTINE | `MemPool_t_Init` | 110 | `SUBROUTINE MemPool_t_Init(this, capacity, status)` |
| SUBROUTINE | `MemPool_t_Alloc` | 129 | `SUBROUTINE MemPool_t_Alloc(this, n, ptr, status)` |
| SUBROUTINE | `MemPool_t_AllocDP1D` | 155 | `SUBROUTINE MemPool_t_AllocDP1D(this, key, n, ptr, status)` |
| SUBROUTINE | `MemPool_t_Free` | 165 | `SUBROUTINE MemPool_t_Free(this, ptr)` |
| SUBROUTINE | `MemPool_t_Reset` | 172 | `SUBROUTINE MemPool_t_Reset(this)` |
| SUBROUTINE | `MemPool_t_Finalize` | 177 | `SUBROUTINE MemPool_t_Finalize(this)` |
| SUBROUTINE | `MatPool_t_Init` | 189 | `SUBROUTINE MatPool_t_Init(this, capacity, status)` |
| SUBROUTINE | `MatPool_t_Alloc` | 208 | `SUBROUTINE MatPool_t_Alloc(this, n, ptr, status)` |
| SUBROUTINE | `MatPool_t_Free` | 232 | `SUBROUTINE MatPool_t_Free(this, ptr)` |
| SUBROUTINE | `MatPool_t_Reset` | 238 | `SUBROUTINE MatPool_t_Reset(this)` |
| SUBROUTINE | `MatPool_t_Finalize` | 243 | `SUBROUTINE MatPool_t_Finalize(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
