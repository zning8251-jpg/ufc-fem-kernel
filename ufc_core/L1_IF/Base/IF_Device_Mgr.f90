!===============================================================================
! MODULE: IF_Device_Mgr
! LAYER:  L1_IF
! DOMAIN: Base
! ROLE:   Mgr — device resource management (CPU/GPU detection + allocation)
! BRIEF:  Unified computing resource management: element checking,
!         structure verification, and resource allocation.
! Status: Draft | Last verified: 2026-04-28
!===============================================================================
! Purpose: TODO:
! Theory: N/A
! Status: Draft
MODULE IF_Device_Mgr
    ! ==========================================================================
    ! Dependency Hierarchy: Minimal dependencies to avoid circular references
    ! ==========================================================================
    ! Base Layer: Basic Error Management - Error handling
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_info, log_warn, log_error, log_debug, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_MEM_ERROR, IF_STATUS_EXISTS, IF_STATUS_NOT_FOUND
    ! Identification Layer: Symbol Table Manager (depends on base layer) - Resource identification
    USE IF_Base_SymTbl, ONLY: &
        symbol_table_exists, get_variable_data_id, &
        IF_STORAGE_TYPE_STRUCTURED, IF_STORAGE_TYPE_UNSTRUCTURED, &
        IF_STATUS_TABLE_NOT_INIT
    ! Metadata Layer: Structured Metadata (depends on base/identification layers) - Structured resource validation
    USE IF_Base_StructMeta_Def, ONLY: &
        StructMetaType, struct_meta_exists, struct_meta_query, &
        IF_STATUS_META_NOT_FOUND, IF_STATUS_META_NOT_INIT

    IMPLICIT NONE

    ! ==========================================================================
    ! 1. Device-Specific Error Codes (Defined within this module)
    ! ==========================================================================
    PUBLIC :: IF_STATUS_DEV_EXISTS, IF_STATUS_DEV_NOT_FOUND, IF_STATUS_DEV_TYPE_INVALID
    PUBLIC :: IF_STATUS_DEV_MEM_ERROR, IF_STATUS_DEV_NOT_INIT, IF_STATUS_DEV_OFFLINE
    PUBLIC :: IF_STATUS_DEV_PERM_DENY, IF_STATUS_DEV_MEM_INSUFF, IF_STATUS_DEV_META_ERR
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_EXISTS = 221     ! Device already registered (duplicate device ID)
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_NOT_FOUND = 222   ! Device not found
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_TYPE_INVALID = 223 ! Invalid device type (must be 1=CPU/2=GPU)
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_MEM_ERROR = 224  ! Device memory query failed
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_NOT_INIT = 225   ! Device manager not initialized
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_OFFLINE = 226    ! Device offline (unable to operate)
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_PERM_DENY = 227  ! Device permission denied (operation blocked)
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_MEM_INSUFF = 228 ! Device memory insufficient
    INTEGER(i4), PARAMETER :: IF_STATUS_DEV_META_ERR = 229   ! Metadata validation failed (unable to operate)

    ! ==========================================================================
    ! 2. Device Configuration Constants (Defined within this module, no external dependencies)
    ! ==========================================================================
    PUBLIC :: IF_MAX_DEVICE_COUNT, IF_DEV_TYPE_CPU, IF_DEV_TYPE_GPU
    PUBLIC :: IF_DEV_STATUS_IDLE, IF_DEV_STATUS_BUSY, IF_DEV_STATUS_OFFLINE
    PUBLIC :: IF_MEM_QUERY_INTERVAL, IF_MIN_MEM_THRESHOLD
    INTEGER(i4), PARAMETER :: IF_MAX_DEVICE_COUNT = 16        ! Maximum supported devices (supports GPU clusters)
    INTEGER(i4), PARAMETER :: IF_DEV_TYPE_CPU = 1           ! Device type: CPU
    INTEGER(i4), PARAMETER :: IF_DEV_TYPE_GPU = 2           ! Device type: GPU
    INTEGER(i4), PARAMETER :: IF_DEV_STATUS_IDLE = 1        ! Device status: Idle
    INTEGER(i4), PARAMETER :: IF_DEV_STATUS_BUSY = 2        ! Device status: Busy
    INTEGER(i4), PARAMETER :: IF_DEV_STATUS_OFFLINE = 3      ! Device status: Offline
    INTEGER(i4), PARAMETER :: IF_MEM_QUERY_INTERVAL = 5      ! Memory query interval (seconds, adjustable by hardware)
    INTEGER(KIND=8), PARAMETER :: IF_MIN_MEM_THRESHOLD = 1024*1024  ! Minimum memory threshold (1MB)

    ! ==========================================================================
    ! 3. Device Data Structures (Integrate resource identification elements with detailed field descriptions)
    ! ==========================================================================
    PUBLIC :: DeviceInfoType, DeviceManagerType

    ! Device Information Structure: Records device capabilities, status, and resource identification
    TYPE :: DeviceInfoType
        ! Static capabilities (non-modifiable after initialization)
        INTEGER(i4) :: device_id = 0                      ! Unique device ID (starting from 1)
        INTEGER(i4) :: device_type = IF_DEV_TYPE_CPU         ! Device type (CPU/GPU)
        CHARACTER(LEN=64) :: device_name = "Unknown"  ! Device name (e.g., 'Intel i9'/'NVIDIA A100')
        CHARACTER(LEN=64) :: driver_version = "Unknown" ! Device driver version
        ! Dynamic status (real-time updates)
        INTEGER(i4) :: device_status = IF_DEV_STATUS_OFFLINE ! Current device status
        INTEGER(KIND=8) :: total_mem = 0             ! Total memory (bytes)
        INTEGER(KIND=8) :: used_mem = 0              ! Used memory (bytes)
        INTEGER(KIND=8) :: free_mem = 0              ! Free memory (bytes)
        INTEGER(KIND=8) :: last_query_time = 0       ! Last memory query time (timestamp in seconds)
        ! Resource association (identification/metadata layers)
        CHARACTER(LEN=64) :: associated_data_id = ""  ! Associated resource data ID (accessible by identification layer)
        INTEGER(i4) :: supported_storage = 0              ! Supported storage types (structured/unstructured)
        LOGICAL :: is_permitted = .TRUE.              ! Whether resource access is permitted
    END TYPE DeviceInfoType

    ! Device Manager Structure: Manages registered devices, provides unified resource allocation
    TYPE :: DeviceManagerType
        LOGICAL :: initialized = .FALSE.              ! Whether the manager is initialized
        INTEGER(i4) :: max_devices = IF_MAX_DEVICE_COUNT     ! Maximum supported devices
        INTEGER(i4) :: current_dev_count = 0              ! Current number of registered devices
        TYPE(DeviceInfoType), ALLOCATABLE :: dev_list(:) ! Device list
    END TYPE DeviceManagerType

    ! ==========================================================================
    ! 4. Global Instance (PRIVATE+SAVE: Fortran2003 Standard, no direct external access)
    ! ==========================================================================
    TYPE(DeviceManagerType), PRIVATE, SAVE :: global_dev_mgr

    ! ==========================================================================
    ! 5. Public Interface Export (Minimal Exposure Principle: Only export externally needed entities)
    ! ==========================================================================
    PRIVATE
    PUBLIC :: init_device_mgr, destroy_device_mgr
    PUBLIC :: register_device, unregister_device, query_device_memory
    PUBLIC :: update_device_status, update_device_memory_usage, get_device_info, check_device_mem_suff
    PUBLIC :: get_active_device_count
    ! Public utility functions used by other modules
    PUBLIC :: get_timestamp, INT_TO_STR, INT8_TO_STR

