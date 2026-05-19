# Spec: p1-material-plast-name-debt

## Requirements

### R1 — Guardian

After this change series, `guardian ufc_core/L4_PH/Material/Plast` **must** report **zero** NAME-001 violations unless explicitly listed in an allowlist file.

### R2 — No behavior change

Renames **must not** alter numerical results of existing tests or reference increments.

### R3 — PUBLIC API

If a **PUBLIC** procedure is renamed, either all `USE` sites in-repo are updated in the same PR, or a deprecated wrapper **must** remain for one release cycle.

---

## Scenarios

### Scenario A — Guardian clean

- **When** guardian runs on `Plast/`  
- **Then** NAME-001 count is 0 (or only allowlisted legacy exports)  

### Scenario B — Dispatch still builds

- **When** PLM paths call renamed Plast symbols  
- **Then** build/harness dispatch paths still pass guardian P0  
