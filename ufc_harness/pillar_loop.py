#!/usr/bin/env python3
"""
Pillar-loop: partition Guardian JSON P0/P1/P2 by six through-domain pillars (P1–P6),
emit deterministic recommended harness commands (no LLM).

Config: ufc_harness/pillar_loop_config.json
Reports: REPORTS/pillar_decision_YYYYMMDD_HHMMSS.md
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

HARNESS_ROOT = Path(__file__).resolve().parent

# Import after sys.path — run_harness adds HARNESS_ROOT; pillar_loop may be run as script
if str(HARNESS_ROOT) not in sys.path:
    sys.path.insert(0, str(HARNESS_ROOT))

import harness_paths  # noqa: E402
import guardian_client  # noqa: E402


def _norm_path(p: str) -> str:
    return p.replace("\\", "/")


def load_pillar_config() -> dict:
    cfg_path = HARNESS_ROOT / "pillar_loop_config.json"
    if not cfg_path.is_file():
        raise FileNotFoundError(str(cfg_path))
    with cfg_path.open(encoding="utf-8") as f:
        return json.load(f)


def assign_pillar(file_path: str, pillars: list[dict]) -> str | None:
    n = _norm_path(file_path).lower()
    for p in pillars:
        for m in p.get("path_markers", []):
            if m.lower().replace("\\", "/") in n:
                return str(p["id"])
    return None


def _unique_rules(violations: list[dict]) -> list[str]:
    return sorted({str(v.get("rule_id", "?")) for v in violations if v.get("rule_id")})


def _build_recommendations(
    pillar: dict,
    p0_list: list[dict],
    ufc_root: Path,
) -> list[str]:
    """Deterministic rule engine from violation rule_ids + pillar profile."""
    rules = _unique_rules([v for v in p0_list if v.get("severity") == "P0"])
    scan = str(ufc_root / pillar["default_scan_subdir"])
    lines: list[str] = []

    if "DEP-001" in rules or any(r.startswith("DEP") for r in rules):
        lines.append(
            f"python ufc_harness/run_harness.py guardian {scan} --rules DEP-001 --json"
        )
    if any(r.startswith("HOT") for r in rules):
        hot = [r for r in rules if r.startswith("HOT")]
        lines.append(
            "python ufc_harness/run_harness.py guardian "
            f"{scan} --rules {','.join(hot) if hot else 'HOT-001,HOT-002,HOT-003,HOT-004'} --json"
        )
    if "GLB-001" in rules:
        lines.append(f"python ufc_harness/run_harness.py guardian {scan} --rules GLB-001 --json")
    if "WB-001" in rules:
        lines.append(f"python ufc_harness/run_harness.py guardian {scan} --rules WB-001 --json")
    if "TYPE-003" in rules:
        lines.append(
            f"python ufc_harness/run_harness.py guardian {scan} --rules TYPE-003 --json"
        )

    lines.append(f"python ufc_harness/run_harness.py guardian {scan} --fail-on-p0")
    lines.append(f"python ufc_harness/run_harness.py naming {scan}")

    has_l5_proc = any(
        "/l5_rt/" in _norm_path(str(v.get("file_path", ""))).lower()
        and "_proc" in Path(str(v.get("file_path", ""))).stem.lower()
        for v in p0_list
    )
    if has_l5_proc:
        sio = HARNESS_ROOT / "tools/code_development/sio_checker.py"
        if sio.is_file():
            lines.append(f"python ufc_harness/tools/code_development/sio_checker.py {scan}")

    # De-dup preserving order
    seen: set[str] = set()
    out: list[str] = []
    for x in lines:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def run_pillar_loop(ns: argparse.Namespace) -> int:
    ufc_root = harness_paths.ufc_root()
    core = harness_paths.ufc_core_dir()
    scan = ns.path if ns.path else (str(core) if core.exists() else str(ufc_root))

    cfg = load_pillar_config()
    pillars: list[dict] = cfg["pillars"]

    reports_dir = ufc_root / "REPORTS"
    reports_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_path = reports_dir / f"pillar_decision_{ts}.md"

    if ns.dry_run:
        print("[pillar-loop] --dry-run: skipping guardian; writing minimal report.", file=sys.stderr)
        lines = _report_markdown(
            ts, ufc_root, scan, [], {}, pillars, cfg, dry_run=True, cross_cutting=[]
        )
        report_path.write_text(lines, encoding="utf-8")
        print(f"[pillar-loop] report: {report_path}")
        for ln in _stdout_commands({}, pillars, dry_run=True):
            print(ln)
        return 0

    g_rc, data, g_err, perr = guardian_client.run_guardian_json(ufc_root, scan, cwd=str(ufc_root))
    if perr:
        print(f"[pillar-loop] guardian JSON parse: {perr}", file=sys.stderr)
        if g_err:
            print(g_err[:4000], file=sys.stderr)

    by_pillar: dict[str, list[dict]] = defaultdict(list)
    cross: list[dict] = []
    for v in data:
        fp = str(v.get("file_path", ""))
        pid = assign_pillar(fp, pillars)
        if pid:
            by_pillar[pid].append(v)
        else:
            cross.append(v)

    p0_by_pillar = {k: [x for x in vs if x.get("severity") == "P0"] for k, vs in by_pillar.items()}
    p0_cross = [x for x in cross if x.get("severity") == "P0"]

    md = _report_markdown(
        ts, ufc_root, scan, data, p0_by_pillar, pillars, cfg, dry_run=False, cross_cutting=cross
    )
    report_path.write_text(md, encoding="utf-8")
    print(f"[pillar-loop] report: {report_path}")

    for ln in _stdout_commands(dict(p0_by_pillar), pillars, dry_run=False):
        print(ln)

    p0_total = sum(1 for v in data if v.get("severity") == "P0")
    if ns.fail_on_p0 and p0_total > 0:
        return 1
    if g_rc != 0 and not data:
        return min(g_rc, 2)
    return 0 if g_rc == 0 else min(g_rc, 1)


def _stdout_commands(
    p0_by_pillar: dict[str, list[dict]],
    pillars: list[dict],
    *,
    dry_run: bool,
) -> list[str]:
    out: list[str] = []
    if dry_run:
        out.append("# pillar-loop (dry-run): would run full guardian on ufc_core, then partition by P1–P6.")
        return out
    ufc_root = harness_paths.ufc_root()
    for p in pillars:
        pid = p["id"]
        p0s = p0_by_pillar.get(pid, [])
        if not p0s:
            continue
        out.append(f"## {pid} — P0 count={len(p0s)}")
        for cmd in _build_recommendations(p, p0s, ufc_root):
            out.append(cmd)
    if not any(p0_by_pillar.get(p["id"]) for p in pillars):
        out.append("# No P0 violations in pillar-partitioned view (or no P0 at all). Run: python ufc_harness/run_harness.py closure")
    return out


def _report_markdown(
    ts: str,
    ufc_root: Path,
    scan: str,
    all_violations: list[dict],
    p0_by_pillar: dict[str, list[dict]],
    pillars: list[dict],
    cfg: dict,
    *,
    dry_run: bool,
    cross_cutting: list[dict],
) -> str:
    lines: list[str] = []
    lines.append("# Pillar-loop decision report\n\n")
    lines.append(f"- **Generated**: `{ts}`\n")
    lines.append(f"- **UFC root**: `{ufc_root}`\n")
    lines.append(f"- **Guardian scan**: `{scan}`\n")
    lines.append(f"- **Config**: `ufc_harness/pillar_loop_config.json`\n")
    if dry_run:
        lines.append("- **Mode**: dry-run (no guardian executed)\n")
    lines.append("\n## Binary structure (from config)\n\n")
    bs = cfg.get("binary_structure", {})
    lines.append(f"```json\n{json.dumps(bs, ensure_ascii=False, indent=2)}\n```\n")

    lines.append("\n## Six pillars (P1–P6)\n\n")
    lines.append("| id | name | default L3 scan subdir |\n")
    lines.append("|----|------|------------------------|\n")
    for p in pillars:
        lines.append(
            f"| `{p['id']}` | {p.get('name_en','')} / {p.get('name_zh','')} | `{p.get('default_scan_subdir','')}` |\n"
        )

    lines.append("\n## P0 by pillar\n\n")
    if dry_run:
        lines.append("_Skipped in dry-run._\n")
    else:
        any_p0 = False
        for p in pillars:
            pid = p["id"]
            p0s = [v for v in p0_by_pillar.get(pid, []) if v.get("severity") == "P0"]
            if not p0s:
                continue
            any_p0 = True
            lines.append(f"### {pid}\n\n")
            by_rule = Counter(str(v.get("rule_id", "?")) for v in p0s)
            lines.append(f"- **P0 count**: {len(p0s)}; **rules**: {dict(by_rule)}\n")
            for cmd in _build_recommendations(p, p0s, ufc_root):
                lines.append(f"  - `{cmd}`\n")
            lines.append("\n")
        if not any_p0:
            lines.append("_No P0 in any pillar bucket._\n")

    if not dry_run and cross_cutting:
        p0x = [v for v in cross_cutting if v.get("severity") == "P0"]
        lines.append("\n## Unassigned path bucket (P0)\n\n")
        if p0x:
            lines.append(f"- **P0 count**: {len(p0x)} (file paths did not match any pillar `path_markers`)\n")
            for v in p0x[:40]:
                lines.append(
                    f"  - `{v.get('rule_id')}` `{v.get('file_path')}` L{v.get('line_no')}\n"
                )
            if len(p0x) > 40:
                lines.append(f"  - _… {len(p0x) - 40} more_\n")
            lines.append(
                "\n**Recommended**: `python ufc_harness/run_harness.py guardian "
                f"{scan} --fail-on-p0` then narrow by top `rule_id`.\n"
            )
        else:
            lines.append("_No unassigned P0._\n")

    lines.append("\n## Full scan counts (severity)\n\n")
    if dry_run:
        lines.append("_Skipped._\n")
    else:
        ctr = Counter(str(v.get("severity", "?")) for v in all_violations)
        lines.append(f"- {dict(ctr)}\n")

    lines.append("\n---\n*Autonomous layer: rule-only recommendations; no LLM.*\n")
    return "".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Partition Guardian violations by P1–P6 pillars; emit recommended harness commands.",
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help="guardian scan path (default: ufc_core)",
    )
    parser.add_argument("--dry-run", action="store_true", help="skip guardian; write scaffold report")
    parser.add_argument(
        "--fail-on-p0",
        action="store_true",
        help="exit 1 if any P0 in full guardian JSON",
    )
    ns = parser.parse_args(argv)
    return run_pillar_loop(ns)


if __name__ == "__main__":
    raise SystemExit(main())
