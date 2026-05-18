# `PH_BC_Aux_Def.f90`

- **Source**: `L4_PH/LoadBC/PH_BC_Aux_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_BC_Aux_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_BC_Aux_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_BC_Aux`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `LoadBC`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/LoadBC/PH_BC_Aux_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_BC_Stp_Ctl_Algo` (lines 18–26)

```fortran
  TYPE, PUBLIC :: PH_BC_Stp_Ctl_Algo
    INTEGER(i4) :: bc_method = PH_BC_BC_PENALTY
    REAL(wp) :: penalty_param = 1.0E12_wp
    REAL(wp) :: lagrange_tol = 1.0E-8_wp
    REAL(wp) :: conv_tol = 1.0E-6_wp
    LOGICAL :: auto_cutback = .TRUE.
    INTEGER(i4) :: max_cutbacks = 5_i4
    REAL(wp) :: cutback_factor = 0.25_wp
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
