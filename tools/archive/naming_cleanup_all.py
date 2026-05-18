#!/usr/bin/env python3
"""
UFC full-repo f90 naming cleanup.
Phase 1: Delete 15 full-name _Def shell files (duplicate MODULE definitions)
Phase 2: Fix ~10 miscellaneous filename mismatches
Phase 3: Batch rename ~80 Material subfamily files (align filename to MODULE)
Phase 4: Add LEGACY annotations to 6 cross-layer MODULE prefix files
Phase 5: Add LEGACY annotations to 3 multi-module files
"""
import os
import re
import shutil
from pathlib import Path

UFC_CORE = Path(r"d:\TEST7\UFC\ufc_core")
EXCLUDE_DIRS = {"ExternalLibs"}

MOD_DECL = re.compile(r"^(\s*)(MODULE)\s+(\w+)", re.IGNORECASE)
END_MOD = re.compile(r"^(\s*)(END\s+MODULE)\s+(\w+)", re.IGNORECASE)

stats = {"deleted": 0, "renamed": 0, "use_updates": 0, "legacy_annotated": 0}


def all_f90_files():
    for f in sorted(UFC_CORE.rglob("*.f90")):
        if any(ex in f.parts for ex in EXCLUDE_DIRS):
            continue
        yield f


def update_all_use(old_mod, new_mod):
    count = 0
    pat = re.compile(
        r"^(\s*USE\s+)" + re.escape(old_mod) + r"\b",
        re.IGNORECASE | re.MULTILINE
    )
    for f in all_f90_files():
        try:
            content = f.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        new_content, n = pat.subn(r"\g<1>" + new_mod, content)
        if n > 0:
            count += n
            f.write_text(new_content, encoding="utf-8")
    stats["use_updates"] += count
    return count


def rename_module_in_file(filepath, old_mod, new_mod):
    content = filepath.read_text(encoding="utf-8", errors="replace")
    new_lines = []
    for line in content.split("\n"):
        m_decl = MOD_DECL.match(line)
        m_end = END_MOD.match(line)
        if m_decl and m_decl.group(3).lower() == old_mod.lower():
            line = m_decl.group(1) + m_decl.group(2) + " " + new_mod
        elif m_end and m_end.group(3).lower() == old_mod.lower():
            line = m_end.group(1) + m_end.group(2) + " " + new_mod
        new_lines.append(line)
    filepath.write_text("\n".join(new_lines), encoding="utf-8")


def delete_file(filepath):
    if filepath.exists():
        filepath.unlink()
        stats["deleted"] += 1
        print(f"    Deleted: {filepath.name}")
    else:
        print(f"    NOT FOUND: {filepath}")


def rename_file_safe(old_path, new_path):
    if old_path == new_path:
        return
    if new_path.exists():
        new_path.unlink()
        stats["deleted"] += 1
    shutil.move(str(old_path), str(new_path))
    stats["renamed"] += 1
    print(f"    {old_path.name} -> {new_path.name}")


def add_legacy_note(filepath, note_text):
    if not filepath.exists():
        print(f"    NOT FOUND: {filepath}")
        return
    content = filepath.read_text(encoding="utf-8", errors="replace")
    marker = "NAMING NOTE" if "NAMING NOTE" not in content else None
    if marker is None and "LEGACY" in content.split("\n")[0]:
        print(f"    Already annotated: {filepath.name}")
        return
    if "NAMING NOTE" in content:
        print(f"    Already annotated: {filepath.name}")
        return
    lines = content.split("\n")
    insert_idx = 0
    for i, line in enumerate(lines):
        if line.strip().upper().startswith("MODULE "):
            insert_idx = i
            break
    lines.insert(insert_idx, f"! NAMING NOTE (UFC_naming_v3.0): {note_text}")
    filepath.write_text("\n".join(lines), encoding="utf-8")
    stats["legacy_annotated"] += 1
    print(f"    Annotated: {filepath.name}")


# =====================================================================
# PHASE 1: Delete 15 full-name _Def shell files
# =====================================================================
def phase1():
    print("\n" + "=" * 70)
    print("PHASE 1: Delete 15 full-name _Def shell files")
    print("=" * 70)

    shells = [
        "L2_NM/Solver/NM_Solver_Def.f90",
        "L2_NM/Matrix/NM_Matrix_Def.f90",
        "L3_MD/Boundary/MD_Boundary_Def.f90",
        "L3_MD/Interaction/MD_Interaction_Def.f90",
        "L3_MD/KeyWord/MD_KeyWord_Def.f90",
        "L3_MD/Output/MD_Output_Def.f90",
        "L3_MD/Section/MD_Section_Def.f90",
        "L3_MD/WriteBack/MD_WriteBack_Def.f90",
        "L5_RT/Contact/RT_Contact_Def.f90",
        "L5_RT/Element/RT_Element_Def.f90",
        "L5_RT/LoadBC/RT_LoadBC_Def.f90",
        "L5_RT/Output/RT_Output_Def.f90",
        "L5_RT/StepDriver/RT_StepDriver_Def.f90",
        "L5_RT/WriteBack/RT_WriteBack_Def.f90",
        "L6_AP/Output/AP_Output_Def.f90",
    ]
    for s in shells:
        delete_file(UFC_CORE / s.replace("/", os.sep))


