# UFC Harness（`ufc_harness/`）

与 **UFC 仓库** 同级的辅助工具集：文档结构/链接检查、Fortran 命名扫描、CMake 构建触发、算法与合同粗映射等。  
**路径约定**：本目录须位于 `UFC/ufc_harness/`（即 `harness_paths.ufc_root() == 本目录的父目录`）。

## 快速开始

```text
# 在任意目录执行（使用绝对路径亦可）
# 默认 --plan 根目录 = UFC/design_plan（见 harness_config paths.plan_relative_to_ufc；可用 UFC_DEFAULT_PLAN 覆盖）
python UFC/ufc_harness/run_harness.py plan-checks
python UFC/ufc_harness/run_harness.py code-templates-ssot
python UFC/ufc_harness/run_harness.py reports-root-guard
python UFC/ufc_harness/run_harness.py doc-structure
python UFC/ufc_harness/run_harness.py show-config
python UFC/ufc_harness/run_harness.py build --status
python UFC/ufc_harness/run_harness.py change-package validate --change-id <change_id> [--strict]
python UFC/ufc_harness/run_harness.py discipline verify [--touch-path <rel> ...] [--strict]
```

**CI（monorepo）**：`ufc-ci.yml` 的 **Harness doc / SSOT** job 在 `UFC/` 下执行 `npm ci`（安装 `@fission-ai/openspec`）、`npx openspec --version`，并运行 `python scripts/ci/check_change_packages_strict.py --ufc-root UFC`（对含 `proposal.md` 的每个 `plan/changes/*` 做 **`change-package validate --strict`**）。

- **`plan-checks`**：依次运行 `doc_structure_checker` + `cross_ref_validator` + **`reports_root_md_guard`**（`REPORTS/` 根目录 `*.md` 行数门禁，见 `harness_config.reports_root_md_guard`）+ **`scan_code_templates_ssot.py`**（默认 `docs/02_Developer_Guide/Code_Templates/` 的 `.f90`/`.md`，**以及** `docs/02_Developer_Guide/` 下其余 `.md`（跳过 `Code_Templates/`），**以及** `docs/03_Domain_Pillars/` 的 `.md` 内 Fortran 围栏；写 `REPORTS/code_templates_ssot_scan.md`）。当前仓库若存在大量历史坏链，`cross_ref` 可能非零退出；可先只用 **`doc-structure`** 做门禁，或逐步修链后再启用 `plan-checks`。模板扫描可单独运行 **`code-templates-ssot`**；渐进合入 CI 时可用 **`code-templates-ssot --warn-only`**。
- **`build`**：透传给 `tools/code_development/build_trigger.py`（与 `run_harness.py` 同参数）。

### 另一类入口：`uhc.py`

按「类别 + 脚本名」转发，例如：

```text
python UFC/ufc_harness/uhc.py doc doc_structure_checker UFC/design_plan
python UFC/ufc_harness/uhc.py code naming_checker
```

运行 `python UFC/ufc_harness/uhc.py` 无参数可列出工具。

## 配置

| 文件 | 作用 |
|------|------|
| [`config/harness_config.json`](config/harness_config.json) | `doc_structure.required_dirs`、`thresholds`、`modules` 工具清单（供人工与文档对齐；**目录规则已由** `doc_structure_checker` **读取**）。 |

不再使用本机绝对路径字段；UFC 根目录一律由 `harness_paths.py` 根据 `ufc_harness` 位置推导。

## 与 `scripts/ci/` 的关系

- **仓库级 Fortran/质量门禁**仍以 [`../../scripts/ci/README.md`](../../scripts/ci/README.md) 为准（如 `check_f90_sub_std.py`）。
- **Harness** 侧重 PLAN 与辅助脚本；可选在 CI 中增加一步：  
  `python UFC/ufc_harness/run_harness.py doc-structure` 或 `plan-checks`。

## 环境变量

| 变量 | 作用 |
|------|------|
| `UFC_CMAKE_GENERATOR` | 覆盖 `build_trigger` 的 CMake `-G`（未设置时：Windows 默认 `MinGW Makefiles`，类 Unix 默认 `Unix Makefiles`）。 |

<a id="harness-engineering-ufc"></a>

## Harness Engineering 与 UFC 对照（五模块 / 三层）

以下术语与分层来自社区通行的 **Harness Engineering** 叙述（模型之外的「缰绳系统」：**Agent = Model + Harness**）。UFC 侧以本目录工具链与仓库根 `AGENTS.md` 闭环为准；IDE 侧工具白名单、人工确认、云 Agent 策略等仍属外部环境，不在本表展开。

### 五个核心模块

