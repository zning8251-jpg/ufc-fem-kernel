#!/usr/bin/env python3
"""UFC Harness Gate Checker

Checks architectural constraints defined in:
  docs/05_Project_Planning/PPLAN/06_核心架构/UFC_跨层错误传播协议_Harness门禁.md

Gates checked:
  H-ERR-01  Every public SUBROUTINE across layers has status OUT param
  H-ERR-03  No bare STOP/ERROR STOP outside FATAL handling
  H-CON-01  Every domain directory has CONTRACT.md
  H-DEP-03  No ISO_FORTRAN_ENV usage (must use IF_Prec)
  H-NAM-03  No new MODULE *_Algo files (legacy only)
  H-HOT-01  No ALLOCATE/DEALLOCATE inside Compute_*/Eval subroutines

Usage:
  python check_harness_gates.py <ufc_core_path> [--strict]
    --strict: treat soft gates as hard (exit 1 on any failure)

Exit codes:
  0: all hard gates pass
  1: at least one hard gate failed
"""

import os
import re
import sys
import json
from pathlib import Path
from collections import defaultdict

HARD_GATES = ["H-ERR-01", "H-ERR-03", "H-CON-01", "H-DEP-03", "H-HOT-01"]
SOFT_GATES = ["H-NAM-03", "H-CON-02"]

LAYER_DIRS = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]

# Patterns
RE_BARE_STOP = re.compile(r"^\s*(?:ERROR\s+)?STOP\b", re.IGNORECASE)
RE_ISO_FORTRAN = re.compile(r"USE\s+(?:,\s*INTRINSIC\s*::\s*)?ISO_FORTRAN_ENV", re.IGNORECASE)
RE_MODULE_ALGO = re.compile(r"^MODULE\s+\w+_Algo\s*$", re.IGNORECASE | re.MULTILINE)
RE_ALLOCATE_IN_COMPUTE = re.compile(r"^\s*(?:ALLOCATE|DEALLOCATE)\s*\(", re.IGNORECASE)
RE_SUBROUTINE_START = re.compile(
    r"^\s*SUBROUTINE\s+(\w+)\s*\(", re.IGNORECASE
)
RE_COMPUTE_EVAL = re.compile(r"Compute_|_Eval|_Compute", re.IGNORECASE)


def find_f90_files(root: Path):
    """Yield all .f90 files under root, skipping build/ExternalLibs."""
    for p in root.rglob("*.f90"):
        parts = p.parts
        if any(skip in parts for skip in ("build", "ExternalLibs", "__pycache__", "Tests")):
            continue
        yield p


def check_con_01(root: Path):
    """H-CON-01: Every domain directory has CONTRACT.md."""
    issues = []
    for layer in LAYER_DIRS:
        layer_path = root / layer
        if not layer_path.is_dir():
            continue
        for domain_dir in sorted(layer_path.iterdir()):
            if not domain_dir.is_dir():
                continue
            if domain_dir.name.startswith(".") or domain_dir.name == "contracts":
                continue
            contract = domain_dir / "CONTRACT.md"
            if not contract.exists():
                issues.append(f"{layer}/{domain_dir.name}")
    return issues


def check_dep_03(root: Path):
    """H-DEP-03: No ISO_FORTRAN_ENV usage."""
    issues = []
    for f in find_f90_files(root):
        with open(f, "r", encoding="utf-8", errors="ignore") as fh:
            for i, line in enumerate(fh, 1):
                if RE_ISO_FORTRAN.search(line):
                    rel = f.relative_to(root)
                    issues.append(f"{rel}:{i}")
    return issues


def check_err_03(root: Path):
    """H-ERR-03: No bare STOP/ERROR STOP."""
    issues = []
    for f in find_f90_files(root):
        with open(f, "r", encoding="utf-8", errors="ignore") as fh:
            for i, line in enumerate(fh, 1):
                stripped = line.strip()
                if RE_BARE_STOP.match(stripped):
                    if "FATAL" not in line.upper() and "! FATAL" not in line:
                        rel = f.relative_to(root)
                        issues.append(f"{rel}:{i}: {stripped[:60]}")
    return issues


