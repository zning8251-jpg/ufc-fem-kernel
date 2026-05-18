#!/usr/bin/env python3
"""Ensure MD_Mat_PLM_PlastBase USE ... ONLY imports from MD_MAT_PLG_GEOTECH_DESC
are covered by PUBLIC symbols in the Geotech module (case-insensitive Fortran names)."""
from __future__ import annotations

import pathlib
import re
import sys


def _split_fortran_list(chunk: str) -> list[str]:
    out: list[str] = []
    for part in chunk.split(","):
        name = part.split("!")[0].strip()
        if name:
            out.append(name)
    return out


def public_symbols(geotech_text: str) -> set[str]:
    syms: set[str] = set()
    for m in re.finditer(r"^\s*PUBLIC\s*::\s*(.+)$", geotech_text, re.MULTILINE | re.IGNORECASE):
        line = m.group(1)
        for s in _split_fortran_list(line):
            syms.add(s.lower())
    return syms


def only_imports_from_geotech(plastic_text: str) -> list[str]:
    """Extract ONLY-list for the first USE MD_MAT_PLG_GEOTECH_DESC (stop before next top-level USE)."""
    key = re.search(
        r"(?m)^\s*USE\s+MD_MAT_PLG_GEOTECH_DESC\s*,\s*ONLY\s*:",
        plastic_text,
        re.IGNORECASE,
    )
    if not key:
        raise SystemExit("Could not find USE MD_MAT_PLG_GEOTECH_DESC, ONLY: in MD_Mat_PLM_PlastBase")
    rest = plastic_text[key.end() :]
    lines: list[str] = []
    for raw in rest.splitlines():
        if re.match(r"^\s*USE\s+[A-Za-z_]", raw) and lines:
            break
        lines.append(raw)
    block = "\n".join(lines)
    block = re.sub(r"&\s*\n\s*&?", " ", block)
    block = re.sub(r"\s+", " ", block)
    return _split_fortran_list(block)


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    geotech = (root / "L3_MD/Material/Contract/PLG/MD_MAT_PLG_GEOTECH_DESC.f90").read_text(
        encoding="utf-8", errors="replace"
    )
    plastic = (root / "L3_MD/Material/Dispatch/PLM/MD_Mat_PLM_PlastBase.f90").read_text(
        encoding="utf-8", errors="replace"
    )
    pub = public_symbols(geotech)
    need = only_imports_from_geotech(plastic)
    missing = [n for n in need if n.lower() not in pub]
    if missing:
        print("Missing from MD_MAT_PLG_GEOTECH_DESC PUBLIC (needed by PlastBase ONLY):")
        for n in missing:
            print(f"  {n}")
        return 1
    print(f"OK: {len(need)} ONLY imports from Geotech match PUBLIC exports.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
