"""
Phase 2: Unify MODULE = Filename stem across all templates.
- Fix MODULE name mismatches in RT_Proc, PH, MD files
- Delete duplicate MD_XXX_Amplitude_Types.f90
- Rename MODULE in PH_XXX_UMAT_ULTRA_COMPACT to avoid collision
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

# ---- MODULE name fixes: map filename stem -> current MODULE -> new MODULE ----
# For each file, replace MODULE and END MODULE declarations

module_fixes = {
    # RT_Proc files where MODULE != filename
    'RT_XXX_Elem_Proc.f90': {
        'old': 'RT_Elem_XXX_XXX_Proc',
        'new': 'RT_XXX_Elem_Proc',
    },
    'RT_XXX_Assembly_Proc.f90': {
        'old': 'RT_Assembly_XXX_XXX_Proc',
        'new': 'RT_XXX_Assembly_Proc',
    },
    'RT_XXX_Solver_Proc.f90': {
        'old': 'RT_Solver_XXX_Proc',
        'new': 'RT_XXX_Solver_Proc',
    },
    'RT_XXX_WriteBack_Proc.f90': {
        'old': 'RT_WriteBack_XXX_Proc',
        'new': 'RT_XXX_WriteBack_Proc',
    },
    'RT_XXX_Contact_Proc.f90': {
        'old': 'RT_Contact_XXX_Proc',
        'new': 'RT_XXX_Contact_Proc',
    },
    'RT_XXX_Field_Proc.f90': {
        'old': 'RT_Field_XXX_Proc',
        'new': 'RT_XXX_Field_Proc',
    },
    # PH files where MODULE != filename
    'PH_XXX_Constraint.f90': {
        'old': 'PH_Constr_XXX',
        'new': 'PH_XXX_Constraint',
    },
    'PH_XXX_Solver.f90': {
        'old': 'PH_Solv_XXX',
        'new': 'PH_XXX_Solver',
    },
    'PH_XXX_Field.f90': {
        'old': 'PH_Field_XXX',
        'new': 'PH_XXX_Field',
    },
    # RT Types where XXX dropped
    'RT_XXX_StepDriver_Types.f90': {
        'old': 'RT_StepDriver_Types',
        'new': 'RT_XXX_StepDriver_Types',
    },
    'RT_XXX_Constraint_Types.f90': {
        'old': 'RT_Constraint_Types',
        'new': 'RT_XXX_Constraint_Types',
    },
    'RT_XXX_Field_Types.f90': {
        'old': 'RT_Field_Types',
        'new': 'RT_XXX_Field_Types',
    },
    # MD Types where XXX dropped
    'MD_XXX_Analysis_Types.f90': {
        'old': 'MD_Analysis_Types',
        'new': 'MD_XXX_Analysis_Types',
    },
    # UMAT ULTRA COMPACT collision fix
    'PH_XXX_UMAT_ULTRA_COMPACT.f90': {
        'old': 'PH_XXX_UMAT',
        'new': 'PH_XXX_UMAT_Compact',
    },
}

for fname, fix in module_fixes.items():
    fpath = os.path.join(TMPL, fname)
    if not os.path.exists(fpath):
        print(f"[SKIP] {fname}: file not found")
        continue
    txt = read_file(fpath)
    if txt is None:
        print(f"[SKIP] {fname}: cannot read")
        continue

    old_mod = fix['old']
    new_mod = fix['new']

    # Replace MODULE declaration
    pat_mod = re.compile(r'^(\s*MODULE\s+)' + re.escape(old_mod) + r'\s*$', re.MULTILINE)
    pat_end = re.compile(r'^(\s*END\s+MODULE\s+)' + re.escape(old_mod) + r'\s*$', re.MULTILINE)

    count_mod = len(pat_mod.findall(txt))
    count_end = len(pat_end.findall(txt))

    if count_mod == 0:
        # Try case-insensitive
        pat_mod = re.compile(r'^(\s*MODULE\s+)' + re.escape(old_mod) + r'\s*$', re.MULTILINE | re.IGNORECASE)
        pat_end = re.compile(r'^(\s*END\s+MODULE\s+)' + re.escape(old_mod) + r'\s*$', re.MULTILINE | re.IGNORECASE)
        count_mod = len(pat_mod.findall(txt))
        count_end = len(pat_end.findall(txt))

    if count_mod > 0:
        txt = pat_mod.sub(r'\g<1>' + new_mod, txt)
        txt = pat_end.sub(r'\g<1>' + new_mod, txt)
        # Also update header comment if it mentions the old module name
        txt = txt.replace(f'Module: {old_mod}', f'Module: {new_mod}')
        write_file(fpath, txt)
        print(f"[FIXED] {fname}: MODULE {old_mod} -> {new_mod}")
        fixed += 1
    else:
        print(f"[SKIP] {fname}: MODULE {old_mod} not found in file")

# ---- Delete duplicate MD_XXX_Amplitude_Types.f90 ----
dup_path = os.path.join(TMPL, 'MD_XXX_Amplitude_Types.f90')
if os.path.exists(dup_path):
    os.remove(dup_path)
    print(f"[DELETED] MD_XXX_Amplitude_Types.f90 (duplicate of MD_Amplitude_Types.f90)")
    fixed += 1

# ---- Fix Skeleton header {Feature} inconsistency ----
for fname in ['UFC_Skeleton_Def.f90', 'UFC_Skeleton_Core.f90']:
    fpath = os.path.join(TMPL, fname)
    txt = read_file(fpath)
    if txt:
        # Header says {Layer}_{Domain}_{Feature}_Def but MODULE is {Layer}_{Domain}_Def
        # Align header to match MODULE (drop {Feature} from header)
        txt = txt.replace(
            '{Layer}_{Domain}/{Feature}/{Layer}_{Domain}_{Feature}_Def.f90',
            '{Layer}_{Domain}/{Feature}/{Layer}_{Domain}_Def.f90'
        )
        txt = txt.replace(
            '{Layer}_{Domain}/{Feature}/{Layer}_{Domain}_{Feature}_Core.f90',
            '{Layer}_{Domain}/{Feature}/{Layer}_{Domain}_Core.f90'
        )
        txt = txt.replace(
            'Module: {Layer}_{Domain}_{Feature}_Def',
            'Module: {Layer}_{Domain}_Def'
        )
        txt = txt.replace(
            'Module: {Layer}_{Domain}_{Feature}_Core',
            'Module: {Layer}_{Domain}_Core'
        )
        txt = txt.replace(
            'Module: {Layer}_{Domain}_Core\n! Layer',
            'Module: {Layer}_{Domain}_Core\n! Note:  When domain has sub-features, use {Layer}_{Domain}_{Feature}_Core.f90\n! Layer'
        )
        write_file(fpath, txt)
        print(f"[FIXED] {fname}: header {{Feature}} inconsistency aligned")
        fixed += 1

print(f"\n=== Phase 2 complete: {fixed} fixes applied ===")
