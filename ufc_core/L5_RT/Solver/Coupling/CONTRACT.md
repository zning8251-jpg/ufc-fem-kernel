## Coupling 域级合同卡 (L5_RT)

- **层级**: L5_RT  
- **域名**: Coupling / 多物理场耦合（运行时）  
- **缩写**: MF（`RT_MF_*`、`RT_MFCoordinator` 等）  
- **职责**: 在 **热路径** 上执行 **多场耦合迭代**（单向 / 交错 / 分区迭代 / 单体等策略），驱动场间数据交换与收敛判据；消费 L3 经 Bridge 下发的耦合配置。  
- **非职责**: 不定义耦合对 SSOT（L3 `MD_Cpl_*`）；不替代 L4 单场本构/单元核；不处理运动学约束耦合（H1 Constraint）。  

### 与 L3 / L4 的边界

- L3 `MD_Cpl_Def` / `MD_Cpl_Desc`：**建模期 SSOT**；经 **`RT_MF_Brg_Populate`** 写入 L5 `RT_MF_Def` 四型。  
- L3 `MD_Field_*` 等：场侧 **Desc** 经各自 Bridge 与 L5 装配；**不**在本合同重复 Field 全量清单。  
- L4 `PH_Thermal_*` / `PH_Mech_*` / `PH_Acoustic_*` 等：提供 **单场贡献 / 耦合项核**；由 **`RT_MF_Coordinator`** 调度调用（非本目录再包一层「总 Field 过程」）。  
- **配置回写原则**：运行期若需改耦合 **配置**，应 **回写 L3 SSOT** 后 **再 Populate** 到 L5 slot，避免 L5 孤改与 L3 漂移。  

### L5 四型（本半柱）

- **Desc**：`RT_MF_Coupling_Desc` 等 — 运行时 **不可变配置视图**（由 L3 Populate 得到）。  
- **State**：`RT_MF_Coupling_State` — 子循环索引、残差、活跃对等 **热状态**。  
- **Ctx**：分配/释放、交换缓冲绑定等 **瞬态上下文**。  
- **Algo**：松弛、Aitken、子循环上限、插值策略等 **算法参数**（与 L3 `MD_Cpl_Algo` 映射见 Bridge 设计）。  

### 运行时三件套

| 组件 | 模块 / 文件 | 说明 |
|------|----------------|------|
| Coordinator | `RT_MF_Coordinator` | 耦合 **主循环**；策略分支与场序编排。 |
| Types | `RT_MF_Def` | L5 耦合 **四型 AUTHORITY**。 |
| Bridge | `RT_MF_Brg` | **L3 → L5 Populate**；可选 **状态同步** 查询。 |

### 依赖与消费方

- **上游**: L1 `IF_*`；L3 `MD_Cpl_Def` / `MD_Cpl_Core`（`MD_Cpl_*_Proc`）；L4 `PH_Thermal_*` / `PH_Mech_*` / `PH_Acoustic_*`（按具体模型装配）。  
- **协同**: StepDriver（如 `RT_STEPDRV_SEQ_COUPLED` 触发耦合路径）；Output（耦合诊断输出）。  
- **原则**: L5 **执行** 与 L3 **真源** 分离；持久配置变更 **以 L3 为准**。  

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../AGENTS.md)** Repository rules 第 5 节一致：L5 耦合 **Golden-line** 与 **高频子过程** 以 **`status`** / 显式参数为主；**跨域复合 IO** 通过约定的 `*_Arg` / `Apply_*`（及 Harness）渐进引入，**不**用「无契约裸指针」替代结构化边界。新增 **`RT_MF_*_Proc`** 时须满足 SIO 检查清单（与仓库 Harness 对齐）。

*说明：具体 `*_Arg` 形态以各 `_Proc.f90` 与 Bridge 合同为准，本卡只定原则。*

### 文件清单

- `RT_MF_Def.f90` — 四型与耦合数据结构（**AUTHORITY · L5 Coupling**）  
- `RT_MF_Coordinator.f90` — 耦合迭代 **GOLDEN-LINE**（当前可为 PLACEHOLDER）  
- `RT_MF_Brg.f90` — L3→L5 **Populate Bridge**（ACTIVE / PLACEHOLDER 以源码标注为准）  

### 状态

- **Phase**: 与源码 `STATUS` 注释一致（多为 **ACTIVE / PLACEHOLDER** 混合演进）  
- **本目录核心文件数**: 3  
- **半柱归属**: H6 Coupling（**L3 + L5**）  

---

### 细粒度子程序清单（纲要）

