# UFC 三级存储架构设计

> **版本**: v1.0 | **日期**: 2026-04-26
>
> **定位**: 统一管理 UFC FEM 内核的全部数据存储——从 CPU 缓存到磁盘持久化。
>
> **关联**:
> - 方法论: [ALGORITHM_STEP_PROTOCOL.md](../../templates/ALGORITHM_STEP_PROTOCOL.md)
> - 跨域数据流: [ASP_CROSS_DOMAIN_FLOW.md](ASP_CROSS_DOMAIN_FLOW.md)
> - L1 基础设施: [ASP_L1_IF.md](ASP_L1_IF.md)
> - 内存域合同: `UFC/ufc_core/L1_IF/Memory/CONTRACT.md`
> - IO 域合同: `UFC/ufc_core/L1_IF/IO/CONTRACT.md`

---

## 一、设计动机

### 1.1 问题陈述

| 问题 | 现状 | 后果 |
|------|------|------|
| 内存池爆炸 | 按层-域分配 → 理论 120+ 池 | 管理复杂、碎片化、统计困难 |
| 无溢出机制 | 大模型 (>10M DOF) 全驻 RAM | OOM 崩溃，无法处理超大问题 |
| 持久化分散 | Checkpoint/ODB/VTK 各自为政 | 无统一流控、无增量写入 |
| 缓存不感知 | ALLOCATE 随意分配 | 缓存行未对齐、AoS 布局低效 |
| AI 内存孤岛 | AI 推理缓冲独立管理 | 与 FEM 内存池不互通 |

### 1.2 设计目标

1. **内存池数量降到 ~10 个** (从 120+ 降一个数量级)
2. **透明溢出**: 内存不足时自动 Spill 到磁盘，回载时自动 Reload
3. **统一持久化**: Checkpoint / Output / Spill 共享同一 IO 后端
4. **缓存友好**: 热路径数据按 cache-line 对齐，支持 SoA 布局
5. **AI 集成**: AI 专用池 64-byte 对齐，支持 GPU 映射

---

## 二、内存池正交多维设计

### 2.1 维度定义

借鉴 Phase x Verb 的二维正交思路，内存池按**温度 x 形态**二维正交：

#### 维度一：数据温度（3 级）

| 温度 | 生命周期 | TYPE 载体 | 更新频率 | INTENT 倾向 |
|------|---------|-----------|---------|------------|
| COLD | 全分析期不变 | Desc | Config 阶段写入，之后只读 | IN |
| WARM | 跨增量/步演化 | State | 每增量/步更新 | INOUT |
| HOT | 每迭代/每GP | Ctx | 每次迭代重置 | INOUT |

#### 维度二：数据形态（4 类）

| 形态 | 典型数据 | 内存特征 | 对齐要求 |
|------|---------|---------|---------|
| SCALAR | 参数、标志、计数器 | 小块 (<1KB)、分散 | 无 |
| VECTOR | u(n_dof), F(n_dof), R(n_dof) | 大块连续 1D | cache-line (64B) |
| MATRIX | K_global(CSR), D_el(6,6), Ke(ndof,ndof) | 大块 2D/CSR | cache-line (64B) |
| STRUCT | TYPE 实例数组 (elem_desc(:)) | 复合结构体数组 | 按最大成员对齐 |

### 2.2 正交矩阵与裁剪

```
          SCALAR    VECTOR    MATRIX    STRUCT
  COLD    ×(合并P1)   P2        ×(少见)     P1
  WARM    ×(合并P7)   P3        P4(可选)   P7
  HOT     ×(无需)     P5        P6        ×(少见)
```

理论 12 格，裁剪理由：
- COLD+SCALAR: 量极小 (几十个参数)，合并到 COLD+STRUCT (P1)
- COLD+MATRIX: 极少 (弹性矩阵 D_el 缓存在 Ctx 里属 HOT)
- WARM+SCALAR: 量极小，合并到 WARM+STRUCT (P7)
- HOT+SCALAR: Ctx 中无独立标量池需求
- HOT+STRUCT: Ctx 中结构体实际是 VECTOR/MATRIX 的包装

### 2.3 最终池清单

#### 通用池 (7 个)

| 池 ID | 温度 | 形态 | 枚举值 | 典型消费者 | 预估规模 | 溢出策略 |
|-------|------|------|--------|-----------|---------|---------|
| **P1** | COLD | STRUCT | `POOL_COLD_STRUCT` | L3_MD 全部 Desc, L4_PH Desc | ~MB | 可溢出 (最优先) |
| **P2** | COLD | VECTOR | `POOL_COLD_VECTOR` | Mesh.coords, Mesh.conn, nodesets | ~10MB+ | 可溢出 (优先) |
| **P3** | WARM | VECTOR | `POOL_WARM_VECTOR` | stress_n, sdv_n, u_n, v_n, a_n | ~100MB | 可溢出 (Checkpoint 优先) |
| **P4** | WARM | MATRIX | `POOL_WARM_MATRIX` | 预条件矩阵 M_pc, Mass 矩阵 | ~10MB | 可溢出 |
| **P5** | HOT | VECTOR | `POOL_HOT_VECTOR` | r, p, Ap, du, F_ext, Fint, R | ~100MB | **禁止溢出** |
| **P6** | HOT | MATRIX | `POOL_HOT_MATRIX` | K_global(CSR), Ke_local | ~GB | **禁止溢出** |
| **P7** | WARM | STRUCT | `POOL_WARM_STRUCT` | elem_state(:), mat_state(:) | ~10MB | 可溢出 (Checkpoint 优先) |

#### 专用池 (3 个)

| 池 ID | 用途 | 枚举值 | 特殊要求 | 预估规模 |
|-------|------|--------|---------|---------|
| **SP1** | AI 推理 | `POOL_AI` | 64-byte 对齐, GPU 可映射 | 可配置 |
| **SP2** | 线程工作区 | `POOL_WORKSPACE` | per-thread Slab, 零碎片 | n_threads × slab_size |
| **SP3** | IO 缓冲 | `POOL_IO_BUFFER` | 双缓冲, 异步写入就绪 | ~10MB |

