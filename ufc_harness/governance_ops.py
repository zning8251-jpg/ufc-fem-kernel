#!/usr/bin/env python3
"""
UFC 工程治理：变更包校验 + 纪律 manifest 提示（OpenSpec / Agent-Skills 自研等价）。

- change-package validate --change-id <id> [--strict]
- discipline verify [--touch-path REL ...] [--strict]
"""

from __future__ import annotations

import argparse
import fnmatch
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Set, Tuple

HARNESS_ROOT = Path(__file__).resolve().parent


def _ufc_root() -> Path:
    return HARNESS_ROOT.parent


def _changes_dir() -> Path:
    return _ufc_root() / "plan" / "changes"


def _manifest_path() -> Path:
    return _ufc_root() / "ufc_governance" / "triad" / "discipline" / "manifest.v1.json"


def _validate_spec_keywords(text: str) -> Tuple[bool, str]:
    t = text.lower()
    keys = ("when", "then", "must", "scenario")
    hits = sum(1 for k in keys if k in t)
    if hits >= 2:
        return True, f"spec keywords hit count={hits}"
    return False, "spec should include at least two of: WHEN, THEN, MUST, Scenario (case-insensitive)"


def cmd_change_package_validate(ns: argparse.Namespace) -> int:
    cid = (ns.change_id or "").strip()
    if not cid:
        print("[change-package] validate requires --change-id", file=sys.stderr)
        return 2
    root = _changes_dir() / cid
    strict = bool(ns.strict)
    errors: List[str] = []

    if not root.is_dir():
        msg = f"missing change directory: {root}"
        print(f"[change-package] ERROR: {msg}", file=sys.stderr)
        return 1 if strict else 0

    required_files = [
        root / "proposal.md",
        root / "design.md",
        root / "tasks.md",
    ]
    for p in required_files:
        if not p.is_file():
            errors.append(f"missing required file: {p.relative_to(_ufc_root())}")

    spec_files = list(root.glob("specs/**/*.md"))
    if not spec_files:
        errors.append("missing specs: expected at least one specs/**/*.md")
    else:
        for sf in spec_files:
            try:
                body = sf.read_text(encoding="utf-8")
            except OSError as e:
                errors.append(f"cannot read {sf}: {e}")
                continue
            ok, note = _validate_spec_keywords(body)
            if not ok:
                errors.append(f"{sf.relative_to(_ufc_root())}: {note}")

    for e in errors:
        print(f"[change-package] ERROR: {e}", file=sys.stderr)

    if errors:
        print(
            f"[change-package] validate {'FAIL' if strict else 'WARN'} change_id={cid} errors={len(errors)}",
            file=sys.stderr,
        )
        return 1 if strict else 0
    print(f"[change-package] validate OK change_id={cid}")
    return 0


def _load_manifest() -> Dict[str, Any]:
    p = _manifest_path()
    if not p.is_file():
        raise FileNotFoundError(str(p))
    with p.open(encoding="utf-8") as f:
        return json.load(f)


def _match_rules(rel_posix: str, rules: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    matched: List[Dict[str, Any]] = []
    rel_posix = rel_posix.replace("\\", "/").strip("/")
    for rule in rules:
        globs = rule.get("when_globs") or []
        for g in globs:
            gnorm = str(g).replace("\\", "/")
            if fnmatch.fnmatch(rel_posix, gnorm):
                matched.append(rule)
                break
    return matched


def cmd_discipline_verify(ns: argparse.Namespace) -> int:
    strict = bool(ns.strict)
    try:
        data = _load_manifest()
    except FileNotFoundError as e:
        print(f"[discipline] ERROR: {e}", file=sys.stderr)
        return 1 if strict else 0
    except json.JSONDecodeError as e:
        print(f"[discipline] ERROR: invalid JSON manifest: {e}", file=sys.stderr)
        return 1

    rules = data.get("rules") or []
    if not isinstance(rules, list):
        print("[discipline] ERROR: manifest.rules must be a list", file=sys.stderr)
        return 1 if strict else 0

    ufc = _ufc_root()
    paths = [str(p).strip() for p in (ns.touch_path or []) if str(p).strip()]
    if not paths:
        print("[discipline] No --touch-path: printing all rules (guidance only).\n")
        for rule in rules:
            rid = rule.get("id", "?")
            desc = rule.get("description", "")
            print(f"## rule:{rid} — {desc}")
            for hc in rule.get("harness_commands") or []:
                argv = hc.get("argv")
                if isinstance(argv, list):
                    line = "python UFC/ufc_harness/run_harness.py " + " ".join(str(a) for a in argv)
                else:
                    line = str(hc)
                req = hc.get("required", False)
                note = hc.get("note", "")
                print(f"  - {'[required]' if req else '[optional]'} {line}")
                if note:
                    print(f"    note: {note}")
            print()
        print("[discipline] verify OK (no paths to match)")
        return 0

    aggregated: Set[str] = set()
    bad = False
    for raw in paths:
        p = Path(raw)
        if not p.is_absolute():
            p = (Path.cwd() / p).resolve()
        try:
            rel = p.resolve().relative_to(ufc.resolve())
        except ValueError:
            print(f"[discipline] ERROR: path not under UFC root: {p}", file=sys.stderr)
            bad = True
            continue
        rel_posix = rel.as_posix()
        matched = _match_rules(rel_posix, rules)
        if not matched:
            print(f"[discipline] INFO: no rule matched for {rel_posix}")
        for rule in matched:
            rid = rule.get("id", "?")
            for hc in rule.get("harness_commands") or []:
                argv = hc.get("argv")
                if isinstance(argv, list):
                    line = "python UFC/ufc_harness/run_harness.py " + " ".join(str(a) for a in argv)
                else:
                    line = str(hc)
                key = f"{rid}::{line}"
                if key not in aggregated:
                    aggregated.add(key)
                    print(f"[discipline] matched {rel_posix} -> {line}")

    if bad:
        return 1 if strict else 0
    print(f"[discipline] verify OK (touched_paths={len(paths)})")
    return 0


def main_change_package(argv: List[str]) -> int:
    p = argparse.ArgumentParser(prog="change-package")
    sub = p.add_subparsers(dest="action", required=True)
    pv = sub.add_parser("validate", help="校验 plan/changes/<change_id>/ 四制品与 spec 关键字")
    pv.add_argument("--change-id", required=True, dest="change_id")
    pv.add_argument(
        "--strict",
        action="store_true",
        help="缺失或不合规时非零退出（默认 warn-only：打印错误仍退出 0）",
    )
    pv.set_defaults(func=cmd_change_package_validate)
    ns, rest = p.parse_known_args(argv)
    if rest:
        print(f"[change-package] unknown extra args: {rest}", file=sys.stderr)
        return 2
    return int(ns.func(ns))


def main_discipline(argv: List[str]) -> int:
    p = argparse.ArgumentParser(prog="discipline")
    sub = p.add_subparsers(dest="action", required=True)
    pv = sub.add_parser("verify", help="按 manifest 提示 harness 义务（默认指导模式）")
    pv.add_argument(
        "--touch-path",
        action="append",
        default=[],
        dest="touch_path",
        help="相对或绝对路径，可重复；相对当前 cwd（应位于 UFC 根下）",
    )
    pv.add_argument(
        "--strict",
        action="store_true",
        help="manifest 缺失/非法或路径越界时非零退出",
    )
    pv.set_defaults(func=cmd_discipline_verify)
    ns, rest = p.parse_known_args(argv)
    if rest:
        print(f"[discipline] unknown extra args: {rest}", file=sys.stderr)
        return 2
    return int(ns.func(ns))
