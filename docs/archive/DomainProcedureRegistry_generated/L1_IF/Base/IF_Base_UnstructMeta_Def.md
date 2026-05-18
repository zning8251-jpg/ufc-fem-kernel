# `IF_Base_UnstructMeta_Def.f90`

- **Source**: `L1_IF/Base/IF_Base_UnstructMeta_Def.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Base_UnstructMeta_Def`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Base_UnstructMeta_Def`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Base_UnstructMeta`
- **第四段角色（四段式）**: `_Def`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Base_UnstructMeta_Def.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UnstructAttrType` (lines 76–91)

```fortran
    TYPE :: UnstructAttrType
        ! Hash table-specific attributes
        INTEGER(i4) :: hash_bucket_count = IF_DEFAULT_HASH_BUCKETS ! Hash bucket count
        REAL :: hash_load_factor = 0.0                    ! Hash load factor (element_count/bucket_count)
        CHARACTER(LEN=32) :: hash_collision = "CHAINING"   ! Collision resolution (CHAINING/OPEN_ADDR)
        ! Linked list-specific attributes
        LOGICAL :: list_is_circular = .FALSE.             ! Whether circular linked list
        LOGICAL :: list_is_double = .TRUE.                ! Whether double-linked list
        ! Graph/adjacency list-specific attributes
        INTEGER(KIND=8) :: graph_vertex_count = 0         ! Number of graph vertices
        INTEGER(KIND=8) :: graph_edge_count = 0           ! Number of graph edges
        LOGICAL :: graph_is_directed = .FALSE.            ! Whether directed graph
        ! Queue-specific attributes
        INTEGER(KIND=8) :: queue_capacity = IF_DEFAULT_QUEUE_CAPACITY ! Queue capacity
        LOGICAL :: queue_is_dynamic = .TRUE.              ! Whether queue supports dynamic expansion
    END TYPE UnstructAttrType
```

### `UnstructMetaType` (lines 94–113)

```fortran
    TYPE :: UnstructMetaType
        ! Identification linking (aligned with symbol table, non-modifiable)
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""        ! Unique data ID (linked to symbol table)
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = ""      ! Linked variable name (from symbol table)
        INTEGER(i4) :: storage_type = IF_STORAGE_TYPE_UNSTRUCTURED  ! Storage type (fixed as unstructured)
        INTEGER(i4) :: unstruct_type = 0                        ! Unstructured type (IF_DATA_TYPE_HASH/...)
        
        ! Core attributes (common to unstructured data)
        INTEGER(KIND=8) :: element_count = 0               ! Current number of elements
        TYPE(UnstructAttrType) :: type_attr = UnstructAttrType()  ! Explicit init for nested type
        CHARACTER(LEN=IF_MAX_SERIAL_FMT_LEN) :: serial_format = "BINARY" ! Serialization format
        INTEGER(KIND=8) :: total_size = 0                 ! Total memory size (bytes)
        
        ! Integrity and lifecycle
        INTEGER(i4) :: crc32 = 0                              ! Data checksum (ensures integrity)
        CHARACTER(LEN=20) :: create_time = ""             ! Creation time (YYYY-MM-DD HH:MM:SS)
        CHARACTER(LEN=20) :: update_time = ""             ! Last update time
        LOGICAL :: is_valid = .FALSE.                    ! Metadata validity (logical deletion flag)
        LOGICAL :: is_frozen = .FALSE.                   ! Whether frozen (attribute updates denied)
    END TYPE UnstructMetaType
```

### `UnstructMetaManagerType` (lines 116–121)

```fortran
    TYPE :: UnstructMetaManagerType
        LOGICAL :: initialized = .FALSE.                  ! Whether manager is initialized
        INTEGER(i4) :: max_meta_count = 0                     ! Max number of supported metadata entries
        INTEGER(i4) :: current_meta_count = 0                 ! Current number of valid metadata entries
        TYPE(UnstructMetaType), ALLOCATABLE :: meta_list(:) ! Array of metadata entries
    END TYPE UnstructMetaManagerType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `init_unstruct_meta_mgr` | 145 | `SUBROUTINE init_unstruct_meta_mgr(status, max_meta_count)` |
| SUBROUTINE | `destroy_unstruct_meta_mgr` | 197 | `SUBROUTINE destroy_unstruct_meta_mgr(status)` |
| SUBROUTINE | `unstruct_meta_create` | 232 | `SUBROUTINE unstruct_meta_create(var_name, unstruct_type, init_attr, meta, status)` |
| SUBROUTINE | `unstruct_meta_query` | 332 | `SUBROUTINE unstruct_meta_query(query_key, query_type, meta, status)` |
| SUBROUTINE | `unstruct_meta_try_query` | 400 | `SUBROUTINE unstruct_meta_try_query(query_key, query_type, meta, found, status)` |
| SUBROUTINE | `unstruct_meta_update` | 462 | `SUBROUTINE unstruct_meta_update(data_id, update_field, new_value, new_attr, status)` |
| SUBROUTINE | `unstruct_meta_delete` | 590 | `SUBROUTINE unstruct_meta_delete(data_id, status)` |
| SUBROUTINE | `unstruct_meta_validate` | 628 | `SUBROUTINE unstruct_meta_validate(data_id, current_crc32, is_valid, status)` |
| SUBROUTINE | `get_unstruct_meta_count` | 663 | `SUBROUTINE get_unstruct_meta_count(count, status)` |
| FUNCTION | `unstruct_type_to_str` | 854 | `FUNCTION unstruct_type_to_str(type_code) RESULT(type_str)` |
| SUBROUTINE | `get_timestamp` | 879 | `SUBROUTINE get_timestamp(timestamp)` |
| FUNCTION | `INT_TO_STR` | 891 | `FUNCTION INT_TO_STR(i) RESULT(str)` |
| FUNCTION | `INT8_TO_STR` | 902 | `FUNCTION INT8_TO_STR(i8) RESULT(str)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
