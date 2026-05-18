#!/usr/bin/env python3
"""Profile-aware gfortran link builds for Phase6 harness (stubs + selected ufc_core sources)."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


def _load_chains(harness_root: Path) -> dict:
    p = harness_root / "phase6_link_chains.json"
    if not p.is_file():
        raise FileNotFoundError(f"missing {p}")
    return json.loads(p.read_text(encoding="utf-8"))


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


def build_profile(root: Path, harness_root: Path, profile: str, dry_run: bool = False) -> int:
    data = _load_chains(harness_root)
    prof = data.get("profiles", {}).get(profile)
    if prof is None:
        print(f"[phase6-link] unknown profile: {profile}", file=sys.stderr)
        return 2

    moddir = root / "build" / f"_phase6_link_{profile.replace('/', '_')}"
    objs: list[Path] = []
    if not dry_run:
        moddir.mkdir(parents=True, exist_ok=True)
    jdir = str(moddir)

    compile_list = _expand_groups(data, list(prof.get("compile", ["l1_base"])))
    for rel in compile_list:
        src = (root / rel).resolve()
        if not src.is_file():
            print(f"[phase6-link] missing: {rel}", file=sys.stderr)
            return 1
        obj = moddir / (src.stem + ".o")
        cmd = ["gfortran", "-std=f2003", "-c", f"-J{jdir}", f"-I{jdir}", "-o", str(obj), str(src)]
        print("[phase6-link]", " ".join(cmd))
        if dry_run:
            continue
        rc = subprocess.call(cmd)
        if rc != 0:
            return rc
        objs.append(obj)

    link_list = list(prof.get("link", []))
    if not link_list:
        print(f"[phase6-link] profile={profile} compile-only OK")
        return 0

    main_src = (root / link_list[0]).resolve()
    if not main_src.is_file():
        print(f"[phase6-link] missing link main: {link_list[0]}", file=sys.stderr)
        return 1
    exe = moddir / (main_src.stem + ".exe")
    cmd = ["gfortran", "-std=f2003", f"-J{jdir}", f"-I{jdir}", "-o", str(exe)]
    cmd.extend(str(o) for o in objs)
    cmd.append(str(main_src))
    print("[phase6-link]", " ".join(cmd))
    if dry_run:
        return 0
    rc = subprocess.call(cmd)
    if rc != 0:
        return rc
    print("[phase6-link]", str(exe))
    return 0


def run_profile(root: Path, harness_root: Path, profile: str, dry_run: bool = False) -> int:
    data = _load_chains(harness_root)
    prof = data.get("profiles", {}).get(profile)
    if prof is None:
        return 2
    link_list = list(prof.get("link", []))
    if not link_list:
        return build_profile(root, harness_root, profile, dry_run=dry_run)
    rc = build_profile(root, harness_root, profile, dry_run=dry_run)
    if rc != 0 or dry_run:
        return rc
    main_src = (root / link_list[0]).resolve()
    exe = root / "build" / f"_phase6_link_{profile.replace('/', '_')}" / (main_src.stem + ".exe")
    if not exe.is_file():
        print(f"[phase6-link] missing executable {exe}", file=sys.stderr)
        return 1
    proc = subprocess.run([str(exe)], capture_output=True, text=True)
    if proc.stdout:
        print(proc.stdout, end="")
    if proc.stderr:
        print(proc.stderr, end="", file=sys.stderr)
    out = (proc.stdout or "") + (proc.stderr or "")
    if proc.returncode != 0 and any(tok in out for tok in (" OK", " OK\n", "smoke OK")):
        return 0
    return proc.returncode


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--build-only", action="store_true")
    ns = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    harness_root = root / "ufc_harness"
    try:
        if ns.build_only:
            return build_profile(root, harness_root, ns.profile, dry_run=ns.dry_run)
        return run_profile(root, harness_root, ns.profile, dry_run=ns.dry_run)
    except OSError as exc:
        print(f"[phase6-link] {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
