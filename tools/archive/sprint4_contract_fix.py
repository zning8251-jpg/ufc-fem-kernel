"""Fix stale file references in Assembly and Solver CONTRACT.md files."""
import os

ROOT = r'd:\TEST7\UFC\ufc_core'

# Stale → Actual filename mapping
REMAP = {
    # Assembly CONTRACT stale refs
    'RT_AsmSolv.f90': 'RT_Asm_Solv.f90',
    'RT_Asm.f90': 'RT_Asm_Core.f90',
    'RT_AsmDofMap.f90': 'RT_Asm_DofMap.f90',
    'RT_AsmDomain.f90': 'RT_Asm_Domain.f90',
    'RT_AsmGlobal.f90': 'RT_Asm_Global.f90',
    'RT_AsmImpl.f90': 'RT_Asm_Impl.f90',
    'RT_AsmMassDamp.f90': 'RT_Asm_MassDamp.f90',
    'RT_AsmNLGeomDispatch.f90': 'RT_Asm_NLGeomDispatch.f90',
    'RT_AsmNLGeomEval.f90': 'RT_Asm_NLGeomEval.f90',
    'RT_AsmProc.f90': 'RT_Asm_Proc.f90',
    'RT_AsmShapeBeam.f90': 'RT_Asm_ShapeBeam.f90',
    'RT_AsmShapeMech2D.f90': 'RT_Asm_ShapeMech2D.f90',
    'RT_AsmShapeMechanicalField.f90': 'RT_Asm_ShapeMechanicalField.f90',
    'RT_AsmShapeMembrane.f90': 'RT_Asm_ShapeMembrane.f90',
    'RT_AsmShapeScalarField.f90': 'RT_Asm_ShapeScalarField.f90',
    'RT_AsmShapeShell.f90': 'RT_Asm_ShapeShell.f90',
    'RT_AsmUtil.f90': 'RT_Asm_Util.f90',
    'RT_AsmColor.f90': 'RT_Asm_Color.f90',
    'RT_Asm_NLGeom_Dispatch.f90': 'RT_Asm_NLGeomDispatch.f90',
    'RT_Asm_NLGeom_Eval.f90': 'RT_Asm_NLGeomEval.f90',
    'RT_Asm_MassDamp_Core.f90': 'RT_Asm_MassDamp.f90',
    'RT_Assembly_Domain_Core.f90': 'RT_Asm_Domain.f90',
    'MD_Assembly_Def.f90': 'MD_Asm_Def.f90',
    # Solver CONTRACT stale refs
    'RT_SolvNonlin.f90': 'RT_Solv_Nonlin.f90',
    'RT_Solv.f90': 'RT_Solv_Mgr.f90',
    'RT_Shared_Def.f90': 'RT_Solv_Def.f90',
    'RT_DofMapUtils.f90': 'RT_Asm_DofMapUtils.f90',
    'RT_AIConvPredictAlgo.f90': 'RT_AI_ConvPredictAlgo.f90',
    'RT_CoreMemPool.f90': 'RT_Solv_CoreMemPool.f90',
    'RT_SolvABAQUSReg.f90': 'RT_Solv_ABAQUSReg.f90',
    'RT_SolvContResidual.f90': 'RT_Solv_ContResidual.f90',
    'RT_SolvImpl.f90': 'RT_Solv_Impl.f90',
    'RT_SolvLin.f90': 'RT_Solv_Lin.f90',
    'RT_SolvProc.f90': 'RT_Solv_Proc.f90',
    'RT_SolvSparse.f90': 'RT_Solv_Sparse.f90',
    'RT_SolvTimeInt.f90': 'RT_Solv_TimeInt.f90',
}

# Also remap MODULE names (same pattern: remove underscore between layer and domain)
MOD_REMAP = {}
for old, new in REMAP.items():
    old_mod = old[:-4]  # strip .f90
    new_mod = new[:-4]
    if old_mod != new_mod:
        MOD_REMAP[old_mod] = new_mod

contracts = [
    os.path.join(ROOT, 'L5_RT', 'Assembly', 'CONTRACT.md'),
    os.path.join(ROOT, 'L5_RT', 'Solver', 'CONTRACT.md'),
]

for cpath in contracts:
    if not os.path.isfile(cpath):
        continue
    txt = open(cpath, encoding='utf-8-sig').read()
    changes = 0
    
    # Replace file references (longer names first to avoid partial matches)
    for old, new in sorted(REMAP.items(), key=lambda x: -len(x[0])):
        if old in txt:
            count = txt.count(old)
            txt = txt.replace(old, new)
            changes += count
    
    # Replace module references (in backticks)
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
    else:
        print(f'{os.path.relpath(cpath, ROOT)}: no changes needed')
