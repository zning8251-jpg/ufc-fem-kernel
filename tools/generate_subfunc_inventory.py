#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UFC 细粒度子程序清单生成器
扫描每个域/子域的 .f90 文件，提取 MODULE/TYPE/SUBROUTINE/FUNCTION 声明，
生成标准的「细粒度子程序清单」表格并追加到 CONTRACT.md。

仅追加，不修改已有内容。如果 CONTRACT.md 已包含「细粒度子程序清单」或「细粒度清单」则跳过。
"""
import os
import re
import sys
import glob
from collections import defaultdict

UFC_CORE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ufc_core")

FUNC_SET_PATTERNS = {
    "Init":     re.compile(r'_Init|_Initialize|_Setup|_Create', re.IGNORECASE),
    "Finalize": re.compile(r'_Finalize|_Destroy|_Cleanup|_Free|_Deallocate', re.IGNORECASE),
    "Compute":  re.compile(r'_Compute|_Calculate|_Evaluate|_Solve|_Integrate|_Update', re.IGNORECASE),
    "Query":    re.compile(r'_Get|_Query|_Find|_Lookup|_Search|_Count|_Has|_Is', re.IGNORECASE),
    "Mutate":   re.compile(r'_Set|_Add|_Remove|_Delete|_Insert|_Assign|_Reset|_Clear', re.IGNORECASE),
    "Validate": re.compile(r'_Valid|_Check|_Verify|_Assert|_Test', re.IGNORECASE),
    "Parse":    re.compile(r'_Parse|_Read|_Load|_Import|_Decode', re.IGNORECASE),
    "Bridge":   re.compile(r'_Brg|_Bridge|_Facade|_Adapt|_Convert|_Transform', re.IGNORECASE),
    "Populate": re.compile(r'_Populate|_Build|_Sync|_Fill|_Map', re.IGNORECASE),
    "IO":       re.compile(r'_Write|_Print|_Dump|_Output|_Log|_Report|_Summary|_Display', re.IGNORECASE),
}

MODULE_RE = re.compile(r'^\s*MODULE\s+(\w+)\s*$', re.IGNORECASE)
END_MODULE_RE = re.compile(r'^\s*END\s+MODULE', re.IGNORECASE)
TYPE_DEF_RE = re.compile(r'^\s*TYPE(?:\s*,\s*(?:PUBLIC|PRIVATE))?\s*(?:::)?\s*(\w+)\s*$', re.IGNORECASE)
TYPE_EXT_RE = re.compile(r'^\s*TYPE(?:\s*,\s*(?:PUBLIC|PRIVATE))?\s*,\s*EXTENDS\s*\(\s*\w+\s*\)\s*(?:::)?\s*(\w+)', re.IGNORECASE)
SUB_RE = re.compile(r'^\s*(?:PURE\s+|ELEMENTAL\s+|RECURSIVE\s+)*SUBROUTINE\s+(\w+)', re.IGNORECASE)
FUNC_RE = re.compile(r'^\s*(?:(?:PURE|ELEMENTAL|RECURSIVE)\s+)*(?:(?:INTEGER|REAL|LOGICAL|CHARACTER|DOUBLE\s+PRECISION|TYPE|CLASS)\s*(?:\([^)]*\))?\s+)?FUNCTION\s+(\w+)', re.IGNORECASE)
PUBLIC_RE = re.compile(r'^\s*PUBLIC\s*::\s*(.+)', re.IGNORECASE)
PUBLIC_BARE_RE = re.compile(r'^\s*PUBLIC\s*$', re.IGNORECASE)
PRIVATE_DEFAULT_RE = re.compile(r'^\s*PRIVATE\s*$', re.IGNORECASE)
TBP_RE = re.compile(r'^\s*PROCEDURE\s*(?:\([^)]*\))?\s*(?:,\s*\w+)*\s*::\s*(\w+)', re.IGNORECASE)
GENERIC_RE = re.compile(r'^\s*GENERIC\s*(?:,\s*\w+)*\s*::\s*(\w+)\s*=>', re.IGNORECASE)
END_TYPE_RE = re.compile(r'^\s*END\s+TYPE', re.IGNORECASE)
CONTAINS_RE = re.compile(r'^\s*CONTAINS\s*$', re.IGNORECASE)


def classify_func_set(name):
    for fs, pat in FUNC_SET_PATTERNS.items():
        if pat.search(name):
            return fs
    return "—"


def scan_f90(filepath):
    """Scan a .f90 file and return structured info per module."""
    modules = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception:
        return modules

    current_mod = None
    in_type = False
    in_contains = False

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('!'):
            continue

        m = MODULE_RE.match(stripped)
        if m:
            current_mod = {
                "name": m.group(1),
                "types": [],
                "procedures": [],
                "publics": set(),
                "private_default": False,
            }
            in_contains = False
            modules.append(current_mod)
            continue

        if END_MODULE_RE.match(stripped):
            current_mod = None
            in_contains = False
            continue

        if current_mod is None:
            continue

        if CONTAINS_RE.match(stripped):
            in_contains = True
            continue

        if PRIVATE_DEFAULT_RE.match(stripped) and not in_type:
            current_mod["private_default"] = True
            continue

        m = PUBLIC_RE.match(stripped)
        if m:
            names = [n.strip().rstrip('&') for n in m.group(1).split(',')]
            current_mod["publics"].update(n for n in names if n)
            continue

        m = TYPE_DEF_RE.match(stripped) or TYPE_EXT_RE.match(stripped)
        if m and not in_contains:
            type_name = m.group(1)
            if type_name.upper() not in ('NONE',):
                current_mod["types"].append(type_name)
                in_type = True
            continue

        if in_type:
            if END_TYPE_RE.match(stripped):
                in_type = False
                continue
            m = TBP_RE.match(stripped)
            if m:
                current_mod["procedures"].append({"name": m.group(1), "kind": "TBP"})
            m = GENERIC_RE.match(stripped)
            if m:
                current_mod["procedures"].append({"name": m.group(1), "kind": "GENERIC"})
            continue

        m = SUB_RE.match(stripped)
        if m:
            current_mod["procedures"].append({"name": m.group(1), "kind": "SUB"})
            continue

        m = FUNC_RE.match(stripped)
        if m:
            current_mod["procedures"].append({"name": m.group(1), "kind": "FN"})
            continue

    return modules


def generate_inventory_for_dir(target_dir, exclude_subdirs=None):
    """Generate inventory rows for f90 files in target_dir."""
    exclude_subdirs = set(exclude_subdirs or [])
    f90_files = []
    for root, dirs, files in os.walk(target_dir):
        rel = os.path.relpath(root, target_dir).replace("\\", "/")
        top_dir = rel.split("/")[0] if rel != "." else ""
        if top_dir in exclude_subdirs:
            continue
        skip = {"contracts", "Tests", "tests", "__pycache__", ".git"}
        dirs[:] = [d for d in dirs if d not in skip]
        for f in sorted(files):
            if f.endswith(".f90"):
                f90_files.append(os.path.join(root, f))

    f90_files.sort(key=lambda p: os.path.relpath(p, target_dir))
    if not f90_files:
        return []

    rows = []
    for fpath in f90_files:
        relpath = os.path.relpath(fpath, target_dir).replace("\\", "/")
        modules = scan_f90(fpath)

        if not modules:
            rows.append(f"| `{relpath}` | — | — | — |")
            continue

        for mod in modules:
            types_str = ", ".join(f"`{t}`" for t in mod["types"]) if mod["types"] else "—"

            procs_parts = []
            for p in mod["procedures"]:
                vis = "PUB"
                if mod["private_default"] and p["name"] not in mod["publics"]:
                    vis = "PRV"
                func_set = classify_func_set(p["name"])
                procs_parts.append(f"`{p['name']}` ({p['kind']},{vis},{func_set})")

            procs_str = "; ".join(procs_parts) if procs_parts else "—"
            rows.append(f"| `{relpath}` | `{mod['name']}` | {types_str} | {procs_str} |")

    return rows


def find_all_contracts(ufc_core):
    """Find all CONTRACT.md files and return (contract_path, dir_path, display_name)."""
    contracts = []
    for root, dirs, files in os.walk(ufc_core):
        skip = {"contracts", "Tests", "tests", "__pycache__", ".git"}
        dirs[:] = [d for d in dirs if d not in skip]
        if "CONTRACT.md" in files:
            display = os.path.relpath(root, ufc_core).replace("\\", "/")
            contracts.append((os.path.join(root, "CONTRACT.md"), root, display))
    contracts.sort(key=lambda x: x[2])
    return contracts


def get_child_contract_dirs(parent_dir, ufc_core):
    """Get immediate subdirectories that have their own CONTRACT.md."""
    children = []
    for item in os.listdir(parent_dir):
        child_path = os.path.join(parent_dir, item)
        if os.path.isdir(child_path) and os.path.exists(os.path.join(child_path, "CONTRACT.md")):
            children.append(item)
    return children


def process_contract(contract_path, dir_path, display_name, ufc_core, dry_run=False):
    """Process a single CONTRACT.md."""
    with open(contract_path, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    if "细粒度子程序清单" in content or "细粒度清单" in content:
        return "SKIP_EXISTS"

    child_contract_dirs = get_child_contract_dirs(dir_path, ufc_core)
    rows = generate_inventory_for_dir(dir_path, exclude_subdirs=child_contract_dirs)

    if not rows:
        section = "\n\n---\n\n### 细粒度子程序清单\n\n> 本域暂无 .f90 文件（或全部归属子域 CONTRACT）。\n"
    else:
        section = "\n\n---\n\n### 细粒度子程序清单\n\n"
        section += "| 文件 | MODULE | TYPE（PUBLIC） | 过程 / TBP |\n"
        section += "|------|--------|---------------|------------|\n"
        section += "\n".join(rows) + "\n"

    if dry_run:
        return f"WOULD_APPEND ({len(rows)} rows, excl children: {child_contract_dirs or 'none'})"

    with open(contract_path, 'a', encoding='utf-8') as f:
        f.write(section)

    return f"APPENDED ({len(rows)} rows)"


def main():
    dry_run = "--dry-run" in sys.argv

    contracts = find_all_contracts(UFC_CORE)
    results = defaultdict(list)

    for contract_path, dir_path, display in contracts:
        status = process_contract(contract_path, dir_path, display, UFC_CORE, dry_run)
        key = status.split(" ")[0]
        results[key].append(f"{display}: {status}")

    print("=" * 72)
    print(f"UFC 细粒度子程序清单生成报告 ({'DRY RUN' if dry_run else 'LIVE'})")
    print("=" * 72)
    print(f"\nCONTRACT.md 总数: {len(contracts)}")

    for key in ["APPENDED", "WOULD_APPEND", "SKIP_EXISTS", "SKIP_NO_CONTRACT"]:
        items = results.get(key, [])
        if items:
            print(f"\n### {key} ({len(items)})")
            for item in items:
                print(f"  {item}")

    print("\n" + "=" * 72)


if __name__ == "__main__":
    main()
