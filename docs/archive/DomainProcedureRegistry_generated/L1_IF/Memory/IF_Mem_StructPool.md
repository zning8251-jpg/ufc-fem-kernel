# `IF_Mem_StructPool.f90`

- **Source**: `L1_IF/Memory/IF_Mem_StructPool.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Mem_StructPool`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Mem_StructPool`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Mem_StructPool`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Memory`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Memory/IF_Mem_StructPool.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `StructMemBlockType` (lines 110–129)

```fortran
    TYPE :: StructMemBlockType
        CHARACTER(LEN=20) :: alloc_time = ""             ! "Allocation timestamp"
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: var_name = "" ! "Variable name"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""   ! "Data ID"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_SMEM_DIMS) = [0,0,0,0]       ! "Dimension information"
        INTEGER(i4) :: char_len = 0                          ! "Character length (only for CHAR type)"
        INTEGER(i4) :: device_id = 1                         ! "Device ID"
        INTEGER(KIND=8) :: mem_addr = 0                  ! "Memory address"
        INTEGER(KIND=8) :: block_size = 0                ! "Block size (bytes)"
        INTEGER(KIND=8) :: used_size = 0                 ! "Used size (bytes)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether in use"
        LOGICAL :: is_locked = .FALSE.                   ! "Whether locked (prevent LRU eviction)"
        LOGICAL :: is_unified = .FALSE.                  ! "Whether unified memory"
        INTEGER(i4) :: subarray_id = 0                       ! "Unified memory subarray ID"
        INTEGER(i4) :: struct_id = 0                         ! "Structure definition ID (0=none)"
        INTEGER(i4) :: class_id = 0                          ! "Class definition ID (0=none)"
        CHARACTER(LEN=20) :: last_access_time = ""       ! "Last access timestamp"
        INTEGER(i4) :: lru_count = 0                         ! "LRU counter"
    END TYPE StructMemBlockType
```

### `CptrStorageType` (lines 133–136)

```fortran
    TYPE, PRIVATE :: CptrStorageType
        SEQUENCE
        INTEGER(C_INT8_T) :: d(1)
    END TYPE CptrStorageType
```

### `StructMemberType` (lines 141–148)

```fortran
    TYPE :: StructMemberType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Member name"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_DIMENSIONS) = [0,0,0,0]      ! "Dimensions"
        INTEGER(i4) :: char_len = 0                          ! "Character length"
        INTEGER(KIND=8) :: offset = 0                    ! "Memory offset"
        LOGICAL :: is_public = .TRUE.                    ! "Whether public"
    END TYPE StructMemberType
```

### `StructDefType` (lines 153–161)

```fortran
    TYPE :: StructDefType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Structure name"
        INTEGER(i4) :: struct_id = 0                         ! "Structure ID"
        INTEGER(i4) :: member_count = 0                      ! "Number of members"
        TYPE(StructMemberType), ALLOCATABLE :: members(:) ! "Member list"
        INTEGER(KIND=8) :: size = 0                      ! "Structure size (bytes)"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: metadata = ""  ! "Metadata"
        LOGICAL :: is_complete = .FALSE.                 ! "Whether fully defined"
    END TYPE StructDefType
```

### `ClassDefType` (lines 166–176)

```fortran
    TYPE :: ClassDefType
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: name = ""     ! "Class name"
        CHARACTER(LEN=IF_MAX_VAR_NAME_LEN) :: parent_name = "" ! "Parent class name"
        INTEGER(i4) :: class_id = 0                          ! "Class ID"
        INTEGER(i4) :: parent_id = 0                         ! "Parent class ID"
        INTEGER(i4) :: member_count = 0                      ! "Number of members"
        TYPE(StructMemberType), ALLOCATABLE :: members(:) ! "Member list"
        INTEGER(KIND=8) :: size = 0                      ! "Class size (bytes)"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: metadata = ""  ! "Metadata"
        LOGICAL :: is_complete = .FALSE.                 ! "Whether fully defined"
    END TYPE ClassDefType
