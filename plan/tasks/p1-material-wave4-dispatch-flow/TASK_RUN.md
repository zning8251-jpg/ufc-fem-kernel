---
task_run_version: "1.1"
session: "p1-material-wave4-dispatch-flow"
status: in_progress
current_step_id: "S5"
updated_at: "2026-05-19T20:00:00Z"
governance_change_id: "p1-material-wave4-dispatch-flow"
pillar_id: "P1"
wave: "W1-wave4-dispatch"
---

# TASK_RUN — `p1-material-wave4-dispatch-flow`

> **变更包**：[`plan/changes/p1-material-wave4-dispatch-flow/`](../../changes/p1-material-wave4-dispatch-flow/)  
> **与 wave3 关系**：**解耦** — Plast J2 见 [`p1-material-wave3-plast-loc`](../p1-material-wave3-plast-loc/)（PR #1）

## Goal

L4 `Material/Dispatch/` **塑性求值脊索**：维持 **FLOW-003 P0=0**；收拢 `UF_Plastic_Eval_Dispatch` +（计划）`UF_Plastic_UMAT_Dispatch` 为 `*_Arg` SIO；补 `PH_MatPLMEval` MOD-001。

## Subtasks (S1–S7)

| Step | 内容 | state |
|------|------|-------|
| S1 | CONTRACT + spec | done |
| S2 | GAP §2.3 刷新 | done |
| S3 | 变更包 + 本 TASK_RUN | done |
| S4 | — | n/a |
| S5 | §3.1 Eval Arg 已实现；§3.2 UMAT Arg 待办 | in_progress |
| S6 | discipline + guardian touched | done |
| S7 | change-package strict + PR | pending |

## Log

| ts (UTC) | harness | rc | note |
|----------|---------|----|------|
| 2026-05-19 | guardian Dispatch --fail-on-p0 | 0 | P0=0（FLOW-003 已绿于 main） |
| 2026-05-19 | impl | 0 | `UF_Plastic_Eval_Dispatch_Arg` + L3 三处挂接 |
| 2026-05-19 | guardian PH_MatPLMEval.f90 | 0 | P0=0；Eval 入口 INTF 绿；UMAT 仍 P2 渐进 |

## Next action

- 完成 **§3.2** `UF_Plastic_UMAT_Dispatch_Arg`（SIO 预算第 2 项）→ harness §4.4 → 开 PR。
