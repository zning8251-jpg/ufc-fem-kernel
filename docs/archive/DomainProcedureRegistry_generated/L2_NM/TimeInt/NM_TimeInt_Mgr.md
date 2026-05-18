# `NM_TimeInt_Mgr.f90`

- **Source**: `L2_NM/TimeInt/NM_TimeInt_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_TimeInt_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_TimeInt_Mgr`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_TimeInt`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `TimeInt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/TimeInt/NM_TimeInt_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_TimeIntCtrl` (lines 26–36)

```fortran
  TYPE, PUBLIC :: NM_TimeIntCtrl
    INTEGER(i4) :: scheme       = NM_TimeIntNewmark
    REAL(wp)    :: beta         = 0.25_wp        ! Newmark ?
    REAL(wp)    :: gamma        = 0.50_wp        ! Newmark ?
    REAL(wp)    :: alpha_hht    = 0.0_wp         ! HHT-? (0 = no dissipation)
    REAL(wp)    :: dtMin        = 1.0e-10_wp
    REAL(wp)    :: dtMax        = 1.0_wp
    REAL(wp)    :: dtInit       = 0.01_wp
    INTEGER(i4) :: cutbackLimit = 5_i4
    LOGICAL     :: enAdaptive   = .TRUE.
  END TYPE NM_TimeIntCtrl
```

### `NM_TimeInt_Domain` (lines 41–50)

```fortran
  TYPE, PUBLIC :: NM_TimeInt_Domain
    TYPE(NM_TimeIntCtrl) :: ctrl
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init        => NM_TimeInt_Init
    PROCEDURE :: Finalize    => NM_TimeInt_Finalize
    PROCEDURE :: SetScheme   => NM_TimeInt_SetScheme
    PROCEDURE :: Advance     => NM_TimeInt_Advance
    PROCEDURE :: GetSummary  => NM_TimeInt_GetSummary
  END TYPE NM_TimeInt_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_TimeInt_Finalize` | 54 | `SUBROUTINE NM_TimeInt_Finalize(this)` |
| SUBROUTINE | `NM_TimeInt_Init` | 62 | `SUBROUTINE NM_TimeInt_Init(this, status)` |
| SUBROUTINE | `NM_TimeInt_SetScheme` | 77 | `SUBROUTINE NM_TimeInt_SetScheme(this, scheme, beta, gamma, alpha, status)` |
| SUBROUTINE | `NM_TimeInt_Advance` | 118 | `SUBROUTINE NM_TimeInt_Advance(this, u, v, a, dt, status)` |
| SUBROUTINE | `NM_TimeInt_GetSummary` | 159 | `SUBROUTINE NM_TimeInt_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
