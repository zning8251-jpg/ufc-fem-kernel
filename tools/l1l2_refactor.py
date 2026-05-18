#!/usr/bin/env python3
"""
L1_IF + L2_NM specific refactoring (17 items):
 1.  Delete IF_Error_Def.f90 (duplicate shell, MODULE already renamed to IF_Err_Def)
 2.  IF_Parser -> IF_IO_Parser, IF_Writer -> IF_IO_Writer
 3.  IF_Log -> IF_Log_Core (old file replaces existing skeleton)
 4.  IF_Mem -> IF_Mem_Core (old file replaces existing skeleton)
 5.  IF_StructMemPool -> IF_Mem_StructPool
 6.  IF_UnstructMemPool -> IF_Mem_UnStructPool
 7.  IF_Mon -> IF_Mon_Core (old file replaces existing skeleton)
 8.  Delete IF_Monitor_Def.f90 (duplicate shell)
 9.  IF_Prec -> IF_Prec_Core (old file replaces existing skeleton)
10.  IF_Reg -> IF_Reg_Core (old file replaces existing skeleton)
11.  Delete IF_Registry_Def.f90 (duplicate shell)
12.  NM_Base -> NM_Base_Core (old file replaces existing skeleton)
13.  NM_BaseErrCodes.f90 -> NM_Base_ErrCodes.f90 (file rename only, MODULE already correct)
14.  NM_BaseNorms.f90 -> NM_Base_Norms.f90 (file rename only)
15.  NM_BaseUtils.f90 -> NM_Base_Utils.f90 (file rename only)
16.  NM_Base_Def1 -> merge into NM_Base_Def (append types, update USE, delete Def1)
17.  NM_PrecConvert -> NM_Prec_Convert
"""
import os
import re
import shutil
from pathlib import Path

UFC_CORE = Path(r"d:\TEST7\UFC\ufc_core")
EXCLUDE_DIRS = {"ExternalLibs"}

# Pre-compile patterns
MOD_DECL = re.compile(r"^(\s*)(MODULE)\s+(\w+)", re.IGNORECASE)
END_MOD = re.compile(r"^(\s*)(END\s+MODULE)\s+(\w+)", re.IGNORECASE)

stats = {"use_updates": 0, "files_renamed": 0, "files_deleted": 0}


def all_f90_files():
    """Yield all .f90 files in ufc_core excluding ExternalLibs."""
    for f in sorted(UFC_CORE.rglob("*.f90")):
        if any(ex in f.parts for ex in EXCLUDE_DIRS):
            continue
        yield f


def update_all_use(old_mod, new_mod):
    """Update all USE old_mod references to USE new_mod across ufc_core."""
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
    """Rename MODULE declaration and END MODULE in a file."""
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


def rename_file(old_path, new_path):
    """Rename a file, handling collision by deleting target first."""
    if old_path == new_path:
        return
    if new_path.exists():
        new_path.unlink()
        print(f"  Deleted existing: {new_path.name}")
        stats["files_deleted"] += 1
    shutil.move(str(old_path), str(new_path))
    print(f"  Renamed: {old_path.name} -> {new_path.name}")
    stats["files_renamed"] += 1


def delete_file(filepath):
    """Delete a file."""
    if filepath.exists():
        filepath.unlink()
        print(f"  Deleted: {filepath}")
        stats["files_deleted"] += 1
    else:
        print(f"  NOT FOUND: {filepath}")


def do_full_rename(filepath, old_mod, new_mod, new_filename, target_dir=None):
    """Full: rename MODULE decl + USE refs + file."""
    print(f"\n  [{old_mod} -> {new_mod}]")
    if not filepath.exists():
        print(f"  SKIP: {filepath} not found")
        return
    rename_module_in_file(filepath, old_mod, new_mod)
    n = update_all_use(old_mod, new_mod)
    print(f"  Updated {n} USE references")
    dest_dir = target_dir or filepath.parent
    new_path = dest_dir / new_filename
    rename_file(filepath, new_path)


