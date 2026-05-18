#!/usr/bin/env python3
"""Ensure every PUBLIC symbol in MD_Mat_PLM_PlastBase is imported via a USE ... ONLY block.

(Legacy name: verify_plastic_reg_exports.py — checks the L3 plastic aggregate facade.)
"""
from __future__ import annotations

import pathlib
import re
import sys


def _split_list(chunk: str) -> list[str]:
    out: list[str] = []
    for part in chunk.split(","):
        name = part.split("!")[0].strip()
        if name:
            out.append(name)
    return out


def _module_header(text: str) -> str:
    m = re.search(
        r"(?is)MODULE\s+MD_Mat_PLM_PlastBase\s*(.*?)^\s*IMPLICIT\s+NONE",
        text,
        re.MULTILINE,
    )
    if not m:
        raise SystemExit("Could not find MODULE MD_Mat_PLM_PlastBase ... IMPLICIT NONE span")
    return m.group(1)


def imported_only_symbols(header: str) -> set[str]:
    flat = re.sub(r"&\s*\n\s*&?\s*", " ", header)
    flat = re.sub(r"\s+", " ", flat)
    syms: set[str] = set()
    for m in re.finditer(r"(?i)\bUSE\s+\w+\s*,\s*ONLY\s*:\s*(.+?)(?=\bUSE\s+\w+\s*,\s*ONLY\s*:|\Z)", flat):
        for s in _split_list(m.group(1)):
            syms.add(s.lower())
    return syms


def public_symbols(reg_text: str) -> set[str]:
    syms: set[str] = set()
    for m in re.finditer(r"^\s*PUBLIC\s*::\s*(.+)$", reg_text, re.MULTILINE | re.IGNORECASE):
        for s in _split_list(m.group(1)):
            syms.add(s.lower())
    return syms


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    reg_path = root / "L3_MD/Material/Dispatch/PLM/MD_Mat_PLM_PlastBase.f90"
    reg_text = reg_path.read_text(encoding="utf-8", errors="replace")
    header = _module_header(reg_text)
    imp = imported_only_symbols(header)
    pub = public_symbols(reg_text)
    missing = sorted(pub - imp)
    if missing:
        print("PUBLIC symbols in MD_Mat_PLM_PlastBase without a matching USE ... ONLY import:")
        for n in missing:
            print(f"  {n}")
        return 1
    print(f"OK: {len(pub)} PUBLIC symbols match USE ... ONLY imports (MD_Mat_PLM_PlastBase).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
