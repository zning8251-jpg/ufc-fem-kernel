# 变更包策略（Spec 环）

## 真源优先级（双轨期）

1. `**ufc_core/**/CONTRACT.md**`：与实现直接绑定的域合同，变更包不得与之冲突。
2. `**docs/**`：未 flip 前为规范叙事默认真源；变更包应 **引用路径** 而非复制大段。
3. `**ufc_governance/library/`**：flip 后的叙事真源；迁移规则见 `[../../MIGRATION.md](../../MIGRATION.md)`。

## 变更包路径（唯一约定）

- **Canonical**：`UFC/plan/changes/<change_id>/`  
- **禁止**：同一 `change_id` 在 `ufc_governance/triad/spec/changes/` 再建一套平行包（避免双真源）。

## 四制品最小集


| 文件                           | 用途                           |
| ---------------------------- | ---------------------------- |
| `proposal.md`                | Why / What / 影响面             |
| `design.md`                  | 技术决策、Open Questions          |
| `tasks.md`                   | Checkbox 任务清单（对齐 `TASK_RUN`） |
| `specs/<capability>/spec.md` | 可验收条款（建议含 Scenario 风格）       |


模板目录：`[templates/change_package/](templates/change_package/README.md)`。