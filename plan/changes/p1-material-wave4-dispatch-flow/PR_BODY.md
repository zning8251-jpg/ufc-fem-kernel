## Summary

P1 Material **wave4** — L4 `Dispatch/` 塑性求值脊索 SIO（与 wave3 Plast/J2 **解耦**）。

- **`UF_Plastic_Eval_Dispatch_Arg`** + 单参 `UF_Plastic_Eval_Dispatch`；`UF_Plastic_Eval_Dispatch_Core` 私有化。
- **`UF_Plastic_UMAT_Dispatch_Arg`** + 单参 `UF_Plastic_UMAT_Dispatch`；legacy 多参经 module-private **`UF_Plastic_UMAT_Legacy_Shim`**。
- L3 挂接：`MD_Mat_Plast_Dispatch`、`MD_Mat_Lib`、`MD_MatLibPH_Brg`。
- **`PH_MatPLMEval`** MOD-001 模块头；**FLOW-003** 目录级 P0=0（`md_elas_wire` / 无 `%desc%=` 直写）。

**不在本 PR**：`UF_Plastic_Leg_*` / `PH_MAT_UMAT_Plastic_Dispatch` 全量 INTF（P2 渐进）；`Plast/` 非 J2；`intf001` §3 follow-up。

---

## 主轴声明

| 项 | 内容 |
|----|------|
| **层** | L4_PH（+ L3 桥挂接） |
| **域** | `ufc_core/L4_PH/Material/Dispatch/` |
| **合同** | 未改 `CONTRACT.md` 正文 |
| **Bridge** | `MD_MatLibPH_Brg` 再导出 `*_Arg` |
| **SIO** | 是 — `UF_Plastic_Eval_Dispatch_Arg`、`UF_Plastic_UMAT_Dispatch_Arg` |

---

## Harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave4-dispatch-flow --strict
# closure: REPORTS/loop_run_20260519_115259.md (exit 1: repo-wide naming 存量)
```

---

## Changed files

| 路径 | 摘要 |
|------|------|
| `Dispatch/PH_MatPLMEval.f90` | 双 Arg SIO + Legacy_Shim + MOD-001 |
| `L3_MD/.../MD_Mat_Plast_Dispatch.f90` | Eval Arg 调用 |
| `L3_MD/.../MD_Mat_Lib.f90` | Eval Arg 调用 |
| `L3_MD/Bridge/.../MD_MatLibPH_Brg.f90` | 再导出 Arg |
| `plan/changes|tasks|workflows/...` | wave4 变更包 |

---

## Roll-forward

- **Plast 非 J2**（Hill/Barlat/Crystal）或 **`PH_MatEval` Eval 族 Arg 化** — 独立 change_id。
- 可与 **PR #1 wave3** 并行合并。

## Refs

- [`plan/tasks/p1-material-wave4-dispatch-flow/TASK_RUN.md`](../../tasks/p1-material-wave4-dispatch-flow/TASK_RUN.md)
- [`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md) §2
