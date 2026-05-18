# `RT_Solv_TimeInt.f90`

- **Source**: `L5_RT/Solver/RT_Solv_TimeInt.f90`
- **Generated (UTC)**: 2026-05-07T07:47:18Z
- **MODULE (heuristic)**: `RT_Solv_TimeInt`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `RT_Solv_TimeInt`
- **逻辑主线（默认三段式 `RT_{Domain+Feature}`）**: `RT_Solv_TimeInt`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Solver`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L5_RT/Solver/RT_Solv_TimeInt.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `UF_TimeIntState` (lines 41–53)

```fortran
  type, public :: UF_TimeIntState
    real(wp), allocatable :: u_n(:)        ! Displacement at time n
    real(wp), allocatable :: v_n(:)        ! Velocity at time n
    real(wp), allocatable :: a_n(:)        ! Acceleration at time n
    real(wp), allocatable :: u_np1(:)      ! Displacement at time n+1
    real(wp), allocatable :: v_np1(:)      ! Velocity at time n+1
    real(wp), allocatable :: a_np1(:)      ! Acceleration at time n+1
    real(wp) :: t_n = 0.0_wp              ! Time at step n
    real(wp) :: t_np1 = 0.0_wp            ! Time at step n+1
    real(wp) :: dt = 0.0_wp               ! Time step
    real(wp) :: dt_prev = 0.0_wp          ! Previous time step
    integer(i4) :: step = 0_i4            ! Current step number
  end type UF_TimeIntState
```

### `UF_TimeIntConfig` (lines 55–69)

```fortran
  type, public :: UF_TimeIntConfig
    integer(i4) :: method = METHOD_NEWMARK
    real(wp) :: beta = 0.25_wp            ! Newmark beta parameter
    real(wp) :: gamma = 0.5_wp            ! Newmark gamma parameter
    real(wp) :: alpha = 0.0_wp            ! HHT-alpha parameter (alias for alpha_f)
    real(wp) :: alpha_f = 0.0_wp          ! HHT-alpha parameter
    real(wp) :: alpha_m = 0.0_wp          ! Generalized alpha parameter
    real(wp) :: rho_inf = 0.9_wp         ! Generalized alpha spectral radius
    logical :: adaptive = .false.         ! Use adaptive time stepping
    real(wp) :: dt_min = 1.0e-12_wp      ! Minimum time step
    real(wp) :: dt_max = 1.0_wp          ! Maximum time step
    real(wp) :: error_tolerance = 1.0e-6_wp  ! Error tolerance for adaptive stepping
    real(wp) :: adaptive_tolerance = 1.0e-6_wp ! Adaptive step tolerance
    real(wp) :: adaptive_safety = 0.9_wp  ! Safety factor for adaptive stepping
  end type UF_TimeIntConfig
```

### `UF_EnergyState` (lines 71–77)

```fortran
  type, public :: UF_EnergyState
    real(wp) :: kinetic_energy = 0.0_wp
    real(wp) :: potential_energ = 0.0_wp
    real(wp) :: total_energy = 0.0_wp
    real(wp) :: energy_error = 0.0_wp
    real(wp) :: energy_error_relative = 0.0_wp
  end type UF_EnergyState
```

### `RT_Solv_TimeInt_Core_Args` (lines 100–126)

```fortran
  TYPE :: RT_Solv_TimeInt_Core_Args
  ! Purpose: —�?  ! Theory:
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: tol         = 1.0e-12_wp  ! numerical tolerance
  REAL(wp), POINTER     :: coords(:,:) => NULL()  ! nodal coordinates ptr
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: state(:)    => NULL()  ! material state / SDV scratch ptr
  REAL(wp), POINTER     :: stress(:)   => NULL()  ! stress (Voigt) ptr
  REAL(wp), POINTER     :: strain(:)   => NULL()  ! strain (Voigt) ptr
  REAL(wp), POINTER     :: F_def(:,:)  => NULL()  ! deformation gradient ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  END TYPE RT_Solv_TimeInt_Core_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `AsmEffLoad_Newmark` | 131 | `subroutine AsmEffLoad_Newmark(F_ext_np1, F_int_np1, M, C, u_n, v_n, &` |
