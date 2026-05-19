## Summary

- **P0 FLOW-003**: `PH_Mat_Plast_Populate_From_L3` writes only `cfg`/`pop`/`props`; elastic/hardening reads via `plast_desc_read_*`.
- **P1 INTF-001**: `UF_Chaboche_UMAT_Arg` + public `UF_Chaboche_UMAT(arg)`; `PH_MatPLMEval` Chaboche CASE aligned with Hill.
- **MOD-001** on `PH_Mat_Plast_Core` and `PH_Mat_Plast_Chaboche_Core`.

`guardian Plast --fail-on-p0` → **P0=0, P1=0** (P2 NAME/MOD debt on non-touched files remains).

## Test plan

- [x] `guardian ufc_core/L4_PH/Material/Plast --fail-on-p0`
- [x] `change-package validate --change-id p1-material-plast-guardian-debt --strict`

## Out of scope

- Full `Plast/` NAME-001 sweep; C2 MatEval split; Orthotropic dummy; Crystal implementation.
