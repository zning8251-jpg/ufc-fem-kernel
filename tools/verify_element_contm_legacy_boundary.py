#!/usr/bin/env python3
"""P2 G6-W2: only allowlisted L4 Element files may reference legacy Contm/Ops."""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Paths relative to repo root (forward slashes).
ALLOWLIST_PREFIXES = (
    "ufc_core/L4_PH/Element/Legacy/",
    "ufc_core/L4_PH/Element/PH_Elem_Contm.f90",
    "ufc_core/L4_PH/Element/PH_ElemContm_Ops.f90",
    "ufc_core/L4_PH/Element/Solid2D/PH_Elem_Sld2D_Def.f90",
    "ufc_core/L4_PH/Element/Solid3D/PH_Elem_Sld3D_Def.f90",
    "ufc_core/L4_PH/Element/Solid2Dt/",
    "ufc_core/L4_PH/Element/Solid3Dt/",
    "ufc_core/L3_MD/Bridge/Bridge_L4/MD_ElemPH_Brg.f90",
)

SCAN_ROOT = "ufc_core/L4_PH/Element"

FORBIDDEN = re.compile(
    r"PH_Elem_Contm\b|PH_ElemContm_Ops|PH_Elem_Contm_Brg|Calc_Continuum|CompPoro|CompThm|CompTHM",
    re.IGNORECASE,
)


def _norm(rel: str) -> str:
    return rel.replace("\\", "/")


def _allowed(rel: str) -> bool:
    n = _norm(rel)
    return any(n == p or n.startswith(p) for p in ALLOWLIST_PREFIXES)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    scan = root / SCAN_ROOT
    if not scan.is_dir():
        print(f"[contm-legacy-boundary] missing scan root: {SCAN_ROOT}", file=sys.stderr)
        return 1

    failed = False
    checked = 0
    for path in sorted(scan.rglob("*.f90")):
        rel = _norm(str(path.relative_to(root)))
        if _allowed(rel):
            continue
        checked += 1
        text = path.read_text(encoding="utf-8", errors="replace")
        for i, line in enumerate(text.splitlines(), start=1):
            if line.strip().startswith("!"):
                continue
            if FORBIDDEN.search(line):
                print(
                    f"[contm-legacy-boundary] {rel}:{i}: "
                    f"legacy Contm reference outside allowlist: {line.strip()[:120]}",
                    file=sys.stderr,
                )
                failed = True

    if failed:
        return 1
    print(f"[contm-legacy-boundary] OK (scanned {checked} non-allowlisted files under {SCAN_ROOT})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
