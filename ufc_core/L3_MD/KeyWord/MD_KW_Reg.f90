!===================================================================
! MODULE:  MD_KW_Reg
! LAYER:   L3_MD
! DOMAIN:  KeyWord
! ROLE:    _Mgr
! BRIEF:   Central registry for all Abaqus keywords.
!          Data-driven registration with hash-based lookup.
!===================================================================

MODULE MD_KW_Reg
    USE IF_Prec_Core, ONLY: wp, i4, i8
    USE MD_Base_ObjModel, ONLY: BaseRegistry, ErrorStatusType, IF_STATUS_OK, IF_STATUS_INVALID, IF_STATUS_NOT_FOUND
    USE MD_KW_Def
    IMPLICIT NONE
    PRIVATE

    ! ==========================================================================
    ! Module Constants
    ! ==========================================================================
    INTEGER(i4), PARAMETER :: REGISTRY_MAX_KEYWORDS = 512   ! Max keywords capacity
    INTEGER(i4), PARAMETER :: HASH_TABLE_SIZE = 1024        ! Hash table size (power of 2)
    
    ! ==========================================================================
    ! Keyword Registry Type (extends BaseRegistry)
    ! ==========================================================================
    TYPE, PUBLIC, EXTENDS(BaseRegistry) :: MD_KW_Registry_Type
        TYPE(KW_MetadataType), ALLOCATABLE, TARGET :: keywords(:)
        INTEGER(i4), ALLOCATABLE :: hash_table(:)
        INTEGER(i4) :: max_keywords = REGISTRY_MAX_KEYWORDS
        INTEGER(i4) :: hash_table_size = HASH_TABLE_SIZE
    CONTAINS
        ! BaseRegistry interface implementation
        PROCEDURE :: Initialize => MD_KW_Registry_Initialize
        PROCEDURE :: Cleanup => MD_KW_Registry_Cleanup
        PROCEDURE :: Register => MD_KW_Registry_Register
        PROCEDURE :: Unregister => MD_KW_Registry_Unregister
        PROCEDURE :: Lookup => MD_KW_Registry_Lookup
        PROCEDURE :: Exists => MD_KW_Registry_Exists
        PROCEDURE :: GetRegisteredCount => MD_KW_Registry_GetRegisteredCount
        PROCEDURE :: ListRegistered => MD_KW_Registry_ListRegistered
        
        ! Helper methods (private)
        PROCEDURE, PRIVATE :: FindKeywordIndex => MD_KW_Registry_FindKeywordIndex
        PROCEDURE, PRIVATE :: FindKeyword => MD_KW_Registry_FindKeyword
        PROCEDURE, PRIVATE :: RegisterKeyword => MD_KW_Registry_RegisterKeyword
        PROCEDURE, PRIVATE :: RemoveFromHashTable => MD_KW_Registry_RemoveFromHashTable
    END TYPE MD_KW_Registry_Type
    
    ! ==========================================================================
    ! Global Registry Instance (for backward compatibility)
    ! ==========================================================================
    TYPE(MD_KW_Registry_Type), SAVE, PUBLIC :: g_kw_registry
    
    ! ==========================================================================
    ! Legacy storage removed (Phase A: index tree + flat domain)
    ! Single source: g_kw_registry%keywords(:)
    ! ==========================================================================
    
    ! ==========================================================================
    ! Public Interface
    ! ==========================================================================
    PUBLIC :: kw_registry_init           ! Initialize registry
    PUBLIC :: kw_registry_register       ! Register a keyword
    PUBLIC :: kw_registry_find           ! Find keyword by name
    PUBLIC :: kw_registry_exists         ! Check if keyword exists
    PUBLIC :: kw_registry_get_count      ! Get registered count
    PUBLIC :: kw_registry_get_all        ! Get all keywords
    PUBLIC :: kw_registry_add_param      ! Add parameter to keyword
    PUBLIC :: kw_registry_set_data_spec  ! Set data line spec
    PUBLIC :: kw_registry_set_hierarchy  ! Set hierarchy spec
    PUBLIC :: kw_is_initialized          ! Check if initialized

