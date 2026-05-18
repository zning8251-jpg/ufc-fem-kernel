"""
Final global audit of ALL .f90 files in ufc_core.
Checks: MODULE=Filename, ISO_FORTRAN_ENV, USE IF_Prec_Core ONLY, BOM
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
LEGACY_DIRS = ['ExternalLibs']

issues = []
files_scanned = 0
bom_count = 0

for dp, dns, fns in os.walk(ROOT):
    is_legacy = any(leg in dp for leg in LEGACY_DIRS)
    for fname in sorted(fns):
        if not fname.endswith('.f90'):
            continue
        
        fpath = os.path.join(dp, fname)
        rel = os.path.relpath(fpath, ROOT)
        files_scanned += 1
        stem = fname[:-4]
        
        # BOM check
        with open(fpath, 'rb') as f:
            raw = f.read(3)
        if raw == b'\xef\xbb\xbf':
            bom_count += 1
        
        try:
            txt = open(fpath, encoding='utf-8-sig').read()
        except:
            issues.append(('READ_ERROR', rel, 'Cannot read'))
            continue
        
        if is_legacy:
            continue
        
        # MODULE = Filename (skip known LEGACY multi-module files)
        legacy_multi = any(x in rel for x in ['MD_KW.f90', 'MD_Int_Ctx.f90'])
        mods = re.findall(r'^\s*MODULE\s+(?!PROCEDURE\b)(\w+)', txt, re.MULTILINE | re.IGNORECASE)
        if mods and not legacy_multi:
            mod = mods[0]
            if mod != stem and mod.lower() != stem.lower():
                issues.append(('MODULE_MISMATCH', rel, f'MODULE {mod} != {stem}'))
        
        # ISO_FORTRAN_ENV (allow for OUTPUT_UNIT, INT8 only)
        if 'ISO_FORTRAN_ENV' in txt:
            # Check if it's only for non-precision items
            iso_match = re.search(r'ISO_FORTRAN_ENV.*ONLY:\s*(.+)', txt)
            if iso_match:
                items = iso_match.group(1).strip()
                precision_items = ['REAL64', 'REAL32', 'INT32', 'INT64', 'wp']
                has_precision = any(p in items for p in precision_items)
                if has_precision:
                    issues.append(('ISO_FORTRAN_PRECISION', rel, f'ISO_FORTRAN_ENV for precision: {items}'))
            else:
                issues.append(('ISO_FORTRAN_BARE', rel, 'ISO_FORTRAN_ENV without ONLY'))
        
        # USE IF_Prec_Core without ONLY
        if re.search(r'^\s*USE\s+IF_Prec_Core\s*$', txt, re.MULTILINE | re.IGNORECASE):
            issues.append(('PREC_NO_ONLY', rel, 'USE IF_Prec_Core without ONLY'))

print(f'=== FINAL GLOBAL AUDIT ===')
print(f'Files scanned: {files_scanned}')
print(f'Remaining BOMs: {bom_count}')
print(f'Issues: {len(issues)}')

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
print(f'  REMAINING BOMs: {bom_count}')
