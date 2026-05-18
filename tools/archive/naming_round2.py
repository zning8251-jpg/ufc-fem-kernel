#!/usr/bin/env python3
"""
UFC f90 Round-2 Naming Cleanup
Phases A-D: CamelCase split, Element split, Material expand, Umbrella rename
"""
import os
import re
import shutil
from pathlib import Path
from collections import OrderedDict

UFC_ROOT = Path(r"d:\TEST7\UFC")
UFC_CORE = UFC_ROOT / "ufc_core"
EXCLUDE_DIRS = {"ExternalLibs"}
DRY_RUN = False

MOD_DECL_PAT = re.compile(r"^(\s*)(MODULE)\s+(\w+)", re.IGNORECASE)
END_MOD_PAT = re.compile(r"^(\s*)(END\s+MODULE)\s+(\w+)", re.IGNORECASE)

stats = {"renamed": 0, "mod_updated": 0, "use_updated": 0, "collision": 0}

# =====================================================================
# MANUAL OVERRIDES - exact stem -> new_stem (highest priority)
# Handles cases where auto-matching produces wrong results
# =====================================================================
MANUAL_OVERRIDES = {
    # Constraint domain (full name -> Constr abbreviation)
    "MD_ConstraintPairDef": "MD_Constr_PairDef",
    "MD_ConstraintPropDB": "MD_Constr_PropDB",
    "MD_ConstraintSurfBridge": "MD_Constr_SurfBridge",
    "MD_ConstraintSync": "MD_Constr_Sync",
    "PH_ConstraintDomain": "PH_Constr_Domain",
    # Contact (full name -> Cont abbreviation)
    "RT_ContactCore": "RT_Cont_Core2",
    "PH_ContactCore": "PH_Cont_Core2",
    # Ambiguous prefix conflicts
    "NM_Preconditioner": "NM_Solv_Preconditioner",
    "NM_NonlinSolv": "NM_Solv_Nonlin",
    "NM_NonlinearNewton": "NM_Solv_Newton",
    "NM_NonlinearArcLength": "NM_Solv_ArcLength",
    "NM_NonlinearTrustRegion": "NM_Solv_TrustRegion",
    "NM_QuasiNewtonFamily": "NM_Solv_QuasiNewton",
    "NM_ContinuationMethod": "NM_Solv_Continuation",
    "NM_LinearSolver": "NM_Solv_Linear",
    "NM_DirectSolver": "NM_Solv_Direct",
    "NM_IterSolver": "NM_Solv_IterSolver",
    "NM_ComplexLinearSolver": "NM_Solv_ComplexLinear",
    "NM_MemoryPool": "NM_Solv_MemPool",
    "NM_SparseSolvInterface": "NM_Solv_SparseInterface",
    "NM_SparsePakWrapper": "NM_Solv_SparsePakWrap",
    "NM_SparseMtx": "NM_Mtx_Sparse",
    "NM_AMGInterface": "NM_Solv_AMGInterface",
    "NM_GMRESSolveTranspose": "NM_Solv_GMRESTranspose",
    "NM_SpMVCSRTranspose": "NM_Mtx_SpMVCSRTranspose",
    "NM_AdaptiveTimeStep": "NM_TimeInt_AdaptStep",
    "NM_TimeStepController": "NM_TimeInt_StepCtrl",
    "NM_TSEventDet": "NM_TimeInt_EventDet",
    "NM_Vec": "NM_Mtx_Vec",
    # L3 ambiguous
    "MD_Connector": "MD_Int_Connector",
    "MD_Instance": "MD_Assem_Instance",
    "MD_UFCHashSetUtility": "MD_Base_HashSetUtil",
    "MD_UniFld": "MD_Out_UniFld",
    "MD_UniFldOps": "MD_Out_UniFldOps",
    "MD_PropMass": "MD_Sect_PropMass",
    "MD_PropNonStructMass": "MD_Sect_PropNonStructMass",
    "MD_PropPtMass": "MD_Sect_PropPtMass",
    "MD_PropRotInertia": "MD_Sect_PropRotInertia",
    "MD_Node": "MD_Mesh_Node",
    # L4 ambiguous
    "PH_AnalysisRouterModule": "PH_Base_AnalysisRouter",
    "PH_CrossDomainInterfaces": "PH_Base_CrossDomainIntf",
    "PH_ErrCode": "PH_Base_ErrCode",
    "PH_FlatToNestedLBC": "PH_LBC_FlatToNested",
    "PH_NestedToFlatLBC": "PH_LBC_NestedToFlat",
    "PH_GeostaticAlgo": "PH_LBC_GeostaticAlgo",
    "PH_Ldbc": "PH_LBC_Legacy",
    "PH_MultiPhysContrib": "PH_Field_MultiPhysContrib",
    "PH_Mass": "PH_Elem_Mass2",
    "PH_PhysicsUtils": "PH_Base_PhysicsUtils",
    "PH_AcousticSuite": "PH_Elem_AcousticSuite",
    "PH_AcousticTransientSolv": "PH_Elem_AcousticTransientSolv",
    "PH_ShapeMechanicalField": "PH_Elem_ShapeMechField",
    "PH_ShellNLGeom": "PH_Elem_ShellNLGeom",
    "PH_ThermalForceAsm": "PH_Elem_ThermalForceAsm",
    "PH_ThermalStrainKernel": "PH_Elem_ThermalStrainKernel",
    "PH_ThermalStressKernel": "PH_Elem_ThermalStressKernel",
    "PH_UMATIntfEnhanced": "PH_Mat_UMATIntfEnhanced",
    # L5 ambiguous
    "RT_CoreMemPool": "RT_Solv_CoreMemPool",
    "RT_DofMapUtils": "RT_Asm_DofMapUtils",
    "RT_ThermalMechanicalCpl": "RT_Elem_ThermalMechCpl",
    # L6 ambiguous
    "AP_PostProcDataAnal": "AP_Out_PostProcDataAnal",
    "AP_PostProcVisual": "AP_Out_PostProcVisual",
    # LinSolv family (NM_ files with LinSolv prefix)
    "NM_LinSolvCfg": "NM_Solv_LinCfg",
    "NM_LinSolvDir": "NM_Solv_LinDir",
    "NM_LinSolvDirCholesky": "NM_Solv_LinDirCholesky",
    "NM_LinSolvDirLU": "NM_Solv_LinDirLU",
    "NM_LinSolvDirMultifrontal": "NM_Solv_LinDirMultifrontal",
    "NM_LinSolvIter": "NM_Solv_LinIter",
    "NM_LinSolvIterAdv": "NM_Solv_LinIterAdv",
    "NM_LinSolvIterBiCGSTAB": "NM_Solv_LinIterBiCGSTAB",
    "NM_LinSolvIterCG": "NM_Solv_LinIterCG",
    "NM_LinSolvIterGMRES": "NM_Solv_LinIterGMRES",
    "NM_LinSolvPrec": "NM_Solv_LinPrec",
    "NM_LinSolvPrecAMG": "NM_Solv_LinPrecAMG",
    "NM_LinSolvPrecAMGMultilevel": "NM_Solv_LinPrecAMGMulti",
    "NM_LinSolvPrecILU": "NM_Solv_LinPrecILU",
    "NM_LinSolvPrecSSOR": "NM_Solv_LinPrecSSOR",
    # Umbrella collision fixes
    "AP_InpMgr": "AP_Inp_MgrLegacy",  # avoid collision with AP_Inp->AP_Inp_Mgr
}

