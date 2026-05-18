"""Fix stale file references in Sprint 5 CONTRACT.md files."""
import os, re

ROOT = r'd:\TEST7\UFC\ufc_core'

REMAP = {
    'MD_HashTable.f90': 'MD_Hash_Table.f90',
    'MD_IntIntegration.f90': 'MD_Int_Integration.f90',
    'MD_IntMapper.f90': 'MD_Int_Mapper.f90',
    'MD_IntMgr.f90': 'MD_Int_Mgr.f90',
    'MD_IntParser.f90': 'MD_Int_Parser.f90',
    'MD_IntSync.f90': 'MD_Int_Sync.f90',
    'PH_ConstrMPC.f90': 'PH_Constr_MPC.f90',
    'PH_ConstrPeriod.f90': 'PH_Constr_Period.f90',
    'PH_ConstrTie.f90': 'PH_Constr_Tie.f90',
    'RT_AsmSolv.f90': 'RT_Asm_Solv.f90',
    'RT_BCReactionForce.f90': 'RT_BC_ReactionForce.f90',
    'RT_ContAugLagSolv.f90': 'RT_Cont_AugLagSolv.f90',
    'RT_ContCtrl.f90': 'RT_Cont_Ctrl.f90',
    'RT_ContExpl.f90': 'RT_Cont_Expl.f90',
    'RT_ContSearch.f90': 'RT_Cont_Search.f90',
    'RT_ContSolv.f90': 'RT_Cont_Solv.f90',
    'RT_LBCImpl.f90': 'RT_LBC_Impl.f90',
    'RT_LBCProc.f90': 'RT_LBC_Proc.f90',
    'RT_ContactCore.f90': 'RT_Cont_Core.f90',
    'RT_SolvSparse.f90': 'RT_Solv_Sparse.f90',
}

# Also remap module names
MOD_REMAP = {}
for old, new in REMAP.items():
    MOD_REMAP[old[:-4]] = new[:-4]

contracts = [
    os.path.join(ROOT, 'L3_MD', 'Constraint', 'CONTRACT.md'),
    os.path.join(ROOT, 'L3_MD', 'Interaction', 'CONTRACT.md'),
    os.path.join(ROOT, 'L4_PH', 'Constraint', 'CONTRACT.md'),
    os.path.join(ROOT, 'L4_PH', 'Contact', 'CONTRACT.md'),
    os.path.join(ROOT, 'L4_PH', 'LoadBC', 'CONTRACT.md'),
    os.path.join(ROOT, 'L5_RT', 'Contact', 'CONTRACT.md'),
    os.path.join(ROOT, 'L5_RT', 'LoadBC', 'CONTRACT.md'),
]

total_changes = 0
for cpath in contracts:
    if not os.path.isfile(cpath):
        continue
    txt = open(cpath, encoding='utf-8-sig').read()
    changes = 0
    
    for old, new in sorted(REMAP.items(), key=lambda x: -len(x[0])):
        if old in txt:
            count = txt.count(old)
            txt = txt.replace(old, new)
            changes += count
    
    for old_mod, new_mod in sorted(MOD_REMAP.items(), key=lambda x: -len(x[0])):
        pattern = f'`{old_mod}`'
        replacement = f'`{new_mod}`'
        if pattern in txt:
            count = txt.count(pattern)
            txt = txt.replace(pattern, replacement)
            changes += count
    
    if changes > 0:
        with open(cpath, 'w', encoding='utf-8') as f:
            f.write(txt)
        print(f'{os.path.relpath(cpath, ROOT)}: {changes} references updated')
        total_changes += changes
    else:
        print(f'{os.path.relpath(cpath, ROOT)}: no changes')

print(f'\nTotal changes: {total_changes}')
