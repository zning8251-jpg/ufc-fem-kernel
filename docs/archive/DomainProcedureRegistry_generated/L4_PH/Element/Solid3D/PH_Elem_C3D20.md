# `PH_Elem_C3D20.f90`

- **Source**: `L4_PH/Element/Solid3D/PH_Elem_C3D20.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D20`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D20`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D20`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3D`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3D/PH_Elem_C3D20.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_C3D20_ShapeFunc_Algo` (lines 152–156)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_Algo
    REAL(wp) :: xi  ! Natural coordinate ? ? [-1, 1]
    REAL(wp) :: eta  ! Natural coordinate ? ? [-1, 1]
    REAL(wp) :: zeta  ! Natural coordinate ? ? [-1, 1]
  END TYPE PH_Elem_C3D20_ShapeFunc_Algo
```

### `PH_Elem_C3D20_ShapeFunc_State` (lines 159–162)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_State
    REAL(wp) :: N(20)  ! Shape functions N_i(?,?,?)
    REAL(wp) :: dNdxi(3, 20)  ! Shape function derivatives ?N_i/??_j
  END TYPE PH_Elem_C3D20_ShapeFunc_State
```

### `PH_Elem_C3D20_ShapeFunc_Arg` (lines 167–171)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_ShapeFunc_Arg
    TYPE(PH_Elem_C3D20_ShapeFunc_Algo) :: algo                   ! [IN]
    TYPE(PH_Elem_C3D20_ShapeFunc_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_ShapeFunc_Arg
```

### `PH_Elem_C3D20_Jac_Desc` (lines 179–181)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates x_i
  END TYPE PH_Elem_C3D20_Jac_Desc
```

### `PH_Elem_C3D20_Jac_State` (lines 184–188)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_State
    REAL(wp) :: dNdxi(3, 20)  ! Shape function derivatives ?N/?? (input)
    REAL(wp) :: J(3, 3)  ! Jacobian matrix J = ?x/??
    REAL(wp) :: detJ  ! Jacobian determinant |J|
  END TYPE PH_Elem_C3D20_Jac_State
```

### `PH_Elem_C3D20_Jac_Arg` (lines 193–197)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Jac_Arg
    TYPE(PH_Elem_C3D20_Jac_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_Jac_State) :: state  ! Contains dNdxi as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Jac_Arg
```

### `PH_Elem_C3D20_BMatrix_State` (lines 205–208)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_BMatrix_State
    REAL(wp) :: dNdx(3, 20)  ! Shape function derivatives ?N/?x (input)
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix (output)
  END TYPE PH_Elem_C3D20_BMatrix_State
```

### `PH_Elem_C3D20_BMatrix_Arg` (lines 213–216)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_BMatrix_Arg
    TYPE(PH_Elem_C3D20_BMatrix_State) :: state  ! Contains dNdx as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_BMatrix_Arg
```

### `PH_Elem_C3D20_JacB_Desc` (lines 224–226)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates x_i
  END TYPE PH_Elem_C3D20_JacB_Desc
```

### `PH_Elem_C3D20_JacB_Algo` (lines 229–233)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Algo
    REAL(wp) :: xi  ! Natural coordinate ?
    REAL(wp) :: eta  ! Natural coordinate ?
    REAL(wp) :: zeta  ! Natural coordinate ?
  END TYPE PH_Elem_C3D20_JacB_Algo
```

### `PH_Elem_C3D20_JacB_State` (lines 236–242)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_State
    REAL(wp) :: N(20)  ! Shape functions
    REAL(wp) :: dNdx(3, 20)  ! Shape function derivatives ?N/?x
    REAL(wp) :: J(3, 3)  ! Jacobian matrix
    REAL(wp) :: detJ  ! Jacobian determinant
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix
  END TYPE PH_Elem_C3D20_JacB_State
```

### `PH_Elem_C3D20_JacB_Arg` (lines 247–252)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_JacB_Arg
    TYPE(PH_Elem_C3D20_JacB_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_JacB_Algo) :: algo                   ! [IN]
    TYPE(PH_Elem_C3D20_JacB_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_JacB_Arg
```

### `PH_Elem_C3D20_Strain_State` (lines 260–264)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Strain_State
    REAL(wp) :: B(6, 60)  ! Strain-displacement matrix (input)
    REAL(wp) :: u(60)  ! Displacement vector (input)
    REAL(wp) :: strain(6)  ! Strain vector [?xx, ?yy, ?zz, ?xy, ?yz, ?zx]^T (output)
  END TYPE PH_Elem_C3D20_Strain_State
```

### `PH_Elem_C3D20_Strain_Arg` (lines 269–272)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Strain_Arg
    TYPE(PH_Elem_C3D20_Strain_State) :: state  ! Contains B and u as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Strain_Arg
```

### `PH_Elem_C3D20_Stress_Desc` (lines 280–282)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_Desc
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_Stress_Desc
```

### `PH_Elem_C3D20_Stress_State` (lines 285–289)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_State
    REAL(wp) :: epsilon(6)  ! Strain vector (input)
    REAL(wp) :: sigma(6)  ! Stress vector [?xx, ?yy, ?zz, ?xy, ?yz, ?zx]^T (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_Stress_State
```

### `PH_Elem_C3D20_Stress_Arg` (lines 294–298)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_Stress_Arg
    TYPE(PH_Elem_C3D20_Stress_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_Stress_State) :: state  ! Contains epsilon and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_Stress_Arg
```

### `PH_Elem_C3D20_StiffMatrix_Desc` (lines 306–309)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_StiffMatrix_Desc
```

### `PH_Elem_C3D20_StiffMatrix_State` (lines 312–314)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_State
    REAL(wp) :: Ke(60, 60)  ! Element stiffness matrix K = ? B^TDB dV
  END TYPE PH_Elem_C3D20_StiffMatrix_State
```

### `PH_Elem_C3D20_StiffMatrix_Arg` (lines 319–323)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_StiffMatrix_Arg
    TYPE(PH_Elem_C3D20_StiffMatrix_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_StiffMatrix_State) :: state                   ! [OUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_StiffMatrix_Arg
```

### `PH_Elem_C3D20_IntForce_Desc` (lines 331–334)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_Desc
    REAL(wp) :: coords(3, 20)  ! Node coordinates
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_IntForce_Desc
```

### `PH_Elem_C3D20_IntForce_State` (lines 337–341)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_State
    REAL(wp) :: u(60)  ! Displacement vector (input)
    REAL(wp) :: R_int(60)  ! Internal force vector R = ? B^T? dV (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_IntForce_State
```

### `PH_Elem_C3D20_IntForce_Arg` (lines 346–350)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_IntForce_Arg
    TYPE(PH_Elem_C3D20_IntForce_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_IntForce_State) :: state  ! Contains u and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_IntForce_Arg
```

### `PH_Elem_C3D20_NL_TL_Desc` (lines 358–361)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_Desc
    REAL(wp) :: coords_ref(3, 20)  ! Reference coordinates X
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_NL_TL_Desc
```

### `PH_Elem_C3D20_NL_TL_State` (lines 364–370)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_State
    REAL(wp) :: u_elem(60)  ! Displacement vector u (input)
    REAL(wp) :: Ke_mat(60, 60)  ! Material stiffness matrix K_mat (output)
    REAL(wp) :: Ke_geo(60, 60)  ! Geometric stiffness matrix K_geo (output)
    REAL(wp) :: R_int(60)  ! Internal force vector R_int (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_NL_TL_State
```

### `PH_Elem_C3D20_NL_TL_Arg` (lines 375–379)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_TL_Arg
    TYPE(PH_Elem_C3D20_NL_TL_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_NL_TL_State) :: state  ! Contains u_elem and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_NL_TL_Arg
```

### `PH_Elem_C3D20_NL_UL_Desc` (lines 387–390)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_Desc
    REAL(wp) :: coords_prev(3, 20)  ! Previous coordinates x_n
    TYPE(MatPropertyDef) :: mat_prop  ! Material properties
  END TYPE PH_Elem_C3D20_NL_UL_Desc
```

### `PH_Elem_C3D20_NL_UL_State` (lines 393–399)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_State
    REAL(wp) :: u_incr(60)  ! Incremental displacement ?u (input)
    REAL(wp) :: Ke_mat(60, 60)  ! Material stiffness matrix K_mat (output)
    REAL(wp) :: Ke_geo(60, 60)  ! Geometric stiffness matrix K_geo (output)
    REAL(wp) :: R_int(60)  ! Internal force vector R_int (output)
    TYPE(PH_MatPoint_State), ALLOCATABLE :: mat_state(:)  ! Material state per GP
  END TYPE PH_Elem_C3D20_NL_UL_State
```

### `PH_Elem_C3D20_NL_UL_Arg` (lines 404–408)

```fortran
  TYPE, PUBLIC :: PH_Elem_C3D20_NL_UL_Arg
    TYPE(PH_Elem_C3D20_NL_UL_Desc) :: desc                   ! [IN]
    TYPE(PH_Elem_C3D20_NL_UL_State) :: state  ! Contains u_incr and mat_state as input                   ! [INOUT]
    TYPE(ErrorStatusType) :: status                   ! [OUT]
  END TYPE PH_Elem_C3D20_NL_UL_Arg
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_ELEM_C3D20_BEnhanced` | 413 | `SUBROUTINE PH_ELEM_C3D20_BEnhanced(dN_xi, dN_eta, dN_zeta, J_inv, B_enh)` |
| SUBROUTINE | `PH_ELEM_C3D20_IncompatibleShapeFunc` | 435 | `SUBROUTINE PH_ELEM_C3D20_IncompatibleShapeFunc(xi, eta, zeta, N_enh, dN_xi, dN_eta, dN_zeta)` |
| SUBROUTINE | `PH_ELEM_C3D20_Inv3x3` | 456 | `SUBROUTINE PH_ELEM_C3D20_Inv3x3(A, Ainv, detA)` |
| SUBROUTINE | `PH_ELEM_C3D20_Volume_27pt` | 486 | `SUBROUTINE PH_ELEM_C3D20_Volume_27pt(coords, volume)` |
| SUBROUTINE | `PH_El_C3_FormIntForceByVaria` | 501 | `SUBROUTINE PH_El_C3_FormIntForceByVaria(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_El_C3_FormStiffMatrixByVa` | 511 | `SUBROUTINE PH_El_C3_FormStiffMatrixByVa(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_El_C3_GaussPointsReduced` | 520 | `SUBROUTINE PH_El_C3_GaussPointsReduced(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_El_C3_IntForceByVariant` | 542 | `SUBROUTINE PH_El_C3_IntForceByVariant(coords, u, E_young, nu, variant, R_int)` |
| SUBROUTINE | `PH_El_C3_IntForceIncompatibl` | 562 | `SUBROUTINE PH_El_C3_IntForceIncompatibl(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_El_C3_IntForceReduced` | 573 | `SUBROUTINE PH_El_C3_IntForceReduced(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_El_C3_IntForceSelective` | 582 | `SUBROUTINE PH_El_C3_IntForceSelective(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_El_C3_LumpMassReduced` | 626 | `SUBROUTINE PH_El_C3_LumpMassReduced(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixByVarian` | 633 | `SUBROUTINE PH_El_C3_StiffMatrixByVarian(coords, E_young, nu, variant, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixIncompat` | 652 | `SUBROUTINE PH_El_C3_StiffMatrixIncompat(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixReduced` | 699 | `SUBROUTINE PH_El_C3_StiffMatrixReduced(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_StiffMatrixSelectiv` | 707 | `SUBROUTINE PH_El_C3_StiffMatrixSelectiv(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_El_C3_ThermStrainVector` | 749 | `SUBROUTINE PH_El_C3_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_C3D20_BMatrix` | 757 | `SUBROUTINE PH_Elem_C3D20_BMatrix(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_ConsMass` | 782 | `SUBROUTINE PH_Elem_C3D20_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D20_ConstMatrix` | 810 | `SUBROUTINE PH_Elem_C3D20_ConstMatrix(E_young, nu, D)` |
| SUBROUTINE | `PH_Elem_C3D20_DefInit` | 834 | `SUBROUTINE PH_Elem_C3D20_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D20_FormGeomStiff` | 838 | `SUBROUTINE PH_Elem_C3D20_FormGeomStiff(coords, sigma, Kg)` |
| SUBROUTINE | `PH_Elem_C3D20_FormIntForce` | 884 | `SUBROUTINE PH_Elem_C3D20_FormIntForce(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_FormStiffMatrix` | 943 | `SUBROUTINE PH_Elem_C3D20_FormStiffMatrix(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_GaussPoints` | 992 | `SUBROUTINE PH_Elem_C3D20_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D20_GaussPoints27` | 1009 | `SUBROUTINE PH_Elem_C3D20_GaussPoints27(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D20_IntForce` | 1026 | `SUBROUTINE PH_Elem_C3D20_IntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D20_FormIntForceFromStress` | 1051 | `SUBROUTINE PH_Elem_C3D20_FormIntForceFromStress(coords, sigma6, R_int)` |
| SUBROUTINE | `PH_Elem_C3D20_IntForce27` | 1069 | `SUBROUTINE PH_Elem_C3D20_IntForce27(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_C3D20_Jac_Scalar` | 1093 | `SUBROUTINE PH_Elem_C3D20_Jac_Scalar(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D20_Jac_Struct` | 1106 | `SUBROUTINE PH_Elem_C3D20_Jac_Struct(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_JacB_Scalar` | 1143 | `SUBROUTINE PH_Elem_C3D20_JacB_Scalar(coords, xi_pt, eta_pt, zeta_pt, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D20_JacB_Struct` | 1164 | `SUBROUTINE PH_Elem_C3D20_JacB_Struct(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_LumpMass` | 1244 | `SUBROUTINE PH_Elem_C3D20_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D20_LumpMass27` | 1269 | `SUBROUTINE PH_Elem_C3D20_LumpMass27(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D20_NL_TL` | 1292 | `SUBROUTINE PH_Elem_C3D20_NL_TL(coords_ref, u_elem, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D20_NL_UL` | 1499 | `SUBROUTINE PH_Elem_C3D20_NL_UL(coords_prev, u_incr, mat_prop, mat_state, Ke_mat, Ke_geo, R_int, status, variant)` |
| SUBROUTINE | `PH_Elem_C3D20_ShapeFunc_Scalar` | 1724 | `SUBROUTINE PH_Elem_C3D20_ShapeFunc_Scalar(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D20_ShapeFunc_Struct` | 1737 | `SUBROUTINE PH_Elem_C3D20_ShapeFunc_Struct(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_StiffMatrix` | 1828 | `SUBROUTINE PH_Elem_C3D20_StiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D20_StiffMatrixFromD` | 1853 | `SUBROUTINE PH_Elem_C3D20_StiffMatrixFromD(coords, D6, Ke)` |
| SUBROUTINE | `PH_Elem_C3D20_StiffMatrix27` | 1874 | `SUBROUTINE PH_Elem_C3D20_StiffMatrix27(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_C3D20_Strain` | 1895 | `SUBROUTINE PH_Elem_C3D20_Strain(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_Stress` | 1906 | `SUBROUTINE PH_Elem_C3D20_Stress(arg)` |
| SUBROUTINE | `PH_Elem_C3D20_Volume27` | 1939 | `SUBROUTINE PH_Elem_C3D20_Volume27(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D20_GetCentroid` | 1955 | `SUBROUTINE PH_Elem_C3D20_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D20_GetInertiaOrig` | 1983 | `SUBROUTINE PH_Elem_C3D20_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D20_GetSectProps` | 2015 | `SUBROUTINE PH_Elem_C3D20_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D20_GetVolume` | 2024 | `SUBROUTINE PH_Elem_C3D20_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D20_ApplyConstraint` | 2040 | `SUBROUTINE PH_Elem_C3D20_ApplyConstraint(ctype, idof, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D20_ApplyMPC` | 2053 | `SUBROUTINE PH_Elem_C3D20_ApplyMPC(c, val, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D20_FormContactContrib` | 2069 | `SUBROUTINE PH_Elem_C3D20_FormContactContrib(face_id, xi, eta, zeta, N, n, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D20_FormContactFaceCtr` | 2107 | `SUBROUTINE PH_Elem_C3D20_FormContactFaceCtr(face_id, coords, gap, penalty, K_el, F_el)` |
| SUBROUTINE | `PH_Elem_C3D20_FormFacePressure` | 2244 | `SUBROUTINE PH_Elem_C3D20_FormFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D20_FormBodyForce` | 2424 | `SUBROUTINE PH_Elem_C3D20_FormBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D20_FormNodalForce` | 2445 | `SUBROUTINE PH_Elem_C3D20_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `invert_20x20` | 2460 | `SUBROUTINE invert_20x20(A, Ainv, info)` |
| SUBROUTINE | `PH_Elem_C3D20_EvalPrincStress` | 2490 | `SUBROUTINE PH_Elem_C3D20_EvalPrincStress(sigma, principal)` |
| SUBROUTINE | `PH_Elem_C3D20_EvalStrainInvar` | 2544 | `SUBROUTINE PH_Elem_C3D20_EvalStrainInvar(strain, I1e, J2e)` |
| SUBROUTINE | `PH_Elem_C3D20_EvalStressInvar` | 2556 | `SUBROUTINE PH_Elem_C3D20_EvalStressInvar(sigma, I1, J2, J3)` |
| SUBROUTINE | `PH_Elem_C3D20_EvalTriaxiality` | 2580 | `SUBROUTINE PH_Elem_C3D20_EvalTriaxiality(sigma, triax)` |
| SUBROUTINE | `PH_Elem_C3D20_CollectIPVars` | 2594 | `SUBROUTINE PH_Elem_C3D20_CollectIPVars(ip_stress, ip_strain, ip_peeq, n_ip, out_vars)` |
| SUBROUTINE | `PH_Elem_C3D20_EvalVonMises` | 2616 | `SUBROUTINE PH_Elem_C3D20_EvalVonMises(sigma, seq)` |
| SUBROUTINE | `PH_Elem_C3D20_GetExtrapMat` | 2629 | `SUBROUTINE PH_Elem_C3D20_GetExtrapMat(E)` |
| SUBROUTINE | `PH_Elem_C3D20_MapToNode` | 2653 | `SUBROUTINE PH_Elem_C3D20_MapToNode(ip_vars, weights, node_vars)` |
| SUBROUTINE | `PH_Elem_C3D20_Material_Update_Routed` | 2672 | `SUBROUTINE PH_Elem_C3D20_Material_Update_Routed(rt_ctx, mat_slot, dStrain, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

| Lines | Header |
|-------|--------|
| 1137–1140 | `INTERFACE PH_Elem_C3D20_Jac` |
| 1239–1242 | `INTERFACE PH_Elem_C3D20_JacB` |
| 1718–1721 | `INTERFACE PH_Elem_C3D20_ShapeFunc` |
