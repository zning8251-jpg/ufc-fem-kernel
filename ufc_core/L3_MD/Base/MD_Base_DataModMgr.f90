!===============================================================================
! MODULE:  MD_Base_DataModMgr
! LAYER:   L3_MD
! DOMAIN:  Model / Base
! ROLE:    _Mgr (data model manager)
! BRIEF:   Unified data model manager: type registration, data access,
!          module framework. Metadata-driven type system with field descriptors.
!===============================================================================
!   Unified data model manager for model definition layer. Merged from three modules:
!   MD_Base_UnifiedType_Mgr (type registration), MD_Base_UDA_Mgr (data access),
!   MD_Base_UMod_Mgr (unified framework). Provides type registration, data object
!   management, and module framework services.
!
! Theory chain:
!   Type registration: Metadata-driven type system with field descriptors (FieldMeta),
!   type metadata (TypeMeta), type classification (Desc/State/Ctx/Algo/Struct).
!   Data access: Unified memory management, data object lifecycle (create, set, get, delete),
!   serialization (save/load). Framework: Module registration, initialization, memory allocation.
!   Ref: Metadata-driven programming, unified memory management patterns.
!
! Logic chain:
!   TypeReg: Init -> RegisterType -> FindType/GetTypeInfo/GetFieldInfo -> ValidateType -> Shutdown.
!   DataAccess: Init -> AllocateDataObj -> FindById/FindByName -> DeallocateDataObj.
!   UniFrame: Init -> RegisterModule -> FindModule/GetModuleInterface -> AllocateModuleMemory ->
!   DeallocateModuleMemory -> Done. Dependency: L3_MD Base -> L1 IF (Error API, Memory Manager).
!
! Computation chain:
!   TypeReg Init: Allocate types array (max_types), set memory_managed flag, clear all types.
!   RegisterType: Validate params, check uniqueness, allocate fields array, calculate type size,
!   store type metadata. FindType: Search by name, update last_access_time. ValidateType:
!   Check type class valid, validate fields. DataAccess Init: Allocate objects array (max_objects).
!   AllocateDataObj: Find free slot, allocate via unified memory or buffer, associate pointers.
!   UniFrame Init: Initialize memory system, type system, allocate adapters array.
!
! Data chain:
!   Input: Type metadata (type_name, type_class, fields), data object params (name, type_id,
!   size_elements), module params (module_name, init_func, cleanup_func).
!   Output: TypeReg (registered types), DataAccess (data objects), UniFrame (registered modules).
!   State: nTypes, nProperties, object_count, adapter_count, memory allocation state.
!
! Data structure:
!   Container path: Ctx (TypeReg, DataAccess, UniFrame).
!   - Desc: TypeMeta (type metadata with fields), FieldMeta (field metadata).
!   - Algo: N/A (management module, algorithms in separate modules).
!   - Ctx: TypeReg (nTypes, types(:)), DataAccess (object_count, objects(:)),
!   UniFrame (adapter_count, adapters(:)).
!   - State: Registration state (nTypes, object_count, adapter_count), memory allocation state.
!   Supporting types: DataObj (data object with buffer/pointers), ModuleAPI (module adapter).
!
! Three-step mapping:
!   Init: Step level (model setup, initialize managers).
!   RegisterType/AllocateDataObj/RegisterModule: Step level (register definitions).
!   FindType/FindById/FindModule: Step level (query).
!   Shutdown/DeallocateDataObj/Done: Step level (cleanup).
!
! Contents (A-Z):
!   Types: DataAccess, DataObj, FieldMeta, ModuleAPI, TypeMeta, TypeReg, UniFrame
!   Functions: CalcDataStride, DataAccess_FindById, DataAccess_FindByName, MAPLOGICALTOIND,
!     Uma_FindModule, Uma_GetModuleInterface, data_is_associated
!   Subroutines: DataAccess_AllocateDataObj, DataAccess_DeallocateDataObj, DataAccess_Init,
!     Uma_AllocateModuleMemory, Uma_DeallocateModuleMemory, Uma_Init, Uma_InitMemorySystem,
!     Uma_InitTypeSystem, Uma_RegisterModule, TypeReg_CalculateTypeSize, TypeReg_ClearAllTypes,
!     TypeReg_FindType, TypeReg_GetFieldInfo, TypeReg_GetTypeInfo, TypeReg_Init, TypeReg_Init_TBP,
!     TypeReg_RegisterType, TypeReg_Shutdown, TypeReg_ValidateFields, TypeReg_ValidateFieldsArray,
!     TypeReg_ValidateType, TypeReg_ValidateTypeParams, data_associate_pointer, data_create_object,
!     data_destroy_object, data_disassociate_pointer, data_get_pointer, data_get_stats,
!     fw_add_mod, fw_done, fw_init, obj_copy_field, obj_del, obj_get, obj_load, obj_new,
!     obj_new_and_set, obj_save, obj_set, type_find, type_flds, type_init, type_reg
!
! Notes:
!   Merged module: UnifiedType (TypeReg), UDA (DataAccess), UMod (UniFrame).
!   Type registration: Metadata-driven type system with five categories (Desc/State/Ctx/Algo/Struct).
!   Data access: Unified memory management, data object lifecycle, serialization.
!   Framework: Module registration and initialization, memory allocation tracking.
!   Logic/Computation chain diagrams: see MD_Base_DataMod_Mgr_Chains.md
!
! Status: CORE | Last verified: 2026-03-02
! Theory: N/A
!===============================================================================
!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)
!>>> UFC_L3_CONTRACT | Model/CONTRACT.md

!>>> UFC_L3_QUENCH | Domain:Model | Role:Mgr | FuncSet:Query,Mutate | HotPath:Yes
!>>> Basis:PLAN/04_Implementation_Roadmap/UFC_Reference_HYPLAS_Program_L3L4L5.md (SingleInst: L3 analysis reads only Desc, no Elem Compute)

