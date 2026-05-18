## IO 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：IO / 输入输出与持久化
- **缩写**：IF_IO (`IF_IO_*`)
- **职责**：提供文件读写、数据序列化/反序列化、Checkpoint 持久化机制；支持多格式（文本、二进制、HDF5）。
- **四型配置**：
  - **Desc**：文件句柄 TYPE、IO 模式枚举；**SpillFile 配置（块大小、文件路径）、IOBuffer 配置（双缓冲大小）**。
  - **State**：当前文件状态、缓冲区；**SpillFile 状态（当前偏移、块数）、IOBuffer 状态（当前活动缓冲区、待刷出队列）**。
  - **Ctx**：**Spill/Reload 请求上下文（pool_id + block_id + size）**。
  - **Algo**：序列化/反序列化、压缩/解压；**块级随机读写调度、双缓冲交替策略、增量 Checkpoint 差异检测**。
- **核心接口**：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| File | File_Open, File_Close, File_Read | 文件操作 |
| Serial | Serialize, Deserialize | 序列化接口 |
| Checkpoint | Checkpoint_Save, Checkpoint_Load | 断点续算 |
| Format | HDF5_Read, HDF5_Write | HDF5 格式支持 |
| **SpillFile** | **SpillFile_Open, SpillFile_Close, SpillFile_WriteBlock, SpillFile_ReadBlock** | **三级存储 Spill/Reload 块级随机读写** |
| **IOBuffer** | **IOBuf_Init, IOBuf_Write, IOBuf_Flush, IOBuf_Swap** | **SP3 双缓冲流式写入** |
| **IncrCheckpoint** | **IncrCP_Begin, IncrCP_WriteChanged, IncrCP_End** | **增量 Checkpoint (仅写变化块)** |

- **依赖**：Error（错误处理）、Log（日志记录）、Precision（数据类型）、**Memory/StorageMgr（Spill 触发通知）**。
- **热路径**：**否** — IO 属于初始化/输出阶段。**Spill/Reload 可在热路径触发但非常规路径。**
- **实现锚点**：
  - `IF_IO_File.f90` — 文件操作核心
  - `IF_IO_Serial.f90` — 序列化接口
  - `IF_IO_Checkpoint.f90` — Checkpoint 管理
  - `IF_IO_HDF5.f90` — HDF5 格式支持

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

**版本**：v1.0  
**最后更新**：2026-03-23  
**状态**：✅ 已补全

---

