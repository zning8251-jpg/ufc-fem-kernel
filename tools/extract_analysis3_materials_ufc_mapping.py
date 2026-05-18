#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extract ANALYSIS_3.pdf (Abaqus Analysis User's Guide Volume III — Materials).

Per UFC/.cursor/rules/pdf-processing.mdc:
  - TOC + keyword page discovery: **PyMuPDF (fitz)**
  - **Tables / Data lines blocks**: **pdfplumber** (`extract_tables`)

Outputs:
  - REPORTS/analysis3_materials_ufc_mapping.json
  - REPORTS/analysis3_material_keyword_ufc_fields.csv
  - docs/03_Domain_Pillars/Abaqus_Manual_Alignment/ANALYSIS_3_Materials_PartV_Manual.md
    (Part I only, between HTML markers; see stubs ANALYSIS_3_Materials_UFC_Mapping.md / _Family_UFC_TYPE_Catalog.md)
"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANUAL = ROOT / "Manual" / "ANALYSIS_3.pdf"
OUT_JSON = ROOT / "REPORTS" / "analysis3_materials_ufc_mapping.json"
OUT_CSV = ROOT / "REPORTS" / "analysis3_material_keyword_ufc_fields.csv"
ALIGN = ROOT / "docs" / "03_Domain_Pillars" / "Abaqus_Manual_Alignment"
MERGED_MANUAL = ALIGN / "ANALYSIS_3_Materials_PartV_Manual.md"
CATALOG_MD = ALIGN / "ANALYSIS_3_Materials_Family_UFC_TYPE_Catalog.md"
STUB_MAPPING = ALIGN / "ANALYSIS_3_Materials_UFC_Mapping.md"
MARK_P1_BEGIN = "<!-- ANALYSIS3_AUTO_PART1_BEGIN -->"
MARK_P1_END = "<!-- ANALYSIS3_AUTO_PART1_END -->"

# UFC 11 主族（与 L3_MD/Material/CONTRACT.md、MD_Ana_Comp.f90 一致）
FAMILY_DIRS = {
    1: ("Elastic", "Elas/", "Elas/"),
    2: ("Plastic", "Plast/", "Plast/"),
    3: ("Geo", "Geo/", "Geo/"),
    4: ("Hyper", "HyperElas/", "HyperElas/"),
    5: ("VE", "Viscoelas/", "Viscoelas/"),
    6: ("VP/Creep", "Creep/", "Creep/"),
    7: ("Damage", "Damage/", "Damage/"),
    8: ("Composite", "Composite/", "Composite/"),
    9: ("Heat/Thermal", "Thermal/", "Thermal/"),
    10: ("Acoustic", "Acoustic/", "Acoustic/"),
    11: ("EM/User", "User/", "Contract+Dispatch"),
}

CHAPTER_RE = re.compile(r"^(?P<num>2[1-6])\.\s*(?P<rest>.+)$")
SUBSEC_RE = re.compile(r"^(?P<num>2[1-6]\.\d+(?:\.\d+)?)\s+(?P<rest>.+)$")

# Single-token *KEYWORD (materials volume common)
STAR_TOKEN = re.compile(r"\*\s*([A-Z][A-Z0-9_]{1,40})\b")
STAR_USER_MAT = re.compile(r"\*\s*USER\s+MATERIAL\b", re.I)
STAR_SPECIFIC_HEAT = re.compile(r"\*\s*SPECIFIC\s+HEAT\b", re.I)
STAR_DRUCKER_PRAGER = re.compile(r"\*\s*DRUCKER\s+PRAGER\b", re.I)
STAR_MOHR_COULOMB = re.compile(r"\*\s*MOHR\s+COULOMB\b", re.I)

# Canonical *MATERIAL-related options (uppercase token after *)
PRIORITY_KEYWORDS = frozenset(
    {
        "DENSITY",
        "ELASTIC",
        "PLASTIC",
        "CREEP",
        "HYPOELASTIC",
        "HYPERELASTIC",
        "HYPERFOAM",
        "VISCOELASTIC",
        "USERMATERIAL",  # normalized from USER MATERIAL
        "CONDUCTIVITY",
        "EXPANSION",
        "SPECIFICHEAT",
        "LATENTHEAT",
        "DAMAGEINITIATION",
        "DAMAGEEVOLUTION",
        "DAMAGESTABILIZATION",
        "EOS",
        "POROUSMETALPLASTICITY",
        "CRUSHABLEFOAM",
        "CASTIRONPLASTICITY",
        "CLAYPLASTICITY",
        "DRUCKERPRAGER",
        "MOHRCOULOMB",
        "CAPPLASTICITY",
        "CONCRETE",
        "FABRIC",
        "HEATGENERATION",
    }
)


def _norm_keyword_token(s: str) -> str:
    t = s.upper().replace(" ", "").replace("\u00a0", "")
    return t


