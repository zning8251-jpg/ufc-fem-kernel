# `RT_Cont_Def.f90`

- **Source**: `L5_RT/Contact/RT_Cont_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `RT_Cont_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Cont_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Cont`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Contact`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Contact/RT_Cont_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_Contact_Desc` (lines 89–122)

```fortran
  TYPE, PUBLIC :: RT_Contact_Desc
    !-- Identity
    INTEGER(i4)       :: n_contact_pairs = 0_i4
    CHARACTER(LEN=64) :: contact_name    = ''
    LOGICAL           :: is_initialized  = .FALSE.

    !-- Contact pair surface IDs
    INTEGER(i4), POINTER :: master_surf_ids(:) => NULL()
    INTEGER(i4), POINTER :: slave_surf_ids(:)  => NULL()

    !-- Per-pair type and friction model (RT_CONT_* constants)
    INTEGER(i4), POINTER :: contact_types(:)   => NULL()
    INTEGER(i4), POINTER :: friction_models(:) => NULL()

    !-- Contact parameters
    REAL(wp), POINTER :: friction_coeffs(:)   => NULL()
    REAL(wp), POINTER :: penalty_stiffness(:) => NULL()
    REAL(wp), POINTER :: clearance(:)         => NULL()

    !-- Search tolerances
    REAL(wp) :: global_search_tol  = 1.0e-6_wp
    REAL(wp) :: local_search_tol   = 1.0e-8_wp
    REAL(wp) :: search_radius_factor = 1.1_wp

    !-- Initial adjustment
    LOGICAL  :: adjust_slave_nodes = .FALSE.
    REAL(wp) :: adjust_tolerance   = 1.0e-6_wp

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: AddPair
    PROCEDURE :: SetFriction
    PROCEDURE :: Finalize
  END TYPE RT_Contact_Desc
```

### `RT_Contact_State` (lines 128–176)

```fortran
  TYPE, PUBLIC :: RT_Contact_State
    !-- Pair status (RT_CONT_PAIR_* constants)
    LOGICAL,     POINTER :: pair_active(:) => NULL()
    INTEGER(i4), POINTER :: pair_status(:) => NULL()
    INTEGER(i4) :: n_active_pairs = 0_i4
    INTEGER(i4) :: n_open_pairs   = 0_i4
    INTEGER(i4) :: n_closed_pairs = 0_i4

    !-- Global contact force
    REAL(wp), POINTER :: f_contact(:) => NULL()
    REAL(wp) :: total_contact_force = 0.0_wp
    REAL(wp) :: max_contact_force   = 0.0_wp

    !-- Gap / penetration statistics
    REAL(wp), POINTER :: penetration(:) => NULL()
    REAL(wp) :: max_penetration = 0.0_wp
    REAL(wp) :: avg_penetration = 0.0_wp
    REAL(wp) :: max_gap         = 0.0_wp

    !-- Friction state
    REAL(wp), POINTER :: friction_force(:) => NULL()
    LOGICAL,  POINTER :: is_sticking(:)    => NULL()
    INTEGER(i4) :: n_sticking = 0_i4
    INTEGER(i4) :: n_sliding  = 0_i4

    !-- Energy bookkeeping
    REAL(wp) :: contact_energy = 0.0_wp

    !-- Convergence
    LOGICAL           :: converged  = .FALSE.
    INTEGER(i4)       :: iterations = 0_i4
    TYPE(ErrorStatusType) :: status

    !-- Augmented Lagrange state (active only when enforcement_method == RT_CONT_ENFORCE_AUG_LAGRANGE)
    !   Double-buffer: lambda_n holds committed multipliers; lambda_trial holds trial values
    !   during the current Uzawa outer iteration.
    REAL(wp), POINTER :: lambda_n(:)     => NULL()  !< Committed Lagrange multipliers [n_pairs]
    REAL(wp), POINTER :: lambda_trial(:) => NULL()  !< Trial Lagrange multipliers    [n_pairs]
    INTEGER(i4)       :: uzawa_iter      = 0_i4     !< Current Uzawa outer-iteration counter
    LOGICAL           :: uzawa_converged = .FALSE.  !< .TRUE. when ||delta_lambda|| < tol_aug

  CONTAINS
    PROCEDURE :: Reset
    PROCEDURE :: UpdateStatus
    PROCEDURE :: AggregateStatistics
    PROCEDURE :: AugLagInit
    PROCEDURE :: AugLagCommit
    PROCEDURE :: AugLagRollback
  END TYPE RT_Contact_State
