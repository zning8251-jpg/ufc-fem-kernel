#!/usr/bin/env python3
"""
Scan L3_MD/Material for Fortran TYPE declarations with PUBLIC visibility.

Output: UFC/REPORTS/material_public_types_index.json

Heuristic (line-based):
  - Match TYPE ... :: Name (optional EXTENDS(Parent))
  - Require PUBLIC somewhere on the same logical statement (handles continuation lines)
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAT = ROOT / "ufc_core" / "L3_MD" / "Material"
OUT = ROOT / "REPORTS" / "material_public_types_index.json"

# TYPE, PUBLIC [, EXTENDS(parent)] :: TypeName (search within joined statement)
RE_TYPE = re.compile(
    r"TYPE\s*,\s*PUBLIC(?:\s*,\s*EXTENDS\s*\(\s*([^)]+?)\s*\))?\s*::\s*(\w+)",
    re.IGNORECASE,
)


def collect_statement(lines: list[str], start_idx: int) -> str:
    """Join Fortran continuation lines starting at start_idx (0-based)."""
    parts = [lines[start_idx].rstrip()]
    j = start_idx
    while parts[-1].rstrip().endswith("&") and j + 1 < len(lines):
        j += 1
        parts.append(lines[j].rstrip())
    return " ".join(parts)


def scan_file(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    hits: list[dict] = []
    idx = 0
    rel = path.relative_to(ROOT).as_posix()
    while idx < len(lines):
        stmt = collect_statement(lines, idx)
        m = RE_TYPE.search(stmt)
        if m and "PUBLIC" in stmt.upper():
            parent = (m.group(1) or "").strip() or None
            name = m.group(2).strip()
            hits.append(
                {
                    "type_name": name,
                    "extends": parent,
                    "file": rel,
                    "line": idx + 1,
                }
            )
        idx += 1
    return hits


def main() -> int:
    if not MAT.is_dir():
        print("Missing", MAT, file=sys.stderr)
        return 1
    all_hits: list[dict] = []
    for p in sorted(MAT.rglob("*.f90")):
        all_hits.extend(scan_file(p))
    all_hits.sort(key=lambda h: (h["file"], h["line"]))
    payload = {
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "scan_root": "ufc_core/L3_MD/Material",
        "count": len(all_hits),
        "public_types": all_hits,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(all_hits)} types)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
