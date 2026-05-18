"""
Phase 3: Fix constant references and layer prefix violations.
- Replace short-name constant defaults with fully-qualified PARAMETER names
- Fix PH_ prefix constants in MD_ modules (layer violation)
- Fix RT_ prefix constants in PH_ modules (layer violation)
- Fix PH_Mat_XXX_Load_State naming in PH_XXX_Load
- Add missing STATUS_OK / init_error_status to USE lists
"""
import os, re

TMPL = r'd:\TEST7\UFC\docs\templates'

def read_file(path):
    for enc in ('utf-8', 'utf-8-sig', 'latin-1'):
        try:
            with open(path, 'r', encoding=enc) as f:
                return f.read()
        except:
            continue
    return None

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

fixed = 0

# ---- 1. MD_Friction_Types: PH_FRIC_ -> MD_FRIC_, fix short defaults ----
p = os.path.join(TMPL, 'MD_Friction_Types.f90')
txt = read_file(p)
if txt:
    # Fix layer-violating PH_FRIC_ prefix to MD_FRIC_
    txt = txt.replace('PH_FRIC_FRIC_LAW_COULOMB', 'MD_FRIC_FRIC_LAW_COULOMB')
    txt = txt.replace('PH_FRIC_FRIC_LAW_LAGRANGE', 'MD_FRIC_FRIC_LAW_LAGRANGE')
    txt = txt.replace('PH_FRIC_FRIC_LAW_PENALTY', 'MD_FRIC_FRIC_LAW_PENALTY')
    txt = txt.replace('PH_FRIC_FRIC_LAW_USER', 'MD_FRIC_FRIC_LAW_USER')
    txt = txt.replace('PH_FRIC_FRIC_LAW_ANISOTROPIC', 'MD_FRIC_FRIC_LAW_ANISOTROPIC')
    # Fix short-name defaults in TYPE fields
    txt = txt.replace('fric_law     = FRIC_LAW_COULOMB', 'fric_law     = MD_FRIC_FRIC_LAW_COULOMB')
    txt = txt.replace('subrt_type   = FRIC_SUBRT_FRIC', 'subrt_type   = MD_FRIC_FRIC_SUBRT_FRIC')
    # Fix in Reset subroutine
    txt = txt.replace('self%fric_law   = FRIC_LAW_COULOMB', 'self%fric_law   = MD_FRIC_FRIC_LAW_COULOMB')
    write_file(p, txt)
    print(f"[FIXED] MD_Friction_Types.f90: PH_FRIC_ -> MD_FRIC_, short defaults fixed")
    fixed += 1

# ---- 2. MD_DOF_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'MD_DOF_Types.f90')
txt = read_file(p)
if txt:
    txt = txt.replace('ordering_method = DOF_ORD_RCM', 'ordering_method = MD_DOF_DOF_ORD_RCM')
    write_file(p, txt)
    print(f"[FIXED] MD_DOF_Types.f90: DOF_ORD_RCM -> MD_DOF_DOF_ORD_RCM")
    fixed += 1

