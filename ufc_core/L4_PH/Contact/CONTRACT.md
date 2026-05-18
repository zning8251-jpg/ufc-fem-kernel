# Contact 域合同卡 (L4_PH/Contact)

**Layer**: L4_PH (物理组件层)  
**Domain**: Contact (接触力学)  
**Version**: v3.1  
**Updated**: 2026-04-28  
**Status**: ACTIVE  
**关联文档**:  
- L3 合同卡: [`L3_MD/Interaction/CONTRACT.md`](../../L3_MD/Interaction/CONTRACT.md)  
- L5 合同卡: [`L5_RT/Contact/CONTRACT.md`](../../L5_RT/Contact/CONTRACT.md)  
- 四型设计: [`DESIGN_Cont_FourTypes.md`](./DESIGN_Cont_FourTypes.md)  
- 域柱架构: `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §P3

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules §5 一致。

## 一、职责边界

### 核心职责
- **定位**: UFC L4_PH 层 Contact 域 — 接触力学物理计算引擎
- **职责**: 间隙/穿透检测、法向力计算、摩擦力求解、接触刚度组装、搜索算法实现（BVH/Bucket/CCD）、显式接触力、热-力耦合接触、磨损演化
- **边界**: 仅提供物理计算内核；接触对 Desc 定义由 L3_MD/Interaction 持有；运行时调度与编排由 L5_RT/Contact 处理
- **依赖**: L3_MD/Interaction (Desc 定义, via Populate), L1_IF/Prec (精度), L1_IF/Error (错误码)

### 禁止事项
- **禁止**持有 Desc 真相源 — Desc 由 L3 定义，L4 仅 via Populate 接收只读副本
- **禁止**自行调度求解循环 — 迭代编排由 L5_RT 负责
- **禁止**直接 USE L3/L5 模块 — 跨层通信经 Bridge 过程
- **禁止**在热路径使用 ALLOCATE — Ctx 必须栈分配、零堆操作

---

## 二、文件清单 (18 个核心 .f90)

| 子目录 | 文件 | MODULE | 状态 | 角色 |
|--------|------|--------|------|------|
| `/` | `PH_Cont_Def.f90` | `PH_Cont_Def` | **AUTHORITY** | 统一四型 TYPE 定义 (Desc/State/Algo/Ctx + LEGACY 简化型) |
| `/` | `PH_Cont_Core.f90` | `PH_Cont_Core` | **ACTIVE** | 核心物理计算 (Gap/Force/Stiffness) |
| `Domain/` | `PH_Cont_Domain.f90` | `PH_Cont_Domain` | **ACTIVE** | 域级常量/枚举/容器 |
| `Core/` | `PH_Cont_Mgr.f90` | `PH_Cont_Mgr` | **ACTIVE** | 算法框架 + 结构化 SIO 过程 |
| `Core/` | `PH_Cont_Brg.f90` | `PH_Cont_Brg` | **ACTIVE** | L4 Bridge API (结构化 + 非结构化) |
| `Core/` | `PH_Cont_CSR.f90` | `PH_Cont_CSR` | **ACTIVE** | CSR 格式接触刚度装配 |
| `Core/` | `PH_Cont_Ctx_Def.f90` | `PH_Cont_Ctx_Def` | **ACTIVE** | 上下文管理 (PH_ContactCtx) |
| `Search/` | `PH_Cont_Search.f90` | `PH_Cont_Search` | **ACTIVE** | 搜索入口 (SpatialHash/BBox) |
| `Search/` | `PH_ContSearch_Adv.f90` | `PH_ContSearch_Adv` | **ACTIVE** | 高级搜索 (原 RT_ContSearch 已重命名) |
| `Search/` | `PH_Cont_BVHBuilder.f90` | `PH_Cont_BVHBuilder` | **ACTIVE** | BVH 树构建 |
| `Search/` | `PH_Cont_BVHQuery.f90` | `PH_Cont_BVHQuery` | **ACTIVE** | BVH 树查询 |
| `Search/` | `PH_Cont_CCD.f90` | `PH_Cont_CCD` | **ACTIVE** | 连续碰撞检测 (CCD) |
| `Friction/` | `PH_Cont_Friction.f90` | `PH_Cont_Friction` | **ACTIVE** | 摩擦模型库 (Coulomb/正则化/速率相关) |
| `Explicit/` | `PH_Cont_Expl.f90` | `PH_Cont_Expl` | **ACTIVE** | 显式动力学接触 |
| `Self/` | `PH_Cont_SelfContact.f90` | `PH_Cont_SelfContact` | **ACTIVE** | 自接触检测/排斥 |
| `Thermal/` | `PH_ThermalCont_Def.f90` | `PH_ThermalCont_Def` | **ACTIVE** | 热接触四型定义 |
| `Thermal/` | `PH_Cont_ThermoMech.f90` | `PH_Cont_ThermoMech` | **ACTIVE** | 热-力耦合接触 |
| `Wear/` | `PH_Cont_WearEvolution.f90` | `PH_Cont_WearEvolution` | **ACTIVE** | 磨损演化 (Archard/能量法) |
| `AI/` | `PH_AI_ContactLaw.f90` | `PH_AI_ContactLaw` | **ACTIVE** | AI 接触律代理 (插槽 4) |

---

## 三、四型 TYPE 映射

### 3.1 AUTHORITY 四型 (PH_Cont_Def.f90)

| 四型 | TYPE 名称 | 核心字段 | 温度/INTENT |
|------|-----------|----------|------------|
| **Desc** | `PH_Cont_Desc` | contact_pair_id, slave_surface_id, method, penalty_parameter, mu_static, mu_dynamic, search_algorithm | 冷/IN |
| **State** | `PH_Cont_State` | contact_state, gap, penetration, normal_force(:), friction_force(:), K_contact(:,:), slip_velocity(:), residual_norm, iteration_count | 温/INOUT |
| **Algo** | `PH_Cont_Algo` | max_iterations, tolerance, optimization_strategy, decay_rate, rate_dependency, ai_enabled | 冷/IN |
| **Ctx** | `PH_Cont_Ctx` / `PH_ContactCtx` | slave_node_coords(:,:), master_node_coords(:,:), normal_vector(:), tangent_vector(:), contactPressure, gap_function | 热/INOUT |

### 3.2 扩展四型

| TYPE | 所属模块 | 用途 |
|------|---------|------|
| `PH_Cont_Friction_Model` | `PH_Cont_Def` (Types) | 摩擦模型配置 |
| `PH_Cont_Thermal_Properties` | `PH_Cont_Def` (Types) | 热接触属性 |
| `PH_Cont_Dynamic_Properties` | `PH_Cont_Def` (Types) | 动力学接触属性 |
| `PH_Cont_Optimization_Params` | `PH_Cont_Def` (Types) | 优化参数 |
| `PH_Contact_VUINTER_Ctx` | `PH_Cont_Def` (Types) | 用户接触子程序上下文 |
| `PH_Contact_GAPCON_Ctx` | `PH_Cont_Def` (Types) | 间隙导热上下文 |
| `PH_Contact_UINTER_Ctx` | `PH_Cont_Def` (Types) | 隐式用户接触上下文 |
| `PH_Thermal_Cont_Desc/State/Algo/Ctx` | `PH_ThermalCont_Def` | 热接触完整四型 |

### 3.3 LEGACY 四型 (根目录 PH_Cont_Def.f90)

| TYPE | 说明 |
|------|------|
| `PH_Contact_Desc` | 简化 Desc (penalty_normal/tangent, gap_tolerance, mu_friction) |
| `PH_Contact_State` | 简化 State (gap, f_normal, f_friction, contact_status, slip) |
| `PH_Contact_Algo` | 简化 Algo (method, scale_factor) |
| `PH_Contact_Ctx` | 简化 Ctx (x_slave(3), x_master(3), normal(3), K_contact(24,24)) |

> **新代码应 USE `PH_Cont_Def`（已合并至根目录，Types/ 副本已删除）。**

---

## 四、核心接口清单

### 4.1 物理计算 (PH_Cont_Core)

| 接口 | 功能 | 签名概要 |
|------|------|----------|
| `PH_Contact_Core_Init` | 初始化状态+上下文 | (desc, state, algo, ctx, status) |
| `PH_Contact_Core_Finalize` | 释放/清零 | (state, ctx, status) |
| `PH_Contact_Compute_Gap` | 计算间隙 | (desc, state, ctx, status) |
| `PH_Contact_Compute_Normal_Force` | 罚函数法向力 | (desc, state, status) |
| `PH_Contact_Compute_Friction_Force` | Coulomb 摩擦力 | (desc, state, status) |
| `PH_Contact_Compute_Stiffness` | 接触刚度矩阵 | (desc, state, ctx, status) |
| `PH_Contact_Penalty_Param` | 罚参数估算 | (E, h_elem, scale) → penalty |
| `PH_Contact_Check_Status` | 状态判定 (OPEN/CLOSED) | (desc, state, status) |

### 4.2 算法框架 (PH_Cont_Mgr / PH_Cont_Brg)

| 接口 | 功能 |
|------|------|
| `PH_Cont_AlgorithmFramework` | 接触算法主框架 |
| `PH_Cont_SearchPairs` | 搜索配对 |
| `PH_Cont_DetectPenetration` | 穿透检测 |
| `PH_Cont_CalculateGap` | 间隙计算 |
| `PH_Cont_ApplyConstraints` | 约束施加 |
| `PH_Cont_UpdateFriction` | 摩擦更新 |
| `PH_Cont_ConvergenceCheck` | 收敛检查 |
| `PH_Cont_Penetration_Algo` | 穿透算法调度 |
| `PH_Cont_Friction_Algo` | 摩擦算法调度 |
| `PH_Cont_Thermal_Contact` | 热接触调度 |
| `PH_Cont_Dynamic_Contact` | 动力接触调度 |

### 4.3 搜索算法

| 接口 | 模块 | 功能 |
|------|------|------|
| `PH_Cont_SearchPairs` | `PH_Cont_Search` | 搜索入口 |
| `PH_Cont_SpatialHash` | `PH_Cont_Search` | 空间哈希搜索 |
| `PH_Cont_BoundingBox` | `PH_Cont_Search` | 包围盒检测 |
| `PH_Cont_Pair_Identify` | `PH_Cont_Search` | 接触对识别 |
| `PH_Cont_BuildBVH_FromSurface` | `PH_Cont_BVHBuilder` | BVH 构建 |
| `PH_ContBVH_Traverse` | `PH_Cont_BVHQuery` | BVH 遍历 |
| `PH_ContBVH_QueryPoint` | `PH_Cont_BVHQuery` | BVH 点查询 |
| `PH_ContBVH_CollectCandidates` | `PH_Cont_BVHQuery` | BVH 候选收集 |
| `PH_ContCCD_ComputeTOI` | `PH_Cont_CCD` | 碰撞时刻 (TOI) |
| `PH_ContCCD_ConservativeAdvancement` | `PH_Cont_CCD` | 保守步进法 |

### 4.4 摩擦模型

| 接口 | 模块 | 功能 |
|------|------|------|
| `PH_ContFric_Coulomb` | `PH_Cont_Friction` | Coulomb 摩擦 |
| `PH_ContFric_StickSlip` | `PH_Cont_Friction` | 粘滑转换 |
| `PH_ContFric_Regularized` | `PH_Cont_Friction` | 正则化摩擦 |
| `PH_ContFric_VelocityDep` | `PH_Cont_Friction` | 速率相关摩擦 |
| `PH_ContFric_PressureDep` | `PH_Cont_Friction` | 压力相关摩擦 |
| `PH_ContFric_TangentStiff` | `PH_Cont_Friction` | 摩擦切向刚度 |

---

## 五、接触算法矩阵

| 算法 | 枚举常量 | 适用场景 | 实现模块 | **完整度** |
|------|---------|---------|---------|----------|
| **Node-to-Surface (NTS)** | `PH_CONT_NODE_TO_SURF` | 小滑移、一般接触 | `PH_Cont_Domain` + `PH_Cont_NTS_Eval` | **55%** — BVH框架已有，NTS投影核心(NR+自然坐标)缺失 |
| **Surface-to-Surface (STS)** | `PH_CONT_SURF_TO_SURF` | 大滑移、大变形 | `PH_Cont_Domain` | **待补全** — 仅枚举定义 |
| **Mortar** | `PH_CONT_MORTAR` | 高精度、非匹配网格 | `PH_Cont_Domain` | **待补全** — 仅枚举定义 |
| **Self-Contact** | `PH_CONT_SELF_CONTACT` | 自身折叠/褶皱 | `PH_Cont_SelfContact` | **框架已有** — 自接触检测/排斥基础已建立 |

### 约束施加方法

| 方法 | 枚举常量 | 说明 | **完整度** |
|------|---------|------|----------|
| **罚函数法** | `PH_CONT_METHOD_PENALTY` | 标准罚函数, f = -k·g | **20%** — 标量gap/法向力框架已有，面级力向量/完整刚度矩阵缺失 |
| **Lagrange 乘子法** | `PH_CONT_METHOD_LAGRANGE` | 精确约束, 增加自由度 | **待补全** |
| **增广 Lagrange 法** | `PH_CONT_METHOD_AUGMENTED` | Uzawa 外迭代 (L5 调度) | **待补全** |

---

## 六、搜索方法支持矩阵

| 搜索方法 | 模块 | 复杂度 | 适用规模 | 说明 |
|---------|------|--------|---------|------|
| **BVH (层次包围体)** | `PH_Cont_BVHBuilder` + `PH_Cont_BVHQuery` | O(N log N) | 大规模 (>1000 对) | 生产首选 |
| **Spatial Hash (空间哈希)** | `PH_Cont_Search` | O(N) 均摊 | 中等规模 | 均匀分布优 |
| **Bounding Box (包围盒)** | `PH_Cont_Search` | O(N²) | 小规模 (<100 对) | 简单快速 |
| **CCD (连续碰撞检测)** | `PH_Cont_CCD` | O(N log N) | 高速冲击 | 防穿越保护 |
| **BruteForce** | `PH_Cont_Search` (fallback) | O(N²) | 调试/验证 | 保底方案 |

---

## 七、摩擦模型清单

| 模型 | 枚举 (Domain) | 枚举 (Friction) | 说明 |
|------|--------------|-----------------|------|
| **Coulomb** | `PH_FRIC_COULOMB` | `PH_FRICT_COULOMB` | 经典库仑摩擦 μ·N |
| **罚函数摩擦** | `PH_FRIC_PENALTY` | — | 罚参数摩擦 |
| **指数型** | `PH_FRIC_EXPONENTIAL` | — | 指数衰减摩擦 |
| **用户自定义** | `PH_FRIC_USER` | — | 用户子程序 FRIC/VFRIC |
| **粘滑转换** | — | `PH_FRICT_STICK_SLIP` | 精确粘滑判定 |
| **速率相关** | — | `PH_FRICT_VELOCITY_DEP` | 滑移速率依赖 |
| **压力相关** | — | `PH_FRICT_PRESSURE_DEP` | 接触压力依赖 |
| **正则化** | — | `PH_FRICT_REGULARIZED` | 光滑正则化过渡 |

> **枚举双轨说明**: `PH_FRIC_*` (PH_Cont_Domain) 为域级摩擦族分类; `PH_FRICT_*` (PH_Cont_Friction) 为算法级模型 ID。

---

## 八、热路径约束

| 约束项 | 规定 | 检查方式 |
|--------|------|---------|
| Ctx 零 ALLOCATE | `PH_Contact_Base_Ctx` 仅栈标量/定长数组，禁止 ALLOCATABLE | Code Review |
| 64-byte 对齐 | AVX-512 友好布局 | AP-8 规范 |
| 搜索频率策略 | BVH 重建频率由 L5 控制 (每 N 步重建)，L4 仅执行查询 | L5 Contract |
| IP 循环约束 | 接触力计算在 IP 循环外 (面级别)，不进入高斯点内循环 | 设计约束 |
| 热路径入口 | `PH_Cont_AlgorithmFramework` → 搜索 → 穿透检测 → 力计算 → 刚度装配 | Gold-Line |
| K_contact 装配 | 经 `PH_Cont_CSR` 直接写入 CSR 稀疏矩阵，避免中间稠密矩阵 | 性能约束 |

---

## 九、L3 消费契约 (via Populate)

| 数据项 | L3 来源 | L4 接收位置 | 传输方式 |
|--------|---------|------------|---------|
| 接触对定义 (pair_id, master/slave) | `MD_ContactPairDef` | `PH_Cont_Desc` | `MD_Cont_PH_FillParams_FromMD` |
| 摩擦参数 (mu, model_type) | `MD_ContactProperty_Type` | `PH_Cont_Friction_Model` | `MD_Cont_PH_FillParams_FromMD` |
| 罚刚度/算法参数 | `MD_Contact_Algo` | `PH_Cont_Algo` | `MD_Cont_PH_FillParams_FromMD` |
| 表面节点/单元 | `MD_Interaction_Domain` | `PH_Contact_Ctx` | Bridge 初始化 |

**Bridge 载体**: `L3_MD/Bridge/Bridge_L4/MD_ContPH_Brg`

---

## 十、L5 供给契约 (via Dispatch/Bridge)

| 服务 | L5 消费方 | L4 提供接口 | 说明 |
|------|----------|------------|------|
| 搜索配对 | `RT_Cont_Search` | `PH_Cont_SearchPairs` | L5 调度搜索频率 |
| 穿透检测 | `RT_Cont_Solv` | `PH_Cont_DetectPenetration` | 返回穿透量 |
| 接触力计算 | `RT_Cont_Solv` → `RT_Cont_ComputeForce` | `PH_Cont_Penetration_Algo` + `PH_Cont_Friction_Algo` | 法向+摩擦 |
| 接触刚度 | `RT_Cont_Solv` → `RT_Cont_Assemble` | `PH_Cont_Compute_Stiffness` | CSR 格式 |
| 收敛检查 | `RT_Cont_AugLagSolv` | `PH_Cont_ConvergenceCheck` | 残差范数 |
| 显式动力学 | `RT_Cont_Expl` | `PH_ContExpl_*` | 显式时间步 |
| 统计查询 | `RT_Cont_Solv` → `RT_Cont_GetStats` | `PH_Cont_CheckConvergence` | 迭代/穿透统计 |

**Bridge 载体**: `RT_Contact_Brg_ToL4` (L5→L4 上下文传递)

---

## 十一、域际关系

| 编号 | 对端域 | 关系 | 说明 |
|------|--------|------|------|
| R1 | L3_MD/Interaction | S(消费) | Desc 定义 via Populate |
| R2 | L5_RT/Contact | P(提供) | 物理计算内核 via Dispatch |
| R3 | L5_RT/Assembly | P(提供) | 接触刚度 → 全局 K/F |
| R4 | L1_IF/Prec | U(USE) | `wp`, `i4` 精度常量 |
| R5 | L1_IF/Error | U(USE) | `ErrorStatusType` |

---

## 十二、域缩双名登记 (UFC_命名规范_v3.0 §10.1)

本域存在两种域缩并用:
- **`PH_Cont_*`** — 短形式，用于 TYPE 定义 (`PH_Cont_Def`, `PH_Cont_Desc`) 和紧凑模块名
- **`PH_Contact_*`** — 长形式，用于核心实现 (`PH_Contact_Core`, `PH_Contact_Def`) 和过程名

两者等价，新代码优先使用 **`PH_Cont_*`** (短)。不强制批量改名。

---

## 十三、AI Enhancement (插槽 4: AI_ContactLaw)

| 项 | 内容 |
|----|------|
| **插槽编号** | 4 (AI_ContactLaw) |
| **定位** | 域级增强 (Concern B) — 本域可选 AI 路径 |
| **模块** | `AI/PH_AI_ContactLaw.f90` |
| **四型** | Algo: `AI_ContactLaw_Type` (网络配置) |
| **公开接口** | `AI_ContactLaw_Init`, `AI_ContactLaw_Predict`, `AI_ContactLaw_Finalize` |
| **调用时机** | 接触面法向/切向力计算 |
| **引擎** | L1 `IF_AI_Runtime` (ONNX) |
| **默认** | `enabled = .FALSE.`，零开销 |
| **参见** | `AI_Slot_Contract.md` §2.4, `UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §2.5 |

