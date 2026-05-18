# `IF_Mem_UnStructPool.f90`

- **Source**: `L1_IF/Memory/IF_Mem_UnStructPool.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Mem_UnStructPool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_UnStructPool`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_UnStructPool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_UnStructPool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `EdgeDataType` (lines 95–101)

```fortran
    TYPE :: EdgeDataType
        INTEGER(i4) :: from_node = 0
        INTEGER(i4) :: to_node = 0
        REAL    :: weight   = 1.0
        LOGICAL :: is_directed = .FALSE.
        CHARACTER(LEN=64) :: label = ""
    END TYPE EdgeDataType
```

### `ListNodeType` (lines 103–111)

```fortran
    TYPE :: ListNodeType
        INTEGER(i4) :: data_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_data  = 0
        REAL    :: real_data = 0.0
        CHARACTER(LEN=64) :: char_data = ""
        TYPE(EdgeDataType) :: edge_data
        TYPE(ListNodeType), POINTER :: prev => NULL()
        TYPE(ListNodeType), POINTER :: next => NULL()
    END TYPE ListNodeType
```

### `LinkedListType` (lines 113–117)

```fortran
    TYPE :: LinkedListType
        INTEGER(i4) :: size = 0
        TYPE(ListNodeType), POINTER :: head => NULL()
        TYPE(ListNodeType), POINTER :: tail => NULL()
    END TYPE LinkedListType
```

### `HashNodeType` (lines 119–126)

```fortran
    TYPE :: HashNodeType
        CHARACTER(LEN=64) :: key = ""
        INTEGER(i4) :: value_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_value  = 0
        REAL    :: real_value = 0.0
        CHARACTER(LEN=64) :: char_value = ""
        TYPE(HashNodeType), POINTER :: next => NULL()
    END TYPE HashNodeType
```

### `HashBucketType` (lines 128–130)

```fortran
    TYPE :: HashBucketType
        TYPE(HashNodeType), POINTER :: head => NULL()
    END TYPE HashBucketType
```

### `HashTableType` (lines 132–137)

```fortran
    TYPE :: HashTableType
        INTEGER(i4) :: capacity = 0
        INTEGER(i4) :: count    = 0
        REAL    :: load_factor = 0.7
        TYPE(HashBucketType), ALLOCATABLE :: buckets(:)
    END TYPE HashTableType
```

### `AdjacencyListType` (lines 139–144)

```fortran
    TYPE :: AdjacencyListType
        INTEGER(i4) :: num_nodes = 0
        LOGICAL :: is_directed = .FALSE.
        TYPE(LinkedListType), ALLOCATABLE :: adj(:)
        INTEGER(i4) :: edge_count = 0
    END TYPE AdjacencyListType
```

### `SkipListNodeType` (lines 147–154)

```fortran
    TYPE :: SkipListNodeType
        INTEGER(i4) :: key = 0
        INTEGER(i4) :: value_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_value = 0
        REAL    :: real_value = 0.0
        CHARACTER(LEN=64) :: char_value = ""
        TYPE(SkipListNodeType), POINTER :: next => NULL()
    END TYPE SkipListNodeType
```

### `SkipListType` (lines 156–160)

```fortran
    TYPE :: SkipListType
        INTEGER(i4) :: size  = 0
        REAL    :: probability = 0.5
        TYPE(SkipListNodeType), POINTER :: header => NULL()
    END TYPE SkipListType
```

### `GraphNodeType` (lines 163–169)

```fortran
    TYPE :: GraphNodeType
        INTEGER(i4) :: node_id = 0
        INTEGER(i4) :: data_type = IF_TYPE_UNKNOWN
        INTEGER(i4) :: int_data = 0
        REAL    :: real_data = 0.0
        CHARACTER(LEN=64) :: char_data = ""
    END TYPE GraphNodeType
```

### `GraphType` (lines 171–178)

