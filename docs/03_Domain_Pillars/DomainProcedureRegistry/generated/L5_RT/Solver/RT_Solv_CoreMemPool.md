# `RT_Solv_CoreMemPool.f90`

- **Source**: `L5_RT/Solver/RT_Solv_CoreMemPool.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Solv_CoreMemPool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_CoreMemPool`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_CoreMemPool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_CoreMemPool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CMP_Slot_t` (lines 50–56)

```fortran
    TYPE :: CMP_Slot_t
        LOGICAL                              :: active   = .FALSE.
        INTEGER(i4)                          :: kind     = 0_i4     ! REAL or INT
        CHARACTER(LEN=CMP_KEY_LEN)           :: key      = ''
        REAL(wp),    POINTER                 :: rptr(:)  => NULL()
        INTEGER(i4), POINTER                 :: iptr(:)  => NULL()
    END TYPE CMP_Slot_t
```

### `UF_CoreMemPool_t` (lines 61–73)

```fortran
    TYPE :: UF_CoreMemPool_t
        LOGICAL                              :: initialized = .FALSE.
        INTEGER(i4)                          :: capacity    = 0_i4   ! max slots
        INTEGER(i4)                          :: used        = 0_i4   ! active slots
        TYPE(CMP_Slot_t), ALLOCATABLE        :: slots(:)
    CONTAINS
        PROCEDURE :: Init
        PROCEDURE :: AllocDP1D
        PROCEDURE :: AllocInt1D
        PROCEDURE :: Dealloc
        PROCEDURE :: Reset
        PROCEDURE :: Finalize
    END TYPE UF_CoreMemPool_t
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `CMP_Init` | 86 | `SUBROUTINE CMP_Init(this, capacity)` |
| SUBROUTINE | `CMP_AllocDP1D` | 101 | `SUBROUTINE CMP_AllocDP1D(this, key, n, ptr, status)` |
| SUBROUTINE | `CMP_AllocInt1D` | 139 | `SUBROUTINE CMP_AllocInt1D(this, key, n, ptr, status)` |
| SUBROUTINE | `CMP_Dealloc` | 175 | `SUBROUTINE CMP_Dealloc(this, key)` |
| SUBROUTINE | `CMP_Reset` | 195 | `SUBROUTINE CMP_Reset(this)` |
| SUBROUTINE | `CMP_Finalize` | 210 | `SUBROUTINE CMP_Finalize(this)` |
| FUNCTION | `cmp_find_or_new_slot` | 222 | `FUNCTION cmp_find_or_new_slot(pool, key, kind_flag) RESULT(idx)` |
| SUBROUTINE | `CoreMemPool_AllocDP1D` | 253 | `SUBROUTINE CoreMemPool_AllocDP1D(key, n, ptr, status)` |
| SUBROUTINE | `CoreMemPool_AllocInt1D` | 261 | `SUBROUTINE CoreMemPool_AllocInt1D(key, n, ptr, status)` |
| SUBROUTINE | `CoreMemPool_Dealloc` | 269 | `SUBROUTINE CoreMemPool_Dealloc(key)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
