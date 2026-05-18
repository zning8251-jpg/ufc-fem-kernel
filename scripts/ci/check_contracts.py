#!/usr/bin/env python3
"""UFC Contract Card Validator

Checks that every domain directory under ufc_core has a CONTRACT.md
and validates basic structure requirements.

Usage:
  python check_contracts.py <ufc_core_path>

Exit codes:
  0: all domains have valid contracts
  1: missing or invalid contracts found
"""

import sys
import re
from pathlib import Path

LAYER_DIRS = ["L1_IF", "L2_NM", "L3_MD", "L4_PH", "L5_RT", "L6_AP"]

REQUIRED_SECTIONS = [
    r"#+\s*.*职责",
    r"#+\s*.*十件套",
]

RECOMMENDED_SECTIONS = [
    r"#+\s*.*四链",
    r"#+\s*.*域际关系|域间关系|上游|下游",
    r"#+\s*.*SIO|Arg",
    r"#+\s*.*约束|Harness",
]


def check_domain_contract(contract_path: Path, domain_rel: str):
    """Check a single CONTRACT.md for required/recommended content."""
    issues = []
    warnings = []

    try:
        content = contract_path.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        issues.append(f"{domain_rel}: cannot read CONTRACT.md: {e}")
        return issues, warnings

    if len(content.strip()) < 50:
        issues.append(f"{domain_rel}: CONTRACT.md is nearly empty ({len(content)} chars)")
        return issues, warnings

    for pattern in REQUIRED_SECTIONS:
        if not re.search(pattern, content, re.IGNORECASE):
            warnings.append(f"{domain_rel}: missing recommended section matching '{pattern}'")

    for pattern in RECOMMENDED_SECTIONS:
        if not re.search(pattern, content, re.IGNORECASE):
            warnings.append(f"{domain_rel}: consider adding section matching '{pattern}'")

    return issues, warnings


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <ufc_core_path>")
        sys.exit(1)

    root = Path(sys.argv[1])
    if not root.is_dir():
        print(f"Error: {root} is not a directory")
        sys.exit(1)

    all_issues = []
    all_warnings = []
    total_domains = 0
    with_contract = 0

    for layer in LAYER_DIRS:
        layer_path = root / layer
        if not layer_path.is_dir():
            continue
        for domain_dir in sorted(layer_path.iterdir()):
            if not domain_dir.is_dir():
                continue
            if domain_dir.name.startswith(".") or domain_dir.name == "contracts":
                continue

            total_domains += 1
            domain_rel = f"{layer}/{domain_dir.name}"
            contract = domain_dir / "CONTRACT.md"

            if not contract.exists():
                all_issues.append(f"{domain_rel}: CONTRACT.md MISSING")
            else:
                with_contract += 1
                issues, warnings = check_domain_contract(contract, domain_rel)
                all_issues.extend(issues)
                all_warnings.extend(warnings)

    print("=" * 60)
    print("UFC Contract Card Validation Report")
    print("=" * 60)
    print(f"  Total domains: {total_domains}")
    print(f"  With CONTRACT.md: {with_contract}")
    print(f"  Coverage: {with_contract}/{total_domains} ({100*with_contract//max(total_domains,1)}%)")
    print()

    if all_issues:
        print(f"  ISSUES ({len(all_issues)}):")
        for issue in all_issues:
            print(f"    [-] {issue}")
    else:
        print("  No issues found.")

    if all_warnings:
        print(f"\n  WARNINGS ({len(all_warnings)}):")
        for w in all_warnings[:20]:
            print(f"    [~] {w}")
        if len(all_warnings) > 20:
            print(f"    ... and {len(all_warnings) - 20} more")

    print("=" * 60)

    if all_issues:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()