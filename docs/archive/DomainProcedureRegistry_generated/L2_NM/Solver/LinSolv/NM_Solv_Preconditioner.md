# `NM_Solv_Preconditioner.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_Preconditioner.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Preconditioner`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Preconditioner`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Preconditioner`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_Preconditioner.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_Precond` (lines 65–119)

```fortran
    TYPE, PUBLIC :: UF_Precond
        INTEGER(i4) :: ptype = NM_PRECOND_NONE   ! Preconditioner type
        INTEGER(i4) :: n = 0                   ! Matrix dimension
        REAL(wp) :: omega = 1.0_wp            ! Relaxation parameter (SSOR)
        INTEGER(i4) :: lfil = 10              ! Fill-in level (ILUT/ILUK)
        REAL(wp) :: droptol = 1.0E-4_wp       ! Drop tolerance (ILUT)
        
        ! Jacobi preconditioner
        REAL(wp), ALLOCATABLE :: diag_inv(:)  ! Inverted diagonal
        
        ! ILU factorization storage (MSR format)
        REAL(wp), ALLOCATABLE :: alu(:)       ! L and U values
        INTEGER(i4), ALLOCATABLE :: jlu(:)    ! Column indices
        INTEGER(i4), ALLOCATABLE :: ju(:)     ! Pointers to U diagonal
        INTEGER(i4) :: iwk = 0                ! Work array size
        
        ! ILU(k) work arrays
        INTEGER(i4), ALLOCATABLE :: levs(:)    ! Level array for ILU(k)
        REAL(wp), ALLOCATABLE :: w(:)          ! Work array
        INTEGER(i4), ALLOCATABLE :: jw(:)      ! Integer work array
        
        ! IC(0) storage
        REAL(wp), ALLOCATABLE :: ic_diag(:)    ! IC diagonal factors
        
        ! SSOR storage (uses original matrix)
        TYPE(UF_CSRMatrix), POINTER :: mat_ptr => NULL()  ! Pointer to original matrix
        REAL(wp), ALLOCATABLE :: ssor_d(:)       ! True diagonal of A
        REAL(wp), ALLOCATABLE :: ssor_da(:)      ! Modified diagonal for SSOR
        REAL(wp), ALLOCATABLE :: ssor_da1(:)     ! Inverse of ssor_da
        INTEGER(i4), ALLOCATABLE :: jdiag(:)     ! Diagonal index pointers
        
        ! AMG data structures (HSL MI20)
        TYPE(mi20_data), ALLOCATABLE :: amg_coarse(:)
        TYPE(mi20_control) :: amg_ctrl
        TYPE(mi20_solve_control) :: amg_solve_ctrl
        TYPE(mi20_info) :: amg_info
        TYPE(mi20_keep) :: amg_keep
        INTEGER(i4), ALLOCATABLE :: amg_row(:)
        INTEGER(i4), ALLOCATABLE :: amg_col(:)
        REAL(wp), ALLOCATABLE :: amg_val(:)
        
        ! Block preconditioner parameters
        INTEGER(i4) :: block_size = 1         ! Block size (e.g., 3 for 3D, 6 for shell)
        INTEGER(i4) :: nblocks = 0            ! Number of blocks
        REAL(wp), ALLOCATABLE :: block_diag(:,:,:)  ! Block diagonal inverses (bs x bs x nblocks)
        REAL(wp), ALLOCATABLE :: block_alu(:)       ! Block ILU values
        INTEGER(i4), ALLOCATABLE :: block_jlu(:)    ! Block ILU column indices
        INTEGER(i4), ALLOCATABLE :: block_ju(:)     ! Block ILU U pointers
        
        LOGICAL :: is_setup = .FALSE.
    CONTAINS
        PROCEDURE :: setup => precond_setup_method
        PROCEDURE :: apply => precond_apply_method
        PROCEDURE :: destroy => precond_destroy_method
    END TYPE UF_Precond
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `precond_create` | 126 | `SUBROUTINE precond_create(pc, ptype, n, ierr)` |
| SUBROUTINE | `precond_destroy` | 144 | `SUBROUTINE precond_destroy(pc)` |
| SUBROUTINE | `precond_destroy_method` | 183 | `SUBROUTINE precond_destroy_method(this)` |
| SUBROUTINE | `precond_setup` | 191 | `SUBROUTINE precond_setup(pc, mat, ierr)` |
| SUBROUTINE | `precond_setup_method` | 257 | `SUBROUTINE precond_setup_method(this, mat, ierr)` |
| SUBROUTINE | `precond_apply` | 267 | `SUBROUTINE precond_apply(pc, x, y)` |
| SUBROUTINE | `precond_apply_method` | 308 | `SUBROUTINE precond_apply_method(this, x, y)` |
| SUBROUTINE | `setup_jacobi` | 319 | `SUBROUTINE setup_jacobi(pc, mat, ierr)` |
| SUBROUTINE | `apply_jacobi` | 356 | `SUBROUTINE apply_jacobi(pc, x, y)` |
| SUBROUTINE | `setup_ilu0` | 373 | `SUBROUTINE setup_ilu0(pc, mat, ierr)` |
| SUBROUTINE | `setup_ilut` | 468 | `SUBROUTINE setup_ilut(pc, mat, ierr)` |
| SUBROUTINE | `apply_ilu` | 656 | `SUBROUTINE apply_ilu(pc, x, y)` |
| SUBROUTINE | `setup_block_jacobi` | 698 | `SUBROUTINE setup_block_jacobi(pc, mat, ierr)` |
| SUBROUTINE | `block_lu_invert` | 778 | `SUBROUTINE block_lu_invert(A, n, ierr)` |
| SUBROUTINE | `apply_block_jacobi` | 895 | `SUBROUTINE apply_block_jacobi(pc, x, y)` |
| SUBROUTINE | `setup_block_ilu0` | 925 | `SUBROUTINE setup_block_ilu0(pc, mat, ierr)` |
| SUBROUTINE | `apply_block_ilu` | 966 | `SUBROUTINE apply_block_ilu(pc, x, y)` |
| SUBROUTINE | `precond_set_block_size` | 980 | `SUBROUTINE precond_set_block_size(pc, block_size)` |
| SUBROUTINE | `setup_ssor_full` | 993 | `SUBROUTINE setup_ssor_full(pc, mat, ierr)` |
| SUBROUTINE | `apply_ssor_full` | 1034 | `SUBROUTINE apply_ssor_full(pc, x, y)` |
| SUBROUTINE | `setup_ic0` | 1115 | `SUBROUTINE setup_ic0(pc, mat, ierr)` |
| SUBROUTINE | `setup_ick` | 1245 | `SUBROUTINE setup_ick(pc, mat, ierr)` |
| SUBROUTINE | `apply_ic` | 1259 | `SUBROUTINE apply_ic(pc, x, y)` |
| SUBROUTINE | `setup_iluk_wrap` | 1306 | `SUBROUTINE setup_iluk_wrap(pc, mat, ierr)` |
| SUBROUTINE | `setup_amg` | 1365 | `SUBROUTINE setup_amg(pc, mat, ierr)` |
| SUBROUTINE | `apply_amg` | 1419 | `SUBROUTINE apply_amg(pc, x, y)` |
| SUBROUTINE | `setup_ssor_eisenstat` | 1452 | `SUBROUTINE setup_ssor_eisenstat(pc, mat, ierr)` |
| SUBROUTINE | `apply_ssor_eisenstat` | 1519 | `SUBROUTINE apply_ssor_eisenstat(pc, x, y)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
