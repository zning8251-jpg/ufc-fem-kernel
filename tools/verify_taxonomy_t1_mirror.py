#!/usr/bin/env python3
"""
CI helper: L3_MD/Material vs L4_PH/Material must share the same 11 T1 subdirs
(MAT_TAXONOMY.md §2). Exits 0 on match, 1 with message on mismatch.

Run from repo root or anywhere:
  python UFC/ufc_core/tools/verify_taxonomy_t1_mirror.py
"""
from __future__ import annotations

import sys
from pathlib import Path

# Same order as MAT_TAXONOMY §2 — unified subdir names
T1_DIRS = frozenset(
    {
        "ELA",
        "HYP",
        "PLM",
        "PLG",
        "POR",
        "DMG",
        "CMP",
        "VSC",
        "MPH",
        "SPU",
        "USR",
    }
)

ALLOWED_EXTRA_L3 = frozenset({"Domain", "Registry", "Bridge", "Contract", "Shared", "Dispatch"})
ALLOWED_EXTRA_L4 = frozenset({"Domain", "Registry", "Populate", "Bridge", "Contract", "Shared", "Dispatch"})


def main() -> int:
    here = Path(__file__).resolve()
    ufc_core = here.parent.parent
    l3 = ufc_core / "L3_MD" / "Material"
    l4 = ufc_core / "L4_PH" / "Material"
    if not l3.is_dir() or not l4.is_dir():
        print("ERROR: expected", l3, "and", l4, file=sys.stderr)
        return 1

    def subdirs(root: Path) -> set[str]:
        return {p.name for p in root.iterdir() if p.is_dir() and not p.name.startswith("_")}

    d3 = subdirs(l3)
    d4 = subdirs(l4)

    missing_l3 = sorted(T1_DIRS - d3)
    missing_l4 = sorted(T1_DIRS - d4)
    stray_l3 = sorted((d3 - T1_DIRS) - {"_inv"} - ALLOWED_EXTRA_L3)
    stray_l4 = sorted((d4 - T1_DIRS) - ALLOWED_EXTRA_L4)

    err = False
    if missing_l3:
        err = True
        print("L3 missing T1 dirs:", missing_l3, file=sys.stderr)
    if missing_l4:
        err = True
        print("L4 missing T1 dirs:", missing_l4, file=sys.stderr)
    if stray_l3:
        err = True
        print("L3 stray dirs (not T1 ∪ root-public ∪ _inv):", stray_l3, file=sys.stderr)
    if stray_l4:
        err = True
        print("L4 stray dirs (not T1 ∪ root-public):", stray_l4, file=sys.stderr)

    if err:
        return 1
    print("OK: L3/L4 Material T1 mirror matches MAT_TAXONOMY §2 (11 dirs).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
