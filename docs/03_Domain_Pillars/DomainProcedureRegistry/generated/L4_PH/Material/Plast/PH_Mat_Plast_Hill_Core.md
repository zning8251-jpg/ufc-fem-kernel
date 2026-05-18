# `PH_Mat_Plast_Hill_Core.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Plast_Hill_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_Hill_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast_Hill`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_Hill_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `HilMat` (lines 101–120)

```fortran
  TYPE :: HilMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: K = 0.0_wp
    REAL(wp) :: H11 = 0.0_wp
    REAL(wp) :: H22 = 0.0_wp
    REAL(wp) :: H33 = 0.0_wp
    REAL(wp) :: H12 = 0.0_wp
    REAL(wp) :: H23 = 0.0_wp
    REAL(wp) :: H13 = 0.0_wp
    REAL(wp) :: H44 = 0.0_wp
    REAL(wp) :: H55 = 0.0_wp
    REAL(wp) :: H66 = 0.0_wp
    REAL(wp) :: sigma_y0 = 0.0_wp
    REAL(wp) :: H_hardening = 0.0_wp
    REAL(wp) :: n_hardening = 1.0_wp
    LOGICAL :: init = .FALSE.
  END TYPE HilMat
```

### `PH_Hill_Cfg_Elastic` (lines 122–125)

```fortran
  TYPE, PUBLIC :: PH_Hill_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Hill_Cfg_Elastic
```

### `PH_Hill_Cfg_Yield` (lines 127–130)

```fortran
  TYPE, PUBLIC :: PH_Hill_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp  ! Reference direction yield stress
    INTEGER(i4) :: hill_model = 1_i4     ! 1=Hill48, 2=Hill90
  END TYPE PH_Hill_Cfg_Yield
```

### `PH_Hill_Cfg_RValue` (lines 132–136)

```fortran
  TYPE, PUBLIC :: PH_Hill_Cfg_RValue
    REAL(wp) :: R_0 = 0.0_wp
    REAL(wp) :: R_45 = 0.0_wp
    REAL(wp) :: R_90 = 0.0_wp            ! Lankford coefficient (0°, 45°, 90°)
  END TYPE PH_Hill_Cfg_RValue
```

### `PH_Hill_Cfg_HillParam` (lines 138–145)

```fortran
  TYPE, PUBLIC :: PH_Hill_Cfg_HillParam
    REAL(wp) :: F = 0.0_wp
    REAL(wp) :: G = 0.0_wp
    REAL(wp) :: H = 0.0_wp
    REAL(wp) :: L = 0.0_wp
    REAL(wp) :: M = 0.0_wp
    REAL(wp) :: N = 0.0_wp               ! Hill48 anisotropic parameters
  END TYPE PH_Hill_Cfg_HillParam
```

### `PH_Hill_Cfg_Harden` (lines 147–150)

```fortran
  TYPE, PUBLIC :: PH_Hill_Cfg_Harden
    REAL(wp) :: hardening_modulus = 0.0_wp
    REAL(wp) :: hardening_exponent = 1.0_wp
  END TYPE PH_Hill_Cfg_Harden
```

### `Hill_Params` (lines 152–159)

```fortran
  TYPE, PUBLIC :: Hill_Params
    TYPE(PH_Hill_Cfg_Elastic)    :: elastic
    TYPE(PH_Hill_Cfg_Yield)      :: yield
    TYPE(PH_Hill_Cfg_RValue)     :: rvalue
    TYPE(PH_Hill_Cfg_HillParam)  :: hill
    TYPE(PH_Hill_Cfg_Harden)     :: harden
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Hill_Params
```

### `Hill_State` (lines 161–167)

```fortran
  TYPE, PUBLIC :: Hill_State
    REAL(wp), ALLOCATABLE :: stress_current(:)
    REAL(wp), ALLOCATABLE :: strain_plastic(:)
    REAL(wp) :: equiv_plastic_strain = 0.0_wp
    REAL(wp) :: yield_stress_current = 0.0_wp
    LOGICAL  :: is_plastic = .FALSE.
  END TYPE
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Mat_Hill_Init` | 178 | `SUBROUTINE PH_Mat_Hill_Init(params, state)` |
| SUBROUTINE | `PH_Mat_Hill_Compute_Anisotropic_Parameters` | 193 | `SUBROUTINE PH_Mat_Hill_Compute_Anisotropic_Parameters(params)` |
| SUBROUTINE | `PH_Mat_Hill_Calc_Stress` | 218 | `SUBROUTINE PH_Mat_Hill_Calc_Stress(params, state, strain_increment, sigma)` |
| FUNCTION | `Eval_Hill48_Yield` | 243 | `FUNCTION Eval_Hill48_Yield(params, state, sigma) RESULT(f)` |
| SUBROUTINE | `Return_Mapping_Hill48` | 267 | `SUBROUTINE Return_Mapping_Hill48(params, state, stress_trial, sigma)` |
| SUBROUTINE | `Calc_Hill48_Gradient` | 293 | `SUBROUTINE Calc_Hill48_Gradient(params, sigma, df_dsigma)` |
| FUNCTION | `Construct_Elastic_D_Mtx` | 310 | `FUNCTION Construct_Elastic_D_Mtx(params) RESULT(D)` |
| SUBROUTINE | `PH_Hill_Plasticity_Eval` | 323 | `SUBROUTINE PH_Hill_Plasticity_Eval(mat_desc, strain_increment, state, &` |
| SUBROUTINE | `HillPlasticity_UpdateStress` | 380 | `SUBROUTINE HillPlasticity_UpdateStress(in, out)` |
| SUBROUTINE | `UF_Hill_Init` | 440 | `SUBROUTINE UF_Hill_Init(Mat, props, nprops, status)` |
| SUBROUTINE | `UF_Hill_UMAT` | 499 | `SUBROUTINE UF_Hill_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `UF_Hill_ComputeStress` | 550 | `SUBROUTINE UF_Hill_ComputeStress(Mat, stress_old, statev, dstran, &` |
| SUBROUTINE | `UF_Hill_ComputeTangent` | 672 | `SUBROUTINE UF_Hill_ComputeTangent(Mat, stress, statev, &` |
| SUBROUTINE | `hil_BuildElasticStiffness` | 717 | `SUBROUTINE hil_BuildElasticStiffness(PH_MAT_E, nu, D, ndir, nshr, ntens)` |
| SUBROUTINE | `hil_MatComp_Stress` | 750 | `SUBROUTINE hil_MatComp_Stress(D, strain, stress, ndir, nshr, ntens)` |
| SUBROUTINE | `hil_ComputeDeviatoricStress` | 766 | `SUBROUTINE hil_ComputeDeviatoricStress(stress, s_dev, p_mean, ndir, nshr, ntens)` |
| SUBROUTINE | `hil_ComputeHillEquivalentStress` | 798 | `SUBROUTINE hil_ComputeHillEquivalentStress(s_dev, p_mean, H11, H22, H33, &` |
| SUBROUTINE | `hil_ComputeFlowDirection` | 825 | `SUBROUTINE hil_ComputeFlowDirection(s_dev, p_mean, H11, H22, H33, &` |
| SUBROUTINE | `hil_ComputeElastoplasticStiff` | 869 | `SUBROUTINE hil_ComputeElastoplasticStiff(D_elastic, n_flow, hardening_modul, &` |
| SUBROUTINE | `PH_MAT_UMAT_HillPlasticity` | 909 | `SUBROUTINE PH_MAT_UMAT_HillPlasticity(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
