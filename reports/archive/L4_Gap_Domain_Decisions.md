# L4 缺失域设计决策记录

**文档性质**：记录 UFC 六层架构中 **L4_PH 层无独立目录** 的域柱的设计决策、理由和未来扩展条件。旨在避免反复讨论和设计漂移；若有条件变化须修改此文件的决策，须走域合同变更流程。

**报告 ID**：`REP-L4-GAP-DECISIONS`。
**版本**：v1.1（2026-05-05）。v1.1 勘误：与 v1.0 目录存在性表述对齐仓库现状（见 §1.1、§2.1）。

---

## 1. P5 Output — L4 无独立域

### 1.1 决策

**Output 域在 L4 层不采用 Material 域规模的完整四型域目录**；编排与 I/O 仍在 L5。仓库现状（8 域薄柱）：存在 **薄 TYPE 层** `L4_PH/Output/`（`PH_Out_Def` / `PH_Out_Core` / `PH_Out_Brg`），承载坐标变换、张量旋转、IP→节点外推等 **物理量变换**，与 v1.0 中“数学映射在 L4 消费入口”的边界一致。历史桥位置 `L4_PH/Bridge/Output/PH_Out_Brg.f90` 保留为兼容 shim（以域根 `L4_PH/Output/` 为规范入口）。

### 1.2 理由

1. **Output 的物理量变换是纯数学操作**：坐标变换、张量旋转、积分点→节点外推是确定性的数学映射，不是独立物理域——它们不引入新物理定律/本构
2. **L5 编排已是输出调度的权威层**：`RT_Out_Mgr`（L5 金线）负责触发判定、Frame 缓冲、格式化写入；L4 只需在触发时提供变换服务的消费入口
3. **避免薄域膨胀**：若为 Output 建立独立 `L4_PH/Output/` 四型（`PH_Out_Desc/State/Algo/Ctx`），实质是将一组桥接函数包装为完整域——参考材料域 L4 的规模（72 文件），Output L4 若同样全套将过度设计

### 1.3 决策约束

| 约束 | 内容 |
|------|------|
| **L4 Bridge 职责** | 坐标变换、张量旋转、IP→节点外推（仅触发时按需调用） |
| **L4 不做** | 触发判定、缓冲管理、文件IO、格式选择（这些在 L5） |
| **L4 不持 SSOT** | Output 请求定义 SSOT 在 L3 (`MD_Out_Def`) |
| **L4 不做 ABI_Flat 引擎** | UVARM/VUVARM/URDFIL 等 ABI 由 L5 编排触发 |

### 1.4 未来可能扩展的条件

1. Output 物理量变换需要独立的状态维护（如时变张量旋转序列）
2. 需要导入新的物理量映射族（如 CFD 以外的场变换）
3. 显式动力学等高频输出场景需要 L4 级缓冲优化

若上述条件触发，新建 `L4_PH/Output/` 目录 + `PH_Out_Def.f90`(四型 AUTHORITY) + `PH_Out_Core.f90` 的代价为约 3 模块/200 行。

---

## 2. P6 WriteBack — L4 无独立域

### 2.1 决策

**WriteBack 域在 L4 层不采用完整四型“大域”目录**；L3 步内写回编排与白名单仍在 L5（WB-01—WB-03 不变）。仓库现状：存在 **薄 TYPE 层** `L4_PH/WriteBack/`（`PH_WB_Def` / `PH_WB_Core`），职责为物理量→写回 **格式准备**；历史桥 `L4_PH/Bridge/WriteBack/PH_WB_Brg.f90` 仍为桥接入口之一，与“L4 不直写 L3”的约束一致。

### 2.2 理由

1. **WB-02 硬规则：L4 禁止直写 L3**。这意味着 L4 即使建有完整四型，其核心职责（格式准备）依然只是 Bridge 级——不拥有回写编排权，不触发白名单
2. **回写编排权全部在 L5**：`RT_WBDomain` (L5 金线) 持有 AttachBuffers、WBImpl 编排、MD_WB_Brg 11域分派、审计等完整 Pipeline；L4 在 Pipeline 中仅作为格式转换的供给方
3. **避免伪双主源**：若 L4 和 L5 都持有 WriteBack 四型，容易产生"L4 负责格式准备，L5 负责编排"的模糊边界——历史经验显示这会导致步内双写（L4 与 L5 都尝试写 L3 State）

### 2.3 决策约束

| 约束 | 内容 |
|------|------|
| **WB-01** | L5→L3 是唯一合法的 L3 步内变异路径 |
| **WB-02** | L4 禁止直写 L3；所有写回须经 L5 WB_Guard |
| **WB-03** | 白名单外字段写入尝试为 FATAL 级 |
| **L4 Bridge 职责** | 物理量→序列化格式的转换、缓冲准备 |
| **L4 不做** | 文件写入、状态持久化、检查点管理（这些在 L5） |

### 2.4 未来可能扩展的条件

1. 新增写回目标格式（非序列化格式，如特定耦合接口的实时流式输出）需要 L4 级格式管线
2. L4 本身需要持有回写状态（如写回速率控制、写回优先级队列）
3. WB-02 规则放宽（需域合同变更）后允许 L4 有条件直写 L3

