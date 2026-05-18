!===============================================================================
! MODULE:  MD_Model_Mgr
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Mgr (domain manager / container facade)
! BRIEF:   Top-level model domain container. MD_Model_Domain uses the unified
!          MD_Model_Desc (from MD_Model_Def) with cfg%/pop% nesting.
!          P0: Register/Query/Get/Validate/WriteBack operations.
!          Includes MD_Model_Ctx (unified context for model operations).
!
!          v2.2 — removed redundant MD_Model_Desc and analysis constants;
!          now imports MD_Model_Desc and constants from MD_Model_Def (SSOT).
!
! NOTE:    Historical file/module name swap — do NOT rename:
!          MD_Model_Mgr.f90 -> MODULE MD_Model_Mgr (was MD_ModelDomain.f90)
!===============================================================================
MODULE MD_Model_Mgr
  USE IF_Prec_Core,    ONLY: wp, i4
  USE IF_Err_Brg,      ONLY: ErrorStatusType, init_error_status, &
                              MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID, &
                              uf_set_error_status
  USE MD_Base_ObjModel, ONLY: BaseCtx, BaseSta
  USE MD_Model_Def,    ONLY: MD_Model_Desc, MD_Model_State, MD_Model_Ctx, &
                              MD_Model_Algo, &
                              MD_MODEL_ANALYSIS_STATIC, MD_MODEL_ANALYSIS_COUPLED_TEMP
  USE MD_ModelRT_Brg,  ONLY: ThreadWS
  USE MD_Model_Import, ONLY: ImportProperties
  USE MD_Model_Prestress, ONLY: PrestressProperties
  USE MD_Model_Substruct, ONLY: SubstructureProperties
  IMPLICIT NONE
  PRIVATE

  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Domain
  ! KIND:  Ctx
  ! DESC:  Domain container (single source of truth for model)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_Domain
    TYPE(MD_Model_Desc) :: desc                          ! model descriptor
    LOGICAL             :: isBuilt        = .FALSE.      ! build completed flag
    REAL(wp)            :: build_timestamp = 0.0_wp      ! build timestamp
    LOGICAL             :: initialized    = .FALSE.      ! init state
  CONTAINS
    PROCEDURE :: Init          => MD_Model_Domain_Init
    PROCEDURE :: Finalize      => MD_Model_Domain_Finalize
    PROCEDURE :: SetDesc       => MD_Model_Domain_SetDesc
    PROCEDURE :: GetInfo       => MD_Model_Domain_GetInfo
    PROCEDURE :: WriteBack     => MD_Model_WriteBack
    PROCEDURE :: ValidateModel => MD_Model_ValidateModel
    PROCEDURE :: GetModelByName => MD_Model_Domain_GetModelByName
    PROCEDURE :: GetSummary    => MD_Model_Domain_GetSummary
  END TYPE MD_Model_Domain


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_GetSummary_Arg
  ! KIND:  Arg
  ! DESC:  Argument bundle for GetSummary operation
  !---------------------------------------------------------------------------
  TYPE, PUBLIC :: MD_Model_GetSummary_Arg
    CHARACTER(LEN=512)    :: summary = ""  ! [out] summary text
    TYPE(ErrorStatusType) :: status        ! [out] error status
  END TYPE MD_Model_GetSummary_Arg


  !---------------------------------------------------------------------------
  ! TYPE:  MD_Model_Ctx
  ! KIND:  Ctx
  ! DESC:  Unified context for model operations (extends BaseCtx)
  !---------------------------------------------------------------------------
  TYPE, PUBLIC, EXTENDS(BaseCtx) :: MD_Model_Ctx
    TYPE(BaseSta)                 :: sta                     ! status state
    TYPE(MD_Model_Desc),  POINTER :: desc => NULL()          ! descriptor pointer
    TYPE(MD_Model_State), POINTER :: state => NULL()         ! state pointer
    TYPE(MD_Model_Ctx),   POINTER :: ctx => NULL()           ! context pointer
    TYPE(MD_Model_Algo),  POINTER :: algo => NULL()          ! algorithm pointer
    TYPE(ThreadWS),       POINTER :: tws(:) => NULL()       ! thread workspace
    LOGICAL                      :: success = .FALSE.       ! operation success flag
  CONTAINS
    PROCEDURE :: Init           => MD_Model_Ctx_Init
    PROCEDURE :: Destroy        => MD_Model_Ctx_Destroy
    PROCEDURE :: Reset          => MD_Model_Ctx_Reset
    PROCEDURE :: GetStatus      => MD_Model_Ctx_GetStatus
    PROCEDURE :: SetStatus      => MD_Model_Ctx_SetStatus
    PROCEDURE :: ClearStatus    => MD_Model_Ctx_ClearStatus
    PROCEDURE :: IsOK           => MD_Model_Ctx_IsOK
    PROCEDURE :: IsError        => MD_Model_Ctx_IsError
    PROCEDURE :: Bind           => MD_Model_Ctx_Bind
    PROCEDURE :: Valid          => MD_Model_Ctx_Valid
    PROCEDURE :: GetDesc       => MD_Model_Ctx_GetDesc
    PROCEDURE :: GetState       => MD_Model_Ctx_GetState
    PROCEDURE :: GetAlgo        => MD_Model_Ctx_GetAlgo
  END TYPE MD_Model_Ctx

  TYPE, PUBLIC :: MD_Model_AdvProps
    INTEGER(i4) :: numImports = 0_i4
    INTEGER(i4) :: numPrestresses = 0_i4
    INTEGER(i4) :: numSubstructures = 0_i4
    TYPE(ImportProperties), ALLOCATABLE :: imports(:)
    TYPE(PrestressProperties), ALLOCATABLE :: prestresses(:)
    TYPE(SubstructureProperties), ALLOCATABLE :: substructures(:)
  CONTAINS
    PROCEDURE, PUBLIC :: AddImport => MD_Model_AdvProps_AddImport
    PROCEDURE, PUBLIC :: AddPrestress => MD_Model_AdvProps_AddPrestress
    PROCEDURE, PUBLIC :: AddSubstructure => MD_Model_AdvProps_AddSubstructure
    PROCEDURE, PUBLIC :: FindImport => MD_Model_AdvProps_FindImport
    PROCEDURE, PUBLIC :: FindPrestress => MD_Model_AdvProps_FindPrestress
    PROCEDURE, PUBLIC :: FindSubstructure => MD_Model_AdvProps_FindSubstructure
    PROCEDURE, PUBLIC :: Clear => MD_Model_AdvProps_Clear
  END TYPE MD_Model_AdvProps

  ! Public procedures (non-TBP)
  PUBLIC :: MD_Model_Ctx
  PUBLIC :: MD_Model_Ctx_Get_NestedContext
  PUBLIC :: MD_Model_Ctx_Set_NestedContext
  PUBLIC :: MD_Model_Ctx_Merge_Contexts
  PUBLIC :: MD_Model_Domain_Init_Arg, MD_Model_Domain_SetDesc_Arg, MD_Model_Domain_Validate_Arg
  PUBLIC :: MD_Model_AdvProps

