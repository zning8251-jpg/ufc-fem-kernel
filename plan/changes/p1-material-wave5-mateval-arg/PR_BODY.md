## Summary

- **PH_MatEval** contract/doc cleanup (`p1-material-wave5-mateval-arg`): Arg-only public API narrative, MOD-001 module header, legacy `Eval_In`/`Eval_Out` inventory removed from file header.
- **CONTRACT.md**: new **Legacy `PH_MatEval` aggregate** subsection (staging table + C2 migration pointer).
- Representative Eval procedures (ElasticIso, PlasticVM, PlasticHill): four-chain comments (Theory / Logic / Compute / Data).
- **No new Arg types** — implementations unchanged aside from comments/docs.

## Test plan

- [x] `guardian ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90 --fail-on-p0` → P0=0
- [x] `discipline verify --touch-path …/PH_MatEval.f90`
- [x] `naming …/PH_MatEval.f90`
- [x] `change-package validate --change-id p1-material-wave5-mateval-arg --strict`
- [x] `closure --skip-plan-checks` → `REPORTS/loop_run_20260519_120515.md`

## Merge notes

- Independent of `p1-material-wave5-plast-nonj2` (PR #3/#4); safe to merge after or in parallel with wave5 Plast once file conflicts are absent.
- C2 per-family absorption of `PH_MatEval` → **future change_id** (out of scope).
