# `NM_Solv_LinCfg.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinCfg.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinCfg`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinCfg`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinCfg`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinCfg.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_LinSolv_Config_Params` (lines 20–31)

```fortran
    TYPE, PUBLIC :: NM_LinSolv_Config_Params
        INTEGER(i4) :: solver_type = 0
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30
        INTEGER(i4) :: precond_type = 2
        INTEGER(i4) :: lfil = 10
        REAL(wp) :: droptol = 1.0E-4_wp
        INTEGER(i4) :: size_threshold = 5000
        LOGICAL :: is_symmetric = .FALSE.
        LOGICAL :: verbose = .FALSE.
    END TYPE NM_LinSolv_Config_Params
```

### `NM_LinSolv_Config_Result` (lines 33–39)

```fortran
    TYPE, PUBLIC :: NM_LinSolv_Config_Result
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0
    END TYPE NM_LinSolv_Config_Result
```

### `UF_LinSolParams` (lines 42–53)

```fortran
    TYPE, PUBLIC :: UF_LinSolParams
        INTEGER(i4) :: solver_type = 0
        INTEGER(i4) :: max_iter = 1000
        REAL(wp) :: tol = 1.0E-10_wp
        INTEGER(i4) :: restart = 30
        INTEGER(i4) :: precond_type = 2
        INTEGER(i4) :: lfil = 10
        REAL(wp) :: droptol = 1.0E-4_wp
        INTEGER(i4) :: size_threshold = 5000
        LOGICAL :: is_symmetric = .FALSE.
        LOGICAL :: verbose = .FALSE.
    END TYPE UF_LinSolParams
```

### `UF_LinSolResult` (lines 55–61)

```fortran
    TYPE, PUBLIC :: UF_LinSolResult
        INTEGER(i4) :: solver_used = 0
        INTEGER(i4) :: iterations = 0
        REAL(wp) :: residual = 0.0_wp
        REAL(wp) :: solve_time = 0.0_wp
        INTEGER(i4) :: status = 0
    END TYPE UF_LinSolResult
```

### `NM_LinSolv_Config` (lines 103–125)

```fortran
    TYPE :: NM_LinSolv_Config
        INTEGER(i4) :: problem_size = 0
        INTEGER(i4) :: problem_type = NM_PROBLEM_SPD
        INTEGER(i4) :: bandwidth = 0
        INTEGER(i4) :: profile = 0
        REAL(wp) :: fill_ratio = 0.0_wp
        REAL(wp) :: avg_row_width = 0.0_wp
        REAL(wp) :: condition_estimate = 0.0_wp
        INTEGER(i4) :: recommended_solver = NM_SOLVER_PCG
        INTEGER(i4) :: recommended_precond = NM_PRECOND_ILU0
        INTEGER(i4) :: ilu_fill_level = 0
        INTEGER(i4) :: recommended_max_iter = 1000
        REAL(wp) :: recommended_tol = 1.0E-10_wp
        LOGICAL :: use_reordering = .FALSE.
        INTEGER(i4), ALLOCATABLE :: perm(:)
        INTEGER(i4), ALLOCATABLE :: inv_perm(:)
        REAL(wp) :: matrix_memory = 0.0_wp
        REAL(wp) :: precond_memory = 0.0_wp
        REAL(wp) :: solver_memory = 0.0_wp
        REAL(wp) :: total_memory = 0.0_wp
    CONTAINS
        PROCEDURE :: destroy => NM_LinSolv_Config_Destroy
    END TYPE NM_LinSolv_Config
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_LinSolv_Config_Destroy` | 129 | `SUBROUTINE NM_LinSolv_Config_Destroy(this)` |
| SUBROUTINE | `NM_LinSolv_Config_AutoConfigure` | 135 | `SUBROUTINE NM_LinSolv_Config_AutoConfigure(K, config, verbose)` |
| SUBROUTINE | `NM_LinSolv_Config_Estimate_Memory` | 216 | `SUBROUTINE NM_LinSolv_Config_Estimate_Memory(K, config)` |
| FUNCTION | `NM_LinSolv_Config_Recommend_Precond` | 271 | `FUNCTION NM_LinSolv_Config_Recommend_Precond(K, problem_type) RESULT(precond)` |
| FUNCTION | `NM_LinSolv_Config_Check_SPD` | 300 | `FUNCTION NM_LinSolv_Config_Check_SPD(K, check_symmetry, check_diagonal) RESULT(is_spd)` |
| SUBROUTINE | `NM_LinSolv_Config_Solve_Optimized` | 340 | `SUBROUTINE NM_LinSolv_Config_Solve_Optimized(K, b, x, params, result, verbose)` |
| FUNCTION | `NM_LinSolv_Config_Solver_Name` | 400 | `FUNCTION NM_LinSolv_Config_Solver_Name(solver_type) RESULT(name)` |
| FUNCTION | `NM_LinSolv_Config_Precond_Name` | 418 | `FUNCTION NM_LinSolv_Config_Precond_Name(precond_type) RESULT(name)` |
| SUBROUTINE | `NM_LinSolv_Config_For_Physics` | 450 | `SUBROUTINE NM_LinSolv_Config_For_Physics(physics_type, n, config)` |
| SUBROUTINE | `NM_LinSolv_Config_Print_Summary` | 541 | `SUBROUTINE NM_LinSolv_Config_Print_Summary(iou)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
