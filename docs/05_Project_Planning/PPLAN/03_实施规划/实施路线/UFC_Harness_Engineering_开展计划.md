# UFC Harness Engineering 开展计划

> **文档类型**：实施路线 / 检查项清单  
> **创建日期**：2026-03-24  
> **上位设计**：[UFC Harness Engineering 系统设计方案](../../05_实施指南/UFC_Harness_Engineering_系统设计.md)（五层架构、组件与接口设想）  
> **PLAN 入口**：[`../../README.md`](../../README.md)  
> **Agent 与技能**：[`../../../../AGENTS.md`](../../../../AGENTS.md)、[`.cursor/AGENT.md`](../../../../.cursor/AGENT.md)（与 `AGENTS.md` 技能表对齐）

本文在「系统设计」之上，给出 **Harness 五模块 ↔ UFC 资产映射**、**四类工作流挂载表**，以及 **Phase A / B / C** 可勾选检查项，便于排期与验收。

---

## 一、目标与边界

- **目标**：为人机协同 Agent 建立**生产向 Harness** 能力，覆盖 **文档管理、代码开发、算法落实、UFC 架构完善与打通**，且与 **HYPLAS 约定**（Populate 冷路径、热路径零 L3 等）不冲突。  
- **边界**：Harness 主要作用于 **开发时、CI、编排层**；**不在 L4_PH 热路径内**运行 LLM 或重型编排逻辑。  
- **原则对齐**：尽量减少模型记忆负载、规则进系统、小工具、状态持久化、可观测、分层 Evaluation（与 Harness Engineering 通用五原则一致）。

---

## 二、五模块 ↔ UFC 映射

| Harness 模块 | UFC 中已有对应 | 开展期建议补强 |
|--------------|----------------|----------------|
| **Environment** | 工作区 `UFC/`、`ufc_core/`；[`PLAN`](../../README.md)；可执行 `gfortran` / `scripts/ci` | 明确 **允许写入根**（如仅 `UFC/`、`scripts/`）；构建/生成物目录约定与文档同步 |
| **Tool** | `Read`/`Grep`/`Shell`；`npx openskills read <skill>`；[`scripts/ci`](../../../../scripts/ci/) 下各检查脚本 | **工具清单化**：单一职责 CLI（语法、合同引用、`!>>>` 抽检、链接检查等），避免「万能脚本」 |
| **Control** | [`.cursor/rules`](../../../../.cursor/rules/)、[`AGENTS.md`](../../../../AGENTS.md) Repository rules、质量门脚本 | **显式策略**：对话/任务最大步数或超时；危险操作白名单；阶段机（文档→设计→改码→验证） |
| **Memory** | [`PLAN/README`](../../README.md)、[`archive/PLAN_History/99_归档库`](../../../archive/PLAN_History/99_归档库/README.md)、`域合同卡`（当前工作区未收录）、Populate 写入的 L4 槽 | **任务状态外置**：固定模板（目标/层域/已改文件/下一步/阻塞）；不全量堆入 Prompt |
| **Evaluation** | `gfortran -std=f2003 -fsyntax-only`；`scripts/ci/*`；技能 `fem-kernel-verification` / `fem-kernel-test-design`；合同卡 | **分层验收**：文档（链接、与实现一致）；代码（语法+最小构建）；算法（FourChain/验证清单）；架构（合同 diff + [`BRIDGE_INDEX`](../../../../ufc_core/L3_MD/Bridge/BRIDGE_INDEX.md)） |

---

## 三、四类工作流 × Harness

| 工作流 | Environment | 核心 Tool | Control | Memory | Evaluation |
|--------|-------------|-----------|---------|--------|--------------|
| **文档管理** | `UFC/PLAN` | 链接检查、归档规范、入口 `README` 同步 | 大稿进 `99_归档库` | `PLAN/README` + `99_归档库/README` | 死链扫描；`AGENTS.md` ↔ `.cursor/AGENT.md` 技能名一致（可选脚本） |
| **代码开发** | `ufc_core/**/*.f90` | `gfortran`；`ufc-layer-domain-feature`；[`check_f90_sub_std.py`](../../../../scripts/ci/check_f90_sub_std.py) 等 | 改动范围；禁止无关大重构 | `UFC_检查清单_每轮必查_简化版`（当前工作区未收录）会话断点 | 语法；可选增量测试 |
| **算法落实** | L4 域目录 + PLAN 锚点 | FourChain / HYPLAS 只读路径；Bridge 真值表 | 先合同后实现 | `contracts` + Populate 数据链 | Patch/验证技能；数值对照 |
| **架构完善与打通** | 全仓只读 + 定点写 | `fem-kernel-architecture` / `fem-kernel-data-contract`；域清单 | 按域/链拆任务 | `UFC_域改造总清单`（当前工作区未收录）、[`M0` 审计](../域分级重构/M0_L4L5_热路径违规USE_audit.md) | 合同↔代码引用；Populate/RT 路径检查 |

