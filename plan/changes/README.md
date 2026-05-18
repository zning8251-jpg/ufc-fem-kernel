# `plan/changes/` — 规格驱动变更包（OpenSpec 自研等价）

## 约定

- 每个 **`change_id`** 对应子目录 `plan/changes/<change_id>/`，内含四制品（见 [`ufc_governance/triad/spec/POLICY.md`](../../ufc_governance/triad/spec/POLICY.md)）。
- **金样**：[`example-ufc-triad/`](example-ufc-triad) — 校验通过后可复制改名使用。
- **归档**：完成后可整体移至 `plan/changes/archive/<YYYY-MM-DD>-<change_id>/`（团队可调整，但须在 `ufc_governance/migration/INVENTORY.csv` 登记）。

## Harness

```text
python UFC/ufc_harness/run_harness.py change-package validate --change-id <change_id> [--strict]
```

默认 **warn-only**（有问题仍退出 0，仅打印警告）；`--strict` 时缺失制品或非零退出。
