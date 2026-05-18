# `RT_Solv_Def.f90`

- **Source**: `L5_RT/Solver/RT_Solv_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Solv_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_AdvancedTimeIntegrator` (lines 74–97)

```fortran
  type, public :: RT_AdvancedTimeIntegrator
    integer(i4) :: method = 1          ! 1=Newmark, 2=HHT-?, 3=Generalized-?, 4=Central
    real(wp) :: dt = 0.0_wp
    real(wp) :: time = 0.0_wp
    integer(i4) :: step = 0

    ! Newmark parameters
    real(wp) :: beta = 0.25_wp, gamma = 0.5_wp

    ! HHT-alpha parameters
    real(wp) :: alpha = -0.1_wp

    ! Generalized-alpha parameters
    real(wp) :: alpha_m = 0.0_wp, alpha_f = 0.0_wp
    real(wp) :: gamma_ga = 0.5_wp, beta_ga = 0.25_wp

    ! State vectors
    real(wp), allocatable :: u_n(:), v_n(:), a_n(:), u_np1(:), v_np1(:), a_np1(:)
    real(wp), allocatable :: M(:,:), C(:,:), K(:,:)
    real(wp), allocatable :: F_ext_n(:), F_ext_np1(:), F_int_n(:), F_int_np1(:)
    real(wp), allocatable :: K_eff(:,:), F_eff(:)

    LOGICAL :: init = .FALSE.
  end type RT_AdvancedTimeIntegrator
```

### `RT_AdvancedNLSol` (lines 102–137)

```fortran
  type, public :: RT_AdvancedNLSol
    integer(i4) :: method = 1         ! Solution method (1=NR, 2=Arc-Length, etc.)
    integer(i4) :: max_iterations = 50
    integer(i4) :: convergence_typ = 4  ! 1=disp, 2=force, 3=energy, 4=mixed
    real(wp) :: tolerance_force = 1.0e-6_wp
    real(wp) :: tolerance_disp = 1.0e-6_wp
    real(wp) :: tolerance_energ = 1.0e-8_wp

    ! Arc-length parameters
    real(wp) :: arc_length_radi = 1.0_wp
    real(wp) :: arc_length_ds = 0.1_wp
    integer(i4) :: arc_length_type = 1

    ! Line search parameters
    real(wp) :: line_search_alp = 1.0_wp
    real(wp) :: line_search_eta = 0.5_wp
    integer(i4) :: max_line_search = 10

    ! Trust region parameters
    real(wp) :: trust_region_de = 1.0_wp
    real(wp) :: trust_region_et = 0.1_wp

    ! State variables
    integer(i4) :: iteration = 0
    real(wp) :: residual_norm = 0.0_wp
    real(wp) :: displacement_no = 0.0_wp
    real(wp) :: energy_norm = 0.0_wp
    logical :: converged = .FALSE.

    ! Solution vectors
    real(wp), allocatable :: u(:), du(:), R(:), K(:,:), F_ext(:)
    real(wp), allocatable :: u_arc(:), psi(:)
    real(wp) :: lambda = 0.0_wp

    LOGICAL :: init = .FALSE.
  end type RT_AdvancedNLSol
```

### `RT_Solv_Cfg_Desc` (lines 219–229)

```fortran
  TYPE, PUBLIC :: RT_Solv_Cfg_Desc
    INTEGER(i4) :: runtime_id = 0_i4
    CHARACTER(LEN=64) :: solver_label = ''
    TYPE(MD_LinearSolver_Desc), POINTER :: md_linear => NULL()
    TYPE(MD_NR_Algo), POINTER :: md_nr => NULL()
    TYPE(MD_Precond_Desc), POINTER :: md_precond => NULL()
    INTEGER(i4) :: n_dofs_total = 0_i4
    INTEGER(i4) :: n_eqns = 0_i4
    LOGICAL :: is_initialized = .FALSE.
    LOGICAL :: is_active = .TRUE.
  END TYPE RT_Solv_Cfg_Desc
```

### `RT_Solv_Itr_Desc_Cache` (lines 231–235)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Desc_Cache
    INTEGER(i4) :: linear_method = RT_SOLV_LINSOL_DIRECT
    INTEGER(i4) :: nr_strategy = RT_SOLV_NR_FULL
    LOGICAL :: unsymmetric_system = .FALSE.
  END TYPE RT_Solv_Itr_Desc_Cache
```

### `RT_Solv_Desc` (lines 237–240)

```fortran
  TYPE, PUBLIC :: RT_Solv_Desc
    TYPE(RT_Solv_Cfg_Desc) :: cfg
    TYPE(RT_Solv_Itr_Desc_Cache) :: itr
  END TYPE RT_Solv_Desc
