#!/usr/bin/env python3
"""Generate L3/L4/L5 .f90 inventory + pilot checklist (one row per file).

Examples:
  python tools/gen_l3l4l5_f90_inventory.py
  python tools/gen_l3l4l5_f90_inventory.py --wave W1 -o docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_pilot_f90任务清单_W1.md

**WARNING**: `--wave Wx` 省略 `-o` 时，会**整表覆写** `.../L3_L4_L5_pilot_f90任务清单_Wx.md`（含人工维护的 W1 批注）。请改用 **`-o <临时路径>`** 做 diff，或先备份/提交后再生成。

Wave filters align with docs/05_Project_Planning/PPLAN/03_实施规划/实施路线 «波次驱动» 规划（EXEC §4–§6）；W7/W8 为近似前缀并集，复杂分界以合同为准。
"""
from __future__ import annotations

import argparse
import os
import re
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
UFC_CORE = REPO / "ufc_core"
LAYERS = ("L3_MD", "L4_PH", "L5_RT")
DEFAULT_OUT = (
    REPO
    / "docs"
    / "PPLAN"
    / "03_实施规划"
    / "实施路线"
    / "L3_L4_L5_pilot_f90任务清单.md"
)

SUB_RE = re.compile(r"^\s*(SUBROUTINE|FUNCTION)\s+", re.MULTILINE)


def domain_bucket(layer: str, rel_to_core: Path) -> str:
    assert rel_to_core.parts[0] == layer
    if len(rel_to_core.parts) == 2:
        return "(layer_root)"
    return rel_to_core.parts[1]


def collect_all_rows() -> tuple[list[tuple[str, Path, int]], dict[str, int], dict[tuple[str, str], int]]:
    rows: list[tuple[str, Path, int]] = []
    per_layer_files: dict[str, int] = {L: 0 for L in LAYERS}
    bucket_counts: dict[tuple[str, str], int] = {}

    for layer in LAYERS:
        root = UFC_CORE / layer
        if not root.is_dir():
            raise SystemExit(f"missing {root}")
        for dirpath, _, files in os.walk(root):
            for fn in sorted(files):
                if not fn.endswith(".f90"):
                    continue
                fp = Path(dirpath) / fn
                rel = fp.relative_to(UFC_CORE)
                txt = fp.read_text(encoding="utf-8", errors="replace")
                n_sub = len(SUB_RE.findall(txt))
                rows.append((layer, rel, n_sub))
                per_layer_files[layer] += 1
                b = domain_bucket(layer, rel)
                bucket_counts[(layer, b)] = bucket_counts.get((layer, b), 0) + 1

    rows.sort(key=lambda x: (x[1].as_posix(),))
    return rows, per_layer_files, bucket_counts


def norm_rel(rel: Path) -> str:
    return rel.as_posix().replace("\\", "/")


def match_wave(rel: Path, wave: str) -> bool:
    """Return True if rel (relative to ufc_core) belongs to wave Wx scope."""
    s = norm_rel(rel)
    if wave == "W1":
        if s.startswith("L3_MD/Material/"):
            return True
        if s.startswith("L4_PH/Material/"):
            return True
        if s.startswith("L5_RT/Material/"):
            return True
        if s == "L3_MD/Bridge/Bridge_L4/MD_MatLibPH_Brg.f90":
            return True
        if s == "L5_RT/Bridge/RT_Brg_Def.f90":
            return True
        return False
    if wave == "W2":
        return (
            s.startswith("L3_MD/Element/Mesh/")
            or s.startswith("L3_MD/Element/Elem/")
            or s.startswith("L4_PH/Element/")
            or s.startswith("L5_RT/Element/")
        )
    if wave == "W3":
        return s.startswith("L3_MD/Interaction/") or s.startswith("L4_PH/Contact/") or s.startswith(
            "L5_RT/Contact/"
        )
    if wave == "W4":
        return s.startswith("L3_MD/Boundary/") or s.startswith("L4_PH/LoadBC/") or s.startswith(
            "L5_RT/LoadBC/"
        )
    if wave == "W5":
        return (
            s.startswith("L3_MD/Output/")
            or s.startswith("L4_PH/Bridge/Output/")
            or s.startswith("L5_RT/Output/")
        )
    if wave == "W6":
        return (
            s.startswith("L3_MD/WriteBack/")
            or s.startswith("L4_PH/Bridge/WriteBack/")
            or s.startswith("L5_RT/WriteBack/")
        )
    if wave == "W7":
        prefixes = (
            "L3_MD/Constraint/",
            "L4_PH/Constraint/",
            "L3_MD/Field/",
            "L4_PH/Field/",
            "L3_MD/Assembly/",
            "L5_RT/Assembly/",
            "L3_MD/Analysis/Step/",
            "L5_RT/StepDriver/",
            "L3_MD/Analysis/Solver/",
            "L5_RT/Solver/",
            "L3_MD/Analysis/Amplitude/",
            "L3_MD/Analysis/Coupling/",
            "L5_RT/Solver/Coupling/",
        )
        if any(s.startswith(p) for p in prefixes):
            return True
        if s == "L4_PH/Element/PH_Elem_dRdTheta.f90":
            return True
        return False
    if wave == "W8":
        if s.startswith("L3_MD/KeyWord/"):
            return True
        if s.startswith("L3_MD/Model/"):
            return True
        if s.startswith("L3_MD/Part/"):
            return True
        if s.startswith("L3_MD/Section/"):
            return True
        if s.startswith("L5_RT/Logging/"):
            return True
        return False
    raise SystemExit(f"unknown --wave {wave!r} (use W1..W8)")