```

### `RT_Contact_Algo` (lines 182–217)

```fortran
  TYPE, PUBLIC :: RT_Contact_Algo
    !-- Discretization (RT_CONT_DISC_* constants)
    INTEGER(i4) :: discretization_method = RT_CONT_DISC_NODE_TO_SURF

    !-- Constraint enforcement (RT_CONT_ENFORCE_* constants)
    INTEGER(i4) :: enforcement_method    = RT_CONT_ENFORCE_PENALTY
    REAL(wp)    :: penalty_scale_factor  = 1.0_wp
    REAL(wp)    :: lagrange_init         = 0.0_wp

    !-- Friction (RT_CONT_FRICTION_* constants)
    INTEGER(i4) :: friction_model        = RT_CONT_FRICTION_COULOMB
    REAL(wp)    :: friction_decay_coeff  = 0.0_wp
    REAL(wp)    :: slip_tolerance        = 1.0e-8_wp

    !-- Search strategy
    INTEGER(i4) :: search_frequency  = 10_i4  ! Rebuild BVH every N increments
    LOGICAL     :: use_global_search = .TRUE.
    LOGICAL     :: use_adaptive_rebuild = .TRUE.

    !-- Contact damping
    LOGICAL  :: use_damping   = .FALSE.
    REAL(wp) :: damping_factor = 0.05_wp

    !-- Augmented Lagrange (Uzawa outer-iteration) parameters
    !   Only used when enforcement_method == RT_CONT_ENFORCE_AUG_LAGRANGE
    INTEGER(i4) :: n_aug_max = 5_i4         !< Max Uzawa outer iterations
    REAL(wp)    :: rho_aug   = 1.0_wp       !< Augmentation penalty  rho (lambda update scale)
    REAL(wp)    :: tol_aug   = 1.0e-6_wp    !< Uzawa convergence: ||delta_lambda||_inf < tol_aug

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: SelectEnforcement
    PROCEDURE :: ConfigureFriction
    PROCEDURE :: ConfigureSearch
    PROCEDURE :: ConfigureAugLag
  END TYPE RT_Contact_Algo
```

### `RT_Contact_Ctx` (lines 223–259)

```fortran
  TYPE, PUBLIC :: RT_Contact_Ctx
    !-- Current pair index
    INTEGER(i4) :: current_pair_idx = 0_i4

    !-- Temporary geometry (stack scalars)
    REAL(wp) :: gap_distance      = 0.0_wp
    REAL(wp) :: penetration_depth = 0.0_wp
    REAL(wp) :: contact_pressure  = 0.0_wp

    !-- Local frame (stack arrays ?? size fixed)
    REAL(wp) :: normal_vector(3)    = 0.0_wp
    REAL(wp) :: tangent_vector(3,2) = 0.0_wp
    REAL(wp) :: slip_direction(3)   = 0.0_wp

    !-- Closest-point projection
    REAL(wp) :: closest_pt(3) = 0.0_wp
    REAL(wp) :: gp_xi   = 0.0_wp
    REAL(wp) :: gp_eta  = 0.0_wp

    !-- Shape function scratch (N_master / N_slave up to 4 nodes)
    REAL(wp) :: shape_master(4) = 0.0_wp
    REAL(wp) :: shape_slave(4)  = 0.0_wp

    !-- Node/element indices
    INTEGER(i4) :: master_node_id  = 0_i4
    INTEGER(i4) :: slave_node_id   = 0_i4
    INTEGER(i4) :: contact_elem_id = 0_i4

    !-- Work pointers (must be attached before use; NO ALLOCATABLE here)
    REAL(wp), POINTER :: temp_force(:) => NULL()
    REAL(wp), POINTER :: temp_disp(:)  => NULL()

  CONTAINS
    PROCEDURE :: AttachBuffers
    PROCEDURE :: ClearTemporaries
    PROCEDURE :: Detach
  END TYPE RT_Contact_Ctx
