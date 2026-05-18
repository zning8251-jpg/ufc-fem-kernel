import json
data = json.load(open(r'd:\TEST7\UFC\REPORTS\TYPE_Sync_Audit.json', 'r', encoding='utf-8'))
total_m = 0
total_e = 0
for r in data:
    m = len(r['missing'])
    e = len(r['found_elsewhere'])
    total_m += m
    total_e += e
    print(f"{r['layer']}/{r['domain']}: CONTRACT={len(r['contract_types'])}, Def={len(r['def_types'])}, InDef={len(r['found_in_def'])}, Elsewhere={e}, MISSING={m}")
    if r['missing']:
        for t in r['missing']:
            print(f"  MISSING: {t}")
    if r['found_elsewhere']:
        for t, loc in r['found_elsewhere']:
            print(f"  ELSEWHERE: {t} -> {loc}")
print(f"\nTOTAL: MISSING={total_m}, ELSEWHERE={total_e}")
