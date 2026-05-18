# `PH_Mat_Constit_Def.f90`

- **Source**: `L4_PH/Material/Contract/PH_Mat_Constit_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Constit_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Constit_Def`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Constit`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Material/Contract`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Contract/PH_Mat_Constit_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_MatPoint_State` (lines 42–52)

```fortran
  TYPE :: PH_MatPoint_State
    INTEGER(i4) :: mat_id = 0_i4
    INTEGER(i4) :: nStatev = 0_i4
    REAL(wp), ALLOCATABLE :: statev(:)
    REAL(wp), ALLOCATABLE :: statev_old(:)
    REAL(wp) :: temp = 0.0_wp
    REAL(wp) :: temp_old = 0.0_wp
    REAL(wp) :: time_step = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    LOGICAL :: is_initialized = .FALSE.
  END TYPE PH_MatPoint_State
```

### `PH_MatPoint_StressStrain` (lines 60–67)

```fortran
  TYPE :: PH_MatPoint_StressStrain
    REAL(wp) :: strain(6) = 0.0_wp
    REAL(wp) :: strain_inc(6) = 0.0_wp
    REAL(wp) :: strain_old(6) = 0.0_wp
    REAL(wp) :: sigma(6) = 0.0_wp
    REAL(wp) :: stress_old(6) = 0.0_wp
    REAL(wp) :: tangent(6,6) = 0.0_wp
  END TYPE PH_MatPoint_StressStrain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

*(none detected outside TYPE bodies)*

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
