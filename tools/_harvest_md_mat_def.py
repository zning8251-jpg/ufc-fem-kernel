import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "ufc_core"
syms: set[str] = set()
pat = re.compile(r"USE\s+MD_Mat_Def\s*,\s*ONLY\s*:\s*([^\n!]+)", re.I)
for p in root.rglob("*.f90"):
    text = p.read_text(encoding="utf-8", errors="replace")
    for m in pat.finditer(text):
        chunk = m.group(1)
        chunk = chunk.split("!")[0]
        for part in chunk.split(","):
            part = part.strip()
            if not part:
                continue
            name = part.split("=>")[-1].strip()
            if name:
                syms.add(name)
for s in sorted(syms):
    print(s)
print("TOTAL", len(syms), file=__import__("sys").stderr)
