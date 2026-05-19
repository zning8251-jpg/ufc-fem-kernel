# Design: p1-material-wave5-mateval-arg

## Scope

| 项 | 值 |
|----|-----|
| **pillar_id** | P1 Material |
| **domain** | `L4_PH/Material/Dispatch/PH_MatEval.f90` |
| **性质** | **合同/文档/形式** 收口（非大规模重构） |

## 现状（2026-05-19 · `main`）

| 检查 | 结果 |
|------|------|
| 实现签名 | 14× `PH_Mat_*_Eval(arg)` 已为单 Arg |
| Guardian INTF-001 | 0 |
| Guardian FLOW-003 | 0（`md_elas_wire` 已用于 composite/hill/vm 路径） |
| MOD-001 | 模块头不完整 |

## Decisions

1. **不新增** 第 15 个 Arg TYPE — 仅澄清既有 14+1 workspace Arg。
2. **不重命名** `PH_Mat_PlasticVonMises_Eval` 等过程名（避免全库 churn）；合同声明「过程名 = Arg 入口」。
3. **可选**：在 `CONTRACT.md` 增「Legacy Eval aggregate (`PH_MatEval`)」表：模型 → Arg TYPE → 是否 staging（C2 迁出目标族）。
4. **SIO 预算**：本 change **不消耗**「≤2 新 Arg」预算（无新公开入口，仅文档化）。

## Acceptance

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90 --fail-on-p0
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave5-mateval-arg --strict
```
