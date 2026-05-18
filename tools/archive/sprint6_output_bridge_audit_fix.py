"""
Sprint 6: Output + Field + Bridge + WriteBack + Logging + remaining L3/L4/L5 domains
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
DOMAIN_KEYWORDS = ['Output', 'Field', 'Bridge', 'WriteBack', 'Logging', 'Populate', 
                   'DOF', 'Amplitude', 'Analysis', 'Coupling', 'Orientation',
                   'Section', 'Property', 'Damping', 'AI']

# Collect from all 3 layers, but exclude already-handled directories
ALREADY_DONE = {
    'Element', 'Mesh', 'Material', 'Assembly', 'Solver', 'StepDriver',
    'LoadBC', 'Load', 'Contact', 'Constraint', 'Interaction', 'Friction',
    'Precision', 'Error', 'Log', 'Memory', 'Monitor', 'Registry', 'IO', 'Base',
    'Base_Legacy', 'ExternalLibs', 'Matrix', 'TimeInt',
}

DIRS = []
for layer in ['L3_MD', 'L4_PH', 'L5_RT']:
    layer_dir = os.path.join(ROOT, layer)
    if not os.path.isdir(layer_dir):
        continue
    for d in os.listdir(layer_dir):
        full = os.path.join(layer_dir, d)
        if os.path.isdir(full) and d not in ALREADY_DONE:
            DIRS.append(full)
    # Also handle root files not yet scanned
    for f in os.listdir(layer_dir):
        if f.endswith('.f90') and os.path.isfile(os.path.join(layer_dir, f)):
            # Root files - create a pseudo entry
            pass  # We'll handle root files separately

# Add root-level f90 files from L3/L4/L5
ROOT_FILES = []
for layer in ['L3_MD', 'L4_PH', 'L5_RT']:
    layer_dir = os.path.join(ROOT, layer)
    if not os.path.isdir(layer_dir):
        continue
    for f in os.listdir(layer_dir):
        fp = os.path.join(layer_dir, f)
        if f.endswith('.f90') and os.path.isfile(fp):
            ROOT_FILES.append(fp)

def read_file(path):
    for enc in ('utf-8-sig', 'utf-8', 'latin-1'):
        try:
            with open(path, 'r', encoding=enc) as f:
                return f.read()
        except:
            continue
    return None

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

issues = []
fixes = []
files_scanned = 0
bom_stripped = 0

def process_file(fpath, rel):
    global files_scanned, bom_stripped
    files_scanned += 1
    stem = os.path.basename(fpath)[:-4]
    
    with open(fpath, 'rb') as f:
        raw = f.read()
    if raw[:3] == b'\xef\xbb\xbf':
        with open(fpath, 'wb') as f:
            f.write(raw[3:])
        bom_stripped += 1
    
    txt = read_file(fpath)
    if txt is None:
        issues.append(('READ_ERROR', rel, 'Cannot read'))
        return
    
    mods = re.findall(r'^\s*MODULE\s+(?!PROCEDURE\b)(\w+)', txt, re.MULTILINE | re.IGNORECASE)
    if mods:
        mod = mods[0]
        if mod != stem and mod.lower() != stem.lower():
            issues.append(('MODULE_MISMATCH', rel, f'MODULE {mod} != {stem}'))
    
    if 'ISO_FORTRAN_ENV' in txt:
        issues.append(('ISO_FORTRAN', rel, 'Uses ISO_FORTRAN_ENV'))
    
    prec_bare = re.search(r'^\s*USE\s+IF_Prec_Core\s*$', txt, re.MULTILINE | re.IGNORECASE)
    if prec_bare:
        needs = []
        if 'REAL(wp)' in txt or '_wp' in txt: needs.append('wp')
        if 'INTEGER(i4)' in txt or '(i4)' in txt: needs.append('i4')
        if 'INTEGER(i8)' in txt or '(i8)' in txt: needs.append('i8')
        if not needs: needs = ['wp', 'i4']
        pattern = re.compile(r'^(\s*USE\s+IF_Prec_Core)\s*$', re.MULTILINE | re.IGNORECASE)
        txt = pattern.sub(r'\1, ONLY: ' + ', '.join(needs), txt)
        write_file(fpath, txt)
        fixes.append((rel, f'PREC_NO_ONLY -> ONLY: {", ".join(needs)}'))
    
    if mods:
        mod = mods[0]
        expected = None
        if 'L3_MD' in rel: expected = 'MD_'
        elif 'L4_PH' in rel: expected = 'PH_'
        elif 'L5_RT' in rel: expected = 'RT_'
        if expected and not mod.startswith(expected):
            for p in ['MD_', 'PH_', 'RT_', 'IF_', 'NM_']:
                if mod.startswith(p) and p != expected:
                    issues.append(('WRONG_LAYER_PREFIX', rel,
                        f'MODULE {mod} has {p} prefix, expected {expected}'))
                    break

# Process directories
print('Directories found:')
for d in sorted(DIRS):
    print(f'  {os.path.relpath(d, ROOT)}')

for base_dir in DIRS:
    for dirpath, dirnames, filenames in os.walk(base_dir):
        for fname in sorted(filenames):
            if not fname.endswith('.f90'):
                continue
            fpath = os.path.join(dirpath, fname)
            rel = os.path.relpath(fpath, ROOT)
            process_file(fpath, rel)

# Process root files
print(f'\nRoot files: {len(ROOT_FILES)}')
for fpath in ROOT_FILES:
    rel = os.path.relpath(fpath, ROOT)
    process_file(fpath, rel)

# Report
print(f'\n=== Sprint 6: Output+Field+Bridge+WriteBack Audit ===')
print(f'Files scanned: {files_scanned}')
print(f'BOM stripped:  {bom_stripped}')
print(f'Auto-fixes:    {len(fixes)}')
print(f'Issues:        {len(issues)}')

if fixes:
    print(f'\n--- Auto-fixes ---')
    for p, d in fixes:
        print(f'  {p}: {d}')

cats = {}
for c, p, m in issues:
    cats.setdefault(c, []).append((p, m))
for c in sorted(cats):
    print(f'\n--- {c} ({len(cats[c])}) ---')
    for p, m in sorted(cats[c]):
        print(f'  {p}: {m}')

print(f'\n=== Summary ===')
for c in sorted(cats):
    print(f'  {c}: {len(cats[c])}')
print(f'  TOTAL: {len(issues)}')
