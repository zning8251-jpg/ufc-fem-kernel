#!/usr/bin/env python3
"""
UFC naming normalization: rename full-domain files to abbreviated domain names,
update MODULE/END MODULE declarations, and update all USE references.

Usage:
  python naming_normalize.py --dry-run          # preview changes
  python naming_normalize.py --execute          # apply changes
  python naming_normalize.py --execute --layer L5_RT  # single layer
"""
import os
import re
import sys
import shutil
import argparse
from pathlib import Path
from collections import defaultdict

UFC_CORE = Path(r"d:\TEST7\UFC\ufc_core")
EXCLUDE_DIRS = {"ExternalLibs"}

DOMAIN_ABBREV = {
    "Material": "Mat",
    "Element": "Elem",
    "Contact": "Cont",
    "Solver": "Solv",
    "Assembly": "Asm",
    "Output": "Out",
    "WriteBack": "WB",
    "KeyWord": "KW",
    "Interaction": "Int",
    "Section": "Sect",
    "Boundary": "BC",
    "LoadBC": "LBC",
    "Constraint": "Constr",
    "Coupling": "Cpl",
    "Amplitude": "Amp",
    "Error": "Err",
    "Memory": "Mem",
    "Monitor": "Mon",
    "Registry": "Reg",
    "Precision": "Prec",
    "Matrix": "Mtx",
    "Logging": "Log",
    "StepDriver": "Step",
    "Bridge": "Brg",
}

MOD_DECL = re.compile(r"^(\s*)(MODULE)\s+(\w+)", re.IGNORECASE)
END_MOD = re.compile(r"^(\s*)(END\s+MODULE)\s+(\w+)", re.IGNORECASE)
USE_STMT = re.compile(r"^(\s*)(USE)\s+(\w+)", re.IGNORECASE)


def should_exclude(path):
    parts = path.parts
    return any(ex in parts for ex in EXCLUDE_DIRS)


def compute_new_module_name(old_name):
    """Given a module name like MD_Material_Core, return MD_Mat_Core."""
    for full, abbr in sorted(DOMAIN_ABBREV.items(), key=lambda x: -len(x[0])):
        pattern = re.compile(r"^(\w+?_)" + re.escape(full) + r"(_|$)", re.IGNORECASE)
        m = pattern.match(old_name)
        if m:
            prefix = m.group(1)
            suffix = old_name[m.end(1) + len(full):]
            return prefix + abbr + suffix
    return None


def find_rename_candidates(layer_filter=None):
    """Find all .f90 files whose MODULE name uses a full domain name.
    
    Only considers the FIRST module in each file for file renaming.
    Skips files where the abbreviated target file already exists (collision).
    Also collects secondary modules inside files for USE-only updates.
    """
    candidates = []
    secondary_modules = []  # modules in multi-module files, USE-only update
    seen_files = set()
    
    for f in sorted(UFC_CORE.rglob("*.f90")):
        if should_exclude(f):
            continue
        if layer_filter:
            parts = str(f).split("ufc_core")
            if len(parts) > 1:
                layer = parts[1].split(os.sep)[1] if os.sep in parts[1][1:] else ""
                if layer != layer_filter:
                    continue

        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        first_module = True
        for line in content.split("\n"):
            m = MOD_DECL.match(line)
            if not m:
                continue
            mod_name = m.group(3)
            if mod_name.upper() == "PROCEDURE":
                continue
            new_name = compute_new_module_name(mod_name)
            if new_name and new_name.lower() != mod_name.lower():
                if first_module and f not in seen_files:
                    # Only rename file if module name matches filename
                    fname_matches = (mod_name.lower() == f.stem.lower())
                    new_file = f.parent / (new_name + ".f90")
                    
                    if not fname_matches:
                        # Module name doesn't match file — multi-module file
                        secondary_modules.append({
                            "file": f,
                            "old_module": mod_name,
                            "new_module": new_name,
                            "collision": False,
                        })
                    elif new_file.exists() and new_file != f:
                        secondary_modules.append({
                            "file": f,
                            "old_module": mod_name,
                            "new_module": new_name,
                            "collision": True,
                        })
                    else:
                        candidates.append({
                            "file": f,
                            "old_module": mod_name,
                            "new_module": new_name,
                            "new_file": new_file,
                        })
                    seen_files.add(f)
                else:
                    secondary_modules.append({
                        "file": f,
                        "old_module": mod_name,
                        "new_module": new_name,
                        "collision": False,
                    })
            first_module = False
    return candidates, secondary_modules


