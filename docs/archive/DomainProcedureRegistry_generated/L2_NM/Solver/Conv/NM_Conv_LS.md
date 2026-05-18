# `NM_Conv_LS.f90`

- **Source**: `L2_NM/Solver/Conv/NM_Conv_LS.f90`
- **Generated (UTC)**: 2026-05-07T07:47:16Z
- **MODULE (heuristic)**: `NM_Conv_LS`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `NM_Conv_LS`
- **逻辑主线（默认三段式 `NM_{Domain+Feature}`）**: `NM_Conv_LS`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver/Conv`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L2_NM/Solver/Conv/NM_Conv_LS.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `LineSearch_Params` (lines 39–50)

```fortran
  TYPE, PUBLIC :: LineSearch_Params
    INTEGER(i4) :: criterion = NM_LINESEARCH_WOLFE
    REAL(DP) :: c1 = 1.0E-4_DP
    REAL(DP) :: c2 = 0.9_DP
    REAL(DP) :: alpha_init = 1.0_DP
    REAL(DP) :: alpha_min = 1.0E-10_DP
    REAL(DP) :: alpha_max = 1.0E10_DP
    REAL(DP) :: rho = 0.5_DP
    INTEGER(i4) :: max_iter = 20_i4
    INTEGER(i4) :: interpolation = NM_INTERP_CUBIC
    LOGICAL :: verbose = .FALSE.
  END TYPE LineSearch_Params
```

### `LineSearch_State_Step` (lines 52–55)

```fortran
  TYPE, PUBLIC :: LineSearch_State_Step
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: alpha_prev = ZERO
  END TYPE LineSearch_State_Step
```

### `LineSearch_State_Obj` (lines 57–61)

```fortran
  TYPE, PUBLIC :: LineSearch_State_Obj
    REAL(DP) :: phi = ZERO
    REAL(DP) :: phi_prev = ZERO
    REAL(DP) :: phi0 = ZERO
  END TYPE LineSearch_State_Obj
```

### `LineSearch_State_Grad` (lines 63–67)

```fortran
  TYPE, PUBLIC :: LineSearch_State_Grad
    REAL(DP) :: dphi = ZERO
    REAL(DP) :: dphi_prev = ZERO
    REAL(DP) :: dphi0 = ZERO
  END TYPE LineSearch_State_Grad
```

### `LineSearch_State_Status` (lines 69–72)

```fortran
  TYPE, PUBLIC :: LineSearch_State_Status
    INTEGER(i4) :: iteration = 0_i4
    LOGICAL :: converged = .FALSE.
  END TYPE LineSearch_State_Status
```

### `LineSearch_State` (lines 74–79)

```fortran
  TYPE, PUBLIC :: LineSearch_State
    TYPE(LineSearch_State_Step)   :: step
    TYPE(LineSearch_State_Obj)    :: obj
    TYPE(LineSearch_State_Grad)   :: grad
    TYPE(LineSearch_State_Status) :: status
  END TYPE LineSearch_State
```

### `LineSearch_Result` (lines 81–88)

```fortran
  TYPE, PUBLIC :: LineSearch_Result
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: phi_alpha = ZERO
    REAL(DP) :: dphi_alpha = ZERO
    INTEGER(i4) :: n_iterations = 0_i4
    LOGICAL :: success = .FALSE.
    CHARACTER(LEN=128) :: message = ""
  END TYPE LineSearch_Result
```

### `Function_Eval` (lines 90–94)

```fortran
  TYPE, PUBLIC :: Function_Eval
    REAL(DP) :: alpha = ZERO
    REAL(DP) :: phi = ZERO
    REAL(DP) :: dphi = ZERO
  END TYPE Function_Eval
```

### `TrustRegion_Params_Method` (lines 97–99)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params_Method
    INTEGER(i4) :: method
  END TYPE TrustRegion_Params_Method
```

### `TrustRegion_Params_Delta` (lines 101–105)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params_Delta
    REAL(DP) :: delta_init
    REAL(DP) :: delta_min
    REAL(DP) :: delta_max
  END TYPE TrustRegion_Params_Delta
```

### `TrustRegion_Params_Eta` (lines 107–111)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params_Eta
    REAL(DP) :: eta
    REAL(DP) :: eta1
    REAL(DP) :: eta2
  END TYPE TrustRegion_Params_Eta
```

### `TrustRegion_Params_Gamma` (lines 113–116)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params_Gamma
    REAL(DP) :: gamma1
    REAL(DP) :: gamma2
  END TYPE TrustRegion_Params_Gamma
```

### `TrustRegion_Params_CG` (lines 118–121)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params_CG
    INTEGER(i4) :: max_cg_iter
    REAL(DP) :: cg_tol
  END TYPE TrustRegion_Params_CG
```

### `TrustRegion_Params` (lines 123–129)

```fortran
  TYPE, PUBLIC :: TrustRegion_Params
    TYPE(TrustRegion_Params_Method) :: method
    TYPE(TrustRegion_Params_Delta) :: delta
    TYPE(TrustRegion_Params_Eta) :: eta
    TYPE(TrustRegion_Params_Gamma) :: gamma
    TYPE(TrustRegion_Params_CG) :: cg
  END TYPE TrustRegion_Params
```

