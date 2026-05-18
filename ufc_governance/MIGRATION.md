# 双轨迁移说明（`docs/` → `ufc_governance/library/`）

## 原则

1. **Flip 前**：`docs/` 仍为规范叙事默认真源；本目录 `library/`** 中文件若为「试点」或「索引」，须在正文顶部用 YAML 或表格标明：
  - `legacy_pointer:` 原 `docs/` 或 `design_plan/` 路径（仍可读）。
  - `supersedes:` 仅在实际完成 flip 且团队宣布切换后填写。
2. **Flip 后**：对应旧路径保留 **stub**（短文件，只含「已迁移至 …」与链接），避免断链。
3. **禁止**：在未更新 `[migration/INVENTORY.csv](migration/INVENTORY.csv)` 的情况下搬移大块正文。

## 与 Harness 的关系

- 目录结构门禁仍以 `design_plan/` + `harness_config.json` 为主；`library/` 的第二套 `required_dirs` 为可选后续（见 `ufc_harness` 文档）。
- 变更包校验：`change-package validate` 针对 `[plan/changes/<change_id>/](../plan/changes)`。

## 试点

首批试点条目见 `migration/INVENTORY.csv` 中 `status=pilot` 行及 `[library/00_constitution/TRIAD_SYSTEM_INDEX.md](library/00_constitution/TRIAD_SYSTEM_INDEX.md)`。