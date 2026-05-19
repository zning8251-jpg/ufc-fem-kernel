# Tasks: p1-material-orthotropic-eval-fix

## 1. Readiness

- [x] 1.1 确认 `PH_MatEval.f90` orthotropic 残留 dummy
- [x] 1.2 变更包 + TASK_RUN

## 2. Implementation

- [x] 2.1 扩展 `PH_Mat_ElasticOrthotropic_Eval_Arg`
- [x] 2.2 删除 `PH_Mat_ElasticOrthotropic_Eval` 内多余 dummy
- [x] 2.3 CONTRACT Legacy 表 orthotropic 行

## 3. Harness

- [x] 3.1 `guardian PH_MatEval.f90 --fail-on-p0`
- [x] 3.2 `change-package validate --strict`

## 4. Roll-forward

- [x] 4.1 PR
- [ ] 4.2 合并后 archive task
