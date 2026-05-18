#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scan ufc_core Fortran sources for verbose / prose-style identifiers.

Lexicon: ``UFC/tools/naming_lexicon.py`` (``verbose_token_hints()``).

Policy (aligned with UFC/docs/02_Developer_Guide & rules/ufc-naming.mdc):

  - Member / local / dummy names should use the project lexicon (props, cfg, …),
    not full English words (properties, configuration, …).
  - Default: report-only, exit 0. Use --fail-on 1 (or higher) to gate CI once baseline is clear.

This is a **heuristic** scanner (regexp on lines), not a full Fortran parser.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Set, Tuple

from naming_lexicon import verbose_token_hints

# Whole identifiers to never flag (lowercase)
ALLOW_IDENTIFIERS: Set[str] = {
    "equation",
    "relations",
    "relation",
    "station",
    "stations",
    "cation",
    "vacation",
}

# Prefixes for exported symbols; long stems here are often structural, not "verboseness"
IGNORE_NAME_PREFIXES: Tuple[str, ...] = ("md_", "ph_", "rt_", "nm_", "if_", "ap_", "uf_", "kw_")


def _strip_fortran_comment(line: str) -> str:
    """Remove trailing ! comment when not inside quotes (best-effort)."""
    in_sq = in_dq = False
    out: List[str] = []
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == "'" and not in_dq:
            in_sq = not in_sq
            out.append(ch)
        elif ch == '"' and not in_sq:
            in_dq = not in_dq
            out.append(ch)
        elif ch == "!" and not in_sq and not in_dq:
            break
        else:
            out.append(ch)
        i += 1
    return "".join(out).rstrip()


_RE_DECL = re.compile(
    r"(?i)^\s*(?:integer|real|logical|character|type\s*\([^)]+\))\b[^:]*::\s*(.+)$"
)
_RE_PROC = re.compile(
    r"(?i)^\s*(?:pure\s+|recursive\s+|elemental\s+)*(?:subroutine|function)\s+(\w+)\b"
)


def _split_decl_names(rhs: str) -> List[str]:
    """Rough split of declaration RHS into candidate identifier names."""
    rhs = rhs.strip()
    if not rhs:
        return []
    parts = rhs.split(",")
    names: List[str] = []
    for part in parts:
        part = part.strip()
        if not part:
            continue
        m = re.search(r"\b(?:pointer|allocatable|target|save|parameter|dimension\s*\([^)]*\)|intent\s*\([^)]*\))\b", part, re.I)
        if m and m.start() == 0:
            continue
        m2 = re.search(r"\b([a-z][a-z0-9_]*)\b", part, re.I)
        if m2:
            names.append(m2.group(1))
        if "=" in part:
            left = part.split("=", 1)[0].strip()
            m3 = re.search(r"\b([a-z][a-z0-9_]*)\s*$", left, re.I)
            if m3:
                names.append(m3.group(1))
    dedup: List[str] = []
    seen: Set[str] = set()
    for n in names:
        low = n.lower()
        if low not in seen:
            seen.add(low)
            dedup.append(n)
    return dedup


def _is_fortran_constant_name(name: str) -> bool:
    """ALL_CAPS style names (often PARAMETER / enum); exclude from 'verbose English' heuristics."""
    if not name:
        return False
    return bool(re.match(r"^[A-Z][A-Z0-9_]*$", name))


def _underscore_token_match(low_name: str, tok: str) -> bool:
    """
    Match tok as a Fortran-style morpheme: preceded by start or '_', followed by '_' / end / digit.
    Avoids 'initialize' matching inside 'initialized' (no '_initialize' segment).
    """
    return re.search(rf"(^|_){re.escape(tok)}(_|$|[0-9])", low_name) is not None


def _hits_for_name(
    raw_name: str,
    max_len: int,
    avoid: Dict[str, str],
    *,
    check_length: bool,
    check_substrings: bool,
) -> List[str]:
    low = raw_name.lower()
    if raw_name.startswith("http") or low in ALLOW_IDENTIFIERS:
        return []
    if _is_fortran_constant_name(raw_name):
        return []
    reasons: List[str] = []
    if check_length and len(raw_name) > max_len:
        reasons.append(f"length>{max_len}")
    if check_substrings:
        for tok, hint in avoid.items():
            if _underscore_token_match(low, tok):
                reasons.append(f"token:{tok}→{hint}")
    return reasons


def _should_skip_procedure_name(name: str) -> bool:
    low = name.lower()
    return any(low.startswith(p) for p in IGNORE_NAME_PREFIXES)


def _line_has_parameter_attr(line: str) -> bool:
    return bool(re.search(r"(?i),\s*parameter\s*::|::\s*[^!]*\bparameter\b", line))


