#!/usr/bin/env python3
"""
TYPE Sync Audit: Compare CONTRACT §2 TYPE declarations with actual .f90 TYPE definitions.
Produces a per-domain report of MISSING, MATCHED, and EXTRA types.
"""
import os, re, json, glob

UFC_ROOT = r"d:\TEST7\UFC\ufc_core"
LAYERS = ["L3_MD", "L4_PH", "L5_RT"]

def find_domains():
    """Find all domains (layer/domain pairs) that have CONTRACT.md."""
    domains = []
    for layer in LAYERS:
        layer_path = os.path.join(UFC_ROOT, layer)
        if not os.path.isdir(layer_path):
            continue
        for entry in sorted(os.listdir(layer_path)):
            dom_path = os.path.join(layer_path, entry)
            contract = os.path.join(dom_path, "CONTRACT.md")
            if os.path.isdir(dom_path) and os.path.isfile(contract):
                domains.append((layer, entry, dom_path))
    return domains

def extract_contract_types(contract_path):
    """Extract TYPE names declared in CONTRACT §2 section."""
    with open(contract_path, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()
    
    # Find §2 section (various formats: §2, ## 2, §二, ## §2, etc.)
    # Look for section about TYPEs
    types = set()
    lines = content.split('\n')
    in_type_section = False
    section_depth = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Detect TYPE section start (§2 or §二 or §三 with TYPE keyword or "TYPE" in header)
        if re.match(r'^#{1,3}\s*§?\s*[2二三]', stripped) or \
           re.match(r'^#{1,3}\s*.*TYPE', stripped, re.IGNORECASE):
            if 'TYPE' in stripped.upper() or '类型' in stripped or '型' in stripped:
                in_type_section = True
                section_depth = len(re.match(r'^(#+)', stripped).group(1)) if stripped.startswith('#') else 2
                continue
        
        # Detect next major section (exit TYPE section)
        if in_type_section and stripped.startswith('#'):
            hdr_match = re.match(r'^(#+)', stripped)
            if hdr_match and len(hdr_match.group(1)) <= section_depth:
                # Check if it's a subsection within TYPE section
                if not ('TYPE' in stripped.upper() or 'Desc' in stripped or 'State' in stripped or 
                        'Algo' in stripped or 'Ctx' in stripped or '四型' in stripped):
                    in_type_section = False
                    continue
        
        if not in_type_section:
            continue
        
        # Extract TYPE names from backtick references in the TYPE section
        # Pattern: `TypeName` - typically PascalCase or has underscore prefix
        backtick_refs = re.findall(r'`([A-Z][A-Za-z0-9_]+)`', stripped)
        for ref in backtick_refs:
            # Filter: must look like a TYPE name (not a file, module, or subroutine)
            # Skip if it ends with .f90 or .md
            if ref.endswith('.f90') or ref.endswith('.md'):
                continue
            # Skip if it looks like a subroutine name (verb patterns)
            if any(ref.startswith(p) for p in ['Init_', 'Set_', 'Get_', 'Compute_', 'Apply_', 
                                                  'Reset_', 'Update_', 'Build_', 'Create_',
                                                  'Destroy_', 'Print_', 'Write_', 'Read_',
                                                  'Register_', 'Ensure_', 'Validate_']):
                continue
            # Skip if looks like a module name (ends with _Mod or _Module)  
            if ref.endswith('_Mod') or ref.endswith('_Module'):
                continue
            # Keep if it matches TYPE naming patterns
            if '_Desc' in ref or '_State' in ref or '_Algo' in ref or '_Ctx' in ref or \
               '_Type' in ref or '_Config' in ref or '_Params' in ref or '_Domain' in ref or \
               '_Cache' in ref or '_Buffer' in ref or '_Base' in ref or \
               ref.endswith('Status') or ref.endswith('Record') or ref.endswith('Entry') or \
               ref.endswith('Logger') or ref.endswith('Config') or \
               '_Bridge_' in ref or 'Bridge_Ctx' in ref:
                types.add(ref)
                continue
            # Also check if the line has TYPE-indicating context
            if '定义于' in stripped or 'TYPE' in stripped or '::' in stripped or \
               '类型' in stripped or 'type' in stripped.lower():
                # More likely a TYPE reference
                if not any(ref.startswith(p) for p in ['IF_', 'USE_']):
                    types.add(ref)
        
        # Also extract from table rows: | `TypeName` | ... |
        table_match = re.match(r'^\|\s*`([A-Z][A-Za-z0-9_]+)`\s*\|', stripped)
        if table_match:
            tname = table_match.group(1)
            if not tname.endswith('.f90') and not tname.endswith('.md'):
                types.add(tname)
        
        # Extract from bullet points: - `TypeName` or - **`TypeName`**
        bullet_match = re.match(r'^[-*]\s+\*{0,2}`([A-Z][A-Za-z0-9_]+)`', stripped)
        if bullet_match:
            tname = bullet_match.group(1)
            if not tname.endswith('.f90') and not tname.endswith('.md'):
                types.add(tname)
    
    return types

def find_f90_types_in_dir(domain_path):
    """Find all TYPE definitions in .f90 files within a domain directory (recursive)."""
    types_by_file = {}  # type_name -> file_path
    
    for root, dirs, files in os.walk(domain_path):
        for fname in files:
            if fname.endswith('.f90'):
                fpath = os.path.join(root, fname)
                try:
                    with open(fpath, 'r', encoding='utf-8', errors='replace') as f:
                        for line in f:
                            # Match: TYPE[, PUBLIC] :: TypeName
                            m = re.match(r'\s*TYPE\s*(?:,\s*(?:PUBLIC|PRIVATE))?\s*::\s*(\w+)', 
                                        line, re.IGNORECASE)
                            if m:
                                tname = m.group(1)
                                rel_path = os.path.relpath(fpath, domain_path).replace('\\', '/')
                                types_by_file[tname] = rel_path
                except:
                    pass
    
    return types_by_file

def main():
    domains = find_domains()
    results = {}
    total_matched = 0
    total_missing = 0
    total_extra_contract = 0
    
    for layer, domain, dom_path in domains:
        contract_path = os.path.join(dom_path, "CONTRACT.md")
        key = f"{layer}/{domain}"
        
        contract_types = extract_contract_types(contract_path)
        code_types = find_f90_types_in_dir(dom_path)
        
        if not contract_types and not code_types:
            continue
        
        # Find _Def.f90 types specifically
        def_types = {t: f for t, f in code_types.items() if '_Def' in f}
        non_def_types = {t: f for t, f in code_types.items() if '_Def' not in f}
        
        matched = []
        case_a = []  # In code but not in _Def.f90
        case_missing = []  # In contract but not in any code
        
        for ct in sorted(contract_types):
            if ct in def_types:
                matched.append({"type": ct, "file": def_types[ct]})
            elif ct in non_def_types:
                case_a.append({"type": ct, "file": non_def_types[ct]})
            else:
                case_missing.append(ct)
        
        # Types in _Def.f90 but not in CONTRACT
        undocumented_def = []
        for t, f in sorted(def_types.items()):
            if t not in contract_types:
                undocumented_def.append({"type": t, "file": f})
        
        if contract_types or code_types:
            results[key] = {
                "contract_count": len(contract_types),
                "contract_types": sorted(contract_types),
                "matched": matched,
                "case_a_in_non_def": case_a,
                "missing_from_code": case_missing,
                "undocumented_in_def": undocumented_def,
                "all_code_types_count": len(code_types)
            }
            total_matched += len(matched)
            total_missing += len(case_missing)
            total_extra_contract += len(case_a)
    
    # Output
    out_path = r"d:\TEST7\UFC\REPORTS\TYPE_Sync_v3.json"
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    # Write text report
    rpt_path = r"d:\TEST7\UFC\REPORTS\TYPE_Sync_v3_output.txt"
    with open(rpt_path, 'w', encoding='utf-8') as rpt:
        rpt.write(f"=== TYPE Sync Audit Summary ===\n")
        rpt.write(f"Domains analyzed: {len(results)}\n")
        rpt.write(f"Total matched (in _Def.f90): {total_matched}\n")
        rpt.write(f"Total Case A (in non-_Def): {total_extra_contract}\n")
        rpt.write(f"Total missing from code: {total_missing}\n")
        rpt.write(f"\n--- Per-domain details ---\n")
        for key, data in sorted(results.items()):
            if data['missing_from_code'] or data['case_a_in_non_def'] or data['undocumented_in_def']:
                rpt.write(f"\n{key}: (CONTRACT={data['contract_count']}, code_total={data['all_code_types_count']})\n")
                if data['case_a_in_non_def']:
                    rpt.write(f"  Case A (non-_Def):\n")
                    for item in data['case_a_in_non_def']:
                        rpt.write(f"    {item['type']} -> {item['file']}\n")
                if data['missing_from_code']:
                    rpt.write(f"  MISSING from code:\n")
                    for t in data['missing_from_code']:
                        rpt.write(f"    {t}\n")
                if data['undocumented_in_def']:
                    rpt.write(f"  Undocumented in _Def:\n")
                    for item in data['undocumented_in_def']:
                        rpt.write(f"    {item['type']} ({item['file']})\n")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        err_path = r'd:\TEST7\UFC\REPORTS\type_sync_error.txt'
        with open(err_path, 'w') as f:
            import traceback
            traceback.print_exc(file=f)
        raise
