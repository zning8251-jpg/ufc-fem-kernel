"""Split MD_Model_Data.f90 -> _Def.f90 and _Proc.f90
   Split MD_Model_Lib.f90 -> _Lib.f90 (core) + _VarCtx.f90
"""
import re, os

def get_module_ranges(lines):
    """Find all MODULE/END MODULE pairs in the file."""
    modules = []
    for i, line in enumerate(lines):
        m = re.match(r'^\s*MODULE\s+(\w+)', line)
        if m:
            mod_name = m.group(1)
            end_pat = re.compile(r'^\s*END\s+MODULE\s+' + re.escape(mod_name))
            for j in range(i, len(lines)):
                if end_pat.match(lines[j]):
                    modules.append((mod_name, i, j))
                    break
    return modules

def extract_doc_header(lines, mod_start):
    """Go backwards from mod_start to find all doc comment lines."""
    doc_start = mod_start
    while doc_start > 0:
        prev = lines[doc_start - 1].strip()
        if prev == '' or prev.startswith('!') or prev.startswith('!>'):
            doc_start -= 1
        else:
            break
    return doc_start

def split_md_model_data():
    filepath = r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data.f90'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    modules = get_module_ranges(lines)
    print(f"MD_Model_Data.f90: {len(modules)} modules found")
    for n, s, e in modules:
        print(f"  {n}: lines {s+1}-{e+1}")
    
    type_mods = []
    proc_mods = []
    first = True
    for n, s, e in modules:
        if n == 'MD_Model_Data' and first:
            type_mods.append((n, s, e))
            first = False
        elif n.endswith('_Type'):
            type_mods.append((n, s, e))
        elif n.endswith('_Parse') or n.endswith('_Validate'):
            proc_mods.append((n, s, e))
        else:
            print(f"  WARNING: unclassified {n}")
    
    def write_extracted_file(outpath, mod_list, header_lines):
        with open(outpath, 'w', encoding='utf-8') as f:
            for hl in header_lines:
                f.write(hl + '\n')
            f.write('\n')
            for idx, (mod_name, ms, me) in enumerate(mod_list):
                doc_start = extract_doc_header(lines, ms)
                if idx > 0:
                    f.write('\n')
                for l_idx in range(doc_start, me + 1):
                    f.write(lines[l_idx].rstrip() + '\n')
                f.write('\n')
    
    def_header = [
        '!===============================================================================',
        '! MODULE:  MD_Model_Data_Def',
        '! LAYER:   L3_MD',
        '! DOMAIN:  Model',
        '! ROLE:    _Def (aggregated type definitions)',
        '! BRIEF:   All _Type modules from MD_Model_Data.f90 (Table, Parameter, Field,',
        '!          Distribution, Variable, Filter, PhysicalConstants types).',
        '!          Split per L3_MD/Model refactoring plan Step 4.',
        '!===============================================================================',
    ]
    proc_header = [
        '!===============================================================================',
        '! MODULE:  MD_Model_Data_Proc',
        '! LAYER:   L3_MD',
        '! DOMAIN:  Model',
        '! ROLE:    _Proc (parse / validate procedures)',
        '! BRIEF:   All _Parse and _Validate modules from MD_Model_Data.f90.',
        '!          Split per L3_MD/Model refactoring plan Step 4.',
        '!===============================================================================',
    ]
    
    def_path = r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data_Def.f90'
    proc_path = r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data_Proc.f90'
    
    write_extracted_file(def_path, type_mods, def_header)
    write_extracted_file(proc_path, proc_mods, proc_header)
    
    print(f"\nWrote MD_Model_Data_Def.f90 ({len(type_mods)} type modules)")
    print(f"Wrote MD_Model_Data_Proc.f90 ({len(proc_mods)} proc modules)")

