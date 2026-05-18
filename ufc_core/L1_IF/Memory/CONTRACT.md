## Memory 域级合同卡（L1_IF）

- **层级**：L1_IF
- **域名**：Memory / 内存管理与分配
- **缩写**：IF_Memory (`IF_Memory_*`)
- **职责**：提供动态内存分配、内存池管理、泄漏检测机制；支持自定义分配器与对齐分配。
- **四型配置**：
  - **Desc**：内存块 TYPE、分配器句柄、泄漏检测表；**PoolConfig（池注册表）、SpillRecord（溢出记录）**。
  - **State**：当前分配计数、内存池状态；**PoolStats（池统计）、全局溢出/回载计数**。
  - **Ctx**：**分配请求临时上下文（pool_id + size + alignment）**。
  - **Algo**：首次适配/最佳适配策略、引用计数；**LRU 淘汰策略、温度-形态路由、Spill/Reload 触发策略**。
- **核心接口**（按功能集）：

| 功能集 | 绑定 | 说明 |
|--------|------|------|
| Alloc | Allocate, Deallocate | 动态内存分配 |
| Pool | Pool_Create, Pool_Allocate, Pool_Destroy | 内存池管理 |
| Leak | Leak_Check_Enable, Leak_Dump | 泄漏检测 |
| Align | Allocate_Aligned | 对齐分配（SIMD 优化） |
| **StorageMgr** | **Init, Finalize, Alloc, Free, Reset_Pool, Get_Stats** | **三级存储统一门面 (Tier 2)** |
| **StorageMgr_Vec** | **Alloc_Vector, Alloc_Matrix_CSR** | **高级分配 (带形态)** |
| **Spill** | **Force_Spill, Preload, Spill_Notify** | **Tier 2↔Tier 3 溢出/回载** |