```

### `RT_Solv_Stp_State` (lines 246–249)

```fortran
  TYPE, PUBLIC :: RT_Solv_Stp_State
    INTEGER(i4) :: n_cutbacks = 0_i4
    INTEGER(i4) :: total_iters = 0_i4
  END TYPE RT_Solv_Stp_State
```

### `RT_Solv_Itr_Ctrl` (lines 251–254)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Ctrl
    INTEGER(i4) :: curr_iter = 0_i4
    INTEGER(i4) :: max_iter_reached = 0_i4
  END TYPE RT_Solv_Itr_Ctrl
```

### `RT_Solv_Itr_Norms` (lines 256–262)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Norms
    REAL(wp) :: res_norm_abs = 0.0_wp
    REAL(wp) :: res_norm_rel = 1.0_wp
    REAL(wp) :: disp_norm_abs = 0.0_wp
    REAL(wp) :: disp_norm_rel = 1.0_wp
    REAL(wp) :: energy_norm = 0.0_wp
  END TYPE RT_Solv_Itr_Norms
```

### `RT_Solv_Itr_Refs` (lines 264–268)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Refs
    REAL(wp) :: res_ref = 1.0_wp
    REAL(wp) :: disp_ref = 1.0_wp
    REAL(wp) :: pnewdt_min = 1.0_wp
  END TYPE RT_Solv_Itr_Refs
```

### `RT_Solv_Itr_Flags` (lines 270–274)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Flags
    LOGICAL :: converged = .FALSE.
    LOGICAL :: cutback_requested = .FALSE.
    LOGICAL :: severe_discontinuity = .FALSE.
  END TYPE RT_Solv_Itr_Flags
```

### `RT_Solv_Itr_NRState` (lines 276–281)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_NRState
    TYPE(RT_Solv_Itr_Ctrl)  :: ctrl
    TYPE(RT_Solv_Itr_Norms) :: norms
    TYPE(RT_Solv_Itr_Refs)  :: refs
    TYPE(RT_Solv_Itr_Flags) :: flags
  END TYPE RT_Solv_Itr_NRState
```

### `RT_Solv_NRState` (lines 283–291)

```fortran
  TYPE, PUBLIC :: RT_Solv_NRState
    TYPE(RT_Solv_Stp_State) :: stp
    TYPE(RT_Solv_Itr_NRState) :: itr
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init => NRState_Init
    PROCEDURE :: Reset => NRState_Reset
    PROCEDURE :: UpdateNorms => NRState_UpdateNorms
  END TYPE RT_Solv_NRState
```

### `RT_Solv_Linear_Stp_State` (lines 296–306)

```fortran
  TYPE, PUBLIC :: RT_Solv_Linear_Stp_State
    INTEGER(i4) :: ndof = 0_i4
    INTEGER(i4) :: nnz = 0_i4
    INTEGER(i4) :: method = RT_SOLV_LINSOL_DIRECT
    LOGICAL :: unsymmetric = .FALSE.
    LOGICAL :: factorization_available = .FALSE.
    LOGICAL :: reuse_factorization = .FALSE.
    INTEGER(i4) :: factorization_age = 0_i4
    REAL(wp), POINTER :: rhs(:) => NULL()
    REAL(wp), POINTER :: du(:) => NULL()
  END TYPE RT_Solv_Linear_Stp_State
```

### `RT_Solv_Linear_Itr_State` (lines 308–315)

```fortran
  TYPE, PUBLIC :: RT_Solv_Linear_Itr_State
    INTEGER(i4) :: krylov_iter = 0_i4
    REAL(wp) :: krylov_tol_achieved = 0.0_wp
    REAL(wp) :: residual_initial = 0.0_wp
    REAL(wp) :: residual_final = 0.0_wp
    INTEGER(i4) :: solver_flag = RT_SOLV_STATUS_NOT_STARTED
    LOGICAL :: solved = .FALSE.
  END TYPE RT_Solv_Linear_Itr_State
```

### `RT_Solv_LinearState` (lines 317–324)

```fortran
  TYPE, PUBLIC :: RT_Solv_LinearState
    TYPE(RT_Solv_Linear_Stp_State) :: stp
    TYPE(RT_Solv_Linear_Itr_State) :: itr
    TYPE(ErrorStatusType) :: status
  CONTAINS
    PROCEDURE :: Init => LinearState_Init
    PROCEDURE :: Reset => LinearState_Reset
  END TYPE RT_Solv_LinearState
```

