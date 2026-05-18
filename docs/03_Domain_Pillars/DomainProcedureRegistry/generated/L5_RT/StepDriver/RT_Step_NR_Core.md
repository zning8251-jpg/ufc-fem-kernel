# `RT_Step_NR_Core.f90`

- **Source**: `L5_RT/StepDriver/RT_Step_NR_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Step_NR_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Step_NR_Core`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Step_NR`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `StepDriver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/StepDriver/RT_Step_NR_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_NR_Params` (lines 67–112)

```fortran
  TYPE, PUBLIC :: RT_NR_Params
    ! --- Convergence tolerances ---
    REAL(wp)    :: tol_force    = 1.0E-6_wp   ! Force criterion tolerance (||R||/||F_ext||)
    REAL(wp)    :: tol_disp     = 1.0E-6_wp   ! Displacement criterion (||Δu||/||u||)
    REAL(wp)    :: tol_energy   = 1.0E-8_wp   ! Energy criterion (|Δu^T·R|/|Δu_1^T·R_1|)
    INTEGER(i4) :: max_iter     = 16_i4       ! Maximum NR iterations per increment
    INTEGER(i4) :: criteria_mask = 7_i4       ! Bitmask: 1=force, 2=disp, 4=energy
    INTEGER(i4) :: conv_mode    = NR_CONV_AND ! Combination mode

    ! --- Time stepping parameters (DESIGN §4) ---
    REAL(wp)    :: dt_min       = 1.0E-12_wp  ! Minimum time increment
    REAL(wp)    :: dt_max       = 1.0_wp      ! Maximum time increment
    REAL(wp)    :: grow_factor  = 1.5_wp      ! Growth factor after successful increment
    REAL(wp)    :: cut_factor   = 0.25_wp     ! Cutback factor on failure
    INTEGER(i4) :: max_cutbacks = 5_i4        ! Max consecutive cutbacks before failure
    INTEGER(i4) :: n_opt_iter   = 5_i4        ! Optimal iteration count for adaptive stepping

    ! --- Line search parameters (DESIGN §5) ---
    LOGICAL     :: use_line_search = .TRUE.   ! Enable line search
    REAL(wp)    :: ls_tol       = 0.5_wp      ! Armijo condition parameter c1
    INTEGER(i4) :: ls_max_iter  = 10_i4       ! Max line search iterations

    ! --- Strategy selection (DESIGN §2.3) ---
    LOGICAL     :: use_modified_nr = .FALSE.  ! Modified NR (tangent only at iter 1)

    ! --- BFGS quasi-Newton parameters (adapted from RT_NLSolver_QuasiNewton) ---
    LOGICAL     :: use_bfgs       = .FALSE.   ! Enable BFGS secant update (skip tangent reassembly)
    INTEGER(i4) :: bfgs_memory    = 5_i4      ! L-BFGS memory depth (# stored pairs)
    REAL(wp)    :: bfgs_restart_tol = 1.0E-2_wp ! Restart BFGS if |s^T y| < tol*|s||y|

    ! --- Arc-length (Riks) parameters (adapted from RT_NLSolver_ArcLen) ---
    LOGICAL     :: use_arc_length = .FALSE.    ! Enable arc-length control
    REAL(wp)    :: arc_length_init = 0.01_wp   ! Initial arc-length Δs
    REAL(wp)    :: arc_min        = 1.0E-4_wp  ! Min arc-length
    REAL(wp)    :: arc_max        = 1.0_wp     ! Max arc-length
    REAL(wp)    :: psi_arc        = 1.0_wp     ! Scaling factor ψ (1=spherical, 0=cylindrical)

    ! --- Convergence weight factors (for NR_CONV_WEIGHTED mode) ---
    REAL(wp)    :: w_force        = 0.5_wp     ! Weight for force criterion
    REAL(wp)    :: w_disp         = 0.3_wp     ! Weight for displacement criterion
    REAL(wp)    :: w_energy       = 0.2_wp     ! Weight for energy criterion
    REAL(wp)    :: weighted_tol   = 0.8_wp     ! Threshold: score > tol → converged

    ! --- Divergence detection ---
    REAL(wp)    :: diverge_ratio  = 1.0E+4_wp  ! |R|/|R_0| > ratio → diverged
  END TYPE RT_NR_Params
```

### `RT_NR_Status` (lines 117–128)

```fortran
  TYPE, PUBLIC :: RT_NR_Status
    INTEGER(i4) :: n_iter       = 0_i4        ! Current iteration count
    INTEGER(i4) :: n_cutbacks   = 0_i4        ! Consecutive cutback count
    INTEGER(i4) :: total_iters  = 0_i4        ! Total iterations across increments
    REAL(wp)    :: force_norm   = 0.0_wp      ! Current ||R||/||F_ext||
    REAL(wp)    :: disp_norm    = 0.0_wp      ! Current ||Δu||/||u||
    REAL(wp)    :: energy_norm  = 0.0_wp      ! Current |Δu^T·R|/|Δu_1^T·R_1|
    REAL(wp)    :: energy_ref   = 0.0_wp      ! First iteration energy (reference)
    REAL(wp)    :: dt_current   = 0.0_wp      ! Current time step size
    LOGICAL     :: converged    = .FALSE.      ! Convergence flag
    LOGICAL     :: diverged     = .FALSE.      ! Divergence flag
  END TYPE RT_NR_Status
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_NR_Init` | 135 | `SUBROUTINE RT_NR_Init(params, nr_status, dt_initial, status)` |
| SUBROUTINE | `RT_NR_Iterate` | 183 | `SUBROUTINE RT_NR_Iterate(u, du, R, F_ext, alpha, iter, params, nr_status, status)` |
| SUBROUTINE | `RT_NR_CheckConvergence` | 231 | `SUBROUTINE RT_NR_CheckConvergence(R, du, u, F_ext, params, nr_status, status)` |
| SUBROUTINE | `RT_NR_LineSearch` | 319 | `SUBROUTINE RT_NR_LineSearch(du, R_current, g0, params, alpha_out, status)` |
| SUBROUTINE | `RT_NR_AutoStep` | 402 | `SUBROUTINE RT_NR_AutoStep(nr_status, params, dt_new, status)` |
| SUBROUTINE | `RT_NR_Cutback` | 446 | `SUBROUTINE RT_NR_Cutback(nr_status, params, dt_new, step_failed, status)` |
| SUBROUTINE | `RT_NR_Solve` | 501 | `SUBROUTINE RT_NR_Solve(u, R, F_ext, du, params, nr_status, status)` |
| FUNCTION | `Norm2Vec` | 594 | `PURE FUNCTION Norm2Vec(v, n) RESULT(nrm)` |
| FUNCTION | `DotProd` | 609 | `PURE FUNCTION DotProd(a, b, n) RESULT(dp)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
