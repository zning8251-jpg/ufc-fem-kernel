"""
Fix all stale .f90 file references across all CONTRACT.md files.
Uses fuzzy matching (normalize by removing underscores) to find actual files.
"""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'

# Build complete file inventory
all_files = {}  # filename -> relative path
for dp, dns, fns in os.walk(ROOT):
    for fn in fns:
        if fn.endswith('.f90'):
            all_files[fn] = os.path.relpath(os.path.join(dp, fn), ROOT)

# Build normalized lookup: filename_without_underscores_lowercase -> actual filename
norm_lookup = {}
for fn in all_files:
    norm = fn[:-4].lower().replace('_', '')
    norm_lookup.setdefault(norm, []).append(fn)

# Find all CONTRACT.md files
contracts = []
for dp, dns, fns in os.walk(ROOT):
    for fn in fns:
        if fn == 'CONTRACT.md':
            contracts.append(os.path.join(dp, fn))

total_fixes = 0
total_contracts = 0

for cpath in sorted(contracts):
    txt = open(cpath, encoding='utf-8-sig').read()
    refs = re.findall(r'`(\w+\.f90)`', txt)
    if not refs:
        continue
    
    changes = 0
    for ref in set(refs):
        if ref in all_files:
            continue  # Already correct
        
        # Try fuzzy match
        norm = ref[:-4].lower().replace('_', '')
        candidates = norm_lookup.get(norm, [])
        
        if len(candidates) == 1:
            actual = candidates[0]
            if ref != actual:
                txt = txt.replace(ref, actual)
                changes += txt.count(actual)  # Approximate
        elif len(candidates) > 1:
            # Prefer same layer prefix
            prefix = ref[:3]  # e.g., 'MD_', 'PH_', 'RT_'
            same_prefix = [c for c in candidates if c.startswith(prefix)]
            if len(same_prefix) == 1:
                actual = same_prefix[0]
                txt = txt.replace(ref, actual)
                changes += 1
    
    if changes > 0:
        with open(cpath, 'w', encoding='utf-8') as f:
            f.write(txt)
        rel = os.path.relpath(cpath, ROOT)
        print(f'{rel}: updated')
        total_fixes += 1
    total_contracts += 1

print(f'\nProcessed {total_contracts} CONTRACTs, updated {total_fixes}')