def find_all_use_references(old_module):
    """Find all .f90 files that USE the given module name."""
    refs = []
    pat = re.compile(r"^\s*USE\s+" + re.escape(old_module) + r"\b", re.IGNORECASE)
    for f in sorted(UFC_CORE.rglob("*.f90")):
        if should_exclude(f):
            continue
        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for i, line in enumerate(content.split("\n"), 1):
            if pat.match(line):
                refs.append((f, i))
    return refs


def update_module_in_file(filepath, old_mod, new_mod, dry_run=True):
    """Update MODULE declaration, END MODULE, and internal references in a file."""
    content = filepath.read_text(encoding="utf-8", errors="replace")
    old_pat = re.compile(r"\b" + re.escape(old_mod) + r"\b")

    new_lines = []
    changed = False
    for line in content.split("\n"):
        m_decl = MOD_DECL.match(line)
        m_end = END_MOD.match(line)

        if m_decl and m_decl.group(3) == old_mod:
            line = m_decl.group(1) + m_decl.group(2) + " " + new_mod
            changed = True
        elif m_end and m_end.group(3) == old_mod:
            line = m_end.group(1) + m_end.group(2) + " " + new_mod
            changed = True
        new_lines.append(line)

    if changed and not dry_run:
        filepath.write_text("\n".join(new_lines), encoding="utf-8")
    return changed


def update_use_references(old_mod, new_mod, dry_run=True):
    """Update all USE statements referencing old_mod across the codebase."""
    count = 0
    pat = re.compile(
        r"^(\s*USE\s+)" + re.escape(old_mod) + r"\b",
        re.IGNORECASE | re.MULTILINE
    )
    for f in sorted(UFC_CORE.rglob("*.f90")):
        if should_exclude(f):
            continue
        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        new_content, n = pat.subn(r"\g<1>" + new_mod, content)
        if n > 0:
            count += n
            if not dry_run:
                f.write_text(new_content, encoding="utf-8")
    return count


def rename_file(old_path, new_path, dry_run=True):
    """Rename a file (git mv style)."""
    if old_path == new_path:
        return False
    if not dry_run:
        if new_path.exists():
            print(f"  WARNING: target exists, skipping: {new_path}")
            return False
        shutil.move(str(old_path), str(new_path))
    return True


def main():
    parser = argparse.ArgumentParser(description="UFC naming normalization")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--execute", action="store_true")
    parser.add_argument("--layer", type=str, default=None, help="e.g. L5_RT")
    args = parser.parse_args()

    dry_run = not args.execute

    print(f"Mode: {'DRY-RUN' if dry_run else 'EXECUTE'}")
    if args.layer:
        print(f"Layer filter: {args.layer}")
    print()

    candidates, secondary = find_rename_candidates(args.layer)
    print(f"Found {len(candidates)} rename candidates, {len(secondary)} secondary/collision modules")
    print()

    # Process collision/secondary modules first (USE-only updates)
    if secondary:
        print("=== COLLISION / SECONDARY MODULES (USE-only update) ===\n")
        for s in secondary:
            old_mod = s["old_module"]
            new_mod = s["new_module"]
            tag = "COLLISION" if s.get("collision") else "SECONDARY"
            use_refs = find_all_use_references(old_mod)
            print(f"  [{tag}] {old_mod} -> {new_mod} (in {s['file'].name}, {len(use_refs)} USE refs)")
            if not dry_run:
                update_module_in_file(s["file"], old_mod, new_mod, dry_run=False)
                n = update_use_references(old_mod, new_mod, dry_run=False)
                print(f"    Updated: MODULE decl + {n} USE refs")
        print()

    # Process file renames
    print("=== FILE RENAMES ===\n")
    for c in candidates:
        old_mod = c["old_module"]
        new_mod = c["new_module"]
        old_file = c["file"]
        new_file = c["new_file"]

        use_refs = find_all_use_references(old_mod)
        print(f"--- {old_mod} -> {new_mod} ---")
        print(f"  File: {old_file.name} -> {new_file.name}")
        print(f"  USE references: {len(use_refs)}")

        if not dry_run:
            update_module_in_file(old_file, old_mod, new_mod, dry_run=False)
            n = update_use_references(old_mod, new_mod, dry_run=False)
            renamed = rename_file(old_file, new_file, dry_run=False)
            print(f"  Updated: MODULE decl, {n} USE refs, file {'renamed' if renamed else 'skipped'}")
        print()

    print(f"Total: {len(candidates)} rename + {len(secondary)} secondary")


if __name__ == "__main__":
    main()
