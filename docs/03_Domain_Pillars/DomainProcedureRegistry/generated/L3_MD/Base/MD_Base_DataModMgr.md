# `MD_Base_DataModMgr.f90`

- **Source**: `L3_MD/Base/MD_Base_DataModMgr.f90`
- **Generated (UTC)**: 2026-05-14T07:52:51Z
- **MODULE (heuristic)**: `MD_Base_DataModMgr`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `MD_Base_DataModMgr`
- **逻辑主线（默认三段式 `MD_{Domain+Feature}`）**: `MD_Base_DataModMgr`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Base`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L3_MD/Base/MD_Base_DataModMgr.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `FieldMeta` (lines 139–149)

```fortran
    TYPE :: FieldMeta
        CHARACTER(len=64) :: field_name = ""
        INTEGER(i4) :: dType = 0
        INTEGER(i4) :: element_len = 1
        INTEGER(i8) :: offset_bytes = 0
        INTEGER(i4) :: rank = 0
        INTEGER(i4) :: dims(7) = 0
        LOGICAL :: is_pointer = .FALSE.
        LOGICAL :: is_allocatable = .FALSE.
        CHARACTER(len=256) :: description = ""
    END TYPE FieldMeta
```

### `TypeMeta` (lines 152–166)

```fortran
    TYPE :: TypeMeta
        INTEGER(i4) :: type_id = 0
        CHARACTER(len=128) :: type_name = ""
        INTEGER(i4) :: type_class = 0
        INTEGER(i4) :: owner_module = 0
        INTEGER(i4) :: nFields = 0
        INTEGER(i8) :: type_size_bytes = 0
        INTEGER(i4) :: memory_block_id = 0
        TYPE(FieldMeta), ALLOCATABLE :: fields(:)
        LOGICAL :: registered = .FALSE.
        LOGICAL :: validated = .FALSE.
        INTEGER(i8) :: registration_ti = 0
        INTEGER(i8) :: last_access_tim = 0
        CHARACTER(len=512) :: description = ""
    END TYPE TypeMeta
