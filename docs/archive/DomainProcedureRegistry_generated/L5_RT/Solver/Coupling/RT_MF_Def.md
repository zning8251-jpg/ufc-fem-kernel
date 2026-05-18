# `RT_MF_Def.f90`

- **Source**: `L5_RT/Solver/Coupling/RT_MF_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `RT_MF_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_MF_Def`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_MF`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Solver/Coupling`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/Coupling/RT_MF_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `RT_MF_FieldPair_Desc` (lines 83–107)

```fortran
  TYPE, PUBLIC :: RT_MF_FieldPair_Desc
    !-- Sender / receiver field IDs (use RT_MF_FIELD_* constants)
    INTEGER(i4) :: src_field_id  = 0_i4   ! [IN]  source field (1-6)
    INTEGER(i4) :: dst_field_id  = 0_i4   ! [IN]  target field (1-6)

    !-- Transferred physical quantity (use RT_MF_QTY_* constants)
    INTEGER(i4) :: qty_type      = 0_i4   ! [IN]  what is transmitted

    !-- Number of DOFs per node on sender side for this quantity
    INTEGER(i4) :: src_ndof_per_node = 1_i4  ! [IN]  e.g. 3 for displacement

    !-- Interface surface ID (refers to mesh surface set in L3_MD/Coupling)
    INTEGER(i4) :: interface_surf_id = 0_i4  ! [IN]  links to MD_Coup_InterfaceMesh

    !-- Scale factor applied to the transferred quantity
    !   (e.g. Taylor-Quinney coefficient chi for STR→THM plastic heat)
    REAL(wp) :: scale_factor = 1.0_wp        ! [IN]  default = 1

    !-- Coupling active flag (runtime toggle, does NOT violate immutability:
    !   pair can be dormant in Phase-1 and activated in Phase-2 analysis)
    LOGICAL :: active = .TRUE.               ! [IN]

    !-- Pair label for diagnostics
    CHARACTER(LEN=32) :: label = ''          ! [IN]  optional
  END TYPE RT_MF_FieldPair_Desc
```

### `RT_MF_InterfaceBuf` (lines 115–130)

```fortran
  TYPE, PUBLIC :: RT_MF_InterfaceBuf
    INTEGER(i4) :: pair_id       = 0_i4    ! back-reference to pair index
    INTEGER(i4) :: n_nodes       = 0_i4    ! number of interface nodes
    INTEGER(i4) :: n_dof         = 0_i4    ! DOF per node for this quantity

    REAL(wp), ALLOCATABLE :: send_buf(:,:) ! [OUT] outgoing values (n_nodes, n_dof)
    REAL(wp), ALLOCATABLE :: recv_buf(:,:) ! [IN]  incoming values after interpolation

    !-- Interpolation weight matrix (sparse, row-compressed)
    !   W(i,j): weight from sender node j to receiver node i
    !   Allocated and filled by RT_MF_InterpSetup before the coupling loop.
    REAL(wp), ALLOCATABLE :: W_interp(:,:) ! (n_recv_nodes, n_send_nodes)

    !-- Δ-buffer for convergence check: stores previous iteration values
    REAL(wp), ALLOCATABLE :: recv_prev(:,:) ! (n_nodes, n_dof)
  END TYPE RT_MF_InterfaceBuf
