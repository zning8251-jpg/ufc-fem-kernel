# `PH_Elem_B31.f90`

- **Source**: `L4_PH/Element/Beam/PH_Elem_B31.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_B31`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_B31`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_B31`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Beam`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Beam/PH_Elem_B31.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_B31_StiffMatrix_Arg` (lines 97–105)

```fortran
  TYPE, PUBLIC :: PH_Elem_B31_StiffMatrix_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    REAL(wp) :: area                   ! Cross-sectional area [m²]                   ! [IN]
    REAL(wp) :: Iy                     ! Bending inertia about local y-axis [m⁴]                   ! [IN]
    REAL(wp) :: Iz                     ! Bending inertia about local z-axis [m⁴]                   ! [IN]
    REAL(wp) :: J_torsion              ! Torsional constant [m⁴]                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B31_StiffMatrix_Arg
```

### `PH_Elem_B31_IntForce_Arg` (lines 120–124)

```fortran
  TYPE, PUBLIC :: PH_Elem_B31_IntForce_Arg
    REAL(wp) :: E_young                ! Young's modulus [Pa]                   ! [IN]
    REAL(wp) :: nu                     ! Poisson's ratio                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B31_IntForce_Arg
```

### `PH_Elem_B31_NL_TL_Arg` (lines 146–153)

```fortran
  TYPE, PUBLIC :: PH_Elem_B31_NL_TL_Arg
    TYPE(MatPropertyDef) :: mat_prop   ! Material properties descriptor                   ! [IN]
    REAL(wp) :: area                   ! Cross-sectional area [m²]                   ! [IN]
    REAL(wp) :: Iy                     ! Bending inertia about y-axis [m⁴]                   ! [IN]
    REAL(wp) :: Iz                     ! Bending inertia about z-axis [m⁴]                   ! [IN]
    INTEGER(i4) :: n_section_pts       ! Number of cross-section Gauss points                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B31_NL_TL_Arg
```

### `PH_Elem_B31_NL_UL_Arg` (lines 175–182)

```fortran
  TYPE, PUBLIC :: PH_Elem_B31_NL_UL_Arg
    TYPE(MatPropertyDef) :: mat_prop   ! Material properties descriptor                   ! [IN]
    REAL(wp) :: area                   ! Cross-sectional area [m²]                   ! [IN]
    REAL(wp) :: Iy                     ! Bending inertia about y-axis [m⁴]                   ! [IN]
    REAL(wp) :: Iz                     ! Bending inertia about z-axis [m⁴]                   ! [IN]
    INTEGER(i4) :: n_section_pts       ! Number of cross-section Gauss points                   ! [IN]
    TYPE(ErrorStatusType) :: status    ! Error status                   ! [OUT]
  END TYPE PH_Elem_B31_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_B31_GetLength` | 192 | `SUBROUTINE PH_Elem_B31_GetLength(coords, length)` |
| SUBROUTINE | `PH_Elem_B31_GetCrossSectionArea` | 203 | `SUBROUTINE PH_Elem_B31_GetCrossSectionArea(sect_area_in, area)` |
| SUBROUTINE | `PH_Elem_B31_GetInertiaIyy` | 214 | `SUBROUTINE PH_Elem_B31_GetInertiaIyy(sect_iyy_in, Iyy)` |
| SUBROUTINE | `PH_Elem_B31_GetInertiaIzz` | 225 | `SUBROUTINE PH_Elem_B31_GetInertiaIzz(sect_izz_in, Izz)` |
| SUBROUTINE | `PH_Elem_B31_GetTorsionJ` | 236 | `SUBROUTINE PH_Elem_B31_GetTorsionJ(sect_j_in, J_torsion)` |
| SUBROUTINE | `PH_Elem_B31_ApplyConstraint` | 251 | `SUBROUTINE PH_Elem_B31_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_B31_FormNodalForce` | 269 | `SUBROUTINE PH_Elem_B31_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_B31_EvalBeamStress` | 333 | `SUBROUTINE PH_Elem_B31_EvalBeamStress(coords, u, sigma, E_young, nu, area, Iy, Iz, J_torsion)` |
| SUBROUTINE | `PH_El_B31_ConsMassWithSectio` | 405 | `SUBROUTINE PH_El_B31_ConsMassWithSectio(coords, rho, area, Me)` |
| SUBROUTINE | `PH_El_B31_FormStiffMatrixWit` | 430 | `SUBROUTINE PH_El_B31_FormStiffMatrixWit(coords, E_young, nu, area, Iy, Iz, J_torsion, Ke)` |
| SUBROUTINE | `PH_El_B31_LumpMassWithSectio` | 522 | `SUBROUTINE PH_El_B31_LumpMassWithSectio(coords, rho, area, M_lumped)` |
| SUBROUTINE | `PH_Elem_B31_ThermStrainVector` | 541 | `SUBROUTINE PH_Elem_B31_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_B31_ConsMass` | 555 | `SUBROUTINE PH_Elem_B31_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_B31_DefInit` | 562 | `SUBROUTINE PH_Elem_B31_DefInit()` |
| SUBROUTINE | `PH_Elem_B31_FormIntForce` | 565 | `SUBROUTINE PH_Elem_B31_FormIntForce(arg)` |
| SUBROUTINE | `PH_Elem_B31_FormIntForce_Legacy` | 594 | `SUBROUTINE PH_Elem_B31_FormIntForce_Legacy(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_B31_FormStiffMatrix` | 604 | `SUBROUTINE PH_Elem_B31_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_B31_LumpMass` | 616 | `SUBROUTINE PH_Elem_B31_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_B31_NL_TL` | 623 | `SUBROUTINE PH_Elem_B31_NL_TL(arg)` |
| SUBROUTINE | `GetGaussPoint1D_TL` | 795 | `SUBROUTINE GetGaussPoint1D_TL(igp, xi, wt)` |
| SUBROUTINE | `GetSectionGaussPoint_TL` | 806 | `SUBROUTINE GetSectionGaussPoint_TL(igp, n_pts, A, Iy_val, Iz_val, y, z, wt)` |
| SUBROUTINE | `PH_Elem_B31_NL_UL` | 830 | `SUBROUTINE PH_Elem_B31_NL_UL(arg)` |
| SUBROUTINE | `GetGaussPoint1D` | 1020 | `SUBROUTINE GetGaussPoint1D(igp, xi, wt)` |
| SUBROUTINE | `GetSectionGaussPoint` | 1032 | `SUBROUTINE GetSectionGaussPoint(igp, n_pts, A, Iy_val, Iz_val, y, z, wt)` |
| SUBROUTINE | `GetGaussPoint2x2` | 1051 | `SUBROUTINE GetGaussPoint2x2(igp, h, b, y, z, wt)` |
| SUBROUTINE | `UF_Elem_B31_Calc` | 1071 | `SUBROUTINE UF_Elem_B31_Calc(ElemType, Formul, Ctx, state_in, Mat, state_out, flags)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
