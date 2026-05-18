# ASP 横切面: 三级存储算法步规约

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **定位**: 以算法步规约 (ASP) 格式描述三级存储系统的完整操作流程。
> 本文是 [THREE_TIER_STORAGE.md](THREE_TIER_STORAGE.md) 的算法步视图，
> 与 [ASP_CROSS_DOMAIN_FLOW.md](ASP_CROSS_DOMAIN_FLOW.md) 互补。
>
> **横切面说明**: 存储管理不属于单一域，而是**横切**所有六层和53个域。
> 本文以 IF_StorageMgr 为核心，描述存储操作在整个执行生命周期中的算法步。

---

## 一、执行生命周期中的存储算法步

### 总览: 存储操作按 Phase 分布

```
Phase        存储算法步                              执行频率
──────────────────────────────────────────────────────────────
Config       S01: StorageMgr_Init                   1 次
             S02: Pool_Configure                    1 次
             S03: SpillFile_Open                    1 次

Populate     S04: COLD_Pool_Allocate                n_desc 次
             S05: COLD_Pool_Fill                    n_desc 次
             S06: WARM_Pool_Allocate                n_state 次

Step         S07: HOT_Pool_Reset_And_Alloc          每步 1 次
  │
  ├─ Inc     S08: HOT_Alloc_IterVectors             每增量 1 次
  │  │       S09: Spill_Check_And_Execute           每增量 1 次
  │  │
  │  └─ Iter S10: HOT_Access (正常路径)              每迭代 n 次
  │          S11: Reload_On_Access (溢出路径)         稀有
  │
  ├─ IncEnd  S12: WARM_Evolve_State                 每增量 1 次
  │          S13: Checkpoint_Conditional             按频率
  │
  └─ StepEnd S14: Output_Flush                      每步 1 次
             S15: Preload_NextStep                  每步 1 次

Finalize     S16: SpillFile_Compact                 1 次
             S17: Pool_Deallocate_All               1 次
             S18: StorageMgr_Finalize               1 次
             S19: SpillFile_Cleanup                 1 次
```

---

## 二、算法步详细规约 (五元素卡)

### S01: StorageMgr_Init — 三级存储初始化

| 元素 | 内容 |
|------|------|
| **意图** | 初始化三级存储管理器，创建 10 个内存池，建立池注册表 |
| **消费** | 池配置 PoolConfig(10) ← L6_AP/Config 或默认值; 问题规模 (n_nodes, n_elems, n_dof, nnz_K) |
| **产出** | 全局 StorageMgr 实例 (pool_registry, stats_array, spill_records) |
| **算法核心** | 1. 读取池配置 → 2. 为每个池分配后端内存 (malloc) → 3. 初始化 bump/free-list 分配器 → 4. 注册到 SymTbl |
| **前置** | IF_Prec 已初始化; IF_Error 已初始化 |
| **后置** | 10 个池就绪; PoolStats 全零; SpillFile 未打开 |

### S02: Pool_Configure — 池容量自适应

| 元素 | 内容 |
|------|------|
| **意图** | 根据问题规模自适应调整池容量，避免过分配或欠分配 |
| **消费** | n_nodes, n_elems, n_dof, nnz_K ← L3_MD/Model (解析后) |
| **产出** | 更新后的 PoolConfig.max_bytes, spill_threshold |
| **算法核心** | 按附录 A.4 公式计算各池容量 → 检查系统可用内存 → 若不足: 缩减 COLD/WARM 池 + 启用 aggressive spill |
| **前置** | S01 完成; L3_MD/Model 已解析 (n_nodes 等已知) |
| **后置** | 池容量与问题规模匹配; 超大问题自动启用 spill 模式 |

### S03: SpillFile_Open — 外存通道建立

| 元素 | 内容 |
|------|------|
| **意图** | 创建 Spill 文件，建立 Tier 2↔Tier 3 通道 |
| **消费** | job_dir ← L6_AP/Job; pid ← 系统 |
| **产出** | SpillFile 句柄 (file_unit, header, block_index) |
| **算法核心** | 1. 构造路径 `<job_dir>/ufc_spill_<pid>.bin` → 2. 写入 File Header (magic, version) → 3. 初始化空 Block Index → 4. 注册到 IO 域 |
| **前置** | S01 完成; job_dir 有效 |
| **后置** | SpillFile 已创建 (0 blocks); IO 通道就绪 |

