# `PH_Mat_Plast_Barlat_Core.f90`

- **Source**: `L4_PH/Material/Plast/PH_Mat_Plast_Barlat_Core.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Mat_Plast_Barlat_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Mat_Plast_Barlat_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Mat_Plast_Barlat`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Material/Plast`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Material/Plast/PH_Mat_Plast_Barlat_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Barl_Cfg_Elastic` (lines 65–68)

```fortran
  TYPE, PUBLIC :: PH_Barl_Cfg_Elastic
    REAL(wp) :: E_modulus = 0.0_wp
    REAL(wp) :: nu_poisson = 0.0_wp
  END TYPE PH_Barl_Cfg_Elastic
```

### `PH_Barl_Cfg_Yield` (lines 70–72)

```fortran
  TYPE, PUBLIC :: PH_Barl_Cfg_Yield
    REAL(wp) :: yield_stress_0 = 0.0_wp
  END TYPE PH_Barl_Cfg_Yield
```

### `PH_Barl_Cfg_Model` (lines 74–77)

```fortran
  TYPE, PUBLIC :: PH_Barl_Cfg_Model
    INTEGER(i4) :: barlat_model = 1_i4 ! 1=Yld89, 2=Yld2000-2d, 3=Yld2004-18p
    INTEGER(i4) :: exponent_m = 2_i4   ! Yield exponent
  END TYPE PH_Barl_Cfg_Model
```

### `PH_Barl_Cfg_Params` (lines 79–82)

```fortran
  TYPE, PUBLIC :: PH_Barl_Cfg_Params
    REAL(wp) :: alpha(8) = 0.0_wp    ! Yld2000-2d 8 parameters
    REAL(wp) :: C_tensor(18) = 0.0_wp ! Yld2004-18p parameter
  END TYPE PH_Barl_Cfg_Params
```

### `PH_Barl_Cfg_Harden` (lines 84–86)

```fortran
  TYPE, PUBLIC :: PH_Barl_Cfg_Harden
    REAL(wp) :: hardening_modulus = 0.0_wp
  END TYPE PH_Barl_Cfg_Harden
```

### `Barlat_Params` (lines 88–95)

```fortran
  TYPE, PUBLIC :: Barlat_Params
    TYPE(PH_Barl_Cfg_Elastic) :: elastic
    TYPE(PH_Barl_Cfg_Yield)   :: yield
    TYPE(PH_Barl_Cfg_Model)   :: model
    TYPE(PH_Barl_Cfg_Params)  :: param
    TYPE(PH_Barl_Cfg_Harden)  :: harden
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE Barlat_Params
```

### `Barlat_State` (lines 97–103)

```fortran
  TYPE, PUBLIC :: Barlat_State
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
| SUBROUTINE | `PH_Mat_Barlat_Init` | 109 | `SUBROUTINE PH_Mat_Barlat_Init(params, state)` |
| SUBROUTINE | `PH_Mat_Barlat_Calc_Stress` | 120 | `SUBROUTINE PH_Mat_Barlat_Calc_Stress(params, state, strain_increment, sigma)` |
| FUNCTION | `Eval_Yld2000_2d` | 152 | `FUNCTION Eval_Yld2000_2d(params, state, sigma) RESULT(f)` |
| SUBROUTINE | `Transform_Lin_Yld2000` | 174 | `SUBROUTINE Transform_Lin_Yld2000(params, sigma, s_prime)` |
| FUNCTION | `Eval_Yld89` | 196 | `FUNCTION Eval_Yld89(params, state, sigma) RESULT(f)` |
| FUNCTION | `Eval_Yld2004_18p` | 204 | `FUNCTION Eval_Yld2004_18p(params, state, sigma) RESULT(f)` |
| SUBROUTINE | `Return_Mapping_Barlat` | 212 | `SUBROUTINE Return_Mapping_Barlat(params, state, stress_trial, sigma)` |
| SUBROUTINE | `Calc_Principal_2D` | 224 | `SUBROUTINE Calc_Principal_2D(stress_2d, phi1, phi2)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