CONTAINS
    ! ==========================================================================
    ! Subroutine: Initialize Device Manager (Registers default CPU, associates resource metadata)
    ! ==========================================================================
    SUBROUTINE init_device_mgr(status, max_devices)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: max_devices  ! Optional: Custom max device count
        INTEGER(i4) :: local_max_dev
        TYPE(DeviceInfoType) :: default_cpu
        CHARACTER(LEN=20) :: init_time

        CALL init_error_status(status)

        ! Pre-check: Whether manager is already initialized (base error code: IF_STATUS_EXISTS)
        IF (global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Device manager already initialized"
            CALL log_info("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Handle max device count (default: IF_MAX_DEVICE_COUNT, range: 1~IF_MAX_DEVICE_COUNT)
        local_max_dev = IF_MAX_DEVICE_COUNT
        IF (PRESENT(max_devices)) THEN
            IF (max_devices <= 0 .OR. max_devices > IF_MAX_DEVICE_COUNT) THEN
                status%status_code = IF_STATUS_ERROR
                WRITE(status%message, '(A,I0,A,I0)') &
                    "Max devices must be 1-", IF_MAX_DEVICE_COUNT, ", got ", max_devices
                CALL log_error("DeviceManager", TRIM(status%message))
                RETURN
            END IF
            local_max_dev = max_devices
        END IF

        ! Allocate device list (base error code: IF_STATUS_MEM_ERROR)
        ALLOCATE(global_dev_mgr%dev_list(local_max_dev), STAT=status%io_stat)
        IF (status%io_stat /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0)') &
                "Allocate device list failed (stat=", status%io_stat
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Initialize default CPU device (simulation: associate 'IF_DEFAULT_CPU' resource, query metadata)
        CALL get_timestamp(init_time)
        default_cpu%device_id = 1
        default_cpu%device_type = IF_DEV_TYPE_CPU
        default_cpu%device_name = "Default CPU"
        default_cpu%driver_version = "Native"
        default_cpu%device_status = IF_DEV_STATUS_IDLE
        default_cpu%total_mem = 8*1024*1024*1024_8  ! Simulate 8GB CPU memory
        default_cpu%free_mem = default_cpu%total_mem
        default_cpu%used_mem = 0
        default_cpu%last_query_time = get_timestamp_int()
        default_cpu%associated_data_id = "IF_DEFAULT_CPU_001"
        default_cpu%supported_storage = IF_STORAGE_TYPE_STRUCTURED  ! Default support for structured storage
        default_cpu%is_permitted = .TRUE.

        ! Register default CPU to manager
        global_dev_mgr%dev_list(1) = default_cpu
        global_dev_mgr%current_dev_count = 1
        global_dev_mgr%max_devices = local_max_dev
        global_dev_mgr%initialized = .TRUE.

        ! Log initialization completion (split long message for readability)
        CALL log_info("DeviceManager", &
                      "Initialized device manager (max devices="//TRIM(INT_TO_STR(local_max_dev))//&
                      ", default CPU: ID="//TRIM(INT_TO_STR(default_cpu%device_id))//&
                      ", mem="//TRIM(INT8_TO_STR(default_cpu%total_mem))//" bytes)")
    END SUBROUTINE init_device_mgr

    ! ==========================================================================
    ! Subroutine: Destroy Device Manager (Deallocate list, reset status)
    ! ==========================================================================
    SUBROUTINE destroy_device_mgr(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        CALL init_error_status(status)

        ! Pre-check: Whether manager is uninitialized (specific error code: IF_STATUS_DEV_NOT_INIT)
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_warn("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Deallocate device list (base error code: IF_STATUS_MEM_ERROR)
        IF (ALLOCATED(global_dev_mgr%dev_list)) THEN
            DEALLOCATE(global_dev_mgr%dev_list, STAT=status%io_stat)
            IF (status%io_stat /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0)') &
                    "Deallocate device list failed (stat=", status%io_stat
                CALL log_error("DeviceManager", TRIM(status%message))
            END IF
        END IF

        ! Reset manager status
        global_dev_mgr%initialized = .FALSE.
        global_dev_mgr%max_devices = 0
        global_dev_mgr%current_dev_count = 0

        CALL log_info("DeviceManager", "Destroyed device manager")
    END SUBROUTINE destroy_device_mgr

    ! ==========================================================================
    ! Subroutine: Register Device (Validates resource identification, metadata association)
    ! ==========================================================================
    SUBROUTINE register_device(dev_id, dev_type, dev_name, driver_ver, data_id, &
                               storage_type, status)
        INTEGER(i4), INTENT(IN) :: dev_id                  ! Device ID (unique)
        INTEGER(i4), INTENT(IN) :: dev_type                ! Device type (1=CPU/2=GPU)
        CHARACTER(LEN=*), INTENT(IN) :: dev_name       ! Device name
        CHARACTER(LEN=*), INTENT(IN) :: driver_ver     ! Driver version
        CHARACTER(LEN=*), INTENT(IN) :: data_id        ! Associated resource data ID (from symbol table)
        INTEGER(i4), INTENT(IN) :: storage_type           ! Supported storage type
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        TYPE(DeviceInfoType) :: new_dev
        LOGICAL :: sym_exists, meta_exists

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_DEV_NOT_INIT)
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Valid device ID range (1~max_devices)
        IF (dev_id <= 0 .OR. dev_id > global_dev_mgr%max_devices) THEN
            status%status_code = IF_STATUS_ERROR
            WRITE(status%message, '(A,I0,A,I0)') &
                "Device ID must be 1-", global_dev_mgr%max_devices, ", got ", dev_id
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 3: Whether device is already registered (specific error code: IF_STATUS_DEV_EXISTS)
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id .AND. &
                global_dev_mgr%dev_list(i)%device_status /= IF_DEV_STATUS_OFFLINE) THEN
                status%status_code = IF_STATUS_DEV_EXISTS
                WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " already registered"
                CALL log_error("DeviceManager", TRIM(status%message))
                RETURN
            END IF
        END DO

        ! Pre-check 4: Valid device type (specific error code: IF_STATUS_DEV_TYPE_INVALID)
        IF (dev_type /= IF_DEV_TYPE_CPU .AND. dev_type /= IF_DEV_TYPE_GPU) THEN
            status%status_code = IF_STATUS_DEV_TYPE_INVALID
            status%message = "Device type must be 1(CPU) or 2(GPU)"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 5: Whether associated resource exists in symbol table (identification layer)
        sym_exists = symbol_table_exists(TRIM(data_id), status)
        IF (status%status_code == IF_STATUS_TABLE_NOT_INIT) THEN
            status%status_code = IF_STATUS_DEV_META_ERR
            status%message = "Symbol table not initialized, cannot link data ID"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF
        IF (.NOT. sym_exists) THEN
            status%status_code = IF_STATUS_DEV_META_ERR
            WRITE(status%message, '(A,A,A)') "Data ID '", TRIM(data_id), "' not in symbol table"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 6: Whether associated resource metadata exists (metadata layer)
        IF (storage_type == IF_STORAGE_TYPE_STRUCTURED) THEN
            meta_exists = struct_meta_exists(TRIM(data_id), status)
            IF (status%status_code == IF_STATUS_META_NOT_INIT) THEN
                status%status_code = IF_STATUS_DEV_META_ERR
                status%message = "Structured metadata manager not initialized"
                CALL log_error("DeviceManager", TRIM(status%message))
                RETURN
            END IF
            IF (.NOT. meta_exists .AND. status%status_code == IF_STATUS_META_NOT_FOUND) THEN
                status%status_code = IF_STATUS_DEV_META_ERR
                WRITE(status%message, '(A,A,A)') "Structured meta for '", TRIM(data_id), "' not found"
                CALL log_error("DeviceManager", TRIM(status%message))
                RETURN
            END IF
        ELSE IF (storage_type == IF_STORAGE_TYPE_UNSTRUCTURED) THEN
            ! Unstructured storage type not supported (UnstructMetaData module not available)
            status%status_code = IF_STATUS_DEV_TYPE_INVALID
            status%message = "Unstructured storage type not supported"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Initialize new device info (simulate memory: CPU=8GB, GPU=16GB)
        new_dev%device_id = dev_id
        new_dev%device_type = dev_type
        new_dev%device_name = TRIM(dev_name)
        new_dev%driver_version = TRIM(driver_ver)
        new_dev%device_status = IF_DEV_STATUS_IDLE
        new_dev%associated_data_id = TRIM(data_id)
        new_dev%supported_storage = storage_type
        new_dev%is_permitted = .TRUE.

        ! Set device memory (simulation: CPU=8GB, GPU=16GB)
        IF (dev_type == IF_DEV_TYPE_CPU) THEN
            new_dev%total_mem = 8*1024*1024*1024_8
        ELSE
            new_dev%total_mem = 16*1024*1024*1024_8
        END IF
        new_dev%free_mem = new_dev%total_mem
        new_dev%used_mem = 0
        new_dev%last_query_time = get_timestamp_int()

        ! Register device to manager
        global_dev_mgr%dev_list(dev_id) = new_dev
        global_dev_mgr%current_dev_count = global_dev_mgr%current_dev_count + 1

        ! Log successful registration (split long message)
        CALL log_info("DeviceManager", &
                      "Registered device: ID="//TRIM(INT_TO_STR(dev_id))//&
                      ", type="//TRIM(dev_type_to_str(dev_type))//&
                      ", name='"//TRIM(dev_name)//&
                      "', data_id='"//TRIM(data_id)//"'")

        ! Set success status for caller logging
        status%status_code = IF_STATUS_OK
        status%message = "Device registered successfully"
    END SUBROUTINE register_device

    ! ==========================================================================
    ! Subroutine: Unregister Device (Mark as offline, disable resource association)
    ! ==========================================================================
    SUBROUTINE unregister_device(dev_id, status)
        INTEGER(i4), INTENT(IN) :: dev_id          ! Device ID
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_DEV_NOT_INIT)
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Find device and unregister
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id) THEN
                ! Check if device is already offline
                IF (global_dev_mgr%dev_list(i)%device_status == IF_DEV_STATUS_OFFLINE) THEN
                    status%status_code = IF_STATUS_DEV_OFFLINE
                    WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " is already offline"
                    CALL log_warn("DeviceManager", TRIM(status%message))
                    RETURN
                END IF

                ! Mark as offline, clear resource association
                global_dev_mgr%dev_list(i)%device_status = IF_DEV_STATUS_OFFLINE
                global_dev_mgr%dev_list(i)%used_mem = 0
                global_dev_mgr%dev_list(i)%free_mem = 0
                global_dev_mgr%dev_list(i)%associated_data_id = ""
                global_dev_mgr%current_dev_count = global_dev_mgr%current_dev_count - 1

                CALL log_info("DeviceManager", &
                              "Unregistered device: ID="//TRIM(INT_TO_STR(dev_id)))
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Device not found (specific error code: IF_STATUS_DEV_NOT_FOUND)
        status%status_code = IF_STATUS_DEV_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " not found"
        CALL log_error("DeviceManager", TRIM(status%message))
    END SUBROUTINE unregister_device

    ! ==========================================================================
    ! Subroutine: Query Device Memory (Supports cached/real-time query, adapts to hardware performance)
    ! ==========================================================================
    SUBROUTINE query_device_memory(dev_id, total_mem, used_mem, free_mem, status)
        INTEGER(i4), INTENT(IN) :: dev_id                ! Device ID
        INTEGER(KIND=8), INTENT(OUT) :: total_mem    ! Total memory (bytes)
        INTEGER(KIND=8), INTENT(OUT) :: used_mem    ! Used memory (bytes)
        INTEGER(KIND=8), INTENT(OUT) :: free_mem    ! Free memory (bytes)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i
        INTEGER(KIND=8) :: current_time, time_diff

        CALL init_error_status(status)
        total_mem = 0
        used_mem = 0
        free_mem = 0

        ! Pre-check 1: Whether manager is initialized (specific error code: IF_STATUS_DEV_NOT_INIT)
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Find device and query memory
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id) THEN
                ! Check if device is offline (specific error code: IF_STATUS_DEV_OFFLINE)
                IF (global_dev_mgr%dev_list(i)%device_status == IF_DEV_STATUS_OFFLINE) THEN
                    status%status_code = IF_STATUS_DEV_OFFLINE
                    WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " is offline"
                    CALL log_error("DeviceManager", TRIM(status%message))
                    RETURN
                END IF

                ! Memory query logic: Real-time if >IF_MEM_QUERY_INTERVAL, else use cache
                current_time = get_timestamp_int()
                time_diff = current_time - global_dev_mgr%dev_list(i)%last_query_time

                IF (time_diff > IF_MEM_QUERY_INTERVAL) THEN
                    ! Real-time query (simulation: replace with actual hardware interface)
                    CALL simulate_hw_mem_query(dev_id, &
                                              global_dev_mgr%dev_list(i)%total_mem, &
                                              global_dev_mgr%dev_list(i)%used_mem, &
                                              global_dev_mgr%dev_list(i)%free_mem, status)
                    IF (status%status_code /= IF_STATUS_OK) THEN
                        status%status_code = IF_STATUS_DEV_MEM_ERROR
                        status%message = "Failed to query device memory"
                        CALL log_error("DeviceManager", TRIM(status%message))
                        RETURN
                    END IF
                    global_dev_mgr%dev_list(i)%last_query_time = current_time
                    CALL log_debug("DeviceManager", &
                                  "Real-time mem query: dev="//TRIM(INT_TO_STR(dev_id))//&
                                  ", free="//TRIM(INT8_TO_STR(global_dev_mgr%dev_list(i)%free_mem))//" bytes")
                ELSE
                    ! Use cache (reduce hardware access frequency)
                    CALL log_debug("DeviceManager", &
                                  "Cached mem query: dev="//TRIM(INT_TO_STR(dev_id))//&
                                  ", cache age="//TRIM(INT8_TO_STR(time_diff))//"s")
                END IF

                ! Return memory info
                total_mem = global_dev_mgr%dev_list(i)%total_mem
                used_mem = global_dev_mgr%dev_list(i)%used_mem
                free_mem = global_dev_mgr%dev_list(i)%free_mem
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Device not found (specific error code: IF_STATUS_DEV_NOT_FOUND)
        status%status_code = IF_STATUS_DEV_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " not found"
        CALL log_error("DeviceManager", TRIM(status%message))
    END SUBROUTINE query_device_memory

    ! ==========================================================================
    ! Subroutine: Check Device Memory Sufficiency (Based on metadata resource size)
    ! ==========================================================================
    SUBROUTINE check_device_mem_suff(dev_id, data_id, storage_type, is_suff, status)
        INTEGER(i4), INTENT(IN) :: dev_id              ! Device ID
        CHARACTER(LEN=*), INTENT(IN) :: data_id    ! Resource data ID
        INTEGER(i4), INTENT(IN) :: storage_type       ! Storage type (structured/unstructured)
        LOGICAL, INTENT(OUT) :: is_suff           ! Sufficiency result (.TRUE.=sufficient)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(KIND=8) :: total_mem, used_mem, free_mem, required_mem
        TYPE(StructMetaType) :: struct_meta

        CALL init_error_status(status)
        is_suff = .FALSE.
        required_mem = 0

        ! Step 1: Query current device memory
        CALL query_device_memory(dev_id, total_mem, used_mem, free_mem, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        ! Step 2: Get resource memory size from metadata (metadata layer)
        IF (storage_type == IF_STORAGE_TYPE_STRUCTURED) THEN
            CALL struct_meta_query(TRIM(data_id), 1, struct_meta, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                status%status_code = IF_STATUS_DEV_META_ERR
                status%message = "Failed to get structured meta for data ID"
                CALL log_error("DeviceManager", TRIM(status%message))
                RETURN
            END IF
            required_mem = struct_meta%total_size
        ELSE
            ! For unstructured data, use a default required memory size
            ! This is a temporary fix until UnstructMetaData is properly implemented
            required_mem = 1024 * 1024 * 1024  ! Default to 1GB
        END IF

        ! Step 3: Check sufficiency (reserve 10% safety margin)
        IF (required_mem == 0) THEN
            is_suff = .TRUE.
            CALL log_debug("DeviceManager", &
                          "Required mem is 0, dev "//TRIM(INT_TO_STR(dev_id))//" is sufficient")
            RETURN
        END IF

        IF (free_mem >= required_mem * 1.1_8) THEN
            is_suff = .TRUE.
            CALL log_debug("DeviceManager", &
                          "Dev "//TRIM(INT_TO_STR(dev_id))//" mem sufficient (free: "//&
                          TRIM(INT8_TO_STR(free_mem))//", required: "//TRIM(INT8_TO_STR(required_mem))//")")
        ELSE
            status%status_code = IF_STATUS_DEV_MEM_INSUFF
            WRITE(status%message, '(A,I0,A,I0,A,I0)') &
                "Dev ", dev_id, " out of mem (free: ", free_mem, ", required: ", required_mem, ")"
            CALL log_error("DeviceManager", TRIM(status%message))
        END IF
    END SUBROUTINE check_device_mem_suff

    ! ==========================================================================
    ! Internal Subroutine: Simulate Hardware Memory Query (Replace with actual hardware interface)
    ! ==========================================================================
    SUBROUTINE simulate_hw_mem_query(dev_id, total_mem, used_mem, free_mem, status)
        INTEGER(i4), INTENT(IN) :: dev_id
        INTEGER(KIND=8), INTENT(INOUT) :: total_mem, used_mem, free_mem
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        REAL :: rand_val  ! Fortran standard random number in [0,1)

        CALL init_error_status(status)

        ! 1. Generate standard random number (Fortran standard intrinsic procedure)
        CALL RANDOM_NUMBER(rand_val)  ! rand_val  ?[0,1)

        ! 2. Simulate memory fluctuation (mimic real hardware behavior)
        ! CPU memory fluctuation: ±5% (0.95~1.05x), GPU memory fluctuation: ±10% (0.9~1.1x)
        IF (dev_id <= global_dev_mgr%max_devices .AND. &
            global_dev_mgr%dev_list(dev_id)%device_type == IF_DEV_TYPE_CPU) THEN
            ! CPU: used_mem = used_mem Ý?(0.95 + 0.1×random)
            used_mem = INT(used_mem * (0.95 + 0.1 * rand_val), KIND=8)
        ELSE
            ! GPU: used_mem = used_mem Ý?(0.9 + 0.2×random)
            used_mem = INT(used_mem * (0.9 + 0.2 * rand_val), KIND=8)
        END IF

        ! 3. Ensure memory validity: used_mem ?total_mem - minimum threshold
        used_mem = MIN(used_mem, total_mem - IF_MIN_MEM_THRESHOLD)
        free_mem = total_mem - used_mem
        status%status_code = IF_STATUS_OK
    END SUBROUTINE simulate_hw_mem_query

    ! ==========================================================================
    ! Internal Function: Convert Device Type to String (for logging)
    ! ==========================================================================
    FUNCTION dev_type_to_str(type_code) RESULT(type_str)
        INTEGER(i4), INTENT(IN) :: type_code
        CHARACTER(LEN=10) :: type_str

        SELECT CASE (type_code)
            CASE (IF_DEV_TYPE_CPU)
                type_str = "CPU"
            CASE (IF_DEV_TYPE_GPU)
                type_str = "GPU"
            CASE DEFAULT
                type_str = "Unknown"
        END SELECT
    END FUNCTION dev_type_to_str

    ! ==========================================================================
    ! Internal Subroutine: Get Timestamp (String Format, for logging)
    ! ==========================================================================
    SUBROUTINE get_timestamp(timestamp)
        CHARACTER(LEN=20), INTENT(OUT) :: timestamp
        INTEGER(i4) :: values(8)

        CALL DATE_AND_TIME(VALUES=values)
        WRITE(timestamp, '(I4,"-",I2.2,"-",I2.2," ",I2.2,":",I2.2,":",I2.2)') &
            values(1), values(2), values(3), values(5), values(6), values(7)
    END SUBROUTINE get_timestamp

    ! ==========================================================================
    ! Internal Function: Get Timestamp (Integer Format, for memory query interval)
    ! ==========================================================================
    INTEGER(KIND=8) FUNCTION get_timestamp_int()
        INTEGER(i4) :: values(8)

        CALL DATE_AND_TIME(VALUES=values)
        get_timestamp_int = INT(values(1), KIND=8)*31536000_8 + &  ! Seconds in year
                            INT(values(2), KIND=8)*2592000_8 + &   ! Seconds in month
                            INT(values(3), KIND=8)*86400_8 + &     ! Seconds in day
                            INT(values(5), KIND=8)*3600_8 + &     ! Seconds in hour
                            INT(values(6), KIND=8)*60_8 + &       ! Seconds in minute
                            INT(values(7), KIND=8)              ! Seconds
    END FUNCTION get_timestamp_int

    ! ==========================================================================
    ! Internal Function: Integer to String (Fortran2003 Compatible, for logging)
    ! ==========================================================================
    FUNCTION INT_TO_STR(i) RESULT(str)
        INTEGER(i4), INTENT(IN) :: i
        CHARACTER(LEN=20) :: str

        WRITE(str, '(I0)') i
        str = TRIM(ADJUSTL(str))
    END FUNCTION INT_TO_STR

    ! ==========================================================================
    ! Internal Function: 8-Byte Integer to String (for memory size logging)
    ! ==========================================================================
    FUNCTION INT8_TO_STR(i8) RESULT(str)
        INTEGER(KIND=8), INTENT(IN) :: i8
        CHARACTER(LEN=30) :: str

        WRITE(str, '(I0)') i8
        str = TRIM(ADJUSTL(str))
    END FUNCTION INT8_TO_STR

    ! ==========================================================================
    ! Subroutine: Update Device Status (Idle/Busy/Offline)
    ! ==========================================================================
    SUBROUTINE update_device_status(dev_id, new_status, status)
        INTEGER(i4), INTENT(IN) :: dev_id          ! Device ID
        INTEGER(i4), INTENT(IN) :: new_status      ! New status (IF_DEV_STATUS_*)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Pre-check 2: Valid new status
        IF (new_status /= IF_DEV_STATUS_IDLE .AND. new_status /= IF_DEV_STATUS_BUSY .AND. &
            new_status /= IF_DEV_STATUS_OFFLINE) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Invalid device status (1=idle, 2=busy, 3=offline)"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Find device and update status
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id) THEN
                ! Prevent status update for offline devices
                IF (global_dev_mgr%dev_list(i)%device_status == IF_DEV_STATUS_OFFLINE .AND. &
                    new_status /= IF_DEV_STATUS_OFFLINE) THEN
                    status%status_code = IF_STATUS_DEV_OFFLINE
                    WRITE(status%message, '(A,I0,A)') "Cannot update status for offline device ID ", dev_id
                    CALL log_error("DeviceManager", TRIM(status%message))
                    RETURN
                END IF

                ! Update status and log (use dev_status_to_str for readability)
                global_dev_mgr%dev_list(i)%device_status = new_status
                CALL log_info("DeviceManager", "Updated device "//TRIM(INT_TO_STR(dev_id))//&
                              " status to "//TRIM(dev_status_to_str(new_status)))
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Device not found
        status%status_code = IF_STATUS_DEV_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " not found"
        CALL log_error("DeviceManager", TRIM(status%message))
    END SUBROUTINE update_device_status

    ! ==========================================================================
    ! Internal Function: Convert Device Status to String (IF_DEV_STATUS_* to readable string)
    ! ==========================================================================
    FUNCTION dev_status_to_str(status_code) RESULT(status_str)
        INTEGER(i4), INTENT(IN) :: status_code  ! Input: Device status code (IF_DEV_STATUS_*)
        CHARACTER(LEN=10) :: status_str     ! Output: Status string ("Idle"/"Busy"/"Offline")

        SELECT CASE (status_code)
            CASE (IF_DEV_STATUS_IDLE)
                status_str = "Idle"
            CASE (IF_DEV_STATUS_BUSY)
                status_str = "Busy"
            CASE (IF_DEV_STATUS_OFFLINE)
                status_str = "Offline"
            CASE DEFAULT
                status_str = "Unknown"  ! Should not occur for valid status codes
        END SELECT
    END FUNCTION dev_status_to_str

    ! ==========================================================================
    ! Subroutine: Update Device Memory Usage (delta-based, used by memory pools)
    ! ==========================================================================
    SUBROUTINE update_device_memory_usage(dev_id, delta_mem, status)
        INTEGER(i4), INTENT(IN) :: dev_id      ! Device ID
        INTEGER(KIND=8), INTENT(IN) :: delta_mem ! Memory delta (bytes, can be negative)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)

        ! Pre-check 1: Whether manager is initialized
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Find device by ID
        DO i = 1, global_dev_mgr%current_dev_count
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id) THEN
                global_dev_mgr%dev_list(i)%used_mem = MAX(0_8, &
                    global_dev_mgr%dev_list(i)%used_mem + delta_mem)
                global_dev_mgr%dev_list(i)%free_mem = MAX(0_8, &
                    global_dev_mgr%dev_list(i)%total_mem - global_dev_mgr%dev_list(i)%used_mem)
                global_dev_mgr%dev_list(i)%last_query_time = get_timestamp_int()
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
        END DO

        ! Device not found
        status%status_code = IF_STATUS_DEV_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " not found for mem update"
        CALL log_error("DeviceManager", TRIM(status%message))
    END SUBROUTINE update_device_memory_usage

    ! ==========================================================================
    ! Subroutine: Get Detailed Device Information
    ! ==========================================================================
    SUBROUTINE get_device_info(dev_id, dev_info, status)
        INTEGER(i4), INTENT(IN) :: dev_id              ! Device ID
        TYPE(DeviceInfoType), INTENT(OUT) :: dev_info  ! Output device information
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        dev_info = DeviceInfoType()  ! Initialize device info to default values

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Find device and get information
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_id == dev_id) THEN
                dev_info = global_dev_mgr%dev_list(i)
                status%status_code = IF_STATUS_OK
                CALL log_debug("DeviceManager", "Got info for device "//TRIM(INT_TO_STR(dev_id))//&
                              " (type: "//TRIM(dev_type_to_str(dev_info%device_type))//")")
                RETURN
            END IF
        END DO

        ! Device not found
        status%status_code = IF_STATUS_DEV_NOT_FOUND
        WRITE(status%message, '(A,I0,A)') "Device ID ", dev_id, " not found"
        CALL log_error("DeviceManager", TRIM(status%message))
    END SUBROUTINE get_device_info

    ! ==========================================================================
    ! Subroutine: Get Current Count of Active Devices
    ! ==========================================================================
    SUBROUTINE get_active_device_count(count, status)
        INTEGER(i4), INTENT(OUT) :: count  ! Count of active devices
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i

        CALL init_error_status(status)
        count = 0

        ! Pre-check: Whether manager is initialized
        IF (.NOT. global_dev_mgr%initialized) THEN
            status%status_code = IF_STATUS_DEV_NOT_INIT
            status%message = "Device manager not initialized"
            CALL log_error("DeviceManager", TRIM(status%message))
            RETURN
        END IF

        ! Count active devices (exclude offline)
        DO i = 1, global_dev_mgr%max_devices
            IF (global_dev_mgr%dev_list(i)%device_status /= IF_DEV_STATUS_OFFLINE) THEN
                count = count + 1
            END IF
        END DO

        status%status_code = IF_STATUS_OK
        CALL log_debug("DeviceManager", "Current active device count: "//TRIM(INT_TO_STR(count)))
    END SUBROUTINE get_active_device_count

END MODULE IF_Device_Mgr