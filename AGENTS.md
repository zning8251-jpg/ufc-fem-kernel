# AGENTS — UFC 闭环体系

## 闭环架构：Prompt → Context → Skills → MCP → Agent → Harness → Loop

```
graph LR
    P[Prompt 用户输入] --> C[Context 上下文加载]
    C --> S[Skills 技能匹配]
    S --> M[MCP 外部工具]
    S --> A[Agent 执行]
    M --> A
    A --> H[Harness 仓库工具]
    H --> L[Loop 反馈]
    L --> C
    L --> S
```


| 节点          | 载体                                                           | 说明                     |
| ----------- | ------------------------------------------------------------ | ---------------------- |
| **Prompt**  | 用户查询                                                         | 触发整个闭环的入口              |
| **Context** | `AGENTS.md` + `rules/` + `docs/README.md` + 记忆               | 自动加载的上下文               |
| **Skills**  | `skills/**/SKILL.md`                                         | 按需匹配的专业能力              |
| **MCP**     | brave-search, github, playwright, fetch, sequential-thinking | 外部工具（搜索/代码/浏览器/推理）     |
| **Agent**   | Qoder/Cursor AI                                              | 执行主体                   |
| **Harness** | `ufc_harness/run_harness.py`                                 | 仓库级工具集（命名检查/架构守卫/文档健康） |
| **Loop**    | 记忆更新 + 文档修正 + 技能迭代                                           | 执行结果反哺体系               |


---

## Available Skills

When users ask you to perform tasks, check if any of the available skills below can help complete the task more effectively. Skills provide specialized capabilities and domain knowledge.

How to use skills:

- Invoke: `npx openskills read <skill-name>` (run in your shell)
  - For multiple: `npx openskills read skill-one,skill-two`
- The skill content will load with detailed instructions on how to complete the task
- Base directory provided in output for resolving bundled resources (references/, scripts/, assets/)

Usage notes:

- Only use skills listed in  below
- Do not invoke a skill that is already loaded in your context
- Each skill invocation is stateless

fem-kernel-architectureUFC / FEM kernel architecture: six layers, domain/feature sets, Desc/Algo/Ctx/State, four chains (theory/logic/computation/data), F90 kernel evolution. Use for architecture design, layer boundaries, bridge patterns, and aligning code with UFC docs. Entry: UFC/docs/README.md, docs/05_Project_Planning/PPLAN/README.md; plan/repo map: UFC/docs/00-快速导航.md#plan-to-repo-links. Docs: UFC/docs/; code: UFC/ufc_core/.project

fem-kernel-api-designFinite-element kernel public API design: stable boundary vs internal implementation, deprecation/migration, Python/C bindings. Use when user asks about API design, stable API, FFI, or backward compatibility. Pairs with fem-kernel-architecture and fem-kernel-data-contract.project

fem-kernel-data-contractData contracts between layers/domains: stable fields, versioning, serialization, traceable data chain. Use when user mentions data contract, interface contract, compatibility, or serialization across L3/L4/L5.project

fem-kernel-extensibilityExtension points: UEL, UMAT, user loads, registration and Bridge to L4_PH/L5_RT. Use for plugin/UEL/UMAT design or second-party extension APIs.project

fem-kernel-observabilityObservability: counters, timers, diagnostics, logging and error propagation aligned with error architecture; causal narrative as a cross-cutting trace view (not a fifth chain). Use for profiling hooks, debug support, cross-layer status propagation, or trace/span annotations for trigger/upstream fields.project

fem-kernel-test-designTestability: unit/integration/E2E, mocks, injection boundaries, minimal test units. Use with fem-kernel-verification for CI and regression strategy.project

fem-kernel-verificationVerification: patch tests, benchmarks, NAFEMS/ABAQUS-style references, V&V checklists. Use when user asks verification, acceptance tests, or regression cases for constitutive/element/solver behavior.project

