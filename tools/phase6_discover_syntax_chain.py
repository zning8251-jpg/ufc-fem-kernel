#!/usr/bin/env python3
"""Discover missing Fortran modules for Phase6 syntax/link chains via gfortran -c."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

_MISSING_MOD_RE = re.compile(
    r"Can't open module file '([^']+)\.mod'",
    re.IGNORECASE,
)
_MODULE_FILE_RE = re.compile(r"^\s*MODULE\s+(\w+)", re.IGNORECASE | re.MULTILINE)


def _load_chains(harness_root: Path) -> dict:
    p = harness_root / "phase6_syntax_chains.json"
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


def _resolve_src(ufc_root: Path, core: Path, rel: str) -> Path | None:
    for base in (ufc_root, core):
        p = (base / rel).resolve()
        if p.is_file():
            return p
    return None


def _mod_to_stem(mod_name: str) -> str:
    return mod_name.lower().replace("__", "_")


def _find_source_for_module(core: Path, mod_name: str, cache: dict[str, str | None]) -> str | None:
    key = mod_name.lower()
    if key in cache:
        return cache[key]
    stem = _mod_to_stem(mod_name)
    candidates: list[Path] = []
    for pat in (f"{stem}.f90", f"*{stem}*.f90", f"*{mod_name}*.f90"):
        candidates.extend(core.rglob(pat))
    for path in sorted(candidates, key=lambda p: len(str(p))):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in _MODULE_FILE_RE.finditer(text):
            if m.group(1).lower() == key:
                rel = path.relative_to(core).as_posix()
                cache[key] = rel
                return rel
    cache[key] = None
    return None


def _fortran_std(flag: str) -> str:
    return flag if flag in ("f2003", "f2008") else "f2003"


def _compile_unit(src: Path, jdir: str, dry_run: bool, std: str = "f2003") -> tuple[int, str]:
    cmd = ["gfortran", f"-std={_fortran_std(std)}", "-c", f"-J{jdir}", f"-I{jdir}", str(src)]
    print("[phase6-discover]", " ".join(cmd))
    if dry_run:
        return 0, ""
    proc = subprocess.run(cmd, capture_output=True, text=True)
    out = (proc.stdout or "") + (proc.stderr or "")
    if out:
        print(out, end="")
    return proc.returncode, out


def _missing_mods(text: str) -> list[str]:
    return [m.replace(".mod", "").replace(".MOD", "") for m in _MISSING_MOD_RE.findall(text)]


def _ensure_module(
    core: Path,
    jdir: str,
    mod_name: str,
    compile_list: list[str],
    mod_cache: dict[str, str | None],
    discovered: list[str],
    dry_run: bool,
    stack: set[str],
    std: str = "f2003",
) -> int:
    if mod_name.lower() in stack:
        return 1
    stack.add(mod_name.lower())
    rel_src = _find_source_for_module(core, mod_name, mod_cache)
    if rel_src is None:
        print(f"[phase6-discover] no source for module {mod_name}", file=sys.stderr)
        return 1
    if rel_src in compile_list:
        return 0
    compile_list.append(rel_src)
    discovered.append(rel_src)
    src_path = core / rel_src
    rc, out = _compile_unit(src_path, jdir, dry_run, std)
    if rc == 0:
        print(f"[phase6-discover] +compile {rel_src}  (module {mod_name})")
        return 0
    for dep in _missing_mods(out):
        rc2 = _ensure_module(core, jdir, dep, compile_list, mod_cache, discovered, dry_run, stack, std)
        if rc2 != 0:
            return rc2
    rc, out2 = _compile_unit(src_path, jdir, dry_run, std)
    if rc == 0:
        print(f"[phase6-discover] +compile {rel_src}  (module {mod_name})")
        return 0
    if _missing_mods(out2):
        for dep in _missing_mods(out2):
            rc2 = _ensure_module(core, jdir, dep, compile_list, mod_cache, discovered, dry_run, stack, std)
            if rc2 != 0:
                return rc2
        rc, _ = _compile_unit(src_path, jdir, dry_run, std)
    return rc


def discover_profile(
    ufc_root: Path,
    harness_root: Path,
    profile: str,
    *,
    max_rounds: int = 80,
    dry_run: bool = False,
    emit_json: bool = False,
    fortran_std: str = "f2003",
) -> int:
    data = _load_chains(harness_root)
    prof = data.get("profiles", {}).get(profile)
    if prof is None:
        print(f"[phase6-discover] unknown profile: {profile}", file=sys.stderr)
        return 2

    core = ufc_root / "ufc_core"
    moddir = ufc_root / "build" / f"_discover_{profile.replace('/', '_')}"
    if not dry_run:
        moddir.mkdir(parents=True, exist_ok=True)
    jdir = str(moddir)

    std = prof.get("fortran_std", fortran_std)
    compile_list = _expand_groups(data, list(prof.get("compile", ["l1_base"])))
    syntax_list = _expand_groups(data, list(prof.get("syntax_only", [])))
    mod_cache: dict[str, str | None] = {}
    discovered: list[str] = []

    for rel in compile_list:
        src = _resolve_src(ufc_root, core, rel)
        if src is None:
            print(f"[phase6-discover] skip missing: {rel}", file=sys.stderr)
            continue
        rc, _ = _compile_unit(src, jdir, dry_run, std)
        if rc != 0:
            print(f"[phase6-discover] compile failed for {rel}", file=sys.stderr)
            return rc

    targets = syntax_list or compile_list[-1:]
    for rel in targets:
        src = _resolve_src(ufc_root, core, rel)
        if src is None:
            print(f"[phase6-discover] missing target: {rel}", file=sys.stderr)
            return 1

        for round_i in range(max_rounds):
            cmd = ["gfortran", f"-std={_fortran_std(std)}", "-fsyntax-only", f"-J{jdir}", f"-I{jdir}", str(src)]
            print("[phase6-discover]", " ".join(cmd))
            if dry_run:
                return 0
            proc = subprocess.run(cmd, capture_output=True, text=True)
            out = (proc.stdout or "") + (proc.stderr or "")
            if out:
                print(out, end="")
            if proc.returncode == 0:
                print(f"[phase6-discover] OK profile={profile} target={rel} rounds={round_i}")
                if emit_json and discovered:
                    print(json.dumps({"discovered_compile": discovered}, indent=2))
                return 0

            missing = _missing_mods(out)
            if not missing:
                print(f"[phase6-discover] failed without missing mod (round {round_i})", file=sys.stderr)
                return proc.returncode

            added = False
            for mod_name in missing:
                before = len(compile_list)
                rc = _ensure_module(
                    core, jdir, mod_name, compile_list, mod_cache, discovered, dry_run, set(), std
                )
                if rc != 0:
                    return rc
                if len(compile_list) > before:
                    added = True

            if not added:
                print("[phase6-discover] no new units to add", file=sys.stderr)
                return proc.returncode

    print("[phase6-discover] max rounds exceeded", file=sys.stderr)
    return 1


def discover_target(
    ufc_root: Path,
    target_rel: str,
    *,
    max_rounds: int = 80,
    dry_run: bool = False,
    emit_json: bool = False,
    fortran_std: str = "f2008",
) -> int:
    core = ufc_root / "ufc_core"
    moddir = ufc_root / "build" / "_discover_target"
    if not dry_run:
        moddir.mkdir(parents=True, exist_ok=True)
    jdir = str(moddir)

    base_compile = [
        "L1_IF/Error/IF_Err_Def.f90",
        "L1_IF/Error/IF_Err_Brg.f90",
        "L1_IF/Precision/IF_Prec_Core.f90",
        "L1_IF/Memory/IF_Mem_Mgr.f90",
        "L1_IF/Memory/IF_Mem_Algo.f90",
    ]
    compile_list: list[str] = list(base_compile)
    mod_cache: dict[str, str | None] = {}
    discovered: list[str] = []

    src = _resolve_src(ufc_root, core, target_rel)
    if src is None:
        print(f"[phase6-discover] missing target: {target_rel}", file=sys.stderr)
        return 1

    for rel in compile_list:
        s = core / rel
        if s.is_file():
            rc, _ = _compile_unit(s, jdir, dry_run, fortran_std)
            if rc != 0:
                return rc

    for round_i in range(max_rounds):
        cmd = ["gfortran", f"-std={_fortran_std(fortran_std)}", "-fsyntax-only", f"-J{jdir}", f"-I{jdir}", str(src)]
        print("[phase6-discover]", " ".join(cmd))
        if dry_run:
            return 0
        proc = subprocess.run(cmd, capture_output=True, text=True)
        out = (proc.stdout or "") + (proc.stderr or "")
        if out:
            print(out, end="")
        if proc.returncode == 0:
            print(f"[phase6-discover] OK target={target_rel} rounds={round_i}")
            if emit_json:
                print(json.dumps({"discovered_compile": discovered}, indent=2))
            return 0

        missing = _missing_mods(out)
        if not missing:
            return proc.returncode

        added = False
        for mod_name in missing:
            before = len(compile_list)
            rc = _ensure_module(
                core, jdir, mod_name, compile_list, mod_cache, discovered, dry_run, set(), fortran_std
            )
            if rc != 0:
                return rc
            if len(compile_list) > before:
                added = True

        if not added:
            return proc.returncode

    return 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", default="phase6-track13-md-def")
    ap.add_argument("--target", help="Relative path under ufc_core or UFC root")
    ap.add_argument("--emit-json", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--max-rounds", type=int, default=80)
    ap.add_argument("--std", default="", help="f2003 or f2008 (default f2008 for --target, else from profile)")
    ns = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    harness_root = root / "ufc_harness"
    std = ns.std or ""
    if ns.target:
        return discover_target(
            root,
            ns.target,
            max_rounds=ns.max_rounds,
            dry_run=ns.dry_run,
            emit_json=ns.emit_json,
            fortran_std=std or "f2008",
        )
    return discover_profile(
        root,
        harness_root,
        ns.profile,
        max_rounds=ns.max_rounds,
        dry_run=ns.dry_run,
        emit_json=ns.emit_json,
        fortran_std=std or "f2003",
    )


if __name__ == "__main__":
    raise SystemExit(main())
