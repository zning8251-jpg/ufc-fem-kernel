# `PH_Mat_Damage_Lemaitre_Core.f90`

- **Source**: `L4_PH/Material/Damage/PH_Mat_Damage_Lemaitre_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Damage_Lemaitre_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Damage_Lemaitre_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Damage_Lemaitre`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Damage`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Damage/PH_Mat_Damage_Lemaitre_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_CDM_Props` (lines 91–109)

```fortran
  TYPE, PUBLIC :: PH_CDM_Props
    !-- Damage parameters (§5.2)
    REAL(wp) :: S_dmg       = 0.0_wp   ! Damage strength parameter S [Pa]
    REAL(wp) :: s_exp       = 1.0_wp   ! Damage exponent s [-]
    REAL(wp) :: eps_D       = 0.0_wp   ! Damage threshold strain [-]
    REAL(wp) :: D_crit      = 0.5_wp   ! Critical damage value D_c [-]
    !-- Elastic parameters (shared with J2)
    REAL(wp) :: E           = 0.0_wp   ! Young's modulus [Pa]
    REAL(wp) :: nu          = 0.0_wp   ! Poisson's ratio [-]
    !-- Plasticity parameters (delegated to J2 kernel)
    REAL(wp) :: sigma_y0    = 0.0_wp   ! Initial yield stress [Pa]
    REAL(wp) :: H           = 0.0_wp   ! Linear hardening modulus [Pa]
    REAL(wp) :: K_swift     = 0.0_wp   ! Swift K parameter [Pa]
    REAL(wp) :: n_swift     = 0.0_wp   ! Swift exponent [-]
    REAL(wp) :: eps0_swift  = 0.0_wp   ! Swift reference strain [-]
    REAL(wp) :: sigma_inf   = 0.0_wp   ! Voce saturation stress [Pa]
    REAL(wp) :: delta_voce  = 0.0_wp   ! Voce decay rate [-]
    INTEGER(i4) :: hardening_type = 1_i4  ! 1=Linear, 2=Swift, 3=Voce
  END TYPE PH_CDM_Props
```

### `PH_CDM_State` (lines 116–126)

```fortran
  TYPE, PUBLIC :: PH_CDM_State
    REAL(wp) :: D           = 0.0_wp   ! Damage variable [0,1]
    REAL(wp) :: Y           = 0.0_wp   ! Damage energy release rate [Pa]
    REAL(wp) :: eps_p_eq    = 0.0_wp   ! Equivalent plastic strain [-]
    REAL(wp) :: strain_p(6) = 0.0_wp   ! Plastic strain (Voigt) [-]
    REAL(wp) :: stress(6)   = 0.0_wp   ! Nominal (Cauchy) stress (Voigt) [Pa]
    REAL(wp) :: eff_stress(6) = 0.0_wp ! Effective stress σ̃ (Voigt) [Pa]
    REAL(wp) :: D_ep(6,6)   = 0.0_wp   ! Damaged consistent tangent [Pa]
    LOGICAL  :: damaged     = .FALSE.  ! Damage activated (ε̄_p > ε_D)
    LOGICAL  :: failed      = .FALSE.  ! Material failed (D >= D_crit)
  END TYPE PH_CDM_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_CDM_ComputeStress` | 136 | `SUBROUTINE PH_CDM_ComputeStress(props, strain_inc, state, tangent, pnewdt, ierr)` |
| SUBROUTINE | `PH_CDM_Init` | 166 | `SUBROUTINE PH_CDM_Init(props, state, ierr)` |
| SUBROUTINE | `PH_CDM_CoupledUpdate` | 215 | `SUBROUTINE PH_CDM_CoupledUpdate(props, strain_inc, state, tangent, pnewdt, ierr)` |
| SUBROUTINE | `PH_CDM_EffectiveStress` | 414 | `SUBROUTINE PH_CDM_EffectiveStress(stress, D, eff_stress)` |
| SUBROUTINE | `PH_CDM_EnergyRelease` | 433 | `SUBROUTINE PH_CDM_EnergyRelease(sigma_eq, Rv, E, Y)` |
| SUBROUTINE | `PH_CDM_Triaxiality` | 451 | `SUBROUTINE PH_CDM_Triaxiality(stress, sigma_eq, nu, Rv)` |
| SUBROUTINE | `PH_CDM_DamageEvolution` | 479 | `SUBROUTINE PH_CDM_DamageEvolution(Y, S_dmg, s_exp, dg, D_old, D_crit, D_new)` |
| SUBROUTINE | `PH_CDM_DamagedTangent` | 511 | `SUBROUTINE PH_CDM_DamagedTangent(D_el, G, H_tan, dg, q_trial, n_dir, &` |
| SUBROUTINE | `PH_Mat_CDM_Validate_Params` | 576 | `SUBROUTINE PH_Mat_CDM_Validate_Params(props, ierr)` |
| SUBROUTINE | `PH_Mat_CDM_Compute_Stress` | 602 | `SUBROUTINE PH_Mat_CDM_Compute_Stress(props, strain_inc, state, stress, ierr)` |
| SUBROUTINE | `PH_Mat_CDM_Compute_Tangent` | 620 | `SUBROUTINE PH_Mat_CDM_Compute_Tangent(props, state, C_tangent, ierr)` |
| SUBROUTINE | `PH_Mat_CDM_Update_State` | 634 | `SUBROUTINE PH_Mat_CDM_Update_State(props, state, ierr)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
