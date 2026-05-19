# Spec: p2-element-legacy-contm-retire

## G6-W0 — Golden path isolation

- **Given** PR01 production Ke/Fe anchors listed in `LEGACY_CONTM_BOUNDARY.md`  
- **When** `tools/verify_element_golden_path_no_contm.py` runs  
- **Then** no `PH_Elem_Contm` / `Calc_Continuum*` reference appears in those files  

## G6-W0 — Harness

- **When** `python ufc_harness/run_harness.py tst --case p2-element-golden-seam` runs  
- **Then** verifier passes and seam anchor files have guardian P0=0  
