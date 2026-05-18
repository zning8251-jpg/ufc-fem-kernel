## Base 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Base / 基础类型与全局设施
- **缩写**：IF_Base (`IF_Base_*`)
- **职责**：提供 UFC 全栈通用的基础 TYPE、枚举、常量、全局状态容器；为各层提供统一的数据结构基元。
- **四型配置**：
  - **Desc**：基础 TYPE 定义（如 `tSection`、`tMaterial` 等跨域共享结构）。
  - **State**：全局状态容器（如 `g_ufc_global`）。
  - **Ctx**：运行时上下文管理（已并入本域，原 Ctx 域撤销）。
  - **Algo**：无数值算法，仅提供数据结构。
- **核心接口**：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Types | tSection, tMaterial, ... | 跨域共享 TYPE |
| Enums | eDomain, eStepType, ... | 全局枚举 |
| Global | g_ufc_global | 全局状态访问 |
| Ctx | Ctx_Init, Ctx_Get | 上下文管理（原 IF_Ctx_Core） |

- **依赖**：Precision（数值精度定义）。
- **热路径**：**否** — 纯数据定义，无计算逻辑。
- **实现锚点**：
  - `IF_Base_Types.f90` — 基础 TYPE 定义
  - `IF_Base_Enums.f90` — 全局枚举
  - `IF_Base_Global.f90` — 全局状态容器
  - `IF_Base_Ctx.f90` — 上下文管理（原 IF_Ctx_Core）

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.1  
**最后更新**：2026-04-17  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_BASE_xxx` (10100–10199) |
| 严重级 | WARNING: 类型不匹配(可降级); ERROR: 全局状态初始化失败; FATAL: 无 |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 使用默认值; ERROR：上报调用者 |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L2_NM/* | U(USE) | 数值方法层使用基础类型 |
| R2 | L3_MD/* | U(USE) | 模型数据层使用基础类型 |
| R3 | L4_PH/* | U(USE) | 有限元组件层使用基础类型 |
| R4 | L5_RT/* | U(USE) | 运行时层使用基础类型 |
| R5 | L6_AP/* | U(USE) | 应用层使用基础类型 |
| R6 | L1_IF/Precision | U(USE) | 精度定义 |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| TYPE 定义须保持前向兼容 | 硬 | Code Review | — |
| 全局状态访问须线程安全 | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | IF_Base_Types (tSection/tMaterial 等) | 跨域共享结构 |
| 2 | State 定义 | g_ufc_global | 全局状态容器 |
| 3 | Algo 定义 | N/A | 纯数据定义无算法 |
| 4 | Ctx 定义 | IF_Base_Ctx | 运行时上下文管理 |
| 5 | Init/Finalize | Ctx_Init / Ctx_Finalize | 上下文生命周期 |
| 6 | Query | Ctx_Get 等 | 全局状态查询 |
| 7 | Validate | 类型一致性校验 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | N/A | 最底层无桥接 |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 纯数据结构无计算 |
| 13 | Error | status 参数返回 | 见错误处理 |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——纯基础设施类型定义 |
| 逻辑链 | 全局枚举/结构为上层提供统一数据契约 |
| 计算链 | 无计算——编译时类型与常量 |
| 数据链 | TYPE 定义的字段布局为层间数据交换基础 |

---

## 重命名记录 (v1.1 - 2026-04-17)

### 命名规范整改

| 旧文件名 | 新文件名 | 模块名变更 | 原因 |
|----------|----------|------------|------|
| IF_DeviceManager.f90 | IF_Device_Mgr.f90 | IF_DeviceManager → IF_Device_Mgr | 符合UFCK命名规范(缩写Mgr) |
| IF_Step_Type.f90 | IF_Step_Types.f90 | IF_Step_Type → IF_Step_Types | 符合UFCK命名规范(Types复数) |

### 命名规范说明

1. **Manager缩写**: `Manager` → `Mgr` (统一缩写,减少字符)
2. **Type复数**: `Type` → `Types` (包含多个常量/TYPE定义时使用复数)
3. **下划线分隔**: 单词间使用下划线分隔(如`Device_Mgr`)

### 影响范围

- ✅ 模块名已更新
- ✅ 文件内容保持不变(仅模块名变更)
- ⚠️ 需检查其他模块的USE语句(如有引用需同步更新)


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Base.f90` | `IF_Base` | `IF_SymEntry`, `IF_DeviceCaps`, `IF_Base_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `GetCaps` (TBP,PRV,—); `RegisterSymbol` (TBP,PRV,—); `LookupSymbol` (TBP,PRV,—); `IF_Base_Finalize` (SUB,PRV,Finalize); `IF_Base_GetCaps` (SUB,PRV,Query); `IF_Base_Init` (SUB,PRV,Init); `IF_Base_LookupSym` (SUB,PRV,Query); `IF_Base_RegSym` (SUB,PRV,—) |
| `IF_Base_Ctx.f90` | `IF_Base_Ctx` | `BaseCtx` | `Init` (TBP,PRV,—); `Cleanup` (TBP,PRV,—); `ClearStatus` (TBP,PRV,—); `SetStatus` (TBP,PRV,—); `IsOK` (TBP,PRV,—); `IsError` (TBP,PRV,—); `BaseCtx_Init` (SUB,PRV,Init); `BaseCtx_Cleanup` (SUB,PRV,Finalize); `BaseCtx_ClearStatus` (SUB,PRV,Mutate); `BaseCtx_SetStatus` (SUB,PRV,Mutate); `BaseCtx_IsOK` (FN,PRV,Query); `BaseCtx_IsError` (FN,PRV,Query) |
| `IF_Base_DP.f90` | `IF_Base_DP` | `StructFieldDesc`, `ClassFieldDesc`, `StructTypeRegistryEntry`, `ClassTypeRegistryEntry`, `DP_VarView`, `ShardMovePlan` | `dp_log` (SUB,PRV,IO); `dp_set_log_level` (SUB,PUB,Mutate); `dp_get_log_level` (SUB,PUB,Query); `dp_get_last_error` (SUB,PUB,Query); `dp_get_error_stats` (SUB,PUB,Query); `dp_reset_error_stats` (SUB,PUB,Mutate); `dp_sync_class_type_to_structmempool` (SUB,PRV,Populate); `INT8_TO_STR` (FN,PRV,—); `WRITE_INT` (FN,PRV,—); `dp_init` (SUB,PUB,Init); `dp_shutdown` (SUB,PUB,—); `dp_register_struct_array` (SUB,PUB,—); `dp_register_unstruct` (SUB,PUB,—); `dp_ensure_unstruct` (SUB,PUB,—); `dp_register_struct_type` (SUB,PUB,—); `dp_register_class_type` (SUB,PUB,—); `dp_internal_pack_class_array_to_records` (SUB,PRV,—); `dp_plan_rebalance` (SUB,PUB,—); `dp_save` (SUB,PUB,—); `dp_load` (SUB,PUB,Parse); `dp_get_shards` (SUB,PUB,Query); `dp_get_shards_by_node` (SUB,PUB,Query); `dp_get_shards_for_file` (SUB,PUB,Query); `dp_rebuild_unstruct_from_file` (SUB,PRV,—); `dp_get_meta` (SUB,PUB,Query); `dp_validate` (SUB,PUB,Validate); `dp_get_struct_handle` (SUB,PUB,Query); `dp_get_struct_ptr` (SUB,PUB,Query); `dp_get_class_ptr` (SUB,PUB,Query); `dp_get_struct_element_ptr` (SUB,PUB,Query); `dp_get_struct_element_cptr` (SUB,PUB,Query); `dp_get_class_element_ptr` (SUB,PUB,Query); `dp_get_unstruct_handle` (SUB,PUB,Query); `dp_dump_debug` (SUB,PUB,IO); `dp_create_int_array1d` (SUB,PUB,Init); `dp_create_int_array2d` (SUB,PUB,Init); `dp_create_dp_array1d` (SUB,PUB,Init); `dp_create_dp_array2d` (SUB,PUB,Init); `dp_create_int_array3d` (SUB,PUB,Init); `dp_create_int_array4d` (SUB,PUB,Init); `dp_create_dp_array3d` (SUB,PUB,Init); `dp_create_dp_array4d` (SUB,PUB,Init); `dp_create_char_array1d` (SUB,PUB,Init); `dp_create_char_array2d` (SUB,PUB,Init); `dp_create_char_array3d` (SUB,PUB,Init); `dp_create_char_array4d` (SUB,PUB,Init); `dp_create_struct_array` (SUB,PUB,Init); `dp_create_class_array` (SUB,PUB,Init); `dp_ensure_queue` (SUB,PUB,—); `dp_create_queue` (SUB,PUB,Init); `dp_queue_enqueue` (SUB,PUB,—); `dp_queue_dequeue` (SUB,PUB,—); `dp_queue_get_size` (SUB,PUB,Query); `dp_create_hash_table` (SUB,PUB,Init); `dp_get_hash_table_size` (SUB,PUB,Query); `dp_hash_insert` (SUB,PUB,Query); `dp_hash_get` (SUB,PUB,Query); `dp_create_graph` (SUB,PUB,Init); `dp_graph_add_node` (SUB,PUB,Mutate); `dp_graph_add_edge` (SUB,PUB,Mutate); `dp_get_graph_size` (SUB,PUB,Query); `dp_graph_bfs` (SUB,PUB,—); `dp_graph_dfs` (SUB,PUB,—); `dp_create_adjacency_list` (SUB,PUB,Init); `dp_adjacency_add_edge` (SUB,PUB,Mutate); `dp_get_adjacency_list_size` (SUB,PUB,Query); `dp_create_linked_list` (SUB,PUB,Init); `dp_get_linked_list_size` (SUB,PUB,Query); `dp_list_push_back` (SUB,PUB,—); `dp_list_get_values` (SUB,PUB,Query); `dp_create_skip_list` (SUB,PUB,Init); `dp_get_skip_list_size` (SUB,PUB,Query); `dp_skip_insert` (SUB,PUB,Mutate); `dp_skip_get_all` (SUB,PUB,Query); `dp_validate_crc` (SUB,PRV,Validate); `dp_backup` (SUB,PUB,—); `dp_restore` (SUB,PUB,—); `dp_register_var_view` (SUB,PUB,—); `dp_list_var_views` (SUB,PUB,—); `dp_calculate_file_crc32` (SUB,PRV,Compute) |
| `IF_Base_StructMeta_Def.f90` | `IF_Base_StructMeta_Def` | `DeviceInfoType`, `StructMetaVersionType`, `StructMetaType`, `StructMetaManagerType`, `QueryConditionType`, `QueryFilterType` | `init_struct_meta_mgr` (SUB,PUB,—); `destroy_struct_meta_mgr` (SUB,PUB,—); `struct_meta_create` (SUB,PUB,Init); `hash_data_id` (FN,PRV,—); `insert_meta_index_by_id` (SUB,PRV,—); `remove_meta_index_by_id` (SUB,PRV,—); `store_meta_entry` (SUB,PRV,—); `invalidate_meta_entry` (SUB,PRV,—); `find_meta_index_by_id` (SUB,PRV,—); `struct_meta_query` (SUB,PUB,Query); `struct_meta_try_query` (SUB,PUB,Query); `struct_meta_update` (SUB,PUB,Compute); `struct_meta_save_version` (SUB,PUB,—); `struct_meta_get_version` (SUB,PUB,Query); `struct_meta_get_version_history` (SUB,PUB,Query); `struct_meta_restore_version` (SUB,PUB,—); `struct_meta_add_device_association` (SUB,PUB,Mutate); `struct_meta_remove_device_association` (SUB,PUB,Mutate); `struct_meta_get_device_association` (SUB,PUB,Query); `struct_meta_get_all_device_associations` (SUB,PUB,Query); `struct_meta_is_device_associated` (FN,PUB,Query); `get_struct_meta_statistics` (SUB,PUB,—); `get_struct_meta_type_statistics` (SUB,PUB,—); `get_struct_meta_storage_statistics` (SUB,PUB,—); `get_struct_meta_operation_statistics` (SUB,PUB,—); `get_struct_meta_device_statistics` (SUB,PUB,—); `struct_meta_export` (SUB,PUB,—); `struct_meta_export_all` (SUB,PUB,—); `struct_meta_import` (SUB,PUB,Parse); `struct_meta_import_all` (SUB,PUB,Parse); `struct_meta_batch_import` (SUB,PUB,Parse); `export_meta_to_json` (SUB,PRV,—); `export_all_meta_to_json` (SUB,PRV,—); `export_meta_to_xml` (SUB,PRV,—); `export_all_meta_to_xml` (SUB,PRV,—); `export_meta_to_csv` (SUB,PRV,—); `export_all_meta_to_csv` (SUB,PRV,—); `export_meta_to_binary` (SUB,PRV,—); `export_all_meta_to_binary` (SUB,PRV,—); `import_meta_from_json` (SUB,PRV,—); `import_all_meta_from_json` (SUB,PRV,—); `import_meta_from_xml` (SUB,PRV,—); `import_all_meta_from_xml` (SUB,PRV,—); `import_meta_from_csv` (SUB,PRV,—); `import_all_meta_from_csv` (SUB,PRV,—); `import_meta_from_binary` (SUB,PRV,—); `import_all_meta_from_binary` (SUB,PRV,—); `add_meta_to_manager` (SUB,PRV,—); `import_sample_metadata_entries` (SUB,PRV,—); `struct_meta_delete` (SUB,PUB,Mutate); `struct_meta_validate` (SUB,PUB,Validate); `get_struct_meta_count` (SUB,PUB,Query); `struct_meta_exists` (FN,PUB,—); `find_struct_meta_by_id` (FN,PRV,—); `find_empty_meta_slot` (FN,PRV,—); `find_free_meta_entry` (FN,PRV,Finalize); `validate_struct_params` (FN,PRV,—); `get_timestamp` (SUB,PRV,—); `INT_TO_STR` (FN,PUB,—); `INT_ARR_TO_STR` (FN,PUB,—); `REAL_TO_STR` (FN,PRV,—); `LOGICAL_TO_STR` (FN,PRV,—); `struct_meta_create_batch` (SUB,PUB,Init); `struct_meta_update_batch` (SUB,PUB,Compute); `struct_meta_delete_batch` (SUB,PUB,Mutate); `struct_meta_persist` (SUB,PUB,—); `struct_meta_recover` (SUB,PUB,—); `init_query_filter` (SUB,PUB,Query); `add_query_condition` (SUB,PUB,Query); `struct_meta_complex_query` (SUB,PUB,Query); `evaluate_condition` (FN,PRV,—); `struct_meta_validate_all` (SUB,PUB,Validate); `struct_meta_repair` (SUB,PUB,—); `struct_meta_recover_from_error` (SUB,PUB,—); `get_struct_meta_error_summary` (SUB,PUB,IO); `struct_meta_reset_error_counter` (SUB,PUB,Query); `verify_metadata_crc` (FN,PRV,—); `calculate_metadata_crc` (SUB,PRV,—); `calculate_valid_dim_count` (SUB,PRV,Query); `calculate_total_elements` (SUB,PRV,—) |
| `IF_Base_SymTbl.f90` | `IF_Base_SymTbl` | `HashTableEntryType`, `HashTableType`, `SymTableEntryType`, `VariableMigrationType`, `SymbolTableType`, `SymbolTableStatusType` | `calculate_hash` (FN,PUB,Query); `hash_table_create` (SUB,PUB,Init); `hash_table_destroy` (SUB,PUB,Finalize); `hash_table_insert` (SUB,PUB,Mutate); `hash_table_delete` (SUB,PUB,Mutate); `hash_table_find` (FN,PUB,Query); `init_sym_table` (SUB,PUB,—); `destroy_sym_table` (SUB,PUB,—); `register_variable` (SUB,PUB,—); `register_variable_batch` (SUB,PUB,—); `unregister_variable` (SUB,PUB,—); `register_temp_variable` (SUB,PUB,—); `find_variable` (SUB,PUB,—); `get_variable_data_id` (SUB,PUB,—); `symbol_table_exists` (FN,PUB,—); `get_variable_count` (SUB,PUB,Query); `is_valid_var_name` (FN,PUB,Validate); `is_valid_type_match` (FN,PUB,Validate); `find_free_entry` (FN,PUB,Finalize); `LOWERCASE` (FN,PUB,—); `INT_TO_STR` (FN,PUB,—); `register_simple_temp_variable` (SUB,PUB,—); `export_variable_for_migration` (FN,PUB,—); `import_variable_from_migration` (FN,PUB,—); `migrate_variable_between_nodes` (SUB,PUB,—); `get_relative_time` (FN,PUB,—); `update_variable_access_stats` (SUB,PUB,—); `update_variable_update_stats` (SUB,PUB,Compute); `get_variable_usage_stats` (SUB,PUB,—); `save_symbol_table_to_file` (SUB,PUB,—); `load_symbol_table_from_file` (SUB,PUB,—); `update_lru_cache` (SUB,PUB,—); `configure_lru_cache_size` (SUB,PUB,—); `save_variable_version` (SUB,PUB,—); `rollback_to_version` (SUB,PUB,—); `get_variable_version_history` (SUB,PUB,—); `get_variable_current_version` (SUB,PUB,—); `get_symbol_table_status` (SUB,PUB,—); `generate_symbol_table_report` (SUB,PUB,IO) |
| `IF_Base_UnstructMeta_Def.f90` | `IF_Base_UnstructMeta_Def` | `UnstructAttrType`, `UnstructMetaType`, `UnstructMetaManagerType` | `init_unstruct_meta_mgr` (SUB,PUB,—); `destroy_unstruct_meta_mgr` (SUB,PUB,—); `unstruct_meta_create` (SUB,PUB,Init); `unstruct_meta_query` (SUB,PUB,Query); `unstruct_meta_try_query` (SUB,PUB,Query); `unstruct_meta_update` (SUB,PUB,Compute); `unstruct_meta_delete` (SUB,PUB,Mutate); `unstruct_meta_validate` (SUB,PUB,Validate); `get_unstruct_meta_count` (SUB,PUB,Query); `unstruct_meta_exists` (FN,PUB,—); `find_free_unstruct_entry` (FN,PRV,Finalize); `validate_unstruct_params` (FN,PRV,—); `calc_unstruct_size` (FN,PRV,—); `unstruct_type_to_str` (FN,PRV,—); `get_timestamp` (SUB,PRV,—); `INT_TO_STR` (FN,PRV,—); `INT8_TO_STR` (FN,PRV,—) |
| `IF_Device_Mgr.f90` | `IF_Device_Mgr` | `DeviceInfoType`, `DeviceManagerType` | `init_device_mgr` (SUB,PUB,—); `destroy_device_mgr` (SUB,PUB,—); `register_device` (SUB,PUB,—); `unregister_device` (SUB,PUB,—); `query_device_memory` (SUB,PUB,—); `check_device_mem_suff` (SUB,PUB,—); `simulate_hw_mem_query` (SUB,PRV,Query); `dev_type_to_str` (FN,PRV,—); `get_timestamp` (SUB,PUB,—); `get_timestamp_int` (FN,PRV,—); `INT_TO_STR` (FN,PUB,—); `INT8_TO_STR` (FN,PUB,—); `update_device_status` (SUB,PUB,—); `dev_status_to_str` (FN,PRV,—); `update_device_memory_usage` (SUB,PUB,—); `get_device_info` (SUB,PUB,—); `get_active_device_count` (SUB,PUB,Query) |
| `IF_Math_Util.f90` | `IF_Math_Util` | — | `IF_Math_Clamp` (FN,PUB,—); `IF_Math_CrossProduct` (FN,PUB,—); `IF_Math_DotProduct` (FN,PUB,—); `IF_Math_IsEqual` (FN,PUB,Query); `IF_Math_IsFinite` (FN,PUB,Query); `IF_Math_IsInf` (FN,PUB,Query); `IF_Math_IsNaN` (FN,PUB,Query); `IF_Math_IsZero` (FN,PUB,Query); `IF_Math_Lerp` (FN,PUB,—); `IF_Math_Norm` (FN,PUB,—); `IF_Math_Sign` (FN,PUB,—); `IF_Math_Mtx_Determinant` (SUB,PUB,—); `IF_Math_Mtx_Determinant_3x3` (SUB,PRV,—); `IF_Math_Mtx_Inverse` (SUB,PUB,—); `IF_Math_Mtx_Inverse_3x3` (SUB,PRV,—); `IF_Math_Mtx_Multiply` (SUB,PUB,—); `IF_Math_Mtx_Transpose` (FN,PUB,—); `IF_Math_Normalize` (SUB,PUB,—); `IF_Math_SafeDivide` (SUB,PUB,—); `IF_Math_SafeLog` (SUB,PUB,—); `IF_Math_SafeSqrt` (SUB,PUB,—) |
| `IF_Step_Def.f90` | `IF_Step_Def` | — | — |
