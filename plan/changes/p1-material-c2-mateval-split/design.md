# Design: p1-material-c2-mateval-split

## Facade pattern

```text
Caller → USE PH_MatEval → re-exports symbols from:
           PH_Mat_Elas_PointEval  (iso + ortho)
           PH_Mat_Plast_PointEval (J2 point + Hill point)
```

`PH_Mat_Plast_PointEval` → `USE PH_Mat_Elas_PointEval` for elastic trial (`md_elas_wire` unchanged).

## Harness

```text
guardian Dispatch/PH_MatEval.f90 Elas/PH_Mat_Elas_PointEval.f90 Plast/PH_Mat_Plast_PointEval.f90 --fail-on-p0
change-package validate --change-id p1-material-c2-mateval-split --strict
```

## PR-B (follow-up)

- `Hyper/PH_Mat_Hyper_PointEval.f90`
- `Damage/`, `Creep/`, `Viscoelas/`, `Composite/` point Eval modules
- 最终缩小 `PH_MatEval` 至 workspace + 纯 re-export