ufc-layer-domain-featureUFC layer-domain-feature subroutine/module templates and implementation: six layers, four TYPE kinds, four chains, HYPLAS-aligned Populate/hot path. SIO: unified *_Arg bundle with [IN]/[OUT] comments—no inp/out pair; 5-tuple (4 types + args) or 6-tuple (+ RT_Com_Base_Ctx). Triggers: ufc gen, ufc template, explicit Layer+Domain+Feature. Must read UFC/docs/README.md + docs/05_Project_Planning/PPLAN/README.md then v5.0 + docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md. Skill file: skills/ufc-layer-domain-feature/SKILL.md.project

ufc-structured-ioUFC Principle #14 结构化 IO 可执行技能：统一 *_Arg（[IN]/[OUT] 注释）+ 五参 (desc,state,algo,ctx,args) 或六参 (+RT_Com_Base_Ctx,args)；弃用 inp/out 对偶（R-01b 仅遗留）。含 INTENT 禁令、Harness SIO-01~14、迁移与域推广矩阵。触发：structured-io、*_Arg、五参六参、_Proc.f90、Principle #14、SIO 检查。project

ufc-governance-triadUFC 工程治理三件套编排：规格环（plan/changes 变更包）、流程环（triad/flow PLAYBOOK + TASK_RUN）、纪律环（manifest + Harness）。触发：三件套、OpenSpec 等价、变更包、change-package、discipline verify、ufc_governance、铁三角、What/How/Quality。必读 ufc_governance/README.md 与 triad/CROSSWALK.md。project

ufc-domain-pillar-closure[PLACEHOLDER] UFC 贯通域柱闭环固化技能。Use whenever the user asks to synchronize or harden an L3/L4/L5 domain pillar, mentions 贯通域柱, L3/L4/L5 同步改造, Field 模板域, Def/Ops/Brg/Proc 判定.project

ufc-naming-checkerUFC Fortran 命名规范可执行技能：按场景（MODULE、四型+Args、TBP 短名、公开/私有过程、变量/常量、Bridge/LoadBC）写码前加载、写码后跑 Harness naming；真源 rules/ufc-naming.mdc；脚本 tools/check_naming_l3l4l5l6.py。触发：命名、naming、TBP、Desc/State/Algo/Ctx、Layer_Domain_VerbObj、规范校验。project

ufc-solver-router[PLACEHOLDER] UFC 求解器类型路由技能。基于 RT_SolverType 枚举，UMAT/VUMAT 选择。触发：求解器路由、RT_SolverType、solver-router。project

ufc-domain-interaction[PLACEHOLDER] UFC Interaction 域完整性补全技能。Contact Pairs/Surface Interaction/Friction。触发：Interaction 域、接触域、Contact Pairs。project

ufc-domain-keyword[PLACEHOLDER] UFC KeyWord 域完整性补全技能。ABAQUS 关键字语法树与参数约束。触发：KeyWord 域、关键字解析、Parser。project

ufc-domain-output[PLACEHOLDER] UFC Output 子域完整性补全技能。Field/History/Nodal/Element Output。触发：Output 域、场变量输出、ODB。project

doc-coauthoringGuide users through a structured workflow for co-authoring documentation. Use when user wants to write documentation, proposals, technical specs, decision docs, or similar structured content.project

docxCreate, read, edit, or manipulate Word documents (.docx). Triggers: Word doc, .docx, professional documents with formatting, report/memo/letter/template.project

frontend-designCreate distinctive, production-grade frontend interfaces with high design quality. Use for web components, dashboards, landing pages, React components, HTML/CSS layouts.project

internal-commsWrite internal communications: status reports, leadership updates, company newsletters, FAQs, incident reports, project updates.project

mcp-builderGuide for creating high-quality MCP servers that enable LLMs to interact with external services through well-designed tools.project

pptxAny .pptx file involved: create slide decks, parse text from .pptx, edit presentations. Trigger: deck, slides, presentation, .pptx filename.project

skill-creatorCreate new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch or update an existing skill.project

