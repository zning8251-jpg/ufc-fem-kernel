# 算法步规约：L1_IF — 基础设施层（8 域 + StorageMgr）

> **版本**: v1.1 | **日期**: 2026-04-26 | **域类型**: 全部为数据域/观测域
>
> L1 特征：Config Phase 为主，无 HOT_PATH。算法步模式统一：Init → Configure → Query → Finalize。
>
> **v1.1 变更**: 新增 StorageMgr (三级存储管理器) 域；更新 Memory/IO 域以反映三级存储架构。
>
> **模式参考**: [ASP_GOLDEN_MD_Model.md](ASP_GOLDEN_MD_Model.md) （数据域黄金样板）
>
> **存储层详细规约**: [ASP_STORAGE_CROSS_CUT.md](ASP_STORAGE_CROSS_CUT.md) | [THREE_TIER_STORAGE.md](THREE_TIER_STORAGE.md)

---

## Base

**核心意图**: 全局初始化、版本查询、分析维度管理

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Base_Core_Init` | — | base_desc(空) | 分配描述器 | Config |
| 1 | `IF_Base_Global_Init` | n_dim, analysis_type (外部) | base_desc.n_dim, .analysis_type | 全局参数设定 | Config |
| 2 | `IF_Base_Get_Version` | 内部常量 | version_string | 读取编译期版本号 | (any) |
| 3 | `IF_Base_Get_NDim` | base_desc.n_dim | result(i4) | 返回空间维度 | (any) |
| 4 | `IF_Base_Get_Analysis_Type` | base_desc.analysis_type | result(i4) | 返回分析类型枚举 | (any) |
| 5 | `IF_Base_Core_Finalize` | base_desc | — | 释放资源 | Config |

### 闭合性验证

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| base_desc.n_dim | Step 1 | Step 3, 外部(L3/L4) | ✓ |
| base_desc.analysis_type | Step 1 | Step 4, 外部 | ✓ |
| version_string | Step 2 | 外部(UI) | ✓ |

---

## Precision

**核心意图**: `wp`/`i4`/`i8` 精度管理

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Precision_Core_Init` | — | prec_desc | KIND 参数初始化 | Config |
| 1 | `IF_Precision_Get_WP_Bytes` | 内部常量 | result(i4) | `result = STORAGE_SIZE(1.0_wp)/8` | (any) |
| 2 | `IF_Precision_Is_Double` | 内部常量 | result(LOGICAL) | `result = (wp == REAL64)` | (any) |
| 3 | `IF_Precision_Machine_Eps` | 内部常量 | result(wp) | `result = EPSILON(1.0_wp)` | (any) |
| 4 | `IF_Precision_Huge_Val` | 内部常量 | result(wp) | `result = HUGE(1.0_wp)` | (any) |
| 5 | `IF_Precision_Real_To_String` | val(wp) | char_string | 格式化输出 | (any) |
| 6 | `IF_Precision_Core_Finalize` | prec_desc | — | 释放 | Config |

### 闭合性: 纯查询域，所有 OUT 为返回值给外部消费者。✓ 全闭合。

---

## Registry

**核心意图**: 字符串键值注册表

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Registry_Core_Init` | — | registry_state(空) | 分配哈希表/数组 | Config |
| 1 | `IF_Registry_Register` | key, value (外部) | registry_state.entries(+1) | `entries(n+1) = {key, value}` | Config |
| 2 | `IF_Registry_Lookup` | key | result(value or NULL) | 线性/哈希查找 | (any) |
| 3 | `IF_Registry_Contains` | key | result(LOGICAL) | 同上，返回 bool | (any) |
| 4 | `IF_Registry_Remove` | key | registry_state.entries(-1) | 标记删除 | Config |
| 5 | `IF_Registry_Clear` | — | registry_state = 空 | 全量重置 | Config |
| 6 | `IF_Registry_Get_Count` | registry_state.n | result(i4) | 返回条目数 | (any) |
| 7 | `IF_Registry_Core_Finalize` | registry_state | — | 释放 | Config |

### 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| entries(:) | Step 1 (累积) | Step 2, 3, 4, 6 | ✓ |
| n (计数) | Step 1/4/5 | Step 6 | ✓ |

---

## Monitor

**核心意图**: 计时器、计数器、性能报告（观测域）

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Monitor_Core_Init` | — | monitor_state | 分配计时器/计数器池 | Config |
| 1 | `IF_Monitor_Timer_Start` | timer_id | timers(id).start_time | `CALL CPU_TIME(t); start=t` | (any) |
| 2 | `IF_Monitor_Timer_Stop` | timer_id | timers(id).elapsed += (now-start) | 累计计时 | (any) |
| 3 | `IF_Monitor_Counter_Inc` | counter_id, delta | counters(id) += delta | 原子递增 | (any) |
| 4 | `IF_Monitor_Report` | timers, counters | 格式化文本 | 遍历打印 | (any) |
| 5 | `IF_Monitor_Reset` | — | timers=0, counters=0 | 全量重置 | (any) |
| 6 | `IF_Monitor_Core_Finalize` | monitor_state | — | 释放 | Config |

