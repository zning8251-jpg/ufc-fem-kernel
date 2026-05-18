# `NM_Conv_MG.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_MG.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Conv_MG`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_MG`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_MG`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_MG.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Multigrid_Params_Method` (lines 48–52)

```fortran
  TYPE, PUBLIC :: Multigrid_Params_Method
    INTEGER(i4) :: mg_type = NM_MG_GEOMETRIC
    INTEGER(i4) :: cycle_type = NM_MG_V_CYCLE
    INTEGER(i4) :: smoother = NM_MG_SMOOTHER_GS
  END TYPE Multigrid_Params_Method
```

### `Multigrid_Params_Hierarchy` (lines 54–56)

```fortran
  TYPE, PUBLIC :: Multigrid_Params_Hierarchy
    INTEGER(i4) :: max_levels = 10_i4
  END TYPE Multigrid_Params_Hierarchy
```

### `Multigrid_Params_Smooth` (lines 58–63)

```fortran
  TYPE, PUBLIC :: Multigrid_Params_Smooth
    INTEGER(i4) :: pre_sweeps = 2_i4
    INTEGER(i4) :: post_sweeps = 2_i4
    INTEGER(i4) :: coarse_sweeps = 10_i4
    REAL(DP) :: smoother_omega = 1.0_DP
  END TYPE Multigrid_Params_Smooth
```

### `Multigrid_Params_Conv` (lines 65–69)

```fortran
  TYPE, PUBLIC :: Multigrid_Params_Conv
    REAL(DP) :: coarse_tolerance = 1.0E-6_DP
    INTEGER(i4) :: max_iterations = 100_i4
    REAL(DP) :: tolerance = 1.0E-6_DP
  END TYPE Multigrid_Params_Conv
```

### `Multigrid_Params` (lines 71–76)

```fortran
  TYPE, PUBLIC :: Multigrid_Params
    TYPE(Multigrid_Params_Method) :: method
    TYPE(Multigrid_Params_Hierarchy) :: hierarchy
    TYPE(Multigrid_Params_Smooth) :: smooth
    TYPE(Multigrid_Params_Conv) :: conv
  END TYPE Multigrid_Params
```

### `Grid_Level` (lines 79–91)

```fortran
  TYPE, PUBLIC :: Grid_Level
    INTEGER(i4) :: level_id = 0_i4
    INTEGER(i4) :: n_points = 0_i4
    REAL(DP), ALLOCATABLE :: A(:,:)        !< coeff matrix
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
    REAL(DP), ALLOCATABLE :: b(:)          !< RHS
    REAL(DP), ALLOCATABLE :: r(:)          !< residual
    ! transfer ops
    REAL(DP), ALLOCATABLE :: P(:,:)        !< prolong (coarse->fine)
    REAL(DP), ALLOCATABLE :: R(:,:)        !< restrict (fine->coarse)
    TYPE(Grid_Level), POINTER :: finer => NULL()
    TYPE(Grid_Level), POINTER :: coarser => NULL()
  END TYPE Grid_Level
```

### `Multigrid_Solver` (lines 94–99)

```fortran
  TYPE, PUBLIC :: Multigrid_Solver
    TYPE(Grid_Level), POINTER :: finest => NULL()
    TYPE(Grid_Level), POINTER :: coarsest => NULL()
    INTEGER(i4) :: n_levels = 0_i4
    TYPE(Multigrid_Params) :: params
  END TYPE Multigrid_Solver
```

### `Multigrid_Result_Solution` (lines 102–104)

```fortran
  TYPE, PUBLIC :: Multigrid_Result_Solution
    REAL(DP), ALLOCATABLE :: x(:)          !< solution
  END TYPE Multigrid_Result_Solution
```

### `Multigrid_Result_Stats` (lines 106–110)

```fortran
  TYPE, PUBLIC :: Multigrid_Result_Stats
    REAL(DP) :: residual_norm = ZERO       !< final residual
    INTEGER(i4) :: n_cycles = 0_i4         !< cycle count
    INTEGER(i4) :: n_levels = 0_i4         !< level count
  END TYPE Multigrid_Result_Stats
```

### `Multigrid_Result_Status` (lines 112–115)

```fortran
  TYPE, PUBLIC :: Multigrid_Result_Status
    LOGICAL :: converged = .FALSE.         !< converged
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE Multigrid_Result_Status
```

### `Multigrid_Result` (lines 117–121)

```fortran
  TYPE, PUBLIC :: Multigrid_Result
    TYPE(Multigrid_Result_Solution) :: solution
    TYPE(Multigrid_Result_Stats) :: stats
    TYPE(Multigrid_Result_Status) :: status
  END TYPE Multigrid_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Multigrid_Solv` | 163 | `SUBROUTINE NM_Multigrid_Solv(A, b, x, params, result, status)` |
| SUBROUTINE | `NM_Multigrid_VCycle` | 240 | `SUBROUTINE NM_Multigrid_VCycle(level, params)` |
| SUBROUTINE | `NM_Multigrid_WCycle` | 275 | `SUBROUTINE NM_Multigrid_WCycle(level, params)` |
| SUBROUTINE | `NM_Multigrid_Build_Hierarchy` | 323 | `SUBROUTINE NM_Multigrid_Build_Hierarchy(A, params, mg, status)` |
| SUBROUTINE | `NM_GMG_Build_Levels` | 345 | `SUBROUTINE NM_GMG_Build_Levels(A, params, mg, status)` |
| SUBROUTINE | `NM_AMG_Build_Levels` | 413 | `SUBROUTINE NM_AMG_Build_Levels(A, params, mg, status)` |
| SUBROUTINE | `NM_Calc_Prolongation` | 429 | `SUBROUTINE NM_Calc_Prolongation(n_fine, n_coarse, P)` |
| SUBROUTINE | `NM_Calc_Restriction` | 462 | `SUBROUTINE NM_Calc_Restriction(P, R)` |
| SUBROUTINE | `NM_MG_Smooth` | 476 | `SUBROUTINE NM_MG_Smooth(level, n_sweeps, params)` |
| SUBROUTINE | `NM_MG_Smooth_Jacobi` | 493 | `SUBROUTINE NM_MG_Smooth_Jacobi(level, n_sweeps, omega)` |
| SUBROUTINE | `NM_MG_Smooth_GaussSeidel` | 524 | `SUBROUTINE NM_MG_Smooth_GaussSeidel(level, n_sweeps)` |
| SUBROUTINE | `NM_MG_Smooth_SOR` | 550 | `SUBROUTINE NM_MG_Smooth_SOR(level, n_sweeps, omega)` |
| SUBROUTINE | `NM_MG_Coarse_Solv` | 577 | `SUBROUTINE NM_MG_Coarse_Solv(level, params)` |
| SUBROUTINE | `NM_Multigrid_Init` | 608 | `SUBROUTINE NM_Multigrid_Init(mg, params)` |
| SUBROUTINE | `NM_Multigrid_Destroy` | 620 | `RECURSIVE SUBROUTINE NM_Multigrid_Destroy(mg)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
