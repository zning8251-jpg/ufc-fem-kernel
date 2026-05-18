# Tasks: rollout-l4-material-wave2-dispatch

## 1. Baseline (Dispatch path — audit + harness)

- [x] 1.1 Read [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) + `plan/changes/rollout-l4-material-wave2-dispatch/specs/**`
- [x] 1.2 Run **baseline** (record rc + short summary in `plan/tasks/rollout-l4-material-wave2-dispatch/TASK_RUN.md` Log):
  - `python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0`
  - `python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Dispatch`
- [x] 1.3 If baseline is non-zero: list top **3** files or rule IDs to target in §2 (no silent drift)

## 2. Harness gates (per batch of `.f90` edits under `Dispatch/`)

- [x] 2.1 `discipline verify --touch-path` on each touched file under `ufc_core/L4_PH/Material/Dispatch/`
- [x] 2.2 `guardian <touched.f90> --fail-on-p0` (narrow to changed files during iteration)
- [x] 2.3 `naming <touched.f90>` (or parent `Dispatch` after batch)

## 3. Optional minimal fix (first wave budget)

- [x] 3.1 Apply **at most one** isolated fix aligned with §1.3 (or mark deferred with reason in `TASK_RUN` Log)

## 4. Closure

- [x] 4.1 `python ufc_harness/run_harness.py change-package validate --change-id rollout-l4-material-wave2-dispatch --strict`
- [x] 4.2 `python ufc_harness/run_harness.py closure --skip-plan-checks` (drop `--skip-plan-checks` if plan-checks already green)

## 5. Roll-forward

- [x] 5.1 Mark `TASK_RUN` done; open next `change_id` for next Material subtree (e.g. `Elas/`, `Plast/`) or deepen Dispatch if §3 deferred