theme-factoryToolkit for styling artifacts with a theme. 10 pre-set themes with colors/fonts for slides, docs, reports, HTML landing pages.project

xlsxAny spreadsheet task: .xlsx, .xlsm, .csv, .tsv. Create, edit, fix spreadsheets, compute formulas, formatting, charting, data cleaning.project

---

## Skills 选用速查（UFC / 有限元内核）


| 用户意图                                            | 优先技能                                      |
| ----------------------------------------------- | ----------------------------------------- |
| 给定 L3/L4/L5 + 域 + 功能集，**生成模板并改 f90**            | `ufc-layer-domain-feature`                |
| 六层架构、域划分、四链、Bridge、**不写具体子程序骨架**                | `fem-kernel-architecture`                 |
| 层间/域间 **类型字段、版本、序列化**                           | `fem-kernel-data-contract`                |
| **对外 API / 废弃策略 / Python·C 绑定**                 | `fem-kernel-api-design`                   |
| **UEL / UMAT / 插件注册**                           | `fem-kernel-extensibility`                |
| **日志、错误传播、计时、诊断、trace/因果标注（非第五链）**              | `fem-kernel-observability`                |
| **单测/集成测/Mock 边界**                              | `fem-kernel-test-design`                  |
| **Patch test、NAFEMS、验收与回归题**                    | `fem-kernel-verification`                 |
| **三件套 / 变更包 / 治理流程 / discipline manifest**      | `ufc-governance-triad`                    |
| **贯通域柱闭环固化、Field 模板域推广**                        | `ufc-domain-pillar-closure` [PLACEHOLDER] |
| **_Proc.f90 生成/校验/迁移、*_Arg、SIO 检查**             | `ufc-structured-io`                       |
| **命名规范检查、模块/TYPE/过程/变量名校验**                     | `ufc-naming-checker`                      |
| **求解器类型路由、UMAT/VUMAT 选择**                       | `ufc-solver-router` [PLACEHOLDER]         |
| **Interaction 域、Contact Pairs、Friction**        | `ufc-domain-interaction` [PLACEHOLDER]    |
| **KeyWord 域、关键字解析、Parser**                      | `ufc-domain-keyword` [PLACEHOLDER]        |
| **Output 域、Field/History/Nodal/Element Output** | `ufc-domain-output` [PLACEHOLDER]         |
| **新建或改版技能本身**                                   | `skill-creator`                           |


调用方式：`npx openskills read <skill-name>`（多个用逗号分隔）。

---

## MCP 服务器

Agent 可使用以下 MCP 服务器扩展能力：


| MCP 服务器               | 工具                                                          | 适用场景                                  |
| --------------------- | ----------------------------------------------------------- | ------------------------------------- |
| `brave-search`        | `brave_web_search`, `brave_local_search`                    | 查找 ABAQUS 手册、NAFEMS 基准、Fortran 标准引用   |
| `github`              | `search_code`, `get_file_contents`, `create_pull_request` 等 | 搜索 UFC 上游源码、创建 PR、查阅 Issue            |
| `playwright`          | `browser_navigate`, `browser_snapshot`, `browser_click` 等   | 验证 Web UI（ufc-architecture-dashboard） |
| `fetch`               | `fetch`                                                     | 抓取在线文档、手册页面                           |
| `sequential-thinking` | `sequentialthinking`                                        | 复杂多步推理（架构设计、重构决策）                     |


---

## Harness 集成（Agent 工具箱）

Agent 可通过 `python UFC/ufc_harness/run_harness.py` 调用仓库级工具：


