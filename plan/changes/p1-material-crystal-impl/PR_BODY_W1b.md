## Summary

- **W1b**: Replace W1a iso-surrogate with **1-slip Schmid** in `UF_CrystalPlasticity_UMAT` (mat_id 266).
- Resolved shear \(\tau = P:\sigma\); slip return on \(|\tau|\) vs \(\tau_c = \tau_{c0} + H\gamma\).
- **CONTRACT**: W1a marked **DEPRECATED**; W1b is current.

## Depends on

- [#12](https://github.com/zning8251-jpg/ufc-fem-kernel/pull/12) merged (W1a)

## Test plan

- [x] `guardian PH_Mat_Plast_Crystal_Core.f90 --fail-on-p0`
- [x] `change-package validate --change-id p1-material-crystal-impl --strict`

## props

| Index | Field |
|-------|--------|
| 1–4 | `E`, `nu`, `tau_c0`, `H` |
| 5–7 | `s1,s2,s3` (optional if `nprops≥9`) |
| 8–9 | `m1,m2` (`m3=0` unless `nprops≥10` → `props(10)`) |
