#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build Abaqus U* subroutine ↔ UFC file / module / SIO alignment table.

Primary source of truth: tools/gen_umat_adapter.py :: ALL_SUBROUTINES
  (module_name, core_proc, group, ufc_domain).

Secondary:
  - Legacy adapter stubs: docs/02_Developer_Guide/Legacy_Adapters_Reference/Adapters/**/{NAME}_Adapter.f90
  - ufc_core scan: does `core_proc` appear as SUBROUTINE / INTERFACE target?

Outputs (under UFC/REPORTS/):
  - usub_ufc_alignment.csv
  - usub_ufc_alignment.md
"""
from __future__ import annotations

import csv
import importlib.util
import re
import sys
from pathlib import Path

UFC_ROOT = Path(__file__).resolve().parents[1]
TOOLS = UFC_ROOT / "tools"
GEN = TOOLS / "gen_umat_adapter.py"
ADAPTER_ROOT = (
    UFC_ROOT
    / "docs"
    / "02_Developer_Guide"
    / "Legacy_Adapters_Reference"
    / "Adapters"
)
UFC_CORE = UFC_ROOT / "ufc_core"
REPORTS = UFC_ROOT / "REPORTS"


def load_all_subroutines() -> list[dict]:
    spec = importlib.util.spec_from_file_location("gen_umat_adapter", GEN)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {GEN}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[attr-defined]
    data = getattr(mod, "ALL_SUBROUTINES", None)
    if not isinstance(data, list):
        raise RuntimeError("ALL_SUBROUTINES missing or not a list")
    return data


def layer_hint(group: str) -> str:
    g = group.lower()
    if g in ("material", "element", "contact", "field"):
        return "L4_PH"
    if g in ("load", "bc"):
        return "L5_RT (LoadBC) / L3_MD"
    if g in ("constraint",):
        return "L5_RT / L3_MD"
    if g in ("analysis",):
        return "L5_RT / L6_AP"
    return "TBD"


def find_adapter_path(name: str) -> str:
    hits = sorted(ADAPTER_ROOT.rglob(f"{name}_Adapter.f90"))
    if not hits:
        return ""
    # Prefer path without nested .../Adapters/Adapters/
    def score(p: Path) -> tuple[int, int]:
        s = str(p)
        return (s.count("Adapters\\Adapters") + s.count("Adapters/Adapters"), len(s))

    best = min(hits, key=score)
    return best.relative_to(UFC_ROOT).as_posix()


_core_re_cache: dict[str, re.Pattern[str]] = {}


def core_pattern(core_proc: str) -> re.Pattern[str]:
    if core_proc not in _core_re_cache:
        esc = re.escape(core_proc.strip())
        _core_re_cache[core_proc] = re.compile(
            rf"(SUBROUTINE|FUNCTION|MODULE\s+PROCEDURE)\s+{esc}\b|::\s*{esc}\b",
            re.IGNORECASE,
        )
    return _core_re_cache[core_proc]


def scan_ufc_core_for_core(core_proc: str) -> str:
    pat = core_pattern(core_proc)
    for f in UFC_CORE.rglob("*.f90"):
        try:
            txt = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if pat.search(txt):
            return f.relative_to(UFC_ROOT).as_posix()
    return ""


def scan_ufc_core_five_param_hint(group: str) -> str:
    """Return one representative file in ufc_core that uses canonical five dummy names."""
    needle = re.compile(
        r"SUBROUTINE\s+\w+\s*\([^)]*\bdesc\b[^)]*\bstate\b[^)]*\balgo\b[^)]*\bctx\b[^)]*\bargs\b",
        re.IGNORECASE | re.DOTALL,
    )
    roots: list[Path] = []
    g = group.lower()
    if g == "material":
        roots = [UFC_CORE / "L4_PH" / "Material"]
    elif g == "element":
        roots = [UFC_CORE / "L4_PH" / "Element"]
    elif g == "load":
        roots = [UFC_CORE / "L5_RT" / "LoadBC"]
    elif g == "bc":
        roots = [UFC_CORE / "L5_RT" / "LoadBC", UFC_CORE / "L3_MD"]
    elif g == "contact":
        roots = [UFC_CORE / "L4_PH" / "Contact"]
    elif g == "field":
        roots = [UFC_CORE / "L4_PH" / "Field"]
    elif g == "constraint":
        roots = [UFC_CORE / "L5_RT", UFC_CORE / "L3_MD"]
    elif g == "analysis":
        roots = [UFC_CORE / "L5_RT", UFC_CORE / "L6_AP"]
    else:
        roots = [UFC_CORE / "L4_PH"]

    def score_hint(p: Path) -> tuple[int, int]:
        s = str(p).replace("\\", "/")
        sc = 0
        if "_Proc.f90" in s:
            sc += 200
        if "/Plast/" in s and "PH_Mat_" in s:
            sc += 80
        if "PH_Mat_DP" in s:
            sc += 40
        if "PH_Elem_" in s and "_Proc" in s:
            sc += 60
        return (-sc, len(s))

    candidates: list[Path] = []
    for root in roots:
        if not root.is_dir():
            continue
        for f in root.rglob("*.f90"):
            try:
                txt = f.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            ok = False
            if needle.search(txt):
                ok = True
            else:
                one = " ".join(txt.split())
                if (
                    "subroutine" in one.lower()
                    and "desc" in one.lower()
                    and "state" in one.lower()
                    and "algo" in one.lower()
                    and "ctx" in one.lower()
                    and "intent" in one.lower()
                    and ":: args" in one.lower()
                ):
                    ok = True
            if ok:
                candidates.append(f)
    if not candidates:
        return ""
    best = min(candidates, key=score_hint)
    return best.relative_to(UFC_ROOT).as_posix()


def sio_note(entry: dict, core_file: str, five_hint: str) -> str:
    """Short narrative for SIO column."""
    api = entry.get("core_proc", "")
    mod = entry.get("module_name", "")
    if core_file:
        return f"core `{api}` in `{core_file}` (see module `{mod}`)"
    if five_hint:
        return f"core `{api}` not found in ufc_core; five-param example in `{five_hint}`"
    return f"core `{api}` / module `{mod}` — planned (adapter generator); verify ufc_core implementation"


def main() -> int:
    if not GEN.is_file():
        print(f"ERROR: {GEN} missing", file=sys.stderr)
        return 1

    rows: list[dict[str, str]] = []
    for s in load_all_subroutines():
        name = str(s.get("name", ""))
        group = str(s.get("group", ""))
        mod = str(s.get("module_name", ""))
        core = str(s.get("core_proc", ""))
        dom = str(s.get("ufc_domain", ""))
        adapter = find_adapter_path(name)
        core_file = scan_ufc_core_for_core(core)
        five_hint = scan_ufc_core_five_param_hint(group)
        rows.append(
            {
                "abaqus_subroutine": name,
                "generator_group": group,
                "ufc_domain": dom,
                "ufc_layer_hint": layer_hint(group),
                "target_module": mod,
                "target_core_api": core,
                "legacy_adapter_path": adapter or "(no Legacy_Adapters_Reference stub)",
                "ufc_core_core_file": core_file or "(not found)",
                "sio_five_param_example": five_hint or "(no local five-param match)",
                "sio_bridge_note": sio_note(s, core_file, five_hint),
            }
        )

    REPORTS.mkdir(parents=True, exist_ok=True)
    csv_path = REPORTS / "usub_ufc_alignment.csv"
    md_path = REPORTS / "usub_ufc_alignment.md"

    fieldnames = list(rows[0].keys()) if rows else []
    with csv_path.open("w", newline="", encoding="utf-8-sig") as fp:
        w = csv.DictWriter(fp, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)

    lines = [
        "# Abaqus U* 子程序 ↔ UFC 对齐表（自动生成）",
        "",
        f"生成：`python tools/{Path(__file__).name}`",
        f"数据源：`tools/gen_umat_adapter.py` → `ALL_SUBROUTINES`（{len(rows)} 条）。",
        "",
        "## 列说明",
        "",
        "| 列 | 含义 |",
        "|---|------|",
        "| abaqus_subroutine | Abaqus 用户子程序名 |",
        "| generator_group | 生成器分组（material/element/…） |",
        "| ufc_domain | 生成器中的域标签 |",
        "| ufc_layer_hint | 建议 UFC 层（L4_PH / L5_RT …） |",
        "| target_module / target_core_api | 生成器目标模块与核心 API 名 |",
        "| legacy_adapter_path | 文档区 Legacy 适配器 f90 路径（若存在） |",
        "| ufc_core_core_file | 在 `ufc_core` 中首次命中 `core_api` 定义的 .f90 |",
        "| sio_five_param_example | 同域下五参 `(desc,state,algo,ctx,args)` 示例文件（启发式） |",
        "| sio_bridge_note | 简短说明 |",
        "",
        "## 表",
        "",
    ]
    hdr = "| " + " | ".join(fieldnames) + " |"
    sep = "| " + " | ".join("---" for _ in fieldnames) + " |"
    lines.append(hdr)
    lines.append(sep)
    for r in rows:
        cells = [r[k].replace("|", "\\|") for k in fieldnames]
        lines.append("| " + " | ".join(cells) + " |")
    lines.append("")
    lines.append("## 说明")
    lines.append("")
    lines.append(
        "- **五参入口**：UFC 规范为 `(desc, state, algo, ctx, args)`；材料类 Abaqus 适配历史上常见 "
        "`(desc, ctx, state, algo, rt_ctx, pnewdt)` 等变体，见 `docs/.../UMAT_Adapter.f90` 注释与 `ufc-structured-io`。"
    )
    lines.append("- 未在 `ufc_core` 命中 `target_core_api` 的条目表示**生成器已登记、内核未落地或名称不同**，需人工核对。")
    md_path.write_text("\n".join(lines), encoding="utf-8")

    print(csv_path)
    print(md_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
