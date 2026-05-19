# Change: contract-l4-element

## Why

**P2 Element** 是六大贯通域柱中 **Ke / Loc Eval / Material route** 的主战场（[`PILLAR_ROLLOUT_ROADMAP.md`](../../workflows/PILLAR_ROLLOUT_ROADMAP.md)）。`L4_PH/Element/CONTRACT.md` v2.6 已覆盖文件清单与四型，但柱级 **S1–S3** 尚未形成独立 change 包：无统一 **差距快照**、无 **S4–S7 实现波次** 的任务分解、与 **P1 Material** 接缝（`mat_pt_idx` → `Compute_Ke`）未在 plan 层锁定。

本 change **仅交付 S1–S3**（合同审计 + 快照 + change 包），**不含** `ufc_core` 大规模重构。

## What Changes（S1–S3）

| 阶段 | 交付物 |
|------|--------|
| **S1** | 三份合同交叉审计清单（L3 Mesh/Elem、L4 Element、L5 Assembly/Element） |
| **S2** | `plan/workflows/P2_ELEMENT_GAP_SNAPSHOT.md` — P2-G1–G6 差距表 |
| **S3** | 本 change 包（`proposal` / `design` / `spec` / `tasks`）+ `plan/tasks/contract-l4-element/TASK_RUN.md` |

## What NOT（本 PR / 本包）

- `PH_Elem_Contm` legacy 删除、`RT_Elem_Proc` SIO 全量 Arg 化（→ `p2-element-*` 实现波次）
- Cohesive/Gasket/Surface/User 空壳内核
- 与 P1 W2/NAME **代码** 并行修改（计划可并行，**合并**错开）

## Preconditions

- [`PR01_P1_P2_材料单元装配金线.md`](../../../docs/02_Developer_Guide/PR01_P1_P2_材料单元装配金线.md) 可作为评审模板
- P1 post-wave5 已在 `main`（#7–#13）；P1 S7 仍待 W2+NAME

## Impact

- 为 **`p2-element-loc-eval`**、**`p2-element-ke-sio`** 等实现 change 提供真源与闸门
- 不改动运行时行为

## Links

- 柱检查表：[`UFC_L345_形式对齐域级检查表_P1-P6.md`](../../../docs/02_Developer_Guide/UFC_L345_形式对齐域级检查表_P1-P6.md) § P2
- 编排：[`L3L4L5_MASTER_PLAN.md`](../../workflows/L3L4L5_MASTER_PLAN.md) Phase **C3**
- 材料接缝：[`L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) R2
