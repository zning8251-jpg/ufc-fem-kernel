import sys
import codecs
"""Fix systematic u->s / U->S corruption in RT_Asm_Solv.f90."""
path = r"D:\TEST7\UFC\ufc_core\L5_RT\Assembly\RT_Asm_Solv.f90"

with open(path, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

replacements = {
    "MODSLE": "MODULE",
    "SSBROSTINE": "SUBROUTINE",
    "FSNCTION": "FUNCTION",
    "RESSLT": "RESULT",
    "END MODULE RT_Asm_Solv\n": "",
    "INTENT(INOST": "INTENT(INOUT",
    "INTENT(OST": "INTENT(OUT",
    "ErrorStatSsType": "ErrorStatusType",
    "init_error_statSs": "init_error_status",
    "local_statSs": "local_status",
    "statSs_local": "status_local",
    "IF_STATSS_OK": "IF_STATUS_OK",
    "IF_STATSS_INVALID": "IF_STATUS_INVALID",
    "IF_STATSS_ERROR": "IF_STATUS_ERROR",
    "IF_STATSS_WARN": "IF_STATUS_WARN",
    "IF_STATSS_MEM_ERROR": "IF_STATUS_MEM_ERROR",
    "IF_STATSS_IO_ERROR": "IF_STATUS_IO_ERROR",
    "IF_STATSS_EXISTS": "IF_STATUS_EXISTS",
    "IF_STATSS_FATAL": "IF_STATUS_FATAL",
    "IF_STATSS_UNSUPPORTED": "IF_STATUS_UNSUPPORTED",
    "IF_STATSS_CONVERGED": "IF_STATUS_CONVERGED",
    "IF_STATSS_NOT_CONVERGED": "IF_STATUS_NOT_CONVERGED",
    "IF_STATSS_NOT_FOUND": "IF_STATUS_NOT_FOUND",
    "ProdSction": "Production",
    "ASTHORITY": "AUTHORITY",
    "aSthoritative": "authoritative",
    "CompStation": "Computation",
    "hSb": "hub",
    "lSmped": "lumped",
    "StatSs": "Status",
    "init_statSs": "init_status",
    "stSb": "stub",
    "reqSired": "required",
    "resolStion": "resolution",
    "sSrface": "surface",
    "BSild": "Build",
    "popSlate": "populate",
    "enSms": "enums",
    "AcoSstic": "Acoustic",
    "coSpling": "coupling",
    "GaSss": "Gauss",
    "NSmGaSss": "NumGauss",
    "JoSle": "Joule",
    "cSrl": "curl",
    "ModSle": "Module",
    "PArpose": "Purpose",
    "reqSested": "requested",
}

count = 0
for old, new in replacements.items():
    c = content.count(old)
    if c > 0:
        content = content.replace(old, new)
        count += c

print(f"Applied {count} replacements")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
