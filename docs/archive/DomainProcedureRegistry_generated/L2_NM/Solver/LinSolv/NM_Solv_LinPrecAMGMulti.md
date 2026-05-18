# `NM_Solv_LinPrecAMGMulti.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinPrecAMGMulti.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinPrecAMGMulti`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinPrecAMGMulti`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinPrecAMGMulti`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinPrecAMGMulti.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_AMG_Level` (lines 22–34)

```fortran
  TYPE, PUBLIC :: NM_AMG_Level
    TYPE(CSR_Matrix) :: A                !<  
    TYPE(CSR_Matrix) :: P                !< prolongation ( 
    TYPE(CSR_Matrix) :: R                !< restriction
    
    INTEGER(i4) :: n_fine                    !<  
    INTEGER(i4) :: n_coarse                  !<  
    
    !  
    INTEGER(i4) :: smoother_type             !< 1=Jacobi, 2=Gauss-Seidel, 3=ILU
    INTEGER(i4) :: n_sweeps                  !<  iter count
    REAL(DP) :: relaxation_factor        !< relaxation 
  END TYPE
```

### `NM_AMG_Hierarchy` (lines 37–45)

```fortran
  TYPE, PUBLIC :: NM_AMG_Hierarchy
    INTEGER(i4) :: n_levels                  !<  
    TYPE(NM_AMG_Level), ALLOCATABLE :: levels(:)  !< level 
    
    !  
    INTEGER(i4) :: coarse_solver_type        !< 1=Direct, 2=Iterative
    INTEGER(i4) :: coarse_max_iter           !<  
    REAL(DP) :: coarse_tolerance         !<  
  END TYPE
```

### `NM_AMG_Params` (lines 48–66)

```fortran
  TYPE, PUBLIC :: NM_AMG_Params
    INTEGER(i4) :: max_levels                !<  ( 10-20)
    INTEGER(i4) :: coarsening_type           !< 1=Classical, 2=Aggregation
    REAL(DP) :: strong_threshold         !<  ( 0.25-0.5)
    REAL(DP) :: interpolation_truncation !<  value 
    INTEGER(i4) :: interpolation_type        !< 1=Direct, 2=Standard, 3=Extended
    
    !  param (SA-AMG)
    INTEGER(i4) :: aggregation_type          !<  
    INTEGER(i4) :: target_coarsening_factor  !<  
    
    !  param
    INTEGER(i4) :: pre_sweeps                !<  
    INTEGER(i4) :: post_sweeps               !<  
    REAL(DP) :: smoother_omega           !<  relaxation 
    
    !  
    INTEGER(i4) :: coarse_size_threshold     !<  
  END TYPE
```

### `NM_AMG_Preconditioner` (lines 69–73)

```fortran
  TYPE, PUBLIC :: NM_AMG_Preconditioner
    TYPE(NM_AMG_Hierarchy) :: hierarchy     !< AMGlevel 
    TYPE(NM_AMG_Params) :: params           !< AMGparam
    LOGICAL :: is_initialized            !< Initialize  
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_AMG_Init_Params` | 97 | `SUBROUTINE NM_AMG_Init_Params(params)` |
| SUBROUTINE | `NM_AMG_Classical_Coarsening` | 128 | `SUBROUTINE NM_AMG_Classical_Coarsening(A, params, cf_marker, n_coarse, status)` |
| SUBROUTINE | `NM_AMG_Direct_Interpolation` | 262 | `SUBROUTINE NM_AMG_Direct_Interpolation(A, cf_marker, n_coarse, P, status)` |
| SUBROUTINE | `NM_AMG_Aggregation` | 379 | `SUBROUTINE NM_AMG_Aggregation(A, params, aggregates, n_aggregates, status)` |
| SUBROUTINE | `NM_AMG_Smoothed_Prolongation` | 445 | `SUBROUTINE NM_AMG_Smoothed_Prolongation(A, aggregates, n_aggregates, omega, P, status)` |
| SUBROUTINE | `NM_AMG_Smoother_Jacobi` | 499 | `SUBROUTINE NM_AMG_Smoother_Jacobi(A, b, x, omega, n_sweeps)` |
| SUBROUTINE | `NM_AMG_Smoother_GaussSeidel` | 544 | `SUBROUTINE NM_AMG_Smoother_GaussSeidel(A, b, x, omega, n_sweeps)` |
| SUBROUTINE | `NM_AMG_Setup` | 580 | `SUBROUTINE NM_AMG_Setup(A, params, prec, status)` |
| SUBROUTINE | `Transpose_CSR` | 660 | `SUBROUTINE Transpose_CSR(A, AT)` |
| SUBROUTINE | `Galerkin_Projection` | 670 | `SUBROUTINE Galerkin_Projection(R, A, P, Ac)` |
| SUBROUTINE | `NM_AMG_Apply` | 692 | `SUBROUTINE NM_AMG_Apply(prec, b, x, status)` |
| SUBROUTINE | `NM_AMG_Destroy` | 768 | `SUBROUTINE NM_AMG_Destroy(prec)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