```

### `TypeReg` (lines 169–178)

```fortran
    TYPE :: TypeReg
        INTEGER(i4) :: nTypes = 0
        INTEGER(i4) :: max_types = 5000
        INTEGER(i4) :: memory_block_id = 0
        TYPE(TypeMeta), ALLOCATABLE :: types(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: memory_managed = .FALSE.
    CONTAINS
        PROCEDURE :: Init => TypeReg_Init_TBP
    END TYPE TypeReg
```

### `DataObj` (lines 183–198)

```fortran
    TYPE :: DataObj
        INTEGER(i4) :: id = 0
        INTEGER(i4) :: type_id = 0
        INTEGER(i4) :: mem_block_id = 0
        CHARACTER(len=128) :: name = ""
        INTEGER(i8) :: version = 0
        INTEGER(i8) :: created_time = 0
        INTEGER(i8) :: modified_time = 0
        LOGICAL :: dirty = .FALSE.
        LOGICAL :: uses_unified_me = .FALSE.
        BYTE, ALLOCATABLE :: data_buffer(:)
        REAL(wp), POINTER :: real_data(:) => null()
        INTEGER(i4), POINTER :: int_data(:) => null()
        LOGICAL, POINTER :: logical_data(:) => null()
        CHARACTER(len=:), POINTER :: char_data => null()
    END TYPE DataObj
```

### `DataAccess` (lines 201–207)

```fortran
    TYPE :: DataAccess
        INTEGER(i4) :: object_count = 0
        INTEGER(i4) :: max_objects = 100000
        TYPE(DataObj), ALLOCATABLE :: objects(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: uses_unified_me = .FALSE.
    END TYPE DataAccess
```

### `ModuleAPI` (lines 212–222)

```fortran
    TYPE :: ModuleAPI
        INTEGER(i4) :: module_id = 0
        CHARACTER(len=128) :: module_name = ""
        LOGICAL :: init = .FALSE.
        LOGICAL :: registered = .FALSE.
        INTEGER(i4) :: memory_pool_id = 0
        INTEGER(i4) :: registered_type = 0
        INTEGER(i8) :: total_memory_us = 0
        PROCEDURE(Module_Init_Intf), POINTER :: init_func => null()
        PROCEDURE(Module_Cleanup_Intf), POINTER :: cleanup_func => null()
    END TYPE ModuleAPI
```

### `UniFrame` (lines 225–233)

```fortran
    TYPE :: UniFrame
        INTEGER(i4) :: adapter_count = 0
        INTEGER(i4) :: max_adapters = 100
        INTEGER(i4) :: next_module_id = 1
        TYPE(ModuleAPI), ALLOCATABLE :: adapters(:)
        LOGICAL :: init = .FALSE.
        LOGICAL :: memory_system_i = .FALSE.
        LOGICAL :: type_system_ini = .FALSE.
    END TYPE UniFrame
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `Module_Init_Intf` | 238 | `SUBROUTINE Module_Init_Intf(module_id, status)` |
| SUBROUTINE | `Module_Cleanup_Intf` | 244 | `SUBROUTINE Module_Cleanup_Intf(module_id, status)` |
| SUBROUTINE | `TypeReg_Init` | 256 | `SUBROUTINE TypeReg_Init(this, use_unified_mem, status)` |
| SUBROUTINE | `TypeReg_Init_TBP` | 297 | `SUBROUTINE TypeReg_Init_TBP(this, status)` |
| SUBROUTINE | `type_init` | 303 | `SUBROUTINE type_init()` |
| SUBROUTINE | `type_reg` | 309 | `SUBROUTINE type_reg(reg, type_name, type_class, owner_module, fields, nFields, type_id, status)` |
| SUBROUTINE | `type_find` | 320 | `SUBROUTINE type_find(reg, type_name, type_id, status)` |
| SUBROUTINE | `type_flds` | 328 | `SUBROUTINE type_flds(reg, type_id, field_name, field_info, status)` |
| SUBROUTINE | `TypeReg_ClearAllTypes` | 337 | `SUBROUTINE TypeReg_ClearAllTypes(this)` |
| SUBROUTINE | `TypeReg_RegisterType` | 360 | `SUBROUTINE TypeReg_RegisterType(this, type_name, type_class, owner_module, &` |
| SUBROUTINE | `TypeReg_FindType` | 437 | `SUBROUTINE TypeReg_FindType(this, type_name, type_id, status)` |
| SUBROUTINE | `TypeReg_GetTypeInfo` | 460 | `SUBROUTINE TypeReg_GetTypeInfo(this, type_id, type_info, status)` |
| SUBROUTINE | `TypeReg_GetFieldInfo` | 479 | `SUBROUTINE TypeReg_GetFieldInfo(this, type_id, field_name, field_info, status)` |
| SUBROUTINE | `TypeReg_ValidateType` | 508 | `SUBROUTINE TypeReg_ValidateType(this, type_id, status)` |
| SUBROUTINE | `TypeReg_Shutdown` | 542 | `SUBROUTINE TypeReg_Shutdown(this, status)` |
| SUBROUTINE | `TypeReg_ValidateTypeParams` | 570 | `SUBROUTINE TypeReg_ValidateTypeParams(type_name, type_class, owner_module, &` |
| SUBROUTINE | `TypeReg_ValidateFieldsArray` | 602 | `SUBROUTINE TypeReg_ValidateFieldsArray(fields, nFields, status)` |
| SUBROUTINE | `TypeReg_ValidateFields` | 643 | `SUBROUTINE TypeReg_ValidateFields(type_meta, status)` |
| SUBROUTINE | `TypeReg_CalculateTypeSize` | 650 | `SUBROUTINE TypeReg_CalculateTypeSize(type_meta, total_size, status)` |
| SUBROUTINE | `DataAccess_Init` | 701 | `SUBROUTINE DataAccess_Init(this, max_objects, status)` |
| SUBROUTINE | `DataAccess_AllocateDataObj` | 730 | `SUBROUTINE DataAccess_AllocateDataObj(this, name, type_id, data_type, size_elements, &` |
| SUBROUTINE | `DataAccess_DeallocateDataObj` | 803 | `SUBROUTINE DataAccess_DeallocateDataObj(this, obj_id, status)` |
| FUNCTION | `DataAccess_FindById` | 860 | `FUNCTION DataAccess_FindById(this, obj_id) RESULT(obj)` |
| FUNCTION | `DataAccess_FindByName` | 875 | `FUNCTION DataAccess_FindByName(this, name) RESULT(obj)` |
| FUNCTION | `CalcDataStride` | 894 | `FUNCTION CalcDataStride(dims) RESULT(strides)` |
| FUNCTION | `MAPLOGICALTOIND` | 908 | `FUNCTION MAPLOGICALTOIND(coord, strides) RESULT(idx)` |
| SUBROUTINE | `data_create_object` | 920 | `SUBROUTINE data_create_object(data_type, size_elements, rank, name, obj_id, status)` |
| SUBROUTINE | `data_destroy_object` | 955 | `SUBROUTINE data_destroy_object(obj_id, status)` |
| SUBROUTINE | `data_associate_pointer` | 962 | `SUBROUTINE data_associate_pointer(obj_id, ptr, status)` |
| SUBROUTINE | `data_disassociate_pointer` | 1018 | `SUBROUTINE data_disassociate_pointer(obj_id, status)` |
| SUBROUTINE | `data_get_pointer` | 1048 | `SUBROUTINE data_get_pointer(obj_id, ptr, status)` |
| FUNCTION | `data_is_associated` | 1116 | `FUNCTION data_is_associated(obj_id) RESULT(associated)` |
| SUBROUTINE | `data_get_stats` | 1143 | `SUBROUTINE data_get_stats(total_objects, memory_used, status)` |
| SUBROUTINE | `obj_new` | 1180 | `SUBROUTINE obj_new(this, type_id, name, id, status)` |
| SUBROUTINE | `obj_set` | 1249 | `SUBROUTINE obj_set(this, id, field_name, data_value, status)` |
| SUBROUTINE | `obj_get` | 1348 | `SUBROUTINE obj_get(this, id, field_name, data_value, status)` |
| SUBROUTINE | `obj_del` | 1438 | `SUBROUTINE obj_del(this, id, status)` |
| SUBROUTINE | `obj_save` | 1461 | `SUBROUTINE obj_save(this, id, buffer, buffer_size, status)` |
| SUBROUTINE | `obj_load` | 1490 | `SUBROUTINE obj_load(this, id, buffer, buffer_size, status)` |
| SUBROUTINE | `obj_new_and_set` | 1518 | `SUBROUTINE obj_new_and_set(this, type_id, name, field_name, data_value, id, status)` |
| SUBROUTINE | `obj_copy_field` | 1532 | `SUBROUTINE obj_copy_field(this, src_id, dst_id, meta, status)` |
| SUBROUTINE | `Uma_Init` | 1594 | `SUBROUTINE Uma_Init(max_adapters, status)` |
| SUBROUTINE | `Uma_InitMemorySystem` | 1630 | `SUBROUTINE Uma_InitMemorySystem(status)` |
| SUBROUTINE | `Uma_InitTypeSystem` | 1638 | `SUBROUTINE Uma_InitTypeSystem(status)` |
| SUBROUTINE | `Uma_RegisterModule` | 1648 | `SUBROUTINE Uma_RegisterModule(module_name, init_func, cleanup_func, module_id, status)` |
| FUNCTION | `Uma_FindModule` | 1698 | `FUNCTION Uma_FindModule(module_id) RESULT(module)` |
| FUNCTION | `Uma_GetModuleInterface` | 1714 | `FUNCTION Uma_GetModuleInterface(module_name) RESULT(module)` |
| SUBROUTINE | `Uma_AllocateModuleMemory` | 1730 | `SUBROUTINE Uma_AllocateModuleMemory(module_id, data_type, size_elements, name, &` |
| SUBROUTINE | `Uma_DeallocateModuleMemory` | 1759 | `SUBROUTINE Uma_DeallocateModuleMemory(module_id, mem_id, status)` |
| SUBROUTINE | `fw_init` | 1779 | `SUBROUTINE fw_init(this, memory_capacity, status)` |
| SUBROUTINE | `fw_add_mod` | 1814 | `SUBROUTINE fw_add_mod(this, module_name, module_id, status)` |
| SUBROUTINE | `fw_done` | 1848 | `SUBROUTINE fw_done(this, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
