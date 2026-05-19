# TASK_RUN — p2-element-legacy-contm-retire

| Field | Value |
|-------|-------|
| change_id | `p2-element-legacy-contm-retire` |
| pillar | **P2 Element**（G6 legacy Contm） |
| phase | **G6-W0** |
| branch (suggested) | `feat/p2-element-legacy-contm-retire` |
| date | 2026-05-19 |

## Depends on

- #21 — `material-route-audit` + `ke-arg-align`
- PR01 — #20 / `plan/archive/p2-element-pr01-seam-doc/`

## Next action

1. Merge G6-W0 PR  
2. Open G6-W1（`Solid*_Def` 脱离 Contm 回退）

## Harness

```text
python ufc_harness/run_harness.py tst p2-element-golden-seam
python ufc_harness/run_harness.py change-package validate --change-id p2-element-legacy-contm-retire --strict
```
