# `PH_Elem_AC2D4.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC2D4.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AC2D4`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC2D4`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC2D4`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC2D4.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC2D4_UEL_Args` (lines 48–70)

```fortran
  TYPE, PUBLIC :: PH_AC2D4_UEL_Args
    !-- [IN] Flags for computation control
    LOGICAL     :: compute_amatrx = .TRUE.   ! Compute tangent stiffness matrix
    LOGICAL     :: compute_rhs    = .TRUE.   ! Compute residual vector
    
    !-- [IN] P3 dynamic analysis extensions
    LOGICAL     :: compute_mass   = .FALSE.  ! Mass matrix computation flag (P3)
    INTEGER(i4) :: mass_method    = 0_i4    ! 0=None, 1=Consistent, 2=Lumped(HRZ), 3=Lumped(RowSum), 4=Lumped(Uniform)
    LOGICAL     :: compute_damping = .FALSE. ! Damping matrix computation flag (P3)
    REAL(wp)    :: alpha_M        = 0.0_wp  ! Mass proportional damping coefficient [1/s]
    REAL(wp)    :: beta_K         = 0.0_wp  ! Stiffness proportional damping coefficient [s]
    
    !-- [IN] Step control (from RT_Com_Ctx%lflags)
    INTEGER(i4) :: lflags_kstep   = 0_i4
    
    !-- [OUT] Status and diagnostics
    TYPE(ErrorStatusType) :: status      ! Error status (required by SIO-03)
    LOGICAL               :: success      = .FALSE.  ! Overall step success flag
    REAL(wp)              :: pnewdt       = 1.0_wp   ! Suggested time step change ratio
    REAL(wp)              :: strain_energy = 0.0_wp  ! Element strain energy (acoustic potential)
    INTEGER(i4)           :: ip_failed    = 0_i4     ! IP index where failure occurred
    REAL(wp)              :: total_mass   = 0.0_wp  ! Total element mass (P3 diagnostic)
  END TYPE PH_AC2D4_UEL_Args
```

### `PH_Elem_Acoustic_Args` (lines 182–223)

```fortran
  TYPE :: PH_Elem_Acoustic_Args
  !---------------------------------------------------------------------------
  ! PURPOSE: Legacy argument bundle for shape function/Jacobian helpers
  ! STATUS: ⚠️ DEPRECATED - Internal use only, not used by UEL interface
  ! TODO: Consider removal after verifying no external dependencies
  !---------------------------------------------------------------------------
  !> ROLE: ShapeFunc/JacB/FormStiffMatrix/FormIntForce/NL_TL/NL_UL/
  !>       ApplyConstraint/ApplyMPC/FormContactContrib/FormContactFaceCtr/
  !> FormBodyForce/FormNodalForce/CollectIPVars
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
  END TYPE PH_Elem_Acoustic_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_AC2D4_UEL_API` | 235 | `SUBROUTINE PH_AC2D4_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `PH_AC2D4_UEL_Impl` | 283 | `SUBROUTINE PH_AC2D4_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `AC2D4_Get_Gauss_Point` | 580 | `SUBROUTINE AC2D4_Get_Gauss_Point(ip, npts, xi_out, eta_out, w_out)` |
