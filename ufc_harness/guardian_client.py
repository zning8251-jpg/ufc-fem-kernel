"""
Shared helpers for invoking tools/arch_guardian.py with JSON capture.

Used by run_harness.py (closure) and pillar_loop.py to avoid duplicate subprocess logic.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


def python_exe() -> str:
    return sys.executable


def run_subprocess_text(
    argv: list[str],
    *,
    cwd: str | Path | None = None,
) -> subprocess.CompletedProcess[str]:
    """Run a command with UTF-8 text capture (Windows-safe paths via str cwd)."""
    kwargs: dict = {
        "capture_output": True,
        "text": True,
        "encoding": "utf-8",
        "errors": "replace",
    }
    if cwd is not None:
        kwargs["cwd"] = str(Path(cwd)) if isinstance(cwd, Path) else cwd
    return subprocess.run(argv, **kwargs)


def guardian_script_path(ufc_root: Path) -> Path | None:
    for rel in ("scripts/arch_guardian.py", "tools/arch_guardian.py"):
        p = ufc_root / rel
        if p.is_file():
            return p
    return None


def parse_guardian_json(stdout: str) -> tuple[list[dict], str | None]:
    raw = (stdout or "").strip()
    if not raw.startswith("["):
        return [], "guardian stdout was not JSON array"
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        return [], f"JSON decode error: {e}"
    if not isinstance(data, list):
        return [], "guardian JSON root is not a list"
    return data, None


def run_guardian_json(
    ufc_root: Path,
    scan: str,
    *,
    cwd: str | None = None,
    rules: str | None = None,
) -> tuple[int, list[dict], str, str | None]:
    """
    Run arch_guardian with --json. Returns (exit_code, violations_list, stderr, parse_error).
    """
    script = guardian_script_path(ufc_root)
    if not script:
        return 2, [], "guardian script missing", "arch_guardian.py not found under tools/ or scripts/"
    args = [python_exe(), str(script), scan, "--json"]
    if rules:
        args.extend(["--rules", rules])
    proc = run_subprocess_text(args, cwd=cwd or str(ufc_root))
    data, perr = parse_guardian_json(proc.stdout or "")
    return proc.returncode, data, proc.stderr or "", perr