---

## 十四、错误处理

| 项目 | 规定 |
|------|------|
| 错误码范围 | `ERR_L4_CONTACT_xxx` (40300–40399) |
| 严重级 | WARNING: 搜索无候选 (fallback BruteForce); ERROR: 穿透超阈值/几何退化; FATAL: BVH 构建失败 (内存) |
| 传播规则 | 经 `ErrorStatusType` + `status` 参数返回调用方；不自行 STOP |
| 恢复策略 | WARNING：日志 + fallback; ERROR：中止当前对并上报; FATAL：标记 status 并返回 |

---

## 十五、算法完整度评估（基于 FourDomain_HotPath 报告）

> 综合加权完整度：**37%** | 复用级别：L2-L3 | 预估补齐工期：13天

| 算法模块 | 完整度 | 可复用 | 缺失关键项 |
|----------|--------|--------|----------|
| **NTS 搜索** | **55%** | BVH框架、栈式遍历 | NTS投影核心(NR迭代+自然坐标求解)、空间哈希完整实现 |
| - BVH构建 | 70% | AABB计算+递归分裂 | SAH排序 (TODO) |
| - BVH遍历 | 80% | 栈式遍历框架 | 精确距离计算 (TODO) |
| - 全局搜索 | 40% | 暴力搜索可作fallback | BVH集成路径 (placeholder) |
| - 空间哈希 | 20% | 接口定义 | 完整哈希表实现 |
| - NTS投影 | **0%** | — | 局部NR投影 + 自然坐标求解 |
| - CCD | 60% | TOI计算框架 | 保守步进精化 |
| **罚函数** | **20%** | 标量gap逻辑、罚参数估算 | 面级投影后间隙、等效节点力向量、完整(3n+3)×(3n+3)刚度矩阵 |
| - 间隙函数 | 40% | 标量gap逻辑 | 面级投影后间隙 |
| - 法向力 | 60% | 罚函数公式 | 等效节点力向量 |
| - 接触刚度 | 30% | 3×3外积框架 | 完整接触刚度矩阵 |
| - 罚参数估算 | 80% | E/h估算 | 自适应调整 |
| - CSR装配 | 60% | CSR格式框架 | 对接新刚度格式 |
| **Coulomb摩擦** | **15%** | 速度方向摩擦力、指数衰减 | 增量返回映射、粘结/滑动分支一致切线 |
| - Coulomb基础 | 50% | 速度方向摩擦力 | 增量返回映射 |
| - 粘滑转换 | 50% | 指数衰减公式 | 与返回映射集成 |
| - 正则化 | 70% | tanh正则化 | 无需大改 |
| - 一致切线 | 30% | 近似外积 | 粘结/滑动分支精确形式 |
| - 切向刚度 | **0%** | — | 与罚函数刚度合并 |