```

### `RT_MF_Coupling_Desc` (lines 139–191)

```fortran
  TYPE, PUBLIC :: RT_MF_Coupling_Desc
    !--------------------------------------------------------------------------
    ! A. Active field registry
    !--------------------------------------------------------------------------
    !  n_fields  ?number of simultaneously active physics fields (2..6)
    !  field_ids ?ordered list of field IDs using RT_MF_FIELD_* constants
    !              field_ids(1..n_fields) are valid; rest zero-padded.
    INTEGER(i4) :: n_fields              = 0_i4           ! [IN]
    INTEGER(i4) :: field_ids(RT_MF_MAX_FIELDS) = 0_i4    ! [IN]

    !-- Coupling activation matrix: coup_matrix(i,j) = .TRUE. means field i
    !   sends data to field j.  Populated from 5×5 coupling decision table.
    LOGICAL :: coup_matrix(RT_MF_MAX_FIELDS, RT_MF_MAX_FIELDS) = .FALSE. ! [IN]

    !--------------------------------------------------------------------------
    ! B. Coupling pair list
    !--------------------------------------------------------------------------
    !  n_pairs    ?number of active directional coupling pairs
    !  pairs(*)   ?array of pair descriptors (ALLOCATABLE to allow 0..N pairs)
    INTEGER(i4) :: n_pairs = 0_i4                             ! [IN]
    TYPE(RT_MF_FieldPair_Desc), ALLOCATABLE :: pairs(:)       ! [IN]  size=n_pairs

    !--------------------------------------------------------------------------
    ! C. Coupling strategy (global, applies to all pairs unless overridden)
    !--------------------------------------------------------------------------
    !  Use RT_MF_COUP_* constants.
    !  A per-pair strategy extension can be added in Phase-2 via pairs(i)%strategy
    !  when asymmetric coupling is required (e.g. FSI strong + THM weak).
    INTEGER(i4) :: global_strategy = RT_MF_COUP_STAG    ! [IN]  default: Staggered

    !--------------------------------------------------------------------------
    ! D. Time synchronization scheme
    !--------------------------------------------------------------------------
    !  Fields may run with different time steps (e.g. structural dt_str >> dt_cfd).
    !  subcycle_ratio(i) = dt_master / dt_field_i  (integer subcycling count)
    !  If subcycle_ratio(i) = 1 for all i ?fully synchronized.
    INTEGER(i4) :: subcycle_ratio(RT_MF_MAX_FIELDS) = 1_i4   ! [IN]

    !-- Master field ID: the field whose time step drives the coupling loop.
    !   Typically STR (1) for FSI structural-dominant problems.
    INTEGER(i4) :: master_field_id = RT_MF_FIELD_STR          ! [IN]

    !--------------------------------------------------------------------------
    ! E. Metadata / traceability
    !--------------------------------------------------------------------------
    !  runtime_id  ?unique analysis ID (assigned by UFC_Driver)
    !  label       ?optional user-defined coupling scenario name
    !  md_coup_id  ?reference back to L3_MD/Coupling record (for traceability)
    INTEGER(i4)      :: runtime_id  = 0_i4    ! [IN]
    CHARACTER(LEN=64):: label       = ''      ! [IN]  optional
    INTEGER(i4)      :: md_coup_id  = 0_i4    ! [IN]  L3_MD coupling descriptor ID
    LOGICAL          :: is_valid    = .FALSE. ! [IN]  set by validation routine
  END TYPE RT_MF_Coupling_Desc
