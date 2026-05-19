#!/usr/bin/env python3
"""P2 G6-W0: production Ke/Fe golden-path files must not reference legacy PH_Elem_Contm."""
from __future__ import annotations

import re
import sys
from pathlib import Path

# Anchors from PR01 seam + Element CONTRACT Phase 4 chain.
GOLDEN_REL = (
    "ufc_core/L5_RT/Assembly/RT_Asm_Solv.f90",
    "ufc_core/L4_PH/Element/PH_Elem_Domain.f90",
    "ufc_core/L4_PH/Element/PH_Elem_Eval.f90",
    "ufc_core/L4_PH/Element/PH_ElemKeDispatch.f90",
    "ufc_core/L4_PH/Element/PH_ElemFeDispatch.f90",
)

FORBIDDEN = re.compile(
    r"PH_Elem_Contm|PH_ElemContm_Ops|Calc_Continuum|CompPoro|CompThm|CompTHM",
    re.IGNORECASE,
)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    failed = False
    for rel in GOLDEN_REL:
        path = root / rel
        if not path.is_file():
            print(f"[golden-no-contm] missing anchor: {rel}", file=sys.stderr)
            failed = True
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for i, line in enumerate(text.splitlines(), start=1):
            if line.strip().startswith("!"):
                continue
            if FORBIDDEN.search(line):
                print(
                    f"[golden-no-contm] {rel}:{i}: legacy Contm reference: {line.strip()[:120]}",
                    file=sys.stderr,
                )
                failed = True
    if failed:
        return 1
    print(f"[golden-no-contm] OK ({len(GOLDEN_REL)} anchors)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
