# Feature 交付 Playbook（Flow 环）

UFC 特化流程；外源七步对照见 `[../CROSSWALK.md](../CROSSWALK.md)`。

## 0. 入口

- 读 `ufc_governance/README.md`、`triad/CROSSWALK.md`。
- **L3/L4/L5「二元结构 + 三维度」滚动改造**：见同目录 [`PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md`](PLAYBOOK_L3L5_BINARY_TRIVIUM_ROLLOUT.md)（skills 顺序、Harness 批次、roll-forward）。
- 新建 `plan/changes/<change_id>/`（从金样复制）。

## 1. 澄清（brainstorming）

- 对模糊需求做 Socratic 反问；澄清轮次上限建议 **3**（可在 `TASK_RUN` 记录）。
- 未决项写入 `design.md` → Open Questions。

## 2. 隔离（using-git-worktrees）

- 新分支或 `git worktree`；baseline：`guardian` / 构建按团队约定。

## 3. 细计划（writing-plans）

- 将 OpenSpec `tasks.md` 拆为 `plan/tasks/<session>/TASK_RUN.md` 的 Subtasks；`next_harness` 列写具体 `run_harness.py` 子命令。

## 4. 实现（subagent / executing-plans）

- 子任务粒度：**可独立验证**；并行时注意合并与 CONTRACT 对齐。

## 5. 测试（test-driven-dev）

- Fortran：先失败测试/再实现（行为约束）；合并门禁以 CI 为准。

## 6. 审查（requesting-code-review）

- 分级：阻断 / 警告 / 建议；链接到 PR。

## 7. 收尾（finishing-branch）

- `change-package validate --strict` → `closure` 或子集 → 合并/PR/废弃决策。
- 归档变更包并更新 `ufc_governance/migration/INVENTORY.csv`。

## 与 `TASK_RUN.md` 的对齐

建议在 front matter 增加（可选）：

```yaml
governance_change_id: "<change_id>"
```

与 `plan/changes/<change_id>/` 对应；模板见 `ufc_harness/templates/TASK_RUN.template.md`。