# `NM_Mtx_Core.f90`

- **Source**: `L2_NM/Matrix/NM_Mtx_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Mtx_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Mtx_Core`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Mtx`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Matrix`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Matrix/NM_Mtx_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `NM_Matrix_Index` (lines 27–36)

```fortran
  TYPE, PUBLIC :: NM_Matrix_Index
    INTEGER(i4) :: n_rows = 0_i4
    INTEGER(i4) :: n_cols = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)   ! CSR: (n_rows+1), 1-based
    INTEGER(i4), ALLOCATABLE :: col_ind(:)   ! CSR: (nnz)
    INTEGER(i4) :: format = NM_MAT_FMT_CSR
    LOGICAL     :: is_symmetric = .FALSE.
    LOGICAL     :: finalized = .FALSE.
  END TYPE NM_Matrix_Index
```

### `NM_Matrix_Values` (lines 40–43)

```fortran
  TYPE, PUBLIC :: NM_Matrix_Values
    INTEGER(i4) :: index_id = 0_i4
    REAL(wp), ALLOCATABLE :: values(:)  ! (nnz)
  END TYPE NM_Matrix_Values
```

### `NM_Matrix` (lines 47–50)

```fortran
  TYPE, PUBLIC :: NM_Matrix
    TYPE(NM_Matrix_Index)   :: index
    TYPE(NM_Matrix_Values)  :: data
  END TYPE NM_Matrix
```

### `UF_COOEntry` (lines 76–80)

```fortran
  TYPE, PUBLIC :: UF_COOEntry
    INTEGER(i4) :: row = 0
    INTEGER(i4) :: col = 0
    REAL(wp)    :: val = CSR_ZERO
  END TYPE UF_COOEntry
```

### `UF_CSRMatrix` (lines 82–101)

```fortran
  TYPE, PUBLIC :: UF_CSRMatrix
    INTEGER(i4) :: nrows = 0
    INTEGER(i4) :: ncols = 0
    INTEGER(i4) :: nnz = 0
    REAL(wp), ALLOCATABLE :: val(:)
    INTEGER(i4), ALLOCATABLE :: col_ind(:)
    INTEGER(i4), ALLOCATABLE :: row_ptr(:)
    LOGICAL :: is_symmetric = .FALSE.
    LOGICAL :: is_initialized = .FALSE.
  CONTAINS
    PROCEDURE :: init => csr_init
    PROCEDURE :: destroy => csr_destroy_method
    PROCEDURE :: get => csr_get_value_method
    PROCEDURE :: set => csr_set_value_method
    PROCEDURE :: add => csr_add_value_method
    PROCEDURE :: matvec => csr_matvec
    PROCEDURE :: matvec_trans => csr_matvec_trans
    PROCEDURE :: get_row_nnz => csr_get_row_nnz
    PROCEDURE :: print_info => csr_info_method
  END TYPE UF_CSRMatrix
```

### `UF_CSR_Assembly_Map` (lines 106–116)

