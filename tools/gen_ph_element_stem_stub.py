#!/usr/bin/env python3
"""Phase6 §3.4 — minimal element stem shell generator (contract placeholder).

Reads a small JSON or defaults and prints Fortran MODULE skeleton lines to stdout.
Real 370+ variant generation stays behind explicit config schema.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def emit_module(stem: str) -> str:
    safe = "".join(c if c.isalnum() or c == "_" else "_" for c in stem)
    return f"""! AUTO-GENERATED STUB — Phase6 track 3.4
MODULE PH_ElemGen_{safe}
  implicit none
  private
  public :: PH_ElemGen_{safe}_Info
contains
  subroutine PH_ElemGen_{safe}_Info()
    continue
  end subroutine PH_ElemGen_{safe}_Info
end MODULE PH_ElemGen_{safe}
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--stem", default="C3D8", help="element stem name")
    ap.add_argument("--json", type=Path, default=None, help="optional list of stems")
    ap.add_argument(
        "--manifest",
        type=Path,
        default=None,
        help="JSON list of stems (default: UFC/tools/ph_element_stems_manifest.json)",
    )
    ap.add_argument("--out-dir", type=Path, default=None, help="write .f90 files here")
    ap.add_argument("--dry-list", action="store_true", help="list stems that would be generated")
    ns = ap.parse_args()
    stems = [ns.stem]
    root = Path(__file__).resolve().parents[1]
    manifest_path = ns.manifest
    if manifest_path is None:
        cand = root / "tools" / "ph_element_stems_manifest.json"
        if cand.is_file():
            manifest_path = cand
    if manifest_path is not None and manifest_path.is_file():
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        stems = [str(x) for x in data] if isinstance(data, list) else [str(data)]
    elif ns.json and ns.json.is_file():
        data = json.loads(ns.json.read_text(encoding="utf-8"))
        stems = [str(x) for x in data] if isinstance(data, list) else [str(data)]
    if ns.dry_list:
        for s in stems:
            print(f"PH_ElemGen_{s}.f90")
        return 0
    for s in stems:
        text = emit_module(str(s))
        if ns.out_dir:
            ns.out_dir.mkdir(parents=True, exist_ok=True)
            out = ns.out_dir / f"PH_ElemGen_{s}.f90"
            out.write_text(text, encoding="utf-8")
            print(out)
        else:
            sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
