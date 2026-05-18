#!/usr/bin/env python3
"""UFC naming audit against v3.0 spec."""
import os, re
from pathlib import Path
from collections import defaultdict

core = Path(r"d:\TEST7\UFC\ufc_core")
issues = defaultdict(list)
stats = {"total": 0, "module_file_mismatch": 0, "no_layer_prefix": 0}

LAYER_PREFIXES = {"IF_", "NM_", "MD_", "PH_", "RT_", "AP_"}
MOD_RE = re.compile(r"^\s*MODULE\s+(\w+)", re.IGNORECASE)

for f in sorted(core.rglob("*.f90")):
    stats["total"] += 1
    fname = f.stem
    try:
        content = f.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue

    for line in content.split("\n"):
        m = MOD_RE.match(line)
        if not m:
            continue
        mod = m.group(1)
        if mod.upper() == "PROCEDURE":
            continue

        if mod != fname and mod.lower() != fname.lower():
            stats["module_file_mismatch"] += 1
            parts = str(f).split("ufc_core")
            layer = parts[1].split(os.sep)[1] if len(parts) > 1 else "?"
            issues["module_file_mismatch"].append(
                f"{layer}: {f.name} -> MODULE {mod}"
            )

        has_prefix = any(
            mod.startswith(p) or mod.upper().startswith(p) for p in LAYER_PREFIXES
        )
        if not has_prefix:
            stats["no_layer_prefix"] += 1
            parts = str(f).split("ufc_core")
            layer = parts[1].split(os.sep)[1] if len(parts) > 1 else "?"
            issues["no_layer_prefix"].append(f"{layer}: MODULE {mod} ({f.name})")

print("=== UFC Naming Audit Report (v3.0) ===")
print(f"Total .f90 files scanned: {stats['total']}")
print()
print(f"--- MODULE/File Mismatches ({stats['module_file_mismatch']}) ---")
for item in sorted(issues["module_file_mismatch"])[:40]:
    print(f"  {item}")
if len(issues["module_file_mismatch"]) > 40:
    print(f"  ... and {len(issues['module_file_mismatch'])-40} more")
print()
print(f"--- Missing Layer Prefix ({stats['no_layer_prefix']}) ---")
for item in sorted(issues["no_layer_prefix"])[:40]:
    print(f"  {item}")
if len(issues["no_layer_prefix"]) > 40:
    print(f"  ... and {len(issues['no_layer_prefix'])-40} more")
