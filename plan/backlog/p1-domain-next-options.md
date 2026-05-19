# P1 — 域切换选项（Material 主链完成后）

> **更新**：2026-05-19 · Material post-wave5 **COMPLETE**

## Material 域（本 repo 已立项草案）

| change_id | 优先级建议 | 状态 |
|-----------|------------|------|
| [`p1-material-crystal-w2-multislip`](../changes/p1-material-crystal-w2-multislip/) | **高**（有晶体需求时） | plan DRAFT |
| [`p1-material-plast-name-debt`](../changes/p1-material-plast-name-debt/) | 低（质量债） | plan DRAFT |

## 其它 P1 域（见 [`L3L4L5_MASTER_PLAN.md`](../workflows/L3L4L5_MASTER_PLAN.md)）

| 域 | 建议 change_id | 说明 | Phase |
|----|----------------|------|-------|
| **L4 Element** | `contract-l4-element` / `p1-element-*` | Loc Eval、Ke、与 Material 路由 | C3 / Phase D |
| **L5 StepDriver** | `contract-l5-stepdriver` | 六参 / Iter 合同 | C1 |
| **L5 Assembly** | `contract-l5-assembly` | Glb Asm | C2 |
| **L5 Solver** | `contract-l5-solver` | 与 L2 引用 | C5 |
| **L5 RT Material** | `p1-rt-mat-bridge` | `RT_Mat_Dispatch_*` 与 L4 slot 金线 | Phase D |

**切换域前**：`agent-task init` + `plan/changes/<id>/` + 该域 `CONTRACT.md` / GAP 行。

## 决策提示

| 若目标是… | 选 |
|-----------|-----|
| 继续材料本构深度 | **Crystal W2** |
| 清 guardian 噪音、无功能风险 | **NAME-001** |
| 闭环 / 求解器 / 单元 | **Element 或 L5**（合同波次 C*） |
| 规范与门禁可复制 | **L3L4L5 Phase C** 合同 PR |

## 相关

- [`p1-material-post-wave5-backlog.md`](p1-material-post-wave5-backlog.md) §5  
- [`P1_MATERIAL_GAP_SNAPSHOT.md`](../workflows/P1_MATERIAL_GAP_SNAPSHOT.md)
