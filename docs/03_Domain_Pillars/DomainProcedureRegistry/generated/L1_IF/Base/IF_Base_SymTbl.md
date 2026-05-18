# `IF_Base_SymTbl.f90`

- **Source**: `L1_IF/Base/IF_Base_SymTbl.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_Base_SymTbl`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_SymTbl`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base_SymTbl`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_SymTbl.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `HashTableEntryType` (lines 92–96)

```fortran
      TYPE :: HashTableEntryType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: key = ""  ! Key (variable name)
        INTEGER(i4) :: value_index = 0                  ! Value (index in symbol table entries)
        TYPE(HashTableEntryType), POINTER :: next => NULL()  ! Next entry in collision chain
    END TYPE HashTableEntryType
```

### `HashTableType` (lines 99–104)

```fortran
    TYPE :: HashTableType
        LOGICAL :: initialized = .FALSE.             ! Initialization flag
        INTEGER(i4) :: size = 0                          ! Number of buckets
        INTEGER(i4) :: count = 0                         ! Number of entries
        TYPE(HashTableEntryType), ALLOCATABLE :: buckets(:)  ! Buckets array
    END TYPE HashTableType
```

### `SymTableEntryType` (lines 111–132)

```fortran
    TYPE :: SymTableEntryType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: variable_name = ""  ! Variable name (unique identifier)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Associated data ID (points to metadata)
        INTEGER(i4) :: data_type = 0                            ! Data type (IF_DATA_TYPE_*)
        INTEGER(i4) :: storage_type = 0                         ! Storage type (IF_STORAGE_TYPE_*)
        LOGICAL :: is_valid = .FALSE.                      ! Entry validity (logical deletion flag)
        INTEGER(i4) :: next_free = 0                            ! Index of next free entry (for free list)
        ! Usage statistics fields
        INTEGER(i4) :: access_count = 0                         ! Number of times the variable was accessed
        INTEGER(i4) :: update_count = 0                         ! Number of times the variable was updated
        REAL :: last_access_time = 0.0                      ! Last access timestamp (seconds since initialization)
        REAL :: creation_time = 0.0                         ! Creation timestamp (seconds since initialization)
        ! LRU cache fields
        INTEGER(i4) :: prev = 0                                 ! Previous entry in LRU list
        INTEGER(i4) :: next = 0                                 ! Next entry in LRU list
        
        ! Version control fields
        INTEGER(i4) :: current_version = 0                      ! Current version number
        INTEGER(i4) :: version_count = 0                        ! Number of versions stored
        INTEGER(i4) :: version_history(IF_MAX_VERSIONS)            ! Array to store version data IDs
        REAL(wp) :: version_timestamps(IF_MAX_VERSIONS)  ! Timestamps for each version
    END TYPE SymTableEntryType
```

### `VariableMigrationType` (lines 135–140)

```fortran
    TYPE :: VariableMigrationType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: variable_name = ""  ! Variable name
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Data ID
        INTEGER(i4) :: data_type = 0                            ! Data type
        INTEGER(i4) :: storage_type = 0                         ! Storage type
    END TYPE VariableMigrationType
```

### `SymbolTableType` (lines 143–156)

```fortran
    TYPE :: SymbolTableType
        LOGICAL :: initialized = .FALSE.    ! Whether symbol table is initialized
        INTEGER(i4) :: max_entries = 0          ! Max number of supported entries
        INTEGER(i4) :: entry_count = 0          ! Current number of valid entries
        TYPE(SymTableEntryType), ALLOCATABLE :: entries(:)  ! Entry array
        TYPE(HashTableType) :: hash_table   ! Hash table for fast variable name lookups
        INTEGER(i4) :: free_list_head = 0       ! Head of the free entry list
        INTEGER(i4) :: resize_threshold = 0     ! Threshold for table resizing
        REAL :: init_time = 0.0             ! Symbol table initialization time (seconds)
        ! LRU cache fields
        INTEGER(i4) :: lru_head = 0             ! Head of LRU cache list (most recently used)
        INTEGER(i4) :: lru_tail = 0             ! Tail of LRU cache list (least recently used)
        INTEGER(i4) :: lru_max_size = 100       ! Maximum size of LRU cache (default: 100 entries)
    END TYPE SymbolTableType
```

### `SymbolTableStatusType` (lines 159–168)

