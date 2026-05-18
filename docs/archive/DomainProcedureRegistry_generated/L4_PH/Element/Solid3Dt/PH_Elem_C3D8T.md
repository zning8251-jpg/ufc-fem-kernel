# `PH_Elem_C3D8T.f90`

- **Source**: `L4_PH/Element/Solid3Dt/PH_Elem_C3D8T.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_C3D8T`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_C3D8T`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_C3D8T`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Solid3Dt`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Solid3Dt/PH_Elem_C3D8T.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_ELEM_C3D8T_MaterialProperties` (lines 82–96)

```fortran
  TYPE :: PH_ELEM_C3D8T_MaterialProperties
    INTEGER(i4) :: material_type
    REAL(wp) :: density
    REAL(wp) :: young_modulus
    REAL(wp) :: poisson_ratio
    REAL(wp) :: thermal_expansion
    REAL(wp) :: thermal_conductivity
    REAL(wp) :: specific_heat
    REAL(wp) :: reference_temperature
    REAL(wp) :: e_temperature_coefficient
    REAL(wp) :: alpha_temperature_coefficient
    REAL(wp) :: k_temperature_coefficient
    REAL(wp) :: yield_stress
    REAL(wp) :: hardening_modulus
  END TYPE PH_ELEM_C3D8T_MaterialProperties
```

### `PH_ELEM_C3D8T_SectionProperties` (lines 98–105)

```fortran
  TYPE :: PH_ELEM_C3D8T_SectionProperties
    INTEGER(i4) :: section_type
    REAL(wp) :: thickness
    REAL(wp) :: area
    REAL(wp) :: moment_of_inertia(3, 3)
    REAL(wp) :: centroid(3)
    REAL(wp) :: shear_area(3)
  END TYPE PH_ELEM_C3D8T_SectionProperties
```

### `PH_ELEM_C3D8T_OutputData` (lines 107–120)

```fortran
  TYPE :: PH_ELEM_C3D8T_OutputData
    REAL(wp) :: nodal_displacements(24)
    REAL(wp) :: nodal_temperatures(8)
    REAL(wp) :: nodal_stresses(6, 8)
    REAL(wp) :: nodal_strains(6, 8)
    REAL(wp) :: von_mises_stress(8)
    REAL(wp) :: thermal_stress(6, 8)
    REAL(wp) :: total_stress(6, 8)
    REAL(wp) :: heat_flux(3, 8)
    REAL(wp) :: element_energy(3)
    REAL(wp) :: integration_points(27, 3)
    REAL(wp) :: point_stresses(6, 27)
    REAL(wp) :: point_temperatures(27)
  END TYPE PH_ELEM_C3D8T_OutputData
```

