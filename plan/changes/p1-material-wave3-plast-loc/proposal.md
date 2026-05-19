# Change: p1-material-wave3-plast-loc

## Why

P1 Material 在 wave-1（脊索）、wave-2（`Dispatch/`）、`intf001`（SIO bridge）已收口后，**竖切下一环**为 L4 **`Plast/`** 局部本构核：Guardian 基线显示 **P0 DEP-001**（`PH_Mat_Plast_J2_UMAT_Core` → `USE RT_Com_Def`）与 **P1 INTF-001**（J2 公开过程参数过多）。若不按域柱子树推进，易与 `PH_MatEval` 全域 FLOW-003 清理混 PR，违反工作流防偏离规则。

## What Changes

- **范围**：仅 `ufc_core/L4_PH/Material/Plast/` 下 **J2 竖切**相关文件（见 `tasks.md` §1）；**不含** Hill/Barlat/Crystal 全量、**不含** `Dispatch/`（已 wave-2）。
- **预期**：
  1. 消除 `Plast/` 内 **DEP-001 P0**（`RT_PNEWDT_NO_CHANGE` / `RT_Com_Base_Ctx` 依赖下沉或 L4 本地常量，方案见 `design.md`）。
  2. **至多 2 个**公开入口收拢为 `*_Arg`（优先 `PH_Mat_Plast_Eval` 与 `PH_J2_RadialReturn` 或合同指定入口）。
  3. touched 文件补 **MOD-001** 模块头（Purpose/Theory/Status）。
- **合同**：若裁剪/委托关系变化，增量更新 `L4_PH/Material/CONTRACT.md` Plast 小节（单独 commit 或同 PR 明确节）。

## Impact

- 依赖：Populate 金线不变（`PH_L4_Populate`）；与 `intf001` bridge **兼容**，不重复改 `PH_MatPLM_PlastCall` 除非接口连锁。
- 风险：DEP 常量迁移若动 `RT_Com_Def`，须 **收窄** 仅新增 L1/L4 别名，禁止 L4 继续 `USE L5_RT` 模块。

## Links

- 差距快照：[`plan/workflows/P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
- 工作流：[`UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md)
- 任务卡：[`plan/tasks/p1-material-wave3-plast-loc/TASK_RUN.md`](../../tasks/p1-material-wave3-plast-loc/TASK_RUN.md)
