# Spec: p1-material-wave3-plast-loc

## Requirements

### R1 — Scope lock

- The change MUST only modify Fortran under `ufc_core/L4_PH/Material/Plast/` files listed in `tasks.md` §1 unless CONTRACT.md is updated in the same PR with explicit rationale.
- The change MUST NOT modify `ufc_core/L4_PH/Material/Dispatch/` (owned by wave-2 / intf001).

### R2 — DEP-001

- After implementation, `python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_J2_UMAT_Core.f90 --fail-on-p0` MUST exit 0.
- `PH_Mat_Plast_J2_UMAT_Core` MUST NOT `USE` any `L5_RT` module.

### R3 — SIO budget

- At most **two** newly introduced or refactored public procedures in scope MAY use unified `*_Arg` bundles (Principle #14).
- Remaining INTF-001 findings MUST be listed in `TASK_RUN` Log as deferred with file:line.

### R4 — Populate gold line

- Material slot population semantics (`desc%props`, `PH_Mat_Desc_Effective_Model`) MUST remain unchanged unless a regression test or CONTRACT amendment is included.

### R5 — Verification

- `change-package validate --change-id p1-material-wave3-plast-loc --strict` MUST pass before merge.
- PR description MUST include workflow five-tuple (layer/domain/contract/bridge/SIO) per `UFC_L3L4L5_域柱改造固化工作流_v1.0.md`.

## Scenarios

### Scenario A — Guardian P0 cleared on J2 UMAT core

- **Given** baseline DEP-001 on `PH_Mat_Plast_J2_UMAT_Core.f90`
- **When** the change is applied
- **Then** per-file guardian with `--fail-on-p0` returns 0 for that file

### Scenario B — Eval entry Args (optional within budget)

- **Given** `PH_Mat_Plast_Eval` is selected as one of two SIO refactors
- **When** Eval is called from within Plast
- **Then** public interface uses `*_Arg` with documented `[IN]/[OUT]` and no new inp/out pairs