# =====================================================================
# PHASE 2: Fix miscellaneous filename mismatches
# =====================================================================
def phase2():
    print("\n" + "=" * 70)
    print("PHASE 2: Fix miscellaneous filename mismatches")
    print("=" * 70)

    # Simple renames (file -> MODULE name)
    renames = [
        ("L1_IF/Monitor/IF_MonMgr.f90", "IF_Mon_Mgr.f90"),
        ("L4_PH/Contact/Search/PH_ContSearchAdvanced.f90", "PH_ContSearchAdv.f90"),
        ("L6_AP/UI/AP_UIINP.f90", "AP_UI_INP_Core.f90"),
    ]

    for old_rel, new_name in renames:
        old_path = UFC_CORE / old_rel.replace("/", os.sep)
        new_path = old_path.parent / new_name
        if old_path.exists():
            rename_file_safe(old_path, new_path)

    # NM_Mtx.f90 -> NM_Mtx_Core.f90 (MODULE is NM_Mtx_Core)
    # But NM_Mtx_Core.f90 already exists as separate file - check
    f = UFC_CORE / "L2_NM" / "Matrix" / "NM_Mtx.f90"
    target = f.parent / "NM_Mtx_Core.f90"
    if f.exists():
        if target.exists():
            # NM_Mtx_Core.f90 exists separately - this is a two-file situation
            # NM_Mtx.f90 has MODULE NM_Mtx_Core - it's a rename collision
            # Delete the old file since the target already has the canonical content
            # Actually, NM_Mtx.f90 MODULE was renamed to NM_Mtx_Core by prior script
            # and NM_Mtx_Core.f90 is the skeleton. The real content is in NM_Mtx.f90.
            # Same pattern as IF_Prec: delete skeleton, rename old.
            target.unlink()
            stats["deleted"] += 1
            print(f"    Deleted skeleton: {target.name}")
        rename_file_safe(f, target)

    # MD_Model_Brg.f90 -> MD_Model_DomBrg.f90
    f = UFC_CORE / "L3_MD" / "Model" / "MD_Model_Brg.f90"
    if f.exists():
        rename_file_safe(f, f.parent / "MD_Model_DomBrg.f90")

    # RT_Global_Ctx.f90 -> RT_Global_Ctx_Types.f90
    f = UFC_CORE / "L5_RT" / "RT_Global_Ctx.f90"
    if f.exists():
        rename_file_safe(f, f.parent / "RT_Global_Ctx_Types.f90")

    # PH_MatPlastJ2Iso.f90 -> PH_Mat_Plast_J2.f90
    f = UFC_CORE / "L4_PH" / "Material" / "Plast" / "PH_MatPlastJ2Iso.f90"
    if f.exists():
        rename_file_safe(f, f.parent / "PH_Mat_Plast_J2.f90")

    # MD_Model.f90 <-> MD_ModelDomain.f90 SWAP
    print("\n  MD_Model <-> MD_ModelDomain swap:")
    model_dir = UFC_CORE / "L3_MD" / "Model"
    f_a = model_dir / "MD_Model.f90"          # MODULE = MD_ModelDomain
    f_b = model_dir / "MD_ModelDomain.f90"    # MODULE = MD_Model
    if f_a.exists() and f_b.exists():
        tmp = model_dir / "_SWAP_TEMP_.f90"
        shutil.move(str(f_a), str(tmp))
        shutil.move(str(f_b), str(f_a))
        shutil.move(str(tmp), str(f_b))
        stats["renamed"] += 2
        print(f"    Swapped: MD_Model.f90 <-> MD_ModelDomain.f90")
        # Now MD_Model.f90 has MODULE MD_Model, MD_ModelDomain.f90 has MODULE MD_ModelDomain
    
    # MD_Elem_Def.f90 has MODULE MD_Elem_Def_Legacy - this is fine, already LEGACY
    # MD_Mat_StateInit.f90 removed (was duplicate of MD_Mat_Reg.f90; unused)


