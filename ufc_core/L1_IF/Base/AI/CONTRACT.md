# L1_IF/AI 域合同卡

> **层级**: L1_IF (基础设施层)
> **域**: AI (AI运行时)
> **版本**: v1.1
> **状态**: Active
> **最后更新**: 2026-05-14

---


### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../AGENTS.md)** Repository rules §5 一致：**不**强制本域每个过程都使用 `*_Arg` / `Apply_*`。**避免**仅承载 **`status`**、无其它字段的 `Arg` 薄封装（无必要）。**保留** `*_Arg`（及 `Apply_*` 若适用）当一次交互有 **≥2** 个会一起演进的字段，或明确由 **Harness / 生成器 / 跨层编排** 消费。**层间边界**与 **L5 `_Proc`** 仍以全仓库 SIO 硬约束为准。

## 一、基本信息

- **域名**: AI (AI Runtime)
- **层级**: L1_IF
- **父域**: L1_IF (基础设施层)
- **子域**: 无
- **状态**: Active
- **域柱定位**: **基础设施域 (Infrastructure)** — 非域柱，横切所有层，类比 `IF_Mem`/`IF_Log`。为 6 个推理插槽提供公共引擎，插槽本身归属各自宿主域。见 `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §2.5。
- **一句话职责**: UFC数据中台的AI能力底座,提供硬件无关、模型格式无关、精度可配置的AI运行时服务

---

## 二、职责边界

### 本域负责
- ✅ ONNX Runtime统一封装,为上层6个AI插槽提供标准化推理接口
- ✅ 模型加载/卸载: ONNX模型加载、会话管理、热更新
- ✅ 推理执行: 单样本推理(调试)+批量推理(热路径SIMD/GPU加速)
- ✅ 设备管理: CPU/GPU切换、64-byte内存对齐(AVX-512)
- ✅ 张量运算: MatMul/Conv/激活函数(内部优化)
- ✅ 数据预处理/后处理: 归一化/标准化、特征提取、AI输出映射到物理量
- ✅ 错误映射: ONNX Runtime C API → UFC ErrorStatusType 100%覆盖

### 本域不负责
- ❌ AI算法逻辑(训练/优化/调参)
- ❌ 上层业务逻辑(切步控制/收敛预测/本构代理等)
- ❌ 模型训练与导出(仅负责推理)
- ❌ GPU底层驱动(通过ONNX Runtime间接调用)

---

## 三、四类TYPE映射

| TYPE | 是否必需 | 生命周期 | 所有权 | 跨层传递 |
|------|---------|---------|--------|---------|
| **Desc** (IF_AI_Model_Desc) | ✅ | 初始化后只读 | 本域 | 允许(L6→L1) |
| **State** (IF_AI_Infer_State) | ✅ | 运行时更新 | 本域 | 禁止 |
| **Algo** (IF_AI_Infer_Algo) | ✅ | 初始化后只读 | 本域 | 允许(L5→L1) |
| **Ctx** (IF_AI_Infer_Ctx) | ✅ | 调用级 | 调用方 | 允许 |

**嵌套四型布局（实现真源）**：`IF_AI_Def.f90` 中 **`IF_AI_Model_Desc`** 由 **`path` / `fmt` / `dim` / `params` / `flags`** 组成；**`IF_AI_Infer_State`** 由 **`count` / `timing` / `cache` / `flags` / `err`** 组成。**`IF_AI_Model_Desc_Init` / `IF_AI_Infer_State_Init`** 仅写入上述嵌套成员（2026-05-14 与 TYPE 定义对齐）。

---

## 四、四链映射

### 理论链
- ONNX Runtime C API规范: https://onnxruntime.ai/docs/api/c/
- AVX-512 SIMD优化指南
- 深度学习推理优化技术(SIMO&Laursen, 2020)

### 逻辑链
- L6_AP/L5_RT/L4_PH → IF_AI_API → IF_AI_Core → IF_AI_Runtime → ONNX Runtime
- 6个AI插槽统一调用入口,禁止上层直接调用底层引擎API

### 计算链
- 模型加载: 文件解析 → 图验证 → 会话创建 → 缓存
- 推理执行: 输入预处理 → 缓存检查 → ONNX推理 → 输出后处理
- 批量推理: 批量数据组装 → 单次ONNX调用 → 结果拆分 → 性能统计

### 数据链
- **Desc生命周期**: Job Init → 模型加载 → 推理使用 → Job Finalize
- **State生命周期**: 推理调用 → 状态更新 → 性能统计 → 下次调用
- **Ctx生命周期**: 推理开始 → 上下文分配 → 推理结束 → 上下文释放
- **缓存生命周期**: 模型加载 → 缓存填充 → 缓存命中/未命中 → 缓存清空

---

## 五、核心接口

### 对外API (IF_AI_API.f90)

| 接口 | 说明 | 调用方 |
|------|------|--------|
| `IF_AI_API_Init` | 初始化AI API系统 | L6_AP Job初始化 |
| `IF_AI_API_Finalize` | 释放AI API系统资源 | L6_AP Job清理 |
| `IF_AI_API_LoadModel` | 加载AI模型 | L5_RT/L4_PH |
| `IF_AI_API_UnloadModel` | 卸载AI模型 | L5_RT/L4_PH |
| `IF_AI_API_Infer` | 单样本推理 | AI_StepCtr/AI_MatInteg/AI_ContactLaw |
| `IF_AI_API_Infer_Batch` | 批量推理 | AI_ConvPredict/AI_Preconditioner/AI_SparseSolver |
| `IF_AI_API_ClearCache` | 清空推理缓存 | L5_RT/L4_PH |
| `IF_AI_API_GetPerfStats` | 获取性能统计 | L6_AP监控 |
| `IF_AI_API_GetVersion` | 获取版本号 | 调试/诊断 |
| `IF_AI_API_GetSummary` | 获取配置摘要 | 调试/诊断 |

### 对内实现

| 模块 | 说明 |
|------|------|
| `IF_AI_Core.f90` | AI推理引擎核心(会话管理/批量推理/设备管理/缓存) |
| `IF_AI_Runtime.f90` | ONNX Runtime接口(现有,STUB状态) |
| `IF_AI_ModelLoader.f90` | 模型加载器(.onnx/.pt格式支持+验证) |
| `IF_AI_TensorOps.f90` | 张量运算(MatMul/Conv/激活函数SIMD优化) |
| `IF_AI_Preprocess.f90` | 数据预处理+后处理(归一化/特征提取/物理量映射) |
| `IF_AI_Types.f90` | TYPE定义(Desc/State/Algo/Ctx) |

---

## 六、错误码

| 错误码 | 说明 | 处理策略 |
|--------|------|---------|
| L1:AI:0001 | AI域未初始化 | 调用IF_AI_API_Init |
| L1:AI:0002 | 模型文件不存在 | 检查模型路径 |
| L1:AI:0003 | 不支持的模型格式 | 仅支持.onnx/.pt |
| L1:AI:0004 | 会话池已满 | 增加max_sessions参数 |
| L1:AI:0005 | 无效会话索引 | 检查会话索引范围 |
| L1:AI:0006 | 推理失败 | 检查输入数据有效性 |
| L1:AI:0007 | 缓存清理失败 | 重试或忽略 |
| L1:AI:0008 | 输入维度不匹配 | 检查模型输入维度 |
| L1:AI:0009 | 检测到NaN/Inf值 | 数据预处理过滤 |
| L1:AI:0010 | 模型验证失败 | 检查模型完整性 |

---

## 七、依赖关系

### 依赖的下层域
- `L1_IF/Base` (IF_Prec_Core/IF_Math_Util)
- `L1_IF/Error` (IF_Err_API)
- `L1_IF/Memory` (IF_Mem_Core - 64-byte对齐分配)
- `L1_IF/IO` (IF_IO_File - 模型文件读取)

### 被上层依赖
- `L5_RT/StepDriver` (AI_StepCtr插槽)
- `L5_RT/Solver` (AI_ConvPredict插槽)
- `L4_PH/Material` (AI_MatInteg插槽)
- `L4_PH/Contact` (AI_ContactLaw插槽)
- `L2_NM/Solver` (AI_Preconditioner/AI_SparseSolver插槽)

---

## 八、文件清单

| 文件 | 行数 | 说明 | 状态 |
|------|------|------|------|
| `IF_AI_Core.f90` | 434 | AI推理引擎核心 | ✅ Active |
| `IF_AI_API.f90` | 399 | 统一API接口 | ✅ Active |
| `IF_AI_ModelLoader.f90` | 302 | 模型加载器 | ✅ Active |
| `IF_AI_TensorOps.f90` | 265 | 张量运算 | ✅ Active |
| `IF_AI_Preprocess.f90` | 287 | 数据预处理+后处理 | ✅ Active |
| `IF_AI_Types.f90` | 210 | TYPE定义 | ✅ Active |
| `IF_AI_Runtime.f90` | 374 | ONNX Runtime接口 | ⚠️ STUB |
| **合计** | **2271** | | |

---

## 九、测试策略

### 单元测试
- ✅ 模型加载/卸载测试
- ✅ 单样本推理测试
- ✅ 批量推理测试
- ✅ 缓存命中率测试
- ✅ 性能统计测试
- ✅ 数据归一化/反归一化测试
- ✅ NaN/Inf检测测试

### 集成测试
- ⏳ AI_StepCtr集成测试(L5_RT)
- ⏳ AI_ConvPredict集成测试(L5_RT)
- ⏳ AI_MatInteg集成测试(L4_PH)
- ⏳ AI_ContactLaw集成测试(L4_PH)

### 性能测试
- ⏳ 批量推理吞吐量测试(batch_size=100/1000/10000)
- ⏳ GPU加速比测试(CUDA vs CPU)
- ⏳ 缓存命中率测试(不同场景)
- ⏳ 内存对齐性能测试(64-byte vs 非对齐)

---

## 十、性能指标

| 指标 | 目标值 | 当前值 | 状态 |
|------|--------|--------|------|
| 单样本推理延迟 | <1ms | STUB | ⏳ |
| 批量推理吞吐量 | >10000 samples/s | STUB | ⏳ |
| 缓存命中率 | >80% | N/A | ⏳ |
| GPU加速比 | >10× (batch=1000) | N/A | ⏳ |
| 内存对齐 | 64-byte | ✅ | 🟢 |

---

## 十一、TODO清单

### Phase 1 (已完成)
- ✅ 补全6个核心文件(Core/API/Model_Loader/Tensor_Ops/Preprocess/Types)
- ✅ 创建CONTRACT.md合同卡
- ✅ 定义四类TYPE体系
- ✅ 定义错误码体系

### Phase 2 (待执行)
- ⏳ 实现ONNX Runtime C API绑定(IF_AI_Runtime.f90)
- ⏳ 实现GPU支持(CUDA/TensorRT)
- ⏳ 实现SIMD优化(AVX-512)
- ⏳ 完善单元测试

### Phase 3 (长期)
- 🔍 实现模型量化(INT8/FP16)
- 🔍 实现动态批处理
- 🔍 实现模型热更新
- 🔍 集成6个AI插槽

---

**审查人**: UFC Architecture Team  
**批准人**: UFC Core Team  
**最后更新**: 2026-04-17


---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `IF_AI.f90` | `IF_AI` | `IF_AI_CacheEntry`, `IF_AI_CacheManager`, `IF_AI_PerfStats`, `IF_AI_Domain` | `IF_AI_Domain_Init` (SUB,PUB,Init); `IF_AI_Domain_Finalize` (SUB,PUB,Finalize); `IF_AI_Domain_Infer` (SUB,PUB,—); `IF_AI_Domain_Infer_Batch` (SUB,PUB,—); `IF_AI_Domain_ClearCache` (SUB,PUB,Mutate); `IF_AI_Domain_GetPerfStats` (SUB,PUB,Query); `IF_AI_Domain_GetSummary` (SUB,PUB,Query) |
| `IF_AI_Brg.f90` | `IF_AI_Brg` | — | `IF_AI_API_Init` (SUB,PUB,Init); `IF_AI_API_Finalize` (SUB,PUB,Finalize); `IF_AI_API_LoadModel` (SUB,PUB,Parse); `IF_AI_API_UnloadModel` (SUB,PUB,—); `IF_AI_API_Infer` (SUB,PUB,—); `IF_AI_API_Infer_Batch` (SUB,PUB,—); `IF_AI_API_ClearCache` (SUB,PUB,Mutate); `IF_AI_API_GetPerfStats` (SUB,PUB,Query); `IF_AI_API_GetVersion` (SUB,PUB,Query); `IF_AI_API_GetSummary` (SUB,PUB,Query) |
| `IF_AI_Def.f90` | `IF_AI_Def` | `IF_AI_Model_Desc`, `IF_AI_Infer_State`, `IF_AI_Infer_Algo`, `IF_AI_Infer_Ctx` | `IF_AI_Model_Desc_Init` (SUB,PUB,Init); `IF_AI_Infer_State_Init` (SUB,PUB,Init); `IF_AI_Infer_Algo_Init` (SUB,PUB,Init); `IF_AI_Infer_Ctx_Init` (SUB,PUB,Init) |
| `IF_AI_ModelLoader.f90` | `IF_AI_ModelLoader` | `IF_AI_ModelMetadata`, `IF_AI_ModelCacheEntry`, `IF_AI_ModelCache` | `IF_AI_Model_Load` (SUB,PUB,Parse); `IF_AI_Model_Validate` (SUB,PUB,Validate); `IF_AI_Model_GetMetadata` (SUB,PUB,Query); `IF_AI_ModelCache_Init` (SUB,PUB,Init); `IF_AI_ModelCache_Find` (SUB,PUB,Query); `IF_AI_ModelCache_Add` (SUB,PUB,Mutate) |
| `IF_AI_Preprocess.f90` | `IF_AI_Preprocess` | `IF_AI_NormalizationParams` | `IF_AI_Preprocess_Normalize` (SUB,PUB,—); `IF_AI_Preprocess_Denormalize` (SUB,PUB,—); `IF_AI_Preprocess_ExtractFeatures` (SUB,PUB,—); `IF_AI_Preprocess_MapToPhysical` (SUB,PUB,Populate); `IF_AI_Preprocess_ValidateInput` (SUB,PUB,Validate) |
| `IF_AI_Runtime.f90` | `IF_AI_Runtime` | `IF_AI_SessionConfig`, `IF_AI_RuntimeState`, `IF_AI_SessionPool` | `IF_AI_CreateSession` (SUB,PUB,Init); `IF_AI_RunSession` (SUB,PUB,—); `IF_AI_RunSession_Batch` (SUB,PRV,—); `IF_AI_DestroySession` (SUB,PUB,Finalize); `IF_AI_SessionPool_Init` (SUB,PUB,Init); `IF_AI_SessionPool_Acquire` (SUB,PUB,—); `IF_AI_SessionPool_Release` (SUB,PUB,—) |
| `IF_AI_TensorOps.f90` | `IF_AI_TensorOps` | — | `IF_AI_Tensor_MatMul` (SUB,PUB,—); `IF_AI_Tensor_Conv2D` (SUB,PUB,—); `IF_AI_Tensor_ReLU` (SUB,PUB,—); `IF_AI_Tensor_Sigmoid` (SUB,PUB,—); `IF_AI_Tensor_Softmax` (SUB,PUB,—); `IF_AI_Tensor_AddBias` (SUB,PUB,Mutate) |