- **依赖**：IF_Error（错误处理）、IF_Precision（数据类型）、IF_IO（Spill 文件读写）。
- **热路径**：**是** — 大规模矩阵/网格频繁分配释放。
- **实现锚点**：
  - `IF_Memory_Types.f90` — 内存管理 TYPE 定义
    ```fortran
    TYPE :: MemoryBlock
      INTEGER(i8) :: size          ! 块大小（字节）
      INTEGER(i8) :: alloc_id      ! 分配 ID（用于追踪）
      CHARACTER(:), ALLOCATABLE :: source  ! 分配位置（文件：行号）
      TYPE(MemoryBlock), POINTER :: next => NULL()
    END TYPE MemoryBlock
    
    TYPE :: MemoryPool
      TYPE(MemoryBlock), POINTER :: free_list => NULL()
      TYPE(MemoryBlock), POINTER :: used_list => NULL()
      INTEGER(i8) :: pool_size
      INTEGER(i8) :: block_size
    END TYPE MemoryPool
    ```
  - `IF_Memory_Alloc.f90` — 分配器核心
    ```fortran
    FUNCTION Allocate(size, source) RESULT(ptr)
      INTEGER(i8), INTENT(IN) :: size
      CHARACTER(len=*), INTENT(IN), OPTIONAL :: source
      TYPE(MemoryBlock), POINTER :: ptr
      
      ! 伪代码：
      ! 1. 检查内存池是否有合适块
      ! 2. 若无，调用系统 malloc
      ! 3. 记录分配信息到 leak_table
      ! 4. 返回指针
      
      IF (ASSOCIATED(pool%free_list)) THEN
        ! 从空闲链表分配（首次适配）
        DO WHILE (ASSOCIATED(current))
          IF (current%size >= size) THEN
            ptr => current
            current%alloc_id = global_id_counter
            IF (PRESENT(source)) ptr%source = source
            EXIT
          END IF
          current => current%next
        END DO
      ELSE
        ! 系统分配
        ALLOCATE(ptr, SOURCE=memory_block(size))
      END IF
      
      ! 更新统计
      alloc_count = alloc_count + 1_i8
      total_allocated = total_allocated + size
    END FUNCTION Allocate
    
    SUBROUTINE Deallocate(ptr)
      TYPE(MemoryBlock), POINTER, INTENT(INOUT) :: ptr
      ! 伪代码：
      ! 1. 从 used_list 移除
      ! 2. 加入 free_list（或返回系统）
      ! 3. 更新统计
      IF (.NOT. ASSOCIATED(ptr)) RETURN
      
      ! 标记为已释放
      deallocated_bytes = deallocated_bytes + ptr%size
      DEALLOCATE(ptr)
    END SUBROUTINE Deallocate
    ```
  - `IF_Memory_Pool.f90` — 内存池管理
  - `IF_Memory_Leak.f90` — 泄漏检测
    ```fortran
    SUBROUTINE Leak_Dump()
      ! 伪代码：遍历所有未释放块，输出到日志
      ! DO WHILE (ASSOCIATED(block))
      !   WRITE(log_unit, *) "Leaked: ", block%alloc_id, &
      !                      " Size: ", block%size, &
      !                      " Source: ", block%source
      !   block => block%next
      ! END DO
      ! WRITE(log_unit, *) "Total leaked: ", total_allocated - total_deallocated
    END SUBROUTINE Leak_Dump
    ```

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
| 错误码范围 | `ERR_L1_MEMORY_xxx` (10500–10599)；**三级存储扩展 (10580–10599)** |
| 严重级 | WARNING: 内存池碎片化(可整理)/**池使用率>80% (Spill 预警)**; ERROR: 分配失败/内存不足/**Spill/Reload 失败**; FATAL: 系统级 OOM/**全池 OOM + Spill 磁盘满** |
| 传播规则 | 经 `status` 参数返回；不自行 STOP |
| 恢复策略 | WARNING：日志 + 触发整理/**触发 Spill**; ERROR：上报调用者决定降级/**回退到上一 Checkpoint**; FATAL：紧急 dump + 终止 |
| **三级存储错误码** | **ERR_POOL_OOM (10580), ERR_POOL_SPILL_FAILED (10581), ERR_POOL_RELOAD_FAILED (10582), ERR_POOL_INVALID_ID (10583), ERR_POOL_NOT_SPILLABLE (10584), ERR_IO_BUFFER_FULL (10585), ERR_CHECKPOINT_CORRUPT (10586)** |

---

### 域际关系

| 编号 | 对端域 | 关系类型 | 说明 |
|------|--------|----------|------|
| R1 | L2_NM/* | S(消费) | 数值方法层内存分配 (P5/P6 HOT 池) |
| R2 | L3_MD/* | S(消费) | 模型数据层内存分配 (P1/P2 COLD 池) |
| R3 | L4_PH/* | S(消费) | 有限元组件层内存分配 (P5/P6 HOT 池) |
| R4 | L5_RT/* | S(消费) | 运行时层内存分配 (P3/P5/P6/P7 池) |
| R5 | L6_AP/* | S(消费) | 应用层内存分配 (P1/SP3 池) |
| R6 | L1_IF/Error | U(USE) | 错误码定义 |
| R7 | L1_IF/Base | U(USE) | 基础类型 + SymTbl 元数据 (pool_id 字段) |
| R8 | L1_IF/Precision | U(USE) | 数据精度 |
| **R9** | **L1_IF/IO** | **U(USE)** | **Spill/Reload 文件读写 (IF_IO_SpillFile)** |
| **R10** | **L1_IF/Base/AI** | **S(消费)** | **AI 推理专用池 SP1 管理** |

---

### 约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 不得向上依赖 (L2–L6) | 硬 | Code Review | — |
| 热路径内禁止 ALLOCATE(Init 预分配) | 硬 | Harness | H-HOT-01 |
| 泄漏检测须可关闭(Release 模式) | 软 | Code Review | — |

---

### 十件套 v2.0 映射

| # | 逻辑件 | 本域映射 | 说明 |
|---|--------|----------|------|
| 1 | Desc 定义 | MemoryBlock / MemoryPool / **PoolConfig / SpillRecord** TYPE | 内存块与池描述 + **三级存储池注册** |
| 2 | State 定义 | 分配计数 / 内存池状态 / **PoolStats** | 运行时内存统计 + **池级利用率** |
| 3 | Algo 定义 | 首次适配/最佳适配 / 引用计数 / **LRU 淘汰 / 温度路由** | 分配策略 + **Spill 策略** |
| 4 | Ctx 定义 | **分配请求上下文 (pool_id + size + align)** | **StorageMgr 分配临时上下文** |
| 5 | Init/Finalize | Pool_Create / Pool_Destroy / **StorageMgr_Init / _Finalize** | 内存池生命周期 + **三级存储初始化** |
| 6 | Query | Get_Memory_Usage / Leak_Dump / **Get_Stats / Print_Report** | 内存统计查询 + **全池报告** |
| 7 | Validate | 泄漏检测 / 双重释放检查 | 内嵌 |
| 8 | Populate | N/A | L1 无 Populate 链 |
| 9 | Bridge | **StorageMgr ↔ IF_IO (Spill/Reload)** | **Tier 2→Tier 3 溢出桥接** |
| 10 | WriteBack | N/A | 基础设施不回写 |
| 11 | Parse | N/A | 不涉及关键字解析 |
| 12 | Compute | N/A | 非计算域 |
| 13 | Error | status 参数返回 / **ERR_POOL_OOM / ERR_POOL_SPILL_FAILED** | 见错误处理 + **溢出错误** |

---

### 四链说明

| 链 | 映射说明 |
|----|----------|
| 理论链 | 无理论背景——内存管理基础设施 |
| 逻辑链 | Allocate/Deallocate + Pool 管理，全层统一内存入口 |
| 计算链 | Init/Finalize 阶段分配；热路径禁止动态分配 |
| 数据链 | MemoryBlock 追踪链 → Leak_Dump 诊断输出 |


---

### dp_save / dp_load 接入点 (v3.0)

Checkpoint/Restart 统一流程中, Memory 域提供以下序列化入口:

| 接口 | 方向 | 说明 |
|------|------|------|
| `IF_Serial_Init` | — | 初始化序列化管理器 |
| `IF_Mem_Serial.Serialize` | Save | 将内存块序列化到字节流 |
| `IF_Mem_Serial.Deserialize` | Load | 从字节流反序列化到内存块 |
| `IF_WS_Save` | Save | Workspace 状态持久化 |
| `IF_WS_Load` | Load | Workspace 状态恢复 |

详见 [CHECKPOINT_UNIFIED_FLOW.md](../../../docs/05_Project_Planning/PPLAN/06_核心架构/CHECKPOINT_UNIFIED_FLOW.md)。

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_Mem.f90` | `IF_Mem` | `IF_MemPool_Desc`, `IF_MemPool_Runtime`, `IF_MemStats`, `IF_Memory_Domain` | `Init` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `CreatePool` (TBP,PRV,—); `AllocFromPool` (TBP,PRV,—); `AllocFromPoolById` (TBP,PRV,—); `ResetPool` (TBP,PRV,—); `GetStats` (TBP,PRV,—); `PrintReport` (TBP,PRV,—); `IF_FindPool` (FN,PRV,Query); `IF_Memory_Domain_Init` (SUB,PRV,Init); `IF_Memory_Domain_Finalize` (SUB,PRV,Finalize); `IF_Memory_CreatePool` (SUB,PRV,Init); `IF_Memory_AllocFromPool` (SUB,PRV,—); `IF_Memory_AllocFromPoolById` (SUB,PRV,—); `IF_Memory_ResetPool` (SUB,PRV,Mutate); `IF_Memory_GetStats` (SUB,PRV,Query); `IF_Memory_PrintReport` (SUB,PRV,IO) |
| `IF_Mem_Chunk.f90` | `IF_Mem_Chunk` | `ChunkMeta_Type`, `GenericChunkMetaType` | `IF_Chunk_Init` (SUB,PUB,Init); `IF_Chunk_Clear` (SUB,PUB,Mutate); `IF_Chunk_Register` (SUB,PUB,—); `IF_Chunk_Get` (SUB,PUB,Query); `gcm_init` (SUB,PUB,Init); `gcm_clear` (SUB,PUB,Mutate); `gcm_register_chunk` (SUB,PUB,—); `gcm_get_chunks` (SUB,PUB,Query) |
| `IF_Mem_Mgr.f90` | `IF_Mem_Mgr` | `MemoryPool`, `MemoryStatistics`, `IF_Mem_InitPool_In`, `IF_Mem_InitPool_Out`, `IF_Mem_AllocFromPool_In`, `IF_Mem_AllocFromPool_Out`, `IF_Mem_FreeToPool_In`, `IF_Mem_FreeToPool_Out`, `IF_Mem_GetStatistics_In`, `IF_Mem_GetStatistics_Out`, `LegacyPtrBlock` | `IF_Mem_InitPool_Structured` (SUB,PRV,Init); `IF_Mem_AllocFromPool_Structured` (SUB,PRV,—); `IF_Mem_FreeToPool_Structured` (SUB,PRV,Finalize); `IF_Mem_GetStatistics_Structured` (SUB,PRV,Query); `IF_Mem_AllocFromPool` (SUB,PUB,—); `IF_Mem_CheckLeaks` (SUB,PUB,Validate); `IF_Mem_FreeToPool` (SUB,PUB,Finalize); `IF_Mem_GetFragmentation` (SUB,PUB,Query); `IF_Mem_GetStatistics` (SUB,PUB,Query); `IF_Mem_InitPool` (SUB,PUB,Init); `IF_Mem_ShutdownPool` (SUB,PUB,—); `mem_init` (SUB,PUB,Init); `mem_alloc` (SUB,PUB,—); `mem_alloc_array` (SUB,PUB,—); `mem_free` (SUB,PUB,Finalize); `mem_alloc_pointer` (SUB,PUB,—); `mem_associate_pointer` (SUB,PUB,—); `mem_is_pointer_associated` (FN,PUB,Query); `mem_disassociate_pointer` (SUB,PUB,—); `INT_TO_STRING` (FN,PRV,—); `IF_Mem_AllocReal1D` (SUB,PUB,—); `UF_Mem_AllocReal1D` (SUB,PUB,—); `IF_Mem_AllocReal2D` (SUB,PUB,—); `UF_Mem_AllocReal2D` (SUB,PUB,—); `IF_Mem_FreeReal1D` (SUB,PUB,Finalize); `UF_Mem_FreeReal1D` (SUB,PUB,Finalize); `IF_Mem_FreeReal2D` (SUB,PUB,Finalize); `UF_Mem_FreeReal2D` (SUB,PUB,Finalize) |
| `IF_Mem_Serial.f90` | `IF_Mem_Serial` | `SerializationFormatType`, `SerializationManagerType` | `Init` (TBP,PRV,—); `RegisterFormat` (TBP,PRV,—); `Serialize` (TBP,PRV,—); `Deserialize` (TBP,PRV,—); `Valid` (TBP,PRV,—); `GetFormatInfo` (TBP,PRV,—); `Finalize` (TBP,PRV,—); `SerializeInterface` (SUB,PRV,—); `DeserializeInterface` (SUB,PRV,—); `GetSizeInterface` (FN,PRV,—); `IF_Serial_Init` (SUB,PUB,Init); `IF_Serial_Finalize` (SUB,PUB,Finalize); `IF_Serial_Get_SuppFmts` (FN,PUB,Query); `SerializationManager_Init` (SUB,PRV,Init); `SerializationManager_RegisterFormat` (SUB,PRV,—); `SerializationManager_Serialize` (SUB,PRV,—); `SerializationManager_Deserialize` (SUB,PRV,—); `SerializationManager_Valid` (SUB,PRV,Validate); `SerializationManager_GetFormatInfo` (SUB,PRV,Query); `SerializationManager_Finalize` (SUB,PRV,Finalize); `InitializeSerializationContext` (SUB,PRV,—); `CleanupSerializationContext` (SUB,PRV,—); `WriteSerializedData` (SUB,PRV,—); `ReadSerializedData` (SUB,PRV,—); `ValidateSerializedData` (SUB,PRV,—); `ValidateBinaryData` (SUB,PRV,—); `ValidateTextData` (SUB,PRV,—); `InitializeStandardFormats` (SUB,PRV,—); `IsFormatRegistered` (FN,PRV,—); `FindFormatId` (FN,PRV,—); `DetectFileFormat` (FN,PRV,—) |
| `IF_Mem_ThreadSlab.f90` | `IF_Mem_ThreadSlab` | `ThreadSlab` | `init` (TBP,PRV,—); `reset` (TBP,PRV,—); `alloc` (TBP,PRV,—); `usage` (TBP,PRV,—); `ThreadSlab_Init` (SUB,PUB,Init); `slab_init` (SUB,PRV,Init); `ThreadSlab_Finalize` (SUB,PUB,Finalize); `slab_reset` (SUB,PRV,Mutate); `ThreadSlab_Reset` (SUB,PUB,Mutate); `slab_alloc` (SUB,PRV,—); `ThreadSlab_Alloc` (SUB,PUB,—); `ThreadSlab_AllocAligned` (SUB,PUB,—); `slab_get_usage` (FN,PRV,Query); `ThreadSlab_GetUsage` (FN,PUB,Query); `ThreadSlab_Report` (SUB,PUB,IO) |
| `IF_Mem_WS.f90` | `IF_Mem_WS` | `Workspace`, `WorkspaceState`, `WorkspaceManager` | `StructWS_Proc` (SUB,PRV,—); `MultiFieldWS_Proc` (SUB,PRV,—); `StructBmWS_Proc` (SUB,PRV,—); `StructBmWS_Proc_2` (SUB,PRV,—); `PoroCapacityWS_Proc` (SUB,PRV,—); `ThermalCapacityWS_Proc` (SUB,PRV,—); `IF_WS_Mgr_Init` (SUB,PRV,Init); `IF_WS_Create` (SUB,PUB,Init); `IF_WS_Destroy` (SUB,PUB,Finalize); `IF_WS_Get` (SUB,PUB,Query); `IF_WS_Resize` (SUB,PUB,—); `IF_WS_Clear` (SUB,PUB,Mutate); `IF_WS_Save` (SUB,PUB,—); `IF_WS_Load` (SUB,PUB,Parse); `IF_WS_GetState` (SUB,PUB,Query); `IF_WS_SetState` (SUB,PUB,Mutate); `IF_WS_FindById` (FN,PRV,Query); `IF_WS_Reuse` (SUB,PUB,—); `IF_WS_EstimateSize` (SUB,PUB,—); `IF_WS_GetStatistics` (SUB,PUB,Query); `IF_WS_Compact` (SUB,PUB,—); `IF_WS_GetReuseCount` (SUB,PUB,Query); `RT_Elem_WS_RegStruct` (SUB,PUB,—); `RT_Elem_WS_RegMultiField` (SUB,PUB,—); `RT_Elem_WS_RegStructBm` (SUB,PUB,—); `RT_Elem_WS_RegStructBm_2` (SUB,PUB,—); `RT_Elem_WS_RegPoroCapacity` (SUB,PUB,—); `RT_Elem_WS_RegThermCapacity` (SUB,PUB,—); `RT_Elem_WS_GetStruct` (SUB,PUB,Query); `RT_Elem_WS_GetMultiField` (SUB,PUB,Query); `RT_Elem_WS_GetStructBm` (SUB,PUB,Query); `RT_Elem_WS_GetStructBm_2` (SUB,PUB,Query); `RT_Elem_WS_GetPoroCapacity` (SUB,PUB,Query); `RT_Elem_WS_GetThermCapacity` (SUB,PUB,Query); `GetStructWS` (SUB,PUB,—); `IF_WS_Alloc_SolverVec` (SUB,PUB,Compute); `IF_WS_Free_SolverVec` (SUB,PUB,Finalize); `IF_WS_Get_NL_DeltaWorkspace` (SUB,PUB,Query); `IF_WS_Get_Linear_Workspace` (SUB,PUB,Query); `IF_WS_Finalize` (SUB,PUB,Finalize); `UF_WS_Get_NL_DeltaWorkspace` (SUB,PUB,Query); `UF_WS_Get_Lin_Workspace` (SUB,PUB,Query); `UF_WS_Get_Linear_Workspace` (SUB,PUB,Query); `UF_WS_Finalize` (SUB,PUB,Finalize) |
| `IF_StructMemPool.f90` | `IF_StructMemPool` | `StructMemBlockType`, `CptrStorageType`, `StructMemberType`, `StructDefType`, `ClassDefType`, `UnifiedSubarrayType`, `StructDeviceBufferMapType`, `StructMemPoolType` | `add_class_member` (SUB,PUB,—); `add_struct_member` (SUB,PUB,—); `alloc_char1d` (SUB,PUB,—); `alloc_char2d` (SUB,PUB,—); `alloc_char3d` (SUB,PUB,—); `alloc_char4d` (SUB,PUB,—); `alloc_class` (SUB,PUB,—); `alloc_class_array` (SUB,PUB,—); `alloc_dp1d` (SUB,PUB,—); `alloc_dp2d` (SUB,PUB,—); `alloc_dp3d` (SUB,PUB,—); `alloc_dp4d` (SUB,PUB,—); `alloc_int1d` (SUB,PUB,—); `alloc_int2d` (SUB,PUB,—); `alloc_int3d` (SUB,PUB,—); `alloc_int4d` (SUB,PUB,—); `alloc_struct` (SUB,PUB,—); `alloc_struct_array` (SUB,PUB,—); `alloc_struct_mem` (SUB,PUB,—); `allocate_unified_memory` (SUB,PRV,—); `calculate_struct_size` (FN,PRV,—); `check_struct_block_device_mem` (SUB,PRV,—); `check_struct_block_device_mem_on_device` (SUB,PRV,—); `compute_member_size` (SUB,PRV,—); `create_struct_unified_mem` (SUB,PUB,—); `dealloc_struct_mem` (SUB,PUB,—); `destroy_struct_mem_pool` (SUB,PUB,—); `evict_lru_blocks` (SUB,PRV,—); `finalize_class_def` (SUB,PUB,—); `finalize_struct_def` (SUB,PUB,—); `find_free_block` (SUB,PRV,Finalize); `get_char1d_ptr` (SUB,PUB,—); `get_char2d_ptr` (SUB,PUB,—); `get_char3d_ptr` (SUB,PUB,—); `get_char4d_ptr` (SUB,PUB,—); `get_class_block_id_by_data_id` (SUB,PUB,—); `get_class_element_ptr` (SUB,PUB,—); `get_class_ptr` (SUB,PUB,—); `get_dims_string` (FN,PRV,—); `get_dp1d_ptr` (SUB,PUB,—); `get_dp2d_ptr` (SUB,PUB,—); `get_dp3d_ptr` (SUB,PUB,—); `get_dp4d_ptr` (SUB,PUB,—); `get_int1d_ptr` (SUB,PUB,—); `get_int2d_ptr` (SUB,PUB,—); `get_int3d_ptr` (SUB,PUB,—); `get_int4d_ptr` (SUB,PUB,—); `get_struct_block_base_cptr` (SUB,PUB,—); `get_struct_block_id_by_data_id` (SUB,PUB,—); `get_struct_element_cptr` (SUB,PUB,—); `get_struct_element_ptr` (SUB,PUB,—); `get_struct_mem_pool_stats` (SUB,PUB,—); `get_struct_ptr` (SUB,PUB,—); `get_struct_subarray_ptr_1d_char` (SUB,PUB,—); `get_struct_subarray_ptr_1d_dp` (SUB,PUB,—); `get_struct_subarray_ptr_1d_int` (SUB,PUB,—); `get_struct_subarray_ptr_2d_char` (SUB,PUB,—); `get_struct_subarray_ptr_2d_dp` (SUB,PUB,—); `get_struct_subarray_ptr_2d_int` (SUB,PUB,—); `get_struct_subarray_ptr_3d_char` (SUB,PRV,—); `get_struct_subarray_ptr_3d_dp` (SUB,PRV,—); `get_struct_subarray_ptr_3d_int` (SUB,PRV,—); `get_struct_subarray_ptr_4d_char` (SUB,PRV,—); `get_struct_subarray_ptr_4d_dp` (SUB,PRV,—); `get_struct_subarray_ptr_4d_int` (SUB,PRV,—); `get_timestamp` (SUB,PRV,—); `get_type_string` (FN,PRV,—); `get_unified_subarray_id_by_data_id` (SUB,PUB,—); `get_unified_subarray_ptr_generic` (SUB,PRV,—); `init_struct_mem_pool` (SUB,PUB,—); `initialize_class_memory` (SUB,PRV,—); `initialize_struct_memory` (SUB,PRV,—); `INT_TO_STR` (FN,PRV,—); `INT_TO_STR8` (FN,PRV,—); `lock_struct_mem` (SUB,PUB,—); `query_struct_mem_block` (SUB,PUB,—); `register_class_def` (SUB,PUB,—); `register_struct_def` (SUB,PUB,—); `register_struct_subarray` (SUB,PUB,—); `smem_get_device_buffer` (SUB,PUB,Query); `smem_map_block_to_device` (SUB,PUB,Populate); `smem_sync_block` (SUB,PUB,Populate); `sort_lru_list` (SUB,PRV,—); `unlock_struct_mem` (SUB,PUB,—); `verify_class_layout` (SUB,PUB,—); `verify_struct_layout` (SUB,PUB,—) |
| `IF_UnstructMemPool.f90` | `IF_UnstructMemPool` | `EdgeDataType`, `ListNodeType`, `LinkedListType`, `HashNodeType`, `HashBucketType`, `HashTableType`, `AdjacencyListType`, `SkipListNodeType`, `SkipListType`, `GraphNodeType`, `GraphType`, `QueueType`, `UnstructObjectDataType`, `UnstructObjectType`, `UnstructMemPoolType` | `find_object_index` (FN,PRV,—); `unstruct_data_exists` (FN,PUB,—); `simple_hash` (FN,PRV,Query); `adjacency_list_add_edge` (SUB,PUB,Mutate); `adjacency_list_delete_edge` (SUB,PUB,Mutate); `adjacency_list_get_edges` (SUB,PUB,Query); `create_adjacency_list` (SUB,PUB,—); `create_graph` (SUB,PUB,—); `create_hash_table` (SUB,PUB,Query); `create_linked_list` (SUB,PUB,—); `create_queue` (SUB,PUB,—); `create_skip_list` (SUB,PUB,—); `create_unstruct_data` (SUB,PUB,—); `delete_unstruct_data` (SUB,PUB,—); `destroy_unstruct_mem_pool` (SUB,PUB,—); `get_adjacency_list_size` (SUB,PUB,—); `get_graph_size` (SUB,PUB,—); `get_hash_table_size` (SUB,PUB,Query); `get_linked_list_size` (SUB,PUB,—); `get_queue_size` (SUB,PUB,—); `get_skip_list_size` (SUB,PUB,—); `get_unstruct_data_info` (SUB,PUB,—); `graph_add_edge` (SUB,PUB,Mutate); `graph_add_node` (SUB,PUB,Mutate); `graph_bfs` (SUB,PUB,—); `graph_dfs` (SUB,PUB,—); `graph_dfs_visit` (SUB,PRV,—); `graph_get_edges` (SUB,PUB,Query); `graph_remove_edge` (SUB,PUB,Mutate); `graph_remove_node` (SUB,PUB,Mutate); `hash_table_get` (SUB,PUB,Query); `hash_table_get_all` (SUB,PUB,Query); `hash_table_insert` (SUB,PUB,Mutate); `init_unstruct_mem_pool` (SUB,PUB,—); `insert_graph_edge` (SUB,PRV,—); `insert_single_edge` (SUB,PRV,—); `linked_list_delete` (SUB,PUB,Mutate); `linked_list_get_values` (SUB,PUB,Query); `linked_list_insert` (SUB,PUB,Mutate); `queue_allocate_storage` (SUB,PRV,—); `queue_dequeue` (SUB,PUB,—); `queue_enqueue` (SUB,PUB,—); `queue_get_all` (SUB,PUB,Query); `queue_peek` (SUB,PUB,—); `skip_list_delete` (SUB,PUB,Mutate); `skip_list_get_all` (SUB,PUB,Query); `skip_list_insert` (SUB,PUB,Mutate); `skip_list_search` (SUB,PUB,Query); `WRITE_INT` (FN,PRV,—) |