### `PH_Elem_Sld3DT_Args` (lines 185–227)

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
| SUBROUTINE | `PH_Elem_C3D8T_FormStiffMatrix_MatAware` | 235 | `SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix_MatAware(coords, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_C3D8T_FormCouplingStiffness_MatAware` | 289 | `SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness_MatAware(coords, D_tangent, alpha, Ke_ut)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormIntForce_MatAware` | 318 | `SUBROUTINE PH_Elem_C3D8T_FormIntForce_MatAware(coords, u, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_C3D8T_FormCouplingStiffness` | 387 | `SUBROUTINE PH_Elem_C3D8T_FormCouplingStiffness(coords, E_young, nu, alpha, Ke_ut)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormStiffMatrix` | 412 | `SUBROUTINE PH_Elem_C3D8T_FormStiffMatrix(coords, E_young, nu, alpha, k_thermal, T_ref, Ke)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormThermalStiffness` | 441 | `SUBROUTINE PH_Elem_C3D8T_FormThermalStiffness(coords, k_thermal, Ke_tt)` |
| SUBROUTINE | `PH_Elem_C3D8T_ConsMass` | 460 | `SUBROUTINE PH_Elem_C3D8T_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_C3D8T_DefInit` | 468 | `SUBROUTINE PH_Elem_C3D8T_DefInit()` |
| SUBROUTINE | `PH_Elem_C3D8T_FormIntForce` | 471 | `SUBROUTINE PH_Elem_C3D8T_FormIntForce(coords, u, E_young, nu, alpha, k_thermal, T_ref, R_int)` |
| SUBROUTINE | `PH_Elem_C3D8T_GaussPoints` | 505 | `SUBROUTINE PH_Elem_C3D8T_GaussPoints(xi, eta, zeta, weights)` |
| SUBROUTINE | `PH_Elem_C3D8T_Jac` | 510 | `SUBROUTINE PH_Elem_C3D8T_Jac(dNdxi, coords, J, detJ)` |
| SUBROUTINE | `PH_Elem_C3D8T_JacB` | 516 | `SUBROUTINE PH_Elem_C3D8T_JacB(coords, xi, eta, zeta, N, dNdx, J, detJ, B)` |
| SUBROUTINE | `PH_Elem_C3D8T_LumpMass` | 523 | `SUBROUTINE PH_Elem_C3D8T_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_C3D8T_ShapeFunc` | 531 | `SUBROUTINE PH_Elem_C3D8T_ShapeFunc(xi, eta, zeta, N, dNdxi)` |
| SUBROUTINE | `PH_Elem_C3D8T_ThermStrain3D` | 537 | `SUBROUTINE PH_Elem_C3D8T_ThermStrain3D(T, T_ref, alpha, strain_th)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetCentroid` | 553 | `SUBROUTINE PH_Elem_C3D8T_GetCentroid(coords, centroid)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetInertiaOrig` | 577 | `SUBROUTINE PH_Elem_C3D8T_GetInertiaOrig(coords, rho, I_out)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetSectProps` | 605 | `SUBROUTINE PH_Elem_C3D8T_GetSectProps(coords, density_in, volume, mass)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetVolume` | 613 | `SUBROUTINE PH_Elem_C3D8T_GetVolume(coords, volume)` |
| SUBROUTINE | `ApplyFixedConstraint` | 631 | `SUBROUTINE ApplyFixedConstraint(K_global, F_global, dof, value, large_stiff)` |
| SUBROUTINE | `PH_Elem_C3D8T_ApplyConstraints` | 647 | `SUBROUTINE PH_Elem_C3D8T_ApplyConstraints(K_global, F_global, constraints, &` |
| SUBROUTINE | `PH_Elem_C3D8T_ApplyPenaltyConstraints` | 700 | `SUBROUTINE PH_Elem_C3D8T_ApplyPenaltyConstraints(K_global, F_global, constraints, &` |
| SUBROUTINE | `PH_Elem_C3D8T_FormConstraintMatrix` | 746 | `SUBROUTINE PH_Elem_C3D8T_FormConstraintMatrix(constraints, C_matrix, rhs_vector)` |
| FUNCTION | `PH_Elem_C3D8T_CheckConstraintCompatibility` | 791 | `FUNCTION PH_Elem_C3D8T_CheckConstraintCompatibility(constraints) RESULT(is_compatible)` |
| SUBROUTINE | `GetFaceNodes` | 824 | `SUBROUTINE GetFaceNodes(face_id, face_nodes)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormContactStiffness` | 838 | `SUBROUTINE PH_Elem_C3D8T_FormContactStiffness(coords, face_id, contact_type, contact_params, K_contact)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormThermalContact` | 847 | `SUBROUTINE PH_Elem_C3D8T_FormThermalContact(coords, face_id, contact_resistance, K_thermal_contact)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormConvectionBoundary` | 855 | `SUBROUTINE PH_Elem_C3D8T_FormConvectionBoundary(coords, face_id, convection_coeff, T_ambient, K_convection, F_convection)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormRadiationBoundary` | 866 | `SUBROUTINE PH_Elem_C3D8T_FormRadiationBoundary(coords, face_id, emissivity, stefan_boltzmann, T_ambient, K_radiation, F_radiation)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateContactForces` | 878 | `SUBROUTINE PH_Elem_C3D8T_CalculateContactForces(coords, face_id, contact_type, contact_params, &` |
| SUBROUTINE | `PH_Elem_C3D8T_FormMechBodyForce` | 895 | `SUBROUTINE PH_Elem_C3D8T_FormMechBodyForce(coords, bx, by, bz, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormMechFacePressure` | 903 | `SUBROUTINE PH_Elem_C3D8T_FormMechFacePressure(coords, p, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormMechGravity` | 912 | `SUBROUTINE PH_Elem_C3D8T_FormMechGravity(coords, rho, g_dir, g_mag, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormThermalBodySource` | 922 | `SUBROUTINE PH_Elem_C3D8T_FormThermalBodySource(coords, Q, F_therm)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormThermalFaceFlux` | 941 | `SUBROUTINE PH_Elem_C3D8T_FormThermalFaceFlux(coords, face_id, q, F_therm)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormNodalForce` | 1048 | `SUBROUTINE PH_Elem_C3D8T_FormNodalForce(load_type, coords, val, face_id, F_eq)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetMaterialProperties` | 1076 | `SUBROUTINE PH_Elem_C3D8T_GetMaterialProperties(material_id, temperature, mat_props)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetSectionProperties` | 1090 | `SUBROUTINE PH_Elem_C3D8T_GetSectionProperties(section_id, section_type, section_props)` |
| SUBROUTINE | `PH_Elem_C3D8T_FormElasticityMatrix` | 1099 | `SUBROUTINE PH_Elem_C3D8T_FormElasticityMatrix(mat_props, D_matrix)` |
| SUBROUTINE | `PH_Elem_C3D8T_GetThermalProperties` | 1122 | `SUBROUTINE PH_Elem_C3D8T_GetThermalProperties(mat_props, thermal_expansion, thermal_conductivity, specific_heat)` |
| SUBROUTINE | `PH_Elem_C3D8T_UpdateTemperatureProperties` | 1132 | `SUBROUTINE PH_Elem_C3D8T_UpdateTemperatureProperties(mat_props, temperature)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateEffectiveProperties` | 1137 | `SUBROUTINE PH_Elem_C3D8T_CalculateEffectiveProperties(mat_properties, section_props, effective_E, effective_nu, effective_alpha)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateStressStrain` | 1151 | `SUBROUTINE PH_Elem_C3D8T_CalculateStressStrain(coords, D_matrix, displacements, output_data)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateThermalStress` | 1199 | `SUBROUTINE PH_Elem_C3D8T_CalculateThermalStress(coords, temperatures, thermal_expansion, reference_temperature, output_data, D_matrix)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateVonMisesStress` | 1228 | `SUBROUTINE PH_Elem_C3D8T_CalculateVonMisesStress(output_data)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateEnergy` | 1248 | `SUBROUTINE PH_Elem_C3D8T_CalculateEnergy(coords, D_matrix, displacements, temperatures, density, specific_heat, output_data, reference_temperature)` |
| SUBROUTINE | `PH_Elem_C3D8T_CalculateHeatFlux` | 1291 | `SUBROUTINE PH_Elem_C3D8T_CalculateHeatFlux(coords, temperatures, thermal_conductivity, output_data)` |
| SUBROUTINE | `PH_Elem_C3D8T_OutputFieldValues` | 1320 | `SUBROUTINE PH_Elem_C3D8T_OutputFieldValues(output_data, field_type, output_values)` |
| SUBROUTINE | `PH_Elem_C3D8T_WriteResultsToFile` | 1335 | `SUBROUTINE PH_Elem_C3D8T_WriteResultsToFile(element_id, output_data, filename)` |
| SUBROUTINE | `PH_Elem_C3D8T_GenerateVisualizationData` | 1341 | `SUBROUTINE PH_Elem_C3D8T_GenerateVisualizationData(coords, output_data, vtk_filename)` |
| SUBROUTINE | `PH_Elem_C3D8T_Material_Update_Thermo_Routed` | 1347 | `SUBROUTINE PH_Elem_C3D8T_Material_Update_Thermo_Routed(rt_ctx, mat_slot, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
