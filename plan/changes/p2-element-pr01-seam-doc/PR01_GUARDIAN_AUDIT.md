# PR01 接缝 — Guardian 审计（2026-05-19）

> **命令**：`python ufc_harness/run_harness.py guardian <path> [--fail-on-p0]`  
> **范围**：PR01 **锚点文件**（非全 `Element/` / `Material/` 树）

## 汇总

| 文件 | P0 | P1 | P2 | `--fail-on-p0` |
|------|----|----|-----|----------------|
| `L4_PH/Element/PH_Elem_Def.f90` | 0 | 4 | 3 | **PASS** |
| `L4_PH/Element/PH_Elem_Domain.f90` | 0 | 1 | 3 | **PASS** |
| `L4_PH/Element/Shared/PH_Elem_MaterialRoute.f90` | 0 | 7 | 21 | **PASS**（2026-05-19，`p2-element-material-route-audit`：L4 `PH_Elem_MatRoute_ValidateRtCtx`） |
| `L5_RT/Assembly/RT_Asm_Solv.f90` | 0 | 0 | 10 | **PASS** |
| `L4_PH/Material/Dispatch/PH_MatEval.f90` | 0 | 0 | 0 | **PASS** |

## 全树参考（非门控）

| 路径 | P0 | 备注 |
|------|-----|------|
| `L4_PH/Material/` | 94 | 全树；不阻塞 PR01 文档波次 |
| `L4_PH/Element/` | 149 | 全树 |
| `L5_RT/Assembly/` | 0 | 目录级 P0=0 |

## 跟进

| 项 | change_id |
|----|-----------|
| ~~`PH_Elem_MaterialRoute.f90` P0=1~~ | **已销**（`ValidateRtCtx`，无 `USE RT_Mat_Core`） |
| `RT_Asm_Solv` P2 | 随 `p2-element-ke-arg-align` 或 H3 Assembly |
| `PH_Elem_MaterialRoute` P1/P2 | NAME/MOD/INTF 债 — 独立命名波次 |
