# Material Family Rollout Matrix

This matrix drives the Material pillar rollout after the L3/L4/L5 contract freeze.

**中文 — 11 主族与 L3/L4/L5 三层打通执行清单**：[`Material_11Families_L3L4L5_三层打通清单.md`](./Material_11Families_L3L4L5_三层打通清单.md)（`mat_family` 真源：`MD_Ana_Comp.f90`）。**按 `mat_family` 1→11 顺序落地索引**：[`Material_11Families_Sequential_Rollout.md`](./Material_11Families_Sequential_Rollout.md)。材料柱审计 CSV：`python UFC/tools/material_pillar_audit.py`（默认输出到 `UFC/docs/03_Domain_Pillars/MaterialPillar/`）。

## Route Levels

| Level | Meaning | Acceptance |
|-------|---------|------------|
| L0 Inventory | Files and roles are known | Present in `material_pillar_inventory.csv` |
| L1 Populate | L3 Desc maps to `PH_Mat_Slot%ctx%matModel` and `mat_model_id` | Covered by `PH_L4_L3MatContract` tests |
| L2 Slot | Slot props/state are initialized without hot-path L3 scan | `PH_L4_Populate_Material` positive test |
| L3 Route | L5 route table/ctx built from L4 slot | `RT_Mat_Brg_BuildTable_FromMaterial` test |
| L4 Kernel | L4 family kernel or routed helper computes representative response | Exact test in `TEST_Material_L3_L4_Closure.f90` or family test |
| L5 WriteBack | L5 diagnostics validates stress/state before commit | `RT_Mat_Brg_WriteBackHook` test |

## Family Matrix

| Family | Marker | L1 | L2 | L3 | L4 representative | Next closure |
|--------|--------|----|----|----|-------------------|--------------|
| Elastic | `PH_MAT_ELASTIC` | DONE | DONE | DONE | `PH_Mat_Elas_Core` / continuum route helpers | Expand exact kernel dispatch tests |
| Plastic | `PH_MAT_ELASTO_PLASTIC` | DONE | DONE | DONE | J2 representative slot route | Add real PLM kernel dispatch after legacy UMAT path is quarantined |
| Geo | `PH_MAT_GEOTECH` | DONE | TODO | TODO | Mohr-Coulomb or Drucker-Prager | Add slot props contract and representative kernel test |
| Hyper | `PH_MAT_HYPERELASTIC` | DONE | TODO | TODO | Neo-Hookean | Add finite-strain state contract |
| Viscoelastic | `PH_MAT_VISCOELASTIC` | DONE | TODO | TODO | Prony / Kelvin | Add time-increment state contract |
| Creep | `PH_MAT_CREEP` | DONE | TODO | TODO | Power-law creep | Add state_old/state_new protocol |
| Damage | `PH_MAT_DAMAGE` | DONE | TODO | TODO | Gurson or ductile damage | Add SDV evolution test |
| Composite | `PH_MAT_COMPOSITE` | DONE | TODO | TODO | Castani / CLT representative | Add section/material boundary note |
| Thermal | `PH_MAT_THERMAL` | DONE | PARTIAL | FAMILY_ROUTE | scalar conductivity route | `DC*` rows accepted as thermal scalar family route until per-element heat-transfer modules exist |
| Acoustic | `PH_MAT_ACOUSTIC` | MARKER_ONLY | PARTIAL | PARTIAL | acoustic fluid route helper | Add L3 acoustic class mapping when authoritative category is present |
| User | `PH_MAT_USER_UMAT` / `PH_MAT_USER_VUMAT` | DONE | TODO | PARTIAL | UMAT/VUMAT bridge | Add user-material bundle closure test |

## Rollout Rule

Each family advances in order: L1 mapping -> L2 slot contract -> L3 route ctx -> L4 representative kernel -> L5 writeback/diagnostics. A family may be accepted as `FAMILY_ROUTE` only when the contract states exactly which behavior remains owned by Element/Section rather than Material.

## P1.1 Decisions

| Decision | Outcome |
|----------|---------|
| L5 Elastic dispatch smoke | `RT_Mat_Test` builds a populated L4 slot, makes an L5 ctx, validates dispatch, then calls the L4 shared Elastic3D route helper for a positive stress/tangent response |
| `DC*` thermal transfer rows | Closed as `FAMILY_ROUTE` through scalar conductivity route because no `PH_Elem_DC*.f90` per-element modules exist in the current tree |
| Test entry | `TEST_Material_Pillar_Runner.f90` aggregates Material L3/L4 closure and L5 route tests |
| Plastic P1.2 route | `TEST_Material_L3_L4_Closure` now verifies `MD_MAT_CATEGORY_PL -> PH_MAT_ELASTO_PLASTIC -> RT_Mat_Dispatch_Ctx`; real J2 kernel dispatch remains the next PLM quarantine task |
