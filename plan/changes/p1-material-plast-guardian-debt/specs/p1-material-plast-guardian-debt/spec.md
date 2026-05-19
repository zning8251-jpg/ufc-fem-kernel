# Spec: p1-material-plast-guardian-debt

## Requirements

### Scenario: Plast guardian P0 gate

- **WHEN** `guardian ufc_core/L4_PH/Material/Plast --fail-on-p0` runs after merge
- **THEN** exit code MUST be 0 (no P0/P1 violations)

### Scenario: Chaboche SIO

- **WHEN** dispatch invokes Chaboche plasticity
- **THEN** the public entry MUST be `UF_Chaboche_UMAT(UF_Chaboche_UMAT_Arg)` only (INTF-001)

### Scenario: Populate cold path

- **WHEN** `PH_Mat_Plast_Populate_From_L3` fills L4 Desc from L3 props
- **THEN** it MUST NOT assign `desc%E`, `desc%nu`, `desc%G`, `desc%K`, `desc%sigma_y`, `desc%H_iso` directly (FLOW-003)

## Out of scope

- Directory-wide NAME-001 renames.
- Non-Chaboche legacy UMAT multi-arg cleanup (DruckerPrager, Gurson, …).
