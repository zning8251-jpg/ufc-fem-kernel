# Change: rollout-l4-material-binary-trivium

## Why

Align **L4_PH / Material** feature modules with the UFC architecture methodology: **binary module structure** = data side (primary/secondary **Desc / State / Algo / Ctx** + unified `*_Arg`, nested/parallel/master–slave) + procedure side (**space / time / action** dimensions in verifiable terms). This pilot establishes the governance triad (change package + `TASK_RUN` + Harness) before scaling to other L4 domains and L3/L5.

## What Changes

- Pilot scope: **`ufc_core/L4_PH/Material/`** (first wave: definition/dispatch/populate entry points listed in `tasks.md`, not the entire 355-file tree).
- Documentation of record: `design.md` maps methodology vocabulary to `CONTRACT.md` + Principle #14 SIO.
- No mandatory `.f90` edits in this change package alone; implementation lands in follow-up commits under the same `change_id` / `TASK_RUN` until DoD is met.

## Impact

- Touches planning artifacts under `plan/changes/` and `plan/tasks/` only until implementation PRs are opened.
- Runtime risk: none until `.f90` PRs merge; `CONTRACT.md` remains SSOT for Material domain.
