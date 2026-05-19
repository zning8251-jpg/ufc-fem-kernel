# TASK_RUN — p2-element-pr01-seam-doc

| Field | Value |
|-------|-------|
| change_id | `p2-element-pr01-seam-doc` |
| pillar | **P2 Element**（PR01 接缝） |
| phase | **S4 文档** |
| branch (suggested) | `feat/p2-element-pr01-seam-doc` |
| date | 2026-05-19 |

## Depends on

- P1 S7：[`P1_MATERIAL_S7_SIGNOFF.md`](../../workflows/P1_MATERIAL_S7_SIGNOFF.md)
- [`contract-l4-element`](../changes/contract-l4-element/) S3 done (#15)

## Deliverables

- [`design.md`](../changes/p2-element-pr01-seam-doc/design.md)
- [`PR01_GUARDIAN_AUDIT.md`](../changes/p2-element-pr01-seam-doc/PR01_GUARDIAN_AUDIT.md)

## Next action

1. Merge PR（plan only）  
2. Open `p2-element-material-route-audit`（销 `MaterialRoute` P0）  
3. `p2-element-ke-arg-align`

## Harness

```text
python ufc_harness/run_harness.py change-package validate --change-id p2-element-pr01-seam-doc --strict
```