| SUBROUTINE | `AsmEffStiff_HHT` | 162 | `subroutine AsmEffStiff_HHT(K, M, C, alpha_f, a0, a1, K_eff, status)` |
| SUBROUTINE | `AsmEffStiff_Newmark` | 194 | `subroutine AsmEffStiff_Newmark(K, M, C, a0, a1, K_eff, status)` |
| SUBROUTINE | `AssembleEffectiveLoad_HHT` | 226 | `subroutine AssembleEffectiveLoad_HHT(F_ext_n, F_ext_np1, F_int_n, F_int_np1, &` |
| SUBROUTINE | `ConvertCSRToDense` | 261 | `subroutine ConvertCSRToDense(K_csr, K_dense, status)` |
| SUBROUTINE | `correct_newmark_Integ` | 289 | `subroutine correct_newmark_Integ(integrator)` |
| SUBROUTINE | `GaussianElimination` | 301 | `subroutine GaussianElimination(A, b, x, info)` |
| SUBROUTINE | `predict_newmark_Integ` | 342 | `subroutine predict_newmark_Integ(integrator)` |
| SUBROUTINE | `RT_TimeInt_CentralDiff` | 358 | `subroutine RT_TimeInt_CentralDiff(integrator, F_ext_np1, status)` |
| SUBROUTINE | `RT_TimeInt_Explicit_Integ` | 394 | `subroutine RT_TimeInt_Explicit_Integ(integrator, M, F_ext_n, F_ext_np1, &` |
| SUBROUTINE | `RT_TimeInt_GenAlpha` | 523 | `subroutine RT_TimeInt_GenAlpha(integrator, rho_inf, F_ext_np1, status)` |
| SUBROUTINE | `RT_TimeInt_HHT_Alpha` | 559 | `subroutine RT_TimeInt_HHT_Alpha(integrator, alpha, F_ext_np1, status)` |
| SUBROUTINE | `RT_TimeInt_HHT_Alpha_Dyn` | 642 | `subroutine RT_TimeInt_HHT_Alpha_Dyn(integrator, alpha, status)` |
| SUBROUTINE | `RT_TimeInt_Implicit_Integ` | 687 | `subroutine RT_TimeInt_Implicit_Integ(integrator, K, M, C, F_ext_np1, &` |
| SUBROUTINE | `RT_TimeInt_Newmark` | 795 | `subroutine RT_TimeInt_Newmark(integrator, F_ext_np1, status)` |
| SUBROUTINE | `RT_TimeInt_Newmark_Dyn` | 870 | `subroutine RT_TimeInt_Newmark_Dyn(integrator, status)` |
| SUBROUTINE | `SolveLinearSystem` | 916 | `subroutine SolveLinearSystem(A, b, x, status)` |
| SUBROUTINE | `SolveMassSystem` | 947 | `subroutine SolveMassSystem(M, b, x, status)` |
| SUBROUTINE | `UF_TimeIntegration_AdaptiveStep` | 987 | `subroutine UF_TimeIntegration_AdaptiveStep(state, config, error_estimate, &` |
| SUBROUTINE | `UF_TimeIntegration_CentralDifference` | 1035 | `subroutine UF_TimeIntegration_CentralDifference(state, config, M, F_ext_np1, &` |
| SUBROUTINE | `UF_TimeIntegration_EnergyConservation` | 1098 | `subroutine UF_TimeIntegration_EnergyConservation(state, M, K, energy_state, &` |
| SUBROUTINE | `UF_TimeIntegration_Newmark_Beta` | 1153 | `subroutine UF_TimeIntegration_Newmark_Beta(state, config, M, C, K, F_ext_np1, &` |
| SUBROUTINE | `UF_TimeIntegration_HHT_Alpha` | 1248 | `subroutine UF_TimeIntegration_HHT_Alpha(state, config, M, C, K, F_ext_n, &` |
| SUBROUTINE | `update_time_Integ_state` | 1344 | `subroutine update_time_Integ_state(integrator)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
