# TASK_RUN — p1-material-c2-mateval-split (PR-B)

| Field | Value |
|-------|-------|
| change_id | `p1-material-c2-mateval-split` |
| branch | `feat/p1-material-c2-mateval-split-prb` |
| base | `feat/p1-material-c2-mateval-split-pra` |
| date | 2026-05-19 |

## Done

- Hyper / Damage / Creep / Visco / Composite → `*_PointEval.f90`
- `PH_MatEval.f90` facade-only
- CONTRACT C2 table complete
- guardian P0=0 on all touched modules

## Harness

```text
guardian PH_MatEval + 5 PointEval modules → P0=0
change-package validate --strict → OK
```
