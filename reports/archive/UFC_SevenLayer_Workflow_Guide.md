# UFC 七层工作流实操指南：任务卡模板 + 域编排表 + 全流程

| 项 | 内容 |
|---|------|
| **版本** | 1.0 |
| **日期** | 2026-05-08 |
| **用途** | 面向「L3/L4/L5 全域二元结构改造」的可执行工作流：任务卡、Context 截取清单、Agent 指令序列、域编排顺序 |
| **前置阅读** | [AI_SevenLayer_Stack_UFC_Mechanism_and_Optimization.md](./AI_SevenLayer_Stack_UFC_Mechanism_and_Optimization.md)、[Master_Domain_Inventory_Index.md](./Master_Domain_Inventory_Index.md) |

---

## 0. 全文提纲

1. 域编排顺序与联动表
2. 参数化任务卡模板（直接替换域名/路径即可用）
3. Context 截取清单（按优先级排列）
4. Agent 指令（从 Prompt 到 Merge 的完整序列）
5. 各 Harness 门禁的角色
6. Loop 节奏：三类循环
7. 常见问题与回避策略

---

## 1. 域编排顺序

### 前提

从**最高优先级、依赖风险最小**的域开始，逐步推进以积累经验；联动域锚定后串联改造。

### 波次 A – 全贯通域柱（L3+L4+L5，P1–P4）

| 顺序 | 域 | 层覆盖 | 域缩 | 来源（L3 CONTRACT） | 联动风险 |
|------|-----|--------|------|---------------------|----------|
| A1 | **Material** | L3+L4+L5 | Mat | ufc_core/L3_MD/Material/CONTRACT.md | 低 — 已被 Material Inventory 充分覆盖，改造经验可复用到其它域 |
| A2 | **Element** | L3+L4+L5 | Elem | ufc_core/L3_MD/Element/Elem/CONTRACT.md | 中 — 依赖 Section + Mesh，但 Section 改造在本波次后做则需预留接口 |
| A3 | **LoadBC** | L3+L4+L5 | LoadBC | ufc_core/L3_MD/LoadBC/CONTRACT.md | 低 — 域边界清晰；注意与旧 Boundary/ 的 DEPRECATED 关系 |
| A4 | **Contact/Interaction** | L3+L4+L5 | Cont | ufc_core/L3_MD/Interaction/CONTRACT.md | 中 — L3 名 Interaction、L4/L5 名 Contact；双名制需在任务卡中显式约定 |

### 波次 B – 半贯通域柱（L3+L5，P5–P6）

| 顺序 | 域 | 层覆盖 | 域缩 | 来源 | 联动风险 |
|------|-----|--------|------|------|----------|
| B1 | **Output** | L3+L5 | Out | ufc_core/L3_MD/Output/CONTRACT.md | 低 — 无 L4，涉及 MD_Out_* / RT_Out_* |
| B2 | **WriteBack** | L3+L5 | WB | ufc_core/L3_MD/WriteBack/CONTRACT.md | 中 — 写回白名单枚举涉及**所有已改造域**，应安排在 A1–A4 / B1 之后 |

### 波次 C – 层专属域 & 剩余 L3/L4/L5 域

| 顺序 | 域 | 层 | 域缩 | 来源 | 联动风险 |
|------|-----|----|------|------|----------|
| C1 | **Section** | L3+L5 | Sect | ufc_core/L3_MD/Section/CONTRACT.md | 高 — 被 Element 依赖，建议与 Element 联动（Element 先声明接口，Section 后落地） |
| C2 | **Analysis**（Step、Solver） | L3+L5（无L4） | Step/Solv | ufc_core/L3_MD/Analysis/CONTRACT.md | 中 — 三步状态机需在其它所有域改造后对齐触发点 |
| C3 | **Assembly** | L3,L5 | — | （无独立 CONTRACT？） | 中 — 跨域组装，依赖 Material/Element/LoadBC 的 Populate |
| C4 | **Model** | L3 | — | ufc_core/L3_MD/Model/CONTRACT.md | 低 — 根容器，需预留注册点 |
| C5 | **KeyWord** | L3 | KW | ufc_core/L3_MD/KeyWord/CONTRACT.md | 低 — 独立解析域 |
| C6 | **Constraint** | L3,L4 | Constr | — | 低 |
| C7 | **Field** | L3,L4 | — | — | 低 — 场变量容器 |
| C8 | **Bridge** | L3-L4-L5 | — | — | 跨层；待所有域改造后统一对齐 |
| C9 | **Part** | L3 | — | ufc_core/L3_MD/Part/CONTRACT.md | 低 |
| C10 | **Base**（L1/L2 公共层） | 独立 | — | — | 不改，仅确保被所有域正确 USE |
| C11 | **Logging**、**StepDriver** | L5 | — | — | 零改 |