def match_prefixes(rel: Path, prefixes: list[str]) -> bool:
    s = norm_rel(rel)
    for p in prefixes:
        p0 = p.replace("\\", "/").strip().rstrip("/")
        if s == p0 or s.startswith(p0 + "/"):
            return True
    return False


def write_full_manifest(
    out_path: Path,
    rows: list[tuple[str, Path, int]],
    per_layer_files: dict[str, int],
    bucket_counts: dict[tuple[str, str], int],
) -> None:
    per_layer_sub = {L: 0 for L in LAYERS}
    total_sub = 0
    for layer, rel, n_sub in rows:
        per_layer_sub[layer] += n_sub
        total_sub += n_sub

    total_f90 = sum(per_layer_files.values())

    lines: list[str] = []
    lines.append("# L3 / L4 / L5 — pilot 改造次级任务清单（按 `.f90` 文件）")
    lines.append("")
    lines.append(f"> **生成日期**：{date.today().isoformat()}  ")
    lines.append(
        "> **自动化**：[`UFC/tools/gen_l3l4l5_f90_inventory.py`](../../../../tools/gen_l3l4l5_f90_inventory.py)  "
    )
    lines.append(
        "> **设计母体**：[`ufc-layer-l3-l4-l5-pilot.md`](ufc-layer-l3-l4-l5-pilot.md)  "
    )
    lines.append(
        "> **波次真源**：[`UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md`](UFC_L3_L4_L5_主辅TYPE嵌套_全域铺开执行计划.md)（**禁止**脱离 W0–W8 自行发明任务顺序）"
    )
    lines.append("")
    lines.append("## 1. 统计摘要")
    lines.append("")
    lines.append("| 层 | `.f90` 文件数 | `SUBROUTINE`/`FUNCTION` 数（约） |")
    lines.append("|---|---------------|-----------------------------------|")
    for L in LAYERS:
        lines.append(f"| **{L}** | {per_layer_files[L]} | {per_layer_sub[L]} |")
    lines.append(f"| **合计** | **{total_f90}** | **{total_sub}** |")
    lines.append("")
    lines.append("## 2. 任务粒度说明（必读）")
    lines.append("")
    lines.append(
        "- **本清单的一条 checkbox = 一个 `.f90` 源文件** 的 pilot 对齐改造（主辅 TYPE、Step1–4、域 `CONTRACT.md` 随波次更新）。"
    )
    lines.append(
        f"- 全仓三层合计 **{total_sub}** 个子程序；若按「每个子程序一条独立任务」会产生上万条不可评审条目，**与全域铺开执行计划的波次/域柱 PR 边界冲突**。单文件内多个过程应在 **同一文件任务** 内一并收敛。"
    )
    lines.append(
        "- **执行顺序**不以本文件字母序为准：以 **W0→W8** 与 §2 前置依赖为准（例如先 Material 贯通柱，再 Element，等）。本清单用于 **覆盖率核对** 与 **文件级勾选**。"
    )
    lines.append("")
    lines.append("## 3. 域桶文件数（第一层目录 / 根文件）")
    lines.append("")
    lines.append("| 层 | 域桶 | 文件数 |")
    lines.append("|---|------|--------|")
    for layer in LAYERS:
        buckets = sorted((b, c) for (L, b), c in bucket_counts.items() if L == layer)
        for b, c in buckets:
            lines.append(f"| {layer} | `{b}` | {c} |")
    lines.append("")
    lines.append("## 4. 文件级次级任务（T0001 …）")
    lines.append("")
    for i, (layer, rel, n_sub) in enumerate(rows, start=1):
        tid = f"T{i:04d}"
        rel_s = norm_rel(rel)
        lines.append(f"- [ ] **{tid}** `{rel_s}` （约 {n_sub} 个子程序）")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path} ({total_f90} tasks, {total_sub} subprograms)")


