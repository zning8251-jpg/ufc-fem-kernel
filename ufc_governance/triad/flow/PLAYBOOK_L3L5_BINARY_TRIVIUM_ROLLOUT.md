# L3/L4/L5「二元结构 + 三维度」滚动改造 Playbook

本页固化 **L3/L4/L5 二元结构 + 空间/时间/动作** 滚动改造的操作顺序（与 `triad/CROSSWALK.md` 及试点变更包一致）。

---

## 1. Skills 加载顺序（Context → Skills）

在 Agent 会话中**依次**加载（可一行多技能）。**命名**与 SIO/架构并列：写 `ufc_core/**/*.f90` 前须加载 `ufc-naming-checker`（场景 A–F：MODULE、四型+Args、TBP、公开/私有过程、变量/常量、Bridge/LoadBC），见 [`skills/ufc-naming-checker/SKILL.md`](../../../skills/ufc-naming-checker/SKILL.md)。

```bash
cd UFC
npx openskills read ufc-governance-triad,fem-kernel-architecture,ufc-structured-io,ufc-naming-checker,fem-kernel-data-contract
```

| 顺序 | 技能 | 用途 |
|------|------|------|
| 1 | `ufc-governance-triad` | 变更包路径、`change-package` / `discipline`、与 `TASK_RUN` 绑定 |
| 2 | `fem-kernel-architecture` | 四型、四链、层边界、Populate/Bridge 叙事 |
| 3 | `ufc-structured-io` | `*_Arg`、五参/六参、`_Proc`、SIO 硬约束 |
| 4 | `ufc-naming-checker` | 按场景自检命名；真源 `rules/ufc-naming.mdc`；与「空间/时间/动作」叙事对齐时**动词+对象**在过程名，维度进注释/合同 |
| 5 | `fem-kernel-data-contract` | 合同字段、版本与实现同步 |
| 按需 | `fem-kernel-test-design`、`fem-kernel-verification` | 每波次有行为变更时补 |

---

## 2. 每批 `.f90` 改动后的 Harness（纪律环）

**写码前**：已执行 §1 中的 `ufc-naming-checker`（避免 MODULE / TBP / `*_Arg` 名一次性写错）。**写码后**：下列三步对**本批**路径各跑一次（子程序名、四型、TBP、变量等由 `naming` 扫；与技能场景表交叉核对）。

对**每一个**已修改或即将修改的文件路径执行（从 `UFC/` 目录）：

```bash
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/PH_Mat_Def.f90
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material --fail-on-p0
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material
```

波次合并前（或 PR 前）：

```bash
python ufc_harness/run_harness.py change-package validate --change-id <change_id> --strict
python ufc_harness/run_harness.py closure --skip-plan-checks
```

若 `plan-checks` 已绿，可去掉 `--skip-plan-checks` 以全量文档门禁。

---

## 3. Loop（防遗忘）

| 动作 | 载体 |
|------|------|
| 记录卡住的 Guardian 规则 / **命名**（含 Harness 报的符号与场景：如 TBP、公开过程） | `TASK_RUN.md` → **Log** 表 |
| 全链路摘要 | `REPORTS/loop_run_*.md`（`closure`） |
| 对照 spec 是否偏离 | 可选 `python ufc_harness/run_harness.py agent-slow-loop` |
| 叙事真源迁移（非本 Playbook 必需） | `ufc_governance/migration/INVENTORY.csv` |

---

## 4. Roll-forward（下一域 / 下一层）

1. 当前 `change_id` 的 `tasks.md` §1 **DoD** 全部勾选且 Harness 绿。  
2. 将 `TASK_RUN` 中子任务标为 `done`；`current_step_id` 指向收尾行。  
3. **新建**下一 `plan/changes/<new_change_id>/`（勿在同一包内混多域大改）。  
4. `agent-task init --session <new_session> --goal "..."` 并设 `governance_change_id`。  
5. L3 → L4 → L5 的层序与域序由团队 PPLAN 风险表调整；默认仍建议 **先紧后松**（热路径 / CONTRACT 紧的域先行）。

---

## 5. 当前仓库试点索引

| change_id | 层/域 | 说明 |
|-----------|--------|------|
| `rollout-l4-material-binary-trivium` | L4_PH / Material | 入口脊索 + 方法论落 spec；`TASK_RUN` session 同名 |
| `rollout-l4-material-wave2-dispatch` | L4_PH / Material / Dispatch | Dispatch 子树基线 guardian+naming + 可选单笔 P0 修复；`TASK_RUN` session 同名 |

复制新波次：从 [`plan/changes/example-ufc-triad/`](../changes/example-ufc-triad) 或本试点目录复制后改名，再跑 `change-package validate --strict`。
