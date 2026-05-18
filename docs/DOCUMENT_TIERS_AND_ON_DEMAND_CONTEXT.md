# 文档分级体系 × 按需加载 × 旧稿治理

本文建立 **可执行的文档分级（T0–T5）**、**Agent 上下文按需加载顺序**，并与 **旧稿治理 / 清理 / 重构** 流程对齐。执行边界与合并不再重复叙述的，以 [`DOC_MAINTENANCE_GUIDE.md`](./DOC_MAINTENANCE_GUIDE.md) 为准；仓库目录桶以 [`../rules/ufc-directory-layout.mdc`](../rules/ufc-directory-layout.mdc) 为准。

---

## 一、文档分级（T0–T5）

| 层级 | 含义 | 典型路径 | Agent 默认是否整包加载 |
|------|------|-----------|------------------------|
| **T0** | **入口与路由** | `UFC/AGENTS.md`、`docs/README.md`、`docs/00-快速导航.md` | 可读摘要；**不**贴全文 |
| **T1** | **架构 SSOT** | `docs/01_Architecture_Spec/`（Master、总决选、阅读版汇编） | **只开当前决策相关章节** |
| **T2** | **开发者与合同真源** | `docs/02_Developer_Guide/`、`ufc_core/**/CONTRACT.md` | **按域/层**打开；SIO 等用技能包 |
| **T3** | **域柱与实施规划** | `docs/03_Domain_Pillars/`、`docs/05_Project_Planning/PPLAN/` | **禁止**整桶 `PPLAN` 进上下文；用 README 表 + 单文件链接 |
| **T4** | **生成物与运行态** | `REPORTS/`、`design_plan/`（Harness 骨架）、`plan/tasks/`（`TASK_RUN.md`） | **报告只摘结论段**；骨架目录不替代 T1–T3 正文 |
| **T5** | **归档与历史** | `docs/archive/`、历史 stub | **仅追溯**；不作为新真理默认源 |

**与「五主桶」关系**：五桶是 **物理分区**；T 级是 **认知/加载优先级**。映射：`01`≈T1，`02`≈T2，`03`≈T3，`04`≈T2–T3 交界（验证），`05`≈T3，`archive`≈T5。

---

## 二、按需加载流程（优化后标准顺序）

长任务或新会话建议 **严格按序**，前一步产出作为后一步输入指针：

1. **T0**：读 `AGENTS.md` 技能速查 + `docs/README.md` 本节链接（不超过约 2k 字节的「指针块」自写即可）。  
2. **任务真相源**：打开 `plan/tasks/<task_id>/TASK_RUN.md` 的 **Goal、Next action、References**（若无则先 `agent-task init`）。  
3. **技能（渐进披露）**：只 `npx openskills read <命中技能>`，**不**预读全部 `skills/`。  
4. **T1/T2 单点**：只打开 References 中 **列出的路径**；需要规范时再点进 `CONTRACT.md` / 指定 PPLAN 单文件。  
5. **检索替代「向量 RAG」**：对已知文件名/符号用 **仓库 grep**；对章节用 **锚点链接**（`00-快速导航.md#…`）。  
6. **Harness 收口**：`agent-bundle --task "…"` 生成**当次**上下文包（仍应短）；再跑 `guardian` / `closure` 等。  
7. **写回**：子任务完成写 **3–5 行摘要** 到 `TASK_RUN.md` 的 **Log** 或 `agent-checkpoint append`；**不**把长结论只留在对话里。

**反模式**：首轮就把 `03_Domain_Pillars` 或整棵 PPLAN 粘进模型；在 T4 `REPORTS` 里改「规范结论」却不回写 T1–T3。

---

## 三、旧文档分级治理 / 清理 / 重构

### 3.1 三类动作

| 动作 | 适用 | 要求 |
|------|------|------|
| **治理（保留但降权）** | 仍有人读、但非真源 | 顶部加 **「状态：deprecated / 见 xxx」** 或改为 **stub 三行 + 链接** |
| **清理（移出热路径）** | 被新稿覆盖、仍要审计 | 移 **`docs/archive/<主题>/`**，根或原目录留 **README 一行说明** |
| **重构（合并真源）** | 多文件重复叙事 | 按 [`DOC_MAINTENANCE_GUIDE.md`](./DOC_MAINTENANCE_GUIDE.md) 白名单与 MR 约束；**同一 MR** 内 grep 更新入链 |

### 3.2 建议优先级（与体量）

1. **断链与失效路径**（`UFC/PLAN`、`docs/PPLAN` 旧前缀等）：只改链、不改论断 → 低风险。  
2. **明确被替代的 v1/v2 稿**：stub 化或进 archive → 中风险。  
3. **`03_Domain_Pillars` 大子树**：**禁止无清单批量删**；先做 **README 索引 + 去明显重复** → 高风险需专项 MR。

### 3.3 与 `design_plan/`、`plan/` 的分工

| 区域 | 文档类型 |
|------|----------|
| **`design_plan/`** | 满足 Harness `doc_structure` 的 **章节目录骨架**；可放「索引 md」指向 `docs/05_…`，**不**复制 PPLAN 长篇 |
| **`plan/tasks/`** | **任务级** References + 决策摘要；**不**存放应用级 SSOT |
| **`docs/`** | **规范与真源**；归档只进 **`docs/archive/`** |

---

## 四、与编排 Playbook 的衔接

- **任务编排与七段闭环**：[`../plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md`](../plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md)  
- **机器可读闭环清单**：`ufc_harness/closure_loop_checklist.json`（`sources` 可含本文件路径供工具读）

---

## 五、修订与责任

- **真源冲突**：以 `CONTRACT.md`、现行 PPLAN 章节、`01_Architecture_Spec` 锚点为准；裁决写入主文档一小节，**不**静默删旧稿。  
- **本文件变更**：属「体系与流程」；技术结论仍以各域合同与架构稿为准。

---

*创建目的：统一「文档分级 + 按需加载 + 旧稿治理」入口，减少 Agent 重复长上下文与误把 T4/T5 当真源的问题。*
