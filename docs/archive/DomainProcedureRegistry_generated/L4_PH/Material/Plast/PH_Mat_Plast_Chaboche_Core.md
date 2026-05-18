# `PH_Mat_Plast_Chaboche_Core.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_Chaboche_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Mat_Plast_Chaboche_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_Chaboche_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast_Chaboche`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_Chaboche_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `ChabMat` (lines 101–112)

```fortran
  TYPE, PRIVATE :: ChabMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: lambda = 0.0_wp
    REAL(wp) :: mu = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    INTEGER(i4) :: n_components = 2_i4
    REAL(wp) :: C(3) = 0.0_wp
    REAL(wp) :: gamma(3) = 0.0_wp
    LOGICAL :: init = .FALSE.
  END TYPE ChabMat
```

### `PH_Chab_Cfg_Elastic` (lines 116–119)

```fortran
  TYPE, PUBLIC :: PH_Chab_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Chab_Cfg_Elastic
```

### `PH_Chab_Cfg_Yield` (lines 121–123)

```fortran
  TYPE, PUBLIC :: PH_Chab_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp ! Initial yield stress
  END TYPE PH_Chab_Cfg_Yield
```

### `PH_Chab_Cfg_BackStress` (lines 125–129)

```fortran
  TYPE, PUBLIC :: PH_Chab_Cfg_BackStress
    INTEGER(i4) :: n_back_stresses = 2_i4 ! Number of backstresses (typically 2-4)
    REAL(wp) :: C_kinematic(PH_MAT_MAX_BACK_STRESSES) = 0.0_wp ! Kinematic hardening modulus
    REAL(wp) :: gamma_recall(PH_MAT_MAX_BACK_STRESSES) = 0.0_wp ! Dynamic recovery parameter
  END TYPE PH_Chab_Cfg_BackStress
```

### `PH_Chab_Cfg_Isotrop` (lines 131–134)

```fortran
  TYPE, PUBLIC :: PH_Chab_Cfg_Isotrop
    REAL(wp) :: b_isotropic = 0.0_wp ! Isotropic hardening rate
    REAL(wp) :: R_infinity = 0.0_wp  ! Saturation isotropic hardening
  END TYPE PH_Chab_Cfg_Isotrop
```

### `Chab_Params` (lines 136–142)

```fortran
  TYPE, PUBLIC :: Chab_Params
    TYPE(PH_Chab_Cfg_Elastic)    :: elastic
    TYPE(PH_Chab_Cfg_Yield)      :: yield
    TYPE(PH_Chab_Cfg_BackStress) :: back
    TYPE(PH_Chab_Cfg_Isotrop)    :: isotrop
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Chab_Params
```

### `Chab_State` (lines 144–153)

```fortran
  TYPE, PUBLIC :: Chab_State
    REAL(wp), ALLOCATABLE :: stress_current(:)
    REAL(wp), ALLOCATABLE :: strain_plastic(:)
    REAL(wp), ALLOCATABLE :: back_stress(:,:)  ! n_back × 6
    REAL(wp), ALLOCATABLE :: back_stress_total(:)
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: R_isotropic = 0.0_wp ! isotropic hardening variable
    REAL(wp) :: yield_stress_current = 0.0_wp
    LOGICAL  :: is_plastic = .FALSE.
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Chaboche_Init` | 160 | `SUBROUTINE PH_Mat_Chaboche_Init(params, state)` |
| SUBROUTINE | `PH_Mat_Chaboche_Calc_Stress` | 178 | `SUBROUTINE PH_Mat_Chaboche_Calc_Stress(params, state, strain_increment, sigma)` |
| SUBROUTINE | `Return_Mapping_Chaboche` | 219 | `SUBROUTINE Return_Mapping_Chaboche(params, state, stress_trial, sigma)` |
| SUBROUTINE | `Update_Back_Stress_Chaboche` | 254 | `SUBROUTINE Update_Back_Stress_Chaboche(params, state, i_back, delta_lambda, n)` |
| SUBROUTINE | `Update_Isotropic_Hardening` | 272 | `SUBROUTINE Update_Isotropic_Hardening(params, state, delta_lambda)` |
| SUBROUTINE | `UF_Chaboche_Init` | 287 | `SUBROUTINE UF_Chaboche_Init(Mat, props, nprops, status)` |
| SUBROUTINE | `UF_Chaboche_ComputeYieldFunction` | 354 | `SUBROUTINE UF_Chaboche_ComputeYieldFunction(sigma_dev, alpha_total, sigma_y, &` |
| SUBROUTINE | `UF_Chaboche_UpdateBackStress` | 387 | `SUBROUTINE UF_Chaboche_UpdateBackStress(alpha_old, dlambda, d_eps_p, &` |
| SUBROUTINE | `UF_Chaboche_ComputeTotalBackStress` | 431 | `SUBROUTINE UF_Chaboche_ComputeTotalBackStress(alpha_component, n_components, &` |
| SUBROUTINE | `UF_Chaboche_UMAT` | 452 | `SUBROUTINE UF_Chaboche_UMAT(sigma, statev, ddsdde, sse, spd, scd, rpl, &` |
| SUBROUTINE | `chab_compute_deviatoric_stress` | 641 | `SUBROUTINE chab_compute_deviatoric_stress(stress, s_dev, p_mean, ndir, nshr, ntens)` |
| SUBROUTINE | `chab_build_elastic_stiffness` | 658 | `SUBROUTINE chab_build_elastic_stiffness(lambda, mu, ndim, D_elastic)` |
| SUBROUTINE | `chab_compute_trial_stress` | 698 | `SUBROUTINE chab_compute_trial_stress(stress_old, dstran, D_elastic, &` |
| SUBROUTINE | `chab_normalize_vector` | 723 | `SUBROUTINE chab_normalize_vector(vec, n)` |
| SUBROUTINE | `UF_Chaboche_ComputeStress` | 744 | `SUBROUTINE UF_Chaboche_ComputeStress(Mat, stress, statev, dstran, &` |
| SUBROUTINE | `UF_Chaboche_ComputeTangent` | 791 | `SUBROUTINE UF_Chaboche_ComputeTangent(Mat, stress, alpha_total, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