### S04: COLD_Pool_Allocate — 冷数据分配

| 元素 | 内容 |
|------|------|
| **意图** | 为 Desc 类型数据分配 COLD 池内存 (P1/P2) |
| **消费** | 分配请求 (pool_id, nbytes, alignment) ← L3_MD/*_Init, L4_PH/*_Init |
| **产出** | 数据指针 ptr, 块 ID block_id |
| **算法核心** | 1. 路由: struct→P1, vector→P2 → 2. bump allocator 分配 → 3. 记录 block 元数据 → 4. 更新 PoolStats |
| **前置** | 目标池已初始化 (S01) |
| **后置** | ptr 指向可用内存; block_id 注册到 SpillRecord 表 |

### S05: COLD_Pool_Fill — 冷数据填充

| 元素 | 内容 |
|------|------|
| **意图** | 通过 Populate 链填充 COLD 数据 (coords, conn, 材料参数等) |
| **消费** | L3_MD 解析结果 → COLD 池块 |
| **产出** | COLD 池数据就绪 (只读) |
| **算法核心** | Bridge 调用: L3→L4 Populate → 数据写入 P1/P2 块 → 标记为 READONLY |
| **前置** | S04 分配完成; L3_MD 数据解析完成 |
| **后置** | COLD 数据不可变; 所有 Desc 引用有效 |

### S06: WARM_Pool_Allocate — 温数据分配

| 元素 | 内容 |
|------|------|
| **意图** | 为 State 类型数据分配 WARM 池内存 (P3/P7) |
| **消费** | 分配请求 ← L5_RT/StepDriver_Init, L5_RT/FieldManager_Init |
| **产出** | State 向量/结构体的数据指针 |
| **算法核心** | 1. 路由: vector→P3, struct→P7 → 2. free-list 分配 → 3. 初始化为零 → 4. 更新 PoolStats |
| **前置** | S01 完成; 问题规模已知 |
| **后置** | u_n, stress_n, sdv_n, elem_state(:) 等分配就绪 |

### S07: HOT_Pool_Reset_And_Alloc — 热池重置

| 元素 | 内容 |
|------|------|
| **意图** | 每个分析步开始时重置 HOT 池，分配步级工作空间 |
| **消费** | 步配置 ← L5_RT/StepDriver |
| **产出** | HOT 池清空并重新分配; 步级工作向量就绪 |
| **算法核心** | 1. P5 Reset (bump 指针归零) → 2. P6 Reset → 3. 分配步级向量 (F_ext 等) → 4. 分配 K_global CSR 结构 |
| **前置** | S06 完成 (WARM 就绪) |
| **后置** | HOT 池 utilization ≈ 初始分配量; bump 指针设定 |

### S08: HOT_Alloc_IterVectors — 迭代向量分配

| 元素 | 内容 |
|------|------|
| **意图** | 每个增量步开始时分配迭代级工作向量 |
| **消费** | 增量步配置 ← L5_RT/StepDriver |
| **产出** | 迭代向量 (r, p, Ap, du, ...) 分配在 P5 |
| **算法核心** | P5 bump allocator: 连续分配 n_vecs × n_dof × 8 bytes |
| **前置** | S07 完成 |
| **后置** | 迭代向量可用; HOT 池 utilization 接近工作集大小 |

### S09: Spill_Check_And_Execute — 溢出检查

| 元素 | 内容 |
|------|------|
| **意图** | 在增量步开始时检查各可溢出池，必要时执行 Spill |
| **消费** | PoolStats (utilization) ← 各池; SpillFile 句柄 |
| **产出** | 释放的内存空间; 更新的 SpillRecord |
| **算法核心** | 1. 遍历可溢出池 (P1,P2,P3,P4,P7) → 2. 检查 utilization > threshold → 3. 选择 LRU 块 → 4. 序列化写入 SpillFile → 5. 释放池内空间 |
| **前置** | SpillFile 已打开 (S03) |
| **后置** | 所有池 utilization < threshold; SpillFile 更新 |

### S10: HOT_Access — 热路径内存访问 (正常路径)

| 元素 | 内容 |
|------|------|
| **意图** | 迭代循环中的正常内存读写 (K, F, r, p 等) |
| **消费** | HOT 池指针 (P5/P6 块) |
| **产出** | 计算结果写入 HOT 池 |
| **算法核心** | 直接指针访问, 无额外开销 (与 ALLOCATE 等价) |
| **前置** | S08 完成; 块未被 Spill (HOT 禁止溢出) |
| **后置** | 数据更新; 无 SpillRecord 变化 |

### S11: Reload_On_Access — 溢出块回载 (异常路径)

| 元素 | 内容 |
|------|------|
| **意图** | 访问已溢出到 Tier 3 的块时，自动回载到 Tier 2 |
| **消费** | SpillRecord (block_id, offset, size); SpillFile |
| **产出** | 块回载到池中; 数据指针更新 |
| **算法核心** | 1. 检测 is_spilled → 2. 池中分配空间 (可能触发 S09) → 3. SpillFile 随机读 → 4. CRC 校验 → 5. 标记 is_spilled=FALSE |
| **前置** | SpillFile 有效; 目标块 SpillRecord 存在 |
| **后置** | 块在池中可用; reload_count++ |

### S12: WARM_Evolve_State — 状态演化

| 元素 | 内容 |
|------|------|
| **意图** | 增量步收敛后，将 HOT 计算结果写回 WARM 状态 |
| **消费** | stress (HOT/P5) → stress_n (WARM/P3); u (HOT/P5) → u_n (WARM/P3) |
| **产出** | WARM 池状态更新为新收敛值 |
| **算法核心** | BLAS-style copy: P5 块 → P3 块 (向量); Ctx 结构 → State 结构 (P7) |
| **前置** | 增量步收敛 (NR 迭代成功) |
| **后置** | State 反映最新收敛结果; HOT 可安全 Reset |

### S13: Checkpoint_Conditional — 条件性断点保存

| 元素 | 内容 |
|------|------|
| **意图** | 按频率或用户请求将 WARM 池数据持久化到 Tier 3 |
| **消费** | P3 全量 (State 向量); P7 全量 (State 结构体); 步/增量编号 |
| **产出** | Checkpoint 文件 (二进制 snapshot) |
| **算法核心** | 1. 判断是否触发 (步频率 / 用户信号) → 2. 全量: dump P3+P7 → 3. 增量: 仅写入变化块 (dirty flag) → 4. 写入 SpillRecord 表 → 5. 滚动清理旧 Checkpoint |
| **前置** | S12 完成 (State 一致) |
| **后置** | Checkpoint 文件可用于 Restart |

### S14: Output_Flush — 输出刷出

| 元素 | 内容 |
|------|------|
| **意图** | 步结束时将场输出/历史输出通过 SP3 IO_BUFFER 刷到磁盘 |
| **消费** | Field/History 数据 ← L5_RT/Output; SP3 双缓冲 |
| **产出** | ODB/HDF5/VTK 文件更新 |
| **算法核心** | 1. 收集输出变量 → 2. 写入 SP3 活动缓冲 → 3. 缓冲满 → 交换缓冲 → 4. 后台刷出到文件 |
| **前置** | S12 完成; SP3 已初始化 |
| **后置** | 输出文件包含当前步数据 |

### S15: Preload_NextStep — 预取

| 元素 | 内容 |
|------|------|
| **意图** | 在步间隙预取下一步可能需要的已溢出 COLD 块 |
| **消费** | 下一步配置 (激活的 Load/BC/Material); SpillRecord 表 |
| **产出** | 预取的块回载到 COLD 池 |
| **算法核心** | 1. 分析下一步配置 → 2. 识别需要的 COLD 块 → 3. 检查是否已溢出 → 4. 异步 Reload |
| **前置** | 下一步配置已知 (L3_MD/Step) |
| **后置** | 下一步热路径不会触发 Reload |

### S16: SpillFile_Compact — 碎片整理

| 元素 | 内容 |
|------|------|
| **意图** | 分析结束前整理 SpillFile，减少碎片 |
| **消费** | SpillFile (含已回载的无效块) |
| **产出** | 紧凑的 SpillFile (或删除) |
| **算法核心** | 1. 扫描 Block Index → 2. 复制有效块到新文件 → 3. 原子替换 → 4. 更新 SpillRecord |
| **前置** | 所有计算步完成 |
| **后置** | SpillFile 碎片率 ≈ 0% |

### S17: Pool_Deallocate_All — 全池释放

| 元素 | 内容 |
|------|------|
| **意图** | 释放所有 10 个池的内存 |
| **消费** | 全部池后端内存 |
| **产出** | 系统内存归还 |
| **算法核心** | 按温度逆序释放: HOT → WARM → COLD → 专用池; 强制 Reload 仍在 SpillFile 中的块 (如需保留) |
| **前置** | S16 完成; 无活跃计算 |
| **后置** | 所有池 allocated_bytes = 0 |

### S18: StorageMgr_Finalize — 管理器关闭

| 元素 | 内容 |
|------|------|
| **意图** | 关闭三级存储管理器，输出最终报告 |
| **消费** | 全部 PoolStats; SpillDiagnostics |
| **产出** | 最终存储报告 (到日志); 泄漏检测结果 |
| **算法核心** | 1. Print_Report → 2. Leak_Check → 3. 释放管理器内部数据 |
| **前置** | S17 完成 |
| **后置** | StorageMgr 不可用; 所有内存归还系统 |

### S19: SpillFile_Cleanup — 外存清理

| 元素 | 内容 |
|------|------|
| **意图** | 删除 SpillFile 和临时文件 |
| **消费** | SpillFile 路径 |
| **产出** | 磁盘空间释放 |
| **算法核心** | 1. 关闭文件句柄 → 2. 删除文件 → 3. 清理临时目录 |
| **前置** | S18 完成 |
| **后置** | 无残留临时文件 (正常退出) |

---

## 三、生产-消费闭合矩阵

| # | 数据项 | 生产者 | 消费者 | 池归属 | 闭合验证 |
|---|--------|--------|--------|--------|---------|
| C1 | PoolConfig(10) | S01/S02 | 全部 S03-S18 | 管理器内部 | ✅ |
| C2 | SpillFile 句柄 | S03 | S09,S11,S13,S16,S19 | 管理器内部 | ✅ |
| C3 | COLD Desc 数据 | S04+S05 | L3→L4 Populate, L5 热路径 | P1/P2 | ✅ |
| C4 | WARM State 向量 | S06, S12 | S10 (读), S12 (写), S13 | P3 | ✅ |
| C5 | WARM State 结构体 | S06, S12 | S10, S12, S13 | P7 | ✅ |
| C6 | HOT 迭代向量 | S08 | S10 (高频读写) | P5 | ✅ |
| C7 | HOT K_global | S07 | S10 (装配+求解) | P6 | ✅ |
| C8 | SpillRecord 表 | S09 (写), S11 (更新) | S09,S11,S13,S15,S16 | 管理器内部 | ✅ |
| C9 | Checkpoint 文件 | S13 | Restart (外部) | Tier 3 | ✅ |
| C10 | Output 数据 | S14 | 后处理 (外部) | Tier 3 via SP3 | ✅ |
| C11 | SpillFile 块数据 | S09 (写) | S11 (读), S15 (预取) | Tier 3 | ✅ |
| C12 | PoolStats | S04-S12 (更新) | S09 (检查), S18 (报告) | 管理器内部 | ✅ |
| C13 | SpillDiagnostics | S09,S11 (更新) | S18 (报告) | 管理器内部 | ✅ |
| C14 | AI 推理缓冲 | SP1 分配 | L4_PH/Material AI, L5_RT AI | SP1 | ✅ |
| C15 | 线程工作区 | SP2 分配 | L4_PH/Element GP 循环 | SP2 | ✅ |

**闭合率: 15/15 = 100%**

---

## 四、温度梯度与数据流向

```
                    温度梯度 (COLD → HOT)
                    ─────────────────────→

Tier 3 (Disk)    Tier 2 (RAM)                    Tier 1 (Cache)
─────────────    ─────────────────────────────    ──────────────
                 P1 COLD_STRUCT  ─── Populate ──→
SpillFile ←──── P2 COLD_VECTOR  ─── Populate ──→ (Desc 缓存)
                 ├─────────────────────────────┤
Checkpoint ←─── P3 WARM_VECTOR  ←── Evolve ────→
Checkpoint ←─── P7 WARM_STRUCT  ←── Evolve ────→ (State 缓存)
                 ├─────────────────────────────┤
                 P5 HOT_VECTOR   ←→ Iterate ──→ L1/L2 缓存
                 P6 HOT_MATRIX   ←→ Iterate ──→ L1/L2 缓存
Output ←──────── ├─────────────────────────────┤
                 SP1 AI          ←→ Inference ─→ GPU HBM
                 SP2 WORKSPACE   ←→ Thread ────→ L1 缓存
ODB/VTK ←────── SP3 IO_BUFFER   ──→ Flush

数据流向:
  配置: Config → P1/P2 (一次性写入)
  填充: Populate P1/P2 → L4/L5 (只读)
  计算: P5/P6 高频读写 (每迭代)
  演化: P5 → P3, P7 (增量结束)
  持久: P3/P7 → Tier 3 (步结束)
  溢出: P1/P2 → SpillFile (自动, 按需)
  回载: SpillFile → P1/P2 (按需)
```

---

## 五、与现有 ASP 的接入点

存储操作嵌入到各域的算法步中，以下列出主要接入点：

| 现有 ASP 步 | 存储接入 | 说明 |
|------------|---------|------|
| ASP_RT_StepDriver.S01 (Init) | **S01+S02** | StorageMgr 初始化随 StepDriver 初始化 |
| ASP_RT_StepDriver.S03 (Populate) | **S04+S05** | COLD 分配+填充 |
| ASP_RT_StepDriver.S06 (Begin_Step) | **S07** | HOT 池 Reset |
| ASP_RT_StepDriver.S08 (Begin_Inc) | **S08+S09** | 迭代向量分配 + Spill 检查 |
| ASP_PH_Mat_Elas.S01-S07 | **S10** | 热路径访问 (全在 HOT 池) |
| ASP_RT_StepDriver.S10 (Converge) | **S12** | State 演化 |
| ASP_RT_StepDriver.S12 (End_Inc) | **S13** | 条件 Checkpoint |
| ASP_RT_StepDriver.S13 (End_Step) | **S14+S15** | Output + 预取 |
| ASP_RT_StepDriver.S14 (Finalize) | **S16-S19** | 全部清理 |
| ASP_MD_Model.S01 (Init) | **S04** | L3 Desc 分配走 P1/P2 |
| ASP_MD_Model.S03 (Populate) | **S05** | L3 数据填充 |

---

## 六、错误恢复流程

```
错误场景                          恢复策略
──────────────────────────────────────────────────────────
S04/S06: 池分配失败               → 触发 S09 (Spill)
                                  → 重试分配
                                  → 若仍失败: ERR_POOL_OOM

S09: Spill 写入失败              → 尝试扩展 SpillFile
                                  → 尝试另一磁盘路径
                                  → ERR_POOL_SPILL_FAILED

S11: Reload CRC 校验失败          → 重试读取 (1次)
                                  → 从最近 Checkpoint 恢复
                                  → ERR_POOL_RELOAD_FAILED

S13: Checkpoint 写入失败          → 重试
                                  → WARNING + 跳过 (非致命)

S14: IO_BUFFER 双缓冲均满         → 阻塞等待刷出完成
                                  → WARNING (IO 瓶颈)

S11→S09 循环 (Reload→Spill 死循环) → depth_counter > 3
                                    → 临时扩展池
                                    → ERR_POOL_OOM (FATAL)
```
