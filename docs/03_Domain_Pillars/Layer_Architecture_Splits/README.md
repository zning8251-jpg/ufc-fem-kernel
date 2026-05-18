# 六层架构拆分（Layer_Architecture_Splits）

> **路径**：`docs/03_Domain_Pillars/Layer_Architecture_Splits/README.md`  
> **最后更新**：2026-05-02

本目录是 **UFC 六层（L1–L6）** 相关长文档的主挂载点之一；总入口见 [`docs/README.md`](../../README.md)，实施与闭环见 [`docs/05_Project_Planning/PPLAN/README.md`](../../05_Project_Planning/PPLAN/README.md)。

**归档说明**：历史上 **00-总纲 / 01-理论基础 / 02-架构定义** 等树曾放在 `docs/archive_20260418/六层架构拆分_归档/`。**当前克隆中该目录可能不存在**（未提交或已迁出）。若链接失效，见 [`docs/DOC_MAINTENANCE_GUIDE.md#archived-assets`](../../DOC_MAINTENANCE_GUIDE.md#archived-assets)。

---

## 子目录索引（本仓库内可读）

| 目录 | 说明 |
|------|------|
| [03-实施路线](03-实施路线/README.md) | 差距分析、分阶段路线图、模块合并与检查清单 |
| [04-六层架构拆解](04-六层架构拆解/README.md) | 按 L1–L6 分层的详细设计入口 |
| [05-工程规范](05-工程规范/README.md) | 工程侧规范与交叉引用 |
| [06-附录](06-附录/README.md) | 附录与模式总结等 |

**逻辑分类与归档路径表**（含 00–02 在归档树中的位置）：[`README_文档分类清单.md`](README_文档分类清单.md)。

---

## 阅读顺序建议

1. **依赖方向**：L6 → L5 → L4 → L3 → L2 → L1（单向）。
2. **Bridge / Context**：先看各层 README 中的 Bridge、Context 约定，再下钻长文。
3. **与代码对齐**：以 `ufc_core` 各层 `CONTRACT.md` 与 Harness 为准；文档仅作叙述与历史对照。

---

## 维护

新增或搬迁 Markdown 时，请同步更新 **本子目录 README** 与 [`docs/README.md`](../../README.md) 中的互链，避免双轨真源。
