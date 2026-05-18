#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scan developer templates + domain-pillar docs for SSOT drift vs UFC Fortran rules.

Default targets (under UFC root):
  - docs/02_Developer_Guide/Code_Templates/**/*.f90 and **.md
  - docs/02_Developer_Guide/**/*.md excluding subtree Code_Templates/ (no double-scan)
  - docs/03_Domain_Pillars/**/*.md only (Fortran fenced blocks; tree has no .f90)

Rules (non-comment code lines in .f90; fenced bodies in .md):
  - USE / dependency on IF_Err_API (prefer IF_Err_Brg per project rules)
  - ISO_FORTRAN_ENV / SELECTED_REAL_KIND / REAL64 (precision must use IF_Prec / wp)
  - Legacy material prefix PH_Material_* (TYPE/module names), PH_Material_Domain_Core
  - Unqualified STATUS_OK (must be IF_STATUS_OK or structured status per SIO)

Full-line Fortran comments (! ...) are skipped in .f90. Inline code uses the segment before '!'.

`--root` (repeatable): optional scan roots (each uses .f90 + .md). When omitted, use
built-in defaults: Code_Templates (.f90 + .md), rest of Developer Guide (.md only,
excluding Code_Templates/), and docs/03_Domain_Pillars (.md only).

Exit code: 0 if no hits, 1 if violations (unless --warn-only).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Iterator, List, Sequence, Tuple

# (relative path from UFC root, extensions, skip first path segment under root)
DEFAULT_ROOT_SPECS: Sequence[Tuple[str, Tuple[str, ...], Tuple[str, ...]]] = (
    ("docs/02_Developer_Guide/Code_Templates", (".f90", ".md"), ()),
    ("docs/02_Developer_Guide", (".md",), ("Code_Templates",)),
    ("docs/03_Domain_Pillars", (".md",), ()),
)

ScanSpec = Tuple[Path, Tuple[str, ...], Tuple[str, ...]]


def _ufc_root() -> Path:
    here = Path(__file__).resolve()
    for p in [here.parent.parent, *here.parents]:
        if (p / "ufc_core").is_dir() and (p / "ufc_harness").is_dir():
            return p
    return here.parent.parent


@dataclass
class Hit:
    path: str
    line: int
    rule_id: str
    message: str
    excerpt: str


# (rule_id, regex, human message)
_RULES: Sequence[Tuple[str, re.Pattern[str], str]] = (
    (
        "ERR_API_USE",
        re.compile(r"(?i)\bUSE\s+[^!\n;]*\bIF_Err_API\b"),
        "禁止 USE IF_Err_API；错误传播请走 IF_Err_Brg / 结构化状态（见 rules 与 ufc-structured-io）",
    ),
    (
        "ISO_FORTRAN_ENV",
        re.compile(r"\bISO_FORTRAN_ENV\b"),
        "禁止使用 ISO_FORTRAN_ENV；精度用 USE IF_Prec, ONLY: wp, i4",
    ),
    (
        "SELECTED_REAL_KIND",
        re.compile(r"\bSELECTED_REAL_KIND\b"),
        "禁止自定义 KIND / SELECTED_REAL_KIND；使用 IF_Prec 的 wp / i4",
    ),
    (
        "REAL64_TOKEN",
        re.compile(r"\bREAL64\b"),
        "禁止 REAL64 等 ISO 环境别名；使用 wp",
    ),
    (
        "PH_MATERIAL_DOMAIN_CORE",
        re.compile(r"PH_Material_Domain_Core"),
        "禁止遗留模块/类型名 PH_Material_Domain_Core",
    ),
    (
        "PH_MATERIAL_LEGACY",
        re.compile(r"\bPH_Material_[A-Za-z0-9_]+"),
        "禁止 PH_Material_* 旧前缀；材料物理层使用 L4_PH_Material_* 等现行命名",
    ),
    (
        "STATUS_OK_UNQUALIFIED",
        re.compile(r"(?<![A-Za-z_])STATUS_OK(?![A-Za-z_])"),
        "禁止裸 STATUS_OK；使用 IF_STATUS_OK 或合同约定的结构化状态字段",
    ),
)


def _fortran_code_segment(line: str) -> str:
    """Strip end-of-line Fortran comment (first unquoted ! is hard; v1: first !)."""
    if "!" in line:
        return line.split("!", 1)[0].rstrip()
    return line.rstrip()


def _is_full_line_f90_comment(line: str) -> bool:
    s = line.strip()
    return s.startswith("!")


def _scan_text_lines(
    rel_path: str,
    lines: List[str],
    base_line: int,
    *,
    skip_full_line_comments: bool,
) -> List[Hit]:
    hits: List[Hit] = []
    for i, raw in enumerate(lines, start=base_line):
        line = raw.rstrip("\n")
        if skip_full_line_comments and _is_full_line_f90_comment(line):
            continue
        seg = _fortran_code_segment(line) if skip_full_line_comments else line
        if not seg.strip():
            continue
        for rule_id, rx, msg in _RULES:
            if rx.search(seg):
                excerpt = line.strip()[:200]
                hits.append(
                    Hit(
                        path=rel_path,
                        line=i,
                        rule_id=rule_id,
                        message=msg,
                        excerpt=excerpt,
                    )
                )
                break
    return hits


