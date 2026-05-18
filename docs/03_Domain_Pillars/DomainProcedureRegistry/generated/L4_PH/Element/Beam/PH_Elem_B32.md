# `PH_Elem_B32.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B32.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B32`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B32`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B32`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B32.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_B32_StiffMatrix_Arg` (lines 107–115)

```fortran
  TYPE, PUBLIC :: PH_Elem_B32_StiffMatrix_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    REAL(wp) :: area                   ! Cross-sectional area [m²]                   ! [IN]
    REAL(wp) :: Iy                     ! Bending inertia about local y-axis [m⁴]                   ! [IN]
    REAL(wp) :: Iz                     ! Bending inertia about local z-axis [m⁴]                   ! [IN]
    REAL(wp) :: J_torsion              ! Torsional constant [m⁴]                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_StiffMatrix_Arg
```

### `PH_Elem_B32_IntForce_Arg` (lines 130–134)

```fortran
  TYPE, PUBLIC :: PH_Elem_B32_IntForce_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_IntForce_Arg
```

### `PH_Elem_B32_NL_TL_Arg` (lines 140–143)

```fortran
  TYPE, PUBLIC :: PH_Elem_B32_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_NL_TL_Arg
```

### `PH_Elem_B32_NL_UL_Arg` (lines 149–152)

```fortran
  TYPE, PUBLIC :: PH_Elem_B32_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties (Desc)                   ! [IN]
    TYPE(ErrorStatusType) :: status  ! Error status                   ! [OUT]
  END TYPE PH_Elem_B32_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B32_ThermStrainVector` | 157 | `SUBROUTINE PH_Elem_B32_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_B32_GetArea` | 171 | `SUBROUTINE PH_Elem_B32_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_B32_ApplyConstraint` | 186 | `SUBROUTINE PH_Elem_B32_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_B32_FormNodalForce` | 208 | `SUBROUTINE PH_Elem_B32_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_B32_EvalBeamStress` | 225 | `SUBROUTINE PH_Elem_B32_EvalBeamStress(coords, u, sigma, E_young, nu, area, Iy, Iz, J_torsion)` |
| SUBROUTINE | `PH_Elem_B32_ConsMass` | 246 | `SUBROUTINE PH_Elem_B32_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_B32_DefInit` | 261 | `SUBROUTINE PH_Elem_B32_DefInit()` |
| SUBROUTINE | `PH_Elem_B32_FormIntForce` | 268 | `SUBROUTINE PH_Elem_B32_FormIntForce(in, out)` |
| SUBROUTINE | `PH_Elem_B32_FormStiffMatrix_Legacy` | 299 | `SUBROUTINE PH_Elem_B32_FormStiffMatrix_Legacy(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_B32_FormIntForce_Legacy` | 312 | `SUBROUTINE PH_Elem_B32_FormIntForce_Legacy(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_B32_FormStiffMatrix` | 322 | `SUBROUTINE PH_Elem_B32_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_B32_LumpMass` | 422 | `SUBROUTINE PH_Elem_B32_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_B32_NL_TL` | 429 | `SUBROUTINE PH_Elem_B32_NL_TL(arg)` |
| SUBROUTINE | `PH_Elem_B32_NL_UL` | 517 | `SUBROUTINE PH_Elem_B32_NL_UL(arg)` |
| SUBROUTINE | `UF_Elem_B32_Calc` | 608 | `SUBROUTINE UF_Elem_B32_Calc(ElemType, Formul, Ctx, state_in, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