### `TrustRegion_State` (lines 131–137)

```fortran
  TYPE, PUBLIC :: TrustRegion_State
    REAL(DP) :: delta
    REAL(DP) :: rho
    INTEGER(i4) :: iter_count
    LOGICAL :: converged
    LOGICAL :: hit_boundary
  END TYPE TrustRegion_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| FUNCTION | `NM_LineSearch_Default_Params` | 167 | `FUNCTION NM_LineSearch_Default_Params() RESULT(params)` |
| SUBROUTINE | `NM_LineSearch` | 184 | `SUBROUTINE NM_LineSearch(params, x0, d, phi0, dphi0, &` |
| FUNCTION | `Objective_proc` | 190 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 195 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_LineSearch_Armijo` | 220 | `SUBROUTINE NM_LineSearch_Armijo(params, x0, d, phi0, dphi0, &` |
| FUNCTION | `Objective_proc` | 226 | `FUNCTION Objective_proc(x) RESULT(f)` |
| SUBROUTINE | `NM_LineSearch_Wolfe` | 273 | `SUBROUTINE NM_LineSearch_Wolfe(params, x0, d, phi0, dphi0, &` |
| FUNCTION | `Objective_proc` | 279 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 284 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_LineSearch_Strong_Wolfe` | 347 | `SUBROUTINE NM_LineSearch_Strong_Wolfe(params, x0, d, phi0, dphi0, &` |
| FUNCTION | `Objective_proc` | 353 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `Gradient_proc` | 358 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| SUBROUTINE | `NM_Backtracking_LineSearch` | 419 | `SUBROUTINE NM_Backtracking_LineSearch(x0, d, phi0, dphi0, rho, c1, &` |
| FUNCTION | `Objective_proc` | 425 | `FUNCTION Objective_proc(x) RESULT(f)` |
| SUBROUTINE | `NM_Backtracking_Cubic` | 451 | `SUBROUTINE NM_Backtracking_Cubic(x0, d, phi0, dphi0, rho, c1, &` |
| FUNCTION | `Objective_proc` | 457 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `NM_Cubic_Interpolation_Step` | 488 | `FUNCTION NM_Cubic_Interpolation_Step(a, b, phi_a, phi_b, dphi_a, dphi_b) RESULT(alpha)` |
| FUNCTION | `NM_Quadratic_Interpolation_Step` | 508 | `FUNCTION NM_Quadratic_Interpolation_Step(a, b, phi_a, phi_b, dphi_a) RESULT(alpha)` |
| SUBROUTINE | `NM_Golden_Section_LineSearch` | 521 | `SUBROUTINE NM_Golden_Section_LineSearch(x0, d, phi0, dphi0, Objective_proc, alpha, status)` |
| FUNCTION | `Objective_proc` | 525 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `NM_Eval_Phi` | 566 | `FUNCTION NM_Eval_Phi(x0, d, alpha, Objective_proc) RESULT(phi)` |
| FUNCTION | `Objective_proc` | 569 | `FUNCTION Objective_proc(x) RESULT(f)` |
| FUNCTION | `NM_Eval_Dphi` | 583 | `FUNCTION NM_Eval_Dphi(x0, d, alpha, Gradient_proc) RESULT(dphi)` |
| FUNCTION | `Gradient_proc` | 586 | `FUNCTION Gradient_proc(x) RESULT(g)` |
| FUNCTION | `NM_Check_Armijo_Condition` | 601 | `FUNCTION NM_Check_Armijo_Condition(phi_alpha, phi0, dphi0, alpha, c1) RESULT(satisfied)` |
| FUNCTION | `NM_Check_Wolfe_Condition` | 607 | `FUNCTION NM_Check_Wolfe_Condition(dphi_alpha, dphi0, c2) RESULT(satisfied)` |
| SUBROUTINE | `NM_LineSearch_Init` | 613 | `SUBROUTINE NM_LineSearch_Init(state, phi0, dphi0, alpha_init)` |
| FUNCTION | `NM_TrustRegion_Default_Params` | 631 | `FUNCTION NM_TrustRegion_Default_Params() RESULT(params)` |
| SUBROUTINE | `NM_Find_Boundary_Intersection` | 646 | `SUBROUTINE NM_Find_Boundary_Intersection(z, d, delta, p)` |
| SUBROUTINE | `NM_TrustRegion_Dogleg` | 664 | `SUBROUTINE NM_TrustRegion_Dogleg(g, B, delta, p, hit_boundary)` |
| SUBROUTINE | `NM_TrustRegion_Steihaug` | 721 | `SUBROUTINE NM_TrustRegion_Steihaug(g, B, delta, params, p, hit_boundary)` |
| SUBROUTINE | `NM_TrustRegion_Update_Radius` | 776 | `SUBROUTINE NM_TrustRegion_Update_Radius(rho, params, state)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 189–200 | `INTERFACE` |
| 225–231 | `INTERFACE` |
| 278–289 | `INTERFACE` |
| 352–363 | `INTERFACE` |
| 424–430 | `INTERFACE` |
| 456–462 | `INTERFACE` |
| 524–530 | `INTERFACE` |
| 568–574 | `INTERFACE` |
| 585–591 | `INTERFACE` |
