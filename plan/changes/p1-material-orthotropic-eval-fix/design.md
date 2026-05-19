# Design: p1-material-orthotropic-eval-fix

## Arg 对齐

```fortran
TYPE, PUBLIC :: PH_Mat_ElasticOrthotropic_Eval_Arg
  TYPE(MD_ElasticMatDesc) :: mat_desc    ! [IN]
  REAL(wp) :: strain(6) = 0.0_wp         ! [IN]
  REAL(wp) :: sigma(6) = 0.0_wp          ! [OUT]
  REAL(wp) :: D_matrix(6, 6) = 0.0_wp    ! [OUT]
  TYPE(ErrorStatusType) :: status          ! [OUT]
END TYPE
```

## 过程签名

- **唯一公开形式**：`SUBROUTINE PH_Mat_ElasticOrthotropic_Eval(arg)` — 无额外 dummy。

## Harness

```text
python ufc_harness/run_harness.py guardian ufc_core/L4_PH/Material/Dispatch/PH_MatEval.f90 --fail-on-p0
python ufc_harness/run_harness.py change-package validate --change-id p1-material-orthotropic-eval-fix --strict
```
