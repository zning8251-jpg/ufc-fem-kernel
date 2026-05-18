# Handoff: Material binary-structure pass → Element domain

## Scope completed (Material only)

- **TYPE-003 (L4_PH/Material):** Fixed 5 P0 hits by removing `ALLOCATABLE` from types whose names end in `*Ctx` (guardian rule `TYPE003_CtxNoAlloc`). `PH_Mat_Interp_Ctx` cache arrays are now `POINTER` with `ASSOCIATED`/`DEALLOCATE`/`ALLOCATE` in `PH_Mat_Interp_Init` / `PH_Mat_Interp_Finalize`. `PH_Mat_{Hyper,Plast,Visco}_Inc_Evo_Ctx%field_var` are `POINTER` with `NULLIFY` in `Ctx_Init` / `Ctx_Clean` (no prior `ALLOCATE` in-tree; future population should `=>` bind to a workspace slice).
- **Binary clarity (minimal):** Added `!--- COLD … vs HOT … ---` banners to `PH_Mat_Def.f90`, `RT_Mat_Def.f90`, and flagship L3 `MD_Mat_Elas_Def.f90`. Reordered `USE` in `RT_Mat_Def.f90` (precision module first).

## Guardian (`python tools/arch_guardian.py <path> --rules TYPE-003`)

| Path | Result |
|------|--------|
| `ufc_core/L3_MD/Material` | 0 violations |
| `ufc_core/L4_PH/Material` | 0 violations (was 5 P0 before pointer migration) |
| `ufc_core/L5_RT/Material` | 0 violations |

## Naming checker (`python ufc_harness/uhc.py code naming_checker <dir>`)

- **L3_MD/Material:** Ran on full tree — **63 / 101 files** flagged (mostly legacy module names without `_Core`/`_Def`/etc. suffix). Treat as **baseline debt**, not introduced by this pass.
- L4/L5 Material subsets were not re-run separately; expect similar suffix drift on model-specific modules outside strict `*_Def`/`*_Core` naming.

---

## Audit: key modules by layer (suffix pattern & gaps)

### L3_MD/Material (`ufc_core/L3_MD/Material`)

| Area | Typical modules | Pattern (cold / hot) | Gap / note |
|------|-----------------|----------------------|------------|
| Contract hub | `Contract/MD_Mat_Def.f90` | **Mixed:** canonical `Desc`/`State`/`Ctx`/`Algo` + legacy `MatCtxLegacy` with many `ALLOCATABLE`s | Monolithic cold+legacy; splitting would be high churn — prefer gradual extraction, not bulk refactor |
| Per-family | `*/MD_Mat_*_Def.f90`, `*_Brg.f90`, `*_Core.f90` | Strong **Def / Brg / Core** split for promoted families (Elas, Plast, Hyper, …) | Standalone kernels (`MD_Mat_Acou_Linear`, `MD_Mat_Comp_Hashin`, …) often **no `_Core` suffix** (naming_checker noise) |
| Dispatch / registry | `Dispatch/*`, `Registry/*` | Ops / dispatch | OK as hot orchestration |
| Docs under Material | `docs_Phase3_*.md` | N/A | Informational only |

### L4_PH/Material (`ufc_core/L4_PH/Material`)

| Area | Typical modules | Pattern | Gap / note |
|------|-----------------|---------|------------|
| Re-export hub | `PH_Mat_Def.f90` | Cold-only `USE` re-exports | **Flagship** — keep grouped: domain core → enums → family `*_Def` |
| Domain / populate | `PH_Mat_Domain_Core.f90`, `PH_L4_Populate.f90`, `PH_Mat_Dispatch.f90` | Hot | Large surface; binary banner optional |
| Family | `*/PH_Mat_*_Def.f90`, `*_Core.f90`, `*_Eval.f90` | **Def / Core / Eval** | `PH_Mat_Interp_Core.f90` defines `PH_Mat_Interp_Ctx` (now TYPE-003 clean) |
| Contract / UMAT | `Contract/PH_Mat_*_Def.f90`, `PH_Mat_UMAT_Brg.f90` | Cold + bridge | `PH_Mat_Aux_Def.f90` holds heavy transient buffers (`ALLOCATABLE` on **non-**`*Ctx` names — guardian OK) |

### L5_RT/Material (`ufc_core/L5_RT/Material`)

| Area | Typical modules | Pattern | Gap / note |
|------|-----------------|---------|------------|
| Re-export | `RT_Mat_Def.f90` | Cold dispatch types + `RT_Mat_Algo` | Thin; aligns with `IF_Mat_Dispatch_Def` |
| Family cores | `RT_Mat_*_Def.f90`, `RT_Mat_*_Core.f90` | **Def / Core** | `RT_Mat_*_Def` uses `ALLOCATABLE` on **route tables** (`TYPE(...), ALLOCATABLE :: entries(:)`); names are not `*Ctx` — TYPE-003 silent |
| Bridge | `RT_Mat_Brg.f90` | Hot | Consumer of L4 slot/desc |

---

## Next: Element domain (actionable, do **not** bulk-refactor NLGeom/assembly here)

1. **Mirror Material discipline:** For each layer, treat **`PH_Elem_Def.f90` / `MD_Elem_Def.f90` / `RT_Elem_Def.f90`** as cold hubs; keep **`PH_Elem_Core.f90`**, `PH_ElemDomain_Ops.f90`, `PH_Elem_*_Def` per family, and **`RT_Elem_*_Proc.f90`** as hot.
2. **TYPE-003 sweep:** Run  
   `python tools/arch_guardian.py ufc_core/L4_PH/Element --rules TYPE-003`  
   (and L3/L5 Element if present). Fix any `*Ctx` / `*Inc*Ctx` with `ALLOCATABLE` the same way as Material (pointer + `ASSOCIATED`/`NULLIFY` at call sites in Element scope).
3. **High-value files to read first:**  
   - L4: `ufc_core/L4_PH/Element/PH_Elem_Def.f90`, `PH_Elem_Core.f90`, `PH_Elem_Aux_Def.f90`, `PH_Elem_Domain.f90`  
   - L3: `ufc_core/L3_MD/Element/Elem/MD_Elem_Def.f90`, `MD_Elem_Domain.f90`, `MD_Elem_PHBinding.f90`  
   - L5: `ufc_core/L5_RT/Element/RT_Elem_Def.f90`, `RT_Elem_Core.f90`, `RT_ElemDispatch_Brg.f90`
4. **Naming baseline:** Expect many `PH_Elem_C3D8`-style modules without `_Core`; run `uhc.py code naming_checker` on each subtree and track **delta** only unless you adopt a rename policy.

---

## Files touched in this Material pass

- `ufc_core/L4_PH/Material/PH_Mat_Interp_Core.f90`
- `ufc_core/L4_PH/Material/Hyper/PH_Mat_Hyper_Def.f90`
- `ufc_core/L4_PH/Material/Plast/PH_Mat_Plast_Def.f90`
- `ufc_core/L4_PH/Material/Viscoelas/PH_Mat_Visco_Def.f90`
- `ufc_core/L4_PH/Material/PH_Mat_Def.f90`
- `ufc_core/L5_RT/Material/RT_Mat_Def.f90`
- `ufc_core/L3_MD/Material/Elas/MD_Mat_Elas_Def.f90`
- `REPORTS/archive/handoff_element_domain.md` (this file; 已冷归档)
