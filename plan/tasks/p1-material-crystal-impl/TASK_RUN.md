# TASK_RUN — p1-material-crystal-impl

| Field | Value |
|-------|-------|
| change_id | `p1-material-crystal-impl` |
| phase | **W1a in progress**（iso-surrogate） |
| W1b | 1-slip Schmid — follow-up PR |
| docs PR | [#11](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/11) → `main` |
| branch (future) | `feat/p1-material-crystal-impl` |
| date | 2026-05-19 |

## Draft artifacts

- `plan/changes/p1-material-crystal-impl/` — proposal, design, tasks, spec, PR_BODY
- **Decision pending**: W1 iso-surrogate vs 1-slip Schmid（见 `design.md` §2.1）

## Gate checklist

- [x] #7 #8 #9 #10 merged（2026-05-19）
- [x] C2 / guardian / ortho tasks archived
- [ ] Implementation PR `feat/p1-material-crystal-impl` from `main`

## Harness (implementation phase)

```text
change-package validate --change-id p1-material-crystal-impl --strict
guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
```