# =====================================================================
# DOMAIN PREFIX TABLES (longest-match-first order)
# Only for straightforward splits where the domain abbreviation is clear
# =====================================================================
DOMAIN_PREFIXES = {
    "IF": [
        "ThreadWS", "Base", "Err", "IO", "Log", "Mem", "Mon", "Prec",
        "Reg", "AI", "Sym",
    ],
    "NM": [
        "TimeInt", "Solv", "Conv", "Cpl", "AI",
        "Assem", "Mtx", "BVH", "Brg", "Base", "Prec", "Eigen",
    ],
    "MD": [
        "Model", "Mesh", "Elem", "Part", "Sect", "Assem", "Step", "Solv",
        "Amp", "LBC", "Int", "Out", "WB", "KW", "KeyWord", "DOF",
        "Sets", "Mat", "Hash", "Cont", "Inp", "Base",
        "MatELA", "MatPLM", "MatSPU", "MatPOR", "MatPLG",
        "Aco", "Analysis",
    ],
    "PH": [
        "ElemDomain", "ElemContm", "Elem",
        "ContSearch", "ContCSR", "ContCtrl", "ContExpl", "ContSolv", "Cont",
        "ConstrMPC", "ConstrPeriod", "ConstrTie", "Constr",
        "Field", "Mat", "MatPlast", "MatCreep", "MatHyperElas",
        "MatGeotech", "MatGeo", "MatDam", "MatVisc", "MatSpcl",
        "MatTherm", "MatComp", "MatELA", "MatPLM",
        "Brg", "Out", "WB", "BC", "Load", "Base",
    ],
    "RT": [
        "Asm", "Cont", "Elem", "Mesh", "Solv", "Step",
        "Out", "LBC", "WB", "Log", "MF", "Writer", "AI", "Brg", "BC",
    ],
    "AP": [
        "InpScript", "InpInit", "Inp", "Parser",
        "Out", "Job", "Solv", "Reg", "Cfg", "UI", "Brg", "Base",
    ],
}

