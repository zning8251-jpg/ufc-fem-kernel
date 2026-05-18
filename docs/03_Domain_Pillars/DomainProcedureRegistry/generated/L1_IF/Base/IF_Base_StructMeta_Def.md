# `IF_Base_StructMeta_Def.f90`

- **Source**: `L1_IF/Base/IF_Base_StructMeta_Def.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Base_StructMeta_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_StructMeta_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base_StructMeta`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_StructMeta_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `DeviceInfoType` (lines 96–103)

```fortran
    TYPE :: DeviceInfoType
        CHARACTER(LEN=IF_MAX_DEVICE_ID_LENGTH) :: device_id = ""              ! Unique device ID
        CHARACTER(LEN=IF_MAX_DEVICE_NAME_LENGTH) :: device_name = ""          ! Device name
        CHARACTER(LEN=IF_MAX_DEVICE_TYPE_LENGTH) :: device_type = ""          ! Device type (GPU/CPU/TPU/Storage)
        CHARACTER(LEN=IF_MAX_DEVICE_LOCATION_LENGTH) :: location = ""         ! Device physical location
        LOGICAL :: is_primary_device = .FALSE.                            ! Whether this is the primary device
        CHARACTER(LEN=20) :: association_time = ""                        ! Association timestamp
    END TYPE DeviceInfoType
```

### `StructMetaVersionType` (lines 107–116)

```fortran
    TYPE :: StructMetaVersionType
        INTEGER(i4) :: version_number = 0                     ! Version number
        CHARACTER(LEN=20) :: version_time = ""            ! Version creation time
        CHARACTER(LEN=IF_VERSION_NOTE_MAX_LENGTH) :: version_note = "" ! Version note/description
        INTEGER(i4) :: crc32 = 0                              ! Checksum at this version
        INTEGER(i4) :: data_type = 0                          ! Data type at this version
        INTEGER(i4) :: dimensions(IF_MAX_DIMENSIONS) = [0,0,0,0] ! Dimensions at this version
        INTEGER(KIND=8) :: total_size = 0                 ! Total size at this version
        LOGICAL :: is_chunked = .FALSE.                   ! Chunked status at this version
    END TYPE StructMetaVersionType
```

### `StructMetaType` (lines 119–157)

```fortran
    TYPE :: StructMetaType
        ! Identification linking (aligned with symbol table)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Unique data ID (linked to symbol table)
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = ""      ! Linked variable name (from symbol table)
        INTEGER(i4) :: storage_type = IF_STORAGE_TYPE_STRUCTURED    ! Storage type (fixed as structured, no modification)
        
        ! Data type and dimensions (core characteristics of structured data)
        INTEGER(i4) :: data_type = 0                            ! Data type (IF_DATA_TYPE_INT/DP/CHAR/STRUCT/CLASS)
        INTEGER(i4) :: dimensions(IF_MAX_DIMENSIONS) = [0,0,0,0]   ! 1-4D dimensions (0 for invalid dimensions)
        INTEGER(i4) :: valid_dim_count = 0                     ! Number of valid dimensions (1-4)
        INTEGER(KIND=8) :: element_size = 0                ! Size of single element (bytes, e.g., INT=4, DP=8)
        INTEGER(KIND=8) :: total_elements = 0             ! Total number of elements (product of dimensions)
        INTEGER(KIND=8) :: total_size = 0                 ! Total memory size (bytes = element_size * total_elements)
        
        ! Chunk and memory characteristics (adapted for industrial IO)
        LOGICAL :: is_chunked = .FALSE.                    ! Whether to use chunked storage
        INTEGER(KIND=8) :: chunk_size = IF_DEFAULT_CHUNK_SIZE ! Chunk size (bytes)
        INTEGER(i4) :: total_chunks = 0                       ! Total number of chunks
        INTEGER(KIND=8), ALLOCATABLE :: chunk_offsets(:)   ! Chunk offsets (bytes, valid only for chunked storage)
        
        ! Integrity and lifecycle
        INTEGER(i4) :: crc32 = 0                              ! Data checksum (ensures integrity)
        CHARACTER(LEN=20) :: create_time = ""             ! Creation time (YYYY-MM-DD HH:MM:SS)
        CHARACTER(LEN=20) :: update_time = ""             ! Last update time
        LOGICAL :: is_valid = .FALSE.                    ! Metadata validity (logical deletion flag)
        LOGICAL :: is_constant = .FALSE.                  ! Whether data is constant (non-updatable)
        
        ! Version control fields
        INTEGER(i4) :: version_number = 1                     ! Current version number
        INTEGER(i4) :: version_history_count = 0              ! Number of versions in history
        TYPE(StructMetaVersionType), ALLOCATABLE :: version_history(:) ! Version history
        
        ! Device association fields
        INTEGER(i4) :: device_count = 0                       ! Number of associated devices
        TYPE(DeviceInfoType), DIMENSION(IF_MAX_DEVICES_PER_META) :: associated_devices ! Associated devices

        ! Hash index linkage for data_id (used by internal index structure)
        INTEGER(i4) :: next_in_id_hash = 0
    END TYPE StructMetaType
```