### `RT_Solv_Itr_Algo` (lines 329–358)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Algo
    INTEGER(i4) :: nr_max_iter = 16_i4
    INTEGER(i4) :: nr_max_severe = 50_i4
    INTEGER(i4) :: nr_max_cutbacks = 5_i4
    INTEGER(i4) :: nr_tangent_strategy = RT_SOLV_NR_FULL
    INTEGER(i4) :: nr_tangent_interval = 1_i4
    LOGICAL :: use_line_search = .FALSE.
    INTEGER(i4) :: ls_max_iter = 5_i4
    REAL(wp) :: ls_tolerance = 0.5_wp
    REAL(wp) :: cutback_factor = 0.25_wp
    REAL(wp) :: expand_factor = 1.5_wp
    INTEGER(i4) :: linsol_method = RT_SOLV_LINSOL_DIRECT
    INTEGER(i4) :: linsol_max_iter = 300_i4
    REAL(wp) :: linsol_tolerance = 1.0e-10_wp
    LOGICAL :: linsol_unsymmetric = .FALSE.
    INTEGER(i4) :: precond_type = 0_i4
    INTEGER(i4) :: ilu_fill_level = 0_i4
    REAL(wp) :: ilu_drop_tolerance = 1.0e-4_wp
    INTEGER(i4) :: amg_max_levels = 10_i4
    LOGICAL :: rebuild_precond_every_step = .FALSE.
    REAL(wp) :: conv_res_tol_rel = 5.0e-3_wp
    REAL(wp) :: conv_res_tol_abs = 0.0_wp
    REAL(wp) :: conv_disp_tol_rel = 1.0e-2_wp
    REAL(wp) :: conv_disp_tol_abs = 0.0_wp
    INTEGER(i4) :: conv_norm_type = RT_SOLV_NORM_L2
    LOGICAL :: conv_check_energy = .FALSE.
    REAL(wp) :: conv_energy_tol = 1.0e-5_wp
    REAL(wp) :: zero_force_tol = 1.0e-10_wp
    REAL(wp) :: singular_pivot_tol = 1.0e-12_wp
  END TYPE RT_Solv_Itr_Algo
```

### `RT_Solv` (lines 360–366)

```fortran
  TYPE, PUBLIC :: RT_Solv
    TYPE(RT_Solv_Itr_Algo) :: itr
  CONTAINS
    PROCEDURE :: Init => SolvAlgo_Init
    PROCEDURE :: SetNRParams => SolvAlgo_SetNR
    PROCEDURE :: SetLinearParams => SolvAlgo_SetLinear
  END TYPE RT_Solv
```

### `RT_Solv_Stp_Ctx` (lines 371–384)

```fortran
  TYPE, PUBLIC :: RT_Solv_Stp_Ctx
    INTEGER(i4) :: step_id = 0_i4
    INTEGER(i4) :: incr_id = 0_i4
    REAL(wp) :: step_time = 0.0_wp
    REAL(wp) :: total_time = 0.0_wp
    REAL(wp) :: time_increment = 0.0_wp
    REAL(wp) :: prev_time_increment = 0.0_wp
    INTEGER(i4) :: n_nodes = 0_i4
    INTEGER(i4) :: n_elements = 0_i4
    INTEGER(i4) :: n_active_dofs = 0_i4
    LOGICAL :: is_first_incr = .FALSE.
    INTEGER(i4) :: thread_id = 0_i4
    INTEGER(i4) :: n_threads = 1_i4
  END TYPE RT_Solv_Stp_Ctx
```

### `RT_Solv_Itr_Ctx` (lines 386–390)

```fortran
  TYPE, PUBLIC :: RT_Solv_Itr_Ctx
    INTEGER(i4) :: nr_iter_id = 0_i4
    LOGICAL :: is_first_iter = .FALSE.
    LOGICAL :: force_convergence_check = .FALSE.
  END TYPE RT_Solv_Itr_Ctx
```

### `RT_Solv_Ctx` (lines 392–398)

```fortran
  TYPE, PUBLIC :: RT_Solv_Ctx
    TYPE(RT_Solv_Stp_Ctx) :: stp
    TYPE(RT_Solv_Itr_Ctx) :: itr
  CONTAINS
    PROCEDURE :: Init => SolvCtx_Init
    PROCEDURE :: Update => SolvCtx_Update
  END TYPE RT_Solv_Ctx