# Static field-level map: Abaqus option → UFC host TYPE / logical field (see MD_Mat_Def.f90).
# ufc_host_type uses **document canonical** names (e.g. MD_Mat_Desc); Fortran PUBLIC is MD_Mat_Desc since L3 Material CONTRACT v2.2 — see ANALYSIS_3_Materials_PartV_Manual.md Part II.
# "props(k)" = packed order after Populate; exact index is model-specific.
KEYWORD_UFC_FIELDMAP: dict[str, list[dict[str, str]]] = {
    "DENSITY": [
        {
            "abaqus_quantity": "ρ (mass density)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(k) packed by Populate OR section-level density bundle",
            "family_desc_anchor": "— (跨族)",
            "code_ref": "MD_Mat_Def.f90 :: PUBLIC MD_Mat_Desc",
        },
    ],
    "ELASTIC": [
        {
            "abaqus_quantity": "Isotropic: E, ν (or G, K) / Orthotropic: Dij",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); cfg%matModel / cfg%materialType",
            "family_desc_anchor": "`L3_MD/Material/Elas/*` + `PH_Mat_Elas_*`",
            "code_ref": "MD_Mat_Def.f90 :: PUBLIC MD_MatDesc + 各族线弹 Desc",
        },
    ],
    "PLASTIC": [
        {
            "abaqus_quantity": "yield + hardening parameters",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); behavior; pop%nStateV",
            "family_desc_anchor": "`L3_MD/Material/Plast/*` + `PH_Mat_*_Plast`",
            "code_ref": "MD_Mat_Def.f90 :: PUBLIC MD_MatDesc / MD_MAT_CATEGORY_PL",
        },
    ],
    "CREEP": [
        {
            "abaqus_quantity": "creep law constants",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); pop%nStateV (SDV)",
            "family_desc_anchor": "`L3_MD/Material/Creep/`",
            "code_ref": "MD_MAT_CATEGORY_CR",
        },
    ],
    "HYPOELASTIC": [
        {
            "abaqus_quantity": "C_ijkl rate-based moduli",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`Elas/` hypo 分支",
            "code_ref": "MD_MAT_CATEGORY_EL",
        },
    ],
    "HYPERELASTIC": [
        {
            "abaqus_quantity": "strain-energy coefficients (C_i, D_i, …)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); cfg%matModel",
            "family_desc_anchor": "`HyperElas/` + `PH_Mat_HyperElas_*`",
            "code_ref": "MD_MAT_MODEL_HYP",
        },
    ],
    "HYPERFOAM": [
        {
            "abaqus_quantity": "foam hyperelastic parameters",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`HyperElas/`",
            "code_ref": "MD_MAT_MODEL_HYP",
        },
    ],
    "VISCOELASTIC": [
        {
            "abaqus_quantity": "Prony / g_i, τ_i / frequency data",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); pop%nStateV",
            "family_desc_anchor": "`Viscoelas/` + `PH_Mat_Visco_*`",
            "code_ref": "MD_MAT_MODEL_VISC",
        },
    ],
    "USERMATERIAL": [
        {
            "abaqus_quantity": "PROPS, NPROPS, STATEV",
            "ufc_host_type": "MD_Mat_Desc + MD_Mat_UMAT_Intf / MatCtxLegacy",
            "ufc_field_logical": "props(:); nProps; nStateV; materialType=USER",
            "family_desc_anchor": "`User/` + `PH_UMAT_*`",
            "code_ref": "MD_Mat_Def.f90 :: PUBLIC MD_MAT_UMAT_Intf (文档 MD_Mat_UMAT_Intf), MatCtxLegacy",
        },
    ],
    "CONDUCTIVITY": [
        {
            "abaqus_quantity": "k (thermal conductivity tensor / isotropic)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:) via thermal Populate",
            "family_desc_anchor": "`Thermal/`",
            "code_ref": "MD_MAT_CATEGORY_EL + thermal coupling flags",
        },
    ],
    "EXPANSION": [
        {
            "abaqus_quantity": "α (CTE)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`Thermal/` + elastic coupling",
            "code_ref": "PUBLIC MD_MatDesc + thermal tables",
        },
    ],
    "SPECIFICHEAT": [
        {
            "abaqus_quantity": "c_p",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`Thermal/`",
            "code_ref": "—",
        },
    ],
    "DRUCKERPRAGER": [
        {
            "abaqus_quantity": "β, d, ψ, …",
            "ufc_host_type": "MD_Mat_Desc + MD_Mat_DP_Desc",
            "ufc_field_logical": "主卡 props + Populate → MD_Mat_DP_Desc typed fields",
            "family_desc_anchor": "`L3_MD/Material/Geo/MD_Geo_DruckerPrager.f90`",
            "code_ref": "MD_Mat_DP_Desc; props on PUBLIC MD_MatDesc",
        },
    ],
    "MOHRCOULOMB": [
        {
            "abaqus_quantity": "φ, c, ψ, …",
            "ufc_host_type": "MD_Mat_Desc + MD_Mat_Mohr_Coulomb_Desc",
            "ufc_field_logical": "props(:) or typed Geo Desc",
            "family_desc_anchor": "`Geo/PH_MatGeo_MohrCoulomb*`",
            "code_ref": "MD_MatPLG_MohrCoulomb :: MohrCoulomb_MatDesc (文档 MD_Mat_Mohr_Coulomb_Desc)",
        },
    ],
    "CAPPLASTICITY": [
        {
            "abaqus_quantity": "Cap / transition surface params",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`Geo/`",
            "code_ref": "—",
        },
    ],
    "CONCRETE": [
        {
            "abaqus_quantity": "tension stiffening / damage vars",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); pop%nStateV",
            "family_desc_anchor": "`Damage/` + `Plast/`",
            "code_ref": "MD_MAT_CATEGORY_DA",
        },
    ],
    "EOS": [
        {
            "abaqus_quantity": "EOS parameters",
            "ufc_host_type": "MD_Mat_Desc / User bundle",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`User/`",
            "code_ref": "MD_MAT_MODEL_USER",
        },
    ],
    "FABRIC": [
        {
            "abaqus_quantity": "fabric stiffness / nonlinear shear",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:); cfg%behavior",
            "family_desc_anchor": "`Geo/` / `Composite/`（织物）",
            "code_ref": "MD_MAT_CATEGORY_GEOMAT / COMPOSITE",
        },
    ],
    "LATENTHEAT": [
        {
            "abaqus_quantity": "L, solidus, liquidus (latent heat)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:)",
            "family_desc_anchor": "`Thermal/`",
            "code_ref": "—",
        },
    ],
    "HEATGENERATION": [
        {
            "abaqus_quantity": "r (heat generation rate)",
            "ufc_host_type": "MD_Mat_Desc",
            "ufc_field_logical": "props(:) / coupled thermal load",
            "family_desc_anchor": "`Thermal/`",
            "code_ref": "—",
        },
    ],
}


