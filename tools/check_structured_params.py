#!/usr/bin/env python3
"""
Check if subroutines use structured types instead of exposing members.
Validates UFC design principle: struct-oriented parameter passing (域边界与链路打通 2.3).

Usage:
  python tools/check_structured_params.py src/L4_PH/Mat/PH_Mat_Elastic_Algo.f90
  python tools/check_structured_params.py --all-layers --output encapsulation_violations.csv
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple


# Rule 1: internal field names that should not appear as standalone parameters
EXPOSED_FIELDS = [
    "young_mod", "poisson", "mat_id", "elem_id", "ndof", "nel", "ngauss", "density",
    "thermal_exp", "thermal_expansion", "yield_stress", "stress", "strain", "plastic_strain",
    "xyz", "connect", "sdv", "props", "dtime", "dt", "time_current", "time_increment",
]

# Related param groups: if >= 3 from same group appear, suggest grouping into TYPE
MAT_GROUP = ["young_mod", "poisson", "density", "thermal_exp", "thermal_expansion", "props"]
ELEM_GROUP = ["nel", "ndof", "ngauss", "xyz", "connect", "elem_id"]
STATE_GROUP = ["stress", "strain", "plastic_strain", "sdv", "stress_old", "strain_old"]

PARAM_GROUP_NAMES = {
    "mat": MAT_GROUP,
    "elem": ELEM_GROUP,
    "state": STATE_GROUP,
}


def extract_subroutines(content: str, filepath: str) -> List[Dict[str, Any]]:
    """Extract subroutine signatures and parameter names from Fortran source."""
    subs: List[Dict[str, Any]] = []
    # Match subroutine ... ( ... ) and capture name and argument list
    pattern = re.compile(
        r"\bsubroutine\s+(\w+)\s*\((.*?)\)"
        r"|SUBROUTINE\s+(\w+)\s*\((.*?)\)",
        re.IGNORECASE | re.DOTALL,
    )
    for m in pattern.finditer(content):
        name = (m.group(1) or m.group(3)).strip()
        args = (m.group(2) or m.group(4) or "").strip()
        if not args or args.upper() in ("", "NONE"):
            param_names = []
        else:
            # Split by comma, respect nested parens loosely
            param_names = []
            for part in re.split(r"\s*,\s*", args):
                # Take first word (variable name) before optional :: or (
                part = part.strip()
                if "::" in part:
                    part = part.split("::", 1)[1].strip()
                first = part.split()[0].strip() if part else ""
                if first and not first.upper().startswith("INTENT"):
                    param_names.append(first.lower())
        subs.append({
            "file": filepath,
            "name": name,
            "param_names": param_names,
            "param_count": len(param_names),
        })
    return subs


def has_multiple_related_params(param_names: List[str]) -> Tuple[bool, Optional[str], List[str]]:
    """Check if multiple related params suggest grouping into TYPE."""
    param_set = {p.lower() for p in param_names}
    for group_name, group in PARAM_GROUP_NAMES.items():
        count = sum(1 for g in group if g.lower() in param_set)
        if count >= 3:
            found = [p for p in param_names if p.lower() in [x.lower() for x in group]]
            return True, group_name, found
    return False, None, []


def check_subroutine_encapsulation(fortran_file: str) -> List[Dict[str, Any]]:
    """
    Check subroutine interfaces for struct-oriented parameter passing.
    """
    path = Path(fortran_file)
    if not path.exists():
        return [{"file": fortran_file, "subroutine": "", "type": "FILE_NOT_FOUND", "message": f"File not found: {fortran_file}"}]

    content = path.read_text(encoding="utf-8", errors="replace")
    subs = extract_subroutines(content, str(path))
    violations: List[Dict[str, Any]] = []

    for sub in subs:
        params = sub["param_names"]

        # Rule 1: exposed internal fields
        for field in EXPOSED_FIELDS:
            if field.lower() in [p.lower() for p in params]:
                violations.append({
                    "file": sub["file"],
                    "subroutine": sub["name"],
                    "type": "EXPOSED_FIELD",
                    "field": field,
                    "message": f"Should use TYPE instead of exposing '{field}'",
                })

        # Rule 2: related params should be grouped into TYPE
        related, group_name, related_list = has_multiple_related_params(params)
        if related and group_name:
            violations.append({
                "file": sub["file"],
                "subroutine": sub["name"],
                "type": "SHOULD_GROUP",
                "params": related_list,
                "group": group_name,
                "message": f"Related params ({', '.join(related_list)}) should be grouped into TYPE",
            })

        # Rule 3: too many parameters (>8 warning, >5 primitive suggests pack TYPE)
        if sub["param_count"] > 8:
            # Heuristic: assume non-type params are REAL/INTEGER/LOGICAL if short and no type prefix
            primitive_count = sum(
                1 for p in params
                if p.lower() not in ("mat_desc", "elem_desc", "ctx", "state", "status", "pack", "desc", "algo", "solv_ctx")
            )
            if primitive_count > 5:
                violations.append({
                    "file": sub["file"],
                    "subroutine": sub["name"],
                    "type": "TOO_MANY_PARAMS",
                    "count": sub["param_count"],
                    "message": f"{sub['param_count']} params (recommend <8). Consider using pack TYPE.",
                })

    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description="Check struct-oriented parameter passing (UFC 2.3)")
    parser.add_argument("files", nargs="*", help="Fortran .f90 files to check")
    parser.add_argument("--all-layers", action="store_true", help="Scan L1_IF through L6_AP for .f90")
    parser.add_argument("--output", "-o", help="Write violations to CSV file")
    parser.add_argument("--layer", help="Limit --all-layers to one layer (e.g. L4_PH)")
    args = parser.parse_args()

    if args.all_layers:
        base = Path(__file__).resolve().parent.parent
        layers = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]
        if args.layer:
            layers = [args.layer]
        files = []
        for ly in layers:
            d = base / ly
            if d.is_dir():
                files.extend(d.rglob("*.f90"))
        args.files = [str(p) for p in sorted(set(files))]

    if not args.files:
        parser.print_help()
        return 0

    all_violations: List[Dict[str, Any]] = []
    for f in args.files:
        all_violations.extend(check_subroutine_encapsulation(f))

    if args.output:
        import csv
        with open(args.output, "w", newline="", encoding="utf-8") as out:
            if all_violations:
                w = csv.DictWriter(out, fieldnames=["file", "subroutine", "type", "message", "field", "params", "count"])
                w.writeheader()
                for v in all_violations:
                    row = {k: v.get(k, "") for k in ["file", "subroutine", "type", "message", "field", "count"]}
                    row["params"] = ",".join(v.get("params", [])) if v.get("params") else ""
                    w.writerow(row)
        print(f"Wrote {len(all_violations)} violations to {args.output}")

    if all_violations:
        print(f"\n{'='*70}")
        print(f"Found {len(all_violations)} encapsulation violation(s)")
        print(f"{'='*70}\n")
        for v in all_violations:
            print(f"[{v['type']}] {v.get('subroutine', '?')}")
            print(f"  File: {v['file']}")
            print(f"  {v['message']}")
            if "field" in v and v["field"]:
                print(f"  Exposed field: {v['field']}")
            if "params" in v and v["params"]:
                print(f"  Related params: {', '.join(v['params'])}")
            print()
        return 1

    print("All checked subroutines use structured parameter passing (or no subroutines found).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
