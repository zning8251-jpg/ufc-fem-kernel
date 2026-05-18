#!/usr/bin/env python3
"""
Unify TBP implementation names in Material *_{MD|PH|RT}_Mat_<Family>_Def.f90 files:
  <Stem>_<Role>_<Verb>  ->  <Role>_<Verb>
Roles: Dispatch_Table, Desc, State, Algo, Ctx (longest prefix first).

Special cases (legacy names without _Desc_):
  MD_Mat_Plast_Def.f90: MD_Mat_Plast_ComputeDerived -> Desc_ComputeDerived,
                        MD_Mat_Plast_Clean -> Desc_Clean (after role renames).

Usage (from repo root, PowerShell):
  python UFC/tools/tbp_mat_def_short_impl.py --apply
  python UFC/tools/tbp_mat_def_short_impl.py          # dry-run, print only
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Repo root: .../UFC/tools/ -> parents[1] == UFC
_UFC_ROOT = Path(__file__).resolve().parents[1]
_UFC_CORE = _UFC_ROOT / "ufc_core"

_MODULE_RE = re.compile(r"^\s*MODULE\s+(\w+)\s*$", re.IGNORECASE | re.MULTILINE)

_ROLES_ORDERED = (
    "Dispatch_Table",
    "Desc",
    "State",
    "Algo",
    "Ctx",
)

# (filename, old, new) after standard role-prefix pass
_POST_REPLACE_BY_BASENAME: dict[str, list[tuple[str, str]]] = {
    "MD_Mat_Plast_Def.f90": [
        ("MD_Mat_Plast_ComputeDerived", "Desc_ComputeDerived"),
        ("MD_Mat_Plast_Clean", "Desc_Clean"),
    ],
}


def _iter_mat_def_files() -> list[Path]:
    out: list[Path] = []
    for base in (
        _UFC_CORE / "L3_MD" / "Material",
        _UFC_CORE / "L4_PH" / "Material",
        _UFC_CORE / "L5_RT" / "Material",
    ):
        if not base.is_dir():
            continue
        for p in base.rglob("*_Mat_*_Def.f90"):
            if p.is_file():
                out.append(p)
    return sorted(set(out))


def _stem_from_module(mod: str) -> str | None:
    if not mod.endswith("_Def"):
        return None
    return mod[: -len("_Def")]


def transform_text(path: Path, text: str) -> tuple[str, bool]:
    m = _MODULE_RE.search(text)
    if not m:
        return text, False
    stem = _stem_from_module(m.group(1))
    if not stem:
        return text, False
    if not (stem.startswith("MD_Mat_") or stem.startswith("PH_Mat_") or stem.startswith("RT_Mat_")):
        return text, False

    original = text
    for role in _ROLES_ORDERED:
        old_p = f"{stem}_{role}_"
        new_p = f"{role}_"
        text = text.replace(old_p, new_p)

    for old_s, new_s in _POST_REPLACE_BY_BASENAME.get(path.name, []):
        text = text.replace(old_s, new_s)

    return text, text != original


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write files")
    args = ap.parse_args()

    changed_files: list[Path] = []
    for path in _iter_mat_def_files():
        raw = path.read_text(encoding="utf-8", errors="replace")
        new_text, changed = transform_text(path, raw)
        if not changed:
            continue
        changed_files.append(path)
        if args.apply:
            path.write_text(new_text, encoding="utf-8", newline="\n")
        else:
            print(f"would update: {path.relative_to(_UFC_ROOT)}")

    print(f"{'Updated' if args.apply else 'Would update'} {len(changed_files)} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