### 跨域消费者: L5_RT/Logging, L6_AP/UI (读取 Report 输出)

---

## Log

**核心意图**: 结构化日志

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Log_Core_Init` | — | log_desc(level=INFO) | 设默认级别，打开缓冲 | Config |
| 1 | `IF_Log_Set_Level` | level(枚举) | log_desc.level | 更新日志级别 | Config |
| 2–5 | `IF_Log_Debug/Info/Warn/Error` | message, level | → 缓冲区/stdout | `IF (level >= current) WRITE(…)` | (any) |
| 6 | `IF_Log_Separator` | — | → stdout | 打印分隔线 | (any) |
| 7 | `IF_Log_Flush` | 缓冲区 | → 文件/stdout | 刷新缓冲 | (any) |
| 8 | `IF_Log_Core_Finalize` | log_desc | — | Flush + 关闭 | Config |

### 数据流模式: 纯输出型（生产→外部消费=人类/文件），无回流。✓

---

## IO

**核心意图**: 文件 I/O、检查点/重启；**三级存储 Tier 3 外存管理 (SpillFile, IOBuffer, Checkpoint)**

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_IO_Core_Init` | — | io_desc | 分配文件句柄池 | Config |
| 1 | `IF_IO_Open` | filename, mode | io_desc.unit_map(id) | `OPEN(UNIT=…, FILE=…)` | Config |
| 2 | `IF_IO_Read_Real_Array` | unit, n | data(n) | `READ(unit) data` | Config |
| 3 | `IF_IO_Read_Checkpoint` | filename | model_state | 反序列化 | Config |
| 4 | `IF_IO_Write_Real_Array` | unit, data(n) | → 文件 | `WRITE(unit) data` | Step |
| 5 | `IF_IO_File_Exists` | filename | result(LOGICAL) | `INQUIRE(FILE=…)` | (any) |
| 6 | `IF_IO_Close` | unit | — | `CLOSE(UNIT=…)` | Config |
| 7 | `IF_IO_Core_Finalize` | io_desc | — | 关闭所有句柄 | Config |
| **8** | **`IF_IO_SpillFile_Open`** | **job_dir, pid** | **SpillFile 句柄** | **创建 Spill 文件, 写入 Header** | **Config** |
| **9** | **`IF_IO_SpillFile_WriteBlock`** | **block_data, size** | **file_offset, checksum** | **追加写入+更新 Block Index** | **Inc** |
| **10** | **`IF_IO_SpillFile_ReadBlock`** | **file_offset, size** | **block_data** | **随机读取+CRC 校验** | **(any)** |
| **11** | **`IF_IO_SpillFile_Close`** | **SpillFile 句柄** | **—** | **关闭+可选碎片整理** | **Config** |
| **12** | **`IF_IO_IOBuf_Init`** | **buf_size** | **双缓冲 (A+B)** | **分配 SP3 IO_BUFFER** | **Config** |
| **13** | **`IF_IO_IOBuf_Write`** | **data** | **→ 活动缓冲** | **写入当前缓冲, 满时交换** | **Step** |
| **14** | **`IF_IO_IOBuf_Flush`** | **已满缓冲** | **→ 磁盘文件** | **后台刷出** | **Step** |
| **15** | **`IF_IO_IncrCP_Write`** | **dirty_blocks** | **→ Checkpoint 文件** | **仅写变化块 (增量 Checkpoint)** | **Step** |

### 跨域消费者: L6_AP/Input (Read), L5_RT/Output (Write), **StorageMgr (SpillFile R/W)**

---

## Memory

