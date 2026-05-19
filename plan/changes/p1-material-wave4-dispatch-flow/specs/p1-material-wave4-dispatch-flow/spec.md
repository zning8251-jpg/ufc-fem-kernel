# Spec: p1-material-wave4-dispatch-flow

## Requirements

### R1 — Scope lock

- MUST only modify files listed in `tasks.md` §1 unless CONTRACT.md is amended in the same PR.
- MUST NOT modify `ufc_core/L4_PH/Material/Plast/**`.

### R2 — FLOW-003

- `guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` MUST exit 0 after changes.
- Runtime outputs MUST NOT assign to inbound `*_Desc` / `%desc%` fields except documented **wire/copy-in** locals (`md_elas_wire`, `plm_wrk` pack-only).

### R3 — SIO budget

- At most **two** public L4 dispatch procedures in scope MAY use single `*_Arg` entry (Principle #14).
- Legacy multi-arg bodies MAY remain **private** (`*_Core`, `*_Leg_*`).

### R4 — L3 bridge

- `UF_Plastic_Eval_Dispatch_FromDesc` and `MD_Mat_Lib` plastic range MUST call `UF_Plastic_Eval_Dispatch` via `UF_Plastic_Eval_Dispatch_Arg`.

### R5 — Verification

- `change-package validate --change-id p1-material-wave4-dispatch-flow --strict` MUST pass before merge.

## Scenarios

### Scenario A — Eval dispatch Arg spine

- **Given** L3 packed `PlastModels_Desc` and `MatEval_Ctx`
- **When** `UF_Plastic_Eval_Dispatch(eval_arg)` runs
- **Then** `eval_arg%status` is set and `eval_arg%ctx` stress/statev updated without mutating L3 `MD_Mat_Desc` SSOT

### Scenario B — Guardian FLOW-003 on Dispatch tree

- **Given** baseline wave-2 reported FLOW-003 on Eval modules
- **When** this change is on `main`
- **Then** directory guardian with `--fail-on-p0` reports P0=0
