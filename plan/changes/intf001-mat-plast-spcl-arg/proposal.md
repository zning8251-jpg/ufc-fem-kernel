# Change: intf001-mat-plast-spcl-arg

## Why

Post–wave-2 Material dispatch follow-up: align `UF_Mat_Plast_Calc` and `UF_Mat_Special_Calc` with INTF-001 (`*_Arg` SIO bundle) like `UF_Mat_Elastic_Calc`, fix optional `status` initialization, and complete `PH_Mat_TypeToId` plastic mapping without pulling `MD_Mat_Lib` into the bridge.

## What Changes

- `PH_MatPLM_PlastCall.f90` / `PH_Mat_Spcl_Def.f90`: single public `UF_*_Calc_Arg` per procedure; remove legacy placeholder `*Args` types.
- `PH_Mat_Defn_UMAT_Bridge.f90`: plastic `mat_subtype` → `mat_id` linear map (deprecated slots invalid); stub `Defn_Invoke_UMAT` accepts full plastic id band for smoke parity with `201`; **public `Defn_Invoke_UMAT(du)` + `Defn_Invoke_UMAT_Arg`** (INTF-001).

## Impact

- Bounded to L4_PH Material Dispatch/Contract files listed above plus optional smoke test extension; no `docs/` registry bulk edits.