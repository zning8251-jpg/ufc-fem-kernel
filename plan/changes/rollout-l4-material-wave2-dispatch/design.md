# Design: rollout-l4-material-wave2-dispatch

## Methodology to UFC mapping (wave 2 — Dispatch subtree)

| Methodology term | UFC realization (Dispatch path) |
|------------------|-----------------------------------|
| 四类 + Args | Dispatch callers pass **Desc/State/Ctx** slices consistent with slot contract; new boundary code uses unified `*_Arg` per Principle #14 (no new `inp`/`out` pairs). |
| 嵌套 / 并列 / 主从 | **Master** eval chain: `PH_MatEval*` / PLM facades route to family cores; nested models stay behind typed Desc, not ad-hoc globals. |
| 空间维度 | IP / quadrature hooks documented where they change **external** stress or tangent contract (module header or CONTRACT pointer). |
| 时间维度 | Stateful increments stay on **State** carriers; no silent writes to Desc-only fields (Guardian FLOW-003 class). |
| 动作维度 | Stress/tangent outputs and RT-facing writes obey **hot-path** and **DEP** rules (no L4→L5 dependency inversion). |

## Decisions

1. **Wave boundary**: Only `ufc_core/L4_PH/Material/Dispatch/` in this `change_id`; other Material subtrees require **new** `change_id` after DoD for §1 here.
2. **SSOT**: [`ufc_core/L4_PH/Material/CONTRACT.md`](../../../ufc_core/L4_PH/Material/CONTRACT.md) overrides chat narrative.
3. **Harness strategy**: Prefer **per-file** `guardian <path.f90> --fail-on-p0` when editing; whole-directory `guardian Dispatch` is the **baseline** metric, not necessarily green in the first PR.

## Open Questions

- Which single P0 rule cluster (e.g. FLOW-003 vs DEP-001) yields the best ROI first under `Dispatch/`?

## Alternatives considered

- Re-run whole `ufc_core/L4_PH/Material` P0 cleanup in one change — **rejected** (surface too large; repeats wave-1 lesson).
