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

### Scenario A — W2-REF-01（系1单增量）

- **Given** `nprops=19`, W2-REF-01 props/`dstran`（`design.md` §6）  
- **When** `UF_CrystalPlasticity_UMAT` runs one increment from zero state  
- **Then** `gamma^{(1)}≈0.003307009`, `gamma^{(2)}=0`, `IF_STATUS_OK`

### Scenario A2 — Two active slips

- **Given** stress path with both \(|\tau^{tr}_\alpha|>\tau^\alpha_c\)  
- **When** the UMAT runs  
- **Then** both `statev(1:2)` increase and `IF_STATUS_OK`  

### Scenario B — W1b regression

- **Given** W1b props (single slip) only  
- **When** the UMAT runs the same increment as before W2  
- **Then** stress and `statev` match W1b baseline within tolerance  

### Scenario C — Invalid statev

- **Given** `nstatev < 8` for W2a  
- **When** the UMAT runs  
- **Then** `IF_STATUS_INVALID` is returned  
