# `IF_UnstructFile_Mgr.f90`

- **Source**: `L1_IF/IO/Checkpoint/IF_UnstructFile_Mgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `IF_UnstructFile_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_UnstructFile_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_UnstructFile`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `IO/Checkpoint`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/IO/Checkpoint/IF_UnstructFile_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UnstructFileHandleType` (lines 70–76)

```fortran
    TYPE :: UnstructFileHandleType
        CHARACTER(LEN=256) :: file_path = ""
        INTEGER(i4) :: file_unit = -1
        LOGICAL :: is_open = .FALSE.
        INTEGER(i4) :: format_type = IF_FORMAT_BINARY
        CHARACTER(LEN=16) :: mode = ""  ! "READ" / "WRITE"
    END TYPE UnstructFileHandleType
```

### `ChunkMetaType` (lines 81–89)

```fortran
    TYPE :: ChunkMetaType
        CHARACTER(LEN=256) :: file_path = ""
        CHARACTER(LEN=64)  :: data_id   = ""
        INTEGER(i4) :: chunk_id = 0
        INTEGER(KIND=8) :: file_offset = 0_8
        INTEGER(KIND=8) :: chunk_size  = 0_8
        INTEGER(i4) :: unstruct_type = 0
        LOGICAL :: is_valid = .FALSE.
    END TYPE ChunkMetaType
```

### `HeaderCacheEntryType` (lines 100–106)

```fortran
    TYPE :: HeaderCacheEntryType
        CHARACTER(LEN=256) :: file_path = ""
        CHARACTER(LEN=64)  :: data_id   = ""
        INTEGER(i4) :: unstruct_type = 0
        INTEGER(KIND=8) :: mem_size = 0_8
        LOGICAL :: is_valid = .FALSE.
    END TYPE HeaderCacheEntryType
```

### `DataFileMapEntryType` (lines 117–121)

```fortran
    TYPE :: DataFileMapEntryType
        CHARACTER(LEN=64)  :: data_id = ""
        CHARACTER(LEN=256) :: file_path = ""
        LOGICAL :: is_valid = .FALSE.
    END TYPE DataFileMapEntryType
```

### `UnstructFileIOCapabilities` (lines 127–135)

```fortran
    TYPE :: UnstructFileIOCapabilities
        LOGICAL :: supports_binary_format   = .TRUE.
        LOGICAL :: supports_text_format     = .TRUE.
        LOGICAL :: supports_cache           = .TRUE.
        LOGICAL :: supports_encryption      = .TRUE.
        LOGICAL :: supports_compression     = .TRUE.
        LOGICAL :: supports_sharding        = .FALSE.
        LOGICAL :: supports_distributed_io  = .FALSE.
    END TYPE UnstructFileIOCapabilities
```

### `UfmIOOptionsType` (lines 142–146)

