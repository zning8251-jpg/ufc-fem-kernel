!===============================================================================
! Template: MD_Model_Types.f90                                [Template v1.0]
! Layer:    L3_MD — Model Description Layer
! Domain:   Model — Top-level Index Tree
!
! PURPOSE & DESIGN INTENT:
!   MD_Model_Domain is the INDEX TREE for the entire L3_MD layer.
!   It holds ONLY summary counts and cross-reference ID arrays — no data bodies.
!
! THREE-LAYER ARCHITECTURE — Layer 1 Specification:
!
!   Layer 1 — MD_Model_Domain  (THIS file — Index Tree)
!   ───────────────────────────────────────────────────
!   Responsibility:
!     • Store summary counts (n_parts, n_steps, n_materials, ...)
!     • Store cross-domain reference arrays (e.g., step_id_list, material_id_list)
!     • Updated via SyncModelCounts() AFTER all domain Init() calls
!     • Frozen after L6_AP parse (via LayerContainer%Freeze)
!     • Read-only during solve (L5_RT reads from domain arrays, not here)
!
!   Data flow:
!     L6_AP parse → each domain%Add() → SyncModelCounts() → Model%desc updated
!     L5_RT solve → reads domain%desc(i) directly, never via Model%desc
!
!   What Model_Domain must NOT do:
!     ✗ Store material properties, step parameters, mesh data
!     ✗ Create second copies of data from other domains
!     ✗ Allocate large arrays that duplicate domain storage
!
!   Layer 2 — MD_XXX_Domain  (see MD_XXX_Domain_Types.f90)
!   Layer 3 — MD_L3_LayerContainer  (see MD_L3_LayerContainer_Core.f90)
!
! PRODUCTION REFERENCE:
!   Production implementation: UFC/ufc_core/L3_MD/Model/MD_Model_Core.f90
!   This template aligns with that implementation's MD_Model_Desc +
!   MD_Model_Domain pattern. Use this as a design reference/starting scaffold.
!
! FOUR TYPE CATEGORIES for Model domain:
!   Desc  — summary counts, analysis type, model name (write-once)
!   State — build status, timestamp (WriteBack whitelist gated)
!   Algo  — (none for Model domain; reserved for future extension)
!   Ctx   — (none for Model domain; Model is cold-path only)
!
! ANALYSIS TYPE CONSTANTS (align with MD_Model_Core.f90 production values):
!   MD_MODEL_ANALYSIS_STATIC           = 1
!   MD_MODEL_ANALYSIS_DYNAMIC_IMPLICIT = 2
!   MD_MODEL_ANALYSIS_DYNAMIC_EXPLICIT = 3
!   MD_MODEL_ANALYSIS_EIGENVALUE       = 4
!   MD_MODEL_ANALYSIS_HEAT_TRANSFER    = 5
!   MD_MODEL_ANALYSIS_COUPLED_TEMP     = 6
!
! Last revised: 2026-03-30
!===============================================================================
MODULE MD_Model_Types
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID
  IMPLICIT NONE
  PRIVATE

  !--- Public exports ---
  PUBLIC :: MD_Model_Desc
  PUBLIC :: MD_Model_State
  PUBLIC :: MD_Model_Domain
  PUBLIC :: MD_Model_Domain_Init
  PUBLIC :: MD_Model_Domain_Finalize
  PUBLIC :: MD_Model_Domain_SetDesc
  PUBLIC :: MD_Model_Domain_SyncCounts
  PUBLIC :: MD_Model_WriteBack

  !=============================================================================
  ! Analysis type constants — mirror MD_Model_Core.f90 production values
  !=============================================================================
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_STATIC           = 1_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_DYNAMIC_IMPLICIT = 2_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_DYNAMIC_EXPLICIT = 3_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_EIGENVALUE       = 4_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_HEAT_TRANSFER    = 5_i4
  INTEGER(i4), PARAMETER, PUBLIC :: MD_MODEL_ANALYSIS_COUPLED_TEMP     = 6_i4

  !=============================================================================
  ! MD_Model_Desc — Write-once model metadata (INDEX TREE summary)
  !
  ! RULE: These are COUNTS only. They are synced from domain arrays via
  !       SyncModelCounts(). Never store data bodies here.
  !=============================================================================
  TYPE, PUBLIC :: MD_Model_Desc
    !-- Identity --
    CHARACTER(LEN=256) :: model_name    = ''        ! Model name (from input file)
    INTEGER(i4)        :: spatial_dim   = 3_i4      ! 2 or 3
    INTEGER(i4)        :: analysis_type = MD_MODEL_ANALYSIS_STATIC

    !-- Summary counts (synced from each domain; read-only during solve) --
    !   Updated by MD_L3_LayerContainer%SyncModelCounts()
    INTEGER(i4) :: n_parts         = 0_i4    ! Part domain count
    INTEGER(i4) :: n_steps         = 0_i4    ! Step domain count
    INTEGER(i4) :: n_materials     = 0_i4    ! Material domain count
    INTEGER(i4) :: n_sections      = 0_i4    ! Section domain count
    INTEGER(i4) :: n_loadbcs       = 0_i4    ! Load + BC domain count (combined)
    INTEGER(i4) :: n_amplitudes    = 0_i4    ! Amplitude domain count
    INTEGER(i4) :: n_interactions  = 0_i4    ! Interaction/Contact domain count
    INTEGER(i4) :: n_outputs       = 0_i4    ! Output request count
    INTEGER(i4) :: n_constraints   = 0_i4    ! Constraint domain count
    INTEGER(i4) :: n_meshes        = 0_i4    ! Mesh partition count (usually 1)

    !-- Cross-reference ID arrays (optional; populated only if needed by L5_RT)
    !   These are ID lists for ordered traversal; actual data lives in domains.
    !   Leave as size-0 if not required — domains are accessed by index directly.
    !
    !   Example usage (if needed):
    !     INTEGER(i4), ALLOCATABLE :: active_step_ids(:)   ! Ordered step execution list
    !     INTEGER(i4), ALLOCATABLE :: active_material_ids(:)
    !
    !   Current policy: Do NOT allocate unless L5_RT traversal requires ordered ID list.
    !   Simple sequential traversal (DO i=1,n_steps) is preferred over ID indirection.

  END TYPE MD_Model_Desc

  !=============================================================================
  ! MD_Model_State — WriteBack-gated runtime state
  !
  ! RULE: Only fields in the WriteBack whitelist may be written.
  !       The whitelist is managed in MD_L3_LayerContainer%PopulateWriteBackWhitelist.
  !       Currently whitelisted: isBuilt, build_timestamp.
  !=============================================================================
  TYPE, PUBLIC :: MD_Model_State
    LOGICAL  :: isBuilt          = .FALSE.   ! L5_RT marks TRUE after build complete
    REAL(wp) :: build_timestamp  = 0.0_wp    ! Time when model was built (seconds)
  END TYPE MD_Model_State

  !-- NOTE: MD_Model_Algo and MD_Model_Ctx are intentionally omitted.
  !   Model domain is cold-path only. If future extensions require algorithm
  !   parameters for model-level operations, add MD_Model_Algo at that time.

  !=============================================================================
  ! MD_Model_Domain — Layer 1 Index Tree container
  !
  ! This is a SINGLETON (one per MD_L3_LayerContainer).
  ! No ALLOCATABLE arrays of Desc/State — there is exactly one model.
  ! All counts are scalars in Desc; State is a single scalar struct.
  !=============================================================================
  TYPE, PUBLIC :: MD_Model_Domain
    !--- Single Desc (write-once after parse) ---
    TYPE(MD_Model_Desc) :: desc

    !--- Single State (WriteBack whitelist gated) ---
    TYPE(MD_Model_State) :: state

    !--- Lifecycle ---
    LOGICAL :: initialized = .FALSE.

  CONTAINS
    PROCEDURE :: Init          => MD_Model_Domain_Init
    PROCEDURE :: Finalize      => MD_Model_Domain_Finalize
    PROCEDURE :: SetDesc       => MD_Model_Domain_SetDesc
    PROCEDURE :: SyncCounts    => MD_Model_Domain_SyncCounts
    PROCEDURE :: WriteBack     => MD_Model_WriteBack
    PROCEDURE :: ValidateModel => MD_Model_Domain_Validate
  END TYPE MD_Model_Domain

