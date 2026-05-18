#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Domain-scoped rename: legacy MODULE ``{IF|NM|MD|PH|RT|AP}_*_Algo[NN].f90``
→ ``…_Ops[NN].f90``, then patch ``USE`` / ``MODULE`` / ``END MODULE`` / quoted
module string literals under configurable roots.

**Does not** rename ``TYPE(…_Algo)`` four-kind identifiers — only module-oriented
patterns (same rules as the L4_PH/Element one-off migration).

Typical usage (from repo root ``d:/TEST7``):

  # Plan only
  python UFC/tools/migrate_ufc_module_algo_to_ops.py \\
      --under L4_PH/LoadBC --under L4_PH/Field --dry-run

  # Execute one domain bucket (repeat per PR)
  python UFC/tools/migrate_ufc_module_algo_to_ops.py --under L5_RT/Assembly --apply

  # Mirror of the Element-only driver (equivalent to multiple --under)
  python UFC/tools/migrate_l4_ph_element_algo_to_ops.py --apply

``--under`` paths are relative to ``UFC/ufc_core/`` unless absolute.

After each batch: ``domain_procedure_registry_scan.py`` → ``align.py`` (and build).
"""
from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

UFC_ROOT = Path(__file__).resolve().parents[1]
UFC_CORE = UFC_ROOT / "ufc_core"

# Six-layer Fortran module prefixes (compilation-unit stems).
_LAYER_STEM_PREFIX_RE = re.compile(r"^(IF|NM|MD|PH|RT|AP)_.*_Algo(\d*)$")


def stem_algo_to_ops(stem: str, *, stem_prefix: str | None) -> str | None:
    """
    IF_Foo_Algo / MD_Foo_Algo1 / PH_GeostaticAlgo_Algo -> …_Ops / …_Ops1 / …_Ops.
    Returns None if stem is not a targeted legacy MODULE file stem.

    stem_prefix:
      If set (e.g. ``\"PH_\"``), only stems starting with that literal are
      migrated — avoids picking up odd placements such as ``MD_*`` under
      ``L4_PH/Element/``.
    """
    if stem_prefix is not None and not stem.startswith(stem_prefix):
        return None
    if not _LAYER_STEM_PREFIX_RE.match(stem):
        return None
    i = stem.rfind("_Algo")
    if i < 0:
        return None
    suffix = stem[i + len("_Algo") :]
    if suffix != "" and not suffix.isdigit():
        return None
    return stem[:i] + "_Ops" + suffix


def rename_source(old: Path, new: Path, *, repo_root: Path) -> None:
    new.parent.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(
        ["git", "mv", str(old), str(new)],
        cwd=repo_root,
        capture_output=True,
        text=True,
    )
    if r.returncode == 0:
        return
    shutil.move(str(old), str(new))


def patch_module_file(text: str, old_mod: str, new_mod: str) -> str:
    t = text
    t = re.sub(
        rf"(?im)^(\s*MODULE\s+){re.escape(old_mod)}(\s*($|[!]))",
        rf"\g<1>{new_mod}\g<2>",
        t,
    )
    t = re.sub(
        rf"(?im)^(\s*END\s+MODULE\s+){re.escape(old_mod)}(\s*($|[!]))",
        rf"\g<1>{new_mod}\g<2>",
        t,
    )
    t = re.sub(
        rf"^(!\s*Module:\s*){re.escape(old_mod)}\s*$",
        rf"\g<1>{new_mod}",
        t,
        flags=re.MULTILINE | re.IGNORECASE,
    )
    return t


def patch_global_text(text: str, pairs: list[tuple[str, str]]) -> str:
    pairs = sorted(pairs, key=lambda p: len(p[0]), reverse=True)
    t = text
    for old, new in pairs:
        t = re.sub(
            rf"(?im)^(\s*USE\s+){re.escape(old)}(\s*($|[,!]))",
            rf"\g<1>{new}\g<2>",
            t,
        )
        t = re.sub(
            rf"(?im)^(\s*MODULE\s+){re.escape(old)}(\s*($|[!]))",
            rf"\g<1>{new}\g<2>",
            t,
        )
        t = re.sub(
            rf"(?im)^(\s*END\s+MODULE\s+){re.escape(old)}(\s*($|[!]))",
            rf"\g<1>{new}\g<2>",
            t,
        )
        t = t.replace(f'"{old}"', f'"{new}"')
        t = t.replace(f"'{old}'", f"'{new}'")
    return t


def resolve_under_paths(raw: list[str]) -> list[Path]:
    out: list[Path] = []
    for s in raw:
        p = Path(s)
        if not p.is_absolute():
            p = UFC_CORE / p
        p = p.resolve()
        if not p.exists():
            print("Missing path:", p, file=sys.stderr)
            raise SystemExit(2)
        out.append(p)
    return out


def discover_renames(
    scan_dirs: list[Path], *, stem_prefix: str | None
) -> list[tuple[Path, Path, str, str]]:
    out: list[tuple[Path, Path, str, str]] = []
    seen: set[Path] = set()
    for d in scan_dirs:
        for fp in sorted(d.rglob("*.f90")):
            if fp in seen:
                continue
            seen.add(fp)
            if "ExternalLibs" in fp.parts:
                continue
            stem = fp.stem
            new_stem = stem_algo_to_ops(stem, stem_prefix=stem_prefix)
            if new_stem is None:
                continue
            new_path = fp.with_name(new_stem + ".f90")
            if new_path == fp:
                continue
            out.append((fp, new_path, stem, new_stem))
    return out


def default_global_patch_roots() -> list[Path]:
    roots = [UFC_CORE, UFC_ROOT / "ufc_harness"]
    return [p for p in roots if p.is_dir()]


def run_migration(
    *,
    scan_dirs: list[Path],
    apply: bool,
    global_roots: list[Path],
    repo_root: Path,
    stem_prefix: str | None = None,
) -> int:
    renames = discover_renames(scan_dirs, stem_prefix=stem_prefix)
    if not renames:
        print("No matching *_Algo*.f90 under:", *[str(d) for d in scan_dirs], sep="\n  ")
        return 0

    pairs = [(a[2], a[3]) for a in renames]

    print(f"Found {len(renames)} compilation units to rename.")
    for old_p, new_p, _, _ in renames[:8]:
        try:
            rel_o = old_p.relative_to(UFC_CORE)
        except ValueError:
            rel_o = old_p
        try:
            rel_n = new_p.relative_to(UFC_CORE)
        except ValueError:
            rel_n = new_p
        print(f"  {rel_o} -> {rel_n}")
    if len(renames) > 8:
        print(f"  ... and {len(renames) - 8} more")

    if not apply:
        print("Dry run: no changes. Pass --apply to execute.")
        return 0

    for old_p, new_p, _, _ in renames:
        if new_p.exists():
            print("Refusing overwrite existing:", new_p, file=sys.stderr)
            return 1
        rename_source(old_p, new_p, repo_root=repo_root)

    for _, new_p, old_m, new_m in renames:
        text = new_p.read_text(encoding="utf-8", errors="replace")
        text = patch_module_file(text, old_m, new_m)
        new_p.write_text(text, encoding="utf-8", newline="\n")

    excl = {"ExternalLibs"}
    for root in global_roots:
        if not root.is_dir():
            continue
        for fp in sorted(root.rglob("*.f90")):
            if any(seg in excl for seg in fp.parts):
                continue
            text = fp.read_text(encoding="utf-8", errors="replace")
            new_text = patch_global_text(text, pairs)
            if new_text != text:
                fp.write_text(new_text, encoding="utf-8", newline="\n")

    print("Done: renames + global USE/MODULE/string patch.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Rename *_Algo Fortran MODULE files to *_Ops within given ufc_core subtrees."
    )
    ap.add_argument(
        "--under",
        action="append",
        default=[],
        metavar="REL_OR_ABS",
        help="Subdir under UFC/ufc_core/ to scan (repeatable). Example: L5_RT/Assembly",
    )
    ap.add_argument(
        "--apply",
        action="store_true",
        help="Perform renames and patches (default is dry-run listing only)",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print planned renames (default if --apply omitted)",
    )
    ap.add_argument(
        "--stem-prefix",
        default=None,
        metavar="PREFIX",
        help="Only rename stems starting with this prefix (e.g. PH_ under L4_PH).",
    )
    args = ap.parse_args()
    if args.apply and args.dry_run:
        print("Use only one of --apply or --dry-run", file=sys.stderr)
        return 2

    if not args.under:
        print("Provide at least one --under path (relative to UFC/ufc_core/).", file=sys.stderr)
        return 2

    scan_dirs = resolve_under_paths(args.under)
    repo_root = UFC_ROOT.parent
    return run_migration(
        scan_dirs=scan_dirs,
        apply=bool(args.apply),
        global_roots=default_global_patch_roots(),
        repo_root=repo_root,
        stem_prefix=args.stem_prefix,
    )


if __name__ == "__main__":
    raise SystemExit(main())