for layer in DOMAIN_PREFIXES:
    DOMAIN_PREFIXES[layer].sort(key=len, reverse=True)

# =====================================================================
# MATERIAL SUBFAMILY EXPANSION TABLE (Phase C)
# =====================================================================
MAT_SUBFAM_EXPAND = {
    "MD_HypAB": "MD_Hyp_ArrudaBoyce",
    "MD_HypVdW": "MD_Hyp_VanDerWaals",
    "MD_HypNeoHk": "MD_Hyp_NeoHookean1",
    "MD_HypNeoHooke": "MD_Hyp_NeoHookean2",
    "MD_HypOgdn2": "MD_Hyp_Ogden2",
    "MD_HypOgdn3": "MD_Hyp_Ogden3",
    "MD_HypMoon2": "MD_Hyp_MooneyRivlin2",
    "MD_HypMoon5": "MD_Hyp_MooneyRivlin5",
    "MD_HypMooneyRivlin": "MD_Hyp_MooneyRivlin",
    "MD_HypMarlow": "MD_Hyp_Marlow",
    "MD_HypFoam": "MD_Hyp_Foam",
    "MD_HypGent": "MD_Hyp_Gent",
    "MD_HypYeoh": "MD_Hyp_Yeoh",
    "MD_PlsAF": "MD_Pls_ArmstrongFrederick",
    "MD_PlsGTN": "MD_Pls_GTN",
    "MD_PlsJ2Iso": "MD_Pls_J2Iso",
    "MD_PlsJ2Tab": "MD_Pls_J2Tab",
    "MD_PlsBarlat": "MD_Pls_Barlat",
    "MD_PlsChaboche": "MD_Pls_Chaboche",
    "MD_PlsHill48": "MD_Pls_Hill48",
    "MD_PlsJohnsonCook": "MD_Pls_JohnsonCook",
    "MD_PlsKinComb": "MD_Pls_KinComb",
    "MD_PlsKinLin": "MD_Pls_KinLin",
    "MD_PlsORNL": "MD_Pls_ORNL",
    "MD_DmgCDP": "MD_Dmg_CDP",
    "MD_DmgCZM": "MD_Dmg_CZM",
    "MD_DmgFLD": "MD_Dmg_FLD",
    "MD_DmgGTN": "MD_Dmg_GTN",
    "MD_DmgJohnsonCook": "MD_Dmg_JohnsonCook",
    "MD_DmgLemaitre": "MD_Dmg_Lemaitre",
    "MD_DmgBrittle": "MD_Dmg_Brittle",
    "MD_DmgDuctile": "MD_Dmg_Ductile",
    "MD_DmgShear": "MD_Dmg_Shear",
    "MD_CmpCLT": "MD_Cmp_CLT",
    "MD_CmpFabric": "MD_Cmp_Fabric",
    "MD_CmpFoamVE": "MD_Cmp_FoamVE",
    "MD_CmpHashin": "MD_Cmp_Hashin",
    "MD_CmpJointed": "MD_Cmp_Jointed",
    "MD_CrpBodner": "MD_Crp_Bodner",
    "MD_CrpNorton": "MD_Crp_Norton",
    "MD_CrpPowerLaw": "MD_Crp_PowerLaw",
    "MD_CrpGarofalo": "MD_Crp_Garofalo",
    "MD_CrpAnand": "MD_Crp_Anand",
    "MD_CrpHarper": "MD_Crp_Harper",
    "MD_CrpRobinson": "MD_Crp_Robinson",
    "MD_CrpStrain": "MD_Crp_Strain",
    "MD_CrpAnneal": "MD_Crp_Anneal",
    "MD_CrpDuvautLions": "MD_Crp_DuvautLions",
    "MD_CrpPerzyna": "MD_Crp_Perzyna",
    "MD_CrpTwoLayer": "MD_Crp_TwoLayer",
    "MD_CrpUserDef": "MD_Crp_UserDef",
    "MD_VisKelvinVoigt": "MD_Vis_KelvinVoigt",
    "MD_VisPronyDev": "MD_Vis_PronyDev",
    "MD_VisPronyVol": "MD_Vis_PronyVol",
    "MD_VisWLF": "MD_Vis_WLF",
    "MD_ThmIso": "MD_Thm_Iso",
    "MD_ThmOrtho": "MD_Thm_Ortho",
    "MD_ThmPhaseChg": "MD_Thm_PhaseChg",
    "MD_ElaAniso": "MD_Ela_Aniso",
    "MD_ElaIso": "MD_Ela_Iso",
    "MD_ElaOrtho": "MD_Ela_Ortho",
    "MD_GeoMohrCoulomb": "MD_Geo_MohrCoulomb",
    "MD_GeoDruckerPrager": "MD_Geo_DruckerPrager",
    "MD_AcoAbsorb": "MD_Aco_Absorb",
    "MD_AcoLinear": "MD_Aco_Linear",
    "MD_UsrExt1": "MD_Usr_Ext1",
    "MD_UsrExt2": "MD_Usr_Ext2",
    "MD_UsrUMAT": "MD_Usr_UMAT",
    "MD_UsrVUMAT": "MD_Usr_VUMAT",
    "MD_MatPORGurson": "MD_MatPOR_Gurson",
    "MD_MatPORPorous": "MD_MatPOR_Porous",
    "MD_MatPORFoam3": "MD_MatPOR_Foam3",
    "MD_MatPORCrushFoam": "MD_MatPOR_CrushFoam",
    "MD_MatPLGCap": "MD_MatPLG_Cap",
    "MD_MatPLGJoint": "MD_MatPLG_Joint",
    "MD_MatPLGDruckerPrager": "MD_MatPLG_DruckerPrager",
    "MD_MatPLGMohrCoulomb": "MD_MatPLG_MohrCoulomb",
    "MD_MatPLGCamClay": "MD_MatPLG_CamClay",
    "MD_MatPLGCapped": "MD_MatPLG_Capped",
    "MD_MatPLGConcreteDP": "MD_MatPLG_ConcreteDP",
    "MD_MatPLGCreep": "MD_MatPLG_Creep",
    "MD_MatPLGExpansive": "MD_MatPLG_Expansive",
    "MD_MatPLGInterface": "MD_MatPLG_Interface",
    "MD_MatPLGRock": "MD_MatPLG_Rock",
}

