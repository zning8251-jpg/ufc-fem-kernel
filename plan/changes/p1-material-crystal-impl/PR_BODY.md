## Summary

- **W1a iso-surrogate**: mat_id **266** — J2-equivalent radial return (`sigma_y = sqrt(3)*tau_c`).
- Replaces `STATUS_UNSUPPORTED`; documents surrogate in `CONTRACT.md`.
- **W1b** (1-slip Schmid) deferred to a follow-up PR.

## Preconditions

Merge **#7 → #8 → #9 → #10** and C2 archive before opening this PR.

## Test plan

- [ ] `guardian` Crystal_Core — P0=0
- [ ] `change-package validate --change-id p1-material-crystal-impl --strict`
- [ ] discipline verify touch-path Crystal_Core

## Out of scope

Multi-slip CPFEM, L3 `MD_MatPLMCrystal`, `PH_MatEval` point Eval.
