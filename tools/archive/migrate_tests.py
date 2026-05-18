#!/usr/bin/env python3
"""
Migrate test files from ufc_core/*/Tests/ to UFC/tests/{Layer}/.
Delete empty Tests/ directories afterward.

Usage:
  python migrate_tests.py --dry-run
  python migrate_tests.py --execute
"""
import os
import shutil
import argparse
from pathlib import Path

UFC_ROOT = Path(r"d:\TEST7\UFC")
UFC_CORE = UFC_ROOT / "ufc_core"
TESTS_DST = UFC_ROOT / "tests"
EXCLUDE_DIRS = {"ExternalLibs"}


def find_test_dirs():
    """Find all Tests/ directories under ufc_core (excluding ExternalLibs)."""
    test_dirs = []
    for d in sorted(UFC_CORE.rglob("Tests")):
        if not d.is_dir():
            continue
        if any(ex in d.parts for ex in EXCLUDE_DIRS):
            continue
        test_dirs.append(d)
    return test_dirs


def get_layer(test_dir):
    """Extract layer name from path like ufc_core/L3_MD/Material/Tests."""
    rel = test_dir.relative_to(UFC_CORE)
    parts = rel.parts
    if len(parts) >= 2:
        return parts[0]
    return "ufc_core"


def main():
    parser = argparse.ArgumentParser(description="Migrate UFC test files")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()

    dry_run = not args.execute
    print(f"Mode: {'DRY-RUN' if dry_run else 'EXECUTE'}")
    print()

    test_dirs = find_test_dirs()
    print(f"Found {len(test_dirs)} Tests/ directories in ufc_core")
    print()

    moved = 0
    for td in test_dirs:
        layer = get_layer(td)
        dst_dir = TESTS_DST / layer

        for f in sorted(td.glob("*.f90")):
            dst_file = dst_dir / f.name
            print(f"  {f.relative_to(UFC_CORE)} -> tests/{layer}/{f.name}")

            if not dry_run:
                dst_dir.mkdir(parents=True, exist_ok=True)
                if dst_file.exists():
                    print(f"    WARNING: target exists, skipping")
                    continue
                shutil.move(str(f), str(dst_file))
            moved += 1

    print(f"\nTotal files to move: {moved}")

    if not dry_run:
        print("\nCleaning empty Tests/ directories...")
        removed = 0
        for td in sorted(test_dirs, reverse=True):
            remaining = list(td.iterdir())
            if not remaining:
                td.rmdir()
                removed += 1
                print(f"  Removed: {td.relative_to(UFC_CORE)}")
            else:
                print(f"  Kept (non-empty): {td.relative_to(UFC_CORE)}")
        print(f"Removed {removed} empty directories")


if __name__ == "__main__":
    main()