CONTAINS

    ! ==========================================================================
    ! Simple string hash function (djb2 algorithm)
    ! ==========================================================================
    FUNCTION hash_string(str) RESULT(hash)
        CHARACTER(LEN=*), INTENT(IN) :: str
        INTEGER(i4) :: hash
        INTEGER(i4) :: i, c
        INTEGER(i8) :: hash64
        
        hash64 = 5381
        DO i = 1, LEN_TRIM(str)
            c = ICHAR(str(i:i))
            ! Convert to uppercase for case-insensitive hashing
            IF (c >= ICHAR('a') .AND. c <= ICHAR('z')) c = c - 32
            hash64 = MOD(hash64 * 33 + c, INT(2147483647, i8))
        END DO
        hash = INT(MOD(hash64, INT(HASH_TABLE_SIZE, i8)) + 1, i4)
    END FUNCTION hash_string

    ! ==========================================================================
    ! BaseRegistry Interface Implementation
    ! ==========================================================================
    SUBROUTINE MD_KW_Registry_Initialize(this, max_capacity, status)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        INTEGER(i4), INTENT(IN), OPTIONAL :: max_capacity
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: i
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(local_status)
        
        IF (this%initialized) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        IF (PRESENT(max_capacity)) THEN
            this%max_capacity = MAX(1_i4, max_capacity)
            this%max_keywords = this%max_capacity
        END IF
        
        IF (ALLOCATED(this%keywords)) DEALLOCATE(this%keywords)
        IF (ALLOCATED(this%hash_table)) DEALLOCATE(this%hash_table)
        
        ALLOCATE(this%keywords(this%max_keywords))
        ALLOCATE(this%hash_table(this%hash_table_size))
        
        this%hash_table = 0
        this%registered_count = 0_i4
        
        DO i = 1, this%max_keywords
            this%keywords(i)%keyword_name = ""
            this%keywords(i)%is_registered = .FALSE.
        END DO
        
        ! Register all predefined keywords
        ! === Priority 1: Core keywords (~80) ===
        CALL register_model_keywords(this)
        CALL register_mesh_keywords(this)
        CALL register_part_keywords(this)
        CALL register_material_keywords(this)
        CALL register_section_keywords(this)
        CALL register_constraint_keywords(this)
        CALL register_load_keywords(this)
        CALL register_contact_keywords(this)
        CALL register_step_keywords(this)
        CALL register_output_keywords(this)
        CALL register_amplitude_keywords(this)
        CALL register_special_keywords(this)
        
        ! === Priority 2: Extended keywords (~50) ===
        CALL register_advanced_material_keywords(this)
        CALL register_porous_media_keywords(this)
        CALL register_advanced_contact_keywords(this)
        CALL register_advanced_step_keywords(this)
        CALL register_multiphysics_keywords(this)
        CALL register_predefined_field_keywords(this)
        
        ! === Priority 3: Professional extensions (~70) ===
        CALL register_connector_keywords(this)
        CALL register_cohesive_keywords(this)
        CALL register_output_control_keywords(this)
        CALL register_optimization_keywords(this)
        CALL register_explicit_keywords(this)
        CALL register_miscellaneous_keywords(this)
        
        ! === Phase B: Tier 1 Core  (18 keywords for 90% coverage) ===
        CALL register_constraint_advanced_keywords(this)
        CALL register_interaction_keywords(this)
        CALL register_initial_condition_advanced_keywords(this)
        CALL register_restart_keywords(this)
        
        ! === Phase C: Tier 2 Extension (20 keywords for 95% coverage) ===
        CALL register_material_tier2_keywords(this)
        CALL register_section_tier2_keywords(this)
        CALL register_output_tier2_keywords(this)
        CALL register_load_tier2_keywords(this)
        
        ! === Phase C: Tier 3 Extension (30 keywords for 98% coverage) ===
        CALL register_analysis_tier3_keywords(this)
        CALL register_constraint_tier3_keywords(this)
        CALL register_load_tier3_keywords(this)
        CALL register_step_tier3_keywords(this)
        CALL register_special_tier3_keywords(this)
        
        this%initialized = .TRUE.
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE MD_KW_Registry_Initialize

    SUBROUTINE MD_KW_Registry_Cleanup(this, status)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(local_status)
        
        IF (ALLOCATED(this%keywords)) DEALLOCATE(this%keywords)
        IF (ALLOCATED(this%hash_table)) DEALLOCATE(this%hash_table)
        
        this%registered_count = 0_i4
        this%initialized = .FALSE.
        
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE MD_KW_Registry_Cleanup

    SUBROUTINE MD_KW_Registry_Register(this, name, item, status)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        CLASS(*), INTENT(IN), OPTIONAL :: item  ! For BaseRegistry interface compatibility
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: category
        CHARACTER(LEN=256) :: description
        
        ! Default values - actual registration should use the full interface
        category = 0
        description = ""
        
        ! Inline: directly call RegisterKeyword
        CALL this%RegisterKeyword(name, category, description, status)
    END SUBROUTINE MD_KW_Registry_Register

    SUBROUTINE MD_KW_Registry_Unregister(this, name, status)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        TYPE(ErrorStatusType) :: local_status
        INTEGER(i4) :: idx, i
        
        CALL init_error_status(local_status)
        
        IF (.NOT. this%initialized) THEN
            local_status%status_code = IF_STATUS_INVALID
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        ! Find and remove keyword
        idx = this%FindKeywordIndex(name)
        IF (idx == 0) THEN
            local_status%status_code = IF_STATUS_NOT_FOUND
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        ! Remove from hash table
        CALL this%RemoveFromHashTable(name)
        
        ! Shift remaining keywords
        DO i = idx, this%registered_count - 1
            this%keywords(i) = this%keywords(i + 1)
        END DO
        
        this%keywords(this%registered_count)%is_registered = .FALSE.
        this%registered_count = this%registered_count - 1_i4
        
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE MD_KW_Registry_Unregister

    FUNCTION MD_KW_Registry_Lookup(this, name) RESULT(found)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        LOGICAL :: found
        
        TYPE(KW_MetadataType), POINTER :: ptr
        
        found = .FALSE.
        IF (.NOT. this%initialized) RETURN
        
        ptr => this%FindKeyword(name)
        found = ASSOCIATED(ptr)
    END FUNCTION MD_KW_Registry_Lookup

    FUNCTION MD_KW_Registry_Exists(this, name) RESULT(exists)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        LOGICAL :: exists
        
        ! Inline: directly call Lookup
        exists = this%Lookup(name)
    END FUNCTION MD_KW_Registry_Exists

    FUNCTION MD_KW_Registry_GetRegisteredCount(this) RESULT(count)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        INTEGER(i4) :: count
        
        count = this%registered_count
    END FUNCTION MD_KW_Registry_GetRegisteredCount

    SUBROUTINE MD_KW_Registry_ListRegistered(this, names, count, status)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(OUT) :: names(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: i, n
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(local_status)
        
        n = MIN(SIZE(names), this%registered_count)
        count = 0_i4
        
        DO i = 1, this%max_keywords
            IF (this%keywords(i)%is_registered) THEN
                count = count + 1_i4
                IF (count <= n) THEN
                    names(count) = TRIM(this%keywords(i)%keyword_name)
                END IF
            END IF
        END DO
        
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE MD_KW_Registry_ListRegistered

    ! ==========================================================================
    ! Helper Methods (private)
    ! ==========================================================================
    FUNCTION MD_KW_Registry_FindKeywordIndex(this, name) RESULT(idx)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        INTEGER(i4) :: idx
        
        INTEGER(i4) :: i
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name
        
        idx = 0
        upper_name = kw_to_upper(TRIM(name))
        
        DO i = 1, this%registered_count
            IF (TRIM(this%keywords(i)%keyword_name) == TRIM(upper_name)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION MD_KW_Registry_FindKeywordIndex

    FUNCTION MD_KW_Registry_FindKeyword(this, name) RESULT(ptr)
        CLASS(MD_KW_Registry_Type), INTENT(IN) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        TYPE(KW_MetadataType), POINTER :: ptr
        
        INTEGER(i4) :: hash_val, probe, idx, start_probe
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name
        
        NULLIFY(ptr)
        
        IF (.NOT. this%initialized) RETURN
        
        upper_name = kw_to_upper(TRIM(name))
        hash_val = hash_string(upper_name)
        start_probe = hash_val
        probe = hash_val
        
        DO
            idx = this%hash_table(probe)
            IF (idx == 0) EXIT
            
            IF (TRIM(this%keywords(idx)%keyword_name) == TRIM(upper_name)) THEN
                ptr => this%keywords(idx)
                RETURN
            END IF
            
            probe = MOD(probe, this%hash_table_size) + 1
            IF (probe == start_probe) EXIT
        END DO
    END FUNCTION MD_KW_Registry_FindKeyword

    SUBROUTINE MD_KW_Registry_RegisterKeyword(this, keyword_name, category, description, status)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category
        CHARACTER(LEN=*), INTENT(IN) :: description
        TYPE(ErrorStatusType), INTENT(OUT), OPTIONAL :: status
        
        INTEGER(i4) :: hash_val, idx, probe
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name
        TYPE(ErrorStatusType) :: local_status
        
        CALL init_error_status(local_status)
        
        IF (.NOT. this%initialized) THEN
            CALL this%Initialize(status=local_status)
            IF (local_status%status_code /= IF_STATUS_OK) THEN
                IF (PRESENT(status)) status = local_status
                RETURN
            END IF
        END IF
        
        upper_name = kw_to_upper(TRIM(keyword_name))
        
        IF (this%registered_count >= this%max_keywords) THEN
            local_status%status_code = IF_STATUS_INVALID
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        IF (this%Exists(upper_name)) THEN
            IF (PRESENT(status)) status = local_status
            RETURN
        END IF
        
        this%registered_count = this%registered_count + 1
        idx = this%registered_count
        
        this%keywords(idx)%keyword_name = upper_name
        this%keywords(idx)%category = category
        this%keywords(idx)%cfg%description = TRIM(description)
        this%keywords(idx)%is_registered = .TRUE.
        this%keywords(idx)%param_count = 0
        this%keywords(idx)%has_data_lines = .FALSE.
        this%keywords(idx)%requires_end = .FALSE.
        
        hash_val = hash_string(upper_name)
        probe = hash_val
        DO WHILE (this%hash_table(probe) /= 0)
            probe = MOD(probe, this%hash_table_size) + 1
            IF (probe == hash_val) EXIT
        END DO
        this%hash_table(probe) = idx
        
        IF (PRESENT(status)) status = local_status
    END SUBROUTINE RegisterKeyword

    SUBROUTINE MD_KW_Registry_RemoveFromHashTable(this, name)
        CLASS(MD_KW_Registry_Type), INTENT(INOUT) :: this
        CHARACTER(LEN=*), INTENT(IN) :: name
        
        INTEGER(i4) :: hash_val, probe, idx, start_probe
        CHARACTER(LEN=KW_MAX_NAME_LEN) :: upper_name
        
        upper_name = kw_to_upper(TRIM(name))
        hash_val = hash_string(upper_name)
        start_probe = hash_val
        probe = hash_val
        
        DO
            idx = this%hash_table(probe)
            IF (idx == 0) EXIT
            
            IF (TRIM(this%keywords(idx)%keyword_name) == TRIM(upper_name)) THEN
                this%hash_table(probe) = 0
                RETURN
            END IF
            
            probe = MOD(probe, this%hash_table_size) + 1
            IF (probe == start_probe) EXIT
        END DO
    END SUBROUTINE MD_KW_Registry_RemoveFromHashTable

    ! ==========================================================================
    ! Legacy Interface (for backward compatibility)
    ! ==========================================================================
    FUNCTION kw_is_initialized() RESULT(is_init)
        LOGICAL :: is_init
        is_init = g_kw_registry%IsInitialized()
    END FUNCTION kw_is_initialized

    SUBROUTINE kw_registry_init()
        TYPE(ErrorStatusType) :: status
        CALL g_kw_registry%Initialize(status=status)
    END SUBROUTINE kw_registry_init

    ! ==========================================================================
    ! Register a keyword
    ! ==========================================================================
    SUBROUTINE kw_registry_register(keyword_name, category, description, success)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        INTEGER(i4), INTENT(IN) :: category
        CHARACTER(LEN=*), INTENT(IN) :: description
        LOGICAL, INTENT(OUT), OPTIONAL :: success
        
        TYPE(ErrorStatusType) :: status
        
        ! Inline: directly call g_kw_registry%RegisterKeyword
        CALL g_kw_registry%RegisterKeyword(keyword_name, category, description, status)
        
        IF (PRESENT(success)) THEN
            success = (status%status_code == IF_STATUS_OK)
        END IF
    END SUBROUTINE kw_registry_register

    ! ==========================================================================
    ! Find keyword by name
    ! ==========================================================================
    FUNCTION kw_registry_find(keyword_name) RESULT(metadata_ptr)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        TYPE(KW_MetadataType), POINTER :: metadata_ptr
        
        NULLIFY(metadata_ptr)
        
        IF (.NOT. g_kw_registry%IsInitialized()) CALL kw_registry_init()
        
        metadata_ptr => g_kw_registry%FindKeyword(keyword_name)
    END FUNCTION kw_registry_find

    ! ==========================================================================
    ! Check if keyword exists
    ! ==========================================================================
    FUNCTION kw_registry_exists(keyword_name) RESULT(exists)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        LOGICAL :: exists
        
        IF (.NOT. g_kw_registry%IsInitialized()) CALL kw_registry_init()
        ! Inline: directly call g_kw_registry%Exists
        exists = g_kw_registry%Exists(keyword_name)
    END FUNCTION kw_registry_exists

    ! ==========================================================================
    ! Get registered keyword count
    ! ==========================================================================
    FUNCTION kw_registry_get_count() RESULT(count)
        INTEGER(i4) :: count
        count = g_kw_registry%GetRegisteredCount()
    END FUNCTION kw_registry_get_count

    ! ==========================================================================
    ! Get all registered keywords
    ! ==========================================================================
    SUBROUTINE kw_registry_get_all(keywords, count)
        TYPE(KW_MetadataType), INTENT(OUT) :: keywords(:)
        INTEGER(i4), INTENT(OUT) :: count
        INTEGER(i4) :: i, n
        
        IF (.NOT. g_kw_registry%IsInitialized()) CALL kw_registry_init()
        n = MIN(SIZE(keywords), g_kw_registry%GetRegisteredCount())
        DO i = 1, n
            keywords(i) = g_kw_registry%keywords(i)
        END DO
        count = n
    END SUBROUTINE kw_registry_get_all

    ! ==========================================================================
    ! Add parameter definition to a keyword
    ! ==========================================================================
    SUBROUTINE kw_registry_add_param(keyword_name, param_name, param_type, &
                                      is_required, default_val, description, success)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        CHARACTER(LEN=*), INTENT(IN) :: param_name
        INTEGER(i4), INTENT(IN) :: param_type
        LOGICAL, INTENT(IN) :: is_required
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: default_val
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: description
        LOGICAL, INTENT(OUT), OPTIONAL :: success
        
        TYPE(KW_MetadataType), POINTER :: kw
        INTEGER(i4) :: idx
        
        IF (PRESENT(success)) success = .FALSE.
        
        kw => kw_registry_find(keyword_name)
        IF (.NOT. ASSOCIATED(kw)) RETURN
        
        IF (kw%param_count >= KW_MAX_PARAMS) RETURN
        
        idx = kw%param_count + 1
        kw%param_count = idx
        
        kw%params(idx)%name = kw_to_upper(TRIM(param_name))
        kw%params(idx)%param_type = param_type
        kw%params(idx)%is_required = is_required
        IF (PRESENT(default_val)) kw%params(idx)%default_value = TRIM(default_val)
        IF (PRESENT(description)) kw%params(idx)%cfg%description = TRIM(description)
        
        IF (PRESENT(success)) success = .TRUE.
    END SUBROUTINE kw_registry_add_param

    ! ==========================================================================
    ! Set data line specification
    ! ==========================================================================
    SUBROUTINE kw_registry_set_data_spec(keyword_name, has_data, min_lines, max_lines, cols)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        LOGICAL, INTENT(IN) :: has_data
        INTEGER(i4), INTENT(IN), OPTIONAL :: min_lines, max_lines, cols
        
        TYPE(KW_MetadataType), POINTER :: kw
        
        kw => kw_registry_find(keyword_name)
        IF (.NOT. ASSOCIATED(kw)) RETURN
        
        kw%has_data_lines = has_data
        IF (PRESENT(min_lines)) kw%min_data_lines = min_lines
        IF (PRESENT(max_lines)) kw%max_data_lines = max_lines
        IF (PRESENT(cols)) kw%data_cols_per_line = cols
    END SUBROUTINE kw_registry_set_data_spec

    ! ==========================================================================
    ! Set hierarchy specification
    ! ==========================================================================
    SUBROUTINE kw_registry_set_hierarchy(keyword_name, requires_end, end_keyword, &
                                          valid_parents)
        CHARACTER(LEN=*), INTENT(IN) :: keyword_name
        LOGICAL, INTENT(IN), OPTIONAL :: requires_end
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: end_keyword
        CHARACTER(LEN=*), INTENT(IN), OPTIONAL :: valid_parents(:)
        
        TYPE(KW_MetadataType), POINTER :: kw
        INTEGER(i4) :: i, n
        
        kw => kw_registry_find(keyword_name)
        IF (.NOT. ASSOCIATED(kw)) RETURN
        
        IF (PRESENT(requires_end)) kw%requires_end = requires_end
        IF (PRESENT(end_keyword)) kw%end_keyword = TRIM(end_keyword)
        IF (PRESENT(valid_parents)) THEN
            n = MIN(SIZE(valid_parents), KW_MAX_CHILDREN)
            kw%valid_parent_count = n
            DO i = 1, n
                kw%valid_parents(i) = kw_to_upper(TRIM(valid_parents(i)))
            END DO
        END IF
    END SUBROUTINE kw_registry_set_hierarchy

    ! ==========================================================================
    ! INTERNAL: Register Model Definition Keywords
    ! ==========================================================================
    SUBROUTINE register_model_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        CALL reg_ptr%RegisterKeyword("HEADING", KW_CAT_MODEL, "Model title and description", status)
        CALL kw_registry_set_data_spec("HEADING", .TRUE., min_lines=0, max_lines=0)
        
        CALL reg_ptr%RegisterKeyword("PREPRINT", KW_CAT_MODEL, "Control printed output", status)
        CALL kw_registry_add_param("PREPRINT", "ECHO", PARAM_TYPE_ENUM, .FALSE., "NO")
        CALL kw_registry_add_param("PREPRINT", "MODEL", PARAM_TYPE_ENUM, .FALSE., "NO")
        CALL kw_registry_add_param("PREPRINT", "HISTORY", PARAM_TYPE_ENUM, .FALSE., "NO")
        CALL kw_registry_add_param("PREPRINT", "CONTACT", PARAM_TYPE_ENUM, .FALSE., "NO")
    END SUBROUTINE register_model_keywords

    ! ==========================================================================
    ! INTERNAL: Register Mesh Keywords
    ! ==========================================================================
    SUBROUTINE register_mesh_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *NODE
        CALL reg_ptr%RegisterKeyword("NODE", KW_CAT_MESH, "Define nodes", status)
        CALL kw_registry_add_param("NODE", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NODE", "SYSTEM", PARAM_TYPE_ENUM, .FALSE., "R")
        CALL kw_registry_add_param("NODE", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("NODE", .TRUE., cols=4)  ! id, x, y, z
        
        ! *ELEMENT
        CALL kw_registry_register("ELEMENT", KW_CAT_MESH, "Define elements")
        CALL kw_registry_add_param("ELEMENT", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_add_param("ELEMENT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("ELEMENT", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("ELEMENT", .TRUE.)
        
        ! *NSET
        CALL kw_registry_register("NSET", KW_CAT_MESH, "Define node set")
        CALL kw_registry_add_param("NSET", "NSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("NSET", "GENERATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("NSET", "INSTANCE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NSET", "INTERNAL", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("NSET", .TRUE.)
        
        ! *ELSET
        CALL kw_registry_register("ELSET", KW_CAT_MESH, "Define element set")
        CALL kw_registry_add_param("ELSET", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ELSET", "GENERATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("ELSET", "INSTANCE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("ELSET", "INTERNAL", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("ELSET", .TRUE.)
        
        ! *SURFACE
        CALL kw_registry_register("SURFACE", KW_CAT_MESH, "Define surface")
        CALL kw_registry_add_param("SURFACE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SURFACE", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ELEMENT")
        CALL kw_registry_add_param("SURFACE", "COMBINE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SURFACE", .TRUE.)
        
        ! *ORIENTATION
        CALL kw_registry_register("ORIENTATION", KW_CAT_MESH, "Define material orientation")
        CALL kw_registry_add_param("ORIENTATION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ORIENTATION", "SYSTEM", PARAM_TYPE_ENUM, .FALSE., "RECTANGULAR")
        CALL kw_registry_add_param("ORIENTATION", "LOCAL DIRECTIONS", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("ORIENTATION", .TRUE., cols=6)
        
        ! *NGEN
        CALL kw_registry_register("NGEN", KW_CAT_MESH, "Generate nodes")
        CALL kw_registry_add_param("NGEN", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NGEN", "LINE", PARAM_TYPE_ENUM, .FALSE., "L")
        CALL kw_registry_set_data_spec("NGEN", .TRUE.)
        
        ! *ELGEN
        CALL kw_registry_register("ELGEN", KW_CAT_MESH, "Generate elements")
        CALL kw_registry_add_param("ELGEN", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("ELGEN", .TRUE.)
        
        ! *NCOPY
        CALL kw_registry_register("NCOPY", KW_CAT_MESH, "Copy nodes")
        CALL kw_registry_add_param("NCOPY", "CHANGE NUMBER", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("NCOPY", "OLD SET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("NCOPY", "NEW SET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NCOPY", "SHIFT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("NCOPY", .TRUE.)
        
        ! *ELCOPY
        CALL kw_registry_register("ELCOPY", KW_CAT_MESH, "Copy elements")
        CALL kw_registry_add_param("ELCOPY", "ELEMENT SHIFT", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("ELCOPY", "NODE SHIFT", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("ELCOPY", "OLD SET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ELCOPY", "NEW SET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("ELCOPY", .FALSE.)
    END SUBROUTINE register_mesh_keywords

    ! ==========================================================================
    ! INTERNAL: Register Part/Instance/Assembly Keywords
    ! ==========================================================================
    SUBROUTINE register_part_keywords()
        ! *PART
        CALL kw_registry_register("PART", KW_CAT_PART, "Begin part definition")
        CALL kw_registry_add_param("PART", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_hierarchy("PART", requires_end=.TRUE., end_keyword="END PART")
        
        ! *END PART
        CALL kw_registry_register("END PART", KW_CAT_END, "End part definition")
        
        ! *INSTANCE
        CALL kw_registry_register("INSTANCE", KW_CAT_PART, "Create part instance")
        CALL kw_registry_add_param("INSTANCE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("INSTANCE", "PART", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("INSTANCE", .TRUE., min_lines=0, max_lines=2)
        CALL kw_registry_set_hierarchy("INSTANCE", requires_end=.TRUE., end_keyword="END INSTANCE")
        
        ! *END INSTANCE
        CALL kw_registry_register("END INSTANCE", KW_CAT_END, "End instance definition")
        
        ! *ASSEMBLY
        CALL kw_registry_register("ASSEMBLY", KW_CAT_PART, "Begin assembly definition")
        CALL kw_registry_add_param("ASSEMBLY", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_hierarchy("ASSEMBLY", requires_end=.TRUE., end_keyword="END ASSEMBLY")
        
        ! *END ASSEMBLY
        CALL kw_registry_register("END ASSEMBLY", KW_CAT_END, "End assembly definition")

        ! *TRANSLATE
        CALL kw_registry_register("TRANSLATE", KW_CAT_PART, "Translate instance")
        CALL kw_registry_add_param("TRANSLATE", "INSTANCE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("TRANSLATE", .TRUE., min_lines=1, max_lines=1)

        ! *NODE FROM NSET (Custom/Pseudo)
        CALL kw_registry_register("NODE FROM NSET", KW_CAT_MESH, "Import nodes from set (Custom)")
        CALL kw_registry_set_data_spec("NODE FROM NSET", .FALSE.)

        ! *ELEMENT FROM ELSET (Custom/Pseudo)
        CALL kw_registry_register("ELEMENT FROM ELSET", KW_CAT_MESH, "Import elements from set (Custom)")
        CALL kw_registry_set_data_spec("ELEMENT FROM ELSET", .FALSE.)
    END SUBROUTINE register_part_keywords

    ! ==========================================================================
    ! INTERNAL: Register Material Keywords
    ! ==========================================================================
    SUBROUTINE register_material_keywords()
        ! *MATERIAL
        CALL kw_registry_register("MATERIAL", KW_CAT_MATERIAL, "Begin material definition")
        CALL kw_registry_add_param("MATERIAL", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        
        ! *ELASTIC
        CALL kw_registry_register("ELASTIC", KW_CAT_MATERIAL, "Linear elastic properties")
        CALL kw_registry_add_param("ELASTIC", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ISOTROPIC")
        CALL kw_registry_add_param("ELASTIC", "MODULI", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("ELASTIC", .TRUE., cols=2)  ! E, nu
        
        ! *PLASTIC
        CALL kw_registry_register("PLASTIC", KW_CAT_MATERIAL, "Plastic properties")
        CALL kw_registry_add_param("PLASTIC", "HARDENING", PARAM_TYPE_ENUM, .FALSE., "ISOTROPIC")
        CALL kw_registry_add_param("PLASTIC", "RATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("PLASTIC", "DATATYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("PLASTIC", .TRUE., cols=2)  ! stress, strain
        
        ! *DENSITY
        CALL kw_registry_register("DENSITY", KW_CAT_MATERIAL, "Mass density")
        CALL kw_registry_set_data_spec("DENSITY", .TRUE., cols=1)
        
        ! *CONDUCTIVITY
        CALL kw_registry_register("CONDUCTIVITY", KW_CAT_MATERIAL, "Thermal conductivity")
        CALL kw_registry_add_param("CONDUCTIVITY", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ISO")
        CALL kw_registry_set_data_spec("CONDUCTIVITY", .TRUE.)
        
        ! *SPECIFIC HEAT
        CALL kw_registry_register("SPECIFIC HEAT", KW_CAT_MATERIAL, "Specific heat capacity")
        CALL kw_registry_set_data_spec("SPECIFIC HEAT", .TRUE., cols=1)
        
        ! *EXPANSION
        CALL kw_registry_register("EXPANSION", KW_CAT_MATERIAL, "Thermal expansion")
        CALL kw_registry_add_param("EXPANSION", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ISO")
        CALL kw_registry_add_param("EXPANSION", "ZERO", PARAM_TYPE_REAL, .FALSE.)
        ! Data: ISO (alpha,T[,...]); ORTHO (a11,a22,a33,T); ANISO (6 Voigt alphas)
        CALL kw_registry_set_data_spec("EXPANSION", .TRUE.)

        ! *THERMO ELASTIC (mat_id 108) �?aliases for lexer/token forms
        CALL kw_registry_register("THERMO ELASTIC", KW_CAT_MATERIAL, "Thermo-elastic isotropic (E, nu, alpha, T_ref)")
        CALL kw_registry_set_data_spec("THERMO ELASTIC", .TRUE., cols=4)
        CALL kw_registry_register("THERMOELASTIC", KW_CAT_MATERIAL, "Alias of *THERMO ELASTIC")
        CALL kw_registry_set_data_spec("THERMOELASTIC", .TRUE., cols=4)

        CALL kw_registry_register("PIEZO ELASTIC", KW_CAT_MATERIAL, "Piezoelectric elastic (10 property values)")
        CALL kw_registry_set_data_spec("PIEZO ELASTIC", .TRUE., cols=10)
        CALL kw_registry_register("PIEZOELASTIC", KW_CAT_MATERIAL, "Alias of *PIEZO ELASTIC")
        CALL kw_registry_set_data_spec("PIEZOELASTIC", .TRUE., cols=10)

        CALL kw_registry_register("THERMO ELEC ELASTIC", KW_CAT_MATERIAL, "Thermo-piezo-elastic (12 property values)")
        CALL kw_registry_set_data_spec("THERMO ELEC ELASTIC", .TRUE., cols=12)
        CALL kw_registry_register("THERMOELECELASTIC", KW_CAT_MATERIAL, "Alias of *THERMO ELEC ELASTIC")
        CALL kw_registry_set_data_spec("THERMOELECELASTIC", .TRUE., cols=12)
        CALL kw_registry_register("THERMO PIEZO ELASTIC", KW_CAT_MATERIAL, "Alias of *THERMO ELEC ELASTIC")
        CALL kw_registry_set_data_spec("THERMO PIEZO ELASTIC", .TRUE., cols=12)
        CALL kw_registry_register("THERMOPIEZOELASTIC", KW_CAT_MATERIAL, "Alias of *THERMO ELEC ELASTIC")
        CALL kw_registry_set_data_spec("THERMOPIEZOELASTIC", .TRUE., cols=12)
        
        ! *UF-THERMAL (UniField thermal coupling options)
        CALL kw_registry_register("UF-THERMAL", KW_CAT_MATERIAL, "UniField thermal coupling options")
        CALL kw_registry_add_param("UF-THERMAL", "THERMEXP", PARAM_TYPE_ENUM, .FALSE., "ON")
        CALL kw_registry_set_data_spec("UF-THERMAL", .FALSE.)
        
        ! *UF-PORO (UniField poroelastic coupling options)
        CALL kw_registry_register("UF-PORO", KW_CAT_MATERIAL, "UniField poroelastic coupling options")
        CALL kw_registry_add_param("UF-PORO", "VOLRATE", PARAM_TYPE_ENUM, .FALSE., "ON")
        ! Data line: alpha_b, k_hyd, S_s, rho_fluid, cp_fluid
        CALL kw_registry_set_data_spec("UF-PORO", .TRUE., cols=5)
        
        ! *UF-PORO-2PH (Two-phase / variably saturated pore-flow options)
        CALL kw_registry_register("UF-PORO-2PH", KW_CAT_MATERIAL, "Two-phase pore-flow constitutive options")
        CALL kw_registry_add_param("UF-PORO-2PH", "MODEL", PARAM_TYPE_ENUM, .FALSE., "COREY")
        ! Data line (MODEL=COREY): Swr, Snr, n_w, phi, alpha
        ! Data line (MODEL=VANG):  alpha, n, phi, Swr, Snr, m, l
        CALL kw_registry_set_data_spec("UF-PORO-2PH", .TRUE.)
        
        ! *HYPERELASTIC
        CALL kw_registry_register("HYPERELASTIC", KW_CAT_MATERIAL, "Hyperelastic material")
        CALL kw_registry_add_param("HYPERELASTIC", "MOONEY-RIVLIN", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("HYPERELASTIC", "NEO HOOKE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("HYPERELASTIC", "OGDEN", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("HYPERELASTIC", "POLYNOMIAL", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("HYPERELASTIC", "N", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("HYPERELASTIC", .TRUE.)
        
        ! *VISCOELASTIC
        CALL kw_registry_register("VISCOELASTIC", KW_CAT_MATERIAL, "Viscoelastic properties")
        CALL kw_registry_add_param("VISCOELASTIC", "TIME", PARAM_TYPE_ENUM, .FALSE., "PRONY")
        CALL kw_registry_add_param("VISCOELASTIC", "FREQUENCY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("VISCOELASTIC", .TRUE.)
        
        ! *CREEP
        CALL kw_registry_register("CREEP", KW_CAT_MATERIAL, "Creep properties")
        CALL kw_registry_add_param("CREEP", "LAW", PARAM_TYPE_ENUM, .FALSE., "STRAIN")
        CALL kw_registry_set_data_spec("CREEP", .TRUE.)
        
        ! *DAMPING
        CALL kw_registry_register("DAMPING", KW_CAT_MATERIAL, "Material damping")
        CALL kw_registry_add_param("DAMPING", "ALPHA", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("DAMPING", "BETA", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("DAMPING", "COMPOSITE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("DAMPING", .FALSE.)
        
        ! *DEPVAR
        CALL kw_registry_register("DEPVAR", KW_CAT_MATERIAL, "Solution-dependent state variables")
        CALL kw_registry_add_param("DEPVAR", "DELETE", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("DEPVAR", .TRUE., cols=1)
        
        ! *USER MATERIAL
        CALL kw_registry_register("USER MATERIAL", KW_CAT_MATERIAL, "User-defined material (UMAT)")
        CALL kw_registry_add_param("USER MATERIAL", "CONSTANTS", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("USER MATERIAL", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("USER MATERIAL", "UNSYMM", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("USER MATERIAL", .TRUE.)
    END SUBROUTINE register_material_keywords

    ! ==========================================================================
    ! INTERNAL: Register Section Keywords
    ! ==========================================================================
    SUBROUTINE register_section_keywords()
        ! *SOLID SECTION
        CALL kw_registry_register("SOLID SECTION", KW_CAT_SECTION, "Solid element section")
        CALL kw_registry_add_param("SOLID SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SOLID SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SOLID SECTION", "ORIENTATION", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("SOLID SECTION", "CONTROLS", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SOLID SECTION", .TRUE., min_lines=0, max_lines=1)
        
        ! *SHELL SECTION
        CALL kw_registry_register("SHELL SECTION", KW_CAT_SECTION, "Shell element section")
        CALL kw_registry_add_param("SHELL SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SHELL SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SHELL SECTION", "ORIENTATION", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("SHELL SECTION", "COMPOSITE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("SHELL SECTION", "OFFSET", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("SHELL SECTION", .TRUE.)
        
        ! *BEAM SECTION
        CALL kw_registry_register("BEAM SECTION", KW_CAT_SECTION, "Beam element section")
        CALL kw_registry_add_param("BEAM SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("BEAM SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("BEAM SECTION", "SECTION", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_set_data_spec("BEAM SECTION", .TRUE.)
        
        ! *MEMBRANE SECTION
        CALL kw_registry_register("MEMBRANE SECTION", KW_CAT_SECTION, "Membrane section")
        CALL kw_registry_add_param("MEMBRANE SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("MEMBRANE SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("MEMBRANE SECTION", .TRUE.)
        
        ! *COHESIVE SECTION
        CALL kw_registry_register("COHESIVE SECTION", KW_CAT_SECTION, "Cohesive element section")
        CALL kw_registry_add_param("COHESIVE SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("COHESIVE SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("COHESIVE SECTION", "RESPONSE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("COHESIVE SECTION", .TRUE.)
        
        ! *SECTION CONTROLS
        CALL kw_registry_register("SECTION CONTROLS", KW_CAT_SECTION, "Section integration controls")
        CALL kw_registry_add_param("SECTION CONTROLS", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SECTION CONTROLS", "HOURGLASS", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("SECTION CONTROLS", "SECOND ORDER ACCURACY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SECTION CONTROLS", .TRUE., min_lines=0)
    END SUBROUTINE register_section_keywords

    ! ==========================================================================
    ! INTERNAL: Register Constraint Keywords
    ! ==========================================================================
    SUBROUTINE register_constraint_keywords()
        ! *BOUNDARY
        CALL kw_registry_register("BOUNDARY", KW_CAT_CONSTRAINT, "Boundary conditions")
        CALL kw_registry_add_param("BOUNDARY", "TYPE", PARAM_TYPE_ENUM, .FALSE., "DISPLACEMENT")
        CALL kw_registry_add_param("BOUNDARY", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("BOUNDARY", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_add_param("BOUNDARY", "FIXED", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("BOUNDARY", .TRUE.)
        
        ! *TIE
        CALL kw_registry_register("TIE", KW_CAT_CONSTRAINT, "Tie constraint")
        CALL kw_registry_add_param("TIE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("TIE", "ADJUST", PARAM_TYPE_ENUM, .FALSE., "YES")
        CALL kw_registry_add_param("TIE", "POSITION TOLERANCE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("TIE", .TRUE.)
        
        ! *COUPLING
        CALL kw_registry_register("COUPLING", KW_CAT_CONSTRAINT, "Coupling constraint")
        CALL kw_registry_add_param("COUPLING", "CONSTRAINT NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("COUPLING", "REF NODE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("COUPLING", "SURFACE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("COUPLING", .FALSE.)
        
        ! *KINEMATIC COUPLING
        CALL kw_registry_register("KINEMATIC COUPLING", KW_CAT_CONSTRAINT, "Kinematic coupling")
        CALL kw_registry_add_param("KINEMATIC COUPLING", "REF NODE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_set_data_spec("KINEMATIC COUPLING", .TRUE.)
        
        ! *DISTRIBUTING COUPLING
        CALL kw_registry_register("DISTRIBUTING COUPLING", KW_CAT_CONSTRAINT, "Distributing coupling")
        CALL kw_registry_add_param("DISTRIBUTING COUPLING", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("DISTRIBUTING COUPLING", .TRUE.)
        
        ! *MPC
        CALL kw_registry_register("MPC", KW_CAT_CONSTRAINT, "Multi-point constraint")
        CALL kw_registry_add_param("MPC", "MODE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("MPC", "USER", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MPC", .TRUE.)
        
        ! *EQUATION
        CALL kw_registry_register("EQUATION", KW_CAT_CONSTRAINT, "Linear constraint equation")
        CALL kw_registry_set_data_spec("EQUATION", .TRUE.)
        
        ! *RIGID BODY
        CALL kw_registry_register("RIGID BODY", KW_CAT_CONSTRAINT, "Rigid body constraint")
        CALL kw_registry_add_param("RIGID BODY", "REF NODE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("RIGID BODY", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("RIGID BODY", "TIE NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("RIGID BODY", .FALSE.)
        
        ! *INITIAL CONDITIONS
        CALL kw_registry_register("INITIAL CONDITIONS", KW_CAT_CONSTRAINT, "Initial conditions")
        CALL kw_registry_add_param("INITIAL CONDITIONS", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_add_param("INITIAL CONDITIONS", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("INITIAL CONDITIONS", .TRUE.)
    END SUBROUTINE register_constraint_keywords

    ! ==========================================================================
    ! INTERNAL: Register Load Keywords
    ! ==========================================================================
    SUBROUTINE register_load_keywords()
        ! *CLOAD
        CALL kw_registry_register("CLOAD", KW_CAT_LOAD, "Concentrated load")
        CALL kw_registry_add_param("CLOAD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("CLOAD", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_add_param("CLOAD", "FOLLOWER", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CLOAD", .TRUE.)
        
        ! *DLOAD
        CALL kw_registry_register("DLOAD", KW_CAT_LOAD, "Distributed load")
        CALL kw_registry_add_param("DLOAD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DLOAD", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_add_param("DLOAD", "FOLLOWER", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("DLOAD", .TRUE.)
        
        ! *DSLOAD
        CALL kw_registry_register("DSLOAD", KW_CAT_LOAD, "Distributed surface load")
        CALL kw_registry_add_param("DSLOAD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DSLOAD", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("DSLOAD", .TRUE.)
        
        ! *TEMPERATURE
        CALL kw_registry_register("TEMPERATURE", KW_CAT_LOAD, "Temperature field")
        CALL kw_registry_add_param("TEMPERATURE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("TEMPERATURE", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_add_param("TEMPERATURE", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("TEMPERATURE", .TRUE.)
        
        ! *SFILM
        CALL kw_registry_register("SFILM", KW_CAT_LOAD, "Surface film condition")
        CALL kw_registry_add_param("SFILM", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("SFILM", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("SFILM", .TRUE.)
        
        ! *SRADIATE
        CALL kw_registry_register("SRADIATE", KW_CAT_LOAD, "Surface radiation")
        CALL kw_registry_add_param("SRADIATE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("SRADIATE", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("SRADIATE", .TRUE.)
        
        ! *CFLUX
        CALL kw_registry_register("CFLUX", KW_CAT_LOAD, "Concentrated heat flux")
        CALL kw_registry_add_param("CFLUX", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("CFLUX", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("CFLUX", .TRUE.)
        
        ! *DFLUX
        CALL kw_registry_register("DFLUX", KW_CAT_LOAD, "Distributed heat flux")
        CALL kw_registry_add_param("DFLUX", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DFLUX", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("DFLUX", .TRUE.)
        
        ! *PRESSURE
        CALL kw_registry_register("PRESSURE", KW_CAT_LOAD, "Pressure load (deprecated)")
        CALL kw_registry_add_param("PRESSURE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("PRESSURE", .TRUE.)
        
        ! *CONNECTOR LOAD
        CALL kw_registry_register("CONNECTOR LOAD", KW_CAT_LOAD, "Connector element load")
        CALL kw_registry_add_param("CONNECTOR LOAD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR LOAD", .TRUE.)
    END SUBROUTINE register_load_keywords

    ! ==========================================================================
    ! INTERNAL: Register Contact Keywords
    ! ==========================================================================
    SUBROUTINE register_contact_keywords()
        ! *CONTACT PAIR
        CALL kw_registry_register("CONTACT PAIR", KW_CAT_CONTACT, "Contact pair definition")
        CALL kw_registry_add_param("CONTACT PAIR", "INTERACTION", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CONTACT PAIR", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("CONTACT PAIR", "SMALL SLIDING", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("CONTACT PAIR", "ADJUST", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT PAIR", .TRUE.)
        
        ! *SURFACE INTERACTION
        CALL kw_registry_register("SURFACE INTERACTION", KW_CAT_CONTACT, "Surface interaction properties")
        CALL kw_registry_add_param("SURFACE INTERACTION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        
        ! *FRICTION
        CALL kw_registry_register("FRICTION", KW_CAT_CONTACT, "Friction model")
        CALL kw_registry_add_param("FRICTION", "SLIP TOLERANCE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("FRICTION", "EXPONENTIAL DECAY", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("FRICTION", "ELASTIC SLIP", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("FRICTION", .TRUE.)
        
        ! *SURFACE BEHAVIOR
        CALL kw_registry_register("SURFACE BEHAVIOR", KW_CAT_CONTACT, "Surface behavior")
        CALL kw_registry_add_param("SURFACE BEHAVIOR", "PRESSURE-OVERCLOSURE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("SURFACE BEHAVIOR", "NO SEPARATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("SURFACE BEHAVIOR", .TRUE., min_lines=0)
        
        ! *GAP CONDUCTANCE
        CALL kw_registry_register("GAP CONDUCTANCE", KW_CAT_CONTACT, "Gap conductance")
        CALL kw_registry_add_param("GAP CONDUCTANCE", "USER", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("GAP CONDUCTANCE", .TRUE.)
        
        ! *CONTACT
        CALL kw_registry_register("CONTACT", KW_CAT_CONTACT, "General contact")
        CALL kw_registry_add_param("CONTACT", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_hierarchy("CONTACT", requires_end=.TRUE., end_keyword="END CONTACT")
        
        ! *END CONTACT
        CALL kw_registry_register("END CONTACT", KW_CAT_END, "End general contact")
        
        ! *CONTACT INCLUSIONS
        CALL kw_registry_register("CONTACT INCLUSIONS", KW_CAT_CONTACT, "Contact inclusions")
        CALL kw_registry_add_param("CONTACT INCLUSIONS", "ALL EXTERIOR", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT INCLUSIONS", .TRUE., min_lines=0)
        
        ! *CONTACT EXCLUSIONS
        CALL kw_registry_register("CONTACT EXCLUSIONS", KW_CAT_CONTACT, "Contact exclusions")
        CALL kw_registry_set_data_spec("CONTACT EXCLUSIONS", .TRUE.)
        
        ! *CONTACT PROPERTY ASSIGNMENT
        CALL kw_registry_register("CONTACT PROPERTY ASSIGNMENT", KW_CAT_CONTACT, "Contact property assignment")
        CALL kw_registry_set_data_spec("CONTACT PROPERTY ASSIGNMENT", .TRUE.)
        
        ! *CLEARANCE
        CALL kw_registry_register("CLEARANCE", KW_CAT_CONTACT, "Initial clearance")
        CALL kw_registry_add_param("CLEARANCE", "MASTER", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CLEARANCE", "SLAVE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CLEARANCE", "VALUE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("CLEARANCE", .TRUE., min_lines=0)
    END SUBROUTINE register_contact_keywords

    ! ==========================================================================
    ! INTERNAL: Register Step Keywords
    ! ==========================================================================
    SUBROUTINE register_step_keywords()
        ! *STEP
        CALL kw_registry_register("STEP", KW_CAT_STEP, "Begin analysis step")
        CALL kw_registry_add_param("STEP", "NAME", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("STEP", "NLGEOM", PARAM_TYPE_ENUM, .FALSE., "NO")
        CALL kw_registry_add_param("STEP", "PERTURBATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("STEP", "INC", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("STEP", "UNSYMM", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("STEP", "AMPLITUDE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_hierarchy("STEP", requires_end=.TRUE., end_keyword="END STEP")
        
        ! *END STEP
        CALL kw_registry_register("END STEP", KW_CAT_END, "End analysis step")
        
        ! *STATIC
        CALL kw_registry_register("STATIC", KW_CAT_STEP, "Static analysis procedure")
        CALL kw_registry_add_param("STATIC", "RIKS", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("STATIC", "STABILIZE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("STATIC", "ALLSDTOL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("STATIC", "DIRECT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("STATIC", .TRUE., min_lines=0, max_lines=1, cols=4)
        
        ! *DYNAMIC
        CALL kw_registry_register("DYNAMIC", KW_CAT_STEP, "Dynamic analysis procedure")
        CALL kw_registry_add_param("DYNAMIC", "EXPLICIT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("DYNAMIC", "SUBSPACE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("DYNAMIC", "APPLICATION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("DYNAMIC", "ALPHA", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("DYNAMIC", "DIRECT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("DYNAMIC", .TRUE., min_lines=0, max_lines=1)
        
        ! *FREQUENCY
        CALL kw_registry_register("FREQUENCY", KW_CAT_STEP, "Natural frequency extraction")
        CALL kw_registry_add_param("FREQUENCY", "EIGENSOLVER", PARAM_TYPE_ENUM, .FALSE., "LANCZOS")
        CALL kw_registry_add_param("FREQUENCY", "NORMALIZATION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("FREQUENCY", "ACOUSTIC COUPLING", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("FREQUENCY", .TRUE.)
        
        ! *BUCKLE
        CALL kw_registry_register("BUCKLE", KW_CAT_STEP, "Eigenvalue buckling")
        CALL kw_registry_add_param("BUCKLE", "EIGENSOLVER", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("BUCKLE", .TRUE.)
        
        ! *HEAT TRANSFER
        CALL kw_registry_register("HEAT TRANSFER", KW_CAT_STEP, "Heat transfer analysis")
        CALL kw_registry_add_param("HEAT TRANSFER", "STEADY STATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("HEAT TRANSFER", "DELTMX", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("HEAT TRANSFER", .TRUE.)
        
        ! *COUPLED TEMPERATURE-DISPLACEMENT
        CALL kw_registry_register("COUPLED TEMPERATURE-DISPLACEMENT", KW_CAT_STEP, "Coupled thermo-mechanical")
        CALL kw_registry_add_param("COUPLED TEMPERATURE-DISPLACEMENT", "STEADY STATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("COUPLED TEMPERATURE-DISPLACEMENT", "DELTMX", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("COUPLED TEMPERATURE-DISPLACEMENT", "CREEP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("COUPLED TEMPERATURE-DISPLACEMENT", .TRUE.)
        
        ! *MODAL DYNAMIC
        CALL kw_registry_register("MODAL DYNAMIC", KW_CAT_STEP, "Modal dynamics")
        CALL kw_registry_add_param("MODAL DYNAMIC", "CONTINUE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MODAL DYNAMIC", .TRUE.)
        
        ! *STEADY STATE DYNAMICS
        CALL kw_registry_register("STEADY STATE DYNAMICS", KW_CAT_STEP, "Steady-state dynamics")
        CALL kw_registry_add_param("STEADY STATE DYNAMICS", "DIRECT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("STEADY STATE DYNAMICS", "SUBSPACE PROJECTION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("STEADY STATE DYNAMICS", .TRUE.)
        
        ! *VISCO
        CALL kw_registry_register("VISCO", KW_CAT_STEP, "Quasi-static viscoelastic")
        CALL kw_registry_add_param("VISCO", "CETOL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("VISCO", .TRUE.)
        
        ! *ANNEAL
        CALL kw_registry_register("ANNEAL", KW_CAT_STEP, "Annealing (clear plastic when T > T_anneal)")
        CALL kw_registry_set_data_spec("ANNEAL", .TRUE.)
        
        ! *GEOSTATIC
        CALL kw_registry_register("GEOSTATIC", KW_CAT_STEP, "Geostatic stress")
        CALL kw_registry_set_data_spec("GEOSTATIC", .TRUE.)
        
        ! *SOILS
        CALL kw_registry_register("SOILS", KW_CAT_STEP, "Soil consolidation")
        CALL kw_registry_add_param("SOILS", "CONSOLIDATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("SOILS", .TRUE.)
        
        ! *RANDOM RESPONSE
        CALL kw_registry_register("RANDOM RESPONSE", KW_CAT_STEP, "Random response (PSD)")
        CALL kw_registry_set_data_spec("RANDOM RESPONSE", .TRUE.)
        
        ! *RESPONSE SPECTRUM
        CALL kw_registry_register("RESPONSE SPECTRUM", KW_CAT_STEP, "Response spectrum analysis")
        CALL kw_registry_add_param("RESPONSE SPECTRUM", "SUM", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("RESPONSE SPECTRUM", .TRUE.)
        
        ! *COMPLEX FREQUENCY
        CALL kw_registry_register("COMPLEX FREQUENCY", KW_CAT_STEP, "Complex eigenvalue (damped)")
        CALL kw_registry_add_param("COMPLEX FREQUENCY", "FRICTION DAMPING", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("COMPLEX FREQUENCY", .TRUE.)
        
        ! *MASS DIFFUSION
        CALL kw_registry_register("MASS DIFFUSION", KW_CAT_STEP, "Mass diffusion analysis")
        CALL kw_registry_add_param("MASS DIFFUSION", "STEADY STATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MASS DIFFUSION", .TRUE.)
        
        ! *COUPLED THERMAL-ELECTRICAL-STRUCTURAL
        CALL kw_registry_register("COUPLED THERMAL-ELECTRICAL-STRUCTURAL", KW_CAT_STEP, "Thermal-electrical-structural 3-field")
        CALL kw_registry_set_data_spec("COUPLED THERMAL-ELECTRICAL-STRUCTURAL", .TRUE.)
        
        ! *PIEZOELECTRIC (step procedure)
        CALL kw_registry_register("PIEZOELECTRIC", KW_CAT_STEP, "Piezoelectric analysis")
        CALL kw_registry_set_data_spec("PIEZOELECTRIC", .TRUE.)
        
        ! *ELECTROMAGNETIC
        CALL kw_registry_register("ELECTROMAGNETIC", KW_CAT_STEP, "Electromagnetic (eddy current/magnetostatics)")
        CALL kw_registry_set_data_spec("ELECTROMAGNETIC", .TRUE.)
        
        ! *ACOUSTIC
        CALL kw_registry_register("ACOUSTIC", KW_CAT_STEP, "Acoustic / coupled acoustic-structural")
        CALL kw_registry_set_data_spec("ACOUSTIC", .TRUE.)
        
        ! *STEADY STATE TRANSPORT
        CALL kw_registry_register("STEADY STATE TRANSPORT", KW_CAT_STEP, "Steady-state transport (rolling/sliding)")
        CALL kw_registry_set_data_spec("STEADY STATE TRANSPORT", .TRUE.)
        
        ! *SUBSTRUCTURE
        CALL kw_registry_register("SUBSTRUCTURE", KW_CAT_STEP, "Substructure / super-element")
        CALL kw_registry_add_param("SUBSTRUCTURE", "GENERATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("SUBSTRUCTURE", .TRUE.)
        
        ! *CONTROLS
        CALL kw_registry_register("CONTROLS", KW_CAT_STEP, "Solution controls")
        CALL kw_registry_add_param("CONTROLS", "PARAMETERS", PARAM_TYPE_ENUM, .FALSE., "TIME INCREMENTATION")
        CALL kw_registry_add_param("CONTROLS", "ANALYSIS", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("CONTROLS", "FIELD", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONTROLS", .TRUE., min_lines=0)
    END SUBROUTINE register_step_keywords

    ! ==========================================================================
    ! INTERNAL: Register Output Keywords
    ! ==========================================================================
    SUBROUTINE register_output_keywords()
        ! *OUTPUT
        CALL kw_registry_register("OUTPUT", KW_CAT_OUTPUT, "Output requests")
        CALL kw_registry_add_param("OUTPUT", "FIELD", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("OUTPUT", "HISTORY", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("OUTPUT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("OUTPUT", "TIME INTERVAL", PARAM_TYPE_REAL, .FALSE.)
        
        ! *NODE OUTPUT
        CALL kw_registry_register("NODE OUTPUT", KW_CAT_OUTPUT, "Node output")
        CALL kw_registry_add_param("NODE OUTPUT", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NODE OUTPUT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("NODE OUTPUT", .TRUE., min_lines=0)
        
        ! *ELEMENT OUTPUT
        CALL kw_registry_register("ELEMENT OUTPUT", KW_CAT_OUTPUT, "Element output")
        CALL kw_registry_add_param("ELEMENT OUTPUT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("ELEMENT OUTPUT", "DIRECTIONS", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("ELEMENT OUTPUT", "POSITION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("ELEMENT OUTPUT", .TRUE., min_lines=0)
        
        ! *CONTACT OUTPUT
        CALL kw_registry_register("CONTACT OUTPUT", KW_CAT_OUTPUT, "Contact output")
        CALL kw_registry_add_param("CONTACT OUTPUT", "MASTER", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("CONTACT OUTPUT", "SLAVE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT OUTPUT", .TRUE., min_lines=0)
        
        ! *ENERGY OUTPUT
        CALL kw_registry_register("ENERGY OUTPUT", KW_CAT_OUTPUT, "Energy output")
        CALL kw_registry_add_param("ENERGY OUTPUT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("ENERGY OUTPUT", .TRUE., min_lines=0)
        
        ! *NODE PRINT
        CALL kw_registry_register("NODE PRINT", KW_CAT_OUTPUT, "Node print")
        CALL kw_registry_add_param("NODE PRINT", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NODE PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("NODE PRINT", "TOTALS", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("NODE PRINT", .TRUE.)
        
        ! *EL PRINT
        CALL kw_registry_register("EL PRINT", KW_CAT_OUTPUT, "Element print")
        CALL kw_registry_add_param("EL PRINT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("EL PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("EL PRINT", "POSITION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("EL PRINT", .TRUE.)
        
        ! *NODE FILE
        CALL kw_registry_register("NODE FILE", KW_CAT_OUTPUT, "Node file output")
        CALL kw_registry_add_param("NODE FILE", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("NODE FILE", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("NODE FILE", .TRUE.)
        
        ! *EL FILE
        CALL kw_registry_register("EL FILE", KW_CAT_OUTPUT, "Element file output")
        CALL kw_registry_add_param("EL FILE", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("EL FILE", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("EL FILE", .TRUE.)
        
        ! *RESTART
        CALL kw_registry_register("RESTART", KW_CAT_OUTPUT, "Restart control")
        CALL kw_registry_add_param("RESTART", "WRITE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("RESTART", "READ", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("RESTART", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("RESTART", "OVERLAY", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("RESTART", .TRUE., min_lines=0)
        
        ! *MONITOR
        CALL kw_registry_register("MONITOR", KW_CAT_OUTPUT, "Monitor output")
        CALL kw_registry_add_param("MONITOR", "NODE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("MONITOR", "DOF", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("MONITOR", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
    END SUBROUTINE register_output_keywords

    ! ==========================================================================
    ! INTERNAL: Register Amplitude Keywords
    ! ==========================================================================
    SUBROUTINE register_amplitude_keywords()
        ! *AMPLITUDE
        CALL kw_registry_register("AMPLITUDE", KW_CAT_AMPLITUDE, "Define amplitude curve")
        CALL kw_registry_add_param("AMPLITUDE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("AMPLITUDE", "TIME", PARAM_TYPE_ENUM, .FALSE., "STEP TIME")
        CALL kw_registry_add_param("AMPLITUDE", "VALUE", PARAM_TYPE_ENUM, .FALSE., "RELATIVE")
        CALL kw_registry_add_param("AMPLITUDE", "DEFINITION", PARAM_TYPE_ENUM, .FALSE., "TABULAR")
        CALL kw_registry_add_param("AMPLITUDE", "SMOOTH", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("AMPLITUDE", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("AMPLITUDE", .TRUE.)
    END SUBROUTINE register_amplitude_keywords

    ! ==========================================================================
    ! INTERNAL: Register Special Keywords
    ! ==========================================================================
    SUBROUTINE register_special_keywords()
        ! *INCLUDE
        CALL kw_registry_register("INCLUDE", KW_CAT_SPECIAL, "Include external file")
        CALL kw_registry_add_param("INCLUDE", "INPUT", PARAM_TYPE_STRING, .TRUE.)
        
        ! *PARAMETER
        CALL kw_registry_register("PARAMETER", KW_CAT_SPECIAL, "Define parameters")
        CALL kw_registry_set_data_spec("PARAMETER", .TRUE.)
        
        ! *PHYSICAL CONSTANTS
        CALL kw_registry_register("PHYSICAL CONSTANTS", KW_CAT_SPECIAL, "Physical constants")
        CALL kw_registry_add_param("PHYSICAL CONSTANTS", "ABSOLUTE ZERO", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("PHYSICAL CONSTANTS", "STEFAN BOLTZMANN", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("PHYSICAL CONSTANTS", "UNIVERSAL GAS CONSTANT", PARAM_TYPE_REAL, .FALSE.)
        
        ! *SYSTEM
        CALL kw_registry_register("SYSTEM", KW_CAT_SPECIAL, "Define coordinate system")
        CALL kw_registry_set_data_spec("SYSTEM", .TRUE.)
        
        ! *TRANSFORM
        CALL kw_registry_register("TRANSFORM", KW_CAT_SPECIAL, "Nodal transformation")
        CALL kw_registry_add_param("TRANSFORM", "NSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("TRANSFORM", "TYPE", PARAM_TYPE_ENUM, .FALSE., "R")
        CALL kw_registry_set_data_spec("TRANSFORM", .TRUE.)
        
        ! *DISTRIBUTION
        CALL kw_registry_register("DISTRIBUTION", KW_CAT_SPECIAL, "Spatial distribution")
        CALL kw_registry_add_param("DISTRIBUTION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("DISTRIBUTION", "LOCATION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("DISTRIBUTION", "TABLE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("DISTRIBUTION", .TRUE.)
        
        ! *DISTRIBUTION TABLE
        CALL kw_registry_register("DISTRIBUTION TABLE", KW_CAT_SPECIAL, "Distribution table")
        CALL kw_registry_add_param("DISTRIBUTION TABLE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("DISTRIBUTION TABLE", .TRUE.)
        
        ! *EMBEDDED ELEMENT
        CALL kw_registry_register("EMBEDDED ELEMENT", KW_CAT_SPECIAL, "Embedded element")
        CALL kw_registry_add_param("EMBEDDED ELEMENT", "HOST ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("EMBEDDED ELEMENT", .TRUE.)
        
        ! *MASS
        CALL kw_registry_register("MASS", KW_CAT_SPECIAL, "Point mass")
        CALL kw_registry_add_param("MASS", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("MASS", .TRUE.)
        
        ! *INERTIA
        CALL kw_registry_register("INERTIA", KW_CAT_SPECIAL, "Rotary inertia")
        CALL kw_registry_add_param("INERTIA", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("INERTIA", .TRUE.)
        
        ! *SPRING
        CALL kw_registry_register("SPRING", KW_CAT_SPECIAL, "Spring element")
        CALL kw_registry_add_param("SPRING", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SPRING", "NONLINEAR", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("SPRING", .TRUE.)
        
        ! *DASHPOT
        CALL kw_registry_register("DASHPOT", KW_CAT_SPECIAL, "Dashpot element")
        CALL kw_registry_add_param("DASHPOT", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("DASHPOT", .TRUE.)
        
        ! *CONNECTOR SECTION
        CALL kw_registry_register("CONNECTOR SECTION", KW_CAT_SPECIAL, "Connector section")
        CALL kw_registry_add_param("CONNECTOR SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CONNECTOR SECTION", "BEHAVIOR", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR SECTION", .TRUE.)
        
        ! *CONNECTOR BEHAVIOR
        CALL kw_registry_register("CONNECTOR BEHAVIOR", KW_CAT_SPECIAL, "Connector behavior")
        CALL kw_registry_add_param("CONNECTOR BEHAVIOR", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_hierarchy("CONNECTOR BEHAVIOR", requires_end=.TRUE., &
                                        end_keyword="END CONNECTOR BEHAVIOR")
        
        ! *END CONNECTOR BEHAVIOR
        CALL kw_registry_register("END CONNECTOR BEHAVIOR", KW_CAT_END, "End connector behavior")
    END SUBROUTINE register_special_keywords

    ! ==========================================================================
    ! PRIORITY 2: Advanced Material Keywords (Damage, Failure, Geomechanics)
    ! ==========================================================================
    SUBROUTINE register_advanced_material_keywords()
        ! --- Damage Initiation and Evolution ---
        CALL kw_registry_register("DAMAGE INITIATION", KW_CAT_MATERIAL, "Damage initiation criterion")
        CALL kw_registry_add_param("DAMAGE INITIATION", "CRITERION", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_add_param("DAMAGE INITIATION", "ALPHA", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("DAMAGE INITIATION", "OMEGA", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("DAMAGE INITIATION", .TRUE.)
        
        CALL kw_registry_register("DAMAGE EVOLUTION", KW_CAT_MATERIAL, "Damage evolution law")
        CALL kw_registry_add_param("DAMAGE EVOLUTION", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_add_param("DAMAGE EVOLUTION", "SOFTENING", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("DAMAGE EVOLUTION", "MIXED MODE BEHAVIOR", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DAMAGE EVOLUTION", .TRUE.)
        
        CALL kw_registry_register("DAMAGE STABILIZATION", KW_CAT_MATERIAL, "Damage viscous regularization")
        CALL kw_registry_set_data_spec("DAMAGE STABILIZATION", .TRUE.)
        
        ! --- Failure Criteria ---
        CALL kw_registry_register("FAIL STRAIN", KW_CAT_MATERIAL, "Strain-based failure")
        CALL kw_registry_set_data_spec("FAIL STRAIN", .TRUE.)
        
        CALL kw_registry_register("FAIL STRESS", KW_CAT_MATERIAL, "Stress-based failure")
        CALL kw_registry_set_data_spec("FAIL STRESS", .TRUE.)
        
        CALL kw_registry_register("SHEAR FAILURE", KW_CAT_MATERIAL, "Shear failure model")
        CALL kw_registry_add_param("SHEAR FAILURE", "ELEMENT DELETION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SHEAR FAILURE", .TRUE.)
        
        CALL kw_registry_register("TENSILE FAILURE", KW_CAT_MATERIAL, "Tensile failure model")
        CALL kw_registry_add_param("TENSILE FAILURE", "ELEMENT DELETION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("TENSILE FAILURE", .TRUE.)
        
        ! --- Geomechanics Models ---
        CALL kw_registry_register("DRUCKER PRAGER", KW_CAT_MATERIAL, "Drucker-Prager plasticity")
        CALL kw_registry_add_param("DRUCKER PRAGER", "SHEAR CRITERION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DRUCKER PRAGER", .TRUE.)
        
        CALL kw_registry_register("DRUCKER PRAGER HARDENING", KW_CAT_MATERIAL, "Drucker-Prager hardening")
        CALL kw_registry_add_param("DRUCKER PRAGER HARDENING", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DRUCKER PRAGER HARDENING", .TRUE.)
        
        CALL kw_registry_register("MOHR COULOMB", KW_CAT_MATERIAL, "Mohr-Coulomb plasticity")
        CALL kw_registry_set_data_spec("MOHR COULOMB", .TRUE.)
        
        CALL kw_registry_register("MOHR COULOMB HARDENING", KW_CAT_MATERIAL, "Mohr-Coulomb hardening")
        CALL kw_registry_set_data_spec("MOHR COULOMB HARDENING", .TRUE.)
        
        CALL kw_registry_register("CAP PLASTICITY", KW_CAT_MATERIAL, "Modified Drucker-Prager/Cap")
        CALL kw_registry_set_data_spec("CAP PLASTICITY", .TRUE.)
        
        CALL kw_registry_register("CAP HARDENING", KW_CAT_MATERIAL, "Cap hardening data")
        CALL kw_registry_set_data_spec("CAP HARDENING", .TRUE.)
        
        CALL kw_registry_register("CLAY PLASTICITY", KW_CAT_MATERIAL, "Cam-Clay plasticity")
        CALL kw_registry_add_param("CLAY PLASTICITY", "HARDENING", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CLAY PLASTICITY", .TRUE.)
        
        CALL kw_registry_register("CLAY HARDENING", KW_CAT_MATERIAL, "Cam-Clay hardening")
        CALL kw_registry_set_data_spec("CLAY HARDENING", .TRUE.)
        
        ! --- Porous Metal Plasticity ---
        CALL kw_registry_register("POROUS METAL PLASTICITY", KW_CAT_MATERIAL, "Gurson porous plasticity")
        CALL kw_registry_add_param("POROUS METAL PLASTICITY", "RELATIVE DENSITY", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("POROUS METAL PLASTICITY", .TRUE.)
        
        CALL kw_registry_register("VOID NUCLEATION", KW_CAT_MATERIAL, "Void nucleation model")
        CALL kw_registry_set_data_spec("VOID NUCLEATION", .TRUE.)
        
        ! --- Concrete/Brittle ---
        CALL kw_registry_register("CONCRETE", KW_CAT_MATERIAL, "Concrete smeared cracking")
        CALL kw_registry_set_data_spec("CONCRETE", .TRUE.)
        
        CALL kw_registry_register("BRITTLE CRACKING", KW_CAT_MATERIAL, "Brittle cracking model")
        CALL kw_registry_add_param("BRITTLE CRACKING", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("BRITTLE CRACKING", .TRUE.)
        
        CALL kw_registry_register("BRITTLE FAILURE", KW_CAT_MATERIAL, "Brittle failure criterion")
        CALL kw_registry_set_data_spec("BRITTLE FAILURE", .TRUE.)
        
        CALL kw_registry_register("BRITTLE SHEAR", KW_CAT_MATERIAL, "Brittle shear retention")
        CALL kw_registry_set_data_spec("BRITTLE SHEAR", .TRUE.)
        
        CALL kw_registry_register("CONCRETE DAMAGED PLASTICITY", KW_CAT_MATERIAL, "CDP model")
        CALL kw_registry_set_data_spec("CONCRETE DAMAGED PLASTICITY", .TRUE.)
        
        CALL kw_registry_register("CONCRETE COMPRESSION HARDENING", KW_CAT_MATERIAL, "CDP compression")
        CALL kw_registry_set_data_spec("CONCRETE COMPRESSION HARDENING", .TRUE.)
        
        CALL kw_registry_register("CONCRETE TENSION STIFFENING", KW_CAT_MATERIAL, "CDP tension")
        CALL kw_registry_set_data_spec("CONCRETE TENSION STIFFENING", .TRUE.)
        
        CALL kw_registry_register("CONCRETE COMPRESSION DAMAGE", KW_CAT_MATERIAL, "CDP compression damage")
        CALL kw_registry_set_data_spec("CONCRETE COMPRESSION DAMAGE", .TRUE.)
        
        CALL kw_registry_register("CONCRETE TENSION DAMAGE", KW_CAT_MATERIAL, "CDP tension damage")
        CALL kw_registry_set_data_spec("CONCRETE TENSION DAMAGE", .TRUE.)
    END SUBROUTINE register_advanced_material_keywords

    ! ==========================================================================
    ! PRIORITY 2: Porous Media / Coupled Pore Fluid Flow
    ! ==========================================================================
    SUBROUTINE register_porous_media_keywords()
        ! --- Permeability ---
        CALL kw_registry_register("PERMEABILITY", KW_CAT_MATERIAL, "Permeability for pore fluid flow")
        CALL kw_registry_add_param("PERMEABILITY", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ISOTROPIC")
        CALL kw_registry_add_param("PERMEABILITY", "SPECIFIC", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("PERMEABILITY", .TRUE.)
        
        CALL kw_registry_register("POROUS BULK MODULI", KW_CAT_MATERIAL, "Porous media bulk moduli")
        CALL kw_registry_set_data_spec("POROUS BULK MODULI", .TRUE.)
        
        CALL kw_registry_register("SORPTION", KW_CAT_MATERIAL, "Sorption behavior")
        CALL kw_registry_add_param("SORPTION", "LAW", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SORPTION", .TRUE.)
        
        CALL kw_registry_register("MOISTURE SWELLING", KW_CAT_MATERIAL, "Moisture-induced swelling")
        CALL kw_registry_set_data_spec("MOISTURE SWELLING", .TRUE.)
        
        CALL kw_registry_register("GEL", KW_CAT_MATERIAL, "Gel swelling model")
        CALL kw_registry_set_data_spec("GEL", .TRUE.)
        
        ! --- Fluid Properties ---
        CALL kw_registry_register("FLUID BULK MODULUS", KW_CAT_MATERIAL, "Pore fluid bulk modulus")
        CALL kw_registry_set_data_spec("FLUID BULK MODULUS", .TRUE.)
        
        CALL kw_registry_register("FLUID DENSITY", KW_CAT_MATERIAL, "Pore fluid density")
        CALL kw_registry_set_data_spec("FLUID DENSITY", .TRUE.)
        
        CALL kw_registry_register("FLUID EXPANSION", KW_CAT_MATERIAL, "Pore fluid thermal expansion")
        CALL kw_registry_set_data_spec("FLUID EXPANSION", .TRUE.)
        
        ! --- Flow Loads/BCs ---
        CALL kw_registry_register("PORE FLUID", KW_CAT_LOAD, "Pore fluid flow")
        CALL kw_registry_add_param("PORE FLUID", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("PORE FLUID", .TRUE.)
        
        CALL kw_registry_register("GAP FLOW", KW_CAT_LOAD, "Gap pore fluid flow")
        CALL kw_registry_set_data_spec("GAP FLOW", .TRUE.)
        
        CALL kw_registry_register("FLUID LEAKOFF", KW_CAT_LOAD, "Fluid leakoff through surface")
        CALL kw_registry_set_data_spec("FLUID LEAKOFF", .TRUE.)
        
        CALL kw_registry_register("DFLOW", KW_CAT_LOAD, "Distributed pore fluid flow")
        CALL kw_registry_add_param("DFLOW", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DFLOW", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DFLOW", .TRUE.)
        
        CALL kw_registry_register("CFLOW", KW_CAT_LOAD, "Concentrated pore fluid flow")
        CALL kw_registry_add_param("CFLOW", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("CFLOW", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CFLOW", .TRUE.)
        
        ! --- Coupled Procedures ---
        CALL kw_registry_register("SOILS", KW_CAT_STEP, "Consolidation/coupled pore fluid")
        CALL kw_registry_add_param("SOILS", "CONSOLIDATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("SOILS", "UTOL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("SOILS", "END", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SOILS", .TRUE.)
    END SUBROUTINE register_porous_media_keywords

    ! ==========================================================================
    ! PRIORITY 2: Advanced Contact and Cohesive Zone
    ! ==========================================================================
    SUBROUTINE register_advanced_contact_keywords()
        ! --- Cohesive Behavior ---
        CALL kw_registry_register("COHESIVE BEHAVIOR", KW_CAT_CONTACT, "Cohesive surface behavior")
        CALL kw_registry_add_param("COHESIVE BEHAVIOR", "ELIGIBILITY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("COHESIVE BEHAVIOR", .TRUE., min_lines=0)
        
        CALL kw_registry_register("DAMAGE", KW_CAT_CONTACT, "Contact damage initiation")
        CALL kw_registry_add_param("DAMAGE", "CRITERION", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_set_data_spec("DAMAGE", .TRUE.)
        
        ! --- Contact Controls ---
        CALL kw_registry_register("CONTACT CONTROLS", KW_CAT_CONTACT, "Contact algorithm controls")
        CALL kw_registry_add_param("CONTACT CONTROLS", "STABILIZE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("CONTACT CONTROLS", "AUTOMATIC TOLERANCES", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("CONTACT CONTROLS", "RESET", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT CONTROLS", .TRUE., min_lines=0)
        
        CALL kw_registry_register("CONTACT DAMPING", KW_CAT_CONTACT, "Contact damping")
        CALL kw_registry_add_param("CONTACT DAMPING", "DEFINITION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT DAMPING", .TRUE.)
        
        CALL kw_registry_register("CONTACT STABILIZATION", KW_CAT_CONTACT, "Contact stabilization")
        CALL kw_registry_add_param("CONTACT STABILIZATION", "TANGENT FRACTION", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT STABILIZATION", .TRUE., min_lines=0)
        
        CALL kw_registry_register("CONTACT FORMULATION", KW_CAT_CONTACT, "Contact formulation")
        CALL kw_registry_add_param("CONTACT FORMULATION", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT FORMULATION", .FALSE.)
        
        ! --- Gap Element ---
        CALL kw_registry_register("GAP", KW_CAT_CONTACT, "Gap element property")
        CALL kw_registry_add_param("GAP", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("GAP", .TRUE.)
        
        CALL kw_registry_register("GAP HEAT GENERATION", KW_CAT_CONTACT, "Frictional heat generation")
        CALL kw_registry_set_data_spec("GAP HEAT GENERATION", .TRUE.)
        
        ! --- Self-Contact ---
        CALL kw_registry_register("SELF CONTACT", KW_CAT_CONTACT, "Self-contact definition")
        CALL kw_registry_add_param("SELF CONTACT", "SURFACE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("SELF CONTACT", .FALSE.)
        
        ! --- Debonding ---
        CALL kw_registry_register("DEBOND", KW_CAT_CONTACT, "Crack propagation along interface")
        CALL kw_registry_add_param("DEBOND", "MASTER", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("DEBOND", "SLAVE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("DEBOND", .FALSE.)
        
        CALL kw_registry_register("FRACTURE CRITERION", KW_CAT_CONTACT, "Debonding fracture criterion")
        CALL kw_registry_add_param("FRACTURE CRITERION", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_add_param("FRACTURE CRITERION", "MIXED MODE BEHAVIOR", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("FRACTURE CRITERION", .TRUE.)
    END SUBROUTINE register_advanced_contact_keywords

    ! ==========================================================================
    ! PRIORITY 2: Advanced Step/Procedure Types
    ! ==========================================================================
    SUBROUTINE register_advanced_step_keywords()
        ! --- Substructure ---
        CALL kw_registry_register("SUBSTRUCTURE GENERATE", KW_CAT_STEP, "Generate substructure")
        CALL kw_registry_add_param("SUBSTRUCTURE GENERATE", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("SUBSTRUCTURE GENERATE", "RECOVERY MATRIX", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SUBSTRUCTURE GENERATE", .TRUE.)
        
        CALL kw_registry_register("SUBSTRUCTURE PROPERTY", KW_CAT_SECTION, "Substructure property assignment")
        CALL kw_registry_add_param("SUBSTRUCTURE PROPERTY", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("SUBSTRUCTURE PROPERTY", .TRUE.)
        
        CALL kw_registry_register("RETAINED NODAL DOFS", KW_CAT_CONSTRAINT, "Retained DOFs for substructure")
        CALL kw_registry_set_data_spec("RETAINED NODAL DOFS", .TRUE.)
        
        ! --- Dynamic Procedures ---
        CALL kw_registry_register("RANDOM RESPONSE", KW_CAT_STEP, "Random response analysis")
        CALL kw_registry_set_data_spec("RANDOM RESPONSE", .TRUE.)
        
        CALL kw_registry_register("RESPONSE SPECTRUM", KW_CAT_STEP, "Response spectrum analysis")
        CALL kw_registry_add_param("RESPONSE SPECTRUM", "SUM", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("RESPONSE SPECTRUM", .TRUE.)
        
        CALL kw_registry_register("SPECTRUM", KW_CAT_AMPLITUDE, "Define spectrum")
        CALL kw_registry_add_param("SPECTRUM", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SPECTRUM", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SPECTRUM", .TRUE.)
        
        CALL kw_registry_register("COMPLEX FREQUENCY", KW_CAT_STEP, "Complex eigenvalue analysis")
        CALL kw_registry_add_param("COMPLEX FREQUENCY", "FRICTION DAMPING", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("COMPLEX FREQUENCY", .TRUE.)
        
        CALL kw_registry_register("DIRECT CYCLIC", KW_CAT_STEP, "Direct cyclic analysis")
        CALL kw_registry_add_param("DIRECT CYCLIC", "FATIGUE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("DIRECT CYCLIC", .TRUE.)
        
        ! --- Mass Diffusion ---
        CALL kw_registry_register("MASS DIFFUSION", KW_CAT_STEP, "Mass diffusion analysis")
        CALL kw_registry_add_param("MASS DIFFUSION", "STEADY STATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MASS DIFFUSION", .TRUE.)
        
        CALL kw_registry_register("DIFFUSIVITY", KW_CAT_MATERIAL, "Mass diffusivity")
        CALL kw_registry_add_param("DIFFUSIVITY", "LAW", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DIFFUSIVITY", .TRUE.)
        
        CALL kw_registry_register("SOLUBILITY", KW_CAT_MATERIAL, "Material solubility")
        CALL kw_registry_set_data_spec("SOLUBILITY", .TRUE.)
        
        CALL kw_registry_register("KAPPA", KW_CAT_MATERIAL, "Pressure stress factor")
        CALL kw_registry_set_data_spec("KAPPA", .TRUE.)
        
        CALL kw_registry_register("CONCENTRATION FLUX", KW_CAT_LOAD, "Concentrated concentration flux")
        CALL kw_registry_add_param("CONCENTRATION FLUX", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CONCENTRATION FLUX", .TRUE.)
    END SUBROUTINE register_advanced_step_keywords

    ! ==========================================================================
    ! PRIORITY 2: Multiphysics (Acoustic, Piezoelectric, Electromagnetic)
    ! ==========================================================================
    SUBROUTINE register_multiphysics_keywords()
        ! --- Acoustic ---
        CALL kw_registry_register("ACOUSTIC MEDIUM", KW_CAT_MATERIAL, "Acoustic medium property")
        CALL kw_registry_set_data_spec("ACOUSTIC MEDIUM", .TRUE.)
        
        CALL kw_registry_register("ACOUSTIC INFINITE", KW_CAT_SECTION, "Acoustic infinite section")
        CALL kw_registry_add_param("ACOUSTIC INFINITE", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("ACOUSTIC INFINITE", .TRUE.)
        
        CALL kw_registry_register("INCIDENT WAVE", KW_CAT_LOAD, "Acoustic incident wave")
        CALL kw_registry_add_param("INCIDENT WAVE", "PROPERTY", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("INCIDENT WAVE", .TRUE.)
        
        CALL kw_registry_register("INCIDENT WAVE PROPERTY", KW_CAT_SPECIAL, "Incident wave property")
        CALL kw_registry_add_param("INCIDENT WAVE PROPERTY", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("INCIDENT WAVE PROPERTY", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("INCIDENT WAVE PROPERTY", .TRUE.)
        
        CALL kw_registry_register("ACOUSTIC WAVE FORMULATION", KW_CAT_SPECIAL, "Acoustic wave formulation")
        CALL kw_registry_add_param("ACOUSTIC WAVE FORMULATION", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("ACOUSTIC WAVE FORMULATION", .FALSE.)
        
        CALL kw_registry_register("SIMPEDANCE", KW_CAT_LOAD, "Surface impedance")
        CALL kw_registry_add_param("SIMPEDANCE", "PROPERTY", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SIMPEDANCE", .TRUE.)
        
        CALL kw_registry_register("IMPEDANCE PROPERTY", KW_CAT_SPECIAL, "Impedance property")
        CALL kw_registry_add_param("IMPEDANCE PROPERTY", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("IMPEDANCE PROPERTY", .TRUE.)
        
        ! --- Piezoelectric ---
        CALL kw_registry_register("PIEZOELECTRIC", KW_CAT_MATERIAL, "Piezoelectric coupling")
        CALL kw_registry_add_param("PIEZOELECTRIC", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("PIEZOELECTRIC", .TRUE.)
        
        CALL kw_registry_register("DIELECTRIC", KW_CAT_MATERIAL, "Dielectric property")
        CALL kw_registry_add_param("DIELECTRIC", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DIELECTRIC", .TRUE.)
        
        CALL kw_registry_register("ELECTRICAL CONDUCTIVITY", KW_CAT_MATERIAL, "Electrical conductivity")
        CALL kw_registry_add_param("ELECTRICAL CONDUCTIVITY", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("ELECTRICAL CONDUCTIVITY", .TRUE.)
        
        CALL kw_registry_register("CECHARGE", KW_CAT_LOAD, "Concentrated electric charge")
        CALL kw_registry_add_param("CECHARGE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CECHARGE", .TRUE.)
        
        CALL kw_registry_register("DECHARGE", KW_CAT_LOAD, "Distributed electric charge")
        CALL kw_registry_add_param("DECHARGE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("DECHARGE", .TRUE.)
        
        CALL kw_registry_register("SECHARGE", KW_CAT_LOAD, "Surface electric charge")
        CALL kw_registry_add_param("SECHARGE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SECHARGE", .TRUE.)
        
        ! --- Electromagnetic ---
        CALL kw_registry_register("MAGNETIC PERMEABILITY", KW_CAT_MATERIAL, "Magnetic permeability")
        CALL kw_registry_add_param("MAGNETIC PERMEABILITY", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("MAGNETIC PERMEABILITY", .TRUE.)
        
        CALL kw_registry_register("ELECTROMAGNETIC", KW_CAT_STEP, "Electromagnetic analysis")
        CALL kw_registry_set_data_spec("ELECTROMAGNETIC", .TRUE.)
        
        ! --- Coupled Thermal-Electric ---
        CALL kw_registry_register("COUPLED THERMAL-ELECTRICAL", KW_CAT_STEP, "Joule heating analysis")
        CALL kw_registry_add_param("COUPLED THERMAL-ELECTRICAL", "STEADY STATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("COUPLED THERMAL-ELECTRICAL", "DELTMX", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("COUPLED THERMAL-ELECTRICAL", .TRUE.)
        
        CALL kw_registry_register("JOULE HEAT FRACTION", KW_CAT_MATERIAL, "Joule heat fraction")
        CALL kw_registry_set_data_spec("JOULE HEAT FRACTION", .TRUE.)
    END SUBROUTINE register_multiphysics_keywords

    ! ==========================================================================
    ! PRIORITY 2: Predefined Fields and Other Keywords
    ! ==========================================================================
    SUBROUTINE register_predefined_field_keywords()
        ! --- Predefined Fields ---
        CALL kw_registry_register("FIELD", KW_CAT_LOAD, "Predefined field variable")
        CALL kw_registry_add_param("FIELD", "VARIABLE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("FIELD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("FIELD", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("FIELD", .TRUE.)
        
        CALL kw_registry_register("PREDEFINED FIELD", KW_CAT_LOAD, "Predefined field (alternative)")
        CALL kw_registry_add_param("PREDEFINED FIELD", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_set_data_spec("PREDEFINED FIELD", .TRUE.)
        
        ! --- Time Points ---
        CALL kw_registry_register("TIME POINTS", KW_CAT_SPECIAL, "Define time points")
        CALL kw_registry_add_param("TIME POINTS", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("TIME POINTS", "GENERATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("TIME POINTS", .TRUE.)
        
        ! --- Adaptive Mesh ---
        CALL kw_registry_register("ADAPTIVE MESH", KW_CAT_SPECIAL, "Adaptive mesh controls")
        CALL kw_registry_add_param("ADAPTIVE MESH", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ADAPTIVE MESH", "CONTROLS", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("ADAPTIVE MESH", .FALSE.)
        
        CALL kw_registry_register("ADAPTIVE MESH CONTROLS", KW_CAT_SPECIAL, "Adaptive mesh control parameters")
        CALL kw_registry_add_param("ADAPTIVE MESH CONTROLS", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("ADAPTIVE MESH CONTROLS", .TRUE.)
        
        CALL kw_registry_register("ADAPTIVE MESH CONSTRAINT", KW_CAT_CONSTRAINT, "Adaptive mesh constraint")
        CALL kw_registry_set_data_spec("ADAPTIVE MESH CONSTRAINT", .TRUE.)
        
        ! --- Model Change ---
        CALL kw_registry_register("MODEL CHANGE", KW_CAT_SPECIAL, "Element/contact activation")
        CALL kw_registry_add_param("MODEL CHANGE", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("MODEL CHANGE", "ADD", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("MODEL CHANGE", "REMOVE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MODEL CHANGE", .TRUE.)
        
        ! --- Film/Radiate ---
        CALL kw_registry_register("FILM", KW_CAT_LOAD, "Surface film condition (element-based)")
        CALL kw_registry_add_param("FILM", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("FILM", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("FILM", .TRUE.)
        
        CALL kw_registry_register("RADIATE", KW_CAT_LOAD, "Surface radiation (element-based)")
        CALL kw_registry_add_param("RADIATE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("RADIATE", "OP", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("RADIATE", .TRUE.)
        
        ! --- Viscous Behavior ---
        CALL kw_registry_register("VISCOUS", KW_CAT_MATERIAL, "Viscous material behavior")
        CALL kw_registry_add_param("VISCOUS", "LAW", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("VISCOUS", .TRUE.)
        
        ! --- Rate-Dependent ---
        CALL kw_registry_register("RATE DEPENDENT", KW_CAT_MATERIAL, "Rate-dependent plasticity")
        CALL kw_registry_add_param("RATE DEPENDENT", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("RATE DEPENDENT", .TRUE.)
        
        ! --- Annealing ---
        CALL kw_registry_register("ANNEAL TEMPERATURE", KW_CAT_MATERIAL, "Annealing temperature")
        CALL kw_registry_set_data_spec("ANNEAL TEMPERATURE", .TRUE.)
        
        ! --- Pretension ---
        CALL kw_registry_register("PRETENSION SECTION", KW_CAT_CONSTRAINT, "Pretension section")
        CALL kw_registry_add_param("PRETENSION SECTION", "NODE", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("PRETENSION SECTION", "SURFACE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("PRETENSION SECTION", .FALSE.)
        
        ! --- Release ---
        CALL kw_registry_register("RELEASE", KW_CAT_CONSTRAINT, "Release beam/shell DOFs")
        CALL kw_registry_set_data_spec("RELEASE", .TRUE.)
        
        ! --- Adjust ---
        CALL kw_registry_register("ADJUST", KW_CAT_SPECIAL, "Adjust initial contact overclosure")
        CALL kw_registry_add_param("ADJUST", "MASTER", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ADJUST", "SLAVE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("ADJUST", .TRUE., min_lines=0)
    END SUBROUTINE register_predefined_field_keywords

    ! ==========================================================================
    ! PRIORITY 3: Connector Element Keywords
    ! ==========================================================================
    SUBROUTINE register_connector_keywords()
        ! --- Connector Constitutive Models ---
        CALL kw_registry_register("CONNECTOR ELASTICITY", KW_CAT_SPECIAL, "Connector elastic behavior")
        CALL kw_registry_add_param("CONNECTOR ELASTICITY", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR ELASTICITY", "NONLINEAR", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR ELASTICITY", "RIGID", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR ELASTICITY", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR DAMPING", KW_CAT_SPECIAL, "Connector damping behavior")
        CALL kw_registry_add_param("CONNECTOR DAMPING", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR DAMPING", "NONLINEAR", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR DAMPING", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR FRICTION", KW_CAT_SPECIAL, "Connector friction")
        CALL kw_registry_add_param("CONNECTOR FRICTION", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR FRICTION", "CONTACT FORCE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR FRICTION", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR PLASTICITY", KW_CAT_SPECIAL, "Connector plasticity")
        CALL kw_registry_add_param("CONNECTOR PLASTICITY", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR PLASTICITY", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR HARDENING", KW_CAT_SPECIAL, "Connector hardening")
        CALL kw_registry_add_param("CONNECTOR HARDENING", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR HARDENING", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR POTENTIAL", KW_CAT_SPECIAL, "Connector yield potential")
        CALL kw_registry_add_param("CONNECTOR POTENTIAL", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR POTENTIAL", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR DAMAGE INITIATION", KW_CAT_SPECIAL, "Connector damage initiation")
        CALL kw_registry_add_param("CONNECTOR DAMAGE INITIATION", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR DAMAGE INITIATION", "CRITERION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR DAMAGE INITIATION", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR DAMAGE EVOLUTION", KW_CAT_SPECIAL, "Connector damage evolution")
        CALL kw_registry_add_param("CONNECTOR DAMAGE EVOLUTION", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR DAMAGE EVOLUTION", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR FAILURE", KW_CAT_SPECIAL, "Connector failure")
        CALL kw_registry_add_param("CONNECTOR FAILURE", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR FAILURE", .TRUE., min_lines=0)
        
        ! --- Connector Motion ---
        CALL kw_registry_register("CONNECTOR MOTION", KW_CAT_CONSTRAINT, "Prescribed connector motion")
        CALL kw_registry_add_param("CONNECTOR MOTION", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("CONNECTOR MOTION", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR MOTION", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR STOP", KW_CAT_SPECIAL, "Connector stop/limit")
        CALL kw_registry_add_param("CONNECTOR STOP", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR STOP", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR LOCK", KW_CAT_SPECIAL, "Connector lock condition")
        CALL kw_registry_add_param("CONNECTOR LOCK", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR LOCK", .TRUE.)
        
        CALL kw_registry_register("CONNECTOR CONSTITUTIVE REFERENCE", KW_CAT_SPECIAL, "Connector reference length")
        CALL kw_registry_set_data_spec("CONNECTOR CONSTITUTIVE REFERENCE", .TRUE.)
    END SUBROUTINE register_connector_keywords

    ! ==========================================================================
    ! PRIORITY 3: Cohesive Zone / Fracture Keywords
    ! ==========================================================================
    SUBROUTINE register_cohesive_keywords()
        ! --- Cohesive Section ---
        CALL kw_registry_register("GASKET SECTION", KW_CAT_SECTION, "Gasket element section")
        CALL kw_registry_add_param("GASKET SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("GASKET SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("GASKET SECTION", .TRUE.)
        
        CALL kw_registry_register("GASKET BEHAVIOR", KW_CAT_MATERIAL, "Gasket material behavior")
        CALL kw_registry_set_data_spec("GASKET BEHAVIOR", .TRUE.)
        
        CALL kw_registry_register("GASKET THICKNESS BEHAVIOR", KW_CAT_MATERIAL, "Gasket thickness behavior")
        CALL kw_registry_set_data_spec("GASKET THICKNESS BEHAVIOR", .TRUE.)
        
        CALL kw_registry_register("GASKET CONTACT AREA", KW_CAT_MATERIAL, "Gasket contact area")
        CALL kw_registry_set_data_spec("GASKET CONTACT AREA", .TRUE.)
        
        ! --- Traction-Separation ---
        CALL kw_registry_register("TRACTION SEPARATION", KW_CAT_MATERIAL, "Traction-separation response")
        CALL kw_registry_set_data_spec("TRACTION SEPARATION", .FALSE.)
        
        ! --- Enriched Elements (XFEM) ---
        CALL kw_registry_register("ENRICHMENT", KW_CAT_SPECIAL, "XFEM enrichment")
        CALL kw_registry_add_param("ENRICHMENT", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ENRICHMENT", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("ENRICHMENT", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("ENRICHMENT", .FALSE.)
        
        CALL kw_registry_register("ENRICHMENT ACTIVATION", KW_CAT_SPECIAL, "Activate XFEM enrichment")
        CALL kw_registry_add_param("ENRICHMENT ACTIVATION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("ENRICHMENT ACTIVATION", "ACTIVATE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("ENRICHMENT ACTIVATION", .FALSE.)
        
        ! --- Crack Definition ---
        CALL kw_registry_register("CRACK", KW_CAT_SPECIAL, "Define crack")
        CALL kw_registry_add_param("CRACK", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CRACK", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CRACK", .TRUE.)
        
        CALL kw_registry_register("CONTOUR INTEGRAL", KW_CAT_OUTPUT, "J-integral contour definition")
        CALL kw_registry_add_param("CONTOUR INTEGRAL", "CONTOURS", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("CONTOUR INTEGRAL", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("CONTOUR INTEGRAL", "CRACK TIP NODES", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CONTOUR INTEGRAL", "SYMM", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTOUR INTEGRAL", .TRUE.)
    END SUBROUTINE register_cohesive_keywords

    ! ==========================================================================
    ! PRIORITY 3: Output Control / History / Debug Keywords
    ! ==========================================================================
    SUBROUTINE register_output_control_keywords()
        ! --- History Output ---
        CALL kw_registry_register("HISTORY OUTPUT", KW_CAT_OUTPUT, "History output request")
        CALL kw_registry_add_param("HISTORY OUTPUT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("HISTORY OUTPUT", "TIME INTERVAL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("HISTORY OUTPUT", .FALSE.)
        
        CALL kw_registry_register("FIELD OUTPUT", KW_CAT_OUTPUT, "Field output request")
        CALL kw_registry_add_param("FIELD OUTPUT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("FIELD OUTPUT", "TIME INTERVAL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("FIELD OUTPUT", .FALSE.)
        
        CALL kw_registry_register("INTEGRATED OUTPUT", KW_CAT_OUTPUT, "Integrated output")
        CALL kw_registry_add_param("INTEGRATED OUTPUT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("INTEGRATED OUTPUT", "SECTION POINTS", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("INTEGRATED OUTPUT", .TRUE.)
        
        CALL kw_registry_register("INTEGRATED OUTPUT SECTION", KW_CAT_SPECIAL, "Integrated section definition")
        CALL kw_registry_add_param("INTEGRATED OUTPUT SECTION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("INTEGRATED OUTPUT SECTION", "SURFACE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("INTEGRATED OUTPUT SECTION", .TRUE.)
        
        ! --- Energy Output ---
        CALL kw_registry_register("ENERGY FILE", KW_CAT_OUTPUT, "Energy history file")
        CALL kw_registry_add_param("ENERGY FILE", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("ENERGY FILE", .FALSE.)
        
        CALL kw_registry_register("ENERGY PRINT", KW_CAT_OUTPUT, "Print energy")
        CALL kw_registry_add_param("ENERGY PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("ENERGY PRINT", .FALSE.)
        
        ! --- Modal Output ---
        CALL kw_registry_register("MODE SELECT", KW_CAT_OUTPUT, "Select modes")
        CALL kw_registry_set_data_spec("MODE SELECT", .TRUE.)
        
        CALL kw_registry_register("MODAL OUTPUT", KW_CAT_OUTPUT, "Modal superposition output")
        CALL kw_registry_set_data_spec("MODAL OUTPUT", .TRUE.)
        
        CALL kw_registry_register("MODAL DAMPING", KW_CAT_STEP, "Modal damping definition")
        CALL kw_registry_add_param("MODAL DAMPING", "MODAL", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("MODAL DAMPING", "RAYLEIGH", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("MODAL DAMPING", .TRUE.)
        
        ! --- Debug / Print Control ---
        CALL kw_registry_register("DEBUG", KW_CAT_SPECIAL, "Debug output control")
        CALL kw_registry_add_param("DEBUG", "FILE", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("DEBUG", .FALSE.)
        
        CALL kw_registry_register("DIAGNOSTICS", KW_CAT_SPECIAL, "Solver diagnostics")
        CALL kw_registry_add_param("DIAGNOSTICS", "CONTACT", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("DIAGNOSTICS", "PLASTICITY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DIAGNOSTICS", .FALSE.)
        
        CALL kw_registry_register("MESSAGE", KW_CAT_SPECIAL, "Message file control")
        CALL kw_registry_add_param("MESSAGE", "FILE", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("MESSAGE", .FALSE.)
    END SUBROUTINE register_output_control_keywords

    ! ==========================================================================
    ! PRIORITY 3: Optimization / Sensitivity Keywords
    ! ==========================================================================
    SUBROUTINE register_optimization_keywords()
        ! --- Design Response ---
        CALL kw_registry_register("DESIGN RESPONSE", KW_CAT_SPECIAL, "Design response definition")
        CALL kw_registry_add_param("DESIGN RESPONSE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("DESIGN RESPONSE", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_set_data_spec("DESIGN RESPONSE", .TRUE.)
        
        CALL kw_registry_register("OBJECTIVE FUNCTION", KW_CAT_SPECIAL, "Objective function")
        CALL kw_registry_add_param("OBJECTIVE FUNCTION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("OBJECTIVE FUNCTION", "DESIGN RESPONSE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("OBJECTIVE FUNCTION", "TARGET", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("OBJECTIVE FUNCTION", .FALSE.)
        
        CALL kw_registry_register("DESIGN CONSTRAINT", KW_CAT_SPECIAL, "Design constraint")
        CALL kw_registry_add_param("DESIGN CONSTRAINT", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("DESIGN CONSTRAINT", "DESIGN RESPONSE", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("DESIGN CONSTRAINT", .TRUE.)
        
        ! --- Sensitivity ---
        CALL kw_registry_register("SENSITIVITY", KW_CAT_STEP, "Sensitivity analysis")
        CALL kw_registry_add_param("SENSITIVITY", "DESIGN VARIABLE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SENSITIVITY", .FALSE.)
        
        CALL kw_registry_register("DESIGN VARIABLE", KW_CAT_SPECIAL, "Design variable definition")
        CALL kw_registry_add_param("DESIGN VARIABLE", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("DESIGN VARIABLE", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("DESIGN VARIABLE", .TRUE.)
        
        ! --- Topology Optimization ---
        CALL kw_registry_register("TOPOLOGY", KW_CAT_SPECIAL, "Topology optimization")
        CALL kw_registry_add_param("TOPOLOGY", "INITIAL CONDITION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("TOPOLOGY", "REGION", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("TOPOLOGY", .TRUE.)
        
        CALL kw_registry_register("GEOMETRIC RESTRICTION", KW_CAT_SPECIAL, "Geometry restriction")
        CALL kw_registry_add_param("GEOMETRIC RESTRICTION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("GEOMETRIC RESTRICTION", "TYPE", PARAM_TYPE_ENUM, .TRUE.)
        CALL kw_registry_set_data_spec("GEOMETRIC RESTRICTION", .TRUE.)
    END SUBROUTINE register_optimization_keywords

    ! ==========================================================================
    ! PRIORITY 3: Explicit Dynamics Keywords
    ! ==========================================================================
    SUBROUTINE register_explicit_keywords()
        ! --- Explicit Procedure ---
        CALL kw_registry_register("DYNAMIC EXPLICIT", KW_CAT_STEP, "Explicit dynamic analysis")
        CALL kw_registry_add_param("DYNAMIC EXPLICIT", "FIXED TIME INCREMENTATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("DYNAMIC EXPLICIT", "SCALE FACTOR", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("DYNAMIC EXPLICIT", .TRUE.)
        
        CALL kw_registry_register("BULK VISCOSITY", KW_CAT_SPECIAL, "Bulk viscosity parameters")
        CALL kw_registry_set_data_spec("BULK VISCOSITY", .TRUE.)
        
        ! --- Mass Scaling ---
        CALL kw_registry_register("VARIABLE MASS SCALING", KW_CAT_SPECIAL, "Variable mass scaling")
        CALL kw_registry_add_param("VARIABLE MASS SCALING", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("VARIABLE MASS SCALING", "DT", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("VARIABLE MASS SCALING", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("VARIABLE MASS SCALING", .TRUE., min_lines=0)
        
        CALL kw_registry_register("FIXED MASS SCALING", KW_CAT_SPECIAL, "Fixed mass scaling")
        CALL kw_registry_add_param("FIXED MASS SCALING", "FACTOR", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("FIXED MASS SCALING", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("FIXED MASS SCALING", .TRUE., min_lines=0)
        
        ! --- Distortion Control ---
        CALL kw_registry_register("DISTORTION CONTROL", KW_CAT_SPECIAL, "Element distortion control")
        CALL kw_registry_add_param("DISTORTION CONTROL", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DISTORTION CONTROL", "LENGTH RATIO", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("DISTORTION CONTROL", .TRUE., min_lines=0)
        
        ! --- Explicit Contact ---
        CALL kw_registry_register("CONTACT PAIR, MECHANICAL CONSTRAINT", KW_CAT_CONTACT, "Explicit contact constraint")
        CALL kw_registry_add_param("CONTACT PAIR, MECHANICAL CONSTRAINT", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT PAIR, MECHANICAL CONSTRAINT", .FALSE.)
        
        CALL kw_registry_register("GENERAL CONTACT", KW_CAT_CONTACT, "General contact (Explicit)")
        CALL kw_registry_add_param("GENERAL CONTACT", "INTERACTION", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("GENERAL CONTACT", .FALSE.)
        
        ! --- Hourglass Control ---
        CALL kw_registry_register("HOURGLASS STIFFNESS", KW_CAT_SPECIAL, "Hourglass stiffness")
        CALL kw_registry_add_param("HOURGLASS STIFFNESS", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("HOURGLASS STIFFNESS", .TRUE.)
        
        ! --- Adiabatic ---
        CALL kw_registry_register("DYNAMIC TEMPERATURE-DISPLACEMENT", KW_CAT_STEP, "Adiabatic analysis")
        CALL kw_registry_set_data_spec("DYNAMIC TEMPERATURE-DISPLACEMENT", .TRUE.)
        
        CALL kw_registry_register("INELASTIC HEAT FRACTION", KW_CAT_MATERIAL, "Inelastic heat fraction")
        CALL kw_registry_set_data_spec("INELASTIC HEAT FRACTION", .TRUE.)
    END SUBROUTINE register_explicit_keywords

    ! ==========================================================================
    ! PRIORITY 3: Miscellaneous / Substructure Keywords
    ! ==========================================================================
    SUBROUTINE register_miscellaneous_keywords()
        ! --- Submodeling ---
        CALL kw_registry_register("SUBMODEL", KW_CAT_SPECIAL, "Submodeling")
        CALL kw_registry_add_param("SUBMODEL", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_add_param("SUBMODEL", "GLOBAL ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SUBMODEL", .TRUE.)
        
        CALL kw_registry_register("BOUNDARY SUBMODEL", KW_CAT_CONSTRAINT, "Submodel boundary")
        CALL kw_registry_add_param("BOUNDARY SUBMODEL", "STEP", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("BOUNDARY SUBMODEL", "GLOBAL STEP", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("BOUNDARY SUBMODEL", .TRUE.)
        
        ! --- Rebar ---
        CALL kw_registry_register("REBAR", KW_CAT_SPECIAL, "Rebar reinforcement")
        CALL kw_registry_add_param("REBAR", "ELEMENT", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("REBAR", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("REBAR", .TRUE.)
        
        CALL kw_registry_register("REBAR LAYER", KW_CAT_SPECIAL, "Rebar layer definition")
        CALL kw_registry_add_param("REBAR LAYER", "GEOMETRY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("REBAR LAYER", .TRUE.)
        
        ! --- Shell General Section ---
        CALL kw_registry_register("SHELL GENERAL SECTION", KW_CAT_SECTION, "General shell section")
        CALL kw_registry_add_param("SHELL GENERAL SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("SHELL GENERAL SECTION", "POISSON", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("SHELL GENERAL SECTION", "DENSITY", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("SHELL GENERAL SECTION", .TRUE.)
        
        CALL kw_registry_register("TRANSVERSE SHEAR STIFFNESS", KW_CAT_SECTION, "Shell transverse shear")
        CALL kw_registry_set_data_spec("TRANSVERSE SHEAR STIFFNESS", .TRUE.)
        
        ! --- Heat Generation ---
        CALL kw_registry_register("HEAT GENERATION", KW_CAT_LOAD, "Heat generation")
        CALL kw_registry_add_param("HEAT GENERATION", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("HEAT GENERATION", .TRUE.)
        
        ! --- Cavity Radiation ---
        CALL kw_registry_register("CAVITY DEFINITION", KW_CAT_SPECIAL, "Cavity radiation definition")
        CALL kw_registry_add_param("CAVITY DEFINITION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("CAVITY DEFINITION", .TRUE.)
        
        CALL kw_registry_register("RADIATION VIEWFACTOR", KW_CAT_SPECIAL, "Radiation viewfactor")
        CALL kw_registry_set_data_spec("RADIATION VIEWFACTOR", .FALSE.)
        
        ! --- Centrifugal/Coriolis ---
        CALL kw_registry_register("CORIOLIS", KW_CAT_LOAD, "Coriolis force")
        CALL kw_registry_add_param("CORIOLIS", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CORIOLIS", .TRUE.)
        
        CALL kw_registry_register("CENTRIFUGAL", KW_CAT_LOAD, "Centrifugal load")
        CALL kw_registry_add_param("CENTRIFUGAL", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("CENTRIFUGAL", .TRUE.)
        
        CALL kw_registry_register("ROTARY INERTIA", KW_CAT_LOAD, "Rotary inertia load")
        CALL kw_registry_set_data_spec("ROTARY INERTIA", .TRUE.)
        
        ! --- Bolt Load ---
        CALL kw_registry_register("BOLT LOAD", KW_CAT_LOAD, "Bolt preload")
        CALL kw_registry_add_param("BOLT LOAD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("BOLT LOAD", .TRUE.)
        
        ! --- User Subroutines ---
        CALL kw_registry_register("USER SUBROUTINE", KW_CAT_SPECIAL, "User subroutine library")
        CALL kw_registry_add_param("USER SUBROUTINE", "INPUT", PARAM_TYPE_STRING, .TRUE.)
        CALL kw_registry_set_data_spec("USER SUBROUTINE", .FALSE.)
        
        CALL kw_registry_register("USER OUTPUT VARIABLES", KW_CAT_OUTPUT, "User output variables")
        CALL kw_registry_set_data_spec("USER OUTPUT VARIABLES", .TRUE.)
        
        CALL kw_registry_register("USER DEFINED FIELD", KW_CAT_SPECIAL, "User defined field")
        CALL kw_registry_set_data_spec("USER DEFINED FIELD", .FALSE.)
        
        ! --- Mapped Field ---
        CALL kw_registry_register("MAPPED FIELD", KW_CAT_SPECIAL, "Mapped field from external source")
        CALL kw_registry_add_param("MAPPED FIELD", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("MAPPED FIELD", "INPUT", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("MAPPED FIELD", .TRUE.)
        
        ! --- Co-simulation ---
        CALL kw_registry_register("CO-SIMULATION", KW_CAT_SPECIAL, "Co-simulation interface")
        CALL kw_registry_add_param("CO-SIMULATION", "NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("CO-SIMULATION", "PROGRAM", PARAM_TYPE_STRING, .FALSE.)
        CALL kw_registry_set_data_spec("CO-SIMULATION", .TRUE.)
        
        CALL kw_registry_register("CO-SIMULATION REGION", KW_CAT_SPECIAL, "Co-simulation region")
        CALL kw_registry_add_param("CO-SIMULATION REGION", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CO-SIMULATION REGION", .TRUE.)
    END SUBROUTINE register_miscellaneous_keywords

    ! ==========================================================================
    ! Phase B Tier 1: Register Advanced Constraint Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_constraint_advanced_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *EMBEDDED ELEMENT (embedded element technique)
        CALL reg_ptr%RegisterKeyword("EMBEDDED ELEMENT", KW_CAT_CONSTRAINT, &
            "Embedded element constraint", status)
        CALL kw_registry_add_param("EMBEDDED ELEMENT", "HOST ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("EMBEDDED ELEMENT", .TRUE.)
        
        ! *CLEARANCE (gap/overclosure definition)
        CALL reg_ptr%RegisterKeyword("CLEARANCE", KW_CAT_CONSTRAINT, &
            "Gap clearance definition", status)
        CALL kw_registry_add_param("CLEARANCE", "DEPENDENCY", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CLEARANCE", .TRUE.)
        
        ! *TRANSFORM (coordinate transformation)
        CALL reg_ptr%RegisterKeyword("TRANSFORM", KW_CAT_CONSTRAINT, &
            "Coordinate transformation", status)
        CALL kw_registry_add_param("TRANSFORM", "NSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("TRANSFORM", "TYPE", PARAM_TYPE_ENUM, .FALSE., "R")
        CALL kw_registry_set_data_spec("TRANSFORM", .TRUE.)
        
        ! *SHELL TO SOLID COUPLING
        CALL reg_ptr%RegisterKeyword("SHELL TO SOLID COUPLING", KW_CAT_CONSTRAINT, &
            "Shell-to-solid coupling constraint", status)
        CALL kw_registry_add_param("SHELL TO SOLID COUPLING", "CONSTRAINT NAME", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("SHELL TO SOLID COUPLING", .TRUE.)
        
        ! *CYCLIC SYMMETRY MODEL
        CALL reg_ptr%RegisterKeyword("CYCLIC SYMMETRY MODEL", KW_CAT_CONSTRAINT, &
            "Cyclic symmetry constraint", status)
        CALL kw_registry_add_param("CYCLIC SYMMETRY MODEL", "N", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_set_data_spec("CYCLIC SYMMETRY MODEL", .FALSE.)
        
        ! *SURFACE TO SURFACE CONTACT (general contact)
        CALL reg_ptr%RegisterKeyword("SURFACE TO SURFACE CONTACT", KW_CAT_CONTACT, &
            "Surface-to-surface contact", status)
        CALL kw_registry_add_param("SURFACE TO SURFACE CONTACT", "INTERACTION", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SURFACE TO SURFACE CONTACT", .TRUE.)
        
    END SUBROUTINE register_constraint_advanced_keywords

    ! ==========================================================================
    ! Phase B Tier 1: Register Interaction Keywords (5 keywords)
    ! ==========================================================================
    SUBROUTINE register_interaction_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *SURFACE BEHAVIOR (contact interface behavior)
        CALL reg_ptr%RegisterKeyword("SURFACE BEHAVIOR", KW_CAT_CONTACT, &
            "Contact surface behavior", status)
        CALL kw_registry_add_param("SURFACE BEHAVIOR", "NO SEPARATION", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("SURFACE BEHAVIOR", "PRESSURE-OVERCLOSURE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("SURFACE BEHAVIOR", .FALSE.)
        
        ! *FRICTION (friction model)
        CALL reg_ptr%RegisterKeyword("FRICTION", KW_CAT_CONTACT, &
            "Friction coefficient definition", status)
        CALL kw_registry_add_param("FRICTION", "SLIP TOLERANCE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("FRICTION", "EXPONENTIAL", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("FRICTION", .TRUE.)
        
        ! *GAP (gap definition)
        CALL reg_ptr%RegisterKeyword("GAP", KW_CAT_CONTACT, &
            "Initial gap/overclosure", status)
        CALL kw_registry_add_param("GAP", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("GAP", .TRUE.)
        
        ! *CONTACT DAMPING
        CALL reg_ptr%RegisterKeyword("CONTACT DAMPING", KW_CAT_CONTACT, &
            "Contact damping coefficient", status)
        CALL kw_registry_add_param("CONTACT DAMPING", "DEFINITION", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT DAMPING", .TRUE.)
        
        ! *CONTACT STABILIZATION
        CALL reg_ptr%RegisterKeyword("CONTACT STABILIZATION", KW_CAT_CONTACT, &
            "Contact stabilization", status)
        CALL kw_registry_add_param("CONTACT STABILIZATION", "FACTOR", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("CONTACT STABILIZATION", .TRUE.)
        
    END SUBROUTINE register_interaction_keywords

    ! ==========================================================================
    ! Phase B Tier 1: Register Advanced Initial Condition Keywords (4 keywords)
    ! ==========================================================================
    SUBROUTINE register_initial_condition_advanced_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *TEMPERATURE (initial temperature - already exists in INITIAL CONDITIONS, this is standalone)
        CALL reg_ptr%RegisterKeyword("TEMPERATURE", KW_CAT_LOAD, &
            "Prescribed temperature boundary condition", status)
        CALL kw_registry_add_param("TEMPERATURE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("TEMPERATURE", "OP", PARAM_TYPE_ENUM, .FALSE., "MOD")
        CALL kw_registry_set_data_spec("TEMPERATURE", .TRUE.)
        
        ! *PREDEFINED FIELD (field variables)
        CALL reg_ptr%RegisterKeyword("PREDEFINED FIELD", KW_CAT_LOAD, &
            "Predefined field variables", status)
        CALL kw_registry_add_param("PREDEFINED FIELD", "FIELD", PARAM_TYPE_INTEGER, .TRUE.)
        CALL kw_registry_add_param("PREDEFINED FIELD", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("PREDEFINED FIELD", .TRUE.)
        
        ! *INITIAL STATE (state variable initialization)
        ! UFC: 寮哄�?L3 钀?LoadBC/Ldbc 鍩燂紙涓?*INITIAL CONDITIONS 涓€鑷达級锛岄潪 Const
        CALL reg_ptr%RegisterKeyword("INITIAL STATE", KW_CAT_LOAD, &
            "Initial state variables (Ldbc)", status)
        CALL kw_registry_add_param("INITIAL STATE", "TYPE", PARAM_TYPE_ENUM, .FALSE.)
        CALL kw_registry_set_data_spec("INITIAL STATE", .TRUE.)
        
        ! *GEOSTATIC STRESS (geostatic stress initialization)
        ! UFC: 寮哄�?L3 钀?LoadBC/Ldbc 鍩燂紙闈?Const锛夛紱甯歌绛変�?*INITIAL CONDITIONS,TYPE=GEOSTATIC
        CALL reg_ptr%RegisterKeyword("GEOSTATIC STRESS", KW_CAT_LOAD, &
            "Geostatic stress initialization (Ldbc)", status)
        CALL kw_registry_add_param("GEOSTATIC STRESS", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("GEOSTATIC STRESS", .TRUE.)
        
    END SUBROUTINE register_initial_condition_advanced_keywords

    ! ==========================================================================
    ! Phase B Tier 1: Register Restart Keywords (3 keywords)
    ! ==========================================================================
    SUBROUTINE register_restart_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *RESTART (restart analysis control)
        CALL reg_ptr%RegisterKeyword("RESTART", KW_CAT_STEP, &
            "Restart analysis from previous run", status)
        CALL kw_registry_add_param("RESTART", "WRITE", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("RESTART", "READ", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("RESTART", "STEP", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_add_param("RESTART", "INC", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("RESTART", .FALSE.)
        
        ! *FILE FORMAT (output file format control)
        CALL reg_ptr%RegisterKeyword("FILE FORMAT", KW_CAT_OUTPUT, &
            "Output file format specification", status)
        CALL kw_registry_add_param("FILE FORMAT", "ASCII", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_add_param("FILE FORMAT", "BINARY", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("FILE FORMAT", .FALSE.)
        
        ! *DIAGNOSTICS (diagnostic output control)
        CALL reg_ptr%RegisterKeyword("DIAGNOSTICS", KW_CAT_SPECIAL, &
            "Diagnostic output and debugging", status)
        CALL kw_registry_add_param("DIAGNOSTICS", "LEVEL", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_add_param("DIAGNOSTICS", "CONTACT", PARAM_TYPE_LOGICAL, .FALSE.)
        CALL kw_registry_set_data_spec("DIAGNOSTICS", .FALSE.)
        
    END SUBROUTINE register_restart_keywords

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Material Keywords (8 keywords)
    ! ==========================================================================
    SUBROUTINE register_material_tier2_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *HYPERELASTIC (hyperelastic material)
        CALL reg_ptr%RegisterKeyword("HYPERELASTIC", KW_CAT_MATERIAL, &
            "Hyperelastic material model", status)
        CALL kw_registry_add_param("HYPERELASTIC", "TYPE", PARAM_TYPE_ENUM, .FALSE., "MOONEY-RIVLIN")
        CALL kw_registry_add_param("HYPERELASTIC", "MODULI", PARAM_TYPE_ENUM, .FALSE., "INSTANTANEOUS")
        CALL kw_registry_set_data_spec("HYPERELASTIC", .TRUE.)
        
        ! *HYPERFOAM (hyperelastic foam material)
        CALL reg_ptr%RegisterKeyword("HYPERFOAM", KW_CAT_MATERIAL, &
            "Hyperelastic foam material", status)
        CALL kw_registry_add_param("HYPERFOAM", "N", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_set_data_spec("HYPERFOAM", .TRUE.)
        
        ! *HYPOELASTIC (hypoelastic material)
        CALL reg_ptr%RegisterKeyword("HYPOELASTIC", KW_CAT_MATERIAL, &
            "Hypoelastic material model", status)
        CALL kw_registry_add_param("HYPOELASTIC", "TYPE", PARAM_TYPE_ENUM, .FALSE., "ISOTROPIC")
        CALL kw_registry_set_data_spec("HYPOELASTIC", .TRUE.)
        
        ! *VISCOELASTIC (viscoelastic material)
        CALL reg_ptr%RegisterKeyword("VISCOELASTIC", KW_CAT_MATERIAL, &
            "Viscoelastic material model", status)
        CALL kw_registry_add_param("VISCOELASTIC", "TIME", PARAM_TYPE_ENUM, .FALSE., "PRONY")
        CALL kw_registry_set_data_spec("VISCOELASTIC", .TRUE.)
        
        ! *RATE DEPENDENT (rate-dependent plasticity)
        CALL reg_ptr%RegisterKeyword("RATE DEPENDENT", KW_CAT_MATERIAL, &
            "Rate-dependent plasticity", status)
        CALL kw_registry_add_param("RATE DEPENDENT", "TYPE", PARAM_TYPE_ENUM, .FALSE., "POWER LAW")
        CALL kw_registry_set_data_spec("RATE DEPENDENT", .TRUE.)
        
        ! *CONCRETE (concrete material model)
        CALL reg_ptr%RegisterKeyword("CONCRETE", KW_CAT_MATERIAL, &
            "Concrete damaged plasticity", status)
        CALL kw_registry_set_data_spec("CONCRETE", .TRUE.)
        
        ! *FOAM HARDENING (foam material hardening)
        CALL reg_ptr%RegisterKeyword("FOAM HARDENING", KW_CAT_MATERIAL, &
            "Foam material hardening", status)
        CALL kw_registry_add_param("FOAM HARDENING", "TYPE", PARAM_TYPE_ENUM, .FALSE., "VOLUMETRIC")
        CALL kw_registry_set_data_spec("FOAM HARDENING", .TRUE.)
        
        ! *JOULE HEAT FRACTION (electrical heating fraction)
        CALL reg_ptr%RegisterKeyword("JOULE HEAT FRACTION", KW_CAT_MATERIAL, &
            "Joule heat fraction for electrical-thermal coupling", status)
        CALL kw_registry_set_data_spec("JOULE HEAT FRACTION", .TRUE.)
        
    END SUBROUTINE register_material_tier2_keywords

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Section Keywords (4 keywords)
    ! ==========================================================================
    SUBROUTINE register_section_tier2_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *COHESIVE SECTION (cohesive element section)
        CALL reg_ptr%RegisterKeyword("COHESIVE SECTION", KW_CAT_SECTION, &
            "Cohesive element section properties", status)
        CALL kw_registry_add_param("COHESIVE SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("COHESIVE SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("COHESIVE SECTION", "RESPONSE", PARAM_TYPE_ENUM, .FALSE., "TRACTION SEPARATION")
        CALL kw_registry_set_data_spec("COHESIVE SECTION", .TRUE.)
        
        ! *GASKET SECTION (gasket element section)
        CALL reg_ptr%RegisterKeyword("GASKET SECTION", KW_CAT_SECTION, &
            "Gasket element section properties", status)
        CALL kw_registry_add_param("GASKET SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_add_param("GASKET SECTION", "MATERIAL", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("GASKET SECTION", .TRUE.)
        
        ! *SURFACE SECTION (surface element section)
        CALL reg_ptr%RegisterKeyword("SURFACE SECTION", KW_CAT_SECTION, &
            "Surface element section properties", status)
        CALL kw_registry_add_param("SURFACE SECTION", "ELSET", PARAM_TYPE_NAME_REF, .TRUE.)
        CALL kw_registry_set_data_spec("SURFACE SECTION", .FALSE.)
        
        ! *FRAME (beam section frame definition)
        CALL reg_ptr%RegisterKeyword("FRAME", KW_CAT_SECTION, &
            "Beam section frame orientation", status)
        CALL kw_registry_add_param("FRAME", "TYPE", PARAM_TYPE_ENUM, .FALSE., "RECTANGULAR")
        CALL kw_registry_set_data_spec("FRAME", .TRUE.)
        
    END SUBROUTINE register_section_tier2_keywords

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Output Keywords (4 keywords)
    ! ==========================================================================
    SUBROUTINE register_output_tier2_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *EL PRINT (element output to print file)
        CALL reg_ptr%RegisterKeyword("EL PRINT", KW_CAT_OUTPUT, &
            "Element output to print file", status)
        CALL kw_registry_add_param("EL PRINT", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("EL PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_set_data_spec("EL PRINT", .TRUE.)
        
        ! *CONTACT PRINT (contact output to print file)
        CALL reg_ptr%RegisterKeyword("CONTACT PRINT", KW_CAT_OUTPUT, &
            "Contact output to print file", status)
        CALL kw_registry_add_param("CONTACT PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_set_data_spec("CONTACT PRINT", .TRUE.)
        
        ! *ENERGY PRINT (energy output to print file)
        CALL reg_ptr%RegisterKeyword("ENERGY PRINT", KW_CAT_OUTPUT, &
            "Energy output to print file", status)
        CALL kw_registry_add_param("ENERGY PRINT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_set_data_spec("ENERGY PRINT", .FALSE.)
        
        ! *MODAL OUTPUT (modal analysis output)
        CALL reg_ptr%RegisterKeyword("MODAL OUTPUT", KW_CAT_OUTPUT, &
            "Modal analysis output request", status)
        CALL kw_registry_add_param("MODAL OUTPUT", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE., "1")
        CALL kw_registry_set_data_spec("MODAL OUTPUT", .TRUE.)
        
    END SUBROUTINE register_output_tier2_keywords

    ! ==========================================================================
    ! Phase C Tier 2: Advanced Load Keywords (4 keywords)
    ! ==========================================================================
    SUBROUTINE register_load_tier2_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *CORIOLIS FORCE (Coriolis force load)
        CALL reg_ptr%RegisterKeyword("CORIOLIS FORCE", KW_CAT_LOAD, &
            "Coriolis force in rotating system", status)
        CALL kw_registry_set_data_spec("CORIOLIS FORCE", .TRUE.)
        
        ! *ROTARY ACCELERATION (rotary acceleration load)
        CALL reg_ptr%RegisterKeyword("ROTARY ACCELERATION", KW_CAT_LOAD, &
            "Rotary acceleration load", status)
        CALL kw_registry_add_param("ROTARY ACCELERATION", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("ROTARY ACCELERATION", .TRUE.)
        
        ! *FOUNDATION (foundation interaction)
        CALL reg_ptr%RegisterKeyword("FOUNDATION", KW_CAT_LOAD, &
            "Foundation elastic interaction", status)
        CALL kw_registry_add_param("FOUNDATION", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("FOUNDATION", .TRUE.)
        
        ! *SPRING (spring element load)
        CALL reg_ptr%RegisterKeyword("SPRING", KW_CAT_CONSTRAINT, &
            "Spring element definition", status)
        CALL kw_registry_add_param("SPRING", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("SPRING", .TRUE.)
        
    END SUBROUTINE register_load_tier2_keywords

    ! ==========================================================================
    ! Phase C Tier 3: Advanced Analysis Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_analysis_tier3_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *MODAL DAMPING (modal damping factors)
        CALL reg_ptr%RegisterKeyword("MODAL DAMPING", KW_CAT_STEP, &
            "Modal damping factors", status)
        CALL kw_registry_add_param("MODAL DAMPING", "STRUCTURAL", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("MODAL DAMPING", "VISCOUS", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("MODAL DAMPING", .TRUE.)
        
        ! *SUBSTRUCTURE (substructure analysis)
        CALL reg_ptr%RegisterKeyword("SUBSTRUCTURE", KW_CAT_STEP, &
            "Substructure definition", status)
        CALL kw_registry_add_param("SUBSTRUCTURE", "NAME", PARAM_TYPE_NAME, .TRUE.)
        CALL kw_registry_add_param("SUBSTRUCTURE", "TYPE", PARAM_TYPE_ENUM, .FALSE., "DYNAMIC")
        
        ! *CONTROLS (analysis control parameters)
        CALL reg_ptr%RegisterKeyword("CONTROLS", KW_CAT_STEP, &
            "Analysis control parameters", status)
        CALL kw_registry_add_param("CONTROLS", "PARAMETERS", PARAM_TYPE_ENUM, .FALSE., "TIME INCREMENTATION")
        CALL kw_registry_add_param("CONTROLS", "ANALYSIS", PARAM_TYPE_ENUM, .FALSE., "DISCONTINUOUS")
        
        ! *SOLVER (solver control)
        CALL reg_ptr%RegisterKeyword("SOLVER", KW_CAT_STEP, &
            "Solver control parameters", status)
        CALL kw_registry_add_param("SOLVER", "DIRECT", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("SOLVER", "ITERATIVE", PARAM_TYPE_FLAG, .FALSE.)
        
        ! *STEADY STATE DYNAMICS (steady state dynamic analysis)
        CALL reg_ptr%RegisterKeyword("STEADY STATE DYNAMICS", KW_CAT_STEP, &
            "Steady state dynamics analysis", status)
        CALL kw_registry_add_param("STEADY STATE DYNAMICS", "HARMONIC", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("STEADY STATE DYNAMICS", "SUBSPACE PROJECTION", PARAM_TYPE_FLAG, .FALSE.)
        
        ! *COMPLEX FREQUENCY (complex eigenvalue extraction)
        CALL reg_ptr%RegisterKeyword("COMPLEX FREQUENCY", KW_CAT_STEP, &
            "Complex eigenvalue extraction", status)
        CALL kw_registry_add_param("COMPLEX FREQUENCY", "EIGENSOLVER", PARAM_TYPE_ENUM, .FALSE., "LANCZOS")
        
    END SUBROUTINE register_analysis_tier3_keywords

    ! ==========================================================================
    ! Phase C Tier 3: Advanced Constraint Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_constraint_tier3_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *DISTRIBUTING (distributing coupling constraint)
        CALL reg_ptr%RegisterKeyword("DISTRIBUTING", KW_CAT_CONSTRAINT, &
            "Distributing coupling constraint", status)
        CALL kw_registry_add_param("DISTRIBUTING", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DISTRIBUTING", "REF NODE", PARAM_TYPE_INTEGER, .TRUE.)
        
        ! *DISTRIBUTING COUPLING (alternative name)
        CALL reg_ptr%RegisterKeyword("DISTRIBUTING COUPLING", KW_CAT_CONSTRAINT, &
            "Distributing coupling constraint", status)
        CALL kw_registry_add_param("DISTRIBUTING COUPLING", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DISTRIBUTING COUPLING", "REF NODE", PARAM_TYPE_INTEGER, .TRUE.)
        
        ! *TIE (tie constraint - advanced options)
        CALL reg_ptr%RegisterKeyword("TIE", KW_CAT_CONSTRAINT, &
            "Tie constraint definition", status)
        CALL kw_registry_add_param("TIE", "NAME", PARAM_TYPE_NAME, .TRUE.)
        CALL kw_registry_add_param("TIE", "ADJUST", PARAM_TYPE_ENUM, .FALSE., "NO")
        CALL kw_registry_add_param("TIE", "POSITION TOLERANCE", PARAM_TYPE_REAL, .FALSE.)
        
        ! *CONNECTOR BEHAVIOR (connector element behavior)
        CALL reg_ptr%RegisterKeyword("CONNECTOR BEHAVIOR", KW_CAT_CONSTRAINT, &
            "Connector element behavior", status)
        CALL kw_registry_add_param("CONNECTOR BEHAVIOR", "NAME", PARAM_TYPE_NAME, .TRUE.)
        
        ! *CONNECTOR ELASTICITY (connector elastic stiffness)
        CALL reg_ptr%RegisterKeyword("CONNECTOR ELASTICITY", KW_CAT_CONSTRAINT, &
            "Connector elastic stiffness", status)
        CALL kw_registry_add_param("CONNECTOR ELASTICITY", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR ELASTICITY", .TRUE.)
        
        ! *CONNECTOR DAMPING (connector damping)
        CALL reg_ptr%RegisterKeyword("CONNECTOR DAMPING", KW_CAT_CONSTRAINT, &
            "Connector damping coefficient", status)
        CALL kw_registry_add_param("CONNECTOR DAMPING", "COMPONENT", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("CONNECTOR DAMPING", .TRUE.)
        
    END SUBROUTINE register_constraint_tier3_keywords

    ! ==========================================================================
    ! Phase C Tier 3: Advanced Load Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_load_tier3_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *DFLUX (distributed heat flux)
        CALL reg_ptr%RegisterKeyword("DFLUX", KW_CAT_LOAD, &
            "Distributed heat flux", status)
        CALL kw_registry_add_param("DFLUX", "ELSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DFLUX", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("DFLUX", .TRUE.)
        
        ! *FILM (film heat transfer)
        CALL reg_ptr%RegisterKeyword("FILM", KW_CAT_LOAD, &
            "Film heat transfer condition", status)
        CALL kw_registry_add_param("FILM", "SURFACE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("FILM", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("FILM", .TRUE.)
        
        ! *RADIATE (radiation heat transfer)
        CALL reg_ptr%RegisterKeyword("RADIATE", KW_CAT_LOAD, &
            "Radiation heat transfer", status)
        CALL kw_registry_add_param("RADIATE", "SURFACE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("RADIATE", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("RADIATE", .TRUE.)
        
        ! *DSFLUX (distributed surface flux)
        CALL reg_ptr%RegisterKeyword("DSFLUX", KW_CAT_LOAD, &
            "Distributed surface flux", status)
        CALL kw_registry_add_param("DSFLUX", "SURFACE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("DSFLUX", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("DSFLUX", .TRUE.)
        
        ! *MASS FLOW (mass flow rate)
        CALL reg_ptr%RegisterKeyword("MASS FLOW", KW_CAT_LOAD, &
            "Mass flow rate", status)
        CALL kw_registry_add_param("MASS FLOW", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("MASS FLOW", "AMPLITUDE", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_set_data_spec("MASS FLOW", .TRUE.)
        
        ! *IMPERFECTION (geometric imperfection)
        CALL reg_ptr%RegisterKeyword("IMPERFECTION", KW_CAT_LOAD, &
            "Geometric imperfection", status)
        CALL kw_registry_add_param("IMPERFECTION", "FILE", PARAM_TYPE_NAME, .FALSE.)
        CALL kw_registry_add_param("IMPERFECTION", "STEP", PARAM_TYPE_INTEGER, .FALSE.)
        CALL kw_registry_set_data_spec("IMPERFECTION", .TRUE.)
        
    END SUBROUTINE register_load_tier3_keywords

    ! ==========================================================================
    ! Phase C Tier 3: Advanced Step Control Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_step_tier3_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *RESTART (restart control)
        CALL reg_ptr%RegisterKeyword("RESTART", KW_CAT_STEP, &
            "Restart control parameters", status)
        CALL kw_registry_add_param("RESTART", "READ", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("RESTART", "WRITE", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("RESTART", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        
        ! *BULK VISCOSITY (bulk viscosity damping)
        CALL reg_ptr%RegisterKeyword("BULK VISCOSITY", KW_CAT_STEP, &
            "Bulk viscosity parameters", status)
        CALL kw_registry_add_param("BULK VISCOSITY", "LINEAR", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("BULK VISCOSITY", "QUADRATIC", PARAM_TYPE_REAL, .FALSE.)
        
        ! *CONTACT CONTROLS (contact algorithm control)
        CALL reg_ptr%RegisterKeyword("CONTACT CONTROLS", KW_CAT_STEP, &
            "Contact algorithm control", status)
        CALL kw_registry_add_param("CONTACT CONTROLS", "STABILIZE", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("CONTACT CONTROLS", "AUTOMATIC TOLERANCES", PARAM_TYPE_FLAG, .FALSE.)
        
        ! *VARIABLE MASS SCALING (variable mass scaling for explicit)
        CALL reg_ptr%RegisterKeyword("VARIABLE MASS SCALING", KW_CAT_STEP, &
            "Variable mass scaling control", status)
        CALL kw_registry_add_param("VARIABLE MASS SCALING", "DT", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_add_param("VARIABLE MASS SCALING", "FREQUENCY", PARAM_TYPE_INTEGER, .FALSE.)
        
        ! *FIELD (coupled field analysis)
        CALL reg_ptr%RegisterKeyword("FIELD", KW_CAT_STEP, &
            "Coupled field analysis", status)
        CALL kw_registry_add_param("FIELD", "THERMAL", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("FIELD", "STRUCTURAL", PARAM_TYPE_FLAG, .FALSE.)
        CALL kw_registry_add_param("FIELD", "ELECTRICAL", PARAM_TYPE_FLAG, .FALSE.)
        
        ! *RESPONSE SPECTRUM (response spectrum analysis)
        CALL reg_ptr%RegisterKeyword("RESPONSE SPECTRUM", KW_CAT_STEP, &
            "Response spectrum analysis", status)
        CALL kw_registry_add_param("RESPONSE SPECTRUM", "NSET", PARAM_TYPE_NAME_REF, .FALSE.)
        CALL kw_registry_add_param("RESPONSE SPECTRUM", "SCALE", PARAM_TYPE_REAL, .FALSE.)
        CALL kw_registry_set_data_spec("RESPONSE SPECTRUM", .TRUE.)
        
    END SUBROUTINE register_step_tier3_keywords

    ! ==========================================================================
    ! Phase C Tier 3: Special and Advanced Keywords (6 keywords)
    ! ==========================================================================
    SUBROUTINE register_special_tier3_keywords(registry)
        TYPE(MD_KW_Registry_Type), INTENT(INOUT), OPTIONAL :: registry
        
        TYPE(MD_KW_Registry_Type), POINTER :: reg_ptr
        TYPE(ErrorStatusType) :: status
        
        IF (PRESENT(registry)) THEN
            reg_ptr => registry
        ELSE
            reg_ptr => g_kw_registry
        END IF
        
        ! *INCLUDE (include external file)
        CALL reg_ptr%RegisterKeyword("INCLUDE", KW_CAT_SPECIAL, &
            "Include external input file", status)
        CALL kw_registry_add_param("INCLUDE", "INPUT", PARAM_TYPE_NAME, .TRUE.)
        
        ! *PARAMETER (parameter definition)
        CALL reg_ptr%RegisterKeyword("PARAMETER", KW_CAT_SPECIAL, &
            "Parameter definition", status)
        CALL kw_registry_set_data_spec("PARAMETER", .TRUE.)
        
        ! *PREPRINT (preprint control)
        CALL reg_ptr%RegisterKeyword("PREPRINT", KW_CAT_OUTPUT, &
            "Preprint control", status)
        CALL kw_registry_add_param("PREPRINT", "ECHO", PARAM_TYPE_ENUM, .FALSE., "YES")
        CALL kw_registry_add_param("PREPRINT", "MODEL", PARAM_TYPE_ENUM, .FALSE., "YES")
        
        ! *ORIENTATION (material orientation)
        CALL reg_ptr%RegisterKeyword("ORIENTATION", KW_CAT_MATERIAL, &
            "Material orientation definition", status)
        CALL kw_registry_add_param("ORIENTATION", "NAME", PARAM_TYPE_NAME, .TRUE.)
        CALL kw_registry_add_param("ORIENTATION", "SYSTEM", PARAM_TYPE_ENUM, .FALSE., "RECTANGULAR")
        CALL kw_registry_set_data_spec("ORIENTATION", .TRUE.)
        
        ! *DISTRIBUTION (field distribution)
        CALL reg_ptr%RegisterKeyword("DISTRIBUTION", KW_CAT_SPECIAL, &
            "Field distribution definition", status)
        CALL kw_registry_add_param("DISTRIBUTION", "NAME", PARAM_TYPE_NAME, .TRUE.)
        CALL kw_registry_add_param("DISTRIBUTION", "LOCATION", PARAM_TYPE_ENUM, .FALSE., "ELEMENT")
        CALL kw_registry_set_data_spec("DISTRIBUTION", .TRUE.)
        
        ! *FILTER (result filtering)
        CALL reg_ptr%RegisterKeyword("FILTER", KW_CAT_OUTPUT, &
            "Result filtering", status)
        CALL kw_registry_add_param("FILTER", "TYPE", PARAM_TYPE_ENUM, .FALSE., "BUTTERWORTH")
        CALL kw_registry_add_param("FILTER", "FREQUENCY", PARAM_TYPE_REAL, .FALSE.)
        
    END SUBROUTINE register_special_tier3_keywords

END MODULE MD_KW_Reg