```fortran
    TYPE :: UfmIOOptionsType
        INTEGER(i4) :: default_format_type   = IF_FORMAT_BINARY
        INTEGER(i4) :: default_compress_type = 0
        INTEGER(i4) :: default_encrypt_type  = 0
    END TYPE UfmIOOptionsType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `ufm_init` | 159 | `SUBROUTINE ufm_init(status)` |
| SUBROUTINE | `ufm_set_default_io_options` | 194 | `SUBROUTINE ufm_set_default_io_options(format_type, compress_type, encrypt_type, status)` |
| SUBROUTINE | `ufm_register_io_filters` | 217 | `SUBROUTINE ufm_register_io_filters(write_filter, read_filter, status)` |
| SUBROUTINE | `ufm_destroy` | 230 | `SUBROUTINE ufm_destroy(status)` |
| SUBROUTINE | `ufm_write_unstruct_data` | 257 | `SUBROUTINE ufm_write_unstruct_data(data_id, file_path, format_type, status)` |
| SUBROUTINE | `ufm_read_unstruct_data` | 426 | `SUBROUTINE ufm_read_unstruct_data(file_path, data_id, unstruct_type, mem_size, status)` |
| SUBROUTINE | `ufm_load_unstruct_data` | 605 | `SUBROUTINE ufm_load_unstruct_data(file_path, data_id, status)` |
| SUBROUTINE | `ufm_write_data_to_chunks` | 767 | `SUBROUTINE ufm_write_data_to_chunks(data_id, base_filename, status, chunk_size)` |
| SUBROUTINE | `ufm_merge_chunks_to_file` | 915 | `SUBROUTINE ufm_merge_chunks_to_file(data_id, base_filename, output_filename, status)` |
| SUBROUTINE | `write_adjacency_payload_binary` | 1031 | `SUBROUTINE write_adjacency_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_adjacency_payload_text` | 1073 | `SUBROUTINE write_adjacency_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `write_linked_list_payload_binary` | 1114 | `SUBROUTINE write_linked_list_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_linked_list_payload_text` | 1156 | `SUBROUTINE write_linked_list_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `serialize_linked_list_to_buffer` | 1199 | `SUBROUTINE serialize_linked_list_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_linked_list_from_buffer` | 1288 | `SUBROUTINE deserialize_linked_list_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `write_linked_list_payload_with_filter` | 1362 | `SUBROUTINE write_linked_list_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_linked_list_payload_with_filter` | 1423 | `SUBROUTINE load_linked_list_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_hash_table_payload_binary` | 1504 | `SUBROUTINE write_hash_table_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_skip_list_payload_binary` | 1550 | `SUBROUTINE write_skip_list_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_skip_list_payload_text` | 1601 | `SUBROUTINE write_skip_list_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `write_hash_table_payload_text` | 1650 | `SUBROUTINE write_hash_table_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `serialize_hash_table_to_buffer` | 1696 | `SUBROUTINE serialize_hash_table_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_hash_table_from_buffer` | 1806 | `SUBROUTINE deserialize_hash_table_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `write_hash_table_payload_with_filter` | 1886 | `SUBROUTINE write_hash_table_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_hash_table_payload_with_filter` | 1947 | `SUBROUTINE load_hash_table_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_skip_list_payload_with_filter` | 2028 | `SUBROUTINE write_skip_list_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_skip_list_payload_with_filter` | 2089 | `SUBROUTINE load_skip_list_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_adjacency_payload_with_filter` | 2170 | `SUBROUTINE write_adjacency_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_adjacency_payload_with_filter` | 2231 | `SUBROUTINE load_adjacency_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_graph_payload_with_filter` | 2308 | `SUBROUTINE write_graph_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_graph_payload_with_filter` | 2369 | `SUBROUTINE load_graph_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_graph_payload_binary` | 2445 | `SUBROUTINE write_graph_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_graph_payload_text` | 2488 | `SUBROUTINE write_graph_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `write_queue_payload_with_filter` | 2545 | `SUBROUTINE write_queue_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `write_queue_payload_binary` | 2606 | `SUBROUTINE write_queue_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `write_queue_payload_text` | 2654 | `SUBROUTINE write_queue_payload_text(unit, data_id, fmt, status)` |
| SUBROUTINE | `serialize_queue_to_buffer` | 2703 | `SUBROUTINE serialize_queue_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_queue_from_buffer` | 2826 | `SUBROUTINE deserialize_queue_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `serialize_skip_list_to_buffer` | 2956 | `SUBROUTINE serialize_skip_list_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_skip_list_from_buffer` | 3101 | `SUBROUTINE deserialize_skip_list_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `serialize_graph_to_buffer` | 3235 | `SUBROUTINE serialize_graph_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_graph_from_buffer` | 3336 | `SUBROUTINE deserialize_graph_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `serialize_adjacency_to_buffer` | 3450 | `SUBROUTINE serialize_adjacency_to_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `deserialize_adjacency_from_buffer` | 3548 | `SUBROUTINE deserialize_adjacency_from_buffer(data_id, buffer, payload_size, status)` |
| SUBROUTINE | `copy_int_bytes_to_buffer` | 3645 | `SUBROUTINE copy_int_bytes_to_buffer(src_bytes, num_bytes, dest_buffer, offset)` |
| SUBROUTINE | `copy_real_bytes_to_buffer` | 3658 | `SUBROUTINE copy_real_bytes_to_buffer(src_bytes, num_bytes, dest_buffer, offset)` |
| SUBROUTINE | `clear_chunk_table` | 3671 | `SUBROUTINE clear_chunk_table()` |
| SUBROUTINE | `register_single_chunk` | 3680 | `SUBROUTINE register_single_chunk(data_id, file_path, unstruct_type, mem_size, status)` |
| SUBROUTINE | `register_chunk_in_generic_mgr` | 3730 | `SUBROUTINE register_chunk_in_generic_mgr(data_id, file_path, mem_size, status)` |
| SUBROUTINE | `ufm_get_chunks` | 3753 | `SUBROUTINE ufm_get_chunks(data_id, chunks, count, status)` |
| SUBROUTINE | `ufm_clear_cache` | 3822 | `SUBROUTINE ufm_clear_cache(status)` |
| SUBROUTINE | `ufm_get_cache_stats` | 3842 | `SUBROUTINE ufm_get_cache_stats(hits, misses, requests, status)` |
| SUBROUTINE | `clear_data_file_map` | 3855 | `SUBROUTINE clear_data_file_map()` |
| SUBROUTINE | `ufm_register_data_file` | 3866 | `SUBROUTINE ufm_register_data_file(data_id, file_path, status)` |
| SUBROUTINE | `ufm_find_data_file` | 3935 | `SUBROUTINE ufm_find_data_file(data_id, file_path, found, status)` |
| SUBROUTINE | `load_adjacency_payload_binary` | 3992 | `SUBROUTINE load_adjacency_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_linked_list_payload_binary` | 4055 | `SUBROUTINE load_linked_list_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_hash_table_payload_binary` | 4093 | `SUBROUTINE load_hash_table_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_skip_list_payload_binary` | 4142 | `SUBROUTINE load_skip_list_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_graph_payload_binary` | 4217 | `SUBROUTINE load_graph_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_queue_payload_with_filter` | 4302 | `SUBROUTINE load_queue_payload_with_filter(unit, data_id, io_flags, status)` |
| SUBROUTINE | `load_queue_payload_binary` | 4383 | `SUBROUTINE load_queue_payload_binary(unit, data_id, status)` |
| SUBROUTINE | `load_adjacency_payload_text` | 4464 | `SUBROUTINE load_adjacency_payload_text(unit, data_id, status)` |
| SUBROUTINE | `load_linked_list_payload_text` | 4541 | `SUBROUTINE load_linked_list_payload_text(unit, data_id, status)` |
| SUBROUTINE | `load_hash_table_payload_text` | 4592 | `SUBROUTINE load_hash_table_payload_text(unit, data_id, status)` |
| SUBROUTINE | `load_skip_list_payload_text` | 4644 | `SUBROUTINE load_skip_list_payload_text(unit, data_id, status)` |
| SUBROUTINE | `load_graph_payload_text` | 4711 | `SUBROUTINE load_graph_payload_text(unit, data_id, status)` |
| SUBROUTINE | `load_queue_payload_text` | 4795 | `SUBROUTINE load_queue_payload_text(unit, data_id, status)` |
| FUNCTION | `WRITE_INT` | 4903 | `FUNCTION WRITE_INT(value) RESULT(str)` |
| SUBROUTINE | `ufm_migrate_data_file` | 4909 | `SUBROUTINE ufm_migrate_data_file(data_id, new_file_path, status)` |
| SUBROUTINE | `ufm_preload_data_list` | 5023 | `SUBROUTINE ufm_preload_data_list(data_ids, num_ids, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
