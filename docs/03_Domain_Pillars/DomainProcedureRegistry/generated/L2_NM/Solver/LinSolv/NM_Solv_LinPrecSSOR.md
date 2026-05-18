# `NM_Solv_LinPrecSSOR.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinPrecSSOR.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinPrecSSOR`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinPrecSSOR`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinPrecSSOR`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinPrecSSOR.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_SSOR_Params` (lines 41–48)

```fortran
  TYPE, PUBLIC :: NM_SSOR_Params
    REAL(wp) :: omega = 1.0_wp           ! Relaxation parameter (1 ω < 2)
    INTEGER(i4) :: num_sweeps = 1_i4     ! Number of SSOR sweeps
    LOGICAL :: symmetric = .TRUE.        ! Use SSOR (vs SOR)
    INTEGER(i4) :: sweep_dir = 0_i4      ! 0=forward+backward, 1=forward, 2=backward
    INTEGER(i4) :: block_size = 1_i4     ! Block size for BSOR/BJacobi
    LOGICAL :: use_diagonal_scaling = .FALSE.  ! Pre-scale by D^{-1}
  END TYPE NM_SSOR_Params
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `i4_to_str` | 59 | `FUNCTION i4_to_str(i) RESULT(str)` |
| SUBROUTINE | `NM_Block_Jacobi` | 65 | `SUBROUTINE NM_Block_Jacobi(A, r, z, block_size, status)` |
| SUBROUTINE | `NM_GaussSeidel_Apply` | 120 | `SUBROUTINE NM_GaussSeidel_Apply(A, r, z, symmetric, status)` |
| SUBROUTINE | `NM_Jacobi_Apply` | 138 | `SUBROUTINE NM_Jacobi_Apply(A, r, z, omega, status)` |
| SUBROUTINE | `NM_SOR_Backward` | 170 | `SUBROUTINE NM_SOR_Backward(A, x, b, omega, status)` |
| SUBROUTINE | `NM_SOR_Forward` | 209 | `SUBROUTINE NM_SOR_Forward(A, x, b, omega, status)` |
| SUBROUTINE | `NM_SSOR_Apply` | 255 | `SUBROUTINE NM_SSOR_Apply(A, r, z, params, status)` |
| SUBROUTINE | `NM_SSOR_GetStatistics` | 325 | `SUBROUTINE NM_SSOR_GetStatistics(params, stats, status)` |
| SUBROUTINE | `NM_SSOR_Optimal_Omega` | 341 | `SUBROUTINE NM_SSOR_Optimal_Omega(A, omega_opt, status)` |
| SUBROUTINE | `NM_SSOR_Solv` | 395 | `SUBROUTINE NM_SSOR_Solv(A, b, x, max_iter, tol, params, converged, num_iter, status)` |
| SUBROUTINE | `Solv_Dense_System` | 463 | `SUBROUTINE Solv_Dense_System(A, b, x, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
