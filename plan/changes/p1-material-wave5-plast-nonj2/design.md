# Design: p1-material-wave5-plast-nonj2

## Scope

| 项 | 值 |
|----|-----|
| **pillar_id** | P1 Material |
| **domain** | `ufc_core/L4_PH/Material/Plast/` |
| **families** | Hill · Barlat · Crystal（**不含** Chaboche） |

## SIO 预算（≤2 公开入口 / MR 原则）

| 优先级 | 入口 | 模块 | 说明 |
|--------|------|------|------|
| P0 | `UF_Hill_UMAT_Arg` | Hill_Core | `PH_MatPLMEval` CASE 205 必经 |
| P0 | `PH_Mat_Barlat_Calc_Stress_Arg` | Barlat_Core | 族内唯一应力入口 |
| P1 | `UF_CrystalPlasticity_UMAT_Arg` | Crystal_Core | mat_id 266；可与上表 **分两 PR** 同 change_id |

**建议落地顺序**（同一 `change_id`，可 2 个 PR）：

1. **PR-A**：Hill + Barlat（用满 SIO 预算 2）
2. **PR-B**：Crystal（1 个 Arg + MOD-001）

## Decisions

1. **Legacy 多参体** → module-private `*_Core` 或 `*_Legacy_Shim`（对齐 wave4 `UF_Plastic_UMAT_Legacy_Shim`）。
2. **不重命名** `PH_Mat_Hill_*` / `UF_Hill_*` 存量过程（NAME-001 记入 deferred，本波不修）。
3. **DEP-001**：禁止新增 L4→L5 `USE`；Crystal 桩保持 unsupported 语义即可。

## Acceptance

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Barlat_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave5-plast-nonj2 --strict
```
