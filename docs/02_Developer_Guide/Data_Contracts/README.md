# contracts — 域间数据合同卡目录

> **路径**: `docs/contracts/`
> **用途**: 存放域间数据桥接合同文档（`{{Abbr}}_XXX_CONTRACT.md`）
> **最后更新**: 2026-04-16

---

## 一、目录说明

本目录用于存放 UFC 六层架构中各域之间的数据合同（Contract）文档。

### 合同命名规范

```
{{Abbr}}_{TargetDomain}_CONTRACT.md
```

| 示例 | 说明 |
|------|------|
| `Mat_Element_CONTRACT.md` | Material 域 ↔ Element 域的数据桥接合同 |
| `Elem_Section_CONTRACT.md` | Element 域 ↔ Section 域的数据桥接合同 |
| `Elem_Output_CONTRACT.md` | Element 域 → Output 域的结果传递合同 |

---

## 二、模板引用说明

以下文档引用本目录中的合同：

| 源文档 | 引用路径 |
|--------|----------|
| `templates/DOMAIN_CARD_Template.md` | `../contracts/{{Abbr}}_Section_CONTRACT.md` |
| `templates/DOMAIN_CARD_Template.md` | `../contracts/{{Abbr}}_Output_CONTRACT.md` |

---

## 三、创建新合同

1. 复制模板：`templates/DOMAIN_CARD_Template.md`
2. 填写域间数据桥接规范
3. 命名：`{{Abbr}}_{TargetDomain}}_CONTRACT.md`
4. 放入本目录

---

## 四、相关目录

| 目录 | 内容 |
|------|------|
| `templates/` | 代码模板与域卡模板 |
| `PPLAN/02_域级建模/` | 域级建模文档 |
| `PPLAN/06_核心架构/` | 核心架构设计 |

---

*最后更新: 2026-04-16*