def _demote_md_heading_line(line: str, extra: int = 1) -> str:
    m = re.match(r"^(#{1,6})(\s.*)$", line)
    if not m:
        return line
    n = min(6, len(m.group(1)) + extra)
    return "#" * n + m.group(2)


def _demote_mapping_lines(lines: list[str]) -> list[str]:
    out: list[str] = []
    for i, ln in enumerate(lines):
        if i == 0 and ln.startswith("# ") and not ln.startswith("##"):
            continue
        out.append(_demote_md_heading_line(ln, 1))
    return out


def _stub_mapping_md() -> str:
    return (
        "# 已并入综合手册（Part I）\n\n"
        "本页原「材料卷 × UFC 映射」正文已合并至 "
        "**[`ANALYSIS_3_Materials_PartV_Manual.md`](./ANALYSIS_3_Materials_PartV_Manual.md)** 的 "
        "**Part I — 手册目录、页码与字段映射**（脚本每次运行会刷新该节标记区）。\n"
    )


def _stub_catalog_md() -> str:
    return (
        "# 已并入综合手册（Part II）\n\n"
        "本页原「分族 × 数据结构 × TYPE 总册」正文已合并至 "
        "**[`ANALYSIS_3_Materials_PartV_Manual.md`](./ANALYSIS_3_Materials_PartV_Manual.md)** 的 "
        "**Part II — 分族、关键字与 TYPE 总册**。\n\n"
        "若需单独编辑 Part II 沉淀表，请直接编辑合并手册中该部分（脚本 **不** 覆盖 Part II）。\n"
    )


def _bootstrap_merged_manual(mapping_body: str) -> str:
    """First-time merge: pull static Part II from legacy catalog file if still full."""
    part2 = ""
    try:
        raw = CATALOG_MD.read_text(encoding="utf-8")
    except OSError:
        raw = ""
    if "## 0. TYPE" in raw or "## 0." in raw:
        clines = raw.splitlines()
        if clines and clines[0].startswith("# ") and not clines[0].startswith("##"):
            clines = clines[1:]
        part2 = "\n".join(_demote_md_heading_line(ln, 1) for ln in clines).strip() + "\n"
        part2 = part2.replace(
            "| `ANALYSIS_3_Materials_UFC_Mapping.md` | Part V TOC × `mat_family` + pdfplumber 表预览入口。 |",
            "| 本文 **Part I**（脚本刷新标记区） | 手册 Part V TOC × `mat_family` + pdfplumber 表预览入口。 |",
        )
    else:
        part2 = (
            "### （Part II 未从旧版 Catalog 引导）\n\n"
            "请从版本库恢复 `ANALYSIS_3_Materials_Family_UFC_TYPE_Catalog.md` 全文后重跑一次本脚本，"
            "或手抄 Part II 至本文件。\n"
        )
    return (
        "# ANALYSIS_3 材料卷（Part V）— 综合手册\n\n"
        "**版本**：v1.2（合并版） — 与 Abaqus 2016 Analysis User’s Guide **Volume III / Part V Materials** 对齐  \n"
        "**真源**：`UFC/Manual/ANALYSIS_3.pdf` + `UFC/REPORTS/analysis3_materials_ufc_mapping.json`、"
        "`analysis3_material_keyword_ufc_fields.csv`（本脚本）。  \n"
        "**合同**：`UFC/ufc_core/L3_MD/Material/CONTRACT.md`、`L4_PH/Material/CONTRACT.md`、"
        "`L3_MD/Material/Contract/MD_Mat_Def.f90`。  \n"
        "**结构**：**Part I**（手册 TOC / 页码 / 字段预览，**脚本自动替换**）+ **Part II**（分族与 TYPE 沉淀，**人工维护**）。\n\n"
        "---\n\n"
        "## Part I — 手册目录、页码与字段映射（自动更新）\n\n"
        "下列区块由 `extract_analysis3_materials_ufc_mapping.py` **整段替换**（勿在标记之间手改）。\n\n"
        f"{MARK_P1_BEGIN}\n"
        f"{mapping_body.rstrip()}\n"
        f"{MARK_P1_END}\n\n"
        "---\n\n"
        "## Part II — 分族、关键字与 TYPE 总册（人工沉淀）\n\n"
        '<a id="part-ii-type-naming"></a>\n\n'
        f"{part2}"
    )


