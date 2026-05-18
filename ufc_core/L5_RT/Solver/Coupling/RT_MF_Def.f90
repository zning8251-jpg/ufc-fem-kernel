!===============================================================================
! MODULE: RT_MF_Def
! LAYER:  L5_RT
! DOMAIN: Coupling
! ROLE:   Def
! BRIEF:  MultiField coupling four-type system (Desc/State/Algo/Ctx)
!===============================================================================
!
! Four-TYPE System:
!   RT_MF_Coupling_Desc   -- immutable coupling configuration (cold path)
!   RT_MF_Coupling_State  -- runtime coupling iteration state (hot path)
!   RT_MF_Coupling_Algo   -- coupling algorithm parameters (pre-analysis)
!   RT_MF_Coupling_Ctx    -- per-increment transient hot context
!
! Partial Pillar: H6 Coupling / MultiField (L3 + L5)
!   L3: MD_Cpl_Def (AUTHORITY for coupling pair definitions)
!   L5: RT_MF_Def (THIS MODULE -- AUTHORITY for L5 runtime coupling types)
!   L5 Golden Line: RT_MF_Coordinator.f90 (production coupling driver)
!
! Status: ACTIVE | AUTHORITY | Last verified: 2026-04-28
!===============================================================================
MODULE RT_MF_Def
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, IF_STATUS_OK
  IMPLICIT NONE
  PRIVATE

  !-- Public TYPEs
  PUBLIC :: RT_MF_Coupling_Desc
  PUBLIC :: RT_MF_Coupling_State
  PUBLIC :: RT_MF_Coupling_Algo
  PUBLIC :: RT_MF_Coupling_Ctx
  PUBLIC :: RT_MF_FieldPair_Desc
  PUBLIC :: RT_MF_InterfaceBuf

  !-- Field ID constants (1-indexed, max 6 physics fields)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_STR = 1_i4   ! Structural
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_THM = 2_i4   ! Thermal
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_FLD = 3_i4   ! Fluid (CFD)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_DIF = 4_i4   ! Diffusion
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_EM  = 5_i4   ! Electromagnetic
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_FIELD_ACO = 6_i4   ! Acoustic
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_MAX_FIELDS = 6_i4  ! Max simultaneous fields

  !-- Coupling strategy constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_COUP_ONEWAY   = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_COUP_STAG     = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_COUP_PARTITER = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_COUP_MONO     = 3_i4

  !-- Interface interpolation method constants
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_INTERP_NN    = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_INTERP_RBF   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_INTERP_MLS   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_INTERP_C0    = 3_i4

  !-- Coupling channel quantity type (what is sent across the interface)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_DISP      = 1_i4  ! displacement u
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_VEL       = 2_i4  ! velocity v
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_STRESS    = 3_i4  ! Cauchy stress σ·n
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_TEMP      = 4_i4  ! temperature T
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_HFLUX     = 5_i4  ! heat flux q
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_PRESSURE  = 6_i4  ! fluid pressure p
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_HEATGEN   = 7_i4  ! volumetric heat source Q
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_CONC      = 8_i4  ! concentration / pore pressure
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_CURRENT   = 9_i4  ! electric current density J
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_QTY_JOULE    = 10_i4  ! Joule heat J²/σ_e

  !-- Coupling state codes (analogous to RT_SOLV_STATUS_*)
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_STATE_IDLE        = 0_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_STATE_ITERATING   = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_STATE_CONVERGED   = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_STATE_DIVERGED    = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: RT_MF_STATE_MAX_ITER    = 4_i4

  !=============================================================================
  !  Auxiliary TYPE: RT_MF_FieldPair_Desc
  !    Describes one directional coupling channel: field A sends QTY_xxx to
  !    field B through a named interface surface.
  !    Analogy: MD_Coup_PairDesc at the L3_MD level; this is the L5_RT copy
  !    cached for hot-path routing, NOT the canonical storage.
  !=============================================================================
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

  !=============================================================================
  !  Auxiliary TYPE: RT_MF_InterfaceBuf
  !    Per-pair send/receive buffer for interface quantities.
  !    Allocated once per analysis in RT_MF_Coupling_Ctx.
  !    Layout: buf(n_interface_nodes, n_dof_per_node)
  !=============================================================================
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

  !=============================================================================
  !  TYPE 1: RT_MF_Coupling_Desc  ? immutable configuration (Desc role)
  !
  !  Lifecycle: filled once by UFC_Driver / L6_AP from L3_MD/Coupling data
  !             before the analysis loop begins.  NEVER written during solve.
  !  Hot-path access: read-only from RT_MFCoordinator.
  !=============================================================================
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

  !=============================================================================
  !  TYPE 2: RT_MF_Coupling_State  ? runtime coupling iteration state
  !
  !  Lifecycle: reset at the start of each increment; updated every coupling
  !             iteration by RT_MF_ConvCheck.
  !  Analogy:   RT_Solv_NRState ?the "outer NR" for multi-field coupling.
  !=============================================================================
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

  !=============================================================================
  !  TYPE 3: RT_MF_Coupling_Algo  ? coupling algorithm parameters
  !
  !  Lifecycle: configured once per analysis step (like RT_Solv).
  !             May be adjusted between steps (e.g. tightening eps_coup in Phase 2).
  !  Mutation rule: MUST NOT be written inside the coupling iteration loop.
  !=============================================================================
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

  !=============================================================================
  !  TYPE 4: RT_MF_Coupling_Ctx  ? per-increment transient hot context
  !
  !  Lifecycle:
  !    ALLOCATED at start of each increment by RT_MFCoordinator.
  !    Holds pointers into interface buffer storage for ZERO-COPY exchange.
  !    DEALLOCATED after WriteBack (end of increment).
  !
  !  Performance contract:
  !    All array POINTER members below point into pre-allocated storage
  !    owned by the coupling framework (not by individual field solvers).
  !    No dynamic allocation inside the coupling hot loop.
  !=============================================================================
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

