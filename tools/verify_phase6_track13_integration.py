#!/usr/bin/env python3
"""Phase6 Track 1.3: static integration checks (material rollback wiring)."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    mat = (root / "ufc_core/L3_MD/Material/Dispatch/MD_Mat_Lib.f90").read_text(encoding="utf-8", errors="replace")
    rt = (root / "ufc_core/L5_RT/StepDriver/RT_Step_Exec.f90").read_text(encoding="utf-8", errors="replace")
    for needle in ("committed_state", "UF_MaterialDef_EnsureCommittedForRollback"):
        if needle not in mat:
            print(f"[track13-int] missing in MD_Mat_Lib: {needle}", file=sys.stderr)
            return 1
    test_f90 = root / "tests/L3_MD/test_MD_MatState_snapshot.f90"
    if not test_f90.is_file():
        print("[track13-int] missing Fortran driver test_MD_MatState_snapshot.f90", file=sys.stderr)
        return 1
    for needle in (
        "MD_MatState_Snapshot",
        "MD_MatState_RestoreInto",
        "model_def",
        "inc_driver:",
        "mat_inc_snap",
        "RT_StepDriver_Execute_WithModelDef",
    ):
        if needle not in rt:
            print(f"[track13-int] missing in RT_Step_Exec: {needle}", file=sys.stderr)
            return 1
    print("[track13-int] integration markers OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
