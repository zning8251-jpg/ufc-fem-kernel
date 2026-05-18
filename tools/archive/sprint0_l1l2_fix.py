"""
Sprint 0: L1_IF + L2_NM Automated Fixes
Fixes:
  1. ISO_FORTRAN_ENV → IF_Prec_Core where possible
  2. Add LEGACY markers to ExternalLibs files
  3. Add ONLY clause to bare USE IF_Prec_Core
  4. Fix MODULE name mismatches (MODULE != filename stem)
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'
LAYERS = ['L1_IF', 'L2_NM']
DRY_RUN = False

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

fixes = []

# ============================================================================
# Fix 1: IF_Mem_ThreadSlab.f90 - ISO_FORTRAN_ENV
#   INT64 → i8, keep INT8 and OUTPUT_UNIT from ISO_FORTRAN_ENV
# ============================================================================
f1 = os.path.join(ROOT, 'L1_IF', 'Memory', 'IF_Mem_ThreadSlab.f90')
txt = read_file(f1)
if txt:
    old = 'USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: INT64, INT8, OUTPUT_UNIT\n  USE IF_Prec_Core, ONLY: wp'
    new = 'USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: INT8, OUTPUT_UNIT\n  USE IF_Prec_Core, ONLY: wp, i4, i8'
    if old in txt:
        txt = txt.replace(old, new)
        # Replace INTEGER(INT64) with INTEGER(i8)
        txt = txt.replace('INTEGER(INT64)', 'INTEGER(i8)')
        if not DRY_RUN:
            write_file(f1, txt)
        fixes.append(('IF_Mem_ThreadSlab.f90', 'Replaced INT64→i8, kept INT8/OUTPUT_UNIT from ISO'))
    else:
        fixes.append(('IF_Mem_ThreadSlab.f90', 'SKIP: pattern not found'))

# ============================================================================
# Fix 2: IF_Reg_Core.f90 - ISO_FORTRAN_ENV
#   INT64 → i8 (already imported), REAL64 → wp (already imported), keep OUTPUT_UNIT
# ============================================================================
f2 = os.path.join(ROOT, 'L1_IF', 'Registry', 'IF_Reg_Core.f90')
txt = read_file(f2)
if txt:
    old = '  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: INT64, REAL64, OUTPUT_UNIT\n  USE IF_Prec_Core, ONLY: wp, i4, i8'
    new = '  USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: OUTPUT_UNIT\n  USE IF_Prec_Core, ONLY: wp, i4, i8'
    if old in txt:
        txt = txt.replace(old, new)
        # Replace INTEGER(INT64) with INTEGER(i8), REAL(REAL64) with REAL(wp)
        txt = txt.replace('INTEGER(INT64)', 'INTEGER(i8)')
        txt = txt.replace('REAL(REAL64)', 'REAL(wp)')
        if not DRY_RUN:
            write_file(f2, txt)
        fixes.append(('IF_Reg_Core.f90', 'Replaced INT64→i8, REAL64→wp, kept OUTPUT_UNIT'))
    else:
        fixes.append(('IF_Reg_Core.f90', 'SKIP: pattern not found'))

# ============================================================================
# Fix 3: NM_TimeInt_BEAM.f90 - ISO_FORTRAN_ENV
#   wp => REAL64 → USE IF_Prec_Core, ONLY: wp, i4
# ============================================================================
f3 = os.path.join(ROOT, 'L2_NM', 'TimeInt', 'NM_TimeInt_BEAM.f90')
txt = read_file(f3)
if txt:
    old = 'USE, INTRINSIC :: ISO_FORTRAN_ENV, ONLY: wp => REAL64'
    new = 'USE IF_Prec_Core, ONLY: wp, i4'
    if old in txt:
        txt = txt.replace(old, new)
        if not DRY_RUN:
            write_file(f3, txt)
        fixes.append(('NM_TimeInt_BEAM.f90', 'Replaced ISO_FORTRAN_ENV wp=>REAL64 → IF_Prec_Core'))
    else:
        fixes.append(('NM_TimeInt_BEAM.f90', 'SKIP: pattern not found'))

# ============================================================================
# Fix 4: Add LEGACY markers to ExternalLibs files
# ============================================================================
extlib_dir = os.path.join(ROOT, 'L2_NM', 'ExternalLibs')
if os.path.isdir(extlib_dir):
    for fname in sorted(os.listdir(extlib_dir)):
        if not fname.endswith('.f90'):
            continue
        fpath = os.path.join(extlib_dir, fname)
        txt = read_file(fpath)
        if txt and 'LEGACY' not in txt:
            marker = '! LEGACY: External third-party library - exempt from UFC naming/style conventions\n'
            txt = marker + txt
            if not DRY_RUN:
                write_file(fpath, txt)
            fixes.append((fname, 'Added LEGACY marker'))

# ============================================================================
# Fix 5: Add ONLY clause to bare USE IF_Prec_Core
# ============================================================================
prec_no_only_files = [
    os.path.join(ROOT, 'L2_NM', 'Solver', 'LinSolv', 'NM_Solv_Direct.f90'),
    os.path.join(ROOT, 'L2_NM', 'Solver', 'LinSolv', 'NM_Solv_IterSolver.f90'),
    os.path.join(ROOT, 'L2_NM', 'Solver', 'LinSolv', 'NM_Solv_Linear.f90'),
    os.path.join(ROOT, 'L2_NM', 'Solver', 'LinSolv', 'NM_Solv_Preconditioner.f90'),
    os.path.join(ROOT, 'L2_NM', 'Solver', 'LinSolv', 'NM_Solv_SparsePakWrap.f90'),
    os.path.join(ROOT, 'L2_NM', 'Solver', 'NonlinSolv', 'NM_Solv_Nonlin.f90'),
]

for fpath in prec_no_only_files:
    if not os.path.isfile(fpath):
        fixes.append((os.path.basename(fpath), 'SKIP: file not found'))
        continue
    txt = read_file(fpath)
    if txt is None:
        continue
    fname = os.path.basename(fpath)
    # Find USE IF_Prec_Core without ONLY, being careful not to touch lines that already have ONLY
    pattern = re.compile(r'^(\s*USE\s+IF_Prec_Core)\s*$', re.MULTILINE | re.IGNORECASE)
    if pattern.search(txt):
        # Determine what kinds are used: scan for wp, i4, i8 usage
        needs_wp = 'REAL(wp)' in txt or '_wp' in txt
        needs_i4 = 'INTEGER(i4)' in txt or '(i4)' in txt
        needs_i8 = 'INTEGER(i8)' in txt or '(i8)' in txt
        
        only_list = []
        if needs_wp:
            only_list.append('wp')
        if needs_i4:
            only_list.append('i4')
        if needs_i8:
            only_list.append('i8')
        if not only_list:
            only_list = ['wp', 'i4']  # Default
        
        repl = r'\1, ONLY: ' + ', '.join(only_list)
        txt = pattern.sub(repl, txt)
        if not DRY_RUN:
            write_file(fpath, txt)
        fixes.append((fname, f'Added ONLY: {", ".join(only_list)}'))

# ============================================================================
# Fix 6: Fix MODULE name mismatches in non-ExternalLibs L2_NM files
# ============================================================================
module_fix_map = {
    # filename stem : current MODULE name → should rename MODULE to match file
    # NM_Solv_Dir.f90 has MODULE NM_SolvDir
    os.path.join(ROOT, 'L2_NM', 'Solver', 'NM_Solv_Dir.f90'): ('NM_SolvDir', 'NM_Solv_Dir'),
    # NM_Solv_Precond.f90 has MODULE NM_SolvPrecond
    os.path.join(ROOT, 'L2_NM', 'Solver', 'NM_Solv_Precond.f90'): ('NM_SolvPrecond', 'NM_Solv_Precond'),
    # NM_TimeInt_HHT.f90 has MODULE NM_TimeIntHHT
    os.path.join(ROOT, 'L2_NM', 'TimeInt', 'NM_TimeInt_HHT.f90'): ('NM_TimeIntHHT', 'NM_TimeInt_HHT'),
    # NM_TimeInt_Newmark.f90 has MODULE NM_TimeIntNewmark
    os.path.join(ROOT, 'L2_NM', 'TimeInt', 'NM_TimeInt_Newmark.f90'): ('NM_TimeIntNewmark', 'NM_TimeInt_Newmark'),
    # NM_TimeInt_RK.f90 has MODULE NM_TimeIntRK
    os.path.join(ROOT, 'L2_NM', 'TimeInt', 'NM_TimeInt_RK.f90'): ('NM_TimeIntRK', 'NM_TimeInt_RK'),
}

for fpath, (old_mod, new_mod) in module_fix_map.items():
    if not os.path.isfile(fpath):
        fixes.append((os.path.basename(fpath), 'SKIP: file not found'))
        continue
    txt = read_file(fpath)
    if txt is None:
        continue
    fname = os.path.basename(fpath)
    
    if old_mod in txt:
        txt = txt.replace(f'MODULE {old_mod}', f'MODULE {new_mod}')
        txt = txt.replace(f'END MODULE {old_mod}', f'END MODULE {new_mod}')
        if not DRY_RUN:
            write_file(fpath, txt)
        fixes.append((fname, f'MODULE {old_mod} → {new_mod}'))
        
        # Also fix USE references in other files within L2_NM
        for layer in LAYERS:
            layer_dir = os.path.join(ROOT, layer)
            for dp2, dns, fns in os.walk(layer_dir):
                for fn in fns:
                    if not fn.endswith('.f90'):
                        continue
                    fp2 = os.path.join(dp2, fn)
                    if fp2 == fpath:
                        continue
                    t2 = read_file(fp2)
                    if t2 and f'USE {old_mod}' in t2:
                        t2 = t2.replace(f'USE {old_mod}', f'USE {new_mod}')
                        if not DRY_RUN:
                            write_file(fp2, t2)
                        fixes.append((fn, f'Updated USE {old_mod} → {new_mod}'))

# ============================================================================
# Report
# ============================================================================
print(f"=== Sprint 0: L1_IF + L2_NM Fixes Applied ===")
print(f"Total fixes: {len(fixes)}")
print()
for fname, desc in fixes:
    print(f"  {fname}: {desc}")
