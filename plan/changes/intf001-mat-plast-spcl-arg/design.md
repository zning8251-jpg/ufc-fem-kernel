# Design: intf001-mat-plast-spcl-arg

## Decisions

1. **SIO bundle**: Mirror `UF_Mat_Elastic_Calc_Arg` — `matType`, `Mat`, `strain_in`, `stress_out`, `tangent_out(6,6)`, `want_tangent`, `status`. Optional `state_inout` / `flags` are omitted from the Arg TYPE until a typed carrier exists (no `ufc_core` callers today).
2. **Plastic mat_id**: `PH_Mat_TypeToId(PH_MAT_CAT_PLAST, k)` returns `200 + k` for `k` in `1..27` except deprecated `13`, `14`, `25` → `PH_MAT_ID_INVALID`. Documented band **201–227** supersedes older “201–220” comment (27 category-local kinds).
3. **Bridge stub**: `Defn_Invoke_UMAT` treats `mat_id` in `201:227` like `201` (isotropic stress/tangent smoke) until real per-model UMAT routing lands.

## Alternatives considered

- Keep multi-argument public `UF_Mat_Plast_Calc` — rejected (INTF-001 / Guardian P1).