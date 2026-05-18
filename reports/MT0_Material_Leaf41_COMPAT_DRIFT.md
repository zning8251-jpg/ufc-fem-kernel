# MT-0.2 / MT-0.3 — Material Leaf41 vs `GROUP_MAT_COMPAT` & ID drift

**Scope**: `Abaqus614_Material_Leaf41.md` (41 rows) · `Leaf41_UFC_Crosswalk.csv` · `MD_Ana_Comp.f90` · `MD_Mat_Ids.f90` · `MD_MatReg_Ops.f90`

---

## MT-0.2 — `GROUP_MAT_COMPAT` (G1–G9 × mat_family 1–11)

**Source**: `ufc_core/L3_MD/Analysis/MD_Ana_Comp.f90` — `GROUP_MAT_COMPAT(AC_N_GROUP, AC_N_MAT_FAM)`.

**Reading**: `GROUP_MAT_COMPAT(group, mat_fam)` is `.TRUE.` when physics **group** `group` may host material **family** column `mat_fam` (1=Elastic … 11=User/EM).

**Leaf41 sanity (no code change required for matrix itself)**:

- Structural mechanics leaves (1–39 except pure thermal/acoustic rows) expect **G1** structural + mat_family 1–8,9 (coupled thermal-mech uses G6 rows `.TRUE.` for col 1–8). Pure **thermal-only** materials (Leaf 37–39, `mat_family=9`) are `.FALSE.` on G1 and `.TRUE.` on G2 — matches distinct thermal physics.
- **Acoustic** column 10: `.TRUE.` on G4 and G7/G9; `.FALSE.` on G1 for pure acoustic medium — use **acoustic element / acoustic physics** path when selecting mat_family 10 (Leaf 40 merged row).
- **User / SPU** column 11: `.TRUE.` on G5 EM and G7 multifield and G9 special — Leaf 41 bundle must be validated with **step physics** not only `mat_family`.

**Action**: Step-level validation must call `MD_Ana_Comp_ValidateGroupMat` (or equivalent) so Leaf41 rows are not interpreted as “all groups OK”.

---

## ID / registry drift (MT-0.2 technical debt — partially cleared MT-0.4 / MT-F2.x)

| Topic | Detail |
|--------|--------|
| **Elastic `MAT_ELAS_*` vs `MD_MAT_ELAS_*` / Leaf41 rows 2–4** | **MT-0.4**: `MD_Mat_Ids` + `PH_Mat_Reg` now use **`MAT_ELAS_TRANSV_ISO=103`**, **`MAT_ELAS_ANISO=104`**; `MAT_FAMILY_ELAS_MAX=104`. L3 `MD_MAT_ID_103/104` unchanged. |
| **Hill vs Drucker–Prager @ 202** | **MT-0.4**: **`MD_MAT_HILL_MAT_ID=205`** (`MAT_PLAST_ANISO_HIL`); **DP** remains registry **`202`** (`MD_MAT_DRUCKERPRAGER_M`). **MT-0.5**: **`MAT_PLAST_J2_TAB=219`** (`MD_Pls_J2Tab`, `PH_Mat_Reg` mirror); **202** is **DP-only** for MatLib/registry plastic row. |
| **Chaboche** | **MT-F2.x**: `MD_MAT_CHABOCHE_MAT_ID = 210` (`MAT_PLAST_CHABOCHE`); shim **`MD_MatPLMChaboche`** re-exports PH/KW `CHAB_*` aliases. |
| **Johnson–Cook** | **MT-F2.x**: `MD_MAT_JOHNSONCOOK_MAT = 206` (`MAT_PLAST_JOHNSON_C`); shim **`MD_MatPLMJohnsonCook`**. |
| **Porous elastic** | L3 descriptor leaf **105** vs MatLib `MD_MAT_ELAS_P` / **123** — **open**. |
| **Viscoelastic Prony** | L3 `MD_MAT_ID_401` family vs legacy registry **501** — **open**. |
| **Hyperelastic Neo-Hookean** | L3 `MD_MAT_ID_303` vs registry **121** — **open**. |

**Crosswalk**: authoritative per-row notes live in **`docs/03_Domain_Pillars/MaterialPillar/Leaf41_UFC_Crosswalk.csv`**.

---

## MT-0.3 — Quarantine policy (strict 41 leaves)

**Principle**: Runtime / registry **IDs beyond the 41 semantic leaves** remain valid **implementation extensions** until mapped or removed.

| Class | Handling |
|--------|-----------|
| **MatLib `RegisterDefaultModels` IDs 241–265, 602, …** | Treat as **`EXTENSION_QUARANTINE`** for Leaf41 acceptance; each future MR either **`maps_to_leaf_id`** (one of 1–41) or documents deprecation. |
| **Duplicate use of 202 (DP vs J2 tabular / other)** | **Closed (MT-0.5)**: J2 tabular uses **`MAT_PLAST_J2_TAB=219`**; **`MD_Mat_Lib`** zero-`material_id` default is **`MD_MAT_VONMISES_MAT_ID` (201)**, not 202. **`MD_MAT_ID_FIBER_REINF=202`** remains a separate MatLib composite namespace. |
| **SPU / User (`MD_MAT_ID_702`…`708`, `9001`…)** | Map under **Leaf 41** bundle in CSV; sub-features do not add Leaf 42+. |

**CSV columns**: use `maps_to_leaf_id` when a registry row is an alias of a Leaf41 row; use `quarantine_reason` for `EXTENSION_QUARANTINE` or `ID_COLLISION`.

---

## Follow-on MRs (suggested)

1. ~~**MT-0.5**~~: **Done** — J2 tabular **`MAT_PLAST_J2_TAB=219`**; DP stays **`202`**.
2. **MT-F2.2**: Register **Barlat** in `RegisterDefaultModels` / plastic registry when implementation leaves stub.
3. **MT-F1.2–F1.3**: Header/props gold lines for **Leaf 2–3** (`*ELASTIC` ORTHO/TRAVERSE) + porous **123 vs 105** bridge doc.

---

## Tooling

- `python tools/material_pillar_audit.py` refreshes `docs/03_Domain_Pillars/MaterialPillar/material_l3_l4_mat_id_drift.md` and related inventory CSVs (run after material MRs).
