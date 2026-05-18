# `NM_Solv_Continuation.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_Continuation.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_Continuation`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_Continuation`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_Continuation`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_Continuation.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `Continuation_Params_Method` (lines 54–58)

```fortran
  TYPE, PUBLIC :: Continuation_Params_Method
    INTEGER(i4) :: method = NM_CONTINUATION_PSEUDO_ARCLENGTH
    INTEGER(i4) :: predictor_type = NM_PREDICTOR_TANGENT
    INTEGER(i4) :: corrector_type = NM_CORRECTOR_NEWTON
  END TYPE Continuation_Params_Method
```

### `Continuation_Params_Step` (lines 60–64)

```fortran
  TYPE, PUBLIC :: Continuation_Params_Step
    REAL(DP) :: ds_init = 0.1_DP           !< initial step size
    REAL(DP) :: ds_min = 1.0E-6_DP         !< min step
    REAL(DP) :: ds_max = 1.0_DP            !< max step
  END TYPE Continuation_Params_Step
```

### `Continuation_Params_Iter` (lines 66–70)

```fortran
  TYPE, PUBLIC :: Continuation_Params_Iter
    INTEGER(i4) :: max_steps = 1000_i4     !< max step
    INTEGER(i4) :: max_corrector_iter = 10_i4  !<  
    REAL(DP) :: corrector_tol = 1.0E-6_DP  !<  
  END TYPE Continuation_Params_Iter
```

### `Continuation_Params_Bifurcation` (lines 72–76)

```fortran
  TYPE, PUBLIC :: Continuation_Params_Bifurcation
    REAL(DP) :: theta = 0.5_DP             !< stepcontrolparam
    LOGICAL :: detect_bifurcation = .TRUE. !<  
    REAL(DP) :: bifurcation_tol = 1.0E-4_DP
  END TYPE Continuation_Params_Bifurcation
```

### `Continuation_Params` (lines 78–83)

```fortran
  TYPE, PUBLIC :: Continuation_Params
    TYPE(Continuation_Params_Method) :: method
    TYPE(Continuation_Params_Step) :: step
    TYPE(Continuation_Params_Iter) :: iter
    TYPE(Continuation_Params_Bifurcation) :: bifurcation
  END TYPE Continuation_Params
```

### `Continuation_State_Param` (lines 86–92)

```fortran
  TYPE, PUBLIC :: Continuation_State_Param
    INTEGER(i4) :: step = 0_i4             !<  
    REAL(DP) :: lambda = ZERO              !<  param
    REAL(DP) :: lambda_prev = ZERO         !<  param
    REAL(DP) :: ds = ZERO                  !< current step size
    REAL(DP) :: ds_prev = ZERO             !<  
  END TYPE Continuation_State_Param
```

### `Continuation_State_Vector` (lines 94–99)

```fortran
  TYPE, PUBLIC :: Continuation_State_Vector
    REAL(DP), ALLOCATABLE :: u(:)          !<  
    REAL(DP), ALLOCATABLE :: u_prev(:)     !<  
    REAL(DP), ALLOCATABLE :: tangent(:)    !<  vector
    REAL(DP), ALLOCATABLE :: tangent_prev(:) !<  
  END TYPE Continuation_State_Vector
```

### `Continuation_State_Status` (lines 101–105)

```fortran
  TYPE, PUBLIC :: Continuation_State_Status
    LOGICAL :: converged = .FALSE.         !< converged
    LOGICAL :: bifurcation_detected = .FALSE.
    REAL(DP) :: residual_norm = ZERO
  END TYPE Continuation_State_Status
```

### `Continuation_State` (lines 107–111)

```fortran
  TYPE, PUBLIC :: Continuation_State
    TYPE(Continuation_State_Param) :: param
    TYPE(Continuation_State_Vector) :: vector
    TYPE(Continuation_State_Status) :: status
  END TYPE Continuation_State
```

### `Continuation_Result_Path` (lines 114–118)

```fortran
  TYPE, PUBLIC :: Continuation_Result_Path
    REAL(DP), ALLOCATABLE :: u_path(:,:)   !<  
    REAL(DP), ALLOCATABLE :: lambda_path(:) !< param 
    INTEGER(i4) :: n_steps = 0_i4          !<  
  END TYPE Continuation_Result_Path
```

### `Continuation_Result_Status` (lines 120–124)

```fortran
  TYPE, PUBLIC :: Continuation_Result_Status
    LOGICAL :: completed = .FALSE.         !< whether 
    LOGICAL :: bifurcation_found = .FALSE. !< whether 
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE Continuation_Result_Status
```

### `Continuation_Result` (lines 126–129)

```fortran
  TYPE, PUBLIC :: Continuation_Result
    TYPE(Continuation_Result_Path) :: path
    TYPE(Continuation_Result_Status) :: status
  END TYPE Continuation_Result
```

### `Homotopy_Params` (lines 132–137)

```fortran
  TYPE, PUBLIC :: Homotopy_Params
    INTEGER(i4) :: homotopy_type = NM_HOMOTOPY_FIXED_POINT
    REAL(DP) :: lambda_start = ZERO
    REAL(DP) :: lambda_end = ONE
    INTEGER(i4) :: n_steps = 100_i4
  END TYPE Homotopy_Params
```

