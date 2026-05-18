# `IF_IO_StructFile.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_IO_StructFile.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_IO_StructFile`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_IO_StructFile`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_IO_StructFile`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_IO_StructFile.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `StructFileIOCapabilities` (lines 119–127)

```fortran
    TYPE :: StructFileIOCapabilities
        LOGICAL :: supports_binary_format   = .TRUE.
        LOGICAL :: supports_text_format     = .TRUE.
        LOGICAL :: supports_cache           = .TRUE.
        LOGICAL :: supports_encryption      = .TRUE.
        LOGICAL :: supports_compression     = .TRUE.
        LOGICAL :: supports_sharding        = .TRUE.
        LOGICAL :: supports_distributed_io  = .TRUE.
    END TYPE StructFileIOCapabilities
```

### `DataBlockType` (lines 184–230)

```fortran
    TYPE :: DataBlockType
        CHARACTER(LEN=64) :: data_id = ""                 ! Unique data ID
        INTEGER(i4) :: data_type = 0                         ! Data type (INT/DP/CHAR/STRUCT/CLASS)
        INTEGER(i4) :: dimensions(4) = [0, 0, 0, 0]          ! Array dimensions (1-4D)
        INTEGER(KIND=8) :: mem_size = 0                  ! Memory size (bytes)
        LOGICAL :: is_allocated = .FALSE.                ! Whether memory allocated
        INTEGER(i4) :: node_id = 1                           ! Node ID
        LOGICAL :: is_cached = .FALSE.                   ! Whether in cache
        CHARACTER(LEN=256) :: file_path = ""             ! Associated file path
        LOGICAL :: has_changes = .FALSE.                 ! Whether modified
        
        ! Partial update support
        LOGICAL :: has_partial_changes = .FALSE.          ! Whether partially modified
        INTEGER(i4) :: changed_ranges(4,2,16) = 0         ! Changed ranges: [start,end] for each dimension
        INTEGER(i4) :: changed_range_count = 0                ! Number of changed ranges
        
        ! Encryption and compression
        LOGICAL :: is_encrypted = .FALSE.                ! Whether data is encrypted
        CHARACTER(LEN=64) :: encryption_key = ""         ! Encryption key (simplified)
        INTEGER(i4) :: encryption_algorithm = 0                 ! Encryption algorithm ID
        LOGICAL :: is_compressed = .FALSE.                ! Whether data is compressed
        INTEGER(i4) :: compression_algorithm = 0                ! Compression algorithm ID
        INTEGER(KIND=8) :: original_size = 0             ! Original uncompressed size
        
        ! File format and chunking
        CHARACTER(LEN=32) :: file_format = "BINARY"     ! File format (BINARY, TXT, CSV, etc.)
        INTEGER(i4) :: chunk_size = IF_DEFAULT_BLOCK_SIZE        ! Chunk size for large files
        INTEGER(i4) :: total_chunks = 0                      ! Total number of chunks
        INTEGER(i4) :: current_chunk = 0                     ! Current chunk index
        
        ! Backup and versioning
        CHARACTER(LEN=64) :: backup_id = ""              ! Backup ID
        INTEGER(i4) :: version = 1                            ! Data version
        CHARACTER(LEN=256) :: backup_path = ""            ! Backup file path
        
        ! Access frequency and priority for cache management
        INTEGER(i4) :: access_count = 0                     ! Access count
        INTEGER(i4) :: last_access_time = 0                   ! Last access timestamp
        REAL :: cache_priority = 0.0                     ! Cache priority score
        
        ! Data fields
        INTEGER, ALLOCATABLE :: int_data(:,:,:,:)        ! Integer data
        REAL(KIND=8), ALLOCATABLE :: real_data(:,:,:,:)  ! Double precision data
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), ALLOCATABLE :: char_data(:,:,:,:)  ! Character data
        CLASS(*), ALLOCATABLE :: struct_data             ! Struct data
        CLASS(*), ALLOCATABLE :: class_data              ! Class data
    END TYPE DataBlockType
```

### `CacheEntryType` (lines 238–257)

