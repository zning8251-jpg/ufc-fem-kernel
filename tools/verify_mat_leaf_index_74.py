#!/usr/bin/env python3
"""
Validate MAT_T1_SPEC/MAT_LEAF_INDEX_74.md:
  - exactly 74 data rows (mat_id 101..708 coverage per project convention)
  - unique mat_id values
  - Primary T1 counts match the documented footer (optional cross-check)

Run:
  python UFC/ufc_core/tools/verify_mat_leaf_index_74.py
"""
from __future__ import annotations

import re
import sys
from collections import Counter
from pathlib import Path

EXPECTED_TOTAL = 74
# From MAT_LEAF_INDEX_74.md footer (must match file if you change grouping)
EXPECTED_BY_T1 = {
    "ELA": 6,
    "VSC": 9,
    "MPH": 11,
    "CMP": 5,
    "HYP": 10,
    "PLM": 9,
    "PLG": 9,
    "POR": 2,
    "DMG": 6,
    "SPU": 6,
    "USR": 1,
}


def parse_table(path: Path) -> list[tuple[int, str, str]]:
    rows: list[tuple[int, str, str]] = []
    in_table = False
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("| mat_id |"):
            in_table = True
            continue
        if not in_table or not line.startswith("|"):
            continue
        if re.match(r"^\|\s*---+", line):
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 5:
            continue
        # | empty | id | name | T1 | ...
        try:
            mid = int(parts[1])
        except ValueError:
            continue
        name = parts[2]
        t1 = parts[3]
        rows.append((mid, name, t1))
    return rows


def main() -> int:
    here = Path(__file__).resolve()
    idx = here.parent.parent / "L3_MD" / "Material" / "_inv" / "MAT_T1_SPEC" / "MAT_LEAF_INDEX_74.md"
    if not idx.is_file():
        print("ERROR: missing", idx, file=sys.stderr)
        return 1

    rows = parse_table(idx)
    if len(rows) != EXPECTED_TOTAL:
        print(f"ERROR: expected {EXPECTED_TOTAL} rows, got {len(rows)}", file=sys.stderr)
        return 1

    ids = [r[0] for r in rows]
    if len(ids) != len(set(ids)):
        dup = [k for k, v in Counter(ids).items() if v > 1]
        print("ERROR: duplicate mat_id:", dup, file=sys.stderr)
        return 1

    by_t1 = Counter(r[2] for r in rows)
    bad = {k: (EXPECTED_BY_T1.get(k), by_t1.get(k, 0)) for k in EXPECTED_BY_T1 if by_t1.get(k, 0) != EXPECTED_BY_T1[k]}
    if bad:
        print("ERROR: Primary T1 counts mismatch:", bad, file=sys.stderr)
        return 1

    print(f"OK: {idx.name} — {len(rows)} rows, {len(by_t1)} T1 keys, unique mat_id.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
