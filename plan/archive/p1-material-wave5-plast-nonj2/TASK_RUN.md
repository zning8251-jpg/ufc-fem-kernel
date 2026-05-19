---
task_run_version: "1.1"
session: "p1-material-wave5-plast-nonj2"
status: completed
current_step_id: "S7"
updated_at: "2026-05-19T21:00:00Z"
governance_change_id: "p1-material-wave5-plast-nonj2"
pillar_id: "P1"
wave: "W1-wave5-plast-nonj2"
---

# TASK_RUN — `p1-material-wave5-plast-nonj2`

> **变更包**：[`plan/changes/p1-material-wave5-plast-nonj2/`](../../changes/p1-material-wave5-plast-nonj2/)  
> **前置**：wave3 J2 merged · wave4 Dispatch 可选并行

## Goal

L4 `Plast/` **Hill + Barlat + Crystal**：公开 UMAT/应力入口收拢为 `*_Arg`；同步 `PH_MatPLMEval` Hill 调用链；MOD-001。

## Subtasks

| Step | 内容 | state |
|------|------|-------|
| S1 | CONTRACT + spec | pending |
| S2 | GAP 快照 §2 Hill/Barlat/Crystal | pending |
| S3 | 变更包 strict | pending |
| S5 PR-A | Hill + Barlat Arg | pending |
| S5 PR-B | Crystal Arg | pending |
| S7 | PR + archive | pending |

## Log (PR-B)

| ts | note |
|----|------|
| 2026-05-19 | Crystal Arg；guardian P0/INTF/MOD=0 |

## Next action

- 合并 PR #3 → 本 PR → `git mv plan/tasks/p1-material-wave5-plast-nonj2 plan/archive/`
