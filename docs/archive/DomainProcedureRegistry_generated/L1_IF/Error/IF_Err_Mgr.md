# `IF_Err_Mgr.f90`

- **Source**: `L1_IF/Error/IF_Err_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Err_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Err_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Err`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Error`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Error/IF_Err_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `IF_Error_Stats` (lines 42–47)

```fortran
  TYPE, PUBLIC :: IF_Error_Stats
    INTEGER(i8) :: total_errors   = 0_i8
    INTEGER(i8) :: total_warnings = 0_i8
    INTEGER(i8) :: total_fatals   = 0_i8
    INTEGER(i4) :: last_error_code = 0_i4
  END TYPE IF_Error_Stats
```

### `IF_Error_Domain` (lines 53–62)

```fortran
  TYPE, PUBLIC :: IF_Error_Domain
    TYPE(IF_Err_Stack_State) :: errStack
    TYPE(IF_Error_Stats)       :: stats
    INTEGER(i4) :: maxStackSize = 1024_i4
    LOGICAL     :: initialized  = .FALSE.
  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Finalize
    PROCEDURE :: GetStats
  END TYPE IF_Error_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Finalize` | 69 | `SUBROUTINE Finalize(this)` |
| SUBROUTINE | `GetStats` | 89 | `SUBROUTINE GetStats(this, stats, status)` |
| SUBROUTINE | `Init` | 110 | `SUBROUTINE Init(this, maxStackSize, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
