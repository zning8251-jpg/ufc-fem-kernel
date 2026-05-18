# `NM_Solv_LinPrecILU.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinPrecILU.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinPrecILU`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinPrecILU`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinPrecILU`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinPrecILU.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_ILU_CSR_Type` (lines 43–50)

```fortran
  TYPE, PUBLIC :: NM_ILU_CSR_Type
    INTEGER(i4) :: n = 0_i4              ! Matrix dimension
    INTEGER(i4) :: nnz = 0_i4            ! Number of nonzeros
    INTEGER(i4), ALLOCATABLE :: ia(:)    ! Row pointers (n+1)
    INTEGER(i4), ALLOCATABLE :: ja(:)    ! Column indices (nnz)
    REAL(wp), ALLOCATABLE :: a(:)        ! Nonzero values (nnz)
    LOGICAL :: is_allocated = .FALSE.
  END TYPE NM_ILU_CSR_Type
```

### `NM_ILU_Params` (lines 55–62)

```fortran
  TYPE, PUBLIC :: NM_ILU_Params
    INTEGER(i4) :: level_of_fill = 0_i4  ! k in ILU(k)
    REAL(wp) :: drop_tol = 1.0e-4_wp     ! Drop tolerance for ILUT
    INTEGER(i4) :: max_fill_per_row = 20_i4 ! Max nonzeros per row in ILUT
    LOGICAL :: use_milu = .FALSE.        ! Use Modified ILU
    REAL(wp) :: pivot_tol = 1.0e-10_wp   ! Pivot threshold
    LOGICAL :: reorder = .FALSE.         ! Apply RCM reordering
  END TYPE NM_ILU_Params
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Allocate_CSR` | 72 | `SUBROUTINE Allocate_CSR(csr, n, nnz)` |
| FUNCTION | `i4_to_str` | 89 | `FUNCTION i4_to_str(i) RESULT(str)` |
| SUBROUTINE | `NM_ILU0_Factorize` | 95 | `SUBROUTINE NM_ILU0_Factorize(A, L, U, status)` |
| SUBROUTINE | `NM_ILU0_Solv` | 217 | `SUBROUTINE NM_ILU0_Solv(L, U, b, x, status)` |
| SUBROUTINE | `NM_ILU_Apply` | 290 | `SUBROUTINE NM_ILU_Apply(L, U, r, z, status)` |
| SUBROUTINE | `NM_ILU_Estimate_Fill` | 302 | `SUBROUTINE NM_ILU_Estimate_Fill(A, k, nnz_estimate, status)` |
| SUBROUTINE | `NM_ILU_GetStatistics` | 325 | `SUBROUTINE NM_ILU_GetStatistics(A, L, U, stats, status)` |
| SUBROUTINE | `NM_ILU_Reorder` | 346 | `SUBROUTINE NM_ILU_Reorder(A, A_reordered, perm, status)` |
| SUBROUTINE | `NM_ILUK_Factorize` | 375 | `SUBROUTINE NM_ILUK_Factorize(A, L, U, params, status)` |
| SUBROUTINE | `NM_ILUT_Factorize` | 463 | `SUBROUTINE NM_ILUT_Factorize(A, L, U, params, status)` |
| SUBROUTINE | `NM_MILU_Factorize` | 556 | `SUBROUTINE NM_MILU_Factorize(A, L, U, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