```fortran
  TYPE, PUBLIC :: UF_CSR_Assembly_Map
    INTEGER(i4) :: num_elements = 0
    INTEGER(i4) :: max_dof_per_elem = 0
    INTEGER(i4), ALLOCATABLE :: pos(:,:,:)
    INTEGER(i4), ALLOCATABLE :: pos_flat(:)
    INTEGER(i4), ALLOCATABLE :: elem_offset(:)
    LOGICAL :: initialized = .FALSE.
  CONTAINS
    PROCEDURE :: init => assembly_map_init
    PROCEDURE :: destroy => assembly_map_destroy
  END TYPE UF_CSR_Assembly_Map
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Matrix_Init` | 150 | `SUBROUTINE NM_Matrix_Init(A, n_rows, n_cols, max_nnz, status)` |
| SUBROUTINE | `NM_Matrix_AddEntry` | 185 | `SUBROUTINE NM_Matrix_AddEntry(A, row, col, value, status)` |
| SUBROUTINE | `NM_Matrix_Finalize` | 219 | `SUBROUTINE NM_Matrix_Finalize(A, status)` |
| SUBROUTINE | `NM_Matrix_Destroy` | 252 | `SUBROUTINE NM_Matrix_Destroy(A)` |
| SUBROUTINE | `NM_Matrix_MatVec` | 267 | `SUBROUTINE NM_Matrix_MatVec(A, x, y, status)` |
| SUBROUTINE | `NM_Matrix_GetValue` | 301 | `SUBROUTINE NM_Matrix_GetValue(A, row, col, value, found, status)` |
| SUBROUTINE | `NM_Matrix_SetValue` | 338 | `SUBROUTINE NM_Matrix_SetValue(A, row, col, value, status)` |
| SUBROUTINE | `NM_Mtx_Add` | 383 | `SUBROUTINE NM_Mtx_Add(A, B, C, status)` |
| SUBROUTINE | `NM_Mtx_Subtract` | 400 | `SUBROUTINE NM_Mtx_Subtract(A, B, C, status)` |
| FUNCTION | `NM_Mtx_Det` | 417 | `FUNCTION NM_Mtx_Det(n, A) RESULT(det)` |
| SUBROUTINE | `NM_Mtx_Diag` | 434 | `SUBROUTINE NM_Mtx_Diag(n, d, A, status)` |
| SUBROUTINE | `NM_Mtx_Eye` | 450 | `SUBROUTINE NM_Mtx_Eye(n, Id, status)` |
| SUBROUTINE | `NM_Mtx_Gemm` | 465 | `SUBROUTINE NM_Mtx_Gemm(transa, transb, m, n, k, alpha, A, B, beta, C, status)` |
| SUBROUTINE | `NM_Mtx_Gemv` | 515 | `SUBROUTINE NM_Mtx_Gemv(trans, m, n, alpha, A, x, beta, y, status)` |
| SUBROUTINE | `NM_Mtx_Ger` | 549 | `SUBROUTINE NM_Mtx_Ger(m, n, alpha, x, y, A, status)` |
| SUBROUTINE | `NM_Mtx_Inv` | 565 | `SUBROUTINE NM_Mtx_Inv(n, A, Ainv, status)` |
| FUNCTION | `NM_Mtx_Norm1` | 591 | `FUNCTION NM_Mtx_Norm1(m, n, A) RESULT(norm_1)` |
| FUNCTION | `NM_Mtx_NormF` | 602 | `FUNCTION NM_Mtx_NormF(m, n, A) RESULT(norm_F)` |
| FUNCTION | `NM_Mtx_NormInf` | 609 | `FUNCTION NM_Mtx_NormInf(m, n, A) RESULT(norm_inf)` |
| SUBROUTINE | `NM_Mtx_Symm` | 620 | `SUBROUTINE NM_Mtx_Symm(side, uplo, m, n, alpha, A, B, beta, C, status)` |
| SUBROUTINE | `NM_Mtx_Symv` | 636 | `SUBROUTINE NM_Mtx_Symv(uplo, n, alpha, A, x, beta, y, status)` |
| FUNCTION | `NM_Mtx_Trace` | 668 | `FUNCTION NM_Mtx_Trace(n, A) RESULT(trace)` |
| SUBROUTINE | `NM_Mtx_Transpose` | 679 | `SUBROUTINE NM_Mtx_Transpose(m, n, A, AT, status)` |
| SUBROUTINE | `NM_Mtx_Trmm` | 691 | `SUBROUTINE NM_Mtx_Trmm(side, uplo, transa, diag, m, n, alpha, A, B, status)` |
| SUBROUTINE | `NM_Mtx_Trmv` | 707 | `SUBROUTINE NM_Mtx_Trmv(uplo, trans, diag, n, A, x, status)` |
| SUBROUTINE | `csr_create` | 749 | `SUBROUTINE csr_create(mat, nrows, ncols, nnz_estimate, ierr)` |
| SUBROUTINE | `csr_destroy` | 786 | `SUBROUTINE csr_destroy(mat)` |
| SUBROUTINE | `csr_destroy_method` | 798 | `SUBROUTINE csr_destroy_method(this)` |
| SUBROUTINE | `csr_init_from_coo` | 803 | `SUBROUTINE csr_init_from_coo(mat, nrows, ncols, coo_entries, n_entries, ierr)` |
| SUBROUTINE | `csr_init` | 847 | `SUBROUTINE csr_init(this, nrows, ncols, nnz, ierr)` |
| FUNCTION | `csr_get_value` | 854 | `FUNCTION csr_get_value(mat, row, col) RESULT(val)` |
| FUNCTION | `csr_get_value_method` | 870 | `FUNCTION csr_get_value_method(this, row, col) RESULT(val)` |
| SUBROUTINE | `csr_set_value` | 877 | `SUBROUTINE csr_set_value(mat, row, col, val, ierr)` |
| SUBROUTINE | `csr_set_value_method` | 895 | `SUBROUTINE csr_set_value_method(this, row, col, val, ierr)` |
| SUBROUTINE | `csr_add_value` | 903 | `SUBROUTINE csr_add_value(mat, row, col, val, ierr)` |
| SUBROUTINE | `csr_add_value_method` | 921 | `SUBROUTINE csr_add_value_method(this, row, col, val, ierr)` |
| SUBROUTINE | `csr_clear` | 929 | `SUBROUTINE csr_clear(mat)` |
| SUBROUTINE | `csr_zero_matrix` | 934 | `SUBROUTINE csr_zero_matrix(mat)` |
| SUBROUTINE | `csr_deallocate` | 939 | `SUBROUTINE csr_deallocate(mat)` |
| SUBROUTINE | `csr_scale` | 944 | `SUBROUTINE csr_scale(mat, alpha)` |
| SUBROUTINE | `csr_copy` | 950 | `SUBROUTINE csr_copy(src, dst, ierr)` |
| SUBROUTINE | `csr_add_scaled` | 972 | `SUBROUTINE csr_add_scaled(A, B, alpha, ierr)` |
| SUBROUTINE | `csr_axpy` | 992 | `SUBROUTINE csr_axpy(A, B, alpha, beta, ierr)` |
| SUBROUTINE | `csr_get_diagonal` | 1008 | `SUBROUTINE csr_get_diagonal(mat, diag, ierr)` |
| SUBROUTINE | `csr_set_diagonal` | 1026 | `SUBROUTINE csr_set_diagonal(mat, diag, ierr)` |
| SUBROUTINE | `csr_matvec` | 1043 | `SUBROUTINE csr_matvec(this, x, y)` |
| SUBROUTINE | `csr_matvec_trans` | 1058 | `SUBROUTINE csr_matvec_trans(this, x, y)` |
| FUNCTION | `csr_get_row_nnz` | 1071 | `FUNCTION csr_get_row_nnz(this, row) RESULT(nnz)` |
| SUBROUTINE | `csr_info` | 1082 | `SUBROUTINE csr_info(mat)` |
| SUBROUTINE | `csr_info_method` | 1095 | `SUBROUTINE csr_info_method(this)` |
| SUBROUTINE | `csr_print` | 1100 | `SUBROUTINE csr_print(mat, max_rows, max_cols, unit_num)` |
| SUBROUTINE | `csr_matvec_direct` | 1120 | `SUBROUTINE csr_matvec_direct(A, x, y)` |
| SUBROUTINE | `sparse_lsolve` | 1135 | `SUBROUTINE sparse_lsolve(n, val, col_ind, row_ptr, b, x)` |
| SUBROUTINE | `sparse_lsolve_msr` | 1153 | `SUBROUTINE sparse_lsolve_msr(n, alu, jlu, ju, b, x)` |
| SUBROUTINE | `sparse_matvec` | 1171 | `SUBROUTINE sparse_matvec(n, val, col_ind, row_ptr, x, y)` |
| SUBROUTINE | `sparse_matvec_trans` | 1188 | `SUBROUTINE sparse_matvec_trans(n, ncol, val, col_ind, row_ptr, x, y)` |
| SUBROUTINE | `sparse_usolve` | 1203 | `SUBROUTINE sparse_usolve(n, val, col_ind, row_ptr, b, x)` |
| SUBROUTINE | `sparse_usolve_msr` | 1221 | `SUBROUTINE sparse_usolve_msr(n, alu, jlu, ju, b, x)` |
| SUBROUTINE | `vec_add` | 1239 | `SUBROUTINE vec_add(n, x, y, z)` |
| SUBROUTINE | `vec_axpy` | 1246 | `SUBROUTINE vec_axpy(n, alpha, x, y)` |
| SUBROUTINE | `vec_copy` | 1255 | `SUBROUTINE vec_copy(n, x, y)` |
| FUNCTION | `vec_dot` | 1262 | `FUNCTION vec_dot(n, x, y) RESULT(dot)` |
| FUNCTION | `vec_norm2` | 1269 | `FUNCTION vec_norm2(n, x) RESULT(nrm)` |
| SUBROUTINE | `vec_scale` | 1276 | `SUBROUTINE vec_scale(n, alpha, x)` |
| SUBROUTINE | `vec_sub` | 1283 | `SUBROUTINE vec_sub(n, x, y, z)` |
| SUBROUTINE | `vec_zero` | 1290 | `SUBROUTINE vec_zero(n, x)` |
| SUBROUTINE | `assembly_map_init` | 1299 | `SUBROUTINE assembly_map_init(this, num_elements, max_dof)` |
| SUBROUTINE | `assembly_map_destroy` | 1309 | `SUBROUTINE assembly_map_destroy(this)` |
| SUBROUTINE | `csr_build_assembly_map` | 1317 | `SUBROUTINE csr_build_assembly_map(K, elem_dof, elem_ndof, num_elements, amap, ierr)` |
| FUNCTION | `csr_get_position` | 1343 | `FUNCTION csr_get_position(K, row, col) RESULT(pos)` |
| SUBROUTINE | `csr_fast_assemble_element` | 1366 | `SUBROUTINE csr_fast_assemble_element(K, Ke, amap, ie, ndof)` |
| SUBROUTINE | `csr_batch_assemble` | 1380 | `SUBROUTINE csr_batch_assemble(K, Ke_batch, amap, elem_list, num_batch, ndof)` |
| SUBROUTINE | `csr_analyze_bandwidth` | 1397 | `SUBROUTINE csr_analyze_bandwidth(K, bandwidth, profile, avg_row_width)` |
| SUBROUTINE | `csr_reorder_rcm` | 1417 | `SUBROUTINE csr_reorder_rcm(K, perm, inv_perm)` |
| SUBROUTINE | `add_neighbors_sorted` | 1468 | `SUBROUTINE add_neighbors_sorted(K, node, degree, visited, queue, back)` |
| SUBROUTINE | `sort_by_key` | 1500 | `SUBROUTINE sort_by_key(arr, key, n)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
