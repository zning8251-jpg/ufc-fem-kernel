---
name: ufc-layer-workflow
description: UFC L3/L4/L5 域柱二元结构改造固化工作流。触发：域柱改造、L3/L4/L5 同步改造、贯通域柱、二元结构工作流、Populate 金线、七步工序、G1-G6、波次改造、防偏离。与 ufc-governance-triad、ufc-layer-domain-feature、ufc-structured-io 配合使用。
---

# UFC 域柱改造工作流（Agent 执行指南）

## 何时使用

- 用户要在 **`ufc_core` 仅生产代码** 下改造 **L3_MD / L4_PH / L5_RT** 某一 **贯通域柱 P1–P6**（或半柱 H1–H2）。
- 用户问「怎么搭 workflow」「如何验收」「如何不偏离」。

**不要**用本技能替代：`ufc-layer-domain-feature`（写具体 f90）、`ufc-governance-triad`（变更包四制品细则）。

---

## 必读（按序，用路径打开）

1. [`UFC/docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md`](../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/UFC_L3L4L5_域柱改造固化工作流_v1.0.md) — 前因后果、七步、验收、防偏离  
2. [`UFC/plan/workflows/L3L4L5_MASTER_PLAN.md`](../../plan/workflows/L3L4L5_MASTER_PLAN.md) — Phase A–E 分项与 MR 分解  
3. 域柱 [`L3_L4_L5_语义改造_导航真源.md`](../../docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_语义改造_导航真源.md) — W0–W8 顺序  
4. 该域三层 [`ufc_core/.../CONTRACT.md`](../../ufc_core/) — SSOT  

---

## 硬约束（违反即停）

1. **单位 = 域柱垂直切片**，禁止单 PR 跨 P1+P2 或多柱。  
2. **合同先于代码**：未更新 CONTRACT 不得大改 `*_Def`/热路径。  
3. **L3 禁止 USE L4/L5**（Bridge 出口除外）。  
4. **一个 TASK_RUN 仅一个 `pillar_id`**；仅一个 Step `in_progress`。  
5. **扩 scope → 新 `change_id`**（见既有 material pilot）。  
6. **对话不存真相**：状态写 `plan/tasks/<id>/TASK_RUN.md`。

---

## 七步工序（每柱重复）

| Step | 动作 | 产出 |
|------|------|------|
| S1 | 锚定 CONTRACT + 三轴表 | 合同 diff |
| S2 | `python UFC/tools/domain_procedure_registry_scan.py` | `generated/` + 差距表 |
| S3 | `plan/changes/<id>/` + 复制 [`TASK_RUN_L3L4L5.md`](../../plan/workflows/templates/TASK_RUN_L3L4L5.md) | validate 绿 |
| S4 | L3 `*_Def`/Reg/Brg | discipline/guardian/naming |
| S5 | L4 Populate/Core/Dispatch | 同上 |
| S6 | L5 `*_Proc`/编排 | 同上 + A9 |
| S7 | G1–G6 + `07` 行 + 填 HANDOFF | 归档 TASK_RUN |

**交接**：每步用 [`HANDOFF_MATRIX.md`](../../plan/workflows/templates/HANDOFF_MATRIX.md)。

---

## 验收（必须分三级声明）

| 级别 | 检查 |
|------|------|
| L-形式 | G1–G6（[`UFC_L345_形式对齐域级检查表_P1-P6.md`](../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md)） |
| L-合同 | A4 + A7–A11（域 CONTRACT + [`07` 里程碑](../../docs/05_Project_Planning/PPLAN/11_闭环落地专项/07_L3L4L5_二元结构合同完备里程碑.md)） |
| L-物理 | 单测/集成/patch（**合同齐 ≠ 物理对**） |

PR 必填：**层 / 域 / 合同 / Bridge / SIO** 五元声明。

---

## Harness（touched 路径）

```text
python ufc_harness/run_harness.py agent-task init --session <task_id> --goal "P1 Material S5 ..."
python ufc_harness/run_harness.py discipline verify --touch-path ufc_core/L4_PH/Material/PH_Mat_Def.f90
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material --fail-on-p0
python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material
python ufc_harness/run_harness.py change-package validate --change-id <id> [--strict]
```

可选：`python UFC/skills/ufc-layer-workflow/scripts/validate_args.py <file.f90>`

---

## 协作技能

| 场景 | 技能 |
|------|------|
| 写 f90 骨架/四型 | `ufc-layer-domain-feature` |
| `*_Arg` / `_Proc` | `ufc-structured-io` |
| 变更包四制品 | `ufc-governance-triad` |
| 命名 | `ufc-naming-checker` |

---

## 开任务清单（复制给用户）

1. 选定 **pillar_id**（P1 或 P2 首选）  
2. `agent-task init --session <task_id>`  
3. 合并 `plan/workflows/templates/TASK_RUN_L3L4L5.md`  
4. 新建或续用 `plan/changes/<change_id>/`，design 粘贴 `CHANGE_DESIGN_METHODOLOGY.md`  
5. 按 MASTER_PLAN Phase B→D 执行  