```

### `RT_Cont_Dispatch_Arg` (lines 267–283)

```fortran
  TYPE, PUBLIC :: RT_Cont_Dispatch_Arg
    ! [IN] contact state
    TYPE(RT_Contact_Desc) :: desc             ! [IN]  contact descriptor
    TYPE(RT_Contact_State) :: state           ! [INOUT] contact state
    TYPE(RT_Contact_Algo) :: algo             ! [IN]  algorithm params
    TYPE(RT_Contact_Ctx) :: ctx               ! [INOUT] contact context

    ! [IN] search parameters
    REAL(wp) :: search_tolerance              ! [IN]  gap tolerance
    REAL(wp) :: current_time                  ! [IN]  current time

    ! [OUT] contact results
    REAL(wp), ALLOCATABLE :: contact_forces(:,:) ! [OUT] contact forces
    INTEGER(i4) :: n_contact_pairs            ! [OUT] number of active pairs
    INTEGER(i4) :: status_code                ! [OUT] contact status
    CHARACTER(len=256) :: message             ! [OUT] status message
  END TYPE RT_Cont_Dispatch_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `RT_Cont_Desc_Init` | 306 | `SUBROUTINE RT_Cont_Desc_Init(self)` |
| SUBROUTINE | `RT_Cont_Desc_AddPair` | 311 | `SUBROUTINE RT_Cont_Desc_AddPair(self, master_id, slave_id, contact_type)` |
| SUBROUTINE | `RT_Cont_Desc_SetFriction` | 318 | `SUBROUTINE RT_Cont_Desc_SetFriction(self, pair_idx, mu, friction_model)` |
| SUBROUTINE | `RT_Cont_Desc_Finalize` | 326 | `SUBROUTINE RT_Cont_Desc_Finalize(self)` |
| SUBROUTINE | `RT_Cont_State_Reset` | 341 | `SUBROUTINE RT_Cont_State_Reset(self)` |
| SUBROUTINE | `RT_Cont_State_UpdateStatus` | 368 | `SUBROUTINE RT_Cont_State_UpdateStatus(self)` |
| SUBROUTINE | `RT_Cont_State_AggregateStats` | 384 | `SUBROUTINE RT_Cont_State_AggregateStats(self)` |
| SUBROUTINE | `RT_Cont_Algo_Init` | 402 | `SUBROUTINE RT_Cont_Algo_Init(self)` |
| SUBROUTINE | `RT_Cont_Algo_SelectEnforcement` | 422 | `SUBROUTINE RT_Cont_Algo_SelectEnforcement(self, method)` |
| SUBROUTINE | `RT_Cont_Algo_ConfigureFriction` | 428 | `SUBROUTINE RT_Cont_Algo_ConfigureFriction(self, model, decay, slip_tol)` |
| SUBROUTINE | `RT_Cont_Algo_ConfigureSearch` | 437 | `SUBROUTINE RT_Cont_Algo_ConfigureSearch(self, freq, use_global, adaptive)` |
| SUBROUTINE | `RT_Cont_Algo_ConfigureAugLag` | 448 | `SUBROUTINE RT_Cont_Algo_ConfigureAugLag(self, n_max, rho, tol)` |
| SUBROUTINE | `RT_Cont_Ctx_AttachBuffers` | 461 | `SUBROUTINE RT_Cont_Ctx_AttachBuffers(self, force_buf, disp_buf)` |
| SUBROUTINE | `RT_Cont_Ctx_ClearTemporaries` | 468 | `SUBROUTINE RT_Cont_Ctx_ClearTemporaries(self)` |
| SUBROUTINE | `RT_Cont_Ctx_Detach` | 487 | `SUBROUTINE RT_Cont_Ctx_Detach(self)` |
| SUBROUTINE | `RT_Cont_State_AugLagInit` | 499 | `SUBROUTINE RT_Cont_State_AugLagInit(self, n_pairs, lambda_init)` |
| SUBROUTINE | `RT_Cont_State_AugLagCommit` | 529 | `SUBROUTINE RT_Cont_State_AugLagCommit(self, delta_norm)` |
| SUBROUTINE | `RT_Cont_State_AugLagRollback` | 546 | `SUBROUTINE RT_Cont_State_AugLagRollback(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