def write_filtered(
    out_path: Path,
    all_rows: list[tuple[str, Path, int]],
    filtered: list[tuple[int, str, Path, int]],
    title: str,
    extra_note: str,
) -> None:
    lines: list[str] = []
    lines.append(title)
    lines.append("")
    lines.append(f"> **生成日期**：{date.today().isoformat()}  ")
    lines.append(
        "> **来源**：[`UFC/tools/gen_l3l4l5_f90_inventory.py`](../../../../tools/gen_l3l4l5_f90_inventory.py)  "
    )
    lines.append(
        "> **总清单**：[`L3_L4_L5_pilot_f90任务清单.md`](L3_L4_L5_pilot_f90任务清单.md) — **Txxxx 与总清单一致**"
    )
    lines.append("")
    if extra_note:
        lines.append(f"> {extra_note}")
    lines.append("")
    lines.append("## 本波次文件（勾选覆盖）")
    lines.append("")
    n_sub_tot = 0
    for global_idx, layer, rel, n_sub in filtered:
        tid = f"T{global_idx:04d}"
        rel_s = norm_rel(rel)
        lines.append(f"- [ ] **{tid}** `{rel_s}` （约 {n_sub} 个子程序）")
        n_sub_tot += n_sub
    lines.append("")
    lines.append(f"**合计**：{len(filtered)} 个 `.f90`，约 {n_sub_tot} 个子程序。")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path} ({len(filtered)} tasks)")


def main() -> None:
    parser = argparse.ArgumentParser(description="L3/L4/L5 f90 inventory generator")
    parser.add_argument(
        "--wave",
        choices=["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"],
        help="筛选 EXEC 对应波次权威目录（内置前缀规则）",
    )
    parser.add_argument(
        "--prefix",
        action="append",
        default=[],
        metavar="UF_CORE_REL",
        help="相对 ufc_core/ 的路径前缀，可重复；与 --wave 二选一（优先 --prefix 列表）",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=None,
        help="输出 Markdown 路径（默认：总清单路径或 …_任务清单_Wx.md）",
    )
    args = parser.parse_args()

    rows, per_layer_files, bucket_counts = collect_all_rows()

    if args.prefix:
        prefixes = args.prefix
        filtered: list[tuple[int, str, Path, int]] = []
        for i, (layer, rel, n_sub) in enumerate(rows, start=1):
            if match_prefixes(rel, prefixes):
                filtered.append((i, layer, rel, n_sub))
        out = args.output
        if out is None:
            out = REPO / "docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_pilot_f90任务清单_custom.md"
        note = f"**筛选**：`--prefix` {prefixes!r}"
        write_filtered(
            out,
            rows,
            filtered,
            "# L3/L4/L5 — 自定义前缀筛选任务清单",
            note,
        )
        return

    if args.wave:
        filtered_w: list[tuple[int, str, Path, int]] = []
        for i, (layer, rel, n_sub) in enumerate(rows, start=1):
            if match_wave(rel, args.wave):
                filtered_w.append((i, layer, rel, n_sub))
        out = args.output
        if out is None:
            out = (
                REPO
                / "docs"
                / "PPLAN"
                / "03_实施规划"
                / "实施路线"
                / f"L3_L4_L5_pilot_f90任务清单_{args.wave}.md"
            )
        extra = (
            f"**波次**：{args.wave}（内置前缀；W7/W8 与邻波重叠边界以合同及 EXEC §5–§6 为准）"
        )
        if args.wave == "W7":
            extra += (
                " **H7 提示**：`ufc_core/L2_NM/Solver/AI/` 不在本仓库 866 总清单（仅 L3/L4/L5）内；"
                "DiffPhys / 伴随相关文件请单独列 Issue 跟踪。"
            )
        if args.wave == "W8":
            extra += (
                " **S5 Mesh**：与 **W2** `L3_MD/Element/Mesh/`、`L3_MD/Element/Elem/` 可能重叠；以 Mesh/ELEM 合同划定 Populate/单元分界，避免双真源。"
            )
        write_filtered(
            out,
            rows,
            filtered_w,
            f"# L3/L4/L5 — pilot 任务清单（{args.wave} 筛选）",
            extra,
        )
        return

    out = args.output if args.output is not None else DEFAULT_OUT
    write_full_manifest(out, rows, per_layer_files, bucket_counts)


if __name__ == "__main__":
    main()
