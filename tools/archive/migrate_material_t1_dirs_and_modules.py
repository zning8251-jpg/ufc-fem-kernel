#!/usr/bin/env python3
"""
One-shot migration (run from repo root):
  - Rename L3_MD/Material & L4_PH/Material subdirs: Elastic->ELA, ...
  - Rename *.f90 files to match new MODULE names where applicable
  - Replace MODULE / END MODULE / USE substrings project-wide under ufc_core/

Usage:
  python UFC/ufc_core/tools/migrate_material_t1_dirs_and_modules.py
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # ufc_core

DIR_RENAME = [
    ("Elastic", "ELA"),
    ("HyperElas", "HYP"),
    ("Plastic", "PLM"),
    ("Geotech", "PLG"),
    ("PorousFoam", "POR"),
    ("Damage", "DMG"),
    ("Composite", "CMP"),
    ("Visc", "VSC"),
    ("Coupling", "MPH"),
    ("Special", "SPU"),
    ("UMAT", "USR"),
]

# Old module name -> new (apply longest keys first).
# NOTE: Do not run replace_in_text on this file — it would rewrite these tuples to (new,new).
MODULE_REPLACEMENTS: list[tuple[str, str]] = [
    ("MD_MAT_PLASTIC_DESC_BASE", "MD_MAT_PLM_DESC_BASE"),
    ("MD_MAT_PLAST_GEOTECH_DESC", "MD_MAT_PLG_GEOTECH_DESC"),
    ("MD_MAT_PLAST_POROUSFOAM_DESC", "MD_MAT_POR_FOAM_DESC"),
    ("MD_Mat_Plastic_Registry", "MD_Mat_PLM_Registry"),
    ("MD_Mat_Plastic_TDep", "MD_Mat_PLM_TDep"),
    ("MD_Mat_ConcDmgPlast", "MD_Mat_PLG_ConcreteDamage"),
    ("MD_Mat_SmearedCrackPlast", "MD_Mat_PLG_SmearedCrack"),
    ("MD_Mat_MscaleDmgPlast", "MD_Mat_DMG_Multiscale"),
    ("MD_Mat_ViscoDmgPlast", "MD_Mat_DMG_ViscoDamage"),
    ("MD_Mat_Types_HyperElastic", "MD_Mat_HYP_Types"),
    ("MD_Mat_HyperElastic_Core", "MD_Mat_HYP_Core"),
    ("MD_Mat_Types_Damage", "MD_Mat_DMG_Types"),
    ("MD_Mat_Damage_Core", "MD_Mat_DMG_Core"),
    ("MD_MatLib_Dmg_Base", "MD_Mat_DMG_LibBase"),
    ("MD_Mat_Composite_Core", "MD_Mat_CMP_Core"),
    ("MD_Mat_Viscosity_Core", "MD_Mat_VSC_ViscosityCore"),
    ("MD_Mat_Creep_Core", "MD_Mat_VSC_CreepCore"),
    ("MD_Mat_Types_Visco", "MD_Mat_VSC_Types"),
    ("MD_Mat_Therm_Core", "MD_Mat_MPH_ThermCore"),
    ("MD_Mat_Types_Other", "MD_Mat_SPU_Types"),
    ("MD_Mat_User_Core", "MD_Mat_USR_Core"),
    ("MD_Mat_GeoMat_Core", "MD_Mat_PLG_GeoMatCore"),
    ("MD_Mat_ElasPopulateMap", "MD_Mat_ELA_PopulateMap"),
    ("MD_Mat_CoupledElas_Desc", "MD_Mat_ELA_CoupledDesc"),
    ("MD_Mat_TransIsoElas", "MD_Mat_ELA_TransIsotropic"),
    ("MD_Mat_PorousElas", "MD_Mat_ELA_Porous"),
    ("MD_Mat_OrthoElas", "MD_Mat_ELA_Orthotropic"),
    ("MD_Mat_HypoElas", "MD_Mat_ELA_Hypoelastic"),
    ("MD_Mat_AnisoElas", "MD_Mat_ELA_Anisotropic"),
    ("MD_Mat_IsoElas", "MD_Mat_ELA_Isotropic"),
    ("MD_Mat_ElasBase", "MD_Mat_ELA_ElasBase"),
    ("MD_Mat_ElasCall", "MD_Mat_ELA_ElasCall"),
    ("MD_Mat_CrushFoamPlast", "MD_Mat_POR_CrushFoam"),
    ("MD_Mat_GeotechPlast", "MD_Mat_PLG_Geotech"),
    ("MD_Mat_SoftRockPlast", "MD_Mat_PLG_SoftRock"),
    ("MD_Mat_CamClayPlast", "MD_Mat_PLG_CamClay"),
    ("MD_Mat_JointPlast", "MD_Mat_PLG_Joint"),
    ("MD_Mat_FabricPlast", "MD_Mat_CMP_Fabric"),
    ("MD_Mat_Foam3Plast", "MD_Mat_POR_Foam3"),
    ("MD_Mat_PorousPlast", "MD_Mat_POR_Porous"),
    ("MD_Mat_GursonPlast", "MD_Mat_POR_Gurson"),
    ("MD_Mat_CapPlast", "MD_Mat_PLG_Cap"),
    ("MD_Mat_DpPlast", "MD_Mat_PLG_DruckerPrager"),
    ("MD_Mat_McPlast", "MD_Mat_PLG_MohrCoulomb"),
    ("MD_Mat_CrystalPlast", "MD_Mat_PLM_Crystal"),
    ("MD_Mat_RateDepPlast", "MD_Mat_PLM_RateDep"),
    ("MD_Mat_ViscDmgEMPlast", "MD_Mat_PLM_ViscDmgEM"),
    ("MD_Mat_ThermoViscPlast", "MD_Mat_PLM_ThermoVisc"),
    ("MD_Mat_SwiftVocePlast", "MD_Mat_PLM_SwiftVoce"),
    ("MD_Mat_MixedHardPlast", "MD_Mat_PLM_MixedHard"),
    ("MD_Mat_SmartMatPlast", "MD_Mat_PLM_SmartMat"),
    ("MD_Mat_FgmPlast", "MD_Mat_PLM_Fgm"),
    ("MD_Mat_TemmPlast", "MD_Mat_PLM_Temm"),
    ("MD_Mat_NanoPlast", "MD_Mat_PLM_Nano"),
    ("MD_Mat_CeramicPlast", "MD_Mat_PLM_Ceramic"),
    ("MD_Mat_BarlatPlast", "MD_Mat_PLM_Barlat"),
    ("MD_Mat_BiViscPlast", "MD_Mat_PLM_BiVisc"),
    ("MD_Mat_CastIronPlast", "MD_Mat_PLM_CastIron"),
    ("MD_Mat_ChabPlast", "MD_Mat_PLM_Chaboche"),
    ("MD_Mat_JcPlast", "MD_Mat_PLM_JohnsonCook"),
    ("MD_Mat_HillPlast", "MD_Mat_PLM_Hill"),
    ("MD_Mat_J2Plast", "MD_Mat_PLM_J2"),
    ("MD_Mat_ViscPlast", "MD_Mat_PLM_Viscoplastic"),
    ("MD_Mat_ZaPlast", "MD_Mat_PLM_Za"),
    ("MD_Mat_PlastBase", "MD_Mat_PLM_PlastBase"),
    ("MD_Mat_PlastCall", "MD_Mat_PLM_PlastCall"),
    ("MD_Mat_Expansion", "MD_Mat_ELA_Expansion"),
    ("MD_Mat_Damping", "MD_Mat_ELA_Damping"),
]

MODULE_REPLACEMENTS.sort(key=lambda x: len(x[0]), reverse=True)

# PH_* L4 modules (longest first)
PH_REPLACEMENTS: list[tuple[str, str]] = [
    ("PH_Mat_Plastic_VM_Helpers", "PH_Mat_PLM_VM_Helpers"),
    ("PH_UMAT_PlasticCamClay", "PH_UMAT_PLG_CamClay"),
    ("PH_UMAT_PlasticDP", "PH_UMAT_PLG_Dp"),
    ("PH_UMAT_PlasticJ2", "PH_UMAT_PLM_J2"),
    ("PH_UMAT_Plastic_Ext", "PH_UMAT_PLM_Ext"),
    ("PH_MAT_PLASTIC_EVAL", "PH_MAT_PLM_EVAL"),
    ("PH_MAT_PLASTIC_KERNELS", "PH_MAT_PLM_KERNELS"),
    ("PH_Mat_Plastic_Eval", "PH_Mat_PLM_Eval"),
    ("PH_Mat_Plastic_LegacyFacadeUMATs", "PH_Mat_PLM_LegacyFacadeUMATs"),
    ("PH_Mat_ConcDmgPlast", "PH_Mat_PLG_ConcreteDamage"),
    ("PH_Mat_SmearedCrackPlast", "PH_Mat_PLG_SmearedCrack"),
    ("PH_Mat_MscaleDmgPlast", "PH_Mat_DMG_Multiscale"),
    ("PH_Mat_ViscoDmgPlast", "PH_Mat_DMG_ViscoDamage"),
    ("PH_Mat_CrushFoamPlast", "PH_Mat_POR_CrushFoam"),
    # PH_Mat_PLG_Geotech removed; UF_Geotechnical_UMAT: PH_Mat_PLM_LegacyFacadeUMATs -> PH_MAT_PLM_KERNELS.
    ("PH_Mat_SoftRockPlast", "PH_Mat_PLG_SoftRock"),
    ("PH_Mat_CamClayPlast", "PH_Mat_PLG_CamClay"),
    ("PH_Mat_JointPlast", "PH_Mat_PLG_Joint"),
    ("PH_Mat_FabricPlast", "PH_Mat_CMP_Fabric"),
    ("PH_Mat_Foam3Plast", "PH_Mat_POR_Foam3"),
    ("PH_Mat_PorousPlast", "PH_Mat_POR_Porous"),
    ("PH_Mat_GursonPlast", "PH_Mat_POR_Gurson"),
    ("PH_Mat_CapPlast", "PH_Mat_PLG_Cap"),
    ("PH_Mat_DpPlast", "PH_Mat_PLG_DruckerPrager"),
    ("PH_Mat_McPlast", "PH_Mat_PLG_MohrCoulomb"),
    ("PH_Mat_CrystalPlast", "PH_Mat_PLM_Crystal"),
    ("PH_Mat_RateDepPlast", "PH_Mat_PLM_RateDep"),
    ("PH_Mat_ViscDmgEMPlast", "PH_Mat_PLM_ViscDmgEM"),
    ("PH_Mat_ThermoViscPlast", "PH_Mat_PLM_ThermoVisc"),
    ("PH_Mat_SwiftVocePlast", "PH_Mat_PLM_SwiftVoce"),
    ("PH_Mat_MixedHardPlast", "PH_Mat_PLM_MixedHard"),
    ("PH_Mat_SmartMatPlast", "PH_Mat_PLM_SmartMat"),
    ("PH_Mat_FgmPlast", "PH_Mat_PLM_Fgm"),
    ("PH_Mat_TemmPlast", "PH_Mat_PLM_Temm"),
    ("PH_Mat_NanoPlast", "PH_Mat_PLM_Nano"),
    ("PH_Mat_CeramicPlast", "PH_Mat_PLM_Ceramic"),
    ("PH_Mat_BarlatPlast", "PH_Mat_PLM_Barlat"),
    ("PH_Mat_BiViscPlast", "PH_Mat_PLM_BiVisc"),
    ("PH_Mat_CastIronPlast", "PH_Mat_PLM_CastIron"),
    ("PH_Mat_ChabPlast", "PH_Mat_PLM_Chaboche"),
    ("PH_Mat_JcPlast", "PH_Mat_PLM_JohnsonCook"),
    ("PH_Mat_HillPlast", "PH_Mat_PLM_Hill"),
    ("PH_Mat_J2Plast", "PH_Mat_PLM_J2"),
    ("PH_Mat_ViscPlast", "PH_Mat_PLM_Viscoplastic"),
    ("PH_Mat_ZaPlast", "PH_Mat_PLM_Za"),
    ("PH_Mat_PlastBase", "PH_Mat_PLM_PlastBase"),
    ("PH_Mat_PlastCall", "PH_Mat_PLM_PlastCall"),
    ("PH_Mat_IsoElas", "PH_Mat_ELA_Isotropic"),
    ("PH_Mat_OrthoElas", "PH_Mat_ELA_Orthotropic"),
    ("PH_Mat_TransIsoElas", "PH_Mat_ELA_TransIsotropic"),
    ("PH_Mat_AnisoElas", "PH_Mat_ELA_Anisotropic"),
    ("PH_Mat_PorousElas", "PH_Mat_ELA_Porous"),
    ("PH_Mat_HypoElas", "PH_Mat_ELA_Hypoelastic"),
    ("PH_Mat_LaminateElas", "PH_Mat_CMP_Laminate"),
    ("PH_Mat_ElasBase", "PH_Mat_ELA_ElasBase"),
    ("PH_Mat_ElasCall", "PH_Mat_ELA_ElasCall"),
]

PH_REPLACEMENTS.sort(key=lambda x: len(x[0]), reverse=True)

# Filename stems to rename after MODULE pass (old_base -> new_base) under Material/
FILE_RENAME_STEMS: list[tuple[str, str]] = [
    ("MD_Mat_Plastic_Desc_Base", "MD_Mat_PLM_Desc_Base"),
    ("MD_Mat_Plastic_Registry", "MD_Mat_PLM_Registry"),
    ("MD_Mat_Plastic_TDep", "MD_Mat_PLM_TDep"),
    ("MD_Mat_Plast_Geotech_Desc", "MD_MAT_PLG_GEOTECH_DESC"),
    ("MD_Mat_Plast_PorousFoam_Desc", "MD_MAT_POR_FOAM_DESC"),
    ("PH_Mat_Plastic_Kernels", "PH_Mat_PLM_Kernels"),
]

PATH_REPLACEMENTS: list[tuple[str, str]] = []
for old, new in DIR_RENAME:
    PATH_REPLACEMENTS.append((f"Material\\{old}\\", f"Material\\{new}\\"))
    PATH_REPLACEMENTS.append((f"Material/{old}/", f"Material/{new}/"))
    PATH_REPLACEMENTS.append((f"Material\\\\{old}\\\\", f"Material\\\\{new}\\\\"))


def rename_material_subdirs(base: Path) -> None:
    mat = base / "Material"
    if not mat.is_dir():
        return
    for old, new in DIR_RENAME:
        p_old = mat / old
        p_new = mat / new
        if p_old.is_dir() and not p_new.exists():
            p_old.rename(p_new)
            print(f"RENAMED DIR {p_old} -> {p_new}")
        elif p_old.is_dir() and p_new.exists():
            print(f"SKIP DIR (target exists): {p_new}")


def replace_in_text(text: str) -> str:
    for old, new in PATH_REPLACEMENTS:
        text = text.replace(old, new)
    for old, new in MODULE_REPLACEMENTS:
        text = text.replace(old, new)
    for old, new in PH_REPLACEMENTS:
        text = text.replace(old, new)
    return text


def process_file(path: Path) -> bool:
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    new = replace_in_text(raw)
    if new != raw:
        path.write_text(new, encoding="utf-8", newline="\n")
        return True
    return False


def rename_f90_in_material_tree() -> None:
    """Rename .f90 files in L3/L4 Material/** to new stems where mapping known."""
    stem_map: dict[str, str] = {}
    for old_m, new_m in MODULE_REPLACEMENTS:
        if old_m.startswith("MD_Mat_"):
            stem_map[old_m] = new_m
    for ob, nb in FILE_RENAME_STEMS:
        stem_map[ob] = nb
    # Plastic_Desc_Base file contains MODULE MD_MAT_PLM_DESC_BASE after text replace
    stem_map["MD_Mat_Plastic_Desc_Base"] = "MD_Mat_PLM_Desc_Base"
    for old_m, new_m in PH_REPLACEMENTS:
        if old_m.startswith("PH_Mat_") or old_m.startswith("PH_UMAT_"):
            stem_map[old_m] = new_m

    for layer in ("L3_MD", "L4_PH"):
        mroot = ROOT / layer / "Material"
        if not mroot.is_dir():
            continue
        for f in mroot.rglob("*.f90"):
            stem = f.stem
            if stem in stem_map:
                dest = f.with_name(stem_map[stem] + ".f90")
                if dest == f:
                    continue
                if dest.exists():
                    print(f"SKIP FILE exists: {dest}")
                    continue
                f.rename(dest)
                print(f"RENAMED FILE {f} -> {dest}")


def main() -> int:
    l3 = ROOT / "L3_MD" / "Material"
    l4 = ROOT / "L4_PH" / "Material"
    if not l3.is_dir() or not l4.is_dir():
        print("ERROR: missing Material dirs", file=sys.stderr)
        return 1

    rename_material_subdirs(ROOT / "L3_MD")
    rename_material_subdirs(ROOT / "L4_PH")

    exts = {".f90", ".F90", ".vfproj", ".vcxproj", ".vcxproj.filters", ".md", ".py", ".htm", ".txt"}
    migrate_self = Path(__file__).resolve()
    n = 0
    for dirpath, _, files in os.walk(ROOT):
        dp = Path(dirpath)
        # skip huge build logs optional
        if "BuildLog" in dp.name and ".dir" in str(dp):
            continue
        for fn in files:
            suf = Path(fn).suffix.lower()
            if suf not in exts and fn not in ("CMakeLists.txt",):
                continue
            if fn.endswith(".obj"):
                continue
            p = dp / fn
            if p == migrate_self:
                continue
            if process_file(p):
                n += 1
    print(f"Patched {n} files (text replacements).")

    rename_f90_in_material_tree()

    # Fix Plastic_Desc_Base: module line must be MD_MAT_PLM_DESC_BASE inside MD_Mat_PLM_Desc_Base.f90
    pdesc = ROOT / "L3_MD" / "Material" / "PLM" / "MD_Mat_PLM_Desc_Base.f90"
    if pdesc.is_file():
        t = pdesc.read_text(encoding="utf-8", errors="replace")
        t2 = t.replace("MD_MAT_PLASTIC_DESC_BASE", "MD_MAT_PLM_DESC_BASE")
        if t2 != t:
            pdesc.write_text(t2, encoding="utf-8", newline="\n")
            print("Fixed MD_MAT_PLM_DESC_BASE in Desc_Base file")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