### `StructMetaManagerType` (lines 160–175)

```fortran
    TYPE :: StructMetaManagerType
        LOGICAL :: initialized = .FALSE.                  ! Whether manager is initialized
        INTEGER(i4) :: max_meta_count = 0                     ! Max number of supported metadata entries
        INTEGER(i4) :: current_meta_count = 0                 ! Current number of valid metadata entries
        TYPE(StructMetaType), ALLOCATABLE :: meta_list(:) ! Array of metadata entries
        INTEGER(i4) :: total_versions = 0                     ! Total number of versions created
        INTEGER(i4) :: total_device_associations = 0          ! Total number of device associations
        INTEGER(i4) :: total_queries = 0                      ! Total number of queries executed
        INTEGER(i4) :: total_updates = 0                      ! Total number of updates performed
        INTEGER(i4) :: total_validations = 0                  ! Total number of validations performed
        INTEGER(i4) :: total_errors = 0                       ! Total number of errors encountered

        ! Hash index for data_id: bucket count and bucket heads
        INTEGER(i4) :: id_bucket_count = 0                    ! Number of buckets in hash index
        INTEGER, ALLOCATABLE :: id_bucket_head(:)         ! Head indices for each bucket
    END TYPE StructMetaManagerType
```

### `QueryConditionType` (lines 200–208)

```fortran
    TYPE :: QueryConditionType
        INTEGER(i4) :: cond_type = IF_QUERY_COND_TYPE_NONE   ! Type of condition
        CHARACTER(LEN=IF_MAX_ID_LENGTH) :: str_value1 = "" ! String value 1 (for IDs, names, etc.)
        CHARACTER(LEN=IF_MAX_ID_LENGTH) :: str_value2 = "" ! String value 2 (for range queries)
        INTEGER(i4) :: int_value1 = 0                     ! Integer value 1 (for types, sizes, etc.)
        INTEGER(i4) :: int_value2 = 0                     ! Integer value 2 (for range queries)
        LOGICAL :: logical_value = .FALSE.            ! Logical value (for boolean flags)
        LOGICAL :: is_active = .FALSE.                ! Whether condition is active
    END TYPE QueryConditionType
```

### `QueryFilterType` (lines 211–215)

