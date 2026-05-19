# Spec: contract-l4-element

## Requirements

### R1 — Contract traceability

The change package **must** document the L3→L4→L5 golden seam for `Compute_Ke` with explicit file anchors (`PH_Elem_Def`, `RT_Asm_Solv`, `PH_Elem_MaterialRoute`).

### R2 — Gap snapshot

A **P2_ELEMENT_GAP_SNAPSHOT** workflow artifact **must** list P2-G1–G6 with RAG status before any `p2-element-*` implementation MR merges.

### R3 — Scope fence

S1–S3 deliverables **must not** include functional changes to `ufc_core/L4_PH/Element/**/*.f90` except typo-level doc comments if any.

### R4 — P1 seam

Material slot access (`mat_pt_idx`, `PH_Mat_Domain%slot_pool`) **must** be referenced consistently with `L4_PH/Material/CONTRACT.md` R2.

---

## Scenarios

### Scenario A — Package validation

- **Given** this change directory on a branch  
- **When** `change-package validate --change-id contract-l4-element --strict` runs  
- **Then** validation passes  

### Scenario B — Auditor reads S1 checklist

- **Given** `design.md` §2  
- **When** a reviewer completes S1-1…S1-5 against `main`  
- **Then** each item is ticked or filed as a follow-up issue with change_id  

### Scenario C — Implementation wave blocked

- **Given** S2 snapshot shows P2-G6 **red**  
- **When** a developer opens `p2-element-legacy-contm-retire`  
- **Then** scope is limited to G6 debt and does not claim full P2 S7  