### `Predictor_Corrector_Result` (lines 140–145)

```fortran
  TYPE, PUBLIC :: Predictor_Corrector_Result
    REAL(DP), ALLOCATABLE :: u(:)
    REAL(DP) :: lambda = ZERO
    LOGICAL :: converged = .FALSE.
    INTEGER(i4) :: n_corrector_iter = 0_i4
  END TYPE Predictor_Corrector_Result
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_Continuation_Solv` | 193 | `SUBROUTINE NM_Continuation_Solv(params, Residual_proc, Jacobian_proc, &` |
| SUBROUTINE | `Residual_proc` | 197 | `SUBROUTINE Residual_proc(u, lambda, R, status)` |
| SUBROUTINE | `Jacobian_proc` | 203 | `SUBROUTINE Jacobian_proc(u, lambda, J, status)` |
| SUBROUTINE | `NM_Natural_Continuation` | 232 | `SUBROUTINE NM_Natural_Continuation(params, Residual_proc, Jacobian_proc, &` |
| SUBROUTINE | `Residual_proc` | 236 | `SUBROUTINE Residual_proc(u, lambda, R, status)` |
| SUBROUTINE | `Jacobian_proc` | 242 | `SUBROUTINE Jacobian_proc(u, lambda, J, status)` |
| SUBROUTINE | `NM_Ps_Continuation` | 358 | `SUBROUTINE NM_Ps_Continuation(params, Residual_proc, Jacobian_proc, &` |
| SUBROUTINE | `Residual_proc` | 362 | `SUBROUTINE Residual_proc(u, lambda, R, status)` |
| SUBROUTINE | `Jacobian_proc` | 368 | `SUBROUTINE Jacobian_proc(u, lambda, J, status)` |
| SUBROUTINE | `NM_Homotopy_Solv` | 467 | `SUBROUTINE NM_Homotopy_Solv(homotopy_params, Continuation_proc, &` |
| SUBROUTINE | `Continuation_proc` | 471 | `SUBROUTINE Continuation_proc(u, lambda, R, status)` |
| SUBROUTINE | `NM_Tangent_Predictor` | 507 | `SUBROUTINE NM_Tangent_Predictor(state, ds, pc_result, status)` |
| SUBROUTINE | `NM_Secant_Predictor_Cont` | 530 | `SUBROUTINE NM_Secant_Predictor_Cont(state, ds, pc_result, status)` |
| SUBROUTINE | `NM_Euler_Predictor` | 562 | `SUBROUTINE NM_Euler_Predictor(state, ds, dudlambda, pc_result, status)` |
| SUBROUTINE | `NM_Newton_Corrector` | 588 | `SUBROUTINE NM_Newton_Corrector(params, Residual_proc, Jacobian_proc, &` |
| SUBROUTINE | `Residual_proc` | 592 | `SUBROUTINE Residual_proc(u_in, lambda_in, R, status)` |
| SUBROUTINE | `Jacobian_proc` | 598 | `SUBROUTINE Jacobian_proc(u_in, lambda_in, J, status)` |
| SUBROUTINE | `NM_PseudoArclength_Corrector` | 640 | `SUBROUTINE NM_PseudoArclength_Corrector(params, Residual_proc, Jacobian_proc, &` |
| SUBROUTINE | `Residual_proc` | 644 | `SUBROUTINE Residual_proc(u_in, lambda_in, R, status)` |
| SUBROUTINE | `Jacobian_proc` | 650 | `SUBROUTINE Jacobian_proc(u_in, lambda_in, J, status)` |
| SUBROUTINE | `NM_Calc_Tangent_Vector` | 678 | `SUBROUTINE NM_Calc_Tangent_Vector(J, F_lambda, tangent, status)` |
| SUBROUTINE | `NM_Calc_Null_Space` | 713 | `SUBROUTINE NM_Calc_Null_Space(A, null_vector, status)` |
| FUNCTION | `NM_Adapt_Step_Size` | 730 | `FUNCTION NM_Adapt_Step_Size(ds, iter, max_iter, theta, ds_min, ds_max) &` |
| SUBROUTINE | `NM_Update_Continuation_State` | 749 | `SUBROUTINE NM_Update_Continuation_State(state, pc_result)` |
| SUBROUTINE | `NM_Continuation_Init` | 767 | `SUBROUTINE NM_Continuation_Init(params, u0, lambda0, n, state)` |
| FUNCTION | `NM_Check_Turning_Point` | 798 | `FUNCTION NM_Check_Turning_Point(lambda_prev, lambda, tangent) RESULT(is_turning)` |
| FUNCTION | `NM_Check_Bifurcation` | 807 | `FUNCTION NM_Check_Bifurcation(state) RESULT(detected)` |
| SUBROUTINE | `Solv_Lin_System` | 823 | `SUBROUTINE Solv_Lin_System(A, b, x, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 196–209 | `INTERFACE` |
| 235–248 | `INTERFACE` |
| 361–374 | `INTERFACE` |
| 470–477 | `INTERFACE` |
| 591–604 | `INTERFACE` |
| 643–656 | `INTERFACE` |