---

## 十六、约束分级

| 约束 | 级别 | 检查方式 | Gate |
|------|------|----------|------|
| Desc 为只读，L4 不修改 L3 数据 | 硬 | Code Review | — |
| Ctx 零 ALLOCATE，栈分配 | 硬 | AP-8 | H-PERF-01 |
| 禁止在 L4 自行编排迭代循环 | 硬 | Code Review | — |
| 跨层须经 Bridge，禁止直接 USE L3/L5 | 硬 | Harness | H-DEP-03 |
| 使用 `IF_Prec_Core` 的 `wp`/`i4` | 硬 | Harness | H-ERR-01 |
| 接触算法枚举变更须同步更新本 CONTRACT | 软 | Code Review | — |
| 搜索算法选择须与 L5 Contract 对齐 | 软 | Code Review | — |

---

## 十七、验收标准

### 算法完整性

| 检查项 | 要求 | 当前状态 |
|--------|------|----------|
| NTS 投影核心 | NR迭代+自然坐标求解完整 | **缺失**(0%) — P0优先补全项 |
| 罚函数法向力 | 面级投影后间隙→等效节点力向量 | **部分**(20%) — 标量框架已有，完整面级待补 |
| Coulomb 摩擦返回映射 | 增量形式的粘滑分支返回映射 | **缺失** — 当前仅有速度方向摩擦 |
| 一致切线刚度 | 粘结/滑动双分支精确形式 | **部分**(30%) — 仅有近似外积 |
| BVH 搜索 | SAH排序+精确距离计算 | **部分**(70-80%) |
| CSR 接触刚度装配 | 对接完整接触刚度矩阵 | **部分**(60%) |

