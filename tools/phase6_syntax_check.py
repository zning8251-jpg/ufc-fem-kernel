#!/usr/bin/env python3
"""Phase6 profile-aware gfortran syntax chains (no full-tree link)."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def _load_chains(harness_root: Path) -> dict:
    p = harness_root / "phase6_syntax_chains.json"
    if not p.is_file():
        raise FileNotFoundError(f"missing {p}")
    return json.loads(p.read_text(encoding="utf-8"))


def _fortran_std(flag: str) -> str:
    return flag if flag in ("f2003", "f2008") else "f2003"


def _expand_groups(data: dict, names: list[str]) -> list[str]:
    out: list[str] = []
    for name in names:
        if name in data:
            out.extend(data[name])
        else:
            out.append(name)
    seen: set[str] = set()
    ordered: list[str] = []
    for rel in out:
        if rel not in seen:
            seen.add(rel)
            ordered.append(rel)
    return ordered


def run_profile(ufc_root: Path, harness_root: Path, profile: str, dry_run: bool = False) -> int:
    data = _load_chains(harness_root)
    prof = data.get("profiles", {}).get(profile)
    if prof is None:
        prof = data.get("profiles", {}).get("baseline")
    if prof is None:
        print(f"[phase6-syntax] unknown profile: {profile}", file=sys.stderr)
        return 2

    core = ufc_root / "ufc_core"
    moddir = ufc_root / "build" / f"_harness_syntax_{profile.replace('/', '_')}"
    if not dry_run:
        moddir.mkdir(parents=True, exist_ok=True)
    jdir = str(moddir)

    std = _fortran_std(str(prof.get("fortran_std", "f2003")))
    compile_list = _expand_groups(data, list(prof.get("compile", ["l1_base"])))
    syntax_list = _expand_groups(data, list(prof.get("syntax_only", [])))
    standalone_list = list(prof.get("standalone", []))

    for rel in compile_list:
        src = (ufc_root / rel).resolve()
        if not src.is_file():
            src = (core / rel).resolve()
        if not src.is_file():
            print(f"[phase6-syntax] skip missing compile unit: {rel}", file=sys.stderr)
            continue
        cmd = ["gfortran", f"-std={std}", "-c", f"-J{jdir}", f"-I{jdir}", str(src)]
        print("[phase6-syntax]", " ".join(cmd))
        if dry_run:
            continue
        rc = subprocess.call(cmd)
        if rc != 0:
            return rc

    for rel in syntax_list:
        src = (ufc_root / rel).resolve()
        if not src.is_file():
            src = (core / rel).resolve()
        if not src.is_file():
            print(f"[phase6-syntax] missing syntax target: {rel}", file=sys.stderr)
            return 1
        cmd = ["gfortran", f"-std={std}", "-fsyntax-only", f"-J{jdir}", f"-I{jdir}", str(src)]
        print("[phase6-syntax]", " ".join(cmd))
        if dry_run:
            continue
        rc = subprocess.call(cmd)
        if rc != 0:
            return rc

    for rel in standalone_list:
        src = (ufc_root / rel).resolve()
        if not src.is_file():
            print(f"[phase6-syntax] missing standalone target: {rel}", file=sys.stderr)
            return 1
        cmd = ["gfortran", "-std=f2003", "-fsyntax-only", str(src)]
        print("[phase6-syntax]", " ".join(cmd))
        if dry_run:
            continue
        rc = subprocess.call(cmd)
        if rc != 0:
            return rc

    print(f"[phase6-syntax] profile={profile} OK")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", default="phase6-all")
    ap.add_argument("--dry-run", action="store_true")
    ns = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    harness_root = root / "ufc_harness"
    try:
        return run_profile(root, harness_root, ns.profile, dry_run=ns.dry_run)
    except OSError as exc:
        print(f"[phase6-syntax] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
