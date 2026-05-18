#!/usr/bin/env python3
"""Phase6 Track 1.2: static contract check (no Fortran runtime)."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    md = (root / "ufc_core/L3_MD/Analysis/Step/MD_Step_Proc.f90").read_text(encoding="utf-8", errors="replace")
    nl = (root / "ufc_core/L5_RT/Solver/RT_Solv_Nonlin.f90").read_text(encoding="utf-8", errors="replace")
    for needle in ("arc_nonconverge_use_warn", "arc_constraint_tol_scale"):
        if needle not in md:
            print(f"[track12] missing in MD_Step_Proc: {needle}", file=sys.stderr)
            return 1
    if "arc_nonconverge_use_warn" not in nl or "IF_STATUS_WARN" not in nl:
        print("[track12] ArcLen WARN branch missing in RT_Solv_Nonlin", file=sys.stderr)
        return 1
    if "CASE (4)" not in nl or "RT_NLSolver_ArcLen" not in nl:
        print("[track12] ArcLen dispatch CASE(4) missing in RT_Solv_Nonlin", file=sys.stderr)
        return 1
    arclen_test = root / "tests/L5_RT/test_RT_NLSolver_ArcLen_min.f90"
    if not arclen_test.is_file():
        print("[track12] missing test_RT_NLSolver_ArcLen_min.f90", file=sys.stderr)
        return 1
    print("[track12] contract OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