def _splice_part1(merged_text: str, mapping_body: str) -> str:
    if MARK_P1_BEGIN not in merged_text or MARK_P1_END not in merged_text:
        return merged_text
    pre, _, rest = merged_text.partition(MARK_P1_BEGIN)
    _, _, post = rest.partition(MARK_P1_END)
    return (
        pre.rstrip()
        + MARK_P1_BEGIN
        + "\n"
        + mapping_body.rstrip()
        + "\n"
        + MARK_P1_END
        + post
    )


def _classify(title: str) -> tuple[int | None, str, str]:
    raw = title.strip()
    low = raw.lower()
    mch = CHAPTER_RE.match(raw)
    chap = int(mch.group("num")) if mch else None

    if chap == 21:
        return None, "ch21_meta", "`MD_Mat_Desc`（源码 `MD_MatDesc`）/ `PH_Mat_Desc` 通用：材料库、组合表、密度等跨族属性"

    if "acoustic" in low and chap == 26:
        return 10, "keyword", "`L3_MD/Material/Acoustic/` · `PH_Mat_Acoustic_*`"
    if "user-defined" in low or "umat" in low or "vumat" in low:
        return 11, "keyword", "`User/` + `PH_UMAT_*` / Dispatch 适配"
    if "hydrodynamic" in low or "equation of state" in low or "eos" in low:
        return 11, "keyword", "`User/`（SPU/EOS）或显式专用路径 — 见 CONTRACT 注"
    if "thermal" in low and ("conductivity" in low or "specific heat" in low or "inelastic heat" in low):
        return 9, "keyword", "`Thermal/` · `PH_Mat_Thermal_*`"
    if "electrical" in low or "magnetic" in low or "piezo" in low:
        return 11, "keyword", "`User/` 电磁/耦合特殊 — 与 `GROUP_MAT_COMPAT` G5 对齐"
    if "mass diffusion" in low:
        return 11, "keyword", "扩散场 — 偏 `L3_MD` Field/MassDiff，非结构 11 主族本构核"
    if "concrete" in low or "smeared cracking" in low or "damaged plasticity" in low:
        return 7, "keyword", "`Damage/` + `Plast/` 交叉 — UFC 以 `PH_MAT_DAMAGE` 为主标记"
    if "fabric" in low or "jointed" in low:
        return 3, "keyword", "`Geo/` 或 `Composite/` 扩展 — 当前多走 `Geo`/anisotropic 路由"
    if "crushable foam" in low:
        return 2, "keyword", "`Plast/`（金属泡沫）— 与 Geo 区分见手册"
    if "drucker" in low or "mohr" in low or "critical state" in low or "clay" in low:
        return 3, "keyword", "`Geo/` — 例：`MD_Geo_DruckerPrager` + `PH_Mat_DP_*`"
    if "metal plasticity" in low or "johnson-cook" in low or "porous metal" in low or "gurson" in low:
        return 2, "keyword", "`Plast/`"
    if "rate-dependent plasticity: creep" in low or ("creep and swelling" in low):
        return 6, "keyword", "`Creep/` — 与 `Plast/` 率相关小节交叉，以关键字为准"
    if "creep" in low and "yield" in low and "anisotropic" in low:
        return 2, "keyword", "`Plast/`（屈服+蠕变各向异性 — 主塑性族）"
    if "creep" in low or "swelling" in low:
        return 6, "keyword", "`Creep/` — 与 `Plast/` 率相关小节交叉，以关键字为准"
    if "inelastic mechanical" in low or chap == 23:
        return 2, "chapter", "`Plast/` 为主族；子节经关键字细分为 3/6/7"
    if "progressive damage" in low or chap == 24:
        return 7, "chapter", "`Damage/`"
    if "hydrodynamic" in low or chap == 25:
        return 11, "chapter", "`User/` / 状态方程"
    if "other material" in low or chap == 26:
        return 9, "chapter", "`Thermal/` / `Acoustic/` / `User/` — 子节关键字再分"

    if "hyperelastic" in low or "hyperfoam" in low or "rubberlike" in low or "mullins" in low:
        return 4, "keyword", "`HyperElas/`"
    if "stress softening" in low:
        return 4, "keyword", "`HyperElas/`（Mullins 等）"
    if "viscoelastic" in low or "prony" in low or "wlf" in low or "rheological" in low or "hysteresis" in low:
        return 5, "keyword", "`Viscoelas/`"
    if "porous elasticity" in low or "elastic behavior of porous" in low:
        return 1, "keyword", "手册在弹性卷 — UFC：`Elas/` 弹性矩阵 + `Geo/` 孔压耦合描述分工见域合同"
    if "hypoelastic" in low:
        return 1, "keyword", "`Elas/`（率型表述）"
    if "linear elastic" in low or "no compression" in low or "plane stress orthotropic" in low:
        return 1, "keyword", "`Elas/`"
    if "elastic mechanical" in low or chap == 22:
        return 1, "chapter", "`Elas/` 为主；子节含 4/5 等"

    if "density" in low:
        return None, "general_prop", "`MD_Mat_Desc`（源码 `MD_MatDesc`）/ `PH_Mat_Desc` 通用标量 `density` 字段（跨族）"

    return None, "unresolved", "需人工对照手册正文或关键字表"