```

### `RT_Solv_Conv_Itr_Ctx` (lines 403–418)

```fortran
  TYPE, PUBLIC :: RT_Solv_Conv_Itr_Ctx
    REAL(wp) :: res_tol_rel = 5.0e-3_wp
    REAL(wp) :: res_tol_abs = 0.0_wp
    REAL(wp) :: disp_tol_rel = 1.0e-2_wp
    REAL(wp) :: disp_tol_abs = 0.0_wp
    REAL(wp) :: energy_tol = 1.0e-5_wp
    INTEGER(i4) :: res_norm_type = RT_SOLV_NORM_L2
    INTEGER(i4) :: disp_norm_type = RT_SOLV_NORM_L2
    LOGICAL :: check_energy = .FALSE.
    LOGICAL :: severe_discontinuity_active = .FALSE.
    REAL(wp) :: computed_res_norm = 0.0_wp
    REAL(wp) :: computed_disp_norm = 0.0_wp
    REAL(wp) :: computed_energy_norm = 0.0_wp
    LOGICAL :: converged = .FALSE.
    LOGICAL :: check_performed = .FALSE.
  END TYPE RT_Solv_Conv_Itr_Ctx
```

### `RT_Solv_ConvergenceCtx` (lines 420–426)

```fortran
  TYPE, PUBLIC :: RT_Solv_ConvergenceCtx
    TYPE(RT_Solv_Conv_Itr_Ctx) :: itr
  CONTAINS
    PROCEDURE :: Init => ConvCtx_Init
    PROCEDURE :: Evaluate => ConvCtx_Evaluate
    PROCEDURE :: Reset => ConvCtx_Reset
  END TYPE RT_Solv_ConvergenceCtx
```

### `RT_Solv_Solve_Arg` (lines 702–722)

```fortran
TYPE, PUBLIC :: RT_Solv_Solve_Arg
  ! [IN] solver state
  TYPE(RT_Solv_Desc) :: desc             ! [IN]  solver descriptor
  TYPE(RT_Solv_State) :: state           ! [INOUT] solver state
  TYPE(RT_Solv_Algo) :: algo            ! [IN]  algorithm params

  ! [IN] solve parameters
  REAL(wp), ALLOCATABLE :: k_matrix(:,:)   ! [IN]  global stiffness matrix
  REAL(wp), ALLOCATABLE :: f_vector(:)     ! [IN]  global force vector
  REAL(wp), ALLOCATABLE :: u_vector(:)     ! [INOUT] displacement vector

  ! [IN] solver controls
  INTEGER(i4) :: max_iter                ! [IN]  maximum iterations
  REAL(wp) :: tolerance                  ! [IN]  convergence tolerance

  ! [OUT] solve results
  LOGICAL :: converged                   ! [OUT] convergence flag
  INTEGER(i4) :: n_iterations            ! [OUT] iterations taken
  INTEGER(i4) :: status_code             ! [OUT] solve status
  CHARACTER(len=256) :: message          ! [OUT] status message
END TYPE RT_Solv_Solve_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_CSR_Free` | 434 | `subroutine RT_CSR_Free(A)` |
| SUBROUTINE | `csr_destroy` | 440 | `subroutine csr_destroy(A)` |
| SUBROUTINE | `NRState_Init` | 458 | `SUBROUTINE NRState_Init(self)` |
| SUBROUTINE | `NRState_Reset` | 478 | `SUBROUTINE NRState_Reset(self)` |
| SUBROUTINE | `NRState_UpdateNorms` | 491 | `SUBROUTINE NRState_UpdateNorms(self, res_abs, disp_abs, res_ref, disp_ref)` |
| SUBROUTINE | `LinearState_Init` | 521 | `SUBROUTINE LinearState_Init(self, ndof, method)` |
| SUBROUTINE | `LinearState_Reset` | 539 | `SUBROUTINE LinearState_Reset(self)` |
| SUBROUTINE | `SolvAlgo_Init` | 555 | `SUBROUTINE SolvAlgo_Init(self)` |
| SUBROUTINE | `SolvAlgo_SetNR` | 570 | `SUBROUTINE SolvAlgo_SetNR(self, max_iter, max_cutbacks, tangent_strategy, use_ls)` |
| SUBROUTINE | `SolvAlgo_SetLinear` | 582 | `SUBROUTINE SolvAlgo_SetLinear(self, method, max_iter, tolerance, unsymm)` |
| SUBROUTINE | `SolvCtx_Init` | 600 | `SUBROUTINE SolvCtx_Init(self)` |
| SUBROUTINE | `SolvCtx_Update` | 614 | `SUBROUTINE SolvCtx_Update(self, step, incr, time, dt, nr_iter)` |
| SUBROUTINE | `ConvCtx_Init` | 635 | `SUBROUTINE ConvCtx_Init(self)` |
| FUNCTION | `ConvCtx_Evaluate` | 652 | `FUNCTION ConvCtx_Evaluate(self, res_norm, disp_norm, energy_norm) RESULT(converged)` |
| SUBROUTINE | `ConvCtx_Reset` | 688 | `SUBROUTINE ConvCtx_Reset(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
