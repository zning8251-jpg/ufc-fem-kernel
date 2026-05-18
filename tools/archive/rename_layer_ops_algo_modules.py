#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""
Batch-rename *_Ops.f90 / *_Algo.f90 under ufc_core/<LAYER>/ to drop the role
suffix, and rename MODULE ... / END MODULE ... accordingly.

Then replace USE <old_mod> across selected UFC trees (Fortran + CMake + docs).

Usage:
  python rename_layer_ops_algo_modules.py --layer L1_IF --dry-run
  python rename_layer_ops_algo_modules.py --layer L1_IF
  python rename_layer_ops_algo_modules.py --all-layers

Order L1_IF .. L6_AP when using --all-layers.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


LAYERS = ("L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP")

# Paths under repo root to rewrite references (exclude build artifacts).
# Keep scans under code + build scripts; generated DomainProcedureRegistry is huge — regenerate after renames if needed.
REF_REL_DIRS = (
    "UFC/ufc_core",
    "UFC/ufc_harness",
    "UFC/tests",
    "UFC/tools",
)

TEXT_SUFFIXES = (".f90", ".F90", ".cmake", ".txt", ".md", ".json", ".yml", ".yaml")


def collect_renames(layer_dir: Path) -> list[tuple[Path, str, str, Path]]:
    """Return list of (old_path, old_mod, new_mod, new_path)."""
    out: list[tuple[Path, str, str, Path]] = []
    for p in sorted(layer_dir.rglob("*.f90")):
        name = p.name
        if name.endswith("_Ops.f90"):
            stem = name[: -len("_Ops.f90")]
            new_name = stem + ".f90"
            old_mod = stem + "_Ops"
        elif name.endswith("_Algo.f90"):
            stem = name[: -len("_Algo.f90")]
            new_name = stem + ".f90"
            old_mod = stem + "_Algo"
        else:
            continue
        new_mod = stem
        new_path = p.with_name(new_name)
        out.append((p, old_mod, new_mod, new_path))
    return out


def validate_renames(renames: list[tuple[Path, str, str, Path]]) -> list[str]:
    errors: list[str] = []
    target_map: dict[Path, Path] = {}
    for old, _old_m, _new_m, new in renames:
        if new in target_map and target_map[new] != old:
            errors.append(f"duplicate target {new}: {target_map[new]} and {old}")
        target_map[new] = old
        if new.exists() and new.resolve() != old.resolve():
            errors.append(f"target exists (not source): {new} blocks {old}")
    return errors


def patch_module_decl(text: str, old_mod: str, new_mod: str) -> str:
    # MODULE name / END MODULE name (case-insensitive Fortran, keep original case for new_mod)
    t = re.sub(
        rf"(?im)^(\s*MODULE\s+){re.escape(old_mod)}\s*$",
        rf"\g<1>{new_mod}",
        text,
        flags=re.MULTILINE,
    )
    t = re.sub(
        rf"(?im)^(\s*END\s+MODULE\s+){re.escape(old_mod)}\s*$",
        rf"\g<1>{new_mod}",
        t,
        flags=re.MULTILINE,
    )
    return t


def rewrite_file_content(path: Path, old_mod: str, new_mod: str) -> None:
    raw = path.read_text(encoding="utf-8", errors="replace")
    raw2 = patch_module_decl(raw, old_mod, new_mod)
    if raw2 != raw:
        path.write_text(raw2, encoding="utf-8", newline="\n")


def replace_refs_in_tree(
    repo_root: Path,
    pairs: list[tuple[str, str]],
    dry_run: bool,
) -> int:
    """Replace old_mod with new_mod as whole identifiers. Returns files touched."""
    # Longest old_mod first to avoid rare prefix collisions
    pairs_sorted = sorted(pairs, key=lambda x: len(x[0]), reverse=True)
    touched = 0
    for rel in REF_REL_DIRS:
        base = repo_root / rel
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file():
                continue
            if "build" in path.parts or "build_meshops" in path.parts:
                continue
            if path.suffix.lower() not in {s.lower() for s in TEXT_SUFFIXES}:
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            orig = text
            for old_m, new_m in pairs_sorted:
                # Word boundary: Fortran identifiers
                text = re.sub(rf"\b{re.escape(old_m)}\b", new_m, text)
            if text != orig:
                touched += 1
                if not dry_run:
                    path.write_text(text, encoding="utf-8", newline="\n")
    return touched


def update_cmake_explicit_algo_paths(repo_root: Path, pairs: list[tuple[str, str]], dry_run: bool) -> None:
    """Fix CMake FILTER lines that embed full *_Algo.f90 paths."""
    cm = repo_root / "UFC" / "ufc_core" / "CMakeLists.txt"
    if not cm.exists():
        return
    text = cm.read_text(encoding="utf-8", errors="replace")
    orig = text
    for old_m, new_m in pairs:
        old_file = old_m + ".f90"
        new_file = new_m + ".f90"
        text = text.replace(old_file, new_file)
    if text != orig and not dry_run:
        cm.write_text(text, encoding="utf-8", newline="\n")


def run_layer(ufc_core: Path, repo_root: Path, layer: str, dry_run: bool) -> int:
    layer_dir = ufc_core / layer
    if not layer_dir.is_dir():
        print(f"skip missing {layer_dir}", file=sys.stderr)
        return 1
    renames = collect_renames(layer_dir)
    if not renames:
        print(f"{layer}: no *_Ops.f90 or *_Algo.f90", flush=True)
        return 0
    err = validate_renames(renames)
    if err:
        for e in err:
            print(e, file=sys.stderr)
        return 2
    pairs = [(o[1], o[2]) for o in renames]  # (old_mod, new_mod)
    print(f"{layer}: {len(renames)} files to rename", flush=True)
    if dry_run:
        for old, om, nm, new in renames[:12]:
            print(f"  DRY {old.name} -> {new.name}  ({om} -> {nm})", flush=True)
        if len(renames) > 12:
            print(f"  ... and {len(renames) - 12} more", flush=True)
        return 0
    # 1) Write new files with patched MODULE lines, remove old
    for old_path, old_mod, new_mod, new_path in renames:
        body = old_path.read_text(encoding="utf-8", errors="replace")
        body = patch_module_decl(body, old_mod, new_mod)
        new_path.write_text(body, encoding="utf-8", newline="\n")
        old_path.unlink()
    # 2) Global USE / references
    n = replace_refs_in_tree(repo_root, pairs, dry_run=False)
    print(f"{layer}: reference rewrite touched {n} files under UFC/", flush=True)
    update_cmake_explicit_algo_paths(repo_root, pairs, dry_run=False)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--layer", choices=LAYERS, help="single layer under ufc_core")
    ap.add_argument("--all-layers", action="store_true", help="process L1_IF .. L6_AP in order")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="repo root (parent of UFC/). Default: parent of tools/",
    )
    args = ap.parse_args()
    tools_dir = Path(__file__).resolve().parent
    repo_root = args.repo_root or tools_dir.parent.parent
    ufc_core = repo_root / "UFC" / "ufc_core"
    if not ufc_core.is_dir():
        print(f"ufc_core not found: {ufc_core}", file=sys.stderr)
        return 1
    if args.all_layers:
        code = 0
        for layer in LAYERS:
            r = run_layer(ufc_core, repo_root, layer, args.dry_run)
            if r > code:
                code = r
        return code
    if args.layer:
        return run_layer(ufc_core, repo_root, args.layer, args.dry_run)
    ap.print_help()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
