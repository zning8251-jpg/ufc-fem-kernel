# `PH_Elem_AC2D8.f90`

- **Source**: `L4_PH/Element/Acoustic/PH_Elem_AC2D8.f90`
- **Generated (UTC)**: 2026-05-07T07:47:17Z
- **MODULE (heuristic)**: `PH_Elem_AC2D8`

> Heuristic scan: verify critical files against compiler view; nested TYPE / continuations may mis-classify.

## 命名 — 三段式 / 四段式（对照规范）

与 [CONVENTIONS.md](../../../../CONVENTIONS.md) §1.1–§1.2、[UFC_命名与数据结构规范.md](../../../../../UFC_命名与数据结构规范.md) §3 一致（以下为 **按 `.f90` 文件名 stem 的启发式**，非编译器语义）：

- **stem**: `PH_Elem_AC2D8`
- **逻辑主线（默认三段式 `PH_{Domain+Feature}`）**: `PH_Elem_AC2D8`
- **第四段角色**: *(未解析到闭集内后缀 — 可能为纯三段式主线，或非标准 stem；以源码与合同为准)*
- **源码子路径（层下目录，不含文件名）**: `Element/Acoustic`
- **Registry 布局（镜像 `ufc_core` 相对路径 + `.md`）**: `generated/L4_PH/Element/Acoustic/PH_Elem_AC2D8.md` — *与 [`UFC_ufc_core_目录权威分类.md`](../../../../../05_Project_Planning/PPLAN/06_核心架构/UFC_ufc_core_目录权威分类.md) 物理树一致；三段式/四段式解析见上*

## TYPE blocks

### `PH_AC2D8_UEL_Args` (lines 127–149)

```fortran
  TYPE, PUBLIC :: PH_AC2D8_UEL_Args
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
  END TYPE PH_AC2D8_UEL_Args
```

## Module-level procedures (`SUBROUTINE` / `FUNCTION`)

