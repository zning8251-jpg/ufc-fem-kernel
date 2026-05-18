#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Thin wrapper: L4_PH / Element-only ``*_Algo`` → ``*_Ops`` migration.

Implements the same rules as ``migrate_ufc_module_algo_to_ops.py`` but fixes
the scan root to ``ufc_core/L4_PH/Element/``.

  python UFC/tools/migrate_l4_ph_element_algo_to_ops.py --dry-run
  python UFC/tools/migrate_l4_ph_element_algo_to_ops.py --apply

For other domain buckets use the general driver, e.g.:

  python UFC/tools/migrate_ufc_module_algo_to_ops.py --under L5_RT/Assembly --apply
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from migrate_ufc_module_algo_to_ops import (
    UFC_CORE,
    UFC_ROOT,
    default_global_patch_roots,
    run_migration,
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if args.apply and args.dry_run:
        print("Use only one of --apply or --dry-run", file=sys.stderr)
        return 2
    repo_root = UFC_ROOT.parent
    return run_migration(
        scan_dirs=[UFC_CORE / "L4_PH" / "Element"],
        apply=bool(args.apply),
        global_roots=default_global_patch_roots(),
        repo_root=repo_root,
        stem_prefix="PH_",
    )


if __name__ == "__main__":
    raise SystemExit(main())
