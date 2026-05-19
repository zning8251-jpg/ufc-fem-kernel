# Spec: p1-material-wave5-mateval-arg

## Requirements

### R1 — Scope lock

- Primary file MUST be `ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90`.
- MUST NOT change stress/algorithm numerics (diff should be docs/comments/headers only unless bugfix with test).

### R2 — API clarity

- Module documentation MUST state that each `PH_Mat_<Family>_Eval` accepts exactly one `PH_Mat_<Family>_Eval_Arg` argument.
- MUST NOT introduce new public procedures with >4 parameters.

### R3 — FLOW-003

- MUST preserve `md_elas_wire` (or equivalent) pattern; no new `%mat_desc%` runtime writes.

### R4 — Guardian

- `guardian PH_MatEval.f90 --fail-on-p0` MUST remain exit 0 after changes.

### R5 — change-package

- `change-package validate --change-id p1-material-wave5-mateval-arg --strict` MUST pass.

## Scenarios

### Scenario A — Composite fiber eval

- **Given** `PH_Mat_CompositeFiberReinforced_Eval_Arg` with fiber/matrix Desc fields
- **When** `PH_Mat_CompositeFiberReinforced_Eval(arg)` runs
- **Then** effective modulus uses wire Desc, not in-place mutation of `arg%mat_desc`

### Scenario B — Contract reader

- **Given** a reviewer reads updated `CONTRACT.md` Eval table
- **When** they trace Elastic/Plastic/Hyper models
- **Then** each row points to `PH_Mat_*_Eval_Arg` as the supported L4 entry
