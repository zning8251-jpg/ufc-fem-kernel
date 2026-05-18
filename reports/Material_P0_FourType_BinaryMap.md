# Material domain P0 map: four TYPEs, binary split, L5 chain

**Status**: Read-only planning draft for task cards and harness slices.  
**Cross-ref**: [Material_Domain_Inventory.md](Material_Domain_Inventory.md) — line numbers below are hints; **prefer section headings** after edits.

**Module counts (MDLUE)**: about L3=8, L4=86, L5=25 `.f90` files under `ufc_core` Material trees (approximate; use `glob` when precise).

---

## 1. Four TYPEs by layer

| Role | L3_MD | L4_PH | L5_RT | Inventory (sec / lines) |
|------|--------|--------|--------|-------------------------|
| Desc | `MD_Mat_Desc` in Contract; families in `MD_Mat_*_Def` | `PH_Mat_Desc` in `PH_Mat_Domain_Core.f90`; public via `PH_Mat_Def` | Not a four-type mirror at L5 | Sec 2 diagram; Sec 3.1 table |
| State | family/state in MD | `PH_Mat_State` in `PH_Mat_Domain_Core.f90` | `RT_Mat_Core` swap/cache/checkpoint around L4 state | Sec 3.2; Sec 7 DualWrite |
| Algo | enums/step in `MD_Mat_Def` | `PH_Mat_Algo` + `constitutive` pointer | `RT_Mat_Algo` in `RT_Mat_Def.f90` | Sec 3.2–3.3 |
| Ctx | MD context types | `PH_Mat_Ctx` in `PH_Mat_Domain_Core.f90` | `RT_Mat_Dispatch_Ctx` in `RT_Mat_Def.f90` | Sec 4.3 |

**Takeaway**: `PH_Mat_Domain_Core` is the domain four-type + slot pool source; `PH_Mat_Def` is the public USE hub (aligns with Inventory Sec 3.2).

---

## 2. Binary split (data-leaning vs algorithm-leaning) — today

| Layer | Data-leaning | Algorithm-leaning | Inventory (sec / lines) |
|-------|----------------|-------------------|-------------------------|
| L3 | `MD_Mat_Def`, `MD_Mat_*_Def`, Registry | Dispatch types in MD core / Brg with model specializations | Sec 3.1 |
| L4 | `PH_Mat_Domain_Core`, `PH_Mat_Aux_Def`, `Contract/PH_Mat_*` | `PH_Mat_Core`, `PH_Mat_Reg`, `Dispatch/PH_Mat*.f90`, family `*_Eval.f90` | Sec 3.2 |
| L5 | `RT_Mat_Def`, `RT_Mat_Aux_Def`, family `*_Def` | `RT_Mat_Core` (routing only), family `*_Core` | Sec 3.3 |

---

## 3. L4 symbols (alignment)

| Symbol | Where | Note | Inventory (sec / lines) |
|--------|--------|------|-------------------------|
| `PH_Mat_Slot` | `PH_Mat_Domain_Core.f90` | Bundles four TYPEs + `active` | Sec 3.2 |
| `PH_Mat_Constitutive_Ifc` | `PH_Mat_Domain_Core.f90` | `(desc, state, arg, status)` with `PH_Mat_Eval_Arg` | Sec 4.1 |
| `PH_Mat_Update_Arg` | `PH_Mat_KernelDefn.f90` | Registry/kernel path; **not** the same as `PH_Mat_Eval_Arg` | Sec 4.1 |
| `PH_Mat_Eval_Arg` | `PH_Mat_Domain_Core.f90` | Nested `inp` / `out`; SIO audit target | Sec 4.1 |
| Effective model id | `PH_Mat_Core` + `RT_Mat_Brg` table | Fills `RT_Mat_Dispatch_Table` from `PH_Mat_Desc` | Sec 3.3, Sec 5 |

---

## 4. L5 dispatch chain (short path)

| Step | Content | Inventory (sec / lines) |
|------|---------|---------------------------|
| 1 | `RT_Mat_Brg` / build table from `PH_Mat_Domain` + `desc` | Sec 5 |
| 2 | `RT_Mat_Dispatch_Stress` / `RT_Mat_Dispatch_Tangent` call `PH_Mat_Execute_Flow` / `PH_Mat_Execute_Tangent_Flow` | Sec 4.3; Sec 5 |
| 3 | `RT_Mat_Dispatch_Ctx` / `RT_Mat_Algo` | Sec 3.3 |

---

## 5. Family folders (L3 / L4)

Elas, Plast, Hyper, Viscoelas, Creep, Damage, Thermal, Acoustic, Geo, Composite, User. L3 also has Contract / Registry / Dispatch paths.

**Inventory pointer**: Sec 3.2 table (hub files); Sec 7 (gaps).

---

## 6. Doc anchors

- `UFC/ufc_core/L4_PH/Material/DESIGN_MatFourTypes.md`
- `UFC/ufc_core/L3_MD/Material/DOMAIN_MatL3Types.md`
- Material `CONTRACT.md` under L3/L4/L5 when present

---

## 7. Suggested P1 slices

| Slice | Content | Inventory (sec / lines) |
|-------|---------|-------------------------|
| SIO | `PH_Mat_Eval_Arg` vs structured IO rules; reconcile `Update_Arg` naming at registry boundary | Sec 4.1 |
| L3 binary pilot | Elas-only Def vs Core/Brg split | Sec 3.1 |
| Harness | Table init then `gfortran -fsyntax-only` on touched units | Task card |
| Legacy bridge | `PH_Mat_Core_Types` / UMAT context vs four-type line | Sec 3.2 |

---

## 8. Quick index to Inventory sections

| This doc | Material_Domain_Inventory.md |
|----------|------------------------------|
| Four TYPE diagram | Sec 2 |
| L3 table | Sec 3.1 |
| L4 hub files | Sec 3.2 |
| L5 dispatch | Sec 3.3 |
| `PH_Mat_Constitutive_Ifc` | Sec 4.1 |
| Populate | Sec 4.2 |
| `RT_Mat_Dispatch_*` | Sec 4.3 |
| Sequence | Sec 5 |
| Gaps | Sec 7 |

---

## Revision

| Date | Note |
|------|------|
| 2026-05-08 | P0 draft |
| 2026-05-08 | UTF-8 rewrite; cross-refs by section; align Eval_Arg / Update_Arg / RT_Mat_Core |

---

END