# =====================================================================
# UMBRELLA MODULES (Phase D) - exact stem -> new_stem
# =====================================================================
UMBRELLA_RENAME = {
    "IF_AI": "IF_AI_Mgr",
    "IF_Base": "IF_Base_Mgr",
    "IF_ThreadWS": "IF_ThreadWS_Mgr",
    "IF_Sym": "IF_Sym_Mgr",
    "IF_Err": "IF_Err_Mgr",
    "IF_IO": "IF_IO_Mgr",
    "IF_L1Layer": "IF_L1_Layer",
    "NM_BVH": "NM_BVH_Mgr",
    "NM_TimeInt": "NM_TimeInt_Mgr",
    "NM_Solv": "NM_Solv_Mgr",
    "NM_Brg": "NM_Brg_Mgr",
    "NM_L2Layer": "NM_L2_Layer",
    "MD_Amp": "MD_Amp_Mgr",
    "MD_Step": "MD_Step_Mgr",
    "MD_Solv": "MD_Solv_Mgr",
    "MD_Assem": "MD_Assem_Mgr",
    "MD_LBC": "MD_LBC_Mgr",
    "MD_Int": "MD_Int_API",
    "MD_Mesh": "MD_Mesh_API",
    "MD_Out": "MD_Out_API",
    "MD_Part": "MD_Part_Mgr",
    "MD_Sect": "MD_Sect_Mgr",
    "MD_Elem": "MD_Elem_Mgr",
    "MD_Model": "MD_Model_Mgr",
    "MD_KW": None,  # LEGACY multi-module - skip
    "MD_Sets": "MD_Sets_Mgr",
    "MD_Mat": "MD_Mat_Mgr",
    "MD_Cont": "MD_Cont_Mgr",
    "MD_Const": "MD_Constr_Mgr",
    "MD_DOF": "MD_DOF_Mgr",
    "MD_Node": "MD_Mesh_NodeMgr",
    "MD_L3Layer": "MD_L3_Layer",
    "PH_Base": "PH_Base_Mgr",
    "PH_BC": "PH_BC_Mgr",
    "PH_Load": "PH_Load_Mgr",
    "PH_Cont": "PH_Cont_Mgr",
    "PH_Out": "PH_Out_Mgr",
    "PH_WB": "PH_WB_Mgr",
    "PH_L4Layer": "PH_L4_Layer",
    "RT_Asm": "RT_Asm_Mgr",
    "RT_Brg": "RT_Brg_Mgr",
    "RT_Out": "RT_Out_Mgr",
    "RT_Solv": "RT_Solv_Mgr",
    "RT_Amp": "RT_Amp_Mgr",
    "RT_L5Layer": "RT_L5_Layer",
    "AP_Base": "AP_Base_Mgr",
    "AP_Job": "AP_Job_Mgr",
    "AP_UI": "AP_UI_Mgr",
    "AP_Inp": "AP_Inp_Mgr",
    "AP_Cfg": "AP_Cfg_Mgr",
    "AP_L6Layer": "AP_L6_Layer",
}


