# `NM_Mtx_SpMVCSRTranspose.f90`

- **Source**: `L2_NM/Solver/NM_Mtx_SpMVCSRTranspose.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Mtx_SpMVCSRTranspose`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_SpMVCSRTranspose`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx_SpMVCSRTranspose`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NM_Mtx_SpMVCSRTranspose.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_SparseMatrix_CSR` (lines 31–39)

```fortran
  TYPE, PUBLIC :: NM_SparseMatrix_CSR
    INTEGER(i4) :: nrows = 0_i4
    INTEGER(i4) :: ncols = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! (nrows+1)
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! (nnz)
    REAL(wp), ALLOCATABLE :: values(:)       ! (nnz)
    LOGICAL :: is_sorted = .TRUE.
  END TYPE NM_SparseMatrix_CSR
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_CSR_Transpose` | 46 | `SUBROUTINE NM_CSR_Transpose(A_csr, AT_csr, status)` |
| SUBROUTINE | `NM_CSR_Transpose_InPlace` | 146 | `SUBROUTINE NM_CSR_Transpose_InPlace(A_csr, status)` |
| SUBROUTINE | `NM_CSR_Symmetrize` | 187 | `SUBROUTINE NM_CSR_Symmetrize(A_csr, A_sym_csr, pattern_only, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
