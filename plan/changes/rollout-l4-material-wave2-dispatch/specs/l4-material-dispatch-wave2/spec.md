# Spec: l4-material-dispatch-wave2

## ADDED Requirements

### Requirement: Dispatch subtree Guardian and naming are baselined

Material **Dispatch** façade code under [`ufc_core/L4_PH/Material/Dispatch/`](../../../../../ufc_core/L4_PH/Material/Dispatch) MUST have a recorded **baseline** `guardian` and `naming` run under this `change_id` before substantive refactors. Results MUST be logged in `plan/tasks/rollout-l4-material-wave2-dispatch/TASK_RUN.md` (rc + summary).

#### Scenario: Baseline guardian on Dispatch path

**WHEN** this change is accepted as the active wave for Material Dispatch  
**THEN** maintainers MUST run `python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch --fail-on-p0` once per wave start  
**AND** MUST record exit code and a short note of dominant rule families (e.g. FLOW-003, DEP-001) in `TASK_RUN.md` Log

#### Scenario: Baseline naming on Dispatch path

**WHEN** the same wave starts  
**THEN** maintainers MUST run `python ufc_harness/run_harness.py naming ufc_core/L4_PH/Material/Dispatch`  
**AND** MUST record exit code and whether issues are legacy vs newly introduced for touched files

### Requirement: No new cross-layer dependency inversion in edited Dispatch files

**WHEN** any `ufc_core/L4_PH/Material/Dispatch/**/*.f90` file is modified under this change  
**THEN** `guardian` MUST NOT report new **P0** `DEP-001` (L4_PH USE L5_RT) violations in that file  
**AND** MUST NOT add new `inp`/`out` pairs for new boundary procedures (Principle #14)

#### Scenario: Edited file stays P0-clean at file scope

**WHEN** a PR touches a specific `Dispatch/*.f90`  
**THEN** `guardian <that.f90> --fail-on-p0` MUST pass before merge  
**AND** `naming` on that file MUST pass
