# `IF_Device_Mgr.f90`

- **Source**: `L1_IF/Base/IF_Device_Mgr.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `IF_Device_Mgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `IF_Device_Mgr`
- **逻辑主线（默认三段式 `IF_{Domain+Feature}`）**: `IF_Device`
- **第四段角色（四段式）**: `_Mgr`
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L1_IF/Base/IF_Device_Mgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `DeviceInfoType` (lines 71–87)

```fortran
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
```

### `DeviceManagerType` (lines 90–95)

```fortran
    TYPE :: DeviceManagerType
        LOGICAL :: initialized = .FALSE.              ! Whether the manager is initialized
        INTEGER(i4) :: max_devices = IF_MAX_DEVICE_COUNT     ! Maximum supported devices
        INTEGER(i4) :: current_dev_count = 0              ! Current number of registered devices
        TYPE(DeviceInfoType), ALLOCATABLE :: dev_list(:) ! Device list
    END TYPE DeviceManagerType
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `init_device_mgr` | 117 | `SUBROUTINE init_device_mgr(status, max_devices)` |
| SUBROUTINE | `destroy_device_mgr` | 188 | `SUBROUTINE destroy_device_mgr(status)` |
| SUBROUTINE | `register_device` | 223 | `SUBROUTINE register_device(dev_id, dev_type, dev_name, driver_ver, data_id, &` |
| SUBROUTINE | `unregister_device` | 351 | `SUBROUTINE unregister_device(dev_id, status)` |
| SUBROUTINE | `query_device_memory` | 400 | `SUBROUTINE query_device_memory(dev_id, total_mem, used_mem, free_mem, status)` |
| SUBROUTINE | `check_device_mem_suff` | 478 | `SUBROUTINE check_device_mem_suff(dev_id, data_id, storage_type, is_suff, status)` |
| SUBROUTINE | `simulate_hw_mem_query` | 535 | `SUBROUTINE simulate_hw_mem_query(dev_id, total_mem, used_mem, free_mem, status)` |
| FUNCTION | `dev_type_to_str` | 566 | `FUNCTION dev_type_to_str(type_code) RESULT(type_str)` |
| SUBROUTINE | `get_timestamp` | 583 | `SUBROUTINE get_timestamp(timestamp)` |
| FUNCTION | `INT_TO_STR` | 610 | `FUNCTION INT_TO_STR(i) RESULT(str)` |
| FUNCTION | `INT8_TO_STR` | 621 | `FUNCTION INT8_TO_STR(i8) RESULT(str)` |
| SUBROUTINE | `update_device_status` | 632 | `SUBROUTINE update_device_status(dev_id, new_status, status)` |
| FUNCTION | `dev_status_to_str` | 687 | `FUNCTION dev_status_to_str(status_code) RESULT(status_str)` |
| SUBROUTINE | `update_device_memory_usage` | 706 | `SUBROUTINE update_device_memory_usage(dev_id, delta_mem, status)` |
| SUBROUTINE | `get_device_info` | 744 | `SUBROUTINE get_device_info(dev_id, dev_info, status)` |
| SUBROUTINE | `get_active_device_count` | 781 | `SUBROUTINE get_active_device_count(count, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
