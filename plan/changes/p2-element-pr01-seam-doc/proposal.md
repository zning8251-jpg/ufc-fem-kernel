# Change: p2-element-pr01-seam-doc

## Why

P2 柱 [`contract-l4-element`](../contract-l4-element/) 已完成 S1–S3 计划包；**首条实现波次**须锁定仓库内已存在的 **P1∩P2∩Assembly 生产热路径**（[`PR01_P1_P2_材料单元装配金线.md`](../../../docs/02_Developer_Guide/PR01_P1_P2_材料单元装配金线.md)），避免无叙事地改全 Element 树。

本 change **仅文档化 + 接缝 guardian 基线**（锚点文件 P0 门控），**不改** `ufc_core` 热路径逻辑。

## What Changes

| 交付物 | 说明 |
|--------|------|
| `design.md` | 金线调用链、`PH_Element_Compute_Ke_Arg` 字段表、源码行锚点 |
| `PR01_GUARDIAN_AUDIT.md` | 接缝锚点文件 guardian 扫描记录 |
| `tasks.md` / `TASK_RUN` | S4 文档波次闸门 |
| 交叉链接 | `contract-l4-element/design.md` §4 首项标 **in progress → done** |

## What NOT

- 全库 `Element/` / `Assembly/` P0 清零
- `PH_Elem_Contm` 删除、`ke-arg-align` 字段重构（后续 change）

## Preconditions

- P1 S7 签收（[`P1_MATERIAL_S7_SIGNOFF.md`](../../workflows/P1_MATERIAL_S7_SIGNOFF.md)）
- Material `slot_pool(mat_pt_idx)` 与 Populate 已在 #7–#19 稳定

## Links

- PR01 模板：[`PR01_P1_P2_材料单元装配金线.md`](../../../docs/02_Developer_Guide/PR01_P1_P2_材料单元装配金线.md)
- P2 差距：[`P2_ELEMENT_GAP_SNAPSHOT.md`](../../workflows/P2_ELEMENT_GAP_SNAPSHOT.md)