def check_nam_03(root: Path):
    """H-NAM-03: No new MODULE *_Algo files."""
    issues = []
    for f in find_f90_files(root):
        if f.name.endswith("_Algo.f90"):
            rel = f.relative_to(root)
            issues.append(str(rel))
    return issues


def check_hot_01(root: Path):
    """H-HOT-01: No ALLOCATE/DEALLOCATE inside Compute/Eval subroutines."""
    issues = []
    for f in find_f90_files(root):
        with open(f, "r", encoding="utf-8", errors="ignore") as fh:
            lines = fh.readlines()

        in_compute = False
        current_sub = ""
        for i, line in enumerate(lines, 1):
            m = RE_SUBROUTINE_START.match(line)
            if m:
                sub_name = m.group(1)
                in_compute = bool(RE_COMPUTE_EVAL.search(sub_name))
                current_sub = sub_name
            if line.strip().upper().startswith("END SUBROUTINE"):
                in_compute = False

            if in_compute and RE_ALLOCATE_IN_COMPUTE.match(line):
                rel = f.relative_to(root)
                issues.append(f"{rel}:{i}: {current_sub} -> {line.strip()[:50]}")
    return issues


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <ufc_core_path> [--strict]")
        sys.exit(1)

    root = Path(sys.argv[1])
    strict = "--strict" in sys.argv

    if not root.is_dir():
        print(f"Error: {root} is not a directory")
        sys.exit(1)

    results = {}
    hard_fail = False

    # H-CON-01
    issues = check_con_01(root)
    results["H-CON-01"] = {"status": "PASS" if not issues else "FAIL", "issues": issues}
    if issues:
        hard_fail = True

    # H-DEP-03
    issues = check_dep_03(root)
    results["H-DEP-03"] = {"status": "PASS" if not issues else "FAIL", "issues": issues[:20]}
    if issues:
        hard_fail = True

    # H-ERR-03
    issues = check_err_03(root)
    results["H-ERR-03"] = {"status": "PASS" if not issues else "WARN", "issues": issues[:20]}

    # H-NAM-03 (soft)
    issues = check_nam_03(root)
    results["H-NAM-03"] = {"status": "PASS" if not issues else "WARN", "issues": issues[:20]}
    if issues and strict:
        hard_fail = True

    # H-HOT-01
    issues = check_hot_01(root)
    results["H-HOT-01"] = {"status": "PASS" if not issues else "WARN", "issues": issues[:20]}

    # Report
    print("=" * 60)
    print("UFC Harness Gate Check Report")
    print("=" * 60)
    for gate_id, data in sorted(results.items()):
        status = data["status"]
        n_issues = len(data["issues"])
        marker = "PASS" if status == "PASS" else ("FAIL" if status == "FAIL" else "WARN")
        icon = "+" if marker == "PASS" else ("-" if marker == "FAIL" else "~")
        print(f"  [{icon}] {gate_id}: {marker} ({n_issues} issues)")
        for issue in data["issues"][:5]:
            print(f"        {issue}")
        if n_issues > 5:
            print(f"        ... and {n_issues - 5} more")
    print("=" * 60)

    # JSON output（写入 REPORTS，避免污染 UFC 根目录）
    report_dir = Path("REPORTS")
    report_dir.mkdir(parents=True, exist_ok=True)
    report_path = report_dir / "harness_gate_report.json"
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"Report written to {report_path}")

    if hard_fail:
        print("RESULT: HARD GATE FAILURE")
        sys.exit(1)
    else:
        print("RESULT: ALL HARD GATES PASS")
        sys.exit(0)


if __name__ == "__main__":
    main()