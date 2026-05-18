# `AP_Solv_Def.f90`

- **Source**: `L6_AP/Solver/AP_Solv_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `AP_Solv_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `AP_Solv_Def`
- **逻辑主线（默认三段式 `AP_{Domain+Feature}`）**: `AP_Solv`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L6_AP/Solver/AP_Solv_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `AP_Solver_Desc` (lines 22–24)

```fortran
  TYPE :: AP_Solver_Desc
    CHARACTER(LEN=64) :: solver_name = ""
  END TYPE AP_Solver_Desc
```

### `AP_Solver_Algo` (lines 26–30)

```fortran
  TYPE :: AP_Solver_Algo
    INTEGER(i4) :: solver_type = AP_SOLVER_IMPLICIT
    REAL(wp)    :: tolerance   = 1.0E-6_wp
    INTEGER(i4) :: max_iter    = 100
  END TYPE AP_Solver_Algo
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