**总计: 10 个池** (7 通用 + 3 专用)

### 2.4 池枚举定义

```fortran
MODULE IF_StorageMgr_Def
  USE IF_Prec, ONLY: wp, i4
  IMPLICIT NONE

  INTEGER(i4), PARAMETER, PUBLIC :: POOL_COLD_STRUCT  = 1
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_COLD_VECTOR  = 2
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_WARM_VECTOR  = 3
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_WARM_MATRIX  = 4
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_HOT_VECTOR   = 5
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_HOT_MATRIX   = 6
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_WARM_STRUCT  = 7
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_AI           = 8
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_WORKSPACE    = 9
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_IO_BUFFER    = 10
  INTEGER(i4), PARAMETER, PUBLIC :: POOL_COUNT        = 10

  INTEGER(i4), PARAMETER, PUBLIC :: TEMP_COLD = 1
  INTEGER(i4), PARAMETER, PUBLIC :: TEMP_WARM = 2
  INTEGER(i4), PARAMETER, PUBLIC :: TEMP_HOT  = 3

  INTEGER(i4), PARAMETER, PUBLIC :: SHAPE_SCALAR = 1
  INTEGER(i4), PARAMETER, PUBLIC :: SHAPE_VECTOR = 2
  INTEGER(i4), PARAMETER, PUBLIC :: SHAPE_MATRIX = 3
  INTEGER(i4), PARAMETER, PUBLIC :: SHAPE_STRUCT = 4

  TYPE, PUBLIC :: PoolConfig
    INTEGER(i4) :: pool_id
    INTEGER(i4) :: temperature
    INTEGER(i4) :: data_shape
    INTEGER(i8) :: max_bytes          ! 池容量上限
    INTEGER(i8) :: spill_threshold    ! 溢出阈值 (bytes)
    LOGICAL     :: spillable          ! 是否允许溢出
    LOGICAL     :: gpu_mappable       ! 是否可映射 GPU
    INTEGER(i4) :: alignment          ! 对齐要求 (bytes)
    CHARACTER(LEN=32) :: name
  END TYPE PoolConfig

  TYPE, PUBLIC :: PoolStats
    INTEGER(i4) :: pool_id
    INTEGER(i8) :: allocated_bytes
    INTEGER(i8) :: peak_bytes
    INTEGER(i4) :: n_allocs
    INTEGER(i4) :: n_deallocs
    INTEGER(i4) :: n_spills
    INTEGER(i4) :: n_reloads
    REAL(wp)    :: utilization         ! allocated / max
  END TYPE PoolStats

  TYPE, PUBLIC :: SpillRecord
    INTEGER(i4) :: pool_id
    INTEGER(i4) :: block_id
    INTEGER(i8) :: offset_in_file
    INTEGER(i8) :: size_bytes
    INTEGER(i4) :: access_count
    LOGICAL     :: is_spilled
  END TYPE SpillRecord

END MODULE IF_StorageMgr_Def
```

---

## 三、三级存储架构

### 3.1 架构总览

```
┌─────────────────────────────────────────────────────────┐
│              Tier 3: External Storage (外存)             │
│                                                         │
│  ┌──────────────┐ ┌──────────────┐ ┌────────────────┐  │
│  │  Checkpoint   │ │   Output     │ │  Spill/Swap    │  │
│  │  (IF_IO_      │ │  (IF_Writer  │ │  (IF_IO_       │  │
│  │   Persist)    │ │   VTK/HDF5)  │ │   SpillFile)   │  │
│  │              │ │              │ │               │  │
│  │  Binary snap  │ │  ODB frames  │ │  Block-level   │  │
│  │  full/incr    │ │  Field/Hist  │ │  random R/W    │  │
│  └──────────────┘ └──────────────┘ └────────────────┘  │
│                                                         │
│  统一接口: IF_ExternalStorage_API                        │
└────────────────────┬────────────────────────────────────┘
                     │ Spill ↓ / Reload ↑ (LRU)
┌────────────────────┴────────────────────────────────────┐
│              Tier 2: Memory Pool (内存池)                │
│                                                         │
│  通用池:                                                 │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│  │ P1 │ │ P2 │ │ P3 │ │ P4 │ │ P5 │ │ P6 │ │ P7 │    │
│  │COLD│ │COLD│ │WARM│ │WARM│ │HOT │ │HOT │ │WARM│    │
│  │STRC│ │VEC │ │VEC │ │MTX │ │VEC │ │MTX │ │STRC│    │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘ └────┘    │
│                                                         │
│  专用池:                                                 │
│  ┌─────┐ ┌──────┐ ┌──────────┐                         │
│  │ SP1 │ │ SP2  │ │   SP3    │                         │
│  │ AI  │ │ WKSP │ │ IO_BUF   │                         │
│  │64B  │ │thrd  │ │ dbl-buf  │                         │
│  └─────┘ └──────┘ └──────────┘                         │
│                                                         │
│  统一门面: IF_StorageMgr                                 │
└────────────────────┬────────────────────────────────────┘
                     │ Layout / Prefetch
┌────────────────────┴────────────────────────────────────┐
│              Tier 1: Cache (缓存)                        │
│                                                         │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐  │
│  │  CPU Cache   │ │  GPU HBM    │ │  Layout Policy   │  │
│  │  L1/L2/L3    │ │  (AI pool)  │ │  SoA vs AoS     │  │
│  │  64B align   │ │  PCIe DMA   │ │  stride hint    │  │
│  └─────────────┘ └─────────────┘ └──────────────────┘  │
│                                                         │
│  控制方式: 编译器 hint + IF_Device_Mgr + 内存布局策略      │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Tier 1: 缓存层 (Cache)

缓存层不是软件显式管理的"池"，而是通过**内存布局策略**影响硬件缓存效率。

| 策略 | 实施方式 | 影响 |
|------|---------|------|
| **Cache-line 对齐** | P5/P6 分配 64-byte 对齐 | 避免 false sharing |
| **SoA 布局** | 元素 Ctx 数组按字段分离 | 向量化友好 |
| **预取提示** | GP 循环头 `!DIR$ PREFETCH` | 隐藏访存延迟 |
| **GPU DMA** | SP1 (AI 池) pinned memory | PCIe 传输零拷贝 |
| **连续分配** | HOT 池内部 bump allocator | 空间局部性 |

### 3.3 Tier 2: 内存池层 (Memory Pool)

#### 统一门面 IF_StorageMgr

```fortran
! IF_StorageMgr 公开接口 (概要)

