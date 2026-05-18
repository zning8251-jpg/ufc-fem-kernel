#!/usr/bin/env python3
"""
TASK_RUN.md：长任务外置状态卡（UFC/plan/tasks/<session>/ 约定）。

子命令：init | status | validate | list

覆盖路径：环境变量 UFC_PLAN_ROOT 指向替代 plan 根目录（测试用）。
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple

HARNESS_ROOT = Path(__file__).resolve().parent
TEMPLATE_PATH = HARNESS_ROOT / "templates" / "TASK_RUN.template.md"


def _ensure_import_path() -> None:
    root = str(HARNESS_ROOT)
    if root not in sys.path:
        sys.path.insert(0, root)


def plan_root() -> Path:
    _ensure_import_path()
    import harness_paths  # noqa: E402

    override = os.environ.get("UFC_PLAN_ROOT")
    if override:
        p = Path(override).expanduser().resolve()
        p.mkdir(parents=True, exist_ok=True)
        return p
    return harness_paths.ufc_root() / "plan"


def tasks_root() -> Path:
    r = plan_root() / "tasks"
    r.mkdir(parents=True, exist_ok=True)
    return r


def _session_slug(session: str) -> str:
    s = session.strip()
    safe = "".join(c if c.isalnum() or c in "._-" else "_" for c in s)[:120]
    return safe or "default"


def task_run_path(session: str) -> Path:
    return tasks_root() / _session_slug(session) / "TASK_RUN.md"


def _parse_simple_frontmatter(text: str) -> Tuple[Dict[str, str], str]:
    """Parse leading ---\\n key: value \\n--- body; values stripped, no multiline values."""
    if not text.lstrip().startswith("---"):
        return {}, text
    text_stripped = text.lstrip()
    if not text_stripped.startswith("---"):
        return {}, text
    rest = text_stripped[3:].lstrip("\n")
    end = rest.find("\n---")
    if end == -1:
        return {}, text
    fm_block = rest[:end]
    body = rest[end + 4 :].lstrip("\n")
    meta: Dict[str, str] = {}
    for line in fm_block.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        meta[k.strip()] = v.strip().strip('"').strip("'")
    return meta, body


def _required_fm_keys() -> List[str]:
    return ["task_run_version", "session", "status", "current_step_id", "updated_at"]


def cmd_agent_task_init(ns: argparse.Namespace) -> int:
    session = (ns.session or "").strip()
    if not session:
        print("[agent-task] init requires --session", file=sys.stderr)
        return 2
    goal = (ns.goal or "").strip() or "（填写本任务目标与验收标准）"
    out = task_run_path(session)
    task_dir = out.parent
    if out.is_file() and not ns.force:
        print(f"[agent-task] file exists: {out} (use --force to overwrite)", file=sys.stderr)
        return 1
    if not TEMPLATE_PATH.is_file():
        print(f"[agent-task] missing template: {TEMPLATE_PATH}", file=sys.stderr)
        return 2
    tpl = TEMPLATE_PATH.read_text(encoding="utf-8")
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    content = (
        tpl.replace("{{SESSION}}", _session_slug(session))
        .replace("{{GOAL}}", goal)
        .replace("{{UPDATED_AT}}", ts)
    )
    task_dir.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")
    print(f"[agent-task] init → {out}")
    return 0


def cmd_agent_task_status(ns: argparse.Namespace) -> int:
    session = (ns.session or "").strip()
    if not session:
        print("[agent-task] status requires --session", file=sys.stderr)
        return 2
    out = task_run_path(session)
    if not out.is_file():
        print(f"[agent-task] missing: {out}", file=sys.stderr)
        return 2
    text = out.read_text(encoding="utf-8")
    meta, _ = _parse_simple_frontmatter(text)
    print(f"file: {out}\n")
    for k in _required_fm_keys():
        print(f"  {k}: {meta.get(k, '(missing)')}")
    for k, v in sorted(meta.items()):
        if k in _required_fm_keys():
            continue
        print(f"  {k}: {v}")
    return 0


def _count_subtask_data_rows(body: str) -> int:
    in_sub = False
    count = 0
    for line in body.splitlines():
        if line.strip().startswith("## Subtasks"):
            in_sub = True
            continue
        if in_sub and line.startswith("## ") and "Subtasks" not in line:
            break
        if not in_sub:
            continue
        s = line.strip()
        if not s.startswith("|"):
            continue
        if re.match(r"^\|\s*id\s*\|", s, re.I):
            continue
        if re.match(r"^\|\s*[-:]+", s):
            continue
        parts = [p.strip() for p in s.strip("|").split("|")]
        if len(parts) >= 4 and parts[0].isdigit():
            count += 1
    return count


def cmd_agent_task_validate(ns: argparse.Namespace) -> int:
    session = (ns.session or "").strip()
    if not session:
        print("[agent-task] validate requires --session", file=sys.stderr)
        return 2
    out = task_run_path(session)
    if not out.is_file():
        print(f"[agent-task] missing: {out}", file=sys.stderr)
        return 2
    text = out.read_text(encoding="utf-8")
    meta, body = _parse_simple_frontmatter(text)
    errs: List[str] = []
    for k in _required_fm_keys():
        if k not in meta or not meta[k]:
            errs.append(f"missing frontmatter key: {k}")
    if "## Subtasks" not in text:
        errs.append("missing section: ## Subtasks")
    if "| id |" not in text and "| id|" not in text.replace(" ", ""):
        if "subtask" not in text.lower():
            errs.append("missing Subtasks table header (expected column id)")
    rows = _count_subtask_data_rows(body if "## Subtasks" in text else text)
    if ns.strict and rows < 1:
        errs.append("strict: need at least one numeric subtask row under ## Subtasks")
    if errs:
        for e in errs:
            print(f"[agent-task] validate FAIL: {e}", file=sys.stderr)
        return 1
    print(f"[agent-task] validate OK: {out} (subtask_rows={rows})")
    return 0


def cmd_agent_task_list(_: argparse.Namespace) -> int:
    root = tasks_root()
    if not root.is_dir():
        print("(no plan/tasks/)")
        return 0
    found: List[Tuple[float, Path]] = []
    for d in root.iterdir():
        if not d.is_dir():
            continue
        p = d / "TASK_RUN.md"
        if p.is_file():
            found.append((p.stat().st_mtime, p))
    if not found:
        print("(no */TASK_RUN.md under plan/tasks/)")
        return 0
    for _, p in sorted(found, key=lambda x: x[0], reverse=True):
        print(p)
    return 0


def cmd_agent_task(ns: argparse.Namespace) -> int:
    act = ns.task_action
    if act == "init":
        return cmd_agent_task_init(ns)
    if act == "status":
        return cmd_agent_task_status(ns)
    if act == "validate":
        return cmd_agent_task_validate(ns)
    if act == "list":
        return cmd_agent_task_list(ns)
    print(f"[agent-task] unknown action: {act}", file=sys.stderr)
    return 2
