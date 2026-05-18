## Coupling 域级合同卡 (L3_MD)

- **层级**: L3_MD  
- **域名**: Coupling / 多物理场耦合  
- **缩写**: Cpl (`MD_Cpl_*`、`MD_Coup_*`)  
- **职责**: 定义**多物理场耦合对**（温度-位移、热-电等）并维护其 **SSOT (Single Source of Truth)**。  
- **非职责**: 不执行耦合求解迭代(L5 RT_MFCoordinator); 不处理运动学约束耦合(L4 Constraint域)。  

### 语义边界澄清

| 概念 | 归属域 | 关键字示例 | 
|------|--------|--------|
| **多物理场耦合** (本域) | H6 Coupling | `*COUPLED TEMPERATURE-DISPLACEMENT`, `*COUPLED THERMAL-ELECTRICAL`, etc. |
| **运动学约束耦合** | H1 Constraint | `*COUPLING`, `*KINEMATIC COUPLING`, `*DISTRIBUTING COUPLING` |

### 与 L5 关系

- L3 `MD_Cpl_Desc` 经 Populate 传入 L5 `RT_MF_Coupling_Desc` (via `RT_MF_Brg`)  
- L3 负责"配置" (pairs, strategy selection); L5 负责"执行" (iteration loop, convergence)  
- L3 持有 **原件**; L5 持有 **热拷贝** (copied for performance)  
- **修改必须回 L3**: 运行时若需修改配置 L3, 再重新 Populate 到 L5 slots  

**L5 合同见** [`L5_RT/Solver/Coupling/CONTRACT.md`](../../../L5_RT/Solver/Coupling/CONTRACT.md)。

### 四型定义

| 四型 | TYPE名 | 核心职责 |
|------|--------|----------|
| **Desc** (`MD_Cpl_Desc`) | 耦合对容器、策略选择、容差参数 | Setup 期写入冻结 |
| **State** (`MD_Cpl_State`) | 当前步ID、活跃对数、Populate标记 | 运行期更新 |
| **Algo** (`MD_Cpl_Algo`) | 松弛因子、Aitken 加速、子循环比 | 建模期设置 |
| **Ctx** (`MD_Cpl_Ctx`) | Populate/WriteBack 状态标记 | 瞬态上下文 |

### 核心接口 (按功能集)

| 功能集 | 过程 | Phase × Verb | 说明 |
|--------|------|------------|------|
| Init | `MD_Cpl_Init_Proc` | Setup × Init | 重置 Desc 到空状态 |
| Finalize | `MD_Cpl_Finalize_Proc` | Teardown × Finalize | 清理描述符资源 |
| Mutate | `MD_Cpl_AddPair_Proc` | Setup × Mutate | 注册一个新耦合通道 |
| Validate | `MD_Cpl_Validate_Proc` | Setup × Validate | 检查配对一致性 |
| Query | `MD_Cpl_GetConfig_Proc` | Query × Get | 读取耦合配置摘要 |
| Query | `MD_Cpl_GetPair_Proc` | Query × Get | 按索引查询单个耦合对 |
| Query | `MD_Cpl_GetSummary_Proc` | Query × Get | 诊断汇总（含活跃对数统计） |

### 文件清单

- `MD_Cpl_Def.f90` - 四型定义 (AUTHORITY L3 Coupling)
- `MD_Cpl_Core.f90` - 核心过程 (Init/Finalize/AddPair/Validate/GetConfig/GetPair/GetSummary)

### 依赖

- L1 `IF_Prec_Core` (wp, i4)  
- L1 `IF_Err_Brg` (ErrorStatusType, init_error_status, IF_STATUS_OK, IF_STATUS_INVALID)
- 下游: L5 `RT_MF_Brg` (Populate), L5 `RT_MFCoordinator` (耦合求解驱动)

### 状态

- Phase A (四型完整)
- 文件数: 2  
- 半柱归属: H6 Coupling (L3 + L5)

---

### SIO / `*_Arg`（本域偏好）

与本项目 Principle #14、**[`AGENTS.md`](../../../../../../AGENTS.md)** Repository rules §5 一致： L3 Coupling 域过程参数简单 (Desc + status)，**不**引入 `*_Arg`，除非 Populate Bridge 需要跨层复合参数时才引入 `MD_Cpl_Populate_Arg` 等。

---

