!===============================================================================
! MODULE:  MD_Base_FieldVarMgr
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Mgr (field variable manager)
! BRIEF:   Unified field and variable registration manager. Field descriptors,
!          variable contexts, memory views, DOF system, model system init.
!===============================================================================
!   Unified field and variable registration manager for model definition layer.
!   Merged from MD_Base_Field_Mgr and MD_Base_Var_Core. Provides field registration,
!   variable context management, memory view management, DOF system operations, and
!   model system initialization. Manages field descriptors, variable contexts, and
!   unified memory views for data access.
!
! Theory chain:
!   Field registration: Metadata-driven field registration with location, data type,
!   rank, dimensions. Variable context: Container for registered fields with capacity
!   management and dynamic expansion. Memory views: Type-safe views (1D/2D, real/integer)
!   for accessing registered fields via unified memory system. DOF system: Degree of
!   freedom system management with equation mapping. Model system: High-level model
!   initialization, DOF building, unified interface setup. Ref: Field registration
!   patterns, memory view patterns, DOF management systems.
!
! Logic chain:
!   InitVars: Initialize variable context with model name and capacity -> Allocate vars
!   array. RegField: Register field with name, location, type, rank, dims -> Check
!   capacity, expand if needed -> Register with data platform -> Allocate memory if
!   persistent/history. FindField: Search context by name -> Return index. GetFieldId:
!   Find field -> Return varName. EnsureFields: Initialize data platform. GetR1D/GetR2D/
!   GetI1D/GetI2D/GetL1D: Find field -> Validate type/rank -> Get data pointer -> Copy
!   to output array. ViewR1D/ViewR2D/ViewI1D/ViewI2D: Find field -> Validate -> Create
!   memory view. RegViewR1D/RegViewI1D/RegViewR2D/RegViewI2D: Register field -> Create
!   view. Core_Init: Initialize data platform. Core_Free: Cleanup. Core_HasErr: Check
!   error state. Dof_Ensure: Ensure DOF system is built. Dof_Build: Build DOF system
!   equation mapping. Model_Init: Initialize model system. Model_BuildDof: Build DOF
!   system for model. Model_SetupUIF: Setup unified interface. Dependency: L3_MD Base ->
!   L1 IF (DataPlatform, Error API, Memory Manager), L3_MD Base (Enums_Core, ObjModel_Core).
!
! Computation chain:
!   InitVars: Validate model name -> Set capacity (default 256 or maxVars) -> Allocate
!   vars array -> Initialize nVars=0. RegField: Validate rank (1-4) and dims -> Check
!   if field exists (FindField) -> Expand capacity if needed (double) -> Create VarDesc
!   -> Register with data platform -> Allocate memory if persistent/history (BASEINFRA_ALLOC
!   or BaseInfra_AllocInt1D/Int2D). FindField: Linear search through vars array -> Return
!   index or 0. GetR1D: FindField -> Validate dType=MD_MODEL_DATA_TYPE_DP, rank=1 -> Get data
!   pointer -> Validate size -> Copy array. ViewR1D: FindField -> Validate -> Create
!   MemView1D_DP with pointer association. RegViewR1D: Call RegField -> Call ViewR1D.
!   Dof_Ensure: Validate nNode > 0 -> Call dof_system%Ensure() -> Check stored flag.
!   Dof_Build: Validate nNode > 0 -> Call dof_system%Build() -> Check stored flag.
!   Model_Init: Call model_system%Init() -> Reset DOF system -> Clear UF view.
!   Model_BuildDof: Validate init -> Call model_system%BuildDof() -> Check stored flag.
!   Model_SetupUIF: Validate stored -> Call model_system%SetupUIF() -> Check dm pointer.
!
! Data chain:
!   Input: Model name (mName), field name, location (MD_MODEL_UF_MV_LOC_*), data type (MD_MODEL_DATA_TYPE_*),
!   rank (1-4), dimensions array, is_history flag, is_persistent flag, DOF system, model system.
!   Output: VarCtx (variable context with registered fields), VarDesc (field descriptors),
!   MemView1D_DP/2D_DP/1D_Int/2D_Int (memory views), DofSys (DOF system with equation mapping),
!   ModelSys (model system with DOF and UF view). State: VarCtx state (nVars, maxVars, vars array),
!   field registration state, DOF system state (stored flag), model system state (init flag).
!
! Data structure:
!   Container path: Base (field/variable manager).
!   - Desc: VarDesc (field descriptor: name, varName, location, dType, rank, dims, is_history,
!   is_persistent).
!   - Algo: Field registration algorithms (RegField), memory view algorithms (ViewR1D, etc.),
!   DOF building algorithms (Dof_Build), model initialization algorithms (Model_Init).
!   - Ctx: VarCtx (variable context: mName, nVars, maxVars, vars(:) array).
!   - State: VarCtx state (nVars, maxVars), DOF system state (stored), model system state (init).
!   Supporting types: MemView1D_DP, MemView2D_DP, MemView1D_Int, MemView2D_Int (from IF_Mem_Mgr),
!   VarCtx, VarDesc, DofSys, ModelSys (from MD_BaseObjModel).
!
! Three-step mapping:
!   InitVars/RegField: Step level (model setup, register fields for model).
!   GetR1D/GetR2D/ViewR1D/ViewR2D: Step level (element evaluation, access field data).
!   Dof_Build/Model_BuildDof: Step level (model setup, build DOF system).
!   Model_SetupUIF: Step level (model setup, setup unified interface).
!
! Contents (A-Z):
!   Functions: Core_HasErr, FindField
!   Interfaces: GetVar, RegViewVar, ViewVar
!   Subroutines: Core_Free, Core_Init, DestroyVars, Dof_Build, Dof_Ensure, EnsureFields,
!     GetFieldId, GetI1D, GetI2D, GetL1D, GetR1D, GetR2D, InitVars, Model_BuildDof,
!     Model_Init, Model_SetupUIF, RegField, RegViewI1D, RegViewI2D, RegViewR1D, RegViewR2D,
!     ViewI1D, ViewI2D, ViewR1D, ViewR2D
!
! Notes:
!   Merged module: MD_Base_Field_Mgr + MD_Base_Var_Core. Field types (UF_FldSys, UF_UFField)
!   are in MD_BaseObjModel. Supports field registration with location (Node, Element,
!   Global, Step, Increment, Contact), data types (DP, INT, CHAR), ranks (1-4), dimensions.
!   Memory views provide type-safe access to registered fields. DOF system management for
!   equation mapping. Model system provides high-level initialization and setup. Dynamic
!   capacity expansion for variable context (doubles when full). Error handling via IF_Err_Brg.
!   Logic/Computation chain diagrams: see MD_Base_FieldVar_Mgr_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_FieldVarMgr
    USE IF_Base_DP, ONLY: MD_MODEL_DATA_TYPE_INT, MD_MODEL_DATA_TYPE_DP, MD_MODEL_DATA_TYPE_CHAR
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID, MD_MODEL_STATUS_MEM_ERRO
    USE IF_Err_Brg, ONLY: uf_set_error, uf_has_error, uf_clear_error, log_debug, log_error
    USE IF_Mem_Mgr, ONLY: MemView1D_DP, MemView2D_DP, MemView1D_Int, MemView2D_Int, &
        BaseInfra_RegisterVarView, BaseInfra_GetDataPtr, BaseInfra_InitDataPlatform, &
        BASEINFRA_ALLOC, BaseInfra_AllocInt1D, BaseInfra_AllocInt2D
    USE IF_Prec_Core, ONLY: i4, i8, wp
    USE MD_Base_Enums, ONLY: MD_MODEL_UF_MV_LOC_Step, MD_MODEL_UF_MV_LOC_INCRE, MD_MODEL_UF_MV_LOC_GLOBA
    USE MD_Base_ObjModel, ONLY: VarCtx, VarDesc, UF_ModelDesc, RT_Model, DofSys, ModelSys
    IMPLICIT NONE
    PRIVATE

    PUBLIC :: Core_Free, Core_HasErr, Core_Init
    PUBLIC :: DestroyVars
    PUBLIC :: Dof_Build, Dof_Ensure
    PUBLIC :: DofSys
    PUBLIC :: EnsureFields
    PUBLIC :: FindField
    PUBLIC :: GetFieldId, GetI1D, GetI2D, GetL1D, GetR1D, GetR2D, GetVar
    PUBLIC :: InitVars
    PUBLIC :: MemView1D_DP, MemView1D_Int, MemView2D_DP, MemView2D_Int
    PUBLIC :: Model_BuildDof, Model_Init, Model_SetupUIF, ModelSys
    PUBLIC :: RegField, RegViewI1D, RegViewI2D, RegViewR1D, RegViewR2D, RegViewVar
    PUBLIC :: RT_Model
    PUBLIC :: UF_ModelDesc
    PUBLIC :: VarCtx, VarDesc
    PUBLIC :: ViewI1D, ViewI2D, ViewR1D, ViewR2D, ViewVar

