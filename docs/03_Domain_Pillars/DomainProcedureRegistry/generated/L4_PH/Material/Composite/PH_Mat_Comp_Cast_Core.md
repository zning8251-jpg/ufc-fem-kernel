# `PH_Mat_Comp_Cast_Core.f90`

- **Source**: `L4_PH/Material/Composite/PH_Mat_Comp_Cast_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Comp_Cast_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Comp_Cast_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Comp_Cast`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Composite`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Composite/PH_Mat_Comp_Cast_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `TDepPlasticProps` (lines 21–27)

```fortran
  TYPE :: TDepPlasticProps
    LOGICAL :: enabled = .FALSE.
    REAL(wp) :: T_ref = 0.0_wp
    REAL(wp) :: dE_dT = 0.0_wp
    REAL(wp) :: dNu_dT = 0.0_wp
    REAL(wp) :: dsigmaY_dT = 0.0_wp
  END TYPE TDepPlasticProps
```

### `CastIronMat` (lines 52–65)

```fortran
  TYPE :: CastIronMat
    TYPE(PlastMatBase) :: base
    REAL(wp) :: PH_MAT_E = 0.0_wp
    REAL(wp) :: nu = 0.0_wp
    REAL(wp) :: sigma_t0 = 0.0_wp
    REAL(wp) :: sigma_c0 = 0.0_wp
    REAL(wp) :: H_t = 0.0_wp
    REAL(wp) :: H_c = 0.0_wp
    REAL(wp) :: damage_t_param = 0.0_wp
    REAL(wp) :: damage_c_param = 0.0_wp
    TYPE(TDepPlasticProps) :: temp_props
    LOGICAL :: temp_dependent = .FALSE.
    LOGICAL :: init = .FALSE.
  END TYPE CastIronMat
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `UF_Plastic_InitTDep` | 74 | `SUBROUTINE UF_Plastic_InitTDep(props, nprops, temp_props, status)` |
| SUBROUTINE | `ci_solve_linear_2x2` | 84 | `SUBROUTINE ci_solve_linear_2x2(A, b, x, status)` |
| SUBROUTINE | `UF_CastIron_Init` | 105 | `SUBROUTINE UF_CastIron_Init(Mat, props, nprops, status)` |
| SUBROUTINE | `UF_CastIron_ValidateProps` | 134 | `SUBROUTINE UF_CastIron_ValidateProps(props, nprops, status)` |
| SUBROUTINE | `UF_CastIron_ComputePrincStresses` | 169 | `SUBROUTINE UF_CastIron_ComputePrincStresses(stress, ndim, sigma_principal, sigma_max, sigma_min, status)` |
| SUBROUTINE | `UF_CastIron_ComputeYieldFunction` | 222 | `SUBROUTINE UF_CastIron_ComputeYieldFunction(Mat, sigma_max, sigma_min, eps_p_t, eps_p_c, &` |
| SUBROUTINE | `UF_CastIron_ReturnMapping` | 237 | `SUBROUTINE UF_CastIron_ReturnMapping(Mat, stress_trial, sigma_max_trial, sigma_min_trial, &` |
| SUBROUTINE | `UF_CastIron_ComputeTangent` | 353 | `SUBROUTINE UF_CastIron_ComputeTangent(Mat, stress, sigma_max, sigma_min, yield_type, delta_lambda, &` |
| SUBROUTINE | `UF_CastIron_UMAT` | 378 | `SUBROUTINE UF_CastIron_UMAT(sigma, statev, ddsdde, sse, spd, scd, &` |
| SUBROUTINE | `CastIronPlastic_UpdateStress` | 476 | `SUBROUTINE CastIronPlastic_UpdateStress(in, out)` |
| SUBROUTINE | `PH_MAT_UMAT_CastIronPlastic` | 604 | `SUBROUTINE PH_MAT_UMAT_CastIronPlastic(ctx, status)` |
| SUBROUTINE | `PH_Mat_PLM_CastIronic_Update` | 615 | `SUBROUTINE PH_Mat_PLM_CastIronic_Update(ctx, status)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
