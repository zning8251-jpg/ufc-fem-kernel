# `triad/` — 规格环 · 流程环 · 纪律环

| 环 | 目录 | 外源类比 | UFC 一句话 |
|----|------|-----------|-------------|
| 规格 | [`spec/`](spec/POLICY.md) | OpenSpec | **What**：变更包四制品对齐后再动 `ufc_core`。 |
| 流程 | [`flow/`](flow/PLAYBOOK_FEATURE.md) | Superpowers | **How**：澄清 → 隔离 → 计划 → 实现 → 测试与审查 → 收尾。 |
| 纪律 | [`discipline/`](discipline/README.md) | Agent Skills + CI | **Quality**：manifest 列 harness；不可绕过项进 CI。 |

- 外源命令/技能/生命周期与 UFC 的逐项对照：[`CROSSWALK.md`](CROSSWALK.md)。
- 金样变更包（可复制）：[`plan/changes/example-ufc-triad/`](../plan/changes/example-ufc-triad)。

## 主导方与产出物（组合原则 2.2）

| 层次 | 谁主导 | 产出物 |
|------|--------|--------|
| 需求/规格 | 人审 + AI 起草 | `plan/changes/<id>/` 下 `proposal.md`、`specs/**/spec.md`、`design.md`、`tasks.md` |
| 流程 | AI 按 playbook + `TASK_RUN.md` | 子任务表、harness 执行记录、`REPORTS/` |
| 纪律 | AI 遵从 + Harness/CI | `manifest.v1.json` 所列命令的非零退出即阻断（`--strict` 模式） |
