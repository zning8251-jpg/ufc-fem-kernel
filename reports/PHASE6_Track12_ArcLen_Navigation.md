# Phase6 Track 1.2 — Arc-length path & regression notes

## Call chain (production)

1. **L3 config**: `MD_NonlinSolv` in [`MD_Step_Proc.f90`](../ufc_core/L3_MD/Analysis/Step/MD_Step_Proc.f90) — `method = 4` selects arc-length; fields `arc_nonconverge_use_warn`, `arc_constraint_tol_scale`, `tolerance_energy`, `nr_divergence_growth_limit`.
2. **L5 unified NL**: [`RT_NLSolver_Solv_Unified`](../ufc_core/L5_RT/Solver/RT_Solv_Nonlin.f90) `SELECT CASE (solver%method)` → `CASE (4)` → `RT_NLSolver_ArcLen`.
3. **Assembly path**: `RT_NLSolver_ArcLen` requires `model, step, step_state, dofMap, F_ext, K_CSR` (same as full NR).

## PPLAN `test_run04` / `test_run05`

These names appear in [Phase6 实施规划](../docs/05_Project_Planning/PPLAN/03_实施规划/UFC_核心攻坚战_Phase6_实施规划.md) as **scenario labels** (L-BFGS+ARC-CW vs NR+ARC-CW). There is **no** repository-wide executable named `test_run04`/`test_run05`; wire real CI/TST to `RT_NLSolver_Solv_Unified` with `method=4` and a tiny mesh case when available.

## Behaviour flags (default = legacy)

| Field | Default | Effect |
|-------|---------|--------|
| `MD_NonlinSolv%arc_nonconverge_use_warn` | `.FALSE.` | Max-iter non-convergence → `IF_STATUS_ERROR` (legacy). `.TRUE.` → `IF_STATUS_WARN` for StepDriver cut-back path (same handling as NR WARN). |
| `MD_NonlinSolv%arc_constraint_tol_scale` | `1.0` | Multiplier on sphere constraint tolerance in corrector; `>1` relaxes arc equation. |

## In-file regression

Run: `python tools/verify_phase6_track12_contract.py` (string/field presence; no Fortran execute).
