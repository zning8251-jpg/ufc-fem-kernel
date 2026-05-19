# Change: p1-material-wave4-dispatch-flow

## Why

P1 Material **wave3** 已竖切 **Plast/J2 脊索**（与 `Dispatch/` 解耦）。wave-2 基线曾记录 `Dispatch/` **FLOW-003 P0** 集中于 `PH_MatEval` / `PH_MatPLMEval`；当前 `main` 上 **FLOW-003 已为 P0=0**（`md_elas_wire` / `ASSOCIATE(um_pack=>...)` 模式）。本 change 承接 wave3 §5.2 的 **Dispatch 优先**路线：巩固 Desc/State 边界、收拢 **≤2** 个塑性 dispatch **SIO 脊索**，**不** 触碰 `Plast/` 非 J2 族。

## What Changes

- **范围**：`ufc_core/L4_PH/Material/Dispatch/`（脊索：`PH_MatEval.f90`、`PH_MatPLMEval.f90`）+ 必要 L3 挂接（`MD_Mat_Plast_Dispatch.f90`、`MD_Mat_Lib.f90`、`MD_MatLibPH_Brg.f90`）。
- **预期**：
  1. **FLOW-003**：目录级 `--fail-on-p0` 保持 0；`PH_MatEval` 维持 **wire Desc**（不 runtime 写 `arg%mat_desc`）。
  2. **SIO（≤2）**：`UF_Plastic_Eval_Dispatch(UF_Plastic_Eval_Dispatch_Arg)`；第二预算 **`UF_Plastic_UMAT_Dispatch_Arg`**（见 `tasks.md` §3.2）。
  3. **MOD-001**：`PH_MatPLMEval` 模块头（Purpose/Theory/Status）。
- **不含**：`PH_MatPLM_LegacyFacadeUMATs` 全量 INTF-001；`Plast/` Hill/Barlat/Crystal；`intf001` §3 statev/CTest follow-up。

## Impact

- L3→L4 塑性求值路径经 **`UF_Plastic_Eval_Dispatch_Arg`**；Populate / slot 金线不变。
- 与 **PR #1 wave3** 可并行审查（本分支自 `main`）。

## Links

- 前置 wave3：[`p1-material-wave3-plast-loc`](../p1-material-wave3-plast-loc/)（Plast J2，独立 PR）
- 差距快照：[`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
- 工作流：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)