### 命名合规

| 检查项 | 要求 |
|--------|------|
| 域缩双名 | `PH_Cont_*`(短) / `PH_Contact_*`(长) 等价，新代码优先 `PH_Cont_*` |
| TYPE 命名 | `PH_Cont_{Kind}` (Desc/State/Algo/Ctx) 或 `PH_Contact_{Kind}` |
| MODULE 命名 | `PH_Cont_{Function}` 或 `PH_Cont{Function}` |

### 测试覆盖

| 检查项 | 要求 | 当前状态 |
|--------|------|----------|
| Hertz 接触 PatchTest | 解析解对比 | **待建** |
| NTS 单对验证 | 穿透量/接触力收敛 | **待建** |
| 摩擦滑移验证 | 粘滑转换临界点精度 | **待建** |
| BVH 大规模基准 | >10K 对性能回归 | **待建** |
| e2e 闭环 | `test_contact_nts_e2e.mod` 端到端流 | **基础已建** |

---

## 十八、v2.0 Updates (2026-04-26)

**MODULE rename**: Search/PH_ContSearchAdvanced.f90 module renamed from RT_ContSearch to PH_ContSearchAdv. This fixes a duplicate MODULE name conflict with L5_RT/Contact/RT_Cont_Search.f90.

**Type AUTHORITY**: PH_Cont_Def.f90 (PH_Cont_Def) is the AUTHORITY for L4 Contact type system (deduplicated 2026-04-28, Types/ copy removed).

