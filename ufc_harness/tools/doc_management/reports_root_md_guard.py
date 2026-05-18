#!/usr/bin/env python3
"""
Guard: REPORTS/*.md (UFC root only, not archive/data subdirs) must not exceed
max_lines unless basename is allowlisted. Prevents long-form reports from
reappearing at repo root after stub+archive migration. Threshold default comes
from harness_config (currently 250 for non-allowlisted root `*.md`).

Config: ufc_harness/config/harness_config.json -> reports_root_md_guard
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def _ufc_root() -> Path:
    # .../UFC/ufc_harness/tools/doc_management/<this>.py -> parents[3] == UFC
    return Path(__file__).resolve().parents[3]


def _config() -> dict:
    cfg_path = Path(__file__).resolve().parents[2] / "config" / "harness_config.json"
    with cfg_path.open(encoding="utf-8") as f:
        return json.load(f)


def _line_count(p: Path) -> int:
    with p.open(encoding="utf-8", errors="replace") as f:
        return sum(1 for _ in f)


def main() -> int:
    root = _ufc_root()
    cfg = _config()
    block = cfg.get("reports_root_md_guard") or {}
    if not block.get("enabled", False):
        print(json.dumps({"skipped": True, "reason": "reports_root_md_guard.disabled"}, ensure_ascii=False))
        return 0

    max_lines = int(block.get("max_lines", 320))
    allow = set(block.get("allowlist_basenames") or [])
    reports = root / "REPORTS"
    if not reports.is_dir():
        print(json.dumps({"error": "REPORTS missing", "path": str(reports)}, ensure_ascii=False), file=sys.stderr)
        return 2

    violations: list[dict[str, str | int]] = []
    for p in sorted(reports.glob("*.md")):
        name = p.name
        if name in allow:
            continue
        n = _line_count(p)
        if n > max_lines:
            violations.append({"file": name, "lines": n, "max_lines": max_lines})

    out = {
        "ufc_root": str(root),
        "max_lines": max_lines,
        "allowlist": sorted(allow),
        "violations": violations,
        "ok": len(violations) == 0,
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))
    return 0 if out["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