_FENCE_OPEN = re.compile(r"^\s*```\s*(\S*)\s*$")
_FENCE_CLOSE = re.compile(r"^\s*```\s*$")
_F90ISH = re.compile(r"\b(USE|SUBROUTINE|MODULE|FUNCTION|PROGRAM)\b", re.I)


def _iter_md_fortran_blocks(
    md_text: str,
) -> Iterator[Tuple[int, List[str]]]:
    """Yield (start_line_1based, block_lines) for each fenced Fortran-like block."""
    lines = md_text.splitlines()
    i = 0
    while i < len(lines):
        m = _FENCE_OPEN.match(lines[i])
        if not m:
            i += 1
            continue
        lang = m.group(1).lower()
        start = i + 2
        i += 1
        buf: List[str] = []
        while i < len(lines) and not _FENCE_CLOSE.match(lines[i]):
            buf.append(lines[i])
            i += 1
        if i < len(lines):
            i += 1
        body = "\n".join(buf).strip()
        if not body:
            continue
        if lang in ("fortran", "f90", "f2003", "fortran90"):
            yield start, buf
        elif lang == "" and _F90ISH.search(body):
            yield start, buf


def scan_file(path: Path, ufc_root: Path) -> List[Hit]:
    rel = path.relative_to(ufc_root).as_posix()
    text = path.read_text(encoding="utf-8", errors="replace")
    hits: List[Hit] = []

    if path.suffix.lower() == ".f90":
        lines = text.splitlines()
        hits.extend(
            _scan_text_lines(rel, lines, 1, skip_full_line_comments=True)
        )
    elif path.suffix.lower() == ".md":
        for start_line, block_lines in _iter_md_fortran_blocks(text):
            hits.extend(
                _scan_text_lines(
                    rel,
                    block_lines,
                    start_line,
                    skip_full_line_comments=True,
                )
            )
    return hits


def _walk_targets(
    root: Path,
    extensions: Tuple[str, ...],
    skip_top_level: Tuple[str, ...] = (),
) -> Iterable[Path]:
    skip = frozenset(skip_top_level)
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        if p.suffix.lower() not in extensions:
            continue
        if skip:
            try:
                rel = p.relative_to(root)
                if rel.parts and rel.parts[0] in skip:
                    continue
            except ValueError:
                continue
        yield p


def _resolve_scan_specs(ufc: Path, user_roots: List[str] | None) -> List[ScanSpec]:
    if user_roots:
        out: List[ScanSpec] = []
        for r in user_roots:
            rp = Path(r)
            root = rp.resolve() if rp.is_absolute() else (ufc / r).resolve()
            out.append((root, (".f90", ".md"), ()))
        return out
    return [
        ((ufc / rel).resolve(), exts, skip)
        for rel, exts, skip in DEFAULT_ROOT_SPECS
    ]


def _write_report(out: Path, hits: List[Hit], specs: List[ScanSpec]) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    root_lines = "\n".join(
        (
            f"- `{root.as_posix()}` (`{', '.join(exts)}`)"
            + (
                f"; skip `{', '.join(skip)}/`"
                if skip
                else ""
            )
        )
        for root, exts, skip in specs
    )
    lines = [
        "# Docs Fortran SSOT scan",
        "",
        "**Scanned roots:**",
        root_lines,
        "",
        f"**Violations:** **{len(hits)}**",
        "",
    ]
    if not hits:
        lines.append("No violations.")
    else:
        lines.append("| File | Line | Rule | Message | Excerpt |")
        lines.append("|------|------|------|---------|---------|")
        for h in hits:
            ex = h.excerpt.replace("|", "\\|")
            lines.append(
                f"| `{h.path}` | {h.line} | `{h.rule_id}` | {h.message} | `{ex}` |"
            )
    lines.append("")
    tmp = out.with_suffix(out.suffix + ".tmp")
    tmp.write_text("\n".join(lines), encoding="utf-8")
    tmp.replace(out)


def main(argv: List[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--root",
        action="append",
        default=None,
        help=(
            "Scan root (repeatable; relative paths resolve under UFC root). "
            "Each explicit root uses extensions .f90 + .md. "
            "When omitted, defaults: Code_Templates (.f90+.md); "
            "docs/02_Developer_Guide (.md, excluding Code_Templates/); "
            "docs/03_Domain_Pillars (.md only)."
        ),
    )
    ap.add_argument(
        "--report",
        default=None,
        help="Markdown report path (default: UFC/REPORTS/code_templates_ssot_scan.md)",
    )
    ap.add_argument("--json", action="store_true", help="Print JSON hits to stdout")
    ap.add_argument(
        "--warn-only",
        action="store_true",
        help="Always exit 0; still write report and print summary",
    )
    ns = ap.parse_args(argv)

    ufc = _ufc_root()
    specs = _resolve_scan_specs(ufc, ns.root)
    report_path = Path(ns.report) if ns.report else ufc / "REPORTS" / "code_templates_ssot_scan.md"

    all_hits: List[Hit] = []
    for root, exts, skip_top in specs:
        if not root.is_dir():
            print(f"[ssot-scan] skip missing directory: {root}", file=sys.stderr)
            continue
        for f in _walk_targets(root, exts, skip_top):
            all_hits.extend(scan_file(f, ufc))

    _write_report(report_path, all_hits, specs)

    if ns.json:
        print(json.dumps([asdict(h) for h in all_hits], ensure_ascii=False, indent=2))

    print(f"[ssot-scan] wrote {report_path} ({len(all_hits)} violation(s))")
    if all_hits and not ns.warn_only:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