### 联动风险表

| 须联动域对 | 改造次序要求 |
|-----------|--------------|
| Element ↔ Section | Element 先声明 Desc 接口，Section 再落地截面 Desc（两者可同波次先后走，不可颠倒） |
| WriteBack ↔ 所有域 | WriteBack 白名单（MD_WB_Def）中 domain_id 枚举应在全域改造完后统一更新一次，避免反复改白名单 |
| Analysis ↔ 各域 | 三步状态机中 Populate / Execute / WriteBack 各阶段的触发点契约，待各域形定后再做最后对齐 |

---

## 2. 参数化任务卡模板

以下是可复用的 Markdown 模板。使用时替换域特定参数（用 {{PLACEHOLDER}} 标记）：

`markdown
## 任务：{{域名}}（{{域缩}}）二元结构改造

### 域身份
- **域名**：{{域名}}（如 Material）
- **域缩**：{{域缩}}（如 Mat）
- **覆盖层**：{{层清单}}（如 L3+L4+L5 或 L3+L5）
- **域目录**：
  - L3：UFC/ufc_core/L3_MD/{{L3目录}}/
  - L4：UFC/ufc_core/L4_PH/{{L4目录}}/（若全贯）
  - L5：UFC/ufc_core/L5_RT/{{L5目录}}/（若半贯）

### 改造目标
1. [ ] **数据结构**：{{模块数}} 个模块中，确认/补全四类 TYPE（Desc/State/Algo/Ctx）按 REPORT_Naming_Unified_Spec.md 命名
2. [ ] **过程签名**：层间边界过程（L3→L4 Populate、L4→L5 Dispatch、L5 _Proc）按 Principle #14 套 {{域缩}}_*_Arg，禁止仅包 status 的薄封装
3. [ ] **命名整治**：确保所有新代码以 {{层缀}}{{域缩}}_ 为前缀，再无 {{旧前缀}}_ 残留
4. [ ] **SIO 校验**：通过 sio_checker 零报错
5. [ ] **语法编译**：通过 gfortran -std=f2003 -fsyntax-only 零报错（或 CMake 构建通过）

### 必须参考的三份 Context
1. **域 CONTRACT.md**：UFC/ufc_core/{{L3层目录}}/{{域目录}}/CONTRACT.md
2. **域 Inventory**：UFC/REPORTS/{{域名}}_Domain_Inventory.md
3. **命名规范合订**：UFC/REPORTS/REPORT_Naming_Unified_Spec.md（只读 §1–§6）

### 可选参考
- **过程算法**：`UFC/REPORTS/{{域名}}_Procedure_Algorithm.md`（**根 stub**；长文 `UFC/REPORTS/archive/{{域名}}_Procedure_Algorithm.md`，若有）
- **现有四类范例**：UFC/ufc_core/L3_MD/Material/（Material 域已完成四类拆分的文件）
- **四型设计规范**：UFC/REPORTS/FourKind_MasterAux_Nesting_Design_Spec.md

### 不做的
- 不改非本域文件（除非 README 或 CONTRACT 有明确接口声明）
- 不改 L1/L2 基础设施
- 不重构算法流程骨架（只做数据结构 + 签名对齐）

### 完成定义（Merge 门禁）
- [ ] 每个新 TYPE 有独立模块（或按域规模合理聚合）
- [ ] *_Arg 包含 ≥2 个字段或被 Harness 消费的 L5 _Proc
- [ ] 
aming_checker 零 ERROR
- [ ] gfortran -std=f2003 -fsyntax-only 通过
- [ ] CONTRACT.md 的 TODO 项已相应更新或标记完成
- [ ] DOMAIN_PILLAR_CARD.md（若有）同步更新

### 联动
- 本改造涉及联动的域：{{联动域清单}}（见波次编排表）
- 依赖方向：本域 {{依赖动词}} {{被依赖域}}（如「Populate 阶段调用 Section 的截面查询」）
`

### 使用说明

