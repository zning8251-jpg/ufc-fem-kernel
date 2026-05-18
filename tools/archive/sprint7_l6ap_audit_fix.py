"""
Sprint 7: L6_AP Application Layer Audit & Fix
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
L6_DIR = os.path.join(ROOT, 'L6_AP')

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

if not os.path.isdir(L6_DIR):
    print(f'ERROR: {L6_DIR} does not exist')
    exit(1)

# Also handle L0_Global if exists
l0_dir = os.path.join(ROOT, 'L0_Global')
scan_dirs = [L6_DIR]
if os.path.isdir(l0_dir):
    scan_dirs.append(l0_dir)

for base_dir in scan_dirs:
    for dirpath, dirnames, filenames in os.walk(base_dir):
        for fname in sorted(filenames):
            if not fname.endswith('.f90'):
                continue
            
            fpath = os.path.join(dirpath, fname)
            rel = os.path.relpath(fpath, ROOT)
            files_scanned += 1
            stem = fname[:-4]
            
            # BOM strip
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
            
            # MODULE = Filename
            mods = re.findall(r'^\s*MODULE\s+(?!PROCEDURE\b)(\w+)', txt, re.MULTILINE | re.IGNORECASE)
            if mods:
                mod = mods[0]
                if mod != stem and mod.lower() != stem.lower():
                    issues.append(('MODULE_MISMATCH', rel, f'MODULE {mod} != {stem}'))
            
            # ISO_FORTRAN_ENV
            if 'ISO_FORTRAN_ENV' in txt:
                issues.append(('ISO_FORTRAN', rel, 'Uses ISO_FORTRAN_ENV'))
            
            # USE IF_Prec without ONLY
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
            
            # Wrong layer prefix
            if mods:
                mod = mods[0]
                expected = None
                if 'L6_AP' in rel: expected = 'AP_'
                elif 'L0_Global' in rel: expected = None
                if expected and not mod.startswith(expected):
                    for p in ['MD_', 'PH_', 'RT_', 'IF_', 'NM_']:
                        if mod.startswith(p):
                            issues.append(('WRONG_LAYER_PREFIX', rel,
                                f'MODULE {mod} has {p} prefix, expected {expected}'))
                            break

print(f'=== Sprint 7: L6_AP + L0 Audit ===')
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