### Partial Pillar v2.0 Update — H6 Coupling / MultiField (L3 + L5)

#### 层级分布

| 层 | 模块 | 角色 | 状态 |
|----|------|------|------|
| **L3_MD** | `MD_Cpl_Def.f90` | **AUTHORITY (L3 Coupling)** — 耦合对定义 SSOT | Phase A |
| **L3_MD** | `MD_Cpl_Core.f90` | Core procedures (Init/Finalize/AddPair/Validate/Get/Summary) | Phase A |
| L5_RT | `RT_MF_Def.f90` | AUTHORITY (L5 Coupling) — 运行时耦合四型 | ACTIVE |
| L5_RT | `RT_MF_Coordinator.f90` | GOLDEN-LINE — 耦合求解迭代驱动 | PLACEHOLDER |
| L5_RT | `RT_MF_Brg.f90` | Bridge — L3→L5 Populate 通道 | PLACEHOLDER |

#### L4 缺席说明

耦合是"编排"概念，L4 各域（Material/Element/Field）通过各自的贡献参与耦合计算，不需要独立的 L4 Coupling 目录。

#### L3→L5 Populate 通道

```
MD_Cpl_Desc (L3 SSOT)
  → RT_MF_Brg_Populate (Bridge)
  → RT_MF_Coupling_Desc (L5 hot copy)
```

L3 到 L5 的字段映射:

| L3 字段 | L5 字段 | 说明 |
|---------|---------|------|
| `MD_Cpl_Desc.strategy` | `RT_MF_Coupling_Desc.global_strategy` | 策略选择 |
| `MD_Cpl_Desc.pairs(i)` | `RT_MF_Coupling_Desc.pairs(i)` | 深拷贝 (Populate 时) |
| `MD_Cpl_Desc.max_coupling_iter` | `RT_MF_Coupling_Algo.max_coup_iter` | 最大耦合迭代 |
| `MD_Cpl_Desc.coupling_tol` | `RT_MF_Coupling_Algo.eps_coup_rel` | 收敛容差 |
| `MD_Cpl_Desc.interp_method` | `RT_MF_Coupling_Algo.interp_method` | 插值方法 |

#### L5→L3 WriteBack

当前不需要 WriteBack 通道。耦合运行时状态仅需在 Output/WriteBack 域通用通道中按需回写。

---

### 错误处理

| 错误场景 | 错误码 | 处理方式 |
|----------|--------|----------|
| 耦合对数量超限 | `IF_STATUS_INVALID` | AddPair 拒绝 |
| 无效场 ID (≤0) | `IF_STATUS_INVALID` | AddPair/Validate 拒绝 |
| 自耦合 (src==dst) | `IF_STATUS_INVALID` | AddPair/Validate 拒绝 |
| pair_idx 越界 | `IF_STATUS_INVALID` | GetPair 返回 status |

所有公开过程通过 `ErrorStatusType` 返回状态。不使用 `STOP`。

---

### 细粒度子程序清单

| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |
|------|--------|---------------|------------|
| `MD_Cpl_Def.f90` | `MD_Cpl_Def` | `MD_Coup_PairDef`, `MD_Cpl_Desc`, `MD_Cpl_State`, `MD_Cpl_Algo`, `MD_Cpl_Ctx` | — |
| `MD_Cpl_Core.f90` | `MD_Cpl_Core` | — | `MD_Cpl_Init_Proc` (SUB,PUB,Init); `MD_Cpl_Finalize_Proc` (SUB,PUB,Finalize); `MD_Cpl_AddPair_Proc` (SUB,PUB,Mutate); `MD_Cpl_Validate_Proc` (SUB,PUB,Validate); `MD_Cpl_GetConfig_Proc` (SUB,PUB,Get); `MD_Cpl_GetPair_Proc` (SUB,PUB,Get); `MD_Cpl_GetSummary_Proc` (SUB,PUB,Get) |

---

### 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|----------|
| v2.1 | 2026-05-08 | 核心过程重命名为 **`MD_Cpl_*_Proc`**，与 **`MD_Cpl_*`** TYPE 同柱前缀 |
| v2.0 | 2026-04-26 | 重写合同卡（修复编码损坏）；补充 Finalize/GetPair/GetSummary；ErrorStatusType 规范化 |
| v1.0 | 2026-04-26 | 初始版本（编码损坏） |
