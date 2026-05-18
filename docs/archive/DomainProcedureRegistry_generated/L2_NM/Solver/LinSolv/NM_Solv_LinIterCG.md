# `NM_Solv_LinIterCG.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinIterCG.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinIterCG`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinIterCG`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinIterCG`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinIterCG.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_CG_Params` (lines 36–42)

```fortran
  TYPE, PUBLIC :: NM_CG_Params
    INTEGER(i4) :: max_iter = 1000_i4     ! Maximum iterations
    REAL(wp) :: tolerance = 1.0e-8_wp      ! Convergence tolerance (relative)
    REAL(wp) :: abs_tolerance = 1.0e-14_wp ! Absolute residual threshold
    LOGICAL :: verbose = .FALSE.           ! Print convergence history
    INTEGER(i4) :: print_every = 10_i4     ! Print frequency
  END TYPE NM_CG_Params
```

### `NM_CG_State` (lines 47–53)

```fortran
  TYPE, PUBLIC :: NM_CG_State
    INTEGER(i4) :: num_iter = 0_i4         ! Actual iterations performed
    REAL(wp) :: final_residual = 0.0_wp    ! ||r_k||
    REAL(wp) :: initial_residual = 0.0_wp ! ||r_0||
    LOGICAL :: converged = .FALSE.         ! Convergence flag
    CHARACTER(LEN=256) :: message = ""     ! Status message
  END TYPE NM_CG_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MatVec_Product` | 57 | `SUBROUTINE MatVec_Product(A, x, y, SpMV_proc, status)` |
| SUBROUTINE | `SpMV_proc` | 62 | `SUBROUTINE SpMV_proc(A, x, y, status)` |
| SUBROUTINE | `NM_CG_GetResidualHistory` | 80 | `SUBROUTINE NM_CG_GetResidualHistory(state, residuals, num_residuals, status)` |
| SUBROUTINE | `NM_CG_GetStatistics` | 96 | `SUBROUTINE NM_CG_GetStatistics(state, stats, status)` |
| SUBROUTINE | `NM_CG_Solv` | 113 | `SUBROUTINE NM_CG_Solv(A, b, x, params, state, SpMV_proc, status)` |
| SUBROUTINE | `SpMV_proc` | 125 | `SUBROUTINE SpMV_proc(A, x, y, status)` |
| SUBROUTINE | `NM_CG_Solv_CSR` | 219 | `SUBROUTINE NM_CG_Solv_CSR(n, nnz, row_ptr, col_ind, values, b, x, params, state, status)` |
| SUBROUTINE | `NM_CG_Solv_Precond` | 308 | `SUBROUTINE NM_CG_Solv_Precond(A, b, x, params, state, SpMV_proc, Precond_proc, status)` |
| SUBROUTINE | `SpMV_proc` | 319 | `SUBROUTINE SpMV_proc(A, x, y, status)` |
| SUBROUTINE | `Precond_proc` | 326 | `SUBROUTINE Precond_proc(z, r, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 61–69 | `INTERFACE` |
| 124–132 | `INTERFACE` |
| 318–333 | `INTERFACE` |
