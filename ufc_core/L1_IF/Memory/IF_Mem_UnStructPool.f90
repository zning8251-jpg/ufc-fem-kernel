!===============================================================================
! MODULE: IF_Mem_UnStructPool
! LAYER:  L1_IF
! DOMAIN: Memory
! ROLE:   Impl — unstructured memory pool (adjacency/list/hash/skip/graph/queue)
! BRIEF:  Create/delete unstructured data; merged from UF_UnstructMemPool.
!===============================================================================

MODULE IF_Mem_UnStructPool
    USE IF_Err_Brg, ONLY: &
        ErrorStatusType, init_error_status, &
        log_debug, log_info, log_warn, log_error, &
        IF_STATUS_OK, IF_STATUS_ERROR, IF_STATUS_MEM_ERROR, IF_STATUS_NOT_FOUND, &
        IF_STATUS_INVALID, IF_STATUS_EXISTS
    USE IF_Device_Mgr, ONLY: &
        DeviceInfoType, init_device_mgr, destroy_device_mgr, &
        query_device_memory, update_device_status, update_device_memory_usage, &
        get_device_info, check_device_mem_suff, &
        IF_DEV_TYPE_CPU, IF_DEV_TYPE_GPU
    USE IF_Base_SymTbl, ONLY: &
        register_variable, unregister_variable, symbol_table_exists, &
        get_variable_data_id, &
        IF_STORAGE_TYPE_UNSTRUCTURED, &
        IF_DATA_TYPE_HASH, IF_DATA_TYPE_LINKED_LIST, IF_DATA_TYPE_ADJACENCY, &
        IF_DATA_TYPE_SKIP_LIST, IF_DATA_TYPE_GRAPH, IF_DATA_TYPE_QUEUE
    USE IF_Base_UnstructMeta_Def, ONLY: &
        UnstructMetaType, UnstructAttrType, &
        init_unstruct_meta_mgr, destroy_unstruct_meta_mgr, &
        unstruct_meta_create, unstruct_meta_query, unstruct_meta_try_query, unstruct_meta_update, &
        unstruct_meta_delete, get_unstruct_meta_count, &
        IF_STATUS_UNSMETA_NOT_INIT, IF_STATUS_UNSMETA_NOT_FOUND, &
        UNSTRUCT_TYPE_HASH, UNSTRUCT_TYPE_LINKED_LIST, UNSTRUCT_TYPE_ADJACENCY, &
        UNSTRUCT_TYPE_SKIP_LIST, UNSTRUCT_TYPE_GRAPH, UNSTRUCT_TYPE_QUEUE

    IMPLICIT NONE

    PRIVATE

    ! ------------------------------------------------------------------------
    ! Public procedures and types
    ! ------------------------------------------------------------------------
    PUBLIC :: EdgeDataType
    PUBLIC :: init_unstruct_mem_pool, destroy_unstruct_mem_pool
    PUBLIC :: create_unstruct_data, delete_unstruct_data

    PUBLIC :: get_unstruct_data_info, unstruct_data_exists

    ! Adjacency list / graph-like structure
    PUBLIC :: create_adjacency_list, get_adjacency_list_size
    PUBLIC :: adjacency_list_add_edge, adjacency_list_get_edges, adjacency_list_delete_edge

    ! Generic linked list (integer payload)
    PUBLIC :: create_linked_list, get_linked_list_size
    PUBLIC :: linked_list_insert, linked_list_delete, linked_list_get_values

    ! Hash table (string -> integer)
    PUBLIC :: create_hash_table, get_hash_table_size
    PUBLIC :: hash_table_insert, hash_table_get, hash_table_get_all

    ! Skip list (integer key -> variant value)
    PUBLIC :: create_skip_list
    PUBLIC :: skip_list_insert, skip_list_search, skip_list_delete
    PUBLIC :: get_skip_list_size, skip_list_get_all

    ! Graph (nodes + adjacency list)
    PUBLIC :: create_graph
    PUBLIC :: graph_add_node, graph_add_edge, graph_remove_node, graph_remove_edge
    PUBLIC :: get_graph_size, graph_get_edges, graph_bfs, graph_dfs

    ! Queue (ring buffer, homogeneous type)
    PUBLIC :: create_queue
    PUBLIC :: queue_enqueue, queue_dequeue, queue_peek
    PUBLIC :: get_queue_size, queue_get_all

    ! ------------------------------------------------------------------------
    ! Constants
    ! ------------------------------------------------------------------------
    INTEGER(i4), PARAMETER :: IF_MAX_UNSTRUCT_OBJECTS = 1024
    INTEGER(i4), PARAMETER :: DEVICE_CPU = IF_DEV_TYPE_CPU
    INTEGER(i4), PARAMETER :: DEVICE_GPU = IF_DEV_TYPE_GPU

    ! Simple data type tags for list/hash/queue payloads
    INTEGER(i4), PARAMETER :: IF_TYPE_UNKNOWN = 0
    INTEGER(i4), PARAMETER :: IF_TYPE_INT     = 1
    INTEGER(i4), PARAMETER :: IF_TYPE_DP      = 2
    INTEGER(i4), PARAMETER :: IF_TYPE_CHAR    = 3
    INTEGER(i4), PARAMETER :: IF_TYPE_EDGE    = 4

    INTEGER(i4), PARAMETER :: IF_DEFAULT_HASH_CAPACITY = 101
    INTEGER(i4), PARAMETER :: IF_SKIP_LIST_MAX_LEVEL   = 8

    ! ------------------------------------------------------------------------
    ! Core data structures
    ! ------------------------------------------------------------------------
    TYPE :: EdgeDataType
        INTEGER(i4) :: from_node = 0
        INTEGER(i4) :: to_node = 0
        REAL    :: weight   = 1.0
        LOGICAL :: is_directed = .FALSE.
        CHARACTER(LEN=64) :: label = ""
    END TYPE EdgeDataType

    TYPE :: ListNodeType
        INTEGER(i4) :: data_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_data  = 0
        REAL    :: real_data = 0.0
        CHARACTER(LEN=64) :: char_data = ""
        TYPE(EdgeDataType) :: edge_data
        TYPE(ListNodeType), POINTER :: prev => NULL()
        TYPE(ListNodeType), POINTER :: next => NULL()
    END TYPE ListNodeType

    TYPE :: LinkedListType
        INTEGER(i4) :: size = 0
        TYPE(ListNodeType), POINTER :: head => NULL()
        TYPE(ListNodeType), POINTER :: tail => NULL()
    END TYPE LinkedListType

    TYPE :: HashNodeType
        CHARACTER(LEN=64) :: key = ""
        INTEGER(i4) :: value_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_value  = 0
        REAL    :: real_value = 0.0
        CHARACTER(LEN=64) :: char_value = ""
        TYPE(HashNodeType), POINTER :: next => NULL()
    END TYPE HashNodeType

    TYPE :: HashBucketType
        TYPE(HashNodeType), POINTER :: head => NULL()
    END TYPE HashBucketType

    TYPE :: HashTableType
        INTEGER(i4) :: capacity = 0
        INTEGER(i4) :: count    = 0
        REAL    :: load_factor = 0.7
        TYPE(HashBucketType), ALLOCATABLE :: buckets(:)
    END TYPE HashTableType

    TYPE :: AdjacencyListType
        INTEGER(i4) :: num_nodes = 0
        LOGICAL :: is_directed = .FALSE.
        TYPE(LinkedListType), ALLOCATABLE :: adj(:)
        INTEGER(i4) :: edge_count = 0
    END TYPE AdjacencyListType

    ! ---------------- Skip list types (implemented as a simple sorted singly linked list) ----------------
    TYPE :: SkipListNodeType
        INTEGER(i4) :: key = 0
        INTEGER(i4) :: value_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_value = 0
        REAL    :: real_value = 0.0
        CHARACTER(LEN=64) :: char_value = ""
        TYPE(SkipListNodeType), POINTER :: next => NULL()
    END TYPE SkipListNodeType

    TYPE :: SkipListType
        INTEGER(i4) :: size  = 0
        REAL    :: probability = 0.5
        TYPE(SkipListNodeType), POINTER :: header => NULL()
    END TYPE SkipListType

    ! ---------------- Graph types ----------------
    TYPE :: GraphNodeType
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: data_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_data = 0
        REAL    :: real_data = 0.0
        CHARACTER(LEN=64) :: char_data = ""
    END TYPE GraphNodeType

    TYPE :: GraphType
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_edges = 0
        LOGICAL :: is_directed = .FALSE.
        LOGICAL :: is_weighted = .FALSE.
        TYPE(GraphNodeType), ALLOCATABLE :: nodes(:)
        TYPE(AdjacencyListType) :: adjacency_list
    END TYPE GraphType

    ! ---------------- Queue type ----------------
    TYPE :: QueueType
        INTEGER(i4) :: max_size      = 0
        INTEGER(i4) :: current_size  = 0
        INTEGER(i4) :: front         = 1
        INTEGER(i4) :: rear          = 0
        LOGICAL :: is_circular   = .FALSE.
        LOGICAL :: is_full       = .FALSE.
        INTEGER(i4) :: data_type     = IF_TYPE_UNKNOWN
        INTEGER, ALLOCATABLE :: int_data(:)
        REAL,    ALLOCATABLE :: real_data(:)
        CHARACTER(LEN=64), ALLOCATABLE :: char_data(:)
    END TYPE QueueType

    TYPE :: UnstructObjectDataType
        TYPE(AdjacencyListType) :: adjacency_list
        TYPE(LinkedListType)    :: generic_list
        TYPE(HashTableType)     :: hash_table
        TYPE(SkipListType)      :: skip_list
        TYPE(GraphType)         :: graph
        TYPE(QueueType)         :: queue
    END TYPE UnstructObjectDataType

    TYPE :: UnstructObjectType
        CHARACTER(LEN=64) :: data_id  = ""
        CHARACTER(LEN=64) :: var_name = ""
        INTEGER(i4) :: unstruct_type = 0              ! UNSTRUCT_TYPE_* constants
        INTEGER(i4) :: device_id = DEVICE_CPU
        LOGICAL :: is_allocated = .FALSE.
        LOGICAL :: is_persistent = .FALSE.
        CHARACTER(LEN=256) :: file_path = ""
        INTEGER(KIND=8) :: mem_size = 0_8
        TYPE(UnstructObjectDataType) :: data
    END TYPE UnstructObjectType

    TYPE :: UnstructMemPoolType
        LOGICAL :: initialized = .FALSE.
        INTEGER(i4) :: max_objects = IF_MAX_UNSTRUCT_OBJECTS
        INTEGER(i4) :: used_objects = 0
        TYPE(UnstructObjectType), ALLOCATABLE :: objects(:)
    END TYPE UnstructMemPoolType

    TYPE(UnstructMemPoolType), SAVE :: global_unstruct_pool

