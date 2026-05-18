# Change: rollout-l4-material-wave2-dispatch

## Why

Roll-forward from [`rollout-l4-material-binary-trivium`](../../rollout-l4-material-binary-trivium): wave 1 cleared the **Material entry spine**; **wave 2** narrows to **`ufc_core/L4_PH/Material/Dispatch/`** so Guardian P0 / naming / SIO risk can be triaged on a **bounded** path instead of the full Material tree (still hundreds of legacy violations domain-wide).

## What Changes

- Governance triad artifacts under `plan/changes/rollout-l4-material-wave2-dispatch/` + a new `TASK_RUN` session bound to this `change_id`.
- **Scope**: `ufc_core/L4_PH/Material/Dispatch/**/*.f90` (eval/dispatch façade files per `CONTRACT.md` Registry row).
- **DoD (first commit batch)**: Record **baseline** `guardian` + `naming` on the Dispatch path in `TASK_RUN.md` Log; optional **one** minimal P0 or naming fix if already isolated without cross-domain churn.

## Impact

- Planning + optional targeted `.f90` edits under `Dispatch/` only until tasks §2+ are executed.
- `CONTRACT.md` remains SSOT; contract edits only if this wave explicitly aligns a drift found during audit.
