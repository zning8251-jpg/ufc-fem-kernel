# `NM_Solv_SparsePakWrap.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_SparsePakWrap.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_SparsePakWrap`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_SparsePakWrap`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_SparsePakWrap`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_SparsePakWrap.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_SparsePakHandle` (lines 53–87)

```fortran
    TYPE :: UF_SparsePakHandle
        LOGICAL :: initialized = .FALSE.
        LOGICAL :: symbolic_done = .FALSE.
        LOGICAL :: numeric_done = .FALSE.
        INTEGER(i4) :: n = 0                        ! Matrix dimension
        INTEGER(i4) :: nnz = 0                      ! Non-zeros
        INTEGER(i4) :: reorder_type = NM_SPK_REORDER_RCM
        
        ! Permutation vectors
        INTEGER(i4), ALLOCATABLE :: perm(:)         ! Forward permutation
        INTEGER(i4), ALLOCATABLE :: perm_inv(:)     ! Inverse permutation
        
        ! CSR structure (reordered)
        INTEGER(i4), ALLOCATABLE :: row_ptr(:)      ! Reordered row pointers
        INTEGER(i4), ALLOCATABLE :: col_ind(:)      ! Reordered column indices
        
        ! Cholesky factor storage (envelope/skyline format)
        REAL(wp), ALLOCATABLE :: diag(:)            ! Diagonal elements
        REAL(wp), ALLOCATABLE :: env(:)             ! Envelope (lower triangle)
        INTEGER(i4), ALLOCATABLE :: xenv(:)         ! Envelope index
        INTEGER(i4) :: env_size = 0                 ! Envelope size
        
        ! General sparse factor (for ND/QMD)
        REAL(wp), ALLOCATABLE :: xlnz(:)            ! Factor values
        INTEGER(i4), ALLOCATABLE :: ixlnz(:)        ! Factor column pointers
        INTEGER(i4), ALLOCATABLE :: nzsub(:)        ! Row subscripts
        INTEGER(i4), ALLOCATABLE :: xnzsub(:)       ! Subscript pointers
        INTEGER(i4) :: nofnz = 0                    ! Number of factor nonzeros
        
        ! Statistics
        INTEGER(i4) :: fill_in = 0                  ! Fill-in count
        REAL(wp) :: factor_time = 0.0_wp
    CONTAINS
        PROCEDURE :: cleanup => handle_cleanup
    END TYPE UF_SparsePakHandle
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `spk_solve_csr` | 95 | `SUBROUTINE spk_solve_csr(A, b, x, reorder_type, ierr)` |
| SUBROUTINE | `spk_symbolic_csr` | 137 | `SUBROUTINE spk_symbolic_csr(A, handle, reorder_type, ierr)` |
| SUBROUTINE | `spk_numeric_csr` | 254 | `SUBROUTINE spk_numeric_csr(A, handle, ierr)` |
| SUBROUTINE | `spk_solve_factored` | 310 | `SUBROUTINE spk_solve_factored(handle, b, x, ierr)` |
| SUBROUTINE | `spk_cleanup` | 352 | `SUBROUTINE spk_cleanup(handle)` |
| SUBROUTINE | `handle_cleanup` | 357 | `SUBROUTINE handle_cleanup(this)` |
| SUBROUTINE | `spk_reorder_csr` | 387 | `SUBROUTINE spk_reorder_csr(A, reorder_type, perm, perm_inv, ierr)` |
| FUNCTION | `spk_get_reorder_name` | 411 | `FUNCTION spk_get_reorder_name(reorder_type) RESULT(name)` |
| SUBROUTINE | `build_adjacency` | 435 | `SUBROUTINE build_adjacency(A, adj_row, adj, ierr)` |
| SUBROUTINE | `apply_rcm` | 507 | `SUBROUTINE apply_rcm(n, adj_row, adj, mask, perm, ierr)` |
| SUBROUTINE | `apply_qmd` | 587 | `SUBROUTINE apply_qmd(n, adj_row, adj, mask, deg, perm, ierr)` |
| SUBROUTINE | `apply_nd` | 643 | `SUBROUTINE apply_nd(n, adj_row, adj, mask, perm, ierr)` |
| SUBROUTINE | `compute_envelope` | 659 | `SUBROUTINE compute_envelope(n, adj_row, adj, perm, perm_inv, xenv, &` |
| SUBROUTINE | `add_to_envelope` | 711 | `SUBROUTINE add_to_envelope(handle, i, j, val)` |
| SUBROUTINE | `envelope_cholesky` | 730 | `SUBROUTINE envelope_cholesky(n, xenv, diag, env, ierr)` |
| SUBROUTINE | `envelope_forward_solve_partial` | 783 | `SUBROUTINE envelope_forward_solve_partial(iband, xenv, diag, env)` |
| SUBROUTINE | `envelope_forward_solve` | 815 | `SUBROUTINE envelope_forward_solve(n, xenv, diag, env, rhs)` |
| SUBROUTINE | `envelope_backward_solve` | 846 | `SUBROUTINE envelope_backward_solve(n, xenv, diag, env, rhs)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