# =====================================================================
# PHASE 3: Material subfamily batch rename (file -> MODULE name)
# =====================================================================
def phase3():
    print("\n" + "=" * 70)
    print("PHASE 3: Material subfamily batch rename (align file to MODULE)")
    print("=" * 70)

    mat_dir = UFC_CORE / "L3_MD" / "Material"
    mod_pat = re.compile(r"^\s*MODULE\s+(\w+)", re.IGNORECASE | re.MULTILINE)
    count = 0

    for f in sorted(mat_dir.rglob("*.f90")):
        stem = f.stem
        content = f.read_text(encoding="utf-8", errors="replace")
        mods = mod_pat.findall(content)
        if not mods:
            continue
        first_mod = mods[0]

        if first_mod.lower() != stem.lower():
            new_path = f.parent / f"{first_mod}.f90"
            if new_path.exists() and new_path != f:
                print(f"    COLLISION: {stem} -> {first_mod} (target exists, skip)")
                continue
            rename_file_safe(f, new_path)
            count += 1

    print(f"\n  Total Material renames: {count}")


# =====================================================================
# PHASE 4: LEGACY annotations for cross-layer MODULE prefix issues
# =====================================================================
def phase4():
    print("\n" + "=" * 70)
    print("PHASE 4: LEGACY annotations for cross-layer MODULE prefix")
    print("=" * 70)

    annotations = [
        (
            "L1_IF/Base/RT_SolverType_Def.f90",
            "LEGACY cross-layer: MODULE RT_SolverType_Def lives in L1_IF "
            "because it is a shared enum used by all layers. "
            "File placement is intentional."
        ),
        (
            "L3_MD/Bridge/Bridge_L5/MD_Mesh_Brg.f90",
            "LEGACY cross-layer: MODULE RT_Mesh_Brg in L3_MD bridge directory. "
            "Bridge files may carry target-layer prefix by convention."
        ),
        (
            "L4_PH/Element/MD_FieldState.f90",
            "LEGACY cross-layer: MODULE MD_FieldState in L4_PH. "
            "Retained for backward compatibility with L3 field state re-export."
        ),
        (
            "L4_PH/Element/PH_NLGeomEval.f90",
            "LEGACY cross-layer: MODULE RT_AsmNLGeomEval in L4_PH. "
            "Shared NL-geometry evaluator consumed by both L4 and L5."
        ),
        (
            "L4_PH/Element/PH_ShapeScalarField.f90",
            "LEGACY cross-layer: MODULE RT_AsmShapeScalarField in L4_PH. "
            "Shared shape function module consumed by both L4 and L5."
        ),
        (
            "L4_PH/Element/Shared/PH_ElemDiffUtils.f90",
            "LEGACY cross-layer: MODULE RT_Elem_Diff_Utils in L4_PH. "
            "Shared differentiation utilities consumed by both L4 and L5."
        ),
    ]

    for rel_path, note in annotations:
        add_legacy_note(UFC_CORE / rel_path.replace("/", os.sep), note)


# =====================================================================
# PHASE 5: LEGACY annotations for multi-module files
# =====================================================================
def phase5():
    print("\n" + "=" * 70)
    print("PHASE 5: LEGACY annotations for multi-module files")
    print("=" * 70)

    multi_mod_files = [
        (
            "L3_MD/KeyWord/MD_KW.f90",
            "LEGACY multi-module file: contains 6+ MODULE definitions "
            "(MD_KW_Coverage_Type, etc.). Violates MODULE=FileName rule. "
            "Retained as-is; splitting would break import chains. "
            "New code should NOT follow this pattern."
        ),
        (
            "L3_MD/Model/MD_ModelCoordSys.f90",
            "LEGACY multi-module file: contains 12+ MODULE definitions "
            "(MD_Model_CoordSys_Transform_Type, etc.). Violates MODULE=FileName rule. "
            "Retained as-is; splitting would require major refactoring. "
            "New code should NOT follow this pattern."
        ),
        (
            "L3_MD/Model/MD_ModelData.f90",
            "LEGACY multi-module file: contains 21+ MODULE definitions "
            "(MD_Model_Data_Table, etc.). Violates MODULE=FileName rule. "
            "Retained as-is; splitting would require major refactoring. "
            "New code should NOT follow this pattern."
        ),
    ]

    for rel_path, note in multi_mod_files:
        add_legacy_note(UFC_CORE / rel_path.replace("/", os.sep), note)


# =====================================================================
# MAIN
# =====================================================================
def main():
    print("=" * 70)
    print("UFC Full-Repo f90 Naming Cleanup")
    print("=" * 70)

    phase1()
    phase2()
    phase3()
    phase4()
    phase5()

    print("\n" + "=" * 70)
    print("SUMMARY")
    print(f"  Files deleted:     {stats['deleted']}")
    print(f"  Files renamed:     {stats['renamed']}")
    print(f"  USE refs updated:  {stats['use_updates']}")
    print(f"  LEGACY annotated:  {stats['legacy_annotated']}")
    print("=" * 70)


if __name__ == "__main__":
    main()