**Friction enum clarification**:
- PH_FRIC_* (PH_ContDomain): AUTHORITY for domain-level friction family classification
- PH_FRICT_* (PH_ContFriction): AUTHORITY for algorithm-level friction model IDs

**Domain Pillar**: P3 Contact. See UFC_DOMAIN_PILLAR_ARCHITECTURE.md section P3.

---

## 十九、变更控制

| 规则 | 说明 |
|------|------|
| 新增公开过程 | 须在§四接口清单中登记，PR 中附 CONTRACT diff |
| 新增/修改 TYPE | 须在§三 TYPE 映射表中登记 |
| 枚举值变更 | 须同步 L3/L5 CONTRACT + 本文档 §五/§六/§七 |
| 搜索算法变更 | 须同步 L5 Contract 搜索频率策略 |
| 热路径变更 | 须通过 AP-8 性能审查 |
| CONTRACT 版本 | 每次实质性变更须递增版本号并更新日期 |

---

## 二十、版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v1.0 | 早期 | 初始简版合同卡 (36行) |
| v2.0 | 2026-04-26 | 补充 MODULE rename/TYPE AUTHORITY/枚举说明/AI 插槽 |
| v3.0 | 2026-04-28 | 完整扩充: 职责边界、文件清单、四型映射、接口清单、算法矩阵、搜索方法、摩擦模型、热路径约束、L3/L5 契约、域际关系、变更控制 |
| v3.1 | 2026-04-28 | 补充算法完整度百分比标注、验收标准章节、基于 FourDomain_HotPath 报告的细分完整度矩阵 |
