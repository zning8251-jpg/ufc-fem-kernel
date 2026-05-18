# `RT_Solv_Proc.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Proc.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Solv_Proc`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Proc`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv`
- **第四段角色（四段式）**: `_Proc`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Proc.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Solv_Init_In` (lines 43–63)

```fortran
  TYPE, PUBLIC :: RT_Solv_Init_In
    ! System size
    INTEGER(i4) :: n_dofs     = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_nodes    = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_Desc),   POINTER :: desc => NULL()
    TYPE(RT_Solv_NRState),     POINTER :: nr_state => NULL()
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    
    ! Options
    LOGICAL     :: validate_config           = .TRUE.
    LOGICAL     :: preallocate_solver_memory = .FALSE.
    
    ! Parallel context
    INTEGER(i4) :: n_threads  = 1_i4
    INTEGER(i4) :: comm_rank  = 0_i4
    INTEGER(i4) :: comm_size  = 1_i4
  END TYPE RT_Solv_Init_In
```

### `RT_Solv_Init_Out` (lines 68–77)

```fortran
  TYPE, PUBLIC :: RT_Solv_Init_Out
    ! Status
    TYPE(ErrorStatusType) :: status
    
    ! Diagnostics
    LOGICAL :: initialized = .FALSE.
    CHARACTER(LEN=256) :: message = ''
    INTEGER(i4) :: solver_memory_mb = 0_i4
    INTEGER(i4) :: max_dofs_supported = 0_i4
  END TYPE RT_Solv_Init_Out
```

### `RT_Solv_Equilibrium_In` (lines 84–103)

```fortran
  TYPE, PUBLIC :: RT_Solv_Equilibrium_In
    ! [NON_OWNING_PTR] External load vector [ndof]; caller-owned
    REAL(wp), POINTER :: external_force(:) => NULL()
    ! [NON_OWNING_PTR] Internal force vector [ndof]; caller-owned
    REAL(wp), POINTER :: internal_force(:) => NULL()
    ! [NON_OWNING_PTR] Current displacement [ndof]; caller-owned
    REAL(wp), POINTER :: displacement(:)  => NULL()
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_Desc),   POINTER :: desc => NULL()
    TYPE(RT_Solv_NRState),     POINTER :: nr_state => NULL()
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    TYPE(RT_Solv_Ctx),         POINTER :: ctx => NULL()
    
    ! Options
    LOGICAL :: compute_tangent   = .TRUE.
    LOGICAL :: use_line_search   = .FALSE.
    LOGICAL :: check_convergence = .TRUE.
  END TYPE RT_Solv_Equilibrium_In
```

### `RT_Solv_Equilibrium_Out` (lines 109–127)

```fortran
  TYPE, PUBLIC :: RT_Solv_Equilibrium_Out
    ! Output vectors (ALLOCATABLE allowed on _Out side)
    REAL(wp), ALLOCATABLE :: residual(:)                ! [ndof] out-of-balance force
    REAL(wp), ALLOCATABLE :: displacement_correction(:) ! [ndof] du
    
    ! Convergence
    LOGICAL     :: converged          = .FALSE.
    LOGICAL     :: cutback_requested  = .FALSE.
    REAL(wp)    :: pnewdt             = 1.0_wp
    
    ! Statistics
    INTEGER(i4) :: nr_iterations = 0_i4
    REAL(wp)    :: res_norm      = 0.0_wp
    REAL(wp)    :: disp_norm     = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Equilibrium_Out
```

### `RT_Solv_Linear_In` (lines 133–153)

```fortran
  TYPE, PUBLIC :: RT_Solv_Linear_In
    ! System matrix handle (opaque handle to assembled K matrix)
    INTEGER(i4) :: matrix_handle = -1_i4
    ! [NON_OWNING_PTR] RHS vector [ndof]; caller-owned
    REAL(wp), POINTER :: rhs(:) => NULL()
    
    ! CSR matrix data (non-owning pointers to assembled K)
    INTEGER(i4), POINTER :: K_row_ptr(:) => NULL()
    INTEGER(i4), POINTER :: K_col_idx(:) => NULL()
    REAL(wp),    POINTER :: K_values(:)  => NULL()
    INTEGER(i4) :: n_dof = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_LinearState), POINTER :: linear_state => NULL()
    TYPE(RT_Solv),             POINTER :: algo => NULL()
    TYPE(RT_Solv_Ctx),         POINTER :: ctx => NULL()
    
    ! Options
    LOGICAL :: reuse_factorization       = .FALSE.
    LOGICAL :: compute_condition_number  = .FALSE.
  END TYPE RT_Solv_Linear_In
