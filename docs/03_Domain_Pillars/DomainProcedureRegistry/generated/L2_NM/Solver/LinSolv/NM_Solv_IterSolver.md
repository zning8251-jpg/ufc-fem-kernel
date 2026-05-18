# `NM_Solv_IterSolver.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_IterSolver.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_IterSolver`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_IterSolver`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_IterSolver`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_IterSolver.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_IterParams` (lines 45–55)

```fortran
    TYPE :: UF_IterParams
        INTEGER(i4) :: max_iter = 1000      ! Maximum iterations
        REAL(wp) :: tol_rel = 1.0E-6_wp     ! Relative tolerance
        REAL(wp) :: tol_abs = 1.0E-12_wp    ! Absolute tolerance
        INTEGER(i4) :: restart = 30         ! GMRES restart parameter
        INTEGER(i4) :: print_level = 0      ! 0=silent, 1=final, 2=each iter
        ! Output
        INTEGER(i4) :: iter_count = 0       ! Actual iterations
        REAL(wp) :: res_init = ZERO         ! Initial residual norm
        REAL(wp) :: res_final = ZERO        ! Final residual norm
    END TYPE UF_IterParams
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `givens_rotation` | 59 | `SUBROUTINE givens_rotation(a, b, c, s)` |
| SUBROUTINE | `iter_bicgstab` | 82 | `SUBROUTINE iter_bicgstab(mat, b, x, pc, params, ierr, pool)` |
| SUBROUTINE | `iter_cg` | 265 | `SUBROUTINE iter_cg(mat, b, x, params, ierr)` |
| SUBROUTINE | `iter_gmres` | 368 | `SUBROUTINE iter_gmres(mat, b, x, pc, params, ierr, pool, matPool)` |
| SUBROUTINE | `iter_iccg` | 561 | `SUBROUTINE iter_iccg(mat, b, x, params, ierr)` |
| SUBROUTINE | `iter_pcg` | 713 | `SUBROUTINE iter_pcg(mat, b, x, pc, params, ierr, pool)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
