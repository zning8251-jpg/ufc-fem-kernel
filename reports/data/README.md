# `REPORTS/data/` — 证据包与中间产物

本目录存放报告生成或手工整理所用的 **机器可读数据**（`.json`、`.csv` 等），不是规范正文。

## 1. 与 Markdown 报告的对应关系

| 文件 | 主要消费方（示例） |
|------|-------------------|
| `analysis3_material_keyword_ufc_fields.csv` | 材料关键字 ↔ UFC 字段分析 |
| `analysis3_materials_ufc_mapping.json` | 同上 |
| `manual_extract_raw.json` | Manual 抽取管线；`Manual_UFC_domain_subroutine_mapping_guide.md` 等 |
| `material_public_types_index.json` | 材料域 TYPE 清册类报告 |
| `material_pillar_inventory_baseline_2026-05-02.csv` | Material Pillar 基线清册 |
| `user_subroutine_keyword_pages_ABAQUS_USER_6_14.json` | `usub_ufc_alignment.md` / 子程序对齐 |
| `usub_ufc_alignment.csv` | 与上表同源，CSV 视图 |

若删除或重命名数据文件，须同步更新引用它的 `REPORTS/*.md` 与主索引 [`../README.md`](../README.md) 中的表格。

## 2. 体积与版本管理

- 单文件若持续增长或超过约 **5–10 MB**，优先考虑 **CI 产物外置**、压缩归档，或 **`git-lfs`**（由仓库维护者统一启用）。  
- 大体积原始抽取（如整本 Manual）默认 **不** 提交全量；保留可复现的最小切片与生成脚本说明（脚本通常在 `tools/` 或文档所述路径）。

## 3. 非文本/binary

历史或测试用图像等若体积大、非必需，可迁入 `archive/` 或从索引中移除并注明原因。