| 模块 | 核心关注（一句话） | 在 UFC / 本 harness 中的落点 |
|------|-------------------|------------------------------|
| **Tools（工具）** | 原子化、可组合、可描述的能力单元 | `run_harness.py` / `uhc.py` 转发；`tools/` 下各检查与映射脚本；Agent 侧可选 MCP（见 `closure_loop_checklist.json`） |
| **Knowledge（知识）** | 领域经验按需加载，避免一次性塞满上下文 | `AGENTS.md`、`rules/`、`docs/`、域 `CONTRACT.md`、`skills/**/SKILL.md`；按需 `npx openskills read …` |
| **Observation（观察）** | 任务状态可感知：日志、差异、扫描结果 | `guardian`（含 `--json`）、`closure` / `pillar-loop` 写入的 `REPORTS/*.md`、`build --status` |
| **Action Interfaces（执行接口）** | 把「意图」落成可重复的 CLI / 契约化步骤 | 统一走 `python ufc_harness/run_harness.py <子命令>`；子进程退出码作为门禁信号 |
| **Permissions（权限与边界）** | 能做什么、不能做什么；危险路径需人控 | 架构守卫 P0/P1、仓库目录分区规则、命名与 SIO 规范；删库/越权写生产等仍须 **IDE / CI / 人工** 兜底 |

### 三层架构（工程递进）

| 层次 | 要解决的问题 | UFC / 本 harness 中的典型落点 |
|------|-------------|------------------------------|
| **第一层：基础驾驭** | 让检查与 Agent 辅助流程「跑得动」 | 单次 `doc-structure`、`guardian`、`naming`、单脚本 `uhc.py …` |
| **第二层：约束安全** | 少闯祸：收窄规则、结构化上下文、关键失败可阻断 | `guardian --fail-on-p0`、`pillar-loop` 域柱归因、`agent-bundle` 收口上下文；技能与 MCP 按需启用 |
| **第三层：生产质量** | 可编排、可恢复叙事、可审计、可进 CI | `closure` / `closure --with-ci-gates`、`agent-checkpoint`、`agent-trace`、`agent-slow-loop`；与 `scripts/ci/` 门禁衔接 |

<a id="skill-mcp-agent-rag-ufc"></a>

## Skill · MCP · Agent · RAG 与 UFC 对照（全栈智能化）

以下对照社区文章《Skill+MCP+Agent+RAG 全栈自动化方案》中的**角色分工**与**分层避坑原则**。UFC 以仓库根 `AGENTS.md` 的 **Prompt → Context → Skills → MCP → Agent → Harness → Loop** 为骨架。文中「RAG」若指企业向量库，本仓库未必部署；下表「RAG」一列在 UFC 侧主要对应**结构化文档与合同知识**的按需检索（读文件、`openskills`、搜索），而非替代自建向量服务。

