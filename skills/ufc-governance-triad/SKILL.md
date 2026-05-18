---
name: ufc-governance-triad
description: "UFC 工程治理三件套编排技能：规格环（plan/changes 变更包四制品）、流程环（ufc_governance/triad/flow PLAYBOOK + plan/tasks TASK_RUN）、纪律环（triad/discipline/manifest.v1.json + Harness/CI）。在用户提到三件套、OpenSpec 等价、变更包、铁三角、What/How/Quality、change-package、discipline verify、ufc_governance、迁移双轨时触发。"
---

# UFC 工程治理三件套（Triad）

## 何时使用

| 场景 | 触发词 |
|------|--------|
| 新开功能或大改 | 变更包、proposal、spec Scenario、先对齐再写码 |
| 流程约束 | Superpowers 等价、playbook、TASK_RUN、子任务.harness |
| 质量门禁 | discipline、manifest、guardian、naming、closure |
| 迁移与真源 | ufc_governance/library、flip、INVENTORY |

---

## 第一步：读入口（不可跳过）

1. [`ufc_governance/README.md`](../ufc_governance/README.md)
2. [`ufc_governance/triad/CROSSWALK.md`](../ufc_governance/triad/CROSSWALK.md)
3. [`ufc_governance/triad/spec/POLICY.md`](../ufc_governance/triad/spec/POLICY.md)（变更包**唯一**路径约定）

---

## 第二步：规格环（What）

- **Canonical 路径**：`UFC/plan/changes/<change_id>/`
- 四制品：`proposal.md`、`design.md`、`tasks.md`、`specs/<capability>/spec.md`
- 模板：[`ufc_governance/triad/spec/templates/change_package/`](../ufc_governance/triad/spec/templates/change_package/README.md)
- 金样：[`plan/changes/example-ufc-triad/`](../plan/changes/example-ufc-triad)
- 校验：

```text
python UFC/ufc_harness/run_harness.py change-package validate --change-id <change_id>
```

默认 **warn-only**（有缺失仍退出 0）；合入前建议加 **`--strict`**。

---

## 第三步：流程环（How）

- Playbook：[`ufc_governance/triad/flow/PLAYBOOK_FEATURE.md`](../ufc_governance/triad/flow/PLAYBOOK_FEATURE.md)
- **L3/L4/L5 二元结构 + 三维度滚动**：[`PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md`](../ufc_governance/triad/flow/PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md)
- Skill 路由：[`ufc_governance/triad/flow/SKILL_ROUTING.md`](../ufc_governance/triad/flow/SKILL_ROUTING.md)
- 长任务卡：`python UFC/ufc_harness/run_harness.py agent-task init --session <id> --goal "..."`  
  建议在 `TASK_RUN` front matter 增加 `governance_change_id: "<change_id>"`（与变更包目录名一致）。

---

## 第四步：纪律环（Quality）

- Manifest：[`ufc_governance/triad/discipline/manifest.v1.json`](../ufc_governance/triad/discipline/manifest.v1.json)
- 提示义务（无路径 = 打印全表）：

```text
python UFC/ufc_harness/run_harness.py discipline verify
python UFC/ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L5_RT/Example.f90
```

改 `ufc_core/**/*.f90` 后：**至少** `guardian … --fail-on-p0` 与 `naming`（与 manifest 一致）。

---

## 与 CONTRACT / docs 真源

- **`ufc_core/**/CONTRACT.md`** 优先：变更包不得与其冲突。
- **双轨期**：`docs/` 仍为默认真源；大段叙事迁移须登记 [`ufc_governance/migration/INVENTORY.csv`](../ufc_governance/migration/INVENTORY.csv)。

---

## 刻意降级

小改动若跳过某环，须在 `design.md` Open Questions 或 `TASK_RUN` Log **显式记录原因**。