| 文件 | MODULE | TYPE（PUBLIC 节选） | 过程 / TBP（纲要） |
|------|--------|----------------------|---------------------|
| `RT_MF_Coordinator.f90` | `RT_MF_Coordinator` | — | `RT_MF_Coordinator_Init` (SUB,PRV,Init)；`RT_MF_Coordinator_Run` (SUB,PRV,…)；`RT_MF_Coordinator_Finalize` (SUB,PRV,Finalize)；`RT_MF_Oneway_Loop` / `Staggered` / `PartIter` / `Monolithic`；`RT_MF_Solve_SingleField`；`RT_MF_Exchange_Interface`；`RT_MF_ConvCheck_Coupling`；`RT_MF_Aitken_Accelerate`；`compute_L2_norm_pair`；`i4toa` 等 |
| `RT_MF_Def.f90` | `RT_MF_Def` | `RT_MF_FieldPair_Desc`, `RT_MF_InterfaceBuf`, `RT_MF_Coupling_Desc`, `RT_MF_Coupling_State`, `RT_MF_Coupling_Algo`, `RT_MF_Coupling_Ctx`, … | `Init` / `Reset` (TBP)；`MF_State_Init` / `MF_State_Reset`；`MF_Algo_Init`；`MF_Ctx_Alloc` / `MF_Ctx_Dealloc` 等 |
| `RT_MF_Brg.f90` | `RT_MF_Brg` | — | `RT_MF_Brg_Populate` (SUB,PUB,Populate)；`RT_MF_Brg_SyncState` (SUB,PUB,Query) |

---

### Partial Pillar v2.0 Update — H6 Coupling / MultiField（L3 + L5）

**定位**: 本文档与 **Partial Pillar H6**（多场耦合 / MultiField）对齐，为 L5 侧 **权威索引**。

#### 层级分布

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| **L3_MD** | `MD_Cpl_Def.f90` | **AUTHORITY (L3 Coupling)** — 耦合对定义 SSOT | Phase A |
| **L3_MD** | `MD_Cpl_Core.f90` | **Core** — `MD_Cpl_*_Proc`（Init / Finalize / AddPair / Validate / Get*） | Phase A |
| **L5_RT** | `RT_MF_Def.f90` | **AUTHORITY (L5 Coupling)** — 运行时耦合四型 | ACTIVE |
| **L5_RT** | `RT_MF_Coordinator.f90` | **GOLDEN-LINE** — 耦合求解迭代驱动 | PLACEHOLDER |
| **L5_RT** | `RT_MF_Brg.f90` | **Bridge** — L3→L5 Populate | PLACEHOLDER |

#### L4 Field / Material 消费方式

L5 Coupling 直接消费 L4 侧 **贡献模块**（如 `PH_Field_Cpl`、`PH_Mat_Cpl` 等）。Field 域若仅暴露 **贡献核** 而无单一编排边界，**不需要** 为此单独新增 `PH_Field_Proc.f90` 式总壳；编排由 **`RT_MF_Coordinator`** 承担。

#### 语义边界（与 H1 区分）

| 概念 | 归属 | 关键字示例 |
|------|------|------------|
| **多物理场耦合**（本半柱） | **H6 Coupling** | `*COUPLED TEMPERATURE-DISPLACEMENT`, `*COUPLED THERMAL-ELECTRICAL` |
| **运动学约束耦合** | H1 Constraint | `*COUPLING`, `*KINEMATIC COUPLING` |

#### 数据流（示意）

```
Keyword / 建模管线
  → MD_Cpl_Init_Proc / MD_Cpl_AddPair_Proc 等 → MD_Cpl_Desc（L3 SSOT）
  → RT_MF_Brg_Populate → RT_MF_Coupling_Desc（L5 热拷贝）
  → RT_MFCoordinator_Run（L5 耦合驱动）
  → L4 单场求解核（PH_Thermal / PH_Mech / …）
  → RT_MF_Exchange_Interface（界面量交换）
  → RT_MF_ConvCheck_Coupling（收敛判据）
```

#### StepDriver 集成要点

- `RT_STEPDRV_SEQ_COUPLED` 等枚举路径应能 **挂接** `RT_MFCoordinator_Run`（或等价入口）。  
- `RT_MF_Brg_Populate`：分析步切换或 L3 变更后 **刷新** L5 槽位。  
- `RT_MF_Brg_SyncState`：需要时从 L5 **回读** 部分状态供诊断或其它 RT 域消费（非 L3 真源回写）。  

#### 目录说明

L5 Coupling 代码位于 **`L5_RT/Solver/Coupling/`**（历史布局：与 **Solver** 子树并列，**不**表示耦合逻辑属于「方程求解器 Def」子域）。与 Assembly、StepDriver、Output 等通过 **接口与调度表** 协作，而非目录父子关系。

---

### 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v2.1 | 2026-05-08 | 全文重写为 UTF-8 中文；对齐 L3 `MD_Cpl_*` / `MD_Cpl_*_Proc` 与 `RT_MF_*` 文件名 |
| v2.0 | 2026-04-26 | Partial Pillar v2.0 纲要（原文曾编码损坏） |
