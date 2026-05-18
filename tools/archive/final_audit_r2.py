import os, re
from collections import Counter

base = r'd:\TEST7\UFC\ufc_core'
excludes = {'ExternalLibs'}
mod_pat = re.compile(r'^\s*MODULE\s+(\w+)', re.IGNORECASE | re.MULTILINE)

total = 0
seg_counts = Counter()
two_seg_legacy = 0
two_seg_no_legacy = []
mod_match = 0
mod_mismatch_legacy = 0
mod_mismatch_no_legacy = []

for root, dirs, files in os.walk(base):
    dirs[:] = [d for d in dirs if d not in excludes]
    for fn in sorted(files):
        if not fn.endswith('.f90'):
            continue
        total += 1
        stem = fn[:-4]
        parts = stem.split('_')
        seg = len(parts)
        seg_counts[seg] += 1

        path = os.path.join(root, fn)
        c = open(path, encoding='utf-8', errors='replace').read()
        mods = mod_pat.findall(c)
        has_legacy = 'NAMING NOTE' in c or 'LEGACY' in c[:500]

        if seg == 2:
            if has_legacy:
                two_seg_legacy += 1
            else:
                rel = os.path.relpath(path, base)
                two_seg_no_legacy.append(rel)

        if mods:
            first_mod = mods[0]
            if first_mod.lower() == stem.lower():
                mod_match += 1
            elif has_legacy:
                mod_mismatch_legacy += 1
            else:
                rel = os.path.relpath(path, base)
                mod_mismatch_no_legacy.append((rel, first_mod))

print('=' * 70)
print('UFC f90 ROUND-2 FINAL AUDIT')
print('=' * 70)
print()
print('Total .f90 files: %d' % total)
print()
print('--- Segment Analysis ---')
for seg in sorted(seg_counts.keys()):
    pct = 100.0 * seg_counts[seg] / total
    bar = '#' * int(pct / 2)
    print('  %d-seg: %4d (%5.1f%%) %s' % (seg, seg_counts[seg], pct, bar))
print()
print('--- Two-Segment Remaining ---')
print('  LEGACY annotated: %d' % two_seg_legacy)
print('  Non-LEGACY:       %d' % len(two_seg_no_legacy))
if two_seg_no_legacy:
    for r in two_seg_no_legacy:
        print('    %s' % r)
print()
print('--- MODULE == Filename ---')
print('  Match:              %d' % mod_match)
print('  Mismatch (LEGACY):  %d' % mod_mismatch_legacy)
print('  Mismatch (no tag):  %d' % len(mod_mismatch_no_legacy))
if mod_mismatch_no_legacy:
    for r, m in mod_mismatch_no_legacy:
        print('    %s -> MODULE %s' % (r, m))
print()

three_plus = sum(v for k, v in seg_counts.items() if k >= 3)
two_total = seg_counts.get(2, 0)
print('--- COMPLIANCE ---')
print('  Three-segment+: %d / %d (%.1f%%)' % (three_plus, total, 100.0 * three_plus / total))
print('  Two-segment:    %d (of which %d LEGACY)' % (two_total, two_seg_legacy))
if len(two_seg_no_legacy) == 0 and len(mod_mismatch_no_legacy) == 0:
    print()
    print('  AUDIT PASSED - all non-LEGACY files are three-segment with MODULE==Filename')
print('=' * 70)