def _part5_toc_entries(toc: list[list]) -> list[dict]:
    rows: list[dict] = []
    in_part5 = False
    for lvl, title, page in toc:
        title = (title or "").strip()
        if "Part V" in title and "Material" in title:
            in_part5 = True
            rows.append({"level": lvl, "title": title, "page_1based": page, "part": "V_header"})
            continue
        if not in_part5:
            continue
        if lvl <= 3 and title.startswith("Part ") and "Part V" not in title:
            break
        if title.startswith("27.") or title.startswith("28."):
            break
        rows.append({"level": lvl, "title": title, "page_1based": page, "part": "V_body"})
    return rows


def _dedupe_toc_rows(rows: list[dict]) -> list[dict]:
    seen: set[tuple[str, int]] = set()
    out: list[dict] = []
    for r in rows:
        k = (r.get("title", ""), int(r.get("page_1based", 0)))
        if k in seen:
            continue
        seen.add(k)
        out.append(r)
    return out


def _major_only(rows: list[dict]) -> list[dict]:
    out: list[dict] = []
    for r in rows:
        if r.get("part") == "V_header":
            out.append(r)
            continue
        t = r["title"]
        if CHAPTER_RE.match(t) or SUBSEC_RE.match(t):
            if r["level"] <= 6:
                out.append(r)
    return out


def _snippet_for_page(doc, p1: int, needles: tuple[str, ...], cap: int = 14000) -> str:
    if p1 < 1 or p1 > doc.page_count:
        return ""
    txt = doc.load_page(p1 - 1).get_text("text") or ""
    lines = [ln for ln in txt.splitlines() if any(n in ln for n in needles)]
    if not lines:
        return txt[:cap]
    return "\n".join(lines[:80])[:cap]


def _discover_material_keywords_fitz(path: Path, page_lo_1: int, page_hi_1: int) -> dict[str, list[int]]:
    import fitz

    doc = fitz.open(path)
    hits: dict[str, list[int]] = {}
    try:
        lo = max(1, page_lo_1) - 1
        hi = min(doc.page_count, page_hi_1)
        for i in range(lo, hi):
            text = doc.load_page(i).get_text("text") or ""
            if STAR_USER_MAT.search(text):
                tok = "USERMATERIAL"
                hits.setdefault(tok, []).append(i + 1)
            if STAR_SPECIFIC_HEAT.search(text):
                hits.setdefault("SPECIFICHEAT", []).append(i + 1)
            if STAR_DRUCKER_PRAGER.search(text):
                hits.setdefault("DRUCKERPRAGER", []).append(i + 1)
            if STAR_MOHR_COULOMB.search(text):
                hits.setdefault("MOHRCOULOMB", []).append(i + 1)
            for m in STAR_TOKEN.finditer(text):
                raw = m.group(1).strip()
                tok = _norm_keyword_token(raw)
                if tok in PRIORITY_KEYWORDS or raw.upper() in PRIORITY_KEYWORDS:
                    hits.setdefault(tok, []).append(i + 1)
    finally:
        doc.close()
    for k in hits:
        hits[k] = sorted(set(hits[k]))
    return hits


def _pages_for_table_extraction(kw_pages: dict[str, list[int]], max_pages: int) -> list[int]:
    """Include keyword page and following page (Data lines often span)."""
    acc: list[int] = []
    for kw in sorted(kw_pages.keys()):
        for p in kw_pages[kw]:
            for d in (0, 1):
                acc.append(p + d)
    out: list[int] = []
    seen: set[int] = set()
    for p in sorted(acc):
        if p in seen or p < 1:
            continue
        seen.add(p)
        out.append(p)
        if len(out) >= max_pages:
            break
    return out


