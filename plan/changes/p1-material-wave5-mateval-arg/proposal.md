# Change: p1-material-wave5-mateval-arg

## Why

`PH_MatEval.f90` 在实现层 **已全部** 为 `SUBROUTINE PH_Mat_*_Eval(arg)`，且 Guardian **INTF-001 / FLOW-003 当前为 0**。但模块仍：

- 在注释中保留 legacy **`Eval_In` / `Eval_Out`** 叙事；
- **PUBLIC** 同时导出 `PH_Mat_*_Eval_Arg` 类型与同名 `PH_Mat_*_Eval` 过程（易误解为双轨 API）；
- 缺少与 wave3/wave4 对齐的 **MOD-001** 模块头与 **CONTRACT** 增量说明。

本 change **不** 做 plan C2「按族拆模块」大迁移，仅 **Eval 族 API 合同收口**（独立 `change_id`，与 Plast 非 J2 解耦）。

## What Changes

- **范围**：`ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90`（单文件为主）；可选 `L4_PH/Material/CONTRACT.md` Dispatch/Eval 登记表 **增量**。
- **预期**：
  1. 模块头 Purpose/Theory/Status（MOD-001）。
  2. 公开 API 文档：**唯一** 推荐入口为 `PH_Mat_<Model>_Eval(PH_Mat_<Model>_Eval_Arg)`；`*_Arg` TYPE 为 Principle #14 载体。
  3. 清理文件头 **过时** `Eval_In/Out` 清单注释（或标 `LEGACY-DOC-REMOVED`）。
  4. `guardian PH_MatEval.f90` / `discipline verify` 保持绿。
- **不含**：改 `PH_MatPLMEval`、Plast 三族、Eval 算法/物理。

## Impact

- 调用方若仍 `USE` 仅过程名 — **无签名变化**（过程名未改，仍单 Arg）。
- 文档与审查口径统一，利于后续 C2 按族迁出。

## Links

- 并行：[`p1-material-wave5-plast-nonj2`](../p1-material-wave5-plast-nonj2/)
- 快照：[`P1_MATERIAL_GAP_SNAPSHOT.md`](../../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
