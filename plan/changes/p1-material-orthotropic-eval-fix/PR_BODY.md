## Summary

- Fix **`PH_Mat_ElasticOrthotropic_Eval`** contract: extend `PH_Mat_ElasticOrthotropic_Eval_Arg` with `strain` / `sigma` / `D_matrix` (match isotropic Eval Arg).
- Remove stray secondary dummy declarations inside the subroutine body.

## Test plan

- [x] `guardian ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90 --fail-on-p0`
- [x] `change-package validate --change-id p1-material-orthotropic-eval-fix --strict`

## Out of scope

- `TEST_PH_Mat_Eval.f90` legacy Eval_In/Out migration; orthotropic stiffness inversion upgrade.
