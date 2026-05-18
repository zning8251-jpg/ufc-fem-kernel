# Tasks: rollout-l4-material-binary-trivium

## 1. Entry spine (wave 1 — audit + align plan)

- [x] 1.1 Read `ufc_core/L4_PH/Material/CONTRACT.md` + `plan/changes/rollout-l4-material-binary-trivium/specs/**`
- [x] 1.2 Audit `PH_Mat_Def.f90`, `PH_Mat_Dsp.f90`, `PH_L4_Populate.f90` for Desc/State/Algo/Ctx + `*_Arg` consistency vs CONTRACT
- [x] 1.3 Record gaps in `TASK_RUN.md` Log (no silent drift)

## 2. Harness gates (per batch of `.f90` edits)

**Wave-1 note:** 整域 `guardian ufc_core/L4_PH/Material --fail-on-p0` 与 `naming` 仍有存量告警；本波以脊索三文件为单位执行 discipline / guardian / naming，结果见 `plan/tasks/rollout-l4-material-binary-trivium/TASK_RUN.md` Log。

- [x] 2.1 `discipline verify --touch-path` on each touched file
- [x] 2.2 `guardian ufc_core/L4_PH/Material --fail-on-p0` (narrow path when possible)
- [x] 2.3 `naming ufc_core/L4_PH/Material`

## 3. Closure

- [x] 3.1 `change-package validate --change-id rollout-l4-material-binary-trivium --strict`
- [x] 3.2 `closure` (or `guardian` + `naming` if plan-checks noisy) before PR

## 4. Roll-forward

- [x] 4.1 Mark §1 DoD in `TASK_RUN`; open next `change_id` for next Material subtree or next domain
