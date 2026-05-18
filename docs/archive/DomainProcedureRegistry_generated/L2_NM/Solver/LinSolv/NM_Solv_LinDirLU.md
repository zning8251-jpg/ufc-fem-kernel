# `NM_Solv_LinDirLU.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinDirLU.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_LinDirLU`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinDirLU`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinDirLU`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinDirLU.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_LU_Params_Pivot` (lines 53–56)

```fortran
    TYPE, PUBLIC :: NM_LU_Params_Pivot
    LOGICAL :: use_pivoting = .TRUE.
    REAL(wp) :: pivot_tol = 1.0e-12_wp                   ! pivot tolerance
  END TYPE NM_LU_Params_Pivot
```

### `NM_LU_Params_Block` (lines 58–60)

```fortran
  TYPE, PUBLIC :: NM_LU_Params_Block
    INTEGER(i4) :: block_size = 64_i4                    ! block size
  END TYPE NM_LU_Params_Block
```

### `NM_LU_Params_Flags` (lines 62–65)

```fortran
  TYPE, PUBLIC :: NM_LU_Params_Flags
    LOGICAL :: equilibrate = .FALSE.
    LOGICAL :: refine = .FALSE.
  END TYPE NM_LU_Params_Flags
```

### `NM_LU_Params_Ctrl` (lines 67–69)

```fortran
  TYPE, PUBLIC :: NM_LU_Params_Ctrl
    INTEGER(i4) :: max_refine_iter = 3_i4                ! max refine iter
  END TYPE NM_LU_Params_Ctrl
```

### `NM_LU_Params` (lines 71–76)

```fortran
  TYPE, PUBLIC :: NM_LU_Params
    TYPE(NM_LU_Params_Pivot) :: pivot
    TYPE(NM_LU_Params_Block) :: block
    TYPE(NM_LU_Params_Flags) :: flags
    TYPE(NM_LU_Params_Ctrl)  :: ctrl
  END TYPE NM_LU_Params
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `i4_to_str` | 86 | `FUNCTION i4_to_str(i) RESULT(str)` |
| SUBROUTINE | `NM_LU_Block_Decompose` | 92 | `SUBROUTINE NM_LU_Block_Decompose(A, L, U, P, block_size, status)` |
| SUBROUTINE | `NM_LU_ConditionNumber` | 143 | `SUBROUTINE NM_LU_ConditionNumber(L, U, norm_A, cond_est, status)` |
| SUBROUTINE | `NM_LU_Decompose` | 170 | `SUBROUTINE NM_LU_Decompose(A, L, U, status)` |
| SUBROUTINE | `NM_LU_Decompose_InPlace` | 239 | `SUBROUTINE NM_LU_Decompose_InPlace(A, P, status)` |
| SUBROUTINE | `NM_LU_Decompose_Pivoting` | 300 | `SUBROUTINE NM_LU_Decompose_Pivoting(A, L, U, P, status)` |
| SUBROUTINE | `NM_LU_Determinant` | 400 | `SUBROUTINE NM_LU_Determinant(L, U, P, det_val, status)` |
| SUBROUTINE | `NM_LU_EstimateFillIn` | 432 | `SUBROUTINE NM_LU_EstimateFillIn(A, estimated_fill, status)` |
| SUBROUTINE | `NM_LU_GetStatistics` | 463 | `SUBROUTINE NM_LU_GetStatistics(L, U, stats, status)` |
| SUBROUTINE | `NM_LU_Invert` | 492 | `SUBROUTINE NM_LU_Invert(L, U, P, Ainv, status)` |
| SUBROUTINE | `NM_LU_Refine_Solution` | 530 | `SUBROUTINE NM_LU_Refine_Solution(A, L, U, P, b, x, max_iter, status)` |
| SUBROUTINE | `NM_LU_Reorder` | 577 | `SUBROUTINE NM_LU_Reorder(A, A_reordered, perm, status)` |
| SUBROUTINE | `NM_LU_Residual` | 610 | `SUBROUTINE NM_LU_Residual(A, x, b, residual, status)` |
| SUBROUTINE | `NM_LU_Solv` | 625 | `SUBROUTINE NM_LU_Solv(L, U, P, b, x, status)` |
| SUBROUTINE | `NM_LU_Solv_Multiple` | 688 | `SUBROUTINE NM_LU_Solv_Multiple(L, U, P, B, X, status)` |
| FUNCTION | `Permutation_Sign` | 727 | `FUNCTION Permutation_Sign(P) RESULT(sgn)` |
| SUBROUTINE | `Swap_Int` | 753 | `SUBROUTINE Swap_Int(a, b)` |
| SUBROUTINE | `Swap_Rows` | 761 | `SUBROUTINE Swap_Rows(A, i, j)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