SUBROUTINE IF_StorageMgr_Init(configs, n_pools, status)
SUBROUTINE IF_StorageMgr_Finalize(status)

SUBROUTINE IF_StorageMgr_Alloc(pool_id, nbytes, ptr, block_id, status)
SUBROUTINE IF_StorageMgr_Free(pool_id, block_id, status)
SUBROUTINE IF_StorageMgr_Reset_Pool(pool_id, status)

SUBROUTINE IF_StorageMgr_Get_Stats(pool_id, stats, status)
SUBROUTINE IF_StorageMgr_Print_Report(status)

! 高级接口
SUBROUTINE IF_StorageMgr_Alloc_Vector(pool_id, n, array, block_id, status)
SUBROUTINE IF_StorageMgr_Alloc_Matrix_CSR(pool_id, n, nnz, csr, block_id, status)

! Spill 控制
SUBROUTINE IF_StorageMgr_Force_Spill(pool_id, status)
SUBROUTINE IF_StorageMgr_Preload(pool_id, block_id, status)
```

#### 分配策略（按池温度不同）

| 温度 | 分配策略 | 释放策略 | 溢出行为 |
|------|---------|---------|---------|
| COLD | Bump allocator (顺序分配) | 不释放，Finalize 时批量 | 可溢出到 Tier 3 |
| WARM | Free-list (首次适配) | 增量结束时选择性释放 | 可溢出 (Checkpoint 优先) |
| HOT | Bump allocator (每迭代 Reset) | 整体 Reset | **禁止溢出** |

### 3.4 Tier 3: 外存层 (External Storage)

#### 三种外存场景

| 场景 | 触发方 | 数据来源 | 文件格式 | 生命周期 |
|------|--------|---------|---------|---------|
| **Checkpoint** | L6_AP/Job, L5_RT/StepDriver | WARM 池全量 + HOT 快照 | 二进制 (IF_IO_Persist) | 分析期间，可覆盖 |
| **Output** | L5_RT/Output | Field/History 变量 | ODB/HDF5/VTK/CSV | 永久保留 |
| **Spill** | IF_StorageMgr (自动) | COLD/WARM 池溢出块 | 块级二进制 (IF_IO_SpillFile) | 临时，分析结束清理 |

#### Spill/Reload 详细设计

```
Spill 流程:
  1. 池使用率 > spill_threshold
  2. 选择 LRU 块（最久未访问）
  3. 序列化块到 SpillFile (追加写入)
  4. 记录 SpillRecord (pool_id, block_id, file_offset)
  5. 释放块在池中的空间
  6. 标记块为 is_spilled = .TRUE.

Reload 流程:
  1. 访问已溢出块 (is_spilled = .TRUE.)
  2. 从 SpillFile 读取 (随机读)
  3. 在池中分配空间（可能触发新 Spill）
  4. 反序列化到池
  5. 标记 is_spilled = .FALSE.
  6. 更新 access_count
```

#### 溢出优先级

```
溢出优先顺序 (最先溢出 → 最后溢出):

  COLD+STRUCT (P1)    ← 配置数据，溢出后可重新从 L3 Populate
  COLD+VECTOR (P2)    ← 网格坐标等，溢出后可回载
  WARM+STRUCT (P7)    ← 状态结构体
  WARM+VECTOR (P3)    ← 状态向量 (stress_n 等)
  WARM+MATRIX (P4)    ← 预条件矩阵
  ─────────────────── 溢出禁止线 ───────────────────
  HOT+VECTOR (P5)     ← 迭代工作向量，禁止溢出
  HOT+MATRIX (P6)     ← K_global，禁止溢出
  SP1/SP2/SP3          ← 专用池，禁止溢出
```

---

## 四、与现有设施的演化映射

### 4.1 代码演化路径

| 现有设施 | 文件 | 新方案归属 | 演化策略 |
|---------|------|-----------|---------|
| `g_mem_pool` | IF_Mem_Mgr.f90 | P5/P6 后端 | 保留接口，内部转发到 StorageMgr |
| `g_core_mem_pool` | RT_CoreMemPool.f90 | 合并到 P5 | 标记 deprecated，转发 |
| `IF_StructMemPool` | IF_StructMemPool.f90 | P1/P7 后端 | 保留 struct 分配接口 |
| `IF_UnstructMemPool` | IF_UnstructMemPool.f90 | P1/P7 后端 | 保留 unstruct 分配接口 |
| `IF_Mem_ThreadSlab` | IF_Mem_ThreadSlab.f90 | SP2 后端 | 直接对接 |
| `IF_Mem_WS` | IF_Mem_WS.f90 | P5/P6 注册 | Workspace 向 StorageMgr 注册 |
| `IF_Mem_Serial` | IF_Mem_Serial.f90 | Tier 3 序列化 | Spill 使用其序列化 |
| `IF_IO_Persist` | IF_IO_Persist.f90 | Tier 3 Checkpoint | 扩展增量 Checkpoint |
| `IF_IO_StructFile` | IF_IO_StructFile.f90 | Tier 3 Output | 扩展流式写入 |
| `IF_Device_Mgr` | IF_Device_Mgr.f90 | Tier 1 GPU 映射 | SP1 设备缓冲管理 |

### 4.2 上层调用迁移（渐进式）

```fortran
! 迁移前：直接 ALLOCATE
ALLOCATE(coords(3, n_nodes))

