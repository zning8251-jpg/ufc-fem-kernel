# AI 技能提示词资产：PDF 智能处理 (可移植版)

> **使用说明**：
> 本文件为跨 IDE 通用的 AI 技能（Prompt/SOP）。
>
> - **Cursor**: 可另存为 `.cursor/rules/pdf-processing.mdc`
> - **VSCode / Cline / RooCode**: 可作为 Custom Instructions 或 `.clinerules`
> - **Windsurf**: 可另存为 `.windsurfrules`

---

## 1. 技能定位 (Role & Purpose)

当用户要求读取、解析、合并、拆分或从 PDF 中提取（文本/表格/图片）时，立刻激活本技能。你将作为专业的文档处理专家，使用最合适的 Python 库或命令行工具完成任务。

## 2. 核心工具栈库选型 (Toolchain)

- **pypdf**: 用于合并、拆分、旋转页面、提取元数据、加密解密。
- **pdfplumber**: 用于精准提取文本（保留布局）、提取复杂表格（可导出为 pandas DataFrame/Excel）。
- **reportlab**: 用于从头生成、绘制全新的 PDF（支持排版、画图）。
- **pytesseract + pdf2image**: 专用于扫描版 PDF 的 OCR 提取。
- **命令行 (poppler-utils / qpdf)**: 用于快速提取图片 (`pdfimages`) 或极速合并/拆分。

## 3. 标准操作规程 (SOPs)

### 3.1 提取文本与表格 (基于 pdfplumber)

```python
import pdfplumber
import pandas as pd

with pdfplumber.open("document.pdf") as pdf:
    # 提取文本
    for page in pdf.pages:
        print(page.extract_text())
        
    # 提取表格并转为 DataFrame
    all_tables = []
    for page in pdf.pages:
        for table in page.extract_tables():
            if table:
                df = pd.DataFrame(table[1:], columns=table[0])
                all_tables.append(df)
```

### 3.2 拆分与合并 (基于 pypdf)

```python
from pypdf import PdfWriter, PdfReader

# 合并
writer = PdfWriter()
for pdf_file in ["doc1.pdf", "doc2.pdf"]:
    reader = PdfReader(pdf_file)
    for page in reader.pages:
        writer.add_page(page)
with open("merged.pdf", "wb") as f:
    writer.write(f)
```

## 4. 架构师级应用规则 (Architecture Rules)

1. **理论文献提取**：如果是算法/理论手册，重点使用 `pdfplumber` 定向提取数学公式、变量表。
2. **零幻觉原则**：AI 绝对不能捏造 PDF 中不存在的参数或公式，必须基于提取到的原文本进行解释或架构映射。

