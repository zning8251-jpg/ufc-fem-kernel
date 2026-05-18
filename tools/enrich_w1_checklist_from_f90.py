#!/usr/bin/env python3
"""Append short **W1** / **W2** … excerpts from module headers into pilot checklist Markdown.

Scans the first ~180 lines of each ``ufc_core`` path for a wave marker (``**W1**``,
``**W2**``, ``W1 Material:``, ``W2 Element:``, …) and appends
`` — **Wn**：<snippet>`` to each task row.

Usage:
  python tools/enrich_w1_checklist_from_f90.py [--marker W1] [--refresh] [CHECKLIST.md]
  python tools/enrich_w1_checklist_from_f90.py --marker W2 --refresh \\
    docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_pilot_f90任务清单_W2.md

Without ``--refresh``, rows that already have content after the closing ``）`` are skipped.
Default checklist: ``L3_L4_L5_pilot_f90任务清单_W1.md``; default marker **W1**.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
UFC_CORE = REPO / "ufc_core"

ROW_RE = re.compile(
    r"^(- \[(?:x| )\]\s+\*\*T\d+\*\* `([^`]+)` （约 \d+ 个子程序）)(.*)$"
)


def _is_separator_comment(s: str) -> bool:
    t = s.strip()
    if not t:
        return False
    if set(t) <= {"=", "-"}:
        return True
    if len(t) >= 12 and set(t) <= {"=", "-", " "}:
        return True
    return False


def _tag_start_line(line: str, tag: str) -> bool:
    if f"**{tag}**" in line:
        return True
    s = line.strip()
    if not s.startswith("!"):
        return False
    body = s[1:]
    if re.search(rf"\b{re.escape(tag)}\s*:", body):
        return True
    if re.search(rf"\b{re.escape(tag)}\s+[A-Za-z\u4e00-\u9fff]", body):
        return True
    return False


def _normalize_leading_tag(s: str, tag: str) -> str:
    s = s.strip()
    prefixes = [
        f"**{tag}**：",
        f"**{tag}**:",
        f"{tag}:",
        f"{tag}：",
    ]
    if tag == "W1":
        prefixes.extend(["W1 Material:", "W1 Material："])
    if tag == "W2":
        prefixes.extend(["W2 Mesh:", "W2 Mesh：", "W2 Element:", "W2 Element："])
    for prefix in prefixes:
        if s.startswith(prefix):
            s = s[len(prefix) :].strip()
            break
    return s


def extract_tag_snippet(text: str, tag: str, max_len: int = 200) -> str | None:
    lines = text.splitlines()
    start: int | None = None
    for i, line in enumerate(lines[:180]):
        if _tag_start_line(line, tag):
            start = i
            break
    if start is None:
        return None
    parts: list[str] = []
    for j in range(start, min(start + 8, len(lines))):
        line = lines[j]
        if j > start and line.strip().upper().startswith("MODULE "):
            break
        if line.startswith("!"):
            s = line[1:].strip()
            if not s or _is_separator_comment(s):
                if parts:
                    break
                continue
            parts.append(s)
        elif not line.strip():
            if parts:
                break
        else:
            if parts:
                break
    if not parts:
        return None
    out = " ".join(parts)
    out = _normalize_leading_tag(out, tag)
    out = re.sub(r"\s+", " ", out).strip()
    out = re.sub(r"\s*=+\s*.*$", "", out).strip()
    if len(out) > max_len:
        out = out[: max_len - 1].rstrip() + "…"
    return out or None


def main() -> None:
    ap = argparse.ArgumentParser(description="Enrich pilot checklist from **Wn** module headers")
    ap.add_argument(
        "checklist",
        nargs="?",
        type=Path,
        default=REPO / "docs/05_Project_Planning/PPLAN/03_实施规划/实施路线/L3_L4_L5_pilot_f90任务清单_W1.md",
    )
    ap.add_argument(
        "--refresh",
        action="store_true",
        help="strip existing task-row tails and re-append from .f90 headers",
    )
    ap.add_argument(
        "--marker",
        default="W1",
        choices=("W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"),
        help="marker tag to search in Fortran headers",
    )
    args = ap.parse_args()
    checklist: Path = args.checklist
    tag = args.marker
    raw = checklist.read_text(encoding="utf-8")
    out_lines: list[str] = []
    n_hit = 0
    n_skip = 0
    for line in raw.splitlines():
        m = ROW_RE.match(line)
        if not m:
            out_lines.append(line)
            continue
        prefix = m.group(1)
        rel = m.group(2)
        rest = m.group(3)
        if not args.refresh and rest.strip():
            out_lines.append(line)
            n_skip += 1
            continue
        fp = UFC_CORE / rel
        if not fp.is_file():
            out_lines.append(prefix if args.refresh else line)
            continue
        body = fp.read_text(encoding="utf-8", errors="replace")
        snip = extract_tag_snippet(body, tag)
        label = f"**{tag}**"
        if snip:
            out_lines.append(f"{prefix} — {label}：{snip}")
            n_hit += 1
        else:
            out_lines.append(prefix)
    checklist.write_text("\n".join(out_lines) + ("\n" if raw.endswith("\n") else ""), encoding="utf-8")
    print(
        f"enrich_pilot_checklist: marker={tag} appended excerpts: {n_hit} rows; "
        f"skipped (had tail): {n_skip}; refresh={args.refresh}"
    )


if __name__ == "__main__":
    main()