! 迁移后：通过 StorageMgr
CALL IF_StorageMgr_Alloc_Vector(POOL_COLD_VECTOR, 3*n_nodes, coords, blk_id, status)

! 兼容层：现有 IF_Mem_AllocReal1D 内部转发
SUBROUTINE IF_Mem_AllocReal1D(n, arr, status)
  ! 内部实现改为:
  CALL IF_StorageMgr_Alloc_Vector(POOL_HOT_VECTOR, n, arr, blk_id, status)
END SUBROUTINE
```

---

## 五、与六层架构的集成

### 5.1 各层使用的池

| 层 | 主用池 | 辅用池 | 说明 |
|-----|-------|--------|------|
| L1_IF | (管理者) | SP2, SP3 | 提供存储服务 |
| L2_NM | P5, P6 | — | Solver 工作向量 + K_global |
| L3_MD | P1, P2 | P7 | 全部 Desc + Mesh 大数组 |
| L4_PH | P5, P6, P1 | — | Ctx 工作区 + Desc 参数 |
| L5_RT | P3, P5, P6, P7 | SP3 | State + 装配 + 输出 |
| L6_AP | P1 | SP3 | Config + Output |

### 5.2 生命周期对照

```
Phase      Pool Activity
─────────────────────────────────────────
Config     P1 分配 (Desc)
           P2 分配 (Mesh 大数组)
           P7 分配 (State 结构体)
           P3 分配 (State 向量: u, stress_n)
           SP1 分配 (AI 模型加载)

Populate   P1 填充 (L3→L4 Bridge)
           P2 填充 (coords, conn)

Step       P5 分配 (迭代向量: r, p, Ap)
  │        P6 分配 (K_global CSR)
  │
  ├─ Inc   P5/P6 每迭代 Reset + 重填
  │  │     P3 增量结束: Save_State (stress_n ← stress)
  │  │     SP3: Checkpoint 写入 (若触发)
  │  │
  │  └─ Iter  P5/P6 高频读写 (HOT_PATH)
  │           SP1: AI 推理 (若启用)
  │
  └─ End   SP3: Output 写入 (ODB/VTK)
           P3: WriteBack (stress → L3)

Finalize   全部池 Deallocate
           Spill 文件清理
```

---

## 六、持久化系统设计

### 6.1 三种持久化模式

#### Checkpoint (断点续算)

```
触发: 步结束 / 用户中断 / 定期
内容: WARM 池全量 + HOT 池增量快照
格式: 二进制 (IF_IO_Persist header + pool dump)
策略:
  - 全量: 首次 + 每 N 步
  - 增量: 仅写入自上次 Checkpoint 以来变化的块
  - 滚动: 保留最近 K 个 Checkpoint，自动清理旧的
```

#### Output (场输出/历史输出)

```
触发: 步结束 / 频率控制 (每 N 增量)
内容: Field Output (节点/单元场变量) + History Output (时间序列)
格式: ODB/HDF5 (大规模) / VTK (可视化) / CSV (历史)
策略:
  - 流式写入: 通过 SP3 IO_BUFFER 双缓冲
  - 异步: 缓冲满时触发后台写入 (若支持 async IO)
  - 压缩: 可选 ZLIB 压缩 (HDF5 内置)
```

#### Spill (溢出/交换)

```
触发: 池使用率超阈值 (自动)
内容: COLD/WARM 池中 LRU 块
格式: 块级二进制 (IF_IO_SpillFile)
策略:
  - LRU 淘汰: 最久未访问的块优先溢出
  - 温度优先: COLD 先于 WARM
  - 预取: 进入新增量前，预取下一增量可能需要的块
```

### 6.2 IO 缓冲策略 (SP3)

```
SP3 IO_BUFFER 双缓冲设计:

  ┌──────────┐     ┌──────────┐
  │ Buffer A │     │ Buffer B │
  │ (写入中)  │     │ (刷出中)  │
  └────┬─────┘     └────┬─────┘
       │                │
       │    交替         │
       ▼                ▼
  应用写入 ←──────→ 磁盘刷出

规则:
  - 应用往当前 buffer 写入
  - buffer 满时切换到另一个
  - 后台刷出已满 buffer 到磁盘
  - 若两个都满（IO 太慢），阻塞等待
```

---

## 七、AI 专用池 (SP1) 设计

### 7.1 AI 六插槽内存需求

| 插槽 | 消费者 | 输入规模 | 输出规模 | 调用频率 |
|------|--------|---------|---------|---------|
| AI_StepCtr | L5_RT/StepDriver | ~10 features | 1 (dt) | 每增量 |
| AI_ConvPredict | L5_RT/Solver | ~100 features | 1 (converge?) | 每迭代 |
| AI_MatInteg | L4_PH/Material | 6+n_sdv features | 6 (stress) | 每GP |
| AI_ContactLaw | L4_PH/Contact | ~20 features | ~10 (forces) | 每对 |
| AI_Preconditioner | L2_NM/Solver | sparse pattern | sparse values | 每迭代 |
| AI_SparseSolver | L2_NM/Solver | K,F | du | 每迭代 |

### 7.2 SP1 内存布局

```fortran
TYPE, PUBLIC :: AI_PoolConfig
  INTEGER(i8) :: input_buffer_size    ! 输入张量缓冲
  INTEGER(i8) :: output_buffer_size   ! 输出张量缓冲
  INTEGER(i8) :: model_cache_size     ! 模型参数缓存
  INTEGER(i4) :: alignment            ! 64 bytes (AVX-512)
  LOGICAL     :: gpu_pinned           ! pinned memory for DMA
  INTEGER(i4) :: max_batch_size       ! 批量推理最大 batch
