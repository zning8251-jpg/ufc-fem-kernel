"""
Sprint 2: Element Domain Audit & Fix
Covers: L4_PH/Element, L3_MD/Element/Mesh, L5_RT/Element
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
DIRS = [
    os.path.join(ROOT, 'L4_PH', 'Element'),
    os.path.join(ROOT, 'L3_MD', 'Mesh'),
    os.path.join(ROOT, 'L5_RT', 'Element'),
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
            else:
                has_sub = bool(re.search(r'^\s*SUBROUTINE\s+', txt, re.MULTILINE | re.IGNORECASE))
                if has_sub:
                    issues.append(('NO_MODULE', rel, 'SUBROUTINE without MODULE wrapper'))
            
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
            
            # --- Missing IMPLICIT NONE (in modules only) ---
            if mods and 'IMPLICIT NONE' not in txt.upper():
                issues.append(('NO_IMPLICIT_NONE', rel, 'MODULE without IMPLICIT NONE'))

# --- Report ---
print(f'=== Sprint 2: Element Domain Audit ===')
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
    for path, msg in sorted(items)[:20]:  # Limit output
        print(f'  {path}: {msg}')
    if len(items) > 20:
        print(f'  ... and {len(items) - 20} more')

print(f'\n=== Summary ===')
for cat in sorted(categories.keys()):
    print(f'  {cat}: {len(categories[cat])}')
print(f'  TOTAL ISSUES: {len(issues)}')
print(f'  AUTO-FIXED: {len(fixes)}')
print(f'  BOM STRIPPED: {bom_stripped}')
