# `NM_Solv_QuasiNewton.f90`

- **Source**: `L2_NM/Solver/NonlinSolv/NM_Solv_QuasiNewton.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Solv_QuasiNewton`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Solv_QuasiNewton`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Solv_QuasiNewton`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/NonlinSolv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/NonlinSolv/NM_Solv_QuasiNewton.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `QuasiNewton_Params_Method` (lines 47–50)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Params_Method
    INTEGER(i4) :: method = NM_QN_BFGS
    INTEGER(i4) :: initialization = NM_QN_INIT_SCALED
  END TYPE QuasiNewton_Params_Method
```

### `QuasiNewton_Params_Conv` (lines 52–55)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Params_Conv
    REAL(DP) :: tol = 1.0E-6_DP            !< convergence tolerance
    INTEGER(i4) :: max_iter = 1000_i4      !< max iterations
  END TYPE QuasiNewton_Params_Conv
```

### `QuasiNewton_Params_BFGS` (lines 57–61)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Params_BFGS
    REAL(DP) :: skip_threshold = 1.0E-8_DP !<  
    LOGICAL :: damped = .TRUE.             !< dampingBFGS
    REAL(DP) :: damping_factor = 0.2_DP    !< damping 
  END TYPE QuasiNewton_Params_BFGS
```

### `QuasiNewton_Params_LBFGS` (lines 63–65)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Params_LBFGS
    INTEGER(i4) :: m = 10_i4               !< L-BFGS length
  END TYPE QuasiNewton_Params_LBFGS
```

### `QuasiNewton_Params` (lines 67–72)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Params
    TYPE(QuasiNewton_Params_Method) :: method
    TYPE(QuasiNewton_Params_Conv) :: conv
    TYPE(QuasiNewton_Params_BFGS) :: bfgs
    TYPE(QuasiNewton_Params_LBFGS) :: lbfgs
  END TYPE QuasiNewton_Params
```

### `QuasiNewton_State_Iter` (lines 75–78)

```fortran
  TYPE, PUBLIC :: QuasiNewton_State_Iter
    INTEGER(i4) :: iteration = 0_i4        !< current iteration
    LOGICAL :: converged = .FALSE.         !< converged
  END TYPE QuasiNewton_State_Iter
```

### `QuasiNewton_State_Vars` (lines 80–83)

```fortran
  TYPE, PUBLIC :: QuasiNewton_State_Vars
    REAL(DP), ALLOCATABLE :: x(:)          !<  
    REAL(DP) :: f = ZERO                   !<  
  END TYPE QuasiNewton_State_Vars
```

### `QuasiNewton_State_Grad` (lines 85–88)

```fortran
  TYPE, PUBLIC :: QuasiNewton_State_Grad
    REAL(DP), ALLOCATABLE :: g(:)          !<  
    REAL(DP) :: norm_g = ZERO              !<  
  END TYPE QuasiNewton_State_Grad
```

### `QuasiNewton_State_Step` (lines 90–94)

```fortran
  TYPE, PUBLIC :: QuasiNewton_State_Step
    REAL(DP), ALLOCATABLE :: s(:)          !< step
    REAL(DP), ALLOCATABLE :: y(:)          !<  
    REAL(DP) :: alpha = ONE                !< step
  END TYPE QuasiNewton_State_Step
```

### `QuasiNewton_State` (lines 96–101)

```fortran
  TYPE, PUBLIC :: QuasiNewton_State
    TYPE(QuasiNewton_State_Iter) :: iter
    TYPE(QuasiNewton_State_Vars) :: vars
    TYPE(QuasiNewton_State_Grad) :: grad
    TYPE(QuasiNewton_State_Step) :: step
  END TYPE QuasiNewton_State
```

### `QuasiNewton_Result_Vars` (lines 104–107)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result_Vars
    REAL(DP), ALLOCATABLE :: x(:)          !<  
    REAL(DP) :: f = ZERO                   !<  
  END TYPE QuasiNewton_Result_Vars
```

### `QuasiNewton_Result_Grad` (lines 109–111)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result_Grad
    REAL(DP), ALLOCATABLE :: g(:)          !<  
  END TYPE QuasiNewton_Result_Grad
```

### `QuasiNewton_Result_Hessian` (lines 113–115)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result_Hessian
    REAL(DP), ALLOCATABLE :: H(:,:)        !<  Hessian
  END TYPE QuasiNewton_Result_Hessian
```

