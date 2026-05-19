## Summary

**wave5-plast-nonj2 · PR-A** — Hill + Barlat SIO（SIO 预算 2/2）。

- **`UF_Hill_UMAT_Arg`** + `UF_Hill_UMAT(arg)`；`PH_MatPLMEval` CASE 205 改 Arg 调用。
- **`PH_Mat_Barlat_Calc_Stress_Arg`** + `PH_Mat_Barlat_Calc_Stress(arg)`；`PH_Mat_Barlat_Calc_Stress_Core` 私有化。
- MOD-001：Hill / Barlat 模块头。

**不含**：Crystal（PR-B）· J2（wave3）· `PH_MatEval`.

## Harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Barlat_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.f90 --rules INTF-001
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Barlat_Core.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave5-plast-nonj2 --strict
```

## Changed files

| 路径 | 摘要 |
|------|------|
| `Plast/PH_Mat_Plast_Hill_Core.f90` | `UF_Hill_UMAT_Arg` |
| `Plast/PH_Mat_Plast_Barlat_Core.f90` | `PH_Mat_Barlat_Calc_Stress_Arg` |
| `Dispatch/PH_MatPLMEval.f90` | Hill CASE → Arg |
| `Dispatch/PH_MatPLM_Kernels.f90` | 再导出 `UF_Hill_UMAT_Arg` |

## Roll-forward

- **PR-B**（同 change_id）：`UF_CrystalPlasticity_UMAT_Arg` — 另开 PR 叠本分支或从 main 续开。
