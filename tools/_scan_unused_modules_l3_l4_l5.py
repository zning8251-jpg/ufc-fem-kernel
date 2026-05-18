# -*- coding: utf-8 -*-
"""Heuristic: modules defined under L3_MD / L4_PH / L5_RT with no external USE in ufc_core *.f90."""
from __future__ import annotations

import re
from collections import defaultdict
from pathlib import Path

CORE = Path(__file__).resolve().parents[1]
LAYERS = frozenset({"L3_MD", "L4_PH", "L5_RT"})

# Top-level MODULE only; skip MODULE PROCEDURE via negative lookahead.
MOD_DEF = re.compile(r"^\s*MODULE\s+(?!PROCEDURE)(\w+)\s*(?:!.*)?$", re.I | re.M)
USE_LINE = re.compile(r"^\s*USE\s+(\w+)", re.I | re.M)


def norm_mod(s: str) -> str:
    return s.strip().upper()


def main() -> None:
    f90_files = [
        p
        for p in CORE.rglob("*.f90")
        if "build" not in p.parts and ".git" not in p.parts
    ]

    defs: list[tuple[str, str, str]] = []
    for p in f90_files:
        rel = p.relative_to(CORE)
        layer = rel.parts[0] if rel.parts else ""
        if layer not in LAYERS:
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in MOD_DEF.finditer(text):
            defs.append((layer, rel.as_posix(), m.group(1)))

    # uses[MOD_UPPER][rel_posix] = count
    uses: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    for p in f90_files:
        rel = str(p.relative_to(CORE)).replace("\\", "/")
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in USE_LINE.finditer(text):
            uses[norm_mod(m.group(1))][rel] += 1

    out_lines = [
        "# L3 / L4 / L5：暂未被其他 `.f90` `USE` 的模块（候选「可删 / 待接线」）",
        "",
        "**生成**：`tools/_scan_unused_modules_l3_l4_l5.py`（仓库内一次性扫描）。",
        "",
        "## 说明（必读）",
        "",
        "- **判定**：在 `ufc_core/**/*.f90`（排除 `build/`）中，若某 `MODULE` 定义于 `L3_MD` / `L4_PH` / `L5_RT`，且**除定义文件外**没有任何 `USE module_name` 行命中，则列入下表。",
        "- **漏报**：多行续行的 `USE`、仅被 **C/Python/外部工程** 引用、或仅通过 **INCLUDE / 链接符号** 使用的情况**不会**计入。",
        "- **误报**：测试桩、`PROGRAM` 入口-only、计划中的占位模块可能 legitimately 零引用。删除前请再 `rg` / 构建验证。",
        "- **与合同/桥模块**：部分在 **`BRIDGE_INDEX.md` / 域 `CONTRACT*.md`** 中登记为真值的 `MODULE`，若当前实现尚未被其他 `.f90` 写 `USE`，仍会出现在下表 — **不得仅凭本表删除**，需对照合同与 Populate / 调用链。",
        "",
        "## 按层汇总（零外部 `USE`）",
        "",
    ]

    by_layer: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for layer, rel, mod in defs:
        mu = norm_mod(mod)
        per_file = uses.get(mu, {})
        total = sum(per_file.values())
        in_def = per_file.get(rel, 0)
        external = total - in_def
        if external == 0:
            by_layer[layer].append((mod, rel))

    for layer in sorted(LAYERS):
        rows = sorted(by_layer[layer], key=lambda x: (x[1].lower(), x[0].lower()))
        out_lines.append(f"### {layer}（{len(rows)} 个模块）")
        out_lines.append("")
        out_lines.append("| `MODULE` | 定义文件 |")
        out_lines.append("|----------|----------|")
        for mod, rel in rows:
            out_lines.append(f"| `{mod}` | `{rel}` |")
        out_lines.append("")

    out_path = CORE / "docs" / "_inv" / "UNUSED_MODULE_CANDIDATES_L3_L4_L5.md"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
    print(f"Wrote {out_path} ({sum(len(v) for v in by_layer.values())} modules)")


if __name__ == "__main__":
    main()