### 错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L1_IO_xxx` (10300–10399)；**三级存储扩展 (10380–10399)** |
| 严重级 | WARNING: 文件格式不匹配(可降级)/**Spill 文件接近容量上限**; ERROR: 文件打开/读写失败/**Spill 写入/Reload 读取失败**; FATAL: **Spill 磁盘满 + Checkpoint 文件损坏不可恢复** |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 跳过/**扩展 Spill 文件**; ERROR：关闭句柄 + 上报调用者/**回退上一 Checkpoint**; FATAL：**紧急序列化核心状态 + 终止** |
| **三级存储错误码** | **ERR_SPILL_WRITE_FAIL (10380), ERR_SPILL_READ_FAIL (10381), ERR_SPILL_DISK_FULL (10382), ERR_IOBUF_FULL (10383), ERR_CHECKPOINT_CORRUPT (10384), ERR_CHECKPOINT_VERSION (10385)** |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L6_AP/* | S(消费) | 应用层使用 IO 读写文件 |
| R2 | L5_RT/* | S(消费) | 运行时层 Checkpoint / Output 输出 |
| R3 | L1_IF/Error | U(USE) | 错误码定义 |
| R4 | L1_IF/Base | U(USE) | 基础类型 |
| R5 | L1_IF/Log | U(USE) | IO 错误日志 |
| R6 | L1_IF/Precision | U(USE) | 数据精度 |
| **R7** | **L1_IF/Memory** | **B(双向)** | **StorageMgr 触发 Spill → IO 写入；IO Reload → StorageMgr 回填** |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 文件句柄须配对 Open/Close | 硬 | Harness | H-IO-01 |
| HDF5 接口须可选编译 | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | 文件句柄 TYPE / IO 模式枚举 / **SpillFile 配置 / IOBuffer 配置** | IO 配置描述 + **三级存储外存配置** |
| 2 | State 定义 | 文件状态 / 缓冲区 / **SpillFile 偏移 / IOBuffer 活动缓冲** | 运行时 IO 状态 + **外存状态** |
| 3 | Algo 定义 | 序列化/反序列化 / 压缩 / **块级随机 R/W / 双缓冲交替** | IO 算法 + **Spill 算法** |
| 4 | Ctx 定义 | **Spill/Reload 请求上下文** | **三级存储外存临时上下文** |
| 5 | Init/Finalize | File_Open / File_Close / **SpillFile_Open / _Close / IOBuf_Init** | 文件生命周期 + **外存初始化** |
| 6 | Query | File_Status / File_Size | 文件元信息查询 |
| 7 | Validate | 文件格式校验 / **Checkpoint 完整性 CRC** | 内嵌 + **Checkpoint 校验** |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | **SpillFile ↔ StorageMgr (Spill/Reload 协议)** | **Tier 2↔Tier 3 桥接** |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | status 参数返回 / **ERR_SPILL_DISK_FULL / ERR_CHECKPOINT_CORRUPT** | 见错误处理 + **外存错误** |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——文件 IO 基础设施 |
| 逻辑链 | 统一文件/序列化接口，L5/L6 通过本域读写数据 |
| 计算链 | 无数值计算——IO 在初始化/输出阶段执行 |
| 数据链 | 文件句柄 + 缓冲区管理，Checkpoint 持久化链 |


---

### Checkpoint 统一流程 (v3.0)

跨层 Checkpoint/Restart 统一流程详见 [CHECKPOINT_UNIFIED_FLOW.md](../../../docs/05_Project_Planning/PPLAN/06_核心架构/CHECKPOINT_UNIFIED_FLOW.md)。

IO 域在统一流程中的角色:
- **Checkpoint**: L1 IO 统一写出 checkpoint 文件（步骤 [4]）
- **Restart**: L1 IO 读取 checkpoint 文件（步骤 [1]）
- **SpillFile**: StorageMgr WARM 池 snapshot 的物理存储载体
- **dp_save/dp_load**: 经 `IF_Mem_Serial` 序列化/反序列化，IO 负责实际磁盘写入

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `Checkpoint/IF_IO_Backup.f90` | `IF_IO_Backup` | — | `backup_data` (SUB,PUB,—); `bm_backup_struct` (SUB,PUB,—); `bm_backup_unstruct` (SUB,PUB,—); `bm_calculate_file_crc32` (SUB,PUB,Compute); `bm_get_meta` (SUB,PUB,Query); `bm_restore_struct` (SUB,PUB,—); `bm_restore_unstruct` (SUB,PUB,—); `restore_data` (SUB,PUB,—) |
| `Checkpoint/IF_IO_Persist.f90` | `IF_IO_Persist` | `IF_PersistConfig`, `IF_FileRecord`, `IF_Persist_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `RegisterFile` (TBP,PRV,—); `OpenFile` (TBP,PRV,—); `CloseFile` (TBP,PRV,—); `WriteCheckpoint` (TBP,PRV,—); `ReadCheckpoint` (TBP,PRV,—); `IF_IO_Persist_Init` (SUB,PRV,Init); `IF_IO_Persist_Finalize` (SUB,PRV,Finalize); `IF_Persist_RegisterFile` (SUB,PRV,—); `IF_Persist_OpenFile` (SUB,PRV,—); `IF_Persist_CloseFile` (SUB,PRV,—); `IF_Persist_ReadCheckpoint` (SUB,PRV,Parse); `IF_Persist_WriteCheckpoint` (SUB,PRV,IO) |
| `Checkpoint/IF_IO_StructFile.f90` | `IF_IO_StructFile` | `StructFileIOCapabilities`, `DataBlockType`, `CacheEntryType`, `FileHandleType`, `NodeInfoType`, `StructFileManagerType` | `init` (TBP,PRV,—); `destroy` (TBP,PRV,—); `open_struct_file` (TBP,PRV,—); `close_struct_file` (TBP,PRV,—); `write_data_chunks` (TBP,PRV,—); `read_data_chunks` (TBP,PRV,—); `preload_data_to_cache` (TBP,PRV,—); `evict_lru_cache_entry` (TBP,PRV,—); `clear_cache_all` (TBP,PRV,—); `get_active_node_count` (TBP,PRV,Query); `migrate_data_block` (TBP,PRV,—); `validate_data_block` (TBP,PRV,—); `update_cache_access_time` (TBP,PRV,—); `get_current_time` (TBP,PRV,—); `check_cache` (TBP,PRV,—); `update_data_partial` (TBP,PRV,—); `encrypt_data_block` (TBP,PRV,—); `decrypt_data_block` (TBP,PRV,—); `compress_data_block` (TBP,PRV,—); `decompress_data_block` (TBP,PRV,—); `configure_cache_strategy` (TBP,PRV,—); `get_cache_statistics` (TBP,PRV,—); `detect_file_format` (TBP,PRV,—); `convert_file_format` (TBP,PRV,—); `migrate_data_to_node` (TBP,PRV,—); `shard_file` (TBP,PRV,—); `merge_files` (TBP,PRV,—); `sfm_register_io_filters` (SUB,PUB,—); `int_to_str` (FN,PRV,—); `int_to_str8` (FN,PRV,—); `get_current_timestamp` (FN,PRV,—); `ensure_struct_block_for_cache` (SUB,PRV,—); `normalize_path` (FN,PUB,—); `get_current_working_dir` (FN,PRV,—); `ensure_trailing_slash` (FN,PRV,—); `join_paths` (FN,PUB,—); `create_windows_path` (FN,PRV,—); `extract_filename` (FN,PUB,—); `allocate_file_unit` (FN,PRV,—); `release_file_unit` (SUB,PRV,—); `init_struct_file_manager` (SUB,PRV,—); `destroy_struct_file_manager` (SUB,PRV,—); `open_struct_file` (SUB,PRV,—); `close_struct_file` (SUB,PRV,—); `write_data_chunks` (SUB,PRV,—); `read_data_chunks` (SUB,PRV,—); `preload_data_to_cache` (SUB,PRV,—); `clear_cache_all` (SUB,PRV,—); `init_struct_file_manager_impl` (SUB,PRV,—); `destroy_struct_file_manager_impl` (SUB,PRV,—); `open_struct_file_impl` (SUB,PRV,—); `close_struct_file_impl` (SUB,PRV,—); `write_data_chunks_impl` (SUB,PRV,—); `prepare_data_block_for_write` (SUB,PRV,IO); `read_data_chunks_impl` (SUB,PRV,—); `preload_data_to_cache_impl` (SUB,PRV,—); `evict_lru_cache_entry_impl` (SUB,PRV,—); `clear_cache_all_impl` (SUB,PRV,—); `get_active_node_count_impl` (SUB,PRV,Query); `migrate_data_block_impl` (SUB,PRV,—); `validate_data_block_impl` (SUB,PRV,—); `update_cache_access_time_impl` (SUB,PRV,—); `check_cache` (FN,PRV,—); `get_current_time_impl` (FN,PRV,—); `read_file_metadata` (SUB,PRV,—); `update_file_metadata` (SUB,PRV,—); `write_file_metadata_to_file` (SUB,PRV,—); `dims_to_str` (FN,PRV,—); `str_to_dims` (SUB,PRV,—); `int8_to_str` (FN,PRV,—); `STRING` (FN,PRV,—); `update_data_partial` (SUB,PRV,—); `encrypt_data_block` (SUB,PRV,—); `decrypt_data_block` (SUB,PRV,—); `compress_data_block` (SUB,PRV,—); `decompress_data_block` (SUB,PRV,—); `configure_cache_strategy` (SUB,PRV,—); `get_cache_statistics` (SUB,PRV,—); `detect_file_format` (FN,PRV,—); `convert_file_format` (SUB,PRV,—); `migrate_data_to_node` (SUB,PRV,—); `ensure_struct_block_for_node_cache` (SUB,PRV,—); `shard_file` (SUB,PRV,—); `merge_files` (SUB,PRV,—); `sfm_init` (SUB,PUB,Init); `sfm_destroy` (SUB,PUB,Finalize); `sfm_open_file` (SUB,PUB,—); `sfm_close_file` (SUB,PUB,—); `sfm_write_data` (SUB,PUB,IO); `sfm_read_data` (SUB,PUB,Parse); `sfm_preload_cache` (SUB,PUB,—); `sfm_clear_cache` (SUB,PUB,Mutate); `sfm_configure_cache` (SUB,PUB,—); `sfm_cache_stats` (SUB,PUB,—); `sfm_create_data_block` (SUB,PUB,Init); `sfm_destroy_data_block` (SUB,PUB,Finalize); `sfm_update_partial` (SUB,PUB,Compute); `sfm_encrypt_block` (SUB,PUB,—); `sfm_decrypt_block` (SUB,PUB,—); `sfm_compress_block` (SUB,PUB,—); `sfm_decompress_block` (SUB,PUB,—); `sfm_detect_format` (FN,PUB,—); `sfm_convert_format` (SUB,PUB,Bridge); `sfm_migrate_to_node` (SUB,PUB,—); `sfm_shard_file` (SUB,PUB,—); `sfm_merge_files` (SUB,PUB,—); `sfm_get_shards` (SUB,PUB,Query); `sfm_get_error_string` (FN,PUB,Query) |
| `Checkpoint/IF_StructFormat_API.f90` | `IF_StructFormat_API` | — | `sfa_get_struct_meta_by_var` (SUB,PRV,Query); `sfa_read_struct_txt_like` (SUB,PRV,Parse); `sfa_write_struct_csv` (SUB,PRV,IO); `sfa_write_struct_dat` (SUB,PRV,IO); `sfa_write_struct_inp` (SUB,PRV,IO); `sfa_write_struct_txt_like` (SUB,PRV,IO); `sfm_read_struct_csv` (SUB,PUB,Parse); `sfm_read_struct_dat` (SUB,PUB,Parse); `sfm_read_struct_inp` (SUB,PUB,Parse); `sfm_write_struct_csv` (SUB,PUB,IO); `sfm_write_struct_dat` (SUB,PUB,IO); `sfm_write_struct_inp` (SUB,PUB,IO) |
| `Checkpoint/IF_UnstructFile_Mgr.f90` | `IF_UnstructFile_Mgr` | `UnstructFileHandleType`, `ChunkMetaType`, `HeaderCacheEntryType`, `DataFileMapEntryType`, `UnstructFileIOCapabilities`, `UfmIOOptionsType` | `ufm_init` (SUB,PUB,Init); `ufm_set_default_io_options` (SUB,PUB,Mutate); `ufm_register_io_filters` (SUB,PUB,—); `ufm_destroy` (SUB,PUB,Finalize); `ufm_write_unstruct_data` (SUB,PUB,IO); `ufm_read_unstruct_data` (SUB,PUB,Parse); `ufm_detect_file_format` (FN,PRV,—); `ufm_load_unstruct_data` (SUB,PUB,Parse); `ufm_write_data_to_chunks` (SUB,PUB,IO); `ufm_merge_chunks_to_file` (SUB,PUB,—); `write_adjacency_payload_binary` (SUB,PRV,—); `write_adjacency_payload_text` (SUB,PRV,—); `write_linked_list_payload_binary` (SUB,PRV,—); `write_linked_list_payload_text` (SUB,PRV,—); `serialize_linked_list_to_buffer` (SUB,PRV,—); `deserialize_linked_list_from_buffer` (SUB,PRV,—); `write_linked_list_payload_with_filter` (SUB,PRV,—); `load_linked_list_payload_with_filter` (SUB,PRV,—); `write_hash_table_payload_binary` (SUB,PRV,Query); `write_skip_list_payload_binary` (SUB,PRV,—); `write_skip_list_payload_text` (SUB,PRV,—); `write_hash_table_payload_text` (SUB,PRV,Query); `serialize_hash_table_to_buffer` (SUB,PRV,Query); `deserialize_hash_table_from_buffer` (SUB,PRV,Query); `write_hash_table_payload_with_filter` (SUB,PRV,Query); `load_hash_table_payload_with_filter` (SUB,PRV,Query); `write_skip_list_payload_with_filter` (SUB,PRV,—); `load_skip_list_payload_with_filter` (SUB,PRV,—); `write_adjacency_payload_with_filter` (SUB,PRV,—); `load_adjacency_payload_with_filter` (SUB,PRV,—); `write_graph_payload_with_filter` (SUB,PRV,—); `load_graph_payload_with_filter` (SUB,PRV,—); `write_graph_payload_binary` (SUB,PRV,—); `write_graph_payload_text` (SUB,PRV,—); `write_queue_payload_with_filter` (SUB,PRV,—); `write_queue_payload_binary` (SUB,PRV,—); `write_queue_payload_text` (SUB,PRV,—); `serialize_queue_to_buffer` (SUB,PRV,—); `deserialize_queue_from_buffer` (SUB,PRV,—); `serialize_skip_list_to_buffer` (SUB,PRV,—); `deserialize_skip_list_from_buffer` (SUB,PRV,—); `serialize_graph_to_buffer` (SUB,PRV,—); `deserialize_graph_from_buffer` (SUB,PRV,—); `serialize_adjacency_to_buffer` (SUB,PRV,—); `deserialize_adjacency_from_buffer` (SUB,PRV,—); `copy_int_bytes_to_buffer` (SUB,PRV,—); `copy_real_bytes_to_buffer` (SUB,PRV,—); `clear_chunk_table` (SUB,PRV,—); `register_single_chunk` (SUB,PRV,—); `register_chunk_in_generic_mgr` (SUB,PRV,—); `ufm_get_chunks` (SUB,PUB,Query); `ufm_clear_cache` (SUB,PUB,Mutate); `ufm_get_cache_stats` (SUB,PUB,Query); `clear_data_file_map` (SUB,PRV,Populate); `ufm_register_data_file` (SUB,PUB,—); `ufm_find_data_file` (SUB,PUB,Query); `load_adjacency_payload_binary` (SUB,PRV,—); `load_linked_list_payload_binary` (SUB,PRV,—); `load_hash_table_payload_binary` (SUB,PRV,Query); `load_skip_list_payload_binary` (SUB,PRV,—); `load_graph_payload_binary` (SUB,PRV,—); `load_queue_payload_with_filter` (SUB,PRV,—); `load_queue_payload_binary` (SUB,PRV,—); `load_adjacency_payload_text` (SUB,PRV,—); `load_linked_list_payload_text` (SUB,PRV,—); `load_hash_table_payload_text` (SUB,PRV,Query); `load_skip_list_payload_text` (SUB,PRV,—); `load_graph_payload_text` (SUB,PRV,—); `load_queue_payload_text` (SUB,PRV,—); `WRITE_INT` (FN,PRV,—); `ufm_migrate_data_file` (SUB,PUB,—); `ufm_preload_data_list` (SUB,PUB,—) |
| `Checkpoint/IF_UnstructFormat_API.f90` | `IF_UnstructFormat_API` | — | `ufa_get_unstruct_meta_by_var` (SUB,PRV,Query); `ufm_load_unstruct_csv` (SUB,PUB,Parse); `ufm_load_unstruct_dat` (SUB,PUB,Parse); `ufm_load_unstruct_inp` (SUB,PUB,Parse); `ufm_write_unstruct_csv` (SUB,PUB,IO); `ufm_write_unstruct_dat` (SUB,PUB,IO); `ufm_write_unstruct_inp` (SUB,PUB,IO) |
| `IF_IO.f90` | `IF_IO` | `IF_IO_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `OpenFile` (TBP,PRV,—); `CloseFile` (TBP,PRV,—); `GetHandle` (TBP,PRV,—); `IF_IO_Finalize` (SUB,PRV,Finalize); `IF_IO_Init` (SUB,PRV,Init); `IF_IO_OpenFile` (SUB,PRV,—); `IF_IO_CloseFile` (SUB,PRV,—); `IF_IO_GetHandle` (FN,PRV,Query) |
| `IF_IO_Def.f90` | `IF_IO_Def` | `IF_IO_Cfg_Type`, `IF_IO_Handle_Type` | — |
| `IF_IO_File.f90` | `IF_IO_File` | `IF_FileHandle` | `Open` (TBP,PRV,—); `Close` (TBP,PRV,—); `ReadTextLine` (TBP,PRV,—); `WriteTextLine` (TBP,PRV,—); `ReadBinary` (TBP,PRV,—); `WriteBinary` (TBP,PRV,—); `Rewind` (TBP,PRV,—); `SetPosition` (TBP,PRV,—); `Flush` (TBP,PRV,—); `GetPosition` (TBP,PRV,—); `IsOpen` (TBP,PRV,—); `IF_FileHandle_Open` (SUB,PRV,—); `IF_FileHandle_Close` (SUB,PRV,—); `IF_FileHandle_ReadTextLine` (SUB,PRV,Parse); `IF_FileHandle_WriteTextLine` (SUB,PRV,IO); `IF_FileHandle_ReadBinary` (SUB,PRV,Parse); `IF_FileHandle_WriteBinary` (SUB,PRV,IO); `IF_FileHandle_Rewind` (SUB,PRV,—); `IF_FileHandle_SetPosition` (SUB,PRV,Mutate); `IF_FileHandle_Flush` (SUB,PRV,—); `IF_FileHandle_GetPosition` (FN,PRV,Query); `IF_FileHandle_IsOpen` (FN,PRV,Query); `IF_FileHandle_Exists` (FN,PUB,—); `IF_FileHandle_GetSize` (FN,PUB,Query); `IF_FileHandle_Delete` (SUB,PUB,Mutate); `IF_FileHandle_Copy` (SUB,PUB,—); `IF_FileHandle_CreateDirectory` (SUB,PUB,Init); `IF_FileHandle_Open_Structured` (SUB,PRV,—); `IF_FileHandle_Close_Structured` (SUB,PRV,—); `IF_FileHandle_ReadTextLine_Structured` (SUB,PRV,Parse); `IF_FileHandle_WriteTextLine_Structured` (SUB,PRV,IO) |
| `IF_IO_Filters.f90` | `IF_IO_Filters` | `IF_IO_Filter_Options` | `IF_IO_Filter_Proc` (SUB,PUB,—); `IF_IO_Filter_Identity` (SUB,PUB,—); `IF_IO_Filter_Init_Options` (SUB,PUB,Init); `IF_IO_Filter_Set_Default_Options` (SUB,PUB,Mutate); `IF_IO_Filter_XOR_Read` (SUB,PUB,Parse); `IF_IO_Filter_XOR_Write` (SUB,PUB,IO) |
| `IF_IO_Log.f90` | `IF_IO_Log` | — | `IF_Log_Core_Init` (SUB,PUB,Init); `IF_Log_Core_Shutdown` (SUB,PUB,IO); `IF_Log_Core_SetLevel` (SUB,PUB,Mutate); `IF_Log_Core_Debug` (SUB,PUB,IO); `IF_Log_Core_Info` (SUB,PUB,IO); `IF_Log_Core_Warning` (SUB,PUB,IO); `IF_Log_Core_Error` (SUB,PUB,IO); `IF_Log_Core_Fatal` (SUB,PUB,IO) |
| `IF_Parser.f90` | `IF_Parser` | `IF_ParserHandle` | `IF_Parser_ReadKeyword` (SUB,PUB,Parse); `IF_Parser_ParseNodeLine` (SUB,PUB,Parse); `IF_Parser_ParseElemLine` (SUB,PUB,Parse); `IF_Parser_SkipComments` (SUB,PUB,Parse) |
| `IF_Writer.f90` | `IF_Writer` | `IF_WriterHandle` | `IF_Writer_WriteVTK` (SUB,PUB,IO); `IF_Writer_WriteHDF5` (SUB,PUB,IO); `IF_Writer_WriteCSV` (SUB,PUB,IO) |
