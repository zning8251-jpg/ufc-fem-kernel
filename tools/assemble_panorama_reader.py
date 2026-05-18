# -*- coding: utf-8 -*-
"""Assemble scattered panorama / ADR-line docs into one Markdown reader edition."""
from __future__ import annotations

from pathlib import Path

REPO_UFC = Path(__file__).resolve().parents[1]
DOCS = REPO_UFC / "docs"
OUT = DOCS / "01_Architecture_Spec" / "UFC_全景架构_按章节汇编_阅读版.md"

LOOP_ORDER = [
    "00_闭环域级落地总纲与模板.md",
    "01_L5_RT_StepDriver_闭环落地设计.md",
    "02_L4_PH_Element_闭环落地设计.md",
    "03_L3_MD_Material_闭环落地设计.md",
    "04_L5_RT_Assembly_Solver_闭环落地设计.md",
    "05_中间架构层新版总纲_全景套件v3.0.md",
    "06_域级落地验收表_CodeReview与里程碑.md",
    "06_中间架构层全景套件v3_五大高阶组件深化路线图.md",
    "07_架构与生态融合：双轨制API与用户扩展机制设计.md",
    "08_Extension全家族统一适配架构_UMAT_UEL_ULOAD等通用沙盒设计.md",
    "09_基于模板的存量资产渐进式重构方案.md",
    "10_全域黄金模板分类体系与骨架设计.md",
    "11_全域黄金模板_细粒度微观设计与子程序规范.md",
    "12_中间架构层全景套件_跨层联动与数据灌注体系.md",
    "13_系统工程字典_完整时相与数据嵌套巧设计补充.md",
    "14_UFC_时空动三维正交架构与完备性证明.md",
    "15_UFC_时空动三维正交架构_全维字典与签名矩阵.md",
    "16_L3_MD_数据真源与扁平化关系型树设计.md",
    "17_UFC_L3L4L5_高阶设计陷阱与核心规约.md",
    "18_UFC_双域三维正交体系_截面绑定与分析类型路由.md",
    "19_UFC_终极防坑指南_张量约定_沙盒沙漏与MPI抽象.md",
    "20_UFC_架构深度审查与冲突排雷报告.md",
    "21_UFC_系统级数据全生命周期与三级内存架构.md",
    "22_UFC_超越商业软件_非线性求解的终极秘密与进阶架构.md",
    "23_UFC_超越商业软件_AD混合引擎与高阶非线性防线.md",
    "24_UFC_大规模求解器布阵_AMG与外挂数学库战略.md",
    "99_UFC_全景架构设计文档汇编_MasterBackup.md",
]

INTRO = """# UFC 全景架构按章节汇编（单文件阅读版）

> **用途**：将分散在 `docs/01_Architecture_Spec`、`docs/05_Project_Planning/PPLAN` 与 `PPLAN/11_闭环落地专项` 的多篇短文**按阅读顺序汇入一卷**，便于通读、检索与对外导出。  
> **权威优先级**：若与单行本冲突，以 [`00_UFC_全景架构白皮书_Master_Specification.md`](./00_UFC_全景架构白皮书_Master_Specification.md)、[`27_UFC_01至26全景架构决策汇总与实施路线总决选.md`](./27_UFC_01至26全景架构决策汇总与实施路线总决选.md) 及 `ufc_core/**/CONTRACT.md` 为准；**本文件不发明新约束**，仅做汇编。  
> **生成**：运行 `python tools/assemble_panorama_reader.py` 可自仓库内上述源文件**重新拼接**（勿手改本卷正文大块，以免与源漂移）。

## 「逻辑 ADR 01–26」与仓库里真实文件的关系

`27_` 文中所说的 **ADR 01–26** 是叙事上的**决策串**，并不等于仓库里曾有 26 个名为 `01_*.md` … `26_*.md` 的独立文件。当前 worktree 里与「全景 / 总决选」主线强相关、且已落盘的散稿，已按下表顺序编入本卷：

| 叙事块（见 `27_`） | 本卷中的主要对应 |
|-------------------|------------------|
| 哲学与数据基石（01–10、16、21 等） | 第零编 `00_`；第二–六编 PPLAN `14–18`；闭环稿中的 `16`、`21` 等 |
| 时空动与执行（11–15） | 闭环 `13`、`14`、`15` 等 |
| 路由与非线性 / 求解器（17–20、22–24） | 闭环 `17`–`24` |
| 多场与 PDE 大一统（25–26） | 倒数第二、倒数第一编（`25`、`26`） |

**闭环专项**内另有 `00–06` 等「域级落地」总纲与模板类稿件，置于第七编起，便于从工程闭环读到 ADR 线。
"""


def build_pieces() -> list[tuple[str, str]]:
    pieces: list[tuple[str, str]] = [
        ("01_Architecture_Spec/00_UFC_全景架构白皮书_Master_Specification.md", "第零编 · 全景架构白皮书（SSOT）"),
        ("01_Architecture_Spec/27_UFC_01至26全景架构决策汇总与实施路线总决选.md", "第一编 · 01–26 总决选与叙事索引"),
        ("05_Project_Planning/PPLAN/14_UFC_终极架构统一论_道生万物.md", "第二编 · 架构哲学（PPLAN 14）"),
        ("05_Project_Planning/PPLAN/15_UFC_架构哲学_三千大道_生死因果命运.md", "第三编 · 架构哲学（PPLAN 15）"),
        ("05_Project_Planning/PPLAN/16_UFC_架构哲学_三千大道_万法归宗.md", "第四编 · 架构哲学（PPLAN 16）"),
        ("05_Project_Planning/PPLAN/17_UFC_架构哲学_天地造化_大一统本体论.md", "第五编 · 架构哲学（PPLAN 17）"),
        ("05_Project_Planning/PPLAN/18_UFC_终极架构哲学_大一统终极定稿.md", "第六编 · 架构哲学（PPLAN 18）"),
    ]
    base = 7
    for i, name in enumerate(LOOP_ORDER):
        rel = f"05_Project_Planning/PPLAN/11_闭环落地专项/{name}"
        pieces.append((rel, f"第{base + i}编 · 闭环专项：{name}"))
    n = base + len(LOOP_ORDER)
    pieces.append(
        (
            "01_Architecture_Spec/25_UFC_UniFieldCore_多场统一基座与大统一架构设计.md",
            f"第{n + 1}编 · 多场统一与大统一（原稿 25）",
        )
    )
    pieces.append(
        (
            "01_Architecture_Spec/26_UFC_PDE大统一方程基座_FEM改写CFD的通用架构解决方案.md",
            f"第{n + 2}编 · PDE 大统一与 FEM–CFD（原稿 26）",
        )
    )
    return pieces


def main() -> None:
    parts: list[str] = [INTRO]
    for rel, label in build_pieces():
        path = DOCS / Path(rel)
        if not path.exists():
            raise FileNotFoundError(path)
        body = path.read_text(encoding="utf-8").strip()
        parts.append(f"\n\n---\n\n# {label}\n\n")
        parts.append(f"> **源文件**：`docs/{rel}`\n\n")
        parts.append(body)
        parts.append("\n")

    OUT.write_text("".join(parts).rstrip() + "\n", encoding="utf-8")
    rel_out = OUT.relative_to(REPO_UFC)
    print(f"Wrote {rel_out} ({OUT.stat().st_size} bytes, {len(build_pieces())} sections)")


if __name__ == "__main__":
    main()
