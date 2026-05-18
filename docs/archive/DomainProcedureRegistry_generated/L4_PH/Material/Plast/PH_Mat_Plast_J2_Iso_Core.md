# `PH_Mat_Plast_J2_Iso_Core.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Plast_J2_Iso_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_J2_Iso_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast_J2_Iso`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_J2_Iso_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_J2_Cfg_Elastic` (lines 56–59)

```fortran
  TYPE, PUBLIC :: PH_J2_Cfg_Elastic
    REAL(wp) :: E           = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp) :: nu          = 0.0_wp   ! Poisson's ratio [-]
  END TYPE PH_J2_Cfg_Elastic
```

### `PH_J2_Cfg_Yield` (lines 61–63)

```fortran
  TYPE, PUBLIC :: PH_J2_Cfg_Yield
    REAL(wp) :: sigma_y0    = 0.0_wp   ! Initial yield stress [Pa]
  END TYPE PH_J2_Cfg_Yield
```

### `PH_J2_Cfg_Harden` (lines 65–77)

```fortran
  TYPE, PUBLIC :: PH_J2_Cfg_Harden
    REAL(wp) :: H           = 0.0_wp   ! Linear hardening modulus [Pa]
    !-- Swift parameters: σ_y = K_swift*(eps0_swift + ε̄_p)^n_swift
    REAL(wp) :: K_swift     = 0.0_wp   ! Swift strength coefficient [Pa]
    REAL(wp) :: n_swift     = 0.0_wp   ! Swift hardening exponent [-]
    REAL(wp) :: eps0_swift  = 0.0_wp   ! Swift reference strain [-]
    !-- Voce parameters: σ_y = σ_y0 + sigma_inf*(1 - exp(-delta_voce*ε̄_p))
    REAL(wp) :: sigma_inf   = 0.0_wp   ! Voce saturation stress [Pa]
    REAL(wp) :: delta_voce  = 0.0_wp   ! Voce decay rate [-]
    !-- Armstrong-Frederick kinematic: dα = (2/3)C·dε_p - γ·α·dε̄_p
    REAL(wp) :: C_af        = 0.0_wp   ! AF hardening C parameter [Pa]
    REAL(wp) :: gamma_af    = 0.0_wp   ! AF recall parameter γ [-]
  END TYPE PH_J2_Cfg_Harden
```

### `PH_J2_Cfg_Control` (lines 79–82)

```fortran
  TYPE, PUBLIC :: PH_J2_Cfg_Control
    INTEGER(i4) :: hardening_type = HARD_LINEAR
    LOGICAL     :: use_kinematic  = .FALSE.
  END TYPE PH_J2_Cfg_Control
```

### `PH_J2_Props` (lines 84–90)

```fortran
  TYPE, PUBLIC :: PH_J2_Props
    TYPE(PH_J2_Cfg_Elastic)  :: elastic
    TYPE(PH_J2_Cfg_Yield)    :: yield
    TYPE(PH_J2_Cfg_Harden)   :: harden
    TYPE(PH_J2_Cfg_Control)  :: ctrl
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_J2_Props
```

### `PH_J2_St_Plastic` (lines 100–104)

```fortran
  TYPE, PUBLIC :: PH_J2_St_Plastic
    REAL(wp) :: eps_p_eq       = 0.0_wp    ! Equivalent plastic strain ε̄_p
    REAL(wp) :: strain_p(6)    = 0.0_wp    ! Plastic strain ε_p (Voigt)
    LOGICAL  :: yielded        = .FALSE.   ! Current yield state flag
  END TYPE PH_J2_St_Plastic
```

### `PH_J2_St_Stress` (lines 106–109)

```fortran
  TYPE, PUBLIC :: PH_J2_St_Stress
    REAL(wp) :: stress(6)      = 0.0_wp    ! Cauchy stress σ (Voigt)
    REAL(wp) :: backstress(6)  = 0.0_wp    ! Backstress α (kinematic hardening)
  END TYPE PH_J2_St_Stress
```

### `PH_J2_St_Tangent` (lines 111–113)

```fortran
  TYPE, PUBLIC :: PH_J2_St_Tangent
    REAL(wp) :: D_ep(6,6)      = 0.0_wp    ! Consistent tangent modulus
  END TYPE PH_J2_St_Tangent
```

### `PH_J2_State` (lines 115–120)

```fortran
  TYPE, PUBLIC :: PH_J2_State
    TYPE(PH_J2_St_Plastic) :: plastic
    TYPE(PH_J2_St_Stress)  :: stress
    TYPE(PH_J2_St_Tangent) :: tangent
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_J2_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_J2_ComputeStress` | 136 | `SUBROUTINE PH_J2_ComputeStress(props, strain_inc, state, tangent, pnewdt, ierr)` |
| SUBROUTINE | `PH_J2_Init` | 201 | `SUBROUTINE PH_J2_Init(props, state, ierr)` |
| SUBROUTINE | `PH_J2_TrialStress` | 240 | `SUBROUTINE PH_J2_TrialStress(props, stress_n, strain_inc, &` |
| SUBROUTINE | `PH_J2_YieldCheck` | 309 | `SUBROUTINE PH_J2_YieldCheck(props, eps_p_eq, q_trial, f_trial, sigma_y)` |
| SUBROUTINE | `PH_J2_RadialReturn` | 337 | `SUBROUTINE PH_J2_RadialReturn(props, state, G, q_trial, s_trial, p_mean, &` |
| SUBROUTINE | `PH_J2_ConsistentTangent` | 449 | `SUBROUTINE PH_J2_ConsistentTangent(props, D_el, G, dg, q_trial, n_dir, &` |
| SUBROUTINE | `PH_J2_Hardening` | 527 | `SUBROUTINE PH_J2_Hardening(props, eps_p_eq, sigma_y)` |
| SUBROUTINE | `PH_J2_HardeningTangent` | 560 | `SUBROUTINE PH_J2_HardeningTangent(props, eps_p_eq, H_tan)` |
| SUBROUTINE | `PH_Mat_J2_Validate_Params` | 592 | `SUBROUTINE PH_Mat_J2_Validate_Params(props, ierr)` |
| SUBROUTINE | `PH_Mat_J2_Compute_Stress` | 613 | `SUBROUTINE PH_Mat_J2_Compute_Stress(props, strain_inc, state, stress, ierr)` |
| SUBROUTINE | `PH_Mat_J2_Compute_Tangent` | 631 | `SUBROUTINE PH_Mat_J2_Compute_Tangent(props, state, C_tangent, ierr)` |
| SUBROUTINE | `PH_Mat_J2_Update_State` | 645 | `SUBROUTINE PH_Mat_J2_Update_State(props, state, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
