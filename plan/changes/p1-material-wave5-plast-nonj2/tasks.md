# Tasks: p1-material-wave5-plast-nonj2

## 1. Readiness

- [ ] 1.1 Read `L4_PH/Material/CONTRACT.md` Plast 节 + `specs/**`
- [ ] 1.2 Confirm wave3 **merged** 或 rebase：`PH_Mat_Plast_J2_*` 不重复改
- [ ] 1.3 Baseline guardian（记入 TASK_RUN Log）：
  - `PH_Mat_Plast_Hill_Core.f90` — INTF `UF_Hill_UMAT`
  - `PH_Mat_Plast_Barlat_Core.f90` — NAME P2
  - `PH_Mat_Plast_Crystal_Core.f90` — INTF `UF_CrystalPlasticity_UMAT`

**In-scope**

| 文件 | 入口 |
|------|------|
| `Plast/PH_Mat_Plast_Hill_Core.f90` | `UF_Hill_UMAT` |
| `Plast/PH_Mat_Plast_Barlat_Core.f90` | `PH_Mat_Barlat_Calc_Stress` |
| `Plast/PH_Mat_Plast_Crystal_Core.f90` | `UF_CrystalPlasticity_UMAT` |
| `Dispatch/PH_MatPLM_Kernels.f90` | USE/转发 `UF_Hill_UMAT`（仅连锁） |
| `Dispatch/PH_MatPLMEval.f90` | `CALL UF_Hill_UMAT`（仅连锁） |

## 2. PR-A — Hill + Barlat（SIO 2/2）

- [x] 2.1 `UF_Hill_UMAT_Arg` + `UF_Hill_UMAT(arg)`
- [x] 2.2 `PH_MatPLMEval` / `PH_MatPLM_Kernels` 挂接 Hill Arg
- [x] 2.3 `PH_Mat_Barlat_Calc_Stress_Arg` + 单参入口；`PH_Mat_Barlat_Calc_Stress_Core` private
- [x] 2.4 MOD-001：Hill / Barlat 模块头
- [x] 2.5 harness：discipline + guardian touched + `change-package validate --strict`

## 3. PR-B — Crystal

- [x] 3.1 `UF_CrystalPlasticity_UMAT_Arg` + 单参入口
- [x] 3.2 MOD-001 Crystal 模块头
- [x] 3.3 harness（同上）

## 4. Closure

- [x] 4.1 G1–G6 勾选 + `PR_BODY_PR-A.md` / `PR_BODY_PR-B.md`
- [ ] 4.2 合并后 `plan/tasks/p1-material-wave5-plast-nonj2` → `plan/archive/`

## 5. Roll-forward

- [ ] 5.1 下一：**`p1-material-wave5-mateval-arg`**（Eval 合同收口）
- [ ] 5.2 Chaboche / 全 `Plast/` guardian — 新 change_id
