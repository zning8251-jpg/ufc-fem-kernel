"""
Sprint 0: L1_IF + L2_NM Audit & Fix
- Check MODULE = Filename stem
- Check three-segment naming
- Check USE IF_Prec_Core, ONLY: wp, i4 (not ISO_FORTRAN_ENV)
- Mark ExternalLibs as LEGACY
- Report CONTRACT.md alignment issues
"""
import os, re, glob

ROOT = r'd:\TEST7\UFC\ufc_core'
LAYERS = ['L1_IF', 'L2_NM']
LEGACY_DIRS = ['ExternalLibs']

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

# ---------- Collectors ----------
issues = []
fixes_applied = 0
files_scanned = 0
legacy_marked = 0

for layer in LAYERS:
    layer_dir = os.path.join(ROOT, layer)
    if not os.path.isdir(layer_dir):
        continue
    
    for dirpath, dirnames, filenames in os.walk(layer_dir):
        # Check if this is a LEGACY directory
        is_legacy = any(leg in dirpath for leg in LEGACY_DIRS)
        
        for fname in filenames:
            if not fname.endswith('.f90'):
                continue
            
            fpath = os.path.join(dirpath, fname)
            rel = os.path.relpath(fpath, ROOT)
            files_scanned += 1
            
            txt = read_file(fpath)
            if txt is None:
                issues.append(('READ_ERROR', rel, 'Cannot read file'))
                continue
            
            stem = fname[:-4]  # Remove .f90
            
            # --- Check 1: MODULE = Filename stem ---
            mod_match = re.search(r'^\s*MODULE\s+(\w+)\s*$', txt, re.MULTILINE | re.IGNORECASE)
            if mod_match:
                mod_name = mod_match.group(1)
                if mod_name != stem:
                    # Case-insensitive comparison first
                    if mod_name.lower() == stem.lower():
                        issues.append(('CASE_MISMATCH', rel, f'MODULE {mod_name} vs file {stem} (case only)'))
                    else:
                        issues.append(('MODULE_MISMATCH', rel, f'MODULE {mod_name} != file stem {stem}'))
            else:
                # Check for PROGRAM or bare SUBROUTINE
                prog_match = re.search(r'^\s*PROGRAM\s+', txt, re.MULTILINE | re.IGNORECASE)
                if not prog_match:
                    sub_match = re.search(r'^\s*SUBROUTINE\s+', txt, re.MULTILINE | re.IGNORECASE)
                    if sub_match:
                        issues.append(('NO_MODULE', rel, 'File has SUBROUTINE but no MODULE wrapper'))
            
            # --- Check 2: Three-segment naming ---
            parts = stem.split('_')
            if len(parts) < 3 and not is_legacy:
                # Allow layer files like IF_L1_Layer, NM_L2_Layer
                if not (stem.endswith('_Layer') or stem.startswith('Module') or stem.startswith('agmg')):
                    issues.append(('TWO_SEGMENT', rel, f'Only {len(parts)} segments: {stem}'))
            
            # --- Check 3: USE IF_Prec (precision) ---
            if 'ISO_FORTRAN_ENV' in txt and not is_legacy:
                issues.append(('ISO_FORTRAN', rel, 'Uses ISO_FORTRAN_ENV instead of IF_Prec_Core'))
            
            # Check for old IF_Prec without ONLY
            prec_no_only = re.search(r'USE\s+IF_Prec_Core\s*$', txt, re.MULTILINE | re.IGNORECASE)
            if prec_no_only:
                issues.append(('PREC_NO_ONLY', rel, 'USE IF_Prec_Core without ONLY clause'))
            
            # --- Check 4: LEGACY marking for ExternalLibs ---
            if is_legacy:
                if 'LEGACY' not in txt and 'legacy' not in txt:
                    issues.append(('NEEDS_LEGACY', rel, 'ExternalLibs file needs LEGACY marker'))
            
            # --- Check 5: Missing IMPLICIT NONE ---
            if mod_match and 'IMPLICIT NONE' not in txt.upper():
                issues.append(('NO_IMPLICIT_NONE', rel, 'MODULE without IMPLICIT NONE'))

# ---------- Report ----------
print(f"=== Sprint 0: L1_IF + L2_NM Audit Report ===")
print(f"Files scanned: {files_scanned}")
print(f"Issues found: {len(issues)}")
print()

# Group by category
categories = {}
for cat, path, msg in issues:
    categories.setdefault(cat, []).append((path, msg))

for cat in sorted(categories.keys()):
    items = categories[cat]
    print(f"\n--- {cat} ({len(items)} files) ---")
    for path, msg in sorted(items):
        print(f"  {path}: {msg}")

# ---------- Summary ----------
print(f"\n=== Summary ===")
for cat in sorted(categories.keys()):
    print(f"  {cat}: {len(categories[cat])}")
print(f"  TOTAL: {len(issues)}")
