# TASK_RUN — p1-material-crystal-w2-multislip

| Field | Value |
|-------|-------|
| change_id | `p1-material-crystal-w2-multislip` |
| phase | **COMPLETE** |
| PRs | #14 (W2a core), #16 (W2-REF-01 harness) |
| date | 2026-05-19 |

## Delivered

- W2a N=2 slip + latent hardening (`PH_Mat_Plast_Crystal_Core.f90`)
- CONTRACT W1b/W2a tables
- W2-REF-01: `tools/verify_crystal_w2_ref01.py`, `ctest UMAT_CrystalW2Ref01`

## Follow-up (new change_id or W2b)

- W2a consistent plastic tangent (`ddsdde`)
- Registry mat_id 266 `nprops`/`nstatev` tighten
- `P1_MATERIAL_GAP_SNAPSHOT.md` refresh
