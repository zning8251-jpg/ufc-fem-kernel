## Summary

**wave5-plast-nonj2 · PR-B** — Crystal UMAT SIO（closes change_id 非 J2 三族）。

- **`UF_CrystalPlasticity_UMAT_Arg`** + `UF_CrystalPlasticity_UMAT(arg)`（stub 仍 `STATUS_UNSUPPORTED`）。
- **`PH_MatPLMEval`** CASE 266 → Arg 打包。
- MOD-001：Crystal 模块头。

**依赖**：基于 **PR #3（PR-A Hill+Barlat）** 分支 `feat/p1-material-wave5-plast-nonj2-pra`。

## Harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90 --rules INTF-001,MOD-001
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
```

## Changed files

| 路径 | 摘要 |
|------|------|
| `Plast/PH_Mat_Plast_Crystal_Core.f90` | `UF_CrystalPlasticity_UMAT_Arg` + MOD-001 |
| `Dispatch/PH_MatPLMEval.f90` | CASE 266 Arg |
| `Dispatch/PH_MatPLM_Kernels.f90` | 再导出 Arg |

## Merge order

1. PR #3 (PR-A) → 2. **本 PR (PR-B)** → archive `plan/tasks/p1-material-wave5-plast-nonj2/`
