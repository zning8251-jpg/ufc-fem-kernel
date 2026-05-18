"""
Sprint 4: Assembly + Solver Domain Audit & Fix
Covers: L5_RT/Assembly, L5_RT/Solver, L3_MD/Assembly, L3_MD/Analysis/Solver
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
DIRS = [
    os.path.join(ROOT, 'L5_RT', 'Assembly'),
    os.path.join(ROOT, 'L5_RT', 'Solver'),
    os.path.join(ROOT, 'L3_MD', 'Assembly'),
    os.path.join(ROOT, 'L3_MD', 'Analysis', 'Solver'),
    os.path.join(ROOT, 'L3_MD', 'Analysis', 'Step'),
]

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

for base_dir in DIRS:
    if not os.path.isdir(base_dir):
        print(f'SKIP: {os.path.relpath(base_dir, ROOT)} does not exist')
        continue
    for dirpath, dirnames, filenames in os.walk(base_dir):
        for fname in filenames:
            if not fname.endswith('.f90'):
                continue
            
            fpath = os.path.join(dirpath, fname)
            rel = os.path.relpath(fpath, ROOT)
            files_scanned += 1
            stem = fname[:-4]
            
            # --- BOM strip ---
            with open(fpath, 'rb') as f:
                raw = f.read()
            if raw[:3] == b'\xef\xbb\xbf':
                with open(fpath, 'wb') as f:
                    f.write(raw[3:])
                bom_stripped += 1
            
            txt = read_file(fpath)
            if txt is None:
                issues.append(('READ_ERROR', rel, 'Cannot read'))
                continue
            
            # --- MODULE = Filename ---
            mods = re.findall(r'^\s*MODULE\s+(?!PROCEDURE\b)(\w+)', txt, re.MULTILINE | re.IGNORECASE)
            if mods:
                mod = mods[0]
                if mod != stem:
                    if mod.lower() == stem.lower():
                        issues.append(('CASE_MISMATCH', rel, f'MODULE {mod} vs {stem}'))
                    else:
                        issues.append(('MODULE_MISMATCH', rel, f'MODULE {mod} != {stem}'))
            
            # --- ISO_FORTRAN_ENV ---
            if 'ISO_FORTRAN_ENV' in txt:
                issues.append(('ISO_FORTRAN', rel, 'Uses ISO_FORTRAN_ENV'))
            
            # --- USE IF_Prec without ONLY ---
            prec_bare = re.search(r'^\s*USE\s+IF_Prec_Core\s*$', txt, re.MULTILINE | re.IGNORECASE)
            if prec_bare:
                needs_wp = 'REAL(wp)' in txt or '_wp' in txt
                needs_i4 = 'INTEGER(i4)' in txt or '(i4)' in txt
                needs_i8 = 'INTEGER(i8)' in txt or '(i8)' in txt
                only_items = []
                if needs_wp: only_items.append('wp')
                if needs_i4: only_items.append('i4')
                if needs_i8: only_items.append('i8')
                if not only_items: only_items = ['wp', 'i4']
                
                pattern = re.compile(r'^(\s*USE\s+IF_Prec_Core)\s*$', re.MULTILINE | re.IGNORECASE)
                repl = r'\1, ONLY: ' + ', '.join(only_items)
                txt = pattern.sub(repl, txt)
                write_file(fpath, txt)
                fixes.append((rel, f'PREC_NO_ONLY → ONLY: {", ".join(only_items)}'))
            
            # --- Wrong layer prefix ---
            if mods:
                mod = mods[0]
                expected_prefix = None
                if 'L3_MD' in rel: expected_prefix = 'MD_'
                elif 'L4_PH' in rel: expected_prefix = 'PH_'
                elif 'L5_RT' in rel: expected_prefix = 'RT_'
                
                if expected_prefix and not mod.startswith(expected_prefix):
                    for wp_pref in ['MD_', 'PH_', 'RT_', 'IF_', 'NM_']:
                        if mod.startswith(wp_pref) and wp_pref != expected_prefix:
                            issues.append(('WRONG_LAYER_PREFIX', rel, 
                                f'MODULE {mod} has {wp_pref} prefix, expected {expected_prefix}'))
                            break

# --- Report ---
print(f'=== Sprint 4: Assembly + Solver Audit ===')
print(f'Files scanned: {files_scanned}')
print(f'BOM stripped:  {bom_stripped}')
print(f'Auto-fixes:    {len(fixes)}')
print(f'Issues:        {len(issues)}')

if fixes:
    print(f'\n--- Auto-fixes applied ---')
    for path, desc in fixes:
        print(f'  {path}: {desc}')

categories = {}
for cat, path, msg in issues:
    categories.setdefault(cat, []).append((path, msg))

for cat in sorted(categories.keys()):
    items = categories[cat]
    print(f'\n--- {cat} ({len(items)}) ---')
    for path, msg in sorted(items):
        print(f'  {path}: {msg}')

print(f'\n=== Summary ===')
for cat in sorted(categories.keys()):
    print(f'  {cat}: {len(categories[cat])}')
print(f'  TOTAL ISSUES: {len(issues)}')
