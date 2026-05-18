import os, re
base = r'd:\TEST7\UFC\ufc_core'
excludes = {'ExternalLibs'}
mod_pat = re.compile(r'^\s*MODULE\s+(\w+)', re.IGNORECASE | re.MULTILINE)

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
        first_mod = mods[0] if mods else '(none)'
        has_legacy = 'NAMING NOTE' in c or 'LEGACY' in c[:500]
        rel = os.path.relpath(path, base)
        tag = ' [LEGACY]' if has_legacy else ''
        print('%-60s MOD=%-30s%s' % (rel, first_mod, tag))
