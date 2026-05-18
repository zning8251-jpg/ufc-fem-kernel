#!/usr/bin/env python3
"""
One-shot rename: MD_MatDesc -> MD_Mat_Desc (Fortran material main-card TYPE).

Order:
  1) MD_MatDesc_ -> MD_Mat_Desc_
  2) whole word MD_MatDesc -> MD_Mat_Desc

Run from repo after Base/MD_Mat_BaseDef.f90 lite type renamed to MD_Mat_LiteDesc.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # UFC/
SCAN_DIRS = [ROOT / "ufc_core", ROOT / "tests"]
EXTENSIONS = {".f90", ".F90"}


def transform(text: str) -> str:
    s = text.replace("MD_MatDesc_", "MD_Mat_Desc_")
    s = re.sub(r"\bMD_MatDesc\b", "MD_Mat_Desc", s)
    return s


def main() -> int:
    changed = 0
    files = []
    for base in SCAN_DIRS:
        if not base.is_dir():
            continue
        for p in base.rglob("*"):
            if p.suffix not in EXTENSIONS:
                continue
            raw = p.read_text(encoding="utf-8", errors="replace")
            new = transform(raw)
            if new != raw:
                p.write_text(new, encoding="utf-8", newline="\n")
                changed += 1
                files.append(str(p.relative_to(ROOT)))
    print(f"Updated {changed} files under ufc_core/tests")
    for f in sorted(files)[:40]:
        print(" ", f)
    if len(files) > 40:
        print(f"  ... and {len(files) - 40} more")
    return 0


if __name__ == "__main__":
    sys.exit(main())
