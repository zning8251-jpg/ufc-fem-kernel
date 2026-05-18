!===============================================================================
! Template: MD_XXX_Domain_Types.f90                           [Template v2.0]
! Layer:    L3_MD — Model Description Layer
! Domain:   XXX  — (Replace with actual domain name)
!
! PURPOSE & DESIGN INTENT:
!   This template defines the STANDARD STRUCTURE for a single independent
!   L3_MD domain container (MD_XXX_Domain). Each domain container:
!     1. Manages its own data as ALLOCATABLE arrays (flat storage pattern)
!     2. Holds EXACTLY four type categories: Desc / State / Algo / Ctx
!     3. Does NOT aggregate other domains — that is LayerContainer's job
!     4. Is registered in MD_L3_LayerContainer as a direct field
!
! THREE-LAYER ARCHITECTURE (MANDATORY):
!
!   Layer 1 — MD_Model_Domain  (Index Tree):
!     Holds ONLY summary counts (n_xxx integers) and cross-ref ID arrays.
!     Updated via SyncModelCounts() — never stores data bodies.
!     See: MD_Model_Types.f90 template (also: MD_Model_Core.f90 in production).
!
!   Layer 2 — MD_XXX_Domain  (THIS template — Independent Domain Container):
!     Each domain owns its flat ALLOCATABLE Desc/State/Algo arrays.
!     Single source of truth for that domain's data.
!     Access pattern: domain%desc(i), domain%state(i), domain%algo(i)
!     One domain TYPE per functional area — no cross-domain nesting.
!
!   Layer 3 — MD_L3_LayerContainer  (Aggregator):
!     Holds one field per domain: model / part / mesh / assembly /
!     constraint / section / material / amplitude / loadbc / interaction /
!     step / solver / output / writeback  (14 domains total).
!     Provides Init / Finalize / BindDomains / ValidateAllRefs.
!     NEVER create a separate MD_Domain_Container — LayerContainer IS the aggregator.
!
! FOUR TYPE CATEGORIES (mandatory for every domain):
!   Desc  — cold, write-once config; ALLOCATABLE arrays; frozen after parse
!   State — hot, runtime state;     ALLOCATABLE arrays; updated via WriteBack
!   Algo  — algorithm parameters;   ALLOCATABLE arrays; read-only during iteration
!   Ctx   — transient cross-layer;  NO ALLOCATABLE fields; hot-path buffer
!
! NAMING CONVENTION:
!   Domain name abbreviation: 3-5 chars (e.g., Mat/Elem/Mesh/Load/BC/Cont/Const/Fld/Out)
!   Types:   MD_XXX_Desc / MD_XXX_State / MD_XXX_Algo / MD_XXX_Ctx
!   Domain:  MD_XXX_Domain
!   Subroutines: MD_XXX_Domain_Init / MD_XXX_Domain_Finalize / MD_XXX_WriteBack
!
! STATUS: Template v2.0 — replaces v1.0 (MD_Domain_Container aggregator pattern).
!         v1.0 is DEPRECATED. Do not use MD_Domain_Container or LinkAnalysis.
!         Comment baseline refresh: IF_Err_Brg notes now reference
!         init_error_status, IF_STATUS_*, IF_ERROR_CODE_*, and %status_code.
!
! Last revised: 2026-03-30
!===============================================================================
! LAYER DEPENDENCY (for any specific domain implementation):
!   USE IF_Prec    ONLY: wp, i4
!   USE IF_Err_Brg ONLY: ErrorStatusType + standard bridge vocabulary:
!                       init_error_status, IF_STATUS_*, IF_ERROR_CODE_*
!   DO NOT USE other L3_MD domain modules — cross-domain access goes via LayerContainer
!===============================================================================
MODULE MD_XXX_Domain_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--- Public exports ---
  PUBLIC :: MD_XXX_Desc
  PUBLIC :: MD_XXX_State
  PUBLIC :: MD_XXX_Algo
  PUBLIC :: MD_XXX_Ctx
  PUBLIC :: MD_XXX_Domain
  PUBLIC :: MD_XXX_Domain_Init
  PUBLIC :: MD_XXX_Domain_Finalize
  PUBLIC :: MD_XXX_WriteBack

  !=============================================================================
  ! DOMAIN-SPECIFIC CONSTANTS
  !=============================================================================
  !-- Replace with actual domain constants
  INTEGER(i4), PARAMETER, PUBLIC :: MD_XXX_TYPE_DEFAULT = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_XXX_TYPE_EXTENDED = 2_i4

  !=============================================================================
  ! Desc Category
  ! 「冷路径」：模型元信息、静态配置。解析后冊冒 (Frozen after L6_AP parse)。
  ! Rule: Fields are write-once. ALLOCATABLE allowed. NO POINTER fields.
  !=============================================================================
  TYPE, PUBLIC :: MD_XXX_Desc
    CHARACTER(LEN=80) :: name          = ''       ! Domain entity name
    INTEGER(i4)       :: xxx_id        = 0_i4     ! Unique identifier (1-based)
    INTEGER(i4)       :: xxx_type      = MD_XXX_TYPE_DEFAULT  ! Type selector
    LOGICAL           :: is_active     = .TRUE.   ! Enable/disable flag

    !-- Configuration fields (domain-specific; replace placeholders) --
    ! Example: material elastic properties
    REAL(wp)          :: param_a       = 0.0_wp   ! Replace with actual field
    REAL(wp)          :: param_b       = 0.0_wp   ! Replace with actual field
    INTEGER(i4)       :: n_sub         = 0_i4     ! Sub-item count

    !-- ALLOCATABLE array fields (write-once, freed in Finalize) --
    REAL(wp), ALLOCATABLE :: data_vals(:)          ! Example data array
    INTEGER(i4), ALLOCATABLE :: ref_ids(:)         ! Cross-reference IDs to other domains
  END TYPE MD_XXX_Desc

  !=============================================================================
  ! State Category
  ! 「热路径」：运行时动态状态。WriteBack 白名单管制。
  ! Rule: ALLOCATABLE allowed. Updated ONLY via WriteBack whitelist.
  !       Do NOT write directly outside MD_XXX_WriteBack.
  !=============================================================================
  TYPE, PUBLIC :: MD_XXX_State
    !-- Runtime counters (updated by L5_RT via WriteBack) --
    INTEGER(i4) :: step_idx          = 0_i4    ! Current step index (data chain: L3→L5)
    INTEGER(i4) :: incr_idx          = 0_i4    ! Current increment index
    LOGICAL     :: is_converged      = .FALSE. ! Convergence flag
    LOGICAL     :: is_active         = .FALSE. ! Active in current step

    !-- Domain-specific state fields --
    REAL(wp)    :: current_value     = 0.0_wp  ! Replace with actual state field
    REAL(wp)    :: prev_value        = 0.0_wp  ! Previous increment value

    !-- ALLOCATABLE state arrays (managed lifecycle) --
    REAL(wp), ALLOCATABLE :: state_vec(:)      ! State vector (domain-specific size)
  END TYPE MD_XXX_State

  !=============================================================================
  ! Algo Category
  ! 「算法参数」：迭代内只读。超参数、容差、算法选择。
  ! Rule: NO ALLOCATABLE. Should be small POD-like data. Read-only during solve.
  !=============================================================================
  TYPE, PUBLIC :: MD_XXX_Algo
    !-- Algorithm selection --
    INTEGER(i4) :: method           = 1_i4       ! Algorithm method selector
    INTEGER(i4) :: max_iterations   = 100_i4     ! Maximum iteration count

    !-- Tolerances --
    REAL(wp)    :: abs_tol          = 1.0e-8_wp  ! Absolute tolerance
    REAL(wp)    :: rel_tol          = 1.0e-6_wp  ! Relative tolerance

    !-- Domain-specific algorithm parameters --
    REAL(wp)    :: scale_factor     = 1.0_wp     ! Scaling factor
    LOGICAL     :: use_symmetry     = .FALSE.    ! Symmetry flag
  END TYPE MD_XXX_Algo

  !=============================================================================
  ! Ctx Category
  ! 「上下文缓冲」：热路径跨层传递。禁止 ALLOCATABLE。
  ! Rule: NO ALLOCATABLE, NO POINTER ownership. POINTER fields are non-owning refs.
  !       Reset at start of each hot-path call. Size fixed at compile time.
  !=============================================================================
  TYPE, PUBLIC :: MD_XXX_Ctx
    !-- Hot-path context (reset each call; no memory allocation) --
    INTEGER(i4) :: current_id        = 0_i4    ! Active entity ID
    INTEGER(i4) :: caller_step_idx   = 0_i4    ! Step index from L5_RT
    INTEGER(i4) :: caller_incr_idx   = 0_i4    ! Increment index from L5_RT
    LOGICAL     :: is_last_iter      = .FALSE. ! Last iteration flag

    !-- Non-owning references (POINTER, not ALLOCATABLE; do NOT deallocate) --
    REAL(wp), POINTER :: work_buf(:)  => NULL()  ! Work buffer from L5_RT pool
    REAL(wp), POINTER :: result_ptr   => NULL()  ! Result slot (non-owning)
  END TYPE MD_XXX_Ctx

  !=============================================================================
  ! MD_XXX_Domain — Independent flat-storage domain container (Layer 2)
  !=============================================================================
  TYPE, PUBLIC :: MD_XXX_Domain
    !--- FLAT ALLOCATABLE ARRAYS (single source of truth) ---
    TYPE(MD_XXX_Desc),  ALLOCATABLE :: desc(:)   ! Desc array  [n_xxx]
    TYPE(MD_XXX_State), ALLOCATABLE :: state(:)  ! State array [n_xxx]
    TYPE(MD_XXX_Algo),  ALLOCATABLE :: algo(:)   ! Algo array  [n_xxx]

    !--- Domain counters ---
    INTEGER(i4) :: n_xxx         = 0_i4   ! Number of registered entities
    INTEGER(i4) :: max_xxx       = 0_i4   ! Allocated capacity

    !--- Domain lifecycle ---
    LOGICAL :: initialized       = .FALSE.
    LOGICAL :: frozen            = .FALSE. ! Set TRUE after L6_AP parse (Freeze)

    !--- Ctx is per-call, not stored in domain (use local variable in callers) ---

  CONTAINS
    PROCEDURE :: Init      => MD_XXX_Domain_Init
    PROCEDURE :: Finalize  => MD_XXX_Domain_Finalize
    PROCEDURE :: WriteBack => MD_XXX_WriteBack
    PROCEDURE :: GetDesc   => MD_XXX_Domain_GetDesc
    PROCEDURE :: GetState  => MD_XXX_Domain_GetState
    PROCEDURE :: GetAlgo   => MD_XXX_Domain_GetAlgo
  END TYPE MD_XXX_Domain