def get_layer_prefix(stem):
    parts = stem.split('_')
    if len(parts) >= 2:
        return parts[0] + '_'
    return None


def split_camelcase(stem):
    layer_prefix = get_layer_prefix(stem)
    if not layer_prefix:
        return None
    layer = layer_prefix.rstrip('_')
    rest = stem[len(layer_prefix):]

    if layer not in DOMAIN_PREFIXES:
        return None

    for domain in DOMAIN_PREFIXES[layer]:
        if rest.startswith(domain) and len(rest) > len(domain):
            feature = rest[len(domain):]
            return "%s%s_%s" % (layer_prefix, domain, feature)

    return None


def compute_new_stem(stem, first_mod):
    # Priority 1: Manual overrides
    if stem in MANUAL_OVERRIDES:
        return MANUAL_OVERRIDES[stem]

    # Priority 2: Material subfamily expansion
    if stem in MAT_SUBFAM_EXPAND:
        return MAT_SUBFAM_EXPAND[stem]

    # Priority 3: Umbrella module
    if stem in UMBRELLA_RENAME:
        return UMBRELLA_RENAME[stem]

    # Priority 4: Element split (PH_Elem{Code} -> PH_Elem_{Code})
    layer_prefix = get_layer_prefix(stem)
    if layer_prefix == "PH_":
        rest = stem[3:]
        if rest.startswith("Elem") and len(rest) > 4:
            code = rest[4:]
            if code and code[0] != '_':
                return "PH_Elem_%s" % code

    # Priority 5: CamelCase domain split
    result = split_camelcase(stem)
    if result:
        return result

    return None


