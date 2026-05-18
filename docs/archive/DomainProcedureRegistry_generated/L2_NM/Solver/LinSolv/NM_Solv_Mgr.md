# `NM_Solv_Mgr.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Mgr`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_LinSolvCtrl` (lines 49–57)

```fortran
  TYPE, PUBLIC :: NM_LinSolvCtrl
    INTEGER(i4) :: solvType  = NM_LINSOL_CG
    INTEGER(i4) :: precType  = NM_PREC_ILU0
    INTEGER(i4) :: maxIter   = 1000_i4
    REAL(wp)    :: relTol    = 1.0e-8_wp
    REAL(wp)    :: absTol    = 1.0e-12_wp
    LOGICAL     :: enReorder = .TRUE.
    LOGICAL     :: enGPU     = .FALSE.
  END TYPE NM_LinSolvCtrl
```

### `NM_NLSolvCtrl` (lines 62–71)

```fortran
  TYPE, PUBLIC :: NM_NLSolvCtrl
    INTEGER(i4) :: solvType    = NM_NLSOL_NEWTON
    INTEGER(i4) :: maxNRIter   = 16_i4
    REAL(wp)    :: resConvTol  = 1.0e-6_wp
    REAL(wp)    :: dispConvTol = 1.0e-6_wp
    REAL(wp)    :: energyTol   = 1.0e-8_wp
    REAL(wp)    :: arcLenParam = 0.01_wp
    LOGICAL     :: enLineSearch = .FALSE.
    LOGICAL     :: enEnergyConv = .FALSE.
  END TYPE NM_NLSolvCtrl
```

### `NM_Solver_Domain` (lines 76–86)

```fortran
  TYPE, PUBLIC :: NM_Solver_Domain
    TYPE(NM_LinSolvCtrl) :: linCtrl
    TYPE(NM_NLSolvCtrl)  :: nlCtrl
    LOGICAL              :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: Init                => NM_Solv_Init
    PROCEDURE :: Finalize            => NM_Solv_Finalize
    PROCEDURE :: SetLinearSolver     => NM_Solv_SetLin
    PROCEDURE :: SetNonlinearSolver  => NM_Solv_SetNonlin
    PROCEDURE :: GetSummary          => NM_Solv_GetSummary
  END TYPE NM_Solver_Domain
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Solv_Finalize` | 90 | `SUBROUTINE NM_Solv_Finalize(this)` |
| SUBROUTINE | `NM_Solv_Init` | 98 | `SUBROUTINE NM_Solv_Init(this, status)` |
| SUBROUTINE | `NM_Solv_SetLin` | 111 | `SUBROUTINE NM_Solv_SetLin(this, solvType, precType, maxIter, tol, status)` |
| SUBROUTINE | `NM_Solv_SetNonlin` | 147 | `SUBROUTINE NM_Solv_SetNonlin(this, solvType, maxNRIter, tol, status)` |
| SUBROUTINE | `NM_Solv_GetSummary` | 176 | `SUBROUTINE NM_Solv_GetSummary(this, summary, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