CONTAINS

  SUBROUTINE MD_Model_Domain_Init(this, model_name, spatial_dim, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),       INTENT(IN)    :: model_name
    INTEGER(i4),            INTENT(IN)    :: spatial_dim
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (spatial_dim /= 2_i4 .AND. spatial_dim /= 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Model_Domain_Init: spatial_dim must be 2 or 3, got ', spatial_dim
      RETURN
    END IF

    this%desc%model_name    = TRIM(model_name)
    this%desc%spatial_dim   = spatial_dim
    this%desc%analysis_type = MD_MODEL_ANALYSIS_STATIC  ! Default; set via SetDesc

    !-- Zero all counts (will be synced by SyncModelCounts) --
    this%desc%n_parts        = 0_i4
    this%desc%n_steps        = 0_i4
    this%desc%n_materials    = 0_i4
    this%desc%n_sections     = 0_i4
    this%desc%n_loadbcs      = 0_i4
    this%desc%n_amplitudes   = 0_i4
    this%desc%n_interactions = 0_i4
    this%desc%n_outputs      = 0_i4
    this%desc%n_constraints  = 0_i4
    this%desc%n_meshes       = 0_i4

    this%state%isBuilt         = .FALSE.
    this%state%build_timestamp = 0.0_wp

    this%initialized = .TRUE.
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Domain_Init

  SUBROUTINE MD_Model_Domain_Finalize(this)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this

    IF (.NOT. this%initialized) RETURN

    this%desc          = MD_Model_Desc()   ! Reset to defaults
    this%state         = MD_Model_State()
    this%initialized   = .FALSE.
  END SUBROUTINE MD_Model_Domain_Finalize

  SUBROUTINE MD_Model_Domain_SetDesc(this, model_name, analysis_type, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this
    CHARACTER(LEN=*),       INTENT(IN)    :: model_name
    INTEGER(i4),            INTENT(IN)    :: analysis_type
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Model_Domain_SetDesc: domain not initialized'
      RETURN
    END IF

    IF (analysis_type < MD_MODEL_ANALYSIS_STATIC .OR. &
        analysis_type > MD_MODEL_ANALYSIS_COUPLED_TEMP) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') 'MD_Model_Domain_SetDesc: unknown analysis_type=', analysis_type
      RETURN
    END IF

    this%desc%model_name    = TRIM(model_name)
    this%desc%analysis_type = analysis_type
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Domain_SetDesc

  SUBROUTINE MD_Model_Domain_SyncCounts(this, &
      n_parts, n_steps, n_materials, n_sections, &
      n_loadbcs, n_amplitudes, n_interactions, n_outputs, &
      n_constraints, n_meshes, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this
    INTEGER(i4),            INTENT(IN)    :: n_parts, n_steps, n_materials
    INTEGER(i4),            INTENT(IN)    :: n_sections, n_loadbcs, n_amplitudes
    INTEGER(i4),            INTENT(IN)    :: n_interactions, n_outputs
    INTEGER(i4),            INTENT(IN)    :: n_constraints, n_meshes
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Model_Domain_SyncCounts: domain not initialized'
      RETURN
    END IF

    this%desc%n_parts        = n_parts
    this%desc%n_steps        = n_steps
    this%desc%n_materials    = n_materials
    this%desc%n_sections     = n_sections
    this%desc%n_loadbcs      = n_loadbcs
    this%desc%n_amplitudes   = n_amplitudes
    this%desc%n_interactions = n_interactions
    this%desc%n_outputs      = n_outputs
    this%desc%n_constraints  = n_constraints
    this%desc%n_meshes       = n_meshes

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Domain_SyncCounts

  SUBROUTINE MD_Model_WriteBack(this, isBuilt, build_timestamp, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this
    LOGICAL,                INTENT(IN)    :: isBuilt
    REAL(wp),               INTENT(IN)    :: build_timestamp
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Model_WriteBack: domain not initialized'
      RETURN
    END IF

    this%state%isBuilt         = isBuilt
    this%state%build_timestamp = build_timestamp
    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_WriteBack

  !=============================================================================
  ! MD_Model_Domain_Validate — Validate model domain basic fields
  !=============================================================================
  SUBROUTINE MD_Model_Domain_Validate(this, status)
    CLASS(MD_Model_Domain), INTENT(IN)  :: this
    TYPE(ErrorStatusType),  INTENT(OUT) :: status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Model_Domain_Validate: domain not initialized'
      RETURN
    END IF

    IF (LEN_TRIM(this%desc%model_name) == 0) THEN
      status%status_code = IF_STATUS_INVALID
      status%message     = 'MD_Model_Domain_Validate: model_name is empty'
      RETURN
    END IF

    IF (this%desc%spatial_dim /= 2_i4 .AND. this%desc%spatial_dim /= 3_i4) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') &
        'MD_Model_Domain_Validate: spatial_dim must be 2 or 3, got ', this%desc%spatial_dim
      RETURN
    END IF

    IF (this%desc%analysis_type < MD_MODEL_ANALYSIS_STATIC .OR. &
        this%desc%analysis_type > MD_MODEL_ANALYSIS_COUPLED_TEMP) THEN
      status%status_code = IF_STATUS_INVALID
      WRITE(status%message, '(A,I0)') &
        'MD_Model_Domain_Validate: unknown analysis_type=', this%desc%analysis_type
      RETURN
    END IF

    status%status_code = IF_STATUS_OK
  END SUBROUTINE MD_Model_Domain_Validate

END MODULE MD_Model_Types