END TYPE AI_PoolConfig
```

---

## 八、错误处理

| 错误码 | 说明 | 恢复策略 |
|--------|------|---------|
| ERR_POOL_OOM | 池内存不足 | 触发 Spill，重试分配 |
| ERR_POOL_SPILL_FAILED | Spill 到磁盘失败 | 尝试其他池 Spill，或报 FATAL |
| ERR_POOL_RELOAD_FAILED | Reload 失败 | 重试 + 报错 |
| ERR_POOL_INVALID_ID | 无效池 ID | 报 ERROR |
| ERR_POOL_NOT_SPILLABLE | 尝试溢出禁溢池 | 报 ERROR |
| ERR_IO_BUFFER_FULL | IO 双缓冲均满 | 阻塞等待 + WARNING |
| ERR_CHECKPOINT_CORRUPT | Checkpoint 文件损坏 | 回退到上一个 |

---

## 九、实施路线

### Phase 1: 架构设计 (本文档)
- 完整设计文档 (本文)
- CONTRACT.md 更新
- 内存池矩阵 + Spill 规格
- 算法步规约 (ASP_STORAGE_CROSS_CUT.md)

### Phase 2: L1_IF 核心实现
- IF_StorageMgr.f90 + _Def.f90 + _Spill.f90 + _Policy.f90
- IF_IO_SpillFile.f90
- 现有 IF_Mem_Mgr 适配层
- 单元测试

### Phase 3: 上层渐进接入
- L5_RT/Solver: RT_CoreMemPool 合并
- L4_PH: Element/Material Ctx → P5/P6
- L3_MD: Mesh.coords → P2
- L2_NM: Solver/Matrix → P5/P6

### Phase 4: 持久化 + AI
- SP3 双缓冲 + Output 流式写入
- 增量 Checkpoint
- SP1 AI 池 + GPU 映射
- 性能调优

---

## 十、性能指标目标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 池分配延迟 | < 100ns (HOT bump) | 不含系统 malloc |
| Spill 吞吐 | > 500 MB/s | SSD 顺序写 |
| Reload 延迟 | < 10ms per block | SSD 随机读 |
| 内存利用率 | > 90% (总池) | 碎片率 < 10% |
| IO 缓冲延迟 | < 1ms (buffer switch) | 双缓冲切换 |
| Checkpoint 开销 | < 5% 总计算时间 | 增量模式 |

---

## 附录 A: 内存池正交维度详细定义 + 池分配矩阵

### A.1 温度维度定义（形式化）

```
Temperature ::= COLD | WARM | HOT

COLD:
  write_phase   = Config (一次性)
  read_phase    = Populate + 全分析期
  update_freq   = 0 (不可变)
  INTENT        = IN (只读)
  TYPE_carrier  = Desc
  example       = 材料常数 E/ν、网格拓扑 conn(:,:)、节点坐标 coords(:,:)
  spillable     = YES (最优先溢出)

WARM:
  write_phase   = Step/Increment 结束
  read_phase    = 下一 Step/Increment
  update_freq   = O(n_step × n_inc)
  INTENT        = INOUT
  TYPE_carrier  = State
  example       = 应力 σ_n、状态变量 SDV_n、位移 u_n、速度 v_n
  spillable     = YES (Checkpoint 优先)

HOT:
  write_phase   = 每迭代 / 每 GP
  read_phase    = 同迭代内
  update_freq   = O(n_step × n_inc × n_iter × n_elem × n_gp)
  INTENT        = INOUT (频繁重写)
  TYPE_carrier  = Ctx
  example       = 残差 r, 搜索方向 p, K_global, Ke_local, strain/stress (当前)
  spillable     = NO (性能关键)
```

### A.2 形态维度定义（形式化）

```
DataShape ::= SCALAR | VECTOR | MATRIX | STRUCT

SCALAR:
  memory_pattern  = 小块 (<1KB), 分散
  alignment       = 无要求
  allocator       = 系统 ALLOCATE 或嵌入 STRUCT
  example         = n_nodes, n_elems, dt, tol, flags

VECTOR:
  memory_pattern  = 大块连续 1D, size ∝ n_dof 或 n_nodes
  alignment       = 64-byte (cache-line)
  allocator       = bump (HOT) 或 free-list (WARM)
  example         = u(n_dof), F(n_dof), R(n_dof), coords(3,n_nodes)

MATRIX:
  memory_pattern  = 大块 2D 或 CSR 稀疏, size ∝ n_dof² (稀疏) 或 ndof_el²
  alignment       = 64-byte
  allocator       = bump (HOT) 或 free-list (WARM)
  example         = K_global (CSR: val/col/row), D_el(6,6), Ke(24,24)

STRUCT:
  memory_pattern  = 复合结构体数组, 混合类型字段
  alignment       = 按最大成员对齐
  allocator       = struct-pool (slab 分配)
  example         = elem_desc(:), mat_slot(:), contact_pair(:)