| 命令                                       | 用途                                                                                                                            | CI 门禁       |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------- |
| `run_harness.py change-package validate` | `plan/changes/<id>/` 四制品与 spec 关键字检查                                                                                          | —           |
| `run_harness.py discipline verify`       | 按 `ufc_governance/triad/discipline/manifest.v1.json` 提示 harness 义务                                                            | —           |
| `run_harness.py doc-structure`           | 文档结构完整性检查                                                                                                                     | H-DOC-01    |
| `run_harness.py plan-checks`             | 文档结构 + 交叉引用 + `REPORTS` 根 md 行数门禁 + Fortran SSOT（Code_Templates + `docs/02_Developer_Guide` 其余 md + `docs/03_Domain_Pillars`） | H-DOC-01/02 |
| `run_harness.py code-templates-ssot`     | `Code_Templates` + `docs/02_Developer_Guide`（除模板目录）+ `docs/03_Domain_Pillars` 的 md 围栏 Fortran 真源扫描                            | H-DOC-01/02 |
| `run_harness.py guardian`                | 架构守卫（DEP/GLB/HOT 规则）                                                                                                          | H-ARCH-01   |
| `run_harness.py guardian --fail-on-p0`   | P0 规则阻断检查                                                                                                                     | H-ARCH-01   |
| `uhc.py code naming_checker`             | 命名规范扫描                                                                                                                        | H-NAM-03    |
| `run_harness.py build --status`          | 构建状态检查                                                                                                                        | —           |


更多见 `UFC/ufc_harness/README.md`。

---

## Repository rules（Agent 必读）

以下约束在 UFC 仓库内修改/新增文件时生效：

1. **目录分区**：`ufc_core/` **仅**放六层**生产代码**（禁止任务草稿、调研长文、非构建产出）；`plan/`（小写）放**运行任务**（`tasks/`、`backlog/`、`archive/`、`**changes/`** 规格变更包）；**Harness 默认 `--plan` 设计骨架**在 `**design_plan/`**（见 `harness_config.json` 的 `paths.plan_relative_to_ufc`，勿与 `plan/` 混桶；Windows 不可用 `PLAN`/`plan` 仅靠大小写区分）；`**ufc_governance/`** 放三件套模板与治理叙事迁移桶（见 `ufc_governance/README.md`，与 `docs/` 真源关系见 `ufc_governance/MIGRATION.md`）；`tools/` 放可复用脚本；`config/` 放配置；`docs/` 放规范文档；`REPORTS/` 放 Harness 等报告；`build/` 放编译产物；`ufc_harness/` 放控制系统；`scripts/` 放维护脚本。禁止跨桶混放。细则见 `rules/ufc-directory-layout.mdc`。
2. **Fortran**：新增/修改 `.f90` 须符合 F90/2003；可用 `gfortran -std=f2003 -fsyntax-only` 语法检查。细则见 `rules/ufc-fortran-syntax.mdc`。
3. **命名规范**：模块 ≤3 段、公开过程 `Layer_Domain_VerbObj`、TBP 短动词、常量 UPPER_SNAKE_CASE。细则见 `rules/ufc-naming.mdc`。
4. **SIO / `*_Arg`**：层间边界、L5 `_Proc`、Harness 为硬 SIO 主战场。L3 及小域不强制每个过程套 `*_Arg`。细则见 `skills/ufc-structured-io/SKILL.md` 和各域 `CONTRACT.md` 的 SIO 小节。
5. **文档与实现对齐**：实现与 `CONTRACT.md` / PPLAN 冲突时，先对齐合同再改实现，或显式修订文档并说明原因。**默认不修改**设计文档，除非用户明确要求。
6. **执行**：自行执行构建/检查/脚本，不给出「请用户运行」的说明。
7. **范围**：只改与当前任务相关的文件；避免无关大重构、未请求的长篇文档或批量格式化。

---

**入口文档**：`UFC/docs/README.md`（`[#docs-root-three-buckets](docs/README.md#docs-root-three-buckets)` 三桶：`docs`/`design_plan`/`plan`）| **工程治理三件套**：`UFC/ufc_governance/README.md` | **快速导航**：`UFC/docs/00-快速导航.md` | **Harness**：`UFC/ufc_harness/README.md` | **规则索引**：`UFC/rules/README.md` | **工具索引**：`UFC/tools/README.md`