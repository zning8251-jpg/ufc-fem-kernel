# Tasks: intf001-mat-plast-spcl-arg

## 1. Implementation

- 1.1 `UF_Mat_Plast_Calc` + `UF_Mat_Plast_Calc_Arg`; remove `PH_Mat_PLM_PlastCall_Args`
- 1.2 `UF_Mat_Special_Calc` + `UF_Mat_Special_Calc_Arg`; remove `PH_Mat_Spcl_Def_Args`
- 1.3 `PH_Mat_TypeToId` plastic branch + stub CASE range `201:227`

## 2. Harness

- 2.1 `change-package validate --change-id intf001-mat-plast-spcl-arg --strict`
- 2.2 `guardian` INTF-001 on touched `.f90` (paths as needed)
- 2.3 Extend `test_defn_invoke_umat` when bridge behavior widens
- 2.4 `Defn_Invoke_UMAT` → single **`Defn_Invoke_UMAT_Arg`** (INTF-001 on bridge public API)
## 3. Follow-ups (post-merge hygiene)

- 3.1 Extend **Defn_Invoke_UMAT_Arg** with optional **statev** (or typed SDV carrier) and thread **MD_PH_RouteToConstitutive** state_vars through the bridge when the stub graduates beyond iso tangent.
- 3.2 Register **CTest** targets for `test_defn_invoke_umat` (or wire existing Fortran driver) so `ctest -R Defn_Invoke_UMAT` is non-empty; today `build/` has **0** tests.
- 3.3 Optional: restore **Defn_Invoke_UMAT_FromMatPropDef** as a thin L4-only wrapper over **Defn_Invoke_UMAT_Arg** if other translation units still expect the old name (currently none in-tree after MD_MatLibPH_Brg fix).

## Next

- 2026-05-16 (post-intf001): `git grep` sweep — no code `Defn_Invoke_UMAT(mat_id,` calls (only stale comment in `PH_MatPLM_PlastCall.f90`); `UF_Mat_Elastic_Calc(` / `UF_Mat_Plast_Calc(` only in defining `PH_MatELA_ElasCall.f90` / `PH_MatPLM_PlastCall.f90`; no `UF_Mat_Special_Calc(` hits; `cmake ../ufc_core -DBUILD_TESTING=ON` from `build/` rc=0; `cmake --build . --target test_defn_invoke_umat` rc=2 (gfortran errors in `L1_IF/Base/IF_Base_StructMeta_Def.f90`); `python ufc_harness/run_harness.py change-package validate --change-id intf001-mat-plast-spcl-arg --strict` rc=0; `ctest -R Defn_Invoke_UMAT` not run (test exe did not build).
