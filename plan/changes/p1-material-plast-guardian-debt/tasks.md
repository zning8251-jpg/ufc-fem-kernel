# Tasks: p1-material-plast-guardian-debt

## 1. Readiness

- [x] 1.1 Guardian 基线：`Plast/` P0=6, P1=1（Chaboche INTF）
- [x] 1.2 变更包 + `TASK_RUN` 立项

## 2. Implementation

- [x] 2.1 FLOW-003：`PH_Mat_Plast_Core` Populate + `plast_desc_read_*`
- [x] 2.2 `UF_Chaboche_UMAT_Arg` + legacy 私有化 + PLMEval/Kernels 挂接
- [x] 2.3 MOD-001：`PH_Mat_Plast_Core`、`PH_Mat_Plast_Chaboche_Core` 模块头

## 3. Harness

- [x] 3.1 `guardian Plast --fail-on-p0` → P0=0, P1=0
- [x] 3.2 `discipline verify --touch-path …/Plast`（随 guardian 映射）
- [x] 3.3 `change-package validate --change-id p1-material-plast-guardian-debt --strict`

## 4. Roll-forward

- [x] 4.1 `PR_BODY.md`
- [ ] 4.2 合并后 archive `plan/tasks/p1-material-plast-guardian-debt/`