```fortran
    TYPE :: CacheEntryType
        CHARACTER(LEN=64) :: data_id = ""                 ! Data ID
        INTEGER(i4) :: node_id = 1                           ! Node ID
        INTEGER(i4) :: device_id = 1                          ! Device ID (for diagnostics)
        INTEGER(i4) :: device_type = IF_DEV_TYPE_CPU             ! Device type (1=CPU/2=GPU, etc.)
        CHARACTER(LEN=64) :: device_name = ""             ! Device name/description
        INTEGER(i4) :: mem_block_id = 0                       ! StructMemPool block id (0 = none)
        INTEGER(i4) :: access_count = 0                       ! Access count
        INTEGER(KIND=8) :: last_access_time = 0           ! Last access time (ms)
        LOGICAL :: is_preloaded = .FALSE.                 ! Whether preloaded
        ! Data storage fields (similar to DataBlockType)
        INTEGER(i4) :: data_type = 0                         ! Data type
        INTEGER(i4) :: dimensions(4) = [0, 0, 0, 0]           ! Data dimensions
        INTEGER(KIND=8) :: mem_size = 0                  ! Memory size
        LOGICAL :: is_allocated = .FALSE.                ! Whether data is allocated
        ! Actual data storage
        INTEGER, ALLOCATABLE :: int_data(:,:,:,:)        ! Integer data
        REAL(KIND=8), ALLOCATABLE :: real_data(:,:,:,:)  ! Double precision data
        CHARACTER(LEN=IF_SFM_CHAR_RECORD_LEN), ALLOCATABLE :: char_data(:,:,:,:)  ! Character data
    END TYPE CacheEntryType
```

### `FileHandleType` (lines 266–290)

```fortran
    TYPE :: FileHandleType
        CHARACTER(LEN=256) :: file_path = ""              ! File path
        INTEGER(i4) :: file_unit = -1                         ! File unit number
        LOGICAL :: is_open = .FALSE.                      ! Whether open
        CHARACTER(LEN=16) :: file_mode = ""               ! "READ"/"WRITE"/"APPEND"
        CHARACTER(LEN=16) :: file_format = ""             ! "FORMATTED"/"UNFORMATTED"
        INTEGER(KIND=8) :: total_file_size = 0            ! Total file size (bytes)
        INTEGER(i4) :: total_chunks = 0                       ! Total chunks
        INTEGER(i4) :: node_id = 1                           ! Node ID
        TYPE(StructMetaType) :: metadata                  ! File metadata
        
        ! Enhanced features
        LOGICAL :: is_encrypted = .FALSE.                 ! Whether file is encrypted
        LOGICAL :: is_compressed = .FALSE.                ! Whether file is compressed
        INTEGER(i4) :: encryption_algorithm = 0                  ! Encryption algorithm
        INTEGER(i4) :: compression_algorithm = 0                 ! Compression algorithm
        INTEGER(i4) :: file_type = 1                            ! File type (1=BINARY, 2=TXT, 3=CSV, etc.)
        INTEGER(i4) :: backup_count = 0                         ! Number of backups
        CHARACTER(LEN=64) :: backup_id = ""               ! Current backup ID
        
        ! Chunk management
        INTEGER, ALLOCATABLE :: chunk_offsets(:)           ! Chunk offsets in file
        INTEGER, ALLOCATABLE :: chunk_sizes(:)             ! Chunk sizes
        INTEGER, ALLOCATABLE :: chunk_checksums(:)         ! Chunk checksums
    END TYPE FileHandleType
```

### `NodeInfoType` (lines 295–307)

```fortran
    TYPE :: NodeInfoType
        INTEGER(i4) :: node_id = 0                           ! Node ID
        CHARACTER(LEN=64) :: node_name = ""               ! Node name
        INTEGER(i4) :: device_id = 1                          ! Device ID
        INTEGER(i4) :: device_type = IF_DEV_TYPE_CPU             ! Device type (1=CPU/2=GPU, etc.)
        CHARACTER(LEN=64) :: device_name = ""             ! Device name
        INTEGER(KIND=8) :: total_mem_bytes = 0_8          ! Total device memory (bytes)
        INTEGER(KIND=8) :: free_mem_bytes = 0_8           ! Free device memory (bytes)
        LOGICAL :: is_active = .FALSE.                    ! Whether active
        INTEGER(i4) :: cache_size = IF_MAX_CACHE_SIZE            ! Cache size
        TYPE(CacheEntryType), ALLOCATABLE :: cache(:)     ! Node cache
        TYPE(FileHandleType), ALLOCATABLE :: backup_files(:) ! Backup files
    END TYPE NodeInfoType
```

### `StructFileManagerType` (lines 312–348)

