#!/usr/bin/env python3
"""Compile and run Phase6 minimal Fortran acceptance programs (not full ufc_core link)."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str], cwd: Path | None = None) -> int:
    print("[phase6-fortran]", " ".join(cmd))
    return subprocess.call(cmd, cwd=str(cwd) if cwd else None)


def _link_profile(root: Path, profile: str, dry_run: bool) -> int:
    script = root / "tools" / "phase6_link_build.py"
    cmd = [sys.executable, str(script), "--profile", profile]
    if dry_run:
        cmd.append("--dry-run")
    return _run(cmd, cwd=root)


def run_matstate(root: Path, dry_run: bool, linked: bool) -> int:
    test = root / "tests" / "L3_MD" / "test_MD_MatState_snapshot.f90"
    if not test.is_file():
        print(f"[phase6-fortran] missing {test}", file=sys.stderr)
        return 1
    if linked:
        return _link_profile(root, "matstate_linked", dry_run)
    bdir = root / "build" / "_phase6_matstate"
    if not dry_run:
        bdir.mkdir(parents=True, exist_ok=True)
    exe = bdir / "test_MD_MatState_snapshot.exe"
    if dry_run:
        print(f"[phase6-fortran] would build {exe}")
        return 0
    rc = _run(["gfortran", "-std=f2003", "-o", str(exe), str(test)])
    if rc != 0:
        return rc
    return _run([str(exe)])


def run_arclen(root: Path, dry_run: bool, linked: bool) -> int:
    if linked:
        return _link_profile(root, "arclen_linked", dry_run)
    test = root / "tests" / "L5_RT" / "test_RT_NLSolver_ArcLen_min.f90"
    if not test.is_file():
        print(f"[phase6-fortran] missing {test}", file=sys.stderr)
        return 1
    bdir = root / "build" / "_phase6_arclen"
    if not dry_run:
        bdir.mkdir(parents=True, exist_ok=True)
    exe = bdir / "test_RT_NLSolver_ArcLen_min.exe"
    if dry_run:
        print(f"[phase6-fortran] would build {exe}")
        return 0
    rc = _run(["gfortran", "-std=f2003", "-o", str(exe), str(test)])
    if rc != 0:
        return rc
    return _run([str(exe)])


def run_rt_drv(root: Path, dry_run: bool) -> int:
    return _link_profile(root, "rt_drv", dry_run)


def run_rt_drv_prod(root: Path, dry_run: bool) -> int:
    """Compile-only closure for production RT_Step_Exec (WIP: expand phase6_link_chains rt_drv_prod)."""
    script = root / "tools" / "phase6_link_build.py"
    cmd = [sys.executable, str(script), "--profile", "rt_drv_prod", "--build-only"]
    if dry_run:
        cmd.append("--dry-run")
    return _run(cmd, cwd=root)


def run_fbar(root: Path, dry_run: bool) -> int:
    mod = root / "tests" / "HARNESS_Elem_FBar_Patch.f90"
    runner = root / "tests" / "HARNESS_Elem_FBar_Patch_Runner.f90"
    if not mod.is_file() or not runner.is_file():
        print("[phase6-fortran] missing F-bar harness sources", file=sys.stderr)
        return 1
    bdir = root / "build" / "_phase6_fbar"
    if not dry_run:
        bdir.mkdir(parents=True, exist_ok=True)
    exe = bdir / "HARNESS_Elem_FBar_Patch.exe"
    if dry_run:
        print(f"[phase6-fortran] would build {exe}")
        return 0
    rc = _run(["gfortran", "-std=f2003", "-c", "-o", str(bdir / "fbar_mod.o"), str(mod)])
    if rc != 0:
        return rc
    rc = _run(
        [
            "gfortran",
            "-std=f2003",
            "-o",
            str(exe),
            str(bdir / "fbar_mod.o"),
            str(runner),
        ]
    )
    if rc != 0:
        return rc
    return _run([str(exe)])


def run_l6_bridge(root: Path, dry_run: bool) -> int:
    return _link_profile(root, "l6_bridge", dry_run)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--test",
        required=True,
        choices=["matstate", "arclen", "fbar", "rt_drv", "rt_drv_prod", "l6_bridge"],
    )
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--linked",
        action="store_true",
        help="Use phase6_link_build profile (matstate/arclen)",
    )
    ns = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    if ns.test == "matstate":
        return run_matstate(root, ns.dry_run, linked=True)
    if ns.test == "arclen":
        return run_arclen(root, ns.dry_run, linked=True)
    if ns.test == "rt_drv":
        return run_rt_drv(root, ns.dry_run)
    if ns.test == "rt_drv_prod":
        return run_rt_drv_prod(root, ns.dry_run)
    if ns.test == "l6_bridge":
        return run_l6_bridge(root, ns.dry_run)
    return run_fbar(root, ns.dry_run)


if __name__ == "__main__":
    raise SystemExit(main())