def _extract_tables_pdfplumber(path: Path, pages_1based: list[int]) -> list[dict]:
    import pdfplumber

    out: list[dict] = []
    with pdfplumber.open(str(path)) as pdf:
        nmax = len(pdf.pages)
        for p1 in pages_1based:
            if p1 < 1 or p1 > nmax:
                continue
            page = pdf.pages[p1 - 1]
            try:
                tbls = page.extract_tables(
                    table_settings={
                        "vertical_strategy": "lines",
                        "horizontal_strategy": "lines",
                        "intersection_tolerance": 5,
                    }
                ) or []
            except Exception:  # noqa: BLE001
                tbls = page.extract_tables() or []
            if not tbls:
                continue
            # Keep tables that look like parameter/Data line blocks
            kept: list[list[list[str | None]]] = []
            for t in tbls:
                flat = "\n".join(" | ".join((c or "") for c in row) for row in t).upper()
                if any(
                    x in flat
                    for x in (
                        "DATA",
                        "TYPE",
                        "PARAMETER",
                        "PROPERTY",
                        "YOUNG",
                        "POISSON",
                        "DENSITY",
                    )
                ):
                    kept.append(t)
            if kept:
                out.append({"page_1based": p1, "tables": kept})
    return out


def _table_text_preview(table: list[list[str | None]], max_rows: int = 12) -> str:
    lines: list[str] = []
    for row in table[:max_rows]:
        cells = [(c or "").strip().replace("\n", " ") for c in row]
        lines.append(" | ".join(cells))
    return "\n".join(lines)


def _abaqus_star_label(kw: str) -> str:
    if kw == "USERMATERIAL":
        return "*USER MATERIAL"
    if kw == "DRUCKERPRAGER":
        return "*DRUCKER PRAGER"
    if kw == "MOHRCOULOMB":
        return "*MOHR COULOMB"
    if kw == "SPECIFICHEAT":
        return "*SPECIFIC HEAT"
    return f"*{kw}"