MODULE MD_Base_DataModMgr
    USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status, MD_MODEL_STATUS_OK, MD_MODEL_STATUS_INVALID
    USE IF_Mem_Mgr, ONLY: MemoryPool, g_mem_pool, mem_init, mem_alloc, mem_alloc_array, &
         mem_alloc_pointer, mem_free, mem_associate_pointer, mem_is_pointer_associated, &
         mem_disassociate_pointer, IF_Mem_ShutdownPool
    USE MD_Base_MathUtils
    IMPLICIT NONE
    PRIVATE

    ! PUBLIC declarations (A-Z)
    PUBLIC :: CalcDataStride
    PUBLIC :: MD_MODEL_DATA_TYPE_CHAR, MD_MODEL_DATA_TYPE_COMPL, MD_MODEL_DATA_TYPE_INT, MD_MODEL_DATA_TYPE_INT16, MD_MODEL_DATA_TYPE_INT8
    PUBLIC :: MD_MODEL_DATA_TYPE_LOGIC, MD_MODEL_DATA_TYPE_REAL, MD_MODEL_DATA_TYPE_REAL3, MD_MODEL_DATA_TYPE_REAL6
    PUBLIC :: DataAccess, DataAccess_AllocateDataObj, DataAccess_DeallocateDataObj
    PUBLIC :: DataAccess_FindById, DataAccess_FindByName, DataAccess_Init
    PUBLIC :: DataObj
    PUBLIC :: FieldMeta
    PUBLIC :: g_data_mgr, g_framework, g_type_reg
    PUBLIC :: MAPLOGICALTOIND
    PUBLIC :: ModuleAPI
    PUBLIC :: obj_copy_field, obj_del, obj_get, obj_load, obj_new, obj_new_and_set, obj_save, obj_set
    PUBLIC :: MD_MODEL_TYPE_ALGO, MD_MODEL_TYPE_CTX, MD_MODEL_TYPE_DESC, MD_MODEL_TYPE_STATE, MD_MODEL_TYPE_STRUCT
    PUBLIC :: TypeMeta, TypeReg
    PUBLIC :: TypeReg_FindType, TypeReg_GetFieldInfo, TypeReg_GetTypeInfo
    PUBLIC :: TypeReg_Init, TypeReg_RegisterType, TypeReg_Shutdown, TypeReg_ValidateType
    PUBLIC :: type_find, type_flds, type_init, type_reg
    PUBLIC :: Uma_AllocateModuleMemory, Uma_DeallocateModuleMemory
    PUBLIC :: Uma_FindModule, Uma_GetModuleInterface, Uma_Init, Uma_RegisterModule
    PUBLIC :: UniFrame
    PUBLIC :: data_associate_pointer, data_create_object, data_destroy_object
    PUBLIC :: data_disassociate_pointer, data_get_pointer, data_get_stats, data_is_associated
    PUBLIC :: fw_add_mod, fw_done, fw_init

    !> Type classification definition
    INTEGER(i4), PARAMETER :: MD_MODEL_TYPE_DESC = 1
    INTEGER(i4), PARAMETER :: MD_MODEL_TYPE_STATE = 2
    INTEGER(i4), PARAMETER :: MD_MODEL_TYPE_CTX = 3
    INTEGER(i4), PARAMETER :: MD_MODEL_TYPE_ALGO = 4
    INTEGER(i4), PARAMETER :: MD_MODEL_TYPE_STRUCT = 5

    !> Data type definition
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_INT = 1
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_REAL = 2
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_LOGIC = 3
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_CHAR = 4
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_COMPL = 5
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_INT8 = 6
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_INT16 = 7
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_REAL3 = 8
    INTEGER(i4), PARAMETER :: MD_MODEL_DATA_TYPE_REAL6 = 9

    !> Field metadata definition
    TYPE :: FieldMeta
        CHARACTER(len=64) :: field_name = ""
        INTEGER(i4) :: dType = 0
        INTEGER(i4) :: element_len = 1
        INTEGER(i8) :: offset_bytes = 0
        INTEGER(i4) :: rank = 0
        INTEGER(i4) :: dims(7) = 0
        LOGICAL :: is_pointer = .FALSE.
        LOGICAL :: is_allocatable = .FALSE.
        CHARACTER(len=256) :: description = ""
    END TYPE FieldMeta

    !> Type metadata definition
    TYPE :: TypeMeta
        INTEGER(i4) :: type_id = 0
        CHARACTER(len=128) :: type_name = ""
        INTEGER(i4) :: type_class = 0
        INTEGER(i4) :: owner_module = 0
        INTEGER(i4) :: nFields = 0
        INTEGER(i8) :: type_size_bytes = 0
        INTEGER(i4) :: memory_block_id = 0
        TYPE(FieldMeta), ALLOCATABLE :: fields(:)
        LOGICAL :: registered = .FALSE.
        LOGICAL :: validated = .FALSE.
        INTEGER(i8) :: registration_ti = 0
        INTEGER(i8) :: last_access_tim = 0
        CHARACTER(len=512) :: description = ""
    END TYPE TypeMeta

    !> Type registration manager
    TYPE :: TypeReg
        INTEGER(i4) :: nTypes = 0
        INTEGER(i4) :: max_types = 5000
        INTEGER(i4) :: memory_block_id = 0
        TYPE(TypeMeta), ALLOCATABLE :: types(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: memory_managed = .FALSE.
    CONTAINS
        PROCEDURE :: Init => TypeReg_Init_TBP
    END TYPE TypeReg

    TYPE(TypeReg), TARGET, SAVE :: g_type_reg

    !> Data object definition
    TYPE :: DataObj
        INTEGER(i4) :: id = 0
        INTEGER(i4) :: type_id = 0
        INTEGER(i4) :: mem_block_id = 0
        CHARACTER(len=128) :: name = ""
        INTEGER(i8) :: version = 0
        INTEGER(i8) :: created_time = 0
        INTEGER(i8) :: modified_time = 0
        LOGICAL :: dirty = .FALSE.
        LOGICAL :: uses_unified_me = .FALSE.
        BYTE, ALLOCATABLE :: data_buffer(:)
        REAL(wp), POINTER :: real_data(:) => null()
        INTEGER(i4), POINTER :: int_data(:) => null()
        LOGICAL, POINTER :: logical_data(:) => null()
        CHARACTER(len=:), POINTER :: char_data => null()
    END TYPE DataObj

    !> Data access manager
    TYPE :: DataAccess
        INTEGER(i4) :: object_count = 0
        INTEGER(i4) :: max_objects = 100000
        TYPE(DataObj), ALLOCATABLE :: objects(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: uses_unified_me = .FALSE.
    END TYPE DataAccess

    TYPE(DataAccess), TARGET, SAVE :: g_data_mgr

    !> Module adapter definition
    TYPE :: ModuleAPI
        INTEGER(i4) :: module_id = 0
        CHARACTER(len=128) :: module_name = ""
        LOGICAL :: init = .FALSE.
        LOGICAL :: registered = .FALSE.
        INTEGER(i4) :: memory_pool_id = 0
        INTEGER(i4) :: registered_type = 0
        INTEGER(i8) :: total_memory_us = 0
        PROCEDURE(Module_Init_Intf), POINTER :: init_func => null()
        PROCEDURE(Module_Cleanup_Intf), POINTER :: cleanup_func => null()
    END TYPE ModuleAPI

    !> Unified framework manager
    TYPE :: UniFrame
        INTEGER(i4) :: adapter_count = 0
        INTEGER(i4) :: max_adapters = 100
        INTEGER(i4) :: next_module_id = 1
        TYPE(ModuleAPI), ALLOCATABLE :: adapters(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: memory_system_i = .FALSE.
        LOGICAL :: type_system_ini = .FALSE.
    END TYPE UniFrame

    TYPE(UniFrame), TARGET, SAVE :: g_framework

    ABSTRACT INTERFACE
        SUBROUTINE Module_Init_Intf(module_id, status)
            IMPORT :: i4, ErrorStatusType
            INTEGER(i4), INTENT(IN) :: module_id
            TYPE(ErrorStatusType), INTENT(OUT) :: status
        END SUBROUTINE Module_Init_Intf

        SUBROUTINE Module_Cleanup_Intf(module_id, status)
            IMPORT :: i4, ErrorStatusType
            INTEGER(i4), INTENT(IN) :: module_id
            TYPE(ErrorStatusType), INTENT(OUT) :: status
        END SUBROUTINE Module_Cleanup_Intf
    END INTERFACE

CONTAINS

    ! ===================================================================
    ! UnifiedType: TypeReg procedures
    ! ===================================================================
    SUBROUTINE TypeReg_Init(this, use_unified_mem, status)
        CLASS(TypeReg), INTENT(INOUT) :: this
        LOGICAL, INTENT(IN), OPTIONAL :: use_unified_mem
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat
        INTEGER(i8) :: mem_size_bytes

        CALL init_error_status(status)

        IF (this%init) THEN
            status%status_code = MD_MODEL_STATUS_OK
            RETURN
        END IF

        this%memory_managed = .FALSE.
        IF (PRESENT(use_unified_mem)) THEN
            this%memory_managed = use_unified_mem
        END IF

        ALLOCATE(this%types(this%max_types), STAT=alloc_stat)

        IF (this%memory_managed) THEN
            mem_size_bytes = INT(this%max_types, i8) * INT(STORAGE_SIZE(this%types(1))/8, i8)
            CALL mem_alloc_array(g_mem_pool, mem_size_bytes, 0, 1, &
                               "TypeRegistry_Array", this%memory_block_id, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
                DEALLOCATE(this%types)
                RETURN
            END IF
        END IF
        IF (alloc_stat /= 0) THEN
            status%status_code = -1
            status%message = "Failed to allocate type registry"
            RETURN
        END IF

        CALL TypeReg_ClearAllTypes(this)
        this%init = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_Init

    SUBROUTINE TypeReg_Init_TBP(this, status)
        CLASS(TypeReg), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL TypeReg_Init(this, status=status)
    END SUBROUTINE TypeReg_Init_TBP

    SUBROUTINE type_init()
        TYPE(ErrorStatusType) :: status
        CALL init_error_status(status)
        CALL TypeReg_Init(g_type_reg, status=status)
    END SUBROUTINE type_init

    SUBROUTINE type_reg(reg, type_name, type_class, owner_module, fields, nFields, type_id, status)
        TYPE(TypeReg), INTENT(INOUT) :: reg
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        INTEGER(i4), INTENT(IN) :: type_class, owner_module, nFields
        TYPE(FieldMeta), INTENT(IN) :: fields(:)
        INTEGER(i4), INTENT(OUT) :: type_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL TypeReg_RegisterType(reg, type_name, type_class, owner_module, &
                                 fields, nFields, type_id=type_id, status=status)
    END SUBROUTINE type_reg

    SUBROUTINE type_find(reg, type_name, type_id, status)
        TYPE(TypeReg), INTENT(IN) :: reg
        CHARACTER(LEN=*), INTENT(IN) :: type_name
        INTEGER(i4), INTENT(OUT) :: type_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL TypeReg_FindType(reg, type_name, type_id, status)
    END SUBROUTINE type_find

    SUBROUTINE type_flds(reg, type_id, field_name, field_info, status)
        TYPE(TypeReg), INTENT(IN) :: reg
        INTEGER(i4), INTENT(IN) :: type_id
        CHARACTER(LEN=*), INTENT(IN) :: field_name
        TYPE(FieldMeta), INTENT(OUT) :: field_info
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        CALL TypeReg_GetFieldInfo(reg, type_id, field_name, field_info, status)
    END SUBROUTINE type_flds

    SUBROUTINE TypeReg_ClearAllTypes(this)
        CLASS(TypeReg), INTENT(INOUT) :: this
        INTEGER(i4) :: i

        DO i = 1, this%max_types
            this%types(i)%type_id = 0
            this%types(i)%type_name = ""
            this%types(i)%type_class = 0
            this%types(i)%owner_module = 0
            this%types(i)%nFields = 0
            this%types(i)%type_size_bytes = 0_i8
            this%types(i)%memory_block_id = 0
            this%types(i)%registered = .FALSE.
            this%types(i)%validated = .FALSE.
            this%types(i)%registration_ti = 0_i8
            this%types(i)%last_access_tim = 0_i8
            this%types(i)%cfg%description = ""
            IF (ALLOCATED(this%types(i)%fields)) DEALLOCATE(this%types(i)%fields)
        END DO

        this%nTypes = 0
    END SUBROUTINE TypeReg_ClearAllTypes

    SUBROUTINE TypeReg_RegisterType(this, type_name, type_class, owner_module, &
                                   fields, nFields, description, type_id, status)
        CLASS(TypeReg), INTENT(INOUT) :: this
        CHARACTER(len=*), INTENT(IN) :: type_name
        INTEGER(i4), INTENT(IN) :: type_class, owner_module, nFields
        TYPE(FieldMeta), INTENT(IN) :: fields(:)
        CHARACTER(len=*), INTENT(IN), OPTIONAL :: description
        INTEGER(i4), INTENT(OUT) :: type_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat, i
        INTEGER(i8) :: total_size

        CALL init_error_status(status)
        type_id = -1

        CALL TypeReg_ValidateTypeParams(type_name, type_class, owner_module, &
                                       fields, nFields, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        IF (.NOT. this%init) THEN
            status%status_code = -10
            status%message = "Type registry not initialized"
            RETURN
        END IF

        IF (this%nTypes >= this%max_types) THEN
            status%status_code = -11
            status%message = "Type registry full"
            RETURN
        END IF

        CALL TypeReg_FindType(this, type_name, type_id, status)
        IF (status%status_code == MD_MODEL_STATUS_OK) THEN
            status%status_code = -12
            status%message = "Type already registered: " // TRIM(type_name)
            RETURN
        END IF

        DO i = 1, this%max_types
            IF (.NOT. this%types(i)%registered) THEN
                type_id = this%nTypes + 1
                this%nTypes = this%nTypes + 1

                this%types(type_id)%type_id = type_id
                this%types(type_id)%type_name = TRIM(type_name)
                this%types(type_id)%type_class = type_class
                this%types(type_id)%owner_module = owner_module
                this%types(type_id)%nFields = nFields
                this%types(type_id)%registered = .TRUE.
                this%types(type_id)%validated = .FALSE.

                IF (PRESENT(description)) THEN
                    this%types(type_id)%cfg%description = TRIM(description)
                END IF

                ALLOCATE(this%types(type_id)%fields(nFields), STAT=alloc_stat)
                IF (alloc_stat /= 0) THEN
                    status%status_code = -13
                    status%message = "Failed to allocate fields array"
                    RETURN
                END IF
                this%types(type_id)%fields(:) = fields(1:nFields)

                CALL TypeReg_CalculateTypeSize(this%types(type_id), total_size, status)
                IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
                this%types(type_id)%type_size_bytes = total_size

                CALL SYSTEM_CLOCK(this%types(type_id)%registration_ti)
                this%types(type_id)%last_access_tim = this%types(type_id)%registration_ti

                EXIT
            END IF
        END DO

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_RegisterType

    SUBROUTINE TypeReg_FindType(this, type_name, type_id, status)
        CLASS(TypeReg), INTENT(IN) :: this
        CHARACTER(len=*), INTENT(IN) :: type_name
        INTEGER(i4), INTENT(OUT) :: type_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        type_id = -1

        DO i = 1, this%nTypes
            IF (TRIM(this%types(i)%type_name) == TRIM(type_name)) THEN
                type_id = this%types(i)%type_id
                status%status_code = MD_MODEL_STATUS_OK
                this%types(i)%last_access_tim = SYSTEM_CLOCK_COUNT()
                RETURN
            END IF
        END DO

        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Type not found: " // TRIM(type_name)
    END SUBROUTINE TypeReg_FindType

    SUBROUTINE TypeReg_GetTypeInfo(this, type_id, type_info, status)
        CLASS(TypeReg), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: type_id
        TYPE(TypeMeta), INTENT(OUT) :: type_info
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (type_id < 1 .OR. type_id > this%nTypes) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid type ID"
            RETURN
        END IF

        type_info = this%types(type_id)
        this%types(type_id)%last_access_tim = SYSTEM_CLOCK_COUNT()
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_GetTypeInfo

    SUBROUTINE TypeReg_GetFieldInfo(this, type_id, field_name, field_info, status)
        CLASS(TypeReg), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: type_id
        CHARACTER(len=*), INTENT(IN) :: field_name
        TYPE(FieldMeta), INTENT(OUT) :: field_info
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (type_id < 1 .OR. type_id > this%nTypes) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid type ID"
            RETURN
        END IF

        DO i = 1, this%types(type_id)%nFields
            IF (TRIM(this%types(type_id)%fields(i)%field_name) == TRIM(field_name)) THEN
                field_info = this%types(type_id)%fields(i)
                this%types(type_id)%last_access_tim = SYSTEM_CLOCK_COUNT()
                status%status_code = MD_MODEL_STATUS_OK
                RETURN
            END IF
        END DO

        status%status_code = MD_MODEL_STATUS_INVALID
        status%message = "Field not found: " // TRIM(field_name)
    END SUBROUTINE TypeReg_GetFieldInfo

    SUBROUTINE TypeReg_ValidateType(this, type_id, status)
        CLASS(TypeReg), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: type_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (type_id < 1 .OR. type_id > this%nTypes) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid type ID"
            RETURN
        END IF

        IF (.NOT. this%types(type_id)%registered) THEN
            status%status_code = -20
            status%message = "Type not registered"
            RETURN
        END IF

        SELECT CASE (this%types(type_id)%type_class)
        CASE (MD_MODEL_TYPE_DESC, MD_MODEL_TYPE_STATE, MD_MODEL_TYPE_CTX, MD_MODEL_TYPE_ALGO, MD_MODEL_TYPE_STRUCT)
        CASE DEFAULT
            status%status_code = -21
            status%message = "Invalid type class"
            RETURN
        END SELECT

        CALL TypeReg_ValidateFields(this%types(type_id), status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        this%types(type_id)%validated = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_ValidateType

    SUBROUTINE TypeReg_Shutdown(this, status)
        CLASS(TypeReg), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        DO i = 1, this%nTypes
            IF (ALLOCATED(this%types(i)%fields)) THEN
                DEALLOCATE(this%types(i)%fields)
            END IF
        END DO

        IF (ALLOCATED(this%types)) THEN
            DEALLOCATE(this%types)
        END IF

        IF (this%memory_managed .AND. this%memory_block_id /= 0) THEN
            CALL mem_free(g_mem_pool, this%memory_block_id, status)
        END IF

        this%nTypes = 0
        this%init = .FALSE.
        this%memory_managed = .FALSE.

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_Shutdown

    SUBROUTINE TypeReg_ValidateTypeParams(type_name, type_class, owner_module, &
                                         fields, nFields, status)
        CHARACTER(len=*), INTENT(IN) :: type_name
        INTEGER(i4), INTENT(IN) :: type_class, owner_module, nFields
        TYPE(FieldMeta), INTENT(IN) :: fields(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (LEN_TRIM(type_name) == 0) THEN
            status%status_code = -30
            status%message = "Empty type name"
            RETURN
        END IF

        SELECT CASE (type_class)
        CASE (MD_MODEL_TYPE_DESC, MD_MODEL_TYPE_STATE, MD_MODEL_TYPE_CTX, MD_MODEL_TYPE_ALGO, MD_MODEL_TYPE_STRUCT)
        CASE DEFAULT
            status%status_code = -31
            status%message = "Invalid type class"
            RETURN
        END SELECT

        IF (owner_module < 0) THEN
            status%status_code = -32
            status%message = "Invalid owner module"
            RETURN
        END IF

        CALL TypeReg_ValidateFieldsArray(fields, nFields, status)
    END SUBROUTINE TypeReg_ValidateTypeParams

    SUBROUTINE TypeReg_ValidateFieldsArray(fields, nFields, status)
        TYPE(FieldMeta), INTENT(IN) :: fields(:)
        INTEGER(i4), INTENT(IN) :: nFields
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, j

        CALL init_error_status(status)

        IF (nFields < 0) THEN
            status%status_code = -40
            status%message = "Invalid number of fields"
            RETURN
        END IF

        DO i = 1, nFields
            IF (LEN_TRIM(fields(i)%field_name) == 0) THEN
                status%status_code = -41
                status%message = "Empty field name"
                RETURN
            END IF

            DO j = i+1, nFields
                IF (TRIM(fields(i)%field_name) == TRIM(fields(j)%field_name)) THEN
                    status%status_code = -42
                    status%message = "Duplicate field name: " // TRIM(fields(i)%field_name)
                    RETURN
                END IF
            END DO

            SELECT CASE (fields(i)%dType)
            CASE (MD_MODEL_DATA_TYPE_INT, MD_MODEL_DATA_TYPE_REAL, MD_MODEL_DATA_TYPE_LOGIC, MD_MODEL_DATA_TYPE_CHAR, &
                  MD_MODEL_DATA_TYPE_COMPL, MD_MODEL_DATA_TYPE_INT8, MD_MODEL_DATA_TYPE_INT16, &
                  MD_MODEL_DATA_TYPE_REAL3, MD_MODEL_DATA_TYPE_REAL6)
            CASE DEFAULT
                status%status_code = -43
                status%message = "Invalid data type for field: " // TRIM(fields(i)%field_name)
                RETURN
            END SELECT
        END DO
    END SUBROUTINE TypeReg_ValidateFieldsArray

    SUBROUTINE TypeReg_ValidateFields(type_meta, status)
        TYPE(TypeMeta), INTENT(IN) :: type_meta
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL TypeReg_ValidateFieldsArray(type_meta%fields, type_meta%nFields, status)
    END SUBROUTINE TypeReg_ValidateFields

    SUBROUTINE TypeReg_CalculateTypeSize(type_meta, total_size, status)
        TYPE(TypeMeta), INTENT(IN) :: type_meta
        INTEGER(i8), INTENT(OUT) :: total_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i8) :: field_size
        INTEGER(i4) :: i, j

        CALL init_error_status(status)
        total_size = 0_i8

        DO i = 1, type_meta%nFields
            SELECT CASE (type_meta%fields(i)%dType)
            CASE (MD_MODEL_DATA_TYPE_INT)
                field_size = 4_i8
            CASE (MD_MODEL_DATA_TYPE_REAL)
                field_size = 8_i8
            CASE (MD_MODEL_DATA_TYPE_LOGIC)
                field_size = 4_i8
            CASE (MD_MODEL_DATA_TYPE_CHAR)
                field_size = INT(type_meta%fields(i)%element_len, i8)
            CASE (MD_MODEL_DATA_TYPE_COMPL)
                field_size = 16_i8
            CASE (MD_MODEL_DATA_TYPE_INT8)
                field_size = 1_i8
            CASE (MD_MODEL_DATA_TYPE_INT16)
                field_size = 2_i8
            CASE (MD_MODEL_DATA_TYPE_REAL3)
                field_size = 4_i8
            CASE (MD_MODEL_DATA_TYPE_REAL6)
                field_size = 8_i8
            CASE DEFAULT
                status%status_code = -50
                status%message = "Unknown data type for size calculation"
                RETURN
            END SELECT

            IF (type_meta%fields(i)%rank > 0) THEN
                DO j = 1, type_meta%fields(i)%rank
                    field_size = field_size * INT(type_meta%fields(i)%dims(j), i8)
                END DO
            END IF

            total_size = total_size + field_size
        END DO

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE TypeReg_CalculateTypeSize

    ! ===================================================================
    ! UDA: DataAccess procedures
    ! ===================================================================
    SUBROUTINE DataAccess_Init(this, max_objects, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_objects
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat

        CALL init_error_status(status)

        IF (this%init) THEN
            status%status_code = MD_MODEL_STATUS_OK
            RETURN
        END IF

        IF (PRESENT(max_objects)) THEN
            this%max_objects = max_objects
        END IF

        ALLOCATE(this%objects(this%max_objects), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = -1
            status%message = "Failed to allocate objects array"
            RETURN
        END IF

        this%object_count = 0
        this%init = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE DataAccess_Init

    SUBROUTINE DataAccess_AllocateDataObj(this, name, type_id, data_type, size_elements, &
                                          obj_id, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        CHARACTER(len=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(IN) :: type_id, data_type
        INTEGER(i4), INTENT(IN) :: size_elements
        INTEGER(i4), INTENT(OUT) :: obj_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: mem_block_id, i
        INTEGER(i4) :: dims(1)

        CALL init_error_status(status)
        obj_id = -1

        DO i = 1, this%max_objects
            IF (this%objects(i)%cfg%id == 0) THEN
                obj_id = i
                EXIT
            END IF
        END DO

        IF (obj_id == -1) THEN
            status%status_code = -100
            status%message = "No free object slots available"
            RETURN
        END IF

        IF (this%uses_unified_me) THEN
            dims(1) = size_elements
            CALL mem_alloc_pointer(g_mem_pool, data_type, 1, dims, type_id, &
                                   1, name, mem_block_id, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

            this%objects(obj_id)%cfg%id = obj_id
            this%objects(obj_id)%type_id = type_id
            this%objects(obj_id)%mem_block_id = mem_block_id
            this%objects(obj_id)%name = TRIM(name)
            this%objects(obj_id)%uses_unified_me = .TRUE.
            CALL SYSTEM_CLOCK(this%objects(obj_id)%created_time)
            this%objects(obj_id)%version = 1

            SELECT CASE (data_type)
            CASE (1)
                CALL mem_associate_pointer(g_mem_pool, mem_block_id, &
                                         ptr_real=this%objects(obj_id)%real_data, status=status)
            CASE (2)
                CALL mem_associate_pointer(g_mem_pool, mem_block_id, &
                                         ptr_int=this%objects(obj_id)%int_data, status=status)
            CASE (3)
                CALL mem_associate_pointer(g_mem_pool, mem_block_id, &
                                         ptr_logical=this%objects(obj_id)%logical_data, status=status)
            CASE (4)
                ALLOCATE(CHARACTER(len=size_elements)::this%objects(obj_id)%char_data)
            END SELECT

            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        ELSE
            this%objects(obj_id)%cfg%id = obj_id
            this%objects(obj_id)%type_id = type_id
            this%objects(obj_id)%name = TRIM(name)
            this%objects(obj_id)%uses_unified_me = .FALSE.
            CALL SYSTEM_CLOCK(this%objects(obj_id)%created_time)
            this%objects(obj_id)%version = 1

            ALLOCATE(this%objects(obj_id)%data_buffer(size_elements))
        END IF

        this%object_count = this%object_count + 1
        status%status_code = MD_MODEL_STATUS_OK

    END SUBROUTINE DataAccess_AllocateDataObj

    SUBROUTINE DataAccess_DeallocateDataObj(this, obj_id, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: obj_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (obj_id < 1 .OR. obj_id > this%max_objects) THEN
            status%status_code = -200
            status%message = "Invalid object ID"
            RETURN
        END IF

        IF (this%objects(obj_id)%cfg%id == 0) THEN
            status%status_code = -201
            status%message = "Object not allocated"
            RETURN
        END IF

        IF (this%objects(obj_id)%uses_unified_me) THEN
            IF (ASSOCIATED(this%objects(obj_id)%real_data)) THEN
                CALL mem_disassociate_pointer(g_mem_pool, this%objects(obj_id)%mem_block_id, status)
                NULLIFY(this%objects(obj_id)%real_data)
            END IF
            IF (ASSOCIATED(this%objects(obj_id)%int_data)) THEN
                CALL mem_disassociate_pointer(g_mem_pool, this%objects(obj_id)%mem_block_id, status)
                NULLIFY(this%objects(obj_id)%int_data)
            END IF
            IF (ASSOCIATED(this%objects(obj_id)%logical_data)) THEN
                CALL mem_disassociate_pointer(g_mem_pool, this%objects(obj_id)%mem_block_id, status)
                NULLIFY(this%objects(obj_id)%logical_data)
            END IF
            IF (ASSOCIATED(this%objects(obj_id)%char_data)) THEN
                DEALLOCATE(this%objects(obj_id)%char_data)
                NULLIFY(this%objects(obj_id)%char_data)
            END IF

            CALL mem_free(g_mem_pool, this%objects(obj_id)%mem_block_id, status)
        ELSE
            IF (ALLOCATED(this%objects(obj_id)%data_buffer)) THEN
                DEALLOCATE(this%objects(obj_id)%data_buffer)
            END IF
        END IF

        this%objects(obj_id)%cfg%id = 0
        this%objects(obj_id)%type_id = 0
        this%objects(obj_id)%mem_block_id = 0
        this%objects(obj_id)%name = ""
        this%objects(obj_id)%version = 0
        this%objects(obj_id)%dirty = .FALSE.
        this%objects(obj_id)%uses_unified_me = .FALSE.

        this%object_count = this%object_count - 1
        status%status_code = MD_MODEL_STATUS_OK

    END SUBROUTINE DataAccess_DeallocateDataObj

    FUNCTION DataAccess_FindById(this, obj_id) RESULT(obj)
        CLASS(DataAccess), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: obj_id
        TYPE(DataObj), POINTER :: obj

        obj => null()

        IF (obj_id >= 1 .AND. obj_id <= this%max_objects) THEN
            IF (this%objects(obj_id)%cfg%id == obj_id) THEN
                obj => this%objects(obj_id)
            END IF
        END IF

    END FUNCTION DataAccess_FindById

    FUNCTION DataAccess_FindByName(this, name) RESULT(obj)
        CLASS(DataAccess), INTENT(IN) :: this
        CHARACTER(len=*), INTENT(IN) :: name
        TYPE(DataObj), POINTER :: obj

        INTEGER(i4) :: i

        obj => null()

        DO i = 1, this%max_objects
            IF (this%objects(i)%cfg%id /= 0 .AND. &
                TRIM(this%objects(i)%name) == TRIM(name)) THEN
                obj => this%objects(i)
                EXIT
            END IF
        END DO

    END FUNCTION DataAccess_FindByName

    FUNCTION CalcDataStride(dims) RESULT(strides)
        INTEGER(i4), INTENT(IN) :: dims(:)
        INTEGER(i4) :: strides(SIZE(dims))
        INTEGER(i4) :: i, n

        n = SIZE(dims)
        IF (n > 0) THEN
            strides(1) = 1
            DO i = 2, n
                strides(i) = strides(i-1) * dims(i-1)
            END DO
        END IF
    END FUNCTION CalcDataStride

    FUNCTION MAPLOGICALTOIND(coord, strides) RESULT(idx)
        INTEGER(i4), INTENT(IN) :: coord(:)
        INTEGER(i4), INTENT(IN) :: strides(:)
        INTEGER(i4) :: idx
        INTEGER(i4) :: i

        idx = 1
        DO i = 1, SIZE(coord)
            idx = idx + (coord(i) - 1) * strides(i)
        END DO
    END FUNCTION MAPLOGICALTOIND

    SUBROUTINE data_create_object(data_type, size_elements, rank, name, obj_id, status)
        INTEGER(i4), INTENT(IN) :: data_type, rank
        INTEGER(i8), INTENT(IN) :: size_elements
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: name
        INTEGER(i4), INTENT(OUT) :: obj_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(DataObj) :: obj
        CHARACTER(LEN=64) :: obj_name

        CALL init_error_status(status)

        IF (.NOT. g_data_mgr%initialized) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Data manager not initialized"
            RETURN
        END IF

        IF (PRESENT(name)) THEN
            obj_name = TRIM(name)
        ELSE
            obj_name = "data_obj"
        END IF

        obj%type_id = data_type
        obj%version = 1_i8
        CALL SYSTEM_CLOCK(obj%created_time)
        obj%modified_time = obj%created_time
        obj%dirty = .FALSE.

        CALL DataAccess_AllocateDataObj(g_data_mgr, obj_name, data_type, data_type, &
                                        INT(size_elements, i4), obj_id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
    END SUBROUTINE data_create_object

    SUBROUTINE data_destroy_object(obj_id, status)
        INTEGER(i4), INTENT(IN) :: obj_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL DataAccess_DeallocateDataObj(g_data_mgr, obj_id, status)
    END SUBROUTINE data_destroy_object

    SUBROUTINE data_associate_pointer(obj_id, ptr, status)
        INTEGER(i4), INTENT(IN) :: obj_id
        CLASS(*), POINTER, INTENT(INOUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (obj_id < 1 .OR. obj_id > g_data_mgr%max_objects) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid object ID"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%cfg%id == 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Object not allocated"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%uses_unified_me) THEN
            IF (ASSOCIATED(g_data_mgr%objects(obj_id)%real_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer already associated via object%real_data - use that directly"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%int_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer already associated via object%int_data - use that directly"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer already associated via object%logical_data - use that directly"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%char_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer already associated via object%char_data - use that directly"
            ELSE
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "Cannot associate class(*) pointer - use type-specific accessor or mem_associate_pointer with type-specific pointer"
            END IF
        ELSE
            IF (ASSOCIATED(g_data_mgr%objects(obj_id)%real_data) .OR. &
                ASSOCIATED(g_data_mgr%objects(obj_id)%int_data) .OR. &
                ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data) .OR. &
                ASSOCIATED(g_data_mgr%objects(obj_id)%char_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object type-specific fields - use those directly"
            ELSE
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "Direct pointer association not supported for non-unified memory objects"
            END IF
        END IF
    END SUBROUTINE data_associate_pointer

    SUBROUTINE data_disassociate_pointer(obj_id, status)
        INTEGER(i4), INTENT(IN) :: obj_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (obj_id < 1 .OR. obj_id > g_data_mgr%max_objects) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid object ID"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%cfg%id == 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Object not allocated"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%uses_unified_me) THEN
            CALL mem_disassociate_pointer(g_mem_pool, g_data_mgr%objects(obj_id)%mem_block_id, status)
        ELSE
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Pointer disassociation not supported for non-unified memory objects"
        END IF
        NULLIFY(g_data_mgr%objects(obj_id)%real_data)
        NULLIFY(g_data_mgr%objects(obj_id)%int_data)
        NULLIFY(g_data_mgr%objects(obj_id)%logical_data)
        NULLIFY(g_data_mgr%objects(obj_id)%char_data)
    END SUBROUTINE data_disassociate_pointer

    SUBROUTINE data_get_pointer(obj_id, ptr, status)
        INTEGER(i4), INTENT(IN) :: obj_id
        CLASS(*), POINTER, INTENT(OUT) :: ptr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (obj_id < 1 .OR. obj_id > g_data_mgr%max_objects) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Invalid object ID"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%cfg%id == 0) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Object not allocated"
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%uses_unified_me) THEN
            IF (ASSOCIATED(g_data_mgr%objects(obj_id)%real_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%real_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%int_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%int_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%logical_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%char_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%char_data"
            ELSE IF (mem_is_pointer_associated(g_mem_pool, g_data_mgr%objects(obj_id)%mem_block_id)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "Pointer associated in unified memory - use type-specific accessor"
            ELSE
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "Pointer not associated in unified memory system"
            END IF
        ELSE
            IF (ASSOCIATED(g_data_mgr%objects(obj_id)%real_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%real_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%int_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%int_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%logical_data"
            ELSE IF (ASSOCIATED(g_data_mgr%objects(obj_id)%char_data)) THEN
                NULLIFY(ptr)
                status%status_code = MD_MODEL_STATUS_OK
                status%message = "Pointer available via object%char_data"
            ELSE
                status%status_code = MD_MODEL_STATUS_INVALID
                status%message = "No pointer associated for non-unified memory object"
            END IF
        END IF
    END SUBROUTINE data_get_pointer

    FUNCTION data_is_associated(obj_id) RESULT(associated)
        INTEGER(i4), INTENT(IN) :: obj_id
        LOGICAL :: associated

        IF (obj_id < 1 .OR. obj_id > g_data_mgr%max_objects) THEN
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%cfg%id == 0) THEN
            RETURN
        END IF

        IF (g_data_mgr%objects(obj_id)%uses_unified_me) THEN
            associated = mem_is_pointer_associated(g_mem_pool, g_data_mgr%objects(obj_id)%mem_block_id) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%real_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%int_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%char_data)
        ELSE
            associated = ASSOCIATED(g_data_mgr%objects(obj_id)%real_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%int_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%logical_data) .OR. &
                         ASSOCIATED(g_data_mgr%objects(obj_id)%char_data) .OR. &
                         ALLOCATED(g_data_mgr%objects(obj_id)%data_buffer)
        END IF
    END FUNCTION data_is_associated

    SUBROUTINE data_get_stats(total_objects, memory_used, status)
        INTEGER(i4), INTENT(OUT) :: total_objects
        INTEGER(i8), INTENT(OUT) :: memory_used
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (.NOT. g_data_mgr%initialized) THEN
            status%status_code = MD_MODEL_STATUS_INVALID
            status%message = "Data manager not initialized"
            RETURN
        END IF

        total_objects = g_data_mgr%object_count

        memory_used = 0_i8
        DO i = 1, g_data_mgr%object_count
            IF (ALLOCATED(g_data_mgr%objects(i)%data_buffer)) THEN
                memory_used = memory_used + INT(SIZE(g_data_mgr%objects(i)%data_buffer), i8)
            END IF
            IF (g_data_mgr%objects(i)%uses_unified_me .AND. &
                g_data_mgr%objects(i)%mem_block_id > 0) THEN
                IF (ASSOCIATED(g_data_mgr%objects(i)%real_data)) THEN
                    memory_used = memory_used + INT(SIZE(g_data_mgr%objects(i)%real_data), i8) * 8_i8
                ELSE IF (ASSOCIATED(g_data_mgr%objects(i)%int_data)) THEN
                    memory_used = memory_used + INT(SIZE(g_data_mgr%objects(i)%int_data), i8) * 4_i8
                ELSE IF (ASSOCIATED(g_data_mgr%objects(i)%logical_data)) THEN
                    memory_used = memory_used + INT(SIZE(g_data_mgr%objects(i)%logical_data), i8) * 4_i8
                END IF
            END IF
        END DO

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE data_get_stats

    SUBROUTINE obj_new(this, type_id, name, id, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: type_id
        CHARACTER(len=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(OUT) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i8) :: obj_size
        INTEGER(i4) :: alloc_stat, mem_block_id

        CALL init_error_status(status)
        id = -1

        IF (.NOT. this%init) THEN
            status%status_code = -1
            status%message = "Data access manager not initialized"
            RETURN
        END IF

        IF (this%object_count >= this%max_objects) THEN
            status%status_code = -2
            status%message = "Data object limit exceeded"
            RETURN
        END IF

        IF (type_id < 1 .OR. type_id > g_type_reg%nTypes) THEN
            status%status_code = -3
            status%message = "Invalid type ID"
            RETURN
        END IF

        obj_size = g_type_reg%types(type_id)%type_size_bytes

        CALL mem_alloc(g_mem_pool, obj_size, type_id, 0_i4, TRIM(name), mem_block_id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) THEN
            status%message = "Failed to allocate memory for data object"
            RETURN
        END IF

        IF (.NOT. ALLOCATED(this%objects)) THEN
            ALLOCATE(this%objects(this%max_objects), STAT=alloc_stat)
            IF (alloc_stat /= 0) THEN
                status%status_code = -4
                status%message = "Failed to allocate objects array"
                RETURN
            END IF
        END IF

        this%object_count = this%object_count + 1
        id = this%object_count

        this%objects(id)%cfg%id = id
        this%objects(id)%type_id = type_id
        this%objects(id)%mem_block_id = mem_block_id
        this%objects(id)%name = TRIM(name)
        this%objects(id)%version = 0_i8
        CALL SYSTEM_CLOCK(this%objects(id)%created_time)
        this%objects(id)%modified_time = this%objects(id)%created_time
        this%objects(id)%dirty = .FALSE.

        ALLOCATE(this%objects(id)%data_buffer(INT(obj_size)), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = -4
            status%message = "Failed to allocate data buffer"
            RETURN
        END IF

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_new

    SUBROUTINE obj_set(this, id, field_name, data_value, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        CHARACTER(len=*), INTENT(IN) :: field_name
        CLASS(*), INTENT(IN) :: data_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: type_id, field_idx, i
        TYPE(FieldMeta) :: meta
        INTEGER(i8) :: nelem, nbytes, start_pos, end_pos
        INTEGER(i4) :: int_val
        REAL(wp) :: real_val
        LOGICAL :: log_val

        CALL init_error_status(status)

        IF (id < 1 .OR. id > this%object_count) THEN
            status%status_code = -10
            status%message = "Invalid object ID"
            RETURN
        END IF

        type_id = this%objects(id)%type_id
        IF (type_id < 1 .OR. type_id > g_type_reg%nTypes) THEN
            status%status_code = -11
            status%message = "Invalid type ID for object"
            RETURN
        END IF

        field_idx = 0
        DO i = 1, g_type_reg%types(type_id)%nFields
            IF (TRIM(g_type_reg%types(type_id)%fields(i)%field_name) == TRIM(field_name)) THEN
                field_idx = i
                EXIT
            END IF
        END DO

        IF (field_idx == 0) THEN
            status%status_code = -12
            status%message = "Field not found in type definition"
            RETURN
        END IF

        meta = g_type_reg%types(type_id)%fields(field_idx)

        nelem = 1_i8
        IF (meta%rank > 0) THEN
            DO i = 1, meta%rank
                IF (meta%dims(i) <= 0) THEN
                    status%status_code = -13
                    status%message = "Invalid field dimension"
                    RETURN
                END IF
                nelem = nelem * INT(meta%dims(i), i8)
            END DO
        END IF

        nbytes = nelem * INT(meta%element_len, i8)
        start_pos = INT(meta%offset_bytes, i8) + 1_i8
        end_pos = start_pos + nbytes - 1_i8

        IF (.NOT. ALLOCATED(this%objects(id)%data_buffer)) THEN
            status%status_code = -14
            status%message = "Object buffer not allocated"
            RETURN
        END IF

        IF (end_pos > SIZE(this%objects(id)%data_buffer)) THEN
            status%status_code = -15
            status%message = "Field exceeds buffer size"
            RETURN
        END IF

        SELECT TYPE (data_value)
        TYPE IS (INTEGER(i4))
            IF (nbytes >= 4 .AND. meta%rank == 0) THEN
                int_val = data_value
                this%objects(id)%data_buffer(INT(start_pos):INT(start_pos)+3) = TRANSFER(int_val, [BYTE::])
            END IF
        TYPE IS (REAL(wp))
            IF (nbytes >= 8 .AND. meta%rank == 0) THEN
                real_val = data_value
                this%objects(id)%data_buffer(INT(start_pos):INT(start_pos)+7) = TRANSFER(real_val, [BYTE::])
            END IF
        TYPE IS (LOGICAL)
            IF (nbytes >= 1 .AND. meta%rank == 0) THEN
                log_val = data_value
                this%objects(id)%data_buffer(INT(start_pos)) = MERGE(1, 0, log_val)
            END IF
        CLASS DEFAULT
        END SELECT

        this%objects(id)%dirty = .TRUE.
        this%objects(id)%version = this%objects(id)%version + 1_i8
        CALL SYSTEM_CLOCK(this%objects(id)%modified_time)

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_set

    SUBROUTINE obj_get(this, id, field_name, data_value, status)
        CLASS(DataAccess), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: id
        CHARACTER(len=*), INTENT(IN) :: field_name
        CLASS(*), INTENT(OUT) :: data_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: type_id, field_idx, i
        TYPE(FieldMeta) :: meta
        INTEGER(i8) :: nelem, nbytes, start_pos, end_pos
        INTEGER(i4) :: int_val
        REAL(wp) :: real_val
        LOGICAL :: log_val

        CALL init_error_status(status)

        IF (id < 1 .OR. id > this%object_count) THEN
            status%status_code = -10
            status%message = "Invalid object ID"
            RETURN
        END IF

        type_id = this%objects(id)%type_id
        IF (type_id < 1 .OR. type_id > g_type_reg%nTypes) THEN
            status%status_code = -11
            status%message = "Invalid type ID for object"
            RETURN
        END IF

        field_idx = 0
        DO i = 1, g_type_reg%types(type_id)%nFields
            IF (TRIM(g_type_reg%types(type_id)%fields(i)%field_name) == TRIM(field_name)) THEN
                field_idx = i
                EXIT
            END IF
        END DO

        IF (field_idx == 0) THEN
            status%status_code = -12
            status%message = "Field not found in type definition"
            RETURN
        END IF

        meta = g_type_reg%types(type_id)%fields(field_idx)

        nelem = 1_i8
        IF (meta%rank > 0) THEN
            DO i = 1, meta%rank
                IF (meta%dims(i) <= 0) THEN
                    status%status_code = -13
                    RETURN
                END IF
                nelem = nelem * INT(meta%dims(i), i8)
            END DO
        END IF

        nbytes = nelem * INT(meta%element_len, i8)
        start_pos = INT(meta%offset_bytes, i8) + 1_i8
        end_pos = start_pos + nbytes - 1_i8

        IF (.NOT. ALLOCATED(this%objects(id)%data_buffer) .OR. end_pos > SIZE(this%objects(id)%data_buffer)) THEN
            status%status_code = -14
            RETURN
        END IF

        SELECT TYPE (data_value)
        TYPE IS (INTEGER(i4))
            IF (nbytes >= 4 .AND. meta%rank == 0) THEN
                int_val = TRANSFER(this%objects(id)%data_buffer(INT(start_pos):INT(start_pos)+3), 0_i4)
                data_value = int_val
            END IF
        TYPE IS (REAL(wp))
            IF (nbytes >= 8 .AND. meta%rank == 0) THEN
                real_val = TRANSFER(this%objects(id)%data_buffer(INT(start_pos):INT(start_pos)+7), 0.0_wp)
                data_value = real_val
            END IF
        TYPE IS (LOGICAL)
            IF (nbytes >= 1 .AND. meta%dType == 3) THEN
                log_val = (this%objects(id)%data_buffer(INT(start_pos)) /= 0)
                data_value = log_val
            END IF
        CLASS DEFAULT
            status%status_code = -16
            status%message = "Unsupported type for retrieval"
            RETURN
        END SELECT

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_get

    SUBROUTINE obj_del(this, id, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (id < 1 .OR. id > this%object_count) THEN
            status%status_code = -20
            status%message = "Invalid object ID"
            RETURN
        END IF

        CALL mem_free(g_mem_pool, this%objects(id)%mem_block_id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        IF (ALLOCATED(this%objects(id)%data_buffer)) THEN
            DEALLOCATE(this%objects(id)%data_buffer)
        END IF

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_del

    SUBROUTINE obj_save(this, id, buffer, buffer_size, status)
        CLASS(DataAccess), INTENT(IN) :: this
        INTEGER(i4), INTENT(IN) :: id
        BYTE, ALLOCATABLE, INTENT(OUT) :: buffer(:)
        INTEGER(i8), INTENT(OUT) :: buffer_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat

        CALL init_error_status(status)

        IF (id < 1 .OR. id > this%object_count) THEN
            status%status_code = -30
            status%message = "Invalid object ID"
            RETURN
        END IF

        buffer_size = SIZE(this%objects(id)%data_buffer, KIND=i8)
        ALLOCATE(buffer(INT(buffer_size)), STAT=alloc_stat)

        IF (alloc_stat /= 0) THEN
            status%status_code = -31
            status%message = "Failed to allocate serialization buffer"
            RETURN
        END IF

        buffer(:) = this%objects(id)%data_buffer(:)
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_save

    SUBROUTINE obj_load(this, id, buffer, buffer_size, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: id
        BYTE, INTENT(IN) :: buffer(:)
        INTEGER(i8), INTENT(IN) :: buffer_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (id < 1 .OR. id > this%object_count) THEN
            status%status_code = -40
            status%message = "Invalid object ID"
            RETURN
        END IF

        IF (INT(buffer_size, i4) /= SIZE(this%objects(id)%data_buffer)) THEN
            status%status_code = -41
            status%message = "Buffer size mismatch"
            RETURN
        END IF

        this%objects(id)%data_buffer(:) = buffer(:)
        this%objects(id)%dirty = .TRUE.
        this%objects(id)%version = this%objects(id)%version + 1_i8

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_load

    SUBROUTINE obj_new_and_set(this, type_id, name, field_name, data_value, id, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: type_id
        CHARACTER(LEN=*), INTENT(IN) :: name
        CHARACTER(LEN=*), INTENT(IN) :: field_name
        CLASS(*), INTENT(IN) :: data_value
        INTEGER(i4), INTENT(OUT) :: id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL obj_new(this, type_id, name, id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        CALL obj_set(this, id, field_name, data_value, status)
    END SUBROUTINE obj_new_and_set

    SUBROUTINE obj_copy_field(this, src_id, dst_id, meta, status)
        CLASS(DataAccess), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN) :: src_id, dst_id
        TYPE(FieldMeta), INTENT(IN) :: meta
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i8) :: nelem, nbytes, start_pos, end_pos
        INTEGER(i4) :: i

        CALL init_error_status(status)

        IF (src_id < 1 .OR. src_id > this%object_count) THEN
            status%status_code = -50
            status%message = "Invalid source object ID"
            RETURN
        END IF
        IF (dst_id < 1 .OR. dst_id > this%object_count) THEN
            status%status_code = -51
            status%message = "Invalid destination object ID"
            RETURN
        END IF

        nelem = 1_i8
        IF (meta%rank > 0) THEN
            DO i = 1, meta%rank
                IF (meta%dims(i) <= 0) THEN
                    status%status_code = -52
                    RETURN
                END IF
                nelem = nelem * INT(meta%dims(i), i8)
            END DO
        END IF

        nbytes = nelem * INT(meta%element_len, i8)
        start_pos = INT(meta%offset_bytes, i8) + 1_i8
        end_pos   = start_pos + nbytes - 1_i8

        IF (.NOT. ALLOCATED(this%objects(src_id)%data_buffer) .OR. &
            .NOT. ALLOCATED(this%objects(dst_id)%data_buffer)) THEN
            status%status_code = -53
            RETURN
        END IF

        IF (end_pos > SIZE(this%objects(src_id)%data_buffer, KIND=i8) .OR. &
            end_pos > SIZE(this%objects(dst_id)%data_buffer, KIND=i8)) THEN
            status%status_code = -55
            RETURN
        END IF

        this%objects(dst_id)%data_buffer(INT(start_pos):INT(end_pos)) = &
            this%objects(src_id)%data_buffer(INT(start_pos):INT(end_pos))

        this%objects(dst_id)%dirty = .TRUE.
        this%objects(dst_id)%version = this%objects(dst_id)%version + 1_i8
        CALL SYSTEM_CLOCK(this%objects(dst_id)%modified_time)

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE obj_copy_field

    ! ===================================================================
    ! UMod: UniFrame procedures
    ! ===================================================================
    SUBROUTINE Uma_Init(max_adapters, status)
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_adapters
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat

        CALL init_error_status(status)

        IF (g_framework%initialized) THEN
            status%status_code = MD_MODEL_STATUS_OK
            RETURN
        END IF

        IF (PRESENT(max_adapters)) THEN
            g_framework%max_adapters = max_adapters
        END IF

        ALLOCATE(g_framework%adapters(g_framework%max_adapters), STAT=alloc_stat)
        IF (alloc_stat /= 0) THEN
            status%status_code = -1
            status%message = "Failed to allocate adapters array"
            RETURN
        END IF

        g_framework%adapter_count = 0
        g_framework%next_module_id = 1
        g_framework%init = .TRUE.

        CALL Uma_InitMemorySystem(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        CALL Uma_InitTypeSystem(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_Init

    SUBROUTINE Uma_InitMemorySystem(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        g_framework%memory_system_i = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_InitMemorySystem

    SUBROUTINE Uma_InitTypeSystem(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)
        CALL g_type_reg%Init(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
        g_framework%type_system_ini = .TRUE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_InitTypeSystem

    SUBROUTINE Uma_RegisterModule(module_name, init_func, cleanup_func, module_id, status)
        CHARACTER(len=*), INTENT(IN) :: module_name
        PROCEDURE(Module_Init_Intf), OPTIONAL :: init_func
        PROCEDURE(Module_Cleanup_Intf), OPTIONAL :: cleanup_func
        INTEGER(i4), INTENT(OUT) :: module_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: slot

        CALL init_error_status(status)
        module_id = -1

        DO slot = 1, g_framework%max_adapters
            IF (.NOT. g_framework%adapters(slot)%registered) THEN
                module_id = slot
                EXIT
            END IF
        END DO

        IF (module_id == -1) THEN
            status%status_code = -100
            status%message = "No free module slots available"
            RETURN
        END IF

        g_framework%adapters(module_id)%module_id = g_framework%next_module_id
        g_framework%adapters(module_id)%module_name = TRIM(module_name)
        g_framework%adapters(module_id)%registered = .TRUE.
        g_framework%adapters(module_id)%init = .FALSE.
        g_framework%adapters(module_id)%registered_type = 0
        g_framework%adapters(module_id)%total_memory_us = 0_i8

        IF (PRESENT(init_func)) THEN
            g_framework%adapters(module_id)%init_func => init_func
        END IF
        IF (PRESENT(cleanup_func)) THEN
            g_framework%adapters(module_id)%cleanup_func => cleanup_func
        END IF

        g_framework%adapter_count = g_framework%adapter_count + 1
        g_framework%next_module_id = g_framework%next_module_id + 1

        IF (PRESENT(init_func)) THEN
            CALL init_func(g_framework%adapters(module_id)%module_id, status)
            IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN
            g_framework%adapters(module_id)%init = .TRUE.
        END IF

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_RegisterModule

    FUNCTION Uma_FindModule(module_id) RESULT(module)
        INTEGER(i4), INTENT(IN) :: module_id
        TYPE(ModuleAPI), POINTER :: module
        INTEGER(i4) :: i

        module => null()

        DO i = 1, g_framework%max_adapters
            IF (g_framework%adapters(i)%registered .AND. &
                g_framework%adapters(i)%module_id == module_id) THEN
                module => g_framework%adapters(i)
                EXIT
            END IF
        END DO
    END FUNCTION Uma_FindModule

    FUNCTION Uma_GetModuleInterface(module_name) RESULT(module)
        CHARACTER(len=*), INTENT(IN) :: module_name
        TYPE(ModuleAPI), POINTER :: module
        INTEGER(i4) :: i

        module => null()

        DO i = 1, g_framework%max_adapters
            IF (g_framework%adapters(i)%registered .AND. &
                TRIM(g_framework%adapters(i)%module_name) == TRIM(module_name)) THEN
                module => g_framework%adapters(i)
                EXIT
            END IF
        END DO
    END FUNCTION Uma_GetModuleInterface

    SUBROUTINE Uma_AllocateModuleMemory(module_id, data_type, size_elements, name, &
                                       mem_id, status)
        INTEGER(i4), INTENT(IN) :: module_id, data_type, size_elements
        CHARACTER(len=*), INTENT(IN) :: name
        INTEGER(i4), INTENT(OUT) :: mem_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ModuleAPI), POINTER :: module
        INTEGER(i4) :: dims(1)

        CALL init_error_status(status)
        mem_id = -1

        module => Uma_FindModule(module_id)
        IF (.NOT. ASSOCIATED(module)) THEN
            status%status_code = -200
            status%message = "Module not found"
            RETURN
        END IF

        dims(1) = size_elements
        CALL mem_alloc_pointer(g_mem_pool, data_type, 1, dims, 0, module_id, &
                              TRIM(module%module_name) // "_" // TRIM(name), &
                              mem_id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        module%total_memory_us = module%total_memory_us + INT(size_elements, i8)
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_AllocateModuleMemory

    SUBROUTINE Uma_DeallocateModuleMemory(module_id, mem_id, status)
        INTEGER(i4), INTENT(IN) :: module_id, mem_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        TYPE(ModuleAPI), POINTER :: module

        CALL init_error_status(status)

        module => Uma_FindModule(module_id)
        IF (.NOT. ASSOCIATED(module)) THEN
            status%status_code = -300
            status%message = "Module not found"
            RETURN
        END IF

        CALL mem_free(g_mem_pool, mem_id, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE Uma_DeallocateModuleMemory

    SUBROUTINE fw_init(this, memory_capacity, status)
        CLASS(UniFrame), INTENT(INOUT) :: this
        INTEGER(i8), INTENT(IN) :: memory_capacity
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: alloc_stat

        CALL init_error_status(status)

        IF (this%init) THEN
            status%status_code = -1
            status%message = "Framework already initialized"
            RETURN
        END IF

        CALL mem_init(g_mem_pool, memory_capacity, status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        CALL g_type_reg%Init(status)
        IF (status%status_code /= MD_MODEL_STATUS_OK) RETURN

        IF (.NOT. ALLOCATED(this%adapters)) THEN
            ALLOCATE(this%adapters(this%max_adapters), STAT=alloc_stat)
            IF (alloc_stat /= 0) THEN
                status%status_code = -2
                status%message = "Failed to allocate adapters"
                RETURN
            END IF
        END IF

        this%adapter_count = 0
        this%init = .TRUE.

        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE fw_init

    SUBROUTINE fw_add_mod(this, module_name, module_id, status)
        CLASS(UniFrame), INTENT(INOUT) :: this
        CHARACTER(len=*), INTENT(IN) :: module_name
        INTEGER(i4), INTENT(OUT), OPTIONAL :: module_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: local_module_id

        CALL init_error_status(status)
        IF (PRESENT(module_id)) module_id = -1

        IF (.NOT. this%init) THEN
            status%status_code = -10
            status%message = "Framework not initialized"
            RETURN
        END IF

        IF (this%adapter_count >= this%max_adapters) THEN
            status%status_code = -11
            status%message = "Max adapters reached"
            RETURN
        END IF

        this%adapter_count = this%adapter_count + 1
        local_module_id = this%adapter_count

        this%adapters(local_module_id)%module_id = local_module_id
        this%adapters(local_module_id)%module_name = TRIM(module_name)
        this%adapters(local_module_id)%init = .TRUE.
        this%adapters(local_module_id)%registered = .TRUE.

        IF (PRESENT(module_id)) module_id = local_module_id
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE fw_add_mod

    SUBROUTINE fw_done(this, status)
        CLASS(UniFrame), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        IF (.NOT. this%init) THEN
            status%status_code = -20
            status%message = "Framework not initialized"
            RETURN
        END IF

        IF (ALLOCATED(this%adapters)) DEALLOCATE(this%adapters)

        IF (ALLOCATED(g_data_mgr%objects)) DEALLOCATE(g_data_mgr%objects)

        IF (ALLOCATED(g_type_reg%types)) DEALLOCATE(g_type_reg%types)

        CALL IF_Mem_ShutdownPool(status)

        this%init = .FALSE.
        status%status_code = MD_MODEL_STATUS_OK
    END SUBROUTINE fw_done

END MODULE MD_Base_DataModMgr