**核心意图**: 命名内存池、分配跟踪、泄漏检查；**三级存储内存池管理 (Tier 2)**

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Memory_Core_Init` | — | mem_state | 初始化跟踪表 | Config |
| 1 | `IF_Memory_Track_Alloc` | name, nbytes | mem_state.allocs(+1) | 记录分配 | (any) |
| 2 | `IF_Memory_Track_Dealloc` | name | mem_state.allocs(-1) | 标记释放 | (any) |
| 3 | `IF_Memory_Get_Usage` | — | result(i8) 字节数 | SUM(allocs.nbytes) | (any) |
| 4 | `IF_Memory_Check_Leaks` | mem_state | leak_count, leak_list | 遍历未释放项 | Config |
| 5 | `IF_Memory_Compact` | mem_state | — | 回收碎片 | Config |
| 6 | `IF_Memory_Core_Finalize` | mem_state | — | 释放跟踪表 | Config |

### 闭合性: Track_Alloc/Dealloc 成对，Check_Leaks 验证闭合。✓

---

## StorageMgr (三级存储管理器) 🆕

**核心意图**: 统一管理 10 个正交内存池 (温度×形态)，提供 Tier 2 分配/释放/Reset/Spill/Reload

> **详细 19 步算法**: 见 [ASP_STORAGE_CROSS_CUT.md](ASP_STORAGE_CROSS_CUT.md)
>
> **架构设计**: 见 [THREE_TIER_STORAGE.md](THREE_TIER_STORAGE.md)

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_StorageMgr_Init` | PoolConfig(10) | StorageMgr 实例, 10 池后端 | 分配池后端内存, 初始化分配器 | Config |
| 1 | `IF_StorageMgr_Configure` | n_nodes, n_elems, n_dof, nnz_K | 更新 PoolConfig.max_bytes | 按问题规模自适应调整池容量 | Config |
| 2 | `IF_StorageMgr_Alloc` | pool_id, nbytes | ptr, block_id | 路由到对应池: bump(HOT)/free-list(WARM)/bump(COLD) | (any) |
| 3 | `IF_StorageMgr_Free` | pool_id, block_id | — | 释放块, 更新 PoolStats | (any) |
| 4 | `IF_StorageMgr_Reset_Pool` | pool_id | — | bump 指针归零 (HOT 池) | Step/Inc |
| 5 | `IF_StorageMgr_Spill_Check` | PoolStats (utilization) | SpillRecord 更新 | 检查可溢出池, LRU 选择, 序列化到 SpillFile | Inc |
| 6 | `IF_StorageMgr_Reload` | block_id | ptr (回载数据) | 从 SpillFile 读取, 反序列化, CRC 校验 | (any) |
| 7 | `IF_StorageMgr_Force_Spill` | pool_id | — | 强制溢出指定池 | (manual) |
| 8 | `IF_StorageMgr_Preload` | block_id | ptr (预取数据) | 异步预取已溢出块 | Step |
| 9 | `IF_StorageMgr_Get_Stats` | pool_id | PoolStats | 返回池统计 | (any) |
| 10 | `IF_StorageMgr_Print_Report` | 全部 PoolStats + SpillDiagnostics | 格式化报告 | 遍历打印 | (any) |
| 11 | `IF_StorageMgr_Finalize` | StorageMgr 实例 | — | 释放全部池后端 + 报告 + 泄漏检查 | Config |

### 池清单 (10 个)

| 池 | 温度 | 形态 | 枚举 | 溢出 | 主消费者 |
|----|------|------|------|------|---------|
| P1 | COLD | STRUCT | `POOL_COLD_STRUCT` | ✅ | L3_MD Desc |
| P2 | COLD | VECTOR | `POOL_COLD_VECTOR` | ✅ | Mesh coords/conn |
| P3 | WARM | VECTOR | `POOL_WARM_VECTOR` | ✅ | State stress_n/u_n |
| P4 | WARM | MATRIX | `POOL_WARM_MATRIX` | ✅ | 预条件矩阵 |
| P5 | HOT | VECTOR | `POOL_HOT_VECTOR` | ❌ | 迭代向量 r/p/Ap |
| P6 | HOT | MATRIX | `POOL_HOT_MATRIX` | ❌ | K_global CSR |
| P7 | WARM | STRUCT | `POOL_WARM_STRUCT` | ✅ | State 结构体 |
| SP1 | — | AI | `POOL_AI` | ❌ | AI 推理 |
| SP2 | — | WORKSPACE | `POOL_WORKSPACE` | ❌ | 线程工作区 |
| SP3 | — | IO_BUFFER | `POOL_IO_BUFFER` | ❌ | IO 双缓冲 |

### 闭合性

| 数据项 | 生产者 | 消费者 | 闭合? |
|--------|--------|--------|-------|
| PoolConfig(10) | Step 0/1 | Step 2-11 | ✓ |
| ptr (分配指针) | Step 2 | 全部上层域 | ✓ |
| PoolStats | Step 2-6 (更新) | Step 5, 9, 10 | ✓ |
| SpillRecord | Step 5 (写) | Step 6 (读), 8 (预取) | ✓ |
| SpillDiagnostics | Step 5, 6 (更新) | Step 10, 11 | ✓ |

---

## Error

**核心意图**: 错误状态管理、栈式传播

### 算法步序列

| Step | 过程 | 消费 [IN] | 生产 [OUT] | 算法核 | Phase |
|------|------|-----------|-----------|--------|-------|
| 0 | `IF_Error_Core_Init` | — | error_desc | 初始化错误码表 | Config |
| 1 | `IF_Error_Create` | code, message | ErrorStatusType | 创建错误对象 | (any) |
| 2 | `IF_Error_Chain` | parent_err, child_err | chained_err | 链式追加 | (any) |
| 3 | `IF_Error_Set_Source` | err, file, line | err.source | 标注源位置 | (any) |
| 4 | `IF_Error_Get_Message` | err | message_string | 提取错误信息 | (any) |
| 5 | `IF_Error_Log` | err | → Log 子系统 | 格式化并调用 IF_Log | (any) |
| 6 | `IF_Error_Core_Finalize` | error_desc | — | 释放 | Config |

### 跨域消费者: **全部域**（每个过程都消费/生产 status）。✓ 全闭合。