def _build_csv_rows(
    kw_pages: dict[str, list[int]], tables_payload: list[dict]
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    table_by_page = {t["page_1based"]: t["tables"] for t in tables_payload}
    for kw in sorted(kw_pages.keys()):
        static = KEYWORD_UFC_FIELDMAP.get(kw, [])
        pages = ",".join(str(p) for p in kw_pages[kw][:20])
        if static:
            for entry in static:
                rows.append(
                    {
                        "abaqus_keyword": _abaqus_star_label(kw),
                        "manual_pages": pages,
                        "abaqus_quantity": entry.get("abaqus_quantity", ""),
                        "ufc_host_type": entry.get("ufc_host_type", ""),
                        "ufc_field_logical": entry.get("ufc_field_logical", ""),
                        "family_desc_anchor": entry.get("family_desc_anchor", ""),
                        "code_ref": entry.get("code_ref", ""),
                        "pdfplumber_table_preview": "",
                    }
                )
        else:
            rows.append(
                {
                    "abaqus_keyword": _abaqus_star_label(kw),
                    "manual_pages": pages,
                    "abaqus_quantity": "(no static map — extend KEYWORD_UFC_FIELDMAP)",
                    "ufc_host_type": "MD_Mat_Desc",
                    "ufc_field_logical": "props(:)",
                    "family_desc_anchor": "—",
                    "code_ref": "MD_Mat_Def.f90",
                    "pdfplumber_table_preview": "",
                }
            )
        preview = ""
        for p in kw_pages[kw][:4]:
            for q in (p, p + 1):
                tbls = table_by_page.get(q)
                if not tbls:
                    continue
                blob = "\n".join(_table_text_preview(t, 14) for t in tbls[:2]).upper()
                lab = _abaqus_star_label(kw).upper().replace(" ", "").replace("*", "")
                if lab and lab in blob.replace(" ", ""):
                    preview = _table_text_preview(tbls[0], 14)
                    break
                if not preview:
                    preview = _table_text_preview(tbls[0], 10)
            lab2 = _abaqus_star_label(kw).upper().replace(" ", "").replace("*", "")
            if preview and lab2 and lab2 in preview.upper().replace(" ", ""):
                break
        if not preview:
            for p in kw_pages[kw][:2]:
                for q in (p, p + 1):
                    tbls = table_by_page.get(q)
                    if tbls:
                        preview = _table_text_preview(tbls[0], 10)
                        break
                if preview:
                    break
        if preview:
            for r in reversed(rows):
                if r["abaqus_keyword"] == _abaqus_star_label(kw):
                    r["pdfplumber_table_preview"] = preview[:1800]
                    break
    return rows


def main() -> int:
    try:
        import fitz
    except ImportError:
        print("pip install PyMuPDF", file=sys.stderr)
        return 2

    try:
        import pdfplumber  # noqa: F401
    except ImportError:
        print("pip install pdfplumber", file=sys.stderr)
        return 2

    if not MANUAL.is_file():
        print(f"Missing {MANUAL}", file=sys.stderr)
        return 1

    doc = fitz.open(MANUAL)
    try:
        toc = doc.get_toc(simple=True) or []
        part5 = _part5_toc_entries([[a, b, c] for a, b, c in toc])
        major = _major_only(part5)
        hdr = next((r for r in part5 if r.get("part") == "V_header"), None)
        if hdr:
            major = [hdr] + major

        mapped: list[dict] = []
        for r in major:
            if r.get("part") == "V_header":
                mapped.append({**r, "ufc_mat_family": None, "ufc_note": "Part V 起点"})
                continue
            fam, how, anchor = _classify(r["title"])
            name, l3, l4 = (None, None, None)
            if fam is not None and fam in FAMILY_DIRS:
                name, l3, l4 = FAMILY_DIRS[fam]
            mapped.append(
                {
                    **r,
                    "ufc_mat_family": fam,
                    "ufc_family_name": name,
                    "ufc_l3_material_subdir": l3,
                    "ufc_l4_material_subdir": l4,
                    "classification": how,
                    "ufc_data_anchor": anchor,
                }
            )
        mapped = _dedupe_toc_rows(mapped)

        prop_pages = []
        for label, needles in (
            ("density_21_2_1", ("Density", "DENSITY", "Type", "Data line")),
            ("elastic_22_2_1", ("ELASTIC", "Type", "Data line", "Young")),
            ("combine_21_1_3", ("Combining", "behavior", "table")),
        ):
            p = None
            for r in part5:
                tl = r["title"]
                if label.startswith("density") and "21.2.1" in tl and "Density" in tl:
                    p = r["page_1based"]
                    break
                if label.startswith("elastic") and "22.2.1" in tl:
                    p = r["page_1based"]
                    break
                if label.startswith("combine") and "21.1.3" in tl:
                    p = r["page_1based"]
                    break
            if p:
                prop_pages.append(
                    {
                        "label": label,
                        "page_1based": p,
                        "snippet": _snippet_for_page(doc, p, needles),
                    }
                )

        part5_start = next((r["page_1based"] for r in part5 if r.get("part") == "V_header"), 33)
        part5_end = doc.page_count
        kw_pages = _discover_material_keywords_fitz(MANUAL, part5_start, part5_end)
        table_pages = _pages_for_table_extraction(kw_pages, max_pages=72)
        tables_payload = _extract_tables_pdfplumber(MANUAL, table_pages)
        csv_rows = _build_csv_rows(kw_pages, tables_payload)

        payload = {
            "source_pdf": str(MANUAL),
            "page_count": doc.page_count,
            "ufc_reference": "L3_MD/Material/CONTRACT.md §11主族; MD_Ana_Comp.f90 AC_N_MAT_FAM",
            "md_mat_def_reference": "UFC/ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90",
            "toc_part5_major": mapped,
            "property_snippets": prop_pages,
            "keyword_page_index": kw_pages,
            "pdfplumber_table_pages": table_pages,
            "keyword_pdfplumber_tables": tables_payload,
            "keyword_ufc_fieldmap_static": KEYWORD_UFC_FIELDMAP,
        }
    finally:
        doc.close()

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with OUT_CSV.open("w", newline="", encoding="utf-8") as fp:
        w = csv.DictWriter(
            fp,
            fieldnames=[
                "abaqus_keyword",
                "manual_pages",
                "abaqus_quantity",
                "ufc_host_type",
                "ufc_field_logical",
                "family_desc_anchor",
                "code_ref",
                "pdfplumber_table_preview",
            ],
        )
        w.writeheader()
        for row in csv_rows:
            w.writerow(row)

    lines: list[str] = [
        "# ANALYSIS_3（材料卷）× UFC 材料域映射",
        "",
        "> 生成：`UFC/tools/extract_analysis3_materials_ufc_mapping.py`（**PyMuPDF** 目录/翻页 + **pdfplumber** 表格）。",
        "> 真源：手册 **Part V MATERIALS**；UFC **`mat_family` 1..11** 与 `MD_Mat_Def.f90` / 各族 Desc。",
        "> **TYPE 文档规范名**：材料主卡写 **`MD_Mat_Desc`**（三段式）；Fortran `PUBLIC` 仍为 **`MD_MatDesc`** 直至全局重命名；对照见 **[综合手册 Part II](ANALYSIS_3_Materials_PartV_Manual.md#part-ii-type-naming)** 命名表。",
        "",
        "## 1. 不是「一字母一文件」的一一映射",
        "",
        "Abaqus **一章**常对应 **多个关键字行为**（可组合）。本表为 **主锚点**：",
        "",
        "- **`mat_family` = NULL**：跨族元数据（第 21 章材料库/组合/密度等）→ 落在 **`MD_Mat_Desc`**（源码 `MD_MatDesc`）/ **`PH_Mat_Desc`** 通用字段与 Populate 逻辑。",
        "- **子节**：以 **TOC 标题关键字** 归入 11 主族之一；争议项在 JSON 的 `classification` 字段标为 `keyword` / `chapter`。",
        "",
        "## 2. 手册大章 → UFC 主族（章级锚点）",
        "",
        "| Abaqus 章 | 手册主题 | 主 UFC `mat_family` | L3 目录 | L4 目录 |",
        "|-----------|----------|---------------------|---------|---------|",
        "| 21 | Materials: Introduction | （NULL，元数据） | `Contract/` `Domain/` `Shared/` | `PH_Mat_Domain_Core` / Populate |",
        "| 22 | Elastic Mechanical Properties | **1** Elastic | `Elas/`（+部分 `HyperElas/` `Viscoelas/`） | `Elas/` `HyperElas/` `Viscoelas/` |",
        "| 23 | Inelastic Mechanical Properties | **2** Plastic 为主 | `Plast/` `Geo/` `Creep/` | `Plast/` `Geo/` `Creep/` |",
        "| 24 | Progressive Damage and Failure | **7** Damage | `Damage/` | `Damage/` |",
        "| 25 | Hydrodynamic Properties | **11** User/Special | `User/` 等 | `Contract`+显式 |",
        "| 26 | Other Material Properties | **9/10/11** 按节 | `Thermal/` `Acoustic/` `User/` | 对应子目录 |",
        "",
        "## 3. TOC 抽样行（带物理页 + 推断族）",
        "",
        "完整机器表见 **`UFC/REPORTS/analysis3_materials_ufc_mapping.json`**（`toc_part5_major`）。",
        "",
        "| 物理页 | 目录标题 | `mat_family` | UFC 子目录 | 备注 |",
        "|--------|----------|--------------|------------|------|",
    ]
    for r in mapped:
        if r.get("part") == "V_header":
            continue
        fam = r.get("ufc_mat_family")
        fs = str(fam) if fam is not None else "—"
        l3 = r.get("ufc_l3_material_subdir") or "—"
        note = (r.get("ufc_data_anchor") or "")[:60]
        title = r.get("title", "").replace("|", "\\|")
        lines.append(f"| {r.get('page_1based')} | {title[:70]} | {fs} | {l3} | {note} |")

    lines += [
        "",
        "## 4. Properties（数据结构）与 UFC 对齐思路",
        "",
        "手册 **Type / Data lines** → UFC：**`MD_Mat_Desc`**（源码 `MD_MatDesc`；`cfg` / `pop` / `props` / `nProps` / `nStateV` / `behavior` …）见 `MD_Mat_Def.f90`；各族 **typed Desc**（如 **`MD_Mat_DP_Desc`**）由 Populate 从 `props` 解包。",
        "",
        "### 从 PDF 抽样的正文片段（关键词过滤）",
        "",
    ]
    for ps in payload.get("property_snippets", []):
        lines.append(f"#### {ps['label']} — physical page {ps['page_1based']}")
        lines.append("")
        lines.append("```text")
        lines.append((ps.get("snippet") or "(empty)")[:6000])
        lines.append("```")
        lines.append("")

    lines += [
        "## 5. `*MATERIAL` 子选项 ↔ `MD_Mat_Desc` / Desc 字段（字段级）",
        "",
        "- **机器表**：`UFC/REPORTS/analysis3_material_keyword_ufc_fields.csv`（每关键字多行 = 多个物理量映射）。",
        "- **JSON**：`keyword_page_index`（fitz 命中页）、`keyword_pdfplumber_tables`（表格原始网格）、`keyword_ufc_fieldmap_static`（静态绑定，可人工扩展）。",
        "",
        "说明：**pdfplumber** 对扫描版/复杂排版表格可能失败；`pdfplumber_table_preview` 为空不代表手册无表，可增大 `max_pages` 或改 `table_settings` 后重跑。",
        "",
        "### 静态绑定预览（前 18 行）",
        "",
        "| Abaqus keyword | UFC host | UFC logical field | Family Desc |",
        "|----------------|----------|-------------------|-------------|",
    ]
    for row in csv_rows[:18]:
        kw = row["abaqus_keyword"].replace("|", "\\|")
        h = (row["ufc_host_type"] or "")[:28].replace("|", "\\|")
        f = (row["ufc_field_logical"] or "")[:40].replace("|", "\\|")
        a = (row["family_desc_anchor"] or "")[:28].replace("|", "\\|")
        lines.append(f"| {kw} | {h} | {f} | {a} |")

    lines += [
        "",
        "---",
        "",
        "**维护**：扩展 `PRIORITY_KEYWORDS` 与 `KEYWORD_UFC_FIELDMAP`；换手册版本后重跑。",
        "",
    ]

    mapping_body = "\n".join(_demote_mapping_lines(lines)).rstrip() + "\n"

    ALIGN.mkdir(parents=True, exist_ok=True)
    if MERGED_MANUAL.is_file():
        cur = MERGED_MANUAL.read_text(encoding="utf-8")
        if MARK_P1_BEGIN in cur and MARK_P1_END in cur:
            MERGED_MANUAL.write_text(_splice_part1(cur, mapping_body), encoding="utf-8")
        else:
            print(
                "ANALYSIS_3_Materials_PartV_Manual.md exists but lacks Part I markers; "
                "left unchanged (add markers or remove file to regenerate).",
                file=sys.stderr,
            )
    else:
        MERGED_MANUAL.write_text(_bootstrap_merged_manual(mapping_body), encoding="utf-8")

    try:
        c = CATALOG_MD.read_text(encoding="utf-8")
        if ("## 0. TYPE" in c or "## 0." in c) and "已并入综合手册" not in c:
            CATALOG_MD.write_text(_stub_catalog_md(), encoding="utf-8")
    except OSError:
        pass

    STUB_MAPPING.write_text(_stub_mapping_md(), encoding="utf-8")

    print(OUT_JSON)
    print(OUT_CSV)
    print(MERGED_MANUAL)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