```fortran
    TYPE :: StructFileManagerType
        LOGICAL :: is_initialized = .FALSE.               ! Whether initialized
        INTEGER(i4) :: num_nodes = 0                         ! Number of nodes
        INTEGER(i4) :: max_nodes = IF_MAX_DISTRIBUTED_NODES      ! Max nodes
        TYPE(NodeInfoType), ALLOCATABLE :: nodes(:)       ! Node list
        TYPE(FileHandleType), ALLOCATABLE :: open_files(:) ! Open files
        INTEGER(i4) :: cache_size = IF_MAX_CACHE_SIZE            ! Global cache size
        TYPE(CacheEntryType), ALLOCATABLE :: global_cache(:) ! Global cache
    CONTAINS
        PROCEDURE :: init => init_struct_file_manager_impl
        PROCEDURE :: destroy => destroy_struct_file_manager_impl
        PROCEDURE :: open_struct_file => open_struct_file_impl
        PROCEDURE :: close_struct_file => close_struct_file_impl
        PROCEDURE :: write_data_chunks => write_data_chunks_impl
        PROCEDURE :: read_data_chunks => read_data_chunks_impl
        PROCEDURE :: preload_data_to_cache => preload_data_to_cache_impl
        PROCEDURE :: evict_lru_cache_entry => evict_lru_cache_entry_impl
        PROCEDURE :: clear_cache_all => clear_cache_all_impl
        PROCEDURE :: get_active_node_count => get_active_node_count_impl
        PROCEDURE :: migrate_data_block => migrate_data_block_impl
        PROCEDURE :: validate_data_block => validate_data_block_impl
        PROCEDURE :: update_cache_access_time => update_cache_access_time_impl
        PROCEDURE :: get_current_time => get_current_time_impl
        PROCEDURE :: check_cache
        PROCEDURE :: update_data_partial
        PROCEDURE :: encrypt_data_block
        PROCEDURE :: decrypt_data_block
        PROCEDURE :: compress_data_block
        PROCEDURE :: decompress_data_block
        PROCEDURE :: configure_cache_strategy
        PROCEDURE :: get_cache_statistics
        PROCEDURE :: detect_file_format
        PROCEDURE :: convert_file_format
        PROCEDURE :: migrate_data_to_node
        PROCEDURE :: shard_file
        PROCEDURE :: merge_files
    END TYPE StructFileManagerType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `sfm_register_io_filters` | 360 | `SUBROUTINE sfm_register_io_filters(write_filter, read_filter, status)` |
| FUNCTION | `int_to_str` | 381 | `FUNCTION int_to_str(i) RESULT(str)` |
| FUNCTION | `int_to_str8` | 389 | `FUNCTION int_to_str8(i) RESULT(str)` |
| FUNCTION | `get_current_timestamp` | 397 | `FUNCTION get_current_timestamp() RESULT(timestamp)` |
| SUBROUTINE | `ensure_struct_block_for_cache` | 411 | `SUBROUTINE ensure_struct_block_for_cache(this, cache_idx, data_block, block_id, status)` |
| FUNCTION | `normalize_path` | 489 | `FUNCTION normalize_path(path) RESULT(normalized)` |
| FUNCTION | `get_current_working_dir` | 531 | `FUNCTION get_current_working_dir() RESULT(cwd)` |
| FUNCTION | `ensure_trailing_slash` | 554 | `FUNCTION ensure_trailing_slash(path) RESULT(processed)` |
| FUNCTION | `join_paths` | 565 | `FUNCTION join_paths(base_path, filename) RESULT(joined)` |
| FUNCTION | `create_windows_path` | 588 | `FUNCTION create_windows_path(path) RESULT(win_path)` |
| FUNCTION | `extract_filename` | 606 | `FUNCTION extract_filename(path) RESULT(filename)` |
| FUNCTION | `allocate_file_unit` | 630 | `FUNCTION allocate_file_unit() RESULT(unit)` |
| SUBROUTINE | `release_file_unit` | 649 | `SUBROUTINE release_file_unit(unit)` |
| SUBROUTINE | `init_struct_file_manager` | 661 | `SUBROUTINE init_struct_file_manager(num_nodes, status)` |
| SUBROUTINE | `destroy_struct_file_manager` | 671 | `SUBROUTINE destroy_struct_file_manager(status)` |
| SUBROUTINE | `open_struct_file` | 680 | `SUBROUTINE open_struct_file(file_path, file_mode, file_format, file_handle, status)` |
| SUBROUTINE | `close_struct_file` | 694 | `SUBROUTINE close_struct_file(file_handle, status)` |
| SUBROUTINE | `write_data_chunks` | 704 | `SUBROUTINE write_data_chunks(var_name, data_block, file_handle, status)` |
| SUBROUTINE | `read_data_chunks` | 717 | `SUBROUTINE read_data_chunks(var_name, file_handle, target_node_id, data_block, status)` |
| SUBROUTINE | `preload_data_to_cache` | 731 | `SUBROUTINE preload_data_to_cache(var_name, data_block, status)` |
| SUBROUTINE | `clear_cache_all` | 751 | `SUBROUTINE clear_cache_all(status)` |
| SUBROUTINE | `init_struct_file_manager_impl` | 760 | `SUBROUTINE init_struct_file_manager_impl(this, num_nodes, status)` |
| SUBROUTINE | `destroy_struct_file_manager_impl` | 890 | `SUBROUTINE destroy_struct_file_manager_impl(this, status)` |
| SUBROUTINE | `open_struct_file_impl` | 954 | `SUBROUTINE open_struct_file_impl(this, file_path, file_mode, file_format, &` |
| SUBROUTINE | `close_struct_file_impl` | 1237 | `SUBROUTINE close_struct_file_impl(this, file_handle, status)` |
| SUBROUTINE | `write_data_chunks_impl` | 1298 | `SUBROUTINE write_data_chunks_impl(this, var_name, data_block, &` |
| SUBROUTINE | `prepare_data_block_for_write` | 1553 | `SUBROUTINE prepare_data_block_for_write(this, data_id, data_block, status)` |
| SUBROUTINE | `read_data_chunks_impl` | 1664 | `SUBROUTINE read_data_chunks_impl(this, var_name, file_handle, &` |
| SUBROUTINE | `preload_data_to_cache_impl` | 1996 | `SUBROUTINE preload_data_to_cache_impl(this, var_name, data_id, &` |
| SUBROUTINE | `evict_lru_cache_entry_impl` | 2106 | `SUBROUTINE evict_lru_cache_entry_impl(this, lru_index, status)` |
| SUBROUTINE | `clear_cache_all_impl` | 2154 | `SUBROUTINE clear_cache_all_impl(this, status)` |
| SUBROUTINE | `get_active_node_count_impl` | 2200 | `SUBROUTINE get_active_node_count_impl(this, count, status)` |
| SUBROUTINE | `migrate_data_block_impl` | 2229 | `SUBROUTINE migrate_data_block_impl(this, data_id, src_node_id, &` |
| SUBROUTINE | `validate_data_block_impl` | 2290 | `SUBROUTINE validate_data_block_impl(this, data_block, status)` |
| SUBROUTINE | `update_cache_access_time_impl` | 2344 | `SUBROUTINE update_cache_access_time_impl(this, data_id, status)` |
| FUNCTION | `get_current_time_impl` | 2451 | `FUNCTION get_current_time_impl(this) RESULT(time_ms)` |
| SUBROUTINE | `read_file_metadata` | 2468 | `SUBROUTINE read_file_metadata(this, file_handle, status)` |
| SUBROUTINE | `update_file_metadata` | 2576 | `SUBROUTINE update_file_metadata(this, file_handle, var_name, data_id, &` |
| SUBROUTINE | `write_file_metadata_to_file` | 2601 | `SUBROUTINE write_file_metadata_to_file(file_handle, status)` |
| FUNCTION | `dims_to_str` | 2679 | `FUNCTION dims_to_str(dims, num_dims) RESULT(str)` |
| SUBROUTINE | `str_to_dims` | 2694 | `SUBROUTINE str_to_dims(str, dims, num_dims, status)` |
| FUNCTION | `int8_to_str` | 2734 | `FUNCTION int8_to_str(i8) RESULT(str)` |
| FUNCTION | `STRING` | 2745 | `FUNCTION STRING(len) RESULT(res)` |
| SUBROUTINE | `update_data_partial` | 2756 | `SUBROUTINE update_data_partial(this, data_block, start_idx, end_idx, new_data, error)` |
| SUBROUTINE | `encrypt_data_block` | 2924 | `SUBROUTINE encrypt_data_block(this, data_block, algorithm, key, error)` |
| SUBROUTINE | `decrypt_data_block` | 3079 | `SUBROUTINE decrypt_data_block(this, data_block, key, error)` |
| SUBROUTINE | `compress_data_block` | 3239 | `SUBROUTINE compress_data_block(this, data_block, algorithm, error)` |
| SUBROUTINE | `decompress_data_block` | 3367 | `SUBROUTINE decompress_data_block(this, data_block, error)` |
| SUBROUTINE | `configure_cache_strategy` | 3477 | `SUBROUTINE configure_cache_strategy(this, strategy, cache_size, error)` |
| SUBROUTINE | `get_cache_statistics` | 3601 | `SUBROUTINE get_cache_statistics(this, node_id, hit_rate, usage_count, error)` |
| FUNCTION | `detect_file_format` | 3739 | `FUNCTION detect_file_format(this, file_path, error) RESULT(format)` |
| SUBROUTINE | `convert_file_format` | 3861 | `SUBROUTINE convert_file_format(this, input_path, output_path, input_format, output_format, error)` |
| SUBROUTINE | `migrate_data_to_node` | 4175 | `SUBROUTINE migrate_data_to_node(this, data_block, source_node, target_node, error)` |
| SUBROUTINE | `ensure_struct_block_for_node_cache` | 4330 | `SUBROUTINE ensure_struct_block_for_node_cache(this, data_block, target_node, &` |
| SUBROUTINE | `shard_file` | 4445 | `SUBROUTINE shard_file(this, file_path, num_shards, output_dir, error)` |
| SUBROUTINE | `merge_files` | 4668 | `SUBROUTINE merge_files(this, input_files, output_file, error)` |
| SUBROUTINE | `sfm_init` | 4902 | `SUBROUTINE sfm_init(num_nodes, error)` |
| SUBROUTINE | `sfm_destroy` | 4925 | `SUBROUTINE sfm_destroy(error)` |
| SUBROUTINE | `sfm_open_file` | 4941 | `SUBROUTINE sfm_open_file(file_path, mode, format, file_handle, error)` |
| SUBROUTINE | `sfm_close_file` | 4950 | `SUBROUTINE sfm_close_file(file_handle, error)` |
| SUBROUTINE | `sfm_write_data` | 4956 | `SUBROUTINE sfm_write_data(file_handle, data_block, error, var_name)` |
| SUBROUTINE | `sfm_read_data` | 4989 | `SUBROUTINE sfm_read_data(var_name, file_handle, data_block, error)` |
| SUBROUTINE | `sfm_preload_cache` | 5061 | `SUBROUTINE sfm_preload_cache(var_name, data_block, error)` |
| SUBROUTINE | `sfm_clear_cache` | 5077 | `SUBROUTINE sfm_clear_cache(error)` |
| SUBROUTINE | `sfm_configure_cache` | 5082 | `SUBROUTINE sfm_configure_cache(strategy, cache_size, error)` |
| SUBROUTINE | `sfm_cache_stats` | 5089 | `SUBROUTINE sfm_cache_stats(node_id, hit_rate, usage_count, error)` |
| SUBROUTINE | `sfm_create_data_block` | 5100 | `SUBROUTINE sfm_create_data_block(data_block, data_type, dimensions, error)` |
| SUBROUTINE | `sfm_destroy_data_block` | 5188 | `SUBROUTINE sfm_destroy_data_block(data_block, error)` |
| SUBROUTINE | `sfm_update_partial` | 5247 | `SUBROUTINE sfm_update_partial(data_block, start_idx, end_idx, new_data, error)` |
| SUBROUTINE | `sfm_encrypt_block` | 5259 | `SUBROUTINE sfm_encrypt_block(data_block, algorithm, key, error)` |
| SUBROUTINE | `sfm_decrypt_block` | 5267 | `SUBROUTINE sfm_decrypt_block(data_block, key, error)` |
| SUBROUTINE | `sfm_compress_block` | 5277 | `SUBROUTINE sfm_compress_block(data_block, algorithm, error)` |
| SUBROUTINE | `sfm_decompress_block` | 5284 | `SUBROUTINE sfm_decompress_block(data_block, error)` |
| FUNCTION | `sfm_detect_format` | 5293 | `FUNCTION sfm_detect_format(file_path, error) RESULT(format)` |
| SUBROUTINE | `sfm_convert_format` | 5300 | `SUBROUTINE sfm_convert_format(input_path, output_path, input_format, output_format, error)` |
| SUBROUTINE | `sfm_migrate_to_node` | 5312 | `SUBROUTINE sfm_migrate_to_node(data_block, source_node, target_node, error)` |
| SUBROUTINE | `sfm_shard_file` | 5320 | `SUBROUTINE sfm_shard_file(file_path, num_shards, output_dir, error)` |
| SUBROUTINE | `sfm_merge_files` | 5328 | `SUBROUTINE sfm_merge_files(input_files, output_file, error)` |
| SUBROUTINE | `sfm_get_shards` | 5335 | `SUBROUTINE sfm_get_shards(logical_id, chunks, count, status)` |
| FUNCTION | `sfm_get_error_string` | 5370 | `FUNCTION sfm_get_error_string(status_code) RESULT(error_string)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
