import os, re, shutil
from pathlib import Path

base = Path(r'd:\TEST7\UFC\ufc_core')
ufc_root = Path(r'd:\TEST7\UFC')
excludes = {'ExternalLibs'}

mod_decl = re.compile(r'^(\s*)(MODULE)\s+(\w+)', re.IGNORECASE)
end_mod = re.compile(r'^(\s*)(END\s+MODULE)\s+(\w+)', re.IGNORECASE)

fixes = [
    ('L3_MD/Element/Mesh/MD_DOFMgr.f90', 'MD_DOFMgr', 'MD_DOF_Impl'),
    ('L3_MD/Element/Mesh/MD_Node.f90', 'MD_Node', 'MD_Mesh_NodeDef'),
    ('L4_PH/PH_L4L3MatContract.f90', 'PH_L4L3MatContract', 'PH_L4_L3MatContract'),
    ('L4_PH/PH_L4Populate.f90', 'PH_L4Populate', 'PH_L4_Populate'),
]

mod_renames = {}

for rel, old_mod, new_mod in fixes:
    old_path = base / rel.replace('/', os.sep)
    new_path = old_path.parent / (new_mod + '.f90')

    if not old_path.exists():
        print('NOT FOUND: %s' % old_path)
        continue

    # Update MODULE in file
    content = old_path.read_text(encoding='utf-8', errors='replace')
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        m = mod_decl.match(line)
        if m and m.group(3).lower() == old_mod.lower():
            line = '%s%s %s' % (m.group(1), m.group(2), new_mod)
        else:
            m2 = end_mod.match(line)
            if m2 and m2.group(3).lower() == old_mod.lower():
                line = '%s%s %s' % (m2.group(1), m2.group(2), new_mod)
        new_lines.append(line)
    old_path.write_text('\n'.join(new_lines), encoding='utf-8')

    # Rename file
    shutil.move(str(old_path), str(new_path))
    mod_renames[old_mod] = new_mod
    print('Renamed: %s -> %s' % (old_path.name, new_path.name))

# Update USE references
print('\nUpdating USE references...')
count = 0
search_dirs = [base, ufc_root / 'tests', ufc_root / 'docs', ufc_root / 'ufc_harness']
for search_dir in search_dirs:
    if not search_dir.exists():
        continue
    for dirpath, dirs, files in os.walk(search_dir):
        dirs[:] = [d for d in dirs if d not in excludes]
        for fn in files:
            if not fn.endswith('.f90'):
                continue
            fpath = Path(dirpath) / fn
            content = fpath.read_text(encoding='utf-8', errors='replace')
            new_content = content
            changed = False
            for old_m, new_m in mod_renames.items():
                pat = re.compile(
                    r'^(\s*USE\s+)' + re.escape(old_m) + r'\b',
                    re.IGNORECASE | re.MULTILINE
                )
                result, n = pat.subn(r'\g<1>' + new_m, new_content)
                if n > 0:
                    new_content = result
                    count += n
                    changed = True
            if changed:
                fpath.write_text(new_content, encoding='utf-8')

print('USE refs updated: %d' % count)
