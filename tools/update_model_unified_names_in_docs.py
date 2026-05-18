import os

root = os.path.join(
    os.path.dirname(__file__),
    "..",
    "docs",
    "03_Domain_Pillars",
    "DomainProcedureRegistry",
    "generated",
    "L3_MD",
    "Model",
)
root = os.path.normpath(root)

repls = [
    # Data 子域已合并为 MD_Model_Data_{Table,Parameter,Field,...}.f90；不再将 Registry 中的
    # Unified_* 标识重写为 MD_Mo_Da_* 缩写。
    ("MD_Model_CoordSys_Transform_Unified_Parse", "MD_Mo_CS_Xfm_Un_Pa"),
    ("MD_Model_CoordSys_Transform_Unified_Configure", "MD_Mo_CS_Xfm_Un_Cf"),
    ("MD_Model_CoordSys_System_Unified_Parse", "MD_Mo_CS_Sys_Un_Pa"),
    ("MD_Model_CoordSys_System_Unified_Cfg", "MD_Mo_CS_Sys_Un_Cf"),
    ("MD_Model_CoordSys_Orientation_Unified_Parse", "MD_Model_Coord_Orient_Parse"),
    ("MD_Model_CoordSys_Orientation_Unified_Configure", "MD_Model_Coord_Orient_Cfg"),
    ("MD_Model_CoordSys_Normal_Unified_Parse", "MD_Model_Coord_Normal_Parse"),
    ("MD_Model_CoordSys_Normal_Unified_Cfg", "MD_Model_Coord_Normal_Cfg"),
    ("MD_Model_Adv_Import_Unified_Parse", "MD_Mo_Adv_Im_Un_Pa"),
    ("MD_Model_Adv_Import_Unified_Cfg", "MD_Mo_Adv_Im_Un_Cf"),
    ("MD_Model_Adv_Prestress_Unified_Parse", "MD_Mo_Adv_Ps_Un_Pa"),
    ("MD_Model_Adv_Prestress_Unified_Cfg", "MD_Mo_Adv_Ps_Un_Cf"),
    ("MD_Model_Adv_Substructure_Unified_Parse", "MD_Mo_Adv_Su_Un_Pa"),
    ("MD_Model_Adv_Substructure_Unified_Configure", "MD_Mo_Adv_Su_Un_Cf"),
]
repls.sort(key=lambda x: -len(x[0]))

count = 0
for dirpath, _, files in os.walk(root):
    for fn in files:
        if not fn.endswith(".md"):
            continue
        path = os.path.join(dirpath, fn)
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            text = f.read()
        orig = text
        for old, new in repls:
            text = text.replace(old, new)
        if text != orig:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(text)
            count += 1
            print("updated", path)
print("files touched", count)
