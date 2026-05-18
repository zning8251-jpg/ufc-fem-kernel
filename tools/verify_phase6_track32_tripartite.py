#!/usr/bin/env python3
"""Phase6 Track32-34: tripartite USE in RT_Asm_Complete + F-bar stub + generator manifest."""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    solv = (root / "ufc_core/L5_RT/Assembly/RT_Asm_Solv.f90").read_text(encoding="utf-8", errors="replace")
    fbar = (root / "ufc_core/L4_PH/Element/Solid3D/PH_Elem_FBarHook.f90").read_text(encoding="utf-8", errors="replace")
    gen = (root / "tools/gen_ph_element_stem_stub.py").read_text(encoding="utf-8", errors="replace")
    man = root / "tools/ph_element_stems_manifest.json"
    if "USE RT_Asm_Tripartite" not in solv or "RT_Asm_Tripartite_LinearIndex" not in solv:
        print("[track32] RT_Asm_Solv missing tripartite USE", file=sys.stderr)
        return 1
    if "trip_lin = RT_Asm_Tripartite_LinearIndex" not in solv:
        print("[track32] RT_Asm_Complete missing tripartite index call", file=sys.stderr)
        return 1
    if "trip_dispatch" not in solv:
        print("[track32] RT_Asm_GlobalStiffness missing tripartite dispatch hook", file=sys.stderr)
        return 1
    if "PH_Elem_FBar_PatchTest" not in fbar:
        print("[track33] PH_Elem_FBarHook missing patch-test hook", file=sys.stderr)
        return 1
    if "--manifest" not in gen:
        print("[track34] gen_ph_element_stem_stub missing --manifest", file=sys.stderr)
        return 1
    if not man.is_file():
        print("[track34] missing tools/ph_element_stems_manifest.json", file=sys.stderr)
        return 1
    data = json.loads(man.read_text(encoding="utf-8"))
    if not isinstance(data, list) or len(data) < 1:
        print("[track34] manifest must be non-empty JSON list", file=sys.stderr)
        return 1
    print("[track32-34] tripartite/F-bar/gen markers OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
