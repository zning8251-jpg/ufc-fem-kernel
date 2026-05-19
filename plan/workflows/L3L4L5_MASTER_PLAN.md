# L3/L4/L5 域柱改造 — 总计划（运行编排 v1.0）

> **路径**：`UFC/plan/workflows/L3L4L5_MASTER_PLAN.md`  
> **规范真源**：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)  
> **更新**：2026-05-19  
> **状态**：ACTIVE — 按分项推进；完成一项在 [`../tasks/l3l4l5-workflow-rollout/TASK_RUN.md`](../tasks/l3l4l5-workflow-rollout/TASK_RUN.md) 勾选。

---

## 1. 计划总览（前因 → 后果 → 交付）

| 阶段 | 前因（为何现在做） | 本阶段动作 | 后果（完成后世界变化） | 交付物 |
|------|-------------------|------------|------------------------|--------|
| **Phase A** | 工作流仅存在于对话，无法复用 | 文档+模板+技能落盘 | 任何人/Agent 可按同一路径开工 | 本文档体系 + SKILL |
| **Phase B** | W0 基线不完整则 W1 噪声大 | 命名/Bridge/Registry 基线 | 后续 diff 可信 | W0 检查表 ☑ |
| **Phase C** | 闭环链合同不齐则改代码无验收 | 波次0：StepDriver/Asm/Elem/Mat/Solver 合同 | Phase4 表可逐格勾 | `07` 闭环域行 |
| **Phase D** | Populate 未收敛则热路径双真源 | 波次1：P1 或 P2 金线代码+合同 | 首柱 G1–G6 全绿 | 首柱 PR 系列 + change 包 |
| **Phase E** | 单柱成功不可复制 | 波次2：其余 P3–P6 + H1 | M-L345 可勾 | 多 `change_id` 滚动 |

---

## 2. 分项计划（Phase A — 工作流基础设施）

**目标**：固化「七步工序 + 交接 + 验收 + 防偏离」，不改动 `ufc_core` 生产逻辑。

