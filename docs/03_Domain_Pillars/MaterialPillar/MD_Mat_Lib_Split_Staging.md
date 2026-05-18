# MD_Mat_Lib Split Staging

Generated for the Material pillar rollout.

## Scope

`ufc_core/L3_MD/Material/Dispatch/MD_Mat_Lib.f90` remains a legacy facade. It must not gain new stress, tangent, return-mapping, or SDV evolution APIs. The split is staged so existing UMAT and registry type identities are not broken in one step.

## Current Cycle

```text
MD_Mat_Lib
  -> USE MD_MatReg_Algo
MD_MatReg_Algo
  -> USE MD_Mat_Lib legacy state and UMAT symbols
```

## Split Sequence

| Stage | Target | Action | Acceptance |
|-------|--------|--------|------------|
| S0 | Quarantine | Mark `MD_Mat_Lib` compute-like public surface as frozen | No new L3 stress/tangent/SDV API |
| S1 | Validation | Move populate guards and parameter checks toward `Shared/MD_Mat_Validation.f90` or a narrow populate validation helper | `PH_L4_Populate_Material` can validate without expanding `MD_Mat_Lib` |
| S2 | Metadata | Move material model metadata and registry lists toward `Registry/MD_MatReg_Algo.f90` helpers | Registry owns metadata; facade re-exports only if required |
| S3 | Legacy state | Keep `DmgState` / `FatigueState` / `CreepState` type identity stable until matching UMAT procedures migrate | No Fortran derived-type identity break |
| S4 | UMAT bundle | Move `MD_MAT_UMAT_*` procedures into a dedicated User/Bridge boundary | `MD_MatReg_Algo` no longer imports them from `MD_Mat_Lib` |
| S5 | Facade shrink | `MD_Mat_Lib` becomes compatibility-only | Lib ↔ Registry cycle removed |

## Do Not Do

- Do not move L4 constitutive kernels back into L3.
- Do not rename the 200-file Material tree as part of this split.
- Do not introduce `*_Arg` wrappers that only carry `status`.
- Do not change UMAT/VUMAT public data shapes until a dedicated user-material closure test exists.

## Verification Gates

| Gate | Command / Evidence |
|------|--------------------|
| Inventory | `python tools/material_pillar_audit.py` |
| Legacy dependency scan | `docs/03_Domain_Pillars/MaterialPillar/material_pillar_backlog.md` |
| Closure smoke | `TEST_Material_L3_L4_Closure_Runner.f90` |
| L5 router smoke | `tests/L5_RT/RT_Mat_Test.f90` |
