#!/usr/bin/env python3
"""P2 G5: Elem_Ke_In must expose the same index fields as PH_Element_Compute_Ke_Arg."""
from __future__ import annotations

import re
import sys
from pathlib import Path

REQUIRED_IN_RT_ELEM_PROC = (
    "elem_idx",
    "l3_elem_idx",
    "mat_pt_idx",
    "nDof",
    "coords",
    "mat_props_in",
)

REQUIRED_IN_PH_ELEM_DEF = (
    "elem_idx",
    "l3_elem_idx",
    "mat_pt_idx",
    "nDof",
    "mat_props_in",
)

BRG_SYMBOLS = (
    "RT_Elem_KeIn_ApplyAsmArg",
    "RT_Elem_KeIn_ClearMatProps",
)


def _type_block(text: str, type_name: str) -> str | None:
    pat = rf"TYPE,\s*PUBLIC\s*::\s*{re.escape(type_name)}\b(.*?)^\s*END\s+TYPE\s+{re.escape(type_name)}"
    m = re.search(pat, text, re.MULTILINE | re.DOTALL | re.IGNORECASE)
    return m.group(1) if m else None


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    proc_path = root / "ufc_core/L5_RT/Element/RT_Elem_Proc.f90"
    def_path = root / "ufc_core/L4_PH/Element/PH_Elem_Def.f90"
    brg_path = root / "ufc_core/L5_RT/Element/RT_ElemDispatch_Brg.f90"
    failed = False

    proc_text = proc_path.read_text(encoding="utf-8", errors="replace")
    block = _type_block(proc_text, "Elem_Ke_In")
    if block is None:
        print("[rt-elem-ke-in] missing TYPE Elem_Ke_In in RT_Elem_Proc.f90", file=sys.stderr)
        failed = True
    else:
        for field in REQUIRED_IN_RT_ELEM_PROC:
            if not re.search(rf"\b{re.escape(field)}\b", block):
                print(f"[rt-elem-ke-in] Elem_Ke_In missing field: {field}", file=sys.stderr)
                failed = True

    def_text = def_path.read_text(encoding="utf-8", errors="replace")
    ke_block = _type_block(def_text, "PH_Element_Compute_Ke_Arg")
    if ke_block is None:
        print("[rt-elem-ke-in] missing TYPE PH_Element_Compute_Ke_Arg", file=sys.stderr)
        failed = True
    else:
        for field in REQUIRED_IN_PH_ELEM_DEF:
            if not re.search(rf"\b{re.escape(field)}\b", ke_block):
                print(f"[rt-elem-ke-in] PH_Element_Compute_Ke_Arg missing field: {field}", file=sys.stderr)
                failed = True

    brg_text = brg_path.read_text(encoding="utf-8", errors="replace")
    for sym in BRG_SYMBOLS:
        if sym not in brg_text:
            print(f"[rt-elem-ke-in] RT_ElemDispatch_Brg missing {sym}", file=sys.stderr)
            failed = True
    if "ke_in%mat_props_in" not in brg_text:
        print("[rt-elem-ke-in] RT_Elem_Brg_ComputeKe must use ke_in%mat_props_in", file=sys.stderr)
        failed = True
    if re.search(r"ke_in%u\s*,\s*algo_params", brg_text):
        print("[rt-elem-ke-in] RT_Elem_Brg_ComputeKe must not pass ke_in%u as mat_props", file=sys.stderr)
        failed = True

    if failed:
        return 1
    print("[rt-elem-ke-in] OK (Elem_Ke_In ↔ PH_Element_Compute_Ke_Arg + Brg helpers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