def all_f90_files(*roots):
    for root_dir in roots:
        if not root_dir.exists():
            continue
        for dirpath, dirs, files in os.walk(root_dir):
            dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
            for fn in sorted(files):
                if fn.endswith('.f90'):
                    yield Path(dirpath) / fn


def build_rename_map():
    mod_pat = re.compile(r'^\s*MODULE\s+(\w+)', re.IGNORECASE | re.MULTILINE)
    rename_map = OrderedDict()
    skip_list = []

    for f in all_f90_files(UFC_CORE):
        stem = f.stem
        parts = stem.split('_')
        if len(parts) != 2:
            continue

        content = f.read_text(encoding='utf-8', errors='replace')
        mods = mod_pat.findall(content)
        first_mod = mods[0] if mods else ''

        has_legacy = 'NAMING NOTE' in content or 'LEGACY' in content[:500]
        if has_legacy:
            skip_list.append((stem, 'LEGACY'))
            continue

        new_stem = compute_new_stem(stem, first_mod)
        if new_stem is None:
            skip_list.append((stem, 'NO_MATCH'))
            continue

        if new_stem == stem:
            continue

        rename_map[stem] = {
            'new_stem': new_stem,
            'old_path': f,
            'old_mod': first_mod,
            'new_mod': new_stem,
        }

    return rename_map, skip_list


def rename_module_in_file(filepath, old_mod, new_mod):
    content = filepath.read_text(encoding='utf-8', errors='replace')
    lines = content.split('\n')
    changed = False
    new_lines = []
    for line in lines:
        m = MOD_DECL_PAT.match(line)
        if m and m.group(3).lower() == old_mod.lower():
            line = "%s%s %s" % (m.group(1), m.group(2), new_mod)
            changed = True
        else:
            m2 = END_MOD_PAT.match(line)
            if m2 and m2.group(3).lower() == old_mod.lower():
                line = "%s%s %s" % (m2.group(1), m2.group(2), new_mod)
                changed = True
        new_lines.append(line)

    if changed:
        filepath.write_text('\n'.join(new_lines), encoding='utf-8')
        stats['mod_updated'] += 1
    return changed


def update_use_refs_batch(mod_renames):
    if not mod_renames:
        return 0

    patterns = {}
    for old_mod, new_mod in mod_renames.items():
        pat = re.compile(
            r'^(\s*USE\s+)' + re.escape(old_mod) + r'\b',
            re.IGNORECASE | re.MULTILINE
        )
        patterns[old_mod.lower()] = (pat, new_mod)

    search_dirs = [
        UFC_CORE, UFC_ROOT / "tests", UFC_ROOT / "docs", UFC_ROOT / "ufc_harness",
    ]

    count = 0
    for f in all_f90_files(*search_dirs):
        try:
            content = f.read_text(encoding='utf-8', errors='replace')
        except Exception:
            continue

        new_content = content
        file_changed = False
        for old_lower, (pat, new_mod) in patterns.items():
            result, n = pat.subn(r'\g<1>' + new_mod, new_content)
            if n > 0:
                new_content = result
                count += n
                file_changed = True

        if file_changed:
            f.write_text(new_content, encoding='utf-8')

    stats['use_updated'] += count
    return count


