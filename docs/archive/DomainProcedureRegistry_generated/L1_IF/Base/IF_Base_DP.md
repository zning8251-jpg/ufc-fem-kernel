# `IF_Base_DP.f90`

- **Source**: `L1_IF/Base/IF_Base_DP.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Base_DP`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_DP`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base_DP`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_DP.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `StructFieldDesc` (lines 84–91)

```fortran
    TYPE :: StructFieldDesc
        CHARACTER(LEN=64) :: field_name = ""
        INTEGER(i4) :: data_type  = 0
        INTEGER(i4) :: offset_bytes = 0
        INTEGER(i4) :: elem_len   = 0
        INTEGER(i4) :: rank       = 0
        INTEGER(i4) :: dims(4)    = [1,1,1,1]
    END TYPE StructFieldDesc
```

### `ClassFieldDesc` (lines 93–101)

```fortran
    TYPE :: ClassFieldDesc
        CHARACTER(LEN=64) :: field_name = ""
        INTEGER(i4) :: data_type  = 0
        INTEGER(i4) :: offset_bytes = 0
        INTEGER(i4) :: elem_len   = 0
        INTEGER(i4) :: rank       = 0
        INTEGER(i4) :: dims(4)    = [1,1,1,1]
        LOGICAL           :: is_inherited = .FALSE.
    END TYPE ClassFieldDesc
```

### `StructTypeRegistryEntry` (lines 106–112)

```fortran
    TYPE :: StructTypeRegistryEntry
        CHARACTER(LEN=64) :: type_name = ""
        INTEGER(i4) :: num_fields = 0
        TYPE(StructFieldDesc), ALLOCATABLE :: fields(:)
        INTEGER(KIND=8)   :: elem_size = 0_8
        LOGICAL           :: is_used = .FALSE.
    END TYPE StructTypeRegistryEntry
```

### `ClassTypeRegistryEntry` (lines 114–121)

```fortran
    TYPE :: ClassTypeRegistryEntry
        CHARACTER(LEN=64) :: type_name = ""
        CHARACTER(LEN=64) :: parent_type_name = ""
        INTEGER(i4) :: num_fields = 0
        TYPE(ClassFieldDesc), ALLOCATABLE :: fields(:)
        INTEGER(KIND=8)   :: elem_size = 0_8
        LOGICAL           :: is_used = .FALSE.
    END TYPE ClassTypeRegistryEntry
```

### `DP_VarView` (lines 127–133)

```fortran
    TYPE :: DP_VarView
        CHARACTER(LEN=32) :: category   = ""   ! e.g. 'STATE', 'HISTORY', 'CONTROL'
        CHARACTER(LEN=32) :: scope      = ""   ! e.g. 'MODEL', 'NODE', 'ELEM', 'SOLVER'
        CHARACTER(LEN=64) :: var_name   = ""   ! DataPlatform variable name
        INTEGER(i4) :: storage_type = 0   ! IF_STORAGE_TYPE_STRUCTURED / UNSTRUCTURED
        INTEGER(i4) :: data_type     = 0   ! IF_DATA_TYPE_INT / DP / STRUCT / CLASS
    END TYPE DP_VarView
```

### `ShardMovePlan` (lines 146–152)

