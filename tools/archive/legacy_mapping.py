#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC Legacy Code Mapping Tool
Maps existing f90 files to new skeleton conventions and identifies:
1. Files following new naming (_Def/_Core/_Brg) — conforming
2. Files with legacy naming (_Ops, etc.) — need migration
3. Files without clear skeleton mapping — manual review needed
4. Naming convention violations (four-scene check)
"""
import os
import re
import sys
import glob
from collections import defaultdict

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

LAYER_ABBREV = {"L1_IF": "IF", "L2_NM": "NM", "L3_MD": "MD",
                "L4_PH": "PH", "L5_RT": "RT", "L6_AP": "AP"}

NEW_PATTERNS = {
    "Def":  re.compile(r'_Def\.f90$', re.IGNORECASE),
    "Core": re.compile(r'_Core\.f90$', re.IGNORECASE),
    "Brg":  re.compile(r'_Brg\.f90$', re.IGNORECASE),
    "Proc": re.compile(r'_Proc\.f90$', re.IGNORECASE),
}

LEGACY_PATTERNS = {
    "Ops":      re.compile(r'_Ops\d?\.f90$', re.IGNORECASE),
    "Impl":     re.compile(r'Impl\.f90$', re.IGNORECASE),
    "Old_Defn": re.compile(r'Defn\.f90$', re.IGNORECASE),
    "Legacy_UF": re.compile(r'^UF_', re.IGNORECASE),
}

PREFIX_RE = re.compile(r'^(IF|NM|MD|PH|RT|AP)_')

SKIP_DIRS = {"contracts", "__pycache__", ".git"}


def classify_file(filename, layer):
    """Classify a file as conforming, legacy, or unmapped."""
    abbr = LAYER_ABBREV.get(layer, "")

    for name, pat in NEW_PATTERNS.items():
        if pat.search(filename):
            return "conforming", name

    for name, pat in LEGACY_PATTERNS.items():
        if pat.search(filename):
            return "legacy", name

    if PREFIX_RE.match(filename):
        if filename.startswith(abbr + "_"):
            return "unmapped_correct_prefix", "has_layer_prefix"
        else:
            return "unmapped_wrong_prefix", "wrong_layer_prefix"

    return "unmapped_no_prefix", "no_prefix"


def main():
    stats = defaultdict(lambda: defaultdict(int))
    all_files = []
    violations = []

    for layer in sorted(os.listdir(UFC_CORE)):
        layer_path = os.path.join(UFC_CORE, layer)
        if not os.path.isdir(layer_path) or not layer.startswith("L"):
            continue

        for fpath in glob.glob(os.path.join(layer_path, "**", "*.f90"), recursive=True):
            rel = os.path.relpath(fpath, UFC_CORE).replace("\\", "/")
            filename = os.path.basename(fpath)
            category, detail = classify_file(filename, layer)

            stats[layer][category] += 1
            all_files.append((layer, rel, category, detail))

            if category == "unmapped_wrong_prefix":
                violations.append((layer, rel, detail))

    report_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                              "REPORTS", "legacy_mapping_report.md")

    with open(report_path, 'w', encoding='utf-8') as f:
        f.write("# UFC 存量代码映射报告\n\n")
        f.write(f"> 生成日期: 2026-04-25\n\n")

        f.write("## 分类汇总\n\n")
        f.write("| 层 | 合规 | 遗留命名 | 无映射(正确前缀) | 无映射(错误前缀) | 无前缀 | 总计 |\n")
        f.write("|---|---|---|---|---|---|---|\n")
        total = defaultdict(int)
        for layer in sorted(stats.keys()):
            s = stats[layer]
            row_total = sum(s.values())
            f.write(f"| {layer} | {s['conforming']} | {s['legacy']} | "
                   f"{s['unmapped_correct_prefix']} | {s['unmapped_wrong_prefix']} | "
                   f"{s['unmapped_no_prefix']} | {row_total} |\n")
            for k, v in s.items():
                total[k] += v
        grand_total = sum(total.values())
        f.write(f"| **合计** | **{total['conforming']}** | **{total['legacy']}** | "
               f"**{total['unmapped_correct_prefix']}** | **{total['unmapped_wrong_prefix']}** | "
               f"**{total['unmapped_no_prefix']}** | **{grand_total}** |\n\n")

        conforming_pct = total['conforming'] / grand_total * 100 if grand_total else 0
        f.write(f"**合规率**: {conforming_pct:.1f}%\n\n")

        f.write("## 遗留命名文件清单\n\n")
        f.write("以下文件使用旧命名约定（`_Ops`、`Impl`、`Defn`、`UF_` 前缀），建议逐步迁移：\n\n")
        f.write("| 层 | 文件路径 | 遗留类型 |\n")
        f.write("|---|---|---|\n")
        for layer, rel, cat, detail in all_files:
            if cat == "legacy":
                f.write(f"| {layer} | `{rel}` | {detail} |\n")

        f.write("\n## 前缀违规文件\n\n")
        f.write("以下文件的层前缀与所在层不一致：\n\n")
        f.write("| 层 | 文件路径 | 问题 |\n")
        f.write("|---|---|---|\n")
        for layer, rel, detail in violations:
            f.write(f"| {layer} | `{rel}` | {detail} |\n")

        f.write("\n## 迁移建议\n\n")
        f.write("1. **优先迁移**: `_Ops` → `_Core` 重命名（最大批量）\n")
        f.write("2. **逐步清理**: `Impl` / `Defn` → `_Core` / `_Def`\n")
        f.write("3. **前缀修正**: 跨层前缀文件移入正确的层或通过 Bridge 引用\n")
        f.write("4. **保留**: `UF_` 前缀的用户接口文件可保留（约定为通用接口）\n")

    print("=" * 72)
    print("UFC Legacy Code Mapping Report")
    print("=" * 72)
    print(f"\nTotal files: {grand_total}")
    print(f"Conforming (_Def/_Core/_Brg/_Proc): {total['conforming']} ({conforming_pct:.1f}%)")
    print(f"Legacy naming (_Ops/Impl/Defn/UF_): {total['legacy']}")
    print(f"Unmapped (correct prefix): {total['unmapped_correct_prefix']}")
    print(f"Unmapped (wrong prefix): {total['unmapped_wrong_prefix']}")
    print(f"Unmapped (no prefix): {total['unmapped_no_prefix']}")
    print(f"\nPrefix violations: {len(violations)}")
    print(f"\nReport saved: {report_path}")
    print("=" * 72)


if __name__ == "__main__":
    main()