# ---- 3. MD_Damping_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'MD_Damping_Types.f90')
txt = read_file(p)
if txt:
    # Replace all short-name defaults
    replacements = {
        'DAMP_K_CURRENT': 'MD_DAMP_DAMP_K_CURRENT',
        'DAMP_K_INITIAL': 'MD_DAMP_DAMP_K_INITIAL',
        'DAMP_NONE': 'MD_DAMP_DAMP_NONE',
        'DAMP_RAYLEIGH': 'MD_DAMP_DAMP_RAYLEIGH',
        'DAMP_COMPOSITE': 'MD_DAMP_DAMP_COMPOSITE',
        'DAMP_STRUCT': 'MD_DAMP_DAMP_STRUCT',
    }
    for short, full in replacements.items():
        # Only replace when used as value (after = sign), not in PARAMETER definitions
        # Use word boundary to avoid partial matches
        txt = re.sub(r'(?<==\s)' + re.escape(short) + r'(?=\s|$)', full, txt, flags=re.MULTILINE)
        txt = re.sub(r'=\s+' + re.escape(short) + r'\b', '= ' + full, txt)
    write_file(p, txt)
    print(f"[FIXED] MD_Damping_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

# ---- 4. MD_Material_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'MD_Material_Types.f90')
txt = read_file(p)
if txt:
    short_to_full = {
        'ELAS_ANISOTROPIC': 'MD_MAT_ELAS_ANISOTROPIC',
        'ELAS_ISOTROPIC': 'MD_MAT_ELAS_ISOTROPIC',
        'ELAS_ORTHO': 'MD_MAT_ELAS_ORTHO',
        'HYPER_NEO_HOOKEAN': 'MD_MAT_HYPER_NEO_HOOKEAN',
        'HYPER_MOONEY': 'MD_MAT_HYPER_MOONEY',
        'HYPER_ARRUDA': 'MD_MAT_HYPER_ARRUDA',
        'HYPER_OGDEN': 'MD_MAT_HYPER_OGDEN',
        'PLAST_J2': 'MD_MAT_PLAST_J2',
        'PLAST_DRUCKER': 'MD_MAT_PLAST_DRUCKER',
        'PLAST_CAM_CLAY': 'MD_MAT_PLAST_CAM_CLAY',
        'VISCO_PRONY': 'MD_MAT_VISCO_PRONY',
        'VISCO_CREEP': 'MD_MAT_VISCO_CREEP',
        'DMG_DUCTILE': 'MD_MAT_DMG_DUCTILE',
        'DMG_SHEAR': 'MD_MAT_DMG_SHEAR',
        'DMG_HASHIN': 'MD_MAT_DMG_HASHIN',
        'CPL_THERMAL_EXPANSION': 'MD_MAT_CPL_THERMAL_EXPANSION',
        'CPL_PIEZO': 'MD_MAT_CPL_PIEZO',
    }
    for short, full in short_to_full.items():
        # Replace in type defaults (after = sign)
        txt = re.sub(r'=\s+' + re.escape(short) + r'\b', '= ' + full, txt)
    write_file(p, txt)
    print(f"[FIXED] MD_Material_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

# ---- 5. MD_Orientation_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'MD_Orientation_Types.f90')
txt = read_file(p)
if txt:
    short_to_full = {
        'ORIENT_DEF_RECT': 'MD_ORIENT_ORIENT_DEF_RECT',
        'ORIENT_DEF_CYL': 'MD_ORIENT_ORIENT_DEF_CYL',
        'ORIENT_DEF_SPH': 'MD_ORIENT_ORIENT_DEF_SPH',
        'PLY_REF_RECT': 'MD_ORIENT_PLY_REF_RECT',
        'PLY_REF_CYL': 'MD_ORIENT_PLY_REF_CYL',
        'ORIENT_UPD_NONE': 'MD_ORIENT_ORIENT_UPD_NONE',
        'ORIENT_UPD_COROT': 'MD_ORIENT_ORIENT_UPD_COROT',
        'ORIENT_UPD_JAUMANN': 'MD_ORIENT_ORIENT_UPD_JAUMANN',
    }
    for short, full in short_to_full.items():
        txt = re.sub(r'=\s+' + re.escape(short) + r'\b', '= ' + full, txt)
    write_file(p, txt)
    print(f"[FIXED] MD_Orientation_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

# ---- 6. PH_Solver_Types: fix RT_ prefix constants in PH_ module ----
p = os.path.join(TMPL, 'PH_Solver_Types.f90')
txt = read_file(p)
if txt:
    # Replace RT_LSOLV_ -> PH_LSOLV_ and RT_KRYLOV_ -> PH_KRYLOV_
    txt = re.sub(r'\bRT_LSOLV_', 'PH_LSOLV_', txt)
    txt = re.sub(r'\bRT_KRYLOV_', 'PH_KRYLOV_', txt)
    write_file(p, txt)
    print(f"[FIXED] PH_Solver_Types.f90: RT_LSOLV_/RT_KRYLOV_ -> PH_ prefix")
    fixed += 1

# ---- 7. PH_XXX_Load: fix PH_Mat_XXX_Load_State naming ----
p = os.path.join(TMPL, 'PH_XXX_Load.f90')
txt = read_file(p)
if txt:
    txt = txt.replace('PH_Mat_XXX_Load_State', 'PH_XXX_Load_State')
    write_file(p, txt)
    print(f"[FIXED] PH_XXX_Load.f90: PH_Mat_XXX_Load_State -> PH_XXX_Load_State")
    fixed += 1

# ---- 8. RT_XXX_StepDriver_Types: add missing STATUS_OK import ----
for fname in ['RT_XXX_StepDriver_Types.f90', 'RT_XXX_Constraint_Types.f90', 'RT_XXX_Field_Types.f90']:
    p = os.path.join(TMPL, fname)
    txt = read_file(p)
    if txt:
        # Check if STATUS_OK is used but not imported
        if 'STATUS_OK' in txt and 'ONLY:' in txt:
            # Add STATUS_OK to USE IF_Err_API
            if 'STATUS_OK' not in txt.split('ONLY:')[1].split('\n')[0]:
                txt = re.sub(
                    r'(USE\s+IF_Err_API\s*,\s*ONLY\s*:\s*ErrorStatusType)',
                    r'\1, STATUS_OK',
                    txt
                )
                write_file(p, txt)
                print(f"[FIXED] {fname}: added STATUS_OK to USE list")
                fixed += 1

# ---- 9. MD_Mat_XXX: add missing STATUS_OK import ----
p = os.path.join(TMPL, 'MD_Mat_XXX.f90')
txt = read_file(p)
if txt:
    if 'STATUS_OK' in txt:
        if 'STATUS_OK' not in txt.split('ONLY:')[1].split('\n')[0] if 'ONLY:' in txt else True:
            txt = re.sub(
                r'(USE\s+IF_Err_API\s*,\s*ONLY\s*:\s*[^\n]+)',
                lambda m: m.group(1) + ', STATUS_OK' if 'STATUS_OK' not in m.group(1) else m.group(1),
                txt
            )
            write_file(p, txt)
            print(f"[FIXED] MD_Mat_XXX.f90: added STATUS_OK to USE list")
            fixed += 1

# ---- 10. RT_XXX_Constraint_Proc: fix stale inp/out header ----
p = os.path.join(TMPL, 'RT_XXX_Constraint_Proc.f90')
txt = read_file(p)
if txt:
    txt = txt.replace('RT_Com_Ctx, inp, out)', 'RT_Com_Ctx, args)')
    write_file(p, txt)
    print(f"[FIXED] RT_XXX_Constraint_Proc.f90: stale inp/out -> args")
    fixed += 1

# ---- 11. MD_Amplitude_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'MD_Amplitude_Types.f90')
txt = read_file(p)
if txt:
    short_to_full = {
        'AMP_TYPE_TABULAR': 'MD_AMP_AMP_TYPE_TABULAR',
        'AMP_TYPE_SMOOTH': 'MD_AMP_AMP_TYPE_SMOOTH',
        'AMP_TYPE_PERIODIC': 'MD_AMP_AMP_TYPE_PERIODIC',
        'AMP_TYPE_USER': 'MD_AMP_AMP_TYPE_USER',
        'AMP_INTERP_LINEAR': 'MD_AMP_AMP_INTERP_LINEAR',
        'AMP_INTERP_STEP': 'MD_AMP_AMP_INTERP_STEP',
    }
    for short, full in short_to_full.items():
        txt = re.sub(r'=\s+' + re.escape(short) + r'\b', '= ' + full, txt)
    write_file(p, txt)
    print(f"[FIXED] MD_Amplitude_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

# ---- 12. RT_Global_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'RT_Global_Types.f90')
txt = read_file(p)
if txt:
    txt = re.sub(r'=\s+ANALYSIS_STATIC\b', '= RT_ANALYSIS_ANALYSIS_STATIC', txt)
    write_file(p, txt)
    print(f"[FIXED] RT_Global_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

# ---- 13. RT_Assembly_Types: fix short constant defaults ----
p = os.path.join(TMPL, 'RT_Assembly_Types.f90')
txt = read_file(p)
if txt:
    txt = re.sub(r'=\s+ASM_METHOD_ELEMENT_WISE\b', '= RT_ASM_ASM_METHOD_ELEMENT_WISE', txt)
    write_file(p, txt)
    print(f"[FIXED] RT_Assembly_Types.f90: short constant defaults -> fully-qualified")
    fixed += 1

print(f"\n=== Phase 3 complete: {fixed} fixes applied ===")
