# Guardian 波次 1 试点扫描（L4/L5 Material · DEP-001 + GLB-001）

**日期**：2026-05-14  
**命令**（在 `UFC/` 根执行）：

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material --rules DEP-001,GLB-001
python ufc_harness/run_harness.py guardian ufc_core/L5_RT/Material --rules DEP-001,GLB-001
```

## 结果摘要

| 路径 | P0 | P1 | P2 |
|------|----|----|-----|
| `ufc_core/L4_PH/Material` | **2** | 0 | 0 |
| `ufc_core/L5_RT/Material` | **0** | 0 | 0 |

## L4_PH/Material · P0（DEP-001 依赖反转）

| 文件 | 说明 |
|------|------|
| `Damage/PH_Mat_Damage_Gurson_Core.f90`（约行 17） | L4_PH **USE** 了 **L5_RT** 模块 |
| `Plast/PH_Mat_Plast_J2_UMAT_Core.f90`（约行 52） | 同上 |

**与合同 A8 对账**：当前实现存在 **未备案的越层 USE**；销项方向：经 **Bridge / Populate / SIO** 闭包下沉或上移调用点，禁止 L4 材料核 **长期** 直连 L5。本报告仅作试点证据，**不**在本次 MR 内改 Fortran 依赖图。

## L5_RT/Material

在 **DEP-001 + GLB-001** 规则子集下 **零违规**（与 `L5_RT/Material/CONTRACT.md` 路由-only 叙事一致）。
