"""
Phase 4: Add Phase|Verb annotations and SIO variant markers.
- Add Phase|Verb|PATH to public subroutines in _Proc and _Core templates
- Add SIO_VARIANT markers to RT_Proc headers
- Fix Skeleton Core FuncSet -> Phase|Verb
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

# ---- SIO variant markers for RT_Proc templates ----
sio_6tuple = '!>>> SIO_VARIANT: 6-tuple (Desc, State, Algo, Ctx, RT_Com_Ctx, args)'
sio_5tuple = '!>>> SIO_VARIANT: 5-tuple (Desc, State, Algo, Ctx, args) — no RT_Com_Ctx'
sio_5dual  = '!>>> SIO_VARIANT: 5-tuple-dual-ctx (Algo, State, Conv_Ctx, Lin_Ctx, args)'

rt_proc_sio = {
    'RT_XXX_StepDriver_Proc.f90': sio_6tuple,
    'RT_XXX_Elem_Proc.f90':      sio_6tuple,
    'RT_XXX_Mat_Proc.f90':       sio_6tuple,
    'RT_XXX_Output_Proc.f90':    sio_6tuple,
    'RT_XXX_Load_Proc.f90':      sio_6tuple,
    'RT_XXX_BC_Proc.f90':        sio_6tuple,
    'RT_XXX_Contact_Proc.f90':   sio_6tuple,
    'RT_XXX_Constraint_Proc.f90':sio_6tuple,
    'RT_XXX_Field_Proc.f90':     sio_6tuple,
    'RT_XXX_Assembly_Proc.f90':  sio_5tuple,
    'RT_XXX_WriteBack_Proc.f90': sio_5tuple,
    'RT_XXX_Solver_Proc.f90':    sio_5dual,
}

# Phase|Verb annotations for RT_Proc public subroutines
rt_proc_phase_verb = {
    'RT_XXX_StepDriver_Proc.f90': 'Orchestrate | Apply | COLD_PATH',
    'RT_XXX_Elem_Proc.f90':      'Compute | Apply | HOT_PATH',
    'RT_XXX_Mat_Proc.f90':       'Compute | Apply | HOT_PATH',
    'RT_XXX_Output_Proc.f90':    'Output | Apply | COLD_PATH',
    'RT_XXX_Load_Proc.f90':      'Compute | Apply | HOT_PATH',
    'RT_XXX_BC_Proc.f90':        'Compute | Apply | HOT_PATH',
    'RT_XXX_Contact_Proc.f90':   'Compute | Eval | HOT_PATH',
    'RT_XXX_Constraint_Proc.f90':'Compute | Apply | HOT_PATH',
    'RT_XXX_Field_Proc.f90':     'Compute | Apply | HOT_PATH',
    'RT_XXX_Assembly_Proc.f90':  'Compute | Apply | HOT_PATH',
    'RT_XXX_WriteBack_Proc.f90': 'WriteBack | Apply | COLD_PATH',
    'RT_XXX_Solver_Proc.f90':    'Compute | Apply | HOT_PATH',
}

for fname, sio_marker in rt_proc_sio.items():
    fpath = os.path.join(TMPL, fname)
    txt = read_file(fpath)
    if txt is None:
        continue
    
    changed = False
    
    # Add SIO_VARIANT marker after the last !>>> line in header
    if 'SIO_VARIANT' not in txt:
        # Find the last !>>> line and insert after it
        lines = txt.split('\n')
        last_marker_idx = -1
        for i, line in enumerate(lines):
            if line.strip().startswith('!>>>'):
                last_marker_idx = i
        if last_marker_idx >= 0:
            lines.insert(last_marker_idx + 1, sio_marker)
            changed = True
    
    # Add Phase|Verb to main subroutine
    phase_verb = rt_proc_phase_verb.get(fname, '')
    if phase_verb and 'Phase:' not in txt:
        # Find the main SUBROUTINE declaration and add Phase|Verb before it
        for i, line in enumerate(lines):
            if re.match(r'\s*SUBROUTINE\s+RT_', line) and i > 10:
                # Insert Phase|Verb annotation before
                pv_line = f'  ! Phase: {phase_verb}'
                lines.insert(i, pv_line)
                changed = True
                break
    
    if changed:
        write_file(fpath, '\n'.join(lines))
        print(f"[FIXED] {fname}: added SIO_VARIANT + Phase|Verb")
        fixed += 1

# ---- Phase|Verb for PH_XXX templates ----
ph_proc_phase_verb = {
    'PH_XXX_Elem.f90':        ('Compute | Compute | HOT_PATH', 'PH_XXX_Elem_Compute'),
    'PH_XXX_Mat.f90':         ('Compute | Apply | HOT_PATH', 'PH_Mat_XXX_UMAT_API'),
    'PH_XXX_UMAT.f90':        ('Compute | Apply | HOT_PATH', 'PH_XXX_UMAT_API'),
    'PH_XXX_VUMAT.f90':       ('Compute | Apply | HOT_PATH', 'PH_XXX_VUMAT_API'),
    'PH_XXX_UEL.f90':         ('Compute | Apply | HOT_PATH', 'PH_XXX_UEL_API'),
    'PH_XXX_BC.f90':          ('Compute | Apply | HOT_PATH', 'PH_XXX_BC_API'),
    'PH_XXX_Load.f90':        ('Compute | Apply | HOT_PATH', 'PH_XXX_Load_API'),
    'PH_XXX_Contact.f90':     ('Compute | Apply | HOT_PATH', 'PH_XXX_Contact_API'),
    'PH_XXX_Constraint.f90':  ('Compute | Apply | HOT_PATH', 'PH_XXX_Constr_API'),
    'PH_XXX_Field.f90':       ('Compute | Apply | HOT_PATH', 'PH_XXX_Field_API'),
    'PH_XXX_Solver.f90':      ('Compute | Iterate | HOT_PATH', 'PH_XXX_Solv_Iterate'),
}

for fname, (pv, subr_name) in ph_proc_phase_verb.items():
    fpath = os.path.join(TMPL, fname)
    txt = read_file(fpath)
    if txt is None:
        continue
    if 'Phase:' in txt:
        continue
    
    lines = txt.split('\n')
    changed = False
    for i, line in enumerate(lines):
        if re.match(r'\s*SUBROUTINE\s+' + re.escape(subr_name), line):
            pv_line = f'  ! Phase: {pv}'
            lines.insert(i, pv_line)
            changed = True
            break
    
    if changed:
        write_file(fpath, '\n'.join(lines))
        print(f"[FIXED] {fname}: added Phase|Verb")
        fixed += 1

# ---- Skeleton Core: upgrade FuncSet to Phase|Verb ----
for fname in ['UFC_Skeleton_Core.f90']:
    fpath = os.path.join(TMPL, fname)
    txt = read_file(fpath)
    if txt is None:
        continue
    
    # Replace FuncSet comments with Phase|Verb
    txt = txt.replace(
        '  !   FuncSet: Init',
        '  ! Phase: Config | Verb: Init | COLD_PATH'
    )
    txt = txt.replace(
        '  !   FuncSet: Finalize',
        '  ! Phase: Teardown | Verb: Finalize | COLD_PATH'
    )
    txt = txt.replace(
        '  !   FuncSet: Query',
        '  ! Phase: Query | Verb: Query | COLD_PATH'
    )
    txt = txt.replace(
        '  !   FuncSet: Compute',
        '  ! Phase: Compute | Verb: Compute | HOT_PATH'
    )
    txt = txt.replace(
        '  !   FuncSet: Valid',
        '  ! Phase: Config | Verb: Validate | COLD_PATH'
    )
    
    write_file(fpath, txt)
    print(f"[FIXED] {fname}: FuncSet -> Phase|Verb")
    fixed += 1

# ---- Skeleton Brg: upgrade FuncSet to Phase|Verb ----
for fname in ['UFC_Skeleton_Brg.f90']:
    fpath = os.path.join(TMPL, fname)
    txt = read_file(fpath)
    if txt is None:
        continue
    
    txt = txt.replace(
        '  !   FuncSet: Brg\n  !   Cross-layer: {SourceLayer} -> {TargetLayer}',
        '  ! Phase: Populate | Verb: Populate | COLD_PATH\n  !   Cross-layer: {SourceLayer} -> {TargetLayer}'
    )
    txt = txt.replace(
        '  !   FuncSet: Brg\n  !   Cross-layer: L5_RT -> L3_MD',
        '  ! Phase: WriteBack | Verb: WriteBack | COLD_PATH\n  !   Cross-layer: L5_RT -> L3_MD'
    )
    
    write_file(fpath, txt)
    print(f"[FIXED] {fname}: FuncSet -> Phase|Verb")
    fixed += 1

print(f"\n=== Phase 4 complete: {fixed} fixes applied ===")
