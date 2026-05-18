# `NM_Solv_Nonlin.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_Nonlin.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_Nonlin`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Nonlin`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Nonlin`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_Nonlin.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_NLParams` (lines 52–72)

```fortran
    TYPE :: UF_NLParams
        INTEGER(i4) :: solver_type = NM_NL_TYPE_NEWTON
        INTEGER(i4) :: conv_type = NM_CONV_MIXED
        INTEGER(i4) :: max_iter = 50           ! Max iterations per increment
        REAL(wp) :: tol_force = 1.0E-6_wp  ! Force residual tolerance
        REAL(wp) :: tol_disp = 1.0E-6_wp   ! Displacement tolerance
        REAL(wp) :: tol_energy = 1.0E-10_wp ! Energy tolerance
        LOGICAL :: use_line_search = .FALSE.
        REAL(wp) :: ls_min = 0.1_wp        ! Min line search factor
        REAL(wp) :: ls_max = 1.0_wp        ! Max line search factor
        ! Arc-length parameters
        REAL(wp) :: arc_length = 0.0_wp    ! Initial arc length
        REAL(wp) :: arc_min = 1.0E-6_wp    ! Min arc length
        REAL(wp) :: arc_max = 1.0E+2_wp    ! Max arc length
        REAL(wp) :: psi = 1.0_wp           ! Scaling parameter (0=load, 1=sphere)
        ! Adaptive stepping
        LOGICAL :: adaptive = .TRUE.
        INTEGER(i4) :: target_iter = 5         ! Target iterations for adaptation
        ! L-BFGS parameters
        INTEGER(i4) :: lbfgs_m = 10            ! Number of stored vectors (memory)
    END TYPE UF_NLParams
```

### `UF_NLResult` (lines 77–85)

```fortran
    TYPE :: UF_NLResult
        INTEGER(i4) :: iterations = 0
        INTEGER(i4) :: converged = 0           ! 1=converged, 0=not, -1=diverged
        REAL(wp) :: residual_norm = 0.0_wp
        REAL(wp) :: disp_norm = 0.0_wp
        REAL(wp) :: energy_norm = 0.0_wp
        REAL(wp) :: load_factor = 0.0_wp
        REAL(wp) :: arc_length = 0.0_wp
    END TYPE UF_NLResult
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `residual_interface` | 91 | `SUBROUTINE residual_interface(u, lambda, F_ext, R, ierr)` |
| SUBROUTINE | `tangent_interface` | 100 | `SUBROUTINE tangent_interface(u, K, ierr)` |
| SUBROUTINE | `adjust_arc_length` | 110 | `SUBROUTINE adjust_arc_length(arc_len, iter, params)` |
| SUBROUTINE | `lbfgs_line_search` | 128 | `SUBROUTINE lbfgs_line_search(u, p, lambda, F_ext, compute_residual, &` |
| SUBROUTINE | `nl_arc_length_crisfield` | 199 | `SUBROUTINE nl_arc_length_crisfield(K, R, u, F_ext, lambda, dlambda, &` |
| SUBROUTINE | `linear_solve` | 213 | `SUBROUTINE linear_solve(K, b, x, ierr)` |
| SUBROUTINE | `nl_convergence_check` | 370 | `SUBROUTINE nl_convergence_check(R_norm, R_norm0, du_norm, du_norm0, &` |
| SUBROUTINE | `nl_lbfgs` | 407 | `SUBROUTINE nl_lbfgs(R, u, F_ext, lambda, params, &` |
| SUBROUTINE | `nl_line_search` | 612 | `SUBROUTINE nl_line_search(u, du, lambda, F_ext, compute_residual, alpha, ierr)` |
| SUBROUTINE | `nl_newton_raphson` | 668 | `SUBROUTINE nl_newton_raphson(K, R, du, u, F_ext, lambda, params, &` |
| SUBROUTINE | `linear_solve` | 682 | `SUBROUTINE linear_solve(K, b, x, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 212–220 | `INTERFACE` |
| 681–689 | `INTERFACE` |
