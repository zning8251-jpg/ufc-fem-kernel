## Summary

- **C2 PR-A**: Move legacy **point Eval** for **Elas** (iso + ortho) and **Plast** (J2 + Hill) out of `Dispatch/PH_MatEval.f90` into:
  - `Elas/PH_Mat_Elas_PointEval.f90`
  - `Plast/PH_Mat_Plast_PointEval.f90`
- `PH_MatEval` remains a **facade** — same `PUBLIC` names, `USE` + re-export (no caller churn).
- `CONTRACT.md` Legacy table: **C2 home** column.

## Test plan

- [x] `guardian` on `PH_MatEval.f90`, `PH_Mat_Elas_PointEval.f90`, `PH_Mat_Plast_PointEval.f90` — P0=0
- [x] `change-package validate --change-id p1-material-c2-mateval-split --strict`

## Follow-up (PR-B)

Hyper / Damage / Creep / Visco / Composite point Eval still in `PH_MatEval.f90`.
