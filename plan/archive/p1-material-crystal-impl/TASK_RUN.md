# TASK_RUN — p1-material-crystal-impl

| Field | Value |
|-------|-------|
| change_id | `p1-material-crystal-impl` |
| status | **COMPLETE**（2026-05-19） |
| W1a | **merged** [#12](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/12) — iso-surrogate (**deprecated**) |
| W1b | **merged** [#13](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/13) — 1-slip Schmid |
| docs | [#11](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/11) plan 草案 |

## Delivered

- mat_id **266**：`UF_CrystalPlasticity_UMAT` — W1b Schmid active; W1a removed from code path
- `CONTRACT.md` Crystal UMAT 表；`props`/`statev` 合同

## Follow-up (new change_id, not this task)

- **W2**：多滑移 / 潜硬化 / 有限应变 — 单独立项

## Harness (record)

```text
guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0  → P0=0
change-package validate --change-id p1-material-crystal-impl --strict → OK
```