CONTAINS

    SUBROUTINE InitVars(mName, ctx, maxVars)
        CHARACTER(LEN=*), INTENT(IN)           :: mName
        TYPE(VarCtx),     INTENT(INOUT)        :: ctx
        INTEGER(i4),      INTENT(IN), OPTIONAL :: maxVars
        INTEGER(i4) :: cap, i
        CHARACTER(LEN=256) :: trimmed_name

        trimmed_name = TRIM(ADJUSTL(mName))
        IF (LEN_TRIM(trimmed_name) == 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Model name cannot be empty", "InitVars")
            CALL log_error("InitVars: Empty model name provided")
            RETURN
        END IF

        ctx%mName = trimmed_name

        cap = 256_i4
        IF (PRESENT(maxVars)) THEN
            IF (maxVars < 1) THEN
                CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "maxVars must be >= 1", "InitVars")
                CALL log_error("InitVars: Invalid maxVars provided")
                RETURN
            END IF
            cap = maxVars
        END IF

        IF (ALLOCATED(ctx%vars)) THEN
            IF (ctx%nVars > 0) THEN
                CALL log_debug("InitVars: Deallocating existing Ctx with variables")
            END IF
            DEALLOCATE(ctx%vars)
        END IF

        ALLOCATE(ctx%vars(cap), STAT=i)
        IF (i /= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_MEM_ERRO, "Failed to allocate variable Ctx", "InitVars")
            CALL log_error("InitVars: Memory allocation failed for capacity")
            ctx%maxVars = 0_i4
            ctx%nVars = 0_i4
            RETURN
        END IF

        ctx%maxVars = cap
        ctx%nVars = 0_i4

        CALL log_debug("InitVars: Initialized Ctx for model '" // TRIM(ctx%mName) // "' with capacity")
    END SUBROUTINE InitVars

    SUBROUTINE DestroyVars(ctx)
        TYPE(VarCtx), INTENT(INOUT) :: ctx
        INTEGER(i4) :: n_vars_before, i

        n_vars_before = ctx%nVars

        IF (ALLOCATED(ctx%vars)) THEN
            IF (n_vars_before > 0) THEN
            CALL log_debug("DestroyVars: Destroying Ctx '" // TRIM(ctx%mName) // "' with registered variables")

                DO i = 1, n_vars_before
                    ctx%vars(i)%name = ''
                    ctx%vars(i)%varName = ''
                    ctx%vars(i)%location = 0_i4
                    ctx%vars(i)%dType = 0_i4
                    ctx%vars(i)%rank = 0_i4
                    ctx%vars(i)%dims = 0_i4
                    ctx%vars(i)%is_history = .FALSE.
                    ctx%vars(i)%is_persistent = .FALSE.
                END DO
            END IF
            DEALLOCATE(ctx%vars)
        ELSE IF (n_vars_before > 0) THEN
            CALL log_debug("DestroyVars: Warning - Ctx has nVars > 0 but vars not allocated")
        END IF

        ctx%mName = ''
        ctx%maxVars = 0_i4
        ctx%nVars = 0_i4

        IF (n_vars_before > 0) THEN
            CALL log_debug("DestroyVars: Successfully destroyed Ctx")
        END IF
    END SUBROUTINE DestroyVars

    SUBROUTINE RegField(ctx, name, location, dType, rank, dims, is_history, is_persistent)
        TYPE(VarCtx),     INTENT(INOUT)        :: ctx
        CHARACTER(LEN=*), INTENT(IN)           :: name
        INTEGER(i4),      INTENT(IN)           :: location, dType, rank, dims(:)
        LOGICAL,          INTENT(IN), OPTIONAL :: is_history, is_persistent
        TYPE(VarDesc)         :: desc
        TYPE(ErrorStatusType) :: status
        CHARACTER(LEN=32)     :: scope
        INTEGER(i4)           :: dims4(4), i, n
        LOGICAL               :: hist, persistent
        TYPE(VarDesc), ALLOCATABLE :: tmp_vars(:)
        IF (rank < 1 .OR. rank > 4) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Invalid field rank", "MD_Core")
            RETURN
        END IF
        dims4 = 0
        DO i = 1, rank
            dims4(i) = dims(i)
            IF (dims4(i) <= 0) THEN
                CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Invalid field dimensions", "MD_Core")
                RETURN
            END IF
        END DO
        n = FindField(ctx, name)
        IF (n > 0) THEN
            CALL log_debug("RegField: Field '" // TRIM(name) // "' already registered, skipping")
            RETURN
        END IF
        hist = .false.
        persistent = .true.
        IF (PRESENT(is_history)) hist = is_history
        IF (PRESENT(is_persistent)) persistent = is_persistent
        desc%name = ADJUSTL(name)
        desc%varName = ADJUSTL(name)
        desc%location = location
        desc%dType = dType
        desc%rank = rank
        desc%dims = dims4
        desc%is_history = hist
        desc%is_persistent = persistent

        n = ctx%nVars
        IF (n >= ctx%maxVars) THEN
            IF (ctx%maxVars <= 0) THEN
                CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Variable Ctx not initialized", "RegField")
                CALL log_error("RegField: Ctx must be initialized with InitVars first")
                RETURN
            END IF
            ALLOCATE(tmp_vars(ctx%maxVars * 2), STAT=i)
            IF (i /= 0) THEN
                CALL uf_set_error_status(MD_MODEL_STATUS_MEM_ERRO, "Failed to expand variable Ctx", "RegField")
                CALL log_error("RegField: Memory allocation failed during expansion")
                RETURN
            END IF
            tmp_vars(1:ctx%maxVars) = ctx%vars
            DEALLOCATE(ctx%vars)
            CALL MOVE_ALLOC(tmp_vars, ctx%vars)
            ctx%maxVars = ctx%maxVars * 2
            CALL log_debug("RegField: Expanded Ctx capacity")
        END IF

        ctx%nVars = n + 1_i4
        ctx%vars(n+1_i4) = desc

        scope = "MD_Var"
        CALL BaseInfra_RegisterVarView(scope, desc%varName, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to register var view: " // TRIM(status%message), "RegField")
            ctx%nVars = n
            RETURN
        END IF

        IF (hist .OR. persistent) THEN
            SELECT CASE(dType)
            CASE(MD_MODEL_DATA_TYPE_DP)
                IF (rank == 1) THEN
                    BLOCK
                        REAL(wp), POINTER :: temp_ptr(:)
                        CALL BASEINFRA_ALLOC(desc%varName, INT(dims4(1), i8), temp_ptr, status)
                        NULLIFY(temp_ptr)
                    END BLOCK
                ELSE IF (rank == 2) THEN
                    BLOCK
                        REAL(wp), POINTER :: temp_ptr(:,:)
                        CALL BASEINFRA_ALLOC(desc%varName, INT(dims4(1), i8), INT(dims4(2), i8), temp_ptr, status)
                        NULLIFY(temp_ptr)
                    END BLOCK
                END IF
            CASE(MD_MODEL_DATA_TYPE_INT)
                IF (rank == 1) THEN
                    BLOCK
                        INTEGER(i4), POINTER :: temp_ptr(:)
                        CALL BaseInfra_AllocInt1D(desc%varName, INT(dims4(1), i8), temp_ptr, status)
                        NULLIFY(temp_ptr)
                    END BLOCK
                ELSE IF (rank == 2) THEN
                    BLOCK
                        INTEGER(i4), POINTER :: temp_ptr(:,:)
                        CALL BaseInfra_AllocInt2D(desc%varName, INT(dims4(1), i8), INT(dims4(2), i8), temp_ptr, status)
                        NULLIFY(temp_ptr)
                    END BLOCK
                END IF
            CASE(MD_MODEL_DATA_TYPE_CHAR)
            END SELECT

            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to create data array: " // TRIM(status%message), "RegField")
                CALL log_error("RegField: Failed to create array for field '" // TRIM(desc%name) // "'")
                ctx%nVars = n
                RETURN
            END IF
        END IF

        CALL log_debug("RegField: Registered field '" // TRIM(desc%name) // "'")
    END SUBROUTINE RegField

    FUNCTION FindField(ctx, name) RESULT(idx)
        TYPE(VarCtx),     INTENT(IN) :: ctx
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        INTEGER(i4) :: i
        CHARACTER(LEN=LEN(name)) :: trimmed_name
        trimmed_name = TRIM(name)
        idx = 0
        DO i = 1, ctx%nVars
            IF (TRIM(ctx%vars(i)%name) == trimmed_name) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION FindField

    SUBROUTINE GetFieldId(ctx, name, varName)
        TYPE(VarCtx),     INTENT(IN)  :: ctx
        CHARACTER(LEN=*), INTENT(IN)  :: name
        CHARACTER(LEN=*), INTENT(OUT) :: varName
        INTEGER(i4) :: idx
        idx = FindField(ctx, name)
        IF (idx > 0) THEN
            varName = ctx%vars(idx)%varName
        ELSE
            varName = ''
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
        END IF
    END SUBROUTINE GetFieldId

    SUBROUTINE EnsureFields(ctx)
        TYPE(VarCtx), INTENT(INOUT) :: ctx
        TYPE(ErrorStatusType) :: status

        IF (LEN_TRIM(ctx%mName) == 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Variable Ctx not initialized (empty model name)", "EnsureFields")
            CALL log_error("EnsureFields: Ctx must be initialized with InitVars first")
            RETURN
        END IF

        CALL BaseInfra_InitDataPlatform(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to initialize data platform: " // TRIM(status%message), "EnsureFields")
            CALL log_error("EnsureFields: Data platform initialization failed for model '" // TRIM(ctx%mName) // "'")
            RETURN
        END IF

        CALL log_debug("EnsureFields: Data platform initialized for model '" // TRIM(ctx%mName) // "'")
    END SUBROUTINE EnsureFields

    SUBROUTINE GetR1D(ctx, name, arr)
        TYPE(VarCtx),      INTENT(IN)  :: ctx
        CHARACTER(LEN=*),  INTENT(IN)  :: name
        REAL(wp),          INTENT(OUT) :: arr(:)
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        TYPE(ErrorStatusType) :: status
        REAL(wp), POINTER     :: ptr(:)
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_DP) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected real): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 1) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 1D): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real1d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            RETURN
        END IF
        IF (.NOT. ASSOCIATED(ptr)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Pointer not associated for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (SIZE(arr) /= ctx%vars(idx)%dims(1)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Array size mismatch for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        arr = ptr
    END SUBROUTINE GetR1D

    SUBROUTINE GetR2D(ctx, name, arr)
        TYPE(VarCtx),      INTENT(IN)  :: ctx
        CHARACTER(LEN=*),  INTENT(IN)  :: name
        REAL(wp),          INTENT(OUT) :: arr(:,:)
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        TYPE(ErrorStatusType) :: status
        REAL(wp), POINTER     :: ptr(:,:)
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_DP) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected real): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 2) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 2D): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real2d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            RETURN
        END IF
        IF (.NOT. ASSOCIATED(ptr)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Pointer not associated for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (SIZE(arr, 1) /= ctx%vars(idx)%dims(1) .OR. SIZE(arr, 2) /= ctx%vars(idx)%dims(2)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Array size mismatch for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        arr = ptr
    END SUBROUTINE GetR2D

    SUBROUTINE GetI1D(ctx, name, arr)
        TYPE(VarCtx),      INTENT(IN)  :: ctx
        CHARACTER(LEN=*),  INTENT(IN)  :: name
        INTEGER(i4),       INTENT(OUT) :: arr(:)
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        TYPE(ErrorStatusType) :: status
        INTEGER(i4), POINTER  :: ptr(:)
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_INT) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected integer): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 1) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 1D): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_int1d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            RETURN
        END IF
        IF (.NOT. ASSOCIATED(ptr)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Pointer not associated for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (SIZE(arr) /= ctx%vars(idx)%dims(1)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Array size mismatch for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        arr = ptr
    END SUBROUTINE GetI1D

    SUBROUTINE GetI2D(ctx, name, arr)
        TYPE(VarCtx),      INTENT(IN)  :: ctx
        CHARACTER(LEN=*),  INTENT(IN)  :: name
        INTEGER(i4),       INTENT(OUT) :: arr(:,:)
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        TYPE(ErrorStatusType) :: status
        INTEGER(i4), POINTER  :: ptr(:,:)
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_INT) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected integer): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 2) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 2D): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_int2d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            RETURN
        END IF
        IF (.NOT. ASSOCIATED(ptr)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Pointer not associated for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (SIZE(arr, 1) /= ctx%vars(idx)%dims(1) .OR. SIZE(arr, 2) /= ctx%vars(idx)%dims(2)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Array size mismatch for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        arr = ptr
    END SUBROUTINE GetI2D

    SUBROUTINE GetL1D(ctx, name, arr)
        TYPE(VarCtx),      INTENT(IN)  :: ctx
        CHARACTER(LEN=*),  INTENT(IN)  :: name
        LOGICAL,           INTENT(OUT) :: arr(:)
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        TYPE(ErrorStatusType) :: status
        LOGICAL, POINTER      :: ptr(:)
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 1) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 1D): " // TRIM(name), "MD_Core")
            RETURN
        END IF
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real1d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            RETURN
        END IF
        IF (.NOT. ASSOCIATED(ptr)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Pointer not associated for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        IF (SIZE(arr) /= ctx%vars(idx)%dims(1)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Array size mismatch for field: " // TRIM(name), "MD_Core")
            RETURN
        END IF
        arr = ptr
    END SUBROUTINE GetL1D

    INTERFACE GetVar
        MODULE PROCEDURE GetR1D, GetR2D, GetI1D, GetI2D, GetL1D
    END INTERFACE GetVar

    SUBROUTINE ViewR1D(ctx, name, view)
        TYPE(VarCtx),          INTENT(IN)  :: ctx
        CHARACTER(LEN=*),      INTENT(IN)  :: name
        TYPE(MemView1D_DP), INTENT(OUT) :: view
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        REAL(wp), POINTER     :: ptr(:)
        TYPE(ErrorStatusType) :: status
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_DP) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected real): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 1) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 1D): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data_id = name(1:MIN(LEN(view%data_id), LEN_TRIM(name)))
        view%size = ctx%vars(idx)%dims(1)
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real1d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data => ptr
        view%valid = .true.
    END SUBROUTINE ViewR1D

    SUBROUTINE ViewR2D(ctx, name, view)
        TYPE(VarCtx),          INTENT(IN)  :: ctx
        CHARACTER(LEN=*),      INTENT(IN)  :: name
        TYPE(MemView2D_DP), INTENT(OUT) :: view
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        REAL(wp), POINTER     :: ptr(:,:)
        TYPE(ErrorStatusType) :: status
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_DP) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected real): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 2) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 2D): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data_id = name(1:MIN(LEN(view%data_id), LEN_TRIM(name)))
        view%size1 = ctx%vars(idx)%dims(1)
        view%size2 = ctx%vars(idx)%dims(2)
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_real2d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data => ptr
        view%valid = .true.
    END SUBROUTINE ViewR2D

    SUBROUTINE ViewI1D(ctx, name, view)
        TYPE(VarCtx),           INTENT(IN)  :: ctx
        CHARACTER(LEN=*),       INTENT(IN)  :: name
        TYPE(MemView1D_Int), INTENT(OUT) :: view
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        INTEGER(i4), POINTER  :: ptr(:)
        TYPE(ErrorStatusType) :: status
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_INT) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected integer): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 1) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 1D): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data_id = name(1:MIN(LEN(view%data_id), LEN_TRIM(name)))
        view%size = ctx%vars(idx)%dims(1)
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_int1d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data => ptr
        view%valid = .true.
    END SUBROUTINE ViewI1D

    SUBROUTINE ViewI2D(ctx, name, view)
        TYPE(VarCtx),           INTENT(IN)  :: ctx
        CHARACTER(LEN=*),       INTENT(IN)  :: name
        TYPE(MemView2D_Int), INTENT(OUT) :: view
        INTEGER(i4)           :: idx
        CHARACTER(LEN=256)    :: dp_name
        INTEGER(i4), POINTER  :: ptr(:,:)
        TYPE(ErrorStatusType) :: status
        idx = FindField(ctx, name)
        IF (idx <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field not found: " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%dType /= MD_MODEL_DATA_TYPE_INT) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field type mismatch (expected integer): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        IF (ctx%vars(idx)%rank /= 2) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Field rank mismatch (expected 2D): " // TRIM(name), "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data_id = name(1:MIN(LEN(view%data_id), LEN_TRIM(name)))
        view%size1 = ctx%vars(idx)%dims(1)
        view%size2 = ctx%vars(idx)%dims(2)
        dp_name = ctx%vars(idx)%varName
        CALL BaseInfra_GetDataPtr(dp_name, ptr_int2d=ptr, status=status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Failed to get data pointer", "MD_Core")
            view%valid = .false.
            RETURN
        END IF
        view%data => ptr
        view%valid = .true.
    END SUBROUTINE ViewI2D

    INTERFACE ViewVar
        MODULE PROCEDURE ViewR1D, ViewR2D, ViewI1D, ViewI2D
    END INTERFACE ViewVar

    SUBROUTINE RegViewR1D(ctx, name, location, dim1, view, is_history)
        TYPE(VarCtx),          INTENT(INOUT)        :: ctx
        CHARACTER(LEN=*),      INTENT(IN)           :: name
        INTEGER(i4),           INTENT(IN)           :: location, dim1
        TYPE(MemView1D_DP), INTENT(OUT)          :: view
        LOGICAL,               INTENT(IN), OPTIONAL :: is_history
        INTEGER(i4) :: dims(1)
        LOGICAL     :: hist
        hist = .false.
        IF (PRESENT(is_history)) hist = is_history
        dims(1) = dim1
        CALL RegField(ctx, name, location, MD_MODEL_DATA_TYPE_DP, 1, dims, is_history=hist)
        CALL ViewR1D(ctx, name, view)
    END SUBROUTINE RegViewR1D

    SUBROUTINE RegViewI1D(ctx, name, location, dim1, view, is_history)
        TYPE(VarCtx),           INTENT(INOUT)        :: ctx
        CHARACTER(LEN=*),       INTENT(IN)           :: name
        INTEGER(i4),            INTENT(IN)           :: location, dim1
        TYPE(MemView1D_Int), INTENT(OUT)          :: view
        LOGICAL,                INTENT(IN), OPTIONAL :: is_history
        INTEGER(i4) :: dims(1)
        LOGICAL     :: hist
        hist = .false.
        IF (PRESENT(is_history)) hist = is_history
        dims(1) = dim1
        CALL RegField(ctx, name, location, MD_MODEL_DATA_TYPE_INT, 1, dims, is_history=hist)
        CALL ViewI1D(ctx, name, view)
    END SUBROUTINE RegViewI1D

    SUBROUTINE RegViewR2D(ctx, name, location, dim1, dim2, view, is_history)
        TYPE(VarCtx),          INTENT(INOUT)        :: ctx
        CHARACTER(LEN=*),      INTENT(IN)           :: name
        INTEGER(i4),           INTENT(IN)           :: location, dim1, dim2
        TYPE(MemView2D_DP), INTENT(OUT)          :: view
        LOGICAL,               INTENT(IN), OPTIONAL :: is_history
        INTEGER(i4) :: dims(2)
        LOGICAL     :: hist
        hist = .false.
        IF (PRESENT(is_history)) hist = is_history
        dims(1) = dim1
        dims(2) = dim2
        CALL RegField(ctx, name, location, MD_MODEL_DATA_TYPE_DP, 2, dims, is_history=hist)
        CALL ViewR2D(ctx, name, view)
    END SUBROUTINE RegViewR2D

    SUBROUTINE RegViewI2D(ctx, name, location, dim1, dim2, view, is_history)
        TYPE(VarCtx),           INTENT(INOUT)        :: ctx
        CHARACTER(LEN=*),       INTENT(IN)           :: name
        INTEGER(i4),            INTENT(IN)           :: location, dim1, dim2
        TYPE(MemView2D_Int), INTENT(OUT)          :: view
        LOGICAL,                INTENT(IN), OPTIONAL :: is_history
        INTEGER(i4) :: dims(2)
        LOGICAL     :: hist
        hist = .false.
        IF (PRESENT(is_history)) hist = is_history
        dims(1) = dim1
        dims(2) = dim2
        CALL RegField(ctx, name, location, MD_MODEL_DATA_TYPE_INT, 2, dims, is_history=hist)
        CALL ViewI2D(ctx, name, view)
    END SUBROUTINE RegViewI2D

    INTERFACE RegViewVar
        MODULE PROCEDURE RegViewR1D, RegViewI1D, RegViewR2D, RegViewI2D
    END INTERFACE RegViewVar

    SUBROUTINE Core_Init()
        TYPE(ErrorStatusType) :: status

        IF (uf_has_error()) THEN
            CALL log_debug("Core_Init: Clearing existing error state before initialization")
            CALL uf_clear_error()
        END IF

        CALL BaseInfra_InitDataPlatform(status)

        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, &
                "Failed to initialize data platform: " // TRIM(status%message), "Core_Init")
            CALL log_error("Core_Init: Data platform initialization failed")
            RETURN
        END IF

        CALL log_debug("Core_Init: Data platform initialized successfully")
    END SUBROUTINE Core_Init

    SUBROUTINE Core_Free()
        LOGICAL :: had_error

        had_error = uf_has_error()

        IF (had_error) THEN
            CALL log_debug("Core_Free: Clearing error state before cleanup")
            CALL uf_clear_error()
        END IF

        CALL log_debug("Core_Free: Core module cleanup completed")
    END SUBROUTINE Core_Free

    FUNCTION Core_HasErr() RESULT(res)
        LOGICAL :: res
        res = uf_has_error()
    END FUNCTION Core_HasErr

    SUBROUTINE Dof_Ensure(dof_system)
        TYPE(DofSys), INTENT(INOUT) :: dof_system
        TYPE(ErrorStatusType) :: status

        IF (dof_system%dm%nNode <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system not initialized (nNode <= 0)", "Dof_Ensure")
            CALL log_error("Dof_Ensure: DOF system must be initialized before Ensure")
            RETURN
        END IF

        CALL dof_system%Ensure()

        IF (.NOT. dof_system%stored) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system Ensure failed to build equation mapping", "Dof_Ensure")
            CALL log_error("Dof_Ensure: Failed to build equation mapping")
            RETURN
        END IF

        CALL log_debug("Dof_Ensure: DOF system ensured successfully")
    END SUBROUTINE Dof_Ensure

    SUBROUTINE Dof_Build(dof_system)
        TYPE(DofSys), INTENT(INOUT) :: dof_system
        INTEGER(i4) :: n_eq_before, n_eq_after

        IF (dof_system%dm%nNode <= 0) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system not initialized (nNode <= 0)", "Dof_Build")
            CALL log_error("Dof_Build: DOF system must be initialized before Build")
            RETURN
        END IF

        n_eq_before = dof_system%dm%Neq()

        CALL dof_system%Build()

        n_eq_after = dof_system%dm%Neq()

        IF (.NOT. dof_system%stored) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system Build failed to create equation mapping", "Dof_Build")
            CALL log_error("Dof_Build: Failed to build equation mapping")
            RETURN
        END IF

        CALL log_debug("Dof_Build: DOF system built successfully")
    END SUBROUTINE Dof_Build

    SUBROUTINE Model_Init(model_system)
        TYPE(ModelSys), INTENT(INOUT) :: model_system

        CALL model_system%Init()

        model_system%dof_system%stored = .FALSE.

        IF (ALLOCATED(model_system%uf_view%fields)) THEN
            DEALLOCATE(model_system%uf_view%fields)
        END IF
        model_system%uf_view%nFields = 0_i4
        model_system%uf_view%nEq = 0_i4
        NULLIFY(model_system%uf_view%dm)

        CALL log_debug("Model_Init: Model system initialized (ready for BuildDof/SetupUIF)")
    END SUBROUTINE Model_Init

    SUBROUTINE Model_BuildDof(model_system)
        TYPE(ModelSys), INTENT(INOUT) :: model_system

        IF (.NOT. model_system%init) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "Model system not initialized", "Model_BuildDof")
            CALL log_error("Model_BuildDof: Model system must be initialized first")
            RETURN
        END IF

        CALL model_system%BuildDof()

        IF (.NOT. model_system%dof_system%stored) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system BuildDof failed", "Model_BuildDof")
            CALL log_error("Model_BuildDof: DOF system build failed")
            RETURN
        END IF

        CALL log_debug("Model_BuildDof: DOF system built successfully")
    END SUBROUTINE Model_BuildDof

    SUBROUTINE Model_SetupUIF(model_system)
        TYPE(ModelSys), INTENT(INOUT) :: model_system

        IF (.NOT. model_system%dof_system%stored) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "DOF system not built - call Model_BuildDof first", "Model_SetupUIF")
            CALL log_error("Model_SetupUIF: DOF system must be built before SetupUIF")
            RETURN
        END IF

        CALL model_system%SetupUIF()

        IF (.NOT. ASSOCIATED(model_system%uf_view%dm)) THEN
            CALL uf_set_error_status(MD_MODEL_STATUS_INVALID, "UF view DOF mapping not attached after SetupUIF", "Model_SetupUIF")
            CALL log_error("Model_SetupUIF: Failed to attach DOF mapping to UF view")
            RETURN
        END IF

        CALL log_debug("Model_SetupUIF: Unified interface setup completed")
    END SUBROUTINE Model_SetupUIF

END MODULE MD_Base_FieldVarMgr