```

### A.3 全量池分配矩阵

下表列出所有 53 个域到 10 个池的完整分配映射。

#### 表 A.3.1: L1_IF (基础设施层) — 池管理者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| Memory | 管理 | 管理 | 管理 | 管理 | 管理 | 管理 | 管理 | 管理 | 管理 | — |
| IO | — | — | — | — | — | — | — | — | — | 管理 |
| Base | — | — | — | — | — | — | — | — | — | — |
| Precision | — | — | — | — | — | — | — | — | — | — |
| Error | — | — | — | — | — | — | — | — | — | — |
| Log | — | — | — | — | — | — | — | — | — | — |
| Device | — | — | — | — | — | — | — | 协调 | — | — |
| Parallel | — | — | — | — | — | — | — | — | 协调 | — |
| AI | — | — | — | — | — | — | — | 消费 | — | — |

#### 表 A.3.2: L2_NM (数值方法层) — HOT 消费者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| Solver | — | — | — | P4(M_pc) | **P5** | **P6** | — | SP1? | **SP2** | — |
| Matrix | — | — | — | — | — | **P6** | — | — | — | — |
| Quadrature | — | — | — | — | — | — | — | — | SP2 | — |
| ShapeFunc | — | — | — | — | — | — | — | — | SP2 | — |
| Convergence | — | — | — | — | P5 | — | — | — | — | — |

#### 表 A.3.3: L3_MD (模型数据层) — COLD 主消费者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| Model | **P1** | — | — | — | — | — | — | — | — | — |
| Mesh | **P1** | **P2** | — | — | — | — | — | — | — | — |
| Material | **P1** | — | — | — | — | — | — | — | — | — |
| Section | **P1** | — | — | — | — | — | — | — | — | — |
| NodeSet | **P1** | **P2** | — | — | — | — | — | — | — | — |
| ElemSet | **P1** | **P2** | — | — | — | — | — | — | — | — |
| Surface | **P1** | **P2** | — | — | — | — | — | — | — | — |
| Assembly | **P1** | — | — | — | — | — | — | — | — | — |
| Step | **P1** | — | P3 | — | — | — | **P7** | — | — | — |
| Load | **P1** | **P2** | — | — | — | — | — | — | — | — |
| BC | **P1** | **P2** | — | — | — | — | — | — | — | — |
| Interaction | **P1** | — | — | — | — | — | — | — | — | — |
| Output | **P1** | — | — | — | — | — | — | — | — | — |
| Amplitude | **P1** | **P2** | — | — | — | — | — | — | — | — |
| Solver | **P1** | — | — | — | — | — | — | — | — | — |

#### 表 A.3.4: L4_PH (有限元组件层) — HOT+COLD 消费者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| Element | **P1** | — | — | — | **P5** | **P6** | — | — | **SP2** | — |
| Material | **P1** | — | — | — | **P5** | — | — | SP1? | **SP2** | — |
| LoadBC | **P1** | — | — | — | **P5** | — | — | — | — | — |
| Constraint | **P1** | — | — | — | **P5** | **P6** | — | — | — | — |
| Contact | **P1** | — | — | — | **P5** | — | — | SP1? | **SP2** | — |
| Section | **P1** | — | — | — | — | — | — | — | — | — |
| Interaction | **P1** | — | — | — | **P5** | — | — | — | — | — |

#### 表 A.3.5: L5_RT (运行时层) — 全池消费者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| StepDriver | — | — | **P3** | — | **P5** | — | **P7** | SP1 | — | — |
| Assembly | — | — | — | — | **P5** | **P6** | — | — | — | — |
| Solver | — | — | — | P4 | **P5** | **P6** | — | SP1? | **SP2** | — |
| ElementLoop | — | — | — | — | **P5** | **P6** | — | — | **SP2** | — |
| Output | — | — | — | — | — | — | — | — | — | **SP3** |
| Checkpoint | — | — | P3(读) | — | — | — | P7(读) | — | — | **SP3** |
| Contact | — | — | **P3** | — | **P5** | — | **P7** | — | **SP2** | — |
| DOFManager | — | — | — | — | **P5** | — | — | — | — | — |
| FieldManager | — | — | **P3** | — | — | — | **P7** | — | — | — |
| TimeIntegrator | — | — | **P3** | — | **P5** | — | — | — | — | — |

#### 表 A.3.6: L6_AP (应用层) — 轻量消费者

| 域 | P1 | P2 | P3 | P4 | P5 | P6 | P7 | SP1 | SP2 | SP3 |
|----|----|----|----|----|----|----|----|----|-----|-----|
| Job | **P1** | — | — | — | — | — | — | — | — | **SP3** |
| Config | **P1** | — | — | — | — | — | — | — | — | — |
| Output | — | — | — | — | — | — | — | — | — | **SP3** |

### A.4 池容量估算公式

| 池 | 估算公式 | 10M DOF 估算 |
|----|---------|-------------|
| P1 | n_domains × avg_desc_size | ~5 MB |
| P2 | 3×n_nodes×8 + n_elem×max_npe×4 + sets | ~300 MB |
| P3 | (6+n_sdv)×n_gp×8 + n_dof×8×3 | ~500 MB |
| P4 | nnz(M_pc)×8 (可选) | ~100 MB |
| P5 | n_dof×8×n_vecs (r,p,Ap,du,...~6个) | ~480 MB |
| P6 | nnz(K)×8 + (col+row)×4 | ~2 GB |
| P7 | n_elem×sizeof(elem_state) | ~80 MB |
| SP1 | max_batch × (input+output) × 8 | ~10 MB |
| SP2 | n_threads × slab_size | ~64 MB |
| SP3 | 2 × io_buf_size | ~20 MB |
| **总计** | | **~3.5 GB** |

### A.5 池配置初始化示例

```fortran
SUBROUTINE Setup_Default_Pool_Configs(configs, n_nodes, n_elems, n_dof, nnz_K)
  USE IF_StorageMgr_Def
  USE IF_Prec, ONLY: wp, i4
  IMPLICIT NONE
  TYPE(PoolConfig), INTENT(OUT) :: configs(POOL_COUNT)
  INTEGER(i4), INTENT(IN) :: n_nodes, n_elems, n_dof, nnz_K

  configs(POOL_COLD_STRUCT) = PoolConfig( &
    pool_id = 1, temperature = TEMP_COLD, data_shape = SHAPE_STRUCT, &
    max_bytes = 8_8 * 1024 * 1024, spill_threshold = 6_8 * 1024 * 1024, &
    spillable = .TRUE., gpu_mappable = .FALSE., alignment = 8, &
    name = 'COLD_STRUCT')

  configs(POOL_COLD_VECTOR) = PoolConfig( &
    pool_id = 2, temperature = TEMP_COLD, data_shape = SHAPE_VECTOR, &
    max_bytes = INT(3*n_nodes, 8) * 8_8 * 2, &
    spill_threshold = INT(3*n_nodes, 8) * 8_8, &
    spillable = .TRUE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'COLD_VECTOR')

  configs(POOL_WARM_VECTOR) = PoolConfig( &
    pool_id = 3, temperature = TEMP_WARM, data_shape = SHAPE_VECTOR, &
    max_bytes = INT(n_dof, 8) * 8_8 * 20, &
    spill_threshold = INT(n_dof, 8) * 8_8 * 16, &
    spillable = .TRUE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'WARM_VECTOR')

  configs(POOL_WARM_MATRIX) = PoolConfig( &
    pool_id = 4, temperature = TEMP_WARM, data_shape = SHAPE_MATRIX, &
    max_bytes = INT(nnz_K, 8) * 8_8, &
    spill_threshold = INT(nnz_K, 8) * 6_8, &
    spillable = .TRUE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'WARM_MATRIX')

  configs(POOL_HOT_VECTOR) = PoolConfig( &
    pool_id = 5, temperature = TEMP_HOT, data_shape = SHAPE_VECTOR, &
    max_bytes = INT(n_dof, 8) * 8_8 * 10, &
    spill_threshold = 0_8, &
    spillable = .FALSE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'HOT_VECTOR')

  configs(POOL_HOT_MATRIX) = PoolConfig( &
    pool_id = 6, temperature = TEMP_HOT, data_shape = SHAPE_MATRIX, &
    max_bytes = INT(nnz_K, 8) * 16_8, &
    spill_threshold = 0_8, &
    spillable = .FALSE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'HOT_MATRIX')

  configs(POOL_WARM_STRUCT) = PoolConfig( &
    pool_id = 7, temperature = TEMP_WARM, data_shape = SHAPE_STRUCT, &
    max_bytes = INT(n_elems, 8) * 256_8, &
    spill_threshold = INT(n_elems, 8) * 200_8, &
    spillable = .TRUE., gpu_mappable = .FALSE., alignment = 8, &
    name = 'WARM_STRUCT')

  configs(POOL_AI) = PoolConfig( &
    pool_id = 8, temperature = TEMP_HOT, data_shape = SHAPE_VECTOR, &
    max_bytes = 64_8 * 1024 * 1024, spill_threshold = 0_8, &
    spillable = .FALSE., gpu_mappable = .TRUE., alignment = 64, &
    name = 'AI')

  configs(POOL_WORKSPACE) = PoolConfig( &
    pool_id = 9, temperature = TEMP_HOT, data_shape = SHAPE_VECTOR, &
    max_bytes = 128_8 * 1024 * 1024, spill_threshold = 0_8, &
    spillable = .FALSE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'WORKSPACE')

  configs(POOL_IO_BUFFER) = PoolConfig( &
    pool_id = 10, temperature = TEMP_COLD, data_shape = SHAPE_VECTOR, &
    max_bytes = 20_8 * 1024 * 1024, spill_threshold = 0_8, &
    spillable = .FALSE., gpu_mappable = .FALSE., alignment = 64, &
    name = 'IO_BUFFER')

