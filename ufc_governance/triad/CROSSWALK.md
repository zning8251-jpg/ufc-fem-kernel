# 外源方法论 ↔ UFC 三件套对照（CROSSWALK）

本文固化 OpenSpec / Superpowers / addyosmani Agent Skills 的语义，在 UFC 内的落点与特化规则。**实施与验收以本文件 + `discipline/manifest.v1.json` 为准**；不依赖外网工具默认安装。

---

## 1. 铁三角 What / How / Quality


| 外源表述                    | UFC 落桶                                                       | 验收锚点                                          |
| ----------------------- | ------------------------------------------------------------ | --------------------------------------------- |
| OpenSpec「说清楚」— 书面契约     | `plan/changes/<id>/` + `triad/spec/templates`                | `change-package validate`                     |
| Superpowers「做对事」— 流程    | `triad/flow/*` + `plan/tasks/*/TASK_RUN.md`                  | Subtasks 与 playbook 步骤一致                      |
| Agent Skills「做得好」— 工程标准 | `triad/discipline/manifest.v1.json` + `skills/` + Harness/CI | `discipline verify` + guardian/naming/closure |


---

## 2. OpenSpec 核心命令 → UFC 等价


| 外源命令              | UFC 等价操作                                                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `openspec init`   | 复制金样 `[plan/changes/example-ufc-triad/](../plan/changes/example-ufc-triad)`；阅读 `[ufc_governance/README.md](../README.md)`。 |
| `/opsx:propose`   | 新建 `plan/changes/<change_id>/` 并填四制品；Chat 中可用「按 ufc-governance-triad 开变更包」触发 skill。                                        |
| `/opsx:apply`     | 按 `tasks.md` 与 `TASK_RUN.md` 子任务改代码；绑定同一 `change_id`。                                                                      |
| `/opsx:verify`    | `python UFC/ufc_harness/run_harness.py change-package validate --change-id <id> [--strict]`；大闭环见 `closure`。                |
| `/opsx:archive`   | 将 `plan/changes/<id>/` 移至 `plan/changes/archive/<date>-<id>/`（或团队约定目录）；更新 `migration/INVENTORY.csv`。                       |
| `openspec update` | 更新 `AGENTS.md` 技能表、`triad/flow/SKILL_ROUTING.md`、相关 `skills/**/SKILL.md` 后走 Code Review。                                   |


---

## 3. Superpowers 七步工作流 → UFC `PLAYBOOK_FEATURE.md`


| 步骤  | 外源 skill 名                                    | UFC 对应                                                              |
| --- | --------------------------------------------- | ------------------------------------------------------------------- |
| 1   | brainstorming                                 | `flow/PLAYBOOK_FEATURE.md` §1；澄清轮次上限见 discipline README。            |
| 2   | using-git-worktrees                           | 分支/worktree；与 `plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md` 绿/黄/红策略一致。 |
| 3   | writing-plans                                 | 由 OpenSpec `tasks.md` 细化到 `TASK_RUN` Subtasks。                      |
| 4   | subagent-driven-development / executing-plans | Cursor 多 Agent 或顺序子任务；主 Agent 负责合并与失败恢复。                            |
| 5   | test-driven-development                       | Fortran：`ufc_core` 内既有测试 + `scripts/ci`；先红后绿为**行为约束**，硬强制靠 CI。      |
| 6   | requesting-code-review                        | PR 前自检 + 分级审查表（可写在 `TASK_RUN` Log）。                                 |
| 7   | finishing-a-development-branch                | 合并/PR/废弃决策；与 `agent-task` 收尾字段对齐。                                   |


### 四条设计理念（AI 行为约束，非 OS 钩子）

1. **上下文主动选用**：`AGENTS.md` 技能表 + `SKILL_ROUTING.md`；漏选时人显式 `npx openskills read …`。
2. **子 Agent 两阶段审查**：规格对齐 `specs/`**；代码质量对齐 `manifest` 与 `rules/`。
3. **TDD 优先**：真不可绕过 = pre-commit/CI。
4. **YAGNI + DRY**：大改必须额外人审。

### 15+ 技能名 → UFC `skills/` 或 playbook（非一对一处标 PLACEHOLDER）


| 外源 skill                       | UFC 映射                                            |
| ------------------------------ | ------------------------------------------------- |
| brainstorming                  | `flow/PLAYBOOK_FEATURE.md` + 可选 `doc-coauthoring` |
| writing-plans                  | `TASK_RUN` + `tasks.md`                           |
| executing-plans                | `TASK_RUN` Subtasks 批跑                            |
| subagent-driven-development    | Agent 编排约定（见 playbook）                            |
| test-driven-development        | `fem-kernel-test-design` + CI                     |
| systematic-debugging           | 团队自建笔记或后续 skill                                   |
| verification-before-completion | `closure` / `guardian`                            |
| requesting-code-review         | PR 流程                                             |
| receiving-code-review          | PR 流程                                             |
| using-git-worktrees            | Git 文档 + playbook                                 |
| finishing-a-development-branch | Git 文档 + playbook                                 |
| dispatching-parallel-agents    | IDE 能力                                            |
| writing-skills                 | `skill-creator`                                   |
| using-superpowers              | 本 `triad/README.md`                               |


---

## 4. Agent Skills：7 生命周期 → UFC 操作


| 外源命令      | UFC 等价                                          |
| --------- | ----------------------------------------------- |
| init      | 新建变更包目录 + 填 `proposal.md` 骨架                    |
| verify    | `change-package validate` + `discipline verify` |
| install   | `git clone` 技能仓库已具备；按需 `npx openskills read`    |
| on / off  | 在 `SKILL_ROUTING.md` 标注本任务启用技能集；或团队 CLI 后续扩展    |
| update    | 同步 `skills/` 与 `AGENTS.md` 表                    |
| uninstall | 从任务上下文移除某技能引用                                   |


### 20 技能分类 → UFC 特化（节选）


| 外源维度               | Web 原文约束          | UFC 特化                                     |
| ------------------ | ----------------- | ------------------------------------------ |
| design-api         | OpenAPI 3.0       | 公开 Fortran 模块接口 / `CONTRACT.md` 字段表        |
| code-documentation | JSDoc             | 模块头注释、`!>` 或团队 Doxygen 约定；域 `CONTRACT.md`  |
| code-structure     | 行数上限              | 与 `ufc_naming`/模块拆分惯例一致；大文件需拆分             |
| test-coverage      | 分支 ≥80%           | 以 `scripts/ci` 与语言栈为准；Fortran 以团队配置为准      |
| security-secrets   | token 扫描          | CI `gitleaks` 等 + 不将密钥写入仓库                 |
| production-ready   | Release checklist | `closure` + `guardian --fail-on-p0` + 发布文档 |


完整维度清单见 `discipline/manifest.v1.json` 注释字段与 `discipline/README.md`。

---

## 5. 组合原则 2.2（工具互补）

- `tasks.md`（规格环）→ **输入** `writing-plans` / `TASK_RUN` 细化。  
- 子 Agent 或并行任务 → **执行** `manifest` 中的 harness 建议。  
- 发布前检查 → **对照** `specs/`** 中 Scenario 与域 `CONTRACT.md`（`change-package validate` + `closure`）。

---

## 6. 刻意降级（小改动）

若跳过某环，须在 `TASK_RUN.md` 或变更包 `design.md` 的 **Open Decisions** 中显式记录「降级原因与风险」，避免无声漂移。