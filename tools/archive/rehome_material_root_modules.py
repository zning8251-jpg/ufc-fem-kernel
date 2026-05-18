#!/usr/bin/env python3
"""
Rehome non-leaf Material modules from T1 family directories to root public subdirs.

Goal:
  - keep 11 T1 dirs focused on leaf modules
  - move Core/Base/Call/Eval/Defn/Types/Kernels/Registry-style files
    into root public folders: Domain/Registry/Populate/Bridge/Contract/Shared/Dispatch
  - rewrite path strings project-wide

Run:
  python UFC/ufc_core/tools/rehome_material_root_modules.py
"""
from __future__ import annotations

from pathlib import Path
import os

ROOT = Path(__file__).resolve().parents[1]

MOVE_MAP = {
    # L3 root modules
    "L3_MD/Material/MD_Mat_API.f90": "L3_MD/Material/Domain/MD_Mat_API.f90",
    "L3_MD/Material/MD_Mat_Core.f90": "L3_MD/Material/Base/MD_Mat_Core.f90",
    "L3_MD/Material/MD_Mat_Domain_Types.f90": "L3_MD/Material/Domain/MD_Mat_Domain_Types.f90",
    "L3_MD/Material/MD_Mat_Reg.f90": "L3_MD/Material/Registry/MD_Mat_Reg.f90",
    "L3_MD/Material/MD_Mat_Ids.f90": "L3_MD/Material/Contract/MD_Mat_Ids.f90",
    "L3_MD/Material/MD_Mat_Bridge.f90": "L3_MD/Material/Bridge/MD_Mat_Bridge.f90",
    "L3_MD/Material/MD_Mat_Eval_Types.f90": "L3_MD/Material/Shared/MD_Mat_Eval_Types.f90",
    "L3_MD/Material/MD_Mat_Types.f90": "L3_MD/Material/Contract/MD_Mat_Types.f90",
    "L3_MD/Material/MD_Mat_Sync.f90": "L3_MD/Material/Shared/MD_Mat_Sync.f90",
    # L3 family non-leaf modules
    "L3_MD/Material/ELA/MD_Mat_ELA_ElasBase.f90": "L3_MD/Material/Shared/ELA/MD_Mat_ELA_ElasBase.f90",
    "L3_MD/Material/ELA/MD_Mat_ELA_ElasCall.f90": "L3_MD/Material/Dispatch/ELA/MD_Mat_ELA_ElasCall.f90",
    "L3_MD/Material/ELA/MD_Mat_ELA_PopulateMap.f90": "L3_MD/Material/Shared/ELA/MD_Mat_ELA_PopulateMap.f90",
    "L3_MD/Material/ELA/MD_Mat_ELA_CoupledDesc.f90": "L3_MD/Material/Contract/ELA/MD_Mat_ELA_CoupledDesc.f90",
    "L3_MD/Material/ELA/MD_Mat_ELA_Damping.f90": "L3_MD/Material/Shared/ELA/MD_Mat_ELA_Damping.f90",
    "L3_MD/Material/ELA/MD_Mat_ELA_Expansion.f90": "L3_MD/Material/Shared/ELA/MD_Mat_ELA_Expansion.f90",
    "L3_MD/Material/HYP/MD_Mat_HYP_Core.f90": "L3_MD/Material/Shared/HYP/MD_Mat_HYP_Core.f90",
    "L3_MD/Material/HYP/MD_Mat_HYP_Types.f90": "L3_MD/Material/Contract/HYP/MD_Mat_HYP_Types.f90",
    "L3_MD/Material/VSC/MD_Mat_VSC_ViscosityCore.f90": "L3_MD/Material/Shared/VSC/MD_Mat_VSC_ViscosityCore.f90",
    "L3_MD/Material/VSC/MD_Mat_VSC_CreepCore.f90": "L3_MD/Material/Shared/VSC/MD_Mat_VSC_CreepCore.f90",
    "L3_MD/Material/VSC/MD_Mat_VSC_Types.f90": "L3_MD/Material/Contract/VSC/MD_Mat_VSC_Types.f90",
    "L3_MD/Material/PLM/MD_Mat_PLM_Registry.f90": "L3_MD/Material/Registry/PLM/MD_Mat_PLM_Registry.f90",
    "L3_MD/Material/PLM/MD_Mat_PLM_Desc_Base.f90": "L3_MD/Material/Contract/PLM/MD_Mat_PLM_Desc_Base.f90",
    "L3_MD/Material/PLM/MD_Mat_PLM_TDep.f90": "L3_MD/Material/Shared/PLM/MD_Mat_PLM_TDep.f90",
    "L3_MD/Material/PLM/MD_Mat_PLM_PlastBase.f90": "L3_MD/Material/Dispatch/PLM/MD_Mat_PLM_PlastBase.f90",
    "L3_MD/Material/PLM/MD_Mat_PLM_PlastCall.f90": "L3_MD/Material/Dispatch/PLM/MD_Mat_PLM_PlastCall.f90",
    "L3_MD/Material/PLG/MD_MAT_PLG_GEOTECH_DESC.f90": "L3_MD/Material/Contract/PLG/MD_MAT_PLG_GEOTECH_DESC.f90",
    "L3_MD/Material/PLG/MD_Mat_PLG_GeoMatCore.f90": "L3_MD/Material/Shared/PLG/MD_Mat_PLG_GeoMatCore.f90",
    "L3_MD/Material/DMG/MD_Mat_DMG_Core.f90": "L3_MD/Material/Shared/DMG/MD_Mat_DMG_Core.f90",
    "L3_MD/Material/DMG/MD_Mat_DMG_Types.f90": "L3_MD/Material/Contract/DMG/MD_Mat_DMG_Types.f90",
    "L3_MD/Material/DMG/MD_MatLib_Dmg_Base.f90": "L3_MD/Material/Shared/DMG/MD_MatLib_Dmg_Base.f90",
    "L3_MD/Material/CMP/MD_Mat_CMP_Core.f90": "L3_MD/Material/Shared/CMP/MD_Mat_CMP_Core.f90",
    "L3_MD/Material/MPH/MD_Mat_MPH_ThermCore.f90": "L3_MD/Material/Shared/MPH/MD_Mat_MPH_ThermCore.f90",
    "L3_MD/Material/SPU/MD_Mat_SPU_Types.f90": "L3_MD/Material/Contract/SPU/MD_Mat_SPU_Types.f90",
    "L3_MD/Material/USR/MD_Mat_USR_Core.f90": "L3_MD/Material/Shared/USR/MD_Mat_USR_Core.f90",
    # L4 root modules
    "L4_PH/Material/PH_Mat_Reg_Core.f90": "L4_PH/Material/Registry/PH_Mat_Reg_Core.f90",
    "L4_PH/Material/PH_Mat_Eval.f90": "L4_PH/Material/Dispatch/PH_Mat_Eval.f90",
    "L4_PH/Material/PH_Mat_Ctx.f90": "L4_PH/Material/Domain/PH_Mat_Ctx.f90",
    "L4_PH/Material/PH_Material_Domain_Core.f90": "L4_PH/Material/Domain/PH_Material_Domain_Core.f90",
    "L4_PH/Material/PH_Mat_Standards.f90": "L4_PH/Material/Contract/PH_Mat_Standards.f90",
    "L4_PH/Material/PH_Mat_Integ_Core.f90": "L4_PH/Material/Shared/PH_Mat_Integ_Core.f90",
    "L4_PH/Material/PH_Mat_Constit_Core.f90": "L4_PH/Material/Shared/PH_Mat_Constit_Core.f90",
    "L4_PH/Material/PH_MatConstit_Type.f90": "L4_PH/Material/Contract/PH_MatConstit_Type.f90",
    "L4_PH/Material/PH_Mat_Utils.f90": "L4_PH/Material/Shared/PH_Mat_Utils.f90",
    "L4_PH/Material/PH_Mat_Orient_Core.f90": "L4_PH/Material/Shared/PH_Mat_Orient_Core.f90",
    "L4_PH/Material/UF_Material_Base.f90": "L4_PH/Material/Bridge/UF_Material_Base.f90",
    # L4 family non-leaf modules
    "L4_PH/Material/ELA/PH_Mat_ELA_ElasBase.f90": "L4_PH/Material/Shared/ELA/PH_Mat_ELA_ElasBase.f90",
    "L4_PH/Material/ELA/PH_Mat_ELA_ElasCall.f90": "L4_PH/Material/Dispatch/ELA/PH_Mat_ELA_ElasCall.f90",
    "L4_PH/Material/ELA/PH_UMAT_ElasticIso.f90": "L4_PH/Material/Bridge/ELA/PH_UMAT_ElasticIso.f90",
    "L4_PH/Material/ELA/PH_UMAT_Elastic_Ext.f90": "L4_PH/Material/Bridge/ELA/PH_UMAT_Elastic_Ext.f90",
    "L4_PH/Material/ELA/PH_Mat_ThermoPiezoElas.f90": "L4_PH/Material/Shared/MPH/PH_Mat_ThermoPiezoElas.f90",
    "L4_PH/Material/HYP/PH_Mat_HyperElas_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_HyperElas_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_HyperElas_Defn.f90": "L4_PH/Material/Contract/HYP/PH_Mat_HyperElas_Defn.f90",
    "L4_PH/Material/HYP/PH_Mat_MR_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_MR_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_Ogden_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_Ogden_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_NH_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_NH_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_Yeoh_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_Yeoh_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_AB_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_AB_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_Marlow_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_Marlow_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_ReducedPoly_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_ReducedPoly_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_PermanentSet_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_PermanentSet_Core.f90",
    "L4_PH/Material/HYP/PH_Mat_HyperElasMullins_Core.f90": "L4_PH/Material/Shared/HYP/PH_Mat_HyperElasMullins_Core.f90",
    "L4_PH/Material/HYP/PH_UMAT_MooneyRivlin.f90": "L4_PH/Material/Bridge/HYP/PH_UMAT_MooneyRivlin.f90",
    "L4_PH/Material/HYP/PH_UMAT_Ogden.f90": "L4_PH/Material/Bridge/HYP/PH_UMAT_Ogden.f90",
    "L4_PH/Material/HYP/PH_UMAT_NeoHookean.f90": "L4_PH/Material/Bridge/HYP/PH_UMAT_NeoHookean.f90",
    "L4_PH/Material/HYP/PH_UMAT_Yeoh.f90": "L4_PH/Material/Bridge/HYP/PH_UMAT_Yeoh.f90",
    "L4_PH/Material/HYP/PH_UMAT_HyperElas_Ext.f90": "L4_PH/Material/Bridge/HYP/PH_UMAT_HyperElas_Ext.f90",
    "L4_PH/Material/VSC/PH_Mat_Visc_Defn.f90": "L4_PH/Material/Contract/VSC/PH_Mat_Visc_Defn.f90",
    "L4_PH/Material/VSC/PH_Mat_Creep_Defn.f90": "L4_PH/Material/Contract/VSC/PH_Mat_Creep_Defn.f90",
    "L4_PH/Material/VSC/PH_Visco_Algo.f90": "L4_PH/Material/Shared/VSC/PH_Visco_Algo.f90",
    "L4_PH/Material/VSC/PH_Mat_Visc_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_Visc_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_Creep_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_Creep_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_TimeHardening_Creep_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_TimeHardening_Creep_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_Norton_Creep_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_Norton_Creep_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_LarsonMiller_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_LarsonMiller_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_HyperElasVisco_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_HyperElasVisco_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_HyperbolicSine_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_HyperbolicSine_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_BaileyNorton_Creep_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_BaileyNorton_Creep_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_StrainHardening_Creep_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_StrainHardening_Creep_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_LigamentMaxwell_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_LigamentMaxwell_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_FatigueCreepDamage_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_FatigueCreepDamage_Core.f90",
    "L4_PH/Material/VSC/PH_Mat_ViscoPlasticCoupled_Core.f90": "L4_PH/Material/Shared/VSC/PH_Mat_ViscoPlasticCoupled_Core.f90",
    "L4_PH/Material/VSC/PH_UMAT_LinearViscoElastic.f90": "L4_PH/Material/Bridge/VSC/PH_UMAT_LinearViscoElastic.f90",
    "L4_PH/Material/VSC/PH_UMAT_Visc_74.f90": "L4_PH/Material/Bridge/VSC/PH_UMAT_Visc_74.f90",
    "L4_PH/Material/PLM/PH_Mat_PLM_PlastBase.f90": "L4_PH/Material/Shared/PLM/PH_Mat_PLM_PlastBase.f90",
    "L4_PH/Material/PLM/PH_Mat_PLM_PlastCall.f90": "L4_PH/Material/Dispatch/PLM/PH_Mat_PLM_PlastCall.f90",
    "L4_PH/Material/PLM/PH_Mat_PLM_Eval.f90": "L4_PH/Material/Dispatch/PLM/PH_Mat_PLM_Eval.f90",
    "L4_PH/Material/PLM/PH_Mat_PLM_VM_Helpers.f90": "L4_PH/Material/Shared/PLM/PH_Mat_PLM_VM_Helpers.f90",
    "L4_PH/Material/PLM/PH_Mat_PLM_LegacyFacadeUMATs.f90": "L4_PH/Material/Dispatch/PLM/PH_Mat_PLM_LegacyFacadeUMATs.f90",
    "L4_PH/Material/PLM/Kernel/PH_Mat_PLM_Kernels.f90": "L4_PH/Material/Dispatch/PLM/PH_Mat_PLM_Kernels.f90",
    "L4_PH/Material/PLM/PH_UMAT_PLM_J2.f90": "L4_PH/Material/Bridge/PLM/PH_UMAT_PLM_J2.f90",
    "L4_PH/Material/PLM/PH_UMAT_PLM_Ext.f90": "L4_PH/Material/Bridge/PLM/PH_UMAT_PLM_Ext.f90",
    "L4_PH/Material/PLG/PH_Mat_Geotech_Defn.f90": "L4_PH/Material/Contract/PLG/PH_Mat_Geotech_Defn.f90",
    "L4_PH/Material/PLG/PH_Soils_Algo.f90": "L4_PH/Material/Shared/PLG/PH_Soils_Algo.f90",
    "L4_PH/Material/PLG/PH_Soils_Block.f90": "L4_PH/Material/Shared/PLG/PH_Soils_Block.f90",
    "L4_PH/Material/PLG/PH_UMAT_PLG_CamClay.f90": "L4_PH/Material/Bridge/PLG/PH_UMAT_PLG_CamClay.f90",
    "L4_PH/Material/PLG/PH_UMAT_PLG_Dp.f90": "L4_PH/Material/Bridge/PLG/PH_UMAT_PLG_Dp.f90",
    "L4_PH/Material/DMG/PH_Mat_Damage_Defn.f90": "L4_PH/Material/Contract/DMG/PH_Mat_Damage_Defn.f90",
    "L4_PH/Material/DMG/PH_UMAT_Dmg_74.f90": "L4_PH/Material/Bridge/DMG/PH_UMAT_Dmg_74.f90",
    "L4_PH/Material/MPH/PH_Mat_Therm_Defn.f90": "L4_PH/Material/Contract/MPH/PH_Mat_Therm_Defn.f90",
    "L4_PH/Material/MPH/PH_Mat_Therm_Core.f90": "L4_PH/Material/Shared/MPH/PH_Mat_Therm_Core.f90",
    "L4_PH/Material/MPH/PH_Mat_ThermElec_Core.f90": "L4_PH/Material/Shared/MPH/PH_Mat_ThermElec_Core.f90",
    "L4_PH/Material/MPH/PH_Mat_Piezo_Core.f90": "L4_PH/Material/Shared/MPH/PH_Mat_Piezo_Core.f90",
    "L4_PH/Material/MPH/PH_Piezo_Algo.f90": "L4_PH/Material/Shared/MPH/PH_Piezo_Algo.f90",
    "L4_PH/Material/MPH/PH_UMAT_Thermal_74.f90": "L4_PH/Material/Bridge/MPH/PH_UMAT_Thermal_74.f90",
    "L4_PH/Material/SPU/PH_Mat_Spcl_Defn.f90": "L4_PH/Material/Contract/SPU/PH_Mat_Spcl_Defn.f90",
    "L4_PH/Material/SPU/PH_Mat_Mag_Core.f90": "L4_PH/Material/Shared/SPU/PH_Mat_Mag_Core.f90",
    "L4_PH/Material/SPU/PH_Anneal_Algo.f90": "L4_PH/Material/Shared/SPU/PH_Anneal_Algo.f90",
    "L4_PH/Material/SPU/PH_UMAT_Special_74.f90": "L4_PH/Material/Bridge/SPU/PH_UMAT_Special_74.f90",
    "L4_PH/Material/USR/PH_UMAT_Intf_Enhanced.f90": "L4_PH/Material/Contract/USR/PH_UMAT_Intf_Enhanced.f90",
    "L4_PH/Material/USR/PH_UMAT_Types.f90": "L4_PH/Material/Contract/USR/PH_UMAT_Types.f90",
}

