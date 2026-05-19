# Spec: p1-material-c2-mateval-split (PR-A)

### Scenario: Backward-compatible API

- **WHEN** existing code `USE PH_MatEval, ONLY: PH_Mat_ElasticIsotropic_Eval`
- **THEN** symbols MUST remain available from module `PH_MatEval` without caller changes

### Scenario: Family ownership

- **WHEN** reviewing C2 migration status
- **THEN** isotropic/orthotropic implementations MUST reside in `Elas/PH_Mat_Elas_PointEval.f90`
- **AND** VonMises/Hill point implementations MUST reside in `Plast/PH_Mat_Plast_PointEval.f90`

### Scenario: Guardian

- **WHEN** guardian runs on touched Eval modules with `--fail-on-p0`
- **THEN** exit code MUST be 0
