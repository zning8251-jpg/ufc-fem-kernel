#!/usr/bin/env python3
"""
TYPE Sync v2: Extract TYPEs from CONTRACT.md table rows in §2/§三 TYPE sections,
compare with _Def.f90 definitions and all .f90 definitions.
"""
import os, re, json
from pathlib import Path

UFC = Path(r"d:\TEST7\UFC\ufc_core")

def get_f90_types(dirpath, pattern="*.f90"):
    """Get all TYPE definitions from .f90 files, returns {type_name: relpath}"""
    result = {}
    for root, dirs, files in os.walk(dirpath):
        for f in files:
            if f.endswith('.f90'):
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='ignore') as fh:
                        for line in fh:
                            m = re.match(r'\s*TYPE\s*(?:,\s*PUBLIC)?\s*::\s*(\w+)', line, re.IGNORECASE)
                            if m:
                                result[m.group(1)] = os.path.relpath(fp, dirpath)
                except: pass
    return result

def get_def_types(dirpath):
    """Get TYPE definitions only from *_Def.f90 files"""
    result = {}
    for root, dirs, files in os.walk(dirpath):
        for f in files:
            if f.endswith('_Def.f90'):
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='ignore') as fh:
                        for line in fh:
                            m = re.match(r'\s*TYPE\s*(?:,\s*PUBLIC)?\s*::\s*(\w+)', line, re.IGNORECASE)
                            if m:
                                result[m.group(1)] = os.path.relpath(fp, dirpath)
                except: pass
    return result

def extract_contract_type_names(contract_path):
    """Extract TYPE names from CONTRACT.md TYPE section table rows.
    Looks for table rows with backtick-wrapped names that look like TYPE definitions.
    """
    types = set()
    try:
        with open(contract_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Find sections about TYPE (§2, §三, TYPE 清单, etc.)
        # Extract TYPE names from table rows: | `TypeName` | module | ... |
        # Pattern: table row starting with |, containing a backtick-wrapped name
        lines = content.split('\n')
        in_type_section = False
        for line in lines:
            # Detect TYPE section headers
            if re.match(r'#+\s*(?:\d+[\.\s]*|[一二三四五六七八九十]+[\.\s]*)?.*(?:TYPE|四[型类]|清单)', line, re.IGNORECASE):
                in_type_section = True
                continue
            # Detect next major section header (exit TYPE section)
            if in_type_section and re.match(r'#+\s*(?:\d+[\.\s]*|[一二三四五六七八九十]+[\.\s]*)?.*(?:功能|接口|职责|文件|跨层|域间|约束|验收|错误|变更|版本)', line):
                in_type_section = False
                continue
            if re.match(r'^---\s*$', line):
                if in_type_section:
                    in_type_section = False
                continue
            
            if not in_type_section:
                continue
            
            # Extract TYPE names from table rows
            if '|' in line and not line.strip().startswith('|---'):
                # Look for backtick-wrapped names
                for m in re.finditer(r'`([A-Z][A-Za-z0-9_]+)`', line):
                    name = m.group(1)
                    # Filter: must look like a TYPE name (Fortran-style naming)
                    if re.match(r'^(?:MD|PH|RT|NM|IF|KW)_\w+$', name):
                        # Exclude obvious non-TYPE names
                        if not any(suf in name for suf in ['_Init', '_Finalize', '_Query', '_Compute',
                            '_Apply', '_Get', '_Set', '_Register', '_Validate', '_Check',
                            '_Update', '_Populate', '_Sync', '_Map', '_Run', '_Build',
                            '_Write', '_Read', '_Open', '_Close', '_Save', '_Load',
                            '_Reset', '_Clear', '_Copy', '_From', '_To', '_Impl',
                            '_Proc', '_Brg', '_Core', '_Mgr', '_Ops', '_Eval',
                            '_Dispatch', '_Route', '_Sort']):
                            types.add(name)
                
                # Also extract non-backtick names in first column of TYPE tables
                cols = [c.strip() for c in line.split('|')]
                if len(cols) >= 3:
                    # Second column (after leading |) might be TYPE name
                    for col in cols[1:3]:
                        col = col.strip('`').strip()
                        if re.match(r'^(?:MD|PH|RT|NM|IF|KW)_[A-Za-z0-9_]+$', col):
                            if not any(suf in col for suf in ['_Init', '_Finalize', '_Query', '_Compute',
                                '_Apply', '_Get', '_Set', '_Register', '_Validate']):
                                types.add(col)
    except Exception as e:
        print(f"Error parsing {contract_path}: {e}")
    return types

def main():
    results = []
    stat_a = stat_b = stat_c = 0
    
    for layer in ['L3_MD', 'L4_PH', 'L5_RT']:
        layer_dir = UFC / layer
        if not layer_dir.exists(): continue
        for root, dirs, files in os.walk(layer_dir):
            if 'CONTRACT.md' not in files: continue
            contract_path = Path(root) / 'CONTRACT.md'
            domain_dir = Path(root)
            rel = domain_dir.relative_to(layer_dir)
            domain = str(rel).replace('\\', '/')
            
            contract_types = extract_contract_type_names(contract_path)
            def_types = get_def_types(domain_dir)
            all_types = get_f90_types(domain_dir)
            
            missing_from_def = []
            found_elsewhere = []
            found_in_def = []
            
            for t in sorted(contract_types):
                if t in def_types:
                    found_in_def.append(t)
                elif t in all_types:
                    found_elsewhere.append((t, all_types[t]))
                else:
                    # Check parent directories too (sometimes types are in parent _Def files)
                    # Also check across the whole layer
                    layer_types = get_f90_types(layer_dir)
                    if t in layer_types:
                        found_elsewhere.append((t, f"../{layer_types[t]}"))
                    else:
                        missing_from_def.append(t)
            
            if missing_from_def or found_elsewhere:
                entry = {
                    'layer': layer, 'domain': domain,
                    'contract_types': sorted(contract_types),
                    'found_in_def': found_in_def,
                    'found_elsewhere': found_elsewhere,
                    'missing': missing_from_def,
                }
                results.append(entry)
                
                print(f"\n=== {layer}/{domain} ===")
                print(f"  CONTRACT types ({len(contract_types)}): {sorted(contract_types)}")
                if found_elsewhere:
                    for t, loc in found_elsewhere:
                        print(f"  [A] {t} -> defined in {loc}")
                        stat_a += 1
                if missing_from_def:
                    for t in missing_from_def:
                        print(f"  [?] {t} -> NOT FOUND anywhere")
                        stat_b += 1
    
    print(f"\n{'='*60}")
    print(f"SUMMARY: Found_elsewhere(A)={stat_a}, Missing(B/C)={stat_b}")
    print(f"{'='*60}")
    
    with open(UFC.parent / 'REPORTS' / 'TYPE_Sync_v2.json', 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    main()
