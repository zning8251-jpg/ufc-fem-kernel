# `PH_Mat_Creep_Core.f90`

- **Source**: `L4_PH/Material/Creep/PH_Mat_Creep_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Creep_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Creep_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Creep`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Creep`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Creep/PH_Mat_Creep_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Creep_Props` (lines 75–89)

```fortran
  TYPE, PUBLIC :: PH_Creep_Props
    INTEGER(i4) :: creep_type = PH_CREEP_NORTON  ! 1=Norton, 2=Nabarro
    !-- Elastic
    REAL(wp)    :: E     = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp)    :: nu    = 0.0_wp   ! Poisson's ratio [-]
    !-- Norton parameters
    REAL(wp)    :: A_cr  = 0.0_wp   ! Creep coefficient [Pa^-n · s^-1]
    REAL(wp)    :: n_cr  = 1.0_wp   ! Stress exponent [-]
    REAL(wp)    :: Q_act = 0.0_wp   ! Activation energy [J/mol] (0 = isothermal)
    !-- Nabarro-Herring parameters
    REAL(wp)    :: B_nh  = 0.0_wp   ! Simplified Nabarro coefficient [Pa^-1·s^-1·m^2]
    REAL(wp)    :: d_grain = 1.0E-4_wp ! Grain size [m]
    !-- Temperature (for thermal activation)
    REAL(wp)    :: T_ref = 293.0_wp ! Reference temperature [K]
  END TYPE PH_Creep_Props
```

### `PH_Creep_State` (lines 94–100)

```fortran
  TYPE, PUBLIC :: PH_Creep_State
    REAL(wp) :: stress(6)      = 0.0_wp  ! Cauchy stress [Pa]
    REAL(wp) :: strain_cr(6)   = 0.0_wp  ! Creep strain (Voigt) [-]
    REAL(wp) :: eps_cr_eq      = 0.0_wp  ! Equivalent creep strain [-]
    REAL(wp) :: creep_rate     = 0.0_wp  ! Current creep strain rate [s^-1]
    REAL(wp) :: C_tan(6,6)     = 0.0_wp  ! Algorithmic tangent [Pa]
  END TYPE PH_Creep_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Creep_Validate_Params` | 110 | `SUBROUTINE PH_Mat_Creep_Validate_Params(props, ierr)` |
| SUBROUTINE | `PH_Mat_Creep_Init` | 164 | `SUBROUTINE PH_Mat_Creep_Init(props, state, ierr)` |
| SUBROUTINE | `PH_Mat_Creep_Compute_Stress` | 192 | `SUBROUTINE PH_Mat_Creep_Compute_Stress(props, strain_total, dt, T_curr, &` |
| SUBROUTINE | `PH_Mat_Creep_Compute_Tangent` | 336 | `SUBROUTINE PH_Mat_Creep_Compute_Tangent(props, dt, T_curr, state, &` |
| SUBROUTINE | `PH_Mat_Creep_Update_State` | 443 | `SUBROUTINE PH_Mat_Creep_Update_State(props, stress, C_tangent, state, ierr)` |
| SUBROUTINE | `creep_rate_scalar` | 459 | `SUBROUTINE creep_rate_scalar(props, sigma_eq, T_factor, eps_cr_rate)` |
| SUBROUTINE | `creep_rate_deriv` | 483 | `SUBROUTINE creep_rate_deriv(props, sigma_eq, T_factor, deriv)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
