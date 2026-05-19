## Summary

- **C2 PR-B**: Move remaining legacy point Eval from `PH_MatEval` into family modules:
  - `Hyper/PH_Mat_Hyper_PointEval.f90`
  - `Damage/PH_Mat_Damage_PointEval.f90` (fixes brittle→ductile Arg wiring)
  - `Creep/PH_Mat_Creep_PointEval.f90`
  - `Viscoelas/PH_Mat_Visco_PointEval.f90`
  - `Composite/PH_Mat_Comp_PointEval.f90`
- `PH_MatEval.f90` is now a **thin facade** (~80 lines): re-exports + `PH_Mat_UMATEnsureWorkspace` only.
- Arg bundles extended where implementations required fields (creep `sigma`/`creep_rate`, damage stress/D, laminate `Q_matrix`, etc.).

## Depends on

- **PR-A** [#9](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/9) (`feat/p1-material-c2-mateval-split-pra`) — Elas/Plast PointEval

## Test plan

- [x] `guardian` on all new PointEval modules + `PH_MatEval.f90` — P0=0
- [x] `change-package validate --change-id p1-material-c2-mateval-split --strict`
