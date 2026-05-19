# Spec: p1-material-wave5-plast-nonj2

## Requirements

### R1 — Scope lock

- MUST only modify files in `tasks.md` §1.
- MUST NOT modify `PH_Mat_Plast_J2_Iso_Core.f90` or `PH_Mat_Plast_J2_UMAT_Core.f90`.

### R2 — INTF-001

- After each PR batch, public procedures in scope MUST have ≤4 dummy arguments OR a single `*_Arg` bundle.

### R3 — Dispatch chain

- `PH_MatPLMEval` CASE `PH_MAT_HILL_MAT_ID` MUST call Hill through the new Arg entry without regressing status propagation.

### R4 — Populate

- MUST NOT change `PH_L4_Populate_Material` or slot layout.

### R5 — Verification

- `change-package validate --change-id p1-material-wave5-plast-nonj2 --strict` MUST pass before merge.

## Scenarios

### Scenario A — Hill UMAT via dispatch

- **Given** legacy plastic eval ctx and Hill props in `plm_in`
- **When** `UF_Plastic_Eval_Dispatch` selects Hill mat_id
- **Then** stress/tangent update completes with `IF_STATUS_OK` or documented unsupported, via Arg SIO

### Scenario B — Crystal stub

- **Given** crystal mat_id 266
- **When** `UF_CrystalPlasticity_UMAT(arg)` is invoked
- **Then** status is set without writing to L3 `MD_Mat_Desc` SSOT