```

### `UnifiedSubarrayType` (lines 181–189)

```fortran
    TYPE :: UnifiedSubarrayType
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: data_id = ""   ! "Data ID"
        INTEGER(i4) :: data_type = IF_DATA_TYPE_INT             ! "Data type"
        INTEGER(i4) :: dims(IF_MAX_DIMENSIONS) = [0,0,0,0]      ! "Dimensions"
        INTEGER(i4) :: char_len = 0                          ! "Character length"
        INTEGER(KIND=8) :: offset = 0                    ! "Offset (bytes)"
        INTEGER(KIND=8) :: size = 0                      ! "Size (bytes)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether in use"
    END TYPE UnifiedSubarrayType
```

### `StructDeviceBufferMapType` (lines 194–201)

```fortran
    TYPE :: StructDeviceBufferMapType
        INTEGER(i4) :: block_id = 0                          ! "Mapped block ID"
        INTEGER(i4) :: device_id = 0                         ! "Target device ID"
        TYPE(C_PTR) :: device_ptr = C_NULL_PTR           ! "Opaque device buffer handle / pointer"
        INTEGER(KIND=8) :: size_bytes = 0_8              ! "Buffer size in bytes"
        INTEGER(i4) :: sync_state = 0                        ! "Synchronization state (host/device/in-sync)"
        LOGICAL :: is_used = .FALSE.                     ! "Whether this mapping slot is in use"
    END TYPE StructDeviceBufferMapType
```

### `StructMemPoolType` (lines 207–231)

```fortran
    TYPE :: StructMemPoolType
        LOGICAL :: initialized = .FALSE.                 ! "Whether memory pool is initialized"
        INTEGER(i4) :: bound_device_id = 1                   ! "Bound device ID (pool memory only for this device)"
        INTEGER(i4) :: max_blocks = IF_MAX_SMEM_BLOCKS          ! "Maximum number of memory blocks"
        INTEGER(i4) :: used_blocks = 0                       ! "Number of used memory blocks"
        INTEGER(KIND=8) :: total_mem = 0                 ! "Total pool memory (bytes)"
        INTEGER(KIND=8) :: free_mem = 0                  ! "Free memory (bytes)"
        INTEGER(i4) :: alloc_count = 0                       ! "Allocation count"
        INTEGER(i4) :: free_count = 0                        ! "Free count"
        INTEGER(i4) :: lru_evict_count = 0                   ! "LRU eviction count"
        INTEGER(i4) :: expand_count = 0                      ! "Expansion count"
        INTEGER(i4) :: struct_count = 0                      ! "Number of structure definitions"
        INTEGER(i4) :: class_count = 0                       ! "Number of class definitions"
        TYPE(StructDefType), ALLOCATABLE :: struct_defs(:) ! "Structure definition list"
        TYPE(ClassDefType), ALLOCATABLE :: class_defs(:) ! "Class definition list"
        TYPE(StructMemBlockType), ALLOCATABLE :: mem_blocks(:) ! "Memory block list"
        TYPE(StructDeviceBufferMapType), ALLOCATABLE :: device_buffer_maps(:) ! "Block-device buffer mapping list"
        INTEGER(i4) :: device_buffer_map_count = 0           ! "Number of active device buffer mappings"
        ! Unified memory related
        LOGICAL :: unified_mem_enabled = .FALSE.         ! "Whether unified memory is enabled"
        CHARACTER(LEN=IF_MAX_DATA_ID_LEN) :: unified_mem_id = "" ! "Unified memory ID"
        INTEGER(KIND=8) :: unified_mem_size = 0          ! "Unified memory size (bytes)"
        INTEGER(KIND=8) :: unified_mem_used = 0          ! "Used unified memory (bytes)"
        TYPE(UnifiedSubarrayType), ALLOCATABLE :: unified_subarrays(:) ! "Unified memory subarrays"
    END TYPE StructMemPoolType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `add_class_member` | 302 | `SUBROUTINE add_class_member(class_id, member_name, member_type, dims, char_len, is_public, status)` |