def main():
    print("=" * 70)
    print("L1_IF + L2_NM Refactoring (17 items)")
    print("=" * 70)

    # ===== 1. Delete IF_Error_Def.f90 =====
    print("\n[1] Delete IF_Error_Def.f90 (duplicate shell)")
    delete_file(UFC_CORE / "L1_IF" / "Error" / "IF_Error_Def.f90")

    # ===== 2. IF_Parser -> IF_IO_Parser, IF_Writer -> IF_IO_Writer =====
    print("\n[2] IF_Parser -> IF_IO_Parser, IF_Writer -> IF_IO_Writer")
    do_full_rename(
        UFC_CORE / "L1_IF" / "IO" / "IF_Parser.f90",
        "IF_Parser", "IF_IO_Parser", "IF_IO_Parser.f90"
    )
    do_full_rename(
        UFC_CORE / "L1_IF" / "IO" / "IF_Writer.f90",
        "IF_Writer", "IF_IO_Writer", "IF_IO_Writer.f90"
    )

    # ===== 3. IF_Log -> IF_Log_Core (replace existing skeleton) =====
    print("\n[3] IF_Log -> IF_Log_Core")
    # Delete existing skeleton first
    skel = UFC_CORE / "L1_IF" / "Log" / "IF_Log_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L1_IF" / "Log" / "IF_Log.f90",
        "IF_Log", "IF_Log_Core", "IF_Log_Core.f90"
    )

    # ===== 4. IF_Mem -> IF_Mem_Core (replace existing skeleton) =====
    print("\n[4] IF_Mem -> IF_Mem_Core")
    skel = UFC_CORE / "L1_IF" / "Memory" / "IF_Mem_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L1_IF" / "Memory" / "IF_Mem.f90",
        "IF_Mem", "IF_Mem_Core", "IF_Mem_Core.f90"
    )

    # ===== 5. IF_StructMemPool -> IF_Mem_StructPool =====
    print("\n[5] IF_StructMemPool -> IF_Mem_StructPool")
    do_full_rename(
        UFC_CORE / "L1_IF" / "Memory" / "IF_StructMemPool.f90",
        "IF_StructMemPool", "IF_Mem_StructPool", "IF_Mem_StructPool.f90"
    )

    # ===== 6. IF_UnstructMemPool -> IF_Mem_UnStructPool =====
    print("\n[6] IF_UnstructMemPool -> IF_Mem_UnStructPool")
    do_full_rename(
        UFC_CORE / "L1_IF" / "Memory" / "IF_UnstructMemPool.f90",
        "IF_UnstructMemPool", "IF_Mem_UnStructPool", "IF_Mem_UnStructPool.f90"
    )

    # ===== 7. IF_Mon -> IF_Mon_Core (replace existing skeleton) =====
    print("\n[7] IF_Mon -> IF_Mon_Core")
    skel = UFC_CORE / "L1_IF" / "Monitor" / "IF_Mon_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L1_IF" / "Monitor" / "IF_Mon.f90",
        "IF_Mon", "IF_Mon_Core", "IF_Mon_Core.f90"
    )

    # ===== 8. Delete IF_Monitor_Def.f90 (duplicate shell) =====
    print("\n[8] Delete IF_Monitor_Def.f90")
    delete_file(UFC_CORE / "L1_IF" / "Monitor" / "IF_Monitor_Def.f90")

    # ===== 9. IF_Prec -> IF_Prec_Core (replace existing skeleton) =====
    print("\n[9] IF_Prec -> IF_Prec_Core")
    skel = UFC_CORE / "L1_IF" / "Precision" / "IF_Prec_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L1_IF" / "Precision" / "IF_Prec.f90",
        "IF_Prec", "IF_Prec_Core", "IF_Prec_Core.f90"
    )

    # ===== 10. IF_Reg -> IF_Reg_Core (replace existing skeleton) =====
    print("\n[10] IF_Reg -> IF_Reg_Core")
    skel = UFC_CORE / "L1_IF" / "Registry" / "IF_Reg_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L1_IF" / "Registry" / "IF_Reg.f90",
        "IF_Reg", "IF_Reg_Core", "IF_Reg_Core.f90"
    )

    # ===== 11. Delete IF_Registry_Def.f90 (duplicate shell) =====
    print("\n[11] Delete IF_Registry_Def.f90")
    delete_file(UFC_CORE / "L1_IF" / "Registry" / "IF_Registry_Def.f90")

    # ===== 12. NM_Base -> NM_Base_Core (replace existing skeleton) =====
    print("\n[12] NM_Base -> NM_Base_Core")
    skel = UFC_CORE / "L2_NM" / "Base" / "NM_Base_Core.f90"
    if skel.exists():
        skel.unlink()
        print(f"  Deleted skeleton: {skel.name}")
        stats["files_deleted"] += 1
    do_full_rename(
        UFC_CORE / "L2_NM" / "Base" / "NM_Base.f90",
        "NM_Base", "NM_Base_Core", "NM_Base_Core.f90"
    )

    # ===== 13. NM_BaseErrCodes.f90 -> NM_Base_ErrCodes.f90 (file rename only) =====
    print("\n[13] NM_BaseErrCodes.f90 -> NM_Base_ErrCodes.f90 (file only)")
    f = UFC_CORE / "L2_NM" / "Base" / "NM_BaseErrCodes.f90"
    if f.exists():
        rename_file(f, f.parent / "NM_Base_ErrCodes.f90")

    # ===== 14. NM_BaseNorms.f90 -> NM_Base_Norms.f90 (file rename only) =====
    print("\n[14] NM_BaseNorms.f90 -> NM_Base_Norms.f90 (file only)")
    f = UFC_CORE / "L2_NM" / "Base" / "NM_BaseNorms.f90"
    if f.exists():
        rename_file(f, f.parent / "NM_Base_Norms.f90")

    # ===== 15. NM_BaseUtils.f90 -> NM_Base_Utils.f90 (file rename only) =====
    print("\n[15] NM_BaseUtils.f90 -> NM_Base_Utils.f90 (file only)")
    f = UFC_CORE / "L2_NM" / "Base" / "NM_BaseUtils.f90"
    if f.exists():
        rename_file(f, f.parent / "NM_Base_Utils.f90")

    # ===== 16. NM_Base_Def1 -> merge into NM_Base_Def =====
    print("\n[16] NM_Base_Def1 -> NM_Base_Def (merge)")
    src = UFC_CORE / "L2_NM" / "Base" / "NM_Base_Def1.f90"
    dst = UFC_CORE / "L2_NM" / "Base" / "NM_Base_Def.f90"
    if src.exists() and dst.exists():
        # Read NM_Base_Def1 content - extract everything between PUBLIC types and END MODULE
        src_content = src.read_text(encoding="utf-8", errors="replace")
        dst_content = dst.read_text(encoding="utf-8", errors="replace")

        # Extract PUBLIC declarations, PARAMETER declarations, and TYPE definitions from Def1
        lines = src_content.split("\n")
        extract_lines = []
        in_extract = False
        for line in lines:
            stripped = line.strip().upper()
            if stripped.startswith("PUBLIC") or stripped.startswith("INTEGER") or \
               stripped.startswith("TYPE") or stripped.startswith("REAL") or \
               stripped.startswith("LOGICAL") or stripped.startswith("CHARACTER") or \
               stripped.startswith("END TYPE") or in_extract:
                if stripped.startswith("END MODULE"):
                    break
                extract_lines.append(line)
                if stripped.startswith("TYPE ::") or stripped.startswith("TYPE::"):
                    in_extract = True
                if stripped.startswith("END TYPE"):
                    in_extract = False
                    extract_lines.append("")

        # Remove the END MODULE line from dst and append the extracted content
        dst_lines = dst_content.rstrip().split("\n")
        end_idx = None
        for i in range(len(dst_lines) - 1, -1, -1):
            if dst_lines[i].strip().upper().startswith("END MODULE"):
                end_idx = i
                break

        if end_idx is not None:
            merged_lines = dst_lines[:end_idx]
            merged_lines.append("")
            merged_lines.append("  !---------------------------------------------------------------------------")
            merged_lines.append("  ! Merged from NM_Base_Def1 (solver/control types)")
            merged_lines.append("  !---------------------------------------------------------------------------")
            merged_lines.extend(extract_lines)
            merged_lines.append("")
            merged_lines.append(dst_lines[end_idx])  # END MODULE NM_Base_Def
            merged_lines.append("")

            dst.write_text("\n".join(merged_lines), encoding="utf-8")
            print(f"  Merged {len(extract_lines)} lines from NM_Base_Def1 into NM_Base_Def")

        # Update USE references
        n = update_all_use("NM_Base_Def1", "NM_Base_Def")
        print(f"  Updated {n} USE references")
        # Delete source
        src.unlink()
        print(f"  Deleted: {src.name}")
        stats["files_deleted"] += 1

    # ===== 17. NM_PrecConvert -> NM_Prec_Convert =====
    print("\n[17] NM_PrecConvert -> NM_Prec_Convert")
    do_full_rename(
        UFC_CORE / "L2_NM" / "Base" / "NM_PrecConvert.f90",
        "NM_PrecConvert", "NM_Prec_Convert", "NM_Prec_Convert.f90"
    )

    # ===== Summary =====
    print("\n" + "=" * 70)
    print(f"SUMMARY: {stats['files_renamed']} files renamed, "
          f"{stats['files_deleted']} files deleted, "
          f"{stats['use_updates']} USE references updated")
    print("=" * 70)


if __name__ == "__main__":
    main()