- **机器可读双链**：同主题结构化字段见 [`closure_loop_checklist.json`](closure_loop_checklist.json) 根键 **`skill_mcp_agent_rag_notes`**（`readme_anchor_html_id` = `skill-mcp-agent-rag-ufc`，与本节锚点一致）；科普文链路对照见根键 **`from_chat_to_work_notes`**（[`#from-chat-to-work-ufc`](#from-chat-to-work-ufc)）。

### 四者角色对照

| 技术 | 文章中的定位（一句话） | 在 UFC 仓库中的落点 |
|------|----------------------|---------------------|
| **MCP** | 工具连接层：对接外部系统，定义如何调用 | `closure_loop_checklist.json` → `mcp_servers` 与 `AGENTS.md` MCP 表；在 Cursor/IDE 中**启用**对应服务（配置与密钥在本地，不在仓库） |
| **RAG** | 知识管理层：私有文档与规则，按需检索 | `docs/`、`PLAN/`、各域 `CONTRACT.md`、`REPORTS/` 规范稿；按需打开文件或 `npx openskills read <skill>`；避免把整库长文一次性塞进对话 |
| **Skill** | 流程编排层：SOP、输入输出、约束 | `skills/**/SKILL.md`（如 `ufc-layer-domain-feature`、`ufc-structured-io`）；与 `AGENTS.md` 技能表同步的技能名 |
| **Agent** | 决策调度层：拆任务、选技能/MCP、异常处理 | Cursor/Qoder 等；遵循 `AGENTS.md` 与 `rules/`；**执行与验证**交给 `run_harness.py`（节点 H）与 Loop 反馈 |

### 分层原则（避坑）在 UFC 的落法

| 原则（文章摘要） | UFC 建议 |
|-----------------|----------|
| MCP **只做连接**，不在 MCP 里堆业务逻辑 | 业务规则写在 `docs` / `skills` / Fortran 与 harness **脚本**中；MCP 保持薄封装 |
| RAG **只做知识与检索**，检索结果交给 Skill/Agent 解释 | 检索片段 + 指针路径；复杂判定结合 `guardian` / 合同段落，避免「只信检索摘要」 |
| Skill **只做流程与规范**，复杂决策不硬编码在 Skill 里 | `SKILL.md` 写清触发条件、步骤、边界；跨域大决策由 Agent 结合 harness 报告再拆步 |
| Agent **只做调度**，执行步骤落到可重复命令 | 改 `ufc_core` 后优先跑 `guardian` / `closure`；少在提示词里堆「手搓步骤」，多引用本 README 与 `agent-bundle` 输出 |

### 从 0 到 1 落地清单（UFC 版）

0. **长任务外置状态**（可选）：`python ufc_harness/run_harness.py agent-task init --session <ID> --goal "…"` → 编辑 `plan/tasks/<ID>/TASK_RUN.md`（约定见 `plan/README.md`）；换会话时 `agent-task status --session <ID>`；提交前 `agent-task validate --session <ID> [--strict]`。  
1. **拆任务**：按层/域/功能（L3/L4/L5、`ufc_core` 路径）拆小步；对照 `AGENTS.md` 技能速查表选定 `skills`。  
2. **接 MCP**：在 IDE 启用 checklist 中与任务相关的 MCP；能只读则只读，写入类操作配合人工或分支策略。  
3. **收口知识**：从 `docs/README.md`、`docs/00-快速导航.md`、相关 `CONTRACT.md` 起读；大任务先跑 `agent-bundle --task "…"` 生成上下文包。  
4. **固化 Skill**：对重复工作流 `npx openskills read …` 或迭代 `skills/**/SKILL.md`；保持一 Skill 一事、可组合。  
5. **调度与验证**：Agent 编排「读技能 → 改代码 → 跑 harness」；提交前 `closure` 或至少 `guardian --fail-on-p0` + `naming`；用 `agent-checkpoint` / `agent-trace` 留痕，`agent-slow-loop` 做复盘模板。

<a id="from-chat-to-work-ufc"></a>

### 从「会聊天」到「会干活」：与 UFC / Harness 的一小段对照

科普文把栈串成 **大模型 → Function Calling → MCP → Agent Skills → Agent → 多智能体（A2A）**；UFC 用 **AGENTS.md 闭环**（Prompt→…→Harness→Loop）承接「会干活」：上文 **[Harness Engineering 对照](#harness-engineering-ufc)** 对应「缰绳 / 五模块 / 三层」，本节 **[Skill · MCP · Agent · RAG](#skill-mcp-agent-rag-ufc)** 对应「手 + 领域流程 + 知识按需」；多智能体与 A2A 以 **IDE/平台** 为主，仓库内以 **`closure` / `pillar-loop`** 做多步编排与归因（非 A2A 协议实现）。

| 文章概念 | 在 UFC 中的落点（简） |
|----------|----------------------|
| 大模型「只聊天」 | 须用 **Harness**（如 `guardian`、`closure` 报告）把改动**验回**仓库，避免只说不验 |
| Function Calling | 各 IDE 差异大；可重复动作优先 **MCP + `run_harness.py`** |
| MCP | `closure_loop_checklist.json` → `mcp_servers` |
| Skills 三级加载 | `skills/**` + `openskills read` |
| Agent 干活 | Agent 调度 + **`run_harness.py`（节点 H）** |
| 多 Agent / A2A | 仓库外协作为主；内建以 **编排子命令 + 域柱报告** 拆步与归因 |

- **机器可读**：[`closure_loop_checklist.json`](closure_loop_checklist.json) 根键 **`from_chat_to_work_notes`**（锚点 `from-chat-to-work-ufc`）；与 **`skill_mcp_agent_rag_notes`**、Harness 锚点 **`harness-engineering-ufc`** 互链。

## Agent 调用模式（闭环节点 H）

Agent（Qoder/Cursor AI）可将 Harness 作为代码库级工具集调用。所有命令在 UFC 根目录执行，输出结构化文本。

| 命令 | CI ID | 用途 | Agent 场景 |
|------|-------|------|-----------|
| `python ufc_harness/run_harness.py doc-structure` | H-DOC-01 | 目录结构完整性 | 新增文件后验证目录分区 |
| `python ufc_harness/run_harness.py plan-checks` | H-DOC-01/02 | 结构 + 交叉引用 + REPORTS 根 md 门禁 + Fortran SSOT（Code_Templates + DevGuide 其余 md + Domain Pillars） | 新增文档/模板后验证 |
| `python ufc_harness/run_harness.py guardian` | H-ARCH-01 | 架构守卫全量扫描 | 修改 USE 关系后验证 |
| `python ufc_harness/run_harness.py guardian --fail-on-p0` | H-ARCH-01 | P0 规则阻断 | 提交前必须通过 |
| `python ufc_harness/run_harness.py closure` | — | 编排 doc/plan/guardian/naming + `REPORTS/loop_run_*.md` | 单次闭环自动化 |
| `python ufc_harness/run_harness.py closure --with-pillar-loop` | — | 闭环节奏 + 默认 `pillar-loop --dry-run`（命名后） | 域柱报告骨架，无第二次全量 Guardian |
| `python ufc_harness/run_harness.py pillar-loop` | — | Guardian JSON 按 P1–P6 分桶 + `REPORTS/pillar_decision_*.md` | P0 域柱归因与推荐命令 |
| `python ufc_harness/run_harness.py closure --fail-on-p0` | H-ARCH-01 | 同上且 P0 阻断退出 | 与 guardian `--fail-on-p0` 对齐 |
| `python ufc_harness/uhc.py code naming_checker` | H-NAM-03 | 命名规范扫描 | 新增 TYPE/模块后验证 |
| `python ufc_harness/run_harness.py build --status` | — | 构建状态 | 编译后验证 |
| `python ufc_harness/run_harness.py show-config` | — | 显示配置 | 调试配置问题 |

**Agent Harness 扩展**（对照「上下文工程 / 断点叙事 / 可观测性 / 慢思考复盘」；输出均在 `REPORTS/`）：

| 命令 | 用途 |
|------|------|
| `python ufc_harness/run_harness.py agent-bundle [--task "..."] [--json-sidecar]` | 导出闭环图 + checklist 中的 harness 链 + 层路径提示 |
| `python ufc_harness/run_harness.py agent-checkpoint init \| append \| show \| clear --session ID ...` | 会话 JSON：`agent_session_<ID>.json` |
| `python ufc_harness/run_harness.py agent-trace log \| tail [--cmd ...] [--rc N] [--ms N]` | JSONL 飞行记录：`agent_harness_trace.jsonl` |
| `python ufc_harness/run_harness.py agent-slow-loop [--from-report PATH]` | 生成慢思考复盘模板（默认挂最新 `loop_run_*.md`） |
| `python ufc_harness/run_harness.py agent-task init \| status \| validate \| list [--session ID] [--goal "..."]` | 长任务卡 `plan/tasks/<session>/TASK_RUN.md`（约定见 `plan/README.md`；模板 `ufc_harness/templates/TASK_RUN.template.md`） |
| `python ufc_harness/run_harness.py change-package validate --change-id ID [--strict]` | `plan/changes/<ID>/` 变更包四制品 + spec 关键字（默认 warn-only） |
| `python ufc_harness/run_harness.py discipline verify [--touch-path REL ...] [--strict]` | 按 `ufc_governance/triad/discipline/manifest.v1.json` 聚合 harness 建议 |

测试/CI 可将 `UFC_AGENT_REPORTS_DIR` 指到临时目录，避免污染 `REPORTS/`；**`agent-task`** 可将 `UFC_PLAN_ROOT` 指到临时目录，避免污染 `plan/`。

**编排与目录总览（七段闭环、状态机、按需加载）**：[`plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md`](../plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md)

### Agent 调用约定
- 所有命令从 `UFC/` 根目录执行
- 非零退出码 = 检查未通过，须修复后重跑
- `plan-checks` 的 `cross_ref` 可能因历史坏链非零退出，可先用 `doc-structure` 做门禁

## Closure loop（`closure` 子命令）

单次编排 **doc-structure → plan-checks → guardian（JSON 解析）→ naming**，在 `REPORTS/` 下生成时间戳报告 `loop_run_YYYYMMDD_HHMMSS.md`（含各步退出码、Guardian P0/TYPE-003 摘要、**Next actions** 与外部缺口说明）。

```text
# 在 UFC 仓库根目录执行
python ufc_harness/run_harness.py closure
python ufc_harness/run_harness.py closure --fail-on-p0
python ufc_harness/run_harness.py closure --plan UFC/design_plan --scan UFC/ufc_core
python ufc_harness/run_harness.py closure --skip-plan-checks --skip-doc-structure
python ufc_harness/run_harness.py closure --dry-run
python ufc_harness/run_harness.py closure --with-ci-gates
python ufc_harness/run_harness.py closure --with-pillar-loop
python ufc_harness/run_harness.py closure --with-pillar-loop --pillar-loop-full
```

- **`--dry-run`**：不启动子进程，仍写入 `REPORTS/loop_run_*.md`（用于验证路径与报告模板）；退出码恒为 `0`。
- **`--with-pillar-loop`**：在**命名检查之后**编排 `pillar-loop`；默认等价于 **`pillar-loop --dry-run`**（不写第二次全量 Guardian JSON，仅生成 `REPORTS/pillar_decision_*.md` 骨架）。与 **`--pillar-loop-full`** 联用时运行完整 `pillar-loop`（会再跑一次全量 Guardian）。
- **`--with-ci-gates`**：在命名检查之后，若存在 `scripts/ci/check_harness_gates.py`，则对其传入 `ufc_core` 路径执行（子进程 `cwd` 为 UFC 根，便于生成 **`REPORTS/harness_gate_report.json`**）；stdout/stderr 尾部写入报告 **CI harness gates excerpt**。
- **`--fail-on-p0`**：若全量 guardian JSON 中 P0>0，最终以退出码 1 结束（报告仍会写入）。
- **命名检查**：`closure` 内对 `naming_checker` 使用捕获输出，完整细节见报告末尾 **Naming checker excerpt**；交互式全量输出请直接运行 `run_harness.py naming`。
- **机器可读清单**（Skills 调用模板 + MCP 表，**不**代替 IDE 内 MCP 配置）：[`closure_loop_checklist.json`](closure_loop_checklist.json)（含 `through_domain_pillars` → [`pillar_loop_config.json`](pillar_loop_config.json)；Skill/MCP/Agent/RAG 见 **`skill_mcp_agent_rag_notes`**；科普链路「会聊天→会干活」见 **`from_chat_to_work_notes`**）。

## Pillar-loop（`pillar-loop` 子命令）

按 **P1–P6 贯通域柱**（与 `REPORTS/UFC_L3L4L5_二元重构蓝图规范_v1.0.md` §2.1 一致：Material / Element / Contact·Interaction / LoadBC / Output / WriteBack）对 **Guardian `--json` 全量结果**按路径 `path_markers` 分桶，对含 **P0** 的域柱输出**确定性**推荐命令（`DEP` / `HOT` / `GLB` / `WB` / `TYPE-003` 等 → 收窄 `guardian --rules` + `naming` + 条件 `sio_checker`），并写入 `REPORTS/pillar_decision_YYYYMMDD_HHMMSS.md`。二元结构 **冷/热轴** 写在 `pillar_loop_config.json` 的 `binary_structure` 字段，**非 LLM**。

```text
python ufc_harness/run_harness.py pillar-loop
python ufc_harness/run_harness.py pillar-loop ufc_core/L4_PH/Material
python ufc_harness/run_harness.py pillar-loop --dry-run
python ufc_harness/run_harness.py pillar-loop --fail-on-p0
```

- **`--dry-run`**：不执行 Guardian，仍生成报告骨架（用于 CI 路径探测）。
- **与 `closure` 关系**：`closure` 偏全链路门禁报告；`pillar-loop` 偏 **域柱垂直切片** 的 P0 归因与下一步命令序列。

## 闭环反馈（节点 L）

Harness 输出作为反馈信号驱动以下闭环动作：

| Harness 输出 | 反馈目标 | 动作 |
|-------------|---------|------|
| `doc-structure` 失败 | `UFC/docs/`、`REPORTS/` | 修正目录结构或更新 README 索引 |
| `plan-checks` 坏链 | `UFC/docs/`、`REPORTS/` | 修复死链接，更新 `00-快速导航.md` |
| `guardian` P0 阻断 | `ufc_core/` .f90 源码 | 修正 USE 依赖、热路径违规 |
| `naming_checker` 违规 | `ufc_core/` .f90 源码 | 对齐 `rules/ufc-naming.mdc` |
| 全部通过 | 记忆 / 技能 | 更新「契约与文档协同」记忆，标记合规 |

Agent 应在每次修改后运行相关 Harness 检查，将结果反馈到 `AGENTS.md` 的上下文链路中。

## 设计文档

- [`../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_Harness_Engineering_系统设计.md`](../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_Harness_Engineering_系统设计.md)
- [`../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_Harness_Engineering_开展计划.md`](../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_Harness_Engineering_开展计划.md)
- Phase 1 说明（可能与实现演进不同步时以本 README + `harness_config.json` 为准）：[`../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_Harness_Phase1_文档管理工具集.md`](../docs/05_Project_Planning/PPLAN/05_实施指南/UFC_Harness_Phase1_文档管理工具集.md)