CONTAINS

  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize model domain with name and dimension
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_Init(this, model_name, spatial_dim, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this         ! [inout] domain
    CHARACTER(LEN=*),       INTENT(IN)    :: model_name   ! [in] model name
    INTEGER(i4),            INTENT(IN)    :: spatial_dim  ! [in] spatial dim
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status       ! [out] status

    CALL init_error_status(status)

    IF (this%initialized) THEN
      CALL this%Finalize()
    END IF

    CALL this%desc%Init()
    this%desc%model_name  = TRIM(model_name)
    this%desc%spatial_dim = spatial_dim
    this%isBuilt          = .FALSE.
    this%build_timestamp  = 0.0_wp
    this%initialized      = .TRUE.

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Domain_Init


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_Finalize
  ! PHASE:      P0
  ! PURPOSE:    Release resources and reset state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_Finalize(this)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this  ! [inout] domain

    CALL this%desc%Clean()
    this%isBuilt         = .FALSE.
    this%build_timestamp = 0.0_wp
    this%initialized     = .FALSE.
  END SUBROUTINE MD_Model_Domain_Finalize


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_GetInfo
  ! PHASE:      P0
  ! PURPOSE:    Read-only copy of model descriptor
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_GetInfo(this, desc, status)
    CLASS(MD_Model_Domain), INTENT(IN)  :: this    ! [in] domain
    TYPE(MD_Model_Desc),    INTENT(OUT) :: desc    ! [out] descriptor copy
    TYPE(ErrorStatusType),  INTENT(OUT) :: status  ! [out] status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF

    desc = this%desc
    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Domain_GetInfo


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_SetDesc
  ! PHASE:      P0
  ! PURPOSE:    Set full model descriptor (Write-Once)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_SetDesc(this, desc, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this    ! [inout] domain
    TYPE(MD_Model_Desc),    INTENT(IN)    :: desc    ! [in] descriptor
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status  ! [out] status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF

    this%desc = desc
    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Domain_SetDesc


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_WriteBack
  ! PHASE:      P0
  ! PURPOSE:    WriteBack whitelist fields (isBuilt, build_timestamp)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_WriteBack(this, isBuilt, build_timestamp, status)
    CLASS(MD_Model_Domain), INTENT(INOUT) :: this             ! [inout] domain
    LOGICAL,                INTENT(IN)    :: isBuilt          ! [in] built flag
    REAL(wp),               INTENT(IN)    :: build_timestamp  ! [in] timestamp
    TYPE(ErrorStatusType),  INTENT(OUT)   :: status           ! [out] status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF

    this%isBuilt         = isBuilt
    this%build_timestamp = build_timestamp
    status%status_code   = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_WriteBack


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_ValidateModel
  ! PHASE:      P0
  ! PURPOSE:    Consistency check on model descriptor
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_ValidateModel(this, status)
    CLASS(MD_Model_Domain), INTENT(IN)  :: this    ! [in] domain
    TYPE(ErrorStatusType),  INTENT(OUT) :: status  ! [out] status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF
    IF (LEN_TRIM(this%desc%model_name) == 0) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "model_name is empty"
      RETURN
    END IF
    IF (this%desc%spatial_dim /= 2_i4 .AND. this%desc%spatial_dim /= 3_i4) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "spatial_dim must be 2 or 3"
      RETURN
    END IF
    IF (this%desc%cfg%analysis_type < MD_MODEL_ANALYSIS_STATIC .OR. &
        this%desc%cfg%analysis_type > MD_MODEL_ANALYSIS_COUPLED_TEMP) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "analysis_type out of valid range"
      RETURN
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_ValidateModel


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_GetModelByName
  ! PHASE:      P0
  ! PURPOSE:    Check if model name matches (for single model domain)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_GetModelByName(this, name, found, status)
    CLASS(MD_Model_Domain), INTENT(IN)  :: this    ! [in] domain
    CHARACTER(LEN=*),       INTENT(IN)  :: name    ! [in] name to match
    LOGICAL,                INTENT(OUT) :: found   ! [out] match result
    TYPE(ErrorStatusType),  INTENT(OUT) :: status  ! [out] status

    CALL init_error_status(status)
    found = .FALSE.

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF

    IF (TRIM(this%desc%model_name) == TRIM(name)) THEN
      found = .TRUE.
    END IF

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Domain_GetModelByName


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Domain_GetSummary
  ! PHASE:      P0
  ! PURPOSE:    Get model summary (Arg wrapper)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Domain_GetSummary(this, arg)
    CLASS(MD_Model_Domain),        INTENT(IN)    :: this  ! [in] domain
    TYPE(MD_Model_GetSummary_Arg), INTENT(INOUT) :: arg   ! [inout] arg bundle
    CALL MD_Model_GetSummary_Impl(this, arg%summary, arg%status)
  END SUBROUTINE MD_Model_Domain_GetSummary


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_GetSummary_Impl
  ! PHASE:      P0
  ! PURPOSE:    Generate summary string from model state
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_GetSummary_Impl(this, summary, status)
    CLASS(MD_Model_Domain), INTENT(IN)  :: this     ! [in] domain
    CHARACTER(LEN=512),     INTENT(OUT) :: summary  ! [out] summary text
    TYPE(ErrorStatusType),  INTENT(OUT) :: status   ! [out] status

    CALL init_error_status(status)

    IF (.NOT. this%initialized) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = "MD_Model_Domain not initialized"
      RETURN
    END IF

    WRITE(summary, '(A,A,A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,I0,A,L1)') &
      "Model: '", TRIM(this%desc%model_name), "', ", &
      "Dim=", this%desc%spatial_dim, &
      ", Type=", this%desc%cfg%analysis_type, &
      ", Parts=", this%desc%n_parts, &
      ", Steps=", this%desc%n_steps, &
      ", Mats=", this%desc%n_materials, &
      ", Secs=", this%desc%n_sections, &
      ", Loads=", this%desc%n_loadbcs, &
      ", Interactions=", this%desc%n_interactions, &
      ", Built=", this%isBuilt

    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_GetSummary_Impl


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Init
  ! PHASE:      P0
  ! PURPOSE:    Initialize model context
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Init(this)
    CLASS(MD_Model_Ctx), INTENT(INOUT) :: this  ! [inout] context
    TYPE(ErrorStatusType) :: status
    CALL init_error_status(status)
    CALL this%SetStatus(status)
    this%init = .TRUE.
  END SUBROUTINE MD_Model_Ctx_Init


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Destroy
  ! PHASE:      P0
  ! PURPOSE:    Destroy context and nullify all pointers
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Destroy(this)
    CLASS(MD_Model_Ctx), INTENT(INOUT) :: this  ! [inout] context
    NULLIFY(this%desc)
    NULLIFY(this%state)
    NULLIFY(this%ctx)
    NULLIFY(this%algo)
    NULLIFY(this%tws)
    this%success = .FALSE.
    this%init = .FALSE.
  END SUBROUTINE MD_Model_Ctx_Destroy


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Reset
  ! PHASE:      P0
  ! PURPOSE:    Reset context success flag and clear status
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Reset(this)
    CLASS(MD_Model_Ctx), INTENT(INOUT) :: this  ! [inout] context
    this%success = .FALSE.
    CALL this%ClearStatus()
  END SUBROUTINE MD_Model_Ctx_Reset


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_GetStatus
  ! PHASE:      P0
  ! PURPOSE:    Query current status from context
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_GetStatus(this) RESULT(status)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    TYPE(ErrorStatusType) :: status
    IF (.NOT. this%init) THEN
      CALL init_error_status(status)
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx not initialized'
    ELSE
      status = this%sta%GetStatus()
    END IF
  END FUNCTION MD_Model_Ctx_GetStatus


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_SetStatus
  ! PHASE:      P0
  ! PURPOSE:    Set status in context
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_SetStatus(this, status)
    CLASS(MD_Model_Ctx), INTENT(INOUT)  :: this    ! [inout] context
    TYPE(ErrorStatusType), INTENT(IN)   :: status  ! [in] status to set
    CALL this%sta%SetStatus(status)
  END SUBROUTINE MD_Model_Ctx_SetStatus


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_ClearStatus
  ! PHASE:      P0
  ! PURPOSE:    Clear status in context
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_ClearStatus(this)
    CLASS(MD_Model_Ctx), INTENT(INOUT) :: this  ! [inout] context
    CALL this%sta%ClearStatus()
  END SUBROUTINE MD_Model_Ctx_ClearStatus


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_IsOK
  ! PHASE:      P0
  ! PURPOSE:    Check if context status is OK
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_IsOK(this) RESULT(is_ok)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    LOGICAL :: is_ok
    is_ok = this%sta%IsOK()
  END FUNCTION MD_Model_Ctx_IsOK


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_IsError
  ! PHASE:      P0
  ! PURPOSE:    Check if context status is error
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_IsError(this) RESULT(is_error)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    LOGICAL :: is_error
    is_error = this%sta%IsError()
  END FUNCTION MD_Model_Ctx_IsError


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Bind
  ! PHASE:      P0
  ! PURPOSE:    Bind context to model components
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Bind(this, desc, state, ctx, algo, tws)
    CLASS(MD_Model_Ctx), INTENT(INOUT) :: this  ! [inout] context
    TYPE(MD_Model_Desc), TARGET, INTENT(IN), OPTIONAL   :: desc
    TYPE(MD_Model_State), TARGET, INTENT(IN), OPTIONAL  :: state
    TYPE(MD_Model_Ctx), TARGET, INTENT(IN), OPTIONAL    :: ctx
    TYPE(MD_Model_Algo), TARGET, INTENT(IN), OPTIONAL   :: algo
    TYPE(ThreadWS), TARGET, INTENT(IN), OPTIONAL    :: tws(:)

    IF (PRESENT(desc)) this%desc => desc
    IF (PRESENT(state)) this%state => state
    IF (PRESENT(ctx)) this%ctx => ctx
    IF (PRESENT(algo)) this%algo => algo
    IF (PRESENT(tws)) this%tws => tws
    CALL this%Init()
  END SUBROUTINE MD_Model_Ctx_Bind


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_Valid
  ! PHASE:      P0
  ! PURPOSE:    Check if context has valid model binding
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_Valid(this) RESULT(is_valid)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    LOGICAL :: is_valid
    is_valid = .TRUE.
    IF (.NOT. ASSOCIATED(this%desc)) is_valid = .FALSE.
  END FUNCTION MD_Model_Ctx_Valid


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_GetDesc
  ! PHASE:      P0
  ! PURPOSE:    Get descriptor pointer from context
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_GetDesc(this) RESULT(desc)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    TYPE(MD_Model_Desc), POINTER :: desc
    desc => this%desc
  END FUNCTION MD_Model_Ctx_GetDesc


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_GetState
  ! PHASE:      P0
  ! PURPOSE:    Get state pointer from context
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_GetState(this) RESULT(state)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    TYPE(MD_Model_State), POINTER :: state
    state => this%state
  END FUNCTION MD_Model_Ctx_GetState


  !---------------------------------------------------------------------------
  ! FUNCTION:   MD_Model_Ctx_GetAlgo
  ! PHASE:      P0
  ! PURPOSE:    Get algorithm pointer from context
  !---------------------------------------------------------------------------
  FUNCTION MD_Model_Ctx_GetAlgo(this) RESULT(algo)
    CLASS(MD_Model_Ctx), INTENT(IN) :: this  ! [in] context
    TYPE(MD_Model_Algo), POINTER :: algo
    algo => this%algo
  END FUNCTION MD_Model_Ctx_GetAlgo


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Get_NestedContext
  ! PHASE:      P0
  ! PURPOSE:    Retrieve nested context from parent (composition utility)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Get_NestedContext(parent, context_name, nested_context, found, status)
    CLASS(BaseCtx), INTENT(IN)                :: parent          ! [in] parent ctx
    CHARACTER(LEN=*), INTENT(IN)              :: context_name    ! [in] context key
    CLASS(BaseCtx), POINTER, INTENT(OUT)      :: nested_context  ! [out] nested ctx
    LOGICAL, INTENT(OUT)                      :: found           ! [out] found flag
    TYPE(ErrorStatusType), INTENT(OUT)        :: status          ! [out] status

    CALL init_error_status(status)
    found = .FALSE.
    nested_context => NULL()
    IF (.NOT. parent%init) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx_Get_NestedContext: Parent Ctx not initialized'
      RETURN
    END IF
    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Ctx_Get_NestedContext


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Set_NestedContext
  ! PHASE:      P0
  ! PURPOSE:    Set nested context in parent (composition utility)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Set_NestedContext(parent, context_name, nested_context, status)
    CLASS(BaseCtx), INTENT(INOUT)             :: parent          ! [inout] parent
    CHARACTER(LEN=*), INTENT(IN)              :: context_name    ! [in] context key
    CLASS(BaseCtx), POINTER, INTENT(IN)       :: nested_context  ! [in] nested ctx
    TYPE(ErrorStatusType), INTENT(OUT)        :: status          ! [out] status

    CALL init_error_status(status)
    IF (.NOT. parent%init) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx_Set_NestedContext: Parent Ctx not initialized'
      RETURN
    END IF
    IF (.NOT. ASSOCIATED(nested_context)) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx_Set_NestedContext: Nested Ctx pointer is null'
      RETURN
    END IF
    IF (.NOT. nested_context%init) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx_Set_NestedContext: Nested Ctx not initialized'
      RETURN
    END IF
    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Ctx_Set_NestedContext


  !---------------------------------------------------------------------------
  ! SUBROUTINE: MD_Model_Ctx_Merge_Contexts
  ! PHASE:      P0
  ! PURPOSE:    Merge two contexts into one (composition utility)
  !---------------------------------------------------------------------------
  SUBROUTINE MD_Model_Ctx_Merge_Contexts(ctx1, ctx2, merged, status)
    CLASS(BaseCtx), INTENT(IN)           :: ctx1    ! [in] first context
    CLASS(BaseCtx), INTENT(IN)           :: ctx2    ! [in] second context
    CLASS(BaseCtx), INTENT(OUT)          :: merged  ! [out] merged context
    TYPE(ErrorStatusType), INTENT(OUT)   :: status  ! [out] status

    CALL init_error_status(status)
    IF (.NOT. ctx1%init .OR. .NOT. ctx2%init) THEN
      status%status_code = MD_MODEL_STATUS_INVALID
      status%message = 'MD_Model_Ctx_Merge_Contexts: One or both contexts not initialized'
      RETURN
    END IF
    merged%init = ctx1%init .AND. ctx2%init
    IF (ctx1%IsError()) THEN
      merged%sta = ctx1%sta
    ELSE IF (ctx2%IsError()) THEN
      merged%sta = ctx2%sta
    ELSE
      merged%sta = ctx1%sta
    END IF
    status%status_code = MD_MODEL_STATUS_OK
  END SUBROUTINE MD_Model_Ctx_Merge_Contexts

  SUBROUTINE MD_Model_AdvProps_AddImport(this, import_prop, status)
    CLASS(MD_Model_AdvProps), INTENT(INOUT) :: this
    TYPE(ImportProperties), INTENT(IN) :: import_prop
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(ImportProperties), ALLOCATABLE :: temp(:)
    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, this%numImports
      IF (TRIM(this%imports(i)%import_name) == TRIM(import_prop%import_name)) THEN
        CALL uf_set_error_status(status, MD_MODEL_STATUS_INVALID, "Import already exists: " &
            // TRIM(import_prop%import_name))
        RETURN
      END IF
    END DO
    IF (.NOT. ALLOCATED(this%imports)) THEN
      ALLOCATE(this%imports(10))
    ELSE IF (this%numImports >= SIZE(this%imports)) THEN
      ALLOCATE(temp(this%numImports + 10))
      DO i = 1, this%numImports
        temp(i) = this%imports(i)
      END DO
      DEALLOCATE(this%imports)
      CALL MOVE_ALLOC(temp, this%imports)
    END IF
    this%numImports = this%numImports + 1
    this%imports(this%numImports) = import_prop
  END SUBROUTINE MD_Model_AdvProps_AddImport

  SUBROUTINE MD_Model_AdvProps_AddPrestress(this, prestress, status)
    CLASS(MD_Model_AdvProps), INTENT(INOUT) :: this
    TYPE(PrestressProperties), INTENT(IN) :: prestress
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(PrestressProperties), ALLOCATABLE :: temp(:)
    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, this%numPrestresses
      IF (TRIM(this%prestresses(i)%prestress_name) == TRIM(prestress%prestress_name)) THEN
        CALL uf_set_error_status(status, MD_MODEL_STATUS_INVALID, "Prestress already exists: " &
            // TRIM(prestress%prestress_name))
        RETURN
      END IF
    END DO
    IF (.NOT. ALLOCATED(this%prestresses)) THEN
      ALLOCATE(this%prestresses(10))
    ELSE IF (this%numPrestresses >= SIZE(this%prestresses)) THEN
      ALLOCATE(temp(this%numPrestresses + 10))
      DO i = 1, this%numPrestresses
        temp(i) = this%prestresses(i)
      END DO
      DEALLOCATE(this%prestresses)
      CALL MOVE_ALLOC(temp, this%prestresses)
    END IF
    this%numPrestresses = this%numPrestresses + 1
    this%prestresses(this%numPrestresses) = prestress
  END SUBROUTINE MD_Model_AdvProps_AddPrestress

  SUBROUTINE MD_Model_AdvProps_AddSubstructure(this, substructure, status)
    CLASS(MD_Model_AdvProps), INTENT(INOUT) :: this
    TYPE(SubstructureProperties), INTENT(IN) :: substructure
    TYPE(ErrorStatusType), INTENT(OUT) :: status
    TYPE(SubstructureProperties), ALLOCATABLE :: temp(:)
    INTEGER(i4) :: i

    CALL init_error_status(status)
    DO i = 1, this%numSubstructures
      IF (TRIM(this%substructures(i)%substructure_name) == TRIM(substructure%substructure_name)) THEN
        CALL uf_set_error_status(status, MD_MODEL_STATUS_INVALID, "Substructure already exists: " &
            // TRIM(substructure%substructure_name))
        RETURN
      END IF
    END DO
    IF (.NOT. ALLOCATED(this%substructures)) THEN
      ALLOCATE(this%substructures(10))
    ELSE IF (this%numSubstructures >= SIZE(this%substructures)) THEN
      ALLOCATE(temp(this%numSubstructures + 10))
      DO i = 1, this%numSubstructures
        temp(i) = this%substructures(i)
      END DO
      DEALLOCATE(this%substructures)
      CALL MOVE_ALLOC(temp, this%substructures)
    END IF
    this%numSubstructures = this%numSubstructures + 1
    this%substructures(this%numSubstructures) = substructure
  END SUBROUTINE MD_Model_AdvProps_AddSubstructure

  SUBROUTINE MD_Model_AdvProps_Clear(this)
    CLASS(MD_Model_AdvProps), INTENT(INOUT) :: this
    IF (ALLOCATED(this%imports)) DEALLOCATE(this%imports)
    IF (ALLOCATED(this%prestresses)) DEALLOCATE(this%prestresses)
    IF (ALLOCATED(this%substructures)) DEALLOCATE(this%substructures)
    this%numImports = 0
    this%numPrestresses = 0
    this%numSubstructures = 0
  END SUBROUTINE MD_Model_AdvProps_Clear

  FUNCTION MD_Model_AdvProps_FindImport(this, name) RESULT(import_prop)
    CLASS(MD_Model_AdvProps), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(ImportProperties), POINTER :: import_prop
    INTEGER(i4) :: i

    NULLIFY(import_prop)
    DO i = 1, this%numImports
      IF (TRIM(this%imports(i)%import_name) == TRIM(name)) THEN
        import_prop => this%imports(i)
        RETURN
      END IF
    END DO
  END FUNCTION MD_Model_AdvProps_FindImport

  FUNCTION MD_Model_AdvProps_FindPrestress(this, name) RESULT(prestress)
    CLASS(MD_Model_AdvProps), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(PrestressProperties), POINTER :: prestress
    INTEGER(i4) :: i

    NULLIFY(prestress)
    DO i = 1, this%numPrestresses
      IF (TRIM(this%prestresses(i)%prestress_name) == TRIM(name)) THEN
        prestress => this%prestresses(i)
        RETURN
      END IF
    END DO
  END FUNCTION MD_Model_AdvProps_FindPrestress

  FUNCTION MD_Model_AdvProps_FindSubstructure(this, name) RESULT(substructure)
    CLASS(MD_Model_AdvProps), INTENT(IN) :: this
    CHARACTER(LEN=*), INTENT(IN) :: name
    TYPE(SubstructureProperties), POINTER :: substructure
    INTEGER(i4) :: i

    NULLIFY(substructure)
    DO i = 1, this%numSubstructures
      IF (TRIM(this%substructures(i)%substructure_name) == TRIM(name)) THEN
        substructure => this%substructures(i)
        RETURN
      END IF
    END DO
  END FUNCTION MD_Model_AdvProps_FindSubstructure

  !=============================================================================
  ! *Arg SIO types for MD_Model_Domain operations
  !=============================================================================

  TYPE, PUBLIC :: MD_Model_Domain_Init_Arg
    TYPE(MD_Model_Desc)               :: desc        ! [INOUT] desc to init
    TYPE(ErrorStatusType)             :: status      ! [OUT] status
  END TYPE MD_Model_Domain_Init_Arg

  TYPE, PUBLIC :: MD_Model_Domain_SetDesc_Arg
    TYPE(MD_Model_Desc)               :: desc        ! [IN] new desc
    TYPE(ErrorStatusType)             :: status      ! [OUT] status
  END TYPE MD_Model_Domain_SetDesc_Arg

  TYPE, PUBLIC :: MD_Model_Domain_Validate_Arg
    LOGICAL                           :: is_valid    ! [OUT] validation result
    TYPE(ErrorStatusType)             :: status      ! [OUT] error status
  END TYPE MD_Model_Domain_Validate_Arg

END MODULE MD_Model_Mgr
