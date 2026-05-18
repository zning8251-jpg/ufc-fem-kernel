# `NM_Solv_AMGInterface.f90`

- **Source**: `L2_NM/Solver/LinSolv/NM_Solv_AMGInterface.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `NM_Solv_AMGInterface`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_AMGInterface`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_AMGInterface`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/LinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/LinSolv/NM_Solv_AMGInterface.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_AMG_Control` (lines 39–65)

```fortran
    TYPE :: UF_AMG_Control
        ! Coarsening parameters
        REAL(wp) :: st_parameter = 0.25_wp      ! Strong connection threshold
        INTEGER(i4) :: aggressive = 1            ! Aggressive coarsening steps
        INTEGER(i4) :: max_levels = 100          ! Maximum coarsening levels
        INTEGER(i4) :: max_points = 1            ! Max points on coarsest level
        REAL(wp) :: reduction = 0.8_wp           ! Stagnation detection
        
        ! Smoother parameters
        INTEGER(i4) :: smoother = 2              ! 1=Jacobi, 2=Gauss-Seidel
        INTEGER(i4) :: pre_smoothing = 2         ! Pre-smoothing iterations
        INTEGER(i4) :: post_smoothing = 2        ! Post-smoothing iterations
        REAL(wp) :: damping = 0.8_wp             ! Jacobi damping factor
        
        ! V-cycle parameters
        INTEGER(i4) :: v_iterations = 1          ! V-cycle iterations per apply
        INTEGER(i4) :: coarse_solver = 3         ! Coarse solver type
        INTEGER(i4) :: coarse_solver_its = 10    ! Coarse solver iterations
        
        ! Krylov solver for amg_solve
        INTEGER(i4) :: krylov_solver = 3         ! 0=AMG,1=PCG,2=GMRES,3=BiCGSTAB,4=MINRES
        REAL(wp) :: rel_tol = 1.0E-6_wp          ! Relative tolerance
        
        ! Output control
        INTEGER(i4) :: print_level = 0           ! 0=silent, 1=summary, 2=details
        
    END TYPE UF_AMG_Control
```

### `UF_AMG_Info` (lines 70–80)

```fortran
    TYPE :: UF_AMG_Info
        INTEGER(i4) :: flag = 0                  ! Error/warning flag
        INTEGER(i4) :: clevels = 0               ! Number of coarse levels
        INTEGER(i4) :: cpoints = 0               ! Points on coarsest level
        INTEGER(i4) :: coarse_ops = 0            ! Coarse level operations
        REAL(wp) :: operator_complexity = 0.0_wp ! Sum(nnz)/nnz(A)
        REAL(wp) :: grid_complexity = 0.0_wp     ! Sum(n)/n(A)
        REAL(wp) :: setup_time = 0.0_wp          ! Setup time (seconds)
        REAL(wp) :: apply_time = 0.0_wp          ! Total apply time
        INTEGER(i4) :: apply_count = 0           ! Number of applies
    END TYPE UF_AMG_Info
```

### `UF_AMG_Precond` (lines 85–109)

```fortran
    TYPE :: UF_AMG_Precond
        INTEGER(i4) :: n = 0                     ! Problem size
        INTEGER(i4) :: nnz = 0                   ! Number of non-zeros
        LOGICAL :: is_setup = .FALSE.            ! Setup complete flag
        
        ! Control and info
        TYPE(UF_AMG_Control) :: control
        TYPE(UF_AMG_Info) :: info
        
        ! HSL MI20 data structures (actual AMG data)
        TYPE(mi20_data), ALLOCATABLE :: coarse_data(:)
        TYPE(mi20_control) :: mi20_ctrl
        TYPE(mi20_solve_control) :: solve_ctrl
        TYPE(mi20_info) :: mi20_info
        TYPE(mi20_keep) :: keep
        
        ! Coordinate format storage for setup
        INTEGER(i4), ALLOCATABLE :: row(:)
        INTEGER(i4), ALLOCATABLE :: col(:)
        REAL(wp), ALLOCATABLE :: val(:)
        
    CONTAINS
        PROCEDURE :: destroy => amg_precond_destroy
        
    END TYPE UF_AMG_Precond
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `amg_set_defaults` | 128 | `SUBROUTINE amg_set_defaults(control)` |
| SUBROUTINE | `amg_setup` | 166 | `SUBROUTINE amg_setup(amg, K, ierr, control)` |
| SUBROUTINE | `amg_apply` | 277 | `SUBROUTINE amg_apply(amg, x, y)` |
| SUBROUTINE | `amg_solve` | 328 | `SUBROUTINE amg_solve(amg, b, x, ierr)` |
| SUBROUTINE | `amg_destroy` | 380 | `SUBROUTINE amg_destroy(amg)` |
| SUBROUTINE | `amg_precond_destroy` | 387 | `SUBROUTINE amg_precond_destroy(this)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
