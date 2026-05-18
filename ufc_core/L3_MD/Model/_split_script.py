"""Split MD_Model_Data.f90 and MD_Model_Lib.f90 per L3_MD/Model refactoring plan"""
import re

def split_md_model_data():
    """Split MD_Model_Data.f90 -> MD_Model_Data_Def.f90 (_Type) + MD_Model_Data_Proc.f90 (_Parse/_Validate)"""
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data.f90', 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Headers before first MODULE
    header = []
    i = 0
    while i < len(lines) and not lines[i].startswith('MODULE ') and not lines[i].startswith('MODULE'):
        header.append(lines[i])
        i += 1
    
    # Scan for module types
    type_modules = []  # _Type modules + first MD_Model_Data
    proc_modules = []  # _Parse and _Validate modules
    
    # Track module boundaries
    module_starts = []
    for idx, line in enumerate(lines):
        m = re.match(r'^(MODULE\s+)(MD_Model_Data\S*)(.*)', line)
        if m:
            module_starts.append((idx, m.group(2)))
    
    # Read the sections between modules
    # Headers are the documentation blocks before each MODULE statement
    def get_module_content(start_line_idx, module_name):
        """Get content from a module start through its END MODULE"""
        # Find the END MODULE line
        end_pat = re.compile(r'^END\s+MODULE\s+' + re.escape(module_name))
        end_idx = None
        for j in range(start_line_idx, len(lines)):
            if end_pat.match(lines[j]):
                end_idx = j
                break
        if end_idx is None:
            return None, None
        return start_line_idx, end_idx
    
    # Classify modules
    md_model_data_first = True
    type_mod_names = []
    proc_mod_names = []
    
    for idx, mod_name in module_starts:
        if mod_name == 'MD_Model_Data' and md_model_data_first:
            type_mod_names.append((idx, mod_name))
            md_model_data_first = False
        elif mod_name.endswith('_Type'):
            type_mod_names.append((idx, mod_name))
        elif mod_name.endswith('_Parse') or mod_name.endswith('_Validate'):
            proc_mod_names.append((idx, mod_name))
        else:
            print(f"WARNING: Unclassified module {mod_name} at line {idx+1}")
    
    # Write MD_Model_Data_Def.f90
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data_Def.f90', 'w', encoding='utf-8') as f:
        # Write header
        f.write(write_def_header())
        
        for idx, mod_name in type_mod_names:
            s, e = get_module_content(idx, mod_name)
            if s is not None:
                # Also capture preceding doc comment lines
                doc_start = idx
                while doc_start > 0 and (lines[doc_start-1].startswith('!') or lines[doc_start-1].strip() == '' or
                                          lines[doc_start-1].startswith('!>>>') or lines[doc_start-1].startswith('!>')):
                    doc_start -= 1
                # But don't go further back than the previous module's end
                f.writelines(lines[doc_start:e+1])
                f.write('\n')
    
    print(f"Wrote MD_Model_Data_Def.f90 with {len(type_mod_names)} type modules")
    
    # Write MD_Model_Data_Proc.f90
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Data_Proc.f90', 'w', encoding='utf-8') as f:
        f.write(write_proc_header())
        
        for idx, mod_name in proc_mod_names:
            s, e = get_module_content(idx, mod_name)
            if s is not None:
                doc_start = idx
                while doc_start > 0 and (lines[doc_start-1].startswith('!') or lines[doc_start-1].strip() == '' or
                                          lines[doc_start-1].startswith('!>>>') or lines[doc_start-1].startswith('!>')):
                    doc_start -= 1
                f.writelines(lines[doc_start:e+1])
                f.write('\n')
    
    print(f"Wrote MD_Model_Data_Proc.f90 with {len(proc_mod_names)} procedure modules")


def write_def_header():
    return """!===============================================================================
! MODULE:  MD_Model_Data_Def
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Def (aggregated _Type definitions)
! BRIEF:   Extracted from MD_Model_Data.f90: all _Type modules and core type
!          definitions (TableProperties, ParameterProperties, FieldProperties,
!          DistributionProperties, VariableProperties, FilterProperties,
!          PhysicalConstantsProperties, etc.)
!
!          Split per L3_MD/Model refactoring plan Step 4.
!          Consumer modules that USE MD_Model_Data should now USE MD_Model_Data_Def.
!===============================================================================

"""