| ID | 任务 | 依赖 | 验收标准 | 状态 |
|----|------|------|----------|------|
| A1 | 发布规范 [`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md) | — | PPLAN README 有入口；含 §6–§7 | ☑ |
| A2 | 本 MASTER_PLAN + `plan/workflows/README` | A1 | 链到规范与模板 | ☑ |
| A3 | 模板三件套 `templates/*` | A1 | 可复制、字段齐全 | ☑ |
| A4 | 充实 `skills/ufc-layer-workflow/SKILL.md` | A1–A3 | `openskills read` 可执行七步 | ☑ |
| A5 | PPLAN / 导航真源 / 主轴路线图 互链 | A1 | 六份真源含工作流 | ☑ |
| A6 | `AGENTS.md` 技能表 + 速查行 | A4 | 触发词「域柱改造工作流」 | ☑ |
| A7 | 母任务 `tasks/l3l4l5-workflow-rollout/TASK_RUN.md` | A2 | Phase A 子任务全 done | ☑ |

**Phase A 总闸**：A1–A7 全 ☑ 后，才在 Phase B 启动 W0 批量门禁。

**当前进行（2026-05-19）**：

| 任务 | 路径 | 状态 |
|------|------|------|
| **域柱路线图** | [`PILLAR_ROLLOUT_ROADMAP.md`](PILLAR_ROLLOUT_ROADMAP.md) | **ACTIVE** — P1–P6 → H* → 层专属 |
| P1 post-wave5 | [`backlog/p1-material-post-wave5-backlog.md`](../backlog/p1-material-post-wave5-backlog.md) | **COMPLETE**；尾巴 W2 + NAME |
| P1 W2 / NAME 草案 | [`changes/p1-material-crystal-w2-multislip/`](../changes/p1-material-crystal-w2-multislip/) · [`p1-material-plast-name-debt/`](../changes/p1-material-plast-name-debt/) | plan DRAFT |
| 差距快照 | [`P1_MATERIAL_GAP_SNAPSHOT.md`](P1_MATERIAL_GAP_SNAPSHOT.md) | Material 波次台账已更新 |

---

## 3. 分项计划（Phase B — W0 基线）

**前因**：无命名/Bridge 基线 → Guardian 全红无法归因。  
**后果**：W1 材料柱 MR 可对比 `REPORTS/W0_*` 增量。

| ID | 任务 | 命令/工件 | 验收 |
|----|------|-----------|------|
| B1 | W0.1 命名基线三桶 | `naming_checker` → `REPORTS/W0_naming_baseline_*` | [`L3_L4_L5_W0_出口检查表.md`](../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_W0_出口检查表.md) 对应行 ☑ |
| B2 | W0.3 Bridge 索引 | 更新 `ufc_core/L3_MD/Bridge/BRIDGE_INDEX.md` | 与 CONTRACT 无矛盾 |
| B3 | Registry 全量扫描 | `python UFC/tools/domain_procedure_registry_scan.py` | `generated/_REGISTRY_STATS.md` 时间戳新 |
| B4 | 差距总表（可选） | `plan/tasks/w0-baseline-gap/TASK_RUN.md` | P1 三层 stem 差距 Top20 已列 |

**交接**：B 完成 → 指派 **P1 Material** 或 **P2 Element** 首柱负责人；复制 [`templates/TASK_RUN_L3L4L5.md`](templates/TASK_RUN_L3L4L5.md)。

---

## 4. 分项计划（Phase C — 波次 0：闭环链合同）

**前因**：Phase4 核心链已通，但合同 A+ 不齐 → 改造无「完成」定义。  
**后果**：[`07_L3L4L5_二元结构合同完备里程碑.md`](../docs/05_Project_Planning/PPLAN/11_闭环落地专项/07_L3L4L5_二元结构合同完备里程碑.md) 闭环域行可勾。

**顺序**（与 Phase4 表一致，禁止并行改合同+大规模代码同 PR）：

| 序 | 域路径 | change_id 建议 | S1–S3 重点 | S7 验收 |
|----|--------|----------------|------------|---------|
| C1 | `L5_RT/StepDriver` | `contract-l5-stepdriver` | 六参/Iter 三轴表 | G1–G6 + A4/A+ |
| C2 | `L5_RT/Assembly` | `contract-l5-assembly` | Glb Asm 动作维 | 同上 |
| C3 | `L4_PH/Element` | `contract-l4-element` | Loc Eval 与 Ke | 同上 |
| C4 | `L4_PH/Material` | （已有 v1.1 可审计） | 四型裁剪已部分完成 | 复核 G 表 |
| C5 | `L5_RT/Solver` + L2 引用 | `contract-l5-solver` | A9 N/A 或六参 | 同上 |

每个域：**单独** `plan/changes/<id>/` + `plan/tasks/<id>/`；合同 PR **优先于** 实现 PR。

---

## 5. 分项计划（Phase D — 波次 1：首柱金线）

**前因**：需要一条可复制的 **L3→L4→L5** 样板，证明二元结构可落地。  
**后果**：第二柱（P2 或继续 P1 下一族）可复制 TASK_RUN 模板。

### 5.1 首柱选择决策

| 若缺口是… | 选柱 | 理由 |
|-----------|------|------|
| 材料 Populate/UMAT | **P1** | 已有 pilot、change 样板 |
| 单元 Ke/装配接缝 | **P2** | 与 PR01 金线一致 |

### 5.2 P1 Material 任务分解（示例，可拆 MR）

| MR | Step | 范围（脊索） | Harness 窄路径 |
|----|------|--------------|----------------|
| D-MR-01 | S4 | `MD_Mat_Def`, `MD_Mat_Mgr`, `MD_Mat_Lib` | `L3_MD/Material` |
| D-MR-02 | S4–S5 | `MD_MatLibPH_Brg`, `PH_L4_Populate`, `PH_L4_L3MatContract` | L3 Bridge + L4 |
| D-MR-03 | S5 | `PH_Mat_Def`, `PH_Mat_Dsp`, Dispatch 入口 | `L4_PH/Material` |
| D-MR-04 | S5 | 一族 `*_Core`（如 Plast 或 Elas） | 子目录 |
| D-MR-05 | S6 | `L5_RT/Material/*_Proc` | `L5_RT/Material` |
| D-MR-06 | S7 | G1–G6 + `07` L3/L4/L5 Material 行 | closure |

**已有 change 可续跑**：`rollout-l4-material-binary-trivium`、`intf001-mat-plast-spcl-arg` — **勿** 新建重复 id。

### 5.3 逐步交接（每 MR 必做）

使用 [`templates/HANDOFF_MATRIX.md`](templates/HANDOFF_MATRIX.md)：

1. **Outgoing**：完成 Step 填写证据路径 + Harness rc=0  
2. **Incoming**：下一人读 References + 差距表 + 仅改 TASK_RUN 中 `in_progress` 子任务  
3. **Blocked**：必须写 `blocked_by` + 合同/蓝图条款号  

---

## 6. 分项计划（Phase E — 波次 2：扩面）

**前因**：首柱证明工序有效。  
**后果**：`M-L345` 总闸可勾。

| 柱 | 前置 | 建议顺序 |
|----|------|----------|
| P2 Element | P1 S7 绿 或 团队显式并行授权 | W2 |
| P3 Contact | P2 Step3 绿 | W3 |
| P4 LoadBC | P2/P3 视产品 | W4 |
| P5 Output | 闭环链 Output 合同 | W5 |
| P6 WriteBack | P5 | W6 |
| H1 Step/Solver | P1+P2 | W7 半柱 |

**每个柱**：新 `change_id`；复制 Phase D 的 MR 表结构。

---

## 7. 验收标准总表（防混淆）

| 代号 | 何时检查 | 谁勾选 | 真源 |
|------|----------|--------|------|
| **G1–G6** | 每 MR 结束 | 作者 | 形式对齐检查表 + PR 附件 |
| **A4/A+** | 合同 PR / S7 | Reviewer | `06` + 域 CONTRACT |
| **M-域** | 单域 S7 | Maintainer | `07` 行 |
| **M-L345** | Phase E 末 | 架构负责人 | `07` §2 |
| **C1–C4** | 发布前 | QA | Phase4 表 |
| **Guardian P0** | 每 touched 批 | CI/作者 | Harness |

**禁止**：用「命名扫描全绿」替代「本柱 G1–G6 绿」。

---

## 8. 偏离控制速查

| 偏离征象 | 处置 |
|----------|------|
| PR 出现第二域柱路径 | 拆 PR；复用 HANDOFF 回 S3 |
| 合同与代码不一致 | 先 CONTRACT PR（S1），再实现 |
| TASK_RUN 多步 in_progress | 只允许一个；其余 pending |
| 扩 scope 无新 change_id | `change-package validate` 失败则停 |
| 叙事稿与 CONTRACT 冲突 | Registry README 优先级；改叙事不改合同 |

---

## 9. 与母任务同步

进度以 [`../tasks/l3l4l5-workflow-rollout/TASK_RUN.md`](../tasks/l3l4l5-workflow-rollout/TASK_RUN.md) 为准；本文件版本变更时 bump 母任务 Log。

*维护：Phase 定义变更须同步规范文档 §4–§7。*
