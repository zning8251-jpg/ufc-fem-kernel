# `PH_Elem_CAX6T.f90`

- **Source**: `L4_PH/Element/Solid2Dt/PH_Elem_CAX6T.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_CAX6T`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_CAX6T`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_CAX6T`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid2Dt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid2Dt/PH_Elem_CAX6T.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_Elem_Sld2DT_Args` (lines 50–92)

```fortran
  TYPE :: PH_Elem_Sld2DT_Args
  ! Purpose: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !          ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  ! FormBodyForce/FormNodalForce/CollectIPVars
  ! Theory: Standard FE weak form and B-matrix; Zienkiewicz & Taylor; Bathe FE Procedures.
  ! Status: INTF-001 Progressive Refactoring
  INTEGER(i4)           :: n_node      = 0_i4  ! nodes per element
  INTEGER(i4)           :: n_dof       = 0_i4  ! DoFs per element
  INTEGER(i4)           :: n_ip        = 0_i4  ! integration points per element
  INTEGER(i4)           :: load_type   = 0_i4  ! load kind / case id
  INTEGER(i4)           :: ctype       = 0_i4  ! constraint or cell type code
  INTEGER(i4)           :: face_id     = 0_i4  ! face / surface id
  INTEGER(i4)           :: idof        = 0_i4  ! local DoF index
  REAL(wp)              :: xi          = 0.0_wp  ! parametric coordinate xi
  REAL(wp)              :: eta         = 0.0_wp
  REAL(wp)              :: zeta        = 0.0_wp
  REAL(wp)              :: detJ        = 0.0_wp ! Jacobian
  REAL(wp)              :: penalty     = 0.0_wp  ! penalty factor
  REAL(wp)              :: val         = 0.0_wp  ! prescribed scalar value
  REAL(wp)              :: bx          = 0.0_wp  ! grid index x (hash)
  REAL(wp)              :: by          = 0.0_wp  ! grid index y (hash)
  REAL(wp)              :: bz          = 0.0_wp  ! grid index z (hash)
  REAL(wp), POINTER     :: coords(:,:) => NULL() ! (3,n_node)
  REAL(wp), POINTER     :: u_elem(:)   => NULL()  ! element displacement vector ptr
  REAL(wp), POINTER     :: D(:,:)      => NULL()  ! material stiffness (elasticity) matrix ptr
  REAL(wp), POINTER     :: Ke(:,:)     => NULL()  ! element stiffness matrix ptr
  REAL(wp), POINTER     :: F_eq(:)     => NULL()  ! equivalent nodal force ptr
  REAL(wp), POINTER     :: N(:)        => NULL()  ! shape-function matrix ptr
  REAL(wp), POINTER     :: dNdx(:,:)   => NULL()  ! shape-function spatial derivatives ptr
  REAL(wp), POINTER     :: B(:,:)      => NULL()  ! strain-displacement operator ptr
  REAL(wp), POINTER     :: Ke_geo(:,:) => NULL()  ! geometric stiffness contribution ptr
  REAL(wp), POINTER     :: R_int(:)    => NULL()  ! internal residual ptr
  REAL(wp), POINTER     :: ip_stress(:,:) => NULL()  ! IP stress pack ptr
  REAL(wp), POINTER     :: ip_strain(:,:) => NULL()  ! IP strain pack ptr
  REAL(wp), POINTER     :: ip_peeq(:)  => NULL()  ! IP equivalent plastic strain ptr
  REAL(wp), POINTER     :: out_vars(:,:) => NULL()  ! output variable mask / ids ptr
  REAL(wp)              :: k_therm     = 0.0_wp  ! thermal conductivity scale
  REAL(wp)              :: rho_cp      = 0.0_wp  ! density times heat capacity
  REAL(wp), POINTER     :: T_elem(:)   => NULL()  ! element temperature vector ptr
  REAL(wp), POINTER     :: Ktherm(:,:) => NULL()  ! thermal-thermal block ptr
  REAL(wp), POINTER     :: F_heat(:)   => NULL()  ! thermal force / heat flux load ptr
  REAL(wp), POINTER     :: ip_temp(:)  => NULL()  ! IP temperature ptr
  END TYPE PH_Elem_Sld2DT_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_CAX6T_ThermStrainAxisym` | 97 | `SUBROUTINE PH_Elem_CAX6T_ThermStrainAxisym(T, T_ref, alpha, strain_th)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormStiffMatrix` | 108 | `SUBROUTINE PH_Elem_CAX6T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormCouplingStiffness` | 142 | `SUBROUTINE PH_Elem_CAX6T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormThermalStiffness` | 171 | `SUBROUTINE PH_Elem_CAX6T_FormThermalStiffness(coords, k_thermal, Ke_tt)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormIntForce` | 189 | `SUBROUTINE PH_Elem_CAX6T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)` |
| SUBROUTINE | `PH_Elem_CAX6T_DefInit` | 228 | `SUBROUTINE PH_Elem_CAX6T_DefInit()` |
| SUBROUTINE | `PH_Elem_CAX6T_GaussPoints` | 231 | `SUBROUTINE PH_Elem_CAX6T_GaussPoints(xi, eta, weights)` |
| SUBROUTINE | `PH_Elem_CAX6T_Jac` | 236 | `SUBROUTINE PH_Elem_CAX6T_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_CAX6T_JacB` | 242 | `SUBROUTINE PH_Elem_CAX6T_JacB(coords, xi_pt, eta_pt, N, dNdx, J, detJ, r_pt, B)` |
| SUBROUTINE | `PH_Elem_CAX6T_ShapeFunc` | 249 | `SUBROUTINE PH_Elem_CAX6T_ShapeFunc(xi, eta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_CAX6T_ConsMass` | 255 | `SUBROUTINE PH_Elem_CAX6T_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_CAX6T_LumpMass` | 263 | `SUBROUTINE PH_Elem_CAX6T_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_CAX6T_GetArea` | 271 | `SUBROUTINE PH_Elem_CAX6T_GetArea(coords, area)` |
| SUBROUTINE | `PH_Elem_CAX6T_GetVolume` | 277 | `SUBROUTINE PH_Elem_CAX6T_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_CAX6T_GetCentroid` | 283 | `SUBROUTINE PH_Elem_CAX6T_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_CAX6T_GetSectProps` | 289 | `SUBROUTINE PH_Elem_CAX6T_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormMechBodyForce` | 297 | `SUBROUTINE PH_Elem_CAX6T_FormMechBodyForce(coords, br, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormMechEdgePressure` | 305 | `SUBROUTINE PH_Elem_CAX6T_FormMechEdgePressure(coords, p, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormThermalBodySource` | 314 | `SUBROUTINE PH_Elem_CAX6T_FormThermalBodySource(coords, Q, F_therm)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormThermalEdgeFlux` | 335 | `SUBROUTINE PH_Elem_CAX6T_FormThermalEdgeFlux(coords, edge_id, q, F_therm)` |
| SUBROUTINE | `PH_Elem_CAX6T_FormNodalForce` | 356 | `SUBROUTINE PH_Elem_CAX6T_FormNodalForce(load_type, coords, val, edge_id, F_eq)` |
| SUBROUTINE | `PH_Elem_CAX6T_Material_Update_Thermo_Routed` | 374 | `SUBROUTINE PH_Elem_CAX6T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
