# Spec: intf001-mat-plast-spcl-arg

## Scenario: Plastic dispatch Arg

**When** L4 code calls `UF_Mat_Plast_Calc` with a populated `UF_Mat_Plast_Calc_Arg`, **then** the procedure **must** initialize `arg%status`, map `arg%matType` through `PH_Mat_TypeToId`, and route to `Defn_Invoke_UMAT` for a non-invalid `mat_id`.

## Scenario: Special dispatch Arg

**When** L4 code calls `UF_Mat_Special_Calc` with `UF_Mat_Special_Calc_Arg`, **then** the procedure **must** follow the same status + TypeToId + `Defn_Invoke_UMAT` pattern as elastic/plastic helpers.

## Scenario: Plastic TypeToId

**When** `PH_Mat_TypeToId` is invoked with category plastic and a supported subtype `1..27` excluding deprecated slots, **then** it **must** return a positive `mat_id` in the documented linear band. **When** subtype is deprecated, **then** it **must** return `PH_MAT_ID_INVALID`.

## Scenario: Defn_Invoke_UMAT Arg

**When** callers invoke **Defn_Invoke_UMAT**, **then** they **must** pass a single **`Defn_Invoke_UMAT_Arg`** with **`mat` allocated** before the call; **then** the procedure **must** fill `stress_out`, optional tangent per `want_tangent`, and `status`.