import re

with open(r'd:\TEST7\UFC\ufc_core\L3_MD\Model\MD_Base_ObjModel_Core.f90', encoding='utf-8', errors='replace') as f:
    content = f.read()

for name in ['StateBase', 'GlobalState', 'NodeState', 'ElemState', 'CAT_STATE', 'UF_Model', 'UF_Part', 'UF_Section']:
    # Look for TYPE definitions and PUBLIC declarations
    patterns = [
        r'TYPE\s*,\s*PUBLIC\s*::\s*' + name,
        r'TYPE\s*::\s*' + name,
        r'PUBLIC\s*::\s*' + name,
        r'INTEGER.*PARAMETER.*' + name,
    ]
    found = False
    for p in patterns:
        m = re.search(p, content, re.IGNORECASE)
        if m:
            print(f'{name}: FOUND in MD_Base_ObjModel_Core -> {m.group(0)[:80]}')
            found = True
            break
    if not found:
        print(f'{name}: NOT in MD_Base_ObjModel_Core')