```fortran
    TYPE :: QueryFilterType
        TYPE(QueryConditionType) :: conditions(IF_MAX_QUERY_CONDITIONS) ! Array of conditions
        INTEGER(i4) :: active_cond_count = 0              ! Number of active conditions
        LOGICAL :: use_and_logic = .TRUE.             ! Use AND (TRUE) or OR (FALSE) between conditions
    END TYPE QueryFilterType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `init_struct_meta_mgr` | 245 | `SUBROUTINE init_struct_meta_mgr(status, max_meta_count)` |
| SUBROUTINE | `destroy_struct_meta_mgr` | 315 | `SUBROUTINE destroy_struct_meta_mgr(status)` |
| SUBROUTINE | `struct_meta_create` | 378 | `SUBROUTINE struct_meta_create(var_name, data_type, dimensions, element_size, is_chunked, meta, status)` |
| FUNCTION | `hash_data_id` | 519 | `PURE FUNCTION hash_data_id(data_id, bucket_count) RESULT(bucket_index)` |
| SUBROUTINE | `insert_meta_index_by_id` | 539 | `SUBROUTINE insert_meta_index_by_id(data_id, meta_index)` |
| SUBROUTINE | `remove_meta_index_by_id` | 555 | `SUBROUTINE remove_meta_index_by_id(data_id, meta_index)` |
| SUBROUTINE | `store_meta_entry` | 586 | `SUBROUTINE store_meta_entry(meta_index, meta)` |
| SUBROUTINE | `invalidate_meta_entry` | 599 | `SUBROUTINE invalidate_meta_entry(meta_index)` |
| SUBROUTINE | `find_meta_index_by_id` | 609 | `SUBROUTINE find_meta_index_by_id(data_id, meta_index, status)` |
| SUBROUTINE | `struct_meta_query` | 656 | `SUBROUTINE struct_meta_query(query_key, query_type, meta, status)` |
| SUBROUTINE | `struct_meta_try_query` | 748 | `SUBROUTINE struct_meta_try_query(query_key, query_type, meta, found, status)` |
| SUBROUTINE | `struct_meta_update` | 834 | `SUBROUTINE struct_meta_update(data_id, update_field, new_value, status)` |
| SUBROUTINE | `struct_meta_save_version` | 909 | `SUBROUTINE struct_meta_save_version(data_id, version_note, status)` |
| SUBROUTINE | `struct_meta_get_version` | 1003 | `SUBROUTINE struct_meta_get_version(data_id, version_number, version_out, status)` |
| SUBROUTINE | `struct_meta_get_version_history` | 1062 | `SUBROUTINE struct_meta_get_version_history(data_id, history_count, version_numbers, version_times, version_notes, status)` |
| SUBROUTINE | `struct_meta_restore_version` | 1128 | `SUBROUTINE struct_meta_restore_version(data_id, version_number, status)` |
| SUBROUTINE | `struct_meta_add_device_association` | 1209 | `SUBROUTINE struct_meta_add_device_association(data_id, device_id, device_name, device_type, &` |
| SUBROUTINE | `struct_meta_remove_device_association` | 1301 | `SUBROUTINE struct_meta_remove_device_association(data_id, device_id, status)` |
| SUBROUTINE | `struct_meta_get_device_association` | 1370 | `SUBROUTINE struct_meta_get_device_association(data_id, device_id, device_info, status)` |
| SUBROUTINE | `struct_meta_get_all_device_associations` | 1426 | `SUBROUTINE struct_meta_get_all_device_associations(data_id, device_list, device_count, status)` |
| SUBROUTINE | `get_struct_meta_statistics` | 1526 | `SUBROUTINE get_struct_meta_statistics(total_entries, valid_entries, max_capacity, &` |
| SUBROUTINE | `get_struct_meta_type_statistics` | 1568 | `SUBROUTINE get_struct_meta_type_statistics(type_counts, type_sizes, unique_types, status)` |
| SUBROUTINE | `get_struct_meta_storage_statistics` | 1640 | `SUBROUTINE get_struct_meta_storage_statistics(total_storage, chunked_count, constant_count, &` |
| SUBROUTINE | `get_struct_meta_operation_statistics` | 1707 | `SUBROUTINE get_struct_meta_operation_statistics(total_queries, total_updates, total_validations, &` |
| SUBROUTINE | `get_struct_meta_device_statistics` | 1739 | `SUBROUTINE get_struct_meta_device_statistics(total_associations, avg_devices_per_meta, &` |
| SUBROUTINE | `struct_meta_export` | 1839 | `SUBROUTINE struct_meta_export(meta_id, file_path, file_format, status)` |
| SUBROUTINE | `struct_meta_export_all` | 1921 | `SUBROUTINE struct_meta_export_all(file_path, file_format, status)` |
| SUBROUTINE | `struct_meta_import` | 2001 | `SUBROUTINE struct_meta_import(file_path, file_format, imported_meta_id, status)` |
| SUBROUTINE | `struct_meta_import_all` | 2070 | `SUBROUTINE struct_meta_import_all(file_path, file_format, imported_count, status)` |
| SUBROUTINE | `struct_meta_batch_import` | 2139 | `SUBROUTINE struct_meta_batch_import(file_paths, file_format, imported_count, status)` |
| SUBROUTINE | `export_meta_to_json` | 2226 | `SUBROUTINE export_meta_to_json(meta_id, file_path, status)` |
| SUBROUTINE | `export_all_meta_to_json` | 2286 | `SUBROUTINE export_all_meta_to_json(file_path, status)` |
| SUBROUTINE | `export_meta_to_xml` | 2354 | `SUBROUTINE export_meta_to_xml(meta_id, file_path, status)` |
| SUBROUTINE | `export_all_meta_to_xml` | 2411 | `SUBROUTINE export_all_meta_to_xml(file_path, status)` |
| SUBROUTINE | `export_meta_to_csv` | 2471 | `SUBROUTINE export_meta_to_csv(meta_id, file_path, status)` |
| SUBROUTINE | `export_all_meta_to_csv` | 2510 | `SUBROUTINE export_all_meta_to_csv(file_path, status)` |
| SUBROUTINE | `export_meta_to_binary` | 2549 | `SUBROUTINE export_meta_to_binary(meta_id, file_path, status)` |
| SUBROUTINE | `export_all_meta_to_binary` | 2600 | `SUBROUTINE export_all_meta_to_binary(file_path, status)` |
| SUBROUTINE | `import_meta_from_json` | 2662 | `SUBROUTINE import_meta_from_json(file_path, imported_meta_id, status)` |
| SUBROUTINE | `import_all_meta_from_json` | 2705 | `SUBROUTINE import_all_meta_from_json(file_path, imported_count, status)` |
| SUBROUTINE | `import_meta_from_xml` | 2731 | `SUBROUTINE import_meta_from_xml(file_path, imported_meta_id, status)` |
| SUBROUTINE | `import_all_meta_from_xml` | 2768 | `SUBROUTINE import_all_meta_from_xml(file_path, imported_count, status)` |
| SUBROUTINE | `import_meta_from_csv` | 2791 | `SUBROUTINE import_meta_from_csv(file_path, imported_meta_id, status)` |
| SUBROUTINE | `import_all_meta_from_csv` | 2827 | `SUBROUTINE import_all_meta_from_csv(file_path, imported_count, status)` |
| SUBROUTINE | `import_meta_from_binary` | 2850 | `SUBROUTINE import_meta_from_binary(file_path, imported_meta_id, status)` |
| SUBROUTINE | `import_all_meta_from_binary` | 2907 | `SUBROUTINE import_all_meta_from_binary(file_path, imported_count, status)` |
| SUBROUTINE | `add_meta_to_manager` | 2979 | `SUBROUTINE add_meta_to_manager(new_meta, assigned_id, status)` |
| SUBROUTINE | `import_sample_metadata_entries` | 3013 | `SUBROUTINE import_sample_metadata_entries(imported_count, status)` |
| SUBROUTINE | `struct_meta_delete` | 3073 | `SUBROUTINE struct_meta_delete(data_id, status)` |
| SUBROUTINE | `struct_meta_validate` | 3117 | `SUBROUTINE struct_meta_validate(data_id, current_crc32, is_valid, status)` |
| SUBROUTINE | `get_struct_meta_count` | 3152 | `SUBROUTINE get_struct_meta_count(count, status)` |
| SUBROUTINE | `get_timestamp` | 3319 | `SUBROUTINE get_timestamp(timestamp)` |
| FUNCTION | `INT_TO_STR` | 3331 | `FUNCTION INT_TO_STR(i) RESULT(str)` |
| FUNCTION | `INT_ARR_TO_STR` | 3353 | `FUNCTION INT_ARR_TO_STR(arr) RESULT(str)` |
| FUNCTION | `REAL_TO_STR` | 3369 | `FUNCTION REAL_TO_STR(r) RESULT(str)` |
| FUNCTION | `LOGICAL_TO_STR` | 3380 | `FUNCTION LOGICAL_TO_STR(log_val) RESULT(str)` |
| SUBROUTINE | `struct_meta_create_batch` | 3394 | `SUBROUTINE struct_meta_create_batch(variable_names, dimensions, chunk_sizes, is_constants, &` |
| SUBROUTINE | `struct_meta_update_batch` | 3485 | `SUBROUTINE struct_meta_update_batch(data_ids, new_chunk_sizes, new_is_constants, &` |
| SUBROUTINE | `struct_meta_delete_batch` | 3563 | `SUBROUTINE struct_meta_delete_batch(data_ids, status_codes_out, status)` |
| SUBROUTINE | `struct_meta_persist` | 3620 | `SUBROUTINE struct_meta_persist(file_path, status)` |
| SUBROUTINE | `struct_meta_recover` | 3733 | `SUBROUTINE struct_meta_recover(file_path, status)` |
| SUBROUTINE | `init_query_filter` | 3951 | `SUBROUTINE init_query_filter(filter, use_and_logic)` |
| SUBROUTINE | `add_query_condition` | 3981 | `SUBROUTINE add_query_condition(filter, cond_type, status, str_value1, str_value2, &` |
| SUBROUTINE | `struct_meta_complex_query` | 4070 | `SUBROUTINE struct_meta_complex_query(filter, meta_results, result_count, max_results, status)` |
| SUBROUTINE | `struct_meta_validate_all` | 4215 | `SUBROUTINE struct_meta_validate_all(invalid_count, status)` |
| SUBROUTINE | `struct_meta_repair` | 4292 | `SUBROUTINE struct_meta_repair(repair_count, status)` |
| SUBROUTINE | `struct_meta_recover_from_error` | 4367 | `SUBROUTINE struct_meta_recover_from_error(error_code, status)` |
| SUBROUTINE | `get_struct_meta_error_summary` | 4441 | `SUBROUTINE get_struct_meta_error_summary(total_errors, error_by_type, status)` |
| SUBROUTINE | `struct_meta_reset_error_counter` | 4473 | `SUBROUTINE struct_meta_reset_error_counter(status)` |
| SUBROUTINE | `calculate_metadata_crc` | 4525 | `SUBROUTINE calculate_metadata_crc(meta, crc)` |
| SUBROUTINE | `calculate_valid_dim_count` | 4537 | `SUBROUTINE calculate_valid_dim_count(dimensions, count)` |
| SUBROUTINE | `calculate_total_elements` | 4555 | `SUBROUTINE calculate_total_elements(dimensions, valid_dim_count, total)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