| SUBROUTINE | `AC2D4_Shape_Functions` | 599 | `SUBROUTINE AC2D4_Shape_Functions(xi_in, eta_in, N_out)` |
| SUBROUTINE | `AC2D4_Jacobian` | 612 | `SUBROUTINE AC2D4_Jacobian(coords_in, N_in, xi_in, eta_in, dNdX_out, detJ_out)` |
| SUBROUTINE | `AC2D4_B_Matrix` | 690 | `SUBROUTINE AC2D4_B_Matrix(dNdX_in, B_out)` |
| SUBROUTINE | `AC2D4_Consistent_Mass` | 734 | `SUBROUTINE AC2D4_Consistent_Mass(coords, density, Mass)` |
| SUBROUTINE | `AC2D4_Lumped_Mass` | 776 | `SUBROUTINE AC2D4_Lumped_Mass(coords, density, Mass, method)` |
| SUBROUTINE | `AC2D4_Rayleigh_Damping` | 877 | `SUBROUTINE AC2D4_Rayleigh_Damping(Mass, Stiffness, alpha_M, beta_K, Damping)` |
| SUBROUTINE | `PH_Elem_AC2D4_GetMaterialProps` | 927 | `SUBROUTINE PH_Elem_AC2D4_GetMaterialProps(density, bulk_modulus, sound_speed)` |
| SUBROUTINE | `PH_Elem_AC2D4_GetMaterialProps_FromDesc` | 936 | `SUBROUTINE PH_Elem_AC2D4_GetMaterialProps_FromDesc(desc)` |
| SUBROUTINE | `PH_Elem_AC2D4_GetThickness` | 943 | `SUBROUTINE PH_Elem_AC2D4_GetThickness(thickness)` |
| SUBROUTINE | `PH_Elem_AC2D4_GetAcousticProps` | 948 | `SUBROUTINE PH_Elem_AC2D4_GetAcousticProps(acoustic_density, acoustic_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D4_SetSectionProps` | 957 | `SUBROUTINE PH_Elem_AC2D4_SetSectionProps(density, bulk_modulus, thickness)` |
| SUBROUTINE | `PH_Elem_AC2D4_SetSectionProps_FromDesc` | 963 | `SUBROUTINE PH_Elem_AC2D4_SetSectionProps_FromDesc(sect_desc)` |
| SUBROUTINE | `PH_Elem_AC2D4_ApplyEssentialBC` | 971 | `SUBROUTINE PH_Elem_AC2D4_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormConstraintMatrix` | 995 | `SUBROUTINE PH_Elem_AC2D4_FormConstraintMatrix(constrained_nodes, C_matrix)` |
| SUBROUTINE | `PH_Elem_AC2D4_ApplyPenaltyBC` | 1006 | `SUBROUTINE PH_Elem_AC2D4_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormAcousticImpedance` | 1023 | `SUBROUTINE PH_Elem_AC2D4_FormAcousticImpedance(coords, impedance, face, K_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormRadiationCondition` | 1056 | `SUBROUTINE PH_Elem_AC2D4_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormStructureCoupling` | 1064 | `SUBROUTINE PH_Elem_AC2D4_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)` |
| SUBROUTINE | `PH_ELEM_AC2D4_CalcArea` | 1075 | `SUBROUTINE PH_ELEM_AC2D4_CalcArea(coords, area)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormPressureLoad` | 1086 | `SUBROUTINE PH_Elem_AC2D4_FormPressureLoad(coords, pressure, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormSurfaceTraction` | 1099 | `SUBROUTINE PH_Elem_AC2D4_FormSurfaceTraction(coords, traction, face, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormBodyForce` | 1125 | `SUBROUTINE PH_Elem_AC2D4_FormBodyForce(coords, body_force, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D4_CalcAcousticIntensity` | 1144 | `SUBROUTINE PH_Elem_AC2D4_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)` |
| SUBROUTINE | `PH_Elem_AC2D4_CalcEnergy` | 1158 | `SUBROUTINE PH_Elem_AC2D4_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC2D4_CalcEnergy_FromDesc` | 1178 | `SUBROUTINE PH_Elem_AC2D4_CalcEnergy_FromDesc(coords, nodal_pressures, nodal_velocities, sect_desc, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC2D4_CalcPressure` | 1188 | `SUBROUTINE PH_Elem_AC2D4_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)` |
| SUBROUTINE | `PH_Elem_AC2D4_OutputResults` | 1206 | `SUBROUTINE PH_Elem_AC2D4_OutputResults(coords, nodal_pressures, output_file)` |
| SUBROUTINE | `PH_ELEM_AC2D4_AreaInt` | 1234 | `SUBROUTINE PH_ELEM_AC2D4_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_AC2D4_FormStiffMatrix` | 1260 | `SUBROUTINE PH_Elem_AC2D4_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC2D4_ThermStrainVector` | 1292 | `SUBROUTINE PH_Elem_AC2D4_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC2D4_ConsMass` | 1298 | `SUBROUTINE PH_Elem_AC2D4_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC2D4_DefInit` | 1332 | `SUBROUTINE PH_Elem_AC2D4_DefInit()` |
| SUBROUTINE | `PH_Elem_AC2D4_FormIntForce` | 1335 | `SUBROUTINE PH_Elem_AC2D4_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC2D4_LumpMass` | 1345 | `SUBROUTINE PH_Elem_AC2D4_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC2D4_NL_TL` | 1358 | `SUBROUTINE PH_Elem_AC2D4_NL_TL(coords_ref, p_elem, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_AC2D4_NL_UL` | 1383 | `SUBROUTINE PH_Elem_AC2D4_NL_UL(coords_prev, p_incr, mat_prop, mat_state, &` |
| SUBROUTINE | `UF_Elem_AC2D4_Calc` | 1408 | `SUBROUTINE UF_Elem_AC2D4_Calc(ElemType, Formul, Ctx, state_in, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Temperature_Dependent_Speed` | 1532 | `SUBROUTINE PH_Elem_AC2D4_Temperature_Dependent_Speed(c0, T0, T_current, c_T)` |
| SUBROUTINE | `PH_Elem_AC2D4_Thermal_Expansion_Source` | 1573 | `SUBROUTINE PH_Elem_AC2D4_Thermal_Expansion_Source(coords, N, dNdx, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Biot_Wave_Speed` | 1647 | `SUBROUTINE PH_Elem_AC2D4_Biot_Wave_Speed(porosity, tortuosity, solid_density, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Biot_Damping` | 1760 | `SUBROUTINE PH_Elem_AC2D4_Biot_Damping(porosity, permeability, fluid_viscosity, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Sommerfeld_Radiation` | 1842 | `SUBROUTINE PH_Elem_AC2D4_Sommerfeld_Radiation(coords, wave_number, normal_vec, &\       pressure_field, velocity_field, radiation_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D4_Infinite_Element_Map` | 1927 | `SUBROUTINE PH_Elem_AC2D4_Infinite_Element_Map(base_coords, infinite_coords, &` |
| SUBROUTINE | `PH_Elem_AC2D4_PML_Update_State` | 2039 | `SUBROUTINE PH_Elem_AC2D4_PML_Update_State(p_field, pml_state, sigma_profile, dt, &` |
| SUBROUTINE | `PH_Elem_AC2D4_PML_Absorbing_Boundary` | 2110 | `SUBROUTINE PH_Elem_AC2D4_PML_Absorbing_Boundary(coords, normal_vec, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Biot_Stabilize_SlowWave` | 2214 | `SUBROUTINE PH_Elem_AC2D4_Biot_Stabilize_SlowWave(porosity, permeability, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Precompute_Shapes` | 2347 | `SUBROUTINE PH_Elem_AC2D4_Precompute_Shapes(xi_values, eta_values, n_gauss, &` |
| SUBROUTINE | `PH_Elem_AC2D4_Vectorized_B_Matrix` | 2417 | `SUBROUTINE PH_Elem_AC2D4_Vectorized_B_Matrix(coords, dNdX, B_matrix, n_ips)` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