def scan_file(
    path: Path,
    max_len: int,
    avoid: Dict[str, str],
    *,
    check_length: bool,
    check_substrings: bool,
) -> List[Dict[str, Any]]:
    findings: List[Dict[str, Any]] = []
    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as e:
        return [{"line": 0, "name": "", "kind": "io_error", "detail": str(e)}]

    for lineno, raw in enumerate(lines, 1):
        line = _strip_fortran_comment(raw)
        if not line or line.lstrip().startswith("!"):
            continue

        m = _RE_DECL.match(line)
        if m:
            if _line_has_parameter_attr(line):
                continue
            rhs = m.group(1)
            for name in _split_decl_names(rhs):
                low = name.lower()
                if low in ALLOW_IDENTIFIERS:
                    continue
                for r in _hits_for_name(
                    name,
                    max_len,
                    avoid,
                    check_length=check_length,
                    check_substrings=check_substrings,
                ):
                    findings.append(
                        {
                            "line": lineno,
                            "name": name,
                            "kind": "decl",
                            "detail": r,
                            "excerpt": raw.strip()[:120],
                        }
                    )

        mp = _RE_PROC.match(line)
        if mp:
            name = mp.group(1)
            if _should_skip_procedure_name(name):
                continue
            for r in _hits_for_name(
                name,
                28,
                avoid,
                check_length=check_length,
                check_substrings=check_substrings,
            ):
                findings.append(
                    {
                        "line": lineno,
                        "name": name,
                        "kind": "procedure",
                        "detail": r,
                        "excerpt": raw.strip()[:120],
                    }
                )

    return findings


def iter_f90(
    roots: List[Path],
    layers: Optional[Set[str]] = None,
) -> Iterable[Path]:
    for root in roots:
        if not root.is_dir():
            if root.suffix.lower() == ".f90":
                yield root
            continue
        for p in root.rglob("*.f90"):
            ps = str(p).replace("\\", "/")
            if "/ExternalLibs/" in ps or "\\ExternalLibs\\" in ps:
                continue
            if layers:
                if not any(f"/{ly}/" in ps or f"\\{ly}\\" in ps for ly in layers):
                    continue
            yield p


def main() -> int:
    ap = argparse.ArgumentParser(description="Scan Fortran identifiers for verbose English stems.")
    ap.add_argument(
        "paths",
        nargs="*",
        default=None,
        help="Files or directories (default: UFC/ufc_core relative to repo root)",
    )
    ap.add_argument("--max-len", type=int, default=20, help="Max length for declaration identifiers (default 20)")
    ap.add_argument(
        "--no-length",
        action="store_true",
        help="Disable length rule (useful while baseline still has long locals)",
    )
    ap.add_argument(
        "--substr-only",
        action="store_true",
        help="Only flag lexicon / verbose-token hits (no length)",
    )
    ap.add_argument(
        "--layers",
        default="L3_MD,L4_PH,L5_RT",
        help="Comma-separated layer folder names to include when scanning directories",
    )
    ap.add_argument("--json", action="store_true", help="Emit JSON report to stdout")
    ap.add_argument(
        "--fail-on",
        type=int,
        default=None,
        metavar="N",
        help="Exit 1 if total findings >= N (omit for report-only exit 0)",
    )
    args = ap.parse_args()

    here = Path(__file__).resolve().parent.parent
    roots: List[Path] = []
    if args.paths:
        for s in args.paths:
            roots.append(Path(s).expanduser().resolve())
    else:
        core = here / "ufc_core"
        roots.append(core if core.is_dir() else here)

    layers = {x.strip() for x in args.layers.split(",") if x.strip()}

    check_length = not (args.no_length or args.substr_only)
    check_substrings = True

    hints = verbose_token_hints()

    all_rows: List[Dict[str, Any]] = []
    for f90 in sorted(set(iter_f90(roots, layers))):
        for hit in scan_file(
            f90,
            args.max_len,
            hints,
            check_length=check_length,
            check_substrings=check_substrings,
        ):
            row = {"file": str(f90.relative_to(here)) if f90.is_relative_to(here) else str(f90), **hit}
            all_rows.append(row)

    if args.json:
        print(json.dumps({"findings": all_rows, "count": len(all_rows)}, indent=2, ensure_ascii=False))
    else:
        print(f"scan_verbose_identifiers: {len(all_rows)} finding(s) under {roots!s}")
        by_file: Dict[str, List[Dict[str, Any]]] = {}
        for r in all_rows:
            by_file.setdefault(r["file"], []).append(r)
        for fp in sorted(by_file)[:40]:
            for r in by_file[fp][:5]:
                print(f"  {fp}:{r.get('line')}  {r.get('kind')} `{r.get('name')}`  [{r.get('detail')}]")
            if len(by_file[fp]) > 5:
                print(f"  ... {len(by_file[fp]) - 5} more in {fp}")
        if len(by_file) > 40:
            print(f"... {len(by_file) - 40} more files truncated")

    if args.fail_on is not None and len(all_rows) >= args.fail_on:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
