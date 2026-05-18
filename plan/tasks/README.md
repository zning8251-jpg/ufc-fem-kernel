# `plan/tasks/` — 已立项任务包

- 每个任务独占子目录 **`plan/tasks/<task_id>/`**。  
- **必含** `TASK_RUN.md`（由 `python ufc_harness/run_harness.py agent-task init --session <task_id> ...` 生成）。  
- 可选：`artifacts/`、`notes.md`。  
- **禁止**：`ufc_core` 生产 `.f90` 或可进构建的源码树；实现变更在独立分支/PR 中完成后再在此更新状态。

结题后整包迁至 **`plan/archive/<task_id>/`**。