CONTAINS

    ! Internal: find index of object by data_id (0 if not found)
    INTEGER FUNCTION find_object_index(data_id) RESULT(idx)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4) :: i
        idx = 0
        IF (.NOT. global_unstruct_pool%initialized) RETURN
        IF (.NOT. ALLOCATED(global_unstruct_pool%objects)) RETURN
        DO i = 1, SIZE(global_unstruct_pool%objects)
            IF (global_unstruct_pool%objects(i)%is_allocated .AND. &
                TRIM(global_unstruct_pool%objects(i)%data_id) == TRIM(data_id)) THEN
                idx = i
                RETURN
            END IF
        END DO
    END FUNCTION find_object_index

    LOGICAL FUNCTION unstruct_data_exists(data_id) RESULT(exists)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        exists = (find_object_index(data_id) /= 0)
    END FUNCTION unstruct_data_exists

    ! Internal: simple string hash for hash table (returns 1..cap)
    INTEGER FUNCTION simple_hash(key, cap) RESULT(h)
        CHARACTER(LEN=*), INTENT(IN) :: key
        INTEGER(i4), INTENT(IN) :: cap
        INTEGER(i4) :: i
        h = 0
        DO i = 1, LEN_TRIM(key)
            h = 31 * h + IACHAR(key(i:i))
        END DO
        h = MOD(ABS(h), cap) + 1
    END FUNCTION simple_hash

    SUBROUTINE adjacency_list_add_edge(data_id, from_node, to_node, weight, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        REAL,             INTENT(IN), OPTIONAL :: weight
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        REAL :: w
        LOGICAL :: is_directed

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Adjacency list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_ADJACENCY) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not an adjacency list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (from_node < 1 .OR. to_node < 1 .OR. &
            from_node > global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes .OR. &
            to_node   > global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid node index in adjacency_list_add_edge"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        w = 1.0
        IF (PRESENT(weight)) w = weight

        is_directed = global_unstruct_pool%objects(idx)%data%adjacency_list%is_directed

        CALL insert_single_edge(idx, from_node, to_node, w, is_directed, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        IF (.NOT. is_directed .AND. from_node /= to_node) THEN
            CALL insert_single_edge(idx, to_node, from_node, w, is_directed, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count = &
            global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count + 1

        CALL log_debug("UnstructMemPool", &
            "Added edge "//TRIM(WRITE_INT(from_node))//"->"//TRIM(WRITE_INT(to_node))// &
            " for adjacency list: "//TRIM(data_id))
    END SUBROUTINE adjacency_list_add_edge

    SUBROUTINE adjacency_list_delete_edge(data_id, from_node, to_node, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        LOGICAL :: is_directed
        TYPE(ListNodeType), POINTER :: current, prev
        LOGICAL :: found

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Adjacency list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_ADJACENCY) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not an adjacency list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (from_node < 1 .OR. to_node < 1 .OR. &
            from_node > global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes .OR. &
            to_node   > global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid node index in adjacency_list_delete_edge"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        is_directed = global_unstruct_pool%objects(idx)%data%adjacency_list%is_directed

        !   from_node -> to_node  
        found = .FALSE.
        prev => NULL()
        current => global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%head

        DO WHILE (ASSOCIATED(current))
            IF (current%edge_data%to_node == to_node) THEN
                IF (ASSOCIATED(prev)) THEN
                    prev%next => current%next
                ELSE
                    global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%head => current%next
                END IF

                IF (.NOT. ASSOCIATED(current%next)) THEN
                    global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%tail => prev
                END IF

                DEALLOCATE(current)
                global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%size = &
                    global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%size - 1
                found = .TRUE.
                EXIT
            END IF
            prev => current
            current => current%next
        END DO

        IF (.NOT. found) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Edge not found in adjacency list"
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        !   to_node -> from_node
        IF (.NOT. is_directed .AND. from_node /= to_node) THEN
            prev => NULL()
            current => global_unstruct_pool%objects(idx)%data%adjacency_list%adj(to_node)%head

            DO WHILE (ASSOCIATED(current))
                IF (current%edge_data%to_node == from_node) THEN
                    IF (ASSOCIATED(prev)) THEN
                        prev%next => current%next
                    ELSE
                        global_unstruct_pool%objects(idx)%data%adjacency_list%adj(to_node)%head => current%next
                    END IF

                    IF (.NOT. ASSOCIATED(current%next)) THEN
                        global_unstruct_pool%objects(idx)%data%adjacency_list%adj(to_node)%tail => prev
                    END IF

                    DEALLOCATE(current)
                    global_unstruct_pool%objects(idx)%data%adjacency_list%adj(to_node)%size = &
                        global_unstruct_pool%objects(idx)%data%adjacency_list%adj(to_node)%size - 1
                    EXIT
                END IF
                prev => current
                current => current%next
            END DO
        END IF

        !  ?? 1?
        IF (global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count > 0) THEN
            global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count = &
                global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count - 1
        END IF

        CALL log_debug("UnstructMemPool", &
            "Deleted edge "//TRIM(WRITE_INT(from_node))//"->"//TRIM(WRITE_INT(to_node))// &
            " from adjacency list: "//TRIM(data_id))

        status%status_code = IF_STATUS_OK
    END SUBROUTINE adjacency_list_delete_edge

    SUBROUTINE adjacency_list_get_edges(data_id, node_id, edges, edge_count, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(EdgeDataType), ALLOCATABLE, INTENT(OUT) :: edges(:)
        INTEGER(i4), INTENT(OUT) :: edge_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, n, i
        TYPE(ListNodeType), POINTER :: current

        CALL init_error_status(status)
        edge_count = 0
        IF (ALLOCATED(edges)) DEALLOCATE(edges)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Adjacency list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_ADJACENCY) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not an adjacency list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        n = global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes
        IF (node_id < 1 .OR. node_id > n) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid node index in adjacency_list_get_edges"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        edge_count = global_unstruct_pool%objects(idx)%data%adjacency_list%adj(node_id)%size
        IF (edge_count <= 0) THEN
            RETURN
        END IF

        ALLOCATE(edges(edge_count))

        current => global_unstruct_pool%objects(idx)%data%adjacency_list%adj(node_id)%head
        i = 1
        DO WHILE (ASSOCIATED(current) .AND. i <= edge_count)
            edges(i) = current%edge_data
            current => current%next
            i = i + 1
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE adjacency_list_get_edges

    SUBROUTINE create_adjacency_list(data_id, var_name, num_nodes, is_directed, &
                                     device_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: num_nodes
        LOGICAL, INTENT(IN) :: is_directed
        INTEGER, INTENT(IN), OPTIONAL :: device_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructAttrType) :: attr
        INTEGER(i4) :: idx, dev_id

        CALL init_error_status(status)

        IF (num_nodes < 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "num_nodes must be non-negative"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id

        attr = UnstructAttrType()
        attr%graph_vertex_count = num_nodes
        attr%graph_edge_count   = 0_8
        attr%graph_is_directed  = is_directed

        CALL create_unstruct_data(data_id, var_name, UNSTRUCT_TYPE_ADJACENCY, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate adjacency list in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes   = num_nodes
        global_unstruct_pool%objects(idx)%data%adjacency_list%is_directed = is_directed
        global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count  = 0

        IF (num_nodes > 0) THEN
            ALLOCATE(global_unstruct_pool%objects(idx)%data%adjacency_list%adj(num_nodes))
        END IF

        CALL log_info("UnstructMemPool", &
            "Created adjacency list: data_id='"//TRIM(data_id)//"', nodes="//TRIM(WRITE_INT(num_nodes)))
    END SUBROUTINE create_adjacency_list

    SUBROUTINE create_graph(data_id, var_name, num_nodes, status, is_directed, is_weighted, device_id)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: num_nodes
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL, INTENT(IN), OPTIONAL :: is_directed, is_weighted
        INTEGER, INTENT(IN), OPTIONAL :: device_id

        INTEGER(i4) :: idx, dev_id, ierr, i
        LOGICAL :: gdir, gwei
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (num_nodes < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Number of nodes must be positive"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id
        gdir = .FALSE.
        IF (PRESENT(is_directed)) gdir = is_directed
        gwei = .FALSE.
        IF (PRESENT(is_weighted)) gwei = is_weighted

        attr = UnstructAttrType()
        attr%graph_vertex_count = num_nodes
        attr%graph_edge_count   = 0_8
        attr%graph_is_directed  = gdir

        CALL create_unstruct_data(data_id, var_name, IF_DATA_TYPE_GRAPH, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate graph in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%graph%num_nodes = num_nodes
        global_unstruct_pool%objects(idx)%data%graph%num_edges = 0
        global_unstruct_pool%objects(idx)%data%graph%is_directed = gdir
        global_unstruct_pool%objects(idx)%data%graph%is_weighted = gwei

        ALLOCATE(global_unstruct_pool%objects(idx)%data%graph%nodes(num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate graph nodes (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, num_nodes
            global_unstruct_pool%objects(idx)%data%graph%nodes(i)%node_id   = i
            global_unstruct_pool%objects(idx)%data%graph%nodes(i)%data_type = IF_TYPE_UNKNOWN
            global_unstruct_pool%objects(idx)%data%graph%nodes(i)%int_data  = 0
            global_unstruct_pool%objects(idx)%data%graph%nodes(i)%real_data = 0.0
            global_unstruct_pool%objects(idx)%data%graph%nodes(i)%char_data = ""
        END DO

        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%num_nodes   = num_nodes
        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%is_directed = gdir
        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%edge_count  = 0

        ALLOCATE(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate graph adjacency lists (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, num_nodes
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(i)%size = 0
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(i)%head => NULL()
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(i)%tail => NULL()
        END DO

        CALL log_info("UnstructMemPool", &
            "Created graph: data_id='"//TRIM(data_id)//"', nodes="//TRIM(WRITE_INT(num_nodes)))
    END SUBROUTINE create_graph

    SUBROUTINE create_hash_table(data_id, var_name, initial_capacity, device_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER, INTENT(IN), OPTIONAL :: initial_capacity
        INTEGER, INTENT(IN), OPTIONAL :: device_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructAttrType) :: attr
        INTEGER(i4) :: idx, dev_id, cap, i, ierr

        CALL init_error_status(status)

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id

        cap = IF_DEFAULT_HASH_CAPACITY
        IF (PRESENT(initial_capacity)) THEN
            IF (initial_capacity > 0) cap = initial_capacity
        END IF

        attr = UnstructAttrType()
        attr%hash_bucket_count = cap
        attr%hash_load_factor  = 0.0

        CALL create_unstruct_data(data_id, var_name, UNSTRUCT_TYPE_HASH, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate hash table in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%hash_table%capacity = cap
        global_unstruct_pool%objects(idx)%data%hash_table%count    = 0
        global_unstruct_pool%objects(idx)%data%hash_table%load_factor = 0.7

        ALLOCATE(global_unstruct_pool%objects(idx)%data%hash_table%buckets(cap), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate hash table buckets (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, cap
            global_unstruct_pool%objects(idx)%data%hash_table%buckets(i)%head => NULL()
        END DO

        CALL log_info("UnstructMemPool", &
            "Created hash table: data_id='"//TRIM(data_id)//"', capacity="//TRIM(WRITE_INT(cap)))
    END SUBROUTINE create_hash_table

    SUBROUTINE create_linked_list(data_id, var_name, device_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER, INTENT(IN), OPTIONAL :: device_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(UnstructAttrType) :: attr
        INTEGER(i4) :: idx, dev_id

        CALL init_error_status(status)

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id

        attr = UnstructAttrType()
        attr%list_is_circular = .FALSE.
        attr%list_is_double   = .TRUE.

        CALL create_unstruct_data(data_id, var_name, IF_DATA_TYPE_LINKED_LIST, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate linked list in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%generic_list%size = 0
        global_unstruct_pool%objects(idx)%data%generic_list%head => NULL()
        global_unstruct_pool%objects(idx)%data%generic_list%tail => NULL()

        CALL log_info("UnstructMemPool", &
            "Created generic linked list: data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE create_linked_list

    SUBROUTINE create_queue(data_id, var_name, max_size, status, is_circular, device_id)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: max_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        LOGICAL, INTENT(IN), OPTIONAL :: is_circular
        INTEGER, INTENT(IN), OPTIONAL :: device_id

        INTEGER(i4) :: idx, dev_id
        LOGICAL :: circ
        TYPE(UnstructAttrType) :: attr

        CALL init_error_status(status)

        IF (max_size < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Queue max_size must be positive"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id
        circ = .FALSE.
        IF (PRESENT(is_circular)) circ = is_circular

        attr = UnstructAttrType()
        attr%queue_capacity = max_size

        CALL create_unstruct_data(data_id, var_name, IF_DATA_TYPE_QUEUE, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate queue in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%queue%max_size = max_size
        global_unstruct_pool%objects(idx)%data%queue%current_size = 0
        global_unstruct_pool%objects(idx)%data%queue%front = 1
        global_unstruct_pool%objects(idx)%data%queue%rear  = 0
        global_unstruct_pool%objects(idx)%data%queue%is_circular = circ
        global_unstruct_pool%objects(idx)%data%queue%is_full = .FALSE.
        global_unstruct_pool%objects(idx)%data%queue%data_type = IF_TYPE_UNKNOWN

        CALL log_info("UnstructMemPool", &
            "Created queue: data_id='"//TRIM(data_id)//"', max_size="//TRIM(WRITE_INT(max_size)))
    END SUBROUTINE create_queue

    SUBROUTINE create_skip_list(data_id, var_name, status, probability, device_id)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        REAL, INTENT(IN), OPTIONAL :: probability
        INTEGER, INTENT(IN), OPTIONAL :: device_id

        TYPE(UnstructAttrType) :: attr
        INTEGER(i4) :: idx, dev_id, ierr
        REAL :: p

        CALL init_error_status(status)

        p = 0.5
        IF (PRESENT(probability)) THEN
            IF (probability > 0.0 .AND. probability < 1.0) p = probability
        END IF

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id

        attr = UnstructAttrType()

        CALL create_unstruct_data(data_id, var_name, IF_DATA_TYPE_SKIP_LIST, dev_id, attr, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Failed to locate skip list in pool after creation"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%skip_list%size  = 0
        global_unstruct_pool%objects(idx)%data%skip_list%probability = p

        ALLOCATE(global_unstruct_pool%objects(idx)%data%skip_list%header, STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate skip list header (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%skip_list%header%key        = 0
        global_unstruct_pool%objects(idx)%data%skip_list%header%value_type = IF_TYPE_UNKNOWN
        global_unstruct_pool%objects(idx)%data%skip_list%header%int_value  = 0
        global_unstruct_pool%objects(idx)%data%skip_list%header%real_value = 0.0
        global_unstruct_pool%objects(idx)%data%skip_list%header%char_value = ""
        NULLIFY(global_unstruct_pool%objects(idx)%data%skip_list%header%next)

        CALL log_info("UnstructMemPool", &
            "Created skip list: data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE create_skip_list

    SUBROUTINE create_unstruct_data(data_id, var_name, unstruct_type, device_id, &
                                    init_attr, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: var_name
        INTEGER(i4), INTENT(IN) :: unstruct_type
        INTEGER, INTENT(IN), OPTIONAL :: device_id
        TYPE(UnstructAttrType), INTENT(IN), OPTIONAL :: init_attr
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, dev_id
        TYPE(UnstructAttrType) :: local_attr
        TYPE(UnstructMetaType) :: meta
        LOGICAL :: has_meta

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (LEN_TRIM(data_id) == 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "data_id must not be empty"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (unstruct_data_exists(data_id)) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Unstructured data already exists: "//TRIM(data_id)
            CALL log_info("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        dev_id = DEVICE_CPU
        IF (PRESENT(device_id)) dev_id = device_id

        idx = 0
        DO WHILE (idx == 0)
            DO idx = 1, global_unstruct_pool%max_objects
                IF (.NOT. global_unstruct_pool%objects(idx)%is_allocated) EXIT
            END DO
            IF (idx == global_unstruct_pool%max_objects .AND. &
                global_unstruct_pool%objects(idx)%is_allocated) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                status%message = "Unstructured object pool is full"
                CALL log_error("UnstructMemPool", TRIM(status%message))
                RETURN
            END IF
        END DO

        local_attr = UnstructAttrType()
        IF (PRESENT(init_attr)) local_attr = init_attr

        IF (.NOT. symbol_table_exists(TRIM(var_name), status)) THEN
            CALL register_variable(TRIM(var_name), TRIM(data_id), unstruct_type, &
                                   IF_STORAGE_TYPE_UNSTRUCTURED, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructMemPool", &
                    "register_variable failed: "//TRIM(status%message))
                RETURN
            END IF
        END IF

        CALL unstruct_meta_try_query(TRIM(data_id), 1, meta, has_meta, status)
        IF (status%status_code /= IF_STATUS_OK .AND. status%status_code /= IF_STATUS_UNSMETA_NOT_FOUND) THEN
            CALL log_error("UnstructMemPool", &
                "unstruct_meta_try_query failed: "//TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. has_meta) THEN
            CALL unstruct_meta_create(TRIM(var_name), unstruct_type, local_attr, meta, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                CALL log_error("UnstructMemPool", &
                    "unstruct_meta_create failed: "//TRIM(status%message))
                RETURN
            END IF
        ELSE
            IF (meta%unstruct_type /= unstruct_type) THEN
                status%status_code = IF_STATUS_INVALID
                status%message = "Existing unstructured metadata type mismatch in create_unstruct_data"
                CALL log_error("UnstructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF

        global_unstruct_pool%objects(idx)%data_id = TRIM(data_id)
        global_unstruct_pool%objects(idx)%var_name = TRIM(var_name)
        global_unstruct_pool%objects(idx)%unstruct_type = unstruct_type
        global_unstruct_pool%objects(idx)%device_id = dev_id
        global_unstruct_pool%objects(idx)%is_allocated = .TRUE.
        global_unstruct_pool%objects(idx)%mem_size = meta%total_size

        global_unstruct_pool%used_objects = global_unstruct_pool%used_objects + 1

        CALL update_device_memory_usage(dev_id, meta%total_size, status)

        CALL log_info("UnstructMemPool", &
            "Created unstructured object: data_id='"//TRIM(data_id)//"', var='"//TRIM(var_name)//"'")
    END SUBROUTINE create_unstruct_data

    SUBROUTINE delete_unstruct_data(data_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, b
        TYPE(UnstructMetaType) :: meta
        TYPE(ListNodeType), POINTER :: cur, nxt
        TYPE(HashNodeType), POINTER :: hcur, hnxt
        TYPE(SkipListNodeType), POINTER :: scur, snext

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Unstructured data not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        CALL unstruct_meta_query(TRIM(data_id), 1, meta, status)
        IF (status%status_code == IF_STATUS_OK) THEN
            CALL update_device_memory_usage(global_unstruct_pool%objects(idx)%device_id, &
                                            -meta%total_size, status)
        END IF

        CALL unstruct_meta_delete(TRIM(data_id), status)

        ! Clear adjacency list array
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%adjacency_list%adj)) THEN
            DO b = 1, SIZE(global_unstruct_pool%objects(idx)%data%adjacency_list%adj)
                cur => global_unstruct_pool%objects(idx)%data%adjacency_list%adj(b)%head
                DO WHILE (ASSOCIATED(cur))
                    nxt => cur%next
                    DEALLOCATE(cur)
                    cur => nxt
                END DO
            END DO
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%adjacency_list%adj)
        END IF
        global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes = 0
        global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count = 0
        global_unstruct_pool%objects(idx)%data%adjacency_list%is_directed = .FALSE.

        ! Clear generic linked list
        cur => global_unstruct_pool%objects(idx)%data%generic_list%head
        DO WHILE (ASSOCIATED(cur))
            nxt => cur%next
            DEALLOCATE(cur)
            cur => nxt
        END DO
        global_unstruct_pool%objects(idx)%data%generic_list%head => NULL()
        global_unstruct_pool%objects(idx)%data%generic_list%tail => NULL()
        global_unstruct_pool%objects(idx)%data%generic_list%size = 0

        ! Clear hash table
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%hash_table%buckets)) THEN
            DO b = 1, global_unstruct_pool%objects(idx)%data%hash_table%capacity
                hcur => global_unstruct_pool%objects(idx)%data%hash_table%buckets(b)%head
                DO WHILE (ASSOCIATED(hcur))
                    hnxt => hcur%next
                    DEALLOCATE(hcur)
                    hcur => hnxt
                END DO
                global_unstruct_pool%objects(idx)%data%hash_table%buckets(b)%head => NULL()
            END DO
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%hash_table%buckets)
        END IF
        global_unstruct_pool%objects(idx)%data%hash_table%capacity = 0
        global_unstruct_pool%objects(idx)%data%hash_table%count = 0

        ! Clear skip list
        scur => global_unstruct_pool%objects(idx)%data%skip_list%header
        DO WHILE (ASSOCIATED(scur))
            snext => scur%next
            DEALLOCATE(scur)
            scur => snext
        END DO
        global_unstruct_pool%objects(idx)%data%skip_list%header => NULL()
        global_unstruct_pool%objects(idx)%data%skip_list%size  = 0

        ! Clear graph
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%graph%nodes)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%graph%nodes)
        END IF
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)) THEN
            DO b = 1, SIZE(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)
                cur => global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(b)%head
                DO WHILE (ASSOCIATED(cur))
                    nxt => cur%next
                    DEALLOCATE(cur)
                    cur => nxt
                END DO
            END DO
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)
        END IF
        global_unstruct_pool%objects(idx)%data%graph%num_nodes = 0
        global_unstruct_pool%objects(idx)%data%graph%num_edges = 0

        ! Clear queue
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%int_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%int_data)
        END IF
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%real_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%real_data)
        END IF
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%char_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%char_data)
        END IF
        global_unstruct_pool%objects(idx)%data%queue%max_size = 0
        global_unstruct_pool%objects(idx)%data%queue%current_size = 0
        global_unstruct_pool%objects(idx)%data%queue%front = 1
        global_unstruct_pool%objects(idx)%data%queue%rear  = 0
        global_unstruct_pool%objects(idx)%data%queue%is_circular = .FALSE.
        global_unstruct_pool%objects(idx)%data%queue%is_full = .FALSE.
        global_unstruct_pool%objects(idx)%data%queue%data_type = IF_TYPE_UNKNOWN

        global_unstruct_pool%objects(idx)%data_id = ""
        global_unstruct_pool%objects(idx)%var_name = ""
        global_unstruct_pool%objects(idx)%unstruct_type = 0
        global_unstruct_pool%objects(idx)%device_id = DEVICE_CPU
        global_unstruct_pool%objects(idx)%is_allocated = .FALSE.
        global_unstruct_pool%objects(idx)%is_persistent = .FALSE.
        global_unstruct_pool%objects(idx)%file_path = ""
        global_unstruct_pool%objects(idx)%mem_size = 0_8

        IF (global_unstruct_pool%used_objects > 0) THEN
            global_unstruct_pool%used_objects = global_unstruct_pool%used_objects - 1
        END IF

        CALL log_info("UnstructMemPool", &
            "Deleted unstructured object: data_id='"//TRIM(data_id)//"'")
    END SUBROUTINE delete_unstruct_data

    SUBROUTINE destroy_unstruct_mem_pool(status)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER(i4) :: i, ierr, b
        TYPE(ListNodeType), POINTER :: cur, nxt
        TYPE(HashNodeType), POINTER :: hcur, hnxt
        TYPE(SkipListNodeType), POINTER :: scur, snext

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        IF (ALLOCATED(global_unstruct_pool%objects)) THEN
            DO i = 1, global_unstruct_pool%max_objects
                IF (global_unstruct_pool%objects(i)%is_allocated) THEN
                    ! ----- Clear generic linked list -----
                    cur => global_unstruct_pool%objects(i)%data%generic_list%head
                    DO WHILE (ASSOCIATED(cur))
                        nxt => cur%next
                        DEALLOCATE(cur)
                        cur => nxt
                    END DO
                    global_unstruct_pool%objects(i)%data%generic_list%head => NULL()
                    global_unstruct_pool%objects(i)%data%generic_list%tail => NULL()
                    global_unstruct_pool%objects(i)%data%generic_list%size = 0

                    ! ----- Clear adjacency list -----
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%adjacency_list%adj)) THEN
                        DO b = 1, SIZE(global_unstruct_pool%objects(i)%data%adjacency_list%adj)
                            cur => global_unstruct_pool%objects(i)%data%adjacency_list%adj(b)%head
                            DO WHILE (ASSOCIATED(cur))
                                nxt => cur%next
                                DEALLOCATE(cur)
                                cur => nxt
                            END DO
                        END DO
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%adjacency_list%adj)
                    END IF
                    global_unstruct_pool%objects(i)%data%adjacency_list%num_nodes = 0
                    global_unstruct_pool%objects(i)%data%adjacency_list%edge_count = 0
                    global_unstruct_pool%objects(i)%data%adjacency_list%is_directed = .FALSE.

                    ! ----- Clear hash table -----
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%hash_table%buckets)) THEN
                        DO b = 1, global_unstruct_pool%objects(i)%data%hash_table%capacity
                            hcur => global_unstruct_pool%objects(i)%data%hash_table%buckets(b)%head
                            DO WHILE (ASSOCIATED(hcur))
                                hnxt => hcur%next
                                DEALLOCATE(hcur)
                                hcur => hnxt
                            END DO
                            global_unstruct_pool%objects(i)%data%hash_table%buckets(b)%head => NULL()
                        END DO
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%hash_table%buckets)
                    END IF
                    global_unstruct_pool%objects(i)%data%hash_table%capacity = 0
                    global_unstruct_pool%objects(i)%data%hash_table%count = 0

                    ! ----- Clear skip list -----
                    scur => global_unstruct_pool%objects(i)%data%skip_list%header
                    DO WHILE (ASSOCIATED(scur))
                        snext => scur%next
                        DEALLOCATE(scur)
                        scur => snext
                    END DO
                    global_unstruct_pool%objects(i)%data%skip_list%header => NULL()
                    global_unstruct_pool%objects(i)%data%skip_list%size  = 0

                    ! ----- Clear graph -----
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%graph%nodes)) THEN
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%graph%nodes)
                    END IF
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%graph%adjacency_list%adj)) THEN
                        DO b = 1, SIZE(global_unstruct_pool%objects(i)%data%graph%adjacency_list%adj)
                            cur => global_unstruct_pool%objects(i)%data%graph%adjacency_list%adj(b)%head
                            DO WHILE (ASSOCIATED(cur))
                                nxt => cur%next
                                DEALLOCATE(cur)
                                cur => nxt
                            END DO
                        END DO
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%graph%adjacency_list%adj)
                    END IF
                    global_unstruct_pool%objects(i)%data%graph%num_nodes = 0
                    global_unstruct_pool%objects(i)%data%graph%num_edges = 0

                    ! ----- Clear queue -----
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%queue%int_data)) THEN
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%queue%int_data)
                    END IF
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%queue%real_data)) THEN
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%queue%real_data)
                    END IF
                    IF (ALLOCATED(global_unstruct_pool%objects(i)%data%queue%char_data)) THEN
                        DEALLOCATE(global_unstruct_pool%objects(i)%data%queue%char_data)
                    END IF
                    global_unstruct_pool%objects(i)%data%queue%max_size = 0
                    global_unstruct_pool%objects(i)%data%queue%current_size = 0
                    global_unstruct_pool%objects(i)%data%queue%front = 1
                    global_unstruct_pool%objects(i)%data%queue%rear  = 0
                    global_unstruct_pool%objects(i)%data%queue%is_circular = .FALSE.
                    global_unstruct_pool%objects(i)%data%queue%is_full = .FALSE.
                    global_unstruct_pool%objects(i)%data%queue%data_type = IF_TYPE_UNKNOWN
                END IF
            END DO

            DEALLOCATE(global_unstruct_pool%objects, STAT=ierr)
            IF (ierr /= 0) THEN
                status%status_code = IF_STATUS_MEM_ERROR
                WRITE(status%message, '(A,I0,A)') &
                    "Failed to deallocate unstructured object array (stat=", ierr, ")"
                CALL log_error("UnstructMemPool", TRIM(status%message))
            END IF
        END IF

        global_unstruct_pool%initialized = .FALSE.
        global_unstruct_pool%max_objects = 0
        global_unstruct_pool%used_objects = 0

        CALL destroy_unstruct_meta_mgr(status)
        CALL destroy_device_mgr(status)

        CALL log_info("UnstructMemPool", "Destroyed unstructured memory pool")
    END SUBROUTINE destroy_unstruct_mem_pool

    SUBROUTINE get_adjacency_list_size(data_id, num_nodes, edge_count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: num_nodes
        INTEGER(i4), INTENT(OUT) :: edge_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        num_nodes = 0
        edge_count = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Adjacency list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_ADJACENCY) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not an adjacency list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        num_nodes = global_unstruct_pool%objects(idx)%data%adjacency_list%num_nodes
        edge_count = global_unstruct_pool%objects(idx)%data%adjacency_list%edge_count
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_adjacency_list_size

    SUBROUTINE get_graph_size(data_id, num_nodes, num_edges, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: num_nodes
        INTEGER(i4), INTENT(OUT) :: num_edges
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        num_nodes = 0
        num_edges = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        num_nodes = global_unstruct_pool%objects(idx)%data%graph%num_nodes
        num_edges = global_unstruct_pool%objects(idx)%data%graph%num_edges
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_graph_size

    SUBROUTINE get_hash_table_size(data_id, entry_count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: entry_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        entry_count = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Hash table not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_HASH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a hash table: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        entry_count = global_unstruct_pool%objects(idx)%data%hash_table%count
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_hash_table_size

    SUBROUTINE get_linked_list_size(data_id, list_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: list_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        list_size = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Linked list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_LINKED_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a linked list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        list_size = global_unstruct_pool%objects(idx)%data%generic_list%size
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_linked_list_size

    SUBROUTINE get_queue_size(data_id, queue_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: queue_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        queue_size = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Queue not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a queue: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        queue_size = global_unstruct_pool%objects(idx)%data%queue%current_size
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_queue_size

    SUBROUTINE get_skip_list_size(data_id, list_size, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: list_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        list_size = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Skip list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_SKIP_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a skip list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        list_size = global_unstruct_pool%objects(idx)%data%skip_list%size
        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_skip_list_size

    SUBROUTINE get_unstruct_data_info(data_id, unstruct_type, device_id, mem_size, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(OUT) :: unstruct_type
        INTEGER(i4), INTENT(OUT) :: device_id
        INTEGER(KIND=8), INTENT(OUT) :: mem_size
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx

        CALL init_error_status(status)
        unstruct_type = 0
        device_id = DEVICE_CPU
        mem_size = 0_8

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Unstructured data not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        unstruct_type = global_unstruct_pool%objects(idx)%unstruct_type
        device_id     = global_unstruct_pool%objects(idx)%device_id
        mem_size      = global_unstruct_pool%objects(idx)%mem_size

        status%status_code = IF_STATUS_OK
    END SUBROUTINE get_unstruct_data_info

    SUBROUTINE graph_add_edge(data_id, from_node, to_node, weight, label, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id, label
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        REAL,    INTENT(IN), OPTIONAL :: weight
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        REAL :: w
        TYPE(EdgeDataType) :: edge

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (from_node < 1 .OR. from_node > global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid from_node"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (to_node < 1 .OR. to_node > global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid to_node"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        w = 1.0
        IF (PRESENT(weight)) w = weight

        edge%from_node = from_node
        edge%to_node   = to_node
        edge%weight    = w
        edge%is_directed = global_unstruct_pool%objects(idx)%data%graph%is_directed
        edge%label     = TRIM(label)

        CALL insert_graph_edge(idx, from_node, edge, status)
        IF (status%status_code /= IF_STATUS_OK) RETURN

        IF (.NOT. global_unstruct_pool%objects(idx)%data%graph%is_directed .AND. from_node /= to_node) THEN
            edge%from_node = to_node
            edge%to_node   = from_node
            CALL insert_graph_edge(idx, to_node, edge, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%graph%num_edges = &
            global_unstruct_pool%objects(idx)%data%graph%num_edges + 1
        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%edge_count = &
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%edge_count + 1

        status%status_code = IF_STATUS_OK
    END SUBROUTINE graph_add_edge

    SUBROUTINE graph_add_node(data_id, node_id, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id, char_data
        INTEGER(i4), INTENT(IN) :: node_id, data_type, int_data
        REAL,    INTENT(IN) :: real_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, new_num_nodes, ierr, i
        TYPE(GraphNodeType), ALLOCATABLE :: tmp_nodes(:)
        TYPE(LinkedListType), ALLOCATABLE :: tmp_adj(:)

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (node_id < 1) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Node ID must be positive"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (node_id <= global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%data_type = data_type
            global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%int_data  = int_data
            global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%real_data = real_data
            global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%char_data = TRIM(char_data)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        new_num_nodes = node_id

        ALLOCATE(tmp_nodes(new_num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to expand graph nodes (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        DO i = 1, global_unstruct_pool%objects(idx)%data%graph%num_nodes
            tmp_nodes(i) = global_unstruct_pool%objects(idx)%data%graph%nodes(i)
        END DO

        DO i = global_unstruct_pool%objects(idx)%data%graph%num_nodes + 1, new_num_nodes
            tmp_nodes(i)%node_id   = i
            tmp_nodes(i)%data_type = IF_TYPE_UNKNOWN
            tmp_nodes(i)%int_data  = 0
            tmp_nodes(i)%real_data = 0.0
            tmp_nodes(i)%char_data = ""
        END DO

        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%graph%nodes)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%graph%nodes)
        END IF
        CALL MOVE_ALLOC(tmp_nodes, global_unstruct_pool%objects(idx)%data%graph%nodes)

        ALLOCATE(tmp_adj(new_num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to expand graph adjacency lists (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)) THEN
            DO i = 1, global_unstruct_pool%objects(idx)%data%graph%adjacency_list%num_nodes
                tmp_adj(i) = global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(i)
            END DO
        END IF

        DO i = global_unstruct_pool%objects(idx)%data%graph%adjacency_list%num_nodes + 1, new_num_nodes
            tmp_adj(i)%size = 0
            tmp_adj(i)%head => NULL()
            tmp_adj(i)%tail => NULL()
        END DO

        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)
        END IF
        CALL MOVE_ALLOC(tmp_adj, global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj)
        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%num_nodes = new_num_nodes

        global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%data_type = data_type
        global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%int_data  = int_data
        global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%real_data = real_data
        global_unstruct_pool%objects(idx)%data%graph%nodes(node_id)%char_data = TRIM(char_data)

        global_unstruct_pool%objects(idx)%data%graph%num_nodes = new_num_nodes

        status%status_code = IF_STATUS_OK
    END SUBROUTINE graph_add_node

    SUBROUTINE graph_bfs(data_id, start_node, visited, distances, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: start_node
        LOGICAL, ALLOCATABLE, INTENT(OUT) :: visited(:)
        INTEGER, ALLOCATABLE, INTENT(OUT) :: distances(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, num_nodes, ierr
        INTEGER, ALLOCATABLE :: queue(:)
        INTEGER(i4) :: front, rear
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)
        INTEGER(i4) :: edge_count, j
        INTEGER(i4) :: current_node, neighbor_node

        CALL init_error_status(status)

        IF (ALLOCATED(visited))   DEALLOCATE(visited)
        IF (ALLOCATED(distances)) DEALLOCATE(distances)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        num_nodes = global_unstruct_pool%objects(idx)%data%graph%num_nodes
        IF (start_node < 1 .OR. start_node > num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid start node in graph_bfs"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        ALLOCATE(visited(num_nodes), distances(num_nodes), queue(num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate BFS arrays (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        visited   = .FALSE.
        distances = -1
        front = 1
        rear  = 0

        rear = rear + 1
        queue(rear) = start_node
        visited(start_node)   = .TRUE.
        distances(start_node) = 0

        DO WHILE (front <= rear)
            current_node = queue(front)
            front = front + 1

            CALL graph_get_edges(data_id, current_node, edges, edge_count, status)
            IF (status%status_code /= IF_STATUS_OK) THEN
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
                DEALLOCATE(visited, distances, queue)
                RETURN
            END IF

            DO j = 1, edge_count
                neighbor_node = edges(j)%to_node
                IF (neighbor_node >= 1 .AND. neighbor_node <= num_nodes) THEN
                    IF (.NOT. visited(neighbor_node)) THEN
                        visited(neighbor_node) = .TRUE.
                        distances(neighbor_node) = distances(current_node) + 1
                        rear = rear + 1
                        IF (rear <= num_nodes) THEN
                            queue(rear) = neighbor_node
                        END IF
                    END IF
                END IF
            END DO

            IF (ALLOCATED(edges)) DEALLOCATE(edges)
        END DO

        DEALLOCATE(queue)
        status%status_code = IF_STATUS_OK

        CALL log_debug("UnstructMemPool", &
            "Completed graph BFS from node="//TRIM(WRITE_INT(start_node))// &
            " for graph: "//TRIM(data_id))
    END SUBROUTINE graph_bfs

    SUBROUTINE graph_dfs(data_id, start_node, visited, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: start_node
        LOGICAL, ALLOCATABLE, INTENT(OUT) :: visited(:)
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, num_nodes, ierr

        CALL init_error_status(status)

        IF (ALLOCATED(visited)) DEALLOCATE(visited)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        num_nodes = global_unstruct_pool%objects(idx)%data%graph%num_nodes
        IF (start_node < 1 .OR. start_node > num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid start node in graph_dfs"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        ALLOCATE(visited(num_nodes), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate DFS visited array (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        visited = .FALSE.

        CALL graph_dfs_visit(data_id, start_node, visited, num_nodes, status)

        IF (status%status_code /= IF_STATUS_OK) RETURN

        CALL log_debug("UnstructMemPool", &
            "Completed graph DFS from node="//TRIM(WRITE_INT(start_node))// &
            " for graph: "//TRIM(data_id))
    END SUBROUTINE graph_dfs

    RECURSIVE SUBROUTINE graph_dfs_visit(data_id, current_node, visited, num_nodes, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: current_node, num_nodes
        LOGICAL,          INTENT(INOUT) :: visited(:)
        TYPE(ErrorStatusType), INTENT(INOUT) :: status

        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)
        INTEGER(i4) :: edge_count, i, neighbor_node

        IF (status%status_code /= IF_STATUS_OK) RETURN

        IF (current_node < 1 .OR. current_node > num_nodes) RETURN

        IF (visited(current_node)) RETURN
        visited(current_node) = .TRUE.

        CALL graph_get_edges(data_id, current_node, edges, edge_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(edges)) DEALLOCATE(edges)
            RETURN
        END IF

        DO i = 1, edge_count
            neighbor_node = edges(i)%to_node
            IF (neighbor_node >= 1 .AND. neighbor_node <= num_nodes) THEN
                IF (.NOT. visited(neighbor_node)) THEN
                    CALL graph_dfs_visit(data_id, neighbor_node, visited, num_nodes, status)
                    IF (status%status_code /= IF_STATUS_OK) EXIT
                END IF
            END IF
        END DO

        IF (ALLOCATED(edges)) DEALLOCATE(edges)
    END SUBROUTINE graph_dfs_visit

    SUBROUTINE graph_get_edges(data_id, node_id, edges, edge_count, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(EdgeDataType), ALLOCATABLE, INTENT(OUT) :: edges(:)
        INTEGER(i4), INTENT(OUT) :: edge_count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, i
        TYPE(ListNodeType), POINTER :: cur

        CALL init_error_status(status)
        edge_count = 0
        IF (ALLOCATED(edges)) DEALLOCATE(edges)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (node_id < 1 .OR. node_id > global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid node_id"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        edge_count = global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%size
        IF (edge_count <= 0) RETURN

        ALLOCATE(edges(edge_count))
        cur => global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%head
        i = 1
        DO WHILE (ASSOCIATED(cur) .AND. i <= edge_count)
            edges(i) = cur%edge_data
            cur => cur%next
            i = i + 1
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE graph_get_edges

    SUBROUTINE graph_remove_edge(data_id, from_node, to_node, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: from_node, to_node
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        TYPE(ListNodeType), POINTER :: cur, prev

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (from_node < 1 .OR. from_node > global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid from_node"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        prev => NULL()
        cur => global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(from_node)%head
        DO WHILE (ASSOCIATED(cur))
            IF (cur%edge_data%to_node == to_node) THEN
                IF (ASSOCIATED(prev)) THEN
                    prev%next => cur%next
                ELSE
                    global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(from_node)%head => cur%next
                END IF
                IF (.NOT. ASSOCIATED(cur%next)) THEN
                    global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(from_node)%tail => prev
                END IF
                DEALLOCATE(cur)

                global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(from_node)%size = &
                    global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(from_node)%size - 1
                global_unstruct_pool%objects(idx)%data%graph%adjacency_list%edge_count = &
                    MAX(0, global_unstruct_pool%objects(idx)%data%graph%adjacency_list%edge_count - 1)
                global_unstruct_pool%objects(idx)%data%graph%num_edges = &
                    MAX(0, global_unstruct_pool%objects(idx)%data%graph%num_edges - 1)

                status%status_code = IF_STATUS_OK
                RETURN
            END IF
            prev => cur
            cur => cur%next
        END DO

        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "Edge not found in graph"
    END SUBROUTINE graph_remove_edge

    SUBROUTINE graph_remove_node(data_id, node_id, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: node_id
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, i
        TYPE(EdgeDataType), ALLOCATABLE :: edges(:)
        INTEGER(i4) :: edge_count

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Graph not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_GRAPH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a graph: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (node_id < 1 .OR. node_id > global_unstruct_pool%objects(idx)%data%graph%num_nodes) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Invalid node_id"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        CALL graph_get_edges(data_id, node_id, edges, edge_count, status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            IF (ALLOCATED(edges)) DEALLOCATE(edges)
            RETURN
        END IF

        DO i = 1, edge_count
            CALL graph_remove_edge(data_id, node_id, edges(i)%to_node, status)
        END DO
        IF (ALLOCATED(edges)) DEALLOCATE(edges)

        DO i = 1, global_unstruct_pool%objects(idx)%data%graph%num_nodes
            IF (i /= node_id) THEN
                CALL graph_get_edges(data_id, i, edges, edge_count, status)
                IF (status%status_code /= IF_STATUS_OK) EXIT
                DO WHILE (edge_count > 0)
                    CALL graph_remove_edge(data_id, i, node_id, status)
                    edge_count = edge_count - 1
                END DO
                IF (ALLOCATED(edges)) DEALLOCATE(edges)
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE graph_remove_node

    SUBROUTINE hash_table_get(data_id, key, found, value, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=*), INTENT(IN)  :: key
        LOGICAL,          INTENT(OUT) :: found
        INTEGER(i4), INTENT(OUT) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, h, cap
        TYPE(HashNodeType), POINTER :: node

        CALL init_error_status(status)
        found = .FALSE.
        value = 0

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Hash table not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_HASH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a hash table: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        cap = global_unstruct_pool%objects(idx)%data%hash_table%capacity
        IF (cap <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Hash table capacity is invalid"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        h = simple_hash(TRIM(key), cap)

        node => global_unstruct_pool%objects(idx)%data%hash_table%buckets(h)%head
        DO WHILE (ASSOCIATED(node))
            IF (TRIM(node%key) == TRIM(key)) THEN
                IF (node%value_type == IF_TYPE_INT) THEN
                    value = node%int_value
                ELSE
                    value = 0
                END IF
                found = .TRUE.
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
            node => node%next
        END DO

        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "Key not found in hash table"
    END SUBROUTINE hash_table_get

    SUBROUTINE hash_table_get_all(data_id, keys, values, count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        CHARACTER(LEN=*), ALLOCATABLE, INTENT(OUT) :: keys(:)
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: values(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, cap, i, pos
        TYPE(HashNodeType), POINTER :: node

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(keys))   DEALLOCATE(keys)
        IF (ALLOCATED(values)) DEALLOCATE(values)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Hash table not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_HASH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a hash table: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        count = global_unstruct_pool%objects(idx)%data%hash_table%count
        cap   = global_unstruct_pool%objects(idx)%data%hash_table%capacity

        IF (count <= 0 .OR. cap <= 0) THEN
            RETURN
        END IF

        ALLOCATE(keys(count))
        ALLOCATE(values(count))

        pos = 1
        DO i = 1, cap
            node => global_unstruct_pool%objects(idx)%data%hash_table%buckets(i)%head
            DO WHILE (ASSOCIATED(node) .AND. pos <= count)
                keys(pos)   = TRIM(node%key)
                IF (node%value_type == IF_TYPE_INT) THEN
                    values(pos) = node%int_value
                ELSE
                    values(pos) = 0
                END IF
                pos = pos + 1
                node => node%next
            END DO
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE hash_table_get_all

    SUBROUTINE hash_table_insert(data_id, key, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        CHARACTER(LEN=*), INTENT(IN) :: key
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, h, cap
        TYPE(HashNodeType), POINTER :: node, new_node

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Hash table not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_HASH) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a hash table: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        cap = global_unstruct_pool%objects(idx)%data%hash_table%capacity
        IF (cap <= 0) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Hash table capacity is invalid"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        h = simple_hash(TRIM(key), cap)

        node => global_unstruct_pool%objects(idx)%data%hash_table%buckets(h)%head
        DO WHILE (ASSOCIATED(node))
            IF (TRIM(node%key) == TRIM(key)) THEN
                node%value_type = IF_TYPE_INT
                node%int_value  = value
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
            node => node%next
        END DO

        ALLOCATE(new_node)
        new_node%key        = TRIM(key)
        new_node%value_type = IF_TYPE_INT
        new_node%int_value  = value
        new_node%real_value = 0.0
        new_node%char_value = ""
        new_node%next => global_unstruct_pool%objects(idx)%data%hash_table%buckets(h)%head
        global_unstruct_pool%objects(idx)%data%hash_table%buckets(h)%head => new_node

        global_unstruct_pool%objects(idx)%data%hash_table%count = &
            global_unstruct_pool%objects(idx)%data%hash_table%count + 1

        status%status_code = IF_STATUS_OK
    END SUBROUTINE hash_table_insert

    SUBROUTINE init_unstruct_mem_pool(status, max_objects)
        TYPE(ErrorStatusType), INTENT(OUT) :: status
        INTEGER, INTENT(IN), OPTIONAL :: max_objects
        INTEGER(i4) :: local_max, ierr

        CALL init_error_status(status)

        IF (global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_EXISTS
            status%message = "Unstructured memory pool already initialized"
            CALL log_info("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        local_max = IF_MAX_UNSTRUCT_OBJECTS
        IF (PRESENT(max_objects)) THEN
            IF (max_objects > 0) THEN
                local_max = max_objects
            ELSE
                status%status_code = IF_STATUS_INVALID
                status%message = "max_objects must be positive"
                CALL log_error("UnstructMemPool", TRIM(status%message))
                RETURN
            END IF
        END IF

        ALLOCATE(global_unstruct_pool%objects(local_max), STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate unstructured object array (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%max_objects = local_max
        global_unstruct_pool%used_objects = 0
        global_unstruct_pool%initialized = .TRUE.

        CALL init_unstruct_meta_mgr(status)
        IF (status%status_code /= IF_STATUS_OK .AND. &
            status%status_code /= IF_STATUS_UNSMETA_NOT_INIT) THEN
            CALL log_error("UnstructMemPool", &
                "init_unstruct_meta_mgr failed: "//TRIM(status%message))
        END IF

        CALL init_device_mgr(status)
        IF (status%status_code /= IF_STATUS_OK) THEN
            CALL log_warn("UnstructMemPool", &
                "init_device_mgr returned non-OK: "//TRIM(status%message))
        END IF

        status%status_code = IF_STATUS_OK
        CALL log_info("UnstructMemPool", "Initialized unstructured memory pool")
    END SUBROUTINE init_unstruct_mem_pool

    SUBROUTINE insert_graph_edge(idx, node_id, edge_data, status)
        INTEGER(i4), INTENT(IN) :: idx, node_id
        TYPE(EdgeDataType), INTENT(IN) :: edge_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ListNodeType), POINTER :: new_node

        CALL init_error_status(status)

        ALLOCATE(new_node)
        new_node%data_type = IF_TYPE_EDGE
        new_node%edge_data = edge_data
        new_node%prev => NULL()
        new_node%next => NULL()

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%head)) THEN
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%head => new_node
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%tail => new_node
        ELSE
            new_node%prev => global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%tail
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%tail%next => new_node
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%tail => new_node
        END IF

        global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%size = &
            global_unstruct_pool%objects(idx)%data%graph%adjacency_list%adj(node_id)%size + 1
    END SUBROUTINE insert_graph_edge

    SUBROUTINE insert_single_edge(idx, from_node, to_node, weight, is_directed, status)
        INTEGER(i4), INTENT(IN) :: idx, from_node, to_node
        REAL,    INTENT(IN) :: weight
        LOGICAL, INTENT(IN) :: is_directed
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        TYPE(ListNodeType), POINTER :: new_node

        CALL init_error_status(status)

        ALLOCATE(new_node)
        new_node%data_type           = IF_TYPE_EDGE
        new_node%edge_data%from_node   = from_node
        new_node%edge_data%to_node     = to_node
        new_node%edge_data%weight     = weight
        new_node%edge_data%is_directed = is_directed
        new_node%prev => NULL()
        new_node%next => NULL()

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%head)) THEN
            global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%head => new_node
            global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%tail => new_node
        ELSE
            global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%tail%next => new_node
            new_node%prev => global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%tail
            global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%tail => new_node
        END IF

        global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%size = &
            global_unstruct_pool%objects(idx)%data%adjacency_list%adj(from_node)%size + 1
    END SUBROUTINE insert_single_edge

    SUBROUTINE linked_list_delete(data_id, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        TYPE(ListNodeType), POINTER :: cur

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Linked list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_LINKED_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a linked list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        cur => global_unstruct_pool%objects(idx)%data%generic_list%head
        DO WHILE (ASSOCIATED(cur))
            IF (cur%data_type == IF_TYPE_INT .AND. cur%int_data == value) THEN
                IF (ASSOCIATED(cur%prev)) THEN
                    cur%prev%next => cur%next
                ELSE
                    global_unstruct_pool%objects(idx)%data%generic_list%head => cur%next
                END IF

                IF (ASSOCIATED(cur%next)) THEN
                    cur%next%prev => cur%prev
                ELSE
                    global_unstruct_pool%objects(idx)%data%generic_list%tail => cur%prev
                END IF

                DEALLOCATE(cur)
                global_unstruct_pool%objects(idx)%data%generic_list%size = &
                    global_unstruct_pool%objects(idx)%data%generic_list%size - 1
                status%status_code = IF_STATUS_OK
                RETURN
            END IF
            cur => cur%next
        END DO

        status%status_code = IF_STATUS_NOT_FOUND
        status%message = "Value not found in linked list"
    END SUBROUTINE linked_list_delete

    SUBROUTINE linked_list_get_values(data_id, values, count, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: values(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, i
        TYPE(ListNodeType), POINTER :: cur

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(values)) DEALLOCATE(values)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Linked list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_LINKED_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a linked list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        count = global_unstruct_pool%objects(idx)%data%generic_list%size
        IF (count <= 0) THEN
            RETURN
        END IF

        ALLOCATE(values(count))

        cur => global_unstruct_pool%objects(idx)%data%generic_list%head
        i = 1
        DO WHILE (ASSOCIATED(cur) .AND. i <= count)
            IF (cur%data_type == IF_TYPE_INT) THEN
                values(i) = cur%int_data
            ELSE
                values(i) = 0
            END IF
            cur => cur%next
            i = i + 1
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE linked_list_get_values

    SUBROUTINE linked_list_insert(data_id, value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        TYPE(ListNodeType), POINTER :: new_node

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Linked list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_LINKED_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a linked list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        ALLOCATE(new_node)
        new_node%data_type = IF_TYPE_INT
        new_node%int_data  = value
        new_node%real_data = 0.0
        new_node%char_data = ""
        new_node%prev => NULL()
        new_node%next => NULL()

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%generic_list%head)) THEN
            global_unstruct_pool%objects(idx)%data%generic_list%head => new_node
            global_unstruct_pool%objects(idx)%data%generic_list%tail => new_node
        ELSE
            global_unstruct_pool%objects(idx)%data%generic_list%tail%next => new_node
            new_node%prev => global_unstruct_pool%objects(idx)%data%generic_list%tail
            global_unstruct_pool%objects(idx)%data%generic_list%tail => new_node
        END IF

        global_unstruct_pool%objects(idx)%data%generic_list%size = &
            global_unstruct_pool%objects(idx)%data%generic_list%size + 1
    END SUBROUTINE linked_list_insert

    SUBROUTINE queue_allocate_storage(idx, data_type, status)
        INTEGER(i4), INTENT(IN) :: idx, data_type
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: n, ierr

        CALL init_error_status(status)

        n = global_unstruct_pool%objects(idx)%data%queue%max_size

        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%int_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%int_data)
        END IF
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%real_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%real_data)
        END IF
        IF (ALLOCATED(global_unstruct_pool%objects(idx)%data%queue%char_data)) THEN
            DEALLOCATE(global_unstruct_pool%objects(idx)%data%queue%char_data)
        END IF

        SELECT CASE (data_type)
        CASE (IF_TYPE_INT)
            ALLOCATE(global_unstruct_pool%objects(idx)%data%queue%int_data(n), STAT=ierr)
        CASE (IF_TYPE_DP)
            ALLOCATE(global_unstruct_pool%objects(idx)%data%queue%real_data(n), STAT=ierr)
        CASE (IF_TYPE_CHAR)
            ALLOCATE(global_unstruct_pool%objects(idx)%data%queue%char_data(n), STAT=ierr)
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported queue data_type"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END SELECT

        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate queue storage (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%queue%data_type = data_type
    END SUBROUTINE queue_allocate_storage

    SUBROUTINE queue_dequeue(data_id, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(OUT) :: data_type, int_data
        REAL,    INTENT(OUT) :: real_data
        CHARACTER(LEN=*), INTENT(OUT) :: char_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, pos

        CALL init_error_status(status)
        data_type = IF_TYPE_UNKNOWN
        int_data  = 0
        real_data = 0.0
        char_data = ""

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Queue not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a queue: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%data%queue%current_size == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Queue is empty"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        data_type = global_unstruct_pool%objects(idx)%data%queue%data_type
        pos = global_unstruct_pool%objects(idx)%data%queue%front

        SELECT CASE (data_type)
        CASE (IF_TYPE_INT)
            int_data = global_unstruct_pool%objects(idx)%data%queue%int_data(pos)
        CASE (IF_TYPE_DP)
            real_data = global_unstruct_pool%objects(idx)%data%queue%real_data(pos)
        CASE (IF_TYPE_CHAR)
            char_data = TRIM(global_unstruct_pool%objects(idx)%data%queue%char_data(pos))
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unknown queue data_type"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END SELECT

        global_unstruct_pool%objects(idx)%data%queue%front = &
            global_unstruct_pool%objects(idx)%data%queue%front + 1
        IF (global_unstruct_pool%objects(idx)%data%queue%is_circular) THEN
            IF (global_unstruct_pool%objects(idx)%data%queue%front > &
                global_unstruct_pool%objects(idx)%data%queue%max_size) THEN
                global_unstruct_pool%objects(idx)%data%queue%front = 1
            END IF
        END IF

        global_unstruct_pool%objects(idx)%data%queue%current_size = &
            global_unstruct_pool%objects(idx)%data%queue%current_size - 1
        global_unstruct_pool%objects(idx)%data%queue%is_full = .FALSE.

        status%status_code = IF_STATUS_OK
    END SUBROUTINE queue_dequeue

    SUBROUTINE queue_enqueue(data_id, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id, char_data
        INTEGER(i4), INTENT(IN) :: data_type, int_data
        REAL,    INTENT(IN) :: real_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, pos

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Queue not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a queue: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%data%queue%is_full) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Queue is full"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%data%queue%data_type == IF_TYPE_UNKNOWN) THEN
            CALL queue_allocate_storage(idx, data_type, status)
            IF (status%status_code /= IF_STATUS_OK) RETURN
        ELSE IF (global_unstruct_pool%objects(idx)%data%queue%data_type /= data_type) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Queue data_type mismatch"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        global_unstruct_pool%objects(idx)%data%queue%rear = &
            global_unstruct_pool%objects(idx)%data%queue%rear + 1
        IF (global_unstruct_pool%objects(idx)%data%queue%is_circular) THEN
            IF (global_unstruct_pool%objects(idx)%data%queue%rear > &
                global_unstruct_pool%objects(idx)%data%queue%max_size) THEN
                global_unstruct_pool%objects(idx)%data%queue%rear = 1
            END IF
        END IF

        pos = global_unstruct_pool%objects(idx)%data%queue%rear

        SELECT CASE (data_type)
        CASE (IF_TYPE_INT)
            global_unstruct_pool%objects(idx)%data%queue%int_data(pos) = int_data
        CASE (IF_TYPE_DP)
            global_unstruct_pool%objects(idx)%data%queue%real_data(pos) = real_data
        CASE (IF_TYPE_CHAR)
            global_unstruct_pool%objects(idx)%data%queue%char_data(pos) = TRIM(char_data)
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unsupported queue data_type"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END SELECT

        global_unstruct_pool%objects(idx)%data%queue%current_size = &
            global_unstruct_pool%objects(idx)%data%queue%current_size + 1
        IF (global_unstruct_pool%objects(idx)%data%queue%current_size == &
            global_unstruct_pool%objects(idx)%data%queue%max_size) THEN
            global_unstruct_pool%objects(idx)%data%queue%is_full = .TRUE.
        END IF

        status%status_code = IF_STATUS_OK
    END SUBROUTINE queue_enqueue

    SUBROUTINE queue_get_all(data_id, data_type, int_values, real_values, char_values, count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER(i4), INTENT(OUT) :: data_type
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: int_values(:)
        REAL,             ALLOCATABLE, INTENT(OUT) :: real_values(:)
        CHARACTER(LEN=*), ALLOCATABLE, INTENT(OUT) :: char_values(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, i, pos, nmax

        CALL init_error_status(status)
        data_type = IF_TYPE_UNKNOWN
        count = 0
        IF (ALLOCATED(int_values))  DEALLOCATE(int_values)
        IF (ALLOCATED(real_values)) DEALLOCATE(real_values)
        IF (ALLOCATED(char_values)) DEALLOCATE(char_values)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Queue not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a queue: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        data_type = global_unstruct_pool%objects(idx)%data%queue%data_type
        count = global_unstruct_pool%objects(idx)%data%queue%current_size
        IF (count <= 0) RETURN

        nmax = global_unstruct_pool%objects(idx)%data%queue%max_size

        SELECT CASE (data_type)
        CASE (IF_TYPE_INT)
            ALLOCATE(int_values(count))
        CASE (IF_TYPE_DP)
            ALLOCATE(real_values(count))
        CASE (IF_TYPE_CHAR)
            ALLOCATE(char_values(count))
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unknown queue data_type"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END SELECT

        pos = global_unstruct_pool%objects(idx)%data%queue%front
        DO i = 1, count
            SELECT CASE (data_type)
            CASE (IF_TYPE_INT)
                int_values(i) = global_unstruct_pool%objects(idx)%data%queue%int_data(pos)
            CASE (IF_TYPE_DP)
                real_values(i) = global_unstruct_pool%objects(idx)%data%queue%real_data(pos)
            CASE (IF_TYPE_CHAR)
                char_values(i) = TRIM(global_unstruct_pool%objects(idx)%data%queue%char_data(pos))
            END SELECT

            pos = pos + 1
            IF (global_unstruct_pool%objects(idx)%data%queue%is_circular) THEN
                IF (pos > nmax) pos = 1
            END IF
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE queue_get_all

    SUBROUTINE queue_peek(data_id, data_type, int_data, real_data, char_data, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(OUT) :: data_type, int_data
        REAL,    INTENT(OUT) :: real_data
        CHARACTER(LEN=*), INTENT(OUT) :: char_data
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, pos

        CALL init_error_status(status)
        data_type = IF_TYPE_UNKNOWN
        int_data  = 0
        real_data = 0.0
        char_data = ""

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Queue not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_QUEUE) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a queue: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%data%queue%current_size == 0) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Queue is empty"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        data_type = global_unstruct_pool%objects(idx)%data%queue%data_type
        pos = global_unstruct_pool%objects(idx)%data%queue%front

        SELECT CASE (data_type)
        CASE (IF_TYPE_INT)
            int_data = global_unstruct_pool%objects(idx)%data%queue%int_data(pos)
        CASE (IF_TYPE_DP)
            real_data = global_unstruct_pool%objects(idx)%data%queue%real_data(pos)
        CASE (IF_TYPE_CHAR)
            char_data = TRIM(global_unstruct_pool%objects(idx)%data%queue%char_data(pos))
        CASE DEFAULT
            status%status_code = IF_STATUS_INVALID
            status%message = "Unknown queue data_type"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END SELECT

        status%status_code = IF_STATUS_OK
    END SUBROUTINE queue_peek

    SUBROUTINE skip_list_delete(data_id, key, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: key
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        TYPE(SkipListNodeType), POINTER :: current, prev

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Skip list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_SKIP_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a skip list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%skip_list%header)) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Skip list header is not allocated"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        prev => global_unstruct_pool%objects(idx)%data%skip_list%header
        current => prev%next

        DO WHILE (ASSOCIATED(current) .AND. current%key < key)
            prev => current
            current => current%next
        END DO

        IF (.NOT. ASSOCIATED(current) .OR. current%key /= key) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Key not found in skip list"
            RETURN
        END IF

        prev%next => current%next
        DEALLOCATE(current)

        global_unstruct_pool%objects(idx)%data%skip_list%size = &
            global_unstruct_pool%objects(idx)%data%skip_list%size - 1

        status%status_code = IF_STATUS_OK
    END SUBROUTINE skip_list_delete

    SUBROUTINE skip_list_get_all(data_id, keys, value_types, int_values, real_values, char_values, count, status)
        CHARACTER(LEN=*), INTENT(IN)  :: data_id
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: keys(:)
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: value_types(:)
        INTEGER,          ALLOCATABLE, INTENT(OUT) :: int_values(:)
        REAL,             ALLOCATABLE, INTENT(OUT) :: real_values(:)
        CHARACTER(LEN=*), ALLOCATABLE, INTENT(OUT) :: char_values(:)
        INTEGER(i4), INTENT(OUT) :: count
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, i
        TYPE(SkipListNodeType), POINTER :: cur

        CALL init_error_status(status)
        count = 0
        IF (ALLOCATED(keys))         DEALLOCATE(keys)
        IF (ALLOCATED(value_types))  DEALLOCATE(value_types)
        IF (ALLOCATED(int_values))   DEALLOCATE(int_values)
        IF (ALLOCATED(real_values))  DEALLOCATE(real_values)
        IF (ALLOCATED(char_values))  DEALLOCATE(char_values)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Skip list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_SKIP_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a skip list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        count = global_unstruct_pool%objects(idx)%data%skip_list%size
        IF (count <= 0) RETURN

        ALLOCATE(keys(count))
        ALLOCATE(value_types(count))
        ALLOCATE(int_values(count))
        ALLOCATE(real_values(count))
        ALLOCATE(char_values(count))

        cur => global_unstruct_pool%objects(idx)%data%skip_list%header%next
        i = 1
        DO WHILE (ASSOCIATED(cur) .AND. i <= count)
            keys(i)        = cur%key
            value_types(i) = cur%value_type
            int_values(i)  = cur%int_value
            real_values(i) = cur%real_value
            char_values(i) = TRIM(cur%char_value)
            cur => cur%next
            i = i + 1
        END DO

        status%status_code = IF_STATUS_OK
    END SUBROUTINE skip_list_get_all

    SUBROUTINE skip_list_insert(data_id, key, value_type, int_value, real_value, char_value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id, char_value
        INTEGER(i4), INTENT(IN) :: key, value_type, int_value
        REAL, INTENT(IN) :: real_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx, ierr
        TYPE(SkipListNodeType), POINTER :: current, prev, new_node

        CALL init_error_status(status)

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Skip list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_SKIP_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a skip list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%skip_list%header)) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Skip list header is not allocated"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        prev => global_unstruct_pool%objects(idx)%data%skip_list%header
        current => prev%next

        DO WHILE (ASSOCIATED(current) .AND. current%key < key)
            prev => current
            current => current%next
        END DO

        IF (ASSOCIATED(current) .AND. current%key == key) THEN
            current%value_type = value_type
            current%int_value  = int_value
            current%real_value = real_value
            current%char_value = TRIM(char_value)
            status%status_code = IF_STATUS_OK
            RETURN
        END IF

        ALLOCATE(new_node, STAT=ierr)
        IF (ierr /= 0) THEN
            status%status_code = IF_STATUS_MEM_ERROR
            WRITE(status%message, '(A,I0,A)') &
                "Failed to allocate skip list node (stat=", ierr, ")"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        new_node%key        = key
        new_node%value_type = value_type
        new_node%int_value  = int_value
        new_node%real_value = real_value
        new_node%char_value = TRIM(char_value)
        NULLIFY(new_node%next)

        new_node%next => current
        prev%next      => new_node

        global_unstruct_pool%objects(idx)%data%skip_list%size = &
            global_unstruct_pool%objects(idx)%data%skip_list%size + 1

        status%status_code = IF_STATUS_OK
    END SUBROUTINE skip_list_insert

    SUBROUTINE skip_list_search(data_id, key, value_type, int_value, real_value, char_value, status)
        CHARACTER(LEN=*), INTENT(IN) :: data_id
        INTEGER(i4), INTENT(IN) :: key
        INTEGER(i4), INTENT(OUT) :: value_type, int_value
        REAL,    INTENT(OUT) :: real_value
        CHARACTER(LEN=*), INTENT(OUT) :: char_value
        TYPE(ErrorStatusType), INTENT(OUT) :: status

        INTEGER(i4) :: idx
        TYPE(SkipListNodeType), POINTER :: current

        CALL init_error_status(status)
        value_type = IF_TYPE_UNKNOWN
        int_value  = 0
        real_value = 0.0
        char_value = ""

        IF (.NOT. global_unstruct_pool%initialized) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Unstructured memory pool not initialized"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        idx = find_object_index(data_id)
        IF (idx == 0) THEN
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Skip list not found: "//TRIM(data_id)
            CALL log_warn("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (global_unstruct_pool%objects(idx)%unstruct_type /= UNSTRUCT_TYPE_SKIP_LIST) THEN
            status%status_code = IF_STATUS_INVALID
            status%message = "Object is not a skip list: "//TRIM(data_id)
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        IF (.NOT. ASSOCIATED(global_unstruct_pool%objects(idx)%data%skip_list%header)) THEN
            status%status_code = IF_STATUS_ERROR
            status%message = "Skip list header is not allocated"
            CALL log_error("UnstructMemPool", TRIM(status%message))
            RETURN
        END IF

        current => global_unstruct_pool%objects(idx)%data%skip_list%header%next
        DO WHILE (ASSOCIATED(current) .AND. current%key < key)
            current => current%next
        END DO

        IF (ASSOCIATED(current) .AND. current%key == key) THEN
            value_type = current%value_type
            int_value  = current%int_value
            real_value = current%real_value
            char_value = TRIM(current%char_value)
            status%status_code = IF_STATUS_OK
        ELSE
            status%status_code = IF_STATUS_NOT_FOUND
            status%message = "Key not found in skip list"
        END IF
    END SUBROUTINE skip_list_search

    FUNCTION WRITE_INT(value) RESULT(str)
        INTEGER(i4), INTENT(IN) :: value
        CHARACTER(LEN=32) :: str
        WRITE(str, '(I0)') value
    END FUNCTION WRITE_INT
END MODULE IF_Mem_UnStructPool