# -*- coding: utf-8 -*-
"""
Per-layer *.f90 in ufc_core: SUBROUTINE+FUNCTION starts, blank lines, full-line comments.

- Subprogram: lines starting a SUBROUTINE or FUNCTION (not END SUBROUTINE/FUNCTION).
  Lines inside INTERFACE ... END INTERFACE are ignored (interface specs, not definitions).
- Blank: whitespace-only line.
- Comment: after leading spaces/tabs, first char is ! (full-line comment).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "ufc_core"
LAYERS = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]


def strip_inline_comment(line: str) -> str:
    """Remove trailing free-form comment; respect single/double quotes."""
    s = line.rstrip("\r\n")
    if not s.strip():
        return s
    if s.lstrip().startswith("!"):
        return ""
    out: list[str] = []
    i = 0
    in_sq = in_dq = False
    while i < len(s):
        c = s[i]
        if not in_sq and not in_dq:
            if c == "'":
                in_sq = True
                out.append(c)
            elif c == '"':
                in_dq = True
                out.append(c)
            elif c == "!":
                break
            else:
                out.append(c)
        else:
            out.append(c)
            if in_sq and c == "'":
                if i + 1 < len(s) and s[i + 1] == "'":
                    out.append(s[i + 1])
                    i += 1
                else:
                    in_sq = False
            elif in_dq and c == '"':
                in_dq = False
        i += 1
    return "".join(out)


def is_blank_line(line: str) -> bool:
    return line.strip() == ""


def is_full_comment_line(line: str) -> bool:
    t = line.lstrip()
    return bool(t) and t[0] == "!"


_SUB_START = re.compile(r"\bSUBROUTINE\s+[A-Za-z_][A-Za-z0-9_]*\b", re.I)
_FUNC_START = re.compile(r"\bFUNCTION\s+[A-Za-z_][A-Za-z0-9_]*\b", re.I)
_END_SUB = re.compile(r"\bEND\s+SUBROUTINE\b", re.I)
_END_FUNC = re.compile(r"\bEND\s+FUNCTION\b", re.I)
_END_IFACE = re.compile(r"^\s*END\s+INTERFACE\b", re.I)
_HAS_IFACE = re.compile(r"\bINTERFACE\b", re.I)


def count_substarts(code: str) -> tuple[int, int]:
    t = code.strip()
    if not t:
        return 0, 0
    tu = t.upper()
    if tu.startswith("END"):
        return 0, 0
    ns = 1 if _SUB_START.search(t) and not _END_SUB.search(t) else 0
    nf = 1 if _FUNC_START.search(t) and not _END_FUNC.search(t) else 0
    return ns, nf


def update_interface_depth(code: str, depth: int) -> int:
    tu = code.strip()
    if not tu:
        return depth
    tu_u = tu.upper()
    if _END_IFACE.match(tu_u):
        return max(0, depth - 1)
    if _HAS_IFACE.search(tu_u) and not tu_u.lstrip().startswith("END"):
        return depth + 1
    return depth


def scan_file(path: Path) -> dict:
    total = blank = comment_only = code_lines = 0
    subr = func = 0
    iface_depth = 0
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        total += 1
        if is_blank_line(line):
            blank += 1
            continue
        if is_full_comment_line(line):
            comment_only += 1
            continue
        code = strip_inline_comment(line)
        if not code.strip():
            continue
        code_lines += 1
        iface_depth = update_interface_depth(code, iface_depth)
        if iface_depth == 0:
            ns, nf = count_substarts(code)
            subr += ns
            func += nf
    return {
        "total_lines": total,
        "blank": blank,
        "comment_only": comment_only,
        "code_lines": code_lines,
        "subroutine": subr,
        "function": func,
    }


def main() -> int:
    base = ROOT
    if not base.is_dir():
        print("Missing", base, file=sys.stderr)
        return 1

    grand = {
        "files": 0,
        "total_lines": 0,
        "blank": 0,
        "comment_only": 0,
        "code_lines": 0,
        "subroutine": 0,
        "function": 0,
    }
    per: dict[str, dict] = {}

    for layer in LAYERS:
        d = base / layer
        acc = {k: 0 for k in grand}
        if d.is_dir():
            for p in sorted(d.rglob("*.f90")):
                r = scan_file(p)
                acc["files"] += 1
                for k in (
                    "total_lines",
                    "blank",
                    "comment_only",
                    "code_lines",
                    "subroutine",
                    "function",
                ):
                    acc[k] += r[k]
        per[layer] = acc
        for k in (
            "files",
            "total_lines",
            "blank",
            "comment_only",
            "code_lines",
            "subroutine",
            "function",
        ):
            grand[k] += acc[k]

    print("Scope:", base)
    print(
        "Subprograms: SUBROUTINE + FUNCTION definitions (skip END ...; skip inside INTERFACE)."
    )
    print("Blank / Comment: full-line only; code!inline counts as code line.")
    print()
    hdr = (
        f"{'Layer':<8} {'Files':>6} {'Lines':>8} {'Blank':>8} {'Comment':>9} "
        f"{'Code':>8} {'SUB':>6} {'FUNC':>6} {'Sub+Func':>9}"
    )
    print(hdr)
    print("-" * len(hdr))
    for layer in LAYERS:
        a = per[layer]
        sf = a["subroutine"] + a["function"]
        print(
            f"{layer:<8} {a['files']:>6} {a['total_lines']:>8} {a['blank']:>8} "
            f"{a['comment_only']:>9} {a['code_lines']:>8} {a['subroutine']:>6} "
            f"{a['function']:>6} {sf:>9}"
        )
    sf = grand["subroutine"] + grand["function"]
    print("-" * len(hdr))
    print(
        f"{'TOTAL':<8} {grand['files']:>6} {grand['total_lines']:>8} {grand['blank']:>8} "
        f"{grand['comment_only']:>9} {grand['code_lines']:>8} {grand['subroutine']:>6} "
        f"{grand['function']:>6} {sf:>9}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