| SUBROUTINE | `add_struct_member` | 400 | `SUBROUTINE add_struct_member(struct_id, member_name, member_type, dims, char_len, is_public, status)` |
| SUBROUTINE | `alloc_char1d` | 498 | `SUBROUTINE alloc_char1d(var_name, dim1, char_len, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_char2d` | 641 | `SUBROUTINE alloc_char2d(var_name, dim1, dim2, char_len, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_char3d` | 785 | `SUBROUTINE alloc_char3d(var_name, dim1, dim2, dim3, char_len, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_char4d` | 930 | `SUBROUTINE alloc_char4d(var_name, dim1, dim2, dim3, dim4, char_len, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_class` | 1075 | `SUBROUTINE alloc_class(class_name, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_class_array` | 1187 | `SUBROUTINE alloc_class_array(var_name, class_name, dims, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_dp1d` | 1446 | `SUBROUTINE alloc_dp1d(var_name, dim1, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_dp2d` | 1583 | `SUBROUTINE alloc_dp2d(var_name, dim1, dim2, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_dp3d` | 1722 | `SUBROUTINE alloc_dp3d(var_name, dim1, dim2, dim3, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_dp4d` | 1861 | `SUBROUTINE alloc_dp4d(var_name, dim1, dim2, dim3, dim4, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_int1d` | 2000 | `SUBROUTINE alloc_int1d(var_name, dim1, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_int2d` | 2137 | `SUBROUTINE alloc_int2d(var_name, dim1, dim2, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_int3d` | 2275 | `SUBROUTINE alloc_int3d(var_name, dim1, dim2, dim3, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_int4d` | 2414 | `SUBROUTINE alloc_int4d(var_name, dim1, dim2, dim3, dim4, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_struct` | 2553 | `SUBROUTINE alloc_struct(struct_name, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_struct_array` | 2641 | `SUBROUTINE alloc_struct_array(var_name, struct_name, dims, block_id, status, use_unified)` |
| SUBROUTINE | `alloc_struct_mem` | 2874 | `SUBROUTINE alloc_struct_mem(var_name, data_type, dims, char_len, block_id, status, use_unified)` |
| SUBROUTINE | `allocate_unified_memory` | 2967 | `SUBROUTINE allocate_unified_memory(var_name, data_type, dims, char_len, aligned_size, block_id, status)` |
| FUNCTION | `calculate_struct_size` | 3041 | `FUNCTION calculate_struct_size(struct_id, status) RESULT(struct_size)` |
| SUBROUTINE | `check_struct_block_device_mem` | 3094 | `SUBROUTINE check_struct_block_device_mem(block_id, is_sufficient, status)` |
| SUBROUTINE | `check_struct_block_device_mem_on_device` | 3176 | `SUBROUTINE check_struct_block_device_mem_on_device(block_id, device_id, is_sufficient, status)` |
| SUBROUTINE | `compute_member_size` | 3258 | `SUBROUTINE compute_member_size(member, elem_size, elem_count, total_size)` |
| SUBROUTINE | `create_struct_unified_mem` | 3284 | `SUBROUTINE create_struct_unified_mem(pool_name, pool_size, status)` |
| SUBROUTINE | `dealloc_struct_mem` | 3361 | `SUBROUTINE dealloc_struct_mem(block_id, status)` |
| SUBROUTINE | `destroy_struct_mem_pool` | 3451 | `SUBROUTINE destroy_struct_mem_pool(status)` |
| SUBROUTINE | `evict_lru_blocks` | 3543 | `SUBROUTINE evict_lru_blocks(required_size, status)` |
| SUBROUTINE | `finalize_class_def` | 3631 | `SUBROUTINE finalize_class_def(class_id, status)` |
| SUBROUTINE | `finalize_struct_def` | 3703 | `SUBROUTINE finalize_struct_def(struct_id, status)` |
| SUBROUTINE | `find_free_block` | 3753 | `SUBROUTINE find_free_block(required_size, block_id, status)` |
| SUBROUTINE | `get_char1d_ptr` | 3810 | `SUBROUTINE get_char1d_ptr(mem_block_id, ptr, dim1, char_len, status)` |
| SUBROUTINE | `get_char2d_ptr` | 3898 | `SUBROUTINE get_char2d_ptr(mem_block_id, ptr, dim1, dim2, char_len, status)` |
| SUBROUTINE | `get_char3d_ptr` | 3990 | `SUBROUTINE get_char3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, char_len, status)` |
| SUBROUTINE | `get_char4d_ptr` | 4084 | `SUBROUTINE get_char4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, char_len, status)` |
| SUBROUTINE | `get_class_block_id_by_data_id` | 4182 | `SUBROUTINE get_class_block_id_by_data_id(data_id, block_id, status)` |
| SUBROUTINE | `get_class_element_ptr` | 4226 | `SUBROUTINE get_class_element_ptr(mem_block_id, elem_index, ptr, status)` |
| SUBROUTINE | `get_class_ptr` | 4394 | `SUBROUTINE get_class_ptr(mem_block_id, ptr, status)` |
| FUNCTION | `get_dims_string` | 4538 | `FUNCTION get_dims_string(dims) RESULT(dims_str)` |
| SUBROUTINE | `get_dp1d_ptr` | 4567 | `SUBROUTINE get_dp1d_ptr(mem_block_id, ptr, dim1, status)` |
| SUBROUTINE | `get_dp2d_ptr` | 4653 | `SUBROUTINE get_dp2d_ptr(mem_block_id, ptr, dim1, dim2, status)` |
| SUBROUTINE | `get_dp3d_ptr` | 4742 | `SUBROUTINE get_dp3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, status)` |
| SUBROUTINE | `get_dp4d_ptr` | 4834 | `SUBROUTINE get_dp4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, status)` |
| SUBROUTINE | `get_int1d_ptr` | 4929 | `SUBROUTINE get_int1d_ptr(mem_block_id, ptr, dim1, status)` |
| SUBROUTINE | `get_int2d_ptr` | 5015 | `SUBROUTINE get_int2d_ptr(mem_block_id, ptr, dim1, dim2, status)` |
| SUBROUTINE | `get_int3d_ptr` | 5104 | `SUBROUTINE get_int3d_ptr(mem_block_id, ptr, dim1, dim2, dim3, status)` |
| SUBROUTINE | `get_int4d_ptr` | 5196 | `SUBROUTINE get_int4d_ptr(mem_block_id, ptr, dim1, dim2, dim3, dim4, status)` |
| SUBROUTINE | `get_struct_block_base_cptr` | 5291 | `SUBROUTINE get_struct_block_base_cptr(block_id, base_cptr, status)` |
| SUBROUTINE | `get_struct_block_id_by_data_id` | 5352 | `SUBROUTINE get_struct_block_id_by_data_id(data_id, block_id, status)` |
| SUBROUTINE | `get_struct_element_cptr` | 5396 | `SUBROUTINE get_struct_element_cptr(mem_block_id, elem_index, cptr, status)` |
| SUBROUTINE | `get_struct_element_ptr` | 5535 | `SUBROUTINE get_struct_element_ptr(mem_block_id, elem_index, ptr, status)` |
| SUBROUTINE | `get_struct_mem_pool_stats` | 5563 | `SUBROUTINE get_struct_mem_pool_stats(stats, status)` |
| SUBROUTINE | `get_struct_ptr` | 5587 | `SUBROUTINE get_struct_ptr(mem_block_id, ptr, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_1d_char` | 5708 | `SUBROUTINE get_struct_subarray_ptr_1d_char(subarray_id, ptr, dim1, char_len, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_1d_dp` | 5774 | `SUBROUTINE get_struct_subarray_ptr_1d_dp(subarray_id, ptr, dim1, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_1d_int` | 5838 | `SUBROUTINE get_struct_subarray_ptr_1d_int(subarray_id, ptr, dim1, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_2d_char` | 5902 | `SUBROUTINE get_struct_subarray_ptr_2d_char(subarray_id, ptr, dim1, dim2, char_len, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_2d_dp` | 5970 | `SUBROUTINE get_struct_subarray_ptr_2d_dp(subarray_id, ptr, dim1, dim2, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_2d_int` | 6036 | `SUBROUTINE get_struct_subarray_ptr_2d_int(subarray_id, ptr, dim1, dim2, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_3d_char` | 6102 | `SUBROUTINE get_struct_subarray_ptr_3d_char(subarray_id, ptr, dim1, dim2, dim3, char_len, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_3d_dp` | 6172 | `SUBROUTINE get_struct_subarray_ptr_3d_dp(subarray_id, ptr, dim1, dim2, dim3, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_3d_int` | 6240 | `SUBROUTINE get_struct_subarray_ptr_3d_int(subarray_id, ptr, dim1, dim2, dim3, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_4d_char` | 6308 | `SUBROUTINE get_struct_subarray_ptr_4d_char(subarray_id, ptr, dim1, dim2, dim3, dim4, char_len, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_4d_dp` | 6380 | `SUBROUTINE get_struct_subarray_ptr_4d_dp(subarray_id, ptr, dim1, dim2, dim3, dim4, status)` |
| SUBROUTINE | `get_struct_subarray_ptr_4d_int` | 6450 | `SUBROUTINE get_struct_subarray_ptr_4d_int(subarray_id, ptr, dim1, dim2, dim3, dim4, status)` |
| SUBROUTINE | `get_timestamp` | 6520 | `SUBROUTINE get_timestamp(timestamp)` |
| FUNCTION | `get_type_string` | 6531 | `FUNCTION get_type_string(data_type) RESULT(type_str)` |
| SUBROUTINE | `get_unified_subarray_id_by_data_id` | 6552 | `SUBROUTINE get_unified_subarray_id_by_data_id(data_id, subarray_id, status)` |
| SUBROUTINE | `get_unified_subarray_ptr_generic` | 6589 | `SUBROUTINE get_unified_subarray_ptr_generic(subarray_id, expected_type, expected_dims, dims_out, ptr, dim1, status)` |
| SUBROUTINE | `init_struct_mem_pool` | 6687 | `SUBROUTINE init_struct_mem_pool(status, bound_device_id, max_blocks, total_mem, unified_mem_size)` |
| SUBROUTINE | `initialize_class_memory` | 6882 | `SUBROUTINE initialize_class_memory(block_id, class_id, status)` |
| SUBROUTINE | `initialize_struct_memory` | 7015 | `SUBROUTINE initialize_struct_memory(block_id, struct_id, status)` |
| FUNCTION | `INT_TO_STR` | 7123 | `FUNCTION INT_TO_STR(i) RESULT(str)` |
| FUNCTION | `INT_TO_STR8` | 7132 | `FUNCTION INT_TO_STR8(i) RESULT(str)` |
| SUBROUTINE | `lock_struct_mem` | 7141 | `SUBROUTINE lock_struct_mem(block_id, status)` |
| SUBROUTINE | `query_struct_mem_block` | 7182 | `SUBROUTINE query_struct_mem_block(block_id, mem_block_info, status)` |
| SUBROUTINE | `register_class_def` | 7216 | `SUBROUTINE register_class_def(class_name, parent_name, metadata, class_id, status)` |
| SUBROUTINE | `register_struct_def` | 7318 | `SUBROUTINE register_struct_def(struct_name, metadata, struct_id, status)` |
| SUBROUTINE | `register_struct_subarray` | 7396 | `SUBROUTINE register_struct_subarray(data_id, data_type, dims, char_len, metadata, subarray_id, status, struct_class_name)` |
| SUBROUTINE | `smem_get_device_buffer` | 7536 | `SUBROUTINE smem_get_device_buffer(block_id, device_id, dev_ptr, size_bytes, status)` |
| SUBROUTINE | `smem_map_block_to_device` | 7610 | `SUBROUTINE smem_map_block_to_device(block_id, device_id, status)` |
| SUBROUTINE | `smem_sync_block` | 7718 | `SUBROUTINE smem_sync_block(block_id, device_id, direction, status)` |
| SUBROUTINE | `sort_lru_list` | 7798 | `SUBROUTINE sort_lru_list(lru_list, count)` |
| SUBROUTINE | `unlock_struct_mem` | 7821 | `SUBROUTINE unlock_struct_mem(block_id, status)` |
| SUBROUTINE | `verify_class_layout` | 7862 | `SUBROUTINE verify_class_layout(mem_block_id, status)` |
| SUBROUTINE | `verify_struct_layout` | 7976 | `SUBROUTINE verify_struct_layout(mem_block_id, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
