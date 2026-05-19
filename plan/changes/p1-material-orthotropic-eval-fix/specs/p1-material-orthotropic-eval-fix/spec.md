# Spec: p1-material-orthotropic-eval-fix

### Scenario: Orthotropic Eval Arg contract

- **WHEN** `PH_Mat_ElasticOrthotropic_Eval` is declared
- **THEN** it MUST have exactly one dummy argument of type `PH_Mat_ElasticOrthotropic_Eval_Arg`

### Scenario: Arg bundle fields

- **WHEN** callers supply strain and read stress/stiffness
- **THEN** `PH_Mat_ElasticOrthotropic_Eval_Arg` MUST expose `strain`, `sigma`, and `D_matrix` like the isotropic Eval Arg

### Scenario: Guardian

- **WHEN** `guardian PH_MatEval.f90 --fail-on-p0` runs after merge
- **THEN** exit code MUST remain 0
