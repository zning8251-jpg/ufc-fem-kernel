# Design: rollout-l4-material-binary-trivium

## Methodology to UFC mapping (normative for this pilot)

| Methodology term | UFC realization (this domain) |
|------------------|------------------------------|
| 四类 TYPE + Args | **Desc / State / Algo / Ctx** bundles + `*_Arg` per Principle #14; L4 Populate path per `PH_L4_Populate` / domain `CONTRACT.md` |
| 嵌套 / 并列 / 主从 | Nested material models vs parallel branches vs **master** dispatch (`PH_Mat_Dispatch`, registry); document per-file in tasks |
| 空间维度 | Spatial discretization / quadrature / B-bar–type hooks **only** where `spec` Scenario applies (see spec) |
| 时间维度 | Time integration / increment state carriers (State) — scenarios reference **no** illegal cross-layer USE |
| 动作维度 | State updates, stress/path switches, outputs to RT — align with hot-path rules (Guardian HOT/DEP) |

## Decisions

1. **Pilot boundary**: First implementation wave targets files listed in `tasks.md` §1 only; expanding to full `L4_PH/Material/**/*.f90` requires a **new** `change_id` after DoD for §1.
2. **SSOT**: [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) overrides narrative in chat; if conflict, update CONTRACT in a separate explicitly-scoped change.
3. **SIO**: New or refactored `_Proc` / boundary procedures follow `ufc-structured-io` (five- or six-tuple + `*_Arg`).

## Open Questions

- (Fill per wave) Which Material branch (Elas/Plast/Hyper/…) is second after the entry spine in §1?

## Alternatives considered

- Single mega-change covering all L4_PH — **rejected** (review and Guardian surface too large).
