#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC architecture and naming validation script.
Checks: layer prefix, length limits, role suffix (optional), module header (Contents A-Z),
module internal A-Z order of types/subroutines/functions, filename length.
Per UFC naming checklist and refactoring plan Phase 0 / §3.1.
"""
from pathlib import Path
import re
import sys
import argparse

# Limits per UFC naming standard
MODULE_NAME_MAX = 32
PROC_NAME_MAX = 28
VAR_NAME_MAX = 20
CONST_NAME_MAX = 16
FILE_STEM_MAX = 32

# Layer prefix (module/type name must start with one of these when under that layer)
LAYER_PREFIXES = {
    "L1_IF": ("IF_", "UF_"),
    "L2_NM": ("NM_",),
    "L3_MD": ("MD_",),
    "L4_PH": ("PH_",),
    "L5_RT": ("RT_",),
    "L6_AP": ("AP_",),
}

ROLE_SUFFIXES = (
    "_Type", "_Desc", "_Ctx", "_Mgr", "_Reg", "_Eval", "_Parse",
    "_Valid", "_Init", "_API", "_Brg", "_Defn", "_Core", "_Util",
    "_Test", "_Demo", "_Ref",
)

MODULE_RE = re.compile(r"^\s*MODULE\s+(\w+)", re.I)
SUBR_RE = re.compile(r"^\s*SUBROUTINE\s+(\w+)", re.I)
# FUNCTION name( ... or FUNCTION name ( ...
FUNC_RE = re.compile(r"^\s*FUNCTION\s+(\w+)\s*[\(\s]", re.I)
# TYPE :: Name  or  TYPE(..) :: Name  or  TYPE, EXTENDS(...) :: Name
TYPE_RE = re.compile(r"^\s*TYPE\s*(?:\([^)]+\)\s*::?\s*)?(\w+)", re.I)
CONTENTS_AZ_RE = re.compile(r"Contents\s*\(A-Z\)", re.I)


def layer_from_path(path: Path) -> str | None:
    p = path.as_posix()
    for layer in ("L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"):
        if f"/{layer}/" in p or p.replace("\\", "/").startswith(layer + "/"):
            return layer
    return None


def check_prefix(module_name: str, path: Path) -> list[str]:
    layer = layer_from_path(path)
    if not layer or layer not in LAYER_PREFIXES:
        return []
    allowed = LAYER_PREFIXES[layer]
    if not any(module_name.startswith(p) for p in allowed):
        return [f"Prefix: module '{module_name}' under {layer} should start with one of {allowed}"]
    return []


def check_length_module(name: str) -> list[str]:
    if len(name) > MODULE_NAME_MAX:
        return [f"Length: module name '{name}' exceeds {MODULE_NAME_MAX} chars ({len(name)})"]
    return []


def check_length_procedure(name: str) -> list[str]:
    if len(name) > PROC_NAME_MAX:
        return [f"Length: procedure name '{name}' exceeds {PROC_NAME_MAX} chars ({len(name)})"]
    return []


# Nouns that should not start a procedure name (UFC naming §4: verb-first)
PROCEDURE_NOUN_FIRST_PREFIXES = (
    "Material_", "Materials_", "Solver_", "Solvers_", "Element_", "Elements_",
    "Matrix_", "Convergence_", "Linear_", "Nonlinear_", "Stress_", "Stiffness_",
    "Configuration_", "Assembly_", "Calculation_", "Evaluation_", "Integration_",
    "Initialization_", "Definition_", "Manager_", "Controller_", "Interface_",
    "Description_", "Result_", "Parameter_", "Operation_", "Processing_",
)

# Abbreviation hints (suggest in message)
PROCEDURE_ABBREV_HINTS = (
    ("Convergence", "Conv"), ("Validate", "Valid"), ("Solver", "Solv"),
    ("Initialization", "Init"), ("Definition", "Defn"), ("Algorithm", "Algo"),
    ("Manager", "Mgr"), ("Stiffness", "Stiff"), ("Configuration", "Cfg"),
    ("Integration", "Integ"), ("Evaluation", "Eval"), ("Material", "Mat"),
    ("Element", "Elem"), ("Matrix", "Mtx"), ("Interface", "Intf"),
)


def check_procedure_verb_first(name: str) -> list[str]:
    """Procedure names should start with a verb (UFC naming §4)."""
    violations = []
    for prefix in PROCEDURE_NOUN_FIRST_PREFIXES:
        if name.startswith(prefix) or (prefix.endswith("_") and name.startswith(prefix.rstrip("_"))):
            violations.append(
                f"Procedure verb-first: '{name}' starts with noun; use verb_entity form (e.g. Init_Mat, Setup_Solv)"
            )
            break
    return violations


def check_procedure_abbrev_hint(name: str) -> list[str]:
    """Suggest abbreviations per §4.2 (informational)."""
    hints = []
    for long_form, short in PROCEDURE_ABBREV_HINTS:
        if long_form in name and short not in name:
            hints.append(f"Procedure abbrev hint: consider '{long_form}' -> '{short}' in '{name}'")
    return hints


def check_filename_length(path: Path) -> list[str]:
    stem = path.stem
    if len(stem) > FILE_STEM_MAX:
        return [f"Length: file stem '{stem}' exceeds {FILE_STEM_MAX} chars ({len(stem)})"]
    return []


def check_module_suffix(module_name: str) -> list[str]:
    """Optional: module name should end with a known role suffix when it has one."""
    if "_" not in module_name:
        return []
    if any(module_name.endswith(s) for s in ROLE_SUFFIXES):
        return []
    # Could warn "unknown suffix" but many modules are valid without suffix (e.g. IF_Config)
    return []


def check_header_has_contents_az(text: str, path: Path) -> list[str]:
    """Require module to have 'Contents (A-Z)' in first 50 lines."""
    lines = text.splitlines()[:50]
    for line in lines:
        if CONTENTS_AZ_RE.search(line):
            return []
    return ["Module header: missing 'Contents (A-Z)' English directory comment in first 50 lines"]


def extract_content_items_in_order(text: str) -> list[tuple[str, str]]:
    """Return list of (name, kind) in order of appearance. kind in ('type','subroutine','function')."""
    items = []
    in_module = False
    for line in text.splitlines():
        stripped = line.strip()
        if MODULE_RE.match(stripped):
            in_module = True
            continue
        if in_module and re.match(r"^\s*END\s+MODULE", stripped, re.I):
            break
        if not in_module:
            continue
        if stripped.upper().startswith("END "):
            continue
        m = TYPE_RE.match(stripped)
        if m:
            items.append((m.group(1), "type"))
            continue
        s = SUBR_RE.match(stripped)
        if s:
            items.append((s.group(1), "subroutine"))
            continue
        f = FUNC_RE.match(stripped)
        if f:
            items.append((f.group(1), "function"))
    return items


def check_module_content_az_order(text: str) -> list[str]:
    """Check that types, then subroutines, then functions are each in A-Z order (per §3.1)."""
    items = extract_content_items_in_order(text)
    if not items:
        return []
    # Group by kind, check order within each kind
    by_kind = {"type": [], "subroutine": [], "function": []}
    for name, kind in items:
        by_kind[kind].append(name)
    violations = []
    for kind in ("type", "subroutine", "function"):
        names = by_kind[kind]
        if len(names) < 2:
            continue
        sorted_names = sorted(names, key=str.lower)
        if names != sorted_names:
            violations.append(
                f"Module content A-Z: {kind}s are not in alphabetical order "
                f"(first out-of-order: {names})"
            )
            break
    return violations


def validate_file(path: Path, skip_header_az: bool = False, skip_content_az: bool = False) -> dict:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return {"path": str(path), "error": str(e), "violations": []}

    violations = []
    module_name = None
    for line in text.splitlines():
        m = MODULE_RE.match(line.strip())
        if m:
            module_name = m.group(1)
            break

    if module_name:
        violations.extend(check_prefix(module_name, path))
        violations.extend(check_length_module(module_name))
    violations.extend(check_filename_length(path))

    if not skip_header_az:
        violations.extend(check_header_has_contents_az(text, path))
    if not skip_content_az:
        violations.extend(check_module_content_az_order(text))

    for line in text.splitlines():
        s = SUBR_RE.match(line.strip())
        if s:
            proc = s.group(1)
            violations.extend(check_length_procedure(proc))
            violations.extend(check_procedure_verb_first(proc))
        f = FUNC_RE.search(line)
        if f:
            proc = f.group(1)
            violations.extend(check_length_procedure(proc))
            violations.extend(check_procedure_verb_first(proc))

    return {"path": str(path), "module": module_name, "violations": violations}


def main():
    ap = argparse.ArgumentParser(description="UFC naming and architecture validation")
    ap.add_argument("paths", nargs="*", default=None, help="Files or dirs (default: ufc_core root)")
    ap.add_argument("--skip-header-az", action="store_true", help="Do not require Contents (A-Z) header")
    ap.add_argument("--skip-content-az", action="store_true", help="Do not check module content A-Z order")
    ap.add_argument("-q", "--quiet", action="store_true", help="Only exit code, no per-file output")
    args = ap.parse_args()

    root = Path(__file__).resolve().parent.parent
    paths = args.paths if args.paths else [str(root)]
    all_files = []
    for p in paths:
        path = Path(p)
        if path.is_file() and path.suffix.lower() == ".f90":
            all_files.append(path)
        elif path.is_dir():
            all_files.extend(path.rglob("*.f90"))

    by_file = []
    total_violations = 0
    for f in sorted(set(all_files)):
        res = validate_file(f, skip_header_az=args.skip_header_az, skip_content_az=args.skip_content_az)
        by_file.append(res)
        total_violations += len(res.get("violations", []))

    if not args.quiet:
        for res in by_file:
            if res.get("violations"):
                print(res["path"])
                for v in res["violations"]:
                    print("  -", v)
                print()

    if total_violations:
        if not args.quiet:
            print(f"Total violations: {total_violations} in {len([r for r in by_file if r.get('violations')])} file(s)")
        sys.exit(1)
    if not args.quiet:
        print("No naming/architecture violations found.")
    sys.exit(0)


if __name__ == "__main__":
    main()
