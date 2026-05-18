# `NM_Solv_LinDir.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_LinDir.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_LinDir`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_LinDir`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_LinDir`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_LinDir.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `CSR_Matrix` (lines 32–39)

```fortran
  TYPE, PUBLIC :: CSR_Matrix
    INTEGER(i4) :: n_rows                     !< Number of rows
    INTEGER(i4) :: n_cols                     !< Number of columns
    INTEGER(i4) :: n_nonzeros                 !< Number of nonzero elements
    INTEGER, ALLOCATABLE :: row_ptr(:)    !< Row pointer (n_rows+1)
    INTEGER, ALLOCATABLE :: col_idx(:)    !< Column index (n_nonzeros)
    REAL(DP), ALLOCATABLE :: values(:)    !< Nonzero values (n_nonzeros)
  END TYPE
```

### `Direct_Solver_Params` (lines 42–48)

```fortran
  TYPE, PUBLIC :: Direct_Solver_Params
    INTEGER(i4) :: solver_type               !< Solver type
    INTEGER(i4) :: storage_format            !< Storage format
    LOGICAL  :: use_reordering            !< Use reordering
    LOGICAL  :: symbolic_factorization    !< Symbolic factorization
    REAL(DP) :: pivot_threshold           !< Pivot threshold
  END TYPE
```

### `LU_Factorization` (lines 51–56)

```fortran
  TYPE, PUBLIC :: LU_Factorization
    TYPE(CSR_Matrix) :: L_factor          !< Lower triangular matrix L
    TYPE(CSR_Matrix) :: U_factor          !< Upper triangular matrix U
    INTEGER, ALLOCATABLE :: pivot_perm(:) !< Row permutation vector
    LOGICAL :: is_factored                !< Factorization complete flag
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_LinSolv_Direct_CSR_Init` | 83 | `SUBROUTINE NM_LinSolv_Direct_CSR_Init(n_rows, n_cols, n_nonzeros, A)` |
| SUBROUTINE | `NM_LinSolv_Direct_LU_Factorize` | 117 | `SUBROUTINE NM_LinSolv_Direct_LU_Factorize(A, params, LU_fact)` |
| SUBROUTINE | `NM_LinSolv_Direct_Cholesky_Factorize` | 218 | `SUBROUTINE NM_LinSolv_Direct_Cholesky_Factorize(A, L)` |
| SUBROUTINE | `NM_LinSolv_Direct_Forward_Substitution_CSR` | 285 | `SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_CSR(L, b, y)` |
| SUBROUTINE | `NM_LinSolv_Direct_Forward_Substitution_NM` | 323 | `SUBROUTINE NM_LinSolv_Direct_Forward_Substitution_NM(L, b, y)` |
| SUBROUTINE | `NM_LinSolv_Direct_Backward_Substitution_CSR` | 357 | `SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_CSR(U, y, x)` |
| SUBROUTINE | `NM_LinSolv_Direct_Backward_Substitution_LT` | 397 | `SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_LT(L, y, x)` |
| SUBROUTINE | `NM_LinSolv_Direct_Backward_Substitution_NM` | 431 | `SUBROUTINE NM_LinSolv_Direct_Backward_Substitution_NM(U, y, x)` |
| SUBROUTINE | `NM_LinSolv_Direct_Solv_System` | 470 | `SUBROUTINE NM_LinSolv_Direct_Solv_System(A, b, params, x)` |
| SUBROUTINE | `Dense_To_CSR` | 514 | `SUBROUTINE Dense_To_CSR(A_dense, n, m, A_csr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 67–70 | `INTERFACE NM_LinSolv_Direct_Forward_Substitution` |
| 71–74 | `INTERFACE NM_LinSolv_Direct_Backward_Substitution` |
