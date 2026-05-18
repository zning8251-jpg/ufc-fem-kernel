# `NM_Conv_Def.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Conv_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_Def`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Conv_Desc` (lines 18–23)

```fortran
  TYPE, PUBLIC :: NM_Conv_Desc
    INTEGER(i4) :: max_iterations = 100
    REAL(wp)    :: abs_tol        = 1.0E-10_wp
    REAL(wp)    :: rel_tol        = 1.0E-6_wp
    INTEGER(i4) :: norm_type      = 2
  END TYPE NM_Conv_Desc
```

### `NM_Conv_State` (lines 28–34)

```fortran
  TYPE, PUBLIC :: NM_Conv_State
    INTEGER(i4) :: iteration      = 0
    REAL(wp)    :: residual_norm  = 0.0_wp
    REAL(wp)    :: initial_norm   = 0.0_wp
    LOGICAL     :: converged      = .FALSE.
    LOGICAL     :: diverged       = .FALSE.
  END TYPE NM_Conv_State
```

### `NM_Conv_Algo` (lines 39–43)

```fortran
  TYPE, PUBLIC :: NM_Conv_Algo
    LOGICAL     :: use_line_search = .FALSE.
    REAL(wp)    :: relaxation      = 1.0_wp
    INTEGER(i4) :: check_frequency = 1
  END TYPE NM_Conv_Algo
```

### `NM_Conv_Ctx` (lines 48–52)

```fortran
  TYPE, PUBLIC :: NM_Conv_Ctx
    REAL(wp)    :: prev_residual  = 0.0_wp
    REAL(wp)    :: conv_rate      = 0.0_wp
    INTEGER(i4) :: stagnation_cnt = 0
  END TYPE NM_Conv_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
