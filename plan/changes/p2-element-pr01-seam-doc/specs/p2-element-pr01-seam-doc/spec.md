# Spec: p2-element-pr01-seam-doc

## Requirements

### R1 — Golden seam documentation

The change **must** document the call chain from `RT_Asm_Brg_ElemMatPtIdx` through `RT_Asm_Solv_KeArg_AttachMatProps` to `Compute_Ke` with file paths and line anchors.

### R2 — Ke_Arg field table

A field table for `PH_Element_Compute_Ke_Arg` **must** match `PH_Elem_Def.f90` and L5 fill sites in `RT_Asm_Solv.f90`.

### R3 — Seam guardian baseline

Guardian results for seam anchor files **must** be recorded; P0 gate applies to anchor files listed in `PR01_GUARDIAN_AUDIT.md` except documented follow-ups.

### R4 — No hot-path code change

This change **must not** modify Fortran implementation in `ufc_core` except cross-reference links in `CONTRACT.md` if needed.

---

## Scenarios

### Scenario A — Package validation

- **When** `change-package validate --change-id p2-element-pr01-seam-doc --strict` runs  
- **Then** validation passes  

### Scenario B — Reviewer traces Ke path

- **Given** `design.md`  
- **When** a reviewer follows the chain  
- **Then** they can open listed files without searching the repo  

### Scenario C — MaterialRoute P0

- **Given** `PH_Elem_MaterialRoute.f90` has P0=1 in the audit  
- **When** planning next work  
- **Then** `p2-element-material-route-audit` is the designated fix change  
