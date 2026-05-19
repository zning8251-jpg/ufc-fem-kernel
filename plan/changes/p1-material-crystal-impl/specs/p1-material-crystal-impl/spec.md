# Spec: p1-material-crystal-impl

## Requirements

### R1 — Unsupported 移除

The system **must not** return `STATUS_UNSUPPORTED` from `UF_CrystalPlasticity_UMAT` on valid W1a inputs after this change is merged.

### R1b — W1b Schmid (current)

On valid props, the UMAT **must** use 1-slip Schmid with \(\tau = P:\sigma\) and **must** update `statev(1)` as `gamma`.

### R1a — W1a iso-surrogate (deprecated)

W1a **must not** be the active code path after W1b merges; CONTRACT **must** mark W1a deprecated.

### R2 — Dispatch 路径

The existing `PH_MatPLMEval` CASE 266 Arg wiring **must** remain the integration boundary; implementation **must** live in `PH_Mat_Plast_Crystal_Core` (and optional Kernel).

### R3 — Props 合同

When `nprops` &lt; minimum required for W1, the UMAT **must** set `IF_STATUS_INVALID` with a clear message.

### R4 — Statev

When `nstatev` &lt; 7, the UMAT **must** reject the increment with `IF_STATUS_INVALID` (W1 minimum layout).

### R5 — SSOT

The implementation **must not** mutate L3 `MD_Mat_Desc` registry storage.

---

## Scenarios

### Scenario A — Valid elastic increment

- **Given** mat_id 266, `nprops >= 4`, `nstatev >= 7`, and `dstran` within elastic range  
- **When** `UF_CrystalPlasticity_UMAT(arg)` is called  
- **Then** `arg%status%status_code` is `IF_STATUS_OK` and `arg%ddsdde` is non-zero where requested  

### Scenario B — Invalid props

- **Given** `nprops < 4`  
- **When** the UMAT runs  
- **Then** status is `IF_STATUS_INVALID` and stress is not silently left undefined  

### Scenario C — PLM dispatch

- **Given** a plastic eval context selecting crystal mat_id 266  
- **When** `UF_Plastic_Eval_Dispatch` reaches CASE 266  
- **Then** Arg pack/unpack matches Core fields and status propagates to caller  

### Scenario D — Post-merge regression

- **Given** merged `main` including C2 MatEval split  
- **When** guardian runs on `PH_Mat_Plast_Crystal_Core.f90`  
- **Then** P0 violation count is zero  
