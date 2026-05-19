## Summary

- Implement **W1** crystal plasticity UMAT for mat_id **266** (`UF_CrystalPlasticity_UMAT`).
- Replace `STATUS_UNSUPPORTED` with validated elastic–plastic increment per `design.md`.
- Document `props` / `statev` in `CONTRACT.md`.

## Preconditions

Merge **#7 → #8 → #9 → #10** and C2 archive before opening this PR.

## Test plan

- [ ] `guardian` Crystal_Core — P0=0
- [ ] `change-package validate --change-id p1-material-crystal-impl --strict`
- [ ] discipline verify touch-path Crystal_Core

## Out of scope

Multi-slip CPFEM, L3 `MD_MatPLMCrystal`, `PH_MatEval` point Eval.
