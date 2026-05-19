# TASK_RUN — p1-material-crystal-impl

| Field | Value |
|-------|-------|
| change_id | `p1-material-crystal-impl` |
| phase | **DRAFT**（plan only；等 #7–#10） |
| branch (future) | `feat/p1-material-crystal-impl` |
| date | 2026-05-19 |

## Draft artifacts

- `plan/changes/p1-material-crystal-impl/` — proposal, design, tasks, spec, PR_BODY
- **Decision pending**: W1 iso-surrogate vs 1-slip Schmid（见 `design.md` §2.1）

## Gate checklist

- [ ] #7 #8 #9 #10 merged
- [ ] C2 archived
- [ ] Implementation PR opened from `main`

## Harness (implementation phase)

```text
change-package validate --change-id p1-material-crystal-impl --strict
guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
```
