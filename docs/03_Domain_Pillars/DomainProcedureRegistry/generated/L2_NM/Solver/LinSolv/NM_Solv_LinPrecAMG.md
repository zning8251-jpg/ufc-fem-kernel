# `NM_Solv_LinPrecAMG.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinPrecAMG.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinPrecAMG`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinPrecAMG`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinPrecAMG`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinPrecAMG.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_AMG_CSR_Type` (lines 43–50)

```fortran
  TYPE, PUBLIC :: NM_AMG_CSR_Type
    INTEGER(i4) :: n = 0_i4              ! Matrix dimension
    INTEGER(i4) :: nnz = 0_i4            ! Number of nonzeros
    INTEGER(i4), ALLOCATABLE :: ia(:)    ! Row pointers (n+1)
    INTEGER(i4), ALLOCATABLE :: ja(:)    ! Column indices (nnz)
    REAL(wp), ALLOCATABLE :: a(:)        ! Nonzero values (nnz)
    LOGICAL :: is_allocated = .FALSE.
  END TYPE NM_AMG_CSR_Type
```

### `NM_AMG_Level` (lines 55–64)

```fortran
  TYPE, PUBLIC :: NM_AMG_Level
    TYPE(NM_AMG_CSR_Type) :: A           ! Operator at this level
    TYPE(NM_AMG_CSR_Type) :: P           ! Prolongation (interpolation)
    TYPE(NM_AMG_CSR_Type) :: R           ! Restriction (transpose of P)
    INTEGER(i4), ALLOCATABLE :: cf(:)    ! C/F splitting (1=C, 0=F)
    INTEGER(i4) :: n_coarse = 0_i4       ! Number of coarse points
    REAL(wp), ALLOCATABLE :: x(:)        ! Solution at this level
    REAL(wp), ALLOCATABLE :: b(:)        ! RHS at this level
    REAL(wp), ALLOCATABLE :: r(:)        ! Residual at this level
  END TYPE NM_AMG_Level
```

### `NM_AMG_Hierarchy` (lines 66–70)

```fortran
  TYPE, PUBLIC :: NM_AMG_Hierarchy
    INTEGER(i4) :: num_levels = 0_i4
    TYPE(NM_AMG_Level), ALLOCATABLE :: levels(:)
    LOGICAL :: is_setup = .FALSE.
  END TYPE NM_AMG_Hierarchy
```

### `NM_AMG_Params` (lines 75–100)

```fortran
  TYPE, PUBLIC :: NM_AMG_Params
    ! Coarsening parameters
    REAL(wp) :: strength_threshold = 0.25_wp  ! θ for SOC
    INTEGER(i4) :: coarsen_type = 1_i4        ! 1=RS, 2=CLJP, 3=PMIS
    INTEGER(i4) :: max_levels = 25_i4         ! Maximum levels
    INTEGER(i4) :: coarse_size = 10_i4        ! Stop when n < coarse_size
    
    ! Interpolation parameters
    INTEGER(i4) :: interp_type = 1_i4         ! 1=Direct, 2=Standard, 3=Extended+i
    INTEGER(i4) :: num_paths = 1_i4           ! Number of interpolation paths
    
    ! Smoothing parameters
    INTEGER(i4) :: smoother = 1_i4            ! 1=GS, 2=Jacobi, 3=ω-Jacobi
    INTEGER(i4) :: num_pre_smooth = 1_i4      ! Pre-smoothing steps
    INTEGER(i4) :: num_post_smooth = 1_i4     ! Post-smoothing steps
    REAL(wp) :: relax_weight = 1.0_wp         ! ω for ω-Jacobi (0.5-0.8)
    
    ! Cycle parameters
    INTEGER(i4) :: cycle_type = 1_i4          ! 1=V, 2=W, 3=F
    INTEGER(i4) :: max_coarse_iter = 10_i4    ! Direct solve iterations on coarsest
    REAL(wp) :: coarse_tol = 1.0e-12_wp       ! Tolerance for coarse solve
    
    ! General
    LOGICAL :: verbose = .FALSE.
    REAL(wp) :: truncation_factor = 0.0_wp    ! Drop small entries in P
  END TYPE NM_AMG_Params
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_AMG_Setup` | 120 | `SUBROUTINE NM_AMG_Setup(A, hierarchy, params, status)` |
| SUBROUTINE | `NM_AMG_Coarsen_RS` | 259 | `SUBROUTINE NM_AMG_Coarsen_RS(A, cf, n_coarse, params, status)` |
| SUBROUTINE | `NM_AMG_Interpolation` | 384 | `SUBROUTINE NM_AMG_Interpolation(A, cf, n_coarse, P, params, status)` |
| SUBROUTINE | `NM_AMG_Galerkin` | 485 | `SUBROUTINE NM_AMG_Galerkin(R, A, P, A_coarse, status)` |
| SUBROUTINE | `NM_AMG_V_Cycle` | 516 | `SUBROUTINE NM_AMG_V_Cycle(hierarchy, x, b, params, status)` |
| SUBROUTINE | `V_Cycle_Recursive` | 550 | `RECURSIVE SUBROUTINE V_Cycle_Recursive(level, hierarchy, x, b, params, status)` |
| SUBROUTINE | `NM_AMG_Smooth` | 609 | `SUBROUTINE NM_AMG_Smooth(A, x, b, smoother, num_iter, omega, status)` |
| SUBROUTINE | `NM_AMG_Solv` | 680 | `SUBROUTINE NM_AMG_Solv(hierarchy, r, z, params, status)` |
| SUBROUTINE | `NM_AMG_W_Cycle` | 701 | `SUBROUTINE NM_AMG_W_Cycle(hierarchy, x, b, params, status)` |
| SUBROUTINE | `CSR_Transpose` | 722 | `SUBROUTINE CSR_Transpose(A, AT, status)` |
| SUBROUTINE | `CSR_MatMat` | 731 | `SUBROUTINE CSR_MatMat(A, B, C, status)` |
| SUBROUTINE | `CSR_SpMV` | 740 | `SUBROUTINE CSR_SpMV(A, x, y, alpha, beta, status)` |
| FUNCTION | `i4_to_str` | 770 | `FUNCTION i4_to_str(i) RESULT(str)` |
| SUBROUTINE | `NM_AMG_GetStatistics` | 855 | `SUBROUTINE NM_AMG_GetStatistics(hierarchy, A_finest, stats, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
