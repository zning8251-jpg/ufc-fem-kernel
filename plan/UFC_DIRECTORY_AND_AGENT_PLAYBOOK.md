# UFC 目录配置 × Agent 编排总览

本文把 **仓库根下各桶目录** 与 **Prompt→Context→Skills→MCP→Agent→Harness→Loop** 工作方式对齐，并固化「自主编排、长链连贯、少打扰」的落地做法（**状态机 + 持久化 + 策略**）。权威分区仍以 **`AGENTS.md`**、**`rules/ufc-directory-layout.mdc`** 为准。

---

## 一、UFC 根目录：文档与子目录（速查）

| 路径 | 角色 | 典型内容 |
|------|------|----------|
| **`ufc_core/`** | **仅生产代码** | 六层 Fortran、层内 `Tests/`、`CONTRACT.md`；**不放**任务草稿、长调研、Harness 报告 |
| **`design_plan/`** | **Harness 默认 `--plan`** | `doc_structure.required_dirs` 章节目录骨架；与 **`docs/05_Project_Planning/PPLAN/`** 正文可交叉引用 |
| **`plan/`**（本区） | **运行任务区** | `tasks/<task_id>/TASK_RUN.md`、`backlog/`、`archive/`；**人类编排真相源** |
| **`docs/`** | 规范与 SSOT | 架构、PPLAN、开发者指南 |
| **`REPORTS/`** | **机器生成报告** | `loop_run_*`、`guardian` 摘要、`harness_gate_report.json` 等；**不替代** `TASK_RUN.md` |
| **`ufc_harness/`** | 控制系统 | `run_harness.py`、`closure`、`guardian`、`agent-*` 子命令 |
| **`tools/`** | 可复用脚本 | 与 harness 调用的工具链 |
| **`config/`** | 配置 | 构建与工具配置 |
| **`rules/`** | Cursor/Agent 规则索引 | `.mdc` 与仓库约束 |
| **`skills/`** | 可执行技能包 | `SKILL.md`；与 `AGENTS.md` 技能表对应 |
| **`scripts/`** | 维护/CI 脚本 | 如 `scripts/ci/` |
| **`build/`** | 编译产物区 | 可清空再构建 |
| **`tests/`** | 根级集成/示例测 | 与 `ufc_core` 内测并存时，团队需约定各自边界 |

**易混点**：`design_plan/` ≠ `plan/`；**Windows** 上不可用 `PLAN`/`plan` 仅靠大小写区分，故 Harness 默认用 **`design_plan`**。默认 `--plan` 解析见 **`harness_config.json` → `paths.plan_relative_to_ufc`**，可用 **`UFC_DEFAULT_PLAN`** 覆盖。

---

## 二、七段闭环在 UFC 中的落点

| 节点 | 载体（UFC） | 说明 |
|------|-------------|------|
| **Prompt** | 用户/任务单、`TASK_RUN.md` 的 Goal / Next action | 入口要可写成「可验收的一句话」 |
| **Context** | `AGENTS.md`、`rules/`、`docs/README.md`、按需打开的 `CONTRACT.md` | 少整库粘贴，多 **路径指针** |
| **Skills** | `skills/**`、`npx openskills read <name>` | 元数据在 `AGENTS.md`；正文命中任务再读 |
| **MCP** | IDE 配置、`closure_loop_checklist.json` 的 `mcp_servers` | 能只读则只读 |
| **Agent** | Cursor 等 IDE Agent | **调度**为主；**执行与验证**交给 Harness |
| **Harness** | `python ufc_harness/run_harness.py …` | **单一可信验收链**（尤其 Guardian P0） |
| **Loop** | `REPORTS/`、`agent-checkpoint`、`agent-trace`、必要时迭代技能 | 反馈写外置，不依赖单会话记忆 |

---

## 三、编排内核：状态机 + 持久化 + 策略

### 3.1 任务真相源（单一写处）

| 需求 | 落点 |
|------|------|
| 当前步、下一步、依赖谁 | **`plan/tasks/<task_id>/TASK_RUN.md`**（`agent-task` 维护）；与 **`agent-checkpoint --session`** 可同 ID |
| 机器步骤与退出码 | **`agent-trace`** → `REPORTS/agent_harness_trace.jsonl`（或 CI 日志） |
| 门禁与归因 | **`closure`** / **`pillar-loop`** → `REPORTS/*.md` |

原则：**对话只当 UI**；换会话先 **`agent-task status`** / 读 **`TASK_RUN.md`**，不必复述整段历史。