1. 复制模板到 Issue 或 Cursor Prompt
2. 替换所有 {{}} 占位符（参考下文的域参数速查表）
3. 「必须参考的三份 Context」部分**用 @ 引用文件路径**（Cursor 中直接拖入或输入路径）
4. 将「不做的」和「完成定义」直接发送给 Agent，避免歧义

### 域参数速查表（用于模板填充）

| 域 | 域缩 | 层缀 | 层清单 | L3 目录 | L4 目录 | L5 目录 | 旧前缀（需清理） | 联动域 |
|----|------|-------|---------|---------|---------|---------|----------------|--------|
| Material | Mat | MD_/PH_/RT_ | L3+L4+L5 | Material | Material | Material | Base/UF_* | 无→Section (次要) |
| Element | Elem | MD_/PH_/RT_ | L3+L4+L5 | Element/Elem | Element | Element | Legacy/ELEM_* | Section、Mesh |
| LoadBC | LoadBC | MD_/PH_/RT_ | L3+L4+L5 | LoadBC | LoadBC | LoadBC | Boundary/BC_*、Load_* | Boundary (DEPRECATED) |
| Contact/Interaction | Cont | MD_/PH_/RT_ | L3+L4+L5 | Interaction | Contact | Contact | Int_* | Element/Mesh (表面引用) |
| Output | Out | MD_/RT_ | L3+L5 | Output | — | Output | Output_* | WriteBack |
| WriteBack | WB | MD_/RT_ | L3+L5 | WriteBack | — | WriteBack | WriteBack_* | **所有域**（白名单） |
| Section | Sect | MD_/RT_ | L3+L5 | Section | — | Section | Sec_* | Element（截面引用） |
| Analysis | Step/Solv | MD_/RT_ | L3+L5 | Analysis | — | Solver、StepDriver | — | 所有域（触发点契约） |
| Model | — | MD_ | L3 专属 | Model | — | — | — | 所有 L3 域（注册点） |
| Assembly | — | MD_/RT_ | L3+L5 | Assembly | — | Assembly | — | Material、Element、LoadBC |
| KeyWord | KW | MD_ | L3 专属 | KeyWord | — | — | KW_* | 无 |
| Constraint | Constr | MD_/PH_ | L3+L4 | Constraint | Constraint | — | — | Element、Contact |
| Field | — | MD_/PH_ | L3+L4 | Field | Field | — | — | Material、Output |

---

## 3. Context 截取清单

**原则**：对 Agent 不必喂全量仓库，而是提供**四件套**（优先级从高到低）：

### ★★★ 必读（每次任务都需）

| 序号 | 内容 | 典型路径 |
|------|------|----------|
| 1 | 域 CONTRACT.md | ufc_core/L3_{MD,PH,RT}/{域}/CONTRACT.md（1-3 份） |
| 2 | 域 Inventory | UFC/REPORTS/{域名}_Domain_Inventory.md |
| 3 | 命名规范合订（§1–§6：域缩、层缀、四型、*_Arg） | UFC/REPORTS/REPORT_Naming_Unified_Spec.md |
| 4 | 已完成域的最简范例（如 Material 域四类拆法） | ufc_core/L3_MD/Material/MD_Mat_Def.f90（观察四类文件组织） |

### ★★☆ 推荐（视任务需要）

| 序号 | 内容 | 路径 |
|------|------|------|
| 5 | 过程算法文档（若有） | `UFC/REPORTS/{域名}_Procedure_Algorithm.md`（根 stub）+ `UFC/REPORTS/archive/{域名}_Procedure_Algorithm.md`（长文） |
| 6 | 四型设计规格（R-01 到 R-13） | UFC/REPORTS/FourKind_MasterAux_Nesting_Design_Spec.md |
| 7 | 一页填槽表 | UFC/REPORTS/OnePager_FourKind_MasterAux_Nesting.md |
| 8 | 域柱架构文档 | UFC/docs/05_Project_Planning/PPLAN/06_核心架构/UFC_DOMAIN_PILLAR_ARCHITECTURE.md |

### ★☆☆ 仅当涉及架构调整时读

- PPLAN 主线
- 架构哲学 / 道法术器文档
- 已有域的全套完整源码

### 操作手法

在 Cursor Prompt 中：

`
参考以下文件：
@UFC/ufc_core/L3_MD/Material/CONTRACT.md
@UFC/REPORTS/Material_Domain_Inventory.md
@UFC/REPORTS/REPORT_Naming_Unified_Spec.md
`

或直接在任务卡中写明路径（Agent 会用上下文窗口拉取）。

---

