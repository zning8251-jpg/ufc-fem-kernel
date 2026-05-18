# Phase6 Track22 — SoA pilot notes (PH_Mat_Elas_Core)

Date: 2026-05-15

## Scope

Pilot module: `ufc_core/L4_PH/Material/Elas/PH_Mat_Elas_Core.f90`

## Change

- Added module-level `ph_elas_soa_props(:)` SAVE buffer.
- `PH_Mat_Elas_Populate_From_L3` mirrors L3 props into SoA buffer after `desc%props` copy.

## ALLOCATE baseline (rg)

- Before pilot: `PH_Mat_Elas_Core.f90` had 1 explicit `ALLOCATE` on `desc%props` in Populate path.
- After pilot: +1 `ALLOCATE` on `ph_elas_soa_props` (Populate-only, not IP hot loop).

## Next

- Bind `ph_elas_soa_props` into stress/tangent kernels without changing public API signatures.
- Extend to `PH_Mat_Interp_Core` per `REPORTS/PHASE6_Track22_SoA_Pilot.md`.
