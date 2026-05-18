#!/usr/bin/env python3
"""
Agent-oriented harness helpers (UFC 闭环 × 生产级 Agent Harness 理念).

- **agent-bundle**: 单次导出 Prompt→Context→Harness→Loop 的机器可读上下文包。
- **agent-checkpoint**: 会话状态 JSON（断点续跑叙事，非 LLM）。
- **agent-trace**: JSONL 飞行记录（可观测性）。
- **agent-slow-loop**: 慢思考复盘模板（确定性问题清单，不调模型）。
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

HARNESS_ROOT = Path(__file__).resolve().parent


def _ensure_import_path() -> None:
    root = str(HARNESS_ROOT)
    if root not in sys.path:
        sys.path.insert(0, root)


def _reports_dir() -> Path:
    _ensure_import_path()
    import harness_paths  # noqa: E402

    override = os.environ.get("UFC_AGENT_REPORTS_DIR")
    if override:
        p = Path(override).expanduser().resolve()
        p.mkdir(parents=True, exist_ok=True)
        return p
    r = harness_paths.ufc_root() / "REPORTS"
    r.mkdir(parents=True, exist_ok=True)
    return r


def _utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")


def _load_checklist() -> Dict[str, Any]:
    p = HARNESS_ROOT / "closure_loop_checklist.json"
    if not p.is_file():
        return {}
    with p.open(encoding="utf-8") as f:
        return json.load(f)


def _ufc_root() -> Path:
    _ensure_import_path()
    import harness_paths  # noqa: E402

    return harness_paths.ufc_root()


def cmd_agent_bundle(ns: argparse.Namespace) -> int:
    """Write REPORTS/agent_context_bundle_<ts>.md (+ optional .json sidecar)."""
    ufc = _ufc_root()
    reports = _reports_dir()
    ts = _utc_stamp()
    checklist = _load_checklist()
    task = (ns.task or "").strip()

    md_path = reports / f"agent_context_bundle_{ts}.md"
    lines: List[str] = []
    lines.append("# UFC Agent context bundle\n\n")
    lines.append(f"_Generated: {ts} (UTC-stamped filename)_\n\n")
    if task:
        lines.append("## Current task (from `--task`)\n\n")
        lines.append(f"{task}\n\n")

    lines.append("## UFC closed loop (AGENTS.md)\n\n")
    lines.append("```mermaid\n")
    lines.append("graph LR\n")
    lines.append("  P[Prompt] --> C[Context]\n")
    lines.append("  C --> S[Skills]\n")
    lines.append("  S --> M[MCP]\n")
    lines.append("  S --> A[Agent]\n")
    lines.append("  M --> A\n")
    lines.append("  A --> H[Harness]\n")
    lines.append("  H --> L[Loop]\n")
    lines.append("  L --> C\n")
    lines.append("```\n\n")

    lines.append("## Context carriers\n\n")
    loop_nodes = (checklist.get("loop_nodes") or {}) if checklist else {}
    if loop_nodes:
        for name, body in loop_nodes.items():
            if isinstance(body, dict):
                c = body.get("carrier") or body.get("carriers")
                lines.append(f"- **{name}**: `{c}`\n")
    else:
        lines.append("- See `AGENTS.md` and `ufc_harness/closure_loop_checklist.json`.\n")
    lines.append("\n")

    lines.append("## Document tiers (on-demand context)\n\n")
    lines.append(
        "- **T0–T5 & load order**: `docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md`\n"
    )
    lines.append("- **Maintenance / merge rules**: `docs/DOC_MAINTENANCE_GUIDE.md`\n")
    lines.append("- **Task orchestration**: `plan/UFC_DIRECTORY_AND_AGENT_PLAYBOOK.md`\n\n")

    lines.append("## Recommended harness chain (fast loop)\n\n")
    steps = checklist.get("harness_closure_steps") or [
        {"id": "doc-structure", "command": "python ufc_harness/run_harness.py doc-structure"},
        {"id": "plan-checks", "command": "python ufc_harness/run_harness.py plan-checks"},
        {"id": "guardian", "command": "python ufc_harness/run_harness.py guardian --fail-on-p0"},
        {"id": "naming", "command": "python ufc_harness/run_harness.py naming"},
    ]
    for s in steps:
        sid = s.get("id", "")
        cmd = s.get("command", "")
        lines.append(f"1. `{sid}` → `{cmd}`\n")
    lines.append("\n")

    lines.append("## Six layers (code home)\n\n")
    lines.append("| Layer | Path |\n|------|------|\n")
    lines.append("| L1–L6 production | `ufc_core/` |\n")
    lines.append("| Harness | `ufc_harness/` |\n")
    lines.append("| Docs / contracts | `docs/`, domain `CONTRACT.md` |\n\n")

    lines.append("## Skills (invoke)\n\n")
    lines.append("`npx openskills read <skill-name>` — names in `closure_loop_checklist.json` → `skills`.\n\n")

    lines.append("## Agent harness helpers (this module)\n\n")
    lines.append("| Command | Role |\n")
    lines.append("|---------|------|\n")
    lines.append("| `agent-checkpoint` | Session JSON: goal + step log |\n")
    lines.append("| `agent-trace` | JSONL flight log |\n")
    lines.append("| `agent-slow-loop` | Reflection checklist after a run |\n")
    lines.append("| `agent-bundle` | This file |\n\n")

    lines.append(f"## Repo root\n\n`{ufc}`\n")

    md_path.write_text("".join(lines), encoding="utf-8")
    print(f"[agent-harness] wrote {md_path}")

    if ns.json_sidecar:
        side = {
            "version": "1.0",
            "ufc_root": str(ufc),
            "task": task or None,
            "checklist_version": checklist.get("version"),
            "harness_closure_steps": steps,
            "document_tiers_md": "docs/DOCUMENT_TIERS_AND_ON_DEMAND_CONTEXT.md",
            "markdown": str(md_path),
        }
        jp = reports / f"agent_context_bundle_{ts}.json"
        jp.write_text(json.dumps(side, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"[agent-harness] wrote {jp}")

    return 0


def _session_path(session: str) -> Path:
    safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in session.strip())[:120]
    if not safe:
        safe = "default"
    return _reports_dir() / f"agent_session_{safe}.json"


def cmd_agent_checkpoint(ns: argparse.Namespace) -> int:
    action = ns.action
    session = ns.session or "default"

    if action == "init":
        goal = (ns.goal or "").strip()
        doc: Dict[str, Any] = {
            "version": "1.0",
            "session_id": session,
            "goal": goal,
            "created_at": datetime.now(timezone.utc).isoformat(),
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "steps": [],
        }
        sp = _session_path(session)
        sp.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"[agent-checkpoint] init → {sp}")
        return 0

    sp = _session_path(session)
    if not sp.is_file():
        print(f"[agent-checkpoint] missing session file: {sp}", file=sys.stderr)
        return 2

    if action == "show":
        print(sp.read_text(encoding="utf-8"))
        return 0

    if action == "clear":
        sp.unlink()
        print(f"[agent-checkpoint] cleared {sp}")
        return 0

    if action == "append":
        raw = sp.read_text(encoding="utf-8")
        doc = json.loads(raw)
        step = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "label": (ns.label or "").strip() or "step",
            "harness_cmd": (ns.harness_cmd or "").strip(),
            "exit_code": int(ns.rc) if ns.rc is not None else None,
            "note": (ns.note or "").strip() or None,
        }
        steps = doc.get("steps")
        if not isinstance(steps, list):
            steps = []
        steps.append(step)
        doc["steps"] = steps
        doc["updated_at"] = datetime.now(timezone.utc).isoformat()
        sp.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"[agent-checkpoint] append → {sp} (steps={len(steps)})")
        return 0

    print(f"[agent-checkpoint] unknown action: {action}", file=sys.stderr)
    return 2


_TRACE_FILE = "agent_harness_trace.jsonl"


def cmd_agent_trace(ns: argparse.Namespace) -> int:
    reports = _reports_dir()
    tpath = reports / _TRACE_FILE

    if ns.action == "tail":
        n = max(1, int(ns.lines))
        if not tpath.is_file():
            print("(empty trace)", file=sys.stderr)
            return 0
        all_lines = tpath.read_text(encoding="utf-8").splitlines()
        for line in all_lines[-n:]:
            print(line)
        return 0

    if ns.action == "log":
        rec = {
            "ts": datetime.now(timezone.utc).isoformat(),
            "kind": (ns.kind or "harness").strip(),
            "command": (ns.cmd or "").strip(),
            "exit_code": int(ns.rc) if ns.rc is not None else None,
            "duration_ms": int(ns.ms) if ns.ms is not None else None,
            "session": (ns.session or "").strip() or None,
            "note": (ns.note or "").strip() or None,
        }
        with tpath.open("a", encoding="utf-8") as f:
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        print(f"[agent-trace] logged → {tpath}")
        return 0

    print(f"[agent-trace] unknown action: {ns.action}", file=sys.stderr)
    return 2


def _latest_report_glob(reports: Path, pattern: str) -> Optional[Path]:
    paths = sorted(reports.glob(pattern), key=lambda p: p.stat().st_mtime, reverse=True)
    return paths[0] if paths else None


def cmd_agent_slow_loop(ns: argparse.Namespace) -> int:
    """Emit deterministic 'slow loop' reflection markdown."""
    reports = _reports_dir()
    ufc = _ufc_root()
    ts = _utc_stamp()

    from_path: Optional[Path] = None
    if ns.from_report:
        from_path = Path(ns.from_report).expanduser()
        if not from_path.is_file():
            print(f"[agent-slow-loop] file not found: {from_path}", file=sys.stderr)
            return 2
    else:
        from_path = _latest_report_glob(reports, "loop_run_*.md")
        if from_path is None:
            from_path = _latest_report_glob(reports, "pillar_decision_*.md")

    out = reports / f"agent_slow_loop_{ts}.md"
    lines: List[str] = []
    lines.append("# Agent slow loop (UFC)\n\n")
    lines.append(
        "_Deterministic checklist — 对应「慢思考」复盘：不调 LLM，由 Agent 逐条自答。_\n\n"
    )
    lines.append(f"- **UFC root**: `{ufc}`\n")
    if from_path:
        lines.append(f"- **Input report**: `{from_path}`\n")
    else:
        lines.append("- **Input report**: _(none found; answer from memory of last run)_\n")
    lines.append("\n## Alignment with UFC loop nodes\n\n")
    lines.append("1. **Prompt**: 用户最初目标是否仍被遵守？有无范围蔓延？\n")
    lines.append("2. **Context**: 是否已对照 `AGENTS.md` / 相关 `CONTRACT.md` / 域技能？\n")
    lines.append("3. **Skills**: 本轮是否应加载 `ufc-structured-io` / `ufc-layer-domain-feature` 等而未加载？\n")
    lines.append("4. **MCP**: 哪些外部证据仍缺（手册、上游代码、浏览器验证）？\n")
    lines.append("5. **Harness**: 失败步骤的根因类别（文档 / Guardian P0 / 命名 / SIO）？下一步最小命令？\n")
    lines.append("6. **Loop**: 需要写回 REPORTS、记忆或文档索引的条目？\n\n")

    lines.append("## Harness-specific questions\n\n")
    lines.append("- Guardian：是 `DEP` / `HOT` / `GLB` / `TYPE-003` / `WB` 哪类？是否应收窄 `--rules`？\n")
    lines.append("- 若 P0>0：是否应先修桥接层或依赖方向，再跑全量？\n")
    lines.append("- `pillar-loop`：P1–P6 哪一柱最红？是否应对应子目录单跑 guardian？\n\n")

    lines.append("## Next fast-loop command (fill in)\n\n")
    lines.append("```bash\n# python ufc_harness/run_harness.py ...\n```\n")

    out.write_text("".join(lines), encoding="utf-8")
    print(f"[agent-slow-loop] wrote {out}")
    return 0