!===============================================================================
CONTAINS
!===============================================================================

  !-----------------------------------------------------------------------------
  ! RT_MF_Coupling_State ?Init
  !   Full initialization: resets all counters and allocates per-pair arrays.
  !   Call once per analysis (not per increment; use Reset for per-increment reset).
  !-----------------------------------------------------------------------------
  SUBROUTINE MF_State_Init(self, n_pairs)
    CLASS(RT_MF_Coupling_State), INTENT(INOUT) :: self
    INTEGER(i4),                 INTENT(IN)    :: n_pairs  ! = Desc%n_pairs

    self%coup_iter        = 0_i4
    self%total_coup_iters = 0_i4
    self%n_cutbacks       = 0_i4
    self%coup_res_abs     = 0.0_wp
    self%coup_res_rel     = 1.0_wp
    self%coup_res_ref     = 1.0_wp
    self%field_converged  = .FALSE.
    self%field_pnewdt     = 1.0_wp
    self%pnewdt_min       = 1.0_wp
    self%coup_status      = RT_MF_STATE_IDLE
    self%coup_converged   = .FALSE.
    self%all_fields_converged = .FALSE.
    self%aitken_omega     = 1.0_wp

    !-- Allocate per-pair residual arrays
    IF (ALLOCATED(self%pair_res_abs)) DEALLOCATE(self%pair_res_abs)
    IF (ALLOCATED(self%pair_res_rel)) DEALLOCATE(self%pair_res_rel)
    IF (n_pairs > 0_i4) THEN
      ALLOCATE(self%pair_res_abs(n_pairs), SOURCE=0.0_wp)
      ALLOCATE(self%pair_res_rel(n_pairs), SOURCE=1.0_wp)
    END IF

    self%status = IF_STATUS_OK
  END SUBROUTINE MF_State_Init

  !-----------------------------------------------------------------------------
  ! RT_MF_Coupling_State ?Reset
  !   Per-increment reset: preserve total counters, zero iteration-level data.
  !   Called at the start of each increment by RT_MFCoordinator.
  !-----------------------------------------------------------------------------
  SUBROUTINE MF_State_Reset(self)
    CLASS(RT_MF_Coupling_State), INTENT(INOUT) :: self

    self%coup_iter    = 0_i4
    self%coup_res_abs = 0.0_wp
    self%coup_res_rel = 1.0_wp
    self%coup_res_ref = 1.0_wp
    self%field_converged = .FALSE.
    self%field_pnewdt    = 1.0_wp
    self%pnewdt_min      = 1.0_wp
    self%coup_status     = RT_MF_STATE_IDLE
    self%coup_converged  = .FALSE.
    self%all_fields_converged = .FALSE.
    self%aitken_omega    = 1.0_wp

    IF (ALLOCATED(self%pair_res_abs)) self%pair_res_abs = 0.0_wp
    IF (ALLOCATED(self%pair_res_rel)) self%pair_res_rel = 1.0_wp
  END SUBROUTINE MF_State_Reset

  !-----------------------------------------------------------------------------
  ! RT_MF_Coupling_Algo ?Init
  !   Restores default parameter values (useful for re-initialization).
  !-----------------------------------------------------------------------------
  SUBROUTINE MF_Algo_Init(self)
    CLASS(RT_MF_Coupling_Algo), INTENT(INOUT) :: self

    self%eps_coup_rel    = 1.0e-3_wp
    self%eps_coup_abs    = 0.0_wp
    self%max_coup_iter   = 1_i4
    self%field_inner_tol = 0.0_wp
    self%relax_factor    = 1.0_wp
    self%use_aitken      = .FALSE.
    self%aitken_omega_0  = 0.5_wp
    self%interp_method   = RT_MF_INTERP_NN
    self%conservative_map= .FALSE.
    self%rbf_shape_param = 1.0_wp
    self%allow_subcycle  = .FALSE.
    self%subcycle_interp = 1_i4
    self%off_diag_scale  = 1.0_wp
    self%mono_linsol     = 1_i4
  END SUBROUTINE MF_Algo_Init

  !-----------------------------------------------------------------------------
  ! RT_MF_Coupling_Ctx ?Alloc
  !   Allocates per-increment scratch buffers.
  !   n_pairs: number of coupling pairs (= Desc%n_pairs)
  !   pair_n_nodes(i): number of interface nodes for pair i
  !   pair_n_dof(i)  : DOF per node for pair i
  !-----------------------------------------------------------------------------
  SUBROUTINE MF_Ctx_Alloc(self, n_pairs, pair_n_nodes, pair_n_dof)
    CLASS(RT_MF_Coupling_Ctx), INTENT(INOUT) :: self
    INTEGER(i4), INTENT(IN) :: n_pairs
    INTEGER(i4), INTENT(IN) :: pair_n_nodes(n_pairs)  ! [IN]  nodes per pair
    INTEGER(i4), INTENT(IN) :: pair_n_dof(n_pairs)    ! [IN]  DOF per node per pair

    INTEGER(i4) :: ip

    self%n_bufs = n_pairs

    IF (ALLOCATED(self%bufs)) DEALLOCATE(self%bufs)
    IF (n_pairs > 0_i4) THEN
      ALLOCATE(self%bufs(n_pairs))
      DO ip = 1, n_pairs
        self%bufs(ip)%pair_id = ip
        self%bufs(ip)%pop%n_nodes = pair_n_nodes(ip)
        self%bufs(ip)%pop%n_dof   = pair_n_dof(ip)
        IF (pair_n_nodes(ip) > 0_i4 .AND. pair_n_dof(ip) > 0_i4) THEN
          ALLOCATE(self%bufs(ip)%send_buf (pair_n_nodes(ip), pair_n_dof(ip)), &
                   SOURCE=0.0_wp)
          ALLOCATE(self%bufs(ip)%recv_buf (pair_n_nodes(ip), pair_n_dof(ip)), &
                   SOURCE=0.0_wp)
          ALLOCATE(self%bufs(ip)%recv_prev(pair_n_nodes(ip), pair_n_dof(ip)), &
                   SOURCE=0.0_wp)
        END IF
      END DO
    END IF

    IF (ALLOCATED(self%norm_buf)) DEALLOCATE(self%norm_buf)
    IF (n_pairs > 0_i4) ALLOCATE(self%norm_buf(n_pairs), SOURCE=0.0_wp)

    self%status = IF_STATUS_OK
  END SUBROUTINE MF_Ctx_Alloc

  !-----------------------------------------------------------------------------
  ! RT_MF_Coupling_Ctx ?Dealloc
  !   Releases all per-increment scratch storage.
  !   Called by RT_MFCoordinator after WriteBack.
  !-----------------------------------------------------------------------------
  SUBROUTINE MF_Ctx_Dealloc(self)
    CLASS(RT_MF_Coupling_Ctx), INTENT(INOUT) :: self

    INTEGER(i4) :: ip

    IF (ALLOCATED(self%bufs)) THEN
      DO ip = 1, self%n_bufs
        IF (ALLOCATED(self%bufs(ip)%send_buf))  DEALLOCATE(self%bufs(ip)%send_buf)
        IF (ALLOCATED(self%bufs(ip)%recv_buf))  DEALLOCATE(self%bufs(ip)%recv_buf)
        IF (ALLOCATED(self%bufs(ip)%recv_prev)) DEALLOCATE(self%bufs(ip)%recv_prev)
        IF (ALLOCATED(self%bufs(ip)%W_interp))  DEALLOCATE(self%bufs(ip)%W_interp)
      END DO
      DEALLOCATE(self%bufs)
    END IF

    IF (ALLOCATED(self%norm_buf)) DEALLOCATE(self%norm_buf)

    self%n_bufs    = 0_i4
    self%dof_total = 0_i4
    self%dof_offset = 0_i4
  END SUBROUTINE MF_Ctx_Dealloc

END MODULE RT_MF_Def