---

## 3. Analysis — L4 无独立域

### 3.1 决策

**Analysis 域（Step/Amplitude/Solver/Coupling）在 L4 层无独立域目录**。L4 物理核以 **消费式调用** 响应 StepDriver 信号（步/增量/迭代状态机驱动），求解器经 L5 调度 L2_NM。

### 3.2 理由

1. **三步状态机编排核心在 L5**：`RT_StepDriver` + `RT_Solv_Mgr` 拥有 Step/Inc/Iter 状态机的唯一权威；L4 不需要也**不应**持有完整状态机
2. **L4 物理核的消费式调用模式**：Element、Material、Contact 等 L4 域执行物理计算（Ke/Re、S-Pipeline、Uzawa Loop）时以被动方式响应 StepDriver 的调度信号——不需要独立编排
3. **L3/L5 边界已经足够**：L3 定义分析步配置（`MD_Step_Mgr` 28K 行真源），L5 执行编排（`RT_StepDriver` + `RT_Solv_Mgr`）；中间插入 L4 层反而增加信号传递延迟和状态复制

### 3.3 决策约束

| 约束 | 内容 |
|------|------|
| **三步状态机真源** | `RT_StepDriver_State`(L5) 唯一持有 step_status/inc_status/iter_status |
| **求解器状态真源** | `RT_Solv_NRState`(L5) 唯一持有收敛规范/迭代计数 |
| **L3 配置走 Brg 灌入** | `RT_Step_Brg` / `RT_Solv_Brg` 消费 L3 定义，不复制大数组 |
| **L4 不建 Analysis 四型** | 禁止 `PH_Step_*` / `PH_Solver_*` / `PH_Coupling_*` 独立域 |

### 3.4 未来可能扩展的条件

1. L4 物理核的自适应算法（如自适应时间步长在 L4 侧判定）需要 L4 持有独立的 Step 状态——当前该逻辑在 L5 `RT_Step_Stp_Ctl_Algo`
2. 出现需要在 L4 侧协调多个域物理核的耦合调度（如多场迭代的 L4 级子循环）
3. Amplitude 求值从 L3 迁移到 L4（当前 `Amp_GetFactor` 在 L3，性能关键路径可考虑在 L4 缓存）

---

## 4. H2 Section — L4 无独立域（方案 B：嵌入 Element）

### 4.1 决策

**Section 域在 L4 层采用方案 B（嵌入 `PH_Elem_*`），不建立独立 `L4_PH/Section/` 目录**。L3 `MD_Sect_Desc` 为唯一 SSOT，L4 侧截面参数经 `PH_L4_Populate_Element` 灌入单元缓存。

### 4.2 理由

1. **截面是 M×E×S 正交维**：不是独立贯通柱。截面的消费方主要是 Element（厚度/取向/积分规则）和 Material（`ntens`/应力态推导），建立独立 L4 域会造成与 Element/Material 的双向依赖
2. **Populate 一次性灌入足够**：`sect_id` → 厚度/取向/nlayer/integ 等派生量在 Populate 阶段确定，步内只读；L4 仅需消费这些派生量，无需独立 State 维护
3. **防双主源（R-06）**：若 L3 `MD_Sect_Desc`（SSOT）与 L4 `PH_Sect_Desc`（独立域）并存，容易导致 Populate 时序混乱——谁更新谁？

### 4.3 决策约束

| 约束 | 内容 |
|------|------|
| **方案 B 已锁定** | 截面主挂载为嵌入 `PH_Elem_*` 方案；方案 A（独立 `PH_Sect_*`）为备用 |
| **L3 唯一 SSOT** | `MD_Sect_Desc` 持有所有截面定义字段 |
| **L4 消费方式** | Populate 灌入单元缓存 + 只读 `GetThickness`/`SetSectionProps` Accessor |
| **L4 不做** | 不持第二套截面 State，不参与步内变异 |
| **方案 A 触发条件** | 跨单元型大量重复截面中间结果时，可考虑 Phase 开通 |

### 4.4 未来可能扩展的条件

1. 壳层合板需要 L4 侧做截面状态的局部演化（如逐层更新层合板积分点位置）
2. 出现跨单元型共享截面中间结果（如复合材料统一的应变换算）需要 L4 级缓存
3. 方案 A 触发——需评估独立 `PH_Sect_*` 的收益是否超过双向依赖的复杂度

---

## 5. Cross-references

- `FourKind_MasterAux_Nesting_Design_Spec.md` §5（截面 L4 主挂载决策闭合）
- `OnePager_FourKind_MasterAux_Nesting.md` R-08（截面 cross-cut 规则）
- `Section_L3L4L5_four_type_synthesis.md` §3.5（方案 B 展开）
- `Output_L3L4L5_four_type_synthesis.md` §1（半贯通柱定义）
- `WriteBack_L3L4L5_four_type_synthesis.md` §1（半贯通柱定义 + WB-02）
- `Analysis_L3L4L5_four_type_synthesis.md` §1（半贯通复合柱定义）
- `Pillar_L3L4L5_CrossLayer_Design_Template.md` §0.3（截面域四类文档 + 主挂载二选一）
