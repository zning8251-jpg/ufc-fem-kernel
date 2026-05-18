# Material pillar closure report — 2026-05-03

## Scope (plan B → D)

Executed **B1–B4**, **B3-level RT tests**, **C1/C2 documentation + deprecation markers**, **C3 RT eleven-family skeleton**, **C4 DOMAIN_PILLAR + CONTRACT sync**, **D1 audit refresh + catalog fix**, **D2 this report + baseline note**.

## Added / changed code (high level)

| Area | Change |
|------|--------|
| L3 | `MD_L3_Layer.f90` — `MD_L3_LayerContainer%material` with `Init` / `Register` + TARGET store for registry pointers. |
| L3 | `MD_Mat_Registry.f90` — `MD_Mat_Registry_Access_Desc` for Populate lookup. |
| L4 | `PH_L4_Populate.f90`, `PH_L4_L3MatContract.f90` — Populate + L3→L4 mapping constants. |
| L4 | `PH_Mat_Dispatch.f90`, `PH_Mat_Reg.f90` (complete kernels), `PH_Mat_Def.f90` USE-order fix, `PH_Mat_Core.f90` effective-model + S3 `dstrain` zero default. |
| L4 | `PH_Mat_Elas_Def.f90` — `PH_MAT_ELAS_SUB_THERMO` / `PIEZO` (=109/110) aligned with L3. |
| L5 | `RT_Mat_Brg.f90` — `mid` from `desc%cfg%matId` only. |
| L4 Element | `PH_Elem_MaterialRoute.f90` — remove invalid `desc%matId` fallbacks. |
| Tests | `TEST_Material_L3_L4_Closure.f90`, `RT_Mat_Test.f90` — nested four-type paths + `PH_Mat_Def` USE; 11-family skeleton in RT test. |
| Tools | `material_pillar_audit.py` anchor paths; `material_mat_catalog.py` — L3=`MD_Mat_Ids.f90`, L4=`PH_Mat_Reg.f90`, `_i4` parse, empty-L4 mirror fallback. |

## Removed

- `ufc_core/L4_PH/Material/Elas/*.f90.old`
- `ufc_core/L4_PH/Material/Elas/backup_old/` (directory)

## Not completed mechanically (C1 / C2 body split)

- **C1**: `Dispatch/PH_MatPLM_LegacyFacadeUMATs.f90` (~6800 LOC) remains the implementation container; **DEPRECATED** banner + removal date added. Physical split into seven `PH_Mat_<Family>_<Model>_Core.f90` files is **deferred** (non-trivial helper sharing between UMATs). Next MR: extract by subroutine ranges with shared helper module.
- **C2**: `PH_MatEval.f90` kept as aggregate; **NOTE** added for family-level Eval migration. No mass move of `PH_Mat_*_Eval` routines in this MR.

## Audit / baseline (D1)

- Regenerated: `docs/03_Domain_Pillars/MaterialPillar/material_pillar_inventory.csv`, `material_pillar_summary.md`, `material_pillar_backlog.md`, `material_variant_catalog*.md/csv`.
- Baseline file on disk: `REPORTS/material_pillar_inventory_baseline_2026-05-02.csv` — diff locally with the new inventory CSV for MR review (`fc / WinDiff`).

## Rollback

1. Revert commits touching `tests/*`, `PH_L4_*`, `MD_L3_Layer.f90`, `MD_Mat_Registry_Access_Desc`, `PH_Mat_Reg` / `PH_Mat_Dispatch`, and CONTRACT/DOMAIN rows.
2. Restore deleted `*.old` / `backup_old` only if still required for forensic diff (not recommended).

## Next MR suggestions

1. **C1 execution**: submodule or `INCLUDE` strategy for shared FGM/geo helpers; then thin `PH_MatPLM_LegacyFacadeUMATs` re-export only.
2. **S3 strain path**: wire `uarg%dstrain` from slot state / increment bundle (currently zero-filled fallback in `PH_Mat_S3_StressUpdate`).
3. **PH_MatPLM_Kernels** / missing `PH_Mat_PLM_Fgm` modules: resolve `USE` graph vs `PH_MatPLM_LegacyFacadeUMATs` duplicate symbols if build exposes conflicts.

## Tests

- **Intended gate**: `tests/TEST_Material_Pillar_Runner.f90` (requires Fortran toolchain + full `ufc_core` link — not executed in this agent environment where `gfortran`/`ninja` were unavailable).
- After toolchain install: build `ufc_core` target that links the pillar runner (or project-specific harness) and run the executable; expect exit code **0**.