CONTAINS

  !=============================================================================
  ! MD_XXX_Domain_Init — Allocate arrays with initial capacity
  !   cap_xxx : initial capacity (number of slots to allocate)
  !=============================================================================
  SUBROUTINE MD_XXX_Domain_Init(this, cap_xxx, status)
    CLASS(MD_XXX_Domain),  INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: cap_xxx
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (this%initialized) CALL MD_XXX_Domain_Finalize(this)

    IF (cap_xxx < 1_i4) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_XXX_Domain_Init: cap_xxx must be >= 1'
      RETURN
    END IF

    ALLOCATE(this%desc(cap_xxx))
    ALLOCATE(this%state(cap_xxx))
    ALLOCATE(this%algo(cap_xxx))

    this%n_xxx       = 0_i4
    this%max_xxx     = cap_xxx
    this%initialized = .TRUE.
    this%frozen      = .FALSE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Domain_Init

  !=============================================================================
  ! MD_XXX_Domain_Finalize — Release all ALLOCATABLE arrays
  !=============================================================================
  SUBROUTINE MD_XXX_Domain_Finalize(this)
    CLASS(MD_XXX_Domain), INTENT(INOUT) :: this
    INTEGER(i4) :: i

    IF (.NOT. this%initialized) RETURN

    !-- Release inner ALLOCATABLE fields in each Desc entry --
    IF (ALLOCATED(this%desc)) THEN
      DO i = 1, this%n_xxx
        IF (ALLOCATED(this%desc(i)%data_vals)) DEALLOCATE(this%desc(i)%data_vals)
        IF (ALLOCATED(this%desc(i)%ref_ids))   DEALLOCATE(this%desc(i)%ref_ids)
      END DO
      DEALLOCATE(this%desc)
    END IF

    !-- Release inner ALLOCATABLE fields in each State entry --
    IF (ALLOCATED(this%state)) THEN
      DO i = 1, this%n_xxx
        IF (ALLOCATED(this%state(i)%state_vec)) DEALLOCATE(this%state(i)%state_vec)
      END DO
      DEALLOCATE(this%state)
    END IF

    IF (ALLOCATED(this%algo)) DEALLOCATE(this%algo)

    this%n_xxx       = 0_i4
    this%max_xxx     = 0_i4
    this%initialized = .FALSE.
    this%frozen      = .FALSE.
  END SUBROUTINE MD_XXX_Domain_Finalize

  !=============================================================================
  ! MD_XXX_WriteBack — WriteBack-whitelist-gated state update
  !   Only State fields may be modified here (Desc is frozen after parse).
  !   Called from L5_RT via WriteBack whitelist mechanism.
  !=============================================================================
  SUBROUTINE MD_XXX_WriteBack(this, xxx_id, new_state, status)
    CLASS(MD_XXX_Domain),  INTENT(INOUT) :: this
    INTEGER(i4),           INTENT(IN)    :: xxx_id
    TYPE(MD_XXX_State),    INTENT(IN)    :: new_state
    TYPE(ErrorStatusType), INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_XXX_WriteBack: domain not initialized'
      RETURN
    END IF
    IF (xxx_id < 1_i4 .OR. xxx_id > this%n_xxx) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0,A,I0)') &
        'MD_XXX_WriteBack: xxx_id=', xxx_id, ' out of range, n_xxx=', this%n_xxx
      RETURN
    END IF

    !-- Update ONLY State (Desc is frozen; Algo is read-only during solve) --
    this%state(xxx_id) = new_state
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_WriteBack

  !=============================================================================
  ! Accessor: GetDesc — Return pointer to Desc entry (read-only access pattern)
  !=============================================================================
  SUBROUTINE MD_XXX_Domain_GetDesc(domain, xxx_id, desc_ptr, status)
    CLASS(MD_XXX_Domain),           INTENT(IN)    :: domain
    INTEGER(i4),                    INTENT(IN)    :: xxx_id
    TYPE(MD_XXX_Desc), POINTER,     INTENT(OUT)   :: desc_ptr
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    NULLIFY(desc_ptr)
    IF (.NOT. domain%initialized .OR. xxx_id < 1_i4 .OR. xxx_id > domain%n_xxx) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    desc_ptr => domain%desc(xxx_id)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Domain_GetDesc

  !=============================================================================
  ! Accessor: GetState — Return pointer to State entry
  !=============================================================================
  SUBROUTINE MD_XXX_Domain_GetState(domain, xxx_id, state_ptr, status)
    CLASS(MD_XXX_Domain),            INTENT(IN)    :: domain
    INTEGER(i4),                     INTENT(IN)    :: xxx_id
    TYPE(MD_XXX_State), POINTER,     INTENT(OUT)   :: state_ptr
    TYPE(ErrorStatusType),           INTENT(OUT)   :: status

    CALL init_error_status(status)
    NULLIFY(state_ptr)
    IF (.NOT. domain%initialized .OR. xxx_id < 1_i4 .OR. xxx_id > domain%n_xxx) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    state_ptr => domain%state(xxx_id)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Domain_GetState

  !=============================================================================
  ! Accessor: GetAlgo — Return pointer to Algo entry
  !=============================================================================
  SUBROUTINE MD_XXX_Domain_GetAlgo(domain, xxx_id, algo_ptr, status)
    CLASS(MD_XXX_Domain),           INTENT(IN)    :: domain
    INTEGER(i4),                    INTENT(IN)    :: xxx_id
    TYPE(MD_XXX_Algo), POINTER,     INTENT(OUT)   :: algo_ptr
    TYPE(ErrorStatusType),          INTENT(OUT)   :: status

    CALL init_error_status(status)
    NULLIFY(algo_ptr)
    IF (.NOT. domain%initialized .OR. xxx_id < 1_i4 .OR. xxx_id > domain%n_xxx) THEN
      status%status_code = IF_STATUS_INVALID
      RETURN
    END IF
    algo_ptr => domain%algo(xxx_id)
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_XXX_Domain_GetAlgo

END MODULE MD_XXX_Domain_Types
