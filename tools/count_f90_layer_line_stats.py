# -*- coding: utf-8 -*-
"""
Per-layer .f90 line stats: blank, full-line comment, and all other lines as code.

UFC convention: one MODULE per .f90 file is typical; every non-blank,
non-(full-line-comment) line counts as code (including MODULE/END MODULE,
USE, TYPE, SUBROUTINE, etc.).
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "ufc_core"
LAYERS = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]


def is_blank_line(line: str) -> bool:
    return line.strip() == ""


def is_full_comment_line(line: str) -> bool:
    t = line.lstrip()
    return bool(t) and t[0] == "!"


def scan_file(path: Path) -> tuple[int, int, int]:
    """Return (total_lines, blank, comment_only). code = total - blank - comment."""
    blank = comment = 0
    raw = path.read_text(encoding="utf-8", errors="replace").splitlines()
    total = len(raw)
    for line in raw:
        if is_blank_line(line):
            blank += 1
        elif is_full_comment_line(line):
            comment += 1
    return total, blank, comment


def main() -> int:
    base = ROOT
    if not base.is_dir():
        print("Missing", base, file=sys.stderr)
        return 1

    grand = {"files": 0, "total": 0, "blank": 0, "comment": 0, "code": 0}
    per: dict[str, dict] = {}

    for layer in LAYERS:
        d = base / layer
        acc = {"files": 0, "total": 0, "blank": 0, "comment": 0, "code": 0}
        if d.is_dir():
            for p in sorted(d.rglob("*.f90")):
                t, b, c = scan_file(p)
                acc["files"] += 1
                acc["total"] += t
                acc["blank"] += b
                acc["comment"] += c
                acc["code"] += t - b - c
        per[layer] = acc
        for k in ("files", "total", "blank", "comment", "code"):
            grand[k] += acc[k]

    print("Scope:", base)
    print(
        "Rules: each physical line in *.f90 -- "
        "blank = whitespace only; "
        "comment = first non-space char is ! (full-line comment); "
        "code = all other lines."
    )
    print(
        "Code includes every non-blank, non-full-line-! statement/declaration: "
        "MODULE, END MODULE, CONTAINS, USE, IMPLICIT, INTEGER/REAL/LOGICAL, "
        "TYPE/END TYPE, INTERFACE, ENUM, SUBROUTINE/FUNCTION/END ..., attributes, "
        "executable statements, INCLUDE, preprocessor lines if present, etc."
    )
    print()
    hdr = f"{'Layer':<8} {'Files':>6} {'Total':>9} {'Blank':>9} {'Comment':>9} {'Code':>9}"
    print(hdr)
    print("-" * len(hdr))
    for layer in LAYERS:
        a = per[layer]
        print(
            f"{layer:<8} {a['files']:>6} {a['total']:>9} {a['blank']:>9} {a['comment']:>9} {a['code']:>9}"
        )
    print("-" * len(hdr))
    print(
        f"{'TOTAL':<8} {grand['files']:>6} {grand['total']:>9} {grand['blank']:>9} {grand['comment']:>9} {grand['code']:>9}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
