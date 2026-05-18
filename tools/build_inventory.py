import os, re, json

base = r'd:\TEST7\UFC\ufc_core'
excludes = {'ExternalLibs'}
mod_pat = re.compile(r'^\s*MODULE\s+(\w+)', re.IGNORECASE | re.MULTILINE)
results = []

for root, dirs, files in os.walk(base):
    dirs[:] = [d for d in dirs if d not in excludes]
    for fn in sorted(files):
        if not fn.endswith('.f90'):
            continue
        stem = fn[:-4]
        parts = stem.split('_')
        if len(parts) != 2:
            continue
        path = os.path.join(root, fn)
        c = open(path, encoding='utf-8', errors='replace').read()
        mods = mod_pat.findall(c)
        first_mod = mods[0] if mods else ''
        has_legacy = 'NAMING NOTE' in c or 'LEGACY' in c[:500]
        rel_dir = os.path.relpath(root, base).replace(os.sep, '/')
        results.append({
            'stem': stem,
            'mod': first_mod,
            'dir': rel_dir,
            'legacy': has_legacy
        })

with open(r'd:\TEST7\UFC\tools\two_seg_inventory.json', 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1)

print('Total two-segment files:', len(results))
from collections import Counter
layers = Counter()
for d in results:
    layer = d['dir'].split('/')[0] if '/' in d['dir'] else d['dir']
    layers[layer] += 1
for k, v in sorted(layers.items()):
    print('  %s: %d' % (k, v))
