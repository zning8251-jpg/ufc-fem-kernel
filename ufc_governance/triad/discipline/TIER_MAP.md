# Tier 映射（纪律环 ↔ 文档分级）

与 [`docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`](../../../docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md) 对齐意图；flip 后叙事可由 `ufc_governance/library/` 承接。

| Tier | 现行主要位置 | `library/` 目标桶（flip 后） |
|------|----------------|-------------------------------|
| 总纲 / 入口 | `docs/README.md`、`AGENTS.md` | `library/00_constitution/` |
| 硬规则索引 | `.cursor/rules`、`UFC/rules` | `library/10_statutes/`（索引，非全文复制） |
| 架构叙事 | `docs/01_Architecture_Spec/` 等 | `library/20_architecture/` |
| PPLAN | `docs/05_Project_Planning/PPLAN/` | `library/30_pplan/` |
| 域柱叙事 | `docs/03_Domain_Pillars/` | `library/40_domain_pillars/` |
| 实现合同 | `ufc_core/**/CONTRACT.md` | **不搬迁**；变更包须引用 |

## Flip 门禁摘要

完整清单见 [`../../migration/FLIP_CHECKLIST.md`](../../migration/FLIP_CHECKLIST.md)。