## 4. Agent 指令序列（从 Prompt 到 Merge 的完整步骤）

### Step 1 – 写任务卡

打开上方的「参数化任务卡模板」 → 替换域名/路径/联动域 → 发送给 Cursor Agent。

> 如果你是第一次做，可以用 Material 域作为试跑——它的 CONTRACT.md、Inventory、已完成文件都是最全的。

### Step 2 – Agent 执行（典型交互）

以下是一次典型 Agent 交互（以 Material 域为例）：

`
你（Prompt）：
「按 UFC/REPORTS/UFC_SevenLayer_Workflow_Guide.md 的模板，
对 Material 域（域缩 Mat）做四类 TYPE 拆分。

参考：
@ufc_core/L3_MD/Material/CONTRACT.md
@REPORTS/Material_Domain_Inventory.md
@REPORTS/REPORT_Naming_Unified_Spec.md

以 ufc_core/L3_MD/Material/ 中已完成部分为基础，
把现存单 TYPE 文件中的 Desc/State/Algo/Ctx 拆到独立模块。
»

Agent →
「当前 Material 域 L3 的 MODULE 分布如下：
…（读目录结构 + CONTRACT.md）…
现确认应将 MD_Mat_Def 中的 TYPE MD_Mat_Desc 保留为 Desc；
需新增 MD_Mat_State_Def / MD_Mat_Algo_Def / MD_Mat_Ctx_Def。

以下是生成的四类模块：」

[Agent 生成 4 个 .f90 文件]
`

### Step 3 – 校验

`
你：
「运行 naming_checker 和 sio_checker，
然后用 gfortran -std=f2003 -fsyntax-only 编译检查。」
`

### Step 4 – 复盘与 Merge

`
你（检查 Agent 输出）：
✓ 命名规范
✓ SIO 合规
✓ 语法通过
✓ CONTACT.md 对齐

→ Approve & Merge PR
→ 更新 REPORTS/ 中的域 Inventory 文档
`

---

## 5. Harness 门禁角色

| 检查项 | 工具/命令 | 在 CI/人工中的角色 | 阶段 |
|--------|-----------|-------------------|------|
| 命名合规 | python ufc_harness/tools/code_development/naming_checker.py | **必选** — 拦截命名漂移 | Merge 前 |
| SIO 合规 | python ufc_harness/tools/code_development/sio_checker.py | **必选** — 层间边界与 *_Arg 正确性 | Merge 前 |
| 合同完整性 | python ufc_harness/tools/arch_validation/contract_completeness.py | **必选** — 合同 TODO 与代码同步 | Merge 前 |
| 域边界越界 | python ufc_harness/tools/arch_validation/domain_boundary_checker.py | **推荐** — 禁止跨域 USE | Merge 前 |
| 语法 | gfortran -std=f2003 -fsyntax-only / CMake build | **必选** — 编译级门禁 | Merge 前 |
| 文档坏链 | python ufc_harness/run_harness.py doc-structure | **可选** — 建议 CI 周期巡检 | 定时 |
| 架构一致性 | python ufc_harness/tools/arch_validation/arch_consistency.py | **参考** — 全局规约打分 | 巡检 |

### 命令速查

`powershell
# 语法检查（单文件）
gfortran -std=f2003 -fsyntax-only -c UFC/ufc_core/L3_MD/Material/MD_Mat_Def.f90

# Harness 命名检查
python UFC/ufc_harness/tools/code_development/naming_checker.py

# Harness SIO 检查
python UFC/ufc_harness/tools/code_development/sio_checker.py

# Harness 全量
python UFC/ufc_harness/run_harness.py plan-checks
`

---

## 6. Loop 节奏设计

### 6.1 单任务 Loop（数十分钟至数小时 — 你当前主要节奏）

`
[Perceive]
  你确认当前域状态：读 CONTRACT.md、Inventory、TODO 项。
  输出：任务卡（用 §2 模板）
      ↓ Prompt
[Decide]
  选择适用的 Skill：ufc-layer-domain-feature（生成骨架）、ufc-structured-io（校验 Arg）
  决定任务范围：只做 L3？还是 L3+L4+L5？
      ↓ Cursor Agent 接收
[Act]
  Agent 生成 .f90 模块，跑命名检查，出补丁或 PR
      ↓ PR 提交
[Reflect]
  你审核：
  - Harness 门禁（命名 / SIO / 语法 / 合同）都过了？
  - 是否偏离了域合同定义的边界？
  - 是否与已改造的其他域有接口冲突？
  → 通过则 Merge，更新 Inventory 文档
  → 不通过则调整 Prompt 再跑一轮
`