```

### `RT_Solv_Linear_Out` (lines 159–173)

```fortran
  TYPE, PUBLIC :: RT_Solv_Linear_Out
    ! Solution vector (ALLOCATABLE on _Out side)
    REAL(wp), ALLOCATABLE :: solution(:)          ! [ndof] du
    
    ! Solver statistics
    INTEGER(i4) :: iterations_used      = 0_i4
    REAL(wp)    :: achieved_tolerance   = 0.0_wp
    REAL(wp)    :: condition_number_est = 0.0_wp
    
    ! Status
    INTEGER(i4) :: solver_flag         = 0_i4
    LOGICAL     :: solved_successfully = .FALSE.
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Linear_Out
```

### `RT_Solv_Convergence_In` (lines 178–195)

```fortran
  TYPE, PUBLIC :: RT_Solv_Convergence_In
    ! Current norms
    REAL(wp) :: res_norm_abs  = 0.0_wp
    REAL(wp) :: disp_norm_abs = 0.0_wp
    REAL(wp) :: energy_norm   = 0.0_wp
    
    ! Reference norms
    REAL(wp) :: res_norm_ref  = 1.0_wp
    REAL(wp) :: disp_norm_ref = 1.0_wp
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_NRState),        POINTER :: nr_state => NULL()
    TYPE(RT_Solv),                POINTER :: algo => NULL()
    TYPE(RT_Solv_ConvergenceCtx), POINTER :: conv_ctx => NULL()
    
    ! Force flags
    LOGICAL :: force_check = .FALSE.
  END TYPE RT_Solv_Convergence_In
```

### `RT_Solv_Convergence_Out` (lines 200–217)

```fortran
  TYPE, PUBLIC :: RT_Solv_Convergence_Out
    ! Result
    LOGICAL  :: converged       = .FALSE.
    LOGICAL  :: check_performed = .FALSE.
    
    ! Criteria status
    LOGICAL  :: res_criterion_satisfied    = .FALSE.
    LOGICAL  :: disp_criterion_satisfied   = .FALSE.
    LOGICAL  :: energy_criterion_satisfied = .FALSE.
    
    ! Computed values
    REAL(wp) :: computed_res_rel  = 0.0_wp
    REAL(wp) :: computed_disp_rel = 0.0_wp
    
    ! Status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Convergence_Out
```

### `RT_Solv_Cutback_In` (lines 222–236)

```fortran
  TYPE, PUBLIC :: RT_Solv_Cutback_In
    ! Current state
    REAL(wp)    :: current_dt           = 0.0_wp
    REAL(wp)    :: pnewdt_from_physics  = 1.0_wp
    
    ! Cutback reason: 0=None, 1=Divergence, 2=Physics
    INTEGER(i4) :: cutback_reason = 0_i4
    
    ! Four-type references (bundled for Impl convenience)
    TYPE(RT_Solv_NRState), POINTER :: nr_state => NULL()
    TYPE(RT_Solv),         POINTER :: algo => NULL()
    
    ! Options
    LOGICAL     :: allow_expansion = .TRUE.
  END TYPE RT_Solv_Cutback_In
```

### `RT_Solv_Cutback_Out` (lines 241–255)

```fortran
  TYPE, PUBLIC :: RT_Solv_Cutback_Out
    ! New time increment
    REAL(wp)    :: new_dt        = 0.0_wp
    REAL(wp)    :: dt_multiplier = 1.0_wp
    
    ! Status flags
    LOGICAL     :: cutback_applied      = .FALSE.
    LOGICAL     :: expansion_applied    = .FALSE.
    INTEGER(i4) :: n_cutbacks           = 0_i4
    LOGICAL     :: max_cutbacks_reached = .FALSE.
    
    ! Error status
    TYPE(ErrorStatusType) :: status
    CHARACTER(LEN=256)    :: message = ''
  END TYPE RT_Solv_Cutback_Out
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Solv_Init_Interface` | 263 | `SUBROUTINE RT_Solv_Init_Interface(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Solv_Equilibrium_Interface` | 276 | `SUBROUTINE RT_Solv_Equilibrium_Interface(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Solv_Linear_Interface` | 289 | `SUBROUTINE RT_Solv_Linear_Interface(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Solv_Convergence_Interface` | 302 | `SUBROUTINE RT_Solv_Convergence_Interface(desc, state, algo, ctx, inp, out)` |
| SUBROUTINE | `RT_Solv_Cutback_Interface` | 315 | `SUBROUTINE RT_Solv_Cutback_Interface(desc, state, algo, ctx, inp, out)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