```fortran
    TYPE :: SymbolTableStatusType
        LOGICAL :: initialized = .FALSE.
        INTEGER(i4) :: entry_count = 0
        INTEGER(i4) :: max_entries = 0
        INTEGER(i4) :: free_entries = 0
        REAL(wp) :: initialization_time = 0.0
        INTEGER(i4) :: lru_cache_size = 0
        INTEGER(i4) :: lru_max_size = 0
        REAL(wp) :: memory_usage = 0.0  ! Estimated memory usage in KB
    END TYPE SymbolTableStatusType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `calculate_hash` | 210 | `FUNCTION calculate_hash(key, size) RESULT(hash_value)` |
| SUBROUTINE | `hash_table_create` | 237 | `SUBROUTINE hash_table_create(table, size, status)` |
| SUBROUTINE | `hash_table_destroy` | 289 | `SUBROUTINE hash_table_destroy(table, status)` |
| SUBROUTINE | `hash_table_insert` | 338 | `SUBROUTINE hash_table_insert(table, key, value, status)` |
| SUBROUTINE | `hash_table_delete` | 404 | `SUBROUTINE hash_table_delete(table, key, status)` |
| FUNCTION | `hash_table_find` | 470 | `FUNCTION hash_table_find(table, key, status) RESULT(found_index)` |
| SUBROUTINE | `init_sym_table` | 518 | `SUBROUTINE init_sym_table(status, max_entries)` |
| SUBROUTINE | `destroy_sym_table` | 596 | `SUBROUTINE destroy_sym_table(status)` |
| SUBROUTINE | `register_variable` | 644 | `SUBROUTINE register_variable(variable_name, data_id, data_type, storage_type, status)` |
| SUBROUTINE | `register_variable_batch` | 747 | `SUBROUTINE register_variable_batch(var_names, data_ids, data_types, storage_types, count, status)` |
| SUBROUTINE | `unregister_variable` | 824 | `SUBROUTINE unregister_variable(variable_name, status)` |
| SUBROUTINE | `register_temp_variable` | 892 | `SUBROUTINE register_temp_variable(temp_var_name, data_type, storage_type, status)` |
| SUBROUTINE | `find_variable` | 959 | `SUBROUTINE find_variable(variable_name, data_id, data_type, storage_type, status, log_error_flag)` |
| SUBROUTINE | `get_variable_data_id` | 1020 | `SUBROUTINE get_variable_data_id(variable_name, data_id, status)` |
| SUBROUTINE | `get_variable_count` | 1088 | `SUBROUTINE get_variable_count(count, status)` |
| FUNCTION | `LOWERCASE` | 1239 | `FUNCTION LOWERCASE(str) RESULT(lower_str)` |
| FUNCTION | `INT_TO_STR` | 1258 | `FUNCTION INT_TO_STR(i) RESULT(str)` |
| SUBROUTINE | `register_simple_temp_variable` | 1270 | `SUBROUTINE register_simple_temp_variable(variable_name, status)` |
| FUNCTION | `export_variable_for_migration` | 1326 | `FUNCTION export_variable_for_migration(variable_name, migration_data, status) RESULT(success)` |
| FUNCTION | `import_variable_from_migration` | 1373 | `FUNCTION import_variable_from_migration(migration_data, status) RESULT(success)` |
| SUBROUTINE | `migrate_variable_between_nodes` | 1421 | `SUBROUTINE migrate_variable_between_nodes(variable_name, source_node_id, target_node_id, status)` |
| FUNCTION | `get_relative_time` | 1480 | `FUNCTION get_relative_time() RESULT(rel_time)` |
| SUBROUTINE | `update_variable_access_stats` | 1497 | `SUBROUTINE update_variable_access_stats(variable_name)` |
| SUBROUTINE | `update_variable_update_stats` | 1515 | `SUBROUTINE update_variable_update_stats(variable_name)` |
| SUBROUTINE | `get_variable_usage_stats` | 1533 | `SUBROUTINE get_variable_usage_stats(variable_name, access_count, update_count, &` |
| SUBROUTINE | `save_symbol_table_to_file` | 1575 | `SUBROUTINE save_symbol_table_to_file(file_path, status)` |
| SUBROUTINE | `load_symbol_table_from_file` | 1661 | `SUBROUTINE load_symbol_table_from_file(file_path, status)` |
| SUBROUTINE | `update_lru_cache` | 1866 | `SUBROUTINE update_lru_cache(entry_index, status)` |
| SUBROUTINE | `configure_lru_cache_size` | 1954 | `SUBROUTINE configure_lru_cache_size(new_size, status)` |
| SUBROUTINE | `save_variable_version` | 1993 | `SUBROUTINE save_variable_version(variable_name, status)` |
| SUBROUTINE | `rollback_to_version` | 2064 | `SUBROUTINE rollback_to_version(variable_name, target_version, status)` |
| SUBROUTINE | `get_variable_version_history` | 2160 | `SUBROUTINE get_variable_version_history(variable_name, versions, timestamps, version_count, status)` |
| SUBROUTINE | `get_variable_current_version` | 2217 | `SUBROUTINE get_variable_current_version(variable_name, current_version, status)` |
| SUBROUTINE | `get_symbol_table_status` | 2263 | `SUBROUTINE get_symbol_table_status(status_data, status)` |
| SUBROUTINE | `generate_symbol_table_report` | 2309 | `SUBROUTINE generate_symbol_table_report(report_file, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
