#!/usr/bin/env python3
"""Phase6 Track21: IF_Mem_Algo present and wired from PH_L4_Populate."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    algo = root / "ufc_core/L1_IF/Memory/IF_Mem_Algo.f90"
    pop = root / "ufc_core/L4_PH/Material/PH_L4_Populate.f90"
    if not algo.is_file():
        print("[track21] missing IF_Mem_Algo.f90", file=sys.stderr)
        return 1
    t_algo = algo.read_text(encoding="utf-8", errors="replace")
    t_pop = pop.read_text(encoding="utf-8", errors="replace")
    for needle in ("MODULE IF_Mem_Algo", "IF_Mem_Algo_Scratch_Real1D"):
        if needle not in t_algo:
            print(f"[track21] IF_Mem_Algo missing: {needle}", file=sys.stderr)
            return 1
    if "USE IF_Mem_Algo" not in t_pop or "IF_Mem_Algo_Scratch_Real1D" not in t_pop:
        print("[track21] PH_L4_Populate not wired to IF_Mem_Algo", file=sys.stderr)
        return 1
    plm = (root / "ufc_core/L4_PH/Material/Dispatch/PH_MatPLMEval.f90").read_text(encoding="utf-8", errors="replace")
    if "IF_Mem_Algo_Scratch_Real1D" not in plm:
        print("[track21] PH_MatPLMEval missing IF_Mem_Algo scratch", file=sys.stderr)
        return 1
    if plm.count("IF (.NOT. ALLOCATED(in_struct%state%stress))") > 1:
        print("[track21] PH_MatPLMEval still has duplicate hot-path ALLOCATE guards", file=sys.stderr)
        return 1
    print("[track21] IF_Mem_Algo anchor OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