### `QuasiNewton_Result_Stats` (lines 117–121)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result_Stats
    INTEGER(i4) :: n_iterations = 0_i4     !< iter count
    INTEGER(i4) :: n_func_evals = 0_i4     !<  value 
    INTEGER(i4) :: n_grad_evals = 0_i4     !<  value 
  END TYPE QuasiNewton_Result_Stats
```

### `QuasiNewton_Result_Status` (lines 123–126)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result_Status
    LOGICAL :: converged = .FALSE.         !< converged
    CHARACTER(LEN=128) :: message = ""     !< message
  END TYPE QuasiNewton_Result_Status
```

### `QuasiNewton_Result` (lines 128–134)

```fortran
  TYPE, PUBLIC :: QuasiNewton_Result
    TYPE(QuasiNewton_Result_Vars) :: vars
    TYPE(QuasiNewton_Result_Grad) :: grad
    TYPE(QuasiNewton_Result_Hessian) :: hessian
    TYPE(QuasiNewton_Result_Stats) :: stats
    TYPE(QuasiNewton_Result_Status) :: status
  END TYPE QuasiNewton_Result
```

### `LBFGS_Storage` (lines 137–143)

```fortran
  TYPE, PUBLIC :: LBFGS_Storage
    INTEGER(i4) :: m = 0_i4                !<  length
    INTEGER(i4) :: k = 0_i4                !< current iteration
    REAL(DP), ALLOCATABLE :: s_history(:,:) !< s 
    REAL(DP), ALLOCATABLE :: y_history(:,:) !< y 
    REAL(DP), ALLOCATABLE :: rho(:)         !< 1/(y^T·s)
  END TYPE LBFGS_Storage
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `NM_QuasiNewton_Solv` | 187 | `SUBROUTINE NM_QuasiNewton_Solv(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 192 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 197 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_BFGS_Solv` | 233 | `SUBROUTINE NM_BFGS_Solv(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 238 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 243 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_DFP_Solv` | 332 | `SUBROUTINE NM_DFP_Solv(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 337 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 342 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_SR1_Solv` | 418 | `SUBROUTINE NM_SR1_Solv(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 423 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 428 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_LBFGS_Solv` | 503 | `SUBROUTINE NM_LBFGS_Solv(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 508 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 513 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_BFGS_Update` | 614 | `SUBROUTINE NM_BFGS_Update(H, s, y, ys, damped, damping_factor)` |
| SUBROUTINE | `NM_DFP_Update` | 661 | `SUBROUTINE NM_DFP_Update(H, s, y, ys)` |
| SUBROUTINE | `NM_SR1_Update` | 682 | `SUBROUTINE NM_SR1_Update(H, s, y)` |
| SUBROUTINE | `NM_Broyden_Update` | 703 | `SUBROUTINE NM_Broyden_Update(H, s, y, ys, phi)` |
| SUBROUTINE | `NM_LBFGS_Init` | 725 | `SUBROUTINE NM_LBFGS_Init(m, n, storage)` |
| SUBROUTINE | `NM_LBFGS_Store` | 747 | `SUBROUTINE NM_LBFGS_Store(storage, s, y, ys)` |
| SUBROUTINE | `NM_LBFGS_Two_Loop_Recursion` | 764 | `SUBROUTINE NM_LBFGS_Two_Loop_Recursion(storage, g, gamma, q)` |
| SUBROUTINE | `NM_QuasiNewton_Init` | 804 | `SUBROUTINE NM_QuasiNewton_Init(params, x0, Objective_proc, Gradient_proc, &` |
| FUNCTION | `Objective_proc` | 809 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 814 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| FUNCTION | `NM_Calc_Search_Direction` | 870 | `FUNCTION NM_Calc_Search_Direction(H, g) RESULT(p)` |
| FUNCTION | `NM_Check_Curvature_Condition` | 879 | `FUNCTION NM_Check_Curvature_Condition(s, y, tol) RESULT(satisfied)` |
| FUNCTION | `OUTER_PRODUCT` | 888 | `FUNCTION OUTER_PRODUCT(a, b) RESULT(C)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 191–202 | `INTERFACE` |
| 237–248 | `INTERFACE` |
| 336–347 | `INTERFACE` |
| 422–433 | `INTERFACE` |
| 507–518 | `INTERFACE` |
| 808–819 | `INTERFACE` |