END SUBROUTINE Setup_Default_Pool_Configs
```

---

## 附录 B: Spill/Reload 策略规格设计

### B.1 概述

Spill/Reload 是 Tier 2 (Memory Pool) 与 Tier 3 (External Storage) 之间的核心交互协议。
当内存池使用率超过阈值时，按温度优先级和 LRU 策略将低优先级块溢出到磁盘；
当访问已溢出块时，自动从磁盘回载到内存池。

### B.2 SpillFile 格式

```
SpillFile 二进制格式:

┌──────────────────────────────────────────────┐
│  File Header (64 bytes)                      │
│  ├─ magic: "UFCSPILL" (8 bytes)              │
│  ├─ version: 1 (i4)                          │
│  ├─ block_count: N (i4)                      │
│  ├─ total_bytes: M (i8)                      │
│  ├─ create_time: timestamp (i8)              │
│  ├─ checksum_algo: CRC32 (i4)               │
│  └─ reserved: (28 bytes)                     │
├──────────────────────────────────────────────┤
│  Block Index Table (32 bytes × N)            │
│  ├─ block_id (i4)                            │
│  ├─ pool_id (i4)                             │
│  ├─ offset_in_file (i8)                      │
│  ├─ size_bytes (i8)                          │
│  ├─ checksum (i4)                            │
│  └─ flags (i4)  [compressed|encrypted|...]   │
├──────────────────────────────────────────────┤
│  Data Blocks (variable)                      │
│  ├─ Block 0: [data ...]                      │
│  ├─ Block 1: [data ...]                      │
│  └─ ...                                      │
└──────────────────────────────────────────────┘

设计要点:
  - Block Index Table 在文件头后面，支持快速定位
  - 每个 Data Block 可独立读取（随机访问）
  - 文件仅追加写入 (append-only) 以避免碎片
  - 已 Reload 的块不从文件删除（惰性清理）
  - 文件重整: 当碎片率 > 50% 时触发 compact
```

### B.3 Spill 触发与选择策略

#### B.3.1 触发条件

```
Spill 触发矩阵:

条件                              动作                 优先级
─────────────────────────────────────────────────────────────
pool.allocated > spill_threshold  Spill 该池 LRU 块     自动
pool.allocated > max_bytes × 0.95 紧急 Spill (多块)     紧急
系统可用内存 < 安全阈值              全局 Spill            紧急
用户显式调用 Force_Spill            Spill 指定池           手动
```

#### B.3.2 块选择 (LRU + 温度优先)

```
Spill 块选择算法:

INPUT:  需要释放的字节数 required_bytes
OUTPUT: 选中的块列表 spill_list

1. 按池温度排序: COLD 池 → WARM 池 (HOT 池禁止)
2. 在每个可溢出池内:
   a. 按 last_access_time 升序排列所有块 (LRU)
   b. 跳过 locked 块 (正在被访问)
   c. 跳过 pinned 块 (用户标记不可溢出)
3. 按排序顺序选择块直到累计 >= required_bytes
4. 返回 spill_list

优化: 批量 Spill — 一次选择比 required_bytes 多 20%
     的块，减少频繁触发
