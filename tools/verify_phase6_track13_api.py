#!/usr/bin/env python3
"""Phase6 Track 1.3: ensure MD_MatState snapshot API exists (static)."""
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    text = (root / "ufc_core/L3_MD/Material/Contract/MD_Mat_Def.f90").read_text(encoding="utf-8", errors="replace")
    for name in ("MD_MatState_Snapshot", "MD_MatState_RestoreInto"):
        if f"SUBROUTINE {name}" not in text and f"subroutine {name}" not in text.lower():
            print(f"[track13] missing subroutine {name}", file=sys.stderr)
            return 1
    print("[track13] API OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