```

### `RT_MF_Coupling_State` (lines 200–247)

```fortran
  TYPE, PUBLIC :: RT_MF_Coupling_State
    !--------------------------------------------------------------------------
    ! A. Coupling iteration counters
    !--------------------------------------------------------------------------
    INTEGER(i4) :: coup_iter        = 0_i4   ! [OUT] current coupling iteration k
    INTEGER(i4) :: total_coup_iters = 0_i4   ! [OUT] cumulative over all increments
    INTEGER(i4) :: n_cutbacks       = 0_i4   ! [OUT] time step cutbacks triggered by coupling

    !--------------------------------------------------------------------------
    ! B. Coupling convergence norms
    !    Defined as: ||Φ^k - Φ^{k-1}|| / ||Φ^1||
    !    where Φ is the exchanged quantity on the interface (velocity, temp, ?
    !--------------------------------------------------------------------------
    REAL(wp) :: coup_res_abs       = 0.0_wp  ! [OUT] |ΔΦ| absolute interface residual
    REAL(wp) :: coup_res_rel       = 1.0_wp  ! [OUT] |ΔΦ| / |ΔΦ_0| relative residual
    REAL(wp) :: coup_res_ref       = 1.0_wp  ! [OUT] reference norm from k=1

    !-- Per-pair residuals (parallel to Desc%pairs array, size n_pairs)
    REAL(wp), ALLOCATABLE :: pair_res_abs(:) ! [OUT]  size = n_pairs
    REAL(wp), ALLOCATABLE :: pair_res_rel(:) ! [OUT]  size = n_pairs

    !--------------------------------------------------------------------------
    ! C. Per-field solve status
    !    field_converged(i) = .TRUE. when field i's own inner NR has converged
    !    field_pnewdt(i)    = minimum pnewdt returned from field i's solver
    !                         (< 1 triggers coupling-level time cutback)
    !--------------------------------------------------------------------------
    LOGICAL  :: field_converged(RT_MF_MAX_FIELDS) = .FALSE. ! [OUT]
    REAL(wp) :: field_pnewdt(RT_MF_MAX_FIELDS)    = 1.0_wp  ! [OUT]
    REAL(wp) :: pnewdt_min                         = 1.0_wp  ! [OUT] min across all fields

    !--------------------------------------------------------------------------
    ! D. Overall coupling status
    !--------------------------------------------------------------------------
    INTEGER(i4) :: coup_status = RT_MF_STATE_IDLE ! [OUT]  use RT_MF_STATE_* constants
    LOGICAL     :: coup_converged = .FALSE.        ! [OUT]  .TRUE. when all pairs < tol
    LOGICAL     :: all_fields_converged = .FALSE.  ! [OUT]  .TRUE. when all field NR done

    !-- Aitken relaxation state (updated if Algo%use_aitken = .TRUE.)
    REAL(wp) :: aitken_omega = 1.0_wp  ! [OUT]  current Aitken relaxation factor

    !-- Error status for diagnostics
    TYPE(ErrorStatusType) :: status

  CONTAINS
    PROCEDURE :: Init
    PROCEDURE :: Reset
  END TYPE RT_MF_Coupling_State
```

### `RT_MF_Coupling_Algo` (lines 256–316)

```fortran
  TYPE, PUBLIC :: RT_MF_Coupling_Algo
    !--------------------------------------------------------------------------
    ! A. Convergence criteria
    !--------------------------------------------------------------------------
    !  eps_coup_rel   ?relative interface residual tolerance (primary criterion)
    !  eps_coup_abs   ?absolute tolerance (0 = inactive, use relative only)
    !  max_coup_iter  ?maximum coupling iterations per increment
    !                   (= 1 for pure Staggered without convergence iteration)
    REAL(wp)    :: eps_coup_rel   = 1.0e-3_wp   ! [IN]  default: ‖ΔΦ?‖ΔΦ_0?< 0.1%
    REAL(wp)    :: eps_coup_abs   = 0.0_wp       ! [IN]  0 = relative only
    INTEGER(i4) :: max_coup_iter  = 1_i4         ! [IN]  1 = Staggered, >1 = PartIter

    !-- Field-level inner NR tolerances (may differ from single-field analysis)
    !   Tighter inner convergence is sometimes needed for outer coupling stability.
    !   field_inner_tol(i) = 0 ?use each field solver's own default tolerance.
    REAL(wp) :: field_inner_tol(RT_MF_MAX_FIELDS) = 0.0_wp  ! [IN]  0 = use default

    !--------------------------------------------------------------------------
    ! B. Relaxation / acceleration
    !--------------------------------------------------------------------------
    !  relax_factor   ?under-relaxation applied to exchanged quantity:
    !                   Φ_applied = (1 - ω)*Φ_prev + ω*Φ_new   (ω ?(0,1])
    !  use_aitken     ?enable Aitken Δ² acceleration (adaptive ω)
    !  aitken_omega_0 ?initial Aitken relaxation factor
    REAL(wp) :: relax_factor    = 1.0_wp  ! [IN]  1.0 = no relaxation
    LOGICAL  :: use_aitken      = .FALSE. ! [IN]
    REAL(wp) :: aitken_omega_0  = 0.5_wp  ! [IN]  starting ω for Aitken

    !--------------------------------------------------------------------------
    ! C. Interface interpolation
    !--------------------------------------------------------------------------
    !  interp_method  ?see RT_MF_INTERP_* constants
    !  conservative_map ?enforce conservation of integrated flux across interface
    !                     (requires dual mortar; increases cost ~30%)
    INTEGER(i4) :: interp_method    = RT_MF_INTERP_NN  ! [IN]  default: nearest-neighbour
    LOGICAL     :: conservative_map = .FALSE.           ! [IN]

    !-- RBF shape parameter (used when interp_method = RT_MF_INTERP_RBF)
    REAL(wp) :: rbf_shape_param = 1.0_wp  ! [IN]

    !--------------------------------------------------------------------------
    ! D. Time subcycling
    !--------------------------------------------------------------------------
    !  allow_subcycle   ?permit fields to run at different time steps
    !  subcycle_interp  ?interpolation order for subcycled field data (0=step, 1=linear)
    LOGICAL     :: allow_subcycle   = .FALSE. ! [IN]
    INTEGER(i4) :: subcycle_interp  = 1_i4    ! [IN]  0=constant, 1=linear

    !--------------------------------------------------------------------------
    ! E. Monolithic coupling parameters (RT_MF_COUP_MONO only)
    !--------------------------------------------------------------------------
    !  off_diag_scale  ?scaling applied to off-diagonal coupling sub-matrices
    !                    K_AB = off_diag_scale * dR_A/dΦ_B  (numerical Jacobian)
    !  mono_linsol     ?linear solver for the unified block system
    !                    (reuses RT_SOLV_LINSOL_* constants from RT_Solv_Def)
    REAL(wp)    :: off_diag_scale   = 1.0_wp  ! [IN]
    INTEGER(i4) :: mono_linsol      = 1_i4    ! [IN]  1=Direct sparse (default)

  CONTAINS
    PROCEDURE :: Init
  END TYPE RT_MF_Coupling_Algo
```

### `RT_MF_Coupling_Ctx` (lines 331–369)

```fortran
  TYPE, PUBLIC :: RT_MF_Coupling_Ctx
    !--------------------------------------------------------------------------
    ! A. Time synchronization context
    !--------------------------------------------------------------------------
    REAL(wp) :: time_coup      = 0.0_wp  ! [IN]  coupling synchronization time
    REAL(wp) :: dtime_coup     = 0.0_wp  ! [IN]  coupling master time step
    REAL(wp) :: dtime_field(RT_MF_MAX_FIELDS) = 0.0_wp  ! [IN]  per-field dt
    INTEGER(i4) :: incr_id     = 0_i4    ! [IN]  current increment index

    !--------------------------------------------------------------------------
    ! B. Interface exchange buffers
    !    One RT_MF_InterfaceBuf per coupling pair (ALLOCATABLE).
    !    Allocated once (not per-iteration) by RT_MF_InterpSetup.
    !--------------------------------------------------------------------------
    INTEGER(i4) :: n_bufs = 0_i4                      ! [IN]  = Desc%n_pairs
    TYPE(RT_MF_InterfaceBuf), ALLOCATABLE :: bufs(:)  ! [INOUT]  size = n_bufs

    !--------------------------------------------------------------------------
    ! C. Scratch workspace for convergence check
    !    norm_buf(i) = current |ΔΦ| for pair i before normalization
    !--------------------------------------------------------------------------
    REAL(wp), ALLOCATABLE :: norm_buf(:)    ! [OUT]  size = n_pairs

    !--------------------------------------------------------------------------
    ! D. Field DOF offsets in the monolithic system (Monolithic only)
    !    dof_offset(i) = global DOF start index for field i in the block matrix
    !--------------------------------------------------------------------------
    INTEGER(i4) :: dof_total                        = 0_i4  ! [OUT]  total coupled DOFs
    INTEGER(i4) :: dof_offset(RT_MF_MAX_FIELDS)     = 0_i4  ! [OUT]

    !--------------------------------------------------------------------------
    ! E. Diagnostics
    !--------------------------------------------------------------------------
    TYPE(ErrorStatusType) :: status

  CONTAINS
    PROCEDURE :: Alloc
    PROCEDURE :: Dealloc
  END TYPE RT_MF_Coupling_Ctx
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `MF_State_Init` | 380 | `SUBROUTINE MF_State_Init(self, n_pairs)` |
| SUBROUTINE | `MF_State_Reset` | 414 | `SUBROUTINE MF_State_Reset(self)` |
| SUBROUTINE | `MF_Algo_Init` | 437 | `SUBROUTINE MF_Algo_Init(self)` |
| SUBROUTINE | `MF_Ctx_Alloc` | 463 | `SUBROUTINE MF_Ctx_Alloc(self, n_pairs, pair_n_nodes, pair_n_dof)` |
| SUBROUTINE | `MF_Ctx_Dealloc` | 502 | `SUBROUTINE MF_Ctx_Dealloc(self)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
