# UFC 域柱推进路线图（贯通 → 半贯通 → 层专属）

> **更新**：2026-05-19  
> **真源**：[`UFC_DOMAIN_PILLAR_ARCHITECTURE.md`](../../docs/05_Project_Planning/PPLAN/06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md) · [`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)  
> **编排**：[`L3L4L5_MASTER_PLAN.md`](L3L4L5_MASTER_PLAN.md)

---

## 1. 三层推进顺序（总原则）

```text
① 六大贯通域柱 P1–P6   （每柱 L3→L4→L5 金线，S1–S7，一柱一叙事）
        ↓
② 半贯通域柱 H*        （Constraint / Field / Assembly / Step / Solver / …）
        ↓
③ 层专属 S*            （Bridge / Mesh / KeyWord … — 随柱嵌入，不单开全库横切）
```

**硬约束**（工作流 v1.0）：禁止无独立 PR 叙事下 **并行改 >1 条贯通柱**。

**与 Material 专项关系**：

- **P1 贯通柱**：post-wave5 主链（#7–#13）≈ **S4–S5 大段已交付**；柱级 S7 需 **W2 + NAME 收尾** 后再标「P1 全绿」。
- **W2 / NAME**：属于 **P1 柱内尾巴**，**不**构成第 7 根贯通柱；**不阻塞**启动 **P2 合同波次（S1–S3）** 的 **计划** 工作，但 **阻塞** 宣称 P1 柱 S7 完成。

---

## 2. 阶段 A — 六大贯通域柱（P1–P6）

每柱重复：**S1 合同 → S2 快照 → S3 change 包 → S4 L3 → S5 L4 → S6 L5 → S7 G1–G6 + 归档**。

| 柱 | 名称 | L3 ↔ L4 ↔ L5 | 当前状态（2026-05-19） | 下一 change_id / 动作 |
|----|------|----------------|------------------------|------------------------|
| **P1** | Material | `L3_MD/Material` ↔ `L4_PH/Material` ↔ `L5_RT/Material` | wave3–5 + post-wave5 **COMPLETE**；W1b Schmid #13 | **W2** [`p1-material-crystal-w2-multislip`](../changes/p1-material-crystal-w2-multislip/) → **NAME** [`p1-material-plast-name-debt`](../changes/p1-material-plast-name-debt/) → P1 S7 复核 |
| **P2** | Element | `L3_MD/Elem` ↔ `L4_PH/Element` ↔ `L5_RT/Element` | 待柱级金线 | `contract-l4-element`（S1–S3）→ 实现波次 |
| **P3** | Contact | `Interaction` ↔ `Contact` ↔ `Contact` | 待柱级金线 | 新 change；依赖 P2 Step3 接缝（见 MASTER §6） |
| **P4** | LoadBC | `Boundary` ↔ `LoadBC` ↔ `LoadBC` | 待柱级金线 | 新 change |
| **P5** | Output | `Output` ↔ `Bridge/Output` ↔ `Output` | 待柱级金线 | 闭环 Output 合同（Phase C） |
| **P6** | WriteBack | `WriteBack` ↔ `Bridge/WriteBack` ↔ `WriteBack` | 待柱级金线 | 依赖 P5；Populate/WB 金线 |

### 2.1 P1 柱内执行顺序（Material 专项）

```text
W2 算例锁定 → W2a 实现 PR（N=2 滑移 + 潜硬化）
     ∥（可并行计划/小步）
NAME 清债 PR-A/B/C（guardian Plast P2=17 → 0）
     ↓
P1 S7：G1–G6 表 + `07` Material 行 + 归档 W2/NAME tasks
```

| 顺序 | 包 | 类型 |
|------|-----|------|
| 1 | `p1-material-crystal-w2-multislip` | 实现（有晶体需求时优先） |
| 2 | `p1-material-plast-name-debt` | 质量（可与 W2 **计划**并行，**合并**错开） |
| — | post-wave5 已归档 | #7–#13、plan 在 `main` |

### 2.2 贯通柱推荐开工顺序（跨柱）

在 **不并行改多柱代码** 前提下，**计划/合同**可提前，**实现**建议：

```text
P1 收尾（W2 + NAME）→ P2 Element → P4 LoadBC → P3 Contact → P5 Output → P6 WriteBack
```

说明：

- **P2** 与闭环 **Ke / Loc Eval** 直接相关，宜早。
- **P4** 常与 P2 测试矩阵交织，可在 P2 第一 MR 后启动。
- **P3** 依赖接触–单元接缝，宜在 P2 有绿路径后。
- **P5→P6** 贴近步末 **Output / WriteBack**，放后。

---

## 3. 阶段 B — 半贯通域柱（H*）

> 真源表：[`UFC_DOMAIN_PILLAR_ARCHITECTURE.md` §2.3](../../docs/05_Project_Planning/PPLAN/06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md)

| 柱 | 名称 | 层 | 建议顺序 | 备注 |
|----|------|-----|----------|------|
| H3 | Assembly | L3 + L5 | B1 | 闭环 **C2**；与 P2/P6 接缝 |
| H4a | Step | L3 + L5 | B2 | 闭环 **C1**；六参 / Iter |
| H4b | Solver | L3 + L5 | B3 | 闭环 **C5** |
| H1 | Constraint | L3 + L4 | B4 | |
| H2 | Field | L3 + L4 | B5 | |
| H6 | Coupling | L3 + L5 | B6 | 无 L4 独立目录 |
| H7 | DiffPhys | L2 + L4 | B7 | 可 deferred |
| H4c | Amplitude | L3 only | B8 | 经因子消费 |

**半柱规则**：每层 **合同 PR 先于** 大规模实现；可与贯通柱 **交错**，但 change_id **独立**。

---

## 4. 阶段 C — 层专属（S* / 基础设施）

**不**做「先改完整个 L3 再 L4」式横切；层专属项 **随贯通/半贯通柱嵌入**：

| 类别 | 示例 | 嵌入时机 |
|------|------|----------|
| Bridge | `BRIDGE_INDEX`, Populate, WB | P1/P6 柱 S4–S6 |
| Mesh / KeyWord | 解析与模型数据 | P2 / P4 柱 |
| IF / NM 公共 | L1/L2 | 按需，不挡柱 S7 |

---

## 5. 与 Phase A–E（MASTER_PLAN）对齐

| MASTER 阶段 | 本路线图 |
|-------------|----------|
| Phase C 合同波次 | 贯通柱 **S1** + 半柱 H3/H4a/H4b 合同（可与 P1 收尾并行 **计划**） |
| Phase D 首柱实现 | P1 已实现；**P2** 为下一实现柱 |
| Phase E 扩面 | P3–P6 按 §2.2 顺序 |

---

## 6. 近期可执行清单（建议）

| 周/迭代 | 贯通/半贯通 | 动作 |
|---------|-------------|------|
| **当前** | P1 | 锁 W2 双滑移算例 → W2 PR；穿插 NAME PR-A（J2） |
| **+1** | P1 | NAME B/C；P1 S7 勾 `07` Material 行 |
| **+1** | P2 | `contract-l4-element` + TASK_RUN（仅 S1–S3 亦可） |
| **+2** | H4a / H3 | StepDriver / Assembly **合同** PR（Phase C） |
| **+2** | P2 | Element 第一实现 MR（S4 脊索） |

---

## 7. 相关链接

- Material backlog：[`p1-material-post-wave5-backlog.md`](../backlog/p1-material-post-wave5-backlog.md)  
- 域切换摘要：[`p1-domain-next-options.md`](../backlog/p1-domain-next-options.md)  
- 形式对齐检查表：[`UFC_L345_形式对齐域级检查表_P1-P6.md`](../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md)