def write_proc_header():
    return """!===============================================================================
! MODULE:  MD_Model_Data_Proc
! LAYER:   L3_MD
! DOMAIN:  Model
! ROLE:    _Proc (parse / validate procedures)
! BRIEF:   Extracted from MD_Model_Data.f90: all _Parse and _Validate modules
!          for Table, Parameter, Field, Distribution, Variable, Filter,
!          and PhysicalConstants data types.
!
!          Split per L3_MD/Model refactoring plan Step 4.
!===============================================================================

"""


def split_md_model_lib():
    """Split MD_Model_Lib.f90 -> MD_Model_Lib.f90 (core) + MD_Model_VarCtx.f90 (UF_ModelVar*))
       The Adv modules are already separate within the file and stay in MD_Model_Lib.f90."""
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Lib.f90', 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    # Find all module boundaries
    module_starts = []
    for idx, line in enumerate(lines):
        m = re.match(r'^(MODULE\s+)(MD_Model_\S+)', line)
        if m:
            module_starts.append((idx, m.group(2)))
    
    def get_module_end(start_idx, mod_name):
        end_pat = re.compile(r'^END\s+MODULE\s+' + re.escape(mod_name))
        for j in range(start_idx, len(lines)):
            if end_pat.match(lines[j]):
                return j
        return None
    
    # First module: MD_Model_Lib (lines ~50-1088)
    # This has both UF_ModelDef core and UF_ModelVarContext.
    # Need to extract VarCtx from within it.
    
    # The VarCtx parts within MD_Model_Lib are:
    # - UF_ModelVarContext type definition (around line 143-146)
    # - tl_mv_ctx_ variable (around line 172)
    # - UF_ModelVar* procedures (around lines 993-1086)
    
    # Strategy: Rewrite MD_Model_Lib to USE MD_Model_VarCtx and remove its VarCtx code
    # Create MD_Model_VarCtx from the extracted VarCtx code
    
    # Read current MD_Model_Lib module content
    lib_start = None
    lib_name = None
    for idx, mod_name in module_starts:
        if mod_name == 'MD_Model_Lib':
            lib_start = idx
            lib_name = mod_name
            break
    
    if lib_start is None:
        print("ERROR: MD_Model_Lib module not found")
        return
    
    lib_end = get_module_end(lib_start, lib_name)
    print(f"MD_Model_Lib module: lines {lib_start+1}-{lib_end+1}")
    
    lib_module_lines = lines[lib_start:lib_end+1]
    
    # Scan MD_Model_Lib for VarCtx sections
    # Find: UF_ModelVarContext type definition
    vc_type_start = None
    for i, line in enumerate(lib_module_lines):
        if 'TYPE, PUBLIC :: UF_ModelVarContext' in line:
            vc_type_start = i
            break
    
    # Find UF_ModelVar procedures section
    vc_proc_start = None
    for i in range(len(lib_module_lines)-1, 0, -1):
        if 'CONTAINS' in lib_module_lines[i] and i > 100 and i < len(lib_module_lines) - 100:
            # The CONTAINS line right before UF_ModelVar procedures
            if i > 800:  # It's late in the module
                vc_proc_start = i
                break
    
    # Actually let me find it more precisely
    vc_proc_start = None
    vc_proc_end = None
    for i, line in enumerate(lib_module_lines):
        if 'SUBROUTINE UF_ModelVar_ClearCurrentContext' in line:
            vc_proc_start = i
            break
    if vc_proc_start:
        # The END SUBROUTINE for the last UF_ModelVar sub is around line 1086
        for i in range(len(lib_module_lines)-1, 0, -1):
            if 'END SUBROUTINE UF_ModelVar_SetCurrentContext' in lib_module_lines[i]:
                vc_proc_end = i
                break
    
    print(f"VarCtx type at line offset {vc_type_start}, procs at {vc_proc_start}-{vc_proc_end}")
    
    # Now search more carefully
    proc_contains_start = None
    for i in range(vc_proc_start-1, max(0, vc_proc_start-20), -1):
        if lib_module_lines[i].strip() == 'CONTAINS':
            proc_contains_start = i
            break
    
    print(f"VarCtx CONTAINS at offset {proc_contains_start}")
    
    # Build VarCtx module content
    # The VarCtx code includes:
    # 1. UF_ModelVarContext type definition (with its CONTAINS block)
    # 2. tl_mv_ctx_ SAVE variable
    # 3. PUBLIC declarations for VarCtx functions
    # 4. All UF_ModelVar* subroutines after the CONTAINS
    
    # Find the end of UF_ModelVarContext type
    vc_type_end = None
    for i in range(vc_type_start, min(vc_type_start + 30, len(lib_module_lines))):
        if 'END TYPE UF_ModelVarContext' in lib_module_lines[i]:
            vc_type_end = i
            break
    
    print(f"VarCtx type ends at offset {vc_type_end}")
    
    # Build the new MD_Model_VarCtx module
    vc_module_lines = []
    vc_module_lines.append('!===============================================================================')
    vc_module_lines.append('! MODULE:  MD_Model_VarCtx')
    vc_module_lines.append('! LAYER:   L3_MD')
    vc_module_lines.append('! DOMAIN:  Model')
    vc_module_lines.append('! ROLE:    _Impl (variable context)')  
    vc_module_lines.append('! BRIEF:   UF_ModelVarContext and related UF_ModelVar* operations.')
    vc_module_lines.append('!          Extracted from MD_Model_Lib per L3_MD/Model refactoring plan Step 4.')
    vc_module_lines.append('!===============================================================================')
    vc_module_lines.append('MODULE MD_Model_VarCtx')
    vc_module_lines.append('  USE IF_Err_Brg, ONLY: ErrorStatusType, init_error_status')
    vc_module_lines.append('  USE IF_Prec_Core, ONLY: wp, i4')
    vc_module_lines.append('  IMPLICIT NONE')
    vc_module_lines.append('  PRIVATE')
    vc_module_lines.append('')
    
    # Extract public declarations between PUBLIC keywords
    in_varctx_decl = False
    varctx_public_lines = []
    for i, line in enumerate(lib_module_lines):
        if 'UF_ModelVarContext' in line or 'Context_Model' in line or 'Context_Model_State' in line:
            in_varctx_decl = True
        if 'UF_ModelVar_ClearCurrentContext' in line or 'UF_ModelVarContext_RegisterScalar' in line or 'UF_ModelVar_InitContext' in line or 'UF_ModelVar_RegisterField' in line or 'UF_ModelVar_SetCurrentContext' in line:
            in_varctx_decl = True
    
    # Properly find the PUBLIC declarations from the original module
    public_lines_found = False
    for i, line in enumerate(lib_module_lines):
        if 'PUBLIC :: UF_ModelVarContext' in line:
            public_lines_found = True
        if public_lines_found:
            if line.strip().startswith('!') and not any(p in line for p in ['PUBLIC', 'UF_ModelVar']):
                continue
            varctx_public_lines.append(line)
            if 'UF_ModelVar_SetCurrentContext' in line:
                break
    
    vc_module_lines.extend(varctx_public_lines)
    vc_module_lines.append('')
    
    # Add the type definition
    for i in range(vc_type_start, vc_type_end + 1):
        vc_module_lines.append(lib_module_lines[i])
    vc_module_lines.append('')
    
    # Add tl_mv_ctx_ and other internal variables
    for i in range(vc_type_end + 1, len(lib_module_lines)):
        line = lib_module_lines[i]
        # Stop at CONTAINS or next TYPE
        if line.strip().startswith('CONTAINS') and i >= vc_proc_start - 5 and i <= vc_proc_start + 5:
            break
        if line.strip().startswith('TYPE,') or line.strip().startswith('TYPE ::'):
            break
        if 'PUBLIC ::' in line and not any(v in line for v in ['UF_ModelVar', 'Context_Model']):
            continue
        vc_module_lines.append(line)
    
    vc_module_lines.append('')
    vc_module_lines.append('CONTAINS')
    vc_module_lines.append('')
    
    # Add all VarCtx procedures
    for i in range(vc_proc_start, vc_proc_end + 1):
        vc_module_lines.append(lib_module_lines[i])
    
    vc_module_lines.append('')
    vc_module_lines.append('END MODULE MD_Model_VarCtx')
    
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_VarCtx.f90', 'w', encoding='utf-8') as f:
        f.write('\n'.join(vc_module_lines))
    
    print(f"Wrote MD_Model_VarCtx.f90 ({len(vc_module_lines)} lines)")
    
    # Now rewrite MD_Model_Lib to remove VarCtx code and instead USE MD_Model_VarCtx
    new_lib_lines = list(lib_module_lines)  # copy
    
    # Remove VarCtx type definition
    del new_lib_lines[vc_type_start:vc_type_end + 1]
    
    # Adjust offsets after deletion
    offset = -(vc_type_end - vc_type_start + 1)
    
    # Remove tl_mv_ctx_ and VarCtx private/public declarations
    # Find and remove VarCtx-specific lines in the declaration section
    to_remove = []
    for i, line in enumerate(new_lib_lines):
        # Remove VarCtx specific public declarations
        if any(v in line for v in ['UF_ModelVarContext', 'Context_Model', 'Context_Model_State',
                                     'UF_ModelVar_ClearCurrentContext', 'UF_ModelVarContext_RegisterScalar',
                                     'UF_ModelVar_InitContext', 'UF_ModelVar_RegisterField',
                                     'UF_ModelVar_SetCurrentContext']):
            to_remove.append(i)
        # Remove tl_mv_ctx_ variable
        if 'tl_mv_ctx_' in line:
            to_remove.append(i)
    
    # Remove in reverse order
    for idx in sorted(to_remove, reverse=True):
        del new_lib_lines[idx]
    
    # Find and remove VarCtx CONTAINS + procedures
    # Re-scan for UF_ModelVar procedures
    vc_proc_start_new = None
    vc_proc_end_new = None
    for i, line in enumerate(new_lib_lines):
        if 'SUBROUTINE UF_ModelVar_ClearCurrentContext' in line:
            vc_proc_start_new = i
        if 'END SUBROUTINE UF_ModelVar_SetCurrentContext' in line:
            vc_proc_end_new = i
            break
    
    if vc_proc_start_new and vc_proc_end_new:
        # Also remove the CONTAINS immediately before
        contains_idx = None
        for i in range(vc_proc_start_new - 1, max(0, vc_proc_start_new - 10), -1):
            if new_lib_lines[i].strip() == 'CONTAINS':
                contains_idx = i
                break
        if contains_idx:
            del new_lib_lines[contains_idx:vc_proc_end_new + 1]
        else:
            del new_lib_lines[vc_proc_start_new:vc_proc_end_new + 1]
    
    # Add USE MD_Model_VarCtx after existing USE statements
    use_idx = None
    for i, line in enumerate(new_lib_lines):
        if 'USE ' in line and i < vc_type_start:
            use_idx = i
    # Find last USE in declaration section (before first TYPE or CONTAINS)
    last_use = None
    for i, line in enumerate(new_lib_lines[:100]):
        if line.strip().startswith('USE '):
            last_use = i
    
    if last_use is not None:
        # Check if MD_Model_VarCtx is not already there
        has_varctx_use = any('MD_Model_VarCtx' in l for l in new_lib_lines[:last_use+5])
        if not has_varctx_use:
            new_lib_lines.insert(last_use + 1, '  USE MD_Model_VarCtx, ONLY: UF_ModelVarContext, UF_ModelVar_ClearCurrentContext, &\n')
            new_lib_lines.insert(last_use + 2, '      UF_ModelVarContext_RegisterScalar, UF_ModelVar_InitContext, &\n')
            new_lib_lines.insert(last_use + 3, '      UF_ModelVar_RegisterField, UF_ModelVar_SetCurrentContext\n')
    
    # Now write the file - need to combine with header and trailing modules
    # Read all lines before lib_start (header + doc comments)
    before_lib = lines[:lib_start]
    
    # Read all lines after lib_end (the Adv modules and their doc comments)
    after_lib = lines[lib_end+1:]
    
    # Write combined
    with open(r'D:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Model_Lib.f90', 'w', encoding='utf-8') as f:
        # Header
        f.write('!===============================================================================\n')
        f.write('! MODULE:  MD_Model_Lib\n')
        f.write('! LAYER:   L3_MD\n')
        f.write('! DOMAIN:  Model\n')
        f.write('! ROLE:    _Impl (library registration)\n')
        f.write('! BRIEF:   P0 Library: Core model definition type (UF_ModelDef) and operations.\n')
        f.write('!          Geometry, materials, sections, loads/BCs, DOF management.\n')
        f.write('!          v2.2 — UF_ModelVarContext extracted to MD_Model_VarCtx; this module\n')
        f.write('!          now USEs MD_Model_VarCtx for VarCtx operations.\n')
        f.write('!===============================================================================\n')
        
        # Write the module content
        f.write('\n'.join(new_lib_lines))
        f.write('\n')
        
        # Write trailing Adv modules
        if after_lib:
            # Find the doc comments between lib_end and first Adv module
            f.writelines(after_lib)
    
    print("Wrote updated MD_Model_Lib.f90")


if __name__ == '__main__':
    split_md_model_data()
    split_md_model_lib()
    print("Done!")