```fortran
    TYPE :: GraphType
        INTEGER(i4) :: num_nodes = 0
        INTEGER(i4) :: num_edges = 0
        LOGICAL :: is_directed = .FALSE.
        LOGICAL :: is_weighted = .FALSE.
        TYPE(GraphNodeType), ALLOCATABLE :: nodes(:)
        TYPE(AdjacencyListType) :: adjacency_list
    END TYPE GraphType
```

### `QueueType` (lines 181–192)

```fortran
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
```

### `UnstructObjectDataType` (lines 194–201)

```fortran
    TYPE :: UnstructObjectDataType
        TYPE(AdjacencyListType) :: adjacency_list
        TYPE(LinkedListType)    :: generic_list
        TYPE(HashTableType)     :: hash_table
        TYPE(SkipListType)      :: skip_list
        TYPE(GraphType)         :: graph
        TYPE(QueueType)         :: queue
    END TYPE UnstructObjectDataType
```

### `UnstructObjectType` (lines 203–213)

```fortran
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
```

### `UnstructMemPoolType` (lines 215–220)

```fortran
    TYPE :: UnstructMemPoolType
        LOGICAL :: initialized = .FALSE.
        INTEGER(i4) :: max_objects = IF_MAX_UNSTRUCT_OBJECTS
        INTEGER(i4) :: used_objects = 0
        TYPE(UnstructObjectType), ALLOCATABLE :: objects(:)
    END TYPE UnstructMemPoolType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `adjacency_list_add_edge` | 259 | `SUBROUTINE adjacency_list_add_edge(data_id, from_node, to_node, weight, status)` |
| SUBROUTINE | `adjacency_list_delete_edge` | 323 | `SUBROUTINE adjacency_list_delete_edge(data_id, from_node, to_node, status)` |
| SUBROUTINE | `adjacency_list_get_edges` | 442 | `SUBROUTINE adjacency_list_get_edges(data_id, node_id, edges, edge_count, status)` |
| SUBROUTINE | `create_adjacency_list` | 504 | `SUBROUTINE create_adjacency_list(data_id, var_name, num_nodes, is_directed, &` |
| SUBROUTINE | `create_graph` | 556 | `SUBROUTINE create_graph(data_id, var_name, num_nodes, status, is_directed, is_weighted, device_id)` |
| SUBROUTINE | `create_hash_table` | 645 | `SUBROUTINE create_hash_table(data_id, var_name, initial_capacity, device_id, status)` |
| SUBROUTINE | `create_linked_list` | 701 | `SUBROUTINE create_linked_list(data_id, var_name, device_id, status)` |
| SUBROUTINE | `create_queue` | 738 | `SUBROUTINE create_queue(data_id, var_name, max_size, status, is_circular, device_id)` |
| SUBROUTINE | `create_skip_list` | 790 | `SUBROUTINE create_skip_list(data_id, var_name, status, probability, device_id)` |
| SUBROUTINE | `create_unstruct_data` | 847 | `SUBROUTINE create_unstruct_data(data_id, var_name, unstruct_type, device_id, &` |
| SUBROUTINE | `delete_unstruct_data` | 952 | `SUBROUTINE delete_unstruct_data(data_id, status)` |
| SUBROUTINE | `destroy_unstruct_mem_pool` | 1093 | `SUBROUTINE destroy_unstruct_mem_pool(status)` |
| SUBROUTINE | `get_adjacency_list_size` | 1220 | `SUBROUTINE get_adjacency_list_size(data_id, num_nodes, edge_count, status)` |
| SUBROUTINE | `get_graph_size` | 1259 | `SUBROUTINE get_graph_size(data_id, num_nodes, num_edges, status)` |
| SUBROUTINE | `get_hash_table_size` | 1298 | `SUBROUTINE get_hash_table_size(data_id, entry_count, status)` |
| SUBROUTINE | `get_linked_list_size` | 1334 | `SUBROUTINE get_linked_list_size(data_id, list_size, status)` |
| SUBROUTINE | `get_queue_size` | 1370 | `SUBROUTINE get_queue_size(data_id, queue_size, status)` |
| SUBROUTINE | `get_skip_list_size` | 1406 | `SUBROUTINE get_skip_list_size(data_id, list_size, status)` |
| SUBROUTINE | `get_unstruct_data_info` | 1442 | `SUBROUTINE get_unstruct_data_info(data_id, unstruct_type, device_id, mem_size, status)` |
| SUBROUTINE | `graph_add_edge` | 1478 | `SUBROUTINE graph_add_edge(data_id, from_node, to_node, weight, label, status)` |
| SUBROUTINE | `graph_add_node` | 1553 | `SUBROUTINE graph_add_node(data_id, node_id, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `graph_bfs` | 1668 | `SUBROUTINE graph_bfs(data_id, start_node, visited, distances, status)` |
| SUBROUTINE | `graph_dfs` | 1772 | `SUBROUTINE graph_dfs(data_id, start_node, visited, status)` |
| SUBROUTINE | `graph_dfs_visit` | 1834 | `RECURSIVE SUBROUTINE graph_dfs_visit(data_id, current_node, visited, num_nodes, status)` |
| SUBROUTINE | `graph_get_edges` | 1869 | `SUBROUTINE graph_get_edges(data_id, node_id, edges, edge_count, status)` |
| SUBROUTINE | `graph_remove_edge` | 1927 | `SUBROUTINE graph_remove_edge(data_id, from_node, to_node, status)` |
| SUBROUTINE | `graph_remove_node` | 1998 | `SUBROUTINE graph_remove_node(data_id, node_id, status)` |
| SUBROUTINE | `hash_table_get` | 2064 | `SUBROUTINE hash_table_get(data_id, key, found, value, status)` |
| SUBROUTINE | `hash_table_get_all` | 2129 | `SUBROUTINE hash_table_get_all(data_id, keys, values, count, status)` |
| SUBROUTINE | `hash_table_insert` | 2194 | `SUBROUTINE hash_table_insert(data_id, key, value, status)` |
| SUBROUTINE | `init_unstruct_mem_pool` | 2263 | `SUBROUTINE init_unstruct_mem_pool(status, max_objects)` |
| SUBROUTINE | `insert_graph_edge` | 2319 | `SUBROUTINE insert_graph_edge(idx, node_id, edge_data, status)` |
| SUBROUTINE | `insert_single_edge` | 2347 | `SUBROUTINE insert_single_edge(idx, from_node, to_node, weight, is_directed, status)` |
| SUBROUTINE | `linked_list_delete` | 2379 | `SUBROUTINE linked_list_delete(data_id, value, status)` |
| SUBROUTINE | `linked_list_get_values` | 2439 | `SUBROUTINE linked_list_get_values(data_id, values, count, status)` |
| SUBROUTINE | `linked_list_insert` | 2496 | `SUBROUTINE linked_list_insert(data_id, value, status)` |
| SUBROUTINE | `queue_allocate_storage` | 2549 | `SUBROUTINE queue_allocate_storage(idx, data_type, status)` |
| SUBROUTINE | `queue_dequeue` | 2594 | `SUBROUTINE queue_dequeue(data_id, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `queue_enqueue` | 2671 | `SUBROUTINE queue_enqueue(data_id, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `queue_get_all` | 2755 | `SUBROUTINE queue_get_all(data_id, data_type, int_values, real_values, char_values, count, status)` |
| SUBROUTINE | `queue_peek` | 2835 | `SUBROUTINE queue_peek(data_id, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `skip_list_delete` | 2899 | `SUBROUTINE skip_list_delete(data_id, key, status)` |
| SUBROUTINE | `skip_list_get_all` | 2961 | `SUBROUTINE skip_list_get_all(data_id, keys, value_types, int_values, real_values, char_values, count, status)` |
| SUBROUTINE | `skip_list_insert` | 3028 | `SUBROUTINE skip_list_insert(data_id, key, value_type, int_value, real_value, char_value, status)` |
| SUBROUTINE | `skip_list_search` | 3110 | `SUBROUTINE skip_list_search(data_id, key, value_type, int_value, real_value, char_value, status)` |
| FUNCTION | `WRITE_INT` | 3173 | `FUNCTION WRITE_INT(value) RESULT(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
