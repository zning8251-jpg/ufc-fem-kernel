# Spec: p1-material-crystal-w2-multislip

## Requirements

### R1 — Multi-slip

When `N_slip = 2` props are supplied, the UMAT **must** compute resolved shear stresses on **both** systems and update **both** `gamma` state variables.

### R2 — Latent hardening

Hardening on system \(\alpha\) **must** depend on slip on system \(\beta\) via \(h_{\alpha\beta}\) (at least off-diagonal terms in W2a).

### R3 — Backward compatibility

When only W1b-length props are used (single slip), behavior **must** match pre-W2 W1b within numerical tolerance.

### R4 — statev

`nstatev` below W2a minimum **must** yield `IF_STATUS_INVALID`.

---

## Scenarios

### Scenario A — Two active slips

- **Given** symmetric double-slip props and stress path activating both systems  
- **When** `UF_CrystalPlasticity_UMAT` runs  
- **Then** both `statev(1:2)` increase and `IF_STATUS_OK`  

### Scenario B — W1b regression

- **Given** W1b props (single slip) only  
- **When** the UMAT runs the same increment as before W2  
- **Then** stress and `statev` match W1b baseline within tolerance  

### Scenario C — Invalid statev

- **Given** `nstatev < 8` for W2a  
- **When** the UMAT runs  
- **Then** `IF_STATUS_INVALID` is returned  
