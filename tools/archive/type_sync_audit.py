#!/usr/bin/env python3
"""
TYPE Consistency Audit: Compare CONTRACT.md TYPE declarations with _Def.f90 definitions.
Scans L3_MD, L4_PH, L5_RT layers.
"""
import os
import re
import json
from pathlib import Path

UFC_ROOT = Path(r"d:\TEST7\UFC\ufc_core")

def find_types_in_f90(filepath):
    """Extract TYPE names from a .f90 file (PUBLIC types)."""
    types = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        # Match TYPE, PUBLIC :: TypeName or TYPE :: TypeName
        for m in re.finditer(r'TYPE\s*(?:,\s*PUBLIC)?\s*::\s*(\w+)', content, re.IGNORECASE):
            types.append(m.group(1))
    except:
        pass
    return types

def find_types_in_all_f90(domain_dir):
    """Find all TYPE definitions in all .f90 files in domain dir (recursive)."""
    result = {}  # type_name -> filepath
    for root, dirs, files in os.walk(domain_dir):
        for f in files:
            if f.endswith('.f90'):
                fp = os.path.join(root, f)
                types = find_types_in_f90(fp)
                for t in types:
                    result[t] = os.path.relpath(fp, domain_dir)
    return result

def find_types_in_def_files(domain_dir):
    """Find all TYPE definitions in *_Def.f90 files in domain dir."""
    result = {}
    for root, dirs, files in os.walk(domain_dir):
        for f in files:
            if f.endswith('_Def.f90'):
                fp = os.path.join(root, f)
                types = find_types_in_f90(fp)
                for t in types:
                    result[t] = os.path.relpath(fp, domain_dir)
    return result

def extract_contract_types(contract_path):
    """Extract TYPE names from CONTRACT.md §2 (TYPE section)."""
    types = []
    try:
        with open(contract_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        # Find TYPE names in table rows: | `TypeName` | or | TypeName |
        # Also match TYPE names in various formats
        # Pattern 1: table cells with backtick-wrapped type names
        for m in re.finditer(r'\|\s*`?([A-Z][A-Za-z0-9_]+(?:_(?:Desc|State|Algo|Ctx|Type|Domain|Arg|Params|Config))?)`?\s*\|', content):
            name = m.group(1)
            # Filter out obvious non-TYPE entries
            if not any(x in name.lower() for x in ['module', 'file', 'subroutine', 'function', 'sub', 'fun', 'init', 'finalize']):
                if re.match(r'^[A-Z][A-Za-z0-9_]+_(?:Desc|State|Algo|Ctx|Type|Domain|Arg|Params|Config|Model|Properties|Cfg|Def)$', name) or \
                   re.match(r'^(?:MD|PH|RT|NM|IF)_\w+$', name):
                    types.append(name)
        # Pattern 2: TYPE names mentioned as `TypeName` in text
        for m in re.finditer(r'`((?:MD|PH|RT|NM|IF)_[A-Za-z0-9_]+)`', content):
            name = m.group(1)
            if name not in types and not any(x in name for x in ['_Init', '_Finalize', '_Query', '_Compute', '_Apply', '_Get', '_Set']):
                # Only include if it looks like a TYPE (Desc/State/Algo/Ctx/Type/Domain suffix)
                if re.search(r'_(?:Desc|State|Algo|Ctx|Type|Domain|Arg|Params|Config|Properties|Cfg|Model)$', name):
                    types.append(name)
    except:
        pass
    return list(set(types))

def audit_domain(layer, domain, domain_dir, contract_path):
    """Audit a single domain."""
    contract_types = extract_contract_types(contract_path)
    def_types = find_types_in_def_files(domain_dir)
    all_types = find_types_in_all_f90(domain_dir)
    
    missing = []
    found_elsewhere = []
    found_in_def = []
    
    for t in contract_types:
        if t in def_types:
            found_in_def.append(t)
        elif t in all_types:
            found_elsewhere.append((t, all_types[t]))
        else:
            missing.append(t)
    
    undocumented_in_def = [t for t in def_types if t not in contract_types]
    
    return {
        'layer': layer,
        'domain': domain,
        'contract_path': str(contract_path),
        'domain_dir': str(domain_dir),
        'contract_types': sorted(contract_types),
        'def_types': sorted(def_types.keys()),
        'found_in_def': sorted(found_in_def),
        'found_elsewhere': sorted(found_elsewhere, key=lambda x: x[0]),
        'missing': sorted(missing),
        'undocumented_in_def': sorted(undocumented_in_def),
        'all_types_map': {k: v for k, v in sorted(all_types.items())},
    }

def main():
    results = []
    
    # Scan all domains with CONTRACT.md in L3/L4/L5
    for layer in ['L3_MD', 'L4_PH', 'L5_RT']:
        layer_dir = UFC_ROOT / layer
        if not layer_dir.exists():
            continue
        for root, dirs, files in os.walk(layer_dir):
            if 'CONTRACT.md' in files:
                contract_path = Path(root) / 'CONTRACT.md'
                domain_dir = Path(root)
                # Determine domain name
                rel = domain_dir.relative_to(layer_dir)
                domain = str(rel).replace('\\', '/')
                
                result = audit_domain(layer, domain, domain_dir, contract_path)
                if result['missing'] or result['found_elsewhere'] or result['undocumented_in_def']:
                    results.append(result)
    
    # Print summary
    total_missing = 0
    total_elsewhere = 0
    total_undocumented = 0
    
    print("=" * 80)
    print("TYPE CONSISTENCY AUDIT REPORT")
    print("=" * 80)
    
    for r in results:
        if not r['missing'] and not r['found_elsewhere']:
            continue
        print(f"\n--- {r['layer']}/{r['domain']} ---")
        print(f"  CONTRACT types: {len(r['contract_types'])}")
        print(f"  _Def.f90 types: {len(r['def_types'])}")
        print(f"  Found in _Def: {len(r['found_in_def'])}")
        if r['found_elsewhere']:
            print(f"  Found elsewhere ({len(r['found_elsewhere'])}):")
            for t, loc in r['found_elsewhere']:
                print(f"    - {t} -> {loc}")
            total_elsewhere += len(r['found_elsewhere'])
        if r['missing']:
            print(f"  MISSING ({len(r['missing'])}):")
            for t in r['missing']:
                print(f"    - {t}")
            total_missing += len(r['missing'])
        if r['undocumented_in_def']:
            print(f"  Undocumented in _Def ({len(r['undocumented_in_def'])}):")
            for t in r['undocumented_in_def']:
                print(f"    - {t}")
            total_undocumented += len(r['undocumented_in_def'])
    
    print(f"\n{'=' * 80}")
    print(f"TOTALS: MISSING={total_missing}, FOUND_ELSEWHERE={total_elsewhere}, UNDOCUMENTED={total_undocumented}")
    print(f"{'=' * 80}")
    
    # Save JSON
    out_path = Path(r"d:\TEST7\UFC\REPORTS\TYPE_Sync_Audit.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False, default=str)
    print(f"\nDetailed JSON saved to: {out_path}")

if __name__ == '__main__':
    main()
