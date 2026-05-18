#!/usr/bin/env python3
"""Precise TYPE audit: extract types from CONTRACT table rows only, compare with all .f90 TYPE definitions."""
import os, re, json

UFC = r"d:\TEST7\UFC\ufc_core"
LAYERS = ["L3_MD", "L4_PH", "L5_RT"]

def scan_all_f90_types():
    """Scan all .f90 files for TYPE :: definitions. Returns {type_name: [(rel_path, layer/domain)]}"""
    types = {}
    for layer in LAYERS:
        lp = os.path.join(UFC, layer)
        if not os.path.isdir(lp): continue
        for root, dirs, files in os.walk(lp):
            for f in files:
                if not f.endswith('.f90'): continue
                fp = os.path.join(root, f)
                rel = os.path.relpath(fp, UFC).replace('\\','/')
                try:
                    with open(fp, 'r', encoding='utf-8', errors='replace') as fh:
                        for line in fh:
                            m = re.match(r'\s*TYPE\s*(?:,\s*(?:PUBLIC|PRIVATE))?\s*::\s*(\w+)', line, re.IGNORECASE)
                            if m:
                                tn = m.group(1)
                                types.setdefault(tn, []).append(rel)
                except: pass
    return types

def find_contracts():
    """Find all CONTRACT.md files in L3/L4/L5."""
    contracts = []
    for layer in LAYERS:
        lp = os.path.join(UFC, layer)
        if not os.path.isdir(lp): continue
        for root, dirs, files in os.walk(lp):
            if 'CONTRACT.md' in files:
                fp = os.path.join(root, 'CONTRACT.md')
                rel_dom = os.path.relpath(root, UFC).replace('\\','/')
                contracts.append((rel_dom, fp))
    return contracts

def extract_contract_table_types(contract_path):
    """Extract TYPE names from table rows in §2/§三 TYPE sections of CONTRACT.md."""
    with open(contract_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    
    types = []
    in_type_section = False
    
    for i, line in enumerate(lines):
        s = line.strip()
        
        # Detect TYPE section headers
        if re.match(r'^#{1,3}\s*(?:§?\s*)?[2二三][\.\s].*(?:TYPE|型)', s, re.IGNORECASE) or \
           re.match(r'^#{1,3}\s*(?:§?\s*)?[2二三][\.\s]', s) and ('TYPE' in s or '型' in s):
            in_type_section = True
            continue
        
        # Also detect subsection headers like ### 2.1 Desc, ### 3.1 etc.
        if re.match(r'^#{1,4}\s*(?:\d+\.)?[1-9]', s) and in_type_section:
            # Still in type section subsections
            continue
        
        # Exit type section on next major section
        if in_type_section and re.match(r'^#{1,3}\s*(?:§?\s*)?[3-9四五六七八九十][\.\s]', s):
            if not ('TYPE' in s or '型' in s or 'Desc' in s or 'State' in s or 'Algo' in s or 'Ctx' in s):
                in_type_section = False
                continue
        
        if not in_type_section:
            continue
        
        # Extract from table rows: | `TypeName` | ... |
        # Skip header/separator rows
        if s.startswith('|') and not s.startswith('|---') and not s.startswith('| TYPE 名') and not s.startswith('| 四型'):
            # Extract first backtick-quoted name in the row
            m = re.search(r'`([A-Z][A-Za-z0-9_]+)`', s)
            if m:
                tn = m.group(1)
                # Filter out obvious non-TYPE names
                if tn.endswith('.f90') or tn.endswith('.md'): continue
                if tn.startswith('MODULE_'): continue
                # Likely a TYPE name
                types.append((tn, i+1))  # name, line number
        
        # Also extract from bullet points referencing types
        # - **N/A** patterns should be skipped
        if s.startswith('-') and '`' in s and 'N/A' not in s and '(无' not in s and '(隐式)' not in s and '(内嵌)' not in s and '(委托)' not in s:
            m = re.search(r'`([A-Z][A-Za-z0-9_]+)`', s)
            if m:
                tn = m.group(1)
                if tn.endswith('.f90') or tn.endswith('.md'): continue
                if tn.startswith('MODULE_'): continue
                # Only include if it looks like a TYPE reference in context
                ctx = s.lower()
                if 'type' in ctx or 'desc' in tn or 'state' in tn or 'algo' in tn or 'ctx' in tn or \
                   'domain' in tn or 'config' in tn or 'params' in tn:
                    types.append((tn, i+1))
        
        # Extract from "附加" lines
        if '附加' in s and '`' in s:
            for m in re.finditer(r'`([A-Z][A-Za-z0-9_]+)`', s):
                tn = m.group(1)
                if tn.endswith('.f90') or tn.endswith('.md'): continue
                types.append((tn, i+1))
    
    return types

def main():
    code_types = scan_all_f90_types()
    contracts = find_contracts()
    
    results = {}
    total_a = 0
    total_b = 0
    total_matched = 0
    
    for dom_path, contract_fp in sorted(contracts):
        ctypes = extract_contract_table_types(contract_fp)
        if not ctypes:
            continue
        
        matched = []
        case_a = []  # defined in non-_Def file 
        case_b = []  # truly missing from all code
        
        for tname, linenum in ctypes:
            if tname in code_types:
                files = code_types[tname]
                # Check if any is a _Def file within the same domain
                dom_def_files = [f for f in files if '_Def' in f and dom_path.split('/')[0] in f]
                if dom_def_files:
                    matched.append({"type": tname, "line": linenum, "file": dom_def_files[0]})
                else:
                    case_a.append({"type": tname, "line": linenum, "files": files})
            else:
                case_b.append({"type": tname, "line": linenum})
        
        results[dom_path] = {
            "contract": os.path.relpath(contract_fp, UFC).replace('\\','/'),
            "declared": len(ctypes),
            "matched_def": len(matched),
            "case_a_non_def": len(case_a),
            "case_b_missing": len(case_b),
            "matched": matched,
            "case_a": case_a,
            "case_b": case_b
        }
        total_matched += len(matched)
        total_a += len(case_a)
        total_b += len(case_b)
    
    # Output
    out = r"d:\TEST7\UFC\REPORTS\TYPE_Sync_Precise.json"
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    rpt = r"d:\TEST7\UFC\REPORTS\TYPE_Sync_Precise.txt"
    with open(rpt, 'w', encoding='utf-8') as f:
        f.write(f"=== Precise TYPE Audit ===\n")
        f.write(f"Total declared in CONTRACTs: {total_matched + total_a + total_b}\n")
        f.write(f"Matched (in _Def.f90): {total_matched}\n")
        f.write(f"Case A (in non-_Def code): {total_a}\n")
        f.write(f"Case B (truly missing): {total_b}\n\n")
        
        for dp, data in sorted(results.items()):
            if data['case_a'] or data['case_b']:
                f.write(f"\n{'='*60}\n")
                f.write(f"{dp}: declared={data['declared']}, matched={data['matched_def']}, A={data['case_a_non_def']}, B={data['case_b_missing']}\n")
                if data['case_a']:
                    f.write(f"  Case A (in non-_Def):\n")
                    for item in data['case_a']:
                        f.write(f"    L{item['line']}: {item['type']} -> {', '.join(item['files'])}\n")
                if data['case_b']:
                    f.write(f"  Case B (MISSING from all code):\n")
                    for item in data['case_b']:
                        f.write(f"    L{item['line']}: {item['type']}\n")

if __name__ == '__main__':
    main()