### 6.2 波次 Loop（天级 — 按域编排表推进）

`
[Perceive] 全量巡检：跑 plan-checks，输出当前域门窗状态
[Decide]   对照域编排表（§1）：下一个该做什么域？当前域的门禁缺口在哪？
[Act]      按单任务 Loop 逐个域改造
[Reflect]  每改完一个域：
           - 更新 Inventory（域级 + Master 索引）
           - 更新波次追踪表
           - 若发现联动域需要接口预留，在任务卡中注明
`

### 6.3 巡检/收敛 Loop（周级 — 可选自治）

`
定时 CI 或 cron 触发：
  1. 跑 harness 全套巡检（命名 + 合同 + 结构 + 坏链）
  2. 对比上次巡检快照，输出「漂移报告」
  3. 自动生成 ISSUE 或补丁（命名修复、坏链修复）
  4. 你周一审核、合并
`

---

## 7. 常见问题与回避策略

| 问题 | 表现 | 回避策略 |
|------|------|----------|
| Agent 改到不该改的域 | 新 PR 跨域修改 | 在 Prompt 中写死「不做的」清单；Harness 的 domain_boundary_checker 拦截 |
| 生成的 *_Arg 薄封装 | 只包一个 status 字段 | 套用 ufc-structured-io 校验；在 Prompt 中复制 Principle #14 原文 |
| 命名不合规范 | 
aming_checker ERROR | 直接运行 checker 即可发现，自动修复 |
| 语法错误 | gfortran 报错 | 跑 -fsyntax-only 拦截；大改时可分段验证 |
| 「一次性做完所有域」 | 导致 PR 与冲突巨大、审核困难 | 坚持「一个域一个 PR」的原则，除非明确是跨域联动改造（如 Element + Section） |
| Context 太多，Agent 混淆 | Agent 引用错误文档或规范过时 | 每次只喂「必读三份」+「当前域 Inventory」，不加无关文档 |
| Loop 遗忘 | 改完一个域就不知下一域 | 用波次 Loop 的 Reflect 阶段更新追踪表 |

---

## 附录 A：Material 域作为示范跑的 Context 和 Prompt 示例

### A.1 Prompt 示例（直接复制可用）

`markdown
## 任务：Material 域（Mat）二元结构改造（示范跑）

### 域身份
- 域缩：Mat
- 覆盖层：L3+L4+L5
- L3 目录：UFC/ufc_core/L3_MD/Material/

### 改造目标
1. 确认 Material 域四类 TYPE（Desc/State/Algo/Ctx）已按规范拆分到独立模块
2. 层间边界过程套用 MD_Mat_*_Arg，禁止仅包 status 的薄封装
3. 确保所有新代码以 MD_Mat_/PH_Mat_/RT_Mat_ 为前缀

### 必须参考的三份 Context
@UFC/ufc_core/L3_MD/Material/CONTRACT.md
@UFC/REPORTS/Material_Domain_Inventory.md
@UFC/REPORTS/REPORT_Naming_Unified_Spec.md

### 不做的
- 不改 Material 域以外的代码
- 不改本构求值算法（L4 Execute）本身，只改其签名

### 完成定义
- [ ] 各 TYPE 在独立模块中声明
- [ ] naming_checker 零 ERROR
- [ ] gfortran -std=f2003 -fsyntax-only 通过
`

### A.2 预期 Agent 交互

1. Agent 读 CONTRACT.md → 理解四类 TYPE 映射（见该合同 §2）
2. Agent 读 Inventory → 了解当前模块数（12 主族 + Contract/ 子模块）
3. Agent 读命名规范 → 确认前缀规则
4. Agent 扫描 L3_MD/Material/ 实际文件结构
5. Agent 报告：「已确认 MD_Mat_Desc 为 Desc 核心；MD_Mat_Def 中混有 State 字段，建议抽出 MD_Mat_State_Def」
6. 你决定：批准此拆分 → Agent 生成新模块 → 跑校验 → 你审核 → Merge

---

> **END** — UFC 七层工作流实操指南 v1.0

*冷归档全文：`UFC/REPORTS/archive/UFC_SevenLayer_Workflow_Guide.md`。入口 stub：`UFC/REPORTS/UFC_SevenLayer_Workflow_Guide.md`。*
