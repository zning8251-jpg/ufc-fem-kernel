#!/usr/bin/env python3
"""Phase6 Track22/23: RT_Step_Ctx work_vec lifecycle in RT_Step_Core."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    core = (root / "ufc_core/L5_RT/StepDriver/RT_Step_Core.f90").read_text(encoding="utf-8", errors="replace")
    df = (root / "ufc_core/L5_RT/StepDriver/RT_Step_Def.f90").read_text(encoding="utf-8", errors="replace")
    if "work_vec" not in df:
        print("[track22] RT_Step_Def missing work_vec", file=sys.stderr)
        return 1
    for needle in (
        "ALLOCATE (ctx%work_vec",
        "IF (ASSOCIATED(ctx%work_vec)) DEALLOCATE (ctx%work_vec)",
        "ctx%work_vec(1:n_dof) = du(1:n_dof)",
    ):
        if needle not in core:
            print(f"[track22] RT_Step_Core missing: {needle}", file=sys.stderr)
            return 1
    print("[track22-23] work_vec lifecycle OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
