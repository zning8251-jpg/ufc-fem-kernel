# Design: p2-element-legacy-contm-retire

> **Status**: **ACTIVE**（2026-05-19）— G6-W0 交付中

## 1. 问题

| 模块 | 债 | 影响 |
|------|-----|------|
| `PH_Elem_Contm.f90` | `USE MD_TypeSystem`, `MD_Elem_Mgr`, `MD_Mat_Lib` | guardian DEP / G6 |
| `PH_ElemContm_Ops.f90` | 大体量 legacy 实现 | 维护面 |
| `Solid*_Def` | 回退 `Calc_Continuum*` | 非金线但仍在 L4 热族入口 |

生产路径 **已**走 `RT_Asm_Solv` → `PH_Elem_Domain%Compute_Ke`（#21 门控 `mat_pt_idx` / `mat_props_in`），**不**经过 Contm。

## 2. G6 分阶段

| 阶段 | 交付 | 门闩 |
|------|------|------|
| **G6-W0** | 边界 SSOT + `verify_element_golden_path_no_contm.py` | 金线锚点零 Contm 引用 |
| **G6-W1** | `PH_Elem_Sld3D_Def` 显式路由（`PH_Elem_Contm_Calc3D` / `Calc_C3D8R`）；`Calc_Continuum3D` 仅回退 | **进行中** |
| **G6-W2** | Contm 门面迁 Bridge 或删减 `USE MD_*` | G6 绿候选 |

## 3. 允许调用方（legacy 冻结表）

见 [`LEGACY_CONTM_BOUNDARY.md`](../../../ufc_core/L4_PH/Element/Legacy/LEGACY_CONTM_BOUNDARY.md)。

## 4. Harness

```text
python ufc_harness/run_harness.py tst p2-element-golden-seam
python tools/verify_element_golden_path_no_contm.py
```
