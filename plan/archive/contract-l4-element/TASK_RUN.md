# TASK_RUN — contract-l4-element

| Field | Value |
|-------|-------|
| change_id | `contract-l4-element` |
| pillar | **P2 Element** |
| phase | **S1–S3**（contract / plan only） |
| branch (suggested) | `feat/contract-l4-element-s1-s3` |
| date | 2026-05-19 |

## Depends on

- `L4_PH/Element/CONTRACT.md` v2.6 on `main`
- P1 Material post-wave5（#7–#13）— **不阻塞** 本计划包

## Parallel with

- `p1-material-crystal-w2-multislip`（实现）— **仅 plan** 并行；勿同 MR 混 Element 代码

## Next action

1. 完成 S1 审计表（`design.md` §2）并开 PR  
2. 落盘 `P2_ELEMENT_GAP_SNAPSHOT.md`（S2）  
3. 授权首个实现 change：`p2-element-pr01-seam-doc`

## Harness

```text
python ufc_harness/run_harness.py change-package validate --change-id contract-l4-element --strict
```
