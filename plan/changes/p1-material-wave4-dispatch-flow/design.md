# Design: p1-material-wave4-dispatch-flow

## Scope

| 项 | 值 |
|----|-----|
| **pillar_id** | P1 Material |
| **layers** | L4_PH（主）· L3_MD（挂接） |
| **domain path** | `ufc_core/L4_PH/Material/Dispatch/` |
| **wave** | W1 · Dispatch FLOW/SIO（与 Plast J2 解耦） |

## Methodology mapping

| 方法论项 | UFC 落点 |
|----------|----------|
| Desc | `PlastModels_Desc` / `MD_Mat_Desc` 仅 **冷路径/入参打包**；Eval 内用 **局部 wire**（`md_elas_wire`） |
| State | `MatEval_Ctx` / `MD_Mat_PH_UMAT_In%state` 承载应力、statev、切线 |
| Algo | `MatAlgo_Algo`（kstep/kinc） |
| Args | `UF_Plastic_Eval_Dispatch_Arg`；计划 `UF_Plastic_UMAT_Dispatch_Arg` |
| 主从 | L3 `UF_Plastic_Eval_Dispatch_FromDesc` → L4 Eval_Dispatch → legacy UMAT CASE |
| 动作 | Eval / Dispatch（非 Populate） |

## Decisions

1. **Wave boundary**：仅 `tasks.md` §1 文件；禁止混入 `Plast/` 或 Registry 机械刷新。
2. **FLOW-003**：禁止 `in_struct%desc%field =` 直写；允许 `ASSOCIATE(um_pack=>in_struct%desc)` 仅当 **入参打包**（Populate/Dispatch 边界）；长期迁入 `*_Work` 类型（遗留）。
3. **SIO 预算**：公开 API 优先 **Arg 单参**；`UF_Plastic_Eval_Dispatch_Core` 保持 module-private（5 参实现体）。
4. **与 wave3 关系**：无代码依赖；可任意 merge 顺序。

## Acceptance

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90
python ufc_harness/run_harness.py change-package validate --change-id p1-material-wave4-dispatch-flow --strict
```
