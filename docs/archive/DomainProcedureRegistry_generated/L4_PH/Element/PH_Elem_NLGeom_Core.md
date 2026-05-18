# `PH_Elem_NLGeom_Core.f90`

- **Source**: `L4_PH/Element/PH_Elem_NLGeom_Core.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_NLGeom_Core`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_NLGeom_Core`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_NLGeom`
- **第四段角色（四段式）**: `_Core`
- **源码子路径（层下目录，不含文件名）**: `Element`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/PH_Elem_NLGeom_Core.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_NLGeom_Cfg_Frame` (lines 48–51)

```fortran
  TYPE, PUBLIC :: PH_NLGeom_Cfg_Frame
    INTEGER(i4) :: frame = PH_ELEM_NLGEOM_TL  ! TL/UL/NONE current frame
    LOGICAL     :: large_strain = .TRUE.       ! 大应变标志
  END TYPE PH_NLGeom_Cfg_Frame
```

### `PH_NLGeom_Itr_Kinematics` (lines 53–59)

```fortran
  TYPE, PUBLIC :: PH_NLGeom_Itr_Kinematics
    REAL(wp) :: F(3,3)    = 0.0_wp   ! 变形梯度
    REAL(wp) :: Finv(3,3) = 0.0_wp   ! F的逆
    REAL(wp) :: detF      = 1.0_wp   ! det(F) = J
    REAL(wp) :: C_rg(3,3) = 0.0_wp   ! Right Cauchy-Green C = F^TF
    REAL(wp) :: b_lg(3,3) = 0.0_wp   ! Left Cauchy-Green b = FF^T
  END TYPE PH_NLGeom_Itr_Kinematics
```

### `PH_NLGeom_Itr_Strain` (lines 61–64)

```fortran
  TYPE, PUBLIC :: PH_NLGeom_Itr_Strain
    REAL(wp) :: E_gl(6)  = 0.0_wp   ! Green-Lagrange strain (Voigt)
    REAL(wp) :: e_alm(6) = 0.0_wp   ! Almansi strain (Voigt)
  END TYPE PH_NLGeom_Itr_Strain
```

### `PH_NLGeom_State` (lines 71–76)

```fortran
  TYPE, PUBLIC :: PH_NLGeom_State
    TYPE(PH_NLGeom_Cfg_Frame)      :: cfg_frame
    TYPE(PH_NLGeom_Itr_Kinematics) :: itr_kinematics
    TYPE(PH_NLGeom_Itr_Strain)     :: itr_strain
    ! All flat fields migrated to nested auxiliary TYPEs (Depth 2 cap)
  END TYPE PH_NLGeom_State
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_NLGeom_DeformGrad` | 85 | `SUBROUTINE PH_NLGeom_DeformGrad(state, coords_ref, coords_cur, &` |
| SUBROUTINE | `PH_NLGeom_GreenLagrange` | 151 | `SUBROUTINE PH_NLGeom_GreenLagrange(state, status)` |
| SUBROUTINE | `PH_NLGeom_Almansi` | 186 | `SUBROUTINE PH_NLGeom_Almansi(state, status)` |
| SUBROUTINE | `PH_NLGeom_StressPush` | 227 | `SUBROUTINE PH_NLGeom_StressPush(state, S_voigt, sigma_voigt, status)` |
| SUBROUTINE | `PH_NLGeom_StressPull` | 277 | `SUBROUTINE PH_NLGeom_StressPull(state, sigma_voigt, S_voigt, status)` |
| SUBROUTINE | `PH_NLGeom_GeoStiff` | 322 | `SUBROUTINE PH_NLGeom_GeoStiff(sigma_voigt, dN_dx, n_nodes, w_detJ, Kg, status)` |
| SUBROUTINE | `PH_NLGeom_SelectFrame` | 373 | `SUBROUTINE PH_NLGeom_SelectFrame(state, nlgeom_type, status)` |
| SUBROUTINE | `PH_NLGeom_TangentPush` | 422 | `SUBROUTINE PH_NLGeom_TangentPush(state, C_mat, c_spatial, status)` |
| SUBROUTINE | `Invert3x3` | 513 | `SUBROUTINE Invert3x3(A, Ainv, status)` |
| SUBROUTINE | `Voigt_to_Tensor` | 552 | `SUBROUTINE Voigt_to_Tensor(v, T)` |
| SUBROUTINE | `Tensor_to_Voigt` | 566 | `SUBROUTINE Tensor_to_Voigt(T, v)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