---

## 四、Phase A — 壳与规范落地（建议 1～2 周）

| # | 检查项 | 完成 |
|---|--------|------|
| A1 | 在仓库中确立 **Harness 工具目录**（建议 `scripts/harness/` 或沿用 `scripts/ci/` 并文档说明），并写入本计划或 [`系统设计`](../../05_实施指南/UFC_Harness_Engineering_系统设计.md) 的「Tool」一节引用 | ☐ |
| A2 | 定义 **任务状态 / 会话断点** 落盘模板（可与现有检查清单模板合并），路径固定、Agent 可写 | ☐ |
| A3 | 在 [`AGENTS.md`](../../../../AGENTS.md) 或 `.cursor/rules` 中增加 **一句强制约定**：长任务须更新状态文件（Control + Memory） | ☐ |
| A4 | **Environment** 写入边界写进文档（允许改哪些目录、禁止哪些根路径操作） | ☐ |
| A5 | 与 **系统设计** 中的 Environment/Tool 表做一次 **路径对账**（相对路径、是否仍存在 `verification/` 等） | ☐ |

---

## 五、Phase B — Evaluation 与 CI 对齐（持续迭代）

| # | 检查项 | 完成 |
|---|--------|------|
| B1 | 现有 `scripts/ci/*` 归入 **统一入口**（如 `run_ci_checks.ps1` / `make check` 文档化） | ☐ |
| B2 | **文档类**：PLAN 死链抽检或手动周期；`AGENTS` ↔ `.cursor/AGENT` 技能集一致（脚本或 PR 自检清单） | ☐ |
| B3 | **代码类**：PR 或本地默认跑 **Fortran 语法** + **子程序标准**（已有脚本则挂接） | ☐ |
| B4 | **架构类**：合同变更时触发 **引用文件列表** 或人工 Review 清单（与 `CONTRACT_*` 维护说明一致） | ☐ |
| B5 | 将 **Evaluation 结果** 与 Harness 设计文档中的 Evaluator 概念对齐（命名、职责、落盘位置） | ☐ |

---

## 六、Phase C — 与 UFC 六层叙事对齐（中长期）

| # | 检查项 | 完成 |
|---|--------|------|
| C1 | **L6_AP**：若引入 Job/编排 UI，明确 Control/Memory 与 Step 的映射（设计层可先占位 ADR） | ☐ |
| C2 | **L5_RT**：`step_idx`/`incr_idx` 等日志与 **可观测** 要求对齐 `fem-kernel-observability` 技能要点 | ☐ |
| C3 | **L4_PH / L3_MD**：Populate = Memory 写入 L4；Bridge = Tool 边界；**热路径不跑 Agent** 与 HYPLAS 三附一致 | ☐ |
| C4 | **L2/L1**：数值与基础设施变更时，Harness Tool 是否覆盖（编译、桩、错误码） | ☐ |
| C5 | 每季度 **回顾** 本计划三项 Phase，更新「完成」列与日期 | ☐ |

---

## 七、相关索引

| 资源 | 路径 |
|------|------|
| Harness 系统设计（五层、组件） | [`../../05_实施指南/UFC_Harness_Engineering_系统设计.md`](../../05_实施指南/UFC_Harness_Engineering_系统设计.md) |
| 四链 / MasterPlan | [`UFC_L3_L4_L5_FourChain_MasterPlan.md`](UFC_L3_L4_L5_FourChain_MasterPlan.md) |
| HYPLAS 淬炼（Populate/热路径） | [`UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md`](UFC借鉴HYPLAS_PROGRAM淬炼L3L4L5方案.md) |
| 重构过程记录（导航类） | [`../../../archive/PLAN_History/99_归档库/04_实施报告/_RESTRUCTURE_REPORT_v4.md`](../../../archive/PLAN_History/99_归档库/04_实施报告/_RESTRUCTURE_REPORT_v4.md) |

---

*维护：Phase 完成后在表中打勾并注明日期；重大范围变更时同步更新「系统设计」与本文映射表。*