def split_md_model_lib():
    lib_file = r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Lib.f90'
    with open(lib_file, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    modules = get_module_ranges(lines)
    print(f"\nMD_Model_Lib.f90: {len(modules)} modules found")
    for n, s, e in modules:
        print(f"  {n}: lines {s+1}-{e+1}")
    
    # Find MD_Model_Lib module boundaries
    lib_mod = None
    for n, s, e in modules:
        if n == 'MD_Model_Lib':
            lib_mod = (n, s, e)
            break
    
    if lib_mod is None:
        print("ERROR: MD_Model_Lib not found")
        return
    
    mod_name, mod_start, mod_end = lib_mod
    
    # Read the module body
    mod_body = lines[mod_start:mod_end+1]
    
    # Find key sections within the MD_Model_Lib module:
    # 1. UF_ModelVarContext type
    # 2. Context_Model type + Context_Model_State type
    # 3. tl_mv_ctx_ SAVE variable
    # 4. VarCtx-specific PUBLIC declarations
    # 5. VarCtx procedures (GetCurrentContext, GetReal1D, MV_*, UF_ModelVar_*)
    
    # Find TYPE boundaries
    vc_type_s, vc_type_e = None, None
    cm_type_s, cm_type_e = None, None
    cms_type_s, cms_type_e = None, None
    
    for i, line in enumerate(mod_body):
        if line.strip().startswith('TYPE, PUBLIC :: UF_ModelVarContext'):
            vc_type_s = i
        if vc_type_s is not None and line.strip().startswith('END TYPE UF_ModelVarContext'):
            vc_type_e = i
        
        if line.strip().startswith('TYPE, PUBLIC :: Context_Model'):
            cm_type_s = i
        if cm_type_s is not None and line.strip().startswith('END TYPE Context_Model'):
            cm_type_e = i
        
        if line.strip().startswith('TYPE, PUBLIC :: Context_Model_State'):
            cms_type_s = i
        if cms_type_s is not None and line.strip().startswith('END TYPE Context_Model_State'):
            cms_type_e = i
    
    # Find tl_mv_ctx_ SAVE variable
    tl_line = None
    for i, line in enumerate(mod_body):
        if 'tl_mv_ctx_' in line and 'SAVE' in line:
            tl_line = i
            break
    
    # Find module-level CONTAINS (not inside a TYPE)
    mod_contains = None
    for i, line in enumerate(mod_body):
        s = line.strip()
        if s == 'CONTAINS':
            # Check indentation: module-level has minimal indent
            indent = len(line) - len(line.lstrip())
            if indent <= 2 and i > 200:
                mod_contains = i
                break
    
    print(f"UF_ModelVarContext type: offsets {vc_type_s}-{vc_type_e}")
    print(f"Context_Model type: offsets {cm_type_s}-{cm_type_e}")
    print(f"Context_Model_State type: offsets {cms_type_s}-{cms_type_e}")
    print(f"tl_mv_ctx_ at offset: {tl_line}")
    print(f"Module CONTAINS at offset: {mod_contains}")
    
    # Find VarCtx procedure boundaries
    vc_proc_names = [
        'GetCurrentContext', 'GetReal1D', 'MV_GetContextOrUseCurrent',
        'MV_GetCurrentContext', 'MV_GetReal1D',
        'UF_ModelVar_ClearCurrentContext', 'UF_ModelVarContext_RegisterScalar',
        'UF_ModelVar_InitContext', 'UF_ModelVar_RegisterField', 'UF_ModelVar_SetCurrentContext',
        'Context_Model_EnsureStorage'
    ]
    
    vc_procs = {}  # proc_name -> (start_offset, end_offset)
    for pn in vc_proc_names:
        start = None
        for i in range(0, len(mod_body)):
            if pn in mod_body[i] and (mod_body[i].strip().startswith('SUBROUTINE ') or mod_body[i].strip().startswith('FUNCTION ')):
                start = i
                break
        if start is not None:
            # Find the END SUBROUTINE or END FUNCTION
            end = None
            for i in range(start + 1, len(mod_body)):
                s = mod_body[i].strip()
                if s.startswith('END SUBROUTINE') or s.startswith('END FUNCTION'):
                    if pn in s or ('EnsureStorage' in s and 'Context' in mod_body[i-1]) or ('Context' in s and pn == 'Context_Model_EnsureStorage'):
                        end = i
                        break
            if end is not None:
                vc_procs[pn] = (start, end)
    
    for k, v in vc_procs.items():
        print(f"  {k}: offsets {v[0]}-{v[1]}")
    
    if not vc_procs:
        print("ERROR: No VarCtx procedures found")
        return
    
    # Determine the range to extract
    all_vc_offsets = []
    for start, end in vc_procs.values():
        all_vc_offsets.extend(range(start, end + 1))
    
    if not all_vc_offsets:
        print("ERROR: empty vc ranges")
        return
    
    vc_proc_min = min(all_vc_offsets)
    vc_proc_max = max(all_vc_offsets)
    
    # Build MD_Model_VarCtx module
    vc_lines = []
    vc_lines.append('!===============================================================================')
    vc_lines.append('! MODULE:  MD_Model_VarCtx')
    vc_lines.append('! LAYER:   L3_MD')
    vc_lines.append('! DOMAIN:  Model')
    vc_lines.append('! ROLE:    _VarCtx (variable context)')
    vc_lines.append('! BRIEF:   UF_ModelVarContext, Context_Model, Context_Model_State types')
    vc_lines.append('!          and all UF_ModelVar* / GetContext* / MV_* procedures.')
    vc_lines.append('!          Extracted from MD_Model_Lib per refactoring plan Step 4.')
    vc_lines.append('!===============================================================================')
    vc_lines.append('MODULE MD_Model_VarCtx')
    vc_lines.append('  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status')
    vc_lines.append('  USE IF_Prec_Core, ONLY: wp, i4')
    vc_lines.append('  IMPLICIT NONE')
    vc_lines.append('  PRIVATE')
    vc_lines.append('')
    
    # Add PUBLIC declarations
    vc_lines.append('  ! PUBLIC declarations (extracted from MD_Model_Lib)')
    for i in range(0, mod_contains):
        s = mod_body[i].strip()
        if s.startswith('PUBLIC :: ') and any(kw in s for kw in [
            'UF_ModelVar', 'Context_Model', 'GetCurrentContext', 'GetReal1D', 'MV_',
            'Context_Model_EnsureStorage'
        ]):
            vc_lines.append(mod_body[i])
    
    vc_lines.append('')
    
    # Add types
    if cms_type_s is not None:
        vc_lines.append('  !---------------------------------------------------------------------------')
        vc_lines.append('  ! Context_Model_State')
        vc_lines.append('  !---------------------------------------------------------------------------')
        for i in range(cms_type_s, cms_type_e + 1):
            vc_lines.append(mod_body[i])
        vc_lines.append('')
    
    if cm_type_s is not None:
        vc_lines.append('  !---------------------------------------------------------------------------')
        vc_lines.append('  ! Context_Model')
        vc_lines.append('  !---------------------------------------------------------------------------')
        for i in range(cm_type_s, cm_type_e + 1):
            vc_lines.append(mod_body[i])
        vc_lines.append('')
    
    if vc_type_s is not None:
        vc_lines.append('  !---------------------------------------------------------------------------')
        vc_lines.append('  ! UF_ModelVarContext')
        vc_lines.append('  !---------------------------------------------------------------------------')
        for i in range(vc_type_s, vc_type_e + 1):
            vc_lines.append(mod_body[i])
        vc_lines.append('')
    
    # Add tl_mv_ctx_ if found
    if tl_line is not None:
        vc_lines.append('  ! Thread-local variable context storage')
        vc_lines.append(mod_body[tl_line])
        i = tl_line + 1
        while i < len(mod_body) and 'tl_mv_ctx_' in mod_body[i] and 'SAVE' in mod_body[i]:
            vc_lines.append(mod_body[i])
            i += 1
        vc_lines.append('')
    
    vc_lines.append('CONTAINS')
    vc_lines.append('')
    
    # Add all VarCtx procedures in order
    added_lines = set()
    for _, start, end in sorted([(k, v[0], v[1]) for k, v in vc_procs.items()], key=lambda x: x[1]):
        for i in range(start, end + 1):
            if i not in added_lines:
                vc_lines.append(mod_body[i])
                added_lines.add(i)
        vc_lines.append('')
    
    vc_lines.append('END MODULE MD_Model_VarCtx')
    
    # Write VarCtx module
    vc_file = r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_VarCtx.f90'
    with open(vc_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(vc_lines))
        f.write('\n')
    print(f"\nWrote MD_Model_VarCtx.f90 ({len(vc_lines)} lines)")
    
    # Now rewrite MD_Model_Lib to remove VarCtx and use MD_Model_VarCtx
    # Work with full original lines
    new_lib_lines = []
    
    # Copy header / doc comments before mod_start
    for i in range(0, mod_start):
        new_lib_lines.append(lines[i])
    
    # Write new header for the MODULE
    new_lib_lines.append('!===============================================================================')
    new_lib_lines.append('! MODULE:  MD_Model_Lib')
    new_lib_lines.append('! LAYER:   L3_MD')
    new_lib_lines.append('! DOMAIN:  Model')
    new_lib_lines.append('! ROLE:    _Impl (library registration)')
    new_lib_lines.append('! BRIEF:   P0 Library: Core model definition type (UF_ModelDef) and operations.')
    new_lib_lines.append('!          v2.2 — UF_ModelVarContext, Context_Model extracted to MD_Model_VarCtx;')
    new_lib_lines.append('!          this module USEs MD_Model_VarCtx for VarCtx operations.')
    new_lib_lines.append('!===============================================================================')
    new_lib_lines.append('MODULE MD_Model_Lib')
    
    # Copy USE declarations (line by line from original, adding VarCtx USEs)
    first_use = None
    last_use = None
    for i in range(1, mod_contains):
        s = mod_body[i].strip()
        if s.startswith('USE '):
            if first_use is None:
                first_use = i
            last_use = i
    
    # Copy every non-VarCtx line
    skip_offsets = set()  # offsets in mod_body to skip
    # Skip VarCtx types
    if vc_type_s is not None:
        skip_offsets.update(range(vc_type_s, vc_type_e + 1))
    if cm_type_s is not None:
        skip_offsets.update(range(cm_type_s, cm_type_e + 1))
    if cms_type_s is not None:
        skip_offsets.update(range(cms_type_s, cms_type_e + 1))
    # Skip tl_mv_ctx_
    if tl_line is not None:
        skip_offsets.add(tl_line)
        for j in range(tl_line + 1, tl_line + 3):
            if j < len(mod_body) and 'tl_mv_ctx_' in mod_body[j]:
                skip_offsets.add(j)
    # Skip VarCtx PUBLIC declarations
    for i in range(0, mod_contains):
        s = mod_body[i].strip()
        if s.startswith('PUBLIC :: ') and any(kw in s for kw in [
            'UF_ModelVar', 'Context_Model', 'GetCurrentContext', 'GetReal1D', 'MV_',
            'Context_Model_EnsureStorage'
        ]):
            skip_offsets.add(i)
    # Skip VarCtx procedures and their section
    # The CONTAINS at mod_contains is the module-level CONTAINS
    # We need to keep it, but remove VarCtx procedures
    # Also need to handle the Context_Model_EnsureStorage which may be between CM type and module CONTAINS
    
    # Instead of purely line-based skipping, let me copy all lines but add the USE statement
    # for MD_Model_VarCtx, and remove the specific ranges
    
    used_vc_statement = False
    
    for i in range(mod_start + 1, len(mod_body)):
        if i in skip_offsets:
            continue
        
        # Skip VarCtx procedures in the CONTAINS section
        if i >= vc_proc_min and i <= vc_proc_max:
            continue
        
        s = mod_body[i]
        
        # If we just passed the last USE statement, add the VarCtx USE
        if not used_vc_statement and i > last_use and s.strip().startswith('IMPLICIT'):
            new_lib_lines.append('  ! VarCtx re-exports (from MD_Model_VarCtx)')
            new_lib_lines.append('  USE MD_Model_VarCtx, ONLY: UF_ModelVarContext, Context_Model, Context_Model_State')
            new_lib_lines.append('  USE MD_Model_VarCtx, ONLY: UF_ModelVar_ClearCurrentContext, UF_ModelVarContext_RegisterScalar')
            new_lib_lines.append('  USE MD_Model_VarCtx, ONLY: UF_ModelVar_InitContext, UF_ModelVar_RegisterField, UF_ModelVar_SetCurrentContext')
            new_lib_lines.append('  USE MD_Model_VarCtx, ONLY: GetCurrentContext, GetReal1D')
            new_lib_lines.append('  USE MD_Model_VarCtx, ONLY: MV_GetContextOrUseCurrent, MV_GetCurrentContext, MV_GetReal1D')
            used_vc_statement = True
        
        new_lib_lines.append(s)
    
    # Write the file 
    # Then append everything after END MODULE MD_Model_Lib
    after_lib = []
    for i in range(mod_end + 1, len(lines)):
        after_lib.append(lines[i])
    
    with open(lib_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_lib_lines))
        f.write('\n')
        if after_lib:
            f.write('\n'.join(after_lib))
            f.write('\n')
    
    print(f"Wrote updated MD_Model_Lib.f90")

if __name__ == '__main__':
    split_md_model_data()
    split_md_model_lib()
    print("\nAll splits complete!")