| Kind | Name | Line | Signature (first line) |
|------|------|------|-------------------------|
| SUBROUTINE | `PH_AC2D8_UEL_API` | 160 | `SUBROUTINE PH_AC2D8_UEL_API(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `PH_AC2D8_UEL_Impl` | 191 | `SUBROUTINE PH_AC2D8_UEL_Impl(sect_registry, MD_Elem_Desc, PH_Elem_Ctx, PH_Elem_State, &` |
| SUBROUTINE | `CPS8_GetGaussPoint1D` | 358 | `SUBROUTINE CPS8_GetGaussPoint1D(ip, xi, w)` |
| SUBROUTINE | `CPS8_Shape_Functions` | 375 | `SUBROUTINE CPS8_Shape_Functions(xi, eta, N)` |
| SUBROUTINE | `CPS8_Shape_Functions_Derivatives` | 401 | `SUBROUTINE CPS8_Shape_Functions_Derivatives(xi, eta, dNdxi, dNdeta)` |
| SUBROUTINE | `CPS8_Jacobian` | 435 | `SUBROUTINE CPS8_Jacobian(coords, N, xi, eta, dNdX, detJ)` |
| SUBROUTINE | `AC2D8_B_Matrix` | 467 | `SUBROUTINE AC2D8_B_Matrix(dNdX, B)` |
| SUBROUTINE | `PH_Elem_AC2D8_GetMaterialProps` | 489 | `SUBROUTINE PH_Elem_AC2D8_GetMaterialProps(density, bulk_modulus, sound_speed)` |
| SUBROUTINE | `PH_Elem_AC2D8_GetMaterialProps_FromDesc` | 496 | `SUBROUTINE PH_Elem_AC2D8_GetMaterialProps_FromDesc(desc)` |
| SUBROUTINE | `PH_Elem_AC2D8_GetThickness` | 503 | `SUBROUTINE PH_Elem_AC2D8_GetThickness(thickness)` |
| SUBROUTINE | `PH_Elem_AC2D8_GetAcousticProps` | 508 | `SUBROUTINE PH_Elem_AC2D8_GetAcousticProps(acoustic_density, acoustic_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D8_SetSectionProps` | 516 | `SUBROUTINE PH_Elem_AC2D8_SetSectionProps(density, bulk_modulus, thickness)` |
| SUBROUTINE | `PH_Elem_AC2D8_SetSectionProps_FromDesc` | 520 | `SUBROUTINE PH_Elem_AC2D8_SetSectionProps_FromDesc(sect_desc)` |
| SUBROUTINE | `PH_Elem_AC2D8_ApplyEssentialBC` | 526 | `SUBROUTINE PH_Elem_AC2D8_ApplyEssentialBC(Ke, F_ext, constrained_nodes, prescribed_values)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormConstraintMatrix` | 548 | `SUBROUTINE PH_Elem_AC2D8_FormConstraintMatrix(constrained_nodes, C_matrix)` |
| SUBROUTINE | `PH_Elem_AC2D8_ApplyPenaltyBC` | 559 | `SUBROUTINE PH_Elem_AC2D8_ApplyPenaltyBC(Ke, F_ext, constrained_nodes, prescribed_values, penalty)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormAcousticImpedance` | 574 | `SUBROUTINE PH_Elem_AC2D8_FormAcousticImpedance(coords, impedance, face, K_impedance)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormRadiationCondition` | 614 | `SUBROUTINE PH_Elem_AC2D8_FormRadiationCondition(coords, radiation_coeff, face, K_radiation)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormStructureCoupling` | 622 | `SUBROUTINE PH_Elem_AC2D8_FormStructureCoupling(coords, coupling_coeff, face, K_coupling)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormPressureLoad` | 631 | `SUBROUTINE PH_Elem_AC2D8_FormPressureLoad(coords, pressure, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormSurfaceTraction` | 644 | `SUBROUTINE PH_Elem_AC2D8_FormSurfaceTraction(coords, traction, face, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormBodyForce` | 675 | `SUBROUTINE PH_Elem_AC2D8_FormBodyForce(coords, body_force, F_ext)` |
| SUBROUTINE | `PH_Elem_AC2D8_CalcAcousticIntensity` | 689 | `SUBROUTINE PH_Elem_AC2D8_CalcAcousticIntensity(coords, nodal_pressures, nodal_velocities, intensity)` |
| SUBROUTINE | `PH_Elem_AC2D8_CalcEnergy` | 703 | `SUBROUTINE PH_Elem_AC2D8_CalcEnergy(coords, nodal_pressures, nodal_velocities, density, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC2D8_CalcEnergy_FromDesc` | 722 | `SUBROUTINE PH_Elem_AC2D8_CalcEnergy_FromDesc(coords, nodal_pressures, nodal_velocities, sect_desc, kinetic_energy, potential_energy)` |
| SUBROUTINE | `PH_Elem_AC2D8_OutputResults` | 734 | `SUBROUTINE PH_Elem_AC2D8_OutputResults(coords, nodal_pressures, nodal_velocities, filename)` |
| SUBROUTINE | `PH_Elem_AC2D8_CalcPressure` | 744 | `SUBROUTINE PH_Elem_AC2D8_CalcPressure(coords, nodal_pressures, gauss_points, pressure_field)` |
| SUBROUTINE | `PH_Elem_AC2D8_Update_Speed_of_Sound` | 763 | `SUBROUTINE PH_Elem_AC2D8_Update_Speed_of_Sound(mat_desc, temperature, &` |
| SUBROUTINE | `PH_Elem_AC2D8_Thermal_Expansion_Source` | 821 | `SUBROUTINE PH_Elem_AC2D8_Thermal_Expansion_Source(coords, mat_desc, temperature, source_term, status)` |
| SUBROUTINE | `PH_Elem_AC2D8_Setup_Thermo_Coupling` | 859 | `SUBROUTINE PH_Elem_AC2D8_Setup_Thermo_Coupling(mat_desc, T_field, status)` |
| SUBROUTINE | `PH_ELEM_AC2D8_AreaInt` | 902 | `SUBROUTINE PH_ELEM_AC2D8_AreaInt(coords, area)` |
| SUBROUTINE | `PH_Elem_AC2D8_FormStiffMatrix` | 928 | `SUBROUTINE PH_Elem_AC2D8_FormStiffMatrix(coords, E_young, nu, Ke)` |
| SUBROUTINE | `PH_Elem_AC2D8_ThermStrainVector` | 960 | `SUBROUTINE PH_Elem_AC2D8_ThermStrainVector(alpha, deltaT, eps_th)` |
| SUBROUTINE | `PH_Elem_AC2D8_ConsMass` | 966 | `SUBROUTINE PH_Elem_AC2D8_ConsMass(coords, rho, Me)` |
| SUBROUTINE | `PH_Elem_AC2D8_DefInit` | 1000 | `SUBROUTINE PH_Elem_AC2D8_DefInit()` |
| SUBROUTINE | `PH_Elem_AC2D8_FormIntForce` | 1003 | `SUBROUTINE PH_Elem_AC2D8_FormIntForce(coords, u, E_young, nu, R_int)` |
| SUBROUTINE | `PH_Elem_AC2D8_LumpMass` | 1013 | `SUBROUTINE PH_Elem_AC2D8_LumpMass(coords, rho, M_lumped)` |
| SUBROUTINE | `PH_Elem_AC2D8_NL_TL` | 1026 | `SUBROUTINE PH_Elem_AC2D8_NL_TL(coords_ref, p_elem, mat_prop, mat_state, &` |
| SUBROUTINE | `PH_Elem_AC2D8_NL_UL` | 1051 | `SUBROUTINE PH_Elem_AC2D8_NL_UL(coords_prev, p_incr, mat_prop, mat_state, &` |
| FUNCTION | `PH_Elem_AC2D8_Biot_Compute_Stab_Param` | 1080 | `FUNCTION PH_Elem_AC2D8_Biot_Compute_Stab_Param(wavenumber, flow_velocity, &` |
| SUBROUTINE | `PH_Elem_AC2D8_Biot_Wave_Speed` | 1124 | `SUBROUTINE PH_Elem_AC2D8_Biot_Wave_Speed(mat_desc, porosity, tortuosity, wave_speed, status)` |
| SUBROUTINE | `PH_Elem_AC2D8_Biot_Damping` | 1171 | `SUBROUTINE PH_Elem_AC2D8_Biot_Damping(mat_desc, permeability, viscosity, damping_coef, status)` |
| SUBROUTINE | `PH_Elem_AC2D8_Biot_Stabilize_SlowWave` | 1219 | `SUBROUTINE PH_Elem_AC2D8_Biot_Stabilize_SlowWave(coords, mat_desc, &` |
| SUBROUTINE | `PH_Elem_AC2D8_PML_Update_State` | 1355 | `SUBROUTINE PH_Elem_AC2D8_PML_Update_State(pressure_current, pressure_prev, &` |
| SUBROUTINE | `PH_Elem_AC2D8_PML_Absorbing_Boundary` | 1437 | `SUBROUTINE PH_Elem_AC2D8_PML_Absorbing_Boundary(coords, mat_desc, &` |
| SUBROUTINE | `PH_Elem_AC2D8_Sommerfeld_Radiation` | 1567 | `SUBROUTINE PH_Elem_AC2D8_Sommerfeld_Radiation(coords, mat_desc, pressure_field, \` |
| SUBROUTINE | `PH_Elem_AC2D8_Infinite_Element_Map` | 1608 | `SUBROUTINE PH_Elem_AC2D8_Infinite_Element_Map(coords_infinite, coords_finite, &` |

## Procedures detected inside TYPE bodies

*(none — type-bound bodies often use `PROCEDURE ::` only; see TYPE blocks above)*

## INTERFACE blocks (outline)

*(none)*