### 3.2 分级自治策略（绿 / 黄 / 红）

| 级别 | 示例 | 人是否要点确认 |
|------|------|----------------|
| **绿** | 只读 MCP、`doc-structure`、窄 `guardian --rules`、本地分支探索（团队允许时） | 可自动跑 |
| **黄** | 一批改动后统一 `closure`、汇总 diff | 汇总后 **一次** 审 |
| **红** | 改 `docs/` 规范入口、合 `main`、不可逆批量重命名 | **必须人** |

把分级写进团队约定或 `rules/`（一句即可），避免「每一步都问」。

### 3.3 可恢复执行

- **`agent-checkpoint`**：`init` / `append` / `show` / `clear`，JSON 持久化步骤与 `rc`。  
- **`TASK_RUN.md`**：子任务表 `state`（`pending` / `in_progress` / `done` / `blocked`）+ **Next action 只写一步**。  
- 中断后：**读 checkpoint + TASK_RUN**，再跑 Harness；不从零重讲。

### 3.4 长任务不断线（操作清单）

1. **一个任务一个 ID**：`task_id` = `agent-task --session` =（建议）`agent-checkpoint --session`。  
2. **任务表外置**：只认 **`TASK_RUN.md`** 子任务表 + Next action。  
3. **子任务原子化**：每步结束条件最好是 **可机器验**（如 `guardian --fail-on-p0` 退出码 0），再解锁下一步。  
4. **对话只当 UI**：新开会话 → 先读外置状态，再动手。

### 3.5 按需加载上下文（减冗余）

**体系化分级（T0–T5）与「旧稿治理」边界**：见 **`docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`**；整理/合并/归档执行边界见 **`docs/DOC_MAINTENANCE_GUIDE.md`**。

| 手段 | 做法 |
|------|------|
| **Skill** | `AGENTS.md` 只保留技能名 + 一句触发；**`openskills read`** 按需拉 `SKILL.md` |
| **Harness** | **`agent-bundle --task "…"`** 生成当次小包，避免每次贴全书 |
| **「RAG」替代** | 无向量库时：**精确路径 + grep/读文件**；在 **`TASK_RUN.md`** 增加 **「References」** 小节（3～5 行路径列表） |
| **会话摘要** | 每完成一子任务，**3～5 行**写入 checkpoint 或 `TASK_RUN.md` 的 **Log**；后续轮次 **只读摘要 + 指针** |

### 3.6 角色：实现 / 守门 / 文档（同一 Cursor）

不必多进程多模型：**不同会话**、**不同规则侧重**或 **不同任务卡前缀** 切换角色即可。

| 角色 | 侧重 Harness / 技能 |
|------|---------------------|
| **实现** | `ufc-layer-domain-feature`、`ufc-structured-io`；改完 **`guardian` / `naming`** |
| **守门** | `guardian --rules …`、`pillar-loop`、`agent-slow-loop` |
| **文档** | `doc-structure`、`plan-checks`；**改 `docs/` 规范须明确授权** |

可用 Cursor TODO **按列**推进，避免「实现 + 守门」混在同一段提示里。

---

## 四、命令速查（与本区强相关）

```text
# 任务卡（真相源）
python ufc_harness/run_harness.py agent-task init --session <task_id> --goal "…"
python ufc_harness/run_harness.py agent-task status --session <task_id>
python ufc_harness/run_harness.py agent-task validate --session <task_id> [--strict]

# 会话步骤 JSON
python ufc_harness/run_harness.py agent-checkpoint init --session <task_id> --goal "…"
python ufc_harness/run_harness.py agent-checkpoint append --session <task_id> --label … --harness-cmd "…" --rc …

# 上下文小包 + 慢思考复盘
python ufc_harness/run_harness.py agent-bundle --task "…"
python ufc_harness/run_harness.py agent-slow-loop [--from-report …]

# 默认设计计划根（doc-structure / plan-checks）
# 见 harness_config paths.plan_relative_to_ufc（默认 design_plan）；可设 UFC_DEFAULT_PLAN
```

---

## 五、与 `closure_loop_checklist.json` 的关系

闭环节点、MCP、技能列表的 **机器可读摘要** 见 **`ufc_harness/closure_loop_checklist.json`**（`sources.document_tiers_md` → **`docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`**）；本 Playbook 偏 **人类可读编排**，二者互补。

---

*修订时：目录分区以 `rules/ufc-directory-layout.mdc` 为准；Harness 子命令以 `ufc_harness/README.md` 为准。*