def execute_renames(rename_map):
    # Check for collisions
    target_map = {}
    collisions = []
    for stem, info in list(rename_map.items()):
        new_path = info['old_path'].parent / (info['new_stem'] + '.f90')
        target_key = str(new_path).lower()

        if new_path.exists() and new_path != info['old_path']:
            collisions.append((stem, info['new_stem'], str(new_path)))
            del rename_map[stem]
            continue

        if target_key in target_map:
            collisions.append((stem, info['new_stem'], 'DUPLICATE TARGET with %s' % target_map[target_key]))
            del rename_map[stem]
            continue

        target_map[target_key] = stem

    if collisions:
        print("\n  COLLISIONS (skipped):")
        for old, new, reason in collisions:
            print("    %s -> %s (%s)" % (old, new, reason))
            stats['collision'] += 1

    # Execute renames
    mod_renames = {}
    for stem, info in rename_map.items():
        old_path = info['old_path']
        new_path = old_path.parent / (info['new_stem'] + '.f90')

        if DRY_RUN:
            print("  [DRY] %s -> %s" % (old_path.name, new_path.name))
            continue

        old_mod = info['old_mod']
        new_mod = info['new_mod']
        if old_mod and old_mod.lower() != new_mod.lower():
            rename_module_in_file(old_path, old_mod, new_mod)
            mod_renames[old_mod] = new_mod

        shutil.move(str(old_path), str(new_path))
        stats['renamed'] += 1

    return mod_renames


def main():
    print("=" * 70)
    print("UFC f90 Round-2 Naming Cleanup")
    print("=" * 70)

    if DRY_RUN:
        print("*** DRY RUN MODE ***\n")

    print("Building rename map...")
    rename_map, skip_list = build_rename_map()

    phase_counts = {"A_camelcase": 0, "B_element": 0, "C_material": 0, "D_umbrella": 0}
    for stem, info in rename_map.items():
        if stem in MAT_SUBFAM_EXPAND:
            phase_counts["C_material"] += 1
        elif stem in UMBRELLA_RENAME:
            phase_counts["D_umbrella"] += 1
        elif stem.startswith("PH_Elem") and "_" not in stem[3:]:
            phase_counts["B_element"] += 1
        else:
            phase_counts["A_camelcase"] += 1

    print("\nRename plan:")
    for phase, count in phase_counts.items():
        print("  %s: %d files" % (phase, count))
    print("  Skipped: %d" % len(skip_list))
    print("  Total renames: %d" % len(rename_map))

    no_match = [s for s, r in skip_list if r == 'NO_MATCH']
    if no_match:
        print("\n  NO_MATCH (will stay two-segment):")
        for s in sorted(no_match):
            print("    %s" % s)

    print("\nExecuting renames...")
    mod_renames = execute_renames(rename_map)

    if mod_renames and not DRY_RUN:
        print("\nUpdating USE references for %d module renames..." % len(mod_renames))
        batch_size = 50
        items = list(mod_renames.items())
        for i in range(0, len(items), batch_size):
            batch = dict(items[i:i + batch_size])
            update_use_refs_batch(batch)
            print("  Batch %d/%d done" % (
                i // batch_size + 1,
                (len(items) + batch_size - 1) // batch_size))

    print("\n" + "=" * 70)
    print("SUMMARY")
    print("  Files renamed:     %d" % stats['renamed'])
    print("  MODULEs updated:   %d" % stats['mod_updated'])
    print("  USE refs updated:  %d" % stats['use_updated'])
    print("  Collisions:        %d" % stats['collision'])
    print("=" * 70)


if __name__ == "__main__":
    main()