```

#### B.3.3 Spill 执行流程

```fortran
SUBROUTINE IF_StorageMgr_Spill_Execute(spill_list, n_blocks, status)
  ! Step 1: 锁定所有待溢出块 (防止并发访问)
  ! Step 2: 序列化块数据到内存缓冲
  ! Step 3: 写入 SpillFile (追加写, 更新 Block Index)
  ! Step 4: 计算并验证 checksum
  ! Step 5: 释放块在池中的空间
  ! Step 6: 更新 SpillRecord (offset, size, is_spilled=.TRUE.)
  ! Step 7: 解锁块 (SpillRecord 保留, 数据已释放)
  ! Step 8: 更新 PoolStats (n_spills++)
END SUBROUTINE
```

### B.4 Reload 策略

#### B.4.1 触发条件

```
Reload 触发:

  当且仅当: 访问块的 SpillRecord.is_spilled == .TRUE.

  等效于虚拟内存 "page fault" 概念
```

#### B.4.2 Reload 执行流程

```fortran
SUBROUTINE IF_StorageMgr_Reload(pool_id, block_id, ptr, status)
  ! Step 1: 查找 SpillRecord 获取 file_offset, size
  ! Step 2: 在目标池中尝试分配空间
  !         如果池满 → 递归触发 Spill (选择同池其他 LRU 块)
  ! Step 3: 从 SpillFile 随机读取数据
  ! Step 4: 反序列化到池中新分配的空间
  ! Step 5: 验证 checksum
  ! Step 6: 更新 SpillRecord (is_spilled = .FALSE.)
  ! Step 7: 更新 PoolStats (n_reloads++)
  ! Step 8: 返回数据指针 ptr
END SUBROUTINE
```

#### B.4.3 防循环溢出

```
防死循环机制:

  Reload 触发 Spill → Spill 选择其他块 → 其他块也在用？

  保护措施:
  1. Spill 选择时跳过 locked/pinned 块
  2. Reload 深度计数器: max_reload_depth = 3
  3. 超过深度 → 扩展池容量 (临时) + WARNING
  4. 如果扩展也失败 → ERR_POOL_OOM (FATAL)
```

### B.5 锁机制

```
块级锁:

  Lock(block_id)   — 标记块为"正在使用", Spill 跳过此块
  Unlock(block_id) — 解除锁定, 块可被 Spill

  Pin(block_id)    — 永久锁定 (直到显式 Unpin)
  Unpin(block_id)  — 解除永久锁定

  使用场景:
    Lock/Unlock — 短期 (一次函数调用内)
    Pin/Unpin   — 长期 (跨增量步)

  实现: atomic flag (OpenMP 兼容)
```

### B.6 SpillFile 生命周期管理

```
SpillFile 生命周期:

  创建: IF_StorageMgr_Init 时
    - 路径: <job_dir>/ufc_spill_<pid>.bin
    - 初始大小: 0 (按需增长)
    - 最大大小: 可配置 (默认: 可用磁盘空间的 50%)

  增长: Spill 时 append 写入
    - 块追加到文件末尾
    - Block Index Table 更新

  碎片整理: 当 (已释放块/总块数) > 50%
    - 新建临时文件, 仅复制有效块
    - 原子替换旧文件
    - 更新所有 SpillRecord 的 offset

  清理: IF_StorageMgr_Finalize 时
    - 强制 Reload 所有溢出块 (如果还在用)
    - 删除 SpillFile
    - 如果是异常退出, SpillFile 残留由下次启动清理

  Checkpoint 交互:
    - Checkpoint 前: 不需要 Reload 溢出块
      (SpillFile 本身可视为 COLD/WARM 的持久副本)
    - Checkpoint 写入: SpillRecord 表写入 Checkpoint
    - Restart 后: 重建 SpillFile 引用
```

### B.7 性能优化

| 优化 | 策略 | 预期收益 |
|------|------|---------|
| **批量 Spill** | 一次溢出多个块，合并 IO 操作 | 减少系统调用，+30% 吞吐 |
| **预取 Reload** | 进入新增量前，预取下一步需要的已溢出块 | 隐藏 IO 延迟 |
| **异步 Spill** | 后台线程执行 Spill 写入 | 不阻塞计算 |
| **压缩** | COLD 块写入前 ZLIB 压缩 (低频数据) | 减少 50% 磁盘占用 |
| **大页对齐** | SpillFile 块以 4KB 页对齐 | 直接 mmap 可能 |
| **IO 调度** | 合并相邻块的 Reload 为单次顺序读 | 减少随机 IO |

### B.8 监控与诊断

```fortran
TYPE, PUBLIC :: SpillDiagnostics
  INTEGER(i4) :: total_spills          ! 总溢出次数
  INTEGER(i4) :: total_reloads         ! 总回载次数
  INTEGER(i8) :: total_spill_bytes     ! 总溢出字节数
  INTEGER(i8) :: total_reload_bytes    ! 总回载字节数
  REAL(wp)    :: avg_spill_latency_ms  ! 平均溢出延迟
  REAL(wp)    :: avg_reload_latency_ms ! 平均回载延迟
  INTEGER(i4) :: spill_file_blocks     ! SpillFile 中的块数
  INTEGER(i8) :: spill_file_bytes      ! SpillFile 大小
  REAL(wp)    :: spill_file_fragmentation ! 碎片率
  INTEGER(i4) :: reload_depth_max      ! 最大 Reload 嵌套深度
END TYPE SpillDiagnostics

! 诊断输出示例:
! ===== Three-Tier Storage Report =====
! Pool  | Alloc    | Peak     | Util% | Spills | Reloads
! P1    | 2.1 MB   | 3.0 MB   | 70%   | 5      | 3
! P2    | 240 MB   | 280 MB   | 86%   | 12     | 8
! P3    | 480 MB   | 500 MB   | 96%   | 0      | 0
! P5    | 380 MB   | 400 MB   | 95%   | 0(禁)  | 0
! P6    | 1.8 GB   | 2.0 GB   | 90%   | 0(禁)  | 0
! SpillFile: 120 MB, 20 blocks, frag=15%
! Avg Spill: 2.3ms, Avg Reload: 5.1ms
```