```fortran
    TYPE :: ShardMovePlan
        CHARACTER(LEN=64)  :: logical_id  = ""
        CHARACTER(LEN=256) :: file_path   = ""
        INTEGER(i4) :: chunk_id    = 0
        INTEGER(i4) :: from_node   = 0
        INTEGER(i4) :: to_node     = 0
    END TYPE ShardMovePlan
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `dp_log` | 252 | `SUBROUTINE dp_log(level, source, message)` |
| SUBROUTINE | `dp_set_log_level` | 292 | `SUBROUTINE dp_set_log_level(level, status)` |
| SUBROUTINE | `dp_get_log_level` | 311 | `SUBROUTINE dp_get_log_level(level, status)` |
| SUBROUTINE | `dp_get_last_error` | 320 | `SUBROUTINE dp_get_last_error(error)` |
| SUBROUTINE | `dp_get_error_stats` | 326 | `SUBROUTINE dp_get_error_stats(total_errors, total_warnings)` |
| SUBROUTINE | `dp_reset_error_stats` | 334 | `SUBROUTINE dp_reset_error_stats(status)` |
| SUBROUTINE | `dp_sync_class_type_to_structmempool` | 345 | `SUBROUTINE dp_sync_class_type_to_structmempool(type_name, parent_type_name, field_descs, num_fields, status)` |
| FUNCTION | `INT8_TO_STR` | 417 | `FUNCTION INT8_TO_STR(i8) RESULT(str)` |
| FUNCTION | `WRITE_INT` | 425 | `FUNCTION WRITE_INT(value) RESULT(str)` |
| SUBROUTINE | `dp_init` | 433 | `SUBROUTINE dp_init(status)` |
| SUBROUTINE | `dp_shutdown` | 467 | `SUBROUTINE dp_shutdown(status)` |
| SUBROUTINE | `dp_register_struct_array` | 485 | `SUBROUTINE dp_register_struct_array(var_name, dims, data_type, type_name, status)` |
| SUBROUTINE | `dp_register_unstruct` | 641 | `SUBROUTINE dp_register_unstruct(var_name, unstruct_type, attr, status)` |
| SUBROUTINE | `dp_ensure_unstruct` | 711 | `SUBROUTINE dp_ensure_unstruct(var_name, unstruct_type, attr, status)` |
| SUBROUTINE | `dp_register_struct_type` | 800 | `SUBROUTINE dp_register_struct_type(type_name, field_descs, num_fields, status)` |
| SUBROUTINE | `dp_register_class_type` | 882 | `SUBROUTINE dp_register_class_type(type_name, parent_type_name, field_descs, num_fields, status)` |
| SUBROUTINE | `dp_internal_pack_class_array_to_records` | 975 | `SUBROUTINE dp_internal_pack_class_array_to_records(var_name, struct_meta, data_id, file_path, status)` |
| SUBROUTINE | `dp_plan_rebalance` | 1086 | `SUBROUTINE dp_plan_rebalance(logical_id, target_nodes, plan, num_moves, status)` |
| SUBROUTINE | `dp_save` | 1174 | `SUBROUTINE dp_save(var_name, file_path, format, status)` |
| SUBROUTINE | `dp_load` | 1414 | `SUBROUTINE dp_load(var_name, file_path, format, status)` |
| SUBROUTINE | `dp_get_shards` | 1650 | `SUBROUTINE dp_get_shards(logical_id, chunks, count, status)` |
| SUBROUTINE | `dp_get_shards_by_node` | 1689 | `SUBROUTINE dp_get_shards_by_node(logical_id, node_id, chunks, count, status)` |
| SUBROUTINE | `dp_get_shards_for_file` | 1751 | `SUBROUTINE dp_get_shards_for_file(logical_id, file_path, chunks, count, status)` |
| SUBROUTINE | `dp_rebuild_unstruct_from_file` | 1813 | `SUBROUTINE dp_rebuild_unstruct_from_file(var_name, file_path, status)` |
| SUBROUTINE | `dp_get_meta` | 1943 | `SUBROUTINE dp_get_meta(var_name, struct_meta, unstruct_meta, status)` |
| SUBROUTINE | `dp_validate` | 2026 | `SUBROUTINE dp_validate(var_name, status, current_crc32, file_path)` |
| SUBROUTINE | `dp_get_struct_handle` | 2072 | `SUBROUTINE dp_get_struct_handle(var_name, data_id, status)` |
| SUBROUTINE | `dp_get_struct_ptr` | 2127 | `SUBROUTINE dp_get_struct_ptr(var_name, ptr, status)` |
| SUBROUTINE | `dp_get_class_ptr` | 2176 | `SUBROUTINE dp_get_class_ptr(var_name, ptr, status)` |
| SUBROUTINE | `dp_get_struct_element_ptr` | 2225 | `SUBROUTINE dp_get_struct_element_ptr(var_name, elem_index, ptr, status)` |
| SUBROUTINE | `dp_get_struct_element_cptr` | 2284 | `SUBROUTINE dp_get_struct_element_cptr(var_name, elem_index, cptr, status)` |
| SUBROUTINE | `dp_get_class_element_ptr` | 2344 | `SUBROUTINE dp_get_class_element_ptr(var_name, elem_index, ptr, status)` |
| SUBROUTINE | `dp_get_unstruct_handle` | 2402 | `SUBROUTINE dp_get_unstruct_handle(var_name, data_id, unstruct_type, status)` |
| SUBROUTINE | `dp_dump_debug` | 2460 | `SUBROUTINE dp_dump_debug(var_name, unit, status)` |
| SUBROUTINE | `dp_create_int_array1d` | 2576 | `SUBROUTINE dp_create_int_array1d(var_name, dim1, array_ptr, status)` |
| SUBROUTINE | `dp_create_int_array2d` | 2672 | `SUBROUTINE dp_create_int_array2d(var_name, dim1, dim2, array_ptr, status)` |
| SUBROUTINE | `dp_create_dp_array1d` | 2768 | `SUBROUTINE dp_create_dp_array1d(var_name, dim1, array_ptr, status)` |
| SUBROUTINE | `dp_create_dp_array2d` | 2864 | `SUBROUTINE dp_create_dp_array2d(var_name, dim1, dim2, array_ptr, status)` |
| SUBROUTINE | `dp_create_int_array3d` | 2960 | `SUBROUTINE dp_create_int_array3d(var_name, dim1, dim2, dim3, array_ptr, status)` |
| SUBROUTINE | `dp_create_int_array4d` | 3056 | `SUBROUTINE dp_create_int_array4d(var_name, dim1, dim2, dim3, dim4, array_ptr, status)` |
| SUBROUTINE | `dp_create_dp_array3d` | 3153 | `SUBROUTINE dp_create_dp_array3d(var_name, dim1, dim2, dim3, array_ptr, status)` |
| SUBROUTINE | `dp_create_dp_array4d` | 3249 | `SUBROUTINE dp_create_dp_array4d(var_name, dim1, dim2, dim3, dim4, array_ptr, status)` |
| SUBROUTINE | `dp_create_char_array1d` | 3346 | `SUBROUTINE dp_create_char_array1d(var_name, dim1, char_len, array_ptr, status)` |
| SUBROUTINE | `dp_create_char_array2d` | 3442 | `SUBROUTINE dp_create_char_array2d(var_name, dim1, dim2, char_len, array_ptr, status)` |
| SUBROUTINE | `dp_create_char_array3d` | 3538 | `SUBROUTINE dp_create_char_array3d(var_name, dim1, dim2, dim3, char_len, array_ptr, status)` |
| SUBROUTINE | `dp_create_char_array4d` | 3634 | `SUBROUTINE dp_create_char_array4d(var_name, dim1, dim2, dim3, dim4, char_len, array_ptr, status)` |
| SUBROUTINE | `dp_create_struct_array` | 3732 | `SUBROUTINE dp_create_struct_array(var_name, dims, struct_name, status)` |
| SUBROUTINE | `dp_create_class_array` | 3851 | `SUBROUTINE dp_create_class_array(var_name, dims, class_name, status)` |
| SUBROUTINE | `dp_ensure_queue` | 3973 | `SUBROUTINE dp_ensure_queue(var_name, capacity, is_circular, status)` |
| SUBROUTINE | `dp_create_queue` | 4084 | `SUBROUTINE dp_create_queue(var_name, capacity, is_circular, status)` |
| SUBROUTINE | `dp_queue_enqueue` | 4162 | `SUBROUTINE dp_queue_enqueue(var_name, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `dp_queue_dequeue` | 4240 | `SUBROUTINE dp_queue_dequeue(var_name, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `dp_queue_get_size` | 4283 | `SUBROUTINE dp_queue_get_size(var_name, size, status)` |
| SUBROUTINE | `dp_create_hash_table` | 4323 | `SUBROUTINE dp_create_hash_table(var_name, initial_capacity, status)` |
| SUBROUTINE | `dp_get_hash_table_size` | 4395 | `SUBROUTINE dp_get_hash_table_size(var_name, entry_count, status)` |
| SUBROUTINE | `dp_hash_insert` | 4432 | `SUBROUTINE dp_hash_insert(var_name, key, value, status)` |
| SUBROUTINE | `dp_hash_get` | 4469 | `SUBROUTINE dp_hash_get(var_name, key, found, value, status)` |
| SUBROUTINE | `dp_create_graph` | 4512 | `SUBROUTINE dp_create_graph(var_name, num_nodes, is_directed, is_weighted, status)` |
| SUBROUTINE | `dp_graph_add_node` | 4591 | `SUBROUTINE dp_graph_add_node(var_name, node_id, data_type, int_data, real_data, char_data, status)` |
| SUBROUTINE | `dp_graph_add_edge` | 4628 | `SUBROUTINE dp_graph_add_edge(var_name, from_node, to_node, weight, label, status)` |
| SUBROUTINE | `dp_get_graph_size` | 4665 | `SUBROUTINE dp_get_graph_size(var_name, num_nodes, num_edges, status)` |
| SUBROUTINE | `dp_graph_bfs` | 4704 | `SUBROUTINE dp_graph_bfs(var_name, start_node, visited, distances, status)` |
| SUBROUTINE | `dp_graph_dfs` | 4745 | `SUBROUTINE dp_graph_dfs(var_name, start_node, visited, status)` |
| SUBROUTINE | `dp_create_adjacency_list` | 4787 | `SUBROUTINE dp_create_adjacency_list(var_name, num_nodes, is_directed, status)` |
| SUBROUTINE | `dp_adjacency_add_edge` | 4861 | `SUBROUTINE dp_adjacency_add_edge(var_name, from_node, to_node, weight, status)` |
| SUBROUTINE | `dp_get_adjacency_list_size` | 4898 | `SUBROUTINE dp_get_adjacency_list_size(var_name, num_nodes, edge_count, status)` |
| SUBROUTINE | `dp_create_linked_list` | 4941 | `SUBROUTINE dp_create_linked_list(var_name, status)` |
| SUBROUTINE | `dp_get_linked_list_size` | 5001 | `SUBROUTINE dp_get_linked_list_size(var_name, list_size, status)` |
| SUBROUTINE | `dp_list_push_back` | 5038 | `SUBROUTINE dp_list_push_back(var_name, value, status)` |
| SUBROUTINE | `dp_list_get_values` | 5074 | `SUBROUTINE dp_list_get_values(var_name, values, list_size, status)` |
| SUBROUTINE | `dp_create_skip_list` | 5130 | `SUBROUTINE dp_create_skip_list(var_name, status)` |
| SUBROUTINE | `dp_get_skip_list_size` | 5190 | `SUBROUTINE dp_get_skip_list_size(var_name, list_size, status)` |
| SUBROUTINE | `dp_skip_insert` | 5227 | `SUBROUTINE dp_skip_insert(var_name, key, value_type, int_value, real_value, char_value, status)` |
| SUBROUTINE | `dp_skip_get_all` | 5264 | `SUBROUTINE dp_skip_get_all(var_name, keys, value_types, int_values, real_values, char_values, count, status)` |
| SUBROUTINE | `dp_validate_crc` | 5314 | `SUBROUTINE dp_validate_crc(var_name, crc_value, status)` |
| SUBROUTINE | `dp_backup` | 5393 | `SUBROUTINE dp_backup(var_name, backup_id, status)` |
| SUBROUTINE | `dp_restore` | 5419 | `SUBROUTINE dp_restore(var_name, backup_id, status)` |
| SUBROUTINE | `dp_register_var_view` | 5448 | `SUBROUTINE dp_register_var_view(category, scope, var_name, storage_type, data_type, status)` |
| SUBROUTINE | `dp_list_var_views` | 5502 | `SUBROUTINE dp_list_var_views(category, scope, views, nViews, status)` |
| SUBROUTINE | `dp_calculate_file_crc32` | 5561 | `SUBROUTINE dp_calculate_file_crc32(file_path, crc32, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
