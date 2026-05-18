# `PH_Elem_C3D20T.f90`

- **Source**: `L4_PH/Element/Solid3Dt/PH_Elem_C3D20T.f90`
- **Generated (UTC)**: 2026-05-14T07:52:52Z
- **MODULE (heuristic)**: `PH_Elem_C3D20T`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D20T`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D20T`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3Dt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3Dt/PH_Elem_C3D20T.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ELEM_C3D20T_OutputData` (lines 37–47)

```fortran
  TYPE :: PH_ELEM_C3D20T_OutputData
    REAL(wp) :: nodal_displacements(60)
    REAL(wp) :: nodal_temperatures(20)
    REAL(wp) :: nodal_stresses(6, 20)
    REAL(wp) :: nodal_strains(6, 20)
    REAL(wp) :: von_mises_stress(20)
    REAL(wp) :: thermal_stress(6, 20)
    REAL(wp) :: total_stress(6, 20)
    REAL(wp) :: heat_flux(3, 20)
    REAL(wp) :: element_energy(3)
  END TYPE PH_ELEM_C3D20T_OutputData
```

### `PH_Elem_Sld3DT_Args` (lines 69–111)

```fortran
  TYPE :: PH_Elem_Sld3DT_Args
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
  END TYPE PH_Elem_Sld3DT_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_Elem_C3D20T_ThermStrain3D` | 116 | `SUBROUTINE PH_Elem_C3D20T_ThermStrain3D(T, T_ref, alpha, strain_th)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormStiffMatrix_MatAware` | 128 | `SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_C3D20T_FormCouplingStiffness` | 173 | `SUBROUTINE PH_Elem_C3D20T_FormCouplingStiffness(coords, D_tangent, alpha, Ke_ut)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormStiffMatrix` | 197 | `SUBROUTINE PH_Elem_C3D20T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormThermalStiffness` | 223 | `SUBROUTINE PH_Elem_C3D20T_FormThermalStiffness(coords, k_thermal, Ke_tt)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormIntForce_MatAware` | 242 | `SUBROUTINE PH_Elem_C3D20T_FormIntForce_MatAware(coords, u, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_C3D20T_FormIntForce` | 296 | `SUBROUTINE PH_Elem_C3D20T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)` |
| SUBROUTINE | `PH_Elem_C3D20T_DefInit` | 323 | `SUBROUTINE PH_Elem_C3D20T_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D20T_ConsMass` | 326 | `SUBROUTINE PH_Elem_C3D20T_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D20T_LumpMass` | 334 | `SUBROUTINE PH_Elem_C3D20T_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D20T_ShapeFunc` | 342 | `SUBROUTINE PH_Elem_C3D20T_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D20T_Jac` | 348 | `SUBROUTINE PH_Elem_C3D20T_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D20T_GaussPoints` | 354 | `SUBROUTINE PH_Elem_C3D20T_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D20T_JacB` | 359 | `SUBROUTINE PH_Elem_C3D20T_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D20T_GetVolume` | 366 | `SUBROUTINE PH_Elem_C3D20T_GetVolume(coords, volume)` |
| SUBROUTINE | `PH_Elem_C3D20T_GetSectProps` | 381 | `SUBROUTINE PH_Elem_C3D20T_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D20T_GetCentroid` | 389 | `SUBROUTINE PH_Elem_C3D20T_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormMechBodyForce` | 413 | `SUBROUTINE PH_Elem_C3D20T_FormMechBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormMechFacePressure` | 421 | `SUBROUTINE PH_Elem_C3D20T_FormMechFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormThermalBodySource` | 430 | `SUBROUTINE PH_Elem_C3D20T_FormThermalBodySource(coords, Q, F_therm)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormThermalFaceFlux` | 449 | `SUBROUTINE PH_Elem_C3D20T_FormThermalFaceFlux(coords, face_id, q, F_therm)` |
| SUBROUTINE | `PH_Elem_C3D20T_FormNodalForce` | 548 | `SUBROUTINE PH_Elem_C3D20T_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D20T_Material_Update_Thermo_Routed` | 573 | `SUBROUTINE PH_Elem_C3D20T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