TEXT_EXTS = {
    ".f90", ".F90", ".vfproj", ".vcxproj", ".vcxproj.filters", ".md",
    ".py", ".txt", ".htm", ".cmake",
}


def replace_variants(text: str, old_rel: str, new_rel: str) -> str:
    old_posix = old_rel.replace("\\", "/")
    new_posix = new_rel.replace("\\", "/")
    old_win = old_rel.replace("/", "\\")
    new_win = new_rel.replace("/", "\\")
    old_abs_posix = str(ROOT / old_posix).replace("\\", "/")
    new_abs_posix = str(ROOT / new_posix).replace("\\", "/")
    old_abs_win = str(ROOT / old_posix)
    new_abs_win = str(ROOT / new_posix)
    for o, n in (
        (old_rel, new_rel),
        (old_posix, new_posix),
        (old_win, new_win),
        (old_abs_posix, new_abs_posix),
        (old_abs_win, new_abs_win),
    ):
        text = text.replace(o, n)
    return text


def patch_texts() -> int:
    changed = 0
    self_path = Path(__file__).resolve()
    for dirpath, _, files in os.walk(ROOT):
        dp = Path(dirpath)
        if "BuildLog" in dp.name and ".dir" in str(dp):
            continue
        for fn in files:
            p = dp / fn
            if p == self_path:
                continue
            if p.suffix not in TEXT_EXTS and fn != "CMakeLists.txt":
                continue
            raw = p.read_text(encoding="utf-8", errors="replace")
            new = raw
            for old_rel, new_rel in MOVE_MAP.items():
                new = replace_variants(new, old_rel, new_rel)
            if new != raw:
                p.write_text(new, encoding="utf-8", newline="\n")
                changed += 1
    return changed


def move_files() -> int:
    moved = 0
    for old_rel, new_rel in MOVE_MAP.items():
        src = ROOT / old_rel
        dst = ROOT / new_rel
        if not src.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            continue
        try:
            src.rename(dst)
            moved += 1
            print(f"MOVED {old_rel} -> {new_rel}")
        except PermissionError:
            print(f"SKIP LOCKED {old_rel}")
    return moved


def main() -> int:
    moved = move_files()
    patched = patch_texts()
    print(f"Moved {moved} files; patched {patched} text files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
